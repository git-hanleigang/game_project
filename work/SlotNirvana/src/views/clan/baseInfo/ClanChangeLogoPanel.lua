--[[
Author: cxc
Date: 2021-02-10 10:41:58
LastEditTime: 2021-07-26 11:14:09
LastEditors: Please set LastEditors
Description: 改变公会的 logo 面板
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanChangeLogoPanel.lua
--]]
local ClanChangeLogoPanel = class("ClanChangeLogoPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanChangeLogoPanel:ctor()
    ClanChangeLogoPanel.super.ctor(self)
    self:setLandscapeCsbName("Club/ClubChangeLogoLayer.csb")
    self:setLandscapeCsbName("Club/csd/LOGO/ClubChangeLogoLayer.csb")
    self:setKeyBackEnabled(true)
    gLobalNoticManager:addObserver(self, "changeLogoEvt", ClanConfig.EVENT_NAME.SELECT_CLAN_LOGO_CELL)
end

function ClanChangeLogoPanel:initUI(_defalueClanLogo)
    ClanChangeLogoPanel.super.initUI(self)

    local clanData = ClanManager:getClanData()
    self.m_selectIdx = _defalueClanLogo or 1

    -- 勋章列表
    local listView = self:findChild("ListView_logo")
    listView:setScrollBarEnabled(false)
    local layoutLogos = self:findChild("Layout_logo")
    local layoutSize = layoutLogos:getContentSize()
    local node = self:findChild("node_logos")

    local cellSize = cc.size(160, 160)
    local column = math.floor(layoutSize.width / cellSize.width)
    local space = math.floor((layoutSize.width % cellSize.width) / (column + 1))

    local layoutHeight = 0
    for idx = 1, ClanConfig.MAX_LOGO_COUNT do
        local logoCell = util_createView("views.clan.baseInfo.ClanChangeLogoCell", idx, self.m_selectIdx)
        logoCell:addTo(node)

        local curRow = math.floor((idx - 1) / column) + 1
        local curCol = (idx - 1) % column + 1

        local x = curCol * space + cellSize.width * (curCol - 0.5) --两边不留space 锚点0.5
        local y = curRow * space + cellSize.height * (curRow - 0.5) --两边不留space 锚点0.5
        logoCell:move(x, -y) 
        
        layoutHeight = y + cellSize.height*0.5
    end
    layoutLogos:setContentSize(cc.size(layoutSize.width, layoutHeight))
    node:setPositionY(layoutHeight)
end

function ClanChangeLogoPanel:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_save" then
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.SAVE_SELECT_CLAN_LOGO, self.m_selectIdx) -- 保存选中的公会 logo
        self:closeUI()
    end
end

function ClanChangeLogoPanel:changeLogoEvt(_selectIdx)
    self.m_selectIdx = _selectIdx or 1
end

return ClanChangeLogoPanel