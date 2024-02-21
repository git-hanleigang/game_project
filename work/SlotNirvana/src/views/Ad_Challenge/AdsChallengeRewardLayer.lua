----
local AdsChallengeRewardLayer = class("AdsChallengeRewardLayer", BaseLayer)

function AdsChallengeRewardLayer:ctor()
    AdsChallengeRewardLayer.super.ctor(self)

    local csb_path = ""
    self:setLandscapeCsbName("Ad_Challenge/csb/Ad_Challenge_Reward.csb")
    self:setPortraitCsbName("Ad_Challenge/csb/Ad_Challenge_Reward_Shu.csb")

    self:setExtendData("AdsChallengeRewardLayer")
end
function AdsChallengeRewardLayer:initDatas(reward)
    self.m_rewards = reward
end
-- 弹窗动画
function AdsChallengeRewardLayer:playShowAction()
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
    AdsChallengeRewardLayer.super.playShowAction(self, userDefAction)
end

function AdsChallengeRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function AdsChallengeRewardLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_item")
    self.m_btnCollect = self:findChild("btn_collect")
end


function AdsChallengeRewardLayer:initView()

    self:initRewards()
    
end

function AdsChallengeRewardLayer:initRewards()
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
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(self.m_rewards.coins), {p_limit = 3})
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

function AdsChallengeRewardLayer:onClickMask()
    if self.m_bTouch then
        return
    end
    self.m_bTouch = true
    self:collectAction()
end

function AdsChallengeRewardLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_collect" or name == "btn_close" then
        if self.m_bTouch then
            return
        end
        self.m_bTouch = true
        self:collectAction()
    end
end

function AdsChallengeRewardLayer:collectAction()
    if not self.m_flyCoins or self.m_flyCoins == 0 then
        self:closeFunc()
        return
    end
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local view = gLobalViewManager:getFlyCoinsView()
    view:pubShowSelfCoins(true) -- 不要做纠错处理
    view:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_flyCoins, handler(self, self.closeFunc))
end

function AdsChallengeRewardLayer:closeFunc()
    
    local propsBagList = self.m_rewards.propsBagList

    local popNextLayer = function()
        if propsBagList and next(propsBagList) then
            local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
            mergeManager:popMergePropsBagRewardPanel(
                self.m_rewards.propsBagList,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshBottom = true})
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

return AdsChallengeRewardLayer
