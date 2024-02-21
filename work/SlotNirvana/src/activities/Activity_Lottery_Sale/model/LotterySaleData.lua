--[[
Author: dhs
Date: 2022-04-01 15:21:53
LastEditTime: 2022-04-01 15:21:54
LastEditors: your name
Description: 乐透促销弹板Data
FilePath: /SlotNirvana/src/activities/Activity_Lottery_Sale/model/LotterySaleData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local LotterySaleData = class("LotterySaleData", BaseActivityData)

function LotterySaleData:ctor(_data)
    LotterySaleData.super.ctor(self, _data)
    self.p_open = true
end

return LotterySaleData

