---
-- island li
-- 2019年1月26日
-- CodeGameScreenAliceRubyMachine.lua
-- 
-- 玩法：
-- 
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CodeGameScreenAliceRubyMachine = class("CodeGameScreenAliceRubyMachine", BaseFastMachine)

CodeGameScreenAliceRubyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAliceRubyMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 
CodeGameScreenAliceRubyMachine.EFFECT_TYPE_TEN_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 2 
CodeGameScreenAliceRubyMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- 集满bonus

CodeGameScreenAliceRubyMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 
CodeGameScreenAliceRubyMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenAliceRubyMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3   
CodeGameScreenAliceRubyMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 
CodeGameScreenAliceRubyMachine.SYMBOL_FLY_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 100

CodeGameScreenAliceRubyMachine.m_collectList = nil
CodeGameScreenAliceRubyMachine.m_collectData = {}

CodeGameScreenAliceRubyMachine.m_FixBonusLayer  = nil
CodeGameScreenAliceRubyMachine.m_FixBonusKuang  = nil
CodeGameScreenAliceRubyMachine.m_FreeSpinFixBonusKuang  = nil

CodeGameScreenAliceRubyMachine.m_betLevel = nil -- betlevel 0 1 

CodeGameScreenAliceRubyMachine.m_betNetKuangData = nil -- 不同bet对应的框数据

CodeGameScreenAliceRubyMachine.m_betTotalCoins = 0 --本地存储一份betid

CodeGameScreenAliceRubyMachine.m_isOutLines = nil --是否是断线


-- 构造函数
function CodeGameScreenAliceRubyMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_collectList = nil
    self.m_FixBonusLayer  = nil
    self.m_FixBonusKuang  = {}
    self.m_betLevel = nil
    self.m_FreeSpinFixBonusKuang  = {}
    self.m_betNetKuangData = {}
    self.m_isOutLines = false
    self.m_betTotalCoins = 0
    self.m_bonusData = {}
    self.m_bigItemInfo = {}
    self.isBigPro = false   --小地图是否是大关

    self.m_isBonusTrigger = false

    --init
    self:initGame()
end

function CodeGameScreenAliceRubyMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "AliceRubySounds/AliceRuby_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "AliceRubySounds/AliceRuby_scatter_down2.mp3"
        else
            soundPath = "AliceRubySounds/AliceRuby_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenAliceRubyMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAliceRubyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AliceRuby"  
end

function CodeGameScreenAliceRubyMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar
    self.m_gameBg:runCsbAction("normal",true)

    local node_bar = self:findChild("Alice_jishu_base")
    self.m_baseCollectBar = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectTimesBarView")        --收集次数
    node_bar:addChild(self.m_baseCollectBar)
    self.m_baseCollectBar:setPosition(0,0)

    self.m_AliceRubyGuoChangView = util_spineCreate("Socre_AliceRuby_freegc",true,true)            --过场
    self:addChild(self.m_AliceRubyGuoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
    self.m_AliceRubyGuoChangView:setPosition(display.width/2,display.height/2)
    self.m_AliceRubyGuoChangView:setVisible(false)

    self.m_topCollectBar = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectBarView")          --收集进度条部分
    self:findChild("top"):addChild(self.m_topCollectBar)
    self.m_topCollectBar:runCsbAction("idle",true)

    self.moGuNode = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectActView","AliceRuby_jindu_mogu")      --进度条右边蘑菇
    self.m_topCollectBar:findChild("Alice_jindu_mogu"):addChild(self.moGuNode)
    self.moGuNode:setVisible(false)
    -- self.moGuNode:runCsbAction("idleframe",true)

    self.daGuanNode = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectBarDaGuanTail")      --进度条右边大关
    self.m_topCollectBar:findChild("Alice_jindu_mogu"):addChild(self.daGuanNode)
    self.daGuanNode:setVisible(false)

    self.collectTipView = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectActView","AliceRuby_Map_tips")      --提示按钮
    self.m_clipParent:addChild(self.collectTipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.collectTipView.m_states = nil
    --
    local collectTipViewWorldPos = self:findChild("showTipView"):getParent():convertToWorldSpace(cc.p(self:findChild("showTipView"):getPosition()))
    local collectTipViewPos = self.m_clipParent:convertToNodeSpace(collectTipViewWorldPos)
    
    self.collectTipView:setPosition(collectTipViewPos)
    self.collectTipView:setVisible(false)

    self.m_mapZhezaho = util_createAnimation("AliceRuby_guochang_zhezhao.csb")
    self:findChild("zhezhao"):addChild(self.m_mapZhezaho,1000)

    self.m_FixBonusLayer = cc.Node:create()
    self:findChild("root"):addChild(self.m_FixBonusLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)

    local node_bar = self.m_bottomUI.coinWinNode
    self.m_jiesuanAct = util_createAnimation("AliceRuby_totalwin.csb")
    node_bar:addChild(self.m_jiesuanAct)
    self.m_jiesuanAct:setPositionY(-10)
    self.m_jiesuanAct:setVisible(false)

    self:changeBaseMainUIBg(true)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then    --处理freeSpin最后一次播放音效问题
            local isFreeSpinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)

            if isFreeSpinOver then
    
            else
                if self.m_bIsBigWin then
                    return
                end
            end
        else
            if self.m_bIsBigWin then
                return
            end
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
            soundIndex = 4
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "AliceRubySounds/music_AliceRuby_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
            self.m_winSoundsId = nil
        end)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenAliceRubyMachine:FadeInNode( node,time)
    util_setCascadeOpacityEnabledRescursion(node,true)
    local actLict = {}
    actLict[#actLict + 1] = cc.FadeIn:create(time)
    local sq = cc.Sequence:create(actLict)
    node:runAction(sq)
end

function CodeGameScreenAliceRubyMachine:FadeOutNode( node,time)
    util_setCascadeOpacityEnabledRescursion(node,true)
    local actLict = {}
    actLict[#actLict + 1] = cc.FadeOut:create(time)
    local sq = cc.Sequence:create(actLict)
    node:runAction(sq)
end

function CodeGameScreenAliceRubyMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                gLobalSoundManager:setBackgroundMusicVolume(0)
            end
        end,2.5,self:getModuleName())
    end,0.4,self:getModuleName())
end

function CodeGameScreenAliceRubyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:createMapScroll( )     --创建地图
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins = totalBet  

    self:upateBetLevel()
end

-- function CodeGameScreenAliceRubyMachine:scaleMainLayer()
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

--     if  display.width >= 1500 then
--         mainScale = 1
--     elseif display.width == 1024 and display.height == 768 then 
--         mainScale = 0.82
--     end


--     if globalData.slotRunData.isPortrait == true then
--         if display.height < DESIGN_SIZE.height then
--             mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
--             util_csbScale(self.m_machineNode, mainScale)
--             self.m_machineRootScale = mainScale
--         end
--     else
--         util_csbScale(self.m_machineNode, mainScale)
--         self.m_machineRootScale = mainScale
--         self.m_machineNode:setPositionY(mainPosY + 8)
--     end

-- end



function CodeGameScreenAliceRubyMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()

        local totalBet = globalData.slotRunData:getCurTotalBet( )

        -- 不同的bet切换才刷新框
        if self.m_betTotalCoins ~=  totalBet  then
            self.m_betTotalCoins = totalBet
            -- 根据bet刷新框显示
            self:removeAllBaseKuang()
            self:initCollectKuang(true )
            self:updateCollectTimes( )
            self:changeLockFixNodeNode( )
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)

   gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates( )  then
            if self:getBetLevel() == 0 then
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
end


function CodeGameScreenAliceRubyMachine:changeBaseMainUIBg(isBase)
    if isBase then
        self:findChild("free"):setVisible(false)
    else
        self:findChild("free"):setVisible(true)
    end
end


function CodeGameScreenAliceRubyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAliceRubyMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_AliceRuby_10"
    elseif symbolType == self.SYMBOL_SCORE_11  then
        return "Socre_AliceRuby_11"
    elseif symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_AliceRuby_12"
    elseif symbolType == self.SYMBOL_FIX_BONUS then  
        return "Socre_AliceRuby_FIx_Bonus"
    elseif symbolType == self.SYMBOL_FLY_FIX_BONUS then
        return "Socre_AliceRuby_Bonus_shouji_tuowei"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAliceRubyMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_12,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS,count =  12}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FLY_FIX_BONUS,count =  12}
    
    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenAliceRubyMachine:checkTriggerINFreeSpin( )
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = false  -- 特殊处理

    end

    local isInFs = false
    if hasFreepinFeature == false and 
            self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
            self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or 
                (hasReSpinFeature == true  or hasBonusFeature == true)) then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        -- self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end

function CodeGameScreenAliceRubyMachine:updateCollectTimes( )

    local totalBet = globalData.slotRunData:getCurTotalBet( )  
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 

    local selfdata =  wilddata or {}
    local spinTimes = selfdata.spinTimes or 0
    local oldSpinTimes = selfdata.spinTimes or 0
    if spinTimes then
        if spinTimes == 10 then
            spinTimes = 0
        end
        self.m_baseCollectBar:updateTimes(spinTimes ,10)
    end
end

-- 断线重连 
function CodeGameScreenAliceRubyMachine:MachineRule_initGame(  )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""
        if FreeType == "PickFree" then
            self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
            self.m_fsReelDataIndex = self.COllECT_FS_RUN_STATES
            self.m_bottomUI:showAverageBet()
            self:createSuperFsKuang(nil,true)
        else
            self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
            self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
            -- self:createFsMoveKuang( nil ,true )
        end
    end
    self.m_isOutLines = true
end

function CodeGameScreenAliceRubyMachine:playEffectNotifyNextSpinCall( )
    self.m_bSlotRunning = false
    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

-- 老虎机滚动结束调用
function CodeGameScreenAliceRubyMachine:slotReelDown()
    BaseFastMachine.slotReelDown(self)   
end

--
--单列滚动停止回调
--
function CodeGameScreenAliceRubyMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) 
    and 
    (self:getGameSpinStage( ) ~= QUICK_RUN 
    or self.m_hasBigSymbol == true
    )
    then
         self:creatReelRunAnimation(reelCol + 1)
    end

    

    if self.m_reelDownSoundPlayed  then
        self:playReelDownSound(reelCol,self.m_reelDownSound )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end
    

    
    
    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:setVisible(false)
        end

        local reelEffectOneNode =  self.m_slotEffectLayer:getChildByName("reelEffectNode"..reelCol)
        if reelEffectOneNode and reelEffectOneNode:isVisible() then
            reelEffectOneNode:setVisible(false)
        end
    end
    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end


    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        local isHaveFixSymbol = false
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,iRow,SYMBOL_NODE_TAG))
            if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_BONUS then
                isHaveFixSymbol = true
                targSp:runAnim("buling",false,function(  )
                    targSp:runAnim("idleframe")
                end)

            end
        end

        -- if isHaveFixSymbol == true  then
        --     local soundName = "AliceRuby/music_AliceRuby_Bonus_Down_" .. reelCol .. ".mp3"
        --     -- respinbonus落地音效
        --     gLobalSoundManager:playSound(soundName)
        -- end

    end

    if reelCol == 5 and self:getGameSpinStage( ) ~= QUICK_RUN  then
        local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
        local cash = selfdata.cash or {}
        local lines = cash.lines
        local isWin = false
        if lines and #lines > 0 then
            isWin = true
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenAliceRubyMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal_freespin")
    self.m_gameBg:runCsbAction("normal_freespin",false,function (  )
        self.m_gameBg:runCsbAction("freespin",true)
    end)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenAliceRubyMachine:levelFreeSpinOverChangeEffect()
    self.m_gameBg:runCsbAction("freespin_normal",false,function (  )
        self.m_gameBg:runCsbAction("normal",true)
    end)
end


----------------------------------------框-----------------------------------

function CodeGameScreenAliceRubyMachine:initKuangUI( )
    self:updateCollectData( )
    local selfData = self.m_runSpinResultData.p_selfMakeData 
    local needCount = 0
    local pickScatters =  0
    if selfData then
        needCount = selfData.maxScatters 
        pickScatters =  selfData.pickScatters 
    end
    -- self:updateCollectLoading(pickScatters ,needCount)
    if pickScatters and needCount and pickScatters >= needCount then
        pickScatters = 0
    end
    self.m_topCollectBar:updateLoadingbar(pickScatters ,needCount,true)
    self:updateCollectTimes( )
    self:setBigItemInfo()
    --设置进度条尾部显示
    self:changeProgress()

    local totalBet = globalData.slotRunData:getCurTotalBet( )  
    
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
    local selfdata =  wilddata or {}
    local oldSpinTimes = selfdata.spinTimes or 0
  
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if oldSpinTimes and oldSpinTimes == 10  then
            -- 第10次就不还原固定框了
        else
            self:initCollectKuang( )
        end
        
    else    

        local selfdata = self.m_runSpinResultData.p_fsExtraData or {}
        if selfdata.collect then
            self.m_bottomUI:showAverageBet()
        end
        
        self:createFsMoveKuang( nil, true )
        self.m_baseCollectBar:setVisible(false)
        self.m_topCollectBar:setVisible(false)
    end
end

function CodeGameScreenAliceRubyMachine:removeAllFsKuang( )
    for i=1,#self.m_FreeSpinFixBonusKuang do
        local node = self.m_FreeSpinFixBonusKuang[i]
        node:setVisible(true)
        node:removeFromParent()
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        node.m_baseBoolFlag = true
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end

    self.m_FreeSpinFixBonusKuang = {}
end

function CodeGameScreenAliceRubyMachine:removeAllSuperWildKuang()
    for i=1,#self.m_superFreeSpinFixBonusKuang do
        local node = self.m_superFreeSpinFixBonusKuang[i]
        node:setVisible(true)
        node:removeFromParent()
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        node.m_baseBoolFlag = true
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end
    self.m_superFreeSpinFixBonusKuang = {}
end

function CodeGameScreenAliceRubyMachine:changeFixBonusKuang( )
    
    for k,node in pairs(self.m_FixBonusKuang) do
        local name = node:getName()
        local oldNode = self.m_clipParent:getChildByName(name)
        if oldNode then
            if oldNode.m_baseBoolFlag == nil then
                oldNode.m_baseBoolFlag = true
            end
            self.m_FixBonusKuang[k] = oldNode
        end
    end
end

-- function CodeGameScreenAliceRubyMachine:restAllBaseKuang( )

--     for k,node in pairs(self.m_FixBonusKuang) do
--         local linePos = {}
--         node.m_bInLine = false
--         node:setLinePos(linePos)
--         node:setName("")
--         node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
--     end
--     self.m_FixBonusKuang = {}

-- end

function CodeGameScreenAliceRubyMachine:removeAllBaseKuang( )
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        node:setVisible(true)
        node:removeFromParent()
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        node.m_baseBoolFlag = nil
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end

    self.m_FixBonusKuang = {}
end

function CodeGameScreenAliceRubyMachine:initBetNetKuangData(bets )
    if bets then
        self.m_betNetKuangData = bets
    end
end

function CodeGameScreenAliceRubyMachine:updateBetNetKuangData( )
    local selfdata =  self.m_runSpinResultData.p_selfMakeData
    if selfdata then

        local totalBet = globalData.slotRunData:getCurTotalBet( )
        local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet) )] 
        if wilddata == nil then
            self.m_betNetKuangData[tostring(toLongNumber(totalBet))] = {}
            wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))]
        end
        if selfdata.wildPositions then
            wilddata.wildPositions = selfdata.wildPositions
        end
        
        if selfdata.spinTimes then
            wilddata.spinTimes = selfdata.spinTimes
        end

    end

end




--------------------------------- FreeSpin相关----start-------------------------------------------------

function CodeGameScreenAliceRubyMachine:showEffect_FreeSpin(effectData)

    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

-- FreeSpinstart
function CodeGameScreenAliceRubyMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_custom_enter_fs.mp3")
    local showFSView = function ( ... )
            self:hideMapTipView(true)
            local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
            local FreeType = fsExtraData.FreeType or ""
            local selectReel = fsExtraData.selectReel or ""
            self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
            if FreeType == "PickFree" then
                local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
                if fsWinCoin ~= 0 then
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
                else
                    self.m_bottomUI:updateWinCount("")
                end
                self.m_bottomUI:showAverageBet()
                self:showSuperFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun() --触发fs回调
                    self:createSuperFsKuang(function(  )
                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end)     
                end)
            else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()
                    self:createFsMoveKuang( function(  )
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end )       
                end)
            end
    end
    --  延迟0.5 不做特殊要求都这么延迟
    -- performWithDelay(self,function(  )
        showFSView()    
    -- end,0.5)
end

function CodeGameScreenAliceRubyMachine:showFreeSpinStart(num,func)
    self.m_baseCollectBar:setVisible(false)
    self.m_topCollectBar:setVisible(false)

    -- 避免freespin开始时有空的格子，显得像有BUg一样
    self:changeLockFixNodeNode()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0

    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    -- if spintimes ~= 10  then
    --     self:removeAllBaseKuang( )
    -- end

    if func then
        func()
    end
end
--开始superfs界面
function CodeGameScreenAliceRubyMachine:showSuperFreeSpinStart( num,func )
    self.m_baseCollectBar:setVisible(false)
    self.m_topCollectBar:setVisible(false)
    self:levelFreeSpinEffectChange()
    self:changeBaseMainUIBg()
    self:changeLockFixNodeNode()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0
    if spintimes ~= 10  then
        self:removeAllBaseKuang( )
    end

    self:clearCurMusicBg()
    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_tanBan.mp3")
    local ownerlist={}
    local path = "SuperFreeSpinStart"
    local imgName = nil
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    local selectReel = fsExtraData.selectReel or ""
    local fixPos = fsExtraData.fixPos or {}
    ownerlist["BitmapFontLabel_5"]=num
    local view =  self:showDialog(path,ownerlist,func)
    -- --初始化开始界面的显示位置（留）
    local maxImgNum = 20
    for i=1,maxImgNum do
        local img = view:findChild("Alice_wild_img_" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end
    for i=1,#fixPos do
        local img = view:findChild("Alice_wild_img_" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end
end

--创建superFreeSpin固定框
function CodeGameScreenAliceRubyMachine:createSuperFsKuang( func,isinit)
    self.m_superFreeSpinFixBonusKuang = {}
    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local startWildPositions =  selfData.fixPos or {1,5,6,7}

    --固定wild的位置
    if startWildPositions then
        gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_superFs_show.mp3")
        for i=1,#startWildPositions do
            local v = startWildPositions[i]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            --根据类型获取对应slotNode
            local targSp = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY, false)   
            
            self:checkRemoveOneCacheNode( targSp )

            if targSp  then 
                targSp.m_baseBoolFlag = true
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE        --node所属图形层级(悬浮格子层级)
                local linePos = {}
                linePos[#linePos + 1] = {iX = targSp.p_rowIndex, iY = targSp.p_cloumnIndex}
                targSp.m_bInLine = true         --是否参与连线计算
                targSp:setLinePos(linePos)      --设置参与连线行列坐标
                self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_FIX_NODE_TAG + 1) -- 为了参与连线
                
                targSp:runAnim("bonus_wild")
                targSp:setName("fsSuperKuang_" .. tostring(i))
                local position =  self:getBaseReelsTarSpPos(pos)
                targSp:setPosition(cc.p(position))
                table.insert(self.m_superFreeSpinFixBonusKuang,targSp)
            end
        end
    end
    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,1.5)
end

function CodeGameScreenAliceRubyMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    

    -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_Freespin_end.mp3")

    performWithDelay(self,function(  )
        self:showFreeSpinOverView()
    end,2.5)
    
end


function CodeGameScreenAliceRubyMachine:showFreeSpinOverView()
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_tanBan.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
     local view = self:showFreeSpinOver( strCoins, 
         self.m_runSpinResultData.p_freeSpinsTotalCount,function()
 
             performWithDelay(self,function(  )
                    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                    local currentPos = selfData.currentPos or 0
                     local needCount = self.m_collectData.maxScatters 
                     local pickScatters =  self.m_collectData.pickScatters 
                     local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                     local FreeType = fsExtraData.FreeType or ""
                     
                     if pickScatters == needCount then
                         if fsExtraData.collect then
                             pickScatters = 0
                         end
                     end
 
                     self:updateCollectLoading(pickScatters ,needCount)
 
                     self.m_bottomUI:hideAverageBet()
    
                    local totalBet = globalData.slotRunData:getCurTotalBet( ) 
                    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet) )] 
                    local selfdata =  wilddata or {}
                    local oldSpinTimes = selfdata.spinTimes or 0
    
                    if oldSpinTimes and oldSpinTimes == 10  then
                        -- 第10次就不还原固定框了
                    else
                        self:initCollectKuang( )
                    end
                   
                    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
                    self:clearFrames_Fun()
                    -- 取消掉赢钱线的显示
                    self:clearWinLineEffect()
                    --移除free中的框（wild）
                    if FreeType == "PickFree" then
                        self:removeAllSuperWildKuang()
                        self.m_mapNodePos = currentPos -- 更新最新位置
                        self.m_map.m_currPos = self.m_mapNodePos
                    else
                        self:removeAllFsKuang()
                    end
                    self.m_baseCollectBar:setVisible(true)
                    self.m_topCollectBar:setVisible(true)
                    self:changeBaseMainUIBg(true)
                    self:triggerFreeSpinOverCallFun()
             end,0.5)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},571)
end

function CodeGameScreenAliceRubyMachine:changeLockFixNodeNode( isFreeStart)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0
    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    if spintimes == 10  then
        return
    end

    for colIndex = 1, self.m_iReelColumnNum do
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        for rowIndex = 1, self.m_iReelRowNum do
            local netSymbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            if netSymbolType == self.SYMBOL_FIX_BONUS then
                local symbolNode =  self:getReelParent(colIndex):getChildByTag(self:getNodeTag(colIndex,rowIndex,SYMBOL_NODE_TAG))
                local symbolType = self:getRandomReelType(colIndex, reelDatas)
                while true do
                    if self.m_bigSymbolInfos[symbolType] == nil then
                        break
                    end
                    symbolType = self:getRandomReelType(colIndex, reelDatas)
                end

                while true do
                    if symbolType ~= self.SYMBOL_FIX_BONUS then
                    
                        break
                    end
                    symbolType = self:getRandomReelType(colIndex, reelDatas)
                end

                if symbolNode   then
                    if not symbolNode:isVisible() then
                        symbolNode:setVisible(true)
                        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
                        symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType))
                        symbolNode:runIdleAnim()
                    end
                else
                    local targSp = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)   
                    if targSp  then 
                        targSp.m_baseBoolFlag = true
                        targSp.m_symbolTag = SYMBOL_NODE_TAG
                        targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                        
                        local zorder = self:getBounsScatterDataZorder(symbolType)
                        self:getReelParent(colIndex):addChild(targSp, zorder , self:getNodeTag(colIndex,rowIndex,SYMBOL_NODE_TAG))
                        local position =  self:getNodePosByColAndRow(rowIndex, colIndex) 
                        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(position))
                        local pos = self:getReelParent(colIndex):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                        targSp:setPosition(cc.p(pos))
                    end
                end
            end
        end
    end
end

function CodeGameScreenAliceRubyMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    -- util_setCsbVisible(self.m_baseFreeSpinBar, true)

    
    self.m_baseFreeSpinBar:runCsbAction("start",false,function (  )
        self.m_baseFreeSpinBar:runCsbAction("idle")
    end) 
end

function CodeGameScreenAliceRubyMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    -- util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:runCsbAction("over",false) 
end

function CodeGameScreenAliceRubyMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("fs_tishi")
        self.m_baseFreeSpinBar = util_createView("CodeAliceRubySrc.AliceRubyFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        -- util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:setPosition(0, 0)
    end
end

----------------------------freeSpin相关-----end--------------------------------------------------------

function CodeGameScreenAliceRubyMachine:showGuoChang( func,funcEnd)

    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_GuoChang.mp3")

    self.m_AliceRubyGuoChangView:setVisible(true)
    self:showZheZhao()
    
    util_spinePlay(self.m_AliceRubyGuoChangView,"actionframe",false)
    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,1.8)
end

function CodeGameScreenAliceRubyMachine:showZheZhao( )
    self.m_mapZhezaho:runCsbAction("start",false,function (  )
        self.m_mapZhezaho:runCsbAction("idle")
        self:levelFreeSpinEffectChange()
        self.m_baseCollectBar:setVisible(false)
        self.m_topCollectBar:setVisible(false)
        self:resetMaskLayerNodes()  --将触发的Scatter重置到第一帧（重置连线信息）
    end)
end



---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAliceRubyMachine:MachineRule_SpinBtnCall()
    
    gLobalSoundManager:setBackgroundMusicVolume(1)


    self.isInBonus = false

    self:removeSoundHandler( )
    self.m_jiesuanAct:setVisible(false)
    if self.m_winSoundsId then
        
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil

    end

    self.m_isOutLines = false
    self:hideMapScroll()

    self.m_bSlotRunning = true

    self:hideMapTipView()

    return false -- 用作延时点击spin调用
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenAliceRubyMachine:MachineRule_afterNetWorkLineLogicCalculate()

    self:updateCollectData()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

    self:updateBetNetKuangData()

    
end



--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAliceRubyMachine:addSelfEffect()
    self.m_collectList = nil
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if node then
                        if node.p_symbolType == self.SYMBOL_FIX_BONUS then
                            if not self.m_collectList then
                                self.m_collectList = {}
                            end
                            self.m_collectList[#self.m_collectList + 1] = node
                        end
                    end
                end
            end
        if self.m_collectList and #self.m_collectList > 0 then
            --收集金币
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
        end
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local spinTimes = selfdata.spinTimes
        local kaungList = selfdata.wildPositions or {}
        local PickGame = selfdata.PickGame
        if spinTimes then
            if spinTimes == 10 and kaungList and #kaungList > 0 then
                --第十次所有框都变成wild
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_TEN_COLLECT
            end
        end
        --是否触发收集小游戏
        if PickGame then 
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_FIVE_OF_KIND + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
        end
    end
end


function CodeGameScreenAliceRubyMachine:fixBonusTurnWild( effectData )

    local time = 0.2

    local actList = {}
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        table.insert( actList, node)
    end

    table.sort( actList, function( a,b )

        local icolA = a.p_cloumnIndex
        local icolB = b.p_cloumnIndex

        return icolA < icolB
    end )

    local sortList = {}
    for i=1,#actList do
        local node = actList[i]
        local index = node.p_cloumnIndex
        local list = sortList[index]
        if list == nil then
            sortList[index] = {}
        end
        table.insert( sortList[index], actList[i] )
    end

    for k,v in pairs(sortList) do
        local list = v
        if list then
            table.sort( list, function( a,b )
                local irowA = a.p_rowIndex 
                local irowB = b.p_rowIndex 
        
                return irowA > irowB
            end )
        end
    end

    
    local sortNodeList = {}
    for i=1,5 do
        local list = sortList[i]
        if list then
            for k = 1,#list do

                table.insert( sortNodeList, list[ k ] )
            end
        end
    end
  
    
    
    for i=1,#sortNodeList do
        
        local node = sortNodeList[i]
        node:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
        node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        node:setTag(SYMBOL_FIX_NODE_TAG + 1)
        node:setName("")
        node.m_baseBoolFlag = true
        local linePos = {}
        linePos[#linePos + 1] = {iX = node.p_rowIndex, iY = node.p_cloumnIndex}
        node.m_bInLine = false
        node:setLinePos(linePos)
        
        performWithDelay(self,function(  )
            gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_BonusTurnWild.mp3")
            node:stopAllActions()
            node:runAnim("bonus_wild",false)
        end,((i-1) * time)/2 + 0.2 )
    end


    self.m_FixBonusKuang = {}

    local waitTime = ( #actList * time)
    
    performWithDelay(self,function( )
        effectData.p_isPlay = true
        self:playGameEffect() 
    end,waitTime)
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAliceRubyMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        self:collectFixBonus(effectData )
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_TEN_COLLECT then  
        self:fixBonusTurnWild( effectData )
    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        self:showEffect_CollectBonus(effectData)
    end
	return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAliceRubyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenAliceRubyMachine:beginReel()
    BaseFastMachine.beginReel(self)
    self:changeFixBonusKuang( )
end

-----------------------------------------------------地图相关----start---------------------------------------------------------

function CodeGameScreenAliceRubyMachine:createMapScroll( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0

    self.m_mapNodePos = currentPos

    self.m_map = util_createView("CodeAliceRubySrc.AliceRubyMap.AliceRubyBonusMapScrollView", self.m_bonusData, self.m_mapNodePos)
    self:findChild("map"):addChild(self.m_map)
    self.m_map:setVisible(false)
    -- self:setBigItemInfo()
end

function CodeGameScreenAliceRubyMachine:setBigItemInfo( )
    for k,v in pairs(self.m_bonusData) do
        table.insert( self.m_bigItemInfo,v)
    end
end

function CodeGameScreenAliceRubyMachine:getIsBigType( curPos )
    local pos = 0
    if curPos < 60 then
        pos = curPos + 1
    else
        pos = 1
    end
    for i,v in pairs(self.m_bigItemInfo) do
        if v.pos == pos and v.type == "BIG" then
            return v
        end
    end
    return nil
end

--是否可以点击
function CodeGameScreenAliceRubyMachine:isNormalStates( )
    
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

--展示地图
function CodeGameScreenAliceRubyMachine:showMapScroll(callback,canTouch)
    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true) and callback == nil then
        return
    end

    self.m_bCanClickMap = false

    if self.m_map:getMapIsShow() == true then
        self.m_baseCollectBar:SetFadeOut()
        self.m_map:mapDisappear(function()

            self:resetMusicBg(true)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            self.m_bCanClickMap = true
        end)
    else
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_mapDing.mp3")
        self:hideMapTipView(true)
        self:removeSoundHandler( )
        self.m_baseCollectBar:setFadeIn()
        
        performWithDelay(self,function (  )
            self:resetMusicBg(nil,"AliceRubySounds/AliceRuby_mapBG.mp3")
        end,0.4)
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

function CodeGameScreenAliceRubyMachine:hideMapScroll()
    if self.m_map:getMapIsShow() == true then
        self.m_bCanClickMap = false
        self:resetMusicBg(true)
        self.m_baseCollectBar:SetFadeOut()
        self.m_map:mapDisappear(function()
            self.m_bCanClickMap = true
        end)

    end
end

--提示
function CodeGameScreenAliceRubyMachine:clickMapTipView( )
    if self.m_map:getMapIsShow() ~= true and self.m_bSlotRunning ~= true then
        if not self.collectTipView:isVisible() then
            self:showMapTipView( )
        else    
            self:hideMapTipView( )
        end
    end
end

function CodeGameScreenAliceRubyMachine:showMapTipView( )
    if self:isNormalStates( ) then  --是否可以点击
        if self.collectTipView.m_states == nil or  self.collectTipView.m_states == "idle" then
            self.collectTipView:setVisible(true)
            self.collectTipView.m_states = "show"
            gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_mapDing.mp3")
            self.collectTipView:stopAllActions()
            self.collectTipView:runCsbAction("show",false,function(  )
                self.collectTipView.m_states = "idle"
                self.collectTipView:stopAllActions()
                self.collectTipView:runCsbAction("idle")
                performWithDelay(self.collectTipView,function(  )
                    self.collectTipView:stopAllActions()
                    self.collectTipView:runCsbAction("over",false,function (  )
                        self.collectTipView.m_states = "idle"
                        self.collectTipView:setVisible(false)
                    end)
                end,3)
            end)  
        end
    end
end

function CodeGameScreenAliceRubyMachine:hideMapTipView( _close )
    if self.collectTipView.m_states == "idle" then
        self.collectTipView.m_states = "over"
        self.collectTipView:stopAllActions()
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

function CodeGameScreenAliceRubyMachine:showWinJieSunaAct( )
    self.m_jiesuanAct:setVisible(true)
    local Particle = self.m_jiesuanAct:findChild("Particle_1"):resetSystem()
    self.m_jiesuanAct:runCsbAction("actionframe")
end

-- 创建飞行粒子
function CodeGameScreenAliceRubyMachine:createParticleFly(time,currNode,coins,func)

    local fly =  util_createAnimation("AliceRuby_Map_jiesuanshuzi.csb")
    self:addChild(fly,GD.GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    fly:findChild("m_lb_coin"):setString(util_formatCoins(coins,3))
    gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_flyCoins.mp3")
    fly:runCsbAction("actionframe")
    
    fly:setPosition(cc.p(util_getConvertNodePos(currNode,fly)))

    local endPos = util_getConvertNodePos(self.m_jiesuanAct ,fly)

    
    
    local animation = {}
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        -- fly:findChild("Particle_1"):stopSystem()
        -- fly:findChild("Particle_2"):stopSystem()
        -- fly:findChild("Particle_3"):stopSystem()

        fly:findChild("m_lb_coin"):setVisible(false)
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

---------------------------------------------------地图相关 ------end-------------------------------------------------


---------------------------------------------------collect 相关-------start-------------------------------------------
--更新最大收集和当前收集
function CodeGameScreenAliceRubyMachine:updateCollectData( )
    local selfdata =  self.m_runSpinResultData.p_selfMakeData 
    if selfdata then
        self.m_collectData.maxScatters = selfdata.maxScatters
        self.m_collectData.pickScatters = selfdata.pickScatters
    end
end
--刷新进度条
function CodeGameScreenAliceRubyMachine:updateCollectLoading(pickScatters ,needCount)
    if pickScatters and needCount  then
        self.m_topCollectBar:updateLoadingbar(pickScatters,needCount)
    end
end

function CodeGameScreenAliceRubyMachine:collectFixBonus(effectData )
    local needCount = self.m_collectData.maxScatters 
    local pickScatters =  self.m_collectData.pickScatters 
    local isHaveBouns = false   --是否有收集
    if self.m_collectList and #self.m_collectList > 0 then
        isHaveBouns = true
        self:flyCoins(self.m_collectList,function()
            if self:getBetLevel() == 0 then return end
            --这里刷新进度条 
            self:updateCollectLoading(pickScatters ,needCount)
        end)

        self.m_collectList = nil
    end

    local cash = self.m_runSpinResultData.p_selfMakeData.cash or {}
    local lines = cash.lines

    local spinTimes = self.m_runSpinResultData.p_selfMakeData.spinTimes
    local features = self.m_runSpinResultData.p_features
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""
    if lines and #lines > 0 then
        --第十次所有框都变成wild
        performWithDelay(self,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.7)

    elseif spinTimes == 10 and self.m_FixBonusKuang and #self.m_FixBonusKuang > 0 then
        --第十次所有框都变成wild
        if isHaveBouns then
            performWithDelay(self,function(  )
                effectData.p_isPlay = true
                self:playGameEffect()
            end,2.2)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        
    elseif features and #features == 2 and features[2] == 5 then
        --freeSpin
        performWithDelay(self,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.7)
    elseif pickScatters >= needCount then
        --进入地图
        performWithDelay(self,function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.7)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

---------------------------------------------------collect相关-------end-------------------------------------------

function CodeGameScreenAliceRubyMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.SYMBOL_FIX_BONUS then
                
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end


            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end

function CodeGameScreenAliceRubyMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        for i,v in ipairs(reelDatas) do
            if v == 90 then
                table.remove( reelDatas, i )
            end
        end

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.SYMBOL_FIX_BONUS then
                
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenAliceRubyMachine:initCloumnSlotNodesByNetData()
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount 

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.SYMBOL_FIX_BONUS then
                
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end 
            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder)
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, changeRowIndex, colIndex, true)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = showOrder

            node.p_symbolType = symbolType

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end

-- 处理特殊关卡 遮罩层级
function CodeGameScreenAliceRubyMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

--设置bonus scatter 层级
function CodeGameScreenAliceRubyMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

--改变进度条尾部
function CodeGameScreenAliceRubyMachine:changeProgress()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0
    local data = self:getIsBigType( currentPos )
    if data then
        self.moGuNode:setVisible(false)
        -- self.moGuNode:stopAllAction()
        self.m_topCollectBar:findChild("AliceRuby_jindumogu_di_13"):setVisible(false)
        self.daGuanNode:setVisible(true)
        self.daGuanNode:runCsbAction("idleframe",true)
        --大关wild位置显示
        self.daGuanNode:setWildPos(data)
        self.isBigPro = true
    else
        self.moGuNode:setVisible(true)
        self.m_topCollectBar:findChild("AliceRuby_jindumogu_di_13"):setVisible(true)
        self.moGuNode:runCsbAction("idleframe",true)
        self.daGuanNode:setVisible(false)
        self.isBigPro = false
        -- self.daGuanNode:stopAllAction()
    end
end

---------------------------------------------------bonus相关-------start-------------------------------------------
-- 显示bonus 触发的小游戏
function CodeGameScreenAliceRubyMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    if globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Scatter 的连线， 将其移除， 并且播放一次Scatter 触发内容
    local lineLen = #self.m_reelResultLines

    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
        local time = 1
        local changeNum = 1/(time * 60) 
        local curvolume = 1
        self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
            curvolume = curvolume - changeNum
            if curvolume <= 0 then

                curvolume = 0

                if self.m_updateBgMusicHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
                    self.m_updateBgMusicHandlerID = nil
                end
            end

            gLobalSoundManager:setBackgroundMusicVolume(curvolume)
        end)

        

        performWithDelay(self,function(  )

            -- 停止播放背景音乐
            self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
            -- -- 播放bonus 元素不显示连线
            if scatterLineValue ~= nil then
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()
                self:showBonusAndScatterLineTip(scatterLineValue,function() 
                    performWithDelay(self,function (  )
                        gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                    end,0.3)         
                    
                    -- 播放提示时播放音效        
                    
                    self:showBonusGameView(effectData)
                end)
                self:playScatterTipMusicEffect()
                scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue        
                
            else
                self:showBonusGameView(effectData)
            end
        end,time)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

--重写 显示bonus freespin 触发小格子连线提示处理
function CodeGameScreenAliceRubyMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    
        for iCol=1,self.m_iReelColumnNum do
            for iRow=1,self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol, iRow,SYMBOL_NODE_TAG)
                if symbol ~= nil and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then--这里有空的没有管

                    symbol = self:setSlotNodeEffectParent(symbol)    --播放Scatter动画不循环
        
                    animTime = util_max(animTime, symbol:getAniamDurationByName(symbol:getLineAnimName()) )
                end
            end
        end

    scheduler.performWithDelayGlobal(function()
        callFun()
    end,util_max(2,animTime),self:getModuleName())

end

-- 根据Bonus Game 每关做的处理
--

function CodeGameScreenAliceRubyMachine:showBonusGameView( effectData )
    local features = self.m_runSpinResultData.p_features

    self.m_baseCollectBar:setVisible(false)
    if  features and #features == 2 and features[2] == 5 then      
        local time = 1.5
        -- self:FadeOutNode( self:findChild("root1"),time)
        performWithDelay(self,function( )
            self.m_bottomUI:checkClearWinLabel()
            self:showGuoChang(function (  )
                self:show_Choose_BonusGameView(effectData)
            end)
        end,time)
    end
end

function CodeGameScreenAliceRubyMachine:showEffect_CollectBonus(effectData)
    -- gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_Trigger_Bonus.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currentPos = selfData.currentPos or 0
    self.m_mapNodePos = currentPos -- 更新最新位置
    local LitterGameWin = selfData.LitterGameWin or 0
    self.m_map:updateLittleLevelCoins( self.m_mapNodePos,LitterGameWin )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local PickGame = selfData.PickGame
    self:clearCurMusicBg()
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local tempTeilNode = nil
    if self.isBigPro then
        tempTeilNode = self.daGuanNode
    else
        tempTeilNode = self.moGuNode
    end
    --兔子渐隐
    -- local tuzi = self.m_topCollectBar:findChild("Alice_jindu_tuzi")
    self.m_topCollectBar:setTuziHide(function (  )
        if self.isBigPro then
            gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_collectAll_Big.mp3")
        else
            gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_collectAll.mp3")
        end
        tempTeilNode:runCsbAction("actionframe",false,function(  )
            tempTeilNode:runCsbAction("idleframe",true)
            self.m_map:setMapCanTouch(false)
            self.m_map:hidMoveBtn()
            self:showMapScroll(function(  )
                self.m_map:pandaMove(function(  )
                    if PickGame == "FreeGame" then   --大关
                        -- gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_Trigger_Bonus_Fs.mp3")
                            self:resetMusicBg(true)
                            self.m_topCollectBar:initLoadingbar(0)
                            self.m_topCollectBar:setTuziShow()
                            self.m_baseCollectBar:SetFadeOut()
                            self.m_map:mapDisappear(function ()
                                self:changeProgress()
                                self.m_map:setVisible(false)
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end)
                            
                    else    --小关
                        -- gLobalSoundManager:playSound("CloverHatSounds/music_CloverHat_guanZi_Bian_JinBi.mp3")
                        --创建小关获得的钱数
                        local smallCoin = self.m_map.m_mapLayer.m_vecNodeLevel[self.m_mapNodePos]:findChild("m_lb_coin")
                        smallCoin:setVisible(false)
                        local currNode = self.m_map.m_mapLayer.m_vecNodeLevel[self.m_mapNodePos]
                        
                        self:createParticleFly(0.5,currNode,LitterGameWin,function(  )
                            self.m_map:setMapCanTouch(true)
                            self.m_map:showMoveBtn()
                            local beginCoins =  self.m_serverWinCoins - LitterGameWin
                            self:updateBottomUICoins(beginCoins,LitterGameWin,true )
                            self.m_topCollectBar:initLoadingbar(0)
                            self.m_topCollectBar:setTuziShow()
                            self.m_baseCollectBar:SetFadeOut()
                            self.m_map:mapDisappear(function(  )
                                self:resetMusicBg(true)
                                self:changeProgress()

                                self:checkFeatureOverTriggerBigWin( self.m_serverWinCoins , GameEffect.EFFECT_BONUS)

                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end)
                        end)
                    end
                end, self.m_bonusData, self.m_mapNodePos,LitterGameWin)  
            end,false)
        end)
    end)
    
end

function CodeGameScreenAliceRubyMachine:show_Choose_BonusGameView(effectData)
    -- self:findChild("root1"):setVisible(false)
    local chooseView = util_createView("CodeAliceRubySrc.AliceRubyChooseView",self)
    self:findChild("viewNode"):addChild(chooseView)
    chooseView:setPosition(cc.p(-display.width/2,-display.height/2))
    self:changeBaseMainUIBg()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0

    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    if spintimes ~= 10  then
        self:removeAllBaseKuang( )
    end
    --改变棋盘样式
    chooseView:setEndCall( function(  )
            self:FadeInNode( self:findChild("root1"),0)
            
            -- self:findChild("root1"):setVisible(true)
            self:bonusOverAddFreespinEffect( )

            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮

            if chooseView then
                chooseView:removeFromParent()
                self.m_mapZhezaho:runCsbAction("over")
            end
    end)
end

function CodeGameScreenAliceRubyMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

-- 收集玩法

function CodeGameScreenAliceRubyMachine:removeFlynode(node)
    node:setVisible(true)
    node:removeFromParent()
    node.m_baseBoolFlag = nil
    local symbolType = node.p_symbolType
    self:pushSlotNodeToPoolBySymobolType(symbolType, node)

end

function CodeGameScreenAliceRubyMachine:initCollectKuang(isBetChange )

    local totalBet = globalData.slotRunData:getCurTotalBet( ) 
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet) )] 

    local selfdata = wilddata or {} 
    local kaungList = selfdata.wildPositions or {}
    local spintimes = selfdata.spinTimes or 0


    if isBetChange and  (spintimes == 10) then
        return
    end

    for i=1,#kaungList do
        local v = kaungList[i]
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_FIX_BONUS, fixPos.iX, fixPos.iY, false)   

        self:checkRemoveOneCacheNode( targSp )

        if targSp  then
            targSp.m_baseBoolFlag = true
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            targSp.m_bInLine = false
            targSp:setLinePos(linePos)
            targSp:runAnim("kuang",true)
            targSp:setName(tostring(pos))
            self.m_clipParent:addChild(targSp,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_FIX_NODE_TAG - 1) -- 这里的tag值是为了不参与轮盘小块逻辑

            local position =  self:getBaseReelsTarSpPos(pos )
            targSp:setPosition(cc.p(position))
            table.insert( self.m_FixBonusKuang,targSp)
        end
    end
end


--收集玩法
function CodeGameScreenAliceRubyMachine:flyCoins(list, func)

    for i=1,#self.m_FixBonusKuang do
        local fixBonusKuang = self.m_FixBonusKuang[i]
        if fixBonusKuang then
            fixBonusKuang:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100 )   --将现有的框层级降低
        end
    end
    local endPos = cc.p(self:findChild("top_collect"):getPosition()) 
    local bezTime = 0.34 
    local waitTime = 0.6
    local waitTime_1 = 0.1
    local isShowCollect = false
    if self:getBetLevel() == 0 then
        gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_lowBetZa.mp3")    --收集音效
    else
        gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_CollectBeizi.mp3")    --收集音效
    end
    
    for _, node in pairs(list) do
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self.m_FixBonusLayer:convertToNodeSpace(startPos)

        local coins = self:getSlotNodeBySymbolType(self.SYMBOL_FLY_FIX_BONUS)
        self.m_FixBonusLayer:addChild(coins, 100)
        coins:getCcbProperty("Node_3"):setVisible(true)
        coins:setVisible(false)
        coins:setPosition(newStartPos)
        local particle1 = coins:getCcbProperty("Particle_1")
        local particle2 = coins:getCcbProperty("Particle_2")

        local reelIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex )
        local oldNode = self.m_clipParent:getChildByName(tostring(reelIndex))
        if oldNode then
            oldNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 )   --将oldNode层级提起来
            node:setVisible(false)
            oldNode:stopAllActions()
            if self:getBetLevel() == 0 then
                oldNode:runAnim("lock")
                performWithDelay(oldNode,function(  )
                    oldNode:runAnim("actionframe")
                end,25/30)
            else
                oldNode:runAnim("shouji")
                performWithDelay(oldNode,function(  )
                    oldNode:runAnim("kuang",true)
                end,60/30)
            end
            
        else
            
            self:checkRemoveOneCacheNode( node )

            node.m_baseBoolFlag = true
            local linePos = {}
            node.m_bInLine = false
            node:setLinePos(linePos)
            node:setName(tostring(reelIndex))
            node.m_symbolTag = SYMBOL_FIX_NODE_TAG
            node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            if self.m_signManager then
                local activityData = self.m_signManager.m_activityData
                if activityData then
                    for index = 1,#activityData do
                        local actData = activityData[index]
                        local signTag = actData.signTag
                        local sign = node:getChildByTag(signTag)
                        if not tolua.isnull(sign) then
                            sign:removeFromParent()
                        end
                    end
                end
            end
            
            local posWorld = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
            local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            node:setPosition(cc.p(pos.x, pos.y))
            node:removeFromParent()
            self.m_clipParent:addChild(node, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1, SYMBOL_FIX_NODE_TAG - 1) -- 这里的tag值是为了不参与轮盘小块逻辑
            node:stopAllActions()
            if self:getBetLevel() == 0 then
                node:runAnim("lock")
                performWithDelay(node,function(  )
                    node:runAnim("actionframe")
                end,25/30)
            else
                node:runAnim("shouji")
                performWithDelay(node,function(  )
                    node:runAnim("kuang",true)
                end,60/30)
            end
            
            table.insert( self.m_FixBonusKuang,node)
        end
        if self:getBetLevel() == 1 then
            local actList = {}
            actList[#actList + 1] = cc.DelayTime:create(0.2)
            -- actList[#actList + 1] = cc.CallFunc:create(function(  )
            --     gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_CollectBeizi.mp3")    --收集音效
            -- end)
            actList[#actList + 1] = cc.DelayTime:create(0.4)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                coins:runAnim("shouji")
                coins:setVisible(true)
                particle1:setDuration(-1)     --设置拖尾时间(生命周期)
                particle2:setDuration(-1)
                particle1:setPositionType(0)   --设置可以拖尾
                particle2:setPositionType(0)
                particle1:resetSystem()
                particle2:resetSystem()
            end)
            actList[#actList + 1] = cc.BezierTo:create(bezTime,{cc.p(startPos.x , startPos.y), cc.p(endPos.x, startPos.y), endPos})
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                particle1:stopSystem()--移动结束后将拖尾停掉
                particle2:stopSystem()

                coins:getCcbProperty("Node_3"):setVisible(false)
                self.m_topCollectBar:runCsbAction("actionframe",false,function (  )
                    self.m_topCollectBar:runCsbAction("idle",true)
                end)

                if isShowCollect == false then
                    isShowCollect = true
                end
            end)
            actList[#actList + 1] = cc.DelayTime:create(bezTime )
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                self:removeFlynode(coins)
            end)
            coins:runAction(cc.Sequence:create( actList))
        end
        
                
    end

    if list and #list > 0 then
        self:waitCallFunc( bezTime + waitTime + waitTime_1 ,function(  )
            self:waitCallFunc( 0.1,function(  )
                if func ~= nil then
                    func()
                end
            end)

        end)
    else
        if func ~= nil then
            func()
        end
    end
end

---------------------------------------------------bonus相关-------end-------------------------------------------

function CodeGameScreenAliceRubyMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )
    -- free下不需要考虑更新左上角赢钱
    local endCoins = beiginCoins + currCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    self.m_bottomUI:setIsAddLineWin(false)
    local params = {endCoins,isNotifyUpdateTop,nil,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    globalData.slotRunData.lastWinCoin = lastWinCoin
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenAliceRubyMachine:getBaseReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenAliceRubyMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

-- ---------高低bet

function CodeGameScreenAliceRubyMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenAliceRubyMachine:unlockHigherBet()
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
        local bets = betList[i]
        if bets.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenAliceRubyMachine:updatProgressLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁进度条
            gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_collectJieSuo.mp3")
            self.m_topCollectBar:unLock(self.m_betLevel)
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定进度条
            self.m_topCollectBar:lock(self.m_betLevel)
        end
        
    end 
end

function CodeGameScreenAliceRubyMachine:getMinBet( )
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

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenAliceRubyMachine:upateBetLevel()
    local minBet = self:getMinBet( )
    self:updatProgressLock( minBet ) 
end

function CodeGameScreenAliceRubyMachine:localRequestSpinResult( )
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
    self:getCurrSpinMode() ~= RESPIN_MODE
    then
       
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,data=self.m_collectDataList,betLevel = self:getBetLevel( ) }
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenAliceRubyMachine:requestSpinResult()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local FreeType = fsExtraData.FreeType or ""

        if FreeType == "PickFree" then

            self:localRequestSpinResult( )

        else
            if self.m_FreeSpinFixBonusKuang and #self.m_FreeSpinFixBonusKuang then

                local freeSpinLeftTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
                local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    
                --框开始移动
                self:MoveFsKuang( function(  )
                    self:localRequestSpinResult( )
                end )
    
            else
                self:localRequestSpinResult( )
            end
        end
    else
        local totalBet = globalData.slotRunData:getCurTotalBet( ) 
        local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet) )] 

        local selfdata =  wilddata or {}
        local spinTimes = selfdata.spinTimes or 0
        if spinTimes then

            if spinTimes == 10 then
                spinTimes = 0
            end
            
            self.m_baseCollectBar:updateTimes(spinTimes + 1,10)
        end

        self:localRequestSpinResult( )
    end
end



function CodeGameScreenAliceRubyMachine:createFsMoveKuang( func,isinit)
    self.m_FreeSpinFixBonusKuang = {}

    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local startWildPositions =  selfData.startWildPositions 


    local kaungStarActName = {"up","under","left","right","up_left","up_right","under_right","under_left"}

    if startWildPositions then
        for i=1,#startWildPositions do
            local v = startWildPositions[i]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_FIX_BONUS, fixPos.iX, fixPos.iY, false)   
            
            self:checkRemoveOneCacheNode( targSp )

            if targSp  then 
                targSp.m_baseBoolFlag = true
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                local linePos = {}
                linePos[#linePos + 1] = {}
                targSp.m_bInLine = false
                targSp:setLinePos(linePos)
                targSp:runAnim("kuang",true)
                targSp:setName("fsKuang_" .. tostring(i))
                self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_FIX_NODE_TAG + 1) -- 为了参与连线
                
                if not isinit then
                    if pos > 10 then
                        pos = pos + 21
                    else
                        pos =  pos -21
                    end
                    targSp:setVisible(false)
                end
                local position =  self:getBaseReelsTarSpPos(pos )
                targSp:setPosition(cc.p(position))
                table.insert( self.m_FreeSpinFixBonusKuang,targSp)

                local actName = kaungStarActName[math.random( 1, #kaungStarActName)]
                --if isinit then
                    actName = "kuang"
                --end
                
                if i == 1 then
                    targSp:runAnim(actName,false,function(  )
                        targSp:runAnim("kuang",true)
                        if func then
                            func()
                        end
                    end)
                else
                    targSp:runAnim(actName,false,function(  )
                        targSp:runAnim("kuang",true)
                    end)
                    
                end
            end
        end
    end
end


--移动fs框
function CodeGameScreenAliceRubyMachine:MoveFsKuang( fun )

    local fsKuangNum = #self.m_FreeSpinFixBonusKuang
    self.m_FreeSpinFixBonusKuang = {}
    local moveList= {}
    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildPositions =  selfData.wildPositions 
    if wildPositions then
        for i=1,fsKuangNum do
            local targSp = self.m_clipParent:getChildByName("fsKuang_" .. tostring(i)) 
            targSp:setVisible(true)
            targSp:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_FIX_BONUS ),self.SYMBOL_FIX_BONUS)
            table.insert( self.m_FreeSpinFixBonusKuang, targSp )
            local v = wildPositions[i]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local node = targSp --self.m_FreeSpinFixBonusKuang[i]
            node.p_cloumnIndex = fixPos.iY
            node.p_rowIndex = fixPos.iX
            local linePos = {}
            linePos[#linePos + 1] = {iX = node.p_rowIndex, iY = node.p_cloumnIndex}
            node.m_bInLine = true
            node:setLinePos(linePos)
            local oldPos = cc.p(node:getPosition())
            local position =  self:getBaseReelsTarSpPos(pos )
            local turnOldX = 1
            if (oldPos.x - position.x) < 0 then
                turnOldX = -1
            elseif (oldPos.x - position.x) == 0 then
                turnOldX = 0
            end 
            local turnOldY = 1
            if (oldPos.y - position.y) < 0 then
                turnOldY = -1
            elseif (oldPos.y - position.y) == 0 then
                turnOldY = 0
            end
            local turnNewX =  1
            if (position.x - oldPos.x ) < 0 then
                turnNewX =  -1
            elseif (position.x - oldPos.x ) == 0 then
                turnNewX =  0
            end
            local turnNewY =  1
            if (position.y - oldPos.y ) < 0 then
                turnNewY =  -1
            elseif (position.y - oldPos.y ) == 0 then
                turnNewY =  0
            end
            local actList = {}
            actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                targSp:runAnim("kuang",true)
            end)
            if i == 1 then
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_Bonus_za.mp3")
                end)
            end
            actList[#actList + 1 ] = cc.DelayTime:create(0.1)
            actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                local actList_1 = {}
                actList_1[#actList_1 + 1 ] = cc.ScaleTo:create(1,1.35)
                actList_1[#actList_1 + 1 ] = cc.DelayTime:create(0.3)
                actList_1[#actList_1 + 1 ] = cc.CallFunc:create(function()
                    node:setScale(1.0)
                end)
                local sq_1 = cc.Sequence:create(actList_1)
                node:runAction(sq_1)
            end)
            
            actList[#actList + 1 ] = cc.MoveTo:create(1,cc.p(position))
            actList[#actList + 1 ] = cc.DelayTime:create(0.1)
            -- if i == 1 then
            --     actList[#actList + 1] = cc.CallFunc:create(function(  )
            --         gLobalSoundManager:playSound("AliceRubySounds/music_AliceRuby_Bonus_za.mp3")
            --     end)
            -- end
            actList[#actList + 1 ] = cc.ScaleTo:create(0.1,1)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                targSp:runAnim("bonus_wild",false)
            end)
            if i == 1 then
                actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                    for k=1,#self.m_FreeSpinFixBonusKuang do
                        local node = self.m_FreeSpinFixBonusKuang[k]
                        node.m_baseBoolFlag = true
                        node:setName("fsKuang_" .. tostring(k))
                    end
                    if fun then
                        fun()
                    end
                end)
            end
            local sq = cc.Sequence:create(actList)
            node:runAction(sq)
        end
    end
end

-- 增加赢钱后的 效果
function CodeGameScreenAliceRubyMachine:addLastWinSomeEffect() -- add big win or mega win
    local notAddEffect = self:checkIsAddLastWinSomeEffect( )

    if  notAddEffect then
        return
    end
    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值
    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin
        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN) 
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin
        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin
        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end
    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or
            self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or
                self:checkHasEffectType(GameEffect.EFFECT_EPICWIN) == true or
                    self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenAliceRubyMachine:initGameStatusData(gameData)
    
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and  gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    
    local spin = gameData.spin
    
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end
 
    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    self:setLastWinCoin( totalWinCoins )

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
    
            end
        end 
        self.m_initFeatureData:parseFeatureData(feature)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost 
    end

    if collect and type(collect)=="table" and #collect>0 then 
        for i=1,#collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end

    if gameData.gameConfig ~= nil and  gameData.gameConfig.bets ~= nil then
        self:initBetNetKuangData(gameData.gameConfig.bets)
    end

    if gameData then
        if gameData.gameConfig then
            if gameData.gameConfig.extra then
                if gameData.gameConfig.extra.map then
                    self.m_bonusData = clone(gameData.gameConfig.extra.map)
                end
                
            end
        end
    end

    self:initMachineGame()
end

function CodeGameScreenAliceRubyMachine:checkInitSpinWithEnterLevel( )
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
        if self.m_initFeatureData == nil then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end
        
        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin =  self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin 
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ---- 
        self:checkInitSlotsWithEnterLevel()
        
    end
    return isTriggerEffect,isPlayGameEffect
end

---
-- 进入关卡
--
function CodeGameScreenAliceRubyMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end
    --显示提示
    performWithDelay(self,function (  )
        if self:isNormalStates() then
            self.collectTipView:setVisible(true)
            self.collectTipView.m_states = "show"
            
            self.collectTipView:runCsbAction("show",false,function(  )
                gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_mapDing.mp3")
                self.collectTipView.m_states = "idle"
                self.collectTipView:runCsbAction("idle")
                performWithDelay(self,function(  )
                    self.collectTipView:runCsbAction("over",false,function (  )
                        self.collectTipView.m_states = "idle"
                        self.collectTipView:setVisible(false)
                    end)
                end,3)
            end)
        end
    end,0.3)
    
    
    
    self:initKuangUI( )
    
    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects( )
        self:playGameEffect()
    end
end



function CodeGameScreenAliceRubyMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and 
        #self.m_runSpinResultData.p_features > 0 then
        
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i=1,featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的， 
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes

                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then  -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and 
                        #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then  -- 其他小游戏

                    local isFreeSpinOver = false
                    if self:getCurrSpinMode() == FREE_SPIN_MODE then

                        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
                            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                                isFreeSpinOver = true
                            end
                        end
                
                    end

                    -- freespin over那次的bonus不走底层添加
                    if not isFreeSpinOver then
                       -- 添加 BonusEffect 
                        self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL) 
                    end
                    
                    
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end

            end
            
        end

    end
end

--
function CodeGameScreenAliceRubyMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        -- slotNode:runLineAnim()
        local animName = slotNode:getLineAnimName()
        slotNode:runAnim(animName)
    end
    return slotNode
end



function CodeGameScreenAliceRubyMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function CodeGameScreenAliceRubyMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    reelEffectNode:retain()
    effectAct:retain()
    reelEffectNode:setName("reelEffectNode"..col)
    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}
    reelEffectNode:setVisible(false)
    return reelEffectNode, effectAct
end

--添加金边
function CodeGameScreenAliceRubyMachine:creatReelRunAnimation(col)
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

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:getParent():setOpacity(255)
    reelEffectNode:setOpacity(255)
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then   -- 快滚背景特效
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

function CodeGameScreenAliceRubyMachine:setBetId( )
    local minBet = self:getMinBet()
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
            -- 大于等于
        if bets.p_totalBetValue >= minBet then

            globalData.slotRunData.iLastBetIdx =   bets.p_betId

            break
        end
    end
    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end
--保留（进度条锁住）
-- function CodeGameScreenAliceRubyMachine:changeBetToUnlock( )
--     if self:getBetLevel() then
--          if self:getBetLevel() == 0 then
--              self:setBetId( )
--          end
--     end 
-- end

--设置长滚信息
function CodeGameScreenAliceRubyMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local addLens = false
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 9) 
                self:setLastReelSymbolList()    
            end
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        local index = self.m_iReelColumnNum - 1
        if col == index and bRunLong then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true
        end
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenAliceRubyMachine:specialSymbolActionTreatment( node)
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
        node:runAnim("buling",false,function(  )
            node:runAnim("idleframe",true)
        end)
    end
end

function CodeGameScreenAliceRubyMachine:getBottomUINode( )
    return "CodeAliceRubySrc.AliceRubyGameBottomNode"
end

function CodeGameScreenAliceRubyMachine:initBottomUI()

    CodeGameScreenAliceRubyMachine.super.initBottomUI(self)
   
    --小关结算反馈
    self.titalWin = util_createView("CodeAliceRubySrc.collect.AliceRubyCollectActView","AliceRuby_totalwin")
    self.m_bottomUI:addChild(self.titalWin)
    self.titalWin:setVisible(false)
end

function CodeGameScreenAliceRubyMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)
    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i=1,#newChilds do
            childs[#childs+1]=newChilds[i]
        end
    end

    for childIndex = 1, #childs do
        local child = childs[childIndex]
        self:moveDownCallFun(child, parentData.cloumnIndex)
    end

    local index = 1

    while index <= columnData.p_showGridCount do -- 只改了这 为了适应freespin
        self:createSlotNextNode(parentData)
        local symbolType = parentData.symbolType
        local node = self:getCacheNode(parentData.cloumnIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
            local slotParentBig = parentData.slotParentBig
            -- 添加到显示列表
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, parentData.order, parentData.tag)
            else
                slotParent:addChild(node, parentData.order, parentData.tag)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(parentData.order)
            node:setTag(parentData.tag)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        end
        
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol

        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        node:runIdleAnim()
        -- node:setVisible(false)
        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- 创建一个假的小块 在回滚停止后移除
            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end
end

function CodeGameScreenAliceRubyMachine:moveDownCallFun(node, colIndex)
    -- 回收对象
    if node and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
        node:setVisible(true)
        node:removeFromParent()
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
        print("回收对象".. node.p_symbolType)
        return
    end

    if node and node.m_baseBoolFlag then -- 使用底层池子的不能用basefast的缓存池机制得自己维护
        node.m_baseBoolFlag = nil
        print("回收对象  m_baseBoolFlag ".. node.p_symbolType)
        node:setVisible(true)
        node:removeFromParent()
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
        return
    end

    local symbolNodeList = self.cacheNodeMap[colIndex]
    if symbolNodeList == nil then
        symbolNodeList = {}
        self.cacheNodeMap[colIndex] = symbolNodeList
    end
    node:reset()
    node:setVisible(false)
    node:setTag(-1)
    node.cacheFlag = true
    table.insert(symbolNodeList, node)
end

-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
--
function CodeGameScreenAliceRubyMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    
    if node and node.m_baseBoolFlag then -- 使用底层池子的不能用basefast的缓存池机制得自己维护
        node.m_baseBoolFlag = nil
    end
    node:setVisible(true)
    BaseFastMachine.pushSlotNodeToPoolBySymobolType(self,symbolType, node)
end

function CodeGameScreenAliceRubyMachine:waitCallFunc( _time,_func)
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        if _func then
            _func()
        end
        node:removeFromParent()
    end,_time)
end

function CodeGameScreenAliceRubyMachine:checkRemoveOneCacheNode(_node )
   
    for kk,value in pairs(self.cacheNodeMap) do
        local symbolNodeList = value
        if symbolNodeList ~= nil then
            for i=#symbolNodeList,1,-1 do
                if _node == symbolNodeList[i] then
                   table.remove(symbolNodeList, i)
                end
            end
        end

    end

end

function CodeGameScreenAliceRubyMachine:triggerFreeSpinCallFun()

    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""

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
        if FreeType == "PickFree" then
            
            globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
            self:showFreeSpinBar()
        else
            globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
            self:showFreeSpinBar()
        end
        
    end

    self:setCurrSpinMode( FREE_SPIN_MODE )
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

function CodeGameScreenAliceRubyMachine:showInLineSlotNodeByWinLines(winLines,startIndex,endIndex,bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
    	bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex=1,#self.m_lineSlotNodes do

                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end

            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end

            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex=startIndex,endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and
            lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then

            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i=1,frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and
                    self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then

                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do

                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex=1,#bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode==nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end

                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode==nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil  then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and
                    self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then

                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do

                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex=1,#bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                if slotNode then
                                    if slotNode.p_symbolType then
            
                                    else
                                        print("__________ 错")
                                    end
                                      
                                end
                                isBigSymbol = true
                                break
                            end
                        end

                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                        if slotNode then
                            if slotNode.p_symbolType then
    
                            else
                                print("__________ 错")
                            end
                              
                        end
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    if slotNode then
                        if slotNode.p_symbolType then

                        else
                            print("__________ 错")
                        end
                          
                    end
                end

                if slotNode then
                    if slotNode.p_symbolType then

                    else
                        print("__________ 错")
                    end
                      
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    if sepcicalNode.p_symbolType then
                   
                    else
                        print("__________ 错")
                    end
                end
                
                  
                if sepcicalNode ~= nil  then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    if slotNode then
                        if slotNode.p_symbolType then
                            self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                        else
                            print("__________ 错")
                        end
                          
                    end
                    
                end

                ---
            end  -- end for i = 1 frameNum

        end -- end if freespin bonus


    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    -- local specialChilds = self:getAllSpecialNode()
    -- for specialIndex =1,#specialChilds do
    --     local specialNode = specialChilds[specialIndex]
    --     checkAddLineSlotNode(specialNode)
    -- end

end

function CodeGameScreenAliceRubyMachine:checkIsAddLastWinSomeEffect( )
    --
    local notAdd = BaseFastMachine.checkIsAddLastWinSomeEffect(self )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local PickGame = selfdata.PickGame
    if PickGame then
        return true
    end
    
    return notAdd
end

function CodeGameScreenAliceRubyMachine:operaUserOutCoins( )
    --金币不足
    -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
    self.m_bSlotRunning = false
    gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NoCoins)
    end
    gLobalPushViewControl:setEndCallBack(function()
        local betCoin = self:getSpinCostCoins() or toLongNumber(0)
        local totalCoin = globalData.userRunData.coinNum or 1
        if betCoin <= totalCoin then
            globalData.rateUsData:resetBankruptcyNoPayCount()
            self:showLuckyVedio()
            return
        end

        -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
        if view then
            view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
        else
            self:showLuckyVedio()
        end
    end)
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
    end
end

function CodeGameScreenAliceRubyMachine:scaleMainLayer()
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
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        local addPos = 10

        if display.height/display.width >= 768/1024 then
            mainScale = 0.95
            addPos = 25
        elseif display.height/display.width < 768/1024 and display.height/display.width >= 640/960 then
            addPos = 25
        elseif display.height/display.width < 640/960 and display.height/display.width >= 768/1228 then
            addPos = 20
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + addPos)
    end
end

function CodeGameScreenAliceRubyMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("free" == _sFeature and self.m_isBonusTrigger) then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenAliceRubyMachine.super.levelDeviceVibrate then
        CodeGameScreenAliceRubyMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenAliceRubyMachine