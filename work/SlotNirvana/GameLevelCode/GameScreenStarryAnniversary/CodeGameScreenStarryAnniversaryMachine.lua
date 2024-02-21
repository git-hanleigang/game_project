---
-- island li
-- 2019年1月26日
-- CodeGameScreenStarryAnniversaryMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "StarryAnniversaryPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local SendDataManager = require "network.SendDataManager"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenStarryAnniversaryMachine = class("CodeGameScreenStarryAnniversaryMachine", BaseSlotoManiaMachine)

CodeGameScreenStarryAnniversaryMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenStarryAnniversaryMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenStarryAnniversaryMachine.SYMBOL_EMPTY = 100   -- 空信号

-- 自定义动画的标识
CodeGameScreenStarryAnniversaryMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT + 1 --base下收集bonus
CodeGameScreenStarryAnniversaryMachine.EFFECT_CHANGE_WILD = GameEffect.EFFECT_SELF_EFFECT + 2 --wild变化

-- 构造函数
function CodeGameScreenStarryAnniversaryMachine:ctor()
    CodeGameScreenStarryAnniversaryMachine.super.ctor(self)

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 
    self.m_isAddBigWinLightEffect = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_collectData = {} --进度条收集相关数据
    self.m_iBetLevel = 0 -- bet等级 betlevel 0 1 
    self.m_isQuicklyStop = false --是否点击快停
    self.m_isPlayUpdateRespinNums = true --是否播放刷新respin次数
    self.m_bonusViewScale = 1
    self.m_isDuanXian = false
    self.m_initBonusValue = {{0, "Grand"}, {0, "Major"}, {5, "bonus"}, {0, "Minor"}, {0, "Mini"}}
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    --init
    self:initGame()
end

function CodeGameScreenStarryAnniversaryMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("StarryAnniversaryConfig.csv", "LevelStarryAnniversaryConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenStarryAnniversaryMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "StarryAnniversary"  
end


function CodeGameScreenStarryAnniversaryMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initJackPotBarView() 
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_symbolExpectCtr = util_createView("StarryAnniversarySrc.StarryAnniversarySymbolExpect", self) 
    -- 引入控制插件
    self.m_longRunControl = util_createView("StarryAnniversaryLongRunControl",self) 

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("Node_4"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self:changeBottomBigWinLabUi("StarryAnniversary_bigwin_number.csb")

    -- 跳过
    self.m_openBonusSkip = util_createView("StarryAnniversarySrc.StarryAnniversaryWildSkip", self)
    self:findChild("Node_openSkip"):addChild(self.m_openBonusSkip)
    self.m_openBonusSkip:setVisible(false)

    -- respin快滚
    self.m_lightEffectNode = cc.Node:create()
    self:findChild("Node_4"):addChild(self.m_lightEffectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 200)

    -- respin集满动画
    self.m_respinJiManEffect = util_createAnimation("StarryAnniversary_Grand_jiman.csb")
    self:findChild("Node_bigwin"):addChild(self.m_respinJiManEffect)
    self.m_respinJiManEffect:setVisible(false)

    -- bonus玩法
    self.m_bonusGameView = util_createView("StarryAnniversarySrc.StarryAnniversaryBonusGameView",self)
    self:findChild("Node_bonus"):addChild(self.m_bonusGameView)
    self.m_bonusGameView:setVisible(false)
    self.m_bonusGameView:setScale(self.m_bonusViewScale)

    self:setReelBg(1)
    self:addColorLayer()
end

--[[
    初始化spine动画
]]
function CodeGameScreenStarryAnniversaryMachine:initSpineUI()
    self:initProgress()

    -- 大赢前 预告动画
    self.m_bigWinEffect = util_spineCreate("StarryAnniversary_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinEffect)
    local startPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self:findChild("Node_bigwin"))
    self.m_bigWinEffect:setPosition(startPos)
    self.m_bigWinEffect:setVisible(false)

    -- 预告动画
    self.m_yugaoSpineEffect = util_spineCreate("StarryAnniversary_yugao", true, true)
    self:findChild("Node_guochang"):addChild(self.m_yugaoSpineEffect)
    self.m_yugaoSpineEffect:setVisible(false)

    -- 过场动画 respin
    -- self.m_guochangRespinEffect = util_spineCreate("StarryAnniversary_guochang",true,true)
    self.m_guochangRespinEffect = util_createAnimation("StarryAnniversary_respin_guochang.csb")
    self:findChild("Node_guochang"):addChild(self.m_guochangRespinEffect)
    self.m_guochangRespinEffect:setVisible(false)

    -- 过场动画 bonus
    self.m_guochangBonusEffect = util_spineCreate("StarryAnniversary_guochang3",true,true)
    self:addChild(self.m_guochangBonusEffect, GAME_LAYER_ORDER.LAYER_ORDER_UI + 1)
    self.m_guochangBonusEffect:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochangBonusEffect:setVisible(false)
end

--[[
    每列添加滚动遮罩
]]
function CodeGameScreenStarryAnniversaryMachine:addColorLayer()
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
function CodeGameScreenStarryAnniversaryMachine:showColorLayer()
    for index, maskNode in ipairs(self.m_colorLayers) do
        maskNode:setVisible(true)
        maskNode:setOpacity(0)
        maskNode:runAction(cc.FadeTo:create(0.3, 120))
    end
end

--[[
    列滚动停止 渐隐
]]
function CodeGameScreenStarryAnniversaryMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    if maskNode:isVisible() then
        local fadeAct = cc.FadeTo:create(0.1, 0)
        local func = cc.CallFunc:create( function()
            maskNode:setVisible(false)
        end)
        maskNode:runAction(cc.Sequence:create(fadeAct, func))
    end
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free 3respin 4bonus
]]
function CodeGameScreenStarryAnniversaryMachine:setReelBg(_BgIndex)
    self:runCsbAction("idle")
    self:findChild("Node_1"):setVisible(true)
    self:findChild("Node_bonus"):setVisible(false)
    if _BgIndex == 1 then
        self:findChild("Node_BaseReel"):setVisible(true)
        self:findChild("Node_FreeReel"):setVisible(false)
        self:findChild("Node_base_Jackpot"):setVisible(true)
        self:findChild("Node_feature_Jackpot"):setVisible(false)
        self:findChild("free"):setVisible(false)
        self:findChild("respin"):setVisible(false)
        self:findChild("deng"):setVisible(false)

        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("free"):setVisible(false)
        self.m_gameBg:findChild("respin"):setVisible(false)
        self.m_gameBg:findChild("bonus"):setVisible(false)
        self.m_gameBg:runCsbAction("idle1")

        -- 显示下条目
        self.m_bottomUI:setVisible(true)
    elseif _BgIndex == 2 then
        self:findChild("Node_BaseReel"):setVisible(false)
        self:findChild("Node_FreeReel"):setVisible(true)
        self:findChild("Node_base_Jackpot"):setVisible(false)
        self:findChild("Node_feature_Jackpot"):setVisible(true)
        self:findChild("free"):setVisible(true)
        self:findChild("respin"):setVisible(false)
        self:findChild("deng"):setVisible(true)

        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("free"):setVisible(true)
        self.m_gameBg:findChild("respin"):setVisible(false)
        self.m_gameBg:findChild("bonus"):setVisible(false)
        self.m_gameBg:runCsbAction("idle")

        self.m_baseFreeSpinBar:setVisible(true)
        self.m_respinBarView:setVisible(false)
    elseif _BgIndex == 3 then
        self:findChild("Node_BaseReel"):setVisible(false)
        self:findChild("Node_FreeReel"):setVisible(false)
        self:findChild("Node_base_Jackpot"):setVisible(false)
        self:findChild("Node_feature_Jackpot"):setVisible(true)
        self:findChild("free"):setVisible(false)
        self:findChild("respin"):setVisible(true)
        self:findChild("deng"):setVisible(true)
        self:runCsbAction("idle2", true)

        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("free"):setVisible(false)
        self.m_gameBg:findChild("respin"):setVisible(true)
        self.m_gameBg:findChild("bonus"):setVisible(false)
        self.m_gameBg:runCsbAction("idle1")

        self.m_baseFreeSpinBar:setVisible(false)
        self.m_respinBarView:setVisible(true)
    elseif _BgIndex == 4 then
        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("free"):setVisible(false)
        self.m_gameBg:findChild("respin"):setVisible(false)
        self.m_gameBg:findChild("bonus"):setVisible(true)
        -- self.m_gameBg:runCsbAction("idle1")

        self:findChild("Node_1"):setVisible(false)
        self:findChild("Node_bonus"):setVisible(true)

        -- 隐藏下条目
        self.m_bottomUI:setVisible(false)
    end
end

function CodeGameScreenStarryAnniversaryMachine:enterGamePlayMusic(  )
    self.m_guochangBonusEffect:setVisible(true)
    util_spinePlay(self.m_guochangBonusEffect, "start", false)
    -- 结束 55帧
    util_spineEndCallFunc(self.m_guochangBonusEffect, "start", function ()
        self.m_guochangBonusEffect:setVisible(false)
    end)
    self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_comeGame)
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_enter_game)
    end)
end

function CodeGameScreenStarryAnniversaryMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isDuanXian = true
    CodeGameScreenStarryAnniversaryMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:updateCollectData()
    self.m_progressBar:updateLoadingbar(self.m_collectData.curBonusNums, self.m_collectData.maxBonusNums, true)

    self:upateBetLevel(true)

    -- 打开提醒框
    self:showTipsOpenView(true)
end

function CodeGameScreenStarryAnniversaryMachine:addObservers()
    CodeGameScreenStarryAnniversaryMachine.super.addObservers(self)
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

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_StarryAnniversary_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_StarryAnniversary_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- 高低bet
    gLobalNoticManager:addObserver(self,function(self,params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:upateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    -- 点击解锁进度条
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_iBetLevel == 0 then
            self:unlockHigherBet()
        end
    end,"SHOW_UNLOCK_PROGRESS")

    -- 点击 弹出说明弹板
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_progressBar.m_tipsNode:isVisible() then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_click)
            self:showTipsOverView()
        else
            if self.getGameSpinStage() == IDLE then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_click)
                self:showTipsOpenView()
            end
        end
    end,"SHOW_TIPS")
end

function CodeGameScreenStarryAnniversaryMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenStarryAnniversaryMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenStarryAnniversaryMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS  then
        return "Socre_StarryAnniversary_Bonus1"
    elseif symbolType == self.SYMBOL_EMPTY then
        return "Socre_StarryAnniversary_Empty"
    end 

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenStarryAnniversaryMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenStarryAnniversaryMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS, count = 2}

    return loadNode
end

--[[
    进度条
]]
function CodeGameScreenStarryAnniversaryMachine:initProgress()
    self.m_progressBar = util_createView("StarryAnniversarySrc.StarryAnniversaryProgressBarView")
    -- self:findChild("Node_Collection"):addChild(self.m_progressBar)
    self.m_clipParent:addChild(self.m_progressBar, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - 100)
    self.m_progressBar:setPosition(util_convertToNodeSpace(self:findChild("Node_Collection"), self.m_clipParent))

    local pos = util_convertToNodeSpace(self.m_progressBar.m_tipsNode, self:findChild("Node_Collection"))
    util_changeNodeParent(self:findChild("Node_Collection"), self.m_progressBar.m_tipsNode)
    self.m_progressBar.m_tipsNode:setPosition(pos)
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenStarryAnniversaryMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:freeSpinOrRespinShow(false)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenStarryAnniversaryMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 
    self.m_isDuanXian = false
    if self.m_scheduleId then
        self:showTipsOverView()
    end

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenStarryAnniversaryMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and self:getGameSpinStage() ~= QUICK_RUN then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
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

    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 

    self:reelStopHideMask(reelCol)

    return isTriggerLongRun
end

function CodeGameScreenStarryAnniversaryMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and self:getGameSpinStage() ~= QUICK_RUN then
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

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end

--[[
    滚轮停止
]]
function CodeGameScreenStarryAnniversaryMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenStarryAnniversaryMachine.super.slotReelDown(self)
end

function CodeGameScreenStarryAnniversaryMachine:getBottomUINode()
    return "StarryAnniversarySrc.StarryAnniversaryGameBottomNode"
end
---------------------------------------------------------------------------

--[[
    判断是否 触发 收集bonus
]]
function CodeGameScreenStarryAnniversaryMachine:getIsTriggerCollect( )
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    if node.p_symbolType == self.SYMBOL_BONUS then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end

        if self.m_collectList and #self.m_collectList > 0 then
            return true
        end
    end

    return false
end

--[[
    判断是否 触发 wild 连线
]]
function CodeGameScreenStarryAnniversaryMachine:getIsTriggerChangeWild( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData 
    if selfdata and selfdata.wildIndex and #selfdata.wildIndex > 0 then
        return true
    end
    return false
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenStarryAnniversaryMachine:addSelfEffect()
    if self:getIsTriggerCollect() then
        --收集星星
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_TYPE_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
    end

    if self:getIsTriggerChangeWild() then
        --wild 变化
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_CHANGE_WILD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_CHANGE_WILD
    end
end

--[[
    获取星星飞行之前的延迟时间
    星星飞之前 bonus 有落地动画 区分一下 4 5列的延迟时间
]]
function CodeGameScreenStarryAnniversaryMachine:getBonusXingXingFlyTime( )
    local delayTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_FIX_BONUS then
                    if iCol == 5 then
                        delayTime = 5/30
                    end
                end
            end
        end
    end
    if self.m_isQuicklyStop then
        delayTime = 5/30
    end

    return delayTime
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenStarryAnniversaryMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        local delayTime = self:getBonusXingXingFlyTime()
        self:delayCallBack(delayTime,function()
            self:playEffect_collectBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_CHANGE_WILD then
        self:playEffect_changeWild(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

function CodeGameScreenStarryAnniversaryMachine:beginReel()
    self.m_isQuicklyStop = false
    self.m_fsReelDataIndex = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData and selfData.selectValue then
        self.m_fsReelDataIndex = tonumber(selfData.selectValue)
    end
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and not self:checktriggerSpecialGame() then
        self:showColorLayer()
    end
    
    CodeGameScreenStarryAnniversaryMachine.super.beginReel(self)
end

---
-- 点击快速停止reel
--
function CodeGameScreenStarryAnniversaryMachine:quicklyStopReel(colIndex)
    self.m_isQuicklyStop = true
    CodeGameScreenStarryAnniversaryMachine.super.quicklyStopReel(self, colIndex)
end

---------------------------------------------------collect 相关-------start-------------------------------------------

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenStarryAnniversaryMachine:MachineRule_afterNetWorkLineLogicCalculate()
    CodeGameScreenStarryAnniversaryMachine.super.MachineRule_afterNetWorkLineLogicCalculate(self)
    self:updateCollectData()
end

--更新最大收集和当前收集
function CodeGameScreenStarryAnniversaryMachine:updateCollectData( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local features = self.m_runSpinResultData.p_features
    if selfdata then
        self.m_collectData.maxBonusNums = selfdata.bonusTriggerLimitNumber or 100
        self.m_collectData.curBonusNums = selfdata.bonusTriggerNumber or 0
    else
        self.m_collectData.maxBonusNums = 100
        self.m_collectData.curBonusNums = 0
    end
end

--刷新进度条
function CodeGameScreenStarryAnniversaryMachine:updateCollectLoading(_curBonusNums, _maxBonusNums, _func)
    if _curBonusNums and _maxBonusNums  then
        self.m_progressBar:updateLoadingbar(_curBonusNums, _maxBonusNums , false, _func)
    end
end

--[[
    处理 收集星星
]]
function CodeGameScreenStarryAnniversaryMachine:playEffect_collectBonus(_func)
    local maxBonusNums = self.m_collectData.maxBonusNums 
    local curBonusNums =  self.m_collectData.curBonusNums 

    if self.m_collectList and #self.m_collectList > 0 then
        self:flyXingXingSymbol(self.m_collectList,function()
            if self:getBetLevel() == 0 then return end
            --这里刷新进度条 
            self:updateCollectLoading(curBonusNums ,maxBonusNums, function()
                -- 进度条满 才会触发地图玩法
                -- 写到这里为了 防止加速的时候 进度条显示有问题
                if curBonusNums >= maxBonusNums then
                    --进入地图
                    if _func then
                        _func()
                    end
                end
            end)
        end)

        self.m_collectList = nil
    end

    if curBonusNums < maxBonusNums then
        if _func then
            _func()
        end
    end
end

--[[
    收集玩法
]]
function CodeGameScreenStarryAnniversaryMachine:flyXingXingSymbol(_bonuslist, _func)
    local endPos = util_convertToNodeSpace(self.m_progressBar:findChild("Node_star"), self.m_effectNode)

    if self:getBetLevel() == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonus_collect)
    end
    for _, _node in pairs(_bonuslist) do
        local startPos = util_convertToNodeSpace(_node, self.m_effectNode)
        if self:getBetLevel() == 1 then
            _node:runAnim("shouji2", false, function()
                _node:runAnim("idleframe2", true)
            end)
            self:delayCallBack(3/30, function()
                self:runFlyLineAct(startPos, endPos)
            end)
        end
    end

    if _bonuslist and #_bonuslist > 0 then
        local delayTime = 0
        if self:getBetLevel() == 1 then
            delayTime = 12/30
        end   
        self:delayCallBack(delayTime, function(  )
            if _func then
                _func()
            end
            if self:getBetLevel() == 1 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonus_collect_end)
            end
        end)
    else
        if _func then
            _func()
        end
    end
end

--[[
    收集星星 飞
]]
function CodeGameScreenStarryAnniversaryMachine:runFlyLineAct(_startPos, _endPos)
    local flyNode = util_spineCreate("Socre_StarryAnniversary_Bonus1", true, true)
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(cc.p(_startPos))

    util_spinePlay(flyNode, "shouji")
    local seq = cc.Sequence:create({
        cc.MoveTo:create(12/30, _endPos),
        cc.CallFunc:create(function(  )
            flyNode:setVisible(false)
        end),
        cc.DelayTime:create(0.2),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

--[[
    处理 wild变化
]]
function CodeGameScreenStarryAnniversaryMachine:playEffect_changeWild(_func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData 
    if selfdata and selfdata.wildIndex and #selfdata.wildIndex > 0 then
        self.m_openBonusSkip:setVisible(true)
        self.m_bottomUI:setSkipBonusBtnVisible(true)
        self.m_openBonusSkip:setSkipCallBack(function()
            self.m_openBonusSkip:stopAllActions()
            self:hideQuickStopBtn()
            -- 立即刷新所有连线的wild图标
            self:skipChangeWildSymbolUpDateReel(_func)
            if self.m_wildChangeSound then
                gLobalSoundManager:stopAudio(self.m_wildChangeSound)
                self.m_wildChangeSound = nil
            end
        end)

        self.m_wildChangeSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_wild_change)
        for _, _wildPos in ipairs(selfdata.wildIndex) do
            local slotNode = self:getSymbolByPosIndex(_wildPos)
            if slotNode then
                local slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 2000)
                slotNode:runAnim("switch", false)
            end
        end
        performWithDelay(self.m_openBonusSkip, function()
            self:hideQuickStopBtn()

            if _func then
                _func()
            end
        end, 2)
    else
        if _func then
            _func()
        end
    end
end

--[[
    隐藏快停
]]
function CodeGameScreenStarryAnniversaryMachine:hideQuickStopBtn( )
    self.m_openBonusSkip:clearSkipCallBack()
    self.m_openBonusSkip:setVisible(false)
    self.m_bottomUI:setSkipBonusBtnVisible(false)
end

--[[
    立即刷新所有连线的wild图标
]]
function CodeGameScreenStarryAnniversaryMachine:skipChangeWildSymbolUpDateReel(_func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData 
    if selfdata and selfdata.wildIndex and #selfdata.wildIndex > 0 then
        for _, _wildPos in ipairs(selfdata.wildIndex) do
            local slotNode = self:getSymbolByPosIndex(_wildPos)
            if slotNode then
                local slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 2000)
                slotNode:runAnim("idleframe2", false)
            end
        end
        if _func then
            _func()
        end
    end
end

function CodeGameScreenStarryAnniversaryMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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
            for checkIndex = 1, #self.m_lineSlotNodes do
                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
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
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode == nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                        if slotNode == nil then
                            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode == nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                    if slotNode == nil then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex = 1, #specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenStarryAnniversaryMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotsNode:runAnim("idleframe2")
            else
                slotsNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenStarryAnniversaryMachine:resetMaskLayerNodes()
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
                if lineNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    lineNode:runAnim("idleframe2")
                else
                    lineNode:runIdleAnim()
                end
            end
        end
    end
end

---------------------------------------------------collect相关-------end-------------------------------------------

function CodeGameScreenStarryAnniversaryMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenStarryAnniversaryMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenStarryAnniversaryMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_free_scatter_trigger)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenStarryAnniversaryMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenStarryAnniversaryMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenStarryAnniversaryMachine:checkRemoveBigMegaEffect()
    CodeGameScreenStarryAnniversaryMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenStarryAnniversaryMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("StarryAnniversarySrc.StarryAnniversaryFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_jackPotBarFeatureView:findChild("Node_FreeGameBar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点

    -- respin 计数框
    self.m_respinBarView = util_createView("StarryAnniversarySrc.StarryAnniversaryRespinBar", {machine = self})
    self.m_jackPotBarFeatureView:findChild("Node_RespinBar"):addChild(self.m_respinBarView)
    self.m_respinBarView:setVisible(false)
end

function CodeGameScreenStarryAnniversaryMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_free_more)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            for index = 1, 2 do
                local roleSpine = util_spineCreate("Socre_StarryAnniversary_Scatter", true, true)
                view:findChild("spine"..index):addChild(roleSpine)
                util_spinePlay(roleSpine, "freespinmore_idle", true)

                util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
                util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
            end
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenStarryAnniversaryMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("StarryAnniversarySounds/music_StarryAnniversary_over_fs.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:triggerFreeSpinOverCallFun()
        end
    )
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_overView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_StarryAnniversary_click
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_overView_over)
        self:freeSpinOrRespinOverShow(false)
    end)

    if strCoins ~= "0" then
        for index = 1, 2 do
            local roleSpine = util_spineCreate("Socre_StarryAnniversary_Scatter", true, true)
            view:findChild("spine"..index):addChild(roleSpine)
            util_spinePlay(roleSpine, "freespinover_idle", true)

            util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
            util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
        end

        for index = 6, 9 do
            local roleSpine = util_spineCreate("Socre_StarryAnniversary_"..index, true, true)
            view:findChild("spine"..index):addChild(roleSpine)
            util_spinePlay(roleSpine, "freespinover_idle", true)

            util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
            util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
        end

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},668)   
    end 

    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenStarryAnniversaryMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if coins == "0" then
        return self:showDialog("FreeSpinOver_NoWin", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenStarryAnniversaryMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

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

    if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and not self:checkHasGameEffectType(GameEffect.EFFECT_BIG_WIN_LIGHT) then
        self:playWinCoinsBottom(self.m_iOnceSpinLastWin)
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    local waitTime = 0
    if scatterLineValue ~= nil then
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
        local frameNum = scatterLineValue.iLineSymbolNum
        for i=1, frameNum do
            local symPosData = scatterLineValue.vecValidMatrixSymPos[i]
            local slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
            if slotNode then
                local parent = slotNode:getParent()
                slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, scatterLineValue.enumSymbolType, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 10000)
                slotNode:runAnim("actionframe")
                local duration = slotNode:getAniamDurationByName("actionframe")
                waitTime = util_max(waitTime,duration)
            end
        end
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
    else
        if device.platform == "mac" then
            assert(false, "服务器没给连线数据")
        end
    end
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

-- 继承底层respinView
function CodeGameScreenStarryAnniversaryMachine:getRespinView()
    return "StarryAnniversarySrc.StarryAnniversaryRespinView"    
end

-- 继承底层respinNode
function CodeGameScreenStarryAnniversaryMachine:getRespinNode()
    return "StarryAnniversarySrc.StarryAnniversaryRespinNode"    
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenStarryAnniversaryMachine:getReSpinSymbolScore(_pos)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local addStoredIcons = selfMakeData.addStoredIcons or {}
    local score = nil
    local type = nil

    for _index, _storeData in pairs(storedIcons) do
        if tonumber(_storeData[1]) == _pos then
            score = _storeData[2]
            type = _storeData[3]
            break
        end
    end

    if score == nil then
       return 0, "bonus"
    end

    return score, type
end

function CodeGameScreenStarryAnniversaryMachine:randomDownRespinSymbolScore(symbolType)
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
    return score, type
end

-- 给respin小块进行赋值
function CodeGameScreenStarryAnniversaryMachine:setSpecialNodeScore(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if self:isFixSymbol(symbolNode.p_symbolType) then
        -- 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local coinsView
        if not spineNode.m_csbNode then
            coinsView = util_createAnimation("Socre_StarryAnniversary_BonusCoins.csb")
            util_spinePushBindNode(spineNode, "guadian", coinsView)
            spineNode.m_csbNode = coinsView
        else
            coinsView = spineNode.m_csbNode
        end

        local score = 0
        local type = nil
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow,iCol))
        else
            if self.m_isDuanXian then
                score, type = self.m_initBonusValue[iCol][1], self.m_initBonusValue[iCol][2]
                if score ~= 0 then
                    score = score * globalData.slotRunData:getCurTotalBet()
                end
            else
                score, type = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
            end
        end
        self:showBonusJackpotOrCoins(coinsView, score, type, spineNode)
    elseif symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        if not spineNode.m_fbCsbNode then
            local fbid = globalData.userRunData.facebookBindingID
            local headName = 1 --globalData.userRunData.HeadName or 1
            local frameId = nil --globalData.userRunData.avatarFrameId
            if fbid ~= "" then
                headName = nil
            end
            local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, cc.size(115, 115))
            util_spinePushBindNode(spineNode, "guadian", nodeAvatar)
            spineNode.m_fbCsbNode = nodeAvatar
            nodeAvatar.m_nodeAvatar:setPositionY(5)
        end
    end
end

--[[
    显示bonus上的信息
]]
function CodeGameScreenStarryAnniversaryMachine:showBonusJackpotOrCoins(coinsView, score, type, spineNode)
    if not tolua.isnull(coinsView) then
        if type == "bonus" then
            local labCoins = coinsView:findChild("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3, false, true, true))
            self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 136)
            spineNode:setSkin("shuzi")
            coinsView:setVisible(true)
        else  
            spineNode:setSkin(string.lower(type))
            coinsView:setVisible(false)
        end
    end
end

function CodeGameScreenStarryAnniversaryMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    self:setSpecialNodeScore(node)   
end

-- 是不是 respinBonus小块
function CodeGameScreenStarryAnniversaryMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return true
    end
    return false    
end

-- 结束respin收集
function CodeGameScreenStarryAnniversaryMachine:playLightEffectEnd()
    self:delayCallBack(0.5, function()
        -- 通知respin结束
        self:respinOver()    
    end) 
end

function CodeGameScreenStarryAnniversaryMachine:getJackpotScore(_jpName)
    local jackpotCoinData = self.m_runSpinResultData.p_jackpotCoins or {}
    local coins = jackpotCoinData[_jpName]
    return coins    
end

--[[
    改变respin图标的层级
]]
function CodeGameScreenStarryAnniversaryMachine:changeRespinBonusZOrder( )
    for _, _chipNode in ipairs(self.m_chipList) do
        if _chipNode and _chipNode.p_symbolType then
            
        end
    end
end

function CodeGameScreenStarryAnniversaryMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        self:playLightEffectEnd()
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex

    -- 根据网络数据获得当前固定小块的分数
    local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))

    self.m_lightScore = self.m_lightScore + score

    local function runCollect()
        if type == "bonus" then
            self:playBonusJieSuanEffect(false, chipNode, score, function()
                self.m_playAnimIndex = self. m_playAnimIndex + 1
                self:playChipCollectAnim()
            end)
        else
            self:playBonusJieSuanEffect(true, chipNode, score, function()
                self.m_jackPotBarFeatureView:playWinJackpotEffect(type)
                self:showJackpotView(score, type, function()
                    self.m_jackPotBarFeatureView:hideWinJackpotEffect(type)
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    self:playChipCollectAnim()
                end)
            end)
        end
    end
    runCollect()    
end

--[[
    结算每个bonus的动画
]]
function CodeGameScreenStarryAnniversaryMachine:playBonusJieSuanEffect(_isJackpot, _node, _addCoins, _func)
    if not tolua.isnull(_node) and _node.p_symbolType then
        local actionName = "over_shouji"
        if _isJackpot then
            actionName = "over_shouji2"
        end
        local nodePos = util_convertToNodeSpace(_node, self.m_effectNode)
        local oldParent = _node:getParent()
        local oldPosition = cc.p(_node:getPosition())
        util_changeNodeParent(self.m_effectNode, _node, 0)
        _node:setPosition(nodePos)
        if _isJackpot then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_jackpot_win)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_bonus_fly)
        end

        _node:runAnim(actionName, false, function()
            if not tolua.isnull(_node) then
                util_changeNodeParent(oldParent, _node, REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - _node.p_rowIndex + _node.p_cloumnIndex)
                _node:setPosition(oldPosition)
                _node:runAnim("over_shouji_idle", false)
            end
            if not _isJackpot then
                if _func then
                    _func()
                end
            end
        end)
        if _isJackpot then
            self:moveRootNodeAction(_node)
            self:delayCallBack(0.8, function()
                self:resetMoveNodeStatus(_func)
            end)
        end
    end

    self:playWinCoinsBottom(_addCoins)

    local params = {
        overCoins  = _addCoins,
        jumpTime   = 1/60,
        animName   = "actionframe2",
    }
    self:playBottomBigWinLabAnim(params)
    self:playCoinWinEffectUI()
end

--[[
    显示赢钱区的钱
]]
function CodeGameScreenStarryAnniversaryMachine:playWinCoinsBottom(_addCoins)
    -- self:playCoinWinEffectUI()
    -- 刷新底栏
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + _addCoins)
    self.m_bottomUI.m_changeLabJumpTime = 0.2
    self:updateBottomUICoins(0, _addCoins, false, true, false)
    self.m_bottomUI.m_changeLabJumpTime = nil
end

--获取底栏金币
function CodeGameScreenStarryAnniversaryMachine:getCurBottomWinCoins()
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
function CodeGameScreenStarryAnniversaryMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--结束移除小块调用结算特效
function CodeGameScreenStarryAnniversaryMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()
    if self.m_respinRunSound then
        gLobalSoundManager:stopAudio(self.m_respinRunSound)
        self.m_respinRunSound = nil
    end
    self.m_lightEffectNode:removeAllChildren(true)

    self:changeBottomBigWinLabUi("CommonButton/csb_slot/totalwin_shuzi.csb")

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    table.sort(self.m_chipList, function(a, b)
        if a.p_cloumnIndex == b.p_cloumnIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return a.p_cloumnIndex < b.p_cloumnIndex
    end)

    self:delayCallBack(0.5, function()
        -- 集满棋盘
        if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum) then
            self.m_respinJiManEffect:setVisible(true)
            self.m_respinJiManEffect:findChild("zi"):setVisible(true)
            gLobalSoundManager:playSound("StarryAnniversarySounds/sound_StarryAnniversary_respin_jiman.mp3")
            self.m_respinJiManEffect:runCsbAction("actionframe", false, function()
                self.m_respinJiManEffect:findChild("zi"):setVisible(false)
            end)
            
            self:delayCallBack(170/60, function()
                -- 如果全部都固定了，会中JackPot档位中的Grand
                local jackpotScore = self:getJackpotScore("Grand")
                self.m_lightScore = self.m_lightScore + jackpotScore
                self.m_jackPotBarFeatureView:playWinJackpotEffect("grand")
                self:showJackpotView(
                    jackpotScore,
                    "grand",
                    function()
                        self:playWinCoinsBottom(jackpotScore)
                        self.m_jackPotBarFeatureView:hideWinJackpotEffect("grand")

                        self:delayCallBack(0.5, function()
                            self:playBonusEffectOfRespinEnd(function()
                                self:playChipCollectAnim()   
                            end)
                        end)
                    end,
                    function()
                        self.m_respinJiManEffect:runCsbAction("over", false, function()
                            self.m_respinJiManEffect:setVisible(false)
                        end)
                    end
                )
            end)
        else
            self:playBonusEffectOfRespinEnd(function()
                self:playChipCollectAnim()   
            end)
        end
    end)
end

--[[
    结算前 播放触发动画
]]
function CodeGameScreenStarryAnniversaryMachine:playBonusEffectOfRespinEnd(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_bonus_win)
    for _, _chipNode in ipairs(self.m_chipList) do
        if _chipNode and _chipNode.p_symbolType then
            local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(_chipNode.p_rowIndex, _chipNode.p_cloumnIndex))
            local overName = "over2"
            if type == "bonus" then
                overName = "over"
            end
            _chipNode:runAnim(overName, false, function()
                _chipNode:runAnim("over_idle", true)
            end)
        end
    end

    self:delayCallBack(45/30 + 0.5, function()
        if _func then
            _func()
        end
    end)
end

---判断结算
function CodeGameScreenStarryAnniversaryMachine:reSpinReelDown(addNode)
    self:runQuickEffect()
    self:removeLightRespin()

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    -- if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
    --     self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    -- end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    self:runNextReSpinReel()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

function CodeGameScreenStarryAnniversaryMachine:setReelSlotsNodeVisible(status)
    CodeGameScreenStarryAnniversaryMachine.super.setReelSlotsNodeVisible(self, status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
            end
        end
    end
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenStarryAnniversaryMachine:getRespinRandomTypes()
    local symbolList = { self.SYMBOL_BONUS,
        self.SYMBOL_EMPTY}
    return symbolList    
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenStarryAnniversaryMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling2", bRandom = true}
    }
    return symbolList    
end

---
-- 触发respin 玩法
--
function CodeGameScreenStarryAnniversaryMachine:showEffect_Respin(effectData)
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

function CodeGameScreenStarryAnniversaryMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    self.m_lightScore = 0   

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    --先播放动画 再进入respin
    self:triggerRespinAni(function()
        self:showReSpinStart(function()
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            self:playGuoChangRespinEffect(true, function()
                --可随机的普通信息
                local randomTypes = self:getRespinRandomTypes( )
                --可随机的特殊信号 
                local endTypes = self:getRespinLockTypes()
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)

                self:freeSpinOrRespinShow(true)

                self:runQuickEffect()

            end, function()

            end, true)
        end)
    end)
end

function CodeGameScreenStarryAnniversaryMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount, true)
            -- -- 更改respin 状态下的背景音乐
            -- self:changeReSpinBgMusic()
            self:runNextReSpinReel()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenStarryAnniversaryMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
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
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

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

function CodeGameScreenStarryAnniversaryMachine:showReSpinStart(func)
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_start)
    local view = self:showDialog("ReSpinStart", nil, func, BaseDialog.AUTO_TYPE_ONLY)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
    view:findChild("root"):setScale(self.m_machineRootScale)
    
    for index = 1, 2 do
        local roleSpine = util_spineCreate("Socre_StarryAnniversary_Scatter", true, true)
        view:findChild("spine"..index):addChild(roleSpine)
        util_spinePlay(roleSpine, "freespinmore_idle", true)

        util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
        util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
    end
end

--[[
    respin触发动画
]]
function CodeGameScreenStarryAnniversaryMachine:triggerRespinAni(func)
    local delayTime = 0

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonus_trigger)
    --触发动画
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
            util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 10000)
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

--开始滚动
function CodeGameScreenStarryAnniversaryMachine:startReSpinRun()
    self.m_isPlayUpdateRespinNums = true
    self.m_bonus_down = {}
    self.m_respinReelDownSound = {}
    self.m_isDuanXian = false
    CodeGameScreenStarryAnniversaryMachine.super.startReSpinRun(self)
end

--ReSpin开始改变UI状态
function CodeGameScreenStarryAnniversaryMachine:changeReSpinStartUI(respinCount)
        
end

--ReSpin刷新数量
function CodeGameScreenStarryAnniversaryMachine:changeReSpinUpdateUI(curCount, isComeIn)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinBarView:updateRespinCount(curCount, isComeIn)
end

--ReSpin结算改变UI状态
function CodeGameScreenStarryAnniversaryMachine:changeReSpinOverUI()
        
end

function CodeGameScreenStarryAnniversaryMachine:respinOver()
    
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    self:showRespinOverView()
end

function CodeGameScreenStarryAnniversaryMachine:showRespinOverView(effectData)
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:playGuoChangRespinEffect(false, function()
            self:changeBottomBigWinLabUi("StarryAnniversary_bigwin_number.csb")
            self:setReelSlotsNodeVisible(true)
            self:removeRespinNode()

            self:freeSpinOrRespinOverShow(true)
            self:changeEmptySymbol()
        end, function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
        end)
    end)
    for index = 1, 2 do
        local roleSpine = util_spineCreate("Socre_StarryAnniversary_Scatter", true, true)
        view:findChild("spine"..index):addChild(roleSpine)
        util_spinePlay(roleSpine, "freespinover_idle", true)

        util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
        util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
    end

    for index = 6, 9 do
        local roleSpine = util_spineCreate("Socre_StarryAnniversary_"..index, true, true)
        view:findChild("spine"..index):addChild(roleSpine)
        util_spinePlay(roleSpine, "freespinover_idle", true)

        util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
        util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_overView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_StarryAnniversary_click
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_overView_over)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},668)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--respin结束 移除respin小块对应位置滚轴中的小块
function CodeGameScreenStarryAnniversaryMachine:checkRemoveReelNode(node)
    local targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    local slotParentBig = self:getReelBigParent(node.p_cloumnIndex)
    if targSp == nil and slotParentBig then
        targSp = slotParentBig:getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
    end
    if targSp == nil then
        targSp = self:getFixSymbol(node.p_cloumnIndex, node.p_rowIndex)
    end
    if targSp == nil and self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[node.p_cloumnIndex] ~= nil and node.p_rowIndex == 1 then
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[node.p_cloumnIndex]
        for k = 1, #bigSymbolInfos do
            local bigSymbolInfo = bigSymbolInfos[k]
            for changeIndex = 1, #bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == node.p_rowIndex then
                    targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(node.p_cloumnIndex * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                    if targSp == nil and slotParentBig then
                        targSp = slotParentBig:getChildByTag(node.p_cloumnIndex * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                    end
                    break
                end
            end
        end
    end

    if targSp then
        targSp:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenStarryAnniversaryMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    local zOrder = self:getBounsScatterDataZorder(node.p_symbolType)
    node.p_showOrder = zOrder - node.p_rowIndex + node.p_cloumnIndex * 10
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
    node:runAnim("idleframe2", true)
end

--[[
    respin结束 棋盘上的空图标 随机变成其他
]]
function CodeGameScreenStarryAnniversaryMachine:changeEmptySymbol( )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_EMPTY then
                    local random = math.random(4, 8)
                    self:changeSymbolType(node, random)
                end
            end
        end
    end
end

function CodeGameScreenStarryAnniversaryMachine:triggerReSpinOverCallFun(score)
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
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
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

-- --重写组织respinData信息
function CodeGameScreenStarryAnniversaryMachine:getRespinSpinData()
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

function CodeGameScreenStarryAnniversaryMachine:initJackPotBarView()
    -- base下jackpot
    self.m_jackPotBarView = util_createView("StarryAnniversarySrc.StarryAnniversaryJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_base_Jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点
    
    -- free respin下jackpot
    self.m_jackPotBarFeatureView = util_createView("StarryAnniversarySrc.StarryAnniversaryJackPotBarFeatureView")
    self.m_jackPotBarFeatureView:initMachine(self)
    self:findChild("Node_feature_Jackpot"):addChild(self.m_jackPotBarFeatureView) --修改成自己的节点
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenStarryAnniversaryMachine:showJackpotView(coins, jackpotType, func1, func2)
    local view = util_createView("StarryAnniversarySrc.StarryAnniversaryJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        func1 = function(  )
            if type(func1) == "function" then
                func1()
            end
        end,
        func2 = function(  )
            if type(func2) == "function" then
                func2()
            end
        end,
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenStarryAnniversaryMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] and self:checkSymbolBulingAnimPlay(_slotNode) then
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
                else
                    if _slotNode.p_symbolType == self.SYMBOL_BONUS then
                        _slotNode:runAnim("idleframe2", true)
                    end
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
            end
        end
    end
end

function CodeGameScreenStarryAnniversaryMachine:symbolBulingEndCallBack(_slotNode)
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

function CodeGameScreenStarryAnniversaryMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    table.insert(longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenStarryAnniversaryMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenStarryAnniversaryMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenStarryAnniversaryMachine:isPlayExpect(reelCol)
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
        播放预告中奖统一接口
    ]]
function CodeGameScreenStarryAnniversaryMachine:showFeatureGameTip(_func)
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

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenStarryAnniversaryMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = true

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_yugao)
    self.m_yugaoSpineEffect:setVisible(true)
    util_spinePlay(self.m_yugaoSpineEffect,"actionframe",false)
    util_spineEndCallFunc(self.m_yugaoSpineEffect, "actionframe" ,function ()
        self.m_yugaoSpineEffect:setVisible(false)

        if type(func) == "function" then
            func()
        end
    end) 
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenStarryAnniversaryMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)

    self.m_bigWinEffect:setVisible(true)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bigWin)

    local features = self.m_runSpinResultData.p_features
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if #features > 1 and features[2] == 5 then
        if selfdata and selfdata.initTimes and selfdata.initTimes > 0 then
        else
            if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, true, true})
            end
        end
    end

    util_spinePlay(self.m_bigWinEffect, "actionframe")
    util_spineEndCallFunc(self.m_bigWinEffect, "actionframe", function()
        self.m_bigWinEffect:setVisible(true)
        if type(func) == "function" then
            func()
        end
    end)
end

--设置bonus scatter 层级
function CodeGameScreenStarryAnniversaryMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenStarryAnniversaryMachine.super.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    return order
end

----------------------------------------高低bet start----------------------------------------
--[[
    打开tips
]]
function CodeGameScreenStarryAnniversaryMachine:showTipsOpenView(_isComeIn)
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return
    end
    if not _isComeIn then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_tips_start)
    end
    self.m_progressBar.m_tipsNode:setVisible(true)
    self.m_progressBar.m_tipsNode:runCsbAction("start",false,function()
        self.m_progressBar.m_tipsNode:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:showTipsOverView()
        end, 5)
    end)
    
end

--[[
    关闭tips
]]
function CodeGameScreenStarryAnniversaryMachine:showTipsOverView( )
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_tips_over)
        self.m_progressBar.m_tipsNode:runCsbAction("over",false,function()
            self.m_progressBar.m_tipsNode:setVisible(false)
        end)
    end
end

function CodeGameScreenStarryAnniversaryMachine:getBetLevel( )
    return self.m_iBetLevel
end

function CodeGameScreenStarryAnniversaryMachine:unlockHigherBet()
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

    if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
        self.m_iBetLevel = 1 
        -- 解锁进度条
        self.m_progressBar:unLock()
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
        if bets.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenStarryAnniversaryMachine:updatProgressLock( minBet , _isComeIn)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if _isComeIn then
        if betCoin >= minBet  then
            self.m_iBetLevel = 1 
            -- 解锁进度条
            self.m_progressBar:unLock(_isComeIn)
        else
            self.m_iBetLevel = 0  
            -- 锁定进度条
            self.m_progressBar:lock(_isComeIn)
        end 
    else
        if betCoin >= minBet  then
            if self.m_iBetLevel == nil or self.m_iBetLevel == 0 then
                self.m_iBetLevel = 1 
                -- 解锁进度条
                self.m_progressBar:unLock()
            end
        else
            if self.m_iBetLevel == nil or self.m_iBetLevel == 1 then
                self.m_iBetLevel = 0  
                -- 锁定进度条
                self.m_progressBar:lock()
            end
        end 
    end
end

function CodeGameScreenStarryAnniversaryMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenStarryAnniversaryMachine:upateBetLevel(_isComeIn)
    local minBet = self:getMinBet()
    self:updatProgressLock(minBet, _isComeIn) 
end

----------------------------------------高低bet end----------------------------------------

----------- FreeSpin相关
---
----- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenStarryAnniversaryMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=symPosData.iX})
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
        end

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]
                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=bigSymbolInfo.startRowIndex})
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 10000)
            slotNode:runAnim("actionframe", false) -- 57帧
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenStarryAnniversaryMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.initTimes and selfdata.initTimes > 0 then
    else
        if not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and not self:checkHasGameEffectType(GameEffect.EFFECT_BIG_WIN_LIGHT) then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, true, true})
        end
    end
    
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
        
        local selfdata = self.m_runSpinResultData.p_selfMakeData
        if selfdata and selfdata.initTimes and selfdata.initTimes > 0 then
            -- 播放提示时播放音效
            self:playBonusTipMusicEffect()
        else
            -- 停止播放背景音乐
            self:clearCurMusicBg()
            self:playScatterTipMusicEffect()
        end
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenStarryAnniversaryMachine:showBonusGameView(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.initTimes and selfdata.initTimes > 0 then
        -- 停止播放背景音乐
        self:clearCurMusicBg()
        self:playBonusGameTriggerEffect(function()
            local view = self:showDialog("BreakEggsStart", nil, function()
                self:resetMusicBg(nil,"StarryAnniversarySounds/music_StarryAnniversary_bonus.mp3")
                self:playGuoChangBonusEffect(true, function()
                    self:setReelBg(4)
                    self.m_runSpinResultData.p_features = {0}
                    self.m_bonusGameView:setVisible(true)
                    self.m_bonusGameView:updateBonusGame()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                    self.m_bonusGameView:setEndCall(function(coins)
                        self:showBonusGameOverView(coins)
                    end)
                    self.m_progressBar:playEggsIdleEffect()
                end, function()
                    self:delayCallBack(0.5, function()
                        self.m_bonusGameView:startBonusGame()
                    end)
                end)
                effectData.p_isPlay = true
            end)
            
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonusView_start)
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_StarryAnniversary_click
            view:setBtnClickFunc(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonusView_over)
            end)

            --光
            local guangNode = util_createAnimation("StarryAnniversary_tanban_guang.csb")
            view:findChild("Node_guang"):addChild(guangNode)
            guangNode:runCsbAction("idle", true)
            util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"), true)
            util_setCascadeColorEnabledRescursion(view:findChild("Node_guang"), true)
            for index = 1, 2 do
                local roleSpine = util_spineCreate("Socre_StarryAnniversary_Scatter", true, true)
                view:findChild("spine"..index):addChild(roleSpine)
                util_spinePlay(roleSpine, "freespinmore_idle", true)
    
                util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
                util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
            end
            view:findChild("root"):setScale(self.m_machineRootScale)
        end)
    else
        -- 界面选择回调
        local function chooseCallBack(index)
            self:sendData(index)
            self.m_bIsSelectCall = true
            self.m_iSelectID = index
            self.m_gameEffect = effectData
        end
        effectData.p_isPlay = true

        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            self:showFreatureChooseView(chooseCallBack)
        end
    end
end

--[[
    bonus玩法 结束弹板
]]
function CodeGameScreenStarryAnniversaryMachine:showBonusGameOverView(coins, func)
    -- 停止播放背景音乐
    self:clearCurMusicBg()

    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = self:showDialog("BreakEggsOver", ownerlist, function()
        self:playGuoChangBonusEffect(false, function()
            self:setReelBg(1)
            self.m_bonusGameView:setVisible(false)
            self.m_collectData.curBonusNums = 0
            self.m_progressBar:updateLoadingbar(self.m_collectData.curBonusNums, self.m_collectData.maxBonusNums, true)
        end, function()
            self:resumeLevelSoundHandler()
            self:playGameEffect()
            if func then
                func()
            end
        end)
    end)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonusOverView_start)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_StarryAnniversary_click
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonusOverView_ovet)
    end)

    for index = 1, 2 do
        local roleSpine = util_spineCreate("Socre_StarryAnniversary_Scatter", true, true)
        view:findChild("spine"..index):addChild(roleSpine)
        util_spinePlay(roleSpine, "freespinover_idle", true)

        util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
        util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
    end

    for index = 3, 6 do
        local roleSpine = util_spineCreate("Socre_StarryAnniversary_"..(index+3), true, true)
        view:findChild("spine"..index):addChild(roleSpine)
        util_spinePlay(roleSpine, "freespinover_idle", true)

        util_setCascadeOpacityEnabledRescursion(view:findChild("spine"..index), true)
        util_setCascadeColorEnabledRescursion(view:findChild("spine"..index), true)
    end

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},668)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    收集小游戏 断线处理
]]
function CodeGameScreenStarryAnniversaryMachine:initFeatureInfo(spinData, featureData)
    if (featureData.p_status and featureData.p_status ~= "CLOSED")   then
        self.m_runSpinResultData.p_selfMakeData = featureData.p_data.selfData
        self.m_runSpinResultData.p_bonusWinCoins = featureData.p_data.bonus.bsWinCoins
        self:setReelBg(4)
        self.m_runSpinResultData.p_features = {0}
        self.m_bonusGameView:setVisible(true)
        self.m_bonusGameView:updateBonusGame()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_bonusGameView:setEndCall(function(coins)
            self:showBonusGameOverView(coins)
        end)
        self:delayCallBack(0.5, function()
            self:removeSoundHandler()
            self:resetMusicBg(nil,"StarryAnniversarySounds/music_StarryAnniversary_bonus.mp3")
            self.m_bonusGameView:startBonusGame()
        end)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    end
end

--[[
    二选一界面
]]
function CodeGameScreenStarryAnniversaryMachine:showFreatureChooseView(func)
	local view = util_createView("StarryAnniversarySrc.StarryAnniversaryFeatureChooseView")
    self.m_freeSelectView = view
    view:initViewData(self, func)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    点击二选一界面 发送消息
]]
function CodeGameScreenStarryAnniversaryMachine:sendData(index)
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index-1}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--[[
    gameConfig数据
]]
function CodeGameScreenStarryAnniversaryMachine:initGameStatusData(gameData)
    CodeGameScreenStarryAnniversaryMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.bonusTriggerLimitNumber then
        local selfdata = self.m_runSpinResultData.p_selfMakeData
        if selfdata and selfdata.bonusTriggerLimitNumber then
        else
            self.m_runSpinResultData.p_selfMakeData = {}
        end
        self.m_runSpinResultData.p_selfMakeData.bonusTriggerLimitNumber = gameData.gameConfig.extra.bonusTriggerLimitNumber
        self.m_runSpinResultData.p_selfMakeData.bonusTriggerNumber = gameData.gameConfig.extra.bonusTriggerNumber
    end
end

--[[
    spin结果
]]
function CodeGameScreenStarryAnniversaryMachine:spinResultCallFun(param)
    CodeGameScreenStarryAnniversaryMachine.super.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        if param[1] == true then
            if param[2] and param[2].result then
                if param[2].result.freespin and param[2].result.freespin.freeSpinsLeftCount then
                    globalData.slotRunData.freeSpinCount = param[2].result.freespin.freeSpinsLeftCount
                    globalData.slotRunData.totalFreeSpinCount = param[2].result.freespin.freeSpinsTotalCount
                end

                local spinData = param[2]
                if spinData.action == "FEATURE" then
                    self:operaSpinResultData(param)
                end
                
                self:freeSpinOrRespinShow(false)
                --清空赢钱
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN) 
                self.m_freeSelectView:closeView(function()
                    self.m_freeSelectView = nil
                    self.m_iOnceSpinLastWin = 0
                    self:triggerFreeSpinCallFun()
                    
                    self:delayCallBack(0.5,function (  )
                        self.m_gameEffect.p_isPlay = true
                        self:playGameEffect() 
                    end)
                end)

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Stop,false})
            end
        end
    end
    self.m_bIsSelectCall = false
end

--[[
    free respin 显示
]]
function CodeGameScreenStarryAnniversaryMachine:freeSpinOrRespinShow(_isRespin)
    self.m_jackPotBarView:setVisible(false)
    self.m_jackPotBarFeatureView:setVisible(true)
    self.m_progressBar:setVisible(false)
    self:findChild("Node_Collection"):setVisible(false)
    self:findChild("Image_progress"):setVisible(false)
    
    if not _isRespin then
        self:setReelBg(2)
        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("free"):setVisible(true)
        self.m_gameBg:runCsbAction("over")

        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle2", true)
        end)
    else
        self:setReelBg(3)
    end
end

--[[
    free respin 隐藏
]]
function CodeGameScreenStarryAnniversaryMachine:freeSpinOrRespinOverShow(_isRespin)
    if not _isRespin then
        self:setReelBg(1)
        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("free"):setVisible(true)
        self.m_gameBg:runCsbAction("start")
        self.m_jackPotBarView:setVisible(true)
        self.m_jackPotBarFeatureView:setVisible(false)
        self.m_progressBar:setVisible(true)
        self:findChild("Node_Collection"):setVisible(true)
        self:findChild("Image_progress"):setVisible(true)
    else
        if self.m_bProduceSlots_InFreeSpin then
            self:setReelBg(2)
            self.m_jackPotBarView:setVisible(false)
            self.m_jackPotBarFeatureView:setVisible(true)
            self.m_progressBar:setVisible(false)
            self:findChild("Node_Collection"):setVisible(false)
            self:findChild("Image_progress"):setVisible(false)
        else
            self:setReelBg(1)
            self.m_jackPotBarView:setVisible(true)
            self.m_jackPotBarFeatureView:setVisible(false)
            self.m_progressBar:setVisible(true)
            self:findChild("Node_Collection"):setVisible(true)
            self:findChild("Image_progress"):setVisible(true)
        end
    end
end

--[[
    过场动画 respin
]]
function CodeGameScreenStarryAnniversaryMachine:playGuoChangRespinEffect(_isComeIn, _func1, _func2)
    if _isComeIn then 
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_guochang_baseToRespin)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_guochang_respinToBase)
    end
    self.m_guochangRespinEffect:setVisible(true)
    self.m_guochangRespinEffect:runCsbAction("actionframe", false)
    for particle_index = 1, 2 do
        local particle = self.m_guochangRespinEffect:findChild("Particle_"..particle_index)
        if particle then
            particle:resetSystem()
        end
    end
    -- 切换 110帧
    self:delayCallBack(110/60, function()
        if _func1 then
            _func1()
        end
    end)
    -- 结束 130帧
    self:delayCallBack(130/60, function()
        if _func2 then
            _func2()
        end
        self.m_guochangRespinEffect:setVisible(false)
    end)
end

--[[
    过场动画 bonus
]]

function CodeGameScreenStarryAnniversaryMachine:playGuoChangBonusEffect(_isComeIn, _func1, _func2)
    if _isComeIn then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_guochang_baseToBonus)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_guochang_bonusToBase)
    end

    self.m_guochangBonusEffect:setVisible(true)
    util_spinePlay(self.m_guochangBonusEffect, "actionframe_guochang", false)
    -- 切换 80帧
    util_spineFrameEvent(self.m_guochangBonusEffect, "actionframe_guochang", "switch", function()
        if _func1 then
            _func1()
        end
    end)

    -- 结束 55帧
    util_spineEndCallFunc(self.m_guochangBonusEffect, "actionframe_guochang", function ()
        if _func2 then
            _func2()
        end
        self.m_guochangBonusEffect:setVisible(false)
    end)
end

--[[
    快滚特效 respin
]]
function CodeGameScreenStarryAnniversaryMachine:runQuickEffect()
    self.m_qucikRespinNode = {}
    local bonus_count = #self.m_runSpinResultData.p_storedIcons
    local isLastRespin = self:getIsLastRespin()

    if bonus_count >= 14 then
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
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_quickRun_start)
            self.m_lightEffectNode:removeAllChildren(true)
            for _index = 1, #self.m_qucikRespinNode do
                local quickRunInfo = self.m_qucikRespinNode[_index]
                if not quickRunInfo.isEnd then
                    local light_effect = util_createAnimation("StarryAnniversary_Respinwin.csb")
                    light_effect:runCsbAction("actionframe", true)  --普通滚动状态
                    self.m_lightEffectNode:addChild(light_effect)
                    light_effect:setName("quickRunEffect")
                    light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node, self.m_lightEffectNode))
                    quickRunInfo.node:changeRunSpeed(true, isLastRespin)
                end
            end
        else
            for _index = 1, #self.m_qucikRespinNode do
                local quickRunInfo = self.m_qucikRespinNode[_index]
                if not quickRunInfo.isEnd then
                    quickRunInfo.node:changeRunSpeed(true, isLastRespin)
                end
            end
            if isLastRespin then
                self.m_respinRunSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_respin_quickRun)
                local light_effect = self.m_lightEffectNode:getChildByName("quickRunEffect")
                light_effect:runCsbAction("actionframe2", true)  --普通滚动状态
            end
        end
    end
end

--[[
    移除快滚特效 respin
]]
function CodeGameScreenStarryAnniversaryMachine:removeLightRespin()
    local bonus_count = #self.m_runSpinResultData.p_storedIcons

    if bonus_count >= 15 then
        if self.m_respinRunSound then
            gLobalSoundManager:stopAudio(self.m_respinRunSound)
            self.m_respinRunSound = nil
        end
        self.m_lightEffectNode:removeAllChildren(true)
    end
end

--[[
    判断是否是 respin 最后一次
]]
function CodeGameScreenStarryAnniversaryMachine:getIsLastRespin( )
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount or 1
    local isLastRespin = false
    -- 判断是否是 respin 最后一次
    if reSpinCurCount == 1 then
        isLastRespin = true
    end
    
    return isLastRespin
end

--[[
    bonus 玩法 进度条触发动画
]]
function CodeGameScreenStarryAnniversaryMachine:playBonusGameTriggerEffect(_func)
    self.m_progressBar:playTriggerEffect(_func)
end

function CodeGameScreenStarryAnniversaryMachine:scaleMainLayer()
    CodeGameScreenStarryAnniversaryMachine.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.width / display.height >= 1370/768 then
        self.m_bonusViewScale = self.m_machineRootScale * 1
    elseif display.width / display.height >= 1228/768 then
        mainScale = mainScale * 0.99
        self.m_bonusViewScale = self.m_machineRootScale * 0.88
    elseif display.width / display.height >= 1024/768 then
        mainScale = mainScale * 0.9
        self.m_bonusViewScale = self.m_machineRootScale * 0.87
    elseif display.width / display.height >= 920/768 then
        mainScale = mainScale * 0.84
        self.m_bonusViewScale = self.m_machineRootScale * 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(-2)
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenStarryAnniversaryMachine:initSlotNodes()
    CodeGameScreenStarryAnniversaryMachine.super.initSlotNodes(self)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local symbolNode = util_setSymbolToClipReel(self, iCol, iRow, node.p_symbolType, 0)
                    symbolNode:runAnim("idleframe2", true)
                end
            end
        end
    end
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenStarryAnniversaryMachine:checkPlayBonusDownSound(_node)
    local colIndex = _node.p_cloumnIndex
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        if _node.p_symbolType == self.SYMBOL_BONUS then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_bonus_buling)
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
function CodeGameScreenStarryAnniversaryMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("StarryAnniversarySounds/sound_StarryAnniversary_reelDown.mp3")
        else
            gLobalSoundManager:playSound("StarryAnniversarySounds/sound_StarryAnniversary_quickReelDown.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

--[[
    拉伸镜头效果
]]
function CodeGameScreenStarryAnniversaryMachine:moveRootNodeAction(_node)
    local moveNode = self:findChild("Node_4")
    local parentNode = moveNode:getParent()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_scene_amplify)

    local params = {
        moveNode = moveNode,--要移动节点
        targetNode = _node,--目标位置节点
        parentNode = parentNode,--移动节点的父节点
        time = 0.5,--移动时间
        actionType = 3,
        scale = 1.6,--缩放倍数
    }

    util_moveRootNodeAction(params)
end

--[[
    重置移动节点状态
]]
function CodeGameScreenStarryAnniversaryMachine:resetMoveNodeStatus(_func)
    local moveNode = self:findChild("Node_4")
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_StarryAnniversary_scene_reduce)

    --恢复移动节点状态
    local spawn = cc.Spawn:create({
        cc.MoveTo:create(0.2,cc.p(0,0)),
        cc.ScaleTo:create(0.2,1)
    })
    moveNode:stopAllActions()
    moveNode:runAction(cc.Sequence:create(
        cc.EaseSineInOut:create(spawn),
        cc.CallFunc:create(function()
            if _func then
                _func()
            end
        end)))
end

function CodeGameScreenStarryAnniversaryMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenStarryAnniversaryMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

return CodeGameScreenStarryAnniversaryMachine






