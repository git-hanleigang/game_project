---
--xcyy
--2018年5月23日
--DiscoFeverJackPotjpUpgrade_2_View.lua

local DiscoFeverJackPotjpUpgrade_2_View = class("DiscoFeverJackPotjpUpgrade_2_View",util_require("base.BaseView"))


function DiscoFeverJackPotjpUpgrade_2_View:initUI()

    self:createCsbNode("DiscoFever_jackpot_shengji_0.csb")



end


function DiscoFeverJackPotjpUpgrade_2_View:onEnter()
 

end


function DiscoFeverJackPotjpUpgrade_2_View:onExit()
 
end

function DiscoFeverJackPotjpUpgrade_2_View:updateSpriteVisible( index)
    

    for i=1,5 do
        local name = "Sprite_"..i
        local spr = self:findChild(name)
        if spr then
            spr:setVisible(false)
            if i == index then
                spr:setVisible(true)
            end
        end
        
    end
end


return DiscoFeverJackPotjpUpgrade_2_View