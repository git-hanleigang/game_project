----
local QuestNewWheelRewardLayer = class("QuestNewWheelRewardLayer", BaseLayer)


function QuestNewWheelRewardLayer:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewWheelRewardLayer
end

function QuestNewWheelRewardLayer:initDatas(reward)
    self.m_rewards = reward --{coins items}
    self.m_bTouch = true
end
-- 弹窗动画
function QuestNewWheelRewardLayer:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewWheelRewardLayer.super.playShowAction(self, userDefAction)
end

function QuestNewWheelRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self.m_bTouch = false
end

function QuestNewWheelRewardLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_reward")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_sp_coins = self:findChild("sp_coin")

    self.m_sp_minor = self:findChild("sp_minor")
    self.m_sp_major = self:findChild("sp_major")
    self.m_sp_grand = self:findChild("sp_grand")
    
end


function QuestNewWheelRewardLayer:initView()

    self:initRewards()

    self.m_sp_minor:setVisible(self.m_rewards.jackpotType == 1)
    self.m_sp_major:setVisible(self.m_rewards.jackpotType == 2)
    self.m_sp_grand:setVisible(self.m_rewards.jackpotType == 3)

    gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelReward)
end

function QuestNewWheelRewardLayer:initRewards()
    self.m_flyCoins = 0 
    local propList = {}
    -- 通用道具
    if self.m_rewards.items and #self.m_rewards.items > 0 then
        for i, v in ipairs(self.m_rewards.items) do
            propList[#propList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            if string.find(v.p_icon, "Pouch") then
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                mergeManager:refreshBagsNum(v.p_icon, v.p_num)
            end
        end
    end
    if self.m_rewards.coins and self.m_rewards.coins > 0 then
        self.m_flyCoins = tonumber(self.m_rewards.coins)
        self.m_lb_coin:setString(util_getFromatMoneyStr(self.m_rewards.coins))
        local size_lable = self.m_lb_coin:getContentSize()
        self.m_sp_coins:setPositionX(472.66 - size_lable.width*0.7/2 - 77*0.85/2 - 10)

        --propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(self.m_rewards.coins), {p_limit = 3})
    end

    if #propList > 0 then
        local itemList = {}
        for i = 1, #propList do
            -- 处理一下角标显示
            local itemData = propList[i]
            local newItemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD_BIG)
            if newItemNode then -- csc 2021-11-28 18:00:06 修复如果邮件里包含的道具如果不存在报错的情况
                gLobalDailyTaskManager:setItemNodeByExtraData(itemData, newItemNode)
                itemList[#itemList + 1] = gLobalItemManager:createOtherItemData(newItemNode, 1)
            end
        end
        local size = cc.size(850, 350)
        local scale = self:getUIScalePro()
        if globalData.slotRunData.isPortrait then
            size = cc.size(850, 400)
            scale = 0.84
        end
        --默认大小
        local listView = gLobalItemManager:createRewardListView(itemList, size)
        listView:setScale(scale)
        self.m_nodeReward:addChild(listView)
    end
end

function QuestNewWheelRewardLayer:onClickMask()
    if self.m_bTouch then
        return
    end
    self.m_bTouch = true
    self:collectAction()
end

function QuestNewWheelRewardLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_collect" or name == "btn_close" then
        if self.m_bTouch then
            return
        end
        self.m_bTouch = true
        self:collectAction()
    end
end

function QuestNewWheelRewardLayer:collectAction()
    if not self.m_flyCoins or self.m_flyCoins == 0 then
        self:closeFunc()
        return
    end
    local btnCollect = self:findChild("btn_collect")
    local endPos = globalData.flyCoinsEndPos
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local addValue = self.m_flyCoins
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local info_Currency = {
            {cuyType = FlyType.Coin, 
            addValue = addValue,
            startPos = startPos}
        }
        cuyMgr:playFlyCurrency(
            info_Currency,
            function()
                self:closeFunc()
            end
        )
    end
end

function QuestNewWheelRewardLayer:closeFunc()
    
    local propsBagList = self.m_rewards.propsBagList

    local popNextLayer = function()
        if propsBagList and next(propsBagList) then
            local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
            mergeManager:popMergePropsBagRewardPanel(
                self.m_rewards.propsBagList,
                function()
                    if not tolua.isnull(self) then
                        self:closeUI()
                    end
                end
            )
        else
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end
    end

    if CardSysManager:needDropCards("Advertise Incentive") then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                popNextLayer()
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Advertise Incentive")
    else
        popNextLayer()
    end
end

function QuestNewWheelRewardLayer:requestGainWheelReward()
   G_GetMgr(ACTIVITY_REF.QuestNew):requestCollectWheelReward()
end

function QuestNewWheelRewardLayer:onEnter()
    QuestNewWheelRewardLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.type == "success" then
                self:afterGainWheelReward(params)
            else
                self.m_bTouch = false
            end
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_WHEELREWARD
    )
    self:requestGainWheelReward()
end

function QuestNewWheelRewardLayer:afterGainWheelReward()
    --self:collectAction()
end

function QuestNewWheelRewardLayer:closeUI()
    QuestNewWheelRewardLayer.super.closeUI(
        self,
        function()
            G_GetMgr(ACTIVITY_REF.QuestNew):setStopPoolRun(false)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REQUEST_AFTER_WHEELLAYERCLOSE)
        end
    )
end

return QuestNewWheelRewardLayer
