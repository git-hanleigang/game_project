---
--xcyy
--2018年5月23日
--TripletroveJackpotSpotView.lua

local TripletroveJackpotSpotView = class("TripletroveJackpotSpotView",util_require("Levels.BaseLevelDialog"))


function TripletroveJackpotSpotView:initUI(index)

    self:createCsbNode("Tripletrove_jackpot_dian.csb")
    self:changeShowJackpotColor(index)
end

function TripletroveJackpotSpotView:changeShowJackpotColor(index)
    for i=1,6 do
        if index == i then
            self:findChild("Tripletrove_" .. i):setVisible(true)
        else
            self:findChild("Tripletrove_" .. i):setVisible(false)
        end
    end
end

function TripletroveJackpotSpotView:showJackpotSpotEffect(isStart)
    if isStart then
        self:runCsbAction("start",false,function (  )
            self:runCsbAction("idle")
        end)
    else
        self:runCsbAction("idle")
    end
    
end

function TripletroveJackpotSpotView:setJackpotSpotHideEffect( )
    self:runCsbAction("idle2")
end

return TripletroveJackpotSpotView