---
-- island li
-- 2019年1月26日
-- CodeGameScreenCatchMonstersMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "CatchMonstersPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenCatchMonstersMachine = class("CodeGameScreenCatchMonstersMachine", BaseNewReelMachine)

CodeGameScreenCatchMonstersMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenCatchMonstersMachine.SYMBOL_WHEEL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 --94
CodeGameScreenCatchMonstersMachine.SYMBOL_EXTRA_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 --95
CodeGameScreenCatchMonstersMachine.SYMBOL_NULL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 --100

-- 自定义动画的标识
CodeGameScreenCatchMonstersMachine.KUANG_GET_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- free玩法中 出现转盘图标 收集动画
CodeGameScreenCatchMonstersMachine.FREE_COLLECT_NUMS = GameEffect.EFFECT_SELF_EFFECT + 1 -- free玩法中 出现转盘图标 收集动画
CodeGameScreenCatchMonstersMachine.BIG_SPIN_OVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 191 -- BIGSPIN 结束弹板
CodeGameScreenCatchMonstersMachine.FEATURE_OVER_BET_CHANGE_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 300 -- 玩法结束 改变spin按钮状态
CodeGameScreenCatchMonstersMachine.BIGSPIN_AGAIN_SPIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 301 -- BIGSPIN 滚出来加次数

-- 构造函数
function CodeGameScreenCatchMonstersMachine:ctor()
    CodeGameScreenCatchMonstersMachine.super.ctor(self)

    self.m_iBetLevel = 0 -- bet等级
    self.m_specialBetMulti = {}
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.m_winKuangScaleX = 1 -- win框的默认缩放比例
    self.m_winKuangScaleY = 1 -- win框的默认缩放比例
    self.m_isDuanxian = false
    self.m_jackpotIndex = 0
    self.m_kuangMoveCurIndex = 0
    self.m_kuangReelsListX = {1, 2, 3, 4, 5} -- 移动框X轴 占不同行数 对应的缩放尺寸
    self.m_kuangReelsListY = {1, 2, 3, 4} -- -- 移动框Y轴 占不同列数 对应的缩放尺寸
    self.m_kuangParticle = {} --移动框四周的粒子
    self.m_liziScale = 0.4 -- 粒子的缩放比例
    self.m_isLongRun = false -- base下 移动框变成最大时 棋盘滚动要比正常更久
    self.m_bigWinYuGaoSoundIndex = 1
    self.m_isMoveEnd = false -- 框移动是否结束
    self.m_hSymbolBulingSoundList = {false, false, false, false, false}
    --init
    self:initGame()
end

function CodeGameScreenCatchMonstersMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("CatchMonstersConfig.csv", "LevelCatchMonstersConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCatchMonstersMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CatchMonsters"  
end

function CodeGameScreenCatchMonstersMachine:getBottomUINode()
    return "CatchMonstersSrc.CatchMonstersGameBottomNode"
end

function CodeGameScreenCatchMonstersMachine:initUI()

    --win框 层
    self.m_effectNode = self:findChild("Node_winKuang")

    --飞 层
    self.m_flyNode = cc.Node:create()
    self:addChild(self.m_flyNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 101)

    -- top框
    self.m_topKuangNode = util_createAnimation("CatchMonsters_topDes.csb")
    self:findChild("top_des"):addChild(self.m_topKuangNode)
    self.m_topKuangNode:runCsbAction("idle", true)

    -- 引入控制插件
    self.m_longRunControl = util_createView("CatchMonstersLongRunControl",self)

    self.m_bonusWheelView = util_createView("CatchMonstersSrc.CatchMonstersWheelView", {machine = self})
    self:findChild("Node_wheel"):addChild(self.m_bonusWheelView)
    self.m_bonusWheelView:setVisible(false)

    -- free玩法中 转盘数量
    self.m_freeWheelNumsNode = util_createAnimation("CatchMonsters_jiaobiao_wheel.csb")
    self:findChild("wheel_right"):addChild(self.m_freeWheelNumsNode)
    self.m_freeWheelNumsNode:setVisible(false)

    -- 点击高低bet按钮
    self.m_controlBetView = util_createView("CatchMonstersSrc.CatchMonstersControlBetView", {machine = self})
    self:findChild("Node_choosebet"):addChild(self.m_controlBetView)
    self:showBetChangeDark(false)

    -- 高低bet界面
    self.m_chooseBetView = util_createView("CatchMonstersSrc.CatchMonstersChooseBetView", {machine = self})
    self:addChild(self.m_chooseBetView, GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 2)
    self.m_chooseBetView:setVisible(false)
    self.m_chooseBetView:findChild("root"):setScale(self.m_machineRootScale)

    -- 移动框 最大的时候 动画
    self.m_moveKuangMaxNode = util_createAnimation("CatchMonsters_win_tx.csb")
    self:findChild("Node_bigspin"):addChild(self.m_moveKuangMaxNode)
    self.m_moveKuangMaxNode:setVisible(false)

    self:setReelBg(1)
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView()

    -- 移动框
    self.m_winKuangNode = ccui.Scale9Sprite:create("CatchMonstersCommon/CatchMonsters_reel_98.png")
    self.m_winKuangNode:setCapInsets(cc.rect(72, 55, 2, 2))
    self.m_winKuangNode:setContentSize(cc.size(170*self.m_kuangReelsListX[1]+36, 118*self.m_kuangReelsListY[1]+36))
    self.m_winKuangNode:setAnchorPoint(0.5, 0.5)
    self.m_winKuangNode:setScale9Enabled(true)
    self.m_effectNode:addChild(self.m_winKuangNode, 1)
    self.m_winKuangNode:setPosition(util_convertToNodeSpace(self:findChild("Node_winKuang"), self.m_effectNode))

    self.m_winZiNode = util_createAnimation("CatchMonsters_win_zi.csb")
    self.m_winKuangNode:addChild(self.m_winZiNode)
    self.m_winZiNode:setPosition(self.m_winKuangNode:getContentSize().width/2, 20)

    -- 粒子
    for particleIndex = 1, 4 do
        local particle = cc.ParticleSystemQuad:create("CatchMonstersEffect/CatchMonsters_lizi0"..particleIndex..".plist")    --加粒子效果
        self.m_winKuangNode:addChild(particle, particleIndex)
        particle:setVisible(false)
        self.m_kuangParticle[particleIndex] = particle
        if particleIndex == 1 then
            particle:setPosition(self.m_winKuangNode:getContentSize().width/2, self.m_winKuangNode:getContentSize().height-17)
            particle:setPosVar(cc.p((170*self.m_kuangReelsListX[1]+36)*self.m_liziScale, 0))
        elseif particleIndex == 2 then
            particle:setPosition(self.m_winKuangNode:getContentSize().width/2, 17)
            particle:setPosVar(cc.p((170*self.m_kuangReelsListX[1]+36)*self.m_liziScale, 0))
        elseif particleIndex == 3 then
            particle:setPosition(17, self.m_winKuangNode:getContentSize().height/2)
            particle:setPosVar(cc.p(0, (118*self.m_kuangReelsListY[1]+36)*self.m_liziScale))
        elseif particleIndex == 4 then
            particle:setPosition(self.m_winKuangNode:getContentSize().width-17, self.m_winKuangNode:getContentSize().height/2)
            particle:setPosVar(cc.p(0, (118*self.m_kuangReelsListY[1]+36)*self.m_liziScale))
        end
    end
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenCatchMonstersMachine:initSpineUI()
    -- 大赢前 预告动画
    self.m_bigWinEffect1 = util_spineCreate("CatchMonsters_bigwin_1", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect1, 10)
    local startPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self:findChild("Node_bigwin"))
    self.m_bigWinEffect1:setPosition(startPos)
    self.m_bigWinEffect1:setVisible(false)

    self.m_bigWinEffect2 = util_spineCreate("CatchMonsters_bigwin_1", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect2, 10)
    self.m_bigWinEffect2:setPosition(startPos)
    self.m_bigWinEffect2:setVisible(false)

    self.m_bigWinEffect3 = util_spineCreate("CatchMonsters_bigwin_2", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect3, 1)
    self.m_bigWinEffect3:setPosition(startPos)
    self.m_bigWinEffect3:setVisible(false)

    self.m_bigwinRoleList = {}
    for i = 1, 2 do
        self.m_bigwinRoleList[i] = {}
        for index = 6, 9 do
            local roleSpine = util_spineCreate("Socre_CatchMonsters_"..index, true, true)
            self:findChild("Node_bigwin"):addChild(roleSpine, 5)
            roleSpine:setPosition(startPos)
            roleSpine:setVisible(false)
            table.insert(self.m_bigwinRoleList[i], roleSpine)
        end
    end
    
    -- 预告动画
    self.m_yugaoSpineEffect = util_spineCreate("Socre_CatchMonsters_WheelBonus", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect)
    self.m_yugaoSpineEffect:setVisible(false)

    -- 移动框最大的氛围动画
    self.m_winMaxSpineEffect1 = util_spineCreate("CatchMonsters_qipan_2", true, true)
    self:findChild("Node_tx1"):addChild(self.m_winMaxSpineEffect1)
    self.m_winMaxSpineEffect1:setVisible(false)

    self.m_winMaxSpineEffect2 = util_spineCreate("CatchMonsters_qipan_3", true, true)
    self:findChild("Node_tx2"):addChild(self.m_winMaxSpineEffect2)
    self.m_winMaxSpineEffect2:setVisible(false)

    -- 转盘过场
    self.m_wheelGuochangSpine = util_spineCreate("Socre_CatchMonsters_WheelBonus", true, true)
    self:findChild("Node_guochang"):addChild(self.m_wheelGuochangSpine)
    self.m_wheelGuochangSpine:setVisible(false)

    -- free 开始弹板
    self.m_freeStartSpine = util_spineCreate("Socre_CatchMonsters_WheelBonus", true, true)
    self:findChild("Node_guochang"):addChild(self.m_freeStartSpine, 1)
    self.m_freeStartSpine:setVisible(false)
    self.m_freeStartSpine.coinsNums = util_createAnimation("CatchMonsters_freeStartNums.csb")
    util_spinePushBindNode(self.m_freeStartSpine, "shuzi", self.m_freeStartSpine.coinsNums)

    self.m_freeStartCaiDaiSpine = util_spineCreate("Socre_CatchMonsters_WheelBonus_tx", true, true)
    self:findChild("Node_guochang"):addChild(self.m_freeStartCaiDaiSpine, 2)
    self.m_freeStartCaiDaiSpine:setVisible(false)

    -- free玩法中 转盘数量
    self.m_freeWheelNumsSpine = util_spineCreate("CatchMonsters_jiaobiao_wheel2", true, true)
    self.m_freeWheelNumsNode:findChild("Node_spine"):addChild(self.m_freeWheelNumsSpine)
    self.m_freeWheelNumsSpine.coinsNums = util_createAnimation("CatchMonsters_jiaobiao_wheel_shuzi.csb")
    util_spinePushBindNode(self.m_freeWheelNumsSpine, "shuzi", self.m_freeWheelNumsSpine.coinsNums)
end


--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free
]]
function CodeGameScreenCatchMonstersMachine:setReelBg(_BgIndex)
    self:runCsbAction("idle", true)
    self:findChild("Node_base"):setVisible(_BgIndex == 1)
    self:findChild("Node_free"):setVisible(_BgIndex == 2)
    self.m_gameBg:findChild("base_bg"):setVisible(_BgIndex == 1)
    self.m_gameBg:findChild("free_bg"):setVisible(_BgIndex == 2)
end

function CodeGameScreenCatchMonstersMachine:initMachineBg()
    CodeGameScreenCatchMonstersMachine.super.initMachineBg(self)

    local baseSpine = util_spineCreate("CatchMonsters_bg2", true, true)
    self.m_gameBg:findChild("base_bg"):addChild(baseSpine)
    util_spinePlay(baseSpine, "idle_base", true)

    local freeSpine = util_spineCreate("CatchMonsters_bg2", true, true)
    self.m_gameBg:findChild("free_bg"):addChild(freeSpine)
    util_spinePlay(freeSpine, "idle_free", true)
end

function CodeGameScreenCatchMonstersMachine:enterGamePlayMusic()
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_enter_game)
    end)
end

function CodeGameScreenCatchMonstersMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCatchMonstersMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if not self.m_hasfeature then
        self:setSpinTounchType(false)
        self:changeBetAndBetBtn()
        self.m_chooseBetView:showView()
    else
        self:changeBetAndBetBtn()
    end
    if not self.m_bProduceSlots_InFreeSpin and self:getCurrSpinMode() ~= SPECIAL_SPIN_MODE then
        self.m_controlBetView:playChangeEffect()
    end
    local features = self.m_runSpinResultData.p_features or {}
    if #features and features[2] == 3 then
        self:playWinKuangMoveEffect(nil, true)
    end
end

function CodeGameScreenCatchMonstersMachine:addObservers()
    CodeGameScreenCatchMonstersMachine.super.addObservers(self)
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_CatchMonsters_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_CatchMonsters_winLines" .. soundIndex]
        end 
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- 打开选择bet界面
    gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates() and self.m_bottomUI.m_spinBtn.m_spinBtn:isVisible() and
            self.m_bottomUI.m_spinBtn.m_spinBtn:isTouchEnabled() then
            self.m_chooseBetView:showView(self.m_iBetLevel)
        end
    end, "OPEN_CHOOSEVIEW")
end

function CodeGameScreenCatchMonstersMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCatchMonstersMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    self.m_winKuangNode:stopAllActions()
    if self.m_delayNode ~= nil then
        self.m_delayNode:unscheduleUpdate()
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCatchMonstersMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_WHEEL_BONUS then
        return "Socre_CatchMonsters_WheelBonus"
    end
    if symbolType == self.SYMBOL_EXTRA_BONUS then
        return "Socre_CatchMonsters_Bonus"
    end
    if symbolType == self.SYMBOL_NULL then
        return "Socre_CatchMonsters_null"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCatchMonstersMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCatchMonstersMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WHEEL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_EXTRA_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_NULL,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCatchMonstersMachine:MachineRule_initGame()
    self.m_isDuanxian = true
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        self.m_controlBetView:playSelectBetEffect()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:setReelBg(2)
        self:showWheelNumsByFree()
        self:showBetChangeDark(true)
    end 
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCatchMonstersMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenCatchMonstersMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCatchMonstersMachine.super.slotOneReelDown(self,reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenCatchMonstersMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenCatchMonstersMachine.super.slotReelDown(self)
    if self.m_curWinKuangScaleX == 5 and self.m_curWinKuangScaleY == 4 then
        self:runCsbAction("darkover", false, function()
            self:runCsbAction("idle2", true)
        end)
    end
end
---------------------------------------------------------------------------

--[[
    判断是否触发free下收集
]]
function CodeGameScreenCatchMonstersMachine:isTriggerFreeCollect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        local isTrigger = false
        local winLines = self.m_runSpinResultData.p_winLines or {}
        if #winLines > 0 then
            for _, _pos in ipairs(winLines[1].p_iconPos) do
                local pos = self:getRowAndColByPos(_pos)
                local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_WHEEL_BONUS then
                    return true
                end
            end
        end
    end
    return false
end

--[[
    判断是否bigspin 结束
]]
function CodeGameScreenCatchMonstersMachine:isTriggerBigSpinOver()
    if self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        local bonusStatus = self.m_runSpinResultData.p_bonusStatus
        if bonusStatus == "CLOSED" then
            return true
        end
    end
    return false
end

--[[
    判断是否 框 得到jackpot
]]
function CodeGameScreenCatchMonstersMachine:isTriggerGetJackpot()
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
        if table.nums(jackpotCoins) > 0 then
            return true
        end
    end
    return false
end

--[[
    判断是否 bigspin 里滚出来again spin 
]]
function CodeGameScreenCatchMonstersMachine:isTriggerAgainSpin( )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType == self.SYMBOL_EXTRA_BONUS then
                return true
            end
        end
    end
    return false
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCatchMonstersMachine:addSelfEffect()
    if self:isTriggerGetJackpot() then 
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.KUANG_GET_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.KUANG_GET_JACKPOT_EFFECT
    end
    
    if self:isTriggerFreeCollect() then 
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.FREE_COLLECT_NUMS
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FREE_COLLECT_NUMS
    end

    if self:isTriggerBigSpinOver() then 
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BIG_SPIN_OVER_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BIG_SPIN_OVER_EFFECT

        local feautes = self.m_runSpinResultData.p_features or {}
        if #feautes > 1 and feautes[2] == 3 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FEATURE_OVER_BET_CHANGE_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FEATURE_OVER_BET_CHANGE_EFFECT
        end 
    end

    -- bigspin 滚出来again spin
    if self:isTriggerAgainSpin() then 
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BIGSPIN_AGAIN_SPIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BIGSPIN_AGAIN_SPIN_EFFECT
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCatchMonstersMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.KUANG_GET_JACKPOT_EFFECT then
        self:playEffect_getJackpotEffect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.FREE_COLLECT_NUMS then
        self:playEffect_freeCollectEffect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.BIG_SPIN_OVER_EFFECT then
        self:delayCallBack(2, function()
            self:playEffect_bigSpinOverEffect(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.FEATURE_OVER_BET_CHANGE_EFFECT then
        self:playEffect_featureOver_changeSpinEffect(function()
            effectData.p_isPlay = true
        end)
    elseif effectData.p_selfEffectType == self.BIGSPIN_AGAIN_SPIN_EFFECT then
        self:playEffect_bigSpinAgainSpinEffect(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

--[[
    base玩法 收集bonus钱
]]
function CodeGameScreenCatchMonstersMachine:playEffect_freeCollectEffect(_func)
    local wheelSymbolList = {}
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if #winLines > 0 then
        for _, _pos in ipairs(winLines[1].p_iconPos) do
            local pos = self:getRowAndColByPos(_pos)
            local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_WHEEL_BONUS then
                self:playFreeFlyWheelEffect(symbolNode)
            end
        end
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_wheel_fly)
    end

    local delayCallBack = 24/30
    self:delayCallBack(delayCallBack, function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_wheel_fly_end)
        self.m_freeWheelNumsSpine.coinsNums:findChild("m_lb_num"):setString(self.m_runSpinResultData.p_reSpinCurCount)
        if self.m_freeWheelNumsNode:isVisible() then
            util_spinePlay(self.m_freeWheelNumsSpine, "shouji", false)
            util_spineEndCallFunc(self.m_freeWheelNumsSpine, "shouji", function ()
                util_spinePlay(self.m_freeWheelNumsSpine, "idle", true)
            end)
        else
            self.m_freeWheelNumsNode:setVisible(true)
            util_spinePlay(self.m_freeWheelNumsSpine, "start", false)
            util_spineEndCallFunc(self.m_freeWheelNumsSpine, "start", function ()
                util_spinePlay(self.m_freeWheelNumsSpine, "idle", true)
            end)
        end
        self:delayCallBack(22/30, function()
            if _func then
                _func()
            end
        end)
    end)
end

--[[
    free玩法 收集wheel
]]
function CodeGameScreenCatchMonstersMachine:playFreeFlyWheelEffect(_startNode, _func)
    local startPos = util_convertToNodeSpace(_startNode, self.m_flyNode)
    local endPos = util_convertToNodeSpace(self.m_freeWheelNumsNode, self.m_flyNode)
    
    local flyNode = util_spineCreate("CatchMonsters_jiaobiao_wheel2",true,true)
    self.m_flyNode:addChild(flyNode, 1)
    flyNode:setPosition(startPos)

    util_spinePlay(flyNode, "fly", false)

    local moveTime = 24/30
    local seq = cc.Sequence:create({
        cc.MoveTo:create(moveTime, endPos),
        cc.CallFunc:create(function(  )
            if _func then
                _func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

function CodeGameScreenCatchMonstersMachine:playEffect_featureOver_changeSpinEffect(_func)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    if _func then
        _func()
    end
end

--[[
    获得图标上的jackpot
]]
function CodeGameScreenCatchMonstersMachine:playEffect_getJackpotEffect(_func)
    self.m_jackpotIndex = self.m_jackpotIndex + 1
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if self.m_jackpotIndex > table.nums(selfData.jackpotCoins) then
        if _func then
            _func()
        end
        return
    end

    for _index, _type in pairs(selfData.jackpotCoins) do
        if _index == self.m_jackpotIndex then
            self:showJackpotView(jackpotCoins[_type], _type, function()
                self:playEffect_getJackpotEffect(_func)
            end)
        end
    end
end

--[[
    bigspin 滚出来加次数 图标
]]
function CodeGameScreenCatchMonstersMachine:playEffect_bigSpinAgainSpinEffect(_func)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_EXTRA_BONUS then
                symbolNode:runAnim("actionframe")
            end
        end
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_add_spin)

    self:delayCallBack(2, function()
        if _func then
            _func()
        end
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenCatchMonstersMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenCatchMonstersMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenCatchMonstersMachine:checkRemoveBigMegaEffect()
    CodeGameScreenCatchMonstersMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenCatchMonstersMachine:getShowLineWaitTime()
    local time = CodeGameScreenCatchMonstersMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------
function CodeGameScreenCatchMonstersMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CatchMonstersSrc.CatchMonstersFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("top_des"):addChild(self.m_baseFreeSpinBar, 2) --修改成自己的节点    
end

--[[
    free玩法中 右上角转盘数量
]]
function CodeGameScreenCatchMonstersMachine:showWheelNumsByFree()
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.m_freeWheelNumsNode:setVisible(true)
        self.m_freeWheelNumsSpine.coinsNums:findChild("m_lb_num"):setString(self.m_runSpinResultData.p_reSpinCurCount)
        util_spinePlay(self.m_freeWheelNumsSpine, "start", false)
        util_spineEndCallFunc(self.m_freeWheelNumsSpine, "start", function ()
            util_spinePlay(self.m_freeWheelNumsSpine, "idle", true)
        end)
    end
    self:showBetChangeDark(true)
end

function CodeGameScreenCatchMonstersMachine:showFreeSpinView(effectData)
    local showFSView = function ()
        local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            self:setReelBg(2)
            self:showWheelNumsByFree()
        end, function()
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()    
        end)
    end

    self:delayCallBack(0.5, function()
        showFSView()
    end)    
end

function CodeGameScreenCatchMonstersMachine:showFreeSpinStart(_nums, _func1, _func2)
    self.m_bgmReelsDownDelayTime = 2
    self:reelsDownDelaySetMusicBGVolume() 

    self.m_freeStartSpine:setVisible(true)
    self.m_freeStartCaiDaiSpine:setVisible(true)
    self.m_freeStartSpine.coinsNums:findChild("m_lb_num"):setString(_nums)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_free_startView)

    util_spinePlay(self.m_freeStartSpine, "auto_freestart", true)
    util_spinePlay(self.m_freeStartCaiDaiSpine, "auto_freestart", true)
    self:delayCallBack(1, function()
        if _func1 then
            _func1()
        end
    end)
    util_spineEndCallFunc(self.m_freeStartSpine, "auto_freestart", function()
        self.m_freeStartSpine:setVisible(false)
        self.m_freeStartCaiDaiSpine:setVisible(false)
        self.m_bgmReelsDownDelayTime = 10
        if _func2 then
            _func2()
        end
    end)
end

function CodeGameScreenCatchMonstersMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if coins == "0" then
        return self:showDialog("NoWinView", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
end

function CodeGameScreenCatchMonstersMachine:showFreeSpinOverView(effectData)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view = self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            if self.m_freeWheelNumsNode:isVisible() then
                self:setReelBg(2)
                self.m_freeWheelNumsNode:setVisible(true)
                self:showBetChangeDark(true)
            else
                self:setReelBg(1)
                self.m_freeWheelNumsNode:setVisible(false)
                self:showBetChangeDark(false)
            end
        
            self:featureOverEffect()
            self:triggerFreeSpinOverCallFun()
        end
    )

    if strCoins ~= "0" then
        -- 添加光
        local guangNode = util_createAnimation("CatchMonsters/EpicWinView_guang.csb")
        view:findChild("guang_jiedian"):addChild(guangNode)
        guangNode:runCsbAction("idle", true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("guang_jiedian"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("guang_jiedian"), true)

        -- 彩带
        local caidaipine = util_spineCreate("CatchMonsters_caidai",true,true)
        view:findChild("caidai"):addChild(caidaipine)
        util_spinePlay(caidaipine, "caidai_idle", true)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 676)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_free_overView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_CatchMonsters_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_free_overView_over)
    end)
end

function CodeGameScreenCatchMonstersMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        -- self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    self:showFreeSpinView(effectData)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenCatchMonstersMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CatchMonstersSrc.CatchMonstersJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    

    self.m_wheelJackPotBarView = util_createView("CatchMonstersSrc.CatchMonstersWheelJackPotBarView")
    self.m_wheelJackPotBarView:initMachine(self)
    self.m_bonusWheelView:findChild("jackpot"):addChild(self.m_wheelJackPotBarView) --修改成自己的节点
end

--[[
    显示jackpotWin
]]
function CodeGameScreenCatchMonstersMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CatchMonstersSrc.CatchMonstersJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        func = function()
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenCatchMonstersMachine:showFeatureGameTip(_func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local winKuangScaleX = 1
    local winKuangScaleY = 1
    if selfdata.winType then
        winKuangScaleX = math.floor(tonumber(selfdata.winType[1]) / 10) --win框缩放比例
        winKuangScaleY = tonumber(selfdata.winType[1]) % 10 --win框缩放比例
    end

    local callBack = function()
        if winKuangScaleX == 5 and winKuangScaleY == 4 then
            if type(_func) == "function" then
                _func()
            end
        else
            if self:getFeatureGameTipChance(40) then
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
    end
    
    if self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        if winKuangScaleX == 5 and winKuangScaleY == 4 then
            self.m_moveKuangMaxNode:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_shandian)
            self.m_moveKuangMaxNode:runCsbAction("actionframe", false, function()
                self.m_moveKuangMaxNode:setVisible(false)
                self:playWinKuangMoveEffect(function()
                    callBack()
                end)
            end)
            self:runCsbAction("darkstart", false, function()
                self:runCsbAction("darkidle", true)
            end)
        else
            self:playWinKuangMoveEffect(function()
                callBack()
            end)
        end
    else
        if winKuangScaleX == 5 and winKuangScaleY == 4 then
            self.m_isLongRun = true
            self.m_moveKuangMaxNode:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_shandian)
            self.m_moveKuangMaxNode:runCsbAction("actionframe", false, function()
                self.m_moveKuangMaxNode:setVisible(false)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_kuang_max)
                self:playWinKuangMoveEffect(function()
                    self:setReelRunInfo(true)
                    callBack()
                end)
            end)
            self:runCsbAction("darkstart", false, function()
                self:runCsbAction("darkidle", true)
            end)
        else
            self:playWinKuangMoveEffect()
            callBack()
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
function CodeGameScreenCatchMonstersMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_yugao)

    self.b_gameTipFlag = true
    self.m_yugaoSpineEffect:setVisible(true)
    util_spinePlay(self.m_yugaoSpineEffect,"actionframe_yugao",false)
    util_spineEndCallFunc(self.m_yugaoSpineEffect, "actionframe_yugao" ,function ()
        self.m_yugaoSpineEffect:setVisible(false)
    end) 

    self:runCsbAction("actionframe_yugao", false)

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
function CodeGameScreenCatchMonstersMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_bigwin_yugao)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_CatchMonsters_yugao_say"..self.m_bigWinYuGaoSoundIndex])
    self.m_bigWinYuGaoSoundIndex = self.m_bigWinYuGaoSoundIndex + 1
    if self.m_bigWinYuGaoSoundIndex > 2 then
        self.m_bigWinYuGaoSoundIndex = 1
    end
    
    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)

    self.m_bigWinEffect1:setVisible(true)
    self.m_bigWinEffect2:setVisible(true)
    self.m_bigWinEffect3:setVisible(true)
    
    for i = 1, #self.m_bigwinRoleList do
        for j = 1, #self.m_bigwinRoleList[i] do
            self.m_bigwinRoleList[i][j]:setVisible(true)
            util_spinePlay(self.m_bigwinRoleList[i][j], "actionframe_bigwin"..i)
        end
    end

    util_spinePlay(self.m_bigWinEffect1, "actionframe_bigwin1")
    util_spinePlay(self.m_bigWinEffect2, "actionframe_bigwin2")
    util_spinePlay(self.m_bigWinEffect3, "actionframe_bigwin")

    util_spineEndCallFunc(self.m_bigWinEffect1, "actionframe_bigwin1", function()
        self.m_bigWinEffect1:setVisible(false)
        self.m_bigWinEffect2:setVisible(false)
        self.m_bigWinEffect3:setVisible(false)
        for i = 1, #self.m_bigwinRoleList do
            for j = 1, #self.m_bigwinRoleList[i] do
                self.m_bigwinRoleList[i][j]:setVisible(false)
            end
        end

        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenCatchMonstersMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

--[[
    每次spin之后 win框移动
]]
function CodeGameScreenCatchMonstersMachine:playWinKuangMoveEffect(_func, _isComeIn)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata.winType then
        self.m_curWinKuangScaleX = math.floor(tonumber(selfdata.winType[1]) / 10) --win框缩放比例
        self.m_curWinKuangScaleY = tonumber(selfdata.winType[1]) % 10 --win框缩放比例

        local endPosCol = tonumber(selfdata.winType[2]) -- win框左上角最终位置 列
        local endPosRow = tonumber(selfdata.winType[3]) -- win框左上角最终位置 行
        if endPosRow == 1 then
            endPosRow = 4
        elseif endPosRow == 2 then
            endPosRow = 3
        elseif endPosRow == 3 then
            endPosRow = 2
        elseif endPosRow == 4 then
            endPosRow = 1
        end

        self.m_endPos = self.m_effectNode:convertToNodeSpace(self:getNodePosByColAndRow(endPosRow, endPosCol))
        if self.m_curWinKuangScaleX > 1 then
            self.m_endPos.x = self.m_endPos.x + (self.m_curWinKuangScaleX/2-0.5) * (self.m_SlotNodeW+3)
        end
        if self.m_curWinKuangScaleY > 1 then
            self.m_endPos.y = self.m_endPos.y - (self.m_curWinKuangScaleY/2-0.5) * self.m_SlotNodeH
        end

        self.m_curWinKuangScaleX = self.m_kuangReelsListX[self.m_curWinKuangScaleX]
        self.m_curWinKuangScaleY = self.m_kuangReelsListY[self.m_curWinKuangScaleY]

        if not _isComeIn then
            self:beginMoveWinKuang(0.8, _func)
        else
            self.m_winKuangNode:setPosition(cc.p(self.m_endPos.x, self.m_endPos.y))
            self.m_winKuangNode:setContentSize(cc.size(170*self.m_curWinKuangScaleX+36+3*(self.m_curWinKuangScaleX-1), 118*self.m_curWinKuangScaleY+36))
            self.m_winZiNode:setPosition(self.m_winKuangNode:getContentSize().width/2, 20)
            -- 连线的时候 需要显示的资源
            for particleIndex = 1, 4 do
                local particle = self.m_kuangParticle[particleIndex]
                if particleIndex == 1 then
                    particle:setPosition(self.m_winKuangNode:getContentSize().width/2, self.m_winKuangNode:getContentSize().height-17)
                    particle:setPosVar(cc.p((170*self.m_curWinKuangScaleX+36+3*(self.m_curWinKuangScaleX-1))*self.m_liziScale, 0))
                elseif particleIndex == 2 then
                    particle:setPosition(self.m_winKuangNode:getContentSize().width/2, 17)
                    particle:setPosVar(cc.p((170*self.m_curWinKuangScaleX+36+3*(self.m_curWinKuangScaleX-1))*self.m_liziScale, 0))
                elseif particleIndex == 3 then
                    particle:setPosition(17, self.m_winKuangNode:getContentSize().height/2)
                    particle:setPosVar(cc.p(0, (118*self.m_curWinKuangScaleY+36)*self.m_liziScale))
                elseif particleIndex == 4 then
                    particle:setPosition(self.m_winKuangNode:getContentSize().width-17, self.m_winKuangNode:getContentSize().height/2)
                    particle:setPosVar(cc.p(0, (118*self.m_curWinKuangScaleY+36)*self.m_liziScale))
                end
            end
        end
    end
end

--[[
    开始移动win框
]]
function CodeGameScreenCatchMonstersMachine:beginMoveWinKuang(_moveTime, _func)
    local curScaleX = (self.m_curWinKuangScaleX - self.m_winKuangScaleX) / (_moveTime*60)
    local curScaleY = (self.m_curWinKuangScaleY - self.m_winKuangScaleY) / (_moveTime*60)
    
    local actionList = {}
    actionList[1] = cc.MoveTo:create(_moveTime, cc.p(self.m_endPos.x, self.m_endPos.y))
    actionList[2] = cc.CallFunc:create(function()
        self.m_delayNode:onUpdate(function(delayTime)
            self.m_kuangMoveCurIndex = self.m_kuangMoveCurIndex + 1
            print(self.m_kuangMoveCurIndex)
            local callBack = function()
                self.m_tem_winKuangScaleX = self.m_winKuangScaleX + curScaleX*self.m_kuangMoveCurIndex
                self.m_tem_winKuangScaleY = self.m_winKuangScaleY + curScaleY*self.m_kuangMoveCurIndex
                self.m_winKuangNode:setContentSize(cc.size(170*(self.m_winKuangScaleX + curScaleX*self.m_kuangMoveCurIndex)+36+3*(self.m_curWinKuangScaleX-1), 118*(self.m_winKuangScaleY + curScaleY*self.m_kuangMoveCurIndex)+36))
                self.m_winZiNode:setPosition(self.m_winKuangNode:getContentSize().width/2, 20)
            end
            if curScaleX <= 0 and curScaleY >= 0 then
                if self.m_winKuangScaleX + curScaleX*self.m_kuangMoveCurIndex >= self.m_curWinKuangScaleX and 
                    self.m_winKuangScaleY + curScaleY*self.m_kuangMoveCurIndex <= self.m_curWinKuangScaleY then
                        callBack()
                else
                    print("curScaleX <= 0 and curScaleY >= 0")
                end
            elseif curScaleX <= 0 and curScaleY <= 0 then
                if self.m_winKuangScaleX + curScaleX*self.m_kuangMoveCurIndex >= self.m_curWinKuangScaleX and 
                    self.m_winKuangScaleY + curScaleY*self.m_kuangMoveCurIndex >= self.m_curWinKuangScaleY then
                        callBack()
                else
                    print("curScaleX <= 0 and curScaleY <= 0")
                end
            elseif curScaleX >= 0 and curScaleY <= 0 then
                if self.m_winKuangScaleX + curScaleX*self.m_kuangMoveCurIndex <= self.m_curWinKuangScaleX and 
                    self.m_winKuangScaleY + curScaleY*self.m_kuangMoveCurIndex >= self.m_curWinKuangScaleY then
                        callBack()
                else
                    print("curScaleX >= 0 and curScaleY <= 0")
                end
            elseif curScaleX >= 0 and curScaleY >= 0 then
                if self.m_winKuangScaleX + curScaleX*self.m_kuangMoveCurIndex <= self.m_curWinKuangScaleX and 
                    self.m_winKuangScaleY + curScaleY*self.m_kuangMoveCurIndex <= self.m_curWinKuangScaleY then
                        callBack()
                else
                    print("curScaleX >= 0 and curScaleY >= 0")
                end
            else
                print("不变")
            end
        end)
    end)
    actionList[3] = cc.CallFunc:create(function()
        if self.m_delayNode ~= nil then
            self.m_delayNode:unscheduleUpdate()

            self.m_isMoveEnd = true

            self.m_winKuangNode:setContentSize(cc.size(170*self.m_curWinKuangScaleX+36+3*(self.m_curWinKuangScaleX-1), 118*self.m_curWinKuangScaleY+36))
            self.m_winZiNode:setPosition(self.m_winKuangNode:getContentSize().width/2, 20)

            -- 连线的时候 需要显示的资源
            for particleIndex = 1, 4 do
                local particle = self.m_kuangParticle[particleIndex]
                if particleIndex == 1 then
                    particle:setPosition(self.m_winKuangNode:getContentSize().width/2, self.m_winKuangNode:getContentSize().height-17)
                    particle:setPosVar(cc.p((170*self.m_curWinKuangScaleX+36+3*(self.m_curWinKuangScaleX-1))*self.m_liziScale, 0))
                elseif particleIndex == 2 then
                    particle:setPosition(self.m_winKuangNode:getContentSize().width/2, 17)
                    particle:setPosVar(cc.p((170*self.m_curWinKuangScaleX+36+3*(self.m_curWinKuangScaleX-1))*self.m_liziScale, 0))
                elseif particleIndex == 3 then
                    particle:setPosition(17, self.m_winKuangNode:getContentSize().height/2)
                    particle:setPosVar(cc.p(0, (118*self.m_curWinKuangScaleY+36)*self.m_liziScale))
                elseif particleIndex == 4 then
                    particle:setPosition(self.m_winKuangNode:getContentSize().width-17, self.m_winKuangNode:getContentSize().height/2)
                    particle:setPosVar(cc.p(0, (118*self.m_curWinKuangScaleY+36)*self.m_liziScale))
                end
            end
        end

        -- 移动框最大
        if self.m_curWinKuangScaleX == 5 and self.m_curWinKuangScaleY == 4 then
            self:playWinKuangMaxEffect()
        end

        if _func then
            _func()
        end
    end)
    local seq = cc.Sequence:create(cc.Spawn:create(actionList[1], actionList[2]), actionList[3])
    self.m_winKuangNode:runAction(seq)
end

--新快停逻辑
function CodeGameScreenCatchMonstersMachine:newQuickStopReel(index)
    self:quickStopMoveWinKuang()
    CodeGameScreenCatchMonstersMachine.super.newQuickStopReel(self, index)
end

--快停
function CodeGameScreenCatchMonstersMachine:operaQuicklyStopReel()
    if self.m_quickStopReelIndex then
        return
    end
    --有停止并且未回弹的停止快停
    self.m_quickStopReelIndex = nil
    for i=1,#self.m_reels do
        if self.m_reels[i]:isReelDone() then
            self.m_quickStopReelIndex = i
        end
    end
    if not self.m_quickStopReelIndex then
        self:newQuickStopReel(1)
    else
        if self.m_isLongRun then
            self:newQuickStopReel(1) 
        end
    end
end

--[[
    点击快停的时候 处理移动框
]]
function CodeGameScreenCatchMonstersMachine:quickStopMoveWinKuang()
    self.m_winKuangNode:stopAllActions()

    if self.m_delayNode ~= nil then
        self.m_delayNode:unscheduleUpdate()
    end

    -- 快停的时候 判断0.2秒结束 还是重新计算结束时间
    -- 正常0.8秒结束 对应次数48次
    if not self.m_isMoveEnd then
        self.m_winKuangScaleX = self.m_tem_winKuangScaleX
        self.m_winKuangScaleY = self.m_tem_winKuangScaleY
        if self.m_tem_winKuangScaleX == 0 or self.m_tem_winKuangScaleY == 0 then
            self.m_winKuangScaleX = self.m_curWinKuangScaleX
            self.m_winKuangScaleY = self.m_curWinKuangScaleY
        end
        self.m_kuangMoveCurIndex = 0

        if self.m_kuangMoveCurIndex <= 36 then
            self:beginMoveWinKuang(0.2)
        else
            self:beginMoveWinKuang((48-self.m_kuangMoveCurIndex)/60)
        end
    end
end

--[[
    移动框 变成最大时 需要播放动画
]]
function CodeGameScreenCatchMonstersMachine:playWinKuangMaxEffect()
    self.m_winMaxSpineEffect1:setVisible(true)
    self.m_winMaxSpineEffect2:setVisible(true)
    util_spinePlay(self.m_winMaxSpineEffect1, "idle2", true)
    util_spinePlay(self.m_winMaxSpineEffect2, "idle2", true)
end

--[[
    移动框 变成最大时 需要播放动画 （隐藏）
]]
function CodeGameScreenCatchMonstersMachine:hideWinKuangMaxEffect()
    self.m_winMaxSpineEffect1:setVisible(false)
    self.m_winMaxSpineEffect2:setVisible(false)
    self:runCsbAction("idle", true)
end

function CodeGameScreenCatchMonstersMachine:beginReel()
    if self.m_curWinKuangScaleX and self.m_curWinKuangScaleY then
        self.m_winKuangScaleX = self.m_curWinKuangScaleX
        self.m_winKuangScaleY = self.m_curWinKuangScaleY
    end
    self.m_tem_winKuangScaleX = 0
    self.m_tem_winKuangScaleY = 0
    self.m_isBeginBigSpin = false
    self.m_isDuanxian = false
    self.m_jackpotIndex = 0
    self.m_kuangMoveCurIndex = 0
    self.m_isLongRun = false
    for particleIndex = 1, 4 do
        self.m_kuangParticle[particleIndex]:setVisible(false)
        self.m_kuangParticle[particleIndex]:stopSystem()
    end
    if self.m_winKuangSound then
        gLobalSoundManager:stopAudio(self.m_winKuangSound)
        self.m_winKuangSound = nil
    end
    self.m_reelRunAnimaPlayShake = {false, false, false, false, false}
    self.m_hSymbolBulingSoundList = {false, false, false, false, false}
    self.m_isMoveEnd = false
    CodeGameScreenCatchMonstersMachine.super.beginReel(self)
    if self.m_winMaxSpineEffect1:isVisible() then
        self:hideWinKuangMaxEffect()
    end
end

function CodeGameScreenCatchMonstersMachine:updateReelGridNode(node)
    self:setSpecialNodeScore(node) 
end

function CodeGameScreenCatchMonstersMachine:setSpecialNodeScore(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if symbolNode.p_symbolType < 4 then
        -- 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        if not spineNode.m_csbCoinsNode then
            spineNode.m_csbCoinsNode = util_createAnimation("CatchMonsters_symbolcoin.csb")
            spineNode:addChild(spineNode.m_csbCoinsNode)
        else
            spineNode.m_csbCoinsNode:setVisible(true)
        end

        local score = 0
        local type = nil
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow,iCol))
        else
            score, type = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        end
        self:showBonusJackpotOrCoins(spineNode.m_csbCoinsNode, score, type)
    end
end

--[[
    显示图标上的信息
]]
function CodeGameScreenCatchMonstersMachine:showBonusJackpotOrCoins(coinsView, score, type)
    if coinsView then
        if type == "Normal" then
            coinsView:findChild("Node_1"):setVisible(true)
            coinsView:findChild("Node_jackpot"):setVisible(false)
            local labCoins = coinsView:findChild("m_lb_coins")
            labCoins:setString(util_formatCoinsLN(score, 3, false, true, true))
            self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 152)
        else 
            coinsView:findChild("Node_1"):setVisible(false)
            coinsView:findChild("Node_jackpot"):setVisible(true)
            coinsView:findChild("major"):setVisible(type == "major")
            coinsView:findChild("minor"):setVisible(type == "minor")
        end
    end
end

--[[
    根据网络数据获得小块的分数
]]
function CodeGameScreenCatchMonstersMachine:getReSpinSymbolScore(_pos)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local coins = selfMakeData.coins or {}
    local score = nil
    local type = nil
    local curBet = globalData.slotRunData:getCurTotalBet()

    for i=1, #coins do
        local values = coins[i]
        if tonumber(values[1]) == _pos then
            score = (curBet / self.m_specialBetMulti[self.m_iBetLevel + 1]) * tonumber(values[2])
            type = values[3]
        end
    end

    return score, type
end

function CodeGameScreenCatchMonstersMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    local type = nil
    local curBet = globalData.slotRunData:getCurTotalBet()
    if symbolType == 0 then
        score = self.m_configData:getFixSymbolPro0()
        if score == "minor" then
            score = 0
            type = "minor"
        elseif score == "major" then
            score = 0
            type = "major"
        else
            type = "Normal"
        end
    elseif symbolType == 1 then
        score = self.m_configData:getFixSymbolPro1()
        type = "Normal"
    elseif symbolType == 2 then
        score = self.m_configData:getFixSymbolPro2()
        type = "Normal"
    elseif symbolType == 3 then
        score = self.m_configData:getFixSymbolPro3()
        type = "Normal"
    end

    if self.m_isDuanxian then
        score = curBet * tonumber(score)
    else
        score = (curBet / self.m_specialBetMulti[self.m_iBetLevel + 1]) * tonumber(score)
    end
    return score,type
end

function CodeGameScreenCatchMonstersMachine:playBulingAnimFunc(_slotNode,_symbolCfg)
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if #winLines > 0 then
        for _, _pos in ipairs(winLines[1].p_iconPos) do
            local pos = self:getRowAndColByPos(_pos)
            local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
            if symbolNode and symbolNode.p_cloumnIndex == _slotNode.p_cloumnIndex and symbolNode.p_rowIndex == _slotNode.p_rowIndex then
                _slotNode:runAnim(
                    _symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
                if _slotNode.p_symbolType < 4 then
                    -- 展示
                    local symbol_node = _slotNode:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if spineNode.m_csbCoinsNode then
                        spineNode.m_csbCoinsNode:runCsbAction("buling")
                    end
                end
            end
        end
    end
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenCatchMonstersMachine:playSymbolBulingSound(slotNodeList)
    local cheakLines = function(_slotNode)
        local winLines = self.m_runSpinResultData.p_winLines or {}
        if #winLines > 0 then
            for _, _pos in ipairs(winLines[1].p_iconPos) do
                local pos = self:getRowAndColByPos(_pos)
                local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
                if symbolNode and symbolNode.p_cloumnIndex == _slotNode.p_cloumnIndex and symbolNode.p_rowIndex == _slotNode.p_rowIndex then
                    return true
                end
            end
        end
        return false
    end

    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) and cheakLines(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, nil)
                    self:playHSymbolBulingSound(slotNodeList)
                end
            end
        end
    end
end

--[[
    高级图标落地的时候 配音
]]
function CodeGameScreenCatchMonstersMachine:playHSymbolBulingSound(slotNodeList)
    local symbolType = 10
    local col = 1
    for k, _slotNode in pairs(slotNodeList) do
        if _slotNode and _slotNode.p_symbolType and _slotNode.p_rowIndex < 5 then
            col = _slotNode.p_cloumnIndex
            if _slotNode.p_symbolType < symbolType then
                symbolType = _slotNode.p_symbolType
            end
        end
    end
    if symbolType < 4 then
        if not self.m_hSymbolBulingSoundList[col] then
            self.m_hSymbolBulingSoundList[col] = true
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_CatchMonsters_symbol_buling_say"..symbolType])
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenCatchMonstersMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType < self.SYMBOL_WHEEL_BONUS then
                slotsNode:runLineAnim()
            end
            if slotsNode.p_symbolType < 4 then
                -- 展示
                local symbol_node = slotsNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                if spineNode.m_csbCoinsNode then
                    spineNode.m_csbCoinsNode:runCsbAction("actionframe", true)
                end
            end
            
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenCatchMonstersMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if slotsNode.p_symbolType < self.SYMBOL_WHEEL_BONUS then
                        slotsNode:runLineAnim()
                    end

                    if slotsNode.p_symbolType < 4 then
                        -- 展示
                        local symbol_node = slotsNode:checkLoadCCbNode()
                        local spineNode = symbol_node:getCsbAct()
                        if spineNode.m_csbCoinsNode then
                            spineNode.m_csbCoinsNode:runCsbAction("actionframe", true)
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenCatchMonstersMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
                if lineNode.p_symbolType < 4 then
                    -- 展示
                    local symbol_node = lineNode:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if spineNode.m_csbCoinsNode then
                        spineNode.m_csbCoinsNode:runCsbAction("idle", true)
                    end
                end
            end
        end
    end
end

--[[
    触发转盘 玩法
]]
function CodeGameScreenCatchMonstersMachine:showEffect_Respin(effectData)
    if effectData then
        effectData.p_isPlay = true
    end
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self:resetMaskLayerNodes()
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local delayTime = 0.5
    if self.m_freeWheelNumsNode:isVisible() then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_wheel_Collect_trigger)
        util_spinePlay(self.m_freeWheelNumsSpine, "actionframe", false)
        delayTime = 45/30
    else
        -- 播放触发动画
        local winLines = self.m_runSpinResultData.p_winLines or {}
        if #winLines > 0 then
            delayTime = 2.5
            for _, _pos in ipairs(winLines[1].p_iconPos) do
                local pos = self:getRowAndColByPos(_pos)
                local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_WHEEL_BONUS then
                    symbolNode:setVisible(false)
                    local curWheelSymbol = util_spineCreate("Socre_CatchMonsters_WheelBonus", true, true)
                    self.m_effectNode:addChild(curWheelSymbol, 100)
                    curWheelSymbol:setPosition(util_convertToNodeSpace(symbolNode, self.m_effectNode))
                    util_spinePlay(curWheelSymbol, "actionframe")
                    self:delayCallBack(2, function()
                        local pos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                        util_changeNodeParent(self.m_clipParent, symbolNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
                        symbolNode:setPosition(pos)
                        symbolNode:setVisible(true)
                        curWheelSymbol:removeFromParent()
                    end)
                end
            end
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_wheel_trigger)
        end
    end

    self:delayCallBack(delayTime, function()
        self:playWheelGuoChangEffect(function()
            self:findChild("Node_baseFree"):setVisible(false)
            self.m_bonusWheelView:updateWheelSymbol()
            self.m_bonusWheelView:setVisible(true)
        end, function()
            self:resetMusicBg(nil,"CatchMonstersSounds/music_CatchMonsters_wheel.mp3")
            self.m_bonusWheelView:wheelStart()
        end, true)
    end)

    local callback = function(_func)
        self:delayCallBack(0.5, function()
            if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then 
                self.m_bgmReelsDownDelayTime = 0
                self:reelsDownDelaySetMusicBGVolume() 
            end
            self:playWheelGuoChangEffect(function()
                self:findChild("Node_baseFree"):setVisible(true)
                self.m_bonusWheelView:setVisible(false)
                self:setReelBg(1)
                self.m_freeWheelNumsNode:setVisible(false)
                self:showBetChangeDark(false)
            end, function()
                if not self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) and not self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                    self:playGameEffect()
                    self:resetMusicBg()
                end
                self.m_bgmReelsDownDelayTime = 10
                if _func then
                    _func()
                end
            end, false)
        end)
    end
    self.m_bonusWheelView:initCallBack(callback)
    return true
end

--[[
    转盘中奖free玩法 或者 bigspin玩法
]]
function CodeGameScreenCatchMonstersMachine:beginFreeOrBigSpin( )
    self:findChild("Node_baseFree"):setVisible(true)
    self.m_bonusWheelView:setVisible(false)
    self:playGameEffect()
end

--[[
    转盘玩法过场动画
]]
function CodeGameScreenCatchMonstersMachine:playWheelGuoChangEffect(_func1, _func2, _isComeInWheel)
    if _isComeInWheel then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_wheel_guochang)
    else
        if not self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_wheel_end_guochang)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_free_guochang)
        end
    end
    self.m_wheelGuochangSpine:setVisible(true)
    util_spinePlay(self.m_wheelGuochangSpine, "actionframe_guochang1")
    self:delayCallBack(1, function()
        if type(_func1) == "function" then
            _func1()
        end
    end)
    util_spineEndCallFunc(self.m_wheelGuochangSpine, "actionframe_guochang1", function()
        self.m_wheelGuochangSpine:setVisible(false)
        if type(_func2) == "function" then
            _func2()
        end
    end)
end

--[[
    big spin玩法过场动画
]]
function CodeGameScreenCatchMonstersMachine:playBigWinGuoChangEffect(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_bigSpin_guochang)

    self.m_wheelGuochangSpine:setVisible(true)
    util_spinePlay(self.m_wheelGuochangSpine, "actionframe_guochang2")
    self:delayCallBack(1, function()
        if type(_func1) == "function" then
            _func1()
        end
    end)
    util_spineEndCallFunc(self.m_wheelGuochangSpine, "actionframe_guochang2", function()
        self.m_wheelGuochangSpine:setVisible(false)
        if type(_func2) == "function" then
            _func2()
        end
    end)
end

--[[
    转盘玩法 显示 隐藏spin按钮
]]
function CodeGameScreenCatchMonstersMachine:setWheelBtnVisible(_vis)
    -- self.m_bottomUI:setWheelBtnVisible(_vis)
    self.m_bonusWheelView.m_wheelPanelSpin:setVisible(_vis)
end

--[[
    添加free
]]
function CodeGameScreenCatchMonstersMachine:addFreeSpinEffect( )
    -- 添加freespin effect
    local freeSpinEffect = GameEffectData.new()
    freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
    freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
end

--[[
    添加 bigspin
]]
function CodeGameScreenCatchMonstersMachine:addBigSpinEffect( )
    -- 添加bigspin effect
    local bigSpinEffect = GameEffectData.new()
    bigSpinEffect.p_effectType = GameEffect.EFFECT_BONUS
    bigSpinEffect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = bigSpinEffect
end

--[[
    添加 respin（转盘玩法）
]]
function CodeGameScreenCatchMonstersMachine:addWheelEffect( )
    -- 添加bigspin effect
    local wheelEffect = GameEffectData.new()
    wheelEffect.p_effectType = GameEffect.EFFECT_RESPIN
    wheelEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = wheelEffect
end

--[[
    获取底栏金币
]]
function CodeGameScreenCatchMonstersMachine:getCurBottomWinCoins()
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

--[[
    更新底栏金币
]]
function CodeGameScreenCatchMonstersMachine:updateBottomUICoins(_beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

----
--- 处理spin 成功消息
--
function CodeGameScreenCatchMonstersMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "spinResult"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end
    -- 转盘玩法 不走下面流程
    if (spinData.action == "SPIN" or spinData.action == "FEATURE") and spinData.result.action ~= "RESPIN" then

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenCatchMonstersMachine:initGameStatusData(gameData)
    CodeGameScreenCatchMonstersMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.betMulti then
        self.m_specialBetMulti = gameData.gameConfig.extra.betMulti
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.betlevel then
        self.m_iBetLevel = gameData.gameConfig.extra.betlevel
    end 
end

------------------ 高低bet相关 -----------------------------

function CodeGameScreenCatchMonstersMachine:getBetLevelCoins(index)
    local betMulti = 1
    if self.m_specialBetMulti and #self.m_specialBetMulti > 0 then
        betMulti = self.m_specialBetMulti[index]
    end
    local betIndex = globalData.slotRunData:getCurBetIndex()
    local totalBetValue = globalData.slotRunData:getCurBetValueByIndex(betIndex)
    local betValue = totalBetValue * betMulti
    return betValue
end

function CodeGameScreenCatchMonstersMachine:getCurBetLevelMulti()
    local betMulti = 1
    if self.m_specialBetMulti then
        betMulti = self.m_specialBetMulti[self.m_iBetLevel + 1]
    end
    return betMulti or 1
end

function CodeGameScreenCatchMonstersMachine:chooseBetLevel(_index)
    --是否 选择了不同的 bet
    if _index - 1 ~= self.m_iBetLevel then
        self.m_oldBetLevel = clone(self.m_iBetLevel)
        --修改 betCotrolvIew
        self.m_iBetLevel = _index - 1
        self:changeBetAndBetBtn()
    end
    self:setSpinTounchType(true)
end

--[[
    修改bet值
]]
function CodeGameScreenCatchMonstersMachine:changeBetAndBetBtn( )
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local curBetMulti = self:getCurBetLevelMulti()
    globalData.slotRunData.m_curBetMultiply = curBetMulti

    local betId = globalData.slotRunData.iLastBetIdx
    self.m_bottomUI:changeBetCoinNum(betId, curTotalBet)
end

function CodeGameScreenCatchMonstersMachine:setSpinTounchType(_isTouch)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, _isTouch})
end

------------------ 高低bet相关end -----------------------------

function CodeGameScreenCatchMonstersMachine:isNormalStates( )
    local featureLen = self.m_runSpinResultData.p_features or {}
    if #featureLen >= 2 and self.m_initFeatureData == nil then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    end

    if  self:getGameSpinStage() ~= IDLE and not self.m_isRunningEffect then
        return false
    end

    if  globalData.slotRunData.gameEffStage == GAME_START_REQUEST_STATE then
        return false
    end

    return true
end

function CodeGameScreenCatchMonstersMachine:checkHasFeature()
    local hasfeature = CodeGameScreenCatchMonstersMachine.super.checkHasFeature(self)
    if hasfeature then
        self.m_hasfeature = true
        if self.m_bigSpinOver then
            self.m_hasfeature = false
        end
    end
    return hasfeature
end

function CodeGameScreenCatchMonstersMachine:initFeatureInfo(_spinData, _featureData)
    if _featureData.p_status == "CLOSED" then
        if _featureData.p_data.respin.reSpinsTotalCount > 0 and _featureData.p_data.respin.reSpinCurCount > 0 then
        else
            self.m_bigSpinOver = true
        end
        self:playGameEffect()
        return
    else
        self.m_hasfeature = true
        local bonusExtra = _featureData.p_bonus.extra
        self.m_runSpinResultData.p_bonusExtra = bonusExtra
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        local triggerCoins = _spinData.p_winAmount or 0
        if triggerCoins and triggerCoins ~= 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{triggerCoins,false,false})
        end
    end
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenCatchMonstersMachine:showBonusGameView(effectData)
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_isBeginBigSpin = true
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    self:resetMusicBg(nil,"CatchMonstersSounds/music_CatchMonsters_bigSpin.mp3")
    self:playBigWinGuoChangEffect(function()
        self:setReelBg(2)
        self.m_controlBetView:playSelectBetEffect()
        self:showWheelNumsByFree()
    end, function()
        self:playEffectNotifyNextSpinCall()
    end)
end

function CodeGameScreenCatchMonstersMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE or 
        self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        if self.m_isBeginBigSpin then
            delayTime = 1
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
        -- self.m_handerIdAutoSpin =
        --     scheduler.performWithDelayGlobal(
        --     function(delay)
        --         self:normalSpinBtnCall()
        --     end,
        --     0.5,
        --     self:getModuleName()
        -- )
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenCatchMonstersMachine:showBigSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if coins == "0" then
        return self:showDialog("NoWinView", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
        return self:showDialog("MaxSpinOver", ownerlist, func)
    end
end

--[[
    bigspin玩法结束
]]
function CodeGameScreenCatchMonstersMachine:playEffect_bigSpinOverEffect(_func)
    local strCoins = util_formatCoins(self.m_runSpinResultData.p_bonusWinCoins, 50)
    local view = self:showBigSpinOver(
        strCoins,
        self.m_runSpinResultData.p_bonusExtra.totalTimes,
        function()
            self:showBetChangeDark(false)
            self.m_freeWheelNumsNode:setVisible(false)
            self:featureOverEffect()
            self:setReelBg(1)
            self:setCurrSpinMode(NORMAL_SPIN_MODE)
            self:resetMusicBg()
            if _func then
                _func()
            end
        end
    )

    if strCoins ~= "0" then
        -- 添加光
        local guangNode = util_createAnimation("CatchMonsters/EpicWinView_guang.csb")
        view:findChild("guang_jiedian"):addChild(guangNode)
        guangNode:runCsbAction("idle", true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("guang_jiedian"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("guang_jiedian"), true)

        -- 彩带
        local caidaipine = util_spineCreate("CatchMonsters_caidai",true,true)
        view:findChild("caidai"):addChild(caidaipine)
        util_spinePlay(caidaipine, "caidai_idle", true)

        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 676)
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_bigSpin_overView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_CatchMonsters_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_bigSpin_overView_over)
    end)
end

--[[
    free玩法 bigspin玩法结束的时候 判断是否还有转盘次数
]]
function CodeGameScreenCatchMonstersMachine:featureOverEffect()
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        -- self:showEffect_Respin()
        self:addWheelEffect()
    else
        if self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_bonusWinCoins, GameEffect.EFFECT_BONUS)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_resWinCoins, true, true, self:getCurBottomWinCoins()})
        end
    end
end

function CodeGameScreenCatchMonstersMachine:MachineRule_checkTriggerFeatures()
    CodeGameScreenCatchMonstersMachine.super.MachineRule_checkTriggerFeatures(self)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
    end
end

function CodeGameScreenCatchMonstersMachine:notifyClearBottomWinCoin()
    local isClearWin = false
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    elseif self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    end
    -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44
end

function CodeGameScreenCatchMonstersMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        isNotifyUpdateTop = false
        self:setLastWinCoin(self.m_runSpinResultData.p_bonusWinCoins)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenCatchMonstersMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            self.m_initSpinData.p_freeSpinsLeftCount > 0
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self:checkTriggerFsOver() then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenCatchMonstersMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            if self.m_isDuanxian and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            else
                if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount > 0 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end
            end
        end
    end
end

------- 快滚 ----------
function CodeGameScreenCatchMonstersMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS or _slotNode.p_symbolType == self.SYMBOL_EXTRA_BONUS then
        _slotNode:runAnim("idleframe2", true)
    end
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

function CodeGameScreenCatchMonstersMachine:setReelRunInfo(_isLongRun)
    -- big spin玩法里快滚
    if self:getCurrSpinMode() == SPECIAL_SPIN_MODE or _isLongRun then
        local longRunConfigs = {}
        local reels =  self.m_stcValidSymbolMatrix
        self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
        table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {0,1,2,3,4,5,6,7,8,94,95},
        ["musRunInfos"] = {["startCol"] = 1,["endCol"] = 5}})
        self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
        self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态   
    end 
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenCatchMonstersMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(1, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function CodeGameScreenCatchMonstersMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    if self.m_initFeatureData == nil then
        if self.m_initSpinData and self.m_initSpinData.p_reSpinsTotalCount ~= nil and self.m_initSpinData.p_reSpinsTotalCount > 0 and self.m_initSpinData.p_reSpinCurCount > 0 then
            if self.m_initSpinData.p_freeSpinsLeftCount and self.m_initSpinData.p_freeSpinsLeftCount == 0 then --有free玩法的话 不触发respin
                --手动添加freespin次数
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

                gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

                gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

                local reSpinEffect = GameEffectData.new()
                reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

                self.m_isRunningEffect = true

                if self.checkControlerReelType and self:checkControlerReelType() then
                    globalMachineController.m_isEffectPlaying = true
                end

                -- BtnType_Auto  BtnType_Stop  BtnType_Spin
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

                -- 模拟当前reelDown结束，执行后续操作
                isPlayGameEff = true
            end
        end
    end

    if self.m_initFeatureData and self.m_initFeatureData.p_data and self.m_initFeatureData.p_data.freespin.freeSpinsTotalCount <= 0 and self.m_initFeatureData.p_data.freespin.freeSpinsLeftCount <= 0 then
        if self.m_initFeatureData.p_data.respin and self.m_initFeatureData.p_data.respin.reSpinsTotalCount > 0 and self.m_initFeatureData.p_data.respin.reSpinCurCount > 0 then
            --手动添加freespin次数
            globalData.slotRunData.freeSpinCount = self.m_initFeatureData.p_data.freespin.freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_initFeatureData.p_data.freespin.freeSpinsTotalCount
            self.m_iFreeSpinTimes = self.m_initFeatureData.p_data.freespin.freeSpinsTotalCount

            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

            self.m_isRunningEffect = true

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            -- BtnType_Auto  BtnType_Stop  BtnType_Spin
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 模拟当前reelDown结束，执行后续操作
            isPlayGameEff = true
        end
    end
    return isPlayGameEff
end

function CodeGameScreenCatchMonstersMachine:dealSmallReelsSpinStates()
    if not self.b_gameTipFlag then
        if self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
            -- 快滚第一列开始 就不能点击快停
            return 
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
end

function CodeGameScreenCatchMonstersMachine:triggerLongRunChangeBtnStates()
    if self.m_isLongRun then
        return 
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
end

-- 添加金边
-- 快滚的时候 添加震动
function CodeGameScreenCatchMonstersMachine:creatReelRunAnimation(col)
    if self.m_isLongRun then
        -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_kuang_max_reel)
        return 
    end
    if not self.m_reelRunAnimaPlayShake[col] then
        self.m_reelRunAnimaPlayShake[col] = true
        self:shakeNode(self:findChild("root"), 3, 5, 1)
    end
    CodeGameScreenCatchMonstersMachine.super.creatReelRunAnimation(self, col)
end

--震动
function CodeGameScreenCatchMonstersMachine:shakeNode(_shakeNode,_sx,_sy,_time)
    local changePosY = _sx
    local changePosX = _sy
    local actionList = {}
    local oldPos = cc.p(_shakeNode:getPosition())
    local count = _time
    for i = 1, count do
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
        actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    end

    local seq = cc.Sequence:create(actionList)
    _shakeNode:runAction(seq)
end

function CodeGameScreenCatchMonstersMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true -- 触发了长滚动

        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            if self.m_isLongRun then
                parentData.moveSpeed = self.m_configData.p_reelMoveSpeed
            else
                parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
            end
        end
    end
    return isTriggerLongRun
end

function CodeGameScreenCatchMonstersMachine:showEffect_LineFrame(effectData)
    local isTrigger = false
    local isFour = 0
    local isFive = 0
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if #winLines > 0 then
        for _, _pos in ipairs(winLines[1].p_iconPos) do
            local pos = self:getRowAndColByPos(_pos)
            local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
            if symbolNode and symbolNode.p_symbolType and symbolNode.p_cloumnIndex >= 3 then
                isTrigger = true
                if symbolNode.p_cloumnIndex == 4 then
                    isFour = 1
                elseif symbolNode.p_cloumnIndex == 5 then
                    isFive = 1
                end
            end
        end
    end

    local callBack = function()
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
        self:showLineFrame()

        self:showKuangLines()
        
        local time = self:getShowLineWaitTime()
        if time then
            performWithDelay(
                self,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                0.5
            )
        else
            performWithDelay(self, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, 0.1)
        end
    end

    if isTrigger then
        local delayTime = 5/30
        if isFour and not isFive then
            delayTime = 10/30
        end
        if isFive then
            delayTime = 20/30
        end
        self:delayCallBack(delayTime, function()
            callBack()
        end)
    else
        callBack()
    end

    return true
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenCatchMonstersMachine:checkFeatureOverTriggerBigWin(winAmonut, feature, isWheel)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = self:getNewBingWinTotalBet(true)
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        if isWheel then
            isAddEffect = true
            self.m_llBigOrMegaNum = winAmonut

            local delayEffect = GameEffectData.new()
            delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
            delayEffect.p_effectOrder = feature + 1
            table.insert(self.m_gameEffects, delayEffect)

            local effectData = GameEffectData.new()
            effectData.p_effectType = winEffect
            table.insert(self.m_gameEffects, effectData)
        else
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_effectType == feature then
                    isAddEffect = true
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if isAddEffect == false then
                for i = 1, #self.m_gameEffects do
                    local effectData = self.m_gameEffects[i]
                    if effectData.p_isPlay == false then
                        self.m_llBigOrMegaNum = winAmonut

                        local delayEffect = GameEffectData.new()
                        delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                        delayEffect.p_effectOrder = feature + 1
                        table.insert(self.m_gameEffects, i + 1, delayEffect)

                        local effectData = GameEffectData.new()
                        effectData.p_effectType = winEffect
                        table.insert(self.m_gameEffects, i + 2, effectData)
                        break
                    end
                end
                if #self.m_gameEffects == 0 then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    table.insert(self.m_gameEffects, 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, 2, effectData)
                end
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end

function CodeGameScreenCatchMonstersMachine:scaleMainLayer()
    CodeGameScreenCatchMonstersMachine.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.width / display.height >= 1370/768 then
    elseif display.width / display.height >= 1228/768 then
        mainScale = mainScale * 1.01
    elseif display.width / display.height >= 1152/768 then
        mainScale = mainScale * 1.07
    elseif display.width / display.height >= 920/768 then
        mainScale = mainScale * 1.07
    else
        mainScale = mainScale * 1.07
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

function CodeGameScreenCatchMonstersMachine:callSpinTakeOffBetCoin(betCoin)
    local curCoinNum = globalData.userRunData.coinNum
    globalData.coinsSoundType = 1
    if self:getCurrSpinMode() ~= SPECIAL_SPIN_MODE then
        -- 立即更改金币数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, curCoinNum - betCoin)
    end
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {varCoins = -betCoin})
    -- 增加task 统计
    -- gLobalTaskManger:triggerTask(TASK_SPIN_TIMES)

    -- 这两个方法需要转移到spin结果回来之后再进行处理 csc 2020年11月18日18:04:28
    -- self:calculateSpinData()
    -- --增加新手任务进度
    -- self:checkIncreaseNewbieTask()

    if globalData.slotRunData.m_isNewAutoSpin then
        --autospin次数统计
        if globalData.slotRunData.m_autoNum and globalData.slotRunData.m_autoNum > 0 then
            globalData.slotRunData.m_autoNum = globalData.slotRunData.m_autoNum - 1
        else
            globalData.slotRunData.m_autoNum = 0
            globalData.slotRunData.m_isAutoSpinAction = false
            if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
                globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
            end
        end
    end
end

--[[
    win框 显示连线状态
]]
function CodeGameScreenCatchMonstersMachine:showKuangLines(_isCurShow)
    self.m_winKuangSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_CatchMonsters_winKuang_shanshuo)
    for particleIndex = 1, 4 do
        self.m_kuangParticle[particleIndex]:setVisible(true)
        self.m_kuangParticle[particleIndex]:resetSystem()
    end
    if _isCurShow then
        self:delayCallBack(1, function()
            if self.m_winKuangSound then
                gLobalSoundManager:stopAudio(self.m_winKuangSound)
                self.m_winKuangSound = nil
            end
            for particleIndex = 1, 4 do
                self.m_kuangParticle[particleIndex]:setVisible(false)
                self.m_kuangParticle[particleIndex]:stopSystem()
            end
        end)
    end
end

--[[
    检测是否存在大赢
]]
function CodeGameScreenCatchMonstersMachine:checkHasSelfBigWin()
    if self:checkHasSelfGameEffectType(GameEffect.EFFECT_BIGWIN) or 
    self:checkHasSelfGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
    self:checkHasSelfGameEffectType(GameEffect.EFFECT_EPICWIN) or 
    self:checkHasSelfGameEffectType(GameEffect.EFFECT_LEGENDARY) then
        return true
    end
    return false
end

--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenCatchMonstersMachine:checkHasSelfGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType and self.m_gameEffects[i].p_isPlay == false then
            return true
        end
    end

    return false
end

function CodeGameScreenCatchMonstersMachine:getBounsScatterDataZorder(symbolType)
    local symbolOrder = CodeGameScreenCatchMonstersMachine.super.getBounsScatterDataZorder(self, symbolType)

    if symbolType == self.SYMBOL_WHEEL_BONUS or symbolType == self.SYMBOL_EXTRA_BONUS then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end

    return symbolOrder
end

--[[
    显示bet按钮 遮罩
]]
function CodeGameScreenCatchMonstersMachine:showBetChangeDark(_isDark)
    if _isDark then
        self.m_controlBetView:findChild("Panel_dark"):setVisible(true)
        self.m_controlBetView:runCsbAction("idle3")
    else
        self.m_controlBetView:findChild("Panel_dark"):setVisible(false)
        self.m_controlBetView:runCsbAction("idle", true)
    end
end

return CodeGameScreenCatchMonstersMachine






