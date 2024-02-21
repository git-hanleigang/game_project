--单条滚轴控制类
local LuaList = require("common.LuaList")
local ReelControl = class("ReelControl")
ReelControl.m_parentData = nil          --列数据
ReelControl.m_lastDistance = nil        --上次的位置
ReelControl.m_currentDistance = nil     --实时位置
ReelControl.m_reelSchedule = nil        --带子刷新坐标逻辑
ReelControl.m_doneFunc = nil          --通知回调
function ReelControl:ctor()
    self.m_reelScheduleName = "reels.ReelSchedule"
    self.m_reelGridNodeName = "Levels.SlotsNode"
end
--设置滚动lua类名
function ReelControl:setScheduleName(name)
    self.m_reelScheduleName = name
end
--设置格子lua类名
function ReelControl:setGridNodeName(name)
    self.m_reelGridNodeName = name
end
--关卡重写子节点需要用到
function ReelControl:setMachine(machine)
    self.m_machine = machine
end
--初始化控制类
function ReelControl:initData(parentData,configData,columnData,nextDataFunc,doneFunc,updateGridFunc,checkAddSignFunc)
    --列核心控制数据
    self.m_parentData = parentData
    --关卡列配置滚动参数
    self.m_configData = configData
    --列具体数据
    self.m_columnData = columnData
    --列停止回调
    self.m_doneFunc = doneFunc
    --获得下一个小块数据
    self.m_nextDataFunc = nextDataFunc
    --小块数据刷新回调
    self.m_updateGridFunc = updateGridFunc
    self.m_checkAddSignFunc = checkAddSignFunc
    --滚动相关
    self.m_baseNode = parentData.slotParent
    self.m_topNode = parentData.slotParentBig
    self.m_iColIndex = parentData.cloumnIndex
    self.m_iRowNum = parentData.rowNum
    self.m_gridH = parentData.reelHeight/self.m_iRowNum
    self.m_gridCount = self.m_iRowNum+1
    self.m_gridLen = self.m_gridH*self.m_gridCount
    self.m_gridList = LuaList.new()

    --距离计算
    self.m_lastDistance = 0
    self.m_currentDistance = 0
    self.m_originalPos = cc.p(parentData.startX+0.5*parentData.reelWidth,self.m_gridH*0.5)

    --滚动刷帧
    local ReelSchedule = util_require(self.m_reelScheduleName)
    self.m_reelSchedule = ReelSchedule:create()
    self.m_reelSchedule:initData(parentData,configData)

    --控制参数
    self.m_isPerpareStop = nil      --进入停止阶段
    self.m_isNetWorkData = nil      --获得网络数据
    self.m_reelRunInfo = nil        --快停数据
    self.m_stopReelCount = 0        --停止需要经历的格子数量
    self.m_isReelDone = nil         --是否已经停止
    self.m_bigSymbolInfos = self.m_configData.p_bigSymbolTypeCounts --大信号类型
end

--修改滚轴行数
function ReelControl:changeReelRowNum(rowNum,isAddGridNode)
    if self.m_iRowNum == rowNum then
        return
    end
    --之前滚轴真实长度
    local oldCount = self.m_gridCount
    --设置新滚轴长度
    self.m_iRowNum = rowNum
    self.m_gridCount = self.m_iRowNum+1
    self.m_gridLen = self.m_gridH*self.m_gridCount
    --获得差异值
    local offCount = self.m_gridCount-oldCount

    --现有滚动小块
    local list,start,over = self.m_gridList:getList()
    local nodeCount = self.m_gridList:getListCount()

    if offCount<0 then
        --减少
        self.m_gridList:clear()
        for i=start,over do
            if self.m_gridList:getListCount()<self.m_gridCount then
                self.m_gridList:push(list[i])
            else
                self:removeGrideNode(list[i])
            end
        end
    elseif isAddGridNode then
        --新增
        for i=1,offCount do
            local rowIndex = oldCount+i
            local oldNode = list[start+rowIndex-1]
            local newGrid = nil
            if oldNode then
                --已经存在
                newGrid = oldNode
            else
                local fixNode = self.m_machine:getFixSymbol(self.m_iColIndex,rowIndex)
                if self:isSameLayerTag(fixNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE) then
                    newGrid = fixNode
                else
                    --新增
                    newGrid = self:newGridNode(rowIndex)
                    local col = self.m_iColIndex or -1
                    if self.m_isNetWorkData then
                        self:pushSpinLog("changeReelRowNum isNetWorkData = true".." iCol = " .. col)
                    else
                        self:pushSpinLog("changeReelRowNum isNetWorkData = false".." iCol = " .. col)
                    end
                    self:updateNextData()
                    newGrid:updateGrid(true)
                    newGrid:addSelf()
                    self:updateGridNode(newGrid,rowIndex)
                    if self.m_updateGridFunc then
                        self.m_updateGridFunc(newGrid)
                    end
                    if self.m_checkAddSignFunc then
                        self.m_checkAddSignFunc(newGrid)
                    end
                end
            end
            if not newGrid.m_isInitData then
                newGrid:setMachine(self.m_machine)
                newGrid:initData(self.m_parentData,self.m_configData)
            end
            newGrid:setOriginalDistance(self.m_lastDistance+self.m_originalPos.y+(rowIndex-1)*self.m_gridH)
            newGrid:updateDistance(self.m_currentDistance)
        end
    end
end

--增加缓存-兼容老版本防止remove时候报错
function ReelControl:addCacheGrids()
    -- local list,start,over = self.m_gridList:getList()
    -- for i =start,over do
    --     local gridNode = list[i]
    --     if not tolua.isnull(gridNode) then
    --         if gridNode.getReferenceCount and gridNode:getReferenceCount() == 1 then
    --             gridNode:retain()
    --         end
    --     end
    -- end
end
--清除缓存-
function ReelControl:clearCacheGrids()
    local list,start,over = self.m_gridList:getList()
    for i =start,over do
        local gridNode = list[i]
        if not tolua.isnull(gridNode) and gridNode.clearData  then
            gridNode:clearData()
            self:removeGrideNode(gridNode)
        end
    end
    self.m_gridList:clear()
    self.m_reelSchedule:clearData()

    self.m_parentData = nil
    self.m_configData = nil
    self.m_columnData = nil
    self.m_doneFunc = nil
    self.m_nextDataFunc = nil
    self.m_updateGridFunc = nil
    self.m_checkAddSignFunc = nil
    self.m_baseNode = nil
    self.m_topNode = nil
    self.m_iColIndex = nil
    self.m_iRowNum = nil
    self.m_gridH = nil
    self.m_gridCount = nil
    self.m_gridLen = nil
    self.m_gridList = nil
    self.m_lastDistance = nil
    self.m_currentDistance = nil
    self.m_originalPos = nil
    self.m_reelSchedule = nil
    self.m_isPerpareStop = nil
    self.m_reelRunInfo = nil
    self.m_isNetWorkData = nil
    self.m_stopReelCount = nil
    self.m_isReelDone = nil
    self.m_machine = nil
end
--移除所有小块
function ReelControl:removeAllGridNodes()
    local list,start,over = self.m_gridList:getList()
    for i =start,over do
        self:removeGrideNode(list[i])
    end
end
--删除gridnode
function ReelControl:removeGrideNode(gridNode)
    if not tolua.isnull(gridNode) then -- TODO 补丁
        if gridNode.clear ~= nil then
            gridNode:clear()
        end
        if gridNode:getReferenceCountEx() > 1 then
            gridNode:release()
        end
        if gridNode:getParent() ~= nil then
            gridNode:removeFromParent()
        end
    end
end

--添加格子
function ReelControl:initGridList(gridList)
    local list,start,over = self.m_gridList:getList()
    local count = self.m_gridList:getListCount()
    --替换或者新增
    for i=1,self.m_gridCount do
        if gridList and gridList[i] then
            self:updateGridNode(gridList[i],i)
            if self.m_updateGridFunc then
                self.m_updateGridFunc(gridList[i])
            end

            if self.m_checkAddSignFunc then
                self.m_checkAddSignFunc(gridList[i])
            end
        end
    end

    local count = self.m_gridList:getListCount()
    --补块
    local offCount = self.m_gridCount - count
    for i=1,offCount do
        local rowIndex = count+i
        local newGrid = self:newGridNode(rowIndex)
        self:updateNextData()
        newGrid:updateGrid(true)
        newGrid:addSelf()
        self:updateGridNode(newGrid,rowIndex)
        if self.m_updateGridFunc then
            self.m_updateGridFunc(newGrid)
        end
        if self.m_checkAddSignFunc then
            self.m_checkAddSignFunc(newGrid)
        end
    end
    self:resetReelPos()
end
--兼容fastmachine 循环调用
function ReelControl:foreachGridList(func)
    if not func then
        return
    end
    local list,start,over = self.m_gridList:getList()
    for i =start,over do
        local rowIndex = i-start+1
        local node = list[i]
        if func(rowIndex,self.m_iColIndex,node) then
            break
        end
    end
end
--根据索引获得小块
function ReelControl:getGridNode(rowIndex)
    local list,start,over = self.m_gridList:getList()
    local gridNode = list[start+rowIndex-1]
    if not gridNode then
        return nil
    end
    if self.m_topNode and self.m_configData:checkSpecialSymbol(gridNode.p_symbolType)then
        if gridNode:getParent()~= self.m_topNode then
            return nil
        end
    elseif gridNode:getParent()~= self.m_baseNode then
        return nil
    end
    return gridNode
end
--更新滚轴上的小块一般是切换层级
function ReelControl:updateGridNode(gridNode,rowIndex)
    if tolua.isnull(gridNode) then
        return
    end
    if not gridNode.p_rowIndex or gridNode.p_rowIndex~=rowIndex then
        gridNode.p_rowIndex =rowIndex
    end
    local count = self.m_gridList:getListCount()
    local list,start,over = self.m_gridList:getList()
    local oldNode = list[start+rowIndex-1]
    if rowIndex<=count then
        if not tolua.isnull(oldNode) then
            if oldNode ~= gridNode then
                --已经存在并且不相等替换
                list[start+rowIndex-1] = gridNode
                self:removeGrideNode(oldNode)
            end
        else
            --轴上是空的直接赋值
            list[start+rowIndex-1] = gridNode
        end
    elseif rowIndex<=self.m_gridCount then
        --有扩张新增
        self.m_gridList:push(gridNode)
    end
end
--初始化格子
function ReelControl:newGridNode(index)
    local ReelGridNode = util_require(self.m_reelGridNodeName)
    local node = ReelGridNode:create()
    node:setMachine(self.m_machine)
    node:retain()--兼容缓存池
    node:initData(self.m_parentData,self.m_configData)
    --刷新小块数据
    node:setOriginalDistance(self.m_currentDistance+self.m_originalPos.y+(index-1)*self.m_gridH)
    node:updateDistance(self.m_currentDistance)
    return node
end

--是否是指定层级
function ReelControl:isSameLayerTag(node,layerTag)
    if node and node.p_layerTag and node.p_layerTag == layerTag then
        return true
    end
    return false
end

--重置坐标
function ReelControl:resetReelPos()
    self.m_reelSchedule:resetReel()
    local lastNodeList = {}
    local list,start,over = self.m_gridList:getList()
    self.m_gridList:clear()
    for rowIndex=1,self.m_gridCount do
        local listIndex = start+rowIndex-1
        local node = list[listIndex]
        local isNewGrid = false
        -- -- 第一遍先先插有reel上有没有
        if tolua.isnull(node) then
            --这里直接用machine 调用主类方法了、、
            local fixNode = self.m_machine:getFixSymbol(self.m_iColIndex,rowIndex)
            if self:isSameLayerTag(fixNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE) then
                node = fixNode
            end
        end
        --检测是否有轮子被移除
        if not tolua.isnull(node) then
            --respin节点或者在其他地方创建的节点
            if not node.m_isInitData then
                node:setMachine(self.m_machine)
                node:initData(self.m_parentData,self.m_configData)
            end
            if not node.p_rowIndex or node.p_rowIndex~=rowIndex then
                node.p_rowIndex = rowIndex
                isNewGrid = true
            end
            node:updateLayer()
            --固定小块新增
            if not self:isSameLayerTag(node,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE) then
                isNewGrid = true
            end
        else
            isNewGrid = true
        end
        if isNewGrid then
            --添加新节点 这里是否会有抖动
            local newNode = self:newGridNode(rowIndex)
            newNode:addSelf()
            if not tolua.isnull(node) and node.p_symbolType then
                self:copyGridData(node,newNode)
            else
                self:updateNextData()
                newNode:updateGrid(true)
            end
            --被替换的小块存在并且在滚轮中直接移除
            if self:isSameLayerTag(node,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE) then
                self:removeGrideNode(node)
            end
            node = newNode
            if self.m_updateGridFunc then
                self.m_updateGridFunc(newNode)
            end

            if self.m_checkAddSignFunc then
                self.m_checkAddSignFunc(newNode)
            end
        end

        --重置坐标
        node:setOriginalDistance(self.m_currentDistance+self.m_originalPos.y+(rowIndex-1)*self.m_gridH)
        node:resetPosition()
        node:updateDistance(self.m_currentDistance)
        self.m_gridList:push(node)

        --大信号处理
        local symbolType = node.p_symbolType
        local symbolCount = self.m_bigSymbolInfos[symbolType]
        local count = #lastNodeList
        if symbolCount then
            --检测是否存在长条数据
            if count >0 then
                --上一个是长条
                local lastNode = lastNodeList[#lastNodeList]
                if lastNode.p_symbolType == symbolType then
                    --数据相同放入长条数组
                    lastNodeList[#lastNodeList+1]=node
                    if symbolCount == count + 1 then
                        --长条达到最大数量
                        self:createBigSymbol(lastNodeList)
                        lastNodeList = {}
                    end
                else
                    --是不是一个长条 根据已有数据创建长条
                    self:createBigSymbol(lastNodeList)
                    --清空长条数据
                    lastNodeList = {}
                    --是首个长条
                    lastNodeList[1]=node
                end
            else
                --没有长条数据是首个长条
                lastNodeList[1]=node
            end
        else
            --不是长条检测之前是否存在长条数据
            if count >0 then
                --创建长条信息
                self:createBigSymbol(lastNodeList)
                lastNodeList = {}
            end
        end
    end
    self:createBigSymbol(lastNodeList,true)
end

function ReelControl:createBigSymbol(nodeList,isLast)
    if not nodeList or #nodeList == 0 then
        return
    end
    local count = #nodeList
    local symbolType = nodeList[count].p_symbolType
    local maxCount = self.m_bigSymbolInfos[symbolType]
    for i=1,count do
        local node = nodeList[i]
        local index = nil
        if isLast then
            index = i
        else
            index = i+maxCount-count
        end
        node:updateBigSymbolInfo(index,-self.m_gridH*(index-1),maxCount)
        if i~=1 then
            node:setVisible(false)
        end
    end
end

--拷贝节点
function ReelControl:copyGridData(curNode,targetNode)
    targetNode.p_cloumnIndex =curNode.p_cloumnIndex
    targetNode.p_rowIndex =curNode.p_rowIndex
    targetNode.m_isLastSymbol =curNode.m_isLastSymbol
    targetNode.p_slotNodeH =curNode.p_slotNodeH
    targetNode.p_symbolType =curNode.p_symbolType
    targetNode.p_preSymbolType =curNode.p_preSymbolType
    targetNode.p_showOrder =curNode.p_showOrder
    targetNode.p_reelDownRunAnima =curNode.p_reelDownRunAnima
    targetNode.p_reelDownRunAnimaSound =curNode.p_reelDownRunAnimaSound
    targetNode.p_layerTag =curNode.p_layerTag
    targetNode:initSlotNodeByCCBName(curNode.m_ccbName,curNode.p_symbolType)
    targetNode:setLocalZOrder(curNode:getLocalZOrder())
    targetNode:setTag(curNode:getTag())
    -- curNode:reset()
    -- curNode:resetReelStatus()
end
--开始滚动
function ReelControl:beginReel()
    self.m_lastDistance = 0
    self.m_currentDistance = 0
    self.m_isPerpareStop = nil
    self.m_reelRunInfo = nil
    self.m_isNetWorkData = nil
    self.m_isReelDone = nil
    self:resetReelPos()
    self.m_reelSchedule:beginReelRun()
end
--快滚
function ReelControl:reelLongRun()
    self.m_reelSchedule:reelLongRun()
end
--刷新滚动
function ReelControl:updateReel(dt)
    if self.m_isReelDone then
        return
    end
    
    self.m_reelSchedule:updateReel(dt)
    self.m_currentDistance = self.m_reelSchedule:getCurrentDistance()
    local list,start,over = self.m_gridList:getList()
    for i =start,over do
        local gridNode = list[i]
        if gridNode and gridNode.updateDistance then
            gridNode:updateDistance(self.m_currentDistance)
        end
    end
    self:updateGrid()
    if self.m_reelSchedule:isReelDone() then
        self.m_isReelDone = true
        if self.m_doneFunc then
            self.m_doneFunc(self.m_parentData)
        end
    end
end
--刷新小块坐标
function ReelControl:updateGrid()
    self:checkNormalStopReel()
    if self.m_currentDistance-self.m_lastDistance>=self.m_gridH then
        --刷新信号
        self.m_lastDistance = self.m_lastDistance+self.m_gridH
        local gridNode = self.m_gridList:pop() --挪动中信号
        local list,start,over = self.m_gridList:getList()
        local lastNode = list[over] --顶部信号
        local firstNode = list[start] --底部信号
        --节点在关卡中被移除了、
        if tolua.isnull(gridNode) or not gridNode or not gridNode.updateGrid then
            return
        end

        -- local index,pos,count = lastNode:getBigSymbolInfo()
        self:updateNextData()
        -- if not self.m_parentData.m_isLastSymbol then
        --     if index and index ~= count then
        --         --补齐大信号
        --         self.m_parentData.symbolType = lastNode.p_symbolType
        --     end
        -- end
        gridNode:updateGrid()
        -- --大信号检测
        -- local symbolCount = self.m_bigSymbolInfos[gridNode.p_symbolType]
        -- if symbolCount then
        --     --大信号
        --     if gridNode.p_symbolType == lastNode.p_symbolType then
        --         local index,pos,count = lastNode:getBigSymbolInfo()
        --         if index and index ~= symbolCount then
        --             --非首个延续上一个参数+1
        --             gridNode:updateBigSymbolInfo(index+1,pos-self.m_gridH,symbolCount)
        --             gridNode:setVisible(false)
        --         else
        --             --已满开新的大图
        --             gridNode:updateBigSymbolInfo(1,0,symbolCount)
        --         end
        --     else
        --         --新的大图
        --         gridNode:updateBigSymbolInfo(1,0,symbolCount)
        --     end
        -- end
        if self.m_updateGridFunc then
            self.m_updateGridFunc(gridNode)
        end

        if self.m_checkAddSignFunc then
            self.m_checkAddSignFunc(gridNode)
        end
        gridNode:setOriginalDistance(gridNode:getOriginalDistance()+self.m_gridLen)
        gridNode:updateDistance(self.m_currentDistance)
        self.m_gridList:push(gridNode)
        -- --底部大信号显示检测
        -- if firstNode.m_bigSymbolIndex then
        --     firstNode:setVisible(true)
        -- end
        --快停和下一个信号检测
        if self.m_currentDistance-self.m_lastDistance>=self.m_gridH then
            return self:updateGrid()
        end
    end
end
--获得网络数据刷新最终停止距离剩余小块数量
function ReelControl:perpareStopReel(stopReelCount)
    self.m_stopReelCount = stopReelCount
    self.m_isPerpareStop = true
end

--检测停止距离
function ReelControl:checkNormalStopReel()
    if self.m_reelRunInfo then
        if not self.m_reelSchedule:isReelDone() then
            self.m_reelSchedule:reelDone()
            self:resetQuickStopReel(self.m_reelRunInfo)
            self.m_reelRunInfo = nil
            return
        else
            self.m_reelRunInfo = nil
        end
    end
    --正常停止
    if self.m_isPerpareStop then
        self.m_isPerpareStop = nil
        self.m_isNetWorkData = true
        local offDistance = self.m_currentDistance-self.m_lastDistance
        local moveDistance = (self.m_stopReelCount-self.m_columnData.p_showGridCount+self.m_gridCount)* self.m_gridH
        local targetDistance = moveDistance - offDistance
        self.m_reelSchedule:reelMoveDistance(targetDistance)
    end
end
--是否已经停止开始回弹
function ReelControl:isReelDone()
    return self.m_reelSchedule:isReelDone()
end
--快停
function ReelControl:quickStopReel(reelRunInfo)
    self.m_reelRunInfo = reelRunInfo
end
--重置快停位置
function ReelControl:resetQuickStopReel(reelRunInfo)
    self.m_lastDistance = 0
    self.m_currentDistance = 0
    self.m_isPerpareStop = nil
    self.m_isNetWorkData = true
    self.m_isReelDone = true
    --数据没有替换完成就替换一遍
    self.m_parentData.isLastNode = false
    self.m_parentData.lastReelIndex = reelRunInfo:getReelRunLen()
    local list,start,over = self.m_gridList:getList()
    for i =start,over do
        local rowIndex = i-start+1
        self:updateNextData()
        local node = list[i]
        node:updateGrid()
        if self.m_updateGridFunc then
            self.m_updateGridFunc(node)
        end
        if self.m_checkAddSignFunc then
            self.m_checkAddSignFunc(node)
        end
        node:setOriginalDistance(self.m_originalPos.y+(rowIndex-1)*self.m_gridH)
        node:updateDistance(0)
    end
    if self.m_doneFunc then
        self.m_doneFunc(self.m_parentData)
    end
end
--下一个格子数据
function ReelControl:updateNextData(isRandomData)
    self.m_nextDataFunc(self.m_iColIndex,self.m_isNetWorkData)
end

--关卡输出打印
function ReelControl:pushSpinLog(strLog)
    if not strLog or not self.m_machine or not self.m_machine.pushSpinLog then
        return
    end
    self.m_machine:pushSpinLog(strLog)
end
return ReelControl