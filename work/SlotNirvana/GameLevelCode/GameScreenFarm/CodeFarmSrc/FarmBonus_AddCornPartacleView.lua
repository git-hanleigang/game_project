---
--xcyy
--2018年5月23日
--FarmBonus_AddCornPartacleView.lua

local FarmBonus_AddCornPartacleView = class("FarmBonus_AddCornPartacleView",util_require("base.BaseView"))


function FarmBonus_AddCornPartacleView:initUI()

    self:createCsbNode("Socre_Farm_Tuowei.csb")


   
    
end

function FarmBonus_AddCornPartacleView:starFly(time )
    self:findChild("Particle_1"):setPositionType(0)
    self:findChild("Particle_1_0"):setPositionType(0)
    
    self:findChild("Particle_1"):setDuration(time)
    self:findChild("Particle_1_0"):setDuration(time)
end


function FarmBonus_AddCornPartacleView:onEnter()
 

end

function FarmBonus_AddCornPartacleView:onExit()
 
end



return FarmBonus_AddCornPartacleView