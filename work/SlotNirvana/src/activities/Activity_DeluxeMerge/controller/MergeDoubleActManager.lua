--[[
Author: cxc
Date: 2021-12-22 14:02:51
LastEditTime: 2021-12-22 12:21:33
LastEditors: cxc
Description: 高倍场 合成小游戏 合成双倍材料
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/controller/MergeDoubleActManager.lua
--]]
local MergeDoubleActManager = class("MergeDoubleActManager", BaseActivityControl)

function MergeDoubleActManager:ctor()
    MergeDoubleActManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeDouble)
end

return MergeDoubleActManager
