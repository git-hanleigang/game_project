local MonsterPartyWheelRunView = class("MonsterPartyWheelRunView", util_require("base.BaseView"))

MonsterPartyWheelRunView.m_FeatureNode = nil
MonsterPartyWheelRunView.m_featureOverCallBack = nil
MonsterPartyWheelRunView.m_getNodeByTypeFromPool= nil
MonsterPartyWheelRunView.m_pushNodeToPool = nil
MonsterPartyWheelRunView.m_bigPoseidon = nil
MonsterPartyWheelRunView.m_endValueIndex = nil
MonsterPartyWheelRunView.m_endValue = nil
MonsterPartyWheelRunView.m_winSound = nil
MonsterPartyWheelRunView.m_sendDataFunc = nil
MonsterPartyWheelRunView.m_wheelsData = nil

MonsterPartyWheelRunView.m_bRunEnd = nil

MonsterPartyWheelRunView.FeatureNode_Count = 0

MonsterPartyWheelRunView.TIME_IAMGE_SIZE = nil
MonsterPartyWheelRunView.SYMBOL_HEIGHT = nil
MonsterPartyWheelRunView.REEL_SYMBOL_COUNT = 7
--配置滚动信息
MonsterPartyWheelRunView.ALL_RUN_SYMBOL_NUM = 37


MonsterPartyWheelRunView.m_runDataPoint  = nil
MonsterPartyWheelRunView.m_allSymbols = nil


function MonsterPartyWheelRunView:initUI(data)


      self.TIME_IAMGE_SIZE = data.imgSize
      self.SYMBOL_HEIGHT = data.symbolHeight

      self.m_machine = data.machine

      self.m_wheelsData = data.wheelsData 
      self.m_isAnit = data.isAnit

      self.m_bRunEnd = false
      local resourceFilename= data.csbPath 

      self:createCsbNode(resourceFilename)
      
      self:initWheelsData()

      self:initRuningPoint()

      self:setNodePoolFunc()

      self:initFeatureUI()
      
end  

function MonsterPartyWheelRunView:initWheelsData(  )

      


      self.ALL_RUN_SYMBOL_NUM = 3 * #self.m_wheelsData

      self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1

      self.m_runDataRealPoint = 1
end

function MonsterPartyWheelRunView:getRealWheelData( )
      
      local jpType = nil
      if self.m_runDataRealPoint > #self.m_wheelsData then
          self.m_runDataRealPoint = 1
      end

      local type = self.m_wheelsData[self.m_runDataRealPoint]
      local score = nil
 
      if type == 0 then
            jpType = 201
      elseif type == 1 then
            jpType = 202
      elseif type == 2 then
            jpType = 203
      elseif type == 3 then
            jpType = 204

      elseif type == 5 then
            jpType = 205

      elseif type == 8 then
            jpType = 206

      elseif type == 10 then
            jpType = 207

      elseif type == 12 then
            jpType = 208

      end

      self.m_runDataRealPoint = self.m_runDataRealPoint + 1

      return jpType, score
end

function MonsterPartyWheelRunView:initAllSymbol(endValue)
      self.m_allSymbols = {}
      self.m_endValue = endValue
      local endType = self:getSymbolType(endValue)
      local iSymbolsNum = self.ALL_RUN_SYMBOL_NUM
      for i = 1, iSymbolsNum, 1 do
            local type, score = self:getRealWheelData( )
            local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            self.m_allSymbols[#self.m_allSymbols + 1] = data
            if i > (#self.m_wheelsData * 2) and endType == data.SymbolType then
                  data.Last = true
                  data.jpScore = endValue.score
                  break
            end
      end
      local more = math.floor(self.REEL_SYMBOL_COUNT * 0.5)
      for i = 1, more, 1 do
            local type, score = self:getRealWheelData( )
            local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            self.m_allSymbols[#self.m_allSymbols + 1] = data
      end
end

function MonsterPartyWheelRunView:getSymbolType(endValue)
      local type = endValue.type
      local jpType = nil

      if type == 0 then
            jpType = 201
      elseif type == 1 then
            jpType = 202
      elseif type == 2 then
            jpType = 203
      elseif type == 3 then
            jpType = 204

      elseif type == 5 then
            jpType = 205

      elseif type == 8 then
            jpType = 206
           
      elseif type == 10 then
            jpType = 207
         
      elseif type == 12 then
            jpType = 208
           
      end

      return jpType
end

function MonsterPartyWheelRunView:initRuningPoint()
   self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function MonsterPartyWheelRunView:getNextType()
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = self.m_wheelsData[self.m_runDataPoint]
      local score = nil
 
      if type == 0 then
            jpType = 201
      elseif type == 1 then
            jpType = 202
      elseif type == 2 then
            jpType = 203
      elseif type == 3 then
            jpType = 204

      elseif type == 5 then
            jpType = 205

      elseif type == 8 then
            jpType = 206

      elseif type == 10 then
            jpType = 207

      elseif type == 12 then
            jpType = 208

      end

      self.m_runDataPoint = self.m_runDataPoint + 1

      return jpType, score
end


function MonsterPartyWheelRunView:setNodePoolFunc()

      self.m_getNodeByTypeFromPool = function(symbolType)

            local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)
            local actNode = util_createAnimation(ccbName..".csb")
            
            return actNode
      end


      self.m_pushNodeToPool = function(targSp)
            -- self.m_machine:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
      end
      
end

function MonsterPartyWheelRunView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function MonsterPartyWheelRunView:initFeatureUI()
     
      local jpNode = self:findChild("wheel")

      local initReelData = self:getInitSequence()

      local featureNode = util_createView("CodeMonsterPartySrc.MonsterPartyWheelRunNode",self )
      jpNode:addChild(featureNode)
      -- featureNode:setPosition(130,41)
      
      featureNode:init(self.TIME_IAMGE_SIZE.width, self.TIME_IAMGE_SIZE.height,
      self.m_getNodeByTypeFromPool,
      self.m_pushNodeToPool)

      local reelHeight = self.TIME_IAMGE_SIZE.height
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

function MonsterPartyWheelRunView:setEndValue(endValue)
      self:initAllSymbol(endValue)

      self.m_FeatureNode.isBeginRun = true
      self.m_FeatureNode.m_runSpeed = 300
      self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
   
end

function MonsterPartyWheelRunView:runEndCallBack()      

      
      if self.m_featureOverCallBack then
            self.m_featureOverCallBack()
      end
end

function MonsterPartyWheelRunView:getRunReelData()
      local type, score = self:getNextType()
      local reelData = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false )
      reelData.jpScore = score
      return  reelData
end

function MonsterPartyWheelRunView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function MonsterPartyWheelRunView:getInitSequence()
      local reelDatas = {}

      for i = 1, self.REEL_SYMBOL_COUNT, 1 do 
         local type, score = self:getNextType() 
         local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
         data.jpScore = score
         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end

function MonsterPartyWheelRunView:transSymbolData(endValue)
      local jpType = nil
      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = endValue.type
 
      if type == 0 then
            jpType = 201
      elseif type == 1 then
            jpType = 202
      elseif type == 2 then
            jpType = 203
      elseif type == 3 then
            jpType = 204

      elseif type == 5 then
            jpType = 205
            
      elseif type == 8 then
            jpType = 206
          
      elseif type == 10 then
            jpType = 207
            
      elseif type == 12 then
            jpType = 208
          
      end


      return jpType
end

function MonsterPartyWheelRunView:getRunSequence(endValue)
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

            local reelData = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, symbolType, bLast)
            reelData.jpScore = jpScore

            reelDatas[#reelDatas + 1] = reelData
      end
      return reelDatas
      
end

function MonsterPartyWheelRunView:removeFeatureNode( )
      local featureNode = self.m_FeatureNode
      featureNode:stopAllActions()
      featureNode:removeFromParent()
end

function MonsterPartyWheelRunView:beginMove()
     

end

function MonsterPartyWheelRunView:onEnter()

end
  
function MonsterPartyWheelRunView:onExit()    
      
end


return MonsterPartyWheelRunView