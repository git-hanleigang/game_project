--新滚动类
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseNewReelMachine = class("BaseNewReelMachine", BaseSlotoManiaMachine)
BaseNewReelMachine.m_nextGrideData = nil --下一个小块数据
BaseNewReelMachine.m_initGridNode = nil --初始化节点标识
function BaseNewReelMachine:initData_(...)
    BaseSlotoManiaMachine.initData_(self, ...)
end
--注意如果关卡内重写过 需要检查修改的函数列表
--[[
    --特别注意 如果特殊玩法小块重叠 在随机轮盘前面添加self:removeAllGridNodes()
    getSlotNodeWithPosAndType,--重写updateReelGridNode(node)--刷新小块通知，例如小块上挂件和分数刷新 子类继承(原setSpecialNodeScore方法类似)
    initCloumnSlotNodesByNetData,randomSlotNodes,randomSlotNodesByReel --初始化次轮盘注意是否调用self.m_initGridNode = true,self:initGridList()
    
    比较频繁改动的
    reelSchedulerCheckColumnReelDown,--回弹按下
    setReelRunInfo,--快滚-- setBonusScatterInfo小块提示
    
    removeRespinNode,--respin结束baseMachine拆分重写了注意一下
    --mini轮盘经常继承
    operaNetWorkData, --获得网络数据

    --关卡重写比较少的方法
    createResNode, --创建顶部小块
    clearSlotNodes,--清除小块
    getSymbolCCBNameByType,--获得ccb名字
    updateReelInfoWithMaxColumn,--刷新行列信息
    checkRestSlotNodePos,--重置parentdata
    reelSchedulerHanlder,--滚动
    MachineRule_BackAction,--回弹弹起
    beginReel,--开始滚动
    operaQuicklyStopReel,--快停
    setLastReelSymbolList,--封装最后停止数据
    produceReelSymbolList,--封装期间数据
    createSlotNextNode,--获得下一个数据
    checkReelIndexReason,--检查大信号
    
    --新增方法
    self:updateReelGridNode(node)--刷新小块通知，例如小块上挂件和分数刷新 子类继承(原setSpecialNodeScore方法类似)
    self:changeReelRowNum(colIndex,rowNum,isAddGridNode)--改变列的高度(根据行数)小矮仙玛雅吸血鬼在使用
    self:changeReelDownAnima(parentData)--改变下落提示音乐动画
    self:addReelDownTipNode(nodes)--修改下落提示节点逻辑
    self:playReelDownTipNode(slotNode)--播放提示动画
    self:changeBaseParent(slotNode)--裁切层小块放回滚轴要调用这个(覆盖轮盘中现有小块方法)
    self:removeAllGridNodes() --重新初始化盘面前调用 防止小块重叠
]]
--获得单列控制类
function BaseNewReelMachine:getBaseReelControl()
    return "reels.ReelControl"
end
--滚动
function BaseNewReelMachine:getBaseReelSchedule()
    return "reels.ReelSchedule"
end

--增加缓存
function BaseNewReelMachine:initCacheGrids()
    for i=1,#self.m_reels do
        self.m_reels[i]:addCacheGrids()
    end
end
--清除缓存
function BaseNewReelMachine:clearNewCaches()
    self.m_nextGrideData = nil --下一个小块数据
    self.m_initGridNode = nil --初始化节点标识
    for i=1,#self.m_reels do
        self.m_reels[i]:clearCacheGrids()
    end
    self.m_reels = nil
end

--移除盘面所有小块 重新初始化盘面使用 防止小块重叠
function BaseNewReelMachine:removeAllGridNodes()
    for i=1,#self.m_reels do
        self.m_reels[i]:removeAllGridNodes()
    end
end
--获得滚轴上的小块（不包含固定在轮盘上层的小块）获得固定的需要getFixSymbol
function BaseNewReelMachine:getReelGridNode(col,row)
    return self.m_reels[col]:getGridNode(row)
end
--获得新小快
function BaseNewReelMachine:makeReelGridNode(col,row)
    return self.m_reels[col]:newGridNode(row)
end
--覆盖reel里面的小块
function BaseNewReelMachine:setReelGridNode(node,col,row)
    return self.m_reels[col]:updateGridNode(node,row)
end
--刷新小块通知，例如小块上挂件和分数刷新 子类继承(原setSpecialNodeScore方法类似)
function BaseNewReelMachine:updateReelGridNode(node)
    -- if node.p_symbolType == "xxxxxxxxx" then
    --     self:setSpecialNodeScore(self,{node})
    -- end
end
--改变列的高度(根据行数)
function BaseNewReelMachine:changeReelRowNum(colIndex,rowNum,isAddGridNode)
    self.m_reels[colIndex]:changeReelRowNum(rowNum,isAddGridNode)
end
--下一列数据
function BaseNewReelMachine:createNextGrideData(colIndex,isNetWork)
    local parentData = self.m_slotParents[colIndex]
    
    --如果没有假滚轴初始化一个
    if not parentData.reelDatas then
        local reelDatas = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
            if not reelDatas then
                reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
            end
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        end
        if parentData.beginReelIndex == nil then
            parentData.beginReelIndex = util_random(1, #reelDatas)
        end
        parentData.reelDatas = reelDatas
        self:checkReelIndexReason(parentData)
    end
   
    if isNetWork then
        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            parentData.isReeling = false
            self:createResNode(parentData)
        else
            self:createSlotNextNode(parentData)
        end
    else
        self:getReelDataWithWaitingNetWork(parentData)
    end
    parentData.ccbName = self:getSymbolCCBNameByType(self, parentData.symbolType)
end
--随机信号
function BaseNewReelMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end
--初始化带子（放在drawReelArea()绘制裁切区域之后）
function BaseNewReelMachine:initReelControl()
    local ReelControl = util_require(self:getBaseReelControl())
    self.m_reels = {}
    for i=1,self.m_iReelColumnNum do
        local parentData = self.m_slotParents[i]
        parentData.reelWidth = self.m_fReelWidth
        parentData.reelHeight = self.m_fReelHeigth
        parentData.slotNodeW = self.m_fReelWidth
        parentData.slotNodeH = self.m_fReelHeigth / self.m_iReelRowNum
        local reel = ReelControl:create()
        --设置格子lua类名
        reel:setScheduleName(self:getBaseReelSchedule())
        reel:setGridNodeName(self:getBaseReelGridNode())
        --关卡slotNode重写需要用到
        reel:setMachine(self)
        --初始化
        reel:initData(parentData,self.m_configData,self.m_reelColDatas[i],handler(self,self.createNextGrideData),handler(self,self.reelSchedulerCheckColumnReelDown),handler(self,self.updateReelGridNode),handler(self,self.checkAddSignOnSymbol))
        self.m_reels[i] = reel
    end
end
--初始化格子列表（放在关卡初始化轮盘之后）
function BaseNewReelMachine:initGridList(isFirstNoramlReel)
    self.m_initGridNode = nil
    for i=1,#self.m_reels do
        local gridList = {}
        for j=1,self.m_reels[i].m_iRowNum do
            if isFirstNoramlReel then
                local symbolNode = self:getReelParentChildNode(i,j)
                if not symbolNode then
                    symbolNode = self:getFixSymbol(i,j)
                end
                gridList[j]= symbolNode
            else
                gridList[j]= self:getFixSymbol(i,j)
            end
        end
        self.m_reels[i]:initGridList(gridList)
    end
    self:initCacheGrids()
end

--新滚动调用(放在beginReel()之后）
function BaseNewReelMachine:beginNewReel()
    self.m_isNewReelQuickStop = nil
    self.m_quickStopReelIndex = nil
    for i=1,#self.m_reels do
        self.m_reels[i]:beginReel()
    end
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end
--接收到网路数据
function BaseNewReelMachine:perpareStopReel()
    for i=1,#self.m_reels do
        self.m_reels[i]:perpareStopReel(self.m_reelRunInfo[i]:getReelRunLen())
        local parentData = self.m_slotParents[i]
        local columnData = self.m_reelColDatas[i]
        parentData.lastReelIndex = columnData.p_showGridCount -- 从最初起始开始滚动
    end
    -- dump(self.m_stcValidSymbolMatrix,"spin-result",2)
end
--拷贝节点
-- function BaseNewReelMachine:copyGridData(curNode,targetNode)
--     targetNode.p_cloumnIndex =curNode.p_cloumnIndex
--     targetNode.p_rowIndex =curNode.p_rowIndex
--     targetNode.m_isLastSymbol =curNode.m_isLastSymbol
--     targetNode.p_slotNodeH =curNode.p_slotNodeH
--     targetNode.p_symbolType =curNode.p_symbolType
--     targetNode.p_preSymbolType =curNode.p_preSymbolType
--     targetNode.p_showOrder =curNode.p_showOrder
--     targetNode.p_reelDownRunAnima =curNode.p_reelDownRunAnima
--     targetNode.p_reelDownRunAnimaSound =curNode.p_reelDownRunAnimaSound
--     targetNode.p_layerTag =curNode.p_layerTag
--     targetNode:initSlotNodeByCCBName(curNode.m_ccbName,curNode.p_symbolType)
--     targetNode:setLocalZOrder(curNode:getLocalZOrder())
--     targetNode:setTag(curNode:getTag())
-- end
-------------------------------------------baseMachine-----------------------------------
function BaseNewReelMachine:setLastReelSymbolList()
    -- BaseSlotoManiaMachine.setLastReelSymbolList(self)
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        parentData.fillCount = 0
        local cloumnIndex = parentData.cloumnIndex
        local symbolType = self:getSymbolTypeForNetData(cloumnIndex,1)
        local maxCount = self.m_bigSymbolInfos[symbolType]
        if maxCount ~= nil then
            local columnData = self.m_reelColDatas[cloumnIndex]
            local rowCount = columnData.p_showGridCount
            local bigCount = 1
            for index = 2,rowCount do
                if symbolType == self:getSymbolTypeForNetData(cloumnIndex,index) then
                    bigCount = bigCount+1
                else
                    break
                end
            end
            if bigCount>maxCount then
                bigCount = bigCount%maxCount
            end
            parentData.fillCount = maxCount-bigCount
        end
    end
end

function BaseNewReelMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end
--重写获取真实数据
function BaseNewReelMachine:getSymbolTypeForNetData(iCol, iRow, iLen)
    return self.m_stcValidSymbolMatrix[iRow][iCol]
end
function BaseNewReelMachine:produceReelSymbolList()
end
-- function BaseMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
function BaseNewReelMachine:checkReelIndexReason(parentData)
    local cloumnIndex = parentData.cloumnIndex
    local columnData = self.m_reelColDatas[cloumnIndex]
    local symbolType = self:getSymbolTypeForNetData(cloumnIndex,columnData.p_showGridCount)
    local maxCount = self.m_bigSymbolInfos[symbolType] or 0
    local nextSymbolType = parentData.reelDatas[parentData.beginReelIndex]
    local nextCount = self.m_bigSymbolInfos[nextSymbolType] or 0
    if maxCount>0 or nextCount>0 then
        local breakIndex = 0
        local count = math.max(maxCount,nextCount)
        local curCount = 0
        local lastIndex = parentData.beginReelIndex
        while true do
            lastIndex = lastIndex + 1
            if lastIndex > #parentData.reelDatas then
                lastIndex = 1
            end
            symbolType = parentData.reelDatas[lastIndex]
            if self.m_bigSymbolInfos[symbolType]~=nil then
                curCount = curCount+1
            end
            if curCount>=count then
                break
            end
            breakIndex = breakIndex +1
            if breakIndex>#parentData.reelDatas then
                break
            end
        end
        parentData.beginReelIndex = lastIndex
    end
end
function BaseNewReelMachine:createSlotNextNode(parentData)
    if self.m_isWaitingNetworkData == true then
        -- 等待网络数据返回时， 还没开始滚动真信号，所以肯定为false 2018-12-15 18:15:51
        parentData.m_isLastSymbol = false
        self:getReelDataWithWaitingNetWork(parentData)
        return
    end
    parentData.lastReelIndex = parentData.lastReelIndex + 1
    local cloumnIndex = parentData.cloumnIndex
    local columnData = self.m_reelColDatas[cloumnIndex]
    local nodeCount = self.m_reelRunInfo[cloumnIndex]:getReelRunLen()
    if parentData.lastReelIndex<=nodeCount or parentData.lastReelIndex>nodeCount+columnData.p_showGridCount then
        if parentData.fillCount and parentData.fillCount>0 and parentData.lastReelIndex>=nodeCount-parentData.fillCount then
            --大信号补块
            parentData.m_isLastSymbol = false
            parentData.symbolType = self:getSymbolTypeForNetData(cloumnIndex,1)
        else
            parentData.m_isLastSymbol = false
            self:getReelDataWithWaitingNetWork(parentData)
        end
        local symbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if symbolCount then
            if parentData.fillCount then
                symbolCount = symbolCount + parentData.fillCount
            end
            if parentData.lastReelIndex + symbolCount >nodeCount then
                --假滚轴大信号覆盖到了真数据重新获取数据
                local symbolType = self:getReelSymbolType(parentData)
                local breakIndex = 0
                while self.m_bigSymbolInfos[symbolType] do
                    symbolType = self:getReelSymbolType(parentData)
                    breakIndex = breakIndex +1
                    if breakIndex>=10 then
                        --理论不会报错 预防一下
                        break
                    end
                end
                parentData.symbolType = symbolType
            end
        end
        return
    end
    parentData.fillCount = 0
    local columnRowNum = columnData.p_showGridCount
    parentData.rowIndex = parentData.lastReelIndex-nodeCount
    local symbolType = self:getSymbolTypeForNetData(cloumnIndex,parentData.rowIndex)
    local showOrder = self:getBounsScatterDataZorder(symbolType)
    parentData.symbolType = symbolType
    parentData.order = showOrder - parentData.rowIndex
    parentData.tag = cloumnIndex * SYMBOL_NODE_TAG + parentData.rowIndex

    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    if parentData.rowIndex == columnRowNum then --self.m_iReelRowNum then
        parentData.isLastNode = true
    end
    parentData.m_isLastSymbol = true
    self:changeReelDownAnima(parentData)
end
--改变下落音效
function BaseNewReelMachine:changeReelDownAnima(parentData)
    -- parentData.reelDownAnima = "buling"
    -- parentData.reelDownAnimaSound = "test.mp3"
end
--顶部补块
function BaseNewReelMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    parentData.symbolType = symbolType
    if self.m_bigSymbolInfos[symbolType] ~= nil then
        parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    else
        parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    end
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end
--重新清理
function BaseNewReelMachine:clearSlotNodes()
    self:clearNewCaches()
    BaseSlotoManiaMachine.clearSlotNodes(self)
end
--获得名字
function BaseNewReelMachine:getSymbolCCBNameByType(MainClass, symbolType)
    if not self.m_namePools then
        self.m_namePools = {}
    end
    if self.m_namePools[symbolType] then
        return self.m_namePools[symbolType]
    else
        local ccbName = BaseSlotoManiaMachine.getSymbolCCBNameByType(self,MainClass, symbolType)
        self.m_namePools[symbolType] = ccbName
        return ccbName
    end
end

function BaseNewReelMachine:operaNetWorkData()
    self:dealSmallReelsSpinStates()
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end
--绘制多个裁切区域
function BaseNewReelMachine:updateReelInfoWithMaxColumn()
    BaseSlotoManiaMachine.updateReelInfoWithMaxColumn(self)
    self:initReelControl()
end
--大信号处理
function BaseNewReelMachine:checkRestSlotNodePos()
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for i=1,#newChilds do
                childs[#childs+1]=newChilds[i]
            end
        end
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    local posWorld = slotParent:convertToWorldSpace(cc.p(childNode:getPosition()))
                    local pos = self.m_clipParent:convertToNodeSpace(posWorld)
                    util_changeNodeParent(self.m_clipParent,childNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                    childNode:setPosition(cc.p(pos.x, pos.y))
                end
            end
        end
        parentData:reset()
    end
end
--重写滚动刷帧
function BaseNewReelMachine:reelSchedulerHanlder(dt)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or self:checkGameRunPause() then
        return
    end
    local isAllReelDone = function()
        for index = 1, #self.m_slotParents do
            if self.m_slotParents[index].isResActionDone == false then
                return false
            end
        end
        return true
    end
    for i=1,#self.m_reels do
        self.m_reels[i]:updateReel(dt)
    end
    if isAllReelDone() == true then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        self:slotReelDown()
        self.m_reelDownAddTime = 0
    end
end
--重写列停止
function BaseNewReelMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()
        local slotParentBig = parentData.slotParentBig 
        if slotParentBig then
            slotParentBig:stopAllActions()
        end
        self:slotOneReelDown(parentData.cloumnIndex)
        local speedActionTable = nil
        local addTime = nil
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        if self.m_isNewReelQuickStop then
            slotParent:setPositionY(quickStopY)
            if slotParentBig then
                slotParentBig:setPositionY(quickStopY)
            end
            speedActionTable = {}
            speedActionTable[1], addTime = self:MachineRule_BackAction(slotParent, parentData)
        else
            speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
        end
        if slotParentBig then
            local seq = cc.Sequence:create(speedActionTable)
            slotParentBig:runAction(seq:clone())
        end
        local tipSlotNoes = nil
        local nodeParent = parentData.slotParent
        local nodes = nodeParent:getChildren()
        if slotParentBig then
            local nodesBig = slotParentBig:getChildren()
            for i=1,#nodesBig do
                nodes[#nodes+1]=nodesBig[i]
            end
        end

        -- 播放配置信号的落地音效
        self:playSymbolBulingSound(nodes)
        -- 播放配置信号的落地动效
        self:playSymbolBulingAnim(nodes, speedActionTable)

        --添加提示节点
        tipSlotNoes = self:addReelDownTipNode(nodes)
 
        if tipSlotNoes ~= nil then
            local nodeParent = parentData.slotParent
            for i = 1, #tipSlotNoes do
                --播放提示动画
                self:playReelDownTipNode(tipSlotNoes[i])
            end -- end for
        end

        self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

        local actionFinishCallFunc = cc.CallFunc:create(
        function()
            parentData.isResActionDone = true
            if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                self:newQuickStopReel(self.m_quickStopReelIndex)
            end
            self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
        end)

        
        speedActionTable[#speedActionTable + 1] = actionFinishCallFunc
        slotParent:runAction(cc.Sequence:create(speedActionTable))
    end
    return 0.1
end


--增加提示节点
function BaseNewReelMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then

            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            
            if self:checkSymbolTypePlayTipAnima( slotNode.p_symbolType )then
                
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex,slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            --                            break
            end
        --                        end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end
--播放提示动画
function BaseNewReelMachine:playReelDownTipNode(slotNode)

    self:playScatterBonusSound(slotNode)
    slotNode:runAnim("buling")
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end
--重写回弹
function BaseNewReelMachine:MachineRule_BackAction(slotParent, parentData)
    local back = cc.MoveTo:create(self.m_configData.p_reelResTime, cc.p(slotParent:getPositionX(), 0))
    return back, self.m_configData.p_reelResTime
end
-- --重写获取节点
-- function BaseNewReelMachine:getSlotNodeWithPosAndType( symbolType , row, col , isLastSymbol)
--     if not self.m_initGridNode then
--         --兼容fastmachine关卡
--         local symblNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self,symbolType , row, col , isLastSymbol)
--         self:setSlotCacheNodeWithPosAndType(symblNode, symbolType, row, col, isLastSymbol)
--         return symblNode
--     end
--     --获取新节点
--     if isLastSymbol == nil then
--         isLastSymbol = false
--     end
--     --检查节点是否存在
--     local symblNode = self:getReelGridNode(col,row)
--     if not symblNode then
--         --不存在创建新的
--         symblNode = self:makeReelGridNode(col,row)
--     end
--     if symblNode and symblNode.setMachine then
--         symblNode:setMachine(self)
--     end
--     local ccbName = self:getSymbolCCBNameByType(self, symbolType)
--     symblNode:initSlotNodeByCCBName(ccbName, symbolType)
--     self:setSlotCacheNodeWithPosAndType(symblNode, symbolType, row, col, isLastSymbol)
--     return symblNode
-- end
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function BaseNewReelMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do
        local columnData = self.m_reelColDatas[colIndex]

        local rowCount,rowNum,rowIndex = self:getinitSlotRowDatatByNetData(columnData )

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            -- node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:runIdleAnim()      
            rowIndex = rowIndex - 1
        end  -- end while
    end
    self:initGridList()
end
-- --随机轮盘
-- function BaseNewReelMachine:initRandomSlotNodes()
--     --初始化节点
--     self.m_initGridNode = true
--     BaseSlotoManiaMachine.initRandomSlotNodes(self)
--     self:initGridList()
-- end
--开始滚动
function BaseNewReelMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)
    self:beginNewReel()
end

--裁切层小块放回滚轴要调用这个(覆盖轮盘中现有小块方法)
function BaseNewReelMachine:changeBaseParent(slotNode)
    BaseSlotoManiaMachine.changeBaseParent(self,slotNode)
    if tolua.isnull(slotNode) then
        return
    end
    self:setReelGridNode(slotNode,slotNode.p_cloumnIndex,slotNode.p_rowIndex)
end

function BaseNewReelMachine:quicklyStopReel(colIndex)
    self:operaQuicklyStopReel()
end

--快停
function BaseNewReelMachine:operaQuicklyStopReel()
    if self.m_quickStopReelIndex then
        return
    end
    --有停止并且未回弹的停止快停
    self.m_quickStopReelIndex = nil
    for i=1,#self.m_reels do
        if self.m_reels[i]:isReelDone() then
            self.m_quickStopReelIndex = i
        end
    end
    if not self.m_quickStopReelIndex then
        self:newQuickStopReel(1)
    end
end
--新快停逻辑
function BaseNewReelMachine:newQuickStopReel(index)
    if self.m_isNewReelQuickStop then
        return
    end
    self:setGameSpinStage( QUICK_RUN ) -- 已经处于快速停止状态了。。
    self.m_isNewReelQuickStop = true
    self.m_quickStopReelIndex = nil
    if index>#self.m_reels then
        return
    end
    for i=index,#self.m_reels do
        self.m_reels[i]:quickStopReel(self.m_reelRunInfo[i])
    end
end
---------------------------------------fastmachine 防止报错这里先重写一下----------------------------------
--获取缓存节点
function BaseNewReelMachine:getCacheNode(colIndex,symbolType)
    return nil
end
--清空缓存资源
function BaseNewReelMachine:clearCacheMap()
end
--设置节点属性
function BaseNewReelMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    node.p_rowIndex = row
    node.p_cloumnIndex = col
    node.p_symbolType = symbolType
    node.m_isLastSymbol = isLastSymbol or false
end

function BaseNewReelMachine:foreachSlotParent(colIndex, callBack)
    self.m_reels[colIndex]:foreachGridList(callBack)
end

--补丁找不到在新滚动里面查找
function BaseNewReelMachine:getFixSymbol(iCol, iRow, iTag)
    local fixSp = BaseSlotoManiaMachine.getFixSymbol(self,iCol, iRow, iTag)
    if not fixSp then
        fixSp = self:getReelGridNode(iCol,iRow)
    end
    return fixSp
end
-- --弃用缓存方式
function BaseNewReelMachine:pushSlotNodeToPoolBySymobolType(symbolType, gridNode)
    --清除可能记录的缓存信息
    gridNode.p_cloumnIndex = nil
    gridNode.p_rowIndex = nil
    gridNode.m_isInitData = nil
    gridNode.m_parentData = nil
    gridNode.m_configData = nil
    gridNode.m_baseNode = nil
    gridNode.m_topNode = nil
    gridNode.m_originalPos = nil
    gridNode.m_isInTop = nil
    BaseSlotoManiaMachine.pushSlotNodeToPoolBySymobolType(self,symbolType, gridNode)
    -- if not tolua.isnull(gridNode) then -- TODO 补丁
    --     if gridNode.clear ~= nil then
    --         gridNode:clear()
    --     end
    --     if gridNode:getReferenceCount() > 1 then
    --         gridNode:release()
    --     end
    --     if gridNode:getParent() ~= nil then
    --         gridNode:removeFromParent()
    --     end
    -- end
end

return BaseNewReelMachine