--[[--
    以往赛季的cell
    bg
]]
local CardCollectionBgCell = class("CardCollectionBgCell", BaseView)
function CardCollectionBgCell:initDatas()
end

function CardCollectionBgCell:getCsbName()
    return string.format("CardRes/%s/cash_season_collection_bg_cell.csb", "season202302")
end

return CardCollectionBgCell
