local MrCashFeatureView = class("MrCashFeatureView",  cc.Node)

MrCashFeatureView.slotMachine = nil
MrCashFeatureView.m_FeatureNode = nil
MrCashFeatureView.m_featureSpPool = nil
MrCashFeatureView.m_featureNodeEndNum = nil
MrCashFeatureView.m_featureOverCallBack = nil
MrCashFeatureView.m_signalTypeArray = {1,2,3,5,7,10} -- 配置小块type
MrCashFeatureView.m_musicRunAudioID = nil -- 存储的声音ID

MrCashFeatureView.m_endIndex = 0

local FeatureNode_Count = 0

local TIME_IMAGE_COUNT = 10
local TIME_IAMGE_SIZE = {width = 130, height = 110}
--配置滚动信息
local BASE_RNN_COUNT = 38
local OFF_RUN_COUNT = 3

function MrCashFeatureView:ctor()
	self:initMrCashFeatureView()
	self.m_FeatureNode = {}
	self.m_featureSpPool = {}
	self.m_featureNodeEndNum = 0
	self.m_endIndex = 0
end

function MrCashFeatureView:getFeatureNode(type)
	local spNode = util_createAnimation("Socre_MrCash_fs_NodeNum.csb")

	return spNode
end

function MrCashFeatureView:setSignalTypeArray(array)
	self.m_signalTypeArray = array
end

function MrCashFeatureView:setOverCallBackFun(callFunc)
	self.m_featureOverCallBack = callFunc
 end

function MrCashFeatureView:pushFeatureSp(spNode)

end

function MrCashFeatureView:initFeatureUI(datas,father)
	table.sort(datas,function( a,b )
		return a.EndValue < b.EndValue
	end)

	FeatureNode_Count = #datas
	for i=1,#datas do
		local data = datas[i]
		local pos = data.Pos
		local ArrayPos = data.ArrayPos
		local endValue = data.EndValue
		local runSequence = self:getRunSequence(endValue)
		local initReelData = self:getInitSequence()

		local MrCashFeatureNode = util_createView("CodeMrCashSrc.FreeSpinFeature.MrCashFeatureNode", endValue)
		self:addChild(MrCashFeatureNode)

		MrCashFeatureNode.m_NodeBG = util_createAnimation("Socre_MrCash_shanbai.csb")
		self:addChild(MrCashFeatureNode.m_NodeBG,10)
		MrCashFeatureNode.m_NodeBG:runCsbAction("actionframe",true)


		MrCashFeatureNode:init(TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, function(type)
			return self:getFeatureNode(type)
		end, function(spNode)
			return self:pushFeatureSp(spNode)
		end)
		pos = self:convertToNodeSpace(pos)
		MrCashFeatureNode:setPosition(pos)
		MrCashFeatureNode.m_NodeBG:setPosition(pos)

		MrCashFeatureNode:initFirstSymbolBySymbols(initReelData)
		MrCashFeatureNode:initRunDate(runSequence, function()
			return self:getRunReelData()
		end)
		MrCashFeatureNode:setEndCallBackFun(function()
			self:runEndCallBack()
		end)

		self.m_FeatureNode[#self.m_FeatureNode + 1] = MrCashFeatureNode

		if #MrCashFeatureNode.m_symbolNodeList > 0 then
			MrCashFeatureNode.m_symbolNodeList[#MrCashFeatureNode.m_symbolNodeList]:setVisible(false)
		end

		if #MrCashFeatureNode.m_symbolNodeList > 0 then
			MrCashFeatureNode.m_symbolNodeList[#MrCashFeatureNode.m_symbolNodeList]:setVisible(true)
		end
		performWithDelay(MrCashFeatureNode,function()
			MrCashFeatureNode:beginMove()
		end, i*0.05 + ArrayPos[2]*0.3)
	end

	self.m_musicRunAudioID = gLobalSoundManager:playSound("MrCashSounds/music_MrCash_FsReel_Run.mp3")
end

function MrCashFeatureView:runEndCallBack()
	self.m_featureNodeEndNum = self.m_featureNodeEndNum + 1

	if self.m_featureNodeEndNum == FeatureNode_Count then
		if self.m_musicRunAudioID then -- 停止滚动音效
			gLobalSoundManager:stopAudio(self.m_musicRunAudioID)
			self.m_musicRunAudioID = nil
		end

		performWithDelay(self, function()
			if self.m_featureOverCallBack ~= nil then
				self.m_featureOverCallBack()
			end
		end, 3)
	end
end

function MrCashFeatureView:getRunReelData()
	local index = math.random(1 ,#self.m_signalTypeArray )
	local type = self.m_signalTypeArray[index]
	local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, type, false )
	return  reelData
end

function MrCashFeatureView:getReelData( zorder, width, height, symbolType, bLast )
	local reelData = util_require("data.slotsdata.SpecialReelData"):create()
	reelData.Zorder = zorder
	reelData.Width = width
	reelData.Height = height
	reelData.SymbolType = symbolType
	reelData.Last = bLast
	return reelData
end

function MrCashFeatureView:getInitSequence()
	local reelDatas = {}
	local index = math.random(1 ,#self.m_signalTypeArray )
	local type = self.m_signalTypeArray[index]
	reelDatas[#reelDatas + 1]  = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, type, false )
	return reelDatas
end

function MrCashFeatureView:getRunSequence(endValue)
	local addNum = 6

	if endValue == 1 or endValue == 2 or endValue == 3 then
		self.m_endIndex = self.m_endIndex + math.random(0,1)
	elseif endValue == 4 or endValue == 5 or endValue== 6 then
		self.m_endIndex = self.m_endIndex + 6--math.random(2,2)
	elseif endValue == 7 or endValue == 8 or endValue == 9  then
		self.m_endIndex = self.m_endIndex + 6--math.random(2,2)
	elseif endValue== 10 then
		self.m_endIndex = self.m_endIndex + 8--math.random(3,4)
	end

	local reelDatas = {}
	local totleCount = addNum + self.m_endIndex --xcyy.SlotsUtil:getArc4Random() % OFF_RUN_COUNT + addNum
	local oldSymbolType = nil
	for i=1,totleCount do
		local symbolType = nil
		local bLast = nil
		if i == totleCount then
			symbolType = endValue
			bLast = true
		else
			local index = math.random(1 ,#self.m_signalTypeArray )
			symbolType  = self.m_signalTypeArray[index]
			bLast = false
		end

		local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, symbolType, bLast)

		reelDatas[#reelDatas + 1] = reelData
	end
	return reelDatas
end

function MrCashFeatureView:initMrCashFeatureView()
	local function onNodeEvent(eventName)
		if "enter" == eventName then
			self:onEnter()
		elseif "exit" == eventName then
			self:onExit()
		end
	end
	self:registerScriptHandler(onNodeEvent)
end

function MrCashFeatureView:onEnter()

end

function MrCashFeatureView:onExit()
	for i=1,#self.m_FeatureNode do
		local MrCashFeatureNode = self.m_FeatureNode[i]
		MrCashFeatureNode:stopAllActions()
		MrCashFeatureNode:removeFromParent()
	end

	self:unregisterScriptHandler()  -- 卸载掉注册事件
end

return MrCashFeatureView