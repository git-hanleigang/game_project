local FiveDragonFeatureView = class("FiveDragonFeatureView",  cc.Node)

FiveDragonFeatureView.slotMachine = nil
FiveDragonFeatureView.m_FeatureNode = nil
FiveDragonFeatureView.m_featureSpPool = nil
FiveDragonFeatureView.m_featureNodeEndNum = nil
FiveDragonFeatureView.m_featureOverCallBack = nil
FiveDragonFeatureView.m_signalTypeArray = {1,2,3,5,10} -- 配置小块type
FiveDragonFeatureView.m_musicRunAudioID = nil -- 存储的声音ID

local FeatureNode_Count = 0

local TIME_IMAGE_COUNT = 10
local TIME_IAMGE_SIZE = {width = 160, height = 96}
--配置滚动信息
local BASE_RNN_COUNT = 38
local OFF_RUN_COUNT = 3



function FiveDragonFeatureView:ctor()
      self:initFiveDragonFeatureView()
      self.m_FeatureNode = {}
      self.m_featureSpPool = {}
      self.m_featureNodeEndNum = 0
end

function FiveDragonFeatureView:getFeatureSp(type)
      local spNode = util_createSprite("effect/FiveDragon_shuzi_".. type ..".png")
      spNode.AnchorPointY = 0.5
      -- spNode:retain()
      return spNode 
end

function FiveDragonFeatureView:setSignalTypeArray(array)
     self.m_signalTypeArray = array
end

function FiveDragonFeatureView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
 end

function FiveDragonFeatureView:pushFeatureSp(spNode)
      -- spNode:release()
end

function FiveDragonFeatureView:initFeatureUI(datas,father)

      FeatureNode_Count = #datas
      for i=1,#datas do
            local data = datas[i]
            local pos = data.Pos
            local ArrayPos = data.ArrayPos
            local endValue = data.EndValue
            local runSequence = self:getRunSequence(endValue)
            local initReelData = self:getInitSequence()

            local featureNode = util_createView("CodeFiveDragonSrc.FeatureNode", endValue)
            self:addChild(featureNode)

            featureNode:init(TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, function(type)
                  return self:getFeatureSp(type)
            end, function(spNode)
                  return self:pushFeatureSp(spNode)
            end)
            pos = self:convertToNodeSpace(pos)
            featureNode:setPosition(pos)

            featureNode:initFirstSymbolBySymbols(initReelData)
            featureNode:initRunDate(runSequence, function(  )
                  return self:getRunReelData( )
            end)
            featureNode:setEndCallBackFun(function(  )
                  self:runEndCallBack()
            end)

            self.m_FeatureNode[#self.m_FeatureNode + 1] = featureNode 

            
            if #featureNode.m_symbolNodeList > 0 then
                  featureNode.m_symbolNodeList[#featureNode.m_symbolNodeList]:setVisible(false)
            end
      
            featureNode:runCsbAction("start")

            performWithDelay(self,function( )
                  gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_DragonChange.mp3")
                  
                  if #featureNode.m_symbolNodeList > 0 then
                        featureNode.m_symbolNodeList[#featureNode.m_symbolNodeList]:setVisible(true)
                  end
                  performWithDelay(self, function(  )
                        featureNode:runCsbAction("idleframe", true)
                  end, 1) 
                  performWithDelay(featureNode,function( )
                        featureNode:beginMove()
                        father.m_csbOwner["darkBg"]:setVisible(true)
                  end, i*0.05 + ArrayPos[2]*0.3)
            end,1.1)

            
           
      end

      performWithDelay(self,function( )
            self.m_musicRunAudioID =  gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_LittleBit_Run.mp3")
      end,1.5)

      

end

function FiveDragonFeatureView:runEndCallBack()
      self.m_featureNodeEndNum = self.m_featureNodeEndNum + 1

      if self.m_featureNodeEndNum == FeatureNode_Count then
            if self.m_musicRunAudioID then -- 停止滚动音效
                  gLobalSoundManager:stopAudio(self.m_musicRunAudioID) 
            end
            
            performWithDelay(self, function()
                  if self.m_featureOverCallBack ~= nil then
                        self.m_featureOverCallBack()
                  end
            end, 1)
      end
end

function FiveDragonFeatureView:getRunReelData( )
      local index = math.random(1 ,#self.m_signalTypeArray )
      local type = self.m_signalTypeArray[index] 
      local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, type, false )
      return  reelData
end

function FiveDragonFeatureView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function FiveDragonFeatureView:getInitSequence()
      local reelDatas = {}
      local index = math.random(1 ,#self.m_signalTypeArray )
      local type = self.m_signalTypeArray[index] 
      reelDatas[#reelDatas + 1]  = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, type, false )
      return reelDatas
end

function FiveDragonFeatureView:getRunSequence(endValue)
      local addNum = 0
      if endValue == 1 or endValue == 2 then
            addNum = 1
      elseif endValue == 3 or endValue == 4 or endValue == 5 or endValue== 6 then
            addNum = 5
      elseif endValue == 7 or endValue == 8 or endValue == 9  then
            addNum = 10
      elseif endValue== 10 then
            addNum = 14
      end

      local reelDatas = {}
      local totleCount = xcyy.SlotsUtil:getArc4Random() % OFF_RUN_COUNT + addNum
      for i=1,totleCount do
            local symbolType = nil
            local bLast = nil
            if i == totleCount then
                  symbolType = endValue
                  bLast = true
            else
                  local index = math.random(1 ,#self.m_signalTypeArray )
                  symbolType  = self.m_signalTypeArray[index] 
                  bLast = false
            end
            
            local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, symbolType, bLast)


            reelDatas[#reelDatas + 1] = reelData
      end
      return reelDatas
end

function FiveDragonFeatureView:initFiveDragonFeatureView()
      local function onNodeEvent(eventName)
            if "enter" == eventName then
                self:onEnter()
            elseif "exit" == eventName then
                self:onExit()
            end
        end
        self:registerScriptHandler(onNodeEvent)
end

--loadImgeToCache
function FiveDragonFeatureView:addTimeImageToCache()
      local frameCache = cc.SpriteFrameCache:getInstance()

      for i=1,TIME_IMAGE_COUNT do
            frameCache:addSpriteFrames("effect/FiveDragon_shuzi_".. i ..".png")
      end
end

--removeImgeFromCache
function FiveDragonFeatureView:removeTimeImageFromCache()
      local frameCache = cc.SpriteFrameCache:getInstance()

      for i=1,TIME_IMAGE_COUNT do
            frameCache:removeSpriteFrameByName("effect/FiveDragon_shuzi_".. i ..".png")
      end
end

function FiveDragonFeatureView:onEnter()
      self:addTimeImageToCache()
end
  
function FiveDragonFeatureView:onExit()    

      for i=1,#self.m_FeatureNode do
            local featureNode = self.m_FeatureNode[i]
            featureNode:stopAllActions()
            featureNode:removeFromParent()
      end
      self:removeTimeImageFromCache()
      self:unregisterScriptHandler()  -- 卸载掉注册事件

end

return FiveDragonFeatureView