--[[
Author: cxc
Date: 2021-09-22 20:49:22
LastEditTime: 2021-09-22 20:50:17
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-start
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/model/DeluxeMergeAdvertiseStart.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DeluxeMergeAdvertiseStart = class("DeluxeMergeAdvertiseStart", BaseActivityData)

function DeluxeMergeAdvertiseStart:ctor()
    DeluxeMergeAdvertiseStart.super.ctor(self)
    self.p_open = true
end

return DeluxeMergeAdvertiseStart