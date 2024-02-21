--[[
    打开鲨鱼提示界面
]]
local CSDefeatLayer = class("CSDefeatLayer", BaseLayer)

function CSDefeatLayer:initDatas(_levelIndex, _overCall)
    self.m_levelIndex = _levelIndex
    self.m_overCall = _overCall
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_TipLayer.csb")
end

function CSDefeatLayer:initCsbNodes()
    self.m_lbDes = self:findChild("sp_des")
    self.m_nodeRewards = self:findChild("node_rewards")
    self.m_nodeMonster = self:findChild("Node_NPC")
    self.m_nodeGems = self:findChild("Node_Gems")
    self.m_nodeFree = self:findChild("Node_1STFREE")
    self.m_btnGem = self:findChild("btn_Gem")
    self.m_panelGiveup = self:findChild("Panel_giveup")
    self:addClick(self.m_panelGiveup)
end

function CSDefeatLayer:initView()
    self:initTitleDes()
    self:initGems()
    self:initFree()
    self:initPrice()
    self:initRewards()
    self:initMonster()
    self:initMonthlyCardIcon()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CSDefeatLayer:initTitleDes()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local count = GameData:getLevelCount()
    local labelString = gLobalLanguageChangeManager:getStringByKey("CSDefeatLayer:lb_des")
    self.m_lbDes:setString(string.format(labelString, count - self.m_levelIndex))
end

function CSDefeatLayer:initGems()
    -- self.m_gem = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainGem")
    -- self.m_nodeGems:addChild(self.m_gem)
end

function CSDefeatLayer:initFree()
    if self:isFree() then
        local freeTip = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_Bubble_1stFree.csb")
        self.m_nodeFree:addChild(freeTip)
        freeTip:playAction(
            "start",
            false,
            function()
                if not tolua.isnull(freeTip) then
                    freeTip:playAction("idle", true, nil, 60)
                end
            end,
            60
        )
    end
end

function CSDefeatLayer:initPrice()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local levelCfg = GameData:getLevelConfigByIndex(self.m_levelIndex)
    assert(levelCfg ~= nil, "levelCfg is nil")
    local costGem = levelCfg:getNeedGems() or 0

    local labelString = gLobalLanguageChangeManager:getStringByKey("CSDefeatLayer:btn_Gem")
    -- self:setButtonLabelContent("btn_Gem", labelString, "defeathim")
    self:setButtonLabelContent("btn_Gem", costGem)
    local canFree = GameData:getCanFree()
    if not self:isFree() and canFree then
        local isFirstEntrySharkGame = G_GetMgr(G_REF.MonthlyCard):isFirstEntrySharkGame()
        if isFirstEntrySharkGame then
            G_GetMgr(G_REF.MonthlyCard):setFirstEntrySharkGame()
            local btn = self:getCommonButtonInfo("btn_Gem")
            local param = btn.param
            local labelInfo = param["label_1"]
            local actionList = {}
            actionList[#actionList + 1] = cc.DelayTime:create(15 / 60)
            actionList[#actionList + 1] = cc.FadeTo:create(30 / 60, 0)
            actionList[#actionList + 1] = cc.CallFunc:create(function()
                self:setButtonLabelContent("btn_Gem", "FREE")
            end)
            actionList[#actionList + 1] = cc.FadeTo:create(20 / 60, 255)
            labelInfo.node:runAction(cc.Sequence:create(actionList))
        else
            self:setButtonLabelContent("btn_Gem", "FREE")
        end
    end
end

function CSDefeatLayer:initRewards()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local winRewardData = GameData:getWinRewardData()
    if not winRewardData then
        return
    end
    self.m_itemNodeList = {}

    local coinNum = winRewardData:getCoins()
    if coinNum and coinNum > 0 then
        local tempData = gLobalItemManager:createLocalItemData("Coins", coinNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        self:createRewardNode(tempData)
    end

    local gemNum = winRewardData:getGems()
    if gemNum and gemNum > 0 then
        local tempData = gLobalItemManager:createLocalItemData("Gem", gemNum, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        self:createRewardNode(tempData)
    end

    local itemDatas = winRewardData:getMergeItems()
    if itemDatas and #itemDatas > 0 then
        for i = 1, #itemDatas do
            local tempData = itemDatas[i]
            if tempData.p_type == "Package" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_ADD}})
            end
            self:createRewardNode(tempData)
        end
    end

    util_alignCenter(self.m_itemNodeList, nil, 620)
end

function CSDefeatLayer:createRewardNode(_tempData)
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    local itemNode = gLobalItemManager:createRewardNode(_tempData, ITEM_SIZE_TYPE.REWARD)
    assert(itemNode ~= nil, "ItemNode is null, itemData.p_icon = " .. _tempData.p_icon)
    self.m_nodeRewards:addChild(itemNode)
    local nodeData = {node = itemNode, itemData = _tempData, scale = 1, size = cc.size(width, 0), anchor = cc.p(0.5, 0.5)}
    self.m_itemNodeList[#self.m_itemNodeList + 1] = nodeData
end

function CSDefeatLayer:initMonster()
    local monster = util_spineCreate(CardSeekerCfg.otherPath .. "spine/npc", true, true, 1)
    monster:setScale(0.5)
    self.m_nodeMonster:addChild(monster)
    util_spinePlay(monster, "idle", true)
end

function CSDefeatLayer:initMonthlyCardIcon() -- 购买豪华版月卡显示月卡icon
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local canFree = GameData:getCanFree()
    if canFree then
        local nodeMonthly = self:findChild("node_monthly")
        local monthlyCardIcon = G_GetMgr(G_REF.MonthlyCard):getMonthlyCardIconDeluxe()
        if nodeMonthly and monthlyCardIcon then
            nodeMonthly:addChild(monthlyCardIcon)
        end
    end
end

function CSDefeatLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CSDefeatLayer:canClick()
    if self.m_isRequestingCostGem then
        return false
    end
    if self.m_isRequestingGiveUp then
        return false
    end
    return true
end

function CSDefeatLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_Gem" then
        local GameData = self:getTSGameData()
        if not GameData then
            return
        end
        if self:isFree() then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self.m_isRequestingCostGem = true
            G_GetMgr(G_REF.CardSeeker):requestCostGem()
        else
            local levelCfg = GameData:getLevelConfigByIndex(self.m_levelIndex)
            assert(levelCfg ~= nil, "levelCfg is nil")
            local costGem = levelCfg:getNeedGems() or 0
            if costGem > globalData.userRunData.gemNum then
                -- 打开商城钻石界面
                local params = {activityName = "CSDefeatLayer", log = true, shopPageIndex = 2}
                G_GetMgr(G_REF.Shop):showMainLayer(params)
            else
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                self.m_isRequestingCostGem = true
                G_GetMgr(G_REF.CardSeeker):requestCostGem()
            end
        end
    elseif name == "Panel_giveup" then
        local GameData = self:getTSGameData()
        if not GameData then
            return
        end
        local winRewardData = GameData:getWinRewardData()
        if not winRewardData then
            return
        end
        self.m_isRequestingGiveUp = true
        self.m_allRewardDatas = clone(winRewardData)
        gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/clickGiveup.mp3")
        G_GetMgr(G_REF.CardSeeker):requestGiveUp()
    end
end

function CSDefeatLayer:registerListener()
    CSDefeatLayer.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function()
            self:closeUI(
                function()
                    if not tolua.isnull(self) then
                        if self.m_overCall then
                            self.m_overCall()
                        end
                    end
                end
            )
        end,
        ViewEventType.CARD_SEEKER_REQUEST_COSTGEM
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            self:closeUI(
                function()
                    if not tolua.isnull(self) then
                        G_GetMgr(G_REF.CardSeeker):showLoseLayer(self.m_allRewardDatas, self.m_overCall)
                    end
                end
            )
        end,
        ViewEventType.CARD_SEEKER_REQUEST_GIVEUP
    )
end

function CSDefeatLayer:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

function CSDefeatLayer:isFree()
    local data = self:getTSGameData()
    if data and data:getFirstBuy() then
        return false
    end
    return true
end

return CSDefeatLayer
