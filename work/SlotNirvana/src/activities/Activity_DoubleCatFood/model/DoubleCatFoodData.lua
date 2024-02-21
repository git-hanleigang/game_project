--[[
Author: cxc
Date: 2021-03-23 14:12:05
LastEditTime: 2021-03-23 14:12:44
LastEditors: Please set LastEditors
Description: 双倍猫粮活动
FilePath: /SlotNirvana/src/activities/Activity_DoubleCatFood/model/DoubleCatFoodData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DoubleCatFoodData = class("DoubleCatFoodData", BaseActivityData)

function DoubleCatFoodData:ctor()
    DoubleCatFoodData.super.ctor(self)
    self.p_open = true
end

return DoubleCatFoodData