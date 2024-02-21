--[[
Author: cxc
Date: 2021-12-22 14:02:51
LastEditTime: 2021-12-22 12:21:33
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-start
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/controller/MergeLoadingActManager.lua
--]]
local MergeLoadingActManager = class("MergeLoadingActManager", BaseActivityControl)

function MergeLoadingActManager:ctor()
    MergeLoadingActManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeAdvertiseStart)
end

return MergeLoadingActManager
