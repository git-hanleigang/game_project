---
--xcyy
--2018年5月23日
--DazzlingDiscoReelNode.lua

local DazzlingDiscoReelNode = class("DazzlingDiscoReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}

DazzlingDiscoReelNode.m_isHeadReel = false

function DazzlingDiscoReelNode:ctor(params)
    DazzlingDiscoReelNode.super.ctor(self,params)
    self.m_reelID = self.m_colIndex
end

--[[
    创建裁切层
]]
function DazzlingDiscoReelNode:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    local size = CCSizeMake(self.m_parentData.reelWidth * 1.5,self.m_parentData.reelHeight) 
    self.m_reelSize = size
    self.m_clipNode:setPosition(cc.p(self.m_parentData.reelWidth / 2,0))
    self.m_clipNode:setContentSize(self.m_reelSize)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    --压黑层
    self.m_blackNode = ccui.Layout:create()
    self.m_blackNode:setAnchorPoint(cc.p(0.5, 0))
    self.m_blackNode:setTouchEnabled(false)
    self.m_blackNode:setSwallowTouches(false)
    local size = CCSizeMake(self.m_parentData.reelWidth,self.m_parentData.reelHeight) 
    self.m_blackNode:setPosition(cc.p(self.m_reelSize.width / 2,0))
    self.m_blackNode:setContentSize(size)
    self.m_clipNode:addChild(self.m_blackNode,BASE_SLOT_ZORDER.BIG)
    self.m_blackNode:setVisible(false)
    

    self.m_blackNode:setBackGroundColor(cc.c3b(0, 0, 0))
    self.m_blackNode:setBackGroundColorOpacity(200)
    self.m_blackNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)

    self:createLongWild()

end

--[[
    显示压黑层
]]
function DazzlingDiscoReelNode:showBlackLayer()
    self.m_blackNode:setVisible(true)
    util_nodeFadeIn(self.m_blackNode,0.2,0,200)
end

--[[
    隐藏压黑层
]]
function DazzlingDiscoReelNode:hideBlackLayer( )
    util_fadeOutNode(self.m_blackNode,0.2,function(  )
        self.m_blackNode:setVisible(false)
    end)
end

--[[
    把信号放到压黑层上面
]]
function DazzlingDiscoReelNode:changeSymbolToTop(symbolNode)
    local rollNode = self:getRollNodeByRowIndex(symbolNode.p_rowIndex) --symbolNode:getParent()
    if rollNode then
        self:setRollNodeZOrder(rollNode,symbolNode.p_rowIndex,symbolNode.p_showOrder + BASE_SLOT_ZORDER.BIG,false)
    end
    
end

--[[
    重置信号层级
]]
function DazzlingDiscoReelNode:resetSymbolZOrder(symbolNode)
    local rollNode = self:getRollNodeByRowIndex(symbolNode.p_rowIndex)--symbolNode:getParent()
    if rollNode then
        self:setRollNodeZOrder(rollNode,symbolNode.p_rowIndex,symbolNode.p_showOrder,false)
    end
end

--[[
    重新加载滚动节点上的小块
]]
function DazzlingDiscoReelNode:reloadRollNode(rollNode,rowIndex)

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
                bigRollNode:addChild(symbolNode,50)
            else
                rollNode:addChild(symbolNode,50)
            end
        else
            rollNode:addChild(symbolNode,50)
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

    if self.m_isLastNode then
        self.m_curRowIndex = self.m_curRowIndex + 1
    end
end

--[[
    初始化滚动的点
]]
function DazzlingDiscoReelNode:initBaseRollNodes()
    --计算需要创建的滚动的点的数量
    local nodeCount = self:getMaxNodeCount()
    --创建对应数量的滚动点
    for index = 1,nodeCount do
        local rollNode = cc.Node:create()
        self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
        self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
        local pos = cc.p(self.m_reelSize.width / 2,(index - 1) * self.m_parentData.slotNodeH)
        rollNode:setPosition(pos)

        if self.m_bigReelNodeLayer then
            self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
        end
    end
end

--[[
    获取最大的滚动点数量 
]]
function DazzlingDiscoReelNode:getMaxNodeCount()
    local nodeCount = math.ceil(self.m_reelSize.height / self.m_parentData.slotNodeH) + 2

    
    local needAddCount = 0
    --检测当前滚轮上最长的长条
    for iRow = 1,#self.m_rollNodes do
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode and symbolNode.p_symbolType then
            local isBig,count = self:checkIsBigSymbol(symbolNode.p_symbolType)
            if isBig and count > needAddCount then
                needAddCount = count - 1
            end
        end
    end

    nodeCount = nodeCount + needAddCount
    return nodeCount
end

--[[
    检测小块是否出界
]]
function DazzlingDiscoReelNode:checkRollNodeIsOutLine(rollNode)
    local isOutLine = false
    local symbolNode = self:getSymbolByRow(1)
    local isBig,longCount = false,1
    --判断是否是长条信号
    if symbolNode and symbolNode.p_symbolType then
        isBig,longCount = self:checkIsBigSymbol(symbolNode.p_symbolType)
    end

    local slotHight = self.m_parentData.slotNodeH
    local bottomBorder = -slotHight 
    if isBig then
        bottomBorder = -slotHight * (longCount - 1)
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
        
    end
end

--[[
    开启计时器
]]
function DazzlingDiscoReelNode:startSchedule()

    self.m_machine:registScheduleCallBack(self.m_reelID,function(dt)

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
        local posY = rollNode:getPositionY()
        if symbolNode and symbolNode.m_isLastSymbol then
            self:slotReelDown()
        end
    end)
end

--[[
    滚轮停止
]]
function DazzlingDiscoReelNode:slotReelDown()
    --滚轮停止
    self.m_scheduleNode:unscheduleUpdate()
    self.m_machine:unRegistScheduleCallBack(self.m_reelID)

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
    重置显示状态
]]
function DazzlingDiscoReelNode:resetViewStatus()
    --滚轮停止
    self.m_scheduleNode:unscheduleUpdate()
    self.m_machine:unRegistScheduleCallBack(self.m_reelID)  

    self.m_isChangeSize = false
    self.m_parentData.isDone = true

    --重置小块位置
    self:resetRollNodePos()
    self:resetSymbolRowIndex()

    --检测滚动节点数量是否大于与裁切层可显示数量
    self:checkReduceRollNode()
end

--[[
    重置小块位置
]]
function DazzlingDiscoReelNode:resetRollNodePos()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            rollNode:setPositionY((iRow - 1) * self.m_parentData.slotNodeH)
        end
        
        if self.m_bigReelNodeLayer then
            self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,iRow)
        end
    end)
end

--[[
    重置假滚列表
]]
function DazzlingDiscoReelNode:resetReelDatas()
    if self.m_isHeadReel then
        self.m_parentData.reelDatas = {201}
        self.m_parentData.beginReelIndex = 1
    else
        if type(self.m_machine.checkUpdateReelDatas) then
            self.m_machine:checkUpdateReelDatas(self.m_parentData)
        end
    end
    
end

--[[
    重置假滚列表为普通信号
]]
function DazzlingDiscoReelNode:resetReelDataByNormal()
    self:updateReelDatasByFull()
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function DazzlingDiscoReelNode:updateReelDatasByFull()
    local reelDatas = self.m_machine.m_configData:getFsReelDatasByColumnIndex(0, self.m_colIndex)

    self.m_parentData.reelDatas = reelDatas
    self.m_parentData.beginReelIndex = 1

    return reelDatas
end

--[[
    修改列数
]]
function DazzlingDiscoReelNode:changeColIndex(colIndex)
    self.m_colIndex = colIndex
end

--是否为头像列
function DazzlingDiscoReelNode:setIsHeadReel(isHead)
    self.m_isHeadReel = isHead
end

--[[
    设置动态升行
]]
function DazzlingDiscoReelNode:setDynamicEndFunc(func)
    self.m_dynamicEndFunc = func
end

--[[
    动态升行
]]
function DazzlingDiscoReelNode:dynamicChangeSize(dt)
    local offset = math.floor(self.m_changeSizeSpeed * dt)
    if type(self.m_dynamicPerFunc) == "function" then
        self.m_dynamicPerFunc(dt)
    end
    --检测升行还是降行
    if self.m_reelSize.height > self.m_dynamicSize.height then
        offset = -offset
    end

    local newSize = CCSizeMake(self.m_reelSize.width,self.m_reelSize.height + offset)
    if newSize.height >= self.m_dynamicSize.height and offset > 0 then --已经升到最大
        newSize.height = self.m_dynamicSize.height
        self.m_isChangeSize = false
        self.m_dynamicPerFunc = nil
        if type(self.m_dynamicEndFunc) == "function" then
            self.m_dynamicEndFunc()
        end
    elseif newSize.height <= self.m_dynamicSize.height and offset < 0 then --已经降到最低
        newSize.height = self.m_dynamicSize.height
        self.m_isChangeSize = false
        self.m_dynamicPerFunc = nil
        if type(self.m_dynamicEndFunc) == "function" then
            self.m_dynamicEndFunc()
        end
    end

    local offset = newSize.height - self.m_reelSize.height

    local reelCsbNode = self.m_csbNode
    local reelBg = reelCsbNode:findChild("reel_0")
    reelBg:setContentSize(CCSizeMake(self.m_dynamicSize.width,newSize.height))

    self.m_clipNode:setContentSize(newSize)

    self.m_upAni:setPosition(cc.p(newSize.width / 2,newSize.height))

    self.m_blackNode:setContentSize(CCSizeMake(newSize.width / 1.5,newSize.height))
    self.m_reelSize = newSize

    self.m_longWildSymbol:setPosition(cc.p(self.m_reelSize.width / 2,self.m_reelSize.height / 2))
    if self.m_bigReelNodeLayer and self.m_colIndex == 1 then
        local bigNewSize = CCSizeMake(self.m_bigReelNodeLayer.m_clipSize.width * 1.2,newSize.height)
        self.m_bigReelNodeLayer.m_clipNode:setContentSize(bigNewSize)
        self.m_bigReelNodeLayer.m_clipSize = bigNewSize
    end

    self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    self.m_maxCount = self.m_lastNodeCount

    self:checkAddRollNode()
end

--[[
    重置尺寸
]]
function DazzlingDiscoReelNode:resetSize(reelSize)
    local reelCsbNode = self.m_csbNode
    local reelBg = reelCsbNode:findChild("reel_0")
    reelBg:setContentSize(reelSize)

    local newSize = CCSizeMake(self.m_reelSize.width,reelSize.height)
    self.m_clipNode:setContentSize(newSize)
    self.m_reelSize = newSize

    self.m_upAni:setPosition(cc.p(newSize.width / 2,newSize.height))

    self.m_longWildSymbol:setPosition(cc.p(self.m_reelSize.width / 2,self.m_reelSize.height / 2))

    self.m_blackNode:setContentSize(CCSizeMake(newSize.width / 1.5,newSize.height))

    self:hideLongWild()
end

--[[
    创建一个长条wild图标在压黑层之下
]]
function DazzlingDiscoReelNode:createLongWild( )
    self.m_longWildSymbol = util_spineCreate("Socre_DazzlingDisco_Wild3",true,true)
    self.m_longWildSymbol:setPosition(cc.p(self.m_reelSize.width / 2,self.m_reelSize.height / 2))
    self.m_clipNode:addChild(self.m_longWildSymbol,BASE_SLOT_ZORDER.BIG - 1)
    self.m_longWildSymbol:setScale(2.34)
    self:hideLongWild()
end

--[[
    显示整列wild
]]
function DazzlingDiscoReelNode:showLongWild(headData)
    self.m_longWildSymbol:setVisible(true)

    if not self.m_longWildSymbol.m_headItem then
        local headItem = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotHeadItem",{index = headData.position + 1,parent = self.m_machine.m_parentView})
        util_spinePushBindNode(self.m_longWildSymbol,"touxiang2",headItem)
        headItem:updateHead(headData)
        headItem:findChild("Node_coins"):setVisible(false)
        self.m_longWildSymbol.m_headItem = headItem
    end
    
end

--[[
    隐藏整理wild
]]
function DazzlingDiscoReelNode:hideLongWild()
    self.m_longWildSymbol:setVisible(false)
end

--[[
    隐藏滚动点
]]
function DazzlingDiscoReelNode:hideRollNodes( )
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            rollNode:setVisible(false)
        end
    end)
end

--[[
    显示滚动点
]]
function DazzlingDiscoReelNode:showRollNodes()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            rollNode:setVisible(true)
        end
    end)
end

--[[
    创建整列遮盖动效
]]
function DazzlingDiscoReelNode:createChangeSymbolAni()
    self.m_changeSymbolAni = util_createAnimation("DazzlingDisco_social_qipan_reel_0.csb")
    self.m_clipNode:addChild(self.m_changeSymbolAni,200000)
    self.m_changeSymbolAni:setVisible(false)
    self.m_changeSymbolAni:setPosition(cc.p(self.m_reelSize.width / 2,0))

    self.m_upAni = util_createAnimation("DazzlingDisco_social_qipan_reel_1.csb")
    self.m_clipNode:addChild(self.m_upAni,210000)
    self.m_upAni:findChild("Panel_2"):setVisible(false)
    self.m_upAni:setPosition(cc.p(self.m_reelSize.width / 2,self.m_reelSize.height))
    self.m_upAni:setVisible(false)

    self.m_downAni = util_createAnimation("DazzlingDisco_social_qipan_reel_1.csb")
    self.m_clipNode:addChild(self.m_downAni,220000)
    self.m_downAni:findChild("Panel_1"):setVisible(false)
    self.m_downAni:setPosition(cc.p(self.m_reelSize.width / 2,0))
    self.m_downAni:setVisible(false)
end

--[[
    切换图标动效
]]
function DazzlingDiscoReelNode:runChangeSymbolAni(func)
    self.m_changeSymbolAni:setVisible(true)
    self.m_changeSymbolAni:runCsbAction("start",false,function(  )
        self.m_changeSymbolAni:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    升行特效
]]
function DazzlingDiscoReelNode:changeReelHeightAni()
    self.m_upAni:setVisible(true)
    self.m_upAni:runCsbAction("start",false,function(  )
        self.m_upAni:setVisible(false)
    end)
    self.m_downAni:setVisible(true)
    self.m_downAni:runCsbAction("start",false,function(  )
        self.m_downAni:setVisible(false)
    end)
end

return DazzlingDiscoReelNode