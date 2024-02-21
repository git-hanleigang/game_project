--[[
    外部关联系统展示
    弹框
]]
local BaseView = util_require("base.BaseView")
local shopOuterPopUI = class("shopOuterPopUI", BaseView)
function shopOuterPopUI:initUI(_popType, _num, _index)
    self.m_popType = _popType
    self.m_num = _num
    self.m_index = _index

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    local csbName = nil
    if self.m_popType == "LUCKY_CHALLENGE" then
        csbName = "Shop_Res/Gem/GemPopup/Gem_SkipMission.csb"
    elseif self.m_popType == "DAILY_MISSION" then
        csbName = "Shop_Res/Gem/GemPopup/Gem_SkipMission.csb"
    elseif self.m_popType == "QUEST" then
        csbName = "Shop_Res/Gem/GemPopup/Gem_SkipMission.csb"
    elseif self.m_popType == "BATTLE_PASS" then
        csbName = "Shop_Res/Gem/GemPopup/Gem_BattlePassLevelUp.csb"
    end
    self:createCsbNode(csbName, isAutoScale)
    util_portraitAdaptPortrait(self.m_csbNode)

    self.m_rootNode = self:findChild("root")
    -- self.m_numLB = self:findChild("BitmapFontLabel_1")
    self.m_gemLBDes = self:findChild("font_gem")
    self.m_gemLB = self:findChild("font_gemNum")

    self:runCsbAction("idle")
    self:commonShow(
        self.m_rootNode,
        function()
            self:runCsbAction("idle", false)
        end
    )
    self:updateNum()
end

function shopOuterPopUI:updateNum()
    self:setButtonLabelContent("Button_1", self.m_num)
    -- self.m_numLB:setString(self.m_num)
    -- self:updateLabelSize({label = self.m_numLB, sx = 0.7, sy = 0.7}, 113)

    self.m_gemLB:setString(util_formatCoins(tonumber(globalData.userRunData.gemNum), 6))
    -- self:updateLabelSize({label = self.m_gemLB, sx = 1, sy = 1}, 124)

    local uiList = {}
    uiList[#uiList + 1] = {node = self.m_gemLBDes, size = self.m_gemLBDes:getContentSize(), anchor = cc.p(0.5, 0.5)}
    uiList[#uiList + 1] = {node = self.m_gemLB, size = self.m_gemLB:getContentSize(), anchor = cc.p(0.5, 0.5)}
    util_alignCenter(uiList)

    if globalData.userRunData.gemNum < self.m_num then
        self.m_gemLB:setColor(cc.c3b(255, 0, 0))
    else
        self.m_gemLB:setColor(cc.c3b(255, 255, 255))
    end
end

function shopOuterPopUI:clickFunc(sender)
    local name = sender:getName()
    if self.m_closed then
        return
    end
    if name == "Button_1" then
        if globalData.userRunData.gemNum < self.m_num then
            local params = {shopPageIndex = 2 , dotKeyType = name, dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
            G_GetMgr(G_REF.Shop):showMainLayer(params)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SHOPOUTERPOPUI_CLOSE, {popType = self.m_popType, index = self.m_index})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_PASS_BUTTON, {popType = self.m_popType, index = self.m_index})
        end

        self:closeUI()
    elseif name == "btn_Close" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_SHOPOUTERPOPUI_CLOSE, {popType = self.m_popType, index = self.m_index})
        self:closeUI()
    end
end

function shopOuterPopUI:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:commonHide(
        self.m_rootNode,
        function()
            self:removeFromParent()
        end
    )
end

function shopOuterPopUI:onEnter()
    -- 零点时，关闭此弹板
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_ZERO_CLOSE_GEM_POP_UI
    )
end

function shopOuterPopUI:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return shopOuterPopUI
