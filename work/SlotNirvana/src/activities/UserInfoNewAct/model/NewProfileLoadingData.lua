--[[
Author: cxc
Date: 2022-04-29 11:14:54
LastEditTime: 2022-04-29 11:14:55
LastEditors: cxc
Description: 个人信息页宣传活动 loading
FilePath: /SlotNirvana/src/activities/UserInfoNewAct/model/NewProfileLoadingData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local NewProfileLoadingData = class("NewProfileLoadingData", BaseActivityData)

function NewProfileLoadingData:ctor(_data)
    NewProfileLoadingData.super.ctor(self,_data)
    self.p_open = true
end

return NewProfileLoadingData