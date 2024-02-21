--[[
Author: cxc
Date: 2021-12-22 14:02:51
LastEditTime: 2021-12-22 12:21:33
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-end
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/controller/MergeCountDownActManager.lua
--]]
local MergeCountDownActManager = class("MergeCountDownActManager", BaseActivityControl)

function MergeCountDownActManager:ctor()
    MergeCountDownActManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeAdvertiseEnd)
end

return MergeCountDownActManager
