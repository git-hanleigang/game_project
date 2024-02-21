
---
-- island li
-- 2019年1月26日
-- CodeGameScreenGhostBlasterMachine.lua
-- 
-- 玩法：
-- 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "GhostBlasterPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CodeGameScreenGhostBlasterMachine = class("CodeGameScreenGhostBlasterMachine", BaseReelMachine)

CodeGameScreenGhostBlasterMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
--bonus
CodeGameScreenGhostBlasterMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenGhostBlasterMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenGhostBlasterMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2

CodeGameScreenGhostBlasterMachine.SYMBOL_GHOST_1    =   11  --2x3小鬼
CodeGameScreenGhostBlasterMachine.SYMBOL_GHOST_2    =   12  --2x2小鬼
CodeGameScreenGhostBlasterMachine.SYMBOL_GHOST_3    =   13  --1x1小鬼
CodeGameScreenGhostBlasterMachine.SYMBOL_GHOST_4    =   14  --金币箱
CodeGameScreenGhostBlasterMachine.SYMBOL_EMPTY    =   100   --空信号

-- 自定义动画的标识
CodeGameScreenGhostBlasterMachine.HIT_GHOST_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1  --打鬼事件
CodeGameScreenGhostBlasterMachine.HIT_GHOST_IN_FREE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2  --打鬼事件


-- 构造函数
function CodeGameScreenGhostBlasterMachine:ctor()
    CodeGameScreenGhostBlasterMachine.super.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isAddBigWinLightEffect = true

    self.m_addFreeCount = 0 --free中加次数
    self.m_hitCountInFree = 0 --free中当前炮击次数
    self.m_hitTotalCountInFree = 0 --boss阶段炮击总次数
    self.m_hitCountByCol = {0,0,0,0,0} --free中当前炮击次数
    self.m_isLastBonusInFree = false    --free中最后一个炮
    self.m_isLastShoot = false          --最后一次炮击
    self.m_isDefeatBoss = false         --是否击败boss
    self.m_bossStartShow = false
    self.m_curHitBonusSymbol = nil      --当前执行炮击动效的bonus图标

    -- 添加信号待触发ctroller
    self.m_symbolExpectCtr = util_createView("CodeGhostBlasterSrc.GhostBlasterSymbolExpect", self)

    -- 引入控制插件
    self.m_longRunControl = util_createView("CodeGhostBlasterSrc.GhostBlasterLongRunControl",self)
 
    --init
    self:initGame()
end

function CodeGameScreenGhostBlasterMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("GhostBlasterConfig.csv", "LevelGhostBlasterConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

function CodeGameScreenGhostBlasterMachine:initGameStatusData(gameData)
    if gameData.feature then
        gameData.spin.freespin = gameData.feature.freespin
        gameData.spin.features = gameData.feature.features
    end
    CodeGameScreenGhostBlasterMachine.super.initGameStatusData(self, gameData)    

    if gameData.gameConfig.extra then
        self.m_initUpReelInfo = gameData.gameConfig.extra.upperInfo

        self.m_allUpReelInfo = gameData.gameConfig.extra.bets
    end
    
end

--[[
    显示压黑层
]]
function CodeGameScreenGhostBlasterMachine:showBlackLayer()
    self.m_blackLayer:setVisible(true)
    util_nodeFadeIn(self.m_blackLayer,0.25,0,204)
end

--[[
    隐藏压黑层
]]
function CodeGameScreenGhostBlasterMachine:hideBlackLayer( )
    util_fadeOutNode(self.m_blackLayer,0.25,function(  )
        self.m_blackLayer:setVisible(false)
    end)
end

--[[
    获取当前上轮盘的数据
]]
function CodeGameScreenGhostBlasterMachine:getCurUpReelInfo()
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_allUpReelInfo and self.m_allUpReelInfo[tostring(lineBet)] then
        return clone(self.m_allUpReelInfo[tostring(lineBet)]) 
    end

    return clone(self.m_initUpReelInfo)
end

--[[
    刷新当前bet下上轮盘数据
]]
function CodeGameScreenGhostBlasterMachine:updateCurUpReelInfo()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if selfData and selfData.bets then
        self.m_allUpReelInfo[tostring(lineBet)] = clone(selfData.bets[tostring(lineBet)])
    end

    return self:getCurUpReelInfo()

end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGhostBlasterMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GhostBlaster"  
end


function CodeGameScreenGhostBlasterMachine:getBottomUINode()
    return "CodeGhostBlasterSrc.GhostBlasterBottomNode"
end

function CodeGameScreenGhostBlasterMachine:getReelNode()
    return "CodeGhostBlasterSrc.GhostBlasterReelNode"
end

--[[
    修改背景动画
]]
function CodeGameScreenGhostBlasterMachine:changeBgAni(aniType)
    if aniType == "base" then
        self.m_gameBg:findChild("Base_0"):setVisible(false)
        self.m_gameBg:findChild("Base_1"):setVisible(false)
        self.m_gameBg:findChild("Base"):setVisible(true)
        self:setReelBgShow("base")
        self:findChild("bossbeijing_jinbi"):setVisible(false)
        self:findChild("Node_xianshu"):setVisible(true)
    elseif aniType == "free" then
        self.m_gameBg:findChild("Base_0"):setVisible(true)
        self.m_gameBg:findChild("Base_1"):setVisible(false)
        self.m_gameBg:findChild("Base"):setVisible(false)
        self:findChild("bossbeijing_jinbi"):setVisible(false)
        self:findChild("Node_xianshu"):setVisible(false)
        self:setReelBgShow("free")
    elseif aniType == "boss" then
        self.m_gameBg:findChild("Base_0"):setVisible(false)
        self.m_gameBg:findChild("Base_1"):setVisible(true)
        self.m_gameBg:findChild("Base"):setVisible(false)
        self:findChild("bossbeijing_jinbi"):setVisible(true)
        self:setReelBgShow("free")
    end
end

function CodeGameScreenGhostBlasterMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:changeCoinWinEffectUI(self:getModuleName(), "GhostBlaster_yqqFK.csb")

    self.m_jackPotBarView = util_createView("CodeGhostBlasterSrc.GhostBlasterJackPotBarView",{machine = self})
    self.m_jackPotBarView:initMachine(self)
    self:findChild("root"):addChild(self.m_jackPotBarView) --修改成自己的节点

    --上轮盘
    self.m_upReel = util_createView("CodeGhostBlasterSrc.GhostBlasterUpReel",{machine = self})
    self:findChild("Node_UpperReels"):addChild(self.m_upReel)
    -- self.m_upReel:setVisible(false)

    --pick玩法提示
    self.m_pickTip = util_createAnimation("GhostBlaster_tanbanwenben.csb")
    self:findChild("Node_tanbanwenben"):addChild(self.m_pickTip)
    self.m_pickTip:setVisible(false)

    --free提示
    self.m_freeTip = util_createView("CodeGhostBlasterSrc.GhostBlasterFreeTip")
    self:findChild("Node_FreeGameTips"):addChild(self.m_freeTip)
    self.m_freeTip:setVisible(false)

    --free怪物节点
    self.m_enemyNode = util_createView("CodeGhostBlasterSrc.GhostBlasterEnemyInFree",{machine = self})
    self:findChild("Node_UpperReels"):addChild(self.m_enemyNode)
    self.m_enemyNode:setVisible(false)

    --free赢钱收集区
    self.m_free_win = util_createView("CodeGhostBlasterSrc.GhostBlasterFreeTotalWin",{machine = self})
    self:findChild("Node_FreeWins"):addChild(self.m_free_win)
    self.m_free_win:setVisible(false)

    -- 创建view节点方式
    -- self.m_GhostBlasterView = util_createView("CodeGhostBlasterSrc.GhostBlasterView")
    -- self:findChild("xxxx"):addChild(self.m_GhostBlasterView)
end


function CodeGameScreenGhostBlasterMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 4, 0, 1)
    end)
end

function CodeGameScreenGhostBlasterMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:checkUpateDefaultBet()

    --初始化上轮盘显示
    local upReelInfo = self:getCurUpReelInfo()
    self.m_upReel:refreshView(upReelInfo)

    self:updateBetLevel(true)

    CodeGameScreenGhostBlasterMachine.super.onEnter(self)     -- 必须调用不予许删除

    self:addObservers()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_jackPotBarView:changeShow("free")
        self:showFreeSpinUI()

        
    else
        self.m_jackPotBarView:changeShow("base")
        self:changeBgAni("base")
    end
end

-- 重置当前背景音乐名称
function CodeGameScreenGhostBlasterMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_enemyNode.m_isShowBoss then
            self.m_currentMusicBgName = "GhostBlasterSounds/music_GhostBlaster_boss.mp3"
        else
            self.m_currentMusicBgName = self:getFreeSpinMusicBG()
            if self.m_currentMusicBgName == nil then
                self.m_currentMusicBgName = self:getNormalMusicBg()
            end
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

--[[
    高低bet
]]
function CodeGameScreenGhostBlasterMachine:updateBetLevel(isInit)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if betCoin >= specialBets[1].p_totalBetValue then
        level = 1
    end
    self.m_iBetLevel = level

    if isInit then
        self.m_jackPotBarView:initLockStatus(level == 0)
    else
        self.m_jackPotBarView:setLockStatus(level == 0)
    end

    
end

--[[
    修改reel背景
]]
function CodeGameScreenGhostBlasterMachine:setReelBgShow(gameType)
    self:findChild("Node_base_reel"):setVisible(gameType == "base")
    self:findChild("Node_FG_reel"):setVisible(gameType == "free")
end

function CodeGameScreenGhostBlasterMachine:addObservers()
    CodeGameScreenGhostBlasterMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()

            local upReelInfo = self:getCurUpReelInfo()
            self.m_upReel:checkIsReelSame(upReelInfo)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        -- bonus玩法不播音效
        if params[self.m_stopUpdateCoinsSoundIndex] or params[5] then
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

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
        else
            bgmType = "base"
        end

        local soundName = "GhostBlasterSounds/music_GhostBlaster_last_win_".. bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenGhostBlasterMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGhostBlasterMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

--[[
    获取上轮盘小鬼动画名
]]
function CodeGameScreenGhostBlasterMachine:getUpReelGostAniName(symbolType)
    if symbolType == self.SYMBOL_GHOST_1 then
        return "GhostBlaster_xg1"
    end

    if symbolType == self.SYMBOL_GHOST_2 then
        return "GhostBlaster_xg2"
    end

    if symbolType == self.SYMBOL_GHOST_3 then
        return "GhostBlaster_xg3"
    end

    if symbolType == self.SYMBOL_GHOST_4 then
        return "GhostBlaster_glod"
    end
    
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGhostBlasterMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_GhostBlaster_blank"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_GhostBlaster_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_GhostBlaster_11"
    end

    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_GhostBlaster_Bonus"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGhostBlasterMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenGhostBlasterMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenGhostBlasterMachine:MachineRule_initGame(  )

    
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGhostBlasterMachine:MachineRule_SpinBtnCall()
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_symbolExpectCtr:MachineSpinBtnCall()
    self:setMaxMusicBGVolume( )

    self.m_addFreeCount = 0

    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenGhostBlasterMachine:slotOneReelDown(reelCol)    
    CodeGameScreenGhostBlasterMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
end

---
--保留本轮数据
function CodeGameScreenGhostBlasterMachine:keepCurrentSpinData()
    self:insterReelResultLines()

    --TODO   wuxi update on
    -- globalData.slotRunData.totalFreeSpinCount = (globalData.slotRunData.totalFreeSpinCount or 0) + self.m_iFreeSpinTimes

    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function CodeGameScreenGhostBlasterMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
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

                    -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    --     self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    -- else
                    --     -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                    --     globalData.slotRunData.totalFreeSpinCount = 0
                    --     self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    -- end

                    -- globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes
                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 添加 BonusEffect
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

--[[
    滚轮停止
]]
function CodeGameScreenGhostBlasterMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    --更新free次数
    self.m_addFreeCount = self.m_runSpinResultData.p_freeSpinNewCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsLeftCount or 0


    CodeGameScreenGhostBlasterMachine.super.slotReelDown(self)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenGhostBlasterMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenGhostBlasterMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local reels = self.m_runSpinResultData.p_reels
    local scatterCount = 0
    for iCol = 1,colIndex - 1 do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterCount  = scatterCount + 1
            end
        end
    end

    if colIndex < 3 then
        return true
    elseif colIndex == 3 and scatterCount >= 1 then
        return true
    elseif colIndex == 5 and scatterCount >= 2 then
        return true
    end

    return false
end

--本列停止 判断下列是否有长滚
-- function CodeGameScreenGhostBlasterMachine:getNextReelIsLongRun(reelCol)
--     if reelCol <= self.m_iReelColumnNum then
--         local bHaveLongRun = false
--         for i = 1, reelCol do
--             local reelRunData = self.m_reelRunInfo[i]
--             if reelRunData:getNextReelLongRun() == true then
--                 bHaveLongRun = true
--                 break
--             end
--         end
--         if self:isLongRun(reelCol) and bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() then
--             return true
--         end
--     end
--     return false
-- end

--[[
    是否播放期待动画
]]
function CodeGameScreenGhostBlasterMachine:isPlayExpect(reelCol)
    if reelCol <= self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() then
            return true
        end
    end
    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenGhostBlasterMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)
    local curLongRunData = self.m_longRunControl:getCurLongRunData() or {}
    local LegitimatePos = curLongRunData.LegitimatePos or {}
    
    if table_length(LegitimatePos) > 0  then
        for i=1,#LegitimatePos do
            local posInfo = LegitimatePos[i]
            if  table_vIn(posInfo,_slotNode.p_symbolType) and
                    table_vIn(posInfo,_slotNode.p_cloumnIndex) and 
                        table_vIn(posInfo,_slotNode.p_rowIndex)  then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenGhostBlasterMachine:setReelRunInfo()
    -- assert(nil,"自己配置快滚信息")
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["135"] ,["symbolType"] = {90}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态

    if self.b_gameTipFlag then
        return
    end
    for col=1,self.m_iReelColumnNum do
        local reelRunData = self.m_reelRunInfo[col]
        local runLen = reelRunData:getReelRunLen()
        if col < self.m_iReelColumnNum then
            reelRunData:setReelLongRun(false)
        end

        local reelNode = self.m_baseReelNodes[col]
        reelNode:setRunLen(runLen)
    end
end

function CodeGameScreenGhostBlasterMachine:checkNotifyUpdateWinCoin(_addCoins, _isBonus)
    -- 需要增加的钱
    local addCoins = _addCoins
    local isBonus = _isBonus
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local onceSpinLastWin = self.m_iOnceSpinLastWin
    if addCoins then
        onceSpinLastWin = addCoins
    end

    local upReelWinCoins = self.m_upReel:getTotalWin()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {onceSpinLastWin, isNotifyUpdateTop, nil, upReelWinCoins, isBonus})
end

---------------------------------------------------------------------------

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenGhostBlasterMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    pos.y  = pos.y - 120
    gLobalSoundManager:playSound(PublicConfig.Music_Big_Win_Light)

    local spine = util_spineCreate("GhostBlaster_binwin",true,true)
    rootNode:addChild(spine)
    spine:setPosition(pos)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)

    local aniTime = spine:getAnimationDurationTime("actionframe")
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGhostBlasterMachine:addSelfEffect()

    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons and #storedIcons > 0 then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.HIT_GHOST_IN_FREE_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.HIT_GHOST_IN_FREE_EFFECT -- 动画类型
        else
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.HIT_GHOST_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.HIT_GHOST_EFFECT -- 动画类型
        end
        
        -- 棋盘上出现的炸弹数量多于12时播放
        local shootCount = 0
        for index = 1, #storedIcons do
            local values = storedIcons[index]
            shootCount = shootCount + values[2]
        end

        if shootCount > 12 then
            gLobalSoundManager:playSound(PublicConfig.Music_Shoot_More)
        end
    end
end

--[[
    获取增加的free次数(只加1次)
]]
function CodeGameScreenGhostBlasterMachine:getAddFreeCount()
    local addCount = self.m_addFreeCount
    self.m_addFreeCount = 0
    return addCount
end

--[[
    检测是否显示boss(只检测最终结果)
]]
function CodeGameScreenGhostBlasterMachine:checkShowBoss()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local firstRoundProgress = fsExtraData.firstRoundProgress

    for index = 1,#firstRoundProgress do
        if firstRoundProgress[index] > 0 then
            return false
        end
    end

    return true
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGhostBlasterMachine:MachineRule_playSelfEffect(effectData)

    --打鬼事件
    if effectData.p_selfEffectType == self.HIT_GHOST_EFFECT then
        --炮击时背景音乐不自动关闭
        self:removeSoundHandler()
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:delayCallBack(0.2,function()
            self:hitGhostAni(function()

                if self.m_runSpinResultData.p_winAmount > 0 and #self.m_runSpinResultData.p_winLines == 0 then
                    self.m_bottomUI:notifyTopWinCoin()
                end

                self.m_curHitBonusSymbol = nil
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.HIT_GHOST_IN_FREE_EFFECT then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        self:delayCallBack(0.2,function()
            self:hitGhostInFree(function()
                self.m_curHitBonusSymbol = nil
                --检测结果是否与服务器结果一致
                self.m_enemyNode:checkIsSameResult(fsExtraData)
    
                self.m_isLastBonusInFree = false
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    return true
end

--[[
    最后一次spin轮盘动效
]]
function CodeGameScreenGhostBlasterMachine:showLastSpinLightInFree(func)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if self.m_runSpinResultData.p_freeSpinsLeftCount ~= 0 or #storedIcons == 0 then
        if type(func) == "function" then
            func()
        end
        return
    end

    local light = util_createAnimation("GhostBlaster_Free_qipan.csb")
    self:findChild("root"):addChild(light)
    gLobalSoundManager:playSound(PublicConfig.Music_Free_Final_Light)
    light:runCsbAction("actionframe",false,function()
        if type(func) == "function" then
            func()
        end
        light:removeFromParent()
    end)
end

--[[
    显示boss动画
]]
function CodeGameScreenGhostBlasterMachine:showBossAni(func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData

    self.m_enemyNode:showBossAni(fsExtraData)
    self.m_freeTip:setTipShow(self.m_enemyNode.m_isShowBoss)

    self:showBossStartView(func)
end

--[[
    boss战开始弹板
]]
function CodeGameScreenGhostBlasterMachine:showBossStartView(func)
    local view = util_createAnimation("GhostBlaster_bossstart.csb")
    self:findChild("Node_bossstart"):addChild(view)

    view:findChild("lbl_highBet"):setVisible(self.m_iBetLevel == 1)
    view:findChild("lbl_lowBet"):setVisible(self.m_iBetLevel == 0)
    self:delayCallBack(95 / 60,function()
        gLobalSoundManager:playSound(PublicConfig.Music_Boss_StartAndOver)
    end)
    
    view:runCsbAction("auto",false,function()
        view:removeFromParent()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    free打鬼事件
]]
function CodeGameScreenGhostBlasterMachine:hitGhostInFree(func)
    -- self:showBlackLayer()
    self.m_enemyNode:resetWinCoins()
    local storedIcons = clone(self.m_runSpinResultData.p_storedIcons)

    self.m_freeTip:runOverAni()
    self.m_free_win:resetWinCoinList()

    self.m_hitCountInFree = 0       --boss阶段炮击次数
    self.m_hitCountByCol = {0,0,0,0,0}  --小怪阶段炮击次数

    self.m_isLastBonusInFree = false    --free中最后一个炮
    self.m_isLastShoot = false          --最后一次炮击
    self.m_isDefeatBoss = false         --是否击败boss

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.jackpotWin then
        self.m_isDefeatBoss = true
    end

    --最后一次spin显示光效
    self:showLastSpinLightInFree(function()
        self:hitNextGhostInFree(storedIcons,1,function()
            -- self:hideBlackLayer()
            self.m_free_win:resetWinCoins()
            self:flyWinCoinsToTotalWinInFree(self.m_free_win:findChild("m_lb_coins"),self.m_bottomUI.coinWinNode,self.m_free_win.m_winCoins,function()
                local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                local winAmount = self.m_runSpinResultData.p_winAmount
                local addCoins = nil
                self.m_isJackpot = false
                if fsExtraData.jackpotWin and winAmount then
                    addCoins = winAmount - fsExtraData.jackpotWin
                end
                self:checkNotifyUpdateWinCoin(addCoins, true)
                self:playCoinWinEffectUI()

                self.m_free_win:hideAni()
                self.m_freeTip:showAni()

                if not self.m_enemyNode.m_isShowBoss and self:checkShowBoss() then
                    self:showBossAni(function()
                        if type(func) == "function" then
                            func()
                        end
                    end)
                else
                    if type(func) == "function" then
                        func()
                    end
                end

                
            end)
        end)
    end)
end

--[[
    free中打下个鬼事件
]]
function CodeGameScreenGhostBlasterMachine:hitNextGhostInFree(storedIcons,index,func)
    if index > #storedIcons then
        if self.m_bossStartShow or self.m_isLastShoot then
            if type(func) == "function" then
                func()
            end
        else
            self:delayCallBack(1.5,function()
                if type(func) == "function" then
                    func()
                end
            end)
        end
        
        return
    end

    if index >= #storedIcons then
        self.m_isLastBonusInFree = true
    end

    local iconData = storedIcons[index]

    local symbolNode = self:getSymbolByPosIndex(iconData[1])
    if symbolNode then
        self.m_curHitBonusSymbol = symbolNode
        local ghostAni = self.m_enemyNode:getGhostAniByCol(symbolNode.p_cloumnIndex)
        if ghostAni then
            --小块提层
            symbolNode:setLocalZOrder(symbolNode:getLocalZOrder() + 1000)
            self:runBombardAniInFree(symbolNode,ghostAni,ghostAni.m_hp,1,iconData[2],function()
                self:hitNextGhostInFree(storedIcons,index + 1,func)
            end)
            
        else
            self:hitNextGhostInFree(storedIcons,index + 1,func)
        end
        
    else
        self:hitNextGhostInFree(storedIcons,index + 1,func)
    end
end

--[[
    最后一炮提示
]]
function CodeGameScreenGhostBlasterMachine:showFinalShot(func)
    local tipAni = util_createAnimation("GhostBlaster_Bonus_FINAL.csb")
    self:findChild("Node_FINAL"):addChild(tipAni)
    gLobalSoundManager:playSound(PublicConfig.Music_Free_Final_Text)
    tipAni:runCsbAction("start",false,function()
        if type(func) == "function" then
            func()
        end
        tipAni:removeFromParent()
    end)
end

--[[
    开炮动画(free)
]]
function CodeGameScreenGhostBlasterMachine:runBombardAniInFree(symbolNode,ghostAni,hp,curCount,maxCount,func)

    --检测是否显示boss(调用怪物节点的检测方法,主类中的检测方法只检测最终结果)
    --如果盘面上的炮击次数用尽,要等到收集完金币在显示boss
    if not self.m_enemyNode.m_isShowBoss and self.m_enemyNode:checkShowBoss() and (not self.m_isLastBonusInFree or (curCount <= maxCount and self.m_isLastBonusInFree)) then
        self:showBossAni(function()
            self:runBombardAniInFree(symbolNode,self.m_enemyNode:getGhostAniByCol(symbolNode.p_cloumnIndex),hp,curCount,maxCount,func)
        end)
        self.m_bossStartShow = true
        return
    end

    if curCount > maxCount then
        -- self:putSymbolBackToPreParent(symbolNode)
        -- symbolNode:runAnim("yaan")
        -- symbolNode:setRotation(0)
        if type(func) == "function" then
            func()
        end
        return
    end

    self.m_bossStartShow = false

    if self.m_enemyNode.m_isShowBoss then
        --记录当前炮击次数
        self.m_hitCountInFree = self.m_hitCountInFree + 1
        self.m_hitTotalCountInFree = self.m_hitTotalCountInFree + 1

        --最后一次炮击
        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 and self.m_isLastBonusInFree and curCount >= maxCount then
            self.m_isLastShoot = true
        end
        
    end
    
    self.m_hitCountByCol[symbolNode.p_cloumnIndex]  = self.m_hitCountByCol[symbolNode.p_cloumnIndex] + 1

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    

    local winCoins = 0
    local lineBet = globalData.slotRunData:getCurTotalBet()

    local multiData = fsExtraData.firstRoundMulti
    if self.m_enemyNode.m_isShowBoss then --boss战
        multiData = fsExtraData.secondRoundMulti
        local winMulti = multiData[self.m_hitCountInFree] or 0
        winCoins = winMulti * lineBet

    else --普通小怪
        hp = hp - 1
        local hitCount = self.m_hitCountByCol[symbolNode.p_cloumnIndex]
        local winMulti = multiData[symbolNode.p_cloumnIndex][hitCount] or 0
    
        winCoins = winMulti * lineBet
    end

    self.m_free_win:updateWinCoins(winCoins)

    --最后一炮
    if self.m_isLastShoot then
        --显示最后一炮提示
        self:showFinalShot(function()

            local startPos = util_convertToNodeSpace(symbolNode,self.m_clipParent)
            local endPos = util_convertToNodeSpace(ghostAni,self.m_clipParent)
            endPos.y = endPos.y + 200
            local angle = util_getAngleByPos(startPos,endPos) 
            symbolNode:setRotation(-angle + 90)
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_Final_Shoot)
            symbolNode:runAnim("actionframe_2", false, function()
                self:playSymbolNodeDark(symbolNode, curCount, maxCount)
            end)

            --击中光效
            local feedLight = util_spineCreate("Socre_GhostBlaster_Bonus",true,true)
            self:findChild("root"):addChild(feedLight)
            util_spinePlay(feedLight,"actionframe4")
            util_spineEndCallFunc(feedLight,"actionframe4",function()
                self:delayCallBack(0.1,function()
                    feedLight:removeFromParent()
                end)
            end)
    
            self.m_enemyNode:hitGhostAni(symbolNode.p_cloumnIndex,hp,winCoins,self.m_hitCountInFree,self.m_hitCountInFree,true,function()
                --开下一炮
                self:runBombardAniInFree(symbolNode,ghostAni,hp,curCount + 1,maxCount,func)
            end)
    
    
            self:delayCallBack(30 / 30,function()
                --变更炮击次数
                self:updateBonusCount(symbolNode,maxCount - curCount)
            end)
        end)
    else
        local m_maxHitCount = fsExtraData.secondRoundThreshold
        local curTotalHitCount = self.m_hitTotalCountInFree
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Trigger)
        symbolNode:runAnim("actionframe",false,function()
            self:playSymbolNodeDark(symbolNode, curCount, maxCount)
            if (hp ~= 0 or self.m_enemyNode.m_isShowBoss) and curTotalHitCount ~= m_maxHitCount then
                --开下一炮
                self:runBombardAniInFree(symbolNode,ghostAni,hp,curCount + 1,maxCount,func)
            end
        end)
    
        --炮击光效
        self:showBombardLightAni(symbolNode,ghostAni,function()
            local hitCount = self.m_hitCountByCol[symbolNode.p_cloumnIndex]
            local totalCount = 0
            if self.m_enemyNode.m_isShowBoss then
                hitCount = self.m_hitCountInFree
                totalCount = #fsExtraData.secondRoundMulti
            else
                totalCount = #fsExtraData.firstRoundMulti[symbolNode.p_cloumnIndex] or 0
            end
            
            self.m_enemyNode:hitGhostAni(symbolNode.p_cloumnIndex,hp,winCoins,hitCount,totalCount,false,function()
                if hp == 0 and not self.m_enemyNode.m_isShowBoss then
                    --开下一炮
                    self:runBombardAniInFree(symbolNode,ghostAni,hp,curCount + 1,maxCount,func)
                -- actionframe2时间线拉长，播完动画回调
                elseif self.m_enemyNode.m_isShowBoss and curTotalHitCount == m_maxHitCount then
                    --开下一炮
                    self:runBombardAniInFree(symbolNode,ghostAni,hp,curCount + 1,maxCount,func)
                end
            end)
        end,function()
            
        end)
    
        self:delayCallBack(15 / 30,function()
            --变更炮击次数
            self:updateBonusCount(symbolNode,maxCount - curCount)
        end)
    end
end

-- 小块回位；压暗
function CodeGameScreenGhostBlasterMachine:playSymbolNodeDark(_symbolNode, _curCount, _maxCount)
    local symbolNode = _symbolNode
    local curCount = _curCount
    local maxCount = _maxCount
    if not tolua.isnull(symbolNode) and curCount >= maxCount then
        self:putSymbolBackToPreParent(symbolNode)
        symbolNode:runAnim("yaan")
        symbolNode:setRotation(0)
    end
end

--[[
    收集金币奖励或free次数
]]
function CodeGameScreenGhostBlasterMachine:flyFreeCountOrCoinsInFree(startNode,freeCount,coins,func)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    
    local flyNode,endNode
    local isCoins = true
    if freeCount ~= 0 then
        --边缘时要保证不切边
        if startPos.x - 120 <= 0 then
            startPos.x = 130
        elseif startPos.x + 120 >= display.width then
            startPos.x = startPos.x - 130
        end
        flyNode = util_createAnimation("GhostBlaster_ExtraFreeGames.csb")
        endNode = self.m_baseFreeSpinBar:findChild("m_lb_num_0") 
        local m_lb_num = flyNode:findChild("m_lb_num")
        m_lb_num:setString("+"..freeCount)
        flyNode:findChild("freegame"):setVisible(freeCount <= 1)
        flyNode:findChild("freegames"):setVisible(freeCount > 1)
        isCoins = false
    else
        flyNode = util_createAnimation("GhostBlaster_CoinsGrow.csb")
        local particle = util_createAnimation("GhostBlaster_CoinsGrow_tuoweilizi.csb")
        flyNode:findChild("Node_particle"):addChild(particle)
        if particle:findChild("Particle_1") then
            particle:findChild("Particle_1"):setPositionType(0)
        end
        flyNode.m_particle = particle
        particle:setVisible(false)
        endNode = self.m_free_win
        local m_lb_coins = flyNode:findChild("m_lb_coins")
        local m_lb_coins_0 = flyNode:findChild("m_lb_coins_0")
        m_lb_coins:setString("+"..util_formatCoins(coins,3))
        m_lb_coins_0:setString("+"..util_formatCoins(coins,3))
        if not self.m_free_win:isVisible() then
            self.m_free_win:showAni()
        end

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData.secondRoundProgress >= fsExtraData.secondRoundThreshold then
            flyNode:findChild("Node_little"):setVisible(false)
            flyNode:findChild("Node_big"):setVisible(true)
        else
            flyNode:findChild("Node_little"):setVisible(true)
            flyNode:findChild("Node_big"):setVisible(false)
        end
    end

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    
    self:flyNodeInFree(flyNode,endNode,isCoins,function()
        if isCoins then
            if flyNode.m_particle and flyNode.m_particle:findChild("Particle_1") then
                flyNode.m_particle:findChild("Particle_1"):stopSystem()
            end
            self.m_free_win:runFeedBackAni(coins)
        else
            self.m_baseFreeSpinBar:runFeedBackAni()
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
        end
        if type(func) == "function" then
            func()
        end
    end)

end

--[[
    金币飞行动画(free)
]]
function CodeGameScreenGhostBlasterMachine:flyNodeInFree(flyNode,endNode,isCoins,func)
    local startPos = cc.p(flyNode:getPosition())
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local actionName = "EaseCubicActionIn"
    local delayTime,flyTime = 0.6,50 / 60
    if isCoins then
        delayTime,flyTime = 0.5,25 / 60
        actionName = "EaseQuadraticActionIn"
    end
    flyNode:runCsbAction("start",false,function()
        local actionList = {
            cc.DelayTime:create(delayTime),
            cc.CallFunc:create(function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_CollectCoins)
                flyNode:runCsbAction("fly")
                if flyNode.m_particle then
                    flyNode.m_particle:setVisible(true)
                end
            end),
            cc[actionName]:create(cc.BezierTo:create(flyTime,{startPos, cc.p((startPos.x + endPos.x) / 2, startPos.y + 300), endPos})),
            cc.CallFunc:create(function()
                flyNode:findChild("root"):setVisible(false)
                if type(func) == "function" then
                    func()
                end
            end),
            cc.DelayTime:create(1),
            cc.RemoveSelf:create(true)
        }

        flyNode:runAction(cc.Sequence:create(actionList))
        
    end)
end

--[[
    金币飞行动画(free收集本次打击赢钱到赢钱区)
]]
function CodeGameScreenGhostBlasterMachine:flyWinCoinsToTotalWinInFree(startNode,endNode,coins,func)
    local flyNode = util_createAnimation("GhostBlaster_FreeWins_Coins.csb")
    self.m_effectNode:addChild(flyNode)

    local label = flyNode:findChild("m_lb_coins")
    label:setString(util_formatCoins(coins,3))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,230)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)

    local delayTime,flyTime = 30 / 60,20 / 60

    local actionList = {
        cc.DelayTime:create(0.3),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_Collect_Bottom)
            flyNode:runCsbAction("fly")
        end),
        cc.DelayTime:create(delayTime),
        cc.CallFunc:create(function()
            
        end),
        cc.EaseQuadraticActionIn:create(cc.MoveTo:create(flyTime,endPos)),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    
end

--[[
    检测轮盘上的scatter图标放到压黑层下方
]]
function CodeGameScreenGhostBlasterMachine:putScatterSymbolBack()
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self:putSymbolBackToPreParent(symbolNode)
        end
    end
end

--[[
    打鬼动画
]]
function CodeGameScreenGhostBlasterMachine:hitGhostAni(func)
    local storedIcons = clone(self.m_runSpinResultData.p_storedIcons) 
    -- table.sort( storedIcons, function(a, b)
    --     return a[1] < b[1]
    -- end)

    --当前击败小鬼数量
    self.m_clearCount = 0

    self:showBlackLayer()
    --检测轮盘上的scatter图标放到压黑层下方
    self:putScatterSymbolBack()

    self.m_upReel:resetWinCoins()

    self:hitNextGhost(storedIcons,1,function()
        
        local betData = self:updateCurUpReelInfo()

        --检测客户端结果是否与服务器一致
        self.m_upReel:checkIsReelSame(betData)

        self:hideBlackLayer()

        for index = 1,#storedIcons do
            local symbolNode = self:getSymbolByPosIndex(storedIcons[index][1])
            if symbolNode then
                symbolNode:runAnim("idleframe")
            end
        end

        self:checkAddBigWinEffect()

        --触发bonus玩法时要移除大赢事件
        if self:checkTriggerBonus() then
            self:removeBigWinEffect()
        end

        self:delayCallBack(0.5,function()
            self.m_upReel:clearDefeatGhost()
            if type(func) == "function" then
                func()
            end
        end)
        
    end)
end

--[[
    打击下个小鬼
]]
function CodeGameScreenGhostBlasterMachine:hitNextGhost(storedIcons,index,func)
    if index > #storedIcons then
        
        if type(func) == "function" then
            func()
        end
        return
    end
    local iconData = storedIcons[index]
    --本次炮击是否有击败小鬼
    self.m_isCurClearGhost = false

    util_printLog("GhostBlaster_log 第"..index.."个bonus开炮")

    local symbolNode = self:getSymbolByPosIndex(iconData[1])
    if symbolNode then
        self.m_curHitBonusSymbol = symbolNode
        local ghostAni = self.m_upReel:getGhostAniByCol(symbolNode.p_cloumnIndex)
        if ghostAni then
            self.m_upReel:changeHpSignToTop(ghostAni)
            symbolNode:setLocalZOrder(symbolNode:getLocalZOrder() + 1000)
            local hp = self.m_upReel:getCurHp(ghostAni.m_colIndex,ghostAni.m_rowIndex)
            local delayTime = 0
            -- util_printLog("GhostBlaster_log 当前小鬼血量为:"..hp)
            if hp <= iconData[2] then
                self.m_clearCount = self.m_clearCount + 1
                -- util_printLog("GhostBlaster_log 当前击败数量为:"..self.m_clearCount)
                self.m_isCurClearGhost = true
                self.m_upReel:setGhostDefeatStatus(ghostAni)

                if self.m_clearCount > #self.m_runSpinResultData.p_selfMakeData.changeReels then
                    util_printLog("GhostBlaster_log 清理数量计算错误",true)
                end

                --刚好打死,需加延迟下落
                if hp == iconData[2] then
                    if ghostAni.m_symbolType ~= self.SYMBOL_GHOST_4 then
                        delayTime = 20 / 30
                        if ghostAni.m_posData.rowCount == 3 then
                            delayTime = 25 / 30
                        end
                    end
                end
            end
            
            --开炮动画
            self:runBombardAni(symbolNode,ghostAni,hp,iconData[2],function()
                local selfData = self.m_runSpinResultData.p_selfMakeData
                local nextReels = selfData.changeReels[self.m_clearCount + 1]
                local nextTimes = selfData.changeTimes[self.m_clearCount + 1]
                local nextMulti = selfData.changeMulti[self.m_clearCount + 1]
                ghostAni = self.m_upReel:getGhostAniByCol(symbolNode.p_cloumnIndex)
                if ghostAni then
                    util_printLog("GhostBlaster_log 该bonus结束炮击,检测落下新的小鬼")
                    --检测是否需要落下新的小鬼
                    self:delayCallBack(delayTime,function()
                        self.m_upReel:checkDownNewGhost(ghostAni,nextReels,nextTimes,nextMulti,delayTime > 0,function()
                            self:hitNextGhost(storedIcons,index + 1,func)
                        end)
                    end)
                else
                    self:hitNextGhost(storedIcons,index + 1,func)
                end
                
            end)
        else
            self:hitNextGhost(storedIcons,index + 1,func)
        end
        
    else
        self:hitNextGhost(storedIcons,index + 1,func)
    end
end

--[[
    开炮动画
    @count: 开炮次数
]]
function CodeGameScreenGhostBlasterMachine:runBombardAni(symbolNode,ghostAni,hp,count,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --血量为0时,需要切换怪物
    if hp <= 0 then
        self.m_upReel:putHpSignBack(ghostAni)
        util_printLog("GhostBlaster_log 血量为0,切换小鬼")
        self.m_upReel:checkChangeReels(ghostAni,selfData,symbolNode.p_cloumnIndex,count,self.m_clearCount,function()
            ghostAni = self.m_upReel:getGhostAniByCol(symbolNode.p_cloumnIndex)
            if not ghostAni then
                util_printLog("GhostBlaster_log 未获取到对应小怪,请检查数据",true)
                if type(func) == "function" then
                    func()
                end
                return
            end
            self.m_upReel:changeHpSignToTop(ghostAni)
            local hp = self.m_upReel:getCurHp(ghostAni.m_colIndex,ghostAni.m_rowIndex)
            if hp <= count then
                self.m_upReel:setGhostDefeatStatus(ghostAni)
            end
            --开下一炮
            self:runBombardAni(symbolNode,ghostAni,hp,count,func)
        end) 
        
        return
    end

    if count <= 0 then
        self.m_upReel:putHpSignBack(ghostAni)
        self:putSymbolBackToPreParent(symbolNode)
        symbolNode:runAnim("yaan")
        if type(func) == "function" then
            func()
        end
        return
    end

    gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Trigger)
    symbolNode:runAnim("actionframe",false,function()
        --开下一炮
        self:runBombardAni(symbolNode,ghostAni,hp - 1,count - 1,func)
    end)

    --第20帧爱心消失
    if hp == 1 then
        self:delayCallBack(20 / 30,function()
            self.m_upReel:hideHpSign(ghostAni)
        end)
    end

    self.m_upReel:setHp(ghostAni,hp - 1)
    self:showBombardLightAni(symbolNode,ghostAni,function()
        self.m_upReel:hitGhostAni(ghostAni,hp - 1,count - 1)
        
    end,function()
        
    end)

    self:delayCallBack(15 / 30,function()
        --变更炮击次数
        self:updateBonusCount(symbolNode,count - 1)
    end)
    --
end

--[[
    显示炮击闪电
]]
function CodeGameScreenGhostBlasterMachine:showBombardLightAni(startNode,endNode,keyFunc,endFunc)

    -- 创建粒子
    local flyNode =  util_createAnimation("GhostBlaster_sd.csb")
    local zOrder = startNode:getLocalZOrder()
    --比压黑层要高一层
    self.m_clipParent:addChild(flyNode,zOrder - 1)

    local startPos = util_convertToNodeSpace(startNode,self.m_clipParent)
    local endPos = util_convertToNodeSpace(endNode,self.m_clipParent)

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_enemyNode.m_isShowBoss then
        endPos.y = endPos.y + 200
    else --base下打击光效不偏转
        endPos.x = startPos.x
    end
    
    --设置位置
    flyNode:setPosition(startPos)

    --设置偏转角度
    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( -angle)

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_enemyNode.m_isShowBoss then
        startNode:setRotation(-angle + 90)
    end

    --设置缩放
    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 464 )

    self:delayCallBack(40 / 60,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)

    flyNode:runCsbAction("actionframe",false,function()
        if type(endFunc) == "function" then
            endFunc()
        end

        flyNode:removeFromParent()
    end)

    --击中光效
    local feedLight = util_spineCreate("Socre_GhostBlaster_Bonus",true,true)
    self.m_effectNode:addChild(feedLight,100)
    local pos = util_convertToNodeSpace(endNode,self.m_effectNode)
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_enemyNode.m_isShowBoss then
            pos.y = pos.y + 200
            feedLight:setScale(1.3)
        else
            local scaleCfg = {0.6,0.7,1,0.7,0.6}
            feedLight:setScale(scaleCfg[startNode.p_cloumnIndex])            
            
        end
    else
        local scaleCfg = {1.2,1,0.6,0.6}
        feedLight:setScale(scaleCfg[endNode.m_symbolType - 10])
    end
    feedLight:setPosition(pos)

    util_spinePlay(feedLight,"actionframe3")
    util_spineEndCallFunc(feedLight,"actionframe3",function()
        feedLight:setVisible(false)
        self:delayCallBack(0.1,function()
            feedLight:removeFromParent()
        end)
        
    end)

    return flyNode
    
end

--[[
    free中打击小鬼掉金币动效
]]
function CodeGameScreenGhostBlasterMachine:hitGhostDropCoinsInFree(colIndex,pos,isBoss,status)
    --掉金币动效
    local spine = util_spineCreate("GhostBlaster_Jinbi",true,true)
    self.m_effectNode:addChild(spine,50)
    spine:setPosition(pos)
    local scaleCfg = {0.6,0.8,1,0.8,0.6}
    local scale = 1
    if isBoss then
        scale = 1.3
    else
        scale = scaleCfg[colIndex]
    end
    spine:setScale(scale)   
    local aniName = "jinbi_zha"    
    if status == "change" then
        aniName = "actionframe4"    
    elseif status == "box" then
        aniName = "actionframe5"  
    end
    util_spinePlay(spine,aniName)
    util_spineEndCallFunc(spine,aniName,function()
        spine:setVisible(false) 
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)
end

function CodeGameScreenGhostBlasterMachine:beginReel()
    self.m_isJackpot = false
    CodeGameScreenGhostBlasterMachine.super.beginReel(self)
end

function CodeGameScreenGhostBlasterMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            delayTime = delayTime + self:getWinCoinTime()
        end

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

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

-- 是不是 respinBonus小块
function CodeGameScreenGhostBlasterMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return true
    end
    return false
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenGhostBlasterMachine:getReSpinSymbolScore(id)
    
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local multi = nil

    for index = 1, #storedIcons do
        local values = storedIcons[index]
        if values[1] == id then
            multi = values[2]
        end
    end

    if multi == nil then
       return 0
    end

    return multi
end

--[[
    随机bonus分数
]]
function CodeGameScreenGhostBlasterMachine:randomDownRespinSymbolScore(symbolType)
    local multi = self.m_configData:getFixSymbolPro()
    return multi
end

--[[
    刷新小块显示
]]
function CodeGameScreenGhostBlasterMachine:updateReelGridNode(node,isInit)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node,isInit)
    end
end

-- 给respin小块进行赋值
function CodeGameScreenGhostBlasterMachine:setSpecialNodeScore(symbolNode,isInit)
    if tolua.isnull(symbolNode) or not symbolNode.p_symbolType then
        return
    end

    local symbolType = symbolNode.p_symbolType
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local posIndex = self:getPosReelIdx(iRow, iCol)
    local score = 0

    --初始化时bonus图标上不显示次数
    if not isInit then
        if symbolNode.m_isLastSymbol == true then 
            --根据网络数据获取停止滚动时respin小块的分数
            score = self:getReSpinSymbolScore(posIndex) --获取分数（网络数据）
        else
            score =  self:randomDownRespinSymbolScore(symbolType)
        end
    end
    
    self:updateBonusCount(symbolNode,score)
end

--[[
    变更炮击次数
]]
function CodeGameScreenGhostBlasterMachine:updateBonusCount(symbolNode,count)
    local labelCsb = self:getLblCsbOnSymbol(symbolNode,"GhostBlaster_Bonus_shuzi.csb","kb")
    if not tolua.isnull(labelCsb) then
        local m_lb_num = labelCsb:findChild("m_lb_num")
        if m_lb_num then
            local str = count
            if count <= 0 then
                str = ""
            end
            m_lb_num:setString(str)
        end
    end
end

-- 判断是否触发free；并且没有预告中奖
function CodeGameScreenGhostBlasterMachine:getCurIsTriggerFree()
    local features = self.m_runSpinResultData.p_features or {}

    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_FREESPIN and self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self.b_gameTipFlag then
            return true
        end
    end
    return false
end

----------------------------新增接口插入位---------------------------------------------
--[[
    播放预告中奖概率
    GD.SLOTO_FEATURE = {
        FEATURE_FREESPIN = 1,
        FEATURE_FREESPIN_FS = 2, -- freespin 中再次触发fs
        FEATURE_RESPIN = 3, -- 触发respin 玩法
        FEATURE_MINI_GAME_COLLECT = 4, -- 收集玩法小游戏
        FEATURE_MINI_GAME_OTHER = 5, -- 其它小游戏
        FEATURE_JACKPOT = 6 -- 触发 jackpot
    }
]]
function CodeGameScreenGhostBlasterMachine:getFeatureGameTipChance()
    local features = self.m_runSpinResultData.p_features or {}
    -- 出现预告动画概率默认为70%
    local isNotice = (math.random(1, 100) <= 70) 

    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_FREESPIN and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            return isNotice,"free"
        end
    end

    --bonus个数大于3个
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons and #storedIcons >= 5 then
        return isNotice,"bonus"
    end

    
    return false,"normal"
end
-- 播放预告中奖统一接口
-- 子类重写接口
function CodeGameScreenGhostBlasterMachine:showFeatureGameTip(_func)
    local isNotice,featureType = self:getFeatureGameTipChance()
    if isNotice then

        --播放预告中奖动画
        self:playFeatureNoticeAni(featureType,function()
            if type(_func) == "function" then
                _func()
            end
        end)
        
    else
        if type(_func) == "function" then
            _func()
        end
    end
end

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
]]
function CodeGameScreenGhostBlasterMachine:playFeatureNoticeAni(featureType,func)
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("root")

    self.b_gameTipFlag = true

    if featureType == "free" then

        gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_YuGao_Sound)
        local csbNode = util_createAnimation("GhostBlaster_yugao.csb")
        parentNode:addChild(csbNode)
        csbNode:runCsbAction("actionframe")
        --第115帧消散粒子效果
        self:delayCallBack(115 / 60,function()
            if tolua.isnull(csbNode) then
                return
            end
            for index = 1,4 do
                local particle = csbNode:findChild("Particle_"..index)
                if not tolua.isnull(particle) then
                    particle:stopSystem()
                end
            end
        end)

        --创建对应格式的spine
        local spineAni = util_spineCreate("GhostBlaster_yugao",true,true)
        csbNode:findChild("Node_yugao_jinbi"):addChild(spineAni)
        util_spinePlay(spineAni,"actionframe")
        util_spineEndCallFunc(spineAni,"actionframe",function()
            csbNode:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            self:delayCallBack(0.1,function()
                csbNode:removeFromParent()
            end)
            
        end)
        aniTime = spineAni:getAnimationDurationTime("actionframe")
    else
        local spineAni = util_spineCreate("Socre_GhostBlaster_juese",true,true)
        parentNode:addChild(spineAni)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_YuGao_Sound)
        util_spinePlay(spineAni,"actionframe")
        util_spineEndCallFunc(spineAni,"actionframe",function()
            spineAni:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            self:delayCallBack(0.1,function()
                spineAni:removeFromParent()
            end)
            
        end)
        aniTime = spineAni:getAnimationDurationTime("actionframe")
    end

    
    
    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    --预告中奖时间比滚动时间短,直接返回即可
    if aniTime <= delayTime then
        if type(func) == "function" then
            func()
        end
    else
        self:delayCallBack(aniTime - delayTime,function()
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--[[
    检测是否触发pick玩法
]]
function CodeGameScreenGhostBlasterMachine:checkTriggerPicks()
    local features = self.m_runSpinResultData.p_features
    if not features then
        return false
    end

    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            return true
        end
    end

    return false
end

--[[
    显示pick玩法提示
]]
function CodeGameScreenGhostBlasterMachine:showPickTip()
    self.m_pickTip:setVisible(true)
    self.m_pickTip:runCsbAction("start",false,function()
        self.m_pickTip:runCsbAction("idle",true)
    end)
    
end

--[[
    隐藏pick玩法提示
]]
function CodeGameScreenGhostBlasterMachine:hidePickTip(func)
    self.m_pickTip:runCsbAction("over",false,function()
        self.m_pickTip:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    bonus玩法
]]
function CodeGameScreenGhostBlasterMachine:showEffect_Bonus(effectData)

    if not self.m_pickTip:isVisible() then
        self:showPickTip()
    end

    local endFunc = function(isTriggerFs)
        self:resetMusicBg()
        if isTriggerFs then
            --添加free玩法
            self:checkAddFSEffect()
        else
            self:checkAddBigWinEffect()
        end

        effectData.p_isPlay = true
        self:playGameEffect()
    end
    
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Choose_Text_Trigger)
    self.m_pickTip:runCsbAction("actionframe",false,function()
        self.m_pickTip:setVisible(false)
        local bonusView = util_createView("CodeGhostBlasterSrc.GhostBlasterPickView",{machine = self})
        self:addChild(bonusView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
        bonusView:setPosition(cc.p(0,0))
        
        bonusView:setBonusData(nil,endFunc)

        bonusView:showView()

        bonusView:findChild("root"):setScale(self.m_machineRootScale)
        
    end)

    return true
end

--[[
    检测添加大赢事件
]]
function CodeGameScreenGhostBlasterMachine:checkAddBigWinEffect()
    if not self:checkHasBigWin() then
        self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, GameEffect.EFFECT_BONUS)
    end

    for index = 1,#self.m_gameEffects do
        local effectData = self.m_gameEffects[index]
        if self:isBigWinEffectType(effectData.p_effectType) then
            effectData.p_effectOrder = effectData.p_effectType
        end
    end

    --检测添加大赢光效
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self:checkTriggerBonus() then
        if not self:checkHasGameEffectType(GameEffect.EFFECT_BIG_WIN_LIGHT) then
            self:checkAddBigWinLight()
        end
    end
    self:sortGameEffects()
end

--[[
    是否为bonus触发
]]
function CodeGameScreenGhostBlasterMachine:checkTriggerBonus()
    local features = self.m_runSpinResultData.p_features
    if not features then
        return false
    end

    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            return true
        end
    end

    return false
end

--[[
    移除大赢事件
]]
function CodeGameScreenGhostBlasterMachine:removeBigWinEffect()
    for index = #self.m_gameEffects,1,-1 do
        local effectData = self.m_gameEffects[index]
        if self:isBigWinEffectType(effectData.p_effectType) or effectData.p_effectType == GameEffect.EFFECT_BIG_WIN_LIGHT then
            table.remove(self.m_gameEffects,index)
        end
    end
end

--[[
    检测添加free事件
]]
function CodeGameScreenGhostBlasterMachine:checkAddFSEffect()
    if not self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
        -- 添加freespin effect
        local freeSpinEffect = GameEffectData.new()
        freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
        freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
        self:sortGameEffects()

        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
    end
end

--[[
    飞金币动画
]]
function CodeGameScreenGhostBlasterMachine:flyPickCoinsToTotalWin(winCoins,startNode,endNode,func)

    local flyNode = util_createAnimation("GhostBlaster_picktanban_0.csb")
    self.m_effectNode:addChild(flyNode)

    flyNode:findChild("Node_FG"):setVisible(false)
    flyNode:findChild("Node_FG_0"):setVisible(false)
    flyNode:findChild("Node_coins_0"):setVisible(false)

    local m_lb_coins = flyNode:findChild("m_lb_coins")
    m_lb_coins:setString(util_formatCoins(winCoins,3))


    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)   

    flyNode:setPosition(startPos)

    local actionList = {
        cc.DelayTime:create(16 / 60),
        cc.EaseQuadraticActionIn:create(cc.MoveTo:create(24 / 60,endPos)),
        cc.CallFunc:create(function()
            flyNode:setVisible(false)

            local totalWin = self.m_upReel:getTotalWin()
            self:playCoinWinEffectUI()
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_iOnceSpinLastWin))
            self.m_bottomUI:notifyTopWinCoin()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    }

    gLobalSoundManager:playSound(self.m_publicConfig.Music_Pick_CollectCoins)
    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("fly")
end


function CodeGameScreenGhostBlasterMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeGhostBlasterSrc.GhostBlasterFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenGhostBlasterMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:runIdleAni()
end

function CodeGameScreenGhostBlasterMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenGhostBlasterMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    self:delayCallBack(animTime,function()
        self:resetMaskLayerNodes()
        callFun()
    end)
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenGhostBlasterMachine:hideFreeSpinUI()
    self:hideFreeSpinBar()

    self.m_upReel:setVisible(true)
    self.m_enemyNode:setVisible(false)

    self.m_freeTip:runOverAni()

    self.m_jackPotBarView:changeShow("base")
    -- self.m_jackPotBarView:runIdleAni()
    self:changeBgAni("base")

    self:changeReelToTriggerFree()
end

--[[
    将轮盘恢复成触发free时的轮盘
]]
function CodeGameScreenGhostBlasterMachine:changeReelToTriggerFree()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if not fsExtraData or not fsExtraData.startReels then
        return
    end

    local reels = fsExtraData.startReels

    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        for iRow = 1,#reelNode.m_rollNodes do
            local symbolNode = self:getFixSymbol(iCol, iRow)
            if symbolNode then
                symbolNode.m_isLastSymbol = false
                local symbolType
                if iRow > self.m_iReelRowNum then
                    symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
                else
                    symbolType = reels[self.m_iReelRowNum - iRow + 1][iCol]
                end
                if symbolNode.p_symbolType == symbolType and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    symbolNode:runAnim("idleframe")
                    self:putSymbolBackToPreParent(symbolNode)
                else
                    self:changeSymbolType(symbolNode,symbolType)
                end
                self:updateReelGridNode(symbolNode,true)
                
            end
        end
    end
end

--[[
    显示freeSpin相关UI
]]
function CodeGameScreenGhostBlasterMachine:showFreeSpinUI()
    self:showFreeSpinBar()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData

    self.m_upReel:setVisible(false)
    self.m_enemyNode:setVisible(true)

    self.m_enemyNode:resetView(fsExtraData)
    self.m_hitTotalCountInFree = fsExtraData.secondRoundProgress

    self.m_freeTip:setTipShow(self.m_enemyNode.m_isShowBoss)
    self.m_freeTip:showAni()


    self.m_jackPotBarView:changeShow("free")
    if self.m_enemyNode.m_isShowBoss then
        self:changeBgAni("boss")
    else
        self:changeBgAni("free")
    end
    
end

-- 显示free spin
function CodeGameScreenGhostBlasterMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    
    if scatterLineValue ~= nil then
        -- 等最后一个落地播完再触发
        self:delayCallBack(12/30,function()
            self:showBonusAndScatterLineTip(
                scatterLineValue,
                function()
                    -- self:visibleMaskLayer(true,true)
                    -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                    self:showFreeSpinView(effectData)
                end
            )
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        end)
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenGhostBlasterMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("GhostBlasterSounds/music_GhostBlaster_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local cutSceneFunc = function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
            self:delayCallBack(5 / 60,function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
            end)
        end
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startStart)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            --     effectData.p_isPlay = true
            --     self:playGameEffect()
            -- end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                --过场动画
                self:changeSceneToFree(function()
                    self:showFreeSpinUI()
                end,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end)
            end)
            view:setBtnClickFunc(cutSceneFunc)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenGhostBlasterMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}

    local autoType
    if isAuto then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, autoType)

    if view:findChild("root") then
        view:findChild("root"):setScale(self.m_machineRootScale)
    end

    for index = 1,5 do
        view:findChild("fs_count_"..(index + 3)):setVisible((index + 3) == num)
    end

    local configData = {}
    configData[#configData + 1] = {
        spine = "GhostBlaster_xg1",
        parent = "Node_juese_fen",
        isLoop = true,
        aniName = "tanban_idleframe2"
    }
    configData[#configData + 1] = {
        spine = "GhostBlaster_xg2",
        parent = "Node_juese_lan",
        isLoop = true,
        aniName = "tanban_idleframe2"
    }
    configData[#configData + 1] = {
        spine = "GhostBlaster_anniu_paopao",
        parent = "Node_anniu",
        aniName = "actionframe",
        isLoop = true
    }
    configData[#configData + 1] = {
        spine = "GhostBlaster_tanban_bf",
        parent = "Node_bianfu",
        aniName = "actionframe",
        isLoop = false
    }

    for index = 1,#configData do
        local data = configData[index]
        local spine = util_spineCreate(data.spine,true,true)
        view:findChild(data.parent):addChild(spine)
        util_spinePlay(spine,data.aniName,data.isLoop)
    end

    local light = util_createAnimation("GhostBlaster_tanban_guang.csb")
    view:findChild("Node_guang"):addChild(light)
    light:runCsbAction("actionframe",true)

    return view
end

--[[
    过场动画
]]
function CodeGameScreenGhostBlasterMachine:changeSceneToBase(keyFunc,endFunc)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_FreeToBase_CutScene)
    local spine = util_spineCreate("GhostBlaster_guochang2",true,true)
    self:findChild("root"):addChild(spine)
    util_spinePlay(spine,"actionframe_guochang")
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(10 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
end

--[[
    过场动画
]]
function CodeGameScreenGhostBlasterMachine:changeSceneToFree(keyFunc,endFunc)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_BaseToFree_CutScene)
    self:resetMusicBg(true,"GhostBlasterSounds/music_GhostBlaster_free.mp3")
    local spine = util_spineCreate("GhostBlaster_guochang",true,true)
    self:findChild("root"):addChild(spine)
    util_spinePlay(spine,"actionframe_guochang")
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(70 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
end

function CodeGameScreenGhostBlasterMachine:showFreeSpinOverView()

    self:clearWinLineEffect()
    self.m_hitTotalCountInFree = 0
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 3, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        self:delayCallBack(5 / 60,function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_overOver)
        end)
    end
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:changeSceneToBase(function()
            self:hideFreeSpinUI()
        end,function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)

    view:setBtnClickFunc(cutSceneFunc)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.91,sy=0.91},715)

    local configData = {}
    configData[#configData + 1] = {
        spine = "GhostBlaster_xg2",
        parent = "Node_juese1",
        aniName = "tanban_idleframe3"
    }
    configData[#configData + 1] = {
        spine = "GhostBlaster_xg3",
        parent = "Node_juese2",
        aniName = "tanban_idleframe2"
    }
    configData[#configData + 1] = {
        spine = "Socre_GhostBlaster_juese",
        parent = "Node_juese3",
        aniName = "actionframe2"
    }
    configData[#configData + 1] = {
        spine = "GhostBlaster_anniu_paopao",
        parent = "Node_anniu",
        aniName = "actionframe"
    }

    for index = 1,#configData do
        local data = configData[index]
        local spine = util_spineCreate(data.spine,true,true)
        view:findChild(data.parent):addChild(spine)
        util_spinePlay(spine,data.aniName,true)
    end
    
    if view:findChild("root") then
        view:findChild("root"):setScale(self.m_machineRootScale)
    end
end

--[[
    显示jackpotWin
]]
function CodeGameScreenGhostBlasterMachine:showJackpotView(func)
    self.m_jackPotBarView:runIdleAni()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local winCoins = fsExtraData.jackpotWin
    local view = util_createView("CodeGhostBlasterSrc.GhostBlasterJackpotWinView",{
        winCoin = winCoins,
        machine = self,
        func = function(  )
            self.m_isJackpot = true
            self:checkNotifyUpdateWinCoin(winCoins, true)
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

-------------------------------------------------------------------------

function CodeGameScreenGhostBlasterMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenGhostBlasterMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end
end

---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenGhostBlasterMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenGhostBlasterMachine.super.MachineRule_ResetReelRunData(self)
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenGhostBlasterMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Buling)
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenGhostBlasterMachine:playScatterDownSound(colIndex)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Buling)
end

function CodeGameScreenGhostBlasterMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
    end
end


function CodeGameScreenGhostBlasterMachine:scaleMainLayer()
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
        self.m_isPadScale = true
        mainPosY = mainPosY + 40
    else
        mainScale = wScale
        mainPosY = mainPosY + 20
    end

    local ratio = display.height / display.width
    if ratio <= 2176 / 1800 then
        self:findChild("bg"):setScale(1.2)
    end

    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
    self:findChild("root"):setPosition(display.center)
end
return CodeGameScreenGhostBlasterMachine






