--[[
    圣诞聚合 -- pass
]]
local HolidayRewardData = require("activities.Activity_HolidayNewChallenge.HolidayPass.model.HolidayRewardData")
local HolidayPointData = class("HolidayPointData")
--[[
    message HolidayNewChallengePassPoint {
        optional int32 progress = 1;// 进度
        optional HolidayNewChallengePassReward payReward = 2;// 付费奖励
        optional HolidayNewChallengePassReward freeReward = 3;// 免费奖励
        optional int32 seq = 4; // 奖励序号
    }
]]
function HolidayPointData:parseData(_data, _curProgress, _unlocked)
    self.p_progress = tonumber(_data.progress)
    self.p_seq = tonumber(_data.seq)
    if not self.p_payReward then
        self.p_payReward = HolidayRewardData:create()
    end
    self.p_payReward:parseData(_data.payReward, self.p_progress, _curProgress, _unlocked)

    if not self.p_freeReward then
        self.p_freeReward = HolidayRewardData:create()
    end
    self.p_freeReward:parseData(_data.freeReward, self.p_progress, _curProgress, true)

    self.p_curProgress = _curProgress
    self.p_unlocked = _unlocked
end

function HolidayPointData:getProgress()
    return self.p_progress or 0
end

function HolidayPointData:getSeq()
    return self.p_seq
end

function HolidayPointData:getPayReward()
    return self.p_payReward or {}
end

function HolidayPointData:getFreeReward()
    return self.p_freeReward or {}
end

function HolidayPointData:setCurProgress(_progress)
    self.p_curProgress = _progress
    self.p_payReward:setCurProgress(_progress)
    self.p_freeReward:setCurProgress(_progress)
end

function HolidayPointData:getCurProgress()
    return self.p_curProgress or 0
end

function HolidayPointData:getIsPay()
    return self.p_unlocked
end

function HolidayPointData:hasPassCompleteReward()
    if self.p_curProgress >= self.p_progress then
        local freeReward = self:getFreeReward()
        if freeReward:getCollected() then
            if self:getIsPay() then
                local payReward = self:getPayReward()
                if payReward:getCollected() then
                    return false
                end
            end
        end
        return true
    end
    return false
end

return HolidayPointData
