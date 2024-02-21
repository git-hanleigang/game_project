local BlazingMotorsWheelView = class("BlazingMotorsWheelView", util_require("base.BaseView"))

BlazingMotorsWheelView.m_FeatureNode = nil
BlazingMotorsWheelView.m_featureOverCallBack = nil
BlazingMotorsWheelView.m_getNodeByTypeFromPool= nil
BlazingMotorsWheelView.m_pushNodeToPool = nil
BlazingMotorsWheelView.m_bigPoseidon = nil
BlazingMotorsWheelView.m_endValueIndex = nil
BlazingMotorsWheelView.m_endValue = nil
BlazingMotorsWheelView.m_winSound = nil
BlazingMotorsWheelView.m_sendDataFunc = nil
BlazingMotorsWheelView.m_wheelsData = nil
BlazingMotorsWheelView.m_bTouchEnable = nil
BlazingMotorsWheelView.m_bRunEnd = nil

BlazingMotorsWheelView.SYMBOL_WHEEL_NODE_Lock = 97 
BlazingMotorsWheelView.SYMBOL_WHEEL_NODE_Sweep = 98
BlazingMotorsWheelView.SYMBOL_WHEEL_NODE_WildReels = 99
BlazingMotorsWheelView.SYMBOL_WHEEL_NODE_Rising = 100

local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 364, height = 480}
local SYMBOL_HEIGHT = 150
local REEL_SYMBOL_COUNT = math.ceil( TIME_IAMGE_SIZE.height / 200 )
--配置滚动信息

local ALL_RUN_SYMBOL_NUM = 90

BlazingMotorsWheelView.JackPotSoundBGId = nil -- jackPot背景音乐

BlazingMotorsWheelView.m_runDataPoint  = nil
BlazingMotorsWheelView.m_allSymbols = nil
-- 5000,500,100,30,10



function BlazingMotorsWheelView:initUI(datas)
      if REEL_SYMBOL_COUNT %2 == 0 then
            REEL_SYMBOL_COUNT = REEL_SYMBOL_COUNT + 1
      end
      self.m_bTouchEnable = false
      self.m_bRunEnd = false
      local resourceFilename="BlazingMotors_Wheel.csb"
      self:createCsbNode(resourceFilename)

      self:runCsbAction("start")
      self:initWheelsData(datas)

      self:initRuningPoint()
      


end  

function BlazingMotorsWheelView:initWheelsData( datas )
      for i = 1, #datas, 1 do
          local data = datas[i]
      --     local vecStrs = util_string_split(data,",")
          local wheel = {}
          wheel.type = data[1]  -- vecStrs[1]
          wheel.score = data[2] -- tonumber(vecStrs[2])
          if self.m_wheelsData == nil then
            self.m_wheelsData = {}
          end
          self.m_wheelsData[#self.m_wheelsData + 1] = wheel
      end
      self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function BlazingMotorsWheelView:initAllSymbol(endValue)
      self.m_allSymbols = {}
      self.m_endValue = endValue
      local endType = self:getSymbolType(endValue)
      local iSymbolsNum = ALL_RUN_SYMBOL_NUM
      for i = 1, iSymbolsNum, 1 do
            local type, score = self:getNextType() 
            local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            self.m_allSymbols[#self.m_allSymbols + 1] = data
            if i >= 70 and endType == data.SymbolType then
                  data.Last = true
                  data.jpScore = endValue.score
                  break
            end
      end
      local more = math.floor(REEL_SYMBOL_COUNT * 0.5)
      for i = 1, more, 1 do
            local type, score = self:getNextType() 
            local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            self.m_allSymbols[#self.m_allSymbols + 1] = data
      end
end

function BlazingMotorsWheelView:getSymbolType(endValue)
      local type = endValue.type
      local jpType = nil


      if type == 0 then
            jpType =  self.SYMBOL_WHEEL_NODE_Lock
      elseif type == 1 then
            jpType =  self.SYMBOL_WHEEL_NODE_WildReels
      elseif type == 2 then
            jpType =  self.SYMBOL_WHEEL_NODE_Rising
      elseif type == 3 then
            jpType =  self.SYMBOL_WHEEL_NODE_Sweep
      end

      return jpType
end

function BlazingMotorsWheelView:initRuningPoint()
   self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function BlazingMotorsWheelView:getNextType()
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end
      self.test = self.test + 1
      local type = self.m_wheelsData[self.m_runDataPoint].type
      local score = self.m_wheelsData[self.m_runDataPoint].score
 
      local jpType = nil
      if type == 0 then
            jpType =  self.SYMBOL_WHEEL_NODE_Lock
      elseif type == 1 then
            jpType =  self.SYMBOL_WHEEL_NODE_WildReels
      elseif type == 2 then
            jpType =  self.SYMBOL_WHEEL_NODE_Rising
      elseif type == 3 then
            jpType =  self.SYMBOL_WHEEL_NODE_Sweep
      end

      self.m_runDataPoint = self.m_runDataPoint + 1

      return jpType, score
end


function BlazingMotorsWheelView:setNodePoolFunc(getNodeFunc, pushNodeFunc)
      self.m_getNodeByTypeFromPool = getNodeFunc
      self.m_pushNodeToPool = pushNodeFunc
end



function BlazingMotorsWheelView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function BlazingMotorsWheelView:initFeatureUI()
     
      local jpNode = self:findChild("jackPotNode")
      self.test = 0
      local initReelData = self:getInitSequence()

      local featureNode = util_createView("CodeBlazingMotorsSrc.BlazingMotorsWheelNode")
      jpNode:addChild(featureNode)
      
      featureNode:init(TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height,
      self.m_getNodeByTypeFromPool,
      self.m_pushNodeToPool)

      local reelHeight = TIME_IAMGE_SIZE.height
      featureNode:initFirstSymbolBySymbols(initReelData, reelHeight)

      featureNode:initRunDate(nil, function()
            return self:getRunReelData()
      end)
      featureNode:setEndCallBackFun(function(  )
            self:runEndCallBack()
      end)

      self.m_FeatureNode = featureNode 


      local nodechilds = self.m_FeatureNode.m_clipNode:getChildren()
      for i=1,#nodechilds do
            local onenode = nodechilds[i]
            onenode:setVisible(false)
            
      end
      
      self:runCsbAction("start", false, function ()
            self.m_bTouchEnable = true
            -- self:runCsbAction("idleframe", true)
            local childs = self.m_FeatureNode.m_clipNode:getChildren()
            local watiTime = 0.1
            for i= #childs,1,-1 do
                  local node = childs[i]
                  performWithDelay(self,function(  )
                        node:setVisible(true)
                        node:runAnim("start", false)
                  end,watiTime * ( #childs - i))
                  
                  
            end
      end)

      
end

function BlazingMotorsWheelView:setEndValue(endValue)
      self:initAllSymbol(endValue)
      self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
end

function BlazingMotorsWheelView:runEndCallBack()      


      self.m_FeatureNode:playRunEndAnima()

      performWithDelay(self,function(  )
            if self.m_featureOverCallBack ~= nil then
                  self.m_featureOverCallBack()
            end
            
      end,2)
     
      


end

function BlazingMotorsWheelView:getRunReelData()
      local type, score = self:getNextType()
      local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false )
      reelData.jpScore = score
      return  reelData
end

function BlazingMotorsWheelView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function BlazingMotorsWheelView:getInitSequence()
      local reelDatas = {}

      for i = 1, REEL_SYMBOL_COUNT, 1 do 
         local type, score = self:getNextType() 
         local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
         data.jpScore = score
         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end

function BlazingMotorsWheelView:transSymbolData(endValue)
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = endValue.type
 
      if type == 0 then
            jpType =  self.SYMBOL_WHEEL_NODE_Lock
      elseif type == 1 then
            jpType =  self.SYMBOL_WHEEL_NODE_WildReels
      elseif type == 2 then
            jpType =  self.SYMBOL_WHEEL_NODE_Rising
      elseif type == 3 then
            jpType =  self.SYMBOL_WHEEL_NODE_Sweep
      end

      return jpType
end

function BlazingMotorsWheelView:getRunSequence(endValue)
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

            local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, symbolType, bLast)
            reelData.jpScore = jpScore

            reelDatas[#reelDatas + 1] = reelData
      end
      return reelDatas
      
end

function BlazingMotorsWheelView:beginMove()
      self.m_FeatureNode:beginMove()
      local eventDispatcher = self:getEventDispatcher()
      eventDispatcher:removeEventListenersForTarget(self,true)

      self:runCsbAction("idle", true)
end

function BlazingMotorsWheelView:onEnter()
      
      local function onTouchBegan_callback(touch, event)
            if self.m_bTouchEnable == true then
                  self.m_bTouchEnable = false
                  --gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_click_btn.mp3")
                  return true
            end
            return false
      end
    
      local function onTouchMoved_callback(touch, event)
      end
    
      local function onTouchEnded_callback(touch, event)
            if self.m_sendDataFunc ~= nil then
                  self.m_sendDataFunc()
            end
      end
        
      local listener = cc.EventListenerTouchOneByOne:create()
      listener:setSwallowTouches(false)
      listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
      listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
      listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
      local eventDispatcher = self:getEventDispatcher()    
      eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end
  
function BlazingMotorsWheelView:onExit()    
      local featureNode = self.m_FeatureNode
      featureNode:stopAllActions()
      featureNode:removeFromParent()
end


return BlazingMotorsWheelView