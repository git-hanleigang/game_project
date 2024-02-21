--[[--
    FB加好友活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local QuestMinzIntroData = class("QuestMinzIntroData", BaseActivityData)

function QuestMinzIntroData:ctor()
    QuestMinzIntroData.super.ctor(self)
    self.p_open = true
end

return QuestMinzIntroData