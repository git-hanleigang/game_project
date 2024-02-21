--[[
    基础respin
]]
local BaseRespinView = class("BaseRespinView", util_require("base.BaseView"))

BaseRespinView.m_symbolTypeEnd = nil        --落地的小块类型
BaseRespinView.m_symbolRandomType = nil     --随机信号数组

BaseRespinView.m_machineElementData = nil  --初始化repsin盘面时信息
BaseRespinView.m_machineRow = nil             --关卡轮盘行数
BaseRespinView.m_machineColmn = nil           --关卡轮盘列数
BaseRespinView.m_startCallFunc = nil           --开始转动喊数
BaseRespinView.m_respinTouchStatus = nil        --当前状态机
BaseRespinView.m_storedNodeInfo = nil           --固定小块的信息
BaseRespinView.m_unStoredNodeInfo = nil           --非固定小块的信息
--滚动状态
GD.ENUM_TOUCH_STATUS = {
    UNDO = 1,       ---等待状态 不允许点击
    ALLOW = 2,      ---允许点击
    WATING = 3, --等待滚动
    RUN = 4,        ---滚动状态
    QUICK_STOP = 5, ---快滚状态
}


--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

local MOVE_SPEED = 1500     --滚动速度 像素/每秒

local BASE_LOCK_ZODER       =       1000        --锁定小块基础层级



function BaseRespinView:ctor(respinNodeName)
    BaseRespinView.super.ctor(self,respinNodeName)
    self.m_respinNodeName = respinNodeName

    --停轮音效
    self.m_reelDownSounds = {}

    --落地音效
    self.m_symbolDownSounds = {}

    --快滚状态
    self.m_quickRunStatus = false

    --是否已经有bonus图标开始落地(重置respin次数用)
    self.m_isBonusDown = false

    --假滚类型(是否随机小块类型)
    self.m_isRandomSymbol = true

    --当前剩余spin次数
    self.m_reSpinCurCount = 3

    --裁切层方式(默认整行裁切)
    self.m_clipType = RESPIN_CLIPTYPE.COMBINE

    self.m_clipNodes = {}

    self:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
end

function BaseRespinView:onExit()
    BaseRespinView.super.onExit(self)
end

--[[
    设置假滚类型(是否随机小块类型)
]]
function BaseRespinView:setRunType(isRandom)
    self.m_isRandomSymbol = isRandom
end

--[[
    变更状态机
]]
function BaseRespinView:changeTouchStatus(touchStatus)
    self.m_respinTouchStatus = touchStatus
end

--[[
    获取状态机
]]
function BaseRespinView:getouchStatus()
    return self.m_respinTouchStatus
end

--[[
    设置裁切方式(需要在initRespinElement前调用)
]]
function BaseRespinView:changClipType(clipType)
    self.m_clipType = clipType
end

--[[
    获取裁切方式
]]
function BaseRespinView:getClipType()
    return self.m_clipType
end

function BaseRespinView:setMachine(machine)
    self.m_machine = machine
end

--传入高亮类型 随机类型
function BaseRespinView:setEndSymbolType(symbolTypeEnd, symbolRandomType)
    self.m_symbolTypeEnd = symbolTypeEnd
    self.m_symbolRandomType = symbolRandomType 
end

--[[
    设置停轮数据
]]
function BaseRespinView:setRunEndData(storedNodeInfo,unStoredNodeInfo)
    self.m_storedNodeInfo = storedNodeInfo
    self.m_unStoredNodeInfo = unStoredNodeInfo
end

--[[
    获取respinNode索引
]]
function BaseRespinView:getRespinNodeIndex(colIndex, rowIndex)
    return self.m_machine.m_iReelRowNum - rowIndex + 1 + (colIndex - 1) * self.m_machine.m_iReelRowNum
end

--[[
    根据行列获取respinNode
]]
function BaseRespinView:getRespinNodeByRowAndCol(colIndex, rowIndex)
    local respinNodeIndex = self:getRespinNodeIndex(colIndex,rowIndex)
    local respinNode = self.m_respinNodes[respinNodeIndex]
    return respinNode
end

--[[
    根据行列获取小块
]]
function BaseRespinView:getSymbolByRowAndCol(col,row)
    local respinNode = self:getRespinNodeByRowAndCol(col,row)
    return respinNode:getBaseShowSymbol()
end

--[[
    获取停轮的数据类型
]]
function BaseRespinView:getEndSymbolType(respinNode)
    if self.m_storedNodeInfo then
        for index = 1, #self.m_storedNodeInfo do
            local data = self.m_storedNodeInfo[index]
            if respinNode.m_colIndex == data.iY and respinNode.m_rowIndex == data.iX then
                return data.type
            end
        end
    end
    
    if self.m_unStoredNodeInfo then
        for index = 1, #self.m_unStoredNodeInfo do
            local data = self.m_unStoredNodeInfo[index]
            if respinNode.m_colIndex == data.iY and respinNode.m_rowIndex == data.iX then
                return data.type
            end
        end
    end
end

--[[
    获取锁定信号信息
]]
function BaseRespinView:getEndTypeInfo(symbolType)
    for index = 1,#self.m_symbolTypeEnd do
       local lockType = self.m_symbolTypeEnd[index].type
       if lockType == symbolType then
          return self.m_symbolTypeEnd[index]
       end
    end
    return nil
end

--[[
    初始化裁切层
]]
function BaseRespinView:initClipNodes(machineElement)
    for iRow = 1,self.m_machineRow do
        local pos = self:getClipStartPos(iRow,machineElement)
        local clipNode = ccui.Layout:create()
        clipNode:setAnchorPoint(cc.p(0.5, 0.5))
        clipNode:setTouchEnabled(false)
        clipNode:setSwallowTouches(false)
        local size = CCSizeMake(self.m_slotNodeWidth * self.m_machineColmn * 1.5,self.m_slotNodeHeight)
        clipNode:setPosition(pos)
        clipNode:setContentSize(size)
        clipNode:setClippingEnabled(true)
        self:addChild(clipNode) 
        self.m_clipNodes[iRow] = clipNode

        -- clipNode:setBackGroundColor(cc.c3b(255, 0, 0))
        -- clipNode:setBackGroundColorOpacity(255)
        -- clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end

--[[
    获取裁切层起始位置
]]
function BaseRespinView:getClipStartPos(rowIndex,machineElement)
    --获取轮盘中心点
    local startPos,endPos
    for index = 1,#machineElement do
        local nodeInfo = machineElement[index]
        if nodeInfo then
            local iCol = nodeInfo.ArrayPos.iY
            local iRow = nodeInfo.ArrayPos.iX
            if iCol == 1 and iRow == rowIndex then
                startPos = nodeInfo.Pos
            elseif iCol == self.m_machineColmn and iRow == rowIndex then
                endPos = nodeInfo.Pos
            end
            --获取最下面一层的左右两点
            if startPos and endPos then
                break
            end
        end
    end

    if startPos and endPos then
        local centerPos = cc.p((startPos.x + endPos.x + self.m_slotNodeWidth) / 2, startPos.y)
        local pos = self:convertToNodeSpace(centerPos)
        return pos
    else
        util_printLog("节点位置数据错误,请检查reateRespinNodeInfo方法是否存在逻辑错误",true)
        return cc.p(0,0)
    end
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function BaseRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    
    self.m_machineElementData = machineElement

    --整行裁切
    if self:getClipType() == RESPIN_CLIPTYPE.COMBINE then
        self:initClipNodes(machineElement)
    end

    for index = 1,#machineElement do
        local nodeInfo = machineElement[index]
        local iCol = nodeInfo.ArrayPos.iY
        local iRow = nodeInfo.ArrayPos.iX
        
        local status = nodeInfo.status
        local respinNode = self:createRespinNode(nodeInfo)
        

        self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

        if self:getClipType() == RESPIN_CLIPTYPE.COMBINE then
            local clipNode = self.m_clipNodes[iRow]
            local pos = clipNode:convertToNodeSpace(nodeInfo.Pos)
            clipNode:addChild(respinNode)
            respinNode:setPosition(pos)
        else
            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            respinNode:setPosition(pos)
            self:addChild(respinNode)
        end

        --初始化respinNode上的小块
        local lastList = {nodeInfo.Type}
        respinNode:setSymbolList(lastList)
        respinNode:initSymbolNode(true)

        local endInfo = self:getEndTypeInfo(nodeInfo.Type)
        --锁定的respinNode
        if endInfo then
            self:changeRespinNodeStatus(respinNode,RESPIN_NODE_STATUS.LOCK)
        end
    end

    self:readyMove()
end

--[[
    创建respinNode
]]
function BaseRespinView:createRespinNode(nodeInfo)
    local status = nodeInfo.status
    local colIndex = nodeInfo.ArrayPos.iY
    local rowIndex = nodeInfo.ArrayPos.iX
    local parentData = self:getParentData(colIndex)
    local reelRunData = self:getReelRunData()
    local configData = self:getConfigData(reelRunData)
    local respinNode = util_require(self.m_respinNodeName):create({
        parentData = parentData,      --列数据
        configData = configData,      --列配置数据
        doneFunc = handler(self,self.respinNodeEndCallBack),        --单格停止回调
        createSymbolFunc = handler(self.m_machine,self.m_machine.getSlotNodeWithPosAndType),--创建小块
        pushSlotNodeToPoolFunc = handler(self.m_machine,self.m_machine.pushSlotNodeToPoolBySymobolType),--小块放回缓存池
        updateGridFunc = handler(self.m_machine,self.m_machine.updateReelGridNode),  --小块数据刷新回调
        direction = 0,      --0纵向 1横向 默认纵向
        colIndex = colIndex,
        rowIndex = rowIndex,
        clipType = self:getClipType(),
        parentView = self,
        machine = self.m_machine,      --必传参数

    })

    --设置假滚时使用随机信号的方式
    respinNode:setRunType(self.m_isRandomSymbol)

    return respinNode
end

--[[
    获取数据
]]
function BaseRespinView:getParentData(colIndex)
    local reelDatas = self.m_symbolRandomType
    if not self.m_isRandomSymbol then
        reelDatas = self.m_machine.m_configData:getNormalReelDatasByColumnIndex(colIndex)
    end
    local parentData = {
        reelDatas = reelDatas,
        beginReelIndex = math.random(1,#reelDatas),
        slotNodeW = self.m_slotNodeWidth,
        slotNodeH = self.m_slotNodeHeight,
        reelWidth = self.m_slotNodeWidth,
        reelHeight = self.m_slotNodeHeight,
        isDone = false
    }      --列数据
    return parentData
end

--[[
    获取停轮间隔配置
]]
function BaseRespinView:getReelRunData()
    local reelRunData = {}
    --计算停轮间隔数
    for iCol = 1,self.m_machineColmn do
        local count = BASE_RUN_NUM + BASE_COL_INTERVAL * (iCol - 1)
        reelRunData[iCol] = count
    end

    return reelRunData
end

--[[
    获取配置
]]
function BaseRespinView:getConfigData(reelRunData)
    

    local configData = {
        p_reelMoveSpeed = self:getBaseMoveSpeed(MOVE_SPEED),--MOVE_SPEED,
        p_rowNum = 1,
        p_reelBeginJumpTime = self.m_machine.m_configData.p_reelBeginJumpTime,
        p_reelBeginJumpHight = self.m_machine.m_configData.p_reelBeginJumpHight,
        p_reelResTime = self.m_machine.m_configData.p_reelResTime,
        p_reelResDis = self.m_machine.m_configData.p_reelResDis,
        p_reelRunDatas = reelRunData --停轮间隔
    }
    return configData
end

--设置repinnode宽高
function BaseRespinView:initRespinSize(respinNodeWidth, respinNodeHeight, reelWidth, reelHeight)
    self.m_slotNodeWidth = respinNodeWidth
    self.m_slotNodeHeight = respinNodeHeight

    self.m_slotReelWidth = reelWidth
    self.m_slotReelHeight = reelHeight
end

--传入内存池与machine使用同一个池
function BaseRespinView:setCreateAndPushSymbolFun(funcGetSlotNode, funcPushNodeToPool)
    self.getSlotNodeBySymbolType = funcGetSlotNode
    self.pushSlotNodeToPoolBySymobolType = funcPushNodeToPool
end

--[[
    变更respinNode状态
]]
function BaseRespinView:changeRespinNodeStatus(respinNode,status)
    --判断状态是否一致
    if status == respinNode:getRespinNodeStatus() then
        return
    end

    --锁定状态,小块提层
    if status == RESPIN_NODE_STATUS.LOCK then
        respinNode:changeDownStatus(true)
        local symbolNode = respinNode:getBaseShowSymbol()
        if symbolNode then
            local pos = util_convertToNodeSpace(symbolNode,self)
            local zOrder = self.m_machine:getBounsScatterDataZorder(symbolNode.p_symbolType)
            zOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * self.m_machineRow * 2
            util_changeNodeParent(self,symbolNode,zOrder)
            symbolNode:setPosition(pos)
            respinNode:setLockSymbolNode(symbolNode)
        end
    else --普通状态,小块放回滚轴
        respinNode:putLockSymbolBack()
    end

    respinNode:setRespinNodeStatus(status)
end

--将respinView元素放入respinNode做移动准备工作
--可以重写播放进入respin时动画
function BaseRespinView:readyMove()
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    

    if type(self.m_startCallFunc) == "function" then
        self.m_startCallFunc()
    end
end

--[[
    开始滚动前重置数据
]]
function BaseRespinView:resetDataBeforeMove()
    self:setQuickRunStatus(false)
    self.m_isBonusDown = false
    self.m_reelDownSounds = {}
    self.m_symbolDownSounds = {}
    if self.m_machine and self.m_machine.m_runSpinResultData.p_reSpinCurCount then
        self.m_reSpinCurCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount or 3
    end
end

--组织滚动信息 开始滚动
function BaseRespinView:startMove()
    self:changeTouchStatus(ENUM_TOUCH_STATUS.RUN)

    self:resetDataBeforeMove()

    for index = 1,#self.m_respinNodes do
        if self.m_respinNodes[index]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodes[index]:startMove()
        end
    end
end


--[[
    设置停止信息
]]
function BaseRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    self:setRunEndData(storedNodeInfo, unStoredReels)
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        respinNode:setIsWaitNetBack(false)
        if not respinNode:checkIsDownStatus() then
            --检测是否需要快滚
            if self:checkNeedQuickRun(respinNode) then
                self:setQuickRunStatus(true)
                self:setRespinNodeQuickRun(respinNode)
                self:showQuickRunEffect(respinNode)
            end

            local endNodeType = self:getEndSymbolType(respinNode)
            if endNodeType then
                respinNode:setSymbolList({endNodeType})
            else
                util_printLog("未获取到respin停轮数据,请检查服务器数据",true)
            end
        end
    end
end

--[[
    检测是否需要快滚(子类重写)
]]
function BaseRespinView:checkNeedQuickRun(respinNode)

    --是否为最后一次spin
    if self.m_reSpinCurCount and self.m_reSpinCurCount <= 1 then
        
    end

    return false
end

--[[
    显示快滚特效(子类重写)
]]
function BaseRespinView:showQuickRunEffect(respinNode)
    local pos = cc.p(respinNode:getPosition())

end

--[[
    设置快滚状态
]]
function BaseRespinView:setQuickRunStatus(isQuick)
    self.m_quickRunStatus = isQuick
end

--[[
    获取快滚状态
]]
function BaseRespinView:getQuickRunStatus()
    return self.m_quickRunStatus
end

--[[
    设置respinNode快滚
]]
function BaseRespinView:setRespinNodeQuickRun(respinNode)
    if not self:getQuickRunStatus() then
        return
    end

    respinNode:setQuickRun()
end

--[[
    快停
]]
function BaseRespinView:quicklyStop()
    if self:getouchStatus() ~= ENUM_TOUCH_STATUS.RUN then
        return
    end
    util_printLog("respin快停")
    self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if not respinNode:checkIsDownStatus() then
            respinNode:quickStop()
        end
    end

    
end

--[[
    单格停止回调
]]
function BaseRespinView:respinNodeEndCallBack(respinNode)
    local symbolNode = respinNode:getBaseShowSymbol()
    if symbolNode and symbolNode.p_symbolType then
        local info = self:getEndTypeInfo(symbolNode.p_symbolType)
        --小块提层
        if info then
            self:changeRespinNodeStatus(respinNode,RESPIN_NODE_STATUS.LOCK)
            self:checkPlaySymbolDownSound(symbolNode.p_symbolType,respinNode.m_colIndex,symbolNode)
        end
        self:runNodeEnd(symbolNode,info)
        
    end

    --检测单列停止
    if self:checkOneReelDown(respinNode.m_colIndex) then
        self:slotOneReelDown(respinNode.m_colIndex)
    end

    --滚动停止
    if self:checkIsAllDown() then
        if self.m_machine then
            self.m_machine:reSpinReelDown()
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
        end
    end
end

--[[
    单列停止回调
]]
function BaseRespinView:slotOneReelDown(colIndex)
    self:playReelDownSound(colIndex)
end

--[[
    单列停轮音效
]]
function BaseRespinView:playReelDownSound(colIndex)
    if self.m_reelDownSounds[colIndex] then
        return
    end

    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if self.m_machine and self.m_machine.m_quickStopReelDownSound then
            gLobalSoundManager:playSound(self.m_machine.m_quickStopReelDownSound)
        end
        for iCol = 1,self.m_machineColmn do
            self.m_reelDownSounds[iCol] = true
        end
    else
        if self.m_machine and self.m_machine.m_reelDownSound then
            gLobalSoundManager:playSound(self.m_machine.m_reelDownSound)
        end
        self.m_reelDownSounds[colIndex] = true
    end
end

--[[
    单格停止
]]
function BaseRespinView:runNodeEnd(symbolNode,info)
    if tolua.isnull(symbolNode) then
        return
    end
    if info and info.runEndAnimaName ~= nil and info.runEndAnimaName ~= "" then
        if not self.m_isBonusDown and self.m_machine then
            self.m_isBonusDown= true
            self:changeRespinCount()
        end
        
        symbolNode:runAnim(info.runEndAnimaName, false)
    end
end

--[[
    变更respin次数(在第一个bonus落地时调用,可根据具体需求重写)
]]
function BaseRespinView:changeRespinCount()
    self.m_machine:changeReSpinUpdateUI(self.m_machine.m_runSpinResultData.p_reSpinCurCount)
end

--[[
    检测播放图标落地音效
]]
function BaseRespinView:checkPlaySymbolDownSound(symbolType,colIndex,symbolNode)
    if self.m_symbolDownSounds[colIndex] then
        return
    end
    
    if not self.m_symbolDownSounds then
        self.m_symbolDownSounds = {}
    end

    if not self.m_symbolDownSounds[colIndex] then
        self:playSymbolDownSound(symbolType,symbolNode)
    end

    self.m_symbolDownSounds[colIndex] = true

    --快停
    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        for iCol = 1,self.m_machineColmn do
            self.m_symbolDownSounds[iCol] = true
        end
    end

end

--[[
    播放图标落地音效
]]
function BaseRespinView:playSymbolDownSound(symbolType,symbolNode)
    
end

--[[
    检测单列停止
]]
function BaseRespinView:checkOneReelDown(colIndex)
    local downNodeCount = 0
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if respinNode.m_colIndex == colIndex and respinNode:checkIsDownStatus() then
            downNodeCount = downNodeCount + 1 
        end
    end

    return downNodeCount >= self.m_machineRow
end

--[[
    检测是否所有respinNode都已经停轮
]]
function BaseRespinView:checkIsAllDown()
    for index = 1,#self.m_respinNodes do
        if not self.m_respinNodes[index]:checkIsDownStatus() then
            return false
        end
    end
    return true
end

--[[
    获取所有最终停止信号
]]
function BaseRespinView:getAllEndSlotsNode()
    local endSlotNode = {}



    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode:getBaseShowSymbol()
        if symbolNode then
            endSlotNode[#endSlotNode + 1] = symbolNode
        end
    end

    return endSlotNode
end

--[[
    获取所有参与结算节点
]]
function BaseRespinView:getAllCleaningNode()
    --从 从上到下 左到右(respinNodes默认的排序本身就是如此,按顺序依次取出来就好了)
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode:getLockSymbolNode()
        if symbolNode then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
    end
    
    return cleaningNodes
end

--获取基础滚动速度
function BaseRespinView:getBaseMoveSpeed(_moveSpeed)
    local moveSpeed = _moveSpeed or MOVE_SPEED
    if self.m_machine and self.m_machine.m_configData.p_respinReelMoveSpeedMul then
        moveSpeed = moveSpeed * self.m_machine.m_configData.p_respinReelMoveSpeedMul
    end
    return moveSpeed
end

return BaseRespinView
