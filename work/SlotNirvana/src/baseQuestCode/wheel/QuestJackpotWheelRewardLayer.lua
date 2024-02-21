--[[
    结算界面
]]
local QuestJackpotWheelRewardLayer = class("QuestJackpotWheelRewardLayer", BaseLayer)

function QuestJackpotWheelRewardLayer:initDatas(_rewardCoins, _rewardGems, _rewardItems, _over,_layerType)
    self.m_rewardCoins = _rewardCoins
    self.m_rewardGems = _rewardGems
    self.m_rewardItems = _rewardItems
    self.m_over = _over
    self.m_layerType = _layerType

    local csb_path = QUEST_RES_PATH.QuestJackpotWheelRewardLayer_Normal
    if self.m_layerType == 2 then
        csb_path = QUEST_RES_PATH.QuestJackpotWheelRewardLayer_Mini
    elseif self.m_layerType == 3 then
        csb_path = QUEST_RES_PATH.QuestJackpotWheelRewardLayer_Major
    elseif self.m_layerType == 4 then
        csb_path = QUEST_RES_PATH.QuestJackpotWheelRewardLayer_Grand
    end
    
    self:setLandscapeCsbName(csb_path)

    self:setPauseSlotsEnabled(true)
end

function QuestJackpotWheelRewardLayer:playSelfSound()
    local soundPath = "Activity_FlamingoJackpot/Activity/sound/Coins.mp3"
    if self.m_layerType == 2 then
        soundPath = "QuestSounds/Quest_wheel_MINI.mp3"
    elseif self.m_layerType == 3 then
        soundPath = "QuestSounds/Quest_wheel_MAJOR.mp3"
    elseif self.m_layerType == 4 then
        soundPath = "QuestSounds/Quest_wheel_GRAND.mp3"
    end
    gLobalSoundManager:playSound(soundPath)
end

function QuestJackpotWheelRewardLayer:initCsbNodes()
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_spCoin = self:findChild("sp_coins")
    self.m_lbCoin = self:findChild("lb_num")
    self.m_nodeItems = self:findChild("node_reward")
end

function QuestJackpotWheelRewardLayer:initView()
    self:initCoins()
    self:initItems()
end

function QuestJackpotWheelRewardLayer:initCoins()
    if self.m_layerType < 2 then
        return
    end
    self.m_lbCoin:setString(util_formatCoins(self.m_rewardCoins, 32))
    local UIList = {}
    if self.m_spCoin then
        UIList[#UIList + 1] = {node = self.m_spCoin, scale = 0.9}
        UIList[#UIList + 1] = {node = self.m_lbCoin, scale = 0.71, alignX = 3, alignY = 2}
        util_alignCenter(UIList, nil, 800)
    else
        self:updateLabelSize({label = self.m_lbCoin, sx = 0.84, sy = 0.84}, 800)
    end
end

function QuestJackpotWheelRewardLayer:initItems()
    if not self.m_nodeItems then
        return
    end
    local rewardDataList = {}
    if self.m_layerType < 2 and self.m_rewardCoins and self.m_rewardCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_rewardCoins)
        if itemData then
            table.insert(rewardDataList, itemData)
        end
    end
    if self.m_rewardGems and self.m_rewardGems > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Gem", self.m_rewardGems)
        if itemData then
            table.insert(rewardDataList, itemData)
        end
    end
    if self.m_rewardItems and #self.m_rewardItems > 0 then
        for i=1,#self.m_rewardItems do
            local itemData = self.m_rewardItems[i]
            if string.find(itemData.p_icon, "CashBack") then -- cashback
                itemData:setTempData({p_mark = {{ITEM_MARK_TYPE.NONE}}})
            end
            if string.find(itemData.p_icon, "Coupon") then -- 促销优惠券
                itemData:setTempData({p_mark = {{ITEM_MARK_TYPE.NONE}}})
            end
            if string.find(itemData.p_icon, "club_pass_") then -- 高倍场体验卡
                itemData:setTempData({p_num = 1})
            end
            table.insert(rewardDataList, itemData)
        end
    end
    local propNode = gLobalItemManager:addPropNodeList(rewardDataList, ITEM_SIZE_TYPE.REWARD)
    if propNode then
        self.m_nodeItems:addChild(propNode)
    end
end

function QuestJackpotWheelRewardLayer:flyCoins(_over)
    local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))

    -- local serverCoins = globalData.userRunData.coinNum
    -- local topShowCoins = globalData.topUICoinCount
    -- print("QuestJackpotWheelRewardLayer serverCoins, topShowCoins = ", serverCoins, topShowCoins)

    -- 先还原
    local topTargetCoins = globalData.userRunData.coinNum - self.m_rewardCoins
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = topTargetCoins, isPlayEffect = false})

    local flyList = {}
    if self.m_rewardCoins and self.m_rewardCoins > 0 then
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_rewardCoins, startPos = startPos})
    end
    if self.m_rewardGems and self.m_rewardGems > 0 then
        table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_rewardGems, startPos = startPos})
    end
    if #flyList > 0 then
        G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, _over)
    else
        if _over then
            _over()
        end
    end
end

function QuestJackpotWheelRewardLayer:playShowAction()
    self:playSelfSound()
    QuestJackpotWheelRewardLayer.super.playShowAction(self, "start")
end

function QuestJackpotWheelRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestJackpotWheelRewardLayer:onEnter()
    QuestJackpotWheelRewardLayer.super.onEnter(self)
end

function QuestJackpotWheelRewardLayer:closeUI(_over)
    QuestJackpotWheelRewardLayer.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            if self.m_over then
                self.m_over()
            end
        end
    )
end

function QuestJackpotWheelRewardLayer:clickFunc(sender)
    if self:isShowing() then
        return
    end
    if self:isHiding() then
        return
    end
    local name = sender:getName()
    if name == "btn_collect" then
        if self.m_flying then
            return
        end
        self.m_flying = true
        self:flyCoins(
            function()
                local func = function ()
                    if not tolua.isnull(self) then
                        self:closeUI()
                    end
                end

                if CardSysManager:needDropCards("Quest Jackpot Wheel Award") then
                    CardSysManager:doDropCards("Quest Jackpot Wheel Award", func)
                else
                    func()
                end
            end
        )
    end
end


-- function QuestJackpotWheelRewardLayer:playHideAction()
--     local userDefAction = function(callFunc)
--         self:runCsbAction(
--             "over",
--             false,
--             function()
--                 if callFunc then
--                     callFunc()
--                 end
--             end,
--             60
--         )
--     end
--     QuestJackpotWheelRewardLayer.super.playHideAction(self, userDefAction)
-- end
return QuestJackpotWheelRewardLayer
