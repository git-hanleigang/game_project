--[[
Author: cxc
Date: 2022-04-20 15:26:43
LastEditTime: 2022-04-20 15:26:44
LastEditors: cxc
Description: 头像框 宣传活动 loading
FilePath: /SlotNirvana/src/activities/AvatarFrameAct/controller/AvatarFrameLoadingActMgr.lua
--]]
local AvatarFrameLoadingActMgr = class("AvatarFrameLoadingActMgr", BaseActivityControl)

function AvatarFrameLoadingActMgr:ctor()
    AvatarFrameLoadingActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AvatarFrameLoading)
end

return AvatarFrameLoadingActMgr
