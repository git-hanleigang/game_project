---
--xhkj
--2018年6月11日
--FrogPrinceExtraFreeSpinWheelLab.lua

local FrogPrinceExtraFreeSpinWheelLab = class("FrogPrinceExtraFreeSpinWheelLab", util_require("base.BaseView"))

function FrogPrinceExtraFreeSpinWheelLab:initUI(data)
    self:createCsbNode("FrogPrince_wheel_text_0.csb")
    local num = data._num
    self:setExtraFreeSpinNum(num)
end
function FrogPrinceExtraFreeSpinWheelLab:setExtraFreeSpinNum(num)
    local index = 1
    if num == 0 then
        index = 1
    elseif num == 1 then
        index = 2
    elseif num == 3 then
        index = 3
    elseif num == 5 then
        index = 4
    end
    self:runCsbAction("idle" .. index)
end

function FrogPrinceExtraFreeSpinWheelLab:onEnter()
end

function FrogPrinceExtraFreeSpinWheelLab:onExit()
end

return FrogPrinceExtraFreeSpinWheelLab
