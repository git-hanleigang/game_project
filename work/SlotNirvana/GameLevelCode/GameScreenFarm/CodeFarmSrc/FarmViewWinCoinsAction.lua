---
--xcyy
--2018年5月23日
--FarmViewWinCoinsAction.lua

local FarmViewWinCoinsAction = class("FarmViewWinCoinsAction",util_require("base.BaseView"))


function FarmViewWinCoinsAction:initUI()

    self:createCsbNode("Socre_Farm_Bonus_shouji.csb")

    self:setVisible(false)

end


function FarmViewWinCoinsAction:onEnter()
 

end

function FarmViewWinCoinsAction:onExit()
 
end

function FarmViewWinCoinsAction:showAct( )
    self:setVisible(true)
    self:findChild("Particle_1_0"):resetSystem()
    self:runCsbAction("actionframe",false,function(  )
            self:setVisible(false)
    end)
end

return FarmViewWinCoinsAction