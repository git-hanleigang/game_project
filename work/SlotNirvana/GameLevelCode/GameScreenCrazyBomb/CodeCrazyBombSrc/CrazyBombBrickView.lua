local CrazyBombBrickView = class("CrazyBombBrickView",  cc.Node)

CrazyBombBrickView.slotMachine = nil
CrazyBombBrickView.m_FeatureNode = nil
CrazyBombBrickView.m_featureSpPool = nil
CrazyBombBrickView.m_featureNodeEndNum = nil
CrazyBombBrickView.m_featureOverCallBack = nil
CrazyBombBrickView.m_signalTypeArray = nil -- 配置小块type
CrazyBombBrickView.m_signalTypeIndex = nil -- 配置小块type
CrazyBombBrickView.m_musicRunAudioID = nil -- 存储的声音ID
CrazyBombBrickView.m_data = nil

local FeatureNode_Count = 0

local TIME_IMAGE_COUNT = 10

--配置滚动信息
local BASE_RNN_COUNT = 38
local OFF_RUN_COUNT = 3



function CrazyBombBrickView:ctor()
      self:initCrazyBombBrickView()
      self.m_FeatureNode = {}
      self.m_featureSpPool = {}
      self.m_featureNodeEndNum = 0
end

function CrazyBombBrickView:getFeatureSp(data)
      local csbName = "Socre_CrazyBomb_shuzi.csb"
      if data.num == 20 then
            csbName = "Socre_CrazyBomb_mini.csb"
      elseif data.num == 100 then
            csbName = "Socre_CrazyBomb_minor.csb"
      elseif data.num == 1000 then
            csbName = "Socre_CrazyBomb_major.csb"
      elseif data.num == 5000 then
            csbName = "Socre_CrazyBomb_grand.csb"
      end
      local golden = util_csbCreate(csbName)
      if golden:getChildByName("m_lab_coin") ~= nil then
            local coinNum = data.num * globalData.slotRunData:getCurTotalBet()
            local labCoin = golden:getChildByName("m_lab_coin")
            labCoin:setString(self:util_formatCoins(coinNum, 3))
            local size = labCoin:getContentSize()
            if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
                  labCoin:setScale(0.363)
            elseif data.shape == "2x2" or data.shape == "2x3" then
                    labCoin:setScale(0.836)
            elseif data.shape == "3x2" or data.shape == "3x3" then
                    labCoin:setScale(1.152)
            elseif data.shape == "4x2" or data.shape == "4x3" then
                    labCoin:setScale(1.375)
            elseif data.shape == "5x2" or data.shape == "5x3" then
                    labCoin:setScale(1.589)
            end
      end

      if golden:getChildByName("Words") ~= nil then
            local labWords = golden:getChildByName("Words")
            if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
                  labWords:setScale(0.35)
            elseif data.shape == "2x2" or data.shape == "2x3" then
                  labWords:setScale(0.787)
            elseif data.shape == "3x2" or data.shape == "3x3" then
                  labWords:setScale(1.319)
            elseif data.shape == "4x2" or data.shape == "5x2" then
                  labWords:setScale(1.617)
            elseif data.shape == "4x3" or data.shape == "5x3" then
                  labWords:setScale(1.841)
            end
      end
      local bg = golden:getChildByName("BG")
      bg:setScaleX(data.width / bg:getContentSize().width)
      bg:setScaleY(data.height / bg:getContentSize().height)
      golden:retain()
      return golden 
end

function CrazyBombBrickView:setOverCallBackFun(callFunc)
     self.m_featureOverCallBack = callFunc
end

function CrazyBombBrickView:pushFeatureSp(golden)
      golden:release()
end

function CrazyBombBrickView:initFeatureUI(data,father)
      self.m_data = data
      self.m_signalTypeArray = data.vecBrick
      self.m_signalTypeIndex = math.random(1 ,#self.m_signalTypeArray )
      local pos = data.Pos
      local endValue = data.EndValue
      local runSequence = self:getRunSequence(data)
      local initReelData = self:getInitSequence(data)

      self.p_slotNodeH = data.height
      
      local featureNode = util_createView("CodeCrazyBombSrc.CrazyBombBrickNode", self.p_slotNodeH)
      self:addChild(featureNode)

      featureNode:init(data,data.width, data.height, function(data)
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
      end, 0.05)
      

     
      self.m_musicRunAudioID =  gLobalSoundManager:playSound("FiveDragonSounds/music_FiveDragon_LittleBit_Run.mp3")
      

end

function CrazyBombBrickView:runEndCallBack()
      if self.m_musicRunAudioID then -- 停止滚动音效
            gLobalSoundManager:stopAudio(self.m_musicRunAudioID) 
      end
      
      performWithDelay(self, function()
            if self.m_featureOverCallBack ~= nil then
                  self.m_featureOverCallBack()
            end
      end, 0)
      
end

function CrazyBombBrickView:getRunReelData( data )
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

function CrazyBombBrickView:getReelData( zorder, width, height, symbolType, bLast )
      local reelData = util_require("data.slotsdata.SpecialReelData"):create()
      reelData.Zorder = zorder
      reelData.Width = width
      reelData.Height = height
      reelData.SymbolType = symbolType
      reelData.Last = bLast
      return reelData
end

function CrazyBombBrickView:getInitSequence(data)
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

function CrazyBombBrickView:getRunSequence(data)

      local reelDatas = {}
     
      local reelData = self:getReelData(1,data.width, data.height, data, true)
      reelDatas[#reelDatas + 1] = reelData
      return reelDatas
end

function CrazyBombBrickView:initCrazyBombBrickView()
      local function onNodeEvent(eventName)
            if "enter" == eventName then
                self:onEnter()
            elseif "exit" == eventName then
                self:onExit()
            end
        end
        self:registerScriptHandler(onNodeEvent)
end


function CrazyBombBrickView:onEnter()
      
end
  
function CrazyBombBrickView:onExit()    
      self:unregisterScriptHandler()  -- 卸载掉注册事件

end

function CrazyBombBrickView:reset()

end

-- util_formatCoins(数值,限制大小,是否添加分隔符','}
-- obligate:保留位数 限制大小  notCut=true（不添加分隔符','）
-- 向下取整0.99等于0
-- util_formatCoins(999999.99,2)      输出结果 = 0.9M    --限制2位数
-- util_formatCoins(999999.99,4)      输出结果 = 999.9K  --限制4位数
-- util_formatCoins(999999.99,6)      输出结果 = 999,999 --限制6位数
-- util_formatCoins(999999.99,6,true) 输出结果 = 999999  --不添加分隔符
-- util_formatCoins(999999.99,7)      输出结果 = 999,999 --限制7位数
function CrazyBombBrickView:util_formatCoins(coins, obligate, notCut, normal)
      local obK = math.pow(10, 3)
      if type(coins)~="number" then
          return coins
      end
      --不需要限制的直接返回
      if obligate < 1 then
          return coins
      end
  
      --是否添加分割符
      local isCut = true
      if notCut then
          isCut = false
      end
  
      local str_coins = nil
      coins = tonumber(coins + 0.00001)
      local nCoins = math.floor(coins)
      local count = math.floor(math.log10(nCoins)) + 1
      if count <= obligate then
          str_coins = util_cutCoins(nCoins, isCut)
      else
          if count < 3 then
              str_coins = util_cutCoins(nCoins / obK, isCut) .. "K"
          else
              local tCoins = nCoins
              local tNum = 0
              local units = { "K", "M", "B", "T" }
              local cell = 1000
              local index = 0
              while
                  (1)
              do
                  index = index + 1
                  if index > 4 then
                      return util_cutCoins(tCoins, isCut) .. units[4]
                  end
                  tNum = tCoins % cell
                  tCoins = tCoins / cell
                  local num = math.floor(math.log10(tCoins)) + 1
                  if num <= obligate then
                      --应该保留的小数位
                      local floatNum = obligate - num
                      if normal then
                          local changeNum = math.floor( tCoins *10 ) / 10 
                          return util_cutCoins(changeNum, isCut, floatNum) .. units[index]
                      end
                      local changeNum1 = tCoins
                      --保留1位小数
                      if num==1 and floatNum>0 then
                          floatNum = 1
                          changeNum1 = math.floor( tCoins *10 ) / 10 
                      else
                          --正常模式不保留小数
                          floatNum = 0
                          
                      end
                      return util_cutCoins(changeNum1, isCut, floatNum) .. units[index]
                  end
              end
          end
      end
      return str_coins
end

return CrazyBombBrickView