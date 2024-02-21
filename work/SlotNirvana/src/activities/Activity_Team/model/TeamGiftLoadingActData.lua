--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-29 13:59:41
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-15 14:37:31
FilePath: /SlotNirvana/src/activities/Activity_Team/model/TeamGiftLoadingActData.lua
Description: 公会送红包 宣传活动 data
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TeamGiftLoadingActData = class("TeamGiftLoadingActData", BaseActivityData)

function TeamGiftLoadingActData:ctor()
    TeamGiftLoadingActData.super.ctor(self)
    self.p_open = true
end

return TeamGiftLoadingActData