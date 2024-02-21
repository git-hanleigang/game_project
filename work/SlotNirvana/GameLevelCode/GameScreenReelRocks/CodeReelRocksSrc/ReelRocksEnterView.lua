
local ReelRocksEnterView = class("ReelRocksEnterView", util_require("base.BaseView"))
--fixios0223
function ReelRocksEnterView:initUI(data)
    self.m_click = false

    local resourceFilename = "ReelRocks/StartShow.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("auto")
    -- self:addClick(self:findChild("Panel_1"))
    self.m_csbNode:setPosition(display.center)
    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
    performWithDelay(self.m_delayNode,function ()
        self:removeSelf(false)
    end,240/60)
end

function ReelRocksEnterView:onEnter()
end

function ReelRocksEnterView:onExit()
    
end

function ReelRocksEnterView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return
        end
        self:removeSelf(true)
    end
end

function ReelRocksEnterView:removeSelf(_playAction)
    if self.m_click then
        return
    end

    self.m_delayNode:stopAllActions()
    self.m_click = true

    if _playAction then
        self:runCsbAction("actionframe")
        performWithDelay(self,function()
            self:removeFromParent()
        end,1)
    else
        self:removeFromParent()
    end
   
    
end
return ReelRocksEnterView