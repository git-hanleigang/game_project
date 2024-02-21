---
--xcyy
--2018年5月23日
--PomiFIrMoreBallActionView.lua

local PomiFIrMoreBallActionView = class("PomiFIrMoreBallActionView",util_require("base.BaseView"))


function PomiFIrMoreBallActionView:initUI()

    self:createCsbNode("Pomi_huoQiuBiao.csb")

    self:stopParticle( )
    
end

function PomiFIrMoreBallActionView:playParticle( )
    self:findChild("Particle_1_0"):resetSystem()
    self:findChild("Particle_1"):resetSystem()

end

function PomiFIrMoreBallActionView:stopParticle( )
    self:findChild("Particle_1_0"):stopSystem()
    self:findChild("Particle_1"):stopSystem() 
end


function PomiFIrMoreBallActionView:onEnter()
 

end


function PomiFIrMoreBallActionView:onExit()
 
end


return PomiFIrMoreBallActionView