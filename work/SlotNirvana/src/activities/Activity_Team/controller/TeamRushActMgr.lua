--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-04 16:00:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-04 16:00:51
FilePath: /SlotNirvana/src/activities/Activity_Team/controller/TeamRushActMgr.lua
Description: 公会Rush 宣传活动mgr
--]]
local TeamRushActMgr = class("TeamRushActMgr", BaseActivityControl)

function TeamRushActMgr:ctor()
    TeamRushActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TeamRushInfo)
end

return TeamRushActMgr