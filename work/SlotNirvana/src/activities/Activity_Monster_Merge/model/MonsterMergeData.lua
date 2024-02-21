--[[
    膨胀宣传 合成
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MonsterMergeData = class("MonsterMergeData", BaseActivityData)

function MonsterMergeData:ctor()
    MonsterMergeData.super.ctor(self)
    self.p_open = true
end

return MonsterMergeData