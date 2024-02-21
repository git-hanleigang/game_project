--[[
]]
local ReturnPopupInfo = import(".ReturnPopupInfo")
local ReturnPassPriceData = import(".ReturnPassPriceData")
local ReturnPassPointData = import(".ReturnPassPointData")
local ReturnTaskData = import(".ReturnTaskData")
local ReturnSignData = import(".ReturnSignData")
local ReturnWheelData = import(".ReturnWheelData")

local BaseGameModel = require("GameBase.BaseGameModel")
local ReturnData = class("ReturnData", BaseGameModel)
function ReturnData:ctor()
    ReturnData.super.ctor(self)
    self:setRefName(G_REF.Return)
end

-- 换皮时需主动更改这个名字，暂时无法通过配置来换皮
function ReturnData:getThemeName()
    --return "Return"
    return "Return_Fourth"
end

-- message ReturnSignV2 {
--     optional string begin = 1;
--     repeated ReturnSignDayV2 days = 2;
--     optional int32 day = 3;
--     optional int64 nextExpireAt = 4;  // 下一个奖励领取时间
--     optional int64 expireAt = 5; // 签到到期
--     repeated ReturnSignTask spinTasks = 6;
--     repeated ReturnSignTask questTasks = 7;
--     repeated ReturnSignTask loginTasks = 8;
--     optional bool unlocked = 9;
--     optional ReturnSignPay unlockPrice = 10;
--     repeated PassPointData freePoints = 11;
--     repeated PassPointData payPoints = 12;
--     optional ReturnPopupInfo popupInfo = 13;
--     optional int32 exp = 14;
--     optional bool activeExtra = 15;
--   }
function ReturnData:parseData(_netData)
    ReturnData.super.parseData(self, _netData)

    self.p_begin = _netData.begin
    self.p_days = {}
    if _netData.days and #_netData.days > 0 then
        for i = 1, #_netData.days do
            local day = ReturnSignData:create()
            day:parseData(_netData.days[i], _netData.day)
            table.insert(self.p_days, day)
        end
    end

    self.p_day = _netData.day
    self.p_nextExpireAt = tonumber(_netData.nextExpireAt)
    self.p_expireAt = tonumber(_netData.expireAt)

    self.p_spinTasks = {}
    if _netData.spinTasks and #_netData.spinTasks > 0 then
        for i = 1, #_netData.spinTasks do
            local task = ReturnTaskData:create()
            task:parseData(_netData.spinTasks[i], i)
            table.insert(self.p_spinTasks, task)
        end
    end
    self:resortTable(self.p_spinTasks)
    self.p_questTasks = {}
    if _netData.questTasks and #_netData.questTasks > 0 then
        for i = 1, #_netData.questTasks do
            local task = ReturnTaskData:create()
            task:parseData(_netData.questTasks[i], i)
            table.insert(self.p_questTasks, task)
        end
    end
    self:resortTable(self.p_questTasks)
    self.p_loginTasks = {}
    if _netData.loginTasks and #_netData.loginTasks > 0 then
        for i = 1, #_netData.loginTasks do
            local task = ReturnTaskData:create()
            task:parseData(_netData.loginTasks[i], i)
            table.insert(self.p_loginTasks, task)
        end
    end
    self:resortTable(self.p_loginTasks)

    self.p_passUnlocked = _netData.unlocked
    self.p_passUnlockPrice = nil
    if _netData.unlockPrice and _netData.unlockPrice.price ~= nil and _netData.unlockPrice.price ~= "" then
        self.p_passUnlockPrice = ReturnPassPriceData:create()
        self.p_passUnlockPrice:parseData(_netData.unlockPrice)
    end

    self.p_freePoints = {}
    if _netData.freePoints and #_netData.freePoints > 0 then
        for i = 1, #_netData.freePoints do
            local point = ReturnPassPointData:create()
            point:parseData(_netData.freePoints[i], _netData.exp, true)
            table.insert(self.p_freePoints, point)
        end
    end

    self.p_payPoints = {}
    if _netData.payPoints and #_netData.payPoints > 0 then
        for i = 1, #_netData.payPoints do
            local point = ReturnPassPointData:create()
            point:parseData(_netData.payPoints[i], _netData.exp, _netData.unlocked)
            table.insert(self.p_payPoints, point)
        end
    end

    self.p_letterInfo = nil
    if _netData.popupInfo then
        self.p_letterInfo = ReturnPopupInfo:create()
        self.p_letterInfo:parseData(_netData.popupInfo)
    end

    self.p_curPoint = _netData.exp

    local point = self.p_freePoints[#self.p_freePoints]
    self.m_maxPoint = point:getPoint()

    self.p_activeExtra = _netData.activeExtra -- 激活了付费后双倍签到

    -- wheel
    local hasWheelData = false
    if _netData.HasField then
        hasWheelData = _netData:HasField("backWheel")
    elseif _netData.backWheel then
        hasWheelData = true
    end
    if hasWheelData then
        if not self.p_wheelData then
            self.p_wheelData = ReturnWheelData:create()
        end
        self.p_wheelData:parseData(_netData.backWheel)
    end

    self:initPassData()
    -- self:initTaskData()

    self:initPointList()


    self.m_curLevel = self:initPassCurLevelIndex()

    self:startUpdate()
end

-- 组合pass数据
function ReturnData:initPassData()
    self.m_passData = {}
    if self.p_freePoints and #self.p_freePoints > 0 then
        for i = 1, #self.p_freePoints do
            local info = {
                freePoints = self.p_freePoints[i],
                payPoints = self.p_payPoints[i]
            }
            table.insert(self.m_passData, info)
        end
    end
end

-- function ReturnData:initTaskData()
--     self.m_taskData = {
--         [1] = self.p_spinTasks,
--         [2] = self.p_questTasks,
--         [3] = self.p_loginTasks,
--     }
-- end

-- 组合分数的数组
function ReturnData:initPointList()
    self.m_pointList = {}
    if self.p_freePoints and #self.p_freePoints > 0 then
        for i = 1, #self.p_freePoints do
            table.insert(self.m_pointList, self.p_freePoints[i]:getPoint())
        end
    end
end

-- message ReturnTaskResult {
--     repeated ReturnSignTask spinTasks = 1;
--     repeated ReturnSignTask questTasks = 2;
--     repeated ReturnSignTask loginTasks = 3;
--   }
-- spin触发的数据刷新
function ReturnData:refreshTaskData(_netData)
    self.p_spinTasks = {}
    if _netData.spinTasks and #_netData.spinTasks > 0 then
        for i = 1, #_netData.spinTasks do
            local task = ReturnTaskData:create()
            task:parseData(_netData.spinTasks[i], i)
            table.insert(self.p_spinTasks, task)
        end
    end
    self:resortTable(self.p_spinTasks)
    self.p_questTasks = {}
    if _netData.questTasks and #_netData.questTasks > 0 then
        for i = 1, #_netData.questTasks do
            local task = ReturnTaskData:create()
            task:parseData(_netData.questTasks[i], i)
            table.insert(self.p_questTasks, task)
        end
    end
    self:resortTable(self.p_questTasks)
    self.p_loginTasks = {}
    if _netData.loginTasks and #_netData.loginTasks > 0 then
        for i = 1, #_netData.loginTasks do
            local task = ReturnTaskData:create()
            task:parseData(_netData.loginTasks[i], i)
            table.insert(self.p_loginTasks, task)
        end
    end
    self:resortTable(self.p_loginTasks)
end

function ReturnData:refreshQuestTaskData(_netData)
    self.p_questTasks = {}
    if _netData.returnQuestTask and #_netData.returnQuestTask > 0 then
        for i = 1, #_netData.returnQuestTask do
            local task = ReturnTaskData:create()
            task:parseData(_netData.returnQuestTask[i], i)
            table.insert(self.p_questTasks, task)
        end
    end
    self:resortTable(self.p_questTasks)    
end

function ReturnData:resortTable(_taskDatas)
    local function sortFunc(a, b)
        local priorityA = a:isCollected() == true and 2 or 1
        local priorityB = b:isCollected() == true and 2 or 1
        local indexA = a:getServerIndex()
        local indexB = b:getServerIndex()
        if priorityA == priorityB then
            return indexA < indexB
        else
            return priorityA < priorityB
        end
    end
    table.sort(_taskDatas, sortFunc)
end

-- 付费后触发的签到奖励变化
function ReturnData:refreshDaysData(_netData)
    self.p_days = {}
    if _netData.days and #_netData.days > 0 then
        for i = 1, #_netData.days do
            local day = ReturnSignData:create()
            day:parseData(_netData.days[i], self.p_day)
            table.insert(self.p_days, day)
        end
    end
end

-- function ReturnData:onRegister() -- 弃用了
-- end

function ReturnData:getExpireAt()
    return self.p_expireAt / 1000
end

function ReturnData:getSpinTasks()
    return self.p_spinTasks
end

-- 重新排序后用serverIndex来索引
function ReturnData:getSpinTaskByIndex(_index)
    local tasks = self.p_spinTasks
    if tasks and #tasks > 0 then
        for i=1,#tasks do
            local taskData = tasks[i]
            if taskData:getServerIndex() == _index then
                return taskData
            end
        end
    end
    return nil
end

function ReturnData:getQuestTasks()
    return self.p_questTasks
end

-- 重新排序后用serverIndex来索引
function ReturnData:getQuestTaskByIndex(_index)
    local tasks = self.p_questTasks
    if tasks and #tasks > 0 then
        for i=1,#tasks do
            local taskData = tasks[i]
            if taskData:getServerIndex() == _index then
                return taskData
            end
        end
    end
    return nil
end

function ReturnData:getLoginTasks()
    return self.p_loginTasks
end

-- 重新排序后用serverIndex来索引
function ReturnData:getLoginTaskByIndex(_index)
    local tasks = self.p_loginTasks
    if tasks and #tasks > 0 then
        for i=1,#tasks do
            local taskData = tasks[i]
            if taskData:getServerIndex() == _index then
                return taskData
            end
        end
    end
    return nil
end

function ReturnData:getSignDayData()
    return self.p_days
end

function ReturnData:getSignToday()
    return self.p_day
end

function ReturnData:setPassUnlocked(_isUnlocked)
    self.p_passUnlocked = _isUnlocked

    -- 同步解锁数据
    if self.p_freePoints and #self.p_freePoints > 0 then
        for i = 1, #self.p_freePoints do
            self.p_freePoints[i]:setUnlocked(_isUnlocked)
        end
    end
    if self.p_payPoints and #self.p_payPoints > 0 then
        for i = 1, #self.p_payPoints do
            self.p_payPoints[i]:setUnlocked(_isUnlocked)
        end
    end
end

function ReturnData:isPassUnlocked()
    return self.p_passUnlocked
end

function ReturnData:getPassUnlockPrice()
    return self.p_passUnlockPrice
end

function ReturnData:getPassFreePoints()
    return self.p_freePoints
end

function ReturnData:getPassPayPoints()
    return self.p_payPoints
end

function ReturnData:getPassData()
    return self.m_passData
end

function ReturnData:getPointList()
    return self.m_pointList
end

function ReturnData:getPassCurPoint()
    return self.p_curPoint
end

function ReturnData:getPassMaxPoint()
    return self.m_maxPoint
end

function ReturnData:getLetterInfo()
    return self.p_letterInfo
end

function ReturnData:isActiveExtra()
    return self.p_activeExtra
end

function ReturnData:getWheelData()
    return self.p_wheelData
end

-- 优化删除了翻倍的功能
-- function ReturnData:setActiveExtra(_isActive)
--     self.p_activeExtra = _isActive
-- end

function ReturnData:initPassCurLevelIndex()
    if self.m_pointList and #self.m_pointList > 0 then
        for i = 1, #self.m_pointList do
            local point = self.m_pointList[i]
            if self.p_curPoint <= point then
                return i
            end
        end
    end
end

function ReturnData:getPassCurLevelIndex()
    return self.m_curLevel
end

function ReturnData:getSignDataByIndex(_index)
    if _index and _index > 0 and self.p_days and #self.p_days > 0 then
        return self.p_days[_index]
    end
    return nil
end

function ReturnData:getSignTodayData()
    return self:getSignDataByIndex(self.p_day)
end

function ReturnData:isSignTodayCollected()
    local todayData = self:getSignTodayData()
    if todayData and todayData:isCollected() then
        return true
    end
    return false
end

-- 达成但未领取的
function ReturnData:getPassCompletePoints()
    local points = {}
    local nums = table.nums(self.p_freePoints)
    for i = 1, nums do
        local free = self.p_freePoints[i]
        if self.p_curPoint >= free:getPoint() and not free:isCollected() then
            table.insert(points, free)
        end
        if self.p_passUnlocked then
            local pay = self.p_payPoints[i]
            if self.p_curPoint >= pay:getPoint() and not pay:isCollected() then
                table.insert(points, pay)
            end
        end
    end
    return points
end

function ReturnData:hasPassCompleteReward()
    local completePoints = self:getPassCompletePoints()
    if completePoints and #completePoints > 0 then
        return true
    end
    return false
end

function ReturnData:getQuestTaskComplete()
    local indexs = {}
    local nums = table.nums(self.p_questTasks)
    if nums > 0 then
        for i = 1, nums do
            local taskData = self.p_questTasks[i]
            if taskData:isCollected() == false and taskData:isCompleted() == true then
                table.insert(indexs, taskData:getServerIndex())
            end
        end
    end
    return indexs
end

function ReturnData:getSpinTaskComplete()
    local indexs = {}
    local nums = table.nums(self.p_spinTasks)
    if nums > 0 then
        for i = 1, nums do
            local taskData = self.p_spinTasks[i]
            if taskData:isCollected() == false and taskData:isCompleted() == true then
                table.insert(indexs, taskData:getServerIndex())
            end
        end
    end
    return indexs
end

--停止刷帧
function ReturnData:stopUpdate()
    if self.m_expireALLHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireALLHandlerId)
        self.m_expireALLHandlerId = nil
    end
end

--开启刷帧
function ReturnData:startUpdate()
    self.m_isRunning = true
    self:stopUpdate()

    self.m_expireALLHandlerId =
        scheduler.scheduleGlobal(
            function()
                local overTime = util_getLeftTime(self.p_expireAt)
                if overTime <= 0 then
                    self:stopUpdate()
                    self.m_isRunning = false
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_TIMEOUT)
                    return
                end
            end,
            1
        )
end

function ReturnData:isRunning()
    return self.m_isRunning
end

return ReturnData