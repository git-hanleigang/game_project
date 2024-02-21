---
--island
--2018年6月5日
--HowlingMoonSprAction.lua

local HowlingMoonSprAction = class("HowlingMoonSprAction", util_require("base.BaseView"))

function HowlingMoonSprAction:initUI(data)

    local resourceFilename="LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Tittle.csb"
    self:createCsbNode(resourceFilename)

    self:runCsbAction("actionframe",true)    
end

function HowlingMoonSprAction:onEnter()

end


function HowlingMoonSprAction:onExit()
    
end


return HowlingMoonSprAction