local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local Sounds  = require "CodeThorsStrikeSrc.ThorsSounds"

local CodeGameScreenThorsStrikeMachine = class("CodeGameScreenThorsStrikeMachine", BaseNewReelMachine)
CodeGameScreenThorsStrikeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenThorsStrikeMachine.WILD_FEATURE_EFFECT = 99
CodeGameScreenThorsStrikeMachine.FREE_CHOOSE_FEATURE_EFFECT = 98

CodeGameScreenThorsStrikeMachine.symbol_wild2 = 93  --x2
CodeGameScreenThorsStrikeMachine.symbol_wild3 = 94  --闪电



function CodeGameScreenThorsStrikeMachine:ctor()
  CodeGameScreenThorsStrikeMachine.super.ctor(self)

  self.m_isFeatureOverBigWinInFree = true
  self.m_spinRestMusicBG = true
  self.m_rollShadeFlag = false
  self.m_clipNode = {}
  self.m_allscatters = {}
  self.m_allwilds = {}
  self.m_bQuickStop = false
  self.m_bFreeChoose = false
  self.m_isReconnect = false
  self.m_firstEnter = true
  self.m_nFreeChooseIdx = 0
  self.m_bwildfreature = false
  self.m_wildfreatureTriggercount = 0
  self.m_wildfreatureSoundIndex = -1
  self.m_scatterSpeedCols = {0,0,0,0,0,0}
  self.m_wildSpeedCols = {0,0,0,0,0,0}
  self.m_wildreelRunAnimations = {}
  self.m_wildscatterReelRunAnis = {}
  self.isScatterQuickStopSound = true
  self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
  self.m_isFeatureOverBigWinInFree = true
  
  self:initGame()
end

function CodeGameScreenThorsStrikeMachine:initGame()
  self.m_configData = gLobalResManager:getCSVLevelConfigData("ThorsStrikeConfig.csv", "LevelThorsStrikeConfig.lua")
  self:initMachine(self.m_moduleName)
end

function CodeGameScreenThorsStrikeMachine:getModuleName()
  return "ThorsStrike"
end

function CodeGameScreenThorsStrikeMachine:getBaseReelGridNode()
  return "CodeThorsStrikeSrc.ThorsStrikeSlotNode"
end

function CodeGameScreenThorsStrikeMachine:initUI()
  self:initFreeSpinBar()
  self:changeBaseGameUI()
  self:findChild("mask"):hide()
  self:findChild("mask"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
  self:findChild("mask"):setOpacity(200)

  self:setReelRunSound(Sounds.quickRun.sound)

  self.m_trransitionEffect = GD.util_spineCreate('Thor_guochang',true,true):hide()
  self:findChild('root'):addChild(self.m_trransitionEffect)

  self.m_baseTransitionFree = GD.util_spineCreate('zhuanchang_FG',true,true):hide()
  self:addChild(self.m_baseTransitionFree,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
  self.m_baseTransitionFree:setPosition(display.center)

  self.m_freeYugaoEffect = GD.util_createAnimation("ThorsStrike_yugao.csb"):hide()
  self:findChild("root"):addChild(self.m_freeYugaoEffect)

  self.m_guochangDark = GD.util_createAnimation("ThorsStrike_guochang_dark.csb"):hide()
  self:findChild('Node_dark'):addChild(self.m_guochangDark)

  --for i = 2, 6 do
  --  local reelEffectNode, effectAct = GD.util_csbCreate('WinFrameThorsStrike_run3.csb')
  --  self.m_slotEffectLayer:addChild(reelEffectNode)
  --  local worldPos, reelHeight, reelWidth = self:getReelPos(i)
  --  local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
  --  reelEffectNode:setPosition(cc.p(pos.x, pos.y))
  --  reelEffectNode:hide()
  --  self.m_wildreelRunAnimations[i] = {reelEffectNode, effectAct}
  --end

  --for i = 2, 6 do
  --  local reelEffectNode, effectAct = GD.util_csbCreate('WinFrameThorsStrike_run2.csb')
  --  self.m_slotEffectLayer:addChild(reelEffectNode)
  --  local worldPos, reelHeight, reelWidth = self:getReelPos(i)
  --  local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
  --  reelEffectNode:setPosition(cc.p(pos.x, pos.y))
  --  reelEffectNode:hide()
  --  self.m_wildscatterReelRunAnis[i] = {reelEffectNode, effectAct}
  --end

  -- self.m_pKuosanDi = GD.util_createAnimation('ThorsStrike_kuosan_di.csb'):hide()
  -- self:findChild('wildfeature'):addChild(self.pNodekuosan)

  self.pNodekuosan = GD.util_createAnimation('ThorsStrike_kuosan.csb'):hide()
  self:findChild('root'):addChild(self.pNodekuosan,1000)

  self.m_pNodeShanDian = GD.util_createAnimation('ThorsStrike_kuosan_pidian.csb'):hide()
  self:findChild('root'):addChild(self.m_pNodeShanDian)

  self.m_freeChooseview = GD.util_createView("CodeThorsStrikeSrc.ThorsStrikeFreeChooseView",{machine = self})
  self.m_freeChooseview:hide()
  self.m_freeChooseview:setPosition(-display.cx, -display.cy)
  self:findChild("root"):addChild(self.m_freeChooseview)

  --大赢
  self.m_bigWinSpine = util_spineCreate("ThorsStrike_bigwin",true,true)
  self:findChild("Node_bigwin"):addChild(self.m_bigWinSpine)
  self.m_bigWinSpine:setVisible(false)
  
  self:addColorLayer()
end

function CodeGameScreenThorsStrikeMachine:addColorLayer()
  self.m_colorLayers = {}
  for i = 1, self.m_iReelColumnNum do
    local parentData = self.m_slotParents[i]
    local mask = cc.LayerColor:create(cc.c3b(0,0,0), parentData.reelWidth, parentData.reelHeight):hide()
    mask:setOpacity(200)
    mask:setPositionX(parentData.reelWidth / 2)
    parentData.slotParent:addChild(mask, GD.REEL_SYMBOL_ORDER.REEL_ORDER_1 + 100)
    self.m_colorLayers[i] = mask
  end
end
function CodeGameScreenThorsStrikeMachine:showColorLayer(bfade)
  for i,v in ipairs(self.m_colorLayers) do
    v:show()
    if bfade then
      v:setOpacity(0)
      v:runAction(cc.FadeTo:create(0.3, 200))
    else   v:setOpacity(200)
    end
  end
end
function CodeGameScreenThorsStrikeMachine:hideColorLayer(bfade)
  for i,v in ipairs(self.m_colorLayers) do
    if bfade then
      v:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,0),cc.CallFunc:create(function(p)
        p:hide()
      end)))
    else v:setOpacity(0) v:hide()
    end
  end
end
function CodeGameScreenThorsStrikeMachine:reelStopHideMask(actionTime, col)
  local maskNode = self.m_colorLayers[col]
  local fadeAct = cc.FadeTo:create(actionTime, 0)
  local func = cc.CallFunc:create( function()
    maskNode:setVisible(false)
  end)
  maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

function CodeGameScreenThorsStrikeMachine:getBounsScatterDataZorder(symbolType )
  if symbolType == GD.TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
    return GD.REEL_SYMBOL_ORDER.REEL_ORDER_2 - 1
  end
  return BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType )
end

function CodeGameScreenThorsStrikeMachine:showFreeChooseView(scatterCount)
  gLobalSoundManager:playSound(Sounds.freeChoose.sound)
  self.m_freeChooseview:openViewAnimation(scatterCount)
end

function CodeGameScreenThorsStrikeMachine:hideAllReelRunEffect()
  --for i=2,6 do
  --  self.m_wildreelRunAnimations[i][1]:hide()
  --  self.m_wildscatterReelRunAnis[i][1]:hide()
  --end
end


function CodeGameScreenThorsStrikeMachine:initFreeSpinBar()
  self.m_baseFreeSpinBar = GD.util_createView("CodeThorsStrikeSrc.ThorsStrikeFreespinBarView")
  self:findChild("Node_freespinbar"):addChild(self.m_baseFreeSpinBar)
  GD.util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenThorsStrikeMachine:enterGamePlayMusic(  )
  scheduler.performWithDelayGlobal(function(  )
    gLobalSoundManager:playSound(Sounds.enter.sound)
  end,0.4,self:getModuleName())
end

function CodeGameScreenThorsStrikeMachine:onEnter()
  if gLobalViewManager:isViewPause() then
    return
  end
  CodeGameScreenThorsStrikeMachine.super.onEnter(self)
  self:addObservers()
  self:runCsbAction("show",false)
  self.m_mapwords = {}
  self.m_wildYGnode = {}
  for x = 1, 6 do
    self.m_mapwords[x] = {}
    self.m_wildYGnode[x] = {}
    for y = 1, 5 do
      local node = self:getFixSymbol(x,y, SYMBOL_NODE_TAG)
      self.m_mapwords[x][y] = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    end
  end
end

function CodeGameScreenThorsStrikeMachine:addObservers()
    CodeGameScreenThorsStrikeMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
            if self.m_bIsBigWin then
              return 
            end
        end 
        --赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end
        local soundName = "ThorsStrikeSounds/sound_FortuneFuwa_last_win_".. soundIndex .. ".mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
          soundName = "ThorsStrikeSounds/sound_FortuneFuwa_fs_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenThorsStrikeMachine:onExit()
  if gLobalViewManager:isViewPause() then
    return
  end
  CodeGameScreenThorsStrikeMachine.super.onExit(self)
  self:removeObservers()
  scheduler.unschedulesByTargetName(self:getModuleName())
  if DEBUG == 2 then
    local list = {
      "CodeThorsStrikeSrc.ThorsStrikeSlotNode",
      "CodeThorsStrikeSrc.ThorsStrikeFreeChooseView",
      "CodeThorsStrikeSrc.ThorsStrikeJackPotBarView",
      "CodeGameScreenThorsStrikeMachine",
    }
    for i=1, #list do
      package.loaded[list[i]] = nil
    end
  end
end

function CodeGameScreenThorsStrikeMachine:MachineRule_GetSelfCCBName(symbolType)
  if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
    return "Socre_ThorsStrike_Wild"
  elseif symbolType == CodeGameScreenThorsStrikeMachine.symbol_wild3 then
    return "Socre_ThorsStrike_Wild_2"
  end
  return nil
end

function CodeGameScreenThorsStrikeMachine:getPreLoadSlotNodes()
  local loadNode = CodeGameScreenThorsStrikeMachine.super.getPreLoadSlotNodes(self)
  return loadNode
end

function CodeGameScreenThorsStrikeMachine:changeFreeGameUI()
  self.m_baseFreeSpinBar:show()
  self.m_baseFreeSpinBar:changeFreeSpinByCount()
  self:findChild('reel_base'):hide()
  self:findChild('reel_free'):show()
  --self:findChild("Node_idletx"):show()
  self.m_gameBg:runCsbAction('free',true)
  self:runCsbAction('idleframe',true)
end
function CodeGameScreenThorsStrikeMachine:changeBaseGameUI()
  self.m_baseFreeSpinBar:hide()
  self:findChild('reel_base'):show()
  self:findChild('reel_free'):hide()
  --self:findChild("Node_idletx"):hide()
  self.m_gameBg:runCsbAction('normal',true)
  self:runCsbAction('idleframe1',true)
end
function CodeGameScreenThorsStrikeMachine:playSceneShake()
  local action = 'idleframe1'
  local shake = 'actionframe1' --base
  if self:getCurrSpinMode() == FREE_SPIN_MODE then
    action = 'idleframe'
    shake = 'actionframe'
  end
  self:runCsbAction(shake,false,function()
    self:runCsbAction(action,true)
  end)
end

--播放Free过场动画
function CodeGameScreenThorsStrikeMachine:freeTransitionEffect(callBackFunc)
  self:findChild('Node_1'):show()
  self:findChild('Node_reel'):show()
  self:changeFreeGameUI()
end
--雷神出现过场
function CodeGameScreenThorsStrikeMachine:showThorsTransition(callBackFunc)
  gLobalSoundManager:playSound(Sounds.freeChangeBase.sound)
  self.m_trransitionEffect:show()
  self.m_guochangDark:show()
  self.m_guochangDark:runCsbAction('actionframe',false)
  GD.util_spinePlay(self.m_trransitionEffect,'actionframe',false)
  GD.util_spineEndCallFunc(self.m_trransitionEffect, 'actionframe',function()
    self.m_trransitionEffect:hide()
    if callBackFunc then callBackFunc() end
  end)
  self.m_trransitionEffect:registerSpineEventHandler(function(ev)
    if(ev.eventData.name == 'qiehuan')then
      self:changeBaseGameUI()
    end
  end,sp.EventType.ANIMATION_EVENT)
end

--Base切换到Free 选择过场动画
function CodeGameScreenThorsStrikeMachine:baseChangeToFreeChooseEffect(callBackFunc)
  gLobalSoundManager:playSound(Sounds.freeGuoChang.sound)
  self.m_baseTransitionFree:show()
  GD.util_spinePlay(self.m_baseTransitionFree,"actionframe", false)
  GD.util_spineEndCallFunc(self.m_baseTransitionFree, "actionframe", function ()
    if callBackFunc then callBackFunc() end
    self.m_baseTransitionFree:hide()
  end)
  self.m_baseTransitionFree:registerSpineEventHandler(function(ev)
   if(ev.eventData.name == 'qiehuan')then
     self:findChild('Node_1'):hide()
     self:findChild('Node_reel'):hide()
     self.m_freeChooseview:showChooseBG()
     self:showFreeChooseView(self.m_runSpinResultData.p_fsExtraData.freeLeavel)
   end
  end,sp.EventType.ANIMATION_EVENT)
end

function CodeGameScreenThorsStrikeMachine:shakeNode()
  local changePosY = 16
  local changePosX = 8
  local actions = {}
  local oldPos = cc.p(self:findChild("root"):getPosition())
  for i=1,9 do
    actions[#actions + 1] = cc.MoveTo:create(1/30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
    actions[#actions + 1] = cc.MoveTo:create(1/30, cc.p(oldPos.x, oldPos.y))
    actions[#actions + 1] = cc.MoveTo:create(1/30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
    actions[#actions + 1] = cc.MoveTo:create(1/30, cc.p(oldPos.x, oldPos.y))
    actions[#actions + 1] = cc.MoveTo:create(1/30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
    actions[#actions + 1] = cc.MoveTo:create(1/30, cc.p(oldPos.x, oldPos.y))
  end
  self:findChild("root"):runAction(cc.Sequence:create(actions))
end
--free预告动画
function CodeGameScreenThorsStrikeMachine:playYuGaoEffect( callback )
  gLobalSoundManager:playSound(Sounds.freeYuGao.sound)
  self.m_freeYugaoEffect:show()
  self.m_freeYugaoEffect:runCsbAction("yugao",false, function()
    self.m_freeYugaoEffect:hide()
    if callback then callback() end
  end)
  performWithDelay(self,function()self:shakeNode()end,0.25)
end
--wild预告动画
function CodeGameScreenThorsStrikeMachine:wildYuGaoEffect(spindata)
  gLobalSoundManager:playSound(Sounds.wildFreatureYuGao.sound)
  self:findChild("mask"):show()
  self:hideColorLayer(false)
  local reels = spindata.result.reels
  local wilds = {}
  --for i = 1,4 do
  --  local x,y = math.random(1,6),math.random(1,4)
  --  local p = self:getFixSymbol(x,y, SYMBOL_NODE_TAG)
  --  table.insert(wilds,{p=p,p1 = cc.p(x, y),btrue = false})
  --end
  local array = {}
  for x = 1, 6 do
    for y = 1, 5 do
      if(reels[y][x] == 92)then
        local p = self:getFixSymbol(x, 5-y+1, SYMBOL_NODE_TAG)
        if(p)then
          table.insert(array,{p=p,p1 = cc.p(x, 5-y+1),  btrue = true})
        end
      end
    end
  end
  local tmp, index
  for i=1, #array-1 do
    index = math.random(i, #array)
    if i ~= index then
      tmp = array[index]
      array[index] = array[i]
      array[i] = tmp
    end
  end
  for i=1,#array do
    table.insert(wilds,array[i])
  end
  local dely = 0
  for i=1,#wilds do
    local node = wilds[i].p
    local n,list = 0,{}
    n=n+1 list[n] = cc.DelayTime:create(dely)
    n=n+1 list[n] = cc.CallFunc:create(function(p)
      self:addWildYuGaoAnim( wilds[i])
    end)
    dely = dely + 0.3
    node:runAction(cc.Sequence:create(list))
  end
  --local dely = 2.3
  --self.m_freeYugaoEffect:show()
  --self.m_freeYugaoEffect:runCsbAction("yugao",false, function()
  --  self.m_freeYugaoEffect:hide()
  --end)
  --performWithDelay(self,function()
  --  local de = 0
  --  for i=1,#wilds do
  --    local node = wilds[i].p
  --    local n,list = 0,{}
  --    n=n+1 list[n] = cc.DelayTime:create(de)
  --    n=n+1 list[n] = cc.CallFunc:create(function(p)
  --      self:addWildYuGaoAnim( wilds[i])
  --    end)
  --    de = de + 0.3
  --    node:runAction(cc.Sequence:create(list))
  --  end
  --end,2.3)
  --return dely + (#wilds * 0.3) + 0.5

  return dely + 0.5
end

function CodeGameScreenThorsStrikeMachine:addWildYuGaoAnim(data)
  local node = data.p
  local parent = self:findChild('sp_reel')
  local parentData = self.m_slotParents[data.p1.x]
  local wyugao = GD.util_createAnimation('ThorsStrike_wild_yugao.csb'):show()
  parent:addChild(wyugao,1805)
  --parent:addChild(wyugao)
  --wyugao:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10)
  --print("x_y:",node.p_cloumnIndex,node.p_rowIndex)
  --local wos =  node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
  local wos = self.m_mapwords[data.p1.x][data.p1.y]
  wos = parent:convertToNodeSpace(wos)
  wyugao:setPosition(wos)
  local animationkey = 'actionframe1'
  local wg = nil
  if(data.btrue)then
    animationkey = 'actionframe'
    print('几次_',data.p1.x,data.p1.y)
    wg = GD.util_createAnimation('ThorsStrike_wild_g.csb'):hide()
    parent:addChild(wg,1800)
    --parentData.slotParent:addChild(wg,1800)
    --wos = parentData.slotParent:convertToNodeSpace(self.m_mapwords[data.p1.x][data.p1.y])
    wg:setPosition(wos)
    performWithDelay(wg,function()
      wg:show()
      wg:runCsbAction('start',false,function()
        wg:runCsbAction('idle',true)
      end)
      self.m_wildYGnode[data.p1.x][data.p1.y] = wg
    end,0.1)
  end
  wyugao:runCsbAction(animationkey,false,function()
    wyugao:removeSelf()
  end)
end


function CodeGameScreenThorsStrikeMachine:addTuoweiParticle(node)
  --local tuoWei = node:getChildByName("tuowei")
  local tuoWei = GD.util_spineCreate("Socre_ThorsStrike_Wild_tuowei",false,true)
  node:addChild(tuoWei)
  tuoWei:setName("tuowei")
  GD.util_spinePlay(tuoWei,'idleframe4',true)
end


----------------------------- 玩法处理 ----------------------------------
--场景恢复
function CodeGameScreenThorsStrikeMachine:MachineRule_initGame(  )
  dump(self.m_runSpinResultData)
  self.m_isReconnect = true
  --self.m_runSpinResultData.p_fsExtraData.freeLeavel
  if(self.m_runSpinResultData and self.m_runSpinResultData.p_features)then
    if(self.m_runSpinResultData.p_features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER)then
      print('!!!!!')
    end
    
    if(self.m_runSpinResultData.p_freeSpinsLeftCount > 0)then
      print('======开 始 过 了!!')
      if(self:getCurrSpinMode() == FREE_SPIN_MODE)then
        self:changeFreeGameUI()
        self.m_configData:setFsModel(self.m_runSpinResultData.p_fsExtraData.select)
      end
    end
  end
end

function CodeGameScreenThorsStrikeMachine:spinResultCallFun(param)
  CodeGameScreenThorsStrikeMachine.super.spinResultCallFun(self, param)
  if(self.m_bFreeChoose)then
    if param and param[1] then
      local spinData = param[2]
      if(spinData.action == 'FEATURE')then
        self.m_bFreeChoose = false
        print('....feature')
        globalData.slotRunData.freeSpinCount = spinData.result.freespin.freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = spinData.result.freespin.freeSpinsTotalCount
        self.m_iFreeSpinTimes = spinData.result.freespin.freeSpinsTotalCount
        self.m_freeChooseview:changeFreeEffect()
        self.m_configData:setFsModel(self.m_nFreeChooseIdx)
      end
    end
  end
end

function CodeGameScreenThorsStrikeMachine:enterFree()
  self:showFreeSpinView()
end

function CodeGameScreenThorsStrikeMachine:slotOneReelDown(col)
  CodeGameScreenThorsStrikeMachine.super.slotOneReelDown(self,col)
  local reelRunData = self.m_reelRunInfo[col]
  local isTriggerLongRun = reelRunData:getNextReelLongRun()
  local sound = {scatter = 0,h5 = 0,wild = 0}
  for row = 1,self.m_iReelRowNum do
    local p = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
    if(p)then
      if(p.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD)then
        table.insert(self.m_allwilds, p)
        self:setSymbolToClip(p)
        sound.wild = self:playWildAnim(p,col)
        if(self.m_wildYGnode[col][row])then
          self.m_wildYGnode[col][row]:runCsbAction('over',false,function()
            self.m_wildYGnode[col][row]:removeSelf()
            self.m_wildYGnode[col][row] = nil
          end)
        end
      end
      if(p.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)then
        p:setLineAnimName('actionframe')
        p:setIdleAnimName('idleframe2')
        p:runAnim("idleframe2",true)
      elseif(self.m_ScatterShowCol == nil and p.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER)then
        p:runAnim('buling',false)
        sound.scatter = 1
      elseif(p.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER)then
        p:runAnim("idleframe",true)
      end
    end
  end
  if col == 6 then
    self:hideColorLayer(true)
    self:hideAllReelRunEffect()
    for i,v in ipairs(self.m_allscatters) do
      if(v.m_currAnimName~='idleframe')then
        v:runAnim("idleframe",true)
      end
    end
  end
  local fixSp = self:getFixSymbol(col,6,SYMBOL_NODE_TAG)
  if(fixSp and fixSp.m_particle)then
    fixSp.m_particle:hide()
  end
  if sound.wild == 1 then
    -- self:playBulingSound(col,"wild",Sounds.wildbuling.sound)
    self:playBulingSymbolSounds(col,Sounds.wildbuling.sound)
  end
  if(self.m_ScatterShowCol == nil and sound.scatter == 1)then
    -- self:playBulingSound(col,"scatter",Sounds.scatterBuing.sound)
    self:playBulingSymbolSounds(col,Sounds.scatterBuing.sound)
  end
end
function CodeGameScreenThorsStrikeMachine:playWildAnim(p,col)
  local tag = 0
  if(self.m_ScatterShowCol == nil)then
    --sc预告中...
    p:runAnim("idleframe2",true) --idle
  else
    if(col<6)then
      tag = 1
      p:runAnim('buling',false,function()
        p:runAnim("idleframe2",true)
      end)
    else
      local b = false
      for i=1,5 do
        if self.m_wildSpeedCols[i] > 0 then
          b = true break
        end
      end
      if(b)then
        tag = 1
        p:runAnim('buling',false,function()
          p:runAnim("idleframe2",true)
        end)
      else
        p:runAnim("idleframe2",true)
      end
    end
  end
  return tag
end

function CodeGameScreenThorsStrikeMachine:updateReelGridNode(node)
  if self.m_firstEnter or node:isLastSymbol() then return end
  local symbolType = node.p_symbolType
  if symbolType == GD.TAG_SYMBOL_TYPE.SYMBOL_WILD then
    --self:addTuoweiParticle(node)
    node:runAnim('idleframe4',true)
    node:addTuoweiParticle(self.m_slotParents[node.p_cloumnIndex].slotParent)
  end
  --if(symbolType == 92)then
  --  node:runAnim('idleframe',false)
  --end
end

function CodeGameScreenThorsStrikeMachine:quicklyStopReel(colIndex)
  self.super.quicklyStopReel(self, colIndex)
  self.m_bQuickStop = true
end
--新快停逻辑
function CodeGameScreenThorsStrikeMachine:newQuickStopReel(index)
  CodeGameScreenThorsStrikeMachine.super.newQuickStopReel(self, index)
  for col = 1, self.m_iReelColumnNum do
    local symbolNodeList, start, over = self.m_reels[col].m_gridList:getList()
    for i = start, over do
      local symbolNode = symbolNodeList[i]
      if symbolNode.m_particle then
        symbolNode:remove()
        -- symbolNode.m_particle:setVisible(false)
      end
    end
  end
end

function CodeGameScreenThorsStrikeMachine:playReelDownTipNode(slotNode)
  self:playScatterBonusSound(slotNode)
  local reelCol = slotNode.p_cloumnIndex
  -- self:playBulingSound(reelCol,"scatter",Sounds.scatterBuing.sound)
  -- self:playBulingSymbolSounds(reelCol,Sounds.scatterBuing.sound)
  local isTriggerLongRun = self:setReelLongRun(reelCol)
  local isNextLong = self:getNextReelIsLongRun(reelCol + 1)
  self:playQuickStopBulingScatterSound()
  slotNode:runAnim("buling", false, function()
    if reelCol+1 <= 6 and (self.m_scatterSpeedCols[reelCol+1]>0) and self.m_bQuickStop ~= true then
      slotNode:runAnim("idleframe1", true)
      for i,v in ipairs(self.m_allscatters) do
        if(v.m_currAnimName~='idleframe1')then
          v:runAnim("idleframe1",true)
        end
      end
    else
      slotNode:runAnim("idleframe", true)
    end
  end)
  table.insert(self.m_allscatters, slotNode)
  self:specialSymbolActionTreatment( slotNode)
end

function CodeGameScreenThorsStrikeMachine:levelFreeSpinEffectChange()
  --self:changeFreeGameUI()
end

function CodeGameScreenThorsStrikeMachine:levelFreeSpinOverChangeEffect()
  --self:changeBaseGameUI()
end

function CodeGameScreenThorsStrikeMachine:showFreeSpinView(effectData)
  local showFSView = function ( ... )
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
      self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
        effectData.p_isPlay = true
        self:playGameEffect()
      end,true)
    else
      gLobalSoundManager:playSound(Sounds.freeShowWd.sound)
      local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
          self:triggerFreeSpinCallFun()
          if effectData then
            effectData.p_isPlay = true
          end
          self:playGameEffect()
      end)
      view.m_btnTouchSound = Sounds.freeClick.sound
      view:findChild('Wild_0'):setVisible(self.m_nFreeChooseIdx == 0)
      view:findChild('Wild_1'):setVisible(self.m_nFreeChooseIdx == 1)
      view:findChild('Wild_2'):setVisible(self.m_nFreeChooseIdx == 2)
      view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(Sounds.freeStarWdClose.sound)
      end)
    end
  end
  performWithDelay(self,function()
    showFSView()
  end,0.5)
end

function CodeGameScreenThorsStrikeMachine:showFreeSpinOverView()
  gLobalSoundManager:playSound(Sounds.freeOverShowWd.sound)
  local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
  local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,
  function()
    self:showThorsTransition(function()
      self:triggerFreeSpinOverCallFun()
    end)
  end)
  local node=view:findChild("m_lb_coins")
  view:updateLabelSize({label=node,sx=1.01,sy=1.01},612)
  view.m_btnTouchSound = Sounds.freeOverClick.sound
  view:setBtnClickFunc(function()
    gLobalSoundManager:playSound(Sounds.freeOverWdClose.sound)
  end)
end

function CodeGameScreenThorsStrikeMachine:showBonusGameView(effect)
  self:scatterTriggerEffect(
    function()
      self:baseChangeToFreeChooseEffect(
        function()
          --self:showFreeChooseView(self.m_runSpinResultData.p_fsExtraData.freeLeavel)
          effect.p_isPlay = true
        end
      )
    end
  )
end

function CodeGameScreenThorsStrikeMachine:scatterTriggerEffect( callBackFunc)
  local sys = {}
  for x=1,6 do
    for y=1,5 do
      local p = self:getFixSymbol(x,y,SYMBOL_NODE_TAG)
      if(p.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER)then
        table.insert(sys, p)
      end
    end
  end
  performWithDelay(self,function()
    for i,v in ipairs(sys) do
      v:runAnim('actionframe',false,function()
        v:runAnim("idleframe",true)
        if(i == #sys)then
          performWithDelay(self,callBackFunc,0.5)
        end
      end)
    end
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(Sounds.scatterMusic.sound)
  end,0.5)
end

function CodeGameScreenThorsStrikeMachine:setSymbolToClip(slotNode)
  for i,p in ipairs(self.m_clipNode) do
    if(p == slotNode)then
      return false
    end
  end
  local nodeParent = slotNode:getParent()
  slotNode.m_preParent = nodeParent
  slotNode.m_showOrder = slotNode:getLocalZOrder()
  slotNode.m_preX = slotNode:getPositionX()
  slotNode.m_preY = slotNode:getPositionY()
  slotNode.m_preLayerTag = slotNode.p_layerTag
  local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
  pos = self.m_clipParent:convertToNodeSpace(pos)
  slotNode:setPosition(pos.x, pos.y)
  slotNode:removeFromParent()
  -- 切换图层
  slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
  self.m_clipParent:addChild(slotNode, self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)
  self.m_clipNode[#self.m_clipNode + 1] = slotNode
  local linePos = {}
  linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
  slotNode:setLinePos(linePos)
end

function CodeGameScreenThorsStrikeMachine:setSymbolToReel()
  for i, slotNode in ipairs(self.m_clipNode) do
    local preParent = slotNode.m_preParent
    if preParent ~= nil then
      slotNode.p_layerTag = slotNode.m_preLayerTag
      local nZOrder = slotNode.m_showOrder
      nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder
      util_changeNodeParent(preParent, slotNode, nZOrder)
      slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
      slotNode:runIdleAnim()
    end
  end
  self.m_clipNode = {}
end

function CodeGameScreenThorsStrikeMachine:checkQuickReelEffect(spindata)
  self.m_scatterSpeedCols= {0,0,0,0,0,0}
  self.m_wildSpeedCols = {0,0,0,0,0,0}
  local reels = spindata.result.reels
  local funcOne = function( i_Type )
    local scatters = {0,0,0,0,0,0}
    local num = 0
    for x = 1, 6 do
      num = 0
      for y = 1, 5 do
        if(reels[y][x] == i_Type)then
          num = num + 1
        end
      end
      if(num > 0)then scatters[x] = num end
    end
    return scatters
  end
  local scatters = funcOne(90)
  local wilds    = funcOne(92)
  local snum,wnum = 0,0
  for i=2,6 do
    snum = scatters[i - 1] + snum
    wnum = wilds[i - 1] + wnum
    if(snum > 1)then self.m_scatterSpeedCols[i] = 1 end
    if(wnum > 0)then self.m_wildSpeedCols[i] = 1 end
  end
  print(self.m_scatterSpeedCols, 'scatter加速列')
  print(self.m_wildSpeedCols, 'wild加速列')
end

function CodeGameScreenThorsStrikeMachine:findThors(array, _x)
  local miny,maxy = 0,0
  local list = {}
  for i,v in ipairs(array) do
    if(v == GD.TAG_SYMBOL_TYPE.SYMBOL_WILD)then
      if(miny ==0)then
        miny = i
        table.insert(list, {x=_x, y = i})
      end
      if(i > maxy)then
        maxy = i
      end
    end
  end
  if(maxy > miny)then
    table.insert(list, {x=_x, y = maxy})
  end
  print("Y1_Y2",miny,maxy)
  for i = 1, #list do
    print(list[i].x,list[i].y)
  end
  return list
end

function CodeGameScreenThorsStrikeMachine:symbolChangetoWild(matrix)
  local choose = 1
  for i,p in ipairs(matrix) do
    if(p)then
      p:setScale(1)
      if(p.p_symbolType == GD.TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)then
        p:runAnim('start2',false,function()
          p:runAnim('idleframe6',true)
        end)
        p:setLineAnimName('actionframe3')
        p:setIdleAnimName('idleframe6')
      else
        local ccbNode = p:getCCBNode()
        if ccbNode ~= nil then
          ccbNode:removeFromParent()
          if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,p.p_symbolType)
          end
        end
        p.p_symbolType = 94
        p.m_ccbName = self:MachineRule_GetSelfCCBName(94)
        p:runAnim('start',false,function()
          p:runAnim('idleframe2',true)
        end)
        p:setLineAnimName('actionframe')
        p:setIdleAnimName('idleframe2')
      end
    end
  end
end

----------------Spin逻辑开始时触发-------------------------------
--用于延时滚动轮盘等
function CodeGameScreenThorsStrikeMachine:MachineRule_SpinBtnCall()
  self:setMaxMusicBGVolume( )
  if self.m_winSoundsId then
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil
  end
  self.isScatterQuickStopSound = true
  return false
end

function CodeGameScreenThorsStrikeMachine:addSelfEffect()
  --dump(self.m_runSpinResultData.p_selfMakeData)
  if(self.m_runSpinResultData.p_selfMakeData.wildBianJie and
    #self.m_runSpinResultData.p_selfMakeData.wildBianJie > 0)then
    local ef = GameEffectData.new()
    ef.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    ef.p_effectOrder = CodeGameScreenThorsStrikeMachine.WILD_FEATURE_EFFECT
    ef.p_selfEffectType = CodeGameScreenThorsStrikeMachine.WILD_FEATURE_EFFECT
    table.insert(self.m_gameEffects,ef)
  end
end

function CodeGameScreenThorsStrikeMachine:MachineRule_playSelfEffect(effectData)

  if(effectData.p_selfEffectType == CodeGameScreenThorsStrikeMachine.WILD_FEATURE_EFFECT)then
    print('========wild feature func!!')
    --self:wildFeatureEffect(effectData)
    performWithDelay(self,function()
      self:wildFeatureEffect(effectData)
    end,0.3)

  elseif(effectData.p_selfEffectType == CodeGameScreenThorsStrikeMachine.FREE_CHOOSE_FEATURE_EFFECT)then
    --self:showFreeChooseView()
    --effectData.p_isPlay = true
    --self:playGameEffect()
  end

  return true
end
function CodeGameScreenThorsStrikeMachine:wildFeatureEffect(ef)
  print('=======执行 wild feature')
  dump(self.m_runSpinResultData.p_selfMakeData)
  local selfMakeData = self.m_runSpinResultData.p_selfMakeData
  local mtx = selfMakeData.wildBianJie
  local minX,maxX,minY,maxY = mtx[4]+1,mtx[3]+1,6-(mtx[1]+1),6-(mtx[2]+1)
  self.m_bwildfreature = true
  self.m_wildfreatureTriggercount = self.m_wildfreatureTriggercount + 1
  self:setSymbolToReel()
  self:wildfreatreTwo(minX,maxX,minY,maxY,function()
    ef.p_isPlay = true
    self:playGameEffect()
  end)
  --local mod = math.fmod(self.m_wildfreatureTriggercount,3)
  --local key = 'wildFreature'..mod
  --gLobalSoundManager:playSound(Sounds[key].sound)
  local index = 0
  local key = 'wildFreature'
  if self.m_wildfreatureSoundIndex >= 0 then
    local array = {}
    for i=0,2 do
      if i ~= self.m_wildfreatureSoundIndex then
        table.insert(array, i)
      end
    end
    index = array[math.random(1,#array)]
  else
    index = math.random(0,2)
  end
  self.m_wildfreatureSoundIndex = index
  key = key..index
  gLobalSoundManager:playSound(Sounds[key].sound)
end

function CodeGameScreenThorsStrikeMachine:getAngleAndPos(p1, p2)
  local length = math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2))
  local len2 = length / 2
  local angle = GD.util_getAngleByPos(p1,p2)
  local ct = cc.p((p1.x+p2.x) / 2, (p1.y+p2.y)/2 )
  return { length= length, len2= len2, angle = angle, ct = ct}
end

function CodeGameScreenThorsStrikeMachine:checkBoundary(pm,p1,minX,maxX,minY,maxY)
  --左边界
  local pos = cc.p(p1.x, p1.y)
  if(pm.p_cloumnIndex == minX)then
    pos.x = pos.x - self.m_SlotNodeW / 2
    if(pm.p_rowIndex == maxY)then
      pos.y = pos.y + self.m_SlotNodeH / 2
    elseif(pm.p_rowIndex == minY)then
      pos.y = pos.y - self.m_SlotNodeH / 2
    end
  elseif(pm.p_rowIndex == minY)then --下
    pos.y = pos.y - self.m_SlotNodeH / 2
    if(pm.p_cloumnIndex == maxX)then
      pos.x = pos.x + self.m_SlotNodeW / 2
    end
  elseif(pm.p_cloumnIndex == maxX)then --右
    pos.x = pos.x + self.m_SlotNodeW / 2
    if(pm.p_rowIndex == maxY)then
      pos.y = pos.y + self.m_SlotNodeH / 2
    elseif(pm.p_rowIndex == minY)then
      pos.y = pos.y - self.m_SlotNodeH / 2
    end
  elseif(pm.p_rowIndex == maxY)then --上
    pos.y = pos.y + self.m_SlotNodeH / 2
  end
  return pos
end

function CodeGameScreenThorsStrikeMachine:new_wildfreatre(minX,maxX,minY,maxY)
  self:findChild("mask"):show()
  local parent = self:findChild('wildfeature')
  local array = {}
  for x = minX, maxX do
    for y = minY,maxY do
      local p = self:getFixSymbol(x,y,SYMBOL_NODE_TAG)
      p.bvertex = false
      if(p)then table.insert(array,p) end
      self:setSymbolToClip(p)
    end
  end
  local width = (maxX - minX) * self.m_SlotNodeW
  local height = (maxY - minY) * self.m_SlotNodeH
  local ct = cc.p(width/2, height/2)

  local p = self:getFixSymbol(minX,minY,SYMBOL_NODE_TAG)
  local pos =  p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
  local cenpos = cc.p(pos.x + ct.x,pos.y + ct.y)
  cenpos = parent:convertToNodeSpace(cenpos)

  p.bvertex = true
  local p2 = self:getFixSymbol(maxX,minY,SYMBOL_NODE_TAG)
  p2.bvertex = true
  local p3 = self:getFixSymbol(maxX,maxY,SYMBOL_NODE_TAG)
  p3.bvertex = true
  local p4 = self:getFixSymbol(minX,maxY,SYMBOL_NODE_TAG)
  p4.bvertex = true
  local list = {}
  local function foreat(x, y, p1, num)
    local col,row  = x,y
    for i = 0, num - 1 do
      if(p1.x < 0)then col = x - i  end
      if(p1.x > 0)then col = x + i  end
      if(p1.y < 0)then row = y - i  end
      if(p1.y > 0)then row = y + i  end
      local p = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
      if(p.bvertex or p.p_symbolType == 92)then
        table.insert(list, p)
      end
    end
  end
  foreat(minX,maxY, cc.p(0,-1),maxY-minY + 0)
  foreat(minX,minY, cc.p(1, 0),maxX-minX + 0)
  foreat(maxX,minY, cc.p(0, 1),maxY-minY + 0)
  foreat(maxX,maxY, cc.p(-1,0),maxX-minX + 1)

  local linescfg = {}
  if(minX == maxX)then
    list = {}
    self:addColLightningData(linescfg,cenpos,minX,maxX,minY,maxY)
  elseif(minY == maxY)then
    list = {}
    self:addRowLightningData(linescfg,cenpos,minX,maxX,minY,maxY)
  end

  for i = 1, #list do
    if(i + 1 <= #list)then
      local p = list[i]
      local pos = p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
      local p1 = parent:convertToNodeSpace(pos )
      local p2 = list[i + 1]
      local pos2 = p2:getParent():convertToWorldSpace(cc.p(p2:getPosition()))
      local p3 =  parent:convertToNodeSpace(pos2)
      local bthors = p.p_symbolType == 92
      local p4 = self:checkBoundary(p,p1,minX,maxX,minY,maxY)
      local p5 = self:checkBoundary(p2,p3,minX,maxX,minY,maxY)
      table.insert(linescfg, {p1 = p1, p2 = p3, p3=cenpos,p4=p4,p5=p5, bvertex = p.bvertex,bthors = bthors,pm = p,pline = 0})
    end
  end

  --for i, p in ipairs(linescfg) do
  -- local line = GD.util_createAnimation('ThorsStrike_fashe.csb'):show()
  -- parent:addChild(line)
  -- p.pline = line
  -- p.pline:setPosition(p.p4)
  -- local args = self:getAngleAndPos(p.p4, p.p5 )
  -- p.pline:setRotation(-args.angle)
  -- p.pline:setScale(args.length / 840)
  -- p.pline:runCsbAction('fashe',false,function()
  --   p.pline:runCsbAction('idleframe1',true)
  -- end)
  --end


  self:addLightningEffect(linescfg,array,maxX)
end

function CodeGameScreenThorsStrikeMachine:addLightningEffect(linescfg,array,maxX, endcallFunc )
  local parent = self:findChild('wildfeature')
  for i, p in ipairs(linescfg) do
    local line = GD.util_createAnimation('ThorsStrike_fashe.csb'):hide()
    parent:addChild(line)
    p.pline = line
  end
  local bds = {}
  for i = 1,1 do
    bds[i] = GD.util_createAnimation('ThorsStrike_bd.csb'):hide()
    parent:addChild(bds[i])
  end
 
  local sizew = 840
  local n,list = 0,{}
  n=n+1 list[n] = cc.CallFunc:create(function()
    for i,p in ipairs(array) do
      if(p.p_symbolType == 92)then
        p:runAnim('actionframe2',false)
        if(p.p_cloumnIndex < maxX)then p:setScaleX(-1)end
      end
     end
  end)
  n=n+1 list[n] = cc.DelayTime:create(1.2)
  n=n+1 list[n] = cc.CallFunc:create(function()
    for i, p in ipairs(linescfg) do
      p.pline:show()
      p.pline:setPosition(p.p1)
      local args = self:getAngleAndPos(p.p1, p.p3 )
      if(p.bvertex and not p.bthors)then
        p.pline:setPosition(p.p2)
        args = self:getAngleAndPos(p.p2, p.p3 )
        p.pline:hide()
      end
      p.pline:setRotation(-args.angle)
      p.pline:setScale(args.length / sizew)
      p.pline:runCsbAction('fashe',false,function()
        p.pline:runCsbAction('idleframe1',true)
      end)
    end
  end)
  n=n+1 list[n] = cc.DelayTime:create(0.2)
  n=n+1 list[n] = cc.CallFunc:create(function()
    bds[1]:show()
    bds[1]:setPosition(linescfg[1].p3)
    bds[1]:runCsbAction('fashe_bd')
  end)

  n=n+1 list[n] = cc.DelayTime:create(1.0)
  n=n+1 list[n] = cc.CallFunc:create(function()
    for i, p in ipairs(linescfg) do
 
      local args = self:getAngleAndPos(p.p4, p.p5)
      local dt = 0.3--cc.pGetDistance(p.p4, p.p5) / 100
      p.pline:show()
 
      local move  = cc.MoveTo:create(dt,p.p4)
      if(p.bvertex and not p.bthors)then
        args = self:getAngleAndPos(p.p5, p.p4 )
        move  = cc.MoveTo:create(dt,p.p5)
      end
      
      local spwan = cc.Spawn:create(move,cc.RotateTo:create(dt,-args.angle),cc.ScaleTo:create(0.1, args.length / sizew))
      local call = cc.CallFunc:create(function(pline)
        pline:runCsbAction('actionframe',false,function()
          pline:runCsbAction('idleframe2',true)
        end)
      end)
      p.pline:runAction(cc.Sequence:create(spwan,call))
    end
  end)
  n=n+1 list[n] = cc.DelayTime:create(0.4)
  n=n+1 list[n] = cc.CallFunc:create(function()
    self.pNodekuosan:show()
    self.pNodekuosan:setPosition(linescfg[1].p3)
    self.pNodekuosan:runCsbAction('kuosan')
  end)
  n=n+1 list[n] = cc.DelayTime:create(0.5)
  n=n+1 list[n] = cc.CallFunc:create(function()
    self:symbolChangetoWild(array)
  end)
  n=n+1 list[n] = cc.DelayTime:create(1.2)
  n=n+1 list[n] = cc.CallFunc:create(function()
    for i,p in ipairs(linescfg) do
      p.pm.bvertex = false
    end
    if endcallFunc then endcallFunc() end
  end)
  self:runAction(cc.Sequence:create(list))
end

function CodeGameScreenThorsStrikeMachine:addColLightningData(linescfg, cenpos,minX,maxX,minY,maxY)
  local parent = self:findChild('wildfeature')
  local p =  self:getFixSymbol(minX,maxY,SYMBOL_NODE_TAG)
  local pos = p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
  local p1 = parent:convertToNodeSpace(pos )

  local p2 =  self:getFixSymbol(minX,minY,SYMBOL_NODE_TAG)
  local pos2 = p2:getParent():convertToWorldSpace(cc.p(p2:getPosition()))
  local p3 =  parent:convertToNodeSpace(pos2)

  local w = self.m_SlotNodeW / 2
  local h = self.m_SlotNodeH / 2
  local p4 = cc.p(p1.x - w, p1.y + h)
  local p5 = cc.p(p3.x - w, p3.y - h)

  local p6 = cc.p(p3.x + w, p3.y - h)

  local p7 = cc.p(p1.x + w, p1.y + h)
  local p8 = cc.p(p1.x - w, p1.y + h)

  table.insert(linescfg, {p1 = p1, p2 = p3, p3=cenpos,p4=p4,p5=p5, bvertex = false,bthors = false,pm = p,pline = 0})
  table.insert(linescfg, {p1 = p3, p2 = p3, p3=cenpos,p4=p5,p5=p6, bvertex = false,bthors = false,pm = p2,pline = 0})
  table.insert(linescfg, {p1 = p3, p2 = p3, p3=cenpos,p4=p6,p5=p7, bvertex = false,bthors = false,pm = p2,pline = 0})
  table.insert(linescfg, {p1 = p1, p2 = p3, p3=cenpos,p4=p7,p5=p8, bvertex = false,bthors = false,pm = p,pline = 0})
end

function CodeGameScreenThorsStrikeMachine:addRowLightningData(linescfg, cenpos,minX,maxX,minY,maxY)
  local parent = self:findChild('wildfeature')
  local p =  self:getFixSymbol(minX,minY,SYMBOL_NODE_TAG)
  local pos = p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
  local p1 = parent:convertToNodeSpace(pos )

  local p2 =  self:getFixSymbol(maxX,minY,SYMBOL_NODE_TAG)
  local pos2 = p2:getParent():convertToWorldSpace(cc.p(p2:getPosition()))
  local p3 =  parent:convertToNodeSpace(pos2)

  local w = self.m_SlotNodeW / 2
  local h = self.m_SlotNodeH / 2
  local p4 = cc.p(p1.x - w, p1.y + h)
  local p5 = cc.p(p1.x - w, p1.y - h)

  local p6 = cc.p(p3.x + w, p3.y - h)

  local p7 = cc.p(p3.x + w, p3.y + h)
  local p8 = cc.p(p1.x - w, p1.y + h)

  table.insert(linescfg, {p1 = p1, p2 = p3, p3=cenpos,p4=p4,p5=p5, bvertex = false,bthors = false,pm = p,pline = 0})
  table.insert(linescfg, {p1 = p1, p2 = p3, p3=cenpos,p4=p5,p5=p6, bvertex = false,bthors = false,pm = p2,pline = 0})
  table.insert(linescfg, {p1 = p3, p2 = p1, p3=cenpos,p4=p6,p5=p7, bvertex = false,bthors = false,pm = p2,pline = 0})
  table.insert(linescfg, {p1 = p3, p2 = p1, p3=cenpos,p4=p7,p5=p8, bvertex = false,bthors = false,pm = p,pline = 0})
end

function CodeGameScreenThorsStrikeMachine:wildfreatreTwo(minX,maxX,minY,maxY, callbacks)
  self:findChild("mask"):show()
  local parent = self:findChild('wildfeature')
  local array = {}
  for x = minX, maxX do
    for y = minY,maxY do
      local p = self:getFixSymbol(x,y,SYMBOL_NODE_TAG)
      if(p)then table.insert(array,p) end
      if(p.p_symbolType == 92 or p.p_symbolType == 0)then
        self:setSymbolToClip(p)
      end
    end
  end
  local parentData = self.m_slotParents[1]
  local width = (maxX - minX + 1) * parentData.reelWidth + (maxX - minX) * 4
  local height = (maxY - minY +1) * self.m_SlotNodeH
  local p = self:getFixSymbol(minX,minY,SYMBOL_NODE_TAG)
  local pos =  p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
  local scw = self.m_SlotNodeW / 2
  local sch = self.m_SlotNodeH / 2

  local rightP = self:getFixSymbol(maxX,maxY,SYMBOL_NODE_TAG)
  local rpos =  rightP:getParent():convertToWorldSpace(cc.p(rightP:getPosition()))
  pos.x = pos.x - scw
  pos.y = pos.y - sch

  rpos.x = rpos.x + scw
  rpos.y = rpos.y + sch
  local cenpos = cc.p((pos.x+rpos.x) / 2, (pos.y+rpos.y)/2 )
  --local cenpos = cc.p(pos.x - scw + ct.x, pos.y - sch + ct.y)
  cenpos = parent:convertToNodeSpace(cenpos)
  local rect = cc.size(width,height)

  local p1 = self:getFixSymbol(minX,maxY,SYMBOL_NODE_TAG)
  local p2 = self:getFixSymbol(minX,minY,SYMBOL_NODE_TAG)
  local p3 = self:getFixSymbol(maxX,minY,SYMBOL_NODE_TAG)
  local p4 = self:getFixSymbol(maxX,maxY,SYMBOL_NODE_TAG)

  local list = {p1,p2,p3,p4,p1}
  local linescfg = {}
  if(minX == maxX)then
    list = {}
    self:addColLightningData(linescfg,cenpos,minX,maxX,minY,maxY)
  elseif(minY == maxY)then
    list = {}
    self:addRowLightningData(linescfg,cenpos,minX,maxX,minY,maxY)
  end
  for i = 1, #list do
    if(i + 1 <= #list)then
      local p = list[i]
      local pos = p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
      local p1 = parent:convertToNodeSpace(pos )
      local p2 = list[i + 1]
      local pos2 = p2:getParent():convertToWorldSpace(cc.p(p2:getPosition()))
      local p3 =  parent:convertToNodeSpace(pos2)
      local bthors = p.p_symbolType == 92
      local p4 = self:checkBoundary(p,p1,minX,maxX,minY,maxY)
      local p5 = self:checkBoundary(p2,p3,minX,maxX,minY,maxY)
      table.insert(linescfg, {p1 = p1, p2 = p3, p3=cenpos,p4=p4,p5=p5, bvertex = p.bvertex,bthors = bthors,pm = p,pline = 0})
    end
  end
  self:LightningEffect(linescfg,array,callbacks,rect)
end
function CodeGameScreenThorsStrikeMachine:LightningEffect(linescfg,array, endcallFunc,rect )
    local LightningNode = cc.Node:create()
    self:findChild('root'):addChild(LightningNode)
    LightningNode:setTag(10086)
    local parent = self:findChild('wildfeature')
    local bds = {}
    local center_pos = cc.p(linescfg[1].p3.x -0,linescfg[1].p3.y - 0)
    for i = 1,1 do
      bds[i] = GD.util_createAnimation('ThorsStrike_bd.csb'):hide()
      parent:addChild(bds[i],9999)
    end
    local pKuosanDi = GD.util_createAnimation('ThorsStrike_kuosan_di.csb'):hide()
    parent:addChild(pKuosanDi)

    local cfg = {
      {'ThorsStrike_dian_lan_heng.csb','ThorsStrike_qiu_lan.csb'},
      {'ThorsStrike_dian_jin_heng.csb','ThorsStrike_qiu_jin.csb'},
    }
    for i, p in ipairs(linescfg) do
      p.plines = {}
      p.qius = {}
      for n = 1, 2 do
        local st = cfg[n]
        local line = GD.util_createAnimation(st[1]):hide()
        LightningNode:addChild(line)
        p.plines[n] = line
        p.pline = line
        p.pline:setPosition(p.p4)
        local args = self:getAngleAndPos(p.p4, p.p5 )
        p.pline:setRotation(-args.angle)
        local sz = p.pline:findChild('Panel_1'):getContentSize()
        p.pline:findChild('Panel_1'):setContentSize(cc.size(args.length, sz.height))
        p.pline:runCsbAction('idleframe',true)
        local qiu = GD.util_createAnimation(st[2]):hide()
        LightningNode:addChild(qiu,9999)
        qiu:setPosition(p.p4)
        qiu:runCsbAction('actionframe',true)
        p.qius[n] = qiu
      end
    end
    LightningNode:setScale(0)
    LightningNode:setPosition(center_pos)
  
    local sizew = 840
    local n,list,fashelines = 0,{},{}
    n=n+1 list[n] = cc.CallFunc:create(function()
      for i,p in ipairs(array) do
        if(p.p_symbolType == 92)then
          p:runAnim('actionframe2',false)
          local p1 = parent:convertToNodeSpace(p:getParent():convertToWorldSpace(cc.p(p:getPosition())) )
          if(p1.x < center_pos.x)then
            p:setScaleX(-1)
          end
        end
      end
      gLobalSoundManager:playSound(Sounds.wildTrigger.sound)
    end)
    n=n+1 list[n] = cc.DelayTime:create(1.2)
    n=n+1 list[n] = cc.CallFunc:create(function()
      for i,p in ipairs(array) do
        if(p.p_symbolType == 92)then
          local line = GD.util_createAnimation('ThorsStrike_fashe.csb'):show()
          parent:addChild(line)
          local pos = p:getParent():convertToWorldSpace(cc.p(p:getPosition()))
          local p1 = parent:convertToNodeSpace(pos )
          line:setPosition(p1)
          local args = self:getAngleAndPos(p1, center_pos)
          line:setRotation(-args.angle)
          line:runCsbAction('fashe')
          line:setScale(args.length / 560)
          table.insert(fashelines, line)
        end
      end
    end)
    n=n+1 list[n] = cc.DelayTime:create(0.1)
    n=n+1 list[n] = cc.CallFunc:create(function()
      bds[1]:show()
      bds[1]:setPosition(center_pos)
      bds[1]:runCsbAction('fashe_bd')
    end)

    n=n+1 list[n] = cc.DelayTime:create(0.6)
    n=n+1 list[n] = cc.CallFunc:create(function()
      for i,p in ipairs(linescfg) do
        p.plines[1]:show()
        p.qius[1]:show()
      end
      local call = cc.CallFunc:create(function() end)
      local spwan = cc.Spawn:create(cc.MoveTo:create(0.5,cc.p(0,0)),cc.ScaleTo:create(0.5, 1))
      LightningNode:runAction(cc.Sequence:create(spwan,call))
      gLobalSoundManager:playSound(Sounds.wildFreature.sound)
    end)
    n=n+1 list[n] = cc.DelayTime:create(0.8)
    n=n+1 list[n] = cc.CallFunc:create(function()
      for i,v in ipairs(fashelines) do
        v:removeSelf()
      end
      bds[1]:hide()
      pKuosanDi:show()
      pKuosanDi:findChild('Panel_1'):setContentSize(rect)
      pKuosanDi:runCsbAction('kuosan')
      pKuosanDi:setPosition(center_pos)
      pKuosanDi:findChild('Sprite_1'):setPosition(cc.p(rect.width/2, rect.height / 2))
      self.pNodekuosan:show()
      self.pNodekuosan:setPosition(center_pos)
      self.pNodekuosan:runCsbAction('kuosan')
      local x,y = rect.width / 800,rect.height / 600
      self.pNodekuosan:setScale(math.max(x,y))
      self.m_pNodeShanDian:show()
      self.m_pNodeShanDian:setPosition(center_pos)
      self.m_pNodeShanDian:runCsbAction('kuosan')
      self:playSceneShake()
    end)
    n=n+1 list[n] = cc.DelayTime:create(0.3)
    n=n+1 list[n] = cc.CallFunc:create(function()
      for i,p in ipairs(array) do
        if(p.p_symbolType ~= 92)then
          self:setSymbolToClip(p)
        end
      end
      self:symbolChangetoWild(array)
    end)
    n=n+1 list[n] = cc.DelayTime:create(0.5)
    n=n+1 list[n] = cc.CallFunc:create(function()
      for i,p in ipairs(linescfg) do
        p.plines[1]:hide()
        p.qius[1]:hide()
        p.qius[2]:show()
        p.plines[2]:show()
      end
    end)
    n=n+1 list[n] = cc.DelayTime:create(1.0)
    n=n+1 list[n] = cc.CallFunc:create(function()
      self:findChild('wildfeature'):removeAllChildren()
      --LightningNode:removeSelf()
      for i,p in ipairs(linescfg) do
        -- p.qius[2]:runAction(cc.FadeTo:create(0.01, 0))
        p.qius[2]:runCsbAction('over')
        p.plines[2]:runCsbAction('over',false,function()
          if i == #linescfg then
            LightningNode:removeSelf()
          end
        end)
      end
    end)
    n=n+1 list[n] = cc.DelayTime:create(0.2)
    n=n+1 list[n] = cc.CallFunc:create(function()
      self:findChild("mask"):hide()
      if endcallFunc then endcallFunc() end
    end)
    self:runAction(cc.Sequence:create(list))
end


function CodeGameScreenThorsStrikeMachine:checkOperaSpinSuccess(param)
  local spinData = param[2]
  if spinData.action == "SPIN" then
    local random = util_random(1,10)
    if param[2].result.features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER and self:getCurrSpinMode() ~= FREE_SPIN_MODE and random <=4 then
      self.m_ScatterShowCol = nil
      self:playYuGaoEffect(function()
        CodeGameScreenThorsStrikeMachine.super.checkOperaSpinSuccess(self, param)
      end)
    else
      self:checkQuickReelEffect(spinData)
      self.m_ScatterShowCol = {1,2,3,4,5,6}
      local dely = 0
      --local wyugao =spinData.result.selfData.wildBianJie
      --if(self:getCurrSpinMode() ~= FREE_SPIN_MODE and self.m_bIsBigWin and random <= 4 and wyugao and #wyugao>0)then
      --  dely = self:wildYuGaoEffect(spinData)
      --end
      if dely > 0 then
        performWithDelay(self,function()
          self:findChild("mask"):hide()
          self:showColorLayer(false)
          CodeGameScreenThorsStrikeMachine.super.checkOperaSpinSuccess(self, param)
        end, dely)
      else
        CodeGameScreenThorsStrikeMachine.super.checkOperaSpinSuccess(self, param)
      end
    end
  end
end

function CodeGameScreenThorsStrikeMachine:scaleMainLayer()
  CodeGameScreenThorsStrikeMachine.super.scaleMainLayer(self)
  local ratio = display.height/display.width
  local offy = 0
  if display.height==768 and display.width==1228 then
    offy = -5
    local mainScale = 1.0
    self.m_machineRootScale = mainScale
    GD.util_csbScale(self.m_machineNode, mainScale)
  end
  self.m_machineNode:setPositionY(offy)
end

--轮盘滚动数据生成之后
--改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenThorsStrikeMachine:MachineRule_ResetReelRunData()
end

function CodeGameScreenThorsStrikeMachine:playEffectNotifyNextSpinCall( )
  CodeGameScreenThorsStrikeMachine.super.playEffectNotifyNextSpinCall( self )
  self:checkTriggerOrInSpecialGame(function(  )
    self:reelsDownDelaySetMusicBGVolume( )
  end)
end

function CodeGameScreenThorsStrikeMachine:slotReelDown( )
  self:checkTriggerOrInSpecialGame(function(  )
    self:reelsDownDelaySetMusicBGVolume( )
  end)
  CodeGameScreenThorsStrikeMachine.super.slotReelDown(self)
end

function CodeGameScreenThorsStrikeMachine:beginReel()
  self:setSymbolToReel()
  self.m_allscatters = {}
  self.m_bQuickStop = false
  self.m_firstEnter = false
  self.m_isReconnect = false
  self:findChild("mask"):hide()
  self:findChild('wildfeature'):removeAllChildren()
  self:showColorLayer(true)
  if not self.m_bwildfreature then
    self.m_wildfreatureTriggercount = 0
  end
  self.m_bwildfreature = false
  CodeGameScreenThorsStrikeMachine.super.beginReel(self)
end

function CodeGameScreenThorsStrikeMachine:setReelRunInfo()
  local iColumn = self.m_iReelColumnNum
  local bRunLong = false
  local scatterNum = 0
  local bonusNum = 0
  local longRunIndex = 0
  for col=1,iColumn do
    local reelRunData = self.m_reelRunInfo[col]
    local columnData = self.m_reelColDatas[col]
    local iRow = columnData.p_showGridCount
    if bRunLong == true then
      longRunIndex = longRunIndex + 1
      local runLen = self:getLongRunLen(col, longRunIndex)
      local preRunLen = reelRunData:getReelRunLen()
      local addRun = runLen - preRunLen
      reelRunData:setReelRunLen(runLen)
    end
    local runLen = reelRunData:getReelRunLen()
    if(self.m_ScatterShowCol~=nil)then
      --统计bonus scatter 信息
      scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
      --bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_WILD, col , bonusNum, bRunLong)
      print('scatter_setReelRunInfo_col_ bonusNum, bRunLong:',col,  scatterNum, bRunLong)
      print('bonus_setReelRunInfo_col_ bonusNum, bRunLong:',col,  bonusNum, bRunLong)
    end
  end
end

local runStatus =
{
    DUANG = 1,
    NORUN = 2,
}
function CodeGameScreenThorsStrikeMachine:getRunStatus(col, nodeNum, showCol)
  local showColTemp = {}
  local bscatter = false
  if showCol ~= nil then 
      showColTemp = showCol
      bscatter = true
  else 
      for i=1,self.m_iReelColumnNum do
          showColTemp[#showColTemp + 1] = i
      end
  end
  if bscatter and col == showColTemp[#showColTemp - 1] then
      if nodeNum <= 1 then
          return runStatus.NORUN, false
      elseif nodeNum == 2 then
          return runStatus.DUANG, true
      else
          return runStatus.DUANG, false
      end
  elseif bscatter and col == showColTemp[#showColTemp] then
      if nodeNum <= 2  then
          return runStatus.NORUN, false
      else
          return runStatus.DUANG, false
      end
  else
      if showCol == nil then
        if nodeNum > 0 then
          return runStatus.DUANG, true
        else
          return runStatus.DUANG, false
        end
      else
        if nodeNum == 2 then
          return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
      end
  end
end

function CodeGameScreenThorsStrikeMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
  local reelRunData = self.m_reelRunInfo[column]
  local runLen = reelRunData:getReelRunLen()
  local allSpecicalSymbolNum = specialSymbolNum
  local bRun, bPlayAni =  false,false--reelRunData:getSpeicalSybolRunInfo(symbolType)

  if symbolType ==92 or symbolType == 90  then
    bRun, bPlayAni = true, true
  end

  local soundType = runStatus.DUANG
  local nextReelLong = false

  local showCol = nil
  if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
      showCol = self.m_ScatterShowCol
  elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
      
  end

  if(column == 5)then
    print('66')
  end
  
  soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

  local columnData = self.m_reelColDatas[column]
  local iRow = columnData.p_showGridCount

  for row = 1, iRow do
      if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
      
          local bPlaySymbolAnima = bPlayAni
      
          allSpecicalSymbolNum = allSpecicalSymbolNum + 1
          
          if bRun == true then
              
              soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

              local soungName = nil
              if soundType == runStatus.DUANG then
                  if allSpecicalSymbolNum == 1 then
                      soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                  elseif allSpecicalSymbolNum == 2 then
                      soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                  else
                      soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                  end
              else
                  --不应当播放动画 (么戏了)
                  bPlaySymbolAnima = false
              end

              reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

          else
              -- bonus scatter不参与滚动设置
              local soundName = nil
              if bPlaySymbolAnima == true then
                  --自定义音效
                  
                  reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
              else 
                  reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
              end
          end
      end
      
  end

  if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
      bRunLong = true
      --下列长滚
      reelRunData:setNextReelLongRun(true)
  end
  return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenThorsStrikeMachine:creatReelRunAnimation(col)
  printInfo("xcyy : col %d", col)
  if self.m_reelRunAnima == nil then
      self.m_reelRunAnima = {}
  end

  local reelEffectNode = nil
  local reelAct = nil
  if self.m_reelRunAnima[col] == nil then
      reelEffectNode, reelAct = self:createReelEffect(col)
  else
      local reelObj = self.m_reelRunAnima[col]
      reelEffectNode = reelObj[1]
      reelAct = reelObj[2]
  end
  reelEffectNode:setScaleX(1)
  reelEffectNode:setScaleY(1)
  if self.m_reelEffectName == self.m_defaultEffectName then
      local reelRunAnimaWidth = 200
      local reelRunAnimaHeight = 603
      local worldPos, reelHeight, reelWidth = self:getReelPos(col)
      local scaleY = reelHeight / reelRunAnimaHeight
      local scaleX = reelWidth / reelRunAnimaWidth
      reelEffectNode:setScaleY(scaleY)
      reelEffectNode:setScaleX(scaleX)
  end
  local bPlayBG = false
  self:setLongAnimaInfo(reelEffectNode, col)
  self:hideAllReelRunEffect()
  reelEffectNode:setVisible(true)
  util_csbPlayForKey(reelAct, "run", true)
  --if(self.m_scatterSpeedCols[col] > 0 and self.m_wildSpeedCols[col] <=0)then
  --  reelEffectNode:setVisible(true)
  --  util_csbPlayForKey(reelAct, "run", true)
  --elseif(self.m_scatterSpeedCols[col] > 0 and self.m_wildSpeedCols[col] >0 and self.m_ScatterShowCol ~= nil)then
  --  local reelObj = self.m_wildscatterReelRunAnis[col]
  --  reelEffectNode = reelObj[1]
  --  reelAct = reelObj[2]
  --  reelEffectNode:setVisible(true)
  --  util_csbPlayForKey(reelAct, "run", true)
  --  local frontEffect = self.m_wildscatterReelRunAnis[col - 1]
  --  if(frontEffect~=nil and frontEffect[1]:isVisible())then
  --    frontEffect[1]:runAction(cc.Hide:create())
  --  end
  --elseif(self.m_wildSpeedCols[col] >0)then
  --  bPlayBG = true
  --  local reelObj = self.m_wildreelRunAnimations[col]
  --  reelEffectNode = reelObj[1]
  --  reelAct = reelObj[2]
  --  reelEffectNode:setVisible(true)
  --  util_csbPlayForKey(reelAct, "run", true)
  --  local frontEffect = self.m_wildreelRunAnimations[col - 1]
  --  if(frontEffect~=nil and frontEffect[1]:isVisible())then
  --    frontEffect[1]:runAction(cc.Hide:create())
  --  end
  --end
  if self.m_reelBgEffectName ~= nil and bPlayBG then   --快滚背景特效 wild快滚才播放背景
      local reelEffectNodeBG = nil
      local reelActBG = nil
      if self.m_reelRunAnimaBG == nil then
          self.m_reelRunAnimaBG = {}
      end
      if self.m_reelRunAnimaBG[col] == nil then
          reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
      else
          local reelBGObj = self.m_reelRunAnimaBG[col]
          reelEffectNodeBG = reelBGObj[1]
          reelActBG = reelBGObj[2]
      end
      reelEffectNodeBG:setScaleX(1)
      reelEffectNodeBG:setScaleY(1)
      reelEffectNodeBG:setVisible(true)
      util_csbPlayForKey(reelActBG, "run", true)
  end
  gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
  self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenThorsStrikeMachine:changeReelDownAnima(parentData)
  -- parentData.reelDownAnima = "buling"
  parentData.reelDownAnimaSound = Sounds.scatterBuing.sound
end

--滚轴停止回弹
function CodeGameScreenThorsStrikeMachine:reelSchedulerCheckColumnReelDown(parentData)
  local slotParent = parentData.slotParent
  if parentData.isDone ~= true then
      parentData.isDone = true
      slotParent:stopAllActions()
      self:slotOneReelDown(parentData.cloumnIndex)
      local nodeParent = parentData.slotParent
      local nodes = {}--nodeParent:getChildren()
      for row = 1,self.m_iReelRowNum do
        local p = self:getFixSymbol(parentData.cloumnIndex,row,SYMBOL_NODE_TAG)
        if(p.p_symbolType == 90)then
          table.insert(nodes, p)
        end
      end

      local quickStopY = -35 --快停回弹距离
      if self.m_quickStopBackDistance then
          quickStopY = -self.m_quickStopBackDistance
      end
      -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
      local backTotalTotalTime = 0
      local symbolNodeList, start, over = self.m_reels[parentData.cloumnIndex].m_gridList:getList()
      for i = start, over do
          local allActionTime = 0
          local symbolNode = symbolNodeList[i]
          local speedActionTable = {}
          if self.m_isNewReelQuickStop then
              local originalPos = cc.p(symbolNode:getPosition())
              symbolNode:setPositionY(symbolNode:getPositionY() + quickStopY)

              local moveTime = self.m_configData.p_reelResTime
              if self:getGameSpinStage() == QUICK_RUN then
                  moveTime = 0.3
              end
              local back = cc.MoveTo:create(moveTime, originalPos)
              table.insert(speedActionTable, back)
              allActionTime = allActionTime + moveTime
          else
              local originalPos = cc.p(symbolNode:getPosition())
              local dis = self.m_configData.p_reelResDis
              local speedStart = parentData.moveSpeed
              local preSpeed = speedStart / 118
              local timeDown = self.m_configData.p_reelResTime
              if self:getGameSpinStage() ~= QUICK_RUN then
                  for i = 1, 10 do
                      speedStart = speedStart - preSpeed * (11 - i) * 2
                      local moveDis = dis / 10
                      local time = moveDis / speedStart
                      timeDown = timeDown + time
                      local moveBy = cc.MoveBy:create(time, cc.p(slotParent:getPositionX(), -moveDis))
                      table.insert(speedActionTable, moveBy)
                      allActionTime = allActionTime + time
                  end
              end

              local back = cc.MoveTo:create(timeDown, originalPos)
              table.insert(speedActionTable, back)
              allActionTime = allActionTime + timeDown
          end

          if i == over then
              local nodeParent = parentData.slotParent
              -- local childTab = slotParent:getChildren()
              local childTab = nodeParent:getChildren()
              local tipSlotNoes = nil
              --添加提示节点
              tipSlotNoes = self:addReelDownTipNode(nodes)
              local actionNodeTip =
                  cc.CallFunc:create(
                  function()
                      if tipSlotNoes ~= nil then
                          local nodeParent = parentData.slotParent
                          for i = 1, #tipSlotNoes do
                              --播放提示动画
                              self:playReelDownTipNode(tipSlotNoes[i])
                              
                          end
                      end
                  end
              )
              self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)
              local actionFinishCallFunc =
                  cc.CallFunc:create(
                  function()
                      parentData.isResActionDone = true
                      if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                          self:newQuickStopReel(self.m_quickStopReelIndex)
                      end
                      self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                  end
              )

              if self.m_isShowSpecialNodeTip == true then
                  table.insert(speedActionTable, 1, actionNodeTip)
              end
              speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

              symbolNode:runAction(cc.Sequence:create(speedActionTable))
              
          else
              symbolNode:runAction(cc.Sequence:create(speedActionTable))
          end

          if backTotalTotalTime < allActionTime then
              backTotalTotalTime = allActionTime
          end
      end
      
      self:reelStopHideMask(backTotalTotalTime, parentData.cloumnIndex)
  end
  return 0.1
end

function CodeGameScreenThorsStrikeMachine:setScatterDownScound( )
  for i = 1, 5 do
      local soundPath1 = Sounds.scatterBuing.sound
      -- 
      local soundPathBonus = Sounds.wildbuling.sound
      self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath1  
      -- self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPathBonus
      -- 
  end
end

function CodeGameScreenThorsStrikeMachine:playQuickStopBulingScatterSound()
  
  if self.isScatterQuickStopSound then
    if self:getGameSpinStage() == QUICK_RUN then

      gLobalSoundManager:playSound(Sounds.scatterBuing.sound)
      self.isScatterQuickStopSound = false
    end
  end
  
end

--[[
    延迟回调
]]
function CodeGameScreenThorsStrikeMachine:delayCallBack(time, func)
  local waitNode = cc.Node:create()
  self:addChild(waitNode)
  performWithDelay(
      waitNode,
      function()
          waitNode:removeFromParent(true)
          waitNode = nil
          if type(func) == "function" then
              func()
          end
      end,
      time
  )

  return waitNode
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenThorsStrikeMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = self.m_bottomUI.m_bigWinLabCsb:getPositionY()
        posY = posY + 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    else
      self.m_bottomUI.m_bigWinLabCsb:setScale(0.6)
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1.2,
        animName   = "actionframe3",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenThorsStrikeMachine:showBigWinLight(_func)
    self.m_bIsBigWin = false
    local animName = "actionframe"
    self.m_bigWinSpine:setVisible(true)
    gLobalSoundManager:playSound(Sounds.bigWin.sound)
    util_spinePlay(self.m_bigWinSpine, animName, false)
    util_spineEndCallFunc(self.m_bigWinSpine, animName, function()
        self.m_bigWinSpine:setVisible(false)
        if type(_func) == "function" then
            _func()
        end
    end)

    self:shakeNode()
end

return CodeGameScreenThorsStrikeMachine