--[[
    膨胀宣传-预热
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local MonsterWarmUpData = class("MonsterWarmUpData", BaseActivityData)

function MonsterWarmUpData:ctor()
    MonsterWarmUpData.super.ctor(self)

    -- 活动没数据，时间到了就开了
    self.p_open = true
end

return MonsterWarmUpData
