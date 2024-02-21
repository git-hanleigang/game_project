---
--island
--2018年6月5日
--FortuneBrickFly.lua

local FortuneBrickFly = class("FortuneBrickFly", util_require("base.BaseView"))

function FortuneBrickFly:initUI(data)
    -- local resourceFilename="Socre_fly_particle_"..data..".csb"
    local resourceFilename="Socre_fly_particle.csb"
    self:createCsbNode(resourceFilename)
    self:findChild("Particle_fly"):setPositionType(0)
end

function FortuneBrickFly:onEnter()
    
end

function FortuneBrickFly:onExit()
    
end

return FortuneBrickFly