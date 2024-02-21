---
--xcyy
--2018年5月23日
--PiggyLegendPirateMapSmallItem.lua

local PiggyLegendPirateMapSmallItem = class("PiggyLegendPirateMapSmallItem",util_require("Levels.BaseLevelDialog"))


function PiggyLegendPirateMapSmallItem:initUI(data)

    self:createCsbNode("PiggyLegendPirate_dituxiaoguan.csb")
    self:findChild("m_lb_num"):setString(data.selfPos)
end

function PiggyLegendPirateMapSmallItem:idle()
    self:runCsbAction("idle1",true)
end

function PiggyLegendPirateMapSmallItem:click(func,LitterGameWin)
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_guan_trigger.mp3")
    self:runCsbAction("actionframe",false,function()
        self:completed()
        if func then
            func()
        end
    end)
    
end

function PiggyLegendPirateMapSmallItem:changeSmall( )
    
end

function PiggyLegendPirateMapSmallItem:completed()
    self:runCsbAction("idle2",true)
end


return PiggyLegendPirateMapSmallItem