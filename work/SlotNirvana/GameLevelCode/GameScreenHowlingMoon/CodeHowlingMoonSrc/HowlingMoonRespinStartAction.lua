---
--xhkj
--2018年6月11日
--HowlingMoonRespinStartAction.lua

local HowlingMoonRespinStartAction = class("HowlingMoonRespinStartAction", util_require("base.BaseView"))

function HowlingMoonRespinStartAction:initUI(data)

    local resourceFilename="Socre_HowlingMoon_shuatu.csb"
    self:createCsbNode(resourceFilename)
end


function HowlingMoonRespinStartAction:onEnter()  
end

function HowlingMoonRespinStartAction:toAction(actionName,isLoop,func)

    self:runCsbAction(actionName,isLoop,func)
end

function HowlingMoonRespinStartAction:onExit()
    
    
end


return HowlingMoonRespinStartAction