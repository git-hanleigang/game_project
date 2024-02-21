local MulLuckyStampManager = class("MulLuckyStampManager")
function MulLuckyStampManager:getInstance()
    if MulLuckyStampManager.m_instance == nil then
        MulLuckyStampManager.m_instance = MulLuckyStampManager.new()
    end
    return MulLuckyStampManager.m_instance
end

function MulLuckyStampManager:ctor()
    self:registerObservers()
end

function MulLuckyStampManager:registerObservers()
end

function MulLuckyStampManager:getActivityData()
    -- return clone(G_GetActivityDataByRef(ACTIVITY_REF.MulLuckyStamp)) 
    return G_GetMgr(ACTIVITY_REF.MulLuckyStamp):getRunningData()
end

return MulLuckyStampManager
