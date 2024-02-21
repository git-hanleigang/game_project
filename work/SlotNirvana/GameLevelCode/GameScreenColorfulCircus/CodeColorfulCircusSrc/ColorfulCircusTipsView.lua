---
--xcyy
--2018年5月23日
--ColorfulCircusTipsView.lua

local ColorfulCircusTipsView = class("ColorfulCircusTipsView",util_require("Levels.BaseLevelDialog"))


function ColorfulCircusTipsView:initUI()

    self:createCsbNode("ColorfulCircus_Tips.csb")

end




return ColorfulCircusTipsView