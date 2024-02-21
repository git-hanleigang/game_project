
--fixios0223
local WarriorAliceSlotNode = class("WarriorAliceSlotNode",require("Levels.SlotsNode"))

--添加拖尾
function WarriorAliceSlotNode:addTrailing(parentNode,falseParticleTbl)
    if self.p_symbolType == 94 then
        if tolua.isnull(self.m_trailingNode) then
            self.m_trailingNode = util_createAnimation("WarriorAlice_Bonus_tuowei.csb")
            parentNode:addChild(self.m_trailingNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 99)
            falseParticleTbl[#falseParticleTbl+1] = self.m_trailingNode
        end
        -- if self.m_isLastSymbol ~= true and self.m_trailingNode == nil then
        --     self.m_trailingNode = util_createAnimation("WarriorAlice_Bonus_tuowei.csb")
        --     parentNode:addChild(self.m_trailingNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 99)
        -- end
    end
end

--更新图标坐标
function WarriorAliceSlotNode:updateDistance(distance)
    WarriorAliceSlotNode.super.updateDistance(self,distance)
    if not tolua.isnull(self.m_trailingNode) then
        self.m_trailingNode:setPosition(cc.p(self:getPosition()))
    end
end

function WarriorAliceSlotNode:removeBonusBg()
    if not tolua.isnull(self.m_trailingNode) then
        self.m_trailingNode:removeFromParent()
        self.m_trailingNode = nil
    end
    

end

-- 还原到初始被创建的状态
function WarriorAliceSlotNode:reset()

    self.p_idleIsLoop = false
    self.p_preParent = nil 
    self.p_preX = nil  
    self.p_preY = nil
    self.p_slotNodeH = 0

    self:setVisible(true)
    self.m_reelTargetX = nil
    self.m_reelTargetY = nil
    self.m_isLastSymbol = nil
--    self.p_maxRowIndex = nil
    self.m_lineMatrixPos = nil
    self.m_imageName = nil
    self.m_lineAnimName = nil
    self.m_idleAnimName = nil
    self.m_bInLine = true
    self.m_callBackFun = nil
    self.m_bRunEndTarge = false 
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    
    self:setScale(1)
    self:setOpacity(255)
    self:setRotation(0)

    if self.m_trailingNode then
        self:removeBonusBg()
    end

    if self.trailingNode then
        self.trailingNode:stopAllActions()
        self.trailingNode:removeFromParent()
        self.trailingNode = nil
    end

    if self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(true)
    end
    self:setScale(1)
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:removeFromParent(false)
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,self.p_symbolType)
        end
    end
    

    self.p_symbolType = nil
    self.p_idleIsLoop = false
    
    self.m_currAnimName = nil
    self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnimaTimes = nil
    -- 清空掉当前的actions
    if self.m_actionDatas ~= nil then
        
        table_clear(self.m_actionDatas)
    end

    self:hideBigSymbolClip()
end

return WarriorAliceSlotNode