---
--xcyy
--2018年5月23日
--GhostBlasterFreeTip.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterFreeTip = class("GhostBlasterFreeTip",util_require("Levels.BaseLevelDialog"))


function GhostBlasterFreeTip:initUI()

    self:createCsbNode("GhostBlaster_FreeGameTips.csb")
    self:setVisible(false)
end

function GhostBlasterFreeTip:setTipShow(isBoss)
    self:findChild("Node_normal"):setVisible(not isBoss)
    self:findChild("Node_boss"):setVisible(isBoss)
end

function GhostBlasterFreeTip:showAni(func)
    self:setVisible(true)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)
end

function GhostBlasterFreeTip:runOverAni(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
    end)
end


return GhostBlasterFreeTip