--[[
Author: cxc
Date: 2021-03-04 16:44:26
LastEditTime: 2021-03-08 20:26:17
LastEditors: Please set LastEditors
Description: 侧边栏 菜单 layer
FilePath: /SlotNirvana/src/views/clan/ClanMoreMenuLayer.lua
--]]

local ClanMoreMenuLayer = class("ClanMoreMenuLayer", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

local ClickType = {
    SEARCH = 1,
    RULE = 2,
    USER_INFO = 3,
    FAQ = 4
}

function ClanMoreMenuLayer:initUI()
    local csbName = "Club/csd/Main/ClubMainLayerLeftMenu.csb"
    self:createCsbNode(csbName)

    self.m_clickType = nil
    self.m_actRunning = false
    self:setVisible(false) 

    gLobalNoticManager:addObserver(self, "resetClickTypeEvt", ClanConfig.EVENT_NAME.CLOSE_CLNA_PANEL_UI)
    gLobalNoticManager:addObserver(self, "resetClickTypeEvt", ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER) -- 关闭个人信息页
end


function ClanMoreMenuLayer:onEnter()
    ClanMoreMenuLayer.super.onEnter(self)

    -- 适配
    local homeView = gLobalViewManager:getViewByExtendData("ClanHomeView")
    if homeView then
        self:setScale(homeView:getUIScalePro())
    end    
    
    local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
    self:addChild(touch, -1)
    touch:move(self:convertToNodeSpaceAR(display.center))
    touch:setSwallowTouches(true)
    self:addClick(touch)
    touch:setScale(1/self:getScale())
end


function ClanMoreMenuLayer:resetClickTypeEvt(_name)
    self.m_clickType = nil
    self:updateBtnState()
end

function ClanMoreMenuLayer:switchState(_actName)
    if self.m_actRunning then
        return
    end
    _actName = _actName or "actionframe"
    self.m_actRunning = true
    self:setVisible(true)
    self:runCsbAction(_actName, false, function()
        if _actName == "actionframe1" then
            self:setVisible(false)
        end
        self.m_actRunning = false
    end, 60)
end

-- 改变 按钮 状态
function ClanMoreMenuLayer:updateBtnState()
    local btnBrowse = self:findChild("btn_browse")
    local btnRule = self:findChild("btn_rule")
    local btnUserInfo = self:findChild("btn_userInfo")
    local btnFAQ = self:findChild("btn_faq")

    btnBrowse:setEnabled(self.m_clickType ~= ClickType.SEARCH)
    btnRule:setEnabled(self.m_clickType ~= ClickType.RULE)
    btnUserInfo:setEnabled(self.m_clickType ~= ClickType.USER_INFO)
    btnFAQ:setEnabled(self.m_clickType ~= ClickType.FAQ)
end

function ClanMoreMenuLayer:clickFunc(sender)
    local name = sender:getName()
    -- if not name == "touch_mask" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- end

    if name == "btn_close" or name == "touch_mask" then
        self:switchState("actionframe1")
    elseif name == "btn_browse" then
        -- 搜索 公会
        self.m_clickType = ClickType.SEARCH
        self:updateBtnState()
        ClanManager:popSearchClanPanel()
    elseif name == "btn_rule" then
        -- 规则
        self.m_clickType = ClickType.RULE
        self:updateBtnState()
        ClanManager:popClanRulePanel()
    elseif name == "btn_userInfo" then
        -- 打开 个人信息页
        self.m_clickType = ClickType.USER_INFO
        self:updateBtnState()
        G_GetMgr(G_REF.UserInfo):showMainLayer()
    elseif name == "btn_faq" then
        -- FAQ
        self.m_clickType = ClickType.FAQ
        self:updateBtnState()
        local view = util_createView("views.clan.ClanFAQPanel")
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    elseif name == "bth_rank_rules" then
        local view = util_createView("views.clan.rank.ClanRankRuleLayer")
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    end
end

return ClanMoreMenuLayer
