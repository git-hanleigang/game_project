---
--xcyy
--2018年5月23日
--AfricaRiseMiniBar.lua

local AfricaRiseMiniBar = class("AfricaRiseMiniBar",util_require("base.BaseView"))


function AfricaRiseMiniBar:initUI()
    self:createCsbNode("AfricaRise_ji_Totalbet.csb")
    self.Particle = self:findChild("Particle_3") 
    self.Particle:stopSystem()
end

function AfricaRiseMiniBar:onEnter()

end

function AfricaRiseMiniBar:UpdataSpinCount(count)
    self:findChild("bonus_left_times"):setString(count)
    self:playSubSpinCountEffect()
end

function AfricaRiseMiniBar:playSubSpinCountEffect()
    
    -- local par = cc.ParticleSystemQuad:create("effect/AfricaRise_bdlizi.plist")
    -- self:findChild("Particle_Node"):addChild(par)
    -- scheduler.performWithDelayGlobal(
    --     function()
    --         par:removeFromParent()
    --     end,
    --     1.0,
    --     self:getModuleName()
    -- )
    self.Particle:stopSystem()
    self.Particle:resetSystem()
end
function AfricaRiseMiniBar:UpdataTotalBetNum(_num)
    local node = self:findChild("bonus_total_bet")
    node:setString(util_formatCoins(_num, 50))
    self:updateLabelSize({label = node, sx = 1, sy = 1}, 578)
end

function AfricaRiseMiniBar:onExit()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function AfricaRiseMiniBar:getModuleName()
    return "MiniBar"
end

return AfricaRiseMiniBar