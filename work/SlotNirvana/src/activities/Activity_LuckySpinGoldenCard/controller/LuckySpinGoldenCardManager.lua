--[[
Author: cxc
Date: 2021-10-12 10:09:04
LastEditTime: 2021-10-12 10:23:47
LastEditors: your name
Description: luckySpin送金卡活动 管理模块
FilePath: /SlotNirvana/src/activities/Activity_LuckySpinGoldenCard/controller/LuckySpinGoldenCardManager.lua
--]]

local LuckySpinGoldenCardManager = class("LuckySpinGoldenCardManager", BaseActivityControl)

function LuckySpinGoldenCardManager:ctor()
    LuckySpinGoldenCardManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckySpinGoldenCard)
end

return LuckySpinGoldenCardManager
