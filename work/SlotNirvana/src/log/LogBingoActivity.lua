--
-- bingo活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local ShopItem = util_require("data.baseDatas.ShopItem")
local NetworkLog = require "network.NetworkLog"
local LogBingoActivity = class("LogBingoActivity", NetworkLog)
LogBingoActivity.m_levelName = nil --关卡名称
LogBingoActivity.m_levelOrder = 0 --关卡序号
LogBingoActivity.m_activityData = nil --bingo活动数据

LogBingoActivity.m_lastBingoData = nil

function LogBingoActivity:ctor()
    NetworkLog.ctor(self)
end

--bingo活动页面 弹窗打点 pageName弹窗名字
function LogBingoActivity:sendBingoPopupLog(pageName, fireBallInfo)
    self:initLogBingoActivity()
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    local messageData = {
        tp = "open",
        et = entryData.entryType,
        en = entryData.entryName,
        eo = entryData.entryOpen,
        eth = entryData.entryTheme,
        pn = pageName
    }
    self:sendBingoActivityLog("BingoPopup", messageData, fireBallInfo)
end

--获得道具log
function LogBingoActivity:getItemStr(itemData)
    if not itemData then
        return nil
    end
    if itemData.p_type == "Buff" then
        local itemBuff = itemData.p_buffInfo
        local itemStr = itemBuff.buffType .. "|" .. itemBuff.buffID .. "|" .. itemBuff.buffMultiple .. "|" .. itemBuff.buffExpire * 1000
        return itemStr --道具类型|道具ID|buff翻倍数|道具时长（毫秒
    else
        local itemStr = itemData.p_type .. "|" .. itemData.p_id .. "|" .. itemData.p_description .. "|" .. itemData.p_num
        return itemStr ----道具类型|道具名称|道具ID|道具数量
    end
end

--gLobalSendDataManager:getBingoActivity():updateLastBingoData()
function LogBingoActivity:updateLastBingoData()
    local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
    if bingoData then
        self.m_lastBingoData = clone(bingoData)
    end
end

--发送log
function LogBingoActivity:sendBingoActivityLog(eventAction, messageData, fireBallInfo)
    if messageData == nil then
        messageData = {}
    end
    if self.m_activityData == nil then
        return
    end

    local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
    if not bingoData then
        return
    end
    local panels = bingoData.panels
    local current = nil
    if fireBallInfo ~= nil then
        local preData = bingoData:getPreData()
        current = fireBallInfo.current or bingoData:getCurrent()
        messageData["rd"] = current.round
        if preData ~= nil then
            messageData["s"] = preData.sequence
        end
    else
        current = bingoData:getCurrent()
        for k, v in ipairs(panels) do
            if v.status == "PLAY" then
                messageData["rd"] = k
                break
            end
        end
        messageData["s"] = bingoData:getSequence()
    end
    local bingoServerLogInfo = bingoData:getServerLogInfo()
    gL_logData:syncUserData()
    gL_logData:syncEventData(eventAction)
    local actName = self:formatActivityTime(self.m_activityData.p_start)
    messageData["name"] = actName
    local starTimer = util_getymd_time(self.m_activityData.p_start)
    messageData["day"] = util_daysforstart(starTimer)
    messageData["r"] = bingoServerLogInfo.r
    messageData["bingoBet"] = bingoServerLogInfo.bingoBet
    messageData["bingoBetUsd"] = bingoServerLogInfo.bingoBetUsd
    messageData["roomNum"] = bingoServerLogInfo.roomNum
    messageData["roomType"] = bingoServerLogInfo.roomType

    --卡序号
    local curCount, totalCount = bingoData:getCurrentCardNumInfo(fireBallInfo)
    messageData["cd"] = curCount
    messageData["difficulty"] = bingoData:getDifficulty()
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end

--获得本地保存的key
function LogBingoActivity:getDefaultKey(key)
    local actTime = self:formatActivityTime(self.m_activityData.p_start)
    local defKey = globalData.userRunData.userUdid .. "_" .. actTime .. "_BingoActivity_" .. key
    return defKey
end
--唯一标识
function LogBingoActivity:getSessionId(SessionType, roundCount, enterCount)
    if enterCount and enterCount > 0 then
        return globalData.userRunData.uid .. "_" .. SessionType .. "_" .. roundCount .. "_" .. enterCount
    else
        return globalData.userRunData.uid .. "_" .. SessionType .. "_" .. roundCount
    end
end
--初始化
function LogBingoActivity:initLogBingoActivity()
    local data = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
    local curMachineData = globalData.slotRunData.machineData or {}
    if data then
        self:setLevelData(curMachineData.p_levelName, curMachineData.p_showOrder, data)
    end
end
--设置活动数据、关卡数据
function LogBingoActivity:setLevelData(levelName, levelOrder, data)
    self.m_levelName = levelName
    self.m_levelOrder = levelOrder
    self.m_activityData = data
end
-- 时间格式 ：2019-09-09 00:00:01
-- 返回： 20190909
function LogBingoActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return "Bingo" .. year .. month .. day
end
function LogBingoActivity:formatServerTime()
    local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    nowTime = math.floor(nowTime)
    local tm = os.date("*t", nowTime)
    return tm.year .. tm.month .. tm.day
end
-- levelName: GameScreenLightCherry
-- 返回：LightCherry ，去掉GameScreen
function LogBingoActivity:formatLevelName(levelName)
    if not levelName then
        return
    end
    return string.sub(levelName, 11)
end

--quest活动奖励log
function LogBingoActivity:sendBingoRankLog(myRankData, pool)
    if self.m_activityData == nil then
        return
    end
    local rank, points
    if myRankData then
        rank = myRankData.p_rank
        points = myRankData.p_points
    end
    local messageData = {
        enterOrder = self.m_enterLevelCount,
        rankingList = rank,
        rewardItemNum = points,
        jackpotCoins = pool --总奖励池
    }

    messageData["location"] = "client"
    messageData["activityName"] = self.m_activitName

    local starTimer = util_getymd_time(self.m_activityData.p_start)
    messageData["activityDay"] = util_daysforstart(starTimer)

    local function getDiffText(index)
        local strDiff = "EASY"
        if index == 2 then
            strDiff = "MEDIUM"
        elseif index == 3 then
            strDiff = "HARD"
        end
        return strDiff
    end

    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        messageData["activityTimes"] = questConfig.p_round
        messageData["activityTheme"] = questConfig.p_phase
        local difficulty = questConfig:getCurDifficulty(questConfig.p_phase)
        messageData["difficultySelect"] = getDiffText(difficulty)
        messageData["difficultyId"] = difficulty
        messageData["difficultyLevel"] = questConfig.p_betDifficulty
    end

    gL_logData:syncUserData()
    gL_logData:syncEventData("RankingOpenAction")

    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end
return LogBingoActivity
