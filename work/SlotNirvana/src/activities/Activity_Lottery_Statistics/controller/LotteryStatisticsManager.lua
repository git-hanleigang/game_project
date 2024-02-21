--[[
Author: dhs
Date: 2022-04-01 15:22:19
LastEditTime: 2022-04-01 15:22:20
LastEditors: your name
Description: 乐透STATISTICS宣传图 Mgr
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Statistics/controller/LotteryStatisticsManager.lua
--]]
local LotteryStatisticsManager = class("LotteryStatisticsManager", BaseActivityControl)

function LotteryStatisticsManager:ctor()
    LotteryStatisticsManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LotteryStatistics)
end

return LotteryStatisticsManager

