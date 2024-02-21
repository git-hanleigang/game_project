--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--

local QuestRankData = require("activities.Activity_Quest.model.QuestRankData")
local QuestPhaseData = require "activities.Activity_Quest.model.QuestPhaseData"
local QuestPassData = require "activities.Activity_Quest.model.QuestPassData"
local ShopItem = require "data.baseDatas.ShopItem"

local BaseActivityData = require "baseActivity.BaseActivityData"
local QuestData = class("QuestData", BaseActivityData)

--记录是否通过quest进入关卡
QuestData.m_IsQuestLogin = false --进入quest关卡
QuestData.m_isQuestLobby = false --进入quest大厅
QuestData.p_isLevelEnterQuest = false --普通关卡点击进入quest
QuestData.p_nextAct = nil --下一关动画

QuestData.m_isAutoShowTop = false --是否自动展示排行榜
QuestData.p_questExtraPrize = nil --剩余多少时间开启活动
QuestData.p_questJackpot = nil --宝箱spin累加值
--因为跳转关卡数据清空 提前保存下来
QuestData.m_lastBoxData = nil --宝箱数据
QuestData.m_lastBoxJackpot = nil --假数据jackpot

QuestData.p_day = nil
--新手quest  结束轮次
QuestData.p_offRounds = nil
--quest活动排行榜
QuestData.m_questRankData = nil

--message QuestConfig {
--    optional int32 expire = 1;
--    optional int64 expireAt = 2;
--    optional string activityId = 3;
--    optional int32 phase = 4; // 当前阶段
--    optional int32 stage = 5; // 第几关卡
--    repeated QuestPhaseInfo phases = 6; // 所有的Quest阶段
--    optional int32 discount = 7; //活动折扣
--    optional string stagePurchase = 8;
--    optional string roundPurchase = 9;
--    optional int32 points = 10; // 玩家累计积分
--    optional int64 avgBet = 11; // 平均bet
--    optional int32 betDifficulty = 12; // 平均bet的难度级别
--    optional int32 round = 13; //轮次
--    optional int32 rankUp = 14; //排名上涨多少，-负数表示下降了
--    optional QuestActivityConfig activities = 15;
--    optional string rewardJackpot = 16; // 宝箱spin累加值
--    optional int64 questBet = 17; // questbet
--    optional int32 r = 18; //r
--    optional int32 zone = 19; // 赛区
--    optional double questBetUsd = 20; // questbetUsd
--    optional int32 day = 21; // 活动开启第几天
--    optional int32 offRounds = 22; // 新手quest，按轮数结束
--    optional QuestSkipSale skipSale = 23;  //跳过促销
--    optional int32 preRank = 24;   //上一期排名，没有就是 0
--    optional QuestSkipSale skipSaleV2 = 25;  // 新版跳过促销
--    optional QuestPass questPass = 26; //quest pass
--    optional int32 leftSkipItems = 27; //剩余skip道具
--   optional string skipSaleVersion = 28; //跳过促销版本
--}
function QuestData:ctor()
    QuestData.super.ctor(self)
    self.m_isNewUserQuest = false
    self.p_phases = {}
end

function QuestData:parseData(data)
    QuestData.super.parseData(self, data)
    self.p_expire = data.expire
    self.p_expireAt = tonumber(data.expireAt)
    self.p_activityId = data.activityId
    self.p_phase = data.phase
    self:setStage(data.stage)
    if not self:getStageIdx() then
        self:setCurStage(1)
    end
    if data.phases ~= nil and #data.phases > 0 then
        local len = #data.phases
        for idx = 1, len do
            if not self.p_phases[idx] then
                self.p_phases[idx] = QuestPhaseData:create()
            end

            self.p_phases[idx]:parseData(data.phases[idx])
            self.p_phases[idx]:setIsLast(idx == len)
        end
    end
    self.p_discount = data.discount
    self.p_points = data.points
    self.p_avgBet = data.avgBet
    self.p_betDifficulty = data.betDifficulty
    self.p_round = data.round
    self.p_rankUp = data.rankUp

    self.p_questExtraPrize = globalData.constantData.ACTIVITY_QUEST_EXTRAPRIZE or 24 * 60 * 60
    -- test
    --self.p_discount = 50
    --self.p_expire = 23 * 60 * 60
    self.p_questJackpot = tonumber(data.rewardJackpot)

    if data.offRounds then
        self.p_offRounds = data.offRounds
    end

    -- pass
    if data:HasField("questPass") then
        if not self.p_pass then
            self.p_pass = QuestPassData:create()
        end
        self.p_pass:parseData(data.questPass)
    end

    if data:HasField("leftSkipItems") then
        self.p_leftSkipItems = data.leftSkipItems
    end

    if data.skipSaleVersion and data.skipSaleVersion == "V3" then
        self.p_isHaveSkipSale_PlanB = true
    end
end

function QuestData:getLeftSkipItemCount()
    return self.p_leftSkipItems or 0
end

function QuestData:parseQuestRankConfig(data)
    if not data then
        return
    end

    if not self.m_questRankData then
        self.m_questRankData = QuestRankData:create()
    end
    self.m_questRankData:parseData(data)
end

function QuestData:getRankCfg()
    return self.m_questRankData
end

function QuestData:isRunning()
    if not QuestData.super.isRunning(self) then
        return false
    end

    if self:isNewUserQuest() and not self:isOpen() then
        return false
    end

    return true
end

function QuestData:setNewUserQuest(isNewUserQuest)
    self.m_isNewUserQuest = isNewUserQuest
end

function QuestData:isNewUserQuest()
    return self.m_isNewUserQuest
end

---------------------------------------新手quest 专用------------------------------------------

-- 新手quest是否可以领取奖励
function QuestData:getNewUserHasReward()
    local stateData = self:getCurStageData()
    if stateData.p_status == "FINISHED" then
        return true
    end
    return false
end
--当前阶段任务是否开启  新手quest
function QuestData:isOpen()
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
function QuestData:isDownLoadRes()
    if globalDynamicDLControl:checkDownloading("Activity_QuestNewUser") or globalDynamicDLControl:checkDownloading("Activity_QuestNewUserCode") then
        return false
    else
        return true
    end
end

--是否是最后一轮
function QuestData:checkIsLastRound()
    if self.p_offRounds and self.p_offRounds == self.p_round - 1 then
        return true
    end
    return false
end
---------------------------------------新手quest end------------------------------------------
-- 从Spin结果中解析数据
function QuestData:parseDataFromSpinResult(spinData)
    if not spinData or not spinData.extend then
        return
    end

    local _extendData = spinData.extend
    self:parseQuestSpinData(_extendData.quest)
    self:parseQuestSkipSaleData(_extendData.questSkipSale)
end

-- 解析当前关卡任务数据
function QuestData:parseQuestSpinData(data)
    if not data then
        return
    end

    self.p_questJackpot = data.questJackpot
    local stage_data = self:getCurStageData()
    if not stage_data then
        return
    end
    stage_data:parseData(data.currentStage, true)

    if data.currentStage and data.currentStage.id then
        local stage_idx = tonumber(data.currentStage.id)
        if stage_idx and stage_data.p_id and stage_data.p_id ~= stage_idx then
            util_sendToSplunkMsg("Quest Data", "当前关卡信息不匹配 " .. "服务器值 " .. stage_idx .. " 客户端值 " .. stage_data.p_id or 0)
        end
    end
end

--跳关sale
function QuestData:parseQuestSkipSaleData(data)
    local stage_data = self:getCurStageData()
    if not stage_data then
        return
    end
    local skipData = stage_data:getSkipData()
    if not skipData then
        return
    end

    if data then
        skipData:parseData(data)
    else
        skipData:setIsOpen(false)
    end
end

--是否弹跳关saleview
function QuestData:getIsShowSkipSaleView()
    local stage_data = self:getCurStageData()
    if not stage_data then
        return false
    end
    local skipData = stage_data:getSkipData()
    if not skipData then
        return false
    end

    return skipData:getIsOpen()
end

function QuestData:getSkipSaleDate()
    local stage_data = self:getCurStageData()
    if not stage_data then
        return
    end
    local skipData = stage_data:getSkipData()
    if not skipData then
        return
    end

    return skipData
end

function QuestData:isHaveSkipSale_PlanB()
    return not not self.p_isHaveSkipSale_PlanB
end

function QuestData:getSkipSaleDate_PlanB()
    local stage_data = self:getCurStageData()
    if not stage_data then
        return false ,nil
    end
    
    return stage_data:getSkipData_PlanB()
end

--当前阶段是否完成
function QuestData:IsTaskFinish(phaseIndex, stageIndex)
    if phaseIndex <= 0 or phaseIndex > #self.p_phases or stageIndex <= 0 then
        return false
    end

    local phaseData = self.p_phases[phaseIndex]
    if not phaseData or not phaseData.p_stages or #phaseData.p_stages <= 0 then
        return false
    end

    local stageData = phaseData.p_stages[stageIndex]
    if not stageData or stageData.p_status == nil or stageData.p_status == "" then
        return false
    end

    if stageData.p_status == "FINISHED" then
        return true
    end

    local tasks = stageData:getTasks()
    if not tasks or table.nums(tasks) <= 0 then
        return false
    end

    for _, task_data in pairs(tasks) do
        if task_data and task_data.p_completed ~= nil then
            if task_data.p_completed == false then
                -- 任务状态和关卡状态一致
                return false
            end
        end
    end

    return true
end

--当前阶段任务是否全部完成
function QuestData:IsTaskAllFinish(phaseIndex)
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData.p_stages ~= nil and #phaseData.p_stages > 0 then
            for i = 1, #phaseData.p_stages do
                local stageData = phaseData.p_stages[i]
                if stageData.p_status ~= "FINISHED" then
                    return false
                end
            end

            return true
        end
    end

    return false
end

--是否有折扣
function QuestData:hasDiscount()
    if self.p_expire <= self.p_questExtraPrize and self.p_discount > 0 then
        return true
    end

    return false
end

function QuestData:getDiscount()
    if self.p_expire <= self.p_questExtraPrize then
        return math.max(self.p_discount, 0)
    else
        return 0
    end
end

function QuestData:getCurPhaseData()
    return self:getPhaseData(self.p_phase)
end

function QuestData:getPhaseIdx()
    return self.p_phase
end

function QuestData:getPhaseData(phaseIndex)
    if phaseIndex and phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        return phaseData
    end
    return nil
end

--获取关卡数据
function QuestData:getStageData(phaseIndex, stageIndex)
    local phaseData = self:getPhaseData(phaseIndex)
    if phaseData and phaseData.p_stages ~= nil and stageIndex > 0 and stageIndex <= #phaseData.p_stages then
        local stageData = phaseData.p_stages[stageIndex]
        return stageData
    end
    return nil
end

--获取当前关卡数据
function QuestData:getCurStageData()
    local stageData = self:getStageData(self.p_phase, self.p_stage)
    return stageData
end

function QuestData:getStageIdx()
    return self.p_stage
end

function QuestData:getIsFirstStage()
    return (self.p_phase == 1 and self.p_stage == 1)
end

--根据索引获取该关卡是否是quest配置的关卡
function QuestData:getIsQuestConfigLevel(levelId)
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

function QuestData:getCurTaskInfo()
    local phase_idx = self:getPhaseIdx()
    local stage_idx = self:getStageIdx()
    local task_data = self:getTaskInfo(phase_idx, stage_idx)
    return task_data
end

--获取任务信息
function QuestData:getTaskInfo(phaseIndex, stageIndex)
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData.p_stages ~= nil and stageIndex > 0 and stageIndex <= #phaseData.p_stages then
            local stageData = phaseData.p_stages[stageIndex]
            return stageData.p_tasks
        end
    end

    return nil
end

function QuestData:getPhaseReward()
    local phase_reward = self:getRewardEndStage(self.p_phase)
    return phase_reward
end

--获取当前阶段，最后一关奖励
function QuestData:getRewardEndStage(phaseIndex)
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
function QuestData:getCurDifficulty(phaseIndex, isChooseDifficulty)
    if phaseIndex > 0 and phaseIndex <= #self.p_phases then
        local phaseData = self.p_phases[phaseIndex]
        if phaseData ~= nil then
            return phaseData.p_chooseDifficulty
        end
    end
    return -1
end

function QuestData:getPhaseCount()
    return #self.p_phases or 0
end

--获取关卡和轮盘的总数量
function QuestData:getStageCount()
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

function QuestData:setStage(_stageIdx)
    if not _stageIdx or _stageIdx < 0 then
        return
    end
    if self:isNewUserQuest() or self:getThemeName() ~= "Activity_QuestIsland" then
        self.p_stage = _stageIdx
    end
end

function QuestData:setCurStage(_stageIdx)
    if not _stageIdx or _stageIdx < 0 then
        return
    end
    if not self:isNewUserQuest() and self:getThemeName() == "Activity_QuestIsland" then
        self.p_stage = _stageIdx
    end
end

function QuestData:recordLastBoxData()
    -- 记录一下旧的数值 之前的写法 这个好像用在金币刷新的地方
    local lastBoxData = self:getPhaseReward()
    if lastBoxData then
        self.m_lastBoxData = clone(lastBoxData)
    end
    if self.p_stage == 6 then
        self.m_lastPhase = self.p_phase
    end
    self.m_lastBoxJackpot = self.p_questJackpot
end

--获取入口位置 1：左边，0：右边
function QuestData:getPositionBar()
    return 1
end

function QuestData:getOpenLevel()
    if self:isNewUserQuest() then
        return globalData.constantData.OPENLEVEL_FIRSTQUEST or 5
    else
        return QuestData.super.getOpenLevel(self)
    end
end

function QuestData:isIgnoreExpire()
    local isIgnor = QuestData.super.isIgnoreExpire(self)
    if isIgnor then
        return true
    end

    if self:isNewUserQuest() and self:checkIsLastRound() then
        return true
    end

    return false
end

function QuestData:recordPhaseChips(chips, phase_idx)
    if chips and chips > 0 and phase_idx and phase_idx > 0 then
        self.recordChips = chips
        self.recordPhaseIdx = phase_idx
    end
end

function QuestData:getPhaseChips()
    return self.recordChips, self.recordPhaseIdx
end

function QuestData:clearPhaseChips()
    self.recordChips = nil
    self.recordPhaseIdx = nil
end

function QuestData:recordTaskProcess(phaseIndex)
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

function QuestData:getTaskRecordProcess(phaseIndex, stageIndex)
    if not phaseIndex or not stageIndex then
        return
    end

    local idx = phaseIndex .. "_" .. stageIndex
    if not self.taskRecords or not self.taskRecords[idx] then
        local record_datas = G_GetMgr(ACTIVITY_REF.Quest):getRecordStageInfo()
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

function QuestData:clearTaskRecordProcess(phaseIndex, stageIndex)
    if not phaseIndex or not stageIndex then
        return
    end

    local idx = phaseIndex .. "_" .. stageIndex
    if self.taskRecords and self.taskRecords[idx] then
        self.taskRecords[idx] = nil
    end
end

function QuestData:getTaskProcess(phaseIndex, stageIndex)
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

function QuestData:getTaskProcessByData(task_data, phaseIndex, stageIndex)
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

function QuestData:getPassData()
    return self.p_pass
end

function QuestData:parsePassData(_data)
    if self.p_pass then
        self.p_pass:parseData(_data)
    end
end

-- 新手quest 登录到大厅直接进入 quest 界面(第一章未完成) 
function QuestData:checkNewUserLoginShowQuest()
    if not self:isNewUserQuest() then
        return false
    end

    local phaseIdx = self:getPhaseIdx() or 0
    return phaseIdx < 2
end 

function QuestData:getCurrentPhaseJackpotWheelData()
    local curPhaseData = self:getCurPhaseData()
    if curPhaseData then
        return curPhaseData:getJackpotWheeldata()
    end
    return false,{}
end


function QuestData:updateQuestGoldIncrease(forceInit,data)
    local hasJackpot,wheelData = self:getCurrentPhaseJackpotWheelData()
    if hasJackpot then
        return wheelData:updateQuestGoldIncrease(forceInit,data)
    end
    return false 
end

function QuestData:getRunGoldCoinByType(type)
    local hasJackpot,wheelData = self:getCurrentPhaseJackpotWheelData()
    if hasJackpot then
        return wheelData:getRunGoldCoinByType(type)
    end
    return 1111111
end

function QuestData:isCanShowRunGold()
    local hasJackpot,wheelData = self:getCurrentPhaseJackpotWheelData()
    if hasJackpot then
        return wheelData:isCanShowRunGold()
    end
    return false
end

function QuestData:setWheelResultData(resultData)
    local hasJackpot,wheelData = self:getCurrentPhaseJackpotWheelData()
    if hasJackpot then
        wheelData:setWheelResultData(resultData)
    end
end

return QuestData
