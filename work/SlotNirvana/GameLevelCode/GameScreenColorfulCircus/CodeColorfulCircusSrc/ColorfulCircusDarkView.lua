---
--xcyy
--2018年5月23日
--ColorfulCircusDarkView.lua

local ColorfulCircusDarkView = class("ColorfulCircusDarkView",util_require("Levels.BaseLevelDialog"))


function ColorfulCircusDarkView:initUI()

    self:createCsbNode("ColorfulCircus_dark.csb")

end

return ColorfulCircusDarkView