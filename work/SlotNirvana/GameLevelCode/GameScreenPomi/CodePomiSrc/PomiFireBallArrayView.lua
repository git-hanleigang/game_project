---
--xcyy
--2018年5月23日
--PomiFireBallArrayView.lua

local PomiFireBallArrayView = class("PomiFireBallArrayView",util_require("base.BaseView"))


function PomiFireBallArrayView:initUI()

    self:createCsbNode("Pomi_huoqiu_Array.csb")

end

function PomiFireBallArrayView:playParticle( )
    self:findChild("Particle_1_0"):resetSystem()


end

function PomiFireBallArrayView:stopParticle( )
    self:findChild("Particle_1_0"):stopSystem()

end

function PomiFireBallArrayView:onEnter()
 

end


function PomiFireBallArrayView:onExit()
 
end

return PomiFireBallArrayView