---
--xcyy
--2018年5月23日
--FortuneCatsJackpotHead.lua

local FortuneCatsJackpotHead = class("FortuneCatsJackpotHead",util_require("base.BaseView"))


function FortuneCatsJackpotHead:initUI()
    self:createCsbNode("FortuneCats_jackpot_maotou.csb")
end

function FortuneCatsJackpotHead:onEnter()
end


function FortuneCatsJackpotHead:onExit()
end

return FortuneCatsJackpotHead