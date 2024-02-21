---
--xcyy
--2018年5月23日
--PalaceWishRespinBarView.lua

local PalaceWishRespinBarView = class("PalaceWishRespinBarView",util_require("base.BaseView"))


function PalaceWishRespinBarView:initUI()

    self:createCsbNode("PalaceWish_tishibar.csb")
end


function PalaceWishRespinBarView:onEnter()
 

end

function PalaceWishRespinBarView:changeRespinTimes(times,isinit)

    local lab1 =  self:findChild("PalaceWish_tishi_1_3_0")
    local lab2 =  self:findChild("PalaceWish_tishi_2_5_0")
    local lab3 =  self:findChild("PalaceWish_tishi_3_7_0")

    lab1:setVisible(true)
    lab2:setVisible(true)
    lab3:setVisible(true)

    if times == 0 then

    elseif times == 1 then
        lab1:setVisible(false)

    elseif times == 2 then

        lab2:setVisible(false)

    elseif times == 3 then
        if not isinit then
            self:runCsbAction("actionframe")

            -- local rand = math.random(1,100)
            -- if rand < 30 then
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_respin_resetTimes.mp3")
            -- end
            
        end
        
        lab3:setVisible(false)
    end
    
end

function PalaceWishRespinBarView:onExit()
 
end


return PalaceWishRespinBarView