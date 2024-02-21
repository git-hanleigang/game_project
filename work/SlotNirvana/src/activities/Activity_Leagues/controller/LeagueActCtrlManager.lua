--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-15 16:40:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-15 16:41:43
FilePath: /SlotNirvana/src/activities/Activity_Leagues/controller/LeagueActCtrlManager.lua
Description: 比赛 控制器 管理类
--]]
local LeagueActCtrlManager = class("LeagueActCtrlManager", BaseGameControl)

function LeagueActCtrlManager:ctor()
    LeagueActCtrlManager.super.ctor(self)

    self.m_openType = nil
    self.m_recentOpenType = nil
    self:requireLuaCtrlModule()
    self:setRefName(G_REF.LeagueCtrl)
end

-- 加载比赛ctrl文件
function LeagueActCtrlManager:requireLuaCtrlModule()
    require("activities.Activity_Leagues.config.LeagueCfg")
    require("activities.Activity_Leagues.controller.LeagueControl"):getInstance()
    require("activities.Activity_Leagues.controller.LeagueQualifiedControl"):getInstance()
    require("activities.Activity_Leagues.controller.LeagueSummitControl"):getInstance()
    require("activities.Activity_Leagues.controller.LeagueSaleControl"):getInstance()
end

-- 检查当前开启的比赛类型
function LeagueActCtrlManager:checkCurLeagueOpenType()

    -- (巅峰 -> 资格 -> 普通)
    local checkList = {ACTIVITY_REF.LeagueSummit, ACTIVITY_REF.LeagueQualified, ACTIVITY_REF.League}
    -- 有领奖的 优先领奖的
    for idx, actName in ipairs(checkList) do
        local runningData = G_GetMgr(actName):getRunningData()
        if runningData and runningData:isCanCollect() then
            self.m_openType = idx
            break
        end
    end

    -- 没领奖的 按优先级读取
    if not self.m_openType then
        for idx, actName in ipairs(checkList) do
            local runningData = G_GetMgr(actName):getRunningData()
            if runningData then
                self.m_openType = idx
                break
            elseif globalData.GameConfig:getRecentActivityConfigByRef(actName) then
                self.m_recentOpenType = idx
            end
        end
    end

    -- 三种比赛通用一个促销
    if self.m_openType then
        self:registerListener(checkList[self.m_openType])
        G_GetMgr(ACTIVITY_REF.LeagueSale):addPreRef(checkList[self.m_openType])
    end
end

-- 比赛正在开启 和 将要开启的类型
function LeagueActCtrlManager:getOpenTypeInfo()
    if not self.m_openType and not self.m_recentOpenType then
        self:checkCurLeagueOpenType()
    end

    return {self.m_openType, self.m_recentOpenType}
end
function LeagueActCtrlManager:clearOpenTypeInfo()
    self.m_openType = nil
    self.m_recentOpenType = nil
end

-- 获取大厅下 UI入口 检查下载key
function LeagueActCtrlManager:getLobbyBtCheckDLKey()
    return "Activity_Leagues"
end

-- 获取开启 活动 refname
function LeagueActCtrlManager:getOpenActRefName()
    local key = ACTIVITY_REF.League
    local checkList = {ACTIVITY_REF.LeagueSummit, ACTIVITY_REF.LeagueQualified, ACTIVITY_REF.League}
    local openTypeInfo = self:getOpenTypeInfo()
    if openTypeInfo[1] ~= nil then
        key = checkList[openTypeInfo[1]]
    elseif  openTypeInfo[2] ~= nil then
        key = checkList[openTypeInfo[2]]
    end
    return key
end

-- 获取开启的 ctrl
function LeagueActCtrlManager:getOpenCtrl()
    local key = self:getOpenActRefName()
    return G_GetMgr(key)
end

-- 创建 关卡左边条入口
function LeagueActCtrlManager:createEntryNode()
    local luaModule = self:getOpenCtrl():getMachineEntryModule()
    if not luaModule then
        return
    end

    local node = util_createView(luaModule)
    return node
end

-- 监测本赛季是否结束 弹相应结算奖励
function LeagueActCtrlManager:checkPopSeasonFinalLayer()
    local bPop = G_GetMgr(ACTIVITY_REF.League):onShowFinalLayer()
    if bPop then
        return true
    end

    bPop = G_GetMgr(ACTIVITY_REF.LeagueQualified):onShowFinalLayer()
    if bPop then
        return true
    end

    return G_GetMgr(ACTIVITY_REF.LeagueSummit):checkPopSeasonFinalLayer() 
end

-- 注册事件
function LeagueActCtrlManager:registerListener(_openActName)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == _openActName then
                -- 活动结束 商城比赛折扣 要一直存在
                -- gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig()
                self:clearOpenActInfo()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function LeagueActCtrlManager:clearOpenActInfo()
    self:clearOpenTypeInfo()
    self:checkCurLeagueOpenType()
end

function LeagueActCtrlManager:checkHadRunningData()
    local bExit = false
    local checkList = {ACTIVITY_REF.LeagueSummit, ACTIVITY_REF.LeagueQualified, ACTIVITY_REF.League}
    for idx, actName in ipairs(checkList) do
        local runningData = G_GetMgr(actName):getRunningData()
        if runningData then
            bExit = true
            break
        end
    end

    return bExit
end

-- 比赛我的段位
function LeagueActCtrlManager:setMyDivision(_divison)
    self.m_recordDivision = _divison
end
function LeagueActCtrlManager:getMyDivision()
    return self.m_recordDivision
end

return LeagueActCtrlManager