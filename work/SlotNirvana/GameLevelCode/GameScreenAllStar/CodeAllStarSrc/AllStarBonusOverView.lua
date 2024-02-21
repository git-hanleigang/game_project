---
--xcyy
--2018年5月23日
--AllStarBonusOverView.lua

local AllStarBonusOverView = class("AllStarBonusOverView",util_require("base.BaseView"))


function AllStarBonusOverView:initUI()

    self:createCsbNode("AllStar/BonusOver.csb")
    self.m_isCanTouch = false
    
    self:findChild("Button_1"):setTouchEnabled(false)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        performWithDelay(self,function(  )
            self:findChild("Button_1"):setTouchEnabled(true)
            self.m_isCanTouch = true 
            globalData.slotRunData:checkViewAutoClick(self,"Button_1")
        end,0.1)
    end)

end

function AllStarBonusOverView:updateCoins( coins)
    local lab = self:findChild("m_lb_coins") 
    if lab and coins then
        lab:setString(util_formatCoins(coins,50))

        self:updateLabelSize({label=lab,sx=0.94,sy=0.94},750)

    end
end



function AllStarBonusOverView:onEnter()
 

end


function AllStarBonusOverView:onExit()

end


function AllStarBonusOverView:initCallFunc(strCoins,func)

    self.m_func = func

    self:updateCoins( strCoins)

end

--默认按钮监听回调
function AllStarBonusOverView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    if self.m_isCanTouch then
        self.m_isCanTouch = false
        if name == "Button_1" then
            
            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_btn_click.mp3")

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



return AllStarBonusOverView