local GoldenBrickView = class("GoldenBrickView",  cc.Node)

GoldenBrickView.slotMachine = nil
GoldenBrickView.m_FeatureNode = nil
GoldenBrickView.m_featureSpPool = nil
GoldenBrickView.m_featureNodeEndNum = nil
GoldenBrickView.m_featureOverCallBack = nil
GoldenBrickView.m_signalTypeArray = nil -- 配置小块type
GoldenBrickView.m_signalTypeIndex = nil -- 配置小块type
GoldenBrickView.m_musicRunAudioID = nil -- 存储的声音ID
GoldenBrickView.m_data = nil

local FeatureNode_Count = 0

local TIME_IMAGE_COUNT = 10

--配置滚动信息
local BASE_RNN_COUNT = 38
local OFF_RUN_COUNT = 3



function GoldenBrickView:ctor()
      self:initGoldenBrickView()
      self.m_FeatureNode = {}
      self.m_featureSpPool = {}
      self.m_featureNodeEndNum = 0
end

function GoldenBrickView:getFeatureSp(data)
      local csbName = "Socre_GoldenPig_shuzi.csb"
      if data.num == 20 then
            csbName = "Socre_GoldenPig_mini.csb"
      elseif data.num == 100 then
            csbName = "Socre_GoldenPig_minor.csb"
      elseif data.num == 1000 then
            csbName = "Socre_GoldenPig_major.csb"
      elseif data.num == 2000 then
            csbName = "Socre_GoldenPig_grand.csb"
      end
      local golden = util_csbCreate(csbName)
      if golden:getChildByName("m_lab_coin") ~= nil then
            local coinNum = data.num * globalData.slotRunData:getCurTotalBet()
            local labCoin = golden:getChildByName("m_lab_coin")
            labCoin:setString(util_formatCoins(coinNum, 3))
            if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
                  labCoin:setScale(0.45)
            elseif data.shape == "2x2" or data.shape == "2x3" then
                  labCoin:setScale(0.95)
            elseif data.shape == "3x2" or data.shape == "3x3" then
                  labCoin:setScale(1.28)
            elseif data.shape == "4x2" or data.shape == "5x2" then
                  labCoin:setScale(1.41)
            elseif data.shape == "4x3" or data.shape == "5x3" then
                  labCoin:setScale(1.75)
            end
      end

      if golden:getChildByName("Words") ~= nil then
            local labWords = golden:getChildByName("Words")
            if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
                  labWords:setScale(0.35)
            elseif data.shape == "2x2" or data.shape == "2x3" then
                  labWords:setScale(0.7)
            elseif data.shape == "3x2" or data.shape == "3x3" then
                  labWords:setScale(0.99)
            elseif data.shape == "4x2" or data.shape == "5x2" then
                  labWords:setScale(1.12)
            elseif data.shape == "4x3" or data.shape == "5x3" then
                  labWords:setScale(1.26)
            end
      end
      local bg = golden:getChildByName("BG")
      bg:setScaleX(data.width / bg:getContentSize().width)
      bg:setScaleY(data.height / bg:getContentSize().height)
      -- golden:retain()

      --设定最大显示长度
      if golden:getChildByName("m_lab_coin") ~= nil then
            local labCoin = golden:getChildByName("m_lab_coin")
            self:updateLabelSize({label=labCoin,sx=1,sy=1},bg:getBoundingBox().width * 0.8)
      end

      return golden 
end

function GoldenBrickView:setOverCallBackFun(callFunc)
     self.m_featureOverCallBack = callFunc
end

function GoldenBrickView:pushFeatureSp(golden)
      -- golden:release()
end

function GoldenBrickView:initFeatureUI(data,father)
      self.m_data = data
      self.m_signalTypeArray = data.vecBrick
      self.m_signalTypeIndex = math.random(1 ,#self.m_signalTypeArray )
      local pos = data.Pos
      local endValue = data.EndValue
      local runSequence = self:getRunSequence(data)
      local initReelData = self:getInitSequence(data)

      self.p_slotNodeH = data.height
      
      local featureNode = util_createView("CodeGoldenPigSrc.GoldenBrickNode", self.p_slotNodeH)
      self:addChild(featureNode)

      featureNode:init(data.width, data.height, function(data)
            return self:getFeatureSp(data)
      end, function(golden)
            return self:pushFeatureSp(golden)
      end)
      -- pos = self:convertToNodeSpace(pos)
      featureNode:setPosition(0, 0)

      featureNode:initFirstSymbolBySymbols(initReelData)
      featureNode:initRunDate(runSequence, function(  )
            return self:getRunReelData(data )
      end)
      featureNode:setEndCallBackFun(function(  )
            self:runEndCallBack()
      end)
      featureNode:setresDis(data.height * 0.5)
      
      if #featureNode.m_symbolNodeList > 0 then
            featureNode.m_symbolNodeList[#featureNode.m_symbolNodeList]:setVisible(false)
      end

      
      gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_DragonChange.mp3")
      
      if #featureNode.m_symbolNodeList > 0 then
            featureNode.m_symbolNodeList[#featureNode.m_symbolNodeList]:setVisible(true)
      end
      performWithDelay(featureNode,function( )
            featureNode:beginMove()
      end, 0.31)
      

     
      self.m_musicRunAudioID =  gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_LittleBit_Run.mp3")
      

end

function GoldenBrickView:runEndCallBack()
      if self.m_musicRunAudioID then -- 停止滚动音效
            gLobalSoundManager:stopAudio(self.m_musicRunAudioID) 
      end
      
      performWithDelay(self, function()
            if self.m_featureOverCallBack ~= nil then
                  self.m_featureOverCallBack()
            end
      end, 0)
      
end

function GoldenBrickView:getRunReelData( data )
      local newData = {}
      newData.width = data.width
      newData.height = data.height
      newData.shape = data.shape 
      newData.num = self.m_signalTypeArray[self.m_signalTypeIndex]
      self.m_signalTypeIndex = self.m_signalTypeIndex + 1
      if self.m_signalTypeIndex > #self.m_signalTypeArray then
            self.m_signalTypeIndex = 1
      end
      local reelData = self:getReelData(1,newData.width, newData.height, newData, false )
      return  reelData
end

function GoldenBrickView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function GoldenBrickView:getInitSequence(data)
      local reelDatas = {}

      local newData = {}
      newData.width = data.width
      newData.height = data.height
      newData.num = self.m_signalTypeArray[self.m_signalTypeIndex]
      newData.shape = data.shape 
      self.m_signalTypeIndex = self.m_signalTypeIndex + 1
      if self.m_signalTypeIndex > #self.m_signalTypeArray then
            self.m_signalTypeIndex = 1
      end

      reelDatas[#reelDatas + 1]  = self:getReelData(1, newData.width, newData.height, newData, false )
      return reelDatas
end

function GoldenBrickView:getRunSequence(data)

      local reelDatas = {}
     
      local reelData = self:getReelData(1,data.width, data.height, data, true)
      reelDatas[#reelDatas + 1] = reelData
      return reelDatas
end

function GoldenBrickView:initGoldenBrickView()
      local function onNodeEvent(eventName)
            if "enter" == eventName then
                self:onEnter()
            elseif "exit" == eventName then
                self:onExit()
            end
        end
        self:registerScriptHandler(onNodeEvent)
end


function GoldenBrickView:onEnter()

end
  
function GoldenBrickView:onExit()  
      self:unregisterScriptHandler()  -- 卸载掉注册事件
end

function GoldenBrickView:reset()

end

--调整label大小 info={label=cc.label,sx=1,sy=1} length=宽度限制 otherInfo={info1,info2,info3,...}
function GoldenBrickView:updateLabelSize(info, length, otherInfo)
    local _label = info.label
    if _label.mulNode then
        _label = _label.mulNode
    end
    local width = _label:getContentSize().width
    local scale = length / width
    if width <= length then
        scale = 1
    end

    _label:setScaleX(scale * (info.sx or 1))
    _label:setScaleY(scale * (info.sy or 1))
    if otherInfo and #otherInfo > 0 then
        for k, orInfo in ipairs(otherInfo) do
            orInfo.label:setScaleX(scale * (orInfo.sx or 1))
            orInfo.label:setScaleY(scale * (orInfo.sy or 1))
        end
    end
end

return GoldenBrickView