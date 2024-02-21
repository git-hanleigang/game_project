---
--xcyy
--2018年5月23日
--FortuneGodMapMoveItem.lua

local FortuneGodMapMoveItem = class("FortuneGodMapMoveItem",util_require("Levels.BaseLevelDialog"))


function FortuneGodMapMoveItem:initUI()

    self:createCsbNode("Socre_FortuneGod_mapcaishen.csb")

end


return FortuneGodMapMoveItem