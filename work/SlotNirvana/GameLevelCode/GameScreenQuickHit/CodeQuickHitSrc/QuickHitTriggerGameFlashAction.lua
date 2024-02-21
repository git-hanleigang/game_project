---
--xhkj
--2018年6月11日
--QuickHitTriggerGameFlashAction.lua

local QuickHitTriggerGameFlashAction = class("QuickHitTriggerGameFlashAction", util_require("base.BaseView"))
QuickHitTriggerGameFlashAction.waitTime = 0

function QuickHitTriggerGameFlashAction:initUI()

    local resourceFilename="Socre_QuickHit_Wheelxingxing.csb"
    self:createCsbNode(resourceFilename)

    self:findChild("Particle_1"):setPosition(cc.p(0,806)) -- -848
    self:findChild("Particle_2"):setPosition(cc.p(0,806)) -- -848
    self:findChild("Particle_3"):setPosition(cc.p(0,806)) -- -848
    self:findChild("Particle_4"):setPosition(cc.p(0,806)) -- -848

    self:findChild("Particle_1"):setPositionType(1)
    self:findChild("Particle_2"):setPositionType(1)
    self:findChild("Particle_3"):setPositionType(1)
    self:findChild("Particle_4"):setPositionType(1)

    self.waitTime = 1
    self:runFlashAction( )
    self:runFlashAction2()
    self:runFlashAction3()
    self:runFlashAction4()
end

function QuickHitTriggerGameFlashAction:runFlashAction( )
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(self.waitTime,cc.p(0,-848))
    self:findChild("Particle_1"):runAction(cc.Sequence:create(actionList))
end

function QuickHitTriggerGameFlashAction:runFlashAction2( )
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(self.waitTime,cc.p(0,-848))
    self:findChild("Particle_2"):runAction(cc.Sequence:create(actionList))
end
function QuickHitTriggerGameFlashAction:runFlashAction3( )
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(self.waitTime,cc.p(0,-848))
    self:findChild("Particle_3"):runAction(cc.Sequence:create(actionList))
end
function QuickHitTriggerGameFlashAction:runFlashAction4( )
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(self.waitTime,cc.p(0,-848))
    self:findChild("Particle_4"):runAction(cc.Sequence:create(actionList))
end

function QuickHitTriggerGameFlashAction:getWaitTime( )
    return self.waitTime
end

function QuickHitTriggerGameFlashAction:onEnter()
   

end


function QuickHitTriggerGameFlashAction:onExit()
    
end

function QuickHitTriggerGameFlashAction:removeSelf(func)
    if func then
        func()
    end
    self:removeFromParent()
end

function QuickHitTriggerGameFlashAction:initMachine(machine)
    self.m_machine = machine
end

return QuickHitTriggerGameFlashAction