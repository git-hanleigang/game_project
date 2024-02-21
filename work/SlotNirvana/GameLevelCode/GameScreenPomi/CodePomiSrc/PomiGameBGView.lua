---
--xcyy
--2018年5月23日
--PomiGameBGView.lua

local PomiGameBGView = class("PomiGameBGView",util_require("views.gameviews.GameMachineBG"))


function PomiGameBGView:getUIScalePro()

    local ratio = display.width / display.height
    if ratio <= 1.34 then
        return 1
    end

    local x=display.width/DESIGN_SIZE.width
    local y=display.height/DESIGN_SIZE.height
    local pro = 1 -- x/y
    return pro
end

return PomiGameBGView