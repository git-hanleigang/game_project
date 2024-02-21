--[[
Author: cxc
Date: 2022-04-20 15:37:24
LastEditTime: 2022-04-20 15:37:25
LastEditors: cxc
Description: 头像框 宣传活动 loading 数据
FilePath: /SlotNirvana/src/activities/AvatarFrameAct/model/AvatarFrameLoadingData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local AvatarFrameLoadingData = class("AvatarFrameLoadingData", BaseActivityData)

function AvatarFrameLoadingData:ctor(_data)
    AvatarFrameLoadingData.super.ctor(self,_data)
    self.p_open = true
end

return AvatarFrameLoadingData