---
--island
--2018年4月12日
--CrazyBombWheelCoinsWinView.lua
---- 
local CrazyBombWheelCoinsWinView = class("CrazyBombWheelCoinsWinView", util_require("base.BaseView"))


function CrazyBombWheelCoinsWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "CrazyBomb/WheelGetCoins.csb"
    self:createCsbNode(resourceFilename)

end

function CrazyBombWheelCoinsWinView:initViewData(coins,callBackFun)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)


    self.m_callFun = callBackFun
    local labCoin = self:findChild("m_lb_coins")
    labCoin:setString(util_formatCoins(coins,20))
    
    self:updateLabelSize({label=labCoin,sx=1,sy=0.93},709)
    
end


function CrazyBombWheelCoinsWinView:onEnter()
end

function CrazyBombWheelCoinsWinView:onExit()
    
end

function CrazyBombWheelCoinsWinView:clickFunc(sender)
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

return CrazyBombWheelCoinsWinView