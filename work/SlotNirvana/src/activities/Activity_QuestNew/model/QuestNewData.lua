--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--

local QuestNewRankData = require("activities.Activity_QuestNew.model.QuestNewRankData")
local QuestNewChapterData = require "activities.Activity_QuestNew.model.QuestNewChapterData"
local QuestNewCoinIncreaseData = require "activities.Activity_QuestNew.model.QuestNewCoinIncreaseData"
local ShopItem = require "data.baseDatas.ShopItem"

local BaseActivityData = require "baseActivity.BaseActivityData"
local QuestNewData = class("QuestNewData", BaseActivityData)

QuestNewData.p_questExtraPrize = nil --剩余多少时间开启活动
QuestNewData.p_questJackpot = nil --宝箱spin累加值

QuestNewData.p_day = nil
--新手quest  结束轮次
QuestNewData.p_offRounds = nil
--quest活动排行榜
QuestNewData.m_questRankData = nil

-- message FantasyQuest {
--   optional string activityName = 1;
--   optional string theme = 2;
--   optional string begin = 3;
--   optional int64 expireAt = 4;
--   optional string activityId = 5;
--   optional int32 round = 6;
--   optional int32 phase = 7;
--   repeated FantasyQuestPhase phases = 8;
--   optional string minor = 9; // link jackpot金币
--   optional string major = 10;
--   optional string grand = 11;
--   optional int32 expire = 12;
-- }


function QuestNewData:ctor()
    QuestNewData.super.ctor(self)
    self.m_isNewUserQuestNew = false
end

function QuestNewData:parseData(data)
    QuestNewData.super.parseData(self, data)
    
    self.p_phase = data.phase  --章节进度
    self.p_stage = data.stage  --关卡进度
    if not self.p_stage_Before then
        self.p_stage_Before = self.p_stage
    end
    if data.phases ~= nil and #data.phases > 0 then
        local allChapterCount = #data.phases
        if not self.p_phases or self.p_forceInitChapter then
            self.p_phases = {}
            for i = 1, #data.phases do
                local phasesInfo = QuestNewChapterData:create()
                phasesInfo:parseData(data.phases[i],i,self.p_phase)
                phasesInfo:setAllChapterCount(allChapterCount)
                self.p_phases[#self.p_phases + 1] = phasesInfo
            end
        else
            for i = 1, #data.phases do
                self.p_phases[i]:parseData(data.phases[i],i,self.p_phase)
            end
        end
    end
    local allMaxChapter = #self.p_phases

    if self.p_phase == allMaxChapter and self.p_phases[allMaxChapter]:isWheelFinish() and not self.m_hasReset then
        self.m_hasReset = true
        local phasesInfo = QuestNewChapterData:create()
        phasesInfo:parseData(nil,allMaxChapter,self.p_phase,true)
        self.p_phases[#self.p_phases + 1] = phasesInfo
    end

    self.p_theme = data.theme
    self.p_begin = data.begin
    self.p_round = data.round
    self.p_minor = tonumber(data.minor)  --link jackpot金币
    self.p_major = tonumber(data.major) 
    self.p_grand = tonumber(data.grand) 

    
    self.p_leftSpins = tonumber(data.leftSpins) or 0 -- 任务进度X2 剩余可用次数

    if data.fantasyQuestSaleData then
        self.p_fantasyQuestSaleData = {}
        if data.fantasyQuestSaleData.gems and #data.fantasyQuestSaleData.gems >0 then
            self.p_fantasyQuestSaleData.p_gems = data.fantasyQuestSaleData.gems
        end
        if data.fantasyQuestSaleData.spinTimes and #data.fantasyQuestSaleData.spinTimes >0 then
            self.p_fantasyQuestSaleData.p_spinTimes = data.fantasyQuestSaleData.spinTimes
        end
    end
end

function QuestNewData:setForceInitChapter(doForce)
    self.p_forceInitChapter = doForce
end

function QuestNewData:getALlChapter()
    return self.p_phases
end

function QuestNewData:getChapterDataByChapterId(chapterId)
    if chapterId <= #self.p_phases then
        return self.p_phases[chapterId]
    end
    return nil
end

function QuestNewData:getCurrentChapterData()
    return self.p_phases[self.p_phase]
end

function QuestNewData:getPointDataByChapterIdAndIndex(chapterId,index)
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        return chapterData:getPointDataByIndex(index)
    end
    return nil
end

function  QuestNewData:getALLPointDataByChapterId(chapterId)
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        return chapterData:getAllPointData()
    end
    return nil
end

-------------------------------------------------刷新章节-----------------------------------------------
function QuestNewData:getCurrentChapterID()
    return self.p_phase
end

function QuestNewData:checkChapterCompleted()
    for i = 1, #self.p_phases do
        self.p_phases[i]:checkChapterCompleted()
    end
end

------------------------------------------关卡相关---------------------------------------------------------------------

---记录是否通过quest进入关卡
function QuestNewData:setEnterGameFromQuest(isEnterGameFromQuest)
    self.m_isEnterGameFromQuest = isEnterGameFromQuest
    if not isEnterGameFromQuest then
        self.m_enterGameChapterId = nil
        self.m_enterGamePointId = nil
    end
end
function QuestNewData:isEnterGameFromQuest()
    return self.m_isEnterGameFromQuest
end

---记录是否通过关卡进入Quest
function QuestNewData:setEnterQuestFromGame(isEnterQuestFromGame)
    self.m_isEnterQuestFromGame = isEnterQuestFromGame
end
function QuestNewData:isEnterQuestFromGame()
    return self.m_isEnterQuestFromGame
end


function QuestNewData:setEnterGameChapterIdAndPointId(chapterId,pointId)
    self.m_enterGameChapterId = chapterId
    self.m_enterGamePointId = pointId
end

function QuestNewData:getEnterGameChapterIdAndPointId()
    return self.m_enterGameChapterId ,self.m_enterGamePointId
end

function QuestNewData:getEnterGamePointData()
    return self:getPointDataByChapterIdAndIndex(self.m_enterGameChapterId,self.m_enterGamePointId)
end

function QuestNewData:getEnterGamePointNextData()
    local data = self:getPointDataByChapterIdAndIndex(self.m_enterGameChapterId,self.m_enterGamePointId + 1)
    if not data then
        data = {isWheel = true}
    end
    return data
end

function QuestNewData:getStageIdx()
    return self.p_stage
end

function QuestNewData:getEnterGameTaskInfo()
    local use_chapterId = self.m_enterGameChapterId
    local use_pointId = self.m_enterGamePointId
    if not use_chapterId or not use_pointId then
        use_chapterId = self.p_phase
        use_pointId = self.p_stage
    end
    local task_data = self:getTaskInfo(use_chapterId, use_pointId)
    return task_data
end

--获取任务信息
function QuestNewData:getTaskInfo(chapterId, stageIndex)
    if chapterId > 0 and chapterId <= #self.p_phases then
        local chapterData = self:getChapterDataByChapterId(chapterId)
        if chapterData.p_stages ~= nil and stageIndex > 0 and stageIndex <= #chapterData.p_stages then
            local stageData = chapterData:getPointDataByIndex(stageIndex) 
            return stageData:getAllTask()
        end
    end
    return nil
end






function QuestNewData:parseQuestRankConfig(data)
    if not data then
        return
    end

    if not self.m_questRankData then
        self.m_questRankData = QuestNewRankData:create()
    end
    self.m_questRankData:parseData(data)
end

function QuestNewData:getRankCfg()
    return self.m_questRankData
end

function QuestNewData:isRunning()
    if not QuestNewData.super.isRunning(self) then
        return false
    end

    if self:isNewUserQuestNew() and not self:isOpen() then
        return false
    end

    return true
end

function QuestNewData:setNewUserQuest(isNewUserQuestNew)
    self.m_isNewUserQuestNew = isNewUserQuestNew
end

function QuestNewData:isNewUserQuestNew()
    return self.m_isNewUserQuestNew
end

---------------------------------------新手quest 专用------------------------------------------

-- 新手quest是否可以领取奖励
function QuestNewData:getNewUserHasReward()
    local stateData = self:getCurStageData()
    if stateData.p_status == "FINISHED" then
        return true
    end
    return false
end
--当前阶段任务是否开启  新手quest
function QuestNewData:isOpen()
    if not self.p_expireAt then
        return false
    end
    if globalData.constantData.OPENLEVEL_NEWUSERQUEST and globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_NEWUSERQUEST then
        return false
    end
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return (self.p_expireAt / 1000) >= curTime
end

--资源是否已下载
function QuestNewData:isDownLoadRes()
    if globalDynamicDLControl:checkDownloading("Activity_QuestNewNewUser") or globalDynamicDLControl:checkDownloading("Activity_QuestNewNewUserCode") then
        return false
    else
        return true
    end
end

--是否是最后一轮
function QuestNewData:checkIsLastRound()
    if self.p_offRounds and self.p_offRounds == self.p_round - 1 then
        return true
    end
    return false
end


---------------------------------------新手quest end------------------------------------------



-- 从Spin结果中解析数据
function QuestNewData:parseDataFromSpinResult(spinData)
    if not spinData or not spinData.extend then
        return
    end

    local _extendData = spinData.extend
    self:parseQuestNewSpinData(_extendData.quest)
    
end

-- 解析当前关卡任务数据
function QuestNewData:parseQuestNewSpinData(data)
    if not data then
        return
    end

    if data.leftSpins then
        self.p_leftSpins = tonumber(data.leftSpins)-- 任务进度X2 剩余可用次数
    end

    if not data.currentStage then
        return
    end
    local chapterId = data.currentPhase
    local pointId = data.currentStage.stage
    if not chapterId or not pointId then
        return
    end
    local chapterData = self:getChapterDataByChapterId(chapterId)
    if chapterData then
        if data.phasePickStars then
            chapterData:setPickStars(data.phasePickStars)
        end
        if data.jackpotWheel then
            chapterData:refreshWheelData(data.jackpotWheel)
        end
        if data.nextStageResult then
            local nextPointId = data.nextStageResult.stage
            if nextPointId then
                self.p_stage = nextPointId
                chapterData:setCurrentStage(nextPointId)
                local nextPoint_data = chapterData:getPointDataByIndex(nextPointId) 
                if nextPoint_data then
                    nextPoint_data:parseData(data.nextStageResult)
                end
            end
        end
        local point_data = chapterData:getPointDataByIndex(pointId) 
        if point_data then
            point_data:refreshDataAfterSpin(data.currentStage)
        end
    end
    
    --self.p_questJackpot = data.questJackpot
end

--当前阶段是否完成
function QuestNewData:IsTaskFinish(phaseIndex, stageIndex)
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData.p_stages ~= nil and stageIndex > 0 and stageIndex <= #phaseData.p_stages then
            local stageData = phaseData.p_stages[stageIndex]
            return stageData.p_status == "FINISHED"
        end
    end

    return false
end

--当前阶段任务是否全部完成
function QuestNewData:IsTaskAllFinish(phaseIndex)
    if not phaseIndex then
        phaseIndex = self.p_phase
    end
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData.p_stages ~= nil and #phaseData.p_stages > 0 then
            for i = 1, #phaseData.p_stages do
                local stageData = phaseData.p_stages[i]
                if not stageData:isCompleted() then
                    return false
                end
            end

            return true
        end
    end

    return false
end

function QuestNewData:isHasReset()
    return not not self.m_hasReset
end
--是否有折扣
function QuestNewData:hasDiscount()
    if self.p_expire <= self.p_questExtraPrize and self.p_discount > 0 then
        return true
    end

    return false
end

function QuestNewData:getDiscount()
    if self.p_expire <= self.p_questExtraPrize then
        return math.max(self.p_discount, 0)
    else
        return 0
    end
end

function QuestNewData:getCurPhaseData()
    return self:getPhaseData(self.p_phase)
end

function QuestNewData:getPhaseIdx()
    return self.p_phase
end

function QuestNewData:getPhaseData(phaseIndex)
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        return phaseData
    end
    return nil
end

--获取关卡数据
function QuestNewData:getStageData(phaseIndex, stageIndex)
    local phaseData = self:getPhaseData(phaseIndex)
    if phaseData and phaseData.p_stages ~= nil and stageIndex > 0 and stageIndex <= #phaseData.p_stages then
        local stageData = phaseData.p_stages[stageIndex]
        return stageData
    end
    return nil
end


function QuestNewData:getIsFirstStage()
    return (self.p_phase == 1 and self.p_stage == 1)
end

--根据索引获取该关卡是否是quest配置的关卡
function QuestNewData:getIsQuestNewConfigLevel(levelId)
    if self.p_phases and #self.p_phases > 0 then
        for i = 1, #self.p_phases do
            local stagesData = self.p_phases[i].p_stages
            if stagesData and #stagesData > 0 then
                for j = 1, #stagesData do
                    local levelData = stagesData[j]
                    if levelData.p_gameId == levelId then
                        return true
                    end
                end
            end
        end
    end
    return false
end



function QuestNewData:getPhaseReward()
    local phase_reward = self:getRewardEndStage(self.p_phase)
    return phase_reward
end

--获取当前阶段，最后一关奖励
function QuestNewData:getRewardEndStage(phaseIndex)
    if phaseIndex > 0 and self.p_phases and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData.p_stages ~= nil and #phaseData.p_stages > 0 then
            local stageIndex = #phaseData.p_stages
            local stageData = phaseData.p_stages[stageIndex]
            return stageData
        end
    end
end

--当前阶段难度
function QuestNewData:getCurDifficulty(phaseIndex, isChooseDifficulty)
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData ~= nil then
            return phaseData.p_chooseDifficulty
        end
    end
    return -1
end

--获取关卡和轮盘的总数量
function QuestNewData:getStageCount()
    local count = 0
    if self.p_phases ~= nil and #self.p_phases > 0 then
        for i = 1, #self.p_phases do
            local stageData = self.p_phases[i]
            if stageData.p_stages ~= nil and #stageData.p_stages > 0 then
                count = count + #stageData.p_stages
            end
        end
    end
    return count
end

function QuestNewData:recordLastBoxData()
    -- 记录一下旧的数值 之前的写法 这个好像用在金币刷新的地方
    local lastBoxData = self:getPhaseReward()
    if lastBoxData then
        self.m_lastBoxData = clone(lastBoxData)
    end
    if self.p_stage == 6 then
        self.m_lastPhase = self.p_phase
        self.m_lastBoxCoins = globalData.userRunData.coinNum
    end
    self.m_lastBoxJackpot = self.p_questJackpot
end

--获取入口位置 1：左边，0：右边
function QuestNewData:getPositionBar()
    return 1
end

function QuestNewData:getOpenLevel()
    if self:isNewUserQuestNew() then
        return globalData.constantData.OPENLEVEL_FIRSTQUEST or 5
    else
        return QuestNewData.super.getOpenLevel(self)
    end
end

function QuestNewData:isIgnoreExpire()
    local isIgnor = QuestNewData.super.isIgnoreExpire(self)
    if isIgnor then
        return true
    end

    if self:isNewUserQuestNew() and self:checkIsLastRound() then
        return true
    end

    return false
end

function QuestNewData:recordTaskProcess(phaseIndex)
    if not phaseIndex then
        return
    end

    if not self.taskRecords then
        self.taskRecords = {}
    end
    local phase_data = self:getPhaseData(phaseIndex)
    for stageIndex, stage_data in pairs(phase_data.p_stages) do
        local idx = phaseIndex .. "_" .. stageIndex
        local percent = self:getTaskProcess(phaseIndex, stageIndex)
        self.taskRecords[idx] = percent
    end
end

function QuestNewData:getTaskRecordProcess(phaseIndex, stageIndex)
    if not phaseIndex or not stageIndex then
        return
    end

    local idx = phaseIndex .. "_" .. stageIndex
    if not self.taskRecords or not self.taskRecords[idx] then
        local record_datas = G_GetMgr(ACTIVITY_REF.QuestNew):getRecordStageInfo()
        if record_datas and record_datas.phaseIdx == phaseIndex then
            local cell_data = record_datas.phase_data.p_stages[stageIndex]
            if cell_data and cell_data.p_tasks then
                local process = self:getTaskProcessByData(cell_data.p_tasks)
                return process or 0
            end
        end

        return self:getTaskProcess(phaseIndex, stageIndex)
    end

    return self.taskRecords[idx]
end

function QuestNewData:clearTaskRecordProcess(phaseIndex, stageIndex)
    if not phaseIndex or not stageIndex then
        return
    end

    local idx = phaseIndex .. "_" .. stageIndex
    if self.taskRecords and self.taskRecords[idx] then
        self.taskRecords[idx] = nil
    end
end

function QuestNewData:getTaskProcess(phaseIndex, stageIndex)
    if not phaseIndex or not stageIndex then
        return
    end

    local task_data = self:getTaskInfo(phaseIndex, stageIndex)
    local process = self:getTaskProcessByData(task_data)
    if not process then
        local stage_data = self:getStageData(phaseIndex, stageIndex)
        if stage_data then
            if stage_data.p_status == "COMPLETE" then
                return 100
            else
                return 0
            end
        end
    end
    return process
end

function QuestNewData:getTaskProcessByData(task_data, phaseIndex, stageIndex)
    if task_data and table.nums(task_data) > 0 then
        local complete_count = 0
        local total_counts = #task_data
        if total_counts > 0 then
            for idx, task_data in pairs(task_data) do
                if task_data and task_data.p_completed then
                    complete_count = complete_count + 1
                end
            end
            return math.ceil(complete_count / total_counts * 100)
        end
    end
    return 0
end

function QuestNewData:getLeftSpins()
    return self.p_leftSpins
end

function QuestNewData:getSaleData()
    return self.p_fantasyQuestSaleData
end

-------------------------------------------------时间记忆------------------------------------------------------------------
----

function QuestNewData:setTargetQuestGoldIncrease(data)
    self.p_minor_target = tonumber(data.minorPoolCoins) + self.p_minor --link jackpot金币
    self.p_major_target = tonumber(data.majorPoolCoins) + self.p_major
    self.p_grand_target = tonumber(data.grandPoolCoins) + self.p_grand
    if data.newJackpotUser then
        self.m_gainJackpotType = data.newJackpotUser.jackpotType
        self.m_gainJackpotUserName = data.newJackpotUser.name
    end
end

function QuestNewData:rememberOldCoins()
    self.p_minor_old = self.p_minor
    self.p_major_old = self.p_major
    self.p_grand_old = self.p_grand
end

function QuestNewData:updateQuestGoldIncrease(forceInit,data)
    if not self.m_isInitGoldRun and not data then
        return false 
    end

    if data then
        self:setTargetQuestGoldIncrease(data)
    end
    local refresh = false
    if (forceInit  or not self.m_increaseList) and data then
        self.m_increaseList = {}
       
        local minorData = QuestNewCoinIncreaseData:create()
        minorData:setMaxCoins(self.p_minor_old,self.p_minor_target,self.p_minor)
        if self.m_gainJackpotType and self.m_gainJackpotType == 1 then
            
        end
        self.m_increaseList[#self.m_increaseList + 1] = minorData

        local majorData = QuestNewCoinIncreaseData:create()
        majorData:setMaxCoins(self.p_major_old,self.p_major_target,self.p_major)
        self.m_increaseList[#self.m_increaseList + 1] = majorData

        local grandData = QuestNewCoinIncreaseData:create()
        grandData:setMaxCoins(self.p_grand_old,self.p_grand_target,self.p_grand)
        self.m_increaseList[#self.m_increaseList + 1] = grandData
        if not self.m_isInitGoldRun then
            self.m_isInitGoldRun = true
        end
    else
        for i = 1, #self.m_increaseList do
            local oneRefresh = self.m_increaseList[i]:updateIncrese()
            if not refresh then
                refresh = oneRefresh
            end
        end
    end
    return refresh
end

-- 第二个返回值 是否是展示名字
function QuestNewData:getRunGoldCoinByType(type)
    return self.m_increaseList[type]:getRuningGold()
end

function QuestNewData:isCanShowRunGold()
    return not not self.m_isInitGoldRun
end

-- 新手quest 登录到大厅直接进入 quest 界面(第一章未完成) 
function QuestNewData:checkNewUserLoginShowQuest()
    if not self:isNewUserQuestNew() then
        return false
    end

    local phaseIdx = self:getPhaseIdx() or 0
    return phaseIdx < 2
end 

return QuestNewData
