--[[
    
]]

local RoutineSaleFlyNode = class("RoutineSaleFlyNode", BaseView)

function RoutineSaleFlyNode:getCsbName()
    if self.m_isPortrait then
        return "Sale_New/csb/reward/node_number_fly_shu.csb"
    else
        return "Sale_New/csb/reward/node_number_fly.csb"
    end
end

function RoutineSaleFlyNode:initDatas(_discount, _isPortrait)
    self.m_discount = _discount
    self.m_isPortrait = _isPortrait
end

function RoutineSaleFlyNode:initUI(_discount, _isPortrait)
    RoutineSaleFlyNode.super.initUI(self)

    local lb_number = self:findChild("lb_number")
    lb_number:setString("x" .. _discount)
end

function RoutineSaleFlyNode:playStart(_func)
    self:runCsbAction("start", false, function ()
        if _func then
            _func()
        end
    end)
end

return RoutineSaleFlyNode