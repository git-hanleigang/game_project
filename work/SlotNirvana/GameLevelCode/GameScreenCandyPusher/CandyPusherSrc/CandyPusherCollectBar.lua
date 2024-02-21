---
--xcyy
--2018年5月23日
--CandyPusherCollectBar.lua

local CandyPusherCollectBar = class("CandyPusherCollectBar",util_require("base.BaseView"))
CandyPusherCollectBar.m_points = {}

function CandyPusherCollectBar:initUI(machine)
    self:createCsbNode("CandyPusher_shouji.csb")
    
    self.m_tip = util_createAnimation("CandyPusher_Tips.csb")
    machine:findChild("Node_tips"):addChild(self.m_tip)
    self.m_tip.m_states = "idle"
    self.m_tip:setVisible(false)


    self.m_super = util_createAnimation("CandyPusher_shouji_zi.csb")
    self:findChild("Node_Zi"):addChild(self.m_super)

    self:initCollectPoint( )
end

function CandyPusherCollectBar:initCollectPoint( )

    self.m_points = {}

    for i=1,10 do
       local parentNode = self:findChild("Node_"..i) 
        local point = util_createAnimation("CandyPusher_shouji_coin.csb")
        parentNode:addChild(point)
        table.insert(self.m_points,point)
        point:setVisible(false)
    end
end

function CandyPusherCollectBar:showTriggerAnimation( _func )
    self:stopAllActions()

    for i=1,#self.m_points do
        local points = self.m_points[i]
        if not points:isVisible() then
            points:setVisible(true)
            points:runCsbAction("actionframe")
            break
        end
    end


    performWithDelay(self,function(  )
        if _func then
            _func()
        end
    end,51/60)
end

function CandyPusherCollectBar:showFullAnimation( _func )
    self.m_super:runCsbAction("actionframe")
    self:runCsbAction("actionframe",false,function(  )
        if _func then
            _func()
        end
    end)

end

function CandyPusherCollectBar:updatePoints(_currNUm )
    
    for i=1,#self.m_points do
        local points = self.m_points[i]
        if i <= _currNUm then
            points:runCsbAction("idle")
            points:setVisible(true)
        else
            points:setVisible(false)
        end
    end

end

function CandyPusherCollectBar:showTip( )
    self.m_tip:stopAllActions()
    self.m_tip:setVisible(true)
    self.m_tip.m_states = "start"
    self.m_tip:runCsbAction("show",false,function(  )
        self.m_tip.m_states = "idle"
    end)
    performWithDelay(self.m_tip,function(  )
        self:hideTip( )
    end,3)
    
end

function CandyPusherCollectBar:hideTip( )
    self.m_tip:stopAllActions()
    self.m_tip.m_states = "over"
    self.m_tip:runCsbAction("over",false,function(  )
        self.m_tip.m_states = "idle"
        self.m_tip:setVisible(false)
    end)
end

function CandyPusherCollectBar:quickTip( )
    self.m_tip:stopAllActions()
    self.m_tip.m_states = "idle"
    self.m_tip:setVisible(false)
end

--默认按钮监听回调
function CandyPusherCollectBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_i" then
        if self.m_tip.m_states == "idle" then
            if self.m_tip:isVisible() then
                self:hideTip( )
            else
                self:showTip( )
            end
        end
        
    end
end

return CandyPusherCollectBar