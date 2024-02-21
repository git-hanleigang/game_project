---
--xcyy
--2018年5月23日
--WitchyHallowinRespinView.lua
local PublicConfig = require "WitchyHallowinPublicConfig"
local WitchyHallowinRespinView = class("WitchyHallowinRespinView",util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3


function WitchyHallowinRespinView:ctor()
    WitchyHallowinRespinView.super.ctor(self)
    self.m_isQuickRun = false
    self.m_quickRunNode = nil

    self.m_tipNodes = {}
    self.m_bonusDown = {}
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function WitchyHallowinRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
    self.m_machineElementData = machineElement
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

    self:addBorderLine()

    self:readyMove()
end

function WitchyHallowinRespinView:createRespinNode(symbolNode, status)

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

    local colorNode = util_createAnimation("WitchyHallowin_diban.csb")
    colorNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    self:addChild(colorNode, VIEW_ZORDER.REPSINNODE - 100)

    self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex),130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        respinNode.m_baseFirstNode = symbolNode
        symbolNode:runAnim("idleframe2",true)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

    respinNode:addTipNode(self,VIEW_ZORDER.REPSINNODE + 30)
end

--repsinNode滚动完毕后 置换层级
function WitchyHallowinRespinView:respinNodeEndCallBack(endNode, status)
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

        self.m_machine:delayCallBack(20 / 30,function(  )
            --图标显示idle
            self:showSymbolIdleAni()
        end)

        

        self.m_isQuickRun = false
        self.m_quickRunNode = nil

        local unLockNodes = {}
        for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]
            end
            self.m_respinNodes[i]:hideGrandTip()
        end

        if #unLockNodes == 1 and self.m_machine.m_runSpinResultData.p_reSpinCurCount > 0 then
            unLockNodes[1]:showGrandTip()
        end
    end
end

function WitchyHallowinRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        endNode:runAnim(info.runEndAnimaName, false,function(  )
            endNode:runAnim("idleframe2", true)
        end)

        


        if self.m_isQuickRun then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_bonus_down)
        else
            if self.m_machine:checkControlerReelType() then
                if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                    self.m_machine:setGameSpinStage(QUICK_RUN)
                end
                self.m_machine:checkPlayBonusDownSound(endNode.p_cloumnIndex)
                
            else
                if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                    self.m_machine.m_parent:setGameSpinStage(QUICK_RUN)
                end
                self.m_machine.m_parent:checkPlayBonusDownSound(endNode.p_cloumnIndex)
            end
        end
        
    end
    -- body
end

--[[
    获取respinNode
]]
function WitchyHallowinRespinView:getRespinNodeIndex(col, row)
    return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
    根据行列获取respinNode
]]
function WitchyHallowinRespinView:getRespinNodeByRowAndCol(col,row)
    local respinNodeIndex = self:getRespinNodeIndex(col,row)
    local respinNode = self.m_respinNodes[respinNodeIndex]
    return respinNode
end

--组织滚动信息 开始滚动
function WitchyHallowinRespinView:startMove()
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

    self.m_isLastSpin = false

    if #unLockNodes == 1 then
        unLockNodes[1]:showGrandTip()

        if self.m_machine.m_runSpinResultData.p_reSpinCurCount - 1 == 0 then
            self.m_isLastSpin = true
        end

        unLockNodes[1]:changeRunSpeed(true)
        self.m_isQuickRun = true
        self.m_quickRunNode = unLockNodes[1]
    else
        for k,unlockNode in pairs(unLockNodes) do
            unlockNode:hideGrandTip()
        end

        
    end
end

---获取所有参与结算节点
function WitchyHallowinRespinView:getAllCleaningNode()
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
        
    end
    return cleaningNodes
end

function WitchyHallowinRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false 
        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
        if repsinNode.m_isQuick then
            runLong = (self.m_baseRunNum + 5 * BASE_COL_INTERVAL) * 2

            --2个轮盘同时快滚时
            if self.m_machine:checkControlerReelType() and self.m_machine.m_isDoubleReels then
                if self.m_machine.m_miniMachine.m_respinView.m_isQuickRun then
                    runLong = (self.m_baseRunNum + 5 * BASE_COL_INTERVAL) * 5
                end
            end
        end
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

--[[
      添加分割线
]]
function WitchyHallowinRespinView:addBorderLine( )
    local line = util_createAnimation("WitchyHallowin_Respinjiange.csb")
    self:addChild(line,VIEW_ZORDER.REPSINNODE + 20)
    line:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_jiange"),self))
end

function WitchyHallowinRespinView:oneReelDown(colIndex)

    self.m_machine:respinOneReelDown(colIndex,self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP)
    
end

--[[
    拉镜头时图标期待动画
]]
function WitchyHallowinRespinView:showExpectAni( )
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("actionframe1",true)
        end
    end
end

--[[
    图标idle
]]
function WitchyHallowinRespinView:showSymbolIdleAni()
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("idleframe2",true)
        end
    end
end

return WitchyHallowinRespinView