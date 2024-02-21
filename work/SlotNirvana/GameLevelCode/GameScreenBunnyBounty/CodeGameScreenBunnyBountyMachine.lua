---
-- island li
-- 2019年1月26日
-- CodeGameScreenBunnyBountyMachine.lua
-- 
-- 玩法：
-- 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "BunnyBountyPublicConfig"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenBunnyBountyMachine = class("CodeGameScreenBunnyBountyMachine", BaseReelMachine)

CodeGameScreenBunnyBountyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2

CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- Bonus1
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- Bonus2
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3  -- Bonus3
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_LINK_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4  -- Link1
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_LINK_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5  -- Link2
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_LINK_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6  -- Link3
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  -- 空图标
CodeGameScreenBunnyBountyMachine.SYMBOL_SCORE_LINK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- 假滚link

CodeGameScreenBunnyBountyMachine.EFFECT_COLLECT_COIN_OR_TIMES       = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集bonus上的free次数和金币
CodeGameScreenBunnyBountyMachine.EFFECT_COLLECT_BONUS               = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集动效

-- 构造函数
function CodeGameScreenBunnyBountyMachine:ctor()
    CodeGameScreenBunnyBountyMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_maxRowCount = 3
    self.m_respinReelDownSound = {}

    --大赢光效
    self.m_isAddBigWinLightEffect = true

    self.m_isBonusEnd = false
 
    --init
    self:initGame()
end

function CodeGameScreenBunnyBountyMachine:initGameStatusData(gameData)
    CodeGameScreenBunnyBountyMachine.super.initGameStatusData(self, gameData)

    local extraData = gameData.gameConfig.extra
    if extraData then
        self.m_progerssConfig = extraData.bonusProgressInit
    else
        self.m_progerssConfig = {
            ["94"] = {5,10},
            ["95"] = {15,30},
            ["96"] = {10,25}
        }
    end
end

--[[
    获取所有收集等级
]]
function CodeGameScreenBunnyBountyMachine:getCollectLevels()
    local levels = {1,1,1}
    local temp = {self.SYMBOL_SCORE_BONUS_1,self.SYMBOL_SCORE_BONUS_2,self.SYMBOL_SCORE_BONUS_3}
    for index = 1,3 do
        local level = self:getCollectLevelBySymbolType(temp[index])
        levels[index] = level
    end
    return levels
end

--[[
    根据信号获取收集等级
]]
function CodeGameScreenBunnyBountyMachine:getCollectLevelBySymbolType(symbolType)
    local features = self.m_runSpinResultData.p_features or {}
    local targetFeature,levelConfig
    if symbolType == self.SYMBOL_SCORE_BONUS_1 then
        targetFeature = SLOTO_FEATURE.FEATURE_FREESPIN
    elseif symbolType == self.SYMBOL_SCORE_BONUS_2 and not self.m_isEnter and not self.m_isBonusEnd then 
        targetFeature = SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER
    elseif symbolType == self.SYMBOL_SCORE_BONUS_3 then
        targetFeature = SLOTO_FEATURE.FEATURE_RESPIN
    end

    local levelConfig = self.m_progerssConfig[tostring(symbolType)]

    if targetFeature then
        for index = 1, #features do 
            local featureId = features[index]
            if featureId == targetFeature then
                return 3
            end
        end
    end
    

    local selfData = self.m_runSpinResultData.p_selfMakeData
    --收集bonus1的时候检测是否触发了respin且respin是否升行
    if symbolType == self.SYMBOL_SCORE_BONUS_1 then
        if self:checkTriggerRespinAndFreeSpin() then
            return 3
        end
    end

    
    if selfData and selfData.bonusProgress and levelConfig then
        local collectCount = selfData.bonusProgress["bonus"..symbolType] or 0
        if collectCount >= levelConfig[1] and collectCount < levelConfig[2] then
            return 2
        elseif collectCount >= levelConfig[2] then
            return 3
        end
    end

    return 1
end

--[[
    是否为respin触发
]]
function CodeGameScreenBunnyBountyMachine:checkTriggerRespin()
    local features = self.m_runSpinResultData.p_features
    if not features then
        return false
    end

    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_RESPIN then
            return true
        end
    end

    return false
end

--[[
    检测是否触发free
]]
function CodeGameScreenBunnyBountyMachine:checkTriggerFree()
    local features = self.m_runSpinResultData.p_features or {}
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

--[[
    检测respin和freespin是否同时触发
]]
function CodeGameScreenBunnyBountyMachine:checkTriggerRespinAndFreeSpin()
    local features = self.m_runSpinResultData.p_features or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local curRsCount = self.m_runSpinResultData.p_reSpinCurCount or 0
    --收集bonus1的时候检测是否触发了respin且respin是否升行
    if curRsCount > 0 and selfData and selfData.reelsMode and tonumber(selfData.reelsMode) > 3 then
        return true
    end
    return false
end

--[[
    检测是否同时触发所有玩法
]]
function CodeGameScreenBunnyBountyMachine:checkTriggerAll()
    local triggers = {}
    local features = self.m_runSpinResultData.p_features or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if features then
        for index = 1, #features do 
            local featureId = features[index]
            if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                triggers[#triggers + 1] = self.SYMBOL_SCORE_BONUS_2
            elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then
                triggers[#triggers + 1] = self.SYMBOL_SCORE_BONUS_3
                if selfData and selfData.reelsMode and tonumber(selfData.reelsMode) > 3 then
                    triggers[#triggers + 1] = self.SYMBOL_SCORE_BONUS_1
                end
            elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN then --free和respin同时触发时不会发回free的feature
                triggers[#triggers + 1] = self.SYMBOL_SCORE_BONUS_1
            end
        end
    end


    return triggers
end



function CodeGameScreenBunnyBountyMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBunnyBountyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BunnyBounty"  
end

function CodeGameScreenBunnyBountyMachine:getReelNode()
    return "CodeBunnyBountySrc.BunnyBountyReelNode"
end

-- 继承底层respinView
function CodeGameScreenBunnyBountyMachine:getRespinView()
    return "CodeBunnyBountySrc.BunnyBountyRespinView"
end

-- 继承底层respinNode
function CodeGameScreenBunnyBountyMachine:getRespinNode()
    return "CodeBunnyBountySrc.BunnyBountyRespinNode"
end

function CodeGameScreenBunnyBountyMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("CodeBunnyBountySrc.BunnyBountyFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenBunnyBountyMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    if self.m_maxRowCount > 3 then
        -- 
        local posNode = self:findChild("Node_freebar_"..self.m_maxRowCount.."X5")
        self.m_baseFreeSpinBar:setPosition(cc.p(posNode:getPosition()))
    end
end

function CodeGameScreenBunnyBountyMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

--[[
    判断是否为bonus小块(需要在子类重写)
]]
function CodeGameScreenBunnyBountyMachine:isFixSymbol(symbolType)
    if not symbolType then
        util_printLog("CodeGameScreenBunnyBountyMachine:isFixSymbol 信号值为空",true)
        return false
    end

    if symbolType == self.SYMBOL_SCORE_BONUS_1 then
        return true
    end
    if symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return true
    end
    if symbolType == self.SYMBOL_SCORE_BONUS_3 then
        return true
    end
    
    return false
end

--[[
    判断是否为Link小块
]]
function CodeGameScreenBunnyBountyMachine:isLinkSymbol(symbolType)
    if not symbolType then
        util_printLog("CodeGameScreenBunnyBountyMachine:isLinkSymbol 信号值为空",true)
        return false
    end
    if symbolType == self.SYMBOL_SCORE_LINK_1 then
        return true
    end
    if symbolType == self.SYMBOL_SCORE_LINK_2 then
        return true
    end
    if symbolType == self.SYMBOL_SCORE_LINK_3 then
        return true
    end

    if symbolType == self.SYMBOL_SCORE_LINK then
        return true
    end
    
    return false
end


--[[
    初始化背景
]]
function CodeGameScreenBunnyBountyMachine:initMachineBg()
    local gameBg = util_spineCreate("GameScreenBunnyBountyBg",true,true)
    local bgNode = self:findChild("bg")

    bgNode:addChild(gameBg)
    self.m_gameBg = gameBg

    self.m_bgParticle = util_createAnimation("BunnyBounty/GameScreenBunnyBountyBg.csb") 
    bgNode:addChild(self.m_bgParticle)
    
end

--[[
    修改背景动画
]]
function CodeGameScreenBunnyBountyMachine:changeBgAni(aniType)
    if aniType == "base" then
        util_spinePlay(self.m_gameBg,"Bace",true)
        self.m_bgParticle:setVisible(false)
        self.m_reel_bg_3x5:findChild("Node_free_reel"):setVisible(false)
    elseif aniType == "free" then
        util_spinePlay(self.m_gameBg,"Free",true)
        self.m_bgParticle:setVisible(false)
        self.m_reel_bg_3x5:findChild("Node_free_reel"):setVisible(true)
    elseif aniType == "respin" then
        util_spinePlay(self.m_gameBg,"respin",true)
        self.m_bgParticle:setVisible(false)
        self.m_reel_bg_3x5:findChild("Node_free_reel"):setVisible(true)
    elseif aniType == "bonus" then
        self.m_bgParticle:setVisible(true)
    end
end

--[[
    base下UI是否显示
]]
function CodeGameScreenBunnyBountyMachine:setBaseReelShow(isShow)
    self:findChild("node_main"):setVisible(isShow)
end

function CodeGameScreenBunnyBountyMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_effectNode:setScale(self.m_machineRootScale)

    self.m_effectNode2 = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode2)

    --收集条
    self.m_collectBar = util_createView("CodeBunnyBountySrc.BunnyBountyCollectBar",{machine = self})
    self:findChild("Node_collect"):addChild(self.m_collectBar)
    
   
    --创建轮盘背景
    --3x5轮盘背景
    self.m_reel_bg_3x5 = util_createAnimation("BunnyBounty_Node_reel_3X5.csb")
    self:findChild("Node_reel"):addChild(self.m_reel_bg_3x5)
    self.m_reel_bg_3x5:findChild("Node_free_reel"):setVisible(false)

    --4x5轮盘背景
    self.m_reel_bg_4x5 = util_createAnimation("BunnyBounty_Node_reel_4X5.csb")
    self:findChild("Node_reel"):addChild(self.m_reel_bg_4x5)
    --5x5轮盘背景
    self.m_reel_bg_5x5 = util_createAnimation("BunnyBounty_Node_reel_5X5.csb")
    self:findChild("Node_reel"):addChild(self.m_reel_bg_5x5)
    --6x5轮盘背景
    self.m_reel_bg_6x5 = util_createAnimation("BunnyBounty_Node_reel_6X5.csb")
    self:findChild("Node_reel"):addChild(self.m_reel_bg_6x5)

    --jackpotBar
    self.m_jackpotBar = util_createView("CodeBunnyBountySrc.BunnyBountyJackPotBarView",{machine = self})
    self:findChild("Node_base_jackpot"):addChild(self.m_jackpotBar)

    --free提示板
    self.m_free_tip = util_createAnimation("BunnyBounty_free_tishi.csb")
    self:findChild("Node_free_tishi"):addChild(self.m_free_tip)
    self.m_free_tip:setVisible(false)

    --respin赢钱板
    self.m_totalWin_respin = util_createAnimation("BunnyBounty_respin_totalwin.csb")
    self:findChild("Node_respintotalwin"):addChild(self.m_totalWin_respin)
    self.m_totalWin_respin:setVisible(false)

    --respinBar
    self.m_respinbar = util_createView("CodeBunnyBountySrc.BunnyBountyRespinBar",{machine = self.m_machine})
    self:findChild("Node_respinbar"):addChild(self.m_respinbar)
    self.m_respinbar:setVisible(false)
    

    --多福多彩
    self.m_colorfulGameView = util_createView("CodeBunnyBountySrc.BunnyBountyColorfulGame",{machine = self})
    self:findChild("root"):addChild(self.m_colorfulGameView)
    self.m_colorfulGameView:setVisible(false)
end


function CodeGameScreenBunnyBountyMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_BunnyBounty_enter_game)
    end)
end

function CodeGameScreenBunnyBountyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "BunnyBounty_totalwin.csb")
    local respinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --respin断线重连显示触发的轮盘
    if respinCurCount and respinCurCount > 0 and selfData and selfData.reSpinTriggerReels then
        self.m_runSpinResultData.p_reels = selfData.reSpinTriggerReels
        local extraData = self.m_runSpinResultData.p_rsExtraData
        if extraData.resultStoredIcons then
            self.m_runSpinResultData.p_storedIcons = extraData.resultStoredIcons
        end
    end
    
    self.m_isEnter = true
    CodeGameScreenBunnyBountyMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --收集等级
    local levels = self:getCollectLevels()
    self.m_collectBar:initCollectLevel(levels)
    
    --变更对应轮盘背景
    self:changeCurReelBg()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeSpinUI()
    else
        self:changeBgAni("base")      
        self.m_collectBar:resumeSpinIdle()
    end

    self.m_isEnter = false
end

--[[
    修改当前轮盘背景
]]
function CodeGameScreenBunnyBountyMachine:changeCurReelBg()
    
    --将提层的图标放回去
    self:checkChangeBaseParent()
    --获取当前最大行数
    self:getCurMaxRowCount()

    local posNode = self:findChild("Node_respintotalwin_"..self.m_maxRowCount.."x5")
    if posNode then
        local pos = cc.p(posNode:getPosition()) 
        self.m_totalWin_respin:setPosition(pos)
    end
    

    self.m_reel_bg_3x5:setVisible(self.m_maxRowCount == 3)
    self.m_reel_bg_4x5:setVisible(self.m_maxRowCount == 4)
    self.m_reel_bg_5x5:setVisible(self.m_maxRowCount == 5)
    self.m_reel_bg_6x5:setVisible(self.m_maxRowCount == 6)

    --变更裁切层大小
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetHight = self.m_SlotNodeH * self.m_maxRowCount

        reelNode:changClipSizeWithoutAni(targetHight, true)
    end

    self.m_iReelRowNum = self.m_maxRowCount
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    self:changeTouchSpinLayerSize()
    
end

--[[
    获取当前的最大行数
]]
function CodeGameScreenBunnyBountyMachine:getCurMaxRowCount()
    self.m_maxRowCount = 3
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.reelsMode then
        self.m_maxRowCount = tonumber(selfData.reelsMode) 
    end

end

function CodeGameScreenBunnyBountyMachine:addObservers()
    CodeGameScreenBunnyBountyMachine.super.addObservers(self)
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

        local soundName = PublicConfig.SoundConfig["sound_BunnyBounty_win_lines_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_BunnyBounty_win_lines_free_"..soundIndex] 
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenBunnyBountyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBunnyBountyMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenBunnyBountyMachine:getBounsScatterDataZorder(symbolType)
    local symbolOrder = CodeGameScreenBunnyBountyMachine.super.getBounsScatterDataZorder(self, symbolType)

    if self:isFixSymbol(symbolType) or self:isLinkSymbol(symbolType) then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
    end

    return symbolOrder
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBunnyBountyMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BunnyBounty_10"
    end
    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_BunnyBounty_11"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS_1 then
        return "Socre_BunnyBounty_Bonus1"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return "Socre_BunnyBounty_Bonus2"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS_3 then
        return "Socre_BunnyBounty_Bonus3"
    end
    if symbolType == self.SYMBOL_SCORE_LINK_1 then
        return "Socre_BunnyBounty_Link1"
    end
    if symbolType == self.SYMBOL_SCORE_LINK_2 then
        return "Socre_BunnyBounty_Link2"
    end
    if symbolType == self.SYMBOL_SCORE_LINK_3 then
        return "Socre_BunnyBounty_Link3"
    end

    if symbolType == self.SYMBOL_SCORE_LINK then
        return "Socre_BunnyBounty_Link"
    end
    if symbolType == self.SYMBOL_SCORE_EMPTY then
        return "Socre_BunnyBounty_Empty"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBunnyBountyMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBunnyBountyMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenBunnyBountyMachine:MachineRule_initGame(  )
    
    
end

--
--单列滚动停止回调
--
function CodeGameScreenBunnyBountyMachine:slotOneReelDown(reelCol)    
    CodeGameScreenBunnyBountyMachine.super.slotOneReelDown(self,reelCol) 
    if reelCol == 1 then
        -- self:hideBlackLayer()
    end
    
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBunnyBountyMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBunnyBountyMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关

--[[
    显示free相关UI
]]
function CodeGameScreenBunnyBountyMachine:showFreeSpinUI()
    self:showFreeSpinBar()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

    self.m_free_tip:setVisible(true)
    local freeTipNode = self:findChild("Node_free_tishi_"..self.m_maxRowCount.."x5")
    if freeTipNode then
        self.m_free_tip:setPosition(cc.p(freeTipNode:getPosition()))
    end

    self.m_collectBar:showFreeCollectBar()

    self:changeBgAni("free")

    self.m_jackpotBar:setVisible(self.m_iReelRowNum <= 4)

end

--[[
    隐藏free相关UI
]]
function CodeGameScreenBunnyBountyMachine:hideFreeSpinUI()
    self.m_free_tip:setVisible(false)
    self.m_collectBar:showBaseCollectBar()
    self.m_jackpotBar:setVisible(true)

    self:hideFreeSpinBar()

    --收集等级
    local levels = self:getCollectLevels()
    self.m_collectBar:initCollectLevel(levels)
    self.m_collectBar:resumeSpinIdle()
    self:changeBgAni("base")
end

---
-- 显示free spin
function CodeGameScreenBunnyBountyMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    

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

    
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

--[[
    free触发动画
]]
function CodeGameScreenBunnyBountyMachine:runFreeTriggerAni(func)
    self.m_collectBar:runTriggerAni(self.SYMBOL_SCORE_BONUS_1,"free",function()
        self.m_collectBar:runRabbitTrigger("free",function()
            if type(func) == "function" then
                func()
            end
            
        end)
    end)
end

-- FreeSpinstart
function CodeGameScreenBunnyBountyMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BunnyBountySounds/music_BunnyBounty_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end

            self:runFreeTriggerAni(function()
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()
                    self:changeCurReelBg()
                    self:showFreeSpinUI()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end)
            end)
            
        end
    end

    self:delayCallBack(0.5,function()

        showFSView()    
    end)
end

--[[
    过场动画(free)
]]
function CodeGameScreenBunnyBountyMachine:changeSceneToFree(keyFunc,endFunc)
    local spine = util_spineCreate("Socre_BunnyBounty_Bonus1",true,true)
    self:addChild(spine,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    spine:setPosition(display.center)

    util_spinePlay(spine,"actionframe_guochang1")
    util_spineEndCallFunc(spine,"actionframe_guochang1",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(18 / 30,keyFunc)
end

function CodeGameScreenBunnyBountyMachine:showFreeSpinStart(num, func, isAuto)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local rowCount = tonumber(selfData.reelsMode) 
    local ownerlist = {}
    ownerlist["m_lb_num_1"] = num
    ownerlist["m_lb_num_2"] = rowCount

    local view = util_createView("CodeBunnyBountySrc.BunnyBountyFreeStartView",{
        machine = self,
        ownerlist = ownerlist,
        scale = self.m_machineRootScale,
        func = func,
    })

    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- view:setPosition(display.center)

    return view
end

function CodeGameScreenBunnyBountyMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("BunnyBountySounds/music_BunnyBounty_over_fs.mp3")
    self:clearWinLineEffect()

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        self:hideFreeSpinUI()

        self:changeCurReelBg()
    end,function()
        self:triggerFreeSpinOverCallFun()
    end)
    

    if view:findChild("root") then
        view:findChild("root"):setScale(self.m_machineRootScale)
    end

end

function CodeGameScreenBunnyBountyMachine:showFreeSpinOver(coins, num, keyFunc,endFunc)
    self:clearCurMusicBg()
    local ownerlist = {}
    if globalData.slotRunData.lastWinCoin == 0 then
        local view = self:showDialog("NoWin", ownerlist, function()
            self:changeSceneToFree(function()
                if type(keyFunc) == "function" then
                    keyFunc()
                end
            end,function()
                if type(endFunc) == "function" then
                    endFunc()
                end
            end)
        end)
        return view
    else
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)

        local view = util_createView("CodeBunnyBountySrc.BunnyBountyFreeOverView",{
            machine = self,
            ownerlist = ownerlist,
            scale = self.m_machineRootScale,
            keyFunc = keyFunc,
            endFunc = endFunc
        })
    
        self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        return view
    end
    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBunnyBountyMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   
    self.m_isBonusEnd = false

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function CodeGameScreenBunnyBountyMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()

    if isFiveOfKind and self.m_isAllLineType then
        self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

function CodeGameScreenBunnyBountyMachine:beginReel()
    CodeGameScreenBunnyBountyMachine.super.beginReel(self)
    -- self:showBlackLayer()
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBunnyBountyMachine:addSelfEffect()

    if self:checkHasBonusOnReel() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_COLLECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_COLLECT_BONUS -- 动画类型
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.coinOrFreeSpinTimesLists and #selfData.coinOrFreeSpinTimesLists > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_COLLECT_COIN_OR_TIMES
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_COLLECT_COIN_OR_TIMES -- 动画类型
    end

end

--[[
    检测轮盘上是否有bonus图标
]]
function CodeGameScreenBunnyBountyMachine:checkHasBonusOnReel()
    local reels = self.m_runSpinResultData.p_reels or {}
    for iRow = 1,#reels do
        local rowData = reels[iRow] or {}
        for iCol = 1,#rowData do
            if rowData[iCol] and self:isFixSymbol(rowData[iCol]) then
                return true
            end
        end
    end

    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBunnyBountyMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_COLLECT_BONUS then
        
        --收集bonus
        self:collectBonusAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        

    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_COIN_OR_TIMES then
        local callBack = function()
            --收集bonus上的金币和free次数
            self:collectCoinsAndFreeTimes(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end
        if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop then
            self:delayCallBack(15 / 30,function()
                callBack()
            end)
        else
            callBack()
        end
        
    end

    
    return true
end

--[[
    收集bonus上的金币和free次数
]]
function CodeGameScreenBunnyBountyMachine:collectCoinsAndFreeTimes(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.coinOrFreeSpinTimesLists then
        if type(func) == "function" then
            func()
        end
        return
    end

    local list = selfData.coinOrFreeSpinTimesLists

    self:collectFreeTimes(list,function()
        self:collectCoinsInFree(list,func)
    end)
    
end

--[[
    收集free次数
]]
function CodeGameScreenBunnyBountyMachine:collectFreeTimes(list,func)
    local isNeedCollect = false
    for index = 1,#list do
        if list[index][3] ~= "coins" then
            local data = list[index]
            isNeedCollect = true
            local symbolNode = self:getSymbolByPosIndex(data[1])
            if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                symbolNode:runAnim("shouji2")
                self:delayCallBack(5 / 30,function()
                    --小块上的ui隐藏
                    self:getCsbNodeOnBonus2(symbolNode)
                    local flyNode = util_createAnimation("BunnyBounty_Bonus_addspin.csb")
                    self.m_effectNode:addChild(flyNode)
                    for iCount = 1,2 do
                        if flyNode:findChild("sp_addTimes_"..iCount) then
                            flyNode:findChild("sp_addTimes_"..iCount):setVisible(iCount == data[2])
                        end
                    end
                    self:flyNodeAni(flyNode,symbolNode,self.m_baseFreeSpinBar:findChild("m_lb_num_2"))
                end)
            end
        end
    end

    if isNeedCollect then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_bonus_to_win_coins)
        self:delayCallBack(50 / 60,function()
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            self.m_baseFreeSpinBar:runAddCountAni()
            if type(func) == "function" then
                func()
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    收集金币数
]]
function CodeGameScreenBunnyBountyMachine:collectCoinsInFree(list,func)
    local isNeedCollect = false
    local winCoins = 0
    for index = 1,#list do
        if list[index][3] == "coins" then
            local data = list[index]
            isNeedCollect = true
            winCoins = winCoins + data[2]
            local symbolNode = self:getSymbolByPosIndex(data[1])
            if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
                
                symbolNode:runAnim("shouji2")
                self:delayCallBack(5 / 30,function()
                    --小块上的ui隐藏
                    self:getCsbNodeOnBonus2(symbolNode)
                    local flyNode = util_createAnimation("BunnyBounty_Bonus_addcoins.csb")
                    self.m_effectNode:addChild(flyNode)
                    local m_lb_coins = flyNode:findChild("m_lb_coins")
                    if m_lb_coins then
                        
                        m_lb_coins:setString(util_formatCoins(data[2],3))
                    end
                    self:flyNodeAni(flyNode,symbolNode,self.m_bottomUI.coinWinNode)
                end)
            end
        end
    end

    if isNeedCollect then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_bonus_to_win_coins)
        self:delayCallBack(50 / 60,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_bonus_to_win_coins_feed_back)
            local effectNode = self.m_bottomUI.coinBottomEffectNode
            if effectNode and effectNode:findChild("m_lb_coins") then
                effectNode:findChild("m_lb_coins"):setString("+"..util_getFromatMoneyStr(winCoins))
            end
            self:playCoinWinEffectUI()

            local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins
            local winAmount = self.m_runSpinResultData.p_winAmount
            local curCoins = fsWinCoins - winAmount + winCoins
            self.m_iOnceSpinLastWin = winAmount - winCoins
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curCoins))
            if type(func) == "function" then
                func()
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--播放
function CodeGameScreenBunnyBountyMachine:playCoinWinEffectUI(callBack)
    self.m_bottomUI:playCoinWinEffectUI(callBack)
    local effectNode = self.m_bottomUI.coinBottomEffectNode
    if effectNode then
        for index = 1,2 do
            local particle = effectNode:findChild("Particle_"..index)
            if particle then
                particle:resetSystem()
            end
        end
    end
end

--[[
    飞行动画(free中)
]]
function CodeGameScreenBunnyBountyMachine:flyNodeAni(flyNode,startNode,endNode,func)
    if not flyNode then
        if type(func) == "function" then
            func()
        end
        return
    end

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)

    local actionList = {
        cc.DelayTime:create(20 / 60),
        cc.EaseQuadraticActionIn:create(cc.MoveTo:create(25 / 60,endPos)),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.Hide:create(),
        cc.DelayTime:create(0.1),
        cc.RemoveSelf:create()
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("shouji")
end

--[[
    收集bonus
]]
function CodeGameScreenBunnyBountyMachine:collectBonusAni(func)
    local features = self.m_runSpinResultData.p_features
    local isTrigger = features and #features > 1

    local levelUpIndex = -1

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_bonus)
    for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
            local symbolType = symbolNode.p_symbolType
            --收集等级
            local level = self:getCollectLevelBySymbolType(symbolType)
            local endNode = self.m_collectBar:getBarItemBySymbolType(symbolNode.p_symbolType)
            --判断是否升级,播放音效 优先级 1升3 > 2升3 > 1升2
            if level == 3 and endNode.m_level == 1 and levelUpIndex < 3 then
                levelUpIndex = 3
            elseif level == 3 and endNode.m_level == 2 and levelUpIndex < 2 then
                levelUpIndex = 2
            elseif level == 2 and endNode.m_level == 1 and levelUpIndex < 1 then
                levelUpIndex = 1
            end
            self:flyBonusAni(symbolType,symbolNode,endNode,function()
                self.m_collectBar:runCollectAni(symbolType,level,isTrigger)
            end)
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:checkTriggerFree() then
        isTrigger = false
    end

    

    self:delayCallBack(0.6,function()
        if levelUpIndex ~= -1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_BunnyBounty_collect_bar_rise_"..levelUpIndex])
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_bonus_feed_back)
        end
        
    end)

    if isTrigger then
        self:delayCallBack(40 / 30,func)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    bonus飞行动画
]]
function CodeGameScreenBunnyBountyMachine:flyBonusAni(symbolType,startNode,endNode,func)
    local symbolName = self:getSymbolCCBNameByType(self,symbolType)
    local flyNode = util_spineCreate(symbolName,true,true)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        endPos.y  = endPos.y + 80
        if symbolType == self.SYMBOL_SCORE_BONUS_1 then
            endPos.x  = endPos.x - 180
        elseif symbolType == self.SYMBOL_SCORE_BONUS_2 then
            endPos.x  = endPos.x + 180
        elseif symbolType == self.SYMBOL_SCORE_BONUS_3 then
            endPos.y  = endPos.y + 180
        end
    end
    
    local topPos = cc.p((startPos.x + endPos.x) / 2,math.max(startPos.y,endPos.y) + 600)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    local actionList = {
        cc.EaseSineIn:create(cc.BezierTo:create(0.6,{startPos, topPos, endPos})),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.Hide:create(),
        cc.DelayTime:create(0.1),
        cc.RemoveSelf:create()
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    util_spinePlay(flyNode,"shouji")
end


--[[
    bonus玩法
]]
function CodeGameScreenBunnyBountyMachine:showEffect_Bonus(effectData)
    local isLevelUp,lastJackpot = self:checkIsLevelUp()
    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    local multi = 1
    if string.lower(jackpotType) == "grand" and isLevelUp and string.lower(lastJackpot) == "grand" then
        multi = 2
    end

    local endFunc = function()
        if winCoins > 0 then
            self:showJackpotView(winCoins,jackpotType,multi,true,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    --断线重连回来只显示jackpot弹板
    if self.m_isEnter then
        endFunc()
        
        return true
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.cards then
        util_printLog("CodeGameScreenBunnyBountyMachine bonus数据异常",true)
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end

    self:clearCurMusicBg()

    self:clearWinLineEffect()
    
    local bonusData = {
        rewardList = selfData.cards,
        isLevelUp = isLevelUp,
        winJackpot = jackpotType
    }

    if not self:checkHasBigWin() then
        self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
    end
    

    --重置bonus界面
    self.m_colorfulGameView:resetView(bonusData,function()
        self:showJackpotView(winCoins,jackpotType,multi,false,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_scene_to_base_from_bonus)
            self:changeSceneToBonus(function()
                self:setBaseReelShow(true)
                self.m_isBonusEnd = true
                --重置收集进度
                local levels = self:getCollectLevels()
                self.m_collectBar:initCollectLevel(levels)
                
                --兔子idle
                self.m_collectBar:resumeSpinIdle()

                local params = {self.m_iOnceSpinLastWin, true}
                params[self.m_stopUpdateCoinsSoundIndex] = true

                --通知赢钱
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                
                self.m_colorfulGameView:hideView()
                
            end,function()
                self:resetMusicBg()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            
        end)
    end)
    

    self:delayCallBack(0.1,function()
        self:showBonusView()
    end)
    
    return true
end

--[[
    显示bonus界面
]]
function CodeGameScreenBunnyBountyMachine:showBonusView()
    local triggers = self:checkTriggerAll() 
    local triggerType = "bonus"
    if #triggers >= 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_trigger_all)
        triggerType = "triggerAll"
    end

    for index = 1,#triggers do
        if triggers[index] ~= self.SYMBOL_SCORE_BONUS_2 then
            self.m_collectBar:runExtraTriggerAni(triggers[index])
        end
    end

    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    --收集条播触发
    self.m_collectBar:runTriggerAni(self.SYMBOL_SCORE_BONUS_2,triggerType,function()
        --兔子扔蛋
        self.m_collectBar:runRabbitTrigger("bonus",function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_scene_to_bonus)
            --过场动画
            self:changeSceneToBonus(function()
                self:resetMusicBg(true,"BunnyBountySounds/music_BunnyBounty_bonus.mp3")
                self.m_colorfulGameView:showView()
                self:setBaseReelShow(false)
            end)
        end)
    end)
end

--[[
    过场动画(bonus)
]]
function CodeGameScreenBunnyBountyMachine:changeSceneToBonus(keyFunc,endFunc)
    local spine = util_spineCreate("Socre_BunnyBounty_Bonus2",true,true)
    self:addChild(spine,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    spine:setPosition(display.center)

    util_spinePlay(spine,"actionframe_guochang1")
    util_spineEndCallFunc(spine,"actionframe_guochang1",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(18 / 30,keyFunc)
end

--[[
    检测是否是jackpot升级
]]
function CodeGameScreenBunnyBountyMachine:checkIsLevelUp()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.cards then
        return false
    end
    local list = selfData.cards
    local count = 0
    local jackpotCount = {}
    for index = 1,#list do
        if list[index] == "levelUp" then
            count = count + 1
        end
    end

    return count >= 3,list[#list]
end

--[[
    获取jackpot类型及赢得的金币数
]]
function CodeGameScreenBunnyBountyMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0
end

function CodeGameScreenBunnyBountyMachine:showColorfunGameView(func)
    self.m_colorfulGameView:resetView(nil,func)
    self.m_colorfulGameView:showView()
end

--[[
    显示jackpot弹板
]]
function CodeGameScreenBunnyBountyMachine:showJackpotView(coins,jackpotType,multi,isReconnect,func)
    local view = util_createView("CodeBunnyBountySrc.BunnyBountyJackPotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        multi = multi,
        isReconnect = isReconnect,
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

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBunnyBountyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenBunnyBountyMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenBunnyBountyMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenBunnyBountyMachine:delaySlotReelDown()
    CodeGameScreenBunnyBountyMachine.super.delaySlotReelDown(self)
    self:checkChangeBonusOrder()
    self:sortGameEffects()
end

--[[
    修改bonus事件顺序
]]
function CodeGameScreenBunnyBountyMachine:checkChangeBonusOrder()
    --检测是否有bonus
    for index = 1, #self.m_gameEffects do
        local effectData = self.m_gameEffects[index]
        --bonus玩法要在连线之前
        if effectData.p_effectType == GameEffect.EFFECT_BONUS then
            effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 10
            return
        end
    end
end

function CodeGameScreenBunnyBountyMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenBunnyBountyMachine.super.slotReelDown(self)

    
end

function CodeGameScreenBunnyBountyMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


--[[
    检测播放落地动画
]]
function CodeGameScreenBunnyBountyMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                --提层
                if symbolCfg[1] then
                    self:changeSymbolToClipParent(symbolNode)

                    --回弹
                    local actList = {}
                    local moveTime = self.m_configData.p_reelResTime
                    local dis = self.m_configData.p_reelResDis
                    local pos = cc.p(symbolNode:getPosition())
                    local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                    local action2 = cc.MoveTo:create(moveTime / 2,pos)
                    actList = {action1,action2}
                    symbolNode:runAction(cc.Sequence:create(actList))
                end

                --2.播落地动画
                symbolNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(symbolNode)
                    end
                )

                --bonus落地音效
                if self:isFixSymbol(symbolNode.p_symbolType) then
                    self:checkPlayBonusDownSound(colIndex)
                end
            end
            
        end
    end
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenBunnyBountyMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_bonus_down)
end

--[[
    落地动画后回调
]]
function CodeGameScreenBunnyBountyMachine:symbolBulingEndCallBack(symbolNode)
    if not tolua.isnull(symbolNode) then
        symbolNode:runMixAni("idleframe2",true)
    end
end

----------------------------respin----------------------------------------
--[[
    respin触发动画
]]
function CodeGameScreenBunnyBountyMachine:triggerRespinAni(func)

    self:delayCallBack(0.1,function()
        --检测是否同时触发
        local triggerType = "respin"
        if self:checkTriggerRespinAndFreeSpin() then
            triggerType = "fsAndRs"
            self.m_collectBar:runTriggerAni(self.SYMBOL_SCORE_BONUS_1,triggerType)
            
        end
        --收集条播触发
        self.m_collectBar:runTriggerAni(self.SYMBOL_SCORE_BONUS_3,triggerType,function()
            --兔子扔蛋
            self.m_collectBar:runRabbitTrigger(triggerType,function()
                if type(func) == "function" then
                    func()
                end
                
            end)
        end)
    end)
    
end



function CodeGameScreenBunnyBountyMachine:showReSpinStart(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local rowCount = 3
    if selfData and selfData.reelsMode then
        rowCount = tonumber(selfData.reelsMode) 
    end
    local ownerlist = {}

    local view = util_createView("CodeBunnyBountySrc.BunnyBountyRespinStartView",{
        machine = self,
        rowCount  = rowCount,
        ownerlist = ownerlist,
        scale = self.m_machineRootScale,
        func = func,
    })

    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    return view
end

--[[
    过场动画(respin)
]]
function CodeGameScreenBunnyBountyMachine:changeSceneToRespin(keyFunc,endFunc)
    local spine = util_spineCreate("Socre_BunnyBounty_Bonus3",true,true)
    self:addChild(spine,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    spine:setPosition(display.center)

    util_spinePlay(spine,"actionframe_guochang1")
    util_spineEndCallFunc(spine,"actionframe_guochang1",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(18 / 30,keyFunc)
end

--ReSpin开始改变UI状态
function CodeGameScreenBunnyBountyMachine:changeReSpinStartUI(respinCount)
    self:changeReSpinUpdateUI(respinCount,true)
    self:changeBgAni("respin")

    self.m_totalWin_respin:setVisible(true)
    self.m_totalWin_respin:runCsbAction("idle")
    self.m_collectBar:setVisible(false)
    
    self.m_jackpotBar:setVisible(self.m_iReelRowNum <= 4)
end

--ReSpin结算改变UI状态
function CodeGameScreenBunnyBountyMachine:changeReSpinOverUI()
    self:changeBgAni("base")
    self.m_totalWin_respin:setVisible(false)
    self.m_collectBar:setVisible(true)
    self.m_respinbar:setVisible(false)
    self.m_jackpotBar:setVisible(true)

    --收集等级
    local levels = self:getCollectLevels()
    self.m_collectBar:initCollectLevel(levels)

    self:changeCurReelBg()
end

--ReSpin刷新数量
function CodeGameScreenBunnyBountyMachine:changeReSpinUpdateUI(curCount,isInit)
    self.m_respinbar:updateCount(curCount,isInit)
end

--[[
    刷新respin赢钱
]]
function CodeGameScreenBunnyBountyMachine:updateRespinTotalWinCoins(multi)
    local m_lb_coins = self.m_totalWin_respin:findChild("m_lb_coins")
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet
    if score == 0 then
        score = ""
    else
        score = util_formatCoins(score,50)
    end
    
    m_lb_coins:setString(score)
    self:updateLabelSize({label=m_lb_coins,sx=1,sy=1},355)
end

---
-- 触发respin 玩法
--
function CodeGameScreenBunnyBountyMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        self:delayCallBack(0.5,function()
            self:showRespinView(effectData)
        end)
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

--[[
    显示respin界面
]]
function CodeGameScreenBunnyBountyMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_lightScore = 0
    self.m_curRespinMulti = 0

    local extraData = self.m_runSpinResultData.p_rsExtraData
    if extraData and extraData.totalWin then
        self.m_curRespinMulti = extraData.totalWin
    end

    self:updateRespinTotalWinCoins(self.m_curRespinMulti)

    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end

    --触发动画
    self:triggerRespinAni(function()
        
        local view = self:showReSpinStart(function()
            self:setCurrSpinMode(RESPIN_MODE)
            --修改行数
            self:changeCurReelBg()
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            
            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes( )
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()
    
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes) 
        end)
    end)
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenBunnyBountyMachine:getRespinRandomTypes( )
    local symbolList = {}
    for index = 1,2 do
        symbolList[index] = self.SYMBOL_SCORE_EMPTY
    end
    symbolList[#symbolList + 1] = self.SYMBOL_SCORE_LINK

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenBunnyBountyMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_SCORE_LINK_1, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_SCORE_LINK_2, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_SCORE_LINK_3, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

function CodeGameScreenBunnyBountyMachine:initRespinView(endTypes, randomTypes)
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
            self.m_respinView:setRespinNodeShow(false)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            local isTriggerRespin = self:checkTriggerRespin()
            if isTriggerRespin then
                self:delayCallBack(1,function()
                    self:throwEggAni(function()
                        self.m_respinbar:runStartAni()
                        self:runEggIdle()
                        self.m_respinView:setRespinNodeShow(true)
                        self:runNextReSpinReel()
                    end)
                end)
                
                
            else
                self.m_respinbar:runStartAni()
                self.m_respinView:setRespinNodeShow(true)
                self:runNextReSpinReel()
            end
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end


--[[
    抛蛋动画
]]
function CodeGameScreenBunnyBountyMachine:throwEggAni(func)
    local spine = util_spineCreate("BunnyBounty_juese",true,true)
    self.m_effectNode2:addChild(spine)

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,self.m_effectNode2)
    pos.y = pos.y + 120
    spine:setPosition(pos)

    local eggItems = {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons then
        for index,iconData in pairs(storedIcons) do
            local posIndex = iconData[1]
            local posData = self:getRowAndColByPos(posIndex)
            local respinNode = self.m_respinView:getRespinNodeByRowAndCol(posData.iY,posData.iX)
            if respinNode then
                local score = self:getReSpinSymbolScore(posIndex)
                local linkNode = util_spineCreate("Socre_BunnyBounty_Link1",true,true)
                local slotIndex = #eggItems + 1
                if slotIndex > 6 then
                    slotIndex = 6
                end
                eggItems[#eggItems + 1] = linkNode
                
                
                local node = cc.Node:create()
                
                node:addChild(linkNode)

                linkNode.parentNode = node
                linkNode.targetPosNode = respinNode
                linkNode.score = score
                linkNode:setVisible(false)

                util_spinePlay(linkNode,"idleframe")
                --将蛋绑到兔子上
                util_spinePushBindNode(spine,"guadian"..slotIndex,node)
            end
        end
        
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_throw_eggs)
    util_spinePlay(spine,"start_respin")
    util_spineFrameCallFunc(spine,"start_respin","dan",function()
        --抛蛋
        for index,linkNode in ipairs(eggItems) do
            linkNode:setVisible(true)
            local pos = util_convertToNodeSpace(linkNode.parentNode,self.m_effectNode2)
            util_changeNodeParent(self.m_effectNode2,linkNode)
            linkNode:setPosition(pos)
            self:flyLinkAni(linkNode,linkNode.targetPosNode,linkNode.score)
        end

        self:delayCallBack(33 / 30,function()
        
            if type(func) == "function" then
                func()
            end
        end)

    end,function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)
end
--[[
    link飞行动画
]]
function CodeGameScreenBunnyBountyMachine:flyLinkAni(flyNode,endNode,score,func)

    local startPos = util_convertToNodeSpace(flyNode,self.m_effectNode2)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode2)

    local labelCsb = util_createAnimation("BunnyBounty_link_shuzi.csb")
    util_spinePushBindNode(flyNode,"zi_guadian",labelCsb)
    self:updateLinkLblShow(labelCsb,self.SYMBOL_SCORE_LINK_3,score)

    local topPos = cc.p((startPos.x + endPos.x) / 2,math.max(startPos.y,endPos.y) + 500)

    local actionList = {
        cc.BezierTo:create(20 / 30,{startPos, topPos, endPos})
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    util_spinePlay(flyNode,"switchtoBonus")
    util_spineEndCallFunc(flyNode,"switchtoBonus",function()
        flyNode:setVisible(false)
        self:delayCallBack(0.1,function()
            flyNode:removeFromParent()
        end)
        if type(func) == "function" then
            func()
        end
    end)
end



----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenBunnyBountyMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = self.m_iReelRowNum
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getRespinPosSymbolType(iRow, iCol)
            if not self:isLinkSymbol(symbolType) then
                symbolType = self.SYMBOL_SCORE_EMPTY
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
            local slotNodeH = self.m_SlotNodeH
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

function CodeGameScreenBunnyBountyMachine:getRespinPosSymbolType(iRow, iCol)
    local extraData = self.m_runSpinResultData.p_rsExtraData
    local reels
    if self:checkTriggerRespin() then
        reels = extraData.preReels
    else
        reels = extraData.resultReels
    end

    if not reels then
        util_printLog("CodeGameScreenBunnyBountyMachine:getRespinPosSymbolType 轮盘数据错误",true)
        return self.SYMBOL_SCORE_EMPTY
    end
    
    local rowCount = #reels
    for rowIndex = 1, rowCount do
        local rowDatas = reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

---判断结算
function CodeGameScreenBunnyBountyMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self.m_respinReelDownSound = {}
    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()

    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
    end

    self:checkCollectLinkScore(function()
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false

            self:delayCallBack(1,function()
                --结束
                self:reSpinEndAction()
            end)
        else
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            --继续
            self:runNextReSpinReel()
        end
        
    end)
    
end

--[[
    检测是否需要收集link分数
]]
function CodeGameScreenBunnyBountyMachine:checkCollectLinkScore(func)
    local extraData = self.m_runSpinResultData.p_rsExtraData
    if extraData and extraData.addScoreList and #extraData.addScoreList > 0 then
        if extraData.resultStoredIcons then
            self.m_runSpinResultData.p_storedIcons = extraData.resultStoredIcons
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        local list = extraData.addScoreList
        self:delayCallBack(0.5,function()
            --收集bonus上的分数
            self:collectLinkScore(list,1,function()
                local extraData = self.m_runSpinResultData.p_rsExtraData
                if extraData and extraData.totalWin and extraData.totalWin ~= self.m_curRespinMulti then
                    util_printLog("倍数计算不一致",true)
                    self.m_curRespinMulti = extraData.totalWin
                    self:updateRespinTotalWinCoins(self.m_curRespinMulti)
                end
                if type(func) == "function" then
                    func()
                end
            end)
        end)
        
    else
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    把轮盘上的link2变为link3
]]
function CodeGameScreenBunnyBountyMachine:changeLink2ToLink3(symbolNode,func)
    if not symbolNode then
        if type(func) == "function" then
            func()
        end
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_link2_to_link3)
    symbolNode:runAnim("switchtoBonus",false,function()
        self:changeSymbolType(symbolNode,self.SYMBOL_SCORE_LINK_3,true)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    把轮盘上的link3变为link1
]]
function CodeGameScreenBunnyBountyMachine:changeLink3ToLink1(list,func)
    if not list then
        if type(func) == "function" then
            func()
        end
        return
    end
    local delayTime = 0
    for k,data in pairs(list) do
        if data.preSymbolType == self.SYMBOL_SCORE_LINK_3 then
            local posIndex = data.pos
            local posData = self:getRowAndColByPos(posIndex)
            local symbolNode = self.m_respinView:getSymbolByRowAndCol(posData.iY,posData.iX)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_LINK_3 then
                self:changeSymbolType(symbolNode,self.SYMBOL_SCORE_LINK_1,true)
                self:setLinkSymbolShow(symbolNode)
                local labelCsb = self:getLblCsbOnSymbol(symbolNode,"BunnyBounty_link_shuzi.csb","zi_guadian")
                if labelCsb then
                    labelCsb:setVisible(false)
                end
                self:delayCallBack(15/30,function()
                    if not tolua.isnull(labelCsb)  then
                        labelCsb:setVisible(true)
                    end
                end)
                symbolNode:runAnim("switchtoLink1",false,function()
                    
                end)
                delayTime = 30 / 30
            end
        end
    end
    if delayTime == 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_change_link3_to_link1)
    end

    self:delayCallBack(delayTime,func)
end

--[[
    收集bonus上的分数
]]
function CodeGameScreenBunnyBountyMachine:collectLinkScore(addList,index,func)
    if index > #addList then
        if type(func) == "function" then
            func()
        end
        self:runEggIdle()
        return
    end
    local data = addList[index]
    local posIndex = data.link2Pos
    local posData = self:getRowAndColByPos(posIndex)
    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(posData.iY,posData.iX)
    --当前倍数
    local curMulti = data.everyLink2WinCount
    --收集列表
    local collectList = data.collectList
    --排序
    util_bubbleSort(collectList,function(a,b)
        local pos1 = a.pos or 0
        local pos2 = b.pos or 0

        local posData1 = self:getRowAndColByPos(pos1)
        local posData2 = self:getRowAndColByPos(pos2)
        local iCol1,iRow1= posData1.iY,posData1.iX
        local iCol2,iRow2= posData2.iY,posData2.iX
        --升序排序 相同大小按索引排序
        return iCol1 < iCol2 or (iCol1 == iCol2 and iRow1 > iRow2)
    end)
    local symbolNode
    if respinNode then
        symbolNode = respinNode:getLockSymbolNode()
    end
    if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_LINK_2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_link2_trigger)
        symbolNode:runAnim("actionframe",false,function()
            symbolNode:runAnim("idleframe2",true)
            self:scaleNextLink1(collectList,1,function()
                self:collectNextLink(collectList,1,function()
                    --lin2变为link3
                    self:changeLink2ToLink3(symbolNode,function()
                        self:collectLinkScore(addList,index + 1,func)
                    end)
                    
                end)
            end)
        end)

        self:delayCallBack(24 / 30,function()
            --link3变为link1
            self:changeLink3ToLink1(collectList)
        end)
        
    else
        self.m_curRespinMulti  = self.m_curRespinMulti + curMulti
        self:updateRespinTotalWinCoins(self.m_curRespinMulti)
        self:collectLinkScore(addList,index + 1,func)

    end
end

--[[
    蛋托重新变成蛋
]]
function CodeGameScreenBunnyBountyMachine:resumeEggAni(list)
    for k,symbolNode in pairs(list) do
        symbolNode:runAnim("start")
    end
end

--[[
    蛋播idle
]]
function CodeGameScreenBunnyBountyMachine:runEggIdle()
    local respinNodeList = self.m_respinView.m_respinNodes
    for index,respinNode in ipairs(respinNodeList) do
        local symbolNode = respinNode:getLockSymbolNode()
        if symbolNode and self:isLinkSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("idleframe2",true)
        end
    end
end

--[[
    link1图标逐个放大
]]
function CodeGameScreenBunnyBountyMachine:scaleNextLink1(list,index,func)
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end

    local data = list[index]
    if not next(data) then
        self:scaleNextLink1(list,index + 1,func)
        return
    end
    local posIndex = data.pos
    local posData = self:getRowAndColByPos(posIndex)
    local symbolNode = self.m_respinView:getSymbolByRowAndCol(posData.iY,posData.iX)
    if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_LINK_1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_link1_scale)
        symbolNode:runAnim("actionframe",false,function()
            symbolNode:runAnim("idleframe4",true)
        end)
        self:delayCallBack(0.15,function()
            self:scaleNextLink1(list,index + 1,func)
        end)
    else
        self:scaleNextLink1(list,index + 1,func)
    end
end

--[[
    收集下个分数
]]
function CodeGameScreenBunnyBountyMachine:collectNextLink(list,index,func)
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end
    local data = list[index]
    if not next(data) then
        self:collectNextLink(list,index + 1,func)
        return
    end
    

    local posIndex = data.pos
    local posData = self:getRowAndColByPos(posIndex)
    local symbolNode = self.m_respinView:getSymbolByRowAndCol(posData.iY,posData.iX)
    if symbolNode then
        --显示蛋托
        symbolNode:runAnim("idleframe3")
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_link1_collect)
        self:flyLink1ToTotalWin(symbolNode,self.m_totalWin_respin,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_link1_collect_feed_back)
            self.m_curRespinMulti  = self.m_curRespinMulti + data.curScore
            self:updateRespinTotalWinCoins(self.m_curRespinMulti)
            self:totalWinFeedBackAni()
            
        end)
        self:delayCallBack(0.1,function()
            --重新生成蛋
            symbolNode:runAnim("start")
        end)
        
        self:delayCallBack(0.3,function()
            
            self:collectNextLink(list,index + 1,func)
        end)
    else
        self:collectNextLink(list,index + 1,func)
    end
end

--[[
    respin totalWin反馈动画
]]
function CodeGameScreenBunnyBountyMachine:totalWinFeedBackAni()
    self.m_totalWin_respin:runCsbAction("actionframe")
    for index = 1,4 do
        local particle = self.m_totalWin_respin:findChild("Particle_"..index)
        if particle then
            particle:resetSystem()
        end
    end
end

--[[
    respin收集link1
]]
function CodeGameScreenBunnyBountyMachine:flyLink1ToTotalWin(startNode,endNode,func)
    local flyNode = util_spineCreate("Socre_BunnyBounty_Link1",true,true)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local topPos = cc.p((startPos.x + endPos.x) / 2,math.max(startPos.y,endPos.y) + 300)

        
    local actionList = {
        cc.EaseSineOut:create(cc.BezierTo:create(20 / 30,{startPos, topPos, endPos})),
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    util_spinePlay(flyNode,"shouji")
    util_spineEndCallFunc(flyNode,"shouji",function()
        flyNode:setVisible(false)
        self:delayCallBack(0.1,function()
            flyNode:removeFromParent()
        end)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    respin单列停止
]]
function CodeGameScreenBunnyBountyMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            -- gLobalSoundManager:playSound("TheHonorOfZorroSounds/sound_TheHonorOfZorro_reel_down.mp3")
        else
            -- gLobalSoundManager:playSound("TheHonorOfZorroSounds/sound_TheHonorOfZorro_reel_down_quick.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

--结束移除小块调用结算特效
function CodeGameScreenBunnyBountyMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        if node then
            node:removeFromParent(false)
            self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
        end

    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

function CodeGameScreenBunnyBountyMachine:respinOver()
    

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_BunnyBounty_respin_total_win"])
    self.m_totalWin_respin:runCsbAction("start",false,function()
        self.m_totalWin_respin:runCsbAction("idle2",true)
        self:delayCallBack(0.5,function()
            self:showRespinOverView()
        end)
        
    end)
    
end

function CodeGameScreenBunnyBountyMachine:showRespinOverView()
    self:clearWinLineEffect()

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:setReelSlotsNodeVisible(true)
        self:resetReSpinMode()
        self:removeRespinNode()
        self:changeReSpinOverUI()
    end,function()
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self:resetMusicBg() 
        self.m_lightScore = 0
        self.m_curRespinMulti = 0
        self.m_collectBar:resumeSpinIdle()
    end)
end

function CodeGameScreenBunnyBountyMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    local extraData = self.m_runSpinResultData.p_rsExtraData
    if extraData and extraData.totalWin and extraData.totalWin ~= self.m_curRespinMulti then
        util_printLog("================== 服务器计算结果与客户端不一致 ====================",true)
    end

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
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
    respin结算界面
]]
function CodeGameScreenBunnyBountyMachine:showReSpinOver(coins, keyFunc, endFunc)
    self:clearCurMusicBg()
    local ownerlist = {}
    if self.m_serverWinCoins == 0 then
        local view = self:showDialog("NoWin", ownerlist, function()
            self:changeSceneToRespin(function()
                if type(keyFunc) == "function" then
                    keyFunc()
                end
            end,function()
                if type(endFunc) == "function" then
                    endFunc()
                end
            end)
        end)
        return view
    else
        ownerlist["m_lb_coins"] = coins

        local view = util_createView("CodeBunnyBountySrc.BunnyBountyRespinOverView",{
            machine = self,
            ownerlist = ownerlist,
            scale = self.m_machineRootScale,
            keyFunc = keyFunc,
            endFunc = endFunc
        })
    
        self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        return view
    end
end
---------------------------------------respin  end--------------------------------------------------

----------------------------预告中奖----------------------------------------

-- 播放预告中奖统一接口
function CodeGameScreenBunnyBountyMachine:showFeatureGameTip(_func)

    -- 出现预告动画概率30%
    local isNotice = self:getFeatureGameTipChance()
       
    if isNotice then
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
]]
function CodeGameScreenBunnyBountyMachine:playFeatureNoticeAni(func)
    --动效执行时间
    local aniTime = 0
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_feature_notice)
    local darkAni = util_createAnimation("BunnyBounty_yaan.csb")
    self:findChild("Node_dark"):addChild(darkAni)
    darkAni:runCsbAction("yugao",false,function()
        darkAni:removeFromParent()
    end)

    --获取父节点
    local parentNode = self:findChild("root")

    --检测是否存在预告中奖资源
    local aniName = "BunnyBounty_juese"

    self.b_gameTipFlag = true
    --创建对应格式的spine
    local spineAni = util_spineCreate(aniName,true,true)
    if parentNode then
        parentNode:addChild(spineAni)
        util_spinePlay(spineAni,"yugao")
        util_spineEndCallFunc(spineAni,"yugao",function()
            spineAni:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            self:delayCallBack(0.1,function()
                spineAni:removeFromParent()
            end)
            
        end)
        aniTime = spineAni:getAnimationDurationTime("yugao")
    end
    
    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end
---------------------------------------预告中奖  end--------------------------------------------------
function CodeGameScreenBunnyBountyMachine:showEffect_runBigWinLightAni(effectData)
    if self.m_isBonusEnd then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    return CodeGameScreenBunnyBountyMachine.super.showEffect_runBigWinLightAni(self,effectData)
end
--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenBunnyBountyMachine:showBigWinLight(func)
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_show_big_win_light)

    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local light = util_spineCreate("BunnyBounty_bigwin",true,true)
    rootNode:addChild(light)
    util_spinePlay(light,"actionframe")
    util_spineEndCallFunc(light,"actionframe",function()
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = light:getAnimationDurationTime("actionframe")
    util_shakeNode(rootNode,3,6,aniTime)

    return true
end

--新滚动使用
function CodeGameScreenBunnyBountyMachine:updateReelGridNode(symbolNode)
    -- if self:isFixSymbol(symbolNode.p_symbolType) and not self.m_isEnter then
    --     --显示拖尾
    --     symbolNode:runAnim("tuowei",true)
    -- end

    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
        self:setBonus2Show(symbolNode)
    end

    if self:isLinkSymbol(symbolNode.p_symbolType) and symbolNode.p_symbolType ~= self.SYMBOL_SCORE_LINK then
        self:setLinkSymbolShow(symbolNode)
    end
end

--[[
    设置link图标显示
]]
function CodeGameScreenBunnyBountyMachine:setLinkSymbolShow(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end

    local score = 0
    local addTimes = 1
    --这关假滚没有带数字的图标
    if symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local labelCsb = self:getLblCsbOnSymbol(symbolNode,"BunnyBounty_link_shuzi.csb","zi_guadian")
        if labelCsb then
            self:updateLinkLblShow(labelCsb,symbolNode.p_symbolType,score)
        end
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenBunnyBountyMachine:getReSpinSymbolScore(id)
    
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local multi = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            multi = values[2]
            break
        end
    end

    if multi == nil then
       return 0
    end

    multi = tonumber(multi)

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score
end

--[[
    刷新link图标上的数字显示
]]
function CodeGameScreenBunnyBountyMachine:updateLinkLblShow(csbNode,symbolType,score)
    if not csbNode then
        return
    end
    csbNode:setVisible(symbolType ~= self.SYMBOL_SCORE_LINK_2)
    
    local m_lb_coins = csbNode:findChild("m_lb_coins")
    local str = util_formatCoins(score,3)
    m_lb_coins:setString(str)
    local info={label=m_lb_coins,sx=1,sy=1}
    self:updateLabelSize(info,130)
end

--[[
    设置bonus2图标显示
]]
function CodeGameScreenBunnyBountyMachine:setBonus2Show(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    local freeTimesNode,scoreNode = self:getCsbNodeOnBonus2(symbolNode)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.coinOrFreeSpinTimesLists then
        return
    end

    local list = selfData.coinOrFreeSpinTimesLists
    local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex,symbolNode.p_cloumnIndex)
    local data
    for index = 1,#list do
        if posIndex == list[index][1] then
            data = list[index]
            break
        end
    end

    if data then
        scoreNode:setVisible(data[3] == "coins")
        freeTimesNode:setVisible(data[3] ~= "coins")
        if data[3] == "coins" then
            local m_lb_coins = scoreNode:findChild("m_lb_coins")
            if m_lb_coins then
                m_lb_coins:setString(util_formatCoins(data[2],3))
            end
        else
            for iCount = 1,2 do
                if freeTimesNode:findChild("sp_addTimes_"..iCount) then
                    freeTimesNode:findChild("sp_addTimes_"..iCount):setVisible(iCount == data[2])
                end
            end
        end
    end
end

--[[
    获取bonus2图标上的文字节点
]]
function CodeGameScreenBunnyBountyMachine:getCsbNodeOnBonus2(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and tolua.isnull(spine.m_freeTimesNode) then

        local freeTimesNode = util_createAnimation("BunnyBounty_Bonus_addspin.csb")
        util_spinePushBindNode(spine,"zi_guadian",freeTimesNode)
        spine.m_freeTimesNode = freeTimesNode
    end

    if spine and tolua.isnull(spine.m_scoreNode) then

        local scoreNode = util_createAnimation("BunnyBounty_Bonus_addcoins.csb")
        util_spinePushBindNode(spine,"zi_guadian",scoreNode)
        spine.m_scoreNode = scoreNode
    end

    spine.m_freeTimesNode:setVisible(false)
    spine.m_scoreNode:setVisible(false)

    return spine.m_freeTimesNode,spine.m_scoreNode
end

function CodeGameScreenBunnyBountyMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 5

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
        self.m_isPadScale = true
        mainPosY = mainPosY + 40
    else
        mainScale = wScale
        mainPosY = mainPosY + 20
    end

    local ratio = display.height / display.width
    if ratio <= 2176 / 1800 then
        self:findChild("bg"):setScale(1.2)
    end

    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
    self:findChild("root"):setPosition(display.center)
end

return CodeGameScreenBunnyBountyMachine