--[[
Author: dhs
Date: 2022-04-01 15:22:33
LastEditTime: 2022-04-01 15:22:33
LastEditors: your name
Description: 乐透STATISTICS宣传图 Data
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Statistics/model/LotteryStatisticsData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local LotteryStatisticsData = class("LotteryStatisticsData", BaseActivityData)

function LotteryStatisticsData:ctor(_data)
    LotteryStatisticsData.super.ctor(self, _data)
    self.p_open = true
end

return LotteryStatisticsData
