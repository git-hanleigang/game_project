--[[
    -- 棋盘上提示
    self.m_reelTips = util_createView("CalacasParadeSrc.CalacasParadeReelTips", self)
    self:findChild("Node_tips"):addChild(self.m_reelTips)
]]
local CalacasParadeReelTips = class("CalacasParadeReelTips", util_require("base.BaseView"))


function CalacasParadeReelTips:initUI(_data)
    self:createCsbNode("CalacasParade_des.csb")
    self:playReelTipsIdle()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CalacasParadeReelTips:playReelTipsIdle()
    self:runCsbAction("idle", true)
end

return CalacasParadeReelTips