--[[
    
]]
local BasicSaleTurntable = class("BasicSaleTurntable", BaseView)

function BasicSaleTurntable:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "SpecialSale/BaiscSaleLayer_Turntable_shu.csb"
    else
        return "SpecialSale/BaiscSaleLayer_Turntable.csb"
    end
end

function BasicSaleTurntable:initUI(_data)
    BasicSaleTurntable.super.initUI(self)

    local lb_desc = self:findChild("lb_desc")
    local lb_coins = self:findChild("lb_coins")
    local lb_number = self:findChild("lb_number")
    local num = _data:getMaxMultiplyCount()
    local maxDiscount = _data:getMaxDiscount()
    lb_desc:setString(num .. " WEDGES")
    lb_coins:setString("X" .. maxDiscount .. " COINS")
    lb_number:setString("X" .. maxDiscount)
end

function BasicSaleTurntable:playAction()
    self:runCsbAction("start", false, function ()
        performWithDelay(self, function ()
            self:runCsbAction("over", false, function ()
                self:runCsbAction("idle", true)
            end, 60)
        end, 5)
    end, 60)
end

return BasicSaleTurntable
