--[[
Author: cxc
Date: 2022-01-26 14:34:41
LastEditTime: 2022-01-26 14:34:43
LastEditors: cxc
Description: bingo 比赛 宣传活动 数据
FilePath: /SlotNirvana/src/activities/Activity_BingoRush/model/BingoRushRuleData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BingoRushRuleData = class("BingoRushRuleData", BaseActivityData)

function BingoRushRuleData:ctor()
    BingoRushRuleData.super.ctor(self)
    self.p_open = true
end

return BingoRushRuleData
