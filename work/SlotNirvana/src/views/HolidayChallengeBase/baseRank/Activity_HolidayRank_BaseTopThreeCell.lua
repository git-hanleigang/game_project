--[[
    排行榜前三名
]]
local BaseRankTopCellUI = util_require("baseRank.BaseRankTopThreeCellUI")
local Activity_HolidayRank_BaseTopThreeCell = class("Activity_HolidayRank_BaseTopThreeCell", BaseRankTopCellUI)

function Activity_HolidayRank_BaseTopThreeCell:getCsbName()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    local rank = self.m_data.p_rank or 1
    return string.format(self.m_activityConfig.RESPATH.RANK_TOP_ITEM_NODE, tonumber(rank))
end

-- 累积数量
function Activity_HolidayRank_BaseTopThreeCell:updateNumUI()
    Activity_HolidayRank_BaseTopThreeCell.super.updateNumUI(self)
    self:updateLabelSize({label = self.m_lbNum, sx = 1, sy = 1}, 131)
end

return Activity_HolidayRank_BaseTopThreeCell