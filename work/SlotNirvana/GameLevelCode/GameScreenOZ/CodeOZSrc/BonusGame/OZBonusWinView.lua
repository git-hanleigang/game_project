---
--xcyy
--2018年5月23日
--OZBonusWinView.lua

local OZBonusWinView = class("OZBonusWinView",util_require("base.BaseView"))


function OZBonusWinView:initUI(csbPath)

    self:createCsbNode(csbPath .. ".csb")

    self:findChild("Button_1"):setTouchEnabled(false)
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        
    end)

end


function OZBonusWinView:onEnter()
 

end

function OZBonusWinView:setEndCalFunc( func )

    self.m_overCallFunc = function(  )
        if func then
            func()
        end
    end
    
end
function OZBonusWinView:onExit()
 
end

function OZBonusWinView:closeUI( )
    
    self:runCsbAction("over",false,function(  )
        if self.m_overCallFunc then
            self.m_overCallFunc()
        end

    end)

end

--默认按钮监听回调
function OZBonusWinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        self:findChild("Button_1"):setTouchEnabled(false)

        self:closeUI( )
    end

end


return OZBonusWinView