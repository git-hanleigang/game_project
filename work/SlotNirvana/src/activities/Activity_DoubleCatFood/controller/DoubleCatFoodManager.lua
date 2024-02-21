--[[
Author: cxc
Date: 2021-10-13 20:04:12
LastEditTime: 2021-10-13 20:04:17
LastEditors: your name
Description: 双倍猫粮活动
FilePath: /SlotNirvana/src/activities/Activity_DoubleCatFood/controller/DoubleCatFoodManager.lua
--]]

local DoubleCatFoodManager = class("DoubleCatFoodManager", BaseActivityControl)

function DoubleCatFoodManager:ctor()
    DoubleCatFoodManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckySpinGoldenCard)
end

return DoubleCatFoodManager
