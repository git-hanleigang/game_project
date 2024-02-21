--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-08 14:14:17
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-08 14:14:55
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankRewardsInfoCellUI.lua
Description: 排行榜奖励cell
--]]
local ClanRankRewardsInfoCellUI = class("ClanRankRewardsInfoCellUI", BaseView)

function ClanRankRewardsInfoCellUI:initDatas(_rewardData, _selfRank)
    ClanRankRewardsInfoCellUI.super.initDatas(self)
    
    self.m_rewardData = _rewardData
    self.m_bMe = _rewardData:checkRankIn(_selfRank)
end

function ClanRankRewardsInfoCellUI:initUI()
    ClanRankRewardsInfoCellUI.super.initUI(self)

    -- 背景显隐
    self:initBgUI()
    -- 排行
    self:initRankDescUI()
    -- 奖励-金币 + 高倍场点数
    self:initRewardUI()
end

function ClanRankRewardsInfoCellUI:getCsbName()
    return "Club/csd/RANK/TopTeam/RankRewardsShow.csb"
end

-- 背景显隐
function ClanRankRewardsInfoCellUI:initBgUI()
    local spMe = self:findChild("img_bg2")
    local spOther = self:findChild("img_bg1")

    spMe:setVisible(self.m_bMe)
    spOther:setVisible(not self.m_bMe)
end

-- 段位图标
function ClanRankRewardsInfoCellUI:initRankDescUI()
    local lbRankMe = self:findChild("txt_ranking2")
    local lbRankOther = self:findChild("txt_ranking1")

	lbRankMe:setString(self.m_rewardData:getRankDesc())
	lbRankOther:setString(self.m_rewardData:getRankDesc())
    lbRankMe:setVisible(self.m_bMe)
    lbRankOther:setVisible(not self.m_bMe)
end

-- 奖励-金币 + 高倍场点数
function ClanRankRewardsInfoCellUI:initRewardUI()
    local lbCoins = self:findChild("txt_coin")
    local nodePoints = self:findChild("node_points")
    local lbPoints = self:findChild("lb_points")
    local coins = self.m_rewardData:getCoins() --金币
    local deluxePints = self.m_rewardData:getDeluxePints() --高倍场点数
    if deluxePints > 0 then
        lbCoins:setString(util_formatCoins(coins, 9) .. "+")
        nodePoints:setVisible(true)
        lbPoints:setString(util_getFromatMoneyStr(deluxePints))
        local posX = lbCoins:getPositionX() + lbCoins:getContentSize().width*lbCoins:getScale() + 35
        nodePoints:setPositionX(posX)
    else
        lbCoins:setString(util_formatCoins(coins, 9))
        nodePoints:setVisible(false)
    end
end

function ClanRankRewardsInfoCellUI:getContentSize()
    return self:findChild("img_bg1"):getContentSize()
end

return ClanRankRewardsInfoCellUI