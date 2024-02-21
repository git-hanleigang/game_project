--[[
Author: cxc
Date: 2022-04-29 10:58:00
LastEditTime: 2022-04-29 10:58:01
LastEditors: cxc
Description: 头像框 宣传活动 changeWay
FilePath: /SlotNirvana/src/activities/AvatarFrameAct/controller/AvatarFrameChangeWayActMgr.lua
--]]
local AvatarFrameChangeWayActMgr = class("AvatarFrameChangeWayActMgr", BaseActivityControl)

function AvatarFrameChangeWayActMgr:ctor()
    AvatarFrameChangeWayActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AvatarFrameChangeWay)
end

return AvatarFrameChangeWayActMgr