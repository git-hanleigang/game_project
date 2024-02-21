local ZeusRespinRunView = class("ZeusRespinRunView", util_require("base.BaseView"))

ZeusRespinRunView.m_FeatureNode = nil
ZeusRespinRunView.m_featureOverCallBack = nil
ZeusRespinRunView.m_getNodeByTypeFromPool= nil
ZeusRespinRunView.m_pushNodeToPool = nil
ZeusRespinRunView.m_bigPoseidon = nil
ZeusRespinRunView.m_endValueIndex = nil
ZeusRespinRunView.m_endValue = nil
ZeusRespinRunView.m_winSound = nil
ZeusRespinRunView.m_sendDataFunc = nil
ZeusRespinRunView.m_wheelsData = nil

ZeusRespinRunView.m_bRunEnd = nil

local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 260, height = 80}
local SYMBOL_HEIGHT = 30
local REEL_SYMBOL_COUNT = 3
--配置滚动信息


local ALL_RUN_SYMBOL_NUM = 37


ZeusRespinRunView.m_runDataPoint  = nil
ZeusRespinRunView.m_allSymbols = nil


function ZeusRespinRunView:initUI(machine)


      self.m_machine = machine

      self.m_bRunEnd = false
      local resourceFilename="Socre_Zeus_Coin2_MidRun.csb"
      self:createCsbNode(resourceFilename)
      
      self:initWheelsData()

      self:initRuningPoint()

      self:setNodePoolFunc()

      self:initFeatureUI()
      
end  

function ZeusRespinRunView:initWheelsData(  )

      local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
      local spWheels = selfdata.spWheels

      self.m_wheelsData = spWheels or {"Major",15,60,"Minor",20,100,"Major",20,60,"Minor",15,100}


      ALL_RUN_SYMBOL_NUM = 3 * #self.m_wheelsData

      self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1

      self.m_runDataRealPoint = 1
end

function ZeusRespinRunView:getRealWheelData( )
      
      local jpType = nil
      if self.m_runDataRealPoint > #self.m_wheelsData then
          self.m_runDataRealPoint = 1
      end

      local type = self.m_wheelsData[self.m_runDataRealPoint]
      local score = nil
 
      if type == "Grand" then
            jpType = 201
      elseif type == "Major" then
            jpType = 202
      elseif type == "Minor" then
            jpType = 203
      elseif type == "Mini" then
            jpType = 204
      else
            
            jpType = 205

            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = self.m_wheelsData[self.m_runDataRealPoint] * lineBet
      end

      self.m_runDataRealPoint = self.m_runDataRealPoint + 1

      return jpType, score
end

function ZeusRespinRunView:initAllSymbol(endValue)
      self.m_allSymbols = {}
      self.m_endValue = endValue
      local endType = self:getSymbolType(endValue)
      local iSymbolsNum = ALL_RUN_SYMBOL_NUM
      for i = 1, iSymbolsNum, 1 do
            local type, score = self:getRealWheelData( )
            local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            self.m_allSymbols[#self.m_allSymbols + 1] = data
            if i > (#self.m_wheelsData * 2) and endType == data.SymbolType then
                  if data.SymbolType == 205 then

                        if data.jpScore == endValue.score then
                             
                              data.Last = true
                              data.jpScore = endValue.score
                              break
                        end
                  else
                        data.Last = true
                        data.jpScore = endValue.score
                        break   
                  end
                  
            end
      end
      local more = math.floor(REEL_SYMBOL_COUNT * 0.5)
      for i = 1, more, 1 do
            local type, score = self:getRealWheelData( )
            local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            self.m_allSymbols[#self.m_allSymbols + 1] = data
      end
end

function ZeusRespinRunView:getSymbolType(endValue)
      local type = endValue.type
      local jpType = nil

      if type == "Grand" then
            jpType = 201
      elseif type == "Major" then
            jpType = 202
      elseif type == "Minor" then
            jpType = 203
      elseif type == "Mini" then
            jpType = 204
      else
            
            jpType = 205
      end

      return jpType
end

function ZeusRespinRunView:initRuningPoint()
   self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function ZeusRespinRunView:getNextType()
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = self.m_wheelsData[self.m_runDataPoint]
      local score = nil
 
      if type == "Grand" then
            jpType = 201
      elseif type == "Major" then
            jpType = 202
      elseif type == "Minor" then
            jpType = 203
      elseif type == "Mini" then
            jpType = 204
      else
            
            jpType = 205

            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = self.m_wheelsData[self.m_runDataPoint] * lineBet
      end

      self.m_runDataPoint = self.m_runDataPoint + 1

      return jpType, score
end


function ZeusRespinRunView:setNodePoolFunc()

      self.m_getNodeByTypeFromPool = function(symbolType)

            local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
            local actNode = util_createAnimation(ccbName..".csb")
            
            return actNode
      end


      self.m_pushNodeToPool = function(targSp)
            -- self.m_machine:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
      end
      
end

function ZeusRespinRunView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function ZeusRespinRunView:initFeatureUI()
     
      local jpNode = self:findChild("Node_Coin_zi")

      local initReelData = self:getInitSequence()

      local featureNode = util_createView("CodeZeusSrc.ZeusRespinRunNode")
      jpNode:addChild(featureNode)
      featureNode:setPosition(130,41)
      
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
      
      self.m_FeatureNode:beginMove()
end

function ZeusRespinRunView:setEndValue(endValue)
      self:initAllSymbol(endValue)

      self.m_FeatureNode.m_runSpeed = 300
      self.m_FeatureNode:setresDis(15)
      self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
   
end

function ZeusRespinRunView:runEndCallBack()      

      
      if self.m_featureOverCallBack then
            self.m_featureOverCallBack()
      end
end

function ZeusRespinRunView:getRunReelData()
      local type, score = self:getNextType()
      local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false )
      reelData.jpScore = score
      return  reelData
end

function ZeusRespinRunView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function ZeusRespinRunView:getInitSequence()
      local reelDatas = {}

      for i = 1, REEL_SYMBOL_COUNT, 1 do 
         local type, score = self:getNextType() 
         local data = self:getReelData(1,TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false ) 
         data.jpScore = score
         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end

function ZeusRespinRunView:transSymbolData(endValue)
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = endValue.type
 
      if type == "Grand" then
            jpType = 201
      elseif type == "Major" then
            jpType = 202
      elseif type == "Minor" then
            jpType = 203
      elseif type == "Mini" then
            jpType = 204
      else
            
            jpType = 205
      end


      return jpType
end

function ZeusRespinRunView:getRunSequence(endValue)
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

function ZeusRespinRunView:removeFeatureNode( )
      local featureNode = self.m_FeatureNode
      featureNode:stopAllActions()
      featureNode:removeFromParent()
end

function ZeusRespinRunView:beginMove()
      self.m_FeatureNode:beginMove()

end

function ZeusRespinRunView:onEnter()

end
  
function ZeusRespinRunView:onExit()    
      
end


return ZeusRespinRunView