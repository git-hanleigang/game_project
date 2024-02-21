--[[
    膨胀宣传 免费金币
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MonsterStartData = class("MonsterStartDataData", BaseActivityData)

function MonsterStartData:ctor()
    MonsterStartData.super.ctor(self)
    self.p_open = true
end

return MonsterStartData