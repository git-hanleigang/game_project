--[[
    玩法:
        base:
        free:
]]
local PublicConfig = require "TripleBingoPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenTripleBingoMachine = class("CodeGameScreenTripleBingoMachine", BaseNewReelMachine)

CodeGameScreenTripleBingoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenTripleBingoMachine.FIXBONUS_TYPE_LEVEL1 = 94 -- 第一个收集bingo类型-底图（黄）
CodeGameScreenTripleBingoMachine.FIXBONUS_TYPE_LEVEL2 = 95 -- 第二个收集bingo类型-底图（蓝）
CodeGameScreenTripleBingoMachine.FIXBONUS_TYPE_LEVEL3 = 96 -- 第三个收集bingo类型-底图（红）
CodeGameScreenTripleBingoMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenTripleBingoMachine.SYMBOL_LOCKBONUS_LEVEL1 = 301
CodeGameScreenTripleBingoMachine.SYMBOL_LOCKBONUS_LEVEL2 = 302
CodeGameScreenTripleBingoMachine.SYMBOL_LOCKBONUS_LEVEL3 = 303

CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_COINS_LEVEL1 = 304
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MAJOR_LEVEL1 = 305
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL1 = 306
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINI_LEVEL1 = 307
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINICOINS_LEVEL1 = 308
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINOR_LEVEL1 = 309
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINORCOINS_LEVEL1 = 310
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_GRAND_LEVEL1 = 311


CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_COINS_LEVEL2 = 404
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MAJOR_LEVEL2 = 405
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL2 = 406
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINI_LEVEL2 = 407
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINICOINS_LEVEL2 = 408
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINOR_LEVEL2 = 409
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINORCOINS_LEVEL2 = 410
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_GRAND_LEVEL2 = 411

CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_COINS_LEVEL3 = 504
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MAJOR_LEVEL3 = 505
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL3 = 506
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINI_LEVEL3 = 507
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINICOINS_LEVEL3 = 508
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINOR_LEVEL3 = 509
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_MINORCOINS_LEVEL3 = 510
CodeGameScreenTripleBingoMachine.SYMBOL_FIXBONUS_GRAND_LEVEL3 = 511

CodeGameScreenTripleBingoMachine.EFFECT_CollectBingoSymbol = GameEffect.EFFECT_SELF_EFFECT - 70 --收集bingo图标
CodeGameScreenTripleBingoMachine.EFFECT_BingoLine_Common = GameEffect.EFFECT_SELF_EFFECT - 60 --bingo连线-普通

CodeGameScreenTripleBingoMachine.ServerJackpotType = {
    Grand = "Grand",
    Major = "Major",
    Minor = "Minor",
    Mini = "Mini"
}
CodeGameScreenTripleBingoMachine.JackpotTypeToIndex = {
    [CodeGameScreenTripleBingoMachine.ServerJackpotType.Grand] = 1,
    [CodeGameScreenTripleBingoMachine.ServerJackpotType.Major] = 2,
    [CodeGameScreenTripleBingoMachine.ServerJackpotType.Minor] = 3,
    [CodeGameScreenTripleBingoMachine.ServerJackpotType.Mini] = 4
}

-- 构造函数
function CodeGameScreenTripleBingoMachine:ctor()
    CodeGameScreenTripleBingoMachine.super.ctor(self)
    self.m_lineRespinNodes = {}
    self.m_baseBetValue = -100
    --高低bet(乘倍档位)
    self.m_iBetLevel = -1
    --每个档位的bet消耗乘倍
    self.m_betMultiList = {}
    --一次spin多段赢钱时当前已经累计的金币数
    self.m_spinAddBottomCoins = 0
    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = false

    self.m_bisFirstIn = true

    --init
    self:initGame()
end

function CodeGameScreenTripleBingoMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("TripleBingoConfig.csv", "LevelTripleBingoConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTripleBingoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "TripleBingo"
end

function CodeGameScreenTripleBingoMachine:initUI()
    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    self:findChild("Node_bingoExpect"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --bingo棋盘
    self.m_bingoReelData = util_createView("CodeTripleBingoSrc.BingoReel.TripleBingoBingoData",self)
    self.m_bingoReelCtr = util_createView("CodeTripleBingoSrc.BingoReel.TripleBingoBingoCtr", self)
    --bingo棋盘-期待
    self.m_bingoReelExpectList = {}
    --bingo结算弹板
    self.m_bingoWinnerView = util_createView("CodeTripleBingoSrc.BingoReel.TripleBingoWinnerView", self)
    self:findChild("Node_winner"):addChild(self.m_bingoWinnerView)
    self.m_bingoWinnerView:setVisible(false)
    --棋盘压暗
    self:initReelMask()
    self:initJackPotBarView()

    --free
    self.m_baseFreeSpinBar = util_createView("CodeTripleBingoSrc.Free.TripleBingoFreespinBarView")
    self:findChild("Node_FGbar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)

    --三个bingo玩法界面父节点
    self.m_bingoGameParent = self:findChild("Node_bingoGameView")

    --角色
    local roleParent = self:findChild("Node_bear")
    self.m_beerL = util_createView("CodeTripleBingoSrc.TripleBingoRole", {spineName = "TripleBingo_juese"})
    roleParent:addChild(self.m_beerL)
    self.m_beerL:playBaseIdleAnim()
    self.m_beerR = util_createView("CodeTripleBingoSrc.TripleBingoRole", {spineName = "TripleBingo_juese2"})
    roleParent:addChild(self.m_beerR)
    self.m_beerR:playBaseIdleAnim()
    --说明提示
    self.m_titleL =
        util_createView(
        "CodeTripleBingoSrc.TripleBingoTitle",
        {
            machine = self,
            csbName = "TripleBingo_tishititle.csb"
        }
    )
    self:findChild("Node_tishititle_zuo"):addChild(self.m_titleL)
    self.m_titleR =
        util_createView(
        "CodeTripleBingoSrc.TripleBingoTitle",
        {
            machine = self,
            csbName = "TripleBingo_tishititle2.csb"
        }
    )
    self:findChild("Node_tishititle_you"):addChild(self.m_titleR)

    --预告中奖
    self.m_yugaoAnim = util_createView("CodeTripleBingoSrc.TripleBingoYuGao", self)

    --转场
    self.m_transferAnim = util_createView("CodeTripleBingoSrc.TripleBingoTransfer", {})
    self:findChild("Node_guochang"):addChild(self.m_transferAnim)

    local nodeWinCoinEffect = self.m_bottomUI:getCoinWinNode()
    --底栏大赢
    self.m_bigWinSpine = util_spineCreate("TripleBingo_bigwin_ui", true, true)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setPosition(util_convertToNodeSpace(nodeWinCoinEffect, self))
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setVisible(false)
    --底栏效果
    self.m_bottomEffectSpine = util_spineCreate("TripleBingo_totalwin", true, true)
    nodeWinCoinEffect:addChild(self.m_bottomEffectSpine)
    -- self.m_bottomEffectSpine:setPosition(5, -5)
    self.m_bottomEffectSpine:setVisible(false)
    --底栏大赢文本适配
    if self.m_bottomUI.m_bigWinLabInfo then
        self.m_bottomUI.m_bigWinLabInfo.width = 600
        self.m_bottomUI:setBigWinLabInfo(self.m_bottomUI.m_bigWinLabInfo)
    end

    self:changeReelBg("base")

    
end

function CodeGameScreenTripleBingoMachine:enterGamePlayMusic()

    self:resetMusicBg(true)
    self:delayCallBack(
        0.4,
        function()
            self:playEnterGameSound( PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_1)
        end
    )
end

function CodeGameScreenTripleBingoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTripleBingoMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    --显示respin界面
    self:showRespinView()

    local isATest = globalData.GameConfig:checkABtestGroupA("TripleBingoIcon")
    if not isATest then -- B组是直接解锁三个
        self:changeBetMultiply(3, true)
    else
        --选择bet档位界面
        if self:isCanOpenChooseView() then
            self:showChooseView(true)
        end
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local betLevel = selfData.betLevel or 0
        local bingoReelIndex = betLevel + 1
        self:changeBetMultiply(bingoReelIndex, true)
    end
    
    
    self.m_bingoReelCtr:onEnterUpDateBingoReelSymbolPos()
    self:upDateBetLevel()  

end

function CodeGameScreenTripleBingoMachine:addObservers()
    CodeGameScreenTripleBingoMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
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
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName =  PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_2_LINE"..soundIndex] 
            if self:getCurrSpinMode() == FREE_SPIN_NODE then
                soundName =  PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_3_LINE"..soundIndex] 
            end
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    --更改bet时触发
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not params.p_isLevelUp then
                self:upDateBetLevel()
            end
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenTripleBingoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTripleBingoMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTripleBingoMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_TripleBingo_10"
    elseif symbolType == self.FIXBONUS_TYPE_LEVEL1 then
        return "Socre_TripleBingo_Bonus"
    elseif symbolType == self.FIXBONUS_TYPE_LEVEL2 then
        return "Socre_TripleBingo_Bonus"
    elseif symbolType == self.FIXBONUS_TYPE_LEVEL3 then
        return "Socre_TripleBingo_Bonus"
    end
    return nil
end

function CodeGameScreenTripleBingoMachine:isLockBonus(_bindSymbolType)
    if _bindSymbolType == self.SYMBOL_LOCKBONUS_LEVEL1 then
        return true
    elseif _bindSymbolType == self.SYMBOL_LOCKBONUS_LEVEL2 then
        return true
    elseif _bindSymbolType == self.SYMBOL_LOCKBONUS_LEVEL3 then
        return true
    end
end

function CodeGameScreenTripleBingoMachine:getBindImgName(_bindSymbolType)
    if _bindSymbolType == self.SYMBOL_LOCKBONUS_LEVEL1 then
        return "Socre_TripleBingo_LockBonus_L1"
    elseif _bindSymbolType == self.SYMBOL_LOCKBONUS_LEVEL2 then
        return "Socre_TripleBingo_LockBonus_L2"
    elseif _bindSymbolType == self.SYMBOL_LOCKBONUS_LEVEL3 then
        return "Socre_TripleBingo_LockBonus_L3"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_COINS_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_coins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_GRAND_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_grand"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MAJOR_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_major"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_majorCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINI_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_mini"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINICOINS_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_miniCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINOR_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_minor"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINORCOINS_LEVEL1 then
        return "Socre_TripleBingo_BingoBonus_L1_minorCoins"  
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_COINS_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_coins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_GRAND_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_grand"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MAJOR_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_major"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_majorCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINI_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_mini"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINICOINS_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_miniCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINOR_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_minor"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINORCOINS_LEVEL2 then
        return "Socre_TripleBingo_BingoBonus_L2_minorCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_COINS_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_coins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_GRAND_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_grand"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MAJOR_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_major"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_majorCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINI_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_mini"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINICOINS_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_miniCoins"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINOR_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_minor"
    elseif _bindSymbolType == self.SYMBOL_FIXBONUS_MINORCOINS_LEVEL3 then
        return "Socre_TripleBingo_BingoBonus_L3_minorCoins"
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTripleBingoMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenTripleBingoMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------
--[[
    背景切换
]]
function CodeGameScreenTripleBingoMachine:changeReelBg(_model)
    local bBase = "base" == _model
    local bFree = "free" == _model
    --背景
    self.m_gameBg:findChild("base"):setVisible(bBase)
    self.m_gameBg:findChild("free"):setVisible(bFree)
    --卷轴
end
-- 断线重连
function CodeGameScreenTripleBingoMachine:initGameStatusData(gameData)
    if gameData.gameConfig then
        local extra = gameData.gameConfig.extra
        if nil ~= extra then
            --档位乘倍
            for i, v in ipairs(extra.multiplies) do
                self.m_betMultiList[i] = tonumber(v)
            end
        end
        --高低bet
        local bets = gameData.gameConfig.bets or {}
        self.m_bingoReelData:initBetDataList(bets)
    end

    if gameData.spin then
        --清空bingo玩法的数据
        if gameData.spin.selfData then
            gameData.spin.selfData.jackpot = nil
            gameData.spin.selfData.pick = nil
            gameData.spin.selfData.wheel = nil
        end
    end

    CodeGameScreenTripleBingoMachine.super.initGameStatusData(self, gameData)
end

function CodeGameScreenTripleBingoMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin then
        if globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
            --切换free
            self:changeReelBg("free")
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            self.m_baseFreeSpinBar:setVisible(true)
        end
    end
end

--[[
    bet档位相关
]]
function CodeGameScreenTripleBingoMachine:showChooseView(_bOnEnter)


    local isATest =  globalData.GameConfig:checkABtestGroupA("TripleBingoIcon")
    if not isATest then -- B组是直接解锁三个
        return
    end

    self.m_chooseView = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local viewData = {
        machine = self,
        fnOver = function()
            self.m_chooseView:removeFromParent()
            self.m_chooseView = nil
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end,
        bOnEnter = _bOnEnter,
        bisFirstIn = self.m_bisFirstIn
    }

    self.m_chooseView = util_createView("CodeTripleBingoSrc.TripleBingoChooseView", viewData)
    gLobalViewManager:showUI(self.m_chooseView)
    self.m_chooseView:findChild("root"):setScale(self.m_machineRootScale)
    self.m_bisFirstIn = false
end
function CodeGameScreenTripleBingoMachine:isCanOpenChooseView()

    local isATest = globalData.GameConfig:checkABtestGroupA("TripleBingoIcon")
    if not isATest then -- B组是直接解锁三个
        return
    end

    if nil ~= self.m_chooseView then
        return false
    end
    -- free
    if self.m_bProduceSlots_InFreeSpin then
        return false
    end
    -- 滚轮转动
    if self:getGameSpinStage() ~= IDLE or self:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
        return false
    end
    -- 事件执行
    if self.m_isRunningEffect then
        return false
    end

    return true
end
function CodeGameScreenTripleBingoMachine:changeBetMultiply(_bingoReelIndex, _bAnim)
    local bingoReelMulti = self.m_betMultiList[_bingoReelIndex]
    if not bingoReelMulti then
        return
    end

    local sMsg = string.format("[CodeGameScreenTripleBingoMachine:changeBetMultiply] %d %s", _bingoReelIndex - 1, tostring(bingoReelMulti))
    util_printLog(sMsg, true)

    local newBetLevel = _bingoReelIndex - 1
    self:changeBetMultiplyUpDateUi(self.m_iBetLevel, newBetLevel, _bAnim)
    self.m_iBetLevel = newBetLevel
    globalData.slotRunData:setCurBetMultiply(bingoReelMulti)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end
function CodeGameScreenTripleBingoMachine:changeBetMultiplyUpDateUi(_oldBetLevel, _newBetLevel, _bAnim)
    if _oldBetLevel ~= _newBetLevel then
        self.m_bingoReelCtr:upDateAllBingoReelLockAnimState(_newBetLevel, _bAnim)
    end
end
--[[
    高低bet
]]
function CodeGameScreenTripleBingoMachine:upDateBetLevel()
    local baseBet = self.m_bingoReelData:getBaseBetValue()
    if self.m_baseBetValue ~= baseBet then
        self.m_baseBetValue = baseBet
        self.m_bingoReelCtr:upDateAllBingoReelSymbol()
        self.m_bingoReelCtr:onEnterUpDateBingoReelSymbolPos()
        self.m_bingoReelData:resetBingosList()
    end
    self:upDateBingoReelExpectAnim(false)
    
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTripleBingoMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()

    self:stopAllBingoLabAnim()
    --重置状态
    self.m_spinAddBottomCoins = 0
    self.m_yugaoAnim:setWinningNoticeStatus(false)
    return false
end

--
--单列滚动停止回调
--
function CodeGameScreenTripleBingoMachine:slotOneReelDown(reelCol)
    CodeGameScreenTripleBingoMachine.super.slotOneReelDown(self, reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenTripleBingoMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    CodeGameScreenTripleBingoMachine.super.slotReelDown(self)
end

--[[
    buling相关
]]
function CodeGameScreenTripleBingoMachine:checkSymbolBulingSoundPlay(_slotNode)
    local bBuling = CodeGameScreenTripleBingoMachine.super.checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local needCount = 3 - (self.m_iReelColumnNum - _slotNode.p_cloumnIndex) * 1
        local curCount = self:getSymbolCountByCol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, _slotNode.p_cloumnIndex)
        bBuling = curCount >= needCount
    end
    return bBuling
end

---------------------------------------------------------------------------

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenTripleBingoMachine:addSelfEffect()
    if self:isTriggerCollectBingoSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_CollectBingoSymbol
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_CollectBingoSymbol
    end
    if self:isTriggerBingoLineCommon() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BingoLine_Common
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BingoLine_Common
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTripleBingoMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_CollectBingoSymbol then
        --策划要求延时
        self:levelPerformWithDelay(
            self,
            0.5,
            function()
                self:playEffectCollectBingoSymbol(
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end
        )
    elseif effectData.p_selfEffectType == self.EFFECT_BingoLine_Common then
        self:platEffectBingoLineCommon(
            1,
            function()
                self:resetMusicBg()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    return true
end

function CodeGameScreenTripleBingoMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenTripleBingoMachine.super.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

--[[
    收集bonus
]]
function CodeGameScreenTripleBingoMachine:isTriggerCollectBingoSymbol()
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    for _bingoReelIndex, _bingoData in ipairs(bingos) do
        local coins = _bingoData.coins or {}
        local jackpots = _bingoData.jackpots or {}
        if #coins > 0 or #jackpots > 0 then
            return true
        end
    end
    return false
end
function CodeGameScreenTripleBingoMachine:playEffectCollectBingoSymbol(_fun)

    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_13)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local currTotalBet = globalData.slotRunData:getCurTotalBet()
    local flyTime = 0.5
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    local collectList = {}
    for _bingoReelIndex, _bingoData in ipairs(bingos) do
        local coins = _bingoData.coins or {}
        local jackpots = _bingoData.jackpots or {}
        for i, _data in ipairs(coins) do
            local fixPos = self:getRowAndColByPos(_data.pos)
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
            local symbol = respinNode:getBaseShowSymbol()
            self:playBingoFlyAnim(symbol, flyTime)
            collectList[_data.pos] = {}
            collectList[_data.pos].isPlay = true
            collectList[_data.pos].symbolType = symbol.p_symbolType
        end
        for i, _data in ipairs(jackpots) do
            local fixPos = self:getRowAndColByPos(_data.pos)
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
            local symbol = respinNode:getBaseShowSymbol()
            self:playBingoFlyAnim(symbol, flyTime)
            collectList[_data.pos] = {}
            collectList[_data.pos].isPlay = true
            collectList[_data.pos].symbolType = symbol.p_symbolType
        end
    end

    --收集不卡spin
    local bTriggerBingoLine = self:isTriggerBingoLineCommon()
    local playLines = self.m_bingoReelCtr:getFlashEffectBingoLine(bingos)
    local bBingoReelExpect = self:isTriggerBingoReelExpect(playLines, bingos)
  
    local fnNext = function() end

    self:levelPerformWithDelay(
        self,
        flyTime,
        function()
            if currTotalBet ~= globalData.slotRunData:getCurTotalBet() then
                -- 有可能玩家在飞行粒子时切换了bet，那么就不走改变bingo棋盘的逻辑
                _fun()
                return
            end
            
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_14)

            self:upDateBingoReelExpectAnim(
                true,
                function()
                end,
                bingos,
                playLines
            )

            self:hideBingoReelExpect(bingos)

            if bTriggerBingoLine then
                fnNext = function()
                    _fun()
                end
            end

            self:playBingoFlyOverAnim(collectList, fnNext, bingos, selfData)

            if not bTriggerBingoLine then
                _fun()
            end
            
        end
    )
end
--收集飞行
function CodeGameScreenTripleBingoMachine:playBingoFlyAnim(_symbol, _flyTime)
    local iCol = _symbol.p_cloumnIndex
    local iRow = _symbol.p_rowIndex
    local symbolType = _symbol.p_symbolType
    local bingoReelIndex = PublicConfig.levelId[tostring(symbolType)]
    local bingoReelSymbol = self.m_bingoReelCtr:getBingoReelSymbol(bingoReelIndex, iCol, iRow)
    local parent = self.m_effectNode
    local startPos = util_convertToNodeSpace(_symbol, parent)
    local endPos = util_convertToNodeSpace(bingoReelSymbol, parent)
    local flyNode = util_createAnimation("TripleBingo_Bonus_lizi.csb")
    parent:addChild(flyNode)
    flyNode:setScale(self.m_machineRootScale)
    flyNode:setPosition(startPos)
    local particleName = string.format("Particle_%d", bingoReelIndex)
    local particleNode = flyNode:findChild(particleName)
    particleNode:setVisible(true)
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    local actList = {}
    table.insert(actList, cc.MoveTo:create(_flyTime, endPos))
    table.insert(
        actList,
        cc.CallFunc:create(
            function()
                particleNode:stopSystem()
                util_setCascadeOpacityEnabledRescursion(particleNode, true)
                particleNode:runAction(cc.FadeOut:create(0.5))
            end
        )
    )
    table.insert(actList, cc.DelayTime:create(0.5))
    table.insert(actList, cc.RemoveSelf:create())

    local bHigh = self:checkNewBingoSymbolHigh(iCol, iRow)
    local animName = bHigh and "shouji4" or "shouji3"
    _symbol:runAnim(animName, false)
    flyNode:runAction(cc.Sequence:create(actList))
end



--飞行完毕 bingo棋盘反馈 图标出现/刷新
function CodeGameScreenTripleBingoMachine:playBingoFlyOverAnim(_collectList, _fun, _bingos, _selfData)
    local animTime = 18 / 30
    local jumpTime = 1
    local curBet = globalData.slotRunData:getCurTotalBet()

    for _reelPos, info in pairs(_collectList) do
        local v = info
        local isPlay = v.isPlay
        local symbolType = v.symbolType
        local fixPos = self:getRowAndColByPos(_reelPos)
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
        local bingoReelIndex = PublicConfig.levelId[tostring(symbolType)]
        local bingoReel = self.m_bingoReelCtr:getBingoReel(bingoReelIndex)
        local bingoReelSymbol = bingoReel:getBingoReelFixSymbol(fixPos.iY, fixPos.iX)
        local bVisible = bingoReelSymbol:isVisible()
        bingoReel:upDateBingoSymbolBindCsb(bingoReelSymbol, nil)
        local animNode = bingoReelSymbol:checkLoadCCbNode()
        local slotCsb = animNode.m_slotCsb
        slotCsb:runCsbAction("idleframe")
        local reward = self:getBingoSymbolReward(bingoReelIndex, _reelPos, _bingos, _selfData)
        local curScore = slotCsb.m_score or 0
        local targetScore = reward.socre or 0
        local multi = reward.allSocre / curBet
        local bHigh = nil ~= reward.jackpot or self:isHighBonusMulti(multi)
        --出现时不跳钱
        if bVisible then
            bingoReel:bingoSymbolJumpCoins(slotCsb, curScore, targetScore, jumpTime)
            local animName = bHigh and "shouji2" or "shouji"
            bingoReelSymbol:runAnim(
                animName,
                false,
                function()
                    if bHigh then
                        bingoReelSymbol:runAnim("idleframe2", true)
                    end
                end
            )
        else
            bingoReel:upDateBingoSymbolScore(slotCsb, targetScore)
            local animName = bHigh and "start2" or "start"
            bingoReelSymbol:runAnim(
                animName,
                false,
                function()
                    if bHigh then
                        bingoReelSymbol:runAnim("idleframe2", true)
                    end
                end
            )
            bingoReelSymbol:setVisible(true)
        end
        --隐藏期待
        self:hideBingoReelExpectAnim(bingoReelIndex, _reelPos, _bingos)
    end

    local delayTime = math.max(animTime, jumpTime)
    self:levelPerformWithDelay(self, delayTime, _fun)
end


--飞行完毕 bingo棋盘反馈 图标出现/刷新
function CodeGameScreenTripleBingoMachine:stopAllBingoLabAnim()
    local bingos = self.m_bingoReelData:getCurBetBingosData() or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    for _symbolType, _bingoReelIndex in pairs(PublicConfig.levelId) do
        local symbolType = _symbolType
        local bingoReelIndex = _bingoReelIndex
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local reelPos = self:getPosReelIdx(iCol, iRow)
                local fixPos = self:getRowAndColByPos(reelPos)
                local bingoReel = self.m_bingoReelCtr:getBingoReel(bingoReelIndex)
                local bingoReelSymbol = bingoReel:getBingoReelFixSymbol(fixPos.iY, fixPos.iX)
                local bVisible = bingoReelSymbol:isVisible()
                if bVisible then
                    local animNode = bingoReelSymbol:checkLoadCCbNode()
                    local slotCsb = animNode.m_slotCsb
                    local reward = self:getBingoSymbolReward(bingoReelIndex, reelPos, bingos, selfData)
                    local targetScore = reward.socre or 0
                    bingoReel:stopBingoSymbolJumpCoins(slotCsb, targetScore) 
                end
            end
        end
    end
end

--[[
    多福多彩
]]
function CodeGameScreenTripleBingoMachine:isTriggerBingoLineJackpot(_selfData)
    local data = self.m_runSpinResultData.p_selfMakeData or {}
    local selfData = _selfData or data
    local jackpot = selfData.jackpot or {}
    local process = jackpot.process or {}
    if #process > 0 then
        return true
    end
    return false
end
function CodeGameScreenTripleBingoMachine:platEffectBingoLineJackpot(_fun)
    self:resetMusicBg(nil, PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_SPECIAL_BGM)
    local jackpotGameView = util_createView("CodeTripleBingoSrc.JackpotGame.TripleBingoJackpotGameView", self)
    self.m_bingoGameParent:addChild(jackpotGameView)
    local bonusData = self:getJackpotGameData()
    jackpotGameView:saveBonusData(bonusData)
    jackpotGameView:resetPickGameView()

    local jackpotReward = bonusData.reward
    local bingoReel = self.m_bingoReelCtr:getBingoReel(1)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_" .. math.random(33,34)])
    --中心图标触发
    bingoReel:playCenterSymbolTriggerAnim(
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_35"])
            --从第一棋盘中央弹出
            self:playBingoGameViewSwitchAnim(
                1,
                jackpotGameView,
                true,
                function()
                    --开始bonus
                    jackpotGameView:startGame(
                        function()
                            --中心图标转为奖励模式
                            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_56)
                            self:resetMusicBg(true)
                            bingoReel:upDateBingoCenterSymbolReward()
                            gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_39"])
                            --结束
                            self:playBingoGameViewSwitchAnim(
                                1,
                                jackpotGameView,
                                false,
                                function()
                                    jackpotGameView:removeFromParent()
                                    performWithDelay(
                                        self,
                                        function()
                                            
                                            if _fun then
                                                _fun()
                                            end
                                        end,
                                        0.5
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    )
end
function CodeGameScreenTripleBingoMachine:getJackpotGameData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpot = selfData.jackpot or {}
    local process = jackpot.process or {}
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    local bingInfos = bingos[1] or {}

    local bonusData = {}
    bonusData.index = 1
    bonusData.process = {}
    bonusData.extraProcess = {}
    local jackpotType = ""
    local winCoins = bingInfos.middleWinCoins or 0
    local rewardCount = 0
    local jpCountData = {}
    for i, v in ipairs(process) do
        --超出的放在剩余点击内
        if rewardCount < 3 then
            table.insert(bonusData.process, {name = v, value = 0})

            jpCountData[v] = jpCountData[v] and jpCountData[v] + 1 or 1
            if jpCountData[v] > rewardCount then
                jackpotType = v
                rewardCount = jpCountData[v]
            end
        else
            table.insert(bonusData.extraProcess, {name = v, value = 0})
        end
    end
    bonusData.reward = {name = jackpotType, value = winCoins}

    return bonusData
end

--[[
    N选1
]]
function CodeGameScreenTripleBingoMachine:isTriggerBingoLinePick(_selfData)
    local data = self.m_runSpinResultData.p_selfMakeData or {}
    local selfData = _selfData or data
    local pick = selfData.pick or {}
    local pickIndexes = pick.pickIndexes or {}
    if #pickIndexes > 0 then
        return true
    end
    return false
end
function CodeGameScreenTripleBingoMachine:platEffectBingoLinePick(_fun)
    self:resetMusicBg(nil, PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_SPECIAL_BGM)
    local pickData = self:getPickGameData()
    local pickGameView = util_createView("CodeTripleBingoSrc.PickGame.TripleBingoPickGameView", self)
    self.m_bingoGameParent:addChild(pickGameView)
    pickGameView:resetPickGameView()
    local bingoReel = self.m_bingoReelCtr:getBingoReel(2)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_" .. math.random(33,34)])
    bingoReel:playCenterSymbolTriggerAnim(
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_41"])
            self:playBingoGameViewSwitchAnim(
                2,
                pickGameView,
                true,
                function()
                    pickGameView:startGame(
                        pickData,
                        function()

                            gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_46"])

                            self:playBingoGameViewSwitchAnim(
                                2,
                                pickGameView,
                                false,
                                function()
                                    --中心图标转为奖励模式
                                    local bingoReel = self.m_bingoReelCtr:getBingoReel(2)
                                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_56)
                                    self:resetMusicBg(true)
                                    bingoReel:upDateBingoCenterSymbolReward()
                                    pickGameView:removeFromParent()
                                    performWithDelay(
                                        self,
                                        function()
                                           
                                            if _fun then
                                                _fun()
                                            end
                                        end,
                                        0.5
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    )
end
function CodeGameScreenTripleBingoMachine:getPickGameData()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pick = selfData.pick or {}
    local pickIndexes = pick.pickIndexes or {}
    local pickBoxes = pick.pickBoxes or {}

    local pickData = {}
    pickData.index = 1
    pickData.process = {}
    pickData.extraProcess = {}
    pickData.reward = {name = "coins", value = 0}
    for _lineIndex, _pIndex in ipairs(pickIndexes) do
        local selectIndex = _pIndex + 1
        local selectCoins = tonumber(pickBoxes[_lineIndex][selectIndex]) or 0
        --本行选中
        pickData.process[_lineIndex] = {
            name = "coins",
            value = selectCoins
        }
        --本行未选中
        pickData.extraProcess[_lineIndex] = {}
        for i, _sCoins in ipairs(pickBoxes[_lineIndex]) do
            if i ~= selectIndex then
                table.insert(
                    pickData.extraProcess[_lineIndex],
                    {
                        name = "coins",
                        value = tonumber(_sCoins) or 0
                    }
                )
            end
        end
        --累计金额
        pickData.reward.value = pickData.reward.value + selectCoins
    end

    return pickData
end
--[[
    单列转盘
]]
function CodeGameScreenTripleBingoMachine:isTriggerBingoLineWheel(_selfData)
    local data = self.m_runSpinResultData.p_selfMakeData or {}
    local selfData = _selfData or data
    local wheel = selfData.wheel or {}
    local wheels = wheel.wheels or {}
    if #wheels > 0 then
        return true
    end
    return false
end
function CodeGameScreenTripleBingoMachine:platEffectBingoLineWheel(_func)

    
    self:resetMusicBg(nil, PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_SPECIAL_BGM)
    local bingoReel = self.m_bingoReelCtr:getBingoReel(3)
    local wheelGameView = util_createView("CodeTripleBingoSrc.PortraitWheel.TripleBingoFeatureView", self)
    self.m_bingoGameParent:addChild(wheelGameView)
    wheelGameView:setOverCallBackFun(
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_22)
            self:playBingoGameViewSwitchAnim(
                3,
                wheelGameView,
                false,
                function()
                    --中心图标转为奖励模式
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_56)
                    self:resetMusicBg(true)
                    bingoReel:upDateBingoCenterSymbolReward()
                    wheelGameView:removeFromParent()
                    performWithDelay(
                        self,
                        function()
                            if _func then
                                _func()
                            end
                        end,
                        0.5
                    )
                end
            )
        end
    )

    local bingoReel = self.m_bingoReelCtr:getBingoReel(3)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_" .. math.random(33,34)])
    bingoReel:playCenterSymbolTriggerAnim(
        function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_19)
            self:playBingoGameViewSwitchAnim(
                3,
                wheelGameView,
                true,
                function()
                    wheelGameView:showWheelView()
                end
            )
        end
    )
end

function CodeGameScreenTripleBingoMachine:getWheelGameData(_selfData)
    local wheelData = {}
    local data = self.m_runSpinResultData.p_selfMakeData or {}
    local selfData = _selfData or data
    local wheel = selfData.wheel or {}
    local wheels = wheel.wheels or {}
    wheelData.endData = {}
    for i, _value in ipairs(wheels) do
        wheelData.endData[i] = tonumber(_value) or _value
    end
    local bCoins = tonumber(wheels[2]) and true or false
    wheelData.reward = {}
    wheelData.reward.name = bCoins and "coins" or wheels[2]
    wheelData.reward.value = bCoins and tonumber(wheels[2]) or 0

    return wheelData
end

--[[
    刷新bingo线期待
]]
function CodeGameScreenTripleBingoMachine:isTriggerBingoReelExpect(_playLines, bingos)
    local isPlay = false
    local playLines = _playLines
    for _bingoReelIndex = 1, #playLines do
        if self.m_bingoReelData:checkBingoReelExpectByIindex(_bingoReelIndex, bingos) then
            local lines = playLines[_bingoReelIndex]
            for j = 1, #lines do
                local line = lines[j].bingoExLine
                for k = 1, #line do
                    isPlay = true
                    return isPlay
                end
            end
        end
    end
    return isPlay
end

function CodeGameScreenTripleBingoMachine:upDateBingoReelExpectAnim(_isPlay, _func, _bingos, _playLines)
    local bingos = _bingos or self.m_bingoReelData:getCurBetBingosData()
    local expectDataList = self.m_bingoReelData:getBingoReelExpectPosData(_bingos)
    --新增所有bingo棋盘效果
    for _bingoReelIndex, _posList in ipairs(expectDataList) do
        for _sReelPos, v in pairs(_posList) do
            self:createBingoReelExpectAnim(_bingoReelIndex, tonumber(_sReelPos), _bingos)
        end
    end
    --新增base棋盘效果
    for _bingoReelIndex, _posData in pairs(expectDataList) do
        for _sReelPos, _bool in pairs(_posData) do
            self:createBingoReelExpectAnim(0, tonumber(_sReelPos), _bingos)
        end
    end
    --刷新bingo棋盘的期待,隐藏base棋盘所有期待
    for _index, _data in ipairs(self.m_bingoReelExpectList) do
        if _data.anim:isVisible() then
            local bingoReelIndex = _data.index
            if bingoReelIndex == 0 then
                local isIn = false
                for _bingoReelIndex, _posData in pairs(expectDataList) do
                    for _sReelPos, _bool in pairs(_posData) do
                        if _sReelPos == tostring(_data.pos) then
                            isIn = true
                            break
                        end
                    end
                end
                if not isIn then
                    _data.anim:stopAllActions()
                    _data.anim:setVisible(false)
                end
            else
                if not expectDataList[bingoReelIndex] or 
                    not expectDataList[bingoReelIndex][tostring(_data.pos)] then
                    _data.anim:stopAllActions()
                    _data.anim:setVisible(false)
                end
            end
        end
    end
 
    if not _isPlay then
        if _func then
            _func()
        end
        return
    end

    -- 播放扫光动画
    local speed = 1
    local falshAnimTime = 15/30
    local isPlay = false
    local playLines = _playLines
    for _bingoReelIndex = 1, #playLines do
        if self.m_bingoReelData:checkBingoReelExpectByIindex(_bingoReelIndex, bingos) then
            local lines = playLines[_bingoReelIndex]
            for j = 1, #lines do
                local line = lines[j].bingoExLine
                local lineIndex = lines[j].index
                if table_length(line) > 0 then
                    isPlay = true
                    local pos = line[3]
                    local expectFalshAnim = self:createBingoReelExpectFalshAnim(_bingoReelIndex, pos)
                    expectFalshAnim:setTimeScale(speed)
                    local vectorKey = self.m_bingoReelCtr.m_allLineDataDir[lineIndex] 
                    if vectorKey == "vertical" then
                        util_spinePlay(expectFalshAnim, "actionframe2")
                    elseif vectorKey == "horizontal" then
                        util_spinePlay(expectFalshAnim, "actionframe1")
                    elseif vectorKey == "leftToRight" then
                        util_spinePlay(expectFalshAnim, "actionframe3")
                    elseif vectorKey == "rightToLeft" then
                        util_spinePlay(expectFalshAnim, "actionframe3")
                        expectFalshAnim:setScaleX( - expectFalshAnim:getScaleX())
                    end
                    self:levelPerformWithDelay(
                        self,
                        falshAnimTime,
                        function()
                            expectFalshAnim:removeFromParent()
                        end
                    )
                end
            end
        end
    end

    if isPlay then
        self:levelPerformWithDelay(
            self,
            falshAnimTime,
            function()
                if _func then
                    _func()
                end
            end
        )
    else
        if _func then
            _func()
        end
    end
end
function CodeGameScreenTripleBingoMachine:createBingoReelExpectAnim(_bingoReelIndex, _reelPos, _bingoDatas)
    --[[
        m_bingoReelExpectList = {
            {
                index = 1,
                pos   = 0
                anim  = csb,
            }
        }
    ]]
    --存在且正在播放
    for i, _data in ipairs(self.m_bingoReelExpectList) do
        if _bingoReelIndex == _data.index and _reelPos == _data.pos and _data.anim:isVisible() then
            if 0 == _bingoReelIndex then
                self:updateExpectUi(_bingoReelIndex, _reelPos, _data.anim, _bingoDatas)
            end
            return
        end
    end

    local parent = self.m_bingoReelCtr:getReelExpectAnimParent(_bingoReelIndex)
    local expectAnim = nil
    --池子空余
    for i, _data in ipairs(self.m_bingoReelExpectList) do
        if not _data.anim:isVisible() then
            _data.index = _bingoReelIndex
            _data.pos = _reelPos
            expectAnim = _data.anim
            expectAnim:setVisible(true)
            util_changeNodeParent(parent, expectAnim)
            break
        end
    end
    --新增
    if not expectAnim then
        local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
        local data = {}
        data.index = _bingoReelIndex
        data.pos = _reelPos
        data.anim = util_createAnimation("TripleBingo_Bonus_qidai.csb") -- 期待框
        expectAnim = data.anim
        parent:addChild(expectAnim)
        table.insert(self.m_bingoReelExpectList, data)
    end

    local fixPos = self:getRowAndColByPos(_reelPos)
    if _bingoReelIndex == 0 then
        --刷新坐标
        local posNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
        expectAnim:setPosition(util_convertToNodeSpace(posNode, parent))
        --刷新缩放
        expectAnim:setScale(1)
    else
        local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
        local posNode = bingoReel:getBingoReelFixSymbol(fixPos.iY, fixPos.iX)
        expectAnim:setPosition(util_convertToNodeSpace(posNode, parent))
        expectAnim:setScale(bingoReel.ReelConfig.symbolScale)
    end
    --时间线
    expectAnim:runCsbAction("actionframe", true)

    self:updateExpectUi(_bingoReelIndex, _reelPos, expectAnim, _bingoDatas)
end

function CodeGameScreenTripleBingoMachine:createBingoReelExpectFalshAnim(_bingoReelIndex, _reelPos)
    local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
    local parent = bingoReel:getBingoReelExpectAnimParent()
    local expectFalshAnim = util_spineCreate("Socre_TripleBingo_Bingo_sg2", true, true) -- 期待框
    parent:addChild(expectFalshAnim)
    -- expectFalshAnim:setScale(bingoReel.ReelConfig.symbolScale)
    --刷新坐标
    local fixPos = self:getRowAndColByPos(_reelPos)
    local bingoReelSymbol = bingoReel:getBingoReelFixSymbol(fixPos.iY, fixPos.iX)
    expectFalshAnim:setPosition(util_convertToNodeSpace(bingoReelSymbol, parent))
    expectFalshAnim:setSkin(tostring(_bingoReelIndex))
    return expectFalshAnim
end

function CodeGameScreenTripleBingoMachine:updateExpectUi(_bingoReelIndex, _reelPos, _expectAnim, _curBingosData)
    local expectLevelData = self.m_bingoReelData:getExpectLevelDataByPos(_bingoReelIndex, _reelPos, _curBingosData)
    for i, _imgNode in ipairs(_expectAnim:findChild("Node_kuang"):getChildren()) do
        local imgName = _imgNode:getName()
        local count = #expectLevelData
        local bVisible = false

        if 1 == count then
            --节点命名都是 Sprite2_小_大
            bVisible = imgName == string.format("Sprite_%d_1", expectLevelData[1])
        elseif 2 == count then
            bVisible = imgName == string.format("Sprite2_%d_%d", expectLevelData[1], expectLevelData[2])
        elseif 3 == count then
            bVisible = imgName == "Sprite_3"
        end
        _imgNode:setVisible(bVisible)
    end
end
--检测移除bingo棋盘所有期待
function CodeGameScreenTripleBingoMachine:hideBingoReelExpect(_bingoDatas)
    for _bingoReelIndex = 1, 3 do
        if self:isTriggerBingoLineByIndex(_bingoReelIndex, _bingoDatas) then
            self:hideBingoReelExpectByIndex(_bingoReelIndex, _bingoDatas)
        end
    end
end
--棋盘bingo切掉期待
function CodeGameScreenTripleBingoMachine:hideBingoReelExpectByIndex(_bingoReelIndex, _bingoDatas)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local reelPos = self:getPosReelIdx(iRow, iCol)
            self:hideBingoReelExpectAnim(_bingoReelIndex, reelPos, _bingoDatas)
        end
    end
end
--收集飞到瞬间切掉期待
function CodeGameScreenTripleBingoMachine:hideBingoReelExpectAnim(_bingoReelIndex, _reelPos, _bingoDatas)
    for i, _data in ipairs(self.m_bingoReelExpectList) do
        if _bingoReelIndex == _data.index and _reelPos == _data.pos and _data.anim:isVisible() then
            _data.anim:setVisible(false)
            break
        end
    end
    --刷新对应base棋盘上的效果
    if 0 ~= _bingoReelIndex then
        local expectDataList = self.m_bingoReelData:getBingoReelExpectPosData(_bingoDatas)
        local bExpect = false
        for _bingoReelIndex, _posList in ipairs(expectDataList) do
            if _posList[tostring(_reelPos)] then
                bExpect = true
                break
            end
        end
        --隐藏
        if not bExpect then
            --刷新
            self:hideBingoReelExpectAnim(0, _reelPos, _bingoDatas)
        else
            self:createBingoReelExpectAnim(0, _reelPos, _bingoDatas)
        end
    end
end

--[[
    普通bingo线
]]
function CodeGameScreenTripleBingoMachine:isTriggerBingoLineCommon()
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    for _bingoReelIndex, _bingoData in ipairs(bingos) do
        local bingoLines = _bingoData.bingoLines or {}
        if #bingoLines > 0 then
            return true
        end
    end
    return false
end
function CodeGameScreenTripleBingoMachine:isTriggerBingoLineByIndex(_bingoReelIndex, _bingos)
    local bingos = _bingos or self.m_bingoReelData:getCurBetBingosData()
    local bingoData = bingos[_bingoReelIndex] or {}
    local bingoLines = bingoData.bingoLines or {}
    return #bingoLines > 0
end
function CodeGameScreenTripleBingoMachine:platEffectBingoLineCommon(_bingoReelIndex, _fun)
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    local bingoReelData = bingos[_bingoReelIndex]
    --所有棋盘执行完毕
    if not bingoReelData then
        self:playReelMaskOverAnim()
        local bonusWinCoins = self:getBingoLineWinCoins()
        local effectType = self.EFFECT_BingoLine_Common
        self:addBonusOverBigWinEffect(bonusWinCoins, effectType)
        return _fun()
    end

    --棋盘没有连线
    local bingoLines = bingoReelData.bingoLines or {}
    if #bingoLines <= 0 then
        return self:platEffectBingoLineCommon(_bingoReelIndex + 1, _fun)
    end

    local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
    local linePos = self:getBingoLinesSymbolPos(bingoLines)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_" .. math.random(31,32)])
    --连线框 图标连线 + bingo提示
    bingoReel:playLineFrameAndSymbol(
        bingoLines,
        linePos,
        function()
            --触发bingo对应玩法
            self:checkPlayBingoReelGame(
                _bingoReelIndex,
                function()
                    --结算bingo线
                    self:showBingoWinnerView(
                        _bingoReelIndex,
                        function()
                            self:platEffectBingoLineCommon(_bingoReelIndex + 1, _fun)
                        end
                    )
                end
            )
        end
    )

    --棋盘放大
    self.m_bingoReelCtr:playBingoReelBigStartAnim(
        _bingoReelIndex,
        function()
        end
    )
    --图标压暗
    bingoReel:playNoeLineSymbolDarkAnim(
        linePos,
        function()
        end
    )

    self:playBingoLineRoleAnim()
end

-- 获取 连线图标坐标
function CodeGameScreenTripleBingoMachine:getBingoLinesSymbolPos(_bingoLines)
    local linePos = {}
    for _lineIndex, _lineData in ipairs(_bingoLines) do
        for i, _reelPos in ipairs(_lineData) do
            linePos[tostring(_reelPos)] = true
        end
    end
    return linePos
end

--bingo连线时角色联动
function CodeGameScreenTripleBingoMachine:playBingoLineRoleAnim()
    self.m_beerL:playBingoLineAnim()
    self.m_beerR:playBingoLineAnim()
end

-- 检测并触发bingo玩法
function CodeGameScreenTripleBingoMachine:checkPlayBingoReelGame(_bingoReelIndex, _fun)
    if 1 == _bingoReelIndex then
        if self:isTriggerBingoLineJackpot() then
            return self:platEffectBingoLineJackpot(_fun)
        end
    elseif 2 == _bingoReelIndex then
        if self:isTriggerBingoLinePick() then
            return self:platEffectBingoLinePick(_fun)
        end
    elseif 3 == _bingoReelIndex then
        if self:isTriggerBingoLineWheel() then
            return self:platEffectBingoLineWheel(_fun)
        end
    end
    _fun()
end

function CodeGameScreenTripleBingoMachine:showBingoWinnerView(_bingoReelIndex, _fun)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_23)

    self:playReelMaskStartAnim(false)
    self.m_bingoWinnerView:resetData()
    self.m_bingoWinnerView:setVisible(true)
    self.m_bingoWinnerView:playWinnerBarStartAnim(
        _bingoReelIndex,
        function()
            self:playBingoWinnerViewCollectAnim(
                _bingoReelIndex,
                1,
                function()
                    --棋盘结算完毕 winnerBar 飞向 底栏
                    self:playBingoWinnerViewFlyBottom(
                        _bingoReelIndex,
                        function()
                            _fun()
                        end
                    )
                end
            )
        end
    )
end
--单个棋盘收集
function CodeGameScreenTripleBingoMachine:playBingoWinnerViewCollectAnim(_bingoReelIndex, _lineIndex, _fun)
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    local bingoReelData = bingos[_bingoReelIndex]
    local bingoLines = bingoReelData.bingoLines
    local lineData = bingoLines[_lineIndex]
    if not lineData then
        local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
        bingoReel:hideLineFrameAnim()
        return _fun()
    end

    

    self:playBingoSymbolCollectAnim(
        _bingoReelIndex,
        lineData,
        1,
        function()
            self:levelPerformWithDelay(
                self,
                0.5,
                function()
                    self:playBingoWinnerViewCollectAnim(_bingoReelIndex, _lineIndex + 1, _fun)
                end
            )
        end
    )
end
--单格bingo收集
function CodeGameScreenTripleBingoMachine:playBingoSymbolCollectAnim(_bingoReelIndex, _lineData, _posIndex, _fun)
    local reelPos = _lineData[_posIndex]
    if not reelPos then
        return _fun()
    end

    local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
    local fixPos = self:getRowAndColByPos(reelPos)
    local symbol = bingoReel:getBingoReelFixSymbol(fixPos.iY, fixPos.iX)
    local reward = self:getBingoSymbolReward(_bingoReelIndex, reelPos)
    local flyEndNode = self.m_bingoWinnerView:findChild("root")

    symbol:runAnim("shouji5", false)
    self:levelPerformWithDelay(
        self,
        3 / 30,
        function()
            local flyParems = {}
            flyParems.parent = self.m_effectNode
            flyParems.startPos = util_convertToNodeSpace(symbol, flyParems.parent)
            flyParems.endPos = util_convertToNodeSpace(flyEndNode, flyParems.parent)
            flyParems.particleName = string.format("Particle_%d", _bingoReelIndex)
            flyParems.bingoReelIndex = _bingoReelIndex
            flyParems.fnOver = function()
                --jackpot弹板
                self:showBingoSymbolCollectJackpotView(
                    reward,
                    function()
                        --弹板跳钱
                        self.m_bingoWinnerView:playWinCoinsAnim(
                            _bingoReelIndex,
                            reward.allSocre,
                            function()
                                self:playBingoSymbolCollectAnim(_bingoReelIndex, _lineData, _posIndex + 1, _fun)
                            end
                        )
                        
                    end,
                    _bingoReelIndex
                )
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_24)
            self:playParticleFly(flyParems)
        end
    )
end
function CodeGameScreenTripleBingoMachine:showBingoSymbolCollectJackpotView(_reward, _fun)
    if not _reward.jackpotSocre or _reward.jackpotSocre <= 0 then
        _fun()
        return 
    end

    local jpCoins = _reward.jackpotSocre
    self:showJackpotView(_reward.jackpot, jpCoins, _fun)
end
function CodeGameScreenTripleBingoMachine:playBingoWinnerViewFlyBottom(_bingoReelIndex, _fun)
    --棋盘缩小
    self.m_bingoReelCtr:playBingoReelOverAnim(
        _bingoReelIndex,
        function()
            --赢钱框退出
            self.m_bingoWinnerView:playWinnerBarOverAnim(
                function()
                    self.m_bingoWinnerView:setVisible(false)
                end
            )
            --赢钱飞到底栏
            self:levelPerformWithDelay(
                self,
                30 / 60,
                function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_29)
                    local flyParems = {}
                    flyParems.parent = self.m_effectNode
                    flyParems.startPos = util_convertToNodeSpace(self.m_bingoWinnerView, flyParems.parent)
                    flyParems.endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, flyParems.parent)
                    flyParems.particleName = string.format("Particle_%d", _bingoReelIndex)
                    flyParems.fnOver = function()
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_30)
                        --底栏刷新
                        self:playTripleBingoBottomEffect()
                        self:updateBottomUICoins(self.m_bingoWinnerView.m_curCoins, false, true, false)
                        _fun()
                    end
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_24)
                    self:playParticleFly(flyParems)
                end
            )
        end
    )
end

function CodeGameScreenTripleBingoMachine:getBingoLineWinCoins()
    local winCoins = 0
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    for _bingoReelIndex, _bingoData in ipairs(bingos) do
        local bingoLines = _bingoData.bingoLines or {}
        for _lineIndex, _lineData in ipairs(bingoLines) do
            for i, _reelPos in ipairs(_lineData) do
                local reward = self:getBingoSymbolReward(_bingoReelIndex, _reelPos)
                winCoins = winCoins + reward.allSocre
            end
        end
    end
    return winCoins
end
--特殊玩法结束检测添加大赢
function CodeGameScreenTripleBingoMachine:addBonusOverBigWinEffect(_bonusWinCoins, _effectType)
    local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
    local collectLeftCount = globalData.slotRunData.freeSpinCount
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    local bLastFree = self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount and 0 == collectLeftCount
    --检查添加大赢
    if not bLastFree and not bLine then
        self.m_iOnceSpinLastWin = _bonusWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {_bonusWinCoins, _effectType})
        self:sortGameEffects()
    else
    end
    --刷新顶栏
    if not bFree and not bLine then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end
    --连线的赢钱
    if bLine then
        local lineWinCoins = self:getClientWinCoins()
        self.m_iOnceSpinLastWin = lineWinCoins
    end
end

----------------------------新增接口插入位---------------------------------------------
---------------------------------单个滚动相关接口---------------------------------------------

-- 继承底层respinView
function CodeGameScreenTripleBingoMachine:getRespinView()
    return "CodeTripleBingoSrc.TripleBingoRespinView"
end
-- 继承底层respinNode
function CodeGameScreenTripleBingoMachine:getRespinNode()
    return "CodeTripleBingoSrc.TripleBingoRespinNode"
end

--[[
    显示respin界面
]]
function CodeGameScreenTripleBingoMachine:showRespinView()
    local randomTypes = self:getRespinRandomTypes()
    local endTypes = self:getRespinLockTypes()
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
end

--触发respin
function CodeGameScreenTripleBingoMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self.m_specialReels = true

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

---
-- 进入关卡
--
function CodeGameScreenTripleBingoMachine:enterLevel()
    CodeGameScreenTripleBingoMachine.super.enterLevel(self)
    self.m_initReelFlag = false
end

function CodeGameScreenTripleBingoMachine:initNoneFeature()
    CodeGameScreenTripleBingoMachine.super.initNoneFeature(self)
    self.m_initReelFlag = true
end

function CodeGameScreenTripleBingoMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()
    self.m_initReelFlag = false

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end
--初始化reSpin盘面修改
function CodeGameScreenTripleBingoMachine:reateRespinNodeInfo()
    local respinNodeInfo = CodeGameScreenTripleBingoMachine.super.reateRespinNodeInfo(self)
    local hasFeature = self:checkHasFeature()

    if not hasFeature then
        --修改图标类型
        for i, _nodeInfo in ipairs(respinNodeInfo) do
            local arrayPos = _nodeInfo.ArrayPos
            local symbolType = self:getTripleBingoInitReelSymbolType(arrayPos.iY, arrayPos.iX)
            if symbolType then
                _nodeInfo.Type = symbolType
            end
        end
    end
    --修改图标固定状态
    for i, _nodeInfo in ipairs(respinNodeInfo) do
        local arrayPos = _nodeInfo.ArrayPos
        if 3 == arrayPos.iY and 3 == arrayPos.iX then
            _nodeInfo.status = RESPIN_NODE_STATUS.LOCK
        end
    end

    for i=1,#respinNodeInfo do
        local info = respinNodeInfo[i]
        local pos = info.Pos
        local arrayPos = info.ArrayPos
        if arrayPos.iX > 1 then
            pos.y = pos.y + 1.5 
        end
        
    end

    return respinNodeInfo
end

function CodeGameScreenTripleBingoMachine:getRandomTripleBingoInitReelSymbolType()
    local symbolType = nil
    local roadomList = self:getRespinRandomTypes()
    roadomList[#roadomList+1] = self.FIXBONUS_TYPE_LEVEL1
    roadomList[#roadomList+1] = self.FIXBONUS_TYPE_LEVEL2
    roadomList[#roadomList+1] = self.FIXBONUS_TYPE_LEVEL3
    symbolType = roadomList[math.random(1,#roadomList)]

    return symbolType
end

function CodeGameScreenTripleBingoMachine:getTripleBingoInitReelSymbolType(_iCol, _iRow)
    local symbolType = nil
    --初始轮盘
    if type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(_iCol)
        symbolType = initDatas and initDatas[_iRow]
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            symbolType = self:getRandomTripleBingoInitReelSymbolType()
        end

        return symbolType
    end
    return symbolType
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenTripleBingoMachine:getRespinRandomTypes()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        self.SYMBOL_SCORE_10
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenTripleBingoMachine:getRespinLockTypes()
    --填一个不会出现的图标来保证所有图标不会固定
    local symbolList = {
        {type = self.FIXBONUS_TYPE_LEVEL1, runEndAnimaName = "", bRandom = true},
        {type = self.FIXBONUS_TYPE_LEVEL2, runEndAnimaName = "", bRandom = true},
        {type = self.FIXBONUS_TYPE_LEVEL3, runEndAnimaName = "", bRandom = true},
        {type = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, runEndAnimaName = "", bRandom = true}
    }

    return symbolList
end

-- --重写组织respinData信息
function CodeGameScreenTripleBingoMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    return storedInfo
end

function CodeGameScreenTripleBingoMachine:getMatrixPosSymbolType(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_reels
    if rowCount == 0 then
        local symbolType = 0
        local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        symbolType = symbol.p_symbolType
        return symbolType
    end
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end
---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenTripleBingoMachine:normalSpinBtnCall()
    --暂停中点击了spin不自动开始下一次
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.normalSpinBtnCall then
                self:normalSpinBtnCall()
            end
        end
        return
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    print("触发了 normalspin")

    local time1 = xcyy.SlotsUtil:getMilliSeconds()

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local isContinue = true
    if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
        if self.m_showLineFrameTime ~= nil then
            local waitTime = time1 - self.m_showLineFrameTime
            if waitTime < (self.m_lineWaitTime * 1000) then
                isContinue = false --时间不到，spin无效
            end
        end
    end

    if not isContinue then
        return
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- 引导打点：进入关卡-4.点击spin
    if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.noobTaskStart1) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(1, 4)
    end
    --新手引导相关
    local isComplete = globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.noobTaskStart1, true)
    if isComplete then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWBIE_TASK_TIPS, {1, false})
    end
    if self.m_isWaitingNetworkData == true then -- 真实数据未返回，所以不处理点击
        return
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("normalSpinBtnCall 消耗时间1 .. " .. (time2 - time1))

    if self:getGameSpinStage() == WAIT_RUN then
        return
    end

    self:firstSpinRestMusicBG()

    local isWaitCall = self:MachineRule_SpinBtnCall()
    if isWaitCall == false then
        --!!!替换 BaseMachine:callSpinBtn()
        self:runNextReSpinReel()
        -- 修改freespin count 的信息
        self:checkChangeFsCount()
    else
        self:setGameSpinStage(WAIT_RUN)
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
end

--开始下次ReSpin
function CodeGameScreenTripleBingoMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_curSpinCollectBonus = {}

    self:resetReelDataAfterReel()
    self:notifyClearBottomWinCoin()

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if
        not self:checkSpecialSpin() and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin and
            self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE
     then
        self:operaUserOutCoins()
    else
        if
            self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
                not self:checkSpecialSpin()
         then
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self:takeSpinNextData()
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
            self:startReSpinRun()
        end
    end
end

--开始滚动
function CodeGameScreenTripleBingoMachine:startReSpinRun()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)
    self.m_bingoReelCtr:spinClearBingoReel(function()
        self:requestSpinReusltData()
    end)
    self.m_respinView:startMove()
end

function CodeGameScreenTripleBingoMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        performWithDelay(
            self,
            function()
                self:requestSpinResult()
            end,
            0.5
        )
    else
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage(WAITING_DATA)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function CodeGameScreenTripleBingoMachine:requestSpinResult()
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
    if
        self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin()
     then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end

    self:updateJackpotList()

    self:setSpecialSpinStates(false)

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

---
-- 处理spin 返回结果
function CodeGameScreenTripleBingoMachine:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    -- 把spin数据写到文件 便于找数据bug
    if param[1] == true then
        if device.platform == "mac" then
            if param[2] and param[2].result then
                release_print("消息返回胡来了")
                print(cjson.encode(param[2].result))
            end
        end
        dumpStrToDisk(param[2].result, "------------> result = ", 50)
    else
        dumpStrToDisk({"false"}, "------------> result = ", 50)
    end
    self:checkTestConfigType(param)
    local isOpera = self:checkOpearReSpinAndSpecialReels(param) -- 处理respin逻辑
    if isOpera == true then
        return
    end

    if param[1] == true then -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else -- 处理spin失败
        self:checkOpearSpinFaild(param)
    end
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenTripleBingoMachine:checkOpearReSpinAndSpecialReels(param)
    if param[1] == true then
        local spinData = param[2]
        -- print("respin"..cjson.encode(param[2]))
        if spinData.action == "SPIN" then
            self:operaUserInfoWithSpinResult(param)

            self.m_isWaitingNetworkData = false

            self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
            self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

            self:MachineRule_RestartProbabilityCtrl()

            self:getRandomList()

            self:setGameSpinStage(GAME_MODE_ONE_RUN)

            --刷新当前bet的收集数据
            self.m_bingoReelData:spinUpDateBetData(spinData.result)
            --随机初始化bingo图标
            self:playEffectInitBingoReelSymbol(
                function()
                    --预告中奖
                   
                    self.m_yugaoAnim:playYuGaoAnim(
                        function()
                            --修改按钮状态,开始停轮
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
                            self:stopRespinRun()
                        end
                    )
                end
            )
       
        end
    else
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
    return true
end

--快停
function CodeGameScreenTripleBingoMachine:operaQuicklyStopReel()
    if self.m_respinView:getouchStatus() ~= ENUM_TOUCH_STATUS.RUN or self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        return
    end
    self:MachineRule_respinTouchSpinBntCallBack()
end

function CodeGameScreenTripleBingoMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        self:startReSpinRun()
    elseif self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        --快停
        self:quicklyStop()
    elseif not self.m_respinView then
        release_print("当前出错关卡名称:" .. self:getModuleName())
    end
end

---判断结算
function CodeGameScreenTripleBingoMachine:reSpinReelDown(addNode)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol, iRow)
            local symbolNode = respinNode:getBaseShowSymbol()
            local bingoReelIndex = self:getBingoReelIndexBySymbolType(symbolNode.p_symbolType)
            if bingoReelIndex then
                local bLock = self.m_bingoReelCtr:getBingoReelLockState(bingoReelIndex)
                if bLock then
                    symbolNode:runAnim("darkstart", false)
                end
            end
        end
    end

    self:setGameSpinStage(STOP_RUN)

    self:updateQuestUI()

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FACTION_FIGHT_SLOTS_STOP)
end

function CodeGameScreenTripleBingoMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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
            for checkIndex = 1, #self.m_lineRespinNodes do
                local checkNode = self.m_lineRespinNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY, symPosData.iX)

                checkAddLineSlotNode(respinNode)

                local symbolNode = respinNode:getBaseShowSymbol()
                if symbolNode and symbolNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = symbolNode
                    end

                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = symbolNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上(本关提到respinView上)
--
function CodeGameScreenTripleBingoMachine:changeToMaskLayerSlotNode(respinNode)
    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = respinNode

    self.m_respinView:changeRespinNodeStatus(respinNode, true)
end

function CodeGameScreenTripleBingoMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineRespinNodes

    self.m_lineSlotNodes = {}

    for i, respinNode in ipairs(self.m_lineRespinNodes) do
        self.m_respinView:changeRespinNodeStatus(respinNode, false)
        local symbolNode = respinNode:getBaseShowSymbol()
        if symbolNode then
            symbolNode:runIdleAnim()
        end
    end

    self.m_lineRespinNodes = {}
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenTripleBingoMachine:resetReelDataAfterReel()
    self.m_waitChangeReelTime = 0

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    --添加线上打印
    local logName = self:getModuleName()
    if logName then
        release_print("beginReel ... GameLevelName = " .. logName)
    else
        release_print("beginReel ... GameLevelName = nil")
    end

    self:stopAllActions()
    self:beforeCheckSystemData()
    -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
    self.m_nScatterNumInOneSpin = 0
    self.m_nBonusNumInOneSpin = 0

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        self.m_gameEffects[i] = nil
    end

    self:clearWinLineEffect()

    self.m_showLineFrameTime = nil

    self:resetreelDownSoundArray()
    self:resetsymbolBulingSoundArray()
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenTripleBingoMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY, symPosData.iX)

        local symbolNode = respinNode:getBaseShowSymbol()

        if node:getParent() == nil then
            self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)

            node:setPosition(util_convertToNodeSpace(respinNode, self.m_slotEffectLayer))

            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            node:setPosition(util_convertToNodeSpace(respinNode, self.m_slotEffectLayer))
        end
    end

    self:showEachLineSlotNodeLineAnim(frameIndex)
end

---
-- 显示所有的连线框
--
function CodeGameScreenTripleBingoMachine:showAllFrame(winLines)
    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0

    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY, symPosData.iX)

                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(util_convertToNodeSpace(respinNode, self.m_slotEffectLayer))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

function CodeGameScreenTripleBingoMachine:clearLineAndFrame()
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end
------------------------------------------------------------------------------------------------------------------------

function CodeGameScreenTripleBingoMachine:clearCurMusicBg()
    if self.m_clearNoUseOneTime then
        self.m_clearNoUseOneTime = false
        return 
    end
    CodeGameScreenTripleBingoMachine.super.clearCurMusicBg(self)
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenTripleBingoMachine:showBonusAndScatterLineTip(lineValue, callFun)
    self:levelPerformWithDelay(self, 1/30, callFun)
end

function CodeGameScreenTripleBingoMachine:showEffect_FreeSpin(effectData)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_clearNoUseOneTime = true
    end
    return CodeGameScreenTripleBingoMachine.super.showEffect_FreeSpin(self,effectData)
end


--[[
    Free相关
]]
function CodeGameScreenTripleBingoMachine:showFreeSpinView(effectData)
    local bFreeMore = globalData.slotRunData.currSpinMode == FREE_SPIN_MODE
    local showFSView = function(...)
        if bFreeMore then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_55)
            
            local view =
                self:showFreeSpinMoreAutoNomal(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    self.m_baseFreeSpinBar:playFreeMoreAnim(
                        function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            )
            --背景光
            local lightCsb = util_createAnimation("Socre_TripleBingo_guang.csb")
            view:findChild("Node_guang"):addChild(lightCsb)
            lightCsb:runCsbAction("idleframe", true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_9)
            
            local view =
                self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_11)
                    
                    self.m_transferAnim:playFreeTransferAnim(
                        function()
                            self:changeReelBg("free")
                            self.m_baseFreeSpinBar:changeFreeSpinByCount()
                            self.m_baseFreeSpinBar:setVisible(true)
                        end,
                        function()
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            )
            --背景光
            local lightCsb = util_createAnimation("Socre_TripleBingo_guang.csb")
            view:findChild("Node_guang"):addChild(lightCsb)
            lightCsb:runCsbAction("idleframe", true)
            view:findChild("root"):setScale(self.m_machineRootScale)
            view:setBtnClickFunc(function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_10)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_6)
                
            end)
            
        end
    end

    --sc触发
    self:playFreeTriggerAnim(
        bFreeMore,
        function()
            self:levelPerformWithDelay(self, 0.5, showFSView)
        end
    )
end
function CodeGameScreenTripleBingoMachine:playFreeTriggerAnim(_bFreeMore, _fun)

    local bFreeMore = globalData.slotRunData.currSpinMode == FREE_SPIN_MODE
    if bFreeMore then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_54)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_8)
    end

    --停止连线音效
    self:stopLinesWinSound()

    local animName = "actionframe"
    local delayTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol, iRow)
            local symbol = respinNode:getBaseShowSymbol()
            if symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbol:setVisible(false)
                local spine = util_spineCreate("Socre_TripleBingo_Scatter", true, true)
                self.m_clipParent:addChild(spine,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 2)
                spine:setPosition(util_convertToNodeSpace(symbol, self.m_clipParent))
                util_spinePlay(spine,animName)
                util_spineEndCallFunc(spine,animName,function()
                    symbol:setVisible(true)
                    symbol:runAnim("idleframe2", true)
                    spine:setVisible(false)
                    performWithDelay(spine,function()
                        spine:removeFromParent()
                    end,0)
                end)

                delayTime = spine:getAnimationDurationTime(animName)
            end
        end
    end

    self.m_beerL:playFreeTriggerAnim()
    self.m_beerR:playFreeTriggerAnim()

    self:levelPerformWithDelay(self, delayTime, _fun)
end

function CodeGameScreenTripleBingoMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    performWithDelay(self,function ()
        CodeGameScreenTripleBingoMachine.super.showEffect_newFreeSpinOver(self)
    end,0.3) 
end
function CodeGameScreenTripleBingoMachine:showFreeSpinOverView(effectData)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_" .. math.random(15,16)] )
    local winCoins = globalData.slotRunData.lastWinCoin
    local bWinCoins = winCoins > 0
    local freeTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local fnOver = function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_18)
        
        self.m_transferAnim:playFreeTransferAnim(
            function()
                self:changeReelBg("base")
                self.m_baseFreeSpinBar:setVisible(false)
            end,
            function()
                self:triggerFreeSpinOverCallFun()
            end
        )
    end

    if bWinCoins then
        local strCoins = util_formatCoins(winCoins, 30)
        local view = self:showFreeSpinOver(strCoins, freeTotalCount, fnOver)
        --背景光
        local lightCsb = util_createAnimation("Socre_TripleBingo_guang.csb")
        view:findChild("Node_guang"):addChild(lightCsb)
        lightCsb:runCsbAction("idleframe", true)
        --角色
        local spine = util_spineCreate("TripleBingo_jackpot_tanban", true, true)
        view:findChild("Node_juese"):addChild(spine)
        local startName = "start3"
        util_spinePlay(spine, startName, false)
        util_spineEndCallFunc(
            spine,
            startName,
            function()
                util_spinePlay(spine, "idle3", true)
            end
        )
        --文本适配
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1.01, sy = 1.03}, 673)
        view:findChild("root"):setScale(self.m_machineRootScale)

        local node1 = view:findChild("m_lb_num")
        view:updateLabelSize({label = node1, sx = 0.9, sy = 0.9}, 89)


        view:setBtnClickFunc(function()
            
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_17)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_6)
        end)
    else
        local view = self:showFreeSpinOverNoWin(fnOver)
        --背景光
        local lightCsb = util_createAnimation("Socre_TripleBingo_guang.csb")
        view:findChild("Node_guang"):addChild(lightCsb)
        lightCsb:runCsbAction("idleframe", true)
        view:findChild("root"):setScale(self.m_machineRootScale)

        view:setBtnClickFunc(function()
            
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_17)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_6)
        end)
    end
end

function CodeGameScreenTripleBingoMachine:showFreeSpinOverNoWin(func)
    return self:showDialog("FreeSpinOver_NoWin", {}, func)
end

function CodeGameScreenTripleBingoMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeTripleBingoSrc.TripleBingoJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView)
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenTripleBingoMachine:showJackpotView(jackpotType, coins, func)
    local view =
        util_createView(
        "CodeTripleBingoSrc.TripleBingoJackpotWinView",
        {
            jackpotType = jackpotType,
            winCoin = coins,
            machine = self,
            func = function()
                if type(func) == "function" then
                    func()
                end
            end
        }
    )

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenTripleBingoMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType, coins in pairs(jackpotCoins) do
        return jackpotType, coins
        -- return string.lower(jackpotType), coins
    end
    return "", 0
end

function CodeGameScreenTripleBingoMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenTripleBingoMachine:isFixSymbol(_symbolType)
    if _symbolType == self.FIXBONUS_TYPE_LEVEL1 then
        return true , self.m_iBetLevel >= 0
    elseif _symbolType == self.FIXBONUS_TYPE_LEVEL2 then
        return true , self.m_iBetLevel >= 1
    elseif _symbolType == self.FIXBONUS_TYPE_LEVEL3 then
        return true , self.m_iBetLevel >= 2
    end
    return false
end

function CodeGameScreenTripleBingoMachine:isCoinsBindSymbol(_bindImgType)
    if _bindImgType == self.SYMBOL_FIXBONUS_COINS_LEVEL1 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL1 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MINORCOINS_LEVEL1 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MINICOINS_LEVEL1 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_COINS_LEVEL2 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL2 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MINORCOINS_LEVEL2 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MINICOINS_LEVEL2 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_COINS_LEVEL3 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MAJORCOINS_LEVEL3 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MINORCOINS_LEVEL3 then
        return true
    elseif _bindImgType == self.SYMBOL_FIXBONUS_MINICOINS_LEVEL3 then
        return true
    end
    return false
end

--[[
    刷新小块
]]
function CodeGameScreenTripleBingoMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    local symbolNode = node
    -- 先处理小块绑定
    if self:isFixSymbol(symbolType) then
        local bindNode, score = self:getLblOnBonusSymbol(symbolNode)
        local bindImgType = bindNode:getName()
        if self:isCoinsBindSymbol(tonumber(bindImgType)) then
            self:setSpecialNodeScore(node, score)
        end
    end
    self:upDateBonusSkin(node)
end
--bonus皮肤
function CodeGameScreenTripleBingoMachine:upDateBonusSkin(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    local skinName = self:getBonusSkinName(symbolType)
    if not skinName then
        return
    end
    local animNode = _symbol:checkLoadCCbNode()
    local spine = animNode.m_spineNode or (_symbol.m_symbolType and animNode)
    spine:setSkin(skinName)
end
function CodeGameScreenTripleBingoMachine:getBonusSkinName(_symbolType)
    local skinCfg = {
        [self.FIXBONUS_TYPE_LEVEL1] = "huang",
        [self.FIXBONUS_TYPE_LEVEL2] = "lan",
        [self.FIXBONUS_TYPE_LEVEL3] = "hong"
    }
    return skinCfg[_symbolType]
end

function CodeGameScreenTripleBingoMachine:isHighBonusMulti(_multi)
    return _multi >= 10
end
--根据高倍判断刷新图标的idle
function CodeGameScreenTripleBingoMachine:upDateBingoSymbolIdle(_symbol, _bCenter, _bHigh)
    local animName = "idleframe"
    local bLoop = false
    if not _bCenter and _bHigh then
        animName = "idleframe2"
        bLoop = true
    end
    _symbol:runAnim(animName, bLoop)
end

-- 给respin小块进行赋值
function CodeGameScreenTripleBingoMachine:setSpecialNodeScore(_symbolNode, _score)
    local bindNode = self:getLblOnBonusSymbol(_symbolNode)
    local lab = bindNode:findChild("m_lb_coins")
    if lab and _score then
        _score = util_formatCoins(_score, 3)
        lab:setString(_score)
    end
end

--[[
    随机bonus分数
]]
function CodeGameScreenTripleBingoMachine:randomBindImgType()
    local imgType = self.m_configData:getFixSymbolPro()
    --乘倍
    if tonumber(imgType) then
        local curBet = globalData.slotRunData:getCurTotalBet()
        local score = curBet * imgType
        return score
    end
    --jackpot
    return imgType
end

function CodeGameScreenTripleBingoMachine:getBindImgType(_symbolNode)
    local iCol = _symbolNode.p_cloumnIndex
    local iRow = _symbolNode.p_rowIndex
    local index = self:getPosReelIdx(iRow, iCol)
    local isLastSymbol = _symbolNode.m_isLastSymbol
    local symbolType = _symbolNode.p_symbolType or _symbolNode.m_symbolType
    local level = PublicConfig.levelId[tostring(symbolType)]
    if not symbolType then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and isLastSymbol then
        local newReward = self:getNewBingoSymbolReward(index)
        local imgType, socre = newReward.symbolType, newReward.socre
        --未解锁的bingo走随机数据
        if not imgType and not socre then
            local randomReward = self:getRandomBingoSymbolReward(symbolType)
            imgType, socre = randomReward.symbolType, randomReward.socre
        end
        return imgType, socre
    else
        -- 随机数据
        local randomReward = self:getRandomBingoSymbolReward(symbolType)
        imgType, socre = randomReward.symbolType, randomReward.socre
        return imgType, socre
    end
end
--获取假滚随机bingo图标奖励数据(图标类型, 奖励类型, ...)
function CodeGameScreenTripleBingoMachine:getRandomBingoSymbolReward(_symbolType)
    local data = {}
    data.symbolType = nil
    data.socre = nil
    data.jackpot = nil

    local bingoReelIndex = PublicConfig.levelId[tostring(_symbolType)]
    local randomType = self:randomBindImgType()
    if tonumber(randomType) then
        data.socre = tonumber(randomType)
    else
        data.jackpot = randomType
    end
    data.symbolType = self:getBingoSymbolType(bingoReelIndex, data.jackpot, data.socre)

    return data
end
--获取随机初始化的bingo图标奖励数据(图标类型, 奖励类型, ...)
-- function CodeGameScreenTripleBingoMachine:getInitCoinsBingoSymbolReward(_bingoReelIndex, _reelPos)
--     local data = {}
--     data.symbolType = nil
--     data.socre   = nil
--     data.jackpot = nil
--     return data
-- end
--获取新滚出的bingo图标奖励数据(图标类型, 奖励类型, ...)
function CodeGameScreenTripleBingoMachine:getNewBingoSymbolReward(_reelPos)
    local data = {}
    data.symbolType = nil
    data.socre = nil
    data.jackpot = nil

    local bingos = self.m_bingoReelData:getCurBetBingosData()

    for _bingoReelIndex, _bingInfos in ipairs(bingos) do
        local coinsList = _bingInfos.coins or {}
        for i, v in ipairs(coinsList) do
            if _reelPos == tonumber(v.pos) then
                data.socre = v.coins
                data.jackpot = v.jackpot
                data.symbolType = self:getBingoSymbolType(_bingoReelIndex, data.jackpot, data.socre)
                return data
            end
        end
    end

    return data
end
--获取bingo棋盘上指定位置最终的奖励数据(图标类型, 金币奖励, jp类型, jp奖励, 合计奖励, ...)
function CodeGameScreenTripleBingoMachine:getBingoSymbolReward(_bingoReelIndex, _reelPos, _bingos, _selfData)
    local data = {}
    data.symbolType = nil
    data.socre = 0
    data.jackpot = nil
    data.jackpotSocre = 0
    data.allSocre = 0

    local bingos = _bingos or self.m_bingoReelData:getCurBetBingosData()
    local bingInfos = bingos[_bingoReelIndex] or {}
    local bonusReels = bingInfos.bonusReels or {}
    local fixPos = self:getRowAndColByPos(_reelPos)
    --金币
    local lineIndex = self.m_iReelRowNum - fixPos.iX + 1
    if bonusReels[lineIndex] and bonusReels[lineIndex][fixPos.iY] then
        data.socre = math.max(0, bonusReels[lineIndex][fixPos.iY])
    end
    --jcakpot
    local jackpots = bingInfos.jackpots or {}
    local jackpotCoins = bingInfos.jackpotCoins or {}
    local sReelPos = tostring(_reelPos)
    if jackpots[sReelPos] then
        data.jackpot = jackpots[sReelPos]
        data.jackpotSocre = jackpotCoins[sReelPos] or 0
    end
    --中心图标修改一下奖励获取位置
    if self:isBingoCenterSymbol(nil, nil, _reelPos) then
        self:getCenterBingoSymbolReward(_bingoReelIndex, data, _bingos, _selfData)
    end
    data.allSocre = data.socre + data.jackpotSocre
    data.symbolType = self:getBingoSymbolType(_bingoReelIndex, data.jackpot, data.socre)

    return data
end
function CodeGameScreenTripleBingoMachine:getCenterBingoSymbolReward(_bingoReelIndex, _rewardData, _bingos, _selfData)
    local bingos = _bingos or self.m_bingoReelData:getCurBetBingosData()
    local bingInfos = bingos[_bingoReelIndex] or {}
    if 1 == _bingoReelIndex then
        if self:isTriggerBingoLineJackpot(_selfData) then
            local bonusData = self:getJackpotGameData()
            _rewardData.jackpot = bonusData.reward.name
            _rewardData.jackpotSocre = bingInfos.middleWinCoins or 0
        end
    elseif 2 == _bingoReelIndex then
        if self:isTriggerBingoLinePick(_selfData) then
            _rewardData.socre = bingInfos.middleWinCoins or 0
        end
    elseif 3 == _bingoReelIndex then
        if self:isTriggerBingoLineWheel(_selfData) then
            local wheelData = self:getWheelGameData(_selfData)
            if wheelData.reward.name ~= "coins" then
                _rewardData.jackpot = wheelData.reward.name
                _rewardData.jackpotSocre = bingInfos.middleWinCoins or 0
            else
                _rewardData.socre = bingInfos.middleWinCoins or 0
            end
        end
    end
end

function CodeGameScreenTripleBingoMachine:getBingoSymbolType(_bingoReelIndex, _jpType, _coins)
    local bCoins = _coins and _coins > 0
    if _jpType == self.ServerJackpotType.Mini then
        if bCoins then
            return self["SYMBOL_FIXBONUS_MINICOINS_LEVEL" .. _bingoReelIndex]
        else
            return self["SYMBOL_FIXBONUS_MINI_LEVEL" .. _bingoReelIndex]
        end
    elseif _jpType == self.ServerJackpotType.Minor then
        if bCoins then
            return self["SYMBOL_FIXBONUS_MINORCOINS_LEVEL" .. _bingoReelIndex]
        else
            return self["SYMBOL_FIXBONUS_MINOR_LEVEL" .. _bingoReelIndex]
        end
    elseif _jpType == self.ServerJackpotType.Major then
        if bCoins then
            return self["SYMBOL_FIXBONUS_MAJORCOINS_LEVEL" .. _bingoReelIndex]
        else
            return self["SYMBOL_FIXBONUS_MAJOR_LEVEL" .. _bingoReelIndex]
        end
    elseif _jpType == self.ServerJackpotType.Grand then
        return self["SYMBOL_FIXBONUS_GRAND_LEVEL" .. _bingoReelIndex]
    else
        return self["SYMBOL_FIXBONUS_COINS_LEVEL" .. _bingoReelIndex]
    end
end
--检测新滚出的bonus是否是高倍
function CodeGameScreenTripleBingoMachine:checkNewBingoSymbolHigh(_iCol, _iRow)
    local reelPos = self:getPosReelIdx(_iRow, _iCol)
    local newReward = self:getNewBingoSymbolReward(reelPos)
    local bHigh = false
    if newReward.socre then
        local curBet = globalData.slotRunData:getCurTotalBet()
        local multi = newReward.socre / curBet
        bHigh = self:isHighBonusMulti(multi)
    elseif newReward.jackpot then
        bHigh = true
    end

    return bHigh
end
--检测bingo棋盘上bonus是否是高倍
function CodeGameScreenTripleBingoMachine:checkBingoSymbolHigh(_bingoReelIndex, _iCol, _iRow)
    local reelPos = self:getPosReelIdx(_iRow, _iCol)
    local reward = self:getBingoSymbolReward(_bingoReelIndex, reelPos)
    local bHigh = false
    if reward.socre and reward.socre ~= 0 then
        local curBet = globalData.slotRunData:getCurTotalBet()
        local multi = reward.socre / curBet
        bHigh = self:isHighBonusMulti(multi)
    elseif reward.jackpot then
        bHigh = true
    end

    return bHigh
end

--[[
    spin消息返回时,随机初始化bingo棋盘
]]
function CodeGameScreenTripleBingoMachine:playEffectInitBingoReelSymbol(_fun)
    local bingos = self.m_bingoReelData:getCurBetBingosData()
    local triggerData = {}
    for _bingoReelIndex, _bingoReelData in ipairs(bingos) do
        if nil ~= next(_bingoReelData.initCoins) then
            triggerData[_bingoReelIndex] = _bingoReelData.initCoins
        end
        
    end
    if not next(triggerData)  then
        return _fun()
    end

    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_52)
    local delayTime = 0
    for _bingoReelIndex, _initCoins in pairs(triggerData) do
        local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
        local time = bingoReel:playInitCoinsAnim(_initCoins)
        delayTime = math.max(delayTime, time)
    end
    self:levelPerformWithDelay(self, delayTime, _fun)
end

--[[
    大赢
]]
function CodeGameScreenTripleBingoMachine:showEffect_NewWin(effectData, winType)
    self:playLevelBigWinAnim(
        function()
            -- 停止连线音效
            self:stopLinesWinSound()
            CodeGameScreenTripleBingoMachine.super.showEffect_NewWin(self, effectData, winType)
        end
    )
end
function CodeGameScreenTripleBingoMachine:playLevelBigWinAnim(_fun)
    -- free最后一次
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) then
        _fun()
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_40"])

    self.m_bigWinSpine:setVisible(true)
    local animName = "actionframe_bigwin"
    util_spinePlay(self.m_bigWinSpine, animName, false)
    util_spineEndCallFunc(
        self.m_bigWinSpine,
        animName,
        function()
            self.m_bigWinSpine:setVisible(false)
            _fun()
        end
    )
    self.m_beerL:playBigWinAnim()
    self.m_beerR:playBigWinAnim()

    util_shakeNode(self:findChild("Node_qipan"), 3, 3, 81 / 30)

    local params = {
        overCoins = self.m_llBigOrMegaNum,
        animName = "actionframe3",
        jumpTime = 1.5
    }
    self:playBottomBigWinLabAnim(params)
end

--[[
    获取bonus小块上的label
]]
function CodeGameScreenTripleBingoMachine:getLblOnBonusSymbol(symbolNode)
    local aniNode = symbolNode:checkLoadCCbNode()
    local bindImgType, socre = self:getBindImgType(symbolNode)
    local resName = self:getBindImgName(bindImgType)
    local csbName = string.format("%s.csb", resName)
    local spine = aniNode.m_spineNode
    if spine then
        if (not spine.m_lbl_score or spine.m_lbl_score:getName() ~= tostring(bindImgType)) then
            util_spineRemoveBindNode(spine, spine.m_lbl_score)
            spine.m_lbl_score = nil
            local label = util_createAnimation(csbName)
            local slotName = "shuzi2"
            util_spinePushBindNode(spine, slotName, label)
            spine.m_lbl_score = label
            spine.m_lbl_score:setName(tostring(bindImgType))
            if self:isLockBonus(bindImgType) then
                label:runCsbAction("idleframe2",true)
            end
        end
    end

    return spine.m_lbl_score, socre
end

--[[
    遮罩
]]
function CodeGameScreenTripleBingoMachine:initReelMask()
    self.m_reelMask = util_createAnimation("TripleBingo_mask.csb")
    self:findChild("Node_mask"):addChild(self.m_reelMask)
    self.m_reelMask:setVisible(false)
end
function CodeGameScreenTripleBingoMachine:playReelMaskStartAnim(_bBig)
    local bgNode = self.m_reelMask:findChild("bg")
    local qipanNode = self.m_reelMask:findChild("qipan")
    --对应遮罩打开时不操作
    if _bBig and bgNode:isVisible() then
        return
    elseif qipanNode:isVisible() then
        return
    end

    bgNode:setVisible(_bBig)
    qipanNode:setVisible(not _bBig)
    self.m_reelMask:setVisible(true)
    self.m_reelMask:runCsbAction("start", false)
end
function CodeGameScreenTripleBingoMachine:playReelMaskOverAnim()
    self.m_reelMask:runCsbAction(
        "over",
        false,
        function()
            self.m_reelMask:findChild("bg"):setVisible(false)
            self.m_reelMask:findChild("qipan"):setVisible(false)
            self.m_reelMask:setVisible(false)
        end
    )
end

--[[
    工具
]]
--奖池分值
function CodeGameScreenTripleBingoMachine:getTripleBingoJackpotScore(_index)
    local totalBet = self.m_bingoReelData:getBaseBetValue(nil)
    local value = self:BaseMania_updateJackpotScore(_index, totalBet)
    return value
end

--bingo玩法弹板 从 bingo棋盘 弹出收回
function CodeGameScreenTripleBingoMachine:playBingoGameViewSwitchAnim(_bingoReelIndex, _bingoGameCsb, _bStart, _fun)
    local bingoReel = self.m_bingoReelCtr:getBingoReel(_bingoReelIndex)
    local startPos = _bStart and util_convertToNodeSpace(bingoReel, _bingoGameCsb:getParent()) or cc.p(0, 0)
    local endPos = _bStart and cc.p(0, 0) or util_convertToNodeSpace(bingoReel, _bingoGameCsb:getParent())
    _bingoGameCsb:setPosition(startPos)
    _bingoGameCsb:runAction(cc.EaseOut:create(cc.MoveTo:create(24 / 60, endPos), 1.2))
    local animName = _bStart and "start" or "over"
    _bingoGameCsb:runCsbAction(
        animName,
        false,
        function()
            if _bStart then
                _bingoGameCsb:runCsbAction("idle", true)
            end
            _fun()
        end
    )
end

--底栏反馈
function CodeGameScreenTripleBingoMachine:playTripleBingoBottomEffect()
    self.m_bottomEffectSpine:stopAllActions()
    self.m_bottomEffectSpine:setVisible(true)
    util_spinePlay(self.m_bottomEffectSpine, "actionframe", false)
    performWithDelay(
        self.m_bottomEffectSpine,
        function()
            self.m_bottomEffectSpine:setVisible(false)
        end,
        24 / 30
    )
end
--更新底栏金币
function CodeGameScreenTripleBingoMachine:updateBottomUICoins(_addCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local params = {}
    params[1] = _addCoins
    params[2] = isNotifyUpdateTop
    params[3] = _bJump
    params[4] = 0
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound

    local lastCoins = self:getLastWinCoin()
    local spinWinCoins = self.m_runSpinResultData.p_winAmount or 0
    self.m_spinAddBottomCoins = self.m_spinAddBottomCoins + _addCoins
    local tempLastCoins = lastCoins - spinWinCoins + self.m_spinAddBottomCoins
    self:setLastWinCoin(tempLastCoins)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    self:setLastWinCoin(lastCoins)
end

--粒子飞行
function CodeGameScreenTripleBingoMachine:playParticleFly(_params)
    --[[
        _params = {
            parent       = cc.Node,
            csbName      = "TripleBingo_Bonus_lizi.csb",
            startPos     = cc.p(0, 0),
            endPos       = cc.p(0, 0),
            particleName = "Particle_1",
            flyTime      = 0.5,
            fnOver       = function,
        }
    ]]
    local parent = _params.parent or self.m_effectNode
    local csbName = _params.csbName or "TripleBingo_Bonus_lizi.csb"
    local startPos = _params.startPos
    local endPos = _params.endPos
    local particleName = _params.particleName or "Particle_1"
    local flyTime = _params.flyTime or 0.5
    local bingoReelIndex = _params.bingoReelIndex
    local fnOver = _params.fnOver or function() end

    local flyNode = util_createAnimation(csbName)
    flyNode:setScale(self.m_machineRootScale)
    parent:addChild(flyNode)
    flyNode:setPosition(startPos)

    if bingoReelIndex then
        local flyImg = util_createAnimation("TripleBingo_Bonus_tw.csb")
        flyNode:addChild(flyImg,-1)
        flyImg:findChild("Node_Scale"):setScaleX(0.7)
        flyImg:findChild("TripleBingo_Bingo_tw1_1"):setVisible(bingoReelIndex == 1)
        flyImg:findChild("TripleBingo_Bingo_tw2_2"):setVisible(bingoReelIndex == 2)
        flyImg:findChild("TripleBingo_Bingo_tw3_3"):setVisible(bingoReelIndex == 3)
        local rotation = util_getAngleByPos(startPos, endPos)
        flyImg:setRotation(- rotation)
        flyImg:findChild("Node_flyScale"):setScaleX(0.01)
        util_playScaleToAction(flyImg:findChild("Node_flyScale"), flyTime, 1, function()
            util_playScaleToAction(flyImg:findChild("Node_flyScale"), flyTime / 3, 0.01, function()
            
            end)
        end)
    end
   

    local particleNode = flyNode:findChild(particleName)
    particleNode:setVisible(true)
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    local actList = {}
    table.insert(actList, cc.MoveTo:create(flyTime, endPos))
    table.insert(
        actList,
        cc.CallFunc:create(
            function()
                fnOver()
                particleNode:stopSystem()
                util_setCascadeOpacityEnabledRescursion(particleNode, true)
                particleNode:runAction(cc.FadeOut:create(0.5))
            end
        )
    )
    table.insert(actList, cc.DelayTime:create(0.5))
    table.insert(actList, cc.RemoveSelf:create())
    flyNode:runAction(cc.Sequence:create(actList))
end
-- 延时
function CodeGameScreenTripleBingoMachine:levelPerformWithDelay(_parent, _time, _fun)
    if _time < 0 then
        _fun()
        return
    end
    local waitNode = cc.Node:create()
    _parent:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            _fun()
            waitNode:removeFromParent()
        end,
        _time
    )
    return waitNode
end

--获取bingo棋盘索引
function CodeGameScreenTripleBingoMachine:getBingoReelIndexBySymbolType(_symbolType)
    if self.FIXBONUS_TYPE_LEVEL1 <= _symbolType and _symbolType <= self.FIXBONUS_TYPE_LEVEL3 then
        return _symbolType + 1 - self.FIXBONUS_TYPE_LEVEL1
    end
    return nil
end

function CodeGameScreenTripleBingoMachine:isBingoCenterSymbol(_iCol, _iRow, _reelPos)
    if 12 == _reelPos then
        return true
    end
    if 3 == _iCol and 3 == _iRow then
        return true
    end
    return false
end
--获取信号停轮时N列前的总数
function CodeGameScreenTripleBingoMachine:getSymbolCountByCol(_symbolType, _iCol)
    local count = 0
    local reel = self.m_runSpinResultData.p_reels
    for _lineIndex, _lineData in ipairs(reel) do
        for iCol, _symbol in ipairs(_lineData) do
            if iCol <= _iCol and _symbol == _symbolType then
                count = count + 1
            end
        end
    end

    return count
end

function CodeGameScreenTripleBingoMachine:scaleMainLayer()
    CodeGameScreenTripleBingoMachine.super.scaleMainLayer(self)

    if display.height / display.width == 1228 / 768 then
        self.m_machineRootScale = self.m_machineRootScale + 0.03
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
    elseif display.height / display.width < 1228 / 768 and display.height / display.width >= 960 / 640 then
        local mul = (1228 / 768 - display.height / display.width) / (1228 / 768 - 960 / 640)
        self.m_machineRootScale = self.m_machineRootScale + 0.03 * mul + 0.03
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 16 * mul)
    elseif display.height / display.width < 960 / 640 and display.height / display.width >= 1024 / 768 then
        local mul = (960 / 640 - display.height / display.width) / (960 / 640 - 1024 / 768)
        self.m_machineRootScale = self.m_machineRootScale + 0.01 * mul + 0.06
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 8 * mul + 16)
    elseif display.height / display.width < 1024 / 768 then
        local mul = 1
        self.m_machineRootScale = self.m_machineRootScale + 0.01 * mul + 0.06
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 8 * mul + 16)
    end
end

function CodeGameScreenTripleBingoMachine:checkRemoveBigMegaEffect()
    CodeGameScreenTripleBingoMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

---
-- 显示五个元素在同一条线效果
function CodeGameScreenTripleBingoMachine:showEffect_FiveOfKind(effectData)
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end

function CodeGameScreenTripleBingoMachine:getPayTableCsbPath()
    local isATest = globalData.GameConfig:checkABtestGroupA("TripleBingoIcon")
    if not isATest then -- B组是直接解锁三个
        return "PayTableLayerTripleBingo_GroupB.csb"
    else 
        return CodeGameScreenTripleBingoMachine.super.getPayTableCsbPath(self)
    end
end

return CodeGameScreenTripleBingoMachine
