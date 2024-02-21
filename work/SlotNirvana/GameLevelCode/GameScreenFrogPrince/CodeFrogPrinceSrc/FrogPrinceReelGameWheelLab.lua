---
--xhkj
--2018年6月11日
--FrogPrinceReelGameWheelLab.lua

local FrogPrinceReelGameWheelLab = class("FrogPrinceReelGameWheelLab", util_require("base.BaseView"))

function FrogPrinceReelGameWheelLab:initUI(data)
    self:createCsbNode("FrogPrince_wheel_text.csb")
    local num = data._num 
    self:setReelGameNum(num)
end


function FrogPrinceReelGameWheelLab:onEnter()
 
end

function FrogPrinceReelGameWheelLab:setReelGameNum(num)
    local label =  self:findChild("BitmapFontLabel_1") -- 获得子节点
    label:setString(tostring(num))
end

function FrogPrinceReelGameWheelLab:onExit()
    
end

return FrogPrinceReelGameWheelLab