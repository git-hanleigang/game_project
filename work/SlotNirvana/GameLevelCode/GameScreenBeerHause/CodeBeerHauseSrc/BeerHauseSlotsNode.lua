---
--xcyy
--2018年5月23日
--BeerHauseSlotsNode.lua

local BeerHauseSlotsNode = class("BeerHauseSlotsNode",util_require("Levels.SlotsNode"))


BeerHauseSlotsNode.SYMBOL_FSMORE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 -- 101 freespin + 1  暂时加的容错处理，按理说不应该出现这个信号
BeerHauseSlotsNode.SYMBOL_FSMORE_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- 102 freespin + 1
BeerHauseSlotsNode.SYMBOL_FSMORE_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 -- 103 freespin + 2
BeerHauseSlotsNode.SYMBOL_FSMORE_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 -- 104 freespin + 3

function BeerHauseSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function BeerHauseSlotsNode:getBonusSlotsId(  )

    local slotid = ""

    if self.p_symbolType then
        if self.p_symbolType == self.SYMBOL_FSMORE then
            slotid = 2
        elseif self.p_symbolType == self.SYMBOL_FSMORE_1 then
            slotid = 2
        elseif self.p_symbolType == self.SYMBOL_FSMORE_2 then
            slotid = 3
        elseif self.p_symbolType == self.SYMBOL_FSMORE_3 then
            slotid = 4
        end

    end

    return slotid
end

---
-- 还原到初始被创建的状态
function BeerHauseSlotsNode:reset(removeFlag)
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




---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function BeerHauseSlotsNode:runAnim(animName,loop,func,notAddId)

    local slotId = self:getBonusSlotsId( )
    if notAddId then
        -- print("就是普通播放")
    else 

        animName = animName .. slotId
    end
    

    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end

    local isPlay = ccbNode:runAnim(animName,loop,func)

    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end

    end
    
end


function BeerHauseSlotsNode:runIdleAnim()
    if self.p_idleIsLoop == nil then
        self.p_idleIsLoop = false
    end


    local csbNode = self:getCCBNode()
    if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop,nil,true)
    end
    
end


return BeerHauseSlotsNode