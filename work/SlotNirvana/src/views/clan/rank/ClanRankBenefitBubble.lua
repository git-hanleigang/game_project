--[[
Author: cxc
Date: 2022-03-22 10:38:21
LastEditTime: 2022-03-22 10:38:21
LastEditors: cxc
Description: 公会 权益界面气泡
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankBenefitBubble.lua
--]]
local ClanRankBenefitBubble = class("ClanRankBenefitBubble", BaseView)

function ClanRankBenefitBubble:initDatas(_idx)
    self.m_idx = _idx
end

function ClanRankBenefitBubble:getCsbName()
    local csbPath = "Club/csd/RANK/Rank_benefit_Cell1.csb"
    if self.m_idx then
        csbPath = "Club/csd/RANK/Rank_benefit_Cell"..self.m_idx..".csb"
    end
    return csbPath
end

function ClanRankBenefitBubble:switchBubbleVisible()
    local visible = self:isVisible()
    local actName = "start"
    if visible then
        actName = "over"
    end

    self:setVisible(true)
    self:runCsbAction(actName, false, function()
        self:setVisible(not visible)
    end, 60)
end

return ClanRankBenefitBubble