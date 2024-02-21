--[[
    打开鲨鱼提示界面
]]
local TEST_FREE = false
local CSDefeatLayer = class("CSDefeatLayer", BaseLayer)

function CSDefeatLayer:initDatas(_levelIndex, _overCall)
    self.m_levelIndex = _levelIndex
    self.m_overCall = _overCall
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_TipLayer.csb")
end

function CSDefeatLayer:initCsbNodes()
    self.m_lbDes = self:findChild("sp_des")
    self.m_nodeRewards = self:findChild("node_rewards")
    self.m_nodeGems = self:findChild("Node_Gems")
    -- self.m_nodeFree = self:findChild("Node_1STFREE")
    
    self.m_nodeBtnGem = self:findChild("node_btnGem")
    self.m_btnGem = self:findChild("btn_Gem")
    self.m_panelGiveup = self:findChild("Panel_giveup")
    self.m_lbseek = self:findChild("seek_lbgem")
    self.m_loser = self:findChild("sekk_hs")
    self:addClick(self.m_panelGiveup)
    
    self.m_nodeGuide = self:findChild("node_gems_guide")
end

function CSDefeatLayer:initView()
    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/Seeker_tanban_pop.mp3")
    self:initTitleDes()
    self:initGems()
    -- self:initFree()
    self:initPrice()
    self:initRewards()
    -- self:initMonthlyCardIcon()
    self.m_lbseek:setString(globalData.userRunData.gemNum)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CSDefeatLayer:initTitleDes()
    -- local GameData = self:getTSGameData()
    -- if not GameData then
    --     return
    -- end
    -- local count = GameData:getLevelCount()
    local count = 20
    local labelString = gLobalLanguageChangeManager:getStringByKey("CSDefeatLayer:lb_des")
    self.m_lbDes:setString(string.format(labelString, count - self.m_levelIndex))
end

function CSDefeatLayer:initGems()
    -- self.m_gem = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainGem")
    -- self.m_nodeGems:addChild(self.m_gem)
end

-- function CSDefeatLayer:initFree()
--     if self:isFree() then
--         local freeTip = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_Bubble_1stFree.csb")
--         self.m_nodeFree:addChild(freeTip)
--         freeTip:playAction(
--             "start",
--             false,
--             function()
--                 if not tolua.isnull(freeTip) then
--                     freeTip:playAction("idle", true, nil, 60)
--                 end
--             end,
--             60
--         )
--     end
-- end

function CSDefeatLayer:initPrice()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local levelCfg = GameData:getLevelConfigByIndex(self.m_levelIndex)
    if levelCfg then
        local costGem = levelCfg:getNeedGems() or 0
        if costGem == 0 or self:isFree() then
            self:setButtonLabelContent("btn_Gem", "FREE")
        else
            self:setButtonLabelContent("btn_Gem", costGem)
        end
        if globalData.userRunData.gemNum < costGem then
            self.m_loser:setVisible(true)
        else
            self.m_loser:setVisible(false)
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

-- function CSDefeatLayer:initMonthlyCardIcon() -- 购买豪华版月卡显示月卡icon
--     local GameData = self:getTSGameData()
--     if not GameData then
--         return
--     end
--     local canFree = GameData:getCanFree()
--     if canFree then
--         local nodeMonthly = self:findChild("node_monthly")
--         local monthlyCardIcon = G_GetMgr(G_REF.MonthlyCard):getMonthlyCardIconDeluxe()
--         if nodeMonthly and monthlyCardIcon then
--             nodeMonthly:addChild(monthlyCardIcon)
--         end
--     end
-- end

function CSDefeatLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)

    -- 首次免费复活，强制引导
    self:checkFirstFreeGuide()
end

function CSDefeatLayer:checkFirstFreeGuide()
    if self:isFree() then
        self:startGuide()
    end
end

function CSDefeatLayer:startGuide()
    -- 增加黑色遮罩
    self.m_layout = self:createLayout()
    self.m_layout:setBackGroundColorOpacity(190)
    self.m_layout:setTouchEnabled(true)
    self.m_layout:setSwallowTouches(true)
    util_setCascadeOpacityEnabledRescursion(self, true)

    
    -- local btnSize = self.m_btnGem:getContentSize()
    -- local LPos = util_getConvertNodePos(self.m_btnGem, self.m_layout)
    local worldPos = self.m_btnGem:getParent():convertToWorldSpace(cc.p(self.m_btnGem:getPosition()))
    local LPos = self.m_layout:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    local rPos = cc.p(LPos.x, LPos.y)
    -- 提高按钮层级
    util_changeNodeParent(self.m_layout, self.m_btnGem, 1)
    self.m_btnGem:setPosition(rPos)
    local scale = math.min(1, self:getUIScalePro())
    local gemScale = 1
    self.m_btnGem:setScale(scale*gemScale)
    -- 显示手指
    local finger = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_Gems_Guide.csb")
    self.m_layout:addChild(finger, 2)
    finger:playAction("idle", true, nil, 60)
    finger:setPosition(rPos) 
end

function CSDefeatLayer:overGuide()
    if self.m_layout then
        -- 恢复按钮层级
        util_changeNodeParent(self.m_nodeBtnGem, self.m_btnGem, 1)
        self.m_btnGem:setPosition(cc.p(0, 0))
        self.m_btnGem:setScale(1)
        -- 删除黑色遮罩
        self.m_layout:removeFromParent()
        self.m_layout = nil
    end
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
        if self:isFree() then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:overGuide()
            self.m_isRequestingCostGem = true
            G_GetMgr(G_REF.CardSeeker):requestCostGem()
        else
            local GameData = self:getTSGameData()
            if not GameData then
                return
            end
            local canFree = GameData:getCanFree()
            local levelCfg = GameData:getLevelConfigByIndex(self.m_levelIndex)
            assert(levelCfg ~= nil, "levelCfg is nil")
            local costGem = levelCfg:getNeedGems() or 0
            if costGem > globalData.userRunData.gemNum and not canFree then
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

    gLobalNoticManager:addObserver(
        self,
        function()
            self.m_lbseek:setString(globalData.userRunData.gemNum)
            local GameData = self:getTSGameData()
            local levelCfg = GameData:getLevelConfigByIndex(self.m_levelIndex)
            assert(levelCfg ~= nil, "levelCfg is nil")
            local costGem = levelCfg:getNeedGems() or 0
            if globalData.userRunData.gemNum < costGem then
                self.m_loser:setVisible(true)
            else
                self.m_loser:setVisible(false)
            end
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )
end

function CSDefeatLayer:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

function CSDefeatLayer:isFree()
    if TEST_FREE then
        return true
    end
    -- 建坤：新手期特殊处理，如果是第一次免费，将章节复活的钻石置为0了
    local GameData = self:getTSGameData()
    if GameData then
        local levelCfg = GameData:getLevelConfigByIndex(self.m_levelIndex)
        if levelCfg then
            local costGem = levelCfg:getNeedGems() or 0
            if costGem == 0 then
                return true
            end
        end
    end
    return false
    -- if data and data:getFirstBuy() then
    --     return false
    -- end
    -- return true
end

function CSDefeatLayer:createLayout()
    local tLayout = ccui.Layout:create()
    self.m_nodeGuide:addChild(tLayout)
    -- local size = self.m_nodeRoot:getContentSize()
    local pro = self:getUIScalePro()
    if pro >= 1 then
        pro = 1
    end
    tLayout:setName("touch")
    tLayout:setTouchEnabled(false)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setContentSize(cc.size(display.width/pro, display.height/pro))
    tLayout:setPosition(cc.p(0, 0))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(0)
    return tLayout
end

return CSDefeatLayer
