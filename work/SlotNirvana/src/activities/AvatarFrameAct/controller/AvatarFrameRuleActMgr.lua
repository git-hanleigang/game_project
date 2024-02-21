--[[
Author: cxc
Date: 2022-04-20 15:26:55
LastEditTime: 2022-04-20 15:26:56
LastEditors: cxc
Description: 头像框 宣传活动 rule
FilePath: /SlotNirvana/src/activities/AvatarFrameAct/controller/AvatarFrameRuleActMgr.lua
--]]
local AvatarFrameRuleActMgr = class("AvatarFrameRuleActMgr", BaseActivityControl)

function AvatarFrameRuleActMgr:ctor()
    AvatarFrameRuleActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AvatarFrameRule)
end

return AvatarFrameRuleActMgr
