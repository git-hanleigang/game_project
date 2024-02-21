---
--xcyy
--2018年5月23日
--FarmBonus_AddFsPartacleView.lua

local FarmBonus_AddFsPartacleView = class("FarmBonus_AddFsPartacleView",util_require("base.BaseView"))


function FarmBonus_AddFsPartacleView:initUI()

    self:createCsbNode("Socre_Farm_Tuowei.csb")


   
    
end

function FarmBonus_AddFsPartacleView:starFly(time )
    self:findChild("Particle_1"):setPositionType(0)
    self:findChild("Particle_1_0"):setPositionType(0)
    
    self:findChild("Particle_1"):setDuration(time)
    self:findChild("Particle_1_0"):setDuration(time)
end


function FarmBonus_AddFsPartacleView:onEnter()
 

end

function FarmBonus_AddFsPartacleView:onExit()
 
end



return FarmBonus_AddFsPartacleView