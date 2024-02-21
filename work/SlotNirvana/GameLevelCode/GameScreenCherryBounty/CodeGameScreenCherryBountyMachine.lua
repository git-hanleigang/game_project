--[[
    玩法:
        base:
            wild收集
                触发: 滚出92信号
                表现: 滚出的92会收集到顶部收集栏 满一定数量收集栏升级
            wild固定
                触发: 滚出92信号
                表现: 固定棋盘上2次spin 第3次spin时滚走 滚出新的92会重置所有92次数
            4选1 
                触发: 至少1个94 且94和92总数大于等于6
                表现: "repsin"(3x5) "free1"(4次) "free2"(6次) "free3"(8次) 选1
            2选1 
                触发: 收集92随机触发
                表现: "super_respin"(3x7) "jackpot"(多福多彩)  选1
        free:
            触发: 选择玩法触发
            表现: 
        respin:
            触发: 选择玩法触发
            表现: 
                滚出95时 金额等于所有94的和 
                滚出96时 金额等于所有94 95的和
        多福多彩:
            触发: 选择玩法触发
            表现: 彩金可重复获得 选到over时统一结算
]]
--[[
    数据结构:
        // 进入关卡
        {
            gameConfig.extra = {
                // wild收集等级
                collect_stage = 1,
                // 所有bet的固定wild
                wildStick = {
                    "100" = {
                        leftTimes = 1,
                        wild_position = {0, 1, 2}
                    }
                }
            }
        }
        // spin返回
        {
            p_selfMakeData = {
                // wild剩余次数
                leftTimes = 1
                // wild坐标列表 
                wild_position = {0, 1, 2}
                // 本次滚出wild列表 
                collect_wild = {0, 1, 2}
                // wild收集等级
                collect_stage = 1

                // 选择玩法的类型 (2:4选1  3:2选1)
                bonus_type = 2,
                // 前端上传的选择类型 再次下发 ("free3", "free2", "free1", "repsin", "super_respin", "jackpot")
                kind = "free1",

                // respin-滚出的95
                bonus2_positon = {},
                // respin-滚出的96
                bonus3_positon = {},
                // superReSpin-初始棋盘包含随机94
                bonus_reels = {},
                // bonus图标的坐标和奖励 {坐标 金额}
                storedIcons_2 = { {0,"10000"} }

                // 多福多彩
                jackpot = {
                    // 总赢钱
                    winAmountValue = "0",
                    // 类型进度
                    winjackpotname = {"Mini", "Grand"}
                    // 金额进度
                    winjackpotValue ={"100000", "100000"}
                },
            },
            // bonus {位置, 金额}
            p_storedIcons = {
                 {0, 10000}
            }
            // 选择玩法
            p_bonusExtra = {
                // bonus2乘倍 用于计算单个bonus2金额
                bonus2_mult = 4,
                // 棋盘恢复-卷轴
                reels = {}
                // 棋盘恢复-触发时的selfData数据
                spinR_selfData = {}
            }
            // free
            p_fsExtraData = {
                // bonus2乘倍 用于计算单个bonus2金额
                bonus2_mult = 4,
                // free玩法乘倍 用于计算单个bonus2在free玩法内的金额
                mult = 3,
            }
        }
        // 前端发送
        {
            // 4选1
            messageData.msg  = MessageDataType.MSG_BONUS_SELECT
            messageData.data = "free3"
            // 2选1
            messageData.msg  = MessageDataType.MSG_BONUS_SELECT
            messageData.data = "super_respin"
        }
]]
local PublicConfig   = require "CherryBountyPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local CodeGameScreenCherryBountyMachine = class("CodeGameScreenCherryBountyMachine", BaseNewReelMachine)

CodeGameScreenCherryBountyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCherryBountyMachine.SYMBOL_Bonus1      = 94   --bonus-base模式1,5列出现
CodeGameScreenCherryBountyMachine.SYMBOL_Bonus2      = 95   --bonus-free内代替wild respin内落地时分值为bonus1总和
CodeGameScreenCherryBountyMachine.SYMBOL_Bonus3      = 96   --bonus-respin内落地时分值为bonus1~3总和
CodeGameScreenCherryBountyMachine.SYMBOL_ReSpinBlank = 100  --空图标-respin(带底图)
CodeGameScreenCherryBountyMachine.SYMBOL_Blank       = 200  --空图标

CodeGameScreenCherryBountyMachine.EFFECT_WildCollect        = GameEffect.EFFECT_SELF_EFFECT - 45   --wild收集
CodeGameScreenCherryBountyMachine.EFFECT_FreeCollectBonus   = GameEffect.EFFECT_SELF_EFFECT - 40   --free-收集bonus2
CodeGameScreenCherryBountyMachine.EFFECT_FreeOverSettlement = GameEffect.EFFECT_LINE_FRAME + 1     --free-结算bonus累计赢钱
CodeGameScreenCherryBountyMachine.EFFECT_PickGame           = GameEffect.EFFECT_SELF_EFFECT - 35   --多福多彩

CodeGameScreenCherryBountyMachine.ReSpinEffect_BonusDelay = 1 --bonus加总前置延时
CodeGameScreenCherryBountyMachine.ReSpinEffect_Bonus2     = 2 --bonus2加总
CodeGameScreenCherryBountyMachine.ReSpinEffect_Bonus3     = 3 --bonus3加总
CodeGameScreenCherryBountyMachine.ReSpinEffect_ReSpinMore = 4 --次数重置
CodeGameScreenCherryBountyMachine.ReSpinEffect_FullUp     = 5 --respin全满

CodeGameScreenCherryBountyMachine.SuperReSpinCol = 7 --超级respin列数

--彩金配置
CodeGameScreenCherryBountyMachine.ServerJackpotType = {
    Grand  = "Grand",
    Major  = "Major",
    Minor  = "Minor",
    Mini   = "Mini",
}
CodeGameScreenCherryBountyMachine.JackpotTypeToIndex = {
    [CodeGameScreenCherryBountyMachine.ServerJackpotType.Grand] = 1,
    [CodeGameScreenCherryBountyMachine.ServerJackpotType.Major] = 2,
    [CodeGameScreenCherryBountyMachine.ServerJackpotType.Minor] = 3,
    [CodeGameScreenCherryBountyMachine.ServerJackpotType.Mini]  = 4,
}
CodeGameScreenCherryBountyMachine.JackpotIndexToType = {
    CodeGameScreenCherryBountyMachine.ServerJackpotType.Grand,
    CodeGameScreenCherryBountyMachine.ServerJackpotType.Major,
    CodeGameScreenCherryBountyMachine.ServerJackpotType.Minor,
    CodeGameScreenCherryBountyMachine.ServerJackpotType.Mini,
}

-- 构造函数
function CodeGameScreenCherryBountyMachine:ctor()
    CodeGameScreenCherryBountyMachine.super.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    self.m_iBetLevel = 0
    self.m_spinAddBottomCoins = 0
    self.m_enterLevelData = {}
    --初始化数据-收集等级
    self.m_enterLevelData.curCollectLevel = 1
    --初始化数据-固定wild
    self.m_enterLevelData.lockWild = {}
    --关卡适配-特殊标记
    self.m_bSuperMainLayerFlag = false
    --wild落地收集音效
    self.m_wildCollectSoundList = {}
    --init
    self:initGame()
end

function CodeGameScreenCherryBountyMachine:initGame()
    local csvPath = "CherryBountyConfig.csv"
    local luaPath = "LevelCherryBountyCSVData.lua"
    self.m_configData = gLobalResManager:getCSVLevelConfigData(csvPath, luaPath)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCherryBountyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CherryBounty"  
end

function CodeGameScreenCherryBountyMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    --效果层-低
    self.m_effectNodeDown = cc.Node:create()
    self:addChild(self.m_effectNodeDown, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_effectNodeDown:setScale(self.m_machineRootScale)
    --效果层-高
    self.m_effectNodeUp = cc.Node:create()
    self:addChild(self.m_effectNodeUp, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNodeUp:setScale(self.m_machineRootScale)

    -- 棋盘上提示
    self.m_reelTips = util_createView("CherryBountySrc.CherryBountyReelTips", self)
    self:findChild("Node_baseTips"):addChild(self.m_reelTips)

    --free-顶部提示
    self.m_freeTips = util_createView("CherryBountySrc.CherryBountyTopFreeTips", self)
    self:findChild("Node_xinxiqu"):addChild(self.m_freeTips)
    self.m_freeTips:setVisible(false)
    --free-计数栏
    self.m_freeBar = util_createView("CherryBountySrc.CherryBountyFreeSpinBar", self)
    self:findChild("Node_baseTips"):addChild(self.m_freeBar)
    self.m_freeBar:setVisible(false)

    --reSpin-顶部提示
    self.m_reSpinTopTips = util_createView("CherryBountySrc.CherryBountyTopReSpinTips", self)
    self:findChild("Node_xinxiqu"):addChild(self.m_reSpinTopTips)
    self.m_reSpinTopTips:setVisible(false)
    --reSpin-棋盘提示
    self.m_reSpinReelTips = util_createView("CherryBountySrc.CherryBountyReSpinTips", self)
    self:findChild("Node_respinBar"):addChild(self.m_reSpinReelTips)
    self.m_reSpinReelTips:setVisible(false)

    --多福多彩-顶部提示
    self.m_pickGameTopTips = util_createView("CherryBountySrc.CherryBountyTopPickGameTips", self)
    self:findChild("Node_xinxiqu"):addChild(self.m_pickGameTopTips)
    self.m_pickGameTopTips:setVisible(false)
    --多福多彩-棋盘提示
    self.m_pickGameReelTips = util_createView("CherryBountySrc.CherryBountyPickGameReelTips", self)
    self:findChild("Node_baseTips"):addChild(self.m_pickGameReelTips)
    self.m_pickGameReelTips:setVisible(false)

    --棋盘裁切
    self:findChild("Panel_clip"):setClippingEnabled(false)

    -- 粒子池
    self.m_particleList1 = {}
    self.m_particleList2 = {}


    -- 图标期待
    self.m_symbolExpectCtr = util_createView("CherryBountySrc.CherryBountySymbolExpect", self)

    -- 预告中奖
    self.m_yugaoAnim = util_createView("CherryBountySrc.CherryBountyYuGao", self)

    -- 跳过
    self.m_skipLayer = util_createView("CherryBountySrc.CherryBountySkipLayer", self)
    self:findChild("Node_skip"):addChild(self.m_skipLayer) 
    self.m_skipLayer:setVisible(false)

    -- 遮罩
    self.m_maskCtr = util_createView("CherryBountySrc.CherryBountyMask", self)
    
    --固定wild
    local lockWildData = {}
    lockWildData.machine = self
    lockWildData.parent  = self:findChild("Node_lockWild")
    self.m_lockWild = util_createView("CherryBountySrc.CherryBountyLockWild", lockWildData)

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenCherryBountyMachine:initSpineUI()
    local spineName = "GameScreenCherryBountyBg"
    --关卡背景-高层
    self.m_spineBgUp = util_spineCreate(spineName, true, true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_spineBgUp, 100)
    --关卡背景-低层
    self.m_spineBgDown = util_spineCreate(spineName,true,true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_spineBgDown, 10)
    self.m_spineBgDown:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_gameBg, true)

    --彩金栏
    self.m_jackpotBar = util_createView("CherryBountySrc.CherryBountyJackPotBar", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
 
    --顶部-wild收集
    self.m_topWildCollect = util_createView("CherryBountySrc.CherryBountyTopWildCollect", self)
    self:findChild("Node_shoujiqu"):addChild(self.m_topWildCollect)

    --顶部-金色樱桃
    self.m_topBonus2 = util_createView("CherryBountySrc.CherryBountyTopBonus2", self)
    self:findChild("Node_xinxiqu"):addChild(self.m_topBonus2, 100)
    self.m_topBonus2:setVisible(false)

    self:changeReelBg("base", false)
end


function CodeGameScreenCherryBountyMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.sound_CherryBounty_EnterLevel)
    end)
end

function CodeGameScreenCherryBountyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCherryBountyMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local initData = self.m_enterLevelData
    self.m_topWildCollect:setCurLevel(initData.curCollectLevel)
    self.m_lockWild:initLockWildBetList(initData.lockWild)

    self:updateBetLevel(true)
    self:initCherryBountyFirstReel()
    self.m_topWildCollect:playIdleAnim()
    if self.m_bFreeReconnect then
        self:upDateFreeModelUi(true)
    end
end

function CodeGameScreenCherryBountyMachine:addObservers()
    CodeGameScreenCherryBountyMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        --if self.m_bIsBigWin then return end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate <= 3 then
            soundIndex = 2
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig[string.format("sound_CherryBounty_BaseLineFrame_%d", soundIndex)]
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig[string.format("sound_CherryBounty_FreeLineFrame_%d", soundIndex)]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenCherryBountyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:stopFeatureWinViewJumpCoinsSound(false)


    CodeGameScreenCherryBountyMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCherryBountyMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_Bonus1 then
        return "Socre_CherryBounty_Bonus1"
    end
    if symbolType == self.SYMBOL_Bonus2 then
        return "Socre_CherryBounty_Bonus2"
    end
    if symbolType == self.SYMBOL_Bonus3 then
        return "Socre_CherryBounty_Bonus3"
    end
    if symbolType == self.SYMBOL_ReSpinBlank then
        return "Socre_CherryBounty_ReSpinBlank"
    end
    if symbolType == self.SYMBOL_Blank then
        return "Socre_CherryBounty_Blank"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCherryBountyMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCherryBountyMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
function CodeGameScreenCherryBountyMachine:initGameStatusData(gameData)
    if gameData.gameConfig then
        local extra = gameData.gameConfig.extra
        if nil ~= extra then
            if extra.collect_stage then
                self.m_enterLevelData.curCollectLevel = extra.collect_stage
            end
            if extra.wildStick then
                self.m_enterLevelData.lockWild = extra.wildStick
            end
        end
    end
    --选择玩法数据覆盖spin数据 覆盖后舍弃feature
    if gameData.feature then
        gameData.spin.features    = clone(gameData.feature.features)
        gameData.spin.selfData    = clone(gameData.feature.selfData)
        gameData.spin.freespin    = clone(gameData.feature.freespin)
        local respin = gameData.feature.respin or {}
        gameData.spin.respin      = clone(respin)
        gameData.spin.storedIcons = clone(gameData.feature.storedIcons)
        --superRespin的卷轴必须是7列
        if respin and respin.extra and respin.extra.reels then
            local respin_reels = respin.extra.reels or {}
            local bonus_reels  = respin.extra.bonus_reels or {}
            if bonus_reels[1] and respin_reels[1] then
                if #bonus_reels[1] > #respin_reels[1] then
                    gameData.spin.reels = clone(respin.extra.bonus_reels)
                else
                    gameData.spin.reels = clone(respin.extra.reels)
                end
            end
        end
        gameData.feature = nil
    end
    CodeGameScreenCherryBountyMachine.super.initGameStatusData(self, gameData)
end
-- 断线重连 
function CodeGameScreenCherryBountyMachine:MachineRule_initGame()
    --free断线
    if self.m_bProduceSlots_InFreeSpin then
        self.m_bFreeReconnect = true
    end
    --reSpin断线
    if self:isTriggerCherryBountyReSpin() then
        self.m_bReSpinReconnect = true
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCherryBountyMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    self.m_spinAddBottomCoins = 0
    self.m_wildCollectSoundList = {}
    self.m_symbolExpectCtr:MachineSpinBtnCall()
    self.m_lockWild:MachineSpinBtnCall()
    self:spinUpDateLockWild()

    return false
end
function CodeGameScreenCherryBountyMachine:beginReel()
    CodeGameScreenCherryBountyMachine.super.beginReel(self)
    self.m_maskCtr:playReelMaskStart()
end

--
--单列滚动停止回调
--
function CodeGameScreenCherryBountyMachine:slotOneReelDown(reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
    if 1 == reelCol then
        self.m_maskCtr:playReelMaskOver()
    end
    CodeGameScreenCherryBountyMachine.super.slotOneReelDown(self,reelCol)
end
-- 不用系统音效
function CodeGameScreenCherryBountyMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
--重写-落地动画音效检测
function CodeGameScreenCherryBountyMachine:checkSymbolBulingSoundPlay(_symbol)
    local bBuling = CodeGameScreenCherryBountyMachine.super.checkSymbolBulingSoundPlay(self, _symbol)
    if bBuling then
        if _symbol.p_symbolType == self.SYMBOL_Bonus1 then
            local iCol = _symbol.p_cloumnIndex
            local wildCount  = self:getReelSymbolCountByCol(TAG_SYMBOL_TYPE.SYMBOL_WILD, iCol)
            local bonusCount = self:getReelSymbolCountByCol(self.SYMBOL_Bonus1, iCol)
            local checkCount = 6 - (self.m_iReelColumnNum - iCol) * 2
            bBuling = wildCount + bonusCount >= checkCount
        end
    end
    return bBuling
end
--重写-落地动画播放
function CodeGameScreenCherryBountyMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    self:playCherryBountyWildBuling(slotNodeList, speedActionTable)
    CodeGameScreenCherryBountyMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
end
function CodeGameScreenCherryBountyMachine:playCherryBountyWildBuling(_symbolList, _speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    local wildList = {}
    for i,_symbol in ipairs(_symbolList) do
        local symbolType = _symbol.p_symbolType
        local symbolCfg = bulingAnimCfg[symbolType]
        if symbolCfg then
            if self:checkSymbolBulingAnimPlay(_symbol) then
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    _symbol:setIdleAnimName("idleframe2")
                    _symbol.p_idleIsLoop = true
                    self.m_lockWild:playLockWildBulingAnim(_symbol, _speedActionTable)
                    table.insert(wildList, _symbol)
                end
            end
        end
    end
    --落地时收集
    if #wildList > 0 then
        self:playWildBulingCollect(wildList)
    end
end
--重写-落地动画-落地回调
function CodeGameScreenCherryBountyMachine:symbolBulingEndCallBack(_symbol)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_symbol)
end
--滚轮停止
function CodeGameScreenCherryBountyMachine:slotReelDown()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenCherryBountyMachine.super.slotReelDown(self)
end

---------------------------------------------------------------------------


--添加关卡中触发的玩法
function CodeGameScreenCherryBountyMachine:addOneSelfEffect(_sEType)
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = _sEType
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = _sEType 
end
function CodeGameScreenCherryBountyMachine:addSelfEffect()
    if self:isTriggerEFFECT_FreeCollectBonus() then
        self:addOneSelfEffect(self.EFFECT_FreeCollectBonus)
    end
    if self:isTriggerEFFECT_FreeOverSettlement() then
        self:addOneSelfEffect(self.EFFECT_FreeOverSettlement)
    end
end
--播放玩法动画
function CodeGameScreenCherryBountyMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_FreeCollectBonus then
        self:levelPerformWithDelay(self , 0.5, function()
            self:playEFFECT_FreeCollectBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_FreeOverSettlement then
        local delayTime = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and 1.1 or 0
        self:levelPerformWithDelay(self , delayTime, function()
            self:playEFFECT_FreeOverSettlement(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_PickGame then
        self:playEFFECT_PickGame(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end
function CodeGameScreenCherryBountyMachine:playEffectNotifyNextSpinCall()
    local bQuickStop = self:getGameSpinStage() == QUICK_RUN

    CodeGameScreenCherryBountyMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenCherryBountyMachine:checkRemoveBigMegaEffect()
    CodeGameScreenCherryBountyMachine.super.checkRemoveBigMegaEffect(self)
    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and 
        self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
        self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenCherryBountyMachine:getShowLineWaitTime()
    local time = CodeGameScreenCherryBountyMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    --insert-getShowLineWaitTime
    local winLines = self.m_reelResultLines or {}
    local lineValue = winLines[1] or {}
    if #winLines == 1 and lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        time = 0
    end 

    return time
end

----------------------------新增接口插入位---------------------------------------------
--重写-处理固定wild连线
function CodeGameScreenCherryBountyMachine:showLineFrame()
    self.m_lockWild:hideLockWildByLineFrame()
    --连线跳钱只增长连线的金额
    local lastCoins = self:getLastWinCoin()
    local spinWinCoins = self.m_runSpinResultData.p_winAmount
    local lineWinCoins = self:getClientWinCoins()
    local bOtherWinCoins = spinWinCoins ~= lineWinCoins
    if bOtherWinCoins then
        self.m_iOnceSpinLastWin = lineWinCoins
        local tempLastCoins = lastCoins - spinWinCoins + self.m_spinAddBottomCoins + lineWinCoins
        self:setLastWinCoin(tempLastCoins)
    end
    CodeGameScreenCherryBountyMachine.super.showLineFrame(self)
    self:setLastWinCoin(lastCoins)
end
--重写-重置固定wild
function CodeGameScreenCherryBountyMachine:clearWinLineEffect()
    -- self.m_lockWild:showLockWildByLineFrameOver()
    CodeGameScreenCherryBountyMachine.super.clearWinLineEffect(self)
end
--重写-free连线
function CodeGameScreenCherryBountyMachine:showLineFrameByIndex(winLines,frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    self.super.showLineFrameByIndex(self, winLines, frameIndex)    
end
--重写-free连线
function CodeGameScreenCherryBountyMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    self.super.showAllFrame(self, tempLineValue)    
end
--高低bet-切换回调
function CodeGameScreenCherryBountyMachine:updateBetLevel(_bUpdateUi)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local level = self:getBetLevel(totalBet)
    local curLockState = self.m_iBetLevel < 1
    local newLockState = level < 1
    local bChange = curLockState ~= newLockState
    self.m_iBetLevel = level
    --锁定状态发生变更刷新UI
    if _bUpdateUi or bChange then
        self:lockStateChangeUpDateUi(newLockState, _bUpdateUi)
    end
    self:changeBetUpDateLockWild(_bUpdateUi)
end
--高低bet-锁定状态变更
function CodeGameScreenCherryBountyMachine:lockStateChangeUpDateUi(_newLockState, _bUpdateUi)
    --锁定
    if _newLockState then
        self.m_jackpotBar:playLockAnim()
    --解锁 
    else
        self.m_jackpotBar:playUnLockAnim()
    end
    if not _bUpdateUi then
        if _newLockState then
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_GrandLock)
        else
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_GrandUnLock)
        end
    end
end
--高低bet-获取bet等级
function CodeGameScreenCherryBountyMachine:getBetLevel(_betValue)
    local lockBet = self:getLockBetValue()
    local betLevel = 0
    if _betValue >= lockBet then
        betLevel = 1
    end
    return betLevel
end
--高低bet-锁定状态
function CodeGameScreenCherryBountyMachine:getCurLockState()
    return self.m_iBetLevel < 1
end
--高低bet-临界值
function CodeGameScreenCherryBountyMachine:getLockBetValue()
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local lockBet = 0
    if specialBets[1] and specialBets[1].p_totalBetValue then
        lockBet = specialBets[1].p_totalBetValue
    end
    return lockBet
end

----------------------------玩法处理
--wild收集
function CodeGameScreenCherryBountyMachine:isTriggerEFFECT_WildCollect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildNewPos = selfData.collect_wild or {}
    if #wildNewPos > 0 then 
        return true
    end
    return false
end
-- function CodeGameScreenCherryBountyMachine:playEFFECT_WildCollect(_fun)
--     gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Wild_collectFly)
--     self.m_lockWild:hideLockWildByLineFrame()
--     local selfData = self.m_runSpinResultData.p_selfMakeData
--     local curLevel = self.m_topWildCollect:getCurLevel()
--     local wildNewPos = selfData.collect_wild
--     local bSuperSelect = self:isSuperSelectBonusGame()
--     local bTrigger = bSuperSelect or "" ~= self.m_yugaoAnim:isTriggerFreeYugaoAnim()
--     local newLevel = selfData.collect_stage
--     if bTrigger then
--         newLevel = self.m_topWildCollect.m_maxLevel
--     end
--     self.m_topWildCollect:setCurLevel(newLevel)
--     local bUpGrade = newLevel > curLevel
--     local animName = "shouji"
--     local animTime = 0 
--     local symbolList = {}
--     for i,_reelPos in ipairs(wildNewPos) do
--         local fixPos = self:getCherryBountyRowAndColByPos(_reelPos)
--         local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
--         animTime = symbol:getAniamDurationByName(animName)
--         symbol:runAnim(animName, false, function()
--             self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
--         end)
--         table.insert(symbolList, symbol)
--     end
--     --第10帧飞出钻石
--     --9/30
--     local flyDelay = 0
--     local flyTime  = 21/30
--     self:levelPerformWithDelay(self, flyDelay,function()
--         gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Wild_numStart)
--         --区分是否触发玩法时的事件延时 不卡spin
--         local fnNext = function(_bTrigger)
--             if bTrigger == _bTrigger then
--                 _fun()
--             end
--         end
--         local parent = self.m_effectNodeDown
        
--         local endPos = util_convertToNodeSpace(self.m_topWildCollect, parent)
--         for i,_symbol in ipairs(symbolList) do
--             local tempSymbol = util_createView("CherryBountySrc.CherryBountyTempSymbol", {machine=self})
--             parent:addChild(tempSymbol)
--             tempSymbol:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_WILD)
--             self:upDateWildSymbolSkin(tempSymbol, 3)
--             tempSymbol:setPosition(util_convertToNodeSpace(_symbol, parent))
--             local actList = {}
--             table.insert(actList, cc.MoveTo:create(flyTime, endPos))
--             table.insert(actList, cc.RemoveSelf:create())
--             tempSymbol:runAnim("fly", false)
--             tempSymbol:runAction(cc.Sequence:create(actList))
--         end
--         --收集反馈
--         self:levelPerformWithDelay(self, flyTime,function()
--             --升级检测
--             if bUpGrade then
--                 gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_CollectBar_upGrade)
--                 self.m_topWildCollect:playUpGradeAnim(nil, function()
--                     fnNext(true)
--                 end)
--             else
--                 gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Wild_collectFeedback)
--                 self.m_topWildCollect:playCollectAnim(nil, function()
--                     fnNext(true)
--                 end)
--             end
--         end)
--         fnNext(false)
--     end)
-- end
--wild按列收集
function CodeGameScreenCherryBountyMachine:playWildBulingCollect(_symbolList)
    local parent = self.m_effectNodeDown
    local flyDelay = 7.5/30
    local flyTime  = 13.5/30
    local endPos   = util_convertToNodeSpace(self.m_topWildCollect, parent)
    --升级反馈放在最后一个wild上 其余播普通反馈
    local wildSymbol = _symbolList[1]
    local iCol = wildSymbol.p_cloumnIndex
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildNewPos = selfData.collect_wild
    local bLast = true
    for i,_wildPos in ipairs(wildNewPos) do
        local fixPos = self:getCherryBountyRowAndColByPos(_wildPos) 
        if iCol < fixPos.iY then
            bLast = false
            break
        end
    end
    local bTrigger = self:isSuperSelectBonusGame()
    local curLevel = self.m_topWildCollect:getCurLevel()
    local newLevel = curLevel
    if bLast then
        if bTrigger then
            newLevel = self.m_topWildCollect.m_maxLevel
        else
            newLevel = selfData.collect_stage
        end
    end
    local bUpGrade = false
    --最后一个wild执行收集时 修改收集栏等级 如果有升级播升级反馈
    if bLast then
        self.m_topWildCollect:setCurLevel(newLevel)
        bUpGrade = newLevel > curLevel
    end
    self:playWildBulingCollectSound(iCol, bUpGrade, flyDelay, flyTime)
    --延时飞行
    self:levelPerformWithDelay(self, flyDelay, function()
        for i,_symbol in ipairs(_symbolList) do
            local tempSymbol = util_createView("CherryBountySrc.CherryBountyTempSymbol", {machine=self})
            parent:addChild(tempSymbol)
            tempSymbol:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            self:upDateWildSymbolSkin(tempSymbol, 3)
            tempSymbol:setPosition(util_convertToNodeSpace(_symbol, parent))
            local actList = {}
            table.insert(actList, cc.MoveTo:create(flyTime, endPos))
            table.insert(actList, cc.RemoveSelf:create())
            tempSymbol:runAnim("fly", false)
            tempSymbol:runAction(cc.Sequence:create(actList))
        end
        self:levelPerformWithDelay(self, flyTime, function()
            --升级反馈
            if bUpGrade then
                self.m_topWildCollect:playUpGradeAnim(nil, function() end)
            --收集反馈
            else
                self.m_topWildCollect:playCollectAnim(newLevel, function() end)
            end
        end)
    end)
end
--wild按列收集-收集音效
function CodeGameScreenCherryBountyMachine:playWildBulingCollectSound(_iCol, _bUpGrade, _flyDelay, _flyTime)
    local soundName1 = PublicConfig.sound_CherryBounty_Wild_collectFly
    local soundName2 = PublicConfig.sound_CherryBounty_Wild_collectFeedback
    if _bUpGrade then
        soundName2 = PublicConfig.sound_CherryBounty_CollectBar_upGrade
    end
    --区分快停
    if self:getGameSpinStage() == QUICK_RUN then
        if not self.m_wildCollectSoundList[soundName1] then
            self.m_wildCollectSoundList[soundName1] = true
            self:levelPerformWithDelay(self, _flyDelay, function()
                gLobalSoundManager:playSound(soundName1)
            end)
        end
        if not self.m_wildCollectSoundList[soundName2] then
            self.m_wildCollectSoundList[soundName2] = true
            self:levelPerformWithDelay(self, _flyDelay+_flyTime, function()
                gLobalSoundManager:playSound(soundName2)
            end)
        end
    else
        self:levelPerformWithDelay(self, _flyDelay, function()
            gLobalSoundManager:playSound(soundName1)
            self:levelPerformWithDelay(self, _flyTime, function()
                gLobalSoundManager:playSound(soundName2)
            end)
        end)
    end
end


--wild次数刷新
function CodeGameScreenCherryBountyMachine:playEFFECT_WildTimes(_fun)
    local selfData   = self.m_runSpinResultData.p_selfMakeData
    local wildTimes  = selfData.leftTimes
    local wildPos    = selfData.wild_position
    local wildNewPos = selfData.collect_wild
    local animTime = self.m_lockWild:playAllWildReSetTimesAnim(wildTimes, wildPos, wildNewPos)
    self:levelPerformWithDelay(self, animTime, _fun)
end
--wild次数刷新-切换bet
function CodeGameScreenCherryBountyMachine:changeBetUpDateLockWild(_bUpdateUi)
    if self.m_bProduceSlots_InFreeSpin or self:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end
    if self:isTriggerCherryBountyReSpin() then
        return
    end
    self:clearWinLineEffect()
    self:stopLinesWinSound()
    local totalBet  = globalData.slotRunData:getCurTotalBet()
    local betData   = self.m_lockWild:geLockWildDataByBet(totalBet)
    local wildTimes = betData.leftTimes or 0
    local wildPos   = betData.wild_position or {}
    local wildNewPos = {}
    --高层级wild根据bet数据刷新
    self.m_lockWild:resetLockWild()
    self.m_lockWild:playAllWildTimesAnim(wildTimes, wildPos, wildNewPos)
    --低层级wild全部随机为低级图标
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        local bWild  = _symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
        local bBonus =  self:isCherryBountyBonus(_symbol.p_symbolType)
        if bWild or bBonus then
            local reelPos = self:getCherryBountyPosReelIdx(_iRow, _iCol)
            local bLock = nil~=self.m_lockWild:getLockWildByReelPos()
            if bWild or bLock then
                local newSymbolType = self:getReplaceWildSymbolType()
                self:changeReelSymbolType(_symbol, newSymbolType)
                self:changeReelSymbolOrder(_symbol)
                _symbol:runAnim("idleframe", false)
            end
        end
    end)
end
--wild次数刷新-获取代替wild展示的随机图标
function CodeGameScreenCherryBountyMachine:getReplaceWildSymbolType()
    local symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_2)
    return symbolType
end
--wild次数刷新-spin
function CodeGameScreenCherryBountyMachine:spinUpDateLockWild()
    if self.m_bProduceSlots_InFreeSpin or self:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end
    local totalBet   = globalData.slotRunData:getCurTotalBet()
    local betData    = self.m_lockWild:geLockWildDataByBet(totalBet)
    local wildTimes  = betData.leftTimes or 0
    local wildPos    = betData.wild_position or {}
    local wildNewPos = {}
    self.m_lockWild:showLockWildByLineFrameOver()
    if wildTimes > 0 then
        self.m_lockWild:playAllWildTimesAnim(wildTimes-1, wildPos, wildNewPos)
    else
        self.m_lockWild:spinResetLockWild()
    end
end
--wild次数刷新-盘面恢复
function CodeGameScreenCherryBountyMachine:resumeReelUpDateLockWild()
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local selfData   = bonusExtra.spinR_selfData
    local wildTimes  = selfData.leftTimes or 0
    local wildPos    = selfData.wild_position or {}
    local wildNewPos = {}
    self.m_lockWild:playAllWildTimesAnim(wildTimes, wildPos, wildNewPos)
end


--free收集bonus2
function CodeGameScreenCherryBountyMachine:isTriggerEFFECT_FreeCollectBonus()
    local reels = self.m_runSpinResultData.p_reels or {}
    for _lineIndex,_lineData in ipairs(reels) do
        for _iCol,_symbolType in ipairs(_lineData) do
            if _symbolType == self.SYMBOL_Bonus2 then
                return true
            end
        end
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playEFFECT_FreeCollectBonus(_fun)
    local symbolList = self:getReelSymbolList({}, self.SYMBOL_Bonus2, true)
    --乘倍反馈 金额上涨
    self:playFreeBonus2MultAnim(symbolList, function()
       --依次收集
       self:playFreeBonus2CollectByList(1, symbolList, _fun)
    end)
end
--free的bonus2乘倍-散出小乘倍飞向每个bonus2
function CodeGameScreenCherryBountyMachine:playFreeBonus2MultAnim(_symbolList, _fun)
    local animTime = 0
    local multip = self.m_runSpinResultData.p_fsExtraData.mult
    local bMult = multip > 1
    if bMult then
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FreeMult)
        animTime = 60/60
        for i,_symbol in ipairs(_symbolList) do
            local animNode = _symbol:getCCBNode()
            local bindCsb  = animNode.m_bindCsb
            local labMultip = bindCsb:findChild("m_lb_mult")
            labMultip:setString(string.format("X%d", multip))
            bindCsb:runCsbAction("chengbei", false)
        end
        self.m_maskCtr:playReelMaskStart()
    end
    local baseCoins   = self:getFreeBonus2BaseCoins()
    local bonus2Coins = self:getFreeBonus2Coins()
    self:levelPerformWithDelay(self, animTime, function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Bonus2_freeMult)
        for i,_symbol in ipairs(_symbolList) do
            animTime = self:playFreeBonus2JumpCoins(_symbol, baseCoins, bonus2Coins)
        end
        self:levelPerformWithDelay(self, animTime, function()
            if bMult then
                self.m_maskCtr:playReelMaskOver()
            end
            _fun()
        end)
    end)
end
--free的bonus2乘倍-单个乘倍反馈金额上涨
function CodeGameScreenCherryBountyMachine:playFreeBonus2JumpCoins(_symbol, _baseCoins, _endCoins)
    local animName = "actionframe3"
    local animTime = _symbol:getAniamDurationByName(animName)
    _symbol:runAnim(animName, false, function()
        self.m_symbolExpectCtr:playSymbolIdleAnim(_symbol)
    end)
    --是否跳钱
    local offsetValue = _endCoins - _baseCoins
    if offsetValue > 0 then
        local labCoins = self:getBonusSymbolCoinsLab(_symbol)
        local labInfo  = self:getBonusCoinsLabelInfo(labCoins, _symbol.p_symbolType)
        self:playLabelJumpCoins(labCoins, labInfo, _baseCoins, _endCoins, 0.5, false)
    end

    return animTime
end



--free的bonus2-依次收集
function CodeGameScreenCherryBountyMachine:playFreeBonus2CollectByList(_index, _list, _fun)
    local symbol = _list[_index]
    if not symbol then
        return self:levelPerformWithDelay(self, 0.5, _fun)
    end

    local symbolType = symbol.p_symbolType
    local bonusData  = self:getFreeReelMultBonusData()
    local coins      = self:getReelBonusCoins(nil, bonusData)
    local parent = self.m_effectNodeDown

    local flyCsb = self:createSpineSymbolBindCsb(symbolType)
    parent:addChild(flyCsb)
    flyCsb:setPosition( util_convertToNodeSpace(symbol, parent) )
    self:upDateBonusBindCsb(flyCsb, bonusData)

    local actList = {}
    local flyTime = 0.5
    local endPos  = util_convertToNodeSpace(self.m_freeTips, parent)
    table.insert(actList, cc.MoveTo:create(flyTime, endPos))
    table.insert(actList, cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Bonus2_freeCollectFeedback)
        flyCsb:setVisible(false)
        self.m_freeTips:playCollectAnim(coins)
    end))
    table.insert(actList, cc.DelayTime:create(0.3))
    table.insert(actList, cc.CallFunc:create(function()
        self:playFreeBonus2CollectByList(_index+1, _list, _fun)
    end))
    table.insert(actList, cc.RemoveSelf:create())

    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Bonus2_freeCollect)
    symbol:runAnim("shouji2", false)
    flyCsb:runAction(cc.Sequence:create(actList))
end



--free结算
function CodeGameScreenCherryBountyMachine:isTriggerEFFECT_FreeOverSettlement()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and 0 == globalData.slotRunData.freeSpinCount then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playEFFECT_FreeOverSettlement(_fun)
    local parent   = self.m_effectNodeUp
    local posNode  = self.m_freeTips.m_labCsb
    local coins    = self.m_freeTips.m_targetCoins
    local flyCsb   = self.m_freeTips:createLabelCsb()
    parent:addChild(flyCsb)
    flyCsb:setPosition( util_convertToNodeSpace(posNode, parent) )
    local labCoins = flyCsb:findChild("m_lb_coins")
    self.m_freeTips:upDateLabelCoins(labCoins, coins)
    self.m_freeTips:stopUpDateJumpCoins()
    self.m_freeTips:upDateLabelCoins(self.m_freeTips.m_labCoins, 0)

    local actList = {}
    table.insert(actList, cc.DelayTime:create(30/60))
    local flyTime = (48-30)/60
    local endPos  = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, parent)
    table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(flyTime, endPos), 2))
    table.insert(actList, cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FreeSettlement_collectFeedback)
        local freeBonusCoins = self:getAllFreeBonusCoins()
        self:updateBottomUICoins(freeBonusCoins, false, true, false, true)
        self:playCherryBountyBigWinLabelJumpCoins(freeBonusCoins, freeBonusCoins, 0.01)
        self:playTotalWinSpineAnim()
        self:levelPerformWithDelay(self, 0.5, _fun)
    end))
    table.insert(actList, cc.RemoveSelf:create())

    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FreeSettlement_collect)
    -- 0~48
    flyCsb:runCsbAction("shouji2", false)
    flyCsb:runAction(cc.Sequence:create(actList))
end

--多福多彩
function CodeGameScreenCherryBountyMachine:isTriggerEFFECT_PickGame(_result)
    if _result.selfData.jackpot then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playEFFECT_PickGame(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local gameData = self:getPickGameData()
    local fnOver = function()
        self:showPickGameJackpotView(1, gameData, function()
            self:showPickGameOverView(gameData, function()
                self:addBonusOverBigWinEffect(gameData.winCoins, self.EFFECT_PickGame, true)
                _fun()
            end)
        end)
    end
    self.m_pickGameView:startGame(gameData, fnOver)
end
--多福多彩-模式ui
function CodeGameScreenCherryBountyMachine:upDatePickGameModelUi()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_pickGameTopTips:playLogoIdleAnim()
    self.m_pickGameTopTips:setVisible(true)
    self.m_pickGameReelTips:setVisible(true)
    self.m_topWildCollect:setVisible(false)
    self.m_reelTips:setVisible(false)
    self:findChild("reel"):setVisible(false)

    self.m_pickGameView = util_createView("CherryBountySrc.CherryBountyPickGameView", self)
    self:findChild("Node_pickGame"):addChild(self.m_pickGameView)
end
--多福多彩-数据处理
function CodeGameScreenCherryBountyMachine:getPickGameData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpot  = selfData.jackpot
    local gameData = {}
    gameData.winCoins = tonumber(jackpot.winAmountValue)
    gameData.index = 1
    --over 和 未点击选项
    local extraProcess = {}
    for i=1,3 do
        for k,_jpType in pairs(self.ServerJackpotType) do
            table.insert(extraProcess, {name  = _jpType, value = 0})
        end
    end
    --玩家选项
    gameData.process = {}
    for i,v in ipairs(jackpot.winjackpotname) do
        local coins  = tonumber(jackpot.winjackpotValue[i])
        local reward = {name  = v[2], value = coins}
        table.insert(gameData.process, reward)
        for ii,vv in ipairs(extraProcess) do
            if vv.name == reward.name then
                table.remove(extraProcess, ii)
                break
            end
        end
    end
    gameData.extraProcess = {}
    while #extraProcess > 0 do
        local reward = table.remove(extraProcess, math.random(1, #extraProcess))
        table.insert(gameData.extraProcess, reward)
    end
    --奖励展示列表
    gameData.rewardList = {}
    for i,_reward in ipairs(gameData.process) do
        local showReward = nil
        for ii,vv in ipairs(gameData.rewardList) do
            if vv.name == _reward.name then
                showReward = vv
                break
            end
        end
        if not showReward then
            table.insert(gameData.rewardList, {name=_reward.name, value=_reward.value, count = 1})
        else
            showReward.count = showReward.count+1
            showReward.value = showReward.value+_reward.value
        end
    end
    table.sort(gameData.rewardList, function(_rewardA, _rewardB)
        local jpIndexA = self.JackpotTypeToIndex[_rewardA.name]
        local jpIndexB = self.JackpotTypeToIndex[_rewardB.name]
        return jpIndexA < jpIndexB
    end)
    --玩家选项-补充一个over
    table.insert(gameData.process, {name  = "", value = 0})

    return gameData
end
--多福多彩-彩金界面
function CodeGameScreenCherryBountyMachine:showPickGameJackpotView(_index, _gameData, _fun)
    local showReward = _gameData.rewardList[#_gameData.rewardList+1-_index]
    if not showReward then
        return _fun()
    end
    local jpIndex = self.JackpotTypeToIndex[showReward.name]
    local jpCoins = showReward.value
    local jpMulti = showReward.count
    self:showJackpotView(jpIndex, jpCoins, jpMulti, function()
        self:showPickGameJackpotView(_index+1, _gameData, _fun)
    end)
    self:updateBottomUICoins(jpCoins, false, true, false, false)
end
--多福多彩-结算界面
function CodeGameScreenCherryBountyMachine:showPickGameOverView(_gameData, _fun)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_PickOverView_start)
    local fnSwitch = function()
        self.m_pickGameTopTips:setVisible(false)
        self.m_pickGameReelTips:setVisible(false)
        self.m_jackpotBar:playJackpotBarIdle()
        self.m_topWildCollect:playIdleAnim()
        self.m_topWildCollect:setVisible(true)
        self.m_reelTips:setVisible(true)
        self:findChild("reel"):setVisible(true)
        self:changeReelBg(self.BgModel.Base, true)
        self:findChild("Node_pickGame"):removeAllChildren()
        self.m_pickGameView = nil
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_PickOverView_over)
    end
    local fnOver = function()
        self:resetMusicBg(true, PublicConfig.music_CherryBounty_base)
        _fun()
    end
    local viewData = {}
    viewData.coins     = _gameData.winCoins
    viewData.bBonus    = true
    viewData.fnSwitch  = fnSwitch
    viewData.fnOver    = fnOver
    local view = self:showFeatureWinView(viewData)
    --描述文本
    local typeCount = #_gameData.rewardList
    local pickNode = view.m_modelCsb:findChild(string.format("pick%d", typeCount))
    pickNode:setVisible(true)
    --描述
    local jpCount = #self.JackpotIndexToType
    if typeCount < jpCount then
        local rewardIndex = 1
        for _jpIndex=jpCount,1,-1 do
            for _dataIndex=typeCount,1,-1 do
                local showReward = _gameData.rewardList[_dataIndex]
                if _jpIndex == self.JackpotTypeToIndex[showReward.name] then
                    local nodeName = string.format("jackpot%d%d%d", typeCount, rewardIndex, _jpIndex)
                    local jackpotNode = view.m_modelCsb:findChild(nodeName)
                    jackpotNode:setVisible(true)
                    rewardIndex = rewardIndex + 1
                end
            end
        end
    end
    --倍数
    for _index,_showReward in ipairs(_gameData.rewardList) do
        local sMult  = string.format("X%d", _showReward.count)
        local labMult = view.m_modelCsb:findChild(string.format("m_lb_chengbei%d%d", typeCount, _index))
        labMult:setString(sMult)
    end
end


--N选1
function CodeGameScreenCherryBountyMachine:showBonusGameView(effectData)
    local selfData   = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}
    local bonusMult  = bonusExtra.bonus2_mult or 0
    local totalBet   = globalData.slotRunData:getCurTotalBet()
    local bCommon    = self:isCommonSelectBonusGame()
    local viewData = {}
    viewData.machine   = self
    viewData.bCommon   = bCommon
    viewData.csbName   = "CherryBounty/CherryBounty_sixuanyi.csb" 
    viewData.spineName = "CherryBounty_choose"
    viewData.animNameSuffix  = ""
    viewData.coins  = totalBet * bonusMult
    if not bCommon then
        viewData.csbName = "CherryBounty/CherryBounty_erxunyi.csb"
        viewData.animNameSuffix  = "_2"
        viewData.coins  = 0
    end
    local fnNext = function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end
    --wild转换bonus
    self:playBonusGameWildSwitchBonus(bCommon, function()
        --触发收集
        self:playBonusGameTriggerAnim(bCommon, function()
            --弹板
            self:showCherryBountyChoseView(viewData, fnNext)
        end)
    end)
end
--N选1-是否普通
function CodeGameScreenCherryBountyMachine:isCommonSelectBonusGame()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusType = selfData.bonus_type
    return 2==bonusType
end
--N选1-是否特殊选择
function CodeGameScreenCherryBountyMachine:isSuperSelectBonusGame()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusType = selfData.bonus_type
    return 3==bonusType
end

--N选1-wild变为bonus
function CodeGameScreenCherryBountyMachine:playBonusGameWildSwitchBonus(_bCommon, _fun)
    local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
    local delay = bLine and 0 or 0.5
    self:levelPerformWithDelay(self, delay, function()
        self:clearWinLineEffect()
        self.m_lockWild:hideLockWildByLineFrame()
        self.m_lockWild:resetLockWild()
        --低层bonus播出现 高层wild播消失
        if _bCommon then
            local parent = self.m_effectNodeDown
            local totalBet  = globalData.slotRunData:getCurTotalBet()
            local betData   = self.m_lockWild:geLockWildDataByBet(totalBet)
            local showTimes = betData.leftTimes+1
            local wildPos   = betData.wild_position
            --有节奏的每一个错开3帧
            local indexList = {}
            local maxDelay  = 0
            for i,_reelPos in ipairs(wildPos) do
                local fixPos = self:getCherryBountyRowAndColByPos(_reelPos) 
                local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
                local bonusData = self:getReelBonusRewardData(_reelPos)
                --
                local order = fixPos.iY * 10 - fixPos.iX
                local tempSymbol = util_createView("CherryBountySrc.CherryBountyTempSymbol", {machine=self})
                parent:addChild(tempSymbol, order)
                tempSymbol:setPosition(util_convertToNodeSpace(symbol, parent))
                tempSymbol:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                self:upDateWildSymbolSkin(tempSymbol, showTimes)
                self.m_symbolExpectCtr:playSymbolIdleAnim(tempSymbol)
                --随机延时
                local randomIndex = math.random(1, #wildPos)
                while indexList[tostring(randomIndex)] do
                    randomIndex = math.random(1, #wildPos)
                end
                indexList[tostring(randomIndex)] = randomIndex
                local delayTime = (randomIndex-1) * 3/30
                maxDelay = math.max(maxDelay, delayTime)
                self:levelPerformWithDelay(self, delayTime, function()
                    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Wild_switchBonus)
                    self:changeReelSymbolType(symbol, self.SYMBOL_Bonus1)
                    self:changeReelSymbolOrder(symbol, true)
                    self:addSpineSymbolCsbNode(symbol)
                    self:upDateBonusReward(symbol, bonusData)
                    symbol:runAnim("start", false)
                    tempSymbol:runAnim("switch4", false, function()
                        tempSymbol:removeTempSlotsNode()
                    end)
                end)
            end
            self:levelPerformWithDelay(self, 21/30+maxDelay, _fun)
        else
            _fun()
        end
    end)
end
--N选1-触发
function CodeGameScreenCherryBountyMachine:playBonusGameTriggerAnim(bCommon, _fun)
    if bCommon then
        local animTime = self:playBonusGameSymbolTrigger(bCommon)
        self:levelPerformWithDelay(self, animTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_TopBonus2_start) 
            --依次收集
            self.m_topWildCollect:setVisible(false)
            self.m_topBonus2:playTopBonusStart(function()
                local symbolList = self:getBonusCollectList()
                self:playBonusGameCollectBonus(1, symbolList, _fun)
            end)
        end)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Pick_trigger)
        self.m_topWildCollect:playTriggerAnim(nil, _fun)
    end
end
--N选1-图标触发
function CodeGameScreenCherryBountyMachine:playBonusGameSymbolTrigger(_bCommon)
    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    if _bCommon then
        symbolType = self.SYMBOL_Bonus1
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Bonus1_trigger)
    else

    end
    
    local animTime = self:playSymbolTrigger(symbolType, nil)
    return animTime
end
--N选1-收集棋盘bonus到顶部
function CodeGameScreenCherryBountyMachine:playBonusGameCollectBonus(_index, _list, _fun)
    local symbol = _list[_index]
    if not symbol then
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_TopBonus2_trigger)
        return  self.m_topBonus2:playCollectOverAnim(_fun)
    end

    local reelPos    = self:getCherryBountyPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex)
    local bonusData  = self:getReelBonusRewardData(reelPos)
    local coins      = self:getReelBonusCoins(nil, bonusData)
    local symbolType = symbol.p_symbolType
    local parent     = self.m_effectNodeDown

    local flyCsb = self:createSpineSymbolBindCsb(self.SYMBOL_Bonus1)
    parent:addChild(flyCsb)
    flyCsb:setPosition( util_convertToNodeSpace(symbol, parent) )
    self:upDateBonusBindCsb(flyCsb, bonusData)

    local actList = {}
    local flyTime = 9/30
    local endPos  = util_convertToNodeSpace(self.m_topBonus2, parent)
    table.insert(actList, cc.MoveTo:create(flyTime, endPos))
    table.insert(actList, cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Bonus1_selectCollectFeedback)
        self.m_topBonus2:playTopBonusCollectAnim(coins)
        flyCsb:setVisible(false)
    end))
    table.insert(actList, cc.CallFunc:create(function()
        self:playBonusGameCollectBonus(_index+1, _list, _fun)
    end))
    table.insert(actList, cc.RemoveSelf:create())

    symbol:runAnim("shouji2", false)
    flyCsb:runAction(cc.Sequence:create(actList))
end
--N选1-获取所有bonus图标收集数据
function CodeGameScreenCherryBountyMachine:getBonusCollectList()
    local symbolList = {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    for i,_iconData in ipairs(storedIcons) do
        local fixPos = self:getCherryBountyRowAndColByPos(_iconData[1])
        local symbol = self:getFixSymbol(fixPos.iY , fixPos.iX)
        table.insert(symbolList, symbol)
    end
    table.sort(symbolList, function(symbolA, symbolB)
        if symbolA and symbolB then
            if symbolA.p_cloumnIndex ~= symbolB.p_cloumnIndex then
                return symbolA.p_cloumnIndex < symbolB.p_cloumnIndex
            end
            if symbolA.p_rowIndex ~= symbolB.p_rowIndex then
                return symbolA.p_rowIndex > symbolB.p_rowIndex
            end
        end
        return false
    end)
    return symbolList
end

function CodeGameScreenCherryBountyMachine:showCherryBountyChoseView(_data, _fun)
    if _data.bCommon then
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_SelectView4_start)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_SelectView2_start)
    end

    local view = util_createView("CherryBountySrc.CherryBountyFeatureSelectView", _data)
    view:setBtnClickFunc(function(_result)
        self:addFeatureSelectResult(_result)
        local features = _result.features or {}
        local bFree    = features[2] == SLOTO_FEATURE.FEATURE_FREESPIN
        local bReSpin  = features[2] == SLOTO_FEATURE.FEATURE_RESPIN
        --清空底栏
        if not self.m_bProduceSlots_InFreeSpin then
            self.m_bottomUI:resetWinLabel()
            self.m_bottomUI:checkClearWinLabel()
        end
        --背景
        local sModel = self:getModelByResult(_result)
        self:changeReelBg(sModel, true)
        --模式ui
        if bFree then
            self:upDateFreeModelUi(false)
        elseif bReSpin then
            self:upDateReSpinModelUi(false)
        else
            self:resetMusicBg(true, PublicConfig.music_CherryBounty_pick)
            self:upDatePickGameModelUi()
        end
        if _data.bCommon then
        else
            self.m_topWildCollect:setCurLevel(1)
        end
    end)
    view:setOverAniRunFunc(function(_result)
        _fun()
    end)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--2选1-根据选择结果添加玩法事件
function CodeGameScreenCherryBountyMachine:addFeatureSelectResult(_result)
    self.m_spinAddBottomCoins = 0
    local features  = _result.features or {}
    if  features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        self.m_iFreeSpinTimes                     = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.freeSpinCount      = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        --插入事件
        local effectData = GameEffectData.new()
        effectData.p_effectType  = GameEffect.EFFECT_FREE_SPIN
        effectData.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    elseif  features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
        --插入事件
        local effectData = GameEffectData.new()
        effectData.p_effectType  = GameEffect.EFFECT_RESPIN
        effectData.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    elseif self:isTriggerEFFECT_PickGame(_result) then
        --插入事件
        self:addOneSelfEffect(self.EFFECT_PickGame)
    end
    self:sortGameEffects()
end

--free-移除触发动画
function CodeGameScreenCherryBountyMachine:showEffect_FreeSpin(effectData)
    for i,_lineValue in ipairs(self.m_reelResultLines) do
        if _lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            table.remove(self.m_reelResultLines, i)
            break
        end
    end
    CodeGameScreenCherryBountyMachine.super.showEffect_FreeSpin(self, effectData)
    return true
end
--free-弹板
function CodeGameScreenCherryBountyMachine:showFreeSpinView(effectData)
    local showFSView = function ()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    self:levelPerformWithDelay(self, 0.5, showFSView)
end
--free-模式ui
function CodeGameScreenCherryBountyMachine:upDateFreeModelUi(_bReconnect)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local freeMult  = fsExtraData.mult
    local bonusBaseCoins = self:getFreeBonus2BaseCoins()
    local freeBonusCoins = self:getAllFreeBonusCoins()
    self.m_freeBar:initFreeBarLabelCoins(bonusBaseCoins, freeMult)
    self.m_freeBar:changeFreeSpinByCount()
    self.m_freeTips:initLabelCoins(freeBonusCoins)
    self.m_freeBar:setVisible(true)
    self.m_freeTips:setVisible(true)
    self.m_topBonus2:setVisible(false)
    self.m_topWildCollect:setVisible(false)
    self.m_reelTips:setVisible(false)
    self.m_reSpinTopTips:setVisible(false)
    self.m_reSpinReelTips:setVisible(false)
    if _bReconnect then
        self:changeReelBg(self.BgModel.Free, false)
    end
end
--free-bonus2基础金额
function CodeGameScreenCherryBountyMachine:getFreeBonus2BaseCoins()
    local totalBet    = globalData.slotRunData:getCurTotalBet()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local bonusMult   = fsExtraData.bonus2_mult or 0
    return totalBet * bonusMult
end
--free-单个bonus2在free内的总金额
function CodeGameScreenCherryBountyMachine:getFreeBonus2Coins()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local freeMult    = fsExtraData.mult or 0
    local bonusBaseCoins = self:getFreeBonus2BaseCoins()
    return bonusBaseCoins * freeMult
end
--free-bonus的累计金额
function CodeGameScreenCherryBountyMachine:getAllFreeBonusCoins()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local coins = tonumber(fsExtraData.bonus_win_coins)
    return coins
end
--free-结算弹板
function CodeGameScreenCherryBountyMachine:showFreeSpinOverView(effectData)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FreeOver_start)
    local fnSwitch = function()
        self.m_bFreeReconnect = false
        self.m_freeBar:setVisible(false)
        self.m_freeTips:setVisible(false)
        self.m_topWildCollect:setVisible(true)
        self.m_reelTips:setVisible(true)
        self:changeReelBg(self.BgModel.Base, true)
        self:clearWinLineEffect()
        self:featureOverUpDateReel()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FreeOver_over)
    end
    local fnOver = function()
        self:triggerFreeSpinOverCallFun()
    end

    local freeTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
    local viewData = {}
    viewData.coins     = self.m_runSpinResultData.p_fsWinCoins
    viewData.bFree     = true
    viewData.freeTimes = freeTimes
    viewData.fnSwitch  = fnSwitch
    viewData.fnOver    = fnOver
    local view = self:showFeatureWinView(viewData)
end


function CodeGameScreenCherryBountyMachine:isTriggerCherryBountyReSpin()
    local curTimes = self.m_runSpinResultData.p_reSpinCurCount or 0
    return curTimes > 0
end
--重写-取消respin断线时随机轮盘数据
function CodeGameScreenCherryBountyMachine:respinModeChangeSymbolType()
    -- CodeGameScreenCherryBountyMachine.super.respinModeChangeSymbolType(self)
end

--respin-继承底层respinView
function CodeGameScreenCherryBountyMachine:getRespinView()
    return "CherryBountySrc.CherryBountyReSpinView"    
end
--respin-继承底层respinNode
function CodeGameScreenCherryBountyMachine:getRespinNode()
    return "CherryBountySrc.CherryBountyReSpinNode"    
end
--respin-假滚
function CodeGameScreenCherryBountyMachine:getRespinRandomTypes()
    local symbolList = { 
        self.SYMBOL_ReSpinBlank,
        self.SYMBOL_Bonus2,
        self.SYMBOL_Bonus3,
    }
    return symbolList    
end
--respin-固定图标
function CodeGameScreenCherryBountyMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_Bonus1,  runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Bonus2,  runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Bonus3,  runEndAnimaName = "", bRandom = true},
    }
    return symbolList
end
--respin-刷新模式ui
function CodeGameScreenCherryBountyMachine:upDateReSpinModelUi(_bReconnect)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local curTimes    = self.m_runSpinResultData.p_reSpinCurCount
    local bonus2Coins,bonus3Coins = self:getCurReSpinBonusCoins()
    local bSuper = self:isCherryBountySuperReSpin()
    self.m_reSpinTopTips:upDateReSpinBarTimes(curTimes)
    self.m_reSpinReelTips:initLabelCoins(bonus2Coins, bonus3Coins)
    self.m_reSpinReelTips:setVisible(true)
    self.m_reSpinTopTips:setVisible(true)
    self.m_topBonus2:setVisible(false)
    self.m_topWildCollect:setVisible(false)
    self.m_reelTips:setVisible(false)
    self.m_freeBar:setVisible(false)
    self.m_freeTips:setVisible(false)
    if _bReconnect then
        self:changeReelBg(self:getCurReSpinModel(), false)
    end
    self.m_skipLayer:setSkipLayContentSize(not bSuper)
    self:changeCherryBountyTouchSize(bSuper)
    --构造盘面数据
    local randomTypes = self:getRespinRandomTypes()
    local lockTypes   = self:getRespinLockTypes()
    self:triggerReSpinCallFun(lockTypes, randomTypes)
    self.m_respinView:playReSpinExpectAnim()
    --关卡适配-superReSpin
    if bSuper then
        self:upDateSuperReSpinMainLayerScale(true)
    end
end
--respin-点击棋盘spin区域
function CodeGameScreenCherryBountyMachine:changeCherryBountyTouchSize(_bSuper)
    local spinLayer = self.m_touchSpinLayer
    if spinLayer then
        local reel0Node = self:findChild("sp_reel_0")
        local pos       = cc.p(reel0Node:getPosition())
        local newSize   = cc.size(876, 384)
        if _bSuper then
            pos.x = pos.x - 176
            newSize.width = 1228
        end
        spinLayer:setContentSize(newSize)
        spinLayer:setPosition(pos)
    end
end

--respin-当前respin类型
function CodeGameScreenCherryBountyMachine:getCurReSpinModel()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local respinType = rsExtraData.type
    if "normal" == respinType then
        return self.BgModel.Respin5
    end
    return self.BgModel.Respin7
end
function CodeGameScreenCherryBountyMachine:isCherryBountySuperReSpin()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local respinType = rsExtraData.type
    local bSuperReSpin = self.m_runSpinResultData.p_reSpinsTotalCount > 0 and "normal" ~= respinType
    return bSuperReSpin
end
--respin-当前respin 95 96的金额
function CodeGameScreenCherryBountyMachine:getCurReSpinBonusCoins()
    local bonus2Coins = 0
    local bonus3Coins = 0
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local reels  = rsExtraData.bonus_reels or {}
    for _lineIndex,_lineData in ipairs(reels) do
        local iRow = self.m_iReelRowNum + 1 - _lineIndex
        for _iCol,_symbolType in ipairs(_lineData) do
            local bBonus1 = _symbolType == self.SYMBOL_Bonus1 or _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
            local bBonus2 = _symbolType == self.SYMBOL_Bonus2
            local bBonus3 = _symbolType == self.SYMBOL_Bonus3
            if bBonus1 or bBonus2 or bBonus3 then
                local bSuper    = self:isCherryBountySuperReSpin()
                local reelPos   = self:getCherryBountyPosReelIdx(iRow, _iCol, bSuper)
                local coins = self:getReelBonusCoins(reelPos)
                if bBonus1 then
                    bonus2Coins = bonus2Coins + coins
                    bonus3Coins = bonus3Coins + coins
                else
                    bonus3Coins = bonus3Coins + coins
                end
            end
        end
    end
    
    return bonus2Coins,bonus3Coins
end
--respin-获取当前坐标(包含)之前的bonus3累计金额(上次固定 和 本次落地但是坐标在传入坐标之前)
function CodeGameScreenCherryBountyMachine:getCurReSpinBonus3Coins(_symbolType, _reelPos)
    local bonus3Coins = 0
    local bSuper      = self:isCherryBountySuperReSpin()
    local posData     = self:getCherryBountyRowAndColByPos(_reelPos, bSuper)
    local selfData    = self.m_runSpinResultData.p_selfMakeData
    local bBonus3     = _symbolType == self.SYMBOL_Bonus3
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local bonusIndex = self:getCherryBountyBonusIndex(_symbolType)

    for i,_data in ipairs(storedIcons) do
        local pos = _data[1]
        local fixPos  = self:getCherryBountyRowAndColByPos(pos, bSuper)
        local symbolType = self:getMatrixPosSymbolType(fixPos.iX, fixPos.iY)
        local bAdd = true
        if symbolType ~= self.SYMBOL_Bonus1 then
            --只计算小于等于当前bonus类型的累计金额 或 上次固定的
            local curBonusIndex = self:getCherryBountyBonusIndex(symbolType)
            local bNewLock = self:isNewReSpinLockBonusPos(pos)
            if bonusIndex < curBonusIndex and bNewLock then
                bAdd = false
            else
                --新滚出的bonus判断是否计入当前累计金额
                if bNewLock then
                    if posData.iY < fixPos.iY then
                        bAdd = false
                    elseif posData.iY == fixPos.iY then
                        bAdd = posData.iX <= fixPos.iX
                    end
                end
            end
        end
        if bAdd then
            local bonusCoins = self:getReelBonusCoins(pos)
            bonus3Coins = bonus3Coins + bonusCoins
        end
    end
    return bonus3Coins
end
--respin-获取坐标是否为本次滚出的bonus
function CodeGameScreenCherryBountyMachine:isNewReSpinLockBonusPos(_reelPos)
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus2Pos = selfData.bonus2_positon or {}
    local bonus3Pos = selfData.bonus3_positon or {}
    for i,v in ipairs(bonus2Pos) do
        if v == _reelPos then
            return true
        end
    end
    for i,v in ipairs(bonus3Pos) do
        if v == _reelPos then
            return true
        end
    end
    return false
end


--重写-respin开始时不停止背景
function CodeGameScreenCherryBountyMachine:showEffect_Respin(effectData)
    self.m_bNotClearCurMusic = true
    return CodeGameScreenCherryBountyMachine.super.showEffect_Respin(self, effectData)
end
--重写-respin开始时不停止背景音乐
function CodeGameScreenCherryBountyMachine:clearCurMusicBg()
    if self.m_bNotClearCurMusic then
        self.m_bNotClearCurMusic = nil
        return
    end
    CodeGameScreenCherryBountyMachine.super.clearCurMusicBg(self)
end
--respin-开始弹板
function CodeGameScreenCherryBountyMachine:showRespinView()
    if self.m_bReSpinReconnect then
        self:upDateReSpinModelUi(true)
    end
end
--重写-规避重复调用(由关卡内逻辑提前调用)
function CodeGameScreenCherryBountyMachine:triggerReSpinCallFun(endTypes, randomTypes)
    if not self.m_respinView then
        CodeGameScreenCherryBountyMachine.super.triggerReSpinCallFun(self, endTypes, randomTypes)
    end
end
--respin-初始盘面
function CodeGameScreenCherryBountyMachine:reateRespinNodeInfo()
    local info = {}
    local bSuper   = self:isCherryBountySuperReSpin()
    local colCount = bSuper and self.SuperReSpinCol or self.m_iReelColumnNum
    local columnData = self.m_reelColDatas[1]
    local spReelPos,reelHeight,reelWidth = self:getReelPos(1)
    if bSuper then
        local reSpinReelNode = self:findChild("reSpin_reel_0")
        spReelPos = reSpinReelNode:getParent():convertToWorldSpace(cc.p(reSpinReelNode:getPosition()))
    end
    local colInterval = 4
    local slotNodeH = columnData.p_showGridH
    local rowCount = columnData.p_showGridCount
    for iCol=1,colCount do
        for iRow = rowCount, 1, -1 do
            --初始化图标
            local symbolType = nil
            if not bSuper or self.m_bReSpinReconnect then
                symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            end
            if not symbolType then
                symbolType = self.SYMBOL_ReSpinBlank
            elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = self.SYMBOL_Bonus1
            elseif not self:isCherryBountyBonus(symbolType) then
                symbolType = self.SYMBOL_ReSpinBlank
            end
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            local arrayPos = {iX = iRow, iY = iCol}
            --世界坐标
            local offsetCol = iCol-1
            local pos = cc.p(0, 0)
            pos.x = spReelPos.x + (offsetCol * (reelWidth+colInterval) + reelWidth*0.5) * self.m_machineRootScale
            pos.y = spReelPos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale
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
            info[#info + 1] = symbolNodeInfo
        end
    end
    return info
end
--respin-隐藏展示盘面信息
function CodeGameScreenCherryBountyMachine:setReelSlotsNodeVisible(status)
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        _symbol:setVisible(true == status)
    end)
end
--respin-开始弹板
function CodeGameScreenCherryBountyMachine:showReSpinStart(func)
    self:showReSpinRandomBonus(function()
        func()
    end)
end
--respin-随机bonus
function CodeGameScreenCherryBountyMachine:showReSpinRandomBonus(_fun)
    local bSuper = self:isCherryBountySuperReSpin()
    if not bSuper or self.m_bReSpinReconnect then
        return _fun()
    end
    
    --提起bonus坐标
    local posList   = {}
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local reels = rsExtraData.bonus_reels
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes < 2 then
        reels = self.m_runSpinResultData.p_reels
    end
    for _lineIndex,_lineData in ipairs(reels) do
        local iRow = self.m_iReelRowNum + 1 - _lineIndex
        for _iCol,_symbolType in ipairs(_lineData) do
            if self:isCherryBountyBonus(_symbolType) then
                local reelPos = self:getCherryBountyPosReelIdx(iRow, _iCol, bSuper)
                table.insert(posList, {reelPos, _symbolType})
            end
        end
    end
    if self.m_bReSpinReconnect then
        for i,_data in ipairs(posList) do
            local reelPos    = _data[1]
            local symbolType = _data[2]
            local fixPos = self:getCherryBountyRowAndColByPos(reelPos, bSuper)
            local symbol     = self.m_respinView:getReSpinSymbolNode(fixPos.iX, fixPos.iY)
            local bonusData  = self:getReelBonusRewardData(reelPos)
            self.m_respinView:setReSpinSymbolLock(symbol)
            self:changeReelSymbolType(symbol, symbolType)
            self:addSpineSymbolCsbNode(symbol)
            self:upDateBonusReward(symbol, bonusData)
            self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
        end
        return _fun()
    end
    --随机延时
    local indexList = {}
    local count = #posList
    local maxDelay = 0
    local iStatus  = RESPIN_NODE_STATUS.LOCK
    for i,_data in ipairs(posList) do
        local reelPos    = _data[1]
        local symbolType = _data[2]
        local randomIndex = math.random(1, count)
        while indexList[tostring(randomIndex)] do
            randomIndex = math.random(1, count)
        end
        indexList[tostring(randomIndex)] = randomIndex
        local delayTime = (randomIndex-1) * 3/30
        maxDelay = math.max(maxDelay, delayTime)
        local fixPos = self:getCherryBountyRowAndColByPos(reelPos, bSuper)
        local symbol     = self.m_respinView:getReSpinSymbolNode(fixPos.iX, fixPos.iY)
        local bonusData  = self:getReelBonusRewardData(reelPos)
        self:levelPerformWithDelay(self, delayTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Bonus1_superReSpinStart)
            self.m_respinView:setReSpinSymbolLock(symbol)
            self:changeReelSymbolType(symbol, symbolType)
            self:addSpineSymbolCsbNode(symbol)
            self:upDateBonusReward(symbol, bonusData)
            symbol:runAnim("start", false, function()
                self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
            end)
        end)
    end
    self:levelPerformWithDelay(self,21/30+maxDelay,_fun)
end
--重写-respin刷新次数
function CodeGameScreenCherryBountyMachine:changeReSpinUpdateUI(_curTimes)
    if not _curTimes then
        return
    end  
    self.m_reSpinTopTips:upDateReSpinBarTimes(_curTimes)
end
--respin-组织停轮信息
function CodeGameScreenCherryBountyMachine:getRespinSpinData()
    local storedInfo = {}
    local bSuper = self:isCherryBountySuperReSpin()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    for i,_data in ipairs(storedIcons) do
        local reelPos = _data[1]
        local fixPos = self:getCherryBountyRowAndColByPos(reelPos, bSuper)
        local type = self:getMatrixPosSymbolType(fixPos.iX, fixPos.iY)
        storedInfo[#storedInfo + 1] = {iX = fixPos.iX, iY = fixPos.iY, type = type}
    end
    return storedInfo
end
--respin-停轮信息
function CodeGameScreenCherryBountyMachine:getRespinReelsButStored(_storedInfo)
    local bSuper   = self:isCherryBountySuperReSpin()
    local fnCheckHas = function(iRow, iCol)
        for i,_data in ipairs(_storedInfo) do
            if _data.iX == iRow and _data.iY == iCol then
                return true
            end
        end
        return false
    end
    local reelData = {}
    local colCount = bSuper and self.SuperReSpinCol or self.m_iReelColumnNum
    for iRow=self.m_iReelRowNum, 1, -1 do
        for iCol= 1,colCount do
            if not fnCheckHas(iRow, iCol) then
                local type = self:getMatrixPosSymbolType(iRow, iCol)
                reelData[#reelData + 1] = {iX = iRow, iY = iCol, type = type}
            end
        end
    end
    return reelData
end

--重写-respin停轮
function CodeGameScreenCherryBountyMachine:reSpinReelDown(addNode)
    self:addReSpinGameEffect()
    self:playReSpinGameEffect(function()
        CodeGameScreenCherryBountyMachine.super.reSpinReelDown(self, addNode)
    end)
end
--respin-添加事件
function CodeGameScreenCherryBountyMachine:addReSpinGameEffect()
    self.m_reSpinGameEffectList = {}

    local bTriggerBonus2 = self:isTriggerReSpinEffectBonus2()
    local bTriggerBonus3 = self:isTriggerReSpinEffectBonus3()
    if bTriggerBonus2 or bTriggerBonus3 then
        table.insert(self.m_reSpinGameEffectList, {effectType = self.ReSpinEffect_BonusDelay})
    end 
    if bTriggerBonus2  then
        table.insert(self.m_reSpinGameEffectList, {effectType = self.ReSpinEffect_Bonus2})
    end
    if bTriggerBonus3 then
        table.insert(self.m_reSpinGameEffectList, {effectType = self.ReSpinEffect_Bonus3})
    end
    if self:isTriggerReSpinEffectReSpinMore()  then
        table.insert(self.m_reSpinGameEffectList, {effectType = self.ReSpinEffect_ReSpinMore})
    end
    if self:isTriggerReSpinEffectFullUp()  then
        table.insert(self.m_reSpinGameEffectList, {effectType = self.ReSpinEffect_FullUp})
    end
end
--respin-执行事件
function CodeGameScreenCherryBountyMachine:playReSpinGameEffect(_fun)
    if #self.m_reSpinGameEffectList < 1 then
        return _fun()
    end
    local reSpinGameEffect = table.remove(self.m_reSpinGameEffectList, 1)

    if reSpinGameEffect.effectType == self.ReSpinEffect_BonusDelay then
        self:levelPerformWithDelay(self, 0.5, function()
            self:playReSpinGameEffect(_fun)
        end)
    elseif reSpinGameEffect.effectType == self.ReSpinEffect_Bonus2 then
        self:playReSpinEffectBonus2(function()
            self:playReSpinGameEffect(_fun)
        end)
    elseif reSpinGameEffect.effectType == self.ReSpinEffect_Bonus3 then
        self:playReSpinEffectBonus3(function()
            self:playReSpinGameEffect(_fun)
        end)
    elseif reSpinGameEffect.effectType == self.ReSpinEffect_ReSpinMore then
        self:playReSpinEffectReSpinMore(function()
            self:playReSpinGameEffect(_fun)
        end)
    elseif reSpinGameEffect.effectType == self.ReSpinEffect_FullUp then
        self:playReSpinEffectFullUp(function()
            self:playReSpinGameEffect(_fun)
        end)
    end
end
--respin事件-bonus2加总
function CodeGameScreenCherryBountyMachine:isTriggerReSpinEffectBonus2()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus2Pos = selfData.bonus2_positon or {}
    if #bonus2Pos > 0 then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playReSpinEffectBonus2(_fun)
    local selfData   = self.m_runSpinResultData.p_selfMakeData
    local bonusPos   = selfData.bonus2_positon
    local symbolList  = self:getReSpinSymbolListByPosList({}, bonusPos, true)
    local sourceList = self:getReSpinSymbolListByType({}, {self.SYMBOL_Bonus1})
    self:playBonusCollectCoinsByList(1, symbolList, sourceList, function()
        _fun()
    end)
end

function CodeGameScreenCherryBountyMachine:playBonusCollectCoinsByList(_index, _targetList, _sourceList, _fun)
    local symbol = _targetList[_index]
    if not symbol then
        return _fun()
    end
    local bSuper   = self:isCherryBountySuperReSpin()
    local fnNext = function()
        self.m_respinView:setReSpinLockSymbolOrder(symbol, false)
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpin_upDateTips)
        -- self.m_skipLayer:skipLayerPlaySound(PublicConfig.sound_CherryBounty_ReSpin_upDateTips, 1.8)
        local reelPos = self:getCherryBountyPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex, bSuper)
        local bonus3Coins = self:getCurReSpinBonus3Coins(symbol.p_symbolType, reelPos)
        self.m_reSpinReelTips:playUpDateBonus3CoinsAnim(bonus3Coins)
        self:playBonusCollectCoinsByList(_index+1, _targetList, _sourceList, _fun)
    end
    --当前高级bonus可以收集的bonus
    local newSourceList = {}
    for _index,_sourceSymbol in ipairs(_sourceList) do
        if self:checkReSpinBonusCollect(_targetList, symbol, _sourceSymbol) then
            table.insert(newSourceList, _sourceSymbol)
        end
    end

    --跳过
    local skipData = {}
    skipData.targetList    = _targetList
    skipData.sourceList    = _sourceList
    skipData.targetSymbol  = symbol
    skipData.newSourceList = newSourceList
    local fnSkip = function(_skIndex, _skData)
        self:playSkipReSpinBonusCollectAnim(_skIndex, _skData, fnNext)
    end
    self.m_skipLayer:showSkipLayer(1, skipData, fnSkip)
    --正常执行
    local fnCollectOver = function()
        fnNext()
    end

    self.m_respinView:setReSpinLockSymbolOrder(symbol, true)
    self:playSeniorReSpinBonusCollect(_index, _targetList, 1, newSourceList, fnCollectOver, true)
end
--respin加总-检测图标是否可以被收集
function CodeGameScreenCherryBountyMachine:checkReSpinBonusCollect(_targetList, _targetSymbol ,_collectSymbol)
    if _targetSymbol.p_symbolType == self.SYMBOL_Bonus3 and _collectSymbol.p_symbolType == self.SYMBOL_Bonus3 then
        --被收集的bonus3不是本次滚出的
        local bHas = false
        for i,v in ipairs(_targetList) do
            if v.p_cloumnIndex == _collectSymbol.p_cloumnIndex and v.p_rowIndex == _collectSymbol.p_rowIndex then
                bHas = true
                break
            end
        end
        if not bHas then
            return true
        end
        if _collectSymbol.p_cloumnIndex ~= _targetSymbol.p_cloumnIndex then
            return _collectSymbol.p_cloumnIndex < _targetSymbol.p_cloumnIndex
        end
        if _collectSymbol.p_rowIndex ~= _targetSymbol.p_rowIndex then
            return _collectSymbol.p_rowIndex > _targetSymbol.p_rowIndex
        end
        --被收集的bonus3是本次滚出 且 按顺序在当前加总的bonus3后面
        return false
    end
    return true
end
--respin加总-单个高级bonus收集
function CodeGameScreenCherryBountyMachine:playSeniorReSpinBonusCollect(_targetIndex, _targetList, _sourceIndex, _sourceList, _fun, _canSkip)
    local collectSymbol = _sourceList[_sourceIndex]
    if not collectSymbol then
        return _fun()
    end
    --首个执行收集的高级bonus
    local targetSymbol = _targetList[_targetIndex]
    local bFirstTarget = 1==_targetIndex
    --高级bonus首次收集低级bonus
    local lastSymbol   = _sourceList[_sourceIndex-1]
    local bFirstSource = not lastSymbol
    --高级bonus最后一次收集低级bonus
    local nextSymbol = _sourceList[_sourceIndex+1]
    local bLast = not nextSymbol
    if bLast then
        _canSkip = false
        self.m_skipLayer:hideSkipLayer()
    end
    if _canSkip then
        self.m_skipLayer:saveSkipData(_sourceIndex)
    end
    --本次累加后的金额
    local bSuper     = self:isCherryBountySuperReSpin()
    local bonusCoins = 0
    local lastCoins  = bonusCoins
    for _collectIndex,_symbol in ipairs(_sourceList) do
        if _collectIndex <= _sourceIndex then
            local reelPos = self:getCherryBountyPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex, bSuper)
            local coins   = self:getReelBonusCoins(reelPos)
            lastCoins = bonusCoins
            bonusCoins = bonusCoins + coins
        end
    end

    local collectAnimData = self:getReSpinBonusCollectAnimData(targetSymbol, {collectSymbol})
    --前置延时(非首个高级bonus的首次收集 高级bonus的切换和低级bonus的类型切换 都要加延时)
    local typeInterval = 0
    local bSeniorChange = not bFirstTarget and bFirstSource
    local bLowerChange  = bFirstSource or collectSymbol.p_symbolType ~= lastSymbol.p_symbolType
    if bSeniorChange or bLowerChange then
        typeInterval = collectAnimData.collectTypeInterval
    end
    local nextDelay = collectAnimData.feedbackTime
    self:choosePerformWithDelay(_canSkip, typeInterval, function()
        self:playReSpinBonusCollectAnim(targetSymbol, collectSymbol, collectAnimData, lastCoins, bonusCoins, _canSkip)
        local animTime = collectAnimData.collectTime + nextDelay
        self:choosePerformWithDelay(_canSkip, collectAnimData.collectTime, function()
            --最后一次收集不能跳过-手动调一下反馈效果
            if not _canSkip then
                self:playReSpinBonusCollectFeedback(targetSymbol, collectAnimData, lastCoins, bonusCoins, _canSkip)
            end
            self:choosePerformWithDelay(_canSkip, nextDelay, function()
                self:playSeniorReSpinBonusCollect(_targetIndex, _targetList, _sourceIndex+1, _sourceList, _fun, _canSkip)
            end)
        end)
    end)
end
--respin加总-高级bonus收集低级bonus
function CodeGameScreenCherryBountyMachine:playReSpinBonusCollectAnim(_symbol, _collectSymbol, _animData, _curCoins, _targetCoins, _canSkip)
    --收集
    local collectName = _animData.collectName
    local collectTime = _animData.collectTime
    local flyDelay    = _animData.flyDelay
    local flyTime     = _animData.flyTime
    local soundName1  = _animData.soundName1
    local soundTime1  = _animData.soundTime1
    --飞行光圈
    local flyAnimData = _animData.flyAnimList[1]
    --收集反馈
    local feedbackTime = _canSkip and _animData.feedbackTime or 0
    --震动
    local bShake       = _animData.bShake

    --来源信号的金额
    local bSuper = self:isCherryBountySuperReSpin()
    local reelPos = self:getCherryBountyPosReelIdx(_collectSymbol.p_rowIndex, _collectSymbol.p_cloumnIndex, bSuper)
    local bonusCoins = self:getReelBonusCoins(reelPos)

    _collectSymbol:runAnim(collectName, false, function()
        self.m_symbolExpectCtr:playSymbolIdleAnim(_collectSymbol)
    end)
    self:choosePerformWithDelay(_canSkip, flyDelay, function()
        if _canSkip then
            if bShake then
                self:playCherryBountyReelShakeAnim(flyTime)
            end
            self.m_skipLayer:skipLayerPlaySound(soundName1, soundTime1)
        end
        --飞行效果
        -- self:playParticleFly({"Particle_4"}, _collectSymbol, _symbol, flyTime, true)
        self:playReSpinBonusFlyAnim(flyAnimData, bonusCoins, flyTime, _collectSymbol, _symbol)
        self:choosePerformWithDelay(_canSkip, flyTime, function()
            --不能跳过时不播反馈
            if _canSkip then
                self:playReSpinBonusCollectFeedback(_symbol, _animData, _curCoins, _targetCoins, _canSkip)
            end
        end)
    end)
    local animTime = collectTime + feedbackTime
    return animTime
end
--respin加总-飞行光圈
function CodeGameScreenCherryBountyMachine:playReSpinBonusFlyAnim(_flyAnimData, _coins, _flyTime, _posNode1, _posNode2)
    local parent = self.m_effectNodeUp
    local startPos = util_convertToNodeSpace(_posNode1, parent)
    local endPos   = util_convertToNodeSpace(_posNode2, parent)
    --池子复用
    local pool = self.m_particleList2
    local poolData = nil
    for _index,_data in ipairs(pool) do
        if _data.csbName == _flyAnimData.csbName then
            poolData = table.remove(pool, _index)
            break
        end
    end
    if not poolData then
        poolData = {}
        poolData.csbName = _flyAnimData.csbName
        poolData.csbNode = util_createAnimation(poolData.csbName)
        parent:addChild(poolData.csbNode)
    end
    --粒子拖尾
    poolData.csbNode:setPosition(startPos)
    local particle = poolData.csbNode:findChild("Particle_1")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:stopSystem()
    particle:resetSystem()
    particle:setOpacity(255)
    --粒子外的其他节点的父节点
    local otherNode = poolData.csbNode:findChild("Node_other")
    --金额文本
    local labCoins = poolData.csbNode:findChild("m_lb_coins")
    self:upDateBonusCoinsLabelSize(labCoins, _coins, _flyAnimData.symbolType, nil)

    --飞行到终点后淡出
    local actList = {}
    table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(_flyTime, endPos), 2))
    table.insert(actList, cc.CallFunc:create(function()
        otherNode:setVisible(false)
        particle:stopSystem()
        util_setCascadeOpacityEnabledRescursion(particle, true)
        particle:runAction(cc.FadeOut:create(0.5))
    end))
    table.insert(actList,  cc.DelayTime:create(0.5))
    table.insert(actList, cc.CallFunc:create(function()
        poolData.csbNode:setVisible(false)
        table.insert(pool, poolData)
    end))

    otherNode:setVisible(true)
    poolData.csbNode:setVisible(true)
    poolData.csbNode:runCsbAction(_flyAnimData.animName, true)
    poolData.csbNode:runAction(cc.Sequence:create(actList))
end

--respin加总-收集反馈
function CodeGameScreenCherryBountyMachine:playReSpinBonusCollectFeedback(_targetSymbol, _animData, _curCoins, _targetCoins, _canSkip)
    --收集反馈
    local feedbackName = _animData.feedbackName
    local soundName2   = _animData.soundName2
    local soundTime2   = _animData.soundTime2
    --震动
    local bShake       = _animData.bShake
    
    self:choosePlaySound(_canSkip, soundName2, soundTime2)
    _targetSymbol:runAnim(feedbackName, false, function()
        self.m_symbolExpectCtr:playSymbolIdleAnim(_targetSymbol)
    end)
    if bShake then
        self:playCherryBountyReelShakeAnim(0.3)
    end
    local labCoins = self:getBonusSymbolCoinsLab(_targetSymbol)
    local labInfo  = self:getBonusCoinsLabelInfo(labCoins, _targetSymbol.p_symbolType)
    self:playLabelJumpCoins(labCoins, labInfo, _curCoins, _targetCoins, 0.3, false)
end

--respin加总-跳过
function CodeGameScreenCherryBountyMachine:playSkipReSpinBonusCollectAnim(_skipIndex, _skipData, _fun)
    --硬切所有bonus的时间线为idle
    --硬切收集完成的bonus奖励
    --收集进行中和未收集的bonus同时进行收集 结束后 刷新底栏金额
    --保留飞行途中的所有粒子效果 但是飞行结束不会播反馈动画和音效
    local targetList    = _skipData.targetList
    local sourceList    = _skipData.sourceList
    local targetSymbol  = _skipData.targetSymbol
    local newSourceList = _skipData.newSourceList
    local targetType    = targetList[1].p_symbolType
    local bSuper        = self:isCherryBountySuperReSpin()

    local residueList = {}
    local targetPos  = self:getCherryBountyPosReelIdx(targetSymbol.p_rowIndex, targetSymbol.p_cloumnIndex, bSuper)
    local bonusCoins = self:getReelBonusCoins(targetPos)
    local lastCoins  = 0
    for _index,_symbol in ipairs(newSourceList) do
        local reelPos = self:getCherryBountyPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex, bSuper)
        local coins = self:getReelBonusCoins(reelPos)
        if _index > _skipIndex then
            table.insert(residueList, _symbol)
        else
            lastCoins = lastCoins + coins
        end
    end
    local bResidue = #residueList > 0
    local collectAnimData = self:getReSpinBonusCollectAnimData(targetSymbol, residueList)
    local collectTimeMax = collectAnimData.collectTime
    local collectTimeMin = collectTimeMax
    --收集
    for _index,_symbol in ipairs(residueList) do
        local animData = self:getReSpinBonusCollectAnimData(targetSymbol, {_symbol})
        collectTimeMin = math.min(collectTimeMin, animData.collectTime)
        self:playReSpinBonusCollectAnim(targetSymbol, _symbol, animData, lastCoins, bonusCoins, false)
    end
    --收集反馈
    self:levelPerformWithDelay(self,collectTimeMin,function()
        self:playReSpinBonusCollectFeedback(targetSymbol, collectAnimData, lastCoins, bonusCoins)
        local delay = collectTimeMax - collectTimeMin + collectAnimData.feedbackTime
        self:levelPerformWithDelay(self, delay, _fun)
    end)
end
--respin加总-根据来源和目标信号类型区分收集流程
function CodeGameScreenCherryBountyMachine:getReSpinBonusCollectAnimData(_targetSymbol, _sourceList)
    local collectAnimData = {}
    --收集
    collectAnimData.collectName = "shouji"
    collectAnimData.collectTime = 9/30
    collectAnimData.flyDelay    = 0
    collectAnimData.flyTime     = collectAnimData.collectTime - collectAnimData.flyDelay
    --[[
        飞行光圈的收集流程
        {
            symbolType = 94
            csbName    = "CherryBounty_Bonus_fly1.csb",
            animName   = "fly1"
        }
    ]]
    collectAnimData.flyAnimList = {}
    --反馈
    collectAnimData.feedbackName = "shouji"
    collectAnimData.feedbackTime = 0.1
    --高级bonus执行一个新类型低级bonus收集时的等待 (前置延时)(根据来源做区分)
    collectAnimData.collectTypeInterval = 0.8
    --音效
    collectAnimData.soundName1 = PublicConfig.sound_CherryBounty_ReSpinBonus1_collect
    collectAnimData.soundTime1 = 1.5
    collectAnimData.soundName2 = PublicConfig.sound_CherryBounty_ReSpinBonus1_collectFeedback
    collectAnimData.soundTime2 = 1
    --震动
    collectAnimData.bShake = false

    --取最高级bonus的信号类型
    local targetType = _targetSymbol.p_symbolType
    local sourceType = self.SYMBOL_Bonus1
    for i,_symbol in ipairs(_sourceList) do
        sourceType = math.max(sourceType, _symbol.p_symbolType)
        --飞行光圈的数据
        local flyAnimData = {}
        flyAnimData.symbolType = _symbol.p_symbolType
        flyAnimData.csbName    = "CherryBounty_Bonus_fly1.csb"
        flyAnimData.animName   = "fly1"
        if _symbol.p_symbolType == self.SYMBOL_Bonus1 then
            if targetType == self.SYMBOL_Bonus3 then
                flyAnimData.animName = "fly2"
            end
        elseif _symbol.p_symbolType == self.SYMBOL_Bonus2 then
            flyAnimData.csbName = "CherryBounty_Bonus_fly2.csb"
        else
            flyAnimData.csbName = "CherryBounty_Bonus_fly3.csb"
        end
        table.insert(collectAnimData.flyAnimList, flyAnimData)
    end
    --根据来源区分收集流程
    if sourceType == self.SYMBOL_Bonus1 then

    elseif sourceType == self.SYMBOL_Bonus2 then
        if targetType == self.SYMBOL_Bonus3 then
            collectAnimData.collectTime = 18/30
            collectAnimData.flyDelay    = 0
            collectAnimData.flyTime     = collectAnimData.collectTime - collectAnimData.flyDelay
        end
        collectAnimData.collectTypeInterval = 0.8
    elseif sourceType == self.SYMBOL_Bonus3 then
        collectAnimData.collectName = "actionframe2"
        collectAnimData.collectTime = 60/30
        collectAnimData.flyDelay    = 27/30
        collectAnimData.flyTime     = collectAnimData.collectTime - collectAnimData.flyDelay
        collectAnimData.collectTypeInterval = 1.3
    end

    --根据目标区分反馈流程和音效
    if targetType == self.SYMBOL_Bonus3 then
        collectAnimData.feedbackName = "shouji4"
        collectAnimData.collectOverTime = 1.3
        collectAnimData.soundName1 = PublicConfig.sound_CherryBounty_ReSpinBonus3_collect
        collectAnimData.soundTime1 = 1.7
        collectAnimData.soundName2 = PublicConfig.sound_CherryBounty_ReSpinBonus3_collectFeedback
        collectAnimData.soundTime2 = 1
        --根据来源区分反馈流程和音效
        if sourceType == self.SYMBOL_Bonus2 then
            collectAnimData.feedbackName = "shouji5"
        elseif sourceType == self.SYMBOL_Bonus3 then
            collectAnimData.feedbackName = "actionframe"
            collectAnimData.soundName1 = PublicConfig.sound_CherryBounty_ReSpinBonus3_specialCollect
            collectAnimData.soundTime1 = 2
            collectAnimData.soundName2 = PublicConfig.sound_CherryBounty_ReSpinBonus3_specialFeedback
            collectAnimData.soundTime2 = 1.3
            collectAnimData.bShake = true
        end
    end

    return collectAnimData
end


--延时执行-区分是否可以跳过
function CodeGameScreenCherryBountyMachine:choosePerformWithDelay(_canSkip, _delay, _fun)
    if _canSkip then
        self.m_skipLayer:skipLayerPerformWithDelay(_delay, _fun)
    else
        self:levelPerformWithDelay(self, _delay, _fun)
    end
end
--音效播放-区分是否可以跳过
function CodeGameScreenCherryBountyMachine:choosePlaySound(_canSkip, _soundName, _soundTime)
    if _canSkip then
        self.m_skipLayer:skipLayerPlaySound(_soundName, _soundTime)
    else
        gLobalSoundManager:playSound(_soundName)
    end
end


--respin事件-bonus3加总
function CodeGameScreenCherryBountyMachine:isTriggerReSpinEffectBonus3()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus3Pos = selfData.bonus3_positon or {}
    if #bonus3Pos > 0 then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playReSpinEffectBonus3(_fun)
    local selfData   = self.m_runSpinResultData.p_selfMakeData
    local bonus2Pos  = selfData.bonus2_positon or {}
    local bonusPos   = selfData.bonus3_positon
    local symbolList = self:getReSpinSymbolListByPosList({}, bonusPos, true)
    local bSuper     = self:isCherryBountySuperReSpin()
    local sourceList = self:getReSpinSymbolListByType({}, {self.SYMBOL_Bonus1, self.SYMBOL_Bonus2, self.SYMBOL_Bonus3})
    self:playBonusCollectCoinsByList(1, symbolList, sourceList, function()
        _fun()
    end)
end
--respin事件-次数重置
function CodeGameScreenCherryBountyMachine:isTriggerReSpinEffectReSpinMore()
    if self:isTriggerReSpinEffectBonus2() or self:isTriggerReSpinEffectBonus3() then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playReSpinEffectReSpinMore(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpin_addTimes)
    self.m_reSpinTopTips:playReSpinBarResetAnim()
    _fun()
end

--respin事件-全满
function CodeGameScreenCherryBountyMachine:isTriggerReSpinEffectFullUp()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.fullScreen then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:playReSpinEffectFullUp(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpin_settlementTrigger)
    local selfData   = self.m_runSpinResultData.p_selfMakeData
    local fullScreen =  selfData.fullScreen
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local symbolList  = self:getReSpinSymbolListByIcons(storedIcons)
    local animTime = 0
    for i,v in ipairs(symbolList) do
        local symbol = symbolList[i]
        local animName = "actionframe"
        if symbol.p_symbolType == self.SYMBOL_Bonus3 then
            animName = "actionframe2"
        end
        animTime = symbol:getAniamDurationByName(animName)
        symbol:runAnim(animName, false, function()
            self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
        end)
    end

    local jpIndex = self.JackpotTypeToIndex[fullScreen.jp_name]
    local jpCoins = tonumber(fullScreen.jp_coins)
    local jpMulti = 1
    self:levelPerformWithDelay(self, animTime, function()
        self.m_jackpotBar:playJackpotBarTrigger({jpIndex})
        self:playFullUpSpine(function()
            self:showJackpotView(jpIndex, jpCoins, jpMulti, function()
                self.m_jackpotBar:playJackpotBarIdle()
                _fun()
            end)
            self:updateBottomUICoins(jpCoins, false, true, false, false)
        end)
    end)
end

--棋盘遮挡|喷金币
function CodeGameScreenCherryBountyMachine:playFullUpSpine(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FullUp_start)
    self:levelPerformWithDelay(self, 3, function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_FullUp_over)
    end)
    if not self.m_fullUpSpine1 then
        self.m_fullUpSpine1 = util_spineCreate("CherryBounty_grand_tanban",true,true)
        self:findChild("Node_grand"):addChild(self.m_fullUpSpine1)
    else
        self.m_fullUpSpine1:setVisible(true)
    end
    local bSuper = self:isCherryBountySuperReSpin()
    local animName = "actionframe"
    if bSuper then
        animName = "actionframe2"
    end
    self:findChild("Panel_clip"):setClippingEnabled(true)
    util_spinePlay(self.m_fullUpSpine1, animName, false)
    util_spineEndCallFunc(self.m_fullUpSpine1,  animName, function()
        self:findChild("Panel_clip"):setClippingEnabled(false)
        self.m_fullUpSpine1:setVisible(false)
        _fun()
    end)
    self:playJumpCoinsSpine()
    self:runCsbAction("actionframe", false)
end

function CodeGameScreenCherryBountyMachine:playJumpCoinsSpine()
    if not self.m_jumpCoinsSpine1 then
        self.m_jumpCoinsSpine1 = util_spineCreate("CherryBounty_grand_tanban",true,true)
        self:findChild("Node_bigwin1"):addChild(self.m_jumpCoinsSpine1)

        self.m_jumpCoinsSpine2 = util_spineCreate("CherryBounty_grand_tanban",true,true)
        self:findChild("Node_bigwin2"):addChild(self.m_jumpCoinsSpine2)
    else
        self.m_jumpCoinsSpine1:setVisible(true)
        self.m_jumpCoinsSpine2:setVisible(true)
    end

    local fnPlaySpine = function(_animName, _fnNext)
        util_spinePlay(self.m_jumpCoinsSpine1, _animName, false)
        util_spinePlay(self.m_jumpCoinsSpine2, _animName, false)
        util_spineEndCallFunc(self.m_jumpCoinsSpine1,  _animName, _fnNext)
    end
    fnPlaySpine("start", function()
        fnPlaySpine("idle", function()
            fnPlaySpine("idle", function()
                fnPlaySpine("over", function()
                    self.m_jumpCoinsSpine1:setVisible(false)
                    self.m_jumpCoinsSpine2:setVisible(false)
                end)
            end)
        end)
    end)
end

function CodeGameScreenCherryBountyMachine:showJackpotView(_jpIndex, _jpCoins, _jpMulti, _fun)
    local soundKey = string.format("sound_CherryBountye_JackpotView_%d", _jpIndex)
    gLobalSoundManager:playSound(PublicConfig[soundKey])
    local viewData = {}
    viewData.machine   = self
    viewData.index     = _jpIndex
    viewData.coins     = _jpCoins
    viewData.multi     = _jpMulti
    viewData.csbName   =  "JackpotWinView.csb"
    local view = util_createView("CherryBountySrc.CherryBountyJackPotView", viewData)
    view:setOverAniRunFunc(function()
        _fun()
    end)
    gLobalViewManager:showUI(view)
    local dialogScale = self:getDialogMainLayerScale()
    view:findChild("root"):setScale(dialogScale)
end

--respin-结算
function CodeGameScreenCherryBountyMachine:respinOver()
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local symbolList  = self:getReSpinSymbolListByIcons(storedIcons)
    local fnNext = function()
        self:showCherryBountyReSpinOverView(function()
            CodeGameScreenCherryBountyMachine.super.respinOver(self)
            self:featureOverUpDateReel(true)
        end)
    end
    --跳过
    local skipData = {}
    skipData.reSpinOverList = symbolList
    local fnSkip = function(_skIndex, _skData)
        self:playSkipReSpinOverCollect(_skIndex, _skData, fnNext)
    end
    self.m_skipLayer:showSkipLayer(1, skipData, fnSkip)

    self:playReSpinOverCollect(1, symbolList, function()
        self.m_skipLayer:hideSkipLayer()
        fnNext()
    end)
end
--respin-获取固定图标
function CodeGameScreenCherryBountyMachine:getReSpinSymbolListByIcons(_icons)
    local bSuper = self:isCherryBountySuperReSpin()
    local symbolList = {}
    for i,_data in ipairs(_icons) do
        local fixPos  = self:getCherryBountyRowAndColByPos(_data[1], bSuper)
        local symbol  = self.m_respinView:getReSpinSymbolNode(fixPos.iX, fixPos.iY)
        table.insert(symbolList, symbol)
    end
    table.sort(symbolList, function(_symbolA, _symbolB)
        if _symbolA.p_cloumnIndex ~= _symbolB.p_cloumnIndex then
            return _symbolA.p_cloumnIndex < _symbolB.p_cloumnIndex
        end
        if _symbolA.p_rowIndex ~= _symbolB.p_rowIndex then
            return _symbolA.p_rowIndex > _symbolB.p_rowIndex
        end
        return false
    end)
    return symbolList
end
--respin-获取固定图标
function CodeGameScreenCherryBountyMachine:getReSpinSymbolListByPosList(_symbolList, _posList, _bSort)
    local bSuper = self:isCherryBountySuperReSpin()
    for i,_reelPos in ipairs(_posList) do
        local fixPos  = self:getCherryBountyRowAndColByPos(_reelPos, bSuper)
        local symbol  = self.m_respinView:getReSpinSymbolNode(fixPos.iX, fixPos.iY)
        table.insert(_symbolList, symbol)
    end
    if _bSort then
        table.sort(_symbolList, function(_symbolA, _symbolB)
            if _symbolA.p_cloumnIndex ~= _symbolB.p_cloumnIndex then
                return _symbolA.p_cloumnIndex < _symbolB.p_cloumnIndex
            end
            if _symbolA.p_rowIndex ~= _symbolB.p_rowIndex then
                return _symbolA.p_rowIndex > _symbolB.p_rowIndex
            end
            return false
        end)
    end
    
    return _symbolList
end
--respin-获取固定图标
function CodeGameScreenCherryBountyMachine:getReSpinSymbolListByType(_symbolList, _symbolTypeList)
    local bSuper = self:isCherryBountySuperReSpin()
    local maxCount = self.m_respinView.m_machineCol * self.m_respinView.m_machineRow
    for _index=1,maxCount do
        local reelPos = _index-1
        local fixPos  = self:getCherryBountyRowAndColByPos(reelPos, bSuper)
        local symbol  = self.m_respinView:getReSpinSymbolNode(fixPos.iX, fixPos.iY)
        for i,_symbolType in ipairs(_symbolTypeList) do
            if symbol.p_symbolType == _symbolType then
                table.insert(_symbolList, symbol)
                break
            end
        end
    end
    --排序方式 仅限respin加总
    table.sort(_symbolList, function(_symbolA, _symbolB)
        --信号值
        if _symbolA.p_symbolType ~= _symbolB.p_symbolType then
            return _symbolA.p_symbolType < _symbolB.p_symbolType
        end
        --所在列
        if _symbolA.p_cloumnIndex ~= _symbolB.p_cloumnIndex then
            return _symbolA.p_cloumnIndex < _symbolB.p_cloumnIndex
        end
        --所在行
        if _symbolA.p_rowIndex ~= _symbolB.p_rowIndex then
            return _symbolA.p_rowIndex > _symbolB.p_rowIndex
        end
        return false
    end)
    
    return _symbolList
end

--respin-收集
function CodeGameScreenCherryBountyMachine:playReSpinOverCollect(_index, _list, _fun)
    local symbol = _list[_index]
    if not symbol then
        return _fun()
    end
    --最后一次收集禁止跳过
    local canSkip = true
    local bLast = not _list[_index+1]
    if bLast then
        canSkip = false
        self.m_skipLayer:hideSkipLayer()
    end
    if canSkip then
        self.m_skipLayer:saveSkipData(_index)
    end

    local bLast   = not _list[_index+1]
    local bSuper  = self:isCherryBountySuperReSpin()
    local reelPos = self:getCherryBountyPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex, bSuper)
    local coins   = self:getReelBonusCoins(reelPos)
    local flyData = self:getReSpinOverFlyData(symbol.p_symbolType)

    symbol:runAnim(flyData.collectName, false)
    self:choosePlaySound(canSkip, flyData.soundName, flyData.soundTime)
    self:choosePerformWithDelay(canSkip, flyData.flyDelay, function()
        local endNode = self.m_bottomUI.m_normalWinLabel
        --飞行表现不能被切
        self:playParticleFly({"Particle_4"}, symbol, endNode, flyData.flyTime)
        --飞行结束反馈要跳过
        self:choosePerformWithDelay(canSkip, flyData.flyTime, function()
            self:updateBottomUICoins(coins, false, true, false, false)
            self:playTotalWinSpineAnim()
            --最后一次的间隔要为跳钱时间
            local delayTime = 0.3
            if bLast then
                delayTime = self.m_bottomUI:getCoinsShowTimes(coins)
            end
            self:choosePerformWithDelay(canSkip, delayTime, function()
                self:playReSpinOverCollect(_index+1, _list, _fun)
            end)
        end)
    end)
end
--respin-结算流程的飞行数据
function CodeGameScreenCherryBountyMachine:getReSpinOverFlyData(_symbolType)
    local flyData = {}
    flyData.collectName = "shouji3"
    flyData.flyDelay  = 3/ 30
    flyData.flyTime   = 6/ 30
    flyData.soundName = PublicConfig.sound_CherryBounty_Bonus1_reSpinSettlement
    flyData.soundTime = 1.7
    if _symbolType == self.SYMBOL_Bonus3 then
        flyData.collectName = "actionframe"
        flyData.soundName = PublicConfig.sound_CherryBounty_Bonus3_reSpinSettlement
    end
    return flyData
end


--respin-跳过结算收集
function CodeGameScreenCherryBountyMachine:playSkipReSpinOverCollect(_skipIndex, _skipData, _fun)
    --硬切所有bonus的时间线为idle
    --硬切底栏的提示金额
    --硬切底栏金额
    --保留飞行途中所有粒子效果
    local bSuper     = self:isCherryBountySuperReSpin()
    local symbolList = _skipData.reSpinOverList
    local tipCoins   = 0
    local animTime   = 0
    local endNode = self.m_bottomUI.m_normalWinLabel
    --最高级的反馈音效
    local soundData = {}
    soundData.symbolType = self.SYMBOL_Bonus1
    soundData.soundName  = PublicConfig.sound_CherryBounty_Bonus1_reSpinSettlement
    for _index,v in ipairs(symbolList) do
        local symbol = symbolList[_index]
        if _index > _skipIndex then
            local reelPos    = self:getCherryBountyPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex, bSuper)
            local bonusCoins = self:getReelBonusCoins(reelPos)
            tipCoins = tipCoins + bonusCoins
            local flyData = self:getReSpinOverFlyData(symbol.p_symbolType)
            --收集
            animTime = math.max(flyData.flyDelay + flyData.flyTime)
            if soundData.symbolType < symbol.p_symbolType then
                soundData.symbolType = symbol.p_symbolType
                soundData.soundName = flyData.soundName
            end
            symbol:runAnim(flyData.collectName, false)
            self:levelPerformWithDelay(self, flyData.flyDelay, function()
                self:playParticleFly({"Particle_4"}, symbol, endNode, flyData.flyTime)
            end)
        else
            symbol:runAnim("idleframe", false)
        end
    end
    local bCoins = tipCoins > 0
    if bCoins then
        gLobalSoundManager:playSound(soundData.soundName)
    end
    --收集反馈 刷新提示金额 刷新底栏金额 
    self:levelPerformWithDelay(self, animTime, function()
        local delayTime = 0
        if bCoins then
            delayTime = 150/60
            self:playTotalWinSpineAnim()
            self:playCherryBountyBigWinLabelJumpCoins(tipCoins, tipCoins, 0.01)
        end
        local respinWinCoins = self.m_runSpinResultData.p_resWinCoins
        self:updateBottomUICoins(respinWinCoins, false, false, false, false)
        self:levelPerformWithDelay(self, delayTime, _fun)
    end)
end



--respin-结算弹板
function CodeGameScreenCherryBountyMachine:showCherryBountyReSpinOverView(_fun)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpinOver_start)
    local reSpinModel = self:getCurReSpinModel()
    local fnSwitch = function()
        self.m_bReSpinReconnect = false
        self.m_reSpinTopTips:setVisible(false)
        self.m_reSpinReelTips:setVisible(false)
        self.m_skipLayer:setSkipLayContentSize(false)
        self:changeCherryBountyTouchSize(false)
        self.m_topWildCollect:playIdleAnim()
        self.m_topWildCollect:setVisible(true)
        self.m_reelTips:setVisible(true)
        self:changeReelBg(self.BgModel.Base, true)
        self:featureOverUpDateReel()
        --提前隐藏respin并且打开棋盘图标可见性
        self.m_respinView:setVisible(false)
        self:setReelSlotsNodeVisible(true)
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpinOver_over)
        --关卡适配-superReSpin
        if self:isCherryBountySuperReSpin() then
            self:upDateSuperReSpinMainLayerScale(false)
        end
    end
    local viewData = {}
    viewData.coins    = self.m_runSpinResultData.p_resWinCoins
    viewData.bReSpin5 = reSpinModel == self.BgModel.Respin5
    viewData.bReSpin7 = reSpinModel == self.BgModel.Respin7
    viewData.fnSwitch = fnSwitch
    viewData.fnOver   = function()
        _fun()
    end
    local view = self:showFeatureWinView(viewData)
end
--respin-结束
function CodeGameScreenCherryBountyMachine:showRespinOverView(effectData)
    self:triggerReSpinOverCallFun(0)
end

--玩法结算弹板
function CodeGameScreenCherryBountyMachine:showFeatureWinView(_data)
    --[[
        _data = {
            coins     = 0
            bFree     = true
            freeTimes = 0
            bReSpin5  = false
            bReSpin7  = false
            bBonus    = false
            fnSwitch  = function 
            fnOver    = function 
        }
    ]]
    local csbName   = "CherryBounty_PickRespinOver"
    local ownerlist = {}
    local fnSwitch    = function()
        _data.fnSwitch()
    end
    local fnOver    = function()
        _data.fnOver()
    end
    local view = self:showDialog(csbName, ownerlist, fnOver)
    local dialogScale = self:getDialogMainLayerScale()
    view:findChild("root"):setScale(dialogScale)
    
    --spine添加 调整弹板时间线时长和spine一致
    local spineOver = util_spineCreate("CherryBounty_Over2", true, true)
    view:findChild("Node_spine"):addChild(spineOver)
    if _data.bBonus then
        spineOver:setSkin("pick")
    else
        spineOver:setSkin("free")
    end
    local spineTanban = util_spineCreate("CherryBounty_grand_tanban", true, true)
    view:findChild("Node_bigwin"):addChild(spineTanban)
    --弹板节点绑定到spine指定插槽
    util_spinePushBindNode(spineOver, "Node_shuzi2", view:findChild("kuang"))
    util_spinePushBindNode(spineOver, "Node_anniu",  view:findChild("anniu"))
    util_spinePushBindNode(spineOver, "Node_wenzi",  view:findChild("Node_overwenzi"))
    --不同模式的节点表现
    local modelCsb = util_createAnimation("CherryBounty/CherryBounty_overwenzi.csb")
    view:findChild("Node_overwenzi"):addChild(modelCsb)
    view.m_modelCsb = modelCsb
    local sModel = self.BgModel.Bonus
    if _data.bFree then
        sModel = self.BgModel.Free
        local lanNum = modelCsb:findChild("m_lb_num")
        lanNum:setString(tostring(_data.freeTimes))
    elseif _data.bReSpin5 then
        sModel = self.BgModel.Respin5
    elseif _data.bReSpin7 then
        sModel = self.BgModel.Respin7
    elseif _data.bBonus then
        sModel = self.BgModel.Bonus
    end
    for i,_node in ipairs(modelCsb:findChild("Node_model"):getChildren()) do
        local nodeName = _node:getName()
        _node:setVisible(sModel == nodeName)
    end
    --弹板跳钱
    self:playFeatureWinViewJumpCoinsSound()
    local labelCoins = view:findChild("m_lb_coins")
    local labelInfo  = {label=labelCoins, sx=1, sy=1, width=727}
    local fnUpDateLabelCoins = function(_viewCoins)
        local sCoins = util_formatCoins(_viewCoins, 30)
        labelCoins:setString(sCoins)
        self:updateLabelSize(labelInfo, labelInfo.width)
    end
    local fnJumpOver = function()
        self:stopFeatureWinViewJumpCoinsSound(true)
    end
    self:playLabelJumpCoins(labelCoins, labelInfo, 0, _data.coins, 2, true, fnJumpOver)
    --动画播放
    local startName = "start"
    local idleName  = "idle"
    local overName  = "over"
    util_spinePlay(spineOver, startName, false)
    util_spinePlay(spineTanban, startName, false)
    util_spineEndCallFunc(spineOver,  startName, function()
        util_spinePlay(spineOver, idleName, true)
    end)
    util_spineEndCallFunc(spineTanban,  startName, function()
        util_spinePlay(spineTanban, idleName, true)
    end)
    --音效
    view.m_btnTouchSound = PublicConfig.sound_CherryBounty_CommonClick
    view:setBtnClickFunc(function()
        labelCoins:stopAllActions()
        fnUpDateLabelCoins(_data.coins)
        self:stopFeatureWinViewJumpCoinsSound(true)
        util_spinePlay(spineOver, overName, false)
        util_spinePlay(spineTanban, overName, false)
        fnSwitch()
    end)

    return view
end
--玩法结算弹板-跳钱音效
function CodeGameScreenCherryBountyMachine:playFeatureWinViewJumpCoinsSound()
    self:stopFeatureWinViewJumpCoinsSound(false)
    self.m_featureWinViewSoundId = gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_jumpCoins, true)
end
function CodeGameScreenCherryBountyMachine:stopFeatureWinViewJumpCoinsSound(_bStopSound)
    if self.m_featureWinViewSoundId then
        gLobalSoundManager:stopAudio(self.m_featureWinViewSoundId)
        self.m_featureWinViewSoundId = nil
        if _bStopSound then
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotView_jumpCoinsOver)
        end
    end
end

--初始棋盘
function CodeGameScreenCherryBountyMachine:initCherryBountyFirstReel()
    --无玩法
    if self:checkHasFeature() then
        return
    end
    --当前bet没有固定wild
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local betData  = self.m_lockWild:geLockWildDataByBet(totalBet)
    local wildPos  = betData.wild_position
    if #wildPos > 0 then
        return
    end
    local initReel = {94, 94, 92, 94, 94}
    for iCol,_symbolType in ipairs(initReel) do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol then
                local reelPos = self:getCherryBountyPosReelIdx(iRow, iCol)
                local bLock = nil ~= self.m_lockWild:getLockWildByReelPos(reelPos)
                local newSymbolType = _symbolType
                if bLock then
                    newSymbolType = self:getReplaceWildSymbolType()
                end
                self:changeReelSymbolType(symbol, newSymbolType)
                self:addSpineSymbolCsbNode(symbol)
                self:changeReelSymbolOrder(symbol, true, 0)
                local bBonus = self:isCherryBountyBonus(symbol.p_symbolType)
                if bBonus then
                    local bonusData = self:getInitReelBonusRewardData()
                    self:upDateBonusReward(symbol, bonusData)
                end
                symbol:runAnim("idleframe", false)
            end
        end
    end
end
--重写-数据返回
function CodeGameScreenCherryBountyMachine:spinResultCallFun(param)
    CodeGameScreenCherryBountyMachine.super.spinResultCallFun(self, param)
    if param[1] == true then
        local spinData = param[2]
        --刷新当前bet的收集数据
        self.m_lockWild:spinUpDateLockWildBetList(spinData.result)
    end
end
--重写-预告中奖
function CodeGameScreenCherryBountyMachine:showFeatureGameTip(_fun)
    local delayTime = 0
    local triggerType = self.m_yugaoAnim:isTriggerYuGao()
    if "" ~= triggerType then
        self.b_gameTipFlag = true
        delayTime = self.m_yugaoAnim:playYuGaoAnim(triggerType)
    end
    self:levelPerformWithDelay(self, delayTime+0.5, _fun)
end
--重写-大赢
function CodeGameScreenCherryBountyMachine:showEffect_NewWin(effectData, winType)
    self:playLevelBigWinAnim(function()
        --停止连线音效
        self:stopLinesWinSound()
        CodeGameScreenCherryBountyMachine.super.showEffect_NewWin(self, effectData, winType)
    end)
end
function CodeGameScreenCherryBountyMachine:playLevelBigWinAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_BigWin)
    if not self.m_bigWinSpine1 then
        local nodeWinCoinEffect = self.m_bottomUI:getCoinWinNode()
        local parent  = self.m_effectNodeDown
        local pos     = util_convertToNodeSpace(nodeWinCoinEffect, parent)
        local nodePos = parent:convertToNodeSpace(cc.p(display.width/2, display.height/2))
        --
        self.m_bigWinSpine1 = util_spineCreate("CherryBounty_grand_tanban", true, true)
        parent:addChild(self.m_bigWinSpine1, 10)
        self.m_bigWinSpine1:setPosition(nodePos.x, pos.y)
        --
        self.m_bigWinSpine2 = util_spineCreate("CherryBounty_bigwin", true, true)
        parent:addChild(self.m_bigWinSpine2, 20)
        self.m_bigWinSpine2:setPosition(nodePos.x, pos.y)
    else
        self.m_bigWinSpine1:setVisible(true)
        self.m_bigWinSpine2:setVisible(true)
    end

    local animName = "actionframe_bigwin"
    local animTime = self.m_bigWinSpine1:getAnimationDurationTime(animName)
    self:levelPerformWithDelay(self, animTime, function()
        self.m_bigWinSpine1:setVisible(false)
        self.m_bigWinSpine2:setVisible(false)
        _fun()
    end)
    util_spinePlay(self.m_bigWinSpine1, animName, false)
    util_spinePlay(self.m_bigWinSpine2, animName, false)

    self:playCherryBountyBigWinLabelJumpCoins(0, self.m_llBigOrMegaNum, 0.4)
    self:playCherryBountyReelShakeAnim(animTime)
end
--大赢文本跳钱
function CodeGameScreenCherryBountyMachine:playCherryBountyBigWinLabelJumpCoins(_coins1, _coins2, _time)
    --赢钱数字
    local info = {
        beginCoins = _coins1,
        overCoins  = _coins2,
        animName   = "actionframe3",
        jumpTime   = _time,
    }
    self:playBottomBigWinLabAnim(info)
end

--棋盘震动
function CodeGameScreenCherryBountyMachine:playCherryBountyReelShakeAnim(_time)
    local node = self:findChild("Node_other")
    node:stopAllActions()
    node:setPosition(0, 0)
    util_shakeNode(node, 4, 4, _time)
end

--重写-刷新滚轴小块
function CodeGameScreenCherryBountyMachine:updateReelGridNode(_symbol)
    self:addSpineSymbolCsbNode(_symbol)
    self:upDateReelBonusReward(_symbol)
    self:upDateReelWildTimes(_symbol)
    self:registerBonus2AnimCall(_symbol)
end
--spine图标绑定csb
CodeGameScreenCherryBountyMachine.SpineSymbolBindCfg = {
    [CodeGameScreenCherryBountyMachine.SYMBOL_Bonus1] = {csbName = "CherryBounty_Bonus_Label.csb", boneName = "shuzi"},
    [CodeGameScreenCherryBountyMachine.SYMBOL_Bonus2] = {csbName = "CherryBounty_Bonus_Label.csb", boneName = "shuzi"},
    [CodeGameScreenCherryBountyMachine.SYMBOL_Bonus3] = {csbName = "CherryBounty_Bonus_Label.csb", boneName = "shuzi"},
}
function CodeGameScreenCherryBountyMachine:addSpineSymbolCsbNode(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    local symbolCfg  = self.SpineSymbolBindCfg[symbolType]
    if not symbolCfg then
        return
    end

    -- csb需要播放时间线时 必须重新创建
    local animNode  = _symbol:checkLoadCCbNode()
    local spineNode = animNode.m_spineNode or (_symbol.m_symbolType and animNode) 
    if animNode.m_bindCsb then
        animNode.m_bindCsb = nil
        util_spineClearBindNode(spineNode)
    end
    animNode.m_bindCsb = self:createSpineSymbolBindCsb(symbolType)
    util_spinePushBindNode(spineNode, symbolCfg.boneName, animNode.m_bindCsb)
end
function CodeGameScreenCherryBountyMachine:createSpineSymbolBindCsb(_symbolType)
    local symbolCfg  = self.SpineSymbolBindCfg[_symbolType]
    local csb = util_createAnimation(symbolCfg.csbName)
    csb:runCsbAction("idleframe", false)
    local bonusIndex = self:getCherryBountyBonusIndex(_symbolType)
    for _index=1,3 do
        local bVis = _index==bonusIndex
        local bonusNode = csb:findChild(string.format("bonus%d", _index))
        bonusNode:setVisible(bVis)
    end
    return csb
end
--获取一个bonus上正在使用的金额文本
function CodeGameScreenCherryBountyMachine:getBonusSymbolCoinsLab(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    local bonusIndex = self:getCherryBountyBonusIndex(symbolType)
    local animNode = _symbol:getCCBNode()
    local bindCsb  = animNode.m_bindCsb
    local nodeName = string.format("m_lb_coins_%d", bonusIndex)
    local labCoins = bindCsb:findChild(nodeName)
    return labCoins
end

--bonus
function CodeGameScreenCherryBountyMachine:isCherryBountyBonus(_symbolType)
    if _symbolType == self.SYMBOL_Bonus1 or 
        _symbolType == self.SYMBOL_Bonus2 or 
        _symbolType == self.SYMBOL_Bonus3 then
        return true
    end
    return false
end
function CodeGameScreenCherryBountyMachine:getCherryBountyBonusIndex(_symbolType)
    if self:isCherryBountyBonus(_symbolType) then
        return _symbolType + 1 - self.SYMBOL_Bonus1
    end
    return nil
end
function CodeGameScreenCherryBountyMachine:upDateReelBonusReward(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if not self:isCherryBountyBonus(symbolType) then
        return
    end
    local bonusData = nil
    local bFree    = self:getCurrSpinMode()  == FREE_SPIN_MODE
    local bReSpin  = self:getCurrSpinMode()  == RESPIN_MODE
    local bReelRun = self:getGameSpinStage() ~= IDLE
    --free
    if bFree then
        if bReelRun then
            bonusData = self:getFreeReelBonusData()
        else
            bonusData = self:getFreeReelMultBonusData()
        end
    --respin-滚动
    elseif bReSpin and bReelRun then
        bonusData = self:getReSpinRunBonusData()
    --假滚
    elseif not _symbol.m_isLastSymbol or _symbol.p_rowIndex > self.m_iReelRowNum then
        bonusData = self:getRandomBonusRewardData()
    --滚动中停轮数据
    elseif bReelRun then
        local reelPos = self:getCherryBountyPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex)
        bonusData = self:getReelBonusRewardData(reelPos)
    --断线重连停轮数据
    else
        local bSuper  = self:isCherryBountySuperReSpin()
        local reelPos = self:getCherryBountyPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex, bSuper)
        bonusData = self:getReelBonusRewardData(reelPos)
    end
    self:upDateBonusReward(_symbol, bonusData)
end
--bonus-根据数据刷新图标
function CodeGameScreenCherryBountyMachine:upDateBonusReward(_symbol, _bonusData)
    local animNode = _symbol:getCCBNode()
    local bindCsb  = animNode.m_bindCsb
    self:upDateBonusBindCsb(bindCsb, _bonusData)
end
--bonus-根据数据刷新绑定csb
function CodeGameScreenCherryBountyMachine:upDateBonusBindCsb(_bindCsb, _bonusData)
    local coins  = self:getReelBonusCoins(nil, _bonusData)
    local labCoins1 = _bindCsb:findChild("m_lb_coins_1")
    local labCoins2 = _bindCsb:findChild("m_lb_coins_2")
    local labCoins3 = _bindCsb:findChild("m_lb_coins_3")
    self:upDateBonusCoinsLabelSize(labCoins1, coins, self.SYMBOL_Bonus1, nil)
    self:upDateBonusCoinsLabelSize(labCoins2, coins, self.SYMBOL_Bonus2, nil)
    self:upDateBonusCoinsLabelSize(labCoins3, coins, self.SYMBOL_Bonus3, nil)
end
--bonus-刷新绑定csb内的指定文本
function CodeGameScreenCherryBountyMachine:upDateBonusCoinsLabelSize(_labCoins, _coins, _symbolType, _labInfo)
    --没有金额就只刷新文本适配
    if _coins then
        local sCoins = ""
        if _coins > 0 then
            sCoins = util_formatCoinsLN(_coins, 4)
        end
        _labCoins:setString(sCoins)
    end
    local labInfo = {}
    if _labInfo then
        for k,v in pairs(_labInfo) do
            labInfo[k] = v
        end
    else
        labInfo = self:getBonusCoinsLabelInfo(_labCoins, _symbolType)
    end
    --文本适配
    local labText  = _labCoins:getString()
    local textLen  = string.len(labText)
    local bEnlarge = textLen <= 3
    --文本适配-放大
    if bEnlarge then
        local scale = 1.3
        labInfo.sx = labInfo.sx * scale
        labInfo.sy = labInfo.sy * scale
    end
    self:updateLabelSize(labInfo, labInfo.width)
end
--bonus-获取指定bonus绑定csb的文本适配
function CodeGameScreenCherryBountyMachine:getBonusCoinsLabelInfo(_labCoins, _symbolType)
    local labInfo = {label=_labCoins,  sx=0.82, sy=0.82, width=145}
    if _symbolType == self.SYMBOL_Bonus3 then
        labInfo = {label=_labCoins,  sx=0.68, sy=0.68, width=216}
    end
    return labInfo
end
--bonus2-区分连线和非连线时的文本展示
function CodeGameScreenCherryBountyMachine:registerBonus2AnimCall(_symbol)
    local symbolType = _symbol.p_symbolType
    if symbolType == self.SYMBOL_Bonus2 then
        local lineAnimName = "actionframe2"
        _symbol:setLineAnimName(lineAnimName)
    end
end
--bonus-随机数据
function CodeGameScreenCherryBountyMachine:getRandomBonusRewardData()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local multip   = self.m_configData:getBonus1SymbolRandomMulti()
    local coins    = totalBet * multip
    local bonusData = {}
    bonusData[1]    = -1
    bonusData[2]    = self:getCherryBountyLongNumString(coins)
    return bonusData
end
--bonus-初始化棋盘
function CodeGameScreenCherryBountyMachine:getInitReelBonusRewardData()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local multip   = 5
    local coins    = totalBet * multip
    local bonusData = {}
    bonusData[1]    = -1
    bonusData[2]    = self:getCherryBountyLongNumString(coins)
    return bonusData
end
--bonus-服务器数据
function CodeGameScreenCherryBountyMachine:getReelBonusRewardData(_reelPos)
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfData.storedIcons_2 or {}
    for i,_bonusData in ipairs(storedIcons) do
        if _reelPos == _bonusData[1] then
            return clone(_bonusData) 
        end
    end
    return self:getDefaultBonusData()
end
--bonus-服务器数据-恢复轮盘
function CodeGameScreenCherryBountyMachine:getFeatureOverBonusRewardData(_reelPos)
    local bonusExtra  = self.m_runSpinResultData.p_bonusExtra
    local selfData    = bonusExtra.spinR_selfData or {}
    local storedIcons = selfData.storedIcons_2 or {}
    for i,_bonusData in ipairs(storedIcons) do
        if _reelPos == _bonusData[1] then
            return clone(_bonusData) 
        end
    end
    return self:getDefaultBonusData()
end
--bonus金额-服务器数据 (所有获取bonusData里面金额的位置 都用这个套一层)
function CodeGameScreenCherryBountyMachine:getReelBonusCoins(_reelPos, _bonusData)
    local bonusData  = _bonusData 
    if not bonusData then
        bonusData  = self:getReelBonusRewardData(_reelPos)
    end
    local bonusCoins = tonumber(bonusData[2])
    return bonusCoins
end

--bonus2-free停轮时-服务器数据
function CodeGameScreenCherryBountyMachine:getFreeReelBonusData()
    local bonusData = {}
    bonusData[1] = -1
    bonusData[2] = self:getCherryBountyLongNumString(self:getFreeBonus2BaseCoins())
    return bonusData
end
--bonus2-free停轮时-乘倍后
function CodeGameScreenCherryBountyMachine:getFreeReelMultBonusData()
    local bonusData = {}
    bonusData[1] = -1
    bonusData[2] = self:getCherryBountyLongNumString(self:getFreeBonus2Coins())
    return bonusData
end
--bonus23-respin停轮时-服务器数据
function CodeGameScreenCherryBountyMachine:getReSpinRunBonusData()
    return self:getDefaultBonusData()
end
--bonus-默认数据
function CodeGameScreenCherryBountyMachine:getDefaultBonusData()
    local bonusData = {}
    bonusData[1] = -1
    bonusData[2] = self:getCherryBountyLongNumString(0)
    return bonusData
end
--大数-获取对应字符串
function CodeGameScreenCherryBountyMachine:getCherryBountyLongNumString(_number)
    local sNum = tostring(toLongNumber(_number))
    if tonumber(sNum) ~= _number then
        local sMsg = string.format("[CodeGameScreenCherryBountyMachine:getCherryBountyLongNumString] 1 error %d %d",tonumber(sNum), _number)
        print(sMsg)
        release_print(sMsg)
    end
    return sNum
end

--wild图标
function CodeGameScreenCherryBountyMachine:upDateReelWildTimes(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return
    end
    local wildTimes = 3-1
    --假滚
    if not _symbol.m_isLastSymbol or _symbol.p_rowIndex > self.m_iReelRowNum then
    --停轮
    else
        wildTimes = self:getReelWildTimes()
    end
    self:upDateWildTimes(_symbol, wildTimes)
end
--wild图标-刷新次数- 传入次数是服务器次数 表现次数永远+1
function CodeGameScreenCherryBountyMachine:upDateWildTimes(_symbol, _wildTimes)
    local showTimes = _wildTimes+1
    self:upDateWildSymbolSkin(_symbol, showTimes)
    _symbol:runAnim("idleframe", false)
end
--wild图标-刷新皮肤
function CodeGameScreenCherryBountyMachine:upDateWildSymbolSkin(_symbol, _showTimes)
    local animNode = _symbol:checkLoadCCbNode()
    local spine = animNode.m_spineNode or (_symbol.m_symbolType and animNode)
    local skinName = string.format("skin%d", _showTimes)
    spine:setSkin(skinName)
end
--wild图标-服务器数据
function CodeGameScreenCherryBountyMachine:getReelWildTimes()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    local wildTimes = selfData.leftTimes or 3-1
    return wildTimes
end
--重写-背景音乐切换
function CodeGameScreenCherryBountyMachine:changeReSpinBgMusic()
    self.m_rsBgMusicName = self:getCherryBountyReSpinMusic()
    CodeGameScreenCherryBountyMachine.super.changeReSpinBgMusic(self)
end
--respin玩法的音乐
function CodeGameScreenCherryBountyMachine:getCherryBountyReSpinMusic()
    local bSuper = self:isCherryBountySuperReSpin()
    if bSuper then
        return self:getReSpinMusicBg()
    else
        return self:getFreeSpinMusicBG()
    end
end
--重写-延时停轮后事件的执行
function CodeGameScreenCherryBountyMachine:reelDownNotifyPlayGameEffect()
    local delayTime = 0
    -- if self:isTriggerEFFECT_WildCollect() then
    --     delayTime = 1
    -- end
    if self:isSuperSelectBonusGame() then
        delayTime = 1
    end
    self:levelPerformWithDelay(self, delayTime,function()
        CodeGameScreenCherryBountyMachine.super.reelDownNotifyPlayGameEffect(self)
    end)
end
--重写-取消五连
function CodeGameScreenCherryBountyMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenCherryBountyMachine.super.lineLogicWinLines(self)
    return false
end
--重写-关卡适配
function CodeGameScreenCherryBountyMachine:scaleMainLayer()
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
        --适配偏移
        local scaleData = self:getMainLayerScaleDataBySize(display.width, display.height, self.m_bSuperMainLayerFlag)
        mainScale = mainScale * scaleData.offsetScale
        mainPosY  = mainPosY  + scaleData.offsetY
        --适配偏移 end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end
--关卡适配-superReSpin单独适配(仅在super的进入和退出时调用一下)
function CodeGameScreenCherryBountyMachine:upDateSuperReSpinMainLayerScale(_bSuper)
    self.m_bSuperMainLayerFlag = _bSuper
    self:scaleMainLayer()
    -- m_machineRootScale 发生了变化所有相关使用地方都在这里更新一下
    local newMachineRootScale = self.m_machineRootScale
    self.m_effectNodeDown:setScale(newMachineRootScale)
    self.m_effectNodeUp:setScale(newMachineRootScale)
end
--关卡适配-获取当前适配下弹板所用的缩放
function CodeGameScreenCherryBountyMachine:getDialogMainLayerScale()
    local scale = self.m_machineRootScale
    if self.m_bSuperMainLayerFlag then
        local scaleData = self:getMainLayerScaleDataBySize(display.width, display.height, self.m_bSuperMainLayerFlag)
        scale = scale / scaleData.offsetSuper
    end
    -- print("[CodeGameScreenCherryBountyMachine:getDialogMainLayerScale]",scale)
    return scale
end

--关卡适配-适配数据
function CodeGameScreenCherryBountyMachine:getMainLayerScaleDataBySize(_width, _height, _bSuper)
    --[[
        当前尺寸的(缩放 | 偏移) 动态向上一个尺寸缩放靠拢
        {尺寸比 scale偏移 y偏移} 列表排序必须从大到小
        1228->1370 1.2->1 -5->0
    ]]
    local scaleData = {}
    scaleData.offsetScale  = 1
    scaleData.offsetY      = 0
    scaleData.offsetSuper  = 1
    local scaleConfig = {
        {1970/768, 1,     5,  1},
        {1530/768, 1,     5,  1},
        {1370/768, 1,     5,  0.95},
        {1228/768, 1.15,  5,  0.8},
        {1152/768, 1.2,   5,  0.7},
        {920/768,  1.175, 5,  0.7},
    }
    local whRatio = _width / _height
    for _cfgIndex,_cfg in ipairs(scaleConfig) do
        if whRatio >= _cfg[1] then
            local lastCfg   = scaleConfig[_cfgIndex-1] or {}
            local lastRatio = lastCfg[1] or _cfg[1]
            local lastScale = lastCfg[2] or _cfg[2]
            local lastY     = lastCfg[3] or _cfg[3]
            local lastSuper = lastCfg[4] or _cfg[4]
            local baseRatio  = _cfg[1]
            local baseScale  = _cfg[2]
            local baseY      = _cfg[3]
            local baseSuper  = _cfg[4]
            scaleData.offsetScale = baseScale
            scaleData.offsetY     = baseY
            scaleData.offsetSuper = baseSuper
            if lastRatio ~= baseRatio then
                local progress = (whRatio-baseRatio) / (lastRatio-baseRatio)
                scaleData.offsetScale = baseScale + progress * (lastScale-baseScale)
                scaleData.offsetY     = baseY + progress * (lastY-baseY)
                scaleData.offsetSuper = baseSuper + progress * (lastSuper-baseSuper)
            end
            if _bSuper then
                scaleData.offsetScale = scaleData.offsetScale * scaleData.offsetSuper
                scaleData.offsetY     = scaleData.offsetY + scaleData.offsetY * (scaleData.offsetSuper - 1) * 0.5
            end
            local sMsg = "[CodeGameScreenCherryBountyMachine:scaleMainLayer]"
            sMsg = string.format("%s %d %d %d",sMsg,_cfgIndex,_width,_height)
            sMsg = string.format("%s %.2f %.2f %.2f",sMsg,scaleData.offsetScale,scaleData.offsetY,scaleData.offsetSuper)
            print(sMsg)
            break
        end
    end
    return scaleData
end





--工具-获取绝对坐标
function CodeGameScreenCherryBountyMachine:getCherryBountyPosReelIdx(_iRow, _iCol, _bSuperReSpin)
    if _bSuperReSpin then
        local index = (self.m_iReelRowNum - _iRow) * self.SuperReSpinCol + (_iCol - 1)
        return index
    end
    return self:getPosReelIdx(_iRow, _iCol)
end
--工具-获取行列坐标
function CodeGameScreenCherryBountyMachine:getCherryBountyRowAndColByPos(_reelPos, _bSuperReSpin)
    if _bSuperReSpin then
        local iCol = self.SuperReSpinCol
        local iRow = self.m_iReelRowNum
        local rowIndex = iRow - math.floor(_reelPos / iCol)
        local colIndex = _reelPos % iCol + 1
        return {iX = rowIndex, iY = colIndex}
    end
    return self:getRowAndColByPos(_reelPos)
end


--工具-玩法结束重置棋盘
function CodeGameScreenCherryBountyMachine:featureOverUpDateReel(_bReSpinOver)
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local reels      = bonusExtra.reels
    local wildTimes  = self:getReelWildTimes()
    self:checkChangeBaseParent()
    for _lineIndex,_lineData in ipairs(reels) do
        local iRow = self.m_iReelRowNum + 1 - _lineIndex
        for _iCol,_symbolType in ipairs(_lineData) do
            local newSymbolType = _symbolType
            local symbol = self:getFixSymbol(_iCol, iRow)
            self:changeReelSymbolType(symbol, newSymbolType)
            self:changeReelSymbolOrder(symbol)
            self:addSpineSymbolCsbNode(symbol)
            if newSymbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                self:upDateWildTimes(symbol, wildTimes)
                symbol:runAnim("idleframe2", false)
            elseif self:isCherryBountyBonus(newSymbolType) then
                local reelPos = self:getCherryBountyPosReelIdx(iRow, _iCol, false)
                local bonusData = self:getFeatureOverBonusRewardData(reelPos)
                self:upDateBonusReward(symbol, bonusData)
            end
            if self.m_symbolExpectCtr:isLoopIdleSymbol(newSymbolType) then
                self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
            end
        end
    end
    if not _bReSpinOver then
        self:resumeReelUpDateLockWild()
    end
end
--工具-根据模式切换背景卷轴
CodeGameScreenCherryBountyMachine.BgModel = {
    Base    = "base",
    Free    = "free",
    Respin5 = "respin5",
    Respin7 = "respin7",
    Bonus   = "bonus",
}
function CodeGameScreenCherryBountyMachine:changeReelBg(_model, _bAnim)
    local bBase    = self.BgModel.Base    == _model
    local bFree    = self.BgModel.Free    == _model
    local bReSpin5 = self.BgModel.Respin5 == _model
    local bReSpin7 = self.BgModel.Respin7 == _model
    local bBonus   = self.BgModel.Bonus   == _model
    
    --边框
    self:findChild("qipanbian_35"):setVisible(not bReSpin7)
    self:findChild("qipanbian_37"):setVisible(bReSpin7)
    --卷轴
    self:findChild("base_reel"):setVisible(bBase)
    self:findChild("free_reel"):setVisible(bFree)
    --线数
    self:findChild("Node_xianshu"):setVisible(not bReSpin5 and not bReSpin7)
    --顶栏中心
    self.m_jackpotBar:findChild("base_di"):setVisible(bBase)
    self.m_jackpotBar:findChild("other_di"):setVisible(not bBase)
    --背景
    --[[
        idle1对应base   
        idle2对应free和普通3X5
        idle3对应 3*7和pick
    ]]
    local bgAnimName = ""
    if bBase then
        bgAnimName = "idle1"
    elseif bFree or bReSpin5 then
        bgAnimName = "idle2"
    elseif bReSpin7 or bBonus then
        bgAnimName = "idle3"
    end
    if not _bAnim then
        util_spinePlay(self.m_spineBgUp, bgAnimName, true)
    else
        self.m_spineBgUp:runAction(cc.FadeOut:create(21/60))
        self.m_spineBgDown:setVisible(true)
        util_spinePlay(self.m_spineBgDown, bgAnimName, false)
        util_spineEndCallFunc(self.m_spineBgDown, bgAnimName, function()
            self.m_spineBgUp:stopAllActions()
            util_spinePlay(self.m_spineBgDown, bgAnimName, false)
            util_spinePlay(self.m_spineBgUp, bgAnimName, true)
            performWithDelay(self.m_spineBgUp,function()
                self.m_spineBgDown:setVisible(false)
                self.m_spineBgUp:setOpacity(255)
            end, 0.1)
        end)
    end
end
--根据选择的玩法获得背景模式
function CodeGameScreenCherryBountyMachine:getModelByResult(_result)
    local features = _result.features or {}
    local bFree    = features[2] == SLOTO_FEATURE.FEATURE_FREESPIN
    local bReSpin  = features[2] == SLOTO_FEATURE.FEATURE_RESPIN
    local sModel = self.BgModel.Bonus
    if bFree then
        sModel = self.BgModel.Free
    elseif bReSpin then
        local selfData   = _result.selfData or {}
        local selectType = selfData.kind or ""
        if "respin" == selectType then
            sModel = self.BgModel.Respin5
        else
            sModel = self.BgModel.Respin7
        end
    end
    return sModel
end
--工具-关卡延时
function CodeGameScreenCherryBountyMachine:levelPerformWithDelay(_parent, _time, _fun)
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
--工具-循环棋盘图标
function CodeGameScreenCherryBountyMachine:baseReelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol then
                fun(symbol, iCol, iRow)
            end
        end
    end
end
--工具-获取图标列表
function CodeGameScreenCherryBountyMachine:getReelSymbolList(_symbolList, _symbolType, _bSort)
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        if _symbol.p_symbolType == _symbolType then
            table.insert(_symbolList, _symbol)
        end
    end)
    if _bSort then
        table.sort(_symbolList, function(_symbolA, _symbolB)
            if _symbolA.p_cloumnIndex ~= _symbolB.p_cloumnIndex then
                return _symbolA.p_cloumnIndex < _symbolB.p_cloumnIndex
            end
            if _symbolA.p_rowIndex ~= _symbolB.p_rowIndex then
                return _symbolA.p_rowIndex > _symbolB.p_rowIndex
            end
            return false
        end)
    end
    return _symbolList
end
--工具-获取图标在第N列前的总数
function CodeGameScreenCherryBountyMachine:getReelSymbolCountByCol(_symbolType, _iCol)
    local count = 0
    local reels = self.m_runSpinResultData.p_reels or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.reels then
        reels = selfData.reels
    end
    for _lineIndex,_lineData in ipairs(reels) do
        for iCol,_symbol in ipairs(_lineData) do
            if iCol <= _iCol and _symbol == _symbolType then
                count = count + 1
            end
        end
    end
    return count
end
--工具-变更小块信号值
function CodeGameScreenCherryBountyMachine:changeReelSymbolType(_symbol, _symbolType)
    if _symbol.p_symbolType == _symbolType then
        return false
    end
    if _symbol.p_symbolImage then
        _symbol.p_symbolImage:removeFromParent()
        _symbol.p_symbolImage = nil
    end
    local ccbName = self:getSymbolCCBNameByType(self,_symbolType)
    local order = self:getBounsScatterDataZorder(_symbolType) + _symbol.p_cloumnIndex*10 - _symbol.p_rowIndex
    _symbol:changeCCBByName(ccbName, _symbolType)
    _symbol.p_showOrder  = order
    _symbol.m_showOrder  = _symbol.p_showOrder
    _symbol.p_symbolType = _symbolType
    _symbol:runAnim("idleframe", false)
    --重置一些附加表现
    return true
end
--工具-刷新图标层级
function CodeGameScreenCherryBountyMachine:changeReelSymbolOrder(_symbol, _bTop, _order)
    _symbol:stopAllActions()
    local symbolType = _symbol.p_symbolType
    if nil == _bTop then
        local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList or {}
        _bTop = nil ~= bulingAnimCfg[symbolType]
    end
    local iCol       = _symbol.p_cloumnIndex
    local iRow       = _symbol.p_rowIndex
    if _bTop then
        _order = _order or 0
        --不在棋盘的图标先恢复到棋盘上
        self:changeBaseParent(_symbol)
        util_setSymbolToClipReel(self, iCol, iRow, _symbol.p_symbolType, _order)
        --连线坐标
        local linePos = {}
        linePos[#linePos + 1] = {iX = iRow, iY = iCol}
        _symbol.m_bInLine = true
        _symbol:setLinePos(linePos)
    else
        _order = _order or self:getBounsScatterDataZorder(symbolType)
        _symbol.p_layerTag  = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        _symbol.m_showOrder = _order
        _symbol.p_showOrder = _order
        local slotParent = self.m_slotParents[iCol].slotParent
        local nodePos  = util_convertToNodeSpace(_symbol, slotParent)
        util_changeNodeParent(slotParent, _symbol, _symbol.m_showOrder)
        _symbol:setTag(_symbol.p_cloumnIndex * SYMBOL_NODE_TAG + _symbol.p_rowIndex)
        _symbol:setPosition(nodePos)
    end
end
--工具-图标触发
function CodeGameScreenCherryBountyMachine:playSymbolTrigger(_symbolType, _animName)
    _animName = _animName or "actionframe"
    local animTime = 0
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        if _symbol.p_symbolType == _symbolType then
            if _symbol:getParent() ~= self.m_clipParent then
                self:changeReelSymbolOrder(_symbol, true, nil)
            end
            _symbol:runAnim(_animName, false, function()
                self.m_symbolExpectCtr:playSymbolIdleAnim(_symbol)
            end)
            animTime = _symbol:getAniamDurationByName(_animName)
        end
    end)
    return animTime
end

--工具-粒子-播放单次
function CodeGameScreenCherryBountyMachine:playOnceParticleEffect(_particle)
    _particle:setDuration(0.5)
    _particle:setPositionType(0)
    _particle:stopSystem()
    _particle:resetSystem()
end
--工具-粒子-飞行
function CodeGameScreenCherryBountyMachine:playParticleFly(_nodeNameList, _posNode1, _posNode2, _time, _bEaseIn)
    local parent = self.m_effectNodeUp
    local startPos = util_convertToNodeSpace(_posNode1, parent)
    local endPos   = util_convertToNodeSpace(_posNode2, parent)

    local particleCsb = nil
    if #self.m_particleList1 > 0 then
        particleCsb = table.remove(self.m_particleList1, 1)
        particleCsb:setVisible(true)
    else
        particleCsb = util_createAnimation("CherryBounty_xinxiqu_pick_fly.csb")
        parent:addChild(particleCsb)
    end
    particleCsb:setPosition(startPos)

    for i,_particle in ipairs(particleCsb:findChild("root"):getChildren()) do
        local nodeName = _particle:getName()
        local bVis = false
        for ii,_name in ipairs(_nodeNameList) do
            if nodeName==_name then
                bVis = true
                break
            end
        end
        _particle:setVisible(bVis)
        if bVis then
            _particle:setPositionType(0)
            _particle:setDuration(-1)
            _particle:stopSystem()
            _particle:resetSystem()
            _particle:setOpacity(255)
        end
    end
    local actList = {}
    if _bEaseIn then
        table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(_time, endPos), 2))
    else
        table.insert(actList, cc.MoveTo:create(_time, endPos))
    end
    table.insert(actList, cc.CallFunc:create(function()
        for i,_name in ipairs(_nodeNameList) do
            local particle = particleCsb:findChild(_name)
            particle:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particle, true)
            particle:runAction(cc.FadeOut:create(0.5))
        end
    end))
    table.insert(actList,  cc.DelayTime:create(0.5))
    table.insert(actList, cc.CallFunc:create(function()
        particleCsb:setVisible(false)
        table.insert(self.m_particleList1, particleCsb)
    end))

    particleCsb:runAction(cc.Sequence:create(actList))
end


--工具-更新底栏金币(保证调用在连线事件前)
function CodeGameScreenCherryBountyMachine:updateBottomUICoins(_addCoins, isNotifyUpdateTop, _bJump, _playWinSound, _bAfterLine)
    if nil == isNotifyUpdateTop then
        local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
        isNotifyUpdateTop = not bLine and not bFree
    end

    local params = {}
    params[1] = _addCoins
    params[2] = isNotifyUpdateTop
    params[3] = _bJump
    params[4] = 0
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound

    local lastCoins     = self:getLastWinCoin()
    local spinWinCoins  = self.m_runSpinResultData.p_winAmount
    self.m_spinAddBottomCoins = math.min(spinWinCoins, self.m_spinAddBottomCoins + _addCoins)
    local tempLastCoins = lastCoins - spinWinCoins + self.m_spinAddBottomCoins
    if _bAfterLine then
        local lineWinCoins  = self:getClientWinCoins()
        tempLastCoins = math.min(lastCoins, tempLastCoins + lineWinCoins) 
    end

    self:setLastWinCoin(tempLastCoins)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    self:setLastWinCoin(lastCoins)
end
--工具-底栏反馈
function CodeGameScreenCherryBountyMachine:playTotalWinSpineAnim()
    local animName = "actionframe"
    if not self.m_totalWinSpine then
        local parent = self.m_bottomUI:getCoinWinNode()
        self.m_totalWinSpine =  util_spineCreate("CherryBounty_totalwin", true, true)
        parent:addChild(self.m_totalWinSpine)
        -- util_spineMix(self.m_totalWinSpine, animName, animName, 0.2)
    end
    self.m_totalWinSpine:stopAllActions()
    self.m_totalWinSpine:setVisible(true)
    local animTime = self.m_totalWinSpine:getAnimationDurationTime(animName)
    util_spinePlay(self.m_totalWinSpine, animName, false)
    performWithDelay(self.m_totalWinSpine,function()
        self.m_totalWinSpine:setVisible(false)
    end, animTime)
end
--工具-文本跳钱
function CodeGameScreenCherryBountyMachine:playLabelJumpCoins(_labCoins, _labInfo, _curCoins, _endCoins, _jumpTime, _bView, _fnJumpOver)
    _labCoins:stopAllActions()
    local jumpTime    = _jumpTime
    local offsetValue = _endCoins - _curCoins
    local coinRiseNum = math.floor(offsetValue / (jumpTime * 60))
    local sCoins = self:getCherryBountyLongNumString(coinRiseNum)
    sCoins = string.gsub(sCoins,"0",math.random(1, 5))
    coinRiseNum  = tonumber(sCoins)
    coinRiseNum  = math.ceil(coinRiseNum)
    local fnUpDateLabel = function(_coins)
        local sCoins = ""
        if _bView then 
            sCoins = util_formatCoins(_coins, 30)
        else
            sCoins = util_formatCoinsLN(_coins, 4)
        end
        _labCoins:setString(sCoins)
        self:upDateBonusCoinsLabelSize(_labCoins, nil, nil, _labInfo)
    end
    local fnJumpOver = _fnJumpOver or function() end
    fnUpDateLabel(_curCoins)
    schedule(_labCoins, function()
        _curCoins = math.min(_endCoins, _curCoins + coinRiseNum)
        --刷新
        fnUpDateLabel(_curCoins)
        --停止
        if _curCoins >= _endCoins then
            _labCoins:stopAllActions()
            fnJumpOver()
        end
    end,0.016)
end
--工具-特殊玩法结束检测添加大赢
function CodeGameScreenCherryBountyMachine:addBonusOverBigWinEffect(_bonusWinCoins, _effectType, _bBonus)
    if nil == _bonusWinCoins then
        local spinWinCoins  = self.m_runSpinResultData.p_winAmount or 0
        local lineWinCoins  = self:getClientWinCoins()
        _bonusWinCoins      = spinWinCoins - lineWinCoins
    end

    local bLine  = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
    local bBonus = _bBonus or _effectType >= GameEffect.EFFECT_BONUS
    local leftCount  = globalData.slotRunData.freeSpinCount
    local totalCount = globalData.slotRunData.totalFreeSpinCount
    local bFree      = self:getCurrSpinMode() == FREE_SPIN_MODE
    local bLastFree  = self.m_bProduceSlots_InFreeSpin and leftCount ~= totalCount and 0 == leftCount
    --检查添加大赢
    if not bLastFree and (not bLine or bBonus) then
        self.m_iOnceSpinLastWin = _bonusWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{_bonusWinCoins, _effectType})
        self:sortGameEffects()
    else
    end
    --刷新顶栏 
    if not bFree and (not bLine or bBonus) then
        -- jfs的玩家金额是接口返回
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end
    --刷新连线赢钱值
    if bLine then
        local lineWinCoins  = self:getClientWinCoins()
        self.m_iOnceSpinLastWin = lineWinCoins
    end
end

return CodeGameScreenCherryBountyMachine