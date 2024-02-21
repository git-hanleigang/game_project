---
--xcyy
--2018年5月23日
--LuxeVegasFreeTitleBar.lua
local PublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasFreeTitleBar = class("LuxeVegasFreeTitleBar",util_require("Levels.BaseLevelDialog"))


function LuxeVegasFreeTitleBar:initUI(_machine)

    self:createCsbNode("LuxeVegas_FGtitle.csb")

    self:runCsbAction("idle", true) -- 播放时间线

    self.m_machine = _machine
end

function LuxeVegasFreeTitleBar:showFreeTitleMul(_mul)
    self:findChild("Node_mul_10"):setVisible(_mul==self.m_machine.M_ENUM_TYPE.FREE_1)
    self:findChild("Node_mul_25"):setVisible(_mul==self.m_machine.M_ENUM_TYPE.FREE_2)
    self:findChild("Node_mul_50"):setVisible(_mul==self.m_machine.M_ENUM_TYPE.FREE_3)
end

return LuxeVegasFreeTitleBar
