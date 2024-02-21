--[[
    
]]

local RoutineSaleTurntableTip = class("RoutineSaleTurntableTip", BaseView)

function RoutineSaleTurntableTip:getCsbName()
    return "Sale_New/csb/turntable/SaleTurntable_tip.csb"
end

function RoutineSaleTurntableTip:playStart()
    self:runCsbAction("start", false)
end

function RoutineSaleTurntableTip:playOver()
    self:runCsbAction("over", false)
end

return RoutineSaleTurntableTip