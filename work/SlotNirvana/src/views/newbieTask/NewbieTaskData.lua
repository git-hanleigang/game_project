local NewbieTaskData = class("NewbieTaskData")
NewbieTaskData.p_id = nil --任务名称
NewbieTaskData.p_description = nil --任务描述
NewbieTaskData.p_targetType = nil --任务目标类型
NewbieTaskData.p_targetValue = nil --根据类型获取目标值
NewbieTaskData.p_targetLevel = nil --指定关卡
NewbieTaskData.p_targetMul = nil --指定倍数条件
NewbieTaskData.p_rewardCoins = nil --奖金

NewbieTaskData.m_rewardStatus = nil --领取状态
NewbieTaskData.m_currentValue = nil --当前任务进度
NewbieTaskData.m_maxValue = nil --根据类型获取目标值
NewbieTaskData.m_startLevel = nil --任务开启时的等级

--奖励领取状态0未完成 1已完成未领取 2已领取
local reward_Type ={
    reward_Type_Not=0,
    reward_Type_Unclaimed=1,
    reward_Type_Complete = 2
}

function NewbieTaskData:ctor()
    self.m_rewardStatus = reward_Type.reward_Type_Not
    self.m_currentValue = 0
end

--解析任务数据
function NewbieTaskData:parseData(data)
    self.p_id = tonumber(data[1])
    self.p_description = util_string_split(data[2],";")
    self.p_targetType = data[3]
    self.p_targetValue = tonumber(data[4])
    self.p_targetLevel= data[5]
    self.p_targetMul= tonumber(data[6])
    self.p_rewardCoins = tonumber(data[7])
    if globalData.constantData.NEWBIE_TASK_COINS then
        self.p_rewardCoins = globalData.constantData.NEWBIE_TASK_COINS[self.p_targetType] or tonumber(data[7])
    end
    self.m_maxValue = self.p_targetValue
end

function NewbieTaskData:readServerData()
    local data = globalNewbieTaskManager:getServerData(self.p_id)
    if not data then
        self:changeServerData()
        return
    end
    self.m_rewardStatus = tonumber(data.status)
    self.m_currentValue = tonumber(data.value)
    self.m_startLevel = tonumber(data.level) or globalData.userRunData.levelNum
    if self.p_targetType == NewbieTaskType.reach_level then
        self.m_currentValue = math.max(globalData.userRunData.levelNum-self.m_startLevel,0)
        self.m_maxValue = self.p_targetValue-self.m_startLevel
    end
end

function NewbieTaskData:changeServerData()
    local data = globalNewbieTaskManager:getServerData(self.p_id)
    if data then
        data.status = self.m_rewardStatus
        data.value = self.m_currentValue
        data.level = self.m_startLevel
    else
        self.m_startLevel = globalData.userRunData.levelNum
        local serverData = {}
        serverData.status = self.m_rewardStatus
        serverData.value = self.m_currentValue
        serverData.level = self.m_startLevel
        if self.p_targetType == NewbieTaskType.reach_level then
            self.m_maxValue = self.p_targetValue-self.m_startLevel
            self.m_currentValue = math.max(globalData.userRunData.levelNum-self.m_startLevel,0)
            if self.m_currentValue>=self.m_maxValue then
                self.m_currentValue = self.m_maxValue
                self.m_rewardStatus = reward_Type.reward_Type_Unclaimed
            end
            globalNewbieTaskManager:setServerData(self.p_id,serverData)
        else
            globalNewbieTaskManager:setServerData(self.p_id,serverData)
        end
    end
end

--获得进度
function NewbieTaskData:getPercent()
    if self.m_maxValue == 0 then
        return 100
    end
    local percent = math.ceil(self.m_currentValue/self.m_maxValue * 100)
    return percent
end

function NewbieTaskData:checkIncrease(type,pool,levelName,awardValue)
    if self.m_rewardStatus == reward_Type.reward_Type_Not then
        --判断任务目标类型是否符合
        if not type or type~=self.p_targetType then
            return false
        end

        --判断是否制定了特殊关卡
        if self.p_targetLevel and self.p_targetLevel~="" then
            if not levelName or levelName~=self.p_targetLevel then
                return false
            end
        end

        --判断是否制定了特殊倍数
        if self.p_targetMul then
            if not awardValue or awardValue<self.p_targetMul then
                return false
            end
        end
        return true
    end
    return false
end
--基础目标增加
function NewbieTaskData:increasePool(type,pool,levelName,awardValue)
    if self:checkIncrease(type,pool,levelName,awardValue) then
        --增加进度
        self.m_currentValue = self.m_currentValue + pool
        if self.m_currentValue>=self.m_maxValue then
            self.m_currentValue = self.m_maxValue
            self.m_rewardStatus = reward_Type.reward_Type_Unclaimed
        end
        self:changeServerData()
        globalNewbieTaskManager:upLoadTaskData()
    end
end

--是否待领取
function NewbieTaskData:checkUnclaimed()
    if self.m_rewardStatus == reward_Type.reward_Type_Unclaimed then
        return true
    end
    if self.p_targetType == NewbieTaskType.reach_level then
        if globalData.userRunData.levelNum>=self.p_targetValue then
            self.m_currentValue = self.m_maxValue
            self.m_rewardStatus = reward_Type.reward_Type_Unclaimed
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_UPDATE,self:getPercent())
            return true
        end
    end 
    return false
end

--奖金
function NewbieTaskData:getRewardCoins()
    return self.p_rewardCoins
end

--结束任务
function NewbieTaskData:doComplete()
    self.m_rewardStatus = reward_Type.reward_Type_Complete
    self:changeServerData()
    if self.p_id == 1 then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskFinish1)
    elseif self.p_id == 2 then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskFinish2)
    elseif self.p_id == 3 then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskFinish3)
    end
end



return NewbieTaskData