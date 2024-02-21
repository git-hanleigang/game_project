--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-15 16:53:50
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-16 11:11:09
FilePath: /SlotNirvana/src/activities/Activity_Leagues/controller/LeagueSummitControl.lua
Description: 比赛 巅峰赛 控制器
--]]
local LeagueNetModel = util_require("activities.Activity_Leagues.net.LeagueNetModel")
local LeagueCommonCtrl = util_require("activities.Activity_Leagues.controller.LeagueCommonCtrl")
local LeagueSummitControl = class("LeagueSummitControl", LeagueCommonCtrl)

local LastRankTopData =  util_require("activities.Activity_Leagues.model.LeagueSummitLastRankData")

function LeagueSummitControl:ctor()
    LeagueSummitControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LeagueSummit)

    self.m_typeStr = "Summit"
    self.m_lastRankTopData = LastRankTopData:create()
    self.m_netModel = LeagueNetModel:getInstance() 
end

function LeagueSummitControl:getLastRankTopData()
    return self.m_lastRankTopData
end

-- 显示领取奖励界面
function LeagueSummitControl:popCollectRewardLayer()
    if not self:isCanShowLayer() then
        return false
    end

    local actData = self:getData()
    local resultInfo = actData:getCollectResult()
    local resultView = util_createView("Activity.Summit.Reward.League_RewardLayer", resultInfo)
    self:showLayer(resultView, ViewZorder.ZORDER_UI)
end

-- 巅峰赛奖杯界面
function LeagueSummitControl:popGainTrophyLayer(_dropTrophyInfo)
    if not self:isCanShowLayer() or not _dropTrophyInfo then
        return false
    end

    local trophyType = _dropTrophyInfo.type
    if not trophyType then
        self:collectRankRewardCompleted()
        return
    end
    local resultView = util_createView("Activity.Summit.Reward.League_GainTrophyLayer", trophyType)
    self:showLayer(resultView, ViewZorder.ZORDER_UI)
end

-- 显示上一期 top排行弹板
function LeagueSummitControl:popLastRankListLayer()
    local list = self.m_lastRankTopData:getTeamRankList()
    if #list <= 0 then
        return
    end
    
    local view = util_createView("Activity.Summit.LastRank.League_LastRankListLayer", self.m_lastRankTopData)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function LeagueSummitControl:checkPopSeasonFinalLayer()
    if not self:isDownloadRes() then
        return false
    end

    local leagueData = self:getData()
    if not leagueData then
        return false
    end

    if not leagueData:isCanCollect() then
        return false
    end

    self:showMainLayer()
    return true
end

------------------------------- 网络 -------------------------------
-- 上赛季竞技场排行榜
function LeagueSummitControl:requestSummitTopRankList(_callback)
    local successCallFun = function(_jsonResult)
        self.m_lastRankTopData:parseData(_jsonResult)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_SUMMIT_LAST_TOP_RANK_UPDATE)
    end

    self.m_netModel:requestSummitTopRankList(successCallFun, true)
end
------------------------------- 网络 -------------------------------

-- 领取竞技场上赛季排行榜奖励
function LeagueSummitControl:onCollectRankReward(isSkipActon)
    local callFunc = function()
        -- 显示领取奖励界面
        self:popCollectRewardLayer(isSkipActon)
    end

    self:requestCollectRankReward(callFunc)
end

-- 领取排行奖励完成
function LeagueSummitControl:collectRankRewardCompleted()
    -- 领取完成关闭界面
    local uiView = gLobalViewManager:getViewByName("League_MainLayer")
    if uiView then
        local callFunc = function()
            G_GetMgr(G_REF.LeagueCtrl):clearOpenActInfo()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
        uiView:closeUI(callFunc)
    end

    local activityData = self:getData()
    if activityData then
        activityData:setCanCollect(false)
    end
    self.m_oldData = nil
end

-- 获取本段位 对应的奖杯类型
function LeagueSummitControl:getCurRankTrophyType(_rank)
    local actData = self:getData()
    if not actData or not _rank then
        return
    end

    local list = actData:getTrophyCfgList()
    for i, data in ipairs(list) do
        if data:checkRankIn(_rank) then
            return data:getTrophyType()
        end
    end
end

return LeagueSummitControl