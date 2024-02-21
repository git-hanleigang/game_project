local VegasSlotsNode = class("VegasSlotsNode", util_require("Levels.SlotsNode"))

function VegasSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function VegasSlotsNode:runAnimForeverFun(animName, loop, func)
    local ccbNode = self:checkLoadCCbNode()
    util_csbPlayForKeyForeverFun(ccbNode:getCsbAct(false), animName, loop, func)
end

-- 还原到初始被创建的状态
function VegasSlotsNode:reset()
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
    if self.p_symbolType == 110 or self.p_symbolType == 109 then
        self:runAnim("idleframe1", false)
    end
    if self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(true)
    end
    self:setScale(1)
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        if self.p_symbolType == 110 or self.p_symbolType == 109 then
            if ccbNode.__cname ~= nil and ccbNode.__cname == "SlotsSpineAnimNode" then
                ccbNode.m_spineNode:resetAnimation()
            end
        end
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode, self.p_symbolType)
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

return VegasSlotsNode
