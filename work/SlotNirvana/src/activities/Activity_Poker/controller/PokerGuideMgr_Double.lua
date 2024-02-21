--[[--
    引导
    每一期都有引导
    引导步骤：
    -- Double确认界面， 【无遮罩】（），                          【弱引导】（点击ok和cancel，结束当前步骤）
    -- Double主界面，   【有遮罩】（扑克高亮，有npc），             【弱引导】（点击任意区域，结束当前步骤）
    -- Double选花色，   【有遮罩】（两spine按钮，有npc），          【强引导】
    -- Double放弃，     【无遮罩】（），                          【弱引导】（点击放弃或者选择花色，结束当前步骤）
]]
local PokerGuideMgr = import(".PokerGuideMgr")
local PokerGuideMgr_Double = class("PokerGuideMgr_Double", PokerGuideMgr)

-- 子类重写
function PokerGuideMgr_Double:initCfg()
    -- 引导配置
    self.GUIDE_CFG = {
        {id = 1, key = "doublePoker", startRecord = nil, overRecord = 1, nextId = 2},
        {id = 2, key = "doubleChoose", startRecord = nil, overRecord = 2, preId = 1},
        {id = 3, key = "doubleGiveUp", startRecord = nil, overRecord = 3, preId = 2}
    }
end

-- 子类重写
function PokerGuideMgr_Double:getRefName()
    return ACTIVITY_REF.Poker
end

-- 子类重写
function PokerGuideMgr_Double:getClientCacheKey()
    return "DoubleGuide"
end

-- 子类重写 活动控制类实现showGuideLayer方法
function PokerGuideMgr_Double:createGuideLayer(_stepKey)
    return G_GetMgr(self:getRefName()):showGuideLayer(_stepKey, "double")
end

-- 可重复引导，步骤结束条件
function PokerGuideMgr_Double:getDynamicMax(_stepKey)
    return 0
end

-- 可重复引导，引导步骤计数
function PokerGuideMgr_Double:setDynamicData(_stepKey)
end

return PokerGuideMgr_Double
