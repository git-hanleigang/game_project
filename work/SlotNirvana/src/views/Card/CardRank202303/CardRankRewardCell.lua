--[[
]]
local BaseRankRewardCell = require("baseRank.BaseRankRewardCell")
local CardRankRewardCell = class("CardRankRewardCell", BaseRankRewardCell)

function CardRankRewardCell:setRankInfo(rank_data)
    CardRankRewardCell.super.setRankInfo(self, rank_data)

    if self.lb_rank then
        self:updateLabelSize({label = self.lb_rank}, 140)
    end
end

return CardRankRewardCell