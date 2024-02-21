---
--xhkj
--2018年6月11日
--DragonsBigWheelLab.lua

local DragonsBigWheelLab = class("DragonsBigWheelLab", util_require("base.BaseView"))

function DragonsBigWheelLab:initUI(data)
    local _type = data._type
    local strName = self:getLabNameByType(_type)
    self:createCsbNode(strName)
end

function DragonsBigWheelLab:onEnter()
 
end

function DragonsBigWheelLab:getLabNameByType(_type)
    local strName = ""
    if _type == "0" then
        strName = "Dragons_wheel_fg.csb"
    elseif _type == "3" then
        strName = "Dragons_wheel_3efg.csb"
    elseif _type == "5" then
        strName = "Dragons_wheel_5efg.csb"
    elseif _type == "8" then
        strName = "Dragons_wheel_8efg.csb"
    elseif _type == "MiniWheel" then
        strName = "Dragons_wheel_bw_mini.csb"
    elseif _type == "MinorWheel" then
        strName = "Dragons_wheel_bw_minor.csb"
    elseif _type == "MajorWheel" then
        strName = "Dragons_wheel_bw_major.csb"
    elseif _type == "SuperWheel" then
        strName = "Dragons_wheel_bw_super.csb"
    elseif _type == "Mini" then 
        strName = "Dragons_wheel_mini.csb"
    elseif _type == "Minor" then 
        strName = "Dragons_wheel_minor.csb"
    elseif _type == "Major" then
        strName = "Dragons_wheel_major.csb"
    elseif _type == "Grand" then
        strName = "Dragons_wheel_grand.csb"
    end

    return strName
end

function DragonsBigWheelLab:onExit()
    
end


return DragonsBigWheelLab