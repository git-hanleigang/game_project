--[[
    膨胀宣传 小猪
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MonsterPiggyData = class("MonsterPiggyData", BaseActivityData)

function MonsterPiggyData:ctor()
    MonsterPiggyData.super.ctor(self)
    self.p_open = true
end

return MonsterPiggyData