--[[
Author: cxc
Date: 2022-03-03 17:15:31
LastEditTime: 2022-03-03 17:15:31
LastEditors: cxc
Description: 公会排行榜 宣传活动 数据
FilePath: /SlotNirvana/src/activities/Activity_Team/model/TeamRankActData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TeamRankActData = class("TeamRankActData", BaseActivityData)

function TeamRankActData:ctor()
    TeamRankActData.super.ctor(self)
    self.p_open = true
end

return TeamRankActData