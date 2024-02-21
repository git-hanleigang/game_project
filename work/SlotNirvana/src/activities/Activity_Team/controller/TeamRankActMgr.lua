--[[
Author: cxc
Date: 2022-03-03 17:12:55
LastEditTime: 2022-03-03 17:12:55
LastEditors: cxc
Description: 公会排行榜 宣传活动mgr
FilePath: /SlotNirvana/src/activities/Activity_Team/controller/TeamRankActMgr.lua
--]]
local TeamRankActMgr = class("TeamRankActMgr", BaseActivityControl)

function TeamRankActMgr:ctor()
    TeamRankActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TeamRankInfo)
end

return TeamRankActMgr


