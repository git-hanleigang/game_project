--
-- find活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogFindActivity = class("LogFindActivity", NetworkLog)
LogFindActivity.m_levelName = nil --关卡名称
LogFindActivity.m_levelOrder = 0 --关卡序号
LogFindActivity.m_activityData = nil --find活动数据
LogFindActivity.m_enterLevelCount = 0 --进入关卡次数
LogFindActivity.m_enterFindViewCount = 0 --进入find小游戏次数
LogFindActivity.m_findItemCount = 0 --活动期间累计道具数量
LogFindActivity.m_spinCount = 0 --活动期间累计spin次数
LogFindActivity.m_winCoins = 0 --活动期间累计赢钱数量
LogFindActivity.m_betCoins = 0 --活动期间累计消耗数量

function LogFindActivity:ctor()
    NetworkLog.ctor(self)
end

function LogFindActivity:initData()
    --初始化进入关卡次数
    self:initEnterLevelCount()

    --进入find小游戏次数
    self:initEnterFindViewCount()

    --活动期间累计道具数量
    self:initFindItemCount()

    self:initSpinCount()
    self:initWinCoins()
    self:initBetCoins()
end

function LogFindActivity:clearData()
    self:clearSpinCount()
    self:clearWinCoins()
    self:clearBetCoins()
end

--唯一标识
function LogFindActivity:getSessionId(SessionType, roundCount, enterCount)
    if enterCount and enterCount > 0 then
        return globalData.userRunData.uid .. "_" .. SessionType .. "_" .. roundCount .. "_" .. enterCount
    else
        return globalData.userRunData.uid .. "_" .. SessionType .. "_" .. roundCount
    end
end

--[[
key:
--EnterLevelCount       :活动进入次数
--EnterFindViewCount    :进入find小游戏次数
--FindItemCount         :活动期间获取的道具数量
--SpinCount             :活动期间累计spin次数
--WinCoins              :活动期间累计赢钱数量
--BetCoins              :活动期间累计消耗数量
--PurchaseAmount        :活动期间累计支付
]]
function LogFindActivity:getDefaultKey(key)
    local actTime = self:formatActivityTime(self.m_activityData.p_start)
    local defKey = globalData.userRunData.userUdid .. "_" .. actTime .. "_FindActivity_" .. key
    return defKey
end

--初始化活动期间进入关卡次数
function LogFindActivity:initEnterLevelCount()
    local key = self:getDefaultKey("EnterLevelCount")
    self.m_enterLevelCount = gLobalDataManager:getNumberByField(key, 0)
end

--活动进入次数
function LogFindActivity:updateEnterLevelCount()
    local key = self:getDefaultKey("EnterLevelCount")
    local count = gLobalDataManager:getNumberByField(key, 0)
    count = count + 1
    self.m_enterLevelCount = count

    --记录一下
    gLobalDataManager:setNumberByField(key, count)
end

--初始化活动期间进入find小游戏次数
function LogFindActivity:initEnterFindViewCount()
    local key = self:getDefaultKey("EnterFindViewCount")
    self.m_enterFindViewCount = gLobalDataManager:getNumberByField(key, 0)
end

--进入Find小游戏次数
function LogFindActivity:updateEnterFindViewCount()
    local key = self:getDefaultKey("EnterFindViewCount")
    local count = gLobalDataManager:getNumberByField(key, 0)
    count = count + 1
    self.m_enterFindViewCount = count

    --记录一下
    gLobalDataManager:setNumberByField(key, count)
end

--初始化活动期间获取的道具数量
function LogFindActivity:initFindItemCount()
    local key = self:getDefaultKey("FindItemCount")
    self.m_findItemCount = gLobalDataManager:getNumberByField(key, 0)
end

--活动期间累计道具数量
function LogFindActivity:updateFindItemCount()
    local key = self:getDefaultKey("FindItemCount")
    local count = gLobalDataManager:getNumberByField(key, 0)
    count = count + 1
    self.m_findItemCount = count

    --记录一下
    gLobalDataManager:setNumberByField(key, count)
end

--初始化活动期间累计spin次数
function LogFindActivity:initSpinCount()
    local key = self:getDefaultKey("SpinCount")
    self.m_spinCount = gLobalDataManager:getNumberByField(key, 0)
end

function LogFindActivity:clearSpinCount()
    local key = self:getDefaultKey("SpinCount")
    gLobalDataManager:setNumberByField(key, 0)

    self.m_spinCount = 0
end

function LogFindActivity:getSpinCount()
    return self.m_spinCount
end

--活动期间累计spin次数
function LogFindActivity:updateSpinCount()
    local key = self:getDefaultKey("SpinCount")
    local count = gLobalDataManager:getNumberByField(key, 0)
    count = count + 1
    self.m_spinCount = count

    --记录一下
    gLobalDataManager:setNumberByField(key, count)
end

--初始化活动期间累计赢钱数量
function LogFindActivity:initWinCoins()
    local key = self:getDefaultKey("WinCoins")
    self.m_winCoins = gLobalDataManager:getNumberByField(key, 0)
end

function LogFindActivity:clearWinCoins()
    local key = self:getDefaultKey("WinCoins")
    gLobalDataManager:setNumberByField(key, 0)

    self.m_winCoins = 0
end

function LogFindActivity:getWinCoins()
    return self.m_winCoins
end

--活动期间累计赢钱数量
function LogFindActivity:updateWinCoins(coins)
    if coins == nil or coins <= 0 then
        return
    end

    local key = self:getDefaultKey("WinCoins")
    local count = gLobalDataManager:getNumberByField(key, 0)
    count = count + coins
    self.m_winCoins = count

    --记录一下
    gLobalDataManager:setNumberByField(key, count)
end

--初始化活动期间累计消耗数量
function LogFindActivity:initBetCoins()
    local key = self:getDefaultKey("BetCoins")
    self.m_betCoins = gLobalDataManager:getNumberByField(key, 0)
end

function LogFindActivity:clearBetCoins()
    local key = self:getDefaultKey("BetCoins")
    gLobalDataManager:setNumberByField(key, 0)

    self.m_betCoins = 0
end

function LogFindActivity:getBetCoins()
    return self.m_betCoins
end

--活动期间累计消耗数量
function LogFindActivity:updateBetCoins(coins)
    if coins == nil or coins <= 0 then
        return
    end

    local key = self:getDefaultKey("BetCoins")
    local count = gLobalDataManager:getNumberByField(key, 0)
    count = count + coins
    self.m_betCoins = count

    --记录一下
    gLobalDataManager:setNumberByField(key, count)
end

--设置活动数据、关卡数据
function LogFindActivity:setLevelData(levelName, levelOrder, d)
    self.m_levelName = levelName
    self.m_levelOrder = levelOrder
    self.m_activityData = d
end

function LogFindActivity:getTaskStatus()
    if globalData.findData:IsHaveData() and globalData.findData.p_findNum ~= globalData.findData.p_maxNum then
        return globalData.findData.p_findNum .. "/" .. globalData.findData.p_maxNum
    end

    return "TaskFinish"
end

function LogFindActivity:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据

    NetworkLog.sendLogData(self)
end

function LogFindActivity:sendFindActivityLog(eventAction, messageData)
    if messageData == nil then
        messageData = {}
    end

    if self.m_activityData == nil then
        self.m_activityData = {}
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData(eventAction)

    local actName = self:formatActivityTime(self.m_activityData.p_start)
    messageData["location"] = "client"
    messageData["activityName"] = actName
    local starTimer = util_getymd_time(self.m_activityData.p_start)
    messageData["activityDay"] = util_daysforstart(starTimer)
    messageData["activitytimes"] = globalData.findResult.p_round
    messageData["findItemMax"] = globalData.findResult.p_roundMaxNum
    messageData["findItemNum"] = globalData.findResult.p_roundFindNum
    if self.m_levelName then
        messageData["activitySite"] = self.m_levelName .. "Find"
    end
    messageData["activityDifficulty"] = "auto"
    messageData["difficultyId"] = globalData.findData.p_difficulty
    messageData["activityEnterTimes"] = self.m_enterLevelCount
    messageData["findSession"] = self:getSessionId(actName .. "_Session", globalData.findResult.p_round)
    messageData["findTaskSession"] = self:getSessionId(actName .. "_TaskSession", globalData.findResult.p_round, self.m_enterFindViewCount)
    messageData["order"] = self.m_levelOrder
    messageData["game"] = self.m_levelName

    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end

function LogFindActivity:getTaskActionType(pos)
    local strActionType = ""
    if pos == 1 or pos == 4 then
        if self.m_spinCount <= 0 then
            strActionType = "GameStart"
        else
            strActionType = "AgainEnter"
        end
    elseif pos == 2 then
        strActionType = "GetProps"
    elseif pos == 3 then
        strActionType = "LeaveHalfway"
    elseif pos == 51 then
        strActionType = "CloseEnterFind"
    elseif pos == 52 then
        strActionType = "CloseFind"
    elseif pos == 53 then
        strActionType = "OpenFind"
    elseif pos == 54 then
        strActionType = "EnterFind"
    elseif pos == 6 then
        strActionType = "FinshToGame"
    end

    return strActionType
end

function LogFindActivity:getBuffInfo()
    local buffTime = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPY_FIND_EXTRATIME)
    local buffLeftTime = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPY_FIND_DOUBLEPRIZE)
    local _buffStatus = false
    local _buffName = nil
    if buffTime then
        _buffStatus = true
        local buffData = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPY_FIND_EXTRATIME)
        _buffName = buffData.buffID
    end
    if buffLeftTime and buffLeftTime > 0 then
        _buffStatus = true
        local buffData = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPY_FIND_DOUBLEPRIZE)
        if _buffName then
            _buffName = _buffName .. "|" .. buffData.buffID
        else
            _buffName = buffData.buffID
        end
    end
    if _buffName then
        _buffName = tostring(_buffName)
    end
    return _buffStatus, _buffName
end

--task道具掉落
--[[
pos:
      1.进入关卡
      2.获得道具时
      3.关卡中途退出
      4.已开启活动再次进入
      51. 集齐对话框点击退出按钮
      52. 集齐对话框显示对号
      53. 集齐对话框隐藏对号
      54. 完成任务点击按钮进入Find界面
      6.完成Find活动回到关卡界面
itemData:
      获得的道具数据
]]
function LogFindActivity:sendFindTaskLog(pos, itemData)
    if self.m_activityData == nil or self.m_levelName == nil or self.m_levelName == "" then
        return
    end

    local itemId1 = nil
    local itemName1 = nil
    local itemId2 = nil
    local itemName2 = nil
    local itemId3 = nil
    local itemName3 = nil
    local itemType = nil
    if itemData ~= nil then
        if itemData[1] then
            itemId1 = itemData[1].p_itemId
            itemName1 = itemData[1].p_name
        end
        if itemData[2] then
            itemId2 = itemData[2].p_itemId
            itemName2 = itemData[2].p_name
        end
        if itemData[3] then
            itemId3 = itemData[3].p_itemId
            itemName3 = itemData[3].p_name
        end

        itemType = "ActivityItem"
    end

    local _buffStatus, _buffName = self:getBuffInfo()

    local messageData = {
        actionType = self:getTaskActionType(pos),
        gameTaskStatus = self:getTaskStatus(),
        taskItemId1 = itemId1,
        taskItemName1 = itemName1,
        taskItemId2 = itemId2,
        taskItemName2 = itemName2,
        taskItemId3 = itemId3,
        taskItemName3 = itemName3,
        taskItemType = itemType,
        buffStatus = _buffStatus,
        buffName = _buffName,
        taskItemMax = globalData.findData.p_maxNum,
        taskItemProgress = globalData.findData.p_findNum,
        totalItemNum = self.m_findItemCount,
        findTaskTimes = self.m_enterFindViewCount,
        spins = self.m_spinCount,
        win = self.m_winCoins,
        bet = self.m_betCoins
    }

    self:sendFindActivityLog("FindTaskAction", messageData)
end

--find奖励领取
-- 区分不同奖励：
-- TaskReward = 本次find找全奖励 wellDone + 在规定时间内找全额外奖励 extra
-- "ReWard"..cur.."/"..total = 本轮阶段奖励道具或金币process
-- ItemData = { coins = 1000, id = 10001, num = 1, type = "buff"}
function LogFindActivity:sendFindAwardLog(RewardType, ItemData)
    if self.m_activityData == nil or self.m_levelName == nil or self.m_levelName == "" then
        return
    end
    ItemData = ItemData or {}
    local reward_type = nil
    local coins = nil
    if RewardType == "TaskReward" then
        reward_type = "TaskReward"
    elseif RewardType == "ReWard" then
        reward_type = "ReWard" .. ItemData.currentPro .. "/" .. globalData.findResult.p_roundMaxNum
    elseif RewardType == "FinalReward" then
        reward_type = "FinalReward"
    end

    local messageData = {
        rewardType = reward_type,
        rewardCoins = ItemData.coins,
        rewardItemId = ItemData.id,
        rewardItemType = ItemData.type,
        rewardItemNum = ItemData.num,
        findPurchaseAmount = globalData.findData.p_amount
    }

    self:sendFindActivityLog("FindAwardAction", messageData)
end

--find游戏
function LogFindActivity:sendFindGameLog(errorCount, helpCount, cost_Time, surplus_Time)
    if self.m_activityData == nil or self.m_levelName == nil or self.m_levelName == "" then
        return
    end

    local finishState = "Failed"
    if globalData.findResult.p_findNum >= globalData.findResult.p_maxNum then
        finishState = "Success"
    end

    local function getActivityProgress()
        local progress = globalData.findResult.p_roundFindNum .. "/" .. globalData.findResult.p_roundMaxNum
        if globalData.findResult.p_roundFindNum >= globalData.findResult.p_roundMaxNum then
            progress = "activityFinish"
        end

        return progress
    end

    local messageData = {
        gameTaskStatus = "OpenFind",
        findTaskTimes = self.m_enterFindViewCount,
        findItemTimes = globalData.findResult.p_findNum,
        mistakeItemTimes = errorCount,
        helpTimes = helpCount,
        findFinishStatus = finishState,
        activityFinishProgress = getActivityProgress(),
        findCost = cost_Time,
        surplusTime = surplus_Time,
        rewardCoins = globalData.findResult.p_wellDoneCoins + globalData.findResult.p_extraCoins,
        rewardItemCoins = globalData.findResult.p_wellDoneCoins,
        rewardTimeCoins = globalData.findResult.p_extraCoins
    }

    self:sendFindActivityLog("FindGameAction", messageData)
end

--find活动道具
--[[
itemData          --道具数据
findNum           --find进度 - 当前找到了几个
findStatus        --Sucess  or Failed
findIndex         --找到该道具顺序，失败时Null
findcost          --找到该道具计时
]]
function LogFindActivity:sendFindGameItemLog(itemId, findNum, findStatus, findIndex, findcost)
    if self.m_activityData == nil or self.m_levelName == nil or self.m_levelName == "" then
        return
    end

    local function getFindStatus(status)
        if status then
            return "Sucess"
        end
        return "Failed"
    end

    local messageData = {
        gameTaskStatus = "OpenFind",
        findTaskTimes = self.m_enterFindViewCount,
        findItemId = itemId,
        findItemType = "ActivityItem",
        findItemProgress = findNum .. "/" .. globalData.findData.p_maxNum,
        findItemStatus = getFindStatus(findStatus),
        findItemOrder = findIndex,
        findItemCost = findcost
    }

    self:sendFindActivityLog("FindGameItemAction", messageData)
end

-- 1.活动页面中间页面打开
-- 2.活动主题页面打开
-- 打开中间页=openTheme、打开界面=open
function LogFindActivity:sendFindThemePageLog(operationType, pageName)
    self:initLogFindActivity()
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        entryType = entryData.entryType,
        entryName = entryData.entryName,
        entryOpen = entryData.entryOpen,
        entryTheme = entryData.entryTheme,
        entryOrder = entryData.entryOrder,
        operationType = operationType,
        pageName = pageName
    }
    self:sendFindActivityLog("FindThemePageAction", messageData)
end

function LogFindActivity:initLogFindActivity()
    local data = globalData.commonActivityData:getActivityData(globalData.findData.p_activityId)
    local curMachineData = globalData.slotRunData.machineData or {}
    if data then
        gLobalSendDataManager:getLogFindActivity():setLevelData(curMachineData.p_levelName, curMachineData.p_showOrder, data)
    end
    gLobalSendDataManager:getLogFindActivity():initData()
end

-- 时间格式 ：2019-09-09 00:00:01
-- 返回： 20190909
function LogFindActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return "FindNew" .. year .. month .. day
end

-- levelName: GameScreenLightCherry
-- 返回：LightCherry ，去掉GameScreen
function LogFindActivity:formatLevelName(levelName)
    if not levelName then
        return
    end
    return string.sub(levelName, 11)
end

return LogFindActivity
