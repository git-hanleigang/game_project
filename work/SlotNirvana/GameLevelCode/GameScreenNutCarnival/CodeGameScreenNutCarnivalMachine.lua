--[[
    玩法:
        base:
            收集wild随机触发多幅多彩
            3个以上Scatter触发free
            收集特殊bonus累计触发后的spin次数,高低bet分两档,0档锁grand
            6个以上任意类型bonus触发reSpin
        多幅多彩:
            获得任意一个jackpot玩法结束
        free:
            次数用尽玩法结束
        reSpin:
            触发图标包含任意特殊bonus时直接使用对应乘倍和次数
            触发图标无特殊bonus时,让玩家随机选择一个特殊bonus类型
            reSpin全满时触发转盘，转盘结束后如果还有次数,滚走所有固定bonus继续reSpin
            次数用尽玩法结束
]]
local PublicConfig = require "NutCarnivalPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenNutCarnivalMachine = class("CodeGameScreenNutCarnivalMachine", BaseNewReelMachine)

CodeGameScreenNutCarnivalMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenNutCarnivalMachine.SYMBOL_Bonus           = 94      --bonus-黄色(带钱 or 带jackpot)
CodeGameScreenNutCarnivalMachine.SYMBOL_SpecialBonus_1  = 202     --bonus-绿色-x2
CodeGameScreenNutCarnivalMachine.SYMBOL_SpecialBonus_2  = 203     --bonus-蓝色-x3
CodeGameScreenNutCarnivalMachine.SYMBOL_SpecialBonus_3  = 204     --bonus-紫色-x4
CodeGameScreenNutCarnivalMachine.SYMBOL_SpecialBonus_4  = 205     --bonus-红色-x5
CodeGameScreenNutCarnivalMachine.SYMBOL_Blank           = 100     --假滚中的空信号
CodeGameScreenNutCarnivalMachine.SYMBOL_Mystery         = 101     --假滚中的可变信号(普通bonus,wild,H1,H2,H3,H4,H5)

CodeGameScreenNutCarnivalMachine.EFFECT_FreeMysterySymbol  = GameEffect.EFFECT_SELF_EFFECT - 70   --free内可变图标
CodeGameScreenNutCarnivalMachine.EFFECT_CollectWild        = GameEffect.EFFECT_SELF_EFFECT - 60   --收集wild GameEffect.EFFECT_LINE_FRAME + 1
CodeGameScreenNutCarnivalMachine.EFFECT_PickGame           = GameEffect.EFFECT_LINE_FRAME + 1     --多福多彩 GameEffect.EFFECT_SELF_EFFECT - 55
CodeGameScreenNutCarnivalMachine.EFFECT_CollectBonus       = GameEffect.EFFECT_SELF_EFFECT - 50   --收集bonus

CodeGameScreenNutCarnivalMachine.ServerJackpotType = {
    Grand = "grand",
    Major = "major",
    Maxi  = "maxi",
    Minor = "minor",
    Mini  = "mini",
}
CodeGameScreenNutCarnivalMachine.JackpotTypeToIndex = {
    [CodeGameScreenNutCarnivalMachine.ServerJackpotType.Grand] = 1,
    [CodeGameScreenNutCarnivalMachine.ServerJackpotType.Major] = 2,
    [CodeGameScreenNutCarnivalMachine.ServerJackpotType.Maxi]  = 3,
    [CodeGameScreenNutCarnivalMachine.ServerJackpotType.Minor] = 4,
    [CodeGameScreenNutCarnivalMachine.ServerJackpotType.Mini]  = 5,
}

-- 构造函数
function CodeGameScreenNutCarnivalMachine:ctor()
    CodeGameScreenNutCarnivalMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
 
    --高低bet
    self.m_iBetLevel = 0
    --触发reSpin的图标类型
    self.m_reSpinType = self.SYMBOL_SpecialBonus_1
    -- 本次spin首个快滚的列
    self.m_firstReelRunCol = 0

    --init
    self:initGame()
end

function CodeGameScreenNutCarnivalMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("NutCarnivalConfig.csv", "LevelNutCarnivalCSVData.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

function CodeGameScreenNutCarnivalMachine:getModuleName()
    return "NutCarnival"  
end

function CodeGameScreenNutCarnivalMachine:initUI()
    self.m_effectNode = self:findChild("Node_effect")

    --棋盘背景光
    self.m_reelBgLight = util_createAnimation("NutCarnival_bgg.csb")
    self.m_gameBg:findChild("bonus"):addChild(self.m_reelBgLight)

    -- 奖池
    self.m_jackpotBar = util_createView("CodeNutCarnivalSrc.NutCarnivalJackPotBar", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:playIdleAnim()
    self.m_jackpotBar:playFadeAction()
    --freeBar
    self.m_freeBar = util_createView("CodeNutCarnivalSrc.NutCarnivalFree.NutCarnivalFreeSpinBar", self)
    self:findChild("Node_freespin"):addChild(self.m_freeBar)
    self.m_freeBar:setVisible(false)

    --棋盘压暗
    local reelDarkParent = self:findChild("Node_zhezhao")
    reelDarkParent:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 25)
    self.m_reelDarkCsb = util_createAnimation("NutCarnival_zhezhao.csb")
    reelDarkParent:addChild(self.m_reelDarkCsb)
    self.m_reelDarkCsb:setVisible(false)
    --多幅多彩收-预告
    self.m_yugaoAnim = util_createView("CodeNutCarnivalSrc.NutCarnivalYuGao", self)
    self:findChild("Node_yuGao"):addChild(self.m_yugaoAnim)
    self.m_yugaoAnim:setVisible(false)
    --多幅多彩收集堆
    self.m_wildCollect = util_createView("CodeNutCarnivalSrc.NutCarnivalPickGame.NutCarnivalWildCollect", self)
    self:findChild("Node_pickCollect"):addChild(self.m_wildCollect)
    local feedbackAnim = util_createAnimation("NutCarnival_fankui.csb")
    self.m_effectNode:addChild(feedbackAnim)
    feedbackAnim:setVisible(false)
    self.m_wildCollect:initFeedbackAnim(feedbackAnim)
    --多幅多彩-过场-进入
    self.m_pickGameGuoChang = util_createView("CodeNutCarnivalSrc.NutCarnivalPickGame.NutCarnivalPickGameGuoChang", self)
    self:findChild("Node_guoChang"):addChild(self.m_pickGameGuoChang)
    self.m_pickGameGuoChang:setVisible(false)
    --多幅多彩-过场-结束
    self.m_wildSpineGuoChang = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    self:findChild("Node_guoChang"):addChild(self.m_wildSpineGuoChang)
    self.m_wildSpineGuoChang:setVisible(false)
    --多幅多彩
    self.m_pickGameView = util_createView("CodeNutCarnivalSrc.NutCarnivalPickGame.NutCarnivalPickGameView", self)
    self:findChild("Node_pick"):addChild(self.m_pickGameView)
    self.m_pickGameView:setVisible(false)

    --reSpin奖池
    self.m_reSpinJackpotBar = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinJackPotBar", self)
    self:findChild("Node_jackpot"):addChild(self.m_reSpinJackpotBar)
    self.m_reSpinJackpotBar:setVisible(false)
    --reSpin收集栏
    self.m_collectBar = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinCollectBar", self)
    self:findChild("Node_respin_shouji"):addChild(self.m_collectBar)
    self.m_collectBar:playIdleAnim()
    --reSpin选择界面
    self.m_reSpinPickView = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinPickView", self)
    self:findChild("Node_choose"):addChild(self.m_reSpinPickView)
    self.m_reSpinPickView:setVisible(false)
    --reSpin乘倍展示
    self.m_reSpinMultip = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinMultip", self)
    self:findChild("Node_chenglv"):addChild(self.m_reSpinMultip)
    self.m_reSpinMultip:setVisible(false)
    --reSpin logo
    self.m_reSpinLogo = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinLogo", self)
    self:findChild("Node_logo"):addChild(self.m_reSpinLogo)
    self.m_reSpinLogo:setVisible(false)
    --reSpin 收集金币栏
    self.m_reSpinWinnerBar = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalWinnerBar", self)
    self:findChild("Node_winner"):addChild(self.m_reSpinWinnerBar)
    self.m_reSpinWinnerBar:setVisible(false)
    --reSpin计数栏
    self.m_reSpinBar = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinBar", self)
    self:findChild("Node_respin_spin"):addChild(self.m_reSpinBar)
    self.m_reSpinBar:setVisible(false)
    --reSpin全满动画
    self.m_reSpinWheelTriggerAnim = util_createAnimation("NutCarnival_respin_jiman.csb")
    self:findChild("Node_jiman"):addChild(self.m_reSpinWheelTriggerAnim)
    self.m_reSpinWheelTriggerAnim:setVisible(false)
    --reSpin全满乘倍
    self.m_reSpinMultiAnim = util_createAnimation("NutCarnival_respin_chengbei.csb")
    self:findChild("Node_chengbei"):addChild(self.m_reSpinMultiAnim)
    self.m_reSpinMultiAnim:setVisible(false)
    --reSpin全满乘倍的松鼠庆祝
    self.m_wildSpineCelebrate = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    self:findChild("Node_yuGao"):addChild(self.m_wildSpineCelebrate)
    self.m_wildSpineCelebrate:setVisible(false)

    --reSpin转盘
    self.m_reSpinWheelView = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalWheelView", self)
    self:findChild("Node_wheel_down"):addChild(self.m_reSpinWheelView)
    self.m_reSpinWheelView:setVisible(false)
    --reSpin次数增加提示
    self.m_reSpinRound = util_createView("CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalReSpinRound", self)
    self:findChild("Node_round"):addChild(self.m_reSpinRound)
    self.m_reSpinRound:setVisible(false)

    --大赢
    self.m_bigWinSpine = util_spineCreate("NutCarnival_DY",true,true)
    self:findChild("Node_bigWin"):addChild(self.m_bigWinSpine)
    self.m_bigWinSpine:setVisible(false)

    self:changeBottomBigWinLabUi("NutCarnival_bigwin_zi.csb")

    self:changeReelBg("base")
end


function CodeGameScreenNutCarnivalMachine:enterGamePlayMusic(  )
    self:playEnterGameSound(PublicConfig.sound_NutCarnival_enterLevel)
end

function CodeGameScreenNutCarnivalMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenNutCarnivalMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:updateBetLevel(true)
    self.m_reSpinWheelView:updateReward()
end
function CodeGameScreenNutCarnivalMachine:initGridList()
    CodeGameScreenNutCarnivalMachine.super.initGridList(self)
    if not self:checkHasFeature() then
        self:baseReelForeach(function(_slotsNode, _iCol, _iRow)
            if _slotsNode then
                local symbolType = _slotsNode.p_symbolType
                if self:isNutCarnivalCommonBonus(symbolType) then
                    self:addSpineSymbolCsbNode(_slotsNode)
                    self:resetBonusSymbolReward(_slotsNode)
                    self:setBonusSymbolReward(_slotsNode, 20, "")
                end
            end
        end)
    end
end
function CodeGameScreenNutCarnivalMachine:addObservers()
    CodeGameScreenNutCarnivalMachine.super.addObservers(self)
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
        local bFree     = globalData.slotRunData.currSpinMode == FREE_SPIN_MODE
        local sPrefix   = bFree and "sound_NutCarnival_freeLineFrame_" or "sound_NutCarnival_baseLineFrame_"
        local soundKey  = string.format("%s%d", sPrefix, soundIndex)
        local soundName = PublicConfig[soundKey]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenNutCarnivalMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenNutCarnivalMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenNutCarnivalMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_Bonus then
        return "Socre_NutCarnival_Bonus"
    end
    if symbolType == self.SYMBOL_SpecialBonus_1 then
        return "Socre_NutCarnival_Bonus1"
    end
    if symbolType == self.SYMBOL_SpecialBonus_2 then
        return "Socre_NutCarnival_Bonus2"
    end
    if symbolType == self.SYMBOL_SpecialBonus_3 then
        return "Socre_NutCarnival_Bonus3"
    end
    if symbolType == self.SYMBOL_SpecialBonus_4 then
        return "Socre_NutCarnival_Bonus4"
    end
    if symbolType == self.SYMBOL_Mystery then
        return "Socre_NutCarnival_Mystery"
    end
    if symbolType == self.SYMBOL_Blank then
        return "Socre_NutCarnival_Blank"
    end


    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenNutCarnivalMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenNutCarnivalMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end
function CodeGameScreenNutCarnivalMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


-- 断线重连 
function CodeGameScreenNutCarnivalMachine:initGameStatusData(gameData)
    CodeGameScreenNutCarnivalMachine.super.initGameStatusData(self, gameData)

    if gameData.gameConfig then
        local extra = gameData.gameConfig.extra
        if nil ~= extra then
            self.m_wildCollect:initCollectData(extra.pickIcons)
            self.m_wildCollect:setCollectCount(extra.wildTotal or 0)
            self.m_wildCollect:playIdleAnim()
            --reSpin收集栏数据
            local linkConfig = extra.linkConfig or {}
            self.m_collectBar:setReSpinTemplateCollectData(linkConfig)
            --reSpin转盘数据
            local wheelCfg = {"1","2","3","major", "1","2","3","maxi", "1","2","3","grand"}
            if nil ~= extra.wheelConfig then
                wheelCfg = extra.wheelConfig
            end
            self.m_reSpinWheelView:setWheelConfig(wheelCfg)
        end
        --reSpin收集栏数据
        local betData = gameData.gameConfig.bets or {}
        for _sBetValue,_collectData in pairs(betData) do
            self.m_collectBar:setReSpinCollectCount(tonumber(_sBetValue), _collectData)
        end
    end

    

end
function CodeGameScreenNutCarnivalMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin then
        if globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
            --切换展示
            self.m_freeBar:changeFreeSpinByCount()
            self.m_freeBar:setVisible(true)
            self.m_freeBar:playStartAnim()
            self:changeReelBg("free", true)
        end
    end
end

--[[
    高低bet
]]
function CodeGameScreenNutCarnivalMachine:updateBetLevel(_bOnEnter)
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = self:getBetLevel(betCoin)
    local curLockStatus = self.m_iBetLevel < 1
    local newLockStatus = level < 1
    local bChange       = curLockStatus ~= newLockStatus
    self.m_iBetLevel = level
    --锁定状态发生变更刷新UI
    if _bOnEnter or bChange then
        self:lockStatusChangeUpDateUi(newLockStatus)
    end
    --bet档位变化刷新次数
    self.m_collectBar:updateAllCollectCount(not _bOnEnter)
end
function CodeGameScreenNutCarnivalMachine:getBetLevel(_betValue)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betLevel = 0
    for index = #specialBets,1,-1 do
        if _betValue >= specialBets[index].p_totalBetValue then
            betLevel = index
            break
        end
    end
    return betLevel
end
--@_newLockStatus : 新的锁定状态(是否锁定)
function CodeGameScreenNutCarnivalMachine:lockStatusChangeUpDateUi(_newLockStatus)
    --锁定
    if _newLockStatus then
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_jackpotBarLock)
        self.m_jackpotBar:playLockEffect()
    --解锁 
    else
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_jackpotBarUnLock)
        self.m_jackpotBar:playUnLockEffect()
    end
end
function CodeGameScreenNutCarnivalMachine:getCurLockState()
    return self.m_iBetLevel < 1
end
----------------------------- 玩法处理 -----------------------------------
--[[
    背景切换
]]
function CodeGameScreenNutCarnivalMachine:changeReelBg(_model, _playAnim)
    local bBase   = "base"   == _model
    local bFree   = "free"   == _model
    local bReSpin = "reSpin" == _model
    local bBonus  = "bonus"  == _model

    if _playAnim then
        --卷轴
        self:findChild("Node_base_reel"):setVisible(bBase)
        self:findChild("Node_fg_reel"):setVisible(bFree)
        self:findChild("Node_respin_reel"):setVisible(bReSpin)
        self:findChild("Node_respin"):setVisible(bReSpin)
        --边框
        self:findChild("Node_kuang_base"):setVisible(bBase or bReSpin)
        self:findChild("Node_kuang_fg"):setVisible(bFree)
        --背景
        self.m_gameBg:findChild("base"):setVisible(bBase)
        self.m_gameBg:findChild("free"):setVisible(bFree)
        self.m_gameBg:findChild("bonus"):setVisible(bBonus or bReSpin)
        self:findChild("sp_reSpinReelBg"):setVisible(bReSpin)
        util_setCsbVisible(self.m_reelBgLight, bBonus or bReSpin)
        if self.m_reelBgLight:isVisible() then
            self.m_reelBgLight:runCsbAction("idleframe", true)
        end
    else
        --卷轴
        self:findChild("Node_base_reel"):setVisible(bBase)
        self:findChild("Node_fg_reel"):setVisible(bFree)
        self:findChild("Node_respin_reel"):setVisible(bReSpin)
        self:findChild("Node_respin"):setVisible(bReSpin)
        --边框
        self:findChild("Node_kuang_base"):setVisible(bBase or bReSpin)
        self:findChild("Node_kuang_fg"):setVisible(bFree)
        --背景
        self.m_gameBg:findChild("base"):setVisible(bBase)
        self.m_gameBg:findChild("free"):setVisible(bFree)
        self.m_gameBg:findChild("bonus"):setVisible(bBonus or bReSpin)
        self:findChild("sp_reSpinReelBg"):setVisible(bReSpin)
        util_setCsbVisible(self.m_reelBgLight, bBonus or bReSpin)
        if self.m_reelBgLight:isVisible() then
            self.m_reelBgLight:runCsbAction("idleframe", true)
        end
    end
end

---------------------------------------------------------------------------
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenNutCarnivalMachine:MachineRule_SpinBtnCall()
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume()
    -- 重置一些标记
    self.m_firstReelRunCol = 0



    return false -- 用作延时点击spin调用
end

-- 刷新小块
function CodeGameScreenNutCarnivalMachine:updateReelGridNode(_symbolNode)
    self:addSpineSymbolCsbNode(_symbolNode)
    self:updateBonusSymbol(_symbolNode)
    self:updateFreeMysterySymbol(_symbolNode)
end
function CodeGameScreenNutCarnivalMachine:addSpineSymbolCsbNode(_symbolNode)
    -- 默认一个spine上面最多有一个插槽可以挂cocos工程,存放的变量名称保持一致
    local symbolType = _symbolNode.p_symbolType or _symbolNode.m_symbolType
    local bindNodeCfg = {
        [self.SYMBOL_Bonus]             = {csbName = "NutCarnival_BonusLab.csb",  slotName = "shuzi"},
        [self.SYMBOL_SpecialBonus_1]    = {csbName = "NutCarnival_BonusLab.csb",  slotName = "shuzi"},
        [self.SYMBOL_SpecialBonus_2]    = {csbName = "NutCarnival_BonusLab.csb",  slotName = "shuzi"},
        [self.SYMBOL_SpecialBonus_3]    = {csbName = "NutCarnival_BonusLab.csb",  slotName = "shuzi"},
        [self.SYMBOL_SpecialBonus_4]    = {csbName = "NutCarnival_BonusLab.csb",  slotName = "shuzi"},
    } 
    local symbolCfg = bindNodeCfg[symbolType]
    if not symbolCfg then
        return
    end
    if _symbolNode.p_symbolImage then
        _symbolNode.p_symbolImage:removeFromParent()
        _symbolNode.p_symbolImage = nil
    end

    local animNode = _symbolNode:checkLoadCCbNode()
    if not animNode.m_slotCsb then
        -- 标准小块用的spine是 animNode.m_spineNode, 临时小块的spine直接是 animNode
        local spineNode = animNode.m_spineNode or (_symbolNode.m_symbolType and animNode) 
        animNode.m_slotCsb = util_createAnimation(symbolCfg.csbName)
        util_spinePushBindNode(spineNode, symbolCfg.slotName, animNode.m_slotCsb)
    end
end
function CodeGameScreenNutCarnivalMachine:resetBonusSymbolReward(_symbolNode)
    local symbolType = _symbolNode.p_symbolType or _symbolNode.m_symbolType
    if not self:isNutCarnivalBonus(symbolType) then
        return
    end
    local ccbNode = _symbolNode:getCCBNode()
    if not ccbNode then
        return
    end
    local slotCsb = ccbNode.m_slotCsb
    slotCsb:findChild("major"):setVisible(false)
    slotCsb:findChild("maxi"):setVisible(false)
    slotCsb:findChild("minor"):setVisible(false)
    slotCsb:findChild("mini"):setVisible(false)
    slotCsb:findChild("m_lb_multi"):setString("")
    slotCsb:findChild("m_lb_coins"):setString("")
end
function CodeGameScreenNutCarnivalMachine:updateBonusSymbol(_symbolNode)
    local symbolType = _symbolNode.p_symbolType or _symbolNode.m_symbolType
    if not self:isNutCarnivalBonus(symbolType) then
        return
    end
    --重置奖励
    self:resetBonusSymbolReward(_symbolNode)

    local multi,multiType = 0,""
    if not _symbolNode.m_isLastSymbol or  _symbolNode.p_rowIndex > self.m_iReelRowNum then
        multi = self.m_configData:getReSpinSymbolRandomMulti()
    else
        local reelPos = self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex)
        multi,multiType = self:getReSpinSymbolReward(reelPos)
    end
    self:setBonusSymbolReward(_symbolNode, multi, multiType)
end
function CodeGameScreenNutCarnivalMachine:setBonusSymbolReward(_symbolNode, _multi, _multiType)
    local ccbNode = _symbolNode:getCCBNode()
    local slotCsb = ccbNode.m_slotCsb

    if 0 ~= _multi then
        local curBet   = globalData.slotRunData:getCurTotalBet()
        local sCoins   = util_formatCoins(curBet * _multi, 3)
        local labCoins = slotCsb:findChild("m_lb_coins")
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins, sx=1, sy=1}, 141)
    end
    if "" ~= _multiType then
        local jackpotNode = slotCsb:findChild(string.lower(_multiType))
        jackpotNode:setVisible(true)
    end
end
function CodeGameScreenNutCarnivalMachine:getReSpinSymbolReward(_reelPos)
    local multi,multiType = 0,""
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    for k, v in ipairs(storedIcons) do
        if v[1] == _reelPos then
            multi     = not v[3] and tonumber(v[2]) or 0
            multiType = v[3] and v[3] or "" 
            return multi,multiType
        end
    end
    return multi,multiType
end
--free的可变信号滚动
function CodeGameScreenNutCarnivalMachine:updateFreeMysterySymbol(_symbolNode)
    --不是free滚动
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        return
    end
    if not _symbolNode.m_isLastSymbol or  _symbolNode.p_rowIndex > self.m_iReelRowNum then
        return
    end
    -- 滚轮转动
    if self:getGameSpinStage( ) == IDLE or self:getCurrSpinMode() == NORMAL_SPIN_MODE then
        return false
    end


    --
    local reelPos      = self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex)
    local symbolType   = self:getFreeMysterySymbolType(reelPos)
    if not symbolType then
        return
    end

    self:changeNutCarnivalSymbolType(_symbolNode, self.SYMBOL_Mystery)

    --层级
    local symbolOrder = self:getBounsScatterDataZorder(symbolType)
    local showOrder = symbolOrder + _symbolNode.p_cloumnIndex * 10 - _symbolNode.p_rowIndex
    _symbolNode.p_showOrder = showOrder
    _symbolNode.m_showOrder = showOrder
    _symbolNode:setLocalZOrder(showOrder)
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenNutCarnivalMachine:addSelfEffect()
    if self:isTriggerCollectWild() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType  = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_CollectWild
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_CollectWild
    end
    if self:isTriggerPickGame() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType  = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_PickGame
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_PickGame
    end
    if self:isTriggerCollectBonus() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType  = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_CollectBonus
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_CollectBonus
    end
    if self:isTriggerFreeMystery() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType  = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_FreeMysterySymbol
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_FreeMysterySymbol
    end

    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenNutCarnivalMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_CollectWild then
        self:playEffect_CollectWild(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_PickGame then
        local delayTime = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and 1.1 or 0
        self:levelPerformWithDelay(self, delayTime, function()
            self:playEffect_PickGame(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_CollectBonus then
        self:playEffect_CollectBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_FreeMysterySymbol then
        self:playEffect_FreeMystery(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

--[[
    收集wild
]]
function CodeGameScreenNutCarnivalMachine:isTriggerCollectWild()
    local reels = self.m_runSpinResultData.p_reels or {}
    for _lineIndex,_lineData in ipairs(reels) do
        for _iCol,_symbolType in ipairs(_lineData) do
            if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                return true
            end
        end
    end
    return false
end
function CodeGameScreenNutCarnivalMachine:playEffect_CollectWild(_fun)
    local wildList    = {}
    local flyWildList = {}
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_wild_collect)
    --收集动画
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node and _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            --提前创建
            local startPos = util_convertToNodeSpace(_node, self.m_effectNode)
            local flyCsb = util_createAnimation("NutCarnival_wildCollect.csb")
            self.m_effectNode:addChild(flyCsb)
            flyCsb:setPosition(startPos)
            flyCsb:setVisible(false)
            table.insert(flyWildList, flyCsb)
            -- 0~24
            _node:runAnim("shouji", false)
            table.insert(wildList, _node)
        end
    end)
    --花生
    self:levelPerformWithDelay(self, 1/60, function()
        local flyTime = 0.5
        local endPos = util_convertToNodeSpace(self.m_wildCollect, self.m_effectNode)
        for i,_wildSymbol in ipairs(wildList) do
            local startPos = util_convertToNodeSpace(_wildSymbol, self.m_effectNode)
            local flyCsb = flyWildList[i]
            flyCsb:setVisible(true)
            --收集飞行
            local actList = {}
            if 3 ~= _wildSymbol.p_cloumnIndex then
                local distance    = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
                local radius      = distance/2
                local flyAngle    = util_getAngleByPos(startPos, endPos)
                local offsetAngle = endPos.x > startPos.x and 90 or -90
                local pos1 = cc.p( util_getCirclePointPos(startPos.x, startPos.y, radius, flyAngle + offsetAngle) )
                local pos2 = cc.p( util_getCirclePointPos(endPos.x, endPos.y, radius/2, flyAngle + offsetAngle) )
                table.insert(actList, cc.EaseOut:create(cc.BezierTo:create(flyTime, {pos1, pos2, endPos}), 4))
                -- table.insert(actList, cc.EaseIn:create(cc.BezierTo:create(flyTime, {pos1, pos2, endPos}), 4))
            else
                table.insert(actList, cc.EaseOut:create(cc.MoveTo:create(flyTime, endPos), 4))
                -- table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(flyTime, endPos), 4))
            end
            table.insert(actList, cc.RemoveSelf:create())
            flyCsb:runAction(cc.Sequence:create(actList))
        end
        --没触发 不等待收集时间
        local bTrigger = self:checkHasNutCarnivalSelfEffect(self.EFFECT_PickGame) or self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        if not bTrigger then
            _fun()
        else
            self:levelPerformWithDelay(self, 24/30, _fun)
        end

        local selfData     = self.m_runSpinResultData.p_selfMakeData
        local collectCount = selfData.wildTotal or 0
        if self:checkHasNutCarnivalSelfEffect(self.EFFECT_PickGame) then
            collectCount = self.m_wildCollect:getCollectCountByLevel(3)
        end
        local curCollectLevel = self.m_wildCollect:getCollectLevel(self.m_wildCollect.m_collectCount) 
        local newCollectLevel = self.m_wildCollect:getCollectLevel(collectCount) 
        self:levelPerformWithDelay(self, flyTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_wild_collectOver)
            --收集反馈
            self.m_wildCollect:playCollectAnim(function()
                self.m_wildCollect:setCollectCount(collectCount)
                --升级
                self.m_wildCollect:playUpGradeAnim(curCollectLevel, newCollectLevel, function()
                    self.m_wildCollect:playIdleAnim()
                end)
            end)
        end)
    end)
end
--[[
    多幅多彩
]]
function CodeGameScreenNutCarnivalMachine:isTriggerPickGame()
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    if nil ~= selfData.jackpotGame then
        return true
    end
    return false
end
function CodeGameScreenNutCarnivalMachine:playEffect_PickGame(_fun)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "pickFeature")
    end
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_start)
    self.m_pickGameGuoChang:playGuoChangAnim(
        function()
            self.m_pickGameView:resetUi()
            self.m_pickGameView:setVisible(true)
            --切换bonus
            self:findChild("Node_qipan"):setVisible(false)
            self.m_collectBar:setVisible(false)
            self.m_jackpotBar:setVisible(false)
            self.m_wildCollect:setVisible(false)
            self:changeReelBg("bonus", true)
        end,
        function()
            -- 重置背景音乐
            self:resetMusicBg(nil, PublicConfig.music_NutCarnival_bonus)
            self:setMaxMusicBGVolume()
            local bonusData = self:getPickGameData()
            self.m_pickGameView:startGame(bonusData, function()
                --奖池弹板
                local jpIndex = self.JackpotTypeToIndex[bonusData.award.name]
                local jpWinCoins = bonusData.award.coins
                self:showJackpotView(jpIndex, jpWinCoins, 1,function()
                    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_pickGame_over)
                    --结束过场
                    self.m_wildSpineGuoChang:playBonusGameOverGuoChangAnim(
                        function()
                            if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
                                self:resetMusicBg(nil, "NutCarnivalSounds/music_NutCarnival_free.mp3")
                                self:changeReelBg("free", true)
                            else
                                self:resetMusicBg(nil, "NutCarnivalSounds/music_NutCarnival_base.mp3")
                                self:changeReelBg("base", true)
                            end
                            --切换展示
                            self.m_wildCollect:setCollectCount(0)
                            self.m_wildCollect:playIdleAnim()
                            self:findChild("Node_qipan"):setVisible(true)
                            self.m_collectBar:setVisible(true)
                            self.m_jackpotBar:setVisible(true)
                            self.m_wildCollect:setVisible(true)
                            self.m_pickGameView:setVisible(false)
                            --检查大赢
                            if not self:isLastFreeSpin() and not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                                self.m_iOnceSpinLastWin = jpWinCoins
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{jpWinCoins, self.EFFECT_PickGame})
                                self:sortGameEffects()
                            else
                                local lineWinCoins  = self:getClientWinCoins()
                                self.m_iOnceSpinLastWin = jpWinCoins + lineWinCoins
                            end
                            --刷新顶栏
                            local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
                            if not bFree then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            end
                        end,
                        function()
                            _fun()
                        end
                    )
                end)
                -- 刷新底栏
                local bottomWinCoin = self:getCurBottomWinCoins()
                self:setLastWinCoin(bottomWinCoin + jpWinCoins)
                self:updateBottomUICoins(0, jpWinCoins, nil, true, false)
            end)
        end
    )                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
end
--处理一下数据
function CodeGameScreenNutCarnivalMachine:getPickGameData()
    local bonusData = {}
    local selfData    = self.m_runSpinResultData.p_selfMakeData
    local jackpotGame = selfData.jackpotGame
    bonusData.index        = 1
    bonusData.process      = clone(jackpotGame.jackpotIcons)
    bonusData.extraProcess = {}
    bonusData.award        = {
        name  = jackpotGame.hit,
        coins = jackpotGame.coins
    }

    local tempExtraProcess = {}
    for _times=1,3 do
        for k,_jpType in pairs(self.ServerJackpotType) do
            table.insert(tempExtraProcess, _jpType)
        end
    end
    for _processIndex,jpType in ipairs(bonusData.process) do
        for _extraProcessIndex,_jpType in ipairs(tempExtraProcess) do
            if jpType == _jpType then
                table.remove(tempExtraProcess, _extraProcessIndex)
                break
            end
        end
    end
    while #tempExtraProcess > 0 do
        local jpType = table.remove(tempExtraProcess, math.random(1, #tempExtraProcess))
        table.insert(bonusData.extraProcess, jpType)
    end
    
    return bonusData
end
-- 展示jackpot弹板
function CodeGameScreenNutCarnivalMachine:showJackpotView(_jpIndex, _winCoins, _multip,_fun)
    local soundKey  = string.format("sound_NutCarnival_jackpotView_%d", _jpIndex)
    local soundName =  PublicConfig[soundKey]
    gLobalSoundManager:playSound(soundName)
    --通知jackpot
    local jackPotWinView = util_createView("CodeNutCarnivalSrc.NutCarnivalJackPotWinView", {})
    --弹板音效
    jackPotWinView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_jackpotView_over)
    end)
    jackPotWinView:setOverAniRunFunc(function()
        _fun()
    end)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData({
        coins   = _winCoins,
        index   = _jpIndex,
        multip  = _multip,
        machine = self,
    })
end

--[[
    FreeSpin相关
]]
-- 显示free spin
function CodeGameScreenNutCarnivalMachine:showEffect_FreeSpin(effectData)
    --触发动画
    for i,_lineValue in ipairs(self.m_reelResultLines) do
        if _lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            table.remove(self.m_reelResultLines, i)
            break
        end
    end
    CodeGameScreenNutCarnivalMachine.super.showEffect_FreeSpin(self, effectData)
    return true
end
function CodeGameScreenNutCarnivalMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeStartView_start)
            local freeStartView = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeStartGuoChang)
                self.m_wildSpineGuoChang:playFreeStartGuoChang(
                    function()
                        --切换free
                        self.m_freeBar:changeFreeSpinByCount()
                        
                        self:changeReelBg("free", true)
                    end,
                    function()
                        self.m_freeBar:setVisible(true)
                        self.m_freeBar:playStartAnim()


                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()   
                    end
                )
            end)
            self:updateFreeStartView(freeStartView)
        end
    end

    self:playFreeTriggerAnim(function()
        showFSView()
    end)
end
function CodeGameScreenNutCarnivalMachine:playFreeTriggerAnim(_fun)
    --停止连线音效
    self:stopLinesWinSound()
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_scatter_trigger)
    --触发动画
    local animName  = "actionframe"
    local delayTime = 0
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            if _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                --断线重连时提层
                if self.m_clipParent ~= _node:getParent() then
                    util_setSymbolToClipReel(self,_node.p_cloumnIndex, _node.p_rowIndex, _node.p_symbolType, 0)
                end
                _node:runAnim(animName, false)
                delayTime = _node:getAniamDurationByName(animName)
            elseif self:isNutCarnivalBonus(_node.p_symbolType) or _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                self:putSymbolBackToPreParent(_node)
            end
        end
    end)
    --压暗
    self.m_reelDarkCsb:setVisible(true)
    self.m_reelDarkCsb:runCsbAction("start", false)

    self:levelPerformWithDelay(self, delayTime, function()
        self.m_reelDarkCsb:runCsbAction("over", false, function()
            self.m_reelDarkCsb:setVisible(false)
        end)

        self:levelPerformWithDelay(self, 0.5, _fun)
    end)
end
function CodeGameScreenNutCarnivalMachine:updateFreeStartView(_freeStartView)
    --spine叶子
    local spineYezi    = util_spineCreate("NutCarnival_FreeSpinStart_qian", true, true)
    _freeStartView:findChild("Node_yezi"):addChild(spineYezi)
    util_spinePlay(spineYezi, "idle", true)
    local spineYezi2    = util_spineCreate("NutCarnival_FreeSpinStart_hou", true, true)
    _freeStartView:findChild("Node_di"):addChild(spineYezi2)
    util_spinePlay(spineYezi2, "idle", true)
    --spine角色
    local roleSpine = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    _freeStartView:findChild("Node_juese"):addChild(roleSpine)
    roleSpine:playFreeStartAnim()
    --弹板音效
    _freeStartView.m_btnTouchSound = PublicConfig.sound_NutCarnival_commonClick
    _freeStartView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeStartView_over)
    end)
end

function CodeGameScreenNutCarnivalMachine:showFreeSpinOverView()
    local fsCount    = self.m_runSpinResultData.p_freeSpinsTotalCount
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    local strCoins   = util_formatCoins(fsWinCoins, 30)
    local fnNext = function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeOverGuoChang)
        self.m_wildSpineGuoChang:playFreeOverGuoChangAnim(
            function()
                --切换展示
                self.m_freeBar:changeFreeSpinByCount()
                self.m_freeBar:setVisible(false)
                self:changeReelBg("base", true)
            end,
            function()
                self:triggerFreeSpinOverCallFun()
            end
        )
    end

    local freeOverView = nil
    if fsWinCoins > 0 then
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeOverView_start)
        freeOverView = self:showFreeSpinOver(strCoins, fsCount, fnNext)
        local node=freeOverView:findChild("m_lb_coins")
        freeOverView:updateLabelSize({label=node,sx=1,sy=1}, 655)
        --spine角色
        local roleSpineUp = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
        freeOverView:findChild("Node_qian"):addChild(roleSpineUp)
        roleSpineUp:playFreeOverUpAnim()
        local roleSpineDown = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
        freeOverView:findChild("Node_hou"):addChild(roleSpineDown)
        roleSpineDown:playFreeOverDownAnim()
        --弹板音效
        freeOverView:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeOverView_over)
        end)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeNotWinView_start)
        freeOverView = self:showFreeSpinNoWin(strCoins, fsCount, fnNext)
        --弹板音效
        freeOverView:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_freeNotWinView_over)
        end)
    end
    --spine叶子
    local spineYezi    = util_spineCreate("Socre_NutCarnival_tbbj", true, true)
    freeOverView:findChild("Node_yezi"):addChild(spineYezi)
    util_spinePlay(spineYezi, "idle_yezi", true)
    --弹板音效
    freeOverView.m_btnTouchSound = PublicConfig.sound_NutCarnival_commonClick
end
function CodeGameScreenNutCarnivalMachine:showFreeSpinNoWin(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    return self:showDialog("FreeSpinOver1", ownerlist, func)
end

--[[
    free可变图标
]]
function CodeGameScreenNutCarnivalMachine:isTriggerFreeMystery()
    local fsExtraData  = self.m_runSpinResultData.p_fsExtraData or {}
    local mysteryPoses = fsExtraData.mysteryPoses or {}
    if #mysteryPoses > 0 then
        return true
    end

    return false
end
function CodeGameScreenNutCarnivalMachine:playEffect_FreeMystery(_fun)
    
    local parent = self:findChild("Node_mysterySymbol")
    local fsExtraData  = self.m_runSpinResultData.p_fsExtraData
    local mysteryPoses = fsExtraData.mysteryPoses
    local bonusCount   = 0
    local mysteryCount = #mysteryPoses
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node and self:isNutCarnivalBonus(_node.p_symbolType) then
            bonusCount = bonusCount + 1
        end
    end)
    --区分有无概率触发respin的时间线
    local animName  = "actionframe"
    local delayTime = 3/30 
    if bonusCount + mysteryCount >= 6 then
        animName  = "actionframe2"
        delayTime = 21/30 
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_mystery_trigger_2)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_mystery_trigger)
    end
    for _index,_reelPos in ipairs(mysteryPoses) do
        local fixPos     = self:getRowAndColByPos(_reelPos)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local symbolType = self:getSymbolTypeForNetData(fixPos.iY, fixPos.iX)
        --开门图标
        local mysterySymbol = util_createView("CodeNutCarnivalSrc.NutCarnivalTempSymbol", {machine = self})
	    mysterySymbol:changeSymbolCcb(self.SYMBOL_Mystery)
        local order = fixPos.iY * 10 - fixPos.iX
        parent:addChild(mysterySymbol, order)
        mysterySymbol:setPosition(util_getConvertNodePos(symbolNode, parent))
        mysterySymbol:runAnim(animName, false, function()
            mysterySymbol:removeTempSlotsNode()
        end)
        --
        self:levelPerformWithDelay(self, delayTime, function()
            self:changeNutCarnivalSymbolType(symbolNode, symbolType)
            if self:isNutCarnivalBonus(symbolType) then
                self:addSpineSymbolCsbNode(symbolNode)
                self:updateBonusSymbol(symbolNode)
                symbolNode:runAnim("kaimen", false)
            end
        end)
    end

    self:levelPerformWithDelay(self, delayTime + 24/30, _fun)
end
function CodeGameScreenNutCarnivalMachine:getFreeMysterySymbolType(_reelPos)
    local fsExtraData  = self.m_runSpinResultData.p_fsExtraData or {}
    local mysteryPoses = fsExtraData.mysteryPoses or {}
    for _index,_pos in ipairs(mysteryPoses) do
        if _pos == _reelPos then
            local fixPos = self:getRowAndColByPos(_reelPos)
            local symbolType = self:getSymbolTypeForNetData(fixPos.iY, fixPos.iX)
            return symbolType
        end
    end

    return nil
end

--[[
    收集bonus
]]
function CodeGameScreenNutCarnivalMachine:isTriggerCollectBonus()
    local reels = self.m_runSpinResultData.p_reels or {}
    for _lineIndex,_lineData in ipairs(reels) do
        for _iCol,_symbolType in ipairs(_lineData) do
            if self:isNutCarnivalSpecialBonus(_symbolType) then
                return true
            end
        end
    end

    return false
end
function CodeGameScreenNutCarnivalMachine:playEffect_CollectBonus(_fun)
    local curBet   = globalData.slotRunData:getCurTotalBet()
    --没触发玩法时不等待收集时间
    local bTrigger = self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    if not bTrigger then
        _fun()
    end

    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonus_fly)
    local symbolList      = {}
    --[[
        collectDataList = {
            [信号] = 新增数量
        }
    ]]
    local collectDataList = {} 
    --收集动画
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node and self:isNutCarnivalSpecialBonus(_node.p_symbolType) then
            table.insert(symbolList, _node)
            if not collectDataList[_node.p_symbolType] then
                collectDataList[_node.p_symbolType] = 1
            else
                collectDataList[_node.p_symbolType] = collectDataList[_node.p_symbolType] + 1
            end
        end
    end)

    self:levelPerformWithDelay(self, 6/30, function()
        local flyTime = 12/30
        for i,_symbolNode in ipairs(symbolList) do
            local startPos = util_convertToNodeSpace(_symbolNode, self.m_effectNode)
            local endWorldPos = self.m_collectBar:getCollectFlyEndPos(_symbolNode.p_symbolType)
            local endPos   = self.m_effectNode:convertToNodeSpace(endWorldPos)
            --飞行bonus
            local flyBonus = util_createView("CodeNutCarnivalSrc.NutCarnivalTempSymbol", {machine = self})
            flyBonus:changeSymbolCcb(_symbolNode.p_symbolType)
            self.m_effectNode:addChild(flyBonus)
            flyBonus:setPosition(startPos)
            --刷新奖励
            flyBonus.m_isLastSymbol = true
            flyBonus.p_rowIndex     = _symbolNode.p_rowIndex
            flyBonus.p_cloumnIndex  = _symbolNode.p_cloumnIndex
            self:addSpineSymbolCsbNode(flyBonus)
            self:updateBonusSymbol(flyBonus)
            local actList = {}
            table.insert(actList, cc.MoveTo:create(flyTime, endPos))
            table.insert(actList, cc.RemoveSelf:create())
            flyBonus:runAnim("jiesuan2", false)
            flyBonus:runAction(cc.Sequence:create(actList))
        end
        self:levelPerformWithDelay(self, flyTime, function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonus_flyOver)
            --收集反馈
            self.m_collectBar:playCollectFeedbackAnim(curBet, collectDataList, function()
                if bTrigger then
                    _fun()
                end
            end)
            
        end)
    end)
end
--[[
    reSpin玩法
]]
function CodeGameScreenNutCarnivalMachine:showRespinView()
    --初始化reSpin数据
    local rsExtraData  = self.m_runSpinResultData.p_rsExtraData
    self.m_reSpinType  = tonumber(rsExtraData.triggerSignal)
    --清空底栏
    if not self.m_bProduceSlots_InFreeSpin then
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:checkClearWinLabel()
    end
    --图标触发
    self:playReSpinSymbolActionframe(function()
        --选择界面
        self:playReSpinPickView(function()
            --构造盘面数据
            local randomTypes = self:getRespinRandomTypes()
            local endTypes = self:getRespinLockTypes()
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end)
    end)
end
function CodeGameScreenNutCarnivalMachine:playReSpinSymbolActionframe(_fun)
    self:clearCurMusicBg()
    self:stopLinesWinSound()
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonus_trigger)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pickIndex   = selfData.pickIndex
    local pickSignals = selfData.pickSignals
    local bTriggerReSpinPick = nil ~= pickIndex and nil ~= pickSignals 
    --图标触发
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            if self:isNutCarnivalBonus(_node.p_symbolType) then
                --断线重连时提层
                if self.m_clipParent ~= _node:getParent() then
                    util_setSymbolToClipReel(self,_node.p_cloumnIndex, _node.p_rowIndex, _node.p_symbolType, 0)
                end
                --触发后层级回到棋盘内
                _node:runAnim("actionframe", false, function()
                    self:putSymbolBackToPreParent(_node)
                    self:playSymbolIdleLoopAnim(_node)
                end)
            elseif _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                self:putSymbolBackToPreParent(_node)
            end
        end
    end)
    --收集栏触发
    if not bTriggerReSpinPick then
        self.m_collectBar:playTriggerAnim(self.m_reSpinType, nil)
    end
    local delayTime = 2 + 0.5
    self:levelPerformWithDelay(self, delayTime, _fun)
end
function CodeGameScreenNutCarnivalMachine:playReSpinPickView(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pickIndex   = selfData.pickIndex
    local pickSignals = selfData.pickSignals
    local bTriggerReSpinPick = nil ~= pickIndex and nil ~= pickSignals 
    if not bTriggerReSpinPick then
        _fun()
        return
    end
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinPick_start)
    local reSpinPickData = {}
    reSpinPickData.extraProcess = clone(pickSignals)
    --随机补充
    while (#reSpinPickData.extraProcess) < (5-1) do
        table.insert(reSpinPickData.extraProcess, pickSignals[math.random(1, #pickSignals)])
    end
    reSpinPickData.symbolType  = self.m_reSpinType
    self.m_reSpinPickView:resetPickItem()
    self.m_reSpinPickView:setVisible(true)
    self.m_reSpinPickView:startGame(reSpinPickData, function()
        _fun()
    end)
end
--respin盘面改为到过场时再切
function CodeGameScreenNutCarnivalMachine:initRespinView(endTypes, randomTypes)
    self.m_respinView:setVisible(false)
    CodeGameScreenNutCarnivalMachine.super.initRespinView(self, endTypes, randomTypes)
end
function CodeGameScreenNutCarnivalMachine:setReelSlotsNodeVisible(status)
    -- CodeGameScreenNutCarnivalMachine.super.setReelSlotsNodeVisible(self, status)
end
function CodeGameScreenNutCarnivalMachine:setNutCarnivalReelSlotsNodeVisible(_bStatus)
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            _node:setVisible(true == _bStatus)
        end
    end)
end
function CodeGameScreenNutCarnivalMachine:showReSpinStart(func)
    local fnNext = function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinGuoChang)
        -- 重置背景音乐
        self:resetMusicBg(nil, PublicConfig.music_NutCarnival_reSpin)
        self:setMaxMusicBGVolume()
        self.m_wildSpineGuoChang:playReSpinGuoChangAnim(
            function()
                --切换reSpin
                local curLock = self:getCurLockState()
                self.m_reSpinWheelView:setGrandLockState(curLock)
                self.m_reSpinWheelView:playNormalIdleAnim()
                self.m_reSpinWheelView:setVisible(true)
                self.m_reSpinMultip:setType(self.m_reSpinType)
                self.m_reSpinMultip:playIdleAnim()
                self.m_reSpinMultip:setVisible(true)
                --触发过转盘并且有赢钱时直接展示respin赢钱栏
                local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
                local reSpinRound = rsExtraData.round or 0
                local resWinCoins = self.m_runSpinResultData.p_resWinCoins or 0
                local bShowWinnerBar = resWinCoins > 0 and reSpinRound > 0
                if not bShowWinnerBar then
                    self.m_reSpinLogo:playIdleAnim()
                    self.m_reSpinLogo:setVisible(true)
                    self.m_reSpinWinnerBar:resetUi()
                else
                    self.m_reSpinWinnerBar:setVisible(true)
                    self.m_reSpinWinnerBar:playStartAnim(nil)
                    self.m_reSpinWinnerBar:setWinCoinsLab(resWinCoins)
                end
                self.m_reSpinBar:updateTimes(self.m_runSpinResultData.p_reSpinCurCount)
                self.m_reSpinBar:playIdleAnim()
                self.m_reSpinBar:setVisible(true)
                self.m_reSpinJackpotBar:setGrandLockState(curLock)
                self.m_reSpinJackpotBar:playIdleAnim()
                self.m_reSpinJackpotBar:playFadeAction()
                self.m_reSpinJackpotBar:setVisible(true)
                
                self.m_respinView:setVisible(true)
                self:setNutCarnivalReelSlotsNodeVisible(false)
                self.m_jackpotBar:setVisible(false)
                self.m_collectBar:setVisible(false)
                self.m_wildCollect:setVisible(false)
                if self.m_bProduceSlots_InFreeSpin then
                    self.m_freeBar:setVisible(false)
                end
                self:changeReelBg("reSpin", true)
            end,
            function()
                func()
            end
        )
    end

    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinStartView_start)
    local reSpinStartView = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, fnNext, BaseDialog.AUTO_TYPE_NOMAL)
    --触发次数
    local labTimes = reSpinStartView:findChild("m_lb_num")
    labTimes:setString(self.m_runSpinResultData.p_reSpinsTotalCount)
    --触发类型
    local index = self:getSpecialBonusIndex(self.m_reSpinType)
    local typeNode = reSpinStartView:findChild(string.format("bonus_%d", index))
    typeNode:setVisible(true)
    --spine叶子
    local spineYezi    = util_spineCreate("Socre_NutCarnival_tbbj", true, true)
    reSpinStartView:findChild("Node_yezi"):addChild(spineYezi)
    util_spinePlay(spineYezi, "idle_yezi", true)
    --spine背景
    local spineBg    = util_spineCreate("Socre_NutCarnival_tbbj", true, true)
    reSpinStartView:findChild("Node_beijing"):addChild(spineBg)
    util_spinePlay(spineBg, "start_respin", false)
    util_spineEndCallFunc(spineBg, "start_respin", function()
        util_spinePlay(spineBg, "idle_respine", false)
    end)
    --弹板音效
    reSpinStartView.m_btnTouchSound = PublicConfig.sound_NutCarnival_commonClick
    reSpinStartView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinStartView_over)
    end)
end
--ReSpin开始改变UI状态
function CodeGameScreenNutCarnivalMachine:changeReSpinStartUI(curCount)
    self.m_respinView:playReSpinBonusSymbolIdleAnim()
    self.m_respinView:playLastOneTipAnim()
end

function CodeGameScreenNutCarnivalMachine:reSpinEndAction()
    self:setNutCarnivalReelSlotsNodeVisible(true)

    --reSpin结算栏出现
    self:playReSpinWinnerBarShowAnim(function()
        --开始结算
        local bonusList = self.m_respinView:getLockSymbolList()
        self:playReSpinOverCollectAnim(1, bonusList, function()
            --飞向赢钱区域
            self:playReSpinWinnerCoinsToBottom(function()
                CodeGameScreenNutCarnivalMachine.super.reSpinEndAction(self)
            end)
        end)
    end)    
end
function CodeGameScreenNutCarnivalMachine:playReSpinOverCollectAnim(_animIndex, _bonusList, _fun)
    local bonusNode = _bonusList[_animIndex]
    if not bonusNode then
        _fun()
        return 
    end

    local iCol     = bonusNode.p_cloumnIndex
    local iRow     = bonusNode.p_rowIndex
    local reelPos  = self:getPosReelIdx(iRow, iCol)
    local winCoins = self:getReSpinNodeWinCoins(reelPos)
    local multi,multiType = self:getReSpinSymbolReward(reelPos)
    local rsExtraData  = self.m_runSpinResultData.p_rsExtraData
    local reSpinMultip = rsExtraData.triggerMuti or 1
    local bJackpot = "" ~= multiType

    if bJackpot then
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonus_jiesuan2)
        bonusNode:runAnim("jiesuan2", false, function()
            --reSpin结算栏反馈
            local feedbackTime = self.m_reSpinWinnerBar:playCollectFeedbackAnim()
            feedbackTime = 9/60
            local curWinCoins = self.m_reSpinWinnerBar:getCurWinCoins()
            self.m_reSpinWinnerBar:jumpCoins(curWinCoins + winCoins, feedbackTime)
            --奖池弹板
            local jpIndex = self.JackpotTypeToIndex[multiType]
            self:showJackpotView(jpIndex, winCoins, reSpinMultip, function()
                self:playReSpinOverCollectAnim(_animIndex+1, _bonusList, _fun)
            end)
        end)
    else
        --飞行粒子
        local flyParams = {
            parent   = self.m_effectNode,
            flyTime  = 0.2,
            startPos = util_convertToNodeSpace(bonusNode, self.m_effectNode), 
            endPos   = util_convertToNodeSpace(self.m_reSpinWinnerBar, self.m_effectNode), 
            fnNext   = function()
                gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bonus_jiesuan)
                --reSpin结算栏反馈
                local feedbackTime = self.m_reSpinWinnerBar:playCollectFeedbackAnim()
                feedbackTime = 9/60
                local curWinCoins = self.m_reSpinWinnerBar:getCurWinCoins()
                self.m_reSpinWinnerBar:jumpCoins(curWinCoins + winCoins, feedbackTime)
                self:levelPerformWithDelay(self, feedbackTime+0.1, function()
                    self:playReSpinOverCollectAnim(_animIndex+1, _bonusList, _fun)
                end)
            end,
        }
        bonusNode:runAnim("jiesuan", false)
        self:playNutCarnivalParticleFly(flyParams)
    end
end
--respin收集栏飞向底栏
function CodeGameScreenNutCarnivalMachine:playReSpinWinnerCoinsToBottom(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinWinnerBar_jiesuan)
    local winCoins = self.m_runSpinResultData.p_resWinCoins or 0
    --飞行文本
    local flyCsb = util_createAnimation("NutCarnival_respin_winner_lab.csb")
    self:addChild(flyCsb, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    flyCsb:setScale(self.m_machineRootScale)
    local labCoins = flyCsb:findChild("m_lb_coins")
    local sCoins = util_formatCoins(winCoins, 50)
    labCoins:setString(sCoins)
    self.m_reSpinWinnerBar:upDateWinnerBarLabelSize(labCoins)
    local bottomUi = self.m_bottomUI
    local startPos = util_convertToNodeSpace(self.m_reSpinWinnerBar.m_labelCoins, self)
    local endPos   = util_convertToNodeSpace(bottomUi.m_normalWinLabel, self)
    flyCsb:setPosition(startPos)
    local actList = {}
    table.insert(actList, cc.MoveTo:create(30/60, endPos))
    table.insert(actList, cc.DelayTime:create(6/60))
    table.insert(actList, cc.CallFunc:create(function()
        --底栏反馈
        local delayTime = bottomUi:getCoinsShowTimes(winCoins)
        self:playCoinWinEffectUI(nil)
        local bottomCoins = self:getCurBottomWinCoins()
        self:setLastWinCoin(bottomCoins + winCoins)
        self:updateBottomUICoins(0, winCoins, nil, true)
        self:levelPerformWithDelay(self, delayTime, _fun)
    end))
    table.insert(actList, cc.DelayTime:create(51/60))
    table.insert(actList, cc.RemoveSelf:create())
    -- 0~86
    flyCsb:runCsbAction("shouji", false)
    flyCsb:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenNutCarnivalMachine:showRespinOverView()
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinOverView_start)
    local reSpinWinCoins = self.m_runSpinResultData.p_resWinCoins
    local reSpinOverView = self:showReSpinOver(
        reSpinWinCoins, 
        function()
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinOverGuoChang)
            self.m_wildSpineGuoChang:playReSpinOverGuoChangAnim(
                function()
                    if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
                        self:resetMusicBg(nil, "NutCarnivalSounds/music_NutCarnival_free.mp3")
                        self:changeReelBg("free", true)
                        self.m_freeBar:setVisible(true)
                    else
                        self:resetMusicBg(nil, "NutCarnivalSounds/music_NutCarnival_base.mp3")
                        self:changeReelBg("base", true)
                    end
                    --切换base
                    util_setCsbVisible(self.m_reSpinWheelView, false)
                    util_setCsbVisible(self.m_reSpinMultip, false)
                    util_setCsbVisible(self.m_reSpinLogo, false)
                    util_setCsbVisible(self.m_reSpinBar, false)
                    util_setCsbVisible(self.m_reSpinJackpotBar, false)
                    util_setCsbVisible(self.m_reSpinWinnerBar, false)
                    self.m_jackpotBar:setVisible(true)
                    self.m_collectBar:updateAllCollectCount(false)
                    self.m_collectBar:setVisible(true)
                    self.m_wildCollect:setVisible(true)
                    self:upDateReSpinOverReel()
                end,
                function()
                    self.m_lightScore = 0
                    self:triggerReSpinOverCallFun(self.m_lightScore)
                end
            )
        end
    )
end
function CodeGameScreenNutCarnivalMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local reSpinOverView = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
    local labCoins = reSpinOverView:findChild("m_lb_coins")
    reSpinOverView:updateLabelSize({label=labCoins,sx=1,sy=1}, 655)
    --spine叶子
    local spineYezi    = util_spineCreate("Socre_NutCarnival_tbbj", true, true)
    reSpinOverView:findChild("Node_yezi"):addChild(spineYezi)
    util_spinePlay(spineYezi, "idle_yezi", true)
    --角色
    local roleSpineUp   = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    local roleSpineDown = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    reSpinOverView:findChild("Node_qian"):addChild(roleSpineUp)
    reSpinOverView:findChild("Node_hou"):addChild(roleSpineDown)
    roleSpineUp:playFreeOverUpAnim()
    roleSpineDown:playFreeOverDownAnim()
    --弹板音效
    reSpinOverView.m_btnTouchSound = PublicConfig.sound_NutCarnival_commonClick
    reSpinOverView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinOverView_over)
    end)
    return reSpinOverView
end
--reSpin结束的随机棋盘
function CodeGameScreenNutCarnivalMachine:upDateReSpinOverReel()
    self:baseReelForeach(function(_slotsNode, _iCol, _iRow)
        if _slotsNode and _slotsNode.p_symbolType == self.SYMBOL_Blank then
            local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(_iCol)
            local symbolType = self:getRandomReelType(_iCol, reelDatas)
            while self:isNutCarnivalBonus(symbolType) or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD  do
                symbolType = self:getRandomReelType(_iCol, reelDatas)
            end
            self:changeNutCarnivalSymbolType(_slotsNode, symbolType)
        end
    end)
end

function CodeGameScreenNutCarnivalMachine:reSpinReelDown(addNode)
    self.m_respinView:stopReSpinReelRunEffect()
    self.m_respinView:playLastOneTipAnim()
    --取消抖动
    -- if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self.m_reSpinBar:playIdleAnim()
    -- end
    self:addNutCarnivalReSpinGameEffect()
    self:playNutCarnivalReSpinGameEffect(function()
        CodeGameScreenNutCarnivalMachine.super.reSpinReelDown(self, addNode)
    end)
end
function CodeGameScreenNutCarnivalMachine:addNutCarnivalReSpinGameEffect()
    self.m_reSpinGameEffectList = {}
    if self:isTriggerReSpinWheel() then
        table.insert(self.m_reSpinGameEffectList, {
            effectType = 1,
            effectData = {}
        })
    end
    if self:isTriggerReSpinLastMulti() then
        table.insert(self.m_reSpinGameEffectList, {
            effectType = 2,
            effectData = {}
        })
    end
    
end
function CodeGameScreenNutCarnivalMachine:playNutCarnivalReSpinGameEffect(_fun)
    if #self.m_reSpinGameEffectList < 1 then
        _fun()
        return
    end
    local reSpinGameEffect = table.remove(self.m_reSpinGameEffectList, 1)
    if 1 == reSpinGameEffect.effectType then
        self:playReSpinEffect_ReSpinWheel(reSpinGameEffect.effectData, function()
            _fun()
        end)
    elseif 2 == reSpinGameEffect.effectType then
        self:playReSpinEffect_ReSpinLastMulti(reSpinGameEffect.effectData, function()
            _fun()
        end)
    end
end
--[[
    reSpin玩法-转盘
]]
function CodeGameScreenNutCarnivalMachine:isTriggerReSpinWheel()
    local rsExtraData  = self.m_runSpinResultData.p_rsExtraData or {}
    local bTrigger = nil ~= rsExtraData.hitType

    return bTrigger
end
function CodeGameScreenNutCarnivalMachine:playReSpinEffect_ReSpinWheel(_data, _fun)
    local rsExtraData  = self.m_runSpinResultData.p_rsExtraData or {}
    local hitType  = rsExtraData.hitType or ""
    local addTimes = tonumber(hitType) or 0
    local jackpot  = tonumber(hitType) and "" or hitType
    local jpIndex  = self.JackpotTypeToIndex[jackpot]

    local wheelData = {}
    wheelData.addTimes = addTimes
    wheelData.jackpot  = jackpot
    wheelData.wheelDownFun  = function()
        if nil ~= jpIndex then
            self.m_reSpinJackpotBar:playActionframeAnim(jpIndex)
        end
    end
    wheelData.overFun  = function()
        self:showReSpinWheelAward(function()
            self:playReSpinWheelMoveDown(hitType, _fun)
        end)
    end
    self:levelPerformWithDelay(self, 0.5, function()
        --全满触发动画
        self:playReSpinWheelTriggerAnim(function()
            --全满乘倍
            self:playReSpinMultiAnim(function()
                --respin结算
                self:playReSpinFullCollect(function()
                    --转盘上升
                    self:playReSpinWheelMoveUp(function()
                        self.m_reSpinWheelView:startGame(wheelData)
                    end)
                end)
            end)
        end)
    end)
end
function CodeGameScreenNutCarnivalMachine:playReSpinWheelTriggerAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_jiman)
    self.m_respinView:stopReSpinReelRunEffect()
    self.m_reSpinWheelTriggerAnim:setVisible(true)
    self:runCsbAction("zhen2", false)
    self.m_reSpinWheelTriggerAnim:runCsbAction("start", false, function()
        self.m_reSpinWheelTriggerAnim:setVisible(false)
        _fun()
    end)
end
function CodeGameScreenNutCarnivalMachine:playReSpinMultiAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_multiAnim)
    local rsExtraData  = self.m_runSpinResultData.p_rsExtraData or {}
    local multip = rsExtraData.triggerMuti or 2
    for _index=2,5 do
        local bVisible   = _index==multip
        local multipNode = self.m_reSpinMultiAnim:findChild(string.format("multip_%d", _index))
        multipNode:setVisible(bVisible)
    end
    --乘倍砸棋盘
    self.m_reSpinMultiAnim:setVisible(true)
    self.m_reSpinMultiAnim:runCsbAction("actionframe", false, function()
        self.m_reSpinMultiAnim:setVisible(false)
    end)
    local bonusList = self.m_respinView:getLockSymbolList()
    --80帧 震动 非jackpot的bonus金币上涨
    self:levelPerformWithDelay(self, 81/60, function()
        self:runCsbAction("zhen")
        for _index,_bonusNode in ipairs(bonusList) do
            local iCol     = _bonusNode.p_cloumnIndex
            local iRow     = _bonusNode.p_rowIndex
            local reelPos  = self:getPosReelIdx(iRow, iCol)
            local multi,multiType = self:getReSpinSymbolReward(reelPos)
            if "" == multiType then
                local bonusWinCoins = self:getReSpinNodeWinCoins(reelPos)
                local rewardData = {}
                rewardData.startCoins = math.floor(bonusWinCoins / multip)
                rewardData.endCoins   = bonusWinCoins
                rewardData.jumpTime   = 30/60
                self:playBonusSymbolAddCoins(_bonusNode, rewardData)
            else
                local ccbNode = _bonusNode:getCCBNode()
                local slotCsb = ccbNode.m_slotCsb
                local sMulti = string.format("X%d", multip)
                slotCsb:findChild("m_lb_multi"):setString(sMulti)
            end
        end
        --96帧 集满乘倍
        self:levelPerformWithDelay(self, 15/60, function()
            for _index,_bonusNode in ipairs(bonusList) do
                _bonusNode:runAnim("jiman", false, function()
                    self:playSymbolIdleLoopAnim(_bonusNode)
                end)
                local iCol     = _bonusNode.p_cloumnIndex
                local iRow     = _bonusNode.p_rowIndex
                local reelPos  = self:getPosReelIdx(iRow, iCol)
                local multi,multiType = self:getReSpinSymbolReward(reelPos)
                if "" ~= multiType then
                    local ccbNode = _bonusNode:getCCBNode()
                    local slotCsb = ccbNode.m_slotCsb
                    slotCsb:runCsbAction("jiman", false)
                end
            end
            --全满结算
            self:levelPerformWithDelay(self, 24/30, _fun)
        end)
    end)
end
--bonus上的金币乘倍增加
function CodeGameScreenNutCarnivalMachine:playBonusSymbolAddCoins(_bonusNode, _rewardData)
    --[[
        _rewardData = {
            startCoins = 0,
            endCoins   = 100,
            jumpTime   = 0.5
        }
    ]]
    local offsetValue = _rewardData.endCoins - _rewardData.startCoins
    if offsetValue <= 0 then
        return
    end
    local coinRiseNum =  offsetValue / (_rewardData.jumpTime * 60)
    local sRandomCoinRiseNum   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = math.ceil(tonumber(sRandomCoinRiseNum))
    local ccbNode = _bonusNode:getCCBNode()
    local slotCsb = ccbNode.m_slotCsb
    --报错:信号类型错误
    local labCoins = slotCsb:findChild("m_lb_coins")
    local curCoins = _rewardData.startCoins
    schedule(labCoins, function()
        curCoins = curCoins + coinRiseNum
        curCoins = math.min(_rewardData.endCoins, curCoins)
        local sCoins     = util_formatCoins(curCoins, 3)
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins, sx=1, sy=1}, 141)
        if curCoins >= _rewardData.endCoins then
            labCoins:stopAllActions()
        end
    end,0.008)
end
--全满单独结算一次
function CodeGameScreenNutCarnivalMachine:playReSpinFullCollect(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_Full)
    self.m_respinView:unLockNutCarnivalBonusSymbol()
    --庆祝动画
    self.m_wildSpineCelebrate:playReSpinFullAnim(function()
        --reSpin结算栏出现
        self:playReSpinWinnerBarShowAnim(function()
            self.m_respinView:lockNutCarnivalBonusSymbol()
            --开始结算
            local bonusList = self.m_respinView:getSymbolList(self.SYMBOL_Bonus)
            self:playReSpinOverCollectAnim(1, bonusList, function()
                _fun()
            end)
        end)
    end)
end
-- logo栏 -> 收集栏
function CodeGameScreenNutCarnivalMachine:playReSpinWinnerBarShowAnim(_fun)
    if self.m_reSpinLogo:isVisible() then
        self.m_reSpinLogo:playOverAnim(function()
            self.m_reSpinLogo:setVisible(false)
        end)
    end
    if not self.m_reSpinWinnerBar:isVisible() then
        self.m_reSpinWinnerBar:setVisible(true)
        self.m_reSpinWinnerBar:playStartAnim(_fun)
    else
        _fun()
    end
end
--转盘上升
function CodeGameScreenNutCarnivalMachine:playReSpinWheelMoveUp(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_reelLight)
    --棋盘闪光
    self:runCsbAction("shan", false, function()
        gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_otherUiHide)
        --其余ui消失
        self.m_reSpinWinnerBar:playOverAnim()
        if self.m_reSpinLogo:isVisible() then
            self.m_reSpinLogo:playOverAnim(function()
                self.m_reSpinLogo:setVisible(false)
            end)
        end
        if self.m_reSpinWinnerBar:isVisible() then
            self.m_reSpinWinnerBar:playOverAnim(function()
                self.m_reSpinWinnerBar:setVisible(false)
            end)
        end
        self.m_reSpinJackpotBar:showReSpinWheelJackpotBar()
        self.m_reSpinMultip:playMoveAnim(true)
        self.m_reSpinBar:playMoveAnim(true)
        
        self:levelPerformWithDelay(self, 24/60, function()
            --棋盘消失
            self:runCsbAction("xiayi", false, function()
                gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinWheel_enter)
                --转盘出现
                self.m_reSpinWheelView:setWheelOrder(true)
                self.m_reSpinWheelView:playMoveAnim(false, _fun)
            end)
        end)
    end)
    
end
--表现转盘的奖励
function CodeGameScreenNutCarnivalMachine:showReSpinWheelAward(_fun)
    local rsExtraData  = self.m_runSpinResultData.p_rsExtraData or {}
    local hitType      = rsExtraData.hitType or ""
    --增加reSpin次数
    local addTimes = tonumber(hitType) or 0
    if 0 ~= addTimes then
        self:showReSpinMoreView(addTimes, _fun)
        return
    end
    --jackpot
    local jpType   = hitType
    local jpIndex  = self.JackpotTypeToIndex[jpType] 
    local winCoins = rsExtraData.wheel_win_coins or 0
    local reSpinMultip = 1
    self:showJackpotView(jpIndex, winCoins, reSpinMultip, function()
        _fun()
    end)
end
--转盘下降
function CodeGameScreenNutCarnivalMachine:playReSpinWheelMoveDown(_wheelAward, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinWheel_exit)
    self:runCsbAction("shangyi", false)
    self.m_reSpinJackpotBar:playIdleAnim()
    self.m_reSpinJackpotBar:playFadeAction()
    self.m_reSpinMultip:playMoveAnim(false)
    self.m_reSpinWinnerBar:setVisible(true)
    self.m_reSpinWinnerBar:playStartAnim(nil)
    self.m_reSpinBar:playMoveAnim(false)
    self.m_reSpinWheelView:setWheelOrder(false)
    self.m_reSpinWheelView:playMoveAnim(true, function()
        --如果是新增次数
        local rsExtraData  = self.m_runSpinResultData.p_rsExtraData or {}
        local hitType      = rsExtraData.hitType or ""
        local wheelTimes   = rsExtraData.round or 1
        local addTimes = tonumber(hitType) or 0
        local roundCount = wheelTimes + 1
        if 0 ~= addTimes then
            gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpin_addTimes)
            self.m_reSpinBar:playReSpinMoreAnim(self.m_runSpinResultData.p_reSpinCurCount, function()
                self.m_reSpinRound:playStartAnim(roundCount, _fun)
            end)
        else
            if 0 ~= self.m_runSpinResultData.p_reSpinCurCount then
                self.m_reSpinRound:playStartAnim(roundCount, _fun)
            else
                _fun()
            end
        end
    end)
end
--reSpinMore
function CodeGameScreenNutCarnivalMachine:showReSpinMoreView(_num, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_reSpinMore)
    local ownerlist = {}
    ownerlist["m_lb_num"] = util_formatCoins(_num, 30)
    local reSpinMoreView = self:showDialog("ReSpinMore", ownerlist, _fun, BaseDialog.AUTO_TYPE_NOMAL, nil)
    --文本复数
    local bPlural = _num > 1 
    reSpinMoreView:findChild("wenben1"):setVisible(bPlural)
    reSpinMoreView:findChild("wenben2"):setVisible(not bPlural)
    --spine背景
    local spineBg    = util_spineCreate("Socre_NutCarnival_tbbj", true, true)
    reSpinMoreView:findChild("Node_beijing"):addChild(spineBg)
    local startName = "start_respin2"
    util_spinePlay(spineBg, startName, false)
    util_spineEndCallFunc(spineBg, startName, function()
        util_spinePlay(spineBg, "idle_respine2", false)
    end)
    --角色
    local roleSpine   = util_createView("CodeNutCarnivalSrc.NutCarnivalRoleSpine",{})
    reSpinMoreView:findChild("Node_juese"):addChild(roleSpine)
    roleSpine:playReSpinMoreAnim()

    return reSpinMoreView
end
--[[
    reSpin玩法-满屏成倍
]]
function CodeGameScreenNutCarnivalMachine:isTriggerReSpinLastMulti()
    local curReSpinTimes = self.m_runSpinResultData.p_reSpinCurCount or 0
    local storedIcons    = self.m_runSpinResultData.p_storedIcons or {}
    local rsExtraData    = self.m_runSpinResultData.p_rsExtraData or {}
    local reSpinMultip   = rsExtraData.triggerMuti or 1
    local bTrigger = #self.m_reSpinGameEffectList < 1 and curReSpinTimes <= 0 and #storedIcons >= 15 and reSpinMultip > 1

    return bTrigger
end
function CodeGameScreenNutCarnivalMachine:playReSpinEffect_ReSpinLastMulti(_data, _fun)
    --全满触发动画
    self:playReSpinWheelTriggerAnim(function()
        --全满乘倍
        self:playReSpinMultiAnim(_fun)
    end)
end

--ReSpin刷新数量
function CodeGameScreenNutCarnivalMachine:changeReSpinUpdateUI(curCount)
    if not curCount then
        return
    end
    local bReSpinStart = curCount ~= self.m_runSpinResultData.p_reSpinCurCount
    self.m_reSpinBar:updateTimes(curCount, bReSpinStart)
end
-- 继承底层respinView
function CodeGameScreenNutCarnivalMachine:getRespinView()
    return "CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalRespinView"
end
-- 继承底层respinNode
function CodeGameScreenNutCarnivalMachine:getRespinNode()
    return "CodeNutCarnivalSrc.NutCarnivalReSpin.NutCarnivalRespinNode"
end
function CodeGameScreenNutCarnivalMachine:getRespinRandomTypes()
    local symbolList = {
        self.SYMBOL_Bonus,
        self.SYMBOL_Blank,
    }
    return symbolList 
end
function CodeGameScreenNutCarnivalMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_Bonus, runEndAnimaName = "buling", bRandom = true},
    }
    return symbolList
end

--[[
    预告中奖
]]
function CodeGameScreenNutCarnivalMachine:spinResultCallFun(param)
    CodeGameScreenNutCarnivalMachine.super.spinResultCallFun(self, param)
    -- if param[1] == true then
    --     print("CodeGameScreenNutCarnivalMachine:spinResultCallFun", cjson.encode(param[2].result))
    -- end
    --reSpin收集栏数据
    local selfData   = self.m_runSpinResultData.p_selfMakeData or {}
    local linkConfig = selfData.linkConfig or {}
    local betCoin = globalData.slotRunData:getCurTotalBet()
    self.m_collectBar:setReSpinCollectCount(betCoin, linkConfig)
end
function CodeGameScreenNutCarnivalMachine:operaSpinResultData(param)
	CodeGameScreenNutCarnivalMachine.super.operaSpinResultData(self,param)
	-- 预告中奖标记
    self.m_yugaoAnim:playYuGaoAnim()
end
-- 需要关卡重写的方法
function CodeGameScreenNutCarnivalMachine:updateNetWorkData()
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
    if self.m_yugaoAnim:getWinningNoticeStatus() then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 预告中奖时间线长度
        end, self.m_yugaoAnim.m_winningNoticeTime)
    else
        nextFun()
    end
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenNutCarnivalMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenNutCarnivalMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenNutCarnivalMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

--[[
    落地相关
]]
--
--单列滚动停止回调
--
function CodeGameScreenNutCarnivalMachine:slotOneReelDown(reelCol)    
    CodeGameScreenNutCarnivalMachine.super.slotOneReelDown(self,reelCol) 
   
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_firstReelRunCol == 0 then
            self.m_firstReelRunCol = reelCol

        end
    end
    if reelCol == self.m_iReelColumnNum then
        if 0 ~= self.m_firstReelRunCol then
            self:stopNutCarnivalExpectAnim()
            self.m_firstReelRunCol = 0
        end
    end
end

function CodeGameScreenNutCarnivalMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --1.提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
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
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
end
function CodeGameScreenNutCarnivalMachine:symbolBulingEndCallBack(_slotNode)
    -- _slotNode.m_playBuling = nil
    local symbolType = _slotNode.p_symbolType
    local bScatter = symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER

    if self:isNutCarnivalBonus(symbolType) or bScatter then
        self:playSymbolIdleLoopAnim(_slotNode)
    end
    --期待动画
    if bScatter then 
        if 0 ~= self.m_firstReelRunCol then
            local iCol = _slotNode.p_cloumnIndex
            local iRow = _slotNode.p_rowIndex
            if iCol == self.m_firstReelRunCol then
                self:playNutCarnivalExpectAnim(iCol, nil)
            elseif iCol > self.m_firstReelRunCol then
                self:playNutCarnivalExpectAnim(iCol, iRow)
            end
        end
    end
end
--期待动画 播放/停止
function CodeGameScreenNutCarnivalMachine:playNutCarnivalExpectAnim(_iCol, _iRow)
    local animName = "idleframe1"
    if not _iRow then
        for iCol=1,_iCol do
            for iRow=1,self.m_iReelRowNum do
                local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then 
                    slotsNode:runAnim(animName, true)
                end
            end
        end
    else
        local slotsNode = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
        slotsNode:runAnim(animName, true)
    end 
end
function CodeGameScreenNutCarnivalMachine:stopNutCarnivalExpectAnim()
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then 
                self:playSymbolIdleLoopAnim(slotsNode)
            end
        end
    end
end

function CodeGameScreenNutCarnivalMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenNutCarnivalMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenNutCarnivalMachine.super.slotReelDown(self)
end
function CodeGameScreenNutCarnivalMachine:showLineFrame()
    --[[
        快停刷新问题
        连线和玩法一起触发问题
    ]]
    local lineWinCoins  = self:getClientWinCoins()
    self.m_iOnceSpinLastWin = lineWinCoins
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    local bottomWinCoin = self:getCurBottomWinCoins()
    local lastWinCoin   = 0
    if bFree then
        lastWinCoin = bottomWinCoin + lineWinCoins
    else
        lastWinCoin = lineWinCoins
    end
    self:setLastWinCoin(lastWinCoin)

    CodeGameScreenNutCarnivalMachine.super.showLineFrame(self)
end


function CodeGameScreenNutCarnivalMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    elseif self:checkHasNutCarnivalSelfEffect(self.EFFECT_PickGame) then
        isNotifyUpdateTop = false
    end
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenNutCarnivalMachine:isNutCarnivalBonus(_symbolType)
    return self:isNutCarnivalCommonBonus(_symbolType) or self:isNutCarnivalSpecialBonus(_symbolType)
end
function CodeGameScreenNutCarnivalMachine:isNutCarnivalCommonBonus(_symbolType)
    return _symbolType == self.SYMBOL_Bonus
end
--特殊bonus
function CodeGameScreenNutCarnivalMachine:isNutCarnivalSpecialBonus(_symbolType)
    if _symbolType == self.SYMBOL_SpecialBonus_1 or
        _symbolType == self.SYMBOL_SpecialBonus_2 or
        _symbolType == self.SYMBOL_SpecialBonus_3 or
        _symbolType == self.SYMBOL_SpecialBonus_4 then
        return true
    end
    return false
end
function CodeGameScreenNutCarnivalMachine:getSpecialBonusIndex(_symbolType)
    local bonusIndex = _symbolType + 1 - self.SYMBOL_SpecialBonus_1
    return bonusIndex
end
--[[
    工具
]]
function CodeGameScreenNutCarnivalMachine:isHasBigWin()
    local bool = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            
        bool = true
    end

    return bool
end
function CodeGameScreenNutCarnivalMachine:getSymbolCountByCol(_symbolType, _iCol)
    local count = 0
    local reel = self.m_runSpinResultData.p_reels
    for _lineIndex,_lineData in ipairs(reel) do
        for iCol,_symbol in ipairs(_lineData) do
            if iCol <= _iCol and _symbol == _symbolType then
                count = count + 1
            end
        end
    end

    return count
end
function CodeGameScreenNutCarnivalMachine:playNutCarnivalParticleFly(_params)
    --[[
        _params = {
            parent = cc.Node,
            flyTime  = 1,
            startPos = cc.p(0, 0), 
            endPos   = cc.p(0, 0), 
            fnNext   == function,
            --飞行动作类型
        }
    ]]
    local parent   = _params.parent
    local flyTime  = _params.flyTime
    local startPos = _params.startPos
    local endPos   = _params.endPos
    local fnNext   = _params.fnNext
    local flyCsb = util_createAnimation("NutCarnival_lizi.csb")
    parent:addChild(flyCsb)
    flyCsb:setPosition(startPos)
    local particleNode = flyCsb:findChild("Particle_1")
    particleNode:setVisible(true)
    particleNode:stopSystem()
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    flyCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(flyTime, endPos),
        cc.CallFunc:create(function()
            if fnNext then
                fnNext()
            end

            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))
        end),
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end
function CodeGameScreenNutCarnivalMachine:getReSpinNodeWinCoins(_reelPos)
    local winCoins = 0
    local winLines = self.m_runSpinResultData.p_winLines or {}
    for i,_winData in ipairs(winLines) do
        local iPos = _winData.p_iconPos[1]
        if iPos == _reelPos then
            winCoins = _winData.p_amount
        end
    end
    return winCoins
end
--修改图标类型
function CodeGameScreenNutCarnivalMachine:changeNutCarnivalSymbolType(_slotsNode, _symbolType)
    self:changeSymbolType(_slotsNode, _symbolType)
end
--震动
function CodeGameScreenNutCarnivalMachine:shakeReelNode(_params)
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
function CodeGameScreenNutCarnivalMachine:playSymbolIdleLoopAnim(_slotNode)
    _slotNode:runAnim("idleframe2", true)
end
function CodeGameScreenNutCarnivalMachine:isLastFreeSpin()
    local collectLeftCount  = globalData.slotRunData.freeSpinCount
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local bLast = self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount and 0 == collectLeftCount
    return bLast 
end
function CodeGameScreenNutCarnivalMachine:checkHasNutCarnivalSelfEffect(_selfEffectType)
    for i,_effectData in ipairs(self.m_gameEffects) do
        if _effectData.p_selfEffectType == _selfEffectType then
            return true
        end
    end
    return false
end
-- 延时
function CodeGameScreenNutCarnivalMachine:levelPerformWithDelay(_parent, _time, _fun)
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
function CodeGameScreenNutCarnivalMachine:baseReelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if (isJumpFun) then
                return
            end
        end
    end
end
--获取底栏金币
function CodeGameScreenNutCarnivalMachine:getCurBottomWinCoins()
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
function CodeGameScreenNutCarnivalMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenNutCarnivalMachine:getBounsScatterDataZorder(symbolType)
    local symbolOrder = CodeGameScreenNutCarnivalMachine.super.getBounsScatterDataZorder(self, symbolType)

    if self:isNutCarnivalBonus(symbolType) then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_Mystery then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
    end

    return symbolOrder
end

function CodeGameScreenNutCarnivalMachine:scaleMainLayer()
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
            local bgScale = 1
            -- 1.78
            if display.height / display.width >= 1370/768 then
            --1.59
            elseif display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.23
                mainPosY  = 5
            --1.5
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.25
                mainPosY  = 10
            --1.33
            elseif display.height / display.width >= 1024/768 then
                mainScale = mainScale * 1.31
                mainPosY  = 16
            --1.2
            elseif display.height / display.width >= 1.2--[[2176/1812]] then
                mainScale = mainScale * 1.38
                mainPosY  = 20
                bgScale = 1.2
            end

            mainScale = math.min(1, mainScale)
            util_csbScale(self.m_machineNode, mainScale)
            util_csbScale(self.m_gameBg.m_csbNode, bgScale)
            self.m_machineRootScale  = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end

    end
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenNutCarnivalMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    if self:isTriggerPickGame() then
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenNutCarnivalMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    local lineWinCoins  = self:getClientWinCoins()
    self.m_iOnceSpinLastWin = lineWinCoins
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    local bottomWinCoin = self:getCurBottomWinCoins()
    local lastWinCoin   = 0
    if bFree then
        lastWinCoin = bottomWinCoin + lineWinCoins
    else
        lastWinCoin = lineWinCoins
        -- lastWinCoin = self.m_runSpinResultData.p_winAmount
    end
    self:setLastWinCoin(lastWinCoin)
    local params = {
        overCoins  = lineWinCoins,
        jumpTime   = 1.5,
        animName   = "actionframe",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenNutCarnivalMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_bottomUiBigWin)
    local animName = "actionframe"
    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, animName, false)
    util_spineEndCallFunc(self.m_bigWinSpine, animName, function()
        self.m_bigWinSpine:setVisible(false)

        --停止连线音效
        self:stopLinesWinSound()

        if type(_func) == "function" then
            _func()
        end
    end)
    --震屏
    self:shakeReelNode({
        shakeTimes    = math.floor((81/30)/0.1),
        shakeOnceTime = 0.1,
        shakeNodeName = {
            "Node_pickCollect",
            "Node_reel",
            "Node_bigWin",
        }
    })
end

return CodeGameScreenNutCarnivalMachine