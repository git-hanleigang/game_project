--[[
    
]]
local BasicSaleWheelEf = class("BasicSaleWheelEf", BaseView)

function BasicSaleWheelEf:getCsbName()
    return "SpecialSale/BaiscSaleLayer_WheelGlow.csb"
end

function BasicSaleWheelEf:initUI(_data)
    BasicSaleWheelEf.super.initUI(self)

    self:runCsbAction("idle", true)
end

function BasicSaleWheelEf:playEnd()
    self:runCsbAction("end", false)
end

return BasicSaleWheelEf
