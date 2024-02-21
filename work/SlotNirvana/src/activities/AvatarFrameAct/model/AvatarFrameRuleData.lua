--[[
Author: cxc
Date: 2022-04-20 15:32:03
LastEditTime: 2022-04-20 15:32:04
LastEditors: cxc
Description: 头像框 宣传活动 rule 数据
FilePath: /SlotNirvana/src/activities/AvatarFrameAct/model/AvatarFrameRuleData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local AvatarFrameRuleData = class("AvatarFrameRuleData", BaseActivityData)

function AvatarFrameRuleData:ctor(_data)
    AvatarFrameRuleData.super.ctor(self,_data)
    self.p_open = true
end

return AvatarFrameRuleData