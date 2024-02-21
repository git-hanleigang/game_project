---
--xcyy
--2018年5月23日
--PelicanTipsView.lua

local PelicanTipsView = class("PelicanTipsView",util_require("Levels.BaseLevelDialog"))


function PelicanTipsView:initUI()

    self:createCsbNode("Pelican_Tips.csb")

end




return PelicanTipsView