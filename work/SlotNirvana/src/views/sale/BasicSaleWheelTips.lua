--[[
    
]]
local BasicSaleWheelTips = class("BasicSaleWheelTips", BaseView)

function BasicSaleWheelTips:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "SpecialSale/Turntable/TurntableMain_tips_shu.csb"
    else
        return "SpecialSale/Turntable/TurntableMain_tips.csb"
    end
end

function BasicSaleWheelTips:initUI(_data)
    BasicSaleWheelTips.super.initUI(self)

    local lb_spin = self:findChild("lb_spin")
    local lb_time = self:findChild("lb_time")
    
    lb_spin:setVisible(_data.spin)
    lb_time:setVisible(not _data.spin)

    local saleData = _data.saleData
    local num = saleData:getMaxMultiplyCount()
    local maxDiscount = saleData:getMaxDiscount()
    lb_time:setString("PURCHASE TO SPIN!\nTHERE ARE " .. num .. " WEDGES\nFOR X" .. maxDiscount) 
end

function BasicSaleWheelTips:playAction()
    self:runCsbAction("start", false, function ()
        performWithDelay(self, function ()
            self:runCsbAction("over", false, function ()
                
            end, 60)
        end, 5)
    end, 60)
end

return BasicSaleWheelTips
