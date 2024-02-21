---
--xcyy
--2018年5月23日
--SpartaAddBonusView.lua

local SpartaAddBonusView = class("SpartaAddBonusView",util_require("base.BaseView"))

SpartaAddBonusView.m_FeatureReel = nil
SpartaAddBonusView.m_featureOverCallBack = nil
SpartaAddBonusView.m_featureAddBonusFlyEffectCallBack = nil
SpartaAddBonusView.m_getNodeByTypeFromPool= nil
SpartaAddBonusView.m_pushNodeToPool = nil
SpartaAddBonusView.m_bigPoseidon = nil
SpartaAddBonusView.m_endValueIndex = nil
SpartaAddBonusView.m_endValue = nil
SpartaAddBonusView.m_winSound = nil
SpartaAddBonusView.m_wheelsData = nil
SpartaAddBonusView.m_bTouchEnable = nil
SpartaAddBonusView.m_bRunEnd = nil
local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 300, height = 440}
local SYMBOL_HEIGHT = 110
local REEL_SYMBOL_COUNT = 4

local ALL_RUN_SYMBOL_NUM = 55

SpartaAddBonusView.m_runDataPoint  = nil
SpartaAddBonusView.m_allSymbols = nil

local BONUS_SYMBOL = 94

function SpartaAddBonusView:initUI(machine)

    self.m_machine=machine
    local resourceFilename="Sparta_AddBonus.csb"
    self:createCsbNode(resourceFilename)
    self.effect =  self:findChild("effectFile")
	self.m_effectAct = cc.CSLoader:createTimeline("Socre_Sparta_Scatter_zhongjiang.csb")
	self.effect:runAction(self.m_effectAct)
    util_csbPlayForKey(self.m_effectAct,"actionframe",true)
    
end

function SpartaAddBonusView:initFirstSymbol(_Symbol)
      if self.m_wheelsData == nil then
            self.m_wheelsData = {}
      end
      self.m_FirstList = {}
      for k,value in pairs(_Symbol) do
            local _tpye = value
            local wheel = {}
            wheel.type = _tpye
            self.m_wheelsData[#self.m_wheelsData+1] = wheel
            self.m_FirstList[#self.m_FirstList+1]= wheel
      end
      self:initWheelsData()
      self:initRuningPoint()
end

function SpartaAddBonusView:initWheelsData( )
      local symbolList = {0,1,2,3,4,5,94}
      local RandomNum = 1
      local first = 0
      for i = 1, ALL_RUN_SYMBOL_NUM, 1 do
          local data = xcyy.SlotsUtil:getArc4Random() % (#symbolList-1)+1
          if #self.m_wheelsData <= 55 then
                  if RandomNum >= 7 then
                        local change = xcyy.SlotsUtil:getArc4Random() % 2
                        if change == 0 then
                              RandomNum = 1
                              data = #symbolList
                        end
                  end
                  if first == 4 then
                        RandomNum = 1
                        data = #symbolList
                  end
          end
          local wheel = {}
          wheel.type = symbolList[data]
          if self.m_wheelsData == nil then
            self.m_wheelsData = {}
          end
          self.m_wheelsData[#self.m_wheelsData + 1] = wheel
          RandomNum = RandomNum + 1
          first = first + 1
      end
      for i=#self.m_FirstList,1,-1 do
            self.m_wheelsData[#self.m_wheelsData + 1] = self.m_FirstList[i]
      end

      local data = xcyy.SlotsUtil:getArc4Random() % (#symbolList-1)+1
      local wheel = {}
      wheel.type = symbolList[data]
      self.m_wheelsData[#self.m_wheelsData + 1] = self.m_FirstList[i]
    
      self.m_runDataPoint = 1
end

function SpartaAddBonusView:initAllSymbol()
      self.m_allSymbols = {}
      local iSymbolsNum = #self.m_wheelsData --ALL_RUN_SYMBOL_NUM
      for i = 1, iSymbolsNum, 1 do
            local type = self:getNextType() 
            local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
            self.m_allSymbols[#self.m_allSymbols + 1] = data
            if i >= (#self.m_wheelsData -2) then
                  data.Last = true
                  break
            end
      end
      local more = math.floor(REEL_SYMBOL_COUNT * 0.5)
      for i = 1, more, 1 do
            local type = self:getNextType() 
            local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
            self.m_allSymbols[#self.m_allSymbols + 1] = data
      end

      self.m_FeatureReel:setAllRunSymbols(self.m_allSymbols)
end

function SpartaAddBonusView:initRuningPoint()
   self.m_runDataPoint = 1
end

function SpartaAddBonusView:getNextType()
      
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local _type = self.m_wheelsData[self.m_runDataPoint].type
      self.m_runDataPoint = self.m_runDataPoint + 1

      return _type
end


function SpartaAddBonusView:setNodePoolFunc(getNodeFunc, pushNodeFunc)
      self.m_getNodeByTypeFromPool = getNodeFunc
      self.m_pushNodeToPool = pushNodeFunc
end

function SpartaAddBonusView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function SpartaAddBonusView:setAddBonusFlyEffectCallBackFun(callFunc)
      self.m_featureAddBonusFlyEffectCallBack = callFunc
end

function SpartaAddBonusView:initFeatureUI()
     
      local reelNode = self:findChild("reelNode")
      local initReelData = self:getInitSequence()
    
      local featureReel = util_createView("CodeSpartaSrc.SpartaAddBonusReel")
      reelNode:addChild(featureReel)
      self.m_FeatureReel = featureReel 
      featureReel:init(TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height,
      self.m_getNodeByTypeFromPool,
      self.m_pushNodeToPool)

      local reelHeight = TIME_IAMGE_SIZE.height
      featureReel:initFirstSymbolBySymbols(initReelData, reelHeight)

      featureReel:initRunDate(nil, function()
            return self:getRunReelData()
      end)
      featureReel:setEndCallBackFun(function(  )
            self:runEndCallBack()
      end)

      featureReel:setPlayAddBonusFlyEffectCallBackFun(function(  )
            self:playAddBonusFlyEffectCallBack()
      end)
      
      
      local childs = self.m_FeatureReel.m_clipNode:getChildren()
      for i=1,#childs do
            local node = childs[i]
            node:runAnim("idleframe", false, nil, 20)
      end
      self:initAllSymbol()
end

function SpartaAddBonusView:runEndCallBack()      

      self.m_FeatureReel:playRunEndAnima()

      -- performWithDelay(self, function(  )
      if self.m_featureOverCallBack ~= nil then
            self.m_featureOverCallBack()
      end  
      -- end,2.7)
end

function SpartaAddBonusView:playAddBonusFlyEffectCallBack()

      if self.m_featureAddBonusFlyEffectCallBack ~= nil then
            self.m_featureAddBonusFlyEffectCallBack()
      end  
end
function SpartaAddBonusView:getRunReelData()
      local type = self:getNextType()
      local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false )
      return  reelData
end

function SpartaAddBonusView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      if symbolType == BONUS_SYMBOL then
            zorder = 100
      end
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function SpartaAddBonusView:getInitSequence()
      local reelDatas = {}

      for i = 1, REEL_SYMBOL_COUNT, 1 do 
         local type = self:getNextType() 
         local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end

function SpartaAddBonusView:transSymbolData(endValue)
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = endValue.type

      return type
end

function SpartaAddBonusView:getRunSequence(endValue)
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
            local bLast = nil

            if i == totleCount then
                  symbolType = type
                  bLast = true
                  if self.m_runDataPoint > #self.m_wheelsData then
                        self.m_runDataPoint = 1
                  end
                  self.m_runDataPoint = self.m_runDataPoint + 1
            else
                  symbolType = self:getNextType() 
                  bLast = false
            end

            local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, symbolType, bLast)

            reelDatas[#reelDatas + 1] = reelData
      end
      return reelDatas
      
end

function SpartaAddBonusView:beginMove()
      self.m_FeatureReel:beginMove()
end

function SpartaAddBonusView:onEnter()
end
  
function SpartaAddBonusView:onExit()    
      local featureNode = self.m_FeatureReel
      featureNode:stopAllActions()
      featureNode:removeFromParent()
end



return SpartaAddBonusView