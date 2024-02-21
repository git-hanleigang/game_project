--[[
Author: cxc
Date: 2021-12-22 12:19:39
LastEditTime: 2021-12-22 12:19:39
LastEditors: cxc
Description: 高倍场 合成小游戏 合成双倍材料
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/model/DeluxeMergeDouble.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DeluxeMergeDouble = class("DeluxeMergeDouble", BaseActivityData)

function DeluxeMergeDouble:ctor()
    DeluxeMergeDouble.super.ctor(self)
    self.p_open = true
end

return DeluxeMergeDouble