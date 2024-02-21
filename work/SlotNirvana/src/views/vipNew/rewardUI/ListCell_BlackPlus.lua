--[[--
]]
local ListCell_BlackPlus = class("ListCell_BlackPlus", BaseView)

function ListCell_BlackPlus:getCsbName()
    return "VipNew/csd/rewardUI/ListCell_BlackPlus.csb"
end

function ListCell_BlackPlus:getCellSize()
    return cc.size(205, 546)
end

function ListCell_BlackPlus:onEnter()
    ListCell_BlackPlus.super.onEnter(self)
    self:runCsbAction("idle", true, nil, 60)
end

-- function ListCell_BlackPlus:clickFunc(sender)
--     local name = sender:getName()
--     if name == "btn_explain" then
--         G_GetMgr(G_REF.Vip):showBlackPlusInfoLayer()
--     end
-- end

return ListCell_BlackPlus
