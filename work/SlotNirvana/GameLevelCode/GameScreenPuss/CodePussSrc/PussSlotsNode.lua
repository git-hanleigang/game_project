---
--xcyy
--2018年5月23日
--PussSlotsNode.lua

local PussSlotsNode = class("PussSlotsNode",util_require("Levels.SlotsNode"))

local WildId = {2,3,4,5,6,7,8}


function PussSlotsNode:initMachine( machine )
    self.m_machine =  machine
end

function PussSlotsNode:getActId( symbolType)

    local id = ""
    if self.m_machine and symbolType then
        if symbolType == self.m_machine.SYMBOL_WILD_2X then
            id = WildId[1]
        elseif symbolType == self.m_machine.SYMBOL_WILD_3X then
            id = WildId[2]
        elseif symbolType == self.m_machine.SYMBOL_WILD_5X then
            id = WildId[3]
        elseif symbolType == self.m_machine.SYMBOL_WILD_8X then
            id = WildId[4]
        elseif symbolType == self.m_machine.SYMBOL_WILD_10X then
            id = WildId[5]
        elseif symbolType == self.m_machine.SYMBOL_WILD_25X then
            id = WildId[6]
        elseif symbolType == self.m_machine.SYMBOL_WILD_100X then
            id = WildId[7]
        end
    end
   
    return id
    
end


---
-- 播放连线时的动画
--
function PussSlotsNode:runLineAnim()

    local animName = self:getLineAnimName() .. self:getActId( self.p_symbolType)

    self:runAnim(animName,true)
end

function PussSlotsNode:runIdleAnim()
    if self.p_idleIsLoop == nil then
        self.p_idleIsLoop = false
    end

    local csbNode = self:getCCBNode()
    if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName().. self:getActId( self.p_symbolType) ,self.p_idleIsLoop)
    end
    
end

---
-- 还原到初始被创建的状态
function PussSlotsNode:reset(removeFlag)
    self.p_idleIsLoop = false
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

return PussSlotsNode