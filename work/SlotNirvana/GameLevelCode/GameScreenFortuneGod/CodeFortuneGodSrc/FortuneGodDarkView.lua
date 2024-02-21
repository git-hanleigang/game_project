---
--xcyy
--2018年5月23日
--FortuneGodDarkView.lua

local FortuneGodDarkView = class("FortuneGodDarkView",util_require("Levels.BaseLevelDialog"))


function FortuneGodDarkView:initUI()

    self:createCsbNode("FortuneGod_dark.csb")

end

return FortuneGodDarkView