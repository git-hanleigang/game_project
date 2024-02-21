---
--xcyy
--2018年5月23日
--DemonessFairCollectItemView.lua
local PublicConfig = require "DemonessFairPublicConfig"
local DemonessFairCollectItemView = class("DemonessFairCollectItemView",util_require("Levels.BaseLevelDialog"))

function DemonessFairCollectItemView:initUI()

    self:createCsbNode("DemonessFair_Collect_Item.csb")

    self:setNormalIdle()

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function DemonessFairCollectItemView:setNormalIdle()
    self:runCsbAction("idle", true)
end

function DemonessFairCollectItemView:setCollectIdle()
    self:runCsbAction("idle1", true)
end

-- 收集动画
function DemonessFairCollectItemView:playCollectAni(_isFull)
    local isFull = _isFull
    local actName = "actionframe"
    if isFull then
        actName = "actionframe1"
    end
    self:runCsbAction(actName, false, function()
        self:setCollectIdle()
    end)
end

return DemonessFairCollectItemView
