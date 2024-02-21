---
--xcyy
--2018年5月23日
--WolfSmashSelectPointView.lua

local WolfSmashSelectPointView = class("WolfSmashSelectPointView",util_require("Levels.BaseLevelDialog"))


function WolfSmashSelectPointView:initUI()

    self:createCsbNode("WolfSmash_shouzhitou.csb")


end

function WolfSmashSelectPointView:showPointStartEffect()
    self:runCsbAction("start",false,function ()
        self:runCsbAction("actionframe",true)
    end)
end

function WolfSmashSelectPointView:showPointActEffect()
    
end

function WolfSmashSelectPointView:showPointOverEffect(func)
    self:runCsbAction("over",false,function ()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    延迟回调
]]
function WolfSmashSelectPointView:delayCallBack(time, func)
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

return WolfSmashSelectPointView