--[[--
    装修引导
    每一期都有引导

    引导步骤：
    -- 大厅引导，       【有遮罩】（入口按钮高亮），                【弱引导】（点击任意区域引导结束，点击入口按钮引导结束并按钮生效）
    -- 台机按钮，        【有遮罩】（台机高亮），                   【强引导】（点击play）
    -- NPC说话，        【有遮罩】（npc高亮），                   【弱引导】（点击任意区域引导结束）
    -- DEAL按钮，       【有遮罩】（npc高亮，DEAL按钮高亮），       【强引导】
    -- 锁牌，           【有遮罩】（需要锁定的对应单张牌，一张一步）， 【强引导】， 【重复步骤？？？】
    -- DRAW按钮，       【有遮罩】（npc高亮，DRAW按钮高亮），       【强引导】
    -- paytable，       【有遮罩】（paytable，npc），            【弱引导】（点击任意区域进行下一步）
    -- 标题，           【有遮罩】（标题，npc），                 【弱引导】（点击任意区域进行下一步）
]]
local PokerGuideMgr = import(".PokerGuideMgr")
local PokerGuideMgr_Main = class("PokerGuideMgr_Main", PokerGuideMgr)

-- 子类重写
function PokerGuideMgr_Main:initCfg()
    -- 引导配置
    self.GUIDE_CFG = {
        -- {id = 1, key = "lobby", startRecord = nil, overRecord = 1},
        {id = 1, key = "machine", startRecord = nil, overRecord = 1},
        {id = 2, key = "info", startRecord = nil, overRecord = 2, nextId = 3},
        {id = 3, key = "deal", startRecord = nil, overRecord = 3, preId = 2},
        {id = 4, key = "hold", startRecord = nil, overRecord = nil, preId = 3},
        {id = 5, key = "draw", startRecord = nil, overRecord = 5, preId = 4},
        {id = 6, key = "payTable", startRecord = nil, overRecord = 6, preId = 5},
        {id = 7, key = "title", startRecord = nil, overRecord = 7, preId = 6, nextId = 8},
        {id = 8, key = "autoHold", startRecord = 8, overRecord = nil, preId = 7}
    }
end

-- 子类重写
function PokerGuideMgr_Main:getRefName()
    return ACTIVITY_REF.Poker
end

-- 子类重写
function PokerGuideMgr_Main:getClientCacheKey()
    return "ActivityGuide"
end

-- 子类重写 活动控制类实现showGuideLayer方法
function PokerGuideMgr_Main:createGuideLayer(_stepKey)
    return G_GetMgr(self:getRefName()):showGuideLayer(_stepKey, "main")
end

-- 子类重写 可重复引导，步骤结束条件
function PokerGuideMgr_Main:getDynamicMax(_stepKey)
    local refName = self:getRefName()
    local pDetailData = G_GetMgr(refName):getPokerDetail()
    if pDetailData then
        if _stepKey == "hold" then
            local holdsData = pDetailData:getGuideSuggestHold()
            if holdsData then
                return #holdsData
            end
        end
    end
    return 0
end

-- 子类重写 可重复引导，引导步骤计数
function PokerGuideMgr_Main:setDynamicData(_stepKey)
    local cfgGuide = self:getGuideConfig(_stepKey)
    if cfgGuide.dynamic then
        if cfgGuide.dynamic.max == 0 then
            local dMax = self:getDynamicMax(_stepKey) or 0
            cfgGuide.dynamic.max = dMax
        end
        cfgGuide.dynamic.cur = (cfgGuide.dynamic.cur or 0) + 1
    end
end

return PokerGuideMgr_Main
