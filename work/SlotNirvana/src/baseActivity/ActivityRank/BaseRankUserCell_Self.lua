-- 玩家排行榜信息

local BaseRankUserCell = require "baseActivity.ActivityRank.BaseRankUserCell"
local BaseRankUserCell_Self = class("BaseRankUserCell_Self", BaseRankUserCell)

function BaseRankUserCell_Self:isMyRank()
    return true
end

function BaseRankUserCell_Self:updateView(rank_data)
    if not rank_data or table.nums(rank_data) <= 0 then
        return 0
    end
    self:setRankData(rank_data)

    self.sp_myRank:setVisible(true)
    self.sp_otherRank:setVisible(false)
    self:reloaedIcon()
    self:setRankInfo(rank_data)
end

return BaseRankUserCell_Self
