---
--island
--2018年4月12日
--MrCashFeatureNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local MrCashFeatureNode = class("MrCashFeatureNode",SpeicalReel)

--Reel中的层级
local ZORDER = {
	CLIP_ORDER = 1000,
	RUN_CLIP_ORDER = 2000,
	SHOW_ORDER = 2000,
	UI_ORDER = 3000,
  }

MrCashFeatureNode.m_runState = nil
MrCashFeatureNode.m_runSpeed = nil
MrCashFeatureNode.m_endRunData = nil

--状态
-- local BEGIN_RUN_SPEED = 10    --开始时匀速
-- local BEGIN_RUN_TIME = 0.8

-- local INCREMENT_SPEED = 10    --加速
-- local INCREMENT_TIME = 2

-- local MAX_SPEED = 300
-- local MAX_SPEED_TIME = 1

-- local SLOW_SPEED = 30
-- local SLOW_TIME = 1
MrCashFeatureNode.m_runActions = nil
MrCashFeatureNode.m_runNowAction = nil

local INCREMENT_SPEED = 30         --速度增量 (像素/帧)
local DECELER_SPEED = -60         --速度减量 (像素/帧)

local BEGIN_SPEED = 150             --初速度
local BEGIN_SPEED_TIME = 0     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 0.7        --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 0.7      --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 0          --匀速时间
local MAX_SPEED = 1000
local MIN_SPEED = 500

local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速

MrCashFeatureNode.m_endCallBackFun = nil
MrCashFeatureNode.m_endValue = nil
--状态切换
MrCashFeatureNode.m_timeCount = 0
MrCashFeatureNode.m_countDownTime = 0
-- 小块中奖音效
MrCashFeatureNode.m_littleBitSounds = {}

function MrCashFeatureNode:initUI(data)
	SpeicalReel.initUI(self, data)
	self.m_endValue = data

	self.m_runState = UNIFORM_STATE
	self.m_runSpeed = BEGIN_SPEED

	for i = 1, 3 do
		self.m_littleBitSounds[#self.m_littleBitSounds + 1] = "MrCashSounds/music_MrCash_Reword.mp3"
	end

	local resourceFilename = "Socre_MrCash_fs_Node.csb"
	self:createCsbNode(resourceFilename)
	self:setRunningParam(BEGIN_SPEED)

	self:runCsbAction("idle2")

	self:findChild("m_lb_Mini"):setVisible(false)
	self:findChild("m_lb_Mid"):setVisible(false)
	self:findChild("m_lb_Max"):setVisible(false)
	self:findChild("MrCash_fsdizi_5_Mini"):setVisible(false)
	self:findChild("MrCash_fsdizi_5_Mid"):setVisible(false)
	self:findChild("MrCash_fsdizi_5_Max"):setVisible(false)

	self.m_runActions = self:getMoveActions()
	self.m_runNowAction = self:getNextMoveActions()
end

function MrCashFeatureNode:dealWithCallFunc( func1,func2,func3 ,endValue )
	if endValue == 1 or endValue == 2 or endValue == 3 or endValue == 4 then
		if func1 then
			func1()
		end
	elseif  endValue == 5 or endValue == 6 or endValue == 7 or endValue == 8 or endValue == 9 then
		if func2 then
			func2()
		end
	elseif  endValue >= 10 then
		if func3 then
			func3()
		end
	end
end

--[[
    @desc: -初始化Reel结构
    author:{author}
    time:2018-11-28 12:03:55
    @return:
    @parma:wildth 宽 height 高 getSlotNodeFunc 内存池取  pushSlotNodeFunc 内存池删
]]
function MrCashFeatureNode:init(wildth ,height, getSlotNodeFunc, pushSlotNodeFunc)
	self.m_clipNode = cc.ClippingRectangleNode:create({x= - wildth / 2, y = 0, width = wildth, height = height})
	self.m_clipNode:setPositionY(-height / 2)
	self:addChild(self.m_clipNode,ZORDER.CLIP_ORDER)

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

function MrCashFeatureNode:getNextMoveActions()
	if self.m_runActions ~= nil and #self.m_runActions > 0 then
		local action = self.m_runActions[1]
		table.remove( self.m_runActions, 1)
		if #self.m_runActions == 0 then
			self.m_runDataList = self.m_endRunData
			self.m_dataListPoint = 1
		end
		return action
	end
	assert(false,"没有速度 序列了")
end

--设置滚动序列
function MrCashFeatureNode:getMoveActions()
	local runActions = {}
	local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE}
	local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED , status = ACC_STATE}
	local actionUniform2 = {time = HIGH_SPEED_TIME, status = UNIFORM_STATE}
	local actionDeceler = {time = DECELER_SPEED_TIMES, decelerSpeed = DECELER_SPEED, minSpeed = MIN_SPEED ,status = DECELER_STATE}
	local actionUniform3 = {status = UNIFORM_STATE}
	runActions[#runActions + 1] = actionUniform1
	runActions[#runActions + 1] = actionAcc
	runActions[#runActions + 1] = actionUniform2
	runActions[#runActions + 1] = actionDeceler
	runActions[#runActions + 1] = actionUniform3
	return runActions
end

--重写每帧走的距离
function MrCashFeatureNode:setDtMoveDis(dt)
	self:changeRunState(dt)
	self.m_dtMoveDis = -dt * self.m_runSpeed
end

function MrCashFeatureNode:getIsTimeDown(actionTime)
	if actionTime == nil then
		return false
	end

	if self.m_timeCount >= actionTime then
	     return true
	end
	return false
end

function MrCashFeatureNode:initRunDate(runData, getRunDatafunc)
	self.m_runDataList = getRunDatafunc
	self.m_endRunData = runData
	self.m_dataListPoint = 1
end

function MrCashFeatureNode:changeRunState(dt)
	self.m_timeCount = self.m_timeCount + dt

	local runState = self.m_runNowAction.status
	local actionTime = self.m_runNowAction.time
	if runState == UNIFORM_STATE or runState == HIGHT_STATE then
		if self:getIsTimeDown(actionTime) then
			self.m_runNowAction = self:getNextMoveActions()
			self.m_timeCount = 0
		end
	elseif runState == ACC_STATE then
		local addSpeed = self.m_runNowAction.addSpeed
		local maxSpeed = self.m_runNowAction.maxSpeed
		if self:getIsTimeDown(actionTime) then
			self.m_runNowAction = self:getNextMoveActions()
			self.m_timeCount = 0
		else
			if self.m_runSpeed < maxSpeed then
				self.m_runSpeed = self.m_runSpeed + addSpeed
			else
				self.m_runSpeed = maxSpeed
			end
		end
	elseif runState == DECELER_STATE then
		local decelerSpeed = self.m_runNowAction.decelerSpeed
		local minSpeed = self.m_runNowAction.minSpeed
		if self.m_runSpeed > minSpeed then
			self.m_runSpeed = self.m_runSpeed + decelerSpeed
		else
			self.m_runSpeed = minSpeed
			if self:getIsTimeDown(actionTime) then
				self.m_runNowAction = self:getNextMoveActions()
				self.m_runSpeed = self.m_runSpeed + decelerSpeed
				self.m_timeCount = 0
			end
		end
	end
end

function MrCashFeatureNode:getResultAnimaName()
	local animaName = nil

	self:dealWithCallFunc( function()

		self:findChild("m_lb_Mini"):setVisible(true)
		self:findChild("m_lb_Mini"):setString(self.m_endValue)
		self:findChild("MrCash_fsdizi_5_Mini"):setVisible(true)

		animaName = "actionframe1"
		gLobalSoundManager:playSound(self.m_littleBitSounds[1])
	end,function()

		self:findChild("m_lb_Mid"):setVisible(true)
		self:findChild("m_lb_Mid"):setString(self.m_endValue)
		self:findChild("MrCash_fsdizi_5_Mid"):setVisible(true)

		animaName = "actionframe1"
		gLobalSoundManager:playSound(self.m_littleBitSounds[2])
	end,function()

		animaName = "actionframe1"
		gLobalSoundManager:playSound(self.m_littleBitSounds[3])

		self:findChild("m_lb_Max"):setString(self.m_endValue)
		self:findChild("m_lb_Max"):setVisible(true)
		self:findChild("MrCash_fsdizi_5_Max"):setVisible(true)

	end , self.m_endValue)

	return animaName
end

function MrCashFeatureNode:runResAction()
	self:runReelDown()
	--播放动画
	self.m_clipNode:setVisible(false)
	self:setLocalZOrder(2)

	self.m_NodeBG:runCsbAction("actionframe",false,function()
		self.m_NodeBG:setVisible(false)
	end)

	self:runCsbAction(self:getResultAnimaName(),false, function ()
		self:setLocalZOrder(1)
	end)

	if self.m_endCallBackFun ~= nil then
		self.m_endCallBackFun()
	end


end


function MrCashFeatureNode:setEndCallBackFun(func)
	self.m_endCallBackFun = func
end



--[[
    @desc: --初始化时盘面信号
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function MrCashFeatureNode:initFirstSymbolBySymbols(initDataList)
	for i=1, #initDataList do
		local data = initDataList[i]

		local node = self.getSlotNodeBySymbolType(data.SymbolType)
		node.Height = data.Height

		self:dealRunNodeLabVisible( node,data.SymbolType )

		self.m_clipNode:addChild(node, data.Zorder)
		node:runCsbAction("idle1")
		self:setRunCreateNodePos(node)
		self:pushToSymbolList(node)
	end
end

--[[
    @desc:创建下个信号 并计算出停止距离
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function MrCashFeatureNode:createNextNode()

	if self:getLastSymbolTopY() >  self.m_reelHeight then
	    --最后一个Node > 上边界 创建新的node  反之创建
	    return
	end

	local nextNodeData = self:getNextRunData()
	if nextNodeData == nil then
	    --没有数据了
	    return
	end

	-- gLobalSoundManager:playSound("MrCashSounds/music_MrCash_FsSymbolRun.mp3")

	local node = self.getSlotNodeBySymbolType(nextNodeData.SymbolType)
	node.Height = nextNodeData.Height

	node.isEndNode = nextNodeData.Last
	self.m_clipNode:addChild(node, nextNodeData.Zorder)
	self:setRunCreateNodePos(node)
	self:pushToSymbolList(node)

	self:dealRunNodeLabVisible( node,nextNodeData.SymbolType )

	node:runCsbAction("idle1")

	if nextNodeData.Last and self.m_endDis == nil then
	    --创建出EndNode 计算出还需多长距离停止移动
	    self.m_endDis = self:getDisToReelLowBoundary(node)
	end

	--是否超过上边界 没有的话需要继续创建
	if self:getNodeTopY(node) <= self.m_reelHeight then
	    self:createNextNode()
	end
end

function MrCashFeatureNode:dealRunNodeLabVisible( node ,SymbolType )

	node:findChild("m_lb_Mini"):setVisible(false)
	node:findChild("m_lb_Mid"):setVisible(false)
	node:findChild("m_lb_Max"):setVisible(false)
	node:findChild("m_lb_Max_3"):setVisible(false)
	node:findChild("m_lb_Max_2"):setVisible(false)
	node:findChild("m_lb_Max_1"):setVisible(false)
	node:findChild("m_lb_MainNode_2"):setVisible(false)
	node:findChild("MrCash_fsdizi_5"):setVisible(false)

	self:dealWithCallFunc( function()
		node:findChild("m_lb_Mini"):setVisible(true)
		node:findChild("m_lb_Mini"):setString(SymbolType)

	end,function()
		node:findChild("m_lb_Mid"):setVisible(true)
		node:findChild("m_lb_Mid"):setString(SymbolType)
	end,function()
		node:findChild("m_lb_Max"):setVisible(true)
		node:findChild("m_lb_Max_3"):setString(SymbolType)
		node:findChild("m_lb_Max_2"):setString(SymbolType)
		node:findChild("m_lb_Max_1"):setString(SymbolType)
		node:findChild("m_lb_Max"):setString(SymbolType)

	end,SymbolType )
end

return MrCashFeatureNode