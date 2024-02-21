--[[
Author: cxc
Date: 2021-09-22 20:49:22
LastEditTime: 2021-09-22 20:50:17
LastEditors: cxc
Description: 高倍场 合成小游戏 宣传面板-end
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/model/DeluxeMergeAdvertiseEnd.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DeluxeMergeAdvertiseEnd = class("DeluxeMergeAdvertiseEnd", BaseActivityData)

function DeluxeMergeAdvertiseEnd:ctor()
    DeluxeMergeAdvertiseEnd.super.ctor(self)
    self.p_open = true
end

return DeluxeMergeAdvertiseEnd