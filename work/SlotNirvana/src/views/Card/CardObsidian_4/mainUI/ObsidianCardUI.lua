--[[
    特殊卡册-购物主题
]]
local ObsidianCardUI = class("ObsidianCardUI", BaseLayer)

function ObsidianCardUI:ctor()
    ObsidianCardUI.super.ctor(self)
end

function ObsidianCardUI:getCsbPath()
    return string.format("CardRes/CardObsidian_%s/csb/main/ObsidianAlbum_layer.csb", self.m_seasonId)
end

function ObsidianCardUI:initDatas(_seasonId, _callfunc, _index)
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(_seasonId)
    assert(data ~= nil, "ObsidianCard data is nil")

    self.m_seasonId = _seasonId or data:getCurAlbumID()
    self.m_callfunc = _callfunc
    self.m_pageShowIndex = _index or 1
    self.m_isHistory = data:isHistorySeason(self.m_seasonId)

    local cards = data:getCards()
    self.m_pageNum = math.floor(#cards / 10 + 0.5)
    self:setLandscapeCsbName(self:getCsbPath())
end

function ObsidianCardUI:initCsbNodes()
    self.m_nodeRoot = self:findChild("root")

    self.m_nodeTitle = self:findChild("node_title")
    self.m_nodeChips = self:findChild("node_chips")
    self.m_nodeTime = self:findChild("node_time")

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

function ObsidianCardUI:initView()
    self:initTitle()
    self:initChips()
    self:initTabs()
    self:updateSwitchBtns()
    if self.m_isHistory == false then
        self:initTime()
    end
end

function ObsidianCardUI:initTitle()
    self.m_title = util_createView(self:getTitleLuaPath(), self.m_pageShowIndex, self.m_seasonId)
    self.m_nodeTitle:addChild(self.m_title)
end

function ObsidianCardUI:initChips()
    self.m_chips = util_createView(self:getChipsLuaPath(), self.m_pageShowIndex, self.m_seasonId)
    self.m_nodeChips:addChild(self.m_chips)
end

function ObsidianCardUI:initTime()
    self.m_time = util_createView(self:getTimeLuaPath())
    self.m_nodeTime:addChild(self.m_time)
end

function ObsidianCardUI:initTabs()
    local UIList = {}
    self.m_tabs = {}
    for i = 1, self.m_pageNum do
        local tab = util_createView(self:getTabLuaPath(), i)
        self.m_nodeTabs:addChild(tab)
        self.m_tabs[i] = tab
        tab:updateUI(self.m_pageShowIndex)
        -- local originPos = -(self.m_pageNum / 2) - 0.5 * tab:getTabSize().width + tab:getTabSize().width * (i - 1)
        -- tab:setPositionX(originPos)
        UIList[i] = {node = tab, size = tab:getTabSize(), anchor = cc.p(0.5, 0.5)}
    end
    util_alignCenter(UIList)
    self:updateTabs()
end

function ObsidianCardUI:updateTabs()
    for i = 1, self.m_pageNum do
        self.m_tabs[i]:updateUI(self.m_pageShowIndex)
    end
end

function ObsidianCardUI:updateSwitchBtns()
    self.m_btnLeft:setVisible(self.m_pageShowIndex > 1)
    self.m_btnRight:setVisible(self.m_pageShowIndex < self.m_pageNum)
end

function ObsidianCardUI:addPage()
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
    self.m_chips:updateCells(
        self.m_pageShowIndex,
        function()
            self.m_bScrolling = false
        end
    )
end

function ObsidianCardUI:delPage()
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
    self.m_chips:updateCells(
        self.m_pageShowIndex,
        function()
            self.m_bScrolling = false
        end
    )
end

function ObsidianCardUI:canClick()
    return true
end

-- 点击事件 --
function ObsidianCardUI:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
        G_GetMgr(G_REF.ObsidianCard):showInfoLayer(self.m_seasonId)
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

function ObsidianCardUI:baseTouchEvent(sender, eventType)
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
                self:clickFunc(sender)
                self:clickSound(sender)
            end
        end
    elseif eventType == ccui.TouchEventType.canceled then
        if not self.clickEndFunc then
            return
        end
        self:clickEndFunc(sender, eventType)
    end
end

function ObsidianCardUI:onShowedCallFunc()
    G_GetMgr(G_REF.ObsidianCard):hideNeedHideLayer("CardCollectionObsidianScrollUI")
    CardSysManager:hideCardAlbumView()
    if self.m_title then
        self.m_title:playStart()
    end
end

function ObsidianCardUI:onEnter()
    ObsidianCardUI.super.onEnter(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == G_REF.ObsidianCard and not self.m_isHistory then
                self:closeUI()
                self:closeOtherUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function ObsidianCardUI:closeUI(_over)
    if self.m_closed then
        _over()
        return
    end
    self.m_closed = true
    self.m_title:playOver()
    CardSysManager:showCardAlbumView()
    G_GetMgr(G_REF.ObsidianCard):showNeedHideLayer("CardCollectionObsidianScrollUI")
    ObsidianCardUI.super.closeUI(self, _over)
end

function ObsidianCardUI:closeOtherUI()
    local closeExtendKeyList = self:getCloseExtendKeyList()
    if closeExtendKeyList ~= nil then
        for k, v in ipairs(closeExtendKeyList) do
            local ui = gLobalViewManager:getViewByExtendData(v)
            if ui ~= nil and ui.removeFromParent ~= nil then
                ui:removeFromParent()
            end
        end
    end
end

-- >>> 需要子类重写的函数 ------------------------------------------------------------------
function ObsidianCardUI:getTitleLuaPath()
    return "views.Card.CardObsidian_4.mainUI.ObsidianCardTitle"
end

function ObsidianCardUI:getChipsLuaPath()
    return "views.Card.CardObsidian_4.mainUI.ObsidianCardChips"
end

function ObsidianCardUI:getTabLuaPath()
    return "views.Card.CardObsidian_4.mainUI.ObsidianCardTab"
end

function ObsidianCardUI:getTimeLuaPath()
    return "views.Card.CardObsidian_4.mainUI.ObsidianCardTime"
end

--连带关闭的界面
function ObsidianCardUI:getCloseExtendKeyList()
    return {"BigCardLayer"}
end

return ObsidianCardUI
