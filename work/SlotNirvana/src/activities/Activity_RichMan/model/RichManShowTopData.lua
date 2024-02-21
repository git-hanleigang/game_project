--[[
Author: cxc
Date: 2021-11-04 12:22:59
LastEditTime: 2021-11-04 12:23:28
LastEditors: your name
Description: 大富翁排行榜活动数据
FilePath: /SlotNirvana/src/activities/Activity_RichMan/model/RichManShowTopData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local RichManShowTopData = class("RichManShowTopData", BaseActivityData)

function RichManShowTopData:ctor()
    RichManShowTopData.super.ctor(self)
    self.p_open = true
end

return RichManShowTopData


