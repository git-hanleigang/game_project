---
--xcyy
--2018年5月23日
--WheelOfRomanceTipView.lua

local WheelOfRomanceTipView = class("WheelOfRomanceTipView",util_require("base.BaseView"))


WheelOfRomanceTipView.VIEW_STETES_START = 0
WheelOfRomanceTipView.VIEW_STETES_IDLE = 1
WheelOfRomanceTipView.VIEW_STETES_OVER = 2

WheelOfRomanceTipView.m_currentStates = nil 

function WheelOfRomanceTipView:initUI(_csbPath)

    self:createCsbNode(_csbPath)


    self.m_funcStart = nil 
    self.m_funcIdle = nil 
    self.m_funcOver = nil 

    self.m_currentStates = self.VIEW_STETES_IDLE

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)

    self:addClick(self:findChild("click")) 

end

function WheelOfRomanceTipView:setCallFunc(_func1,_func2,_func3 )
    
    self.m_funcStart = _func1 
    self.m_funcIdle = _func2 
    self.m_funcOver = _func3

end

function WheelOfRomanceTipView:showView( )
    
    self.m_waitNode:stopAllActions()


    if self.m_currentStates == self.VIEW_STETES_IDLE then
        
        if self.m_funcStart then
            self.m_funcStart()
        end

        self:setVisible(true)

        self.m_currentStates = self.VIEW_STETES_START
        self:runCsbAction("show",false,function(  )

            if self.m_funcIdle then
                self.m_funcIdle()
            end

            self:runCsbAction("idle")
            self.m_currentStates = self.VIEW_STETES_IDLE
        end,60)

        performWithDelay(self.m_waitNode,function(  )
            self:hideView( )
        end,3)

    end

    

end


function WheelOfRomanceTipView:hideView( )
    
    self.m_waitNode:stopAllActions()

    if self.m_currentStates == self.VIEW_STETES_IDLE then
        self.m_currentStates = self.VIEW_STETES_OVER

        if self.m_funcOver then
            self.m_funcOver()
        end

        self:runCsbAction("over",false,function(  )
            self:setVisible(false)
            self:runCsbAction("idle")
            self.m_currentStates = self.VIEW_STETES_IDLE
        end,60)
    end
    

end

function WheelOfRomanceTipView:onEnter()
 

end


function WheelOfRomanceTipView:onExit()
 
end

--默认按钮监听回调
function WheelOfRomanceTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
    
        self:hideView( )
    end
end


return WheelOfRomanceTipView