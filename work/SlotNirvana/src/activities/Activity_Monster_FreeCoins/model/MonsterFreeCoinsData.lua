--[[
    膨胀宣传 免费金币
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MonsterFreeCoinData = class("MonsterFreeCoinData", BaseActivityData)

function MonsterFreeCoinData:ctor()
    MonsterFreeCoinData.super.ctor(self)
    self.p_open = true
end

return MonsterFreeCoinData