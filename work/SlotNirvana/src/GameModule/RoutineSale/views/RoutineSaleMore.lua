--[[
    
]]

local RoutineSaleMore = class("RoutineSaleMore", BaseView)

function RoutineSaleMore:getCsbName()
    return "Sale_New/csb/main/SaleMain_More.csb"
end

function RoutineSaleMore:initUI(_discount)
    RoutineSaleMore.super.initUI(self)

    local lb_number = self:findChild("lb_number")
    lb_number:setString(_discount .. "%")

    self:runCsbAction("idle", true)
end

return RoutineSaleMore