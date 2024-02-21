--[[
    棋盘上提示
]]
local CherryBountyReelTips = class("CherryBountyReelTips", util_require("base.BaseView"))

function CherryBountyReelTips:initUI(_data)
    self:createCsbNode("CherryBounty_base_tips.csb")
    util_setCascadeOpacityEnabledRescursion(self, true)
end
function CherryBountyReelTips:onEnter()
    CherryBountyReelTips.super.onEnter(self)
    self:playReelTipsIdle()
end
function CherryBountyReelTips:playReelTipsIdle()
    self:runCsbAction("idle", true)
end

return CherryBountyReelTips