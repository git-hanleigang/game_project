--[[--
]]
local ListCell_Black = class("ListCell_Black", BaseView)

function ListCell_Black:getCsbName()
    return "VipNew/csd/rewardUI/ListCell_Black.csb"
end

function ListCell_Black:getCellSize()
    return cc.size(205, 546)
end

function ListCell_Black:onEnter()
    ListCell_Black.super.onEnter(self)
    self:runCsbAction("idle", true, nil, 60)
end

return ListCell_Black
