--[[
    棋盘上提示
]]
local CherryBountyPickGameReelTips = class("CherryBountyPickGameReelTips", util_require("base.BaseView"))

function CherryBountyPickGameReelTips:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("CherryBounty_pick_tips.csb")
    util_setCascadeOpacityEnabledRescursion(self, true)
end
function CherryBountyPickGameReelTips:onEnter()
    CherryBountyPickGameReelTips.super.onEnter(self)
    self:playReelTipsIdle()
end
function CherryBountyPickGameReelTips:playReelTipsIdle()
    self:runCsbAction("idle", true)
end

return CherryBountyPickGameReelTips