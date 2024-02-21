---
-- island li
-- 2019年1月26日
-- CodeGameScreenLuxeVegasMachine.lua
-- 
-- 玩法：
--[[
    收集玩法：
        1.出现bonus1（94信号）会收集；收集到当前所在列的区域（每列收集的奖金是独立的）
        2.bonus2（101，102，103信号）只会出现在第五列，分别为三挡free玩法，收集的是进入free玩法的次数
    base:
        1.scatter会出现在任意列，三个触发大转盘玩法
    free：
        1.free下不会出现scatter，不会有freeMore
    大转盘玩法：
        1.三个scatter触发大转盘玩法；只在base下触发；
        2.大转盘可以获得free1，free2，free3，Major，Mega，Grand；6中奖励；jackpot直接获取，free则进free玩法
    小转盘玩法：
        1.转盘bonus（95信号；大信号；三个格子）触发小转盘玩法
        2.小转盘可以获得：
                    ①.乘倍奖励（10种）：1X 2X 3X 4X 5X 6X 7X 8X 9X 10X
                    ②.获得全部累计奖金（1种）：AWARD ALL CASH REELS
                    ③.乘倍奖励+多福多财奖励（3种）：1X+jackpot；2X+jackpot；3X+jackpot
    多福多彩玩法：
        1.通过小转盘转出该玩法
        2.点击出三个相同类型jackpot，获取该奖励，结束该玩法
]]
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "LuxeVegasPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenLuxeVegasMachine = class("CodeGameScreenLuxeVegasMachine", BaseSlotoManiaMachine)

CodeGameScreenLuxeVegasMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenLuxeVegasMachine.SYMBOL_SCORE_BONUS = 94
CodeGameScreenLuxeVegasMachine.SYMBOL_SCORE_WHEEL_BONUS = 95
CodeGameScreenLuxeVegasMachine.SYMBOL_SCORE_CHANGE_BONUS = 96
CodeGameScreenLuxeVegasMachine.SYMBOL_SCORE_BONUS_FREE_1 = 101
CodeGameScreenLuxeVegasMachine.SYMBOL_SCORE_BONUS_FREE_2 = 102
CodeGameScreenLuxeVegasMachine.SYMBOL_SCORE_BONUS_FREE_3 = 103

CodeGameScreenLuxeVegasMachine.EFFECT_BONUS_RELOAD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1  --bonusWheel玩法；小转盘结束后播放reload动画
CodeGameScreenLuxeVegasMachine.EFFECT_BONUS_WHEEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2  --bonusWheel玩法；小转盘
CodeGameScreenLuxeVegasMachine.EFFECT_BONUS_FREE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3   --bonusFree玩法；加free次数
CodeGameScreenLuxeVegasMachine.EFFECT_BONUS_COINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4  --bonus玩法；加钱

--自定义的小块类型
-- CodeGameScreenLuxeVegasMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE


-- 自定义动画的标识
-- CodeGameScreenLuxeVegasMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 



-- 构造函数
function CodeGameScreenLuxeVegasMachine:ctor()
    CodeGameScreenLuxeVegasMachine.super.ctor(self)
    -- 引入控制插件
    self.m_longRunControl = util_createView("CodeLuxeVegasSrc/LuxeVegasLongRunControl",self) 

    self.m_isFeatureOverBigWinInFree = true
    self.m_triggerBigWinEffect = false
    --大赢光效
    self.m_isAddBigWinLightEffect = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    --base和free行数
    self.m_baseShowRow = 3
    self.m_freeShowRow = 5
    -- 遮罩透明度
    self.m_panelOpacity = 153
    -- bonus初始倍数(bet取不到时用这个；需*curBet)
    self.m_bonusInitMul = {}
    -- free初始次数
    self.m_freeInitCount = {}
    -- bonus收集区域需要变颜色的倍数
    self.m_collectBgMul = {}
    -- 玩法类型；1：base；10：free*10；25：free*25；50：free*50
    self.m_gamePlayMul = 1
    self.M_ENUM_TYPE = {
        BASE = 1,
        FREE_1 = 10,
        FREE_2 = 25,
        FREE_3 = 50,
    }
    -- 收到网络数据后；判断是否有bonuswheel信号；用于判断播放bonusWheel提层
    self.m_isTriggerBonusTbl = {}

    -- 小轮盘小倍数音效index
    self.m_smallWheelSoundIndex = 1
 
    --init
    self:initGame()
end

function CodeGameScreenLuxeVegasMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LuxeVegasConfig.csv", "LevelLuxeVegasConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLuxeVegasMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LuxeVegas"  
end

function CodeGameScreenLuxeVegasMachine:getBottomUINode()
    return "CodeLuxeVegasSrc.LuxeVegasBottomNode"
end

function CodeGameScreenLuxeVegasMachine:updateBetLevel()
    local curCollectData = {}
    local curFreeCountData = {}
    local isUseBet = false
    local isUseFree = false
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    if self.m_runSpinResultData.p_selfMakeData then
        if self.m_runSpinResultData.p_selfMakeData.bets then
            local bets = self.m_runSpinResultData.p_selfMakeData.bets
            if bets and betCoin and bets[tostring(toLongNumber(betCoin) )] then
                isUseBet = true
                curCollectData = bets[tostring(toLongNumber(betCoin))]
            end
        end
        if self.m_runSpinResultData.p_selfMakeData.frees then
            local frees = self.m_runSpinResultData.p_selfMakeData.frees
            if frees and betCoin and frees[tostring(toLongNumber(betCoin))] then
                isUseFree = true
                curFreeCountData = frees[tostring(toLongNumber(betCoin))]
            end
        end
    end

    -- 没有对应bet；用默认值
    if not isUseBet then
        if self.m_bonusInitMul and #self.m_bonusInitMul > 0 then
            for i=1, #self.m_bonusInitMul do
                curCollectData[i] = betCoin*self.m_bonusInitMul[i]
            end
        end
    end
    -- 没有free；默认值
    if not isUseFree then
        for i=1, #self.m_freeInitCount do
            curFreeCountData[i] = self.m_freeInitCount[i]
        end
    end
    
    -- 刷新收集
    self.m_collectView:refreshCollectCoins(curCollectData)
    -- 刷新free次数
    self.m_collectDiamondView:setFreeCountData(curFreeCountData, true)
end

function CodeGameScreenLuxeVegasMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self.m_gameBg:runCsbAction("idleframe", true)

    self.m_spBgTbl = {}
    self.m_spBgTbl[1] = self.m_gameBg:findChild("Base")
    self.m_spBgTbl[2] = self.m_gameBg:findChild("FG")
    self.m_spBgTbl[3] = self.m_gameBg:findChild("dfdc")
    
    self:initFreeSpinBar()
    self.m_symbolExpectCtr = util_createView("CodeLuxeVegasSrc.LuxeVegasSymbolExpect", self) 
    -- FreeSpinbar
    self:initJackPotBarView()
    self:showJackpotType()

    -- 收集栏光效（要放在最顶层）
    local collectItemLightTbl = {}
    for i=1, 5 do
        collectItemLightTbl[i] = util_createAnimation("LuxeVegas_shoujilan_item_light.csb")
        self:findChild("Node_collect_"..i):addChild(collectItemLightTbl[i])
    end

    --收集钱
    self.m_collectView = util_createView("CodeLuxeVegasSrc.LuxeVegasCollectView", self, collectItemLightTbl)
    self:findChild("Node_shoujilan"):addChild(self.m_collectView)

    -- 收集free次数
    self.m_fgDiamondNodeTop = self:findChild("Node_FGzhanshi_top")
    self.m_fgDiamondNodeBottom = self:findChild("Node_FGzhanshi_bottom")
    self.m_collectDiamondView = util_createView("CodeLuxeVegasSrc.LuxeVegasCollectDiamondView", self)
    self.m_fgDiamondNodeTop:addChild(self.m_collectDiamondView)

    -- 多福多彩
    self.m_colorfulGameView = util_createView("CodeLuxeVegasSrc.LuxeVegasColorfulGame", self, self.m_jackpotColorBar)
    self:findChild("Node_dfdc"):addChild(self.m_colorfulGameView)
    self.m_colorfulGameView:setVisible(false)

    -- freeTitle
    self.m_freeTitleBar = util_createView("CodeLuxeVegasSrc.LuxeVegasFreeTitleBar", self)
    self:findChild("Node_FGtitle"):addChild(self.m_freeTitleBar)

    --遮罩
    self.m_panelUpList = self:createSpinMask(self)

    --特效层
    self.m_effectNode = self:findChild("Node_topEffect")

    local nodePosX, nodePosY = self:findChild("Node_topEffect"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))

    -- free过场
    self.m_guoChangSpine = util_spineCreate("LuxeVegas_guochang",true,true)
    self.m_guoChangSpine:setPosition(worldPos)
    self.m_guoChangSpine:setScale(self.m_machineRootScale)
    self:addChild(self.m_guoChangSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine:setVisible(false)

    -- 多福多彩过场
    self.m_guoChangSpine_1 = util_spineCreate("LuxeVegas_guochang1",true,true)
    self.m_guoChangSpine_1:setPosition(worldPos)
    self.m_guoChangSpine_1:setScale(self.m_machineRootScale)
    self:addChild(self.m_guoChangSpine_1, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine_1:setVisible(false)

    -- 大轮盘下边的遮罩
    self.m_bigWheelPanel = util_createAnimation("LuxeVegas_TopPanel.csb")
    self.m_bigWheelPanel:setPosition(worldPos)
    self:addChild(self.m_bigWheelPanel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_bigWheelPanel:setVisible(false)
    -- 大轮盘过场
    self.m_guoChangSpine_2 = util_spineCreate("LuxeVegas_guochang2",true,true)
    self.m_guoChangSpine_2:setPosition(worldPos)
    self.m_guoChangSpine_2:setScale(self.m_machineRootScale)
    self:addChild(self.m_guoChangSpine_2, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine_2:setVisible(false)

    -- free结束过场
    self.m_guoChangSpine_3 = util_spineCreate("LuxeVegas_guochang3_2",true,true)
    self.m_guoChangSpine_3:setPosition(worldPos)
    self.m_guoChangSpine_3:setScale(self.m_machineRootScale)
    self:addChild(self.m_guoChangSpine_3, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine_3:setVisible(false)

    --收集特效层
    self.m_topEffectNode = cc.Node:create()
    self.m_topEffectNode:setPosition(worldPos)
    self.m_topEffectNode:setScale(self.m_machineRootScale)
    self:addChild(self.m_topEffectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    --大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("LuxeVegas_bigwin",true,true)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    -- 角色
    self.m_roleSpine = util_spineCreate("LuxeVegas_juese",true,true)
    self:findChild("Node_juese"):addChild(self.m_roleSpine)
    self:changeColorfulState()

    --触发小轮盘bonus玩法遮罩
    self.m_maskAni = util_createAnimation("LuxeVegas_dark.csb")
    self.m_onceClipNode:addChild(self.m_maskAni, 10000)
    self.m_maskAni:setVisible(false)

    --触发小轮盘bonus全屏压暗
    self.m_maskFullScreenAni = util_createAnimation("LuxeVegas_dark_1.csb")
    self:findChild("Node_quanpingyaan"):addChild(self.m_maskFullScreenAni)
    self.m_maskFullScreenAni:setVisible(false)

    --玩法提示
    self.m_playTipAni = util_createAnimation("LuxeVegas_wanfatishi.csb")
    self:findChild("Node_wanfatishi"):addChild(self.m_playTipAni)
    self.m_playTipAni:setVisible(false)
    self:addClick(self.m_playTipAni:findChild("click_playTip"))

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "LuxeVegas_totalwin.csb")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitTipNode = cc.Node:create()
    self:addChild(self.m_scWaitTipNode)

    self:changeBgAndReelBg(1)
    self:playRoldIdle(0)
end

function CodeGameScreenLuxeVegasMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 4, 0, 1)
    end)
end

function CodeGameScreenLuxeVegasMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenLuxeVegasMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenLuxeVegasMachine:addObservers()
    CodeGameScreenLuxeVegasMachine.super.addObservers(self)
    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        if self.m_bIsBigWin and not self.m_triggerBigWinEffect then
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

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
        else
            bgmType = "base"
        end

        local soundName = "LuxeVegasSounds/music_LuxeVegas_last_win_".. bgmType.."_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenLuxeVegasMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenLuxeVegasMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenLuxeVegasMachine:scaleMainLayer()
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
function CodeGameScreenLuxeVegasMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS or symbolType == self.SYMBOL_SCORE_CHANGE_BONUS then
        return "Socre_LuxeVegas_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
        return "Socre_LuxeVegas_Wheelbonus"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_FREE_1 then
        return "Socre_LuxeVegas_FGbonus3"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_FREE_2 then
        return "Socre_LuxeVegas_FGbonus2"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_FREE_3 then
        return "Socre_LuxeVegas_FGbonus1"
    end
    
    return nil
end

function CodeGameScreenLuxeVegasMachine:initGameUI()
    self:changeShowRow()
    self:updateBetLevel()
    
    local isTriggerBonus = self:isTriggerBonusGame()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and not isTriggerBonus then
        self:showPlayTip()
    end
end

-- 进游戏显示玩法（不操作6s消失）
function CodeGameScreenLuxeVegasMachine:showPlayTip()
    self.m_playTipAni:setVisible(true)
    self.m_playTipAni:runCsbAction("idle", true)
    performWithDelay(self.m_scWaitTipNode, function()
        self:closePlayTip()
    end, 6.0)
end

function CodeGameScreenLuxeVegasMachine:closePlayTip()
    self.m_scWaitTipNode:stopAllActions()
    if self.m_playTipAni:isVisible() and not self.m_clickPlay then
        self.m_clickPlay = true
        gLobalSoundManager:playSound(self.m_publicConfig.Music_PlayRule_Over)
        self.m_playTipAni:runCsbAction("over", false, function()
            self.m_playTipAni:setVisible(false)
        end)
    end
end

--默认按钮监听回调
function CodeGameScreenLuxeVegasMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_playTip" then
        self:closePlayTip()
    end
end

--初始棋盘
function CodeGameScreenLuxeVegasMachine:initGridList()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
                slotNode:runAnim("idleframe3", true)
            end
        end
    end
end

function CodeGameScreenLuxeVegasMachine:changeShowRow(_isFreeStart, _isFreeOver)
    local curHight = self.m_SlotNodeH*self.m_baseShowRow
    if (self:getCurrSpinMode() == FREE_SPIN_MODE or _isFreeStart) and not _isFreeOver then
        curHight = self.m_SlotNodeH*self.m_freeShowRow
        self:changeBgAndReelBg(2)
    else
        self:changeBgAndReelBg(1)
    end
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = rect.y,
            width = rect.width,
            height = curHight
        }
    )

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize(curHight)
    end
end

function CodeGameScreenLuxeVegasMachine:changeTouchSpinLayerSize(curHight)
    if self.m_SlotNodeH then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, curHight))
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenLuxeVegasMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenLuxeVegasMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

---
--设置bonus scatter 层级
function CodeGameScreenLuxeVegasMachine:getBounsScatterDataZorder(symbolType, iCol, iRow)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:curSymbolIsFreeBonus(symbolType) or symbolType == self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    --右压左、下压上
    if (iCol and iRow) then
        order = order + iCol * 100 - iRow
    end
    return order
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenLuxeVegasMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if self.m_runSpinResultData and self.m_runSpinResultData.p_fsExtraData then
            local freeMaxMultiple = self.m_runSpinResultData.p_fsExtraData.freeMaxMultiple
            if freeMaxMultiple then
                self.m_gamePlayMul = freeMaxMultiple
            end
        end
        self.m_freeTitleBar:showFreeTitleMul(self.m_gamePlayMul)
    end
end

function CodeGameScreenLuxeVegasMachine:initGameStatusData(gameData)
    local featureData = gameData.feature
    local spinData = gameData.spin
    if featureData and spinData then
        if featureData.selfData and spinData.selfData then
            spinData.selfData = featureData.selfData
        end
        if featureData.freespin and spinData.freespin then
            spinData.freespin = featureData.freespin
        end
        if featureData.features and spinData.features then
            spinData.features = featureData.features
        end
    end
    CodeGameScreenLuxeVegasMachine.super.initGameStatusData(self,gameData)
    if self.m_initFeatureData then
        if self.m_initFeatureData.p_status == "CLOSED" then
            self.m_initFeatureData = nil
        end
    end

    -- 获取bet和free初始数据
    if gameData.gameConfig and gameData.gameConfig.extra then
        self.m_bonusInitMul = gameData.gameConfig.extra.bonusInitMultiples or {}
        self.m_freeInitCount = gameData.gameConfig.extra.freeInitCount or {}
        self.m_collectBgMul = gameData.gameConfig.extra.backgroundMultiple or {}
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLuxeVegasMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenLuxeVegasMachine:beginReel()
    self.m_triggerBigWinEffect = false
    self.m_isTriggerBonusTbl = {}
    self.m_isBonusPlay = false
    self.m_isRemoveWheelSymbol = false
    for i = 1, self.m_iReelColumnNum do
        self:changeMaskVisible(true, i, true)
        self.m_panelUpList[i]:setVisible(true)
        self:playMaskFadeAction(true, 0.2, i, function()
            self:changeMaskVisible(true, i)
        end)
    end
    self:closePlayTip()
    
    CodeGameScreenLuxeVegasMachine.super.beginReel(self)

    self:setBonusAndNodeScoreIdle()
    self.m_isRemoveWheelSymbol = true
end

-- spin前把bonus和bonus上的字体透明度设置亮
function CodeGameScreenLuxeVegasMachine:setBonusAndNodeScoreIdle()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                slotNode:runAnim("idleframe_dark", true)
                if slotNode.p_symbolImage then
                    slotNode.p_symbolImage:setVisible(false)
                end
            end
        end
    end
end

--
--单列滚动停止回调
-- 每个reel条滚动到底
function CodeGameScreenLuxeVegasMachine:slotOneReelDown(reelCol)
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

    self:playMaskFadeAction(false, 0.2, reelCol, function()
        self:changeMaskVisible(false, reelCol)
    end)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
    return isTriggerLongRun
end

function CodeGameScreenLuxeVegasMachine:setReelLongRun(reelCol)
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
function CodeGameScreenLuxeVegasMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenLuxeVegasMachine.super.slotReelDown(self)
end

---------------------------------------------------------------------------

--[[
    检测添加大赢光效
]]
function CodeGameScreenLuxeVegasMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
        self.m_triggerBigWinEffect = true
    end
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLuxeVegasMachine:addSelfEffect()
    self.m_isBonusPlay = false
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    local bonusWheelShow = self.m_runSpinResultData.p_selfMakeData.bonusWheelShow
    local bonusWheelResult = self.m_runSpinResultData.p_selfMakeData.bonusWheelResult

    -- 收集列金币玩法
    if self:getCurReelIsHaveBonus() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_COINS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_COINS_EFFECT -- 动画类型
    end

    -- 收集free次数玩法
    if self:getCurIsHaveFreeCount() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_FREE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_FREE_EFFECT -- 动画类型
    end

    -- 小转盘玩法
    if bonusWheelShow and bonusWheelResult then
        self.m_isBonusPlay = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_WHEEL_EFFECT -- 动画类型

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_RELOAD_EFFECT -- 动画类型
    end

    -- free最后一次重新赋值
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_selfMakeData.frees then
        local frees = self.m_runSpinResultData.p_selfMakeData.frees
        local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        if frees and betCoin and frees[tostring(toLongNumber(betCoin))] then
            local curFreeCountData = frees[tostring(toLongNumber(betCoin))]
            -- 刷新free次数
            self.m_collectDiamondView:setFreeCountData(curFreeCountData, true)
        end
    end
    
    -- 触发大轮盘scatter当线处理
    local wheelTriggerMultiple = self.m_runSpinResultData.p_selfMakeData.wheelTriggerMultiple
    if wheelTriggerMultiple then
        self:addScatterPlayLine(wheelTriggerMultiple)
    end
end

function CodeGameScreenLuxeVegasMachine:addScatterPlayLine(_wheelTriggerMultiple)
    local wheelTriggerMultiple = _wheelTriggerMultiple
    local winLines = self.m_runSpinResultData.p_winLines
    local scatterPosData = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local pos = self:getPosReelIdx(iRow, iCol)
            if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                table.insert(scatterPosData, pos)
            end
        end
    end
    local curBet = globalData.slotRunData:getCurTotalBet()
    local rewardCoins = wheelTriggerMultiple * curBet
    local winLineData = self.m_runSpinResultData:getWinLineDataWithPool({})
    winLineData.p_id = self.m_falseLineIdx
    winLineData.p_amount = rewardCoins
    winLineData.p_iconPos = scatterPosData
    winLineData.p_type = 1
    winLineData.p_multiple = 0
    winLines[#winLines + 1] = winLineData

    -- 处理连线数据
    local lineInfo = self:getReelLineInfo()
    local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, scatterPosData)

    lineInfo.enumSymbolType = enumSymbolType
    lineInfo.iLineIdx = self.m_falseLineIdx
    lineInfo.iLineSymbolNum = #scatterPosData
    lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
    self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLuxeVegasMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BONUS_COINS_EFFECT then
        self:collectBonusCoins(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_FREE_EFFECT then
        self:collectBonusFreeCount(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_WHEEL_EFFECT then
        local bonusWheelShow = self.m_runSpinResultData.p_selfMakeData.bonusWheelShow
        local bonusWheelResult = self.m_runSpinResultData.p_selfMakeData.bonusWheelResult
        local oldCollectCoins = self.m_runSpinResultData.p_selfMakeData.oldCollectCoins
        self:showBonusWheelPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0, bonusWheelShow, bonusWheelResult, oldCollectCoins)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_RELOAD_EFFECT then
        self:showBonusWheelReloadPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

-- bonus玩法
function CodeGameScreenLuxeVegasMachine:collectBonusCoins(_callFunc)
    local callFunc = _callFunc
    self.m_effectNode:removeAllChildren()
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons
    local oldCollectCoins = self.m_runSpinResultData.p_selfMakeData.oldCollectCoins

    local delayTime = 0
    local refreshCol = {}
    local isPlaySound = true
    for k, colData in pairs(storedIcons) do
        if next(colData) then
            if isPlaySound then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_CollectFeedBack)
                isPlaySound = false
            end
            refreshCol[k] = true
            for j, bonusData in pairs(colData) do
                local pos = bonusData[1]
                if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                    pos = pos + self:getCurSpinModeSymbolNodeIndex()
                end
                local fixPos = self:getRowAndColByPos(pos)
                local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                if symbolNode then
                    symbolNode:runAnim("idleframe_dark", true)
                    local nodeScore = symbolNode:getChildByName("bonus_tag")
                    if nodeScore then
                        nodeScore:runCsbAction("idleframe_dark", true)
                    end
                end

                local startPos = self:getWorldToNodePos(self.m_effectNode, pos)

                -- 假的信号飞行
                local flyNode = self:createLuxeVegasSymbol(self.SYMBOL_SCORE_BONUS)
                flyNode:runAnim("shouji", false)
                flyNode:setPosition(startPos)
                self.m_effectNode:addChild(flyNode)
                
                local endNode = self.m_collectView:getCollectNode(k)
                local endPos = util_convertToNodeSpace(endNode, self.m_effectNode)

                local tblActionList = {}
                delayTime = 10/30
                tblActionList[#tblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
                tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                    flyNode:setVisible(false)
                end)
                flyNode:runAction(cc.Sequence:create(tblActionList))
            end
        end
    end
    
    local oldCollectCoins = self.m_runSpinResultData.p_selfMakeData.oldCollectCoins
    local bets = self.m_runSpinResultData.p_selfMakeData.bets
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    performWithDelay(self.m_scWaitNode, function()
        local curCollectData = {}
        if oldCollectCoins then
            curCollectData = oldCollectCoins
        else
            if bets and betCoin and bets[tostring(toLongNumber(betCoin))] then
                curCollectData = bets[tostring(toLongNumber(betCoin))]
            end
        end

        if next(curCollectData) then
            -- 刷新收集
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Trigger)
            self.m_collectView:refreshCollectCoins(curCollectData, refreshCol)
        end
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

-- 收集free次数玩法
function CodeGameScreenLuxeVegasMachine:collectBonusFreeCount(_callFunc)
    local callFunc = _callFunc
    self.m_effectNode:removeAllChildren()
    local freeAddCount = self.m_runSpinResultData.p_selfMakeData.freeAddCount or {}
    local frees = self.m_runSpinResultData.p_selfMakeData.frees
    local isTriggerBonus = self:isTriggerBonusGame()
    local curFreeCountData = nil
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    if frees and betCoin and frees[tostring(toLongNumber(betCoin))] then
        curFreeCountData = frees[tostring(toLongNumber(betCoin))]
    end

    if curFreeCountData then
        -- 刷新free次数
        self.m_collectDiamondView:setFreeCountData(curFreeCountData)
    end

    local delayTime = 0
    local refreshCol = {}
    local freeType = 1
    local tblActionList = {}
    for i=1, #freeAddCount do
        local freeCount = freeAddCount[i]
        if freeCount > 0 then
            local oneActionList = {}
            delayTime = 20/30
            freeType = i
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(self.m_iReelColumnNum, iRow, SYMBOL_NODE_TAG)
                if slotNode and self:curSymbolIsFreeBonus(slotNode.p_symbolType) then
                    local collectType = 3-i+1
                    local curRow = 3-iRow+1
                    local collectName = "shouji"..collectType.."_"..curRow
                    local collectSpine = util_spineCreate("LuxeVegas_Bonus_shouji",true,true)
                    self.m_effectNode:addChild(collectSpine)
                    oneActionList[#oneActionList + 1] = cc.CallFunc:create(function()
                        slotNode:runAnim("actionframe", false, function()
                            slotNode:runAnim("idleframe", true)
                        end)
                    end)
                    oneActionList[#oneActionList+1] = cc.DelayTime:create(10/30)
                    oneActionList[#oneActionList + 1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_FgBonus_Fly)
                        util_spinePlay(collectSpine, collectName, false)
                        util_spineEndCallFunc(collectSpine, collectName, function()
                            gLobalSoundManager:playSound(self.m_publicConfig.Music_FgBonus_FeedBack)
                            collectSpine:setVisible(false)
                        end)
                    end)
                end
            end
            if #oneActionList > 0 then
                local seq = cc.Sequence:create(oneActionList)
                self.m_scWaitNode:runAction(seq)
            end
        end
    end
    local tblActionList = {}
    -- 20帧后播反馈
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        if not isTriggerBonus then
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self.m_collectDiamondView:playTriggerAct(freeType)
    end)
    -- 15帧后切数字
    tblActionList[#tblActionList+1] = cc.DelayTime:create(15/60)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        if curFreeCountData then
            -- 刷新free次数
            self.m_collectDiamondView:refreshFreeCount(curFreeCountData)
        end
    end)
    -- 5帧后回调
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/60)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        if isTriggerBonus then
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    end)
    
    local seq = cc.Sequence:create(tblActionList)
    self.m_scWaitNode:runAction(seq)
end

function CodeGameScreenLuxeVegasMachine:isTriggerBonusGame()
    local featureDatas = self.m_runSpinResultData.p_features or {}

    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        return true
    end
    return false
end

-- bonus长条；小转盘玩法
function CodeGameScreenLuxeVegasMachine:showBonusWheelPlay(_callFunc, _index, _wheelConfig, _wheelResult, _oldCollectCoins)
    -- 清除连线
    self:clearWinLineEffect()
    self.m_topEffectNode:removeAllChildren()
    if _index == 0 then
        self:setMaxMusicBGVolume()
        self:showMask(true)
        self:changeDiamondParentNode(false)
        self:changeSymbolParentNode(false)
    end
    local callFunc = _callFunc
    local index = _index + 1
    local wheelConfig = _wheelConfig
    local wheelResult = _wheelResult
    local oldCollectCoins = _oldCollectCoins
    if index > #wheelResult then
        self:showMask(false)
        if not self:checkHasBigWin() then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end

        local params = {self.m_runSpinResultData.p_winAmount,true, true, self.m_runSpinResultData.p_winAmount}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    -- 音效index
    if not self.m_wheelSoundIndex or self.m_wheelSoundIndex >= 2 then
        self.m_wheelSoundIndex = 1
    else
        self.m_wheelSoundIndex = self.m_wheelSoundIndex + 1
    end

    local curResult = wheelResult[index]
    local curCol = curResult[1] + 1
    local curMul = curResult[2]
    local curCoins = curResult[3]

    -- 200以下倍数；200-300收集列的倍数；300以上pick玩法+本列倍数
    local curColMul = 0
    -- 收集类型；1：本列收集；2：awardAll；3：本列乘倍收集+awardAll；4：pick+本列收集
    local collectType = 1
    -- 小转盘
    local wheelNode = nil
    
    if curMul < 200 then
        curColMul = curMul
        collectType = 1
    elseif curMul > 200 and curMul == 201 then
        curColMul = curMul-200
        collectType = 2
    elseif curMul > 201 and curMul < 300 then
        curColMul = curMul-200
        collectType = 3
    else
        curColMul = curMul-300
        collectType = 4
    end

    for iRow = 1, self.m_iReelRowNum do
        local slotNode = self:getFixSymbol(curCol, iRow, SYMBOL_NODE_TAG)

        if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
            local soundName = self.m_publicConfig.Music_WheelBonus_Trigger[self.m_wheelSoundIndex]
            if soundName then
                gLobalSoundManager:playSound(soundName)
            end
            slotNode:runAnim("actionframe", false)
            local collectName = "shouji3"
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                collectName = "shouji"..iRow
            end
            local collectSpine = util_spineCreate("LuxeVegas_BonusWheel_shouji",true,true)
            local offsetPosX = (curCol-3)*self.m_SlotNodeW
            local offsetPosY = (iRow-1)*self.m_SlotNodeH
            collectSpine:setPosition(cc.p(offsetPosX, offsetPosY))
            self.m_topEffectNode:addChild(collectSpine)
            collectSpine:setVisible(false)

            -- 收集到底栏
            local endCallFunc = function()
                local collectCoinsTbl = {}
                local totalCol = 1
                local triggerDelayTime = 0
                if collectType == 1 then
                    totalCol = 1
                elseif collectType == 2 then
                    totalCol = 5
                elseif collectType == 3 then
                    totalCol = 5
                else
                    totalCol = 1
                end
                
                for i = 1, totalCol do
                    local oneActionList = {}
                    local delayTime = 0.2
                    local countDelayTime = (i-1)*(delayTime+0.1)+0.4

                    local flyNode = util_createAnimation("LuxeVegas_jindutiao.csb")
                    local particleTbl = {}
                    for i=1, 2 do
                        particleTbl[i] = flyNode:findChild("Particle_"..i)
                        particleTbl[i]:setPositionType(0)
                        particleTbl[i]:setDuration(-1)
                        particleTbl[i]:resetSystem()
                    end
                    local startNode = self.m_collectView:getCollectNode(i)
                    if totalCol == 1 then
                        collectCoinsTbl[curCol] = self.m_collectView:getCurColCoins(curCol)
                        startNode = self.m_collectView:getCollectNode(curCol)
                    else
                        collectCoinsTbl[i] = self.m_collectView:getCurColCoins(i)
                    end
                    flyNode:setVisible(false)

                    local startPos = util_convertToNodeSpace(startNode, self.m_topEffectNode)
                    local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self.m_topEffectNode)
                    flyNode:setPosition(startPos)
                    self.m_topEffectNode:addChild(flyNode)
                    -- 下一个延时时间
                    oneActionList[#oneActionList+1] = cc.DelayTime:create(countDelayTime)
                    oneActionList[#oneActionList + 1] = cc.CallFunc:create(function()
                        flyNode:setVisible(true)
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Coins_CollectFeeack)
                        if totalCol == 1 then
                            -- self.m_collectView:playItemIdle(curCol)
                            self.m_collectView:collectBottomCoins(curCol)
                        else
                            -- self.m_collectView:playItemIdle(i)
                            self.m_collectView:collectBottomCoins(i)
                        end
                    end)
                    oneActionList[#oneActionList+1] = cc.MoveTo:create(delayTime, endPos)
                    oneActionList[#oneActionList + 1] = cc.CallFunc:create(function()
                        for i=1, 2 do
                            particleTbl[i]:stopSystem()
                        end
                        -- flyNode:setVisible(false)
                        if totalCol == 1 then
                            self:playhBottomLight(collectCoinsTbl[curCol])
                        else
                            self:playhBottomLight(collectCoinsTbl[i])
                        end
                    end)
                    if i == totalCol then
                        oneActionList[#oneActionList+1] = cc.DelayTime:create(0.5)
                    end
                    oneActionList[#oneActionList + 1] = cc.CallFunc:create(function()
                        if i == totalCol then
                            if collectType == 4 then
                                self:showColorfulGameView(wheelNode, function()
                                    self:showBonusWheelPlay(callFunc, index, wheelConfig, wheelResult, oldCollectCoins)
                                end)
                            else
                                wheelNode:setFadeOutAct()
                                self:showBonusWheelPlay(callFunc, index, wheelConfig, wheelResult, oldCollectCoins)
                            end
                        end
                    end)
                    oneActionList[#oneActionList+1] = cc.DelayTime:create(0.5)
                    oneActionList[#oneActionList + 1] = cc.CallFunc:create(function()
                        if not tolua.isnull(flyNode) then
                            flyNode:setVisible(false)
                        end
                    end)
                    local seq = cc.Sequence:create(oneActionList)
                    flyNode:runAction(seq)
                end
            end
            -- endCallFunc()
            -- 收集到上边栏
            local collectCallFunc = function()
                -- 收集和多福多彩jackpot类型直接收集
                if collectType == 1 or collectType == 4 then
                    local tblActionList = {}
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        collectSpine:setVisible(true)
                        util_spinePlay(collectSpine, collectName, true)
                    end)
                    -- 15帧切
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(15/30)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        collectSpine:setVisible(false)
                        self.m_collectView:refreshCoinsByWheel(curCol, curColMul, endCallFunc)
                    end)
                    local seq = cc.Sequence:create(tblActionList)
                    self.m_scWaitNode:runAction(seq)
                -- awardAll类型；播触发再收集
                elseif collectType == 2 then
                    local tblActionList = {}
                    -- 小轮盘特殊光效
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        wheelNode:startSpecialLight()
                    end)
                    -- 延时0.5
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Trigger)
                        self.m_collectView:playTrigger()
                    end)
                    -- 65/60帧切
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(65/60)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        endCallFunc()
                    end)
                    local seq = cc.Sequence:create(tblActionList)
                    self.m_scWaitNode:runAction(seq)
                -- awardAll类型+本列乘倍；先乘倍，收集本列，再触发，再收集所有列
                elseif collectType == 3 then
                    local delayTime = 0.2
                    local tblActionList = {}
                    local flyNode = util_createAnimation("LuxeVegas_jindutiao.csb")
                    local particleTbl = {}
                    for i=1, 2 do
                        particleTbl[i] = flyNode:findChild("Particle_"..i)
                        particleTbl[i]:setPositionType(0)
                        particleTbl[i]:setDuration(-1)
                        particleTbl[i]:resetSystem()
                    end
                    local startNode = self.m_collectView:getCollectNode(curCol)
                    flyNode:setVisible(false)
                    local startPos = util_convertToNodeSpace(startNode, self.m_topEffectNode)
                    local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self.m_topEffectNode)
                    flyNode:setPosition(startPos)
                    self.m_topEffectNode:addChild(flyNode)
                    -- 先向上收集
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        collectSpine:setVisible(true)
                        util_spinePlay(collectSpine, collectName, true)
                    end)
                    -- 15帧切
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(15/30)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        collectSpine:setVisible(false)
                        self.m_collectView:refreshCoinsByWheel(curCol, curColMul)
                    end)
                    -- 延时1s开始收集
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(60/60+1.2)
                    -- 收集本列
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        flyNode:setVisible(true)
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Coins_CollectFeeack)
                        self.m_collectView:playItemIdle(curCol)
                        self.m_collectView:collectBottomCoins(curCol)
                    end)
                    tblActionList[#tblActionList+1] = cc.MoveTo:create(delayTime, endPos)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        for i=1, 2 do
                            particleTbl[i]:stopSystem()
                        end
                        -- flyNode:setVisible(false)
                        local curColCoins = self.m_collectView:getCurColCoins(curCol)
                        self:playhBottomLight(curColCoins)
                    end)
                    -- 底部收集时间0.5
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
                    -- 小轮盘特殊光效
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        wheelNode:startSpecialLight()
                    end)
                    -- 延时1s
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(1.0)
                    -- 播触发动画
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        if not tolua.isnull(flyNode) then
                            flyNode:setVisible(false)
                        end
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Trigger)
                        self.m_collectView:playTrigger()
                    end)
                    -- 65/60帧切
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(65/60)
                    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                        endCallFunc()
                    end)
                    local seq = cc.Sequence:create(tblActionList)
                    flyNode:runAction(seq)
                end
            end
            
            local symbol_node = slotNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            local reel = util_createView("CodeLuxeVegasSrc.LuxeVegasSmallWheelView",{machine = self, _wheelConfig = wheelConfig, _wheelResult = curResult, _endCallFunc = collectCallFunc})
            util_spinePushBindNode(spineNode,"guadian",reel)
            spineNode.m_wheel = reel
            wheelNode = reel

            -- actionframe播放45帧后播放小转盘
            performWithDelay(self.m_scWaitNode, function()
                wheelNode:playStartWheel()
            end, 45/30)
        end
    end
end

-- 多福多彩
function CodeGameScreenLuxeVegasMachine:showColorfulGameView(_wheelNode, _callFunc)
    local wheelNode = _wheelNode
    local callFunc = _callFunc
    local delayTime = 1.0
    if not tolua.isnull(wheelNode) then
        wheelNode:startSpecialLight()
    end
    if not self.m_runSpinResultData.p_selfMakeData or not self.m_runSpinResultData.p_selfMakeData.pickData then
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end
    
    -- 播放震动
    self:levelDeviceVibrate(6, "pickFeature")
    -- 清除连线
    self:clearWinLineEffect()
    local endCallFunc = function()
        self:showColorfulCutScene(function()
            self:resetMusicBg()
            --恢复base界面
            self:changeColorfulState()
            self:showJackpotType()
            self:findChild("Node_sp_reel"):setVisible(true)
            self.m_colorfulGameView:hideSelf()
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:changeBgAndReelBg(2)
            else
                self:changeBgAndReelBg(1)
            end
        end, callFunc)
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local pickData = self.m_runSpinResultData.p_selfMakeData.pickData or {}
    local pickConfig = clone(pickData.process)
    local rewardType = clone(pickData.winJackpot)
    local winValue = clone(pickData.winValue)
    
    local bonusData = {
        rewardList = pickConfig,     --奖励列表
        winJackpot = rewardType,  --获得的jackpot
        winCoins = winValue,      --赢的钱
    }
    
    performWithDelay(self.m_scWaitNode, function()
        self:resetMusicBg(nil, self.m_publicConfig.Music_Pick_Bg)
        self:showColorfulCutScene(function()
            if not tolua.isnull(wheelNode) then
                wheelNode:setFadeOutAct()
            end
            --重置bonus界面
            self:findChild("Node_sp_reel"):setVisible(false)
            self:changeColorfulState(true)
            self:showJackpotType(true)
            self:changeBgAndReelBg(3)
            self.m_colorfulGameView:refreshData(bonusData, endCallFunc)
        end)
    end, delayTime)
end

-- 小转盘玩法结束后；刷新收集钱数动画
function CodeGameScreenLuxeVegasMachine:showBonusWheelReloadPlay(_callFunc)
    local callFunc = _callFunc
    local curCollectData = {}
    local isUseBet = false
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bets then
        local bets = self.m_runSpinResultData.p_selfMakeData.bets
        if bets and betCoin and bets[tostring(toLongNumber(betCoin))] then
            isUseBet = true
            curCollectData = bets[tostring(toLongNumber(betCoin))]
        end
    end

    -- 没有对应bet；用默认值
    if not isUseBet then
        local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        if self.m_bonusInitMul and #self.m_bonusInitMul > 0 then
            for i=1, #self.m_bonusInitMul do
                curCollectData[i] = betCoin*self.m_bonusInitMul[i]
            end
        end
    end
    
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Reload)
    -- reload动画刷新
    self.m_collectView:playReload()
    local tblActionList = {}
    -- 12, 15, 20, 25, 29
    local frameTbl = {12, 3, 5, 5, 4}
    for i=1, 5 do
        tblActionList[#tblActionList+1] = cc.DelayTime:create(frameTbl[i]/60)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_collectView:reloadRefreshCollectCoins(i, curCollectData[i])
            if i == 5 then
                if type(callFunc) == "function" then
                    callFunc()
                end
            end
        end)
    end
    local seq = cc.Sequence:create(tblActionList)
    self.m_scWaitNode:runAction(seq)
end

-- 触发小轮盘时，把钻石放下下边节点(结束再放上边)
function CodeGameScreenLuxeVegasMachine:changeDiamondParentNode(_onTop)
    local onTop = _onTop
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if onTop then
            util_changeNodeParent(self.m_fgDiamondNodeTop, self.m_collectDiamondView)
        else
            util_changeNodeParent(self.m_fgDiamondNodeBottom, self.m_collectDiamondView)
        end
    end
end

-- 当前信号是否在bigSlotParent上
function CodeGameScreenLuxeVegasMachine:getCurSymbolTypeIsBigSlotParent(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS or self:curSymbolIsFreeBonus(_slotNode.p_symbolType) then
        return true
    elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_WHEEL_BONUS and next(self.m_isTriggerBonusTbl) and not self.m_isTriggerBonusTbl[_slotNode.p_cloumnIndex] then
        return true
    end
    return false
end

-- 触发bonus玩法时；把特殊信号层级放在slotParent上
function CodeGameScreenLuxeVegasMachine:changeSymbolParentNode(_onTop)
    local onTop = _onTop
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = -1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and self:getCurSymbolTypeIsBigSlotParent(slotNode) then
                if onTop then
                    self:putSymbolBackToPreParent(slotNode, true)
                else
                    self:putSymbolBackToPreParent(slotNode, false)
                end
            end
        end
    end
end

--[[
    将小块放回原父节点
]]
function CodeGameScreenLuxeVegasMachine:putSymbolBackToPreParent(symbolNode, isInTop)
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

-- 显示遮罩
function CodeGameScreenLuxeVegasMachine:showMask(_showState)
    local showState = _showState
    
    if showState then
        if not self.m_maskAni:isVisible() then
            self.m_maskFullScreenAni:setVisible(true)
            self.m_maskFullScreenAni:runCsbAction("start", false, function()
                self.m_maskFullScreenAni:runCsbAction("idle", true)
            end)
            self.m_maskAni:setVisible(true)
            self.m_maskAni:runCsbAction("start", false, function()
                self.m_maskAni:runCsbAction("idle", true)
            end)
        end
    else
        if self.m_maskAni:isVisible() then
            self:changeSymbolParentNode(true)
            self:changeDiamondParentNode(true)
            self.m_maskAni:runCsbAction("over", false, function()
                self.m_maskAni:setVisible(false)
            end)
            self.m_maskFullScreenAni:runCsbAction("over", false, function()
                self.m_maskFullScreenAni:setVisible(false)
            end)
        end
    end
end

-- freeStart过场
function CodeGameScreenLuxeVegasMachine:showFreeStartCutScene(_callFunc)
    local callFunc = _callFunc
    self.m_guoChangSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Fg_CutScene)
    util_spinePlay(self.m_guoChangSpine, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_guoChangSpine ,"actionframe_guochang",function ()
        self.m_guoChangSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    -- 86帧切
    performWithDelay(self.m_scWaitNode, function()
        --显示base轮盘
        if not tolua.isnull(self.m_wheelReel) then
            self.m_wheelReel:removeFromParent()
            self:setBaseReelShow(true)
        end
        self:changeShowRow(true)
        self.m_freeTitleBar:showFreeTitleMul(self.m_gamePlayMul)
    end, 86/30)
end

-- free结束过场
function CodeGameScreenLuxeVegasMachine:showFreeOverCutScene(_callFunc)
    local callFunc = _callFunc
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Base_CutScene)
    self.m_guoChangSpine_3:setVisible(true)
    util_spinePlay(self.m_guoChangSpine_3, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_guoChangSpine_3 ,"actionframe_guochang",function ()
        self.m_guoChangSpine_3:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    -- 50帧切
    performWithDelay(self.m_scWaitNode, function()
        self:changeShowRow(nil, true)
        -- 如果有大信号并且已经提层；放回卷轴
        self:changeParentNode()
    end, 50/30)
end

-- 多福多彩过场动画
function CodeGameScreenLuxeVegasMachine:showColorfulCutScene(_callFunc, _overFunc)
    local callFunc = _callFunc
    local overFunc = _overFunc
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Colorful_CutScene)
    self.m_guoChangSpine_1:setVisible(true)
    util_spinePlay(self.m_guoChangSpine_1, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_guoChangSpine_1 ,"actionframe_guochang",function ()
        self.m_guoChangSpine_1:setVisible(false)
        if overFunc and type(overFunc) == "function" then
            overFunc()
        end
    end)
    -- 20帧切
    performWithDelay(self.m_scWaitNode, function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, 20/30)
end

-- 大轮盘过场
function CodeGameScreenLuxeVegasMachine:showWheelCutScene(_isWheelStart, _callFunc, _endCallFunc)
    local isWheelStart = _isWheelStart
    local callFunc = _callFunc
    local endCallFunc = _endCallFunc
    local actName = "actionframe_guochang"
    local delayTime = 20/30
    if not isWheelStart then
        actName = "actionframe_guochang2"
    end
    self.m_guoChangSpine_2:setVisible(true)
    self.m_bigWheelPanel:setVisible(true)
    util_spinePlay(self.m_guoChangSpine_2, actName, false)
    util_spineEndCallFunc(self.m_guoChangSpine_2, actName, function ()
        self.m_bigWheelPanel:setVisible(false)
        self.m_guoChangSpine_2:setVisible(false)
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end)
    -- delayTime
    performWithDelay(self.m_scWaitNode, function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenLuxeVegasMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local randomNum = math.random(1, 10)
    if randomNum <= 3 then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Incredible_Sound)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, "actionframe", false)
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

-- 根据index转换需要节点坐标系
function CodeGameScreenLuxeVegasMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

-- 获取轮盘是否有bonus
function CodeGameScreenLuxeVegasMachine:getCurReelIsHaveBonus()
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons
    for k, v in pairs(storedIcons) do
        if #v > 0 then
            return true
        end
    end
    return false
end

-- 获取轮盘上是否有增加的free次数
function CodeGameScreenLuxeVegasMachine:getCurIsHaveFreeCount()
    local freeAddCount = self.m_runSpinResultData.p_selfMakeData.freeAddCount or {}
    for k, v in pairs(freeAddCount) do
        if v > 0 then
            return true
        end
    end
    return false
end

-- 当前是否为freeBonus
function CodeGameScreenLuxeVegasMachine:curSymbolIsFreeBonus(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_BONUS_FREE_1 or _symbolType == self.SYMBOL_SCORE_BONUS_FREE_2 or _symbolType == self.SYMBOL_SCORE_BONUS_FREE_3 then
        return true
    end
    return false
end

function CodeGameScreenLuxeVegasMachine:createLuxeVegasSymbol(_symbolType)
    local symbol = util_createView("CodeLuxeVegasSrc.LuxeVegasSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenLuxeVegasMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenLuxeVegasMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenLuxeVegasMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
    end
end

-- 不用系统音效
function CodeGameScreenLuxeVegasMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenLuxeVegasMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
-- 因为添加了两行假数据；所以连线数据需要加两行
function CodeGameScreenLuxeVegasMachine:lineLogicWinLines()
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        self:compareScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                for i=1, #iconsPos do
                    iconsPos[i] = iconsPos[i] + self:getCurSpinModeSymbolNodeIndex()
                end
            end

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, iconsPos)

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
                isFiveOfKind = true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end
    end

    return isFiveOfKind
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenLuxeVegasMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeLuxeVegasSrc.LuxeVegasFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_FGbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenLuxeVegasMachine:showFreeSpinView(effectData)

    local showFSView = function ()
        local cutSceneFunc = function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
            end, 5/60)
        end
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startStart)
        local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            self:showFreeStartCutScene(function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
        view:findChild("sp_mul_10"):setVisible(self.m_gamePlayMul == self.M_ENUM_TYPE.FREE_1)
        view:findChild("sp_mul_25"):setVisible(self.m_gamePlayMul == self.M_ENUM_TYPE.FREE_2)
        view:findChild("sp_mul_50"):setVisible(self.m_gamePlayMul == self.M_ENUM_TYPE.FREE_3)
        view:findChild("root"):setScale(self.m_machineRootScale)
        view:setBtnClickFunc(cutSceneFunc)
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenLuxeVegasMachine:showFreeSpinOverView(effectData)
    self.m_gamePlayMul = 1
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 3, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
        end, 5/60)
    end
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
        self:clearWinLineEffect()
        self:showFreeOverCutScene(function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.0,sy=1.0},629)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(cutSceneFunc)
end

function CodeGameScreenLuxeVegasMachine:changeParentNode()
    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if childs[i].resetReelStatus ~= nil then
            childs[i]:resetReelStatus()
        end
        if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            if childs[i].p_symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
                self.m_isRemoveWheelSymbol = false
            end
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            if not childs[i].p_showOrder then
                childs[i].p_showOrder = self:getBounsScatterDataZorder(childs[i].p_symbolType)
            end
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            self:changeBaseParent(childs[i])
            childs[i]:resetReelStatus()
            childs[i]:setPosition(pos)
        end
    end
end

function CodeGameScreenLuxeVegasMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    local waitTime = 0
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenLuxeVegasMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeLuxeVegasSrc.LuxeVegasJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_Jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点

    --jackpot
    self.m_jackpotColorBar = util_createView("CodeLuxeVegasSrc.LuxeVegasColofulJackPotBar",{machine = self.m_machine})
    self.m_jackpotColorBar:initMachine(self)
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotColorBar)
end

function CodeGameScreenLuxeVegasMachine:showJackpotType(_isColor)
    if _isColor then
        self.m_jackpotColorBar:setVisible(true)
        self.m_jackPotBarView:setVisible(false)
    else
        self.m_jackpotColorBar:setVisible(false)
        self.m_jackPotBarView:setVisible(true)
    end
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenLuxeVegasMachine:showJackpotView(coins,jackpotType,func)
    if not self:checkHasBigWin() then
        --检测大赢
        self:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS)
    end
    self:playhBottomLight(coins)
    local view = util_createView("CodeLuxeVegasSrc.LuxeVegasJackpotWinView",{
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

function CodeGameScreenLuxeVegasMachine:symbolBulingEndCallBack(_slotNode)
    local curLongRunData = self.m_longRunControl:getCurLongRunData() or {}
    local LegitimatePos = curLongRunData.LegitimatePos or {}
    if table_length(LegitimatePos) > 0  then
        for i=1,#LegitimatePos do
            local posInfo = LegitimatePos[i]
            if table_vIn(posInfo,_slotNode.p_symbolType) and
                table_vIn(posInfo,_slotNode.p_cloumnIndex) and 
                table_vIn(posInfo,_slotNode.p_rowIndex)  then
                self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 
                return true
            end
        end
    end
    return false    
end

function CodeGameScreenLuxeVegasMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenLuxeVegasMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenLuxeVegasMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenLuxeVegasMachine:updateReelGridNode(_symbolNode)
    local nodeScore = _symbolNode:getChildByName("bonus_tag")
    if not tolua.isnull(nodeScore) then
        nodeScore:removeFromParent()
    end
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        local showOrder = self:getBounsScatterDataZorder(_symbolNode.p_symbolType, _symbolNode.p_cloumnIndex, _symbolNode.p_rowIndex)
        _symbolNode.m_showOrder = showOrder
        _symbolNode:setLocalZOrder(showOrder)
        self:setSpecialNodeScoreBonus(_symbolNode)
    elseif _symbolNode.p_symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
        self:removeScoreNode(_symbolNode)
    end
end

function CodeGameScreenLuxeVegasMachine:removeScoreNode(_symbolNode)
    local symbolNode = _symbolNode
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if spineNode and spineNode.m_wheel then
        local nodeWheel = spineNode.m_wheel
        util_spineRemoveBindNode(spineNode, nodeWheel)
    end
end

function CodeGameScreenLuxeVegasMachine:setSpecialNodeScoreBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()

    local nodeScore = util_createAnimation("Socre_LuxeVegas_BonusCoins.csb")
    nodeScore:runCsbAction("idleframe", true)
    symbolNode:addChild(nodeScore, 100)
    nodeScore:setPosition(cc.p(0, 0))
    nodeScore:setName("bonus_tag")

    local sScore = ""
    if symbolNode.m_isLastSymbol == true then
        local mul = self:getReSpinBonusScore(self:getPosReelIdx(iRow, iCol))
        if mul ~= nil and mul ~= 0 then
            local coins = mul * curBet
            sScore = util_formatCoins(coins, 3)
        end
    else
        -- 获取随机分数（本地配置）
        local mul = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        local coins = mul * curBet
        sScore = util_formatCoins(coins, 3)
    end
    nodeScore:findChild("m_lb_coins"):setString(sScore)
end

--[[
    随机bonus分数
]]
function CodeGameScreenLuxeVegasMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_BONUS then
        score = self.m_configData:getBnBasePro()
    end

    return score
end

-- 获取free和base差值（行-index）
function CodeGameScreenLuxeVegasMachine:getCurSpinModeSymbolNodeIndex()
    return (self.m_freeShowRow - self.m_baseShowRow) * self.m_iReelColumnNum
end

--[[
    获取小块真实分数
]]
function CodeGameScreenLuxeVegasMachine:getReSpinBonusScore(id)
    if not self.m_runSpinResultData.p_selfMakeData or not self.m_runSpinResultData.p_selfMakeData.storedIcons then
        return 0
    end
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        id = id - self:getCurSpinModeSymbolNodeIndex()
    end
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons or {}
    local curCol = math.mod(id, self.m_iReelColumnNum) + 1

    local score = 0
    local curColIcons = storedIcons[curCol]
    if curColIcons and #curColIcons > 0 then
        for i=1, #curColIcons do
            local values = curColIcons[i]
            if tonumber(values[1]) == id then
                score = tonumber(values[2])
                break
            end
        end
    end

    return score
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenLuxeVegasMachine:showFeatureGameTip(_func)
    self.m_isTriggerBonusTbl = self:getCurIsHaveBonusWheel()
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

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenLuxeVegasMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
    self.m_guoChangSpine_3:setVisible(true)
    util_spinePlay(self.m_guoChangSpine_3, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_guoChangSpine_3, "actionframe_yugao", function()
        self.m_guoChangSpine_3:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

--[[
        bonus玩法
    ]]
function CodeGameScreenLuxeVegasMachine:showEffect_Bonus(effectData)
    self:clearCurMusicBg()
    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")
    self:clearWinLineEffect()
    local waitTime = 0
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
                    slotNode:runAnim("actionframe")
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end
    self:playScatterTipMusicEffect(true)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isUseFree = false
    local curFreeCountData = {}
    if selfData and selfData.bets then
        local frees = selfData.frees
        local betCoin = globalData.slotRunData:getCurTotalBet() or 0
        if frees and betCoin and frees[tostring(toLongNumber(betCoin))] then
            curFreeCountData = frees[tostring(toLongNumber(betCoin))]
        end
    end

    performWithDelay(self,function(  )
        self:resetMusicBg(nil, self.m_publicConfig.Music_Wheel_Bg)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Open_BigWheel_Door)
        self:showWheelCutScene(true, function()
            self.m_bottomUI:checkClearWinLabel()
            --隐藏base轮盘
            self:setBaseReelShow(false)
            self.m_wheelReel = util_createView("CodeLuxeVegasSrc.LuxeVegasWheelView",{machine = self, _effectData = effectData, _curFreeCountData = curFreeCountData})
            self:findChild("Node_wheel"):addChild(self.m_wheelReel)
            self.m_wheelReel:setPosition(cc.p(-display.width / 2,-display.height / 2))
        end) 
    end,waitTime)
    return true
end

function CodeGameScreenLuxeVegasMachine:bonusGameOver(effectData, callFunc, _rewardType)
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    -- 奖励
    local rewardType = _rewardType
    if not rewardType then
        rewardType = self.m_runSpinResultData.p_selfMakeData.wheelType
    end

    local endCallfunc = function()
        self:resetMusicBg()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_BigWheel_Cut_Scene_Back)
        self:showWheelCutScene(false, function()
            --显示base轮盘
            self:setBaseReelShow(true)
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    local isFreePlay = false
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            isFreePlay = true
            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end

    if isFreePlay then
        if rewardType == "free1" then
            self.m_gamePlayMul = self.M_ENUM_TYPE.FREE_1
        elseif rewardType == "free2" then
            self.m_gamePlayMul = self.M_ENUM_TYPE.FREE_2
        elseif rewardType == "free3" then
            self.m_gamePlayMul = self.M_ENUM_TYPE.FREE_3
        end
        -- 直接进free
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
        local jackpotCoins = allJackpotCoins[rewardType] or 0
        self:showJackpotView(jackpotCoins, rewardType, function()
            endCallfunc()
        end)
    end
end

-- 获取是否有bonusWheel玩法
function CodeGameScreenLuxeVegasMachine:getCurIsHaveBonusWheel()
    local tempTbl = {}
    if not self.m_runSpinResultData.p_selfMakeData then
        return tempTbl
    end
    local bonusWheelShow = self.m_runSpinResultData.p_selfMakeData.bonusWheelShow
    local bonusWheelResult = self.m_runSpinResultData.p_selfMakeData.bonusWheelResult
    if bonusWheelShow and bonusWheelResult then
        for k, v in pairs(bonusWheelResult) do
            local curCol = v[1]+1
            tempTbl[curCol] = true
        end
    end
    return tempTbl
end

function CodeGameScreenLuxeVegasMachine:playhBottomLight(_endCoins)
    self.m_bottomUI:playCoinWinEffectUI()

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenLuxeVegasMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenLuxeVegasMachine:getCurBottomWinCoins()
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

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenLuxeVegasMachine:checkHasGameEffect(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

function CodeGameScreenLuxeVegasMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local lineWinCoins = self:getClientWinCoins()
    local bonusCoins = 0
    if self.m_isTriggerBonusTbl and next(self.m_isTriggerBonusTbl) then
        bonusCoins = self:getCurBonusWinCoins()
    end

    -- self.m_isTriggerBonusTbl
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins-bonusCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount-bonusCoins)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

-- 获取bonus赢钱
function CodeGameScreenLuxeVegasMachine:getCurBonusWinCoins()
    local bonusWheelShow = self.m_runSpinResultData.p_selfMakeData.bonusWheelShow
    local bonusWheelResult = self.m_runSpinResultData.p_selfMakeData.bonusWheelResult
    local bonusCoins = 0
    if bonusWheelShow and bonusWheelResult then
        for k, v in pairs(bonusWheelResult) do
            local curCoins = v[3]
            bonusCoins = bonusCoins + curCoins
        end
    end
    return bonusCoins
end

--[[
    设置base下轮盘显示
]]
function CodeGameScreenLuxeVegasMachine:setBaseReelShow(isShow)
    self:findChild("Node_reel"):setVisible(isShow)
    self.m_roleSpine:setVisible(isShow)
end

-- 播放角色动画
-- 5s呼吸之后切一下大幅度idle，如此循环，按照我帧数算的话，是播四次idle1，然后再播idle2或者idle3
function CodeGameScreenLuxeVegasMachine:playRoldIdle(_count)
    local count = _count + 1
    local idleName = "idle1"
    if count < 5 then
        idleName = "idle1"
    else
        count = 0
        local randomNum = math.random(1, 2)
        if randomNum <= 1 then
            idleName = "idle2"
        else
            idleName = "idle3"
        end
    end
    util_spinePlay(self.m_roleSpine, idleName, false)
    util_spineEndCallFunc(self.m_roleSpine, idleName, function()
        self:playRoldIdle(count)
    end)
end

-- 改变角色位置；base（0，0）；多福多彩（286，76）
function CodeGameScreenLuxeVegasMachine:changeColorfulState(_isColorful)
    if _isColorful then
        self.m_collectView:setColfulState(true)
    else
        self.m_collectView:setColfulState()
    end
end

function CodeGameScreenLuxeVegasMachine:changeBgAndReelBg(_bgType)
    -- 1.base；2.freespin；3.多福多彩
    for i=1, 3 do
        if i == _bgType then
            self.m_spBgTbl[i]:setVisible(true)
        else
            self.m_spBgTbl[i]:setVisible(false)
        end
    end
    if _bgType == 1 then
        self:runCsbAction("base", true)
    elseif _bgType == 2 then
        self:runCsbAction("free", true)
    elseif _bgType == 3 then
        self:runCsbAction("dfdc", true)
    end
end

function CodeGameScreenLuxeVegasMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 and not self.m_isBonusPlay then
        notAdd = true
    end

    return notAdd
end

--[[
    @desc: 遮罩相关
]]
function CodeGameScreenLuxeVegasMachine:createSpinMask(_mainClass)
    --棋盘主类
    local tblMaskList = {}
    local mainClass = _mainClass or self
    
    for i=1, 5 do
        --单列卷轴尺寸
        local reel = mainClass:findChild("sp_reel_"..i-1)
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
        local clipParent = mainClass.m_onceClipNode or mainClass.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(self.m_panelOpacity)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        tblMaskList[i] = panel
    end

    return tblMaskList
end

function CodeGameScreenLuxeVegasMachine:changeMaskVisible(_isVis, _reelCol, _isOpacity)
    if _isOpacity then
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(0)
    else
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(self.m_panelOpacity)
    end
end

function CodeGameScreenLuxeVegasMachine:playMaskFadeAction(_isFadeTo, _fadeTime, _reelCol, _fun)
    local fadeTime = _fadeTime or 0.1
    local opacity = self.m_panelOpacity

    local act_fade = _isFadeTo and cc.FadeTo:create(fadeTime, opacity) or cc.FadeOut:create(fadeTime)
    if not _isFadeTo then
        self.m_panelUpList[_reelCol]:setOpacity(opacity)
    end
    self.m_panelUpList[_reelCol]:setVisible(true)
    self.m_panelUpList[_reelCol]:runAction(act_fade)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function()
        if _fun then
            _fun()
        end
        waitNode:removeFromParent()
    end, fadeTime)
end

-- 假滚如果是96信号；需要变信号 101-30;102-35;103-20
function CodeGameScreenLuxeVegasMachine:getBonusFreeSymbolType()
    local weightTbl = {30, 35, 20}
    local changeSymbolType = {101, 102, 103}
    local totalWetght = 0
    local preValue = 0
    local symbolType = changeSymbolType[1]
    for i=1, #weightTbl do
        totalWetght = totalWetght + weightTbl[i]
    end
    local randomNum = math.random(1, totalWetght)
    for i=1, #weightTbl do
        if randomNum > preValue and randomNum <= preValue + weightTbl[i] then
            symbolType = changeSymbolType[i]
            break
        end
        preValue = preValue + weightTbl[i]
    end
    return symbolType
end

function CodeGameScreenLuxeVegasMachine:createSlotNextNode(parentData)
    CodeGameScreenLuxeVegasMachine.super.createSlotNextNode(self, parentData)
    if parentData.symbolType == self.SYMBOL_SCORE_CHANGE_BONUS then
        parentData.symbolType = self:getBonusFreeSymbolType()
    end
end

---
-- 在这里不影响groupIndex 和 rowIndex 等到结果数据来时使用
--
function CodeGameScreenLuxeVegasMachine:getReelDataWithWaitingNetWork(parentData)
    CodeGameScreenLuxeVegasMachine.super.getReelDataWithWaitingNetWork(self, parentData)
    if parentData.symbolType == self.SYMBOL_SCORE_CHANGE_BONUS then
        parentData.symbolType = self:getBonusFreeSymbolType()
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenLuxeVegasMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] and self:getCurSymbolIsBuling(_slotNode) then
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
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                _slotNode:runAnim(symbolCfg[2], false, function()
                    self:symbolBulingEndCallBack(_slotNode)
                end )
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenLuxeVegasMachine:checkSymbolBulingSoundPlay(_slotNode)
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
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return self:getCurSymbolIsBuling(_slotNode)
            end
        end
    end

    return false
end

-- scatter落地条件
function CodeGameScreenLuxeVegasMachine:isPlayTipAnima(colIndex, rowIndex, node)
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

-- 落地提层特殊；重写条件
function CodeGameScreenLuxeVegasMachine:getCurSymbolIsBuling(_slotNode)
    if _slotNode.p_symbolType == self.SYMBOL_SCORE_WHEEL_BONUS then
        if self.m_isTriggerBonusTbl and next(self.m_isTriggerBonusTbl) and self.m_isTriggerBonusTbl[_slotNode.p_cloumnIndex] then
            return true
        else
            _slotNode:runAnim("idleframe3", true)
            return false
        end
    else
        return true
    end
end

return CodeGameScreenLuxeVegasMachine





