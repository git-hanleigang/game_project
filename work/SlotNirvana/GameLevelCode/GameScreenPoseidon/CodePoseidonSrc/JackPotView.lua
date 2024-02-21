local JackPotView = class("JackPotView", util_require("base.BaseView"))

JackPotView.m_FeatureNode = nil
JackPotView.m_featureSpPool = nil
JackPotView.m_featureNodeEndNum = nil
JackPotView.m_featureOverCallBack = nil
JackPotView.m_signalTypeArray = {101,102,103,104,105,106} -- 配置小块type {score, mini , minor , major, grand, peseidon}
JackPotView.m_musicRunAudioID = nil -- 存储的声音ID
JackPotView.m_getNodeByTypeFromPool= nil
JackPotView.m_pushNodeToPool = nil
JackPotView.m_bigPoseidon = nil
JackPotView.m_jpTime = nil
JackPotView.m_nowPlayJpTime = nil
JackPotView.m_jpDatas = nil
JackPotView.m_jpNode = nil
JackPotView.m_JpSymbolNode = nil
JackPotView.m_winSound = nil
JackPotView.m_bShowTip = nil

local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 309, height = 413}
local REEL_SYMBOL_COUNT = 7
--配置滚动信息
local BASE_RNN_COUNT = 3
local OFF_RUN_COUNT = 3
local JACKPOT_COUNT = 2

JackPotView.JackPotSoundBGId = nil -- jackPot背景音乐

JackPotView.m_runDataPoint  = nil
local RUNNING_DATA = {30,2,2000,5,3,10,8,1,30,2,8,100,1,5,10,15,500,1,5,3,1,100,2,5,8,10,3,15,5,1} 

-- 5000,500,100,30,10

function JackPotView:initUI()
      self.m_FeatureNode = {}
      self.m_featureSpPool = {}
      self.m_featureNodeEndNum = 0
      self.m_jpTime = 1
      self.m_nowPlayJpTime = 1
      self.m_runDataPoint = {}
      self.m_bShowTip = false

      local resourceFilename="Poseidon/BonusLunpan.csb"
      self:createCsbNode(resourceFilename)
      for i=1,JACKPOT_COUNT do
            self:initRuningPoint(i)
      end

      --gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_show_view.mp3",false,function(  )
            self.JackPotSoundBGId =   gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_yin.mp3",true)
      --end)

--      self:findChild("bigbg"):setScale(2.05)

end  

function JackPotView:initRuningPoint(num)
   self.m_runDataPoint[num] = xcyy.SlotsUtil:getArc4Random() % #RUNNING_DATA + 1
end

function JackPotView:setJpSymbolNode(jpNode)
      self.m_JpSymbolNode = jpNode
end

function JackPotView:getNextType(num)
      local jpType = nil
      local jpScore = nil
      if self.m_runDataPoint[num] > #RUNNING_DATA then
          self.m_runDataPoint[num] = 1
      end

      local type = RUNNING_DATA[self.m_runDataPoint[num]]

      jpScore = type 
      if type == 2000 then
            jpType = 106
      elseif type == 500 then
            jpType = 105
      elseif type == 100 then
            jpType = 104
      elseif type == 30 then
            jpType = 103
      elseif type == 10 then
            jpType = 102
      else
            jpType = 101
      end

      self.m_runDataPoint[num] = self.m_runDataPoint[num] + 1

      return jpType, jpScore
end

function JackPotView:addJpNode(machineNode)

      self.m_jpNode= util_createView("CodePoseidonSrc.PoseidonJackPotLayer", machineNode)
      self:findChild("top_node"):addChild(self.m_jpNode)
      self.m_jpNode:setPosition(cc.p(0,0))
      self.m_jpNode:updateJackpotInfo()
end

function JackPotView:setNodePoolFunc(getNodeFunc, pushNodeFunc)
      self.m_getNodeByTypeFromPool = getNodeFunc
      self.m_pushNodeToPool = pushNodeFunc
end

function JackPotView:initJpUI()
      self.m_bigPoseidon = self.m_getNodeByTypeFromPool(10006)
      self.m_bigPoseidon:runAnim("Poseidon_respin_poseidon", true)
      self:findChild("node_pesidon"):addChild(self.m_bigPoseidon )
      self.m_bigPoseidon:setPosition(cc.p(0,300))
      self.m_bigPoseidon:setVisible(false)
      self.m_bigPoseidon:setScale(0.6)
      
      if display.height < 1370 then
            self:findChild("node_pesidon"):setScale(0.8)
            self:findChild("Node_all"):setScale(0.8)
      end

      performWithDelay(self, function (  )
            release_print("JackPotView 112")
            self.m_bigPoseidon:setVisible(true)
            release_print("JackPotView 112 END")
      end, 0.5)


      -- local jpAnima1 = self.m_getNodeByTypeFromPool(10003)
      -- jpAnima1:setPosition(cc.p(0,0))
      -- self:findChild("jackPotNode1"):addChild(jpAnima1,2)
      -- jpAnima1:runAnim("idleframe", true)

      -- local jpAnima2 = self.m_getNodeByTypeFromPool(10003)
      -- jpAnima2:setPosition(cc.p(0,0))
      -- self:findChild("jackPotNode2"):addChild(jpAnima2,2)
      -- jpAnima2:runAnim("idleframe", true)

 end

function JackPotView:setSignalTypeArray(array)
     self.m_signalTypeArray = array
end

function JackPotView:setOverCallBackFun(callFunc)
      self.m_featureOverCallBack = callFunc
end

function JackPotView:jpRunTimes(jpTimes)
      self.m_jpTime = jpTimes
      if  self.m_jpTime > 1 then
            self.m_bShowTip  = true
      end
      self:setJpLabTip(self.m_jpTime)
end

function JackPotView:setJpLabTip(jpTimes)

      local tipLab = self:findChild("lab_tip")

      if jpTimes > 1 then

            tipLab:setString(jpTimes.." SPINS REMAINING")
      elseif jpTimes == 1 then
            if self.m_bShowTip == false then
                  tipLab:setString("")
            else
                  tipLab:setString("1 SPIN REMAINING")
            end
      else
            if self.m_bShowTip then
                  tipLab:setString("LAST SPIN")
            else
                  tipLab:setString("")

            end
      end
end

function JackPotView:initFeatureUI(datas)

      self.m_jpDatas = datas
      
      local data = datas[self.m_nowPlayJpTime]

      for i=1, JACKPOT_COUNT do
            local endValue = data[i]
            
            local jpNode = self:findChild("jackPotNode"..i)
            
            --jackpot 滚动序列
            local runSequence = self:getRunSequence(endValue, i)
            local initReelData = self:getInitSequence(i)

            local featureNode = util_createView("CodePoseidonSrc.JackPotNode", endValue, i)
            jpNode:addChild(featureNode)
            
            featureNode:init(TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height,
            self.m_getNodeByTypeFromPool,
            self.m_pushNodeToPool)

            local reelHeight = TIME_IAMGE_SIZE.height
            featureNode:initFirstSymbolBySymbols(initReelData, reelHeight)

            featureNode:initRunDate(runSequence, function( num )
                  return self:getRunReelData(num )
            end)
            featureNode:setEndCallBackFun(function(  )
                  self:runEndCallBack()
            end)

            self.m_FeatureNode[#self.m_FeatureNode + 1] = featureNode 

            performWithDelay(self, function(  )
                  release_print("JackPotView 193")
                  featureNode:beginMove()
                  release_print("JackPotView 193 END")
            end,  1 + i * 1)
 
            performWithDelay(self, function(  )
                  release_print("JackPotView 199")
                  self:setJpLabTip(self.m_jpTime - 1)
                  release_print("JackPotView 199 END")
            end, 2)
      end

end
 
function JackPotView:runFeatureNode(datas)


      for i=1,#self.m_FeatureNode do
            local endValue = datas[i]

            local featureNode = self.m_FeatureNode[i]
            local runSequence = self:getRunSequence(endValue, i)
            featureNode:initRunDate(runSequence, function( num )
                  return self:getRunReelData( num )
            end)
            performWithDelay(self, function(  )
                  release_print("JackPotView 219 ")
                  featureNode:initAction()
                  featureNode:beginMove()
                  release_print("JackPotView 219 END")
            end, 1 + i * 1)
      end
      performWithDelay(self, function(  )
            release_print("JackPotView 226")
            self:setJpLabTip(self.m_jpTime - 1)
            release_print("JackPotView 226 END")

      end, 2)    

end

function JackPotView:setWinCoin(winCoins)
      local jpWinsLab = self:findChild("lab_wins")
      jpWinsLab:setString(util_getFromatMoneyStr(winCoins))
      
      self:updateLabelSize({label=jpWinsLab,sx = 0.7,sy= 0.7}, 559)
                   
      -- local addValue=(winCoins)*0.05+math.random(1,9)+math.random(1,9)*10+math.random(1,9)*100
      -- local addBaseValue = winCoins / 40
      -- util_jumpNum(jpWinsLab,0,winCoins,addBaseValue,0.05,{90})

      --缩放
      local soundName = "PoseidonSounds/music_Poseidon_freespin_over_view.mp3"
      gLobalSoundManager:stopBgMusic()
      self.m_winSound = gLobalSoundManager:playSound(soundName,false)
end

function JackPotView:runEndCallBack()

      self.m_featureNodeEndNum = self.m_featureNodeEndNum + 1
      if self.m_featureNodeEndNum == JACKPOT_COUNT then
            
            if self.m_musicRunAudioID then -- 停止滚动音效
                  gLobalSoundManager:stopAudio(self.m_musicRunAudioID) 
            end

            local winCoins = 0

            local datas = self.m_jpDatas[self.m_nowPlayJpTime]
            for i=1,#datas do
                  local score = datas[i].score
                  local type = datas[i].type
                  winCoins = winCoins + score

                  if type == "mini" then
                        self.m_jpNode:playJpAnima("mini")
                  elseif type == "minor" then
                        self.m_jpNode:playJpAnima("minor")
                  elseif type == "major" then
                        self.m_jpNode:playJpAnima("major")
                  elseif type == "mega" then
                        self.m_jpNode:playJpAnima("mega")
                  elseif type == "grand" then
                        self.m_jpNode:playJpAnima("grand")
                  end
            end
           local symbolNode = self.m_JpSymbolNode[self.m_nowPlayJpTime]
      --      symbolNode:runAnim("idleframe1004_1")
            symbolNode:getCcbProperty("BitmapFontLabel_1"):setString(util_formatCoins(winCoins, 4))
           
            self:updateLabelSize({label= symbolNode:getCcbProperty("BitmapFontLabel_1"),sx=0.4,sy=0.4},210)
            
            self.m_jpTime = self.m_jpTime - 1
            self.m_nowPlayJpTime = self.m_nowPlayJpTime + 1
            self.m_featureNodeEndNum = 0

            for i=1,#self.m_FeatureNode do
                  self.m_FeatureNode[i]:playRunEndAnima()
            end
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_guochang_jackPot_num_hide.mp3")
      
            
            local jpWinsLab = self:findChild("lab_wins")
            jpWinsLab:setString("0")
            performWithDelay(self, function(  )
                  release_print("JackPotView 291")
                  self:setWinCoin(winCoins)

                  if self.JackPotSoundBGId then
                        gLobalSoundManager:stopAudio(self.JackPotSoundBGId) 
                        self.JackPotSoundBGId = nil
                  end

                  gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_show_view.mp3")
                 
                  self:runCsbAction("actionframe1",false, function()    
                        self.m_jpNode:clearAnimaNode()      
                        self.m_jpNode:runCsbAction("idleframe")
                        if self.m_jpTime == 0 then
      
                              performWithDelay(self, function()
                                    release_print("JackPotView 306")
                                    if self.m_featureOverCallBack ~= nil then
                                          self.m_featureOverCallBack()
                                    end

                                    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_guochang_flash.mp3")
                                    release_print("JackPotView 306 END")
                              end, 2)
                        else
                              performWithDelay(self, function()
                                    release_print("JackPotView 316")
                                    for i=1,#self.m_FeatureNode do
                                          self.m_FeatureNode[i]:playRunEndAnimaIde()
                                    end
                                    self:runCsbAction("idle",true)
                                    local endValue = self.m_jpDatas[self.m_nowPlayJpTime]
                                    self:runFeatureNode(endValue)
                                    release_print("JackPotView 316 END")
                                    
                                    self.JackPotSoundBGId =   gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_jackpot_yin.mp3",true)
                        end, 2)
                        end
                  end)
                  release_print("JackPotView 291 END")
            end,1.7)
  

      end
end

function JackPotView:getRunReelData(num)
      local type, score  = self:getNextType(num)
      local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height / REEL_SYMBOL_COUNT, type, false )
      reelData.jpScore =  score
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

function JackPotView:getInitSequence(num)
      local reelDatas = {}

      for i = 1,7 do 
      --    local index = math.random(1 ,#self.m_signalTypeArray )
         local type, score = self:getNextType(num) 
         local data = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height / REEL_SYMBOL_COUNT, type, false ) 
         data.jpScore =  score

         reelDatas[#reelDatas + 1]  = data
      end
      
      return reelDatas
end

function JackPotView:transSymbolData(endValue)
      local type = nil
      local score = nil

      if endValue.type == "normal" then
            type = 101
            score = endValue.multiple
      elseif endValue.type == "mini" then
            type = 102
            score = endValue.multiple
      elseif endValue.type == "minor" then
            type = 103
            score = endValue.multiple
      elseif endValue.type == "major" then
            type = 104
            score = endValue.multiple
      elseif endValue.type == "mega" then
            type = 105
            score = endValue.multiple
      elseif endValue.type == "grand" then
            type = 106
            score = endValue.multiple
      end

      return type, score
end

function JackPotView:getRunSequence(endValue, num)
      local reelDatas = {}
      local totleCount = BASE_RNN_COUNT + (num - 1) * 4
      local type , score = self:transSymbolData(endValue)
      print("type ".. type .. " score " .. score)
      for i=1, totleCount do

            local symbolType = nil
            
            local jpScore =  0
            local bLast = nil

            if i == totleCount then
                  symbolType = type
                  jpScore = score
                  bLast = true
            else
                  symbolType, jpScore = self:getNextType(num) 
                  bLast = false
            end

            if jpScore == 0 then
                  print("....")
            end
            
            local reelData = self:getReelData(1,TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height / REEL_SYMBOL_COUNT, symbolType, bLast)
            reelData.jpScore = jpScore

            reelDatas[#reelDatas + 1] = reelData
      end
      return reelDatas
end

function JackPotView:onEnter()

end
  
function JackPotView:onExit()    

      for i=1,#self.m_FeatureNode do
            local featureNode = self.m_FeatureNode[i]
            featureNode:stopAllActions()
            featureNode:removeFromParent()
      end

end


return JackPotView