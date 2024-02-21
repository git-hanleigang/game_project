local MiningManiaBonusCarSymbol = class("MiningManiaBonusCarSymbol",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"

MiningManiaBonusCarSymbol.m_animNode = nil
MiningManiaBonusCarSymbol.m_reward = nil
MiningManiaBonusCarSymbol.m_symbolType = nil
MiningManiaBonusCarSymbol.m_textReward = nil
MiningManiaBonusCarSymbol.m_recycleState = false

MiningManiaBonusCarSymbol.SYMBOL_SCORE_BONUS_NULL = 120 -- 空信号
MiningManiaBonusCarSymbol.SYMBOL_SCORE_BONUS_5 = 121    -- 绿色
MiningManiaBonusCarSymbol.SYMBOL_SCORE_BONUS_6 = 122    -- 蓝色
MiningManiaBonusCarSymbol.SYMBOL_SCORE_BONUS_7 = 123    -- 红色
MiningManiaBonusCarSymbol.SYMBOL_SCORE_BONUS_8 = 124    -- 黄色
MiningManiaBonusCarSymbol.SYMBOL_SCORE_BONUS_9 = 125    -- 闹钟

function MiningManiaBonusCarSymbol:initUI(_carMachine)
    self:createCsbNode("MiningMania_BonusCar.csb")
    self.m_carMachine = _carMachine
    self:runCsbAction("idleframe", true)
    self:reset()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function MiningManiaBonusCarSymbol:reset()
    self.m_symbolType = nil
    self.m_reward = nil
    self.m_textReward = nil
    if self.m_animNode then
        self.m_animNode:removeFromParent()
        self.m_animNode = nil
    end
end

function MiningManiaBonusCarSymbol:changeSymbolCcb(_symbolType, _reward)
    self.m_symbolType = _symbolType
    self.m_reward = _reward
    self:runCsbAction("idleframe", true)

    self:findChild("Node_lv"):setVisible(_symbolType == self.SYMBOL_SCORE_BONUS_5)
    self:findChild("Node_lan"):setVisible(_symbolType == self.SYMBOL_SCORE_BONUS_6)
    self:findChild("Node_hong"):setVisible(_symbolType == self.SYMBOL_SCORE_BONUS_7)
    self:findChild("Node_jin"):setVisible(_symbolType == self.SYMBOL_SCORE_BONUS_8)
    self:findChild("Node_timebuff"):setVisible(_symbolType == self.SYMBOL_SCORE_BONUS_9)

    if _symbolType == self.SYMBOL_SCORE_BONUS_5 then
        self.m_animNode = util_spineCreate("Socre_MiningMania_Bonus5",true,true)
        self:findChild("Node_spine_lv"):addChild(self.m_animNode)
        self.m_textReward = self:findChild("m_lb_num_lv")
    elseif _symbolType == self.SYMBOL_SCORE_BONUS_6 then
        self.m_animNode = util_spineCreate("Socre_MiningMania_Bonus6",true,true)
        self:findChild("Node_spine_lan"):addChild(self.m_animNode)
        self.m_textReward = self:findChild("m_lb_num_lan")
    elseif _symbolType == self.SYMBOL_SCORE_BONUS_7 then
        self.m_animNode = util_spineCreate("Socre_MiningMania_Bonus7",true,true)
        self:findChild("Node_spine_hong"):addChild(self.m_animNode)
        self.m_textReward = self:findChild("m_lb_num_hong")
    elseif _symbolType == self.SYMBOL_SCORE_BONUS_8 then
        self.m_animNode = util_spineCreate("Socre_MiningMania_Bonus8",true,true)
        self:findChild("Node_spine_jin"):addChild(self.m_animNode)
        self.m_textReward = self:findChild("m_lb_num_jin")
    elseif _symbolType == self.SYMBOL_SCORE_BONUS_9 then
        self.m_textReward = self:findChild("m_lb_num_time")
    end

    if self.m_animNode then
        util_spinePlay(self.m_animNode,"idleframe4",true)
    end

    self:setSpecialNodeMulBonus()
end

function MiningManiaBonusCarSymbol:onEnter()
    MiningManiaBonusCarSymbol.super.onEnter(self)
end

function MiningManiaBonusCarSymbol:onExit()
    MiningManiaBonusCarSymbol.super.onExit(self)
end

function MiningManiaBonusCarSymbol:runAnim(_isRun)
    self:setRecycleState(true)
    if _isRun then
        if self.m_symbolType ~= self.SYMBOL_SCORE_BONUS_8 and self.m_symbolType ~= self.SYMBOL_SCORE_BONUS_9 then
            gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_CollectNormal)
        end
        if self.m_symbolType == self.SYMBOL_SCORE_BONUS_8 then
            gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_CollectGreen)
        elseif self.m_symbolType == self.SYMBOL_SCORE_BONUS_9 then
            gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_CollectTime)
        end
        self:runCsbAction("actionframe", false, function()
            self.m_carMachine:pushRewardNodeToPool(self)
        end)
    else
        self:runCsbAction("over", false, function()
            self.m_carMachine:pushRewardNodeToPool(self)
        end)
    end
end

--设置bonus上的倍数
function MiningManiaBonusCarSymbol:setSpecialNodeMulBonus()
    if self.m_textReward then
        local sScore = ""
        if self:curIsBonusSpine(self.m_symbolType) then
            sScore = "X" .. self.m_reward
        elseif self.m_symbolType == self.SYMBOL_SCORE_BONUS_9 then
            local reward = math.round(self.m_reward)
            sScore = reward .. "S"
        end
        
        self.m_textReward:setString(sScore)
    end
end

function MiningManiaBonusCarSymbol:getNodeSpine()
    return self.m_animNode
end

function MiningManiaBonusCarSymbol:curIsBonusSpine(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_BONUS_5
        or _symbolType == self.SYMBOL_SCORE_BONUS_6
        or _symbolType == self.SYMBOL_SCORE_BONUS_7
        or _symbolType == self.SYMBOL_SCORE_BONUS_8 then
            return true
    end
    return false
end

-- 回收状态
-- 是否已经回收过(true:已经回收；false:还没有回收)
function MiningManiaBonusCarSymbol:setRecycleState(_state)
    self.m_recycleState = _state
end

function MiningManiaBonusCarSymbol:getRecycleState()
    return self.m_recycleState
end

return MiningManiaBonusCarSymbol
