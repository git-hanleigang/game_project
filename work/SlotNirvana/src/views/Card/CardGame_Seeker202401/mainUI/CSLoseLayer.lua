--[[
   失败界面
]]
local CSLoseLayer = class("CSLoseLayer", BaseLayer)

function CSLoseLayer:initDatas(_rewardDatas, _overCall)
    self.m_rewardDatas = _rewardDatas
    self.m_overCall = _overCall
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_RewardLayer_Lose.csb")
end

function CSLoseLayer:initCsbNodes()
    self.m_nodeRewards = self:findChild("node_rewards")
end

function CSLoseLayer:initView()
    self:initRewards()
    util_setCascadeOpacityEnabledRescursion(self, true)
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/lose.mp3")
    self:runCsbAction("start", false, function()
        self:runCsbAction("over", false, function()
            gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/lose_monster.mp3")
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end, 60)
    end, 60)
    -- performWithDelay(
    --     self,
    --     function()
    --         gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/lose_monster.mp3")
    --         if not tolua.isnull(self) then
    --             self:closeUI()
    --         end
    --     end,
    --     60 / 60
    -- )
end

function CSLoseLayer:initRewards()
    if not self.m_rewardDatas then
        return
    end
    self.m_itemNodeList = {}
    local coinNum = self.m_rewardDatas:getCoins()
    if coinNum and coinNum > 0 then
        local tempData = gLobalItemManager:createLocalItemData("Coins", coinNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        self:createRewardNode(tempData)
    end

    local gemNum = self.m_rewardDatas:getGems()
    if gemNum and gemNum > 0 then
        local tempData = gLobalItemManager:createLocalItemData("Gem", gemNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        self:createRewardNode(tempData)
    end

    local itemDatas = self.m_rewardDatas:getMergeItems()
    if itemDatas and #itemDatas > 0 then
        for i = 1, #itemDatas do
            local tempData = itemDatas[i]
            if tempData.p_type == "Package" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
            end
            self:createRewardNode(tempData)
        end
    end
    util_alignCenter(self.m_itemNodeList, nil, 800)
end

function CSLoseLayer:createRewardNode(_tempData)
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    local itemNode = gLobalItemManager:createRewardNode(_tempData, ITEM_SIZE_TYPE.REWARD)
    self.m_nodeRewards:addChild(itemNode)
    local nodeData = {node = itemNode, itemData = _tempData, size = cc.size(width, 0), scale = 1, anchor = cc.p(0.5, 0.5)}
    self.m_itemNodeList[#self.m_itemNodeList + 1] = nodeData
end

-- function CSLoseLayer:disappearReward(doFunc)
--     gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/lose.mp3")
--     local actionList = {}
--     actionList[#actionList + 1] = cc.EaseSineOut:create(cc.ScaleTo:create(6 / 60, 1.02))
--     local act1 = cc.EaseSineInOut:create(cc.ScaleTo:create(14 / 60, 0.9))
--     local act2 = cc.FadeTo:create(10 / 60, 0)
--     local delay = cc.DelayTime:create(4 / 60)
--     local delaySeq = cc.Sequence:create(delay, act2)
--     actionList[#actionList + 1] = cc.Spawn:create(act1, delaySeq)
--     if doFunc then
--         actionList[#actionList + 1] = cc.CallFunc:create(doFunc)
--     end
--     local seq = cc.Sequence:create(actionList)
--     self.m_nodeRewards:runAction(seq)
-- end

function CSLoseLayer:onShowedCallFunc()
    -- util_performWithDelay(
    --     self,
    --     function()
    --         self:disappearReward(
    --             function()
    --                 if not tolua.isnull(self) then
    --                     self:closeUI()
    --                 end
    --             end
    --         )
    --     end,
    --     2
    -- )
end

function CSLoseLayer:closeUI(_over)
    CSLoseLayer.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            if self.m_overCall then
                self.m_overCall()
            end
            local mainUI = gLobalViewManager:getViewByName("CSMainLayer")
            if not tolua.isnull(mainUI) then
                mainUI:closeUI(
                    function()
                        G_GetMgr(G_REF.CardSeeker):exitGame()
                    end
                )
            else
                G_GetMgr(G_REF.CardSeeker):exitGame()
            end
        end
    )
end

return CSLoseLayer
