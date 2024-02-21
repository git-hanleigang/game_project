---
--xcyy
--2018年5月23日
--PelicanDarkView.lua

local PelicanDarkView = class("PelicanDarkView",util_require("Levels.BaseLevelDialog"))


function PelicanDarkView:initUI()

    self:createCsbNode("Pelican_dark.csb")

end

return PelicanDarkView