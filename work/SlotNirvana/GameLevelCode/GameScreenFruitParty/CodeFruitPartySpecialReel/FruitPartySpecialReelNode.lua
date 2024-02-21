---
--island
--2018年4月12日
--FruitPartySpecialReelNode.lua
--
-- jackpot top bar
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SpeicalReel = require "Levels.SpeicalReel"
local FruitPartySpecialReelNode = class("FruitPartySpecialReelNode",SpeicalReel)

--Reel中的层级
local ZORDER = {
      CLIP_ORDER = 1000,
      RUN_CLIP_ORDER = 2000,
      SHOW_ORDER = 2000,
      UI_ORDER = 3000,
  }

FruitPartySpecialReelNode.m_runState = nil
FruitPartySpecialReelNode.m_runSpeed = nil
FruitPartySpecialReelNode.m_endRunData = nil
FruitPartySpecialReelNode.m_allRunSymbols = nil

local RUN_TAG = 
{
    SYMBOL_TAG = 1,               --滚动信号tag 
    SPEICAL_TAG = 10000,          --特殊元素如遮罩层等等 不参与滚动
}

--状态
FruitPartySpecialReelNode.m_runActions = nil
FruitPartySpecialReelNode.m_runNowAction = nil

local INCREMENT_SPEED = 20        --速度增量 (像素/帧)
local DECELER_SPEED = -7       --速度减量 (像素/帧)

local BEGIN_SPEED = 461             --初速度
local BEGIN_SPEED_TIME = 0     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 2         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 1      --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 5          --匀速时间
local MAX_SPEED = 3000
local MIN_SPEED = 558


local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速
local HIGH_STATE = 3    --高速

local REEL_SIZE = {width = 200, height = 390,decelerNum = 20}

FruitPartySpecialReelNode.DECELER_SYMBOL_NUM = 12

FruitPartySpecialReelNode.m_endCallBackFun = nil

FruitPartySpecialReelNode.m_reelHeight = nil

--状态切换
FruitPartySpecialReelNode.m_timeCount = 0

FruitPartySpecialReelNode.m_randomDataFunc = nil

FruitPartySpecialReelNode.distance = 0

function FruitPartySpecialReelNode:initUI()
      SpeicalReel.initUI(self)      
      self.m_runState = UNIFORM_STATE
      self.m_runSpeed = BEGIN_SPEED
      self:setRunningParam(BEGIN_SPEED)
      self:initAction()

      self.m_allRunSymbols = {}
      self.m_reelIndex = 1

      self.m_effect_node = cc.Node:create()
      self:addChild(self.m_effect_node,100000)
end

--[[
    @desc: -初始化Reel结构 
    author:{author}
    time:2018-11-28 12:03:55
    @return:
    @parma:wildth 宽 height 高 getSlotNodeFunc 内存池取  pushSlotNodeFunc 内存池删
]]
function FruitPartySpecialReelNode:init(getSlotNodeFunc, pushSlotNodeFunc,index,parent)
    local width = REEL_SIZE.width
    local height = REEL_SIZE.height

    self.m_parent = parent
    

    self.m_reelIndex = index

    self.DECELER_SYMBOL_NUM = REEL_SIZE.decelerNum
    local clicpNode = cc.ClippingRectangleNode:create({x= - width / 2, y = 0, width = width, height = height})
    clicpNode:setPositionY(-height / 2)
    self:addChild(clicpNode,ZORDER.CLIP_ORDER)
    self.m_clipNode = cc.Node:create()
    clicpNode:addChild(self.m_clipNode)
    --滚动中提升symbol层级遮罩
    local runclipNode = cc.ClippingRectangleNode:create({x= -width / 2, y = -height, width = width, height = height * 2})
    runclipNode:setAnchorPoint(cc.p(0.5, 0.5))
    self:addChild(runclipNode,ZORDER.RUN_CLIP_ORDER)
    self.m_runclipNode = cc.Node:create()
    runclipNode:addChild(self.m_runclipNode)

    self.m_reelWidth = width
    self.m_reelHeight = height
    -- body
    self.getSlotNodeBySymbolType = getSlotNodeFunc
    self.pushSlotNodeToPoolBySymobolType = pushSlotNodeFunc
end

function FruitPartySpecialReelNode:initAction()
        
      self.m_runActions = self:getMoveActions()
      self.m_runNowAction = self:getNextMoveActions()
      self.m_dataListPoint = 1
end

--[[
    @desc: --初始化时盘面信号  
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function FruitPartySpecialReelNode:initFirstSymbolBySymbols(initDataList)
    for i=1, #initDataList do
        local data = initDataList[i]

        local node = self.getSlotNodeBySymbolType(data)
        node.Height = data.Height
        node.userData = data
    
        self.m_clipNode:addChild(node,i) 
        self:setRunCreateNodePos(node)
        self:pushToSymbolList(node)
    end
end


function FruitPartySpecialReelNode:getDisToReelLowBoundary(node)
    local nodePosY = node:getPositionY()
    local nodeHeight = self.m_reelHeight / 3 
    local dis = nodePosY - (self.m_reelHeight -  nodeHeight / 2)
    return dis
end



function FruitPartySpecialReelNode:getNextRunData()
      local  nextData = self.m_randomDataFunc(self.m_reelIndex)
    
      return nextData
end
  
  
--[[
    @desc:创建下个信号 并计算出停止距离
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function FruitPartySpecialReelNode:createNextNode()
    if self:getLastSymbolTopY() >  self.m_reelHeight then
        --最后一个Node > 上边界 创建新的node  反之创建
        return 
    end

    local nextNodeData = self:getNextRunData()
    if nextNodeData == nil then
        --没有数据了
        return 
    end

    local node = self.getSlotNodeBySymbolType(nextNodeData)
    node.Height = nextNodeData.Height
    node.userData = nextNodeData

    node.isEndNode = nextNodeData.Last
    self.m_clipNode:addChild(node, nextNodeData.Zorder) 
    self:setRunCreateNodePos(node)
    self:pushToSymbolList(node)



    if nextNodeData.Last and self.m_endDis == nil then
        --创建出EndNode 计算出还需多长距离停止移动
        self.m_endDis = self:getDisToReelLowBoundary(node)
    end

    --是否超过上边界 没有的话需要继续创建
    if self:getNodeTopY(node) <= self.m_reelHeight then
        self:createNextNode()
    end
end 
  

function FruitPartySpecialReelNode:getNextMoveActions()
      if self.m_runActions ~= nil and #self.m_runActions > 0 then
            local action = self.m_runActions[1]
            table.remove( self.m_runActions, 1)
            return action
      end
      assert(false,"没有速度 序列了")
end

--设置滚动序列
function FruitPartySpecialReelNode:getMoveActions()
      local runActions = {}
      local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE}
      local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED , status = ACC_STATE}
      local actionUniform2 = {time = HIGH_SPEED_TIME, status = HIGH_STATE}
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
function FruitPartySpecialReelNode:setDtMoveDis(dt)
      self:changeRunState(dt)

      self.m_dtMoveDis = -dt * self.m_runSpeed

      self.distance = self.distance + self.m_dtMoveDis
end

function FruitPartySpecialReelNode:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function FruitPartySpecialReelNode:initRunDate(runData, getRunDatafunc)
      self.m_randomDataFunc = getRunDatafunc
      self.m_runDataList = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end

function FruitPartySpecialReelNode:setAllRunSymbols( allSymbols )
      self.m_allRunSymbols = allSymbols
end

function FruitPartySpecialReelNode:setEndDate(endData)
      self.m_endRunData = endData
end

function FruitPartySpecialReelNode:beginMove()

    if self:getReelStatus() ~= REEL_STATUS.IDLE then
        return 
    end
    self:changeReelStatus(REEL_STATUS.RUNNING)
    local bEndMove = false
    self.m_endNode = nil
    self.m_endDis = nil

    self:onUpdate(function(dt)
          if globalData.slotRunData.gameRunPause then
                return
          end
          if bEndMove then
                self:createNextNode()
                self:unscheduleUpdate()
                self:runResAction()
                self.m_effect_node:removeAllChildren(true)
                return
          end        
          self:createNextNode()
          self:setDtMoveDis(dt)
          if self.m_endDis ~= nil then
                --判断是否结束
                local endDis = self.m_endDis + self.m_dtMoveDis
                if endDis <= 0 then
                      self.m_dtMoveDis = -self.m_endDis
                      bEndMove = true
                else
                      self.m_endDis = endDis
                end
          end

        self:removeBelowReelSymbol()
        self:updateSymbolPosY()
    end)
end

--[[
    @desc:移除界面之下的symbol
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function SpeicalReel:removeBelowReelSymbol()
      local childs = self.m_clipNode:getChildren()
      for i=1,#childs do
            local node = childs[i]
            
            if node:getTag() < RUN_TAG.SPEICAL_TAG then

                  local nowPosY = node:getPositionY()
                  
                  --计算出移除的临界点
                  local removePosY = -node.Height 
                  if nowPosY <= removePosY then
                  node:removeFromParent(true)
                  self:popUpSymbolList()
                  end
            end

      end
end

function FruitPartySpecialReelNode:changeRunState(dt)
      self.m_timeCount = self.m_timeCount + dt

      local runState = self.m_runNowAction.status
      local actionTime = self.m_runNowAction.time
      if runState == UNIFORM_STATE  then
            if self:getIsTimeDown(actionTime) then
                  self.m_runNowAction = self:getNextMoveActions()
                  self.m_timeCount = 0
            end
      elseif runState == HIGH_STATE then
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

function FruitPartySpecialReelNode:getResAction()
    local timeDown = 0
    local speedActionTable = {}
    local dis = 20 
    local speedStart = self.m_runSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end

    local moveBy = cc.MoveBy:create(0.1,cc.p(0, -dis ))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    
    return speedActionTable, timeDown
end


function FruitPartySpecialReelNode:runResAction()
    local downDelayTime = 0
    for index = 1, #self.m_symbolNodeList do
        local node = self.m_symbolNodeList[index]
        local actionTable , downTime = self:getResAction()
        node:runAction(cc.Sequence:create(actionTable))
        if downDelayTime <  downTime then
            downDelayTime = downTime
        end
    end 

    performWithDelay(self,function()
      self.m_parent:playQuickRunSound()
       --滚动完毕
       self:runReelDown()
       if type(self.m_endCallBackFun) == "function" then
            self.m_endCallBackFun() 
       end
       
    end,downDelayTime)
end

function FruitPartySpecialReelNode:playRunEndAnima()
      for i=1,# self.m_symbolNodeList do
           local node =  self.m_symbolNodeList[i]
      --      node:setVisible(false)

           if node.isEndNode then

           else

           end
      end

end

function FruitPartySpecialReelNode:playRunEndAnimaIde()
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            node:runAnim("idleframe")
      end
end

--[[
      初始化小块状态
]]
function FruitPartySpecialReelNode:initSymbolStatus()
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            util_setCascadeOpacityEnabledRescursion(node, true)
            local posY = node:getPositionY()
            posY = posY + REEL_SIZE.height
            node:setPositionY(posY)
            node:setOpacity(0)
      end
end

--[[
      显示动作
]]
function FruitPartySpecialReelNode:showAni(func)
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            local spawn = cc.Spawn:create({
                  cc.MoveBy:create(1,cc.p(0,-REEL_SIZE.height)),
                  cc.FadeIn:create(1)
            })
            node:runAction(spawn)
      end
      performWithDelay(self.m_effect_node,function(  )
            if type(func) == "function" then
                  func()
            end
      end,1)
end

--[[
      显示连线
]]
function FruitPartySpecialReelNode:showLineFrame(iRow)
      local parentNode = self:getParent()
      local size = parentNode:getContentSize()


      local nodeHeight = size.height / 3

      local pos = cc.p(size.width / 2,nodeHeight * (iRow - 1) + nodeHeight / 2)
      --转化为节点坐标
      local worldPos = parentNode:convertToWorldSpace(pos)
      local nodePos = self.m_effect_node:convertToNodeSpace(worldPos)

      local node = util_createAnimation("WinFrameFruitParty.csb")
      node:runCsbAction("actionframe",true)
      node:setPosition(nodePos)

      -- self.m_effect_node:removeAllChildren(true)
      self.m_effect_node:addChild(node)
end

--[[
      显示预告中奖
]]
function FruitPartySpecialReelNode:showNoticeLine( )
      self.m_effect_node:removeAllChildren(true)
      for iRow = 1,3 do
            local parentNode = self:getParent()
            local size = parentNode:getContentSize()

            local nodeHeight = size.height / 3

            local pos = cc.p(size.width / 2,nodeHeight * (iRow - 1) + nodeHeight / 2)
            --转化为节点坐标
            local worldPos = parentNode:convertToWorldSpace(pos)
            local nodePos = self.m_effect_node:convertToNodeSpace(worldPos)

            local node = util_createAnimation("WinFrameFruitParty.csb")
            node:runCsbAction("actionframe",true)
            node:setPosition(nodePos)
            self.m_effect_node:addChild(node)
      end
end

--[[
      清理连线
]]
function FruitPartySpecialReelNode:clearLineAndFrame( )
      self.m_effect_node:removeAllChildren(true)
end

function FruitPartySpecialReelNode:setEndCallBackFun(func)
      self.m_endCallBackFun = func
end


--[[
    延迟回调
]]
function FruitPartySpecialReelNode:delayCallBack(time, func)
      local waitNode = cc.Node:create()
      self:addChild(waitNode)
      performWithDelay(
          waitNode,
          function()
              waitNode:removeFromParent(true)
              waitNode = nil
              if type(func) == "function" then
                  func()
              end
          end,
          time
      )
  
      return waitNode
  end

return FruitPartySpecialReelNode