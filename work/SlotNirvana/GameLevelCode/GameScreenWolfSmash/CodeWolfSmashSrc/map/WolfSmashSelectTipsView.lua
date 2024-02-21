---
--xcyy
--2018年5月23日
--WolfSmashSelectTipsView.lua

local WolfSmashSelectTipsView = class("WolfSmashSelectTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

function WolfSmashSelectTipsView:initUI(index)

    self:createCsbNode("WolfSmash_xinshouyindao.csb")
    self:guideTipsShowForIndex(index)

end

function WolfSmashSelectTipsView:guideTipsShowForIndex(index)
    for i=1,4 do
        self:findChild("jieduan"..i):setVisible(false)
    end
    if index == 1 then
        self:findChild("jieduan1"):setVisible(true)
    elseif index == 2 then
        self:findChild("jieduan2"):setVisible(true)
    elseif index == 3 then
        self:findChild("jieduan4"):setVisible(true)
    elseif index == 4 then
        self:findChild("jieduan3"):setVisible(true)
    end
end

function WolfSmashSelectTipsView:showGuideTipsStartForIndex()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_select_yindao_show)
    self:runCsbAction("start")
end

function WolfSmashSelectTipsView:showGuideTipsIdleForIndex()
    self:runCsbAction("idleframe")
end

function WolfSmashSelectTipsView:showGuideTipsOverForIndex(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_select_yindao_hide)
    self:runCsbAction("over",false,function ()
        if type(func) == "function" then
            func()
        end
    end)
end


--[[
    延迟回调
]]
function WolfSmashSelectTipsView:delayCallBack(time, func)
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

return WolfSmashSelectTipsView