local JackPotView = class("JackPotView", util_require("base.BaseView"))

JackPotView.m_FeatureNode = nil
JackPotView.m_featureOverCallBack = nil
JackPotView.m_getNodeByTypeFromPool= nil
JackPotView.m_pushNodeToPool = nil
JackPotView.m_bigPoseidon = nil
JackPotView.m_endValueIndex = nil
JackPotView.m_endValue = nil
JackPotView.m_winSound = nil
JackPotView.m_sendDataFunc = nil
JackPotView.m_wheelsData = nil
JackPotView.m_bTouchEnable = nil
JackPotView.m_bRunEnd = nil

local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 650, height = display.height}
local SYMBOL_HEIGHT = 200
local REEL_SYMBOL_COUNT = math.ceil( TIME_IAMGE_SIZE.height / 200 )
--配置滚动信息
local BASE_RNN_COUNT = 3
local OFF_RUN_COUNT = 3
local JACKPOT_COUNT = 2

local ALL_RUN_SYMBOL_NUM = 90

JackPotView.JackPotSoundBGId = nil -- jackPot背景音乐

JackPotView.m_runDataPoint  = nil
JackPotView.m_allSymbols = nil
-- 5000,500,100,30,10



function JackPotView:initUI(datas)
      if REEL_SYMBOL_COUNT %2 == 0 then
            REEL_SYMBOL_COUNT = REEL_SYMBOL_COUNT + 1
      end
      self.m_bTouchEnable = false
      self.m_bRunEnd = false
      local resourceFilename="Kangaroos/KangaroosBonusLayer.csb"
      self:createCsbNode(resourceFilename)
      
      self:initWheelsData(datas)

      self:initRuningPoint()
      

      --gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_show_view.ogg",false,function(  )
            -- self.JackPotSoundBGId =   gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_yin.ogg",true)
      --end)

end  

function JackPotView:initWheelsData( datas )
      for i = 1, #datas, 1 do
          local data = datas[i]
          local vecStrs = util_string_split(data,",")
          local wheel = {}
          wheel.type = vecStrs[1]
          wheel.score = tonumber(vecStrs[2])
          if self.m_wheelsData == nil then
            self.m_wheelsData = {}
          end
          self.m_wheelsData[#self.m_wheelsData + 1] = wheel
      end
      self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function JackPotView:initAllSymbol(endValue)
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

function JackPotView:getSymbolType(endValue)
      local type = endValue.type
      local jpType = nil
      if type == "0x" then
            jpType = 100
      elseif type == "1x" then
            jpType = 101
      elseif type == "2x" then
            jpType = 102
      elseif type == "3x" then
            jpType = 103
      elseif type == "4x" then
            jpType = 104
      elseif type == "Grand" then
            jpType = 105
      elseif type == "Major" then
            jpType = 106
      elseif type == "Minor" then
            jpType = 107
      end
      return jpType
end

function JackPotView:initRuningPoint()
   self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function JackPotView:getNextType()
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end
      self.test = self.test + 1
      local type = self.m_wheelsData[self.m_runDataPoint].type
      local score = self.m_wheelsData[self.m_runDataPoint].score
 
      if type == "0x" then
            jpType = 100
      elseif type == "1x" then
            jpType = 101
      elseif type == "2x" then
            jpType = 102
      elseif type == "3x" then
            jpType = 103
      elseif type == "4x" then
            jpType = 104
      elseif type == "Grand" then
            jpType = 105
      elseif type == "Major" then
            jpType = 106
      elseif type == "Minor" then
            jpType = 107
      end

      self.m_runDataPoint = self.m_runDataPoint + 1

      return jpType, score
end


function JackPotView:setNodePoolFunc(getNodeFunc, pushNodeFunc)
      self.m_getNodeByTypeFromPool = getNodeFunc
      self.m_pushNodeToPool = pushNodeFunc
end

function JackPotView:setSendDataFunc(sendDataFunc)
      self.m_sendDataFunc = sendDataFunc
end

function JackPotView:setMoveEndCallBackFun(callFunc)
      self.m_moveEndCallBack = callFunc
end
function JackPotView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function JackPotView:initFeatureUI()
     
      local jpNode = self:findChild("jackPotNode")
      self.test = 0
      local initReelData = self:getInitSequence()

      local featureNode = util_createView("CodeKangaroosSrc.JackPotNode")
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
      
      self:runCsbAction("show", false, function ()
            self.m_bTouchEnable = true
            self:runCsbAction("animation0", true, nil, 20)
      end, 20)

      local childs = self.m_FeatureNode.m_clipNode:getChildren()
      for i=1,#childs do
            local node = childs[i]
            node:runAnim("show", false, nil, 20)
            
      end
end

function JackPotView:setEndValue(endValue)
      self:initAllSymbol(endValue)
      self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
      -- self.m_endValue = endValue
      -- -- local runSequence = 
      -- self.m_FeatureNode:setEndDate(function()
      --       self.m_endValueIndex = nil
      --       print(self.test)
      --       for i = self.m_runDataPoint, #self.m_wheelsData, 1 do
      --             local wheel = self.m_wheelsData[i]
      --             if endValue.type == wheel.type then
      --                   self.m_endValueIndex = i
      --                   break
      --             end
      --       end
      --       if self.m_endValueIndex == nil then
      --             for i = 1, #self.m_wheelsData, 1 do
      --                   local wheel = self.m_wheelsData[i]
      --                   if endValue.type == wheel.type then
      --                         self.m_endValueIndex = i
      --                         break
      --                   end
      --             end
      --       end
      --       return self:getRunSequence(self.m_endValue)
      -- end)
end

function JackPotView:runEndCallBack()      
      if(nil ~= self.m_moveEndCallBack)then
            self.m_moveEndCallBack()
      end
      
      local winCoins = 0
      

      self.m_FeatureNode:playRunEndAnima()
      if self.m_endValue.type == "Grand" or self.m_endValue.type == "Major" or self.m_endValue.type == "Minor" then
            gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_reward_jackpot.mp3")
      else
            gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_reward_diamond.mp3")
      end
      
      
      self:runCsbAction("jiesuan", false, nil, 20)
      performWithDelay(self, function(  )

            

            self:runCsbAction("over", false, function ()
                  if self.JackPotSoundBGId then
                        gLobalSoundManager:stopAudio(self.JackPotSoundBGId) 
                        self.JackPotSoundBGId = nil
                  end
      
                  -- gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_show_view.ogg")
                  
                  if self.m_featureOverCallBack ~= nil then
                        self.m_featureOverCallBack()
                  end
            end, 20)
            local childs = self.m_FeatureNode.m_clipNode:getChildren()
            for i=1,#childs do
                  local node = childs[i]
                  node:runAnim("over", false, nil, 20)
                  
            end
      end,2.7)
end

function JackPotView:getRunReelData()
      local type, score = self:getNextType()
      local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false )
      reelData.jpScore = score
      return  reelData
end

function JackPotView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function JackPotView:getInitSequence()
      local reelDatas = {}

      for i = 1, REEL_SYMBOL_COUNT, 1 do 
         local type, score = self:getNextType() 
         local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
         data.jpScore = score
         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end

function JackPotView:transSymbolData(endValue)
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = endValue.type
 
      if type == "0x" then
            jpType = 100
      elseif type == "1x" then
            jpType = 101
      elseif type == "2x" then
            jpType = 102
      elseif type == "3x" then
            jpType = 103
      elseif type == "4x" then
            jpType = 104
      elseif type == "Grand" then
            jpType = 105
      elseif type == "Major" then
            jpType = 106
      elseif type == "Minor" then
            jpType = 107
      end
      return jpType
end

function JackPotView:getRunSequence(endValue)
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

function JackPotView:beginMove()
      self.m_FeatureNode:beginMove()
      local eventDispatcher = self:getEventDispatcher()
      eventDispatcher:removeEventListenersForTarget(self,true)

      self:runCsbAction("actionframe", true, nil, 20)
end

function JackPotView:onEnter()
      
      local function onTouchBegan_callback(touch, event)
            if self.m_bTouchEnable == true then
                  self.m_bTouchEnable = false
                  gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_click_btn.mp3")
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
  
function JackPotView:onExit()    
      local featureNode = self.m_FeatureNode
      featureNode:stopAllActions()
      featureNode:removeFromParent()
end


return JackPotView