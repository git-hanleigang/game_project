---
--xcyy
--2018年5月23日
--TheHonorOfZorroRespinView.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroRespinView = class("TheHonorOfZorroRespinView",util_require("Levels.RespinView"))
local FrameLoadManager = util_require("manager/FrameLoadManager"):getInstance()

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3


function TheHonorOfZorroRespinView:ctor()
    TheHonorOfZorroRespinView.super.ctor(self)
    self.m_isQuickRun = false

    self.m_bonusDown = {}
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function TheHonorOfZorroRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
    self.m_machineElementData = machineElement
    
    --分割线
    self.m_lineAni = util_createAnimation("TheHonorOfZorro_jian.csb")
    self:addChild(self.m_lineAni,VIEW_ZORDER.NORMAL + 50)
    util_setCascadeOpacityEnabledRescursion(self,true)

    for i=1,#machineElement do
          local nodeInfo = machineElement[i]
          local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

          local pos = self:convertToNodeSpace(nodeInfo.Pos)
          machineNode:setPosition(pos)
          local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - machineNode.p_rowIndex + machineNode.p_cloumnIndex * 10
          self:addChild(machineNode, zOrder, self.REPIN_NODE_TAG)
          machineNode:setVisible(nodeInfo.isVisible)
          if nodeInfo.isVisible then
                -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
          end

          local status = nodeInfo.status
          self:createRespinNode(machineNode, status)
    end

    self:readyMove()
end

function TheHonorOfZorroRespinView:createRespinNode(symbolNode, status)

    local respinNode = util_createView(self.m_respinNodeName)
    respinNode:setMachine(self.m_machine)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
    
    respinNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    respinNode:setReelDownCallBack(function(symbolType, status)
        if self.respinNodeEndCallBack ~= nil then
            self:respinNodeEndCallBack(symbolType, status)
        end
    end, function(symbolType)
        if self.respinNodeEndBeforeResCallBack ~= nil then
            self:respinNodeEndBeforeResCallBack(symbolType)
        end
    end)

    self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
    
    respinNode:initClipNode(nil,130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()

    self.m_machine:runSymbolIdleLoop(symbolNode,"idleframe2")
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        respinNode.m_baseFirstNode = symbolNode
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
    respinNode:setParentView(self)
end

--repsinNode滚动完毕后 置换层级
function TheHonorOfZorroRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + endNode.p_cloumnIndex * 10)
        endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        self.m_machine:reSpinReelDown()
    end
end

function TheHonorOfZorroRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        endNode:runAnim(info.runEndAnimaName, false,function(  )
            self.m_machine:runSymbolIdleLoop(endNode,"idleframe2")
        end)

        if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
            self.m_machine:setGameSpinStage(QUICK_RUN)
        end
        self.m_machine:checkPlayBonusDownSound(endNode.p_cloumnIndex)
    end
    -- body
end

--[[
    获取respinNode
]]
function TheHonorOfZorroRespinView:getRespinNodeIndex(col, row)
    return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
    根据行列获取respinNode
]]
function TheHonorOfZorroRespinView:getRespinNodeByRowAndCol(col,row)
    local respinNodeIndex = self:getRespinNodeIndex(col,row)
    local respinNode = self.m_respinNodes[respinNodeIndex]
    return respinNode
end

--[[
    根据行列获取小块
]]
function TheHonorOfZorroRespinView:getSymbolByRowAndCol(col,row)
    local respinNode = self:getRespinNodeByRowAndCol(col,row)
    return respinNode.m_baseFirstNode
end

--组织滚动信息 开始滚动
function TheHonorOfZorroRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    local unLockNodes = {}
    self.m_bonusDown = {}
    for i=1,#self.m_respinNodes do
        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:changeRunSpeed(false)
            self.m_respinNodes[i]:startMove()
            unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]
        end
    end
end

---获取所有参与结算节点
function TheHonorOfZorroRespinView:getAllCleaningNode(unLockRow)
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) and symbolNode.p_rowIndex <= unLockRow then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
        
    end
    return cleaningNodes
end

function TheHonorOfZorroRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false 
        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
        for i=1, #storedNodeInfo do
            local stored = storedNodeInfo[i]
            if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                repsinNode:setRunInfo(runLong, stored.type)
                bFix = true
            end
        end
        
        for i=1,#unStoredReels do
            local data = unStoredReels[i]
            if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                    repsinNode:setRunInfo(runLong, data.type)
            end
        end
    end
end

function TheHonorOfZorroRespinView:oneReelDown(colIndex)

    self.m_machine:respinOneReelDown(colIndex,self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP)
    
end

--[[
    渐隐出现
]]
function TheHonorOfZorroRespinView:runFadeAni(func)
    for index = 1,#self.m_respinNodes do
        self.m_respinNodes[index]:runFadeAni()
        if self.m_respinNodes[index]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodes[index]:setVisible(false)
        end
    end
    self.m_machine:delayCallBack(0.5,function()
        for index = 1,#self.m_respinNodes do
            self.m_respinNodes[index]:setVisible(true)
            self.m_respinNodes[index].m_baseFirstNode:setVisible(true)
        end
    end)
end

--[[
    分割线动画
]]
function TheHonorOfZorroRespinView:runShowLineAni()
    for index = 1,#self.m_respinNodes do
        self.m_respinNodes[index]:setVisible(false)
        self.m_respinNodes[index].m_baseFirstNode:setVisible(false)
    end
    if self.m_lineAni then
        self.m_lineAni:runCsbAction("actionframe")
    end
    
end

return TheHonorOfZorroRespinView