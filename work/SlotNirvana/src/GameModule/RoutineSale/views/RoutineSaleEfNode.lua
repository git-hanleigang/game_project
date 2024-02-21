--[[
    
]]

local RoutineSaleEfNode = class("RoutineSaleEfNode", BaseView)

function RoutineSaleEfNode:getCsbName()
    return "Sale_New/csb/turntable/xuanzhuanguang.csb"
end

function RoutineSaleEfNode:initUI(_discount)
    RoutineSaleEfNode.super.initUI(self)

    self:runCsbAction("idle", true)
end

return RoutineSaleEfNode