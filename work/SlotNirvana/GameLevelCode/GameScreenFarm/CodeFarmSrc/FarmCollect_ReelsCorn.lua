---
--xcyy
--2018年5月23日
--FarmCollect_ReelsCorn.lua

local FarmCollect_ReelsCorn = class("FarmCollect_ReelsCorn",util_require("base.BaseView"))


function FarmCollect_ReelsCorn:initUI()

    self:createCsbNode("Farm_yumi_geshu.csb")

    self:findChild("Particle_1"):setVisible(false)
    self:findChild("Particle_2"):setVisible(false)

    
end


function FarmCollect_ReelsCorn:starFly(time )

    self:findChild("Particle_1"):setVisible(true)
    self:findChild("Particle_2"):setVisible(true)

    self:findChild("Particle_1"):setPositionType(0)
    self:findChild("Particle_2"):setPositionType(0)
    
    self:findChild("Particle_1"):setDuration(time)
    self:findChild("Particle_2"):setDuration(time)
end

function FarmCollect_ReelsCorn:onEnter()
 

end


function FarmCollect_ReelsCorn:onExit()
 
end


return FarmCollect_ReelsCorn