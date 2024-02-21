---
-- island li
-- 2019年1月26日
-- CodeGameScreenEpicElephantMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "EpicElephantPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenEpicElephantMachine = class("CodeGameScreenEpicElephantMachine", BaseNewReelMachine)

-- Wild	92	
-- BNOUS1	94	普通
-- 95为1列普通wild，96为2列，97为三列
-- BONUS2	101	mini
-- BONUS3	102	mior
-- BONUS4	103	major
-- BONUS5	104	mega
-- BONUS6	105	轮盘
-- BONUS7	106	FREEwild
-- GRAND	107	

CodeGameScreenEpicElephantMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenEpicElephantMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- bonus
CodeGameScreenEpicElephantMachine.SYMBOL_BONUS_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- mini
CodeGameScreenEpicElephantMachine.SYMBOL_BONUS_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- minor
CodeGameScreenEpicElephantMachine.SYMBOL_BONUS_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10  -- major
CodeGameScreenEpicElephantMachine.SYMBOL_BONUS_MEGA = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11  -- mega
CodeGameScreenEpicElephantMachine.SYMBOL_BONUS_WHEEL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12  -- 轮盘图标
CodeGameScreenEpicElephantMachine.SYMBOL_WILD_FREE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  -- free中的wild
CodeGameScreenEpicElephantMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

CodeGameScreenEpicElephantMachine.COLLECT_SHOP_SCORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集商店金币次数
CodeGameScreenEpicElephantMachine.COLLECT_FREE_TIMES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集freespin次数
CodeGameScreenEpicElephantMachine.SUPER_FREE_BACK_OPENSHOP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- super free返回需要打开商店

local signTag = 1001        --角标tag值
--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenEpicElephantMachine:ctor()
    CodeGameScreenEpicElephantMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isShowAllWild = false
    self.m_publicConfig = PublicConfig
    self.m_isStopQuickGun = false --有预告动画的时候 不播放快滚
    self.m_lockWilds = {}
    self.m_isQuicklyStop = false --是否点击快停 
    self.m_isPlayBulingSound = true --判断播放几次落地音效
    self.m_isShowJiaoBiao = false --判断是否显示角标 断线进来不显示
 
    --init
    self:initGame()
end

function CodeGameScreenEpicElephantMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenEpicElephantMachine:initGameStatusData(gameData)
    if gameData.special then
        gameData.spin.features = gameData.special.features
        gameData.spin.freespin = gameData.special.freespin
        gameData.spin.selfData = gameData.special.selfData
    end
    CodeGameScreenEpicElephantMachine.super.initGameStatusData(self, gameData)
    self.m_shopConfig = gameData.gameConfig.extra
    self.m_shopConfig.firstRound = true
    if gameData.spin then
        if gameData.spin.selfData then
            self.m_shopConfig.firstRound = gameData.spin.selfData.firstRound
        end
    end 
    self.m_isSuperFree = self.m_shopConfig.superFree
    self.m_initFreeTimes = gameData.gameConfig.extra.freeSpinTimes
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenEpicElephantMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "EpicElephant"  
end

function CodeGameScreenEpicElephantMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("CodeEpicElephantSrc.EpicElephantFreespinBarView",{machine = self})
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenEpicElephantMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end

    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:refreshInfo(self.m_runSpinResultData.p_selfMakeData.freeTiggerSignal,self.m_isSuperFree)
    util_nodeFadeIn(self.m_baseFreeSpinBar, 0.5, 0, 255, nil, function()
        if not self.m_isSuperFree then
            local chipNode = self.m_baseFreeSpinBar.m_free_bar:findChild("Node_1")
            local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
            nodePos = self:findChild("Node_guochang"):convertToNodeSpace(nodePos)
            util_changeNodeParent(self:findChild("Node_guochang"),chipNode)
            chipNode:setPosition(nodePos)
        end
    end)
end

-- 进入free玩法走过场的时候 需要隐藏base界面的部分显示
function CodeGameScreenEpicElephantMachine:hideBaseByFree( )
    
    self:findChild("Node_shuoming"):setVisible(false)
    self:findChild("Node_shouji"):setVisible(false)
    self:findChild("Node_gualan"):setVisible(false)

    self.m_jiaoSeBase:setVisible(false)
    self.m_jiaoSeFree:setVisible(true)

    self.m_isStopBaseIdle = true
    self.m_isStopFreeIdle = false

    self:playIdleBigJueSeFree()
end

function CodeGameScreenEpicElephantMachine:hideFreeSpinBar()
    
end

-- 退出free玩法走过场的时候 需要显示base界面的部分显示
function CodeGameScreenEpicElephantMachine:showBaseByFree( )
    if not self.m_baseFreeSpinBar then
        return
    end

    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    
    self:findChild("Node_shuoming"):setVisible(true)
    self:findChild("Node_shouji"):setVisible(true)
    self:findChild("Node_gualan"):setVisible(true)

    self.m_jiaoSeBase:setVisible(true)
    self.m_jiaoSeFree:setVisible(false)

    self.m_isStopBaseIdle = false
    self.m_isStopFreeIdle = true

    self:setReelBg(1)
    self:playIdleBigJueSe()
end

function CodeGameScreenEpicElephantMachine:initUI()
    --快滚音效
    self.m_reelRunSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_quickRun

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    --jackpot 只有grand
    self.m_jackpotBar = util_createView("CodeEpicElephantSrc.EpicElephantJackPotBarView",{machine = self})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
   
    --freespin次数收集条
    self.m_freeCollectBar = util_createView("CodeEpicElephantSrc.EpicElephantFreeCollectBar",{machine = self})
    self:findChild("Node_gualan"):addChild(self.m_freeCollectBar)

    --金币收集条
    self.m_coinCollectBar = util_createView("CodeEpicElephantSrc.EpicElephantCoinCollectBar",{machine = self})
    self:findChild("Node_shouji"):addChild(self.m_coinCollectBar)
    -- 更改 tip的层级
    local node = self.m_coinCollectBar.m_tip
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    pos = self:findChild("Node_guochang"):convertToNodeSpace(pos)
    util_changeNodeParent(self:findChild("Node_guochang"), self.m_coinCollectBar.m_tip)
    node:setPosition(pos.x, pos.y)
    
    --说明条
    self.m_explainBar = util_createView("CodeEpicElephantSrc.EpicElephantExplainBar",{machine = self})
    self:findChild("Node_shuoming"):addChild(self.m_explainBar)

    --商店界面
    self.m_shopView = util_createView("CodeEpicElephantShop.EpicElephantShopView",{machine = self})
    self:addChild(self.m_shopView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_shopView:setPosition(display.center)
    self.m_shopView:setScale(self.m_machineRootScale)

    -- 角色base
    self.m_jiaoSeBase = util_spineCreate("Socre_EpicElephant_juese",true,true)
    self:findChild("Node_juese_base"):addChild(self.m_jiaoSeBase)

    -- 角色free
    self.m_jiaoSeFree = util_spineCreate("Socre_EpicElephant_juese",true,true)
    self:findChild("Node_juese_free"):addChild(self.m_jiaoSeFree)
    self.m_jiaoSeFree:setVisible(false)

    -- 预告效果
    self.m_yugaoEffect = util_createAnimation("EpicElephant_yugao.csb")
    self:findChild("yugao"):addChild(self.m_yugaoEffect)
    self.m_yugaoEffect:setVisible(false)

    -- 过场动画
    self.m_guochang = util_spineCreate("Socre_EpicElephant_juese",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochang)
    self.m_guochang:setVisible(false)

    -- 棋盘遮罩
    self.m_qipanDark = util_createAnimation("EpicElephant_qipan_dark.csb")
    self:findChild("yugao"):addChild(self.m_qipanDark)
    self.m_qipanDark:setVisible(false)

    self:setReelBg(1)
    self:playIdleBigJueSe()

end

--设置棋盘的背景
-- _BgIndex 1bace 2free 3superfree
function CodeGameScreenEpicElephantMachine:setReelBg(_BgIndex)
    local nodeName = {"base_bg","free_bg","super_bg","super","free","base"}
    for i,vNode in ipairs(nodeName) do
        self.m_gameBg:findChild(vNode):setVisible(false)
    end
    if _BgIndex == 1 then
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("base"):resetSystem()
    elseif _BgIndex == 2 then
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self.m_gameBg:findChild("free"):setVisible(true)
        self.m_gameBg:findChild("free"):resetSystem()
    elseif _BgIndex == 3 then
        self.m_gameBg:findChild("super_bg"):setVisible(true)
        self.m_gameBg:findChild("super"):setVisible(true)
        self.m_gameBg:findChild("super"):resetSystem()
    end
end

-- 播放角色的idle动画 base 下
function CodeGameScreenEpicElephantMachine:playIdleBigJueSe( )
    if self.m_isStopBaseIdle then
        return
    end
    self.m_jiaoSeBase:setSkin("base")
    local actionName = {"idleframe","idleframe2","idleframe3"}
    local random = math.random(1,10)
    local actionNameCur = actionName[1]
    if random <= 6 then
        actionNameCur = actionName[1]
    elseif random <= 8 then
        actionNameCur = actionName[2]
    elseif random <= 10 then
        actionNameCur = actionName[3]
    end

    -- 如果是idleframe2 /3 后面在播放一遍idleframe
    util_spinePlay(self.m_jiaoSeBase, actionNameCur, false)
    util_spineEndCallFunc(self.m_jiaoSeBase, actionNameCur, function()
        if actionNameCur == "idleframe" then
            self:playIdleBigJueSe()
        else
            util_spinePlay(self.m_jiaoSeBase, "idleframe", false)
            util_spineEndCallFunc(self.m_jiaoSeBase, "idleframe", function()
                self:playIdleBigJueSe()
            end)
        end
    end)
end

-- 播放角色的idle动画 free 下
function CodeGameScreenEpicElephantMachine:playIdleBigJueSeFree( )
    if self.m_isStopFreeIdle then
        return
    end

    self.m_jiaoSeFree:setSkin("free")
    local actionName = {"idleframe","idleframe2","idleframe3"}
    local random = math.random(1,10)
    local actionNameCur = actionName[1]
    if random <= 6 then
        actionNameCur = actionName[1]
    elseif random <= 8 then
        actionNameCur = actionName[2]
    elseif random <= 10 then
        actionNameCur = actionName[3]
    end

    util_spinePlay(self.m_jiaoSeFree, actionNameCur, false)
    util_spineEndCallFunc(self.m_jiaoSeFree, actionNameCur, function()
        self:playIdleBigJueSeFree()
    end)
end

function CodeGameScreenEpicElephantMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound( self.m_publicConfig.SoundConfig.sound_EpicElephant_enterGame )

    end,0.4,self:getModuleName())
end

function CodeGameScreenEpicElephantMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenEpicElephantMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --刷新free次数收集栏
    self:refreshFreeTimesCollectBar()

    --刷新商店积分
    self:refreshShopScore(true)

    --superFree刷新固定图标
    if self.m_isSuperFree then
        self:refreshLockWild(nil, true)
    end

    if self:findChild("Node_shouji"):isVisible() then
        -- 打开提醒框
        self.m_coinCollectBar:showTip()
    end
end

function CodeGameScreenEpicElephantMachine:showShopView()
    --检测按钮是否可以点击
    if not self:collectBarClickEnabled() then
        return
    end

    self:setMaxMusicBGVolume( )

    self.m_shopView:showView()
end

---
-- 判断当前是否可点击
-- 商店玩法等滚动过程中不允许点击的接口
-- 返回true,允许点击
function CodeGameScreenEpicElephantMachine:collectBarClickEnabled()
    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    local bonusStates = self.m_runSpinResultData.p_bonusStatus or ""
    --

    if self.m_isWaitingNetworkData then
        return false
    elseif self:getGameSpinStage() ~= IDLE then
        return false
    elseif bonusStates == "OPEN" then
        return false
    elseif self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return false
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return false
    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then
        return false
    -- elseif self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
    --     return false
    elseif #featureDatas > 1 then
        return false
    elseif self.m_isRunningEffect then
        return false
    end

    return true
end

function CodeGameScreenEpicElephantMachine:addObservers()
    CodeGameScreenEpicElephantMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:refreshFreeTimesCollectBar()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount == 0 then
            else
                return
            end
        end

        --free触发不播连线声
        local featureLen = self.m_runSpinResultData.p_features or {}
        if #featureLen >= 2 then
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

        local soundName = nil
        if self.m_bProduceSlots_InFreeSpin then
            if self.m_isSuperFree then
                soundName = self.m_publicConfig.SoundConfig["sound_EpicElephant_superfree_winLine"..soundIndex] 
            else
                soundName = self.m_publicConfig.SoundConfig["sound_EpicElephant_free_winLine"..soundIndex] 
            end
        else
            soundName = self.m_publicConfig.SoundConfig["sound_EpicElephant_winLine"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenEpicElephantMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenEpicElephantMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_coinCollectBar.m_scheduleId then
        self.m_coinCollectBar:stopAction(self.m_coinCollectBar.m_scheduleId)
        self.m_coinCollectBar.m_scheduleId = nil
    end
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenEpicElephantMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_EpicElephant_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS_MINI then
        return "Socre_EpicElephant_Bonus_mini"
    end

    if symbolType == self.SYMBOL_BONUS_MINOR then
        return "Socre_EpicElephant_Bonus_minor"
    end

    if symbolType == self.SYMBOL_BONUS_MAJOR then
        return "Socre_EpicElephant_Bonus_major"
    end

    if symbolType == self.SYMBOL_BONUS_MEGA then
        return "Socre_EpicElephant_Bonus_mega"
    end

    if symbolType == self.SYMBOL_BONUS_WHEEL then
        return "Socre_EpicElephant_Bonus_wheel"
    end

    if symbolType == self.SYMBOL_WILD_FREE then
        return "Socre_EpicElephant_Wild_bonus"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_EpicElephant_10"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenEpicElephantMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenEpicElephantMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_MEGA,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_WHEEL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_FREE,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenEpicElephantMachine:MachineRule_initGame(  )
    
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:hideBaseByFree()
        if self.m_isSuperFree then
            --平均bet值 展示
            self.m_bottomUI:showAverageBet()

            self:setReelBg(3)
        else
            self:setReelBg(2)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenEpicElephantMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    local bonusNums = 0
    for iCol = 1, reelCol  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    bonusNums = bonusNums + 1
                end
            end
        end
    end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe2
        self:delayCallBack(0.1,function()
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == self.SYMBOL_BONUS then
                            -- 触发快停
                            if self.m_isQuicklyStop then
                                if bonusNums > 1 then
                                    targSp:runAnim("idleframe2",true)
                                else
                                    if targSp.p_cloumnIndex == 2 then
                                        targSp:runAnim("idleframe2",true)
                                    else
                                        targSp:runAnim("idleframe",true)
                                    end
                                end
                            else
                                targSp:runAnim("idleframe3",true)
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
                        if symbolType == self.SYMBOL_BONUS then
                            if bonusNums > 1 then
                                targSp:runAnim("idleframe2",true)
                            else
                                if targSp.p_cloumnIndex == 2 then
                                    targSp:runAnim("idleframe2",true)
                                else
                                    targSp:runAnim("idleframe",true)
                                end
                            end
                        end
                    end
                end
            end
        else
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == self.SYMBOL_BONUS then
                        if bonusNums > 1 then
                            targSp:runAnim("idleframe2",true)
                        else
                            if targSp.p_cloumnIndex == 2 then
                                targSp:runAnim("idleframe2",true)
                            else
                                targSp:runAnim("idleframe",true)
                            end
                        end
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
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenEpicElephantMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenEpicElephantMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 播放过场的时候 播放bonus图标的idleframe动画
function CodeGameScreenEpicElephantMachine:playBonusIdleByGuoChang( )
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    node:runAnim("idleframe2",true)
                end
            end
        end
    end
end
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenEpicElephantMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freeMore_start)

            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self:playBonusIdleByGuoChang()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                if self.m_isSuperFree then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespin_guochang)
                else
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freespin_guochang)
                end

                self:playGuoChangBaseAndFree(function()
                    if self.m_isSuperFree then
                        --平均bet值 展示
                        self.m_bottomUI:showAverageBet()

                        self:setReelBg(3)
                    else
                        self:setReelBg(2)
                    end
                    self:hideBaseByFree()
                    self:playBonusIdleByGuoChang()
                end,function()
                    self:triggerFreeSpinCallFun()

                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

-- 过场动画
function CodeGameScreenEpicElephantMachine:playGuoChangBaseAndFree(func1, func2)
    self.m_guochang:setVisible(true)
    self.m_guochang:setSkin("guochang")
    util_spinePlay(self.m_guochang, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_guochang, "actionframe_guochang", function()
        self.m_guochang:setVisible(false)
    end)

    self:delayCallBack(40/30,function()
        if func1 then
            func1()
        end
    end)

    self:delayCallBack(95/30,function()
        if func2 then
            func2()
        end
    end)
end

function CodeGameScreenEpicElephantMachine:isBonus(symbolType)
    if symbolType == self.SYMBOL_BONUS_MINI or 
        symbolType == self.SYMBOL_BONUS_MINOR or 
        symbolType == self.SYMBOL_BONUS_MAJOR or 
        symbolType == self.SYMBOL_BONUS_MEGA or 
        symbolType == self.SYMBOL_WILD_FREE or 
        symbolType == self.SYMBOL_BONUS_WHEEL then
        return true
    end
    return false
end
---
-- 显示free spin
function CodeGameScreenEpicElephantMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData

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

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end

    if scatterLineValue ~= nil then
        --
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end

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
    else
        local delayTime = 72/30
        local curNodeList = {}--存储临时节点
        local curNewNodeList = {}--存储新的临时节点

        if (fsExtraData.freeType == "WHEELFREESPIN" or self.m_isSuperFree) and self.m_runSpinResultData.p_freeSpinNewCount <= 0 then
            delayTime = 0
        else
            for iCol = 1, self.m_iReelColumnNum  do
                for iRow = 1, self.m_iReelRowNum do
                    local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if node then
                        local symbolType = node.p_symbolType
                        if symbolType == self.SYMBOL_BONUS then
                            node:runAnim("start",false,function()
                                node:runAnim("actionframe2",false,function()
                                    -- node:runAnim("idleframe2",true)
                                end)
                            end)
                            table.insert(curNodeList, node)
                            node:setVisible(false)
                            local newNode = self:createCurNewNode(node, symbolType)
                            table.insert(curNewNodeList, newNode)
                            
                            util_spinePlay(newNode, "start", false)
                            util_spineEndCallFunc(newNode, "start", function()
                                util_spinePlay(newNode, "actionframe2", false)
                            end)
                        end
                        if self:isBonus(symbolType) then
                            node:setVisible(false)

                            local newNode = self:createCurNewNode(node, symbolType)
                            table.insert(curNewNodeList, newNode)
                            
                            if symbolType == self.SYMBOL_WILD_FREE then
                                util_spinePlay(newNode, "idleframe", false)
                            else
                                util_spinePlay(newNode, "idleframe2", false)
                            end

                            self:delayCallBack(12/30,function()
                                node:runAnim("actionframe2",false,function()
                                    -- node:runAnim("idleframe2",true)
                                end)
                                self.m_freeCollectBar:playTriEffect(symbolType)
                                table.insert(curNodeList, node)
                                
                                util_spinePlay(newNode, "actionframe2", false)
                            end)
            
                            -- self.m_jiaoSeBase:setSkin("base")
                            -- util_spinePlay(self.m_jiaoSeBase, "actionframe", false)
                            -- util_spineEndCallFunc(self.m_jiaoSeBase, "actionframe", function()
                            --     self:playIdleBigJueSe()
                            -- end)
                          
                        end
                    end
                end
            end
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freeMore_trigger)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_bonusTrigger)
                -- 播放震动
                if self.levelDeviceVibrate then
                    self:levelDeviceVibrate(6, "free")
                end
            end

            self.m_qipanDark:setVisible(true)
            self.m_qipanDark:runCsbAction("start",false,function()
                self.m_qipanDark:runCsbAction("idle",false)
            end)
        end
        
        self:delayCallBack(delayTime,function()
            self:showFreeSpinView(effectData)
            self.m_qipanDark:runCsbAction("over",false,function()
                self.m_qipanDark:setVisible(false)
                for i,vNode in ipairs(curNodeList) do
                    vNode:setVisible(true)
                end

                for i,vNode in ipairs(curNewNodeList) do
                    vNode:removeFromParent()
                end
            end)
            
        end)
        
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenEpicElephantMachine:createCurNewNode(startNode,symbolType)
    local nodeSpineName = self:MachineRule_GetSelfCCBName(symbolType)
    
    local node = util_spineCreate(nodeSpineName,true,true)
    local startWorldPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos = self:findChild("Node_guochang"):convertToNodeSpace(startWorldPos)
    self:findChild("Node_guochang"):addChild(node, 200)
    node:setPosition(startPos)
    return node
end

function CodeGameScreenEpicElephantMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local csbName = BaseDialog.DIALOG_TYPE_FREESPIN_START

    --触发类型
    local triggerType = self.m_runSpinResultData.p_selfMakeData.freeTiggerSignal

    if self.m_isSuperFree then
        csbName = "FreeSpinStart_2"
    elseif triggerType >= self.SYMBOL_BONUS_MINI and triggerType <= self.SYMBOL_BONUS_MEGA then
        csbName = "FreeSpinStart_1"
        ownerlist["m_lb_num_1"] = self:getLockWildNum(triggerType)
    elseif triggerType >= 95 and triggerType <= 97 then --95为1列wild,96为2列,97为3列
        csbName = "FreeSpinStart_3"
        ownerlist["m_lb_num_1"] = self:getLockWildNum(triggerType)
    end

    local view
    if isAuto then
        view = self:showDialog(csbName, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(csbName, ownerlist, func)
        if self.m_isSuperFree then
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_click
            view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespin_over
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespin_start)
        else
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_click
            view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_freespin_over
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freespin_start)
        end
    end

    if self.m_isSuperFree then
        local wildType = util_createAnimation("EpicElephant_superwild.csb")
        view:findChild("Node_superwild"):addChild(wildType)
        local superFreeType = self.m_runSpinResultData.p_selfMakeData.superFreeType + 1
        for index = 1,5 do
            wildType:findChild("Node_"..index):setVisible(index == superFreeType)
        end
    elseif triggerType >= self.SYMBOL_BONUS_MINI and triggerType <= self.SYMBOL_BONUS_MEGA then
        view:findChild("mini"):setVisible(triggerType == self.SYMBOL_BONUS_MINI)
        view:findChild("minor"):setVisible(triggerType == self.SYMBOL_BONUS_MINOR)
        view:findChild("major"):setVisible(triggerType == self.SYMBOL_BONUS_MAJOR)
        view:findChild("mega"):setVisible(triggerType == self.SYMBOL_BONUS_MEGA)
    end
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    获取固定wild的列数
]]
function CodeGameScreenEpicElephantMachine:getLockWildNum(triggerType)
    --95为1列wild,96为2列,97为3列
    if triggerType == self.SYMBOL_BONUS_MINI or triggerType == 95 then
        return 1
    elseif triggerType == self.SYMBOL_BONUS_MINOR or triggerType == 96 then
        return 2
    elseif triggerType == self.SYMBOL_BONUS_MAJOR or triggerType == self.SYMBOL_BONUS_MEGA or triggerType == 97 then
        return 3
    end

    return 0
end

function CodeGameScreenEpicElephantMachine:showFreeSpinOverView()

   --重置superfree状态
   self:refreshFreeTimesCollectBar()

    if globalData.slotRunData.lastWinCoin == 0 then
        self:clearCurMusicBg()
        local view = self:showDialog("FreeSpinOver_0", {}, function()
            if self.m_isSuperFree then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespinOver_guochang)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freespinOver_guochang)
                util_changeNodeParent(self.m_baseFreeSpinBar.m_free_bar:findChild("Node_teshu"),self.m_baseFreeSpinBar.m_free_bar:findChild("Node_1"))
                self.m_baseFreeSpinBar.m_free_bar:findChild("Node_1"):setPosition(cc.p(0,0))
            end

            self:playGuoChangBaseAndFree(function()
                self:showBaseByFree()
                self:playBonusIdleByGuoChang()
                if self.m_isSuperFree then
                    --平均bet值 隐藏
                    self.m_bottomUI:hideAverageBet()
                end
            end,function()
                
                if self.m_isSuperFree then
                    self.m_fsReelDataIndex = 0
                    -- 添加superfreespin effect back
                    local superfreeSpinEffect = GameEffectData.new()
                    superfreeSpinEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    superfreeSpinEffect.p_effectOrder = self.SUPER_FREE_BACK_OPENSHOP_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = superfreeSpinEffect
                    superfreeSpinEffect.p_selfEffectType = self.SUPER_FREE_BACK_OPENSHOP_EFFECT -- 动画类型           
                end
                self.m_isSuperFree = false
                
                self:triggerFreeSpinOverCallFun()
            end)
        end)
        view:findChild("root"):setScale(self.m_machineRootScale)
    else
        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
        local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            if self.m_isSuperFree then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespinOver_guochang)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freespinOver_guochang)
                util_changeNodeParent(self.m_baseFreeSpinBar.m_free_bar:findChild("Node_teshu"),self.m_baseFreeSpinBar.m_free_bar:findChild("Node_1"))
                self.m_baseFreeSpinBar.m_free_bar:findChild("Node_1"):setPosition(cc.p(0,0))
            end

            self:playGuoChangBaseAndFree(function()
                self:showBaseByFree()
                self:playBonusIdleByGuoChang()
                if self.m_isSuperFree then
                    --平均bet值 隐藏
                    self.m_bottomUI:hideAverageBet()
                end
            end,function()

                if self.m_isSuperFree then
                    -- 添加superfreespin effect back
                    local superfreeSpinEffect = GameEffectData.new()
                    superfreeSpinEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    superfreeSpinEffect.p_effectOrder = self.SUPER_FREE_BACK_OPENSHOP_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = superfreeSpinEffect
                    superfreeSpinEffect.p_selfEffectType = self.SUPER_FREE_BACK_OPENSHOP_EFFECT -- 动画类型           
                end
                self.m_isSuperFree = false

                self:triggerFreeSpinOverCallFun()
                
            end)
        end)
        view:findChild("root"):setScale(self.m_machineRootScale)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.83,sy=0.83},865)
    end
end

function CodeGameScreenEpicElephantMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = nil
    if self.m_isSuperFree then
        --清理固定图标
        self:clearLockWild()
        view = self:showDialog("SuperFreeSpinOver", ownerlist, func)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespinover_over
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superfreespinover_start)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_EpicElephant_freespinOver_over
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_freespinOver_start)
    end

    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenEpicElephantMachine:beginReel()
    --开始滚动时显示全屏wild
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_isShowAllWild = true
    end

    --superfree显示固定wild
    if self.m_isSuperFree then
        self.m_fsReelDataIndex = 1
        for i,ani in ipairs(self.m_lockWilds) do
            ani:setVisible(true)
        end
    end

    self.m_isStopQuickGun = false
    self.m_isQuicklyStop = false
    self.m_isPlayBulingSound = true
    self.m_isShowJiaoBiao = true

    CodeGameScreenEpicElephantMachine.super.beginReel(self)

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenEpicElephantMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   
    if self.m_coinCollectBar.m_scheduleId then
        self.m_coinCollectBar:hideTip()
    end

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenEpicElephantMachine:addSelfEffect()
    --收集商店积分
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.score then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_SHOP_SCORE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_SHOP_SCORE_EFFECT -- 动画类型
    end

    --bonus特殊图标只在第四列出现,且只会出现一个
    for iRow = 1,self.m_iReelRowNum do
        local reels = self.m_runSpinResultData.p_reels
        if reels and reels[iRow] then
            local symbolType = reels[iRow][4]
            if symbolType >= self.SYMBOL_BONUS_MINI and symbolType <= self.SYMBOL_BONUS_MEGA then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.COLLECT_FREE_TIMES_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.COLLECT_FREE_TIMES_EFFECT -- 动画类型
                selfEffect.symbolType = symbolType
                break
            end
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenEpicElephantMachine:MachineRule_playSelfEffect(effectData)
    --收集free次数
    if effectData.p_selfEffectType == self.COLLECT_FREE_TIMES_EFFECT then

        self:collectFreeTimesEffect(effectData)

    elseif effectData.p_selfEffectType == self.COLLECT_SHOP_SCORE_EFFECT then --收集商店积分
        
        self:collectShopScoreEffect(effectData)
        
    elseif effectData.p_selfEffectType == self.SUPER_FREE_BACK_OPENSHOP_EFFECT then
        local isSuperFreeBack = false
    
        if self.m_shopConfig.firstRound then
            isSuperFreeBack = true
        end
        self.m_shopView:showView(isSuperFreeBack)

        effectData.p_isPlay = true
        self:playGameEffect()
    end
    return true
end

-- 收集free玩法次数的动画
function CodeGameScreenEpicElephantMachine:collectFreeTimesEffect(effectData)
    local symbolNode
    for iRow = 1,self.m_iReelRowNum do
        local tempNode = self:getFixSymbol(4,iRow)
        if tempNode and tempNode.p_symbolType == effectData.symbolType then
            symbolNode = tempNode
            break
        end
    end

    local endFunc = function(symbolType)
        local jindutiaoEffect = util_createAnimation("EpicElephant_jindutiao.csb")
        local jindutiaoNode = {"mega", "major", "minor", "mini"}
        for i=1,4 do
            jindutiaoEffect:findChild(jindutiaoNode[i]):setVisible(false)
        end

        local node = nil
        local nodeName = nil
        if symbolType == self.SYMBOL_BONUS_MINI then
            node = self.m_freeCollectBar:findChild("Node_mini")
            jindutiaoEffect:findChild("mini"):setVisible(true)
            nodeName = "mini"
        elseif symbolType == self.SYMBOL_BONUS_MINOR then
            node = self.m_freeCollectBar:findChild("Node_minor")
            jindutiaoEffect:findChild("minor"):setVisible(true)
            nodeName = "minor"
        elseif symbolType == self.SYMBOL_BONUS_MAJOR then
            node = self.m_freeCollectBar:findChild("Node_major")
            jindutiaoEffect:findChild("major"):setVisible(true)
            nodeName = "major"
        elseif symbolType == self.SYMBOL_BONUS_MEGA then
            node = self.m_freeCollectBar:findChild("Node_mega")
            jindutiaoEffect:findChild("mega"):setVisible(true)
            nodeName = "mega"
        end
        node:addChild(jindutiaoEffect)

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_teshu_bonusShouji_fankui)

        jindutiaoEffect:runCsbAction("actionframe",false, function()
            jindutiaoEffect:removeFromParent()
        end)

        effectData.p_isPlay = true
        self:playGameEffect()

        self:refreshFreeTimesCollectBar(nodeName)

        -- 收集动画播完之后 播放棋盘上的idle动画
        symbolNode:runAnim("idleframe2",true)
    end

    --存在小块,执行收集动画
    if symbolNode then
        local endNode = self.m_freeCollectBar
        if effectData.symbolType == self.SYMBOL_BONUS_MINI then
            endNode = self.m_freeCollectBar:findChild("mini")
        elseif effectData.symbolType == self.SYMBOL_BONUS_MINOR then
            endNode = self.m_freeCollectBar:findChild("minor")
        elseif effectData.symbolType == self.SYMBOL_BONUS_MAJOR then
            endNode = self.m_freeCollectBar:findChild("Major")
        elseif effectData.symbolType == self.SYMBOL_BONUS_MEGA then
            endNode = self.m_freeCollectBar:findChild("Mega")
        end
        self:delayCallBack(15/30,function()
            self:flyCollectFreeTimes(effectData.symbolType,symbolNode,endNode,endFunc)
        end)
    else
        endFunc()
    end
end

-- 收集商店金币的动画
function CodeGameScreenEpicElephantMachine:collectShopScoreEffect(effectData)
    local score = 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end

    -- 收集的同时 还有别的事件的话 等收集完在播其他的
    local isDelayPlay = false
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN or effectData.p_effectType == GameEffect.EFFECT_BONUS then
            isDelayPlay = true
        end
    end

    local isFirst = true
    local isPlayYinXiao = true
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.m_scoreItem and symbolNode.m_scoreItem.score > 0 then
                symbolNode.m_scoreItem:setVisible(false)
                self:flyCollectShopScore(symbolNode.m_scoreItem.score,symbolNode.m_scoreItem,self.m_coinCollectBar:findChild("Node_baozha"),function()
                    if isFirst then
                        isFirst = false
                        local flyNodeBaoZha = util_createAnimation("EpicElephant_jindutiao.csb")
                        self.m_coinCollectBar:findChild("Node_baozha"):addChild(flyNodeBaoZha)
                        flyNodeBaoZha:runCsbAction("actionframe1",false,function()
                            flyNodeBaoZha:removeFromParent()
                        end)
                        --刷新商店积分
                        self.m_coinCollectBar:updateCoins(score)

                        if isDelayPlay then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end,isPlayYinXiao)
                if isPlayYinXiao then
                    isPlayYinXiao = false
                end
            end
        end
    end

    if not isDelayPlay then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end
--[[
    收集free次数动画
]]
function CodeGameScreenEpicElephantMachine:flyCollectFreeTimes(symbolType,startNode,endNode,func)
    local csbName = self:getSymbolCCBNameByType(self,symbolType)
    local flyNode = util_spineCreate(csbName,true,true)

    local flyNodeTuoWei = util_createAnimation("EpicElephant_bonus_fly.csb")
    self.m_effectNode:addChild(flyNodeTuoWei,1)
    
    if flyNodeTuoWei:findChild("jiaobiao") then
        flyNodeTuoWei:findChild("jiaobiao"):setVisible(false)
    end
    local nodeName = {"mini", "minor", "mejor", "mega"}
    for i,v in ipairs(nodeName) do
        if flyNodeTuoWei:findChild(v) then
            flyNodeTuoWei:findChild(v):setVisible(false)
        end
    end
    
    if flyNodeTuoWei:findChild(nodeName[symbolType-100]) then
        flyNodeTuoWei:findChild(nodeName[symbolType-100]):setVisible(true)
        flyNodeTuoWei:findChild(nodeName[symbolType-100]):setDuration(1)     --设置拖尾时间(生命周期)
        flyNodeTuoWei:findChild(nodeName[symbolType-100]):setPositionType(0)   --设置可以拖尾
    end

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode,100)
    flyNode:setPosition(startPos)
    flyNodeTuoWei:setPosition(startPos)
    util_spinePlay(flyNode, "shouji", false)

    self:delayCallBack(7/30,function()
        local seq = cc.Sequence:create({
            cc.MoveTo:create(13/30,endPos),
            cc.CallFunc:create(function()
                if type(func) == "function" then
                    func(symbolType)
                end
            end),
            cc.RemoveSelf:create(true)
        })
    
        flyNode:runAction(seq)

        local seq1 = cc.Sequence:create({
            cc.MoveTo:create(13/30,endPos),
            cc.CallFunc:create(function()
                self:delayCallBack(0.5, function()
                    flyNodeTuoWei:removeFromParent()
                end)
            end),
        })
    
        flyNodeTuoWei:runAction(seq1)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_teshu_bonusShouji)
    end)
    
end

--[[
    收集商店积分
]]
function CodeGameScreenEpicElephantMachine:flyCollectShopScore(score,startNode,endNode,func,isPlayYinXiao)
    local flyNode = util_createAnimation("EpicElephant_coin.csb")
    flyNode:findChild("m_lb_coins"):setString(score)

    local flyNodeTuoWei = util_createAnimation("EpicElephant_bonus_fly.csb")
    flyNode:addChild(flyNodeTuoWei,-1)
    if flyNodeTuoWei:findChild("mega") then
        flyNodeTuoWei:findChild("mega"):setVisible(false)
    end
    if flyNodeTuoWei:findChild("mejor") then
        flyNodeTuoWei:findChild("mejor"):setVisible(false)
    end
    if flyNodeTuoWei:findChild("mini") then
        flyNodeTuoWei:findChild("mini"):setVisible(false)
    end
    if flyNodeTuoWei:findChild("minor") then
        flyNodeTuoWei:findChild("minor"):setVisible(false)
    end

    if flyNodeTuoWei:findChild("jiaobiao") then
        flyNodeTuoWei:findChild("jiaobiao"):setDuration(1)     --设置拖尾时间(生命周期)
        flyNodeTuoWei:findChild("jiaobiao"):setPositionType(0)   --设置可以拖尾
    end

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    flyNode:runCsbAction("shouji",false)
    self:delayCallBack(22/60,function()
        local seq = cc.Sequence:create({
            cc.MoveTo:create(20/60,endPos),
            cc.CallFunc:create(function()

                flyNode:findChild("Node_tishi"):setVisible(false)
                self:delayCallBack(15/60, function()
                    flyNode:removeFromParent()
                end)

                if type(func) == "function" then
                    func()
                end
            end),
        })
    
        flyNode:runAction(seq)
        if isPlayYinXiao then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_jiaobiao_fankui)
        end
    end)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenEpicElephantMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenEpicElephantMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenEpicElephantMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenEpicElephantMachine:slotReelDown( )

    if #self.m_lockWilds > 0 then
        for i,ani in ipairs(self.m_lockWilds) do
            ani:setVisible(false)
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenEpicElephantMachine.super.slotReelDown(self)
end

function CodeGameScreenEpicElephantMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenEpicElephantMachine:updateReelGridNode(symbolNode)
    if symbolNode.m_scoreItem then
        symbolNode.m_scoreItem:setVisible(false)
        symbolNode.m_scoreItem.score = 0
    end

    -- 收集玉米相关
    if symbolNode:isLastSymbol() and self.m_isShowJiaoBiao then
        local reelsIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.score then
            local collectScore = selfData.score[reelsIndex + 1]
            if collectScore and collectScore > 0 then
                
                --创建积分角标
                if not symbolNode.m_scoreItem then
                    symbolNode.m_scoreItem =  util_createAnimation("EpicElephant_coin.csb")
                    symbolNode:addChild(symbolNode.m_scoreItem,1000)
                    local symbolSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH)
                    local size = symbolNode.m_scoreItem:findChild('di'):getContentSize()
                    local scale = symbolNode.m_scoreItem:findChild('di'):getScale()
                    size.width = size.width * scale
                    size.height = size.height * scale
                    symbolNode.m_scoreItem:setPosition(cc.p(symbolSize.width / 2 - size.width / 2,-symbolSize.height / 2 + size.height / 2))
                end
                symbolNode.m_scoreItem:setVisible(true)
                symbolNode.m_scoreItem.score = collectScore
                symbolNode.m_scoreItem:findChild("m_lb_coins"):setString(collectScore)
            end
        end
    end
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenEpicElephantMachine:showEffect_Bonus(effectData)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    self:clearCurMusicBg()

    local symbolNode = nil
    local curNodeList = {}--存储临时节点
    local curNewNodeList = {}--存储新的临时节点

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_bonusTrigger)

    --播放触发动画
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    node:runAnim("start",false,function()
                        node:runAnim("actionframe2",false,function()
                            -- node:runAnim("idleframe2",true)
                        end)
                    end)
                    table.insert(curNodeList, node)
                    node:setVisible(false)
                    local newNode = self:createCurNewNode(node, symbolType)
                    table.insert(curNewNodeList, newNode)
                    
                    util_spinePlay(newNode, "start", false)
                    util_spineEndCallFunc(newNode, "start", function()
                        util_spinePlay(newNode, "actionframe2", false)
                    end)
                end
                if self:isBonus(symbolType) then
                    symbolNode = node
                    node:setVisible(false)

                    local newNode = self:createCurNewNode(node, symbolType)
                    -- table.insert(curNewNodeList, newNode)
                    
                    util_spinePlay(newNode, "idleframe2", false)

                    self:delayCallBack(12/30,function()
                        node:runAnim("actionframe2",false,function()
                            node:runAnim("start",false,function()
                                node:runAnim("idleframe2",true)
                            end)
                            self.m_qipanDark:runCsbAction("over",false,function()
                                self.m_qipanDark:setVisible(false)
                                for i,vNode in ipairs(curNodeList) do
                                    vNode:setVisible(true)
                                end
                    
                                for i,vNode in ipairs(curNewNodeList) do
                                    vNode:removeFromParent()
                                end
                            end)
                            newNode:setVisible(false)
                            self:createNewBonusWheel(node, symbolNode)
                        end)
                        util_spinePlay(newNode, "actionframe2", false)
                        self.m_freeCollectBar:playTriEffect(symbolType)

                        -- table.insert(curNodeList, node)

                        -- self.m_jiaoSeBase:setSkin("base")
                        -- util_spinePlay(self.m_jiaoSeBase, "actionframe", false)
                        -- util_spineEndCallFunc(self.m_jiaoSeBase, "actionframe", function()
                        --     self:playIdleBigJueSe()
                        -- end)
                    end)
                end
            end
        end
    end

    self.m_qipanDark:setVisible(true)
    self.m_qipanDark:runCsbAction("start",false,function()
        self.m_qipanDark:runCsbAction("idle",false)
    end)

    self:delayCallBack(79/30,function()
        
        self:resetMusicBg(false,"EpicElephantSounds/music_EpicElephant_wheel.mp3")

        --显示转盘
        local view = util_createView("CodeEpicElephantSrc.EpicElephantWheelView",{machine = self,callBack = function(featureData)

            self:clearCurMusicBg()
            self.m_runSpinResultData:parseResultData(featureData, self.m_lineDataPool)

            if featureData.features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
                --添加freespin事件
                self:addFreeEffect()

                effectData.p_isPlay = true
                self:playGameEffect()
            else
                globalData.slotRunData.lastWinCoin = featureData.winAmount
                if not self:checkHasBigWin() then
                    --检测大赢
                    self:checkFeatureOverTriggerBigWin(featureData.winAmount, GameEffect.EFFECT_BONUS)
                end
                --显示grand
                self:showJackpotWin(featureData.winAmount,function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end
            
        end})

        self:findChild("root"):addChild(view, 100)
    end)

    return true
end

function CodeGameScreenEpicElephantMachine:createNewBonusWheel(startNode, symbolNode)
    local bonusWheel = util_spineCreate("Socre_EpicElephant_Bonus_wheel",true,true)
    local startWorldPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos = self:findChild("root"):convertToNodeSpace(startWorldPos)
    self:findChild("root"):addChild(bonusWheel, 200)
    bonusWheel:setPosition(startPos)

    util_spinePlay(bonusWheel, "start", false)

    local seq1 = cc.Sequence:create({
        cc.MoveTo:create(7/30,cc.p(0, 0)),
        cc.CallFunc:create(function()
            
        end),
    })

    bonusWheel:runAction(seq1)

    self:delayCallBack(31/30,function()
        bonusWheel:removeFromParent()

        if symbolNode then
            symbolNode:setVisible(true)
        end
    end)
end

--[[
    jackpot弹板
]]
function CodeGameScreenEpicElephantMachine:showJackpotWin(coins,func)
    self:clearCurMusicBg()
    self.m_jackpotBar:runCsbAction("actionframe3",false,function()
        self.m_jackpotBar:runCsbAction("idle",true)
    end)

    local view = util_createView("CodeEpicElephantSrc.EpicElephantJackPotWinView",{
        machine = self,
        winCoin = coins,
        func = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            if type(func) == "function" then
                func()
            end
        end
    })
    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalViewManager:showUI(view)
end

--随机信号
function CodeGameScreenEpicElephantMachine:getReelSymbolType(parentData)
    if self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isSuperFree then
        -- if self.m_runSpinResultData.p_fsExtraData.freeType == "WHEELFREESPIN" and (self.m_runSpinResultData.p_selfMakeData.freeTiggerSignal == 94 or 
        -- self.m_runSpinResultData.p_selfMakeData.freeTiggerSignal == 95 or self.m_runSpinResultData.p_selfMakeData.freeTiggerSignal == 96 or 
        -- self.m_runSpinResultData.p_selfMakeData.freeTiggerSignal == 97) then
        -- else
            if self.m_isShowAllWild then
                return TAG_SYMBOL_TYPE.SYMBOL_WILD
            end
            local lockWildCol = self.m_runSpinResultData.p_fsExtraData.wildColumns or {}
            for i,colIndex in ipairs(lockWildCol) do
                if parentData.cloumnIndex == colIndex + 1 then
                    return TAG_SYMBOL_TYPE.SYMBOL_WILD
                end
            end
        -- end
    end
    

    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

--[[
    延迟回调
]]
function CodeGameScreenEpicElephantMachine:delayCallBack(time, func)
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
    刷新freespin次数收集栏
]]
function CodeGameScreenEpicElephantMachine:refreshFreeTimesCollectBar(isScaleName)

    local curTotalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())

    local freeTimes = self.m_initFreeTimes
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.oldFreeSpinConfig and selfData.oldFreeSpinConfig[tostring(curTotalBet)] then
        freeTimes = selfData.oldFreeSpinConfig[tostring(curTotalBet)]
    elseif selfData and selfData.freeSpinConfig and selfData.freeSpinConfig[tostring(curTotalBet)] then
        freeTimes = selfData.freeSpinConfig[tostring(curTotalBet)]
    end

    if not freeTimes then
        return
    end

    self.m_freeCollectBar:refreshCount(freeTimes, isScaleName)
end

--[[
    刷新商店积分
]]
function CodeGameScreenEpicElephantMachine:refreshShopScore(isReConnect)
    local score = 0
    if isReConnect then
        score = self.m_shopConfig.coins or 0
    elseif self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end

    self.m_coinCollectBar:updateCoins(score)
end

--[[
    添加freespin
]]
function CodeGameScreenEpicElephantMachine:addFreeEffect()
    -- 添加freespin effect
    local freeSpinEffect = GameEffectData.new()
    freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
    freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

    --手动添加freespin次数
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
end

--[[
    触发superfree
]]
function CodeGameScreenEpicElephantMachine:triggerSuperFree()
    self.m_isSuperFree = true
    --添加free事件
    self:addFreeEffect()
    
    self:playGameEffect()
end

--[[
    刷新固定图标
]]
function CodeGameScreenEpicElephantMachine:refreshLockWild(func, isDuanXian)
    --已经创建好了,不需要二次创建
    if #self.m_lockWilds > 0 then
        return
    end

    local superFreeType = self.m_runSpinResultData.p_selfMakeData.superFreeType
    if not superFreeType then
        return
    end
    local wildConfig = self.m_shopConfig.shopWildConfig[tostring(superFreeType)]
    if not isDuanXian then
        -- self.m_yugaoEffect:setVisible(true)
        -- self.m_yugaoEffect:runCsbAction("actionframe_yugao",false,function()
        --     self.m_yugaoEffect:setVisible(false)
        -- end) 

        -- self:delayCallBack(15/60,function()
            --创建wild图标
            local isPlaySound = true
            for i,posIndex in ipairs(wildConfig) do
                -- local pos = self:getRowAndColByPos(posIndex)
                -- local iCol,iRow = pos.iY,pos.iX

                local pos = util_getOneGameReelsTarSpPos(self,posIndex ) 
                local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
                local nodePos = self:findChild("yugao"):convertToNodeSpace(worldPos)

                --后期会换成spine
                -- local wildAni = util_createAnimation("Socre_EpicElephant_Wild.csb")
                local wildAni = util_spineCreate("Socre_EpicElephant_Wild",true,true)
                self:findChild("yugao"):addChild(wildAni, -1)
                wildAni:setPosition(nodePos)
                if isDuanXian then
                    util_spinePlay(wildAni, "idleframe", false)
                    wildAni:setVisible(false)
                else
                    util_spinePlay(wildAni, "switch_suoding", false)
                    if isPlaySound then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superFG_start)
                    end
                    isPlaySound = false
                end
                
                self.m_lockWilds[#self.m_lockWilds + 1] = wildAni
                -- 
            end
        -- end)
    else
        local isPlaySound = true
        --创建wild图标
        for i,posIndex in ipairs(wildConfig) do
            -- local pos = self:getRowAndColByPos(posIndex)
            -- local iCol,iRow = pos.iY,pos.iX

            local pos = util_getOneGameReelsTarSpPos(self,posIndex ) 
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
            local nodePos = self:findChild("yugao"):convertToNodeSpace(worldPos)

            --后期会换成spine
            -- local wildAni = util_createAnimation("Socre_EpicElephant_Wild.csb")
            local wildAni = util_spineCreate("Socre_EpicElephant_Wild",true,true)
            self:findChild("yugao"):addChild(wildAni, -1)
            wildAni:setPosition(nodePos)
            if isDuanXian then
                util_spinePlay(wildAni, "idleframe", false)
                wildAni:setVisible(false)
            else
                util_spinePlay(wildAni, "switch_suoding", false)
                if isPlaySound then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_superFG_start)
                end
                isPlaySound = false
            end
            
            self.m_lockWilds[#self.m_lockWilds + 1] = wildAni
            -- 
        end
    end
    
    if func then
        self:delayCallBack(35/30,function()
            func()
        end)
    end
end

--[[
    清空固定图标
]]
function CodeGameScreenEpicElephantMachine:clearLockWild()
    for i,wildAni in ipairs(self.m_lockWilds) do
        wildAni:removeFromParent()
    end
    self.m_lockWilds = {}
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenEpicElephantMachine:playCustomSpecialSymbolDownAct( node)
    CodeGameScreenEpicElephantMachine.super.playCustomSpecialSymbolDownAct(self, node )

    local bonusNum = 0
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    bonusNum = bonusNum + 1
                end
            end
        end
    end

    if node then
        if node.m_scoreItem and node.m_scoreItem:isVisible() then
            -- node.m_scoreItem:runCsbAction("buling",false,function()
                node.m_scoreItem:runCsbAction("idleframe",true)
            -- end)
        end

        if node.p_symbolType == self.SYMBOL_BONUS or 
        node.p_symbolType == self.SYMBOL_BONUS_MINI or 
        node.p_symbolType == self.SYMBOL_BONUS_MINOR or 
        node.p_symbolType == self.SYMBOL_BONUS_MAJOR or 
        node.p_symbolType == self.SYMBOL_BONUS_MEGA or 
        node.p_symbolType == self.SYMBOL_WILD_FREE or 
        node.p_symbolType == self.SYMBOL_BONUS_WHEEL then 
            
            if node.p_cloumnIndex == 4 and (node.p_symbolType == self.SYMBOL_BONUS_MINI or 
            node.p_symbolType == self.SYMBOL_BONUS_MINOR or 
            node.p_symbolType == self.SYMBOL_BONUS_MAJOR or 
            node.p_symbolType == self.SYMBOL_BONUS_MEGA) then
                --修改小块层级
                local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType,node.p_cloumnIndex*10)

                symbolNode:runAnim("buling",false,function()
                    if node.p_symbolType == self.SYMBOL_BONUS or 
                    node.p_symbolType == self.SYMBOL_WILD_FREE or 
                    node.p_symbolType == self.SYMBOL_BONUS_WHEEL then 
                        symbolNode:runAnim("idleframe2",true)
                    end
                end)
            else
                if node.p_cloumnIndex >= 3 and bonusNum < 2 then
                    return
                end

                --修改小块层级
                local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType,node.p_cloumnIndex*10)

                symbolNode:runAnim("buling",false,function()
                    if node.p_symbolType == self.SYMBOL_BONUS or 
                    node.p_symbolType == self.SYMBOL_WILD_FREE or 
                    node.p_symbolType == self.SYMBOL_BONUS_WHEEL then 
                        symbolNode:runAnim("idleframe2",true)
                    end
                end)
            end

            if self.m_isPlayBulingSound then
                if node.p_symbolType == self.SYMBOL_BONUS then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_bonusBuling)
                else
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_teshu_bonusBuling)
                end
            end

            if self.m_isQuicklyStop then
                self.m_isPlayBulingSound = false
            end
            
        end
        if node.p_symbolType == self.SYMBOL_BONUS_MINI or 
        node.p_symbolType == self.SYMBOL_BONUS_MINOR or 
        node.p_symbolType == self.SYMBOL_BONUS_MAJOR or 
        node.p_symbolType == self.SYMBOL_BONUS_MEGA then  
            self.m_reelDownAddTime = 30/30
        end
    end

end

function CodeGameScreenEpicElephantMachine:setReelRunInfo()
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
        --统计bonus scatter 信息
        -- scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenEpicElephantMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = false,false --reelRunData:getSpeicalSybolRunInfo(symbolType)
    if symbolType == self.SYMBOL_BONUS then 
        bRun, bPlayAni = true,true
    end

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
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

function CodeGameScreenEpicElephantMachine:getLongRunLen(col, index)
    local len = 0
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if col > 4 then
        local reelRunData = self.m_reelRunInfo[col - 1]
        local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
        local lastRunLen = reelRunData:getReelRunLen()
        len = lastRunLen + diffLen
        self.m_reelRunInfo[col]:setReelLongRun(false)
    else
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    end

    return len
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenEpicElephantMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    -- 去掉快滚
    if self.m_isStopQuickGun then
        return runStatus.DUANG, false
    else
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            return runStatus.DUANG, false
        else
            if col == showColTemp[#showColTemp - 2] then
                if nodeNum >= 2 then
                    return runStatus.DUANG, true
                else
                    return runStatus.DUANG, false
                end
            else
                return runStatus.DUANG, false
            end
        end
    end
end

function CodeGameScreenEpicElephantMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    if self.m_bProduceSlots_InFreeSpin then
        self:delayCallBack(0.3,function()
            self.m_isShowAllWild = false
            local freeNum = self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount 
            if self.m_isSuperFree and freeNum == 1 then
                self:clearLockWild()
                --刷新固定图标
                self:refreshLockWild(function()
                    self:produceSlots()

                    local isWaitOpera = self:checkWaitOperaNetWorkData()
                    if isWaitOpera == true then
                        return
                    end

                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData() -- end
                end)
            else
                self:produceSlots()

                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end

                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
        end)
    else
        local features = self.m_runSpinResultData.p_features or {}
        if #features >= 2 and features[2] > 0 then
            local random = math.random(1,10)
            if random < 5 then
                self.m_isStopQuickGun = true --有预告动画的时候 不播放快滚
                -- util_spinePlay(self.m_jiaoSeBase, "actionframe_yugao", false)
                self:delayCallBack(20/30,function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_EpicElephant_yugao)

                    self.m_yugaoEffect:setVisible(true)
                    self.m_yugaoEffect:runCsbAction("actionframe_yugao",false,function()
                        self.m_yugaoEffect:setVisible(false)
                    end) 
                    self:runCsbAction("actionframe_yugao",false,function()
                        self:produceSlots()
                
                        local isWaitOpera = self:checkWaitOperaNetWorkData()
                        if isWaitOpera == true then
                            return
                        end
                        self.m_isWaitingNetworkData = false
                        self:operaNetWorkData() -- end
                    end) 
                end)
                -- self:delayCallBack(96/30,function()
                --     self:playIdleBigJueSe()
                -- end)
                
            else
                self:produceSlots()
    
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end

                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
            
        else
            self:produceSlots()
    
            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end

    end
end

function CodeGameScreenEpicElephantMachine:scaleMainLayer()
    CodeGameScreenEpicElephantMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.7
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 10)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.88 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenEpicElephantMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    CodeGameScreenEpicElephantMachine.super.playSymbolBulingAnim(self,slotNodeList, speedActionTable)
    for k, _slotNode in pairs(slotNodeList) do
        if _slotNode then
            util_setChildNodeOpacity(_slotNode, 255)
        end
    end
end

--获得单列控制类
function CodeGameScreenEpicElephantMachine:getBaseReelControl()
    return "CodeEpicElephantSrc.EpicElephantReelControl"
end

function CodeGameScreenEpicElephantMachine:getBaseReelGridNode()
    return "CodeEpicElephantSrc.EpicElephantSlotsNode"
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenEpicElephantMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeEpicElephantSrc.EpicElephantDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
    gLobalViewManager:showUI(view)
    -- end

    return view
end

---
-- 点击快速停止reel
--
function CodeGameScreenEpicElephantMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    self.m_isQuicklyStop = true
    local isDelayCall = false
    if self.m_bClickQuickStop ~= true then
        self.m_iBackDownColID = 1
        for iCol = self.m_iBackDownColID, #self.m_slotParents, 1 do
            local slotParentDatas = self.m_slotParents
            local index = iCol
            local parentData = slotParentDatas[index]
            local col = parentData.cloumnIndex
            local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()
            if parentData.isDone == true and parentData.isResActionDone ~= true then
                isDelayCall = true
                self.m_iBackDownColID = math.max(col, self.m_iBackDownColID)
            end
        end
        if isDelayCall == true then
            self.m_iBackDownColID = self.m_iBackDownColID
        end

        if self.m_iBackDownColID >= self.m_iReelColumnNum and self.m_iBackDownColID ~= 1 then
            self.m_iBackDownColID = 1
            return
        end
    end

    if isDelayCall == true and self.m_bClickQuickStop ~= true then
        self.m_bClickQuickStop = true
    else
        if colIndex ~= nil then
            if colIndex == self.m_iBackDownColID then
                self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。
                self.m_iBackDownColID = 1
                self.m_bClickQuickStop = false
                self:operaQuicklyStopReel()
            end
        else
            self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。
            self.m_iBackDownColID = 1
            self.m_bClickQuickStop = false
            self:operaQuicklyStopReel()
        end
    end
end

return CodeGameScreenEpicElephantMachine