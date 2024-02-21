--[[
Author: dhs
Date: 2021-11-01 14:25:16
LastEditTime: 2022-02-22 14:24:54
LastEditors: your name
Description: 六个箱子促销Mgr
FilePath: /SlotNirvana/src/activities/Promotion_MemoryFlying/controller/MemoryFlyingSaleMgr.lua
--]]

local MemoryFlyingSaleMgr = class("MemoryFlyingSaleMgr", BaseActivityControl)

function MemoryFlyingSaleMgr:ctor()
    MemoryFlyingSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MemoryFlyingSale)
end

return MemoryFlyingSaleMgr
