--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-10 12:13:52
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-10 12:15:31
FilePath: /SlotNirvana/src/views/clan/rank/topTeam/ClanRankTopLogoUI.lua
Description: 最强公会排行， 前三名奖台logoUI
--]]
local ClanRankTopLogoUI = class("ClanRankTopLogoUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRankTopLogoUI:initDatas(_rankCellData, _idx)
    ClanRankTopLogoUI.super.initDatas(self)
    
    self.m_rankCellData = _rankCellData
    self.m_rankIdx = _idx or 1
end

function ClanRankTopLogoUI:initUI()
    ClanRankTopLogoUI.super.initUI(self)

    -- 公会logo
    local spLogo = self:findChild("sp_logo")
    spLogo:setVisible(false)
    if self.m_rankCellData then
        local imgName = self.m_rankCellData:getClanLogo() 
        local imgPath = ClanManager:getClanLogoImgPath(imgName)
        local bSuccess = util_changeTexture(spLogo, imgPath)
        spLogo:setVisible(bSuccess)
    end

    -- 公会名字
    local layoutTeamName = self:findChild("layout_teamName")
    local lbTeamName = self:findChild("lb_teamName")
    lbTeamName:setString("")
    if self.m_rankCellData then
        local teamName = self.m_rankCellData:getName()
        lbTeamName:setString(teamName) 
        util_wordSwing(lbTeamName, 2, layoutTeamName, 3, 30, 3)
        self:runCsbAction("idle", true) 
    end
end

function ClanRankTopLogoUI:getCsbName()
    return string.format("Club/csd/RANK/TopTeam/TopTeam_ranking_%d.csb", self.m_rankIdx)
end

return ClanRankTopLogoUI