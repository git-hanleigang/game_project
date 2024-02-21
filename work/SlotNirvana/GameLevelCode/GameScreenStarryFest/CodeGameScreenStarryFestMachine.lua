---
-- island li
-- 2019年1月26日
-- CodeGameScreenStarryFestMachine.lua
-- 
-- 玩法：
--[[
    固定图标玩法：
        1.出现bonus1（94信号）会出现固定框；
        2.当bonus2（95信号）图标落在有锁定框的位置时，会获得该奖励，若锁定框带有乘倍，则会在乘倍生效后获得该奖励
    base:
        1.3个scatter触发free
        2.bonus1图标首次滚出，该位置会出现一倍锁定框，锁定框固定3次spin
        3.bonus1图标落在一倍锁定框位置，变为二倍锁定框，锁定框固定3次spin
        4.bonus1图标落在二倍锁定框位置，变为三倍锁定框，锁定框固定3次spin
        5.bonus1图标落在三倍锁定框位置，变为五倍锁定框，锁定框固定3次spin
        6.bonus1图标落在五倍锁定框位置，锁定框倍数不变，锁定框固定次数重置为3次spin
    收集玩法：
        1.触发free收集一次；收集满（10次）触发superfree
    free：
        1.free下不会出现scatter，不会有freeMore
        2.FG中，已滚出的锁定框会一直固定到FG结束，锁定框乘倍累计规则同Base一致
        3.SuperFG中，当滚出bonus1图标时，会向上下左右四个方向额外扩展出一个锁定框
    superFree：
        1.进入SuperFG，获得15次spin次数
        2.大转盘可以获得free1，free2，free3，Major，Mega，Grand；6中奖励；jackpot直接获取，free则进free玩法
    特殊spin玩法（jackpot catcher spin feature）：
        1.触发一次只会出现bonus1、bonus2图标的特殊spin，该玩法在Base及FG下均会触发（假滚也会变成相应的类型：①全bonus1；②全bonus1和bonus2）
        2.在Base下触发jackpot catcher spin，则当次spin有可能只会出现bonus1图
        3.有可能触发强化版的特殊spin——Ultra jackpot catcher spin
        4.当触发Ultra jackpot catcher spin时，会出现更多的大钱bonus2及带有高级jackpot的bonus2
]]
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "StarryFestPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenStarryFestMachine = class("CodeGameScreenStarryFestMachine", BaseNewReelMachine)

CodeGameScreenStarryFestMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_BONUS_1 = 94
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_BONUS_2 = 95
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_MINI = 101
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_MINOR = 102
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_MAJOR = 103
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_MEGA = 104
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_MAXI = 105
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_SUPER = 106
CodeGameScreenStarryFestMachine.SYMBOL_SCORE_JACKPOT_GRAND = 107

-- 自定义动画的标识
CodeGameScreenStarryFestMachine.EFFECT_BONUS_SUPER_FREE_SIDE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2  --bonus玩法；super下蔓延；收集完再蔓延
CodeGameScreenStarryFestMachine.EFFECT_BONUS_REWARD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3  --bonus玩法；奖励
CodeGameScreenStarryFestMachine.EFFECT_BONUS_BASE_FIXED_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4  --bonus玩法；固定base
CodeGameScreenStarryFestMachine.EFFECT_BONUS_FREE_FIXED_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5  --bonus玩法；固定free
CodeGameScreenStarryFestMachine.EFFECT_BONUS_SUPER_FREE_FIXED_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6  --bonus玩法；固定superFree
CodeGameScreenStarryFestMachine.EFFECT_BONUS_DARK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 7  --bonus玩法；bonus2先压暗

-- 构造函数
function CodeGameScreenStarryFestMachine:ctor()
    CodeGameScreenStarryFestMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeStarryFestSrc.StarryFestSymbolExpect", self)

    -- 引入控制插件
    self.m_longRunControl = util_createView("CodeStarryFestSrc/StarryFestLongRunControl",self)

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    -- 大赢光效
    self.m_isAddBigWinLightEffect = true
    -- 是否super
    self.m_isSuperFree = false
    -- 当前收集进度
    self.m_collectCount = 0
    -- spin状态下；当前spin需要亮的node
    self.m_spinNodeStateTbl = {}
    -- spin时；需要消失的圈
    self.m_spinTimesOverNodeTbl = {}
    -- bonus2奖励位置
    self.m_rewardBonusData = {}
    -- 顶层假的字体存储
    self.m_falseScoreNodeTbl = {}
    -- 顶层下次spin-bonus2动画类型
    self.m_falseBonusAniTypeTbl = {}

    -- 触发特殊spin类型
    self.M_ENUM_SPIN_TYPE = {
        BASE = 0,   -- 正常spin类型
        SPECIAL_SPIN_LOW_1 = 1,  -- 低等级类型1（假滚全是bonus1）
        SPECIAL_SPIN_LOW_2 = 2,  -- 低等级类型2（假滚全是bonus1和bonus2）
        SPECIAL_SPIN_HEIGHT = 3,    -- 高等级类型（假滚全是bonus1和bonus2）
    }
    self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.BASE

    --init
    self:initGame()
end

function CodeGameScreenStarryFestMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("StarryFestConfig.csv", "StarryFestConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenStarryFestMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "StarryFest"  
end

function CodeGameScreenStarryFestMachine:getBottomUINode()
    return "CodeStarryFestSrc.StarryFestBottomNode"
end

function CodeGameScreenStarryFestMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0
    if next(self.m_specialBets) then
        if betCoin >= self.m_specialBets[2].p_totalBetValue then
            level = 2
        elseif betCoin >= self.m_specialBets[1].p_totalBetValue and betCoin < self.m_specialBets[2].p_totalBetValue then
            level = 1
        elseif betCoin < self.m_specialBets[1].p_totalBetValue then
            level = 0
        else
            print("错误betLevel")
        end
    end
    self.m_iBetLevel = level
end

function CodeGameScreenStarryFestMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Node_base_reel")
    self.m_reelBg[2] = self:findChild("Node_FG_reel")

    -- 背景
    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("Base")
    self.m_bgType[2] = self.m_gameBg:findChild("FG")
    self.m_bgType[3] = self.m_gameBg:findChild("SuperFG")

    -- 收集tips
    local nodeTips = util_createAnimation("StarryFest_shouji_tishi.csb")
    self:findChild("Node_tips"):addChild(nodeTips)
    -- 收集条
    self.m_collectBar = util_createView("CodeStarryFestSrc.StarryFestCollectBar",{machine = self, m_tips = nodeTips})
    self:findChild("Node_topkuang"):addChild(self.m_collectBar)

    -- 大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("StarryFest_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    -- 大赢棋盘下
    self.m_bigWinBottomSpine = util_spineCreate("StarryFest_guochang2",true,true)
    self:findChild("Node_BigWin"):addChild(self.m_bigWinBottomSpine)
    self.m_bigWinBottomSpine:setVisible(false)

    -- 预告中奖
    self.m_yuGaoSpineTbl = {}
    self.m_yuGaoSpineTbl[1] = util_spineCreate("StarryFest_yugao",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpineTbl[1], 2)
    self.m_yuGaoSpineTbl[1]:setVisible(false)

    -- 预告中奖
    self.m_yuGaoSpineTbl[2] = util_spineCreate("StarryFest_guochang2",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpineTbl[2])
    self.m_yuGaoSpineTbl[2]:setVisible(false)

    -- 特殊spin预告
    self.m_specialSpinAni = util_createAnimation("StarryFest_yugao.csb")
    self:findChild("Node_cutScene"):addChild(self.m_specialSpinAni, 10)
    self.m_specialSpinAni:setVisible(false)

    local specialSpinLight = util_createAnimation("StarryFest_yugao_xt.csb")
    self.m_specialSpinAni:findChild("Node_light"):addChild(specialSpinLight)
    specialSpinLight:runCsbAction("actionframe", true)
    util_setCascadeOpacityEnabledRescursion(self.m_specialSpinAni, true)

    -- base-free过场
    self.m_baseToFreeSpine = util_spineCreate("StarryFest_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_baseToFreeSpine)
    self.m_baseToFreeSpine:setVisible(false)

    -- free-base过场
    self.m_freeToBaseSpine = util_spineCreate("StarryFest_guochang2",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_freeToBaseSpine)
    self.m_freeToBaseSpine:setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "StarryFest_yqqFK.csb")
    self:changeBottomBigWinLabUi("StarryFest_xiaUIzi.csb")

    -- 假scatter层
    self.m_topSymbolNode = cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_topSymbolNode, 30)

    -- 最顶部光效层
    self.m_topEffectNode = cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_topEffectNode, 25)

    self.m_topFixEffectNode = cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_topFixEffectNode, 24)

    -- 收集圈下边的光效
    self.m_bottomNodeEffectNode =  cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_bottomNodeEffectNode, 5)
    -- 收集圈下全部特效框
    self.m_bottomFix_pool = {}

    -- base收集玩法层
    self.m_baseEffectNode = cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_baseEffectNode, 10)
    -- base全部光环
    self.m_baseFixed_pool = {}
    -- 初始化base玩法层
    self:initFixedCircle()

    -- base收集玩法层
    self.m_freeEffectNode = cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_freeEffectNode, 10)
    -- free全部光环
    self.m_freeFixed_pool = {}
    -- 初始化free玩法层
    self:initFixedCircle(true)

    -- bonus2上层假字体
    self.m_topEffectScoreNode = cc.Node:create()
    self:findChild("Node_yugao"):addChild(self.m_topEffectScoreNode, 15)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:addClick(self:findChild("Panel_click"))
    
    self:changeBgSpine(1)
end


function CodeGameScreenStarryFestMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.2,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 4, 0, 1)
    end)
end

function CodeGameScreenStarryFestMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenStarryFestMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenStarryFestMachine:initGameUI()
    self:updateLocalData()
    self:updateBetLevel()
    self:updateFixedBonus()
    self:refreshJackpotLock()
    self:refreshCollectBar(true)
    if self.m_isSuperFree then
        self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_SupeerFG_Bg)
        self.m_baseFreeSpinBar:setFreeState(true)
        self.m_bottomUI:showAverageBet()
        self:changeBgSpine(3)
    else
        self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_FG_Bg)
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.m_baseFreeSpinBar:setFreeState(false)
            self:changeBgSpine(2)
        end
    end
end

function CodeGameScreenStarryFestMachine:addObservers()
    CodeGameScreenStarryFestMachine.super.addObservers(self)
    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:clearWinLineEffect()
            self:updateBetLevel()
            self:updateFixedBonus()
            self:refreshJackpotLock()
            self:refreshCollectBar(true)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

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
        
        local totalBet = self:getCurSpinStateBet()
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

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
            if self.m_isSuperFree then
                bgmType = "superFg"
            end
        else
            bgmType = "base"
        end

        local soundName = "StarryFestSounds/music_StarryFest_last_win_".. bgmType .. "_"..soundIndex..".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenStarryFestMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenStarryFestMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenStarryFestMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0

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
            local ratio = display.height / display.width
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            if ratio == 1228 / 768 then
                mainScale = mainScale * 1.02
                tempPosY = 3
            elseif ratio >= 1152/768 and ratio < 1228/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            elseif ratio >= 920/768 and ratio < 1152/768 then
                local mul = (1152 / 768 - display.height / display.width) / (1152 / 768 - 920 / 768)
                mainScale = mainScale + 0.05 * mul + 0.03--* 1.16
                tempPosY = 25
            elseif ratio < 1152/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(tempPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenStarryFestMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_StarryFest_10"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_1 then
        return "Socre_StarryFest_Bonus1"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return "Socre_StarryFest_Bonus2"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenStarryFestMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenStarryFestMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--初始棋盘
function CodeGameScreenStarryFestMachine:initGridList()
    CodeGameScreenStarryFestMachine.super.initGridList(self)
    local hasFeature = self:checkHasFeature()
    if hasFeature == false then
        local curBet = self:getCurSpinStateBet()
        local curMul = 6
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                    local symbol_node = slotNode:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if not tolua.isnull(spineNode.m_bonusNodeScore) then
                        local coins = curMul * curBet
                        local sScore = util_formatCoins(coins, 3)
                        local bonusNodeScore = spineNode.m_bonusNodeScore
                        self:setNodeScoreType(bonusNodeScore, self.SYMBOL_SCORE_BONUS_1)
                        local label = bonusNodeScore:findChild("m_lb_coins")
                        label:setString(sScore)
                        self:setBonusScoreTextColor(label, curMul)
                    end
                end
            end
        end
    end
end

--[[
    初始化锁定框层
]]
function CodeGameScreenStarryFestMachine:initFixedCircle(_isFree)
    local effectNode, fixedTbl, csbName
    if _isFree then
        effectNode = self.m_freeEffectNode
        fixedTbl = self.m_freeFixed_pool
        csbName = "StarryFest_Lock_FG.csb"
    else
        effectNode = self.m_baseEffectNode
        fixedTbl = self.m_baseFixed_pool
        csbName = "StarryFest_Lock_Base.csb"
    end
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local fixCircleNode = util_createAnimation(csbName)
            --获取小块索引
            local index = self:getPosReelIdx(iRow ,iCol,self.m_iReelRowNum)
            effectNode:addChild(fixCircleNode, index)
            --转化坐标位置    
            local pos = self:getWorldToNodePos(effectNode, index)
            fixCircleNode:setPosition(pos)

            fixCircleNode:runCsbAction("idle", true)
            fixCircleNode:setVisible(false)
            --存储固定圈
            fixedTbl[index] = fixCircleNode

            -- 特效框下边的光效
            local bottomEffectAni = util_createAnimation("StarryFest_Lock_dg.csb")
            self.m_bottomNodeEffectNode:addChild(bottomEffectAni, index)
            bottomEffectAni:setPosition(pos)
            bottomEffectAni:setVisible(false)
            self.m_bottomFix_pool[index] = bottomEffectAni
        end
    end
end

-- 重置self.m_freeFixed_pool层级
function CodeGameScreenStarryFestMachine:setFreeFixCircleNodeZorder(_isReset, _index)
    if _isReset then
        for i=1, #self.m_freeFixed_pool do
            local circleNode = self.m_freeFixed_pool[i]
            circleNode:setLocalZOrder(i)
        end
    else
        local circleNode = self.m_freeFixed_pool[_index]
        circleNode:setLocalZOrder(_index+20)
    end
end

-- base和free显示光圈node
function CodeGameScreenStarryFestMachine:showCircleNode(_isFree)
    self.m_freeEffectNode:setVisible(_isFree)
    self.m_baseEffectNode:setVisible(not _isFree)
end

-- base和free隐藏光圈
function CodeGameScreenStarryFestMachine:hideCircleAni(_isFree)
    if _isFree then
        if self.m_freeFixed_pool and #self.m_freeFixed_pool > 0 then
            for k, v in pairs(self.m_freeFixed_pool) do
                v:setVisible(false)
            end
        end
    else
        if self.m_baseFixed_pool and #self.m_baseFixed_pool > 0 then
            for k, v in pairs(self.m_baseFixed_pool) do
                v:setVisible(false)
            end
        end
    end

    -- 圈下边的特效；base和free共用
    if self.m_bottomFix_pool and #self.m_bottomFix_pool > 0 then
        for k, v in pairs(self.m_bottomFix_pool) do
            v:setVisible(false)
        end
    end
end

-- 固定bonus1
-- 特殊spin玩法赋值
function CodeGameScreenStarryFestMachine:updateFixedBonus(_isFreeOver)
    if self:getCurrSpinMode() == FREE_SPIN_MODE and not _isFreeOver then
        self:showCircleNode(true)
        self:hideCircleAni(true)

        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        if fsExtraData.storedIcons then
            local storedIcons = fsExtraData.storedIcons
            for k, v in pairs(storedIcons) do
                local pos = v.position
                local spinTimes = v.spinTimes
                local mul = v.multiple
                local circleNodeAni = self.m_freeFixed_pool[pos]
                local bottomEffectAni = self.m_bottomFix_pool[pos]
                circleNodeAni:setVisible(true)
                circleNodeAni:runCsbAction("idle", true)
                bottomEffectAni:setVisible(true)
                bottomEffectAni:runCsbAction("idle", true)
                self:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
            end
        end

        -- 特殊spin
        if not self.m_runSpinResultData.p_selfMakeData then
            return
        end
        -- 特殊spin玩法
        local featureSpin = self.m_runSpinResultData.p_selfMakeData.featureSpin or 0
        local featureType = self.m_runSpinResultData.p_selfMakeData.featureType or 0
        local featureLevel = self.m_runSpinResultData.p_selfMakeData.featureLevel or 0
        -- 特殊spin赋值
        self:setSpecialSpinPlay(featureSpin, featureType, featureLevel)
    else
        self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.BASE
        self:removeSpinStateNode()
        self:showCircleNode(false)
        self:hideCircleAni()

        if not self.m_runSpinResultData.p_selfMakeData then
            return
        end
        local bets = self.m_runSpinResultData.p_selfMakeData.bets
        local curBet = self:getCurSpinStateBet()
        if bets and bets[tostring( toLongNumber(curBet) )] then
            local betData = bets[tostring(toLongNumber(curBet))]
            if betData then
                -- 固定bonus1
                local storedIcons = betData.storedIcons
                for k, v in pairs(storedIcons) do
                    local pos = v.position
                    local spinTimes = v.spinTimes
                    local mul = v.multiple
                    local circleNodeAni = self.m_baseFixed_pool[pos]
                    local bottomEffectAni = self.m_bottomFix_pool[pos]
                    if spinTimes >= 0 then
                        circleNodeAni:setVisible(true)
                        circleNodeAni:runCsbAction("idle", true)
                        bottomEffectAni:setVisible(true)
                        bottomEffectAni:runCsbAction("idle", true)
                        self:setBaseCircleNodeVisibleState(mul, spinTimes, circleNodeAni, bottomEffectAni, true)
                    end
                end
                -- 特殊spin玩法
                local featureSpin = betData.featureSpin or 0
                local featureType = betData.featureType or 0
                local featureLevel = betData.featureLevel or 0
                -- 特殊spin赋值
                self:setSpecialSpinPlay(featureSpin, featureType, featureLevel)
            end
        end
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenStarryFestMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData and fsExtraData.type then
            self.m_isSuperFree = fsExtraData.type > 0 and true or false
        end
    end
end

function CodeGameScreenStarryFestMachine:initGameStatusData(gameData)
    CodeGameScreenStarryFestMachine.super.initGameStatusData(self,gameData)
    --收集进度数据
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.freespinCount then
        self.m_collectCount = gameData.gameConfig.extra.freespinCount
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenStarryFestMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenStarryFestMachine:beginReel()
    self.collectBonus = false
    self.m_rewardBonusData = {}
    self.m_collectBar:spinCloseTips()
    self:setSpinCircleState()
    self:setCurMusicState()
    CodeGameScreenStarryFestMachine.super.beginReel(self)
end

function CodeGameScreenStarryFestMachine:getWinCoinTime()
    local totalBet = self:getCurSpinStateBet()
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

function CodeGameScreenStarryFestMachine:requestSpinResult()
    if self:getCurSpinIsSpecial() then
        --播放特殊spin预告
        self:playSpecialSpinAni(function()
            CodeGameScreenStarryFestMachine.super.requestSpinResult(self)
        end)
    else
        CodeGameScreenStarryFestMachine.super.requestSpinResult(self)
    end
end

--[[
    @desc: 滚动开始前 重置每列的滚动参数信息
    time:2020-07-21 19:25:40
    @return:
]]
function CodeGameScreenStarryFestMachine:resetParentDataReel(parentData)
    CodeGameScreenStarryFestMachine.super.resetParentDataReel(self, parentData)
    if self:getCurSpinIsSpecial() then
        parentData.moveSpeed = 800
    end
end

-- 是否为特殊spin
function CodeGameScreenStarryFestMachine:getCurSpinIsSpecial()
    if self.m_isSpecialSpinType ~= self.M_ENUM_SPIN_TYPE.BASE then
        return true
    end
    return false
end

-- 是否为特殊spin低等级2级和高等级(有bonus1；还有bonus2)
function CodeGameScreenStarryFestMachine:getCurSpinIsSpecialBonus()
    if self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_2 or self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_HEIGHT then
        return true
    end
    return false
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenStarryFestMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    -- 全是bonus1
    if self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_1 then
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndexSpecial_1(parentData.cloumnIndex)
    elseif self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_2 or self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_HEIGHT then
        -- bonus1和bonus2
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndexSpecial_2(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

-- spin时光圈显示的状态
function CodeGameScreenStarryFestMachine:setSpinCircleState()
    if self.m_spinNodeStateTbl and #self.m_spinNodeStateTbl > 0 then
        for k, v in pairs(self.m_spinNodeStateTbl) do
            if not tolua.isnull(v) then
                v:setVisible(true)
                v:runCsbAction("actionframe", true)
            end
        end
    end
    if self.m_spinTimesOverNodeTbl and #self.m_spinTimesOverNodeTbl > 0 then
        for k, v in pairs(self.m_spinTimesOverNodeTbl) do
            if not tolua.isnull(v) then
                v:runCsbAction("over", false, function()
                    v:setVisible(false)
                end)
            end
        end
    end

    -- free并且为特殊spin时；显示特效光圈
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:getCurSpinIsSpecialBonus() then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        if fsExtraData.storedIcons then
            local storedIcons = fsExtraData.storedIcons
            for k, v in pairs(storedIcons) do
                local pos = v.position
                local mul = v.multiple
                local circleNodeAni = self.m_freeFixed_pool[pos]
                local bottomNodeAni = self.m_bottomFix_pool[pos]
                circleNodeAni:runCsbAction("idle_qd", true)
                bottomNodeAni:runCsbAction("idle_qd", true)
            end
        end
    end

    -- 显示bonus2插槽上的字体
    -- 移除顶部bonus2上假的字体
    self:showBonusScoreNodeAndRemove()
end

-- 显示bonus2插槽上的字体
-- 移除顶部bonus2上假的字体
function CodeGameScreenStarryFestMachine:showBonusScoreNodeAndRemove()
    for k ,v in pairs(self.m_falseScoreNodeTbl) do
        if not tolua.isnull(v) then
            util_resetCsbAction(v.m_csbAct)
            v:removeFromParent()
            self.m_falseScoreNodeTbl[k] = nil

            local fixPos = self:getRowAndColByPos(k)
            local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if slotNode then
                self:setBonusScoreNodeState(slotNode, true)
                if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                    local actName = self.m_falseBonusAniTypeTbl[k]
                    slotNode:runAnim(actName, false)
                    self.m_falseBonusAniTypeTbl[k] = nil
                end
            end
        end
    end
    self.m_topEffectScoreNode:removeAllChildren()
    self.m_falseScoreNodeTbl = {}
    self.m_falseBonusAniTypeTbl = {}
end

--
--单列滚动停止回调
--
function CodeGameScreenStarryFestMachine:slotOneReelDown(reelCol)    
    CodeGameScreenStarryFestMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)

    -- free并且为特殊spin时；当前列特效光圈消失
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:getCurSpinIsSpecialBonus() then
        for iRow = 1, self.m_iReelRowNum do
            local pos = self:getPosReelIdx(iRow, reelCol)
            local circleNodeAni = self.m_freeFixed_pool[pos]
            local bottomNodeAni = self.m_bottomFix_pool[pos]
            circleNodeAni:runCsbAction("idle", true)
            bottomNodeAni:runCsbAction("idle", true)
        end
    end
end

--[[
    滚轮停止
]]
function CodeGameScreenStarryFestMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenStarryFestMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenStarryFestMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    if self:getCurSpinIsSpecial() then
        self.m_specialSpinAni:runCsbAction("over", false, function()
            self.m_specialSpinAni:setVisible(false)
        end)
    end
    -- 动画重置
    local tempSpecialSpin = self.m_isSpecialSpinType
    -- 重置玩法
    self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.BASE
    -- 特殊spin玩法
    local featureSpin = self.m_runSpinResultData.p_selfMakeData.featureSpin or 0
    local featureType = self.m_runSpinResultData.p_selfMakeData.featureType or 0
    local featureLevel = self.m_runSpinResultData.p_selfMakeData.featureLevel or 0
    -- 特殊spin赋值
    self:setSpecialSpinPlay(featureSpin, featureType, featureLevel)

    -- 1.增加；2.刷新；3减少；4：消失
    local updateStoredIcons = self.m_runSpinResultData.p_selfMakeData.updateStoredIcons or {}
    -- 固定bonus玩法
    if next(updateStoredIcons) then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_isSuperFree then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.EFFECT_BONUS_SUPER_FREE_FIXED_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_BONUS_SUPER_FREE_FIXED_EFFECT -- 动画类型

                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.EFFECT_BONUS_SUPER_FREE_SIDE_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_BONUS_SUPER_FREE_SIDE_EFFECT -- 动画类型
            else
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.EFFECT_BONUS_FREE_FIXED_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_BONUS_FREE_FIXED_EFFECT -- 动画类型
            end
        else
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_BONUS_BASE_FIXED_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_BONUS_BASE_FIXED_EFFECT -- 动画类型
        end
    end

    local rewardData = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    -- 固定bonus玩法奖励玩法
    if next(rewardData) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_REWARD_EFFECT
        selfEffect.specialSpin = tempSpecialSpin
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_REWARD_EFFECT -- 动画类型

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_DARK_EFFECT
        selfEffect.specialSpin = tempSpecialSpin
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_DARK_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenStarryFestMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BONUS_DARK_EFFECT then
        local isSpecialSpin = effectData.specialSpin ~= self.M_ENUM_SPIN_TYPE.BASE and true or false
        self:showBonusDark(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, isSpecialSpin)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_BASE_FIXED_EFFECT then
        self:addBaseFixedBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_FREE_FIXED_EFFECT then
        self:addFreeFixedBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_SUPER_FREE_FIXED_EFFECT then
        self:addSuperFreeFixedBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_REWARD_EFFECT then
        -- 先排序
        local rewardData = self.m_runSpinResultData.p_selfMakeData.storedIcons
        local tempDataTbl = {}
        if next(rewardData) then
            for i=1, #rewardData do
                local tempTbl = {}
                local pos = rewardData[i][2]
                local fixPos = self:getRowAndColByPos(pos)
                tempTbl.p_rowIndex = fixPos.iX
                tempTbl.p_cloumnIndex = fixPos.iY
                tempTbl.p_pos = pos
                tempTbl.p_rewardType = rewardData[i][1]
                tempTbl.p_rewardCoins = rewardData[i][3]
                tempTbl.p_mul = rewardData[i][4]
                table.insert(tempDataTbl, tempTbl)
            end
        end
        table.sort(tempDataTbl, function(a, b)
            if a.p_cloumnIndex ~= b.p_cloumnIndex then
                return a.p_cloumnIndex < b.p_cloumnIndex
            end
            if a.p_rowIndex ~= b.p_rowIndex then
                return a.p_rowIndex > b.p_rowIndex
            end
            return false
        end)
        performWithDelay(self.m_scWaitNode, function()
            self:addFixedReward(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, tempDataTbl, 1, true)
        end, 0.4)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_SUPER_FREE_SIDE_EFFECT then
        self:addSuperSideCircleNode(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

-- 特殊spin赋值
-- 判断是否触发特殊玩法
function CodeGameScreenStarryFestMachine:setSpecialSpinPlay(_featureSpin, _featureType, _featureLevel)
    self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.BASE
    -- 触发特殊玩法
    if _featureSpin and _featureSpin == 1 then
        -- 特殊玩法低级
        if _featureLevel == 0 then
            -- 低等玩法类型1
            if _featureType == 1 then
                self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_1
            else
                -- 低等级玩法类型2
                self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_2
            end
        else
            -- 特殊玩法高级
            self.m_isSpecialSpinType = self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_HEIGHT
        end
    end
end

-- 根据index转换需要节点坐标系
function CodeGameScreenStarryFestMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

-- 先把bonus2压暗
function CodeGameScreenStarryFestMachine:showBonusDark(_callFunc, _isSpecial)
    local callFunc = _callFunc
    local isSpecial = _isSpecial
    local rewardData = self.m_runSpinResultData.p_selfMakeData.storedIcons
    -- 压暗bonus2
    if isSpecial then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                    local isDark = true
                    for i=1, #rewardData do
                        local curBonusData = rewardData[i]
                        local fixPos = self:getRowAndColByPos(curBonusData[2])
                        if fixPos.iX == iRow and fixPos.iY == iCol then
                            isDark = false
                            break
                        end
                    end

                    if isDark then
                        slotNode:runAnim("yaan_start", false, function()
                            slotNode:runAnim("yaan_idle", true)
                        end)
                    end
                end
            end
        end
    end
    if type(callFunc) == "function" then
        callFunc()
    end
end

-- 清除effectNode上的临时特效
function CodeGameScreenStarryFestMachine:removeEffectNodeChild(_clearFixEffect)
    self.m_topEffectNode:removeAllChildren()
    if _clearFixEffect then
        self.m_topFixEffectNode:removeAllChildren()
    end
end

-- 清除当前spin亮的node
function CodeGameScreenStarryFestMachine:removeSpinStateNode()
    if self.m_spinNodeStateTbl and #self.m_spinNodeStateTbl > 0 then
        for k, v in pairs(self.m_spinNodeStateTbl) do
            if not tolua.isnull(v) then
                v:removeFromParent()
            end
        end
    end
    self.m_spinNodeStateTbl = {}
    self.m_spinTimesOverNodeTbl = {}
end

-- base下固定bonus1玩法
function CodeGameScreenStarryFestMachine:addBaseFixedBonus(_callFunc)
    local callFunc = _callFunc
    self:removeSpinStateNode()
    
    self:removeEffectNodeChild()
    local delayTime = 0
    local isPlaySound = true
    --1.增加；2.刷新；3减少；4：消失
    local updateStoredIcons = self.m_runSpinResultData.p_selfMakeData.updateStoredIcons or {}
    if updateStoredIcons and #updateStoredIcons > 0 then
        for k, v in pairs(updateStoredIcons) do
            local addType = v.type
            local pos = v.position
            local spinTimes = v.spinTimes
            local mul = v.multiple
            local circleNodeAni = self.m_baseFixed_pool[pos]
            local bottomEffectAni = self.m_bottomFix_pool[pos]
            util_resetCsbAction(bottomEffectAni.m_csbAct)
            util_resetCsbAction(circleNodeAni.m_csbAct)
            local fixPos = self:getRowAndColByPos(pos)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if addType == 1 or addType == 2 then
                delayTime = 0.5
                local targetPos = self:getWorldToNodePos(self.m_topEffectNode, pos)
                -- 光效
                local lightNode = util_createAnimation("StarryFest_Lock_Base_tx.csb")
                lightNode:runCsbAction("start_tx", false, function()
                    if slotNode then
                        -- slotNode:runAnim("idleframe", true)
                    end
                    lightNode:setVisible(false)
                end)
                for i=1, 5 do
                    local effectNode = lightNode:findChild("Node_Mul_"..i)
                    if effectNode then
                        if mul == i then
                            effectNode:setVisible(true)
                        else
                            effectNode:setVisible(false)
                        end
                    end
                end
                self:setBaseCircleNodeVisibleState(mul, spinTimes, circleNodeAni, bottomEffectAni)
                lightNode:setPosition(targetPos)
                self.m_topEffectNode:addChild(lightNode)
                
                if isPlaySound then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Lock)
                    isPlaySound = false
                end
                circleNodeAni:setVisible(true)
                util_resetCsbAction(circleNodeAni.m_csbAct)
                circleNodeAni:runCsbAction("start", false, function()
                    circleNodeAni:runCsbAction("idle", true)
                end)

                bottomEffectAni:setVisible(true)
                util_resetCsbAction(bottomEffectAni.m_csbAct)
                bottomEffectAni:runCsbAction("start", false, function()
                    bottomEffectAni:runCsbAction("idle", true)
                end)
            elseif addType == 3 then
                if delayTime == 0 then
                    delayTime = 0.2
                end
                self:setBaseCircleNodeVisibleState(mul, spinTimes, circleNodeAni, bottomEffectAni)
            elseif addType == 4 then
                self:setBaseCircleNodeVisibleState(mul, spinTimes, circleNodeAni, bottomEffectAni, true)
                -- self.m_spinTimesOverNodeTbl[#self.m_spinTimesOverNodeTbl+1] = circleNodeAni
                -- self.m_spinTimesOverNodeTbl[#self.m_spinTimesOverNodeTbl+1] = bottomEffectAni
                if delayTime == 0 then
                    delayTime = 0.2
                end
            end
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self:removeEffectNodeChild()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

-- 提供一个公共方法（纯粹为了设置圈上状态的显隐）base
function CodeGameScreenStarryFestMachine:setBaseCircleNodeVisibleState(mul, spinTimes, circleNodeAni, bottomEffectAni, isAddLastTime)
    local totalSpinTimes = 3
    for i=1, 5 do
        local mulNode = circleNodeAni:findChild("Node_Mul_"..i)
        local mulEffectNode = bottomEffectAni:findChild("Node_Mul_"..i)
        if mulNode and mulEffectNode then
            if mul == i then
                mulNode:setVisible(true)
                mulEffectNode:setVisible(true)
                -- 三次spin次数
                for p_count=1, 3 do
                    -- 两种状态：默认为spin用过状态；1.未使用状态；2.spin过程中状态；
                    local childName = "Node_Mul_Pos_"..mul.."_"..p_count
                    local childNode = circleNodeAni:findChild(childName)
                    local lightName = "Node_huan_"..mul.."_"..p_count
                    local LightNode = circleNodeAni:findChild(lightName)
                    if childNode then
                        -- 未使用的次数
                        local noUseSpinTimes = totalSpinTimes-spinTimes
                        -- 大于剩余次数；显示未用状态
                        if p_count > noUseSpinTimes then
                            childNode:setVisible(true)
                            if p_count == (noUseSpinTimes+1) then
                                if LightNode then
                                    childNode:setVisible(false)
                                    local lightNodeAni = util_createAnimation("StarryFest_Lock_Base_huan.csb")
                                    LightNode:addChild(lightNodeAni)
                                    lightNodeAni:runCsbAction("idleframe", true)
                                    lightNodeAni:findChild("sp_mul_1"):setVisible(mul == 1)
                                    lightNodeAni:findChild("sp_mul_2"):setVisible(mul == 2)
                                    lightNodeAni:findChild("sp_mul_3"):setVisible(mul == 3)
                                    lightNodeAni:findChild("sp_mul_5"):setVisible(mul == 5)

                                    -- 先存起来；spin时，lightNodeAni播放actionframe
                                    local tempTbl = {}
                                    self.m_spinNodeStateTbl[#self.m_spinNodeStateTbl+1] = lightNodeAni
                                end
                            end
                        else
                            -- 小于等于剩余次数；显示已经用过状态
                            childNode:setVisible(false)
                        end
                    end
                end
            else
                mulNode:setVisible(false)
                mulEffectNode:setVisible(false)
            end
        end
    end

    -- 切bet或者状态是4（消失的话），次数是0，当前bet spin才会消失
    if isAddLastTime and spinTimes == 0 then
        self.m_spinTimesOverNodeTbl[#self.m_spinTimesOverNodeTbl+1] = circleNodeAni
        self.m_spinTimesOverNodeTbl[#self.m_spinTimesOverNodeTbl+1] = bottomEffectAni
    end
end

-- free下固定bonus1玩法
function CodeGameScreenStarryFestMachine:addFreeFixedBonus(_callFunc)
    local callFunc = _callFunc
    self:removeEffectNodeChild()
    local delayTime = 0
    local isPlaySound = true
    --1.增加；2.刷新；3减少；4：消失；5：倍数不变
    local updateStoredIcons = self.m_runSpinResultData.p_selfMakeData.updateStoredIcons or {}
    if updateStoredIcons and #updateStoredIcons > 0 then
        for k, v in pairs(updateStoredIcons) do
            local addType = v.type
            local pos = v.position
            local spinTimes = v.spinTimes
            local mul = v.multiple
            local circleNodeAni = self.m_freeFixed_pool[pos]
            local bottomEffectAni = self.m_bottomFix_pool[pos]
            util_resetCsbAction(bottomEffectAni.m_csbAct)
            util_resetCsbAction(circleNodeAni.m_csbAct)
            local fixPos = self:getRowAndColByPos(pos)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if addType == 1 or addType == 2 then
                delayTime = 0.5
                local targetPos = self:getWorldToNodePos(self.m_topEffectNode, pos)
                -- 光效
                local lightNode = util_createAnimation("StarryFest_Lock_FG_tx.csb")
                lightNode:runCsbAction("start_tx", false, function()
                    if slotNode then
                        -- slotNode:runAnim("idleframe", true)
                    end
                    lightNode:setVisible(false)
                end)
                for i=1, 5 do
                    local effectNode = lightNode:findChild("Node_Mul_"..i)
                    if effectNode then
                        if mul == i then
                            effectNode:setVisible(true)
                        else
                            effectNode:setVisible(false)
                        end
                    end
                end
                self:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
                lightNode:setPosition(targetPos)
                self.m_topEffectNode:addChild(lightNode)

                if isPlaySound then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Lock)
                    isPlaySound = false
                end

                circleNodeAni:setVisible(true)
                util_resetCsbAction(circleNodeAni.m_csbAct)
                circleNodeAni:runCsbAction("start", false, function()
                    circleNodeAni:runCsbAction("idle", true)
                end)

                bottomEffectAni:setVisible(true)
                util_resetCsbAction(bottomEffectAni.m_csbAct)
                bottomEffectAni:runCsbAction("start", false, function()
                    bottomEffectAni:runCsbAction("idle", true)
                end)
            elseif addType == 3 or addType == 4 then
                if delayTime == 0 then
                    delayTime = 0.2
                end
                self:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
            end
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self:removeEffectNodeChild()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

-- 提供一个公共方法（纯粹为了设置圈上状态的显隐）free
function CodeGameScreenStarryFestMachine:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
    for i=1, 5 do
        local mulNode = circleNodeAni:findChild("Node_Mul_"..i)
        local mulEffectNode = bottomEffectAni:findChild("Node_Mul_"..i)
        if mulNode and mulEffectNode then
            if mul == i then
                mulNode:setVisible(true)
                mulEffectNode:setVisible(true)
            else
                mulNode:setVisible(false)
                mulEffectNode:setVisible(false)
            end
        end
    end
end

-- superFree下固定bonus1玩法
function CodeGameScreenStarryFestMachine:addSuperFreeFixedBonus(_callFunc)
    local callFunc = _callFunc
    local delayTime = 0
    self.m_isPlayEffectTbl = {}
    self:removeEffectNodeChild(true)
    local isPlaySound = true
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local storedIconsExtra = fsExtraData.storedIconsExtra or {}
    if storedIconsExtra and #storedIconsExtra > 0 then
        for k, v in pairs(storedIconsExtra) do
            local pos = v.position
            local mul = v.multiple
            local circleNodeAni = self.m_freeFixed_pool[pos]
            local bottomEffectAni = self.m_bottomFix_pool[pos]
            circleNodeAni:setVisible(true)
            bottomEffectAni:setVisible(true)
            util_resetCsbAction(circleNodeAni.m_csbAct)
            util_resetCsbAction(bottomEffectAni.m_csbAct)
            local fixPos = self:getRowAndColByPos(pos)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            local targetPos = self:getWorldToNodePos(self.m_topEffectNode, pos)
            delayTime = 0.5
            -- 光效
            local lightNode = util_createAnimation("StarryFest_Lock_FG_tx.csb")
            lightNode:runCsbAction("start_tx", false, function()
                if slotNode then
                    -- slotNode:runAnim("idleframe", true)
                end
                lightNode:setVisible(false)
            end)
            for i=1, 5 do
                local effectNode = lightNode:findChild("Node_Mul_"..i)
                if effectNode then
                    if mul == i then
                        effectNode:setVisible(true)
                    else
                        effectNode:setVisible(false)
                    end
                end
            end
            self:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
            lightNode:setPosition(targetPos)
            self.m_topEffectNode:addChild(lightNode)
            
            if isPlaySound then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Lock)
                isPlaySound = false
            end

            circleNodeAni:setVisible(true)
            util_resetCsbAction(circleNodeAni.m_csbAct)
            circleNodeAni:runCsbAction("start", false, function()
                circleNodeAni:runCsbAction("idle", true)
                local circleEffectAni = util_createAnimation("StarryFest_Lock_FG_quan.csb")
                circleEffectAni:setPosition(targetPos)
                self.m_topFixEffectNode:addChild(circleEffectAni)
                circleEffectAni:runCsbAction("start", false, function()
                    circleEffectAni:runCsbAction("idle2", true)
                end)
            end)

            bottomEffectAni:setVisible(true)
            util_resetCsbAction(bottomEffectAni.m_csbAct)
            bottomEffectAni:runCsbAction("start", false, function()
                bottomEffectAni:runCsbAction("idle", true)
            end)
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self:removeEffectNodeChild()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

-- super下；收集结束后；蔓延
function CodeGameScreenStarryFestMachine:addSuperSideCircleNode(_callFunc)
    local callFunc = _callFunc
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local storedIconsExtra = fsExtraData.storedIconsExtra or {}
    self:removeEffectNodeChild(true)
    local delayTime = 0
    if storedIconsExtra and #storedIconsExtra > 0 then
        local sideDataMaxMul = {}
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Lock_Side)
        -- 把side里的数据遍历一下；找出相关位置的最大倍数（后端没有给最后终的倍数）
        for i=1, #storedIconsExtra do
            local curData = storedIconsExtra[i].side
            for k, v in pairs(curData) do
                local pos = v[1]
                local mul = v[2]
                if not sideDataMaxMul[pos] or (sideDataMaxMul[pos] and sideDataMaxMul[pos] < mul) then
                    sideDataMaxMul[pos] = mul
                end
            end
        end

        for k, v in pairs(storedIconsExtra) do
            local pos = v.position
            local mul = v.multiple
            local sideData = v.side
            local circleNodeAni = self.m_freeFixed_pool[pos]
            local bottomEffectAni = self.m_bottomFix_pool[pos]
            self:setFreeFixCircleNodeZorder(false, pos)
            circleNodeAni:setVisible(true)
            bottomEffectAni:setVisible(true)
            util_resetCsbAction(circleNodeAni.m_csbAct)
            util_resetCsbAction(bottomEffectAni.m_csbAct)
            local fixPos = self:getRowAndColByPos(pos)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)

            local circleEffectAni = util_createAnimation("StarryFest_Lock_FG_quan.csb")
            local targetPos = self:getWorldToNodePos(self.m_topEffectNode, pos)
            circleEffectAni:setPosition(targetPos)
            self.m_topEffectNode:addChild(circleEffectAni, 100)

            circleEffectAni:runCsbAction("actionframe", false, function()
                circleEffectAni:setVisible(false)
            end)
            circleNodeAni:runCsbAction("actionframe", false, function()
                circleNodeAni:runCsbAction("idle", true)
            end)
            bottomEffectAni:runCsbAction("actionframe", false, function()
                bottomEffectAni:runCsbAction("idle", true)
            end)
            if #sideData > 0 then
                delayTime = 20/60 + 73/60
            end
            performWithDelay(self.m_scWaitNode, function()
                if slotNode then
                    slotNode:runAnim("idleframe", true)
                end
                self:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
                -- 四周扩散
                if #sideData > 0 then
                    self:playSuperSideCircleAni(pos, sideData, sideDataMaxMul)
                end
            end, 6/60)
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self:removeEffectNodeChild()
        self:setFreeFixCircleNodeZorder(true)
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

-- superFree下；四周扩散
function CodeGameScreenStarryFestMachine:playSuperSideCircleAni(_startIndex, _sideData, _sideDataMaxMul)
    local startIndex = _startIndex
    local sideData = _sideData
    local sideDataMaxMul = _sideDataMaxMul
    for k , v in pairs(sideData) do
        local pos = v[1]
        local mul = sideDataMaxMul[pos] or v[2]
        
        local circleNodeAni = self.m_freeFixed_pool[pos]
        local bottomEffectAni = self.m_bottomFix_pool[pos]
        local circleEffectAni = util_createAnimation("StarryFest_Lock_SuperFG.csb")
        local startPos = self:getWorldToNodePos(self.m_topEffectNode, startIndex)
        local endPos = self:getWorldToNodePos(self.m_topEffectNode, pos)
        circleEffectAni:setPosition(startPos)
        self.m_topEffectNode:addChild(circleEffectAni)

        local oneActionTbl = {}
        oneActionTbl[#oneActionTbl+1] = cc.CallFunc:create(function()
            circleEffectAni:runCsbAction("manyan", false)
        end)
        oneActionTbl[#oneActionTbl+1] = cc.EaseIn:create(cc.MoveTo:create(15/60, endPos), 1)
        oneActionTbl[#oneActionTbl+1] = cc.DelayTime:create(7/60)
        oneActionTbl[#oneActionTbl+1] = cc.CallFunc:create(function()
            if not self.m_isPlayEffectTbl[pos] then
                self.m_isPlayEffectTbl[pos] = true
                circleNodeAni:setVisible(true)
                circleNodeAni:runCsbAction("idle", true)
                bottomEffectAni:setVisible(true)
                bottomEffectAni:runCsbAction("idle", true)
                self:setFreeCircleNodeVisibleState(mul, circleNodeAni, bottomEffectAni)
            end
        end)
        oneActionTbl[#oneActionTbl+1] = cc.DelayTime:create(51/60)
        oneActionTbl[#oneActionTbl+1] = cc.CallFunc:create(function()
            circleEffectAni:setVisible(false)
        end)
        local seq = cc.Sequence:create(oneActionTbl)
        circleEffectAni:runAction(seq)
    end
end

-- 领取奖励
function CodeGameScreenStarryFestMachine:addFixedReward(_callFunc, _rewardData, _curIndex, _isPlayMaxSound)
    self:setMaxMusicBGVolume()
    self.collectBonus = true
    local callFunc = _callFunc
    local rewardData = _rewardData
    local curIndex = _curIndex
    local isPlayMaxSound = _isPlayMaxSound
    if curIndex > #rewardData then
        local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
         --刷新顶栏
        if not bFree and not bLine then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end
        self.collectBonus = false
        performWithDelay(self.m_scWaitNode, function()
            self.m_effectNode:removeAllChildren()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 0.5)
        return
    end

    if curIndex == 1 then
        for k, v in pairs(rewardData) do
            local pos = v.p_pos
            local circleNode = self.m_baseFixed_pool[pos]
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                circleNode = self.m_freeFixed_pool[pos]
            end
            local zhuanNode = circleNode:findChild("Node_zhuan")
            if zhuanNode then
                local zhuanNodeAni = util_createAnimation("StarryFest_Lock_Base_zhuan.csb")
                zhuanNode:addChild(zhuanNodeAni)
                zhuanNodeAni:runCsbAction("actionframe", true)
            end
        end
    end

    local curBonusData = rewardData[curIndex]
    local curRow = curBonusData.p_rowIndex
    local curCol = curBonusData.p_cloumnIndex
    local pos = curBonusData.p_pos
    local rewardType = curBonusData.p_rewardType
    local rewardCoins = curBonusData.p_rewardCoins
    local curMul = curBonusData.p_mul
    local slotNode = self:getFixSymbol(curCol, curRow, SYMBOL_NODE_TAG)
    local topNodeScore = self.m_falseScoreNodeTbl[pos]
    local circleNode = self.m_baseFixed_pool[pos]
    local bottomEffectAni = self.m_bottomFix_pool[pos]
    local zhuanNode = circleNode:findChild("Node_zhuan")
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        circleNode = self.m_freeFixed_pool[pos]
        zhuanNode = circleNode:findChild("Node_zhuan")
    end

    if slotNode then
        local tblActionList = {}
        local delayTime = 15/30
        if zhuanNode then
            zhuanNode:removeAllChildren()
        end
        -- 奖励钱
        if rewardType == self.SYMBOL_SCORE_BONUS_1 then
            if curMul < 5 then
                local oneMulCoins = rewardCoins/curMul
                for i=1, curMul do
                    local jsName = "actionframe_js_x1"
                    local idleName = "actionframe_js_x1_idle"
                    local topNodeJsName = "js_1_2"
                    if curMul == 2 then
                        jsName = "actionframe_js_x2_2"
                        idleName = "actionframe_js_x2_idle"
                        if i == curMul then
                            jsName = "actionframe_js_x2"
                        end
                    elseif curMul == 3 then
                        jsName = "actionframe_js_x3_2"
                        idleName = "actionframe_js_x3_idle"
                        if i == curMul then
                            jsName = "actionframe_js_x3"
                        end
                    end
                    if i == curMul then
                        topNodeJsName = "js_1"
                    end
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        circleNode:runCsbAction("js_1", false)
                        bottomEffectAni:runCsbAction("js_1", false)
                        slotNode:runAnim(jsName, false)
                        self:playhBottomLight(oneMulCoins, true, curMul)
                        self:floatingCoins(oneMulCoins)
                        self:playFalseNodeScore(topNodeScore, topNodeJsName)
                    end)
                    tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        if i == curMul then
                            circleNode:runCsbAction("idle", true)
                            bottomEffectAni:runCsbAction("idle", true)
                            slotNode:runAnim(idleName, true)
                        end
                    end)
                    tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.15)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        if i == curMul then
                            self:addFixedReward(callFunc, rewardData, curIndex+1, isPlayMaxSound)
                        end
                    end)
                end
            else
                -- 5倍
                delayTime = 45/30
                local delayTime1 = 20/30
                tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                    circleNode:runCsbAction("js_2", false)
                    bottomEffectAni:runCsbAction("js_2", false)
                    slotNode:runAnim("actionframe_js_x5", false)
                    self:playFalseNodeScore(topNodeScore, "js_2")
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_MaxMul_Reward)
                    if isPlayMaxSound then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Shinning_Point)
                        isPlayMaxSound = false
                    end
                end)
                tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
                tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                    self:floatingCoins(rewardCoins)
                    self:playhBottomLight(rewardCoins, true, curMul)
                    self.m_bigWinBottomSpine:setVisible(true)
                    util_spinePlay(self.m_bigWinBottomSpine, "actionframe_xb", false)
                    util_spineEndCallFunc(self.m_bigWinBottomSpine, "actionframe_xb", function()
                        self.m_bigWinBottomSpine:setVisible(false)
                    end)
                    local rootNode = self:findChild("root")
                    util_shakeNode(rootNode,5,10,0.5)
                end)
                tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime1)
                tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                    circleNode:runCsbAction("idle", true)
                    bottomEffectAni:runCsbAction("idle", true)
                    slotNode:runAnim("actionframe_js_x5_idle", true)
                end)
                tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.15)
                tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                    self:addFixedReward(callFunc, rewardData, curIndex+1, isPlayMaxSound)
                end)
            end
        else
            delayTime = 15/30
            local delayTime1 = 0
            local circleJsName = "js_1"
            local jsName = "actionframe_js_x1"
            local idleName = "actionframe_js_x1_idle"
            if curMul == 2 then
                jsName = "actionframe_js_x2"
                idleName = "actionframe_js_x2_idle"
            elseif curMul == 3 then
                jsName = "actionframe_js_x3"
                idleName = "actionframe_js_x3_idle"
            elseif curMul == 5 then
                delayTime = 45/30
                delayTime1 = 20/30
                jsName = "actionframe_js_x5"
                idleName = "actionframe_js_x5_idle"
                circleJsName = "js_2"
            end
            -- jackpot
            local jackpotNameTbl = {"grand", "super", "maxi", "mega", "major", "minor", "mini"}
            local jackpotIndex = self.SYMBOL_SCORE_JACKPOT_GRAND - rewardType + 1
            local jackpotName = jackpotNameTbl[jackpotIndex]
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                circleNode:runCsbAction(circleJsName, false)
                bottomEffectAni:runCsbAction(circleJsName, false)
                slotNode:runAnim(jsName, false)
                self:playFalseNodeScore(topNodeScore, circleJsName)
                if curMul == 5 then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_MaxMul_Reward)
                    if isPlayMaxSound then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Shinning_Point)
                        isPlayMaxSound = false
                    end
                else
                    self:playCollectRewardSound(curMul)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_FeedBack)
                end
            end)
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                if curMul == 5 then
                    self.m_bigWinBottomSpine:setVisible(true)
                    util_spinePlay(self.m_bigWinBottomSpine, "actionframe_xb", false)
                    util_spineEndCallFunc(self.m_bigWinBottomSpine, "actionframe_bigwin", function()
                        self.m_bigWinBottomSpine:setVisible(false)
                    end)
                    local rootNode = self:findChild("root")
                    util_shakeNode(rootNode,5,10,0.5)
                end
            end)
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime1)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                circleNode:runCsbAction("idle", true)
                bottomEffectAni:runCsbAction("idle", true)
                slotNode:runAnim(idleName, true)
            end)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                local jackPotWinView = util_createView("CodeStarryFestSrc.StarryFestJackpotWinView",{
                    jackpotType = jackpotName,
                    jackpotMul = curMul,
                    winCoin = rewardCoins,
                    machine = self,
                    func = function()
                        self:playhBottomLight(rewardCoins)
                        self:addFixedReward(callFunc, rewardData, curIndex+1, isPlayMaxSound)
                    end
                })
                gLobalViewManager:showUI(jackPotWinView)
                jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
            end)
        end
        local seq = cc.Sequence:create(tblActionList)
        self.m_scWaitNode:runAction(seq)
    else
        self:addFixedReward(callFunc, rewardData, curIndex, isPlayMaxSound)
    end
end

-- 顶部bonus2上假的字体播动画
function CodeGameScreenStarryFestMachine:playFalseNodeScore(topNodeScore, actName)
    if not tolua.isnull(topNodeScore) then
        topNodeScore:runCsbAction(actName, false)
    end
end

-- 飘钱
function CodeGameScreenStarryFestMachine:floatingCoins(_coins)
    local params = {
        overCoins  = _coins,
        jumpTime   = 0.1,
        animName   = "actionframe",
    }
    self.m_bottomUI.m_bigWinLabCsb:setScale(1)
    self:playBottomBigWinLabAnim(params)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenStarryFestMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    self.m_bigWinBottomSpine:setVisible(true)
    util_spinePlay(self.m_bigWinBottomSpine, "actionframe_bigwin", false)
    util_spinePlay(self.m_bigWinSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_bigWinBottomSpine, "actionframe_bigwin", function()
        self.m_bigWinBottomSpine:setVisible(false)
    end)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe")
    util_shakeNode(rootNode,5,10,aniTime)
end

function CodeGameScreenStarryFestMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    local randomSound = math.random(1, 3)
    local soundName = self.m_publicConfig.SoundConfig.Music_Celebrate_Win_More[randomSound]
    if soundName then
        gLobalSoundManager:playSound(soundName)
    end
    CodeGameScreenStarryFestMachine.super.showEffect_runBigWinLightAni(self, effectData)
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.85)
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end
    return true
end

function CodeGameScreenStarryFestMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenStarryFestMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenStarryFestMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
    end
end

-- 不用系统音效
function CodeGameScreenStarryFestMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenStarryFestMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenStarryFestMachine:checkRemoveBigMegaEffect()
    CodeGameScreenStarryFestMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

--默认按钮监听回调
function CodeGameScreenStarryFestMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" then
        self.m_collectBar:spinCloseTips()
    end
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenStarryFestMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeStarryFestSrc.StarryFestFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_topkuang"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenStarryFestMachine:showFreeSpinView(effectData)
    -- local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    -- if fsExtraData and fsExtraData.type then
    --     self.m_isSuperFree = fsExtraData.type > 0 and true or false
    -- end
    
    local showFSView = function ( ... )
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData and fsExtraData.type then
            self.m_isSuperFree = fsExtraData.type > 0 and true or false
        end

        self.m_topSymbolNode:removeAllChildren()
        local freeStartSpine = util_spineCreate("FreeSpinStart",true,true)
        local freeStartLightSpine = util_spineCreate("FreeSpinStart",true,true)
        
        util_spinePlay(freeStartSpine, "start", false)
        util_spineEndCallFunc(freeStartSpine, "start", function()
            freeStartLightSpine:setVisible(true)
            util_spinePlay(freeStartLightSpine, "idle_sg", true)
            util_spinePlay(freeStartSpine, "idle", true)
        end)

        local cutSceneFunc = function()
            util_spinePlay(freeStartSpine, "over", false)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_startOver)
            end, 5/60)
        end
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        if self.m_isSuperFree then
            self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_SupeerFG_Bg)--fs背景音乐
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_SuperFg_StartStart)
        else
            self:setFsBackGroundMusic(self.m_publicConfig.SoundConfig.Music_FG_Bg)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
        end
        local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            self:showCutPlaySceneAni(self.m_isSuperFree, function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)    
        end)

        view:findChild("Node_lingdang"):addChild(freeStartSpine)
        view:findChild("Node_light"):addChild(freeStartLightSpine)
        freeStartLightSpine:setVisible(false)
        view:setBtnClickFunc(cutSceneFunc)
        view:findChild("Node_free_zi"):setVisible(not self.m_isSuperFree)
        view:findChild("Node_super_zi"):setVisible(self.m_isSuperFree)
        self.m_baseFreeSpinBar:setFreeState(self.m_isSuperFree)
        if self.m_isSuperFree then
            self.m_bottomUI:showAverageBet()
        end
        util_setCascadeOpacityEnabledRescursion(view, true)
    end
    
    self:delayCallBack(0.5,function()
        self:refreshCollectBar(false, function()
            showFSView() 
        end)
    end)    
end

---------------------------------弹版----------------------------------
function CodeGameScreenStarryFestMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    if self.m_isSuperFree then
        ownerlist["m_lb_num_super"] = num
    else
        ownerlist["m_lb_num"] = num
    end

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenStarryFestMachine:showFreeSpinOverView(effectData)
    if self.m_isSuperFree then
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_SuperFg_OverStart, 3, 0, 1)
    else
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 3, 0, 1)
    end
    
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    if globalData.slotRunData.lastWinCoin > 0 then
        local freeOverSpine = util_spineCreate("FreeSpinOver",true,true)
        local freeOverLightSpine = util_spineCreate("StarryFest_guochang2",true,true)
        util_spinePlay(freeOverLightSpine, "actionframe_tbyh", true)
        
        util_spinePlay(freeOverSpine, "start", false)
        util_spineEndCallFunc(freeOverSpine, "start", function()
            util_spinePlay(freeOverSpine, "idle", true)
        end)

        local cutSceneFunc = function()
            util_spinePlay(freeOverSpine, "over", false)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
            end, 5/60)
        end
        local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
            self.m_bottomUI:hideAverageBet()
            self:clearWinLineEffect()
            self:showFreeToBaseSceneAni(function()
                self:triggerFreeSpinOverCallFun()
                self.m_isSuperFree = false
            end)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.98,sy=1.0},694)

        view:findChild("spine"):addChild(freeOverSpine)
        view:findChild("yanhua"):addChild(freeOverLightSpine)
        view:setBtnClickFunc(cutSceneFunc)
        view:findChild("Node_free_zi"):setVisible(not self.m_isSuperFree)
        view:findChild("Node_super_zi"):setVisible(self.m_isSuperFree)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        self:showFreeSpinOverNoWin(function()
            self:clearWinLineEffect()
            self.m_bottomUI:hideAverageBet()
            self:showFreeToBaseSceneAni(function()
                self:triggerFreeSpinOverCallFun()
                self.m_isSuperFree = false
            end)
        end)
    end
end

function CodeGameScreenStarryFestMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if self.m_isSuperFree then
        ownerlist["m_lb_num_super"] = num
    else
        ownerlist["m_lb_num"] = num
    end
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenStarryFestMachine:showFreeSpinOverNoWin(_func)
    local view = util_createView("CodeStarryFestSrc.StarryFestFreeOverView",{machineRootScale = self.m_machineRootScale, func = _func})
    gLobalViewManager:showUI(view)
    view:setPosition(display.center)
    return view
end

--[[
    将小块放回原父节点
]]
function CodeGameScreenStarryFestMachine:putSymbolBackToPreParent(symbolNode, isInTop)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
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
        -- local isInTop = self:isSpecialSymbol(symbolNode.p_symbolType)
        symbolNode.m_isInTop = isInTop
        symbolNode:putBackToPreParent()

        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))
    end
end

-- 进出free更改信号
function CodeGameScreenStarryFestMachine:changeSymbolTypeByPlay(_isFreeOver)
    local baseLastReels = self.m_runSpinResultData.p_selfMakeData.baseLastReels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                local _symbolType = math.random(0, 9)
                if _isFreeOver and baseLastReels then
                    local curRow = self.m_iReelRowNum - iRow + 1
                    _symbolType = baseLastReels[curRow][iCol]
                end
                local symbolName = self:getSymbolCCBNameByType(self, _symbolType)
                slotNode:changeCCBByName(symbolName, _symbolType)
                if slotNode.p_symbolImage then
                    slotNode.p_symbolImage:removeFromParent()
                    slotNode.p_symbolImage = nil
                end
                if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                    self:setSpecialNodeScoreBonus(slotNode, true)
                    slotNode:runAnim("idleframe", true)
                end
                slotNode:changeSymbolImageByName(symbolName)
                self:putSymbolBackToPreParent(slotNode, false)
            end
        end
    end
end

--base到free过场
function CodeGameScreenStarryFestMachine:showCutPlaySceneAni(_isSuper, _callFunc)
    local isSuper = _isSuper
    local callFunc = _callFunc
    if self.m_isSuperFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_SuperFg_CutScene)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
    end
    self.m_baseToFreeSpine:setVisible(true)
    util_spinePlay(self.m_baseToFreeSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_baseToFreeSpine, "actionframe_guochang", function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 90帧切
    performWithDelay(self.m_scWaitNode, function()
        self:showBonusScoreNodeAndRemove()
        self:hideCircleAni(true)
        self:setCurMusicState(true)
        self:showCircleNode(true)
        self:changeSymbolTypeByPlay()
        if self.m_isSuperFree then
            self:changeBgSpine(3)
        else
            self:changeBgSpine(2)
        end
    end, 90/60)
end

--free到base过场
function CodeGameScreenStarryFestMachine:showFreeToBaseSceneAni(_callFunc)
    local callFunc = _callFunc
    if self.m_isSuperFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_SuperFg_Base_CutScene)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)
    end
    self.m_freeToBaseSpine:setVisible(true)
    util_spinePlay(self.m_freeToBaseSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_freeToBaseSpine, "actionframe_guochang", function()
        self.m_freeToBaseSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    
    -- 30帧切
    performWithDelay(self.m_scWaitNode, function()
        self:showBonusScoreNodeAndRemove()
        self:refreshCollectBar(true)
        self:updateFixedBonus(true)
        self:changeSymbolTypeByPlay(true)
        self:showCircleNode(false)
        self:changeBgSpine(1)
    end, 30/60)
end

function CodeGameScreenStarryFestMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self.m_topSymbolNode:removeAllChildren()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:levelDeviceVibrate(6, "free")
    local waitTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local topSatterNode = self:createStarryFestSymbol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                    local scatterPos = self:getPosReelIdx(iRow, iCol)
                    local nodePos = self:getTopSymbolPos(scatterPos)

                    slotNode:setVisible(false)
                    topSatterNode:setPosition(nodePos)
                    local scatterZorder = 10 - iRow + iCol
                    self.m_topSymbolNode:addChild(topSatterNode, scatterZorder)

                    topSatterNode:runAnim("actionframe", false, function()
                        slotNode:setVisible(true)
                        slotNode:runAnim("idleframe", true)
                        topSatterNode:setVisible(false)
                    end)

                    local duration = topSatterNode:getAnimDurationTime("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end
    local winLines = self.m_reelResultLines
    if winLines and #winLines == 0 then
        self:addTriggerFreeCoins()
    end
    self:playScatterTipMusicEffect(true)
    
    performWithDelay(self,function()
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true  
end

function CodeGameScreenStarryFestMachine:createStarryFestSymbol(_symbolType)
    local symbol = util_createView("CodeStarryFestSrc.StarryFestSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenStarryFestMachine:getTopSymbolPos(_pos)
    local clipTarPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local nodePos = self.m_topSymbolNode:convertToNodeSpace(worldPos)
    return nodePos
end

function CodeGameScreenStarryFestMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeStarryFestSrc.StarryFestJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

function CodeGameScreenStarryFestMachine:symbolBulingEndCallBack(_slotNode)
    local curLongRunData = self.m_longRunControl:getCurLongRunData() or {}
    local LegitimatePos = curLongRunData.LegitimatePos or {}
    if table_length(LegitimatePos) > 0  then
        for i=1,#LegitimatePos do
            local posInfo = LegitimatePos[i]
            if table_vIn(posInfo,_slotNode.p_symbolType) and
                table_vIn(posInfo,_slotNode.p_cloumnIndex) and 
                table_vIn(posInfo,_slotNode.p_rowIndex)  then
                -- self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 
                return true
            end
        end
    end
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 

    -- if self:getCurSpinIsSpecial() and _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
    if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
        local pos = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
        if self.m_rewardBonusData and #self.m_rewardBonusData > 0 then--and table_vIn(self.m_rewardBonusData, pos) then
            for k, v in pairs(self.m_rewardBonusData) do
                if pos == v.pos then
                    self:addFalseBonusScore(pos, v.rewardType, v.mul, _slotNode)
                end
            end
        end
    end
    return false 
end

function CodeGameScreenStarryFestMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenStarryFestMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenStarryFestMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenStarryFestMachine:updateReelGridNode(_symbolNode)
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
        self:setSpecialNodeScoreBonus(_symbolNode)
    end
end

function CodeGameScreenStarryFestMachine:setSpecialNodeScoreBonus(_symbolNode, _freeToBase)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = self:getCurSpinStateBet()
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local bonusNodeScore, scatterCoins
    if not tolua.isnull(spineNode.m_bonusNodeScore) then
        bonusNodeScore = spineNode.m_bonusNodeScore
    else
        bonusNodeScore = util_createAnimation("StarryFest_BonusCoins.csb")
        util_spinePushBindNode(spineNode,"zi_gd",bonusNodeScore)
        spineNode.m_bonusNodeScore = bonusNodeScore
    end

    local sScore = ""
    local curMul = 1
    local jackpotType = self.SYMBOL_SCORE_BONUS_1
    local idleNameTbl = {"idle_mini", "idle_minor", "idle_major", "idle_mega", "idle_maxi", "idle_super", "idle_grand"}
    if symbolNode.m_isLastSymbol == true then
        local mul = self:getSpinBonusScore(self:getPosReelIdx(iRow, iCol))
        if _freeToBase then
            mul = self:getSpinFreeToBaseBonusScore(self:getPosReelIdx(iRow, iCol))
        end
        if mul ~= nil and mul ~= 0 then
            local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
            local jackpotName = ""
            for i,jackpotCfg in ipairs(jackpotPools) do
                if jackpotCfg.p_configData.p_multiple == mul then
                    jackpotName = jackpotCfg.p_configData.p_name
                    break
                end
            end
        
            if jackpotName == "GRAND" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_GRAND
            elseif jackpotName == "SUPER" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_SUPER
            elseif jackpotName == "MAXI" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_MAXI
            elseif jackpotName == "MEGA" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_MEGA
            elseif jackpotName == "MAJOR" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_MAJOR
            elseif jackpotName == "MINOR" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_MINOR
            elseif jackpotName == "MINI" then
                jackpotType = self.SYMBOL_SCORE_JACKPOT_MINI
            else
                curMul = mul
                local coins = mul * curBet
                sScore = util_formatCoins(coins, 3)
            end
        end
    else
        -- 获取随机分数（本地配置）
        local isJackpot, mul = self:randomDownSpinSymbolScore(symbolNode.p_symbolType)
        if isJackpot then
            jackpotType = mul
        else
            curMul = mul
            local coins = mul * curBet
            sScore = util_formatCoins(coins, 3)
        end
    end
    self:setNodeScoreType(bonusNodeScore, jackpotType)
    bonusNodeScore:setVisible(true)
    local label = bonusNodeScore:findChild("m_lb_coins")
    label:setString(sScore)
    self:setBonusScoreTextColor(label, curMul)
end

-- 设置bonus上字体颜色
function CodeGameScreenStarryFestMachine:setBonusScoreTextColor(_label, _mul)
    if _mul >= 6 then
        _label:setFntFile("StarryFestFont/font_02.fnt")
    else
        _label:setFntFile("StarryFestFont/font_03.fnt")
    end
end

-- 获取当前bet；super里获取平均bet
function CodeGameScreenStarryFestMachine:getCurSpinStateBet()
    local curBet = globalData.slotRunData:getCurTotalBet()
    if self.m_isSuperFree and self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.avgBet then
        curBet = self.m_runSpinResultData.p_selfMakeData.avgBet
    end
    return curBet
end

-- 设置bonus2上字体的类型
function CodeGameScreenStarryFestMachine:setNodeScoreType(bonusNodeScore, jackpotType)
    bonusNodeScore:runCsbAction("idle", true)
    bonusNodeScore:findChild("Node_coins"):setVisible(jackpotType == self.SYMBOL_SCORE_BONUS_1)
    bonusNodeScore:findChild("Node_mini"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_MINI)
    bonusNodeScore:findChild("Node_minor"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_MINOR)
    bonusNodeScore:findChild("Node_major"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_MAJOR)
    bonusNodeScore:findChild("Node_mega"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_MEGA)
    bonusNodeScore:findChild("Node_maxi"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_MAXI)
    bonusNodeScore:findChild("Node_super"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_SUPER)
    bonusNodeScore:findChild("Node_grand"):setVisible(jackpotType == self.SYMBOL_SCORE_JACKPOT_GRAND)
end

--[[
    随机bonus分数
]]
function CodeGameScreenStarryFestMachine:randomDownSpinSymbolScore(symbolType)
    local score, isJackpot = nil
    -- 最高级
    if self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_HEIGHT then
        isJackpot, score = self.m_configData:getBnBasePro(2)
    elseif self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_2 or self:getCurrSpinMode() == FREE_SPIN_MODE then
        isJackpot, score = self.m_configData:getBnBasePro(1)
    else
        isJackpot, score = self.m_configData:getBnBasePro(0)
    end

    return isJackpot, score
end

--[[
    获取小块真实分数
]]
function CodeGameScreenStarryFestMachine:getSpinBonusScore(id)
    if not self.m_runSpinResultData.p_storedIcons then
        return 0
    end
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local score = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end

-- 获取free回basebonus2上的钱
function CodeGameScreenStarryFestMachine:getSpinFreeToBaseBonusScore(id)
    if not self.m_runSpinResultData.p_selfMakeData or not self.m_runSpinResultData.p_selfMakeData.baseLastStoredCoin then
        return 0
    end
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.baseLastStoredCoin or {}

    local score = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenStarryFestMachine:showFeatureGameTip(_func)
    self:updateLocalData()
    if self:getFeatureGameTipChance(70) then
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

--播放特殊spin预告
function CodeGameScreenStarryFestMachine:playSpecialSpinAni(_func)
    local callFunc = _func
    if not self.m_specialSoundIndex or self.m_specialSoundIndex >= 2 then
        self.m_specialSoundIndex = 1
    else
        self.m_specialSoundIndex = self.m_specialSoundIndex + 1
    end
    
    local soundPath = self.m_publicConfig.SoundConfig.Music_Special_Spin_Sound[self.m_specialSoundIndex]
    if soundPath then
        gLobalSoundManager:playSound(soundPath)
    end
    self.m_yuGaoSpineTbl[2]:setVisible(true)
    self.m_specialSpinAni:setVisible(true)
    self.m_specialSpinAni:runCsbAction("idle", false, function()
        self.m_specialSpinAni:runCsbAction("idle", true)
    end)
    local spineName = "actionframe_tb1"
    -- 低级
    if self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_1 or self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_LOW_2 then
        spineName = "actionframe_tb1"
        self.m_specialSpinAni:findChild("Node_lizi"):setVisible(false)
    elseif self.m_isSpecialSpinType == self.M_ENUM_SPIN_TYPE.SPECIAL_SPIN_HEIGHT then
        -- 高级
        spineName = "actionframe_tb2"
        self.m_specialSpinAni:findChild("Node_lizi"):setVisible(true)
    end
    util_spinePlay(self.m_yuGaoSpineTbl[2], spineName, false)
    util_spineEndCallFunc(self.m_yuGaoSpineTbl[2], spineName, function()
        self.m_yuGaoSpineTbl[2]:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
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
function CodeGameScreenStarryFestMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)
    for i=1, 2 do
        self.m_yuGaoSpineTbl[i]:setVisible(true)
        util_spinePlay(self.m_yuGaoSpineTbl[i], "actionframe_yugao", false)
    end
    util_spineEndCallFunc(self.m_yuGaoSpineTbl[2], "actionframe_yugao", function()
        for i=1, 2 do
            self.m_yuGaoSpineTbl[i]:setVisible(false)
        end
        if type(callFunc) == "function" then
            callFunc()
        end
    end) 
end

--[[
    刷新本地存储数据
]]
function CodeGameScreenStarryFestMachine:updateLocalData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end
    local rewardData = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    if next(rewardData) then
        for k, v in pairs(rewardData) do
            local tempTbl = {}
            tempTbl.rewardType = v[1]
            tempTbl.pos = v[2]
            tempTbl.mul = v[4]
            table.insert(self.m_rewardBonusData, tempTbl)
        end
    end

    -- 各个bet下对应的锁定框
    if selfData.bets then
        self.m_betData = selfData.bets
    end

    --收集进度数据
    if selfData.freespinCount then
        self.m_collectCount = selfData.freespinCount
    end
end

-- 播放1、2、3倍的音效
function CodeGameScreenStarryFestMachine:playCollectRewardSound(_curMul)
    if _curMul == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_FeedBack1)
    elseif _curMul == 2 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_FeedBack2)
    elseif _curMul == 3 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_FeedBack3)
    end
end

-- free播触发时，没连线需要加钱
function CodeGameScreenStarryFestMachine:addTriggerFreeCoins()
    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = self.m_runSpinResultData.p_winAmount
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        totalWinCoin = self.m_runSpinResultData.p_fsWinCoins
    end
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

function CodeGameScreenStarryFestMachine:playhBottomLight(_endCoins, _playEffect, _curMul)
    if _playEffect and _curMul then
        self:playCollectRewardSound(_curMul)
        self.m_bottomUI:playCoinWinEffectUI()
    end

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenStarryFestMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenStarryFestMachine:getCurBottomWinCoins()
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

function CodeGameScreenStarryFestMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.superFree
    for i=1, 3 do
        if i == _bgType then
            self.m_bgType[i]:setVisible(true)
        else
            self.m_bgType[i]:setVisible(false)
        end
    end
    self.m_collectBar:setVisible(_bgType==1)
    self.m_baseFreeSpinBar:setVisible(_bgType>1)
    if _bgType <= 3 then
        local bgType = _bgType
        if bgType == 3 then
            bgType = 2
        end
        self:setReelBgState(bgType)
    end
end

function CodeGameScreenStarryFestMachine:setReelBgState(_bgType)
    for i=1, 2 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

-- 更改背景音乐类型
function CodeGameScreenStarryFestMachine:setCurMusicState(_isFree)
    if self:getCurSpinIsSpecial() then
        self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Special_Spin_Bg)
    else
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE or _isFree then
            if self.m_isSuperFree then
                self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_SupeerFG_Bg)
            else
                self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
            end
        else
            self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Base_Bg)
        end
    end
end

--[[
    刷新jackpot解锁状态
]]
function CodeGameScreenStarryFestMachine:refreshJackpotLock()
    self.m_jackPotBarView:setLockJackpot(self.m_iBetLevel)
end

--[[
    刷新收集进度
]]
function CodeGameScreenStarryFestMachine:refreshCollectBar(_onEnter, _callfunc)
    local onEnter = _onEnter
    local curCollect = self.m_collectCount
    if self.m_iBetLevel == 0 then
        self.m_collectBar:lockAni()
    else
        self.m_collectBar:unLockAni()
    end
    self.m_collectBar:refreshCollectCount(curCollect, _onEnter, _callfunc)
end

function CodeGameScreenStarryFestMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local lineWinCoins  = self:getClientWinCoins()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

function CodeGameScreenStarryFestMachine:tipsBtnIsCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end

    return true
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenStarryFestMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                return self:isPlayTipBonus(_slotNode)
            else
                return true
            end
        end
    end

    return false
end

-- 设置顶层score钱数
function CodeGameScreenStarryFestMachine:setFalseNodeScoreType(_pos, _rewardType, _topNodeScore)
    local curBet = self:getCurSpinStateBet()
    local fixPos = self:getRowAndColByPos(_pos)
    local mul = self:getSpinBonusScore(self:getPosReelIdx(fixPos.iX, fixPos.iY))
    local coins = mul * curBet
    local sScore = util_formatCoins(coins, 3)
    local label = _topNodeScore:findChild("m_lb_coins")
    label:setString(sScore)
    self:setBonusScoreTextColor(label, mul)
    self:setNodeScoreType(_topNodeScore, _rewardType)
end

-- bonus2落地条件
function CodeGameScreenStarryFestMachine:isPlayTipBonus(_slotNode)
    local pos = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
    if self.m_rewardBonusData and #self.m_rewardBonusData > 0 then--and table_vIn(self.m_rewardBonusData, pos) then
        for k, v in pairs(self.m_rewardBonusData) do
            if pos == v.pos then
                -- 第八帧往上边加字体
                if not self:getCurSpinIsSpecial() then
                    performWithDelay(self.m_scWaitNode, function()
                        self:addFalseBonusScore(pos, v.rewardType, v.mul, _slotNode)
                    end, 8/30)
                end
                return true
            end
        end
    end
    return false
end

-- 添加落地bonus2假的字体
function CodeGameScreenStarryFestMachine:addFalseBonusScore(pos, rewardType, _mul, _slotNode)
    local actName = {"actionframe_js_x1_over", "actionframe_js_x2_over", "actionframe_js_x3_over", "actionframe_js_x5_over", "actionframe_js_x5_over"}
    if not self.m_falseScoreNodeTbl[pos] then
        local topNodeScore = util_createAnimation("StarryFest_BonusCoins.csb")
        self:setFalseNodeScoreType(pos, rewardType, topNodeScore)
        local scorePos = self:getWorldToNodePos(self.m_topEffectNode, pos)
        topNodeScore:setPosition(scorePos)
        self.m_topEffectScoreNode:addChild(topNodeScore)
        self.m_falseScoreNodeTbl[pos] = topNodeScore
        self.m_falseBonusAniTypeTbl[pos] = actName[_mul]
        self:setBonusScoreNodeState(_slotNode, false)
    end
end

-- 插槽上ScoreNode显隐
function CodeGameScreenStarryFestMachine:setBonusScoreNodeState(_slotNode, _state, _jsName)
    local jsName = _jsName
    local symbol_node = _slotNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if not tolua.isnull(spineNode.m_bonusNodeScore) then
        local bonusNodeScore = spineNode.m_bonusNodeScore
        bonusNodeScore:setVisible(_state)
        bonusNodeScore:runCsbAction("js_idle", true)
    end
end

-- scatter落地条件
function CodeGameScreenStarryFestMachine:isPlayTipAnima(colIndex, rowIndex, node)
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

-- 获取是否有bonus奖励
function CodeGameScreenStarryFestMachine:getCurIsHaveBonusReward()
    if self.m_rewardBonusData and #self.m_rewardBonusData > 0 then
        return true
    end
    return false
end

--21.12.06-播放不影响老关的落地音效逻辑
--同一列如果同时有bonus1和bonus2的落地音效；只播放bonus1的落地音效
function CodeGameScreenStarryFestMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    -- 先检查当前列是否有bonus2落地
    local isPlayBonus1Sound = true
    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            if symbolType == self.SYMBOL_SCORE_BONUS_2 then
                isPlayBonus1Sound = false
                break
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
                if soundPath then
                    if symbolType == self.SYMBOL_SCORE_BONUS_1 then
                        if isPlayBonus1Sound then
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

function CodeGameScreenStarryFestMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenStarryFestMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

function CodeGameScreenStarryFestMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    local isHaveBonus = self:getCurIsHaveBonusReward()
    if #self.m_vecGetLineInfo == 0 and not isHaveBonus then
        notAdd = true
    end

    return notAdd
end

return CodeGameScreenStarryFestMachine






