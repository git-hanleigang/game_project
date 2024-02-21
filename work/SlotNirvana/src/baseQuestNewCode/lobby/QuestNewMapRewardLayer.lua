----
local QuestNewMapRewardLayer = class("QuestNewMapRewardLayer", BaseLayer)


function QuestNewMapRewardLayer:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewMapRewardLayer
end

function QuestNewMapRewardLayer:initDatas(data)
    self.m_rewards = data.reward --{coins items}
    self.callBack = data.callBack
    self.type = data.type or 1 
    self.m_chapterId = data.chapterId 
end
-- 弹窗动画
function QuestNewMapRewardLayer:playShowAction()
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
    QuestNewMapRewardLayer.super.playShowAction(self, userDefAction)
end

function QuestNewMapRewardLayer:playHideAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "over",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewMapRewardLayer.super.playHideAction(self, userDefAction)
end
function QuestNewMapRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestNewMapRewardLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_reward")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_sp_coins = self:findChild("sp_coins")
    self.m_nodeCoins = self:findChild("Node_shuzi")
end


function QuestNewMapRewardLayer:initView()
    gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_ChestCollect)
    self:initRewards()
end

function QuestNewMapRewardLayer:initRewards()
    self.m_flyCoins = 0 

    if self.m_rewards.coin and self.m_rewards.coin > 0 then
        self.m_flyCoins = tonumber(self.m_rewards.coin)
        self.m_lb_coin:setString(util_formatCoins(self.m_flyCoins, 12))
        local size_lable = self.m_lb_coin:getContentSize()
        self.m_sp_coins:setPositionX(40 - size_lable.width*0.7/2 - 77*0.88/2 - 10)
    else
        self.m_nodeCoins:setVisible(false)
        self.m_nodeReward:setPositionY(22)
        self.m_nodeReward:setScale(2)
    end

    self.m_flyGem = 0
    local propList = {}
    -- 通用道具
    if self.m_rewards.items and #self.m_rewards.items > 0 then
        for i, v in ipairs(self.m_rewards.items) do
            propList[#propList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            if string.find(v.p_icon, "Pouch") then
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                mergeManager:refreshBagsNum(v.p_icon, v.p_num)
            elseif string.find(v.p_icon, "Gem") then 
                self.m_flyGem = self.m_flyGem + v.p_num
            end
        end
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
        --默认大小
        local listView = gLobalItemManager:createRewardListView(itemList, size)
        listView:setScale(0.6)
        self.m_nodeReward:addChild(listView)
    end
end

function QuestNewMapRewardLayer:onClickMask()
    if self.m_bTouch then
        return
    end
    self.m_bTouch = true
    self:doCollectLogic()
end

function QuestNewMapRewardLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_collect" or name == "btn_close" then
        if self.m_bTouch then
            return
        end
        self.m_bTouch = true
        self:doCollectLogic()
    end
end

function QuestNewMapRewardLayer:doCollectLogic()
    if self.type == 1 then
        G_GetMgr(ACTIVITY_REF.QuestNew):requestCollectStarMeter(self.m_chapterId)
    else
        self:collectAction()
    end
end

function QuestNewMapRewardLayer:collectAction()
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

        if self.m_flyGem > 0 then
            table.insert(info_Currency,
                {cuyType = FlyType.Gem, 
                addValue = self.m_flyGem,
                startPos = startPos})
        end
        cuyMgr:playFlyCurrency(
            info_Currency,
            function()
                self:closeFunc()
            end
        )
    end
end

function QuestNewMapRewardLayer:closeFunc()
    
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

    if CardSysManager:needDropCards("Quest StarMeters Award") then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                popNextLayer()
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Quest StarMeters Award")
    else
        popNextLayer()
    end
end

function QuestNewMapRewardLayer:onEnter()
    QuestNewMapRewardLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:afterGainStarReward(params)
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_GAINSTARREWARD
    )
end

function QuestNewMapRewardLayer:closeUI()
    local type = self.type
    local callBack = self.callBack
    QuestNewMapRewardLayer.super.closeUI(self,function ()
        if type == 1 and callBack then
            callBack()
        end
    end)
end

function QuestNewMapRewardLayer:afterGainStarReward(params)
    if params.type == "success" then
        G_GetMgr(ACTIVITY_REF.QuestNew):resetChapterStarPrizesRememberData(self.m_chapterId)
        self:collectAction()
    else
        self.m_bTouch = false
    end
end

return QuestNewMapRewardLayer
