--
--大厅关卡节点
--
local LimitedTimeSpecial = class("LimitedTimeSpecial", util_require("base.BaseView"))

LimitedTimeSpecial.m_contentLen = nil
LimitedTimeSpecial.activityNodes = nil
function LimitedTimeSpecial:initUI()
    self:createCsbNode("Lobby/LimitedTimeSpecial.csb")
    self:runCsbAction("idle",true)
end

return LimitedTimeSpecial
