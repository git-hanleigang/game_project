--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-18 15:54:27
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-18 15:54:57
FilePath: /SlotNirvana/Dynamic/Activity_Leagues_Code/Activity/Qualified/Feature/League_FinalistLayer.lua
Description: 比赛控制器 通用 部分
--]]
local LeagueCommonCtrl = class("LeagueCommonCtrl", BaseActivityControl)

function LeagueCommonCtrl:ctor()
    LeagueCommonCtrl.super.ctor(self)

    self:addExtendResList("Activity_Leagues", "Activity_Leagues_Code")
end

-- 大厅展示资源判断
function LeagueCommonCtrl:isDownloadLobbyRes()
    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

-- 是否已下载loading资源；大厅轮播、展示、弹板资源判断
function LeagueCommonCtrl:isDownloadLoadingRes()
    local themeName = self:getThemeName()

    if not self:isDownloadRes(themeName) then
        return false
    end

    local isDownloaded = self:checkDownloaded(themeName .. "_loading")
    if not isDownloaded then
        return false
    end

    return true
end

-- 资源是否下载完成
function LeagueCommonCtrl:isDownloadRes()
    local bDownRes = self:checkDownloaded(ACTIVITY_REF.League)
    local bDownCode = self:checkDownloaded(ACTIVITY_REF.League .. "_Code")
    return bDownRes and bDownCode
end

-- 检查是否是 巅峰赛
function LeagueCommonCtrl:checkIsSummitType()
    return self.m_typeStr == "Summit"
end

------------------------------- UI -------------------------------
-- 进入活动主界面
function LeagueCommonCtrl:onEnterLeagueMain(callFunc)
    local activityData = self:getData()
    -- 检查是否可领取上赛季奖励
    if activityData then
        if activityData:isCanCollect() then
            self:requestLastSeasonRank(callFunc)
        else
            local callbackFunc = function()
                if callFunc then
                    callFunc()
                end
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_GUIDE_CHECK)
            end
            if activityData:isOpenRank() then
                self:requestRank(callbackFunc)
            else
                callbackFunc()
            end
        end
    end
end
-- 显示主界面
function LeagueCommonCtrl:showMainLayer(zOrder)
    if not self:isCanShowLayer() then
        return false
    end

    self:onShowMainLayer(zOrder)
end
function LeagueCommonCtrl:onShowMainLayer(zOrder)
    zOrder = zOrder or ViewZorder.ZORDER_UI

    local callFunc = function()
        local uiView = gLobalViewManager:getViewByName("League_MainLayer")
        if uiView then
            return
        end
        local luaPath = string.format("Activity.%s.League_MainLayer", self.m_typeStr)
        local mainUI = util_createView(luaPath)
        mainUI:setName("League_MainLayer")
        self:showLayer(mainUI, zOrder)
    end

    self:onEnterLeagueMain(callFunc)
    return true
end

-- 获取气泡 pool
function LeagueCommonCtrl:getBubbleTipPool()
    if tolua.isnull(self.m_bubbleTipPool) then
        self.m_bubbleTipPool = util_createView("Activity.Common.BubbleTip.League_BubbleTipPool")
    end

    return self.m_bubbleTipPool
end

-- 关卡内入口
function LeagueCommonCtrl:getMachineEntryModule()
    if not self:isCanShowLayer() then
        return false
    end

    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    local expireAt = activityData:getExpireAt()
    local strTime, bOver = util_daysdemaining(expireAt, true)
    if bOver then
        return
    end

    -- return string.format("Activity.%s.Activity_LeaguesEntryNode", self.m_typeStr)
    return "Activity.Common.GameEntry.LeagueEntryNodeBase"
end

-- 促销入口
function LeagueCommonCtrl:getSaleNodeModule()
    local path = "Activity.Common.League_SaleNode"
    if self.m_typeStr == "Summit" then
        path = "Activity.Summit.League_SaleNode"
    end
    return path
end

-- 显示规则界面
function LeagueCommonCtrl:onShowRuleLayer()
    local luaModulePath = string.format("Activity.%s.League_RuleLayer", self.m_typeStr)
    local resultView = util_createView(luaModulePath)
    self:showLayer(resultView, ViewZorder.ZORDER_POPUI)
end

-- 显示领取奖励界面
function LeagueCommonCtrl:onShowCollectResultLayer(_isSkipActon)
    if not self:isCanShowLayer() then
        return false
    end

    local actData = self:getData()
    local resultView = util_createView("Activity.Common.League_CollectResultLayer", actData, _isSkipActon)
    self:showLayer(resultView, ViewZorder.ZORDER_POPUI)
end
------------------------------- UI -------------------------------


------------------------------- 关卡spin获得奖杯 ------------------------------
-- Spin获得奖杯
function LeagueCommonCtrl:onSetGainCup(cupInfo)
    cupInfo = cupInfo or {}
    if not next(cupInfo) then
        return
    end

    local activityData = self:getRunningData()
    if not activityData then
        return
    end
    -- 保存winType
    activityData:setWinCupInfo(cupInfo)

    -- 第一次进榜 轮盘结束后飞，不然飞 和 第一次打开主界面 会冲突 卡一下还
    if self:isFirstInRank() then
        return
    end

    if cupInfo.cupType == "Spin" then
        -- 非大赢直接飞奖杯
        self:onShowGainCup()
    end
end
-- 显示Spin获得奖杯
function LeagueCommonCtrl:onShowGainCup(_closeViewCb)
    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    local bFly = self:onShowFlyCupLayer(_closeViewCb)
    activityData:setWinCupInfo(nil)
    return bFly
end

-- 显示飞奖杯效果
function LeagueCommonCtrl:onShowFlyCupLayer(_closeViewCb)
    local activityData = self:getRunningData()
    if activityData then
        local cupInfo = activityData:getWinCupInfo()
        if not cupInfo then
            return false
        end
        -- 获取要飞到的坐标
        local _node = gLobalActivityManager:getEntryNode("Leagues")
        if tolua.isnull(_node) then
            return false
        end

        local flyDesPos = _node:getFlyDesPos()

        local _isVisible = gLobalActivityManager:getEntryNodeVisible("Leagues")
        if not _isVisible then
            -- 隐藏图标的时候使用箭头坐标
            flyDesPos = gLobalActivityManager:getEntryArrowWorldPos()
        end

        if not flyDesPos then
            return false
        end

        local layer = util_createView("Activity.Common.CupFly.League_CupLayer")
        self:showLayer(layer, ViewZorder.ZORDER_GUIDE, false)
        layer:playGainCupAction(cupInfo, flyDesPos, _closeViewCb)
        activityData:setWinCupInfo(nil)

        return true
    else
        return false
    end
end


-- 更新关卡内排行
function LeagueCommonCtrl:updateRankInLevel(data)
    if not data then
        return
    end

    local rankData = data.arena
    local openRank = data.openRank
    if not rankData and not openRank then
        return
    end

    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    local _oldRank = activityData:getRankListInLevel()

    -- 更新排名和比赛内排行榜
    activityData:updateOpenRank(openRank)
    activityData:updateRankInLevel(rankData)

    local _newRank = activityData:getRankListInLevel()
    if #_oldRank == 0 and #_newRank > 0 then
        -- 第一次进榜
        self:setFirstInRank(true)
        -- 第一次进榜 刷新下商城服务器数据
        gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig()
    end
end

-- 设置第一进榜状态
function LeagueCommonCtrl:setFirstInRank(inRank)
    self.m_firstInRank = inRank
end
-- 检查第一次进榜
function LeagueCommonCtrl:isFirstInRank()
    return self.m_firstInRank or false
end

-- 更新我的分数
function LeagueCommonCtrl:updateMyPoints(myPoints)
    if not myPoints then
        return
    end

    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    activityData:setMyPoints(myPoints)
end
------------------------------- 关卡spin获得奖杯 -------------------------------

------------------------------- jackpot 金币增长 -------------------------------
-- 获得当前jackpot pool
function LeagueCommonCtrl:getCurJackpotPollValue(dt)
    local activityData = self:getRunningData()
    if not activityData then
        return 0, 0, 0
    end

    local _basePool = activityData:getBaseJackpotPool()
    -- if activityData:isCanCollect() then
    --     return _basePool
    -- end

    local _curPool = activityData:getCurJackpotPool() or 0

    local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(_basePool)
    local perAddCount = 0
    local perAdd1 = perAdd * dt
    local perAdd2 = topMaxperAdd * dt

    --判断更新增量
    if _curPool <= maxCoin then
        if perAddCount ~= perAdd1 then
            perAddCount = perAdd1
        end
    elseif _curPool < topMaxCoin then
        if perAddCount ~= perAdd2 then
            perAddCount = perAdd2
        end
    end
    _curPool = perAddCount + _curPool
    if _curPool >= topMaxCoin then
        _curPool = topMaxCoin
    end

    activityData:setCurJackpotPool(_curPool)

    return _curPool, _basePool, maxCoin
end

function LeagueCommonCtrl:getRateInfo(pool)
    local bottomRate = globalData.constantData.QUEST_JACKPOT_POOL_BOTTOM or 1
    local topRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP or 1
    local perRate = globalData.constantData.QUEST_JACKPOT_POOL_ADD or 0
    local topMaxRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP_MAX or 1
    local topMaxSpeed = globalData.constantData.QUEST_JACKPOT_POOL_TOP_SPEED_MAX or 0
    local baseCoin = pool * bottomRate
    local maxCoin = pool * topRate
    local perAdd = pool * perRate
    local topMaxCoin = pool * topMaxRate
    local topMaxperAdd = pool * topMaxSpeed
    return baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd
end
------------------------------- jackpot 金币增长 -------------------------------

------------------------------- 网络 -------------------------------
-- 请求竞技场排行榜
function LeagueCommonCtrl:requestRank(_callback)
    local successCallFun = function(_jsonResult)
        local activityData = self:getRunningData()
        if activityData then
            activityData:parseRankData(_jsonResult)
            if _callback then
                _callback()
            end
            -- 更新排名
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_RANK_UPDATE)
        end
    end

    self.m_netModel:requestRank(successCallFun, self.m_typeStr == "Summit")
end

-- 领取竞技场上赛季排行榜奖励
function LeagueCommonCtrl:requestCollectRankReward(_callFunc)
    -- 拷贝当前数据
    self.m_oldData = nil
    local tempData = self:getData()
    if tempData then
        self.m_oldData = clone(tempData)
    end

    local successCallFun = function(_jsonResult)
        -- 创建显示奖励弹板
        local activityData = self:getRunningData()
        if activityData then
            activityData:parseCollectResult(_jsonResult)
            if _callFunc then
                _callFunc()
            end
        end
    end
    self.m_netModel:requestCollectRankReward(successCallFun, self.m_typeStr == "Summit")
end

-- 上赛季竞技场排行榜
function LeagueCommonCtrl:requestLastSeasonRank(_callback)
    local successCallFun = function(_jsonResult)
        local activityData = self:getData()
        if activityData then
            activityData:parseRankData(_jsonResult)
            if _callback then
                _callback()
            end
            -- 更新界面显示
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_LAST_SEASON_RANK_UPDATE)
        end
    end

    self.m_netModel:requestLastSeasonRank(successCallFun, self.m_typeStr == "Summit")
end
------------------------------- 网络 -------------------------------

------------------------------- skip 爬榜merge -------------------------------
-- 领取竞技场上赛季排行榜奖励
function LeagueCommonCtrl:onCollectRankReward(isSkipActon)
    local callFunc = function()
        -- 显示领取奖励界面
        self:onShowCollectResultLayer(isSkipActon)
    end

    self:requestCollectRankReward(callFunc)
end
-- 下一步领奖
function LeagueCommonCtrl:nextToCollectReward()
    local activityData = self:getRunningData()
    if activityData and activityData:getCollectResult() then
        -- 显示领取奖励界面
        self:onShowCollectResultLayer()
    else
        -- 没有奖励
        self:onShowDivisionLayer()
    end
end
function LeagueCommonCtrl:onSkipClimbRank()
    -- 移除礼盒节点
    local giftNode = gLobalViewManager:getViewByName("League_Gift_Node")
    if giftNode then
        giftNode:removeFromParent()
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEAGUE_SKIP_CLIMB)
    self:onCollectRankReward(true)
end
------------------------------- skip 爬榜merge -------------------------------

return LeagueCommonCtrl