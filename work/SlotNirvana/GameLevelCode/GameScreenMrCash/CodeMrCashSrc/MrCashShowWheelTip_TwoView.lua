---
--xcyy
--2018年5月23日
--MrCashShowWheelTip_TwoView.lua

local MrCashShowWheelTip_TwoView = class("MrCashShowWheelTip_TwoView",util_require("base.BaseView"))

MrCashShowWheelTip_TwoView.m_machine = nil

function MrCashShowWheelTip_TwoView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("MrCash/JackpoStart.csb")

    self:addClick(self:findChild("click"))

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)
end


function MrCashShowWheelTip_TwoView:onEnter()
 

end



function MrCashShowWheelTip_TwoView:onExit()
 
end

function MrCashShowWheelTip_TwoView:setClickCallFunc( func ,func1 )
    self.m_callFunc = function(  )

        if func1 then
            func1()
        end

        self:runCsbAction("over",false,function(  )
            if func then
                func()
            end

            self:removeFromParent()

        end)
        
    end
end

--默认按钮监听回调
function MrCashShowWheelTip_TwoView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then

        self.m_actNode:stopAllActions()

        self:findChild("click"):setVisible(false)
        gLobalSoundManager:playSound("MrCashSounds/music_MrCash_BrnClick.mp3")

        if self.m_callFunc then
            self.m_callFunc()
        end

    end

end


return MrCashShowWheelTip_TwoView