--[[
    膨胀宣传 金币商城
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MonsterCoinStoreData = class("MonsterCoinStoreData", BaseActivityData)

function MonsterCoinStoreData:ctor()
    MonsterCoinStoreData.super.ctor(self)
    self.p_open = true
end

return MonsterCoinStoreData