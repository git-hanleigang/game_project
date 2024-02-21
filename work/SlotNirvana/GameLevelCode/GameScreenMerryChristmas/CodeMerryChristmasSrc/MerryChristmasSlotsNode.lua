--MerryChristmasSlotsNode.lua

local MerryChristmasSlotsNode = class("MerryChristmasSlotsNode", util_require("Levels.SlotsNode"))

function MerryChristmasSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
    -- self.m_scatterTag = nil
end

function MerryChristmasSlotsNode:removeScatterTag()
    if self.m_scatterTag then
        self.m_scatterTag:removeFromParent()
        self.m_scatterTag = nil
    end
end

function MerryChristmasSlotsNode:removeBonusTip()
    if self.m_bonusTips then
        self.m_bonusTips:removeFromParent()
        self.m_bonusTips = nil
        for i = 1, 5 do
            local lineNode = self:getCcbProperty("Line" .. i)
            if lineNode then
                lineNode:setVisible(false)
            end
        end
    end
end

function MerryChristmasSlotsNode:playScatterTagAction(_actName,_bLoop, func)
    if self.m_scatterTag then
        self.m_scatterTag:runCsbAction(
            _actName,
            _bLoop,
            function()
                if func then
                    func()
                end
            end
        )
    end
end

function MerryChristmasSlotsNode:playBonusTipAction(actName)
    if self.m_bonusTips then
        self.m_bonusTips:runCsbAction(actName, false)
    end
end

function MerryChristmasSlotsNode:clear()
    self:removeScatterTag()
    self:removeBonusTip()
    self.m_currAnimName = nil
    self.m_actionDatas = nil
    self.p_preParent = nil
    self.m_callBackFun = nil
    self:unregisterScriptHandler() -- 卸载掉注册事件

    -- 检测释放掉添加进来的动画节点
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:clear()

        ccbNode:removeAllChildren()

        if ccbNode:getReferenceCount() > 1 then
            ccbNode:release()
        end

        ccbNode:removeFromParent()
    end

    if self.p_symbolImage ~= nil and self.p_symbolImage:getParent() ~= nil then
        self.p_symbolImage:removeFromParent()
    end

    self.p_symbolImage = nil
end

function MerryChristmasSlotsNode:removeAndPushCcbToPool()
    self:removeScatterTag()
    self:removeBonusTip()
    local ccbNode = self:getCCBNode()

    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        if ccbNode.__cname ~= nil and ccbNode.__cname == "SlotsSpineAnimNode" then
            if util_isSupportVersion("1.1.4") then
                ccbNode.m_spineNode:resetAnimation()
            end
        end
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode, self.p_symbolType)
        end
    end
end

-- 还原到初始被创建的状态
function MerryChristmasSlotsNode:reset()
    self.p_idleIsLoop = false
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0
    self:removeScatterTag()
    self:removeBonusTip()
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
return MerryChristmasSlotsNode
