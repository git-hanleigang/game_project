local LuckyDollarSlotsNode = class("LuckyDollarSlotsNode", util_require("Levels.SlotsNode"))

LuckyDollarSlotsNode.m_Corn = nil

function LuckyDollarSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
    self.m_freespinWin = false
end

function LuckyDollarSlotsNode:initSlotNodeByCCBName(ccbName, symbolType)
    if symbolType ~= -1 and self.m_actionDatas == nil then -- 表明是滚动的格子
        self.m_actionDatas = {}
    end

    self.m_ccbName = ccbName

    self.p_symbolType = symbolType
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolClipCanReset = true

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    self.m_imageName = imageName

    if imageName == nil then -- 直接添加ccb
        if self.p_symbolImage ~= nil then
            self.p_symbolImage:setVisible(false)
        end
        self:checkLoadCCbNode()
    else
        local offsetX = 0
        local offsetY = 0
        local scale = 1
        if tolua.type(imageName) == "table" then
            self.m_imageName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
            elseif #imageName == 4 then
                offsetX = imageName[2]
                offsetY = imageName[3]
                scale = imageName[4]
            end
        end
        if self.p_symbolImage == nil then
            self.p_symbolImage = display.newSprite(self.m_imageName)
            self:addChild(self.p_symbolImage)
        else
            self:spriteChangeImage(self.p_symbolImage, self.m_imageName)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

function LuckyDollarSlotsNode:runLineAnim(isloop)
    local animName = self:getLineAnimName()
    self:runAnim(
        animName,
        false,
        function()
            if isloop ~= false then
                if self.p_symbolType < 9 then
                    if self.m_freespinWin then
                        self:runAnim("idleframe3", true)
                    else
                        self:runAnim("idleframe2", true)
                    end
                end
            end
        end
    )
end

function LuckyDollarSlotsNode:getLineAnimName()
    if self.m_lineAnimName ~= nil then
        return self.m_lineAnimName
    else
        if self.p_symbolType < 9 then
            if self.m_freespinWin then
                return "start3"
            else
                return "start"
            end
        else
            return "start"
        end
    end
end

function LuckyDollarSlotsNode:clear()
    self.m_currAnimName = nil
    self.m_actionDatas = nil
    self.p_preParent = nil
    self.m_callBackFun = nil
    self.m_freespinWin = false
    self:unregisterScriptHandler() -- 卸载掉注册事件
    local labNode = self:getCcbProperty("xbei")
    if labNode then
        labNode:removeAllChildren()
    end
    local totallabNode = self:getCcbProperty("xbei_0")
    if totallabNode then
        totallabNode:removeAllChildren()
    end
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

-- 还原到初始被创建的状态
function LuckyDollarSlotsNode:reset()
    self.p_idleIsLoop = false
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0
    self.m_freespinWin = false

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
    local labNode = self:getCcbProperty("xbei")
    if labNode then
        labNode:removeAllChildren()
    end
    local totallabNode = self:getCcbProperty("xbei_0")
    if totallabNode then
        totallabNode:removeAllChildren()
    end
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

function LuckyDollarSlotsNode:setFreeSpinWin(bFsWin)
    self.m_freespinWin = bFsWin
end

return LuckyDollarSlotsNode
