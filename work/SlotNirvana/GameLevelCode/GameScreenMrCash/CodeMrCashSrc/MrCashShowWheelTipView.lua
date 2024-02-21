---
--xcyy
--2018年5月23日
--MrCashShowWheelTipView.lua

local MrCashShowWheelTipView = class("MrCashShowWheelTipView",util_require("base.BaseView"))

MrCashShowWheelTipView.m_machine = nil

function MrCashShowWheelTipView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("MrCash/FeatureStart.csb")

    self:addClick(self:findChild("click"))
end


function MrCashShowWheelTipView:onEnter()
 

end



function MrCashShowWheelTipView:onExit()
 
end

function MrCashShowWheelTipView:setClickCallFunc( func )
    self.m_callFunc = function(  )

        self:runCsbAction("over",false,function(  )
            if func then
                func()
            end

            self:removeFromParent()

        end)
        
    end
end

--默认按钮监听回调
function MrCashShowWheelTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self:findChild("click"):setVisible(false)
        gLobalSoundManager:playSound("MrCashSounds/music_MrCash_BrnClick.mp3")

        if self.m_callFunc then
            self.m_callFunc()
        end

    end

end


return MrCashShowWheelTipView