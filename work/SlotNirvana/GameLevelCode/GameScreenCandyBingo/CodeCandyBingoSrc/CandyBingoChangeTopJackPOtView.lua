---
--xcyy
--2018年5月23日
--CandyBingoChangeTopJackPOtView.lua

local CandyBingoChangeTopJackPOtView = class("CandyBingoChangeTopJackPOtView",util_require("base.BaseView"))


function CandyBingoChangeTopJackPOtView:initUI()

    self:createCsbNode("Socre_CandyBingo_jackPot_Bar.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线

end


function CandyBingoChangeTopJackPOtView:onEnter()
 

end


function CandyBingoChangeTopJackPOtView:onExit()
 
end



return CandyBingoChangeTopJackPOtView