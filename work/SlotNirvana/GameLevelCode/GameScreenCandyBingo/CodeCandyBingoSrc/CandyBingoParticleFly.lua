---
--xcyy
--2018年5月23日
--CandyBingoParticleFly.lua

local CandyBingoParticleFly = class("CandyBingoParticleFly",util_require("base.BaseView"))


function CandyBingoParticleFly:initUI()

    self:createCsbNode("Socre_CandyBingo_tuowei_lizi.csb")

    self:findChild("Particle_1"):setPositionType(0)
    self:findChild("Particle_2"):setPositionType(0)

end


function CandyBingoParticleFly:onEnter()
 

end

function CandyBingoParticleFly:onExit()
 
end


return CandyBingoParticleFly