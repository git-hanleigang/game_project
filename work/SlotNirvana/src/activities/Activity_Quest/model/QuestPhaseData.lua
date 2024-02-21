-- quest 章节数据

local CommonRewards = require "data.baseDatas.CommonRewards"
local QuestStageData = require "activities.Activity_Quest.model.QuestStageData"
local QuestPhaseJackpotWheelData = require("activities.Activity_Quest.model.QuestPhaseJackpotWheelData")
local QuestPhaseData = class("QuestPhaseData")

--message QuestPhaseInfo {
--    optional string status = 1; //当前阶段的状态 INIT, GAMING, FINISHED
--    repeated QuestStageInfo stages = 3; // 本阶段所有的关卡数据
--    optional int32 chooseDifficulty = 6; //选择难度
--    optional int64 phaseCoins = 7;
--    repeated ShopItem items = 8;
--    optional int32 pickChips = 9;
--    optional QuestWheel wheelData = 10; // 海岛章节轮盘奖励
--    optional int32 maxChips = 11; // 总进度
--    optional QuestJackpotWheel jackpotWheel = 12; // 常规章节转盘
--}
function QuestPhaseData:parseData(data)
    --status:INIT, GAMING, FINISHED
    self.p_status = data.status -- 章节状态
    self.p_chooseDifficulty = data.chooseDifficulty -- 章节是否选择过难度
    self.p_phaseCoins = data.phaseCoins -- 章节奖励金币
    self.p_pickChips = data.pickChips -- 章节收集碎片进度
    self.p_maxChips = data.maxChips -- 章节收集碎片上限
    self:parseStagesData(data.stages) -- 关卡数据

    if tonumber(self.p_phaseCoins) <= 0 then
        self.p_phaseCoins = self.p_stages[#self.p_stages].p_coins
    end
    self.p_phaseItems = self.p_stages[#self.p_stages].p_items

    self:parseWheeldata(data.wheelData)

    self:parseJackpotWheeldata(data.jackpotWheel)
end

function QuestPhaseData:parseStagesData(data)
    if not self.p_stages then
        self.p_stages = {}
    end
    if data and #data > 0 then
        local len = #data
        for idx = 1, len do
            local _data = data[idx]
            if not self.p_stages[idx] then
                self.p_stages[idx] = QuestStageData:create()
            end
            self.p_stages[idx]:parseData(_data)
            self.p_stages[idx]:setIsLast(idx == len)

            if _data.wheelData then
                self:parseWheeldata(_data.wheelData)
            end
        end
    end
end

-- 章节只有一组轮盘数据
--message QuestWheel {
--      repeated ShopItem items = 1; //弃用 轮盘上显示的卡包
--    optional int32 hitIndex = 2; // 命中第几个奖励
--    repeated CommonRewards rewards = 3; // 轮盘上显示的卡包
--}
function QuestPhaseData:parseWheeldata(data)
    if data ~= nil and data.rewards and #data.rewards > 0 then
        self.p_wheel = {p_items = {}}
        self.p_wheel.hitIndex = data.hitIndex + 1
        for i = 1, #data.rewards do
            local rewards = CommonRewards:create()
            rewards:parseData(data.rewards[i], true)
            table.insert(self.p_wheel.p_items, rewards)
        end
        local idx = self.p_wheel.hitIndex
        local items = self.p_wheel.p_items
        if items and table.nums(items) > 0 and idx then
            self.p_items = {}
            table.insert(self.p_items, items[idx])
        end
    end
end

function QuestPhaseData:getWheelReward()
    if self.p_wheel then
        local items = self.p_wheel.p_items
        local idx = self.p_wheel.hitIndex
        if items and table.nums(items) > 0 and idx then
            return items[idx]
        end
    end
end

function QuestPhaseData:setIsLast(bl_last)
    self.bl_isLast = bl_last
end

function QuestPhaseData:getIsLast()
    return self.bl_isLast
end

function QuestPhaseData:isComplete()
    if not self.p_pickChips or not self.p_maxChips then
        return false
    end
    if self.p_pickChips >= self.p_maxChips then
        for idx, stage_data in pairs(self.p_stages) do
            if stage_data and stage_data:getState() == "REWARD" then
                return false
            end
        end
        return true
    end
end

function QuestPhaseData:isHasJackpotWheel()
    return not not self.m_hasJackpotWheel
end

function QuestPhaseData:parseJackpotWheeldata(data)
    if data then
        self.m_hasJackpotWheel = true
        self.p_jackpotWheel = QuestPhaseJackpotWheelData:create()
        self.p_jackpotWheel:parseData(data)
    end
end

function QuestPhaseData:getJackpotWheeldata()
    return self.m_hasJackpotWheel ,self.p_jackpotWheel
end
return QuestPhaseData
