--[[--
    左边第一列第一个
    冻结列，不能滑动
]]
local Cell_LeftTop = class("Cell_LeftTop", BaseView)
function Cell_LeftTop:getCsbName()
    return "VipNew/csd/rewardUI/Cell_LeftTop.csb"
end

return Cell_LeftTop
