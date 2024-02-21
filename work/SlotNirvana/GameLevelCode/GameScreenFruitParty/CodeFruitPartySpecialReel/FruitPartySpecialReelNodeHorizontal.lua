---
--island
--2018年4月12日
--FruitPartySpecialReelNodeHorizontal.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local FruitPartySpecialReelNodeHorizontal = class("FruitPartySpecialReelNodeHorizontal",SpeicalReel)

--m_clipNode特殊tag 
local RUN_TAG = 
{
    SYMBOL_TAG = 1,               --滚动信号tag 
    SPEICAL_TAG = 10000,          --特殊元素如遮罩层等等 不参与滚动
}
--Reel中的层级
local ZORDER = {
    CLIP_ORDER = 1000,
    RUN_CLIP_ORDER = 2000,
    SHOW_ORDER = 2000,
    UI_ORDER = 3000,
}



FruitPartySpecialReelNodeHorizontal.m_runState = nil
FruitPartySpecialReelNodeHorizontal.m_runSpeed = nil
FruitPartySpecialReelNodeHorizontal.m_endRunData = nil
FruitPartySpecialReelNodeHorizontal.m_allRunSymbols = nil

local ANCHOR_POINT_Y = 0.5

local SYMBOL_MULTIPLE_1             =           88
local SYMBOL_MULTIPLE_2             =           58
local SYMBOL_MULTIPLE_3             =           48
local SYMBOL_MULTIPLE_4             =           38
local SYMBOL_MULTIPLE_5             =           28
local SYMBOL_MULTIPLE_6             =           18

local REEL_DATA = {28,58,18,48,28,38,18,88,28,48,18,38}

--状态
FruitPartySpecialReelNodeHorizontal.m_runActions = nil
FruitPartySpecialReelNodeHorizontal.m_runNowAction = nil

local INCREMENT_SPEED = 13        --速度增量 (像素/帧)
local DECELER_SPEED = -10     --速度减量 (像素/帧)

local BEGIN_SPEED = 461             --初速度
local BEGIN_SPEED_TIME = 0     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 1         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 1      --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 3          --匀速时间
local MAX_SPEED = 1200
local MIN_SPEED = 100


local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速
local HIGH_STATE = 3    --高速

FruitPartySpecialReelNodeHorizontal.DECELER_SYMBOL_NUM = 12

FruitPartySpecialReelNodeHorizontal.m_endCallBackFun = nil

FruitPartySpecialReelNodeHorizontal.m_reelHeight = nil

--状态切换
FruitPartySpecialReelNodeHorizontal.m_timeCount = 0

FruitPartySpecialReelNodeHorizontal.m_randomDataFunc = nil

FruitPartySpecialReelNodeHorizontal.distance = 0

local REEL_SIZE = {width = 970, height = 400,decelerNum = 50}

function FruitPartySpecialReelNodeHorizontal:initUI()
      SpeicalReel.initUI(self)      
      self.m_runState = UNIFORM_STATE
      self.m_runSpeed = BEGIN_SPEED
      self:setRunningParam(BEGIN_SPEED)
      self:initAction()

      self.m_allRunSymbols = {}

      
end

function FruitPartySpecialReelNodeHorizontal:setCsbNode(csbNode)
      self.m_csbNode = csbNode

      self.m_effect_node = cc.Node:create()
      self.m_csbNode:addChild(self.m_effect_node,100000)
end

function FruitPartySpecialReelNodeHorizontal:setCollects(collects)
      self.m_collects = collects
end

--[[
    @desc: -初始化Reel结构 
    author:{author}
    time:2018-11-28 12:03:55
    @return:
    @parma:wildth 宽 height 高 getSlotNodeFunc 内存池取  pushSlotNodeFunc 内存池删
]]
function FruitPartySpecialReelNodeHorizontal:init(data)
      self.m_parent = data.parent
      self.m_stopUpdateCoinsSoundIndex = self.m_parent.m_parent.m_stopUpdateCoinsSoundIndex

      local width = REEL_SIZE.width
      local height = REEL_SIZE.height
  
      self.DECELER_SYMBOL_NUM = REEL_SIZE.decelerNum
      local clicpNode = cc.ClippingRectangleNode:create({x= 0, y = 0, width = width, height = height})
      clicpNode:setPositionY(-height / 2)
      self:addChild(clicpNode,ZORDER.CLIP_ORDER)
      self.m_clipNode = cc.Node:create()
      clicpNode:addChild(self.m_clipNode)

      --滚动中提升symbol层级遮罩
      local runclipNode = cc.ClippingRectangleNode:create({x= 0, y = 0, width = width, height = height})
      runclipNode:setAnchorPoint(cc.p(0.5, 0.5))
      self:addChild(runclipNode,ZORDER.RUN_CLIP_ORDER)
      self.m_runclipNode = cc.Node:create()
      runclipNode:addChild(self.m_runclipNode)
  
      self.m_reelWidth = width
      self.m_reelHeight = height

end

--[[
      获取小块
]]
function FruitPartySpecialReelNodeHorizontal:getSlotNodeBySymbolType(symbolType)
      local ccbName = ""
      if symbolType == SYMBOL_MULTIPLE_1 then
            ccbName = "Socre_FruitParty_wheel_0"
      elseif symbolType == SYMBOL_MULTIPLE_2 then
            ccbName = "Socre_FruitParty_wheel_1"
      elseif symbolType == SYMBOL_MULTIPLE_3 then
            ccbName = "Socre_FruitParty_wheel_2"
      elseif symbolType == SYMBOL_MULTIPLE_4 then
            ccbName = "Socre_FruitParty_wheel_3"
      elseif symbolType == SYMBOL_MULTIPLE_5 then
            ccbName = "Socre_FruitParty_wheel_4"
      else
            ccbName = "Socre_FruitParty_wheel_5"
      end

      local slotNode = util_createAnimation(ccbName..".csb")
      
      return slotNode
end

function FruitPartySpecialReelNodeHorizontal:initAction()
        
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
function FruitPartySpecialReelNodeHorizontal:initFirstSymbolBySymbols()
      local initDataList = {}
      local startIndex = math.random(1,#REEL_DATA)
      local count = #REEL_DATA
      --随机小块
      for index = 1,count do
            local reelData = util_require("data.slotsdata.SpecialReelData"):create()
            reelData.Zorder = 1
            reelData.Width = REEL_SIZE.width / count
            reelData.Height = REEL_SIZE.height 
            reelData.Last = false
            reelData.SymbolType = REEL_DATA[startIndex]
            
            startIndex = (startIndex + 1) % (count + 1)
            if startIndex == 0  then
                  startIndex = 1 
            end
            table.insert(initDataList,1,reelData)
      end

      for i=1, #initDataList do
            local data = initDataList[i]

            local node = self:getSlotNodeBySymbolType(data.SymbolType)
            node.Height = data.Height
            node.Width = data.Width

            self.m_clipNode:addChild(node, data.Zorder) 
            self:setRunCreateNodePos(node)
            self:pushToSymbolList(node)
      end
end


function FruitPartySpecialReelNodeHorizontal:getDisToReelLowBoundary(node)
    local nodePosX = node:getPositionX()
    local dis = math.abs(nodePosX - node.Width / 2) 
    return dis
end


function FruitPartySpecialReelNodeHorizontal:getNextRunData()
   local  nextData = nil
   if self.m_allRunSymbols and #self.m_allRunSymbols > 0 then
          nextData = self.m_allRunSymbols[1]
          table.remove(self.m_allRunSymbols, 1)
   end
    
    return nextData
end
  
  
--[[
    @desc:创建下个信号 并计算出停止距离
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function FruitPartySpecialReelNodeHorizontal:createNextNode()
    if self:getLastSymbolTopX() >  self.m_reelWidth then
        --最后一个Node > 上边界 创建新的node  反之创建
        return 
    end

    local nextNodeData = self:getNextRunData()
    if nextNodeData == nil then
        --没有数据了
        return 
    end

    local node = self:getSlotNodeBySymbolType(nextNodeData.SymbolType)
    node.Height = nextNodeData.Height
    node.Width = nextNodeData.Width
    node.isEndNode = nextNodeData.Last
    node.data = nextNodeData
    node:runCsbAction("idle")
    self.m_clipNode:addChild(node, nextNodeData.Zorder) 
    self:setRunCreateNodePos(node)
    self:pushToSymbolList(node)

    if nextNodeData.Last and self.m_endDis == nil then
        --创建出EndNode 计算出还需多长距离停止移动
        self.m_endDis = self:getDisToReelLowBoundary(node)
    end

    --是否超过上边界 没有的话需要继续创建
    if self:getNodeTopX(node) <= self.m_reelWidth then
        self:createNextNode()
    end
end 

function FruitPartySpecialReelNodeHorizontal:setRunCreateNodePos(newNode)
    local topX = self:getLastSymbolTopX()
    local newPosX = topX  - newNode.Width * ANCHOR_POINT_Y
    newNode:setPosition(cc.p(newPosX, newNode.Height / 2))
end

function FruitPartySpecialReelNodeHorizontal:getLastSymbolTopX( )
    local lastNode = self:getLastSymbolNode()
    local topX = self.m_reelWidth
    
    if lastNode == nil then
        return topX, lastNode
    end

    local lastNodePosX = lastNode:getPositionX()
    local topX = lastNodePosX - lastNode.Width * ANCHOR_POINT_Y
    return topX, lastNode
end

function FruitPartySpecialReelNodeHorizontal:getNodeTopX(node)
    local nodePosX = node:getPositionX()
    local topX = nodePosX - node.Width * ANCHOR_POINT_Y
    return topX
end
  

function FruitPartySpecialReelNodeHorizontal:getNextMoveActions()
      if self.m_runActions ~= nil and #self.m_runActions > 0 then
            local action = self.m_runActions[1]
            table.remove( self.m_runActions, 1)
            return action
      end
      assert(false,"没有速度 序列了")
end

--设置滚动序列
function FruitPartySpecialReelNodeHorizontal:getMoveActions()
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
function FruitPartySpecialReelNodeHorizontal:setDtMoveDis(dt)
      self:changeRunState(dt)

      self.m_dtMoveDis = dt * self.m_runSpeed

      self.distance = self.distance + self.m_dtMoveDis
end

function FruitPartySpecialReelNodeHorizontal:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function FruitPartySpecialReelNodeHorizontal:initRunDate(runData, getRunDatafunc)
      self.m_randomDataFunc = getRunDatafunc
      self.m_runDataList = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end

function FruitPartySpecialReelNodeHorizontal:setAllRunSymbols(realSymbolTypes)
      self.m_allRunSymbols = {}

      local endIndex = table.indexof(realSymbolTypes,0) or 1
      --计算需转动的小块数量
      local count = #REEL_DATA 
      local startIndex = math.random(1,count)

      local maxCount = count * 6 --count * 5 + (count - startIndex + 1 + endIndex)

      --假滚小块
      for index = 1,maxCount - #realSymbolTypes do
            local reelData = util_require("data.slotsdata.SpecialReelData"):create()
            reelData.Zorder = 1
            reelData.Width = REEL_SIZE.width / count
            reelData.Height = REEL_SIZE.height 
            reelData.Last = false
            reelData.SymbolType = REEL_DATA[startIndex]
            reelData.index = #self.m_allRunSymbols + 1
            
            startIndex = (startIndex + 1) % (count + 1)
            if startIndex == 0  then
                  startIndex = 1 
            end
            table.insert(self.m_allRunSymbols,1,reelData)
      end

      
      --真实小块
      for index = #realSymbolTypes,1,-1 do
            local reelData = util_require("data.slotsdata.SpecialReelData"):create()
            reelData.Zorder = 1
            reelData.Width = REEL_SIZE.width / count
            reelData.Height = REEL_SIZE.height 
            reelData.Last = false
            reelData.index = #self.m_allRunSymbols + 1

            local realIndex = realSymbolTypes[index] + 1
            reelData.SymbolType = REEL_DATA[realIndex]
            table.insert(self.m_allRunSymbols,#self.m_allRunSymbols + 1,reelData)
      end
      self.m_allRunSymbols[#self.m_allRunSymbols].Last = true
end

function FruitPartySpecialReelNodeHorizontal:setEndDate(endData)
      self.m_endRunData = endData
end

function FruitPartySpecialReelNodeHorizontal:startMove(func)
      self:initFirstSymbolBySymbols()
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            node:setVisible(false)
      end
      --进场动画
      local params = {}
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "actionframe1", --动作名称  动画必传参数,单延时动作可不传
            soundFile = "FruitPartySounds/sound_FruitParty_wheel_start.mp3",
            fps = 60,    --帧率  可选参数
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "idle1", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "over1", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            callBack = function(  )
                  --显示轮盘
                  for i=1,# self.m_symbolNodeList do
                        local node =  self.m_symbolNodeList[i]
                        node:setVisible(true)
                        node:runCsbAction("show",false,function(  )
                              node:runCsbAction("idle")
                        end)
                  end
            end
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            soundFile = "FruitPartySounds/sound_FruitParty_wheel_show.mp3",
            actionName = "show", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            callBack = function(  )
                  if type(func) == "function" then
                        func()
                  end
            end
      }

      util_runAnimations(params)

      
end

function FruitPartySpecialReelNodeHorizontal:beginMove(func)

    if self:getReelStatus() ~= REEL_STATUS.IDLE then
        return 
    end
    self:changeReelStatus(REEL_STATUS.RUNNING)
    local bEndMove = false
    self.m_endNode = nil
    self.m_endDis = nil

    local move_dis = 0

    local countDownNode = cc.Node:create()
    self:addChild(countDownNode)

    countDownNode:onUpdate(function(dt)
          if globalData.slotRunData.gameRunPause then
                return
          end
          if bEndMove then
                self:createNextNode()
                self:runResAction()
                countDownNode:unscheduleUpdate()
                countDownNode:removeFromParent(true)
                return
          end        
          self:createNextNode()
          self:setDtMoveDis(dt)
          if self.m_endDis ~= nil then
                --判断是否结束
                local endDis = self.m_endDis - self.m_dtMoveDis
                if endDis <= 0 then
                      self.m_dtMoveDis = self.m_endDis
                      bEndMove = true
                else
                      self.m_endDis = endDis
                end
          end

          move_dis = move_dis + self.m_dtMoveDis
          if move_dis >= REEL_SIZE.width / 12 then
              move_dis = 0
              gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_wheel_spot_move.mp3")
          end

        self:removeBelowReelSymbol()
        self:updateSymbolPosX()
    end)
end

--[[
    @desc:移除界面之下的symbol
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function FruitPartySpecialReelNodeHorizontal:removeBelowReelSymbol()
    local childs = self.m_clipNode:getChildren()
    for i=1,#childs do
        local node = childs[i]
        
        if node:getTag() < RUN_TAG.SPEICAL_TAG then

            local nowPosX = node:getPositionX()
            
            --计算出移除的临界点
            local removePosX = self.m_reelWidth + node.Width
            if nowPosX >= removePosX then
                node:removeFromParent(true)
                self:popUpSymbolList()
            end
        end

    end
end
--[[
    @desc:更新所有Symbol坐标
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function FruitPartySpecialReelNodeHorizontal:updateSymbolPosX()
    local childs = self.m_clipNode:getChildren()
    for i=1,#childs do
  
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosX = node:getPositionX()
            node:setPositionX(nowPosX + self.m_dtMoveDis)
        end
    end
end

function FruitPartySpecialReelNodeHorizontal:changeRunState(dt)
      self.m_timeCount = self.m_timeCount + dt

      local runState = self.m_runNowAction.status
      local actionTime = self.m_runNowAction.time
      if runState == UNIFORM_STATE  then
            if self:getIsTimeDown(actionTime) then
                  self.m_runNowAction = self:getNextMoveActions()
                  self.m_timeCount = 0
            end
      elseif runState == HIGH_STATE then
            if self:getLastSymbolTopX() >=  -self.m_reelWidth * 1.3 * self.m_parent.m_machineRootScale then
                  self.m_runNowAction = self:getNextMoveActions()
                  self.m_timeCount = 0
            end
      elseif runState == ACC_STATE then
            local addSpeed = self.m_runNowAction.addSpeed
            local maxSpeed = self.m_runNowAction.maxSpeed
            if self.m_runSpeed < maxSpeed then
                  self.m_runSpeed = self.m_runSpeed + addSpeed
            else
                  self.m_runSpeed = maxSpeed
                  self.m_runNowAction = self:getNextMoveActions()
                  self.m_timeCount = 0
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

function FruitPartySpecialReelNodeHorizontal:getResAction()
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
        local moveBy = cc.MoveBy:create(time,cc.p(moveDis, 0))
        speedActionTable[#speedActionTable + 1] = moveBy
    end

    local moveBy = cc.MoveBy:create(0.1,cc.p(dis, 0))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    
    return speedActionTable, timeDown
end


function FruitPartySpecialReelNodeHorizontal:runResAction()
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
      gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_wheel_spot_move.mp3")
      --滚动完毕
      self:runReelDown(function(  )
            for index,node in pairs(self.m_symbolNodeList) do
                  
                  node:removeFromParent(true)
            end
            self.m_symbolNodeList = {}
            if type(self.m_endCallBackFun) == "function" then
                  self.m_endCallBackFun()
            end
      end)
       
    end,downDelayTime)
end

function FruitPartySpecialReelNodeHorizontal:runReelDown(func)
      self:changeReelStatus(REEL_STATUS.IDLE)
      self.m_dataListPoint = 1
      gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_wheel_buling.mp3")
      for index,node in pairs(self.m_symbolNodeList) do
            node:runCsbAction("actionframe1",false,function(  )
                  node:runCsbAction("actionframe2")
            end)
      end

      self.m_parent:delayCallBack(85 / 60,function(  )
            --扫光音效
            gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_wheel_refresh_score.mp3")
            --结算动画
            self:doNextNodeAni(1,function(  )
                  self:overAni(func)
            end)
      end)

      
end

function FruitPartySpecialReelNodeHorizontal:doNextNodeAni(index,func)
      if index > 12 then
            if type(func) == "function" then
                  func()
            end
            return
      end

      local count = #self.m_symbolNodeList
      local node = self.m_symbolNodeList[count - index + 1]

      --计算赢钱
      local winCoins = 0
      for collectIndex = 1,2 do
            local spotData = self.m_collects[index + 12 * (collectIndex - 1)]
            if spotData.udid == globalData.userRunData.userUdid then
                  winCoins = winCoins + spotData.coins * node.data.SymbolType
            end
            
      end
      if winCoins > 0 then
            self.m_parent.m_winCoins = winCoins + self.m_parent.m_winCoins
            globalData.slotRunData.lastWinCoin = 0

            local params = {
                  self.m_parent.m_winCoins, 
                  false, 
                  false,
                  self.m_parent.m_winCoins - winCoins
            }
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
      end

      local temp = self:getSlotNodeBySymbolType(node.data.SymbolType)
      self.m_effect_node:addChild(temp)
      temp:setPosition(util_convertToNodeSpace(node,self.m_effect_node))
      node:setVisible(false)

      temp:runCsbAction("actionframe",false,function()
            
            temp:removeFromParent(true)
      end)

      self.m_parent:delayCallBack(0.1,function(  )
            self:doNextNodeAni(index + 1,func)
      end)
end

function FruitPartySpecialReelNodeHorizontal:overAni(func)
      local params = {}
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "over", --动作名称  动画必传参数,单延时动作可不传
            delayTime = 1,
            fps = 60,    --帧率  可选参数
            
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "actiopnframe2", --动作名称  动画必传参数,单延时动作可不传
            soundFile = "FruitPartySounds/sound_FruitParty_wheel_over.mp3",
            fps = 60,    --帧率  可选参数
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "idle2", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
      }
      params[#params + 1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_csbNode,   --执行动画节点  必传参数
            actionName = "over2", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            callBack = function(  )
                  if type(func) == "function" then
                        func()
                  end
            end
      }
      
      util_runAnimations(params)
end

function FruitPartySpecialReelNodeHorizontal:playRunEndAnima()
      for i=1,# self.m_symbolNodeList do
           local node =  self.m_symbolNodeList[i]
      --      node:setVisible(false)

           if node.isEndNode then

           else

           end
      end

end

function FruitPartySpecialReelNodeHorizontal:playRunEndAnimaIde()
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            node:runAnim("idleframe")
      end
end

function FruitPartySpecialReelNodeHorizontal:setEndCallBackFun(func)
      self.m_endCallBackFun = func
end



return FruitPartySpecialReelNodeHorizontal