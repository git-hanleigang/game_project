--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-15 14:36:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-15 14:37:10
FilePath: /SlotNirvana/src/activities/Activity_Team/controller/TeamGiftLoadingActMgr.lua
Description: 公会送红包 宣传活动 mgr
--]]
local TeamGiftLoadingActMgr = class("TeamGiftLoadingActMgr", BaseActivityControl)

function TeamGiftLoadingActMgr:ctor()
    TeamGiftLoadingActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TeamGiftLoading)
end

function TeamGiftLoadingActMgr:getHallPath(hallName)
    return "" .. hallName .. "/" .. hallName ..  "HallNode"
end

function TeamGiftLoadingActMgr:getSlidePath(slideName)
    return "" .. slideName .. "/" .. slideName ..  "SlideNode"
end

function TeamGiftLoadingActMgr:getPopPath(popName)
    return "" .. popName .. "/" .. popName
end

return TeamGiftLoadingActMgr