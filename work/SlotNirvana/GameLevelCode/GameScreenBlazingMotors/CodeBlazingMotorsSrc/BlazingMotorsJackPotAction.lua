---
--xcyy
--2018年5月23日
--BlazingMotorsJackPotAction.lua

local BlazingMotorsJackPotAction = class("BlazingMotorsJackPotAction",util_require("base.BaseView"))


function BlazingMotorsJackPotAction:initUI(id)

    local csbPath = "BlazingMotors_jackpot_effect_" .. id .. ".csb"
    self:createCsbNode(csbPath)


end


function BlazingMotorsJackPotAction:onEnter()
 

end

function BlazingMotorsJackPotAction:onExit()
 
end



return BlazingMotorsJackPotAction