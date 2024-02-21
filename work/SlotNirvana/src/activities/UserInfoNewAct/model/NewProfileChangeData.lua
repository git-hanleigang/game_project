--[[
Author: cxc
Date: 2022-04-29 11:15:06
LastEditTime: 2022-04-29 11:15:07
LastEditors: cxc
Description: 个人信息页宣传活动 change
FilePath: /SlotNirvana/src/activities/UserInfoNewAct/model/NewProfileChangeData.lua
--]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local NewProfileChangeData = class("NewProfileChangeData", BaseActivityData)

function NewProfileChangeData:ctor(_data)
    NewProfileChangeData.super.ctor(self,_data)
    self.p_open = true
end

return NewProfileChangeData