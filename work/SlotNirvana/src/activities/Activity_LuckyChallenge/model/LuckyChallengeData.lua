--[[
    author:JohnnyFred
    time:2019-10-08 19:36:07
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local LuckyChallengeReward = require "data.luckyChallenge.LuckyChallengeReward"
local LuckyChallengeTask = require "data.luckyChallenge.LuckyChallengeTask"
local LuckyChallengeSimpleRank = require "data.luckyChallenge.LuckyChallengeSimpleRank"
local LuckyChallengeRank = require "data.luckyChallenge.LuckyChallengeRank"
local LCPickGameData = require "data.luckyChallenge.LCPickGameData"

local LuckyChallengeData = class("LuckyChallengeData", BaseActivityData)

-- optional string season = 1;
-- optional int32 difficulty = 2; //当前难度
-- optional int32 level = 3; //当前等级
-- optional int32 points = 4; //当前钻石
-- optional int64 start = 6; //开始时间戳（毫秒）
-- optional int64 expireAt = 7; //结束时间戳（毫秒）
-- optional int64 resetAt = 8; //任务重置时间戳（毫秒）
-- repeated LuckyChallengeTask tasks = 9;
-- repeated LuckyChallengeReward rewards = 10;
-- optional LuckyChallengeSimpleRank simpleRank = 11; //简要的排行榜信息
-- optional int32 levelPoints = 12; //当前等级的最大积分数

function LuckyChallengeData:parseData(data, isNotPost)
    LuckyChallengeData.super.parseData(self, data)
    self.lastGameId = data.lastGameId
    self.season = data.season
    self.difficulty = data.difficulty
    self.level = data.level or 1
    self.points = data.points or 0
    self.start = data.start
    -- self.expireAt = tonumber(data.expireAt)
    self.expireAt = self.p_expireAt

    self.resetAt = data.resetAt or 0

    self.redPointList = {}
    self.tasks = {}
    self.m_mapLvTasks = {}
    self.needShowTasks = {}

    if data.gameTasks then
        for i = 1, #data.gameTasks do
            self:createTask(data.gameTasks[i], true, true)
        end
    end
    if data.systemTasks then
        for i = 1, #data.systemTasks do
            self:createTask(data.systemTasks[i], false, i == 1)
        end
    end

    self.rewards = {}
    if data.rewards then
        for i = 1, #data.rewards do
            local tempReward = LuckyChallengeReward:create()
            tempReward:parseData(data.rewards[i])
            self.rewards[i] = tempReward
            if tempReward.status == "COLLECT" then
                if self.redPointList.rewards == nil then
                    self.redPointList.rewards = {}
                end
                self.redPointList.rewards[#self.redPointList.rewards + 1] = tempReward
            end
        end
    end
    if data.simpleRank then
        local tempRank = LuckyChallengeSimpleRank:create()
        tempRank:parseData(data.simpleRank)
        self.simpleRank = tempRank
    end

    self.levelPoints = data.levelPoints
    if data.pickBonus then
        self.pickBonus = LCPickGameData:create()
        self.pickBonus:parseData(data.pickBonus)
        if self.pickBonus.status == "PREPARE" or self.pickBonus.status == "PLAYING" then
            if self.redPointList.rewards == nil then
                self.redPointList.rewards = {}
            end
            self.redPointList.rewards[#self.redPointList.rewards + 1] = self.pickBonus
        end
    end
    --上赛季等级
    self.lastLevel = data.lastLevel
    self.lastLevelPoint = {}
    --赛季继承点数
    if data.lastLevelPoints then
        for i = 1, #data.lastLevelPoints do
            self.lastLevelPoint[i] = data.lastLevelPoints[i]
        end
    end
    if data.lastSeason then
        self.lastSeason = data.lastSeason
    end
    if isNotPost ~= nil and isNotPost == true then
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_UPDATE_VIEW)
    end
end
--[[
    @desc:
    author:{author}
    time:2020-08-05 11:18:33
    --@taskData:  任务数据
	--@isGame:  是否是关卡任务
	--@isCheck:  是否需要检测红点
    @return:
]]
function LuckyChallengeData:createTask(taskData, isGame, isCheck)
    local tempRask = LuckyChallengeTask:create()
    tempRask:parseData(taskData)
    self.tasks[#self.tasks + 1] = tempRask
    local id = math.mod(tempRask.gameId, 10000)
    self.m_mapLvTasks["" .. id] = tempRask
    if isCheck then
        self:checkHasTask(tempRask, isGame)
    end
end

--每次打开界面重置数值
-- function LuckyChallengeData:resetPickGameJackpot()
--     if self.pickBonus then
--         self.pickBonus:resetJackpot()
--     end
--     for i = 1,#self.rewards do
--         if self.rewards[i].status == "COLLECT" then
--             self.rewards[i]:resetJackpot()
--         end
--     end
-- end

function LuckyChallengeData:parseSingleTaskData(data)
    if not data then
        return
    end

    if data.lastGameId ~= 0 then
        self.lastGameId = data.lastGameId
    end

    if data.gameTasks then
        for i = 1, #data.gameTasks do
            local tempRask = LuckyChallengeTask:create()
            tempRask:parseData(data.gameTasks[i])
            self:checkHasAndUpdateAdd(self.tasks, tempRask, true)
            local id = math.mod(tempRask.gameId, 10000)
            self.m_mapLvTasks["" .. id] = tempRask 
            self:checkHasAndUpdateAdd(self.m_mapLvTasks, tempRask, true)
            self:updateShowTask(tempRask, true)
        end
    end
end

function LuckyChallengeData:updateShowTask(data)
    if not self.needShowTasks then
        self.needShowTasks = {}
    end
    local needShow = false
    for i = 1, #self.needShowTasks do
        if self.needShowTasks[i].taskId == data.taskId then
            needShow = true
            self.needShowTasks[i] = data
            break
        end
    end
    if needShow and data.status == "COLLECT" then
        if self.redPointList.tasks == nil then
            self.redPointList.tasks = {}
        end
        self:checkHasAndUpdateAdd(self.redPointList.tasks, data, true)
    end
end
function LuckyChallengeData:checkHasAndUpdateAdd(list, data, isAdd)
    if not list then
        list = {}
    end
    local has = false
    for i = 1, #list do
        if list[i].taskId == data.taskId then
            has = true
            list[i] = data
            break
        end
    end
    if isAdd and not has then
        list[#list + 1] = data
    end
end
function LuckyChallengeData:parseRankData(data)
    if not data then
        return
    end
    self.luckyChallengeRankCfg = LuckyChallengeRank:create()
    self.luckyChallengeRankCfg:parseData(data)
end

function LuckyChallengeData:checkHasTask(data, isGame)
    if not self.needShowTasks then
        self.needShowTasks = {}
    end
    if isGame then
        local has = false
        for i = 1, #self.needShowTasks do
            if self.needShowTasks[i].game == data.game then
                has = true
                break
            end
        end
        if not has then
            if data.status == "COLLECT" then
                if self.redPointList.tasks == nil then
                    self.redPointList.tasks = {}
                end
                self.redPointList.tasks[#self.redPointList.tasks + 1] = data
            end
            self.needShowTasks[#self.needShowTasks + 1] = data
        end
    else
        if data.status == "COLLECT" then
            if self.redPointList.tasks == nil then
                self.redPointList.tasks = {}
            end
            self.redPointList.tasks[#self.redPointList.tasks + 1] = data
        end
        self.needShowTasks[#self.needShowTasks + 1] = data
    end
end
function LuckyChallengeData:isAllOpen()
    -- if self:isOpen() and self:isReachLevel() and gLobalActivityManager:isDownloadRes() then
    if self:isOpen() and self:isReachLevel() then
        return true
    end
    return false
end
function LuckyChallengeData:isOpen()
    if not self.start or not self.expireAt then
        return false
    end
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if tonumber(self.start) / 1000 <= curTime and tonumber(self.expireAt) / 1000 > curTime then
        return true
    end
    return false
end

function LuckyChallengeData:isReachLevel()
    if globalData.userRunData.levelNum < globalData.constantData.CHALLENGE_OPEN_LEVEL then
        return false
    end
    return true
end

function LuckyChallengeData:checkGuideIndexShow(guideIndex)
    -- return false
    if not self:isAllOpen() then
        return false
    end
    if guideIndex == 1 then
        local showTimes = gLobalDataManager:getNumberByField("LCGuide_0_ShowTimes", 0)
        local showParam = gLobalDataManager:getNumberByField("LCGuide_0" .. util_formatServerTime(), 0)
        if showParam == 0 and showTimes <= 3 then
            gLobalDataManager:setNumberByField("LCGuide_0" .. util_formatServerTime(), 1)
            showTimes = showTimes + 1
            gLobalDataManager:setNumberByField("LCGuide_0_ShowTimes", showTimes)
            if showTimes == 3 then
                self:saveLCGuideIndex(1)
            end
            return true
        else
            return false
        end
    elseif guideIndex == 2 then
        return true
    elseif guideIndex == 3 then
        return true
    elseif guideIndex == 4 then
        return true
    elseif guideIndex == 5 then
        return true
    elseif guideIndex == 6 then
        return true
    end
end

function LuckyChallengeData:getLCGuideIndex()
    -- gLobalDataManager:setNumberByField("LCGuide"..globalData.userRunData.uid,5)
    local guideIndex = gLobalDataManager:getNumberByField("LCGuide" .. globalData.userRunData.uid, 0)
    return guideIndex
end

function LuckyChallengeData:saveLCGuideIndex(guideIndex)
    --同步到服务器  防止卸载包导致数据丢失
    gLobalSendDataManager:getNetWorkFeature():sendActionChallengeGuide(guideIndex)
    -- local guideIndex = gLobalDataManager:getNumberByField("LCGuide"..globalData.userRunData.uid,0)
    gLobalDataManager:setNumberByField("LCGuide" .. globalData.userRunData.uid, guideIndex)
end

-- 获取红点信息
-- 0  all 1 task 2 reward
function LuckyChallengeData:getRedPoint(indexType)
    local redNum = 0
    if self.redPointList then
        if indexType == 0 then
            if self.redPointList.tasks then
                redNum = redNum + #self.redPointList.tasks
            end
            if self.redPointList.rewards then
                redNum = redNum + #self.redPointList.rewards
            end
        elseif indexType == 1 then
            if self.redPointList.tasks then
                redNum = redNum + #self.redPointList.tasks
            end
        elseif indexType == 2 then
            if self.redPointList.rewards then
                redNum = redNum + #self.redPointList.rewards
            end
        end
    end
    return redNum
end

--有红点时候该打开哪个选项
function LuckyChallengeData:checkRedPointIndex()
    local index = 1
    if self.redPointList then
        if self.redPointList.tasks and #self.redPointList.tasks > 0 then
            index = 1
            return index
        end
        if self.redPointList.rewards and #self.redPointList.rewards > 0 then
            index = 2
        end
    end
    return index
end

--获得关卡内显示的任务项
function LuckyChallengeData:getCurLevelTask(p_id)
    -- if self.tasks then
    --     for i = 1, #self.tasks do
    --         if self.tasks[i].game and self:checkLevelIsTask(p_id, self.tasks[i]) then
    --             return self.tasks[i]
    --         end
    --     end
    -- end
    -- return nil
    if not p_id then
        return nil
    end
    local id = math.mod(p_id, 10000)
    return self.m_mapLvTasks["" .. id]
end

-- function LuckyChallengeData:checkLevelIsTask(p_id, taskItem)
--     if taskItem.gameId == p_id or taskItem.highGameId == p_id then
--         return true
--     end
--     return false
-- end
--获得上一个关卡内任务项
function LuckyChallengeData:getLevelTaskAfterSpin(taskId)
    for i = 1, #self.tasks do
        if self.tasks[i].taskId == taskId then
            return self.tasks[i]
        end
    end
    return nil
end

function LuckyChallengeData:getSeason()
    return self.season
end

function LuckyChallengeData:getDifficulty()
    return self.difficulty
end

function LuckyChallengeData:getLevel()
    return self.level
end

function LuckyChallengeData:getPoints()
    return self.points
end

function LuckyChallengeData:getRate()
    if not self.levelPoints then
        return 0
    end

    return math.floor(self.points * 100 / self.levelPoints)
end

function LuckyChallengeData:getResetAt()
    return self.resetAt
end

function LuckyChallengeData:getReset()
    return self.reset
end

function LuckyChallengeData:getTasks()
    local guideIndex = self:getLCGuideIndex()
    local redNumTask = self:getRedPoint(1)
    local needSort = false
    if redNumTask > 0 then
        if guideIndex <= 2 then -- 领取任务奖励
            needSort = true
        end
    end
    if needSort then
        for i = 1, #self.needShowTasks do
            if self.needShowTasks[i].status == "COLLECT" then
                local temp = self.needShowTasks[i]
                table.remove(self.needShowTasks, i)
                table.insert(self.needShowTasks, 1, temp)
                break
            end
        end
    end
    -- if index then
    --     return self.needShowTasks[index]
    -- else
    -- for i=1,#self.needShowTasks do
    --     if self.needShowTasks[i].gameId == self.lastGameId or self.needShowTasks[i].highGameId == self.lastGameId then
    --         local temp = self.needShowTasks[i]
    --         table.remove(self.needShowTasks,i)
    --         table.insert(self.needShowTasks, 1, temp)
    --     end
    -- end
    return self.needShowTasks
    -- end
end

function LuckyChallengeData:getRewards()
    return self.rewards
end
function LuckyChallengeData:getRewardByRewardId(rewardId)
    for i = 1, #self.rewards do
        if self.rewards[i].rewardId == tonumber(rewardId) then
            return self.rewards[i]
        end
    end
    return nil
end

function LuckyChallengeData:getLevelRewards(level)
    local result = {}
    for i = 1, #self.rewards do
        if self.rewards[i].level == level then
            result[#result + 1] = self.rewards[i]
        -- if #result >= 5 then
        --     break
        -- end
        end
    end
    return result
end

function LuckyChallengeData:checkIsShowSettlement()
    if not self.lastSeason or tonumber(self.lastSeason) <= 0 or tonumber(self.season) <= 1 then
        return false
    end
    local temp = tonumber(self.season) - tonumber(self.lastSeason)
    if temp > 1 then --赛季差值超过1
        return false
    end
    if self.lastLevel > 0 and self.lastLevelPoint and #self.lastLevelPoint > 0 then
        local key = "LUCKYCHALLENGE_SEASON_" .. self.season
        local curShowTime = gLobalDataManager:getNumberByField(key, 0)
        if curShowTime < 1 then
            gLobalDataManager:setNumberByField(key, 1)
            return true
        end
    end
    return false
end

function LuckyChallengeData:getSimpleRank()
    return self.simpleRank
end

function LuckyChallengeData:getLevelPoints()
    return self.levelPoints
end

function LuckyChallengeData:getRanks()
    return self.simpleRank
end

function LuckyChallengeData:getSmallGame()
    return {}
end

function LuckyChallengeData:getPickData()
    return self.pickBonus
end

function LuckyChallengeData:checkOpenLevel()
    if not LuckyChallengeData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    local needLevel = globalData.constantData.CHALLENGE_OPEN_LEVEL
    if needLevel > curLevel then
        return false
    end

    return true
end

function LuckyChallengeData:checkCanOpenSale()
    --引导期间不弹出促销
    local guideIndex = self:getLCGuideIndex()
    if guideIndex < 6 then
        return false
    end
    --有buff时不弹出促销
    local buffLeftTime = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_LUCKYCHALLENGE_FAST)
    if buffLeftTime > 0 then
        return false
    end
    -- 上次弹出和本次弹出间隔大于 服务站返回值弹出
    if self.m_preTime then
        local tempTime = util_getCurrnetTime()
        local spaceTime = tempTime - self.m_preTime
        if globalData.constantData.CHALLENGE_SALE_TIMES then
            if spaceTime > globalData.constantData.CHALLENGE_SALE_TIMES then
                self.m_preTime = tempTime
            else
                return false
            end
        else
            release_print("CHALLENGE_SALE_TIMES-----is nil")
            return false
        end
    else
        self.m_preTime = util_getCurrnetTime()
    end
    return true
end

return LuckyChallengeData
