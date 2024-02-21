---
--xcyy
--2018年5月30日
--JackpotCherryBG.lua
local JackpotCherryBG = class("JackpotCherryBG", util_require("base.BaseView"))

function JackpotCherryBG:initUI(data)
    self:createCsbNode("Socre_LightCherry_CherryBG.csb")
end

function JackpotCherryBG:toAction(actionName)
    self:runCsbAction(actionName)
end

return JackpotCherryBG