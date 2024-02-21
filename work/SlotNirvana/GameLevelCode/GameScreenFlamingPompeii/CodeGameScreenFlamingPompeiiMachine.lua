--[[
玩法:  
    base:
        随机 wild,bonus,scatter:
            单次spin，随机出wild,bonus,scatter在棋盘上。
    free:
        固定bonus:
            滚动出现的bonus会被固定到棋盘上，每次向下移动一行知道移出盘面，触发reSpin后取消固定。
    reSpin:
        普通buff转盘:
            普通bonus落入buff格子触发,奖励(随机一个位置的bonus获得乘倍, 升行, 加reSpin次数, 结算一次, 所有bonus奖励增加)
        特殊buff转盘:
            特殊bonus落入buff格子触发,奖励(触发位置直接翻倍, 触发位置直接变为jackpot)

]]
local FlamingPompeiiPublicConfig = require "FlamingPompeiiPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenFlamingPompeiiMachine = class("CodeGameScreenFlamingPompeiiMachine", BaseNewReelMachine)
local BaseDialog = util_require("Levels.BaseDialog")

CodeGameScreenFlamingPompeiiMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFlamingPompeiiMachine.SYMBOL_10     = 9
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Bonus1 = 95  --特殊bonus
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Bonus2 = 94  --普通bonus
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Blank  = 100
--buff卷轴
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Buff1_multi                  = 101 --随机bonus乘倍
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Buff1_upRow                  = 102 --升行
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Buff1_addSpinTimes           = 103 --增加spin次数
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Buff1_settlementBonusCoins   = 104 --所有bonus结算一次
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Buff1_addBonusCoins          = 105 --所有bonus钱数增加
CodeGameScreenFlamingPompeiiMachine.SYMBOL_Buff2_bonus                  = 201 --特殊bonus触发转盘的小图标

CodeGameScreenFlamingPompeiiMachine.EFFECT_LockBonus     = GameEffect.EFFECT_SELF_EFFECT - 40    --free-固定bonus
CodeGameScreenFlamingPompeiiMachine.EFFECT_BigWinOver    = 220                                   --大赢结束回调

--jackpot名称转索引
CodeGameScreenFlamingPompeiiMachine.JackpotNameToIndex = {
    grand  = 1,
    mega   = 2,
    major  = 3,
    minor  = 4,
    mini   = 5,
}
CodeGameScreenFlamingPompeiiMachine.JackpotIndexToName = {
    [1] = "grand",
    [2] = "mega",
    [3] = "major",
    [4] = "minor",
    [5] = "mini",
}
CodeGameScreenFlamingPompeiiMachine.MultiTypeToJackpotKey = {
    grand  = "Grand",
    mega   = "Mega",
    major  = "Major",
    minor  = "Minor",
    mini   = "Mini",
}


-- 构造函数
function CodeGameScreenFlamingPompeiiMachine:ctor()
    CodeGameScreenFlamingPompeiiMachine.super.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_isFeatureOverBigWinInFree = true

    --grand锁定
    self.m_curBetValue  = 0
    self.m_grandLockBet = 0
    --reSpin-特殊bonus触发
    self.m_bSpecialReSpin = false
    --freeMore断线
    self.m_reconnectionFreeMore = false
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
    --init
    self:initGame()
end

function CodeGameScreenFlamingPompeiiMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

--
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFlamingPompeiiMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FlamingPompeii"  
end
--小块
function CodeGameScreenFlamingPompeiiMachine:getBaseReelGridNode()
    return "CodeFlamingPompeiiSrc.FlamingPompeiiSlotNode"
end

function CodeGameScreenFlamingPompeiiMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --火山背景 一个常驻,一个临时切换
    self.m_bgSpine = util_spineCreate("GameScreenFlamingPompeiiBg",true,true)
    self.m_gameBg:findChild("Node_bgSpine"):addChild(self.m_bgSpine)
    util_setCascadeOpacityEnabledRescursion(self.m_bgSpine, true)
    self.m_tempBgSpine = util_spineCreate("GameScreenFlamingPompeiiBg",true,true)
    self.m_gameBg:findChild("Node_bgSpine"):addChild(self.m_tempBgSpine)
    self.m_tempBgSpine:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_tempBgSpine, true)
    --base->free过场
    self.m_guochangSpine = util_spineCreate("FlamingPompeii_guochang1",true,true)
    self.m_gameBg:findChild("Node_bgSpine"):addChild(self.m_guochangSpine)
    self.m_guochangSpine:setVisible(false)
    --层级最低过场
    self.m_guochang2Spine_down = util_spineCreate("FlamingPompeii_guochang2_down",true,true)
    self:findChild("Node_freeOverGuoChang_down"):addChild(self.m_guochang2Spine_down)
    self.m_guochang2Spine_down:setVisible(false)
    --压在down上面的过场
    self.m_guochang2Spine_down2 = util_spineCreate("FlamingPompeii_guochang2_up",true,true)
    self:findChild("Node_freeOverGuoChang_down"):addChild(self.m_guochang2Spine_down2)
    self.m_guochang2Spine_down2:setVisible(false)
    --层级最高过场
    self.m_guochang2Spine_up = util_spineCreate("FlamingPompeii_guochang2_up",true,true)
    self:findChild("Node_freeOverGuoChang_up"):addChild(self.m_guochang2Spine_up)
    self.m_guochang2Spine_up:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self.m_gameBg, true)

    -- 奖池
    self.m_jackpotBar = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiJackPotBarView", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --随机固定图标
    self.m_randomSymbol = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiRandomSymbol", self)
    self:findChild("Node_randomSymbol"):addChild(self.m_randomSymbol)

    -- freeBar
    self.m_freeBar = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiFree.FlamingPompeiiFreespinBarView", self)
    self:findChild("Node_spinTimesBar"):addChild(self.m_freeBar)
    self.m_freeBar:setVisible(false)
    -- 固定bonus
    self.m_lockBonus = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiFree.FlamingPompeiiLockBonus", self)
    self:findChild("Layer_lockBonus"):addChild(self.m_lockBonus)
    -- 固定bonus的背景
    self.m_lockBonusReelBg = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiFree.FlamingPompeiiLockBonusReelBg", self)
    self:findChild("Node_randomSymbol"):addChild(self.m_lockBonusReelBg)
    
    


    --reSpinReel 挂点参照都是主棋盘,创建完丢过去
    self.m_reSpinReel = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiMiniMachine",{machine = self})
    self:findChild("Node_reSpinReel"):addChild(self.m_reSpinReel)
    self.m_reSpinReel.m_machineRootScale = self.m_machineRootScale
    self.m_reSpinReel:setVisible(false)
    self.m_reSpinReel:setiMiniMachineReSpinOverCallBack(function()
        self:showFlamingPompeiiReSpinOver()
    end)
    local reSpinReelUiList = {}
    --特殊bonus展示节点
    reSpinReelUiList.topBonus = util_createAnimation("FlamingPompeii_zhanshi.csb")
    self:findChild("Node_zhanshi"):addChild(reSpinReelUiList.topBonus)
    local bonusNode = self:createFlamingPompeiiTempSymbol(self.SYMBOL_Bonus1, {})
    reSpinReelUiList.topBonus:findChild("Node_bonusSpine"):addChild(bonusNode)
    reSpinReelUiList.topBonus.m_bonusNode = bonusNode
    util_setCascadeOpacityEnabledRescursion(reSpinReelUiList.topBonus, true)
    reSpinReelUiList.topBonus:setVisible(false)
    --reSpinBar
    reSpinReelUiList.reSpinBar = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiReSpinBarView", self)
    self:findChild("Node_spinTimesBar"):addChild(reSpinReelUiList.reSpinBar)
    reSpinReelUiList.reSpinBar:setVisible(false)
    --reSpinTopReel
    local commonReelData = {}
    commonReelData.machine        = self
    commonReelData.buffReelIndex  = 1
    reSpinReelUiList.commonTopReel = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiRespinTopReel", commonReelData)
    self:findChild("Node_buffReel"):addChild(reSpinReelUiList.commonTopReel)
    reSpinReelUiList.commonTopReel:setVisible(false)
    --reSpinTopReel-2
    local specialReelData = {}
    specialReelData.machine        = self
    specialReelData.buffReelIndex  = 2
    reSpinReelUiList.specialTopReel = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiRespinTopReel", specialReelData)
    self:findChild("Node_buffReel"):addChild(reSpinReelUiList.specialTopReel)
    reSpinReelUiList.specialTopReel:setVisible(false)
    --reSpin提示
    reSpinReelUiList.reSpinTip = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiReSpin.FlamingPompeiiRespinTips", {})
    self:findChild("Node_reSpintishi"):addChild(reSpinReelUiList.reSpinTip)
    reSpinReelUiList.reSpinTip:setVisible(false)
    self.m_reSpinReel:initUIList(reSpinReelUiList)
    --reSpin棋盘遮罩
    self:findChild("Panel_reSpinStart"):setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2) 
    
    --大赢效果
    self.m_bigWinCsb = util_createAnimation("FlamingPompeii_daying.csb")
    self:findChild("Node_bigWinEffect"):addChild(self.m_bigWinCsb)
    self.m_bigWinCsb:setVisible(false)
    self.m_bigWinSpineDown = util_spineCreate("FlamingPompeii_binwin",true,true)
    self:findChild("Node_bigWinEffect_down"):addChild(self.m_bigWinSpineDown)
    self.m_bigWinSpineDown:setVisible(false)


    self:changeReelBg("base")
    self.m_jackpotBar:setShowState("base")
    self.m_gameBg:findChild("Node_switch"):setVisible(false)
    self.m_reSpinReel:setReSpinReelPosY(4, false)
end

function CodeGameScreenFlamingPompeiiMachine:enterGamePlayMusic(  )
    self:playEnterGameSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_enterLevel)
end

function CodeGameScreenFlamingPompeiiMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_reSpinReel:initMiniRespinView()
    CodeGameScreenFlamingPompeiiMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --reSpin相关事件移除监听
    gLobalNoticManager:removeObserver(self, ViewEventType.RESPIN_TOUCH_SPIN_BTN)
    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_RESPIN_RUN_STOP)

    --初始化buff卷轴的小块
    self.m_reSpinReel.m_commonTopReel.m_reel_horizontal:initSymbolNode()
    self.m_reSpinReel.m_specialTopReel.m_reel_horizontal:initSymbolNode()
    -- 重连修改bonus图标展示
    if self.m_bProduceSlots_InFreeSpin then
        self:reconnectShowLockBonus()
    end
    self:changeBetUpDateGrandLock()
end

function CodeGameScreenFlamingPompeiiMachine:initGridList(isFirstNoramlReel)
    CodeGameScreenFlamingPompeiiMachine.super.initGridList(self, isFirstNoramlReel)
    
    --reSpin棋盘
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    if reSpinCurCount and reSpinCurCount ~= 0 then
        local rsExtraData   = self.m_runSpinResultData.p_rsExtraData
        local reels         = {}
        local reSpinReelRow = rsExtraData.rows 
        -- 重连reSpin随机低级图标
        for _lineIndex,_lineData in ipairs(rsExtraData.reels) do
            if not reels[_lineIndex] then
                reels[_lineIndex] = {}
            end
            for _iCol,_symbolType in ipairs(_lineData) do
                if _symbolType == self.SYMBOL_Blank then
                    local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(_iCol)
                    -- 不要bonus,scatter,空格
                    while _symbolType == self.SYMBOL_Blank or self:isFlamingPompeiiBonusSymbol(_symbolType) or _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER do
                        _symbolType = self:getRandomReelType(_iCol, reelDatas)
                    end
                end
                reels[_lineIndex][_iCol] = _symbolType
            end
        end
        self:initReSpinOverReel(reels, reSpinReelRow, true)
        return
    end
    --初始棋盘
    if not self:checkHasFeature() then
        local curBet   = globalData.slotRunData:getCurTotalBet()
        self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
            local symbolType = _slotsNode.p_symbolType
            if self:isFlamingPompeiiBonusSymbol(symbolType) then
                local multi = 800000000/curBet
                self:addSpineSymbolCsbNode(_slotsNode, multi)
                self:upDateBonusJackpotAndCoins(_slotsNode, multi)
            end
        end)
    end
end

function CodeGameScreenFlamingPompeiiMachine:addObservers()
    CodeGameScreenFlamingPompeiiMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = FlamingPompeiiPublicConfig[string.format("sound_FlamingPompeii_freeLineFrame_%d", soundIndex)]
        else
            soundName = FlamingPompeiiPublicConfig[string.format("sound_FlamingPompeii_lineFrame_%d", soundIndex)]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

     --bet数值切换
     gLobalNoticManager:addObserver(self,function(self,params)
        self:changeBetUpDateGrandLock()
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenFlamingPompeiiMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenFlamingPompeiiMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFlamingPompeiiMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_10 then
        return "Socre_FlamingPompeii_10"
    end
    if symbolType == self.SYMBOL_Bonus1 then
        return "Socre_FlamingPompeii_Bonus1"
    end
    if symbolType == self.SYMBOL_Bonus2 then
        return "Socre_FlamingPompeii_Bonus2"
    end
    if symbolType == self.SYMBOL_Blank then
        return "Socre_FlamingPompeii_Blank"
    end
    --buff棋盘图标
    if symbolType == self.SYMBOL_Buff1_multi then
        return "Wheel_FlamingPompeii_5"
    end
    if symbolType == self.SYMBOL_Buff1_upRow then
        return "Wheel_FlamingPompeii_3"
    end
    if symbolType == self.SYMBOL_Buff1_addSpinTimes then
        return "Wheel_FlamingPompeii_4"
    end
    if symbolType == self.SYMBOL_Buff1_settlementBonusCoins then
        return "Wheel_FlamingPompeii_1"
    end
    if symbolType == self.SYMBOL_Buff1_addBonusCoins then
        return "Wheel_FlamingPompeii_2"
    end
    if symbolType == self.SYMBOL_Buff2_bonus then
        return "Wheel_FlamingPompeii_Bonus"
    end

    return nil
end
--
--设置bonus scatter 层级
function CodeGameScreenFlamingPompeiiMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenFlamingPompeiiMachine.super.getBounsScatterDataZorder(self, symbolType)

    if symbolType ==  self.SYMBOL_Bonus1 or symbolType ==  self.SYMBOL_Bonus2 then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end

    return order
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFlamingPompeiiMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenFlamingPompeiiMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus1,count =  15}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus2,count =  15}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Blank,count =  15}
    


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
--[[
    棋盘背景和卷轴背景
]]
function CodeGameScreenFlamingPompeiiMachine:changeReelBg(_model, _playAnim)
    local bBase  = "base"   == _model
    local bfree  = "free"   == _model
    local bReSpin = "reSpin" == _model
    local spineAnimName = bBase and "idle1" or "idle2"

    if _playAnim then
        --卷轴
        self:findChild("Reel_base"):setVisible(bBase)
        self:findChild("Reel_free"):setVisible(bfree)
        --背景
        self.m_gameBg:findChild("base"):setVisible(bBase)
        self.m_gameBg:findChild("free"):setVisible(bfree)
        self.m_gameBg:findChild("reSpin"):setVisible(bReSpin)
        
        if bfree then
            -- 90~111 渐变
            self:levelPerformWithDelay(self, 33/60, function()
                --打开高层spine 
                self.m_tempBgSpine:setVisible(true)
                --底层spine直接切换到下一个模式的循环idle
                util_spinePlay(self.m_bgSpine, spineAnimName, false)
                util_spineEndCallFunc(self.m_bgSpine, spineAnimName, function()
                    util_spinePlay(self.m_bgSpine, spineAnimName, true)
                    util_spinePlay(self.m_tempBgSpine, spineAnimName, true)
                end)
                --淡出淡入
                self.m_tempBgSpine:runAction(cc.Sequence:create(
                    cc.FadeOut:create(21/30),
                    cc.CallFunc:create(function()
                        self.m_tempBgSpine:setVisible(false)
                        self.m_tempBgSpine:setOpacity(255)
                    end)
                ))
                self.m_bgSpine:setOpacity(0)
                self.m_bgSpine:runAction(cc.FadeIn:create(21/30))
            end)
        else
            util_spinePlay(self.m_bgSpine, spineAnimName, true)
            util_spinePlay(self.m_tempBgSpine, spineAnimName, true)
        end
    else
        --卷轴
        self:findChild("Reel_base"):setVisible(bBase)
        self:findChild("Reel_free"):setVisible(bfree)
        --背景
        self.m_gameBg:findChild("base"):setVisible(bBase)
        self.m_gameBg:findChild("free"):setVisible(bfree)
        self.m_gameBg:findChild("reSpin"):setVisible(bReSpin)
        util_spinePlay(self.m_bgSpine, spineAnimName, true)
        util_spinePlay(self.m_tempBgSpine, spineAnimName, true)
    end
    --线数
    self:findChild("Node_lineCount"):setVisible(not bReSpin)
end

--[[
    断线重连 
]]
function CodeGameScreenFlamingPompeiiMachine:initGameStatusData(gameData)
    CodeGameScreenFlamingPompeiiMachine.super.initGameStatusData(self, gameData)

    if 0 == self.m_grandLockBet then
        local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
        if nil ~= specialBets[1] then
            self.m_grandLockBet = specialBets[1].p_totalBetValue
        end
    end
end

function CodeGameScreenFlamingPompeiiMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if collectLeftCount ~= collectTotalCount then
            self.m_reconnectionFreeMore = true
            --切换展示
            self.m_freeBar:changeFreeSpinByCount()
            self.m_freeBar:setVisible(true)
            self.m_freeBar:runCsbAction("idle_start", false)
            self:changeReelBg("free", false)
        end
    end
    
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFlamingPompeiiMachine:MachineRule_SpinBtnCall()
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
    local moveTime = self.m_lockBonus:playLockSymbolMoveDown()

    return false -- 用作延时点击spin调用
end
-- 转轮开始滚动函数
function CodeGameScreenFlamingPompeiiMachine:beginReel()
    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_reSpinReel:beginMiniReel()
    else
        CodeGameScreenFlamingPompeiiMachine.super.beginReel(self)
    end
end
-- 刷新小块
function CodeGameScreenFlamingPompeiiMachine:updateReelGridNode(node)
    self:addSpineSymbolCsbNode(node)
    self:upDateBonusReward(node)
    self:reSetScatterRewardVisible(node)
    self:removeWildImg(node)
end
function CodeGameScreenFlamingPompeiiMachine:addSpineSymbolCsbNode(_slotsNode)
    -- 默认一个spine上面最多有一个插槽可以挂cocos工程,存放的变量名称保持一致
    local symbolType  = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    local bindNodeCfg = {
        [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = {csbName = "FlamingPompeii_Scatter_Label.csb", slotName = "cishu"},
        [self.SYMBOL_Bonus1]             = {csbName = "FlamingPompeii_Bonus1_Label.csb",  slotName = "wenben"},
        [self.SYMBOL_Bonus2]             = {csbName = "FlamingPompeii_Bonus2_Label.csb",  slotName = "wenben"},
    } 
    local symbolCfg = bindNodeCfg[symbolType]
    if not symbolCfg then
        return
    end
    --判断是否使用静态图+挂点的形式
    if not _slotsNode.m_isLastSymbol then
        _slotsNode:createBonusAddNode()
        return
    elseif _slotsNode.p_symbolImage then
        _slotsNode.p_symbolImage:removeFromParent()
        _slotsNode.p_symbolImage = nil
    end

    local animNode = _slotsNode:checkLoadCCbNode()
    if not animNode.m_slotCsb then
        -- 标准小块用的spine是 animNode.m_spineNode, 临时小块的spine直接是 animNode
        local spineNode = animNode.m_spineNode or (_slotsNode.m_symbolType and animNode) 
        animNode.m_slotCsb = util_createAnimation(symbolCfg.csbName)
        util_spinePushBindNode(spineNode, symbolCfg.slotName, animNode.m_slotCsb)
    end
end
function CodeGameScreenFlamingPompeiiMachine:reSetBonusRewardVisible(_slotsNode)
    --不属于bonus图标
    local symbolType = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    if not self:isFlamingPompeiiBonusSymbol(symbolType) then
        return
    end
    --bonus静态图没有动画节点
    local animNode = _slotsNode:getCCBNode()
    if not animNode then
        return
    end
    --还没添加插槽工程
    local slotCsb  = animNode.m_slotCsb
    if not slotCsb then
        return
    end

    slotCsb:findChild("grand"):setVisible(false)
    slotCsb:findChild("mega"):setVisible(false)
    slotCsb:findChild("major"):setVisible(false)
    slotCsb:findChild("minor"):setVisible(false)
    slotCsb:findChild("mini"):setVisible(false)
    slotCsb:findChild("m_lb_coins"):setVisible(false)
    slotCsb:findChild("grand_2"):setVisible(false)
    slotCsb:findChild("mega_2"):setVisible(false)
    slotCsb:findChild("major_2"):setVisible(false)
    slotCsb:findChild("minor_2"):setVisible(false)
    slotCsb:findChild("mini_2"):setVisible(false)
    slotCsb:findChild("m_lb_coins_2"):setVisible(false)
end
function CodeGameScreenFlamingPompeiiMachine:upDateBonusReward(_slotsNode)
    local symbolType = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    if not self:isFlamingPompeiiBonusSymbol(symbolType) then
        return
    end

    local multi,multiType = 0,""
    if not _slotsNode.m_isLastSymbol or  _slotsNode.p_rowIndex > self.m_iReelRowNum then
        local reSpinReelCfg = self.m_reSpinReel.m_configData
        multi = reSpinReelCfg:getReSpinSymbolRandomMulti()
        self:upDateBonusJackpotAndCoins(_slotsNode, multi)
    else
        local reelPos = self:getPosReelIdx(_slotsNode.p_rowIndex, _slotsNode.p_cloumnIndex)
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            multi,multiType = self:getFreeSpinBonusSymbolMulti(reelPos)
        else
            multi,multiType = self:getReSpinSymbolMulti(reelPos)
        end
        self:upDateSlotsBonusJackpotAndCoins(_slotsNode, multi, multiType)
    end    
end
function CodeGameScreenFlamingPompeiiMachine:reSetScatterRewardVisible(_slotsNode)
    local symbolType = _slotsNode.p_symbolType
    local symbolType = _slotsNode.p_symbolType
    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return
    end
    --没有动画节点
    local animNode = _slotsNode:getCCBNode()
    if not animNode then
        return
    end

    local slotCsb  = animNode.m_slotCsb
    slotCsb:findChild("m_lb_num"):setVisible(false)

    _slotsNode:runAnim("idleframe")
end
function CodeGameScreenFlamingPompeiiMachine:removeWildImg(_slotsNode)
    local symbolType = _slotsNode.p_symbolType
    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return
    end
    -- 提供的静态图滚动时和停轮切换时有差异
    if _slotsNode.m_isLastSymbol and  _slotsNode.p_rowIndex <= self.m_iReelRowNum then
        self:removeSymbolImg(_slotsNode)
    end
end

function CodeGameScreenFlamingPompeiiMachine:getMultiDataByList(_icons, _reelIndex)
    local multi,multiType = 0,""
    for k, v in ipairs(_icons) do
        if v[1] == _reelIndex then
            multi     = v[3]
            multiType = v[4] or ""
            return multi,multiType
        end
    end
    return multi,multiType
end
function CodeGameScreenFlamingPompeiiMachine:getFreeSpinBonusSymbolMulti(_posIndex)
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}

    local multi,multiType = 0,""
    if 0 == multi and "" == multiType then 
        local newIcons = selfData.newstordIcons or {} 
        multi,multiType = self:getMultiDataByList(newIcons, _posIndex)
    end
    if 0 == multi and "" == multiType then 
        local allIcons = selfData.storedIcons or {} 
        multi,multiType = self:getMultiDataByList(allIcons, _posIndex)
    end
    
    return multi,multiType
end
function CodeGameScreenFlamingPompeiiMachine:getReSpinSymbolMulti(_posIndex, _bFinal)
    local multi,multiType = 0,""
    -- 停轮数据
    if 0 == multi and "" == multiType then 
        if not _bFinal then
            local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
            local oldStoredIcons = rsExtraData.oldStoredIcons or {}
            multi,multiType = self:getMultiDataByList(oldStoredIcons, _posIndex)
        end
    end
    -- 最终结果
    if 0 == multi and "" == multiType then 
        local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
        multi,multiType = self:getMultiDataByList(storedIcons, _posIndex)
    end

    return multi,multiType
end
function CodeGameScreenFlamingPompeiiMachine:getReSpinOverSymbolMulti(_posIndex)
    local rsExtraData     = self.m_runSpinResultData.p_rsExtraData
    local baseStoredIcons = rsExtraData.baseStoredIcons
    local multi,multiType = self:getMultiDataByList(baseStoredIcons, _posIndex)

    return multi,multiType
end
--不记录数据方式刷新奖励，包含静态图+工程结构
function CodeGameScreenFlamingPompeiiMachine:upDateBonusJackpotAndCoins(_slotsBonus, _multi)
    local labCsb = nil
    if not labCsb then
        labCsb = _slotsBonus:getBonusAddNode()
    end
    if not labCsb then
        local animNode = _slotsBonus:getCCBNode()
        labCsb  = nil ~= animNode and animNode.m_slotCsb
        --关闭所有奖励可见性
        self:reSetBonusRewardVisible(_slotsBonus)
    end
    local curBet   = globalData.slotRunData:getCurTotalBet()
    local winCoins = curBet * _multi
    if labCsb then
        local labCoins = labCsb:findChild("m_lb_coins")
        labCoins:setVisible(true)
        self:upDateBonusSymbolCoinsLab(labCoins, winCoins)
    end 
end
function CodeGameScreenFlamingPompeiiMachine:upDateSlotsBonusJackpotAndCoins(_slotsBonus, _multi, _multiType, _addMulti)
    local animNode = _slotsBonus:getCCBNode()
    local slotCsb  = animNode.m_slotCsb
    --
    _addMulti = _addMulti or 0
    --节点上保存数值数据和类型数据
    local curBet   = globalData.slotRunData:getCurTotalBet()
    local winCoins = _multi * curBet
    slotCsb.m_bonusWinMultip    = _multi
    slotCsb.m_bonusMultiType    = _multiType
    slotCsb.m_bonusAddWinMultip = _addMulti
    local bJackpot = "" ~= _multiType

    --关闭所有奖励可见性
    self:reSetBonusRewardVisible(_slotsBonus)
    --特殊形态jackpot + addCoins
    local bSpecial = bJackpot and 0 ~= _addMulti
    if bJackpot then
        local jackpotNode = slotCsb:findChild(_multiType)
        jackpotNode:setVisible(true)
        local jackpotNode_2 = slotCsb:findChild(string.format("%s_2", _multiType))
        jackpotNode_2:setVisible(true)
    else
        local labCoins = slotCsb:findChild("m_lb_coins")
        labCoins:setVisible(true)
        --文本适配
        self:upDateBonusSymbolCoinsLab(labCoins, winCoins)
    end
    --两种形态可见性
    slotCsb:findChild("Node_1"):setVisible(not bSpecial)
    slotCsb:findChild("Node_2"):setVisible(bSpecial)
end
function CodeGameScreenFlamingPompeiiMachine:upDateBonusSymbolCoinsLab(_bonusCoinsLab, winCoins)
    local sCoins   = util_formatCoins(winCoins, 3)
    _bonusCoinsLab:setString(sCoins)
    local labInfo = {label=_bonusCoinsLab, sx=1, sy=1, width = 117}
    self:updateLabelSize(labInfo, labInfo.width)
end
function CodeGameScreenFlamingPompeiiMachine:getBonusLabWinData(_slotsBonus)
    local data = {
        multip    = 0,
        multipType = "",
        addMultip    = 0,
    }
    local animNode = _slotsBonus:getCCBNode()
    local slotCsb  = animNode.m_slotCsb
    if slotCsb then
        data.multip     = slotCsb.m_bonusWinMultip or 0
        data.multipType = slotCsb.m_bonusMultiType or ""
        data.addMultip  = slotCsb.m_bonusAddWinMultip or 0
    else
        local symbolType = _slotsBonus.p_symbolType or _slotsBonus.m_symbolType or 999
        local sMsg = strnig.format("[CodeGameScreenFlamingPompeiiMachine:getBonusLabWinData] m_symbolType=(%d)", symbolType)
        error(sMsg)
    end

    return data
end

function CodeGameScreenFlamingPompeiiMachine:spinResultCallFun(param)
    if param[1] == true then
        -- print("CodeGameScreenFlamingPompeiiMachine:spinResultCallFun", cjson.encode(param[2].result))
        if self:getCurrSpinMode() == RESPIN_MODE then
            local spinResult = param[2].result
            self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
            self.m_reSpinReel:netWorkCallFun(param)
        else
            CodeGameScreenFlamingPompeiiMachine.super.spinResultCallFun(self, param)
        end
    else
        CodeGameScreenFlamingPompeiiMachine.super.spinResultCallFun(self, param)
    end
end

function CodeGameScreenFlamingPompeiiMachine:updateNetWorkData()
    --执行一些延时停轮的逻辑
    if self:isTriggerRandomWild() or self:isTriggerRandomBonus() or self:isTriggerRandomScatter() then
        self:playRandomSymbolAnim(function()
            CodeGameScreenFlamingPompeiiMachine.super.updateNetWorkData(self)
        end)
    else
        CodeGameScreenFlamingPompeiiMachine.super.updateNetWorkData(self)
    end
end

--根据关卡玩法重新设置滚动信息 参考 BaseSlots:getLongRunLen
function CodeGameScreenFlamingPompeiiMachine:MachineRule_ResetReelRunData()
    for iCol=1,self.m_iReelColumnNum do
        local scatterRandomCount = self:getRandomSymbolCount(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        local scatterCount = self:getSymbolCountByCol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, iCol-1)
        local curCount = scatterRandomCount + scatterCount
        --触发快滚
        if scatterRandomCount > 0 and curCount >= 2 then
            local reelRunData  = self.m_reelRunInfo[iCol]
            local columnData   = self.m_reelColDatas[iCol]
            local colHeight    = columnData.p_slotColumnHeight
            local longRunIndex = 0
            local runLen = 0
            
            if 1 == iCol then
                local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight
                runLen = 0 + math.floor( reelCount ) * columnData.p_showGridCount
                reelRunData:setReelLongRun(true)
                reelRunData:setNextReelLongRun(true)
                self:creatReelRunAnimation(iCol)
            else
                runLen = self:getLongRunLen(iCol, longRunIndex)
                local lastReelRunData = self.m_reelRunInfo[iCol - 1]
                lastReelRunData:setNextReelLongRun(true)
                reelRunData:setReelLongRun(true)
                reelRunData:setNextReelLongRun(true)
            end
            reelRunData:setReelRunLen(runLen)
            --后面列停止加速移动
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end    
end

--上面未展示行的图标
function CodeGameScreenFlamingPompeiiMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenFlamingPompeiiMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
-- 有特殊需求判断的 重写一下
function CodeGameScreenFlamingPompeiiMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                --scatter如果触发了随机图标那么修改一下落地音效和动画
                if nil ~= self:getRandomSymbol(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex) then
                    return false
                elseif self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    self:getRandomSymbol(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex)
                    return true
                end      
            
            elseif self:isFlamingPompeiiBonusSymbol(_slotNode.p_symbolType) then
                return self:checkSymbolBulingSoundPlay_bonus(_slotNode)
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end
function CodeGameScreenFlamingPompeiiMachine:checkSymbolBulingSoundPlay_bonus(_slotNode)
    local iCol = _slotNode.p_cloumnIndex
    --bonus如果触发了随机图标，那么修改一下落地音效和动画
    if nil ~= self:getRandomSymbol(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex) then   
        return false
    --bonus如果触发了固定图标，那么修改一下落地音效和动画
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE and not self:checkNewBonusLock(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex) then
        return false
    --bonus数量不足
    elseif self:getSymbolCountByCol(self.SYMBOL_Bonus1, iCol) + self:getSymbolCountByCol(self.SYMBOL_Bonus2, iCol) < 5-(self.m_iReelColumnNum-iCol) * 3 then
        return false
    end

    return true
end
function CodeGameScreenFlamingPompeiiMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, nil)
                end
            end
        end
    end
end
function CodeGameScreenFlamingPompeiiMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    CodeGameScreenFlamingPompeiiMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
    -- 原有的bonus图标刷新位置到落地位置并且停止移动
    self.m_lockBonus:playLockSymbolMoveFinish()

    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    for i,_slotNode in ipairs(slotNodeList) do
        local symbolType = _slotNode.p_symbolType
        if self:isFlamingPompeiiBonusSymbol(symbolType) then
            local bBuling = self:checkSymbolBulingSoundPlay_bonus(_slotNode)
            --直接播放呼吸
            if not bBuling then
                self:playBonusSymbolBreathingAnim(_slotNode)
            end
        end
    end
end
function CodeGameScreenFlamingPompeiiMachine:symbolBulingEndCallBack(_slotNode)
    -- _slotNode.m_playBuling = nil

    local symbolType = _slotNode.p_symbolType
    -- local iCol = _slotNode.p_cloumnIndex
    -- local iRow = _slotNode.p_rowIndex

    self:playBonusSymbolBreathingAnim(_slotNode)
end
function CodeGameScreenFlamingPompeiiMachine:playBonusSymbolBreathingAnim(_slotNode)
    local symbolType  = _slotNode.p_symbolType or _slotNode.m_symbolType
    if self:isFlamingPompeiiBonusSymbol(symbolType) then
        _slotNode:runAnim("idleframe2", true)
    end
end

function CodeGameScreenFlamingPompeiiMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        if _iCol == self.m_iReelColumnNum then
            local bulingDatas = self.m_symbolQsBulingSoundArray
            local scKey = tostring(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            if #bulingDatas > 1 and nil ~= bulingDatas[scKey]  then
                self.m_symbolQsBulingSoundArray = {[scKey] = bulingDatas[scKey]}
            end
        end
    end

    return CodeGameScreenFlamingPompeiiMachine.super.playQuickStopBulingSymbolSound(self, _iCol)
end

function CodeGameScreenFlamingPompeiiMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    --随机图标替换到棋盘上
    self:randomSymbolResetReel()
    self.m_randomSymbol:removeRandomSymbol()

    CodeGameScreenFlamingPompeiiMachine.super.slotReelDown(self)
end

function CodeGameScreenFlamingPompeiiMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenFlamingPompeiiMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFlamingPompeiiMachine:addSelfEffect()
    if self:isTriggerLockBonus() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_LockBonus
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_LockBonus 
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFlamingPompeiiMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_LockBonus then
        self:playEffectLockBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BigWinOver then
        self:playEffectBigWinOver(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

--[[
    grand锁定
]]
function CodeGameScreenFlamingPompeiiMachine:changeBetUpDateGrandLock()
    local curBetValue = self.m_curBetValue
    local newBetValue = globalData.slotRunData:getCurTotalBet()
    if self.m_curBetValue ~= newBetValue then
        self.m_curBetValue = newBetValue
        local curLockState = self.m_grandLockBet > curBetValue
        local newLockState = self.m_grandLockBet > newBetValue
        local bEnter  = 0 == curBetValue
        local bChange = curLockState ~= newLockState
        if bEnter or bChange then
            if newLockState then
                self.m_jackpotBar:playLockEffect()
                self.m_jackpotBar:showLockTip()
            else
                self.m_jackpotBar:playUnLockEffect()
                self.m_jackpotBar:hideLockTip()
            end
        end
    end

    self.m_iBetLevel = self:getGrandLockState() and 0 or 1
end
function CodeGameScreenFlamingPompeiiMachine:getGrandLockState()
    local betValue = globalData.slotRunData:getCurTotalBet()
    return self.m_grandLockBet > betValue
end
--[[
    随机图标(消息返回时立刻执行延长假滚)
]]
function CodeGameScreenFlamingPompeiiMachine:playRandomSymbolAnim(_fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_randomSymbol_start)
    --抖动
    self.m_reSpinReel:shakeReelNode({shakeNodeName = {"Spine_bgg"} })
    --spin点击效果
    self.m_guochang2Spine_down:setVisible(true)
    util_spinePlay(self.m_guochang2Spine_down, "actionframe", false)
    util_spineEndCallFunc(self.m_guochang2Spine_down, "actionframe", function()
        self.m_guochang2Spine_down:setVisible(false)
    end)

    self:levelPerformWithDelay(self, 55/30 + 0.4, function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_randomSymbol_down)
        self:playEffectRandomWild()
        self:playEffectRandomBonus()
        self:playEffectRandomScatter()
        
    end)

    local bgSpine2 = self.m_guochang2Spine_down2
    bgSpine2:setVisible(true)
    util_spinePlay(bgSpine2, "actionframe2", false)
    util_spineEndCallFunc(bgSpine2, "actionframe2", function()
        bgSpine2:setVisible(false)
    end)


    --压暗
    self.m_randomSymbol:playReelMaskStartAnim(function()  
    end)
    -- 岩浆飞下来 - 延时 - 图标遮挡效果出现 - 图标出现+落地
    local animTime = 55/30 + 0.4 + 21/60 + 30/30
    self:levelPerformWithDelay(self, animTime, function()
        self.m_randomSymbol:playReelMaskOverAnim(_fun)
    end) 
end
function CodeGameScreenFlamingPompeiiMachine:getRandomSymbol(_iCol, _iRow)
    local children = self.m_randomSymbol:getChildren()
    for i,_symbol in ipairs(children) do
        if _symbol.p_cloumnIndex == _iCol and _symbol.p_rowIndex == _iRow then
            return _symbol
        end
    end
    return nil
end
function CodeGameScreenFlamingPompeiiMachine:getBonusRandomSymbolType(_iCol, _iRow)
    local symbolType  = self.SYMBOL_Bonus1
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local reelIndex   = self:getPosReelIdx(_iRow, _iCol)
    for i,_bonusData in ipairs(storedIcons) do
        if reelIndex == _bonusData[1] then
            symbolType = _bonusData[2]
        end
    end
    return symbolType
end
function CodeGameScreenFlamingPompeiiMachine:randomSymbolResetReel()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --wild
    local wildPos  = selfData.wild_pos or {}
    for i,_iPos in ipairs(wildPos) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        self:changeFlamingPompeiiSlotsNodeType(slotsNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
    end
    --bonus
    local randomBonus = selfData.bonus_pos or {}
    for i,_iPos in ipairs(randomBonus) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local bonusType = self:getBonusRandomSymbolType(fixPos.iY, fixPos.iX)
        self:changeFlamingPompeiiSlotsNodeType(slotsNode, bonusType)
        --提层
        local parent = slotsNode:getParent()
        if parent ~= self.m_clipParent then
            slotsNode = util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, bonusType, 0)
        end
        self:upDateBonusReward(slotsNode)
        self:playBonusSymbolBreathingAnim(slotsNode)
    end
    --scatter
    local randomScatter = selfData.scatter_pos or {}
    for i,_iPos in ipairs(randomScatter) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        self:changeFlamingPompeiiSlotsNodeType(slotsNode, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        --提层
        local parent = slotsNode:getParent()
        if parent ~= self.m_clipParent then
            slotsNode = util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER, 0)
        end
    end
end
--[[
    随机wild
]]
function CodeGameScreenFlamingPompeiiMachine:isTriggerRandomWild()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildPos  = selfData.wild_pos or {}
    return #wildPos > 0
end
function CodeGameScreenFlamingPompeiiMachine:playEffectRandomWild()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildPos  = selfData.wild_pos or {}
    self.m_randomSymbol:addRandomSymbolWild(wildPos)
end
--[[
    随机bonus
]]
function CodeGameScreenFlamingPompeiiMachine:isTriggerRandomBonus()
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local randomBonus = selfData.bonus_pos or {}
    return #randomBonus > 0
end
function CodeGameScreenFlamingPompeiiMachine:playEffectRandomBonus()
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local randomBonus = selfData.bonus_pos or {}
    self.m_randomSymbol:addRandomSymbolBonus(randomBonus)
end
--[[
    随机scatter
]]
function CodeGameScreenFlamingPompeiiMachine:isTriggerRandomScatter()
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local randomScatter = selfData.scatter_pos or {}
    return #randomScatter > 0
end
function CodeGameScreenFlamingPompeiiMachine:playEffectRandomScatter()
    local selfData      = self.m_runSpinResultData.p_selfMakeData or {}
    local randomScatter = selfData.scatter_pos or {}
    self.m_randomSymbol:addRandomSymbolScatter(randomScatter)
end
--[[
    free-固定bonus
]]
function CodeGameScreenFlamingPompeiiMachine:isTriggerLockBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local newIcons = selfData.newstordIcons or {} 
    return #newIcons > 0
end
function CodeGameScreenFlamingPompeiiMachine:playEffectLockBonus(_fun)
    local bSound = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local newIcons = selfData.newstordIcons
    --展示reel条背景
    for i,_data in ipairs(newIcons) do
        local iPos   = _data[1]
        local fixPos = self:getRowAndColByPos(iPos) 
        if not bSound then
            bSound = not self.m_lockBonusReelBg:getLockBonusReelBgShowState(fixPos.iY)
        end
        self.m_lockBonus:showLockBonusReelBg(fixPos.iY)
        --固定bonus
        local lockBonus = self.m_lockBonus:createLockSymbol(fixPos.iY, fixPos.iX, _data[2])
        self:playBonusSymbolBreathingAnim(lockBonus.animNode)
    end
    if bSound then
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_lockBonusReelBg_start)
    end

    local animTime = 21/60
    self:levelPerformWithDelay(self, animTime, function()
        _fun()
    end) 
end
function CodeGameScreenFlamingPompeiiMachine:checkNewBonusLock(_iCol, _iRow)
    local reelIndex = self:getPosReelIdx(_iRow, _iCol)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local newIcons  = selfData.newstordIcons or {} 
    for i,_data in ipairs(newIcons) do
        local iPos   = _data[1]
        if iPos == reelIndex then
            return true
        end
    end

    return false
end
function CodeGameScreenFlamingPompeiiMachine:reconnectShowLockBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local allIcons = selfData.storedIcons or {} 
    for i,_iconData in ipairs(allIcons) do
        local iPos      = _iconData[1]
        local fixPos    = self:getRowAndColByPos(iPos) 
        local lockBonus = self.m_lockBonus:createLockSymbol(fixPos.iY, fixPos.iX,  _iconData[2])
        self:playBonusSymbolBreathingAnim(lockBonus.animNode)
        self.m_lockBonus:showLockBonusReelBg(fixPos.iY)
    end
end
--[[
    大赢结束回调
]]
function CodeGameScreenFlamingPompeiiMachine:playEffectBigWinOver(_fun)
    -- 重置背景音乐
    self:resetMusicBg()

    _fun()
end
--[[
    FreeSpin相关
]]
function CodeGameScreenFlamingPompeiiMachine:showEffect_FreeSpin(effectData)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and self.m_reconnectionFreeMore then
        self.m_reconnectionFreeMore = false
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- !!!不使用连线列表
    -- local lineLen = #self.m_reelResultLines
    -- local scatterLineValue = nil
    -- for i = 1, lineLen do
    --     local lineValue = self.m_reelResultLines[i]
    --     if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
    --         scatterLineValue = lineValue
    --         lineValue.iLineSymbolNum = #lineValue.vecValidMatrixSymPos
    --         table.remove(self.m_reelResultLines, i)
    --         break
    --     end
    -- end
    -- 播放触发动画
    local delayTime = 0
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        if _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local parent = _slotsNode:getParent()
            if parent ~= self.m_clipParent then
                util_setSymbolToClipReel(self,_slotsNode.p_cloumnIndex, _slotsNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
            end
        end
    end)
    
    -- 播放提示时播放音效 放在打开sc图标时播放
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        -- gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_scatterTrigger_2)
    else
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- 停掉连线
        self:stopLinesWinSound()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_scatterTrigger_1)
    end
    --展示free弹板
    self:levelPerformWithDelay(self, delayTime, function()
        self:showFreeSpinView(effectData)
    end)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end
-- 翻开sc图标展示次数
function CodeGameScreenFlamingPompeiiMachine:playOpenScatterSymbolAnim(_fun)
    local selfData   = self.m_runSpinResultData.p_selfMakeData
    local scatterPos = selfData.sc_icons or {}
    table.sort(scatterPos, function(_scatterDataA, _scatterDataB)
        local fixPosA    = self:getRowAndColByPos(_scatterDataA[2]) 
        local fixPosB    = self:getRowAndColByPos(_scatterDataB[2]) 
        if fixPosA.iY ~= fixPosB.iY then
            return fixPosA.iY < fixPosB.iY
        end
        if fixPosA.iX ~= fixPosB.iX then
            return fixPosA.iX > fixPosB.iX
        end
        return false
    end)
    local interval = 0.3
    for i,_scatterData in ipairs(scatterPos) do
        local iPos = _scatterData[2]
        local fixPos    = self:getRowAndColByPos(iPos) 
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        --强制切换
        self:changeFlamingPompeiiSlotsNodeType(slotsNode, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        --提层
        local parent = slotsNode:getParent()
        if parent ~= self.m_clipParent then
            slotsNode = util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER, REEL_SYMBOL_ORDER.REEL_ORDER_MASK)
        end
        --移除静态图
        self:removeSymbolImg(slotsNode)
        --刷新次数
        local animNode = slotsNode:getCCBNode()
        local slotCsb  = animNode.m_slotCsb
        local labTimes = slotCsb:findChild("m_lb_num")
        local sTimes = string.format("%d", _scatterData[3])
        labTimes:setString(sTimes)
        self:updateLabelSize({label=labTimes, sx=0.75, sy=0.75}, 324)
        labTimes:setVisible(true)

        self:levelPerformWithDelay(self, (i - 1) * interval, function()
            gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_scatter_open)
            slotsNode:runAnim("switch", false)
        end)
    end
    local animTime = (#scatterPos-1 ) * interval + 18/60 + 1
    self:levelPerformWithDelay(self, animTime, function()
        _fun()
    end)
end
function CodeGameScreenFlamingPompeiiMachine:removeSymbolImg(_slotsNode)
    --移除静态图
    _slotsNode:checkLoadCCbNode()
    if _slotsNode.p_symbolImage ~= nil and _slotsNode.p_symbolImage:getParent() ~= nil then
        _slotsNode.p_symbolImage:removeFromParent()
        _slotsNode.p_symbolImage = nil
    end
end
--开始弹板
function CodeGameScreenFlamingPompeiiMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeMoreView)
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeTimes_add)
                self.m_freeBar:changeFreeSpinByCount()
                self.m_freeBar:playAddTimesAnim(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end,true)
        else
            gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeStartView_start)
            local freeStartView = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeGuoChang)
                self:playFreeSpinGuoChang(
                    function()
                        --切换展示
                        self.m_freeBar:changeFreeSpinByCount()
                        self.m_freeBar:playStartAnim()
                        self.m_freeBar:setVisible(true)
                        self.m_lockBonus:resetUi()
                        self:changeReelBg("free", true)
                    end,
                    function()
                        self:triggerFreeSpinCallFun()

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end)
            freeStartView.m_btnTouchSound = FlamingPompeiiPublicConfig.sound_FlamingPompeii_commonClick
            freeStartView:setBtnClickFunc(function()
                gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeStartView_over)
            end)
            --光
            local lightCsb = util_createAnimation("Socre_FlamingPompeii_light.csb")
            freeStartView:findChild("Node_light"):addChild(lightCsb)
            lightCsb:runCsbAction("idle", true)
        end
    end

    self:playOpenScatterSymbolAnim(function()
        showFSView()    
    end)
end
function CodeGameScreenFlamingPompeiiMachine:playFreeSpinGuoChang(_fun1, _fun2)
    self.m_guochangSpine:setVisible(true)
    util_spinePlay(self.m_guochangSpine, "actionframe", false)

    self:runCsbAction("actionframe", false)
    self.m_gameBg:findChild("Node_switch"):setVisible(true)
    self.m_gameBg:runCsbAction("actionframe", false)
    -- 第66帧切换显示
    self:levelPerformWithDelay(self, 66/60, function()
        _fun1()
        self:levelPerformWithDelay(self, 136/60, function()
            self.m_gameBg:findChild("Node_switch"):setVisible(false)
            self.m_guochangSpine:setVisible(false)
            _fun2()
        end)
    end)
end

--结束弹板
function CodeGameScreenFlamingPompeiiMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeOverView_start)
    
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    local strCoins = util_formatCoins(fsWinCoins, 50)
    local fsCount    = self.m_runSpinResultData.p_freeSpinsTotalCount
    local view = self:showFreeSpinOver( 
        strCoins, 
        fsCount,
        function()
            gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_backGuoChang)
            self:playFreeSpinOverGuoChang(
                function()
                    --切换展示
                    self.m_freeBar:playOverAnim(function()
                        self.m_freeBar:setVisible(false)
                    end)
                    self:changeReelBg("base")
                    self.m_lockBonus:removeAllLockSymbol()
                    self:initFreeSpinOverReel()
                end,
                function()
                    self:triggerFreeSpinOverCallFun()
                    if self:getGrandLockState() then
                        self.m_jackpotBar:showLockTip()
                    end
                end
            )
        end
    )
    view.m_btnTouchSound = FlamingPompeiiPublicConfig.sound_FlamingPompeii_commonClick
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_freeOverView_over)
    end)
    view:updateLabelSize({label=view:findChild("m_lb_coins"), sx=1.03, sy=1}, 576)
    view:updateLabelSize({label=view:findChild("m_lb_num"),   sx=1, sy=1}, 52)
end
function CodeGameScreenFlamingPompeiiMachine:playFreeSpinOverGuoChang(_fun1, _fun2)
    --抖动
    self.m_reSpinReel:shakeReelNode({shakeNodeName = {"Spine_bgg"} })

    self.m_guochang2Spine_down:setVisible(true)
    self.m_guochang2Spine_up:setVisible(true)
    util_spinePlay(self.m_guochang2Spine_down, "actionframe", false)
    util_spinePlay(self.m_guochang2Spine_up, "actionframe", false)

    -- 第126帧切换显示 210
    self:levelPerformWithDelay(self, 126/60, function()
        _fun1()
        self:levelPerformWithDelay(self, 84/60, function()
            self.m_guochang2Spine_down:setVisible(false)
            self.m_guochang2Spine_up:setVisible(false)
            _fun2()
        end)
    end)
end
function CodeGameScreenFlamingPompeiiMachine:initFreeSpinOverReel()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local allIcons = selfData.storedIcons or {} 
    for i,_data in ipairs(allIcons) do
        local iPos       = _data[1]
        local fixPos     = self:getRowAndColByPos(iPos) 
        local slotsNode  = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        local symbolType = _data[2]
        self:changeFlamingPompeiiSlotsNodeType(slotsNode, symbolType)
        self:upDateBonusReward(slotsNode)
        self:playBonusSymbolBreathingAnim(slotsNode)
    end
end
function CodeGameScreenFlamingPompeiiMachine:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    self:postFreeSpinOverTriggerBigWIn(_coins)
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    local winType = self:isTriggerCookieCrunchBigWin(globalData.slotRunData.lastWinCoin)
    if winType == WinType.Normal then
        self:resetMusicBg()
    else
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BigWinOver
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BigWinOver 
        self:sortGameEffects()
    end
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end
-- 参考 BaseMachine:addLastWinSomeEffect()
function CodeGameScreenFlamingPompeiiMachine:isTriggerCookieCrunchBigWin(_winCoins, _betCoins)
    local betCoins   = _betCoins or globalData.slotRunData:getCurTotalBet()
    local multi      = _winCoins / betCoins 

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate

    local winType = WinType.Normal

    if multi >= iEpicWinLimit then
        winType = WinType.EpicWin
    elseif multi >= iMegaWinLimit then
        winType = WinType.MegaWin
    elseif multi >= iBigWinLimit then
        winType = WinType.BigWin
    end

    return winType
end
--[[
    reSpin相关
]]
--reSpin触发动画
function CodeGameScreenFlamingPompeiiMachine:playReSpinStartActionFrame(_fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bonusTrigger)
    
    --固定图标转移到棋盘上
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local allIcons = selfData.storedIcons or {} 
    for i,_bonusData in ipairs(allIcons) do
        local fixPos     = self:getRowAndColByPos(_bonusData[1])
        local symbolType = _bonusData[2]
        local slotsNode  = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        --切换图标
        if slotsNode.p_symbolImage then
            slotsNode.p_symbolImage:removeFromParent()
            slotsNode.p_symbolImage = nil
        end
        local symbolName = self:getSymbolCCBNameByType(self,symbolType)
        slotsNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
        slotsNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,symbolType))
        slotsNode.p_symbolType = symbolType
        slotsNode:runAnim("idleframe", false)
        slotsNode = util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, symbolType, REEL_SYMBOL_ORDER.REEL_ORDER_MASK)
        self:addSpineSymbolCsbNode(slotsNode)

        local reelPos = self:getPosReelIdx(fixPos.iX, fixPos.iY)
        local multi,multiType = self:getFreeSpinBonusSymbolMulti(reelPos)
        self:upDateSlotsBonusJackpotAndCoins(slotsNode, multi, multiType)
    end
    --固定bonus全部取消
    self.m_lockBonus:resetUi()

    --棋盘上图标触发
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        local slotsNode  = _slotsNode
        local symbolType = slotsNode.p_symbolType
        if self:isFlamingPompeiiBonusSymbol(symbolType) then
            --提层
            local parent = _slotsNode:getParent()
            if parent ~= self.m_clipParent then
                slotsNode = util_setSymbolToClipReel(self,_slotsNode.p_cloumnIndex, _slotsNode.p_rowIndex, symbolType, REEL_SYMBOL_ORDER.REEL_ORDER_MASK)
            end
            slotsNode:runAnim("actionframe", false, function()
                self:playBonusSymbolBreathingAnim(slotsNode)
            end)
        end
    end)

    local animTime = 60/30
    self:levelPerformWithDelay(self, animTime, _fun)
end
function CodeGameScreenFlamingPompeiiMachine:playReSpinStartMaskAnim(_bShow, _fun)
    local reSpinStartMask = self:findChild("Panel_reSpinStart")
    reSpinStartMask:stopAllActions()
    if _bShow then
        reSpinStartMask:setOpacity(0)
        reSpinStartMask:setVisible(true)
    end
    local actList = {}
    if _bShow then
        table.insert(actList, cc.FadeIn:create(0.2))
    else
        table.insert(actList, cc.CallFunc:create(function()
            reSpinStartMask:setVisible(false)
        end))
    end
    if nil ~= _fun then
        table.insert(actList, cc.CallFunc:create(function()
            _fun()
        end))
    end
    
    reSpinStartMask:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenFlamingPompeiiMachine:showRespinView(effectData)
    local rsExtraData = clone(self.m_runSpinResultData.p_rsExtraData)
    local triggerData = {}
    triggerData.reSpinCount       = self.m_runSpinResultData.p_reSpinCurCount
    triggerData.reSpinTotalCount  = self.m_runSpinResultData.p_reSpinsTotalCount
    triggerData.rsExtraData       = rsExtraData
    triggerData.reSpinStoredIcons = self.m_runSpinResultData.p_storedIcons
    self.m_reSpinReel:initTriggerReel(triggerData)
    self.m_bSpecialReSpin = rsExtraData.respinkind == "special"

    --改变一些reSpin状态数据 -- triggerReSpinCallFun 里面的内容
    self:setCurrSpinMode(RESPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_specialReels = true
    self:clearWinLineEffect()
    --free不会清空底栏
    if not self.m_bProduceSlots_InFreeSpin then
        --base下进入的reSpin判断是否触发了结算一次的buff回复底栏金币
        local reSpinWinCoins = self.m_runSpinResultData.p_resWinCoins or 0
        self:setLastWinCoin(0)
        self:updateBottomUICoins(0, reSpinWinCoins, nil, false)
        if 0 == reSpinWinCoins then
            self.m_bottomUI:checkClearWinLabel()
        end
    end
    --scatter放回棋盘
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        local symbolType = _slotsNode.p_symbolType
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self:putSymbolBackToPreParent(_slotsNode)
        end
    end)

    --遮罩
    self:playReSpinStartMaskAnim(true, function()
        --触发动画
        self:playReSpinStartActionFrame(function()
            --弹板
            self:showReSpinStart(function()
                gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_reSpinGuoChang)
                --过场
                self:playFreeSpinOverGuoChang(
                    --展示界面
                    function()
                        --切换展示
                        --重置棋盘行数和坐标
                        self.m_reSpinReel:setReSpinReelPosY(self.m_reSpinReel.m_reSpinRow, false)
                        self.m_reSpinReel:playReSpinUiStartAnim()
                        self.m_reSpinReel:setVisible(true)
                        self:changeReelBg("reSpin")
                        if rsExtraData.rows == self.m_reSpinReel.m_iReelRowNum then
                            self.m_jackpotBar:setShowState("reSpin")
                        end
                        self:findChild("Node_sp_reel"):setVisible(false)
                        self:playReSpinStartMaskAnim(false)
                    end,
                    function()
                        self:changeReSpinBgMusic()
                        self.m_reSpinReel:readyReSpinMove()
                    end
                )
            end)
        end)
    end)
end
function CodeGameScreenFlamingPompeiiMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    func()
end

-- 展示jackpot弹板
function CodeGameScreenFlamingPompeiiMachine:showJackpotView(_jackpotName, _coins, _fun)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_jackpotView_start)

    local jpIndex = self.JackpotNameToIndex[_jackpotName]
    local jackpotData = {
        machine = self,
        index = jpIndex,
        coins = _coins
    }
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(jackpotData.coins, jackpotData.index)
    local jackPotWinView = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiJackPotView", jackpotData)
    jackPotWinView:setOverAniRunFunc(_fun)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData()
end

function CodeGameScreenFlamingPompeiiMachine:showFlamingPompeiiReSpinOver()
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_reSpinOverView_start)

    --重置reSpin的一些状态
    self:resetReSpinMode()
    local reSpinWinCoins = self.m_runSpinResultData.p_resWinCoins
    self:checkFeatureOverTriggerBigWin(reSpinWinCoins, GameEffect.EFFECT_RESPIN_OVER)
    local reSpinOverView = self:showReSpinOver(reSpinWinCoins, function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_backGuoChang)
        self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        local currSpinMode = self:getCurrSpinMode()
        local bFree = currSpinMode == FREE_SPIN_MODE
        --过场
        self:playFreeSpinOverGuoChang(
            function()
                --切换展示
                self.m_reSpinReel:setVisible(false)
                self.m_reSpinReel:playReSpinUiOverAnim()
                if bFree then
                    self:changeReelBg("free")
                else
                    self:changeReelBg("base")
                end
                self.m_jackpotBar:setShowState("base")

                local rsExtraData = self.m_runSpinResultData.p_rsExtraData
                local baseReels   = rsExtraData.baseReels            
                self:initReSpinOverReel(baseReels, 4, false)
                self:findChild("Node_sp_reel"):setVisible(true)
            end,
            function()
                if not self.m_bProduceSlots_InFreeSpin then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                end
                self:resetMusicBg()
                self:playGameEffect()
                if not bFree and self:getGrandLockState() then
                    self.m_jackpotBar:showLockTip()
                end
            end
        ) 
    end)
    reSpinOverView.m_btnTouchSound = FlamingPompeiiPublicConfig.sound_FlamingPompeii_commonClick
    reSpinOverView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_reSpinOverView_over)
    end)
    self:updateLabelSize({label=reSpinOverView:findChild("m_lb_coins"), sx=1.03, sy=1}, 576)
end
--[[
    _reelRow = 5, 当前解锁行数为5
]]
function CodeGameScreenFlamingPompeiiMachine:initReSpinOverReel(_reels, _reelRow, _bReconnection)
    local rsExtraData   = self.m_runSpinResultData.p_rsExtraData
    local startReelPos  = (_reelRow - self.m_iReelRowNum) * 5
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        local lineIndex  = _reelRow - (_iRow - 1)
        local lineData   = _reels[lineIndex]
        local symbolType = lineData[_iCol]

        self:changeFlamingPompeiiSlotsNodeType(_slotsNode, symbolType)
        if self:isFlamingPompeiiBonusSymbol(symbolType) then
            local reelPos = startReelPos + self:getPosReelIdx(_iRow, _iCol)
            local multi,multiType = 0,""
            if _bReconnection then
                multi,multiType = self:getReSpinSymbolMulti(reelPos, true)
            else
                multi,multiType = self:getReSpinOverSymbolMulti(reelPos)
            end
            self:upDateSlotsBonusJackpotAndCoins(_slotsNode, multi, multiType)
            self:playBonusSymbolBreathingAnim(_slotsNode)
        end
    end)
end

--[[
    一些工具
]]
function CodeGameScreenFlamingPompeiiMachine:getSymbolCountByCol(_symbolType, _iCol)
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
function CodeGameScreenFlamingPompeiiMachine:getRandomSymbolCount(_symbolType)
    local count = 0
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}

    if self:isFlamingPompeiiCommonBonusSymbol(_symbolType) then
        local randomBonus = selfData.bonus_pos or {}
        for i,_iPos in ipairs(randomBonus) do
            local fixPos     = self:getRowAndColByPos(_iPos) 
            local symbolType = self:getBonusRandomSymbolType(fixPos.iY, fixPos.iX)
            if symbolType == _symbolType then
                count = count + 1
            end
        end
    elseif _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local randomScatter = selfData.scatter_pos or {}
        count = #randomScatter
    end
    
    return count
end


function CodeGameScreenFlamingPompeiiMachine:isFlamingPompeiiBonusSymbol(_symbolType)
    local bool = _symbolType == self.SYMBOL_Bonus1 or _symbolType == self.SYMBOL_Bonus2
    return bool
end
function CodeGameScreenFlamingPompeiiMachine:isFlamingPompeiiCommonBonusSymbol(_symbolType)
    local bool = _symbolType == self.SYMBOL_Bonus2
    return bool
end

function CodeGameScreenFlamingPompeiiMachine:changeFlamingPompeiiSlotsNodeType(_slotsNode, _symbolType)
    self:changeSymbolType(_slotsNode, _symbolType)
    --添加spine挂点
    _slotsNode.m_isLastSymbol = true
    self:addSpineSymbolCsbNode(_slotsNode)
    --静帧
    _slotsNode:runAnim("idleframe", false)
end
-- 延时
function CodeGameScreenFlamingPompeiiMachine:levelPerformWithDelay(_parent, _time, _fun)
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
--创建临时小块
function CodeGameScreenFlamingPompeiiMachine:createFlamingPompeiiTempSymbol(_symbolType, _initData)
    --[[
        _initData = {
            iCol = 1,
            iRow = 1,
        }
    ]]
    local tempSymbol = util_createView("CodeFlamingPompeiiSrc.FlamingPompeiiTempSymbol", {self})
    tempSymbol:changeSymbolCcb(_symbolType)
    --初始化一些属性
    tempSymbol.m_isLastSymbol = true
    if nil ~= _initData.iCol then
        tempSymbol.p_cloumnIndex = _initData.iCol
    end
    if nil ~= _initData.iRow then
        tempSymbol.p_rowIndex = _initData.iRow
    end

    self:addSpineSymbolCsbNode(tempSymbol)
    return tempSymbol
end
--获取底栏金币
function CodeGameScreenFlamingPompeiiMachine:getnFlamingPompeiiCurBottomWinCoins()
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
function CodeGameScreenFlamingPompeiiMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end
-- 循环处理轮盘小块
function CodeGameScreenFlamingPompeiiMachine:baseReelSlotsNodeForeach(fun)
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
--[[
    解决底层接口不存在问题
]]
function CodeGameScreenFlamingPompeiiMachine:changeSymbolType(symbolNode,symbolType)
    if nil ~= CodeGameScreenFlamingPompeiiMachine.super.changeSymbolType then
        CodeGameScreenFlamingPompeiiMachine.super.changeSymbolType(self, symbolNode,symbolType)
    else
        if symbolNode then
            if symbolNode.p_symbolImage then
                symbolNode.p_symbolImage:removeFromParent()
                symbolNode.p_symbolImage = nil
            end
    
            local symbolName = self:getSymbolCCBNameByType(self,symbolType)
            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
            symbolNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self,symbolType))
    
            symbolNode.p_symbolType = symbolType
    
            self:putSymbolBackToPreParent(symbolNode)
        end
    end
end
function CodeGameScreenFlamingPompeiiMachine:isSpecialSymbol(symbolType)
    if nil ~= CodeGameScreenFlamingPompeiiMachine.super.isSpecialSymbol then
        CodeGameScreenFlamingPompeiiMachine.super.isSpecialSymbol(self, symbolType)
    else
        if not self.m_configData.p_specialSymbolList then
            return false
        end
        for i,v in ipairs(self.m_configData.p_specialSymbolList) do
            if v == symbolType then
                return true
            end
        end
        return false
    end
end
function CodeGameScreenFlamingPompeiiMachine:putSymbolBackToPreParent(symbolNode)
    if nil ~= CodeGameScreenFlamingPompeiiMachine.super.putSymbolBackToPreParent then
        CodeGameScreenFlamingPompeiiMachine.super.putSymbolBackToPreParent(self, symbolNode)
    else
        if symbolNode and symbolNode.p_symbolType then
            local parentData = self.m_slotParents[symbolNode.p_cloumnIndex]
            if not symbolNode.m_baseNode then
                symbolNode.m_baseNode = parentData.slotParent
            end
    
            if not symbolNode.m_topNode then
                symbolNode.m_topNode = parentData.slotParentBig
            end
    
            symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    
            local zOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
            symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
            local isInTop = self:isSpecialSymbol(symbolNode.p_symbolType)
            symbolNode.m_isInTop = isInTop
            symbolNode:putBackToPreParent()
        end
    end
    
end
--[[
    重写
]]

--设置bonus scatter 层级
function CodeGameScreenFlamingPompeiiMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenFlamingPompeiiMachine.super.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_Bonus1 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_Bonus2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end

    return order
end

function CodeGameScreenFlamingPompeiiMachine:getBottomUINode( )
    return "CodeFlamingPompeiiSrc.FlamingPompeiiBoottomUiView"
end

function CodeGameScreenFlamingPompeiiMachine:scaleMainLayer()
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
                mainScale = mainScale * 0.99
                -- mainPosY  = 10
            --1.5
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.01
            --1.33
            elseif display.height / display.width >= 1024/768 then
                mainScale = mainScale * 1.05
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
function CodeGameScreenFlamingPompeiiMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound(FlamingPompeiiPublicConfig.sound_FlamingPompeii_bigWin)
    --先播大赢动画
    self.m_bigWinCsb:setVisible(true)
    for i=1,3 do
        local particleName = string.format("Particle_%d", i)
        local particleNode = self.m_bigWinCsb:findChild(particleName)
        particleNode:setOpacity(255)
        particleNode:stopSystem()
        particleNode:setPositionType(0)
        particleNode:setDuration(-1)
        particleNode:resetSystem()
    end
    self.m_bigWinSpineDown:setVisible(true)
    util_spinePlay(self.m_bigWinSpineDown, "actionframe_bigwin2", false)
    util_spineEndCallFunc(self.m_bigWinSpineDown, "actionframe_bigwin2", function()
        self.m_bigWinSpineDown:setVisible(false)
    end)

    --抖动
    local shakeTimes = 10
    local shakeOnceTime = 60/30 / shakeTimes
    self.m_reSpinReel:shakeReelNode({shakeTimes    = shakeTimes, shakeOnceTime = shakeOnceTime})
    
    self:levelPerformWithDelay(self, 51/30, function()
        for i=1,3 do
            local particleNode = self.m_bigWinCsb:findChild(string.format("Particle_%d", i))
            particleNode:stopSystem()
            util_setCascadeOpacityEnabledRescursion(particleNode, true)
            particleNode:runAction(cc.FadeOut:create(0.5))
        end

        if type(_func) == "function" then
            _func()
        end
    end)
end

return CodeGameScreenFlamingPompeiiMachine