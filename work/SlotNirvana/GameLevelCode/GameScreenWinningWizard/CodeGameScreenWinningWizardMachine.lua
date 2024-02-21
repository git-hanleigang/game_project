--[[
玩法:  
    base:
        顶部轮盘每次spin会随机掉落魔法石
        在触发free后会转变为各种buff(加次数, 图标变wild, 赢钱乘倍)
    free:
        3个以上sc触发 or 收集满15个魔法石触发
        魔法石转化为buff后 开始freeSpin
]]
local PublicConfig = require "WinningWizardPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenWinningWizardMachine = class("CodeGameScreenWinningWizardMachine", BaseNewReelMachine)
local BaseDialog = util_require("Levels.BaseDialog")

CodeGameScreenWinningWizardMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWinningWizardMachine.SYMBOL_TopReel_Bonus         = 201         --小轮盘-bonus
CodeGameScreenWinningWizardMachine.SYMBOL_TopReel_BlackImprint  = 202         --小轮盘-黑色印记
CodeGameScreenWinningWizardMachine.SYMBOL_TopReel_Blank         = 203         --小轮盘-空图标

CodeGameScreenWinningWizardMachine.EFFECT_BASE_BonusCollect   = GameEffect.EFFECT_LINE_FRAME - 1 --base下收集数量发生变化


-- 构造函数
function CodeGameScreenWinningWizardMachine:ctor()
    CodeGameScreenWinningWizardMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    
    -- 轮盘停止的数量
    self.m_winningWizardReelDownTimes = 0

    -- 进入关卡时bet对应的bonus顶部轮盘
    self.m_enterBetBonusData = {}
    -- 本次spin首个快滚的列
    self.m_firstReelRunCol = 0
    -- 预告中奖标记
    self.m_winningNoticeTime   = 0
    self.m_isPlayWinningNotice = false
    
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    --init
    self:initGame()
end

function CodeGameScreenWinningWizardMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWinningWizardMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WinningWizard"  
end

function CodeGameScreenWinningWizardMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    --顶部法阵棋盘
    self.m_specialReel = util_createView("CodeWinningWizardSrc.WinningWizardReSpin.WinningWizardSpecialReelView", {
        machine = self,
    })
    self:findChild("Node_fazhen"):addChild(self.m_specialReel)

    --期待动画
    self.m_expectAnim = util_createView("CodeWinningWizardSrc.WinningWizardFree.WinningWizardScatterExpectAnim",{
        machine = self,
    })
    self:findChild("Node_expect"):addChild(self.m_expectAnim)

    --棋盘遮罩
    local reelDarkParent = self:findChild("Node_dark")
    self.m_reelDark = util_createAnimation("WinningWizard_dark.csb")
    reelDarkParent:addChild(self.m_reelDark)
    reelDarkParent:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2) 
    self.m_reelDark:setVisible(false)

    --预告
    self.m_yugaoSpine = util_spineCreate("Socre_WinningWizard_Scatter",true,true)
    self:findChild("Node_yugaoSpine"):addChild(self.m_yugaoSpine)
    self.m_yugaoSpine:setVisible(false)
    self.m_yugaoMaskCsb = util_createAnimation("WinningWizard_yugao_heizhe.csb")
    self:findChild("Node_yugao"):addChild(self.m_yugaoMaskCsb)
    self.m_yugaoMaskCsb:setVisible(false)
    self.m_yugaoCsb = util_createAnimation("WinningWizard_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yugaoCsb, 10)
    self.m_yugaoCsb:setVisible(false)

    --过场
    self.m_guochangCsb = util_createAnimation("WinningWizard_guochang.csb")
    self:findChild("Node_guochang"):addChild(self.m_guochangCsb)
    self.m_guochangCsb:setVisible(false)

    --大赢效果
    self.m_bigWinLizi= util_createAnimation("WinningWizard_bigwin_lizi.csb")
    self:findChild("Node_bigwin"):addChild(self.m_bigWinLizi)
    self.m_bigWinLizi:setVisible(false)
    self.m_bigWinSpine = util_spineCreate("WinningWizard_bigwin",true,true)
    self.m_bigWinLizi:findChild("Node_spine"):addChild(self.m_bigWinSpine)
    
    --文字说明
    self.m_enterTips = util_createView("CodeWinningWizardSrc.WinningWizardEnterTips")
    self:addChild(self.m_enterTips, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_enterTips:setPosition(display.width/2, display.height/2)
    self.m_enterTips:setVisible(false)

    --所有临时的效果父节点
    self.m_effectAnimParent = self:findChild("Node_effect")

    self:changeReelBg("base")
end


function CodeGameScreenWinningWizardMachine:enterGamePlayMusic(  )
    self:playEnterGameSound(PublicConfig.sound_WinningWizard_enterLevel)
end

function CodeGameScreenWinningWizardMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    --顶部棋盘初始化
    local collectLeftCount  = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
    local collectTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    local bBase = collectLeftCount <= 0 or collectLeftCount == collectTotalCount
    if bBase then
        self.m_specialReel:setCenterLabBaseStatus()
    end

    CodeGameScreenWinningWizardMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_specialReel:upDateReSpinReelStatus()
    if bBase then
        self:changeBetUpDateLockSymbol()
    else
        self:updateWinningWizardCurBetValue(globalData.slotRunData:getCurTotalBet())
    end
    if not self.m_bProduceSlots_InFreeSpin then
        self.m_enterTips:playStartAnim()
    end
    
    --reSpin相关事件移除监听
    gLobalNoticManager:removeObserver(self, ViewEventType.RESPIN_TOUCH_SPIN_BTN)
    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_RESPIN_RUN_STOP)
end

function CodeGameScreenWinningWizardMachine:addObservers()
    CodeGameScreenWinningWizardMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        -- 只有触发大赢并且跳过关卡大赢动画的话才不播连线
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

        local soundKey  = string.format("sound_WinningWizard_baseLineFrame_%d", soundIndex)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            soundKey  = string.format("sound_WinningWizard_freeLineFrame_%d", soundIndex)
        end
        local soundName = PublicConfig[soundKey]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --bet数值切换
    gLobalNoticManager:addObserver(self,function(self,params)
        self:changeBetUpDateLockSymbol()
    end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenWinningWizardMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWinningWizardMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWinningWizardMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_TopReel_Bonus then 
        return "Socre_WinningWizard_Bonus"
    end
    if symbolType == self.SYMBOL_TopReel_BlackImprint then 
        return "Socre_WinningWizard_BlackImprint"
    end
    if symbolType == self.SYMBOL_TopReel_Blank then 
        return "Socre_WinningWizard_Blank"
    end
    

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWinningWizardMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWinningWizardMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
--[[
    界面挂件
]]
function CodeGameScreenWinningWizardMachine:changeReelBg(_model, _playAnim)
    local bBase  = "base" == _model
    local bFree  = "free" == _model
    if _playAnim then
        --卷轴
        self:findChild("Node_base_reel"):setVisible(bBase)
        self:findChild("Node_free_reel"):setVisible(bFree)
        --边框
        self:findChild("Node_base_qipan"):setVisible(bBase)
        self:findChild("Node_free_qipan"):setVisible(bFree)
        --背景
        local animName = bFree and "normal_free" or "free_normal"
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self.m_gameBg:runCsbAction(animName, false, function()
            self.m_gameBg:findChild("base_bg"):setVisible(bBase)
            self.m_gameBg:findChild("free_bg"):setVisible(bFree)
            local animName = bFree and "free" or "normal" 
            self.m_gameBg:runCsbAction(animName, true)
        end)
    else
        --卷轴
        self:findChild("Node_base_reel"):setVisible(bBase)
        self:findChild("Node_free_reel"):setVisible(bFree)
        --边框
        self:findChild("Node_base_qipan"):setVisible(bBase)
        self:findChild("Node_free_qipan"):setVisible(bFree)
        --背景
        local animName = bFree and "free" or "normal" 
        self.m_gameBg:findChild("base_bg"):setVisible(bBase)
        self.m_gameBg:findChild("free_bg"):setVisible(bFree)
        self.m_gameBg:runCsbAction(animName, true)
        --法阵
        if bFree then
            self.m_specialReel:playFreeIdleAnim()
        else
            self.m_specialReel:playBaseIdleAnim()
        end
    end
end
--[[
    顶部固定bonus随bet切换
]]
function CodeGameScreenWinningWizardMachine:changeBetUpDateLockSymbol()
    local newBetValue = globalData.slotRunData:getCurTotalBet()
    if self.m_curBetValue ~= newBetValue then
        self:upDateReSpinReel()
    end
    self:updateWinningWizardCurBetValue(newBetValue)
end
function CodeGameScreenWinningWizardMachine:updateWinningWizardCurBetValue(_newBetValue)
    self.m_curBetValue = _newBetValue
end
function CodeGameScreenWinningWizardMachine:upDateReSpinReel()
    local posData   = self:getCurBetBonusPosData()
    self.m_specialReel:setReSpinReelByPosData(posData)
    self.m_specialReel:updateCenterLabBaseCollectCount(posData, false)
end
function CodeGameScreenWinningWizardMachine:getCurBetBonusPosData()
    local selfData         = self.m_runSpinResultData.p_selfMakeData or {}
    local betBonusDataList = selfData.betData or {}
    local curBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local betBonusData = betBonusDataList[tostring(curBet)] or {}
    local posData = betBonusData.locs or {}
    return posData
end

-- 断线重连 
function CodeGameScreenWinningWizardMachine:initGameStatusData(gameData)
    CodeGameScreenWinningWizardMachine.super.initGameStatusData(self, gameData)

    local extra = gameData.gameConfig.extra
    if nil ~= extra then
        if nil ~= extra.betData then
            self.m_enterBetBonusData = clone(extra.betData)
        end
    end
end
function CodeGameScreenWinningWizardMachine:MachineRule_initGame(  )

    if self.m_bProduceSlots_InFreeSpin then
        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if collectLeftCount ~= collectTotalCount then
            --切换展示
            self:changeReelBg("free", false)
            self.m_specialReel:freeReconnectionUpdateBuffList()
        else
            self.m_winningWizardReconnection = true
        end
    end
end

function CodeGameScreenWinningWizardMachine:spinResultCallFun(param)
    CodeGameScreenWinningWizardMachine.super.spinResultCallFun(self, param)
    if param[1] == true then
        -- print("CodeGameScreenWinningWizardMachine:spinResultCallFun", cjson.encode(param[2].result))
        self:levelPerformWithDelay(self, self.m_winningNoticeTime, function()
            self.m_specialReel:stopReSpinReelMove()
        end)
    end
end

--[[
    预告中奖
]]
function CodeGameScreenWinningWizardMachine:operaSpinResultData(param)
	CodeGameScreenWinningWizardMachine.super.operaSpinResultData(self,param)

	-- 预告中奖标记
    self.m_winningNoticeTime   = self:playYugaoAnim()
	self.m_isPlayWinningNotice = self.m_winningNoticeTime > 0
end
function CodeGameScreenWinningWizardMachine:playYugaoAnim()
    local features = self.m_runSpinResultData.p_features or {}
    -- 由scatter触发的free
    local bScatterFree = false
    local lineList = self.m_reelResultLines or {}
    for i,_lineValue in ipairs(lineList) do
        if _lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bScatterFree = true
            break
        end
    end
    -- 40%
    local bPlay = (math.random(1,10) <= 4)
    if bScatterFree and bPlay then
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_notice)
        
        self.m_yugaoSpine:setVisible(true)
        util_spinePlay(self.m_yugaoSpine, "actionframe_yugao", false)
        util_spineEndCallFunc(self.m_yugaoSpine, "actionframe_yugao", function()
            self.m_yugaoSpine:setVisible(false)
        end)
        self.m_yugaoMaskCsb:setVisible(true)
        self.m_yugaoMaskCsb:runCsbAction("actionframe", false, function()
            self.m_yugaoMaskCsb:setVisible(false)
        end)
        self:levelPerformWithDelay(self, 42/30, function()
            self.m_yugaoCsb:setVisible(true)
            self.m_yugaoCsb:runCsbAction("actionframe", false, function()
                self.m_yugaoCsb:setVisible(false)
            end)
        end)
        return 240/60
    end

    return 0
end
function CodeGameScreenWinningWizardMachine:updateNetWorkData()
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

    -- 将下一步的逻辑包裹一下
    local nextFun = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    -- 判断本次spin的预告中奖标记
    if self.m_isPlayWinningNotice then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 预告中奖时间线长度
        end, self.m_winningNoticeTime)
    else
        nextFun()
    end
end

function CodeGameScreenWinningWizardMachine:MachineRule_ResetReelRunData()
    if self.m_isPlayWinningNotice then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local preRunLen = reelRunData.initInfo.reelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            
            reelRunData:setReelRunLen(preRunLen)
            reelRunData:setReelLongRun(false)
            reelRunData:setNextReelLongRun(false)

            -- 提取某一列所有内容， 一些老关在创建最终信号小块时会以此列表作为最终信号的判断条件
            local columnSlotsList = self.m_reelSlotsList[iCol]  
            -- 新的关卡父类可能没有这个变量
            if columnSlotsList then

                local curRunLen = reelRunData:getReelRunLen()
                local iRow = columnData.p_showGridCount
                -- 将 老的最终列表 依次放入 新的最终列表 对应索引处
                local maxIndex = runLen + iRow
                for checkRunIndex = maxIndex,1,-1 do
                    local checkData = columnSlotsList[checkRunIndex]
                    if checkData == nil then
                        break
                    end
                    columnSlotsList[checkRunIndex] = nil
                    columnSlotsList[curRunLen + iRow - (maxIndex - checkRunIndex)] = checkData
                end

            end
            
        end
    end
end


--
--单列滚动停止回调
--
function CodeGameScreenWinningWizardMachine:slotOneReelDown(reelCol)    
    CodeGameScreenWinningWizardMachine.super.slotOneReelDown(self,reelCol) 
   
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_firstReelRunCol == 0 then
            self.m_firstReelRunCol = reelCol
            self.m_specialReel:setReSpinReelRunData(true, reelCol)
            self.m_expectAnim:playExpectAnim(reelCol)
        end
    end
    if reelCol == self.m_iReelColumnNum then
        self.m_firstReelRunCol = 0
        self.m_expectAnim:stopExpectAnim()
    end
end

---------------------------------------------------------------------------
--[[
    落地相关
]]
function CodeGameScreenWinningWizardMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
function CodeGameScreenWinningWizardMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    for k, _slotNode in pairs(slotNodeList) do
        local symbolType = _slotNode.p_symbolType
        local symbolCfg = bulingAnimCfg[symbolType]
        if symbolCfg then
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                _slotNode.m_playBuling = true
            else
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    self:playSymbolBreathingAnim(_slotNode)
                end
            end
        end
    end
    CodeGameScreenWinningWizardMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
end
function CodeGameScreenWinningWizardMachine:symbolBulingEndCallBack(_slotNode)
    _slotNode.m_playBuling = nil

    local symbolType = _slotNode.p_symbolType
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if 0 ~= self.m_firstReelRunCol then
            local iCol = _slotNode.p_cloumnIndex
            local iRow = _slotNode.p_rowIndex
            self.m_expectAnim:playExpectAnim(iCol, iRow)
        end
        self:playSymbolBreathingAnim(_slotNode)
    end
end
--[[
    呼吸动画
]]
function CodeGameScreenWinningWizardMachine:playSymbolBreathingAnim(_slotNode)
    _slotNode:runAnim("idleframe2", true)
end
--[[
    FreeSpin相关
]]
function CodeGameScreenWinningWizardMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    local reconnectionDelayTime = 0
    if self.m_winningWizardReconnection then
        reconnectionDelayTime = 0.5
    end
    self.m_winningWizardReconnection = nil
    self:levelPerformWithDelay(self, reconnectionDelayTime, function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- !!!不使用连线列表
        local lineLen = #self.m_reelResultLines
        local scatterLineValue = nil
        for i = 1, lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                scatterLineValue = lineValue
                lineValue.iLineSymbolNum = #lineValue.vecValidMatrixSymPos
                table.remove(self.m_reelResultLines, i)
                break
            end
        end
        -- 播放震动
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            -- freeMore时不播放
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end

        --触发动画
        local delayTime = 0
        if nil ~= scatterLineValue then
            gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_scatterSymbol_actionframe)
    
            for i,_symPosData in ipairs(scatterLineValue.vecValidMatrixSymPos) do
                local slotNode = self:getFixSymbol(_symPosData.iY, _symPosData.iX, SYMBOL_NODE_TAG)
                local parent = slotNode:getParent()
                --提层
                if parent ~= self.m_clipParent then
                    slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER, 0)
                end
                self:playWinningWizardScatterTrigger(slotNode)
                local duration = slotNode:getAniamDurationByName("actionframe2")
                -- delayTime = util_max(delayTime, duration)
            end
            local fazhenTime = 21/30 + 21/60--60/60
            delayTime = delayTime + fazhenTime
            self:levelPerformWithDelay(self, fazhenTime, function()
                --free文本淡入
                self.m_specialReel:playCenterLabFreeTimesStartAnim()
                --法阵反馈
                self.m_specialReel:playAnimScatterActionframe()
            end)
            --遮罩淡入->淡出
            self.m_reelDark:setVisible(true)
            self.m_reelDark:runCsbAction("start", false)
            self:levelPerformWithDelay(self, delayTime, function()
                self.m_reelDark:runCsbAction("over", false, function()
                    self.m_reelDark:setVisible(false)
                end)
            end)
            --重置期待动画-sc触发
            self.m_specialReel:reSetSlotAnim()
        else
            --free文本淡入
            self.m_specialReel:playCenterLabFreeTimesStartAnim()
        end
    
        -- 播放提示时播放音效 放在打开sc图标时播放
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_scatterTrigger_2)
        else
            -- 停掉背景音乐
            self:clearCurMusicBg()
            -- 停掉连线
            self:stopLinesWinSound()
            -- gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_scatterTrigger_1)
        end
        --展示free弹板
        self:levelPerformWithDelay(self, delayTime, function()
            self:showFreeSpinView(effectData)
        end)
    
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end)

    
    return true
end
function CodeGameScreenWinningWizardMachine:playWinningWizardScatterTrigger(_scatterNode)
    if _scatterNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return 
    end
    
    --拖尾粒子
    local animNode = _scatterNode:checkLoadCCbNode()
    local posNode  = animNode.m_posNode
    if not posNode then
        posNode = cc.Node:create()
        local spineNode = animNode.m_spineNode
        util_spinePushBindNode(spineNode, "node_1", posNode)
        animNode.m_posNode = posNode
    end
    local parent = self.m_effectAnimParent
    local scatterTuowei = util_createAnimation("WinningWizard_scatter_tw.csb")
    parent:addChild(scatterTuowei)
    
    --触发动画
    _scatterNode:runAnim("actionframe2")
    self:levelPerformWithDelay(self, 21/30, function()
        --修改方向和缩放
        local startPos = util_convertToNodeSpace(posNode, parent)
        local endPos   = util_convertToNodeSpace(self:findChild("Node_fazhen"), parent)
        scatterTuowei:setPosition(startPos)
        local rotation = util_getAngleByPos(startPos, endPos)
        rotation = - rotation
        scatterTuowei:setRotation(rotation)
        local distance = math.sqrt( math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2)) 
        scatterTuowei:setScaleX(distance / (546 * 1.5 * 0.8))

        scatterTuowei:runCsbAction("actionframe", false, function()
            scatterTuowei:removeFromParent()
        end)
    end)
end
function CodeGameScreenWinningWizardMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("WinningWizardSounds/music_WinningWizard_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        --不可能再触发
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            --打开顶部bonus奖励
            self.m_specialReel:openSlotReward(function()
                gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_freeStartView_start)
                --free弹板
                self:showFreeSpinStart(
                    self.m_iFreeSpinTimes,
                    function()
                        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_freeStartGuoChang)
                        self:playFreeGuoChang(
                            function()
                                --切换展示  
                                self:changeReelBg("free", true)
                                self.m_specialReel:playBaseToFreeAnim()
                            end,
                            function()
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()  
                            end
                        )    
                    end
                )
            end)
        end
    end

    --顶部bonus播放触发动画
    self.m_specialReel:playBonusActionFrame(function()
        self.m_specialReel:upDateReSpinReelStatus()
        showFSView()
    end)
end
function CodeGameScreenWinningWizardMachine:showFreeSpinStart(num, func, isAuto)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local buffList    = fsExtraData.buff or {}
    local freeType = self.m_specialReel:getFreeTypeByBuffList(buffList)
    local csbName  = string.format("FreeSpinStart%d", freeType)

    local freeView = self:showDialog(csbName, {}, func, BaseDialog.AUTO_TYPE_NOMAL)
    self:updateFreeStartView(freeView)
    freeView.m_btnTouchSound = PublicConfig.sound_WinningWizard_commonClick
    freeView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_freeStartView_over)
    end)
    
    return freeView
end
function CodeGameScreenWinningWizardMachine:updateFreeStartView(_freeStartView)
    local fsExtraData  = self.m_runSpinResultData.p_fsExtraData or {}
    local buffList     = fsExtraData.buff or {}
    --free次数
    local labFreeTimes = _freeStartView:findChild("m_lb_num")
    if labFreeTimes then
        labFreeTimes:setString(string.format("%d", self.m_iFreeSpinTimes))
    end
    --free结算乘倍
    local labWinMultiple = _freeStartView:findChild("m_lb_winMultiple")
    if labWinMultiple then
        local sKey        = self.m_specialReel.CenterLabData.freeTypeKey_winMultiple
        local winMultiple = 0
        for i,_buffData in ipairs(buffList) do
            if _buffData[2] == sKey then
                winMultiple = winMultiple + _buffData[3]
            end
        end
        labWinMultiple:setString(string.format("X%d", winMultiple))
    end
    --free wild变化
    local wildChangeParent = _freeStartView:findChild("Node_turn")
    if wildChangeParent then
        local wildChangeList = util_createView("CodeWinningWizardSrc.WinningWizardFree.WinningWizardWildChangeList", {
            tubiaoPath  = "WinningWizard_tanban_tubiao.csb",
            tubiaoWidth = 50,
        })
        wildChangeParent:addChild(wildChangeList)
        local sKey        = self.m_specialReel.CenterLabData.freeTypeKey_wildChange
        local symbolList = {}
        for i,_buffData in ipairs(buffList) do
            if _buffData[2] == sKey then
                table.insert(symbolList, _buffData[3])
            end
        end
        wildChangeList:updateWildChangeList(symbolList, true)
    end
    --魔法师
    local spineParent = _freeStartView:findChild("Node_spine")
    if spineParent then
        local roleSpine = util_spineCreate("Socre_WinningWizard_Scatter",true,true)
        spineParent:addChild(roleSpine)
        util_spinePlay(roleSpine, "idle_tanban", true)
    end
end

function CodeGameScreenWinningWizardMachine:showFreeSpinOverView()
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    local strCoins = util_formatCoins(fsWinCoins, 50)
    local fsCount    = self.m_runSpinResultData.p_freeSpinsTotalCount
    gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_freeOverView_start)
    local freeOverView = self:showFreeSpinOver( 
        strCoins, 
        fsCount,
        function()
            gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_freeOverGuoChang)
            self:playFreeGuoChang(
                function()
                    --切换展示  
                    self:changeReelBg("base", true)
                    self.m_specialReel:playFreeToBaseAnim()
                    local posData   = {}
                    self.m_specialReel:setReSpinReelByPosData(posData)
                    self.m_specialReel:reSetSlotReward()
                    self.m_specialReel:setSlotRingOrder(true)
                    self.m_specialReel:resetWildChangeList()
                    self.m_specialReel:setCenterLabBaseStatus()
                    self.m_specialReel:updateCenterLabBaseCollectCount(posData, false)
                end,
                function()
                    self:triggerFreeSpinOverCallFun()
                    self.m_specialReel:upDateReSpinReelStatus()
                end
            )
        end
    )
    freeOverView.m_btnTouchSound = PublicConfig.sound_WinningWizard_commonClick
    freeOverView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_freeOverView_over)
    end)

    local node = freeOverView:findChild("m_lb_coins")
    freeOverView:updateLabelSize({label=node,sx=1,sy=1}, 661)

    --魔法师
    local spineParent = freeOverView:findChild("Node_spine")
    if spineParent then
        local roleSpine = util_spineCreate("Socre_WinningWizard_Scatter",true,true)
        spineParent:addChild(roleSpine)
        util_spinePlay(roleSpine, "actionframe_tanban2", false)
        util_spineEndCallFunc(roleSpine, "actionframe_tanban2", function()
            util_spinePlay(roleSpine, "actionframe_tanban", true)
        end)
    end
end

--[[
    过场动画
]]
function CodeGameScreenWinningWizardMachine:playFreeGuoChang(_fun1, _fun2)
    self.m_guochangCsb:setVisible(true)
    self.m_guochangCsb:runCsbAction("actionframe", false, function()
        self.m_guochangCsb:setVisible(false)
    end)
    self:levelPerformWithDelay(self, 60/60, function()
        _fun1()
        self:levelPerformWithDelay(self, 33/60, function()
            _fun2()
        end)
    end)
end



---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWinningWizardMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )
    self:stopLinesWinSound()
    self.m_enterTips:playOverAnim()
    -- 重置一些标记
    self.m_firstReelRunCol = 0
    self.m_isPlayWinningNotice = false

    return false -- 用作延时点击spin调用
end

--[[
    轮盘启动数量相关
]]
-- 转轮开始滚动函数
function CodeGameScreenWinningWizardMachine:beginReel()
    self.m_winningWizardReelDownTimes = 0
    self:addWinningWizardReelDownTimes()

    CodeGameScreenWinningWizardMachine.super.beginReel(self)
    self.m_specialReel:beginReSpinReelMove()
end
-- 重写此函数 一点要调用 BaseMachine.reelDownNotifyPlayGameEffect(self) 而不是 self:playGameEffect()
function CodeGameScreenWinningWizardMachine:reelDownNotifyPlayGameEffect()
    self.m_winningWizardReelDownTimes = self.m_winningWizardReelDownTimes - 1
    if self.m_winningWizardReelDownTimes <= 0 then
        -- self.m_winningWizardReelDownTimes = 0
        CodeGameScreenWinningWizardMachine.super.reelDownNotifyPlayGameEffect(self)
    end
end
function CodeGameScreenWinningWizardMachine:addWinningWizardReelDownTimes()
    self.m_winningWizardReelDownTimes = self.m_winningWizardReelDownTimes + 1
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWinningWizardMachine:addSelfEffect()
    --没连线自己播 有连线一起播
    if self:isTriggerBonusCollect() and #self.m_vecGetLineInfo == 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_BonusCollect
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_BonusCollect 
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWinningWizardMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_BASE_BonusCollect then
        self:playEffectBonusCollect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end
--[[
    bonus收集
]]
function CodeGameScreenWinningWizardMachine:isTriggerBonusCollect()
    local collectLeftCount  = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
    local collectTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    -- free模式内不刷新收集数量 触发时例外
    if self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount then
        return false
    end

    local posData  = self:getCurBetBonusPosData()
    local newCount = #posData
    local curCount = self.m_specialReel.m_baseCollectCount
    if newCount ~= curCount then
        return true
    end

    return false
end
function CodeGameScreenWinningWizardMachine:playEffectBonusCollect(_fun)
    --等待reSpin所有bonus buling完毕才能开始刷新
    local reSpinView = self.m_specialReel.m_respinView
    local bReelRunAndBuling    = reSpinView:checkWinningWizardReelRunAndBuling()
    if bReelRunAndBuling then
        reSpinView:setWinningWizardBulingCallBack(function()
            self:playEffectBonusCollect(_fun)
        end)
    else
        if not self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
            local soundIndex = math.random(1, 2)
            local soundName  = PublicConfig[string.format("sound_WinningWizard_baseCollectUpDate_%d", soundIndex)]
            gLobalSoundManager:playSound(soundName)
        end
        
        local posData  = self:getCurBetBonusPosData()
        --落地bonus播idle
        self.m_specialReel:playBonusSymbolIdleframeLoop(posData)
        self.m_specialReel:updateCenterLabBaseCollectCount(posData, true)

        local delayTime = 45/60
        self:levelPerformWithDelay(self, delayTime, _fun)
    end
    
end

function CodeGameScreenWinningWizardMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenWinningWizardMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenWinningWizardMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_specialReel:reSpinViewQuickStop()
    CodeGameScreenWinningWizardMachine.super.slotReelDown(self)
end

function CodeGameScreenWinningWizardMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    一些工具
]]
function CodeGameScreenWinningWizardMachine:shakeReelNode(_params)
    _params = _params or {}
    --随机幅度
    local changeMin     = 1
    local changeMax     = 5
    local shakeTimes    = _params.shakeTimes or 4
    local shakeOnceTime = _params.shakeOnceTime or 0.2
    local shakeNodeName = _params.shakeNodeName or {}

    for i,_nodeName in ipairs(shakeNodeName) do
        local shakeNode = self:findChild(_nodeName)
        local oldPos = cc.p(shakeNode:getPosition())
        local changePosY = math.random(changeMin, changeMax)
        local changePosX = math.random(changeMin, changeMax)
        local actList = {}
        for ii=1,shakeTimes do
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x + changePosX, oldPos.y + changePosY)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x, oldPos.y)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x - changePosX, oldPos.y - changePosY)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x, oldPos.y)))
        end
        table.insert(actList, cc.CallFunc:create(function()
            shakeNode:setPosition(oldPos)
        end))
        shakeNode:runAction(cc.Sequence:create(actList))
    end
end

--切换小块类型
function CodeGameScreenWinningWizardMachine:changeWinningWizardSlotsNodeType(_slotsNode, _symbolType)
    if _slotsNode.p_symbolImage then
        _slotsNode.p_symbolImage:removeFromParent()
        _slotsNode.p_symbolImage = nil
    end
    local symbolName = self:getSymbolCCBNameByType(self, _symbolType)
    _slotsNode:changeCCBByName(self:getSymbolCCBNameByType(self, _symbolType), _symbolType)
    _slotsNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, _symbolType))
    _slotsNode.p_symbolType = _symbolType

    --静帧
    _slotsNode:runAnim("idleframe", false)
end
-- 延时
function CodeGameScreenWinningWizardMachine:levelPerformWithDelay(_parent, _time, _fun)
    if _time <= 0 then
        _fun()
        return
    end
    local waitNode = cc.Node:create()
    _parent:addChild(waitNode)
    performWithDelay(waitNode,function()
        _fun()
        waitNode:removeFromParent()
    end, _time)
    return waitNode
end
-- 循环处理轮盘小块
function CodeGameScreenWinningWizardMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end

--freeBuff时 假滚替换一下信号
function CodeGameScreenWinningWizardMachine:checkUpdateReelDatas(parentData)
    local reelDatas = CodeGameScreenWinningWizardMachine.super.checkUpdateReelDatas(self, parentData)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData  = self.m_runSpinResultData.p_fsExtraData or {}
        local buffList     = fsExtraData.buff or {}
        local wildBuffList = self.m_specialReel:getBuffByKey(buffList, self.m_specialReel.CenterLabData.freeTypeKey_wildChange)
        local newReelDatas = clone(reelDatas)
        for _index,_symbolType in ipairs(newReelDatas) do
            for _buffListIndex,_buffData in ipairs(wildBuffList) do
                if _symbolType == _buffData[3] then
                    -- print("[CodeGameScreenWinningWizardMachine:checkUpdateReelDatas]", _symbolType)
                    newReelDatas[_index] = TAG_SYMBOL_TYPE.SYMBOL_WILD
                end
            end
        end
        --重新赋值
        reelDatas = newReelDatas
        parentData.reelDatas = reelDatas
    end
    return reelDatas
end

--解决收集动画和连线一起播时，后面事件的延时问题
function CodeGameScreenWinningWizardMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end
    --连线
    self:showLineFrame()

    --收集动画
    local bTriggerCollect = self:isTriggerBonusCollect()
    if bTriggerCollect then
        self:playEffectBonusCollect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        return true
    end

    --大赢
    local delayTime = 0
    local bTriggerBigWin  = self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN)
    if bTriggerBigWin then
        delayTime = 0.5    
    end
    self:levelPerformWithDelay(self, delayTime, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end
---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenWinningWizardMachine:showLineFrame()
    --将scatter的连线数据内的连线数量改为0
    local winLines = self.m_reelResultLines
    for i,_lineValue in ipairs(winLines) do
        if _lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            _lineValue.iLineSymbolNum = 0
        end
    end

    CodeGameScreenWinningWizardMachine.super.showLineFrame(self)
end
--[[
    检测在小块上添加角标
    非必要不重写改接口,若需重写此接口需调用super方法
    : 解决顶部轮盘也会有活动标示的图片
]]
function CodeGameScreenWinningWizardMachine:checkAddSignOnSymbol(symbolNode)
    -- reSpin节点不添加活动图标
    local symbolType = symbolNode.p_symbolType
    if symbolType == self.SYMBOL_TopReel_BlackImprint or 
        symbolType == self.SYMBOL_TopReel_Blank or
        symbolType == self.SYMBOL_TopReel_Bonus then

        return
    end

    CodeGameScreenWinningWizardMachine.super.checkAddSignOnSymbol(self, symbolNode)
end
function CodeGameScreenWinningWizardMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY   = 8

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
            -- 1.78
            if display.height / display.width >= 1370/768 then
            --1.59
            elseif display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.24
                mainPosY  = 0
            --1.5
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.16
                mainPosY  = 13
            --1.33
            elseif display.height / display.width >= 1024/768 then
                mainScale = mainScale * 0.99
                mainPosY  = 18
            end

            mainScale = math.min(1, mainScale)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale  = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenWinningWizardMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound(PublicConfig.sound_WinningWizard_bigWin)

    local animName = "actionframe"
    self.m_bigWinLizi:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, animName, false)
    util_spineEndCallFunc(self.m_bigWinSpine, animName, function()
        self.m_bigWinLizi:setVisible(false)
        --停止连线
        self:stopLinesWinSound()
        if type(_func) == "function" then
            _func()
        end
    end)

    --震动
    self:shakeReelNode({
        shakeTimes    = 20,
        shakeOnceTime = 0.1,
        shakeNodeName = {
            "root"
        }
    })
end

return CodeGameScreenWinningWizardMachine






