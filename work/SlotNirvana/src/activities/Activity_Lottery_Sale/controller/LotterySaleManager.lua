--[[
Author: dhs
Date: 2022-04-01 15:21:40
LastEditTime: 2022-04-01 15:21:41
LastEditors: your name
Description: 乐透促销Mgr
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Sale/controller/LotterySaleManager.lua
--]]
local LotterySaleManager = class("LotterySaleManager", BaseActivityControl)

function LotterySaleManager:ctor()
    LotterySaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LotterySale)
end

return LotterySaleManager

