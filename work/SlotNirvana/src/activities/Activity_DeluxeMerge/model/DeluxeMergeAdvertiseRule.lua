--[[
Author: cxc
Date: 2021-09-22 20:49:22
LastEditTime: 2021-09-22 20:50:17
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-规则宣传
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/model/DeluxeMergeAdvertiseRule.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DeluxeMergeAdvertiseRule = class("DeluxeMergeAdvertiseRule", BaseActivityData)

function DeluxeMergeAdvertiseRule:ctor()
    DeluxeMergeAdvertiseRule.super.ctor(self)
    self.p_open = true
end

return DeluxeMergeAdvertiseRule