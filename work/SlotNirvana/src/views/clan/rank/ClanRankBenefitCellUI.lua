--[[
Author: cxc
Date: 2022-02-24 18:23:25
LastEditTime: 2022-02-24 18:23:58
LastEditors: cxc
Description: 公会排行  权益cell
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankBenefitCellUI.lua
--]]
local ClanRankBenefitCellUI = class("ClanRankBenefitCellUI", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRankBenefitCellUI:initDatas(_benifitData, _bMe)
    ClanRankBenefitCellUI.super.initDatas(self)
    
    self.m_benifitData = _benifitData
    self.m_bMe = _bMe
end

function ClanRankBenefitCellUI:initUI()
    ClanRankBenefitCellUI.super.initUI(self)

    -- 背景显隐
    self:initBgUI()
    -- 段位图标
    self:initRankIconUI()
    -- 奖励-gem
    self:initRewardGemRateUI()
    -- 奖励-金币
    self:initRewardCoinsRateUI()
    -- 奖励-宝箱
    self:initRewardTeamBoxRateUI()
    -- 奖励-集卡
    self:initRewardCardRateUI()
end

function ClanRankBenefitCellUI:getCsbName()
    return "Club/csd/RANK/Rank_benefitCell.csb"
end

-- 背景显隐
function ClanRankBenefitCellUI:initBgUI()
    local spMe = self:findChild("sp_my_benefit")
    local spOther = self:findChild("sp_other_benefit")

    spMe:setVisible(self.m_bMe)
    spOther:setVisible(not self.m_bMe)
end

-- 段位图标
function ClanRankBenefitCellUI:initRankIconUI()
    local spRank = self:findChild("sp_rank")
    local division = self.m_benifitData:getDivision()
    local iconPath = ClanManager:getRankDivisionIconPath(division)
    util_changeTexture(spRank, iconPath)
end

-- 奖励-宝箱
function ClanRankBenefitCellUI:initRewardTeamBoxRateUI()
    local lb = self:findChild("lb_other_shuzi")
    if self.m_bMe then
        lb = self:findChild("lb_shuzi")
    end
    local boxRate = self.m_benifitData:getBoxRate()
    if boxRate <= 0 then
        lb:setVisible(false)
    end
    lb:setString(boxRate .. "%")
end

-- 奖励-金币
function ClanRankBenefitCellUI:initRewardCoinsRateUI()
    local lb = self:findChild("lb_other_shuzi1")
    if self.m_bMe then
        lb = self:findChild("lb_shuzi1")
    end
    local coinsRate = self.m_benifitData:getCoinsRate()
    if coinsRate <= 0 then
        lb:setVisible(false)
    end
    lb:setString(coinsRate .. "%")
end

-- 奖励-集卡
function ClanRankBenefitCellUI:initRewardCardRateUI()
    local lb = self:findChild("lb_other_shuzi2")
    if self.m_bMe then
        lb = self:findChild("lb_shuzi2")
    end
    local cardRate = self.m_benifitData:getCardRateHour()
    if cardRate <= 0 then
        lb:setVisible(false)
    end
    local subffix = cardRate > 1 and " Hours" or " Hour"
    lb:setString("-"..cardRate .. subffix)
end

-- 奖励-gem
function ClanRankBenefitCellUI:initRewardGemRateUI()
    local lb = self:findChild("lb_other_shuzi3")
    if self.m_bMe then
        lb = self:findChild("lb_shuzi3")
    end
    local gemRate = self.m_benifitData:getGemsRate()
    if gemRate <= 0 then
        lb:setVisible(false)
    end
    lb:setString(gemRate .. "%")
end

function ClanRankBenefitCellUI:getContentSize()
    return self:findChild("Panel_1"):getContentSize()
end

return ClanRankBenefitCellUI