--LottoPartySlotsNode.lua

local LottoPartySlotsNode = class("LottoPartySlotsNode", util_require("Levels.SlotsNode"))

function LottoPartySlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function LottoPartySlotsNode:removeJackpoyTag()
    if self.m_jackpotTag then
        self.m_jackpotTag:removeFromParent()
        self.m_jackpotTag = nil
    end
end

function LottoPartySlotsNode:clear()
    self:removeJackpoyTag()
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

function LottoPartySlotsNode:removeAndPushCcbToPool()
    self:removeJackpoyTag()
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
function LottoPartySlotsNode:reset()
    self.p_idleIsLoop = false
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0
    self:removeJackpoyTag()
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

-- 切换ccb的动画名字在其它特定关卡使用
function LottoPartySlotsNode:changeCCBByName(ccbName, symbolType)
    if ccbName == self.m_ccbName then
        return
    end

    self:removeAndPushCcbToPool()

    self.p_symbolType = symbolType
    self.m_ccbName = ccbName
    self:checkLoadCCbNode()
    self:resetImage()
end

function LottoPartySlotsNode:resetImage()
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(self.m_ccbName)
    self.m_imageName = imageName
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

return LottoPartySlotsNode
