---
--xcyy
--2018年5月23日
--TripletroveJackpotSpotFinishView.lua

local TripletroveJackpotSpotFinishView = class("TripletroveJackpotSpotFinishView",util_require("Levels.BaseLevelDialog"))


function TripletroveJackpotSpotFinishView:initUI()

    self:createCsbNode("Tripletrove_jackpot_dian_tishi.csb")

end

function TripletroveJackpotSpotFinishView:showSpotEffect( )
    self:runCsbAction("actionframe",true)
end


return TripletroveJackpotSpotFinishView