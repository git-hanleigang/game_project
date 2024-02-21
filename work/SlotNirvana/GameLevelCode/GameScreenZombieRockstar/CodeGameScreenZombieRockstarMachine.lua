---
-- island li
-- 2019年1月26日
-- CodeGameScreenZombieRockstarMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "ZombieRockstarPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenZombieRockstarMachine = class("CodeGameScreenZombieRockstarMachine", BaseNewReelMachine)

CodeGameScreenZombieRockstarMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenZombieRockstarMachine.SYMBOL_Empty = 100 --空图标
CodeGameScreenZombieRockstarMachine.SYMBOL_Grey = 101 --灰图标

-- 自定义动画的标识
CodeGameScreenZombieRockstarMachine.PLAYWINCOINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --播放上面区域动画
CodeGameScreenZombieRockstarMachine.COLLECT_SYMBOL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --收集角标

-- 构造函数
function CodeGameScreenZombieRockstarMachine:ctor()
    CodeGameScreenZombieRockstarMachine.super.ctor(self)
    self.m_lineRespinNodes = {} 

    self.m_isAddBigWinLightEffect = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_collectView = {} -- 收集界面
    self.m_symbolTypeList = {0,0,0,0,0,0}
    self.m_betCollectList = {} -- 不同bet下的收集进度
    self.m_curBetCollectDate = {{0, false}, {0, false}, {0, false}} -- 当前bet下的收集进度 和 触发状态
    self.m_isShowJiaoBiao = false --判断是否显示角标 断线进来不显示
    self.m_buffSpineEffect = {}
    self.m_payTableMulti = {}
    self.m_isPlayBuffEffect = 0 --是否在播放buff玩法
    self.m_betBuff2List = {}
    self.m_respinLockSymbolNum = 0 -- respin玩法锁定图标的个数
    self.m_respinMulList = {}
    self.m_firstJiManRespin = false -- 表示首次集满respin
    self.m_clickRespinStop = false
    self.m_isPlayBulingEffect = false
    self.m_buff3IsQuick = true
    self.m_buff3BulingNums = 0
    self.m_mulViewPosY = 0
    self.m_respinPlayBulingEffectList = {}
    self.m_isEnter = false
    --init
    self:initGame()
end

function CodeGameScreenZombieRockstarMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenZombieRockstarMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ZombieRockstar"  
end

function CodeGameScreenZombieRockstarMachine:getBottomUINode( )
    return "ZombieRockstarSrc.ZombieRockstarBottomNode"
end

function CodeGameScreenZombieRockstarMachine:initUI()
    --特效层
    self.m_effectNode = self:findChild("Node_effect")
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_delayTimeNode = cc.Node:create()
    self:addChild(self.m_delayTimeNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    -- 上面赢钱界面
    self.m_ZombieRockstarWinView = util_createView("ZombieRockstarSrc.ZombieRockstarWinCoinsView", self)
    self:findChild("Node_base_collect"):addChild(self.m_ZombieRockstarWinView)

    -- 收集区域
    for index = 1, 3 do
        self.m_collectView[index] = util_createView("ZombieRockstarSrc.ZombieRockstarCollectView", {machine = self, index = index})
        self:findChild("base_collect_left_"..index):addChild(self.m_collectView[index])
    end

    -- 棋盘动画
    self.m_qiPanEffect = util_createAnimation("ZombieRockstar/GameScreenZombieRockstar_tx.csb")
    self:findChild("Node_base_tx"):addChild(self.m_qiPanEffect)
    self.m_qiPanEffect:runCsbAction("idle", true)

    -- 棋盘动画
    self.m_respinQiPanEffect = util_createAnimation("ZombieRockstar/GameScreenZombieRockstar_tx2.csb")
    self:findChild("Node_respin_tx"):addChild(self.m_respinQiPanEffect)
    self.m_respinQiPanEffect:runCsbAction("idle", true)

    -- 棋盘动画
    self.m_respinTbEffect = util_createAnimation("ZombieRockstar_respin_tb.csb")
    self:findChild("Node_respin_tb"):addChild(self.m_respinTbEffect)
    self.m_respinTbEffect:setVisible(false)

    -- respin 乘倍界面
    self.m_respinMulView = util_createAnimation("ZombieRockstar_mult.csb")
    self:findChild("Node_mult"):addChild(self.m_respinMulView)
    self.m_respinMulView:setVisible(false)
    self.m_respinMulView:setPositionY(self.m_mulViewPosY)
    self:createJiManRespinMulView()

    -- maxspin 动画
    self.m_respinMaxSpinEffect = util_createAnimation("ZombieRockstar_respin_maxspin.csb")
    self:findChild("Node_respin_maxspin"):addChild(self.m_respinMaxSpinEffect)
    self.m_respinMaxSpinEffect:setVisible(false)

    self:createRespinView()
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "ZombieRockstar_bigwin")

    -- respin 加金币动画
    self.m_respinTotalWinNumEffect = util_createAnimation("ZombieRockstar_totalwin_shuzi.csb")
    self.m_bottomUI.coinWinNode:addChild(self.m_respinTotalWinNumEffect)
    self.m_respinTotalWinNumEffect:setVisible(false)
    self.m_respinTotalWinNumEffect:setScale(0.7)
    self.m_respinTotalWinNumEffect:setPositionY(65)

    -- 触发buff玩法时的文案
    self.m_triggerBuffEffect = util_createAnimation("ZombieRockstar_base_wenan_tips.csb")
    self:findChild("Node_wenan"):addChild(self.m_triggerBuffEffect)
    self.m_triggerBuffEffect:setVisible(false)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenZombieRockstarMachine:initSpineUI()
    -- 大赢前 预告动画
    self.m_bigWinEffect1 = util_spineCreate("ZombieRockstar_bigwin", true, true)
    self:findChild("Node_guochang"):addChild(self.m_bigWinEffect1)
    self.m_bigWinEffect1:setPosition(util_convertToNodeSpace(self.m_bottomUI.coinWinNode, self:findChild("Node_guochang")))
    self.m_bigWinEffect1:setVisible(false)

    self.m_bigWinEffect2 = util_spineCreate("ZombieRockstar_bigwin_2", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect2)
    self.m_bigWinEffect2:setVisible(false)

    -- 预告动画
    self.m_yugaoSpineEffect = util_spineCreate("ZombieRockstar_yugao", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect)
    self.m_yugaoSpineEffect:setVisible(false)

    -- buff 相关动画
    for buffIndex = 1, 3 do
        self.m_buffSpineEffect[buffIndex] = util_spineCreate("ZombieRockstar_buff"..buffIndex, true, true)
        self:findChild("Node_buff"..buffIndex):addChild(self.m_buffSpineEffect[buffIndex])
        self.m_buffSpineEffect[buffIndex]:setVisible(false)
        if buffIndex == 2 then
            -- 预告动画
            self.m_buffYugaoSpine = util_spineCreate("ZombieRockstar_yugao", true, true)
            self:findChild("Node_buff"..buffIndex):addChild(self.m_buffYugaoSpine)
            self.m_buffYugaoSpine:setVisible(false)
        end
    end

    -- 过场
    self.m_guochangSpineEffect1 = util_spineCreate("ZombieRockstar_guochang_2", true, true)
    self:findChild("Node_guochang"):addChild(self.m_guochangSpineEffect1, 1)
    self.m_guochangSpineEffect1:setVisible(false)

    self.m_guochangSpineEffect2 = util_spineCreate("ZombieRockstar_guochang", true, true)
    self:findChild("Node_guochang"):addChild(self.m_guochangSpineEffect2, 2)
    self.m_guochangSpineEffect2:setVisible(false)

    -- respin 乘倍界面 背景
    self.m_respinMulViewBg = util_spineCreate("ZombieRockstar_mult_bg", true, true)
    self.m_respinMulView:findChild("Node_spine"):addChild(self.m_respinMulViewBg)

    -- respin 喷金币
    self.m_respinTotalWinSpine = util_spineCreate("ZombieRockstar_bigwin_3", true, true)
    self:findChild("Node_guochang"):addChild(self.m_respinTotalWinSpine)
    self.m_respinTotalWinSpine:setPosition(util_convertToNodeSpace(self.m_bottomUI.coinWinNode, self:findChild("Node_guochang")))
    self.m_respinTotalWinSpine:setVisible(false)

    -- respin 两边的音响
    self.m_respinYinXiangSpine = util_spineCreate("GameScreenZombieRockstarBg_1", true, true)
    self:findChild("Node_bg2"):addChild(self.m_respinYinXiangSpine)
    self.m_respinYinXiangSpine:setVisible(false)
end

function CodeGameScreenZombieRockstarMachine:createRespinView( )
    --respinBar
    self.m_respinbar = util_createView("ZombieRockstarSrc.ZombieRockstarRespinBar", self)
    self:findChild("Node_respin_left"):addChild(self.m_respinbar)
    self.m_respinbar:setVisible(false)

    -- 角色
    self.m_respinRoleSpine = util_spineCreate("ZombieRockstar_guochang", true, true)
    self:findChild("Node_juese"):addChild(self.m_respinRoleSpine)
    self.m_respinRoleSpine:setVisible(false)

    -- 右边的成倍
    self.m_respinMulNode = util_createView("ZombieRockstarSrc.ZombieRockstarMulRespinBar", self)
    self:findChild("Node_respin_right"):addChild(self.m_respinMulNode)
    self.m_respinMulNode:setVisible(false)

end

function CodeGameScreenZombieRockstarMachine:initMachineBg()
    CodeGameScreenZombieRockstarMachine.super.initMachineBg(self)
    -- base背景
    self.m_gameBaseSpineBg = util_spineCreate("GameScreenZombieRockstarBg_1", true, true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_gameBaseSpineBg)
    self.m_gameBaseSpineBg:setVisible(false)

    -- respin背景
    self.m_gameRespinSpineBg = util_spineCreate("GameScreenZombieRockstarBg_2", true, true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_gameRespinSpineBg)
    self.m_gameRespinSpineBg:setVisible(false)
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2respin
]]
function CodeGameScreenZombieRockstarMachine:setReelBg(_BgIndex)
    if _BgIndex == 1 then
        self:findChild("Node_sp_reel"):setPositionX(0)
        self.m_gameBaseSpineBg:setVisible(true)
        self.m_gameRespinSpineBg:setVisible(false)
        util_spinePlay(self.m_gameBaseSpineBg, "idleframe", true)
        self.m_qiPanEffect:setPosition(cc.p(0, 0))
        self.m_respinYinXiangSpine:setVisible(false)
    elseif _BgIndex == 2 then
        self:findChild("Node_sp_reel"):setPositionX(-35)
        self.m_gameBaseSpineBg:setVisible(false)
        self.m_gameRespinSpineBg:setVisible(true)
        util_spinePlay(self.m_gameRespinSpineBg, "idleframe2", true)
        self.m_respinYinXiangSpine:setVisible(true)
        util_spinePlay(self.m_respinYinXiangSpine, "idleframe2_respin", true)
    end
    self.m_qiPanEffect:setVisible(_BgIndex == 1)
    self.m_respinQiPanEffect:setVisible(_BgIndex == 2)
    self:findChild("Node_base_kuang"):setVisible(_BgIndex == 1)
    self:findChild("Node_respin_kuang"):setVisible(_BgIndex == 2)
    self.m_ZombieRockstarWinView:setVisible(_BgIndex == 1)
    -- 收集区域
    for index = 1, 3 do
        self.m_collectView[index]:setVisible(_BgIndex == 1)
    end

    self.m_respinbar:setVisible(_BgIndex == 2)
    self.m_respinRoleSpine:setVisible(_BgIndex == 2)
    self.m_respinMulNode:setVisible(_BgIndex == 2)

    self.m_respinView.m_respinLinesNode:setVisible(_BgIndex == 2)
end

function CodeGameScreenZombieRockstarMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_enter_game)
    end)
end

function CodeGameScreenZombieRockstarMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenZombieRockstarMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self.m_isEnter = true
    --显示respin界面
    self:showBaseView()
    self:setReelBg(1)

    for index = 1, 3 do
        self.m_collectView[index]:updateCollectNum(self.m_curBetCollectDate[index][1], true)
    end
    self.m_ZombieRockstarWinView:showBetWinCoins()
end

function CodeGameScreenZombieRockstarMachine:addObservers()
    CodeGameScreenZombieRockstarMachine.super.addObservers(self)
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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_ZombieRockstar_winLines" .. soundIndex]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- 切换bet修改 进度
            self:changeBetCallBack()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenZombieRockstarMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenZombieRockstarMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_respinMulNumsAddSound then
        gLobalSoundManager:stopAudio(self.m_respinMulNumsAddSound)
        self.m_respinMulNumsAddSound = nil
    end
    self:stopUpDateRespinWinCoinsLab()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenZombieRockstarMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_Empty then
        return "Socre_ZombieRockstar_Empty"
    end
    if symbolType == self.SYMBOL_Grey then
        return "ZombieRockstar_qipan_di"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenZombieRockstarMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenZombieRockstarMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Empty,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Grey,count = 2}
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenZombieRockstarMachine:MachineRule_initGame()
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenZombieRockstarMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenZombieRockstarMachine:slotOneReelDown(reelCol)    
    CodeGameScreenZombieRockstarMachine.super.slotOneReelDown(self,reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenZombieRockstarMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenZombieRockstarMachine.super.slotReelDown(self)
end
---------------------------------------------------------------------------

--[[
    判断是否触发 赢钱
]]
function CodeGameScreenZombieRockstarMachine:isTriggerWinCoinsEffect( )
    for _, _symbolNums in ipairs(self.m_symbolTypeList) do
        if _symbolNums > 0 then
            return true
        end
    end
    return false
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenZombieRockstarMachine:addSelfEffect()
    if self:isTriggerWinCoinsEffect() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.PLAYWINCOINS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.PLAYWINCOINS_EFFECT -- 动画类型
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.isBuffSymbol and selfdata.isBuffSymbol > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_SYMBOL_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_SYMBOL_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenZombieRockstarMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_SYMBOL_EFFECT then
        self.m_scheduleId = schedule(self, function()
            if self.m_isPlayBulingEffect then
                self.m_isPlayBulingEffect = false
                if self.m_scheduleId then
                    self:stopAction(self.m_scheduleId)
                    self.m_scheduleId = nil
                end

                self:playCollectSymbolEffect(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end
        end, 1/30)
    elseif effectData.p_selfEffectType == self.PLAYWINCOINS_EFFECT then
        self.m_ZombieRockstarWinView:updateViewByData(self.m_symbolTypeList, function()
            local feautes = self.m_runSpinResultData.p_features or {}
            if feautes and #feautes == 1 then
                if not self:checkHasBigWin() then
                    self:playEffectNotifyChangeSpinStatus()
                end
            end
        end)
        effectData.p_isPlay = true
        self:playGameEffect()
        if #self.m_vecGetLineInfo ~= 0 then
            self.m_qiPanEffect:runCsbAction("actionframe", true)
        end
    end

    return true
end

--[[
    角标落地
]]
function CodeGameScreenZombieRockstarMachine:playCollectSymbolBulingEffect(targSp)
    if targSp and targSp.p_symbolType and targSp.m_collectIconItem and targSp.m_collectIconItem:isVisible() then
        local nodePos = util_convertToNodeSpace(targSp, self.m_effectNode)
        local oldParent = targSp:getParent()
        local oldPosition = cc.p(targSp:getPosition())
        util_changeNodeParent(self.m_effectNode, targSp, 0)
        targSp:setPosition(nodePos)

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_collect_buling)

        local collectIconItem = targSp.m_collectIconItem
        util_spinePlay(collectIconItem, "buling", false)
        local symbolSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH)
        collectIconItem:runAction(cc.Sequence:create(
            cc.DelayTime:create(20/30),
            cc.MoveTo:create(7/30, cc.p(symbolSize.width/4, -symbolSize.height/4)),
            cc.CallFunc:create(function()
                util_changeNodeParent(oldParent, targSp, 0)
                targSp:setPosition(oldPosition)
                util_spinePlay(collectIconItem, "idleframe2", true)
                self.m_isPlayBulingEffect = true
            end)
        ))
    end
end

--[[
    收集角标
]]
function CodeGameScreenZombieRockstarMachine:playCollectSymbolEffect(_func)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol, iRow)
            local targSp = respinNode.m_baseFirstNode
            if targSp and targSp.p_symbolType and targSp.m_collectIconItem and targSp.m_collectIconItem:isVisible() then
                local collectIconItem = targSp.m_collectIconItem
                local startPos = util_convertToNodeSpace(collectIconItem, self.m_effectNode)
                self:playCollectFlyEffect(startPos, function()
                    if _func then
                        _func()
                    end
                end)
                collectIconItem:setVisible(false)
                return
            end
        end
    end
end

--[[
    得到角标收集的终点位置
]]
function CodeGameScreenZombieRockstarMachine:getCollectEndPos()
    local collectIndex = 1
    local collectEndIndex = 1
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    for _index, _numsList in ipairs(self.m_curBetCollectDate) do
        if _index == selfdata.isBuffSymbol then
            selfdata.isBuffSymbol = 0
            collectIndex = _index
            collectEndIndex = _numsList[1]
        end
    end
    
    local endNode = self.m_collectView[collectIndex]:findChild(collectIndex.."_"..collectEndIndex)
    local endPos = util_convertToNodeSpace(endNode, self.m_effectNode)

    return endPos, collectEndIndex, collectIndex
end

--[[
    收集 飞
]]
function CodeGameScreenZombieRockstarMachine:playCollectFlyEffect(_startPos, _func)
    local isFrist = true
    local endPos, collectNums, collectIndex = self:getCollectEndPos()

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_collect_symbol_fly)

    for index = 1, 4 do
        self:delayCallBack(1/30 * (index - 1), function()
            local flyNode = util_spineCreate("ZombieRockstar_jiaobiao",true,true)
            self.m_effectNode:addChild(flyNode, -index)
            flyNode:setPosition(_startPos)

            if index == 1 then
                util_spinePlay(flyNode, "shouji", false)
            else
                util_spinePlay(flyNode, "shouji"..index, false)
            end

            local seq = cc.Sequence:create({
                -- cc.DelayTime:create(10/30),
                cc.MoveTo:create(20/30, endPos),
                cc.CallFunc:create(function()
                    if isFrist then
                        isFrist = false
                        self.m_collectView[collectIndex]:updateCollectNum(collectNums)
                        local delayTime = 0
                        if collectNums == 3 then
                            delayTime = 42/60
                        end
                        self:delayCallBack(delayTime, function()
                            if _func then
                                _func()
                            end
                        end)
                    end
                end),
                cc.RemoveSelf:create(true)
            })

            flyNode:runAction(seq)
        end)
    end
end

-- free和freeMore特殊需求
function CodeGameScreenZombieRockstarMachine:playScatterTipMusicEffect()
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
function CodeGameScreenZombieRockstarMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end


function CodeGameScreenZombieRockstarMachine:checkRemoveBigMegaEffect()
    CodeGameScreenZombieRockstarMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenZombieRockstarMachine:getShowLineWaitTime()
    local time = CodeGameScreenZombieRockstarMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------
---------------------------------单个滚动相关接口---------------------------------------------

-- 继承底层respinView
function CodeGameScreenZombieRockstarMachine:getRespinView()
    return "ZombieRockstarSrc.ZombieRockstarRespinView"
end
-- 继承底层respinNode
function CodeGameScreenZombieRockstarMachine:getRespinNode()
    return "ZombieRockstarSrc.ZombieRockstarRespinNode"
end

--[[
    显示 界面
]]
function CodeGameScreenZombieRockstarMachine:showBaseView()
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()
    
    --构造盘面数据
    self:triggerBaseReSpinCallFun(endTypes, randomTypes)
end

--触发respin
function CodeGameScreenZombieRockstarMachine:triggerBaseReSpinCallFun(endTypes, randomTypes)
    self.m_specialReels = false

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

    self:initBaseRespinView(endTypes, randomTypes)
    
    -- buff1 棋盘遮罩
    self.m_reelsBuff1Dark = util_createAnimation("ZombieRockstar_buff1_dark.csb")
    self.m_respinView:addChild(self.m_reelsBuff1Dark, 100)
    self.m_reelsBuff1Dark:setPosition(util_convertToNodeSpace(self:findChild("Node_respin_tb"), self.m_respinView))
    self.m_reelsBuff1Dark:setVisible(false)

    -- buff2 棋盘遮罩
    self.m_reelsBuff2Dark = util_createAnimation("ZombieRockstar_buff2_dark.csb")
    self.m_respinView:addChild(self.m_reelsBuff2Dark, 100)
    self.m_reelsBuff2Dark:setPosition(util_convertToNodeSpace(self:findChild("Node_buffEffect"), self.m_respinView))
    self.m_reelsBuff2Dark:setVisible(false)
end

function CodeGameScreenZombieRockstarMachine:initBaseRespinView(endTypes, randomTypes)
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

-- 根据本关卡实际小块数量填写
function CodeGameScreenZombieRockstarMachine:getRespinRandomTypes( )
    local symbolList = { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        self.SYMBOL_Empty}
    return symbolList  
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenZombieRockstarMachine:getRespinLockTypes( )
    return {}   
end

function CodeGameScreenZombieRockstarMachine:getMatrixPosSymbolType(iRow, iCol)
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

function CodeGameScreenZombieRockstarMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

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

function CodeGameScreenZombieRockstarMachine:clearWinLineEffect()
    CodeGameScreenZombieRockstarMachine.super.clearWinLineEffect(self)
    self.m_qiPanEffect:runCsbAction("idle", true)
    self.m_respinQiPanEffect:runCsbAction("idle", true)
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function CodeGameScreenZombieRockstarMachine:normalSpinBtnCall()
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

    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_delayTimeNode:stopAllActions()
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
        self.m_isHaveClick = true
    end

    local delayTime = 0
    if self:isRespinJiMan() then 
        delayTime = 70/60
    end

    local callBack = function()
        local isWaitCall = self:MachineRule_SpinBtnCall()
        if isWaitCall == false then
            self:playHideTriggerBuffEffect()
            self:playHideLineDarkEffect()
            self:runNextReSpinReel()
        else
            self:setGameSpinStage(WAIT_RUN)
        end

        local timeend = xcyy.SlotsUtil:getMilliSeconds()

        release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
    end

    self:delayCallBack(delayTime, function()
        if self:isRespinJiMan() then 
            self.m_respinMaxSpinEffect:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_again)
            self.m_respinMaxSpinEffect:runCsbAction("auto", false, function()
                self.m_respinMaxSpinEffect:setVisible(false)
                callBack()
            end)
        else
            callBack()
        end        
    end)
end

--开始下次ReSpin
function CodeGameScreenZombieRockstarMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_isShowJiaoBiao = true
    self.m_isPlayBuffEffect = 0
    self.m_isPlayBulingEffect = false
    self.m_curSpinCollectBonus = {}
    self.m_buff3IsQuick = true
    self.m_buff3BulingNums = 0
    self.m_isEnter = false
    if self:isTriggerWinCoinsEffect() then
        self.m_ZombieRockstarWinView:resetViewByDate(self.m_symbolTypeList)
    end
    self:findChild("Node_buffEffect"):removeAllChildren()
    if self.m_buff3_soundId then
        gLobalSoundManager:stopAudio(self.m_buff3_soundId)
        self.m_buff3_soundId = nil
    end
    
    self:resetReelDataAfterReel()
    self.m_respinView:checkPutLockSymbolBack()
    self:notifyClearBottomWinCoin()

    local betCoin = self:getSpinCostCoins() or 0
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if not self:checkSpecialSpin(  ) and
        self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
            self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin and
                self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE  then

        self:operaUserOutCoins()
    else
        if  self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
                self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
                    not self:checkSpecialSpin(  ) then
            
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

function CodeGameScreenZombieRockstarMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    end
    -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44
end

--开始滚动
function CodeGameScreenZombieRockstarMachine:startReSpinRun()
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
    self:isBeginBuffEffect(function()
        self:requestSpinReusltData()
    end)
    self.m_respinView:startMove()
end

function CodeGameScreenZombieRockstarMachine:requestSpinReusltData()
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

function CodeGameScreenZombieRockstarMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )

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
function CodeGameScreenZombieRockstarMachine:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = 1
    -- 把spin数据写到文件 便于找数据bug
    if param[1] == true then
        if device.platform == "mac"  then 
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
function CodeGameScreenZombieRockstarMachine:checkOpearReSpinAndSpecialReels(param)
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

            if self:getCurrSpinMode() == RESPIN_MODE then
                if not self:isRespinJiMan() then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
                end
            end
            
            --可以在这里处理预告中奖
            self:showFeatureGameTip(function()
                if self:isRespinJiMan() then
                    self:playRespinJiManEffect()
                else
                    self:stopRespinRun()
                end
            end)
        end
    else
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
    return true
end

-- --重写组织respinData信息
function CodeGameScreenZombieRockstarMachine:getRespinSpinData()
    local storedInfo = {}

    return storedInfo
end

--快停
function CodeGameScreenZombieRockstarMachine:operaQuicklyStopReel()
    if self.m_respinView:getouchStatus() ~= ENUM_TOUCH_STATUS.RUN or self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        return
    end
    self:MachineRule_respinTouchSpinBntCallBack()
end

function CodeGameScreenZombieRockstarMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_delayTimeNode:stopAllActions()
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
        self.m_isHaveClick = true
        self:playRespinSymbolAction("idleframe")
        self.m_respinQiPanEffect:runCsbAction("idle", true)

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
function CodeGameScreenZombieRockstarMachine:reSpinReelDown(addNode)
    local delayTime = 0
    if self.m_isPlayBuffEffect == 3 then
        delayTime = 0.5
    end
    self:delayCallBack(delayTime, function()
        self:setGameSpinStage(STOP_RUN)

        self:updateQuestUI()

        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

        self:playBuff3EffectByEnd()
        self:playBuff2EffectByEnd()
        self:playBuff1EffectByEnd()

        local callBack = function()
            print("滚动结束了....")
            self:reelDownNotifyChangeSpinStatus()

            self:delaySlotReelDown()
            self:stopAllActions()
            self:reelDownNotifyPlayGameEffect()
            if self:getCurrSpinMode() == RESPIN_MODE then
                self:playRespinMulAddEffect(function()
                    self:playRespinAddNumsEffect(function()
                        self:playRespinRunEndEffect()
                    end)
                end)
                
                self:runQuickEffect()
            else
                self:playIdleByBase()
            end
            self.m_isHaveClick = false

            -- 三种buff玩法 结束的时候 恢复背景
            if self.m_isPlayBuffEffect > 0 then
                util_spineMix(self.m_gameBaseSpineBg, "idleframe2", "idleframe", 0.3)
                util_spinePlay(self.m_gameBaseSpineBg, "idleframe", true)
            end
        end
        if self.m_curBigRespinNode and #self.m_curBigRespinNode > 0 then
            self:delayCallBack(20/60, function()
                callBack()
            end)
        else
            callBack()
        end
    end)
end

--[[
    每次停轮之后 播放待触发动画的 还原
]]
function CodeGameScreenZombieRockstarMachine:playIdleByBase()
    for index = 1,#self.m_respinView.m_respinNodes do
        local respinNode = self.m_respinView.m_respinNodes[index]
        if respinNode.m_baseFirstNode.m_currAnimName == "idleframe3" then
            respinNode.m_baseFirstNode:runAnim("idleframe")
        end
    end
    if self.m_isPlayBuffEffect == 3 then
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(5, 1)
        respinNode:changeRunSpeed(false)
        respinNode:setNodeReduceSpeed(false)
    end 
end

--判断改变 reSpin 的 状态
function CodeGameScreenZombieRockstarMachine:changeReSpinModeStatus()
end

function CodeGameScreenZombieRockstarMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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

                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(symPosData.iY,symPosData.iX)

                checkAddLineSlotNode(respinNode)

                if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = respinNode.m_baseFirstNode
                    end
    
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = respinNode.m_baseFirstNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上(本关提到respinView上)
--
function CodeGameScreenZombieRockstarMachine:changeToMaskLayerSlotNode(respinNode)
    self.m_lineRespinNodes[#self.m_lineRespinNodes + 1] = respinNode

    self.m_respinView:changeRespinNodeStatus(respinNode,true)
end


function CodeGameScreenZombieRockstarMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineRespinNodes

    self.m_lineSlotNodes = {}

    for i,respinNode in ipairs(self.m_lineRespinNodes) do
        self.m_respinView:changeRespinNodeStatus(respinNode,false)
        if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType then
            respinNode.m_baseFirstNode:runIdleAnim()
        end
    end

    self.m_lineRespinNodes = {}
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenZombieRockstarMachine:resetReelDataAfterReel()
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
function CodeGameScreenZombieRockstarMachine:showLineFrameByIndex(winLines, frameIndex, isLoop)
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

        if node:getParent() == nil then
            
            self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)

            node:setPosition(util_convertToNodeSpace(respinNode,self.m_slotEffectLayer))

            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            node:setPosition(util_convertToNodeSpace(respinNode,self.m_slotEffectLayer))
        end
    end

    self:showEachLineSlotNodeLineAnim( frameIndex, isLoop)
end

function CodeGameScreenZombieRockstarMachine:showEachLineSlotNodeLineAnim(_frameIndex, isLoop)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if isLoop then
                        slotsNode:runLineAnim()
                    else
                        slotsNode:runAnim("actionframe", false)
                    end
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenZombieRockstarMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runAnim("actionframe")
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenZombieRockstarMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self.m_respinView.m_reelsDark:setVisible(true)
    self.m_respinView.m_reelsDark:runCsbAction("start")

    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                -- self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        -- if #winLines > 1 then
        showLienFrameByIndex()
    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1, true)
        end
    end
end

---
-- 显示所有的连线框
--
function CodeGameScreenZombieRockstarMachine:showAllFrame(winLines)
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
                node:setPosition(util_convertToNodeSpace(respinNode,self.m_slotEffectLayer))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

function CodeGameScreenZombieRockstarMachine:clearLineAndFrame()
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

--ReSpin开始改变UI状态
function CodeGameScreenZombieRockstarMachine:changeReSpinStartUI(respinCount)
        
end

--ReSpin刷新数量
function CodeGameScreenZombieRockstarMachine:changeReSpinUpdateUI(curCount, isPlay)
    print("当前展示位置信息  %d ", curCount)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinbar:updateRespinCount(totalCount - curCount, totalCount, isPlay)
end

--ReSpin结算改变UI状态
function CodeGameScreenZombieRockstarMachine:changeReSpinOverUI()
        
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenZombieRockstarMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
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
                if effectData.p_isPlay == false or feature == GameEffect.EFFECT_RESPIN_OVER then
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
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end

function CodeGameScreenZombieRockstarMachine:showRespinOverView()
    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_resWinCoins, GameEffect.EFFECT_RESPIN_OVER)

    local strCoins=util_formatCoins(self.m_runSpinResultData.p_resWinCoins, 50)
    local view = self:showReSpinOver(strCoins,function()
        self:playGuoChangEffect(function()
            self:setReelBg(1)
            self:respinSymbolLockOrUnlock(false)
            self:triggerReSpinOverCallFun(self.m_runSpinResultData.p_resWinCoins)
            self.m_firstJiManRespin = false
            self.m_clickRespinStop = false

            for _index = 1, #self.m_respinView.m_respinNodes do
                local respinNode = self.m_respinView.m_respinNodes[_index]
                respinNode:changeRunSpeed(false)
            end
        end, function()
            self:playGameEffect()
            self:resetMusicBg(true)
        end, false)
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_overView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_ZombieRockstar_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_overView_over)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.94,sy=0.97},717)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local guangNode = util_createAnimation("ZombieRockstar/ReSpinOver_glow.csb")
    view:findChild("Node_glow"):addChild(guangNode)
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_glow"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("Node_glow"), true)
end

function CodeGameScreenZombieRockstarMachine:triggerReSpinOverCallFun(score)
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

function CodeGameScreenZombieRockstarMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    ownerlist["m_lb_num"] = self.m_runSpinResultData.p_reSpinsTotalCount
    return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func, nil, index)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenZombieRockstarMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 1 then
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

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenZombieRockstarMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
    else
        if self:getCurrSpinMode() ~= RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        end
        if type(_func) == "function" then
            _func()
        end
    end    
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenZombieRockstarMachine:showBigWinLight(func)
    self.m_bigWinEffect1:setVisible(true)
    self.m_bigWinEffect2:setVisible(true)

    local random = math.random(1, 10)
    if random <= 3 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_bigWin_yugao_say)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_bigwin_yuGao)

    util_spinePlay(self.m_bigWinEffect1, "actionframe_bigwin")
    util_spinePlay(self.m_bigWinEffect2, "actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWinEffect1, "actionframe_bigwin", function()
        self.m_bigWinEffect1:setVisible(false)
        self.m_bigWinEffect2:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    -- 背景
    util_spinePlay(self.m_gameBaseSpineBg, "idleframe2", false)
    util_spineEndCallFunc(self.m_gameBaseSpineBg, "idleframe2" ,function ()
        util_spinePlay(self.m_gameBaseSpineBg, "idleframe", true)
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
function CodeGameScreenZombieRockstarMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = true
    self.m_yugaoSpineEffect:setVisible(true)

    -- 背景
    util_spinePlay(self.m_gameBaseSpineBg, "idleframe2", false)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_yugao)

    util_spinePlay(self.m_yugaoSpineEffect,"actionframe_yugao",false)
    util_spineEndCallFunc(self.m_yugaoSpineEffect, "actionframe_yugao" ,function ()
        self.m_yugaoSpineEffect:setVisible(false)
        util_spinePlay(self.m_gameBaseSpineBg, "idleframe", true)
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

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenZombieRockstarMachine:MachineRule_stopReelChangeData()
    self.m_symbolTypeList = {0,0,0,0,0,0}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            if self:getCurrSpinMode() ~= RESPIN_MODE then
                local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
                    self.m_symbolTypeList[1] = self.m_symbolTypeList[1] + 1
                elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
                    self.m_symbolTypeList[2] = self.m_symbolTypeList[2] + 1
                elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
                    self.m_symbolTypeList[3] = self.m_symbolTypeList[3] + 1
                elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
                    self.m_symbolTypeList[4] = self.m_symbolTypeList[4] + 1
                elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
                    self.m_symbolTypeList[5] = self.m_symbolTypeList[5] + 1
                elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                    self.m_symbolTypeList[6] = self.m_symbolTypeList[6] + 1
                end
            end
        end
    end

    self:updateBetCollectDate()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata and selfdata.bonusGame3 then
        for i, _pos in ipairs(selfdata.bonus3Pos) do
            _pos[1] = _pos[1] + 1
            _pos[2] = _pos[2] + 1
            if _pos[1] == 1 then
                _pos[1] = 3
            elseif _pos[1] == 3 then
                _pos[1] = 1
            end
        end
    end
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenZombieRockstarMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    if not self:checkHasSelfGameEffectType(self.PLAYWINCOINS_EFFECT) then
        if self:getCurrSpinMode() ~= RESPIN_MODE then
            self:playEffectNotifyChangeSpinStatus()
        end
    else
        if self:checkHasBigWin() then
            self:playEffectNotifyChangeSpinStatus()
        end
    end

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

function CodeGameScreenZombieRockstarMachine:playEffectNotifyChangeSpinStatus()
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
            local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
            if self:getCurrSpinMode() == RESPIN_MODE and #storedIcons >= 15 then
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    end
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenZombieRockstarMachine:checkHasSelfGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_selfEffectType
        if value == effectType then
            return true
        end
    end

    return false
end

function CodeGameScreenZombieRockstarMachine:updateReelGridNode(symbolNode)
    if symbolNode.m_collectIconItem then
        symbolNode.m_collectIconItem:setVisible(false)
    end

    -- 收集相关
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.isBuffSymbol and selfData.isBuffSymbol > 0 then
        if symbolNode:isLastSymbol() and self.m_isShowJiaoBiao and self.m_isPlayBuffEffect == 0 then
            local reelsIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            local buffSymbolPos = selfData.buffSymbolPos
            if buffSymbolPos == reelsIndex then
                --创建角标
                if not symbolNode.m_collectIconItem then
                    symbolNode.m_collectIconItem = util_spineCreate("ZombieRockstar_jiaobiao", true, true)
                    symbolNode:addChild(symbolNode.m_collectIconItem, 1000)
                end
                util_spinePlay(symbolNode.m_collectIconItem, "idleframe")
                symbolNode.m_collectIconItem:setPosition(cc.p(0, 0))
                symbolNode.m_collectIconItem:setVisible(true)
            end
        end
    end

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData and rsExtraData.isRestore and rsExtraData.restore_pos > 0 then
        if symbolNode:isLastSymbol() and self.m_isShowJiaoBiao then
            local reelsIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            local restore_pos = rsExtraData.restore_pos
            if restore_pos == reelsIndex then
                --创建角标
                if not symbolNode.m_respinIconItem then
                    symbolNode.m_respinIconItem = util_spineCreate("ZombieRockstar_jiaobiao_2", true, true)
                    symbolNode:addChild(symbolNode.m_respinIconItem, 999)
                end
                util_spinePlay(symbolNode.m_respinIconItem, "idleframe")
                symbolNode.m_respinIconItem:setPosition(cc.p(0, 0))
                symbolNode.m_respinIconItem:setVisible(true)
            end
        end
    end
end

--[[
    gameConfig数据
]]
function CodeGameScreenZombieRockstarMachine:initGameStatusData(gameData)
    CodeGameScreenZombieRockstarMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.payTableMulti then
        self.m_payTableMulti = gameData.gameConfig.extra.payTableMulti
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.bets then
        self.m_betCollectList = gameData.gameConfig.extra.bets
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.bonus2Bets then
        self.m_betBuff2List = gameData.gameConfig.extra.bonus2Bets
    end

    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.respinPaytableMulti then
        self.m_respinMulList = gameData.gameConfig.extra.respinPaytableMulti
    end

    local betid = gameData.betId or -1
    if betid > 0 then
        local totalBet = 0
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        for _, _betData in ipairs (betList) do
            if _betData.p_betId == betid then
                totalBet = _betData.p_totalBetValue
            end
        end
        self.m_curBetCollectDate = self.m_betCollectList[tostring(toLongNumber(totalBet))] or {{0, false}, {0, false}, {0, false}}
        if self.m_curBetCollectDate and #self.m_curBetCollectDate == 0 then
            self.m_curBetCollectDate = {{0, false}, {0, false}, {0, false}}
        end

        if self.m_betBuff2List[tostring(toLongNumber(totalBet))] then
            gameData.spin.selfData.bonus2AwardPos = self.m_betBuff2List[tostring(toLongNumber(totalBet))].bonus2AwardPos
            gameData.spin.selfData.bonus2AwardSymbol = self.m_betBuff2List[tostring(toLongNumber(totalBet))].bonus2AwardSymbol
        end
    end
end

--[[
    每次spin 之后 更新当前bet的收集进度
]]
function CodeGameScreenZombieRockstarMachine:updateBetCollectDate( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local totalBet = globalData.slotRunData:getCurTotalBet()
    if selfdata and selfdata.buffCount then
        local collectData = self.m_betCollectList[tostring( toLongNumber(totalBet) )]
        self.m_curBetCollectDate = selfdata.buffCount
        if collectData == nil then
            self.m_betCollectList[tostring(toLongNumber(totalBet))] = {}
            self.m_betCollectList[tostring(toLongNumber(totalBet))] = selfdata.buffCount
        else
            self.m_betCollectList[tostring(toLongNumber(totalBet))] = selfdata.buffCount
        end
    else
        self.m_betCollectList[tostring(toLongNumber(totalBet))] = {}
    end

    if selfdata and selfdata.bonus2AwardPos then
        local buff2Data = self.m_betBuff2List[tostring(toLongNumber(totalBet))]
        if buff2Data == nil then
            self.m_betBuff2List[tostring(toLongNumber(totalBet))] = {}
            self.m_betBuff2List[tostring(toLongNumber(totalBet))].bonus2AwardPos = selfdata.bonus2AwardPos
            self.m_betBuff2List[tostring(toLongNumber(totalBet))].bonus2AwardSymbol = selfdata.bonus2AwardSymbol
        else
            self.m_betBuff2List[tostring(toLongNumber(totalBet))].bonus2AwardPos = selfdata.bonus2AwardPos
            self.m_betBuff2List[tostring(toLongNumber(totalBet))].bonus2AwardSymbol = selfdata.bonus2AwardSymbol
        end
    end
end

--[[
    开始下次spin 的时候 判断是否进行buff玩法
]]
function CodeGameScreenZombieRockstarMachine:isBeginBuffEffect(_func)
    if self.m_curBetCollectDate[3][2] then
        self:playBuff3Effect(_func)
    elseif self.m_curBetCollectDate[2][2] then
        self:playBuff2Effect(_func)
    else
        if _func then
            _func()
        end
    end
end

--[[
    开始buff3 玩法
]]
function CodeGameScreenZombieRockstarMachine:playBuff3Effect(_func)
    self.m_isPlayBuffEffect = 3

    util_spinePlay(self.m_gameBaseSpineBg, "idleframe2", true)

    local bigPos = {{3, 1}, {1, 5}} --2x2的位置 写死 服务器不给
    local smallPos = {{3, 2}, {2, 1}, {2, 2}, {2, 4}, {2, 5}, {1, 4}}
    self.m_curBigRespinNode = {}
    self.m_curSmallRespinNode = {}
    self.m_collectView[3]:updateCollectNum(0, true)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local isBeginNext = true
    local isFirst = true

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_collect_trigger_buff3)
    self.m_buffSpineEffect[3]:setVisible(true)
    util_spinePlay(self.m_buffSpineEffect[3], "actionframe_buff3")

    self:delayCallBack(48/30, function()
        for i, _pos in ipairs(bigPos) do
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(_pos[2], _pos[1])
            local startPos = util_convertToNodeSpace(respinNode, self:findChild("Node_buffEffect"))
            local reelMask = util_createAnimation("Socre_ZombieRockstar_tx.csb")
            self:findChild("Node_buffEffect"):addChild(reelMask, 2)
            if _pos[2] == 5 then
                reelMask:setPosition(cc.p(startPos.x - self.m_SlotNodeW, startPos.y + self.m_SlotNodeH))
            else
                reelMask:setPosition(startPos)
            end

            if isFirst then
                isFirst = false
                self.m_buff3_soundId = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_buff3_symbol_down)
            end

            reelMask:runCsbAction("start", false, function()
                reelMask:runCsbAction("idle", true)
                if isBeginNext then
                    isBeginNext = false
                    if _func then
                        _func()
                    end
                end
            end)
            
            self:delayCallBack(2/30, function()
                respinNode:setScale(2)
                respinNode:setZOrder(20000)
                respinNode.m_oldPosition = cc.p(respinNode:getPosition())
                local pos = cc.p(0, 0)
                if _pos[2] == 5 then
                    pos = cc.p(respinNode:getPositionX() - self.m_SlotNodeW/2, respinNode:getPositionY() + self.m_SlotNodeH/2)
                    respinNode:setPosition(pos)
                else
                    pos = cc.p(respinNode:getPositionX() + self.m_SlotNodeW/2, respinNode:getPositionY() - self.m_SlotNodeH/2)
                    respinNode:setPosition(pos)
                end
                local colorNode = self.m_respinView:getChildByName("colorNode_"..respinNode.p_rowIndex.."_"..respinNode.p_colIndex)
                colorNode:setScale(2)
                colorNode:setZOrder(19000)
                colorNode:setPosition(pos)
            end)
            table.insert(self.m_curBigRespinNode, respinNode)
        end
        self:delayCallBack(5/30, function()
            for _, _pos in ipairs(smallPos) do
                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(_pos[2], _pos[1])
                respinNode:setVisible(false)
                table.insert(self.m_curSmallRespinNode, respinNode)
            end
        end)
    end)

    self:delayCallBack(75/30, function()
        self.m_buffSpineEffect[3]:setVisible(false)
    end)
end

--[[
    停轮之后 处理buff3 玩法的2x2 恢复成1x1
]]
function CodeGameScreenZombieRockstarMachine:playBuff3EffectByEnd( )
    if self.m_curBigRespinNode then
        for _, _respinNode in ipairs(self.m_curBigRespinNode) do
            local startPos = util_convertToNodeSpace(_respinNode, self:findChild("Node_buffEffect"))
            local symbolName = self:getSymbolCCBNameByType(self, _respinNode.m_baseFirstNode.p_symbolType)
            local curSymbolNode = util_spineCreate(symbolName, true, true)
            self:findChild("Node_buffEffect"):addChild(curSymbolNode)
            util_spinePlay(curSymbolNode, "idleframe", false)
            curSymbolNode:setScale(2)
            curSymbolNode:setPosition(startPos)
            util_fadeOutNode(curSymbolNode, 20/60)

            _respinNode:setScale(1)
            _respinNode:setZOrder(1)
            if _respinNode.m_oldPosition then
                _respinNode:setPosition(_respinNode.m_oldPosition)
            end
            local colorNode = self.m_respinView:getChildByName("colorNode_".._respinNode.p_rowIndex.."_".._respinNode.p_colIndex)
            colorNode:setScale(1)
            colorNode:setZOrder(-100)
            colorNode:setPosition(_respinNode.m_oldPosition)
        end
        self:delayCallBack(15/60, function()
            self.m_curBigRespinNode = nil
        end)
        -- self:findChild("Node_buffEffect"):removeAllChildren()
    end

    if self.m_curSmallRespinNode then
        for _, _respinNode in ipairs(self.m_curSmallRespinNode) do
            _respinNode:setVisible(true)
        end
        self.m_curSmallRespinNode = nil
    end
end

--[[
    切换bet 修改收集进度
]] 
function CodeGameScreenZombieRockstarMachine:changeBetCallBack()
    self.m_delayTimeNode:stopAllActions()
    for index = 1, 3 do
        util_resetCsbAction(self.m_collectView[index].m_csbAct)
        for collectIndex = 1, 3 do
            util_resetCsbAction(self.m_collectView[index].m_collectSymbolList[collectIndex].m_csbAct)
        end
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local collectData = self.m_betCollectList[tostring(toLongNumber(totalBet))] or {{0, false}, {0, false}, {0, false}}
    if collectData and #collectData == 0 then
        collectData = {{0, false}, {0, false}, {0, false}}
    end
    local isShow = false
    for _index = 1, 3 do
        if collectData[_index][1] >= 3 then
            isShow = true
        end
    end
    for _index = 1, 3 do
        self.m_collectView[_index]:updateCollectNum(collectData[_index][1], true, true, isShow)
    end
    self.m_curBetCollectDate = collectData
    self.m_ZombieRockstarWinView:showBetWinCoins()

    local buff2Data = self.m_betBuff2List[tostring(toLongNumber(totalBet))]
    if buff2Data then
        self.m_runSpinResultData.p_selfMakeData.bonus2AwardPos = buff2Data.bonus2AwardPos
        self.m_runSpinResultData.p_selfMakeData.bonus2AwardSymbol = buff2Data.bonus2AwardSymbol
    end
end

--[[
    开始buff2 玩法
]]
function CodeGameScreenZombieRockstarMachine:playBuff2Effect(_func)
    self.m_isPlayBuffEffect = 2
    self.m_collectView[2]:updateCollectNum(0, true)
    self.m_curBuff2RespinNode = {}
    util_spinePlay(self.m_gameBaseSpineBg, "idleframe2", true)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local isBeginNext = true

    for _index, _pos in ipairs(selfdata.bonus2AwardPos) do
        local fixPos = self:getRowAndColByPos(_pos)
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
        table.insert(self.m_curBuff2RespinNode, respinNode)
    end

    self:playHideLineDarkEffect()
    self.m_reelsBuff2Dark:setVisible(true)
    self.m_reelsBuff2Dark:runCsbAction("actionframe_buff1", false)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_collect_trigger_buff2)
    self.m_buffSpineEffect[1]:setVisible(true)
    util_spinePlay(self.m_buffSpineEffect[1], "actionframe_buff1")
    self:delayCallBack(73/30, function()
        self.m_buffSpineEffect[1]:setVisible(false)
        for _index, _pos in ipairs(selfdata.bonus2AwardPos) do
            self:delayCallBack(0.2 * (_index-1), function()
                local fixPos = self:getRowAndColByPos(_pos)
                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
                local startPos = util_convertToNodeSpace(respinNode, self:findChild("Node_buffEffect"))
                local symbolName = self:getSymbolCCBNameByType(self, selfdata.bonus2AwardSymbol)

                respinNode:setLastSymbolType(selfdata.bonus2AwardSymbol)
                if respinNode:getNodeRunning() then
                    respinNode:quicklyStop()
                end
                self:changeSymbolType(respinNode.m_baseFirstNode, selfdata.bonus2AwardSymbol, true)

                local reelMask = util_createAnimation("Socre_ZombieRockstar_tx2.csb")
                self:findChild("Node_buffEffect"):addChild(reelMask, 2)
                reelMask:setPosition(startPos)
                reelMask:runCsbAction("start", false)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_buff2_symbol_down)
                self:delayCallBack(5/60, function()
                    respinNode:setZOrder(2000)
                end)        
            end)
        end

        self:delayCallBack(60/30, function()
            self.m_reelsBuff2Dark:runCsbAction("over", false, function()
                self.m_reelsBuff2Dark:setVisible(false)
                if  self.m_curBuff2RespinNode ~= nil then
                    for _, _node in ipairs(self.m_curBuff2RespinNode) do
                        if  not tolua.isnull(_node) then
                            _node:setZOrder(1)
                        end
                    end
                end
            end)
            
            self:findChild("Node_buffEffect"):removeAllChildren()
            if _func then
                _func()
            end
        end)
    end)
end

--[[
    停轮之后 处理buff2 玩法 解除锁定
]]
function CodeGameScreenZombieRockstarMachine:playBuff2EffectByEnd( )
    if self.m_curBuff2RespinNode then
        for _, _respinNode in ipairs(self.m_curBuff2RespinNode) do
            self.m_respinView:changeRespinNodeStatus(_respinNode, false)
        end
        self.m_curBuff2RespinNode = nil
    end
end

function CodeGameScreenZombieRockstarMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = true
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

-- 显示free spin
function CodeGameScreenZombieRockstarMachine:showEffect_FreeSpin(effectData)
    local delayTime = 0
    if #self.m_vecGetLineInfo ~= 0 then
        delayTime = 2
    end 
    self:delayCallBack(delayTime, function()
        self.m_beInSpecialGameTrigger = true

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        
        self:showFreeSpinView(effectData)
    end)
    
    return true
end

function CodeGameScreenZombieRockstarMachine:showFreeSpinView(effectData)
    self:setCurrSpinMode(FREE_SPIN_MODE)
    globalData.slotRunData.freeSpinCount = 0
    effectData.p_isPlay = true
    self:playGameEffect()
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:playBuff1Effect(function()
        self:normalSpinBtnCall()
    end)
end

function CodeGameScreenZombieRockstarMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    -- self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    self:showFreeSpinOverView()
end

function CodeGameScreenZombieRockstarMachine:showFreeSpinOverView()
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
        globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
    end
    self.m_bProduceSlots_InFreeSpin = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
end

--[[
    开始buff1 玩法
]]
function CodeGameScreenZombieRockstarMachine:playBuff1Effect(_func)
    self.m_isPlayBuffEffect = 1
    util_spinePlay(self.m_gameBaseSpineBg, "idleframe2", true)

    self.m_curBuff1RespinNode = {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    self.m_buffSpineEffect[2]:setVisible(true)
    self.m_collectView[1]:updateCollectNum(0, true)

    -- 锁定图标层级 修改
    local resetNodeZOrder = function(_zorder)
        if fsExtraData.storedIcons then
            for _index, _pos in ipairs(fsExtraData.storedIcons) do
                local fixPos = self:getRowAndColByPos(_pos)
                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
                respinNode:setZOrder(_zorder)
            end
        end
    end
    
    resetNodeZOrder(2000)
    
    self:playHideLineDarkEffect()
    self.m_reelsBuff1Dark:setVisible(true)
    self.m_reelsBuff1Dark:runCsbAction("start")

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_collect_trigger_buff1)
    util_spinePlay(self.m_buffSpineEffect[2], "actionframe_buff2")
    self.m_buffYugaoSpine:setVisible(true)
    util_spinePlay(self.m_buffYugaoSpine, "actionframe_buff2")

    self:delayCallBack(25/30, function()
        self.m_curBuff1RespinNode = {}
        if fsExtraData.storedIcons then
            for _index, _pos in ipairs(fsExtraData.storedIcons) do
                self:delayCallBack(0.2 * (_index-1), function()
                    local fixPos = self:getRowAndColByPos(_pos)
                    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)

                    self.m_respinView:changeRespinNodeStatus(respinNode, true)
                    respinNode.m_baseFirstNode:runAnim("suoding_start", false, function()
                        -- respinNode.m_baseFirstNode:runAnim("suoding_idle", true)
                    end)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_buff1_symbol_down)

                    local suodingNode = util_createAnimation("ZombieRockstar_base_collect_suoding.csb")
                    respinNode:addChild(suodingNode, -1)
                    suodingNode:runCsbAction("suoding_start")
                    self:delayCallBack(50/60, function()
                        suodingNode:removeFromParent()
                    end)

                    table.insert(self.m_curBuff1RespinNode, respinNode)
                end)
            end
        end
    end)

    self:delayCallBack(95/30, function()
        self.m_reelsBuff1Dark:runCsbAction("over", false, function()
            self.m_reelsBuff1Dark:setVisible(false)
            resetNodeZOrder(1)
        end)
        self.m_buffSpineEffect[2]:setVisible(false)

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_buff1_text_start)
        self.m_respinTbEffect:setVisible(true)
        self.m_respinTbEffect:runCsbAction("auto", false, function()
            self.m_respinTbEffect:setVisible(false)
            if _func then
                _func()
            end
        end)
        self:delayCallBack(10/30, function()
            if  self.m_curBuff1RespinNode ~= nil then
                for _, _node in ipairs(self.m_curBuff1RespinNode) do
                    if  not tolua.isnull(_node) then
                        _node.m_baseFirstNode:runAnim("suoding_idle", true)
                    end
                end
            end
        end)
    end)
end

--[[
    停轮之后 处理buff1 玩法 解除锁定
]]
function CodeGameScreenZombieRockstarMachine:playBuff1EffectByEnd( )
    if self.m_curBuff1RespinNode then
        for _, _respinNode in ipairs(self.m_curBuff1RespinNode) do
            self.m_respinView:changeRespinNodeStatus(_respinNode, false)
            _respinNode.m_baseFirstNode:runAnim("suoding_over", false)
        end
        self.m_curBuff1RespinNode = nil
    end
end

--------------------------respin 玩法-------------------------------
function CodeGameScreenZombieRockstarMachine:showRespinView()
    self:clearCurMusicBg()

    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local symbol = rsExtraData.symbol or 1
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    --先播放动画 再进入respin
    self:triggerRespinAni(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_startView_start)
        local respinStartView = self:showReSpinStart(nil)
        self:delayCallBack(90/30, function()
            if not tolua.isnull(respinStartView) then
                respinStartView:setVisible(false)
            end
            self:resetMusicBg(nil,"ZombieRockstarSounds/music_ZombieRockstar_respin.mp3")
            self:playGuoChangEffect(function()
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()

                self:findChild("Node_buffEffect"):removeAllChildren()

                self:setReelBg(2)
                self.m_isPlayRespinRoleEffect = false
                util_spinePlay(self.m_respinRoleSpine, "idleframe_juese"..(symbol+1), true)
                self.m_respinbar:updateIcon(symbol)
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
                self:respinSymbolLockOrUnlock(true)
                self:playIdleByRespin()

                self:setCurrSpinMode(RESPIN_MODE)
                self.m_specialReels = true
                self.m_respinLockSymbolNum = #self.m_runSpinResultData.p_selfMakeData.storedIcons

                for i = 1, #self.m_respinView.m_respinNodes do
                    local respinNodes = self.m_respinView.m_respinNodes[i]
                    respinNodes.m_symbolRandomType = {self.SYMBOL_Grey, symbol}
                end
                
                if self.m_respinLockSymbolNum - 7 > 0 then
                    self.m_respinMulNode:playMulEffect(self.m_respinLockSymbolNum - 7, false)
                else
                    self.m_respinMulNode:playMulEffect(self.m_respinLockSymbolNum - 7, true)
                end
                self.m_respinMulNode:updateMulCoins(symbol)
                if self.m_runSpinResultData.p_resWinCoins > 0 then
                    self:playWinCoinsBottom(self.m_runSpinResultData.p_resWinCoins, false, false)
                end

                self.m_respinbar:showOrHideWenZi(true)
                if #storedIcons >= 15 then
                    self.m_firstJiManRespin = true
                    self.m_respinbar:showOrHideWenZi(false)
                end
                self:changeSymbolByRespin(symbol)

                self:playHideLineDarkEffect()
            end, function()
                self:delayCallBack(0.5, function()
                    self:normalSpinBtnCall()
                end)
            end, true)
        end)
    end)
end

--[[
    进入respin玩法 修改棋盘上的图标
]]
function CodeGameScreenZombieRockstarMachine:changeSymbolByRespin(_symbol)
    for i = 1, #self.m_respinView.m_respinNodes do
        local respinNode = self.m_respinView.m_respinNodes[i]
        if respinNode.m_baseFirstNode and respinNode.m_baseFirstNode.p_symbolType and respinNode.m_baseFirstNode.p_symbolType ~= _symbol then
            self:changeSymbolType(respinNode.m_baseFirstNode, self.SYMBOL_Grey, true)
        end
    end
end

function CodeGameScreenZombieRockstarMachine:showReSpinStart(func)
    local view = self:showDialog("ReSpinStart", nil, func, 1)
    local respinStartView = util_spineCreate("RespinStart_2", true, true)
    view:findChild("Node_spine"):addChild(respinStartView)
    util_spinePlay(respinStartView, "auto")
    view.m_allowClick = false

    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

--[[
    respin触发动画
]]
function CodeGameScreenZombieRockstarMachine:triggerRespinAni(_func)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}

    util_spinePlay(self.m_gameBaseSpineBg, "idleframe2", true)

    if rsExtraData.symbol then
        self.m_ZombieRockstarWinView:playRespinEffect(rsExtraData.symbol+1, _func)
    else
        if _func then
            _func()
        end
    end
end

--[[
    respin玩法过场
]]
function CodeGameScreenZombieRockstarMachine:playGuoChangEffect(_func1, _func2, _isToRespin)
    if _isToRespin then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_guochang_to_respin)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_guochang_to_base)
    end

    self.m_guochangSpineEffect1:setVisible(true)
    self.m_guochangSpineEffect2:setVisible(true)
    util_spinePlay(self.m_guochangSpineEffect1, "actionframe_yugao", false)
    util_spinePlay(self.m_guochangSpineEffect2, "actionframe_guochang", false)

    self:delayCallBack(60/30, function()
        if _func1 then
            _func1()
        end
    end)

    self:delayCallBack(120/30, function()
        if _func2 then
            _func2()
        end
        self.m_guochangSpineEffect1:setVisible(false)
        self.m_guochangSpineEffect2:setVisible(false)
    end)
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenZombieRockstarMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        return
    end
end

--[[
    respin玩法 锁定图标 或者 解锁图标
]]
function CodeGameScreenZombieRockstarMachine:respinSymbolLockOrUnlock(_isLock)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    for _, _pos in ipairs(storedIcons) do
        local fixPos = self:getRowAndColByPos(_pos)
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
        self.m_respinView:changeRespinNodeStatus(respinNode, _isLock)
    end
end

--[[
    respin玩法 进入的时候播放图标idle
]]
function CodeGameScreenZombieRockstarMachine:playIdleByRespin()
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    for _, _pos in ipairs(storedIcons) do
        local fixPos = self:getRowAndColByPos(_pos)
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
        respinNode.m_baseFirstNode:runAnim("idleframe")
    end
end

--[[
    respin 玩法 自动spin
]]
function CodeGameScreenZombieRockstarMachine:respinBeginNextSpin( )
    if self.m_isHaveClick then
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:delayCallBack(0.8, function()
        self:normalSpinBtnCall()
    end)
end

--[[
    respin 图标播放连线
]]
function CodeGameScreenZombieRockstarMachine:playRespinSymbolAction(_actionName)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    for _, _pos in ipairs(storedIcons) do
        local fixPos = self:getRowAndColByPos(_pos)
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
        respinNode.m_baseFirstNode:runAnim(_actionName, true)
    end
end

--[[
    respin每次滚动停止
]]
function CodeGameScreenZombieRockstarMachine:playRespinRunEndEffect()

    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    self:playRespinSymbolAction("actionframe")
    self.m_respinQiPanEffect:runCsbAction("actionframe2", true)

    -- 锁定图标超过13个
    if #storedIcons > 13 then
        self:playRespinRoleEffect()
    end
    
    -- 集满棋盘图标
    if #storedIcons >= 15 then
        self.m_respinMulNode:playTrigggerEffect()
        self:delayCallBack(2, function()
            self:resetMusicBg(nil,"ZombieRockstarSounds/music_ZombieRockstar_respin_Multiplier.mp3")
            self:playRespinJiManEffect()
        end)
        return
    end

    self.m_respinMulNode:playWinMulEffect(#storedIcons - 7, function()
        local startNode = self.m_respinMulNode:getMulNodeByNums(#storedIcons - 7)
        self:playRespinFlyCollect(startNode, #storedIcons, 1, true)
    end)

    performWithDelay(self.m_delayTimeNode,function()
        for _, _pos in ipairs(storedIcons) do
            local fixPos = self:getRowAndColByPos(_pos)
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(fixPos.iY, fixPos.iX)
            respinNode.m_baseFirstNode:runAnim("idleframe", true)
        end
        self.m_respinQiPanEffect:runCsbAction("idle", true)

        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            self:respinBeginNextSpin()
        else
            performWithDelay(self.m_delayTimeNode,function()
                -- 通知respin结束
                self:showRespinOverView()
            end, 1)
        end
    end, 3.98)
end

--[[
    每滚出一个锁定图标 播一次动画
]]
function CodeGameScreenZombieRockstarMachine:playRespinBulingEffect(_symbolNode)
    if self:getCurrSpinMode() == RESPIN_MODE and _symbolNode.p_symbolType ~= self.SYMBOL_Grey then
        self.m_respinLockSymbolNum = self.m_respinLockSymbolNum + 1
        _symbolNode:runAnim("buling_start", false, function()
            _symbolNode:runAnim("buling_idle", true)
        end)
        table.insert(self.m_respinPlayBulingEffectList, _symbolNode)
        if _symbolNode and _symbolNode.p_symbolType and _symbolNode.m_respinIconItem and _symbolNode.m_respinIconItem:isVisible() then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_add_spin_buling)
        else
            if not self.m_respinView.isQuickRun then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_buling)
            end
        end
        
        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(_symbolNode.p_cloumnIndex, _symbolNode.p_rowIndex)
        self.m_respinView:changeRespinNodeStatus(respinNode, true)
    end
    -- buff3 最后一个小块快滚
    if self.m_isPlayBuffEffect == 3 then
        self.m_buff3BulingNums = self.m_buff3BulingNums + 1
        if self.m_buff3BulingNums >= 13 and self.m_buff3IsQuick then
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(5, 1)
            self.m_buff3IsQuick = false
            -- respinNode:changeRunSpeed(true, true)
            respinNode:setNodeReduceSpeed(true)
        end

        local respinNode = self.m_respinView:getRespinNodeByRowAndCol(1, 3)
        if respinNode.m_baseFirstNode.m_currAnimName ~= "idleframe3" then
            respinNode.m_baseFirstNode:runAnim("idleframe3", true)
        end 
    end

    if self.m_isPlayBuffEffect > 0 and not self.m_respinView.isQuickRun then
        if self.m_isPlayBuffEffect == 3 then
            local smallPos = {{3, 2}, {2, 1}, {2, 2}, {2, 4}, {2, 5}, {1, 4}}
            for _, _pos in ipairs(smallPos) do
                if _pos[1] == _symbolNode.p_rowIndex and _pos[2] == _symbolNode.p_cloumnIndex then
                    return
                end
            end
        end
        self:slotLocalOneReelDown(_symbolNode.p_cloumnIndex)
    end
end

--[[
    respin 玩法滚出来新的图标 停轮之后 播放倍数上涨动画
]]
function CodeGameScreenZombieRockstarMachine:playRespinMulAddEffect(_func)
    if self.m_respinPlayBulingEffectList and #self.m_respinPlayBulingEffectList > 0 then
        self:delayCallBack(8/30, function()
            if self.m_respinLockSymbolNum - 7 > 0 then
                self.m_respinMulNode:playAddMulEffect(self.m_respinLockSymbolNum - 7, function()
                    self:delayCallBack(10/30, function()
                        for _, _node in ipairs(self.m_respinPlayBulingEffectList) do
                            _node:runAnim("buling_over", false)
                        end
                        self.m_respinPlayBulingEffectList = {}
        
                        self:delayCallBack(10/30, function()
                            if _func then
                                _func()
                            end
                        end)
                    end)
                end)
            end
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    respin结算 飞
]]
function CodeGameScreenZombieRockstarMachine:playRespinFlyCollect(_startNode, _nums, _mul, _isCommon)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local startPos = util_convertToNodeSpace(_startNode, self.m_effectNode)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self.m_effectNode)
    local betValue = globalData.slotRunData:getCurTotalBet()
    local mulList = self.m_respinMulList[tostring(rsExtraData.symbol)]

    local coins = mulList[_nums - 7] * betValue * _mul
    local flyNode = nil
    if _isCommon then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_jiesuan_fly)
        flyNode = util_createAnimation("ZombieRockstar_respin_num.csb")
        flyNode:findChild("m_lb_num_1"):setVisible(false)
        flyNode:findChild("m_lb_num_2"):setString(util_formatCoins(coins, 3))
        flyNode:runCsbAction("shouji")
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_collect_fly)
        flyNode = util_createAnimation("ZombieRockstar_respin_num_0.csb")
        flyNode:findChild("m_lb_num_1"):setString(util_formatCoins(coins, 3))
    end
    self.m_effectNode:addChild(flyNode, 1)
    flyNode:setPosition(startPos)
    local actionList = {}
    if _isCommon then
        actionList[#actionList + 1] = cc.BezierTo:create(40/60,{cc.p(startPos.x, startPos.y+100), cc.p(endPos.x, startPos.y+100), endPos})
    else
        actionList[#actionList + 1] = cc.EaseBackIn:create(cc.MoveTo:create(0.5, cc.p(endPos.x, endPos.y)))
    end
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if _isCommon then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_jiesuan_fly_end)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_collect_fly_end)
        end
        self:playWinCoinsBottom(coins, false, true)
        if self.m_runSpinResultData.p_reSpinCurCount ~= 0 then
            self:playEffectNotifyChangeSpinStatus()
        end
    end)
    actionList[#actionList + 1] = cc.RemoveSelf:create(true)

    flyNode:runAction(cc.Sequence:create(actionList))
end

--[[
    显示赢钱区的钱
]]
function CodeGameScreenZombieRockstarMachine:playWinCoinsBottom(_addCoins, _isNotifyUpdateTop, _isPlayEffect)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    if _isPlayEffect then
        self:playCoinWinEffectUI()
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        if _isPlayEffect then
            self:playRespinWinCoinsEffect(_addCoins)
            if #storedIcons >= 15 then
                self.m_respinTotalWinSpine:setVisible(true)
                util_spinePlay(self.m_respinTotalWinSpine, "actionframe_totalwin")
                util_spineEndCallFunc(self.m_respinTotalWinSpine, "actionframe_totalwin", function()
                    self.m_respinTotalWinSpine:setVisible(false)
                end)
            else
                self.m_respinTotalWinSpine:setVisible(true)
                util_spinePlay(self.m_respinTotalWinSpine, "actionframe")
                util_spineEndCallFunc(self.m_respinTotalWinSpine, "actionframe", function()
                    self.m_respinTotalWinSpine:setVisible(false)
                end)
            end
        end
    end
    -- 刷新底栏
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + _addCoins)
    self.m_bottomUI.m_changeLabJumpTime = 0.5
    self:updateBottomUICoins(0, _addCoins, _isNotifyUpdateTop, true, false)
    self.m_bottomUI.m_changeLabJumpTime = nil
end

--[[
    respin加钱动画
]]
function CodeGameScreenZombieRockstarMachine:playRespinWinCoinsEffect(_beginCoins)
    self:stopUpDateRespinWinCoinsLab()
    self.m_respinTotalWinNumEffect:setVisible(true)
    self.m_respinTotalWinNumEffect:runCsbAction("actionframe", false, function()
        self.m_respinTotalWinNumEffect:setVisible(false)
    end)

    --跳钱
    local coinRiseNum = _beginCoins / (0.5 * 60)
    local str   = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.floor(coinRiseNum)
    local curCoins = 0
    self.m_updateRespinWinCoinsLabHandler = scheduler.scheduleUpdateGlobal(function()
        curCoins =  math.min(_beginCoins, curCoins + coinRiseNum)
        local sCoins   = string.format("+%s", util_getFromatMoneyStr(curCoins)) 
        local labCoins = self.m_respinTotalWinNumEffect:findChild("m_lb_coins")
        labCoins:setString(sCoins)
        self:updateLabelSize({label = labCoins, sx=0.91, sy=0.91}, 964)

        if curCoins >= _beginCoins then
            self:stopUpDateRespinWinCoinsLab()
        end
    end)
end

function CodeGameScreenZombieRockstarMachine:stopUpDateRespinWinCoinsLab()
    if nil ~= self.m_updateRespinWinCoinsLabHandler then
        scheduler.unscheduleGlobal(self.m_updateRespinWinCoinsLabHandler)
        self.m_updateRespinWinCoinsLabHandler = nil
    end
end

--获取底栏金币
function CodeGameScreenZombieRockstarMachine:getCurBottomWinCoins()
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
function CodeGameScreenZombieRockstarMachine:updateBottomUICoins(_beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--[[
    respin玩法 锁定图标超过13个 动画
    一直播放 直到respin玩法 结束
]]
function CodeGameScreenZombieRockstarMachine:playRespinRoleEffect( )
    if not self.m_isPlayRespinRoleEffect then
        self.m_isPlayRespinRoleEffect = true
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        local symbol = rsExtraData.symbol or 1
        util_spinePlay(self.m_respinRoleSpine, "actionframe_juese"..(symbol+1), true)
    end
end

--[[
    播放respin +1动画
]]
function CodeGameScreenZombieRockstarMachine:playRespinAddNumsEffect(_func)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData and rsExtraData.isRestore and rsExtraData.restore_pos > 0 then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol, iRow)
                local targSp = respinNode.m_baseFirstNode
                if targSp and targSp.p_symbolType and targSp.m_respinIconItem and targSp.m_respinIconItem:isVisible() then
                    local nodePos = util_convertToNodeSpace(targSp, self.m_effectNode)
                    local oldParent = targSp:getParent()
                    local oldPosition = cc.p(targSp:getPosition())
                    util_changeNodeParent(self.m_effectNode, targSp, 0)
                    targSp:setPosition(nodePos)
    
                    local respinIconItem = targSp.m_respinIconItem
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_again_spin)

                    util_spinePlay(respinIconItem, "buling", false)
                    local symbolSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH)
                    respinIconItem:runAction(cc.Sequence:create(
                        cc.DelayTime:create(20/30),
                        cc.MoveTo:create(7/30, cc.p(symbolSize.width/4, -symbolSize.height/4)),
                        cc.CallFunc:create(function()
                            util_changeNodeParent(oldParent, targSp, 0)
                            targSp:setPosition(oldPosition)
    
                            local startPos = util_convertToNodeSpace(respinIconItem, self.m_effectNode)
                            self:playRespinCollectFlyEffect(startPos, function()
                                if _func then
                                    _func()
                                end
                            end)
                            respinIconItem:setVisible(false)
                        end)
                    ))
                    return
                end
            end
        end
    else
        if _func then
            _func()
        end
    end
end

--[[
    respin 收集 +1spin 飞
]]
function CodeGameScreenZombieRockstarMachine:playRespinCollectFlyEffect(_startPos, _func)
    local endNode = self.m_respinbar:findChild("m_lb_num_3")
    local endPos = util_convertToNodeSpace(endNode, self.m_effectNode)

    local flyNode = util_spineCreate("ZombieRockstar_jiaobiao_2",true,true)
    self.m_effectNode:addChild(flyNode, 1)
    flyNode:setPosition(_startPos)

    util_spinePlay(flyNode, "shouji", false)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_again_spin_fly)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(10/30),
        cc.MoveTo:create(10/30, endPos),
        cc.CallFunc:create(function()

            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount, true)

            if _func then
                _func()
            end
        end),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

--[[
    集满全屏的动画
]]
function CodeGameScreenZombieRockstarMachine:playRespinJiManEffect()
    self.m_firstJiManRespin = true
    self.m_bigWinEffect2:setVisible(true)
    util_spinePlay(self.m_bigWinEffect2, "actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWinEffect2, "actionframe_bigwin", function()
        self.m_bigWinEffect2:setVisible(false)
    end)

    self:playShowRespinMulView()
end

--[[
    出现respin mul界面
]]
function CodeGameScreenZombieRockstarMachine:playShowRespinMulView()
    self.m_respinMulView:setVisible(true)
    self.m_respinMulView:runCsbAction("idle", false)
    self.m_respinMulNumsList[11]:setVisible(false)
    self:setEnableBtn(false)
    self.m_respinMulViewBg:setVisible(false)
    util_spinePlay(self.m_respinMulViewBg, "start", false)
    self:delayCallBack(5/60, function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_comeIn_mul)
        self.m_respinMulViewBg:setVisible(true)
    end)
    
    self:delayCallBack(100/30, function()
        self.m_respinMulView:runCsbAction("start", false, function()
            self.m_respinMulView:runCsbAction("switch", false, function()
                self.m_respinMulView:runCsbAction("switchidle", true)
            end)
        end)
        self:delayCallBack(2, function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_random)
        end)

        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        local startNode = self.m_respinMulNode:getMulNodeByNums(8)
        local startPos = util_convertToNodeSpace(startNode, self.m_effectNode)
        local endPos = util_convertToNodeSpace(self.m_respinMulView:findChild("m_lb_coins"), self.m_effectNode)
        local betValue = globalData.slotRunData:getCurTotalBet()
        local mulList = self.m_respinMulList[tostring(rsExtraData.symbol)]

        local coins = mulList[8] * betValue
        local flyNode = util_createAnimation("ZombieRockstar_respin_num_0.csb")
        self.m_effectNode:addChild(flyNode, 1)
        flyNode:setPosition(startPos)
        flyNode:findChild("m_lb_num_1"):setString(util_formatCoins(coins, 3))

        local seq = cc.Sequence:create(cc.Spawn:create(cc.MoveTo:create(0.5, cc.p(endPos.x, endPos.y)), cc.ScaleTo:create(0.5, 1)))
        flyNode:runAction(seq)

        self.m_respinMulView:findChild("m_lb_coins2"):setString(util_formatCoins(coins, 3))
        self.m_respinMulView:findChild("m_lb_coins2"):setVisible(true)
        self:delayCallBack(120/60, function()
            self.m_effectNode:removeAllChildren()
        end)

        self:delayCallBack(170/60, function()
            self.m_respinMulNumsList[11]:setVisible(true)
            self:beginRespinMulRun()
        end)
    end)

    util_spineEndCallFunc(self.m_respinMulViewBg, "start", function()
        util_spinePlay(self.m_respinMulViewBg, "idle", true)
    end)
end

--[[
    按钮状态
]]
function CodeGameScreenZombieRockstarMachine:setEnableBtn(isEnable)
    self.m_respinMulView:findChild("Button_1"):setTouchEnabled(isEnable)
    -- self.m_respinMulView:findChild("Button_1"):setBright(isEnable)
    if isEnable then
        self.m_clickRespinStop = false
    end
end

function CodeGameScreenZombieRockstarMachine:createJiManRespinMulView()
    self.m_respinMulNumsList = {}
    for index = 1, 10 do
        local mulNumsNode = util_createAnimation("ZombieRockstar_mult_num.csb")
        self.m_respinMulView:findChild("mult_position_"..index):addChild(mulNumsNode)
        self.m_respinMulNumsList[index] = mulNumsNode
        if index == 10 then
            mulNumsNode:findChild("mult_x100"):setVisible(true)
        else
            mulNumsNode:findChild("mult_x"..(index+1)):setVisible(true)
        end
    end
    local mulNumsNode = util_createAnimation("ZombieRockstar_mult_num.csb")
    self.m_respinMulView:findChild("mult"):addChild(mulNumsNode)
    self.m_respinMulNumsList[11] = mulNumsNode

    self:addClick(self.m_respinMulView:findChild("Button_1"))

    -- 数字滚动完的爆炸效果
    self.m_multBoxNode = util_createAnimation("ZombieRockstar_mult_tx.csb")
    self.m_respinMulView:findChild("Node_tx"):addChild(self.m_multBoxNode)
    self.m_multBoxNode:setVisible(false)
end

--[[
    乘倍开始滚动
]]
function CodeGameScreenZombieRockstarMachine:beginRespinMulRun( )
    local speed = 4
    local curMulIndex = 1
    local speedIndex = 1
    local totalTime = 0
  
    self:unscheduleUpdate()
    self:onUpdate( function( dt )
        totalTime = totalTime + dt
        speedIndex = speedIndex + 1
        if speedIndex > speed then
            local mulNumsNode = self.m_respinMulNumsList[11]
            for index = 1, 10 do
                if index == curMulIndex then
                    if curMulIndex == 10 then
                        mulNumsNode:findChild("mult_x100"):setVisible(true)
                    else
                        mulNumsNode:findChild("mult_x"..(curMulIndex+1)):setVisible(true)
                    end
                else
                    if index == 10 then
                        mulNumsNode:findChild("mult_x100"):setVisible(false)
                    else
                        mulNumsNode:findChild("mult_x"..(index+1)):setVisible(false)
                    end
                end
            end
            curMulIndex = curMulIndex + 1
            if curMulIndex > 10 then
                curMulIndex = 1
            end
            speedIndex = 1
        end

        if totalTime > 0.5 then
            self:setEnableBtn(true)
        end

        if totalTime > 10 then
            self.m_clickRespinStop = true
            self:stopRespinMulRun()
        end
    end)
end

--[[
    乘倍 停止
]]
function CodeGameScreenZombieRockstarMachine:stopRespinMulRun( )
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    
    self:unscheduleUpdate()

    local mulNumsNode = self.m_respinMulNumsList[11]
    for index = 1, 10 do
        if index == 10 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_maximum)
            mulNumsNode:findChild("mult_x100"):setVisible(rsExtraData.extraMulti == 100)
        else
            mulNumsNode:findChild("mult_x"..(index+1)):setVisible(rsExtraData.extraMulti == (index+1))
        end
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_select)

    util_resetCsbAction(self.m_respinMulView.m_csbAct)  
    self.m_respinMulView:runCsbAction("switch2", false)
    self:delayCallBack(55/60, function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_down)
    end)

    self:delayCallBack(105/60, function()
        self:jumpCoins(function()
            self.m_multBoxNode:setVisible(true)
            self.m_multBoxNode:runCsbAction("jiman", false, function()
                self.m_multBoxNode:setVisible(false)
                self:delayCallBack(0.5, function()
                    self.m_respinMulView:findChild("m_lb_coins2"):setVisible(false)
                    self:playRespinFlyCollect(self.m_respinMulView:findChild("m_lb_coins2"), 15, rsExtraData.extraMulti, false)
                    self:delayCallBack(3, function()
                        self.m_respinMulView:runCsbAction("over", false, function()
                            self.m_respinMulView:setVisible(false)
                            if self.m_runSpinResultData.p_reSpinCurCount > 0 then
                                self.m_isHaveClick = false
                                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                                self:respinBeginNextSpin()
                            else
                                self:delayCallBack(1, function()
                                    -- 通知respin结束
                                    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                                    self:showRespinOverView()
                                end)
                            end
                        end)
                    end)
                end)
            end)
        end)
    end)
end

function CodeGameScreenZombieRockstarMachine:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_clickRespinStop then
            return
        end
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_click)
        self.m_clickRespinStop = true
        self:stopRespinMulRun()
    end
end

--[[
    滚动加钱
]]
function CodeGameScreenZombieRockstarMachine:jumpCoins(_callBack)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local betValue = globalData.slotRunData:getCurTotalBet()
    local mulList = self.m_respinMulList[tostring(rsExtraData.symbol)]

    local node = self.m_respinMulView:findChild("m_lb_coins2")
    local curCoins = mulList[8] * betValue
    local endCoins = curCoins * rsExtraData.extraMulti
    -- time 固定 2
    local coinRiseNum = (endCoins - curCoins) / (2 * 60)
    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum )
    self.m_respinMulNumsAddSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_nums_add, true)

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
        curCoins = curCoins + coinRiseNum
        if curCoins >= endCoins then
            curCoins = endCoins
            
            node:setString(util_formatCoins(curCoins, 3))
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_respinMulNumsAddSound then
                gLobalSoundManager:stopAudio(self.m_respinMulNumsAddSound)
                self.m_respinMulNumsAddSound = nil
            end
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_nums_add_end)

            if _callBack then
                _callBack()
            end
        else
            node:setString(util_formatCoins(curCoins,3))
        end
    end)
end

--[[
    快滚效果 respin
]]
function CodeGameScreenZombieRockstarMachine:runQuickEffect()
    self.m_qucikRespinNode = {}
    local bonus_count = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}

    if #bonus_count >= 14 then
        local isLastRespin = self:getIsLastRespin()
        for _index = 1, #self.m_respinView.m_respinNodes do
            local respinNode = self.m_respinView.m_respinNodes[_index]
            if respinNode.m_runLastNodeType == self.SYMBOL_Grey then
                respinNode:changeRunSpeed(true, isLastRespin)
            else
                respinNode:changeRunSpeed(false)
            end
        end
    end
end

--[[
    判断是否是 respin 最后一次
]]
function CodeGameScreenZombieRockstarMachine:getIsLastRespin( )
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount or 1
    local isLastRespin = false
    -- 判断是否是 respin 最后一次
    if reSpinCurCount == 1 then
        isLastRespin = true
    end
    
    return isLastRespin
end

--[[
    是否 是respin集满之后流程
]]
function CodeGameScreenZombieRockstarMachine:isRespinJiMan( )
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfMakeData.storedIcons or {}
    if self:getCurrSpinMode() == RESPIN_MODE and #storedIcons >= 15 and self.m_firstJiManRespin then
        return true
    end
    return false
end

--[[
    单列滚动停止回调
]]
function CodeGameScreenZombieRockstarMachine:slotLocalOneReelDown(_iCol)
    self:playReelDownSound(_iCol, self.m_reelDownSound)
end

--[[
    单列滚动停止回调 快停
]]
function CodeGameScreenZombieRockstarMachine:slotLocalQuickOneReelDown()
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_ZombieRockstar_respin_buling)
    end
    gLobalSoundManager:playSound(self.m_quickStopReelDownSound)
end

function CodeGameScreenZombieRockstarMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            effectData.p_effectOrder = effectData.p_effectType
            if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
                effectData.p_effectOrder = effectData.p_effectType - 21 -- 特殊处理 保证freeover 在respin之前
            end
        end
    end
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenZombieRockstarMachine:checkRemoveBigMegaEffect()
end

function CodeGameScreenZombieRockstarMachine:scaleMainLayer()
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
            local ratio = display.height / display.width
            local mainPosY = 0
            self.m_mulViewPosY = 30
            if ratio >= 1228/768 then
                mainScale = mainScale * 1.04
                self.m_mulViewPosY = 20
            elseif ratio >= 1152/768 then
                mainScale = mainScale * 1.08
            elseif ratio >= 920/768 then
                mainScale = mainScale * 1.2
                mainPosY = 25
            else
                mainScale = mainScale * 1.2
                mainPosY = 25
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

--[[
    触发buff玩法时候 的文案
]]
function CodeGameScreenZombieRockstarMachine:playShowTriggerBuffEffect()
    performWithDelay(self.m_delayTimeNode, function()
        if not self.m_triggerBuffEffect:isVisible() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:playHideLineDarkEffect()
            self.m_triggerBuffEffect:setVisible(true)
            self.m_triggerBuffEffect:runCsbAction("start", false, function()
                self.m_triggerBuffEffect:runCsbAction("idle", true)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end)
        end
    end, 0.5)
end

--[[
    触发buff玩法时候 的文案 隐藏
]]
function CodeGameScreenZombieRockstarMachine:playHideTriggerBuffEffect()
    self.m_delayTimeNode:stopAllActions()
    if self.m_triggerBuffEffect:isVisible() then
        self.m_triggerBuffEffect:runCsbAction("over", false, function()
            self.m_triggerBuffEffect:setVisible(false)
        end)
    end
end

--[[
    隐藏连线的时候 的遮罩 
]]
function CodeGameScreenZombieRockstarMachine:playHideLineDarkEffect()
    if self.m_respinView.m_reelsDark:isVisible() then
        self.m_respinView.m_reelsDark:runCsbAction("over", false, function()
            self.m_respinView.m_reelsDark:setVisible(false)
        end)
    end
end

function CodeGameScreenZombieRockstarMachine:getMatrixPosSymbolType(iRow, iCol)
    local hasFeature = self:checkHasFeature()
    if hasFeature == false and self.m_isEnter then
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(iCol)
        return initDatas[iRow]
    else
        local rowCount = #self.m_runSpinResultData.p_reels
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
end

return CodeGameScreenZombieRockstarMachine






