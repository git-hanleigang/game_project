--[[
    基础滚轮
]]
local BaseReelNode = class("BaseReelNode", cc.Node)
BaseReelNode.m_parentData = nil          --列数据
BaseReelNode.m_configData = nil          --配置数据(关键数据 p_reelMoveSpeed p_rowNum p_reelRunDatas) 
BaseReelNode.m_doneFunc = nil            --列停止回调
BaseReelNode.m_nextDataFunc = nil        --获得下一个小块数据
BaseReelNode.pushSlotNodeToPoolFunc = nil --将小块放回缓存池
BaseReelNode.m_updateGridFunc = nil      --小块数据刷新回调
BaseReelNode.m_colIndex = nil           --列索引

BaseReelNode.m_mysteryType = nil        --可变信号值
BaseReelNode.m_targetSymbolType = nil   --可变信号目标值

--滚动方向
local DIRECTION = {
    Vertical = 0,       --纵向
    Horizontal = 1,     --横向

}

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}


--[[
    params = {
        parentData = ,      --列数据
        configData = ,      --列配置数据
        doneFunc = ,        --列停止回调
        createSymbolFunc = ,--创建小块
        pushSlotNodeToPoolFunc = ,--小块放回缓存池
        updateGridFunc = ,  --小块数据刷新回调
        getSymbolZOrderFunc = --获取小块层级接口
        direction = 0,      --0纵向 1横向 默认纵向
        colIndex  = ,
        machine = self      --必传参数
    }
]]
function BaseReelNode:ctor(params)
    --列数据
    self.m_parentData = params.parentData
    --列配置数据
    self.m_configData = params.configData
    --列停止回调
    self.m_doneFunc = params.doneFunc
    --创建小块
    self.m_createSymbolFunc = params.createSymbolFunc
    --小块数据刷新回调
    self.m_updateGridFunc = params.updateGridFunc
    --添加角标回调
    self.m_checkAddSignFunc = params.checkAddSignFunc
    --将小块放回缓存池
    self.m_pushSlotNodeToPoolFunc = params.pushSlotNodeToPoolFunc
    --获取小块层级接口
    self.m_getSymbolZOrderFunc = params.getSymbolZOrderFunc

    --大信号层
    self.m_bigReelNodeLayer = params.bigReelNode

    --长条小块信息
    self.m_LongSymbolInfo = {}


    self.m_colIndex = params.colIndex

    self.m_reelMoveSpeed = self.m_configData.p_reelMoveSpeed --滚动速度

    self.m_lastList = {}
    self.m_netList = {}

    --剩余滚动小块
    self.m_leftCount = 0
    self.m_lastNodeCount = 0
    self.m_maxCount = 0
    self.m_curRowIndex = 1
    self.m_rowNum = self.m_configData.p_rowNum

    --等待网络消息返回
    self.m_isWaittingNetBack = true

    --是否使用真实小块
    self.m_isLastNode = false

    --是否需要动态升行
    self.m_isChangeSize = false
    --升行速度
    self.m_changeSizeSpeed = 200

    --滚动方向
    self.m_direction = params.direction
    if not self.m_direction then
        self.m_direction = DIRECTION.Vertical
    end

    self.m_machine = params.machine

    self.m_rollNodes = {}

    self:initHandler()
    self:initUI()
end

function BaseReelNode:initHandler()
    self:registerScriptHandler(
        function(tag)
            if self == nil then
                return
            end
            if "enter" == tag then
                if self.onBaseEnter then
                    self:onBaseEnter()
                end
            elseif "exit" == tag then
                if self.onBaseExit then
                    self:onBaseExit()
                end
            elseif "cleanup" == tag then
                if self.onCleanUp then
                    self:onCleanUp()
                end
            end
        end
    )
end

--[[
    清理缓存
]]
function BaseReelNode:onCleanUp()
    -- util_printLog("清理滚动点上的小块",true)
    
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            util_resetChildReferenceCount(rollNode)
        end
    
        if bigRollNode then
            util_resetChildReferenceCount(bigRollNode)
        end
    end)
    -- util_printLog("清理完成",true)
end

function BaseReelNode:onBaseEnter()
    if self.onEnter then
        self:onEnter()
    end
end

function BaseReelNode:onBaseExit()
    if self.onExit then
        self:onExit()
    end
end

function BaseReelNode:onEnter()

end

function BaseReelNode:onExit()
    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()

    -- util_printLog("清理滚动点上的小块",true)
    -- self:removeAllSymbol()
    -- util_printLog("清理完成",true)
end

--[[
    移除所有滚动点上的小块
]]
function BaseReelNode:removeAllSymbol( )
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            self:removeSymbolFromRollNode(rollNode)
        end
    
        if bigRollNode then
            self:removeSymbolFromRollNode(bigRollNode)
        end
    end)
end

--[[
    层级关系如图所示
    rootNode
        scheduleNode
        clipNode
            rollNodes
      
]]
function BaseReelNode:initUI()
    --计时器节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    --创建裁切层
    self:createClipNode()

    --创建滚动的点
    self:initBaseRollNodes()
end

--[[
    创建裁切层
]]
function BaseReelNode:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮横向不裁切
        local size = CCSizeMake(self.m_parentData.reelWidth * 1.5,self.m_parentData.reelHeight) 
        self.m_reelSize = size
        self.m_clipNode:setPosition(cc.p(self.m_parentData.reelWidth / 2,0))
    else--横向滚轮纵向不裁切
        local size = CCSizeMake(self.m_parentData.reelWidth,self.m_parentData.reelHeight * 1.5) 
        self.m_reelSize = size
        self.m_clipNode:setPosition(cc.p(0,self.m_parentData.reelHeight / 2))
    end
    self.m_clipNode:setContentSize(self.m_reelSize)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(255, 0, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(255)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    设置动态升行
]]
function BaseReelNode:setDynamicSize(size,perFunc)
    self.m_dynamicSize = size
    self.m_isChangeSize = true
    self.m_dynamicPerFunc = perFunc
end

--[[
    设置升行速度
]]
function BaseReelNode:setChangeSizeSpeed(speed)
    self.m_changeSizeSpeed = speed
end

--[[
    初始化滚动的点
]]
function BaseReelNode:initBaseRollNodes()
    --计算需要创建的滚动的点的数量
    local nodeCount = self:getMaxNodeCount()
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        --创建对应数量的滚动点
        for index = 1,nodeCount do
            local rollNode = cc.Node:create()
            self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
            self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
            rollNode:setPosition(cc.p(self.m_reelSize.width / 2,(index - 1 + 0.5) * self.m_parentData.slotNodeH))

            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
            end
        end
    else --横向滚轮
        --创建对应数量的滚动点
        for index = 1,nodeCount do
            local rollNode = cc.Node:create()
            self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
            self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
            local posX = self.m_reelSize.width - (index - 1 + 0.5) * self.m_parentData.slotNodeW
            rollNode:setPosition(cc.p(posX,self.m_reelSize.height / 2))

            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
            end
        end
    end
end

--[[
    初始化小块显示
]]
function BaseReelNode:initSymbolNode(hasFeature)
    if hasFeature then
        self.m_isWaittingNetBack = false
        self.m_lastNodeCount = self.m_rowNum
        self:forEachRollNode(function(rollNode,bigRollNode,iRow)
            self:removeSymbolByRowIndex(iRow)
            self:reloadRollNode(rollNode,iRow)
        end)
    elseif type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        self:initSymbolByCfg()
    else
        self:forEachRollNode(function(rollNode,bigRollNode,iRow)
            self:removeSymbolByRowIndex(iRow)
            self:reloadRollNode(rollNode,iRow)
        end)
    end
end

--[[
    按照配置初始轮盘
]]
function BaseReelNode:initSymbolByCfg()
    local initDatas = self.m_configData:getInitReelDatasByColumnIndex(self.m_colIndex)
    local startIndex = 1

    --计算长条信号
    self:updateLongSymbolInfo(initDatas)

    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        self:removeSymbolByRowIndex(iRow)
        local symbolType = initDatas[iRow]
        if not symbolType then
            symbolType = initDatas[1]
        end

        local startIndex = startIndex + 1
        if iRow > #initDatas then
            startIndex = 1
        end

        if iRow > self.m_rowNum then
            self:reloadRollNode(rollNode,iRow)
            return
        end

        local isInLongSymbol = self:checkIsInLongSymbol(iRow)
        --检测是否是大信号
        local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

        if not isInLongSymbol then
            local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)
            
            --检测是否是大信号
            if isSpecialSymbol and bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
            symbolNode:setName("symbol")
            symbolNode:setPosition(cc.p(0,0))
            symbolNode.m_longInfo = nil
    
            local isLong = self:checkIsBigSymbol(symbolType)
            if isLong then
                local pos,longInfo = self:getLongSymbolPos(iRow,symbolType)
                symbolNode:setPosition(pos)
                symbolNode.m_longInfo = longInfo
                if longInfo then
                    --将偏移位置的滚动点上的小块移除
                    local maxCount = longInfo.maxCount
                    local curCount = longInfo.curCount
                    if maxCount > curCount then
                        for index = 1,maxCount - curCount do
                            self:removeSymbolByRowIndex(iRow - index)
                        end
                    end
                end
            end
            self.m_curRowIndex  = self.m_curRowIndex + 1
             
            if type(self.m_updateGridFunc) == "function" then
                self.m_updateGridFunc(symbolNode)
            end
            if type(self.m_checkAddSignFunc) == "function" then
                self.m_checkAddSignFunc(symbolNode)
            end
    
            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            symbolNode.p_showOrder = zOrder - iRow
    
            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        end
        
    end)
end

--[[
    重置假滚列表
]]
function BaseReelNode:resetReelDatas()
    if type(self.m_machine.checkUpdateReelDatas) == "function" then
        self.m_machine:checkUpdateReelDatas(self.m_parentData)
    end
    
end

--[[
    获取一个不是长条的小块
]]
function BaseReelNode:getNextNotLongSymbol()
    local symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
    local isLong,count = self:checkIsBigSymbol(symbolType)
    if not isLong then
        return symbolType
    end

    return self:getNextNotLongSymbol()
end

--[[
    获取下个小块
]]
function BaseReelNode:getNextSymbolType()
    -- reelDatas lastReelIndex
    --检测假滚卷轴是否存在
    if not self.m_parentData.reelDatas then
        self:resetReelDatas()
    end

    local function getNext()
        if self.m_mysteryType then
            --如果没有设置目标值,则随机一个普通的信号值
            if not self.m_targetSymbolType then
                self.m_targetSymbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
            end
            return self.m_targetSymbolType
        end

        if self.m_parentData.beginReelIndex > #self.m_parentData.reelDatas then
            self.m_parentData.beginReelIndex = 1
        end
        local symbolType = self.m_parentData.reelDatas[self.m_parentData.beginReelIndex]
        self.m_parentData.beginReelIndex = self.m_parentData.beginReelIndex + 1

        local isLong,count = self:checkIsBigSymbol(symbolType)

        --长条小块且剩余的小块数量不足以支撑长条小块移除
        if isLong and self.m_leftCount < count then
            symbolType = self:getNextNotLongSymbol()
        end

        return symbolType
    end

    --网络消息已经回来(动态升行期间不适用真数据)
    if not self.m_isWaittingNetBack and not self.m_isChangeSize then
        if self.m_leftCount > 0 then
            self.m_leftCount = self.m_leftCount - 1
            --返回假滚卷轴
            local symbolType = getNext()
            return symbolType
        elseif self.m_lastNodeCount > 0 then
            local symbolType
            if #self.m_lastList <= 0 then
                symbolType = getNext()
            else
                symbolType = self.m_lastList[1]
                table.remove(self.m_lastList,1)
            end

            if not symbolType then
                symbolType = getNext()
            end

            self.m_lastNodeCount = self.m_lastNodeCount - 1
            self.m_isLastNode = true
            if self.m_lastNodeCount <= 0 then
                self.m_lastNodeCount = 0
            end

            --返回真实小块数据
            return symbolType
        end
    end

    self.m_isLastNode = false
    --返回假滚卷轴
    local symbolType = getNext()
    return symbolType
end

--[[
    @desc: 开始滚动之前添加一个回弹效果
    time:2020-07-21 19:23:58
    @return:
]]
function BaseReelNode:addJumoActionAfterReel(func)
    local endCount = 0
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local seq = {}
        local pos = cc.p(rollNode:getPosition())
        local moveTime = self.m_configData.p_reelBeginJumpTime / 2
        local moveDistance = self.m_configData.p_reelBeginJumpHight
        if self.m_direction == DIRECTION.Vertical then --纵向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x,pos.y + moveDistance)))
            local action2 = cc.MoveTo:create(moveTime,pos)
            seq = {action1,action2}
        else --横向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x - moveDistance,pos.y)))
            local action2 = cc.MoveTo:create(moveTime,pos)
            seq = {action1,action2}
        end

        seq[#seq + 1] = cc.CallFunc:create(function()
            endCount = endCount + 1
            if endCount >= #self.m_rollNodes then
                if type(func) == "function" then
                    func()
                end
            end
        end)

        local sequece =cc.Sequence:create(seq)
        rollNode:runAction(sequece)

        --大信号
        if bigRollNode then
            local seq = {}
            local pos = cc.p(bigRollNode:getPosition())
            local moveTime = self.m_configData.p_reelBeginJumpTime / 2
            local moveDistance = self.m_configData.p_reelBeginJumpHight
            if self.m_direction == DIRECTION.Vertical then --纵向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x,pos.y + moveDistance)))
                local action2 = cc.MoveTo:create(moveTime,pos)
                seq = {action1,action2}
            else --横向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x - moveDistance,pos.y)))
                local action2 = cc.MoveTo:create(moveTime,pos)
                seq = {action1,action2}
            end

            local sequece =cc.Sequence:create(seq)
            bigRollNode:runAction(sequece)
        end
    end)
end

--[[
    快停
]]
function BaseReelNode:quickStop()
    self.m_leftCount = 0
    self.m_curRowIndex = 1
    self.m_lastList = clone(self.m_netList)
    self.m_lastNodeCount = #self.m_lastList
    self.m_isLastNode = true
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        self:removeSymbolByRowIndex(iRow)
        self:reloadRollNode(rollNode,iRow)
    end)

    self:slotReelDown()
end

--[[
    开始滚动
]]
function BaseReelNode:startMove(func)
    self:setIsWaitNetBack(true)
    
    self.m_isLastNode = false
    --长条小块信息
    self.m_LongSymbolInfo = {}

    self.m_curRowIndex = 1

    self:resetSymbolStatus()

    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    else
        self.m_lastNodeCount = math.floor(self.m_reelSize.width / self.m_parentData.slotNodeW)
    end
    self.m_maxCount = self.m_lastNodeCount
    
    self.m_parentData.isDone = false

    function callBack()
        if type(func) == "function" then
            func()
        end
        self:startSchedule()
    end

    self.m_leftCount = self.m_configData.p_reelRunDatas[self.m_colIndex]
    if self.m_configData.p_reelBeginJumpTime and self.m_configData.p_reelBeginJumpTime > 0 then
        self:addJumoActionAfterReel(callBack)
    else
        callBack()
    end
end

--[[
    重置symbol状态
]]
function BaseReelNode:resetSymbolStatus()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode then
            symbolNode.m_isLastSymbol = false
        end
        rollNode.m_isLastSymbol = false
    end)
end

--[[
    变更裁切层大小(无动画)
]]
function BaseReelNode:changClipSizeWithoutAni(targetHeight, isUp)
    self.m_dynamicSize = CCSizeMake(self.m_reelSize.width,targetHeight)
    self.m_clipNode:setContentSize(self.m_dynamicSize)
    self.m_reelSize = self.m_dynamicSize

    self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    self.m_maxCount = self.m_lastNodeCount

    if self.m_bigReelNodeLayer and self.m_colIndex == 1 then
        local bigNewSize = CCSizeMake(self.m_bigReelNodeLayer.m_clipSize.width,self.m_reelSize.height)
        self.m_bigReelNodeLayer.m_clipNode:setContentSize(CCSizeMake(bigNewSize.width * 1.2, bigNewSize.height))
        self.m_bigReelNodeLayer.m_clipSize = bigNewSize
    end

    if isUp then
        self:checkAddRollNode()
    else
        self:checkReduceRollNode()
    end
    
end

--[[
    动态升行
]]
function BaseReelNode:dynamicChangeSize(dt)
    local offset = math.floor(self.m_changeSizeSpeed * dt)
    if type(self.m_dynamicPerFunc) == "function" then
        self.m_dynamicPerFunc(dt)
    end
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮

        --检测升行还是降行
        if self.m_reelSize.height > self.m_dynamicSize.height then
            offset = -offset
        end

        local newSize = CCSizeMake(self.m_reelSize.width,self.m_reelSize.height + offset)
        if newSize.height >= self.m_dynamicSize.height and offset > 0 then --已经升到最大
            newSize.height = self.m_dynamicSize.height
            self.m_isChangeSize = false
            self.m_dynamicPerFunc = nil
        elseif newSize.height <= self.m_dynamicSize.height and offset < 0 then --已经降到最低
            newSize.height = self.m_dynamicSize.height
            self.m_isChangeSize = false
            self.m_dynamicPerFunc = nil
        end

        self.m_clipNode:setContentSize(newSize)
        self.m_reelSize = newSize

        if self.m_bigReelNodeLayer and self.m_colIndex == 1 then
            local bigNewSize = CCSizeMake(self.m_bigReelNodeLayer.m_clipSize.width,newSize.height)
            self.m_bigReelNodeLayer.m_clipNode:setContentSize(CCSizeMake(bigNewSize.width * 1.2, bigNewSize.height))
            self.m_bigReelNodeLayer.m_clipSize = bigNewSize
        end
    else --横向滚轮
        --检测升行还是降行
        if self.m_reelSize.width > self.m_dynamicSize.width then
            offset = -offset
        end

        local newSize = CCSizeMake(self.m_reelSize.width + offset,self.m_reelSize.height)
        if newSize.width >= self.m_dynamicSize.width and offset > 0 then --已经升到最大
            newSize.width = self.m_dynamicSize.width
            self.m_isChangeSize = false
            self.m_dynamicPerFunc = nil
        elseif newSize.width <= self.m_dynamicSize.width and offset < 0 then --已经降到最低
            newSize.width = self.m_dynamicSize.width
            self.m_isChangeSize = false
            self.m_dynamicPerFunc = nil
        end

        self.m_clipNode:setContentSize(newSize)
        self.m_reelSize = newSize

        if self.m_bigReelNodeLayer and self.m_colIndex == 1 then
            local bigNewSize = CCSizeMake(newSize.width,self.m_bigReelNodeLayer.m_clipSize.height)
            self.m_bigReelNodeLayer.m_clipNode:setContentSize(bigNewSize)
            self.m_bigReelNodeLayer.m_clipSize = bigNewSize
        end
    end

    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    else
        self.m_lastNodeCount = math.floor(self.m_reelSize.width / self.m_parentData.slotNodeW)
    end
    self.m_maxCount = self.m_lastNodeCount

    self:checkAddRollNode()
end

--[[
    检测是否需要增加滚动的点
]]
function BaseReelNode:checkAddRollNode()
    --计算需要创建的滚动的点的数量
    local nodeCount = self:getMaxNodeCount()

    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        if nodeCount > #self.m_rollNodes then
            --创建对应数量的滚动点
            for index = 1,nodeCount - #self.m_rollNodes do
                --最后一个小块
                local lastNode = self.m_rollNodes[#self.m_rollNodes]
                --创建新的滚动点
                local rollNode = cc.Node:create()
                self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
                self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
                rollNode:setPosition(cc.p(self.m_reelSize.width / 2,lastNode:getPositionY() + self.m_parentData.slotNodeH))

                if self.m_bigReelNodeLayer then
                    self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
                    self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,#self.m_rollNodes)
                end

                self:reloadRollNode(rollNode,#self.m_rollNodes)
            end
        end
        
    else --横向滚轮
        if nodeCount > #self.m_rollNodes then
            --创建对应数量的滚动点
            for index = 1,nodeCount - #self.m_rollNodes do
                --最后一个小块
                local lastNode = self.m_rollNodes[#self.m_rollNodes]
                --创建新的滚动点
                local rollNode = cc.Node:create()
                self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
                self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
                local posX = lastNode:getPositionX() - self.m_parentData.slotNodeW
                rollNode:setPosition(cc.p(posX,self.m_reelSize.height / 2))

                if self.m_bigReelNodeLayer then
                    self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
                    self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,#self.m_rollNodes)
                end

                self:reloadRollNode(rollNode,#self.m_rollNodes)
            end
        end
        
    end
end

--[[
    开启计时器
]]
function BaseReelNode:startSchedule()

    self.m_scheduleNode:onUpdate(function(dt)

        if globalData.slotRunData.gameRunPause then
            return
        end

        --检测是否需要升行或降行
        if self.m_isChangeSize then
            self:dynamicChangeSize(dt)
        end

        local offset = math.floor(dt * self.m_reelMoveSpeed) 
        
        --刷新小块位置,如果下面的点移动到可视区域外,怎把该点移动到队尾
        self:updateRollNodePos(offset)

        self:checkAddRollNode()

        --第一个小块永远是最下面的点,如果该点上的小块是真实数据小块,则滚动停止
        local symbolNode = self:getSymbolByRow(1)
        local rollNode = self:getRollNodeByRowIndex(1)
        if rollNode and rollNode.m_isLastSymbol then
            self:slotReelDown()
        end
    end)
end

--[[
    重置小块位置
]]
function BaseReelNode:resetRollNodePos()
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        self:forEachRollNode(function(rollNode,bigRollNode,iRow)
            rollNode:setPositionY((iRow - 1 + 0.5) * self.m_parentData.slotNodeH)
            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,iRow)
            end
        end)
    else --横向滚轮
        self:forEachRollNode(function(rollNode,bigRollNode,iRow)
            local posX = self.m_reelSize.width - (iRow - 1 + 0.5) * self.m_parentData.slotNodeW
            rollNode:setPositionX(posX)
            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,iRow)
            end
        end)
    end
end

--[[
    回弹动作
]]
function BaseReelNode:runBackAction(func)

    local moveTime = self.m_configData.p_reelResTime
    local dis = self.m_configData.p_reelResDis

    local endCount = 0
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        rollNode:stopAllActions()
        local seq = {}
        local pos = cc.p(rollNode:getPosition())
        if self.m_direction == DIRECTION.Vertical then --纵向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
            local action2 = cc.MoveTo:create(moveTime / 2,pos)
            seq = {action1,action2}
        else --横向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x + dis,pos.y)))
            local action2 = cc.MoveTo:create(moveTime / 2,pos)
            seq = {action1,action2}
        end

        if type(func) == "function" then
            seq[#seq + 1] = cc.CallFunc:create(function()
                endCount = endCount + 1
                if endCount >= #self.m_rollNodes then
                    func()
                end
            end)
        end
        
        local sequece =cc.Sequence:create(seq)

        rollNode:runAction(sequece)

        --大信号回弹
        if bigRollNode then
            bigRollNode:stopAllActions()
            local seq = {}
            local pos = cc.p(bigRollNode:getPosition())
            if self.m_direction == DIRECTION.Vertical then --纵向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                local action2 = cc.MoveTo:create(moveTime / 2,pos)
                seq = {action1,action2}
            else --横向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x + dis,pos.y)))
                local action2 = cc.MoveTo:create(moveTime / 2,pos)
                seq = {action1,action2}
            end
            
            local sequece =cc.Sequence:create(seq)

            bigRollNode:runAction(sequece)
        end
    end)
end

--[[
    获取回弹动作
    @pos: 需传入节点位置
]]
function BaseReelNode:getDownBackAction(pos,func)
    --回弹时间
    local moveTime = self.m_configData.p_reelResTime
    --回弹距离
    local dis = self.m_configData.p_reelResDis

    local seq = {}
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
        local action2 = cc.MoveTo:create(moveTime / 2,pos)
        seq = {action1,action2}
    else --横向滚轮
        local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x + dis,pos.y)))
        local action2 = cc.MoveTo:create(moveTime / 2,pos)
        seq = {action1,action2}
    end

    if type(func) == "function" then
        seq[#seq + 1] = cc.CallFunc:create(function()
            func()
        end)
    end

    return seq
end

--[[
    刷新小块位置
]]
function BaseReelNode:updateRollNodePos(offset)

    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if self.m_direction == DIRECTION.Vertical then --纵向滚轮
            if offset > self.m_parentData.slotNodeH then
                offset = self.m_parentData.slotNodeH
            end
            rollNode:setPositionY(rollNode:getPositionY() - offset)
            if bigRollNode then
                bigRollNode:setPositionY(bigRollNode:getPositionY() - offset)
            end
        else --横向滚轮
            if offset > self.m_parentData.slotNodeW then
                offset = self.m_parentData.slotNodeW
            end
            rollNode:setPositionX(rollNode:getPositionX() + offset)
            if bigRollNode then
                bigRollNode:setPositionX(bigRollNode:getPositionX() + offset)
            end
        end
    end)

    --只检测第一个小块是否出界即可
    self:checkRollNodeIsOutLine(self.m_rollNodes[1])
end

--[[
    检测小块是否出界
]]
function BaseReelNode:checkRollNodeIsOutLine(rollNode)
    local isOutLine = false
    local symbolNode = self:getSymbolByRow(1)
    local isBig,longCount = false,1
    --判断是否是长条信号
    if symbolNode and symbolNode.p_symbolType then
        isBig,longCount = self:checkIsBigSymbol(symbolNode.p_symbolType)
        if symbolNode.m_longInfo then
            longCount = symbolNode.m_longInfo.curCount
        end
    end

    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        local slotHight = self.m_parentData.slotNodeH
        local bottomBorder = -slotHight / 2
        if isBig then
            bottomBorder = -slotHight * (longCount - 0.5)
        end
        if rollNode:getPositionY() < bottomBorder then
            for curCount = 1,longCount do
                --最后一个小块
                local lastNode = self.m_rollNodes[#self.m_rollNodes]
                --第一个小块
                local firstNode = self.m_rollNodes[1]
                firstNode:setPositionY(lastNode:getPositionY() + slotHight)

                --如果出界把第一个小块移动到队列尾部
                for index = 1,#self.m_rollNodes - 1 do
                    self.m_rollNodes[index] = self.m_rollNodes[index + 1]
                end
        
                self.m_rollNodes[#self.m_rollNodes] = firstNode
        
                if self.m_bigReelNodeLayer then
                    self.m_bigReelNodeLayer:putFirstRollNodeToTail(self.m_colIndex)
                    self.m_bigReelNodeLayer:refreshRollNodePosByTarget(firstNode,self.m_colIndex,#self.m_rollNodes)
                end

                self:reloadRollNode(firstNode,#self.m_rollNodes)
            end

            --重置滚动点层级
            self:resetAllRollNodeZOrder()
            
        end
    else --横向滚轮
        local slotWidth = self.m_parentData.slotNodeW
        local posX = rollNode:getPositionX()
        local rightBorder = slotWidth / 2 + self.m_reelSize.width
        if isBig then
            rightBorder = self.m_reelSize.width + slotWidth * (longCount - 0.5)
        end
        if rollNode:getPositionX() > rightBorder then

            for curCount = 1,longCount do
                --最后一个小块
                local lastNode = self.m_rollNodes[#self.m_rollNodes]
                --第一个小块
                local firstNode = self.m_rollNodes[1]
                firstNode:setPositionX(lastNode:getPositionX() - slotWidth)

                --如果出界把第一个小块移动到队列尾部
                for index = 1,#self.m_rollNodes - 1 do
                    self.m_rollNodes[index] = self.m_rollNodes[index + 1]
                end
        
                self.m_rollNodes[#self.m_rollNodes] = firstNode

                if self.m_bigReelNodeLayer then
                    self.m_bigReelNodeLayer:putFirstRollNodeToTail(self.m_colIndex)
                    self.m_bigReelNodeLayer:refreshRollNodePosByTarget(firstNode,self.m_colIndex,#self.m_rollNodes)
                end

                self:reloadRollNode(firstNode,#self.m_rollNodes)
            end

            --重置滚动点层级
            self:resetAllRollNodeZOrder()
        end
    end
end

--[[
    判断是否是长条信号
]]
function BaseReelNode:checkIsBigSymbol(symbolType)
    if self.m_configData.p_bigSymbolTypeCounts and self.m_configData.p_bigSymbolTypeCounts[symbolType] then
        return true,self.m_configData.p_bigSymbolTypeCounts[symbolType]
    end
    return false,1
end

--[[
    判断是否是特殊信号
]]
function BaseReelNode:checkIsSpecialSymbol(symbolType)
    if self.m_configData.p_specialSymbolList then
        for i,bigType in ipairs(self.m_configData.p_specialSymbolList) do
            if bigType == symbolType then
                return true
            end
        end
    end

    return false
end

--[[
    判断是否在长条小块内
]]
function BaseReelNode:checkIsInLongSymbol(rowIndex)
    local isInLongSymbol = false
    --遍历小块,如果该点在长条小块范围内,不创建信号块
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbol = nil
        if bigRollNode then
            symbol = self:getSymbolByRollNode(bigRollNode)
        end

        if not symbol then
            symbol = self:getSymbolByRollNode(rollNode)
        end

        if symbol and symbol.p_symbolType then
            local isBig,count = self:checkIsBigSymbol(symbol.p_symbolType)
            if symbol.m_longInfo then
                count = symbol.m_longInfo.curCount
            end
            if isBig and rowIndex <= iRow + count - 1 and rowIndex > iRow then
                isInLongSymbol = true
                return true
            end
        end
    end)

    return isInLongSymbol
end

--[[
    变更小块类型
]]
function BaseReelNode:changeSymbolByType(symbolType,rowIndex)
    local rollNode = self:getRollNodeByRowIndex(rowIndex)

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

    if not isInLongSymbol then
        local symbolNode = self:getSymbolByRow(rowIndex)
        if symbolNode and symbolNode.p_symbolType ~= symbolType then
            symbolNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,symbolType), symbolType)
            symbolNode:setName("symbol")
            symbolNode.p_symbolType = symbolType
            
            if type(self.m_updateGridFunc) == "function" then
                self.m_updateGridFunc(symbolNode)
            end
            if type(self.m_checkAddSignFunc) == "function" then
                self.m_checkAddSignFunc(symbolNode)
            end
            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            symbolNode.p_showOrder = zOrder - rowIndex
            
            --判断是否需要调整父节点
            if isSpecialSymbol and self.m_bigReelNodeLayer then
                local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
                if symbolNode:getParent() and symbolNode:getParent() ~= bigRollNode then
                    util_changeNodeParent(bigRollNode,symbolNode)
                elseif symbolNode:getParent() and symbolNode:getParent() ~= rollNode and symbolNode:getParent() ~= bigRollNode then
                    util_changeNodeParent(rollNode,symbolNode)
                end
            elseif symbolNode:getParent() and symbolNode:getParent() ~= rollNode then
                util_changeNodeParent(rollNode,symbolNode)
            end

            self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,isSpecialSymbol)
        end
    else
        self:removeSymbolByRowIndex(rowIndex)
    end
end

--[[
    重新加载滚动节点上的小块
]]
function BaseReelNode:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)
    rollNode.m_isLastSymbol = self.m_isLastNode
    if not isInLongSymbol then
        local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)
        
        --检测是否是大信号
        if isSpecialSymbol and self.m_bigReelNodeLayer then
            local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
            if bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
        else
            rollNode:addChild(symbolNode)
        end
        symbolNode:setName("symbol")
        symbolNode:setPosition(cc.p(0,0))
        symbolNode.m_longInfo = nil

        local isLong = self:checkIsBigSymbol(symbolType)
        if self.m_isLastNode and isLong then
            local pos,longInfo = self:getLongSymbolPos(self.m_curRowIndex,symbolType)
            symbolNode:setPosition(pos)
            symbolNode.m_longInfo = longInfo
            if longInfo then
                --将偏移位置的滚动点上的小块移除
                local maxCount = longInfo.maxCount
                local curCount = longInfo.curCount
                if maxCount > curCount then
                    for index = 1,maxCount - curCount do
                        self:removeSymbolByRowIndex(rowIndex - index)
                    end
                end
            end
        end
         
        if type(self.m_updateGridFunc) == "function" then
            self.m_updateGridFunc(symbolNode)
        end
        if type(self.m_checkAddSignFunc) == "function" then
            self.m_checkAddSignFunc(symbolNode)
        end

        --根据小块的层级设置滚动点的层级
        local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - rowIndex

        self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,isSpecialSymbol)
    end

    if self.m_isLastNode then
        self.m_curRowIndex = self.m_curRowIndex + 1
    end
end

--[[
    获取长条信号在滚动点上的位置
]]
function BaseReelNode:getLongSymbolPos(rowIndex,symbolType)
    for index = 1,#self.m_LongSymbolInfo do
        local longInfo = self.m_LongSymbolInfo[index]

        if rowIndex == longInfo.startIndex and symbolType == longInfo.symbolType then
            if self.m_direction == DIRECTION.Vertical then --纵向滚轮
                local posY = -self.m_parentData.slotNodeH * (longInfo.maxCount - longInfo.curCount)
                return cc.p(0,posY),longInfo
            else
                local posX = self.m_parentData.slotNodeW * (longInfo.maxCount - longInfo.curCount)
                return cc.p(posX,0),longInfo
            end
        end
    end

    return cc.p(0,0),nil
end

--[[
    获取真实长条小块在轮盘中的长度
]]
function BaseReelNode:getLongSymbolCountInReel(rowIndex,symbolType,maxCount)
    for index = 1,#self.m_LongSymbolInfo do
        local longInfo = self.m_LongSymbolInfo[index]

        if rowIndex == longInfo.startIndex and symbolType == longInfo.symbolType then

            
            return longInfo.curCount
        end
    end
    return maxCount
end

--[[
    根据信号值重新加载滚动节点上的小块
]]
function BaseReelNode:reloadRollNodeBySymbolType(rowIndex,symbolType,isLastNode)

    self:removeSymbolByRowIndex(rowIndex)

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

    local rollNode = self:getRollNodeByRowIndex(rowIndex)
    rollNode.m_isLastSymbol = isLastNode

    if not isInLongSymbol then
        local symbolNode = self.m_createSymbolFunc(symbolType, rowIndex, self.m_colIndex,isLastNode,true)
        
        --检测是否是大信号
        if isSpecialSymbol and self.m_bigReelNodeLayer then
            local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
            if bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
        else
            rollNode:addChild(symbolNode)
        end
        symbolNode:setName("symbol")
        symbolNode:setPosition(cc.p(0,0))
        if type(self.m_updateGridFunc) == "function" then
            self.m_updateGridFunc(symbolNode)
        end
        if type(self.m_checkAddSignFunc) == "function" then
            self.m_checkAddSignFunc(symbolNode)
        end

        --根据小块的层级设置滚动点的层级
        local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - rowIndex

        self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,isSpecialSymbol)
    end
end

--[[
    获取小块层级
]]
function BaseReelNode:getSymbolZOrderByType(symbolType)
    --根据小块的层级设置滚动点的层级
    local zOrder = 0
    if type(self.m_getSymbolZOrderFunc) == "function" then
        zOrder = self.m_getSymbolZOrderFunc(symbolType)
    elseif type(self.m_machine.getBounsScatterDataZorder) == "function" then
        zOrder = self.m_machine:getBounsScatterDataZorder(symbolType)
    end
    return zOrder
end

--[[
    重置所有滚动点层级
]]
function BaseReelNode:resetAllRollNodeZOrder()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode and symbolNode.p_symbolType then
            local isSpecialSymbol = self:checkIsSpecialSymbol(symbolNode.p_symbolType)
            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            symbolNode.p_showOrder = zOrder - iRow

            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        end
    end)
end

--[[
    获取滚动点在队列中对应的索引
]]
function BaseReelNode:getRollNodeIndex(rollNode)
    for index = 1,#self.m_rollNodes do
        if rollNode == self.m_rollNodes[index] then
            return index
        end
    end

    return - 1
end

--[[
    设置层级
]]
function BaseReelNode:setRollNodeZOrder(rollNode,rowIndex,showOrder,isBigSymbol)
    if isBigSymbol and self.m_bigReelNodeLayer then
        local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
        if bigRollNode then
            bigRollNode:setLocalZOrder(showOrder + (self.m_colIndex - 1) * 10)
        else
            rollNode:setLocalZOrder(showOrder)
        end
    else
        rollNode:setLocalZOrder(showOrder)
    end
end

--[[
    变更滚动速度
]]
function BaseReelNode:changeReelMoveSpeed(speed)
    self.m_reelMoveSpeed = speed
end


--[[
    设置等待网络消息返回
]]
function BaseReelNode:setIsWaitNetBack(isBack)
    self.m_isWaittingNetBack = isBack
end

--[[
    设置symbol队列
]]
function BaseReelNode:setSymbolList(list)
    self.m_lastList = list or {}
    self.m_netList = clone(self.m_lastList)
    self.m_lastNodeCount = #self.m_lastList
    self.m_curRowIndex = 1

    --计算长条信号
    self:updateLongSymbolInfo(self.m_lastList)
    

    -- util_printLog("当前列数:"..self.m_colIndex)
    -- local str = ""
    -- for i,v in ipairs(list) do
    --     str = str..v.." "
    -- end
    -- util_printLog(str)
end

--[[
    刷新长条信号信息
]]
function BaseReelNode:updateLongSymbolInfo(list)
    if not list then
        list = self.m_lastList
    end

    --计算长条信号
    local index = 1
    while index <= #list do
        local symbolType = list[index]
        local isLong,maxCount = self:checkIsBigSymbol(symbolType)
        if isLong then
            --计算列表内长条的长度
            local curCount = self:getLongCountInLastList(symbolType,maxCount,list,index)
            local longInfo = {
                symbolType = symbolType,
                maxCount = maxCount,    --最大长度
                curCount = curCount,     --列表内长度
                startIndex = index      --起始索引
            }
            self.m_LongSymbolInfo[#self.m_LongSymbolInfo + 1] = longInfo
            if index == 1 then
                index = index + curCount
            else
                index = index + maxCount
            end
            
        else
            index = index + 1
        end
    end

end

--[[
    判断是否在长条小块内(根据长条信息判定)
]]
function BaseReelNode:checkIsInLongByInfo(rowIndex)
    if self.m_LongSymbolInfo and #self.m_LongSymbolInfo > 0 then
        for index = 1,#self.m_LongSymbolInfo do
            local longInfo = self.m_LongSymbolInfo[index]
            local startIndex = longInfo.startIndex
            local curCount = longInfo.curCount
            if rowIndex >= startIndex and rowIndex <= startIndex + curCount - 1 then
                return true,longInfo
            end
        end
    end
    
    return false,nil
end


--[[
    获取列表内的长条信号长度
]]
function BaseReelNode:getLongCountInLastList(symbolType,maxCount,list,startIndex)
    if not list then
        list = self.m_lastList
    end
    --第一个信号不是长条的直接返回最大长度
    if list[1] ~= symbolType or startIndex ~= 1 then
        return maxCount
    end
    local count = 0
    for index = startIndex,#list do
        if list[index] == symbolType then
            count = count + 1
        else
            break
        end
    end

    if count > maxCount then
        return maxCount
    end

    return count
end


--[[
    设置滚动长度
]]
function BaseReelNode:setRunLen(runLen)
    self.m_leftCount = runLen
end


--[[
    设置可变信号值
]]
function BaseReelNode:setMysteryType(mysteryType,targetType)
    self.m_mysteryType = mysteryType
    self.m_targetSymbolType = targetType
end

--[[
    重置可变信号值
]]
function BaseReelNode:resetMysteryType()
    self:setMysteryType()
end

--[[
    滚轮停止
]]
function BaseReelNode:slotReelDown()
    --滚轮停止
    self.m_scheduleNode:unscheduleUpdate()

    self.m_isChangeSize = false
    self.m_parentData.isDone = true

    --重置小块位置
    self:resetRollNodePos()
    self:resetSymbolRowIndex()

    --回弹动作
    self:runBackAction(function()
        
    end)

    if type(self.m_doneFunc) == "function" then
        self.m_doneFunc(self.m_colIndex)
    end

    --检测滚动节点数量是否大于与裁切层可显示数量
    self:checkReduceRollNode()
end

--[[
    重置小块列索引
]]
function BaseReelNode:resetSymbolRowIndex()
    for iRow = 1,#self.m_rollNodes do
        local isInLongSymbol = self:checkIsInLongSymbol(iRow)
        if not isInLongSymbol then
            local symbolNode = self:getSymbolByRow(iRow)
            if symbolNode then
                if symbolNode.m_longInfo then
                    symbolNode.p_rowIndex = symbolNode.m_longInfo.startIndex
                else
                    symbolNode.p_rowIndex = iRow
                end
                
            end
        end
        
    end
end

--[[
    检测是否需要减少滚动节点
]]
function BaseReelNode:checkReduceRollNode()
    local nodeCount = self:getMaxNodeCount()

    if #self.m_rollNodes > nodeCount then
        local needRemoveCount = #self.m_rollNodes - nodeCount
        for index = needRemoveCount,1,-1 do
            local rollNode = self.m_rollNodes[#self.m_rollNodes]
            self:removeSymbolByRowIndex(#self.m_rollNodes)
            rollNode:removeFromParent()
            table.remove(self.m_rollNodes,#self.m_rollNodes)

            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:reduceOneRollNode(self.m_colIndex)
            end
        end
    end
end

--[[
    获取最大的滚动点数量 
]]
function BaseReelNode:getMaxNodeCount()
    local nodeCount = 0
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        --计算需要滚动的点的数量
        nodeCount = math.ceil(self.m_reelSize.height / self.m_parentData.slotNodeH) + 1
    else --横向滚轮
        --计算需要创建的滚动的点的数量
        nodeCount = math.ceil(self.m_reelSize.width / self.m_parentData.slotNodeW) + 1
    end

    
    local needAddCount = 0
    local bigSymbolCfg = self.m_configData.p_bigSymbolTypeCounts
    --由于长条需要偏移,所以滚动点的数量应加上最长长条的长度
    if bigSymbolCfg and next(bigSymbolCfg) then
        for k,count in pairs(bigSymbolCfg) do
            if needAddCount < count then
                needAddCount = count
            end
        end
    end

    nodeCount = nodeCount + needAddCount
    return nodeCount
end

--[[
    移除滚动点上的小块
]]
function BaseReelNode:removeSymbolFromRollNode(rollNode)
    local children = rollNode:getChildren()

    if children and #children > 0 then
        local count = #children
        for index = 1,count do
            local symbolNode = children[1]
            
            if self.m_pushSlotNodeToPoolFunc and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
                --将小块放回缓存池
                symbolNode:removeFromParent(false)
                self.m_pushSlotNodeToPoolFunc(symbolNode.p_symbolType,symbolNode)
            else
                symbolNode:removeFromParent()
            end
            table.remove(children,1)
        end
    end
end

--[[
    移除滚动点上的小块
]]
function BaseReelNode:removeSymbolByRowIndex(rowIndex)
    local rollNode,bigRollNode = self:getRollNodeByRowIndex(rowIndex)
    if rollNode then
        self:removeSymbolFromRollNode(rollNode)
    end

    if bigRollNode then
        self:removeSymbolFromRollNode(bigRollNode)
    end
    
end

--[[
    判断小块是否在滚动点上
]]
function BaseReelNode:checkSymbolIsOnRollNode(symbolNode,rowIndex)
    local rollNode,bigRollNode = self:getRollNodeByRowIndex(rowIndex)

    if rollNode then
        local children = rollNode:getChildren()
        if children and #children > 0 then
            for index = 1,#children do
                if children[index] == symbolNode then
                    return true
                end
            end
        end
    end

    if bigRollNode then
        local children = bigRollNode:getChildren()
        if children and #children > 0 then
            for index = 1,#children do
                for index = 1,#children do
                    if children[index] == symbolNode then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--[[
    将小块放回滚动点
]]
function BaseReelNode:putSymbolBackToRollNode(rowIndex,symbolNode,zOrder)
    if rowIndex > #self.m_rollNodes then
        return
    end
    if not self:checkSymbolIsOnRollNode(symbolNode,rowIndex) then
        self:removeSymbolByRowIndex(rowIndex)
    end
    
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolNode.p_symbolType)

    local rollNode = self:getRollNodeByRowIndex(rowIndex)

    if not zOrder or zOrder == 0 then
        zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - rowIndex
    end

    self:setRollNodeZOrder(rollNode,rowIndex,zOrder,isSpecialSymbol)
    symbolNode:setPosition(cc.p(0,0))

    local targetParent = rollNode
    if isSpecialSymbol and self.m_bigReelNodeLayer then
        targetParent = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
    end

    if not tolua.isnull(symbolNode) and symbolNode:getParent() and symbolNode:getParent() == targetParent then
        return
    end

    if isSpecialSymbol and self.m_bigReelNodeLayer then
        local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
        if symbolNode:getParent() and symbolNode:getParent() ~= bigRollNode then
            util_changeNodeParent(bigRollNode,symbolNode)
        elseif symbolNode:getParent() and symbolNode:getParent() ~= rollNode and symbolNode:getParent() ~= bigRollNode then
            util_changeNodeParent(rollNode,symbolNode)
        end
    elseif symbolNode:getParent() and symbolNode:getParent() ~= rollNode then
        util_changeNodeParent(rollNode,symbolNode)
    end

    if symbolNode.m_longInfo then
        local posY = -self.m_parentData.slotNodeH * (symbolNode.m_longInfo.maxCount - symbolNode.m_longInfo.curCount)
        symbolNode:setPosition(cc.p(0,posY))

        if symbolNode.m_longClipNode then
            symbolNode.m_longClipNode:removeFromParent()
            symbolNode.m_longClipNode = nil
        end
    end

    symbolNode:setName("symbol")
end


--[[
    获取滚轮上的小块(需要判空)
]]
----------------------------------------------------------------------
function BaseReelNode:getSymbolByRow(rowIndex)

    --遍历小块,判断该点在长条小块范围内,如果在长条小块范围内则返回长条小块
    local longSymbol = nil
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbol = nil
        if bigRollNode then
            symbol = self:getSymbolByRollNode(bigRollNode)
        end

        if not symbol then
            symbol = self:getSymbolByRollNode(rollNode)
        end

        if symbol and symbol.p_symbolType then
            local longInfo = symbol.m_longInfo
            local isBig,count = false,1
            if longInfo then
                isBig,count = true,longInfo.curCount
            end
            --如果在长条范围内,直接返回该长条小块
            if isBig and rowIndex <= iRow + count - 1 and rowIndex >= iRow then
                longSymbol = symbol
                return true
            end
        end        
    end)

    if longSymbol then
        return longSymbol
    end


    --先获取大信号层的小块
    if self.m_bigReelNodeLayer then
        local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
        if not tolua.isnull(bigRollNode) then
            local symbol = self:getSymbolByRollNode(bigRollNode)
            if symbol and symbol.p_symbolType then
                return symbol
            end     
        end
    end

    local rollNode = self:getRollNodeByRowIndex(rowIndex)
    if tolua.isnull(rollNode) then
        return
    end
    return self:getSymbolByRollNode(rollNode)
end

function BaseReelNode:getSymbolByRollNode(rollNode)
    local symbolNode = rollNode:getChildByName("symbol")
    if not tolua.isnull(symbolNode) then
        return symbolNode
    end
end

--[[
    获取滚动点
]]
function BaseReelNode:getRollNodeByRowIndex(rowIndex)
    local rollNode = self.m_rollNodes[rowIndex]
    local bigRollNode
    if self.m_bigReelNodeLayer then
        bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
    end

    return rollNode,bigRollNode
end

--[[
    遍历滚动点
]]
function BaseReelNode:forEachRollNode(func)
    for iRow = 1,#self.m_rollNodes do
        local rollNode = self.m_rollNodes[iRow]
        local bigRollNode
        if self.m_bigReelNodeLayer then
            bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,iRow)
        end
        if type(func) == "function" then
            local needBreak = func(rollNode,bigRollNode,iRow)
            if needBreak then
                break
            end
        end
    end
end
----------------------------------------------------------------------
return BaseReelNode
