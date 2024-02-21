
local ThorsStrikeSlotNode = class("ThorsStrikeSlotNode",require("Levels.SlotsNode"))


function ThorsStrikeSlotNode:addTuoweiParticle(parentNode)
  if(self.p_symbolType == GD.TAG_SYMBOL_TYPE.SYMBOL_WILD)then
    if(not self.m_isLastSymbol and self.m_particle == nil)then
      self.m_particle = GD.util_spineCreate("Socre_ThorsStrike_Wild_tuowei",false,true)
      parentNode:addChild(self.m_particle,GD.REEL_SYMBOL_ORDER.REEL_ORDER_2 - 200)
      GD.util_spinePlay(self.m_particle,'idleframe4',false)
    end
  end
end

function ThorsStrikeSlotNode:updateDistance(distance)
  ThorsStrikeSlotNode.super.updateDistance(self,distance)
  if self.m_particle then
    if(self.m_particle:isVisible() == false)then
      self.m_particle:show()
      GD.util_spinePlay(self.m_particle,'idleframe4',false)
    end
    self.m_particle:setPosition(cc.p(self:getPosition()))
  end
end

function ThorsStrikeSlotNode:removeTuowei()
  local trailingNode = self.m_particle
  self.m_particle = nil
  local pos = cc.p(trailingNode:getPosition()) 
  local sizeY = 700
  local time = sizeY / self.m_machine.m_configData.p_reelMoveSpeed
  local actList = {}
  actList[#actList + 1] = cc.MoveTo:create(time,cc.p(pos.x,pos.y - sizeY))
  actList[#actList + 1] = cc.CallFunc:create(function()
    trailingNode:removeFromParent()
  end)
  trailingNode:runAction(cc.Sequence:create(actList))
end
function ThorsStrikeSlotNode:remove()
  local trailingNode = self.m_particle
  self.m_particle = nil
  trailingNode:removeFromParent()
end


function ThorsStrikeSlotNode:reset()
  ThorsStrikeSlotNode.super.reset(self)
  if self.m_particle then self:removeTuowei()end
  --if self.m_particle then self:remove()end
end




return ThorsStrikeSlotNode