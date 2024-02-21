--[[
Author: cxc
Date: 2022-01-26 12:18:48
LastEditTime: 2022-01-26 14:32:55
LastEditors: cxc
Description: bingo 比赛 宣传活动 mgr
FilePath: /SlotNirvana/src/activities/Activity_BingoRush/controller/BingoRushLoadingManager.lua
--]]
local BingoRushLoadingManager = class("BingoRushLoadingManager", BaseActivityControl)

function BingoRushLoadingManager:ctor()
    BingoRushLoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BingoRushLoading)
end

function BingoRushLoadingManager:isCanShowPop()
    local mrg = G_GetMgr(ACTIVITY_REF.BingoRush)
    if mrg then
        return mrg:isRunning() 
    end

    return true
end

--------------------- bingoRush 开始时间 ---------------------
function BingoRushLoadingManager:getBingoRushOpenTime()
    if self.m_bingoRushOpenTime then
        return self.m_bingoRushOpenTime
    end

    local rushData = self:getBingoRushData()
    local starTime = 0
    if not rushData or not rushData.p_start then
        starTime = self:getBingoRushLoadingOpenTime() 
    else
        starTime = util_getymd_time(rushData.p_start) -- 秒s
    end
    self.m_bingoRushOpenTime = starTime
    return starTime
end

function BingoRushLoadingManager:getBingoRushLoadingOpenTime()
    local loadingData = self:getData()

    if not loadingData.p_start then
        return
    end
    return util_getymd_time(loadingData.p_start)
end

function BingoRushLoadingManager:getBingoRushData()
    local rushData = self:getBingoRushRunningData()
    if not rushData then
        rushData = self:getBingoRushRecentlyData()
    end

    return rushData
end

-- bingo Rush的 正在开始的数据
function BingoRushLoadingManager:getBingoRushRunningData()
    local mgr = G_GetMgr(ACTIVITY_REF.BingoRush)
    if not mgr then
        return
    end

    local rushData = mgr:getData()
    return rushData
end

-- bingo Rush的 将要开启的数据
function BingoRushLoadingManager:getBingoRushRecentlyData()
    local rushData = globalData.GameConfig:getRecentActivityConfigByRef(ACTIVITY_REF.BingoRush)
    return rushData
end
--------------------- bingoRush 开始时间 ---------------------

return BingoRushLoadingManager
