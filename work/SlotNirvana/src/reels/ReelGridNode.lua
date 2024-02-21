--滚轴上的小格子
local ReelGridNode = class("ReelGridNode",cc.Node)
ReelGridNode.m_parentData = nil         --滚动数据
ReelGridNode.m_configData = nil         --滚动数据
ReelGridNode.m_baseNode = nil           --普通层
ReelGridNode.m_topNode = nil            --最上层
ReelGridNode.m_isInTop = nil            --是否在最上层
ReelGridNode.m_lastImageName = nil      --上次贴图名称
ReelGridNode.m_originalPos = nil        --初始坐标
ReelGridNode.m_originalDistance = nil   --起始坐标
ReelGridNode.m_machine = nil            --兼容关卡重写小块用到machine
ReelGridNode.m_bigSymbolIndex = nil     --大信号索引
ReelGridNode.m_bigSymbolPos = nil       --大信号偏移量
ReelGridNode.m_bigSymbolCount = nil     --大信号组成数量
local isDebugSymbol = false
--
function ReelGridNode:clearData()
    self.m_isInitData = nil
    self.m_parentData = nil
    self.m_configData = nil
    self.m_baseNode = nil
    self.m_topNode = nil
    self.m_originalPos = nil
    self.m_isInTop = nil
    self.m_lastImageName = nil
    self.p_cloumnIndex = nil
    self.p_rowIndex = nil
    self.m_isLastSymbol = nil
    self.p_slotNodeH = nil
    self.p_symbolType = nil
    self.p_preSymbolType = nil
    self.p_showOrder = nil
    self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnimaSound = nil
    self.p_layerTag = nil
    self.m_machine = nil
    self.m_bigSymbolIndex = nil
    self.m_bigSymbolPos = nil
    self.m_bigSymbolCount = nil
end
--设置大信号信息
function ReelGridNode:updateBigSymbolInfo(index,pos,count)
    self.m_bigSymbolIndex = index
    self.m_bigSymbolPos = pos
    self.m_bigSymbolCount = count
end
function ReelGridNode:getBigSymbolInfo()
    return self.m_bigSymbolIndex,self.m_bigSymbolPos,self.m_bigSymbolCount
end
--兼容slotNode重写逻辑
function ReelGridNode:setMachine(machine )
    self.m_machine = machine
end

function ReelGridNode:initData(parentData,configData)
    self.m_isInitData = true
    self.m_parentData = parentData
    self.m_configData = configData
    self.m_baseNode = parentData.slotParent
    self.m_topNode = parentData.slotParentBig
    self.m_originalPos = cc.p(parentData.startX+0.5*parentData.slotNodeW,parentData.slotNodeH*0.5)
    self.m_isInTop = false
    self.m_lastImageName = nil
    self:setPosition(self.m_originalPos)
    self:setOriginalDistance(0)
end

--把自己添加到父节点上
function ReelGridNode:addSelf(parnetNode)
    if parnetNode then
        parnetNode:addChild(self, self.m_parentData.order, self.m_parentData.tag)
    else
        if self.m_topNode and self.m_configData:checkSpecialSymbol(self.p_symbolType) then
            self.m_topNode:addChild(self, self.m_parentData.order, self.m_parentData.tag)
            self.m_isInTop = true
        else
            self.m_baseNode:addChild(self, self.m_parentData.order, self.m_parentData.tag)
            self.m_isInTop = false
        end
    end
end

--重置位置
function ReelGridNode:resetPosition()
    self:setPosition(self.m_originalPos)
end
--滚动相关
function ReelGridNode:setOriginalDistance(distance)
    self.m_originalDistance = distance
end
function ReelGridNode:getOriginalDistance()
    return self.m_originalDistance
end
function ReelGridNode:updateDistance(distance)
    if self.m_bigSymbolPos then
        self:setPositionY(self.m_originalDistance-distance+self.m_bigSymbolPos)
    else
        self:setPositionY(self.m_originalDistance-distance)
    end
    
end


--刷新节点添加父节点
function ReelGridNode:updateGrid(isNewGridNode)
    if not isNewGridNode then
        self:reset()
        self:resetReelStatus()
    end
    self:updateParentData()
    self:updateLayer()
    self:updateBigSymbolInfo()
end

--兼容现有代码
function ReelGridNode:updateParentData()
    self.p_cloumnIndex = self.m_parentData.cloumnIndex
    self.p_rowIndex = self.m_parentData.rowIndex
    self.m_isLastSymbol = self.m_parentData.m_isLastSymbol
    self.p_slotNodeH = self.m_parentData.slotNodeH
    self.p_symbolType = self.m_parentData.symbolType
    self.p_preSymbolType = self.m_parentData.preSymbolType
    self.p_showOrder = self.m_parentData.order
    self.p_reelDownRunAnima = self.m_parentData.reelDownAnima
    self.p_reelDownRunAnimaSound = self.m_parentData.reelDownAnimaSound
    self.p_layerTag = self.m_parentData.layerTag
    
    --测试代码
    -- local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(self.m_parentData.ccbName)
    -- if imageName then
    --     self:initSlotNodeByCCBName(self.m_parentData.ccbName,self.m_parentData.symbolType)
    -- end
    self:initSlotNodeByCCBName(self.m_parentData.ccbName,self.p_symbolType)
    self:setLocalZOrder(self.p_showOrder)
    self:setTag(self.m_parentData.tag)
    self:toTestLb()
end

--打印信号类型和横列
function ReelGridNode:toTestLb()
    if isDebugSymbol then
        if not self.testlb then
            self.testlb = cc.LabelTTF:create("", "Arial", 34)
            self:addChild(self.testlb,10)
            self.testlb:setColor(cc.c3b(0,0,0))
            -- self.testlb:setScale(0.7)
        end
        local strTest = self.p_symbolType
        -- local tableStr = string.gsub(tostring(self),"userdata: ","")
        if self.p_rowIndex then
            -- strTest = strTest.."-"..self.p_rowIndex .."\n".. tableStr .. "\n " .. (self.p_layerTag or -1)
            strTest = strTest.."-"..self.p_rowIndex
        end
        self.testlb:setString(strTest)
    end
end

--检测是否切换层级
function ReelGridNode:updateLayer()
    if not self.p_layerTag or self.p_layerTag~= SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
        return
    end
    if self.m_topNode and self:getParent() then
        local isTopSymbol = self.m_configData:checkSpecialSymbol(self.p_symbolType)
        local rowIndex = self.p_rowIndex or 0
        if isTopSymbol and not self.m_isInTop then
            --普通层级信号切换特殊层级信号
            util_changeNodeParent(self.m_topNode,self,self.p_showOrder)
            self.m_isInTop = true
        elseif not isTopSymbol and self.m_isInTop then
            --特殊层级信号切换普通层级信号
            util_changeNodeParent(self.m_baseNode,self,self.p_showOrder)
            self.m_isInTop = false
        end
    end
end

--[[
    切换小块层级到大信号层
]]
function ReelGridNode:changeParentToTopNode(order)
    if not self.p_layerTag or self.p_layerTag~= SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
        return
    end

    local parentNode = self:getParent()
    --信号是否已经在大信号层上
    if self.m_topNode and parentNode and self.m_topNode ~= parentNode then
        if order then
            self.p_showOrder = order
        end
        local pos = util_convertToNodeSpace(self,self.m_topNode)
        util_changeNodeParent(self.m_topNode,self,self.p_showOrder)
        self.m_isInTop = true
        self:setPosition(pos)
    end
end

--[[
    切换小块层级到基础信号层
]]
function ReelGridNode:changeParentToBaseNode(order)
    if not self.p_layerTag or self.p_layerTag~= SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
        return
    end

    local parentNode = self:getParent()
    --信号是否已经在该信号层上
    if self.m_baseNode and parentNode and self.m_baseNode ~= parentNode then
        if order then
            self.p_showOrder = order
        end
        local pos = util_convertToNodeSpace(self,self.m_baseNode)
        util_changeNodeParent(self.m_baseNode,self,self.p_showOrder)
        self.m_isInTop = false
        self:setPosition(pos)
    end
end

--[[
    将小块放回原来的层上
]]
function ReelGridNode:putBackToPreParent()
    if not self.p_layerTag or self.p_layerTag~= SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
        return
    end

    if self.m_isInTop then
        self:changeParentToTopNode()
    else
        self:changeParentToBaseNode()
    end
end

--[[
    将小块提到其他层上
    提出裁切层用,放回原来层级调用putBackToPreParent即可
]]
function ReelGridNode:changeParentToOtherNode(parent,order)
    local preParent = self:getParent()
    if preParent == parent then
        return
    end
    if order then
        self.p_showOrder = order
    end
    local pos = util_convertToNodeSpace(self,parent)
    util_changeNodeParent(parent,self,self.p_showOrder)
    self:setPosition(pos)
end

return ReelGridNode