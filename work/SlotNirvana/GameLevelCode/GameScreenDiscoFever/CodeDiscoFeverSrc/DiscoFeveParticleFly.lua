---
--xcyy
--2018年5月23日
--DiscoFeveParticleFly.lua

local DiscoFeveParticleFly = class("DiscoFeveParticleFly",util_require("base.BaseView"))


function DiscoFeveParticleFly:initUI(name)

    self:createCsbNode(name..".csb")

    self:findChild("Particle_1"):setPositionType(0)

    if name == "DiscoFever_wild_shouji" then
        local node = self:findChild("Node_act")
        if node then
            local WildSpine = util_spineCreate("Socre_DiscoFever_Wild",true,true)
            node:addChild(WildSpine,-1)
            util_spinePlay(WildSpine,"idleframe2",true)
        end
        
    end

end


function DiscoFeveParticleFly:onEnter()
 

end

function DiscoFeveParticleFly:onExit()
 
end


return DiscoFeveParticleFly