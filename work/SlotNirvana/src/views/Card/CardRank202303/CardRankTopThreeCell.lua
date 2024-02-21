--[[
    排行榜前三名
]]
local CardRankConfig = require("views.Card.CardRank202303.CardRankConfig")
local BaseRankTopCellUI = util_require("baseRank.BaseRankTopThreeCellUI")
local CardRankTopThreeCell = class("CardRankTopThreeCell", BaseRankTopCellUI)

function CardRankTopThreeCell:getCsbName()
    local rank = self.m_data.p_rank or 1
    return string.format(CardRankConfig.RankTopThreeCellCsbPath, tonumber(rank))
end

-- 累积数量
function CardRankTopThreeCell:updateNumUI()
    CardRankTopThreeCell.super.updateNumUI(self)
    self:updateLabelSize({label = self.m_lbNum, sx = 1, sy = 1}, 131)
end

return CardRankTopThreeCell