
local GeminiJourneyPublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyRespinView = class("GeminiJourneyRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

local TAG_LIGHT_SINGLE = 1001
local LIGHT_SCALE = 1.4
local TOP_ZORDER = 10000
local BASE_COL_INTERVAL = 3

function GeminiJourneyRespinView:initUI(respinNodeName)
	GeminiJourneyRespinView.super.initUI(self, respinNodeName)
	-- 待集满光效数据
	self.m_lightData = {}
	-- 最后一个格子的Zorder
	self.quickRespinZorder = 0
	-- 最后一个格子快滚的respinNodeTbl
	self.m_lastRespinNodeTbl = {}
	-- 快滚是否已经执行过
	self.m_curIsQuickRun = false
	-- 是否快滚
	self.m_isQuickRun = false
	-- ku快滚音效标记
	self.m_reelRespinRunSoundTag = nil
 end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function GeminiJourneyRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun, _reelIndex)
	self.m_machineRow = machineRow 
	self.m_machineColmn = machineColmn
	self.m_startCallFunc = startCallFun
	self.m_respinNodes = {}
	self.m_respinBottomAni = {}
	self.m_reelIndex = _reelIndex
	self:setMachineType(machineColmn, machineRow)
	self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
	self.m_machineElementData = machineElement
	for i=1,#machineElement do
		local nodeInfo = machineElement[i]
		local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true, _reelIndex)

		local pos = self:convertToNodeSpace(nodeInfo.Pos)
		machineNode:setPosition(pos)
		self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
		machineNode:setVisible(nodeInfo.isVisible)
		if self.m_machine:getCurSymbolIsBonus(machineNode.p_symbolType) then
			local curRow = machineNode.p_rowIndex
			if self.m_machine.m_respinUnlockRowTbl[_reelIndex] and curRow <= self.m_machine.m_respinUnlockRowTbl[_reelIndex] then
				machineNode:runAnim("idleframe4", true)
			else
				machineNode:runAnim("idleframe2", true)
			end
		end

		if machineNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 then
			local curRow = machineNode.p_rowIndex
			if self.m_machine.m_respinUnlockRowTbl[_reelIndex] and curRow <= self.m_machine.m_respinUnlockRowTbl[_reelIndex] then
				self.m_machine:setSpecialNodeScoreBonus(machineNode, _reelIndex, nil, true)
				machineNode:runAnim("idleframe4", true)
			else
				machineNode:runAnim("idleframe3", true)
			end
		end
		if nodeInfo.isVisible then
			-- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
		end

		local status = nodeInfo.status
		self:createRespinNode(machineNode, status, _reelIndex)
	end

	self:readyMove()
end

function GeminiJourneyRespinView:createRespinNode(symbolNode, status, _reelIndex)
	local csbName = "Socre_GeminiJourney_Empty1.csb"
	if _reelIndex == 2 then
		csbName = "Socre_GeminiJourney_Empty2.csb"
	end
	local colorNode = util_createAnimation(csbName)
	colorNode:runCsbAction("idle", true)

	colorNode:setScale(1.0)
	colorNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
	self:addChild(colorNode)
	self.m_respinBottomAni[#self.m_respinBottomAni + 1] = colorNode

    local respinNode = util_createView(self.m_respinNodeName, self)
    respinNode:setMachine(self.m_machine)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(90, 90, 90, 458)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
    
    respinNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    respinNode:setReelDownCallBack(function(symbolType, status, _reelIndex)
		if self.respinNodeEndCallBack ~= nil then
			self:respinNodeEndCallBack(symbolType, status, _reelIndex)
		end
    end, function(symbolType)
		if self.respinNodeEndBeforeResCallBack ~= nil then
			self:respinNodeEndBeforeResCallBack(symbolType)
		end
    end)

    self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
    
	respinNode:setReelIndex(self.m_reelIndex)
	respinNode:initClipNode(nil, 30, _reelIndex)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
		-- respinNode:setLightFirstSlotNode(symbolNode)
		respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
		respinNode.m_clipNode:setVisible(false)
    else
		respinNode:setFirstSlotNode(symbolNode)
		respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
	-- util_changeNodeParent(respinNode.m_clipNode, symbolNode, SHOW_ZORDER.LIGHT_ORDER)
	-- symbolNode:setTag(self.REPIN_NODE_TAG)
	-- symbolNode:setPosition(cc.p(0, 0))
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
	-- respinNode:setVisible(false)
end

--[[
    获取respinNode索引
]]
function GeminiJourneyRespinView:getRespinNodeIndex(colIndex, rowIndex)
    return self.m_machine.m_iReelRowNum - rowIndex + 1 + (colIndex - 1) * self.m_machine.m_iReelRowNum
end

--[[
    根据行列获取respinNode
]]
function GeminiJourneyRespinView:getRespinNodeByRowAndCol(colIndex, rowIndex)
    local respinNodeIndex = self:getRespinNodeIndex(colIndex,rowIndex)
    local respinNode = self.m_respinNodes[respinNodeIndex]
    return respinNode
end

--[[
    根据行列获取小块
]]
function GeminiJourneyRespinView:getSymbolByRowAndCol(col,row)
    local respinNode = self:getRespinNodeByRowAndCol(col,row)
    return respinNode:getBaseShowSymbol()
end

--repsinNode滚动完毕后 置换层级
function GeminiJourneyRespinView:respinNodeEndCallBack(endNode, status, _reelIndex)
	--层级调换
	self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

	if status == RESPIN_NODE_STATUS.LOCK then
		  local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
		  local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
		  util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
		  local respinNode = self:getRespinNodeByRowAndCol(endNode.p_cloumnIndex,endNode.p_rowIndex)
		  respinNode.m_clipNode:setVisible(false)
		  endNode:setTag(self.REPIN_NODE_TAG)
		  endNode:setPosition(pos)
		  endNode:setTag(self.REPIN_NODE_TAG)
	end
	self:runNodeEnd(endNode, _reelIndex)

	if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
		gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)

		local respinCount = 0
		if self.m_reelIndex == 1 then
			respinCount = self.m_machine.m_runSpinResultData.p_rsExtraData.reels1.count
		else
			respinCount = self.m_machine.m_runSpinResultData.p_rsExtraData.reels2.count
		end
		--添加光效
		if respinCount > 0 then
			self:addRespinLightEffectSingle()
		end
	end
end

-- respin结束后置换层级
function GeminiJourneyRespinView:respinOverChangeNodeParent(_reelIndex, _symbolNode)
	-- 下压上；右压左
	local curZorder = _symbolNode.p_cloumnIndex * 10 - _symbolNode.p_rowIndex
	local worldPos = _symbolNode:getParent():convertToWorldSpace(cc.p(_symbolNode:getPositionX(), _symbolNode:getPositionY()))
	local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
	util_changeNodeParent(self, _symbolNode, SHOW_ZORDER.LIGHT_ORDER+curZorder)
	_symbolNode:setPosition(pos)
	_symbolNode:setTag(self.REPIN_NODE_TAG)
	if _symbolNode.p_rowIndex > self.m_machine.m_respinUnlockRowTbl[_reelIndex] then
		-- _symbolNode:runAni("over", false, function()
		-- 	_symbolNode:setVisible(false)
		-- end)
		_symbolNode:setVisible(false)
	end
end

-- 关闭裁剪层
function GeminiJourneyRespinView:closeShowClipNode()
	for key, respinNode in pairs(self.m_respinNodes) do
		if respinNode.m_clipNode then
			respinNode.m_clipNode:setVisible(false)
		end
	end
	-- 底图
	for key, colorNode in pairs(self.m_respinBottomAni) do
		if not tolua.isnull(colorNode) then
			colorNode:runCsbAction("over", false, function()
				colorNode:setVisible(false)
			end)
		end
	end
	
end

-- 打开小块node
function GeminiJourneyRespinView:startShowClipNode(_isStart)
	for key, respinNode in pairs(self.m_respinNodes) do
		if respinNode.m_clipNode then
			local colorNode = respinNode.m_clipNode:getChildByName("colorNode")
			if not tolua.isnull(colorNode) then
				if _isStart then
					colorNode:setVisible(true)
					colorNode:runCsbAction("start", false, function()
						colorNode:runCsbAction("idle", true)
					end)
				else
					colorNode:setVisible(false)
					colorNode:runCsbAction("idle", true)
				end
			end
		end
	end
end

function GeminiJourneyRespinView:runNodeEnd(endNode, _reelIndex)
	local curSymbolNodeRow = endNode.p_rowIndex
	if _reelIndex and self.m_machine.m_respinUnlockRowTbl[_reelIndex] and curSymbolNodeRow <= self.m_machine.m_respinUnlockRowTbl[_reelIndex] then
		if endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 then
			if self.isQuickRun then
				if self.m_machine:getRespinBulingState() then
					self.m_machine:setRespinBulingState(false)
					gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Respin_Bonus2_Buling)
				end
			else
				if self.curColSpecialPlaySound then
					gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Respin_Bonus2_Buling)
					self.curColSpecialPlaySound = nil
				end
			end
			endNode:runAnim("buling", false, function()
				endNode:runAnim("idleframe3", true)
			end)
		end

		if self.m_machine:getCurSymbolIsBonus(endNode.p_symbolType) then
			if self.isQuickRun then
				if not self.respinIsRow1 and not self.respinIsRow2 then
					if self.m_machine:getRespinBulingState() then
						self.m_machine:setRespinBulingState(false)
						gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Bonus_buling)
					end
				end
			else
				if self.curColPlaySound then
					gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Bonus_buling)
					self.curColPlaySound = nil
				end
			end
			endNode:runAnim("buling2", false, function()
				endNode:runAnim("idleframe4", true)
			end)
		end
	else
		if self.m_machine:getCurSymbolIsBonus(endNode.p_symbolType) then
			endNode:runAnim("idleframe4", true)
		end

		if endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 then
			endNode:runAnim("idleframe3", true)
		end
	end

	-- 当前位置有光效；播炸开光效
	if next(self.m_lightData) then
		if (self.m_machine:getCurSymbolIsBonus(endNode.p_symbolType) or endNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2) and endNode.p_rowIndex == self.m_lightData._curRow and endNode.p_cloumnIndex == self.m_lightData._curCol then
			self:stopQucikRunSound()
			self:clearLightAniByType(true, true)
		end
	end
end

function GeminiJourneyRespinView:quicklyStop()
	self.isQuickRun = true
	if self.m_reelRespinRunSoundTag then
        gLobalSoundManager:stopAudio(self.m_reelRespinRunSoundTag)
		self.m_reelRespinRunSoundTag = nil
    end
	for i=1,#self.m_respinNodes do
		local repsinNode = self.m_respinNodes[i]
		if repsinNode:getNodeRunning() then
			repsinNode:quicklyStop()
		end
	end

	self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
	if self.m_reelIndex == 2 then
		self.m_isQuickRun = true
	end

	local isHaveGrand1, isHaveGrand2 = self.m_machine:getCurSpinIsHaveGrand()
	if isHaveGrand1 and next(self.m_lightData) then
		self.m_machine.m_respinGrandDelayTbl[1] = 1.5
	end

	if isHaveGrand2 and next(self.m_lightData) then
		self.m_machine.m_respinGrandDelayTbl[2] = 1.5
	end
	

	if self.m_reelIndex == 2 and not tolua.isnull(self.m_respinActionNode) then
		local nodeZorder = self.quickRespinZorder or 0
		self.m_respinActionNode:stopAllActions()
		self.m_respinActionNode:setLocalZOrder(nodeZorder)
		self.m_respinActionNode:setScale(1.0)
	end
	gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Reel_QuickStop_Sound)
end

function GeminiJourneyRespinView:oneReelDown(iCol)
	self.curColPlaySound = iCol
	self.curColSpecialPlaySound = iCol
    -- if self.m_reelRespinRunSoundTag then
    --     gLobalSoundManager:stopAudio(self.m_reelRespinRunSoundTag)
	-- 	self.m_reelRespinRunSoundTag = nil
    -- end
	local curScale = 1
	if not tolua.isnull(self.m_respinActionNode) then
		curScale = self.m_respinActionNode:getScale()
	end
    if not self.isQuickRun and curScale == 1 then
		self.m_machine:slotLocalOneReelDown(iCol)
  	end
end

-- 回弹结束时关闭快停音效
function GeminiJourneyRespinView:stopQucikRunSound()
	if self.m_reelRespinRunSoundTag then
        gLobalSoundManager:stopAudio(self.m_reelRespinRunSoundTag)
		self.m_reelRespinRunSoundTag = nil
    end
end

--组织滚动信息 开始滚动
function GeminiJourneyRespinView:startMove()
	self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
	self.m_respinNodeRunCount = 0
	self.m_respinNodeStopCount = 0
	self.isQuickRun = false
	self.m_machine:setRespinBulingState(true)
	self.m_machine:setRespinLastSymbolState(true)
	--添加光效
	self:addRespinLightEffectSingle(true)

	for i=1,#self.m_respinNodes do
		if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
			self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
			self.m_respinNodes[i]:startMove()
		end
	end
end

-- 判断当前有多少bonus信号
function GeminiJourneyRespinView:getCurReelBonusCount(_reelData)
    local reels = _reelData
    local curBonusCount = 0
    for iCol = 1, self.m_machine.m_iReelColumnNum do
        for iRow = 1, self.m_machine.m_iReelRowNum do
            local symbolType = reels[iRow][iCol]
            if self.m_machine:getCurSymbolIsBonus(symbolType) or symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 then
                curBonusCount = curBonusCount + 1
            end
        end
    end

    return curBonusCount
end

--[[
      添加光效框 单个小块
]]
function GeminiJourneyRespinView:addRespinLightEffectSingle(_isStartMove)
	--reelData数据
	local reelData = nil
	local respinCount = 0
	if self.m_reelIndex == 1 then
		reelData = self.m_machine.m_runSpinResultData.p_rsExtraData.reels1.reelData
		respinCount = self.m_machine.m_runSpinResultData.p_rsExtraData.reels1.count
	else
		reelData = self.m_machine.m_runSpinResultData.p_rsExtraData.reels2.reelData
		respinCount = self.m_machine.m_runSpinResultData.p_rsExtraData.reels2.count
	end

	local curBonusCount = self:getCurReelBonusCount(reelData)
	if not reelData or respinCount == 0 then
		self.m_machine.m_respinTopNodeTbl[self.m_reelIndex]:removeAllChildren(true)
		return
	end

	--差一个集满就是24个；直接写死了
	if curBonusCount == 24 then
		for key, endNode in pairs(self.m_respinNodes) do
			if endNode.m_lastNode and not self.m_machine:getCurSymbolIsBonus(endNode.m_lastNode.p_symbolType)
			 and endNode.m_lastNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_BONUS_2
			 and not self.m_machine.m_respinTopNodeTbl[self.m_reelIndex]:getChildByTag(TAG_LIGHT_SINGLE) then
				local light_effect = util_createAnimation("GeminiJourney_Respin_run.csb")
				if self.m_machine:getRespinLastSymbolState() then
					self.m_machine:setRespinLastSymbolState(false)
					gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Respin_LastEffectShow)
				end
                light_effect:runCsbAction("start", false, function()
					light_effect:runCsbAction("idle2", true)
				end)
				self.m_machine.m_respinGrandDelayTbl[self.m_reelIndex] = 1.0
				self.m_respinActionNode = endNode

				local csbName = "Socre_GeminiJourney_Empty1.csb"
				if self.m_reelIndex == 2 then
					csbName = "Socre_GeminiJourney_Empty2.csb"
				end
				local colorNode = util_createAnimation(csbName)
				colorNode:runCsbAction("idle", true)

				colorNode:setScale(1.0)
				endNode.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)

				self.m_machine.m_respinTopNodeTbl[self.m_reelIndex]:removeAllChildren(true)
                self.m_machine.m_respinTopNodeTbl[self.m_reelIndex]:addChild(light_effect)
                light_effect:setTag(TAG_LIGHT_SINGLE)
                light_effect:setPosition(util_convertToNodeSpace(endNode.m_lastNode,self.m_machine.m_respinTopNodeTbl[self.m_reelIndex]))
				self.m_lightData._lightAni = light_effect
				self.m_lightData._curRow = endNode.m_lastNode.p_rowIndex
				self.m_lightData._curCol = endNode.m_lastNode.p_cloumnIndex
                break
			 end
		end

		-- 放大
		if _isStartMove then
			if respinCount == 1 then
				if self.m_reelIndex == 1 then
					self:lastRespinScaleAction()
				else
					if self.m_reelIndex == 2 and self.m_machine.m_leftReelIsStop then
						self:lastRespinScaleAction()
					end
				end
			end
		end
	else
		self.m_lightData = {}
	end
end

function GeminiJourneyRespinView:getScaleBigAni()
    local scaleAct = cc.ScaleTo:create(10/60, LIGHT_SCALE)
    return scaleAct
end

function GeminiJourneyRespinView:getScaleSmallAni()
    local scaleAct = cc.ScaleTo:create(10/60, 0)
    return scaleAct
end

-- 清除待集满的光效
function GeminiJourneyRespinView:clearLightAni(_overAniName, _isEndBuling)
	local overAniName = _overAniName
	local isEndBuling = _isEndBuling
	if next(self.m_lightData) then
		local lightAni = self.m_lightData._lightAni
		if not tolua.isnull(lightAni) then
			if not isEndBuling then
				lightAni:runAction(self:getScaleSmallAni())
			else
				lightAni:setScale(1.0)
			end
			lightAni:runCsbAction(overAniName, false, function()
				if not tolua.isnull(self.m_machine) then
					self.m_machine.m_respinTopNodeTbl[self.m_reelIndex]:removeAllChildren(true)
				end
			end)
		end
	end
	if not tolua.isnull(self.m_respinActionNode) then
		local nodeZorder = self.quickRespinZorder or 0
		-- self.m_respinActionNode:stopAllActions()
		self.m_respinActionNode:setLocalZOrder(nodeZorder)
		self.m_respinActionNode:setScale(1.0)
	end
	self.m_lightData = {}
end

-- 根据类型清除小块类型
-- _isEndBuling:是否最后是grand
function GeminiJourneyRespinView:clearLightAniByType(_isEndBuling, _isGrand)
	-- grand情况下，不清除；待最后小块落地清除
	if not _isEndBuling and _isGrand then
		return
	end
	local overAniName = "over"
	if _isEndBuling then
		overAniName = "over1"
	end

	self:clearLightAni(overAniName, _isEndBuling)
end

-- 最后一次光效和格子放大
function GeminiJourneyRespinView:lastRespinScaleAction()
	if self.m_curIsQuickRun then
		return
	end

	self.m_curIsQuickRun = true
	if not tolua.isnull(self.m_respinActionNode) then
		local zorder = self.m_respinActionNode:getLocalZOrder()
		if zorder ~= TOP_ZORDER then
			self.quickRespinZorder = zorder
		end
		if not self.m_isQuickRun then
			self.m_respinActionNode:runAction(self:getScaleBigAni())
			self.m_respinActionNode:setLocalZOrder(TOP_ZORDER)
		end
	end

	if next(self.m_lightData) then
		local lightAni = self.m_lightData._lightAni
		if not tolua.isnull(lightAni) then
			lightAni:runCsbAction("idle", true)
			lightAni:runAction(self:getScaleBigAni())
		end
	end

	-- 左边respin轮盘停轮后；右侧轮盘有快滚的话此时再快滚
	if next(self.m_lastRespinNodeTbl) then
		if not self.isQuickRun then
			self.m_reelRespinRunSoundTag = gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Respin_LastNodeQuick)
		end
		local respinNode = self.m_lastRespinNodeTbl._repsinNode
		local storedType = self.m_lastRespinNodeTbl._type
		respinNode:changeRunSpeed(true)
		respinNode:changeResDis(true)
	end
end

function GeminiJourneyRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
	self.respinIsRow1 = self.m_machine:getCurRespinIsRiseRow_1()
	self.respinIsRow2 = self.m_machine:getCurRespinIsRiseRow_2()
	local respinCount = 0
	if self.m_reelIndex == 1 then
		respinCount = self.m_machine.m_runSpinResultData.p_rsExtraData.reels1.count
	else
		respinCount = self.m_machine.m_runSpinResultData.p_rsExtraData.reels2.count
	end

	for j=1,#self.m_respinNodes do
		local respinNode = self.m_respinNodes[j]
		local bFix = false 
		local runLong = self.m_baseRunNum + (respinNode.p_colIndex- 1) * BASE_COL_INTERVAL
		if self.m_reelIndex == 2 and not self.m_machine.m_leftReelIsStop then
			runLong = self.m_baseRunNum + (self.m_machine.m_iReelColumnNum + respinNode.p_colIndex- 1) * BASE_COL_INTERVAL
		end
		for i=1, #storedNodeInfo do
			local stored = storedNodeInfo[i]
			if respinNode.p_rowIndex == stored.iX and respinNode.p_colIndex == stored.iY then
				if next(self.m_lightData) and respinNode.p_rowIndex == self.m_lightData._curRow and respinNode.p_colIndex == self.m_lightData._curCol then
					if self.m_reelIndex == 1 then
						respinNode:setRunInfo(runLong, stored.type)
						if respinCount == 0 then
							self.m_reelRespinRunSoundTag = gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Respin_LastNodeQuick)
							respinNode:setRunInfo(runLong*2, stored.type)
							respinNode:changeRunSpeed(true)
							respinNode:changeResDis(true)
						end
					else
						if self.m_machine.m_leftReelIsStop then
							respinNode:setRunInfo(runLong, stored.type)
							if respinCount == 0 then
								self.m_reelRespinRunSoundTag = gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_Respin_LastNodeQuick)
								respinNode:changeRunSpeed(true)
								respinNode:changeResDis(true)
								respinNode:setRunInfo(runLong*2, stored.type)
							end
						else
							self.m_lastRespinNodeTbl._repsinNode = respinNode
							self.m_lastRespinNodeTbl._type = stored.type
							respinNode:setRunInfo(runLong, stored.type)
							if respinCount == 0 then
								respinNode:setRunInfo(runLong*2, stored.type)
							end
						end
					end
				else
					respinNode:setRunInfo(runLong, stored.type)
				end
				bFix = true
			end
		end
		
		for i=1,#unStoredReels do
			local data = unStoredReels[i]
			if respinNode.p_rowIndex == data.iX and respinNode.p_colIndex == data.iY then
				respinNode:setRunInfo(runLong, data.type)
			end
		end
	end
end

-- function GeminiJourneyRespinView:getRespinEndNode(iX, iY)
-- 	local childs = self:getChildren()

-- 	for i=1,#childs do
-- 		local node = childs[i]
-- 		if node.getLastNode and node:getLastNode():getTag() == self.REPIN_NODE_TAG and node.p_rowIndex == iX  and node.p_colIndex == iY then
-- 			return node:getLastNode()
-- 		end
-- 	end
-- 	print("RESPINNODE NOT END!!!")
-- 	return nil
-- end

function GeminiJourneyRespinView:getRespinEndNode(iX, iY)
	local childs = self:getFixSlotsNode()

	for i=1,#childs do
		  local node = childs[i]

		  if node.p_rowIndex == iX  and node.p_cloumnIndex == iY then
				return node
		  end
	end
	print("RESPINNODE NOT END!!!")
	return nil
end

--获取所有固定信号
function GeminiJourneyRespinView:getFixSlotsNode()
	local fixSlotNode = {}
	local childs = self:getChildren()

	for i=1,#childs do
		  local node = childs[i]
		  if node:getTag() == self.REPIN_NODE_TAG  then
				fixSlotNode[#fixSlotNode + 1] =  node
		  end
	end
	return fixSlotNode
end

--获取所有固定信号
-- function GeminiJourneyRespinView:getFixSlotsNode()
-- 	local fixSlotNode = {}
-- 	local childs = self:getChildren()

-- 	for i=1,#childs do
-- 		local node = childs[i]
-- 		if node.getLastNode and node:getLastNode():getTag() == self.REPIN_NODE_TAG  then
-- 			fixSlotNode[#fixSlotNode + 1] =  node
-- 		end
-- 	end
-- 	return fixSlotNode
-- end

return GeminiJourneyRespinView