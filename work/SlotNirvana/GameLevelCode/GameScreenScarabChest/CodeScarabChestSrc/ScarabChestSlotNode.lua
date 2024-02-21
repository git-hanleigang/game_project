

local ScarabChestSlotNode = class("ScarabChestSlotNode",util_require("Levels.SlotsNode"))

function ScarabChestSlotNode:addTuoweiParticle(parentNode, falseParticleTbl)
    if(self.p_symbolType == GD.TAG_SYMBOL_TYPE.SYMBOL_WILD)then
        if tolua.isnull(self.m_particle) then
            self.m_particle = GD.util_spineCreate("Socre_ScarabChest_Wild",true,true)
            parentNode:addChild(self.m_particle, GD.REEL_SYMBOL_ORDER.REEL_ORDER_2 - 200)
            GD.util_spinePlay(self.m_particle,'idleframe5',true)
            falseParticleTbl[#falseParticleTbl+1] = self.m_particle
        end
    end
end

function ScarabChestSlotNode:updateDistance(distance)
    ScarabChestSlotNode.super.updateDistance(self,distance)
    if not tolua.isnull(self.m_particle) then
        self.m_particle:setPosition(cc.p(self:getPosition()))
    end
end

function ScarabChestSlotNode:removeTuowei()
    if not tolua.isnull(self.m_particle) then
        self.m_particle:removeFromParent()
        self.m_particle = nil
    end
end

function ScarabChestSlotNode:delayRemoveTuowei()
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

function ScarabChestSlotNode:reset()
    if not tolua.isnull(self.m_particle) then
        self:delayRemoveTuowei()
    end
    ScarabChestSlotNode.super.reset(self)
end

return ScarabChestSlotNode
