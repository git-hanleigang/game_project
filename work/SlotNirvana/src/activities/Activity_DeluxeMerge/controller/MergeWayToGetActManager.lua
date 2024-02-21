--[[
Author: cxc
Date: 2021-12-22 14:02:51
LastEditTime: 2021-12-22 12:21:33
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-道具获取途径宣传
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/controller/MergeWayToGetActManager.lua
--]]
local MergeWayToGetActManager = class("MergeWayToGetActManager", BaseActivityControl)

function MergeWayToGetActManager:ctor()
    MergeWayToGetActManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeAdvertiseGetItem)
end

return MergeWayToGetActManager
