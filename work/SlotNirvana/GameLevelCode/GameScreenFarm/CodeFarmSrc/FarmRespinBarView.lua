---
--xcyy
--2018年5月23日
--FarmRespinBarView.lua

local FarmRespinBarView = class("FarmRespinBarView",util_require("base.BaseView"))


function FarmRespinBarView:initUI()

    self:createCsbNode("Farm_RespinsRemaning.csb")

end


function FarmRespinBarView:onEnter()
    

end

function FarmRespinBarView:changeRespinTimes(time,notplay)
    
    self:findChild("respin"):setVisible(false)
    self:findChild("respins"):setVisible(false)
    if time == 3 then
        
        
        if notplay then

        else
           self:runCsbAction("respin") 
            gLobalSoundManager:playSound("FarmSounds/music_Farm_linghtning_rest_3.mp3")
            
            
        end 

    end

    if time > 1 then
        self:findChild("respins"):setVisible(true)
    else
        self:findChild("respin"):setVisible(true)
    end

    self:findChild("m_lb_num"):setString(time) 
    
end

function FarmRespinBarView:changeGoldBonusCoins(coins)
    self:findChild("m_lb_coins"):setString(util_formatCoins(coins,9,nil,nil,true)) 
    self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=0.5,sy=0.5},474)
end

function FarmRespinBarView:onExit()
 
end



return FarmRespinBarView