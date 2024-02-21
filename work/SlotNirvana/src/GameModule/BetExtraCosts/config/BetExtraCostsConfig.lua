--[[
]]
_G.BetExtraCostsConfig = {}


-- 开关
BetExtraCostsConfig.isEffective = true

-- 新增功能或者活动的引用名
BetExtraCostsConfig.ExtraRefs = {
    ACTIVITY_REF.Minz,
    ACTIVITY_REF.FlamingoJackpot,
    ACTIVITY_REF.DiyFeature,
}

-- 关联活动的开关变化时发送的消息
ViewEventType.NOTIFI_BET_EXTRA_COST_SWITCH = "NOTIFI_BET_EXTRA_COST_SWITCH"