--[[
Author: cxc
Date: 2021-02-22 17:08:59
LastEditTime: 2021-03-08 18:05:06
LastEditors: Please set LastEditors
Description: 公会 说明 面板 
FilePath: /SlotNirvana/src/views/clan/ClanRulePanel.lua
--]]
local ClanRulePanel = class("ClanRulePanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")

local PAGE_COUNT = 4

function ClanRulePanel:ctor()
    ClanRulePanel.super.ctor(self)
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/ClubRuleLayer.csb")
end

function ClanRulePanel:initUI(_params)
    ClanRulePanel.super.initUI(self)
    
    -- 规则 sp list
    for i=1, PAGE_COUNT do
        self["m_page"..i] = self:findChild("sp_shuoming" .. i)
    end
    self:showPage(1)

    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
end

-- 改变 page
function ClanRulePanel:changeCurPage(_changeValue)
    if not _changeValue then
        return
    end

    local idx = self.m_showIdx + _changeValue
    if idx < 1 then
        idx = PAGE_COUNT
    elseif idx > PAGE_COUNT then
        idx = 1
    end
    
    self:showPage(idx)
end

-- 显示某一页
function ClanRulePanel:showPage(_idx)
    for i=1, PAGE_COUNT do
        if not tolua.isnull(self["m_page"..i]) then
            self["m_page"..i]:setVisible(_idx == i)
        end
    end
    
    self.m_showIdx = _idx
end

function ClanRulePanel:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        self:closeUI()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLNA_PANEL_UI, "ClanRulePanel")
    elseif name == "btn_creatteam" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changeCurPage(-1)
    elseif name == "btn_creatteam_0" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:changeCurPage(1)
    end
end

return ClanRulePanel