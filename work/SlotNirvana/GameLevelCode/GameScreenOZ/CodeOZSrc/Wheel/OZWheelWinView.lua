---
--xcyy
--2018年5月23日
--OZWheelWinView.lua

local OZWheelWinView = class("OZWheelWinView",util_require("base.BaseView"))


function OZWheelWinView:initUI(csbPath)

    self:createCsbNode(csbPath .. ".csb")

    self:findChild("Button_1"):setTouchEnabled(false)
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self:findChild("Button_1"):setTouchEnabled(true)
    end)

end


function OZWheelWinView:onEnter()
 

end

function OZWheelWinView:setEndCalFunc( func )

    self.m_overCallFunc = function(  )
        if func then
            func()
        end
    end
    
end
function OZWheelWinView:onExit()
 
end

function OZWheelWinView:closeUI( )
    
    self:runCsbAction("over",false,function(  )
        if self.m_overCallFunc then
            self.m_overCallFunc()
        end

    end)

end

--默认按钮监听回调
function OZWheelWinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        
        self:findChild("Button_1"):setTouchEnabled(false)

        self:closeUI( )
    end

end


return OZWheelWinView