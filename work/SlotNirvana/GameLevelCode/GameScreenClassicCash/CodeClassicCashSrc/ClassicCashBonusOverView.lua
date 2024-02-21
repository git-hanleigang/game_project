---
--xcyy
--2018年5月23日
--ClassicCashBonusOverView.lua

local ClassicCashBonusOverView = class("ClassicCashBonusOverView",util_require("base.BaseView"))
local PublicConfig = require "ClassicCashPublicConfig"

function ClassicCashBonusOverView:initUI()

    self:createCsbNode("ClassicCash/BonusOver.csb")
    self.m_isCanTouch = false
    
    self:findChild("Button"):setTouchEnabled(false)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self:findChild("Button"):setTouchEnabled(true)
        self.m_isCanTouch = true 
        globalData.slotRunData:checkViewAutoClick(self,"Button_1")
    end)
end

function ClassicCashBonusOverView:updateCoins( coins)
    local lab = self:findChild("m_lb_coins") 
    if lab and coins then
        lab:setString(util_formatCoins(coins,50))

        self:updateLabelSize({label=lab,sx=1,sy=1},630)

    end
end



function ClassicCashBonusOverView:onEnter()
 

end


function ClassicCashBonusOverView:onExit()
 
end


function ClassicCashBonusOverView:initCallFunc(strCoins,func)

    self.m_func = func

    self:updateCoins( strCoins)

end

--默认按钮监听回调
function ClassicCashBonusOverView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    if self.m_isCanTouch then
        self.m_isCanTouch = false
        if name == "Button" then
            gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
            performWithDelay(self, function()
                gLobalSoundManager:playSound(PublicConfig.Music_Respin_OverOver) 
            end, 5/60)
            performWithDelay(self,function(  )
                if self.m_func then
                    self.m_func()
                end
            end,0.2)
            self:runCsbAction("over",false,function(  )
                if self then
                    self:removeFromParent()
                end
            end)
        end
    end
    
end



return ClassicCashBonusOverView