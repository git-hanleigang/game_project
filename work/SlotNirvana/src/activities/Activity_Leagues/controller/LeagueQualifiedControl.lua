--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-15 16:53:50
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-16 11:10:12
FilePath: /SlotNirvana/src/activities/Activity_Leagues/controller/LeagueQualifiedControl.lua
Description: 比赛 资格赛 控制器
--]]
local LeagueNetModel = util_require("activities.Activity_Leagues.net.LeagueNetModel")
local LeagueCommonCtrl = util_require("activities.Activity_Leagues.controller.LeagueCommonCtrl")
local LeagueQualifiedControl = class("LeagueQualifiedControl", LeagueCommonCtrl)

function LeagueQualifiedControl:ctor()
    LeagueQualifiedControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LeagueQualified)
    self.m_typeStr = "Qualified"
    self.m_netModel = LeagueNetModel:getInstance() 
end

-- 领取排行奖励完成
function LeagueQualifiedControl:collectRankRewardCompleted()
    -- 领取完成关闭界面
    local uiView = gLobalViewManager:getViewByName("League_MainLayer")
    if uiView then
        local callFunc = function()
            local cb = function()
                self:resetActCollectFlag()
                G_GetMgr(G_REF.LeagueCtrl):clearOpenActInfo()
                if G_GetMgr(ACTIVITY_REF.LeagueSummit):isCanShowLayer() then
                    return
                end
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
            local view = self:checkShowFinalistLayer(cb)
            if not view then
                cb()
            end
        end
        uiView:closeUI(callFunc)
    else
        self:resetActCollectFlag()
    end

    self.m_oldData = nil
end

function LeagueQualifiedControl:resetActCollectFlag()
    local activityData = self:getData()
    if activityData then
        activityData:setCanCollect(false)
    end
end

-- 显示赛季结束界面
function LeagueQualifiedControl:onShowFinalLayer()
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

    local finalLayer = util_createView("Activity.Qualified.League_FinalLayer")
    finalLayer:setName("League_FinalLayer")
    self:showLayer(finalLayer, ViewZorder.ZORDER_POPUI)

    return true
end

-- 显示当前段位界面
function LeagueQualifiedControl:onShowDivisionLayer()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_RANK_SHOW, {status = false})
    local diviView = util_createView("Activity.Qualified.League_ShowDivisionLayer")
    diviView:updateView(self.m_oldData)
    self:showLayer(diviView, ViewZorder.ZORDER_POPUI)
end

-- 资格赛 入围 巅峰赛弹板
function LeagueQualifiedControl:checkShowFinalistLayer(_cb)
    local data = self:getData()
    if not data then
        return
    end
    local bInFinallistRank = data:checkCanJoinSummit()
    if not bInFinallistRank then
        return
    end

    local view = util_createView("Activity.Qualified.Feature.League_FinalistLayer", _cb)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示规则界面
function LeagueQualifiedControl:onShowRuleLayer(_bNormal)
    local luaPath = "Activity.Qualified.League_RuleLayer"
    if _bNormal then
        luaPath = "Activity.Normal.League_RuleLayer"
    end
    local view = util_createView(luaPath, _bNormal)
    self:showLayer(view, ViewZorder.ZORDER_POPUI)
end

return LeagueQualifiedControl