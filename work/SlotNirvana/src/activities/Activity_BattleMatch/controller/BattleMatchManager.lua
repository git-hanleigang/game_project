--[[
Author: ZKK
Description: 比赛聚合管理类
--]]
local BattleMatchManager = class("BattleMatchManager", BaseActivityControl)
local NetWorkBase = util_require("network.NetWorkBase")
local LoadingControl = require("views.loading.LoadingControl")
local ShopItem = util_require("data.baseDatas.ShopItem")

function BattleMatchManager:ctor()
    BattleMatchManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BattleMatch)
    self:resetGainPointsInGamePass()
end

function BattleMatchManager:showMainLayer(_overFunc,inGame)
    local activityData = self:getRunningData()
    if not activityData then
        if _overFunc then
            _overFunc()
        end
        return nil
    end
    if not activityData.m_openRank then
        if not activityData.m_openRank then
            return self:showTipLayer(_overFunc)
        end
    end
    local mainlayer = nil
    self:requestActionRank(function ()
        if not self:isCanShowLayer() then
            if _overFunc then
                _overFunc()
            end
            return nil
        end
        if not gLobalViewManager:getViewLayer():getChildByName("Activity_BattleMatchMainLayer") then
            mainlayer = util_createFindView("Activity/Activity_BattleMatchMainLayer",_overFunc)
            gLobalViewManager:showUI(mainlayer, ViewZorder.ZORDER_UI)
        end
    end, nil)
    
    return mainlayer
end

function BattleMatchManager:showInfoLayer(_overFunc)
    local uiView = util_createFindView("Activity/Activity_BattleMatchInfoLayer")
    if uiView ~= nil then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI,_overFunc)
    end
    return uiView
end

function BattleMatchManager:showTipLayer(_overFunc)
    local uiView = util_createFindView("Activity/Activity_BattleMatchTipLayer",_overFunc)
    if uiView ~= nil then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

function BattleMatchManager:doCheckShowActivityLayer(_overFunc,ignoreGain)
    local result = false
    local isInGame = gLobalViewManager:isLevelView() or gLobalViewManager:isCoinPusherScene() 
    local activityData = self:getRunningData()
    if activityData then
        local hasGain , hasGainPoints = self:checkHasGainActivityPoint()
        if hasGain and isInGame then
            if gLobalViewManager:getViewByExtendData("DailyMissionPassMainLayer") then
                self:setGainPointsInGamePass(hasGain,hasGainPoints,activityData.m_frontRank)
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_REFRESH_BATTLEMATCH_RANK,{hasGain = true,hasGainPoints = hasGainPoints})
            end
        end
        if activityData.m_openRank then
            if isInGame then
                if activityData.m_thisTimeOpenRank and hasGain then
                    result = true
                    self:showMainLayer(_overFunc)
                else
                    if _overFunc then
                        _overFunc()
                    end
                end
            else
                if hasGain or ignoreGain then
                    result = true
                    self:showMainLayer(_overFunc)
                else
                    if _overFunc then
                        _overFunc()
                    end
                end
            end
        else
            if isInGame then
                if _overFunc then
                    _overFunc()
                end
            elseif hasGain or ignoreGain then
                result = true
                self:showTipLayer(_overFunc)
            else
                if _overFunc then
                    _overFunc()
                end
            end
        end
    else
        if _overFunc then
            _overFunc()
        end
    end
    return result 
end

function BattleMatchManager:checkHasGainActivityPoint()
    local hasGain = false
    local hasGainPoints = 0
    local activityData = self:getRunningData()
    if activityData then
        local addPoints = activityData.m_currentPoints - activityData.m_frontPoints
        if addPoints > 0 then
            hasGain = true
            hasGainPoints = addPoints
        end
        activityData:resetFrontPoints()
    end
    return hasGain,hasGainPoints
end



-- 关卡内spin更新活动数据
function BattleMatchManager:updateActivityData(_data)
    local data = self:getRunningData()
    if not data or not _data then
        return
    end
    data:updateActivitySlotData(_data)
end

-- 出关卡时清理 活动对比数据
function BattleMatchManager:clearCompareData()
    local data = self:getRunningData()
    if not data then
        return
    end
    data:clearCompareData()
end

-- 第一次打开排行榜
function BattleMatchManager:resetThisTimeOpenRank()
    local data = self:getRunningData()
    if not data then
        return
    end
    data:resetThisTimeOpenRank()
end

function BattleMatchManager:setGainPointsInGamePass(isGain,hasGainPoints,beganRank)
    if isGain then
        self.m_isGainPointsInGamePass = isGain
        if self.m_gainPointsInGamePass == 0 then
            self.m_beganRank = beganRank
        end
        self.m_gainPointsInGamePass = self.m_gainPointsInGamePass + hasGainPoints
    end
end

function BattleMatchManager:isGainPointsInGamePass()
    return self.m_isGainPointsInGamePass,self.m_gainPointsInGamePass,self.m_beganRank 
end
function  BattleMatchManager:resetGainPointsInGamePass()
    self.m_isGainPointsInGamePass = false
    self.m_gainPointsInGamePass = 0
    self.m_beganRank = 0
end

-- 发送获取排行榜消息
function BattleMatchManager:requestActionRank(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        if failedCallFunc then
            failedCallFunc()
        end
    end

    local function successFunc(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData.result ~= nil then
            local rankData = cjson.decode(resultData.result)
            local battleMatchData = self:getRunningData()
            if battleMatchData and rankData then
                battleMatchData:parseBattleMatchRankData(rankData)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.BattleMatch})
                if successCallFunc then
                    successCallFunc()
                end
            end
        else
            failedFunc()
        end
    end
    gLobalViewManager:addLoadingAnima()
    local actionData = NetWorkBase:getSendActionData(ActionType.CompeteRank)
    local params = {}
    actionData.data.params = json.encode(params)
    NetWorkBase:sendMessageData(actionData, successFunc, failedFunc)
end

-- 发送获取排行榜消息
function BattleMatchManager:requestActionCollectReward(successCallFunc, failedCallFunc)
    local function failedFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local function successFunc(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData.result ~= nil then
            local result = cjson.decode(resultData.result)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_AFTERCOLLETE_BATTLEMATCH_REWARD,self:parseReward(result))
        else
            failedFunc()
        end
    end
    gLobalViewManager:addLoadingAnima()
    local actionData = NetWorkBase:getSendActionData(ActionType.CompeteCollect)
    local params = {}
    actionData.data.params = json.encode(params)
    NetWorkBase:sendMessageData(actionData, successFunc, failedFunc)
end

function BattleMatchManager:parseReward(data)
    local rewards = {}
    rewards.coins = tonumber(data.coins)
    rewards.items = self:parseItems(data.items)
    ------------- 检索合成福袋 zkk-------------
    local rewardItems = rewards.items or {}
    local propsBagList = {}
    for _, data in ipairs(rewardItems) do
        if string.find(data.p_icon, "Pouch") then
            table.insert(propsBagList, data)
        end
    end
    if next(propsBagList) then
        rewards.propsBagList = propsBagList
    end
    return rewards
end

function BattleMatchManager:parseItems(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function BattleMatchManager:getEntryModule()
    if not self:isDownloadRes() then
        return ""
    end
    local _module = "Activity.Activity_BattleMatchEntryNode"
    return _module
end

return BattleMatchManager
