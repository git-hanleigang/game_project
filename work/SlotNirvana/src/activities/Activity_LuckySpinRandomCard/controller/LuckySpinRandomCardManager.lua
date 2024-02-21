--[[
Author: cxc
Date: 2021-10-20 16:02:53
LastEditTime: 2021-10-20 16:07:40
LastEditors: your name
Description: luckySpin 送缺卡
FilePath: /SlotNirvana/src/activities/Activity_LuckySpinRandomCard/controller/LuckySpinRandomCardManager.lua
--]]
local LuckySpinRandomCardManager = class("LuckySpinRandomCardManager", BaseActivityControl)

function LuckySpinRandomCardManager:ctor()
    LuckySpinRandomCardManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckySpinRandomCard)
end

return LuckySpinRandomCardManager
