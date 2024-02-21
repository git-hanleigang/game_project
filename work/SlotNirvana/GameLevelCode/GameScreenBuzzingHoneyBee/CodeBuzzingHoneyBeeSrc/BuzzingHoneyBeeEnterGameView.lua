
local BuzzingHoneyBeeEnterGameView = class("BuzzingHoneyBeeEnterGameView", util_require("base.BaseView"))
--fixios0223
function BuzzingHoneyBeeEnterGameView:initUI(data)
    self.m_click = false

    local resourceFilename = "Socre_BuzzingHoneyBee_start.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idle")
    self:addClick(self:findChild("Panel_1"))
    self.m_csbNode:setPosition(display.center)
    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
    performWithDelay(self.m_delayNode,function ()
        self:removeSelf()
    end,3)
end

function BuzzingHoneyBeeEnterGameView:onEnter()
end

function BuzzingHoneyBeeEnterGameView:onExit()
    
end

function BuzzingHoneyBeeEnterGameView:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_1" then
        if self.m_click == true then
            return
        end
        self:removeSelf()
    end
end

function BuzzingHoneyBeeEnterGameView:removeSelf()
    self.m_delayNode:stopAllActions()
    self.m_click = true
    self:runCsbAction("actionframe")
    performWithDelay(self,function()
        self:removeFromParent()
    end,1)
end
return BuzzingHoneyBeeEnterGameView