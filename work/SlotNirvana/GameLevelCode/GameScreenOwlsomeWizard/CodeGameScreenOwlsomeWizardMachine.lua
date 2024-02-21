---
-- island li
-- 2019年1月26日
-- CodeGameScreenOwlsomeWizardMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "OwlsomeWizardPublicConfig"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenOwlsomeWizardMachine = class("CodeGameScreenOwlsomeWizardMachine", BaseReelMachine)

CodeGameScreenOwlsomeWizardMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenOwlsomeWizardMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenOwlsomeWizardMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenOwlsomeWizardMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenOwlsomeWizardMachine.SYMBOL_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenOwlsomeWizardMachine.SYMBOL_WILD_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3


-- 自定义动画的标识
CodeGameScreenOwlsomeWizardMachine.UP_WHEEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --转盘升级动作
CodeGameScreenOwlsomeWizardMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --收集bonus动作
CodeGameScreenOwlsomeWizardMachine.DROP_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --free中掉落wild
CodeGameScreenOwlsomeWizardMachine.RESET_WHEEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 --重置轮盘

-- 构造函数
function CodeGameScreenOwlsomeWizardMachine:ctor()
    CodeGameScreenOwlsomeWizardMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("OwlsomeWizardLongRunControl",self) 

    self.m_RESPIN_RUN_TIME = 2

    self.m_collectBonusCount = 0
    self.m_isAddBigWinLightEffect = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenOwlsomeWizardMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("OwlsomeWizardConfig.csv", "LevelOwlsomeWizardConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

function CodeGameScreenOwlsomeWizardMachine:initGameStatusData(gameData)
    CodeGameScreenOwlsomeWizardMachine.super.initGameStatusData(self, gameData)
    
    self.m_betData = gameData.gameConfig.extra.bets
    self.m_initWheelInnerBuff = gameData.gameConfig.extra.wheelInnerBuff
    self.m_initWheelOuterData = gameData.gameConfig.extra.wheelOuterMultiple
    self.wheelOuterMiddleMultiple = gameData.gameConfig.extra.wheelOuterMiddleMultiple
    self.wheelOuterHighMultiple = gameData.gameConfig.extra.wheelOuterHighMultiple
end

--[[
    获取当前bet下的wheel数据
]]
function CodeGameScreenOwlsomeWizardMachine:getCurWheelData()
    local betCoins =  toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0
    if self.m_betData[tostring(betCoins)] then
        return clone(self.m_betData[tostring(betCoins)]) 
    elseif self.m_iBetLevel < 1 then
        return {
            clone(self.m_initWheelOuterData) ,
            clone(self.m_initWheelInnerBuff)
        }
    elseif self.m_iBetLevel < 2 then
        return {
            clone(self.wheelOuterMiddleMultiple) ,
            clone(self.m_initWheelInnerBuff)
        }
    else
        return {
            clone(self.wheelOuterHighMultiple) ,
            clone(self.m_initWheelInnerBuff)
        }
    end
end

---
--设置bonus scatter 层级
function CodeGameScreenOwlsomeWizardMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2 or symbolType == self.SYMBOL_WILD_3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenOwlsomeWizardMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "OwlsomeWizard"  
end

function CodeGameScreenOwlsomeWizardMachine:getBottomUINode()
    return "CodeOwlsomeWizardSrc.OwlsomeWizardBottomNode"
end

function CodeGameScreenOwlsomeWizardMachine:getReelNode()
    return "CodeOwlsomeWizardSrc.OwlsomeWizardReelNode"
end

--小块
function CodeGameScreenOwlsomeWizardMachine:getBaseReelGridNode()
    return "CodeOwlsomeWizardSrc.OwlsomeWizardSlotsNode"
end

--[[
    repinBar
]]
function CodeGameScreenOwlsomeWizardMachine:initRespinBar()
    self.m_respinBar = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardRespinBar",{machine = self})
    self:findChild("Node_respintotalwin"):addChild(self.m_respinBar)
end

--[[
    初始化背景
]]
function CodeGameScreenOwlsomeWizardMachine:initMachineBg()
    local gameBg_base = util_spineCreate("GameScreenOwlsomeWizardBg_base",true,true)
    local gameBg_free = util_spineCreate("OwlsomeWizard_free_bg",true,true)
    local bgNode = self:findChild("bg")
    if bgNode then
        bgNode:addChild(gameBg_base, GAME_LAYER_ORDER.LAYER_ORDER_BG)
        bgNode:addChild(gameBg_free, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    end

    self.m_gameBg_base = gameBg_base
    util_spinePlay(gameBg_base,"idle1",true)

    self.m_gameBg_free = gameBg_free
    util_spinePlay(gameBg_free,"animation",true)
end

--[[
    变更背景
]]
function CodeGameScreenOwlsomeWizardMachine:changeBgType(gameType)
    if gameType == "baseToFree" then
        
        self.m_gameBg_base:setVisible(true)
        self.m_gameBg_free:setVisible(true)

        util_spinePlay(self.m_gameBg_base,"switch1")
        util_spineEndCallFunc(self.m_gameBg_base,"switch1",function()
            self.m_gameBg_base:setVisible(false)
        end)
        util_spinePlay(self.m_gameBg_free,"switch1")
        util_spineEndCallFunc(self.m_gameBg_free,"switch1",function()
            util_spinePlay(self.m_gameBg_free,"animation",true)
        end)
        
    elseif gameType == "freeToBase" then

        self.m_gameBg_base:setVisible(true)
        self.m_gameBg_free:setVisible(true)

        util_spinePlay(self.m_gameBg_base,"switch2")
        util_spineEndCallFunc(self.m_gameBg_base,"switch2",function()
            util_spinePlay(self.m_gameBg_base,"idle1",true)
        end)
        
        util_spinePlay(self.m_gameBg_free,"switch2")
        util_spineEndCallFunc(self.m_gameBg_free,"switch2",function()
            self.m_gameBg_free:setVisible(false)
        end)
        
    else
        self.m_gameBg_base:setVisible(gameType == "base")
        self.m_gameBg_free:setVisible(gameType == "free")
        util_spinePlay(self.m_gameBg_base,"idle1",true)
        util_spinePlay(self.m_gameBg_free,"animation",true)
    end
    
end

--[[
    设置跳过按钮是否显示
]]
function CodeGameScreenOwlsomeWizardMachine:setSkipBtnShow(isShow)
    self.m_skipBtn:setVisible(isShow)
    self.m_bottomUI.m_spinBtn:setVisible(not isShow)
end

function CodeGameScreenOwlsomeWizardMachine:initUI()

    local spinParent = self.m_bottomUI:findChild("free_spin_new")
    if spinParent then
        self.m_skipBtn = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardSkipBtn",{machine = self})
        spinParent:addChild(self.m_skipBtn)
        self.m_skipBtn:setVisible(false)
    end

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode2:setPosition(display.center)
    self.m_effectNode2:setScale(self.m_machineRootScale)

    
    self:initFreeSpinBar() -- FreeSpinbar

    self:initRespinBar()

    self:initJackPotBarView() 

    --转盘
    self.m_wheelView = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardWheelView",{machine = self})
    self:findChild("base_wheel"):addChild(self.m_wheelView)

    --魔法书
    self.m_magicBook = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardSpineMagicBook",{machine = self})
    self.m_effectNode:addChild(self.m_magicBook)
    self.m_magicBook:setPosition(util_convertToNodeSpace(self:findChild("Node_mofashu"),self.m_effectNode))
    -- self:findChild("Node_mofashu"):addChild(self.m_magicBook)

    --free角色
    self.m_role_free = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardSpineRoleFree",{machine = self})
    self.m_effectNode:addChild(self.m_role_free,GAME_LAYER_ORDER.LAYER_ORDER_BG + 2)
    self.m_role_free:setVisible(false)
end

function CodeGameScreenOwlsomeWizardMachine:initSpineUI()
    self.m_wheelBigWinLights = {}
    for index = 1,4 do
        local light = util_spineCreate("OwlsomeWizard_bigwin"..index,true,true)
        self:findChild("node_wheel_big_win"):addChild(light)
        self.m_wheelBigWinLights[index] = light
        light:setVisible(false)
    end
    local bgLight  = util_spineCreate("OwlsomeWizard_bigwin5",true,true)
    self:findChild("node_wheel_big_win_5"):addChild(bgLight)
    self.m_wheelBigWinLights[#self.m_wheelBigWinLights + 1] = bgLight
    bgLight:setVisible(false)
end


function CodeGameScreenOwlsomeWizardMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_enter_game)
    end)
end

function CodeGameScreenOwlsomeWizardMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isInit = true
    self:runCsbAction("idle1")
    CodeGameScreenOwlsomeWizardMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:updateBetLevel(true)

    self:updateWheelView()
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgType("free")
        self.m_role_free:setVisible(true)
        self:showFreeSpinUI()
    else
        self:changeBgType("base")
    end

    self.m_isInit = false

end

--[[
    设置轮盘是否显示
]]
function CodeGameScreenOwlsomeWizardMachine:setReelShow(isShow)
    self:findChild("Node_reel"):setVisible(isShow)
end

--[[
    高低bet
]]
function CodeGameScreenOwlsomeWizardMachine:updateBetLevel(isInit)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0 
    if betCoin >= specialBets[1].p_totalBetValue and betCoin < specialBets[2].p_totalBetValue then
        level = 1
    elseif betCoin >= specialBets[2].p_totalBetValue then
        level = 2
    end
    self.m_iBetLevel = level

    if isInit then
        self.m_jackPotBarView:initLockStatus(level)
    else
        self.m_jackPotBarView:setLockStatus(level)
    end

    
end

--[[
    刷新转盘显示
]]
function CodeGameScreenOwlsomeWizardMachine:updateWheelView()
    local wheelData = self:getCurWheelData()
    self.m_wheelView:updateWheelView(wheelData)
end

function CodeGameScreenOwlsomeWizardMachine:addObservers()
    CodeGameScreenOwlsomeWizardMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --freespin最后一次spin不会播大赢,需单独处理
            local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            if fsLeftCount <= 0 then
                self.m_bIsBigWin = false
            end
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_OwlsomeWizard_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_OwlsomeWizard_winline_free_"..soundIndex]
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
            self:updateWheelView()
            self.m_wheelView:runSwithLightAni()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenOwlsomeWizardMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenOwlsomeWizardMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenOwlsomeWizardMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_OwlsomeWizard_10"
    end
    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_OwlsomeWizard_11"
    end
    
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_OwlsomeWizard_Bonus"
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2 or symbolType == self.SYMBOL_WILD_3 then
        return "Socre_OwlsomeWizard_Wild"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenOwlsomeWizardMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenOwlsomeWizardMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenOwlsomeWizardMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenOwlsomeWizardMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenOwlsomeWizardMachine:beginReel()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()

    self:updateWheelView()

    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local endCount = 0
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = moveSpeed
            reelNode:changeReelMoveSpeed(moveSpeed)
        end
        reelNode:resetReelDatas()
        reelNode:startMove(function()
            endCount = endCount + 1
            if endCount >= #self.m_baseReelNodes then
                local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                local fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                if self:getCurrSpinMode() == FREE_SPIN_MODE and fsLeftCount == fsTotalCount then
                    self.m_role_free:setVisible(true)
                    self.m_role_free:changeSceneAni(function()
                        self:requestSpinReusltData()
                    end)
                else
                    self:requestSpinReusltData()
                end
                
            end
        end)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenOwlsomeWizardMachine:slotOneReelDown(reelCol)    
    CodeGameScreenOwlsomeWizardMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenOwlsomeWizardMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenOwlsomeWizardMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenOwlsomeWizardMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.storedIcons and #selfData.storedIcons > 0 then
        -- 
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
    end

    if selfData and selfData.wheelUps and #selfData.wheelUps > 0 then
        
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.UP_WHEEL_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.UP_WHEEL_EFFECT -- 动画类型
    end

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if self:getCurrSpinMode() == FREE_SPIN_MODE and fsExtraData and fsExtraData.specialWilds and #fsExtraData.specialWilds > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.DROP_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DROP_WILD_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenOwlsomeWizardMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then    --收集bonus
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:delayCallBack(0.5,function()
            self:flyMagicBookAni(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.UP_WHEEL_EFFECT then --升级转盘
        self:upWheelAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.DROP_WILD_EFFECT then --free中掉落wild
        self:dropWildInFree(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.RESET_WHEEL_EFFECT then --respin结束重置轮盘
        
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_role_magic)
        self.m_wheelView.m_role_node:resetWheelAni(function()
            local curWheelData = self:getCurWheelData()
            local startIndex = 1
            local rewardList = {}
            for index = 1,#curWheelData[1] do
                rewardList[#rewardList + 1] = curWheelData[1][index]
            end
            self.m_wheelView:showOuterWheelReward(startIndex,rewardList)

            self:delayCallBack(1,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    
    return true
end

--[[
    获取魔法书飞行终点坐标
]]
function CodeGameScreenOwlsomeWizardMachine:getMagicBookTarPosByCol(colIndex)
    local sp_reel = self:findChild("sp_reel_"..(colIndex - 1))
    local pos = util_convertToNodeSpace(sp_reel,self.m_effectNode)

    pos.x  = pos.x + self.m_SlotNodeW / 2
    pos.y  = pos.y + self.m_SlotNodeH * 3.5
    return pos
end

--[[
    魔法书飞行动作
]]
function CodeGameScreenOwlsomeWizardMachine:flyMagicBookAni(func)
    local reels = self.m_runSpinResultData.p_reels
    --计算开始列
    local startCol = 1
    for iCol = 1,self.m_iReelColumnNum do
        local isHaveBonus = false
        for iRow = 1,self.m_iReelRowNum do
            if self:isFixSymbol(reels[iRow][iCol]) then
                startCol = iCol
                isHaveBonus = true
                break
            end
        end

        if isHaveBonus then
            break
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local storedIcons = selfData.storedIcons
    if storedIcons and #storedIcons > 0 then
        local curWheelData = self:getCurWheelData()
        local startIndex = #curWheelData[1] + 1
        self.m_wheelView:showOuterCollectNoticeAni(startIndex,#storedIcons)
    end

    --当前收集的bonus数量
    self.m_collectBonusCount = 0

    --魔法书飞到开始列上方
    local startPos = cc.p(self.m_magicBook:getPosition())
    local endPos = self:getMagicBookTarPosByCol(startCol)
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_magic_book_fly)
    self.m_magicBook:runSpineAnim("fly_start",false,function()
        self.m_magicBook:runSpineAnim("fly",false,function()
            self.m_magicBook:runSpineAnim("fly_idle",true)
            if storedIcons and #storedIcons > 1 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_lucky)
            end
            
            --收集bonus动作
            self:collectBonusAni(startCol,endPos,function()
                self:flyMagicBookToNextCol(startCol + 1,func)
            end)
        end)
    end)

    local actionList = {
        cc.BezierTo:create(15 / 30,{startPos,cc.p(startPos.x,endPos.y),endPos}),
        cc.CallFunc:create(function()
            
        end)
    }

    local seq = cc.Sequence:create(actionList)

    self.m_magicBook:runAction(seq)
    
end

--[[
    魔法书飞向下一列
]]
function CodeGameScreenOwlsomeWizardMachine:flyMagicBookToNextCol(colIndex,func)
    if colIndex > self.m_iReelColumnNum then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0

        if selfData.upBeforeWheel then
            self.m_betData[tostring(totalBet)] = selfData.upBeforeWheel
        else
            self.m_betData[tostring(totalBet)] = selfData.bets[tostring(totalBet)]
        end
        --魔法书飞回原地
        local actionList = {
            cc.MoveTo:create(0.3,util_convertToNodeSpace(self:findChild("Node_mofashu"),self.m_effectNode)),
            cc.CallFunc:create(function()
                
                self:delayCallBack(1,function()
                    self:updateWheelView()
                    if type(func) == "function" then
                        func()
                    end
                end)
                
            end)
        }
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_magic_book_fly_back)
        self.m_magicBook:runAction(cc.Sequence:create(actionList))
        self.m_magicBook:runIdleAni()
        return
    end
    --检测该列是否有bonus
    local reels = self.m_runSpinResultData.p_reels
    local isHaveBonus = false
    for iRow = 1,self.m_iReelRowNum do
        if self:isFixSymbol(reels[iRow][colIndex]) then
            isHaveBonus = true
            break
        end
    end

    if not isHaveBonus then
        self:flyMagicBookToNextCol(colIndex + 1,func)
        return
    end

    self.m_collectBonusCount = 0

    --魔法书飞到开始列上方
    local startPos = cc.p(self.m_magicBook:getPosition())
    local endPos = self:getMagicBookTarPosByCol(colIndex)
    local actionList = {
        cc.MoveTo:create(15 / 30,endPos),
        cc.CallFunc:create(function()
            
        end)
    }


    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_magic_book_collect)
    self.m_magicBook:runSpineAnim("fly_start",false,function()
        self.m_magicBook:runSpineAnim("fly",false,function()
            self.m_magicBook:runSpineAnim("fly_idle",true)
            --收集bonus动作
            self:collectBonusAni(colIndex,endPos,function()
                self:flyMagicBookToNextCol(colIndex + 1,func)
            end)
        end)

        
    end)
    self.m_magicBook:runAction(cc.Sequence:create(actionList))
end

--[[
    --free中掉落wild
]]
function CodeGameScreenOwlsomeWizardMachine:dropWildInFree(func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if not fsExtraData or not fsExtraData.specialWilds or not fsExtraData.dropWilds then
        if type(func) == "function" then
            func()
        end
        return
    end

    local specialWilds = fsExtraData.specialWilds 
    local dropWilds = fsExtraData.dropWilds

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_wild_change)
    local delayTime = 0
    --特殊wild变普通wild
    for key,data in ipairs(specialWilds) do
        local symbolNode = self:getSymbolByPosIndex(data[1])
        if symbolNode then
            if symbolNode.p_symbolType == self.SYMBOL_WILD_2 then
                symbolNode:runAnim("switch1")
                local aniTime = symbolNode:getAniamDurationByName("switch1")
                delayTime = util_max(delayTime,aniTime)
            elseif symbolNode.p_symbolType == self.SYMBOL_WILD_3 then
                symbolNode:runAnim("switch2")
                local aniTime = symbolNode:getAniamDurationByName("switch2")
                delayTime = util_max(delayTime,aniTime)
            end
        end
    end

    --掉落位置变wild
    self:delayCallBack(0.5,function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_wild)
        for key,data in pairs(dropWilds) do
            local symbolNode = self:getSymbolByPosIndex(data[2])
            if symbolNode then
                self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                symbolNode:runAnim("show")
            end
        end
    end)
   
    

    self:delayCallBack(2.5,function()
        if type(func) == "function" then
            func()
        end
    end)

    
end

--[[
    收集bonus
]]
function CodeGameScreenOwlsomeWizardMachine:collectBonusAni(colIndex,endPos,func)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        if type(func) == "function" then
            func()
        end
        return
    end

    local delayTime = 0
    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
            self.m_collectBonusCount  = self.m_collectBonusCount + 1
            local spine = self:createBonusSpine(symbolNode)
            spine:setVisible(false)
            local actionList = {
                cc.DelayTime:create(delayTime),
                cc.CallFunc:create(function()
                    
                    spine:setVisible(true)
                    util_spinePlay(spine,"shouji")
                    util_spineEndCallFunc(spine,"shouji",function()
                        spine:setVisible(false)
                        self:delayCallBack(0.1,function()
                            spine:removeFromParent()
                        end)
                    end)

                    --将滚轮上的信号块变为普通信号
                    self:changeBonusToNormalSymbol(symbolNode)
                end),
                cc.EaseExponentialIn:create(cc.MoveTo:create(20 / 30,endPos)),
                cc.CallFunc:create(function()
                    self.m_magicBook:runSpineAnim("shouji",false,function()
                        self.m_magicBook:runSpineAnim("fly_idle",true)
                    end)
                end)
            }

            spine:runAction(cc.Sequence:create(actionList))
        end
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_magic_book_collect)
    

    self:delayCallBack(delayTime + 20 / 30 + 15 / 30,function()
        --刷新外圈对应的奖励
        self:showOuterReward()

        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示外圈奖励
]]
function CodeGameScreenOwlsomeWizardMachine:showOuterReward()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    

    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0
    local curWheelData = self:getCurWheelData()
    
    local resultWheelData = selfData.bets[tostring(totalBet)]
    if selfData.upBeforeWheel then
        resultWheelData = selfData.upBeforeWheel
    end

    local startIndex = #curWheelData[1] + 1
    local rewardList = {}
    for index = 1,self.m_collectBonusCount do
        rewardList[#rewardList + 1] = resultWheelData[1][startIndex + index - 1]
        curWheelData[1][startIndex + index - 1] = resultWheelData[1][startIndex + index - 1]
        self.m_betData[tostring(totalBet)] = curWheelData
    end
    self.m_wheelView:showOuterWheelReward(startIndex,rewardList)
end

--[[
    将bonus信号变为普通信号
]]
function CodeGameScreenOwlsomeWizardMachine:changeBonusToNormalSymbol(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --将bonus信号变为普通信号
    local storedIcons = selfData.storedIcons
    if storedIcons and #storedIcons > 0 then
        for index = 1,#storedIcons do
            local iconData = storedIcons[index]
            if iconData[1] == posIndex then
                local tarSymbolType = iconData[5]
                if not tolua.isnull(symbolNode) then
                    self:changeSymbolType(symbolNode,tarSymbolType)
                end
                return
            end
        end
    end
end

--[[
    创建一个bonus spine
]]
function CodeGameScreenOwlsomeWizardMachine:createBonusSpine(symbolNode)
    local spine = util_spineCreate("Socre_OwlsomeWizard_Bonus",true,true)
    self.m_effectNode:addChild(spine)
    local pos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
    spine:setPosition(pos)

    local score,multi = self:getReSpinSymbolScore(self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)) --获取分数（网络数据）

    local labelCsb = util_createAnimation("Socre_OwlsomeWizard_Bonus_zi.csb")
    util_spinePushBindNode(spine,"shuzi",labelCsb)

    if type(multi) ~= "number" then
        labelCsb:findChild("m_lb_coins"):setVisible(false)
        labelCsb:findChild("m_lb_coins_high"):setVisible(false)
        labelCsb:findChild("grand"):setVisible(string.lower(multi) == "grand")
        labelCsb:findChild("major"):setVisible(string.lower(multi) == "major")
    else
        labelCsb:findChild("m_lb_coins"):setVisible(true)
        labelCsb:findChild("grand"):setVisible(false)
        labelCsb:findChild("major"):setVisible(false)
        local m_lb_coins = labelCsb:findChild("m_lb_coins")
        m_lb_coins:setString(util_formatCoins(score,3))

        local m_lb_coins_high = labelCsb:findChild("m_lb_coins_high")
        m_lb_coins_high:setString(util_formatCoins(score,3))

        m_lb_coins:setVisible(multi <= 5)
        m_lb_coins_high:setVisible(multi > 5)

        local info1 = {label = m_lb_coins, sx = 1, sy = 1}
        self:updateLabelSize(info1, 120)

        local info2 = {label = m_lb_coins, sx = 1, sy = 1}
        self:updateLabelSize(info2, 120)
    end

    return spine
end



--[[
    升级转盘动画
]]
function CodeGameScreenOwlsomeWizardMachine:upWheelAni(func)
    

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        if type(func) == "function" then
            func()
        end
        return
    end

    self:removeSoundHandler()

    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0

    self.m_betData[tostring(totalBet)] = selfData.bets[tostring(totalBet)]

    self.m_wheelView:randomLevelUpAni(selfData.wheelUps,function()
        -- self:updateWheelView()

        self:reelsDownDelaySetMusicBGVolume()

        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenOwlsomeWizardMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenOwlsomeWizardMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenOwlsomeWizardMachine:playScatterTipMusicEffect()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_scatter_trigger)
end

-- 不用系统音效
function CodeGameScreenOwlsomeWizardMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenOwlsomeWizardMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenOwlsomeWizardMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return true
    end
    
    return false
end

--[[
    小块刷新
]]
function CodeGameScreenOwlsomeWizardMachine:updateReelGridNode(symbolNode)
    local symbolType = symbolNode.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(symbolNode)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        symbolNode:runAnim("idleframe")
    elseif symbolType == self.SYMBOL_WILD_2 then
        symbolNode:runAnim("idleframe2")
    elseif symbolType == self.SYMBOL_WILD_3 then
        symbolNode:runAnim("idleframe3")
    end
end

-- 给respin小块进行赋值
function CodeGameScreenOwlsomeWizardMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score,multi = 0,1
    if symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score,multi = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    else
        score,multi = self:randomDownRespinSymbolScore(symbolNode.p_symbolType,iCol,iRow)
    end

    local labelCsb = self:getLblCsbOnSymbol(symbolNode,"Socre_OwlsomeWizard_Bonus_zi.csb","shuzi")
    if type(multi) ~= "number" then
        labelCsb:findChild("m_lb_coins"):setVisible(false)
        labelCsb:findChild("m_lb_coins_high"):setVisible(false)
        labelCsb:findChild("grand"):setVisible(string.lower(multi) == "grand")
        labelCsb:findChild("major"):setVisible(string.lower(multi) == "major")
    else
        labelCsb:findChild("grand"):setVisible(false)
        labelCsb:findChild("major"):setVisible(false)
        local m_lb_coins = labelCsb:findChild("m_lb_coins")
        m_lb_coins:setString(util_formatCoins(score,3))

        local m_lb_coins_high = labelCsb:findChild("m_lb_coins_high")
        m_lb_coins_high:setString(util_formatCoins(score,3))

        m_lb_coins:setVisible(multi <= 5)
        m_lb_coins_high:setVisible(multi > 5)

        local info1 = {label = m_lb_coins, sx = 1, sy = 1}
        self:updateLabelSize(info1, 120)

        local info2 = {label = m_lb_coins, sx = 1, sy = 1}
        self:updateLabelSize(info2, 120)
    end

    if self.m_isInit then
        symbolNode:runAnim("idleframe1",true)
    elseif self:getGameSpinStage( ) > IDLE and self:getGameSpinStage() ~= QUICK_RUN then
        symbolNode:runAnim("idleframe2",true)
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenOwlsomeWizardMachine:getReSpinSymbolScore(id)
    local lineBet = globalData.slotRunData:getCurTotalBet() or 0
    local multi = 1
    local score = 0

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return multi * lineBet,multi
    end
    
    local storedIcons = selfData.storedIcons

    if storedIcons then
        for i=1, #storedIcons do
            local values = storedIcons[i]
            if values[1] == id then
                multi = values[2]
                score = values[3]
                break
            end
        end 
    end

    if score == 0 then
        score = multi * lineBet
    end

    return score,multi
end

--[[
    随机bonus分数
]]
function CodeGameScreenOwlsomeWizardMachine:randomDownRespinSymbolScore(symbolType,colIndex,rowIndex)
    local score = 0
    
    local lineBet = globalData.slotRunData:getCurTotalBet() or 0
    local multi = self.m_configData:getFixSymbolPro(colIndex,rowIndex,self.m_isInit)
    if type(multi) == "number" then
        score = multi * lineBet
    end
    

    return score,multi
end

-----------------------转盘相关----------------------------
---
-- 触发respin 玩法
--
function CodeGameScreenOwlsomeWizardMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
                --将滚轮上的信号块变为普通信号
                self:changeSymbolType(symbolNode,math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1))
            end
        end
    end

    
    self:delayCallBack(0.5,function()
        self:showRespinView(effectData)
    end)
    return true
end

function CodeGameScreenOwlsomeWizardMachine:showRespinView(effectData)
    self:clearCurMusicBg()

    self.m_specialReels = true
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    
    self.m_wheelView:collectFullAni(function()
        self:showRespinStart(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_change_scene_to_wheel)
            self.m_wheelView.m_role_node:runChangeBgAni(function()
                self:changeReSpinBgMusic()
                self:changeSceneToWheel(function()
                    --构造盘面数据
                    self:triggerReSpinCallFun()
                end)
            end)
            
        end)
        
    end)
    
end

--[[
    转场(轮盘)
]]
function CodeGameScreenOwlsomeWizardMachine:changeSceneToWheel(func)
    
    --切换背景
    self:changeBgType("baseToFree")
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    local rsWinCoins = self.m_runSpinResultData.p_resWinCoins
    self.m_respinBar:updateTotalWin(rsWinCoins,true)
    self.m_respinBar:runShowAni()
    --魔法书飞出轮盘
    self.m_magicBook:runSpineAnim("fly_start",false,function()
        self.m_magicBook:setVisible(false)
        self.m_magicBook:runIdleAni()
    end)
    local posY = self.m_magicBook:getPositionY()
    self.m_magicBook:runAction(cc.MoveTo:create(15 / 30,cc.p(display.width / 2 + 120,posY)))
    self:runCsbAction("guochang",false,function()
        self:setReelShow(false)
        self.m_wheelView:showPointerAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    转场(轮盘)
]]
function CodeGameScreenOwlsomeWizardMachine:changeSceneToBaseFromWheel(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_change_scene_to_base_from_wheel)
    --切换背景
    self:changeBgType("freeToBase")
    self:setReelShow(true)
    self.m_respinBar:runOverAni()

    --魔法书飞回轮盘
    self.m_magicBook:setVisible(true)
    self.m_magicBook:runSpineAnim("fly_start",false,function()
        self.m_magicBook:runIdleAni()
    end)
    local pos = util_convertToNodeSpace(self:findChild("Node_mofashu"),self.m_effectNode)
    self.m_magicBook:setPosition(cc.p(display.width / 2 + 120,pos.y))
    self.m_magicBook:runAction(cc.MoveTo:create(15 / 30,pos))

    self:runCsbAction("guochang2",false,function()
        
        

        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    respin开始界面
]]
function CodeGameScreenOwlsomeWizardMachine:showRespinStart(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_magic_wheel_show)
    --获取父节点
    local parentNode = self:findChild("Node_reel")

    local spineLight = util_spineCreate("OwlsomeWizard_ReSpinStart",true,true)
    parentNode:addChild(spineLight,50)
    util_spinePlay(spineLight,"show")
    util_spineEndCallFunc(spineLight,"show",function()
    spineLight:setVisible(false)
    --延时0.1s移除spine,直接移除会导致闪退
    self:delayCallBack(0.1,function()
        spineLight:removeFromParent()
    end)

    if type(func) == "function" then
        func()
    end
        
    end)
end

--触发respin
function CodeGameScreenOwlsomeWizardMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:setCurrSpinMode(RESPIN_MODE)

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    
   

    self:delayCallBack(1,function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})

        self:runNextReSpinReel()
    end)
    -- 
end

--ReSpin开始改变UI状态
function CodeGameScreenOwlsomeWizardMachine:changeReSpinStartUI(respinCount)
    
    
    self:changeReSpinUpdateUI(respinCount,true)

    
    
end

--ReSpin结算改变UI状态
function CodeGameScreenOwlsomeWizardMachine:changeReSpinOverUI()
    self:runCsbAction("idle1")
    self.m_magicBook:setPosition(util_convertToNodeSpace(self:findChild("Node_mofashu"),self.m_effectNode))
    self.m_magicBook:setVisible(true)
end

--[[
    刷新当前respin剩余次数
]]
function CodeGameScreenOwlsomeWizardMachine:changeReSpinUpdateUI(curCount,isInit)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinBar:updateRespinCount(totalCount - curCount,totalCount,isInit)
end

function CodeGameScreenOwlsomeWizardMachine:MachineRule_respinTouchSpinBntCallBack()
    if self.m_wheelView.m_wheelDownCount < 2 then
        return
    end
    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end
    self:startReSpinRun()
end

--开始下次ReSpin
function CodeGameScreenOwlsomeWizardMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            self:startReSpinRun()
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

--开始滚动
function CodeGameScreenOwlsomeWizardMachine:startReSpinRun()
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()
    
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_wheelView:startWheel()
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenOwlsomeWizardMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end

--接收到数据开始停止滚动
function CodeGameScreenOwlsomeWizardMachine:stopRespinRun()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    self.m_wheelView:setWheelEndIndex(rsExtraData.outerIndex,rsExtraData.innerIndex)
end

---判断结算
function CodeGameScreenOwlsomeWizardMachine:reSpinReelDown()
    self:setGameSpinStage(STOP_RUN)
    self:updateQuestUI()

    self.m_serverWinCoins = self.m_runSpinResultData.p_resWinCoins

    --获得转盘奖励
    self:getWheelReward(function()
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    
            --quest
            self:updateQuestBonusRespinEffectData()
    
            --结束
            self:reSpinEndAction()
    
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    
            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false

            --重置轮盘事件
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LEGENDARY + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RESET_WHEEL_EFFECT -- 动画类型
    
            return
        end

        --继续
        self:runNextReSpinReel()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end)
end

--[[
    获得转盘奖励
]]
function CodeGameScreenOwlsomeWizardMachine:getWheelReward(func)

    local curBetData = self:getCurWheelData()

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    local innerIndex = rsExtraData.innerIndex
    local innerReward = curBetData[2][innerIndex + 1]

    local outerIndex = rsExtraData.outerIndex
    local outerReward = curBetData[1][outerIndex + 1]


    local innerBuff = rsExtraData.innerBuff
    local outerMultiple = rsExtraData.outerMultiple

    self.m_wheelView:showWheelResult(outerIndex,innerIndex,innerReward,function()
        
    end)

    --刷新赢钱
    local function updateTotalWin()
        self:checkShowWheelBigWin()
        --刷新totalwin
        local rsWinCoins = self.m_runSpinResultData.p_resWinCoins

        

        performWithDelay(self.m_skipBtn,function()
            self:setSkipBtnShow(true)
        end,2)
        
        self.m_respinBar:updateTotalWin(rsWinCoins,false,function()
            self.m_skipBtn:stopAllActions()
            self:setSkipBtnShow(false)
            if self.m_rsBigWinSoundID then
                gLobalSoundManager:stopAudio(self.m_rsBigWinSoundID)
                self.m_rsBigWinSoundID = nil
            end
            self.m_wheelView:resetWheelSelectStatus()
            self:hideWheelBigWinLight()

            

            --检测内圈是否转到了升级
            if innerReward == 200 then
                self:showLevelUpInWheel(function()
                    --刷新轮盘
                    self:updateWheelView()
                    if type(func) == "function" then
                        func()
                    end
                end)
            else
                --刷新轮盘
                self:delayCallBack(0.5,function()
                    self:updateWheelView()
                    if type(func) == "function" then
                        func()
                    end
                end)
                
            end

            
        end)
    end

    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    if type(outerReward) == "number" then -- 外圈转到普通奖励
        updateTotalWin()
    else    --转到jackpot
        self.m_wheelView.m_role_node:runJackpotAni(function()
            util_shakeNode(self:findChild("root"),5,10,2)
        end,function()
            self:showJackpotView(self.m_runSpinResultData.p_winAmount,outerReward,function()
                updateTotalWin()
            end)
        end)
    end
end

--[[
    respin跳过涨钱
]]
function CodeGameScreenOwlsomeWizardMachine:skipJumpCoins()
    self:setSkipBtnShow(false)
    self.m_respinBar:jumpEndFunc()
end

--[[
    转盘玩法中转到升级
]]
function CodeGameScreenOwlsomeWizardMachine:showLevelUpInWheel(func)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    local innerBuff = rsExtraData.innerBuff
    local outerMultiple = rsExtraData.outerMultiple
    local outerUpMultiple = rsExtraData.outerUpMultiple
    local outerIndex = rsExtraData.outerIndex

    if outerUpMultiple then
        local upDataList = {}
        for index = 1,#outerUpMultiple do
            if outerMultiple[index] ~= outerUpMultiple[index] then
                upDataList[#upDataList + 1] = {1,index - 1,outerUpMultiple[index],outerIndex}
            end
        end
        outerMultiple = outerUpMultiple

        self.m_wheelView:randomLevelUpAni(upDataList,function()
    
            if type(func) == "function" then
                func()
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end

    --刷新本地存储数据
    local betCoins = toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0
    self.m_betData[tostring(betCoins)] = {
        outerMultiple,
        innerBuff
    }
end

--[[
    检测转盘奖励是否大于10倍
]]
function CodeGameScreenOwlsomeWizardMachine:checkShowWheelBigWin()
    --计算倍数
    local winAmount = self.m_runSpinResultData.p_winAmount
    local totalBet = globalData.slotRunData:getCurTotalBet()
    if winAmount / totalBet < 10 then
        return
    end

    if winAmount / totalBet >= 20 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_terrific)
    end

    self.m_rsBigWinSoundID = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_side_coins,true)
    for index = 1,#self.m_wheelBigWinLights do
        local light = self.m_wheelBigWinLights[index] 
        light:setVisible(true)
        util_spinePlay(light,"actionframe_bigwin",true)
    end

    self.m_wheelView.m_role_node:runBigWinAni()
    
end

--[[
    隐藏转盘大赢光效
]]
function CodeGameScreenOwlsomeWizardMachine:hideWheelBigWinLight()
    for index = 1,#self.m_wheelBigWinLights do
        local light = self.m_wheelBigWinLights[index] 
        light:setVisible(false)
    end
end

function CodeGameScreenOwlsomeWizardMachine:respinOver()
    self.m_respinBar:runWinCoinsAni(function()
        self:delayCallBack(0.5,function()
            self:showRespinOverView()
        end)
    end)
end

function CodeGameScreenOwlsomeWizardMachine:showRespinOverView(effectData)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_respin_over)

    self:clearCurMusicBg()
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:changeSceneToBaseFromWheel(function()
            self:triggerReSpinOverCallFun()
        end)
    end)

    self:delayCallBack(20 / 60,function()
        local betCoins = toLongNumber(globalData.slotRunData:getCurTotalBet()) or 0
        --重置转盘数据
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.bets then
            self.m_betData[tostring(betCoins)] = selfData.bets[tostring(betCoins)]
        end
        local wheelData = self:getCurWheelData()
        wheelData[1] = {}
        self.m_wheelView:updateWheelView(wheelData)

        self.m_wheelView:hidePointerAni()
        self.m_wheelView:resetWheel()
    end)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_hide_respin_over)
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},595)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local light = util_createAnimation("OwlsomeWizard_tanban_guang.csb")
    view:findChild("guang"):addChild(light)    
    light:runCsbAction("idle",true)

    local spine1 = util_spineCreate("Socre_OwlsomeWizard_Wild",true,true)
    view:findChild("juese1"):addChild(spine1)  
    util_spinePlay(spine1,"idleframe_tanban1",true)  

    local spine2 = util_spineCreate("Socre_OwlsomeWizard_Wild",true,true)
    view:findChild("juese2"):addChild(spine2)  
    util_spinePlay(spine2,"idleframe_tanban2",true)  

    local spine3 = util_spineCreate("OwlsomeWizard_free_juese",true,true)
    view:findChild("juese3"):addChild(spine3)  
    util_spinePlay(spine3,"idleframe_tanban3",true)  
end

function CodeGameScreenOwlsomeWizardMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        local params = {self:getLastWinCoin(), false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    else
        coins = self.m_serverWinCoins or 0
        globalData.slotRunData.lastWinCoin = 0
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
    self:resetMusicBg(true)
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

-----------------------------------------------------------

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenOwlsomeWizardMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenOwlsomeWizardMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    
    self.m_baseFreeSpinBar:showAni()
end

function CodeGameScreenOwlsomeWizardMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenOwlsomeWizardMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            print("猫头鹰没有FreeMore")
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self:changeSceneToFree(function()
                    self:showFreeSpinUI()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()   
                end,function()
                    
                end)
                    
            end)

            local ratio = display.height / display.width
            if ratio < 1024 / 768 then  
                view:findChild("root"):setScale(0.9)
            end
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end



--[[
    隐藏free相关UI
]]
function CodeGameScreenOwlsomeWizardMachine:hideFreeSpinUI()
    self:hideFreeSpinBar()

    --切换背景
    self:changeBgType("freeToBase")

    self.m_wheelView:setVisible(true)

    self.m_role_free:setVisible(false)

    self.m_magicBook:setVisible(true)
end

--[[
    显示free相关UI
]]
function CodeGameScreenOwlsomeWizardMachine:showFreeSpinUI()
    self:showFreeSpinBar()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

    self.m_magicBook:setVisible(false)

    --切换背景
    self:changeBgType("free")

    self.m_wheelView:setVisible(false)
end

--[[
    触发free
]]
function CodeGameScreenOwlsomeWizardMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0

     -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

--[[
    过场动画
]]
function CodeGameScreenOwlsomeWizardMachine:changeSceneToFree(keyFunc,endFunc)
    local spine = util_spineCreate("OwlsomeWizard_juese",true,true)
    self.m_effectNode2:addChild(spine)
    local layer =  util_newMaskLayer(true)
    layer:setOpacity(0)
    spine:addChild(layer)
    -- spine:setPosition(display.center)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_change_scene_to_free)

    util_spinePlay(spine,"actionframe_guochang")
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        spine:setVisible(false)
        layer:removeFromParent()
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(70 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
end

function CodeGameScreenOwlsomeWizardMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local autoType
    if isAuto then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_free_start)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, autoType)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_hide_free_start)
    end)

    local spine = util_spineCreate("OwlsomeWizard_FreeSpinStart_qiu",true,true)
    view:findChild("Node_qiu"):addChild(spine)

    util_spinePlay(spine,"start")
    util_spineEndCallFunc(spine,"start",function()
        util_spinePlay(spine,"idle",true)
    end)

    return view

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenOwlsomeWizardMachine:showFreeSpinOverView(effectData)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_free_over)

    if globalData.slotRunData.lastWinCoin <= 0 then
        self:clearCurMusicBg()
        local ownerlist = {}
        local view = self:showDialog("NoWin", ownerlist, function()
            self:triggerFreeSpinOverCallFun()
        end)

        view:setBtnClickFunc(function(  )
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_btn_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_hide_free_over)
            self:hideFreeSpinUI()
        end)

        return 
    end

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()

            self:triggerFreeSpinOverCallFun()
            
        end
    )

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_hide_free_over)
        self:hideFreeSpinUI()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},595)    
    view:findChild("root"):setScale(self.m_machineRootScale)

    local light = util_createAnimation("OwlsomeWizard_tanban_guang.csb")
    view:findChild("guang"):addChild(light)    
    light:runCsbAction("idle",true)

    local spine1 = util_spineCreate("Socre_OwlsomeWizard_Wild",true,true)
    view:findChild("juese1"):addChild(spine1)  
    util_spinePlay(spine1,"idleframe_tanban1",true)  

    local spine2 = util_spineCreate("Socre_OwlsomeWizard_Wild",true,true)
    view:findChild("juese2"):addChild(spine2)  
    util_spinePlay(spine2,"idleframe_tanban2",true)  

    local spine3 = util_spineCreate("OwlsomeWizard_free_juese",true,true)
    view:findChild("juese3"):addChild(spine3)  
    util_spinePlay(spine3,"idleframe_tanban3",true)  
end

function CodeGameScreenOwlsomeWizardMachine:showEffect_FreeSpin(effectData)
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

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    local waitTime = 0

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
                --将滚轮上的信号块变为普通信号
                self:changeSymbolType(symbolNode,math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1))
            end
        end
    end
    
    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()
    for index = 1,self.m_iReelRowNum * self.m_iReelColumnNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local parent = symbolNode:getParent()
            if parent ~= self.m_clipParent then
                self:changeSymbolToClipParent(symbolNode)
            end
            symbolNode:runAnim("actionframe")
            local duration = symbolNode:getAniamDurationByName("actionframe")
            waitTime = util_max(waitTime,duration)
        end
    end

    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenOwlsomeWizardMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardJackPotBarView",{machine = self})
    self:findChild("root"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenOwlsomeWizardMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeOwlsomeWizardSrc.OwlsomeWizardJackpotWinView",{
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

--[[
    检测是否需要播落地
]]
function CodeGameScreenOwlsomeWizardMachine:isPlayTipAnima(colIndex, rowIndex, node)
    if colIndex < 4 then
        return true
    end
    local reels = self.m_runSpinResultData.p_reels
    local symbolType = node.p_symbolType
    local symbolCount = 0
    --获取小块数量
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1,colIndex - 1 do
            if symbolType == reels[iRow][iCol] then
                symbolCount  = symbolCount + 1
            end
        end
    end

    if symbolCount >= 2 then
        return true
    elseif colIndex == 4 and symbolCount >= 1 then
        return true
    end
    return false
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenOwlsomeWizardMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif self:isFixSymbol(_slotNode.p_symbolType) then
                return true
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenOwlsomeWizardMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_bonus_down)
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenOwlsomeWizardMachine:playScatterDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_scatter_down)
end

--[[
    落地动画回调
]]
function CodeGameScreenOwlsomeWizardMachine:symbolBulingEndCallBack(_slotNode)
    if not tolua.isnull(_slotNode) and _slotNode.p_symbolType and _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
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
    elseif not tolua.isnull(_slotNode) then
        _slotNode:runAnim("idleframe1",true)

    end
    
    return false    
end

function CodeGameScreenOwlsomeWizardMachine:setReelRunInfo()
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态

    if self.b_gameTipFlag then
        return
    end
    for col=1,self.m_iReelColumnNum do
        local reelRunData = self.m_reelRunInfo[col]
        local runLen = reelRunData:getReelRunLen()

        local reelNode = self.m_baseReelNodes[col]
        reelNode:setRunLen(runLen)
    end
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenOwlsomeWizardMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenOwlsomeWizardMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenOwlsomeWizardMachine:isPlayExpect(reelCol)
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

function CodeGameScreenOwlsomeWizardMachine:getFeatureGameTipChance()
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 then
        -- 出现预告动画概率默认为30%
        local isNotice = (math.random(1, 100) <= 40) 
        return isNotice
        
    end
    
    return false
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenOwlsomeWizardMachine:showFeatureGameTip(_func)
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
function CodeGameScreenOwlsomeWizardMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_notice_win)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("Node_reel")

    self.b_gameTipFlag = true
    --创建对应格式的spine
    local spineAni = util_spineCreate("OwlsomeWizard_juese",true,true)
    parentNode:addChild(spineAni,100)   

    self.m_wheelView.m_role_node:runNoticeAni()

    util_spinePlay(spineAni,"actionframe_yugao")
    util_spineEndCallFunc(spineAni,"actionframe_yugao",function()
        spineAni:setVisible(false)
        --延时0.1s移除spine,直接移除会导致闪退
        self:delayCallBack(0.1,function()
            spineAni:removeFromParent()
        end)
    end)

    local spineLight = util_spineCreate("OwlsomeWizard_ReSpinStart",true,true)
    parentNode:addChild(spineLight,50)
    util_spinePlay(spineLight,"actionframe_yugao")
    util_spineEndCallFunc(spineLight,"actionframe_yugao",function()
        spineLight:setVisible(false)
        --延时0.1s移除spine,直接移除会导致闪退
        self:delayCallBack(0.1,function()
            spineLight:removeFromParent()
        end)
        
    end)

    aniTime = spineAni:getAnimationDurationTime("actionframe_yugao")

    self:delayCallBack(100 / 30,function()
        --猫头鹰回到转盘上
        self.m_wheelView.m_role_node:runNoticeOverAni()
    end)

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    --预告中奖时间比滚动时间短,直接返回即可
    if aniTime <= delayTime then
        if type(func) == "function" then
            func()
        end
    else
        self:delayCallBack(aniTime - delayTime,function()
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenOwlsomeWizardMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_big_win_light)
    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_role_free:runBigWinAni()
    else
        self.m_wheelView.m_role_node:runBigWinAni()
    end
    

    local bigWinLight = util_spineCreate("OwlsomeWizard_bigwin",true,true)
    self:findChild("Node_bigwin"):addChild(bigWinLight)
    util_spinePlay(bigWinLight,"actionframe_bigwin")
    util_spineEndCallFunc(bigWinLight,"actionframe_bigwin",function()
        bigWinLight:setVisible(false)
        self:delayCallBack(0.1,function()
            bigWinLight:removeFromParent()
        end)

        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = bigWinLight:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(rootNode,5,10,aniTime)
end

function CodeGameScreenOwlsomeWizardMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio < 920 / 768 then  --920以下
        mainScale = 0.59
        mainPosY  = mainPosY + 30
        self:findChild("bg"):setScale(1.2)

    elseif ratio >=  920 / 768 and ratio < 1024 / 768 then --920
        mainScale = 0.59
        mainPosY  = mainPosY + 30
        self:findChild("bg"):setScale(1.2)
    elseif ratio >=  1024 / 768 and ratio < 1152 / 768 then --920
        mainScale = 0.675
        mainPosY  = mainPosY + 30
        self:findChild("bg"):setScale(1.2)

    elseif ratio >= 1152 / 768 and ratio < 1228 / 768 then --1152
        mainScale = 0.78
        mainPosY  = mainPosY + 17
    elseif ratio >= 1228 / 768 and ratio < 1368 / 768 then --1228
        mainScale = 0.87
        mainPosY  = mainPosY + 20
    else --1370以上
        mainScale = 0.99
        mainPosY  = mainPosY + 12
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenOwlsomeWizardMachine:getShowLineWaitTime()
    local time = CodeGameScreenOwlsomeWizardMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

return CodeGameScreenOwlsomeWizardMachine






