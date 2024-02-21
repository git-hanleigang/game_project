--[[
    des:luckyspin 掉落金卡活动 数据接收
    author:{author}
    time:2019-12-25 18:47:12
]]

local LuckySpinAppointCardData = class("LuckySpinAppointCardData")

LuckySpinAppointCardData.p_activityId = nil
LuckySpinAppointCardData.p_activityName = nil
LuckySpinAppointCardData.p_expireAt = nil
LuckySpinAppointCardData.p_expire = nil
LuckySpinAppointCardData.p_isExist = nil

function LuckySpinAppointCardData:ctor()
    self.p_isExist = false
end

function LuckySpinAppointCardData:parseData( data )
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)
    self.p_expire = tonumber(data.expire)
    self.p_isExist = true
    self:setCurrentPhase()
    self:getLeftTimeStr()
end

function LuckySpinAppointCardData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function LuckySpinAppointCardData:isExist()
    if self.p_expire and self.p_expire >0 then
        return true
    end
    return false
end

-- 特殊处理：根据活动id判断是活动第几期（活动id，不能太随意）
-- self.p_activityId = "LSA1001"
function LuckySpinAppointCardData:setCurrentPhase()
    self.m_phase = tonumber(string.sub(self.p_activityId, -2))
end

function LuckySpinAppointCardData:getCurrentPhase()
    return self.m_phase
end

return LuckySpinAppointCardData