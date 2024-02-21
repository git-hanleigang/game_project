--[[
Author: cxc
Date: 2021-12-22 14:02:51
LastEditTime: 2021-12-22 12:21:33
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-规则宣传
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/controller/MergeRuleActManager.lua
--]]
local MergeRuleActManager = class("MergeRuleActManager", BaseActivityControl)

function MergeRuleActManager:ctor()
    MergeRuleActManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeAdvertiseRule)
end

return MergeRuleActManager
