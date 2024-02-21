---
--island
--2017年8月25日
--BaseFastMachine.lua
-- FIX IOS 139
-- 这里实现老虎机的所有UI表现相关联的，而各个关卡更多的关心这里的内容
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local ReelLineInfo = require "data.levelcsv.ReelLineInfo"
local SlotsReelData = require "data.slotsdata.SlotsReelData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsReelRunData = require "data.slotsdata.SlotsReelRunData"
local SlotParentData = require "data.slotsdata.SlotParentData"

local BaseFastMachine = class("BaseFastMachine", BaseSlotoManiaMachine)

function BaseFastMachine:initData_(...)
    BaseSlotoManiaMachine.initData_(self, ...)
    --滚动节点缓存列表
    self.cacheNodeMap = {}
end

function BaseFastMachine:clearCacheMap()
    local cacheNodeMap = self.cacheNodeMap
    for col, nodeList in pairs(cacheNodeMap) do
        for index, node in ipairs(nodeList) do
            node.cacheFlag = false
        end
        cacheNodeMap[col] = nil
    end
end

function BaseFastMachine:getCacheNode(colIndex,symbolType)
    --特殊层级信号不缓存
    if symbolType and self.m_configData:checkSpecialSymbol(symbolType) then
        return nil
    end
    local symbolNodeList = self.cacheNodeMap[colIndex]
    local node = nil
    if symbolNodeList ~= nil then
        for k, v in ipairs(symbolNodeList) do
            if v.cacheFlag then
                node = v
                v.cacheFlag = false
                table.remove(symbolNodeList, k)
                break
            end
        end
    end
    return node
end

---
-- 预创建内存池中的节点， 在LaunchLayer 里面，
--
function BaseFastMachine:preLoadSlotsNodeBySymbolType(symbolType, count)
    for i = 1,count do
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        if ccbName == nil or ccbName == "" then
            return
        end
        local hasSymbolCCB = cc.FileUtils:getInstance():isFileExist(ccbName .. ".csb")
        local hasSpine = cc.FileUtils:getInstance():isFileExist(ccbName .. ".atlas")
        if hasSymbolCCB == true then
            local node = SlotsAnimNode:create()
            node:loadCCBNode(ccbName, symbolType)
            node:retain()
            self:pushAnimNodeToPool(node, symbolType)
        elseif hasSpine then
            local spineSymbolData = self.m_configData:getSpineSymbol(symbolType) or {}
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType,spineSymbolData[3])
            self:pushAnimNodeToPool(node, symbolType)
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            
        else
            return
        end
    end
end

--[[
    @desc: 根据symbolType 
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col: 
    --@isLastSymbol:
    @return:
]]
function BaseFastMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    local tmpSymbolType = self:convertSymbolType(symbolType)
    local symbolNode = self:getSlotNodeBySymbolType(tmpSymbolType)
    self:setSlotCacheNodeWithPosAndType(symbolNode, symbolType, row, col, isLastSymbol)
    return symbolNode
end

function BaseFastMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    node.p_rowIndex = row
    node.p_cloumnIndex = col
    node.p_symbolType = symbolType
    node.m_isLastSymbol = isLastSymbol or false

    --检测添加角标
    self:checkAddSignOnSymbol(node)
end

---
-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
--
function BaseFastMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)


    local symbolNodeList = self.cacheNodeMap[node.p_cloumnIndex]
    if symbolNodeList ~= nil then
        for k, v in ipairs(symbolNodeList) do
            if node == v then
                table.remove(symbolNodeList, k)
                break
            end
        end
    end
    node.cacheFlag = false
    BaseSlotoManiaMachine.pushSlotNodeToPoolBySymobolType(self, symbolType, node)
end


---
-- 清理掉 所有slot node 节点
function BaseFastMachine:clearSlotNodes()
    self:clearCacheMap()
    BaseSlotoManiaMachine.clearSlotNodes(self)
end

---
-- 获取界面上的小块
--
function BaseFastMachine:getReelParentChildNode(iCol, iRow)
    local childNode = nil
    local childTag = self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG)
    self:foreachSlotParent(
        iCol,
        function(index, realIndex, node)
            if node:getTag() == childTag then
                childNode = node
                return true
            end
        end
    )
    return childNode
end

function BaseFastMachine:convertSymbolType(symbolType)
    return symbolType
end

local L_ABS = math.abs
function BaseFastMachine:moveDownCallFun(node, colIndex)
    -- 回收对象
    if node and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
        node:setVisible(true)
        node:removeFromParent(false)
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
        return
    end

    local symbolNodeList = self.cacheNodeMap[colIndex]
    if symbolNodeList == nil then
        symbolNodeList = {}
        self.cacheNodeMap[colIndex] = symbolNodeList
    end
    node:reset()
    node:setVisible(false)
    node:setTag(-1)
    node.cacheFlag = true
    table.insert(symbolNodeList, node)
end

---
-- 检测是否移除掉 每列中的元素
--
function BaseFastMachine:reelSchedulerCheckRemoveNodes(colIndex, halfH, parentY)
    local zOrder = 0
    local preY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, childNode)
            if childNode.p_IsMask == nil then
                local childY = childNode:getPositionY()
                local nodeH = childNode.p_slotNodeH or 144
                -- 判断当前位置信息是否处于当前列的外面，是则移除掉
                local topY = 0
                if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
                    topY = childY + (symbolCount - 0.5) * (halfH * 2) --nodeH * 0.5 -- --
                else
                    topY = childY + nodeH * 0.5 --halfH
                end
                preY = util_max(preY, topY)
                if topY + parentY <= 0 then
                    -- 移除
                    self:moveDownCallFun(childNode, colIndex)
                else
                    zOrder = zOrder + childNode:getLocalZOrder()
                end
            end
        end
    )
    return zOrder, preY
end

---
--移除节点后检测是否需要在创建节点
--
function BaseFastMachine:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
    if parentData.isReeling == true then
        -- 判断哪些元素需要移除出显示列表
        local colIndex = parentData.cloumnIndex
        local columnData = self.m_reelColDatas[colIndex]
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth

        if moveDiff <= 0 then
            local createNextSlotNode = function()
                local symbolType = parentData.symbolType
                local node = self:getCacheNode(colIndex,symbolType)
                if node == nil then
                    node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, colIndex, parentData.m_isLastSymbol)
                    local slotParentBig = parentData.slotParentBig
                    -- 添加到显示列表
                    if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                        slotParentBig:addChild(node, parentData.order, parentData.tag)
                    else
                        slotParent:addChild(node, parentData.order, parentData.tag)
                    end
                else
                    local tmpSymbolType = self:convertSymbolType(symbolType)
                    node:setVisible(true)
                    node:setLocalZOrder(parentData.order)
                    node:setTag(parentData.tag)
                    local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                    node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                    self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, colIndex, parentData.m_isLastSymbol)
                end

                local posY = preY + columnData.p_showGridH * 0.5

                node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

                zOrder = zOrder + parentData.order

                node.p_slotNodeH = columnData.p_showGridH
                node.p_symbolType = symbolType
                node.p_preSymbolType = parentData.preSymbolType
                node.p_showOrder = parentData.order

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
                node.p_layerTag = parentData.layerTag

                node:runIdleAnim()

                if parentData.isHide then
                    node:setVisible(false)
                end

                if self.m_bigSymbolInfos[symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[symbolType]

                    preY = posY + (symbolCount - 0.5) * columnData.p_showGridH
                else
                    preY = posY + 0.5 * columnData.p_showGridH -- 计算创建偏移位置到顶部区域y坐标
                end

                moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
                -- lastNode = node

                -- 创建下一个节点
                if parentData.isLastNode == true then -- 本列最后一个节点移动结束
                    -- 执行回弹, 如果不执行回弹判断是否执行
                    parentData.isReeling = false
                    -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
                    -- 创建一个假的小块 在回滚停止后移除
                    self:createResNode(parentData, node)
                else
                    -- 计算moveDiff 距离是否大于一个 格子， 如果是那么循环补齐多个格子， 以免中间缺失创建
                    self:createSlotNextNode(parentData)
                end
            end

            createNextSlotNode() -- 创建一次

            while (moveDiff < 0 and parentData.isReeling == true) do
                createNextSlotNode()
            end
        else
        end -- end if moveDiff <= 0 then

        self:changeSlotsParentZOrder(zOrder, parentData, slotParent) -- 重新设置zorder
    end -- end if parentData.isReeling == true
end

---
--@param bBlowScreen bool true 移除屏幕下边的小块 false 移除屏幕上方的小块
function BaseFastMachine:removeNodeOutNode(colIndex, bBlowScreen, halfH)
    local slotParentData = self.m_slotParents[colIndex]
    local slotParent = slotParentData.slotParent
    local columnData = self.m_reelColDatas[colIndex]
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, childNode)
            if childNode.p_IsMask == nil then
                local childY = childNode:getPositionY()
                -- 判断当前位置信息是否处于当前列的外面，是则移除掉
                local topY = 0
                if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
                    topY = childY + (symbolCount - 0.5) * columnData.p_showGridH --self.m_SlotNodeH
                else
                    topY = childY + columnData.p_showGridH * 0.5
                end

                --移除屏幕下方
                if bBlowScreen then
                    if topY + slotParent:getPositionY() < 1 then
                        -- 移除
                        self:moveDownCallFun(childNode, colIndex)
                    else
                        if childNode.m_isLastSymbol == false then
                            release_print(
                                "removeNodeOutNode " .. slotParent:getPositionY() .. "  " .. childNode.p_cloumnIndex .. " " .. childNode.p_rowIndex .. " " .. childNode:getPositionY() .. "  " .. topY
                            )
                        end
                    end
                else
                    --移除屏幕上方
                    local bottomY = topY
                    if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                        local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
                        bottomY = bottomY - symbolCount * columnData.p_showGridH --self.m_SlotNodeH
                    else
                        bottomY = bottomY - columnData.p_showGridH
                     --self.m_SlotNodeH
                    end
                    if bottomY + 1 >= math.abs(slotParent:getPositionY() - columnData.p_slotColumnHeight) then --self.m_fReelHeigth) then
                        -- 移除
                        self:moveDownCallFun(childNode, colIndex)
                    end
                end
            end -- end if IsMask
        end
    )
end

function BaseFastMachine:reelSchedulerCheckColumnReelDown(parentData, parentY, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        local colIndex = parentData.cloumnIndex
        local slotParentData = self.m_slotParents[colIndex]
        local slotParent = slotParentData.slotParent
        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end
            
            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            
            self:slotOneReelDown(colIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig 
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(colIndex, true, halfH)
            end

            if self:checkQuickStopStage() then
            --播放滚动条落下的音效
            -- if parentData.cloumnIndex == self.m_iReelColumnNum then

            -- gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            end
            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(colIndex, true, halfH)

            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end
            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            
            self:foreachSlotParent(colIndex, function(index, realIndex, slotNode)
                --播放配置信号的落地音效
                self:playSymbolBulingSound({slotNode})
                -- 播放配置信号的落地动效
                self:playSymbolBulingAnim({slotNode}, speedActionTable)
            end)
            local tipSlotNoes = {}
            self:foreachSlotParent(
                colIndex,
                function(index, realIndex, slotNode)
                    local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                    if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                        --播放关卡中设置的小块效果
                        self:playCustomSpecialSymbolDownAct(slotNode)

                        if self:checkSymbolTypePlayTipAnima( slotNode.p_symbolType )then
                            
                            if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                                tipSlotNoes[#tipSlotNoes + 1] = slotNode
                            end
                        end
                    end
                end
            )


            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]

                    
                    self:playScatterBonusSound(slotNode)
                    slotNode:runAnim("buling")
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end
            
            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )

            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function BaseFastMachine:initCloumnSlotNodesByNetData()
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount,rowNum,rowIndex = self:getinitSlotRowDatatByNetData(columnData )

        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder)
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, changeRowIndex, colIndex, true)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = showOrder

            -- node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end

function BaseFastMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end

function BaseFastMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end

-----
---创建一行小块 用于一列落下时 上边条漏出空隙过大
function BaseFastMachine:createResNode(parentData, lastNode)
    if self.m_bCreateResNode == false then
        return
    end

    local rowIndex = parentData.rowIndex

    local function addRandomNode()
        local symbolType = self:getResNodeSymbolType(parentData)
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local colIndex = parentData.cloumnIndex
        local columnData = self.m_reelColDatas[colIndex]
        local slotNodeH = columnData.p_showGridH

        local node = self:getCacheNode(colIndex,symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, columnData.p_showGridCount + 1, parentData.cloumnIndex, true)
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node)
            else
                slotParent:addChild(node)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, columnData.p_showGridCount + 1, parentData.cloumnIndex, true)
        end

        node.p_slotNodeH = slotNodeH
        node:setTag(-1)
        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local targetPosY = lastNode:getPositionY()
        if self.m_bigSymbolInfos[lastNode.p_symbolType] ~= nil then
            targetPosY = targetPosY + (self.m_bigSymbolInfos[lastNode.p_symbolType]) * slotNodeH
        else
            targetPosY = targetPosY + slotNodeH
        end

        node:setPosition(lastNode:getPositionX(), targetPosY)
        local order = self:getBounsScatterDataZorder(symbolType) - node.p_rowIndex
        node:setLocalZOrder(order)
    end

    if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
        local bigSymbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if rowIndex > 1 and (rowIndex - 1) + bigSymbolCount > self.m_iReelRowNum then -- 表明跨过了 当前一组
            --表明跨组了 不创建小块
        else
            --创建一个小块
            addRandomNode()
        end
    else
        --创建一个小块
        addRandomNode()
    end
end

function BaseFastMachine:getFixSymbol(iCol, iRow, iTag)
    local fixSp = nil
    fixSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, iTag))
    if fixSp == nil and (iCol >= 1 and iCol <= self.m_iReelColumnNum) then
        fixSp = self:getReelParentChildNode(iCol, iRow)
    end
    return fixSp
end

function BaseFastMachine:operaBigSymbolMask(showMask)
    if self.m_hasBigSymbol == false then
        return
    end
    for colIndex = 1, #self.m_slotParents do
        self:foreachSlotParent(
            colIndex,
            function(index, realIndex, childNode)
                if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                    if showMask == true then
                        self:operaBigSymbolShowMask(childNode)
                    else
                        childNode:hideBigSymbolClip()
                    end
                end
            end
        )
    end
end

---
-- 重置列的 local zorder
--
function BaseFastMachine:resetCloumnZorder(col)
    if col < 1 or col > self.m_iReelColumnNum then
        return
    end
    local parentData = self.m_slotParents[col]
    local slotParent = parentData.slotParent
    local totalOrder = 0
    self:foreachSlotParent(
        col,
        function(index, realIndex, slotNode)
            totalOrder = totalOrder + slotNode:getLocalZOrder()
        end
    )
    slotParent:getParent():setLocalZOrder(totalOrder)
end

function BaseFastMachine:foreachSlotParent(colIndex, callBack)
    local slotParentData = self.m_slotParents[colIndex]
    local realIndex = 0
    local index = 0
    if slotParentData ~= nil then
        local slotParent = slotParentData.slotParent
        local slotParentBig = slotParentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j=1,#newChilds do
                childs[#childs+1]=newChilds[j]
            end
        end
        while index < #childs do
            index = index + 1
            local node = childs[index]
            if not node.cacheFlag then
                realIndex = realIndex + 1
                if callBack ~= nil then
                    local flag = callBack(index, realIndex, node)
                    if flag then
                        break
                    end
                end
            end
        end
    end
    return index, realIndex
end

function BaseFastMachine:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or self:checkGameRunPause() then
        return
    end

    if self.m_reelDownAddTime > 0 then
        self.m_reelDownAddTime = self.m_reelDownAddTime - delayTime
    else
        self.m_reelDownAddTime = 0
    end
    local timeDown = 0
    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local columnData = self.m_reelColDatas[index]
        local halfH = columnData.p_showGridH * 0.5

        local parentY = slotParent:getPositionY()
        if parentData.isDone == false then
            local cloumnMoveStep = self:getColumnMoveDis(parentData, delayTime)
            local newParentY = slotParent:getPositionY() - cloumnMoveStep
            if self.m_isWaitingNetworkData == false then
                if newParentY < parentData.moveDistance then
                    newParentY = parentData.moveDistance
                end
            end
            slotParent:setPositionY(newParentY)
            parentY = newParentY
            if slotParentBig then
                slotParentBig:setPositionY(newParentY)
            end
            local zOrder, preY = self:reelSchedulerCheckRemoveNodes(index, halfH, parentY)
            self:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
        end

        if self.m_isWaitingNetworkData == false then
            timeDown = self:reelSchedulerCheckColumnReelDown(parentData, parentY, halfH)
        end
    end -- end for

    local function isAllReelDone()
        for index = 1, #slotParentDatas do
            if slotParentDatas[index].isResActionDone == false then
                return false
            end
        end
        return true
    end

    if isAllReelDone() == true then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        self:slotReelDown()
        self.m_reelDownAddTime = 0
    end
end

function BaseFastMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

--beginReel时尝试修改层级
function BaseFastMachine:checkChangeClipParent(parentData)
    --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
    self:foreachSlotParent(
        parentData.cloumnIndex,
        function(index, realIndex, child)
            local slotParent = parentData.slotParent
            if child.resetReelStatus ~= nil then
                child:resetReelStatus()
            end
            if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE then
                --将该节点放在 .m_clipParent
                child:removeFromParent(false)
                local posWorld = slotParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
                local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                child:setPosition(cc.p(pos.x, pos.y))
                self.m_clipParent:addChild(child, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + child.m_showOrder)
            end
        end
    )
end

function BaseFastMachine:dealSmallReelsSpinStates( )
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end

--[[
    @desc: 检测是否有大信号
    time:2020-07-20 21:31:34
]]
function BaseFastMachine:checkHasBigSymbolWithNetWork( )
    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i = 1, #self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)
        
        local preY,isLastBigSymbol,realChildCount = self:checkLastSymbolInfo(i)

        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if realChildCount == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY - moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    return lastNodeIsBigSymbol , maxDiff
end

function BaseFastMachine:checkLastSymbolInfo(colIndex)

    local preY = 0
    local isLastBigSymbol = false

    local _, realChildCount =
        self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            local nodeH = child.p_slotNodeH or 144
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
                isLastBigSymbol = true
            else
                topY = childY + nodeH * 0.5
                isLastBigSymbol = false
            end

            if topY < preY and isLastBigSymbol == false then
                isLastBigSymbol = false
            end
            preY = util_max(preY, topY)
        end
    )

    return preY,isLastBigSymbol,realChildCount

end


--[[
    @desc: 处理网络消息返回后的大信号数据处理
    time:2020-07-20 21:33:13
    @return:
]]
function BaseFastMachine:operaBigSymbolWithNetWork(maxDiff )
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local _, realChildCount = self:foreachSlotParent(i, nil)
        if realChildCount == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            parentData.moveDiff = maxDiff
        end

        local parentY = slotParent:getPositionY()
        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH

        moveL = moveL + maxDiff

        -- 补齐到长条高度
        local diffDis = maxDiff - math.abs(parentData.moveDiff)

        if diffDis > 0 then
            self:operaBigSymbolAddCounts(diffDis,columnData,parentData)
        end

        parentData.moveDistance = parentY - moveL

        parentData.moveL = moveL
        parentData.moveDiff = nil
        self:createSlotNextNode(parentData)
    end
end
--[[
    @desc: 处理大信号返回之后的补块
    time:2020-07-20 21:36:32
    @return:
]]
function BaseFastMachine:operaBigSymbolAddCounts(diffDis,columnData,parentData )
    local nodeCount = math.floor(diffDis / columnData.p_showGridH)
    local slotParent = parentData.slotParent
    for addIndex = 1, nodeCount do
        local colIndex = parentData.cloumnIndex
        local symbolType = self:getNormalSymbol(colIndex)
        local node = self:getCacheNode(colIndex,symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, 1, 1, false)
            local slotParentBig = parentData.slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            else
                slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            end
        else
            node:setVisible(true)
            node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            node:initSlotNodeByCCBName(ccbName, symbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, 1, 1, false)
        end

        node.p_slotNodeH = columnData.p_showGridH
        local posY = parentData.preY + (addIndex - 1) * columnData.p_showGridH + columnData.p_showGridH * 0.5
        node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        node:setPositionY(posY)
    end
end

--[[
    @desc: 处理普通信号的网络消息返回
    time:2020-07-20 21:34:17
]]
function BaseFastMachine:operaNormalSymbolWithNetWork( )
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        self:createSlotNextNode(parentData)
    end
end

function BaseFastMachine:operaNetWorkData()
    
    self:dealSmallReelsSpinStates( )

    local lastNodeIsBigSymbol,maxDiff = self:checkHasBigSymbolWithNetWork()
    -- 检测假数据滚动时最后一个格子是否为 bigSymbol，
    -- 如果是那么其他列补齐到与最大bigsymbol同样的高度
    if lastNodeIsBigSymbol == true then
        self:operaBigSymbolWithNetWork(maxDiff)
    else
        self:operaNormalSymbolWithNetWork()
    end
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

--[[
    @desc: 获取各列需要补充的node 数量 , 结算上下补偿数量的总和
    author:{author}
    time:2019-03-28 16:30:55
    @return:
]]
function BaseFastMachine:getColumnFillCounts()
    local maxTopY = 0
    local reelsTopYs = {}
    local bottomFileCounts = {}
    local slotParents = self.m_slotParents
    local reelColData = self.m_reelColDatas
    local reelSlotsList = self.m_reelSlotsList
    local rowNum = self.m_iReelRowNum
    local colNum = self.m_iReelColumnNum
    local maxCount = 0
    for colIndex = 1, colNum do
        local columnData = reelColData[colIndex]
        local halfH = columnData.p_showGridH * 0.5
        local parentData = slotParents[colIndex]
        local slotParent = parentData.slotParent
        local preY = self:getSlotNodeChildsTopY(colIndex)
        -- release_print("向上补充信息开始计算..")
        reelsTopYs[colIndex] = preY
        maxTopY = util_max(maxTopY, preY)
        -- release_print("向上补充信息为 " .. i .. " preY = " .. preY )

        --getFillBottomNodeCountWithQuickStop移植过来的函数体
        local columnDatas = reelSlotsList[colIndex]
        local data = columnDatas[#columnDatas - rowNum + 1]
        local fillCount = 0
        local symbolType = -1
        -- 这种情况是表明有些列根本没有滚动的最终信号
        if data == nil or tolua.type(data) == "number" then
            fillCount = 0
        else
            symbolType = data.p_symbolType
            if self.m_bigSymbolInfos[symbolType] ~= nil and self:checkColEnterLastReel(colIndex) == false then
                local bigSymbolColData = self.m_bigSymbolColumnInfo[colIndex]
                if bigSymbolColData ~= nil and #bigSymbolColData > 0 and bigSymbolColData[1].startRowIndex < 1 then
                    fillCount = 1 - bigSymbolColData[1].startRowIndex
                else
                    fillCount = 0
                end
            else
                fillCount = 0
            end
        end
        bottomFileCounts[colIndex] = fillCount
        -- release_print("向下补偿的数量信息为 " .. i .. " count= "..fillCount .. " 信号类型" .. symbolType)
        maxCount = util_max(fillCount, maxCount)
    end

    local topFillCounts = {}
    for colIndex = 1, colNum do
        local reelTopY = reelsTopYs[colIndex]
        local nodeCount = 0
        local parentData = slotParents[colIndex]
        if maxTopY == reelTopY or self:checkColEnterLastReel(colIndex) == true then
            topFillCounts[colIndex] = nodeCount
        else
            local diffDis = maxTopY - reelTopY
            columnData = reelColData[colIndex]
            nodeCount = math.floor(diffDis / columnData.p_showGridH)
            topFillCounts[colIndex] = nodeCount
        end

        --getFillBottomNodeCountWithQuickStop移植过来的函数体
        if self:checkColEnterLastReel(colIndex) == false then
            bottomFileCounts[colIndex] = maxCount -- - bottomFileCounts[i]
        end
        -- release_print("向上补充信息为 " .. index .. " 个数为 = " .. nodeCount )
    end

    local columnFillCounts = {}
    for colIndex = 1, colNum do
        columnFillCounts[colIndex] = topFillCounts[colIndex] + bottomFileCounts[colIndex]
    end
    return columnFillCounts
end

function BaseFastMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            local nodeH = child.p_slotNodeH or self.m_SlotNodeH
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                topY = childY + nodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function BaseFastMachine:getAllSpecialNode()
    -- 自定义特殊块加入连线动画
    local allSpecialNode = {}
    for colIndex = 1, self.m_iReelColumnNum do
        self:foreachSlotParent(
            colIndex,
            function(index, realIndex, slotsNode)
                if slotsNode.m_bInLine == false and slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
                    allSpecialNode[#allSpecialNode + 1] = slotsNode
                end
            end
        )
    end

    --如果为空则从 clipnode获取
    local childs = self.m_clipParent:getChildren()
    local childCount = #childs
    for i = 1, childCount do
        local slotsNode = childs[i]
        if slotsNode.p_layerTag ~= nil then
            if slotsNode.m_bInLine == false and slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
                allSpecialNode[#allSpecialNode + 1] = slotsNode
            end
        end
    end
    return allSpecialNode
end

--触发respin
function BaseFastMachine:triggerReSpinCallFun(endTypes, randomTypes)

    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

--结束移除小块调用结算特效
function BaseFastMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        node:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

return BaseFastMachine
