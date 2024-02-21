

local MedusaManiaSlotNode = class("MedusaManiaSlotNode",util_require("Levels.SlotsNode"))

function MedusaManiaSlotNode:addTuoweiParticle(parentNode, falseParticleTbl)
    if(self.p_symbolType == GD.TAG_SYMBOL_TYPE.SYMBOL_WILD)then
        if tolua.isnull(self.m_particle) then
            self.m_particle = GD.util_spineCreate("Socre_MedusaMania_Wild",true,true)
            parentNode:addChild(self.m_particle,GD.REEL_SYMBOL_ORDER.REEL_ORDER_2 - 200)
            GD.util_spinePlay(self.m_particle,'idleframe2',true)
            falseParticleTbl[#falseParticleTbl+1] = self.m_particle
        end
    end
end

function MedusaManiaSlotNode:updateDistance(distance)
    MedusaManiaSlotNode.super.updateDistance(self,distance)
    if not tolua.isnull(self.m_particle) then
        self.m_particle:setPosition(cc.p(self:getPosition()))
    end
end

function MedusaManiaSlotNode:removeTuowei()
    if not tolua.isnull(self.m_particle) then
        self.m_particle:removeFromParent()
        self.m_particle = nil
    end
end

function MedusaManiaSlotNode:delayRemoveTuowei()
    local trailingNode = self.m_particle
    self.m_particle = nil
    local pos = cc.p(trailingNode:getPosition()) 
    local sizeY = 700
    local time = sizeY / self.m_machine.m_configData.p_reelMoveSpeed
    local actList = {}
    actList[#actList + 1] = cc.MoveTo:create(time,cc.p(pos.x,pos.y - sizeY))
    actList[#actList + 1] = cc.CallFunc:create(function()
        if not tolua.isnull(trailingNode) then
            trailingNode:removeFromParent()
        end
    end)
    trailingNode:runAction(cc.Sequence:create(actList))
end

function MedusaManiaSlotNode:reset()
    if not tolua.isnull(self.m_particle) then
        self:delayRemoveTuowei()
    end
    MedusaManiaSlotNode.super.reset(self)
end

return MedusaManiaSlotNode
