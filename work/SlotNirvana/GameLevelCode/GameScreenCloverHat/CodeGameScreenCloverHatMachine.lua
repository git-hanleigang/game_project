---
-- island li
-- 2019年1月26日
-- CodeGameScreenCloverHatMachine.lua
-- 
-- 玩法：
-- 
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCloverHatMachine = class("CodeGameScreenCloverHatMachine", BaseNewReelMachine)

CodeGameScreenCloverHatMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCloverHatMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenCloverHatMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenCloverHatMachine.SYMBOL_SCATTER_SILVER = 191 -- 银scatter
CodeGameScreenCloverHatMachine.SYMBOL_SCATTER_GOLD = 192 -- 金scatter

CodeGameScreenCloverHatMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 51 -- 收集
CodeGameScreenCloverHatMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 集满bonus
CodeGameScreenCloverHatMachine.FS_ADD_TIMES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 49 -- fs 加次数
CodeGameScreenCloverHatMachine.LOCK_IN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 48 -- lock in 更新框
CodeGameScreenCloverHatMachine.LOCK_IN_WIN_COINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 47 -- lock in 最高档变jackpot
CodeGameScreenCloverHatMachine.LOCK_IN_WIN_FREE_OVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 46 -- lock in freespin 最后一次

CodeGameScreenCloverHatMachine.m_scatterAllLockNode = {}

CodeGameScreenCloverHatMachine.m_collectList = {}
CodeGameScreenCloverHatMachine.m_bonusData = {}

CodeGameScreenCloverHatMachine.m_iReelMinRow = 3
CodeGameScreenCloverHatMachine.m_iReelMaxRow = 4

CodeGameScreenCloverHatMachine.m_bCanClickMap = nil
CodeGameScreenCloverHatMachine.m_bSlotRunning = nil

CodeGameScreenCloverHatMachine.m_LastTurnfsWinCoins = 0

CodeGameScreenCloverHatMachine.MAXROW_REEL_SCALE = 0.87
CodeGameScreenCloverHatMachine.MAXROW_REEL_POS_Y = -40

CodeGameScreenCloverHatMachine.MAIN_REEL_ADD_POS_Y = 10

CodeGameScreenCloverHatMachine.WINTYPE_GREEN = 1
CodeGameScreenCloverHatMachine.WINTYPE_SILVER = 2
CodeGameScreenCloverHatMachine.WINTYPE_GOLD = 3

CodeGameScreenCloverHatMachine.BASE_FS_RUN_STATES = 0
CodeGameScreenCloverHatMachine.COllECT_FS_RUN_STATES = 1

CodeGameScreenCloverHatMachine.m_quickStop = false

CodeGameScreenCloverHatMachine.m_superFreeSpinStart = false

-- 构造函数
function CodeGameScreenCloverHatMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_scatterAllLockNode = {}
    self.m_collectList = {}
    self.m_bonusData = {}
    self.m_LastTurnfsWinCoins = 0
    self.m_quickStop = false
    self.m_superFreeSpinStart = false

    self.m_betLevel = nil

    self.m_isFeatureOverBigWinInFree = true
	--init
	self:initGame()
end

function CodeGameScreenCloverHatMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCloverHatMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CloverHat"  
end

function CodeGameScreenCloverHatMachine:showColorLayer( )
    for i=1,5 do

        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]

        util_playFadeInAction(layerNode,0.1)
        layerNode:setVisible(true)
    end
end

function CodeGameScreenCloverHatMachine:hideColorLayer( )
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]
        util_playFadeOutAction(layerNode,0.1)
        layerNode:setVisible(true)
        performWithDelay(self["m_colorLayer_waitNode_"..i] ,function(  )
            layerNode:setVisible(false)
        end,0.1)
    end
end


function CodeGameScreenCloverHatMachine:initUI()

    

    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100 ,cc.c3b(0, 0, 0),200 )

    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])

        self["colorLayer_"..i] = colorLayers[i]
    end

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_gameBg:runCsbAction("normal",true)
    self.m_gameBg:setAutoScaleEnabled(false)

    for i=1,3 do
        local node = self.m_gameBg:findChild("Node_hudie_"..i)
        if node then
            local hudie = util_createAnimation("CloverHat_hudie.csb")
            node:addChild(hudie)
            hudie:runCsbAction("actionframe",true)
        end
    end

    self:findChild("fsMoreBg"):setVisible(false)
    self:findChild("fsMoreBg"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1 )


    self.m_mapZhezaho = util_createAnimation("CloverHat_Map_zhezhao.csb")
    self:findChild("bg"):addChild(self.m_mapZhezaho,1000)
    self.m_mapZhezaho:setVisible(false)
    
    self:findChild("map"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 30 )
    self:findChild("JACKPOT"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 28 )
    self:findChild("CloverHat_progress"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 27 )
    self:findChild("Node_LockKuang"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 26 )
   
    self:findChild("Node_ShowAddWild"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 24 )

    self.m_slotEffectLayer:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 40)

    self.collectTipView = util_createAnimation("CloverHat_Map_baozang_tanban.csb")
    self.m_clipParent:addChild(self.collectTipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 31 )
    self.collectTipView.m_states = nil

    local collectTipViewWorldPos = self:findChild("showTipView"):getParent():convertToWorldSpace(cc.p(self:findChild("showTipView"):getPosition()))
    local collectTipViewPos = self.m_clipParent:convertToNodeSpace(collectTipViewWorldPos)
    self.collectTipView:setPosition(collectTipViewPos)
    self.collectTipView:setVisible(false)

    self.m_JackPotBar = util_createView("CodeCloverHatSrc.CloverHatJackPotBarView")
    self:findChild("JACKPOT"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self)

    self.m_progress = util_createView("CodeCloverHatSrc.CloverHatBonusProgress")
    -- self:findChild("CloverHat_progress"):addChild(self.m_progress)
    self.m_progress:setPosition(self:findChild("CloverHat_progress"):getPosition())
    self.m_clipParent:addChild(self.m_progress, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2+101)
    
    

    self.m_GuoChangJinBi = util_createAnimation("CloverHat_guochang_jinbi.csb")
    self.m_GuoChangJinBi:setPosition(display.width/2,display.height/2)
    self:addChild(self.m_GuoChangJinBi,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 3)
    self.m_GuoChangJinBi:setVisible(false)

    self.m_guochangLizi = util_createAnimation("CloverHat_guochang_siyecao.csb")
    self.m_guochangLizi:setPosition(display.width/2,display.height/2)
    self:addChild(self.m_guochangLizi,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 4)
    self.m_guochangLizi:setVisible(false)

    
    self.m_wildRandom = util_spineCreate("CloverHat_Wild_Random",true,true)
    self.m_clipParent:addChild(self.m_wildRandom,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    local pos = util_getConvertNodePos(self:findChild("Node_ShowAddWild"),self.m_wildRandom)
    self.m_wildRandom:setPosition(pos)
    self.m_wildRandom:setVisible(false)

    self.m_superFsWildRandom = util_spineCreate("CloverHat_Superfreegame",true,true)
    self.m_clipParent:addChild(self.m_superFsWildRandom,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    local pos = util_getConvertNodePos(self:findChild("Node_ShowAddWild"),self.m_superFsWildRandom)
    self.m_superFsWildRandom:setPosition(pos)
    self.m_superFsWildRandom:setVisible(false)

    self.m_superFsWildRandom_row4 = util_spineCreate("CloverHat_Superfreegame_4",true,true)
    self.m_clipParent:addChild(self.m_superFsWildRandom_row4,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    local pos = util_getConvertNodePos(self:findChild("Node_ShowAddWild"),self.m_superFsWildRandom_row4)
    self.m_superFsWildRandom_row4:setPosition(pos)
    self.m_superFsWildRandom_row4:setVisible(false)


    self.m_wildRandomBg = util_createAnimation("Socre_CloverHat_Wild_heiZZ.csb")
    self.m_clipParent:addChild(self.m_wildRandomBg,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    local pos = util_getConvertNodePos(self:findChild("Node_ShowAddWild"),self.m_wildRandomBg)
    self.m_wildRandomBg:setPosition(pos)
    self.m_wildRandomBg:setVisible(false)

    self.m_wildRandomBg_fourRow = util_createAnimation("Socre_CloverHat_Wild_heiZZ_4.csb")
    self.m_clipParent:addChild(self.m_wildRandomBg_fourRow,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    local pos = util_getConvertNodePos(self:findChild("Node_ShowAddWild"),self.m_wildRandomBg_fourRow)
    self.m_wildRandomBg_fourRow:setPosition(pos)
    self.m_wildRandomBg_fourRow:setVisible(false)

    self:restBaseMainUI()

    local node_bar = self.m_bottomUI.coinWinNode
    self.m_jiesuanAct = util_createAnimation("CloverHat_jiesuanLizi.csb")
    node_bar:addChild(self.m_jiesuanAct)
    self.m_jiesuanAct:setVisible(false)

    self.m_FsLockWildNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_FsLockWildNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

    self.m_BaseLockWildNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_BaseLockWildNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "CloverHatSounds/music_CloverHat_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenCloverHatMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "CloverHatSounds/music_CloverHat_enter.mp3" )

    end,0.4,self:getModuleName())
end


function CodeGameScreenCloverHatMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local pecent =  self:getProgressPecent()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local PickGame = selfData.PickGame 
    if PickGame then
        if PickGame == "FreeGame" then
            print("pick Free 等 free结束在重置进度条")
        else
            pecent = 0 -- 完成pick小游戏断线 重置为 0 
        end
    end
    

    self.m_progress:setPercent(pecent)
 
    self:createMapScroll( )


    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:showMapTipView( )
    end

    self:upateBetLevel()
end

function CodeGameScreenCloverHatMachine:hideMapTipView( _close )

    if self.collectTipView.m_states == "idle" then

        self.collectTipView.m_states = "over"
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)
            
    end

    if _close then
        self.collectTipView:setVisible(false)
        self.collectTipView.m_states = "over"
        self.collectTipView:runCsbAction("over",false,function(  )
            self.collectTipView.m_states = "idle"
            self.collectTipView:setVisible(false)
        end)
    end
        

end

function CodeGameScreenCloverHatMachine:clickMapTipView( )
    


    if self.m_map:getMapIsShow() ~= true and self.m_bSlotRunning ~= true then

        if not self.collectTipView:isVisible() then
            self:showMapTipView( )
        else    
            self:hideMapTipView( )
        end

    end

    

end

function CodeGameScreenCloverHatMachine:showMapTipView( )
    

        
    if self:isNormalStates( ) then
        if self.collectTipView.m_states == nil or  self.collectTipView.m_states == "idle" then

            self.collectTipView:setVisible(true)
                self.collectTipView.m_states = "start"
                self.collectTipView:runCsbAction("start",false,function(  )
                    self.collectTipView.m_states = "idle"
    
                end)
                
        end
    end

    

 
    
end

function CodeGameScreenCloverHatMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)

        if self:isNormalStates( )  then
            if self.m_betLevel == 0 then
                self:unlockHigherBet()
            else
                self:showMapScroll(nil,true)
            end
        end
    end,"SHOW_BONUS_MAP")

    gLobalNoticManager:addObserver(self,function(self,params)
        
        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
            self:clickMapTipView()
        end
        
    end,"SHOW_BONUS_Tip")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end



function CodeGameScreenCloverHatMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end


    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCloverHatMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_CloverHat_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_CloverHat_11"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_CloverHat_Scatter_green"
    elseif symbolType == self.SYMBOL_SCATTER_SILVER then
        return "Socre_CloverHat_Scatter_yin"
    elseif symbolType == self.SYMBOL_SCATTER_GOLD then
        return "Socre_CloverHat_Scatter_gold"
    end
    
    return nil
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCloverHatMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""
        local selectReel = fsExtraData.selectReel or ""

        self:changeMainUI( self.m_iReelMinRow)

        if FreeType == "NormalFree" then
            self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES

            self:updateScatterLockKuang( nil ,true )

        elseif FreeType == "PickFree" then

            self:setFsBackGroundMusic("CloverHatSounds/CloverHat_mapBG.mp3")--fs背景音乐

            self.m_fsReelDataIndex = self.COllECT_FS_RUN_STATES

            self.m_bottomUI:showAverageBet()

            if selectReel == "maprow4" then
                self:changeMainUI( self.m_iReelMaxRow )
                self.m_iReelRowNum = self.m_iReelMaxRow
                self:changeReelData()
            end
            
            self:initSupperWildNode()

        end
    end

    

end

--
--单列滚动停止回调
--
function CodeGameScreenCloverHatMachine:slotOneReelDown(reelCol)   


    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCloverHatMachine:levelFreeSpinEffectChange()

    self.m_gameBg:runCsbAction("freespin",true)
 
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCloverHatMachine:levelFreeSpinOverChangeEffect()
    
    self.m_gameBg:runCsbAction("normal",true)
end
---------------------------------------------------------------------------


----------- FreeSpin相关

function CodeGameScreenCloverHatMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    local path = BaseDialog.DIALOG_TYPE_FREESPIN_START
    local imgName = nil
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    local selectReel = fsExtraData.selectReel or ""
    local fixPos = fsExtraData.fixPos or {}

    if FreeType == "PickFree" then
        path = "SuperFreeSpinStart"

        if selectReel == "maprow4" then
            path = "SuperFreeSpinStart_sihang"
        end

    end

    ownerlist["m_lb_num"]=num
    local view =  self:showDialog(path,ownerlist,func)

    if FreeType == "PickFree" then
        if selectReel == "maprow4" then
            imgName = "CloverHat_wild_img_"
            view:findChild("Node_Row_3"):setVisible(false)
            view:findChild("Node_Row_4"):setVisible(true)
        else
            imgName = "CloverHat_wild_img_3_"
            view:findChild("Node_Row_3"):setVisible(true)
            view:findChild("Node_Row_4"):setVisible(false)
        end

        local maxImgNum = 20
        for i=1,maxImgNum do
            local img = view:findChild(imgName .. i - 1) 
            if img then
                img:setVisible(false)
            end
        end
    
        for i=1,#fixPos do
            local img = view:findChild(imgName .. fixPos[i]) 
            if img then
                img:setVisible(true)
            end
        end
    end
    


    return view
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end


--获取播放连线动画时的层级
function CodeGameScreenCloverHatMachine:getSlotNodeEffectZOrder(slotNode)

     

    return SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 28 + 1
end

-- FreeSpinstart
function CodeGameScreenCloverHatMachine:showFreeSpinView(effectData)

    self:hideMapTipView(true)
    
    self:removeAllBaseLockWildNode( )

    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_fs_StartView.mp3")
   
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
        self:changeViewScale( view )
    else

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""
        local selectReel = fsExtraData.selectReel or ""

        self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
        
        if FreeType == "PickFree" then

            self:setFsBackGroundMusic("CloverHatSounds/CloverHat_mapBG.mp3")--fs背景音乐

            self.m_superFreeSpinStart = true

            self.m_fsReelDataIndex = self.COllECT_FS_RUN_STATES
            

            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            if fsWinCoin ~= 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
            else
                self.m_bottomUI:updateWinCount("")
            end

            self:levelFreeSpinEffectChange()

            self:changeMainUI( self.m_iReelMinRow )

            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            if fsWinCoin ~= 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
            else
                self.m_bottomUI:updateWinCount("")
            end

            self.m_bottomUI:showAverageBet()
            if selectReel == "maprow4" then
                self:changeMainUI( self.m_iReelMaxRow )
                self.m_iReelRowNum = self.m_iReelMaxRow
                self:changeReelData()
            end

            self:initSupperWildNode()

            local childs =  self.m_FsLockWildNode:getChildren()
            for i=1,#childs do
                local node = childs[i]
                if node then
                    node:setVisible(false)
                end
            end

            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()  

            end)

            self:changeViewScale( view )
            

        else

            self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES

            self:showGuoChangLizi(function(  )

                local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
                if fsWinCoin ~= 0 then
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
                else
                    self.m_bottomUI:updateWinCount("")
                end

                self:levelFreeSpinEffectChange()

                self:changeMainUI( self.m_iReelMinRow )

                
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                     
                        local isUpdata = self:updateScatterLockKuang(function(  )
                        
                            
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()  
        
                        end)

                        if isUpdata then
                            gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_ScatterLockKuang.mp3")
                        end
    
                end)
                self:changeViewScale( view )
            end)
        end

    end


end

function CodeGameScreenCloverHatMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)

    local path = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    local selectReel = fsExtraData.selectReel or ""

    if FreeType == "PickFree" then
        path = "SuperFreeSpinOver"
        if selectReel == "maprow4" then
            path = "SuperFreeSpinOver_sihang"
        end
    end

    return self:showDialog(path,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenCloverHatMachine:showFreeSpinOverView()

    self:hideFreeSpinBar()
    
    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_fs_OverView.mp3")

    local winCoins = self.m_runSpinResultData.p_fsWinCoins
    local strCoins=util_formatCoins(winCoins,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

        
        self:showGuoChangLizi(function(  )

            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            self:removeAllScatterLockKuang()

            self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
            
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local currentPos = selfData.currentPos or 0

            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
            local FreeType = fsExtraData.FreeType or ""
            local selectReel = fsExtraData.selectReel or ""

            if FreeType == "PickFree" then
                self.m_bottomUI:hideAverageBet()
                if selectReel == "maprow4" then
                    self.m_iReelRowNum = self.m_iReelMinRow
                    self:changeReelData()
                end

                self.m_progress:restProgressEffect(0)

                self:removeAllSupperWildNode( )

                
                self.m_mapNodePos = currentPos -- 更新最新位置
                self.m_map.m_currPos = self.m_mapNodePos

            end

            

            self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐

            self:changeMainUI( self.m_iReelRowNum )

            self:restBaseMainUI()

            self:triggerFreeSpinOverCallFun()

        end)

        
    end)

    self:changeViewScale( view )

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCloverHatMachine:MachineRule_SpinBtnCall()

    self.m_quickStop = false

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:setMaxMusicBGVolume()

    self.m_jiesuanAct:setVisible(false)

    self:removeAllBaseLockWildNode( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 存储free wincoins
        local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
        self.m_LastTurnfsWinCoins = fsWinCoin
    else
        self.m_LastTurnfsWinCoins = 0
    end
    

    self.m_FsLockWildNode:setVisible(true)


    self:hideMapScroll()

    self.m_bSlotRunning = true

    self:hideMapTipView()

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCloverHatMachine:addSelfEffect()

    self.m_collectList ={}

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then

        if self:getBetLevel() >= 1 then
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                    if node then
                        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            if not self.m_collectList then
                                self.m_collectList = {}
                            end
                            self.m_collectList[#self.m_collectList + 1] = node
                        end
                    end
                end
            end
        end

        if self.m_collectList and #self.m_collectList > 0 then

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FLY_COIN_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT
        
        end

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local PickGame = selfData.PickGame

        --是否触发收集小游戏
        if PickGame then 
            local baseSpecialCoins =  self:getBaseSpecialCoins()
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            if baseSpecialCoins > 0 then
                selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
            else
                selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
            end
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
            
        end
    else

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}

        local FreeType = fsExtraData.FreeType or ""

        if FreeType == "NormalFree" then

            local features = self.m_runSpinResultData.p_features or {}
            if #features >= 2 and features[2] == 1 then
                -- freespin  加次数
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.FS_ADD_TIMES_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.FS_ADD_TIMES_EFFECT
            end
            

            -- freespin  lockIn 玩法
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.LOCK_IN_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.LOCK_IN_EFFECT

            
            local dropMultiple = fsExtraData.dropMultiple or {}
            if table_nums(dropMultiple)  > 0 then
                -- 该结算lockin 小赢钱了
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.LOCK_IN_WIN_COINS_EFFECT
            end


            local resultMultiple = fsExtraData.resultMultiple or {}
            if table_nums(resultMultiple)  > 0 then
                -- freespin 最后一次 结算锁定scatter
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.LOCK_IN_WIN_FREE_OVER_EFFECT
            end

        end


       

    end 



end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCloverHatMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then

        self:showEffect_collectCoin(effectData)

    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then

        self:showEffect_CollectBonus(effectData)

    elseif effectData.p_selfEffectType == self.LOCK_IN_EFFECT then

        self:showEffect_LockIn(effectData)

    elseif effectData.p_selfEffectType == self.LOCK_IN_WIN_COINS_EFFECT then

        self:showEffect_LockIn_WinCoins( effectData )

    elseif effectData.p_selfEffectType == self.LOCK_IN_WIN_FREE_OVER_EFFECT then

        self:showEffect_LockIn_FREE_OVER( effectData )

    elseif effectData.p_selfEffectType == self.FS_ADD_TIMES_EFFECT then

        
        
        
        self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN) -- 移除 freespin Effect

        gLobalSoundManager:playSound("CloverHatSounds/CloverHatSoundsTriggerFs.mp3")

        self:TriggerScatter( function(  )
            gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_fs_StartView.mp3")


                local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()



                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,true)
                self:changeViewScale( view )

        end )

    end

    
	return true
end

function CodeGameScreenCloverHatMachine:showEffect_LockIn_FREE_OVER( effectData )
    

    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_FsOver_Trigger_Reword.mp3")

    self:showColorLayer( )
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self:clearCurMusicBg()

    self.m_LockIn_FreeOver_WinCoins_index = 1
    self.m_LockIn_FreeOver_RunActList = {}
    self.m_LockIn_FreeOver_EndCall = function(  )

        self:hideColorLayer( )

        effectData.p_isPlay = true
        self:playGameEffect()
        
    end



    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local resultMultiple = fsExtraData.resultMultiple
    local resultJackpot = fsExtraData.resultJackpot
    local framesLevel = fsExtraData.framesLevel

    for k,v in pairs(resultMultiple) do
        local pos = tonumber(k)
        local winJpType = resultJackpot[k]
        local winCosin = v
        local winLevel = framesLevel[k]


        local kuang,tablePos = self:getOneScatterLockKuang( pos )
        if kuang then
            
            local fixPos = self:getRowAndColByPos(pos)
            local fixSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

            fixSymbol = util_setSymbolToClipReel(self,fixPos.iY, fixPos.iX, fixSymbol.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            
            if fixSymbol then
                
                kuang:runCsbAction("actionframe",false,function(  )
                    kuang:setVisible(false)
                end)

                if fixSymbol.p_symbolImage ~= nil and fixSymbol.p_symbolImage:getParent() ~= nil then
                    fixSymbol.p_symbolImage:removeFromParent()
                end
                fixSymbol.p_symbolImage = nil
                fixSymbol.m_ccbName = ""

                fixSymbol:changeCCBByName(self:getSymbolCCBNameByType(self, self:getLevelScatterSymbolType( winLevel )), self:getLevelScatterSymbolType( winLevel ))
                self:addScaterBg( fixSymbol )

               

                local showOrder = self:getBounsScatterDataZorder(self:getLevelScatterSymbolType( winLevel )) - fixSymbol.p_rowIndex
                fixSymbol.m_showOrder = showOrder
                fixSymbol:setLocalZOrder(showOrder)

                local fixSymbolData  = {}
                
                fixSymbolData.m_pos = pos
                fixSymbolData.m_iCol = fixPos.iY
                fixSymbolData.m_iRow = fixPos.iX
                fixSymbolData.m_winJpType = winJpType
                fixSymbolData.m_winCoins = winCosin
                fixSymbolData.m_winLevel = winLevel

                local scatterBgNode = fixSymbol:getChildByName("scatterbg")

                if scatterBgNode then
                    scatterBgNode:runCsbAction("actionframe_chuxian",false,function(  )

                        scatterBgNode:runCsbAction("actionframe",true)
                        
                    end)
                end

                
                local aniNode = fixSymbol:getCCBNode()
                if aniNode then
                    aniNode:setVisible(false)
                end

                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(waitNode,function(  )
                    if aniNode then
                        aniNode:setVisible(true)
                    end
                    fixSymbol:runAnim("actionframe_chuxian")
                end,9/30)
                

                table.insert(self.m_LockIn_FreeOver_RunActList,fixSymbolData)
                
     
            end
            

        end
  
  
    end

    -- 按照 位置：由左到右 ； 等级：由低到高排序
    table.sort(self.m_LockIn_FreeOver_RunActList,function( a , b )
        return a.m_pos < b.m_pos
    end)


    local array = {}

    for i=1, #self.m_LockIn_FreeOver_RunActList do
        local data = self.m_LockIn_FreeOver_RunActList[i]
        if array[data.m_winLevel] == nil then
            array[data.m_winLevel] = {}
        end
        table.insert( array[data.m_winLevel], data )
    end

    self.m_LockIn_FreeOver_RunActList = {}
    for k,v in pairs(array) do
        for i=1, #v do
            table.insert( self.m_LockIn_FreeOver_RunActList, v[i] )
        end
    end
    

    -- 等变化动画播完
    local waitNode_1 = cc.Node:create()
    self:addChild(waitNode_1)
    performWithDelay(waitNode_1,function(  )

        -- 开始播放 freeSpin Over  LockIn_RunAct
        self:playFreeOverRunEndActList( )
        
        waitNode_1:removeFromParent()
        
    end,(42 + 9 )/30)
    

    
    

end

function CodeGameScreenCloverHatMachine:playFreeOverRunEndActList( )
    
    if self.m_LockIn_FreeOver_WinCoins_index > #self.m_LockIn_FreeOver_RunActList then
        
        if self.m_LockIn_FreeOver_EndCall then
            self.m_LockIn_FreeOver_EndCall()
        end

        return
    end

    local fixSymbolData = self.m_LockIn_FreeOver_RunActList[self.m_LockIn_FreeOver_WinCoins_index]
    local fixSymbol = self:getFixSymbol(fixSymbolData.m_iCol, fixSymbolData.m_iRow, SYMBOL_NODE_TAG)
    if fixSymbol then

        gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_JianJinHuoDe.mp3")
        local zorder =  fixSymbol:getLocalZOrder()
        fixSymbol:setLocalZOrder(zorder + self.m_LockIn_FreeOver_WinCoins_index )
        
        self:changeScatterNodeData( fixSymbol ,fixSymbolData.m_winJpType,fixSymbolData.m_winCoins) 
        local jpTypeIndex = nil
        local jpTypeActName = nil
        if fixSymbolData.m_winJpType == "Mini" then
            jpTypeIndex = 4
            jpTypeActName = "actionframe_mini"
        elseif fixSymbolData.m_winJpType == "Minor" then
            jpTypeIndex = 3
            jpTypeActName = "actionframe_minor"
        elseif fixSymbolData.m_winJpType == "Major" then
            jpTypeIndex = 2
            jpTypeActName = "actionframe_major"
        elseif fixSymbolData.m_winJpType == "Grand" then
            jpTypeIndex = 1
            jpTypeActName = "actionframe_grand"
        end
        if jpTypeIndex then
                -- 播放 jackpot 逻辑
                fixSymbol:runAnim("actionframe_jiesuan",false,function(  )
                    
                    self.m_JackPotBar:runCsbAction( jpTypeActName ,false,function(  )
                        
                        self.m_JackPotBar:runCsbAction("ilde")

                        -- 播放jackpot弹板
                        self:showJackpotWinView(jpTypeIndex,fixSymbolData.m_winCoins,function(  )

                            gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_JianJinHuoDe_shoujifankui.mp3")

                            self:createParticleFly(0.5,fixSymbol,fixSymbolData.m_winCoins,function(  )

                                self:updateBottomUICoins( self.m_LastTurnfsWinCoins,fixSymbolData.m_winCoins,false )
                                self.m_LastTurnfsWinCoins = self.m_LastTurnfsWinCoins + fixSymbolData.m_winCoins

                                self.m_LockIn_FreeOver_WinCoins_index = self.m_LockIn_FreeOver_WinCoins_index + 1

                                self:playFreeOverRunEndActList( )
    
                            end)

                        end)

                    end)

                end)
        else
            -- 播放 赢钱逻辑
            fixSymbol:runAnim("actionframe_jiesuan",false,function(  )

                gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_JianJinHuoDe_shoujifankui.mp3")

                

                self:createParticleFly(0.5,fixSymbol,fixSymbolData.m_winCoins,function(  )

                    self:updateBottomUICoins(self.m_LastTurnfsWinCoins, fixSymbolData.m_winCoins,false )
                    self.m_LastTurnfsWinCoins = self.m_LastTurnfsWinCoins + fixSymbolData.m_winCoins
                    self.m_LockIn_FreeOver_WinCoins_index = self.m_LockIn_FreeOver_WinCoins_index + 1
                    
                    self:playFreeOverRunEndActList( )

                end)

                
            end)
        end

    end

    

end

function CodeGameScreenCloverHatMachine:playRunActList( )
    
    if self.m_LockIn_WinCoins_index > #self.m_LockIn_RunActList then
        
        if self.m_LockIn_EndCall then
            self.m_LockIn_EndCall()
        end

        return
    end

    local fixSymbolData = self.m_LockIn_RunActList[self.m_LockIn_WinCoins_index]
    local fixSymbol = self:getFixSymbol(fixSymbolData.m_iCol, fixSymbolData.m_iRow, SYMBOL_NODE_TAG)
    if fixSymbol then 


        local scatterBgNode_1 = fixSymbol:getChildByName("scatterbg")
        if scatterBgNode_1 then
            scatterBgNode_1:runCsbAction("actionframe_xiaoshi")
        end
        
        gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_JianJinHuoDe.mp3")

        -- 播放 赢钱逻辑
        fixSymbol:runAnim("actionframe_xiaoshi",false,function(  )

            if fixSymbol.p_symbolImage ~= nil and fixSymbol.p_symbolImage:getParent() ~= nil then
                fixSymbol.p_symbolImage:removeFromParent()
            end
            fixSymbol.p_symbolImage = nil
            fixSymbol.m_ccbName = ""

            fixSymbol:changeCCBByName(self:getSymbolCCBNameByType(self, self:getLevelScatterSymbolType( self.WINTYPE_GOLD )), self:getLevelScatterSymbolType( self.WINTYPE_GOLD ))
            self:addScaterBg( fixSymbol )

            local scatterBgNode = fixSymbol:getChildByName("scatterbg")
            if scatterBgNode then
                scatterBgNode:runCsbAction("actionframe_chuxian",false,function(  )
                    scatterBgNode:runCsbAction("actionframe",true)
                end)
            end
            fixSymbol:runAnim("actionframe_chuxian",false,function(  )

                self:changeScatterNodeData( fixSymbol ,fixSymbolData.m_winJpType,fixSymbolData.m_winCoins) 

                local Particle_2 =  fixSymbol:getCcbProperty("Particle_2")
                if Particle_2 then
                    Particle_2:resetSystem()
                end
                local Particle_3 =  fixSymbol:getCcbProperty("Particle_3")
                if Particle_3 then
                    Particle_3:resetSystem()
                end
                fixSymbol:runAnim("actionframe_jiesuan",false,function(  )

                    local jpTypeIndex = nil
                    local jpTypeActName = nil
                    if fixSymbolData.m_winJpType == "Mini" then
                        jpTypeIndex = 4
                        jpTypeActName = "actionframe_mini"
                    elseif fixSymbolData.m_winJpType == "Minor" then
                        jpTypeIndex = 3
                        jpTypeActName = "actionframe_minor"
                    elseif fixSymbolData.m_winJpType == "Major" then
                        jpTypeIndex = 2
                        jpTypeActName = "actionframe_major"
                    elseif fixSymbolData.m_winJpType == "Grand" then
                        jpTypeIndex = 1
                        jpTypeActName = "actionframe_grand"
                    end
                    if jpTypeIndex then
                        
                        self.m_JackPotBar:runCsbAction( jpTypeActName ,false,function(  )
                            self.m_JackPotBar:runCsbAction("ilde")
                            -- 播放jackpot弹板
                            self:showJackpotWinView(jpTypeIndex,fixSymbolData.m_winCoins,function(  )

                                self:createParticleFly(0.5,fixSymbol,fixSymbolData.m_winCoins,function(  )

                                    self:updateBottomUICoins(self.m_LastTurnfsWinCoins, fixSymbolData.m_winCoins,false )
                                    self.m_LastTurnfsWinCoins = self.m_LastTurnfsWinCoins + fixSymbolData.m_winCoins
                                    
                                    self:playRunActList( )

                                end)
                            end)

                        end)

                    else

                        self:createParticleFly(0.5,fixSymbol,fixSymbolData.m_winCoins,function(  )

                            self:updateBottomUICoins( self.m_LastTurnfsWinCoins ,fixSymbolData.m_winCoins,false )
                            self.m_LastTurnfsWinCoins = self.m_LastTurnfsWinCoins + fixSymbolData.m_winCoins
                            self:playRunActList( )
                            

                        end)

                    end

                end)
                
                
                
            end)

        end)

    end

    self.m_LockIn_WinCoins_index = self.m_LockIn_WinCoins_index + 1
    
end

function CodeGameScreenCloverHatMachine:showEffect_LockIn_WinCoins( effectData )

    self.m_LockIn_WinCoins_index = 1
    self.m_LockIn_RunActList = {}
    self.m_LockIn_EndCall = function(  )
        effectData.p_isPlay = true
        self:playGameEffect()
    end



    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local dropMultiple = fsExtraData.dropMultiple
    local dropJackpot = fsExtraData.dropJackpot

    for k,v in pairs(dropMultiple) do
        local pos = tonumber(k)
        local winJpType = dropJackpot[k]
        local winCosin = v

        local kuang,tablePos = self:getOneScatterLockKuang( pos )
        if kuang then
        
            local fixPos = self:getRowAndColByPos(pos)
            local fixSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if fixSymbol then
                
                local fixSymbolData  = {}
                
                fixSymbolData.m_iCol = fixPos.iY
                fixSymbolData.m_iRow = fixPos.iX
                fixSymbolData.m_winJpType = winJpType
                fixSymbolData.m_winCoins = winCosin
                fixSymbolData.m_pos = pos

                table.insert(self.m_LockIn_RunActList,fixSymbolData)
     
            end
            

        end
  
  
    end

    -- 按照 位置：由左到右 ； 等级：由低到高排序
    table.sort(self.m_LockIn_RunActList,function( a , b )
        return a.m_pos < b.m_pos
    end)


    -- 开始播放 LockIn_RunAct
    self:playRunActList( )


    
    

end

function CodeGameScreenCloverHatMachine:changeScatterNodeData( fixSymbol ,winJpType,winCosin)
    
    local jpImg = {"grand","major","minor","mini"}
    local Node_Jp = fixSymbol:getCcbProperty("Node_Jp")
    if Node_Jp then
        Node_Jp:setVisible(false)
    end
    local Node_lab = fixSymbol:getCcbProperty("Node_lab")
    if Node_lab then
        Node_lab:setVisible(false)
    end
    
    for i=1,#jpImg do
        local img = fixSymbol:getCcbProperty(jpImg[i])
        if img then
            img:setVisible(false)

            if winJpType == "Mini" then
                if i == 4 then
                    img:setVisible(true)
                end
            elseif winJpType == "Minor" then
                if i == 3 then
                    img:setVisible(true)
                end
            elseif winJpType == "Major" then
                if i == 2 then
                    img:setVisible(true)
                end
            elseif winJpType == "Grand" then
                if i == 1 then
                    img:setVisible(true)
                end
            end
        end

    end

    if winJpType == "Mini" or winJpType == "Minor" 
        or winJpType == "Major" or winJpType == "Grand" then
            if Node_Jp then
                Node_Jp:setVisible(true)
            end
    else
        if Node_lab then
            Node_lab:setVisible(true)
        end
        local lab = fixSymbol:getCcbProperty("lab_coins")
        if lab then
            lab:setString(util_formatCoins(winCosin,3))
        end
    end

end

function CodeGameScreenCloverHatMachine:showEffect_LockIn( effectData )

    local isinit = false
    if self.m_quickStop == true then
        self.m_quickStop = false
        isinit = true
    end

    local isUpdata = self:updateScatterLockKuang(function(  )
        effectData.p_isPlay = true
        self:playGameEffect()
    end,isinit)

    if isUpdata then
        gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_ScatterLockKuang.mp3")
    end
    
end

function CodeGameScreenCloverHatMachine:showEffect_collectCoin(effectData)

    local node = self.m_progress:findChild("pand_0")
    local progressPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newProgressPos = self:convertToNodeSpace(progressPos)
    local endPos = cc.p(newProgressPos)

    local pecent = self:getProgressPecent()

    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_Collect_Scatter.mp3")

    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local coins = util_createAnimation("CloverHat_Map_shouji.csb")
        if i == 1 then
            coins.m_isLastSymbol = true
        end
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        coins:setPosition(newStartPos)
        

        coins:runCsbAction("actionframe")

        coins:findChild("Particle_TuoWei_1"):setPositionType(0)
        coins:findChild("Particle_TuoWei_1"):setDuration(-1)

        coins:findChild("Particle_TuoWei_2"):setPositionType(0)
        coins:findChild("Particle_TuoWei_2"):setDuration(-1)

        coins:findChild("Particle_TuoWei_3"):setPositionType(0)
        coins:findChild("Particle_TuoWei_3"):setDuration(-1)
        

        local CoinsNdoe = coins
        local actLsit = {}
        actLsit[#actLsit + 1] = cc.BezierTo:create(18/30,{cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        actLsit[#actLsit + 1] = cc.CallFunc:create( function()

            if CoinsNdoe.m_isLastSymbol == true then
                self.m_progress:updatePercent(pecent)
            end

        end)
        actLsit[#actLsit + 1] = cc.CallFunc:create( function()

            CoinsNdoe:removeFromParent()

        end)
        

        CoinsNdoe:runAction(cc.Sequence:create(actLsit ))
        table.remove(self.m_collectList, i)

    end


    local time = 0

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local PickGame = selfData.PickGame
    local features = self.m_runSpinResultData.p_features or {}

    --触发收集小游戏 播放完收集
    if PickGame or #features >= 2 then 
        time = (18 + 30 )/30
    end

    performWithDelay(self,function(  )

        effectData.p_isPlay = true
        self:playGameEffect()
        
    end,time)
    



end



function CodeGameScreenCloverHatMachine:showEffect_CollectBonus(effectData)

    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_Trigger_Bonus.mp3")
    
    self:clearCurMusicBg()

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self.m_progress.m_Act:runCsbAction("actionframe",false,function(  )
        
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local currentPos = selfData.currentPos or 0
        self.m_mapNodePos = currentPos -- 更新最新位置
        local LitterGameWin = selfData.LitterGameWin or 0
        self.m_map:updateLittleLevelCoins( self.m_mapNodePos,LitterGameWin )

        self:showMapScroll(function(  )

            self.m_map:pandaMove(function(  )
                
                local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                local PickGame = selfData.PickGame 
                if PickGame == "FreeGame" then

                    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_Trigger_Bonus_Fs.mp3")

                    self:showGuoChangJinBi( function(  )
                        self.m_mapZhezaho:runCsbAction("over",false,function(  )
                            self.m_mapZhezaho:setVisible(false)
                        end)

                        self:resetMusicBg(true)

                        self.m_map:mapDisappear()
                        self.m_map:setVisible(false)
 
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end )
                else
                    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_guanZi_Bian_JinBi.mp3")

                    local currNode = self.m_map.m_mapLayer.m_vecNodeLevel[self.m_mapNodePos]
                    self:createParticleFly(0.5,currNode,LitterGameWin,function(  )

                        local beginCoins =  self.m_serverWinCoins - LitterGameWin
                        self:updateBottomUICoins(beginCoins,LitterGameWin,true )
                        
                        self.m_mapZhezaho:runCsbAction("over",false,function(  )
                            self.m_mapZhezaho:setVisible(false)
                        end)

                        self.m_map:mapDisappear(function(  )
                
                            self:resetMusicBg(true)
                            
                            self.m_progress:restProgressEffect(0)

                            effectData.p_isPlay = true
                            self:playGameEffect()
                
                        end)

                        
                    end)
                end
    

            end, self.m_bonusData, self.m_mapNodePos)
    
            
        end,false)

    end)


    

end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCloverHatMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenCloverHatMachine:addScaterBg( symbolNode )
    local scatterBgNode = symbolNode:getChildByName("scatterbg")
    if scatterBgNode then
        scatterBgNode:removeFromParent()
    end
    if symbolNode.p_symbolType  == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

        local scatterbg = util_createAnimation("Socre_CloverHat_Scatter_bg_green.csb")
        symbolNode:addChild(scatterbg,-1)
        scatterbg:setName("scatterbg")
        scatterbg:runCsbAction("actionframe",true)
        
    elseif symbolNode.p_symbolType  == self.SYMBOL_SCATTER_SILVER then

        local scatterbg = util_createAnimation("Socre_CloverHat_Scatter_bg_yin.csb")
        symbolNode:addChild(scatterbg,-1)
        scatterbg:setName("scatterbg")
        scatterbg:runCsbAction("actionframe",true)
       
    elseif symbolNode.p_symbolType  == self.SYMBOL_SCATTER_GOLD then

        local scatterbg = util_createAnimation("Socre_CloverHat_Scatter_bg_gold.csb")
        symbolNode:addChild(scatterbg,-1)
        scatterbg:setName("scatterbg")
        scatterbg:runCsbAction("actionframe",true)
       
    end
end

function CodeGameScreenCloverHatMachine:updateReelGridNode(symbolNode)
 
    if symbolNode and symbolNode:getCcbProperty("Socre_CloverHat_Wild_ditu") then
        symbolNode:getCcbProperty("Socre_CloverHat_Wild_ditu"):setVisible(false)
    end

    self:addScaterBg( symbolNode )

end

function CodeGameScreenCloverHatMachine:initGameStatusData( gameData )
    BaseNewReelMachine.initGameStatusData( self, gameData )
    if gameData then
        if gameData.gameConfig then
            if gameData.gameConfig.extra then
                if gameData.gameConfig.extra.map then
                    self.m_bonusData = clone(gameData.gameConfig.extra.map)
                end
                
            end
        end
    end
end

function CodeGameScreenCloverHatMachine:createMapScroll( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0

    self.m_mapNodePos = currentPos

    self.m_map = util_createView("CodeCloverHatSrc.CloverHatMap.CloverHatBonusMapScrollView", self.m_bonusData, self.m_mapNodePos)
    -- self:findChild("map"):addChild(self.m_map)
    self.m_clipParent:addChild(self.m_map, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2+100)
    self.m_map:setVisible(false)


end

-- freespin 锁定块的玩法


function CodeGameScreenCloverHatMachine:removeAllScatterLockKuang( )
    
    for i = #self.m_scatterAllLockNode,1,-1 do

        local kuang = self.m_scatterAllLockNode[i]
        kuang:removeFromParent()
        table.remove( self.m_scatterAllLockNode, i )
    end

end

function CodeGameScreenCloverHatMachine:getOneScatterLockKuang( index )
    
    for i=1,#self.m_scatterAllLockNode do
        local kuang = self.m_scatterAllLockNode[i]
        if kuang.m_index == index then

            return kuang,i
        end
    end
end

function CodeGameScreenCloverHatMachine:getLevelScatterSymbolType( winType )


    if winType == self.WINTYPE_GREEN then
        return TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    elseif winType == self.WINTYPE_SILVER then
        return self.SYMBOL_SCATTER_SILVER
    else
        return self.SYMBOL_SCATTER_GOLD
    end
end

function CodeGameScreenCloverHatMachine:getScatterLockKuangCsbName( winType )
   

    if winType == self.WINTYPE_GREEN then
        return "Socre_CloverHat_kuang_green.csb"
    elseif winType == self.WINTYPE_SILVER then
        return "Socre_CloverHat_kuang_yin.csb"
    else
        return "Socre_CloverHat_kuang_gold.csb"
    end
end

function CodeGameScreenCloverHatMachine:updateScatterLockKuang( func ,isinit )
    
    local isUpdata = false
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local framesLevel = fsExtraData.framesLevel

    for k,v in pairs(framesLevel) do
        local pos = tonumber(k)
        local winType = v

        local createCsbName = self:getScatterLockKuangCsbName(winType )
        local kuang,tablePos = self:getOneScatterLockKuang( pos )

        if not kuang or kuang.m_csbName ~= createCsbName then
            local lockNode = self:createOneScatterLockKuang( pos ,createCsbName)
            isUpdata = true
            lockNode:runCsbAction("actionframe_chuxian",false,function(  )
                lockNode:runCsbAction("idle",true)
            end)
            if isinit then
                isUpdata = false
                lockNode:runCsbAction("idle",true)
            end
        end
    end

    local time = 0
    if isUpdata then
        time = 48/30
    end

    performWithDelay(self,function(  )
        
        if func then
            func()
        end

    end,time)

    return isUpdata
end

function CodeGameScreenCloverHatMachine:createOneScatterLockKuang( index ,csbName)
    
    local kuang,tablePos = self:getOneScatterLockKuang( index )
    if kuang then
        -- 防止有相同位置的框
        table.remove( self.m_scatterAllLockNode,tablePos )
        kuang:removeFromParent()
    end

    local lockNode = util_createAnimation(csbName)
    lockNode.m_index = index
    lockNode.m_csbName = csbName

    lockNode:setLocalZOrder(index)
    lockNode:setPosition(cc.p(util_getOneGameReelsTarSpPos(self,index )))
    lockNode:runCsbAction("idle",true)
    self:findChild("Node_LockKuang"):addChild(lockNode)

    table.insert( self.m_scatterAllLockNode, lockNode)


    return lockNode

end

function CodeGameScreenCloverHatMachine:hideMapScroll()

    
    if self.m_map:getMapIsShow() == true then

        self.m_bCanClickMap = false

        self.m_mapZhezaho:runCsbAction("over",false,function(  )
            self.m_mapZhezaho:setVisible(false)
        end)
        self:resetMusicBg(true)

        self.m_map:mapDisappear(function()

            self.m_bCanClickMap = true
        end)

    end

end

function CodeGameScreenCloverHatMachine:showMapScroll(callback,canTouch)

    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true) and callback == nil then
        return
    end

    self.m_bCanClickMap = false

    if self.m_map:getMapIsShow() == true then

        self.m_mapZhezaho:runCsbAction("over",false,function(  )
            self.m_mapZhezaho:setVisible(false)
        end)


        self.m_map:mapDisappear(function()

            self:resetMusicBg(true)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self.m_bCanClickMap = true
        end)
    else

        self:clearCurMusicBg()

        self.m_mapZhezaho:setVisible(true)
        self.m_mapZhezaho:runCsbAction("start")

        self:hideMapTipView(true)

        self:removeSoundHandler( )

        self:resetMusicBg(nil,"CloverHatSounds/CloverHat_mapBG.mp3")


        self.m_map:mapAppear(function()

            self.m_bCanClickMap = true

            if callback then
                callback()
            end
        end)
        
        if canTouch then
            self.m_map:setMapCanTouch(true)
        else
            self.m_map:hidMoveBtn( )
        end
    end

end

function CodeGameScreenCloverHatMachine:showGuoChangLizi( func )
    
    gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_GuoChang_YieZi.mp3")

    self.m_guochangLizi:setVisible(true)

    self.m_guochangLizi:findChild("siyecao_big"):setPositionType(0)
    self.m_guochangLizi:findChild("siyecao_big"):setDuration(-1)
    self.m_guochangLizi:findChild("siyecao_smart"):setPositionType(0)
    self.m_guochangLizi:findChild("siyecao_smart"):setDuration(-1)
    self.m_guochangLizi:findChild("lizi"):setPositionType(0)
    self.m_guochangLizi:findChild("lizi"):setDuration(-1)

    self.m_guochangLizi:findChild("siyecao_big"):resetSystem()
    self.m_guochangLizi:findChild("siyecao_smart"):resetSystem()
    self.m_guochangLizi:findChild("lizi"):resetSystem()

    self.m_guochangLizi:runCsbAction("actionframe",false,function(  )
       
        self.m_guochangLizi:findChild("siyecao_big"):stopSystem()
        self.m_guochangLizi:findChild("siyecao_smart"):stopSystem()
        self.m_guochangLizi:findChild("lizi"):stopSystem()

        local node = cc.Node:create()
        self:addChild(node)
        performWithDelay(node,function(  )

            node:removeFromParent()
            self.m_guochangLizi:setVisible(false)

        end,2)
        
    end,60)

    local node_1 = cc.Node:create()
    self:addChild(node_1)
    performWithDelay(node_1,function(  )
        node_1:removeFromParent()


        if func then
            func()
        end

    end,39/60)


end

function CodeGameScreenCloverHatMachine:showGuoChangJinBi( func )
    
    self.m_GuoChangJinBi:setVisible(true)
    self.m_GuoChangJinBi:runCsbAction("actionframe",false,function(  )
        
        

        self.m_GuoChangJinBi:setVisible(false)
    end)

    performWithDelay(self,function(  )

        if func then
            func()
        end

    end,96/30)
    

end

function CodeGameScreenCloverHatMachine:changeViewScale( _view )

    
    if self.m_iReelRowNum == self.m_iReelMaxRow then
        _view:findChild("root"):setScale(self.m_machineRootScale * self.MAXROW_REEL_SCALE ) 
        local pos = util_getConvertNodePos(self:findChild("Node_view_Pos"),_view:findChild("root"))
        _view:findChild("root"):setPosition( cc.p(pos.x,pos.y ) )

    else
        _view:findChild("root"):setScale(self.m_machineRootScale) 
        local pos = util_getConvertNodePos(self:findChild("Node_view_Pos"),_view:findChild("root"))
        _view:findChild("root"):setPosition( cc.p(pos.x,pos.y ) )
    end

end

function CodeGameScreenCloverHatMachine:showJackpotWinView(index,coins,func)
    


    local jackPotWinView = util_createView("CodeCloverHatSrc.CloverHatJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)

    self:changeViewScale( jackPotWinView )

    local curCallFunc = function(  )
        if func then
            func()
        end
    end
    jackPotWinView:initViewData(self,index,coins,curCallFunc)


end

function CodeGameScreenCloverHatMachine:TriggerScatter( func )

    local aniNodeList = {}
    for iRow  = 1, self.m_iReelRowNum, 1 do
        for iCol = 1, self.m_iReelColumnNum, 1 do
            local tarSp = self:getFixSymbol( iCol , iRow, SYMBOL_NODE_TAG)
            
            if tarSp  then
                if tarSp.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER 
                    or tarSp.p_symbolType ==  self.SYMBOL_SCATTER_SILVER
                        or tarSp.p_symbolType ==  self.SYMBOL_SCATTER_GOLD  then
                            local nodeRoot = tarSp:getCcbProperty("root")
                            if nodeRoot then
                                nodeRoot:setVisible(false)
                            end
                            
                            
                            local showOrder = self:getBounsScatterDataZorder(tarSp.p_symbolType) - iRow

                            local actNode = util_createAnimation(self:getSymbolCCBNameByType(self, tarSp.p_symbolType) .. ".csb")
                            self.m_clipParent:addChild(actNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + showOrder)

                            local pos = util_getOneGameReelsTarSpPos(self,self:getPosReelIdx(iRow, iCol) )
                            actNode:setPosition(pos)
                            actNode:runCsbAction("actionframe",false,function(  )
                                if nodeRoot then
                                    nodeRoot:setVisible(true)
                                end
                            end)
                            table.insert( aniNodeList, actNode )
                end
                
            end
        end
    end
    
    performWithDelay(self,function(  )

        for i=1,#aniNodeList do
            local node = aniNodeList[i]
            if node then
                node:removeFromParent()
            end
        end

        if func then
            func()
        end
        
    end, 75 / 30)
end

---
--设置bonus scatter 层级
function CodeGameScreenCloverHatMachine:getBounsScatterDataZorder(symbolType )

    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    if symbolType ==  self.SYMBOL_SCATTER_SILVER then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 2
    elseif symbolType == self.SYMBOL_SCATTER_GOLD then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 2
    end

    local order = BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType )

    

    return order

end

function CodeGameScreenCloverHatMachine:getProgressPecent()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local maxScatters = selfData.maxScatters or 1
    if maxScatters == 0 then
        maxScatters = 1
    end
    local pickScatters = selfData.pickScatters or 0

    local percent = pickScatters / maxScatters * 100
    return percent
end

function CodeGameScreenCloverHatMachine:restBaseMainUI( )
    self:findChild("Node_4RowBg"):setVisible(false)
    self:findChild("Node_3RowBg"):setVisible(true)
    -- self:findChild("CloverHat_progress"):setVisible(true)
    self.m_progress:setVisible(true)
    self:findChild("JACKPOT"):setVisible(true)
    self:findChild("JACKPOT"):setPositionY(251)
end

function CodeGameScreenCloverHatMachine:changeMainUI( row )
    
    if row == self.m_iReelMinRow then


        self:findChild("Node_4RowBg"):setVisible(false)
        self:findChild("Node_3RowBg"):setVisible(true)
        -- self:findChild("CloverHat_progress"):setVisible(false)
        self.m_progress:setVisible(false)

        self:findChild("Node_reel"):setScale(1) 
        self:findChild("Node_reel"):setPositionY(0)
        self:findChild("JACKPOT"):setPositionY(214)

        
    else

       
        self:findChild("Node_4RowBg"):setVisible(true)
        self:findChild("Node_3RowBg"):setVisible(false)
        -- self:findChild("CloverHat_progress"):setVisible(false)
        self.m_progress:setVisible(false)

        self:findChild("Node_reel"):setScale(self.MAXROW_REEL_SCALE) 
        self:findChild("Node_reel"):setPositionY(self.MAXROW_REEL_POS_Y)
        self:findChild("JACKPOT"):setPositionY(350)

    end


end

function CodeGameScreenCloverHatMachine:changeReelData()



    for i = self.m_iReelRowNum , 1, - 1 do
        if self.m_stcValidSymbolMatrix[i] == nil then
            self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
        end
    end
    

    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
    end

    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x, 
                y = rect.y, 
                width = rect.width, 
                height = columnData.p_slotColumnHeight
            }
        )
    end

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
end

function CodeGameScreenCloverHatMachine:playEffectNotifyNextSpinCall( )
    self.m_bSlotRunning = false

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)

end


---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenCloverHatMachine:changeToMaskLayerSlotNode(slotNode)

    BaseNewReelMachine.changeToMaskLayerSlotNode(self,slotNode)

    if slotNode then
        if slotNode.p_rowIndex and slotNode.p_cloumnIndex then
            local pos = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex) 
            local lockWildSpr = self:getSupperWildNode( pos )
            if lockWildSpr then
                slotNode:runAnim("idleframe")
                if slotNode and slotNode:getCcbProperty("Socre_CloverHat_Wild_ditu") then
                    slotNode:getCcbProperty("Socre_CloverHat_Wild_ditu"):setVisible(true)
                end
            else
                slotNode:runAnim("idleframe")
                if slotNode and slotNode:getCcbProperty("Socre_CloverHat_Wild_ditu") then
                    slotNode:getCcbProperty("Socre_CloverHat_Wild_ditu"):setVisible(false)
                end
            end
        
            
        end 
    end

    
end

function CodeGameScreenCloverHatMachine:showWinJieSunaAct( )
    self.m_jiesuanAct:setVisible(true)
    for i=1,4 do
        local Particle = self.m_jiesuanAct:findChild("Particle_"..i)
        if Particle then
            Particle:resetSystem()
        end
    end
    self.m_jiesuanAct:runCsbAction("actionframe")

end

function CodeGameScreenCloverHatMachine:changeSymbolToWild(_posList )
    

    for i=1,#_posList do
        local index = _posList[i]
        local fixPos = self:getRowAndColByPos(index)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if symbolNode then
            if self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ) == symbolNode.m_ccbName then 
                print("wild不处理")
            else
                symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                if symbolNode.p_symbolImage ~= nil then
                    symbolNode.p_symbolImage:removeFromParent()
                    symbolNode.p_symbolImage = nil
                end
            end
            
        end

    end

end

function CodeGameScreenCloverHatMachine:showLineFrame( )

    BaseNewReelMachine.showLineFrame(self )
    -- 有连线的时候假的隐藏
    self.m_FsLockWildNode:setVisible(false)

    self:removeAllBaseLockWildNode( )

end

function CodeGameScreenCloverHatMachine:removeAllSupperWildNode( )
    self.m_FsLockWildNode:removeAllChildren()
end

function CodeGameScreenCloverHatMachine:getSupperWildNode(_pos )

    return self.m_FsLockWildNode:getChildByName(_pos)
end

function CodeGameScreenCloverHatMachine:initSupperWildNode(  )
    
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fixPos = fsExtraData.fixPos or {1,5,6,7}

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName( self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD).."_Lock")
    local imgName = nil
    if imageName == nil then  
        print("没有开启使用滚动替代图，会导致不能新创建的wild锁定静态图")
    else
        local offsetX = 0
        local offsetY = 0
        local scale = 1
        if tolua.type(imageName) == "table" then
            imgName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
            elseif #imageName == 4 then
                offsetX = imageName[2]
                offsetY = imageName[3]
                scale = imageName[4]
            end
        end

        for i=1,#fixPos do
            local pos = fixPos[i]
            local node = cc.Node:create()
            self.m_FsLockWildNode:addChild(node)
            local wildSpr = display.newSprite(imgName)
            node:addChild(wildSpr)
            wildSpr:setScale(scale)
            wildSpr:setPositionX(offsetX)
            wildSpr:setPositionY(offsetY)
            node:setName(pos)
            node:setPosition(util_getOneGameReelsTarSpPos(self,pos))
            
        end

    end

    

end



function CodeGameScreenCloverHatMachine:getBaseSpecialCoins( )
    
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local LittleGameWin = selfdata.LitterGameWin or 0 -- bonus

    return LittleGameWin
end



function CodeGameScreenCloverHatMachine:getFsSpecialCoins( )
    
    local specailCoins = 0

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}

    local dropMultiple = fsExtraData.dropMultiple or {} -- 锁定框到达最大 会获得钱

    for k,v in pairs(dropMultiple) do

        local winCosin = v

        specailCoins = specailCoins + winCosin
    end


    local resultMultiple = fsExtraData.resultMultiple or {}


    for k,v in pairs(resultMultiple) do

        local winCosin = v

        specailCoins = specailCoins + winCosin

    end
    

    return specailCoins

end

function CodeGameScreenCloverHatMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )
    -- free下不需要考虑更新左上角赢钱

    local endCoins = beiginCoins + currCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    local params = {endCoins,isNotifyUpdateTop,nil,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    globalData.slotRunData.lastWinCoin = lastWinCoin
    


end

function CodeGameScreenCloverHatMachine:checkNotifyUpdateWinCoin( )

    
    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    local specialCoins = 0
    local coins = 0
    local beiginCoins = nil

    if isNotifyUpdateTop then

        beiginCoins =  nil
        specialCoins = self:getBaseSpecialCoins()
        coins =  self.m_iOnceSpinLastWin - specialCoins
        
        if specialCoins > 0 then
            -- bonus在更新左上
            isNotifyUpdateTop = false
        end
        
    else
        
        local isFirstFsTime = false
        local freeSpinsTotalCount =  self.m_runSpinResultData.p_freeSpinsTotalCount
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if freeSpinsTotalCount and freeSpinsLeftCount then
            if freeSpinsTotalCount == freeSpinsLeftCount then
                local baseSpecialCoins = self:getBaseSpecialCoins()
                if baseSpecialCoins and baseSpecialCoins > 0 then
                    isFirstFsTime = true
                end
                
            end
        end

        if isFirstFsTime then

            beiginCoins =  nil
            specialCoins = self:getBaseSpecialCoins()
            coins =  self.m_iOnceSpinLastWin - specialCoins
            
        else
            specialCoins = self:getFsSpecialCoins( )
            coins =  fsWinCoin - specialCoins
            beiginCoins = fsWinCoin - self.m_serverWinCoins
        end
        
        
    end

    self.m_LastTurnfsWinCoins = coins

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isNotifyUpdateTop,nil,beiginCoins})
    globalData.slotRunData.lastWinCoin = lastWinCoin

   
 
    
end

function CodeGameScreenCloverHatMachine:checkIsAddLastWinSomeEffect( )
    
    local notAdd  = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end



    local baseSpecialCoins =  self:getBaseSpecialCoins()

    local fsSpecialCoins = self:getFsSpecialCoins( )

    if (baseSpecialCoins + fsSpecialCoins) > 0 then
        -- special 赢钱不为0 则检测大赢
        notAdd  = false

    end


    return notAdd
end

-- 创建飞行粒子
function CodeGameScreenCloverHatMachine:createParticleFly(time,currNode,coins,func)

    local fly =  util_createAnimation("CloverHat_jiesuanshuzi.csb")
    self:addChild(fly,GD.GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    fly:findChild("lab_coins"):setString(util_formatCoins(coins,3))
    
    fly:findChild("Particle_1"):setDuration(-1)
    fly:findChild("Particle_1"):setPositionType(0)
    fly:findChild("Particle_2"):setDuration(-1)
    fly:findChild("Particle_2"):setPositionType(0)
    fly:findChild("Particle_3"):setDuration(-1)
    fly:findChild("Particle_3"):setPositionType(0)
    
    
    fly:setPosition(cc.p(util_getConvertNodePos(currNode,fly)))

    local endPos = util_getConvertNodePos(self.m_jiesuanAct ,fly)

    
    
    local animation = {}
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:findChild("Particle_1"):stopSystem()
        fly:findChild("Particle_2"):stopSystem()
        fly:findChild("Particle_3"):stopSystem()

        fly:findChild("lab_coins"):setVisible(false)

        self:showWinJieSunaAct( )

        if func then
            func()
        end


    end)
    animation[#animation + 1] = cc.DelayTime:create(1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))

    
    
end

-- function CodeGameScreenCloverHatMachine:scaleMainLayer()
--     local uiW, uiH = self.m_topUI:getUISize()
--     local uiBW, uiBH = self.m_bottomUI:getUISize()

--     local mainHeight = display.height - uiH - uiBH
--     local mainPosY = (uiBH - uiH - 30) / 2

--     local winSize = display.size
--     local mainScale = 1

--     local hScale = mainHeight / self:getReelHeight()
--     local wScale = winSize.width / self:getReelWidth()
--     if hScale < wScale then
--         mainScale = hScale
--     else
--         mainScale = wScale
--         self.m_isPadScale = true
--     end
--     if globalData.slotRunData.isPortrait == true then
--         if display.height < DESIGN_SIZE.height then
--             mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
--             util_csbScale(self.m_machineNode, mainScale)
--             self.m_machineRootScale = mainScale
--         end
--     else
--         if display.width <= 1024 then
--             mainScale = mainScale * 0.95
--         end
--         util_csbScale(self.m_machineNode, mainScale)
--         self.m_machineRootScale = mainScale
--         self.m_machineNode:setPositionY(mainPosY + self.MAIN_REEL_ADD_POS_Y)
--     end

-- end

function CodeGameScreenCloverHatMachine:scaleMainLayer()
    CodeGameScreenCloverHatMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 1
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 1.07 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 1.06 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    elseif ratio < 768/1228 and ratio >= 768/1370 then
        local mainScale = 1.01 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    elseif ratio < 768/1370 and ratio >= 768/1530 then
        local mainScale = 1.01 - 0.05*((ratio-768/1530)/(768/1370 - 768/1530))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    elseif ratio < 768/1530 and ratio >= 768/1660 then
        local mainScale = 1.01 - 0.05*((ratio-768/1660)/(768/1530 - 768/1660))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenCloverHatMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "CloverHatSounds/CloverHat_scatter_down_1.mp3"
        elseif i == 2 then
            soundPath = "CloverHatSounds/CloverHat_scatter_down_2.mp3"
        elseif i == 3 then
            soundPath = "CloverHatSounds/CloverHat_scatter_down_3.mp3"
        elseif i == 4 then
            soundPath = "CloverHatSounds/CloverHat_scatter_down_4.mp3"
        else
            soundPath = "CloverHatSounds/CloverHat_scatter_down_5.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenCloverHatMachine:updateNetWorkData()

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

    -- 网络消息已经赋值成功开始进行击随机固定wild的判断逻辑
    self:netBackCheckAddWildAction( )
    
end

function CodeGameScreenCloverHatMachine:removeAllBaseLockWildNode( )
    self.m_BaseLockWildNode:removeAllChildren()
end

function CodeGameScreenCloverHatMachine:initBaseLockWildNode( _fixPos , _func  )

    gLobalSoundManager:setBackgroundMusicVolume(0.1)

    gLobalSoundManager:playSound("CloverHatSounds/CloverHat_radomAddWild.mp3")
   
    local ramdomFireworkName = {"CloverHat_Wild_Random_hong","CloverHat_Wild_Random_huang",
            "CloverHat_Wild_Random_lan","CloverHat_Wild_Random_lv","CloverHat_Wild_Random_zi"}
    
    self.m_wildRandomBg:setVisible(true)
    self.m_wildRandomBg:runCsbAction("actionframe",false,function(  )
        self.m_wildRandomBg:setVisible(false)
    end)
    self.m_wildRandom:setVisible(true)
    util_spinePlay(self.m_wildRandom,"actionframe")
    util_spineEndCallFunc(self.m_wildRandom,"actionframe",function(  )
        self.m_wildRandom:setVisible(false)
    end)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        local maxWaitTime = 0

        for i=1,#_fixPos do

            maxWaitTime = 0.2 * (i -1) 
            local pos = _fixPos[i]
            local node = cc.Node:create()
            self.m_BaseLockWildNode:addChild(node)
            local wildSpr = util_createAnimation("Socre_CloverHat_Wild.csb")
            node:addChild(wildSpr)
            node:setPosition(util_getOneGameReelsTarSpPos(self,pos))
            wildSpr:setVisible(false)
            

            local ramdomFireworkNode = util_spineCreate(ramdomFireworkName[math.random(1,#ramdomFireworkName)],true,true)
            node:addChild(ramdomFireworkNode)
            ramdomFireworkNode:setVisible(false)

            performWithDelay(node,function(  )

                gLobalSoundManager:playSound("CloverHatSounds/CloverHat_radomShowOneWild.mp3")

                ramdomFireworkNode:setVisible(true)
                util_spinePlay(ramdomFireworkNode,"actionframe")

                performWithDelay(node,function(  )
                    wildSpr:setVisible(true)
                    wildSpr:runCsbAction("actionframe2")
                    wildSpr:findChild("Particle_TurnWild_1"):resetSystem()
                    wildSpr:findChild("Particle_TurnWild_2"):resetSystem()
                end,6/30)



            end,maxWaitTime)
           
            
        end

        performWithDelay(waitNode,function(  )
            
            performWithDelay(waitNode,function(  )
                gLobalSoundManager:setBackgroundMusicVolume(1)
                if _func then
                    _func()
                end
    
                waitNode:removeFromParent()
            end,51/30)

        end,maxWaitTime ) 
        
        

    end,99/30)




end

function CodeGameScreenCloverHatMachine:runSuperFreeSpinLockWildNode(  _func  )

    gLobalSoundManager:setBackgroundMusicVolume(0.1)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local fixPos = fsExtraData.fixPos or {1,5,6,7}

    local ramdomFireworkName = {"CloverHat_Wild_Random_hong","CloverHat_Wild_Random_huang",
            "CloverHat_Wild_Random_lan","CloverHat_Wild_Random_lv","CloverHat_Wild_Random_zi"}
    
      
    if self.m_iReelRowNum == self.m_iReelMaxRow then

        self.m_wildRandomBg_fourRow:setVisible(true)
        self.m_wildRandomBg_fourRow:runCsbAction("actionframe",false,function(  )
            self.m_wildRandomBg_fourRow:setVisible(false)
        end)

        
        self.m_superFsWildRandom_row4:setVisible(true)
        util_spinePlay(self.m_superFsWildRandom_row4,"actionframe")
        util_spineEndCallFunc(self.m_superFsWildRandom_row4,"actionframe",function(  )
            self.m_superFsWildRandom_row4:setVisible(false)
        end)
    else
        self.m_wildRandomBg:setVisible(true)
        self.m_wildRandomBg:runCsbAction("actionframe",false,function(  )
            self.m_wildRandomBg:setVisible(false)
        end)

        self.m_superFsWildRandom:setVisible(true)
        util_spinePlay(self.m_superFsWildRandom,"actionframe")
        util_spineEndCallFunc(self.m_superFsWildRandom,"actionframe",function(  )
            self.m_superFsWildRandom:setVisible(false)
        end)

    end
     
    
    


    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        local maxWaitTime = 0

        for i=1,#fixPos do

            maxWaitTime = 0.2 * (i -1) 
            local pos = fixPos[i]
            local node = cc.Node:create()
            self.m_FsLockWildNode:addChild(node)
            local wildSpr = util_createAnimation("Socre_CloverHat_Wild.csb")
            node:addChild(wildSpr)
            node:setPosition(util_getOneGameReelsTarSpPos(self,pos))
            wildSpr:setVisible(false)
            wildSpr:findChild("Socre_CloverHat_Wild_ditu"):setVisible(true)

            local ramdomFireworkNode = util_spineCreate(ramdomFireworkName[math.random(1,#ramdomFireworkName)],true,true)
            node:addChild(ramdomFireworkNode)
            ramdomFireworkNode:setVisible(false)

            local wildsuperSp =  self:getSupperWildNode(pos)
            if wildsuperSp then
                wildsuperSp:setVisible(false)
            end

            
            performWithDelay(node,function(  )
                local node_1 = node
                local pos_1 = pos
                local wildsuperSp_1 = wildsuperSp
                ramdomFireworkNode:setVisible(true)
                util_spinePlay(ramdomFireworkNode,"actionframe")

                gLobalSoundManager:playSound("CloverHatSounds/CloverHat_radomShowOneWild.mp3")
                
                performWithDelay(node_1,function(  )
                    local node_2 = node_1
                    local pos_2 = pos_1
                    local wildsuperSp_2 = wildsuperSp_1
                    wildSpr:setVisible(true)
                    wildSpr:runCsbAction("actionframe2")
                    wildSpr:findChild("Particle_TurnWild_1"):resetSystem()
                    wildSpr:findChild("Particle_TurnWild_2"):resetSystem()

                    performWithDelay(node_2,function(  )

                        node_2:removeFromParent()

                        if wildsuperSp_2 then
                            wildsuperSp_2:setVisible(true)
                        end
                    end,48/30)
                end,6/30)



            end,maxWaitTime)
           
            
        end

        performWithDelay(waitNode,function(  )
            
            performWithDelay(waitNode,function(  )

                gLobalSoundManager:setBackgroundMusicVolume(1)

                if _func then
                    _func()
                end
    
                waitNode:removeFromParent()
            end,51/30)

        end,maxWaitTime ) 
        
        

    end,30/30)




end

function CodeGameScreenCloverHatMachine:netBackCheckAddWildAction( )
    

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local baseLockWilds =  selfData.baseLockWilds or {}
    if baseLockWilds and #baseLockWilds > 0  then

        self:initBaseLockWildNode( baseLockWilds ,function(  )
            self:netBackReelsStop( )
        end )

    else

        if self.m_superFreeSpinStart then

            self.m_superFreeSpinStart = false
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                -- 第一次进superfree锁定wild的位置
                self:runSuperFreeSpinLockWildNode( function(  )
                    self:netBackReelsStop( )
                end )
            end
            

        else
            self:netBackReelsStop( )
        end
       

    end


    
end

function CodeGameScreenCloverHatMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

function CodeGameScreenCloverHatMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    if self.m_bonusReconnect and self.m_bonusReconnect == true then
        return false
    end

    return true
end

function CodeGameScreenCloverHatMachine:reelDownNotifyPlayGameEffect( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local fixPos = fsExtraData.fixPos or {}
        self:changeSymbolToWild(fixPos )
    end
    

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local baseLockWilds =  selfData.baseLockWilds or {}
    self:changeSymbolToWild(baseLockWilds )

    BaseNewReelMachine.reelDownNotifyPlayGameEffect( self)

end

function CodeGameScreenCloverHatMachine:slotReelDown()

    BaseNewReelMachine.slotReelDown(self)
 
end


---
-- 点击快速停止reel
--
function CodeGameScreenCloverHatMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    self.m_quickStop = true

    BaseNewReelMachine.quicklyStopReel(self,colIndex)

end


function CodeGameScreenCloverHatMachine:showFreeSpinMore(num,func,isAuto)

    self:findChild("fsMoreBg"):setVisible(true)
    util_playFadeInAction(self:findChild("fsMoreBg"),0.5)

    local function newFunc()

        util_playFadeOutAction(self:findChild("fsMoreBg"),0.5,function(  )
            self:findChild("fsMoreBg"):setVisible(false)
        end)

        -- self:resetMusicBg(true)  
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end

    end

    local ownerlist={}
    ownerlist["m_lb_num"]=num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE,ownerlist,newFunc,BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE,ownerlist,newFunc)
    end
end


function CodeGameScreenCloverHatMachine:getBetLevel()
    return self.m_betLevel
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenCloverHatMachine:upateBetLevel()
    local minBet = self:getMinBet()
    self:updateHighLowBetLock(minBet)
end

function CodeGameScreenCloverHatMachine:getMinBet()
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end
    return minBet
end

function CodeGameScreenCloverHatMachine:updateHighLowBetLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if globalData.slotRunData.isDeluexeClub == true then
        if self.m_betLevel ~= 1 then
            self.m_betLevel = 1
            self.m_progress:unlock(self.m_betLevel)
        end
    elseif betCoin >= minBet then
        if self.m_betLevel ~= 1 then
            self.m_betLevel = 1
            self.m_progress:unlock(self.m_betLevel)
        end
    else
        if self.m_betLevel ~= 0 then
            self.m_betLevel = 0
            self:hideMapTipView()
            self.m_progress:lock(self.m_betLevel)
        end
    end
end

function CodeGameScreenCloverHatMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}

    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenCloverHatMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    self:hideMapTipView()
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end
return CodeGameScreenCloverHatMachine






