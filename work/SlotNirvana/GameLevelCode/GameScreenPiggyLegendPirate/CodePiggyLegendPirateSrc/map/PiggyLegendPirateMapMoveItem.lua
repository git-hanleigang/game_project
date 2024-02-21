---
--xcyy
--2018年5月23日
--PiggyLegendPirateMapMoveItem.lua

local PiggyLegendPirateMapMoveItem = class("PiggyLegendPirateMapMoveItem",util_require("Levels.BaseLevelDialog"))


function PiggyLegendPirateMapMoveItem:initUI()

    self:createCsbNode("PiggyLegendPirate_dituchuan.csb")

    self.m_chuanSpine = util_spineCreate("PiggyLegendPirate_dituchuan", true, true)
    self:findChild("chuan"):addChild(self.m_chuanSpine)
end


return PiggyLegendPirateMapMoveItem