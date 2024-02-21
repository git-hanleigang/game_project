local ApolloMidRunView = class("ApolloMidRunView", util_require("base.BaseView"))

ApolloMidRunView.m_FeatureNode = nil
ApolloMidRunView.m_featureOverCallBack = nil
ApolloMidRunView.m_getNodeByTypeFromPool= nil
ApolloMidRunView.m_pushNodeToPool = nil
ApolloMidRunView.m_bigPoseidon = nil
ApolloMidRunView.m_endValueIndex = nil
ApolloMidRunView.m_endValue = nil
ApolloMidRunView.m_winSound = nil
ApolloMidRunView.m_sendDataFunc = nil
ApolloMidRunView.m_wheelsData = nil

ApolloMidRunView.m_bRunEnd = nil

local FeatureNode_Count = 0

local SYMBOL_HEIGHT = 115.2--76.8 + 38.4
local REEL_SYMBOL_COUNT = 3
--配置滚动信息

local ALL_RUN_SYMBOL_NUM = 37


ApolloMidRunView.m_runDataPoint  = nil
ApolloMidRunView.m_allSymbols = nil


function ApolloMidRunView:initUI(machine)
	self.m_machine = machine

	self.m_bRunEnd = false

	self.m_radius = 76.8--裁切区域半径
	--裁切区域
	self.m_clipView = util_createView("CodeApolloSrc.ClipView.StencilClipView")
	self:addChild(self.m_clipView)
	self.m_clipView:stencilDrawSolidCircle(cc.p(0,0),self.m_radius,30)

	self:initWheelsData()

	self:initRuningPoint()

	self:setNodePoolFunc()

	self:initFeatureUI()
end

function ApolloMidRunView:initWheelsData()
	local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
	local spWheels = selfdata.spWheels

	self.m_wheelsData = spWheels or {2,3,4,5}

	ALL_RUN_SYMBOL_NUM = 3 * #self.m_wheelsData

	self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1

	self.m_runDataRealPoint = 1
end

function ApolloMidRunView:getRealWheelData()

	local jpType = nil
	if self.m_runDataRealPoint > #self.m_wheelsData then
	    self.m_runDataRealPoint = 1
	end

	local score = self.m_wheelsData[self.m_runDataRealPoint]

	jpType = self.m_machine.SYMBOL_MIDRUN_SYMBOL_REELMULTIPLE

	self.m_runDataRealPoint = self.m_runDataRealPoint + 1

	return jpType, score
end

function ApolloMidRunView:initAllSymbol(endValue)
	self.m_allSymbols = {}
	self.m_endValue = endValue
	self.m_runDataRealPoint = self.m_runDataPoint
	local iSymbolsNum = ALL_RUN_SYMBOL_NUM
	for i = 1, iSymbolsNum, 1 do
		local type, score = self:getRealWheelData()
		local data = self:getReelData(1,self.m_radius * 2, SYMBOL_HEIGHT, type, false )
		data.jpScore = score
		self.m_allSymbols[#self.m_allSymbols + 1] = data
		if i > (#self.m_wheelsData * 2) and endValue.type == data.SymbolType and endValue.score == data.jpScore then
			data.Last = true
			data.jpScore = endValue.score
			break
		end
	end
	local more = math.floor(REEL_SYMBOL_COUNT * 0.5)
	for i = 1, more, 1 do
		local type, score = self:getRealWheelData()
		local data = self:getReelData(1,self.m_radius * 2, SYMBOL_HEIGHT, type, false )
		data.jpScore = score
		self.m_allSymbols[#self.m_allSymbols + 1] = data
	end
end

function ApolloMidRunView:initRuningPoint()
   self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function ApolloMidRunView:getNextType()
	local jpType = nil
	if self.m_runDataPoint > #self.m_wheelsData then
	    self.m_runDataPoint = 1
	end

	local score = self.m_wheelsData[self.m_runDataPoint]

	jpType = self.m_machine.SYMBOL_MIDRUN_SYMBOL_REELMULTIPLE

	self.m_runDataPoint = self.m_runDataPoint + 1

	return jpType, score
end


function ApolloMidRunView:setNodePoolFunc()

	self.m_getNodeByTypeFromPool = function(symbolType)

		local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
		local actNode = util_createAnimation(ccbName..".csb")

		return actNode
	end


	self.m_pushNodeToPool = function(targSp)
		-- self.m_machine:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
	end

end

function ApolloMidRunView:setOverCallBackFun(callFunc)
	self.m_featureOverCallBack = callFunc
end

function ApolloMidRunView:initFeatureUI()
	local initReelData = self:getInitSequence()

	local featureNode = util_createView("CodeApolloSrc.MidRun.ApolloMidRunNode")
	self.m_clipView:addContentToClip(featureNode)

	featureNode:init(self.m_radius * 2, self.m_radius * 2,
	self.m_getNodeByTypeFromPool,
	self.m_pushNodeToPool)

	featureNode:initFirstSymbolBySymbols(initReelData)

	featureNode:initRunDate(nil, function()
		return self:getRunReelData()
	end)
	featureNode:setEndCallBackFun(function()
		self:runEndCallBack()
	end)

	self.m_FeatureNode = featureNode

	-- self.m_FeatureNode:beginMove()
end

function ApolloMidRunView:setEndValue(endValue)
	self:initAllSymbol(endValue)
	self.m_FeatureNode.m_runSpeed = 800
	self.m_FeatureNode:setresDis(15)
	self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
	self.m_FeatureNode:initEndAction()
end

function ApolloMidRunView:runEndCallBack()
	if self.m_featureOverCallBack then
		self.m_featureOverCallBack()
	end
end

function ApolloMidRunView:getRunReelData()
	local type, score = self:getNextType()
	local reelData = self:getReelData(1,self.m_radius * 2, SYMBOL_HEIGHT, type, false )
	reelData.jpScore = score
	return  reelData
end

function ApolloMidRunView:getReelData( zorder, width, height, symbolType, bLast )
	local reelData = util_require("data.slotsdata.SpecialReelData"):create()
	reelData.Zorder = zorder
	reelData.Width = width
	reelData.Height = height
	reelData.SymbolType = symbolType
	reelData.Last = bLast
	return reelData
end

function ApolloMidRunView:getInitSequence()
	local reelDatas = {}

	for i = 1, REEL_SYMBOL_COUNT, 1 do
	   local type, score = self:getNextType()
	   local data = self:getReelData(1,self.m_radius * 2, SYMBOL_HEIGHT, type, false )
	   data.jpScore = score
	   reelDatas[#reelDatas + 1]  = data
	end

	return reelDatas
end

function ApolloMidRunView:transSymbolData(endValue)
	local jpType = nil
	if self.m_runDataPoint > #self.m_wheelsData then
	    self.m_runDataPoint = 1
	end

	local type = endValue.type

	jpType = self.m_machine.SYMBOL_MIDRUN_SYMBOL_REELMULTIPLE

	return jpType
end

function ApolloMidRunView:getRunSequence(endValue)
	if self.m_bRunEnd == true then
		return nil
	end
	self.m_bRunEnd = true
	local reelDatas = {}
	local totleCount = 1
	local tempIndex = nil
	if self.m_runDataPoint > #self.m_wheelsData then
		tempIndex = 1
	else
		tempIndex = self.m_runDataPoint
	end
	if self.m_endValueIndex > tempIndex then
		totleCount = totleCount + self.m_endValueIndex - tempIndex
	elseif self.m_endValueIndex < tempIndex then
		totleCount = totleCount + #self.m_wheelsData + self.m_endValueIndex - tempIndex
	end

	local type = self:transSymbolData(endValue)
	for i=1, totleCount do

		local symbolType = nil

		local jpScore =  0
		local bLast = nil

		if i == totleCount then
			symbolType = type
			jpScore = endValue.score
			bLast = true
			if self.m_runDataPoint > #self.m_wheelsData then
				self.m_runDataPoint = 1
			end
			self.m_runDataPoint = self.m_runDataPoint + 1
		else
			symbolType, jpScore = self:getNextType()
			bLast = false
		end

		local reelData = self:getReelData(1,self.m_radius * 2, SYMBOL_HEIGHT, symbolType, bLast)
		reelData.jpScore = jpScore

		reelDatas[#reelDatas + 1] = reelData
	end
	return reelDatas

end

function ApolloMidRunView:removeFeatureNode()
	local featureNode = self.m_FeatureNode
	featureNode:stopAllActions()
	featureNode:removeFromParent()
end

function ApolloMidRunView:beginMove()
	self.m_FeatureNode:beginMove()
end
function ApolloMidRunView:restartMove()
	self.m_FeatureNode:restartMove()
end
function ApolloMidRunView:onEnter()

end

function ApolloMidRunView:onExit()

end

return ApolloMidRunView