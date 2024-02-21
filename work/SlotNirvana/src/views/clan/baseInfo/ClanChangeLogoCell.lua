--[[
Author: cxc
Date: 2021-03-09 10:25:38
LastEditTime: 2021-03-18 11:36:24
LastEditors: Please set LastEditors
Description: 公会 logo cell
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanChangeLogoCell.lua
--]]
local ClanChangeLogoCell = class("ClanChangeLogoCell", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanChangeLogoCell:initUI(_idx, _selectIdx)
    local csbName = "Club/csd/LOGO/ClubChangeLogoCell.csb"
    self:createCsbNode(csbName)
    
    self.m_idx = _idx --当前cell Idx
    self.m_selectIdx = tonumber(_selectIdx) or 0 --选中的 idx

    self:updateSelectState()

    -- logo
    local spClanIconBg = self:findChild("sp_logodi1")
    local spClanIconBgS = self:findChild("sp_logodi2")
    local spLogo = self:findChild("sp_logo")
    util_changeTexture(spClanIconBg, ClanManager:getClanLogoBgImgPath(_idx))
    util_changeTexture(spClanIconBgS, ClanManager:getClanLogoBgImgPath(_idx, true))
    util_changeTexture(spLogo, ClanManager:getClanLogoImgPath(_idx))
    -- 选中按钮
    local btnSelect = self:findChild("btn_select") 
    btnSelect:setSwallowTouches(false)

    gLobalNoticManager:addObserver(self, "changeLogoEvt", ClanConfig.EVENT_NAME.SELECT_CLAN_LOGO_CELL)
end

function ClanChangeLogoCell:updateSelectState()
    local bSelect = self.m_idx == self.m_selectIdx

    local spSelect = self:findChild("sp_logodi2") -- 选中底板
    local spSelectSign = self:findChild("sp_duihao") -- 选中标识
    local btnSelect = self:findChild("btn_select") -- 选中按钮
    spSelect:setVisible(bSelect)
    spSelectSign:setVisible(bSelect)
    
    btnSelect:setEnabled(not bSelect)
end

function ClanChangeLogoCell:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_select" then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.SELECT_CLAN_LOGO_CELL, self.m_idx) -- 选中公会 logo cell
    end
end

function ClanChangeLogoCell:changeLogoEvt(_selectIdx)
    self.m_selectIdx = _selectIdx or 1
    self:updateSelectState() 
end

return ClanChangeLogoCell