---
--island
--2018年4月12日
--CrazyBombWheelJackPotWinView.lua
---- 
local CrazyBombWheelJackPotWinView = class("CrazyBombWheelJackPotWinView", util_require("base.BaseView"))
CrazyBombWheelJackPotWinView.m_strNodeName = {"Grand", "Major", "Minor", "Mini"}

function CrazyBombWheelJackPotWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "CrazyBomb/WheelJackpot.csb"
    self:createCsbNode(resourceFilename)

end

function CrazyBombWheelJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)
    self:showJackPotType(index)

    self.m_callFun = callBackFun
    local labCoin = self:findChild("m_lb_coins")
    labCoin:setString(util_formatCoins(coins,20))
    
    self:updateLabelSize({label=labCoin,sx=1,sy=1},701)
    
end

function CrazyBombWheelJackPotWinView:showJackPotType( index )
    for i,v in ipairs(self.m_strNodeName) do
        local node = self:findChild(v)

        if index == i then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
    
end

function CrazyBombWheelJackPotWinView:onEnter()
end

function CrazyBombWheelJackPotWinView:onExit()
    
end

function CrazyBombWheelJackPotWinView:clickFunc(sender)
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

return CrazyBombWheelJackPotWinView