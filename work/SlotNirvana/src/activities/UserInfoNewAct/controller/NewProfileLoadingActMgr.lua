--[[
Author: cxc
Date: 2022-04-29 11:20:07
LastEditTime: 2022-04-29 11:20:08
LastEditors: cxc
Description: 个人信息页宣传活动 loading
FilePath: /SlotNirvana/src/activities/UserInfoNewAct/controller/NewProfileLoadingActMgr.lua
--]]
local NewProfileLoadingActMgr = class("NewProfileLoadingActMgr", BaseActivityControl)

function NewProfileLoadingActMgr:ctor()
    NewProfileLoadingActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewProfileLoading)
end

return NewProfileLoadingActMgr