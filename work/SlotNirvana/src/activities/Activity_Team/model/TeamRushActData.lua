--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-04 15:59:59
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-04 16:00:07
FilePath: /SlotNirvana/src/activities/Activity_Team/model/TeamRushActData.lua
Description: 公会Rush 宣传活动 数据
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TeamRushActData = class("TeamRushActData", BaseActivityData)

function TeamRushActData:ctor()
    TeamRushActData.super.ctor(self)
    self.p_open = true
end

return TeamRushActData