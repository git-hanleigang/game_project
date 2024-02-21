--[[
]]

GD.BetBubblesCfg = {}

-- 刷新
ViewEventType.NOTIFY_BETBUBBLE_REFRESH = "NOTIFY_BETBUBBLE_REFRESH"

-- 宽度
BetBubblesCfg.BG_W = 250 

-- 最多显示5个气泡
BetBubblesCfg.LIMIT_MAX_H = 4
BetBubblesCfg.LIMIT_MAX_V = 6

BetBubblesCfg.ZORDER_TYPE = {
    UP = "UP", -- 从上往下排序
    DOWN = "DOWN", -- 从下往上排序
}

-- 活动或者功能的开关
BetBubblesCfg.REF_SWITCH = {
    ON = "ON",
    OFF = "OFF",
}


--[[--
    ================================
    ============模块在这里============
    ================================
    如果一个模块包含多个系统或者功能 或者有独特的要求（比如限高）时，则需要配置模块
    如果系统或者功能不在配置的所有模块内，则自己是一个模块
    模块配置，模块与模块之间有横线分割
]]
BetBubblesCfg.modules = {
    [1] = {
        name = "BetExtraCosts",
        moduleLua = "GameModule/BetBubbles/view/modules/BetExtraCostsModule",
        refs = {
            ACTIVITY_REF.Minz,
            ACTIVITY_REF.FlamingoJackpot,
            ACTIVITY_REF.DiyFeature,
        },
        isLimitMaxH = false, -- 是否限制最大高度
    },
    [2] = {
        name = "CardBetTip",
        moduleLua = "views/gameviews/CardBetChipNodeNew",
    }
}

-- ================================
-- ============配置在这里============
-- ================================
-- 越往下位置越低，从上往下排序，越往下优先级越低
-- 满足条件就一定全显示
local TopTips = {
    "BetExtraCosts", -- gamebet 
}

-- ================================
-- ============配置在这里============
-- ================================
-- 越往下位置越低，从下往上反向排序，越往下优先级越高
local BottomTips = {
    "CardBetTip", -- 集卡
    ACTIVITY_REF.CommonJackpot, -- 公共jackpot
    ACTIVITY_REF.BalloonRush, -- 彩虹
    ACTIVITY_REF.FrostFlameClash, -- 1v1
    ACTIVITY_REF.MegaWinParty, -- 大赢宝箱
}

BetBubblesCfg.Top_ZOrders = {}
for key, value in pairs(TopTips) do
    BetBubblesCfg.Top_ZOrders[value] = key
end
BetBubblesCfg.Bottom_ZOrders = {}
for key, value in ipairs(BottomTips) do
    BetBubblesCfg.Bottom_ZOrders[value] = key
end