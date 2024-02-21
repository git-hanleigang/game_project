---
--island
--2018年4月12日
--CrazyBombWheelFeatherWinView.lua
---- 锁屏玩法 或者FreeSpin玩法
local CrazyBombWheelFeatherWinView = class("CrazyBombWheelFeatherWinView", util_require("base.BaseView"))
CrazyBombWheelFeatherWinView.m_lock = 0
CrazyBombWheelFeatherWinView.m_freespin = 1

function CrazyBombWheelFeatherWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "CrazyBomb/WheelGetFeature.csb"
    self:createCsbNode(resourceFilename)

    if data == self.m_lock then
        self:findChild("Wheel_crazy_3"):setVisible(true)
        self:findChild("Wheel_freespins_1"):setVisible(false)
    
    else
        self:findChild("Wheel_crazy_3"):setVisible(false)
        self:findChild("Wheel_freespins_1"):setVisible(true)
    end

end

function CrazyBombWheelFeatherWinView:initViewData(callBackFun)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)


    self.m_callFun = callBackFun

end


function CrazyBombWheelFeatherWinView:onEnter()
end

function CrazyBombWheelFeatherWinView:onExit()
    
end

function CrazyBombWheelFeatherWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_touch_view_btn.mp3")

        self:runCsbAction("over")
        performWithDelay(self,function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end,1)

    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return CrazyBombWheelFeatherWinView