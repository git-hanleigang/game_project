local ZombieRockstarRespinView = class("ZombieRockstarRespinView", util_require("Levels.RespinView"))

local BASE_COL_INTERVAL = 2

function ZombieRockstarRespinView:ctor(params)
    ZombieRockstarRespinView.super.ctor(self,params)
    self.m_curNodeNumsList = {}
    self.m_curEndNodeList = {}
    self.m_buffNumsTriggerIdle = {7, 6, 7} -- 三种buff玩法 超过对应图标播放期待idle
end

--[[
    单格停止
]]
function ZombieRockstarRespinView:runNodeEnd(symbolNode)
    ZombieRockstarRespinView.super.runNodeEnd(self,symbolNode)
    self.m_machine:playCollectSymbolBulingEffect(symbolNode)

    if self.m_machine.m_isPlayBuffEffect > 0 then
        local symbolType = symbolNode.p_symbolType
        if symbolType ~= 100 then
            if self.m_curNodeNumsList[symbolType] then
                self.m_curNodeNumsList[symbolType] = self.m_curNodeNumsList[symbolType] + 1
            else
                self.m_curNodeNumsList[symbolType] = 1
            end
        end
        local curSymbolType = nil
        if self.m_machine.m_isPlayBuffEffect == 3 then
            curSymbolType = self.m_machine:getSpinResultReelsType(1, 3)
        end
        if table.nums(self.m_curNodeNumsList) > 0 then
            for _symbolType, _nodeNums in pairs(self.m_curNodeNumsList) do
                if _nodeNums >= self.m_buffNumsTriggerIdle[self.m_machine.m_isPlayBuffEffect] and _symbolType == symbolType then
                    if self.m_isChangeRunNums then
                        self.m_isChangeRunNums = false
                        self:changeRespinNodeRunNums()
                    end
                    if symbolNode.m_currAnimName ~= "idleframe3" then
                        symbolNode:runAnim("idleframe3", true)
                    end
                    
                    for _, _respinNode in ipairs(self.m_curEndNodeList) do
                        if _respinNode.p_symbolType == _symbolType then
                            if _respinNode.m_currAnimName ~= "idleframe3" then
                                _respinNode:runAnim("idleframe3", true)
                            end
                        end
                    end
                end
            end
        end

        if self.m_machine.m_isPlayBuffEffect == 3 then
            if curSymbolType == symbolType then
                if symbolNode.m_currAnimName ~= "idleframe3" then
                    symbolNode:runAnim("idleframe3", true)
                end
            end
        end
    end
    table.insert(self.m_curEndNodeList, symbolNode)

    self.m_machine:playRespinBulingEffect(symbolNode)
end

--组织滚动信息 开始滚动
function ZombieRockstarRespinView:startMove()
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_curNodeNumsList = {}
    self.m_curEndNodeList = {}

    -- buff1玩法 
    local features = self.m_machine.m_runSpinResultData.p_features or {}
    if features and #features == 2 and features[2] == 1 then
        local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
        self.m_curNodeNumsList[fsExtraData.symbol] = #fsExtraData.storedIcons
        for _, _pos in ipairs(fsExtraData.storedIcons) do
            local fixPos = self.m_machine:getRowAndColByPos(_pos)
            local respinNode = self:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
            table.insert(self.m_curEndNodeList, respinNode.m_baseFirstNode)
        end
        self.m_machine.m_isPlayBuffEffect = 1
    end
    self.m_isChangeRunNums = true
    self.m_isFirstPlayQuickSound = true
    self.isQuickRun = false
    ZombieRockstarRespinView.super.startMove(self)
end

--[[
    播放图标落地音效
]]
function ZombieRockstarRespinView:playSymbolDownSound(symbolType)
    
end

function ZombieRockstarRespinView:createRespinNode(symbolNode, status)
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

    local colorNode = util_createAnimation("ZombieRockstar_qipan_di.csb")
    colorNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    self:addChild(colorNode, -100)
    colorNode:setName("colorNode_"..symbolNode.p_rowIndex.."_"..symbolNode.p_cloumnIndex)

    self:addChild(respinNode, 1)
    
    respinNode:initClipNode(nil, 130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end

    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function ZombieRockstarRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
          self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
          machineNode:setVisible(nodeInfo.isVisible)
          if nodeInfo.isVisible then
                -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
          end

          local status = nodeInfo.status
          self:createRespinNode(machineNode, status)
    end

    self.m_respinLinesNode = util_createAnimation("ZombieRockstar_respin_lines.csb")
    self.m_respinLinesNode:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_respin_lines"), self))
    self:addChild(self.m_respinLinesNode, REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100)
    self.m_respinLinesNode:setPositionX(35)

    -- buff1 棋盘遮罩
    self.m_reelsDark = util_createAnimation("ZombieRockstar_buff1_dark.csb")
    self:addChild(self.m_reelsDark, 100)
    self.m_reelsDark:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_respin_tb"), self))
    self.m_reelsDark:setVisible(false)

    self:readyMove()
end

--[[
    检测锁定的小块是否需要放回去
]]
function ZombieRockstarRespinView:checkPutLockSymbolBack()
    for index = 1,#self.m_respinNodes do
        --默认锁定的小块需要放回去
        if self.m_respinNodes[index]:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            self:changeRespinNodeStatus(self.m_respinNodes[index],RESPIN_NODE_STATUS.IDLE)
        end
    end
end

--[[
    获取respinNode索引
]]
function ZombieRockstarRespinView:getRespinNodeIndex(col, row)
    return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
      根据行列获取respinNode
]]
function ZombieRockstarRespinView:getRespinNodeByRowAndCol(col,row)
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if respinNode.p_rowIndex == row and respinNode.p_colIndex == col then
            return respinNode
        end
    end
    
    return self.m_respinNodes[1]
end

--[[
    改变小块的锁定状态
]]
function ZombieRockstarRespinView:changeRespinNodeStatus(respinNode, isLock)
    if isLock then
        if not respinNode.isLocked then
            --锁定小块不能滚动
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)

            local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - respinNode.m_baseFirstNode.p_rowIndex +  respinNode.m_baseFirstNode.p_cloumnIndex
            --变更小块父节点
            local pos = util_convertToNodeSpace(respinNode.m_baseFirstNode,self)
            util_changeNodeParent(self,respinNode.m_baseFirstNode,zOrder)
            respinNode.m_baseFirstNode:setPosition(pos)
            respinNode.isLocked = true 
        end
    else
        --解除小块的锁定状态
        respinNode:setFirstSlotNode(respinNode.m_baseFirstNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
        respinNode.isLocked = false
    end
end

--[[
   判断是否在进行buff1 玩法
]]
function ZombieRockstarRespinView:cheakIsBuff1( )
    local freeSpinsTotalCount = self.m_machine.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_machine.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsTotalCount == 1 and freeSpinsLeftCount and freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

function ZombieRockstarRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    local getRespinNodeIndex = function(repsinNode)
        if self.m_machine:getCurrSpinMode() == RESPIN_MODE or self.m_machine.m_isPlayBuffEffect > 0 or self:cheakIsBuff1() then
            local row = repsinNode.p_rowIndex
            if repsinNode.p_rowIndex == 1 then
                row = 3 
            elseif repsinNode.p_rowIndex == 3 then
                row = 1
            end
            if self.m_machine.m_isPlayBuffEffect > 0 or self:cheakIsBuff1() then
                -- buff3 最后一个图标 特殊处理
                if self.m_machine.m_isPlayBuffEffect == 3 and row == 3 and repsinNode.p_colIndex == 5 then
                    return ((repsinNode.p_colIndex- 1)*3 + row) * 4 + 5
                end
                return ((repsinNode.p_colIndex- 1)*3 + row) * 4
            else
                return ((repsinNode.p_colIndex- 1)*3 + row) * BASE_COL_INTERVAL
            end
        else
            return (repsinNode.p_colIndex- 1) * 3
        end
    end

    for j=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
          local bFix = false 
          local runLong = self.m_baseRunNum + getRespinNodeIndex(repsinNode)
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
    动态修改 滚动长度
]]
function ZombieRockstarRespinView:changeRespinNodeRunNums( )
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        repsinNode.m_runNodeNum = repsinNode.m_runNodeNum + 3
    end
end

function ZombieRockstarRespinView:oneReelDown(_Col)
    if not self.isQuickRun then
        if self.m_machine.m_isPlayBuffEffect > 0 then
        else
            self.m_machine:slotLocalOneReelDown(_Col)
        end
    else
        if self.m_isFirstPlayQuickSound then
            self.m_isFirstPlayQuickSound = false
            self.m_machine:slotLocalQuickOneReelDown()
        end
    end
end

function ZombieRockstarRespinView:quicklyStop()
    ZombieRockstarRespinView.super.quicklyStop(self)
    self.isQuickRun = true
end

return ZombieRockstarRespinView 