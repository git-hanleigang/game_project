---
--xcyy
--2018年5月23日
--FarmSlotsNode.lua

local FarmSlotsNode = class("FarmSlotsNode",util_require("Levels.SlotsNode"))

FarmSlotsNode.m_Corn = nil

function FarmSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

---
-- 还原到初始被创建的状态
function FarmSlotsNode:reset(removeFlag)



    if self.m_Corn then
        self.m_Corn:stopAllActions()
        self.m_Corn:removeFromParent()
        self.m_Corn = nil
    end  

    self.p_idleIsLoop = true
    self.p_preParent = nil 
    self.p_preX = nil  
    self.p_preY = nil
    self.p_slotNodeH = 0

    self:setVisible(true)
    self.m_reelTargetX = nil
    self.m_reelTargetY = nil
    self.m_isLastSymbol = nil
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

    if self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(true)
    end
    self:setScale(1)
    local ccbNode = self:getCCBNode()

    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        if removeFlag then
            ccbNode:release()
        else
            -- 放回到池里面去
            if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
                globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,self.p_symbolType)
            end
        end
    end

    self.p_symbolType = nil
    self.p_idleIsLoop = true
    self.m_currAnimName = nil
    self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnimaTimes = nil

    -- 清空掉当前的actions
    if self.m_actionDatas ~= nil then
        table_clear(self.m_actionDatas)
    end

    self:hideBigSymbolClip()
end

-- 是不是 respinBonus小块
function FarmSlotsNode:isFixSymbol(symbolType)


    if symbolType == self.SYMBOL_FIX_BONUS_1 or 
        symbolType == self.SYMBOL_FIX_BONUS_2 or 
        symbolType == self.SYMBOL_FIX_BONUS_3 or 
        
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR  then
            return true
    end
    return false
end

return FarmSlotsNode