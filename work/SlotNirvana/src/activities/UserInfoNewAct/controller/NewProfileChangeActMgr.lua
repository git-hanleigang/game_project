--[[
Author: cxc
Date: 2022-04-29 11:19:54
LastEditTime: 2022-04-29 11:19:55
LastEditors: cxc
Description: 个人信息页宣传活动 change
FilePath: /SlotNirvana/src/activities/UserInfoNewAct/controller/NewProfileChangeActMgr.lua
--]]
local NewProfileChangeActMgr = class("NewProfileChangeActMgr", BaseActivityControl)

function NewProfileChangeActMgr:ctor()
    NewProfileChangeActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewProfileChange)
end

return NewProfileChangeActMgr
