--[[
    
]]
local BasicSaleDiscountNode = class("BasicSaleDiscountNode", BaseView)

function BasicSaleDiscountNode:getCsbName()
    return "SpecialSale/node_fly_shuzi.csb"
end

function BasicSaleDiscountNode:initUI(discount)
    BasicSaleDiscountNode.super.initUI(self)

    local lb_munber = self:findChild("lb_munber_purple_1")
    lb_munber:setString("X" .. discount)
end

function BasicSaleDiscountNode:playFlyAction(_func)
    self:runCsbAction("fly", false, function ()
        self:runCsbAction("baodian", false, function ()
            if _func then
                _func()
            end
        end, 60)
    end, 60)
end

return BasicSaleDiscountNode
