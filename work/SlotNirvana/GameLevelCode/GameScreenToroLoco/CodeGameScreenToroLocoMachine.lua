---
-- island li
-- 2019年1月26日
-- CodeGameScreenToroLocoMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "ToroLocoPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenToroLocoMachine = class("CodeGameScreenToroLocoMachine", BaseNewReelMachine)

CodeGameScreenToroLocoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenToroLocoMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenToroLocoMachine.SYMBOL_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 -- 100

-- 自定义动画的标识
CodeGameScreenToroLocoMachine.QUICKHIT_FREE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 --free玩法同时出现scatter bonus 收集

-- 构造函数
function CodeGameScreenToroLocoMachine:ctor()
    CodeGameScreenToroLocoMachine.super.ctor(self)
    
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 
    self.m_iBetLevel = 0 -- bet等级
    self.m_isAddBigWinLightEffect = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_betCollectReels = {} -- 存储不同bet对应的数据
    self.m_betComeInCoins = 0 -- 进入关卡的时候 存储的bet值
    self.m_isColReelsSlowRun = {false, false, false, false, false} -- 每列是否慢滚
    self.m_freeCollectIndex = 1 -- free玩法 收集相关索引
    self.m_freeCollectBonusIndex = 1 -- free玩法 收集玩法 收集的bonus索引
    self.m_isplayRespinViewBuling = true -- respin最后一个bonus落地的时候 播放屏幕震动
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数
    self.m_respinViewScale = 1 --respin适配值
    self.m_isTriggerLongRun = false --是否触发了快滚
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    --init
    self:initGame()
end

function CodeGameScreenToroLocoMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ToroLocoConfig.csv", "LevelToroLocoConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenToroLocoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ToroLoco"  
end

function CodeGameScreenToroLocoMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 

    self.m_symbolExpectCtr = util_createView("CodeToroLocoSrc.ToroLocoSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("ToroLocoLongRunControl",self) 

    self.m_yugaoEffect = util_createAnimation("ToroLoco_reel_dark.csb")
    self.m_clipParent:addChild(self.m_yugaoEffect, REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 99)
    self.m_yugaoEffect:setPosition(util_convertToNodeSpace(self:findChild("Node_yugao"), self.m_clipParent))
    self.m_yugaoEffect:setVisible(false)

    -- 棋盘压暗
    self.m_reelMask = util_createAnimation("ToroLoco_reel_dark.csb")
    self.m_clipParent:addChild(self.m_reelMask, REEL_SYMBOL_ORDER.REEL_ORDER_2_2-100)
    self.m_reelMask:setVisible(false)

    --过场动画背景
    self.m_guochangEffectBg = util_createAnimation("ToroLoco/GameScreenToroLocoBg.csb")
    self:findChild("Node_guochang"):addChild(self.m_guochangEffectBg, -1)
    self.m_guochangEffectBg:setVisible(false)
    
    self:setReelBg(1)
    self:createRespinView()
    self:addColorLayer()
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "ToroLoco_totalwin.csb")
end

--[[
    初始化spine动画
]]
function CodeGameScreenToroLocoMachine:initSpineUI()
    -- 大赢前 预告动画
    self.m_bigWinEffect = util_spineCreate("ToroLoco_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect)
    local startPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self:findChild("Node_bigwin"))
    self.m_bigWinEffect:setPosition(startPos)
    self.m_bigWinEffect:setVisible(false)

    -- 预告动画
    self.m_yugaoSpineEffect = util_spineCreate("ToroLoco_yugao", true, true)
    -- self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect)
    self.m_clipParent:addChild(self.m_yugaoSpineEffect, REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 98)
    self.m_yugaoSpineEffect:setPosition(util_convertToNodeSpace(self:findChild("Node_yugao"), self.m_clipParent))
    self.m_yugaoSpineEffect:setVisible(false)

    -- 过场动画
    self.m_guochangEffect = util_spineCreate("ToroLoco_guochang",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangEffect)
    self.m_guochangEffect:setVisible(false)
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free 3respin
]]
function CodeGameScreenToroLocoMachine:setReelBg(_BgIndex)
    self.m_gameBg:runCsbAction("idle1")
    if _BgIndex == 1 then
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("reeldi_base"):setVisible(true)
        self:findChild("reeldi_fg"):setVisible(false)

        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)

        self:findChild("Node_xian"):setVisible(true)
        self:findChild("Node_reel"):setVisible(true)
        self:findChild("Node_respin"):setVisible(false)
    elseif _BgIndex == 2 then
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("reeldi_base"):setVisible(false)
        self:findChild("reeldi_fg"):setVisible(true)

        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)

        self:findChild("Node_xian"):setVisible(false)
        self:findChild("Node_reel"):setVisible(true)
        self:findChild("Node_respin"):setVisible(false)
    elseif _BgIndex == 3 then
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(true)

        self:findChild("Node_reel"):setVisible(false)
        self:findChild("Node_respin"):setVisible(true)

    end
end

function CodeGameScreenToroLocoMachine:createRespinView( )
    -- respin界面
    self.m_respinNodeView = util_createAnimation("ToroLoco_Respin.csb")
    self:findChild("Node_respin"):addChild(self.m_respinNodeView)
    self.m_respinNodeView:setScale(self.m_respinViewScale)

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_respinNodeView:findChild("touchSpin"))
    end

    --respinBar
    self.m_respinbar = util_createView("CodeToroLocoSrc.ToroLocoRespinBar")
    self.m_respinNodeView:findChild("Node_respinbar"):addChild(self.m_respinbar)

    --respinJackPotBarView
    self.m_respinJackPotBarView = util_createView("CodeToroLocoSrc.ToroLocoReSpinJackPotBarView")
    self.m_respinJackPotBarView:initMachine(self)
    self.m_respinNodeView:findChild("Node_jackpot"):addChild(self.m_respinJackPotBarView)

    --respin wheel
    self.m_respinWheel = util_createView("CodeToroLocoSrc.ToroLocoRespinWheel")
    self.m_respinWheel:initMachine(self)
    self.m_respinNodeView:findChild("Node_wheel"):addChild(self.m_respinWheel)

    -- respin快滚
    self.m_lightEffectNode = cc.Node:create()
    self.m_respinNodeView:findChild("root"):addChild(self.m_lightEffectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 200)

    -- 提层节点
    self.m_effectNode = cc.Node:create()
    self.m_respinNodeView:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    -- wheel 开始前棋盘的动画
    self.m_respinWheelStart = util_createAnimation("ToroLoco_respinglow.csb")
    self.m_respinNodeView:findChild("Node_tx"):addChild(self.m_respinWheelStart)

    -- 爆炸
    self.m_respinBaoZha = util_spineCreate("ToroLoco_totalwin",true,true)
    self.m_respinNodeView:findChild("Node_tx"):addChild(self.m_respinBaoZha)
    self.m_respinBaoZha:setVisible(false)

    -- respin集满
    -- self.m_respinJiManEffect = util_spineCreate("WheelToroLoco_jiman",true,true)
    -- self.m_respinNodeView:findChild("Node_jiman"):addChild(self.m_respinJiManEffect)
    -- self.m_respinJiManEffect:setVisible(false)
end

--[[
    每列添加滚动遮罩
]]
function CodeGameScreenToroLocoMachine:addColorLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        --单列卷轴尺寸
        local reel = self:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(4.5, 4.5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = self.m_onceClipNode or self.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(0)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        self.m_colorLayers[i] = panel
    end
end

--[[
    显示滚动遮罩
]]
function CodeGameScreenToroLocoMachine:showColorLayer()
    for index, maskNode in ipairs(self.m_colorLayers) do
        maskNode:setVisible(true)
        maskNode:setOpacity(0)
        maskNode:runAction(cc.FadeTo:create(0.3, 150))
        if self.m_isColReelsSlowRun[index] then
            maskNode:setVisible(false)
        end
    end

    if self.m_reelsFalseRoll then
        for _col, _reelsNode in pairs(self.m_reelsFalseRoll) do
            local panel = _reelsNode.panel
            if not tolua.isnull(panel) then
                panel:runAction(cc.FadeTo:create(0.3, 150))
            end
        end
    end
end

--[[
    列滚动停止 渐隐
]]
function CodeGameScreenToroLocoMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(0.1, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

function CodeGameScreenToroLocoMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_enter_game)
    end)
end

function CodeGameScreenToroLocoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenToroLocoMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 进入关卡先初始化一遍jackpot解锁情况
    self:changeBetCallBack(nil, true)
end

function CodeGameScreenToroLocoMachine:addObservers()
    CodeGameScreenToroLocoMachine.super.addObservers(self)
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_ToroLoco_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_ToroLoco_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:changeBetCallBack()
            self:stopLinesWinSound()

            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    -- 点击解锁jackpot
    gLobalNoticManager:addObserver(self,function(self,params)

        if self:isNormalStates( ) then
            if self.m_iBetLevel == 0 then
                self:unlockHigherBet()
            end
        end
    end,"SHOW_UNLOCK_JACKPOT")
end

function CodeGameScreenToroLocoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenToroLocoMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenToroLocoMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS  then
        return "Socre_ToroLoco_Bonus"
    elseif symbolType == self.SYMBOL_EMPTY then
        return "ToroLoco_Black"
    end 
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenToroLocoMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenToroLocoMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_EMPTY,count =  2}

    return loadNode
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenToroLocoMachine:initGameStatusData(gameData)
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.collectReels then
        self.m_betCollectReels = gameData.gameConfig.extra.collectReels
    end

    local betid = gameData.betId or -1
    if betid > 0 then
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        for _, _betData in ipairs (betList) do
            if _betData.p_betId == betid then
                self.m_betComeInCoins = _betData.p_totalBetValue
            end
        end
    end
    if gameData.spin and gameData.spin.action == "RESPIN" then
        if gameData.spin.selfData and ((gameData.spin.selfData.baseTriggerReSpinReels and #gameData.spin.selfData.baseTriggerReSpinReels > 0) or
            (gameData.spin.selfData.freeTriggerReSpinReels and #gameData.spin.selfData.freeTriggerReSpinReels > 0)) then
            if gameData.spin.respin.reSpinCurCount == 0 then
                gameData.spin.reels = gameData.spin.selfData.baseTriggerReSpinReels or gameData.spin.selfData.freeTriggerReSpinReels
                gameData.spin.storedIcons = gameData.spin.selfData.baseTriggerReSpinStoredIcons or gameData.spin.selfData.freeTriggerReSpinStoredIcons
                if gameData.spin.selfData.fifthColumnInfo then
                    gameData.spin.selfData.fifthColumnInfo = {}
                end
            else
                self:initRespinData(gameData)
            end
        end
    end

    if gameData.spin and gameData.spin.action == "FREESPIN" and gameData.spin.freespin.freeSpinsLeftCount == gameData.spin.freespin.freeSpinsTotalCount then
        if gameData.spin.selfData and gameData.spin.selfData.baseTriggerFreeReels and #gameData.spin.selfData.baseTriggerFreeReels > 0 then
            gameData.spin.reels = gameData.spin.selfData.baseTriggerFreeReels
            gameData.spin.storedIcons = gameData.spin.selfData.baseTriggerFreeStoredIcons
        end
    end
    CodeGameScreenToroLocoMachine.super.initGameStatusData(self, gameData)
end

--[[
    断线 特殊处理respin相关数据
]]
function CodeGameScreenToroLocoMachine:initRespinData(gameData)
    if gameData.spin and gameData.spin.selfData and gameData.spin.selfData.baseTriggerReSpinReels then
        for iRow = 1, self.m_iReelRowNum do
            gameData.spin.reels[iRow][5] = gameData.spin.selfData.baseTriggerReSpinReels[iRow][5]
        end
    end

    if gameData.spin and gameData.spin.selfData and gameData.spin.selfData.freeTriggerReSpinReels then
        for iRow = 1, self.m_iReelRowNum do
            gameData.spin.reels[iRow][5] = gameData.spin.selfData.freeTriggerReSpinReels[iRow][5]
        end
    end

    if #gameData.spin.storedIcons > 0 then
        for _, _iconsData in ipairs(gameData.spin.storedIcons) do
            local rowColData = self:getRowAndColBySmallReelsPos(_iconsData[1])
            _iconsData[1] = self:getPosReelIdx(rowColData.iX, rowColData.iY)
        end
    end
end

--[[
    根据pos位置 获取 对应 行列信息
    3x4
]]
function CodeGameScreenToroLocoMachine:getRowAndColBySmallReelsPos(posData)
    local colCount = self.m_iReelColumnNum - 1
    local rowIndex = self.m_iReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

--[[
    @desc: 断线重连时处理 是否有feature 
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenToroLocoMachine:checkHasFeature()
    local hasFeature = CodeGameScreenToroLocoMachine.super.checkHasFeature(self)
    if not hasFeature then
        if tonumber(self.m_betComeInCoins) > 0 then
            local reelsData = self.m_betCollectReels[tostring(self.m_betComeInCoins)]
            if reelsData and #reelsData > 0 then
                hasFeature = true
            end
        end
    end
    return hasFeature
end

--[[
    每次spin 保存bet对应的数据
]]
function CodeGameScreenToroLocoMachine:updateBetNetReelsData( )
    if not self.m_bProduceSlots_InFreeSpin then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local totalBet = globalData.slotRunData:getCurTotalBet( )
        if selfdata and selfdata.bonusReelsParams then
            local reelsData = self.m_betCollectReels[tostring(totalBet)]
            if reelsData == nil then
                self.m_betCollectReels[tostring(totalBet)] = {}
                self.m_betCollectReels[tostring(totalBet)] = selfdata.bonusReelsParams
            else
                self.m_betCollectReels[tostring(totalBet)] = selfdata.bonusReelsParams
            end
        else
            self.m_betCollectReels[tostring(totalBet)] = {}
        end
    end
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenToroLocoMachine:MachineRule_afterNetWorkLineLogicCalculate()
    CodeGameScreenToroLocoMachine.super.MachineRule_afterNetWorkLineLogicCalculate(self)

    self:updateBetNetReelsData()
    self:changeReelsMove()
end

--[[
    切换bet jackpot变化
]]
function CodeGameScreenToroLocoMachine:changeBetCallBack(_betCoins, _isFirstComeIn)
    self.m_iBetLevel = 0
    local betCoins =_betCoins or globalData.slotRunData:getCurTotalBet()

    for _betLevel,_betData in ipairs(self.m_specialBets) do
        if betCoins < _betData.p_totalBetValue then
            break
        end
        self.m_iBetLevel = _betLevel
    end

    -- 上锁
    if self.m_iBetLevel == 0 then
        self.m_jackPotBarView:lockGrand(_isFirstComeIn)
    -- 解锁
    else
        self.m_jackPotBarView:unLockGrand(_isFirstComeIn)
    end

    self:changeBonusColByBet(_isFirstComeIn)
end

--[[
    切换bet之后 改变bonus
]]
function CodeGameScreenToroLocoMachine:changeBonusColByBet(_isFirstComeIn)
    if (not self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) or not _isFirstComeIn) and not self.m_bProduceSlots_InFreeSpin then
        self:changeBonusBaseToFree()
        self:changeBonusFreeToBase()
    end
end

--[[
    点击解锁jackpot
]]
function CodeGameScreenToroLocoMachine:unlockHigherBet()
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

    self.m_jackPotBarView:unLockGrand()

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

--[[
    判断是否可以点击解锁
]]
function CodeGameScreenToroLocoMachine:isNormalStates( )
    
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

    return true
end

--[[
    获取解锁进度条对应的bet
]]
function CodeGameScreenToroLocoMachine:getMinBet()
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end
    return minBet
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenToroLocoMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:setReelBg(2)
    end 
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenToroLocoMachine:MachineRule_SpinBtnCall()
    self.m_isTriggerLongRun = false
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenToroLocoMachine:slotOneReelDown(reelCol)
    local isTriggerLongRun = CodeGameScreenToroLocoMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 
end

--[[
    滚轮停止
]]
function CodeGameScreenToroLocoMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    -- for iCol = 1, self.m_iReelColumnNum do
    --     self:reelStopHideMask(iCol)
    -- end
    
    -- if self.m_reelsFalseRoll and table.nums(self.m_reelsFalseRoll) > 0 then
    --     for _col, _reelsNode in pairs(self.m_reelsFalseRoll) do
    --         local panel = _reelsNode.panel
    --         if not tolua.isnull(panel) then
    --             panel:runAction(cc.FadeTo:create(0.1, 0))
    --         end
    --     end
    -- end
    
    if self.m_isTriggerLongRun then
        local features = self.m_runSpinResultData.p_features or {}
        if features and #features < 2 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_almost_there)
        end
    end

    self:delayCallBack(0.1, function()
        self:removeReelsMove()
        CodeGameScreenToroLocoMachine.super.slotReelDown(self)
    end)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenToroLocoMachine:addSelfEffect()
    if self:isTriggerFreeCollect() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.QUICKHIT_FREE_COLLECT -- 动画类型
    end
end

--[[
    free玩法 是否触发收集
]]
function CodeGameScreenToroLocoMachine:isTriggerFreeCollect( )
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local features  = self.m_runSpinResultData.p_features or {}
        local reels  = self.m_runSpinResultData.p_reels or {}
        local count = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, #reels do
                if reels[iRow][iCol] == self.SYMBOL_BONUS then
                    count = count + 1
                end
            end
        end

        if #features > 1 and features[2] == 1 and count > 0 then
            return true
        end 
    end
    return false
end

--
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenToroLocoMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.QUICKHIT_FREE_COLLECT then
        self:playEffect_freeCollectEffect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

--[[
    free玩法 收集钱
]]
function CodeGameScreenToroLocoMachine:playEffect_freeCollectEffect(_func)
    local scatterList = {}
    local bonusList = {}
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_free_bonus_trigger)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType then
                if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolNode.p_symbolType == self.SYMBOL_BONUS then
                    util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        table.insert(scatterList, symbolNode)
                    end
                    if symbolNode.p_symbolType == self.SYMBOL_BONUS then
                        table.insert(bonusList, symbolNode)
                    end

                    symbolNode.m_oldZOrder = symbolNode:getLocalZOrder()
                    symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 100 + symbolNode.m_oldZOrder)
                    symbolNode:runAnim("actionframe2", false)
                end
            end
        end
    end

    if #scatterList > 1 then
        table.sort(scatterList, function(a, b)
            return a.p_cloumnIndex < b.p_cloumnIndex
        end)
    end
    if #bonusList > 1 then
        table.sort(bonusList, function(a, b)
            if a.p_cloumnIndex == b.p_cloumnIndex then
                return a.p_rowIndex > b.p_rowIndex
            end
            return a.p_cloumnIndex < b.p_cloumnIndex
        end)
    end

    self:delayCallBack(60/30, function()
        for _, _scatterNode in ipairs(scatterList) do
            _scatterNode:runAnim("shouji_idle", true)
        end

        for _, _bonusNode in ipairs(bonusList) do
            _bonusNode:runAnim("shouji_idle", true)
        end

        self:playEffect_freeCollectCoins(_func, scatterList, bonusList)
    end)
end

--[[
    free玩法 收集钱
]]
function CodeGameScreenToroLocoMachine:playEffect_freeCollectCoins(_func, _scatterList, _bonusLists)
    if self.m_freeCollectIndex > #_scatterList then
        for _, _bonusNode in ipairs(_bonusLists) do
            if _bonusNode.m_oldZOrder then
                _bonusNode:setLocalZOrder(_bonusNode.m_oldZOrder)
            end
        end
        for _, _scatterNode in ipairs(_scatterList) do
            _scatterNode:hideBigSymbolClip()
        end

        if _func then
            _func()
        end

        return
    end

    self.m_freeCollectBonusIndex = 1
    local delayTime = 0
    if self.m_freeCollectIndex == 1 then
        delayTime = 1
    end

    self:delayCallBack(delayTime, function()
        for _index, _scatterNode in ipairs(_scatterList) do
            if _index ~= self.m_freeCollectIndex and _scatterNode.m_oldZOrder then
                local columnData = self.m_reelColDatas[_scatterNode.p_cloumnIndex]
                if _scatterNode.p_cloumnIndex == 1 or _scatterNode.p_cloumnIndex == 5 then
                    _scatterNode:setLocalZOrder(_scatterNode.m_oldZOrder-2000)
                    _scatterNode:showBigSymbolClip(-columnData.p_showGridH, columnData.p_slotColumnWidth, columnData.p_showGridH*4, _scatterNode.p_cloumnIndex, _scatterNode.p_rowIndex)
                else
                    local nodePos = util_convertToNodeSpace(_scatterNode, self:getReelParent(_scatterNode.p_cloumnIndex))
                    util_changeNodeParent(self.m_slotParents[_scatterNode.p_cloumnIndex].slotParent, _scatterNode, _scatterNode.p_showOrder)
                    _scatterNode:setPosition(nodePos)
                end
            end
        end

        local scatterNode = _scatterList[self.m_freeCollectIndex]
        if scatterNode then
            if scatterNode.m_oldZOrder then
                scatterNode:hideBigSymbolClip()
                util_setSymbolToClipReel(self, scatterNode.p_cloumnIndex, scatterNode.p_rowIndex, scatterNode.p_symbolType, 0)
                scatterNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + scatterNode.m_oldZOrder)
            end
            self.m_reelMask:setVisible(true)
            self.m_reelMask:runCsbAction("start")

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_free_scatter_big)

            scatterNode:runAnim("shouji_over", false, function()
                scatterNode:runAnim("idleframe2", true)
                if scatterNode.m_oldZOrder then
                    scatterNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 100 + scatterNode.m_oldZOrder)
                end
                self:playEffect_freeCollectCoinsEffect(_bonusLists, self.m_freeCollectIndex == #_scatterList, function()
                    self.m_freeCollectIndex = self.m_freeCollectIndex + 1
                    self:playEffect_freeCollectCoins(_func, _scatterList, _bonusLists)
                end)
            end)
            self:delayCallBack(12/30, function()
                local rootNode = self:findChild("root")
                util_shakeNode(rootNode, 5, 10, 1)
            end)
        end
    end)
end

function CodeGameScreenToroLocoMachine:playEffect_freeCollectCoinsEffect(_bonusLists, _isLastScatter, _func)
    if self.m_freeCollectBonusIndex > #_bonusLists then
        self.m_reelMask:runCsbAction("over", false, function()
            self.m_reelMask:setVisible(false)
            if _func then
                _func()
            end
        end)

        return
    end

    local _bonusNode = _bonusLists[self.m_freeCollectBonusIndex]
    local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(_bonusNode.p_rowIndex, _bonusNode.p_cloumnIndex))
    if _bonusNode.m_oldZOrder then
        _bonusNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + _bonusNode.m_oldZOrder)
    end

    local actionframe = "shouji_over"
    if not _isLastScatter then
        actionframe = "shouji_over2"
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_free_bonus_coins_jiesuan)

    _bonusNode:runAnim(actionframe, false, function()
        if not _isLastScatter then
            _bonusNode:runAnim("shouji_idle", true)
        else
            _bonusNode:runAnim("idleframe2", true)
        end 
        if _bonusNode.m_oldZOrder then
            _bonusNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 100 + _bonusNode.m_oldZOrder)
        end
    end)
    
    self:playWinCoinsBottom(score)

    if type == "bonus" then
        self:delayCallBack(0.5, function()
            self.m_freeCollectBonusIndex = self.m_freeCollectBonusIndex + 1
            self:playEffect_freeCollectCoinsEffect(_bonusLists, _isLastScatter, _func)
        end)
    else
        self.m_jackPotBarView:playWinEffect(type)
        self:showJackpotView(score, type, function()
            self.m_jackPotBarView:hideWinEffect(type)
            self.m_freeCollectBonusIndex = self.m_freeCollectBonusIndex + 1
            self:playEffect_freeCollectCoinsEffect(_bonusLists, _isLastScatter, _func)
        end)
    end
end

function CodeGameScreenToroLocoMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenToroLocoMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenToroLocoMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_free_scatter_trigger)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenToroLocoMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenToroLocoMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenToroLocoMachine:checkRemoveBigMegaEffect()
    CodeGameScreenToroLocoMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

--获取底栏金币
function CodeGameScreenToroLocoMachine:getCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
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

--更新底栏金币
function CodeGameScreenToroLocoMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenToroLocoMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeToroLocoSrc.ToroLocoFreespinBarView", {machine = self})
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("bar1"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点   
    
    self.m_baseFreeSpinBar1 = util_createView("CodeToroLocoSrc.ToroLocoFreespinBarView", {machine = self})
    self.m_baseFreeSpinBar1:setVisible(false)
    self:findChild("bar2"):addChild(self.m_baseFreeSpinBar1) --修改成自己的节点   
end

function CodeGameScreenToroLocoMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar1:setVisible(true)
end

function CodeGameScreenToroLocoMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    util_setCsbVisible(self.m_baseFreeSpinBar1, false)
end

function CodeGameScreenToroLocoMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

function CodeGameScreenToroLocoMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        local view = nil
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_freeMore)

            view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self.m_baseFreeSpinBar:playAddNumsEffect(function()
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                end)
                self.m_baseFreeSpinBar1:playAddNumsEffect()

                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:playGuoChangEffect(function()
                    self.m_runSpinResultData.p_selfMakeData = {}
                    self:setReelBg(2)
                    self:changeBonusBaseToFree()
                end, function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()   
                end, true)
            end)

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_freeStartView_start)
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_ToroLoco_click
            view:setBtnClickFunc(function(  )
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_freeStartView_over)
            end)
        end
        -- 添加光
        local guangNode = util_createAnimation("ToroLoco_glow.csb")
        view:findChild("Node_glow"):addChild(guangNode)
        guangNode:runCsbAction("idle", true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("Node_glow"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("Node_glow"), true)

        for index = 1, 2 do
            local jueSeSpine = util_spineCreate("ToroLoco_guochang",true,true)
            view:findChild("Node_juese"):addChild(jueSeSpine)
            util_spinePlay(jueSeSpine, "freespin_start"..index, false)
            util_spineEndCallFunc(jueSeSpine, "freespin_start"..index, function ()
                util_spinePlay(jueSeSpine, "freespin_idle"..index, true)
            end)
        end

        view:findChild("root"):setScale(self.m_machineRootScale)
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenToroLocoMachine:showEffect_runBigWinLightAni(effectData)
    if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
        if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_fsWinCoins - self:getCurBottomWinCoins()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, false})
    end
    return CodeGameScreenToroLocoMachine.super.showEffect_runBigWinLightAni(self, effectData)
end

--[[
   base 进入 free 棋盘上有bonus 随机变成其他
]]
function CodeGameScreenToroLocoMachine:changeBonusBaseToFree( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS then
                local randomType = math.random(0, 8)
                self:changeSymbolType(symbolNode, randomType)
            end
        end
    end
end

--[[
   free 进入 base 恢复触发的时候 棋盘
]]
function CodeGameScreenToroLocoMachine:changeBonusFreeToBase( )
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local reelsData = self.m_betCollectReels[tostring(totalBet)]
    if reelsData and #reelsData > 0 then
        for _, _reelsData in ipairs(reelsData) do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(_reelsData.column+1, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    local symbolType = _reelsData.curColumn[iRow]
                    if iRow == 1 then
                        symbolType = _reelsData.curColumn[3]
                    elseif iRow == 3 then
                        symbolType = _reelsData.curColumn[1]
                    end
                    self:changeSymbolType(slotNode, symbolType)
                    if symbolType == self.SYMBOL_BONUS then
                        self.m_runSpinResultData.p_storedIcons = _reelsData.curStoredIcons
                        self:setSpecialNodeScore(slotNode)
                        slotNode:runAnim("idleframe2", true)
                    end
                end
            end
        end
    end
end

function CodeGameScreenToroLocoMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if coins == "0" then
        return self:showDialog("NoWin", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
end

function CodeGameScreenToroLocoMachine:showFreeSpinOverView(effectData)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:playGuoChangFreeToBaseEffect(function()
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()

                self:changeReelsByRespinOrFree(true)

                self:setReelBg(1)
            end, function()
                self:triggerFreeSpinOverCallFun()
            end, true)
        end
    )
    if strCoins ~= "0" then
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},690)
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_freeOverView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_ToroLoco_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_freeOverView_over)
    end)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenToroLocoMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    local waitTime = 0
    self.m_reelMask:setVisible(true)
    self.m_reelMask:runCsbAction("start")
    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and not self:checkHasGameEffectType(GameEffect.EFFECT_BIG_WIN_LIGHT) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, false, false})
    end

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:runAnim("actionframe")
                util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                local duration = symbolNode:getAniamDurationByName("actionframe")
                waitTime = util_max(waitTime,duration)
            end
        end
    end

    performWithDelay(self,function(  )
        self.m_reelMask:runCsbAction("over", false, function()
            self.m_reelMask:setVisible(false)
        end)
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenToroLocoMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_fsWinCoins - self:getCurBottomWinCoins()
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenToroLocoMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
        if self.m_bProduceSlots_InFreeSpin then
            notAdd = false
        end
    end

    return notAdd
end

-- 继承底层respinView
function CodeGameScreenToroLocoMachine:getRespinView()
    return "CodeToroLocoSrc.ToroLocoRespinView"    
end

-- 继承底层respinNode
function CodeGameScreenToroLocoMachine:getRespinNode()
    return "CodeToroLocoSrc.ToroLocoRespinNode"    
end

function CodeGameScreenToroLocoMachine:getBaseReelGridNode()
    return "CodeToroLocoSrc.ToroLocoSlotNode"
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenToroLocoMachine:getReSpinSymbolScore(_pos, _isEnd)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local fifthColumnInfo = selfMakeData.fifthColumnInfo or {}
    local score = nil
    local type = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if tonumber(values[1]) == _pos then
            score = values[2]
            type = values[3]
            if not _isEnd and fifthColumnInfo and #fifthColumnInfo > 0 and fifthColumnInfo[2] == "multiple" then
                score = values[2]/fifthColumnInfo[1]
            end
        end
    end

    return score, type
end

function CodeGameScreenToroLocoMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    local type = nil
    if symbolType == self.SYMBOL_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
        if score == "Mini" then
            score = 0
            type = "Mini"
        elseif score == "Minor" then
            score = 0
            type = "Minor"
        elseif score == "Major" then
            score = 0
            type = "Major"
        elseif score == "Grand" then
            score = 0
            type = "Grand"
        else
            score = score * globalData.slotRunData:getCurTotalBet()
            type = "bonus"
        end
    end
    return score,type
end

-- 给respin小块进行赋值
function CodeGameScreenToroLocoMachine:setSpecialNodeScore(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if self:isFixSymbol(symbolNode.p_symbolType) then
        -- 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local coinsView
        if not spineNode.m_csbNode then
            coinsView = util_createAnimation("Socre_ToroLoco_Bonus_Zi.csb")
            util_spinePushBindNode(spineNode,"wenzi",coinsView)
            spineNode.m_csbNode = coinsView
        else
            spineNode.m_csbNode:setVisible(true)
            coinsView = spineNode.m_csbNode
        end
        coinsView:runCsbAction("idle", false)

        local score = 0
        local type = nil
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow,iCol))
        else
            score, type = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        end
        self:showBonusJackpotOrCoins(coinsView, score, type)
    end
end

function CodeGameScreenToroLocoMachine:getPosReelIdx(iRow, iCol)
    local totalCol = self.m_iReelColumnNum
    if self:getCurrSpinMode() == RESPIN_MODE and not self.m_isComeInRespin then
        totalCol = self.m_iReelColumnNum - 1
    end
    local index = (self.m_iReelRowNum - iRow) * totalCol + (iCol - 1)
    return index
end

--[[
    显示bonus上的信息
]]
function CodeGameScreenToroLocoMachine:showBonusJackpotOrCoins(coinsView, score, type)
    if coinsView then
        coinsView:findChild("Node_2"):setVisible(false)
        coinsView:findChild("Node_jackpot"):setVisible(false)
        coinsView:findChild("Node_jackpot_mul"):setVisible(false)

        if type == "bonus" then
            coinsView:findChild("Node_2"):setVisible(true)
            local labCoins = coinsView:findChild("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3, false, true, true))
            self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 168)
        else  
            coinsView:findChild("Node_jackpot"):setVisible(true)
            coinsView:findChild("grand"):setVisible(type == "Grand")
            coinsView:findChild("major"):setVisible(type == "Major")
            coinsView:findChild("minor"):setVisible(type == "Minor")
            coinsView:findChild("mini"):setVisible(type == "Mini")
        end
    end
end

function CodeGameScreenToroLocoMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS then
        self:setSpecialNodeScore(node)
    end    
end

-- 是不是 respinBonus小块
function CodeGameScreenToroLocoMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return true
    end
    return false    
end

-- 结束respin收集
function CodeGameScreenToroLocoMachine:playLightEffectEnd()
    self:delayCallBack(0.5, function()
        -- 通知respin结束
        self:respinOver()  
    end)
end

function CodeGameScreenToroLocoMachine:getJackpotScore(_jpName)
    local jackpotCoinData = self.m_runSpinResultData.p_jackpotCoins or {}
    local coins = jackpotCoinData[_jpName]
    return coins    
end

function CodeGameScreenToroLocoMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        self:playLightEffectEnd()
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex

    -- 根据网络数据获得当前固定小块的分数
    local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol), true)
    local addScore = score

    self.m_lightScore = self.m_lightScore + addScore

    local function runCollect()
        if type == "bonus" then
            self:playBonusJieSuanEffect(chipNode, addScore, false, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim()
            end)
        else
            self:playBonusJieSuanEffect(chipNode, addScore, true, function()
                self:showJackpotView(addScore, type, function()
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    self:playChipCollectAnim()
                end)
            end)
        end
    end
    runCollect()    
end

--[[
    bonus结算 飞粒子
]]
function CodeGameScreenToroLocoMachine:playBonusFlyLiZi(_startNode, _func)
    local startPos = util_convertToNodeSpace(_startNode, gLobalViewManager.p_ViewLayer)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, gLobalViewManager.p_ViewLayer)
    
    local flyNode = util_spineCreate("Socre_ToroLoco_Bonus",true,true)
    gLobalViewManager.p_ViewLayer:addChild(flyNode, 1)
    flyNode:setPosition(startPos)

    util_spinePlay(flyNode, "jiesuan", false)

    local moveTime = 15/30
    if _startNode.p_rowIndex == 1 then
        moveTime = 13/30
    elseif _startNode.p_rowIndex == 3 then
        moveTime = 17/30
    end
    local seq = cc.Sequence:create({
        cc.MoveTo:create(moveTime, cc.p(endPos.x, startPos.y)),
        cc.CallFunc:create(function(  )
            if _func then
                _func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

--[[
    结算每个bonus的动画
]]
function CodeGameScreenToroLocoMachine:playBonusJieSuanEffect(_node, _addCoins, _isJackpot, _func)
    local jiesuanName = "shouji_over"
    if _isJackpot then
        jiesuanName = "shouji_over"
    end

    if not tolua.isnull(_node) and _node.p_symbolType then
        local nodePos = util_convertToNodeSpace(_node, self.m_effectNode)
        local oldParent = _node:getParent()
        local oldPosition = cc.p(_node:getPosition())
        util_changeNodeParent(self.m_effectNode, _node, 0)
        _node:setPosition(nodePos)
        _node:runAnim(jiesuanName, false, function()
            if not tolua.isnull(_node) then
                util_changeNodeParent(oldParent, _node, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                _node:setPosition(oldPosition)
                -- _node:runAnim("darkstart", false)

                -- local symbol_node = _node:checkLoadCCbNode()
                -- local spineNode = symbol_node:getCsbAct()
                -- if spineNode.m_csbNode then
                --     local coinsNode = spineNode.m_csbNode
                --     coinsNode:runCsbAction("darkstart", false)
                -- end
            end
        end)
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respin_bonus_fly_coins)

    self:playBonusFlyLiZi(_node, function()
        self:playWinCoinsBottom(_addCoins)

        if _func then
            _func()
        end
    end)
end

--[[
    wheel滚动结束 结算
]]
function CodeGameScreenToroLocoMachine:playWheelCollectEffect(_winNode, _func)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local fifthColumnInfo = selfMakeData.fifthColumnInfo or {}
    if #fifthColumnInfo > 0 then
        if fifthColumnInfo[2] == "multiple" then --乘倍
            self:playWheelWinMulEffect(fifthColumnInfo, _func)
        elseif fifthColumnInfo[2] == "bonus" then --金币
            self:playWheelWinBonusEffect(self.m_respinWheel:findChild("Node_fly"), fifthColumnInfo[1], _func)
        else -- jackpot
            _winNode:runCsbAction("zhongjiang", false, function()
                self.m_respinJackPotBarView:hideWinEffect(fifthColumnInfo[2])
                self:showJackpotView(fifthColumnInfo[1], fifthColumnInfo[2], function()
                    if _func then
                        _func()
                    end
                end)

                self:playWinCoinsBottom(fifthColumnInfo[1])
            end)
        end
    else
        if _func then
            _func()
        end
    end
end

--[[
    转盘中奖金币 之后的动效
]]
function CodeGameScreenToroLocoMachine:playWheelWinBonusEffect(_startNode, _addCoins, _func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_wheel_fly_coins)

    local startPos = util_convertToNodeSpace(_startNode, gLobalViewManager.p_ViewLayer)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, gLobalViewManager.p_ViewLayer)
    
    local flyNode = util_createAnimation("Socre_ToroLoco_Respin_Zi.csb")
    gLobalViewManager.p_ViewLayer:addChild(flyNode, 1)
    flyNode:setPosition(startPos)
    flyNode:findChild("Node_jackpot_respin"):setVisible(false)
    flyNode:findChild("Node_mul"):setVisible(false)
    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(_addCoins, 3, false, true, true))

    local liziNode = util_createAnimation("Socre_ToroLoco_Bonus_lizi.csb")
    flyNode:findChild("Node_respin"):addChild(liziNode, -1)

    flyNode:runCsbAction("shouji", false)

    local particle = nil
    if not tolua.isnull(liziNode) then
        particle = liziNode:findChild("Particle_1")
        if particle then
            particle:setPositionType(0)
        end
    end
    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.4, endPos),
        cc.CallFunc:create(function(  )
            flyNode:findChild("m_lb_coins"):setVisible(false)
            if particle then
                particle:stopSystem()
            end
            self:playWinCoinsBottom(_addCoins)

            if _func then
                _func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

--[[
    显示赢钱区的钱
]]
function CodeGameScreenToroLocoMachine:playWinCoinsBottom(_addCoins)
    self:playCoinWinEffectUI()
    -- 刷新底栏
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + _addCoins)
    self.m_bottomUI.m_changeLabJumpTime = 0.2
    self:updateBottomUICoins(0, _addCoins, false, true, false)
    self.m_bottomUI.m_changeLabJumpTime = nil
end

--[[
    转盘中奖乘倍 之后的动效
]]
function CodeGameScreenToroLocoMachine:playWheelWinMulEffect(_fifthColumnInfo, _func)
    local startPos = cc.p(self.m_respinWheel:findChild("Node_fly"):getPosition())
    local endPos = util_convertToNodeSpace(self.m_respinNodeView:findChild("Node_tx"), self.m_effectNode)
    
    local flyNode = util_createAnimation("Socre_ToroLoco_Respin_Zi.csb")
    self.m_effectNode:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    flyNode:setPosition(startPos)
    flyNode:findChild("Node_jackpot_respin"):setVisible(false)
    flyNode:findChild("Node_respin"):setVisible(false)
    flyNode:findChild("m_lb_coins_mul"):setString("X".._fifthColumnInfo[1])

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_wheel_mul_fly)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_wheel_mul_fly_za)

    flyNode:runCsbAction("chengbei", false)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(25/60),
        cc.MoveTo:create(0.5,endPos),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create(true)
    })
    flyNode:runAction(seq)

    self:delayCallBack(75/60, function()
        self.m_respinBaoZha:setVisible(true)
        util_spinePlay(self.m_respinBaoZha, "actionframe_respin2", false)
        util_spineEndCallFunc(self.m_respinBaoZha, "actionframe_respin2" ,function ()
            self.m_respinBaoZha:setVisible(false)
        end) 

        local rootNode = self:findChild("root")
        util_shakeNode(rootNode, 5, 10, 1)
        self:playAddCoinsBonusEffect(_func)
    end)
end

--[[
    给respin棋盘上的小块 加钱动画
]]
function CodeGameScreenToroLocoMachine:playAddCoinsBonusEffect(_func)
    -- 获得所有固定的respinBonus小块
    local chipList = self.m_respinView:getAllCleaningNode()
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local fifthColumnInfo = selfMakeData.fifthColumnInfo or {}

    for _, _chipNode in ipairs(chipList) do
        local symbol_node = _chipNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()

        if spineNode.m_csbNode then
            local oldScore = 0
            local coinsNode = spineNode.m_csbNode
            local newScore, type = self:getReSpinSymbolScore(self:getPosReelIdx(_chipNode.p_rowIndex, _chipNode.p_cloumnIndex), true)
            if type == "bonus" then
                if fifthColumnInfo and #fifthColumnInfo > 0 then
                    oldScore = newScore / fifthColumnInfo[1]
                end
                self:jumpCoinsUp(_chipNode, newScore, oldScore, coinsNode)
            else
                coinsNode:findChild("Node_jackpot"):setVisible(false)
                coinsNode:findChild("Node_jackpot_mul"):setVisible(true)
                coinsNode:findChild("grand_0"):setVisible(type == "Grand")
                coinsNode:findChild("major_0"):setVisible(type == "Major")
                coinsNode:findChild("minor_0"):setVisible(type == "Minor")
                coinsNode:findChild("mini_0"):setVisible(type == "Mini")
                if fifthColumnInfo and #fifthColumnInfo > 0 then
                    coinsNode:findChild("m_lb_coins_mul"):setString("X"..fifthColumnInfo[1])
                end
            end
        end
    end

    self:delayCallBack(0.5, function()
        if _func then
            _func()
        end
    end)
end

-- 金币跳动
function CodeGameScreenToroLocoMachine:jumpCoinsUp(node, _coins, _curCoins, _coinsNode)
    if not tolua.isnull(node) then
        local curCoins = _curCoins or 0
        -- 每秒60帧
        local coinRiseNum =  (_coins - _curCoins) / (0.5 * 60)

        local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
        coinRiseNum = tonumber(str)
        coinRiseNum = math.ceil(coinRiseNum)

        node.m_updateCoinsAction = schedule(self, function()
            curCoins = curCoins + coinRiseNum
            curCoins = curCoins < _coins and curCoins or _coins
            
            local sCoins = curCoins

            if not tolua.isnull(node) then
                local labCoins = _coinsNode:findChild("m_lb_coins")
                labCoins:setString(util_formatCoins(sCoins, 3, false, true, true))
                self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 168)
            end

            if curCoins >= _coins then
                self:stopUpDateCoinsUp(node)
            end
        end,0.008)
    end
end

function CodeGameScreenToroLocoMachine:stopUpDateCoinsUp(node)
    if not tolua.isnull(node) then
        if node.m_updateCoinsAction then
            self:stopAction(node.m_updateCoinsAction)
            node.m_updateCoinsAction = nil
        end
    end
end

--结束移除小块调用结算特效
function CodeGameScreenToroLocoMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self.m_lightEffectNode:removeAllChildren(true)

    -- self:clearCurMusicBg()

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    table.sort(self.m_chipList, function(a, b)
        if a.p_cloumnIndex == b.p_cloumnIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return a.p_cloumnIndex < b.p_cloumnIndex
    end)
    self:delayCallBack(0.5, function()
        self:playChipCollectAnim()    
    end)
end

--[[
    最后一个bonus 落地
]]
function CodeGameScreenToroLocoMachine:playRespinViewJiManEffect( )
    local chipNodeList = self.m_respinView:getAllCleaningNode()
    if self.m_isplayRespinViewBuling then
        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
            if self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons == 12 then
                self.m_respinNodeView:runCsbAction("buling", false)
                self.m_isplayRespinViewBuling = false
            end
        else
            if #chipNodeList == 12 then
                self.m_respinNodeView:runCsbAction("buling", false)
                self.m_isplayRespinViewBuling = false
            end
        end
    end
end

---判断结算
function CodeGameScreenToroLocoMachine:reSpinReelDown(addNode)
    self:runQuickEffect()
    self:removeLightRespin()
    if self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons == 11 and not self.m_isPlayRespinQuickRun then
        self.m_isPlayRespinQuickRun = true
        self.m_respinWheel:playLockIdle2()
    end
    if self.m_respinQuickRunSoundId then
        gLobalSoundManager:stopAudio(self.m_respinQuickRunSoundId)
        self.m_respinQuickRunSoundId = nil
    end

    self:resetMoveNodeStatus(function()
        CodeGameScreenToroLocoMachine.super.reSpinReelDown(self, addNode)
    end)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenToroLocoMachine:getRespinRandomTypes()
    local symbolList = { self.SYMBOL_BONUS,
        self.SYMBOL_EMPTY}
    return symbolList    
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenToroLocoMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = true}
    }
    return symbolList    
end

---
-- 触发respin 玩法
--
function CodeGameScreenToroLocoMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:levelDeviceVibrate(6, "respin")
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self:stopLinesWinSound()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:delayCallBack(0.5, function()
            self:showRespinView(effectData)
        end)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenToroLocoMachine:showRespinView()
    self.m_isComeInRespin = true
    self.m_isPlayRespinQuickRun = false
    self.m_respinWheel:updateTrainNode()
    self:clearCurMusicBg()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_lightScore = 0   

    --先播放动画 再进入respin
    self:triggerRespinAni(function()
        self:showReSpinStart(function()
            self:playGuoChangEffect(function()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)

                self:setReelBg(3)
                
                self.m_respinWheel:playLockIdle()
                self.m_respinWheel:wheelRun()

                self:runQuickEffect()

                self.m_respinWheelStart:setVisible(false)
            end, function()

            end, false)
        end)
    end)
end

function CodeGameScreenToroLocoMachine:startReSpinRun( )
    self.m_isComeInRespin = false
    self.m_isplayRespinViewBuling = true
    self.m_isPlayUpdateRespinNums = true
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    CodeGameScreenToroLocoMachine.super.startReSpinRun(self)
    self:moveRootNodeAction()

    local isLastRespin = self:getIsLastRespin()
    if self.m_lightEffectNode:getChildByName("quickRunEffect") and isLastRespin then
        self.m_respinQuickRunSoundId = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respin_quickRun)
    end
end

--[[
    respin触发动画
]]
function CodeGameScreenToroLocoMachine:triggerRespinAni(func)
    local delayTime = 0

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_bonus_trigger)
    --触发动画
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
            util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
            symbolNode:runAnim("actionframe", false, function()
                symbolNode:runAnim("idleframe2", true)
            end)
            local aniTime = symbolNode:getAniamDurationByName("actionframe")
            if delayTime < aniTime then
                delayTime = aniTime
            end
        end
    end

    if type(func) == "function" then
        self:delayCallBack(delayTime + 0.5,func)
    end
end

--触发respin
function CodeGameScreenToroLocoMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

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
    self.m_respinNodeView:findChild("Node_sp_reel"):addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenToroLocoMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum-1,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount, true)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            self:runNextReSpinReel()
        end
    )
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenToroLocoMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum-1 do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType ~= self.SYMBOL_BONUS then
                symbolType = self.SYMBOL_EMPTY
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReSpinReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_respinViewScale * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_respinViewScale * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

function CodeGameScreenToroLocoMachine:getReSpinReelPos(col)
    local reelNode = self.m_respinNodeView:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

function CodeGameScreenToroLocoMachine:showReSpinStart(func)
    local view = self:showDialog("ReSpinStart", nil, func)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
    view:findChild("root"):setScale(self.m_machineRootScale)
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respinStartView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_ToroLoco_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respinStartView_over)
    end)

    -- 添加光
    local guangNode = util_createAnimation("ToroLoco_glow.csb")
    view:findChild("Node_glow"):addChild(guangNode)
    guangNode:runCsbAction("idle", true)
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_glow"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("Node_glow"), true)

    for index = 1, 2 do
        local jueSeSpine = util_spineCreate("ToroLoco_guochang",true,true)
        view:findChild("Node_juese"):addChild(jueSeSpine)
        util_spinePlay(jueSeSpine, "freespin_start"..index, false)
        util_spineEndCallFunc(jueSeSpine, "freespin_start"..index, function ()
            util_spinePlay(jueSeSpine, "freespin_idle"..index, true)
        end)
    end
end

--ReSpin开始改变UI状态
function CodeGameScreenToroLocoMachine:changeReSpinStartUI(respinCount)
        
end

--ReSpin刷新数量
function CodeGameScreenToroLocoMachine:changeReSpinUpdateUI(curCount, isComeIn)
    print("当前展示位置信息  %d ", curCount)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinbar:updateRespinCount(curCount, totalCount, isComeIn)
end

--ReSpin结算改变UI状态
function CodeGameScreenToroLocoMachine:changeReSpinOverUI()
        
end

function CodeGameScreenToroLocoMachine:showRespinOverView(effectData)
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:playGuoChangFreeToBaseEffect(function()
            self:removeRespinNode()
            if self.m_bProduceSlots_InFreeSpin then
                self:setReelBg(2)
            else
                self:setReelBg(1)
            end
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:changeReelsByRespinOrFree()
            self.m_respinWheel:stopRoll()
        end, function()
            self:playGameEffect()
            self:resetMusicBg(true)
        end, false)
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respinOverView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_ToroLoco_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respinOverView_over)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},690)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenToroLocoMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        local params = {self:getLastWinCoin(), false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    else
        coins = self.m_serverWinCoins or 0
        local params = {self.m_serverWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    -- self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    -- self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
   free 玩法，respin玩法之后 恢复成触发时候 的棋盘
]]
function CodeGameScreenToroLocoMachine:changeReelsByRespinOrFree(_isFree)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerReels = {}
    if _isFree then
        triggerReels = selfdata.baseTriggerFreeReels or {}
        self.m_runSpinResultData.p_storedIcons = selfdata.baseTriggerFreeStoredIcons or {}
    else
        if not self.m_bProduceSlots_InFreeSpin then
            triggerReels = selfdata.baseTriggerReSpinReels or {}
            self.m_runSpinResultData.p_storedIcons = selfdata.baseTriggerReSpinStoredIcons or {}
        else
            triggerReels = selfdata.freeTriggerReSpinReels or {}
            self.m_runSpinResultData.p_storedIcons = selfdata.freeTriggerReSpinStoredIcons or {}
        end
    end
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType and #triggerReels > 0 then
                local symbolType = nil
                if iRow == 1 then
                    symbolType = triggerReels[3][iCol]
                elseif iRow == 3 then
                    symbolType = triggerReels[1][iCol]
                else
                    symbolType = triggerReels[iRow][iCol]
                end
                if symbolType then
                    self:changeSymbolType(symbolNode, symbolType)
                    if symbolType == self.SYMBOL_BONUS then
                        symbolNode:runAnim("idleframe2", true)
                        self:setSpecialNodeScore(symbolNode)
                        util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        symbolNode:runAnim("idleframe2", true)
                        util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    end
                end
            end
        end
    end
end

function CodeGameScreenToroLocoMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:clearCurMusicBg()

    self:showRespinOverView()
end

--结束移除小块调用结算特效
function CodeGameScreenToroLocoMachine:removeRespinNode()
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfMakeData.fifthColumnInfo and #selfMakeData.fifthColumnInfo > 0 then
        self.m_runSpinResultData.p_selfMakeData.fifthColumnInfo = {}
    end

    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        --respin结束 移除respin小块
        self:checkRemoveReelNode(node)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

--respin结束 移除respin小块对应位置滚轴中的小块
function CodeGameScreenToroLocoMachine:checkRemoveReelNode(symbolNode)
    if symbolNode and symbolNode.p_symbolType then
        symbolNode:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(symbolNode.p_symbolType, symbolNode)
    end
end

-- --重写组织respinData信息
function CodeGameScreenToroLocoMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo    
end

--[[
    快滚特效 respin
]]
function CodeGameScreenToroLocoMachine:runQuickEffect()
    self.m_qucikRespinNode = {}
    local bonus_count = #self.m_runSpinResultData.p_storedIcons
    local isLastRespin = self:getIsLastRespin()

    if bonus_count >= 11 then
        if self.m_respinView then
            for _index = 1, #self.m_respinView.m_respinNodes do
                local repsinNode = self.m_respinView.m_respinNodes[_index]
                if repsinNode.m_runLastNodeType == self.SYMBOL_EMPTY then
                    self.m_qucikRespinNode[#self.m_qucikRespinNode + 1] = {
                        node = repsinNode
                    }
                else
                    repsinNode:changeRunSpeed(false)
                end
            end
        end
    end

    if #self.m_qucikRespinNode > 0 then
        if not self.m_lightEffectNode:getChildByName("quickRunEffect") then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respin_quickRun_start)
            self.m_lightEffectNode:removeAllChildren(true)
            for _index = 1, #self.m_qucikRespinNode do
                local quickRunInfo = self.m_qucikRespinNode[_index]
                if not quickRunInfo.isEnd then
                    local light_effect = util_createAnimation("ToroLoco_ReSpinBar_tx.csb")
                    light_effect:runCsbAction("actionframe", true)  --普通滚动状态
                    self.m_lightEffectNode:addChild(light_effect)
                    light_effect:setName("quickRunEffect")
                    light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node, self.m_lightEffectNode))
                    if isLastRespin then
                        quickRunInfo.node:changeRunSpeed(true, isLastRespin)
                    end
                end
            end
        else
            for _index = 1, #self.m_qucikRespinNode do
                local quickRunInfo = self.m_qucikRespinNode[_index]
                if not quickRunInfo.isEnd then
                    if isLastRespin then
                        quickRunInfo.node:changeRunSpeed(true, isLastRespin)
                    end
                end
            end
        end
    end
end

--[[
    移除快滚特效 respin
]]
function CodeGameScreenToroLocoMachine:removeLightRespin()
    local bonus_count = #self.m_runSpinResultData.p_storedIcons

    if bonus_count >= 12 then
        self.m_lightEffectNode:removeAllChildren(true)
    end
end

--[[
    判断是否是 respin 最后一次
]]
function CodeGameScreenToroLocoMachine:getIsLastRespin( )
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount or 1
    local isLastRespin = false
    -- 判断是否是 respin 最后一次
    if reSpinCurCount == 1 then
        isLastRespin = true
    end
    
    return isLastRespin
end

--[[
    拉伸镜头效果
]]
function CodeGameScreenToroLocoMachine:moveRootNodeAction()
    if #self.m_qucikRespinNode == 0 then
        return 
    end

    local isLastRespin = self:getIsLastRespin()
    if not isLastRespin then
        return
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respin_shot_amplify)

    local moveNode = self:findChild("Node_1")
    local parentNode = moveNode:getParent()

    local params = {
        moveNode = moveNode,--要移动节点
        targetNode = self.m_qucikRespinNode[1].node,--目标位置节点
        parentNode = parentNode,--移动节点的父节点
        time = 2.8,--移动时间
        actionType = 3,
        scale = 2,--缩放倍数
    }

    self.m_isRespinQuickRunLast = true
    util_moveRootNodeAction(params)
end

--[[
    重置移动节点状态
]]
function CodeGameScreenToroLocoMachine:resetMoveNodeStatus(_func)
    if self.m_isRespinQuickRunLast then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respin_shot_reduce)

        self.m_isRespinQuickRunLast = false
        local moveNode = self:findChild("Node_1")
        --恢复移动节点状态
        local spawn = cc.Spawn:create({
            cc.MoveTo:create(0.5,cc.p(0,0)),
            cc.ScaleTo:create(0.5,1)
        })
        moveNode:stopAllActions()
        moveNode:runAction(cc.Sequence:create(
            cc.EaseSineInOut:create(spawn),
            cc.CallFunc:create(function()
                self:playWheelStartEffect(function()
                    if _func then
                        _func()
                    end
                end)
            end)))
    else
        self:delayCallBack(0.5, function()
            self:playWheelStartEffect(function()
                if _func then
                    _func()
                end
            end)
        end)
    end
end

--[[
    wheel开始 之前的期待动画
]]
function CodeGameScreenToroLocoMachine:playWheelStartEffect(_func)
    local chipList = self.m_respinView:getAllCleaningNode()
    if chipList and #chipList == 12 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_respin_jiman)
        self.m_respinWheelStart:setVisible(true)
        -- self.m_respinJiManEffect:setVisible(true)
        for index = 1, 5 do
            if self.m_respinWheelStart:findChild("Particle_"..index) then
                self.m_respinWheelStart:findChild("Particle_"..index):resetSystem()
            end
        end
        -- util_spinePlay(self.m_respinJiManEffect, "actionframe")
        -- util_spineEndCallFunc(self.m_respinJiManEffect, "actionframe", function()
        --     self.m_respinJiManEffect:setVisible(false)
            
        -- end)

        self.m_respinWheelStart:runCsbAction("actionframe", false)
        self:delayCallBack((75+60)/60, function()
            for index = 1, 5 do
                if self.m_respinWheelStart:findChild("Particle_"..index) then
                    self.m_respinWheelStart:findChild("Particle_"..index):stopSystem()
                end
            end

            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.fifthColumnInfo then
                self.m_respinWheel:produceDatas(self.m_runSpinResultData.p_selfMakeData.fifthColumnInfo)
            end

            self.m_respinWheel:playWheelUnlockEffect(function()
                if _func then
                    _func()
                end
            end)
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    respin棋盘震动
]]
function CodeGameScreenToroLocoMachine:playRespinReelShakeEffect()
    self:runCsbAction("actionframe_respin", false)
end

function CodeGameScreenToroLocoMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeToroLocoSrc.ToroLocoJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenToroLocoMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeToroLocoSrc.ToroLocoJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

function CodeGameScreenToroLocoMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == self.SYMBOL_BONUS then
        _slotNode:runAnim("idleframe2", true)
    end
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

function CodeGameScreenToroLocoMachine:setReelRunInfo()
    -- free玩法里 不快滚
    if not self.m_bProduceSlots_InFreeSpin then
        local longRunConfigs = {}
        local reels =  self.m_stcValidSymbolMatrix
        self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
        table.insert(longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
        self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
        self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态   
    end 
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenToroLocoMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenToroLocoMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenToroLocoMachine:isPlayExpect(reelCol)
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
function CodeGameScreenToroLocoMachine:getFeatureGameTipChance()
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local isNotice = (math.random(1, 100) <= 40)
        return isNotice
    end

    return false
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenToroLocoMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then
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

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
    下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
]]
function CodeGameScreenToroLocoMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_yugao)

    self.b_gameTipFlag = true
    self.m_yugaoSpineEffect:setVisible(true)
    util_spinePlay(self.m_yugaoSpineEffect,"actionframe_yugao",false)
    util_spineEndCallFunc(self.m_yugaoSpineEffect, "actionframe_yugao" ,function ()
        self.m_yugaoSpineEffect:setVisible(false)
    end) 

    self.m_yugaoEffect:setVisible(true)
    self.m_yugaoEffect:runCsbAction("actionframe_yugao", false, function()
        self.m_yugaoEffect:setVisible(false)
    end)

    --动效执行时间
    local aniTime = 2

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown(5)

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
    end)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenToroLocoMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_bigwin_yugao)

    self.m_bigWinEffect:setVisible(true)

    util_spinePlay(self.m_bigWinEffect, "actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWinEffect, "actionframe_bigwin", function()
        self.m_bigWinEffect:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenToroLocoMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] and not self.m_isColReelsSlowRun[_slotNode.p_cloumnIndex] and self:checkSymbolBulingAnimPlay(_slotNode) then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)

                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, _slotNode.p_cloumnIndex*10)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            else
                if _slotNode.p_symbolType == self.SYMBOL_BONUS then
                    _slotNode:runAnim("idleframe2", true)
                end
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenToroLocoMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- 慢滚的列不播放 落地动画
            if self.m_isColReelsSlowRun[_slotNode.p_cloumnIndex] then
                return false
            end
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                if _slotNode.p_symbolType == self.SYMBOL_BONUS then
                    if _slotNode.p_cloumnIndex <= 3 then
                        return true
                    else
                        return self:getBonusNums()
                    end
                end
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--[[
    @desc: 
    author:{author}
    time:2023-06-25 10:56:20
    @return:
]]
function CodeGameScreenToroLocoMachine:getBonusNums( )
    local bonusNums = 0
    for iCol = 1, self.m_iReelColumnNum - 2 do
        for iRow = 1, self.m_iReelRowNum do
            local symbol = self:getMatrixPosSymbolType(iRow, iCol)
            if symbol == self.SYMBOL_BONUS then
                bonusNums = bonusNums + 1
            end
        end
    end
    if bonusNums >= 3 then
        return true
    end
    return false
end

function CodeGameScreenToroLocoMachine:beginReel()
    self:isPlayReelsMove()
    self.m_freeCollectIndex = 1
    self.m_freeCollectBonusIndex = 1
    self.m_betComeInCoins = 0
    -- self:showColorLayer()

    CodeGameScreenToroLocoMachine.super.beginReel(self)
end

---
-- 点击快速停止reel
--
function CodeGameScreenToroLocoMachine:quicklyStopReel(colIndex)
    CodeGameScreenToroLocoMachine.super.quicklyStopReel(self, colIndex)
    if self.m_bonusMoveSound then
        gLobalSoundManager:stopAudio(self.m_bonusMoveSound)
        self.m_bonusMoveSound = nil
    end
end

-------------------------棋盘慢滚 begin -------------------------------
--[[
    判断是否有慢滚
]]
function CodeGameScreenToroLocoMachine:isPlayReelsMove( )
    self.m_reelsFalseRoll = {}
    self.m_isColReelsSlowRun = {false, false, false, false, false}

    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local reelsData = {}
    if not self.m_bProduceSlots_InFreeSpin then
        reelsData = self.m_betCollectReels[tostring(totalBet)]
    else
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        reelsData = selfdata.bonusReelsParams or {}
    end
    if reelsData and #reelsData > 0 then
        for _, _reelsData in ipairs(reelsData) do
            if _reelsData.renew then
                self:createReelsMove(_reelsData.column+1, _reelsData)
            end
        end
        self:delayCallBack(self.m_configData.p_reelBeginJumpTime, function()
            self.m_bonusMoveSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_bonus_move)
        end)
    end
end

--[[
    慢滚reel上的bonus 显示数值
]]
function CodeGameScreenToroLocoMachine:showReelsBonusCoins(_symbolNode, _index, _reelsData)
    local coinsView = util_createAnimation("Socre_ToroLoco_Bonus_Zi.csb")
    util_spinePushBindNode(_symbolNode, "wenzi", coinsView)

    local pos = nil
    if _index == 4 or _index == 3 then
        pos = self:getPosReelIdx(1, _reelsData.column+1)
    elseif _index == 2 then
        pos = self:getPosReelIdx(2, _reelsData.column+1)
    else
        pos = self:getPosReelIdx(3, _reelsData.column+1)
    end

    local score = 0
    local type = nil
    local storeIcons = _reelsData.nextStoredIcons
    if _index == 4 then
        storeIcons = _reelsData.curStoredIcons
    end
    for _, _storeIcons in ipairs(storeIcons) do
        if pos == _storeIcons[1] then
            score = _storeIcons[2]
            type = _storeIcons[3]
            break
        end
    end

    self:showBonusJackpotOrCoins(coinsView, score, type)
end

--[[
    创建 假的慢滚滚轴
]]
function CodeGameScreenToroLocoMachine:createReelsMove(_col, _reelsData)
    self.m_isColReelsSlowRun[_col] = true

    local reelNode = self:findChild("sp_reel_" .. (_col - 1))
    local reelSize = reelNode:getContentSize()
    local pos = cc.p(util_convertToNodeSpace(reelNode, self.m_onceClipNode))
    local reelsNode = util_createAnimation("ToroLoco_Reels.csb")
    self.m_onceClipNode:addChild(reelsNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10000 + _col)
    reelsNode:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)

    --遮罩
    local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
    panel:setOpacity(0)
    panel:setAnchorPoint(cc.p(0, 0))
    panel:setContentSize(reelSize.width, reelSize.height/3*4)
    panel:setPosition(cc.p(0, 0))
    reelsNode:findChild("Node_rootNew"):addChild(panel, 98)
    reelsNode.panel = panel
    self.m_reelsFalseRoll[_col] = reelsNode

    for index = 1, 4 do
        local symbolType = 0
        if index == 4 then
            symbolType = _reelsData.curColumn[3]
        else
            symbolType = _reelsData.nextColumn[index]
        end
        local symbolName = self:getSymbolCCBNameByType(self, symbolType)
        if symbolType ~= self.SYMBOL_BONUS then
            local symbolNode = display.newSprite("#ToroLocoSymbol/"..symbolName..".png")
            reelsNode:findChild("Node_"..index):addChild(symbolNode)
            symbolNode:setScale(0.5)
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                reelsNode:findChild("Node_"..index):setLocalZOrder(99)
            end
        else
            local symbolNode = util_spineCreate(symbolName, true, true)
            reelsNode:findChild("Node_"..index):addChild(symbolNode)
            reelsNode:findChild("Node_"..index):setLocalZOrder(100+index)
            self:showReelsBonusCoins(symbolNode, index, _reelsData)
            util_spinePlay(symbolNode, "idleframe2", true)
        end
    end

    self.m_reels[_col].m_baseNode:setVisible(false)
    self.m_reels[_col].m_topNode:setVisible(false)

    reelsNode:findChild("Node_root"):runAction(cc.Sequence:create(
        cc.JumpTo:create(self.m_configData.p_reelBeginJumpTime, cc.p(0, 0), self.m_configData.p_reelBeginJumpHight, 1),
        cc.MoveTo:create(1.5, cc.p(0, -self.m_SlotNodeH))
    ))
end

--[[
    收到服务器数据 之后 修改假滚移动
]]
function CodeGameScreenToroLocoMachine:changeReelsMove( )
    -- if self.m_reelsFalseRoll then
    --     for _col, _reelsNode in pairs(self.m_reelsFalseRoll) do
    --         _reelsNode:findChild("Node_root"):stopAllActions()
            
    --         local moveTime = self:getRunTimeBeforeReelDown(_col)
    --         _reelsNode:findChild("Node_root"):runAction(cc.Sequence:create(
    --             cc.MoveTo:create(moveTime + 0.2, cc.p(0, -self.m_SlotNodeH))
    --         ))
    --     end
    -- end
end

--[[
    获取停轮前假滚时间
]]
function CodeGameScreenToroLocoMachine:getRunTimeBeforeReelDown(_col)
    --获取滚动速度
    local moveSpeed = self.m_configData.p_reelMoveSpeed
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_configData.p_fsReelMoveSpeed then
        moveSpeed = self.m_configData.p_fsReelMoveSpeed
    end
    --获取滚动距离
    local runLen = self.m_configData.p_reelRunDatas[_col]
    local distance = self.m_SlotNodeH * runLen
    local delayTime = distance / moveSpeed

    return delayTime
end

--[[
    销毁 假的慢滚滚轴
]]
function CodeGameScreenToroLocoMachine:removeReelsMove()
    if self.m_reelsFalseRoll then
        for _col, _reelsNode in pairs(self.m_reelsFalseRoll) do
            _reelsNode:removeFromParent()
            _reelsNode = nil

            self.m_reels[_col].m_baseNode:setVisible(true)
            self.m_reels[_col].m_topNode:setVisible(true)

            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
                if slotNode and (slotNode.p_symbolType == self.SYMBOL_BONUS or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
                    util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, slotNode.p_cloumnIndex*10)
                    slotNode:runAnim("idleframe2", true)
                end
            end
        end
    end

    self.m_reelsFalseRoll = {}
end
-------------------------棋盘慢滚 end -------------------------------

--[[
    过场动画
]]

function CodeGameScreenToroLocoMachine:playGuoChangEffect(_func1, _func2, _isFree)
    if _isFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_guochang_baseToFree)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_guochang_toRespin)
    end
    self.m_guochangEffect:setVisible(true)
    self.m_guochangEffectBg:setVisible(true)
    util_spinePlay(self.m_guochangEffect, "actionframe_guochang", false)
    self.m_guochangEffectBg:runCsbAction("actionframe_guochang", false)

    -- 切换 80帧
    self:delayCallBack(80/30, function()
        if _func1 then
            _func1()
        end
    end)

    -- 结束 105帧
    self:delayCallBack(105/30, function()
        if _func2 then
            _func2()
        end
        self.m_guochangEffect:setVisible(false)
        self.m_guochangEffectBg:setVisible(false)
    end)
end

--[[
    过场动画
]]

function CodeGameScreenToroLocoMachine:playGuoChangFreeToBaseEffect(_func1, _func2, _isFree)
    if _isFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_guochang_freeToBase)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_guochang_respin_end)
    end
    local guochangBg = util_createAnimation("ToroLoco/GameScreenToroLocoBg.csb")
    self:findChild("bg"):addChild(guochangBg, -1)
    guochangBg:findChild("free_bg"):setVisible(false)
    guochangBg:findChild("respin_bg"):setVisible(false)

    guochangBg:runCsbAction("switch", false)

    self.m_guochangEffect:setVisible(true)
    util_spinePlay(self.m_guochangEffect, "actionframe_guochang2", false)

    --  20帧
    self:delayCallBack(20/60, function()
        guochangBg:removeFromParent()
    end)

    -- 切换 20帧
    self:delayCallBack(20/30, function()
        if _func1 then
            _func1()
        end
        
    end)

    -- 结束 45帧
    self:delayCallBack(45/30, function()
        if _func2 then
            _func2()
        end
        self.m_guochangEffect:setVisible(false)
    end)
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenToroLocoMachine:initSlotNodes()
    CodeGameScreenToroLocoMachine.super.initSlotNodes(self)
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                symbolNode:runAnim("idleframe2", true)
            end
        end
    end
end

---
--设置bonus scatter 层级
function CodeGameScreenToroLocoMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenToroLocoMachine.super.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    return order
end

function CodeGameScreenToroLocoMachine:scaleMainLayer()
    CodeGameScreenToroLocoMachine.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.width / display.height >= 1370/768 then
        self.m_respinViewScale = self.m_machineRootScale * 0.95
    elseif display.width / display.height >= 1228/768 then
        mainScale = mainScale * 1.0
        self.m_respinViewScale = self.m_machineRootScale * 0.91 * (1228/display.width)
    elseif display.width / display.height >= 1152/768 then
        mainScale = mainScale * 1
        self.m_respinViewScale = self.m_machineRootScale * 0.94 * (1152/display.width)
        self.m_gameBg:setPositionY(self.m_gameBg:getPositionY() - 30 )
        self.m_gameBg:setPositionX(self.m_gameBg:getPositionX() )
    elseif display.width / display.height >= 920/768 then
        mainScale = mainScale * 1.03
        self.m_respinViewScale = self.m_machineRootScale * 1.2 * (920/display.width)
        self.m_gameBg:setPositionY(self.m_gameBg:getPositionY() - 35 )
        self.m_gameBg:setPositionX(self.m_gameBg:getPositionX() )
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(0)
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenToroLocoMachine:checkPlayBonusDownSound(_node)
    local colIndex = _node.p_cloumnIndex
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        if _node.p_symbolType == self.SYMBOL_BONUS then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ToroLoco_bonus_buling)
        end
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    respin单列停止
]]
function CodeGameScreenToroLocoMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("ToroLocoSounds/sound_ToroLoco_reelDown.mp3")
        else
            gLobalSoundManager:playSound("ToroLocoSounds/sound_ToroLoco_reelDownQuickStop.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

return CodeGameScreenToroLocoMachine