---
-- island li
-- 2019年1月26日
-- CodeGameScreenRobinIsHoodMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "RobinIsHoodPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")

local CodeGameScreenRobinIsHoodMachine = class("CodeGameScreenRobinIsHoodMachine", BaseReelMachine)

CodeGameScreenRobinIsHoodMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenRobinIsHoodMachine.SYMBOL_BONUS_1         =       94          --金币bonus
CodeGameScreenRobinIsHoodMachine.SYMBOL_BONUS_2         =       95          --乘倍bonus
CodeGameScreenRobinIsHoodMachine.SYMBOL_BONUS_3         =       97          --折扣卷bonus
CodeGameScreenRobinIsHoodMachine.SYMBOL_BONUS_4         =       101         --free bonus
CodeGameScreenRobinIsHoodMachine.SYMBOL_BONUS_5         =       102         --jackpot bonus

CodeGameScreenRobinIsHoodMachine.SYMBOL_EMPTY           =       200          --空信号
-- 自定义动画的标识
CodeGameScreenRobinIsHoodMachine.COLLECT_BONUS_SCORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1     --射箭动效
CodeGameScreenRobinIsHoodMachine.COLLECT_SHOP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2            --收集商店相关动效
CodeGameScreenRobinIsHoodMachine.COLLECT_ALL_SHOP_COINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3     --收集角标动效

--角标tag
local TAG_SIGN = 3001

-- 构造函数
function CodeGameScreenRobinIsHoodMachine:ctor()
    CodeGameScreenRobinIsHoodMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeRobinIsHoodSrc.RobinIsHoodSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("RobinIsHoodLongRunControl",self) 

    self.m_arrow_down = {} --弓箭图标落地
    self.m_flyNodes = {}

    self.m_scatterCount = 0 --scatter数量

    self.m_discountSoundIndex = 1


    self.m_arrowList = {}   --弓箭图标列表
    self.m_haveArrowInFirstCol = {} --第一列是否存在弓箭图标
    self.m_multiBgList = {}
    self.m_lockBonus = {}
    self.m_bonusCollectMulti = 0 --收集bonus的倍数
    self.m_collectBonusWinCoins = 0
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.m_isDiscount = false   --是否折扣
    self.m_isSuperFs = false
    self.m_isBonusOver = false
    --init
    self:initGame()
end

function CodeGameScreenRobinIsHoodMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("RobinIsHoodConfig.csv", "LevelRobinIsHoodConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

--[[
    @desc: 断线重连时处理 是否有feature 
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenRobinIsHoodMachine:checkHasFeature()
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then
        for i = 1, #self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN or featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        hasFeature = true
    end

    return hasFeature
end

---
-- 检测上次feature 数据
--
function CodeGameScreenRobinIsHoodMachine:checkNetDataFeatures()
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- self:sortGameEffects( )
            -- self:playGameEffect()
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]

                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1

                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                            for addPosIndex = 1, #lineData.p_iconPos do
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
                            end

                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end
                if checkEnd == true then
                    break
                end
            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
        end
    end
end

function CodeGameScreenRobinIsHoodMachine:initGameStatusData(gameData)
    if gameData.special and gameData.special.selfData then
        gameData.spin.selfData = gameData.special.selfData
    end
    if gameData.special and self:checkTriggerFree(gameData.special.features) then
        gameData.spin.freespin = gameData.special.freespin
        gameData.spin.features = gameData.special.features
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                gameData.spin.reels[iRow][iCol] = self.m_configData["init_reel"..iCol][iRow]
            end
        end
        if gameData.special.freespin.freeSpinsLeftCount > 0 then
            self.m_isSuperFs = true
        end
    end
    if gameData.spin then
        local features = gameData.spin.features
        for index = 1,#features do
            if features[index] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                table.remove(features,index)
                break
            end
        end
    end
    
    CodeGameScreenRobinIsHoodMachine.super.initGameStatusData(self, gameData)

    self.m_shopData = {}
    self:updateShopData(gameData.gameConfig.extra)
    
    if gameData.special then
        self:updateShopData(gameData.special.selfData)
    end
    
end

--[[
    更新商店是否二次点击数据
]]
function CodeGameScreenRobinIsHoodMachine:updateDoublePickData(pageIndex,pickResult)
    if pickResult[1] == "extraPick" then
        self.m_shopData.extraPick[pageIndex] = true
        self.m_shopData.extraPickPos[pageIndex] = pickResult[#pickResult]
    else
        self.m_shopData.extraPick[pageIndex] = false
        self.m_shopData.extraPickPos[pageIndex] = {}
    end
end

--[[
    更新商店数据
]]
function CodeGameScreenRobinIsHoodMachine:updateShopData(data)
    if not data then
        return
    end

    if data.oldShop then
        self.m_shopData.shop = data.oldShop
    elseif data.shop then
        self.m_shopData.shop = data.shop
    end

    if data.clickPos then
        self.m_shopData.clickPos = data.clickPos
    end

    if data.extraPick then
        self.m_shopData.extraPick = data.extraPick
    end

    if data.extraPickPos then
        self.m_shopData.extraPickPos = data.extraPickPos
    end

    if data.oldShopCoins then
        self.m_shopData.shopCoins = data.oldShopCoins
    elseif data.shopCoins then
        self.m_shopData.shopCoins = data.shopCoins
    end

    if data.coins then
        self.m_shopData.coins = data.coins
    end

    if data.cost then
        self.m_shopData.cost = data.cost
    end
    if data.finished then
        self.m_shopData.finished = data.finished
    end
    if data.startTime then
        self.m_shopData.startTime = data.startTime
    end
    if data.endTime then
        self.m_shopData.endTime = data.endTime
    end
end

--[[
    获取当前商店页数
]]
function CodeGameScreenRobinIsHoodMachine:getCurShopPageIndex()
    
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRobinIsHoodMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RobinIsHood"  
end

function CodeGameScreenRobinIsHoodMachine:getBottomUINode()
    return "CodeRobinIsHoodSrc.RobinIsHoodBottomNode"
end

function CodeGameScreenRobinIsHoodMachine:getReelNode()
    return "CodeRobinIsHoodSrc.RobinIsHoodReelNode"
end

--[[
    设置跳过按钮是否显示
]]
function CodeGameScreenRobinIsHoodMachine:setSkipBtnShow(isShow)
    self.m_skipBtn:setVisible(isShow)
    self.m_bottomUI.m_spinBtn:setVisible(not isShow)
end

--[[
    变更背景
]]
function CodeGameScreenRobinIsHoodMachine:changeBgType(gameType)
    self.m_gameBg:findChild("Base"):setVisible(gameType == "base")
    self.m_gameBg:findChild("Free"):setVisible(gameType == "free")
    self.m_gameBg:findChild("Dfdc"):setVisible(gameType == "bonus")
end

function CodeGameScreenRobinIsHoodMachine:initUI()
    local spinParent = self.m_bottomUI:findChild("free_spin_new")
    if spinParent then
        self.m_skipBtn = util_createView("CodeRobinIsHoodSrc.RobinIsHoodSkipBtn",{machine = self})
        spinParent:addChild(self.m_skipBtn)
        self.m_skipBtn:setVisible(false)
    end

    self:changeCoinWinEffectUI(self:getModuleName(), "RobinIsHood_totalwin.csb")

    self.m_waittingNode = cc.Node:create()
    self:addChild(self.m_waittingNode)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    --特效层1
    self.m_effectNode1 = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode1,1000)

    self:findChild("Node_free_kuang"):setVisible(false)
    self:findChild("Node_free_reel"):setVisible(false)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --大角色
    self.m_spineRole = util_createView("CodeRobinIsHoodSrc.RobinIsHoodSpineRole",{machine = self})
    self:findChild("Node_juese"):addChild(self.m_spineRole)
    
    self:initFreeSpinBar() -- FreeSpinbar
    --多福多彩
    self.m_colorfulGameView = util_createView("CodeRobinIsHoodSrc.RobinIsHoodColorfulGame",{machine = self})
    self:findChild("root"):addChild(self.m_colorfulGameView)
    self.m_colorfulGameView:setVisible(false) 

    --商店界面
    self.m_shopView = util_createView("CodeRobinIsHoodSrc.RobinIsHoodShop.RobinIsHoodShopView",{machine = self})
    self:addChild(self.m_shopView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_shopView:setPosition(display.center)
    self.m_shopView:findChild("root"):setScale(self.m_machineRootScale)
    self.m_shopView:setVisible(false)

    --商店金币
    self.m_shopCoinBar = util_createView("CodeRobinIsHoodSrc.RobinIsHoodShop.RobinIsHoodShopCollectBar",{machine = self})
    self:findChild("Node_base_discount"):addChild(self.m_shopCoinBar)

    self:initJackPotBarView() 

    self.m_special_frame_base = self:findChild("special_frame_base")
    self.m_special_frame_free = self:findChild("special_frame_free")
    self.m_special_frame_base:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 50)
    self.m_special_frame_free:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 50)

    -- 创建view节点方式
    -- self.m_RobinIsHoodView = util_createView("CodeRobinIsHoodSrc.RobinIsHoodView")
    -- self:findChild("xxxx"):addChild(self.m_RobinIsHoodView)  
   
end


--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenRobinIsHoodMachine:initSpineUI()
    
end


function CodeGameScreenRobinIsHoodMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_RobinIsHood_enter_level)
    end)
end

function CodeGameScreenRobinIsHoodMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isEnter = true
    CodeGameScreenRobinIsHoodMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:setShopCoins(self.m_shopData.coins)

    --刷新折扣卷
    if self.m_shopData.endTime and self.m_shopData.endTime > 0 then
        local leftTime = self.m_shopData.endTime / 1000 - util_getCurrnetTime()
        self.m_shopCoinBar:updateDiscountTime(leftTime)
    end

    self.m_special_frame_base:setVisible(true)
    self.m_special_frame_free:setVisible(false)

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not self:checkTriggerFree(self.m_runSpinResultData.p_features) then
        self.m_shopCoinBar:showTipAni()
        self:changeBgType("base")
    
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_collectBonusWinCoins = self.m_runSpinResultData.p_fsWinCoins
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData.superFreeType then
            self.m_isSuperFs = true
            self.m_baseFreeSpinBar:updateSuperShow(self.m_isSuperFs)
        end
        self:showFreeUI()
        self:changeBgType("free")
    end
    self.m_isEnter = false
end

--[[
    设置金币数显示
]]
function CodeGameScreenRobinIsHoodMachine:setShopCoins(coins)
    if not coins then
        coins = self.m_shopData.coins
    end
    self.m_shopCoinBar:setCoins(coins)
    self.m_shopView.m_coins_bar:setCoins(coins)
end

--[[
    检测是否触发free
]]
function CodeGameScreenRobinIsHoodMachine:checkTriggerBonus()
    local features = self.m_runSpinResultData.p_features
    if features then
        for index = 1, #features do 
            local featureId = features[index]
            if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                return true
            end
        end
    end

    return false
end

--[[
    检测是否触发free
]]
function CodeGameScreenRobinIsHoodMachine:checkTriggerFree(features)
    
    if features then
        for index = 1, #features do 
            local featureId = features[index]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then
                return true
            end
        end
    end

    return false
end

function CodeGameScreenRobinIsHoodMachine:addObservers()
    CodeGameScreenRobinIsHoodMachine.super.addObservers(self)
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
        
        local lTatolBetNum = self:getTotalBet()
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

        local soundName = PublicConfig.SoundConfig["sound_RobinIsHood_base_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_isSuperFs then
                soundName = PublicConfig.SoundConfig["sound_RobinIsHood_super_free_winline_"..soundIndex]
            else
                soundName = PublicConfig.SoundConfig["sound_RobinIsHood_free_winline_"..soundIndex]
            end
            
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenRobinIsHoodMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    util_resetChildReferenceCount(self.m_effectNode1)
    CodeGameScreenRobinIsHoodMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
--设置bonus scatter 层级
function CodeGameScreenRobinIsHoodMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType == self.SYMBOL_BONUS_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isFixSymbol(symbolType) or symbolType == self.SYMBOL_BONUS_2 then
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
    return order

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenRobinIsHoodMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_RobinIsHood_pick1"
    end

    if symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_RobinIsHood_Bonus6"
    end

    if symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_RobinIsHood_Bonus"
    end

    if symbolType == self.SYMBOL_BONUS_4 then
        return "Socre_RobinIsHood_pick2"
    end
    
    if symbolType == self.SYMBOL_BONUS_5 then
        return "Socre_RobinIsHood_pick3"
    end

    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_RobinIsHood_Empty"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenRobinIsHoodMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenRobinIsHoodMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenRobinIsHoodMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRobinIsHoodMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    

    return false -- 用作延时点击spin调用
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenRobinIsHoodMachine:resetReelDataAfterReel()
    CodeGameScreenRobinIsHoodMachine.super.resetReelDataAfterReel(self)
    self.m_arrowList = {}
    self.m_haveArrowInFirstCol = {} --第一列是否存在弓箭图标
    self.m_bonusCollectMulti = 0 --收集bonus的倍数
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_collectBonusWinCoins = 0
    else
        if next(self.m_multiBgList) then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_multi_bg"])
        end

        for key,multiBg in pairs(self.m_multiBgList) do
            multiBg:setVisible(true)
            multiBg:stopAllActions()
            multiBg:runCsbAction("start")
            performWithDelay(multiBg,function()
                multiBg:runCsbAction("idle",true)
            end,30 / 60)
            for iCol = 2,self.m_iReelColumnNum do
                --检测是否需要隐藏乘倍标签
                if multiBg.m_doubleList then
                    local doubleItem = multiBg.m_doubleList[tostring(iCol)]
                    doubleItem:setVisible(true)
                    doubleItem:runCsbAction("start")
                end
            end
        end
    end
    

    if self.m_shopCoinBar:isShowTip() then
        self.m_shopCoinBar:hideTipAni()
    end

    for key,lockNode in pairs(self.m_lockBonus) do
        local rowIndex = tonumber(key)
        local symbolNode = self:getFixSymbol(1,rowIndex)
        if symbolNode then
            self:changeSymbolType(symbolNode,self.SYMBOL_EMPTY)
            self:changeSymbolToClipParent(symbolNode)
        end

        if not tolua.isnull(lockNode) then
            lockNode:setVisible(true)
            lockNode.m_isLock = false
        end
        
    end
end

function CodeGameScreenRobinIsHoodMachine:beginReel()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()

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
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_bonus_hit_down"])
                    local csbAni = util_createAnimation("Socre_RobinIsHood_Bonus_xialuo.csb")
                    self:findChild("root"):addChild(csbAni)
                    csbAni:runCsbAction("actionframe",false,function()
                        self:requestSpinReusltData()
                        if not tolua.isnull(csbAni) then
                            csbAni:removeFromParent()
                        end
                    end)
                else
                    self:requestSpinReusltData()
                end
            end
        end)
    end
end

function CodeGameScreenRobinIsHoodMachine:firstSpinRestMusicBG()
    if self.m_spinRestMusicBG then
        if self.m_isSuperFs then
            self:resetMusicBg(true,"RobinIsHoodSounds/music_RobinIsHood_super_free.mp3")
        else
            self:resetMusicBg()
        end
        self.m_spinRestMusicBG = false
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenRobinIsHoodMachine:slotOneReelDown(reelCol)    
    CodeGameScreenRobinIsHoodMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
    if reelCol == 1 then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:updateLockBonus()
        end
    else
        for key,multiBg in pairs(self.m_multiBgList) do
            local rowIndex = tonumber(key)
            --检测是否需要隐藏乘倍标签
            if multiBg.m_doubleList then
                local symbolNode = self:getFixSymbol(reelCol,rowIndex)
                if not tolua.isnull(symbolNode) and self:isCollectBonus(symbolNode.p_symbolType) then
                    
                else
                    local doubleItem = multiBg.m_doubleList[tostring(reelCol)]
                    doubleItem:runCsbAction("over",false,function()
                        if not tolua.isnull(doubleItem) then
                            doubleItem:setVisible(false)
                        end
                    end)
                end
            end
        end
    end

    
end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function CodeGameScreenRobinIsHoodMachine:lineLogicWinLines()
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        self:compareScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

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

    return false
end

--[[
    滚轮停止
]]
function CodeGameScreenRobinIsHoodMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenRobinIsHoodMachine.super.slotReelDown(self)

    self.m_arrow_down = {}
    self.m_scatterCount = 0 --scatter数量

    --检测移除乘倍背景
    for key,csbNode in pairs(self.m_multiBgList) do
        local rowIndex = tonumber(key)
        local isHaveBonus = false
        for iCol = 2,self.m_iReelColumnNum do
            local targetSymbol = self:getFixSymbol(iCol,rowIndex)
            if targetSymbol and self:isCollectBonus(targetSymbol.p_symbolType) then
                isHaveBonus = true
                break
            end
        end
        if self.m_lockBonus[tostring(rowIndex)] and not isHaveBonus then
            self:hideMultiBg(rowIndex)
        elseif not isHaveBonus then
            self:removeMultiBg(rowIndex)
        end
    end
end

-----by he 将除自定义动画之外的动画层级赋值
--
function CodeGameScreenRobinIsHoodMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            if effectData.p_effectType == GameEffect.EFFECT_BONUS then
                effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 30
            else
                effectData.p_effectOrder = effectData.p_effectType
            end
            
        end
    end
end

--[[
    获取平均bet
]]
function CodeGameScreenRobinIsHoodMachine:getTotalBet()
    if self.m_runSpinResultData.p_avgBet and self.m_runSpinResultData.p_avgBet > 0 then
        return self.m_runSpinResultData.p_avgBet
    end
    return globalData.slotRunData:getCurTotalBet()
end

function CodeGameScreenRobinIsHoodMachine:pushAnimNodeToPool(animNode, symbolType)
    if symbolType == self.SYMBOL_BONUS_2 then
        --乘倍图标不放到池子中,否则设置皮肤有问题
        animNode:clear()
        animNode:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表
        animNode:release()
        return
    end
    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}

        self.m_reelAnimNodePool[symbolType] = reelPool
    end
    animNode:setScale(1)
    reelPool[#reelPool + 1] = animNode
end

--新滚动使用
function CodeGameScreenRobinIsHoodMachine:updateReelGridNode(symbolNode)
    if tolua.isnull(symbolNode) or not symbolNode.p_symbolType then
        return
    end

    symbolNode.m_isLock = false
    symbolNode.m_isDark = false

    local symbolType = symbolNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS_1 then --金币bonus
        self:setBonusSymbolScore(symbolNode)
    elseif symbolType == self.SYMBOL_BONUS_2 then --乘倍bonus
        self:setBonusSymbolMulti(symbolNode)
    elseif symbolType == self.SYMBOL_BONUS_3 then --折扣卷bonus
        self:setSpecialBonusSymbol(symbolNode)
    elseif symbolType == self.SYMBOL_BONUS_4 then --free bonus
    elseif symbolType == self.SYMBOL_BONUS_5 then --jackpot bonus
    end

    if self.m_isEnter then
        if symbolType == self.SYMBOL_BONUS_1 then
            symbolNode:runAnim("idleframe2",true)
        end
    else
        -- if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_4 or symbolType == self.SYMBOL_BONUS_5 then
        --     if self:getGameSpinStage( ) > IDLE and self:getGameSpinStage() ~= QUICK_RUN then
        --         symbolNode:runAnim("idleframe3",true)
        --     end
        -- end
    end
    
end

--[[
    在图标上创建金币角标
]]
function CodeGameScreenRobinIsHoodMachine:checkAddSignOnSymbol(symbolNode)
    CodeGameScreenRobinIsHoodMachine.super.checkAddSignOnSymbol(self,symbolNode)
    if self.m_isEnter then
        return
    end
    if tolua.isnull(symbolNode) then
        return
    end

    local sign = symbolNode:getChildByTag(TAG_SIGN)
    if not tolua.isnull(sign) then
        sign:removeFromParent()
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE or not symbolNode.m_isLastSymbol then
        return
    end

    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.score then
        --存在角标
        if selfData.score[posIndex + 1] and selfData.score[posIndex + 1] > 0 and symbolNode.p_symbolType ~= self.SYMBOL_BONUS_3 then
            local sign = util_createAnimation("RobinIsHood_base_smallcoins.csb")
            symbolNode:addChild(sign, 100000)
            sign:setTag(TAG_SIGN)
            local symbolSize = cc.size(self.m_SlotNodeW, self.m_SlotNodeH)
            local signSize = cc.size(35, 35)
            local pos = cc.p(symbolSize.width / 2 - signSize.width / 2, -symbolSize.height / 2 + signSize.height / 2)
            --将角标放在图标的右下角
            sign:setPosition(pos)
            sign.m_coins = selfData.score[posIndex + 1]
            sign:findChild("m_lb_num"):setString(sign.m_coins)

        end
    end
end


--[[
    设置折扣券小块
]]
function CodeGameScreenRobinIsHoodMachine:setSpecialBonusSymbol(symbolNode)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.specialBonus then
        return
    end

    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)

    
    local data = self:getSpecialBonusData(posIndex)
    if data then
        local bonusType = data[2]
        local addCount = data[3]
        local csbNode = self:getCsbOnSpecialBonus(symbolNode,bonusType)
        if csbNode then
            if bonusType == "time" then --加时间
            
                local hour,minute,second = self:getFormatTime(addCount)
                csbNode:findChild("Time_H"):setString(hour)
                csbNode:findChild("Time_M"):setString(minute)
                csbNode:findChild("Time_S"):setString(second)

            else --"coins" --加收集
                local csbNode = self:getCsbOnSpecialBonus(symbolNode,bonusType)
                csbNode:findChild("m_lb_num"):setString(addCount)
                csbNode:setVisible(true)
            end
        end
        
    end
end

--[[
    格式化时间
]]
function CodeGameScreenRobinIsHoodMachine:getFormatTime(time)
    local hour,minute,second = 0,0,0

    hour = math.floor(time / (60 * 60))
    minute = math.floor((time - hour * (60 * 60)) / 60)
    second = math.floor(time % 60)

    return hour,minute,second
end

--[[
    获取小块spine槽点上绑定的csb节点
    csbName csb文件名称
    bindNodeName 槽点名称
]]
function CodeGameScreenRobinIsHoodMachine:getCsbOnSpecialBonus(symbolNode,bonusType)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine then

        if not spine.m_lblCsbNode then
            local csbNode = util_createAnimation("RobinIsHood_base_zhekouquan.csb")
            util_spinePushBindNode(spine,"zi",csbNode)
            spine.m_lblCsbNode = csbNode
            for index = 1,2 do
                local particle = csbNode:findChild("Particle_"..index)
                if not tolua.isnull(particle) then
                    particle:setVisible(false)
                end
            end

        end
        if not spine.m_coinCsbNode then
            local csbNode = util_createAnimation("RobinIsHood_base_smallcoins.csb")
            util_spinePushBindNode(spine,"jinbi",csbNode)
            spine.m_coinCsbNode = csbNode
        end
        spine.m_lblCsbNode:setVisible(false)
        spine.m_coinCsbNode:setVisible(false)

        if bonusType == "time" then
            return spine.m_lblCsbNode
        else
            return spine.m_coinCsbNode
        end

    end
    
end

--[[
    获取折扣卷小块数据
]]
function CodeGameScreenRobinIsHoodMachine:getSpecialBonusData(posIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.specialBonus then
        return nil
    end

    local bonusType = nil
    local addCount = 0
    for k,data in pairs(selfData.specialBonus) do
        if data[1] == posIndex then
            return data
        end
    end

    return nil
end

--[[
    设置乘倍小块
]]
function CodeGameScreenRobinIsHoodMachine:setBonusSymbolMulti(symbolNode,multi)
    if not multi then
        multi = 1
        local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        if symbolNode.m_isLastSymbol == true then 
            --根据网络数据获取停止滚动时respin小块的分数
            multi = self:getReSpinSymbolScore(posIndex) --获取分数（网络数据）
        else
            multi = self.m_configData:getFixSymbolPro()
            if multi < 1 then
                multi = 1
            end
        end
    end

    local isLock = false
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isLock = (math.random(1,5) == 1)
    end
    if not symbolNode.m_isLastSymbol and isLock then 
        symbolNode:runAnim("idleframe3",true)
    end
    

    symbolNode.m_multiple = multi

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine then
        if multi == 1 then
            spine:setSkin("default")
        elseif multi <= 5 then
            spine:setSkin(multi.."X")
        else
            spine:setSkin("default")
            util_printLog("小块倍数错误,请检查数据是否正确",true)
        end
    end

    
end

-- 给respin小块进行赋值
function CodeGameScreenRobinIsHoodMachine:setBonusSymbolScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 0
    local multi = 1
    if symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        multi,score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
    else
        multi,score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    local labelCsb,spine = self:getLblCsbOnSymbol(symbolNode,"Socre_RobinIsHood_Bonus_zi.csb","zi")
    if labelCsb then
        labelCsb:setVisible(true)
        local m_lb_coins1 = labelCsb:findChild("m_lb_coins1")
        local m_lb_coins2 = labelCsb:findChild("m_lb_coins2")

        m_lb_coins1:setString(util_formatCoins(score,3))
        m_lb_coins2:setString(util_formatCoins(score,3))

        self:updateLabelSize({label=m_lb_coins1,sx=1,sy=1},150)  
        self:updateLabelSize({label=m_lb_coins2,sx=1,sy=1},150)  
        
        m_lb_coins1:setVisible(multi < 2.5)
        m_lb_coins2:setVisible(multi >= 2.5)
    end

    if not tolua.isnull(spine) then
        spine:setSkin("common")
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenRobinIsHoodMachine:getReSpinSymbolScore(id)
    
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local multi = nil
    local addTimes = 1

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            multi = values[2]
            break
        end
    end

    local lineBet = self:getTotalBet()
    if multi == nil then
       return 0,lineBet
    end

    
    local score = multi * lineBet
    return multi,score
end

--[[
    随机bonus分数
]]
function CodeGameScreenRobinIsHoodMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    local lineBet = self:getTotalBet()
    local multi = self.m_configData:getFixSymbolPro()
    if self.m_isEnter then
        multi = 2.5
    end
    score = multi * lineBet


    return multi,score
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRobinIsHoodMachine:addSelfEffect()

    local haveSpecialCoins = false --特殊图标中是否有金币
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.specialBonus and next(selfData.specialBonus) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_SHOP_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_SHOP_EFFECT -- 动画类型

        --判断是否有金币
        for index = 1,#selfData.specialBonus do
            local data = selfData.specialBonus[index]
            if data[2] == "coins" then
                haveSpecialCoins = true
                break
            end
        end
    end   
    
    local isCollect = false
    local reels = self.m_runSpinResultData.p_reels
    for iRow = 1,#reels do
        
        if reels[iRow][1] == self.SYMBOL_BONUS_2 then
            for iCol = 2,self.m_iReelColumnNum do
                if self:isCollectBonus(reels[iRow][iCol]) then
                    isCollect = true
                    break
                end
            end
            if isCollect then
                break
            end
            
        end
    end
    if not isCollect then
        for key,v in pairs(self.m_lockBonus) do
            local rowIndex = tonumber(key)
            local iRow = self.m_iReelRowNum - rowIndex + 1
            for iCol = 2,self.m_iReelColumnNum do
                if self:isCollectBonus(reels[iRow][iCol]) then
                    isCollect = true
                    break
                end
            end
            if isCollect then
                break
            end
        end
    end

    if isCollect then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_SCORE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_SCORE_EFFECT -- 动画类型
    end

    --收集所有角标
    if selfData and selfData.score and not haveSpecialCoins and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_ALL_SHOP_COINS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_ALL_SHOP_COINS_EFFECT -- 动画类型
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenRobinIsHoodMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_SHOP_EFFECT then

        self:delayCallBack(17 / 30,function()
            --收集商店金币及折扣
            self:collectShopCoinsAndDiscount(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)

    elseif effectData.p_selfEffectType == self.COLLECT_BONUS_SCORE_EFFECT then --射箭动效
        
        self:delayCallBack(30 / 30,function()
            self:showBlackLayer()
            for key,lockNode in pairs(self.m_lockBonus) do
                lockNode:setVisible(true)
                local rowIndex = tonumber(key)
                for i,arrowSymbol in ipairs(self.m_arrowList) do
                    if arrowSymbol.p_rowIndex == rowIndex then
                        self:changeSymbolType(arrowSymbol,self.SYMBOL_EMPTY)
                        table.remove(self.m_arrowList,i)
                        break
                    end
                end
                self.m_arrowList[#self.m_arrowList + 1] = lockNode
                
            end

            table.sort(self.m_arrowList,function(a,b)
                return a.p_rowIndex > b.p_rowIndex
            end)
            if not self:checkHasBigWin() then
                self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, GameEffect.EFFECT_BONUS)
            end

            self.m_collectArrowEnd = function()
                self.m_collectArrowEnd = nil
                self:hideBlackLayer( )
                -- self:setSkipBtnShow(false)
                effectData.p_isPlay = true
                self:playGameEffect()
            end

            for iCol = 2,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local targetSymbol = self:getFixSymbol(iCol,iRow)
                    if not tolua.isnull(targetSymbol) and (targetSymbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or targetSymbol.p_symbolType == self.SYMBOL_BONUS_3) then
                        self:putSymbolBackToPreParent(targetSymbol)
                    end
                end
            end

            for index = 1,#self.m_arrowList do
                local arrowSymbol = self.m_arrowList[index]
                local isHaveBonus = false
                for iCol = 2,self.m_iReelColumnNum do
                    local targetSymbol = self:getFixSymbol(iCol,arrowSymbol.p_rowIndex)
                    if not tolua.isnull(targetSymbol) and self:isCollectBonus(targetSymbol.p_symbolType) then
                        isHaveBonus = true
                        break
                    end
                end
                if not isHaveBonus then
                    arrowSymbol:stopAllActions()
                    if arrowSymbol:isSlotsNode() then
                        arrowSymbol:runAnim("dark1_start")
                        arrowSymbol.m_isDark = true
                    else
                        arrowSymbol.isIdle = false
                        util_spinePlay(arrowSymbol,"dark2_start")
                        arrowSymbol.m_isDark = true
                    end
                end
            end

            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                --base下,玩法开始时,不参与玩法的靶子压暗
                for iCol = 2,self.m_iReelColumnNum do
                    for iRow = 1,self.m_iReelRowNum do
                        if not self.m_haveArrowInFirstCol[tostring(iRow)] then
                            local symbol = self:getFixSymbol(iCol,iRow)
                            if not tolua.isnull(symbol) and self:isCollectBonus(symbol.p_symbolType) then
                                symbol:runAnim("dark")
                                symbol.m_isDark = true
                            end
                        end
                    end
                end
            end


            -- self:setSkipBtnShow(true)
            self:collectNextArrowLine(self.m_arrowList,1,function()
                self:m_collectArrowEnd()
            end)
        end)
        
    elseif effectData.p_selfEffectType == self.COLLECT_ALL_SHOP_COINS_EFFECT then --收集所有角标
        local coins = self.m_shopData.coins
        self:collectAllShopCoins(function()
            --刷新金币
            self:delayCallBack(38 / 60,function()
                self.m_shopCoinBar:runCollectCoinsFeedBackAni()
                self:setShopCoins(coins)
            end)
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

--[[
    跳过射箭收集
]]
function CodeGameScreenRobinIsHoodMachine:skipCollectBonus()
    if type(self.m_collectArrowEnd) == "function" then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, true,true})
        elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
            globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins
            if self.m_collectBonusWinCoins ~= self.m_runSpinResultData.p_fsWinCoins then
                self.m_collectBonusWinCoins = self.m_runSpinResultData.p_fsWinCoins
                local startCoins = self.m_collectBonusWinCoins - self.m_runSpinResultData.p_winAmount
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_collectBonusWinCoins, false,true,startCoins})
            end
        end
        for rowIndex,multiBg in pairs(self.m_multiBgList) do
            --移除乘倍背景
            if not self.m_lockBonus[tostring(rowIndex)] then
                self:removeMultiBg(rowIndex)
            else
                self:hideMultiBg(rowIndex)
            end
        end

        for k,lockNode in pairs(self.m_lockBonus) do
            if not lockNode.isIdle then
                util_spinePlay(lockNode,"idleframe4",true)
                lockNode.isIdle = true
            end
        end
        self.m_waittingNode:stopAllActions()
        if type(self.m_collectArrowEnd) == "function" then
            self:m_collectArrowEnd()
        end
        
    end
end

--[[
    收集下一个Bonus
]]
function CodeGameScreenRobinIsHoodMachine:collectNextArrowLine(list,index,func)
    if index > #list then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines == 0 and not self:checkTriggerBonus() then
            self.m_bottomUI:notifyTopWinCoin()
        elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
            globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins
            if self.m_collectBonusWinCoins ~= self.m_runSpinResultData.p_fsWinCoins then
                self.m_collectBonusWinCoins = self.m_runSpinResultData.p_fsWinCoins
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_collectBonusWinCoins, false,true})
            end
        end

        --取消箭头压暗
        for index = 1,#list do
            local slotNode = list[index]
            if not tolua.isnull(slotNode) then
                if slotNode.m_isDark then
                    if slotNode:isSlotsNode() then
                        slotNode:runAnim("dark1_over")
                    else
                        util_spinePlay(slotNode,"dark2_over")
                        local delayTime = slotNode:getAnimationDurationTime("dark2_over")
                        performWithDelay(slotNode,function()
                            util_spinePlay(slotNode,"idleframe4",true)
                        end,delayTime)
                    end
                end
            end
        end
        --base下取消靶子压暗
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            for iCol = 2,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local symbol = self:getFixSymbol(iCol,iRow)
                    if not tolua.isnull(symbol) and symbol.m_isDark then
                        symbol:runAnim("idleframe")
                    end
                end
            end
        end

        if type(func) == "function" then
            func()
        end
        return
    end

    local symbolNode = list[index]
    local rowIndex = symbolNode.p_rowIndex
    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)

    local storedIcons = self.m_runSpinResultData.p_storedIcons
    --计算当前行的赢钱
    local curLineMulti = 0
    for index = 1,4 do
        local multi = self:getReSpinSymbolScore(posIndex + index)
        if self.m_haveArrowInFirstCol[tostring(rowIndex)] then
            multi  = multi * self.m_haveArrowInFirstCol[tostring(rowIndex)]
        end
        self.m_bonusCollectMulti  = self.m_bonusCollectMulti + multi
        curLineMulti  = curLineMulti + multi
    end


    local isHaveBonus = false
    for iCol = 2,self.m_iReelColumnNum do
        local targetSymbol = self:getFixSymbol(iCol,rowIndex)
        if not tolua.isnull(targetSymbol) and self:isCollectBonus(targetSymbol.p_symbolType) then
            isHaveBonus = true
        end
    end

    if isHaveBonus then --有可收集的bonus才射箭
        local delayTime = 0
        local zOrder = symbolNode:getLocalZOrder()
        symbolNode:setLocalZOrder(zOrder + 1000)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_arrow_start"])
        if symbolNode:isSlotsNode() then
            symbolNode:runAnim("actionframe")
            delayTime = symbolNode:getAniamDurationByName("actionframe")
        else
            symbolNode.isIdle = false
            util_spinePlay(symbolNode,"actionframe2")
            delayTime = symbolNode:getAnimationDurationTime("actionframe2")
        end

        globalData.slotRunData.lastWinCoin = 0
        
        performWithDelay(self.m_waittingNode,function()
            if not tolua.isnull(symbolNode) then
                symbolNode:setLocalZOrder(zOrder)
            end
            
            if symbolNode:isSlotsNode() then
                symbolNode:runAnim("idleframe2",true)
            else
                util_spinePlay(symbolNode,"idleframe4",true)
                symbolNode.isIdle = true
            end
        end,delayTime)

        performWithDelay(self.m_waittingNode,function()
            --移除乘倍背景
            if not self.m_lockBonus[tostring(rowIndex)] then
                self:removeMultiBg(rowIndex)
            else
                self:hideMultiBg(rowIndex)
            end
        end,40 / 30)
        
        --金币bonus收集反馈
        performWithDelay(self.m_waittingNode,function()
            local symbolList = {}
            for iCol = 2,self.m_iReelColumnNum do
                local targetSymbol = self:getFixSymbol(iCol,rowIndex)
                if targetSymbol and self:isCollectBonus(targetSymbol.p_symbolType) then
                    symbolList[#symbolList + 1] = targetSymbol
                    
                end
            end

            self:collectNextBonusCoins(symbolList,1,function()
                self:collectNextArrowLine(list,index + 1,func)
            end)
        end,35 / 30)
    else
        self:collectNextArrowLine(list,index + 1,func)
    end
end

--[[
    收集下个bonus
]]
function CodeGameScreenRobinIsHoodMachine:collectNextBonusCoins(list,index,func)
    if index > #list then
        -- local symbolNode = list[index - 1]
        -- local lineMulti = self.m_haveArrowInFirstCol[tostring(symbolNode.p_rowIndex)] or 1
        local delayTime = 20 / 30
        delayTime  = delayTime + 1 + 2 * #list / 30
        performWithDelay(self.m_waittingNode,function()
            if type(func) == "function" then
                func()
            end
        end,delayTime)
        return
    end

    local symbolNode = list[index]
    if not tolua.isnull(symbolNode) then
        local zOrder = symbolNode:getLocalZOrder()
        symbolNode:setLocalZOrder(zOrder + 500)

        local aniName = "actionframe"
        local lineMulti = self.m_haveArrowInFirstCol[tostring(symbolNode.p_rowIndex)] or 1
        if lineMulti > 1 then
            aniName = "actionframe2"
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_bonus_multi"])
            if symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then
                local labelCsb = self:getLblCsbOnSymbol(symbolNode,"Socre_RobinIsHood_Bonus_zi.csb","zi")
                symbolNode:changeSkin(lineMulti.."X")
                performWithDelay(self.m_waittingNode,function()
                    if not tolua.isnull(labelCsb) then
                        labelCsb:setVisible(false)
                    end
                    
                    local coins,multi = self:updateCoinBonusMulti(symbolNode)
                    --爆点光效
                    local light = util_createAnimation("Socre_RobinIsHood_Bonus_zi_0.csb")
                    symbolNode:addChild(light)
                    light:runCsbAction(aniName,false,function()
                        light:removeFromParent()
                    end)
                    self:flyCoinToBottom(multi,coins,true,symbolNode,self.m_bottomUI.coinWinNode,function()
                        self:showCollectBonusCoins(coins)
                        local params = {self.m_collectBonusWinCoins + coins, false,true,self.m_collectBonusWinCoins}
                        params[self.m_stopUpdateCoinsSoundIndex] = true
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                        self.m_collectBonusWinCoins = self.m_collectBonusWinCoins + coins
                        
                    end)
                end,20 / 30)
            end
            
        else
            if symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then
                local labelCsb = self:getLblCsbOnSymbol(symbolNode,"Socre_RobinIsHood_Bonus_zi.csb","zi")
                local coins,multi = self:updateCoinBonusMulti(symbolNode)
                if not tolua.isnull(labelCsb) then
                    labelCsb:setVisible(false)
                end
                --爆点光效
                local light = util_createAnimation("Socre_RobinIsHood_Bonus_zi_0.csb")
                symbolNode:addChild(light)
                light:runCsbAction(aniName,false,function()
                    light:removeFromParent()
                end)
                self:flyCoinToBottom(multi,coins,false,symbolNode,self.m_bottomUI.coinWinNode,function()
                    
                    self:showCollectBonusCoins(coins)
                    local params = {self.m_collectBonusWinCoins + coins, false,true,self.m_collectBonusWinCoins}
                    params[self.m_stopUpdateCoinsSoundIndex] = true
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                    self.m_collectBonusWinCoins = self.m_collectBonusWinCoins + coins
        
                end)
            end
        end
        
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_arrow_start_feed_back"])
        symbolNode:runAnim(aniName,false,function()
            if not tolua.isnull(symbolNode) then
                symbolNode:setLocalZOrder(zOrder)
                symbolNode:runAnim("idleframe2",true)
            end
        end)

        performWithDelay(self.m_waittingNode,function()
            self:collectNextBonusCoins(list,index + 1,func)
        end,2 / 30)
    else
        self:collectNextBonusCoins(list,index + 1,func)
    end
end

--[[
    飞金币动画
]]
function CodeGameScreenRobinIsHoodMachine:flyCoinToBottom(multi,score,isMulti,startNode,endNode,func)
    local flyNode = util_createAnimation("Socre_RobinIsHood_Bonus_zi.csb")
    local m_lb_coins1 = flyNode:findChild("m_lb_coins1")
    local m_lb_coins2 = flyNode:findChild("m_lb_coins2")
    
    m_lb_coins1:setVisible(multi < 2.5)
    m_lb_coins2:setVisible(multi >= 2.5)

    m_lb_coins1:setString(util_formatCoins(score,3))
    m_lb_coins2:setString(util_formatCoins(score,3))

    self:updateLabelSize({label=m_lb_coins1,sx=1,sy=1},150)  
    self:updateLabelSize({label=m_lb_coins2,sx=1,sy=1},150)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    local actionList = {
    }
    
    if isMulti then
        flyNode:runCsbAction("actionframe2")
        actionList[#actionList + 1] = cc.DelayTime:create(30 / 60)
    else
        actionList[#actionList + 1] = cc.DelayTime:create(40 / 60)
        flyNode:runCsbAction("actionframe")
    end

    actionList[#actionList + 1] = cc.EaseQuadraticActionIn:create(cc.MoveTo:create(20 / 60,endPos))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if type(func) == "function" then
            func()
        end
    end)
    actionList[#actionList + 1] = cc.RemoveSelf:create(true)
    local seq = cc.Sequence:create(actionList)
    flyNode:runAction(seq)
end


--[[
    收集bonus金币下方动效
]]
function CodeGameScreenRobinIsHoodMachine:showCollectBonusCoins(coins)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_bottom_coin_feed_back"])
    local winLabCsb = util_createAnimation("RobinIsHood_coins.csb")
    self.m_bottomUI.coinWinNode:addChild(winLabCsb)
    local str   = string.format("+%s", util_getFromatMoneyStr(coins)) 
    local labCoins = winLabCsb:findChild("m_lb_coins")
    labCoins:setString(str)
    winLabCsb:runCsbAction("actionframe",false,function()
        if not tolua.isnull(winLabCsb) then
            winLabCsb:removeFromParent()
        end
    end)

    
    winLabCsb:setScale(0.65)
    winLabCsb:setPositionY(15)
    self:playCoinWinEffectUI()
    
end


--[[
    收集商店金币及折扣
]]
function CodeGameScreenRobinIsHoodMachine:collectShopCoinsAndDiscount(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.specialBonus then
        if type(func) == "function" then
            func()
        end
        return 
    end

    local specialBonus = selfData.specialBonus
    local delayTime,showTime = 0,0
    for index = 1,#specialBonus do
        local data = specialBonus[index]
        --收集折扣券
        if data[2] == "time" then
            showTime = self:flyShopDiscount(data,self.m_shopCoinBar.m_message)
        else    --收集金币
            showTime = self:flyShopCoinsOnBonus(data,self.m_shopCoinBar:findChild("m_lb_coins"))
        end
        if showTime > delayTime then
            delayTime = showTime
        end
    end

    self:delayCallBack(delayTime,func)
    
end

--[[
    收集所有图标上的角标
]]
function CodeGameScreenRobinIsHoodMachine:collectAllShopCoins(func)
    local isPlaySound = false
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) then
            local sign = symbolNode:getChildByTag(TAG_SIGN)
            if not tolua.isnull(sign) then
                isPlaySound = true
                local coins = sign.m_coins
                self:flyShopCoinsAni(coins,sign,self.m_shopCoinBar:findChild("Sprite_2"))
                sign:removeFromParent()
            end
        end
    end

    if isPlaySound then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_collect_sign)
        self:delayCallBack(38 / 60,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_collect_sign_feed_back)
        end)
    end
   

    if type(func) == "function" then
        func()
    end

    return isPlaySound
end

--[[
    飞金币动画
]]
function CodeGameScreenRobinIsHoodMachine:flyShopCoinsAni(coins,startNode,endNode,func)
    local flyNode = self:getFlyNodeFromList()
    flyNode:setVisible(true)
    for index = 1,2 do
        local particle = flyNode.m_particle:findChild("Particle_"..index)
        if not tolua.isnull(particle) then
            particle:resetSystem()
            particle:setPositionType(0)
        end
    end
    flyNode:findChild("m_lb_num"):setString(coins)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)
    local actionList = {
        cc.DelayTime:create(20 / 60),
        cc.EaseQuadraticActionIn:create(cc.MoveTo:create(18 / 60,endPos)),
        cc.CallFunc:create(function()
            for index = 1,2 do
                local particle = flyNode.m_particle:findChild("Particle_"..index)
                if not tolua.isnull(particle) then
                    particle:stopSystem()
                end
            end

            if not tolua.isnull(flyNode:findChild("Node_coins")) then
                flyNode:findChild("Node_coins"):setVisible(false)
            end

            self:delayCallBack(1,function()
                if not tolua.isnull(flyNode) then
                    self:pushFlyNodeToList(flyNode)
                end
            end)
        end)
    }
    local seq = cc.Sequence:create(actionList)
    flyNode:runAction(seq)
    flyNode:runCsbAction("fly")
end

function CodeGameScreenRobinIsHoodMachine:getFlyNodeFromList()
    if #self.m_flyNodes == 0 then
        local flyNode = util_createAnimation("RobinIsHood_base_smallcoins.csb")
        self.m_effectNode:addChild(flyNode)
        local particle = util_createAnimation("RobinIsHood_base_smallcoins_lizi.csb")
        flyNode:findChild("Node_lizi"):addChild(particle)
        flyNode.m_particle = particle
        return flyNode
    end

    local flyNode = self.m_flyNodes[#self.m_flyNodes]
    table.remove(self.m_flyNodes,#self.m_flyNodes)
    return flyNode
end

function CodeGameScreenRobinIsHoodMachine:pushFlyNodeToList(flyNode)
    self.m_flyNodes[#self.m_flyNodes + 1] = flyNode
    if not tolua.isnull(flyNode) then
        flyNode:findChild("Node_coins"):setVisible(true)
    end
    flyNode:setVisible(false)
end

--[[
    收集bonus图标上的商店金币
]]
function CodeGameScreenRobinIsHoodMachine:flyShopCoinsOnBonus(data,endNode)
    local symbolNode = self:getSymbolByPosIndex(data[1])
    if not symbolNode then
        return 0
    end

    local coins = self.m_shopData.coins
   
    local isHaveSign = self:collectAllShopCoins(function()
        
    end)

    local flyTime = 0
    if isHaveSign then
        flyTime = 38 / 60
    end
    self:delayCallBack(flyTime,function()
        
        self:setShopCoins(coins - data[3])
        if isHaveSign then
            self.m_shopCoinBar:runCollectCoinsFeedBackAni()
        end
        symbolNode:runAnim("actionframe",false,function()
            symbolNode:runAnim("actionframe_idle",true)
        end)

        --10帧后开始飞金币
        self:delayCallBack(10 / 30,function()
            local csbNode = self:getCsbOnSpecialBonus(symbolNode,"coins")
            csbNode:setVisible(false)
            
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_collect_bonus_coins)
            self:flyShopCoinsAni(data[3],csbNode,self.m_shopCoinBar:findChild("Sprite_2"))
            
            self:delayCallBack(38 / 60,function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_collect_bonus_coins_feed_back)
                --刷新金币
                self.m_shopCoinBar:runCollectCoinsFeedBackAni()
                self:setShopCoins(coins)
            end)
        end)
    end)

    
    --延长的展示时间期间不可点击spin
    local showTime = 10 / 30 + flyTime + 20 / 60
    return showTime
end

--[[
    收集折扣券
]]
function CodeGameScreenRobinIsHoodMachine:flyShopDiscount(data,endNode)
    local symbolNode = self:getSymbolByPosIndex(data[1])
    if not symbolNode then
        return 0
    end
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_collect_discount_sound_"..self.m_discountSoundIndex])
    self.m_discountSoundIndex  = self.m_discountSoundIndex + 1
    if self.m_discountSoundIndex > 2 then
        self.m_discountSoundIndex = 1
    end
    symbolNode:runAnim("actionframe2",false,function()
        symbolNode:runAnim("actionframe2_idle",true)
    end)

    local flyTime = 15 / 60
    --40帧后显示折扣券
    self:delayCallBack(40 / 30,function()
        local csbNode = self:getCsbOnSpecialBonus(symbolNode,"time")
        csbNode:setVisible(false)

        local startPos = util_convertToNodeSpace(csbNode,self.m_effectNode)

        local flyNode = util_createAnimation("RobinIsHood_base_zhekouquan.csb")
        self.m_effectNode:addChild(flyNode)
        flyNode:setPosition(startPos)

        local addTime = data[3]
        local hour,minute,second = self:getFormatTime(addTime)
        flyNode:findChild("Time_H"):setString(hour)
        flyNode:findChild("Time_M"):setString(minute)
        flyNode:findChild("Time_S"):setString(second)

        local particle_1 = flyNode:findChild("Particle_1")
        if not tolua.isnull(particle_1) then
            particle_1:setVisible(false)
        end

        local Particle_2 = flyNode:findChild("Particle_2")
        if not tolua.isnull(Particle_2) then
            Particle_2:setVisible(true)
            Particle_2:setPositionType(0)
        end
        flyNode:runCsbAction("start",false,function()
            
            if not tolua.isnull(flyNode) then
                flyNode:runCsbAction("shouji",false)
            end
            local endPos = util_convertToNodeSpace(self.m_shopCoinBar.m_message,self.m_effectNode)
            local actionList = {
                cc.DelayTime:create(0.5),
                cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_collect_discount"])
                end),
                cc.EaseQuadraticActionIn:create(cc.MoveTo:create(flyTime,endPos)),
                cc.CallFunc:create(function()

                    local isVisible = self.m_shopCoinBar:runDiscountFeedBack()
                    if isVisible then
                        self:delayCallBack(30 / 60 + 0.5,function()
                            local endTime = self.m_shopData.endTime / 1000
                            local curTime = util_getCurrnetTime()
                            local leftTime = endTime - curTime
                            self.m_shopCoinBar:updateDiscountTime(leftTime)
                        end)
                    else
                        local endTime = self.m_shopData.endTime / 1000
                        local curTime = util_getCurrnetTime()
                        local leftTime = endTime - curTime
                        self.m_shopCoinBar:updateDiscountTime(leftTime)
                    end
                    
                    flyNode:setVisible(false)
                    if not tolua.isnull(Particle_2) then
                        Particle_2:stopSystem()
                    end
                    self:delayCallBack(0.1,function()
                        flyNode:removeFromParent()
                    end)
                end)
            }
            if not tolua.isnull(flyNode) then
                local seq = cc.Sequence:create(actionList)
                flyNode:runAction(seq)
                
            end
        end)
    end)
    
    --延长的展示0.5s期间不可点击spin
    local showTime = 40 / 30 + 30 / 60 + 0.5
    return showTime
end



function CodeGameScreenRobinIsHoodMachine:playEffectNotifyNextSpinCall( )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 1
        
        local winCoinTime = self:getWinCoinTime()
        if self:checkTriggerFree(self.m_runSpinResultData.p_features) then
            winCoinTime = 0
        end
        delayTime = delayTime + winCoinTime

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
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end

    if self.m_isBonusOver then
        self.m_isBonusOver = false
        self:reelsDownDelaySetMusicBGVolume( ) 
    else
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( ) 
        end)
    end
    

end

-- free和freeMore特殊需求
function CodeGameScreenRobinIsHoodMachine:playScatterTipMusicEffect()
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
function CodeGameScreenRobinIsHoodMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenRobinIsHoodMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenRobinIsHoodMachine:checkRemoveBigMegaEffect()
    CodeGameScreenRobinIsHoodMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenRobinIsHoodMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeRobinIsHoodSrc.RobinIsHoodFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenRobinIsHoodMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:showUI(self.m_isSuperFs)
end

function CodeGameScreenRobinIsHoodMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end



--[[
    检测添加free事件
]]
function CodeGameScreenRobinIsHoodMachine:checkAddFsEffect(data)
    local features = data.features
    if self:checkTriggerFree(features) then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
        effectData.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData

        self:sortGameEffects()
        self:updateFreeCount(data.freespin.freeSpinsLeftCount,data.freespin.freeSpinsTotalCount)
        self.m_isSuperFs = true

        self.m_isRunningEffect = true
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        return true
    end
    return false
end

--[[
    刷新free次数数据
]]
function CodeGameScreenRobinIsHoodMachine:updateFreeCount(leftCount,totalCount)
    globalData.slotRunData.freeSpinCount = leftCount
    globalData.slotRunData.totalFreeSpinCount = totalCount
    self.m_runSpinResultData.p_freeSpinsLeftCount = leftCount
    self.m_runSpinResultData.p_freeSpinsTotalCount = totalCount

    self.m_iFreeSpinTimes = leftCount
end

function CodeGameScreenRobinIsHoodMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("RobinIsHoodSounds/music_RobinIsHood_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self.m_collectBonusWinCoins = self.m_runSpinResultData.p_fsWinCoins
            
            local func = function()
                self:setCurrSpinMode(FREE_SPIN_MODE)
                if self.m_isSuperFs then
                    self:resetMusicBg(true,"RobinIsHoodSounds/music_RobinIsHood_super_free.mp3")
                else
                    self:resetMusicBg()
                end
                self:changeSceneToFree(function()
                    self:triggerFreeSpinCallFun()
                    self:showFreeUI()

                    effectData.p_isPlay = true
                    self:playGameEffect() 
                    
                end,function()
                    
                end)
            end
            if self.m_isSuperFs then
                -- 停掉背景音乐
                self:clearCurMusicBg()
                local view = self:showShowSuperFsView(function()
                    func()    
                end)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_fs_start"])
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    func()  
                end)
                view:setBtnClickFunc(function(  )
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click)
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_hide_fs_start"])
                end)

                local btn = view:findChild("Button_start")
                if not tolua.isnull(btn) then
                    btn:setTouchEnabled(false)
                end
    
                local spine = util_spineCreate("RobinIsHood_guochang1",true,true)
                view:findChild("bg"):addChild(spine)
                util_spinePlay(spine,"start")
                util_spineEndCallFunc(spine,"start",function()
                    util_spinePlay(spine,"idle",true)
                    if not tolua.isnull(btn) then
                        btn:setTouchEnabled(true)
                    end
                end)
                util_setCascadeOpacityEnabledRescursion(view:findChild("bg"),true)
    
                local m_light = util_createAnimation("RobinIsHood_tanban_guang.csb")
                view:findChild("Node_guang"):addChild(m_light)
                m_light:runCsbAction("idle2",true)
                util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"),true)
            end
            
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenRobinIsHoodMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    
    
end

--[[
    显示free相关UI
]]
function CodeGameScreenRobinIsHoodMachine:showFreeUI()
    self:findChild("Node_free_kuang"):setVisible(true)
    self:findChild("Node_free_reel"):setVisible(true)
    self:findChild("Node_base_reel"):setVisible(false)
    self:findChild("Node_basekuang"):setVisible(false)
    self.m_jackpotBar_free:setVisible(true)
    self.m_jackPotBarView:setVisible(false)
    self.m_shopCoinBar:setVisible(false)
    self.m_spineRole:setVisible(false)
    self.m_haveArrowInFirstCol = {}
    self:changeBgType("free")

    self.m_special_frame_base:setVisible(false)
    self.m_special_frame_free:setVisible(true)

    self:showFreeSpinBar()

    if self.m_isSuperFs then
        self.m_bottomUI:showAverageBet()
    end
    --升行
    self.m_iReelRowNum = 10
    local reelHeight = self.m_SlotNodeH * self.m_iReelRowNum
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        
        reelNode:changClipSizeWithoutAni(reelHeight,true)
    end

    --变更压黑层大小
    local blackLayerSize = self.m_blackLayer:getContentSize()
    blackLayerSize.height = reelHeight
    self.m_blackLayer:setContentSize(blackLayerSize)

    for i = self.m_iReelRowNum , 1, - 1 do
        if self.m_stcValidSymbolMatrix[i] == nil then
            self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
        end
    end

    --变更点击区域大小
    self:changeTouchSpinLayerSize()

    self:updateLockBonus()

    --非bonus图标转化为空
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum + 1 do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if not tolua.isnull(symbolNode) then
                self:changeSymbolType(symbolNode,self.SYMBOL_EMPTY)
            end
        end
    end
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenRobinIsHoodMachine:hideFreeUI()
    self:findChild("Node_free_kuang"):setVisible(false)
    self:findChild("Node_free_reel"):setVisible(false)
    self:findChild("Node_base_reel"):setVisible(true)
    self:findChild("Node_basekuang"):setVisible(true)
    self.m_jackpotBar_free:setVisible(false)
    self.m_jackPotBarView:setVisible(true)
    self.m_shopCoinBar:setVisible(true)
    self.m_spineRole:setVisible(true)
    self.m_collectBonusWinCoins = 0

    self.m_special_frame_base:setVisible(true)
    self.m_special_frame_free:setVisible(false)

    self:hideFreeSpinBar()

    self:changeBgType("base")

    self.m_bottomUI:hideAverageBet()
    --先把提层的图标放回去
    self:checkChangeBaseParent()

    --移除固定的图标
    for k,lockNode in pairs(self.m_lockBonus) do
        lockNode:removeFromParent()
    end

    self.m_lockBonus = {}

    for rowIndex,multiBg in pairs(self.m_multiBgList) do
        self:removeMultiBg(rowIndex)
    end

    
    --降行
    self.m_iReelRowNum = 4
    local reelHeight = self.m_SlotNodeH * self.m_iReelRowNum
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        
        reelNode:changClipSizeWithoutAni(reelHeight,false)
    end

    --变更压黑层大小
    local blackLayerSize = self.m_blackLayer:getContentSize()
    blackLayerSize.height = reelHeight
    self.m_blackLayer:setContentSize(blackLayerSize)

    for index = 5 , 10 do
        if self.m_stcValidSymbolMatrix[index] then
            self.m_stcValidSymbolMatrix[index] = nil
        end
    end

    --变更点击区域大小
    self:changeTouchSpinLayerSize()
    
    local reels = self.m_runSpinResultData.p_fsExtraData.reel

    if reels then
        for iCol = 1,self.m_iReelColumnNum do
            local reelNode = self.m_baseReelNodes[iCol]
            for iRow = 1,#reelNode.m_rollNodes do
                local symbolNode = self:getFixSymbol(iCol,iRow)
                local symbolType
                if iRow > self.m_iReelRowNum then
                    symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_2)
                else
                    symbolType = reels[self.m_iReelRowNum - iRow + 1][iCol]
                end
                if symbolNode and symbolType then
                    self:changeSymbolType(symbolNode,symbolType)
                    if symbolType == self.SYMBOL_BONUS_2 then
                        symbolNode:runAnim("idleframe2",true)
                    elseif symbolType == self.SYMBOL_BONUS_1 then
                        symbolNode:runAnim("idleframe",true)
                        local labelCsb = self:getLblCsbOnSymbol(symbolNode,"Socre_RobinIsHood_Bonus_zi.csb","zi")
                        if not tolua.isnull(labelCsb) then
                            labelCsb:setVisible(false)
                        end
                    end
                end
            end
            reelNode:resetAllRollNodeZOrder(true)
        end
    end
end

--[[
    过场动画(free)
]]
function CodeGameScreenRobinIsHoodMachine:changeSceneToFree(keyFunc,endFunc)
    if self.m_isSuperFs then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_change_scene_to_super_fs)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_change_scene_to_fs)
    end
    local spine = util_spineCreate("RobinIsHood_guochang1",true,true)
    self:findChild("root"):addChild(spine)
    spine:setScale(self.m_bgScale)
    util_spinePlay(spine,"actionframe_guochang")
    self:delayCallBack(68 / 30,keyFunc)
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    过场动画
]]
function CodeGameScreenRobinIsHoodMachine:changeSceneToBaseFromFree(keyFunc,endFunc)
    if self.m_isSuperFs then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_change_scene_to_base_from_super_fs)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_change_scene_to_base_from_fs)
    end
    local spine = util_spineCreate("RobinIsHood_guochang1",true,true)
    self:findChild("root"):addChild(spine)
    spine:setScale(self.m_bgScale)
    util_spinePlay(spine,"actionframe_guochang2")
    self:delayCallBack(68 / 30,keyFunc)
    util_spineEndCallFunc(spine,"actionframe_guochang2",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

function CodeGameScreenRobinIsHoodMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("RobinIsHoodSounds/music_RobinIsHood_over_fs.mp3")

    globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins
    
    local view = self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()

            self:changeSceneToBaseFromFree(function()
                self.m_runSpinResultData.p_avgBet = 0
                self:hideFreeUI()
            end,function()
                self:triggerFreeSpinOverCallFun()
            end)
            
        end
    )
    local node=view:findChild("m_lb_coins")
    if not tolua.isnull(node) then
        view:updateLabelSize({label=node,sx=1,sy=1},693)   
    end
    
end

function CodeGameScreenRobinIsHoodMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    if coins > 0 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
        local view
        if self.m_isSuperFs then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_show_super_fs_over)
            view = self:showDialog("SuperFreeSpinOver", ownerlist, func)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_show_fs_over)
            view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        end
        local m_light = util_createAnimation("RobinIsHood_tanban_guang.csb")
        view:findChild("Node_guang"):addChild(m_light)
        m_light:runCsbAction("idle",true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"),true)

        
        view:setBtnClickFunc(function(  )
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click)
            if self.m_isSuperFs then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_super_fs_over)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_fs_over)
            end
            
        end)

        return view
    else
        local ownerlist = {}
        local view = self:showDialog("NoWin", ownerlist, func)

        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_show_fs_over)
        view:setBtnClickFunc(function(  )
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_fs_over)
        end)

        return view
    end
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenRobinIsHoodMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            scatterLineValue:clean()
            break
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if not self.m_isSuperFs then
            -- 停掉背景音乐
            self:clearCurMusicBg()
        end
        
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    local waitTime = 0

    self:stopLinesWinSound()

    local func = function()
        self:showFreeSpinView(effectData)
    end

    self:delayCallBack(0.5,function()
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        if self.m_isSuperFs then
            func()
        else
            self:runScatterTriggerAni(func)
        end
    end)
    
    
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

--[[
    显示superFree界面
]]
function CodeGameScreenRobinIsHoodMachine:showShowSuperFsView(func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = self.m_iFreeSpinTimes
    local view = self:showDialog("SuperFreeSpinStart", ownerlist, func)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_super_fs_start"])
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_hide_super_fs_start"])
    end)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local pageIndex = (fsExtraData.buy or 0) + 1
    local tip = util_createAnimation("RobinIsHood_SuperFreeSpin_conditons.csb")
    view:findChild("Node_conditons"):addChild(tip)
    for index = 1,5 do
        tip:findChild("Node_"..index):setVisible(index == pageIndex)
    end

    local btn = view:findChild("Button_start")
    if not tolua.isnull(btn) then
        btn:setTouchEnabled(false)
    end

    self:delayCallBack(50 / 60,function()
        if not tolua.isnull(btn) then
            btn:setTouchEnabled(true)
        end
    end)

    return view
end

--[[
    scatter触发动画
]]
function CodeGameScreenRobinIsHoodMachine:runScatterTriggerAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_scatter_trigger"])
    local scatterList = {}
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterList[#scatterList + 1] = symbolNode
            
        end
    end
    if #scatterList >= 3 then
    self.m_spineRole:runFreeTriggerAni()
    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    local delayTime = 0
    for index = 1,#scatterList do
        local symbolNode = scatterList[index]
        symbolNode:changeParentToOtherNode(self.m_effectNode1)
        symbolNode:runAnim("actionframe",false,function()
            self:putSymbolBackToPreParent(symbolNode)
        end)

        local duration = symbolNode:getAniamDurationByName("actionframe")
        if duration > delayTime then
            delayTime = duration
        end
    end
    
    self:delayCallBack(delayTime,func)
    else
        self.m_spineRole:runFreeTriggerAni(func)
    end
end

function CodeGameScreenRobinIsHoodMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeRobinIsHoodSrc.RobinIsHoodJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpotbar"):addChild(self.m_jackPotBarView) --修改成自己的节点    

    self.m_jackpotBar_free = util_createView("CodeRobinIsHoodSrc.RobinIsHoodFreeJackPotBarView")
    self.m_jackpotBar_free:initMachine(self)
    self:findChild("Node_free_jackpot"):addChild(self.m_jackpotBar_free) --修改成自己的节点  
    self.m_jackpotBar_free:setVisible(false)
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenRobinIsHoodMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeRobinIsHoodSrc.RobinIsHoodJackpotWinView",{
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
    判断是否为bonus小块(需要在子类重写)
]]
function CodeGameScreenRobinIsHoodMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 or 
    symbolType == self.SYMBOL_BONUS_3 or 
    symbolType == self.SYMBOL_BONUS_4 or 
    symbolType == self.SYMBOL_BONUS_5 then
        return true
    end
    
    return false
end

--[[
    判断是否为需要收集的bonus
]]
function CodeGameScreenRobinIsHoodMachine:isCollectBonus(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 or 
    symbolType == self.SYMBOL_BONUS_4 or 
    symbolType == self.SYMBOL_BONUS_5 then
        return true
    end
    
    return false
end

--[[
    显示乘倍背景
]]
function CodeGameScreenRobinIsHoodMachine:createMultiBg(rowIndex,multi,isInit)
    if not multi then
        multi = 1
    end
    if self.m_multiBgList[tostring(rowIndex)] and multi == self.m_multiBgList[tostring(rowIndex)].m_multi then
        return
    elseif self.m_multiBgList[tostring(rowIndex)] then
        self:removeMultiBg(rowIndex)
    end

    local csbName = "RobinIsHood_free_arrow_green.csb"
    if multi > 1 then
        csbName = "RobinIsHood_free_arrow_blue.csb"
    end
    local csbNode = util_createAnimation(csbName)
    self.m_multiBgList[tostring(rowIndex)] = csbNode
    csbNode.m_multi = multi

    if multi > 1 then
        local doubleList = {}
        for index = 2,5 do
            local item = util_createAnimation("RobinIsHood_double.csb")
            doubleList[tostring(index)] = item
            csbNode:findChild("Node_reel_"..index):addChild(item)
            item:runCsbAction("idle")
            item:findChild("m_lb_num_2x"):setString(multi.."X")
            
        end
        csbNode.m_doubleList = doubleList
    end

    self.m_clipParent:addChild(csbNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 25)
    local sp_reel = self.m_csbOwner["sp_reel_2"]
    local pos = cc.p(sp_reel:getPosition())
    local reelSize = sp_reel:getContentSize()
    pos.x  = pos.x + reelSize.width / 2
    pos.y  = pos.y + self.m_SlotNodeH * (rowIndex - 0.5)
    csbNode:setPosition(pos)
    csbNode:setTag(10)

    if isInit then
        csbNode:setVisible(false) 
    end

    csbNode:runCsbAction("start")
    performWithDelay(csbNode,function()
        csbNode:runCsbAction("idle",true)
    end,30 / 60)
end

--[[
    隐藏乘倍背景
]]
function CodeGameScreenRobinIsHoodMachine:hideMultiBg(rowIndex)
    if self.m_multiBgList[tostring(rowIndex)] then
        local bg = self.m_multiBgList[tostring(rowIndex)]
        bg:stopAllActions()
        bg:runCsbAction("over",false,function()
            
        end)
        local time = util_csbGetAnimTimes(bg.m_csbAct,"over")
        performWithDelay(bg,function()
            bg:setVisible(false)
        end,time)
    end
end

--[[
    移除乘倍背景
]]
function CodeGameScreenRobinIsHoodMachine:removeMultiBg(rowIndex)
    if self.m_multiBgList[tostring(rowIndex)] then
        local bg = self.m_multiBgList[tostring(rowIndex)]
        bg:stopAllActions()
        bg:runCsbAction("over",false,function()
            bg:removeFromParent()
        end)
        self.m_multiBgList[tostring(rowIndex)] = nil
    end
end

--[[
    检测是否为固定图标
]]
function CodeGameScreenRobinIsHoodMachine:checkIsLockNode(rowIndex)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        return false
    end

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.lockHitBonus then
        local iRow = self.m_iReelRowNum - rowIndex + 1
        local multi = fsExtraData.lockHitBonus[iRow]
        if multi > 0 and not self.m_lockBonus[tostring(rowIndex)] then
            return true
        end
    end
    return false
end

--[[
    检测播放落地动画
]]
function CodeGameScreenRobinIsHoodMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    local isHaveMultiBg = false
    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then

                --提层
                if symbolCfg[1] then
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    self:changeSymbolToClipParent(symbolNode)

                    --回弹
                    local actList = {}
                    local moveTime = self.m_configData.p_reelResTime
                    local dis = self.m_configData.p_reelResDis
                    local pos = cc.p(curPos)
                    local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                    local action2 = cc.MoveTo:create(moveTime / 2,pos)
                    actList = {action1,action2}
                    symbolNode:runAction(cc.Sequence:create(actList))
                end

                for key,lockNode in pairs(self.m_lockBonus) do
                    self.m_haveArrowInFirstCol[key] = lockNode.m_multi
                end
                if symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                    self.m_arrowList[#self.m_arrowList + 1] = symbolNode
                    self.m_haveArrowInFirstCol[tostring(symbolNode.p_rowIndex)] = symbolNode.m_multiple
                    self:createMultiBg(symbolNode.p_rowIndex,symbolNode.m_multiple)
                    isHaveMultiBg = true
                end

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    
                    local bulingAni = symbolCfg[2]
                    if symbolNode.p_symbolType == self.SYMBOL_BONUS_2  then
                        if self:checkIsLockNode(symbolNode.p_rowIndex) then
                            bulingAni = "buling2"
                            symbolNode.m_isLock = true
                        else
                            symbolNode.m_isLock = false
                        end
                    elseif symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then
                        -- self:updateCoinBonusMulti(symbolNode)
                        -- local multi = self.m_haveArrowInFirstCol[tostring(iRow)] or 1
                        -- if multi > 1 then
                        --     bulingAni = "buling2"
                        -- end

                    end

                    --2.播落地动画
                    symbolNode:runAnim(
                        bulingAni,
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )
                    --bonus落地音效
                    if self:isFixSymbol(symbolNode.p_symbolType) then
                        self:checkPlayBonusDownSound(colIndex)
                    end
                    --scatter落地音效
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:checkPlayScatterDownSound(colIndex)
                    end

                    if symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                        self:checkPlayArrowSymbolDownSound(colIndex)
                    end
                else
                    --free下只有靶子和箭头,所以不考虑其他图标落地,且参与玩法的靶子直接压暗不落地
                    if not self.m_haveArrowInFirstCol[tostring(iRow)] and self:getCurrSpinMode() == FREE_SPIN_MODE then
                        symbolNode:runAnim("dark")
                        symbolNode.m_isDark = true
                    end
                end
            end
            
        end
    end

    if isHaveMultiBg then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_multi_bg"])
    end
end

--[[
    检测播放弓箭落地音效
]]
function CodeGameScreenRobinIsHoodMachine:checkPlayArrowSymbolDownSound(colIndex)
    if not self.m_arrow_down[colIndex] then
        
        self:playArrowDownSound(colIndex)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_arrow_down[iCol] = true
        end
    else
        self.m_arrow_down[colIndex] = true
    end
end

--[[
    播放弓箭落地音效
]]
function CodeGameScreenRobinIsHoodMachine:playArrowDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_arrow_down"])
end


--[[
    播放bonus落地音效
]]
function CodeGameScreenRobinIsHoodMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_bonus_down)
end

--[[
    检测播放scatter落地音效
]]
function CodeGameScreenRobinIsHoodMachine:checkPlayScatterDownSound(colIndex)
    self.m_scatterCount  = self.m_scatterCount + 1
    if self.m_scatterCount > 3 then
        self.m_scatterCount = 3
    end
    
    if self:getGameSpinStage() == QUICK_RUN and self.m_scatter_down[iCol] then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_scatter_down[iCol] = true
        end
        if self.m_scatterCount == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_scatter_down_3"])
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_scatter_down_1"])
        end
        
    else
        
        if not self.m_scatter_down[colIndex] then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_scatter_down_"..self.m_scatterCount])
        end
        self.m_scatter_down[colIndex] = true
    end
end


--[[
    刷新固定图标
]]
function CodeGameScreenRobinIsHoodMachine:updateLockBonus()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.lockHitBonus then
        for iRow = 1,#fsExtraData.lockHitBonus do
            local multi = fsExtraData.lockHitBonus[iRow]
            local rowIndex = self.m_iReelRowNum - iRow + 1
            if multi > 0 and not self.m_lockBonus[tostring(rowIndex)] then
                local lockNode = util_spineCreate("Socre_RobinIsHood_Bonus6",true,true)
                local zOrder = self:getBounsScatterDataZorder(self.SYMBOL_BONUS_2)
                zOrder = zOrder - rowIndex + self.m_iReelRowNum * 2
                self.m_clipParent:addChild(lockNode,zOrder)
                lockNode.m_multi = multi
                if multi == 1 then
                    lockNode:setSkin("default")
                elseif multi <= 5 then
                    lockNode:setSkin(multi.."X")
                else
                    lockNode:setSkin("default")
                    util_printLog("小块倍数错误,请检查数据是否正确",true)
                end
                lockNode:setTag(10)
                self.m_lockBonus[tostring(rowIndex)] = lockNode
                util_spinePlay(lockNode,"idleframe4",true)
                lockNode.isIdle = true
                --创建乘倍背景
                self:createMultiBg(rowIndex,multi,true)
                lockNode.p_rowIndex = rowIndex
                lockNode.p_cloumnIndex = 1

                lockNode.isSlotsNode = function()
                    return false
                end

                --正在播落地,等落地播完再显示出来
                if self.m_haveArrowInFirstCol[tostring(rowIndex)] then
                    lockNode:setVisible(false)
                end

                local symbolNode = self:getFixSymbol(1,rowIndex)
                if not tolua.isnull(symbolNode) then
                    local pos = util_convertToNodeSpace(symbolNode,self.m_clipParent)
                    lockNode:setPosition(pos)
                end
            end
        end
    end
end

--[[
    更新金币bonus倍数
]]
function CodeGameScreenRobinIsHoodMachine:updateCoinBonusMulti(symbolNode)
    local rowIndex = symbolNode.p_rowIndex
    local multi = self.m_haveArrowInFirstCol[tostring(rowIndex)] or 1
    local skinName = "common"
    if multi > 1 and multi <= 5 then
        skinName = multi.."X"
    end


    local preMulti,score = self:getReSpinSymbolScore(self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)) --获取分数（网络数据）

    local labelCsb,spine = self:getLblCsbOnSymbol(symbolNode,"Socre_RobinIsHood_Bonus_zi.csb","zi")
    local endScore = multi * score

    if spine then
        spine:setSkin(skinName)
    end
    if labelCsb and multi > 1 then
        local m_lb_coins1 = labelCsb:findChild("m_lb_coins1")
        local m_lb_coins2 = labelCsb:findChild("m_lb_coins2")
        
        m_lb_coins1:setVisible(multi * preMulti < 2.5)
        m_lb_coins2:setVisible(multi * preMulti >= 2.5)

        m_lb_coins1:setString(util_formatCoins(endScore,3))
        m_lb_coins2:setString(util_formatCoins(endScore,3))

        self:updateLabelSize({label=m_lb_coins1,sx=1,sy=1},150)  
        self:updateLabelSize({label=m_lb_coins2,sx=1,sy=1},150)
    end    
    
    return endScore,multi * preMulti
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenRobinIsHoodMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断

                if self:isPlayScatterDown(_slotNode) then
                    return true
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_BONUS_2 or _slotNode.p_symbolType == self.SYMBOL_BONUS_3 then
                return true
            elseif self:isCollectBonus(_slotNode.p_symbolType) then
                --第一列没有弓箭图标时,bonus不播落地
                if self.m_haveArrowInFirstCol[tostring(_slotNode.p_rowIndex)] or self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                    return true
                else
                    return false
                end
                
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--[[
    scatter是否播落地
]]
function CodeGameScreenRobinIsHoodMachine:isPlayScatterDown(symbolNode)
    local colIndex = symbolNode.p_cloumnIndex
    if colIndex == 2 then
        return true
    end

    local scatterNum = 0
    local reels = self.m_runSpinResultData.p_reels
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 2,colIndex - 1 do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterNum  = scatterNum + 1
            end
        end
    end

    if colIndex == 3 and scatterNum >= 1 then
        return true
    elseif colIndex == 4 and scatterNum >= 2 then
        return true
    end

    return false
end

function CodeGameScreenRobinIsHoodMachine:symbolBulingEndCallBack(_slotNode)
    if tolua.isnull(_slotNode) then
        return
    end
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 
    if _slotNode.p_symbolType == self.SYMBOL_BONUS_2 then
        if _slotNode.m_isLock then
            _slotNode:runAnim("idleframe4",true)
        else
            _slotNode:runAnim("idleframe2",true)
        end
        if self.m_lockBonus[tostring(_slotNode.p_rowIndex)] then
            local spine = self.m_lockBonus[tostring(_slotNode.p_rowIndex)]
            util_spinePlay(spine,"idleframe4",true)
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE and self:isCollectBonus(_slotNode.p_symbolType) and not self.m_haveArrowInFirstCol[tostring(_slotNode.p_rowIndex)] then
        --靶子播落地后,不参与玩法的压暗
        _slotNode:runAnim("dark")
        _slotNode.m_isDark = true
    elseif self:isCollectBonus(_slotNode.p_symbolType) then
        _slotNode:runAnim("idleframe2",true)
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

function CodeGameScreenRobinIsHoodMachine:setReelRunInfo()
    --更新商店数据
    self:updateShopData(self.m_runSpinResultData.p_selfMakeData)

    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["234"] ,["symbolType"] = {90}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态

    if self.m_shopData.endTime and self.m_shopData.endTime > 0 then
        local endTime = self.m_shopData.endTime / 1000
        local curTime = util_getCurrnetTime()
        local leftTime = endTime - curTime
        if leftTime > 0 then
            self.m_isDiscount = true
        end
    end
    

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
function CodeGameScreenRobinIsHoodMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenRobinIsHoodMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenRobinIsHoodMachine:isPlayExpect(reelCol)
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
function CodeGameScreenRobinIsHoodMachine:showFeatureGameTip(_func)
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
function CodeGameScreenRobinIsHoodMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_notice_win"])
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("Node_yugao")

    self.b_gameTipFlag = true
    local spineAni = util_spineCreate("RobinIsHood_yugao",true,true)
    parentNode:addChild(spineAni)
    util_spinePlay(spineAni,"actionframe_yugao")
    util_spineEndCallFunc(spineAni,"actionframe_yugao",function()
        spineAni:setVisible(false)
        --延时0.1s移除spine,直接移除会导致闪退
        self:delayCallBack(0.1,function()
            spineAni:removeFromParent()
        end)
        
    end)
    
    aniTime = spineAni:getAnimationDurationTime("actionframe_yugao")

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    过场动画(多福多彩到base)
]]
function CodeGameScreenRobinIsHoodMachine:changeSceneToBaseFromColorGame(keyFunc,endFunc)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_change_scene_to_base"])
    local spine = util_spineCreate("RobinIsHood_guochang1",true,true)
    self:findChild("root"):addChild(spine)
    spine:setScale(self.m_bgScale)
    util_spinePlay(spine,"actionframe_guochang")
    self:delayCallBack(68 / 30,keyFunc)
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    过场动画(多福多彩)
]]
function CodeGameScreenRobinIsHoodMachine:changeSceneToColorfulGame(keyFunc,endFunc)
    local spine = util_spineCreate("RobinIsHood_guochang",true,true)
    self:findChild("root"):addChild(spine)
    util_spinePlay(spine,"actionframe_guochang")
    spine:setScale(self.m_bgScale)
    self:delayCallBack(35 / 30,keyFunc)
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    显示多福多彩UI
]]
function CodeGameScreenRobinIsHoodMachine:showColorfulGameUI()
    self:findChild("node_reel_ui"):setVisible(false)
end

--[[
    隐藏多福多彩UI
]]
function CodeGameScreenRobinIsHoodMachine:hideColorfulGameUI()
    self:findChild("node_reel_ui"):setVisible(true)
    self.m_colorfulGameView:hideView()
    self:changeBgType("base")
end

--[[
        bonus玩法
    ]]
function CodeGameScreenRobinIsHoodMachine:showEffect_Bonus(effectData)
    

    self:clearWinLineEffect()

    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    local selfData = self.m_runSpinResultData.p_selfMakeData

    if not self:checkHasBigWin() then
        self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin,GameEffect.EFFECT_BONUS)
    end
    
    local bonusData = {
        rewardList = selfData.process,    --奖励列表
        winJackpot = jackpotType        --获得的jackpot
    }

    --重置bonus界面
    self.m_colorfulGameView:resetView(bonusData,function()
        self:showJackpotView(winCoins,jackpotType,function()
            --过场动画
            self:changeSceneToBaseFromColorGame(function()
                self:hideColorfulGameUI()
                self:clearCurMusicBg()
            end,function()
                
                self.m_isBonusOver = true
                self:resetMusicBg()

                self:removeGameEffectType(GameEffect.EFFECT_BONUS)

                self.m_runSpinResultData.p_features = {0}
                
                local totalBet = self:getTotalBet()
                globalData.slotRunData.lastWinCoin = 0
                if self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines == 0 then
                    local params = {self.m_iOnceSpinLastWin, true,true,self.m_collectBonusWinCoins}
                    params[self.m_stopUpdateCoinsSoundIndex] = true
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                else
                    local params = {winCoins + self.m_collectBonusWinCoins, false,true,self.m_collectBonusWinCoins}
                    params[self.m_stopUpdateCoinsSoundIndex] = true
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                
                end

                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            
        end)

        
    end)

    
    self:delayCallBack(1,function()
        
        self:showBonusStart(function()
            self:resetMusicBg(true,"RobinIsHoodSounds/music_RobinIsHood_colorful_game.mp3")
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_change_scene_to_colorful_game"])
            --过场动画
            self:changeSceneToColorfulGame(function()
                self:changeBgType("bonus")
                self:showColorfulGameUI()
                self.m_colorfulGameView:showView()
            end,function()
                self.m_colorfulGameView:setClickEnabled(true)
            end)
        end)
        
    end)
    

    return true    
end

--[[
    多福多彩开始弹板
]]
function CodeGameScreenRobinIsHoodMachine:showBonusStart(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_bonus_start"])
    local view = self:showDialog("JackpotFeature", {}, func)

    local m_light = util_createAnimation("RobinIsHood_tanban_guang.csb")
    view:findChild("Node_guang"):addChild(m_light)
    m_light:runCsbAction("idle3",true)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_RobinIsHood_hide_bonus_start)
        self:clearCurMusicBg()
    end)

    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_guang"),true)

    return view
end
--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenRobinIsHoodMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0    
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenRobinIsHoodMachine:showBigWinLight(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_RobinIsHood_show_big_win_light"])
    local rootNode = self:findChild("root")
    local bigWinNode = self:findChild("Node_bigwin")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,self.m_effectNode1)

    self.m_spineRole:runBigWinAni()

    --大赢光效1
    local bigWinLight1 = util_spineCreate("RobinIsHood_bigwin",true,true)
    bigWinNode:addChild(bigWinLight1)
    util_spinePlay(bigWinLight1,"actionframe2")
    util_spineEndCallFunc(bigWinLight1,"actionframe2",function()
        bigWinLight1:setVisible(false)
        self:delayCallBack(0.1,function()
            bigWinLight1:removeFromParent()
        end)
    end)

    --大赢光效2
    local bigWinLight2 = util_spineCreate("RobinIsHood_bigwin",true,true)
    self.m_effectNode1:addChild(bigWinLight2)
    bigWinLight2:setPosition(pos)
    util_spinePlay(bigWinLight2,"actionframe1")
    util_spineEndCallFunc(bigWinLight2,"actionframe1",function()
        bigWinLight2:setVisible(false)
        self:delayCallBack(0.1,function()
            bigWinLight2:removeFromParent()
        end)
    end)

    local aniTime = bigWinLight1:getAnimationDurationTime("actionframe2")
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    通知刷新赢钱
]]
function CodeGameScreenRobinIsHoodMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if self.m_iOnceSpinLastWin <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local params = {self.m_iOnceSpinLastWin, isNotifyUpdateTop}
    if not winLines or #winLines == 0 then
        params[self.m_stopUpdateCoinsSoundIndex] = true
    end
    

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
end

--[[
    金币跳动
]]
function CodeGameScreenRobinIsHoodMachine:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 1   --持续时间
    local maxWidth = params.maxWidth or 150 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local lblScale = params.lblScale or 1
    local maxCount = params.maxCount or 50 --保留最大的位数
    local jumpSound --= PublicConfig.SoundConfig.sound_WitchyHallowin_jump_coins
    local jumpSoundEnd --= PublicConfig.SoundConfig.sound_WitchyHallowin_jump_coins_end

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60  * duration)

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    label:stopAllActions()
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            label:stopAllActions()
            label:setString("+"..util_formatCoins(endCoins,maxCount))
            local info={label = label,sx = lblScale,sy = lblScale}
            self:updateLabelSize(info,maxWidth)

            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString("+"..util_formatCoins(curCoins,maxCount))

            local info={label = label,sx = lblScale,sy = lblScale}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenRobinIsHoodMachine:operaEffectOver()
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

    self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
            if self.m_isSuperFs then
                self.m_isSuperFs = false
                if selfData and selfData.firstRound then
                    self.m_shopView:showView(nil,function()
                        self.m_shopView:showUnlockAni()
                    end)
                    self.m_shopView:updateLockView()
                else
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    local pageIndex
                    if selfData and selfData.lastBuy then
                        pageIndex = selfData.lastBuy[1] + 1
                        if pageIndex > 5 then
                            pageIndex = 5
                        end
                    end
                    -- local pageIndex = fsExtraData.buy + 1
                    self.m_shopView:showView(pageIndex,function()
                        self.m_shopView:showUnlockAni()
                    end)
                end
                
            end
        end
    end
end

function CodeGameScreenRobinIsHoodMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

    local winSize = display.size
    local mainScale = 1
    self.m_bgScale = 1

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

    elseif ratio >=  920 / 768 and ratio < 1152 / 768 then --920
        mainScale = 0.6
        mainPosY  = mainPosY + 35
        self:findChild("bg"):setScale(1.2)
        self.m_bgScale = 1.2

    elseif ratio >= 1152 / 768 and ratio < 1228 / 768 then --1152
        mainScale = 0.8
        mainPosY  = mainPosY + 21
    elseif ratio >= 1228 / 768 and ratio < 1368 / 768 then --1228
        mainScale = 0.86
        mainPosY  = mainPosY + 20
    else --1370以上
        mainScale = 1
        mainPosY  = mainPosY + 10
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

return CodeGameScreenRobinIsHoodMachine






