--[[
Author: cxc
Date: 2022-03-19 16:59:03
LastEditTime: 2022-03-19 16:59:04
LastEditors: cxc
Description: 段位上升下降最新权益值
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankReportCell.lua
--]]
local ClanRankReportCell = class("ClanRankAllRewardBubble", BaseView)
function ClanRankReportCell:getCsbName()
    return "Club/csd/RANK/ClubRankReportCell_" .. self.m_csbIdx .. ".csb"
end

function ClanRankReportCell:initDatas(_csbIdx, _rate)
    self.m_csbIdx = _csbIdx
    self.m_rate = _rate or 0
end

function ClanRankReportCell:initUI(_cellData)
    ClanRankReportCell.super.initUI(self)

	-- 权益lb
    local lb = self:findChild("lb_shuzi")
    if self.m_csbIdx == 4 then
        --集卡cd
        local subffix = self.m_rate > 1 and " Hours" or " Hour"
        lb:setString("-" .. self.m_rate .. subffix)
    else
        lb:setString("+" .. self.m_rate .. "%")
    end
end

return ClanRankReportCell