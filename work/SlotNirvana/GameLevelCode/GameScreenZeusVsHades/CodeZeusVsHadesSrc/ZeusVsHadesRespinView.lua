

local ZeusVsHadesRespinView = class("ZeusVsHadesRespinView", util_require("Levels.RespinView"))
local BASE_COL_INTERVAL = 3
local VIEW_ZORDER = 
{
	NORMAL = 100,
	REPSINNODE = 1,
}
function ZeusVsHadesRespinView:ctor()
	self.super.ctor(self)
	self.m_isQuickRun = false--是否快滚
	self.m_isBigres = false--是否回弹
end
function ZeusVsHadesRespinView:setIsQuickRun(isQuick)
	self.m_isQuickRun = isQuick
end
function ZeusVsHadesRespinView:setIsBigres(isBigres)
	self.m_isBigres = isBigres
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function ZeusVsHadesRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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

		local status = nodeInfo.status
		self:createRespinNode(machineNode, status,nodeInfo.teamType)
	end

	self:readyMove()
end
function ZeusVsHadesRespinView:createRespinNode(symbolNode, status,teamType)

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
    
	respinNode:setTeamType(teamType)
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
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

function ZeusVsHadesRespinView:runNodeEnd(endNode)
	local info = self:getEndTypeInfo(endNode.p_symbolType)
	if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
		endNode:runAnim(info.runEndAnimaName, false)
	elseif self.m_machine:isPlunderSymbol(endNode.p_symbolType) or self.m_machine:isCollectSymbol(endNode.p_symbolType) then
		endNode:runAnim("buling",false)
		if endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_PLUNDER then
			gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_PLUNDERBuling.mp3")
		elseif endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_PLUNDER_2 then
			gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_PLUNDER2Buling.mp3")
		elseif endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_COLLECT then
			gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_COLLECTBuling.mp3")
		elseif endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_COLLECT_2 then
			gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_COLLECT2Buling.mp3")
		end
	end
end

function ZeusVsHadesRespinView:oneReelDown(col)
	local bonusSound = 0
	for row = 1,self.m_machine.m_iReelRowNum do
		local slot = self:getRespinNode(row,col)
		if slot:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			local symbolType = slot.m_runLastNodeType
			if self:getTypeIsEndType(symbolType) == true then
				bonusSound = 1
			end
		end
	end
	if bonusSound > 0 then
        
	else
		
	end
end
---获取所有参与结算节点 不排序
function ZeusVsHadesRespinView:getAllCleaningNodeNoSort()
	local zeusCleaningNodes = {}
	local hadesCleaningNodes = {}
	local childs = self:getChildren()

	for i = 1,#childs do
		local node = childs[i]
		if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
			if node.p_symbolType == self.m_machine.SYMBOL_SCORE_MULTIPLE then
				zeusCleaningNodes[#zeusCleaningNodes + 1] = node
			elseif node.p_symbolType == self.m_machine.SYMBOL_SCORE_MULTIPLE_2 then
				hadesCleaningNodes[#hadesCleaningNodes + 1] = node
			end
		end
	end
	return zeusCleaningNodes,hadesCleaningNodes
end

---获取所有参与结算节点并排序
function ZeusVsHadesRespinView:getAllCleaningNode()
	local zeusCleaningNodes,hadesCleaningNodes = self:getAllCleaningNodeNoSort()

	--从 上到下 左到右排序
	local sortNode = {}
	if #zeusCleaningNodes > 0 then
		for iCol = 1 , self.m_machineColmn do
			local sameRowNode = {}
			for i = 1, #zeusCleaningNodes do
				local node = zeusCleaningNodes[i]
				if node.p_cloumnIndex == iCol then
					sameRowNode[#sameRowNode + 1] = node
				end
			end
			table.sort( sameRowNode, function(a, b)
				return b.p_rowIndex < a.p_rowIndex
			end)

			for i = 1,#sameRowNode do
				sortNode[#sortNode + 1] = sameRowNode[i]
			end
		end
		zeusCleaningNodes = sortNode
	end

	--从上到下 右到左排序
	if #hadesCleaningNodes > 0 then
		local sortNode = {}
		for iCol = self.m_machineColmn,1, -1 do
			local sameRowNode = {}
			for i = 1, #hadesCleaningNodes do
				local node = hadesCleaningNodes[i]
				if node.p_cloumnIndex == iCol then
					sameRowNode[#sameRowNode + 1] = node
				end
			end
			table.sort( sameRowNode, function(a, b)
				return b.p_rowIndex < a.p_rowIndex
			end)
			for i = 1,#sameRowNode do
				sortNode[#sortNode + 1] = sameRowNode[i]
			end
		end
		hadesCleaningNodes = sortNode
	end

	return zeusCleaningNodes,hadesCleaningNodes
end

function ZeusVsHadesRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
	for j = 1,#self.m_respinNodes do
		local repsinNode = self.m_respinNodes[j]
		local bFix = false 
		local runLong = 0
		if repsinNode.p_colIndex <= 5 then
			runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
		else
			runLong = self.m_baseRunNum + (10 - repsinNode.p_colIndex) * BASE_COL_INTERVAL
		end

		for i = 1, #storedNodeInfo do
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

--组织滚动信息 开始滚动   isRunZeus是不是只转宙斯阵营图标
function ZeusVsHadesRespinView:startMove(isRunZeus)
	self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
	self.m_respinNodeRunCount = 0
	self.m_respinNodeStopCount = 0
	for i = 1,#self.m_respinNodes do
		if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			if isRunZeus == true then
				if self.m_respinNodes[i].m_teamType == 0 then
					self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
					self.m_respinNodes[i]:startMove()
				end
			else
				self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
				self.m_respinNodes[i]:startMove()
			end
		end
	end
end

--获取最终停止信号
function ZeusVsHadesRespinView:getEndSlotsNode(col,row)
	local childs = self:getChildren()
	for i = 1,#childs do
		local node = childs[i]
		if node:getTag() == self.REPIN_NODE_TAG then
			if node.p_rowIndex == row  and node.p_cloumnIndex == col then
				return node
		  	end
		end
	end
	for i = 1,#self.m_respinNodes do
		local respinNode = self.m_respinNodes[i]
		if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			if respinNode.p_rowIndex == row and respinNode.p_colIndex == col then
				return respinNode:getLastNode()
		  	end
		end
	end
end
function ZeusVsHadesRespinView:changeTeamType(machine,teamType,col,row)
	local changeSymbolNode = nil
	local childs = self:getChildren()
	for i = 1,#childs do
		local node = childs[i]
		if node:getTag() == self.REPIN_NODE_TAG then
			if node.p_rowIndex == row  and node.p_cloumnIndex == col then
				--node图标变为对应阵营的图标
				local changeSymbolType = nil
				if teamType == 0 then
					changeSymbolType = machine.SYMBOL_SCORE_MULTIPLE
				else
					changeSymbolType = machine.SYMBOL_SCORE_MULTIPLE_2
				end
				local numStr = node:getCcbProperty("m_lb_beishu"):getString()
				node:changeCCBByName(machine:getSymbolCCBNameByType(machine,changeSymbolType ), changeSymbolType)
				node:getCcbProperty("m_lb_beishu"):setString(numStr)
				node:runAnim("idleframe1")
				changeSymbolNode = node
				break
		  	end
		end
	end

	for i = 1,#self.m_respinNodes do
		local respinNode = self.m_respinNodes[i]
		if respinNode.p_rowIndex == row and respinNode.p_colIndex == col then
			respinNode:setTeamType(teamType)
			respinNode:initClipOpacity(130)
			respinNode:initRunningData()
			if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
				--图标换成respin普通图标
				local changeSymbolType = nil
				if teamType == 0 then
					changeSymbolType = machine.SYMBOL_SCORE_RESPINNORMAL
				else
					changeSymbolType = machine.SYMBOL_SCORE_RESPINNORMAL_2
				end
				respinNode:getLastNode():changeCCBByName(machine:getSymbolCCBNameByType(machine,changeSymbolType ), changeSymbolType)
				respinNode:getLastNode():changeSymbolImageByName(machine:getSymbolCCBNameByType(machine,changeSymbolType))
				changeSymbolNode = respinNode
			end
			break
		end
	end
	
	return changeSymbolNode
end
--所有teamType阵营图标滚轴变暗
function ZeusVsHadesRespinView:allTeamChangeDark(teamType)
	for i = 1,#self.m_respinNodes do
		local respinNode = self.m_respinNodes[i]
		if respinNode.m_teamType == teamType then
			respinNode.m_colorNodeBg:playAction("dark")
			if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
				respinNode:getLastNode():runAnim("dark")
			else
				local childs = self:getChildren()
				for i = 1,#childs do
					local node = childs[i]
					if node:getTag() == self.REPIN_NODE_TAG then
						if node.p_rowIndex == respinNode.p_rowIndex  and node.p_cloumnIndex == respinNode.p_colIndex then
							node:runAnim("dark")
							break
						end
					end
				end
			end
		end
	end
end
--所有teamType阵营图标滚轴变亮
function ZeusVsHadesRespinView:allTeamChangeLight(teamType)
	for i = 1,#self.m_respinNodes do
		local respinNode = self.m_respinNodes[i]
		if respinNode.m_teamType == teamType then
			respinNode.m_colorNodeBg:playAction("darkover")
			if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
				respinNode:getLastNode():runAnim("darkover")
			else
				local childs = self:getChildren()
				for i = 1,#childs do
					local node = childs[i]
					if node:getTag() == self.REPIN_NODE_TAG then
						if node.p_rowIndex == respinNode.p_rowIndex  and node.p_cloumnIndex == respinNode.p_colIndex then
							node:runAnim("darkover")
							break
						end
					end
				end
			end
		end
	end
end
return ZeusVsHadesRespinView