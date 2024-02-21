---
-- island li
-- 2019年1月26日
-- CodeGameScreenPiggyLegendTreasureMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local PiggyLegendTreasureMusicConfig = require "CodePiggyLegendTreasureSrc.PiggyLegendTreasureMusicConfig"
local CodeGameScreenPiggyLegendTreasureMachine = class("CodeGameScreenPiggyLegendTreasureMachine", BaseNewReelMachine)

CodeGameScreenPiggyLegendTreasureMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenPiggyLegendTreasureMachine.BASE_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- base自定义
CodeGameScreenPiggyLegendTreasureMachine.FREE_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- free自定义
CodeGameScreenPiggyLegendTreasureMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenPiggyLegendTreasureMachine.SYMBOL_SCORE_BLANK = 100               --reSpin空信号 
CodeGameScreenPiggyLegendTreasureMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenPiggyLegendTreasureMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenPiggyLegendTreasureMachine.UPPERREEL_SYMBOL_SCORE_1 = 11 --上棋盘的信号值
CodeGameScreenPiggyLegendTreasureMachine.UPPERREEL_SYMBOL_SCORE_2 = 12
CodeGameScreenPiggyLegendTreasureMachine.UPPERREEL_SYMBOL_SCORE_3 = 13
CodeGameScreenPiggyLegendTreasureMachine.UPPERREEL_SYMBOL_SCORE_4 = 14


-- 构造函数
function CodeGameScreenPiggyLegendTreasureMachine:ctor()
    CodeGameScreenPiggyLegendTreasureMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_isOpenRewaedFreeSpin = true
    self.m_spinRestMusicBG = true
    --存储当前上棋盘的信息
    self.m_upperReelIsFirstPaoJi = {}
    self.m_upperReelData = {}
    for iRow = 1,3 do
        self.m_upperReelData[iRow] = {}
        self.m_upperReelIsFirstPaoJi[iRow] = {}
        for iCol = 1, 5 do
            self.m_upperReelData[iRow][iCol] = {}
            self.m_upperReelIsFirstPaoJi[iRow][iCol] = true
        end
    end
    -- free小BOSS是否是第一次被炮击
    self.m_freeSmallBossIsFirstPaoJi = {}
    for iCol = 1, 5 do
        self.m_freeSmallBossIsFirstPaoJi[iCol] = true
    end
    -- free大BOSS是否是第一次被炮击
    self.m_freeBigBossIsFirstPaoJi = true

    --重新存储base bonus炮弹数据相关
    self.m_baseBonusPaoDanData = {}
    --重新存储free bonus炮弹数据相关
    self.m_freeBonusPaoDanData = {}
    --当前发射炮弹 的索引 base
    self.m_paoDanIndexCur = 1
    --当前发射炮弹 的索引 free
    self.m_paoDanFreeIndexCur = 1
    --当前是 第几次消除
    self.m_removeIndexCur = 1
    -- 存储5个小BOSS
    self.m_freeSmallBoss = {}
    -- 存储5个小BOSS被击败显示宝箱
    self.m_freeSmallBossBox = {}
    -- 存储5飞小BOSS上方的金币
    self.m_freeSmallBossCoin = {}
    --存储free玩法 小BOSS的进度条值
    self.m_freeSmallBossProgress = {5,5,5,5,5}
    -- 存储base下新的bonus图标
    self.m_baseNewBonusNode = {}
    -- base消除临时存储 赢钱
    self.m_baseCurWinCoin = 0
    -- free 临时存储 赢钱
    self.m_freeCurWinCoin = 0
    -- free 第二阶段 炮击次数 用于判断残血
    self.m_secondRoundProgress = 0
    -- 第一次进入残血
    self.m_firstBianCanXue = true
    -- free每次spin收集的临时金币
    self.m_freeSmallCoinTotal = 0
    -- free每次炮击出现的金币停留时间
    self.m_freeSmallCoinStayTime = 0.5
    -- free第一阶段每次炮击生成的小金币位置 索引
    self.m_freePaoJiSmallCoinIndex = {0,0,0,0,0}
    -- free第二阶段每次炮击生成的小金币位置 索引 分左右
    self.m_freePaoJiBigLeftCoinIndex = 0
    self.m_freePaoJiBigRightCoinIndex = 3
    -- 音效配置
    self.m_musicConfig = PiggyLegendTreasureMusicConfig
    --快滚音效
    self.m_reelRunSound = self.m_musicConfig.Sound_Scatter_Quick
    --init
    self:initGame()
end

function CodeGameScreenPiggyLegendTreasureMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("PiggyLegendTreasureConfig.csv", "LevelPiggyLegendTreasureConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {1,3,5}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPiggyLegendTreasureMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PiggyLegendTreasure"  
end

function CodeGameScreenPiggyLegendTreasureMachine:initUI()

    -- util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- 上棋盘
    self.m_upperReel = util_createAnimation("PiggyLegendTreasure_UpperReels.csb")
    self:findChild("Node_reel2"):addChild(self.m_upperReel)

    -- 创建jackpot Super
    self.m_superJackpot = util_createView("CodePiggyLegendTreasureSrc.PiggyLegendTreasureJackPotBarView")
    self:findChild("Node_super"):addChild(self.m_superJackpot)
    self.m_superJackpot:initMachine(self)

    -- free临时赢钱显示框
    self.m_freeWinCoinCurNode = util_createAnimation("PiggyLegendTreasure_FreeWins.csb")
    self:findChild("Node_FreeWins"):addChild(self.m_freeWinCoinCurNode)
    self.m_freeWinCoinCurNode:setVisible(false)

    local BottomNode_bar = self.m_bottomUI:findChild("font_last_win_value")
    self.m_jiesuanAct = util_createAnimation("PiggyLegendTreasure_jiesuan.csb")
    local bottomNodePos = util_convertToNodeSpace(BottomNode_bar,self)
    self:addChild(self.m_jiesuanAct,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    self.m_jiesuanAct:setPosition(bottomNodePos)
    self.m_jiesuanAct:setVisible(false)

    -- 指挥开炮动画
    self.m_zhiHuiKaiPaoNode = util_spineCreate("PiggyLegendTreasure_Zhihui", true, true)
    self:findChild("Node_zhihuikaipao"):addChild(self.m_zhiHuiKaiPaoNode)
    self.m_zhiHuiKaiPaoNode:setPositionX(display.width - display.width*self.m_machineRootScale)
    self.m_zhiHuiKaiPaoNode:setScale(self.m_machineRootScale)
    self.m_zhiHuiKaiPaoNode:setVisible(false)

    -- free阶段 提醒
    self.m_freeTiXingNode = util_createAnimation("PiggyLegendTreasure_FreeGameTips.csb")
    self:findChild("Node_Tips"):addChild(self.m_freeTiXingNode)
    self.m_freeTiXingNode:setVisible(false)

    self:setReelBg(1)
    self:createFiveBoss()

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end
        local features = self.m_runSpinResultData.p_features
        if #features > 1 then
            return
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
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

        local soundName = "PiggyLegendTreasureSounds/sound_PiggyLegendTreasure_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenPiggyLegendTreasureMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "PiggyLegendTreasureSounds/sound_PiggyLegendTreasure_ScatteDown.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

--[[
    创建五个小BOSS
]]
function CodeGameScreenPiggyLegendTreasureMachine:createFiveBoss( )
    -- 创建五个小BOSS
    for bossIndex = 1, 5 do
        local smallBoss
        if bossIndex == 1 or bossIndex == 5 then
            smallBoss = util_spineCreate("Socre_PiggyLegendTreasure_Box3", true, true)
        elseif bossIndex == 2 or bossIndex == 4 then
            smallBoss = util_spineCreate("Socre_PiggyLegendTreasure_Box2", true, true)
        else
            smallBoss = util_spineCreate("Socre_PiggyLegendTreasure_Box1", true, true)
        end
        
        self:findChild("Node_freebox"..bossIndex):addChild(smallBoss)
        local xuetiao = util_createAnimation("PiggyLegendTreasure_xuetiao.csb")
        smallBoss:addChild(xuetiao)
        xuetiao:setPositionY(82*self.m_machineRootScale)
        smallBoss.xuetiao = xuetiao
        xuetiao:setVisible(false)
        self.m_freeSmallBoss[bossIndex] = smallBoss
        smallBoss:setVisible(false)
    end
end

-- freespinbar
function CodeGameScreenPiggyLegendTreasureMachine:initFreeSpinBar( )
    if globalData.slotRunData.isPortrait == true then
        local node_bar = self:findChild("Node_freebar")
        self.m_baseFreeSpinBar =util_createView("CodePiggyLegendTreasureSrc.PiggyLegendTreasureFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:initMachine(self)
    end
end

function CodeGameScreenPiggyLegendTreasureMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        if not self:checkHasGameEffectType(GameEffect.EFFECT_REWARD_FS_START) then
            self:playEnterGameSound(self.m_musicConfig.Sound_EnterGame)
        end
    end,0.4,self:getModuleName())
end

function CodeGameScreenPiggyLegendTreasureMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenPiggyLegendTreasureMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 初始化上棋盘
    self:initUpperReel()
end

function CodeGameScreenPiggyLegendTreasureMachine:addObservers()
    CodeGameScreenPiggyLegendTreasureMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        local betCoin = globalData.slotRunData:getCurTotalBet()
        
        if tonumber(betCoin) ~= tonumber(self.m_curBet) then
            
            self:updataCurBetData(betCoin)
            self.m_curBet = betCoin
            -- self:changeBaseGameMusic(false)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenPiggyLegendTreasureMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenPiggyLegendTreasureMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenPiggyLegendTreasureMachine:updataCurBetData(betCoin)
    
    local curData
    local lastCurData
    local isQieHuanReel = true --判断是否切换上棋盘
    if self.m_betsData and table.nums(self.m_betsData) > 0 then
        curData = self.m_betsData[tostring(toLongNumber(betCoin))]
        lastCurData = self.m_betsData[tostring(toLongNumber(self.m_curBet))]
        if not curData then
            curData = self.m_betsDataDefault
            if not lastCurData then
                isQieHuanReel = false
            end
        end
    else
        curData = self.m_betsDataDefault
        isQieHuanReel = false
    end

    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            if curData.upperReels[iRow][iCol] and curData.upperTimes[iRow][iCol] then
                local isBlank = self:getBigNodePos(curData.upperReels, iRow, iCol)
                -- 判断大图标 自定义左下角的位置 其他位置 当空处理 101代表空
                if isBlank then
                    self.m_upperReelData[iRow][iCol][1] = 101
                    self.m_upperReelData[iRow][iCol][2] = 0
                    self.m_upperReelData[iRow][iCol][3] = 0
                else
                    self.m_upperReelData[iRow][iCol][1] = curData.upperReels[iRow][iCol]
                    self.m_upperReelData[iRow][iCol][2] = curData.upperTimes[iRow][iCol]
                    self.m_upperReelData[iRow][iCol][3] = curData.upperMulti[iRow][iCol]
                end
            end
        end
    end
    if isQieHuanReel then
        -- 初始化上棋盘
        self:initUpperReel()
    else
        -- 初始化上棋盘 只修改金币怪物的数值
        self:initUpperReel(true)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPiggyLegendTreasureMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_PiggyLegendTreasure_Bonus"
    end

    if symbolType == self.SYMBOL_SCORE_BLANK then
        return "Socre_PiggyLegendTreasure_blank"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_PiggyLegendTreasure_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_PiggyLegendTreasure_11"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPiggyLegendTreasureMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenPiggyLegendTreasureMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BLANK,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count = 2}

    return loadNode
end

function CodeGameScreenPiggyLegendTreasureMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBgSpine = util_spineCreate("GameScreenPiggyLegendTreasureBg", true, true) 
    gameBg:findChild("Node_bg"):addChild(self.m_gameBgSpine)

    self.m_gameBg = gameBg
end

--设置棋盘的背景
-- _BgIndex 1bace 2free 
function CodeGameScreenPiggyLegendTreasureMachine:setReelBg(_BgIndex)
    
    if _BgIndex == 1 then
        util_spinePlay(self.m_gameBgSpine, "idleframe", true)
        self:findChild("PiggyLegendTreasure_tizi_1"):setVisible(false)
    elseif _BgIndex == 2 then
        util_spinePlay(self.m_gameBgSpine, "idleframe2", true)
        self:findChild("PiggyLegendTreasure_tizi_1"):setVisible(true)
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenPiggyLegendTreasureMachine:specialSymbolActionTreatment( node)
    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --修改小块层级
        local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType,0)
        symbolNode:runAnim("buling",false,function()
            symbolNode:runAnim("idle",true)
        end)
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenPiggyLegendTreasureMachine:MachineRule_initGame(  )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setReelBg(2)

        self.m_upperReel:setVisible(false)

        local isOpenSecondRound = true
        for _index, _progress in ipairs(fsExtraData.firstRoundProgress) do
            if _progress > 0 then
                isOpenSecondRound = false
                break
            end
        end
        -- 第二阶段
        if isOpenSecondRound then
            self.m_bossFreeSecond = util_spineCreate("Socre_PiggyLegendTreasure_boss", true, true) 
            self:findChild("Node_bigBoss"):addChild(self.m_bossFreeSecond)

            self.m_secondRoundProgress = self.m_runSpinResultData.p_fsExtraData.secondRoundProgress or 0
            self:playBossFreeSecondIdle()

            if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
                self.m_firstBianCanXue = false
                self:playBossFreeSecondIdleCabXue()
            else
                self:playBossFreeSecondIdle()
            end
        else
            for _bossIndex = 1, 5 do
                self.m_freeSmallBoss[_bossIndex]:setVisible(true)
                util_spinePlay(self.m_freeSmallBoss[_bossIndex],"idleframe3",true)
            end
            self.m_freeSmallBossProgress = fsExtraData.firstRoundProgress

            for _index, _progress in ipairs(self.m_freeSmallBossProgress) do
                if self.m_freeSmallBossProgress[_index] > 0 then
                    local reduceIdle = 5 - self.m_freeSmallBossProgress[_index]
                    self.m_freeSmallBoss[_index].xuetiao:setVisible(true)
                    if reduceIdle == 0 then
                        self.m_freeSmallBoss[_index].xuetiao:runCsbAction("idle",false)
                    else
                        self.m_freeSmallBoss[_index].xuetiao:runCsbAction("idle0"..reduceIdle,false)
                    end
                else
                    if self.m_freeSmallBossBox[_index] then
                    else
                        local freeSmallBossBox = util_spineCreate("Socre_PiggyLegendTreasure_Box", true, true)
                        if _index == 1 or _index == 5 then
                            util_spinePlay(freeSmallBossBox,"1idle3",true)
                        elseif _index == 2 or _index == 4 then
                            util_spinePlay(freeSmallBossBox,"1idle2",true)
                        else
                            util_spinePlay(freeSmallBossBox,"1idle1",true)
                        end
                        self.m_freeSmallBossBox[_index] = freeSmallBossBox
                        self.m_freeSmallBoss[_index]:setVisible(false)
                        self:findChild("Node_freebox".._index):addChild(self.m_freeSmallBossBox[_index])
                    end
                end
            end
        end

        self.m_freeCurWinCoin = globalData.slotRunData.lastWinCoin
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenPiggyLegendTreasureMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenPiggyLegendTreasureMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenPiggyLegendTreasureMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:playFreeSpinGuoChangAnim(
            function()
                self:setReelBg(2)

                for _index, _freeSmallBossNode in ipairs(self.m_freeSmallBoss) do
                    _freeSmallBossNode:setVisible(true)
                    _freeSmallBossNode.xuetiao:setVisible(false)
                    util_spinePlay(_freeSmallBossNode,"tiao",false)
     
                    util_spineEndCallFunc(_freeSmallBossNode, "tiao", function()
                        util_spinePlay(_freeSmallBossNode,"idleframe3",true)
                    end)
                end
            end,
            function()
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_FreeStartView)
                self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                    --清空赢钱
                    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
                    self.m_freeCurWinCoin = globalData.slotRunData.lastWinCoin
                    
                    self:triggerFreeSpinCallFun()
                    for _index, _freeSmallBossNode in ipairs(self.m_freeSmallBoss) do
                        _freeSmallBossNode:setVisible(true)
                        _freeSmallBossNode.xuetiao:setVisible(true)
                        _freeSmallBossNode.xuetiao:runCsbAction("chuxian",false)
                    end

                    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_XueChuXian)

                    self.m_freeTiXingNode:setVisible(true)
                    self.m_freeTiXingNode:runCsbAction("chuxian",false)
                    self.m_freeTiXingNode:findChild("Stage1"):setVisible(true)
                    self.m_freeTiXingNode:findChild("Stage2"):setVisible(false)

                    effectData.p_isPlay = true
                    self:playGameEffect()      
                end) 
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self, function(  )
        showFSView()    
    end,0.5)
end


---------------------------------弹版----------------------------------
function CodeGameScreenPiggyLegendTreasureMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    view.m_btnTouchSound = self.m_musicConfig.Sound_FreeStartViewClose
    local smallBoss1 = util_spineCreate("Socre_PiggyLegendTreasure_Box2", true, true)
    local smallBoss2 = util_spineCreate("Socre_PiggyLegendTreasure_Box2", true, true)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:findChild("zhu1"):addChild(smallBoss1)
    view:findChild("zhu2"):addChild(smallBoss2)

    util_spinePlay(smallBoss1,"start",false)
    util_spineEndCallFunc(smallBoss1, "start", function()
        util_spinePlay(smallBoss1,"idle",true)
    end)
    util_spinePlay(smallBoss2,"start",false)
    util_spineEndCallFunc(smallBoss2, "start", function()
        util_spinePlay(smallBoss2,"idle",true)
    end)

    return view
end

function CodeGameScreenPiggyLegendTreasureMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    
    self:showFreeSpinOverView()

    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
end

function CodeGameScreenPiggyLegendTreasureMachine:showFreeSpinOverView()

    local function freeSpinOver()
        local strCoins = self.m_runSpinResultData.p_fsWinCoins
        self:clearCurMusicBg()
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_OverView)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            -- 还原棋盘
            for iCol = 1, self.m_iReelColumnNum  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local rowNew = iRow
                        if iRow == 1 then
                            rowNew = 3
                        elseif iRow == 3 then
                            rowNew = 1
                        end
                        if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.startReels and
                        self.m_runSpinResultData.p_fsExtraData.startReels[rowNew] and self.m_runSpinResultData.p_fsExtraData.startReels[rowNew][iCol] then
                            local symbolType = self.m_runSpinResultData.p_fsExtraData.startReels[rowNew][iCol]
                            self:changeSymbolType(targSp, symbolType, true)
                            targSp:runIdleAnim()
                        end
                    end
                end
            end

            self:putBackScatterNode()

            self:triggerFreeSpinOverCallFun()
            
            self:setReelBg(1)

            self.m_upperReel:setVisible(true)
            self.m_upperReel:runCsbAction("idle",false)

            for _index, _freeSmallBossNode in ipairs(self.m_freeSmallBoss) do
                _freeSmallBossNode:setVisible(false)
            end

            for i, vNode in pairs(self.m_freeSmallBossBox) do
                if vNode then
                    vNode:setVisible(false)
                    vNode:removeFromParent()
                    vNode = nil
                end
            end
            self.m_freeSmallBossProgress = {5,5,5,5,5}

            self.m_freeCurWinCoin = 0
            self:waitWithDelay(1/30, function()
                self.m_freeSmallBossBox = {}
            end)

            if self.m_bossFreeSecond then
                self.m_bossFreeSecond:setVisible(false)
                self.m_bossFreeSecond:removeFromParent()
                self.m_bossFreeSecond = nil
            end

            self.m_secondRoundProgress = 0
            self.m_firstBianCanXue = true

            self.m_freeTiXingNode:setVisible(false)
        end)
        view:findChild("root"):setScale(self.m_machineRootScale)
    end

    if self.m_runSpinResultData.p_fsExtraData.jackpotWin then
        globalData.slotRunData.lastWinCoin = self.m_freeCurWinCoin + self.m_runSpinResultData.p_fsExtraData.jackpotWin
        local params = {self.m_runSpinResultData.p_fsExtraData.jackpotWin,false,true,self.m_freeCurWinCoin}
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
        self.m_freeCurWinCoin = self.m_freeCurWinCoin + self.m_runSpinResultData.p_fsExtraData.jackpotWin

        local jackPotWinView = util_createView("CodePiggyLegendTreasureSrc.PiggyLegendTreasureJackPotWinView")
        gLobalViewManager:showUI(jackPotWinView)
        self.m_superJackpot:runCsbAction("jiesuantb",false,function()
            self.m_superJackpot:runCsbAction("idle",false)
        end)
        jackPotWinView:initViewData(self,self.m_runSpinResultData.p_fsExtraData.jackpotWin,function()
            freeSpinOver()
        end)
    else
        freeSpinOver()
    end

end

function CodeGameScreenPiggyLegendTreasureMachine:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    self:postFreeSpinOverTriggerBigWIn(_coins)
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    self:resetMusicBg()
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenPiggyLegendTreasureMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}

    self:runCsbAction("idle",false)

    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

    local freeOverLang = util_spineCreate("Socre_PiggyLegendTreasure_9", true, true)

    view:findChild("lang"):addChild(freeOverLang)

    util_spinePlay(freeOverLang,"start",false)
    util_spineEndCallFunc(freeOverLang, "start", function()
        util_spinePlay(freeOverLang,"idle",true)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},500)

    return view

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPiggyLegendTreasureMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )

    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPiggyLegendTreasureMachine:addSelfEffect()
    self:getBonusDataByReelDown()

    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons and #storedIcons > 0 then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.BASE_BONUS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BASE_BONUS_EFFECT -- 动画类型
        else
            --自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREE_BONUS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREE_BONUS_EFFECT -- 动画类型
        end
    end
end

--[[
    滚出来bonus之后 处理相关数据
]]
function CodeGameScreenPiggyLegendTreasureMachine:getBonusDataByReelDown( )
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons and #storedIcons > 0 then
        local paoDanNum = 0
        for i,vList in ipairs(storedIcons) do
            for ii,v in ipairs(vList) do
                paoDanNum = paoDanNum + 1
            end
        end
        if paoDanNum >= 12 then
            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Bonus_More)
        end
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            local selfMakeData = self.m_runSpinResultData.p_selfMakeData
            for iRow = 1, self.m_iReelRowNum do
                for iCol = 1, self.m_iReelColumnNum do
                    if selfMakeData.changeReels[1][iRow][iCol] and selfMakeData.changeTimes[1][iRow][iCol] then
                        local isBlank = self:getBigNodePos(selfMakeData.changeReels[1], iRow, iCol)
                        -- 判断大图标 自定义左下角的位置 其他位置 当空处理 101代表空
                        if isBlank then
                            self.m_upperReelData[iRow][iCol][1] = 101
                            self.m_upperReelData[iRow][iCol][2] = 0
                        else
                            self.m_upperReelData[iRow][iCol][1] = selfMakeData.changeReels[1][iRow][iCol]
                            self.m_upperReelData[iRow][iCol][2] = selfMakeData.changeTimes[1][iRow][iCol]
                        end
                    end
                end
            end
            for _, vPos in ipairs(storedIcons) do
                --获取bonus行列信息
                local fixPos = self:getRowAndColByPos(vPos[1])
                for _index = 1, vPos[2] do
                    local paoDanData = {row = fixPos.iX, col = fixPos.iY}
                    table.insert(self.m_baseBonusPaoDanData, paoDanData)
                end
            end
            table.sort( self.m_baseBonusPaoDanData, function(a, b)
                if a.col == b.col then
                    return a.row > b.row
                end
                return a.col < b.col
            end )
        else
            local addColIndex = {}--解析倍数的时候 使用的索引
            for index = 1, 5 do
                addColIndex[index] = 0
            end
            for _, vPos in ipairs(storedIcons) do
                --获取bonus行列信息
                local fixPos = self:getRowAndColByPos(vPos[1])
                for index = 1, vPos[2] do
                    local paoDanData = {row = fixPos.iX, col = fixPos.iY}
                    addColIndex[fixPos.iY] = addColIndex[fixPos.iY] + 1
                    if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.firstRoundMulti and
                        self.m_runSpinResultData.p_fsExtraData.firstRoundMulti[fixPos.iY] and self.m_runSpinResultData.p_fsExtraData.firstRoundMulti[fixPos.iY][addColIndex[fixPos.iY] ] then
                            -- 第一阶段每次击打获得的倍数
                            paoDanData.Multi = self.m_runSpinResultData.p_fsExtraData.firstRoundMulti[fixPos.iY][addColIndex[fixPos.iY]]
                    end
                    table.insert(self.m_freeBonusPaoDanData, paoDanData)
                end
            end

            -- 第二阶段每次击打获得的倍数
            if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.secondRoundMulti then
                for i,v in ipairs(self.m_runSpinResultData.p_fsExtraData.secondRoundMulti) do
                    for j,m in ipairs(self.m_freeBonusPaoDanData) do
                        if not m.Multi then
                            m.Multi = v
                            break
                        end
                    end
                end
            end

            table.sort( self.m_freeBonusPaoDanData, function(a, b)
                if a.col == b.col then
                    return a.row > b.row
                end
                return a.col < b.col
            end )

            -- 随机给free 次数
            if self.m_runSpinResultData.p_freeSpinNewCount and self.m_runSpinResultData.p_freeSpinNewCount > 0 then
                if self.m_runSpinResultData.p_fsExtraData.secondRoundProgress <= 0 then
                    -- 第一阶段只会在打死怪物 或者 打死之后继续打 跳freemoreNum
                    local isBreak = false
                    for bossIndex = 1, 5 do
                        local curAddIndex = 0
                        if isBreak then
                            break
                        end

                        for _, _paoDanData in ipairs(self.m_freeBonusPaoDanData) do
                            if _paoDanData.col == bossIndex then
                                curAddIndex = curAddIndex + 1
                                if self.m_freeSmallBossProgress[bossIndex] == curAddIndex then
                                    isBreak = true
                                    _paoDanData.freeNum = self.m_runSpinResultData.p_freeSpinNewCount
                                    break
                                end
                            end
                        end

                        if isBreak then
                            break
                        end

                        for _, _paoDanData in ipairs(self.m_freeBonusPaoDanData) do
                            if _paoDanData.col == bossIndex then
                                if self.m_freeSmallBossProgress[bossIndex] <= 0 then
                                    isBreak = true
                                    _paoDanData.freeNum = self.m_runSpinResultData.p_freeSpinNewCount
                                    break
                                end
                            end
                        end
                    end
                else
                    local random = math.random(1, #self.m_freeBonusPaoDanData-1)
                    self.m_freeBonusPaoDanData[random].freeNum = self.m_runSpinResultData.p_freeSpinNewCount
                end
            end
        end
    end
end

-- 指挥开炮动画
function CodeGameScreenPiggyLegendTreasureMachine:zhiHuiKaiPaoEffect(func)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if #storedIcons > 0 then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local paoDanNum = 0
            for i,vList in ipairs(storedIcons) do
                for ii,v in ipairs(vList) do
                    paoDanNum = paoDanNum + 1
                end
            end
            if paoDanNum >= 5 then
                self.m_zhiHuiKaiPaoNode:setVisible(true)
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Bonus_KaiPao)
                util_spinePlay(self.m_zhiHuiKaiPaoNode,"actionframe")
                self:waitWithDelay(20/30, function()
                    if func then
                        func()
                    end
                end)
            else
                if func then
                    func()
                end
            end
        else
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winRatio = self.m_runSpinResultData.p_winAmount / lTatolBetNum
            local winEffect = nil
            if winRatio >= self.m_HugeWinLimitRate then
                winEffect = true
            elseif winRatio >= self.m_MegaWinLimitRate then
                winEffect = true
            elseif winRatio >= self.m_BigWinLimitRate then
                winEffect = true
            end
            if winEffect or #storedIcons >= 3 then
                self.m_zhiHuiKaiPaoNode:setVisible(true)
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Bonus_KaiPao)
                util_spinePlay(self.m_zhiHuiKaiPaoNode,"actionframe")
                self:waitWithDelay(20/30, function()
                    if func then
                        func()
                    end
                end)
            else
                if func then
                    func()
                end
            end
        end
    else
        if func then
            func()
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPiggyLegendTreasureMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BASE_BONUS_EFFECT then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:zhiHuiKaiPaoEffect(function()
            self:baseBonusEffect(function()
                effectData.p_isPlay = true
                self:playGameEffect()
    
                self:checkTriggerOrInSpecialGame(function(  )
                    self:reelsDownDelaySetMusicBGVolume( ) 
                end)
            end)
        end)
    end

    if effectData.p_selfEffectType == self.FREE_BONUS_EFFECT then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:zhiHuiKaiPaoEffect(function()
            self:freeBonusEffect(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPiggyLegendTreasureMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenPiggyLegendTreasureMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenPiggyLegendTreasureMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenPiggyLegendTreasureMachine:slotReelDown( )
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons and #storedIcons > 0 then
    else
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( ) 
        end)
    end
    local isHaveBonus = false
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == self.SYMBOL_BONUS then
                        isHaveBonus = true
                        targSp:setVisible(false)
                        self:createNewBonusByRowAndCol(iRow, iCol)
                    end
                end
            end
        end
        if isHaveBonus then
            self:runCsbAction("bianan",false,function()
                self:runCsbAction("idle2",true)
                self:putBackScatterNode()
            end)
        end
    else
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == self.SYMBOL_BONUS then
                        targSp:runAnim("idleframe2", true)
                    end
                end
            end
        end
    end

    CodeGameScreenPiggyLegendTreasureMachine.super.slotReelDown(self)
end

--[[
    在bonus的位置 创建一个新的bonus
]]
function CodeGameScreenPiggyLegendTreasureMachine:createNewBonusByRowAndCol(iRow, iCol)
    local startWorldPos = self:getNodePosByColAndRow( iRow, iCol)
    local startPos = self:findChild("Node_paodan"):convertToNodeSpace(startWorldPos)
    local newBonus = self:getSlotNodeBySymbolType(self.SYMBOL_BONUS)
    newBonus:setPosition(startPos)
    self:findChild("Node_paodan"):addChild(newBonus)
    newBonus:runAnim("idleframe2", true)
    local symbol_node = newBonus:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local coinsView
    if not spineNode.m_csbNode then
        coinsView = util_createAnimation("PiggyLegendTreasure_Bonus_shuzi.csb")
        util_spinePushBindNode(spineNode,"shuzi",coinsView)
        spineNode.m_csbNode = coinsView
    end
    local score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    if score ~= nil then
        spineNode.m_csbNode:findChild("m_lb_num"):setString(score)
    end

    self.m_baseNewBonusNode[iRow.."x"..iCol] = newBonus

end
--
--单列滚动停止回调
--
function CodeGameScreenPiggyLegendTreasureMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe2
        self:waitWithDelay(0.1,function()
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            -- 触发快停
                            if self.m_isQuicklyStop then
                                targSp:runAnim("idle",true)
                            else
                                targSp:runAnim("idle2",true)
                            end
                        end
                    end
                end
            end
        end)
        
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            targSp:runAnim("idle",true)
                        end
                    end
                end
            end
        else
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        targSp:runAnim("idle",true)
                    end
                end
            end
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
        self:triggerLongRunChangeBtnStates()
    end
    
    return isTriggerLongRun
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenPiggyLegendTreasureMachine:showBonusAndScatterLineTip(lineValue,callFun)

    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

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
        if slotNode==nil then
            slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX)
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
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            slotNode:runAnim("actionframe",false,function (  )
                -- slotNode:runAnim("idle",true)
            end)
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenPiggyLegendTreasureMachine:beginReel( )

    CodeGameScreenPiggyLegendTreasureMachine.super.beginReel(self)

    self.m_baseBonusPaoDanData = {}
    self.m_paoDanIndexCur = 1
    self.m_removeIndexCur = 1

    self.m_freeBonusPaoDanData = {}
    self.m_paoDanFreeIndexCur = 1
    self.m_baseCurWinCoin = 0

    for iRow = 1,3 do
        for iCol = 1, 5 do
            self.m_upperReelIsFirstPaoJi[iRow][iCol] = true
        end
    end
    for iCol = 1, 5 do
        self.m_freeSmallBossIsFirstPaoJi[iCol] = true
    end
    self.m_freeBigBossIsFirstPaoJi = true

    self:runCsbAction("idle",false)
end

function CodeGameScreenPiggyLegendTreasureMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- 延时函数
function CodeGameScreenPiggyLegendTreasureMachine:waitWithDelay(time, func)
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

function CodeGameScreenPiggyLegendTreasureMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS then
        self:setSpecialNodeScore(self,{node})
    end
end

function CodeGameScreenPiggyLegendTreasureMachine:enterLevel()
    CodeGameScreenPiggyLegendTreasureMachine.super.enterLevel(self)
    
    local betValue = globalData.slotRunData:getCurTotalBet()
    self.m_curBet = betValue

    local curData
    if self.m_betsData and table.nums(self.m_betsData) > 0 then
        curData = self.m_betsData[tostring(toLongNumber(self.m_curBet))]
        if not curData then
            curData = self.m_betsDataDefault
        end
    else
        curData = self.m_betsDataDefault
    end

    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            if curData.upperReels[iRow][iCol] and curData.upperTimes[iRow][iCol] then
                local isBlank = self:getBigNodePos(curData.upperReels, iRow, iCol)
                -- 判断大图标 自定义左下角的位置 其他位置 当空处理 101代表空
                if isBlank then
                    self.m_upperReelData[iRow][iCol][1] = 101
                    self.m_upperReelData[iRow][iCol][2] = 0
                    self.m_upperReelData[iRow][iCol][3] = 0
                else
                    self.m_upperReelData[iRow][iCol][1] = curData.upperReels[iRow][iCol]
                    self.m_upperReelData[iRow][iCol][2] = curData.upperTimes[iRow][iCol]
                    self.m_upperReelData[iRow][iCol][3] = curData.upperMulti[iRow][iCol]
                end
            end
        end
    end

    -- free玩法棋盘上的 bonus置灰
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == self.SYMBOL_BONUS then
                        targSp:runAnim("idleframean",true)
                        local symbol_node = targSp:checkLoadCCbNode()
                        local spineNode = symbol_node:getCsbAct()
                        spineNode.m_csbNode:findChild("m_lb_num"):setString("")
                    end
                end
            end
        end
    end
end

function CodeGameScreenPiggyLegendTreasureMachine:initGameStatusData(gameData)
    if gameData.gameConfig.extra ~= nil then
        self.m_betsData = {}
        local curData
        local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
        local selfMakeData = gameData.gameConfig.extra
        self.m_betsDataDefault = selfMakeData.upperInfo
        if selfMakeData.bets and table.nums(selfMakeData.bets) > 0 then
            self.m_betsData = selfMakeData.bets
            if selfMakeData.bets[tostring(lineBet)] then
                curData = selfMakeData.bets[tostring(lineBet)]
            else
                curData = selfMakeData.upperInfo
            end
        else
            curData = selfMakeData.upperInfo
        end

        for iRow = 1,self.m_iReelRowNum do
            for iCol = 1, self.m_iReelColumnNum do
                if curData.upperReels[iRow][iCol] and curData.upperTimes[iRow][iCol] then
                    local isBlank = self:getBigNodePos(curData.upperReels, iRow, iCol)
                    -- 判断大图标 自定义左下角的位置 其他位置 当空处理 101代表空
                    if isBlank then
                        self.m_upperReelData[iRow][iCol][1] = 101
                        self.m_upperReelData[iRow][iCol][2] = 0
                        self.m_upperReelData[iRow][iCol][3] = 0
                    else
                        self.m_upperReelData[iRow][iCol][1] = curData.upperReels[iRow][iCol]
                        self.m_upperReelData[iRow][iCol][2] = curData.upperTimes[iRow][iCol]
                        self.m_upperReelData[iRow][iCol][3] = curData.upperMulti[iRow][iCol]
                    end
                end
            end
        end
    end
    CodeGameScreenPiggyLegendTreasureMachine.super.initGameStatusData(self, gameData)
end

--每次spin之后 上棋盘变化之后 保存
function CodeGameScreenPiggyLegendTreasureMachine:saveBaseBonusUpperReels( )
    local lineBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    
    if self.m_betsData and self.m_betsData[tostring(lineBet)] then
        for row = 1, 3 do
            for col = 1, 5 do
                self.m_betsData[tostring(lineBet)].upperReels[row][col] = self.m_upperReelData[row][col][1]
                self.m_betsData[tostring(lineBet)].upperTimes[row][col] = self.m_upperReelData[row][col][2]
                self.m_betsData[tostring(lineBet)].upperMulti[row][col] = self.m_upperReelData[row][col][3]
            end
        end
    else
        self.m_betsData[tostring(lineBet)] = {}
        self.m_betsData[tostring(lineBet)].upperReels = {}
        self.m_betsData[tostring(lineBet)].upperTimes = {}
        self.m_betsData[tostring(lineBet)].upperMulti = {}
        for row = 1, 3 do
            self.m_betsData[tostring(lineBet)].upperReels[row] = {}
            self.m_betsData[tostring(lineBet)].upperTimes[row] = {}
            self.m_betsData[tostring(lineBet)].upperMulti[row] = {}
            for col = 1, 5 do
                self.m_betsData[tostring(lineBet)].upperReels[row][col] = self.m_upperReelData[row][col][1]
                self.m_betsData[tostring(lineBet)].upperTimes[row][col] = self.m_upperReelData[row][col][2]
                self.m_betsData[tostring(lineBet)].upperMulti[row][col] = self.m_upperReelData[row][col][3]
            end
        end
    end
end

-- free 过场
function CodeGameScreenPiggyLegendTreasureMachine:playFreeSpinGuoChangAnim(_switchFun, _endFun)

    gLobalSoundManager:playSound(self.m_musicConfig.Sound_GuoChang)
    local bonusGuoChang = util_spineCreate("Socre_PiggyLegendTreasure_Bonus", true, true) 
    self:findChild("Node_guochang"):addChild(bonusGuoChang)

    util_changeNodeParent(self:findChild("Node_guochang"), self.m_upperReel)

    local paoDanGuoChang = util_spineCreate("Socre_PiggyLegendTreasure_Bonus", true, true) 
    self:findChild("Node_guochang"):addChild(paoDanGuoChang)

    local paoJiGuoChang = util_spineCreate("Socre_PiggyLegendTreasure_Paoji", true, true) 
    self:findChild("Node_guochang"):addChild(paoJiGuoChang)
    paoJiGuoChang:setPositionY(280*self.m_machineRootScale)
    paoJiGuoChang:setVisible(false)

    util_spinePlay(bonusGuoChang,"guochang",false)
    util_spinePlay(paoDanGuoChang,"guochang2",false)

    self:waitWithDelay(35/30, function()
        paoJiGuoChang:setVisible(true)
        util_spinePlay(paoJiGuoChang,"gcpaoji",false)
        util_changeNodeParent(self:findChild("Node_reel2"), self.m_upperReel)
        util_changeNodeParent(self:findChild("Node_super_0"), self.m_superJackpot)
        self.m_upperReel:runCsbAction("gc",false,function()
            self.m_upperReel:setVisible(false)
            util_changeNodeParent(self:findChild("Node_super"), self.m_superJackpot)
        end)
        self:waitWithDelay(17/60, function()
            if _switchFun then
                _switchFun()
            end
        end)
    end)

    self:waitWithDelay(80/30, function()
        if _endFun then
            _endFun()
        end
        
        bonusGuoChang:removeFromParent()
        paoJiGuoChang:removeFromParent()
        paoDanGuoChang:removeFromParent()
    end)
end

--[[
    获取小块真实分数
]]
function CodeGameScreenPiggyLegendTreasureMachine:getSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = 0

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end
    return score
end

-- 给bonus小块进行赋值
function CodeGameScreenPiggyLegendTreasureMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local coinsView
    if not spineNode.m_csbNode then
        coinsView = util_createAnimation("PiggyLegendTreasure_Bonus_shuzi.csb")
        util_spinePushBindNode(spineNode,"shuzi",coinsView)
        spineNode.m_csbNode = coinsView
    else
        coinsView = spineNode.m_csbNode
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时小块的分数
        local score = self:getSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        if score ~= nil then
            coinsView:findChild("m_lb_num"):setString(score)
        end
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                coinsView:findChild("m_lb_num"):setString(score)
            end
        end
    end
end

function CodeGameScreenPiggyLegendTreasureMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

function CodeGameScreenPiggyLegendTreasureMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

-- free下bonus发射动画
function CodeGameScreenPiggyLegendTreasureMachine:freeBonusEffect(func)
    -- 炮弹全部发射完了 跳出循环
    if self.m_paoDanFreeIndexCur > #self.m_freeBonusPaoDanData then
        if self.m_runSpinResultData and self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold and 
            self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
            if self.m_firstBianCanXue and self.m_runSpinResultData.p_freeSpinsLeftCount ~= 0 then
                self.m_firstBianCanXue = false
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ComeCanXue)
                util_spinePlay(self.m_bossFreeSecond,"bian",false)
                util_spineEndCallFunc(self.m_bossFreeSecond,"bian",function ()
                    self:playBossFreeSecondIdleCabXue()
                    if func then
                        func()
                    end
                end)
            else
                if func then
                    func()
                end
            end
        else
            if func then
                func()
            end
        end
        return
    end

    local isPlayFlyCoin = false -- 每个位置炮弹打完 或者 全部把 猪打死 要收集金币
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    -- 当前发射的炮弹信息
    local paoDanDataCur = self.m_freeBonusPaoDanData[self.m_paoDanFreeIndexCur]
    local startWorldPos = self:getNodePosByColAndRow( paoDanDataCur.row, paoDanDataCur.col)
    local startPos = self:findChild("Node_paodan"):convertToNodeSpace(startWorldPos)

    local upperSmallBossNode = self:findChild("Node_freebox"..paoDanDataCur.col)
    local endWorldPos = upperSmallBossNode:getParent():convertToWorldSpace(cc.p(upperSmallBossNode:getPositionX(),upperSmallBossNode:getPositionY()))
    local endPos = self:findChild("Node_paodan"):convertToNodeSpace(endWorldPos)

    if self.m_bossFreeSecond then 
        local upperBigBossNode = self:findChild("Node_guochang")
        local endWorldPos1 = upperBigBossNode:getParent():convertToWorldSpace(cc.p(upperBigBossNode:getPositionX(),upperBigBossNode:getPositionY()))
        endPos = self:findChild("Node_paodan"):convertToNodeSpace(endWorldPos1)
        endPos.y = endPos.y + 200
    end

    local symbolNode
    for i,vPos in ipairs(storedIcons) do
        --获取bonus行列信息
        local fixPos = self:getRowAndColByPos(vPos[1])
        if fixPos.iX == paoDanDataCur.row and fixPos.iY == paoDanDataCur.col then
            symbolNode = self:getFixSymbol(paoDanDataCur.col, paoDanDataCur.row, SYMBOL_NODE_TAG)
            -- 第二阶段 击打 bonus需要调整 位置
            if self.m_bossFreeSecond then 
                self:bossFreeSecondBonusRotation(symbolNode, fixPos.iX, fixPos.iY)
            end
        end
    end
    
    -- 最后一发炮弹 特殊处理
    if self:getIsFinallyPaoDan() then
        self:playLastPaoDanEffect(symbolNode, paoDanDataCur, endPos, func)
        return
    end

    if symbolNode and symbolNode.p_symbolType then
        symbolNode:runAnim("actionframe", false, function()
            symbolNode:runAnim("idleframe", true)
        end)
    end
    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Bonus_FaShe)

    self:waitWithDelay(10/30,function()
        local actionList = {}

        local paoDan = util_spineCreate("Socre_PiggyLegendTreasure_Paodan", true, true) 
        self:findChild("Node_paodan"):addChild(paoDan, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        util_spinePlay(paoDan,"paodan1",true)

        startPos.y = startPos.y+80
        if self.m_bossFreeSecond then 
            local Rotation = self:bossFreeSecondBonusRotation(nil, paoDanDataCur.row, paoDanDataCur.col)
            if paoDanDataCur.col == 4 or paoDanDataCur.col == 5 then
                startPos.x = startPos.x - (80 * math.tan(math.rad(Rotation)))
            else
                startPos.x = startPos.x + (80 * math.tan(math.rad(Rotation)))
            end
        end

        paoDan:setPosition(startPos)

        actionList[#actionList + 1] = cc.MoveTo:create(9/30,endPos)

        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self.m_paoDanFreeIndexCur = self.m_paoDanFreeIndexCur + 1
            self:playPaoJiEffect(endPos, paoDanDataCur, func, isPlayFlyCoin)
            paoDan:removeFromParent()
        end)

        local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))

        paoDan:runAction(cc.Sequence:create(spawnAct))

        isPlayFlyCoin = self:showReelsByPaoJiEffect(storedIcons, paoDanDataCur)
        
    end)
end

--[[
    最后一发炮弹 特殊处理
]]
function CodeGameScreenPiggyLegendTreasureMachine:playLastPaoDanEffect(symbolNode, paoDanDataCur, endPos, func)
    -- 最后一发炮弹 特殊处理
    self:showFinallyPaoDanTanBan()

    local startWorldPos = self:getNodePosByColAndRow( paoDanDataCur.row, paoDanDataCur.col)
    local startPos = self:findChild("Node_paodan"):convertToNodeSpace(startWorldPos)
    symbolNode:setVisible(false)
    local newBonus = self:getSlotNodeBySymbolType(self.SYMBOL_BONUS)
    newBonus:setPosition(startPos)
    self:findChild("Node_paodan"):addChild(newBonus)
    self:bossFreeSecondBonusRotation(newBonus, paoDanDataCur.row, paoDanDataCur.col)
    newBonus:runAnim("idleframe", true)
    symbolNode:runAnim("idleframean", true)
    local symbol_node = newBonus:checkLoadCCbNode()
    local spineNodeNew = symbol_node:getCsbAct()
    local coinsView
    if not spineNodeNew.m_csbNode then
        coinsView = util_createAnimation("PiggyLegendTreasure_Bonus_shuzi.csb")
        util_spinePushBindNode(spineNodeNew,"shuzi",coinsView)
        spineNodeNew.m_csbNode = coinsView
    end
    
    spineNodeNew.m_csbNode:findChild("m_lb_num"):setString(1)

    self:waitWithDelay(1,function()
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_LastPaoJi)
        newBonus:runAnim("actionframe2", false, function()
            newBonus:runAnim("idleframe", true)
            if self.m_bossFreeSecond then 
                newBonus:setRotation(0)
                symbolNode:setRotation(0)
                newBonus:removeFromParent()
                symbolNode:setVisible(true)
            end
            self:runCsbAction("idle",false)
        end)

        self.m_paoDanFreeIndexCur = self.m_paoDanFreeIndexCur + 1

        -- 最后一发炮弹 打完之后
        self:updataFinallyPaoDanData(paoDanDataCur.Multi, paoDanDataCur.col, endPos, function()
            self:freeBonusEffect(func)
        end)

        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        spineNode.m_csbNode:findChild("m_lb_num"):setString("")
        
    end)
end

--[[
    炮弹打击之后效果
]]
function CodeGameScreenPiggyLegendTreasureMachine:playPaoJiEffect(endPos, paoDanDataCur, func, isPlayFlyCoin)
    local paoDanJiZhong = util_spineCreate("Socre_PiggyLegendTreasure_Paoji", true, true) 
    self:findChild("Node_paodan"):addChild(paoDanJiZhong, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    -- 第二阶段 击打
    if self.m_bossFreeSecond then 
        paoDanJiZhong:setPosition(endPos)
        
        if self.m_bossFreeSecond:isVisible() then
            local secondRoundProgressCur = self.m_secondRoundProgress
            self.m_secondRoundProgress = self.m_secondRoundProgress + 1

            local bossFanKuiActionframeName

            if secondRoundProgressCur > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
                if paoDanDataCur.col == 1 or paoDanDataCur.col == 2 then
                    bossFanKuiActionframeName = "shouji2"
                elseif paoDanDataCur.col == 4 or paoDanDataCur.col == 5 then
                    bossFanKuiActionframeName = "shouji2_1"
                else
                    bossFanKuiActionframeName = "shouji2_2"
                end 
            else
                if paoDanDataCur.col == 1 or paoDanDataCur.col == 2 then
                    bossFanKuiActionframeName = "shouji"
                elseif paoDanDataCur.col == 4 or paoDanDataCur.col == 5 then
                    bossFanKuiActionframeName = "shouji_1"
                else
                    bossFanKuiActionframeName = "shouji_2"
                end 
            end
            
            if self.m_freeBigBossIsFirstPaoJi then
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BossPaoJi)
            end
            self.m_freeBigBossIsFirstPaoJi = false

            if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_FreeSecondPaoJi)
            else
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_FreeSecondPaoJiJianKang)
            end
            util_spinePlay(self.m_bossFreeSecond,bossFanKuiActionframeName,false)
            util_spineEndCallFunc(self.m_bossFreeSecond,bossFanKuiActionframeName,function ()
                -- 残血状态
                if not self.m_firstBianCanXue then
                    if self.m_paoDanFreeIndexCur > #self.m_freeBonusPaoDanData then
                        util_spinePlay(self.m_bossFreeSecond, "idle2_1", false)
                        util_spineEndCallFunc(self.m_bossFreeSecond, "idle2_1", function()
                            self:playBossFreeSecondIdleCabXue()
                        end)
                    else
                        self:playBossFreeSecondIdleCabXue()
                    end
                else
                    if self.m_paoDanFreeIndexCur > #self.m_freeBonusPaoDanData then
                        local random = math.random(1,10)
                        local randomIdle = "idle_1"
                        if random > 5 then
                            randomIdle = "idle_2"
                            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BossIdle1)
                        else
                            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BossIdle2)
                        end
                        util_spinePlay(self.m_bossFreeSecond, randomIdle, false)
                        util_spineEndCallFunc(self.m_bossFreeSecond, randomIdle, function()
                            self:playBossFreeSecondIdle()
                        end)
                    else
                        self:playBossFreeSecondIdle()
                    end
                end
            end)
        end
        util_spinePlay(paoDanJiZhong,"paoji3",false)
        self:waitWithDelay(0/30,function()
            if self.m_bossFreeSecond.pen then
                self.m_bossFreeSecond.pen:runCsbAction("pen2",false)
            else
                local penCoinsNode = util_createAnimation("PiggyLegendTreasure_Bonus_jinbi.csb")
                self.m_bossFreeSecond:addChild(penCoinsNode)
                penCoinsNode:setPositionY(200)
                penCoinsNode:runCsbAction("pen2",false)
                self.m_bossFreeSecond.pen = penCoinsNode
            end
            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuPenCoin)
            -- 虚弱状态下 播放
            if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
                -- 计算jinbi 的位置
                local upperReelNode = self.m_bossFreeSecond
                local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
                local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
                startPos.y = startPos.y + 200
                
                local jinbi = util_spineCreate("PiggyLegendTreasure_Jinbi", true, true)
                self:findChild("Node_guochang"):addChild(jinbi,10000)
                jinbi:setPosition(startPos)
                util_spinePlay(jinbi,"actionframe",false)
                self:waitWithDelay(21/30,function()
                    jinbi:setVisible(false)
                    jinbi:removeFromParent()
                end)
            end
            self:upperSmallBossNodeUpdataNum(paoDanDataCur.freeNum, paoDanDataCur.row, paoDanDataCur.col, func, paoDanDataCur.Multi, isPlayFlyCoin)
        end)
        
    else
        paoDanJiZhong:setPosition(endPos)
        
        if self.m_freeSmallBoss[paoDanDataCur.col]:isVisible() then
            util_spinePlay(self.m_freeSmallBoss[paoDanDataCur.col],"actionframe3",false)
            util_spineEndCallFunc(self.m_freeSmallBoss[paoDanDataCur.col],"actionframe3",function ()
                util_spinePlay(self.m_freeSmallBoss[paoDanDataCur.col],"idleframe3",true)
            end)
            if self.m_freeSmallBoss[paoDanDataCur.col].pen then
                self.m_freeSmallBoss[paoDanDataCur.col].pen:runCsbAction("pen1",false)
            else
                local upperReelNode = self.m_freeSmallBoss[paoDanDataCur.col]
                local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
                local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
                local penCoinsNode = util_createAnimation("PiggyLegendTreasure_Bonus_jinbi.csb")
                self:findChild("Node_guochang"):addChild(penCoinsNode)
                penCoinsNode:setPosition(startPos)
                penCoinsNode:runCsbAction("pen1",false)
                self.m_freeSmallBoss[paoDanDataCur.col].pen = penCoinsNode
            end
            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuPenCoin)
            
            local paoJiSound
            if paoDanDataCur.col == 1 or paoDanDataCur.col == 5 then
                paoJiSound = self.m_musicConfig.Sound_GuanWu_PaoJi3
            elseif paoDanDataCur.col == 2 or paoDanDataCur.col == 4 then
                paoJiSound = self.m_musicConfig.Sound_GuanWu_PaoJi2
            else
                paoJiSound = self.m_musicConfig.Sound_GuanWu_PaoJi1
            end
            
            if self.m_freeSmallBossIsFirstPaoJi[paoDanDataCur.col] then
                gLobalSoundManager:playSound(paoJiSound)
            end
            self.m_freeSmallBossIsFirstPaoJi[paoDanDataCur.col] = false

        else
            local paoJiName 
            local idleName
            if paoDanDataCur.col == 1 or paoDanDataCur.col == 5 then
                paoJiName = "1z3"
                idleName = "1idle3"
            elseif paoDanDataCur.col == 2 or paoDanDataCur.col == 4 then
                paoJiName = "1z2"
                idleName = "1idle2"
            else
                paoJiName = "1z1"
                idleName = "1idle1"
            end

            util_spinePlay(self.m_freeSmallBossBox[paoDanDataCur.col],paoJiName,false)
            util_spineEndCallFunc(self.m_freeSmallBossBox[paoDanDataCur.col],paoJiName,function ()
                util_spinePlay(self.m_freeSmallBossBox[paoDanDataCur.col],idleName,true)
            end)
            if self.m_freeSmallBossBox[paoDanDataCur.col].pen then
                self.m_freeSmallBossBox[paoDanDataCur.col].pen:runCsbAction("pen1",false)
            else
                local upperReelNode = self.m_freeSmallBossBox[paoDanDataCur.col]
                local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
                local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
                local penCoinsNode = util_createAnimation("PiggyLegendTreasure_Bonus_jinbi.csb")
                self:findChild("Node_guochang"):addChild(penCoinsNode)
                penCoinsNode:setPosition(startPos)
                penCoinsNode:runCsbAction("pen1",false)
                self.m_freeSmallBossBox[paoDanDataCur.col].pen = penCoinsNode
            end
            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BoxPenCoin)
        end
        
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuPaoJi)
        util_spinePlay(paoDanJiZhong,"paoji2",false)
        self:upperSmallBossNodeUpdataNum(paoDanDataCur.freeNum, paoDanDataCur.row, paoDanDataCur.col, func, paoDanDataCur.Multi, isPlayFlyCoin)
    end
    self:waitWithDelay(18/30,function()
        paoDanJiZhong:removeFromParent()
    end)
end

--[[
    炮击之后 处理界面上显示
]]
function CodeGameScreenPiggyLegendTreasureMachine:showReelsByPaoJiEffect(storedIcons, paoDanDataCur)
    local isPlayFlyCoin = false
    for i,vPos in ipairs(storedIcons) do
        --获取bonus行列信息
        local fixPos = self:getRowAndColByPos(vPos[1])
        if fixPos.iX == paoDanDataCur.row and fixPos.iY == paoDanDataCur.col then
            local symbolNode = self:getFixSymbol(paoDanDataCur.col, paoDanDataCur.row, SYMBOL_NODE_TAG)
            vPos[2] = vPos[2] - 1
            if vPos[2] == 0 then
                isPlayFlyCoin = true
                if self.m_bossFreeSecond then 
                    self:waitWithDelay(0.5,function()
                        symbolNode:setRotation(0)
                    end)
                else
                    self:waitWithDelay(0.5,function()
                        local isFirstRoundEnd = true
                        -- 判断一下 是否第一阶段结束
                        for i,v in ipairs(self.m_freeSmallBossProgress) do
                            if v > 0 then
                                isFirstRoundEnd = false
                            end
                        end
                        
                        self:waitWithDelay(0.5,function()
                            if self.m_freeSmallBossFreeNumNode and not isFirstRoundEnd and self.m_freeSmallBossFreeNumNode.row == fixPos.iX
                            and self.m_freeSmallBossFreeNumNode.col == fixPos.iY then
                                self:showFreeBoxFreeNumFly(self.m_freeSmallBossFreeNumNode, self.m_freeSmallBossFreeNumNode.num, function()
                                    if not tolua.isnull(self.m_freeSmallBossFreeNumNode) then                                 
                                        self.m_freeSmallBossFreeNumNode:removeFromParent()
                                    end
                                    self.m_freeSmallBossFreeNumNode = nil
                                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                                end)
                            end
                        end)
                    end)
                end
                self:waitWithDelay(13/30,function()
                    symbolNode:runAnim("yaan",false,function()
                        symbolNode:runAnim("idleframean",true)
                    end)
                end)
            end
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if spineNode.m_csbNode then
                if vPos[2] == 0 then
                    spineNode.m_csbNode:findChild("m_lb_num"):setString("")
                else
                    spineNode.m_csbNode:findChild("m_lb_num"):setString(vPos[2])
                end
            end
        end
    end
    return isPlayFlyCoin
end

--free 刷新小BOSS
function CodeGameScreenPiggyLegendTreasureMachine:upperSmallBossNodeUpdataNum(freeNum, row, col, func, Multi, isPlayFlyCoin)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if not self.m_freeWinCoinCurNode:isVisible() then
        self.m_freeWinCoinCurNode:setVisible(true)
        self.m_freeWinCoinCurNode:findChild("Node_1"):setVisible(true)
        self.m_freeWinCoinCurNode:findChild("m_lb_coins"):setString("0")
        self.m_freeWinCoinCurNode:runCsbAction("chuxian",false)
        self.m_freeTiXingNode:runCsbAction("yincang",false)
    else
        self.m_freeWinCoinCurNode:runCsbAction("idle",false)
    end

    -- 第二阶段 击打
    if self.m_bossFreeSecond then
        self:upperBigBossNodeUpdataNum(freeNum, row, col, func, Multi)
    else
        --判断进度条是否存在
        if self.m_freeSmallBossProgress[col] > 0 then
            self.m_freeSmallBossProgress[col] = self.m_freeSmallBossProgress[col] - 1
            local reduceIdle = 5 - self.m_freeSmallBossProgress[col]
            self.m_freeSmallBoss[col].xuetiao:runCsbAction("jianxue"..reduceIdle,false,function()
                self.m_freeSmallBoss[col].xuetiao:runCsbAction("idle0"..reduceIdle,false)
                if self.m_freeSmallBossProgress[col] == 0 then

                    util_spinePlay(self.m_freeSmallBoss[col],"actionframe4",false)

                    local freeSmallBossBox = util_spineCreate("Socre_PiggyLegendTreasure_Box", true, true)
                    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuChangeBox)

                    if col == 1 or col == 5 then
                        gLobalSoundManager:playSound(self.m_musicConfig.Sound_GuanWu_Die3)
                        util_spinePlay(freeSmallBossBox,"1b3",false)
                        util_spineEndCallFunc(freeSmallBossBox, "1b3", function()
                            util_spinePlay(freeSmallBossBox,"1idle3",true)
                        end)
                    elseif col == 2 or col == 4 then
                        gLobalSoundManager:playSound(self.m_musicConfig.Sound_GuanWu_Die2)
                        util_spinePlay(freeSmallBossBox,"1b2",false)
                        util_spineEndCallFunc(freeSmallBossBox, "1b2", function()
                            util_spinePlay(freeSmallBossBox,"1idle2",true)
                        end)
                    else
                        gLobalSoundManager:playSound(self.m_musicConfig.Sound_GuanWu_Die1)
                        util_spinePlay(freeSmallBossBox,"1b1",false)
                        util_spineEndCallFunc(freeSmallBossBox, "1b1", function()
                            util_spinePlay(freeSmallBossBox,"1idle1",true)
                        end)
                    end

                    self.m_freeSmallBossBox[col] = freeSmallBossBox

                    self.m_freeSmallBoss[col]:setVisible(false)
                    self:findChild("Node_freebox"..col):addChild(self.m_freeSmallBossBox[col])

                    -- 计算jinbi 的位置
                    self:playJinBiCoinsEffect(col)
                end
                if self.m_freeSmallBossProgress[col] == 1 then
                    self.m_freeSmallBoss[col].xuetiao:runCsbAction("bianhong",true)
                end
            end)
        else
            if self.m_freeSmallBossBox[col] then
                
            else
                local freeSmallBossBox = util_spineCreate("Socre_PiggyLegendTreasure_Box", true, true)
                if col == 1 or col == 5 then
                    util_spinePlay(freeSmallBossBox,"1idle3",true)
                elseif col == 2 or col == 4 then
                    util_spinePlay(freeSmallBossBox,"1idle2",true)
                else
                    util_spinePlay(freeSmallBossBox,"1idle1",true)
                end
                self.m_freeSmallBossBox[col] = freeSmallBossBox
                self.m_freeSmallBoss[col]:setVisible(false)
                self:findChild("Node_freebox"..col):addChild(self.m_freeSmallBossBox[col])
            end
            self:playJinBiCoinsEffect(col)
        end

        --上个动画 喷金币 时间35帧
        self:playFreeNumsEffect(freeNum, col, row, Multi)

        self:playCollectCoinsEffect(func)
    end
    
end

--[[
    炮弹击中之后 跳金币
]]
function CodeGameScreenPiggyLegendTreasureMachine:playJinBiCoinsEffect(col)
    -- 计算jinbi 的位置
    local upperReelNode = self:findChild("Node_freebox"..col)
    local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
    local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)

    local jinbiPos = util_convertToNodeSpace(self.m_freeSmallBossBox[col],self)
    local jinbi = util_spineCreate("PiggyLegendTreasure_Jinbi", true, true)
    self:findChild("Node_guochang"):addChild(jinbi,10000)
    jinbi:setPosition(startPos)
    util_spinePlay(jinbi,"actionframe",false)
    self:waitWithDelay(21/30,function()
        jinbi:setVisible(false)
        jinbi:removeFromParent()
    end)
end

--[[
    炮弹击中跳free次数
]]
function CodeGameScreenPiggyLegendTreasureMachine:playFreeNumsEffect(freeNum, col, row, Multi)
    local freeSmallBossFreeNum = nil
    --上个动画 喷金币 时间35帧
    self:waitWithDelay(0/60,function()
        if freeNum then
            freeSmallBossFreeNum = util_createAnimation("PiggyLegendTreasure_ExtraFreeGames.csb")
            local upperReelNode = self.m_bossFreeSecond
            if self.m_freeSmallBossBox[col] then
                upperReelNode = self.m_freeSmallBossBox[col]
            else
                upperReelNode = self.m_freeSmallBoss[col]
            end
            
            local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
            local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
            startPos.y = startPos.y + 150
            
            self:findChild("Node_guochang"):addChild(freeSmallBossFreeNum,10000)
            
            freeSmallBossFreeNum:setPosition(startPos)
            freeSmallBossFreeNum:findChild("m_lb_coins"):setString("+"..freeNum)
            if freeNum > 1 then
                freeSmallBossFreeNum:findChild("PiggyLegendTreasure_JinBi3_1"):setVisible(false)
                freeSmallBossFreeNum:findChild("Pic2"):setVisible(true)
            else
                freeSmallBossFreeNum:findChild("PiggyLegendTreasure_JinBi3_1"):setVisible(true)
                freeSmallBossFreeNum:findChild("Pic2"):setVisible(false)
            end
            
            freeSmallBossFreeNum:runCsbAction("chuxian",false,function()
                freeSmallBossFreeNum:runCsbAction("idle",true)
            end)
            self.m_freeSmallBossFreeNumNode = freeSmallBossFreeNum
            self.m_freeSmallBossFreeNumNode.num = freeNum
            self.m_freeSmallBossFreeNumNode.row = row
            self.m_freeSmallBossFreeNumNode.col = col
        end

        self:showPaoJiCoin(self:findChild("Node_freebox"..col), Multi, col)
        
    end)
end

--[[
    炮击之后 收集
]]
function CodeGameScreenPiggyLegendTreasureMachine:playCollectCoinsEffect(func)
    local isFirstRoundEnd = true
    -- 判断一下 是否第一阶段结束
    for i,v in ipairs(self.m_freeSmallBossProgress) do
        if v > 0 then
            isFirstRoundEnd = false
        end
    end

    local funCallBack = function()
        self:playFreeSecondGuoChang(function()
            self:resetMusicBg(true,self.m_musicConfig.Music_Free_Bg2)
            self:showBossFreeSecondView(function()
                self:freeBonusEffect(func)
            end)
        end)
    end

    local funCallBack1 = function(delayTime)
        if isFirstRoundEnd then
            self:waitWithDelay(delayTime, function()
                if self.m_freeSmallBossFreeNumNode then
                    self:waitWithDelay(0.5,function()
                        self:showFreeBoxFreeNumFly(self.m_freeSmallBossFreeNumNode, self.m_freeSmallBossFreeNumNode.num, function()
                            self.m_freeSmallBossFreeNumNode:removeFromParent()
                            self.m_freeSmallBossFreeNumNode = nil
                            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

                            funCallBack()
                        end)
                    end)
                else
                    funCallBack()
                end
            end)
        else
            self:freeBonusEffect(func)
        end
    end

    self:waitWithDelay(6/60,function()
        -- 收集金币到赢钱框
        if self.m_paoDanFreeIndexCur > #self.m_freeBonusPaoDanData then
            self:waitWithDelay(self.m_freeSmallCoinStayTime + 25/60 + 25/60 + 1,function()
                self:showFreeBoxCoinFly(self.m_freeSmallCoinTotal, function()
                    if self.m_runSpinResultData.p_fsExtraData.jackpotWin then
                        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_JiBaiKuang)
                    end
                    self.m_freeWinCoinCurNode:runCsbAction("xiaoshi",false,function()
                        self.m_freeWinCoinCurNode:setVisible(false)
                        self.m_freeTiXingNode:runCsbAction("chuxian",false)
                        if isFirstRoundEnd then
                            self.m_freeTiXingNode:findChild("Stage1"):setVisible(false)
                            self.m_freeTiXingNode:findChild("Stage2"):setVisible(true)
                        else
                            self.m_freeTiXingNode:findChild("Stage1"):setVisible(true)
                            self.m_freeTiXingNode:findChild("Stage2"):setVisible(false)
                        end
                    end)
                    self.m_freeSmallCoinTotal = 0
                    -- 创建第二阶段 大boss
                    funCallBack1(0.1)
                end)
            end)
        else
            -- 创建第二阶段 大boss
            local delaytime = self.m_freeSmallCoinStayTime + 25/60 + 25/60 + 1
            funCallBack1(delaytime)
        end
    end)
end

-- free 每次炮击跳出来一个小金币 1秒之后收集
function CodeGameScreenPiggyLegendTreasureMachine:showPaoJiCoin(node, Multi, col)
    local upperReelNode = node
    local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
    local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
    
    local freeSmallBossCoin = util_createAnimation("PiggyLegendTreasure_CoinsGrow.csb")
    self:findChild("Node_guochang"):addChild(freeSmallBossCoin, 10000)

    local randomX
    local randomY
    if self.m_bossFreeSecond then
        local randomXList = {-150,-150,-150,150,150,150}
        local randomYList = {250,300,350,250,300,350}
        local freePaojiBigIndexCur
        if col == 3 then
            if math.random(1,10) < 6 then
                col = 1
            else
                col = 5
            end
        end
        if col < 3 then
            if self.m_freePaoJiBigLeftCoinIndex < 3 then
                self.m_freePaoJiBigLeftCoinIndex = self.m_freePaoJiBigLeftCoinIndex + 1
            else
                self.m_freePaoJiBigLeftCoinIndex = 1
            end
            freePaojiBigIndexCur = self.m_freePaoJiBigLeftCoinIndex
        elseif col > 3 then
            if self.m_freePaoJiBigRightCoinIndex < 6 then
                self.m_freePaoJiBigRightCoinIndex = self.m_freePaoJiBigRightCoinIndex + 1
            else
                self.m_freePaoJiBigRightCoinIndex = 4
            end
            freePaojiBigIndexCur = self.m_freePaoJiBigRightCoinIndex
        end
        randomX = randomXList[freePaojiBigIndexCur]
        randomY = randomYList[freePaojiBigIndexCur]
    else
        local randomXList = {-40,-40,-40,40,40,40}
        local randomYList = {120,160,200,120,160,200}
        if col then
            if self.m_freePaoJiSmallCoinIndex[col] < 6 then
                self.m_freePaoJiSmallCoinIndex[col] = self.m_freePaoJiSmallCoinIndex[col] + 1
            else
                self.m_freePaoJiSmallCoinIndex[col] = 1
            end
        end
        randomX = randomXList[self.m_freePaoJiSmallCoinIndex[col]]
        randomY = randomYList[self.m_freePaoJiSmallCoinIndex[col]]
    end
    freeSmallBossCoin:setPositionX(startPos.x + randomX)
    freeSmallBossCoin:setPositionY(startPos.y + randomY)

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = Multi * lineBet
    freeSmallBossCoin:findChild("m_lb_coins"):setString("+"..util_formatCoins(score, 3))

    freeSmallBossCoin:runCsbAction("chuxian",false,function()
        freeSmallBossCoin:runCsbAction("idle",true)
        self:waitWithDelay(self.m_freeSmallCoinStayTime, function()
            self:showFreeSmallCoinFly(freeSmallBossCoin, score, function()
                freeSmallBossCoin:removeFromParent()
                freeSmallBossCoin = nil
            end)
        end)
    end)
end

-- 显示free 小金币收集
function CodeGameScreenPiggyLegendTreasureMachine:showFreeSmallCoinFly(flyNodeOld, winCoins, func)
    local startPos = util_convertToNodeSpace(flyNodeOld,self)

    local endNode = self.m_freeWinCoinCurNode
    local endPos = util_convertToNodeSpace(endNode,self)

    flyNodeOld:setVisible(false)

    local delayTime = 10/60
    local flyNode = util_createAnimation("PiggyLegendTreasure_CoinsGrow.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode:setPosition(startPos)
    flyNode:findChild("m_lb_coins"):setString("+"..util_formatCoins(winCoins, 3))

    flyNode:runCsbAction("shouji",false)
    flyNode:findChild("Particle_1"):setDuration(0.5)     --设置拖尾时间(生命周期)
    flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    self:waitWithDelay(delayTime, function()
        local actList = {}
        actList[#actList + 1] = cc.BezierTo:create(15/60,{cc.p(startPos.x, startPos.y+100), cc.p(endPos.x, startPos.y+100), endPos})
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self.m_freeWinCoinCurNode:runCsbAction("shouji",false)
            self:jumpCoins(self.m_freeWinCoinCurNode, self.m_freeSmallCoinTotal + winCoins, self.m_freeSmallCoinTotal)
            self.m_freeSmallCoinTotal = self.m_freeSmallCoinTotal + winCoins
        end)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            flyNode:findChild("Node_1"):setVisible(false)
            self:waitWithDelay(0.5, function()
                flyNode:removeFromParent()
            end)
            if func then
                func()
            end
        end)
        flyNode:runAction(cc.Sequence:create(actList))
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuCoinFly)
    end)
end

-- 金币跳动
function CodeGameScreenPiggyLegendTreasureMachine:jumpCoins(node, coins, _curCoins, isSecondBoss)
    local curCoins = _curCoins or 0
    -- 每秒60帧
    local coinRiseNum =  (coins - _curCoins) / (0.3 * 60)  

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    --  数字上涨音效
    -- self.m_soundId = gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_jumpCoin.mp3",true)

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < coins and curCoins or coins
        
        -- self:updateWinCoinsLabel(curCoins)
        local sCoins = curCoins
        if node.findChild then --加个判断 不然加速的时候 node可能会提前销毁 可能会报错
            local label = node:findChild("m_lb_coins")
            label:setString(util_formatCoins(sCoins, 3))
        end

        if curCoins >= coins then
            self:stopUpDateCoins()
        end
    end,0.008)
end

function CodeGameScreenPiggyLegendTreasureMachine:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
end

--free 刷新大BOSS
function CodeGameScreenPiggyLegendTreasureMachine:upperBigBossNodeUpdataNum(freeNum, row, col, func, Multi)
    --上个动画 喷金币 时间35帧
    self:waitWithDelay(0/60,function()
        if self.m_bossFreeSecond then
            if freeNum then
                local freeSmallBossFreeNum = util_createAnimation("PiggyLegendTreasure_ExtraFreeGames.csb")
                self.m_bossFreeSecond:addChild(freeSmallBossFreeNum)
                freeSmallBossFreeNum:setPositionY(250)
                
                if freeSmallBossFreeNum then
                    self:showFreeBoxFreeNumFly(freeSmallBossFreeNum, freeNum, function()
                        freeSmallBossFreeNum:removeFromParent()
                        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                    end)
                end
            end

            self:showPaoJiCoin(self.m_bossFreeSecond, Multi, col)

            self:waitWithDelay(6/60,function()
                if self.m_paoDanFreeIndexCur > #self.m_freeBonusPaoDanData then
                    -- 收集金币到赢钱框
                    self:waitWithDelay(self.m_freeSmallCoinStayTime + 25/60 + 25/60 + 1,function()
                        self:showFreeBoxCoinFly(self.m_freeSmallCoinTotal, function()
                            self:freeBonusEffect(func)
                            if self.m_runSpinResultData.p_fsExtraData.jackpotWin then
                                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_JiBaiKuang)
                            end
                            self.m_freeWinCoinCurNode:runCsbAction("xiaoshi",false,function()
                                self.m_freeWinCoinCurNode:setVisible(false)
                                self.m_freeTiXingNode:runCsbAction("chuxian",false)
                                self.m_freeTiXingNode:findChild("Stage1"):setVisible(false)
                                self.m_freeTiXingNode:findChild("Stage2"):setVisible(true)
                            end)
                            self.m_freeSmallCoinTotal = 0
                        end)
                    end)
                else
                    local delayTime = 0
                    if freeNum then
                        delayTime = 25/60
                    end
                    self:waitWithDelay(delayTime,function()
                        self:freeBonusEffect(func)
                    end)
                end
            end)
        end
    end)
end

-- 最后一发炮弹 打完之后
function CodeGameScreenPiggyLegendTreasureMachine:updataFinallyPaoDanData(Multi, col, endPos, func)
    --上个动画 发射炮弹 时间38帧的时候 播放 actionframe2第38帧的时候播paoji5和pen3
    self:waitWithDelay(38/30,function()
        if self.m_bossFreeSecond then
            local paoDanJiZhong = util_spineCreate("Socre_PiggyLegendTreasure_Paoji", true, true) 
            self:findChild("Node_paodan"):addChild(paoDanJiZhong, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
            -- 第二阶段 击打
            paoDanJiZhong:setPosition(endPos)
            util_spinePlay(paoDanJiZhong,"paoji5",false)

            -- 喷金币
            if self.m_bossFreeSecond.pen then
                self.m_bossFreeSecond.pen:runCsbAction("pen3",false)
            else
                local penCoinsNode = util_createAnimation("PiggyLegendTreasure_Bonus_jinbi.csb")
                self.m_bossFreeSecond:addChild(penCoinsNode)
                penCoinsNode:setPositionY(200)
                penCoinsNode:runCsbAction("pen3",false)
                self.m_bossFreeSecond.pen = penCoinsNode
            end

            -- 虚弱状态下 播放
            if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
                -- 计算jinbi 的位置
                local upperReelNode = self.m_bossFreeSecond
                local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
                local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
                startPos.y = startPos.y + 200
                
                local jinbi = util_spineCreate("PiggyLegendTreasure_Jinbi", true, true)
                self:findChild("Node_guochang"):addChild(jinbi,10000)
                jinbi:setPosition(startPos)
                util_spinePlay(jinbi,"actionframe",false)
                self:waitWithDelay(21/30,function()
                    jinbi:setVisible(false)
                    jinbi:removeFromParent()
                end)
            end
        end
    end)

    -- 击中BOSS之后 判断BOSS 是否呗击败 击败会传jackpotWin 字段
    local bossFanKuiActionframeName
    local isJiBai = false
    --击败
    if self.m_runSpinResultData.p_fsExtraData.jackpotWin then
        isJiBai = true
        bossFanKuiActionframeName = "end"
        if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
            bossFanKuiActionframeName = "end_1"
        end
        -- gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_LastPaoJi)
    else
        bossFanKuiActionframeName = "end2"
        if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
            bossFanKuiActionframeName = "end2_1"
        end
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BossWeiDie)
    end
    
    util_spinePlay(self.m_bossFreeSecond,bossFanKuiActionframeName,false)
    util_spineEndCallFunc(self.m_bossFreeSecond,bossFanKuiActionframeName,function ()
        if isJiBai then
            -- self.m_bossFreeSecond:setVisible(false)
        else
            -- 残血状态
            if self.m_secondRoundProgress > self.m_runSpinResultData.p_fsExtraData.secondRoundThreshold then
                self:playBossFreeSecondIdleCabXue()
            else
                local random = math.random(1,10)
                local randomIdle = "idle_1"
                if random > 5 then
                    randomIdle = "idle_2"
                    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BossIdle1)
                else
                    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_BossIdle2)
                end
                util_spinePlay(self.m_bossFreeSecond, randomIdle, false)
                util_spineEndCallFunc(self.m_bossFreeSecond, randomIdle, function()
                    self:playBossFreeSecondIdle()
                end)
            end
        end

        -- self:showPaoJiCoin(self.m_bossFreeSecond, Multi, col)
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local score = Multi * lineBet
        self:jumpCoins(self.m_freeWinCoinCurNode, self.m_freeSmallCoinTotal + score, self.m_freeSmallCoinTotal)
        self.m_freeSmallCoinTotal = self.m_freeSmallCoinTotal + score

        self:waitWithDelay(1,function()
            -- 收集金币到赢钱框
            self:showFreeBoxCoinFly(self.m_freeSmallCoinTotal, function()
                if isJiBai then
                    self:showJachPotView(func)
                else
                    if func then
                        func()
                    end
                end
                if self.m_runSpinResultData.p_fsExtraData.jackpotWin then
                    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_JiBaiKuang)
                end
                self.m_freeWinCoinCurNode:runCsbAction("xiaoshi",false,function()
                    self.m_freeWinCoinCurNode:setVisible(false)
                    self.m_freeTiXingNode:runCsbAction("chuxian",false)
                    self.m_freeTiXingNode:findChild("Stage1"):setVisible(false)
                    self.m_freeTiXingNode:findChild("Stage2"):setVisible(true)
                end)
                self.m_freeSmallCoinTotal = 0
            end)
        end)
    end)
end

--free进入第二阶段的 过场
function CodeGameScreenPiggyLegendTreasureMachine:playFreeSecondGuoChang(func)
    
    for col, vNode in ipairs(self.m_freeSmallBossBox) do
        if vNode then
            if col == 1 or col == 5 then
                util_spinePlay(vNode,"1xiaoshi3",false)
                self:waitWithDelay(15/30, function()
                    vNode:setVisible(false)
                end)
            elseif col == 2 or col == 4 then
                util_spinePlay(vNode,"1xiaoshi2",false)
                self:waitWithDelay(15/30, function()
                    vNode:setVisible(false)
                end)
            else
                util_spinePlay(vNode,"1xiaoshi1",false)
                self:waitWithDelay(15/30, function()
                    vNode:setVisible(false)
                end)
            end
        end
    end

    self:waitWithDelay(16/30, function()
        self.m_freeSmallBossBox = {}
    end)
    
    self.m_bossFreeSecond = util_spineCreate("Socre_PiggyLegendTreasure_boss", true, true) 
    self:findChild("Node_bigBoss"):addChild(self.m_bossFreeSecond)

    local view = util_createView("CodePiggyLegendTreasureSrc.PiggyLegendTreasureFreeBossGuoChangView")

    gLobalViewManager:showUI(view)
    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_GuoChang)

    util_spinePlay(self.m_bossFreeSecond,"buling",false)

    self:waitWithDelay(54/30, function()
        self:playBossFreeSecondIdle()
        view:closeSpineView()
        if func then
            func()
        end
    end)

end

-- 循环播放第二节点BOSS的两个idle 健康的
function CodeGameScreenPiggyLegendTreasureMachine:playBossFreeSecondIdle( )
    util_spinePlay(self.m_bossFreeSecond,"idle",true)
end

-- 循环播放第二节点BOSS的两个idle 残血的
function CodeGameScreenPiggyLegendTreasureMachine:playBossFreeSecondIdleCabXue( )
    util_spinePlay(self.m_bossFreeSecond,"idle2",false)
    util_spineEndCallFunc(self.m_bossFreeSecond, "idle2", function()
        self:playBossFreeSecondIdleCabXue()
    end)
end

-- 判断 是否是最后一颗子弹
function CodeGameScreenPiggyLegendTreasureMachine:getIsFinallyPaoDan( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if globalData.slotRunData.freeSpinCount == 0 then
        if self.m_bossFreeSecond and self.m_paoDanFreeIndexCur == #self.m_freeBonusPaoDanData then
            if fsExtraData.jackpotWin then
                return true
            else
                local random = math.random(1,10)
                if random < 6 then
                    return true
                else
                    return false
                end
            end
        else
            return false
        end
    end
end

-- 显示 最后一颗炮弹 发射前
function CodeGameScreenPiggyLegendTreasureMachine:showFinallyPaoDanTanBan( )
    local finallyPaoDanTanBan = util_createAnimation("PiggyLegendTreasure_Bonus_FINAL.csb")
    self:findChild("tb"):addChild(finallyPaoDanTanBan)

    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_LastPaoJiTiXing)

    finallyPaoDanTanBan:runCsbAction("start",false,function()
        finallyPaoDanTanBan:removeFromParent()
    end)
end

function CodeGameScreenPiggyLegendTreasureMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_bossFreeSecond and globalData.slotRunData.freeSpinCount == 0 and #storedIcons > 0 then
            local random = math.random(1,10)
            if random < 6 then
                self:showFreeFinallyQiPan()
            end
        end
    end

    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData() -- end
end

-- 最后一次free的时候 棋盘显示
function CodeGameScreenPiggyLegendTreasureMachine:showFreeFinallyQiPan( )
    self:runCsbAction("zhyj",true)
    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_LastQiPanLizi)
end

-- 第二阶段 击打 bonus需要调整 位置
function CodeGameScreenPiggyLegendTreasureMachine:bossFreeSecondBonusRotation(symbolNode, row, col)
    local Rotation = 0
    if row == 1 then
        if col == 1 or col == 5 then
            Rotation = 19
        elseif col == 2 or col == 4 then
            Rotation = 10
        end
    elseif row == 2 then
        if col == 1 or col == 5 then
            Rotation = 24
        elseif col == 2 or col == 4 then
            Rotation = 12
        end
    else
        if col == 1 or col == 5 then
            Rotation = 28
        elseif col == 2 or col == 4 then
            Rotation = 14
        end
    end
    if symbolNode then
        if  col == 4 or col == 5 then
            symbolNode:setRotation(-Rotation)
        else
            symbolNode:setRotation(Rotation)
        end
    end
    return Rotation
end

-- 显示第二阶段的 开始弹板
function CodeGameScreenPiggyLegendTreasureMachine:showBossFreeSecondView(func)
    local bossSecondTanBan1 = util_createAnimation("BossStart.csb")
    self:findChild("Node_guochang"):addChild(bossSecondTanBan1)

    local bossSecondTanBan2 = util_createAnimation("PiggyLegendTreasure_bossstart.csb")
    self:findChild("Node_secondFree"):addChild(bossSecondTanBan2)

    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_SecondStartView)

    bossSecondTanBan1:runCsbAction("start",false,function()
        bossSecondTanBan1:runCsbAction("idle",false,function()
            bossSecondTanBan1:runCsbAction("over",false,function()
                bossSecondTanBan1:removeFromParent()
            end)
        end)
    end)

    bossSecondTanBan2:runCsbAction("start",false,function()
        bossSecondTanBan2:runCsbAction("idle",false,function()
            -- 棋盘变亮
            self:runCsbAction("bianliang",false,function()
                self:runCsbAction("idle",false)
            end)

            bossSecondTanBan2:runCsbAction("over",false,function()
                if func then
                    func()
                end
                bossSecondTanBan2:removeFromParent()
            end)
        end)
    end)

    -- 棋盘变暗
    self:runCsbAction("bianan",false,function()
        self:runCsbAction("idle2",false)
    end)
end

--显示最后 中奖 jackpot
function CodeGameScreenPiggyLegendTreasureMachine:showJachPotView(func)
    self.m_superJackpot:runCsbAction("actionframe",false,function()
        self.m_superJackpot:runCsbAction("actionframe",true)
        if func then
            func()
        end
    end)
end

-- 显示free 次数飞到freeber
function CodeGameScreenPiggyLegendTreasureMachine:showFreeBoxFreeNumFly(flyNodeOld, freeNum, func)
    local startPos = util_convertToNodeSpace(flyNodeOld,self)

    local endNode = self.m_baseFreeSpinBar:findChild("Node_1")
    local endPos = util_convertToNodeSpace(endNode,self)

    flyNodeOld:setVisible(false)
    local flyNode

    flyNode = util_createAnimation("PiggyLegendTreasure_ExtraFreeGames.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode:setPosition(startPos)
    flyNode:findChild("m_lb_coins"):setString("+"..freeNum)
    if freeNum > 1 then
        flyNode:findChild("PiggyLegendTreasure_JinBi3_1"):setVisible(false)
        flyNode:findChild("Pic2"):setVisible(true)
    else
        flyNode:findChild("PiggyLegendTreasure_JinBi3_1"):setVisible(true)
        flyNode:findChild("Pic2"):setVisible(false)
    end

    flyNode:runCsbAction("shouji",false)
    self:waitWithDelay(75/60, function()
        local actList = {}
        actList[#actList + 1]  = cc.MoveTo:create(15/60,endPos)
        
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self.m_baseFreeSpinBar.m_baoZha:runCsbAction("fankui",false)
            self.m_baseFreeSpinBar:runCsbAction("fankui",false)

            flyNode:removeFromParent()

            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_NumUpDate)
            if func then
                func()
            end
        end)
        flyNode:runAction(cc.Sequence:create(actList))
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_NumFly)
    end)
end

-- 显示free 钱飞到赢钱框
function CodeGameScreenPiggyLegendTreasureMachine:showFreeBoxCoinFly(winCoins, func)
    local startPos = util_convertToNodeSpace(self.m_freeWinCoinCurNode:findChild("Node_1"),self)

    self.m_freeWinCoinCurNode:findChild("Node_1"):setVisible(false)

    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)
    
    local flyNode = util_createAnimation("PiggyLegendTreasure_FreeWins_Coins.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode:setPosition(startPos)
    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(winCoins, 3))

    flyNode:runCsbAction("shouji2",false)
    flyNode:findChild("Particle_1"):setDuration(1)     --设置拖尾时间(生命周期)
    flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    self:waitWithDelay(45/60, function()
        local actList = {}
        actList[#actList + 1]  = cc.MoveTo:create(15/60,endPos)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self:showWinJieSunaAct()
        end)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self:updateBottomUICoinsFree(winCoins)
        end)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            flyNode:findChild("m_lb_coins"):setVisible(false)
            self:waitWithDelay(0.5, function()
                flyNode:removeFromParent()
            end)

            self.m_freePaoJiSmallCoinIndex = {0,0,0,0,0}
            self.m_freePaoJiBigLeftCoinIndex = 0
            self.m_freePaoJiBigRightCoinIndex = 3

            if func then
                func()
            end
        end)
        flyNode:runAction(cc.Sequence:create(actList))
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuTotalCoinFly)
    end)
end

-- base下bonus发射动画
function CodeGameScreenPiggyLegendTreasureMachine:baseBonusEffect(func)
    -- 炮弹全部发射完了 跳出循环
    if self.m_paoDanIndexCur > #self.m_baseBonusPaoDanData then
        self:saveBaseBonusUpperReels()
        if globalData.slotRunData.lastWinCoin < self.m_runSpinResultData.p_winAmount then
            self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
        end
        -- 棋盘变亮
        self:runCsbAction("bianliang",false,function()
            self:runCsbAction("idle",true)
            for _, vNode in pairs(self.m_baseNewBonusNode) do
                if vNode then
                    vNode:removeFromParent()
                    self:pushSlotNodeToPoolBySymobolType(vNode.p_symbolType, vNode)
                    vNode = nil
                end
            end
            self.m_baseNewBonusNode = {}

            if func then
                func()
            end
        end)
        
        return
    end

    local storedIcons = self.m_runSpinResultData.p_storedIcons
    -- 当前发射的炮弹信息
    local paoDanDataCur = self.m_baseBonusPaoDanData[self.m_paoDanIndexCur]
    local startWorldPos = self:getNodePosByColAndRow( paoDanDataCur.row, paoDanDataCur.col)
    local startPos = self:findChild("Node_paodan"):convertToNodeSpace(startWorldPos)
    
    local endPaoDanRow = 0 --炮弹打到上棋盘 所在行
    local endPaoDanCol = paoDanDataCur.col -- 被击中图标所在真实列
    endPaoDanRow, endPaoDanCol = self:getPaoJiRowAndCol(paoDanDataCur, endPaoDanRow, endPaoDanCol)
 
    -- 表示炮弹所打的这列 没有图标了 不在继续打了
    if endPaoDanRow == 0 then
        self.m_paoDanIndexCur = self.m_paoDanIndexCur + 1
        self:baseBonusEffect(func)
        return
    end
    local upperReelNode = self.m_upperReel:findChild("sp_reel"..endPaoDanRow.."_"..paoDanDataCur.col)
    local endWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
    local endPos = self:findChild("Node_paodan"):convertToNodeSpace(endWorldPos)

    local oldNode = self.m_upperReel:findChild("sp_reel"..endPaoDanRow.."_"..endPaoDanCol)
    local ChildNode = oldNode:getChildren()
    local paoJiWorldPos = oldNode:getParent():convertToWorldSpace(cc.p(oldNode:getPositionX(),oldNode:getPositionY()))
    
    local upperReelNodeType = self.m_upperReelData[endPaoDanRow][endPaoDanCol][1]
    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
            paoJiWorldPos.y = paoJiWorldPos.y + self.m_SlotNodeH
        end
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
            paoJiWorldPos.y = paoJiWorldPos.y + self.m_SlotNodeH/2
        end
        paoJiWorldPos.x = paoJiWorldPos.x + self.m_SlotNodeH/2
    end
        
    local paoJiPos = self:findChild("Node_paodan"):convertToNodeSpace(paoJiWorldPos)

    local symbolNode = nil
    for i,vPos in ipairs(storedIcons) do
        --获取bonus行列信息
        local fixPos = self:getRowAndColByPos(vPos[1])
        if fixPos.iX == paoDanDataCur.row and fixPos.iY == paoDanDataCur.col then
            symbolNode = self.m_baseNewBonusNode[fixPos.iX.."x"..fixPos.iY]
        end
    end
    if symbolNode and symbolNode.p_symbolType then
        symbolNode:runAnim("actionframe", false, function()
            symbolNode:runAnim("idleframe2", true)
        end)
    end
    
    gLobalSoundManager:playSound(self.m_musicConfig.Sound_Bonus_FaShe)

    self:waitWithDelay(10/30,function()
        local actionList = {}
        local paoDan = util_spineCreate("Socre_PiggyLegendTreasure_Paodan", true, true) 
        self:findChild("Node_paodan"):addChild(paoDan, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        util_spinePlay(paoDan,"paodan1",true)

        startPos.y = startPos.y+80

        paoDan:setPosition(startPos)

        actionList[#actionList + 1] = cc.MoveTo:create(9/30,endPos)

        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self.m_paoDanIndexCur = self.m_paoDanIndexCur + 1
            self:showPaoJiBoxEffect(paoJiPos, endPaoDanRow, endPaoDanCol, ChildNode)

            self:upperReelNodeUpdataNum(paoDanDataCur.row, endPaoDanRow, paoDanDataCur.col, func)
            paoDan:removeFromParent()
        end)

        local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))
        paoDan:runAction(cc.Sequence:create(spawnAct))

        self:showPaoJiBonusNum(storedIcons, paoDanDataCur)
    end)
end

--[[
    炮击之后显示bonus上面的次数
]]
function CodeGameScreenPiggyLegendTreasureMachine:showPaoJiBonusNum(storedIcons, paoDanDataCur)
    for i,vPos in ipairs(storedIcons) do
        --获取bonus行列信息
        local fixPos = self:getRowAndColByPos(vPos[1])
        if fixPos.iX == paoDanDataCur.row and fixPos.iY == paoDanDataCur.col then
            local symbolNode = self:getFixSymbol(paoDanDataCur.col, paoDanDataCur.row, SYMBOL_NODE_TAG)
            vPos[2] = vPos[2] - 1
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if vPos[2] == 0 then
                spineNode.m_csbNode:findChild("m_lb_num"):setString("")
            else
                spineNode.m_csbNode:findChild("m_lb_num"):setString(vPos[2])
            end

            local newBonus = self.m_baseNewBonusNode[fixPos.iX.."x"..fixPos.iY]
            local symbol_nodeNew = newBonus:checkLoadCCbNode()
            local spineNodeNew = symbol_nodeNew:getCsbAct()
            spineNodeNew.m_csbNode:runCsbAction("jian",false, function()
                if vPos[2] == 0 then
                    local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    targSp:setVisible(true)
                    self:waitWithDelay(3/30,function()
                        targSp:runAnim("yaan",false,function()
                            targSp:runAnim("idleframean",true)
                        end)
                        newBonus:runAnim("yaan",false,function()
                            newBonus:runAnim("idleframean",true)
                        end)
                    end)
                end
            end)
            self:waitWithDelay(6/60,function()
                if vPos[2] == 0 then
                    spineNodeNew.m_csbNode:findChild("m_lb_num"):setString("")
                else
                    spineNodeNew.m_csbNode:findChild("m_lb_num"):setString(vPos[2])
                end
            end)
        end
    end
end

--[[
    炮击之后的爆炸效果
]]
function CodeGameScreenPiggyLegendTreasureMachine:showPaoJiBoxEffect(paoJiPos, endPaoDanRow, endPaoDanCol, ChildNode)
    local paoDanJiZhong = util_spineCreate("Socre_PiggyLegendTreasure_Paoji", true, true) 
    self:findChild("Node_paodan"):addChild(paoDanJiZhong, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    paoDanJiZhong:setPosition(paoJiPos)
    local upperReelNodeType = self.m_upperReelData[endPaoDanRow][endPaoDanCol][1]
    local jizhongName 
    local paoJiSound
    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
        jizhongName = "paoji1_1"
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_PaoJiBigTuBiao)
        paoJiSound = self.m_musicConfig.Sound_GuanWu_PaoJi1
    elseif upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
        jizhongName = "paoji1_2"
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_PaoJiBigTuBiao)
        paoJiSound = self.m_musicConfig.Sound_GuanWu_PaoJi2
    else
        jizhongName = "paoji1_3"
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_PaoJiSmallTuBiao)
        paoJiSound = self.m_musicConfig.Sound_GuanWu_PaoJi3
    end
    if upperReelNodeType ~= self.UPPERREEL_SYMBOL_SCORE_4 then
        if self.m_upperReelIsFirstPaoJi[endPaoDanRow][endPaoDanCol] then
            gLobalSoundManager:playSound(paoJiSound)
        end
        self.m_upperReelIsFirstPaoJi[endPaoDanRow][endPaoDanCol] = false
    end
    
    util_spinePlay(ChildNode[1],"actionframe",false)
    util_spineEndCallFunc(ChildNode[1],"actionframe",function ()
        util_spinePlay(ChildNode[1],"idleframe",true)
    end)
    util_spinePlay(paoDanJiZhong,jizhongName,false)
    self:waitWithDelay(18/30,function()
        paoDanJiZhong:removeFromParent()
    end)
end
--[[
    计算炮击位置
]]
function CodeGameScreenPiggyLegendTreasureMachine:getPaoJiRowAndCol(paoDanDataCur, endPaoDanRow, endPaoDanCol)
    for iRow = self.m_iReelRowNum, 1, -1 do
        local upperReelData = self.m_upperReelData[iRow][paoDanDataCur.col][2]
        if upperReelData ~= 0 then
            endPaoDanRow = iRow
            endPaoDanCol = paoDanDataCur.col
            break
        end
    end
    for row = self.m_iReelRowNum, 1, -1 do
        local upperReelNodeType = self.m_upperReelData[row][paoDanDataCur.col][1]
        if upperReelNodeType ~= 101 and upperReelNodeType ~= 100 then
            if self.m_upperReelData[row][paoDanDataCur.col][2] > 0 then
                endPaoDanRow = row
                endPaoDanCol = paoDanDataCur.col
                break
            end
        else
            local upperReelNodeRowNew = 0
            if paoDanDataCur.col == 2 or paoDanDataCur.col == 4 then
                for rowNew = self.m_iReelRowNum, 1, -1 do
                    local upperReelData = self.m_upperReelData[rowNew][paoDanDataCur.col-1][1]
                    if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                        upperReelNodeRowNew = rowNew
                        endPaoDanCol = paoDanDataCur.col-1
                        break
                    end
                end
            end
            if upperReelNodeRowNew ~= 0 then
                if self.m_upperReelData[upperReelNodeRowNew][paoDanDataCur.col-1][2] > 0 then
                    endPaoDanRow = upperReelNodeRowNew
                    break
                end
            end
        end
    end

    return endPaoDanRow, endPaoDanCol
end

--[[
    将scatter bonus 放回原层级
]]
function CodeGameScreenPiggyLegendTreasureMachine:putBackScatterNode()
    --scatter图标放回原层级
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == self.SYMBOL_BONUS or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                    targSp:putBackToPreParent()
                end
            end
        end
    end

end

function CodeGameScreenPiggyLegendTreasureMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        -- delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end
---------------
-- 上面棋盘相关
---------------

-- 策划定的3x2图标 只会显示在1 2列，2x2图标只会显示在3 4列
-- 客户端自定的 3x2图标 2x2图标 锚点都设置在左下角 所以这俩图标落点只能是在第1列 第3列

-- 获取上棋盘上面的小块
function CodeGameScreenPiggyLegendTreasureMachine:getUpperReelNode(symbolType)
    local node = nil
    
    -- util_spinePushBindNode(Spine,"text",coinsView)
    if symbolType == self.UPPERREEL_SYMBOL_SCORE_1 then
        node = util_spineCreate("Socre_PiggyLegendTreasure_Box1", true, true) 
    end

    if symbolType == self.UPPERREEL_SYMBOL_SCORE_2 then
        node = util_spineCreate("Socre_PiggyLegendTreasure_Box2", true, true) 
    end

    if symbolType == self.UPPERREEL_SYMBOL_SCORE_3 then
        node = util_spineCreate("Socre_PiggyLegendTreasure_Box3", true, true) 
    end

    if symbolType == self.UPPERREEL_SYMBOL_SCORE_4 then
        node = util_spineCreate("Socre_PiggyLegendTreasure_Box4", true, true) 
        local upperNodeJine = util_createAnimation("PiggyLegendTreasure_jine.csb")
        util_spinePushBindNode(node,"jine",upperNodeJine)
        -- node:addChild(upperNodeJine)
        upperNodeJine:runCsbAction("idle",false)
        node.upperNodeJine = upperNodeJine
    end

    util_spinePlay(node,"idleframe",true)

    if node then
        local upperNodeXieLiang = util_createAnimation("Socre_PiggyLegendTreasure_jiaobiao.csb")
        util_spinePushBindNode(node,"shuzi",upperNodeXieLiang)
        node.upperNodeXieLiang = upperNodeXieLiang
    end

    return node
end

-- 炮弹打到上棋盘 图标角标 刷新相关
function CodeGameScreenPiggyLegendTreasureMachine:upperReelNodeUpdataNum(paoDanRow, iRow, iCol, func)
    local upperReelNodeType = self.m_upperReelData[iRow][iCol][1]
    local upperReelNodeNum = self.m_upperReelData[iRow][iCol][2]
    local upperReelNodeRowNew = iRow
    local upperReelNodeColNew = iCol
    local storedIcons = self.m_runSpinResultData.p_storedIcons

    if upperReelNodeType ~= 100 and upperReelNodeType ~= 101 then
        self.m_upperReelData[iRow][iCol][2] = self.m_upperReelData[iRow][iCol][2] - 1
        upperReelNodeNum = self.m_upperReelData[iRow][iCol][2]
    else
        if iCol == 1 or iCol == 3 then
            for row = self.m_iReelRowNum, 1, -1 do
                local upperReelData = self.m_upperReelData[row][iCol][1]
                if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                    upperReelNodeRowNew = row
                    upperReelNodeColNew = iCol
                    break
                end
            end
        else
            for row = self.m_iReelRowNum, 1, -1 do
                local upperReelData = self.m_upperReelData[row][iCol-1][1]
                if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                    upperReelNodeRowNew = row
                    upperReelNodeColNew = iCol-1
                    break
                end
            end
        end
        self.m_upperReelData[upperReelNodeRowNew][upperReelNodeColNew][2] = self.m_upperReelData[upperReelNodeRowNew][upperReelNodeColNew][2] - 1
        upperReelNodeNum = self.m_upperReelData[upperReelNodeRowNew][upperReelNodeColNew][2]
    end

    local oldNode = self.m_upperReel:findChild("sp_reel"..upperReelNodeRowNew.."_"..upperReelNodeColNew)
    local ChildNode = oldNode:getChildren()
    if #ChildNode > 0 then
        -- 刷新角标 血量
        if ChildNode[1].upperNodeXieLiang then
            ChildNode[1].upperNodeXieLiang:runCsbAction("jianxue",false,function()
            end)
            self:waitWithDelay(6/60,function()
                ChildNode[1].upperNodeXieLiang:findChild("m_lb_num"):setString(upperReelNodeNum)
                -- 整列 血量为0的时候 触发消除
                if self:getIsTriggerRemove(iRow, iCol) then
                    self:waitWithDelay(0.5,function()
                        self:playRemoveUpperReelSymbolEffect(iRow, iCol, func)
                    end)
                else
                    local isRemove = false
                    for i,vPos in ipairs(storedIcons) do
                        --获取bonus行列信息
                        local fixPos = self:getRowAndColByPos(vPos[1])
                        if fixPos.iX == paoDanRow and fixPos.iY == iCol then
                            if vPos[2] == 0 then
                                isRemove = true
                            end
                        end
                    end
                    if isRemove then
                        local delayTime = 0.0
                        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_4 and upperReelNodeNum == 0 then
                            delayTime = 0.7
                        end
                        self:waitWithDelay(delayTime,function()
                            self:playRemoveUpperReelSymbolEffect(iRow, iCol, func)
                        end)
                    else
                        self:baseBonusEffect(func)
                    end
                end
            end)
            self:waitWithDelay(20/60,function()
                if upperReelNodeNum == 0 then
                    ChildNode[1].upperNodeXieLiang:runCsbAction("xiaoshi",false,function()

                    end)
                    ChildNode[1].upperNodeXieLiang:findChild("m_lb_num"):setString(upperReelNodeNum)
                    self:playUpperReelChangeBox(upperReelNodeRowNew, upperReelNodeColNew)
                else
                    if upperReelNodeNum == 1 then
                        ChildNode[1].upperNodeXieLiang:runCsbAction("bianhong",true)
                    else
                        ChildNode[1].upperNodeXieLiang:runCsbAction("idle2",true)
                    end
                end
            end)
        end
    end
end

-- 判断整列 血量 是否为0 为0则触发消除
function CodeGameScreenPiggyLegendTreasureMachine:getIsTriggerRemove(iRow, iCol)
    for row = self.m_iReelRowNum, 1, -1 do
        local upperReelNodeType = self.m_upperReelData[row][iCol][1]
        if upperReelNodeType ~= 100 and upperReelNodeType ~= 101 then
            if self.m_upperReelData[row][iCol][2] > 0 then
                return false
            end
        else
            local upperReelNodeRowNew = 0
            local upperReelNodeColNew = 0
            if iCol == 1 or iCol == 3 then
                for rowNew = self.m_iReelRowNum, 1, -1 do
                    local upperReelData = self.m_upperReelData[rowNew][iCol][1]
                    if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                        upperReelNodeRowNew = rowNew
                        upperReelNodeColNew = iCol
                        break
                    end
                end
            else
                for rowNew = self.m_iReelRowNum, 1, -1 do
                    local upperReelData = self.m_upperReelData[rowNew][iCol-1][1]
                    if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                        upperReelNodeRowNew = rowNew
                        upperReelNodeColNew = iCol-1
                        break
                    end
                end
            end
            if upperReelNodeRowNew ~= 0 and upperReelNodeColNew ~= 0 then
                if self.m_upperReelData[upperReelNodeRowNew][upperReelNodeColNew][2] > 0 then
                    return false
                end
            end
        end
    end
    return true
end

-- 根据上棋盘信息 判断有大图标的具体位置 有的话在那个位置
function CodeGameScreenPiggyLegendTreasureMachine:getBigNodePos(changeReels, iRow, iCol)
    if changeReels[iRow][iCol] == self.UPPERREEL_SYMBOL_SCORE_1 or changeReels[iRow][iCol] == self.UPPERREEL_SYMBOL_SCORE_2 then
        if changeReels[iRow][iCol] == self.UPPERREEL_SYMBOL_SCORE_1 then
            if iCol == 1 then
                if changeReels[iRow+1] and changeReels[iRow+1][iCol] and changeReels[iRow+1][iCol] == self.UPPERREEL_SYMBOL_SCORE_1 then
                    return true
                else
                    return false
                end
            else
                return true
            end
        end

        if changeReels[iRow][iCol] == self.UPPERREEL_SYMBOL_SCORE_2 then
            if iCol == 3 then
                if changeReels[iRow+1] and changeReels[iRow+1][iCol] and changeReels[iRow+1][iCol] == self.UPPERREEL_SYMBOL_SCORE_2 then
                    return true
                else
                    return false
                end
            else
                return true
            end
        end
    else
        return false
    end
end

-- 初始化上棋盘
-- isChange 为true 表示 切换bet的时候 只修改 金币怪物的数值 
function CodeGameScreenPiggyLegendTreasureMachine:initUpperReel(isChange)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData

    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            local oldNode = self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol)
            if isChange then
                if oldNode then
                    local ChildNode = oldNode:getChildren()
                    for j=1,#ChildNode do
                        local node = ChildNode[j]
                        if node.upperNodeJine then
                            local lineBet = globalData.slotRunData:getCurTotalBet()
                            local winCoin = self.m_upperReelData[iRow][iCol][3] * lineBet
                            node.upperNodeJine:findChild("BitmapFontLabel_2"):setString(util_formatCoins(winCoin, 3))

                            node.upperNodeJine:updateLabelSize({label=node.upperNodeJine:findChild("BitmapFontLabel_2"),sx=1,sy=1},126)
                        end
                    end
                end
            else
                if oldNode then
                    local ChildNode = oldNode:getChildren()
                    for j=1,#ChildNode do
                        ChildNode[j]:removeFromParent()
                    end
                end
                if self.m_upperReelData[iRow][iCol][1] ~= 100 and self.m_upperReelData[iRow][iCol][1] ~= 101 then
                    local node = self:getUpperReelNode(self.m_upperReelData[iRow][iCol][1])
                    self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol):addChild(node)
                    node.upperNodeXieLiang:findChild("m_lb_num"):setString(self.m_upperReelData[iRow][iCol][2])
                    if self.m_upperReelData[iRow][iCol][2] == 1 then
                        node.upperNodeXieLiang:runCsbAction("bianhong",true)
                    end
                    if node.upperNodeJine then
                        local lineBet = globalData.slotRunData:getCurTotalBet()
                        local winCoin = self.m_upperReelData[iRow][iCol][3] * lineBet
                        node.upperNodeJine:findChild("BitmapFontLabel_2"):setString(util_formatCoins(winCoin, 3))
                        node.upperNodeJine:updateLabelSize({label=node.upperNodeJine:findChild("BitmapFontLabel_2"),sx=1,sy=1},126)
                    end
                end
            end
        end
    end
end

-- 上棋盘怪物血量为0之后 变成宝箱
function CodeGameScreenPiggyLegendTreasureMachine:playUpperReelChangeBox(iRow, iCol)
    local upperReelNodeType = self.m_upperReelData[iRow][iCol][1]
    if upperReelNodeType ~= self.UPPERREEL_SYMBOL_SCORE_4 then
        local oldNode = self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol)
        local ChildNode = oldNode:getChildren()

        for i, vNode in ipairs(ChildNode) do
            if vNode then
                vNode:removeFromParent()
            end
        end
        
        local boxNameAction
        local boxNameIdle
        local guaiWuDieSound
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
            boxNameAction = "b1"
            boxNameIdle = "idle1"
            guaiWuDieSound = self.m_musicConfig.Sound_GuanWu_Die1
        elseif upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
            boxNameAction = "b2"
            boxNameIdle = "idle2"
            guaiWuDieSound = self.m_musicConfig.Sound_GuanWu_Die2
        else
            boxNameAction = "b3"
            boxNameIdle = "idle3"
            guaiWuDieSound = self.m_musicConfig.Sound_GuanWu_Die3
        end
        local random = math.random(1,10)
        if random < 4 then
            gLobalSoundManager:playSound(guaiWuDieSound)
        end

        local nodeBox = util_spineCreate("Socre_PiggyLegendTreasure_Box", true, true) 
        self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol):addChild(nodeBox)
        util_spinePlay(nodeBox,boxNameAction,false)
        util_spineEndCallFunc(nodeBox,boxNameAction,function ()
            util_spinePlay(nodeBox,boxNameIdle,true)
        end)

        local upperNodeXieLiang = util_createAnimation("Socre_PiggyLegendTreasure_jiaobiao.csb")
        util_spinePushBindNode(nodeBox,"shuzi",upperNodeXieLiang)
        upperNodeXieLiang:findChild("m_lb_num"):setString(0)
        upperNodeXieLiang:runCsbAction("xiaoshi",false)

        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_ChangeBox)

        -- 计算jinbi 的位置
        local upperReelNode = self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol)
        local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
            startWorldPos.x = startWorldPos.x + self.m_SlotNodeH/2
            startWorldPos.y = startWorldPos.y + self.m_SlotNodeH
        end
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
            startWorldPos.x = startWorldPos.x + self.m_SlotNodeH/2
            startWorldPos.y = startWorldPos.y + self.m_SlotNodeH/2
        end
        local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)

        local jinbi = util_spineCreate("PiggyLegendTreasure_Jinbi", true, true)
        self:findChild("Node_guochang"):addChild(jinbi,100000)
        jinbi:setPosition(startPos)
        util_spinePlay(jinbi,"actionframe",false)
        self:waitWithDelay(21/30,function()
            jinbi:setVisible(false)
            jinbi:removeFromParent()
        end)

        local startPos = cc.p(0, 0)
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
            startPos.x = startPos.x + self.m_SlotNodeH/2
            startPos.y = startPos.y + self.m_SlotNodeH
        end
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
            startPos.x = startPos.x + self.m_SlotNodeH/2
            startPos.y = startPos.y + self.m_SlotNodeH/2
        end

        local selfMakeData = self.m_runSpinResultData.p_selfMakeData
        local winCoin = 0
        if selfMakeData.changeMulti[self.m_removeIndexCur] and selfMakeData.changeMulti[self.m_removeIndexCur][iRow] then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            winCoin = selfMakeData.changeMulti[self.m_removeIndexCur][iRow][iCol] * lineBet
        end

        local flyNode = util_createAnimation("PiggyLegendTreasure_jine.csb")
        nodeBox:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
        flyNode:setPosition(startPos)
        flyNode:findChild("BitmapFontLabel_2"):setString(util_formatCoins(winCoin, 3))
        if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
            flyNode:setScale(1.5)
        else
            flyNode:updateLabelSize({label=flyNode:findChild("BitmapFontLabel_2"),sx=1,sy=1},126)
        end
        nodeBox.flyNode = flyNode

        flyNode:runCsbAction("chuxian",false,function()
            if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
                flyNode:setScale(1.5)
            end
        end)
    else
        local oldNode = self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol)
        local ChildNode = oldNode:getChildren()
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_boxPoSui)

        for i, vNode in ipairs(ChildNode) do
            if vNode then
                util_spinePlay(vNode,"xiaoshi",false)

                local selfMakeData = self.m_runSpinResultData.p_selfMakeData
                local winCoin = 0
                if selfMakeData.changeMulti[self.m_removeIndexCur] and selfMakeData.changeMulti[self.m_removeIndexCur][iRow] then
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    winCoin = selfMakeData.changeMulti[self.m_removeIndexCur][iRow][iCol] * lineBet
                end

                local flyNode = util_createAnimation("PiggyLegendTreasure_jine.csb")
                vNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
                flyNode:findChild("BitmapFontLabel_2"):setString(util_formatCoins(winCoin, 3))
                flyNode:updateLabelSize({label=flyNode:findChild("BitmapFontLabel_2"),sx=1,sy=1},126)
                flyNode:runCsbAction("idle",false)

                local poSuiNode = util_createAnimation("PiggyLegendTreasure_posui.csb")
                vNode:addChild(poSuiNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +6)
                poSuiNode:runCsbAction("fankui3",false)
            end
        end

        -- 计算jinbi 的位置
        local upperReelNode = self.m_upperReel:findChild("sp_reel"..iRow.."_"..iCol)
        local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
        local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)

        local jinbi = util_spineCreate("PiggyLegendTreasure_Jinbi", true, true)
        self:findChild("Node_guochang"):addChild(jinbi,100000)
        jinbi:setPosition(startPos)
        util_spinePlay(jinbi,"actionframe",false)
        self:waitWithDelay(21/30,function()
            jinbi:setVisible(false)
            jinbi:removeFromParent()
        end)
    end
end

--消除上棋盘图标
function CodeGameScreenPiggyLegendTreasureMachine:playRemoveUpperReelSymbolEffect(iRow, iCol, func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    -- 需要掉落新图标的行 列
    local fallSymbolRowAndCol = {}
    local isNeedDelay = false -- 消除的时候 需要延时
    local isHaveScore4 = true -- 消除的时候 是否有score4 这个延时少1秒

    -- 记录消除的位置
    local function insertRemoveRowAndCol(row, col)
        if fallSymbolRowAndCol[col] then
            table.insert(fallSymbolRowAndCol[col], row)
        else
            fallSymbolRowAndCol[col] = {}
            table.insert(fallSymbolRowAndCol[col], row)
        end
    end

    local upperReelBigNodeRowNew = 0
    local upperReelBigNodeColNew = 0
    local isRepeat = false -- 避免重复消除

    for row = self.m_iReelRowNum, 1, -1 do
        local upperReelNodeType = self.m_upperReelData[row][iCol][1]
        if upperReelNodeType ~= 100 and upperReelNodeType ~= 101 then
            if self.m_upperReelData[row][iCol][2] <= 0 then
                isNeedDelay = true
                isHaveScore4 = self:playNodePoSuiFuncEffect(row, iCol)
                if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then 
                    insertRemoveRowAndCol(row, iCol)
                    insertRemoveRowAndCol(row, iCol+1)
                    isRepeat = true
                else
                    insertRemoveRowAndCol(row, iCol)
                end
            end
        else
            local upperReelNodeRowNew = 0
            local upperReelNodeColNew = 0
            if iCol == 1 or iCol == 3 then
                for rowNew = self.m_iReelRowNum, 1, -1 do
                    local upperReelData = self.m_upperReelData[rowNew][iCol][1]
                    if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                        if self.m_upperReelData[rowNew][iCol][2] <= 0 then 
                            upperReelNodeRowNew = rowNew
                            upperReelNodeColNew = iCol
                            upperReelBigNodeRowNew = rowNew
                            upperReelBigNodeColNew = iCol
                            break
                        end
                    end
                end
            else
                for rowNew = self.m_iReelRowNum, 1, -1 do
                    local upperReelData = self.m_upperReelData[rowNew][iCol-1][1]
                    if upperReelData == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelData == self.UPPERREEL_SYMBOL_SCORE_2 then
                        if self.m_upperReelData[rowNew][iCol-1][2] <= 0 then 
                            upperReelNodeRowNew = rowNew
                            upperReelNodeColNew = iCol-1
                            upperReelBigNodeRowNew = rowNew
                            upperReelBigNodeColNew = iCol-1
                            break
                        end
                    end
                end
            end
            if upperReelNodeRowNew ~= 0 and upperReelNodeColNew ~= 0 then
                if iCol == 1 or iCol == 3 then
                    if upperReelNodeType == 100 then
                        insertRemoveRowAndCol(row, iCol)
                    else
                        insertRemoveRowAndCol(row, iCol)
                        insertRemoveRowAndCol(row, iCol+1)
                    end
                else
                    if upperReelNodeType == 100 then
                        insertRemoveRowAndCol(row, iCol)
                    else
                        insertRemoveRowAndCol(row, iCol)
                        insertRemoveRowAndCol(row, iCol-1)
                    end
                end
            end
        end
    end
    -- 2 4列的时候 判断下1 3 列是否有空的位置100
    if iCol == 2 or iCol == 4 then
        for rowNew = self.m_iReelRowNum, 1, -1 do
            local upperReelData = self.m_upperReelData[rowNew][iCol-1][1]
            if upperReelData == 100 then
                insertRemoveRowAndCol(rowNew, iCol-1)
            end
        end
    end
    if iCol == 1 or iCol == 3 then
        for rowNew = self.m_iReelRowNum, 1, -1 do
            local upperReelData = self.m_upperReelData[rowNew][iCol+1][1]
            if upperReelData == 100 then
                insertRemoveRowAndCol(rowNew, iCol+1)
            end
        end
    end

    if upperReelBigNodeRowNew ~= 0 and upperReelBigNodeColNew ~= 0 then
        if not isRepeat then
            isNeedDelay = true
            isHaveScore4 = self:playNodePoSuiFuncEffect(upperReelBigNodeRowNew, upperReelBigNodeColNew)
        end
    end
    -- 判断棋盘本身是否有空位置
    if table.nums(fallSymbolRowAndCol) == 2 then
        if iCol == 1 or iCol == 3 then
            for row = self.m_iReelRowNum, 1, -1 do
                for col = iCol, iCol+1 do
                    local upperReelNodeType = self.m_upperReelData[row][col][1]
                    if upperReelNodeType == 100 then
                        local isAdd = true --判断是否已经添加过了
                        for i,v in ipairs(fallSymbolRowAndCol[col]) do
                            if v == row then
                                isAdd = false
                            end
                        end
                        if isAdd then
                            insertRemoveRowAndCol(row, col)
                        end
                    end
                end
            end
        else
            for row = self.m_iReelRowNum, 1, -1 do
                for col = iCol-1, iCol do
                    local upperReelNodeType = self.m_upperReelData[row][col][1]
                    if upperReelNodeType == 100 then
                        local isAdd = true --判断是否已经添加过了
                        for i,v in ipairs(fallSymbolRowAndCol[col]) do
                            if v == row then
                                isAdd = false
                            end
                        end
                        if isAdd then
                            insertRemoveRowAndCol(row, col)
                        end
                    end
                end
            end
        end
    else
        for row = self.m_iReelRowNum, 1, -1 do
            local upperReelNodeType = self.m_upperReelData[row][iCol][1]
            if upperReelNodeType == 100 and fallSymbolRowAndCol[iCol] then
                local isAdd = true --判断是否已经添加过了
                for i,v in ipairs(fallSymbolRowAndCol[iCol]) do
                    if v == row then
                        isAdd = false
                    end
                end
                if isAdd then
                    insertRemoveRowAndCol(row, iCol)
                end
            end
        end
    end
    -- 当前炮击列 没有空的 则肯定 不消除
    if not fallSymbolRowAndCol[iCol] then
        fallSymbolRowAndCol = {}
    end

    local delayTime = 0.0
    if isNeedDelay then
        delayTime = 0/30+25/60+16/30+0.5 --消除的只有score4 
        if not isHaveScore4 then
            delayTime = 0/30+45/60+16/30+1 --消除的 不止有score4
        end
    end

    local isTiQian = false --是否提前播放大赢动画
    if isNeedDelay and self.m_paoDanIndexCur > #self.m_baseBonusPaoDanData and self:checkBigWin() then
        isTiQian = true
        local timeDelay = 1.5
        if not isHaveScore4 then
            timeDelay = 2.5
        end
        self:waitWithDelay(timeDelay, function()
            self:baseBonusEffect(func)    
        end)  
    end

    self:waitWithDelay(delayTime, function()
        self:playFallSymbolEffect(iRow, iCol, func, fallSymbolRowAndCol, isTiQian)
    end)
end

--[[
    播放破碎动画
]]
function CodeGameScreenPiggyLegendTreasureMachine:playNodePoSuiFuncEffect(row, col)
    local isHaveScore4 = true
    local upperReelNodeType = self.m_upperReelData[row][col][1]
    if upperReelNodeType ~= self.UPPERREEL_SYMBOL_SCORE_4 then
        isHaveScore4 = false
        
        self:showBaseBoxCoin(row, col, upperReelNodeType)
        self:waitWithDelay(60/60,function()
            local oldNode = self.m_upperReel:findChild("sp_reel"..row.."_"..col)
            local ChildNode = oldNode:getChildren()
            local boxNameXiaoshi
            local poSuiFanKui
            local startPos = cc.p(0, 0)
            if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
                boxNameXiaoshi = "xiaoshi1"
                poSuiFanKui = "fankui1"
                startPos.x = startPos.x + self.m_SlotNodeH/2
                startPos.y = startPos.y + self.m_SlotNodeH
            elseif upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
                boxNameXiaoshi = "xiaoshi2"
                poSuiFanKui = "fankui2"
                startPos.x = startPos.x + self.m_SlotNodeH/2
                startPos.y = startPos.y + self.m_SlotNodeH/2
            elseif upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_3 then
                boxNameXiaoshi = "xiaoshi3"
                poSuiFanKui = "fankui3"
            end

            gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_boxPoSui)

            for i, vNode in ipairs(ChildNode) do
                if vNode then
                    if vNode.flyNode then
                        vNode.flyNode:setVisible(false)
                    end
                    local poSuiNode = util_createAnimation("PiggyLegendTreasure_posui.csb")
                    vNode:addChild(poSuiNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +6)
                    poSuiNode:runCsbAction(poSuiFanKui,false)
                    poSuiNode:setPosition(startPos)

                    util_spinePlay(vNode,boxNameXiaoshi,false)
                    self:waitWithDelay(17/30,function()
                        if not tolua.isnull(vNode) then
                            vNode:removeFromParent()
                        end
                    end)
                end
            end
        end)
    else
        self:showBaseBoxCoin(row, col, upperReelNodeType) 
        self:waitWithDelay(0/60,function()
            local oldNode = self.m_upperReel:findChild("sp_reel"..row.."_"..col)
            local ChildNode = oldNode:getChildren()
            local boxNameXiaoshi = "idleframe2"
            
            for i, vNode in ipairs(ChildNode) do
                if vNode then
                    util_spinePlay(vNode,boxNameXiaoshi,false)
                    self:waitWithDelay(1/30,function()
                        if not tolua.isnull(vNode) then 
                            vNode:removeFromParent()
                        end
                    end)
                end
            end
        end)
    end
    return isHaveScore4
end

-- 连线的时候 更新 底部钱
function CodeGameScreenPiggyLegendTreasureMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if isNotifyUpdateTop then
        if globalData.slotRunData.lastWinCoin < self.m_runSpinResultData.p_winAmount then
            self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop, true, self.m_baseCurWinCoin})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

-- 判断是否需要下落
function CodeGameScreenPiggyLegendTreasureMachine:isNeedMove(_row, _col, _vRowList, colNum)
    for i,vRow in ipairs(_vRowList) do
        if colNum > 1 then
            if vRow == 3 or _row <= vRow then
                return true
            end
        else
            if self.m_upperReelData[_row][_col][1] ~= self.UPPERREEL_SYMBOL_SCORE_1 and 
                self.m_upperReelData[_row][_col][1] ~= self.UPPERREEL_SYMBOL_SCORE_2 then
                    return true
            end
        end
    end
    return false
end

--重新掉落图标
function CodeGameScreenPiggyLegendTreasureMachine:playFallSymbolEffect(iRow, iCol, func, fallSymbolRowAndCol, isTiQian)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local isAdd = false
    for k,v in pairs(fallSymbolRowAndCol) do
        isAdd = true
    end
    if isAdd then
        self.m_removeIndexCur = self.m_removeIndexCur + 1
    end
    
    for k,v in pairs(fallSymbolRowAndCol) do
        for iRow = 1,self.m_iReelRowNum do
            if selfMakeData.changeReels[self.m_removeIndexCur] and selfMakeData.changeReels[self.m_removeIndexCur][iRow][k] and selfMakeData.changeTimes[self.m_removeIndexCur][iRow][k] then
                local isBlank = self:getBigNodePos(selfMakeData.changeReels[self.m_removeIndexCur], iRow, k)
                -- 判断大图标 自定义左下角的位置 其他位置 当空处理 101代表空
                if isBlank then
                    self.m_upperReelData[iRow][k][1] = 101
                    self.m_upperReelData[iRow][k][2] = 0
                    self.m_upperReelData[iRow][k][3] = 0
                else
                    self.m_upperReelData[iRow][k][1] = selfMakeData.changeReels[self.m_removeIndexCur][iRow][k]
                    self.m_upperReelData[iRow][k][2] = selfMakeData.changeTimes[self.m_removeIndexCur][iRow][k]
                    self.m_upperReelData[iRow][k][3] = selfMakeData.changeMulti[self.m_removeIndexCur][iRow][k]
                end
            end
        end
    end

    -- 结合新的数据判断消除的位置是否需要下落
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local function delateKongFun()
        for k,vList in pairs(fallSymbolRowAndCol) do
            for i,vRow in ipairs(vList) do
                if self.m_upperReelData and self.m_upperReelData[vRow][k][1] then
                    if self.m_upperReelData[vRow][k][1] == 100 then
                        table.remove( vList, i )
                        delateKongFun()
                    end
                end
            end
        end
    end
    delateKongFun()

    -- 排序
    for k,vList in pairs(fallSymbolRowAndCol) do
        table.sort(vList, function(a, b)
            return a > b
        end)
    end

    local delayTime = 0.0
    for k,vRowList in pairs(fallSymbolRowAndCol) do
        if #vRowList >= 3 then
            for i,row in ipairs(vRowList) do
                delayTime = self:playUpReelSymbolDown(row, k, 3)
            end
        else
            for row = self.m_iReelRowNum, 1, -1 do
                if self:isNeedMove(row, k, vRowList, table.nums(fallSymbolRowAndCol)) then
                    delayTime = self:playUpReelSymbolDown(row, k, #vRowList)
                end
            end
        end
    end
    if fallSymbolRowAndCol and table.nums(fallSymbolRowAndCol) > 0 then
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_PigMove)
    end

    if not isTiQian then
        self:waitWithDelay(delayTime, function()
            self:baseBonusEffect(func)
        end)
    end
end

--[[
    炮击击败之后 下落
]]
function CodeGameScreenPiggyLegendTreasureMachine:playUpReelSymbolDown(row, k, rowNums)
    local delayTime = 0
    local oldNode = self.m_upperReel:findChild("sp_reel"..row.."_"..k)
    if oldNode then
        local ChildNode = oldNode:getChildren()
        for j=1,#ChildNode do
            ChildNode[j]:removeFromParent()
        end
    end
    if self.m_upperReelData[row][k][1] ~= 101 and self.m_upperReelData[row][k][1] ~= 100 then
        delayTime = 0.5
        local node = self:getUpperReelNode(self.m_upperReelData[row][k][1])
        self.m_upperReel:findChild("sp_reel"..row.."_"..k):addChild(node)
        node:setPositionY(self.m_SlotNodeH * rowNums)
        node.upperNodeXieLiang:findChild("m_lb_num"):setString(self.m_upperReelData[row][k][2])
        if self.m_upperReelData[row][k][2] == 1 then
            node.upperNodeXieLiang:runCsbAction("bianhong",true)
        end
        if node.upperNodeJine then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local winCoin = self.m_upperReelData[row][k][3] * lineBet
            node.upperNodeJine:findChild("BitmapFontLabel_2"):setString(util_formatCoins(winCoin, 3))
            node.upperNodeJine:updateLabelSize({label=node.upperNodeJine:findChild("BitmapFontLabel_2"),sx=1,sy=1},126)
        end
        -- 下落烟雾
        local yanWuNode = util_createAnimation("PiggyLegendTreasure_tubiaoxialuo.csb")
        node:addChild(yanWuNode)
        if self.m_upperReelData[row][k][1] == self.UPPERREEL_SYMBOL_SCORE_1 or self.m_upperReelData[row][k][1] == self.UPPERREEL_SYMBOL_SCORE_2 then
            yanWuNode:setPosition(cc.p(self.m_SlotNodeH/2, -self.m_SlotNodeH/2)) 
        else
            yanWuNode:setPositionY(-self.m_SlotNodeH/2)
        end
        
        local pos = cc.p(0, 0)
        local moveTo = cc.MoveTo:create(0.4, pos)
        local fun =
            cc.CallFunc:create(
            function()
                util_spinePlay(node,"buling",false)

                local actionframe = "yanwu2"
                if self.m_upperReelData[row][k][1] == self.UPPERREEL_SYMBOL_SCORE_1 or self.m_upperReelData[row][k][1] == self.UPPERREEL_SYMBOL_SCORE_2 then
                    actionframe = "yanwu1"
                end
                yanWuNode:runCsbAction(actionframe,false,function()
                    yanWuNode:removeFromParent()
                end)

                self:shakeNode(node, self.m_upperReelData[row][k][1])

                util_spineEndCallFunc(node,"buling",function ()
                    util_spinePlay(node,"idleframe",true)
                end)
            end
        )

        node:runAction(cc.Sequence:create(moveTo, fun))
    end
    return delayTime
end

--下落之后 震动
function CodeGameScreenPiggyLegendTreasureMachine:shakeNode(node, type)
    local changePosY = 5
    local changePosX = 2.5
    if type == self.UPPERREEL_SYMBOL_SCORE_1 then
        changePosY = 15
        changePosX = 7.5
    end
    if type == self.UPPERREEL_SYMBOL_SCORE_2 then
        changePosY = 10
        changePosX = 5
    end
    local actionList2 = {}
    local oldPos = cc.p(node:getPosition())

    for i=1,2 do
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    end

    local seq2 = cc.Sequence:create(actionList2)
    node:runAction(seq2)

end

-- 显示base 上棋盘变成宝箱之后上面的钱
function CodeGameScreenPiggyLegendTreasureMachine:showBaseBoxCoin(row, col, upperReelNodeType, func)
    local upperReelNode = self.m_upperReel:findChild("sp_reel"..row.."_"..col)
    local startWorldPos = upperReelNode:getParent():convertToWorldSpace(cc.p(upperReelNode:getPositionX(),upperReelNode:getPositionY()))
    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 then
        startWorldPos.x = startWorldPos.x + self.m_SlotNodeH/2
        startWorldPos.y = startWorldPos.y + self.m_SlotNodeH
    end
    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
        startWorldPos.x = startWorldPos.x + self.m_SlotNodeH/2
        startWorldPos.y = startWorldPos.y + self.m_SlotNodeH/2
    end
    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_4 then
        local ChildNode = upperReelNode:getChildren()
        if ChildNode.upperNodeJine then
            ChildNode.upperNodeJine:setVisible(false)
        end
    else
        local ChildNode = upperReelNode:getChildren()
        for i,vNode in ipairs(ChildNode) do
            if vNode then
                if vNode.flyNode then
                    vNode.flyNode:setVisible(false)
                end
            end
        end
    end
    local startPos = self:convertToNodeSpace(startWorldPos)

    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)

    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local winCoin = 0
    if selfMakeData.changeMulti[self.m_removeIndexCur] and selfMakeData.changeMulti[self.m_removeIndexCur][row] then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        winCoin = selfMakeData.changeMulti[self.m_removeIndexCur][row][col] * lineBet
    end

    local flyNode = util_createAnimation("PiggyLegendTreasure_jine.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode:setPosition(startPos)
    flyNode:findChild("BitmapFontLabel_2"):setString(util_formatCoins(winCoin, 3))
    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_1 or upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_2 then
        flyNode:setScale(1.5)
    else
        flyNode:updateLabelSize({label=flyNode:findChild("BitmapFontLabel_2"),sx=1,sy=1},126)
    end

    if upperReelNodeType == self.UPPERREEL_SYMBOL_SCORE_4 then
        flyNode:runCsbAction("idle",false)
        self:waitWithDelay(0.5, function()
            flyNode:runCsbAction("shouji",false)
            flyNode:findChild("Particle_1"):setDuration(0.5)     --设置拖尾时间(生命周期)
            flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
            self:waitWithDelay(45/60, function()
                local actList = {}
                actList[#actList + 1]  = cc.MoveTo:create(15/60,endPos)
                actList[#actList + 1] = cc.CallFunc:create(function (  )
                    self:showWinJieSunaAct()
                end)
                actList[#actList + 1] = cc.CallFunc:create(function (  )
                    self:updateBottomUICoinsBase(winCoin)
                end)
                actList[#actList + 1] = cc.CallFunc:create(function (  )
                    flyNode:findChild("Node_1"):setVisible(false)
                    self:waitWithDelay(0.5, function()
                        flyNode:removeFromParent()
                    end)
                    if func then
                        func()
                    end
                end)
                flyNode:runAction(cc.Sequence:create(actList))
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_CoinFly)
            end)
        end)
    else
        flyNode:runCsbAction("idle",false)
        self:waitWithDelay(1, function()
            flyNode:runCsbAction("shouji",false)
            flyNode:findChild("Particle_1"):setDuration(0.5)     --设置拖尾时间(生命周期)
            flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
            self:waitWithDelay(45/60, function()
                local actList = {}
                actList[#actList + 1]  = cc.MoveTo:create(15/60,endPos)
                actList[#actList + 1] = cc.CallFunc:create(function (  )
                    if func then
                        func()
                    end
                    self:showWinJieSunaAct()
                end)
                actList[#actList + 1] = cc.CallFunc:create(function (  )
                    self:updateBottomUICoinsBase(winCoin)
                end)
                actList[#actList + 1] = cc.CallFunc:create(function (  )
                    flyNode:findChild("Node_1"):setVisible(false)
                    self:waitWithDelay(0.5, function()
                        flyNode:removeFromParent()
                    end)
                end)
                flyNode:runAction(cc.Sequence:create(actList))
                gLobalSoundManager:playSound(self.m_musicConfig.Sound_Base_CoinFly)
            end)
        end)
    end
    
end

function CodeGameScreenPiggyLegendTreasureMachine:showWinJieSunaAct( )
    self.m_jiesuanAct:setVisible(true)
    self.m_jiesuanAct:runCsbAction("fankui",false,function()
        self.m_jiesuanAct:setVisible(false)
    end)
end

-- 检查大赢
function CodeGameScreenPiggyLegendTreasureMachine:checkBigWin( )
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        
        return true
    end
    return false
end

-- base 飞钱之后 更新底部赢钱
function CodeGameScreenPiggyLegendTreasureMachine:updateBottomUICoinsBase(currCoins)
    local endCoins = self.m_baseCurWinCoin + currCoins
    globalData.slotRunData.lastWinCoin = self.m_baseCurWinCoin + currCoins

    local params = {endCoins,true,true,self.m_baseCurWinCoin}
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    self.m_baseCurWinCoin = self.m_baseCurWinCoin + currCoins

    -- 检查是否有大赢 没有的话 判断添加
    if not self:checkBigWin() then
        self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, self.BASE_BONUS_EFFECT+10)
    end
end

-- free 飞钱之后 更新底部赢钱
function CodeGameScreenPiggyLegendTreasureMachine:updateBottomUICoinsFree(currCoins)
    local endCoins = self.m_freeCurWinCoin + currCoins
    globalData.slotRunData.lastWinCoin = self.m_freeCurWinCoin + currCoins

    local params = {endCoins,false,true,self.m_freeCurWinCoin}
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    self.m_freeCurWinCoin = self.m_freeCurWinCoin + currCoins

end

function CodeGameScreenPiggyLegendTreasureMachine:scaleMainLayer()
    CodeGameScreenPiggyLegendTreasureMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.7
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 20)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.76 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 15)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.88 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 20)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.94 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio <= 768/1370 then
    end
end

---
--判断改变freespin的状态
function CodeGameScreenPiggyLegendTreasureMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end
end

-- 重置当前背景音乐名称
function CodeGameScreenPiggyLegendTreasureMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
        if self.m_bossFreeSecond then 
            self.m_currentMusicBgName = self.m_musicConfig.Music_Free_Bg2
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end

return CodeGameScreenPiggyLegendTreasureMachine