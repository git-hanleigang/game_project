

local VegasLifeSlotNode = class("VegasLifeSlotNode",util_require("Levels.SlotsNode"))

VegasLifeSlotNode.p_idleIsLoop = nil -- 动画是否需要循环

function VegasLifeSlotNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
    self.p_reelDownRunAnima = "buling"
end

---
-- 还原到初始被创建的状态
function VegasLifeSlotNode:reset()

    self.p_idleIsLoop = true
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

    if self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(true)
    end
    self:setScale(1)
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,self.p_symbolType)
        end
    end


    self.p_symbolType = nil

    self.m_currAnimName = nil
    -- self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnima = "buling"

    self.p_reelDownRunAnimaTimes = nil
    -- 清空掉当前的actions
    if self.m_actionDatas ~= nil then

        table_clear(self.m_actionDatas)
    end

    self:hideBigSymbolClip()
end
function VegasLifeSlotNode:runIdleAnim()
    -- if self.p_idleIsLoop == nil then
    --     self.p_idleIsLoop = true
    -- end
    self.p_idleIsLoop = true
    local csbNode = self:getCCBNode()
    if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop)
    end

end
---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function VegasLifeSlotNode:runAnim(animName,loop,func)
    -- if self.p_symbolType == 90 and animName ~= "idleframe" then
    --     print("animName-----------"..animName)
    -- end

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

return VegasLifeSlotNode