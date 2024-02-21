--[[
Author: cxc
Date: 2022-01-24 20:10:25
LastEditTime: 2022-02-14 15:01:40
LastEditors: cxc
Description: 高倍场 合成小游戏 合成周卡活动
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/controller/MergeWeekActManager.lua
--]]
local MergeWeekActManager = class("MergeWeekActManager", BaseActivityControl)
local MergeWeekNet = require("activities.Activity_DeluxeMerge.net.MergeWeekNet")

function MergeWeekActManager:ctor()
    MergeWeekActManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeWeek)
    self.m_netModel = MergeWeekNet:getInstance()
end

function MergeWeekActManager:sendCollectReq()
    self.m_netModel:sendCollectReq()
end

function MergeWeekActManager:goPurchase()
    self.m_netModel:goPurchase()
end

function MergeWeekActManager:getHallPath(hallName)
    if hallName == "Activity_MergeWeek_Winter" then
        return hallName .. "/" .. hallName ..  "HallNode"
    else
        return MergeWeekActManager.super.getHallPath(self, hallName)
    end
end

function MergeWeekActManager:getPopPath(popName)
    if popName == "Activity_MergeWeek_Winter" then
        return popName .. "/" .. popName
    else
        return MergeWeekActManager.super.getPopPath(self, popName)
    end
end

return MergeWeekActManager
