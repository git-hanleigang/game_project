local WheelOfRomanceFeatureView = class("WheelOfRomanceFeatureView", util_require("base.BaseView"))

WheelOfRomanceFeatureView.m_FeatureNode = nil
WheelOfRomanceFeatureView.m_featureOverCallBack = nil
WheelOfRomanceFeatureView.m_getNodeByTypeFromPool= nil
WheelOfRomanceFeatureView.m_pushNodeToPool = nil
WheelOfRomanceFeatureView.m_endValue = nil
WheelOfRomanceFeatureView.m_wheelsData = nil
WheelOfRomanceFeatureView.m_wheelsType = nil

WheelOfRomanceFeatureView.m_bRunEnd = nil

WheelOfRomanceFeatureView.RUNTYPE_GREEN = 0 -- 左
WheelOfRomanceFeatureView.RUNTYPE_BULE = 1 -- 左
WheelOfRomanceFeatureView.RUNTYPE_PURPLE = 2 -- 左
WheelOfRomanceFeatureView.RUNTYPE_RED = 3 -- 左
WheelOfRomanceFeatureView.RUNTYPE_YELLOW = 4 --右

WheelOfRomanceFeatureView.VIEW_1 = 1 -- 由左至右
WheelOfRomanceFeatureView.VIEW_2 = 2 
WheelOfRomanceFeatureView.VIEW_3 = 3 
WheelOfRomanceFeatureView.VIEW_4 = 4 

-- 4 -- 向前 1
-- 0,1，2，3 -- 后退 0

-- 信号与钱数是一一对应的

-- bonusgame 假滚 信号
WheelOfRomanceFeatureView.WHEEL_RUN_TYPE_1 = {}
WheelOfRomanceFeatureView.WHEEL_RUN_TYPE_2 = {}
WheelOfRomanceFeatureView.WHEEL_RUN_TYPE_3 = {}
WheelOfRomanceFeatureView.WHEEL_RUN_TYPE_4 = {}


-- bonusgame 假滚 钱数
WheelOfRomanceFeatureView.WHEEL_RUN_DATA_1 = {}
WheelOfRomanceFeatureView.WHEEL_RUN_DATA_2 = {}
WheelOfRomanceFeatureView.WHEEL_RUN_DATA_3 = {} 
WheelOfRomanceFeatureView.WHEEL_RUN_DATA_4 = {}



WheelOfRomanceFeatureView.m_runDataPoint  = nil
WheelOfRomanceFeatureView.m_allSymbols = nil

--配置滚动信息
WheelOfRomanceFeatureView.TIME_IAMGE_SIZE = {width = 260, height = 80}
WheelOfRomanceFeatureView.SYMBOL_HEIGHT = 62
WheelOfRomanceFeatureView.REEL_SYMBOL_COUNT = 3
WheelOfRomanceFeatureView.ALL_RUN_SYMBOL_NUM = 0
WheelOfRomanceFeatureView.allSymbolNum = 17
function WheelOfRomanceFeatureView:initUI(_runData)

      -- bonusgame 假滚 信号
      self.WHEEL_RUN_TYPE_1 = {4,4,4,0,4,0,4,0,4,4,4,0,4,0,4,0}
      self.WHEEL_RUN_TYPE_2 = {1,4,1,4,1,4,1,4,1,4,1,4,1,4,1,4} 
      self.WHEEL_RUN_TYPE_3 = {2,4,2,4,2,4,2,4,2,4,2,4,2,4,2,4} 
      self.WHEEL_RUN_TYPE_4 = {3,4,3,4,3,4,3,4,3,4,3,4,3,4,3,4} 


      -- bonusgame 假滚 钱数
      self.WHEEL_RUN_DATA_1 = {25,75,25,100,25,100,25,100,25,75,25,100,25,100,25,100}
      self.WHEEL_RUN_DATA_2 = {100,50,150,50,100,50,100,50,150,50,100,50,150,50,100,50} 
      self.WHEEL_RUN_DATA_3 = {500,75,500,75,250,75,500,75,500,75,150,75,500,75,100,75} 
      self.WHEEL_RUN_DATA_4 = {750,100,750,100,500,100,750,100,750,100,500,100,750,100,250,100} 

      self.m_machine = _runData.m_machine
      self.m_index = _runData.m_index
      
      self:createCsbNode("WheelOfRomance_Wheel_1_"..self.m_index..".csb")

      self.m_bRunEnd = false

      -- view1,view3  显示的是四个，六个，但实际是五个，七个，在创建时移动了位置，改变了显示的区域
      -- 在初始化滚动区域时移动的位置 initFeatureUI() self.TIME_IAMGE_SIZE.decelerNum
      if self.m_index == self.VIEW_1 then
            self.TIME_IAMGE_SIZE = {width = 158,height = 300, uiheight = 250,decelerNum = 20}
            self.REEL_SYMBOL_COUNT = 5
            self.SYMBOL_HEIGHT = 60
      elseif self.m_index == self.VIEW_2 then  
            self.TIME_IAMGE_SIZE = {width = 158,height = 420, uiheight = 300,decelerNum = 20}
            self.REEL_SYMBOL_COUNT = 7
            self.SYMBOL_HEIGHT = 60
      elseif self.m_index == self.VIEW_3 then 
            self.TIME_IAMGE_SIZE = {width = 158,height = 420, uiheight = 362.5,decelerNum = 20}
            self.SYMBOL_HEIGHT = 60
            self.REEL_SYMBOL_COUNT = 7
      elseif self.m_index == self.VIEW_4 then 
            self.TIME_IAMGE_SIZE = {width = 158, height = 540,uiheight = 412.5,decelerNum = 20 }
            self.SYMBOL_HEIGHT = 60
            self.REEL_SYMBOL_COUNT = 9
      end
     
      --PortraitWheel数据 
      if self.m_machine.m_portraitWheel then
            self:analysisPortraitWheelData( )
      end
      
      self:initWheelsData()

      self:setNodePoolFunc()

      self:initFeatureUI()
      
end

function WheelOfRomanceFeatureView:analysisPortraitWheelData( )


      for index = 1,#self.m_machine.m_portraitWheel do
            self["WHEEL_RUN_TYPE_"..index] = {}
            self["WHEEL_RUN_DATA_"..index] = {}
            local data = self.m_machine.m_portraitWheel[index]
            local splitTable = util_string_split(data,";")
            for k = 1,#splitTable do
                  local splitdata = splitTable[k]
                 local rundata =  util_string_split(splitdata,"=" , true)
                 local runType = rundata[2]
                 if rundata[2] == 1 then

                        runType = 4
                 else
                        runType = index - 1
                 end
                 table.insert( self["WHEEL_RUN_TYPE_"..index], runType )
                 table.insert( self["WHEEL_RUN_DATA_"..index], rundata[1] )
            end
      end
end

function WheelOfRomanceFeatureView:initWheelsData(   )

      self.m_wheelsData = self["WHEEL_RUN_DATA_"..self.m_index]  
      self.ALL_RUN_SYMBOL_NUM = 5 * #self.m_wheelsData
      self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
      self.m_runDataRealPoint = 1

      self.m_wheelsType = self["WHEEL_RUN_TYPE_"..self.m_index]  
      
end

function WheelOfRomanceFeatureView:getNetLineBet( )
      
      local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
      local bets = selfdata.bets or  globalData.slotRunData:getCurTotalBet()
      return  bets

end

function WheelOfRomanceFeatureView:update( )
      
end

function WheelOfRomanceFeatureView:getRealWheelData( )
      
      
      if self.m_runDataRealPoint > #self.m_wheelsData then
          self.m_runDataRealPoint = 1
      end

      local lineBet = self:getNetLineBet( )
      local score = self.m_wheelsData[self.m_runDataRealPoint] * lineBet
      local jpType = self.m_wheelsType[self.m_runDataRealPoint]

      self.m_runDataRealPoint = self.m_runDataRealPoint + 1

      return jpType, score,lineBet
end

function WheelOfRomanceFeatureView:initAllSymbol(_endIndex)
      self.m_allSymbols = {}
      self.m_endValue = _endIndex -- 最终停止的 位置
  
      local endType = self["WHEEL_RUN_TYPE_"..self.m_index][_endIndex]

      
      -- 存上占位的
      for i = 1, self.allSymbolNum, 1 do
            local type, score,lineBet = self:getRealWheelData( )
            local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            data.jpBet = lineBet
            self.m_allSymbols[#self.m_allSymbols + 1] = data
      end


      local breakIndex = nil
      for i = 1, self.ALL_RUN_SYMBOL_NUM, 1 do

            local dataEndIndex = self.m_runDataRealPoint
            if dataEndIndex > #self.m_wheelsData  then
                  dataEndIndex = 1
            end

            local type, score,lineBet = self:getRealWheelData( )
            local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            data.jpBet = lineBet
            self.m_allSymbols[#self.m_allSymbols + 1] = data

            if dataEndIndex == _endIndex then
                  data.Last = true
                  local lineBet = self:getNetLineBet( )
                  data.jpScore = self["WHEEL_RUN_DATA_"..self.m_index][_endIndex] * lineBet -- 算法给出的计算方式
                  data.jpBet = lineBet
                  breakIndex = i  

                  break   
            end
            
      end

      local moreNum =   math.floor(self.REEL_SYMBOL_COUNT * 0.5)
      local addindex = 0
      
      for i = breakIndex, self.ALL_RUN_SYMBOL_NUM, 1 do
            local type, score,lineBet = self:getRealWheelData( )
            local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
            data.jpScore = score
            data.jpBet = lineBet
            self.m_allSymbols[#self.m_allSymbols + 1] = data

            addindex = addindex + 1
            if  addindex >= moreNum then

                  break   

            end
      end



end


function WheelOfRomanceFeatureView:getNextType()


      if self.m_runDataPoint > #self.m_wheelsData then
          self.m_runDataPoint = 1
      end

      local type = self.m_wheelsData[self.m_runDataPoint]

      local lineBet = self:getNetLineBet( )
      local score = self.m_wheelsData[self.m_runDataPoint] * lineBet

      local jpType = self.m_wheelsType[self.m_runDataPoint]

      self.m_runDataPoint = self.m_runDataPoint + 1

      return jpType, score,lineBet
end


function WheelOfRomanceFeatureView:setNodePoolFunc()

      self.m_getNodeByTypeFromPool = function(symbolType)

            local ccbName = "Socre_WheelOfRomance_Wheel_" .. symbolType
            local actNode = util_createAnimation(ccbName..".csb")
            
            return actNode
      end


      self.m_pushNodeToPool = function(targSp)

      end
      
end

function WheelOfRomanceFeatureView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function WheelOfRomanceFeatureView:initFeatureUI()
     
      local jpNode = self:findChild("Node_Reel")

      local initReelData = self:getInitSequence()

      local featureNode = util_createView("CodeWheelOfRomanceSrc.PortraitWheel.WheelOfRomanceFeatureNode")
      jpNode:addChild(featureNode)

      featureNode:init(self.TIME_IAMGE_SIZE.width, self.TIME_IAMGE_SIZE.height,self.m_getNodeByTypeFromPool,self.m_pushNodeToPool,self.TIME_IAMGE_SIZE.uiheight,self.TIME_IAMGE_SIZE.decelerNum)

      --移动位置
      if self.m_index == self.VIEW_1 then
            featureNode.m_clipNode:setPositionY(-25)
            featureNode.m_runclipNode:setPositionY(-25)
            featureNode:setPositionY(0)
      elseif self.m_index == self.VIEW_2 then 
            featureNode.m_clipNode:setPositionY(-61)
            featureNode.m_runclipNode:setPositionY(-61)
            featureNode:setPositionY(1)
      elseif self.m_index == self.VIEW_3 then 
            featureNode.m_clipNode:setPositionY(-28.5)
            featureNode.m_runclipNode:setPositionY(-28.5)
            featureNode:setPositionY(0.5)
      elseif self.m_index == self.VIEW_4 then 
            featureNode.m_clipNode:setPositionY(-63.5)
            featureNode.m_runclipNode:setPositionY(-63.5)
            featureNode:setPositionY(1)
      end

      featureNode:initFirstSymbolBySymbols(initReelData)

      featureNode:initRunDate(nil, function()
            return self:getRunReelData()
      end)
      featureNode:setEndCallBackFun(function(  )
            self:runEndCallBack()
      end)

      self.m_FeatureNode = featureNode 
      
end

function WheelOfRomanceFeatureView:updateFeatureNodeScore( )
      
      self.m_FeatureNode:updateRunNodeScore(self:getNetLineBet( ) )
end

function WheelOfRomanceFeatureView:setEndValue(_endIndex)
      self:initAllSymbol(_endIndex)

      self.m_FeatureNode:setresDis(15)
      self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
   
end

function WheelOfRomanceFeatureView:runEndCallBack()      

      
      if self.m_featureOverCallBack then
            self.m_featureOverCallBack()
      end
end

function WheelOfRomanceFeatureView:getRunReelData()
      local type, score,lineBet = self:getNextType()
      local reelData = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false )
      reelData.jpScore = score
      reelData.jpBet = lineBet
      return  reelData
end

function WheelOfRomanceFeatureView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function WheelOfRomanceFeatureView:getInitSequence()
      local reelDatas = {}

      for i = 1, self.REEL_SYMBOL_COUNT, 1 do 
         local type, score,lineBet = self:getNextType() 
         local data = self:getReelData(1,self.TIME_IAMGE_SIZE.width, self.SYMBOL_HEIGHT, type, false ) 
         data.jpScore = score
         data.jpBet = lineBet
         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end



function WheelOfRomanceFeatureView:removeFeatureNode( )
      local featureNode = self.m_FeatureNode
      featureNode:stopAllActions()
      featureNode:removeFromParent()
end

function WheelOfRomanceFeatureView:beginMove()
      self.m_FeatureNode:initAction()
      self.m_FeatureNode:beginMove()

end

function WheelOfRomanceFeatureView:onEnter()

end
  
function WheelOfRomanceFeatureView:onExit()    
      
end


return WheelOfRomanceFeatureView