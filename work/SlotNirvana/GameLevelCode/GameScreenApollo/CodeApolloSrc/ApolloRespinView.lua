

local ApolloRespinView = class("ApolloRespinView", util_require("Levels.RespinView"))
local BASE_COL_INTERVAL = 3

function ApolloRespinView:ctor()
	self.super.ctor(self)
	self.m_isQuickRun = false--是否快滚
	self.m_isBigres = false--是否回弹
end
function ApolloRespinView:setIsQuickRun(isQuick)
	self.m_isQuickRun = isQuick
end
function ApolloRespinView:setIsBigres(isBigres)
	self.m_isBigres = isBigres
end
function ApolloRespinView:runNodeEnd(endNode)
	local info = self:getEndTypeInfo(endNode.p_symbolType)
	if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
		endNode:runAnim(info.runEndAnimaName, false,function ()
			endNode:runAnim("idleframe",true)
		end)
	end
	if endNode.m_specialRunUI then
		endNode.m_specialRunUI:beginMove()
	end
end

function ApolloRespinView:oneReelDown(col)
	local bonusSound = 0
	for row = 1,self.m_machine.m_iReelRowNum do
		local slot = self:getRespinNode(row,col)
		if slot:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			local symbolType = slot.m_runLastNodeType
			if self.m_machine:isFixSymbol(symbolType) == true then
				bonusSound = 1
			end
		end
	end
	if bonusSound > 0 then
        gLobalSoundManager:playSound("ApolloSounds/music_Apollo_bonusfall.mp3")
	else
		gLobalSoundManager:playSound("ApolloSounds/music_Apollo_ReelDown.mp3")
	end
end
---获取所有参与结算节点 不排序
function ApolloRespinView:getAllCleaningNodeNoSort()
	local cleaningNodes = {}
	local childs = self:getChildren()

	for i=1,#childs do
		local node = childs[i]
		if node:getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
			cleaningNodes[#cleaningNodes + 1] = node
		end
	end
	return cleaningNodes
end

---获取所有参与结算节点并排序
function ApolloRespinView:getAllCleaningNode()
	local cleaningNodes = self:getAllCleaningNodeNoSort()

	--从 从上到下 左到右排序
	local sortNode = {}
	for iCol = 1 , self.m_machineColmn do
		local sameRowNode = {}
		for i = 1, #cleaningNodes do
			local  node = cleaningNodes[i]
			if node.p_cloumnIndex == iCol then
				sameRowNode[#sameRowNode + 1] = node
			end
		end
		table.sort( sameRowNode, function(a, b)
			return b.p_rowIndex < a.p_rowIndex
		end)

		for i=1,#sameRowNode do
			sortNode[#sortNode + 1] = sameRowNode[i]
		end
	end
	cleaningNodes = sortNode
	return cleaningNodes
end

function ApolloRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
	local quickIndex = 0
	for j = 1,#self.m_respinNodes do
		local repsinNode = self.m_respinNodes[j]
		local bFix = false 
		local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL

		--设置快滚
		if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			repsinNode:changeResDis(false)
			if self.m_isQuickRun then
				quickIndex = quickIndex + 1
				runLong = quickIndex * 70
				repsinNode:changeRunSpeed(true)
				repsinNode:changeResDis(true)
			end
			if self.m_isBigres then
				repsinNode:changeResDis(true)
			end
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
return ApolloRespinView