
-- FIX IOS 139 1
local TrainYourDragonRespinView = class("TrainYourDragonRespinView", util_require("Levels.RespinView"))
--初始化时创建滚轴
function TrainYourDragonRespinView:createRespinNode(symbolNode, status)
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

    self:addChild(respinNode,1)--VIEW_ZORDER.REPSINNODE = 1
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex))
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
		local newSymbolNode = self:cloneSymbolNode(symbolNode)
		newSymbolNode:setPosition(cc.p(symbolNode:getPosition()))
		self:addChild(newSymbolNode, symbolNode:getLocalZOrder(), self.REPIN_NODE_TAG)
		newSymbolNode:playAction("idleframe",true)
		
		respinNode:setFirstSlotNode(symbolNode)
		respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
		-- symbolNode:setVisible(false)

		symbolNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_SCORE_10), self.m_machine.SYMBOL_SCORE_10)
    else
		respinNode:setFirstSlotNode(symbolNode)
		respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

end
--一列滚完 回弹前
function TrainYourDragonRespinView:oneReelDown(col)
	local bonusSound = 0
	for row = 1,self.m_machine.m_iReelRowNum do
		local slot = self:getRespinNode(row,col)
		if slot:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			local symbolType = slot.m_runLastNodeType
			if symbolType == self.m_machine.SYMBOL_FIX_SYMBOL1 then
				if bonusSound < 1 then
					bonusSound = 1
				end
			elseif self.m_machine:isFixSymbol(symbolType) == true then
				bonusSound = 2
			end
		end
	end
	if bonusSound > 0 then
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_bonusBuling"..bonusSound..".mp3")
	else
		gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_ReelDown.mp3")
	end
end
--repsinNode滚动完毕后  一个滚轴滚完
function TrainYourDragonRespinView:respinNodeEndCallBack(endNode, status)
	--层级调换
	self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1
	local symbolNode = endNode
	if status == RESPIN_NODE_STATUS.LOCK then
		local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
		local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
		-- endNode:removeFromParent()
		-- self:addChild(endNode , REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex, self.REPIN_NODE_TAG)
		-- endNode:setPosition(pos)
		-- endNode:setVisible(false)
		symbolNode = self:cloneSymbolNode(endNode)
		self:addChild(symbolNode , REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex, self.REPIN_NODE_TAG)
		symbolNode:setPosition(pos)

		endNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_SCORE_10), self.m_machine.SYMBOL_SCORE_10)
	end
	self:runNodeEnd(symbolNode)
	if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
	   gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
	end
end
function TrainYourDragonRespinView:runNodeEnd(endNode)
	local info = self:getEndTypeInfo(endNode.p_symbolType)
	if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
		endNode:playAction(info.runEndAnimaName, false,function ()
			endNode:playAction("idleframe",true)
		end)
	end
end
--复制一个图标
function TrainYourDragonRespinView:cloneSymbolNode(endNode)
	local fileName = self.m_machine:getSymbolCCBNameByType(self.m_machine,endNode.p_symbolType)
	local symbolNode = util_createAnimation(fileName..".csb")
	symbolNode.p_symbolType = endNode.p_symbolType
	symbolNode.m_isLastSymbol = endNode.m_isLastSymbol
	symbolNode.p_rowIndex = endNode.p_rowIndex
	symbolNode.p_cloumnIndex = endNode.p_cloumnIndex
	if endNode.p_symbolType == self.m_machine.SYMBOL_FIX_SYMBOL2 then
		self.m_machine:setSpecialNodeScore(nil,{symbolNode})
	end
	symbolNode:findChild("xing_bg"):setVisible(false)
	return symbolNode
end
--获得一行的图标
function TrainYourDragonRespinView:getOneRowRespinNode(row)
	local endSlotNode = {}
	local childs = self:getChildren()

	for i=1,#childs do
		local node = childs[i]
		if node:getTag() == self.REPIN_NODE_TAG and node.p_rowIndex == row then
			endSlotNode[#endSlotNode + 1] =  node
		end
	end
	return endSlotNode
end
---获取所有参与结算节点
function TrainYourDragonRespinView:getAllRespinNode()
	local endSlotNode = {}
	local childs = self:getChildren()
	for i=1,#childs do
		local node = childs[i]
		if node:getTag() == self.REPIN_NODE_TAG then
			endSlotNode[#endSlotNode + 1] =  node
		end
	end
	return endSlotNode
end
--获取所有最终停止信号
function TrainYourDragonRespinView:getAllEndSlotsNode()
	local endSlotNode = {}
	for i=1,#self.m_respinNodes do
		local repsinNode = self.m_respinNodes[i]
		endSlotNode[#endSlotNode + 1] = repsinNode:getLastNode()
	end
	return endSlotNode
end
return TrainYourDragonRespinView