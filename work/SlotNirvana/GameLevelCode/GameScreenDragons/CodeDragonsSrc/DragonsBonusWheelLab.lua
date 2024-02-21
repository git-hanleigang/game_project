---
--xhkj
--2018年6月11日
--DragonsBonusWheelLab.lua

local DragonsBonusWheelLab = class("DragonsBonusWheelLab", util_require("base.BaseView"))

function DragonsBonusWheelLab:initUI(data)
    local num = data.num
    local strName = "Dragons_wheel1_" .. num .. ".csb"
    self:createCsbNode(strName)
end

function DragonsBonusWheelLab:onEnter()
 
end

function DragonsBonusWheelLab:onExit()
    
end

return DragonsBonusWheelLab