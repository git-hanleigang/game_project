--[[
    特殊卡册
]]
local CardSpecialClanUI = class("CardSpecialClanUI", BaseLayer)

function CardSpecialClanUI:initDatas(_clanIndex)
    self.m_pageShowIndex = _clanIndex or 1

    -- local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    -- if not data then
    --     return
    -- end
    -- local clanData = data:getSpecialClanByIndex(self.m_pageShowIndex)
    -- if not clanData then
    --     return
    -- end
    -- local cards = clanData:getCards()
    -- self.m_pageNum = math.floor(#cards / CardSpecialClanCfg.QuestMagicClanCardNum + 0.5)

    self.m_pageNum = CardSpecialClanCfg.QuestMagicClanNum

    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()
    self.m_chipsLuaPath = "views.Card." .. themeName .. ".mainUI.CardSpecialClanChips"
    self.m_tabLuaPath = "views.Card." .. themeName .. ".mainUI.CardSpecialClanTab"
    self.m_titleLuaPath = "views.Card." .. themeName .. ".mainUI.CardSpecialClanTitle"
    self.m_guideCsbPath = "CardRes/" .. themeName .. "/csb/guide/MagicAlbum_Guide_%d.csb"
    self:setLandscapeCsbName("CardRes/" .. themeName .. "/csb/main/MagicClanMainLayer.csb")
end

function CardSpecialClanUI:initCsbNodes()
    self.m_nodeRoot = self:findChild("root")

    self.m_nodeTitle = self:findChild("node_title")
    self.m_nodeChips = self:findChild("node_chips")

    self.m_btnLeft = self:findChild("btn_left")
    self.m_btnRight = self:findChild("btn_right")

    self.m_PanelTouch = self:findChild("Panel_touch")
    self:addClick(self.m_PanelTouch)
    self.m_PanelTouch:setSwallowTouches(false)

    self.m_nodeTabs = self:findChild("node_tabs")
    self.m_nodeGuideMask = self:findChild("node_guide_mask")
    self.m_nodeGuides = {}
    for i = 1, 2 do
        self.m_nodeGuides[i] = self:findChild("node_guide_" .. i)
    end
end

function CardSpecialClanUI:initView()
    self:initTitle()
    self:initChips()
    self:initTabs()
    self:updateSwitchBtns()
end

function CardSpecialClanUI:initTitle()
    self.m_title = util_createView(self.m_titleLuaPath, self.m_pageShowIndex)
    self.m_nodeTitle:addChild(self.m_title)
    self.m_title:playStart()
end

function CardSpecialClanUI:initChips()
    self.m_chips = util_createView(self.m_chipsLuaPath, self.m_pageShowIndex)
    self.m_nodeChips:addChild(self.m_chips)
end

function CardSpecialClanUI:initTabs()
    local UIList = {}
    self.m_tabs = {}
    for i = 1, self.m_pageNum do
        local tab = util_createView(self.m_tabLuaPath, i)
        self.m_nodeTabs:addChild(tab)
        self.m_tabs[i] = tab
        UIList[i] = {node = tab, size = tab:getTabSize(), scale = 1, anchor = cc.p(0.5, 0.5)}
        tab:updateUI(self.m_pageShowIndex)
    end
    util_alignCenter(UIList)
end

function CardSpecialClanUI:updateTabs()
    for i = 1, self.m_pageNum do
        self.m_tabs[i]:updateUI(self.m_pageShowIndex)
    end
end

function CardSpecialClanUI:updateSwitchBtns()
    self.m_btnLeft:setVisible(self.m_pageShowIndex > 1)
    self.m_btnRight:setVisible(self.m_pageShowIndex < self.m_pageNum)
end

function CardSpecialClanUI:addPage()
    if self.m_bScrolling == true then
        return
    end
    if self.m_pageShowIndex >= self.m_pageNum then
        return
    end
    self.m_pageShowIndex = self.m_pageShowIndex + 1

    self.m_bScrolling = true
    self:updateSwitchBtns()
    self:updateTabs()
    self.m_title:updateUI(self.m_pageShowIndex)
    self.m_chips:updateCells(
        self.m_pageShowIndex,
        function()
            self.m_bScrolling = false
        end
    )
end

function CardSpecialClanUI:delPage()
    if self.m_bScrolling == true then
        return
    end
    if self.m_pageShowIndex == 1 then
        return
    end
    self.m_pageShowIndex = self.m_pageShowIndex - 1

    self.m_bScrolling = true
    self:updateSwitchBtns()
    self:updateTabs()
    self.m_title:updateUI(self.m_pageShowIndex)
    self.m_chips:updateCells(
        self.m_pageShowIndex,
        function()
            self.m_bScrolling = false
        end
    )
end

function CardSpecialClanUI:canClick()
    return true
end

-- 点击事件 --
function CardSpecialClanUI:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end

    if name == "btn_close" then
        CardSysManager:showCardAlbumView()
        self:closeUI()
    -- elseif name == "btn_info" then
    --     G_GetMgr(G_REF.CardSpecialClan):showInfoLayer()
    elseif name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:delPage()
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:addPage()
    elseif name == "touch_guide" then
        self:checkGuide()
    end
end

function CardSpecialClanUI:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:setButtonStatusByBegan(sender)
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:setButtonStatusByMoved(sender)
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc then
            return
        end
        self:setButtonStatusByEnd(sender)
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()

        local name = sender:getName()
        if name == "Panel_touch" then
            local offx = endPos.x - beginPos.x
            if offx > 50 then
                self:delPage()
            elseif offx < -50 then
                self:addPage()
            end
        else
            local offx = math.abs(endPos.x - beginPos.x)
            local offy = math.abs(endPos.y - beginPos.y)
            if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil then
                self:clickSound(sender)
                self:clickFunc(sender)
            end
        end
    elseif eventType == ccui.TouchEventType.canceled then
        if not self.clickEndFunc then
            return
        end
        self:clickEndFunc(sender, eventType)
    end
end

function CardSpecialClanUI:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardSpecialClanUI.super.playShowAction(self, "start")
end

function CardSpecialClanUI:onShowedCallFunc()
    CardSysManager:hideCardAlbumView()
    self:runCsbAction("idle", true, nil, 60)
end

function CardSpecialClanUI:onEnter()
    CardSpecialClanUI.super.onEnter(self)

    self:checkGuide()
end

function CardSpecialClanUI:closeUI(_over)
    if self.m_closed then
        return
    end
    self.m_closed = true
    CardSpecialClanUI.super.closeUI(self, _over)
end

function CardSpecialClanUI:showGuide(_index)
    local mask = self:createLayout()
    mask:setName("touch_guide")
    self.m_nodeGuideMask:addChild(mask)
    self:addClick(mask)
    local view = util_createView(string.format(self.m_guideCsbPath, _index))
    self.m_nodeGuides[_index]:addChild(view)
end

function CardSpecialClanUI:checkGuide()
    if not self.m_guideStep then
        self.m_guideStep = gLobalDataManager:getNumberByField("CardSpecialClanGuide_" .. globalData.userRunData.userUdid, 0)
    end
    self.m_guideStep = self.m_guideStep + 1
    if guideStep == 1 then
        self:showGuide(1)
        gLobalDataManager:setNumberByField("CardSpecialClanGuide_" .. globalData.userRunData.userUdid, 1)
    elseif guideStep == 2 then
        self:showGuide(2)
        gLobalDataManager:setNumberByField("CardSpecialClanGuide_" .. globalData.userRunData.userUdid, 2)
    end
end

function CardSpecialClanUI:createLayout()
    local tLayout = ccui.Layout:create()
    tLayout:setTouchEnabled(true)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(190)
    return tLayout
end

return CardSpecialClanUI
