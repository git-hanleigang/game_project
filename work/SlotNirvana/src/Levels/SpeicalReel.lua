local SpeicalReel = class("SpeicalReel",  util_require("base.BaseView"))

--Reel中的层级
local ZORDER = {
    CLIP_ORDER = 1000,
    RUN_CLIP_ORDER = 2000,
    SHOW_ORDER = 2000,
    UI_ORDER = 3000,
}

-- --滚动中的层级 也就是m_clipNode下的层级
-- local RUN_ZORDER = {
--     SYMBOL_ORDER = 1,               --滚动层级
--     SPEICAL_ORDER = 10000,          --特殊元素如遮罩层等等
--     FIX_ORDER = 20000,              --symol 固定
--     EFFECT_ORDER = 30000,           --效果层
-- }

--m_clipNode特殊tag 
local RUN_TAG = 
{
    SYMBOL_TAG = 1,               --滚动信号tag 
    SPEICAL_TAG = 10000,          --特殊元素如遮罩层等等 不参与滚动
}

--滚动状态
GD.REEL_STATUS = {
    IDLE = 0,               --等待状态
    RUNNING = 1,            --滚动状态
    QUICK_STOP = 2,         --快停状态
}

--滚动参数---------------------------

local MOVE_SPEED = 500     --滚动速度 像素/每秒
SpeicalReel.RES_DIS = 20

-----------------------------------

SpeicalReel.m_clipNode = nil                        --滚动剪切
SpeicalReel.m_runclipNode = nil                        --剪切

SpeicalReel.m_reelWidth = nil
SpeicalReel.m_reelHeight = nil
SpeicalReel.m_dtMoveDis = nil
SpeicalReel.m_symbolNodeList = nil                  --node池

SpeicalReel.m_runDataList = nil                     --滚动数据表
SpeicalReel.m_dataListPoint = nil                   --滚动指针

SpeicalReel.m_endNode = nil
SpeicalReel.m_endDis = nil

SpeicalReel.m_runStatus = nil

SpeicalReel.m_endCallBackFun = nil
-----------------------------------------
SpeicalReel.getSlotNodeBySymbolType = nil           --内存池
SpeicalReel.pushSlotNodeToPoolBySymobolType = nil

local ANCHOR_POINT_Y = 0.5                          --原本传进来参数 现在csb统一锚点为 0.5 0.5
---信号格式 信号类型  层级 宽 高 停止信号  AnchorPointY 锚点坐标 
-- {SymbolType = 1, Zorder = 1, Width = 1, Height = 1 ,Last = false, AnchorPointY = 0.2}
function SpeicalReel:initUI(data)
    self.m_clipNode = 0                        --剪切
    self.m_reelWidth = 0
    self.m_reelHeight = 0
    self.m_dtMoveDis = 0
    self.m_symbolNodeList = {}
    self.m_endNode = nil
    self.m_endDis = nil
    self.m_runStatus = REEL_STATUS.IDLE
end

--[[
    @desc: -初始化Reel结构 
    author:{author}
    time:2018-11-28 12:03:55
    @return:
    @parma:wildth 宽 height 高 getSlotNodeFunc 内存池取  pushSlotNodeFunc 内存池删
]]
function SpeicalReel:init(wildth ,height, getSlotNodeFunc, pushSlotNodeFunc)
    self.m_clipNode = cc.ClippingRectangleNode:create({x= - wildth / 2, y = 0, width = wildth, height = height})
    self.m_clipNode:setPositionY(-height / 2)
    self:addChild(self.m_clipNode,ZORDER.CLIP_ORDER)

    -- local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 130),wildth * 10 , height* 10 )
    -- colorLayer:setPosition(-wildth * 2 , -height * 2)
    -- self.m_clipNode:addChild(colorLayer, 1, RUN_TAG.SPEICAL_TAG)
    
    --滚动中提升symbol层级遮罩
    self.m_runclipNode = cc.ClippingRectangleNode:create({x= -wildth / 2, y = -height, width = wildth, height = height * 2})
    self.m_runclipNode:setAnchorPoint(cc.p(0.5, 0.5))
    self:addChild(self.m_runclipNode,ZORDER.RUN_CLIP_ORDER)

    self.m_reelWidth = wildth
    self.m_reelHeight = height
    -- body
    self.getSlotNodeBySymbolType = getSlotNodeFunc
    self.pushSlotNodeToPoolBySymobolType = pushSlotNodeFunc
end

function SpeicalReel:addLayerColorBG(c4f, wildth, height)
    local colorLayer = cc.LayerColor:create(cc.c4f(220,20,60, 130),wildth * 10 , height* 10 )
    colorLayer:setPosition(-wildth * 2 , -height * 2)
    self.m_clipNode:addChild(colorLayer, 1, RUN_TAG.SPEICAL_TAG)
end
--[[
    @desc:滚动参数设置
    author:{author}
    time:2018-11-28 15:26:15
    @return:
]]
function SpeicalReel:setRunningParam(moveSpeed)
    MOVE_SPEED = moveSpeed
end

function SpeicalReel:getRunSpeed()
    return MOVE_SPEED 
end

--[[
    @desc:回弹距离设置
    author:{author}
    time:2018-11-28 15:26:15
    @return:
]]
function SpeicalReel:setresDis(resDis)
    self.RES_DIS = resDis
end

--[[
    @desc: --初始化时盘面信号  
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function SpeicalReel:initFirstSymbol(node)
    local wordPos = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(),node:getPositionY()))

    local tag =  node:getTag()
    local zorder = node:getZorder()
    node:retain()
    node:removeFromParent(false)

    local lastSymbolNode = self:getLastSymbolNode()

    node:setPosition(cc.p(0, 0))

    self.m_clipNode:addChild(node, zorder, tag)
    node:release()   
    node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    
    self:pushToSymbolList(node)
end

--[[
    @desc: --初始化时盘面信号  
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function SpeicalReel:initFirstSymbolBySymbols(initDataList)
    for i=1, #initDataList do
        local data = initDataList[i]

        local node = self.getSlotNodeBySymbolType(data.SymbolType)
        node.Height = data.Height
    
        self.m_clipNode:addChild(node, data.Zorder) 
        self:setRunCreateNodePos(node)
        self:pushToSymbolList(node)
    end
end

--[[
    @desc: 数据管理
    author:{author}
    time:2018-11-28 17:16:47
    --@runData: 
    @return:
]]
function SpeicalReel:initRunDate(runData)
    self.m_runDataList = runData
    self.m_dataListPoint = 1
end

function SpeicalReel:getRunDate()
    return self.m_runDataList 
end

function SpeicalReel:addRunData(data,point)
    self.m_runDataList = data
    table.insert(  self.m_runDataList, point, data )
end

function SpeicalReel:removeRunData(data,point)
    table.remove( data, point)
end
------------------------

function SpeicalReel:getNextRunData()
    if type(self.m_runDataList) == "function" then
        return self.m_runDataList()
    else
        local nowPoint = self.m_dataListPoint
        self.m_dataListPoint = self.m_dataListPoint + 1
        local nextData = nil
        if nowPoint <= #self.m_runDataList  then
            nextData = self.m_runDataList[nowPoint]
        end
        return nextData
    end
end

--获取第一个真实数据的point 用于快停
function SpeicalReel:getEndDataPoint()
    if type(self.m_runDataList) == "function" then
       assert(false, "停止数据还没有返回!!!!!!!!")
    end
    for i=1,#self.m_runDataList do
        local data = self.m_runDataList[i]

        if data.Last == true then
            return i
        end
    end
    assert(false, "没设置停止数据！！！！！")
end

--[[
    @desc: symbolNode池
    author:{author}
    time:2018-11-28 16:50:53
    --@symbolInfos: 
    @return:
]]
--- 返回最后一个信号
function SpeicalReel:getLastSymbolNode()
    if #self.m_symbolNodeList == 0 then
        return nil
    end
    return  self.m_symbolNodeList[#self.m_symbolNodeList]
end

function SpeicalReel:pushToSymbolList(node)
    self.m_symbolNodeList[#self.m_symbolNodeList + 1] = node 
end

function SpeicalReel:popUpSymbolList()
    table.remove(self.m_symbolNodeList, 1)
end

function SpeicalReel:removeFromSymbolList(node)

    for i=1,#self.m_symbolNodeList do
        local listNode = self.m_symbolNodeList[i]
        if listNode == node then
            table.remove( self.m_symbolNodeList, i)
            return 
        end
    end
end

--[[
    @desc:更新所有Symbol坐标
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function SpeicalReel:updateSymbolPosY()
    local childs = self.m_clipNode:getChildren()
    for i=1,#childs do
  
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosY = node:getPositionY()
            node:setPositionY(nowPosY + self.m_dtMoveDis)
        end
    end
end

--[[
    @desc:移除界面之下的symbol
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function SpeicalReel:removeBelowReelSymbol()
    local childs = self.m_clipNode:getChildren()
    for i=1,#childs do
        local node = childs[i]
        
        if node:getTag() < RUN_TAG.SPEICAL_TAG then

            local nowPosY = node:getPositionY()
            
            --计算出移除的临界点
            local removePosY = -node.Height 
            if nowPosY <= removePosY then
                node:removeFromParent(false)
                self.pushSlotNodeToPoolBySymobolType(node)  
                self:popUpSymbolList()
            end
        end

    end
end

function SpeicalReel:setRunCreateNodePos(newNode)
    local topY = self:getLastSymbolTopY()
    local newPosY = topY + newNode.Height * ANCHOR_POINT_Y
    newNode:setPosition(cc.p(0, newPosY))
end

function SpeicalReel:getLastSymbolTopY( )
    local lastNode = self:getLastSymbolNode()
    local topY = 0
    
    if lastNode == nil then
        return topY, lastNode
    end

    local lastNodePosY = lastNode:getPositionY()
    local topY = lastNode.Height * (1 - ANCHOR_POINT_Y) + lastNodePosY
    return topY, lastNode
end

function SpeicalReel:getNodeTopY(node)
    local nodePosY = node:getPositionY()
    local topY = node.Height * ANCHOR_POINT_Y + nodePosY
    return topY
end

function SpeicalReel:getAnchorPointY()
    return ANCHOR_POINT_Y
end

function SpeicalReel:setAnchorPointY(anchorPointY)
    ANCHOR_POINT_Y = anchorPointY
end

function SpeicalReel:getDisToReelLowBoundary(node)
    local nodePosY = node:getPositionY()
    local dis = nodePosY - node.Height * ANCHOR_POINT_Y
    return dis
end

--[[
    @desc:创建下个信号 并计算出停止距离
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function SpeicalReel:createNextNode()

    if self:getLastSymbolTopY() >  self.m_reelHeight then
        --最后一个Node > 上边界 创建新的node  反之创建
        return 
    end

    local nextNodeData = self:getNextRunData()
    if nextNodeData == nil then
        --没有数据了
        return 
    end

    local node = self.getSlotNodeBySymbolType(nextNodeData.SymbolType)
    node.Height = nextNodeData.Height

    node.isEndNode = nextNodeData.Last
    self.m_clipNode:addChild(node, nextNodeData.Zorder) 
    self:setRunCreateNodePos(node)
    self:pushToSymbolList(node)

    if nextNodeData.Last and self.m_endDis == nil then
        --创建出EndNode 计算出还需多长距离停止移动
        self.m_endDis = self:getDisToReelLowBoundary(node)
    end

    --是否超过上边界 没有的话需要继续创建
    if self:getNodeTopY(node) <= self.m_reelHeight then
        self:createNextNode()
    end
end 

function SpeicalReel:changeReelStatus(status)
    self.m_runStatus = status
end

function SpeicalReel:getReelStatus()
    return self.m_runStatus
end

--[[
    @desc: 滚动逻辑
    author:{author}
    time:2018-11-28 15:18:59
    @return:
]]
function SpeicalReel:beginMove()

    if self:getReelStatus() ~= REEL_STATUS.IDLE then
        return 
    end
    self:changeReelStatus(REEL_STATUS.RUNNING)
    local bEndMove = false
    self.m_endNode = nil
    self.m_endDis = nil

    self:onUpdate(function(dt)
        if globalData.gameRunPause then
            return
        end
        if bEndMove then
            self:unscheduleUpdate()
            self:runResAction()
            return
        end        
        self:createNextNode()
        self:setDtMoveDis(dt)
        if self.m_endDis ~= nil then
            --判断是否结束
            local endDis = self.m_endDis + self.m_dtMoveDis
            if endDis <= 0 then
                self.m_dtMoveDis = -self.m_endDis
                bEndMove = true
            else
                self.m_endDis = endDis
            end
        end

        self:removeBelowReelSymbol()
        self:updateSymbolPosY()
    end)
end

--每帧走的距离
function SpeicalReel:setDtMoveDis(dt)
    self.m_dtMoveDis = -dt * MOVE_SPEED
end

--回弹处理
function SpeicalReel:runResAction()
    local downDelayTime = 0
    for index = 1, #self.m_symbolNodeList do
        local node = self.m_symbolNodeList[index]
        local actionTable , downTime = self:getResAction()
        node:runAction(cc.Sequence:create(actionTable))
        if downDelayTime <  downTime then
            downDelayTime = downTime
        end
    end 

    performWithDelay(self,function()
       --滚动完毕
       self:runReelDown()
    end,downDelayTime)
end

function SpeicalReel:runReelDown()
    self:changeReelStatus(REEL_STATUS.IDLE)
    self.m_dataListPoint = 1
end

function SpeicalReel:setEndCallBackFun(func)
    self.m_endCallBackFun = func
end

--获取回弹action
function SpeicalReel:getResAction()
    local timeDown = 0
    local speedActionTable = {}
    local dis = self.RES_DIS 
    local speedStart = MOVE_SPEED
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end

    local moveBy = cc.MoveBy:create(0.1,cc.p(0, -self.RES_DIS))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    
    return speedActionTable, timeDown
end

--[[
    @desc: 置换层级
    author:{author}
    time:2018-11-28 18:38:19
    @return:
]]
--提高endNode层级
function SpeicalReel:raiseEndNodeZorder()
    -- self.m_runclipNode
end

--恢复endNode层级
function SpeicalReel:resetEndNodeZorder()
    
end

function SpeicalReel:onExit()
    util_resetChildReferenceCount(self.m_clipNode)
end

function SpeicalReel:onEnter()    
end

return SpeicalReel


--example
-- local SpeicalReel = require("Levels.SpeicalReel")
--     self.speicalReel =  SpeicalReel:create()
--     self.speicalReel:init(200 ,302, function(symbolType)
--         return self:getSlotNodeBySymbolType(symbolType)
--     end,
--     function(targSp)
--         self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
--     end
--     )
--     -- {SymbolType = 1, Zorder = 1, Width = 1, Height = 1 ,Last = false, AnchorPointY = 0.2}
--     local dataList = 
--     {
--     {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},
--     {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--     }
--     self.speicalReel:initFirstSymbolBySymbols(dataList)
--     self.speicalReel:setPosition(cc.p(200, 200))
--     self:addChild( self.speicalReel, 100000)

--     local dataListReal = 
--     {
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},

--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, Zorder = 1, Width = 200, Height = 151 ,Last = false, AnchorPointY = 0.5},
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, Zorder = 1, Width = 200, Height = 151 ,Last = true, AnchorPointY = 0.5},
--         {SymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, Zorder = 1, Width = 200, Height = 151 ,Last = true, AnchorPointY = 0.5},

--     }
--     self.speicalReel:initRunDate(dataListReal)