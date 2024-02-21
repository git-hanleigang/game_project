---
--xcyy
--2018年5月23日
--PiggyLegendPirateMapBigItem.lua

local PiggyLegendPirateMapBigItem = class("PiggyLegendPirateMapBigItem",util_require("Levels.BaseLevelDialog"))

local BIG_LEVEL = {
    LEVEL1 = 2,
    LEVEL2 = 7,
    LEVEL3 = 13,
    LEVEL4 = 20
}

function PiggyLegendPirateMapBigItem:initUI(data)
    self:createCsbNode("PiggyLegendPirate_ditudaguan.csb")

    self.posIndex = data.selfPos
    self:changeFile(data)

end

function PiggyLegendPirateMapBigItem:changeFile(data)
    local nodeName = {"Node_ditudaguan1","Node_ditudaguan2","Node_ditudaguan3","Node_ditudaguan4"}

    for i,vName in ipairs(nodeName) do
        self:findChild(vName):setVisible(false)
    end

    if data.selfPos == BIG_LEVEL.LEVEL1 then
        self:findChild("Node_ditudaguan1"):setVisible(true)
    elseif data.selfPos == BIG_LEVEL.LEVEL2 then
        self:findChild("Node_ditudaguan2"):setVisible(true)
    elseif data.selfPos == BIG_LEVEL.LEVEL3 then
        self:findChild("Node_ditudaguan3"):setVisible(true)
    elseif data.selfPos == BIG_LEVEL.LEVEL4 then
        self:findChild("Node_ditudaguan4"):setVisible(true)
    end
end

function PiggyLegendPirateMapBigItem:idle()
    self:runCsbAction("idle1",true)
end

function PiggyLegendPirateMapBigItem:click(func, LitterGameWin)
    self:findChild("Particle_1"):resetSystem()
    self:findChild("Particle_1_0"):resetSystem()
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_daguan_trigger.mp3")

    self:waitWithDelay(56/60, function()
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_map_guan_trigger.mp3")
    end)
    
    self:runCsbAction("actionframe1",false,function()
        self:completed()
        if func then
            func()
        end
    end)

end

function PiggyLegendPirateMapBigItem:completed()
    self:runCsbAction("idle2",true)
end

-- 延时函数
function PiggyLegendPirateMapBigItem:waitWithDelay(time, endFunc, parent)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

return PiggyLegendPirateMapBigItem