-- bingo比赛 弹窗

local BaseActivityData = require("baseActivity.BaseActivityData")
local BingoRushNewRuleData = class("BingoRushNewRuleData", BaseActivityData)

function BingoRushNewRuleData:ctor()
    BingoRushNewRuleData.super.ctor(self)
    self.p_open = true
end

return BingoRushNewRuleData
