---
--xcyy
--2018年5月23日
--LuxeVegasBottomNode.lua

local LuxeVegasBottomNode = class("LuxeVegasBottomNode",util_require("views.gameviews.GameBottomNode"))


function LuxeVegasBottomNode:initUI(...)

    LuxeVegasBottomNode.super.initUI(self, ...)

end

function LuxeVegasBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        local particle1 = coinBottomEffectNode:findChild("Particle_1")
        local particle2 = coinBottomEffectNode:findChild("Particle_2")
        particle1:resetSystem()
        particle2:resetSystem()
        coinBottomEffectNode:runCsbAction("actionframe",false,function()
            particle1:stopSystem()
            particle2:stopSystem()
            -- coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

return LuxeVegasBottomNode
