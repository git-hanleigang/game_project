-- 新版大富翁数据解析

local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local WorldTripTaskData = require("activities.Activity_WorldTrip.model.WorldTripTaskData")
local WorldTripRecallData = require("activities.Activity_WorldTrip.model.WorldTripRecallData")
local WorldTripData = class("WorldTripData", BaseActivityData)

function WorldTripData:ctor()
    WorldTripData.super.ctor(self)
    self.curCellIdx = 0
    self.maxCellIdx = 0
    self.lastCellIdx = 0
    self.endCellIdx = 0
    self.tarCellIdx = 0
end

------------------------------------    游戏登录数据    ------------------------------------
--//新版大富翁信息
-- message WorldTripConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 round = 4; //轮次
--     optional int32 leftDices = 5; //剩余骰子数量
--     optional int32 diceLimit = 6; //最大骰子数量
--     optional int32 spinDiceLimit = 7; //spin骰子数量上限
--     repeated WorldTripChapterInfo chapterInfoList = 8; //章节信息
--     optional WorldTripGameReward roundReward = 9; //轮次奖励
--     optional int32 collect = 10; //Spin能量收集个数
--     optional int32 max = 11; //Spin能量最大收集个数
--     optional int32 selectDiceNumberTimes = 12; //选择筛子点数 剩余次数
--     optional int32 maxSelectDiceNumberTimes = 13; //选择筛子点数 最大次数
--     optional int32 currentChapter = 14; //当前章节
--     optional WorldTripChapterGame chapterGame = 15; //当前章节游戏数据
--     optional int32 recallPoints = 16; //recall积累点数
--     optional int32 maxRecallPoints = 17; //recall积累点数
--     optional WorldTripRecallGame recallGame = 18; //recall小游戏数据
--     optional WorldTripTask task = 19; //任务
--     optional string status = 20; //状态 CHAPTER/RECALL/RECALL_END(recall结束待复活)
--     optional int32 zone = 21; //排行榜 赛区
--     optional int32 roomType = 22; //排行榜 房间类型
--     optional int32 roomNum = 23; //排行榜 房间数
--     optional int32 rankUp = 24; //排行榜排名上升的幅度
--     optional int32 rank = 25; //排行榜排名
--     optional int32 points = 26; //排行榜 积分
-- }
function WorldTripData:parseData(data, isNetData)
    BaseActivityData.parseData(self, data, isNetData)

    -- 登录数据
    self.leftDices = data.leftDices -- 剩余骰子数量
    self.diceLimit = data.diceLimit -- 最大骰子数量
    self.spinDiceLimit = data.spinDiceLimit -- spin累积骰子上限
    self.collect = data.collect -- Spin能量收集个数(关卡中骰子收集进度)
    self.max = data.max -- Spin能量最大收集个数
    self.optionalDices = data.selectDiceNumberTimes -- 选择骰子点数 剩余次数
    self.maxOptionalDices = data.maxSelectDiceNumberTimes -- 选择骰子点数 最大次数
    self.finalRewards = self:parseRewards(data.roundReward)
    self.phaseData = self:parsePhasesData(data.chapterInfoList) -- 所有章节简要信息
    if self.curPhaseIdx and self.curPhaseIdx ~= data.currentChapter then
        -- 跨章节 重置数据
        self.lastCellIdx = 0
        self.curCellIdx = 0
        self.endCellIdx = 0
        self.dice_num = 0
        self:setIsNewChapter(true)
    end
    self.curPhaseIdx = data.currentChapter -- 当前章节
    self.curPhaseData = self:parseCurPhaseData(data.chapterGame)
    self:mergePosToCellData()
    if self.curPhaseData then
        self.tarCellIdx = self.curPhaseData.cur_idx
        self.maxCellIdx = #self.curPhaseData.cells
        if self.lastCellIdx == 0 then
            self.lastCellIdx = self.tarCellIdx
        end
        if self.curCellIdx == 0 then
            self.curCellIdx = self.tarCellIdx
        end
        if self.endCellIdx == 0 then
            self.endCellIdx = self.tarCellIdx
        end
    end

    self.recallPoints = data.recallPoints -- recall积累点数
    self.maxRecallPoints = data.maxRecallPoints -- recall积累点数最大值
    self:parseRecallData(data.recallGame)
    self:parseTaskData(data.task)
    self.status = data.status -- 状态 CHAPTER/RECALL/RECALL_END(recall结束待复活)
    self.rank = tonumber(data.rank) or 0 -- 排行榜排名
    self.points = tonumber(data.points) -- 排行榜积分
    self.rankUp = tonumber(data.rankUp) -- 排行榜排名上升的幅度
    self.round = tonumber(data.round)
    -- 数据刷新事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.WorldTrip})
end

-- message WorldTripChapterInfo {
--     optional int32 chapter = 1; //章节
--     optional bool special = 2; //是否是特殊章节
--     optional WorldTripGameReward reward = 3;//奖励
--     optional string status = 4; //状态 INIT/PLAYING/FINISH
-- }
function WorldTripData:parsePhasesData(data)
    if not data or table.nums(data) <= 0 then
        return
    end
    local phases = {}
    for idx, phase_data in ipairs(data) do
        if not phases[idx] then
            phases[idx] = {}
        end
        phases[idx].idx = phase_data.chapter
        phases[idx].isSpecial = phase_data.special
        phases[idx].rewards = self:parseRewards(phase_data.reward)
        phases[idx].status = phase_data.status
    end

    return phases
end

-- message WorldTripChapterGame {
--     optional int32 chapter = 1;//章节
--     optional WorldTripGameReward reward = 2; //奖励
--     optional int32 current = 3; //当前位置
--     repeated WorldTripChapterPosition positionList = 4; //格子信息
-- }
function WorldTripData:parseCurPhaseData(data)
    local phase_data = {}
    if not data then
        return phase_data
    end
    phase_data.rewards = self:parseRewards(data.reward)
    phase_data.cur_idx = data.current
    phase_data.cells = self:parseCellData(data.positionList)
    return phase_data
end

-- message WorldTripChapterPosition {
--     optional int32 index = 1; //格子索引
--     optional int32 type = 2; //格子类型 0:空 1:金币 2:物品 3:前进 4:后退 5:促销buff
--     optional int32 forwardNum = 3; //前进格子数
--     optional int32 backwardNum = 4; //后退格子数
--    optional WorldTripGameReward reward = 5;//奖励
-- }
function WorldTripData:parseCellData(data)
    if not data then
        return
    end
    local cell_list = {}
    for _idx, _data in ipairs(data) do
        if _data then
            local cell_data = {}
            cell_data.idx = _data.index
            cell_data.cell_type = _data.type
            cell_data.step = 0

            if cell_data.cell_type == 4 then
                cell_data.step = _data.forwardNum
            elseif cell_data.cell_type == 5 then
                cell_data.step = _data.backwardNum
            end
            cell_data.rewards = self:parseRewards(_data.reward)
            cell_list[_idx] = cell_data
        end
    end

    return cell_list
end

function WorldTripData:setRouters(routerList)
    if routerList and table.nums(routerList) >= 0 then
        self.router_list = routerList
    end

    self:mergePosToCellData()
end

function WorldTripData:mergePosToCellData()
    if self.router_list and table.nums(self.router_list) > 0 then
        for idx, pos in ipairs(self.router_list) do
            if idx then
                local cell_data = self:getCellData(idx)
                if cell_data then
                    cell_data.pPos = pos
                end
            end
        end
    end
end

-- message WorldTripRecallGame {
--     optional int32 current = 1; //当前位置
--     repeated WorldTripChapterPosition positionList = 2; //格子信息
--     optional int32 needGems = 3; //复活所需宝石
--     optional bool resurrected = 4; //是否复活过
--     optional WorldTripGameReward winReward = 5; //赢得的奖励
-- }
function WorldTripData:parseRecallData(data)
    if not data then
        return
    end
    if not self.recallData then
        self.recallData = WorldTripRecallData:create()
    end
    self.recallData:parseData(data)
end

-- message WorldTripTask {
--     optional string taskDesc = 1; //任务描述
--     optional int64 param = 2; //目标
--     optional int64 process = 3; //进度
--     optional bool completed = 4; //是否完成
--     optional WorldTripGameReward reward = 5; //奖励
-- }
function WorldTripData:parseTaskData(data)
    if not data then
        return
    end

    if not self.taskData then
        self.taskData = WorldTripTaskData:create()
    end
    self.taskData:parseData(data)
end

-- message WorldTripGameReward {
--     optional int64 coins = 1; //金币奖励
--     repeated ShopItem itemList = 2; //物品奖励
-- }
function WorldTripData:parseRewards(data)
    if not data then
        return
    end
    local rewards = {coins = 0, items = {}}
    if data then
        if data.coins and tonumber(data.coins) > 0 then
            rewards.coins = tonumber(data.coins)
        end
        if data.itemList and table.nums(data.itemList) > 0 then
            for _, item_data in ipairs(data.itemList) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data)
                table.insert(rewards.items, shopItem)
            end
        end
    end
    return rewards
end

-- 解析排行榜信息
function WorldTripData:parseWorldTripRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

------------------------------------    游戏进度数据    ------------------------------------
-- 地图上制掷骰子结果
function WorldTripData:parsePlayData(data)
    -- local a = {
    --     addRecallPoints = 2,
    --     cardDropInfoList = {},
    --     current = 10,
    --     diceNumber = 3,
    --     end = false,
    --     recall = false,
    --     recallPoints = 4,
    --     success = true,
    --     taskCompleted = false,
    --     taskParam = 5,
    --     taskProcess = 0
    -- }
    self.dice_num = data.diceNumber
    self.endCellIdx = self.lastCellIdx + self.dice_num
    local max_idx = self:getMaxIdx()
    if self.endCellIdx >= max_idx then
        self.endCellIdx = max_idx
    end
    self.leftDices = data.leftDices
    self.optionalDices = data.selectDiceNumberTimes -- 选择骰子点数 剩余次数
    self.maxOptionalDices = data.maxSelectDiceNumberTimes -- 选择骰子点数 最大次数
    self.tarCellIdx = data.current
    if self.taskData then
        self.taskData:parsePlayData(data)
        self.nextTask = data.nextTask
    end

    if data.latticeCoins and tonumber(data.latticeCoins) > 0 then
        local reward_data = {}
        reward_data.coins = tonumber(data.latticeCoins)
        reward_data.itemList = {}
        local cell_rewards = self:parseRewards(reward_data)
        self:setCellRewardRecord(cell_rewards)
    end

    self.recallPoints = data.recallPoints
    if data.recall then
        self.status = "RECALL"
    else
        self.status = "CHAPTER"
    end

    if data.recallGame then
        self.recallData:parseData(data.recallGame)
    end
end

function WorldTripData:parseRecallPlayData(data)
    self.dice_num = data.diceNumber
    self.status = data.status
    self.recallData:parseRecallPlayData(data)
end

------------------------------------    获取游戏数据    ------------------------------------
-- 当前轮数
function WorldTripData:getSequence()
    return self.round or 1
end

-- 当前章节
function WorldTripData:getCurrent()
    return self.curPhaseIdx or 1
end

-- 获取最终大奖
function WorldTripData:getFinalReward()
    return self.finalRewards
end

-- 获取章节简要信息
function WorldTripData:getPhaseInfoByIdx(idx)
    if idx and self.phaseData[idx] then
        return self.phaseData[idx]
    end
end

function WorldTripData:getPhaseRewardByIdx(idx)
    local phase_data = self:getPhaseInfoByIdx(idx)
    if phase_data and phase_data.rewards then
        return phase_data.rewards
    end
end

-- 获取章节奖励
function WorldTripData:getPhaseReward()
    local rewards = self:getPhaseRewardByIdx(self.curPhaseIdx)
    return rewards
end

function WorldTripData:getAllPhases()
    return self.phaseData
end

function WorldTripData:getPhaseMax()
    return table.nums(self.phaseData)
end

-- 获取当前章节详细数据
function WorldTripData:getCurPhaseData()
    return self.curPhaseData
end

-- 获取当前章节id
function WorldTripData:getCurPhaseIdx()
    return self.curPhaseIdx
end

-- 设置当前格子id
function WorldTripData:setCurIdx(_idx)
    self.curCellIdx = _idx
end

-- 获取当前格子id
function WorldTripData:getCurIdx()
    return self.curCellIdx
end

function WorldTripData:setLastIndex(_index)
    self.lastCellIdx = _index
end
-- 上一次移动位置
function WorldTripData:getLastIdx()
    return self.lastCellIdx
end

function WorldTripData:isEndRouter(_idx)
    if not self.endCellIdx or _idx >= self.endCellIdx then
        return true
    end
    return false
end

-- 获取下一个路点
function WorldTripData:getNextRouter()
    local cur_idx = self:getCurIdx()
    if not self:isEndRouter(cur_idx) then
        local next_idx = cur_idx + 1
        local cell_data = self:getCellData(next_idx)
        return cell_data
    end
    return false
end

function WorldTripData:getEndIdx()
    return self.endCellIdx
end

function WorldTripData:getTargetIdx()
    return self.tarCellIdx
end

function WorldTripData:getMaxIdx()
    return self.maxCellIdx
end

function WorldTripData:getDiceNum()
    return self.dice_num
end

function WorldTripData:refreshTask()
    if self.nextTask then
        self.taskData:parseData(self.nextTask)
        self.nextTask = nil
    end
end

function WorldTripData:resetCellIdx()
    self.lastCellIdx = self.tarCellIdx
    self.curCellIdx = self.tarCellIdx
    self.endCellIdx = self.tarCellIdx
    self.dice_num = 0
end

-- 当前步骤的奖励是否已经获取
function WorldTripData:isCellComplete(_idx)
    if not _idx or _idx <= 0 then
        return false
    end
    local cur_idx = self:getCurIdx()
    return cur_idx >= _idx
end

function WorldTripData:isPhaseComplete()
    return self.status == "CHAPTER" and self.curCellIdx == self.maxCellIdx
end

-- 格子奖励
function WorldTripData:setCellRewardRecord(data)
    if not data then
        return
    end
    self.record_cellReward = self:parseRewards(data)
end

function WorldTripData:getCellRewardRecord()
    return self.record_cellReward
end

function WorldTripData:clearCellRewardRecord()
    self.record_cellReward = nil
end

-- 章节奖励
function WorldTripData:setPhaseRewardRecord(data)
    if not data then
        return
    end
    self.record_phaseReward = self:parseRewards(data)
end

function WorldTripData:getPhaseRewardRecord()
    return self.record_phaseReward
end

function WorldTripData:clearPhaseRewardRecord()
    self.record_phaseReward = nil
end

-- 通关奖励
function WorldTripData:setFinalRewardRecord(data)
    if not data then
        return
    end
    self.record_finalReward = self:parseRewards(data)
end

function WorldTripData:getFinalRewardRecord()
    return self.record_finalReward
end

function WorldTripData:clearFinalRewardRecord()
    self.record_finalReward = nil
end

-- {
--     idx = 1,
--     cell_type = 1,
--     step = 0,
--     rewards = {coins = 0, items = {}}
-- }
function WorldTripData:getCellData(idx)
    local cur_phase = self:getCurPhaseData()
    if cur_phase and cur_phase.cells and cur_phase.cells[idx] then
        return cur_phase.cells[idx]
    end
end

function WorldTripData:getCurCellData()
    local cur_idx = self:getCurIdx()
    local cur_cell = self:getCellData(cur_idx)
    if cur_cell then
        return cur_cell
    end
end

-- 获取任务数据
function WorldTripData:getTaskData()
    return self.taskData
end

-- 获取小游戏数据
function WorldTripData:getRecallData()
    return self.recallData
end

-- 获取小游戏点数
function WorldTripData:getRecallPoints()
    return self.recallPoints
end

function WorldTripData:getRecallPointsMax()
    return self.maxRecallPoints
end

-- 获取当前章节状态
function WorldTripData:getStatus()
    return self.status
end

function WorldTripData:setStatus(status)
    self.status = status
end

function WorldTripData:isNewChapter()
    return self.bl_phaseNew
end

function WorldTripData:setIsNewChapter(bl_new)
    self.bl_phaseNew = bl_new
end

-- 获取剩余骰子数
function WorldTripData:getDices()
    return self.leftDices
end

-- 获取骰子投掷点数
-- function WorldTripData:getDice()
--     return self.dice
-- end

function WorldTripData:getOptionalDices()
    return self.optionalDices or 0
end

function WorldTripData:getOptionalDicesMax()
    return self.maxOptionalDices or 0
end

-- 获取排行榜cfg
function WorldTripData:getRankCfg()
    return self.p_rankCfg
end

--获取入口位置 1：左边，0：右边
function WorldTripData:getPositionBar()
    return 1
end

return WorldTripData
