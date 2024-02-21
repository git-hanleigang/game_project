---
--xhkj
--2018年6月11日
--QuickHitWheelPointAction.lua

local QuickHitWheelPointAction = class("QuickHitWheelPointAction", util_require("base.BaseView"))

function QuickHitWheelPointAction:initUI()


    self:createCsbNode("Socre_QuickHit_Wheelsanfa.csb")

    self:runCsbAction("hide")
end


function QuickHitWheelPointAction:onEnter()
 

end

function QuickHitWheelPointAction:showParticle( )
    self:findChild("Particle_1"):resetSystem() 
end

function QuickHitWheelPointAction:onExit()
    
end

return QuickHitWheelPointAction