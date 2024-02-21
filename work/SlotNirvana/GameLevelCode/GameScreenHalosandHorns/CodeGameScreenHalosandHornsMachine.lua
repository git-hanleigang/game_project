---
-- island li
-- 2019年1月26日
-- CodeGameScreenHalosandHornsMachine.lua
-- 
-- 玩法：
-- 
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenHalosandHornsMachine = class("CodeGameScreenHalosandHornsMachine", BaseSlotoManiaMachine)

CodeGameScreenHalosandHornsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenHalosandHornsMachine.RISE_REEL_COL_1_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 90 
CodeGameScreenHalosandHornsMachine.RISE_REEL_COL_2_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 89 
CodeGameScreenHalosandHornsMachine.RISE_REEL_COL_3_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 88 
CodeGameScreenHalosandHornsMachine.RISE_REEL_COL_4_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 87 
CodeGameScreenHalosandHornsMachine.RISE_REEL_COL_5_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 86 

CodeGameScreenHalosandHornsMachine.FREE_SPIN_DELAY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- free 下每次spin都等待free轮子的游戏事件结束

CodeGameScreenHalosandHornsMachine.SYMBOL_ANGEL_10 = 9
CodeGameScreenHalosandHornsMachine.SYMBOL_ANGEL_11 = 10
CodeGameScreenHalosandHornsMachine.SYMBOL_ANGEL_12 = 11
CodeGameScreenHalosandHornsMachine.SYMBOL_ANGEL_13 = 12
CodeGameScreenHalosandHornsMachine.SYMBOL_ANGEL_14 = 13

CodeGameScreenHalosandHornsMachine.SYMBOL_DEVIL_RISE = 94
CodeGameScreenHalosandHornsMachine.SYMBOL_ANGEL_DECLINE = 95

-- 快滚缩放比例
CodeGameScreenHalosandHornsMachine.m_LongRunScale = {60,60,60,80,100,118,140,156,178}

CodeGameScreenHalosandHornsMachine.m_baseReelRestRow = 3
CodeGameScreenHalosandHornsMachine.m_baseReelRow = {5,4,3,4,6}
CodeGameScreenHalosandHornsMachine.m_currentReelRow = {5,4,3,4,6}
CodeGameScreenHalosandHornsMachine.m_LinesReelRow = {5,4,3,4,6}
CodeGameScreenHalosandHornsMachine.m_columnMaxReward = {"8","30","GRAND","15","6"} 
CodeGameScreenHalosandHornsMachine.m_betColumnMaxRewards = {} 
CodeGameScreenHalosandHornsMachine.m_betColumnRows = {} 

CodeGameScreenHalosandHornsMachine.m_reelBgBeginPercent = 33
CodeGameScreenHalosandHornsMachine.m_reelBGAddPercent = math.floor(100/9) 

CodeGameScreenHalosandHornsMachine.m_reelJianTou_BeginPosY = -169
CodeGameScreenHalosandHornsMachine.m_reelianTou_AddPosY = 80

CodeGameScreenHalosandHornsMachine.m_reelJianTouBG_BeginPosY = -175
CodeGameScreenHalosandHornsMachine.m_reelJianTouBG_AddPosY = 80

local reelClipAddSizeY = 37 -- 裁切轮子多出来多少px

CodeGameScreenHalosandHornsMachine.m_clipNode_BeginSizeY = 240 + reelClipAddSizeY
CodeGameScreenHalosandHornsMachine.m_clipNode_AddSizeY = 80

CodeGameScreenHalosandHornsMachine.m_maxMutilBonusTop = 10
CodeGameScreenHalosandHornsMachine.m_waitTimeReelDown = 0
CodeGameScreenHalosandHornsMachine.m_spinReelDownTime = 0.4

CodeGameScreenHalosandHornsMachine.BONUS_TOP_NODENAME  = {"bonus_Node_1","bonus_Node_2","bonus_Node_Jp","bonus_Node_3","bonus_Node_4"}
CodeGameScreenHalosandHornsMachine.BONUS_TOP_TYPE_JP = "GRAND"
CodeGameScreenHalosandHornsMachine.BONUS_TOP_TYPE_FREE = "FREE"
CodeGameScreenHalosandHornsMachine.BONUS_TOP_TYPE_COINS_ZI = "ZI"
CodeGameScreenHalosandHornsMachine.BONUS_TOP_TYPE_COINS_LV = "LV"

CodeGameScreenHalosandHornsMachine.RiseSpeed = 0.1

CodeGameScreenHalosandHornsMachine.MAIN_ADD_POSY = 45

CodeGameScreenHalosandHornsMachine.ZhuZi_level_1 = 5
CodeGameScreenHalosandHornsMachine.ZhuZi_level_2 = 6
CodeGameScreenHalosandHornsMachine.ZhuZi_level_3 = 7

CodeGameScreenHalosandHornsMachine.SCATTER_SYMBOL_SIZE = 3

CodeGameScreenHalosandHornsMachine.COL_1 = 1
CodeGameScreenHalosandHornsMachine.COL_2 = 2
CodeGameScreenHalosandHornsMachine.COL_3 = 3
CodeGameScreenHalosandHornsMachine.COL_4 = 4
CodeGameScreenHalosandHornsMachine.COL_5 = 5

CodeGameScreenHalosandHornsMachine.updateSpeed = 0.04

CodeGameScreenHalosandHornsMachine.m_isOutLines = true

CodeGameScreenHalosandHornsMachine.m_top_bonus_reword_coins = 0

CodeGameScreenHalosandHornsMachine.m_collectBonusPos = {} -- 播放topbonus 动画的位置

CodeGameScreenHalosandHornsMachine.m_triggerFirst = true --是否是第一次进入到升行游戏

-- 构造函数
function CodeGameScreenHalosandHornsMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isOnceClipNode = false
    self.m_spinRestMusicBG = true
    self.m_bCreateResNode = false
    self.m_isOutLines = true

    self.m_iReelMinRow = 3
    self.m_iReelMaxRow = 9

    -- 小块，连线框，基础baseDialog弹板csb 根据实际帧率设置
    self.m_slotsAnimNodeFps = 30
    self.m_lineFrameNodeFps = 30
    self.m_baseDialogViewFps = 30

    self.m_top_bonus_reword_coins = 0
    self.m_isFeatureOverBigWinInFree = true

    --init
    self:initGame()
end

function CodeGameScreenHalosandHornsMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(self.m_iReelMaxRow,self.m_iReelColumnNum,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenHalosandHornsMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("HalosandHornsConfig.csv", "LevelHalosandHornsConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenHalosandHornsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "HalosandHorns"  
end

function CodeGameScreenHalosandHornsMachine:initUI()

    local win_txt = self.m_bottomUI:findChild("win_txt")
    if win_txt then

        self.m_winEffect = util_createAnimation("HalosandHorns_yingqian.csb")
        win_txt:addChild(self.m_winEffect,-1)
        self.m_winEffect:setVisible(false)
    
    end

    self.m_gameBg:runCsbAction("normal",true)
    self.m_gameBg:setAutoScaleEnabled(false)

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_jackPotBar = util_createView("CodeHalosandHornsSrc.HalosandHornsJackPotBarView","Socre_HalosandHorns_jcakpot_3")
    self:findChild("jcakpot_Node"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:runCsbAction("idleframe",true)
    

    self.m_jpBarJinBi = util_createAnimation("HalosandHorns_jcakpot_jinbi.csb")
    self.m_jackPotBar:findChild("Node_jinbi"):addChild(self.m_jpBarJinBi)
    self.m_jpBarJinBi:setVisible(false)

    self.m_jpBarZi = util_createAnimation("HalosandHorns_jackpot_zi.csb")
    self.m_jackPotBar:findChild("Node_emojackpot"):addChild(self.m_jpBarZi)
    self.m_jpBarZi:setVisible(false)

    self.m_jpBarEmo = util_spineCreate("Socre_HalosandHorns_jcakpot_1",true,true)
    self.m_jackPotBar:findChild("Node_emo"):addChild(self.m_jpBarEmo)
    self.m_jpBarEmo:setVisible(false)


   for iCol = 1,self.m_iReelColumnNum do

        self["DevilZhuZi_"..iCol] = util_createAnimation("HalosandHorns_zhuzi_emo.csb")
        self:findChild("xianshu_"..iCol):addChild(self["DevilZhuZi_"..iCol])
        self["DevilZhuZi_"..iCol]:runCsbAction("actionframe",true)

        self["zhizhen_emo_"..iCol] = util_createAnimation("HalosandHorns_zhizhen_emo.csb")
        self:findChild("HalosandHorns_zhizhen_"..iCol):addChild(self["zhizhen_emo_"..iCol])
        self["zhizhen_emo_"..iCol]:runCsbAction("idle",true)
        self:findChild("HalosandHorns_zhizhen_"..iCol):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)


        self["m_updateReelBgNode_"..iCol] = cc.Node:create()
        self:addChild(self["m_updateReelBgNode_"..iCol])

        self["m_updateReelAniRiseNode_"..iCol] = cc.Node:create()
        self:addChild(self["m_updateReelAniRiseNode_"..iCol])
        
   end
 
    local reelData= {}
    reelData.machine = self
    self.m_miniReel = util_createView("CodeHalosandHornsSrc/FsReel/HalosandHornsFsMiniMachine",reelData)
    self:findChild("Node_AngelReel"):addChild(self.m_miniReel) 
    self:findChild("Node_AngelReel"):setVisible(false)
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniReel.m_touchSpinLayer)
    end

    self.m_guoChang = util_createAnimation("HalosandHorns_guochang.csb") 
    self:addChild(self.m_guoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChang:setPosition(display.width/2,display.height/2)
    self.m_guoChang:findChild("root"):setScale(self.m_machineRootScale)
    self.m_guoChang:setVisible(false)

    

    self.m_yuGaoDark = util_createAnimation("HalosandHorns_yugao_Bgdark.csb") 
    self:findChild("Node_yugao"):addChild(self.m_yuGaoDark)
    self.m_yuGaoDark:setVisible(false)

    self.m_yuGao = util_createAnimation("HalosandHorns_yugao_Bg.csb") 
    self:findChild("Node_yugao"):addChild(self.m_yuGao)
    self.m_yuGao:setVisible(false)

    self.m_yuGao_Devil_Man = util_spineCreate("HalosandHorns_yugao",true,true)
    self.m_yuGao:findChild("Node_Devil_Man"):addChild(self.m_yuGao_Devil_Man)
    
    self:restBonusTopZorder( )
    
    self:findChild("jcakpot_Node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 110)
    self:findChild("Node_AngelReel"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    self:findChild("Node_yugao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 90)
    self:findChild("Node_guoChang"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 10)


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        self:stopLinesWinSound()

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            self:showWinEffect( )
        elseif winRate > 3  then
            soundIndex = 3
            self:showWinEffect( )
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "HalosandHornsSounds/music_HalosandHorns_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenHalosandHornsMachine:restBonusTopZorder( )
    for iCol = 1,self.m_iReelColumnNum do
        local nodeName = self.BONUS_TOP_NODENAME
        local parentTopNode = self:findChild(nodeName[iCol])
        parentTopNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 109 + iCol )
    end
end

function CodeGameScreenHalosandHornsMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then

        mainScale = display.height / (self:getReelHeight() + uiH + uiBH)
        if display.height > DESIGN_SIZE.height then
            mainScale = DESIGN_SIZE.height / (self:getReelHeight() + uiH + uiBH)
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + self.MAIN_ADD_POSY )

        
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

function CodeGameScreenHalosandHornsMachine:initGameStatusData(gameData)
    
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)

    if gameData and gameData.gameConfig and  gameData.gameConfig.extra ~= nil then

        local initColumnRows =  gameData.gameConfig.extra.initColumnRows
        local betColumnRows = gameData.gameConfig.extra.betColumnRows
        local betColumnMaxRewards =  gameData.gameConfig.extra.betColumnMaxRewards
        if initColumnRows then
            self.m_baseReelRow = initColumnRows
        end

        if betColumnMaxRewards then
            self.m_betColumnMaxRewards = betColumnMaxRewards
        end
        

        if betColumnRows then
            self.m_betColumnRows = betColumnRows
        end

    end

end


function CodeGameScreenHalosandHornsMachine:getBonusOneTopSymbolType(_maxReward )
    if _maxReward == self.BonusTopSymbolType_Jp then

        return self.BonusTopSymbolType_Jp

    elseif _maxReward == self.BONUS_TOP_TYPE_FREE then

        return self.BONUS_TOP_TYPE_FREE

    else

        if tonumber(_maxReward) > self.m_maxMutilBonusTop then
            return self.BONUS_TOP_TYPE_COINS_LV
        else
            return self.BONUS_TOP_TYPE_COINS_ZI
        end


    end 
end

function CodeGameScreenHalosandHornsMachine:updateBonusOneTopSymbol(_iCol )

    local nodeName = self.BONUS_TOP_NODENAME
    local parentNode = self:findChild(nodeName[_iCol])
    local maxReward =  self.m_columnMaxReward[_iCol]
    local isAdd = false

    if self["BonusTopSymbol_".._iCol] then

        if self["BonusTopSymbol_".._iCol].m_type ~= self:getBonusOneTopSymbolType(maxReward )  then
            isAdd = true
            self["BonusTopSymbol_".._iCol]:stopAllActions()
            self["BonusTopSymbol_".._iCol]:removeFromParent()
            self["BonusTopSymbol_".._iCol] = nil
        end

    else
        isAdd = true
    end

    if isAdd then

        if maxReward == self.BonusTopSymbolType_Jp then
            print("不创建--------")
        elseif maxReward == self.BONUS_TOP_TYPE_FREE then
            if isAdd then
                self["BonusTopSymbol_".._iCol] = util_createAnimation("Socre_HalosandHorns_bonus_3.csb")
                parentNode:addChild(self["BonusTopSymbol_".._iCol])
                self["BonusTopSymbol_".._iCol].m_type = self.BONUS_TOP_TYPE_FREE
                self["BonusTopSymbol_".._iCol].m_sign = maxReward
            end
            
        else
    
            if isAdd then
                
                if tonumber(maxReward) > self.m_maxMutilBonusTop then
                    self["BonusTopSymbol_".._iCol] = util_createAnimation("Socre_HalosandHorns_bonus_1.csb")
                    parentNode:addChild(self["BonusTopSymbol_".._iCol])
                    self["BonusTopSymbol_".._iCol].m_type = self.BONUS_TOP_TYPE_COINS_LV
                    self["BonusTopSymbol_".._iCol].m_sign = maxReward
                    
                else
                    self["BonusTopSymbol_".._iCol] = util_createAnimation("Socre_HalosandHorns_bonus_2.csb")
                    parentNode:addChild(self["BonusTopSymbol_".._iCol])
                    self["BonusTopSymbol_".._iCol].m_type = self.BONUS_TOP_TYPE_COINS_ZI  
                    self["BonusTopSymbol_".._iCol].m_sign = maxReward
                end
            end

        end 


        self:updateBonusTopSymbolIdleAnim( _iCol)


    end
    
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local lab_1 = self["BonusTopSymbol_".._iCol]:findChild("m_lb_coins_1")
    if lab_1 then
        lab_1:setString(util_formatCoins(totalBet * tonumber(maxReward),3)  )
    end
    local lab_2 = self["BonusTopSymbol_".._iCol]:findChild("m_lb_coins_2")
    if lab_2 then
        lab_2:setVisible(false)
    end
    

end

function CodeGameScreenHalosandHornsMachine:updateBonusTopSymbolIdleAnim( _iCol)
    if _iCol ~= self.COL_3 then
        if self.m_currentReelRow[_iCol] == 8 then
            self["BonusTopSymbol_".._iCol]:runCsbAction("idleframe1",true)
        else
            self["BonusTopSymbol_".._iCol]:runCsbAction("idleframe",true)
        end
    end
    
end

function CodeGameScreenHalosandHornsMachine:initBonusTopSymbol( )
    

    self.m_bonusTopJpDevilBg = util_createAnimation("Socre_HalosandHorns_jcakpot_1_bg.csb")
    self:findChild("bonus_Node_Jp"):addChild(self.m_bonusTopJpDevilBg)

    self.m_bonusTopJpDevil = util_spineCreate("Socre_HalosandHorns_jcakpot_1",true,true)
    self:findChild("bonus_Node_Jp"):addChild(self.m_bonusTopJpDevil)
    util_spinePlay(self.m_bonusTopJpDevil,"idleframe",true)

    for iCol = 1,self.m_iReelColumnNum  do

        if iCol ~= self.COL_3 then
            self:updateBonusOneTopSymbol(iCol )
        end
        
    end

    
end

function CodeGameScreenHalosandHornsMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "HalosandHornsSounds/music_HalosandHorns_enter.mp3" )

    end,0.4,self:getModuleName())
end


function CodeGameScreenHalosandHornsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:initColumnRows( )
    self:initColumnMaxRewards()
    self:updateCurrentReelRow( )
    self:updateCurrentColumnMaxReward( )
    self:updateLinesNum( )
    self:updateReelUIPos( )
    self:initBonusTopSymbol()
    

end


function CodeGameScreenHalosandHornsMachine:updateDevilMainReelUI( )

    -- 取消掉赢钱线的显示
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()

    

    

    for iCol=1,#self.m_currentReelRow  do
        local reelRow = self.m_currentReelRow[iCol]

        self:restReelUI(iCol,reelRow,self.updateSpeed )
        self:updateOneZhuZiLevel( iCol,reelRow )

        if iCol ~= self.COL_3  then
            self:updateBonusOneTopSymbol(iCol )
            self:updateBonusTopSymbolIdleAnim(iCol)
        end

    end

    self:updateLinesNum( )
end

function CodeGameScreenHalosandHornsMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)


    gLobalNoticManager:addObserver(self,function(self,params)

        self.m_collectBonusPos = {}
        
        self:updateCurrentReelRow( )
        self:updateCurrentColumnMaxReward( )

        self:updateDevilMainReelUI()
        

    end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenHalosandHornsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenHalosandHornsMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_ANGEL_10 then
        return "Socre_HalosandHorns_10"
    elseif symbolType ==  self.SYMBOL_ANGEL_11 then
        return "Socre_HalosandHorns_11"
    elseif symbolType ==  self.SYMBOL_ANGEL_12 then
        return "Socre_HalosandHorns_12"
    elseif symbolType ==  self.SYMBOL_ANGEL_13 then
        return "Socre_HalosandHorns_13"
    elseif symbolType ==  self.SYMBOL_ANGEL_14 then
        return "Socre_HalosandHorns_14"
    elseif symbolType ==  self.SYMBOL_DEVIL_RISE then
        return "Socre_HalosandHorns_jiantou_2"
    elseif symbolType ==  self.SYMBOL_ANGEL_DECLINE then
        return "Socre_HalosandHorns_jiantou_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_HalosandHorns_Scatter_1"
    end
    
    

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenHalosandHornsMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ANGEL_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ANGEL_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ANGEL_12,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ANGEL_13,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ANGEL_14,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_DEVIL_RISE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ANGEL_DECLINE,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenHalosandHornsMachine:MachineRule_initGame(  )

    if  self:getCurrSpinMode() == FREE_SPIN_MODE then

        self.m_gameBg:runCsbAction("fs",true)

        self:findChild("Node_Devil_Reel"):setVisible(false)

        self.m_miniReel:updateFsUI( )
        self:findChild("Node_AngelReel"):setVisible(true)
    end

end

--
--单列滚动停止回调
--
function CodeGameScreenHalosandHornsMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenHalosandHornsMachine:levelFreeSpinEffectChange()

    -- 自定义事件修改背景动画


end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenHalosandHornsMachine:levelFreeSpinOverChangeEffect()

    -- 自定义事件修改背景动画

    
end
---------------------------------------------------------------------------
---------------------------------弹版----------------------------------
function CodeGameScreenHalosandHornsMachine:showFreeSpinStart(num,func,isAuto)
    local ownerlist={}

    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func,BaseDialog.AUTO_TYPE_NOMAL)

end

----------- FreeSpin相关
function CodeGameScreenHalosandHornsMachine:triggerFreeSpinCallFun()

    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)  -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode( FREE_SPIN_MODE )
    self.m_bProduceSlots_InFreeSpin = true
    -- self:resetMusicBg()
end
-- FreeSpinstart
function CodeGameScreenHalosandHornsMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_fsStart_View.mp3")

    self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

        self:showGuoChang( "actionframe",function(  )
            
            self.m_waitTimeReelDown = 0

            self:updateDevilMainReelUI()
            self.m_gameBg:runCsbAction("fs",true)

           
            self:findChild("Node_Devil_Reel"):setVisible(false)

            self.m_miniReel:updateFsUI( )
            self:findChild("Node_AngelReel"):setVisible(true)
            self:triggerFreeSpinCallFun()

        end,function(  )

            self:resetMusicBg()

            effectData.p_isPlay = true
            self:playGameEffect()  
        end )

    end,true)


end

function CodeGameScreenHalosandHornsMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_fsOver_View.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            self:showGuoChang( "actionframe1",function(  )
                self.m_gameBg:runCsbAction("normal",true)

                self.m_waitTimeReelDown = 0

                self:findChild("Node_Devil_Reel"):setVisible(true)
                self:findChild("Node_AngelReel"):setVisible(false)
            end,function(  )
                self:triggerFreeSpinOverCallFun() 
            end )
        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},648)

end


function CodeGameScreenHalosandHornsMachine:updateTopBonusForSpin( )

    
    local isPlay = false
    for iCol = 1,self.m_iReelColumnNum  do

        if iCol ~= self.COL_3 then
            local currIcol = iCol
            self:updateBonusOneTopSymbol(currIcol )
            if table_vIn(self.m_collectBonusPos, currIcol) then
                self["BonusTopSymbol_"..iCol]:runCsbAction("show",false,function(  )
                    self:updateBonusTopSymbolIdleAnim( currIcol)
                end) 

                isPlay = true
            end
            
        end
        
    end

    if isPlay then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_spinShowTopBonus.mp3")  
        end
       
    end

    self.m_collectBonusPos = {}
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenHalosandHornsMachine:MachineRule_SpinBtnCall()
    
    self.m_triggerFirst = false
    self.m_miniReel.m_triggerFirst = false

    self.m_top_bonus_reword_coins = 0
    self.m_miniReel.m_top_bonus_reword_coins = 0

    self.m_isOutLines = false

    self.m_miniReel:updateReelUIPosForSpin( )
    self:updateReelUIPosForSpin( )


    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
   
    
    return false -- 用作延时点击spin调用
end

function CodeGameScreenHalosandHornsMachine:getSelfEffetZOrder(_iCol,_zoder )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local up = selfdata.up or {}
    local upRows = up.upRows or {0,0,0,0,0}
    local upRowNum = upRows[_iCol] or 0
    local endRow = self.m_currentReelRow[_iCol] + upRowNum

    local rewordType = self.m_columnMaxReward[_iCol]
    local zoder = 0

    if endRow == self.m_iReelMaxRow then

        self.m_triggerColNum = self.m_triggerColNum + 1
        
        if rewordType ==  self.BONUS_TOP_TYPE_FREE  then
            -- 最后播
            zoder = GameEffect.EFFECT_SELF_EFFECT - 40
        elseif rewordType ==  self.BONUS_TOP_TYPE_JP then
    
            zoder = GameEffect.EFFECT_SELF_EFFECT - 50
        else
            -- 最先播
            zoder = _zoder
        end
    else
        zoder = _zoder
    end

    
    

    return zoder
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenHalosandHornsMachine:addSelfEffect()


    self.m_triggerFirst = true
    self.m_triggerColNum = 0
    self.m_triggerCurrNum = 0


    self.m_AniColNum = 0
    self.m_AniCurrNum = 0

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        local selfEffect = GameEffectData.new() 
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.FREE_SPIN_DELAY_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FREE_SPIN_DELAY_EFFECT

    else

        -- 结算顺序，由左向右结算钱，然后结算jackpot，最后结算bonus
        -- 信号触发的bonus，不会和顶部触发的bonus，同时触发

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local up = selfdata.up or {}
        local upRows = up.upRows or {0,0,0,0,0}
        if upRows[self.COL_1] ~= 0 then
            self.m_AniColNum = self.m_AniColNum + 1
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self:getSelfEffetZOrder(1,self.RISE_REEL_COL_1_EFFECT ) 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RISE_REEL_COL_1_EFFECT
        end

        if upRows[self.COL_2] ~= 0 then
            self.m_AniColNum = self.m_AniColNum + 1
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self:getSelfEffetZOrder(2,self.RISE_REEL_COL_2_EFFECT ) 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RISE_REEL_COL_2_EFFECT
        end

        if upRows[self.COL_3] ~= 0 then
            self.m_AniColNum = self.m_AniColNum + 1
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self:getSelfEffetZOrder(3,self.RISE_REEL_COL_3_EFFECT ) 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RISE_REEL_COL_3_EFFECT
        end

        if upRows[self.COL_4] ~= 0 then
            self.m_AniColNum = self.m_AniColNum + 1
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self:getSelfEffetZOrder(4,self.RISE_REEL_COL_4_EFFECT ) 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RISE_REEL_COL_4_EFFECT
        end

        if upRows[self.COL_5] ~= 0 then
            self.m_AniColNum = self.m_AniColNum + 1
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self:getSelfEffetZOrder(5,self.RISE_REEL_COL_5_EFFECT ) 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RISE_REEL_COL_5_EFFECT
        end
       
    end

    

end

---
--设置bonus scatter 层级
function CodeGameScreenHalosandHornsMachine:getBounsScatterDataZorder(symbolType )
    
    local zorder = BaseSlotoManiaMachine.getBounsScatterDataZorder(self,symbolType )

    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    if symbolType == self.SYMBOL_DEVIL_RISE then

        zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1

    elseif symbolType == self.SYMBOL_ANGEL_DECLINE then  

        zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1

    end


    return zorder

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenHalosandHornsMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.RISE_REEL_COL_1_EFFECT then

        self:playRiseReelCol(effectData, self.COL_1 )

    elseif effectData.p_selfEffectType == self.RISE_REEL_COL_2_EFFECT then

        self:playRiseReelCol(effectData, self.COL_2 )

    elseif effectData.p_selfEffectType == self.RISE_REEL_COL_3_EFFECT then

        self:playRiseReelCol(effectData , self.COL_3 )

    elseif effectData.p_selfEffectType == self.RISE_REEL_COL_4_EFFECT then

        self:playRiseReelCol(effectData , self.COL_4 )

    elseif effectData.p_selfEffectType == self.RISE_REEL_COL_5_EFFECT then

        self:playRiseReelCol(effectData , self.COL_5 )

    end

    
    return true
end

function CodeGameScreenHalosandHornsMachine:getOneAniSymbol(_iCol,_iRow )
    
    local slotNode = nil
    if self.m_bigSymbolColumnInfo ~= nil and
        self.m_bigSymbolColumnInfo[_iCol] ~= nil then
        local isBigSymbol = false
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[_iCol]
        for k = 1, #bigSymbolInfos do

            local bigSymbolInfo = bigSymbolInfos[k]

            for changeIndex=1,#bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == _iRow then

                    slotNode = self:getFixSymbol(_iCol, _iRow)
                    isBigSymbol = true
                    break
                end
            end

        end
        if isBigSymbol == false then
            slotNode = self:getFixSymbol(_iCol, _iRow)
        end
    else
        slotNode = self:getFixSymbol(_iCol, _iRow)
    end
    
    return slotNode
end

function CodeGameScreenHalosandHornsMachine:getAniLastNodeList(_iCol,_riseSymbolRow )
    
    local lastNodeList = {}
    
    for iRow=1,self.m_iReelMaxRow do
        if iRow < _riseSymbolRow then

            local symbolNode = self:getOneAniSymbol(_iCol,iRow )
            table.insert(lastNodeList,symbolNode)
        end
        
    end
        

    return lastNodeList
end

function CodeGameScreenHalosandHornsMachine:updateAniLastNodeRowTag(_aniLastNodeList ,_addRow )
    for i=1,#_aniLastNodeList do
        local symbolNode = _aniLastNodeList[i]
        local row = symbolNode.p_rowIndex + _addRow
        -- 长条不会出现
        self:updateSymbolRowTag(symbolNode,row )
        
    end
end

function CodeGameScreenHalosandHornsMachine:updateSymbolRowTag(_symbolNode,_row )
    _symbolNode.p_rowIndex = _row
    _symbolNode:setTag(self:getNodeTag(_symbolNode.p_cloumnIndex, _symbolNode.p_rowIndex, SYMBOL_NODE_TAG))
    
end


function CodeGameScreenHalosandHornsMachine:createOneSymbolNode(_symbolType,_rowIndex,_cloumnIndex)
    
    local columnData = self.m_reelColDatas[_cloumnIndex]
    local halfNodeH = columnData.p_showGridH * 0.5

    local changeRowIndex = _rowIndex

    local stepCount = 1
    -- 检测是否为长条模式 
    if self.m_bigSymbolInfos and self.m_bigSymbolInfos[_symbolType] ~= nil then
        local symbolCount = self.m_bigSymbolInfos[_symbolType]
        changeRowIndex = changeRowIndex - symbolCount
    end 

    
    local parentData = self.m_slotParents[_cloumnIndex]
    parentData.m_isLastSymbol = true

    local node = self:getSlotNodeWithPosAndType(_symbolType,changeRowIndex,_cloumnIndex,true)
    node.p_slotNodeH = columnData.p_showGridH

    node.p_showOrder = self:getBounsScatterDataZorder(_symbolType) - changeRowIndex
    
    if not node:getParent() then
        local slotParentBig = parentData.slotParentBig
        if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
            slotParentBig:addChild(node,
                REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, _cloumnIndex * SYMBOL_NODE_TAG + changeRowIndex)
        else
            parentData.slotParent:addChild(node,
                REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, _cloumnIndex * SYMBOL_NODE_TAG + changeRowIndex)
        end
    else
        node:setTag(_cloumnIndex * SYMBOL_NODE_TAG + changeRowIndex)
        node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
        node:setVisible(true)
    end

    node.p_symbolType = _symbolType
    node.p_reelDownRunAnima = parentData.reelDownAnima

    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
    node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )
    node:runIdleAnim()

    return node
end





function CodeGameScreenHalosandHornsMachine:createRiseSymbolMoveTuoWei(_iCol )


    self["riseSymbolMoveTuoWei".._iCol] = util_createAnimation("HalosandHorns_tuowei_emo_move.csb")
    self:getReelParent(_iCol):addChild(self["riseSymbolMoveTuoWei".._iCol], REEL_SYMBOL_ORDER.REEL_ORDER_4)
    self["riseSymbolMoveTuoWei".._iCol]:runCsbAction("idle")
    self["riseSymbolMoveTuoWei".._iCol]:setVisible(true)

    

end

function CodeGameScreenHalosandHornsMachine:createRiseSymbolTimeLines(_riseSymbol )

    local currCol = _riseSymbol.p_cloumnIndex

    local riseSymbolBaoZha = self.m_clipParent:getChildByName("riseSymbolTimeLines"..currCol)
    if riseSymbolBaoZha then
        
    else
        riseSymbolBaoZha = util_createAnimation("Socre_HalosandHorns_xianshu_2.csb")
        self.m_clipParent:addChild(riseSymbolBaoZha,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 9)
        riseSymbolBaoZha:setName("riseSymbolTimeLines")
        
    end

    riseSymbolBaoZha:setVisible(true)
    riseSymbolBaoZha:runCsbAction("actionframe",false,function(  )
        riseSymbolBaoZha:setVisible(false)
    end)
    riseSymbolBaoZha:setPosition(util_getOneGameReelsTarSpPos(self,self:getPosReelIdx(_riseSymbol.p_rowIndex,_riseSymbol.p_cloumnIndex)))

    local linesNum = self:getCurrLinesNum( )

    local str = tostring(linesNum)
    riseSymbolBaoZha:findChild("m_lines_num"):setString(str)

end



function CodeGameScreenHalosandHornsMachine:beginRiseAni( )
    
    self.m_currAniRow = self.m_currAniRow + 1
    self.m_currAniIndex = self.m_currAniIndex + 1

    if self.m_currAniRow > self.m_endAniRow then
        if self.m_AniRndFunc then
            self.m_AniRndFunc()
        end

        return
    end

    local _symbolType = self.m_endRowReelData[self.m_currAniIndex]

    -- 移除停止行图标
    local currAniRowNode = self:getFixSymbol(self.m_currAniCol,self.m_currAniRow )
    

    -- 修改上升图标以下的图标 tag p_rowIndex
    local  aniLastNodelist = self:getAniLastNodeList(self.m_currAniCol ,self.m_currRiseSymbolRow)
    self:updateAniLastNodeRowTag(aniLastNodelist, 1)

    -- 创建底部拉出来的图标
    -- 长条不可能出现在升行图标的列
    local downSymbol =  self:createOneSymbolNode(_symbolType,1 ,self.m_currAniCol)
    downSymbol:setPositionY(downSymbol:getPositionY() - self.m_SlotNodeH )

    local cutNum = self.m_currAniRow - self.m_RiseSymbol.p_rowIndex

    local riseSymbolRow  =  self.m_currAniRow
    local RiseSymbolOldRow = self.m_RiseSymbol.p_rowIndex
    -- 修改上升图标 tag p_rowIndex
    self:updateSymbolRowTag(self.m_RiseSymbol,riseSymbolRow )

    table.insert(aniLastNodelist,downSymbol)
    
    

    local RiseSymbolTime = 15/30  --self.RiseSpeed * cutNum

    for i=1,#aniLastNodelist do
        local node = aniLastNodelist[i]
        util_playMoveByAction(node,RiseSymbolTime,cc.p(0,self.m_SlotNodeH))
    end

    
    
    self:updateReelRiseSymbol( self.m_RiseSymbol,self.m_currAniCol,self.m_currAniRow,RiseSymbolTime , RiseSymbolOldRow,function(  )
        
        self:moveDownCallFun(currAniRowNode)

        
        self:updateLinesNumFromRow(self.m_currAniCol,self.m_currAniRow )

        self:createRiseSymbolTimeLines(self.m_RiseSymbol )

        self:updateOneZhuZiLevel( self.m_currAniCol,self.m_currAniRow )

        self:playOneZhuZiTishiguang(self.m_currAniCol )

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            -- 动画箭头动画播完 继续下一轮
            if self["riseSymbolMoveTuoWei"..self.m_currAniCol] then
                self["riseSymbolMoveTuoWei"..self.m_currAniCol]:removeFromParent()
                self["riseSymbolMoveTuoWei"..self.m_currAniCol] = nil
            end

            self.m_currRiseSymbolRow = self.m_RiseSymbol.p_rowIndex

            if self.m_currAniRow >= self.m_endAniRow then
                self:beginRiseAni( )
            else
                local waitTime = 0.5
                performWithDelay(self,function(  )

                    gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_shenghang.mp3") 

                    self.m_RiseSymbol:runAnim("actionframe1")
                    local AniNode = self.m_RiseSymbol:getCCBNode()

                    self:beginRiseAni( )



                end,waitTime)
            end

            waitNode:removeFromParent()
        end,15/30)

         
            

    end)


    local riseSymbolMoveTuoWei =  self["riseSymbolMoveTuoWei"..self.m_currAniCol]
    if riseSymbolMoveTuoWei then
        riseSymbolMoveTuoWei:runCsbAction("actionframe")
    end

    local ReelUITime = RiseSymbolTime - self.updateSpeed
    self:updateReelUI( self.m_currAniCol,self.m_currAniRow,ReelUITime)

end

function CodeGameScreenHalosandHornsMachine:getBonusDevilSymbolIndex( _col,_row)
    
    for iRow = _row , 1, -1 do

        local symbolType = self:getMatrixPosSymbolType(iRow, _col)
        if symbolType == self.SYMBOL_DEVIL_RISE then
            return self:getPosReelIdx(iRow,_col) 
        end

    end

end

function CodeGameScreenHalosandHornsMachine:playRiseReelCol(effectData,_iCol )

    
    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local up = selfdata.up or {}
    local upRows = up.upRows or {0,0,0,0,0}
    local upRowNum = upRows[_iCol] or 0
    local upReels = up.upReels or {}
    local endRow = selfdata.columnRows[_iCol] --self.m_currentReelRow[_iCol] + upRowNum
    if selfdata.columnRewards and selfdata.columnRewards[tostring(_iCol - 1)] then
        endRow = self.m_iReelMaxRow
    end

    local endRowReelData = upReels[_iCol]
    local iCol = _iCol
    local riseSymbolIndex = self:getBonusDevilSymbolIndex( _iCol,endRow) -- 恶魔升行位置
    local fixPos = self:getRowAndColByPos(riseSymbolIndex)
    local riseSymbolRow = fixPos.iX 
    -- release_print("恶魔升行位置 iCol:"..iCol.. "endRow:"..endRow.."riseSymbolRow:"..riseSymbolRow)

    for iRow = 1, self.m_iReelMaxRow do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            -- release_print("targSp iCol:"..iCol.. "iRow:"..iRow.."symbolType:"..symbolType.."targSp.symbolType:"..targSp.p_symbolType)
            -- print("targSp iCol:"..iCol.. "iRow:"..iRow.."symbolType:"..symbolType.."targSp.symbolType:"..targSp.p_symbolType)
        else
            -- release_print("targSp获取不到 iCol:"..iCol.. "iRow:"..iRow.."symbolType: "..symbolType)
            -- print("targSp获取不到 iCol:"..iCol.. "iRow:"..iRow.."symbolType: "..symbolType)
            local symbolNode = self:createOneSymbolNode(symbolType,iRow,iCol)
            self:removeRiseTuoWeiNode(symbolNode )
        end
    end

    local symbolNodeIndex = 0
    local childs = self.m_slotParents[iCol].slotParent:getChildren()
    for index = 1, #childs do
        local node = childs[index]
        if node.p_symbolType then
            symbolNodeIndex = symbolNodeIndex + 1
            -- release_print("node iCol:"..node.p_cloumnIndex.. "iRow:"..node.p_rowIndex.."symbolType:"..node.p_symbolType)
            -- print("node iCol:"..node.p_cloumnIndex.. "iRow:"..node.p_rowIndex.."symbolType:"..node.p_symbolType)
        end
    end

    -- release_print("symbolNodeIndex :"..symbolNodeIndex)
    -- print("symbolNodeIndex :"..symbolNodeIndex)

    self.m_currRiseSymbolRow = riseSymbolRow
    self.m_currAniIndex = 0
    self.m_currAniCol = iCol
    self.m_currAniRow = endRow - upRowNum 
    self.m_endAniRow = endRow
    self.m_endRowReelData = endRowReelData
    self.m_AniRndFunc = function(  )


        self.m_currentReelRow[_iCol] = endRow

        self:updateBonusTopSymbolIdleAnim( _iCol)

        -- 到位置后判断是否进入特殊玩法
        self:triggerOneColTopSymbolGame( function(  )


            self:restBonusTopZorder( )

            self.m_RiseSymbol = util_setClipReelSymbolToBaseParent(self,self.m_RiseSymbol)

    
            self.m_currRiseSymbolRow = nil
            self.m_currAniCol = nil
            self.m_currAniRow = nil
            self.m_endAniRow = nil
            self.m_AniRndFunc = nil
            self.m_RiseSymbol = nil
    
            self.m_AniCurrNum = self.m_AniCurrNum + 1
            
            local waitTime = 0
            if self.m_AniCurrNum >= self.m_AniColNum then
                waitTime = 0.5
            end

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode,function(  )
                effectData.p_isPlay = true
                self:playGameEffect()
                waitNode:removeFromParent()
            end,waitTime)

            

        end, _iCol)


    end

    local waitTimes = 0.1
    if self.m_triggerFirst then
        self.m_triggerFirst = false
        waitTimes = 18/30
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_shenghang.mp3") 

        -- release_print("self.m_RiseSymbol iCol:"..iCol.. "riseSymbolRow:"..riseSymbolRow)

        -- 上升图标提层级
        self.m_RiseSymbol = util_setSymbolToClipReel(self,iCol, riseSymbolRow, self.SYMBOL_DEVIL_RISE,0)
        self.m_RiseSymbol:runAnim("actionframe1")
        self:beginRiseAni()

        waitNode:removeFromParent()
    end,waitTimes)
    


end

function CodeGameScreenHalosandHornsMachine:updateColumnMaxReward( _iCol )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local columnMaxReward = selfdata.columnMaxReward
    if columnMaxReward then
        self.m_columnMaxReward[_iCol] = columnMaxReward[_iCol]
    end
    
end

function CodeGameScreenHalosandHornsMachine:triggerOneColTopSymbolGame( _func ,_iCol)

    local endRow =  self.m_currentReelRow[_iCol]

    local coins = 0 

    if endRow == self.m_iReelMaxRow then

        self.m_triggerCurrNum = self.m_triggerCurrNum + 1
        
        self.m_waitTimeReelDown = self.m_spinReelDownTime

        --判断触发什么玩法
        local rewordType = self.m_columnMaxReward[_iCol]


        self:updateColumnMaxReward(_iCol) -- 更新
        local betIdx = globalData.slotRunData:getCurBetIndex()
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local columnRow = selfdata.columnRows--self.m_betColumnRows[tostring(betIdx)]
        local restRow = columnRow[_iCol]
        self.m_currentReelRow[_iCol] = restRow

        gLobalSoundManager:setBackgroundMusicVolume(0.4)

        gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_TriggerTop_Bonus.mp3") 

        -- 触发集满玩法
        --箭头触发动画
        self.m_RiseSymbol:runAnim("actionframe2")
        local AniNode = self.m_RiseSymbol:getCCBNode()
        util_spineEndCallFunc(AniNode.m_spineNode,"actionframe2",function(  )
            
        end)
        
        performWithDelay(self,function(  )
            
            local nodeName = self.BONUS_TOP_NODENAME
            local parentTopNode = self:findChild(nodeName[_iCol])
            parentTopNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 104)
            
            if rewordType ==  self.BONUS_TOP_TYPE_FREE  then
                table.insert( self.m_collectBonusPos, _iCol )
                -- freegame
                if self["BonusTopSymbol_".._iCol] then
                    self["BonusTopSymbol_".._iCol]:runCsbAction("actionframe",false,function(  )
                        

                        gLobalSoundManager:setBackgroundMusicVolume(1)


                        if _func then
                            _func()
                        end

                    end)
                end
            elseif rewordType ==  self.BONUS_TOP_TYPE_JP then

                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                local grandWinAmount = selfdata.grandWinCoins or 0
                local endCoins = grandWinAmount
               

                -- jackpot
                self:showDevilJpRewordAnim( endCoins,function(  )

                    
                    self:updateBottomUICoins( self.m_top_bonus_reword_coins,endCoins )

                    gLobalSoundManager:setBackgroundMusicVolume(1)

                    if _func then
                        _func()
                    end

                end )
            else
                table.insert( self.m_collectBonusPos, _iCol )
                -- 普通赢钱
                if self["BonusTopSymbol_".._iCol] then
                    self["BonusTopSymbol_".._iCol]:runCsbAction("actionframe")
 
                    local startNode = self["BonusTopSymbol_".._iCol]
                    local endNode = self.m_bottomUI:findChild("win_txt")
                    self:showTopBonusCollect(startNode,endNode,function(  )

                        local totalBet = globalData.slotRunData:getCurTotalBet()
                        local endCoins = totalBet * tonumber(rewordType)
                        self:updateBottomUICoins( self.m_top_bonus_reword_coins,endCoins )

                        gLobalSoundManager:setBackgroundMusicVolume(1)
                        
                        if _func then
                            _func()
                        end 

                    end)


   
                end

            end



        end,15/30)
        

    else
        -- 没有触发集满玩法
        if _func then
            _func()
        end
    end


end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
-- function CodeGameScreenHalosandHornsMachine:MachineRule_ResetReelRunData()
--     --self.m_reelRunInfo 中存放轮盘滚动信息
 
-- end

function CodeGameScreenHalosandHornsMachine:playEffectNotifyNextSpinCall( )

    BaseSlotoManiaMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenHalosandHornsMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseSlotoManiaMachine.slotReelDown(self)


end


--[[
    ********************  
    reel轮上涨  
--]]

function CodeGameScreenHalosandHornsMachine:updateReelUIPosForSpin( )
    
    
    for i=1,#self.m_currentReelRow do
        local iCol = i
        local iRow = self.m_currentReelRow[i]

        self:updateReelUI( iCol,iRow,self.m_waitTimeReelDown )
        self:updateOneZhuZiLevel( iCol,iRow )
    end

    self:updateTopBonusForSpin( )
    self:updateLinesNum( )
end

function CodeGameScreenHalosandHornsMachine:updateReelUIPos( )
    
    for i=1,#self.m_currentReelRow do
        local iCol = i
        local iRow = self.m_currentReelRow[i]

        self:restReelUI( iCol,iRow)
        self:updateOneZhuZiLevel( iCol,iRow )
    end
end

function CodeGameScreenHalosandHornsMachine:restReelUI( _iCol,_rowIndex )
    
    local reelBG = self:findChild("reel_BG_".._iCol)
    local jianTou = self:findChild("HalosandHorns_zhizhen_".._iCol)
    local jianTouDi = self:findChild("HalosandHorns_ui_".._iCol)
    local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + _iCol)

    

    local reelBg_EndPercent = self.m_reelBGAddPercent * _rowIndex
    local jianTou_EndPosY = self.m_reelJianTou_BeginPosY + self.m_reelianTou_AddPosY * (_rowIndex - 3)
    local jianTouBg_EndPosY = self.m_reelJianTouBG_BeginPosY + self.m_reelJianTouBG_AddPosY * (_rowIndex - 3)
    local clipNode_EndSizeY = self.m_clipNode_BeginSizeY + self.m_clipNode_AddSizeY * (_rowIndex - 3) 

    if _rowIndex == self.m_iReelMaxRow then
        reelBg_EndPercent = 100
        jianTou_EndPosY = jianTou_EndPosY - 10 -- 最后一次少移动10px
        jianTouBg_EndPosY = jianTouBg_EndPosY - 10  -- 最后一次少移动10px
    end

    local reelBGPercent = reelBG:getPercent()
    reelBG:setPercent(reelBg_EndPercent)


    local jianTouPosY = jianTou:getPositionY()
    jianTou:setPositionY(jianTou_EndPosY)

    local jianTouBgPosY = jianTouDi:getPositionY()
    jianTouDi:setPositionY(jianTouBg_EndPosY)
    

    local clipNodeRect = clipNode:getClippingRegion()
    clipNode:setClippingRegion(
        {
            x = clipNodeRect.x,
            y = clipNodeRect.y,
            width = clipNodeRect.width,
            height = clipNode_EndSizeY
        }
    )

    

end

function CodeGameScreenHalosandHornsMachine:updateReelUI( _iCol,_rowIndex,_time , _func,_updateCallFun)
    
    local reelBG = self:findChild("reel_BG_".._iCol)
    local jianTou = self:findChild("HalosandHorns_zhizhen_".._iCol)
    local jianTouDi = self:findChild("HalosandHorns_ui_".._iCol)
    local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + _iCol)
    local updateCallFunc = _updateCallFun
    

    local reelBg_EndPercent = self.m_reelBGAddPercent * _rowIndex
    local jianTou_EndPosY = self.m_reelJianTou_BeginPosY + self.m_reelianTou_AddPosY * (_rowIndex - 3)
    local jianTouBg_EndPosY = self.m_reelJianTouBG_BeginPosY + self.m_reelJianTouBG_AddPosY * (_rowIndex - 3)
    local clipNode_EndSizeY = self.m_clipNode_BeginSizeY + self.m_clipNode_AddSizeY * (_rowIndex - 3) 
    
    if _rowIndex == self.m_iReelMaxRow then
        reelBg_EndPercent = 100
        jianTou_EndPosY = jianTou_EndPosY - 10 -- 最后一次少移动10px
        jianTouBg_EndPosY = jianTouBg_EndPosY - 10  -- 最后一次少移动10px
    end

    local reelBg_CurrentPercent = reelBG:getPercent()
    local jianTou_CurrentPosY = jianTou:getPositionY()
    local jianTouBg_CurrentPosY = jianTouDi:getPositionY()
    local clipNode_CurrentRect = clipNode:getClippingRegion()



    local reelBgAddNum = (reelBg_EndPercent - reelBg_CurrentPercent ) / (_time / self.updateSpeed)
    local jianTouAddNum = (jianTou_EndPosY - jianTou_CurrentPosY) / (_time / self.updateSpeed)
    local jianTouBgAddNum = (jianTouBg_EndPosY - jianTouBg_CurrentPosY) / (_time / self.updateSpeed)
    local clipNodeAddNum = (clipNode_EndSizeY - clipNode_CurrentRect.height) / (_time / self.updateSpeed)

    reelBgAddNum = self:GetPreciseDecimal(reelBgAddNum, 11)
    jianTouAddNum = self:GetPreciseDecimal(jianTouAddNum, 11)
    jianTouBgAddNum = self:GetPreciseDecimal(jianTouBgAddNum, 11)
    clipNodeAddNum = self:GetPreciseDecimal(clipNodeAddNum, 11)

    local reelBg_isEnd = false
    local jianTou_isEnd = false
    local jianTouBg_isEnd = false
    local clipNode_isEnd = false
    local updataCallFunc_isEnd = true
    if updateCallFunc then
        updataCallFunc_isEnd = false
    end
    

    local scheduleNode =  self["m_updateReelBgNode_".._iCol]
    scheduleNode:stopAllActions()

    util_schedule(scheduleNode, function(  )
        
        local reelBGPercent = reelBG:getPercent()
        if reelBgAddNum >= 0 then
            if reelBGPercent >= reelBg_EndPercent then
                reelBg_isEnd = true
                reelBG:setPercent(reelBg_EndPercent)
            elseif reelBGPercent < reelBg_EndPercent then
                local updateNum = reelBGPercent + reelBgAddNum
                if updateNum > reelBg_EndPercent then
                    updateNum = reelBg_EndPercent
                end
                reelBG:setPercent(updateNum)
            end
        else
            if reelBGPercent >= reelBg_EndPercent then
                reelBg_isEnd = true
                reelBG:setPercent(reelBg_EndPercent)
            elseif reelBGPercent > reelBg_EndPercent then
                reelBG:setPercent(reelBGPercent + reelBgAddNum)
            end
        end
        


        local jianTouPosY = jianTou:getPositionY()
        if jianTouAddNum >= 0 then
            if jianTouPosY >= jianTou_EndPosY then
                jianTou_isEnd = true
                jianTou:setPositionY(jianTou_EndPosY)
            elseif jianTouPosY < jianTou_EndPosY then
                local updateNum = jianTouPosY + jianTouAddNum
                if updateNum > jianTou_EndPosY then
                    updateNum = jianTou_EndPosY
                end
                jianTou:setPositionY(updateNum)
            end
        else
            if jianTouPosY <= jianTou_EndPosY then
                jianTou_isEnd = true
                jianTou:setPositionY(jianTou_EndPosY)
            elseif jianTouPosY > jianTou_EndPosY then
                jianTou:setPositionY(jianTouPosY + jianTouAddNum)
            end
        end
        

        local jianTouBgPosY = jianTouDi:getPositionY()
        if jianTouBgAddNum >= 0  then
            if jianTouBgPosY >= jianTouBg_EndPosY then
                jianTouBg_isEnd = true
                jianTouDi:setPositionY(jianTouBg_EndPosY)
            elseif jianTouBgPosY < jianTouBg_EndPosY then

                local updateNum = jianTouBgPosY + jianTouBgAddNum
                if updateNum > jianTouBg_EndPosY then
                    updateNum = jianTouBg_EndPosY
                end

                jianTouDi:setPositionY(updateNum)
            end
        else
            if jianTouBgPosY <= jianTouBg_EndPosY then
                jianTouBg_isEnd = true
                jianTouDi:setPositionY(jianTouBg_EndPosY)
            elseif jianTouBgPosY > jianTouBg_EndPosY then
                jianTouDi:setPositionY(jianTouBgPosY + jianTouBgAddNum)
            end
        end
        

 
        local clipNodeRect = clipNode:getClippingRegion()

        if clipNodeAddNum >= 0 then
            if clipNodeRect.height >= clipNode_EndSizeY then
                clipNode_isEnd = true
                clipNode:setClippingRegion(
                    {
                        x = clipNodeRect.x,
                        y = clipNodeRect.y,
                        width = clipNodeRect.width,
                        height = clipNode_EndSizeY
                    }
                )
            elseif clipNodeRect.height < clipNode_EndSizeY then

                local updateNum = clipNodeRect.height + clipNodeAddNum
                if updateNum > clipNode_EndSizeY then
                    updateNum = clipNode_EndSizeY
                end

                clipNode:setClippingRegion(
                    {
                        x = clipNodeRect.x,
                        y = clipNodeRect.y,
                        width = clipNodeRect.width,
                        height = updateNum
                    }
                )
            end
        else
            if clipNodeRect.height <= clipNode_EndSizeY then
                clipNode_isEnd = true
                clipNode:setClippingRegion(
                    {
                        x = clipNodeRect.x,
                        y = clipNodeRect.y,
                        width = clipNodeRect.width,
                        height = clipNode_EndSizeY
                    }
                )
            elseif clipNodeRect.height > clipNode_EndSizeY then
                clipNode:setClippingRegion(
                    {
                        x = clipNodeRect.x,
                        y = clipNodeRect.y,
                        width = clipNodeRect.width,
                        height = clipNodeRect.height + clipNodeAddNum
                    }
                )
            end
        end
        

        if updateCallFunc then
            updataCallFunc_isEnd = updateCallFunc()
        end
       
        if reelBg_isEnd and jianTou_isEnd and jianTouBg_isEnd 
            and clipNode_isEnd and updataCallFunc_isEnd  then

            scheduleNode:stopAllActions()
            if _func then
                _func()
            end
        end
    end, self.updateSpeed)
    
    

end

--- nNum 源数字
--- n 小数位数
function CodeGameScreenHalosandHornsMachine:GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum;
    end
    n = n or 0;
    n = math.floor(n)
    if n < 0 then
        n = 0;
    end
    local nDecimal = 10 ^ n
    local nTemp = math.ceil(nNum * nDecimal);
    local nRet = nTemp / nDecimal;
    return nRet;
end

function CodeGameScreenHalosandHornsMachine:updateReelRiseSymbol( _node,_iCol,_endRow,_time , RiseSymbolOldRow ,_func)
    
    self:createRiseSymbolMoveTuoWei(_iCol )


    local currNode = _node
    local endIndex = self:getPosReelIdx(_endRow, _iCol)
    local endPos = util_getOneGameReelsTarSpPos(self,endIndex)
    
    local node_EndPosY = endPos.y
    local node_CurrentPosY = currNode:getPositionY()
    local nodeAddNum = (node_EndPosY - node_CurrentPosY ) / (_time / self.updateSpeed)
    local nodeMove_isEnd = false

    local riseSymbolMoveTuoWei_CurrentPos = util_getPosByColAndRow(self,currNode.p_cloumnIndex, RiseSymbolOldRow)
    local riseSymbolMoveTuoWeiEndY = util_getPosByColAndRow(self,currNode.p_cloumnIndex, _endRow).y
    local riseSymbolMoveTuoWeiAddNum = (riseSymbolMoveTuoWeiEndY - riseSymbolMoveTuoWei_CurrentPos.y ) / (_time / self.updateSpeed)
    local riseSymbolMoveTuoWei_isEnd = false

    riseSymbolMoveTuoWeiAddNum = self:GetPreciseDecimal(riseSymbolMoveTuoWeiAddNum, 11)

    local riseSymbolMoveTuoWei =  self["riseSymbolMoveTuoWei".._iCol]
    if riseSymbolMoveTuoWei then
        riseSymbolMoveTuoWei:runCsbAction("idle")
        riseSymbolMoveTuoWei:setVisible(true)
        riseSymbolMoveTuoWei:setPosition(riseSymbolMoveTuoWei_CurrentPos)
    end

    local scheduleNode =  self["m_updateReelAniRiseNode_".._iCol]
    scheduleNode:stopAllActions()

    util_schedule(scheduleNode, function(  )
        
        local currNodePosY = currNode:getPositionY()
        if currNodePosY >= node_EndPosY then
            nodeMove_isEnd = true
            currNode:setPositionY(node_EndPosY)
        elseif currNodePosY < node_EndPosY then
            currNode:setPositionY(currNodePosY + nodeAddNum)
        end


        if riseSymbolMoveTuoWei then
            local currRiseSymbolMoveTuoWeiPosY = riseSymbolMoveTuoWei:getPositionY()
            if currRiseSymbolMoveTuoWeiPosY >= riseSymbolMoveTuoWeiEndY then
                riseSymbolMoveTuoWei_isEnd = true
                riseSymbolMoveTuoWei:setPositionY(riseSymbolMoveTuoWeiEndY)
            elseif currRiseSymbolMoveTuoWeiPosY < riseSymbolMoveTuoWeiEndY then
                riseSymbolMoveTuoWei:setPositionY(currRiseSymbolMoveTuoWeiPosY + riseSymbolMoveTuoWeiAddNum)
            end
        else
            riseSymbolMoveTuoWei_isEnd = true
        end
       

        if nodeMove_isEnd and riseSymbolMoveTuoWei_isEnd  then

            scheduleNode:stopAllActions()

            if _func then
                _func()
            end
        end
    end, self.updateSpeed)
    
    

end



function CodeGameScreenHalosandHornsMachine:FSReelDownNotify(  )
    
    self.m_reelResultLines = {}
    self.m_vecGetLineInfo = {}

   BaseSlotoManiaMachine.slotReelDown(self)

end

function CodeGameScreenHalosandHornsMachine:FSReelShowSpinNotify( )

    self:restSelfGameEffects( self.FREE_SPIN_DELAY_EFFECT  )

end

function CodeGameScreenHalosandHornsMachine:showGuoChang( animName,_func,_func2 )
    
    
    gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_GuoChang.mp3") 

    self.m_guoChang:setVisible(true)
    self.m_guoChang:runCsbAction(animName,false,function(  )
        if _func2 then
            _func2()
        end
        self.m_guoChang:setVisible(false)
    end)
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        if _func then
            _func()
        end
        node:removeFromParent()
    end,30/30)

end

function CodeGameScreenHalosandHornsMachine:showYuGao(_func )
    
    gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_YuGaoZhongJiang.mp3") 

    self.m_yuGao:setVisible(true)

    self.m_yuGaoDark:setVisible(true)
    self.m_yuGaoDark:runCsbAction("actionframe",false,function(  )
        self.m_yuGaoDark:setVisible(false)
    end)

    self.m_yuGao:findChild("Node_21"):setVisible(false)

    util_spinePlay(self.m_yuGao_Devil_Man,"actionframe")
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )

        self.m_yuGao:findChild("Node_21"):setVisible(true)
        self.m_yuGao:runCsbAction("actionframe",false,function(  )
            
            self.m_yuGao:setVisible(false)

            if _func then
                _func()
            end

        end)

        node:removeFromParent()
    end,45/30)
     

end

------------------------
------------------
-------------
---------
--- 顶部副轮子玩法


function CodeGameScreenHalosandHornsMachine:requestSpinResult( )
    

    -- 轮子变化时需要等轮子变化完在发送消息

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    local waitTime = 0
    if self.m_waitTimeReelDown > 0 then
        waitTime = self.m_waitTimeReelDown + 0.1
    end
    performWithDelay(waitNode,function(  )

        self.m_waitTimeReelDown = 0

        BaseSlotoManiaMachine.requestSpinResult(self )

        waitNode:removeFromParent()
    end,waitTime)

    

    
    
end

function CodeGameScreenHalosandHornsMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end


    self:updateColumnRows( )
    self:updateColumnMaxRewards()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:netBackReelsStop( )
    else
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local isShowYuGao = selfdata.showVideo
    
        if isShowYuGao then
            self:showYuGao(function(  )
                self:netBackReelsStop( )
            end)
        else
            self:netBackReelsStop( )
        end 
    end
    

end

function CodeGameScreenHalosandHornsMachine:netBackReelsStop( )


    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
  
end


function CodeGameScreenHalosandHornsMachine:showDevilJpRewordAnim( coins,_func )
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "jackpot")
    end

    gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_DevilJpReword.mp3") 

    self:findChild("jcakpot_Node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)

    self.m_bonusTopJpDevil:setVisible(false)
    self.m_jpBarEmo:setVisible(true)
    util_spinePlay(self.m_jpBarEmo,"actionframe1")

    util_spineEndCallFunc(self.m_jpBarEmo,"actionframe1",function(  )
        
        self.m_bonusTopJpDevilBg:runCsbAction("actionframe",false,function(  )
            self.m_bonusTopJpDevilBg:runCsbAction("idleframe")
        end)

        util_spinePlay(self.m_jpBarEmo,"actionframe")

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            
            
            self.m_jackPotBar:updateRewordCoins(coins )
            
            self.m_jackPotBar:runCsbAction("actionframe") -- 45帧
            performWithDelay(waitNode,function(  )
                util_spinePlay(self.m_jpBarEmo,"actionframe_free_1")
                performWithDelay(waitNode,function(  )

                    util_spinePlay(self.m_jpBarEmo,"actionframe_free_2",true)

                    performWithDelay(waitNode,function(  )

                        self.m_jpBarJinBi:setVisible(true)
                        self.m_jpBarJinBi:runCsbAction("actionframe") -- 50

                        self.m_jackPotBar:runCsbAction("actionframe1") -- 25帧
                        self.m_jpBarZi:setVisible(true)
                        self.m_jpBarZi:runCsbAction("actionframe")

                        performWithDelay(waitNode,function(  )
                            
                            self.m_jackPotBar:runCsbAction("jiesuan",true)

                            util_spinePlay(self.m_jpBarEmo,"actionframe_free_3")

                            performWithDelay(waitNode,function(  )
                                util_spinePlay(self.m_jpBarEmo,"actionframe_free_4",true)

                                performWithDelay(waitNode,function(  )
                                    util_spinePlay(self.m_jpBarEmo,"actionframe_free_5",false)   
                                    performWithDelay(waitNode,function(  )
                                        self.m_jackPotBar:runCsbAction("jiesuanover",false,function(  )
                                            self:findChild("jcakpot_Node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 110)
                                            
                                            self.m_jackPotBar:setBoolShowReword( false )
                                            
                                            self.m_jackPotBar:runCsbAction("show",false,function(  )
                                                self.m_jackPotBar:runCsbAction("idleframe",true)
                                            end)

                                            self.m_bonusTopJpDevil:setVisible(true)
                                            self.m_jpBarEmo:setVisible(false)

                                            if _func then
                                                _func()
                                            end
                                        end)
            
                                        self.m_jpBarZi:runCsbAction("over",false,function(  )
                                            self.m_jpBarZi:setVisible(false)
                                        end)

                                        self.m_jpBarJinBi:runCsbAction("over",false,function(  )
                                            self.m_jpBarJinBi:setVisible(false)
                                        end)

                                        waitNode:removeFromParent()
            
                                    end,30/30)
        
                                end,15/30)

                            end,10/30)

                        end,25/30)
        
                    end,15/30)

                end,15/30)

            end,15/30)

        end,30/30)

    end)

    

end

function CodeGameScreenHalosandHornsMachine:getSlotNodeWithPosAndType(symbolType , row, col ,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    self:createRiseTuoWeiNode(reelNode)

    return reelNode
end



function CodeGameScreenHalosandHornsMachine:removeRiseTuoWeiNode(_symbolNode )
    local riseTuoWeiNode = _symbolNode:getChildByName("devilRiseTuoWei")
    if riseTuoWeiNode then
        riseTuoWeiNode:removeFromParent()
    end 
    
end

function CodeGameScreenHalosandHornsMachine:createRiseTuoWeiNode(_symbolNode )
    

    if self.m_isOutLines then
        return
    end

    if _symbolNode then
        self:removeRiseTuoWeiNode(_symbolNode )
        if _symbolNode.p_symbolType == self.SYMBOL_DEVIL_RISE then  
            local riseTuoWei = util_createAnimation("HalosandHorns_tuoweiA.csb")
            _symbolNode:addChild(riseTuoWei,-10)
            riseTuoWei:findChild("Sprite_tianshi"):setVisible(false)
            riseTuoWei:setName("devilRiseTuoWei")
            riseTuoWei:runCsbAction("idle",true) 
        end
        

    end
end


---
--添加金边
function CodeGameScreenHalosandHornsMachine:creatReelRunAnimation(col)
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
    local row = self.m_currentReelRow[col]
    reelEffectNode:setScaleY(self.m_LongRunScale[row]/100)
    
    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end



function CodeGameScreenHalosandHornsMachine:initColumnMaxRewards( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local betColumnMaxRewards = selfdata.betColumnMaxRewards

    if betColumnMaxRewards then
        self.m_betColumnMaxRewards = betColumnMaxRewards
    end
    
   
end

function CodeGameScreenHalosandHornsMachine:updateColumnMaxRewards( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local columnMaxRewards = selfdata.columnMaxRewards 
    if columnMaxRewards then
        local betIdx = globalData.slotRunData:getCurBetIndex()
        self.m_betColumnMaxRewards[tostring(betIdx)] = columnMaxRewards
    end
end


function CodeGameScreenHalosandHornsMachine:updateCurrentColumnMaxReward( )

    local betIdx = globalData.slotRunData:getCurBetIndex()
    local columnMaxReward = self.m_betColumnMaxRewards[tostring(betIdx)]

    if columnMaxReward then
        self.m_columnMaxReward = columnMaxReward
    else
        self.m_columnMaxReward = self:getRodamTopReword( )
    end

end

function CodeGameScreenHalosandHornsMachine:initColumnRows( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local betColumnRows = selfdata.betColumnRows

    if betColumnRows then
        self.m_betColumnRows = betColumnRows
    end 


    
end

function CodeGameScreenHalosandHornsMachine:updateColumnRows( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local columnRows = selfdata.columnRows 
    if columnRows then
        local betIdx = globalData.slotRunData:getCurBetIndex()
        self.m_betColumnRows[tostring(betIdx)] = columnRows
    end
end


function CodeGameScreenHalosandHornsMachine:updateCurrentReelRow( )

    local betIdx = globalData.slotRunData:getCurBetIndex()
    local columnRow = self.m_betColumnRows[tostring(betIdx)]

    if columnRow then
        self.m_currentReelRow = columnRow
    else
        self.m_currentReelRow =  self:getRodamReelRow( )
    end

end
-- 根据算法确定当前bet的reel行信息
function CodeGameScreenHalosandHornsMachine:getRodamReelRow( )
    
    local currRow = {}
    local baseRow = {3,4,4,5,6}
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local Y = math.fmod( totalBet,23 ) 

    if math.fmod(Y,2) == 0 then
        -- 偶数
        currRow[3] = 4
        for i=#baseRow,1,-1 do
            if baseRow[i] == 4 then
                table.remove( baseRow, i)
                break
            end
        end
    else
        -- 奇数
        currRow[3] = 3
        for i=#baseRow,1,-1 do
            if baseRow[i] == 3 then
                table.remove( baseRow, i)
                break
            end
        end
    end

    table.sort( baseRow, function(a, b)
        return a > b
    end )

    local otherY = math.fmod( totalBet,7 ) 

    local insterCol = {}

    if otherY == 0 then -- 对应列数
        insterCol = {2,1,5,4}
    elseif otherY == 1 then
        insterCol = {1,2,4,5}
    elseif otherY == 2 then
        insterCol = {5,4,1,2}
    elseif otherY == 3 then
        insterCol = {4,5,1,2}
    elseif otherY == 4 then
        insterCol = {1,4,5,2}
    elseif otherY == 5 then
        insterCol = {4,1,2,5}
    elseif otherY == 6 then
        insterCol = {1,4,2,5}
    end
    
    for i=1,#insterCol do
        local currCol = insterCol[i]
        currRow[currCol] = baseRow[i] 
    end


    return currRow,Y
end
-- 跟局算法确实当前bet的topBonus信息
function CodeGameScreenHalosandHornsMachine:getRodamTopReword( )
    
    local topRewordData = {}

    topRewordData[3] = "GRAND"

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local Y = tonumber(math.fmod( totalBet,23 ) ) 
    local X = tonumber(math.fmod( totalBet,17 ) ) 
    local currNum = tonumber(math.fmod( X,4 ) ) 

    local lastCol = {1,2,4,5}

    local bonusCol = nil
    if currNum == 0 then
        topRewordData[1] = "FREE"
        bonusCol = 1
    elseif currNum == 1 then
        topRewordData[2] = "FREE"
        bonusCol = 2
    elseif currNum == 2 then
        topRewordData[4] = "FREE"
        bonusCol = 4
    elseif currNum == 3 then
        topRewordData[5] = "FREE"
        bonusCol = 5
    end

    local num_1 = bonusCol + 1
    if num_1 > 5 then
        num_1 = 1
    end
    if num_1 == 3 then
        num_1 = 4
    end

    if 0 <=  X and X <= 4 then
        topRewordData[num_1] = "5"
    elseif 5 <= X and X <= 7 then
        topRewordData[num_1] = "6"
    elseif 8 <= X and X <= 10 then
        topRewordData[num_1] = "8"
    elseif 11 <= X and X <= 12 then
        topRewordData[num_1] = "10"
    elseif 13 <= X and X <= 14 then
        topRewordData[num_1] = "15"
    elseif X == 15 then
        topRewordData[num_1] = "20"
    elseif X >= 16 then
        topRewordData[num_1] = "30"
    end

    

    local num_2 = num_1 + 1
    if num_2 > 5 then
        num_2 = 1
    end
    if num_2 == 3 then
        num_2 = 4
    end

    local cutX = math.abs( X - 9 ) 

    if 0 <= cutX and cutX <= 4 then
        topRewordData[num_2] = "5"
    elseif 5 <= cutX and cutX <= 7 then
        topRewordData[num_2] = "6"
    elseif 8 <= cutX and cutX <= 10 then
        topRewordData[num_2] = "8"
    elseif 11 <= cutX and cutX <= 12 then
        topRewordData[num_2] = "10"
    elseif 13 <= cutX and cutX <= 14 then
        topRewordData[num_2] = "15"
    elseif cutX == 15 then
        topRewordData[num_1] = "20"
    elseif cutX >= 16 then
        topRewordData[num_2] = "30"
    end


    local num_3 = num_2 + 1

    if num_3 > 5 then
        num_3 = 1
    end
    if num_3 == 3 then
        num_3 = 4
    end

    if 0 <= Y and Y <= 5 then
        topRewordData[num_3] = "5"
    elseif 6 <= Y and Y <= 11 then
        topRewordData[num_3] = "6"
    elseif 12 <= Y and Y <= 15 then
        topRewordData[num_3] = "8"
    elseif 16 <= Y and Y <= 17 then
        topRewordData[num_3] = "10"
    elseif 18 <= Y and Y <= 19 then
        topRewordData[num_3] = "15"
    elseif 20 <= Y and Y <= 21 then
        topRewordData[num_3] = "20"
    elseif Y >= 22 then
        topRewordData[num_3] = "30"
    end



    return topRewordData
end

function CodeGameScreenHalosandHornsMachine:getCurrLinesNum( )
    local linesNum = 1
    for iCol=1,#self.m_LinesReelRow do
        local row = self.m_LinesReelRow[iCol]
        linesNum = linesNum * row
    end
    return linesNum
end


function CodeGameScreenHalosandHornsMachine:updateLinesNumFromRow(_iCol,_iRow )

    self.m_LinesReelRow[_iCol] = _iRow

    local linesNum = 1
    for iCol=1,#self.m_LinesReelRow do
        if iCol ~= _iCol then
            local row = self.m_LinesReelRow[iCol]
            linesNum = linesNum * row 
        end
        
    end
    linesNum = linesNum * _iRow
    local str = util_AutoLineWrap(tostring(linesNum)) 
   
    self:findChild("HalosandHorns_m_lb_conis"):setString(str)
    
end

function CodeGameScreenHalosandHornsMachine:updateLinesNum( )
    local linesNum = 1
    for iCol=1,#self.m_currentReelRow do
        local row = self.m_currentReelRow[iCol]
        linesNum = linesNum * row
        self.m_LinesReelRow[iCol] = row
    end
    
    local str = util_AutoLineWrap(tostring(linesNum)) 
   
    self:findChild("HalosandHorns_m_lb_conis"):setString(str)
    
end

function CodeGameScreenHalosandHornsMachine:checkEffectiveRow(_iCol,_iRow )
    
    local row = self.m_currentReelRow[_iCol]
    if _iRow <= row then
        return true
    end
end

function CodeGameScreenHalosandHornsMachine:playCustomSpecialSymbolDownAct( slotNode )

    CodeGameScreenHalosandHornsMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType == self.SYMBOL_DEVIL_RISE  then


        if self:checkEffectiveRow(slotNode.p_cloumnIndex,slotNode.p_rowIndex ) then

            local soundPath = "HalosandHornsSounds/HalosandHornsSounds_TriggerBonusDown.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

            slotNode:runAnim("buling")
        end

            
        
        local devilRiseTuoWei = slotNode:getChildByName("devilRiseTuoWei")
        if devilRiseTuoWei then
            devilRiseTuoWei:runCsbAction("actionframe")
        end

    elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        
        local isShowBuling = false
        if slotNode.p_cloumnIndex == self.COL_2 then
            if self:getOneColScatterFullShowNum( self.COL_2 ) >= self.COL_3  then
                isShowBuling = true
            end
        elseif slotNode.p_cloumnIndex == self.COL_3 then
            
            if self:getOneColScatterFullShowNum( self.COL_2 ) >= self.COL_3 then
                if self:getOneColScatterFullShowNum( self.COL_3 ) >= self.COL_3 then
                    isShowBuling = true
                end
            end
            
        elseif slotNode.p_cloumnIndex == self.COL_4 then

            if self:getOneColScatterFullShowNum( self.COL_4 ) >= self.COL_3 then
                if self:getOneColScatterFullShowNum( self.COL_3 ) >= self.COL_3 then
                    if self:getOneColScatterFullShowNum( self.COL_2 ) >= self.COL_3 then
                        isShowBuling = true
                    end
                end
            end
    
        end
        

        if self:checkEffectiveRow(slotNode.p_cloumnIndex,slotNode.p_rowIndex ) then
            if isShowBuling then

                local soundPath = "HalosandHornsSounds/HalosandHornsSounds_TriggerBonusDown.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

                slotNode:runAnim("buling")
            end
        end

        
        
    end
    

    
end

function CodeGameScreenHalosandHornsMachine:beginReel()
    if  self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:resetReelDataAfterReel()
        
        self.m_miniReel:beginReel()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)
    else

        BaseSlotoManiaMachine.beginReel(self)
        
    end
end

function CodeGameScreenHalosandHornsMachine:quicklyStopReel(colIndex)
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseSlotoManiaMachine.quicklyStopReel(self, colIndex) 
    end
    
end

function CodeGameScreenHalosandHornsMachine:restSelfGameEffects( restType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return 
                end
                
            end

        end
    end
    
end

---
-- 处理spin 返回结果
function CodeGameScreenHalosandHornsMachine:spinResultCallFun(param)


    BaseSlotoManiaMachine.spinResultCallFun(self,param)

    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then


        if param[1] == true then
            local spinData = param[2]
            if spinData.result then
                self.m_miniReel:netWorkCallFun(spinData.result)
            end
        end
    end
    
 
end

--服务端网络数据返回成功后处理
function CodeGameScreenHalosandHornsMachine:MachineRule_afterNetWorkLineLogicCalculate()
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
    

end

function CodeGameScreenHalosandHornsMachine:updateOneZhuZiLevel( _iCol,_currRow )

    local ZhuZi = self["DevilZhuZi_".._iCol] 
    if ZhuZi then

        ZhuZi:findChild("Node_fen"):setVisible(false)
        ZhuZi:findChild("Node_lan"):setVisible(false)
        ZhuZi:findChild("Node_hong"):setVisible(false)

  
        if _currRow == self.ZhuZi_level_1 then
            ZhuZi:findChild("Node_fen"):setVisible(true)
        elseif _currRow == self.ZhuZi_level_2 then
            ZhuZi:findChild("Node_lan"):setVisible(true)
        elseif _currRow >= self.ZhuZi_level_3 then
            ZhuZi:findChild("Node_hong"):setVisible(true)
        else
            print("全部不显示")
        end

    end
      
    
end

function CodeGameScreenHalosandHornsMachine:playOneZhuZiTishiguang(_iCol )
    local zhuZiTishiguang = self["DevilZhuZi_tishiguang_".._iCol] 
    if zhuZiTishiguang then
        zhuZiTishiguang:setVisible(true)
        zhuZiTishiguang:runCsbAction("actionframe",false,function(  )
            zhuZiTishiguang:setVisible(false)
        end)
    end


end

function CodeGameScreenHalosandHornsMachine:showTopBonusCollect(_startNode,_endNode,_func)
    
    
    _startNode:setVisible(false)

    local csbName = "Socre_HalosandHorns_bonus_1"
    if _startNode.m_type and _startNode.m_type == self.BONUS_TOP_TYPE_COINS_ZI  then
        csbName = "Socre_HalosandHorns_bonus_2"
    end

    local tuoWei =  util_createAnimation(csbName..".csb") 
    self:addChild(tuoWei,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    tuoWei:runCsbAction("actionframe")

    local lab_1 = _startNode:findChild("m_lb_coins_1")
    local lab_2 = tuoWei:findChild("m_lb_coins_1")
    local lab_3 = tuoWei:findChild("m_lb_coins_2") 
    if lab_1 and lab_2 then
        lab_2:setString(lab_1:getString())
    end
    if lab_3 then
        lab_3:setVisible(false)
    end

    local worldPos = _startNode:getParent():convertToWorldSpace(cc.p(_startNode:getPosition()))
    local startPos = tuoWei:getParent():convertToNodeSpace(worldPos)
    tuoWei:setPosition(startPos)

    local worldPos = _endNode:getParent():convertToWorldSpace(cc.p(_endNode:getPosition()))
    local endPos = tuoWei:getParent():convertToNodeSpace(worldPos)

    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(1.4)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        _startNode:setVisible(true)
    end)
    
    actList[#actList + 1] = cc.MoveTo:create(0.5,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if _func then
            _func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    tuoWei:runAction(sq)

end


------------------------------------------------设置快滚  长条scatter 不能算多个scatter
---

function CodeGameScreenHalosandHornsMachine:getOneColScatterFullShowNum( _iCol )
    local scatterNum = 0
    
    for iRow=1,self.m_currentReelRow[_iCol] do

        local symbolType = self.m_stcValidSymbolMatrix[iRow][_iCol]
        
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterNum = scatterNum + 1
        end

        if scatterNum >= self.SCATTER_SYMBOL_SIZE then
            break
        end
    end

    return scatterNum
end

function CodeGameScreenHalosandHornsMachine:getScatterTriggerCol( )


    local scatterNum_col_2 = self:getOneColScatterFullShowNum( self.COL_2 )
    local scatterNum_col_3 = self:getOneColScatterFullShowNum( self.COL_3 )
  
    if scatterNum_col_2 >= self.SCATTER_SYMBOL_SIZE and scatterNum_col_3 >= self.SCATTER_SYMBOL_SIZE then
        return self.COL_4
    end
 

    return nil

end

--根据关卡玩法重新设置滚动信息
function CodeGameScreenHalosandHornsMachine:MachineRule_ResetReelRunData()

    local triggerCol = self:getScatterTriggerCol()

    if triggerCol  then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local reelLongRunTime = 1.5

            if iCol >= triggerCol and iCol < self.m_iReelColumnNum then
                local iRow = columnData.p_showGridCount

                local lastColLens = reelRunInfo[1]:getReelRunLen()
                if iCol ~= 1 then
                    lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                    reelRunInfo[iCol - 1]:setNextReelLongRun(true)
                end

                local colHeight = columnData.p_slotColumnHeight
                local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                local runLen = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高

                local preRunLen = reelRunData:getReelRunLen()
                reelRunData:setReelRunLen(runLen)

                if triggerCol ~= iCol then
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
                end
            else
                if iCol == self.m_iReelColumnNum  then
                    local lastColLens = reelRunInfo[iCol -1]:getReelRunLen()
                    local preRunLen = reelRunInfo[iCol].initInfo.reelRunLen
                    local pretriggerColRunLen = reelRunInfo[triggerCol].initInfo.reelRunLen
                    local addRunLen = preRunLen - pretriggerColRunLen

                    reelRunData:setReelRunLen(lastColLens + addRunLen)
                    reelRunData:setReelLongRun(false)
                    reelRunData:setNextReelLongRun(false)
                end
                
            end
        end
    end

    self:setLastReelSymbolList()
end

function CodeGameScreenHalosandHornsMachine:initHasFeature( )

    if  self:getCurrSpinMode() == FREE_SPIN_MODE then
        BaseSlotoManiaMachine.initNoneFeature( self)
    else
        BaseSlotoManiaMachine.initHasFeature( self)
    end

end


function CodeGameScreenHalosandHornsMachine:checkNotifyUpdateWinCoin( )


    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return -- free 下利用小轮盘的更新钱数
    end


    local winLines = self.m_reelResultLines

    if #winLines <= 0  then -- 没有连线不更新钱
        return
    end

    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local coins = 0
    local specialCoins =  self:getSpecialWinCoins()
    
    local beiginCoins = specialCoins

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop,nil,beiginCoins})
    globalData.slotRunData.lastWinCoin = lastWinCoin

end

function CodeGameScreenHalosandHornsMachine:getSpecialWinCoins( )
    return self.m_top_bonus_reword_coins 
end


function CodeGameScreenHalosandHornsMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )


    local winLines = self.m_reelResultLines

    if self.m_triggerCurrNum  >= self.m_triggerColNum then
        if not isNotifyUpdateTop then
            if #winLines <= 0  then -- 没有连线更新钱
                isNotifyUpdateTop = true
            end
        end
    end

    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    
    local endCoins = currCoins + beiginCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,isNotifyUpdateTop,nil,beiginCoins})
    globalData.slotRunData.lastWinCoin = lastWinCoin

    self:showWinEffect( )
    
    self.m_top_bonus_reword_coins = endCoins

end

--绘制多个裁切区域
function CodeGameScreenHalosandHornsMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1000000)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)

        local clipControlNode = cc.Node:create()
        clipNode:addChild(clipControlNode)
        clipControlNode:setName("clipControlNode")

        clipControlNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
    
        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")
        
        
    end
end


---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenHalosandHornsMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end

            end
        end

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)

            if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
               
                    
                if slotNode.p_bigSymbolMaskNode then
                    slotNode.p_bigSymbolMaskNode:setPositionY( - 10)
                    local ccAnimNode = slotNode.p_bigSymbolMaskNode:getChildren()
                    if ccAnimNode and ccAnimNode[1] then
                        ccAnimNode[1]:setPositionY( 10)
                    end
                    local clipNode_CurrentRect = slotNode.p_bigSymbolMaskNode:getClippingRegion()
                    slotNode.p_bigSymbolMaskNode:setClippingRegion(
                            {
                                x = clipNode_CurrentRect.x,
                                y = clipNode_CurrentRect.y,
                                width = clipNode_CurrentRect.width,
                                height = clipNode_CurrentRect.height + 20
                            }
                        )
                end
                
            end

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenHalosandHornsMachine:showWinEffect( )
    
    self:playCoinWinEffectUI()
    
    -- self.m_winEffect:setVisible(true)
    -- self.m_winEffect:findChild("Particle_1"):resetSystem()
    -- self.m_winEffect:runCsbAction("actionframe",false,function(  )
    --     self.m_winEffect:setVisible(false)
    -- end)
end

-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function CodeGameScreenHalosandHornsMachine:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )
    
    if symbolType == self.SYMBOL_DEVIL_RISE  or symbolType == self.SYMBOL_ANGEL_DECLINE  then
        symbolType = 5
    end

    return symbolType
end

function CodeGameScreenHalosandHornsMachine:checkIsAddLastWinSomeEffect( )
    
    -- local notAdd  = false

    -- if #self.m_vecGetLineInfo == 0 then
    --     notAdd = true
    -- end

    -- local specialCoins =  self:getSpecialWinCoins()
    -- if specialCoins and specialCoins > 0 then
    --     notAdd = false
    -- end

    return false
end

function CodeGameScreenHalosandHornsMachine:showEffect_LineFrame(effectData)


    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        
        local lineLen = #self.m_reelResultLines
        self.m_scatterLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                self.m_scatterLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end
    
       BaseSlotoManiaMachine.showEffect_LineFrame(self,effectData)
       
    end
    

   

    return true

end

---
-- 显示free spin
function CodeGameScreenHalosandHornsMachine:showEffect_FreeSpin(effectData)

    self.m_reelResultLines[#self.m_reelResultLines + 1] = self.m_scatterLineValue

    BaseSlotoManiaMachine.showEffect_FreeSpin(self,effectData)
    return true
end

---
--添加连线动画
function CodeGameScreenHalosandHornsMachine:addLineEffect()

    for i = 1, #self.m_reelResultLines do
        local lineValue = self.m_reelResultLines[i]
        if not lineValue.enumSymbolType then

            print("CodeGameScreenHalosandHornsMachine ------- lineValue.enumSymbolType 为空")
            release_print("CodeGameScreenHalosandHornsMachine ------- lineValue.enumSymbolType 为空")
            if lineValue.vecValidMatrixSymPos then
                print(json.encode(lineValue.vecValidMatrixSymPos))
                release_print(json.encode(lineValue.vecValidMatrixSymPos))
            else
                print("CodeGameScreenHalosandHornsMachine------- lineValue.vecValidMatrixSymPos 为空")
            end

            if lineValue.enumSymbolEffectType then
                print(" CodeGameScreenHalosandHornsMachine enumSymbolEffectType________  ".. lineValue.enumSymbolEffectType )
                release_print(" CodeGameScreenHalosandHornsMachine enumSymbolEffectType________  ".. lineValue.enumSymbolEffectType )
            else
                print("CodeGameScreenHalosandHornsMachine ------- lineValue.enumSymbolEffectType 为空")
            end
            
        end
    end

    CodeGameScreenHalosandHornsMachine.super.addLineEffect(self)
end

return CodeGameScreenHalosandHornsMachine






