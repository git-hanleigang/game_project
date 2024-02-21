---
--xcyy
--2018年5月23日
--WarriorAliceSpecialReelAct.lua

local WarriorAliceSpecialReelAct = class("WarriorAliceSpecialReelAct",util_require("Levels.BaseLevelDialog"))

local showName = {
    "Node_lv",
    "Node_lan",
    "Node_fen",
    "Node_hong"
}

function WarriorAliceSpecialReelAct:initUI(iCol)

    self:createCsbNode("WarriorAlice_reel_tishi.csb")

    self:showReelActForCol(iCol, false)
end

--根据列显示
function WarriorAliceSpecialReelAct:showReelActForCol(iCol, isPlayHong)
    if isPlayHong then
        for i,v in ipairs(showName) do
            if i == 4 then
                self:findChild(v):setVisible(true)
            else
                self:findChild(v):setVisible(false)
            end
        end
    else
        if iCol == 1 or iCol == 5 then
            for i,v in ipairs(showName) do
                if i == 1 then
                    self:findChild(v):setVisible(true)
                else
                    self:findChild(v):setVisible(false)
                end
            end
        elseif iCol == 2 or iCol == 4 then
            for i,v in ipairs(showName) do
                if i == 2 then
                    self:findChild(v):setVisible(true)
                else
                    self:findChild(v):setVisible(false)
                end
            end
        else
            for i,v in ipairs(showName) do
                if i == 3 then
                    self:findChild(v):setVisible(true)
                else
                    self:findChild(v):setVisible(false)
                end
            end
        end
    end
end

function WarriorAliceSpecialReelAct:onEnter()

    WarriorAliceSpecialReelAct.super.onEnter(self)

end

function WarriorAliceSpecialReelAct:onExit()
    WarriorAliceSpecialReelAct.super.onExit(self)

end

--[[
    延迟回调
]]
function WarriorAliceSpecialReelAct:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WarriorAliceSpecialReelAct