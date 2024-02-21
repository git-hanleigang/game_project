---
-- island li
-- 2019年1月26日
-- CodeGameScreenDemonessFairMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "DemonessFairPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenDemonessFairMachine = class("CodeGameScreenDemonessFairMachine", BaseNewReelMachine)

CodeGameScreenDemonessFairMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_COINS_BONUS = 94  -- 带钱的bonus
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_JACKPOT_MINI = 101   -- mini
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_JACKPOT_MINOR = 102   -- minor
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_JACKPOT_MAJOR = 103   -- major
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_JACKPOT_MEGA = 104   -- grand
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_JACKPOT_GRAND = 105   -- grand

CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_REPEAT_COINS_BONUS = 96  -- 带钱的repeatBonus
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_REPEAT_JACKPOT_MINI = 201   -- repeat_mini
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_REPEAT_JACKPOT_MINOR = 202   -- repeat_minor
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_REPEAT_JACKPOT_MAJOR = 203   -- repeat_major
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_REPEAT_JACKPOT_MEGA = 204   -- repeat_grand
CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_REPEAT_JACKPOT_GRAND = 205   -- repeat_grand

CodeGameScreenDemonessFairMachine.SYMBOL_SCORE_FIRE_BONUS = 98  -- 带火的bonus（消除bonus）

-- 自定义动画的标识
-- CodeGameScreenDemonessFairMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 
CodeGameScreenDemonessFairMachine.EFFECT_WIPE_PLAY = GameEffect.EFFECT_SELF_EFFECT - 2  -- 消除玩法（消除火🔥）
CodeGameScreenDemonessFairMachine.EFFECT_BONUS_TRIGGER_PLAY = GameEffect.EFFECT_SELF_EFFECT - 3  -- free-bonus触发动画
CodeGameScreenDemonessFairMachine.EFFECT_COLLECT_BONUS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 4  -- 收集玩法

-- 构造函数
function CodeGameScreenDemonessFairMachine:ctor()
    CodeGameScreenDemonessFairMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeDemonessFairSrc.DemonessFairSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("CodeDemonessFairSrc.DemonessFairLongRunControl",self)

    -- 大赢光效
    self.m_isAddBigWinLightEffect = true

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    -- base和free玩法时3行
    self.m_baseTypeRow = 3
    -- 最高行
    self.m_maxRow = 7
    -- 顶部多福多彩收集进度
    self.m_curTopCollectLevel = 1
    -- 消除收集进度
    self.m_curWipeCollectNum = 0
    -- 全屏点击
    self.m_roleClick = true
    -- 当前次spin落地bonus的次数
    self.m_bonusBuLingIndex = 0
    -- 当前scatter落地的个数
    self.m_curScatterBulingCount = 0
    -- 当前scatter触发index
    self.m_scatterTriggerIndex = 0
    -- 当前bonus触发index
    self.m_bonusTriggerIndex = 0
    -- 飞小块（粒子）池子
    self.m_flyNodes = {}
    --init
    self:initGame()
end

function CodeGameScreenDemonessFairMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("DemonessFairConfig.csv", "LevelDemonessFairConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenDemonessFairMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "DemonessFair"  
end

function CodeGameScreenDemonessFairMachine:getBottomUINode()
    return "CodeDemonessFairSrc.DemonessFairBottomNode"
end

function CodeGameScreenDemonessFairMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_jackPotBarViewTbl = {}
    self:initJackPotBarView() 

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Base_Reel")
    self.m_reelBg[2] = self:findChild("Free_Reel")
    self.m_reelBg[3] = self:findChild("Respin_Reel")

    -- 背景
    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("Node_baseBg")
    self.m_bgType[2] = self.m_gameBg:findChild("Node_freeBG")
    self.m_bgType[3] = self.m_gameBg:findChild("Node_respinBG")
    self.m_bgType[4] = self.m_gameBg:findChild("Node_superRespinBG")

    -- 蜡烛
    local fireAni = util_createAnimation("DemonessFair_bg_lazhu.csb")
    self:findChild("Node_bg_lazhu"):addChild(fireAni)
    fireAni:runCsbAction("idle", true)

    -- 角色反馈动画
    self.m_collectFeedBackNode = self:findChild("Node_shouji_fankui")
    
    -- 创建view节点方式
    self.m_collectView = util_createView("CodeDemonessFairCollectSrc.DemonessFairCollectView", self, self:findChild("Node_tips"))
    self:findChild("Node_Collect"):addChild(self.m_collectView)

    -- 升行动画
    self.m_upRowAni = util_createAnimation("DemonessFair_shenghang_tx.csb")
    self:findChild("Node_shenghang_tx"):addChild(self.m_upRowAni)
    self.m_upRowAni:setVisible(false)

    -- 升行时下边的火
    self.m_bottomFireAni = util_createAnimation("DemonessFair_shenghang_huo.csb")
    self:findChild("Node_shenghang_huo"):addChild(self.m_bottomFireAni)
    self.m_bottomFireAni:setVisible(false)

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))
    -- 入场说明
    self.m_enterGameTipsAni = util_createAnimation("DemonessFairShuoMing.csb")
    self:addChild(self.m_enterGameTipsAni, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_enterGameTipsAni:setScale(self.m_machineRootScale)
    self.m_enterGameTipsAni:setPosition(worldPos)
    self.m_enterGameTipsAni:setVisible(false)

    -- 上升的点，跟着动画走，用于上升裁剪区域
    self.m_spUpNode = self:findChild("shang")

    -- 最顶部光效层
    self.m_topEffectNode = self:findChild("Node_topEffect")
    -- 收集层光效
    self.m_flyEffectNode = self:findChild("Node_flyEffect")

    -- 消除特效层
    self.m_reelEffectNode = cc.Node:create()
    self.m_onceClipNode:addChild(self.m_reelEffectNode, 10000)

    -- 消除最后收集层
    self.m_resultEffectNode = cc.Node:create()
    self:addChild(self.m_resultEffectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_resultEffectNode:setScale(self.m_machineRootScale)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scRoleWaitNode = cc.Node:create()
    self:addChild(self.m_scRoleWaitNode)

    self.m_scWipeScheduleNode = cc.Node:create()
    self:addChild(self.m_scWipeScheduleNode)

    self:addClick(self:findChild("Panel_click"))

    self:changeBgAndReelBg(1)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenDemonessFairMachine:initSpineUI()
    -- 0-24
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "DemonessFair_totalwin_tx")

    -- 上边的大角色
    self.m_topRoleSpine = util_spineCreate("DemonessFair_juese",true,true)
    self:findChild("Node_bg_lazhu"):addChild(self.m_topRoleSpine)

    -- 过场动画
    self.m_cutSceneSpine = util_spineCreate("DemonessFair_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneSpine)
    self.m_cutSceneSpine:setVisible(false)

    -- free-base过场动画
    self.m_cutFreeToBaseSpine = util_spineCreate("Socre_DemonessFair_Scatter",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutFreeToBaseSpine)
    self.m_cutFreeToBaseSpine:setVisible(false)

    -- 预告中奖
    self.m_yuGaoSpine = util_spineCreate("DemonessFair_yugao",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpine, 10)
    self.m_yuGaoSpine:setVisible(false)

    -- 大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("DemonessFair_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_bigWinSpine:setVisible(false)
end

function CodeGameScreenDemonessFairMachine:enterGamePlayMusic()
    local randomIndex = math.random(1, 2)
    local soundName = self.m_publicConfig.SoundConfig.Music_Enter_GameTbl[randomIndex]
    if soundName then
        self:delayCallBack(0.2,function()
            globalMachineController:playBgmAndResume(soundName, 4, 0, 1)
        end)
    end

    -- 入场动画
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self:getCurFeatureIsFree() then
        self:showEnterGameAni()
    end
end

-- 入场动画
function CodeGameScreenDemonessFairMachine:showEnterGameAni()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    self.m_enterGameTipsAni:setVisible(true)
    self.m_enterGameTipsAni:runCsbAction("auto", false, function()
        self.m_enterGameTipsAni:setVisible(false)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
    end)
end

function CodeGameScreenDemonessFairMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenDemonessFairMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenDemonessFairMachine:initGameUI()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgAndReelBg(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        -- 如果上次有repeatBonus玩法，需要用变化后的bonus信号
        self:setLastReelByRepeatBonusPlay()
    end

    -- 进游戏显示的一定是baseJackpotBar
    self:setShowJackpotType(1)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        -- 顶部多福多彩等级
        if selfData.total_bn_level then
            self.m_curTopCollectLevel = selfData.total_bn_level
        end

        -- 消除收集进度
        if selfData.wipeCount then
            self.m_curWipeCollectNum = selfData.wipeCount
        end
    end

    self:playTopRoleSpine()
    self:refreshCollectProcess(true, self.m_curWipeCollectNum)
end

function CodeGameScreenDemonessFairMachine:addObservers()
    CodeGameScreenDemonessFairMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        --if self.m_bIsBigWin then return end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate <= 3 then
            soundIndex = 2
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_DemonessFair_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_DemonessFair_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenDemonessFairMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:resetWipeScheduleNode()
    self.m_flyEffectNode:removeAllChildren()
    CodeGameScreenDemonessFairMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenDemonessFairMachine:scaleMainLayer()
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
function CodeGameScreenDemonessFairMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_DemonessFair_10"
    elseif symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        return "Socre_DemonessFair_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MINI then
        return "Socre_DemonessFair_Bonus_Mini"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR then
        return "Socre_DemonessFair_Bonus_Minor"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
        return "Socre_DemonessFair_Bonus_Major"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MEGA then
        return "Socre_DemonessFair_Bonus_Mega"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        return "Socre_DemonessFair_Bonus_Grand"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS then
        return "Socre_DemonessFair_Repeat"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MINI then
        return "Socre_DemonessFair_Repeat_Mini"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MINOR then
        return "Socre_DemonessFair_Repeat_Minor"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MAJOR then
        return "Socre_DemonessFair_Repeat_Major"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MEGA then
        return "Socre_DemonessFair_Repeat_Mega"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_GRAND then
        return "Socre_DemonessFair_Repeat_Grand"
    elseif symbolType == self.SYMBOL_SCORE_FIRE_BONUS then
        return "Socre_DemonessFair_Xiaochu"
    end
    
    return nil
end

-- 当前信号是否为repeatBonus信号
function CodeGameScreenDemonessFairMachine:getCurSymbolIsRepeat(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS or symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MINI or
     symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MINOR or symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MAJOR or
     symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_MEGA or symbolType == self.SYMBOL_SCORE_REPEAT_JACKPOT_GRAND then
        return true
    end
    return false
end

-- 当前信号是否为普通bonus信号
function CodeGameScreenDemonessFairMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_COINS_BONUS or symbolType == self.SYMBOL_SCORE_JACKPOT_MINI or
        symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR or symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR or
        symbolType == self.SYMBOL_SCORE_JACKPOT_MEGA or symbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        return true
    end
    return false
end

-- 判断当前信号是否为低分信号
function CodeGameScreenDemonessFairMachine:getCurSymbolIsLowSymbol(_symbolType)
    local symbolType = _symbolType
    if symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 and symbolType <= self.SYMBOL_SCORE_10 then
        return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenDemonessFairMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenDemonessFairMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

--顶部补块
function CodeGameScreenDemonessFairMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    if self.m_isHaveWipePlay then
        symbolType = self:getLowSymbolType()
    end
    parentData.symbolType = symbolType
    if self.m_bigSymbolInfos[symbolType] ~= nil then
        parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    else
        parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    end
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end

-- 获取低级图标信号
function CodeGameScreenDemonessFairMachine:getLowSymbolType()
    local symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, self.SYMBOL_SCORE_10)
    return symbolType
end

function CodeGameScreenDemonessFairMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
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

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenDemonessFairMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenDemonessFairMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenDemonessFairMachine:beginReel()
    self:resetSpinData()
    CodeGameScreenDemonessFairMachine.super.beginReel(self)
end

-- spin是重置数据
function CodeGameScreenDemonessFairMachine:resetSpinData()
    self.m_isHaveWipePlay = false
    self.m_isHaveRepeatPlay = false
    self.m_collectBonus = false
    self.m_bonusBuLingIndex = 0
    -- 角色升级时延时播放角色触发
    self.m_delayTriggerRoleTime = 0
    -- 当前否要升级（角色）
    self.m_curIsUpGrade = false
    -- 当前快停收集状态
    self.m_quickCollectState = false
    -- 当前收集bonus的列（一列只收集一个）
    self.m_curCollectColSound = 0
    self.m_collectView:spinCloseTips()
end

--
--单列滚动停止回调
--
function CodeGameScreenDemonessFairMachine:slotOneReelDown(reelCol)    
    CodeGameScreenDemonessFairMachine.super.slotOneReelDown(self,reelCol)
    local longRunData = self.m_longRunControl:getCurLongRunData()
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol, longRunData) 
end

--[[
    滚轮停止
]]
function CodeGameScreenDemonessFairMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenDemonessFairMachine.super.slotReelDown(self)
    self.m_curScatterBulingCount = 0
end

function CodeGameScreenDemonessFairMachine:setLastReelByRepeatBonusPlay()
    if not self.m_runSpinResultData or not self.m_runSpinResultData.p_selfMakeData or 
        not self.m_runSpinResultData.p_selfMakeData.triggerRepeat_loc or #self.m_runSpinResultData.p_selfMakeData.triggerRepeat_loc < 1 then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local triggerRepeatLoc = selfData.triggerRepeat_loc or {}

    for index, repeatBonusData in pairs(triggerRepeatLoc) do
        local symbolNodePos = repeatBonusData[1]
        local oriSymbolType = repeatBonusData[2]
        local changeSymbolType = repeatBonusData[3]
        local fixPos = self:getRowAndColByPos(tonumber(symbolNodePos))
        local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if slotNode and changeSymbolType then
            self:changeSymbolCCBByName(slotNode, changeSymbolType)
            if changeSymbolType == self.SYMBOL_SCORE_COINS_BONUS then
                self:setRepeatNodeScoreBonus(slotNode)
            end
            slotNode:runAnim("idleframe1", true)
        end
    end
end

---
-- 在这里不影响groupIndex 和 rowIndex 等到结果数据来时使用
--
function CodeGameScreenDemonessFairMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)

    if self.m_iReelRowNum > self.m_baseTypeRow then
        symbolType = self:getLowSymbolType()
    end
    parentData.symbolType = symbolType
end

-- 根据index转换需要节点坐标系
function CodeGameScreenDemonessFairMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

-- 设置角色动画相关
function CodeGameScreenDemonessFairMachine:playTopRoleSpine(_isClick)
    self.m_scRoleWaitNode:stopAllActions()

    if _isClick then
        -- actionframe_dianji1（0-55）;actionframe_dianji2（0-55）;actionframe_dianji3（0-55）
        self.m_roleClick = false
        local curTopCollectLevel = self.m_curTopCollectLevel
        local clickNameTbl = {"actionframe_dianji1", "actionframe_dianji2", "actionframe_dianji3"}
        util_spinePlay(self.m_topRoleSpine, clickNameTbl[curTopCollectLevel], false)
        util_spineEndCallFunc(self.m_topRoleSpine, clickNameTbl[curTopCollectLevel], function()
            self.m_roleClick = true
            self:playTopRoleSpine()
        end)
    else
        self.m_roleClick = true
        -- idle1（0-240）;idle2（0-240）;idle3（0-240）;idle4(0-240）)
        local idleNameTbl = {"idle1", "idle2", "idle3", "idle4"}
        util_spinePlay(self.m_topRoleSpine, idleNameTbl[self.m_curTopCollectLevel], true)

        -- 最高级后随机播放一下穿插动作
        -- 先各百分之50概率播放
        local randomRate = math.random(1, 10)
        if randomRate <= 5 then
            if self.m_curTopCollectLevel == 3 then
                local delayTime = 240/30
                -- idle3_3（0-130）;idle3_2（0-80）
                performWithDelay(self.m_scRoleWaitNode, function()
                    local randomSpineNameTbl = {"idle3_2", "idle3_3"}
                    local randomNum = math.random(1, 2)
                    local spineName = randomSpineNameTbl[randomNum]
                    util_spinePlay(self.m_topRoleSpine, spineName, false)
                    util_spineEndCallFunc(self.m_topRoleSpine, spineName, function()
                        self:playTopRoleSpine()
                    end)
                end, delayTime)
            elseif self.m_curTopCollectLevel == 4 then
                local delayTime = 240/30
                -- idle4_2（0-125）
                performWithDelay(self.m_scRoleWaitNode, function()
                    local spineName = "idle4_2"
                    util_spinePlay(self.m_topRoleSpine, spineName, false)
                    util_spineEndCallFunc(self.m_topRoleSpine, spineName, function()
                        self:playTopRoleSpine()
                    end)
                end, delayTime)
            end
        end
    end
end

-- 设置角色反馈动画
-- actionframe_fankui1(0-25);actionframe_fankui2(0-25);actionframe_fankui3(0-25)
function CodeGameScreenDemonessFairMachine:playRoleSpineFeedBack()
    self.m_scRoleWaitNode:stopAllActions()
    self.m_roleClick = false

    self.m_topRoleSpine:resetAnimation()
    util_cancelSpineEventHandler(self.m_topRoleSpine)
    local feedBackName = "actionframe_fankui" .. self.m_curTopCollectLevel
    util_spinePlay(self.m_topRoleSpine, feedBackName, false)
    util_spineEndCallFunc(self.m_topRoleSpine, feedBackName, function()
        self:playTopRoleSpine()
    end)
end

-- 角色触发动画
-- actionframe(0-60)
function CodeGameScreenDemonessFairMachine:playRoleTriggerSpine()
    self.m_scRoleWaitNode:stopAllActions()
    self.m_roleClick = false

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Role_Kiss_Sound)
    self.m_topRoleSpine:resetAnimation()
    util_cancelSpineEventHandler(self.m_topRoleSpine)
    local feedBackName = "actionframe1_" .. self.m_curTopCollectLevel
    util_spinePlay(self.m_topRoleSpine, feedBackName, false)
    util_spineEndCallFunc(self.m_topRoleSpine, feedBackName, function()
        self:playTopRoleSpine()
    end)
end

-- 进入升行玩法后的触发动画
-- actionframe2（0-130）
function CodeGameScreenDemonessFairMachine:playWipeTriggerSpine()
    self.m_scRoleWaitNode:stopAllActions()
    self.m_roleClick = false

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Role_Trigger)
    self.m_topRoleSpine:resetAnimation()
    util_cancelSpineEventHandler(self.m_topRoleSpine)
    util_spinePlay(self.m_topRoleSpine, "actionframe2", false)
    util_spineEndCallFunc(self.m_topRoleSpine, "actionframe2", function()
        self:playTopRoleSpine()
    end)
end

-- 大角色预告动画
function CodeGameScreenDemonessFairMachine:playRoleYuGaoSpine()
    self.m_scRoleWaitNode:stopAllActions()
    self.m_roleClick = false

    self.m_topRoleSpine:resetAnimation()
    util_cancelSpineEventHandler(self.m_topRoleSpine)
    local yuGaoName = "actionframe_yugao"..self.m_curTopCollectLevel
    util_spinePlay(self.m_topRoleSpine, yuGaoName, false)
    util_spineEndCallFunc(self.m_topRoleSpine, yuGaoName, function()
        self:playTopRoleSpine()
    end)
end

-- 触发消除时，第一次消除角色动画
function CodeGameScreenDemonessFairMachine:playWipeRoleSpine()
    self.m_scRoleWaitNode:stopAllActions()
    self.m_roleClick = false

    self.m_topRoleSpine:resetAnimation()
    util_cancelSpineEventHandler(self.m_topRoleSpine)
    local spineActName = "xiaochu"
    util_spinePlay(self.m_topRoleSpine, spineActName, false)
    util_spineEndCallFunc(self.m_topRoleSpine, spineActName, function()
        self:playTopRoleSpine()
    end)
end

-- 刷新收集进度
function CodeGameScreenDemonessFairMachine:refreshCollectProcess(_onEnter, _totalWipeCollectNum)
    self.m_collectView:refreshProcess(_onEnter, _totalWipeCollectNum)
end
---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenDemonessFairMachine:addSelfEffect()
    self.m_isWipePlay = false
    self.m_delayTime = 0.5
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 消除玩法
    local wipeData = selfData.wipe
    -- 收集玩法
    local collectStoredIcons = self:getCurSpinIsHaveCollectPlay(true)
    -- free下触发消除玩法类型
    local wipeTriggerType = selfData.wipeTriggerType

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- free下先播触发
        if wipeData and next(wipeData) then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_BONUS_TRIGGER_PLAY -- 动画类型
        end

        -- free下repeat变完后收集
        if wipeTriggerType and wipeTriggerType == "repeat" then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_BONUS_PLAY -- 动画类型
        end
    end

    if wipeData and next(wipeData) then
        self.m_isWipePlay = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 4
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_WIPE_PLAY -- 动画类型
    end

    -- 判断当前spin是否有连线
    local winLines = self.m_runSpinResultData.p_winLines or {}
    --  if self:getCurrSpinMode() ~= FREE_SPIN_MODE and #winLines > 0 then
    if #winLines > 0 then
       self.m_delayTime = 2
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenDemonessFairMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BONUS_TRIGGER_PLAY then
        local collectBonusData = self:getSortCollectPlayData()
        self:delayCallBack(self.m_delayTime, function()
            self:showBonusTriggerPlay(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, collectBonusData)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_BONUS_PLAY then
        local collectBonusData = self:getSortCollectPlayData()
        self:showCollectBonusPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, collectBonusData)
    elseif effectData.p_selfEffectType == self.EFFECT_WIPE_PLAY then
        local collectBonusData = self:getSortCollectPlayData()
        self:delayCallBack(self.m_delayTriggerRoleTime, function()
            self:triggerWipePlay(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, collectBonusData)
        end)
    end
    
    return true
end

-- 判断当前是否有收集玩法(需要把repeat信号剔除出去)
function CodeGameScreenDemonessFairMachine:getCurSpinIsHaveCollectPlay(_isCollectPlay)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collectStoredIcons = clone(selfData.storedIcons)
    if _isCollectPlay and collectStoredIcons and next(collectStoredIcons) then
        for i=#collectStoredIcons, 1, -1 do
            local symbolType = collectStoredIcons[i][2]
            if self:getCurSymbolIsRepeat(symbolType) then
                table.remove(collectStoredIcons, i)
            end
        end
    end

    return collectStoredIcons
end

-- 排序玩法信息
function CodeGameScreenDemonessFairMachine:getSortCollectPlayData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collectStoredIcons = self:getCurSpinIsHaveCollectPlay()
    local tempDataTbl = {}

    for k, bonusData in pairs(collectStoredIcons) do
        local tempTbl = {}
        tempTbl.p_pos = tonumber(bonusData[1])
        local fixPos = self:getRowAndColByPos(tonumber(bonusData[1]))
        local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.p_symbolNode = slotNode
        tempTbl.p_isJackpot = bonusData[4]
        tempTbl.p_symbolType = bonusData[2]
        table.insert(tempDataTbl, tempTbl)
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
    return tempDataTbl
end

-- 排序结算玩法信息
function CodeGameScreenDemonessFairMachine:getSortResultPlayData(_allRewardData)
    local allRewardData = _allRewardData
    local tempDataTbl = {}

    for k, bonusData in pairs(allRewardData) do
        local tempTbl = {}
        tempTbl.p_pos = tonumber(bonusData[1])
        local fixPos = self:getRowAndColByPos(tonumber(bonusData[1]))
        local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.p_symbolNode = slotNode
        tempTbl.p_symbolType = bonusData[2]
        tempTbl.p_curRewardCoins = bonusData[3]
        tempTbl.p_isJackpot = bonusData[4]
        table.insert(tempDataTbl, tempTbl)
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
    return tempDataTbl
end

-- 排序repeatBonus顺序（在消除玩法里）
function CodeGameScreenDemonessFairMachine:getSortRepeatBonusPlayData(_repeatBonusData)
    local repeatBonusData = _repeatBonusData
    local tempDataTbl = {}
    if repeatBonusData and next(repeatBonusData) then
        for k, bonusData in pairs(repeatBonusData) do
            local tempTbl = {}
            tempTbl.p_pos = tonumber(bonusData[1])
            tempTbl.p_oriSymbolType = tonumber(bonusData[2])
            tempTbl.p_changeSymbolType = tonumber(bonusData[3])
            local fixPos = self:getRowAndColByPos(tonumber(bonusData[1]))
            tempTbl.p_rowIndex = fixPos.iX
            tempTbl.p_cloumnIndex = fixPos.iY
            table.insert(tempDataTbl, tempTbl)
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
    end
    return tempDataTbl
end

-- 收集玩法
function CodeGameScreenDemonessFairMachine:showCollectBonusPlay(_callFunc, _collectBonusData)
    local callFunc = _callFunc
    local collectBonusData = _collectBonusData
    self.m_topEffectNode:removeAllChildren()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local oldTopCollectLevel = self.m_curTopCollectLevel
    local curTopCollectLevel = 3--selfData.total_bn_level

    local delayTime = 0.4
    local isPlayMask = true
    local isPlayCollectIndex = 0
    local totalCount = #collectBonusData
    for k, data in pairs(collectBonusData) do
        local oneTblActionList = {}
        local curSymbolNode = data.p_symbolNode
        local symbolNodePos = data.p_pos
        local isJackpot = data.p_isJackpot
            
        -- 飞行的bonus
        local flyNode = self:getFlyNodeFromList()
        flyNode:setVisible(true)
        local startPos = self:getWorldToNodePos(self.m_flyEffectNode, symbolNodePos)
        local endPos = cc.p(0, 0)
        flyNode:setPosition(startPos)
        local particleTbl = {}
        for i=1, 4 do
            local particle = flyNode:findChild("Particle_" .. i)
            if not tolua.isnull(particle) then
                table.insert(particleTbl, particle)
                particle:setPositionType(0)
                particle:setDuration(-1)
                particle:resetSystem()
            end
        end
        oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
            if curSymbolNode then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Collect)
                curSymbolNode:runAnim("shouji", false, function()
                    curSymbolNode:runAnim("idleframe", true)
                end)
            end
        end)
        oneTblActionList[#oneTblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
        oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Collect_FeedBack)
            -- 角色反馈动画
            local collectFeedBackAni = util_createAnimation("DemonessFair_shouji_fankui.csb")
            self.m_collectFeedBackNode:addChild(collectFeedBackAni)
            collectFeedBackAni:runCsbAction("actionframe", false, function()
                collectFeedBackAni:removeFromParent()
            end)
            for i=1, #particleTbl do
                if not tolua.isnull(particleTbl[i]) then
                    particleTbl[i]:stopSystem()
                end
            end
            self:playRoleSpineFeedBack()
        end)
        -- 判断是否升级
        if curTopCollectLevel > oldTopCollectLevel then
            self.m_curTopCollectLevel = curTopCollectLevel
            oneTblActionList[#oneTblActionList + 1] = cc.DelayTime:create(25/30)
            -- actionframe_shengji1_2(0-40); actionframe_shengji1_3(0-4); actionframe_shengji2_3(0-40)
            oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
                self:playRoleLevelUpSound(oldTopCollectLevel)
                local upGradeName = "actionframe_shengji" .. oldTopCollectLevel .. "_" .. curTopCollectLevel
                util_spinePlay(self.m_topRoleSpine, upGradeName, false)
                util_spineEndCallFunc(self.m_topRoleSpine, upGradeName, function()
                    self:playTopRoleSpine()
                end)
            end)
            oneTblActionList[#oneTblActionList + 1] = cc.DelayTime:create(40/30)
        end
        oneTblActionList[#oneTblActionList + 1] = cc.DelayTime:create(0.2)
        oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
            isPlayCollectIndex = isPlayCollectIndex + 1
            if isPlayCollectIndex == totalCount then
                isPlayCollectIndex = isPlayCollectIndex + 1
                if type(callFunc) == "function" then
                    callFunc()
                end
            end
            if not tolua.isnull(flyNode) then
                self:pushFlyNodeToList(flyNode)
            end
        end)
        flyNode:runAction(cc.Sequence:create(oneTblActionList))
    end
end

-- 大角色升级音效
function CodeGameScreenDemonessFairMachine:playRoleLevelUpSound(_oldLevel)
    local soundPath = self.m_publicConfig.SoundConfig.Music_Role_LevelUp_Tbl[_oldLevel]
    if soundPath then
        gLobalSoundManager:playSound(soundPath)
    end
end

-- 改为落地后收集
function CodeGameScreenDemonessFairMachine:bulingCollectBonusPlay(_slotNode)
    local collectBonusData = self:getSortCollectPlayData()
    self.m_bonusBuLingIndex = self.m_bonusBuLingIndex + 1
    local isLastCollect = false
    local oldTopCollectLevel, curTopCollectLevel
    if next(collectBonusData) and self.m_bonusBuLingIndex >= #collectBonusData then
        isLastCollect = true
        local selfData = self.m_runSpinResultData.p_selfMakeData

        oldTopCollectLevel = self.m_curTopCollectLevel
        curTopCollectLevel = selfData.total_bn_level
        -- 消除玩法
        local wipeData = selfData.wipe
        if wipeData and next(wipeData) then
            curTopCollectLevel = 3
        end
    end
    local slotNode = _slotNode
    local curCollectCol = slotNode.p_cloumnIndex
    local symbolNodePos = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
    -- 飞行的bonus
    local flyNode = self:getFlyNodeFromList()
    flyNode:setVisible(true)
    local startPos = self:getWorldToNodePos(self.m_flyEffectNode, symbolNodePos)
    
    local endPos = cc.p(0, 0)
    flyNode:setPosition(startPos)
    local particleTbl = {}
    for i=1, 4 do
        local particle = flyNode:findChild("Particle_" .. i)
        if not tolua.isnull(particle) then
            table.insert(particleTbl, particle)
            particle:setPositionType(0)
            particle:setDuration(-1)
            particle:resetSystem()
        end
    end

    local oneTblActionList = {}
    local delayTime = 0.4
    local isPlaySound = false
    if not self.m_quickCollectState and self.m_curCollectColSound ~= curCollectCol then
        self.m_curCollectColSound = curCollectCol
        isPlaySound = true
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Collect)
    end
    oneTblActionList[#oneTblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
    oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
        if isPlaySound then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Collect_FeedBack)
        end
        -- 角色反馈动画
        local collectFeedBackAni = util_createAnimation("DemonessFair_shouji_fankui.csb")
        self.m_collectFeedBackNode:addChild(collectFeedBackAni)
        collectFeedBackAni:runCsbAction("actionframe", false, function()
            collectFeedBackAni:removeFromParent()
        end)
        for i=1, #particleTbl do
            if not tolua.isnull(particleTbl[i]) then
                particleTbl[i]:stopSystem()
            end
        end
        if not self.m_curIsUpGrade then
            self:playRoleSpineFeedBack()
        end
    end)
    if not self.m_curIsUpGrade then
        -- 判断是否升级
        if isLastCollect and curTopCollectLevel > oldTopCollectLevel then
            self.m_curIsUpGrade = true
            self.m_curTopCollectLevel = curTopCollectLevel
            self.m_delayTriggerRoleTime = 25/30+40/30
            oneTblActionList[#oneTblActionList + 1] = cc.DelayTime:create(25/30)
            -- actionframe_shengji1_2(0-40); actionframe_shengji1_3(0-4); actionframe_shengji2_3(0-40)
            oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
                self:playRoleLevelUpSound(oldTopCollectLevel)
                local upGradeName = "actionframe_shengji" .. oldTopCollectLevel .. "_" .. curTopCollectLevel
                util_spinePlay(self.m_topRoleSpine, upGradeName, false)
                util_spineEndCallFunc(self.m_topRoleSpine, upGradeName, function()
                    self.m_delayTriggerRoleTime = 0
                    self.m_curIsUpGrade = false
                    self:playTopRoleSpine()
                end)
            end)
        end
    end

    oneTblActionList[#oneTblActionList + 1] = cc.DelayTime:create(0.2)
    oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
        if not tolua.isnull(flyNode) then
            self:pushFlyNodeToList(flyNode)
        end
    end)
    flyNode:runAction(cc.Sequence:create(oneTblActionList))
end

function CodeGameScreenDemonessFairMachine:getFlyNodeFromList()
    if #self.m_flyNodes == 0 then
        local flyNode = util_createAnimation("Socre_DemonessFair_Bonus_tw.csb")
        self.m_flyEffectNode:addChild(flyNode)
        return flyNode
    end

    local flyNode = self.m_flyNodes[#self.m_flyNodes]
    table.remove(self.m_flyNodes,#self.m_flyNodes)
    return flyNode
end

function CodeGameScreenDemonessFairMachine:pushFlyNodeToList(flyNode)
    self.m_flyNodes[#self.m_flyNodes + 1] = flyNode
    flyNode:setVisible(false)
end

-- free下bonus触发动画
function CodeGameScreenDemonessFairMachine:showBonusTriggerPlay(_callFunc, _collectBonusData)
    local callFunc = _callFunc
    local collectBonusData = _collectBonusData
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- free下触发消除玩法类型
    local wipeTriggerType = selfData.wipeTriggerType
    -- repeatData
    local triggerRepeatLoc = selfData.triggerRepeat_loc or {}
    local wipeType = selfData.wipe_type
    local delayTime = 85/30

    -- 角色触发
    -- self:playRoleTriggerSpine()

    local isPlaySound = true
    -- bonus触发
    for k, data in pairs(collectBonusData) do
        local curSymbolNode = data.p_symbolNode
        local symbolType = data.p_symbolType
        local curSymbolPos = data.p_pos
        if curSymbolNode then
            if isPlaySound then
                isPlaySound = false
                if wipeType == "super" then
                    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Bonus_SuperTrigger, 2, 0, 1)
                else
                    local bonusTriggerSoundTbl = self.m_publicConfig.SoundConfig.Music_Bonus_Trigger_Tbl
                    self.m_bonusTriggerIndex = self.m_bonusTriggerIndex + 1
                    if self.m_bonusTriggerIndex > 2 then
                        self.m_bonusTriggerIndex = 1
                    end
                    local soundTime = 2
                    if self.m_bonusTriggerIndex == 1 then
                        soundTime = 4
                    end

                    local soundPath = bonusTriggerSoundTbl[self.m_bonusTriggerIndex]
                    if soundPath then
                        globalMachineController:playBgmAndResume(soundPath, soundTime, 0, 1)
                        self:clearCurMusicBg()
                    end
                end
            end
            if wipeTriggerType == "repeat" and self:getCurSymbolIsRepeat(symbolType) then
                local changeSymbolType, oriSymbolType = nil
                for k, v in pairs(triggerRepeatLoc) do
                    if curSymbolPos == v[1] then
                        oriSymbolType = v[2]
                        changeSymbolType = v[3]
                    end
                end
                
                if oriSymbolType then
                    -- 上边创建一个假的repeatBonus，盖住freeBar（需求）
                    local topSymbolNode = self:createDemonessFairSymbol(oriSymbolType)
                    local topNodePos = self:getWorldToNodePos(self.m_topEffectNode, curSymbolPos)
                    topSymbolNode:setPosition(topNodePos)
                    self.m_topEffectNode:addChild(topSymbolNode)
                    topSymbolNode.p_cloumnIndex = curSymbolNode.p_cloumnIndex
                    topSymbolNode.p_rowIndex = curSymbolNode.p_rowIndex
                    topSymbolNode.m_isLastSymbol = curSymbolNode.m_isLastSymbol

                    curSymbolNode:setVisible(false)
                    if changeSymbolType then
                        self:changeSymbolCCBByName(curSymbolNode, changeSymbolType)
                        if changeSymbolType == self.SYMBOL_SCORE_COINS_BONUS then
                            self:setRepeatNodeScoreBonus(curSymbolNode)
                            
                            local coins = self:getBonusScoreData(curSymbolPos, self.SYMBOL_SCORE_REPEAT_COINS_BONUS)
                            topSymbolNode:setUpReelBonusCoins(oriSymbolType, curSymbolPos, coins)
                        end
                        curSymbolNode:runAnim("idleframe1", true)
                    end

                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Repeat_ChangeSymbolType)
                    topSymbolNode:runAnim("actionframe", false, function()
                        curSymbolNode:setVisible(true)
                        topSymbolNode:setVisible(false)
                    end)
                    -- 补丁：测试点系统切回来回调没走？导致不显示卷轴上的小块
                    self:delayCallBack(delayTime, function()
                        if not tolua.isnull(curSymbolNode) and not curSymbolNode:isVisible() then
                            curSymbolNode:setVisible(true)
                        end
                    end)
                end
            elseif wipeTriggerType == "normal" and self:getCurSymbolIsBonus(symbolType) then
                delayTime = 60/30
                curSymbolNode:runAnim("actionframe", false, function()
                    curSymbolNode:runAnim("idleframe1", true)
                end)
            end
        end
    end

    self:delayCallBack(delayTime+0.1, function()
        self.m_topEffectNode:removeAllChildren()
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

-- 触发消除玩法
function CodeGameScreenDemonessFairMachine:triggerWipePlay(_callFunc, _collectBonusData)
    local callFunc = _callFunc
    local collectBonusData = _collectBonusData
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_curWipeCollectNum = selfData.wipeCount
    local wipeType = selfData.wipe_type
    local maxRows = selfData.extraRows
    -- free下触发消除玩法类型
    local wipeTriggerType = selfData.wipeTriggerType

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local tblActionList = {}
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        -- 角色触发
        self:playRoleTriggerSpine()
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(60/30)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            -- 收集条
            if wipeType == "super" then
                self.m_curWipeCollectNum = 10
            end
            -- 收集火
            self:refreshCollectProcess(nil, self.m_curWipeCollectNum)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_Top_Add)
        end)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(40/60)

        if wipeType == "super" then
            -- respin次数条点亮动画结束后0.2srespin次数条点亮动画结束后0.2s
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.2)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_Top_Add_FeedBack)
                self.m_collectView:playTriggerAct()
            end)
            -- 30-150
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(120/60)
        end
    end
    -- respin次数条点亮动画结束后0.5s
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.5)
    -- 出弹板
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self.m_bottomUI:resetWinLabel()
            self.m_bottomUI:checkClearWinLabel()
        end
        self:showWipeStartDialog(wipeType, function()
            self:showCutPlaySceneAni(wipeType, maxRows, function()
                self:showWipePlay(callFunc)
            end, true)
        end)
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 消除开始弹板
function CodeGameScreenDemonessFairMachine:showWipeStartDialog(_wipeType, _endCallFunc)
    local wipeType = _wipeType
    local endCallFunc = _endCallFunc
    local csbName = "ReSpinStart"
    local soundPath = self.m_publicConfig.SoundConfig.Music_Wipe_StartAndOver
    if wipeType == "super" then
        csbName = "SuperReSpinStart"
        soundPath = self.m_publicConfig.SoundConfig.Music_Wipe_StartAndOver_Super
    end
    gLobalSoundManager:playSound(soundPath)
    local view = self:showDialog(csbName, nil, endCallFunc, BaseDialog.AUTO_TYPE_NOMAL, nil)
    local roleSpine = util_spineCreate("DemonessFair_juese",true,true)
    view:findChild("Node_juese"):addChild(roleSpine)
    util_spinePlay(roleSpine, "idleframe_start_tb", true)

    -- 弹板上的火
    local fireAni = util_createAnimation("DemonessFair_tb_huo.csb")
    view:findChild("Node_huo"):addChild(fireAni)
    fireAni:runCsbAction("idle", true)

    view:findChild("root"):setScale(self.m_machineRootScale)
    util_setCascadeOpacityEnabledRescursion(view, true)
end

-- 消除结束弹板
function CodeGameScreenDemonessFairMachine:showWipeOverDialog(_wipeType, _endCallFunc)
    local wipeType = _wipeType
    local endCallFunc = _endCallFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local winCoins = selfData.wipeWinCoins or 0

    local csbName = "ReSpinOver"
    local soundPath = self.m_publicConfig.SoundConfig.Music_Wipe_OverStart
    local soundTime = 2
    if wipeType == "super" then
        csbName = "SuperReSpinOver"
        self.m_curWipeCollectNum = 0
        self:refreshCollectProcess(true, self.m_curWipeCollectNum)
        soundPath = self.m_publicConfig.SoundConfig.Music_Wipe_OverStart_Super
        soundTime = 4
    end
    if soundPath then
        globalMachineController:playBgmAndResume(soundPath, soundTime, 0, 1)
        self:clearCurMusicBg()
    end

    local cutSceneFunc = function()
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
        end, 5/60)
    end
    
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(winCoins, 30)
    local view = self:showDialog(csbName, ownerlist, endCallFunc)

    local roleSpine = util_spineCreate("DemonessFair_juese",true,true)
    view:findChild("Node_juese"):addChild(roleSpine)
    util_spinePlay(roleSpine, "idleframe_tanban", true)

    view:setBtnClickFunc(cutSceneFunc)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.08,sy=1.08},610)    
    view:findChild("root"):setScale(self.m_machineRootScale)
    util_setCascadeOpacityEnabledRescursion(view, true)
end

-- 消除过场动画
function CodeGameScreenDemonessFairMachine:showCutPlaySceneAni(_wipeType, _maxRows, _endCallFunc, _isStart)
    local wipeType = _wipeType
    local maxRows = _maxRows
    local endCallFunc = _endCallFunc
    local isStart = _isStart

    if isStart then
        local soundPath = self.m_publicConfig.SoundConfig.Music_Enter_Wipe_CutScene
        if wipeType == "super" then
            soundPath = self.m_publicConfig.SoundConfig.Music_Enter_Wipe_CutScene_Super
        end
        gLobalSoundManager:playSound(soundPath)
    else
        local soundPath = self.m_publicConfig.SoundConfig.Music_Exit_Wipe_CutScene
        if wipeType == "super" then
            soundPath = self.m_publicConfig.SoundConfig.Music_Exit_Wipe_CutScene_Super
        end
        gLobalSoundManager:playSound(soundPath)
    end

    -- actionframe_guochang：0-105
    self.m_cutSceneSpine:setVisible(true)
    util_spinePlay(self.m_cutSceneSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_cutSceneSpine, "actionframe_guochang", function()
        self.m_cutSceneSpine:setVisible(false)
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end)

    -- 71帧时切背景
    performWithDelay(self.m_scWaitNode, function()
        self:setMaxMusicBGVolume()
        if isStart then
            -- 左侧系统栏隐藏
            gLobalActivityManager:setSlotLeftFloatVisible(false)
            self:runCsbAction("idle1", true)
            self.m_curTopCollectLevel = 4
            self:playTopRoleSpine()
            self.m_baseFreeSpinBar:setVisible(false)
            if maxRows == self.m_maxRow then
                self:setShowJackpotType(3)
            else
                self:setShowJackpotType(2)
            end
            if wipeType == "super" then
                self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_SuperWipe_Bg)
                self:changeBgAndReelBg(4)
                -- super下用平均bet
                self.m_refreshJackpotBar = true
                --平均bet值 展示
                self.m_bottomUI:showAverageBet()
            else
                self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Wipe_Bg)
                self:changeBgAndReelBg(3)
            end
        else
            -- 左侧系统栏显示
            gLobalActivityManager:setSlotLeftFloatVisible(true)
            self:resetMusicBg()
            self.m_refreshJackpotBar = false
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:changeBgAndReelBg(2)
                self.m_baseFreeSpinBar:setVisible(true)
            else
                self:changeBgAndReelBg(1)
            end
            --平均bet值 隐藏
            self.m_bottomUI:hideAverageBet()
            self.m_upRowAni:setVisible(false)
            self.m_bottomFireAni:setVisible(false)
            self.m_curTopCollectLevel = 1
            self:playTopRoleSpine()
            self:setShowJackpotType(1)
            self:setOneUpClipNode()
            for i = 1, self.m_iReelColumnNum do
                self:changeReelRowNum(i, self.m_iReelRowNum, true)
            end

            -- 普通信号换成正常颜色
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, maxRows do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode and self:getCurSymbolIsLowSymbol(slotNode.p_symbolType) then
                        slotNode:runAnim("idleframe", true)
                    end

                    -- 高行放回slotParent
                    if iRow > self.m_baseTypeRow then
                        self:putSymbolBackToPreParent(slotNode)
                    end
                end
            end
        end
    end, 71/30)
end

-- 消除玩法
function CodeGameScreenDemonessFairMachine:showWipePlay(_callFunc)
    self:resetWipeScheduleNode()
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 消除玩法
    local wipeData = selfData.wipe
    local maxRows = selfData.extraRows
    -- 升完行后需要变成火的信号
    local changFireData = wipeData[1].wipePosition

    local newReelData = selfData.startReels
    self:changeShowRow(maxRows, newReelData)

    -- 一行一行升
    local curRow = self.m_baseTypeRow

    local tblActionList = {}
    local delayTime = 130/30
    -- 进入respin界面后1s开始播
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(1)
    -- actionframe2（0-130）
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        -- 过场完了之后；播角色触发
        self:playWipeTriggerSpine()
    end)
    -- tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
    -- 升行特效
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_UpReel_TipSound)
        self.m_upRowAni:setVisible(true)
        self.m_upRowAni:runCsbAction("start", false, function()
            self.m_upRowAni:runCsbAction("idle", true)
        end)
    end)
    -- start0-80
    -- tblActionList[#tblActionList + 1] = cc.DelayTime:create(80/60)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self.m_bottomFireAni:setVisible(true)
        self.m_bottomFireAni:runCsbAction("idle", true)
        self:showOneUpReelPlay(callFunc, maxRows, curRow)
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 一行一行升
function CodeGameScreenDemonessFairMachine:showOneUpReelPlay(_callFunc, _maxRows, _curRow)
    local callFunc = _callFunc
    local maxRows = _maxRows
    local curRow = _curRow + 1

    self:resetWipeScheduleNode()
    if curRow > maxRows then
        -- 升完行之后播放假升行动画
        local randomNum = math.random(1, 10)
        if maxRows == self.m_maxRow then
            randomNum = 10
        elseif maxRows == self.m_maxRow-1 then
            randomNum = 1
        end
        if randomNum <= 5 then
            local actName = "actionframe" .. curRow-1 .. "_" .. curRow .. "_1"
            local idleName = "idle" .. curRow-1
            self:startUpClipNode()
            self:runCsbAction(actName, false, function()
                self.m_upRowAni:runCsbAction("over", false, function()
                    self.m_upRowAni:setVisible(false)
                end)
                self:runCsbAction(idleName, true)
                self:resetWipeScheduleNode()
                self:setOneUpClipNode()
                -- 升完行之后开始变火信号
                self:delayCallBack(0.5, function()
                    self:changeFireSymbol(callFunc)
                end)
            end)
        else
            self.m_upRowAni:runCsbAction("over", false, function()
                self.m_upRowAni:setVisible(false)
            end)
            -- 升完行之后开始变火信号
            self:delayCallBack(0.5, function()
                self:changeFireSymbol(callFunc)
            end)
        end
        return
    end

     --[[
        升行至4行，升行节奏不变
        升行至5行，每次升行完停0.2s再升下一行
        升行至6行，每次升行完停0.3s再升下一行
        升行至7行，每次升行完停0.4s再升下一行
    ]]
    local delayTime = 0
    if curRow > 4 then
        delayTime = (curRow-4)*0.1 + 0.1
    end

    -- 升行动画
    local actName = "actionframe" .. curRow-1 .. "_" .. curRow
    local idleName = "idle" .. curRow
    self:delayCallBack(delayTime, function()
        self:startUpClipNode()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_UpReel_Sound)
        self:runCsbAction(actName, false, function()
            self:runCsbAction(idleName, true)
            self:resetWipeScheduleNode()
            self:setOneUpClipNode()
            self:delayCallBack(0.1, function()
                self:showOneUpReelPlay(callFunc, maxRows, curRow)
            end)
        end)
    end)
end

-- 先升行
function CodeGameScreenDemonessFairMachine:changeShowRow(_maxRows, _newReelData)
    -- 最大行
    self.m_iReelRowNum = _maxRows
    -- 新轮盘数据
    local newReelData = _newReelData

    local maxHight = self.m_SlotNodeH * self.m_iReelRowNum

    -- 填充数据
    for i = self.m_baseTypeRow + 1, self.m_iReelRowNum, 1 do
        if self.m_stcValidSymbolMatrix[i] == nil then
            self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
        end
    end

    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i, self.m_iReelRowNum, true)
    end

    -- 信号重新赋值
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                local curRow = self.m_iReelRowNum - iRow + 1
                local symbolType = newReelData[curRow][iCol]
                self:changeSymbolCCBByName(slotNode, symbolType)
                if symbolType == self.SYMBOL_SCORE_COINS_BONUS or symbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS then
                    self:setUpReelBonusCoins(slotNode, symbolType)
                end

                -- 高行设置tag值
                if iRow > self.m_baseTypeRow then
                    slotNode:setTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                end
            end
        end
    end
end

-- 先变成火的信号
function CodeGameScreenDemonessFairMachine:changeFireSymbol(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 消除玩法
    local wipeData = selfData.wipe
    -- 升完行后需要变成火的信号
    local changFireData = wipeData[1].wipePosition

    -- 变火信号98
    local isPlaySound = true
    for k, fireData in pairs(changFireData) do
        local symbolNodePos = fireData[1]
        local fixPos = self:getRowAndColByPos(symbolNodePos)
        local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

        local tempFireNode = self:createDemonessFairSymbol(self.SYMBOL_SCORE_FIRE_BONUS)
        local tempFireNodePos = self:getWorldToNodePos(self.m_topEffectNode, symbolNodePos)
        tempFireNode:setPosition(tempFireNodePos)
        self.m_topEffectNode:addChild(tempFireNode)

        -- show(0-22)
        if isPlaySound then
            isPlaySound = false
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fire_Disappear)
        end
        tempFireNode:runAnim("show", false, function()
            self:changeSymbolCCBByName(slotNode, self.SYMBOL_SCORE_FIRE_BONUS)
            self:changeSymbolToClipParent(slotNode)
            slotNode:runAnim("idleframe1", true)
            tempFireNode:setVisible(false)
        end)
    end

    -- 低分信号变颜色
    local lowSymbolTbl = {4, 5, 6, 7, 8, 9}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType and self:getCurSymbolIsLowSymbol(slotNode.p_symbolType) then
                local switchSpine = util_spineCreate("DemonessFair_symbol_tx",true,true)
                local switchNodePos = self:getWorldToNodePos(self.m_topEffectNode, self:getPosReelIdx(iRow, iCol))
                switchSpine:setPosition(switchNodePos)
                self.m_topEffectNode:addChild(switchSpine)
                util_spinePlay(switchSpine, "switch", false)
                slotNode:runAnim("switch", false, function()
                    slotNode:runAnim("idleframe1", false)
                end)
            end
        end
    end

    local tblActionList = {}
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.5)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self:playWipeRoleSpine()
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.5)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self.m_topEffectNode:removeAllChildren()
        self:showWipeFireSymbol(callFunc, 0)
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 消除前，把低分图标放回slotParent
function CodeGameScreenDemonessFairMachine:setLowSymbolTypeToSlotParent()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType and self:getCurSymbolIsLowSymbol(slotNode.p_symbolType) then
                self:putSymbolBackToPreParent(slotNode)
            end
        end
    end
end

-- 消除步骤开始------------------
-- 消除->下落->收集->依次循环
-- 开始消除
function CodeGameScreenDemonessFairMachine:showWipeFireSymbol(_callFunc, _wipeIndex)
    local callFunc = _callFunc
    local wipeIndex = _wipeIndex + 1
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 消除玩法
    local wipeData = selfData.wipe
    local wipeType = selfData.wipe_type

    if wipeIndex > #wipeData then
        local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
         --刷新顶栏
        if not bFree and not bLine then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end
        if not self:checkHasBigWin() then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end
        -- 恢复行
        local maxRow = self.m_iReelRowNum
        self.m_iReelRowNum = self.m_baseTypeRow
        self:delayCallBack(0.5, function()
            self:showWipeOverDialog(wipeType, function()
                self:showCutPlaySceneAni(wipeType, maxRow, function()
                    if type(callFunc) == "function" then
                        callFunc()
                    end
                end)
            end)
        end)
        return
    end
    self:setLowSymbolTypeToSlotParent()
    -- 消除的信号
    local changFireData = wipeData[wipeIndex].wipePosition
    -- 下落的信号
    local iconsMovement = wipeData[wipeIndex].iconsMovement
    -- 当前bonus信号位置和倍数
    local storedIcons = wipeData[wipeIndex].storedIcons
    -- 消除前的卷轴数据
    local beforeReelData =  wipeData[wipeIndex].reelsBeforeWipe
    self:checkWipeReelData(beforeReelData)

    -- actionframe(0-12) -- 消除
    local fireActTime = 12/30
    local isPlaySound = true
    for k, fireData in pairs(changFireData) do
        local symbolNodePos = fireData[1]
        local fixPos = self:getRowAndColByPos(symbolNodePos)
        local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

        -- actionframe(0-21)
        if isPlaySound then
            isPlaySound = false
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fire_Appear)
        end
        if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_FIRE_BONUS then
            slotNode:runAnim("actionframe", false, function()
                slotNode:setVisible(false)
            end)
        end
    end

    --[[
        1）掉落速度不一致，每列掉落时长固定为0.4s，每列都是同时落地
        2）spin次数每增加2，时长减0.1s，最多减至0.2s为止
    ]]
    -- 下落的时间
    local delayTime = 0.4 - math.floor(wipeIndex/2)*0.1
    if delayTime < 0.2 then
        delayTime = 0.2
    end

    -- 等消除动画播完
    self:delayCallBack(fireActTime, function()
        local intervalTime = 0.2
        local bulingTime = 0
        local isPlaySound = true
        local bonusSoundPath = self.m_publicConfig.SoundConfig.Music_RepeatBonus_Buling_Sound
        local isPlayBonusSound = true
        for k, moveData in pairs(iconsMovement) do
            local oneTblActionList = {}
            local moveSymbolType = moveData[1]
            local moveDis = moveData[2]
            local symbolStartPos = moveData[3]
            local symbolEndPos = moveData[4]

            if moveDis > 0 then
                -- 判断播放哪个音效（优先播放带钱和jackpot的音效）
                if self:getCurSymbolIsBonus(moveSymbolType) then
                    bonusSoundPath = self.m_publicConfig.SoundConfig.Music_Bonus_Buling_Sound
                end
                local moveNode = self:createDemonessFairSymbol(moveSymbolType)
                local moveNodeStartPos = self:getWorldToNodePos(self.m_reelEffectNode, symbolStartPos)
                local moveNodeEndPos = self:getWorldToNodePos(self.m_reelEffectNode, symbolEndPos)
                moveNode:setPosition(moveNodeStartPos)
                self.m_reelEffectNode:addChild(moveNode)

                local fixPos = self:getRowAndColByPos(symbolEndPos)
                local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                if fixPos.iX <= self.m_iReelRowNum then
                    self:changeSymbolCCBByName(slotNode, moveSymbolType)
                    if slotNode and slotNode.p_symbolType and self:getCurSymbolIsLowSymbol(slotNode.p_symbolType) then
                        self:putSymbolBackToPreParent(slotNode)
                    end
                    slotNode:setVisible(false)
                    if moveSymbolType == self.SYMBOL_SCORE_COINS_BONUS or moveSymbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS then
                        local curCoins = self:getWipeBonusScoreData(symbolEndPos, moveSymbolType, storedIcons)
                        moveNode:setUpReelBonusCoins(moveSymbolType, symbolEndPos, curCoins)
                        self:setUpReelBonusCoins(slotNode, moveSymbolType, curCoins)
                    end
                end

                if self:getCurSymbolIsLowSymbol(moveSymbolType) then
                    moveNode:runAnim("idleframe1", true)
                    slotNode:runAnim("idleframe1", true)
                else
                    moveNode:runAnim("idleframe", true)
                    slotNode:runAnim("idleframe1", true)
                end

                if isPlaySound then
                    isPlaySound = false
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fire_MoveDown)
                end
                oneTblActionList[#oneTblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, moveNodeEndPos))
                if self:getCurSymbolIsBonus(moveSymbolType) or self:getCurSymbolIsRepeat(moveSymbolType) then
                    bulingTime = 21/30
                    oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
                        self:changeSymbolToClipParent(slotNode)
                        slotNode:setVisible(true)
                        moveNode:setVisible(false)
                        if isPlayBonusSound then
                            isPlayBonusSound = false
                            gLobalSoundManager:playSound(bonusSoundPath)
                        end
                        slotNode:runAnim("buling", false, function()
                            slotNode:runAnim("idleframe1", true)
                        end)
                    end)
                    oneTblActionList[#oneTblActionList + 1] = cc.DelayTime:create(bulingTime)
                end
                oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
                    if moveSymbolType == self.SYMBOL_SCORE_FIRE_BONUS then
                        self:changeSymbolToClipParent(slotNode)
                    end
                    moveNode:setVisible(false)
                    slotNode:setVisible(true)
                end)
                moveNode:runAction(cc.Sequence:create(oneTblActionList))
            end
        end

        local totalTime = delayTime + bulingTime
        self:delayCallBack(totalTime, function()
            self:collectBonusReward(callFunc, wipeIndex, 0)
        end)
    end)
end

-- 每消除一次就收集一次bonus
function CodeGameScreenDemonessFairMachine:collectBonusReward(_callFunc, _wipeIndex, _winIndex)
    local callFunc = _callFunc
    local wipeIndex = _wipeIndex
    local winIndex = _winIndex + 1
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_collectBonus = true
    -- 消除玩法
    local wipeData = selfData.wipe
    -- 收集bonus奖励的次数
    local winTimes = wipeData[wipeIndex].winTimes
    -- 是否收集钱
    local isCollect = wipeData[wipeIndex].isCollect
    -- repeatBonus位置
    local repeatBonus = self:getSortRepeatBonusPlayData(clone(wipeData[wipeIndex].repeatBonus))
    -- 收集的奖励
    local allRewardData = wipeData[wipeIndex].storedIcons
    local resultBonusData = self:getSortResultPlayData(allRewardData)
    -- 当前bonus信号位置和倍数
    local storedIcons = wipeData[wipeIndex].storedIcons

    if isCollect and winIndex <= winTimes then
        if winIndex > 1 then
            -- repeat图标先触发，然后接着重新收集一遍
            local repeatBonusData = repeatBonus[winIndex-1]
            local changeSymbolType = repeatBonusData.p_changeSymbolType
            local repeatBonusPos = repeatBonusData.p_pos
            local fixPos = self:getRowAndColByPos(repeatBonusPos)
            local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            local curSymbolZorder = slotNode:getLocalZOrder()
            if slotNode and slotNode.p_symbolType and self:getCurSymbolIsRepeat(slotNode.p_symbolType) then
                self:setCurSymbolZorder(slotNode, curSymbolZorder+100)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Repeat_ChangeSymbolType)
                slotNode:runAnim("actionframe", false, function()
                    self:setCurSymbolZorder(slotNode, curSymbolZorder)
                    self:changeSymbolCCBByName(slotNode, changeSymbolType)
                    slotNode:runAnim("idleframe1", true)
                    local curCoins = self:getWipeBonusScoreData(repeatBonusPos, changeSymbolType, storedIcons)
                    self:setUpReelBonusCoins(slotNode, changeSymbolType, curCoins)
                    self:collectOneBonusReward(callFunc, resultBonusData, wipeIndex, winIndex, 0)
                end)
            end
        else
            self:collectOneBonusReward(callFunc, resultBonusData, wipeIndex, winIndex, 0)
        end
    else
        -- 从上个消除流程完全结束至下个消除流程开始，间隔1s
        self:delayCallBack(0.5, function()
            self:showWipeFireSymbol(callFunc, wipeIndex)
        end)
    end
end

-- 一个一个收集
function CodeGameScreenDemonessFairMachine:collectOneBonusReward(_callFunc, _resultBonusData, _wipeIndex, _winIndex, _collectIndex)
    local callFunc = _callFunc
    local resultBonusData = _resultBonusData
    local wipeIndex = _wipeIndex
    local winIndex = _winIndex
    local collectIndex = _collectIndex + 1
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 消除玩法
    local wipeData = selfData.wipe
    -- 收集的奖励
    local allRewardData = wipeData[wipeIndex].storedIcons
    local maxRows = selfData.extraRows

    if collectIndex > #allRewardData then
        self:collectBonusReward(callFunc, wipeIndex, winIndex)
        return
    end

    -- 收集奖励
    local curRewardData = resultBonusData[collectIndex]
    local curSymbolNode = curRewardData.p_symbolNode
    local curSymbolType = curRewardData.p_symbolType
    local curSymbolPos = curRewardData.p_pos
    local curRewardCoins = curRewardData.p_curRewardCoins
    local curJackpotType = curRewardData.p_isJackpot

    -- jiesuan(0-22)
    if curSymbolNode then
        local curSymbolZorder = curSymbolNode:getLocalZOrder()
        local delayTime = 0.4
        
        self:setCurSymbolZorder(curSymbolNode, curSymbolZorder+100)
        curSymbolNode:runAnim("jiesuan", false, function()
            self:setCurSymbolZorder(curSymbolNode, curSymbolZorder)
            curSymbolNode:runAnim("idleframe1", true)
        end)
        
        if curJackpotType then
            local jackpotCoins = self:getWinJackpotCoinsAndType(curJackpotType)
            self:playBottomFlyCoins(jackpotCoins, 1/60)
            self:playBottomLight(jackpotCoins)
    
            local JACKPOT_INDEX = {
                grand = 1,
                mega = 2,
                major = 3,
                minor = 4,
                mini = 5
            }
            local jackpotIndex = JACKPOT_INDEX[curJackpotType]
            if maxRows == self.m_maxRow then
                self.m_jackPotBarViewTbl[3]:playTriggerJackpot(jackpotIndex)
            else
                self.m_jackPotBarViewTbl[2]:playTriggerJackpot(jackpotIndex)
            end
            self:delayCallBack(0.5, function()
                self.m_bottomUI:setWinLabState(false)
            end)
            self:delayCallBack(delayTime, function()
                self.m_bottomUI:setWinLabState(false)
                self:showJackpotView(jackpotCoins, curJackpotType, function()
                    self.m_bottomUI:setWinLabState(false)
                    self:collectOneBonusReward(callFunc, resultBonusData, wipeIndex, winIndex, collectIndex)
                end)
            end)
        else
            self:playBottomFlyCoins(curRewardCoins, 1/60)
            self:playBottomLight(curRewardCoins)
            self:delayCallBack(delayTime, function()
                self.m_bottomUI:setWinLabState(false)
                self:collectOneBonusReward(callFunc, resultBonusData, wipeIndex, winIndex, collectIndex)
            end)
        end
    end
end

-- 播动画时提层
function CodeGameScreenDemonessFairMachine:setCurSymbolZorder(_symbolNode, _curZorder)
    _symbolNode:setLocalZOrder(_curZorder)
end

-- 校验轮盘信号（以免在变化过程中出错）
function CodeGameScreenDemonessFairMachine:checkWipeReelData(_reelData)
    local reelData = _reelData
    -- 信号检测
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                local curRow = self.m_iReelRowNum - iRow + 1
                local symbolType = reelData[curRow][iCol]
                if slotNode.p_symbolType ~= symbolType then
                    self:changeSymbolCCBByName(slotNode, symbolType)
                end
            end
        end
    end
end

-- 改为指定信号
function CodeGameScreenDemonessFairMachine:changeSymbolCCBByName(_slotNode, _symbolType)
    if _slotNode.p_symbolImage then
        _slotNode.p_symbolImage:removeFromParent()
        _slotNode.p_symbolImage = nil
    end
    _slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, _symbolType), _symbolType)
    _slotNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, _symbolType))
end

-- 重置定时器
function CodeGameScreenDemonessFairMachine:resetWipeScheduleNode()
    if self.m_scWipeScheduleNode ~= nil then
        self.m_scWipeScheduleNode:unscheduleUpdate()
    end
end

-- 跟动画配合，每帧监测动画上升的位置，来设置裁剪的高度
function CodeGameScreenDemonessFairMachine:startUpClipNode()
    if self.m_scWipeScheduleNode ~= nil then
        self.m_scWipeScheduleNode:onUpdate(function(delayTime)
            self:setOneUpClipNode(delayTime)
        end)
    end
end

-- 一行一行上升
function CodeGameScreenDemonessFairMachine:setOneUpClipNode(_delayTime)
    local delayTime = _delayTime
    local posY = self.m_spUpNode:getPositionY() + 67
    local curHight = self.m_SlotNodeH * self.m_baseTypeRow + posY

    local x, y = self.m_onceClipNode:getPosition()
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = rect.y,
            width = rect.width,
            height = curHight
        }
    )
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenDemonessFairMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 5
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

function CodeGameScreenDemonessFairMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    return CodeGameScreenDemonessFairMachine.super.showEffect_runBigWinLightAni(self,effectData)
end

function CodeGameScreenDemonessFairMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenDemonessFairMachine.super.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenDemonessFairMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FreeMoreBonus_Trigger)
        else
            local scatterTriggerSoundTbl = self.m_publicConfig.SoundConfig.Music_Scatter_Trigger_Base
            self.m_scatterTriggerIndex = self.m_scatterTriggerIndex + 1
            if self.m_scatterTriggerIndex > 2 then
                self.m_scatterTriggerIndex = 1
            end

            local soundPath = scatterTriggerSoundTbl[self.m_scatterTriggerIndex]
            if soundPath then
                globalMachineController:playBgmAndResume(soundPath, 3, 0, 1)
            end
        end
    end
end

-- 不用系统音效
function CodeGameScreenDemonessFairMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenDemonessFairMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenDemonessFairMachine:checkRemoveBigMegaEffect()
    CodeGameScreenDemonessFairMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenDemonessFairMachine:getShowLineWaitTime()
    local time = CodeGameScreenDemonessFairMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    --insert-getShowLineWaitTime
    local winLines = self.m_reelResultLines or {}
    local lineValue = winLines[1] or {}
    if #winLines == 1 and lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        time = 0
    end 

    return time
end

----------------------------新增接口插入位---------------------------------------------

--默认按钮监听回调
function CodeGameScreenDemonessFairMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" and self.m_roleClick and self:tipsBtnIsCanClick() then
        self:playTopRoleSpine(true)
    end
end

function CodeGameScreenDemonessFairMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeDemonessFairSrc.DemonessFairFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("FreeBar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenDemonessFairMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_More_Auto)
            self.m_baseFreeSpinBar:setFreeAni(true)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            -- 过场和弹板结合
            local guochangSpine = util_spineCreate("Socre_DemonessFair_Scatter",true,true)
            view:findChild("hua"):addChild(guochangSpine)
            util_spinePlay(guochangSpine, "actionframe_guochang", false)

            -- 花瓣
            local huabanSpine = util_spineCreate("Socre_DemonessFair_Scatter",true,true)
            view:findChild("huaban"):addChild(huabanSpine)
            util_spinePlay(huabanSpine, "actionframe_guochang_huaban", false)

            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        else
            -- 282帧切背景
            self:delayCallBack(282/60, function()
                self.m_baseFreeSpinBar:changeFreeSpinByCount()
                self.m_baseFreeSpinBar:setVisible(true)
                self:changeBgAndReelBg(2)
            end)
            -- 92帧
            self:delayCallBack(85/30, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartOver)
            end)

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end, true)

            -- 过场和弹板结合
            local guochangSpine = util_spineCreate("Socre_DemonessFair_Scatter",true,true)
            view:findChild("hua"):addChild(guochangSpine)
            util_spinePlay(guochangSpine, "actionframe_guochang", false)

            -- 花瓣
            local huabanSpine = util_spineCreate("Socre_DemonessFair_Scatter",true,true)
            view:findChild("huaban"):addChild(huabanSpine)
            util_spinePlay(huabanSpine, "actionframe_guochang_huaban", false)

            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

---------------------------------弹版----------------------------------
function CodeGameScreenDemonessFairMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenDemonessFairMachine:showFreeSpinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 2, 0, 1)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    if globalData.slotRunData.lastWinCoin > 0 then
        local cutSceneFunc = function()
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
            end, 5/60)
        end
        local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
            self:clearWinLineEffect()
            self:showFreeToBaseCutSceneAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)

        -- hua的挂点挂Socre_DemonessFair_Scatter的idleframe_tanban：0-60
        local flowerSpine = util_spineCreate("Socre_DemonessFair_Scatter",true,true)
        view:findChild("Node_hua"):addChild(flowerSpine)
        util_spinePlay(flowerSpine, "idleframe_tanban", true)

        -- DemonessFair_tanban1的idleframe_tanban：0-60
        -- DemonessFair_tanban2的idleframe_tanban：0-60
        -- 挂点：FreeSpinOver.csd的Node_hua
        local leftFlowerSpine = util_spineCreate("DemonessFair_tanban2",true,true)
        view:findChild("Node_hua"):addChild(leftFlowerSpine)
        util_spinePlay(leftFlowerSpine, "idleframe_tanban", true)

        local rightFlowerSpine = util_spineCreate("DemonessFair_tanban1",true,true)
        view:findChild("Node_hua"):addChild(rightFlowerSpine)
        util_spinePlay(rightFlowerSpine, "idleframe_tanban", true)

        local node=view:findChild("m_lb_coins")
        view:setBtnClickFunc(cutSceneFunc)
        view:updateLabelSize({label=node,sx=1.08,sy=1.08},610)    
        view:findChild("root"):setScale(self.m_machineRootScale)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        local cutSceneFunc = function()
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
            end, 5/60)
        end

        local view = self:showFreeSpinOverNoWin(function()
            self:clearWinLineEffect()
            self:showFreeToBaseCutSceneAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)

        view:setBtnClickFunc(cutSceneFunc)
        util_setCascadeOpacityEnabledRescursion(view, true)
    end
end

function CodeGameScreenDemonessFairMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FeatureOver",nil,_func)
    return view
end

-- free过场动画
function CodeGameScreenDemonessFairMachine:showFreeToBaseCutSceneAni(_endCallFunc)
    local endCallFunc = _endCallFunc
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)

    -- actionframe_guochang2：0-126
    self.m_cutFreeToBaseSpine:setVisible(true)
    util_spinePlay(self.m_cutFreeToBaseSpine,"actionframe_guochang2",false)
    util_spineEndCallFunc(self.m_cutFreeToBaseSpine, "actionframe_guochang2", function()
        self.m_cutFreeToBaseSpine:setVisible(false)
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end)

    -- 87帧切背景
    performWithDelay(self.m_scWaitNode, function()
        self:changeBgAndReelBg(1)
        self.m_baseFreeSpinBar:setVisible(false)
    end, 87/30)
end

function CodeGameScreenDemonessFairMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:clearCurMusicBg()
        self:levelDeviceVibrate(6, "free")
    end
    
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
                    slotNode:runAnim("actionframe", false, function()
                        slotNode:runAnim("idleframe1", true)
                    end)
                    
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end
    self:playScatterTipMusicEffect(true)
    
    performWithDelay(self,function()
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true      
end

function CodeGameScreenDemonessFairMachine:createDemonessFairSymbol(_symbolType)
    local symbol = util_createView("CodeDemonessFairSrc.DemonessFairSymbol", self)
    symbol:initDatas(self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

---
    -- 逐条线显示 线框和 Node 的actionframe
    --
function CodeGameScreenDemonessFairMachine:showLineFrameByIndex(winLines,frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    self.super.showLineFrameByIndex(self, winLines, frameIndex)    
end

---
    -- 显示所有的连线框
    --
function CodeGameScreenDemonessFairMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    self.super.showAllFrame(self, tempLineValue)    
end

function CodeGameScreenDemonessFairMachine:getFsTriggerSlotNode(parentData, symPosData)
    return self:getFixSymbol(symPosData.iY, symPosData.iX)    
end

function CodeGameScreenDemonessFairMachine:initJackPotBarView()
    -- 三个jackpotBar；1：base；2：不是最高行消除；3：最高行消除玩法
    self.m_jackPotBarViewTbl[1] = util_createView("CodeDemonessJackpotFairSrc.DemonessFairJackPotBarView")
    self.m_jackPotBarViewTbl[1]:initMachine(self)
    self:findChild("JackpotBar"):addChild(self.m_jackPotBarViewTbl[1])

    self.m_jackPotBarViewTbl[2] = util_createView("CodeDemonessJackpotFairSrc.DemonessFairJackPotBarWipeView")
    self.m_jackPotBarViewTbl[2]:initMachine(self)
    self:findChild("JackpotBar"):addChild(self.m_jackPotBarViewTbl[2])

    self.m_jackPotBarViewTbl[3] = util_createView("CodeDemonessJackpotFairSrc.DemonessFairJackPotBarWipeMaxRowView")
    self.m_jackPotBarViewTbl[3]:initMachine(self)
    self:findChild("JackpotBar"):addChild(self.m_jackPotBarViewTbl[3])
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenDemonessFairMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeDemonessFairSrc.DemonessFairJackpotWinView",{
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

function CodeGameScreenDemonessFairMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}, ["isScatter"] = true} )
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["anyNumAnyWhere"] ,["legitimateNum"] = 3, ["symbolType"] = {94, 101, 102, 103, 104, 105, 96, 201, 202, 203, 204, 205}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态 
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenDemonessFairMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenDemonessFairMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenDemonessFairMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

function CodeGameScreenDemonessFairMachine:updateReelGridNode(_symbolNode)
    -- 钱和free需要往插槽上挂字体
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        self:setNodeScoreBonus(_symbolNode)
    elseif _symbolNode.p_symbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS then
        self:setRepeatNodeScoreBonus(_symbolNode)
    end
end

-- bonusCoins
function CodeGameScreenDemonessFairMachine:setNodeScoreBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType then
        return
    end

    local curBet = self:getCurSpinStateBet()
    local sScore = ""
    local mul, coins
    local nodeScore = self:getLblCsbOnSymbol(symbolNode,"Socre_DemonessFair_Bonus_Coins.csb","shuzi")

    if symbolNode.m_isLastSymbol == true then
        coins = self:getBonusScoreData(self:getPosReelIdx(iRow, iCol), self.SYMBOL_SCORE_COINS_BONUS)
        if coins ~= nil and coins ~= 0 then
            sScore = util_formatCoinsLN(coins, 3)
            -- sScore = util_formatCoinsLN({coins = coins, obligate = 3, obligateF = 1})
        end
    else
        -- 获取随机分数（本地配置）
        mul = self:randomDownSymbolScore(symbolNode.p_symbolType)
        local coins = mul * curBet
        sScore = util_formatCoinsLN(coins, 3)
        -- sScore = util_formatCoinsLN({coins = coins, obligate = 3, obligateF = 1})
    end

    local textNode = nodeScore:findChild("m_lb_coins")
    if textNode then
        textNode:setString(sScore)
    end
end

-- repeatBonus
function CodeGameScreenDemonessFairMachine:setRepeatNodeScoreBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType then
        return
    end

    local curBet = self:getCurSpinStateBet()
    local sScore = ""
    local mul, coins
    local nodeScore = self:getLblCsbOnSymbol(symbolNode,"Socre_DemonessFair_RepeatBonus_Coins.csb","shuzi")

    if symbolNode.m_isLastSymbol == true then
        coins = self:getBonusScoreData(self:getPosReelIdx(iRow, iCol), self.SYMBOL_SCORE_REPEAT_COINS_BONUS)
        if coins ~= nil and coins ~= 0 then
            sScore = util_formatCoinsLN(coins, 3)
            -- sScore = util_formatCoinsLN({coins = coins, obligate = 3, obligateF = 1})
        end
    else
        -- 获取随机分数（本地配置）
        mul = self:randomDownSymbolScore(symbolNode.p_symbolType)
        local coins = mul * curBet
        sScore = util_formatCoinsLN(coins, 3)
        -- sScore = util_formatCoinsLN({coins = coins, obligate = 3, obligateF = 1})
    end

    local textNode = nodeScore:findChild("m_lb_coins")
    if textNode then
        textNode:setString(sScore)
    end
end


-- 升行后设置bonus上的钱
function CodeGameScreenDemonessFairMachine:setUpReelBonusCoins(_symbolNode, _symbolType, _curCoins)
    local symbolNode = _symbolNode
    local symbolType = _symbolType
    local curCoins = _curCoins
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local csbName = ""
    if symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        csbName = "Socre_DemonessFair_Bonus_Coins.csb"
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS then
        csbName = "Socre_DemonessFair_RepeatBonus_Coins.csb"
    end

    local coins = 0
    if curCoins then
        coins = curCoins
    else
        coins = self:getUpReelBonusScoreData(self:getPosReelIdx(iRow, iCol), symbolType)
    end
    local nodeScore = self:getLblCsbOnSymbol(symbolNode, csbName, "shuzi")

    local sScore = util_formatCoinsLN(coins, 3)

    local textNode = nodeScore:findChild("m_lb_coins")
    if textNode then
        textNode:setString(sScore)
    end
end

-- 消除时每一步bonus数据
function CodeGameScreenDemonessFairMachine:getWipeBonusScoreData(_id, _symbolType, _storedIcons)
    local id = _id
    local storedIcons = _storedIcons
    local symbolType = _symbolType
    local score = 0
    if not storedIcons then
        return
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        -- if values[1] == id and values[2] == symbolType then
        if values[1] == id then
            score = values[3]
            break
        end
    end
    if score == 0 then
        local test = 0
    end

    return score
end

--[[
    升完行获取小块真实分数
]]
function CodeGameScreenDemonessFairMachine:getUpReelBonusScoreData(id, _symbolType)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.triggerStoredIcons
    local score = 0
    if not storedIcons then
        return
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        -- if values[1] == id and values[2] == _symbolType then
        if values[1] == id then
            score = values[3]
            break
        end
    end

    return score
end

--[[
    获取小块真实分数
]]
function CodeGameScreenDemonessFairMachine:getBonusScoreData(id, _symbolType)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.storedIcons
    local score = nil
    if not storedIcons then
        return
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id and values[2] == _symbolType then
            score = values[3]
            break
        end
    end

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenDemonessFairMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        score = self.m_configData:getBnBasePro()
    elseif symbolType == self.SYMBOL_SCORE_REPEAT_COINS_BONUS then
        score = self.m_configData:getBnBasePro(true)
    end

    return score
end

-- 获取当前bet
function CodeGameScreenDemonessFairMachine:getCurSpinStateBet(_isAvgBet)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if _isAvgBet and selfData and selfData.averageBet and selfData.averageBet > 0 then
        curBet = selfData.averageBet
    end
    return curBet
end

-- 设置当前是否有消除玩法
function CodeGameScreenDemonessFairMachine:setCurSpinWipePlayState()
    self.m_isHaveWipePlay = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 消除玩法
    local wipeData = selfData.wipe
    if wipeData and next(wipeData) then
        self.m_isHaveWipePlay = true
    end

    -- repeat玩法
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- free下触发消除玩法类型
        local wipeTriggerType = selfData.wipeTriggerType
        if wipeTriggerType and wipeTriggerType == "repeat" then
            self.m_isHaveRepeatPlay = true
        end
    end
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenDemonessFairMachine:showFeatureGameTip(_func)
    self:setCurSpinWipePlayState()
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
function CodeGameScreenDemonessFairMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)

    self:playRoleYuGaoSpine()
    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end) 
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenDemonessFairMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, "actionframe_bigwin", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe_bigwin", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(rootNode, 5, 10, aniTime)
end

--[[
    将小块放回原父节点
]]
function CodeGameScreenDemonessFairMachine:putSymbolBackToPreParent(symbolNode, isInTop)
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

--[[
    获取jackpot类型及赢得的金币数
]]
function CodeGameScreenDemonessFairMachine:getWinJackpotCoinsAndType(_curJackpotType)
    local curJackpotType = _curJackpotType
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        if string.lower(curJackpotType) == string.lower(jackpotType) then
            return coins
        end
    end
    return 0    
end

-- 播放飘钱
function CodeGameScreenDemonessFairMachine:playBottomFlyCoins(_rewardCoins, _delayTime)
    local rewardCoins = _rewardCoins
    local delayTime = _delayTime

    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end

    local params = {
        overCoins  = _rewardCoins,
        jumpTime   = delayTime,
        animName   = "actionframe3",
        isPlayCoins = true,
    }
    
    self:playBottomBigWinLabAnim(params)
end

function CodeGameScreenDemonessFairMachine:playBottomLight(_endCoins)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Collect_CoinBonus_FeedBack)
    self.m_bottomUI:playCoinWinEffectUI()

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenDemonessFairMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenDemonessFairMachine:getCurBottomWinCoins()
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

-- 三个jackpotBar；1：base；2：不是最高行消除；3：最高行消除玩法
function CodeGameScreenDemonessFairMachine:setShowJackpotType(_showIndex)
    local showIndex = _showIndex
    for _index, _jackpotBar in pairs(self.m_jackPotBarViewTbl) do
        if _index == showIndex then
            _jackpotBar:setVisible(true)
            _jackpotBar:setIdle()
        else
            _jackpotBar:setVisible(false)
        end
    end
end

-- 重置jackpot动画
function CodeGameScreenDemonessFairMachine:resetJackpotAni()
    for _index, _jackpotBar in pairs(self.m_jackPotBarViewTbl) do
        _jackpotBar:resetJackpot()
    end
end

function CodeGameScreenDemonessFairMachine:changeBgAndReelBg(_bgType)
    -- 1.base；2.freespin；3.消除；4.super消除
    for i=1, 4 do
        if i == _bgType then
            self.m_bgType[i]:setVisible(true)
        else
            self.m_bgType[i]:setVisible(false)
        end
    end

    if _bgType == 1 then
        self:runCsbAction("idle", true)
    elseif _bgType == 2 then
        self:runCsbAction("idle1", true)
    end
    
    local bgType = _bgType
    if bgType == 4 then
        bgType = 3
    end
    self:setReelBgState(bgType)
end

function CodeGameScreenDemonessFairMachine:setReelBgState(_bgType)
    for i=1, 3 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

function CodeGameScreenDemonessFairMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    local lineWinCoins = self:getClientWinCoins()
    local wipeCoins = 0
    if self.m_isWipePlay then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        wipeCoins = selfData.wipeWinCoins or 0
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins-wipeCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount-wipeCoins)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

function CodeGameScreenDemonessFairMachine:tipsBtnIsCanClick()
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

--[[
    小块提层到clipParent上
]]
function CodeGameScreenDemonessFairMachine:changeSymbolToClipParent(symbolNode)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
        local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local pos = util_getOneGameReelsTarSpPos(self, index)
        local showOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
        showOrder = showOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * self.m_baseTypeRow * 2
        symbolNode.p_showOrder = showOrder
        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        util_changeNodeParent(self.m_clipParent,symbolNode,showOrder)
        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))

        symbolNode:setPosition(cc.p(pos.x, pos.y))
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenDemonessFairMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    self:changeSymbolToClipParent(_slotNode)
                    -- util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
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
                self:playBulingAnimFunc(_slotNode,symbolCfg)
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenDemonessFairMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                else
                    self.m_symbolExpectCtr:playSymbolIdleAnim(_slotNode, true)    
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

-- 落地动画
function CodeGameScreenDemonessFairMachine:playBulingAnimFunc(_slotNode,_symbolCfg)
    if not self.m_isHaveRepeatPlay and self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
        self:bulingCollectBonusPlay(_slotNode)
        if self:getGameSpinStage() == QUICK_RUN then
            if not self.m_quickCollectState then
                self.m_quickCollectState = true
            end
        end
    end
    _slotNode:runAnim(_symbolCfg[2], false, function()
        self:symbolBulingEndCallBack(_slotNode)
    end)
end

-- 当前是否是free
function CodeGameScreenDemonessFairMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenDemonessFairMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    local scatterSoundTbl = self.m_publicConfig.SoundConfig.Music_Scatter_Buling

    local isQuickHaveScatter = false
    -- 检查下前三列是否有scatter（前三列有scatter必然播落地）
    if self:getGameSpinStage() == QUICK_RUN then
        local reels = self.m_runSpinResultData.p_reels
        for iCol = 1, (self.m_iReelColumnNum-2) do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = reels[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isQuickHaveScatter = true
                    break
                end
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
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    soundPath = symbolCfg[1]
                end
                if soundPath then
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self.m_curScatterBulingCount = self.m_curScatterBulingCount + 1
                        if self.m_curScatterBulingCount > #symbolCfg then
                            self.m_curScatterBulingCount = #symbolCfg
                        end
                        soundPath = scatterSoundTbl[self.m_curScatterBulingCount]
                        if self:getGameSpinStage() == QUICK_RUN then
                            if self:getCurFeatureIsFree() then
                                soundPath = scatterSoundTbl[3]
                            else
                                soundPath = scatterSoundTbl[1]
                            end
                        end
                    end

                    -- 快停时；有scatter 不播bonus
                    if self:getCurSymbolIsBonus(symbolType) or self:getCurSymbolIsRepeat(symbolType) then
                        if not isQuickHaveScatter then
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

return CodeGameScreenDemonessFairMachine
