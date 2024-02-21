--[[
Author: cxc
Date: 2022-02-24 17:24:47
LastEditTime: 2022-02-24 17:24:48
LastEditors: cxc
Description: 公会排行  排行cell信息
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankCellUI.lua
--]]
local ClanRankCellUI = class("ClanRankCellUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRankCellUI:updateUI(_rankCellData, _selfClanCid)
    self.m_rankCellData = _rankCellData
    self.m_bMe = _selfClanCid == _rankCellData:getCid() 

    -- 背景显隐
    self:initBgUI()
    -- 排行icon
    self:initRankIconUI()
    -- 公会勋章log
    self:initTeamLogoUI()
    -- 公会名字
    self:initTeamNameUI()
    -- 公会人数
    self:initTeamMemberCountUI()
    -- 当前公会点数
    self:initTeamPoints()
end

function ClanRankCellUI:getCsbName()
    return "Club/csd/RANK/ClubRankCell.csb"
end

-- 背景显隐
function ClanRankCellUI:initBgUI()
    local spMe = self:findChild("Sp_myrank")
    local spOther = self:findChild("Sp_otherrank")
    spMe:setVisible(self.m_bMe)
    spOther:setVisible(not self.m_bMe)
end

-- 排行icon
function ClanRankCellUI:initRankIconUI()
    local sp1 = self:findChild("sp_1st")
    local sp2 = self:findChild("sp_2nd")
    local sp3 = self:findChild("sp_3rd")
    local lbRank = self:findChild("lb_rank")
    local rank = self.m_rankCellData:getRank()
    sp1:setVisible(rank == 1)
    sp2:setVisible(rank == 2)
    sp3:setVisible(rank == 3)
    lbRank:setVisible(rank > 3)
    if rank > 4 then
        lbRank:setString(rank)
    end
end

-- 公会勋章log
function ClanRankCellUI:initTeamLogoUI()
    local spLogoBg = self:findChild("sp_clanBg")
    local spLogo = self:findChild("sp_clanLogo")
    local clanLogo = self.m_rankCellData:getClanLogo() 
    local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
    local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
    util_changeTexture(spLogoBg, imgBgPath)
    util_changeTexture(spLogo,  imgPath)
end

-- 公会名字
function ClanRankCellUI:initTeamNameUI()
    local layoutName = self:findChild("layout_myTeamName")
    local lbName = self:findChild("lb_myname")
    if not self.m_bMe then
        layoutName = self:findChild("layout_otherTeamName")
        lbName = self:findChild("lb_othername")
    end
    local name = self.m_rankCellData:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end

-- 公会人数
function ClanRankCellUI:initTeamMemberCountUI()
    local lbCount = self:findChild("lb_myMemberCount")
    if not self.m_bMe then
        lbCount = self:findChild("lb_otherMemberCount")
    end
    local memberCount = self.m_rankCellData:getMemberCount() 
    local memberLimitCount = self.m_rankCellData:getMemberLimitCount() 
    lbCount:setString(memberCount .. "/" .. memberLimitCount)
end

-- 当前公会点数
function ClanRankCellUI:initTeamPoints()
    local lbPoints = self:findChild("lb_clubpoint_shuzi")
    local points = self.m_rankCellData:getPoints()
    lbPoints:setString(util_getFromatMoneyStr(points))
end

-- 获取cellSize
function ClanRankCellUI:getContentSize()
    return self:findChild("Sp_myrank"):getContentSize()
end

return ClanRankCellUI