--[[
Author: cxc
Date: 2022-04-29 10:56:58
LastEditTime: 2022-04-29 10:56:59
LastEditors: cxc
Description: 头像框 宣传活动 changeWay 数据
FilePath: /SlotNirvana/src/activities/AvatarFrameAct/model/AvatarFrameChangeWayData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local AvatarFrameChangeWayData = class("AvatarFrameChangeWayData", BaseActivityData)

function AvatarFrameChangeWayData:ctor(_data)
    AvatarFrameChangeWayData.super.ctor(self,_data)
    self.p_open = true
end

return AvatarFrameChangeWayData