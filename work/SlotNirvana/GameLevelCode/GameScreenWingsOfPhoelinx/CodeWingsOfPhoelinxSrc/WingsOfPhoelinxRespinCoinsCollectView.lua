---
--xcyy
--2018年5月23日
--WingsOfPhoelinxRespinCoinsCollectView.lua

local WingsOfPhoelinxRespinCoinsCollectView = class("WingsOfPhoelinxRespinCoinsCollectView",util_require("Levels.BaseLevelDialog"))



function WingsOfPhoelinxRespinCoinsCollectView:initUI()

    self:createCsbNode("WingsOfPhoelinx_bonusjishukuang.csb")
    self.m_coins = 0
    self.overFunc = nil
    self.m_click = true
end


function WingsOfPhoelinxRespinCoinsCollectView:onEnter()

    WingsOfPhoelinxRespinCoinsCollectView.super.onEnter(self)

end

function WingsOfPhoelinxRespinCoinsCollectView:onExit()
    WingsOfPhoelinxRespinCoinsCollectView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

--初始化板子上的钱数
function WingsOfPhoelinxRespinCoinsCollectView:resetLabel(winCoins)
    if winCoins ~= nil then
        local node=self:findChild("BitmapFontLabel_1")
        node:setString(util_formatCoins(winCoins,50))
        self:updateLabelSize({label=node,sx=0.61,sy=0.61},697)
        -- self:findChild("BitmapFontLabel_1"):setString(winCoins)
        self.m_coins = winCoins
    else
        self:findChild("BitmapFontLabel_1"):setString("")
        self.m_coins = 0
    end
    
end

function WingsOfPhoelinxRespinCoinsCollectView:UpdateWinLabel(coins)
    self.m_coins = self.m_coins + coins
    local node=self:findChild("BitmapFontLabel_1")
    node:setString(util_formatCoins(self.m_coins,50))
    self:updateLabelSize({label=node,sx=0.61,sy=0.61},697)
end

function WingsOfPhoelinxRespinCoinsCollectView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

        if self.m_click == true then
            return 
        end

        -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/music_WingsOfPhoelinxs_Click_Collect.mp3")
        self.m_click = true
        self:runCsbAction("over",false,function (  )
            if self.overFunc then
                self.overFunc()
                self.overFunc = nil
            end
        end)
    end
end

function WingsOfPhoelinxRespinCoinsCollectView:setOverFunc(func)
    self.overFunc = func
end

function WingsOfPhoelinxRespinCoinsCollectView:setOverShow( )

    self.m_click = true
    
    self:stopAllActions()
    local particle = self:findChild("Particle_1")
    gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Link_WingsOfPhoelinx_overView.mp3")
    self:runCsbAction("actionframe3",false,function (  )
        self:runCsbAction("idle",true)
        particle:stopSystem()--移动结束后将拖尾停掉
        self.m_click = false
    end)
    performWithDelay(self,function (  )
        particle:resetSystem()
    end,45/60)
end

return WingsOfPhoelinxRespinCoinsCollectView