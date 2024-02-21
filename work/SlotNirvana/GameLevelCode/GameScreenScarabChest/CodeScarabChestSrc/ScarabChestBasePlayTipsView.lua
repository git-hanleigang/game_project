---
--xcyy
--2018年5月23日
--ScarabChestBasePlayTipsView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestBasePlayTipsView = class("ScarabChestBasePlayTipsView",util_require("Levels.BaseLevelDialog"))

function ScarabChestBasePlayTipsView:initUI(_machine)

    self:createCsbNode("ScarabChest_UItishi.csb")

    self.m_machine = _machine
end

-- idle
function ScarabChestBasePlayTipsView:showStart(_onEnter)
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    if _onEnter then
        self:runCsbAction("idle", true)
    else
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

-- over
function ScarabChestBasePlayTipsView:closeBasePlayTips()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

return ScarabChestBasePlayTipsView
