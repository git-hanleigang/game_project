--[[
    金色奖励的任务数据
]]

local HolidayTaskData = class("HolidayTaskData")

-- message HolidayNewChallengeGoldGoods {
--     optional bool unlocked = 1;//是否解锁
--     optional string description = 2;//气泡描述
--     optional string unlockParams = 3; // 解锁参数
--     optional string curPayment = 4; // 当前进度
--   }

function HolidayTaskData:ctor()
    self.p_complete = false
end

function HolidayTaskData:parseData(_data)
    -- if not self.p_unlocked and _data.unlocked then
    --     self.p_complete = true
    -- elseif  self.p_complete then
    --     self.p_complete = false
    -- end
    self.p_unlocked         = _data.unlocked         --是否解锁                   
    self.p_description      = _data.description      --气泡描述
    self.p_unlockParams     = _data.unlockParams     --解锁参数                   
    self.p_curPayment       = _data.curPayment       --当前进度
end

-- 是否解锁
function HolidayTaskData:isUnlocked()
    return self.p_unlocked
end

function HolidayTaskData:setUnlocked(val)
    self.p_unlocked = val
end

--总进度
function HolidayTaskData:getUnlockParams()
    return tonumber(self.p_unlockParams)
end

--当前进度
function HolidayTaskData:getCurPayment()
    return tonumber(self.p_curPayment)
end

function HolidayTaskData:getDescription()
    return self.p_description
end

-- 是否刚刚完成
function HolidayTaskData:isComplete()
    return self.p_complete
end

function HolidayTaskData:setComplete(val)
    self.p_complete = val
end

return HolidayTaskData