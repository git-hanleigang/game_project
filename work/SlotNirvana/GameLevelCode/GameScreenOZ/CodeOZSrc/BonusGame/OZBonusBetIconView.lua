---
--xcyy
--2018年5月23日
--OZBonusBetIconView.lua

local OZBonusBetIconView = class("OZBonusBetIconView",util_require("base.BaseView"))


function OZBonusBetIconView:initUI(game)

    self.m_game = game
    self:createCsbNode("OZ_bx_5x.csb")

    self:runCsbAction("idle")
end




function OZBonusBetIconView:onEnter()
 

end


function OZBonusBetIconView:onExit()
 
end

return OZBonusBetIconView