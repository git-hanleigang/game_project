--[[
    盖戳队列，嵌套
]]
local LuckyStampQueue = class("LuckyStampQueue")

function LuckyStampQueue:ctor()
    self.m_overFunc = nil
end

-- 本次盖戳的回调
function LuckyStampQueue:setOverFunc(_over)
    self.m_overFunc = _over
end

function LuckyStampQueue:doOverFunc()
    print("LuckyStamp Queue:doOverFunc")
    if self.m_overFunc then
        self.m_overFunc()
    end
end

function LuckyStampQueue:initPopList()
    self.m_popList = {}
    table.insert(self.m_popList, handler(self, self.triggerLuckyStampCard))
    table.insert(self.m_popList, handler(self, self.triggerHolidayChallenge))
end

function LuckyStampQueue:doExitNextPop()
    print("LuckyStamp Queue:doExitNextPop", #self.m_popList)
    if self.m_popList and #self.m_popList == 0 then
        self:doOverFunc()
        return
    end
    local func = table.remove(self.m_popList, 1)
    local function callback()
        self:doExitNextPop()
    end
    func(callback)
end

-- 弹出盖戳额外送卡活动界面
function LuckyStampQueue:triggerLuckyStampCard(_over)
    print("LuckyStamp Queue:triggerLuckyStampCard")
    local function callFunc()
        if _over then
            _over()
        end
    end
    if G_GetMgr(ACTIVITY_REF.LuckyStampCard):isActive() then
        local view = G_GetMgr(ACTIVITY_REF.LuckyStampCard):showMainLayer(callFunc)
        if not view then
            callFunc()
        end
    else
        callFunc()
    end
end

-- 聚合挑战 圣诞树
function LuckyStampQueue:triggerHolidayChallenge(_over)
    print("LuckyStamp Queue:triggerHolidayChallenge")
    local function callFunc()
        if _over then
            _over()
        end
    end
    if G_GetMgr(G_REF.LuckyStamp):getHolidayChallenge() then
        G_GetMgr(G_REF.LuckyStamp):setHolidayChallenge(false)
        if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompleted() then
            local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.LUCKYSTAMP
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):chooseCreatePopLayer(taskType, callFunc)
        else
            callFunc()
        end
    else
        callFunc()
    end
end

return LuckyStampQueue
