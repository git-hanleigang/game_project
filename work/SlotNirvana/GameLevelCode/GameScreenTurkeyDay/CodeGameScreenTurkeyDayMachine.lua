---
-- island li
-- 2019年1月26日
-- CodeGameScreenTurkeyDayMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "TurkeyDayPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenTurkeyDayMachine = class("CodeGameScreenTurkeyDayMachine", BaseNewReelMachine)

CodeGameScreenTurkeyDayMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenTurkeyDayMachine.m_pickRootSccale = 1.0

CodeGameScreenTurkeyDayMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenTurkeyDayMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenTurkeyDayMachine.SYMBOL_SCORE_BONUS_1 = 94
CodeGameScreenTurkeyDayMachine.SYMBOL_SCORE_BONUS_2 = 95

CodeGameScreenTurkeyDayMachine.EFFECT_LAST_SHOW_LINE = GameEffect.EFFECT_SELF_EFFECT - 2  --所有玩法结束后再连线
CodeGameScreenTurkeyDayMachine.EFFECT_FREE_BONUS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 3  --freeBonus玩法
CodeGameScreenTurkeyDayMachine.EFFECT_JACKPOT_BONUS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 4  --jackpotBonus玩法（多福多彩）
CodeGameScreenTurkeyDayMachine.EFFECT_TURN_BONUS_REWARD = GameEffect.EFFECT_SELF_EFFECT - 5  --普通bonus，先翻一遍（钱、free、jackpot都翻）；然后翻倍（有特殊bonus）
CodeGameScreenTurkeyDayMachine.EFFECT_TRIGGER_BUFF_ROLE = GameEffect.EFFECT_SELF_EFFECT - 6  --触发特殊bonus；播放动画
CodeGameScreenTurkeyDayMachine.EFFECT_FULL_SCREEN_BONUS = GameEffect.EFFECT_SELF_EFFECT - 7  --满屏bonus庆祝

CodeGameScreenTurkeyDayMachine.BASE_FS_RUN_STATES = 0
CodeGameScreenTurkeyDayMachine.COllECT_FS_RUN_STATES = 1

-- 构造函数
function CodeGameScreenTurkeyDayMachine:ctor()
    CodeGameScreenTurkeyDayMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeTurkeyDaySrc.TurkeyDaySymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("TurkeyDayLongRunControl",self) 

    -- 大赢光效
    self.m_isAddBigWinLightEffect = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    -- 触发玩法前连线时间
    self.m_delayTime = 0
    -- 是否玩法结束连线
    self.m_isLastShowLine = true
    -- 下一次basespin使用的假滚卷轴,默认为True，Ture使用bonus假滚，False使用sc假滚
    self.m_reelIsBonus = true

    self.ENUM_REWARD_TYPE = 
    {
        COINS_REWARD = 1,
        FREE_REWARD = 2,
        JACKPOT_REWARD = 3,
        BUFF_REWARD = 4,
    }

    -- 当前scatter落地的个数
    self.m_curScatterBulingCount = 0
    -- 当前bonus变钱时音效的index
    self.m_curBonusEffectIndex = 0
    --init
    self:initGame()
end

function CodeGameScreenTurkeyDayMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("TurkeyDayConfig.csv", "LevelTurkeyDayConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTurkeyDayMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "TurkeyDay"  
end

function CodeGameScreenTurkeyDayMachine:getBottomUINode()
    return "CodeTurkeyDaySrc.TurkeyDayBottomNode"
end

function CodeGameScreenTurkeyDayMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    --多福多彩
    self.m_colorfulGameView = util_createView("CodeTurkeyDaySrc.TurkeyDayColorfulGame",{machine = self})
    self:addChild(self.m_colorfulGameView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_colorfulGameView:setVisible(false) 

    self:initJackPotBarView()

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("base_reel")
    self.m_reelBg[2] = self:findChild("free_reel")

    -- 背景
    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("base")
    self.m_bgType[2] = self.m_gameBg:findChild("fg")
    self.m_bgType[3] = self.m_gameBg:findChild("pick")

    -- 顶部tips
    self.m_tipsAni = util_createAnimation("TurkeyDay_base_tips.csb")
    self:findChild("base_tips"):addChild(self.m_tipsAni)

    --触发bonus玩法遮罩
    self.m_maskAni = util_createAnimation("TurkeyDay_qipan_yaan.csb")
    self.m_onceClipNode:addChild(self.m_maskAni, 10000)
    self.m_maskAni:setVisible(false)

    self.m_topEffectNode = self:findChild("Node_topEffect")

    -- 右侧老母鸡槽的位置
    self.m_chickNodeTbl = {}
    for i=1, 2 do
        self.m_chickNodeTbl[i] = self:findChild("Node_ji_"..i)
    end

    -- 右侧玩法bonusNode(插槽上的小鸡)
    self.m_chickBonusNodeTbl = {}
    -- 右侧玩法bonusNode(插槽上的字体)
    self.m_chickBonusTextNodeTbl = {}

    self.m_skip_click = self:findChild("Panel_skip_click")
    self.m_skip_click:setVisible(false)
    self:addClick(self.m_skip_click)
   
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitTurnNode = cc.Node:create()
    self:addChild(self.m_scWaitTurnNode)

    self.m_colorfulGameView:scaleMainLayer(self.m_pickRootSccale)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenTurkeyDayMachine:initSpineUI()
    -- 大角色
    self.m_roleSpine = util_spineCreate("Socre_TurkeyDay_Scatter",true,true)
    self:findChild("basefree_juese"):addChild(self.m_roleSpine)
    self:setRightRoleIdle()

    -- 全屏bonus庆祝动画
    self.m_fullScreenSpine = util_spineCreate("TurkeyDay_qiuzhu",true,true)
    self:findChild("Node_qingzhu"):addChild(self.m_fullScreenSpine)
    self.m_fullScreenSpine:setVisible(false)

    -- 大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("TurkeyDay_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_bigWinSpine:setVisible(false)

    -- 鸡窝上层
    self.m_henHouseTopAni, self.m_henHouseTopSpine = self:createHenHouse(true)
    self.m_henHouseTopSpine:setVisible(false)

    -- 鸡窝下层
    self.m_henHouseBottomAni, self.m_henHouseBottomSpine = self:createHenHouse()
    self.m_henHouseBottomSpine:setVisible(false)

    -- 右侧鸡窝附加动画
    self.m_rightOtherSpine = util_spineCreate("TurkeyDay_ywzd",true,true)
    self:findChild("Node_ywzd"):addChild(self.m_rightOtherSpine)
    self.m_rightOtherSpine:setVisible(false)

    -- 预告中奖
    self.m_yuGaoSpine = util_spineCreate("TurkeyDay_yugao",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpine)
    self.m_yuGaoSpine:setVisible(false)

    -- base-free过场
    self.m_baseToFreeSpine = util_spineCreate("TurkeyDay_guochang3",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_baseToFreeSpine)
    self.m_baseToFreeSpine:setVisible(false)

    -- free-base过场
    self.m_freeToBaseSpine = util_spineCreate("TurkeyDay_guochang1",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_freeToBaseSpine)
    self.m_freeToBaseSpine:setVisible(false)

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))
    -- pick过场
    self.m_pickCutSceneSpine = util_spineCreate("TurkeyDay_guochang1",true,true)
    self.m_pickCutSceneSpine:setPosition(worldPos)
    self.m_pickCutSceneSpine:setScale(self.m_machineRootScale)
    self:addChild(self.m_pickCutSceneSpine, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_pickCutSceneSpine:setVisible(false)

    self:changeBgSpine(1)
    self:setTipsIdle(1)
end

function CodeGameScreenTurkeyDayMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 3, 0, 1)
    end)
end

function CodeGameScreenTurkeyDayMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTurkeyDayMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenTurkeyDayMachine:initGameUI()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgSpine(2)
    end
    -- 如果上次有bonus玩法，需要用上次的轮盘
    self:setLastReelByBonusPlay()
    -- 设置上一次假滚的卷轴
    self:setLastReelFalseRollData()
end

function CodeGameScreenTurkeyDayMachine:addObservers()
    CodeGameScreenTurkeyDayMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

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

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_TurkeyDay_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_TurkeyDay_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenTurkeyDayMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTurkeyDayMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTurkeyDayMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_TurkeyDay_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_TurkeyDay_11"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_1 then
        return "Socre_TurkeyDay_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return "Socre_TurkeyDay_Bonus_tx"
    end
    
    return nil
end

-- 当前是否为bonus
function CodeGameScreenTurkeyDayMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_BONUS_1 or symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return true
    end

    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTurkeyDayMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenTurkeyDayMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

function CodeGameScreenTurkeyDayMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        local ratio = display.width / display.height
        if ratio >= 1370/768 then
            mainScale = 1
            mainPosY = mainPosY + 3
            self.m_pickRootSccale = mainScale
        elseif ratio >= 1228/768 then
            mainScale = mainScale * 0.9
            self.m_pickRootSccale = mainScale * 1.05
        elseif ratio >= 1152/768 and ratio < 1228/768 then
            mainScale = mainScale * 0.8
            self.m_pickRootSccale = mainScale * 1.05 --* 0.84
        elseif ratio < 1152/768 then
            mainScale = mainScale * 0.66
            mainPosY = mainPosY + 10
            self.m_pickRootSccale = mainScale * 1.05
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

--顶部补块
function CodeGameScreenTurkeyDayMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    if self:getCurSymbolIsBonus(symbolType)then
        symbolType = math.random(1, 10)
    end
    parentData.symbolType = symbolType
    if self.m_bigSymbolInfos[symbolType] ~= nil then
        parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    else
        parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    end
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenTurkeyDayMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 
end

function CodeGameScreenTurkeyDayMachine:initGameStatusData(gameData)
    CodeGameScreenTurkeyDayMachine.super.initGameStatusData(self, gameData)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTurkeyDayMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenTurkeyDayMachine:beginReel()
    self.collectBonus = false
    self.m_isLastShowLine = true
    CodeGameScreenTurkeyDayMachine.super.beginReel(self)
    if self:getCurSpinPlayState() then
        self:setNextRightRoleIdle()
    end
end

-- 重置jackpot玩法和free玩法状态
function CodeGameScreenTurkeyDayMachine:setCurSpinPlayState(_state)
    self.m_isHaveJackpotBonus = _state
    self.m_isHaverFreeBonus = _state
end

function CodeGameScreenTurkeyDayMachine:getCurSpinPlayState()
    if self.m_isHaveJackpotBonus or self.m_isHaverFreeBonus then
        return true
    end
    return false
end

--默认按钮监听回调
function CodeGameScreenTurkeyDayMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_skip_click" then
        self:runSkipCollect()
    end
end

function CodeGameScreenTurkeyDayMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local lastLineWinCoins = self:getClientWinCoins()
    local winRate = lastLineWinCoins / totalBet
    -- local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if lastLineWinCoins > 0 then
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 1.5
        elseif winRate > 3 and winRate <= 6 then
            showTime = 2.5
        elseif winRate > 6 then
            showTime = 3
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    return showTime
end

function CodeGameScreenTurkeyDayMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        -- self.m_clipParent:addChild(reelEffectNode, -1,SYMBOL_NODE_TAG * 100)
        self.m_onceClipNode:addChild(reelEffectNode, 20010)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        -- if reelType == "ccui.Layout" then
        --     reelEffectNode:setLocalZOrder(0)
        -- end
        reelEffectNode:setPosition(cc.p(reel:getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenTurkeyDayMachine:slotOneReelDown(reelCol)    
    CodeGameScreenTurkeyDayMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 
end

--[[
    滚轮停止
]]
function CodeGameScreenTurkeyDayMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    CodeGameScreenTurkeyDayMachine.super.slotReelDown(self)
    self.m_curScatterBulingCount = 0
end

function CodeGameScreenTurkeyDayMachine:setLastReelFalseRollData()
    if not self.m_runSpinResultData or not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 下一次basespin使用的假滚卷轴,默认为True，Ture使用bonus假滚，False使用sc假滚
    self.m_reelIsBonus = selfData.reelIsBonus
    if self.m_reelIsBonus then
        self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
    else
        self.m_fsReelDataIndex = self.COllECT_FS_RUN_STATES
    end
end

function CodeGameScreenTurkeyDayMachine:setLastReelByBonusPlay()
    if not self.m_runSpinResultData or not self.m_runSpinResultData.p_selfMakeData or 
        not self.m_runSpinResultData.p_selfMakeData.BonusIcons or #self.m_runSpinResultData.p_selfMakeData.BonusIcons < 1 then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 普通bonus
    local BonusIcons = selfData.BonusIcons
    --特殊bonus
    local buffIcons = selfData.buffIcons

    -- 轮盘信号
    local reelsData = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local posRow = self.m_iReelRowNum - iRow + 1
            local symbolType = reelsData[posRow][iCol]
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            self:changeSymbolCCBByName(slotNode, symbolType)
        end
    end

    -- 普通bonus
    local BonusIcons = clone(selfData.BonusIcons[#selfData.BonusIcons])
    -- 特殊bonus
    local buffIcons = clone(selfData.buffIcons[1])
    -- 本地排序
    local clientBonusData = self:getLocalSortData(BonusIcons, buffIcons)

    -- 判断是否有特殊bonus（多少倍）
    local buffMul = 1
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusReard = bonusData.p_bonusReard
        if bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
            buffMul = bonusReard + 1
        end
    end

    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusPos = bonusData.p_bonusPos
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
            local csbName,bindNode,skinName = self:getBindNodeInfo("coinsReward")
            symbolNode:changeSkin(skinName)
            local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
            self:setBonusCoinsColor(labelCsb, bonusReard)
            symbolNode:runAnim("actionframe_shouji_dan_idle", true)
        elseif bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
            local csbName,bindNode,skinName = self:getBindNodeInfo("freeReward")
            symbolNode:changeSkin(skinName)
            local zorder = symbolNode:getLocalZOrder()
            symbolNode:setLocalZOrder(zorder+10)
            local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
            self:setBonusFreeTimes(labelCsb, bonusReard, buffMul)
            symbolNode:runAnim("actionframe_shouji_dan_idle", true)
        elseif bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
            local csbName,bindNode,skinName = self:getBindNodeInfo("jackpotReward")
            symbolNode:changeSkin(skinName)
            local zorder = symbolNode:getLocalZOrder()
            symbolNode:setLocalZOrder(zorder+10)
            local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
            self:setBonusjackpotType(labelCsb, bonusReard, buffMul)
            symbolNode:runAnim("actionframe_shouji_dan_idle", true)
        elseif bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
            local skinName = "boost"
            if bonusReard > 1 then
                skinName = "boost"..bonusReard.."x"
            end
            symbolNode:changeSkin(skinName)
            symbolNode:runAnim("ji_idleframe_ke", true)
        end
    end

    -- 右侧老母鸡上添加bonus；初始化
    self:addRightPlayBonus(clientBonusData, self.ENUM_REWARD_TYPE.JACKPOT_REWARD, buffMul, 1)
end

-- 右侧老母鸡上添加bonus；初始化
function CodeGameScreenTurkeyDayMachine:addRightPlayBonus(_clientBonusData, _curType, _buffMul, _rightSlotPos)
    local clientBonusData = _clientBonusData
    local curType = _curType
    local buffMul = _buffMul
    local rightSlotPos = _rightSlotPos

    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusPos = bonusData.p_bonusPos
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode

        if curType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD and bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
            self.m_isHaveJackpotBonus = true
            local buffIdleName = "jh_idle_1"
            if buffMul > 1 then
                buffIdleName = "jh_idle_2"
            end

            -- 鸡盒上的字
            local textAni = util_createAnimation("Socre_TurkeyDay_Bonus_Jackpot.csb")
            for i=1, 4 do
                textAni:findChild("sp_jackpotCount_"..i):setVisible(i==buffMul)
            end
            self:addRightTextNode(textAni, 1, "jackpotReward")
            textAni:runCsbAction("idle", true)

            -- 鸡盒上的小鸡
            local csbName,bindNode,skinName = self:getBindNodeInfo("jackpotReward")
            local buffBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
            buffBonusNode:runAnim(buffIdleName, true)
            local spineNode = buffBonusNode:getNodeSpine()
            spineNode:setSkin(skinName)
            util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
            self:addRightBonus(buffBonusNode, 1, "jackpotReward")
            rightSlotPos = rightSlotPos + 1
        elseif curType == self.ENUM_REWARD_TYPE.FREE_REWARD and bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
            self.m_isHaverFreeBonus = true
            local buffIdleName = "jh_idle_1"
            if buffMul > 1 then
                buffIdleName = "jh_idle_2"
            end
            -- 鸡盒上的字
            local textAni = util_createAnimation("Socre_TurkeyDay_Bonus_FreeTimes.csb")
            for i=1, 4 do
                textAni:findChild("sp_freeCount_"..i):setVisible(i==buffMul)
                textAni:findChild("m_lb_num"):setString(bonusReard)
            end
            self:addRightTextNode(textAni, rightSlotPos, "freeReward")
            textAni:runCsbAction("idle", true)

            -- 鸡盒上的小鸡
            local csbName,bindNode,skinName = self:getBindNodeInfo("freeReward")
            local buffBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
            buffBonusNode:runAnim(buffIdleName, true)
            local spineNode = buffBonusNode:getNodeSpine()
            spineNode:setSkin(skinName)
            util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
            self:addRightBonus(buffBonusNode, rightSlotPos, "freeReward")
            rightSlotPos = rightSlotPos + 1
        elseif curType == self.ENUM_REWARD_TYPE.BUFF_REWARD and bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD and self:getCurSpinPlayState() then
            -- 鸡盒上的字
            local skinName = "boost"
            local mul = buffMul-1
            if buffMul > 1 then
                skinName = "boost"..mul.."x"
            end
            
            local textAni = util_createAnimation("Socre_TurkeyDay_Bonus_Buff_Right.csb")
            for i=1, 3 do
                textAni:findChild("Node_"..i):setVisible(i==mul)
            end
            self:addRightTextNode(textAni, 2, "buffReward")
            textAni:runCsbAction("idle", true)

            -- 鸡盒上的小鸡
            local buffBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_2)
            buffBonusNode:runAnim("jh_idleframe2", true)
            local spineNode = buffBonusNode:getNodeSpine()
            spineNode:setSkin(skinName)
            util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
            self:addRightBonus(buffBonusNode, 2, "buffReward")
        end
    end

    if curType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
        self:addRightPlayBonus(clientBonusData, self.ENUM_REWARD_TYPE.FREE_REWARD, buffMul, rightSlotPos)
    elseif curType == self.ENUM_REWARD_TYPE.FREE_REWARD then
        self:addRightPlayBonus(clientBonusData, self.ENUM_REWARD_TYPE.BUFF_REWARD, buffMul, rightSlotPos)
    end
end

-- 改为指定信号
function CodeGameScreenTurkeyDayMachine:changeSymbolCCBByName(_slotNode, _symbolType)
    if _slotNode.p_symbolImage then
        _slotNode.p_symbolImage:removeFromParent()
        _slotNode.p_symbolImage = nil
    end
    _slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, _symbolType), _symbolType)
    _slotNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, _symbolType))
end

---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenTurkeyDayMachine:addSelfEffect()
    self.m_isBonusPlay = false
    self.m_isHaveBuffBonus = false
    self:setCurSpinPlayState()
    self.m_delayTime = 0
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 普通bonus
    local BonusIcons = selfData.BonusIcons
    --特殊bonus
    local buffIcons = selfData.buffIcons
    -- jackpot（）多福多彩
    local jackpot = selfData.jackpot
    -- 下一次basespin使用的假滚卷轴,默认为True，Ture使用bonus假滚，False使用sc假滚
    self.m_reelIsBonus = selfData.reelIsBonus
    if self.m_reelIsBonus then
        self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
    else
        self.m_fsReelDataIndex = self.COllECT_FS_RUN_STATES
    end

    -- 是否全屏bonus
    if self:curSpinIsFullScreenBonus() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_FULL_SCREEN_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_FULL_SCREEN_BONUS -- 动画类型
    end

    if BonusIcons and next(BonusIcons) then
        self.m_isBonusPlay = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TURN_BONUS_REWARD -- 动画类型
    end

    -- 是否有jackpot（多福多彩玩法）
    if jackpot and next(jackpot) then
        self.m_isHaveJackpotBonus = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_JACKPOT_BONUS_PLAY -- 动画类型
    end

    -- 本次spin是否有freeBonus
    if self:getCurSpinIsHaveFreeBonus() then
        self.m_isHaverFreeBonus = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN - 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_FREE_BONUS_PLAY -- 动画类型
    end

    -- 触发bonus玩法前右侧老母鸡的触发动画
    if buffIcons and next(buffIcons) then
        self.m_isHaveBuffBonus = true
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = self.EFFECT_TRIGGER_BUFF_ROLE
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.EFFECT_TRIGGER_BUFF_ROLE -- 动画类型
    end

     -- 判断当前spin是否有连线
     local winLines = self.m_runSpinResultData.p_winLines or {}
     local delayTime = 0
    --  if self:getCurrSpinMode() ~= FREE_SPIN_MODE and #winLines > 0 then
     if #winLines > 0 then
        self.m_delayTime = 2
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_LAST_SHOW_LINE -- 动画类型
     end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTurkeyDayMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_FULL_SCREEN_BONUS then
        self:runFullScreenAct(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_TRIGGER_BUFF_ROLE then
        performWithDelay(self.m_scWaitNode, function()
            self:playRoleAction(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end, 0.5)
    elseif effectData.p_selfEffectType == self.EFFECT_TURN_BONUS_REWARD then
        self:showMask(true)
        performWithDelay(self.m_scWaitNode, function()
            self:playTurnBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, 1)
        end, self.m_delayTime)
    elseif effectData.p_selfEffectType == self.EFFECT_JACKPOT_BONUS_PLAY then
        self:playTriggerJackpotBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_FREE_BONUS_PLAY then
        self:playTriggerFreeBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_LAST_SHOW_LINE then
        self:playShowLine(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

-- 当前玩法是否满屏bonus玩法
function CodeGameScreenTurkeyDayMachine:curSpinIsFullScreenBonus()
    -- 轮盘信号
    local bonusCount = 0
    local reelsData = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local posRow = self.m_iReelRowNum - iRow + 1
            local symbolType = reelsData[posRow][iCol]
            if self:getCurSymbolIsBonus(symbolType) then
                bonusCount = bonusCount + 1
            end
        end
    end

    if bonusCount == self.m_iReelColumnNum*self.m_iReelRowNum then
        return true
    end

    return false
end

-- 当前玩法是否有freeBonus
function CodeGameScreenTurkeyDayMachine:getCurSpinIsHaveFreeBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 普通bonus
    local BonusIcons = selfData.BonusIcons
    if BonusIcons and next(BonusIcons) then
        for k, bonusData in pairs(BonusIcons[1]) do
            local bonusType = bonusData[1]
            if bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
                return true
            end
        end
    end

    return false
end

-- 右侧老母鸡动画idle
function CodeGameScreenTurkeyDayMachine:setRightRoleIdle(_isClear)
    util_spinePlay(self.m_roleSpine, "idleframe2_2", true)
    if _isClear then
        util_spineClearBindNode(self.m_roleSpine)
    end
end

-- 下次spin时，有bonus玩法需要恢复
function CodeGameScreenTurkeyDayMachine:setNextRightRoleIdle(_callFunc)
    local callFunc = _callFunc
    util_spinePlay(self.m_roleSpine, "actionframe_box_over", false)
    util_spineEndCallFunc(self.m_roleSpine, "actionframe_box_over", function()
        util_spineClearBindNode(self.m_roleSpine)
        self:setRightRoleIdle()
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

-- 右侧老母鸡上插槽添加小鸡
function CodeGameScreenTurkeyDayMachine:addRightBonus(_bonusNode, _index, _rewardType)
    local bonusNode = _bonusNode
    local bindName = "ji".._index
    local rewardType = _rewardType
    self.m_chickBonusNodeTbl[rewardType] = bonusNode
    util_spinePushBindNode(self.m_roleSpine,bindName,bonusNode)
end

-- 右侧老母鸡上插槽上字体
function CodeGameScreenTurkeyDayMachine:addRightTextNode(_textNode, _index, _rewardType)
    local textNode = _textNode
    local bindName = "zi".._index
    local rewardType = _rewardType
    self.m_chickBonusTextNodeTbl[rewardType] = textNode
    util_spinePushBindNode(self.m_roleSpine,bindName,textNode)
end

-- 老母鸡（scatter）收集动画
function CodeGameScreenTurkeyDayMachine:playRoleCollect()
    util_spinePlay(self.m_roleSpine, "actionframe_shouji", false)
    util_spineEndCallFunc(self.m_roleSpine, "actionframe_shouji", function()
        util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
    end)
end

-- 触发bonus玩法角色庆祝动画
function CodeGameScreenTurkeyDayMachine:playRoleActionByBonus(_callFunc)
    local callFunc = _callFunc
    util_spinePlay(self.m_roleSpine, "actionframe_qingzhu2", false)
    util_spineEndCallFunc(self.m_roleSpine, "actionframe_qingzhu2", function()
        util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

-- 角色庆祝动画
function CodeGameScreenTurkeyDayMachine:playRoleAction(_callFunc)
    local callFunc = _callFunc
    util_spinePlay(self.m_roleSpine, "actionframe_qingzhu", false)
    util_spineEndCallFunc(self.m_roleSpine, "actionframe_qingzhu", function()
        self:setRightRoleIdle(true)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

-- 全屏bonus庆祝动画
function CodeGameScreenTurkeyDayMachine:runFullScreenAct(_callFunc)
    local callFunc = _callFunc
    self.m_fullScreenSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FullScreenBonus_Sound)
    util_spinePlay(self.m_fullScreenSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_fullScreenSpine, "actionframe", function()
        self.m_fullScreenSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)

    local rootNode = self:findChild("Node_rootOther")

    local aniTime = 1.0
    util_shakeNode(rootNode,5,10,aniTime)
end

-- 播放bonus变钱音效（程序：30%的概率和bonus变金额bonus动画一起播。按顺序播每次播一个）
function CodeGameScreenTurkeyDayMachine:playBonusCoinsSoundEffect()
    local randomNum = math.random(1, 10)
    if randomNum <= 3 then
        self.m_curBonusEffectIndex = self.m_curBonusEffectIndex + 1
        if self.m_curBonusEffectIndex > 2 then
            self.m_curBonusEffectIndex = 1
        end
        local soundName = self.m_publicConfig.SoundConfig.Music_BonusCoins_Effect[self.m_curBonusEffectIndex]
        if soundName then
            gLobalSoundManager:playSound(soundName)
        end
    end
end

-- 普通bonus，先翻一遍（钱、free、jackpot都翻）；然后翻倍（有特殊bonus）
function CodeGameScreenTurkeyDayMachine:playTurnBonus(_callFunc, _curType)
    local callFunc = _callFunc
    self:clearWinLineEffect()
    self.m_scWaitTurnNode:stopAllActions()
    -- 当前奖励类型
    local curType = _curType
    if curType > self.ENUM_REWARD_TYPE.FREE_REWARD then
        performWithDelay(self.m_scWaitNode, function()
            self:playAddBuff(callFunc, 1)
        end, 18/30)
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 普通bonus
    local BonusIcons = clone(selfData.BonusIcons[1])
    -- 特殊bonus
    local buffIcons = clone(selfData.buffIcons[1])
    -- 本地排序
    local clientBonusData = self:getLocalSortData(BonusIcons, buffIcons)

    if curType == self.ENUM_REWARD_TYPE.COINS_REWARD then
        self:setMaxMusicBGVolume()
        self:setSkipData(function()
        self:playTurnBonus(callFunc, 2)
        end, true)
    end

    local isPlaySound = true
    local tblActionList = {}
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusPos = bonusData.p_bonusPos
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        if curType == self.ENUM_REWARD_TYPE.COINS_REWARD then
            if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    local csbName,bindNode,skinName = self:getBindNodeInfo("coinsReward")
                    symbolNode:changeSkin(skinName)
                    local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                    self:setBonusCoinsColor(labelCsb, bonusReard)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Coins_Sound)
                    -- 播放音效
                    if isPlaySound then
                        isPlaySound = false
                        self:playBonusCoinsSoundEffect()
                    end
                    symbolNode:runAnim("actionframe_pkpt", false, function()
                        symbolNode:runAnim("idle_1", true)
                    end)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
            elseif bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD or bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Crack_Sound)
                    symbolNode:runAnim("dan_dpk", false, function()
                        symbolNode:runAnim("dan_dpk_idle", true)
                    end)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
            elseif bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Crack_Sound)
                    symbolNode:runAnim("dan_idleframe3", false, function()
                        symbolNode:runAnim("dan_idleframe3_idle", true)
                    end)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
            end
        else
            if bonusType ~= self.ENUM_REWARD_TYPE.COINS_REWARD then
                if bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
                    local csbName,bindNode,skinName = self:getBindNodeInfo("freeReward")
                    symbolNode:changeSkin(skinName)
                    local zorder = symbolNode:getLocalZOrder()
                    symbolNode:setLocalZOrder(zorder+10)
                    local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                    self:setBonusFreeTimes(labelCsb, bonusReard, 1)

                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Speicla_Sound)
                        symbolNode:runAnim("actionframe_pkts", false, function()
                            symbolNode:runAnim("idle_1", true)
                        end)
                    end)
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
                elseif bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                    local csbName,bindNode,skinName = self:getBindNodeInfo("jackpotReward")
                    symbolNode:changeSkin(skinName)
                    local zorder = symbolNode:getLocalZOrder()
                    symbolNode:setLocalZOrder(zorder+10)
                    local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                    self:setBonusjackpotType(labelCsb, bonusReard, 1)
                    
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Speicla_Sound)
                        symbolNode:runAnim("actionframe_pkts", false, function()
                            symbolNode:runAnim("idle_1", true)
                        end)
                    end)
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
                elseif bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                    local skinName = "boost"
                    local actName = "ji_actionframe"
                    local idleName = "ji_idleframe2"
                    symbolNode:changeSkin(skinName)
                    
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Buff_Sound)
                        symbolNode:runAnim(actName, false, function()
                            symbolNode:runAnim(idleName, true)
                        end)
                    end)
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(24/30)
                end
            end
        end
    end

    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:setSkipData(nil, false)
        self:playTurnBonus(callFunc, curType+1)
    end)
    self.m_scWaitTurnNode:runAction(cc.Sequence:create(tblActionList))
end

-- 翻倍buff
function CodeGameScreenTurkeyDayMachine:playAddBuff(_callFunc, _curBuffMul)
    local callFunc = _callFunc
    -- 当前奖励翻倍索引
    local curBuffMul = _curBuffMul
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 特殊bonus
    local buffIcons = selfData.buffIcons[1]
    if self.m_isHaveBuffBonus then
        local tblActionList = {}
        local bonusPos = buffIcons[1]
        local maxBuffMul = buffIcons[2]
        if curBuffMul <= maxBuffMul then
            local fixPos = self:getRowAndColByPos(bonusPos)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)

            local skinName = "boost"
            local actName = "ji_actionframe"
            local idleName = "ji_idleframe2"
            local delayTime = 30/30
            local changeSkinDelayTime = 0
            if curBuffMul > 1 then
                actName = "ji_switchto"..curBuffMul.."x"
                skinName = "boost"..curBuffMul.."x"
                if curBuffMul == 2 then
                    delayTime = (40-7)/30
                    changeSkinDelayTime = 7/30
                else
                    delayTime = (40-18)/30
                    changeSkinDelayTime = 18/30
                end

                -- 金蛋（金鸡）升级
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_BuffBonus_Trigger_Sound)
                    symbolNode:runAnim(actName, false, function()
                        symbolNode:runAnim(idleName, true)
                    end)
                end)
                -- 第7帧从皮肤“boost”切换为“boost2x”；第18帧从皮肤“boost2x”切换为“boost3x”
                tblActionList[#tblActionList+1] = cc.DelayTime:create(changeSkinDelayTime)
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    symbolNode:changeSkin(skinName)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
            end
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:playAddMulReward(callFunc, curBuffMul)
            end)
            
            self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
        else
            self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.COINS_REWARD)
        end
    else
        self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.COINS_REWARD)
    end
end

-- 翻倍（有特殊bonus）先翻buff bonus
function CodeGameScreenTurkeyDayMachine:playAddMulReward(_callFunc, _curBuffMul)
    local callFunc = _callFunc
    -- 当前奖励翻倍索引
    local curBuffMul = _curBuffMul + 1

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 特殊bonus
    local buffIcons = selfData.buffIcons[1]
    -- 普通bonus
    local BonusIcons = clone(selfData.BonusIcons[curBuffMul])

    if self.m_isHaveBuffBonus and BonusIcons and next(BonusIcons) then
        -- if curBuffMul == 2 then
        --     self:showMask(true)
        -- end
        -- 本地排序
        local clientBonusData = self:getLocalSortData(BonusIcons, buffIcons)
        -- 默认为1倍基础上加，本地改数据+1
        local maxBuffMul = buffIcons[2] + 1
        if curBuffMul <= maxBuffMul then
            local tblActionList = {}
            local mul = curBuffMul-1
            for k, bonusData in pairs(clientBonusData) do
                local bonusType = bonusData.p_bonusType
                local bonusPos = bonusData.p_bonusPos
                local bonusReard = bonusData.p_bonusReard
                local symbolNode = bonusData.p_symbolNode
                
                if bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                    local feedBackName = "ji_actionframe_shijia"
                    if curBuffMul > 2 then
                        feedBackName = "ji_actionframe_shijia"..mul
                    end
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_BuffBonus_Trigger_Sound)
                        symbolNode:runAnim(feedBackName, false, function()
                            symbolNode:runAnim("ji_idleframe2", true)
                        end)
                    end)
                end
            end
            -- 反馈45帧
            tblActionList[#tblActionList+1] = cc.DelayTime:create(45/30)
            local feedBackName = "actionframe_buff"
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:playBuffFeedBack(feedBackName, mul)
            end)
            tblActionList[#tblActionList+1] = cc.DelayTime:create(30/30)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:playAddBonusReward(callFunc, curBuffMul)
            end)
            self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
        else
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    else
        if type(callFunc) == "function" then
            callFunc()
        end
    end
end

-- 翻倍（有特殊bonus）后翻普通bonus
function CodeGameScreenTurkeyDayMachine:playAddBonusReward(_callFunc, _curBuffMul)
    local callFunc = _callFunc
    -- 当前奖励翻倍索引
    local curBuffMul = _curBuffMul

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 特殊bonus
    local buffIcons = selfData.buffIcons[1]
    -- 普通bonus
    local BonusIcons = clone(selfData.BonusIcons[curBuffMul])

    if self.m_isHaveBuffBonus and BonusIcons and next(BonusIcons) then
        -- 本地排序
        local clientBonusData = self:getLocalSortData(BonusIcons, buffIcons)
        -- 默认为1倍基础上加，本地改数据+1
        local maxBuffMul = buffIcons[2] + 1
        if curBuffMul <= maxBuffMul then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Add_Buff_FeedBack_Sound)
            local tblActionList = {}
            local mul = curBuffMul-1
            for k, bonusData in pairs(clientBonusData) do
                local bonusType = bonusData.p_bonusType
                local bonusPos = bonusData.p_bonusPos
                local bonusReard = bonusData.p_bonusReard
                local symbolNode = bonusData.p_symbolNode
                
                if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                    local feedBackName = "actionframe_fklan_" .. mul
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        local csbName,bindNode,skinName = self:getBindNodeInfo("coinsReward")
                        symbolNode:changeSkin(skinName)
                        local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                        self:setBonusCoinsColor(labelCsb, bonusReard, true)
                        symbolNode:runAnim(feedBackName, false, function()
                            symbolNode:runAnim("idle_1", true)
                        end)
                    end)
                elseif bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
                    local feedBackName = "actionframe_fkhong_" .. mul
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        local csbName,bindNode,skinName = self:getBindNodeInfo("freeReward")
                        symbolNode:changeSkin(skinName)
                        local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                        self:setBonusFreeTimes(labelCsb, bonusReard, curBuffMul, true)
                        symbolNode:runAnim(feedBackName, false, function()
                            symbolNode:runAnim("idle_2", true)
                        end)
                    end)
                elseif bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                    local feedBackName = "actionframe_fkzi_" .. mul
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        local csbName,bindNode,skinName = self:getBindNodeInfo("jackpotReward")
                        symbolNode:changeSkin(skinName)
                        local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                        self:setBonusjackpotType(labelCsb, bonusReard, curBuffMul, true)
                        -- 添加锤子上node（插槽）
                        local nodeScore = self:getCurLevelCsbOnSymbol(symbolNode, "Socre_TurkeyDay_Bonus_Buff_Small.csb", "zi_guadian2")
                        for i=1, 3 do
                            nodeScore:findChild("Node_"..i):setVisible(i==mul)
                        end
                        symbolNode:runAnim(feedBackName, false, function()
                            symbolNode:runAnim("idle_2", true)
                        end)
                    end)
                end
            end
            -- 反馈45帧
            tblActionList[#tblActionList+1] = cc.DelayTime:create(45/30+0.5)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:playAddBuff(callFunc, curBuffMul)
            end)
            self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
        else
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    else
        if type(callFunc) == "function" then
            callFunc()
        end
    end
end

-- 最后收集奖励（按照类型收集）
function CodeGameScreenTurkeyDayMachine:collectAllReward(_callFunc, _curType)
    local callFunc = _callFunc
    -- 当前奖励类型
    local curType = _curType
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 特殊bonus
    local buffIcons = selfData.buffIcons[1]
    -- 普通bonus
    local BonusIcons = clone(selfData.BonusIcons[#selfData.BonusIcons])
    -- 本地排序
    local clientBonusData = self:getLocalSortData(BonusIcons, buffIcons)

    if curType > self.ENUM_REWARD_TYPE.BUFF_REWARD then
        self.m_topEffectNode:removeAllChildren()
        self:showMask(false)
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    -- 判断是否有特殊bonus（多少倍）
    local buffMul = 1
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusReard = bonusData.p_bonusReard
        if bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
            buffMul = bonusReard + 1
        end
    end

    local tblActionList = {}
    if curType == self.ENUM_REWARD_TYPE.COINS_REWARD then
        -- 有钱的奖励先显示鸡窝
        local curCount = 0
        for k, bonusData in pairs(clientBonusData) do
            local bonusType = bonusData.p_bonusType
            if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                curCount = curCount + 1
                if curCount == 1 then
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        self:showHenHouse(true)
                    end)
                    -- 鸡窝动画19帧
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(20/30)
                end
            end
        end

        -- 先收集钱
        if curCount > 0 then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:colectRewardCoins(function()
                    self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.JACKPOT_REWARD)
                end, clientBonusData, curCount)
            end)
        else
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.JACKPOT_REWARD)
            end)
        end
    elseif curType == self.ENUM_REWARD_TYPE.FREE_REWARD then
        -- 收集free
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:collectRewardFree(callFunc, clientBonusData, buffMul)
        end)
    elseif curType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
        -- 收集jackpot
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:collectRewardJackpot(callFunc, clientBonusData, buffMul)
        end)
    elseif curType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
        -- 收集加倍
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:collectRewardBuff(callFunc, clientBonusData, buffMul)
        end)
    end
    
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集奖励钱
function CodeGameScreenTurkeyDayMachine:colectRewardCoins(_callFunc, _clientBonusData, _totalCount)
    local callFunc = _callFunc
    local clientBonusData = _clientBonusData
    local totalCount = _totalCount

    local curCount = 0
    local curTotalCoins = 0
    local allFlyBonusTbl = {}
    local isRunFunc = true
    local isPlaySound = true
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusPos = bonusData.p_bonusPos
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        local fixPos = self:getRowAndColByPos(bonusPos)
        
        if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
            local tblActionList = {}
            curCount = curCount + 1
            self.collectBonus = true
            curTotalCoins = curTotalCoins + bonusReard

            local csbName,bindNode,skinName = self:getBindNodeInfo("coinsReward")
            symbolNode:changeSkin(skinName)
            local labelCsb, spine = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
            symbolNode:runAnim("actionframe_jiesuan_lan_dan", false, function()
                symbolNode:runAnim("actionframe_shouji_dan_idle", true)
            end)
            -- 飞走的鸡
            local flyBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
            local spineNode = flyBonusNode:getNodeSpine()
            spineNode:setSkin(skinName)
            local label = util_createAnimation(csbName)
            util_spinePushBindNode(spineNode,bindNode,label)
            self:setBonusCoinsColor(label, bonusReard)
            local startPos = self:getWorldToNodePos(self.m_henHouseNodeTbl[curCount], bonusPos)
            local effectStartPos = self:getWorldToNodePos(self.m_topEffectNode, bonusPos)
            local endPos = cc.p(0, 0)--util_convertToNodeSpace(self.m_henHouseNodeTbl[curCount], self.m_effectNode)
            flyBonusNode:setPosition(effectStartPos)
            self.m_topEffectNode:addChild(flyBonusNode, bonusPos)
            local endNode = self.m_henHouseNodeTbl[curCount]
            -- 30帧
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                if isPlaySound then
                    isPlaySound = false
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CollectBonusCoins_Sound)
                end
                flyBonusNode:runAnim("actionframe_jiesuan_lan_ji", false, function()
                    flyBonusNode:runAnim("actionframe_jiesuan_lan_idle", true)
                end)
            end)
            table.insert(allFlyBonusTbl, flyBonusNode)
            tblActionList[#tblActionList+1] = cc.DelayTime:create(10/30)
            -- 起飞的时候切父节点
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                util_changeNodeParent(endNode, flyBonusNode)
                flyBonusNode:setPosition(startPos)
                -- self.m_henHouseNodeTbl[curCount]:addChild(flyBonusNode)
            end)
            -- 第10--25帧程序控制位移
            local midPos = cc.p(startPos.x, startPos.y)
            if fixPos.iY < 2 then
                midPos = cc.p(startPos.x + 200, startPos.y)
            elseif fixPos.iY > 3 then
                midPos = cc.p(startPos.x - 200, startPos.y)
            end
            -- tblActionList[#tblActionList+1] = cc.EaseIn:create(cc.MoveTo:create(10/30, endPos), 2)--cc.MoveTo:create(10/30, endPos)
            tblActionList[#tblActionList + 1] = cc.EaseIn:create(cc.BezierTo:create(15/30, {startPos, midPos, endPos}), 2)
            -- tblActionList[#tblActionList + 1] = cc.BezierTo:create(10/30, {startPos, midPos, endPos})
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                if isRunFunc then
                    isRunFunc = false
                    self:endCollectHenHouse(callFunc, allFlyBonusTbl, curTotalCoins)
                end
            end)

            flyBonusNode:runAction(cc.Sequence:create(tblActionList))
        end
    end

    if curCount == 0 then
        if type(callFunc) == "function" then
            callFunc()
        end
    end
end

-- 钱收集完了，收集鸡窝
function CodeGameScreenTurkeyDayMachine:endCollectHenHouse(_callFunc, _allFlyBonusTbl, _totalRewardCoins)
    local callFunc = _callFunc
    local allFlyBonusTbl = _allFlyBonusTbl
    local totalRewardCoins = _totalRewardCoins

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        local params = {
            overCoins  = totalRewardCoins,
            jumpTime   = 1.5,
            animName   = "actionframe3",
        }

        local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
        --刷新顶栏
        local isNotifyUpdateTop = false
        if not bFree and not bLine and not self.m_isHaveJackpotBonus then
            isNotifyUpdateTop = true
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end
        self:playBottomBigWinLabAnim(params)
        self:playBottomLight(totalRewardCoins, true, isNotifyUpdateTop)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_RewardCoins_Jump_Sound)
        -- actionframe_jiesuan（0，24）、actionframe_jiesuan2（0，24）
        util_spinePlay(self.m_henHouseTopSpine, "actionframe_jiesuan", false)
        util_spinePlay(self.m_henHouseBottomSpine, "actionframe_jiesuan2", false)
    end)
    -- -- actionframe_jiesuan_lan_ji第19帧开始播
    -- tblActionList[#tblActionList+1] = cc.DelayTime:create(19/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        for k, flyBonusNode in pairs(allFlyBonusTbl) do
            if not tolua.isnull(flyBonusNode) then
                local spineNode = flyBonusNode:getNodeSpine()
                --清理绑定节点
                util_spineClearBindNode(spineNode)
            end
        end
    end)
    -- actionframe_jiesuan_lan_ji -- 30帧
    tblActionList[#tblActionList+1] = cc.DelayTime:create(24/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(self.m_henHouseTopSpine, "idleframe", true)
        util_spinePlay(self.m_henHouseBottomSpine, "idleframe2", true)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(35/30)
    -- 鸡窝消失（weiyi（0，10）over（0，7）over2（0，23））
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_henHouseBottomAni:runCsbAction("weiyi", false)
    end)
    -- weiyi播到第10帧再播二进制时间线over和over2
    tblActionList[#tblActionList+1] = cc.DelayTime:create(10/60)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(self.m_henHouseTopSpine, "over", false)
        util_spinePlay(self.m_henHouseBottomSpine, "over2", false)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(23/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:showHenHouse(false)
    end)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if not self:checkHasBigWin() and not self.m_isHaveJackpotBonus then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end
        if type(callFunc) == "function" then
            callFunc()
        end
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集Jackopt（多福多彩）到右侧老母鸡上
function CodeGameScreenTurkeyDayMachine:collectRewardJackpot(_callFunc, _clientBonusData, _buffMul)
    local callFunc = _callFunc
    local clientBonusData = _clientBonusData
    local buffMul = _buffMul

    self.m_topEffectNode:removeAllChildren()
    local actName = "actionframe_shouji_dan1"
    local idleName = "actionframe_shouji_dan_idle"
    local flyActName = "actionframe_shouji_ji1"
    local buffIdleName = "jh_idle_1"
    if buffMul > 1 then
        actName = "actionframe_shouji_dan2"
        flyActName = "actionframe_shouji_ji2"
        buffIdleName = "jh_idle_2"
    end

    local isHaveJackpot = false
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusPos = bonusData.p_bonusPos
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        
        if bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
            isHaveJackpot = true
            local tblActionList = {}

            -- 鸡盒出现 actionframe_box_start（0，23）
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Role_ShowBox)
                util_spinePlay(self.m_roleSpine, "actionframe_box_start", false)
                util_spineEndCallFunc(self.m_roleSpine, "actionframe_box_start", function()
                    util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
                end)
            end)

            tblActionList[#tblActionList+1] = cc.DelayTime:create(23/30)

            local csbName,bindNode,skinName = self:getBindNodeInfo("jackpotReward")
            symbolNode:changeSkin(skinName)
            -- 往右侧飞bonus
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_SpecialBonus)
                symbolNode:runAnim(actName, false, function()
                    symbolNode:runAnim(idleName, true)
                end)
            end)
            
            -- 飞走的鸡
            local flyBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
            local spineNode = flyBonusNode:getNodeSpine()
            spineNode:setSkin(skinName)
            local label = util_createAnimation(csbName)
            util_spinePushBindNode(spineNode,bindNode,label)
            self:setBonusjackpotType(label, bonusReard, buffMul)
            local startPos = self:getWorldToNodePos(self.m_topEffectNode, bonusPos)
            local endPos = util_convertToNodeSpace(self.m_chickNodeTbl[1], self.m_topEffectNode)
            flyBonusNode:setPosition(startPos)
            flyBonusNode:setVisible(false)
            self.m_topEffectNode:addChild(flyBonusNode, 100)
            -- 27帧
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                flyBonusNode:setVisible(true)
                flyBonusNode:runAnim(flyActName, false, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_SpecialBonusFeedBack)
                    flyBonusNode:setVisible(false)
                end)
            end)
            tblActionList[#tblActionList+1] = cc.DelayTime:create(8/30)
            -- 第8--27帧程序控制位移
            local midPos = cc.p(startPos.x + 200, startPos.y)
            -- tblActionList[#tblActionList+1] = cc.EaseIn:create(cc.MoveTo:create(12/30, endPos), 2)--cc.MoveTo:create(10/30, endPos)
            -- tblActionList[#tblActionList + 1] = cc.EaseIn:create(cc.BezierTo:create(19/30, {startPos, midPos, endPos}), 2)
            tblActionList[#tblActionList + 1] = cc.EaseSineInOut:create(cc.BezierTo:create(18/30, {startPos, midPos, endPos}))
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                flyBonusNode:setVisible(false)
                self:playRoleCollect()
                -- 鸡盒上的字
                local textAni = util_createAnimation("Socre_TurkeyDay_Bonus_Jackpot.csb")
                for i=1, 4 do
                    textAni:findChild("sp_jackpotCount_"..i):setVisible(i==buffMul)
                end
                self:addRightTextNode(textAni, 1, "jackpotReward")
                textAni:runCsbAction("start", false, function()
                    textAni:runCsbAction("idle", true)
                end)

                -- 鸡盒上的小鸡
                local buffBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
                buffBonusNode:runAnim(buffIdleName, true)
                local spineNode = buffBonusNode:getNodeSpine()
                spineNode:setSkin(skinName)
                self:addRightBonus(buffBonusNode, 1, "jackpotReward")
            end)
            -- 字体动画30帧
            tblActionList[#tblActionList+1] = cc.DelayTime:create(30/60)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.FREE_REWARD)
            end)
            flyBonusNode:runAction(cc.Sequence:create(tblActionList))
        end
    end

    if not isHaveJackpot then
        self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.FREE_REWARD)
    end
end

-- 收集free到右侧老母鸡上
function CodeGameScreenTurkeyDayMachine:collectRewardFree(_callFunc, _clientBonusData, _buffMul)
    local callFunc = _callFunc
    local clientBonusData = _clientBonusData
    local buffMul = _buffMul

    self.m_topEffectNode:removeAllChildren()
    local actName = "actionframe_shouji_dan1"
    local idleName = "actionframe_shouji_dan_idle"
    local flyActName = "actionframe_shouji_ji1"
    local buffIdleName = "jh_idle_1"
    if buffMul > 1 then
        actName = "actionframe_shouji_dan2"
        flyActName = "actionframe_shouji_ji2"
        buffIdleName = "jh_idle_2"
    end

    -- 判断是否有jackpot玩法（用于鸡盒的位置）
    local rightSlotPos = 1
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        if bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
            rightSlotPos = 2
        end
    end

    local isHaveFree = false
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        local bonusPos = bonusData.p_bonusPos
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        
        if bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
            isHaveFree = true
            local tblActionList = {}

            -- 鸡盒出现 actionframe_box_start（0，23）
            if rightSlotPos == 1 then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Role_ShowBox)
                    util_spinePlay(self.m_roleSpine, "actionframe_box_start", false)
                    util_spineEndCallFunc(self.m_roleSpine, "actionframe_box_start", function()
                        util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
                    end)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(23/30)
            end

            local csbName,bindNode,skinName = self:getBindNodeInfo("freeReward")
            symbolNode:changeSkin(skinName)
            
            -- 往右侧飞bonus
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_SpecialBonus)
                symbolNode:runAnim(actName, false, function()
                    symbolNode:runAnim(idleName, true)
                end)
            end)
            
            -- 飞走的鸡
            local flyBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
            local spineNode = flyBonusNode:getNodeSpine()
            spineNode:setSkin(skinName)
            local label = util_createAnimation(csbName)
            util_spinePushBindNode(spineNode,bindNode,label)
            self:setBonusFreeTimes(label, bonusReard, buffMul)
            local startPos = self:getWorldToNodePos(self.m_topEffectNode, bonusPos)
            local endPos = util_convertToNodeSpace(self.m_chickNodeTbl[rightSlotPos], self.m_topEffectNode)
            flyBonusNode:setPosition(startPos)
            flyBonusNode:setVisible(false)
            self.m_topEffectNode:addChild(flyBonusNode, 100)
            -- 27帧
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                flyBonusNode:setVisible(true)
                flyBonusNode:runAnim(flyActName, false, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_SpecialBonusFeedBack)
                    flyBonusNode:setVisible(false)
                end)
            end)
            tblActionList[#tblActionList+1] = cc.DelayTime:create(8/30)
            -- 第8--27帧程序控制位移
            local midPos = cc.p(startPos.x + 200, startPos.y)
            -- tblActionList[#tblActionList+1] = cc.EaseIn:create(cc.MoveTo:create(12/30, endPos), 2)--cc.MoveTo:create(10/30, endPos)
            -- tblActionList[#tblActionList + 1] = cc.EaseIn:create(cc.BezierTo:create(12/30, {startPos, midPos, endPos}), 2)
            tblActionList[#tblActionList + 1] = cc.EaseSineInOut:create(cc.BezierTo:create(18/30, {startPos, midPos, endPos}))
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                flyBonusNode:setVisible(false)
                self:playRoleCollect()
                -- 鸡盒上的字
                local textAni = util_createAnimation("Socre_TurkeyDay_Bonus_FreeTimes.csb")
                for i=1, 4 do
                    textAni:findChild("sp_freeCount_"..i):setVisible(i==buffMul)
                    textAni:findChild("m_lb_num"):setString(bonusReard)
                end
                self:addRightTextNode(textAni, rightSlotPos, "freeReward")
                textAni:runCsbAction("start", false, function()
                    textAni:runCsbAction("idle", true)
                end)

                -- 鸡盒上的小鸡
                local buffBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_1)
                buffBonusNode:runAnim(buffIdleName, true)
                local spineNode = buffBonusNode:getNodeSpine()
                spineNode:setSkin(skinName)
                self:addRightBonus(buffBonusNode, rightSlotPos, "freeReward")
            end)
            -- 字体动画30帧
            tblActionList[#tblActionList+1] = cc.DelayTime:create(30/60)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.BUFF_REWARD)
            end)
            flyBonusNode:runAction(cc.Sequence:create(tblActionList))
        end
    end

    if not isHaveFree then
        self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.BUFF_REWARD)
    end
end

-- 收集加倍（buff）到右侧老母鸡上
function CodeGameScreenTurkeyDayMachine:collectRewardBuff(_callFunc, _clientBonusData, _buffMul)
    local callFunc = _callFunc
    local clientBonusData = _clientBonusData
    local buffMul = _buffMul

    self.m_topEffectNode:removeAllChildren()
    local actName = "ji_actionframe_shouji"
    local idleName = "ji_idleframe_ke"
    local flyActName = "ji_actionframe_shouji2"
    local buffIdleName = "jh_idleframe2"

    local isHaveSpecialPlay = false
    -- 判断是否有jackpot玩法或者free玩法（如果只有钱，不收集buff）
    for k, bonusData in pairs(clientBonusData) do
        local bonusType = bonusData.p_bonusType
        if bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD or bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD then
            isHaveSpecialPlay = true
        end
    end

    local isHaveBuff = false
    if isHaveSpecialPlay then
        for k, bonusData in pairs(clientBonusData) do
            local bonusType = bonusData.p_bonusType
            local bonusPos = bonusData.p_bonusPos
            local bonusReard = bonusData.p_bonusReard
            local symbolNode = bonusData.p_symbolNode
            
            if bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                isHaveBuff = true
                local tblActionList = {}
                local skinName = "boost"
                local mul = buffMul-1
                if mul > 1 then
                    skinName = "boost"..mul.."x"
                end
                symbolNode:changeSkin(skinName)
                
                -- 往右侧飞bonus
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_SpecialBonus)
                    symbolNode:runAnim(actName, false, function()
                        symbolNode:runAnim(idleName, true)
                    end)
                end)

                -- 飞走的鸡
                local flyBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_2)
                local spineNode = flyBonusNode:getNodeSpine()
                spineNode:setSkin(skinName)
                local startPos = self:getWorldToNodePos(self.m_topEffectNode, bonusPos)
                local endPos = util_convertToNodeSpace(self.m_chickNodeTbl[2], self.m_topEffectNode)
                flyBonusNode:setPosition(startPos)
                flyBonusNode:setVisible(false)
                self.m_topEffectNode:addChild(flyBonusNode, 100)
                -- 25帧
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    flyBonusNode:setVisible(true)
                    flyBonusNode:runAnim(flyActName, false, function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_SpecialBonusFeedBack)
                        flyBonusNode:setVisible(false)
                    end)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(12/30)
                -- 第12-31帧位移；ji_actionframe_shouji2（0.32）
                local midPos = cc.p(startPos.x + 200, startPos.y)
                -- tblActionList[#tblActionList+1] = cc.EaseIn:create(cc.MoveTo:create(12/30, endPos), 2)--cc.MoveTo:create(10/30, endPos)
                tblActionList[#tblActionList + 1] = cc.EaseSineInOut:create(cc.BezierTo:create(19/30, {startPos, midPos, endPos}))
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:playRoleCollect()
                end)
                -- tblActionList[#tblActionList+1] = cc.DelayTime:create(1/60)
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    flyBonusNode:setVisible(false)
                    -- 鸡盒上的字
                    local textAni = util_createAnimation("Socre_TurkeyDay_Bonus_Buff_Right.csb")
                    for i=1, 3 do
                        textAni:findChild("Node_"..i):setVisible(i==mul)
                    end
                    self:addRightTextNode(textAni, 2, "buffReward")
                    textAni:runCsbAction("start", false, function()
                        textAni:runCsbAction("idle", true)
                    end)

                    -- 鸡盒上的小鸡
                    local buffBonusNode = self:createTurkeyDaySymbol(self.SYMBOL_SCORE_BONUS_2)
                    buffBonusNode:runAnim(buffIdleName, true)
                    local spineNode = buffBonusNode:getNodeSpine()
                    spineNode:setSkin(skinName)
                    self:addRightBonus(buffBonusNode, 2, "buffReward")
                end)
                -- 字体动画30帧
                tblActionList[#tblActionList+1] = cc.DelayTime:create(30/60)
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.BUFF_REWARD+1)
                end)
                flyBonusNode:runAction(cc.Sequence:create(tblActionList))
            end
        end
    end
    if not isHaveSpecialPlay or not isHaveBuff then
        self:collectAllReward(callFunc, self.ENUM_REWARD_TYPE.BUFF_REWARD+1)
    end
end

-- bonus先触发
function CodeGameScreenTurkeyDayMachine:playTriggerJackpotBonus(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 特殊bonus
    local buffIcons = selfData.buffIcons[1]
    local actName = "jh_cf"
    local idleName = "jh_idle_1"
    if self.m_isHaveBuffBonus then
        actName = "jh_cf2"
        idleName = "jh_idle_2"
    end
    local jackpotBonusNode = self.m_chickBonusNodeTbl["jackpotReward"]
    local buffBonusNode = self.m_chickBonusNodeTbl["buffReward"]
    local jackpotTextNode = self.m_chickBonusTextNodeTbl["jackpotReward"]
    local buffTextNode = self.m_chickBonusTextNodeTbl["buffReward"]
    
    local tblActionList = {}
    -- actionframe_qingzhu2（0，80）
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Trigger_ColofulGame, 3, 0, 1)
        self:playRoleActionByBonus()
    end)
    -- 大角色触发动画播到“第20帧”时候播小鸡的  jh_cf
    tblActionList[#tblActionList+1] = cc.DelayTime:create(20/30)
    -- jh_cf（0，60）低等级小鸡；jh_cf2（0，60）高等级小鸡
    if not tolua.isnull(jackpotBonusNode) then
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            jackpotBonusNode:runAnim(actName, false, function()
                jackpotBonusNode:runAnim(idleName, true)
            end)
        end)
        -- jh_actionframe_cf（0,60）
        if not tolua.isnull(buffBonusNode) then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                buffBonusNode:runAnim("jh_actionframe_cf", false, function()
                    buffBonusNode:runAnim("jh_idleframe2", true)
                end)
            end)
        end
        if not tolua.isnull(jackpotTextNode) then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                jackpotTextNode:runCsbAction("actionframe", false, function()
                    jackpotTextNode:runCsbAction("idle", true)
                end)
            end)
        end
        if not tolua.isnull(buffTextNode) then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                buffTextNode:runCsbAction("actionframe", false, function()
                    buffTextNode:runCsbAction("idle", true)
                end)
            end)
        end
    end
    tblActionList[#tblActionList+1] = cc.DelayTime:create(60/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Jackpot_Bg)
        self:triggerRightPlaySpine(callFunc, self.ENUM_REWARD_TYPE.JACKPOT_REWARD)
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 右侧鸡窝触发玩法动画
function CodeGameScreenTurkeyDayMachine:triggerRightPlaySpine(_callFunc, _triggerType)
    local callFunc = _callFunc
    local triggerType = _triggerType

    local tblActionList = {}
    -- actionframe（0，32）
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_rightOtherSpine:setVisible(true)
        util_spinePlay(self.m_rightOtherSpine, "actionframe", false)
        util_spineEndCallFunc(self.m_rightOtherSpine, "actionframe", function()
            self.m_rightOtherSpine:setVisible(false)
        end)
    end)
    -- 当actionframe（0，32）播到第13帧时，大角色播idleframe2_wo
    tblActionList[#tblActionList+1] = cc.DelayTime:create(13/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(self.m_roleSpine, "idleframe2_wo", false)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(19/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if triggerType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
            -- 多福多彩
            self:showPickCutSceneAni(callFunc, true)
        elseif triggerType == self.ENUM_REWARD_TYPE.FREE_REWARD then
            if type(callFunc) == "function" then
                callFunc()
            end
        else
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 显示多福多彩界面
function CodeGameScreenTurkeyDayMachine:showColorfulView(_callFunc)
    local callFunc = _callFunc

    self:clearWinLineEffect()

    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    local bonusData = {
        jackpot = selfData.jackpot,    --奖励列表
        winJackpot = jackpotType        --获得的jackpot
    }

    --重置bonus界面
    self.m_colorfulGameView:resetView(bonusData,function()
        self:showJackpotView(winCoins, jackpotType, function()
            self:resetMusicBg()
            self:showPickCutSceneAni(callFunc)
        end)
    end)

    self.m_colorfulGameView:showView()
end

-- free最后触发
function CodeGameScreenTurkeyDayMachine:playTriggerFreeBonus(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 特殊bonus
    local buffIcons = selfData.buffIcons[1]
    local actName = "jh_cf"
    local idleName = "jh_idle_1"
    if self.m_isHaveBuffBonus then
        actName = "jh_cf2"
        idleName = "jh_idle_2"
    end
    local freeBonusNode = self.m_chickBonusNodeTbl["freeReward"]
    local buffBonusNode = self.m_chickBonusNodeTbl["buffReward"]
    local freeTextNode = self.m_chickBonusTextNodeTbl["freeReward"]
    local buffTextNode = self.m_chickBonusTextNodeTbl["buffReward"]

    local tblActionList = {}
    -- actionframe_qingzhu2（0，80）
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_RightFree_Trigger_Sound)
        self:playRoleActionByBonus()
    end)
    -- 大角色触发动画播到“第20帧”时候播小鸡的  jh_cf
    tblActionList[#tblActionList+1] = cc.DelayTime:create(20/30)
    -- jh_cf（0，60）低等级小鸡；jh_cf2（0，60）高等级小鸡
    if not tolua.isnull(freeBonusNode) then
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            freeBonusNode:runAnim(actName, false, function()
                freeBonusNode:runAnim(idleName, true)
            end)
        end)
        -- jh_actionframe_cf（0,60）
        if not tolua.isnull(buffBonusNode) then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                buffBonusNode:runAnim("jh_actionframe_cf", false, function()
                    buffBonusNode:runAnim("jh_idleframe2", true)
                end)
            end)
        end
        if not tolua.isnull(freeTextNode) then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                freeTextNode:runCsbAction("actionframe", false, function()
                    freeTextNode:runCsbAction("idle", true)
                end)
            end)
        end
        if not tolua.isnull(buffTextNode) then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                buffTextNode:runCsbAction("actionframe", false, function()
                    buffTextNode:runCsbAction("idle", true)
                end)
            end)
        end
    end
    tblActionList[#tblActionList+1] = cc.DelayTime:create(60/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 所有玩法结束后再连线
function CodeGameScreenTurkeyDayMachine:playShowLine(_callFunc)
    local callFunc = _callFunc
    self.m_isLastShowLine = false
    self:clearWinLineEffect()
    self:showLineFrame()
    if type(callFunc) == "function" then
        callFunc()
    end
end

-- 根据index转换需要节点坐标系
function CodeGameScreenTurkeyDayMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

-- 本地排序，填充数据
function CodeGameScreenTurkeyDayMachine:getLocalSortData(_BonusIcons, _buffIcons)
    local BonusIcons = _BonusIcons
    local buffIcons = _buffIcons
    if buffIcons and next(buffIcons) then
        local tempTbl = {}
        tempTbl[1] = self.ENUM_REWARD_TYPE.BUFF_REWARD
        tempTbl[2] = buffIcons[1]
        tempTbl[3] = buffIcons[2]
        table.insert(BonusIcons,tempTbl)
    end
    -- 本地排序
    local clientBonusData = {}
    for k, v in pairs(BonusIcons) do
        local tempTbl = {}
        local bonusType = v[1]
        local bonusPos = v[2]
        local bonusReard = v[3]
        local fixPos = self:getRowAndColByPos(bonusPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        tempTbl.p_bonusType = bonusType
        tempTbl.p_bonusPos = bonusPos
        tempTbl.p_bonusReard = bonusReard
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.p_symbolNode = symbolNode
        table.insert(clientBonusData, tempTbl)
    end

    -- 本地排序
    table.sort(clientBonusData, function(a, b)
        if a.p_cloumnIndex ~= b.p_cloumnIndex then
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
        if a.p_rowIndex ~= b.p_rowIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return false
    end)

    return clientBonusData
end

--[[
    获取小块spine槽点上绑定的csb节点
    csbName csb文件名称
    bindNodeName 槽点名称
]]
function CodeGameScreenTurkeyDayMachine:getCurLevelCsbOnSymbol(symbolNode,csbName,bindNodeName)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and tolua.isnull(spine.m_bindNodeScore) then
        local label = util_createAnimation(csbName)
        util_spinePushBindNode(spine,bindNodeName,label)
        spine.m_bindNodeScore = label
    end

    return spine.m_bindNodeScore,spine
end

function CodeGameScreenTurkeyDayMachine:getBindNodeInfo(_nodeType)
    local nodeType = _nodeType

    local csbName,bindNode,skinName

    if nodeType == "coinsReward" then
        csbName = "Socre_TurkeyDay_Bonus_Coins.csb"
        bindNode = "lan_guadian"
        skinName = "lan"
    elseif nodeType == "freeReward" then
        csbName = "Socre_TurkeyDay_Bonus_FreeTimes.csb"
        bindNode = "hong_guadian"
        skinName = "hong"
    elseif nodeType == "jackpotReward" then
        csbName = "Socre_TurkeyDay_Bonus_Jackpot.csb"
        bindNode = "zi_guadian1"
        skinName = "zi"
    end

    return csbName,bindNode,skinName
end

-- 设置bonus字体上的钱数和颜色
-- mul<=1.5  绿色
-- 1.5<mul<=2.5 蓝色
-- 2.5<mul  紫色
function CodeGameScreenTurkeyDayMachine:setBonusCoinsColor(_csbNode, _bonusReard, _isDelay)
    local isDelay = _isDelay
    local csbNode = _csbNode
    local bonusCoins = _bonusReard
    local curBet = globalData.slotRunData:getCurTotalBet()
    local rewardMul = bonusCoins/curBet
    local sScore =util_formatCoinsLN(bonusCoins, 3, true)
    csbNode:runCsbAction("idle", true)

    local delayTime = 0
    if isDelay then
        delayTime = 25/30
    end
    performWithDelay(self.m_scWaitNode, function()
        local textNameTbl = {"m_lb_coins_1", "m_lb_coins_2", "m_lb_coins_3"}

        for k, v in pairs(textNameTbl) do
            csbNode:findChild(v):setString(sScore)
            csbNode:findChild(v):setVisible(false)
            self:updateLabelSize({label=csbNode:findChild(v),sx=1.0,sy=1.0},142)
        end
        
        if rewardMul <= 1 then
            csbNode:findChild(textNameTbl[1]):setVisible(true)
        elseif rewardMul > 1 and rewardMul <= 2 then
            csbNode:findChild(textNameTbl[2]):setVisible(true)
        else
            csbNode:findChild(textNameTbl[3]):setVisible(true)
        end
    end, delayTime)
end

-- 设置bonus上的free次数
function CodeGameScreenTurkeyDayMachine:setBonusFreeTimes(_csbNode, _bonusReard, _freeType, _isDelay)
    local isDelay = _isDelay
    local csbNode = _csbNode
    local freeCount = _bonusReard
    local freeType = _freeType
    csbNode:runCsbAction("idle", true)

    local delayTime = 0
    if isDelay then
        delayTime = 25/30
    end

    performWithDelay(self.m_scWaitNode, function()
        local spFreeTypeNameTbl = {"sp_freeCount_1", "sp_freeCount_2", "sp_freeCount_3", "sp_freeCount_4"}
        for k, v in pairs(spFreeTypeNameTbl) do
            csbNode:findChild(v):setVisible(k==freeType)
        end

        csbNode:findChild("m_lb_num"):setString(freeCount)
    end, delayTime)
end

-- 设置bonus上的jackpot类型
function CodeGameScreenTurkeyDayMachine:setBonusjackpotType(_csbNode, _bonusReard, _jackpotType, _isDelay)
    local isDelay = _isDelay
    local csbNode = _csbNode
    local jackpotReward = _bonusReard
    local jackpotType = _jackpotType
    csbNode:runCsbAction("idle", true)

    local delayTime = 0
    if isDelay then
        delayTime = 25/30
    end

    performWithDelay(self.m_scWaitNode, function()
        local spJackpotTypeNameTbl = {"sp_jackpotCount_1", "sp_jackpotCount_2", "sp_jackpotCount_3", "sp_jackpotCount_4"}
        for k, v in pairs(spJackpotTypeNameTbl) do
            csbNode:findChild(v):setVisible(k==jackpotType)
        end
    end, delayTime)
end

-- 显示遮罩
function CodeGameScreenTurkeyDayMachine:showMask(_showState)
    local showState = _showState
    if _showState then
        if not self.m_maskAni:isVisible() then
            self.m_maskAni:setVisible(true)
            util_resetCsbAction(self.m_maskAni.m_csbAct)
            self.m_maskAni:runCsbAction("start", false, function()
                self.m_maskAni:runCsbAction("idle", true)
            end)
        end
    else
        if self.m_maskAni:isVisible() then
            util_resetCsbAction(self.m_maskAni.m_csbAct)
            self.m_maskAni:runCsbAction("over", false, function()
                self.m_maskAni:setVisible(false)
            end)
        end
    end
end

-- 显示鸡窝
function CodeGameScreenTurkeyDayMachine:showHenHouse(_showState)
    local showState = _showState
    self.m_henHouseTopAni:setVisible(showState)
    self.m_henHouseBottomAni:setVisible(showState)
    self.m_henHouseTopSpine:setVisible(showState)
    self.m_henHouseBottomSpine:setVisible(showState)

    for k, _node in pairs(self.m_henHouseNodeTbl) do
        _node:removeAllChildren()
    end

    if showState then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_BonusHouse_Appear_Sound)
        self.m_henHouseTopAni:runCsbAction("idle", true)
        self.m_henHouseBottomAni:runCsbAction("idle", true)
        util_spinePlay(self.m_henHouseTopSpine, "start", false)
        util_spinePlay(self.m_henHouseBottomSpine, "start2", false)
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenTurkeyDayMachine:showBigWinLight(func)
    local rootNode = self:findChild("Node_rootOther")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local actionframeName = "actionframe"
    if self.m_isBonusPlay then
        actionframeName = "actionframe2"
    end

    if self:getCurSpinPlayState() then
        self:playRoleActionByBonus()
    else
        self:playRoleAction()
    end

    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, actionframeName, false)
    util_spineEndCallFunc(self.m_bigWinSpine, actionframeName, function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime(actionframeName)
    util_shakeNode(rootNode,5,10,aniTime)
end

function CodeGameScreenTurkeyDayMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenTurkeyDayMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

function CodeGameScreenTurkeyDayMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    local randomNum = math.random(1, 10)
    if randomNum <= 3 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win_Effect)
    end
    return CodeGameScreenTurkeyDayMachine.super.showEffect_runBigWinLightAni(self,effectData)
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenTurkeyDayMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 8
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

function CodeGameScreenTurkeyDayMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenTurkeyDayMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenTurkeyDayMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FgMore_ScatterTrigger)
        else
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenTurkeyDayMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenTurkeyDayMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenTurkeyDayMachine:checkRemoveBigMegaEffect()
    CodeGameScreenTurkeyDayMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenTurkeyDayMachine:getShowLineWaitTime()
    local time = CodeGameScreenTurkeyDayMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenTurkeyDayMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeTurkeyDaySrc.TurkeyDayFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("free_spinbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenTurkeyDayMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("TurkeyDaySounds/music_TurkeyDay_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_baseFreeSpinBar:setFreeAni(true)
            local lightSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
            lightSpine:setVisible(false)

            local lightAni = util_createAnimation("TurkeyDay_tb_guang.csb")
            lightAni:runCsbAction("idleframe", true)

            local roleSpine = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
            roleSpine:setSkin("hong")
            util_spinePlay(roleSpine, "tb_hong_idle", true)

            performWithDelay(self.m_scWaitNode, function()
                lightSpine:setVisible(true)
                util_spinePlay(lightSpine, "title3_idle", false)
            end, 30/60)

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FgMore_Auto)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            view:findChild("wzsg"):addChild(lightSpine)
            view:findChild("zg"):addChild(lightAni)
            view:findChild("free_tb_juese_3"):addChild(roleSpine)
        else
            self.m_isHaveJackpotBonus = false
            self.m_isHaverFreeBonus = false
            local cutSceneFunc = function()
                performWithDelay(self.m_scWaitNode, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartOver)
                end, 5/60)
            end

            self:showBaseToFreeSceneAni(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end)

                local roleSpine_1 = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
                roleSpine_1:setSkin("hong")
                util_spinePlay(roleSpine_1, "tb_hong_idle", true)

                local roleSpine_2 = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
                roleSpine_2:setSkin("hong")
                roleSpine_2:setVisible(false)

                local lightAni = util_createAnimation("TurkeyDay_tb_guang.csb")
                lightAni:runCsbAction("idleframe", true)

                local lightSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
                lightSpine:setVisible(false)

                local btnLightSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
                btnLightSpine:setVisible(false)

                performWithDelay(self.m_scWaitNode, function()
                    util_spinePlay(roleSpine_1, "tb_hong_chan_di", false)
                    util_spineEndCallFunc(roleSpine_1, "tb_hong_chan_di", function()
                        util_spinePlay(roleSpine_1, "tb_hong_idle", true)
                    end)

                    roleSpine_2:setVisible(true)
                    util_spinePlay(roleSpine_2, "tb_hong_chan_shang", false)
                    util_spineEndCallFunc(roleSpine_2, "tb_hong_chan_shang", function()
                        roleSpine_2:setVisible(false)
                    end)
                end, 181/60)

                view.m_allowClick = false
                local time = view:getAnimTime("start")
                performWithDelay(self.m_scWaitNode, function()
                    view.m_allowClick = true
                    if not tolua.isnull(lightSpine) and not tolua.isnull(btnLightSpine) then
                        lightSpine:setVisible(true)
                        util_spinePlay(lightSpine, "title2_idle", true)

                        btnLightSpine:setVisible(true)
                        util_spinePlay(btnLightSpine, "anniu_idle", true)
                    end
                end, time)

                view:setBtnClickFunc(cutSceneFunc)
                view:findChild("free_tb_juese_3"):addChild(roleSpine_1)
                view:findChild("free_tb_juese_3shang"):addChild(roleSpine_2)
                view:findChild("zg"):addChild(lightAni)
                view:findChild("wzsg"):addChild(lightSpine)
                view:findChild("anniusg"):addChild(btnLightSpine)
                view:findChild("root"):setScale(self.m_machineRootScale)
                util_setCascadeOpacityEnabledRescursion(view, true)
            end)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

-- pick过场
function CodeGameScreenTurkeyDayMachine:showPickCutSceneAni(_callFunc, _isStart)
    local callFunc = _callFunc
    local isStart = _isStart
    self.m_pickCutSceneSpine:setVisible(true)
    -- actionframe_guochang2（0，105）
    local actName = "actionframe_guochang"
    if isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Colorful_CutScene)
        actName = "actionframe_guochang2"
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Colorful_Base_CutScene)
    end
    util_spinePlay(self.m_pickCutSceneSpine,actName,false)
    util_spineEndCallFunc(self.m_pickCutSceneSpine, actName, function()
        self.m_pickCutSceneSpine:setVisible(false)
        if not isStart then
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    end)
    
    -- 78帧切
    performWithDelay(self.m_scWaitNode, function()
        if isStart then
            self:changeBgSpine(3)
            self:showColorfulView(callFunc)
        else
            util_spinePlay(self.m_roleSpine, "idleframe2_3", true)
            self.m_colorfulGameView:hideView()
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:changeBgSpine(2)
            else
                self:changeBgSpine(1)
            end
        end
    end, 78/30)
end

-- free到base过场
function CodeGameScreenTurkeyDayMachine:showFreeToBaseSceneAni(_callFunc)
    local callFunc = _callFunc
    self.m_freeToBaseSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)
    util_spinePlay(self.m_freeToBaseSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_freeToBaseSpine, "actionframe_guochang", function()
        self.m_freeToBaseSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 78帧切
    performWithDelay(self.m_scWaitNode, function()
        self:changeBgSpine(1)
        self.m_baseFreeSpinBar:setVisible(false)
        self:setCurSpinPlayState()
        self:setRightRoleIdle(true)
    end, 78/30)
end

-- base到free过场
function CodeGameScreenTurkeyDayMachine:showBaseToFreeSceneAni(_callFunc)
    local callFunc = _callFunc
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
    self.m_baseToFreeSpine:setVisible(true)
    util_spinePlay(self.m_baseToFreeSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_baseToFreeSpine, "actionframe_guochang", function()
        self.m_baseToFreeSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 32帧切
    performWithDelay(self.m_scWaitNode, function()
        self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        self:setRightRoleIdle(true)
    end, 32/30)
end

function CodeGameScreenTurkeyDayMachine:showFreeSpinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 3, 0, 1)
    local strCoins = util_formatCoinsLN(globalData.slotRunData.lastWinCoin, 30)
    if globalData.slotRunData.lastWinCoin > 0 then
        local btnLightSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
        btnLightSpine:setVisible(false)

        local lightSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
        lightSpine:setVisible(false)

        local roleSpine = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
        roleSpine:setSkin("hong")
        util_spinePlay(roleSpine, "tb_hong_idle2", true)

        local scatterSpine = util_spineCreate("Socre_TurkeyDay_Scatter",true,true)
        util_spinePlay(scatterSpine, "idleframe2_tb", true)

        local cutSceneFunc = function()
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
            end, 5/60)
        end

        local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
            self:clearWinLineEffect()
            self:triggerRightPlaySpine(function()
                self:showFreeToBaseSceneAni(function()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        end)

        view.m_allowClick = false
        local time = view:getAnimTime("start")
        performWithDelay(self.m_scWaitNode, function()
            view.m_allowClick = true
            if not tolua.isnull(lightSpine) and not tolua.isnull(btnLightSpine) then
                lightSpine:setVisible(true)
                util_spinePlay(lightSpine, "title4_idle", true)

                btnLightSpine:setVisible(true)
                util_spinePlay(btnLightSpine, "anniu_idle", true)
            end
        end, time)

        view:setBtnClickFunc(cutSceneFunc)
        local node=view:findChild("m_lb_coins")
        view:findChild("anniusg"):addChild(btnLightSpine)
        view:findChild("wzsg"):addChild(lightSpine)
        view:findChild("free_tb_juese_1"):addChild(roleSpine)
        view:findChild("free_tb_juese_2"):addChild(scatterSpine)
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},711)
        view:findChild("root"):setScale(self.m_machineRootScale)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        local btnLightSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
        btnLightSpine:setVisible(false)

        local view = self:showFreeSpinOverNoWin(function()
            self:clearWinLineEffect()
            self:triggerRightPlaySpine(function()
                self:showFreeToBaseSceneAni(function()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        end)

        view.m_allowClick = false
        local time = view:getAnimTime("start")
        performWithDelay(self.m_scWaitNode, function()
            view.m_allowClick = true
            if not tolua.isnull(btnLightSpine) then
                btnLightSpine:setVisible(true)
                util_spinePlay(btnLightSpine, "anniu_idle", true)
            end
        end, time)

        view:findChild("anniusg"):addChild(btnLightSpine)
        util_setCascadeOpacityEnabledRescursion(view, true)
    end
end

function CodeGameScreenTurkeyDayMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FeatureOver",nil,_func)
    return view
end

function CodeGameScreenTurkeyDayMachine:showEffect_FreeSpin(effectData)
    local delayTime = 0
    if not self.m_isHaverFreeBonus then
        delayTime = 0.5
    end
    performWithDelay(self.m_scWaitNode, function()
        self.m_beInSpecialGameTrigger = true
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:clearCurMusicBg()
        end
        if not self.m_isHaverFreeBonus then
            self:playRoleAction()
        end

        self:levelDeviceVibrate(6, "free")
        local waitTime = 0
        if not self.m_isHaverFreeBonus then
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode then
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            local parent = slotNode:getParent()
                            if parent ~= self.m_clipParent then
                                slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                            else
                                slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 5)
                            end
                            slotNode:runAnim("actionframe", false, function()
                                slotNode:runAnim("idleframe2", true)
                            end)
                            
                            local duration = slotNode:getAniamDurationByName("actionframe")
                            waitTime = util_max(waitTime,duration)
                        end
                    end
                end
            end
            self:playScatterTipMusicEffect(true)
        end
        
        performWithDelay(self,function()
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, delayTime)
    return true    
end

function CodeGameScreenTurkeyDayMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeTurkeyDaySrc.TurkeyDayJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("basefree_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenTurkeyDayMachine:showJackpotView(coins,jackpotType,func)
    if not self:checkHasBigWin() then
        --检测大赢
        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
    end
    self:playBottomLight(coins, true, true)
    local view = util_createView("CodeTurkeyDaySrc.TurkeyDayJackpotWinView",{jackpotType = jackpotType, winCoin = coins, machine = self, func = function(  )
        if type(func) == "function" then
            func()
        end
    end})

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

function CodeGameScreenTurkeyDayMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenTurkeyDayMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenTurkeyDayMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenTurkeyDayMachine:updateReelGridNode(_symbolNode)
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
        local aniNode = _symbolNode:checkLoadCCbNode()     
        local spine = aniNode.m_spineNode
        if spine and not tolua.isnull(spine.m_bindCsbNode) then
            --清理绑定节点
            util_spineClearBindNode(spine)
        end
    end
end

function CodeGameScreenTurkeyDayMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

-- 创建鸡窝
-- 两层，底部UI上边一层，底部UI下边一层
function CodeGameScreenTurkeyDayMachine:createHenHouse(_isTop)
    local isTop = _isTop
    local henHouseAni = util_createAnimation("TurkeyDay_jiwo.csb")
    henHouseAni:runCsbAction("idle", true)
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    worldPos.y = worldPos.y - 25
    local bottomScale = self.m_machineRootScale
    if self.m_bottomUI and self.m_bottomUI.m_csbNode and self.m_bottomUI.m_csbNode:getScale() then
        bottomScale = self.m_bottomUI.m_csbNode:getScale()
    end
    henHouseAni:setScale(bottomScale)
    henHouseAni:setPosition(worldPos)

    local henHouseSpine = util_spineCreate("TurkeyDay_jiwo",true,true)

    -- 鸡窝上层
    if isTop then
        henHouseAni:findChild("Node_shang"):addChild(henHouseSpine)
        self:addChild(henHouseAni, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        henHouseAni:findChild("Node_other"):setVisible(false)
    else
        -- 鸡窝下层
        henHouseAni:findChild("Node_xia"):addChild(henHouseSpine)
        self:addChild(henHouseAni, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 10)

        -- 鸡窝上的节点
        self.m_henHouseNodeTbl = {}
        for i=1, 15 do
            self.m_henHouseNodeTbl[i] = henHouseAni:findChild("juese_"..i)
        end
    end

    return henHouseAni, henHouseSpine
end

function CodeGameScreenTurkeyDayMachine:createTurkeyDaySymbol(_symbolType)
    local symbol = util_createView("CodeTurkeyDaySrc.TurkeyDaySymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

-- respin开始，bonus往右侧飞的时候，在点击的时候跳过移除
function CodeGameScreenTurkeyDayMachine:setSkipData(func, _state)
    self.m_skipFunc = func
    self.m_skip_click:setVisible(_state)
    self.m_bottomUI:setSkipBtnVisible(_state)
end

function CodeGameScreenTurkeyDayMachine:runSkipCollect()
    self.m_skip_click:setVisible(false)
    if type(self.m_skipFunc) == "function" then
        self.m_scWaitTurnNode:stopAllActions()
        self.m_bottomUI:setSkipBtnVisible(false)

        local selfData = self.m_runSpinResultData.p_selfMakeData
        -- 普通bonus
        local BonusIcons = clone(selfData.BonusIcons[1])
        -- 特殊bonus
        local buffIcons = clone(selfData.buffIcons[1])
        -- 本地排序
        local clientBonusData = self:getLocalSortData(BonusIcons, buffIcons)

        local tblActionList = {}
        for k, bonusData in pairs(clientBonusData) do
            local bonusType = bonusData.p_bonusType
            local bonusPos = bonusData.p_bonusPos
            local bonusReard = bonusData.p_bonusReard
            local symbolNode = bonusData.p_symbolNode

            if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                local csbName,bindNode,skinName = self:getBindNodeInfo("coinsReward")
                symbolNode:changeSkin(skinName)
                local labelCsb = self:getLblCsbOnSymbol(symbolNode, csbName, bindNode)
                self:setBonusCoinsColor(labelCsb, bonusReard)
                symbolNode:runAnim("idle_1", true)
            elseif bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD or bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                symbolNode:runAnim("dan_dpk_idle", true)
            elseif bonusType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                symbolNode:runAnim("dan_idleframe3_idle", true)
            end
        end
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.3)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_skipFunc()
            self:setSkipData(nil, false)
        end)
        
        self.m_scWaitTurnNode:runAction(cc.Sequence:create(tblActionList))
    end
end

function CodeGameScreenTurkeyDayMachine:playBottomLight(_endCoins, _playEffect, _isNotifyUpdateTop)
    if _playEffect then
        self.m_bottomUI:playCoinWinEffectUI()
    end

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin, _isNotifyUpdateTop)
end

--BottomUI接口
function CodeGameScreenTurkeyDayMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenTurkeyDayMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

function CodeGameScreenTurkeyDayMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.pick
    for i=1, 3 do
        if i == _bgType then
            self.m_bgType[i]:setVisible(true)
        else
            self.m_bgType[i]:setVisible(false)
        end
    end
    
    if _bgType < 3 then
        self:setReelBgState(_bgType)
        if _bgType == 2 then
            self.m_tipsAni:setVisible(false)
            self:runCsbAction("idle_free", true)
        else
            self.m_tipsAni:setVisible(true)
            self:runCsbAction("idle_base", true)
        end
    else
        self:runCsbAction("idle_jackpot", true)
    end
end

function CodeGameScreenTurkeyDayMachine:setReelBgState(_bgType)
    for i=1, 2 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

function CodeGameScreenTurkeyDayMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 or not self.m_isLastShowLine then
        return
    end
    local lineWinCoins = self:getClientWinCoins()
    local bonusCoins = 0
    if self.m_isBonusPlay then
        bonusCoins = self:getCurBonusWinCoins()
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins-bonusCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount-bonusCoins)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

function CodeGameScreenTurkeyDayMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 and not self.m_isBonusPlay then
        notAdd = true
    end

    return notAdd
end

-- 获取bonus赢钱
function CodeGameScreenTurkeyDayMachine:getCurBonusWinCoins()
    local bonusCoins = 0
    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    if winCoins and winCoins > 0 then
        bonusCoins = bonusCoins + winCoins
    end

    -- 普通bonus
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local BonusIcons = selfData.BonusIcons
    if BonusIcons and next(BonusIcons) then
        for k, bonusData in pairs(BonusIcons[#selfData.BonusIcons]) do
            local bonusType = bonusData[1]
            local bonusReard = bonusData[3]
            if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                bonusCoins = bonusCoins + bonusReard
            end
        end
    end
    return bonusCoins
end

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
function CodeGameScreenTurkeyDayMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    local isTriggerBonusPlay = self:getCurSpinIsTriggerBonusPlay()
    
    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 or isTriggerBonusPlay then
        -- 出现预告动画概率默认为30%
        local probability = 30
        if _probability then
            probability = _probability
        end
        local isNotice = (math.random(1, 100) <= probability) 
        return isNotice
    end
    
    return false
end

-- 若本次Spin触发Fortune Coin Boost且玩家能达到大赢或触发FG/JACKPOT ,40%概率播放
function CodeGameScreenTurkeyDayMachine:getCurSpinIsTriggerBonusPlay()
    local isTriggerBonusPlay = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 普通bonus
    local BonusIcons = selfData.BonusIcons
    --特殊bonus
    local buffIcons = selfData.buffIcons
    if BonusIcons and next(BonusIcons) then
        for k, bonusData in pairs(BonusIcons[1]) do
            local bonusType = bonusData[1]
            if bonusType == self.ENUM_REWARD_TYPE.FREE_REWARD or bonusType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                isTriggerBonusPlay = true
                break
            end
        end

        -- if not isTriggerBonusPlay and buffIcons and next(buffIcons) then
        --     local totalWinCoins = self.m_runSpinResultData.p_winAmount or 0
        --     isTriggerBonusPlay = self:getCurRewardCoinsIsBigWin(totalWinCoins)
        -- end
    end

    return isTriggerBonusPlay
end

-- 获取当前赢钱是否触发bigwin
function CodeGameScreenTurkeyDayMachine:getCurRewardCoinsIsBigWin(_rewardCoins)
    local rewardCoins = _rewardCoins
    local curBet = globalData.slotRunData:getCurTotalBet()
    local mul = rewardCoins/curBet
    local iBigWinLimit = self.m_BigWinLimitRate
    if mul >= iBigWinLimit then
        return true
    end
    return false
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenTurkeyDayMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance(40) and not self:getCurSpinPlayState() then
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
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

-- 乘倍配合预告buff动画
function CodeGameScreenTurkeyDayMachine:playBuffFeedBack(_actName, _mul)
    local actName = _actName
    local mul = _mul
    self.m_yuGaoSpine:setVisible(true)
    local soundName = self.m_publicConfig.SoundConfig.Music_Buff_Trigger[mul]
    if soundName then
        gLobalSoundManager:playSound(soundName)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Add_Buff_Sound)
    util_spinePlay(self.m_yuGaoSpine, actName, false)
    util_spineEndCallFunc(self.m_yuGaoSpine, actName, function()
        self.m_yuGaoSpine:setVisible(false)
    end)
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenTurkeyDayMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)
    util_spinePlay(self.m_roleSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_roleSpine, "actionframe_yugao", function()
        self:setRightRoleIdle()
    end) 

    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe_yugao", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenTurkeyDayMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0    
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenTurkeyDayMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        if self.m_reelIsBonus then
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndexScatter(parentData.cloumnIndex)
        end
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

-- 播放顶部文案
function CodeGameScreenTurkeyDayMachine:setTipsIdle(_curIndex)
    local curIndex = _curIndex
    if curIndex >= 3 then
        curIndex = 1
    end

    local idleNameTbl = {"TurkeyDay_base_wenzi1_1", "TurkeyDay_base_wenzi2_2", "TurkeyDay_base_wenzi3_3"}
    for i=1, 3 do
        self.m_tipsAni:findChild(idleNameTbl[i]):setVisible(i == curIndex)
    end

    util_resetCsbAction(self.m_tipsAni.m_csbAct)
    -- 间隔播放
    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_tipsAni:runCsbAction("start", false, function()
            self.m_tipsAni:runCsbAction("idle", true)
        end)
    end)
    -- 3s切一条文案
    tblActionList[#tblActionList+1] = cc.DelayTime:create(3.0)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self.m_tipsAni:runCsbAction("over", false)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(20/60)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:setTipsIdle(curIndex+1)
    end)
    local seq = cc.Sequence:create(tblActionList)
    self.m_scWaitNode:runAction(seq)
end

function CodeGameScreenTurkeyDayMachine:playBulingAnimFunc(_slotNode,_symbolCfg)
    if _slotNode and _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --特殊bonus
        local buffIcons = selfData.buffIcons
        if buffIcons and next(buffIcons) then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_PlayRole_Sound)
            self:playRoleAction()
        end
    end
    _slotNode:runAnim(_symbolCfg[2], false, function()
        self:symbolBulingEndCallBack(_slotNode)
    end)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenTurkeyDayMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                else
                    self.m_symbolExpectCtr:playSymbolIdleAnim(_slotNode, true)    
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

-- scatter落地条件
function CodeGameScreenTurkeyDayMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local reels = self.m_runSpinResultData.p_reels
    local scatterCount = 0
    for iCol = 1,colIndex - 1 do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterCount  = scatterCount + 1
            end
        end
    end

    if colIndex < 4 then
        return true
    elseif colIndex == 4 and scatterCount >= 1 then
        return true
    elseif colIndex == 5 and scatterCount >= 2 then
        return true
    end

    return false
end

-- 当前是否是free
function CodeGameScreenTurkeyDayMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenTurkeyDayMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    local scatterSoundTbl = self.m_publicConfig.SoundConfig.Music_Scatter_Buling

    local isQuickHaveScatter = false
    -- 检查下前三列是否有scatter（前三列有scatter必然播落地）
    if self:getGameSpinStage() == QUICK_RUN then
        local reels = self.m_runSpinResultData.p_reels
        for iCol = 1, (self.m_iReelColumnNum-2) do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = reels[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isQuickHaveScatter = true
                    break
                end
            end
        end
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    soundPath = symbolCfg[1]
                end
                if soundPath then
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self.m_curScatterBulingCount = self.m_curScatterBulingCount + 1
                        if self.m_curScatterBulingCount > #symbolCfg then
                            self.m_curScatterBulingCount = #symbolCfg
                        end
                        soundPath = scatterSoundTbl[self.m_curScatterBulingCount]
                        if self:getGameSpinStage() == QUICK_RUN then
                            if self:getCurFeatureIsFree() then
                                soundPath = scatterSoundTbl[3]
                            else
                                soundPath = scatterSoundTbl[1]
                            end
                        end
                    end

                    -- 快停时；有scatter 不播bonus
                    if self:getCurSymbolIsBonus(symbolType)then
                        if not isQuickHaveScatter then
                            self:playBulingSymbolSounds(iCol, soundPath, nil)
                        end
                    else
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
        end
    end
end

return CodeGameScreenTurkeyDayMachine
