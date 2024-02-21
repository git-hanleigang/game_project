---
--xcyy
--2018年5月23日
--FarmBonus_Wheel_SpinView.lua

local FarmBonus_Wheel_SpinView = class("FarmBonus_Wheel_SpinView",util_require("base.BaseView"))

FarmBonus_Wheel_SpinView.m_CanTouch = nil

FarmBonus_Wheel_SpinView.m_ClickCall = nil

function FarmBonus_Wheel_SpinView:initUI()

    self:createCsbNode("Farm_zhuanpan_spin.csb")


    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("click_CloseAuto"))
    self:findChild("click_CloseAuto"):setVisible(false)
    

    self:runCsbAction("actionframe",true,nil,60)

    self.m_dealyNode = cc.Node:create()
    self:addChild(self.m_dealyNode)

    self.m_autoSpinUI = util_createAnimation("Farm_zhuanpan_auto.csb") 
    self:findChild("autoSpin"):addChild(self.m_autoSpinUI)
    self:findChild("autoSpin"):setVisible(false)
end


function FarmBonus_Wheel_SpinView:onEnter()
 

end

function FarmBonus_Wheel_SpinView:setCanTouch(states)
    self.m_CanTouch = states

    if states then
        self:runCsbAction("idleframe")
    else
 
    end
end

function FarmBonus_Wheel_SpinView:setClickCall(func )
    self.m_ClickCall = func
end

function FarmBonus_Wheel_SpinView:onExit()
 
end

function FarmBonus_Wheel_SpinView:setSpinBtnParent( Parent  )
    self.m_Parent = Parent 
end


--点击监听
function FarmBonus_Wheel_SpinView:clickStartFunc(sender)
    self.m_ClickTimes = 0

    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        if self.m_CanTouch then
            self:runCsbAction("idleframe2")
            performWithDelay(self.m_dealyNode,function(  )
                self.m_Parent:OpenAutoSpin( )  
    
                performWithDelay(self,function(  )
                    self:runCsbAction("idleframe")
                end,0.1)
    
                if self.m_ClickCall then
                    self.m_ClickCall()
                    self.m_ClickCall = nil
                end 
    
            end,1)
        end
        
        

    elseif name == "click_CloseAuto" then
        self.m_autoSpinUI:runCsbAction("idleframe2")
    end
    

end

--结束监听
function FarmBonus_Wheel_SpinView:clickEndFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self.m_dealyNode:stopAllActions()
        performWithDelay(self,function(  )
            self:runCsbAction("idleframe")
        end,0.1)
    elseif name == "click_CloseAuto" then
        performWithDelay(self,function(  )
            self.m_autoSpinUI:runCsbAction("idleframe")
        end,0.1)

    end
end


--默认按钮监听回调
function FarmBonus_Wheel_SpinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self.m_dealyNode:stopAllActions()
       

        if self.m_CanTouch then

            performWithDelay(self,function(  )
                self:runCsbAction("idleframe")
            end,0.1)

            print(" wheel  click clickclickclickclickclick") 

            if self.m_ClickCall then
                self.m_ClickCall()
                self.m_ClickCall = nil
            end

            self.m_CanTouch = false

        end

    elseif name == "click_CloseAuto" then 
        self.m_Parent:CloseAutoSpin( )
        performWithDelay(self,function(  )
            self.m_autoSpinUI:runCsbAction("idleframe")
        end,0.1)
    end

end


return FarmBonus_Wheel_SpinView