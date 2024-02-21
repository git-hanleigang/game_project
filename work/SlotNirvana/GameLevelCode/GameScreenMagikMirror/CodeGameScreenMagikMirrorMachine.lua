---
-- island li
-- 2019年1月26日
-- CodeGameScreenMagikMirrorMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "MagikMirrorPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenMagikMirrorMachine = class("CodeGameScreenMagikMirrorMachine", BaseNewReelMachine)

CodeGameScreenMagikMirrorMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenMagikMirrorMachine.SYMBOL_SCORE_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --红苹果
CodeGameScreenMagikMirrorMachine.SYMBOL_SCORE_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  --金苹果


-- 自定义动画的标识
CodeGameScreenMagikMirrorMachine.GAME_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1 -- 收集
CodeGameScreenMagikMirrorMachine.GAME_MIRROR_ROTATE_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2 -- 旋转

local COMMON_INDEX = {
    ONE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6
}

local MIRROR_SCALE = {
    1,
    0.8,
    0.59,
    0.46,
    0.46,
    0.46
}

-- 构造函数
function CodeGameScreenMagikMirrorMachine:ctor()
    CodeGameScreenMagikMirrorMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeMagikMirrorSrc.MagikMirrorSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("MagikMirrorLongRunControl",self) 


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.m_specialBets = nil
    self.curBetCoins = 0
    self.curBonusListForBet = {}
    self.curFreeNum = 0
    self.curBonusNum = 0
    self.m_betLevel = nil
    self.expectBgList = {}
    self.stagingNum = 0
    self.lastTypeForRotate = nil

    self.rotateMirrorList = {}

    self.rotateIndexForQuickStop = 0    --魔镜快停时记录旋转轮数

    self.rotateEffect = nil

    self.isSuperFree = false

    self.m_isQuickRotate = true

    self.curJackpotCoins = 0

    self.b_gameTipFlagForBigWin = false

    self.m_bonusTrigger = 0

    self.isOverEffect = 0

    self.isFreeYuGao = true

    self.isLightSound = false
    self.isChangeSound = false

    self.isSoundForThreeMirror = true

    self.isInitReelSymbol = false

    self.isBigSize = false

    self.isCanChangeBet = false
    
    --init
    self:initGame()
end

function CodeGameScreenMagikMirrorMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMagikMirrorMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MagikMirror"  
end




function CodeGameScreenMagikMirrorMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
    -- self.m_effectNode:setScale(self.m_machineRootScale)
    --旋转用节点
    self.m_rotateNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_rotateNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    self.m_effect1 = cc.Node:create()
    self:findChild("root"):addChild(self.m_effect1,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_effect2 = cc.Node:create()
    self:findChild("root"):addChild(self.m_effect2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self:runCsbAction("idle",true)

    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 
    self:initFreeNumBar()
    self:showUiForIndex(COMMON_INDEX.ONE)
    self:addBigMirror()
    self:createReelExpectBG()

    self:addBigWinShow()
    self:addYuGaoCsb()

    self:changeBottomBigWinLabUi("MagikMirror_bigwin_number.csb")

    --pick界面
    self.m_pickGameView = util_createView("CodeMagikMirrorSrc.MagikMirrorPickGameView",self)
    self:findChild("Node_pick"):addChild(self.m_pickGameView)
    self.m_pickGameView:setVisible(false)

    self:addTempMirrorTb()

    self:addSmallJackpotTb()

    self.noClickLayer = util_createAnimation("MagikMirrorNoClick.csb")
    self:addChild(self.noClickLayer, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.noClickLayer:setPosition(display.width * 0.5, display.height * 0.5)
    self.noClickLayer:setVisible(false)

    self.changeBetNode = cc.Node:create()
    self:addChild(self.changeBetNode)

end



function CodeGameScreenMagikMirrorMachine:initSpineUI()
    self:addGuochangShow()
    --大赢2
    self.m_bigWin2 = util_spineCreate("MagikMirror_bigwin2", true, true)
    self:findChild("Node_bigwin2"):addChild(self.m_bigWin2)
    self.m_bigWin2:setPosition(cc.p(0,0))
    self.m_bigWin2:setVisible(false)
end


function CodeGameScreenMagikMirrorMachine:addTempMirrorTb()
    self.mirrorViewTb = util_createAnimation("MagikMirror_mojing_TB.csb")
    local pos = util_convertToNodeSpace(self:findChild("Node_mojing_TB"),self.m_effect2)
    self.m_effect2:addChild(self.mirrorViewTb,1000)
    local lizi1 = self.mirrorViewTb:findChild("Particle_1")
    local lizi2 = self.mirrorViewTb:findChild("Particle_2")
    if lizi1 and lizi2 then
        lizi1:setDuration(-1)
        lizi1:resetSystem()
        lizi2:setDuration(-1)
        lizi2:resetSystem()
    end
    self.mirrorViewTb:setScale(0.85)
    self.mirrorViewTb:setPosition(pos)
    self.mirrorViewTb.isShow = false
    self.mirrorViewTb:setVisible(false)
end

function CodeGameScreenMagikMirrorMachine:addSmallJackpotTb()
    self.smallJackpotViewTb = util_createView("CodeMagikMirrorSrc.MagikMirrorJackpotSmallView")
    local pos = util_convertToNodeSpace(self:findChild("Node_mojing_TB"),self.m_effect2)
    self.m_effect2:addChild(self.smallJackpotViewTb,1010)
    self.smallJackpotViewTb:setPosition(pos)
    self.smallJackpotViewTb.isShow = false
    self.smallJackpotViewTb:setVisible(false)
end

function CodeGameScreenMagikMirrorMachine:showSmallJackpotTb(jackpotType)
    if self.mirrorViewTb.isShow then
        self.smallJackpotViewTb:changeLight(false)
    else
        self.smallJackpotViewTb:changeLight(true)
    end
    if not self.smallJackpotViewTb.isShow then
        self.smallJackpotViewTb:setVisible(true)
        self.smallJackpotViewTb.isShow = true
        self.smallJackpotViewTb:initViewUi(jackpotType)
    else
        self.smallJackpotViewTb:updateViewUi(jackpotType)
    end
    
end

function CodeGameScreenMagikMirrorMachine:showSmallJackpotTbAct(func)
    if self.smallJackpotViewTb.isShow then
        self.smallJackpotViewTb:showAct(func)
    end
    
end

function CodeGameScreenMagikMirrorMachine:hideSmallJackpotTb(func)
    if self.smallJackpotViewTb.isShow then
        self.smallJackpotViewTb:showOver(func)
        self.smallJackpotViewTb.isShow = false
    end
    
end

--[[
    @desc: ui相关部分
    author:{author}
    time:2023-06-05 20:36:26
    @return:
]]

function CodeGameScreenMagikMirrorMachine:showUiForIndex(index)
    if index == COMMON_INDEX.ONE then
        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("super_bg"):setVisible(false)
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_superfree_reel"):setVisible(false)
        self.m_baseFreeNumBar:setVisible(true)
        
        self.m_baseFreeSpinBar:setVisible(false)
    elseif index == COMMON_INDEX.TWO then
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self.m_gameBg:findChild("super_bg"):setVisible(false)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("Node_superfree_reel"):setVisible(false)
        self.m_baseFreeNumBar:setVisible(false)
        --刷新free次数
        self.m_baseFreeSpinBar:changeFreeImage(false)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
    elseif index == COMMON_INDEX.THREE then
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("super_bg"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_superfree_reel"):setVisible(true)
        self.m_baseFreeNumBar:setVisible(false)
        --刷新free次数
        self.m_baseFreeSpinBar:changeFreeImage(true)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
    end
end

function CodeGameScreenMagikMirrorMachine:initFreeNumBar()
    self.m_baseFreeNumBar = util_createView("CodeMagikMirrorSrc.MagikMirrorFreeNumBarView")
    self:findChild("Node_freebar"):addChild(self.m_baseFreeNumBar)
end

function CodeGameScreenMagikMirrorMachine:addBigMirror()
    self.mirror = util_createView("CodeMagikMirrorSrc.MagikMirrorMirrorView")
    self:findChild("Node_mo1_1"):addChild(self.mirror)
    self:setMirrorLighting(self.mirror)
    self.mirror.isPermanent = true
end

function CodeGameScreenMagikMirrorMachine:addBigWinShow()
    self.bigWinEffect = util_createAnimation("MagikMirror_bigwin.csb")
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
    self:findChild("root"):addChild(self.bigWinEffect,100)
    self.bigWinEffect:setPosition(cc.p(pos.x,(pos.y - 30)))
    self.bigWinSpine = util_spineCreate("MagikMirror_bigwin", true, true)
    self.bigWinEffect:findChild("Node_spine"):addChild(self.bigWinSpine)
    self.bigWinEffect:setVisible(false)
end

function CodeGameScreenMagikMirrorMachine:addGuochangShow()
    self.m_spineGuochang = util_spineCreate("MagikMirror_guochang", true, true)
    self.m_spineGuochang:setScale(self.m_machineRootScale)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)
end

--[[
    过场动画
]]
function CodeGameScreenMagikMirrorMachine:showGuochang(func1,func2)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    self.noClickLayer:setVisible(true)
    self.m_spineGuochang:setVisible(true)
    util_spinePlay(self.m_spineGuochang, "actionframe")
    util_spineEndCallFunc(self.m_spineGuochang, "actionframe", function ()
        self.noClickLayer:setVisible(false)
        self.m_spineGuochang:setVisible(false)
        if type(func2) == "function" then
            func2()
        end
    end)
    self:delayCallBack(70/30,function ()
        if type(func1) == "function" then
            func1()
        end
    end)
end

function CodeGameScreenMagikMirrorMachine:showBigWinEffect()
    self.bigWinEffect:setVisible(true)
    self.m_bigWin2:setVisible(true)
    local particle1 = self.bigWinEffect:findChild("Particle_1")
    local particle2 = self.bigWinEffect:findChild("Particle_2")
    if particle1 and particle2 then
        particle1:resetSystem()
        particle2:resetSystem()
    end
    util_spinePlay(self.m_bigWin2, "actionframe")
    util_spineEndCallFunc(self.m_bigWin2, "actionframe", function ()
        self.m_bigWin2:setVisible(false)
    end)
    if not tolua.isnull(self.bigWinSpine) then
        util_spinePlay(self.bigWinSpine, "actionframe")
    end
    
    self:delayCallBack(2,function ()
        self.bigWinEffect:setVisible(false)
    end)
end

function CodeGameScreenMagikMirrorMachine:addYuGaoCsb()
    self.yuGao1 = util_createAnimation("MagikMirror_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.yuGao1,1)
    local spineAni = util_spineCreate("Socre_MagikMirror_8",true,true)
    self.yuGao1:findChild("Node_spine"):addChild(spineAni)
    self.yuGao1.spineAni = spineAni
    self.yuGao1:setVisible(false)
end

function CodeGameScreenMagikMirrorMachine:showYuGaoCsb()
    -- if self.isFreeYuGao then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_yugao)
    -- else
        -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_bigWin_yugao)
    -- end
    
    self.yuGao1:setVisible(true)
    local particle1 = self.yuGao1:findChild("Particle_1")
    local particle2 = self.yuGao1:findChild("Particle_2")
    self.yuGao1:runCsbAction("actionframe")
    if particle1 and particle2 then
        particle1:resetSystem()
        particle2:resetSystem()
    end
    if not tolua.isnull(self.yuGao1.spineAni) then
        util_spinePlay(self.yuGao1.spineAni,"yugao")
    end
    self:delayCallBack(92/30,function ()
        self.yuGao1:setVisible(false)
    end)
end

function CodeGameScreenMagikMirrorMachine:createReelExpectBG()
    for i=1,6 do
        local expectBg = util_createAnimation("MagikMirror_Scatter_wait.csb")
        self.m_clipParent:addChild(expectBg, -1,SYMBOL_NODE_TAG * 100)
        local reel = self:findChild("sp_reel_" .. (i - 1))
        local reelType = tolua.type(reel)
        if reelType == "ccui.Layout" then
            expectBg:setLocalZOrder(0)
        end
        expectBg:setPosition(cc.p(reel:getPosition()))
        self.expectBgList[i] = expectBg

        expectBg:setVisible(false)
    end
end

function CodeGameScreenMagikMirrorMachine:showReelExpectBgForCol(iCol)
    local expectBg = self.expectBgList[iCol]
    if expectBg then
        expectBg:setVisible(true)
        expectBg:runCsbAction("actionframe",true)
    end
end

function CodeGameScreenMagikMirrorMachine:stopExpectBg()
    for i,node in ipairs(self.expectBgList) do
        if node then
            node:setVisible(false)
        end
    end
end


function CodeGameScreenMagikMirrorMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound( "MagikMirrorSounds/music_MagikMirror_enter.mp3" )
    end)
end

function CodeGameScreenMagikMirrorMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagikMirrorMachine.super.onEnter(self)     -- 必须调用不予许删除
    -- local sMsg = string.format("[CodeGameScreenMagikMirrorMachine:getFakeRotateType] m_symbolType=(%d)", 100)
    --     error(sMsg)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    self.curBetCoins = betCoin
    self:upateBetLevel()
    self:addObservers()
    self:addLiziAndLight()
    if self.m_baseFreeNumBar then
        self.m_baseFreeNumBar:showAutoAction()
    end
end

function CodeGameScreenMagikMirrorMachine:addObservers()
    CodeGameScreenMagikMirrorMachine.super.addObservers(self)
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
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_MagikMirror_base_line_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.isSuperFree then
                soundName = self.m_publicConfig.SoundConfig["sound_MagikMirror_super_line_"..soundIndex] 
            else
                soundName = self.m_publicConfig.SoundConfig["sound_MagikMirror_free_line_"..soundIndex] 
            end
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        
        -- --切换bet显示不同收集bonus
        local betCoin = globalData.slotRunData:getCurTotalBet()
        if self.curBetCoins ~= betCoin then
            self:updateStaginfBonusForBet()
            self.curBetCoins = betCoin
            self:upateBetLevel()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,"SHOW_BONUS_MAP")
end


function CodeGameScreenMagikMirrorMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagikMirrorMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenMagikMirrorMachine:unlockHigherBet()
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


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMagikMirrorMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return "Socre_MagikMirror_Bonus1"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS2 then
        return "Socre_MagikMirror_Bonus2"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMagikMirrorMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMagikMirrorMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS2,count =  2}


    return loadNode
end

--初始化收集的数据（gameConf+ig里存对应bet的收集列表）
function CodeGameScreenMagikMirrorMachine:initGameStatusData( gameData )
    CodeGameScreenMagikMirrorMachine.super.initGameStatusData(self,gameData)
    self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
	local gameConfig = gameData.gameConfig
    if gameConfig and gameConfig.extra then
        if gameConfig.extra.bets then
            self:initBetNetCollectData(gameConfig.extra.bets)
        else
            self.curBonusListForBet = {}
        end
        if gameConfig.extra.freespinCount then
            self.curFreeNum = gameConfig.extra.freespinCount
        else
            self.curFreeNum = 0
        end
    else
        self.curBonusListForBet = {}
        self.curFreeNum = 0
    end
    
end

function CodeGameScreenMagikMirrorMachine:scaleMainLayer()
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
            self.isBigSize = false
            local ratio = display.height / display.width
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            if ratio == 1228 / 768 then
                mainScale = mainScale * 1.03
                tempPosY = 3.5
            elseif ratio >= 1152/768 and ratio < 1228/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            elseif ratio >= 920/768 and ratio < 1152/768 then
                local mul = (1152 / 768 - display.height / display.width) / (1152 / 768 - 920 / 768)
                mainScale = mainScale + 0.05 * mul + 0.03--* 1.16
                tempPosY = 25
                self:findChild("bg"):setScale(1.2)
            elseif ratio < 1152/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(tempPosY)
        else
            self.isBigSize = true
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenMagikMirrorMachine:quicklyStopReel(colIndex)
    --如果是魔镜玩法的stop，则跳过旋转
    if not self.m_isQuickRotate then
        
        --跳过旋转阶段
        self:showMirrorForQuickStop()
        self.m_isQuickRotate = true
    else
        CodeGameScreenMagikMirrorMachine.super.quicklyStopReel(self,colIndex)
    end
end

function CodeGameScreenMagikMirrorMachine:initBetNetCollectData( bets )
	if bets then
		self.curBonusListForBet = bets
	end
end

function CodeGameScreenMagikMirrorMachine:getMinBet( )
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

function CodeGameScreenMagikMirrorMachine:getMirrorCollectNum()
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    if table_length(self.curBonusListForBet) == 0 then
        return 0
    end
    local collectNum = 0
    if self.curBonusListForBet[tostring(betCoin)] then
        collectNum = self.curBonusListForBet[tostring(betCoin)]
    end
    
    return collectNum
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenMagikMirrorMachine:upateBetLevel()
    local minBet = self:getMinBet( )
    self:updatJackpotLock( minBet ) 
    --刷新魔镜收集
    local mirrorCollectNum = self:getMirrorCollectNum()
    self.curBonusNum = mirrorCollectNum
    self.mirror:initCollectKuang(mirrorCollectNum)
    --刷新free次数收集
    if self.m_betLevel == 1 then
        self.m_baseFreeNumBar:updateShowCollectItem(self.curFreeNum)
    end
    
end

function CodeGameScreenMagikMirrorMachine:updatJackpotLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁jackpot
            self.m_jackPotBarView:showJackpotUnLock()
            --解锁进度条
            self.m_baseFreeNumBar:unLockCollect()
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定jackpot
            self.m_jackPotBarView:showJackpotLock()
            --锁定进度条
            self.m_baseFreeNumBar:lockCollect()
        end
        
    end 
end

function CodeGameScreenMagikMirrorMachine:updateReelGridNode(symblNode)
    
    if self:isBonusSymbol(symblNode) then      
        if not symblNode:isLastSymbol() then
            symblNode:runAnim("tuowei",true)
        end
    end
        
    -- if self.isInitReelSymbol and symblNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
    --     symblNode:runAnim("idleframe2",true)
    -- end
end

function CodeGameScreenMagikMirrorMachine:isBonusSymbol(_slotNode)
    if _slotNode then
        if _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS2 then
            return true
        end
    end
    return false
end

----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenMagikMirrorMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- 断线重连 
function CodeGameScreenMagikMirrorMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
        self:setSuperState()
        if self.isSuperFree then
            local avgBet = self.m_runSpinResultData.p_avgBet or nil
            self:showUiForIndex(COMMON_INDEX.THREE)
            self:setMirrorLighting(self.mirror,true)
            self.m_jackPotBarView:setAverageBet(avgBet)
            --平均bet值 展示
            self.m_bottomUI:showAverageBet()
        else
            self:showUiForIndex(COMMON_INDEX.TWO)
            self:setMirrorLighting(self.mirror,true)
        end
        
        self.mirror:showOrHiteKuang(true)
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bets = selfData.bets or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0
    if bonusTrigger > 0 then
         bonusTrigger = 0
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMagikMirrorMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    if self.m_baseFreeNumBar then
        self.m_baseFreeNumBar:showOverAction()
    end
    self.b_gameTipFlagForBigWin = false
    self.isInitReelSymbol = false
    if self.m_bonusTrigger > 0 then
        self.m_bonusTrigger = 0
        self:showRotateOver()
        self:flyAppleStagingToMirror()
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenMagikMirrorMachine:getFreeSpinMusicBG()
    if self.isSuperFree then
        return PublicConfig.SoundConfig.music_MagikMirror_superFreeBgm
    end
    return self.m_fsBgMusicName
end

-- function CodeGameScreenMagikMirrorMachine:resetMusicBg(isMustPlayMusic, musicName)
--     if isMustPlayMusic == nil then
--         isMustPlayMusic = false
--     end
--     local preBgMusic = self.m_currentMusicBgName

--     self:resetCurBgMusicName(musicName)

--     if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
--         if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
--             if self.isSuperFree then
--                 self.m_currentMusicBgName = PublicConfig.SoundConfig.music_MagikMirror_superFreeBgm
--             end
--             self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
--         end
--         if self.m_currentMusicId == nil then
--             if self.isSuperFree then
--                 self.m_currentMusicBgName = PublicConfig.SoundConfig.music_MagikMirror_superFreeBgm
--             end
--             self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
--         end
--     else
--         -- gLobalSoundManager:stopAudio(self.m_currentMusicId)
--         -- self.m_currentMusicId = nil
--         self:clearCurMusicBg()
--     end
-- end

--
--单列滚动停止回调
--
function CodeGameScreenMagikMirrorMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMagikMirrorMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 

end

--[[
    滚轮停止
]]
function CodeGameScreenMagikMirrorMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenMagikMirrorMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMagikMirrorMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bets = selfData.bets or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0
    local freespinCount = selfData.freespinCount

    if bets and table_length(bets) then               --每次spin刷新bet列表
        self.curBonusListForBet = bets
    end

    if self:isShowCollectBonus() > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_COLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_COLLECT_EFFECT -- 动画类型
    end

    if bonusTrigger > 0 then
        self.m_bonusTrigger = bonusTrigger
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GAME_MIRROR_ROTATE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GAME_MIRROR_ROTATE_EFFECT -- 动画类型
    end


end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMagikMirrorMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.GAME_COLLECT_EFFECT then
        self:delayCallBack(0.5,function ()
            self:collectBonusEffect(function ()

                --记录魔镜上的苹果数
                local mirrorCollectNum = self:getMirrorCollectNum()
                self.curBonusNum = mirrorCollectNum

                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end

    if effectData.p_selfEffectType == self.GAME_MIRROR_ROTATE_EFFECT then
        self.rotateEffect = effectData
        self:setMaxMusicBGVolume()
        self:showMirrorRotateEffect(1,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    end

    return true
end

function CodeGameScreenMagikMirrorMachine:beginReel()
    self.isCanChangeBet = true
    self.changeBetNode:stopAllActions()
    CodeGameScreenMagikMirrorMachine.super.beginReel(self)
end

function CodeGameScreenMagikMirrorMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMagikMirrorMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenMagikMirrorMachine:playScatterTipMusicEffect()
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
function CodeGameScreenMagikMirrorMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenMagikMirrorMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenMagikMirrorMachine:checkRemoveBigMegaEffect()
    CodeGameScreenMagikMirrorMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenMagikMirrorMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeMagikMirrorSrc.MagikMirrorFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end


--无赢钱
function CodeGameScreenMagikMirrorMachine:showNoWinView(func)
    self:clearCurMusicBg()
    local view = self:showDialog("NoWin", nil, func,BaseDialog.AUTO_TYPE_ONLY)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenMagikMirrorMachine:showFreeSpinOver(coins, num, func)
    local name = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    if self.isSuperFree then
        name = "SuperFreeSpinOver"
    end
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    if self.isSuperFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_superfreeOver_show)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_freeOver_show)
    end
    
    local view = self:showDialog(name, ownerlist, func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_click)
        if self.isSuperFree then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_superfreeOver_hide)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_freeOver_hide)
        end
        
    end)

    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenMagikMirrorMachine:showFreeSpinOverView(effectData)
    self:clearCurMusicBg()
    --globalData.slotRunData.lastWinCoin
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    local strCoins = util_formatCoins(freeSpinWinCoin,50)
    if freeSpinWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                if self.isSuperFree then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_superTobase_guochang)
                else
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_freeTobase_guochang)
                end
                self:delayCallBack(30/30,function ()
                    if self.m_bonusTrigger > 0 then
                        self.m_bonusTrigger = 0
                        self:showRotateOver()
                        self:flyAppleStagingToMirror()
                    end
                    self:delayCallBack(0.5,function ()
                        self.mirror:showOrHiteKuang(false)
                        local mirrorCollectNum = self:getMirrorCollectNum()
                        self.curBonusNum = mirrorCollectNum
                        if self.isSuperFree then
                            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                            local freespinNum = selfData.freespinCount or 0
                            self.curFreeNum = freespinNum
                            self.m_baseFreeNumBar:resetAllSprite()
                            self.m_jackPotBarView:setAverageBet(nil)
                            --平均bet值 隐藏
                            self.m_bottomUI:hideAverageBet()
                        end
                        self.mirror:initCollectKuang(mirrorCollectNum)
                        self.mirror:runCsbAction("idle1",true)
                        self:setMirrorLighting(self.mirror,false)
                    end)
                end)
                self:showGuochang(function ()
                    self:showUiForIndex(COMMON_INDEX.ONE)
                end,function ()
                    self:setSuperState()
                    self.m_baseFreeNumBar.m_lockStatus = true
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},603)
    else
        local view = self:showNoWinView(function ()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_freeTobase_guochang)
            self:showGuochang(function ()
                self:showUiForIndex(COMMON_INDEX.ONE)
                self.mirror:showOrHiteKuang(false)
                local mirrorCollectNum = self:getMirrorCollectNum()
                self.curBonusNum = mirrorCollectNum
                if self.isSuperFree then
                    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                    local freespinNum = selfData.freespinCount or 0
                    self.curFreeNum = freespinNum
                    self.m_baseFreeNumBar:resetAllSprite()
                    self.m_jackPotBarView:setAverageBet(nil)
                    --平均bet值 隐藏
                    self.m_bottomUI:hideAverageBet()
                end
                self.mirror:initCollectKuang(mirrorCollectNum)
                self.mirror:runCsbAction("idle1",true)
                self:setMirrorLighting(self.mirror,false)
            end,function ()
                self:setSuperState()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
    end
end


function CodeGameScreenMagikMirrorMachine:getTempScatterForTrigger(node)
    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newStartPos = self.m_effectNode:convertToNodeSpace(startPos)
    local newBonusSpine = util_spineCreate("Socre_MagikMirror_Scatter",true,true)
    self.m_effectNode:addChild(newBonusSpine)
    newBonusSpine:setPosition(newStartPos)
    local zOder = self:getBounsScatterDataZorder(self.SYMBOL_FIX_SYMBOL)
    newBonusSpine:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + zOder - node.p_rowIndex)
    return newBonusSpine
end

function CodeGameScreenMagikMirrorMachine:setSuperState()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local type = fsExtraData.type or 0
    if type == 0 then
        self.isSuperFree = false
    else
        self.isSuperFree = true
    end
        
end

function CodeGameScreenMagikMirrorMachine:showEffect_FreeSpin(effectData)
    --设置super标识
    self:setSuperState()
    local tempScatter = {}
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
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

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    local waitTime = 0
    --进入pick界面
    --触发动画
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freespinNum = selfData.freespinCount or 0
    self.curFreeNum = freespinNum
    self:playScatterTipMusicEffect()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    node:setVisible(false)
                    node:changeParentToOtherNode(self.m_clipParent)
                    local newScatterSpine = self:getTempScatterForTrigger(node)
                    tempScatter[#tempScatter + 1] = newScatterSpine
                    util_spinePlay(newScatterSpine, "actionframe", false)
                    util_spineEndCallFunc(newScatterSpine, "actionframe",function()
                        util_spinePlay(newScatterSpine, "idleframe", true)
                    end)
                end
            end
        end
    end
    self:delayCallBack(100/30,function ()
        --刷新free次数框
        if self.m_betLevel == 1 then
            self.m_baseFreeNumBar:updateShowCollectItem(self.curFreeNum)
        end
    end)
    self:delayCallBack(5,function ()
        for i,v in ipairs(tempScatter) do
            if v then
                v:removeFromParent()
            end
        end
        tempScatter = {}
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.p_symbolType then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        node:setVisible(true)
                        node:runAnim("idleframe", true)
                    end
                end
            end
        end
        local waitTimeFree = 0
        if self.isSuperFree and self.m_betLevel == 1 then
            waitTimeFree = 70/60
            self.m_baseFreeNumBar:showTriggerAction()
        end
        self:delayCallBack(waitTimeFree,function ()
            self:showFreePickSpinView(effectData)
        end)

    end)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenMagikMirrorMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeMagikMirrorSrc.MagikMirrorJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

function CodeGameScreenMagikMirrorMachine:updateBottomUICoins(_endCoins,isNotifyUpdateTop,_playWinSound,isPlayAnim,beiginCoins)
    local params = {_endCoins,isNotifyUpdateTop,isPlayAnim,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

-----------jackpot

function CodeGameScreenMagikMirrorMachine:getJackpotList(index)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bets = selfData.bets or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0    --是否触发旋转
    local changeReels = bonusData.reels or {}     --旋转后需要变成wild的信号位置
    local bonusList = bonusData.bonusList or {}         --旋转最终显示;是否jackpot；jackpot钱数；是否旋转（可能会分裂出多个魔镜）
    local rotateTimes = table_length(bonusList)         --旋转轮数
    if rotateTimes <= 0 then
        return {}
    end
    local info = bonusList[index]
    local jackpotList = {}
    for i,v in ipairs(info) do
        local jackpotIndex = v[2]
        local jackpotCoins = v[3]
        if jackpotIndex ~= 0 and v[4] == 1 then
            local jackpotInfo = {jackpotIndex,tonumber(jackpotCoins)}
            jackpotList[#jackpotList + 1] = jackpotInfo
        end
    end
    return jackpotList
end

function CodeGameScreenMagikMirrorMachine:getJackpotCoins()
    local jackpotCoins = 0
    local jackpotInfo = self:isHaveJackpot()
    for i,v in ipairs(jackpotInfo) do
        local coins = v[2]
        if coins ~= 0 then
            jackpotCoins = jackpotCoins + coins
        end
    end
    return jackpotCoins
end

function CodeGameScreenMagikMirrorMachine:showJackpotSmallView(index,jackpotList,func)
    local jackpotNum = #jackpotList
    if index > jackpotNum then
        if func then
            func()
        end
        return
    end
    local jackpotType = jackpotList[index][1]
    local jackpotCoins = jackpotList[index][2]
    local view = util_createView("CodeMagikMirrorSrc.MagikMirrorJackpotSmallView",{
        jackpotType = jackpotType,
        winCoin = jackpotCoins,
        machine = self,
        func = function(  )
            self:showJackpotView(jackpotCoins,jackpotType,function ()
                index = index + 1
                self:showJackpotSmallView(index,jackpotList,func)
            end)
        end
    })

    self:findChild("Node_jackpot_TB"):addChild(view)
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenMagikMirrorMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeMagikMirrorSrc.MagikMirrorJackpotWinView",{
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
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    local a = self.m_runSpinResultData
    if self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
        local endCoins = self.curJackpotCoins + coins
        self:setLastWinCoin(endCoins)
        self:updateBottomUICoins(endCoins,isNotifyUpdateTop,true,true,self.curJackpotCoins)
        self.curJackpotCoins = endCoins
    else
        local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
        local winCoins = self.m_runSpinResultData.p_winAmount or 0
        local curWinCoins = fsWinCoins - winCoins
        local endCoins = curWinCoins + coins
        self:setLastWinCoin(endCoins)
        self:updateBottomUICoins(endCoins,isNotifyUpdateTop,true,true,curWinCoins)
        self.curJackpotCoins = endCoins
    end
    
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

function CodeGameScreenMagikMirrorMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self.curJackpotCoins > 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop,true,self.curJackpotCoins})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
    
end

function CodeGameScreenMagikMirrorMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local reels = self.m_runSpinResultData.p_reels
    local scatterCount = 0
    for iCol = 1,colIndex - 1 do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterCount  = scatterCount + 1
            end
        end
    end

    if colIndex <= 4 then
        return true
    elseif colIndex == 5 and scatterCount >= 1 then
        return true
    elseif colIndex == 6 and scatterCount >= 2 then
        return true
    end

    return false
end

function CodeGameScreenMagikMirrorMachine:isShowLongRun(_slotNode)
    local reelCol = _slotNode.p_cloumnIndex
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN ) then
            return true
        end 
    end
    return false
end

function CodeGameScreenMagikMirrorMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if self:checkSymbolBulingAnimPlay(_slotNode) then
                    if symbolCfg[1] then
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
                
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                if self:isShowLongRun(_slotNode) then
                    self:setSymbolExpect(_slotNode)
                else
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
end

function CodeGameScreenMagikMirrorMachine:setSymbolExpect(_slotNode)
    local iCol = _slotNode.p_cloumnIndex
    self.m_symbolExpectCtr:playExpectAnim(iCol,nil)
end

function CodeGameScreenMagikMirrorMachine:symbolBulingEndCallBack(_slotNode)
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

function CodeGameScreenMagikMirrorMachine:setReelRunInfo()
    -- assert(nil,"自己配置快滚信息")
    local a = self.m_runSpinResultData

    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["anyNumContinuity"] ,["symbolType"] = {200,201}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenMagikMirrorMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenMagikMirrorMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenMagikMirrorMachine:isPlayExpect(reelCol)
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

function CodeGameScreenMagikMirrorMachine:triggerFreeSpinCallFun()
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

function CodeGameScreenMagikMirrorMachine:requestSpinResult()
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
    self.m_iBetLevel = self.m_betLevel
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenMagikMirrorMachine:showFeatureGameTip(_func)
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

function CodeGameScreenMagikMirrorMachine:getFeatureGameTipChance()
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local isNotice = (math.random(1, 100) <= 40) 
        self.isFreeYuGao = true
        return isNotice
    else
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = self.m_runSpinResultData.p_winAmount / lTatolBetNum
        --有大赢
        if winRatio > self.m_BigWinLimitRate then
            local isNotice = (math.random(1, 100) <= 40) 
            self.isFreeYuGao = false
            return isNotice
        end
    end

    return false
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenMagikMirrorMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = true
    self.b_gameTipFlagForBigWin = true
    --动效执行时间
    local aniTime = 95/30
    self:showYuGaoCsb()
    if self.b_gameTipFlag then
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
        return
    end

    if type(func) == "function" then
        func()
    end    
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenMagikMirrorMachine:showEffect_runBigWinLightAni(effectData)

    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1.2,
        animName   = "actionframe",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()

        effectData.p_isPlay = true
        self:playGameEffect()
    end)
    

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenMagikMirrorMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)
    local finishSymbol = self:checkIsHaveSymbolForMirror()
    if finishSymbol == 1 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_Impressive)
    elseif finishSymbol == 2 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_heehee)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_bigWin_yugao)
    self:showBigWinEffect()
    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--判断是否有魔镜玩法且是否有H1或H2图标
function CodeGameScreenMagikMirrorMachine:checkIsHaveSymbolForMirror()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0    --是否触发旋转
    local bonusList = bonusData.bonusList or {}         --旋转最终显示;是否jackpot；jackpot钱数；是否旋转（可能会分裂出多个魔镜）
    local rotateTimes = table_length(bonusList)         --旋转轮数
    if bonusTrigger > 0 then
        local totalBonusList = bonusList[rotateTimes] or {}
        for i,v in ipairs(totalBonusList) do
            if v[1] then
                if v[1] == 0 then
                    return 1
                elseif v[1] == 1 then
                    return 2
                end
            end
        end
    end
    return 0
end

function CodeGameScreenMagikMirrorMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                slotsNode:runAnim("idleframe2",true)
            else
                slotsNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenMagikMirrorMachine:initNoneFeature()
    self.isInitReelSymbol = true
    CodeGameScreenMagikMirrorMachine.super.initNoneFeature(self)
    
end

-----------------------------自定义1：收集苹果玩法

function CodeGameScreenMagikMirrorMachine:isShowCollectBonus()
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local bonusNum = table_length(storedIcons) or 0

    return bonusNum
end

function CodeGameScreenMagikMirrorMachine:collectBonusEffect(func)
    
    local totalNum = self:isShowCollectBonus()
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_bonus_collect)
    for index = 1,totalNum do
        --获取移动初始位置
        local symbolIndex = storedIcons[index]
        if not symbolIndex then
            if type(func) == "function" then
                func()
            end
            return
        end
        local symbolNode = self:getSymbolByPosIndex(symbolIndex)
        local type = symbolNode.p_symbolType or nil
        local startPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
        --获取移动最终位置
        local endPos = nil
        local bonusNumIndex = index
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local freeEndNode = self.mirror:findChild("Node_shouji_free_1")
            endPos = util_convertToNodeSpace(freeEndNode,self.m_effectNode)
        else
            bonusNumIndex = self.curBonusNum + index
            if bonusNumIndex > 6 then
                local stagingIndex = bonusNumIndex % 6
                self.stagingNum = self.stagingNum + 1
                local stagingNode = self:findChild("Node_mojing_qipan_"..stagingIndex)
                endPos = util_convertToNodeSpace(stagingNode,self.m_effectNode)
            else
                local endNode = self.mirror:findChild("Node_shouji_"..bonusNumIndex)
                endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
            end
        end
        
        --飞行
        
        self:flyBonusForCollect(symbolNode,startPos,endPos,type,bonusNumIndex,self.stagingNum)
    end
    local waitTime = 1
    if bonusTrigger == 1 then
        waitTime = 2
    end

    
    self:delayCallBack(waitTime,function ()

        if type(func) == "function" then
            func()
        end
        if bonusTrigger ~= 1 then
            self.isCanChangeBet = false
            self.m_baseFreeNumBar.m_lockStatus = false
            self.m_bottomUI:updateBetEnable(false)
            self.changeBetNode:stopAllActions()
            performWithDelay(self.changeBetNode,function ()
                local features = self.m_runSpinResultData.p_features or {}
                if #features >= 2 and features[2] > 0 then
                    
                else
                    if not self.isCanChangeBet then
                        self.m_baseFreeNumBar.m_lockStatus = true
                        self.m_bottomUI:updateBetEnable(true)
                    end
                    
                end
            end,1.5)
        end
    end)
    
end

--苹果播动画以及飞行
function CodeGameScreenMagikMirrorMachine:flyBonusForCollect(symbolNode,startPos,endPos,type,bonusNumIndex,stagingNum)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0

    local apple = self:createTempFlyBonus(type)
    self.m_effectNode:addChild(apple)
    apple:setLocalZOrder(10000 + symbolNode.p_cloumnIndex * 10 - symbolNode.p_rowIndex)
    apple:setPosition(startPos)
    local particle1 = nil
    local waitTime = 20/30
    -- if stagingNum > 0 then
    --     waitTime = 40/30
    -- end
    if not tolua.isnull(apple.lizi) then
        particle1 = apple.lizi:findChild("Particle_1")
    end
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if not tolua.isnull(apple.tempBonus) then
            util_spinePlay(apple.tempBonus, "shouji")
        end
    end)
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        --将bonus小块变成wild
        self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
        symbolNode:runAnim("start",false,function ()
            symbolNode:runAnim("idleframe2",true)
        end)
        if particle1 then
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle1:setPositionType(0)   --设置可以拖尾
            particle1:resetSystem()
        end
    end)
    actList[#actList + 1] = cc.EaseExponentialIn:create(cc.MoveTo:create(0.5, endPos))
    
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.mirror:updateCollectFreeKuang()
        else
            if stagingNum > 0 then
                --将苹果收集到暂存区域
                self:createTempBonusForStaging(type,stagingNum)
            else
                self.mirror:updateCollectKuang(bonusNumIndex)
            end
        end
        
        
        apple.tempBonus:setVisible(false)
        if particle1 then
            particle1:stopSystem()--移动结束后将拖尾停掉
        end
    end) 
    actList[#actList + 1] = cc.DelayTime:create(0.5)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        apple:removeFromParent()
    end) 
    apple:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenMagikMirrorMachine:createTempFlyBonus(type)
    local apple = util_createAnimation("MagikMirror_bonus_guadian.csb")
    local tempBonus = nil
    local lizi = nil
    if type and type == self.SYMBOL_SCORE_BONUS2 then
        tempBonus = util_spineCreate("Socre_MagikMirror_Bonus2", true, true)
        lizi = util_createAnimation("MagikMirror_bonuslizi2.csb")
    else
        tempBonus = util_spineCreate("Socre_MagikMirror_Bonus1", true, true)
        lizi = util_createAnimation("MagikMirror_bonuslizi1.csb")
    end
    apple:findChild("spine"):addChild(tempBonus)
    apple:findChild("lizi"):addChild(lizi)
    apple.tempBonus = tempBonus
    apple.lizi = lizi
    return apple
end

function CodeGameScreenMagikMirrorMachine:createTempBonusForStaging(type,stagingNum)
    local tempBonusCsb = util_createAnimation("MagikMirror_mojing_shouji_idle.csb")
    local tempBonus = util_spineCreate("Socre_MagikMirror_Bonus1", true, true)
    if type and type == self.SYMBOL_SCORE_BONUS2 then
        tempBonus = util_spineCreate("Socre_MagikMirror_Bonus2", true, true)
    end
    tempBonusCsb:findChild("Node_apple"):addChild(tempBonus)
    tempBonusCsb.m_spine = tempBonus
    local stagingNode = self:findChild("Node_mojing_qipan_"..stagingNum)
    if stagingNode then
        stagingNode:addChild(tempBonusCsb)
        tempBonusCsb:runCsbAction("idle",true)
        util_spinePlay(tempBonus, "shouji_idle",true)
        stagingNode.tempBonusCsb = tempBonusCsb
    end
end

--spin数据回来后停轮前将暂存区苹果移动到魔镜上
function CodeGameScreenMagikMirrorMachine:flyAppleStagingToMirror(func)
    if self.stagingNum <= 0 then
        self.stagingNum = 0
        if func then
            func()
        end
        return
    end
    --将暂存的苹果移动到镜子上并在暂存区域清除
    if self.stagingNum > 0 then
        self:clearStagingBonus()
    end

    for i=1,self.stagingNum do
        local stagingNode = self:findChild("Node_mojing_qipan_"..i)
        local stagingPos = util_convertToNodeSpace(stagingNode,self.m_effectNode)
        local endNode = self.mirror:findChild("Node_shouji_"..i)
        local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
        local apple = self:createTempFlyBonus(self.SYMBOL_SCORE_BONUS1)
        apple:findChild("lizi"):setVisible(false)
        util_spinePlay(apple.tempBonus, "shouji_idle")
        self.m_effectNode:addChild(apple,i)
        apple:setPosition(stagingPos)
        local particle1 = nil
        
        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            if not tolua.isnull(apple.tempBonus) then
                util_spinePlay(apple.tempBonus, "shouji2")
            end
        end)
        actList[#actList + 1] = cc.MoveTo:create(0.5, endPos)
        actList[#actList + 1] = cc.CallFunc:create(function (  )

            self.mirror:updateCollectKuang(i)
            
            apple.tempBonus:setVisible(false)
        end) 
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            apple:removeFromParent()
        end) 
        apple:runAction(cc.Sequence:create( actList))
    end

    self:delayCallBack(1,function ()
        self.stagingNum = 0
        if func then
            func()
        end
    end)
end

function CodeGameScreenMagikMirrorMachine:updateStaginfBonusForBet()
    if self.stagingNum > 0 then
        self:clearStagingBonus()
        local num = self.stagingNum
        for i=1,num do
            self.mirror:updateCollectKuang(i)
        end
        self.stagingNum = 0
    end
end

function CodeGameScreenMagikMirrorMachine:clearStagingBonus()
    for i=1,5 do
        local stagingNode = self:findChild("Node_mojing_qipan_"..i)
        local children = stagingNode:getChildren()
        for k,node in pairs(children) do
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
end

---------------------------------------------自定义2：魔镜旋转

--随机变化次数
function CodeGameScreenMagikMirrorMachine:getRotateNum()
    local num = math.random(5,8)
    return num - 1
end

--是否是普通图标
function CodeGameScreenMagikMirrorMachine:isOrdinaryType(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 or
                symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 or
                    symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 or
                        symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        return true
    end
    return false
end

--获取不会转出的类型
function CodeGameScreenMagikMirrorMachine:getNoRotateType(info)
    local noRotateList = {}
    for i,v in ipairs(info) do
        if info[i][4] == 0 then
            noRotateList[#noRotateList + 1] = info[i][1]
        end
    end
    return noRotateList
end

--是否是已经固定魔镜显示的图标
function CodeGameScreenMagikMirrorMachine:checkIsNoRotateType(info,symbolType)
    local noRotateList = self:getNoRotateType(info)
    for i,v in ipairs(noRotateList) do
        if symbolType == v then
            return false
        end
    end
    return true
end

function CodeGameScreenMagikMirrorMachine:getJackpotName(index)
    if index == 1 then
        return "grand"
    elseif index == 2 then
        return "major"
    elseif index == 3 then
        return "minor"
    elseif index == 4 then
        return "mini"
    end
end

function CodeGameScreenMagikMirrorMachine:isHaveJackpotForFake(jackpotType)
    local jackpotName =  string.lower(jackpotType) 
    if jackpotName == "grand" or
        jackpotName == "major" or
            jackpotName == "minor" or
                jackpotName == "mini" then
        return true
    end
    return false
end

function CodeGameScreenMagikMirrorMachine:getJackpotIndex(jackpotType)
    local jackpotName =  string.lower(jackpotType) 
    if jackpotName == "grand" then
        return 1
    elseif jackpotName == "major" then
        return 2
    elseif jackpotName == "minor" then
        return 3
    elseif jackpotName == "mini" then
        return 4
    end
end

function CodeGameScreenMagikMirrorMachine:checkOtherMirrorImage(index,symbolType)
    if not index then 
        return true
    end
    for i,list in pairs(self.allTempRotateList) do
        local type =  list[index][1]
        if type == symbolType then
            return false
        end
    end
    return true
end

function CodeGameScreenMagikMirrorMachine:getReelsSymbolForRotate()
    local function isRepeatType(type,list)
        for i,v in ipairs(list) do
            if type == v then
                return true
            end
        end
        return false
    end
    local list = {}
    local reels = self.m_runSpinResultData.p_reels or {}
    for i,v in ipairs(reels) do
        for j,type in ipairs(v) do
            if self:isOrdinaryType(type) and not isRepeatType(type,list) then
                list[#list + 1] = type
            end
        end
    end
    return list
end

--随机棋盘上有的类型
function CodeGameScreenMagikMirrorMachine:getFakeRotateType(info,index,num,list,isAddMirrorType,isAddJackpotType,overType,getIndex)
    getIndex = getIndex + 1
    
    local listNum = #self.reelsSymbolList
    
    local reels = self.m_runSpinResultData.p_reels or {}
    local showJackpotName = 0

    local beforeSymbolList = list[index - 1] or {}
    local beforeSymbol = nil
    if table_length(beforeSymbolList) > 0 then
        beforeSymbol = beforeSymbolList[1]
    end

    if getIndex > 500 then
        if beforeSymbol then
            return beforeSymbol,showJackpotName
        else
            return self.reelsSymbolList[listNum],showJackpotName
        end
        
        
    end
    --随机行列
    local randomNum = math.random(1,listNum)
    --第几个展示魔镜本身
    local addMirror = math.ceil(num/2)
    local randomJackpotIndex = math.random(1,4)
    local addJackpot = math.ceil(num/3)
    if isAddJackpotType and addJackpot == index then
        showJackpotName = self:getJackpotName(randomJackpotIndex)
    end
    local symbolType = self.reelsSymbolList[randomNum]
    if isAddMirrorType and addMirror == index then
        symbolType = 100
    end
    -- if totalNum > 100 then
    --     local sMsg = string.format("[CodeGameScreenMagikMirrorMachine:getFakeRotateType] m_symbolType=(%d)", symbolType)
    --     error(sMsg)
    -- end
    if symbolType == 100 then   --如果是魔镜本身，直接返回
        return symbolType,showJackpotName
    end
    if index > 1 then   --大于1时需要判断是否与前一个图标相同
        
        
        if index == num then    --最后一个需要判断是否与最终确定的图标相同
            --普通图标、已经固定的图标、前一个图标、其他魔镜同样位置的图标、最终确认的图标
            if symbolType and self:checkIsNoRotateType(info,symbolType) and beforeSymbol ~= symbolType and self:checkOtherMirrorImage(index,symbolType) and symbolType ~= overType then
                return symbolType,showJackpotName
            else
                return self:getFakeRotateType(info,index,num,list,isAddMirrorType,isAddJackpotType,overType,getIndex)
            end
        else
            --普通图标、已经固定的图标、前一个图标、其他魔镜同样位置的图标
            if symbolType and self:checkIsNoRotateType(info,symbolType) and beforeSymbol ~= symbolType and self:checkOtherMirrorImage(index,symbolType) then

                return symbolType,showJackpotName
            else
                return self:getFakeRotateType(info,index,num,list,isAddMirrorType,isAddJackpotType,overType,getIndex)
            end
        end
        
    else
        --普通图标、已经固定的图标、其他魔镜同样位置的图标
        if symbolType and self:checkIsNoRotateType(info,symbolType) and self:checkOtherMirrorImage(index,symbolType) then

            return symbolType,showJackpotName
        else
            return self:getFakeRotateType(info,index,num,list,isAddMirrorType,isAddJackpotType,overType,getIndex)
        end
    end
        
    
end

function CodeGameScreenMagikMirrorMachine:getRotateListForNum(overType,overJackpot,num,info,isAddMirrorType,isAddJackpotType)
    self.reelsSymbolList = self:getReelsSymbolForRotate()
    local tempList = {}
    for i=1,num do
        local fakeType,fakeJackpot = self:getFakeRotateType(info,i,num,tempList,isAddMirrorType,isAddJackpotType,overType,1)
        if fakeType == 100 then
            isAddMirrorType = false
        end
        if fakeJackpot ~= 0 then
            isAddJackpotType = false
        end
        tempList[#tempList + 1] = {fakeType,fakeJackpot}
    end
    tempList[#tempList + 1] = {overType,overJackpot}
    return tempList
end

--将旋转的魔镜与正常base的区分开，方便分裂多个魔镜.
--旋转轮数：转出魔镜本身后，分裂并且再次进行旋转
--旋转圈数：每一轮旋转的圈数
--self.m_rotateNode
function CodeGameScreenMagikMirrorMachine:showMirrorRotateEffect(roundIndex,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bets = selfData.bets or {}
    local bonusData = selfData.bonusData or {}
    local bonusTrigger = bonusData.bonusTrigger or 0    --是否触发旋转
    local changeReels = bonusData.reels or {}     --旋转后需要变成wild的信号位置
    local bonusList = bonusData.bonusList or {}         --旋转最终显示;是否jackpot；jackpot钱数；是否旋转（可能会分裂出多个魔镜）
    local rotateTimes = table_length(bonusList)         --旋转轮数
    if roundIndex > rotateTimes then
        self.m_isQuickRotate = true
        self:delayCallBack(0.5,function ()
            self.isSoundForThreeMirror = true
            self:hideAllLiziAndLighting()
            --将服务器给的位置变成wild
            self:changeReelsSymbolWild()
            -- self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
            if self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
                self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
            else
                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            end
            if #self.m_runSpinResultData.p_winLines == 0 then
                if self:checkHasBigWin() == false then
                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount,self.GAME_MIRROR_ROTATE_EFFECT)
                end
            end
            -- self:showRotateOver()

            -- self:flyAppleStagingToMirror(function ()
                self:delayCallBack(1.5,function ()
                    if type(func) == "function" then
                        func()
                    end
                end)
            -- end)
        end)
        return
    end
    
    self.rotateIndexForQuickStop = roundIndex
    
    local waitTime = 0
    local waitTime2 = 0
    if roundIndex + 1 <= rotateTimes then
        waitTime2 = 2
    end
    if roundIndex == 1 then
        waitTime = 70/60
    end
    local num = self:getRotateNum()
    local waitTime1 = 1.5 * num
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if roundIndex == 1 then
            self.mirror:triggerRotateEffect()
        else
            
        end
    end)
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if roundIndex == 1 then
            --第一轮只有一个魔镜
            self.mirror:setVisible(false)
            local mirror = self:createMojingForRotate(1,1)
        end
        -- 打开stop按钮的点击状态 
        -- 修改的状态取自 SpinBtn:btnStopTouchEnd() 内判断的状态数据
        self.m_bottomUI.m_spinBtn.m_btnStopTouch = false
        globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
        globalData.slotRunData.isClickQucikStop = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        self.m_isQuickRotate = false

        self:showMirrorRotateEffectIndex(roundIndex,num)
    end)
    actList[#actList + 1] = cc.DelayTime:create(waitTime1 + 3)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        self.m_isQuickRotate = true
        --是否有jackpot
        local jackpotList = self:getJackpotList(roundIndex)
        if #jackpotList > 0 then
            --展示jackpot弹板
            self:showSmallJackpotTbAct(function ()
                self:hideSmallJackpotTb(function ()
                    self.smallJackpotViewTb:setVisible(false)
                    self.smallJackpotViewTb.isShow = false
                end)
                self:showJackpotView(jackpotList[1][2],jackpotList[1][1],function ()
                    
                    if roundIndex + 1 <= rotateTimes then
                        --缩放移动，新的魔镜生成、移动
                        self:divisionMirrorEffect(roundIndex + 1)
                    end
                    self:delayCallBack(waitTime2,function ()
                        roundIndex = roundIndex + 1
                        self:showMirrorRotateEffect(roundIndex,func)
                    end)
                end)
            end)
        else
            if roundIndex + 1 <= rotateTimes then
                --缩放移动，新的魔镜生成、移动
                self:divisionMirrorEffect(roundIndex + 1)
            end
            self:delayCallBack(waitTime2,function ()
                roundIndex = roundIndex + 1
                self:showMirrorRotateEffect(roundIndex,func)
            end)
        end
    end)
    local sq = cc.Sequence:create(actList)
    self.m_effect1:runAction(sq)
end

--旋转每一轮
function CodeGameScreenMagikMirrorMachine:showMirrorRotateEffectIndex(roundIndex,num,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusList = bonusData.bonusList or {}
    local rotateTimes = table_length(bonusList)         
    local info = bonusList[roundIndex] or {}
    self.allTempRotateList = {}
    
    if table_length(info) == 0 then
        return
    end
    
    local randomMirror = self:randomOneMirrorForMirror(info)
    local randomMirrorForJackpot = self:randomOneMirrorForJackpot(info)
    for i,v in ipairs(info) do
        --获取对应镜子
        if info[i][4] == 1 then
            local isAddMirrorType = false
            local isAddJackpotType = false
            if i == randomMirror then
                isAddMirrorType = true
            end
            if i == randomMirrorForJackpot then
                isAddJackpotType = true
            end
            --播放动画
            local tempList = self:getRotateListForNum(info[i][1],info[i][2],num,info,isAddMirrorType,isAddJackpotType)
            self.allTempRotateList[i] = tempList
        end
    end
    local isShowSound = true
    if #self.rotateMirrorList > 3 and self.isSoundForThreeMirror then
        self.isSoundForThreeMirror = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_Terrific)
    end
    
    for i,v in ipairs(info) do
        --获取对应镜子
        local mirror = self.rotateMirrorList[i]
        if not tolua.isnull(mirror) and info[i][4] == 1 then
            local isOverEffect = false
            if roundIndex == rotateTimes and i == #info then   --最后转一次，玩法即将结束
                isOverEffect = true
            end
            --播放动画
            local tempList = self.allTempRotateList[i]
            self:showImageForRotate(1,tempList,mirror,info[i],i,isShowSound,isOverEffect)
            isShowSound = false
        end
    end
end

--随机一个可以转动的镜子
function CodeGameScreenMagikMirrorMachine:randomOneMirrorForMirror(info)
    local tempList = {}
    for i,v in ipairs(info) do
        if info[i][4] == 1 then
            tempList[#tempList + 1] = i
        end
    end
    local tempIndex = math.random(1,#tempList)
    return tempList[tempIndex]
end

function CodeGameScreenMagikMirrorMachine:randomOneMirrorForJackpot(info)
    local tempList = {}
    for i,v in ipairs(info) do
        if info[i][4] == 1 then
            tempList[#tempList + 1] = i
        end
    end
    local tempIndex = math.random(1,#tempList)
    return tempList[tempIndex]
end


--每一个镜子展示不同图片
function CodeGameScreenMagikMirrorMachine:showImageForRotate(showImageIndex,list,mirror,info,mirrorIndex,isShowSound,isOverEffect)
    local listLen = table_length(list)
    if showImageIndex > listLen then
        self.isOverEffect = 0
        return
    end
    local fakeType = nil
    local fakeJackpot = 0
    local lastJackpot = 0
    local lastType = nil
    if list[showImageIndex] and list[showImageIndex][1] and list[showImageIndex][2] then
        fakeType = list[showImageIndex][1]
        fakeJackpot = list[showImageIndex][2] or 0
    end
    if list[showImageIndex - 1]and list[showImageIndex - 1][1] and list[showImageIndex - 1][2] then
        lastType = list[showImageIndex - 1][1]
        lastJackpot = list[showImageIndex - 1][2] or 0
    end
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local isLast = false

        --展示图片的同时，棋盘上对应类型变为金色
        if showImageIndex == listLen then    --若有jackpot，显示
            isLast = true
        end
        -- local isOverEffect = self.isOverEffect
        -- self.isOverEffect = self.isOverEffect - 1
        mirror:showRotateEffect(lastType,fakeType,isLast,isOverEffect)
        --若转出魔镜，添加魔镜弹板，为不改变流程，添加临时  
        if not self.mirrorViewTb.isShow and fakeType == 100 then
            if isLast then
                local isNotice = (math.random(1, 100) <= 30) 
                if isNotice then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_happening)
                end
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_mirror_changeMirror)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_mirror_changeMirror2)
            end
            self:showMirrorTb(true)
        elseif self.mirrorViewTb.isShow and lastType == 100 then
            self.mirrorViewTb.isShow = false
            self.mirrorViewTb:runCsbAction("over",false) 
        end

        --jackpot光和弹板
        if showImageIndex == listLen then
            local isHaveJackpot = info[2] or 0
            if isHaveJackpot ~= 0 then
                mirror:showJackpotLightForIndex(isHaveJackpot,false,true)   --魔镜上的光效
                self:showSmallJackpotTb(isHaveJackpot)    --棋盘上的小弹板
            end
        else
            mirror:showJackpotLightForIndex(fakeJackpot,false,false)--魔镜上的光效
            if self:isHaveJackpotForFake(fakeJackpot) then
                if isLast then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_mirror_changejp)
                end
                self:showSmallJackpotTb(fakeJackpot)    --棋盘上的小弹板
            elseif self:isHaveJackpotForFake(lastJackpot) then
                self:hideSmallJackpotTb()--棋盘上的小弹板
                mirror:showJackpotForIndex(0)   --魔镜上的字
            end
        end
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(1.5/2)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if showImageIndex == listLen then    --若有jackpot，显示
            local isHaveJackpot = info[2] or 0
            mirror:showJackpotForIndex(isHaveJackpot)
        else
            if self:isHaveJackpotForFake(fakeJackpot) then
                mirror:showJackpotForIndex(fakeJackpot)--魔镜上的字
            end
        end
        
        if isShowSound then
            self.isLightSound = true
            self.isChangeSound = true
        end

        self:changeReelSymbolForType(lastType,fakeType,showImageIndex,mirrorIndex,isShowSound)
    end)
    actList[#actList + 1] = cc.DelayTime:create(1.5/2)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        showImageIndex = showImageIndex + 1
        self:showImageForRotate(showImageIndex,list,mirror,info,mirrorIndex,isShowSound,isOverEffect)
    end)
    local sq = cc.Sequence:create(actList)
    mirror:runAction(sq)
end

function CodeGameScreenMagikMirrorMachine:showMirrorTb(isShow)
    if isShow then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:setMirrorLighting(self.mirrorViewTb,true)
        else
            self:setMirrorLighting(self.mirrorViewTb)
        end
        self.mirrorViewTb.isShow = true
        self.mirrorViewTb:setVisible(true)
        self.mirrorViewTb:runCsbAction("start")
    else
        self.mirrorViewTb.isShow = false
        self.mirrorViewTb:setVisible(false)
    end
end

function CodeGameScreenMagikMirrorMachine:getChangeSymbolActName(type,ischange)
    if ischange then
        if type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
            return "actionframe3"
        else
            return "actionframe4"
        end
    else
        if type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
            return "actionframe4"
        else
            return "actionframe3"
        end
    end
end

--[[
    @desc: 如果要隐藏的图片是其他镜子要显示的图片，则不变化
    author:{author}
    time:2023-06-26 14:27:53
    --@lastType:
	--@type: 
    @return:
]]
function CodeGameScreenMagikMirrorMachine:isNoChange(lastType,index,mirrorIndex)
    local list = self.allTempRotateList[index]
    for i,v in pairs(self.allTempRotateList) do
        -- if i ~= mirrorIndex then
            if v[index] then
                if v[index][1] == lastType then
                    return true
                end
            end
            
        -- end
    end
    return false
end

--将对应类型的小块变成金色或者取消金色
function CodeGameScreenMagikMirrorMachine:changeReelSymbolForType(lastType,type,index,mirrorIndex,isShowSound)
    -- if lastType and type and lastType == type then
    --     return
    -- end
    --遍历棋盘
    if lastType then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.p_symbolType then
                    if node.p_symbolType == lastType then
                        if self:isNoChange(lastType,index,mirrorIndex) then
                            
                        else
                            local actName = self:getChangeSymbolActName(lastType,false)
                            --取消金色
                            node:runAnim(actName)
                            self:showLiziAndLighting(node,false,false,isShowSound)
                            self:putSymbolBackToPreParent(node)
                        end
                        
                        
                    end
                end
            end
        end
    end
    if type then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node and node.p_symbolType then
                    if node.p_symbolType == type then
                        --将小块提层
                        self:changeSymbolToClipParent(node)
                        node:runAnim("idleframe")
                        --在小块上添加粒子和背光
                        self:showLiziAndLighting(node,true,false,isShowSound)
                        --变成金色
                        if isShowSound and self.isChangeSound then
                            if type ~= 100 then
                                self.isChangeSound = false
                                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_symbol_changeGold)
                            end
                        end
                        node:runAnim("actionframe2")
                    
                    end
                end
            end
        end
    end
    
end

function CodeGameScreenMagikMirrorMachine:addLiziAndLight()
    self.liziAndLightList = {}
    for iCol = 1, self.m_iReelColumnNum do
        self.liziAndLightList[iCol] = {}
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local lightPos = util_convertToNodeSpace(node,self:findChild("Node_light"))
                local liziPos = util_convertToNodeSpace(node,self:findChild("Node_lizi"))
                local lizi = util_spineCreate("Socre_MagikMirror_9", true, true)
                local lighting = util_spineCreate("Socre_MagikMirror_9", true, true)
                local lighting2 = util_spineCreate("Socre_MagikMirror_9", true, true)
                self:findChild("Node_light"):addChild(lighting2,1)
                self:findChild("Node_light"):addChild(lighting,2)
                self:findChild("Node_lizi"):addChild(lizi)
                lighting:setPosition(lightPos)
                lighting2:setPosition(lightPos)
                lizi:setPosition(liziPos)
                lighting:setVisible(false)
                lighting2:setVisible(false)
                lizi:setVisible(false)
                self.liziAndLightList[iCol][iRow] = {lizi,lighting,lighting2}
            end
            
        end
    end
end

function CodeGameScreenMagikMirrorMachine:showLiziAndLighting(node,isShow,isQuick,isShowSound)
    local symbolType = node.p_symbolType
    if node.p_rowIndex and node.p_cloumnIndex then
        local list = self.liziAndLightList[node.p_cloumnIndex][node.p_rowIndex]
        local lizi = list[1]
        local lighting = list[2]
        local lighting2 = list[3]
        if lighting and lizi and lighting2 then
            if isQuick then
                if isShow then
                    lighting:stopAllActions()
                    util_spinePlay(lighting, "idleframe3")
                    lighting:setVisible(true)
                    lighting2:setVisible(false)
                    lizi:setVisible(false)
                    if symbolType and (symbolType == 0 or symbolType == 1) then
                        util_spinePlay(lighting, "zhuan", true)
                    else
                        util_spinePlay(lighting, "zhuan_small", true)
                    end
                else
                    lighting:stopAllActions()
                    lighting:setVisible(false)
                    lizi:setVisible(false)
                    lighting2:setVisible(false)
                end
                
            else
                if isShow then
                    lighting:stopAllActions()

                    lizi:setVisible(true)
                    lighting2:setVisible(true)
                    if isShowSound and self.isLightSound then
                        self.isLightSound = false
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_symbol_buling)
                    end
                    if symbolType and (symbolType == 0 or symbolType == 1) then
                        util_spinePlay(lizi, "zhuan1")
                        util_spinePlay(lighting2, "zhuan2")
                    else
                        util_spinePlay(lizi, "zhuan1_small")
                        util_spinePlay(lighting2, "zhuan2_small")
                    end
                    
                    performWithDelay(lighting,function ()
                        lizi:setVisible(false)
                        lighting2:setVisible(false)
                        util_spinePlay(lighting, "idleframe3")
                        lighting:setVisible(true)
                        if symbolType and (symbolType == 0 or symbolType == 1) then
                            util_spinePlay(lighting, "zhuan", true)
                        else
                            util_spinePlay(lighting, "zhuan_small", true)
                        end
                    end,50/30)
                else
                    lighting:stopAllActions()
                    lighting:setVisible(false)
                    lighting2:setVisible(false)
                    lizi:setVisible(false)
                end
            end
            
        end
    end
end

function CodeGameScreenMagikMirrorMachine:hideAllLiziAndLighting()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local list = self.liziAndLightList[iCol][iRow]
            if list[1] and list[2] and list[3] then
                list[1]:setVisible(false)
                list[2]:setVisible(false)
                list[3]:setVisible(false)
            end
        end
    end
end

--旋转结束后，变wild
function CodeGameScreenMagikMirrorMachine:changeReelsSymbolWild()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local changeList = bonusData.reels or {}
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_symbol_changeWild)
    for i,index in ipairs(changeList) do
        local symbolNode = self:getSymbolByPosIndex(index)
        if symbolNode then
            local type = symbolNode.p_symbolType
            self:putSymbolBackToPreParent(symbolNode)
            self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
            --wild时间线
            symbolNode:runAnim("start",false,function ()
                symbolNode:runAnim("idleframe2",true)
            end)
            --假小块时间线
            local fakeNode = self:createSymbolAniNode(type)
            local pos = util_convertToNodeSpace(symbolNode,self.m_effect2)
            self.m_effect2:addChild(fakeNode)
            fakeNode:setPosition(pos)
            local actName = self:getChangeSymbolActName(type,true)
            fakeNode:runAnim(actName)
            self:delayCallBack(0.5,function ()
                fakeNode:removeSymbolAniNode()
            end)
        end
    end
end

--棋盘上的魔镜弹板
function CodeGameScreenMagikMirrorMachine:createNewMirrorView(num)
    local mirrorView = util_createAnimation("MagikMirror_mojing_TB.csb")
    local pos = util_convertToNodeSpace(self:findChild("Node_mojing_TB"),self.m_effect2)
    self.m_effect2:addChild(mirrorView)
    mirrorView:setScale(0.85)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setMirrorLighting(mirrorView,true)
    else
        self:setMirrorLighting(mirrorView)
    end
    mirrorView:setPosition(pos)
    return mirrorView
end

--缩放移动，新的魔镜生成、移动
function CodeGameScreenMagikMirrorMachine:divisionMirrorEffect(index)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusList = bonusData.bonusList or {}
    local info = bonusList[index]
    local totalNum = table_length(info)     --魔镜总数
    if totalNum <= 0 then
        return
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_Mirror_fly)
    --分裂前的进行移动
    local lastInfo = bonusList[index - 1] or {}
    local actScaleIndex = MIRROR_SCALE[totalNum]
    for i,v in ipairs(lastInfo) do
        local lastMirror = self.rotateMirrorList[i]
        if lastMirror then
            --移动
            local endPos = util_convertToNodeSpace(self:findChild("Node_mo".. totalNum .."_" ..i),self.m_effect1)
            local scaleAct = cc.ScaleTo:create(0.5, actScaleIndex)
            local moveAct = cc.MoveTo:create(0.5,endPos)
            local act_move = cc.Spawn:create(scaleAct,moveAct)
            lastMirror:runAction(act_move)
        end
    end

    local lastNum = table_length(lastInfo)
    --新创建的从弹板移动到指定位置
    for i = lastNum + 1,totalNum do
        local tempMirror = self:createNewMirrorView()
        --清理转出魔镜时临时的魔镜弹板，为了不改变之前的流程，故而如此处理
        local lizi = tempMirror:findChild("Particle_4")
        local lizi2 = tempMirror:findChild("Particle_1")
        local lizi3 = tempMirror:findChild("Particle_2")
        local moveEndPos = util_convertToNodeSpace(self:findChild("Node_mo".. totalNum .."_" ..i),self.m_effect2)
        local scaleAct1 = cc.ScaleTo:create(0.5, actScaleIndex)
        local moveAct1 = cc.EaseIn:create(cc.MoveTo:create(0.5,moveEndPos),2)
        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            if self.mirrorViewTb.isShow then
                self:showMirrorTb(false)
            end
            tempMirror:runCsbAction("fly")
            if lizi and lizi2 and lizi3 then
                lizi:setDuration(-1)     --设置拖尾时间(生命周期)
                lizi:setPositionType(0)   --设置可以拖尾
                lizi:resetSystem()
                lizi2:setDuration(-1)     --设置拖尾时间(生命周期)
                lizi2:setPositionType(0)   --设置可以拖尾
                lizi2:resetSystem()
                lizi3:setDuration(-1)     --设置拖尾时间(生命周期)
                lizi3:setPositionType(0)   --设置可以拖尾
                lizi3:resetSystem()
            end
        end)
        actList[#actList + 1] = cc.Spawn:create(scaleAct1,moveAct1)
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            local mirror = self:createMojingForRotate(i,totalNum)
            mirror:showFlyEndAction()
            tempMirror:setVisible(false)
            if lizi and lizi2 and lizi3 then
                lizi:stopSystem()--移动结束后将拖尾停掉
                lizi2:stopSystem()--移动结束后将拖尾停掉
                lizi3:stopSystem()--移动结束后将拖尾停掉
            end
        end)
        actList[#actList + 1] = cc.DelayTime:create(0.5)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            tempMirror:removeFromParent()
        end) 
        local sq = cc.Sequence:create(actList)
        tempMirror:runAction(sq)
    end
end

function CodeGameScreenMagikMirrorMachine:createMojingForRotate(index,totalIndex)
    local pos = util_convertToNodeSpace(self:findChild("Node_mo".. totalIndex .."_" ..index),self.m_effect1)
    local mojingView = util_createView("CodeMagikMirrorSrc.MagikMirrorMirrorForRotateView")
    mojingView.index = index
    self.m_effect1:addChild(mojingView)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setMirrorLighting(mojingView,true)
    else
        self:setMirrorLighting(mojingView)
    end
    
    local actScaleIndex = MIRROR_SCALE[totalIndex]
    mojingView:setScale(actScaleIndex)
    mojingView:setPosition(pos)
    self.rotateMirrorList[#self.rotateMirrorList + 1] = mojingView
    return mojingView
end

function CodeGameScreenMagikMirrorMachine:setMirrorLighting(node,isFree)
    if isFree then
        if self.isSuperFree then
            node:findChild("superfree_diguang"):setVisible(true)
            node:findChild("free_diguang"):setVisible(false)
            node:findChild("base_diguang"):setVisible(false)
        else
            node:findChild("superfree_diguang"):setVisible(false)
            node:findChild("free_diguang"):setVisible(true)
            node:findChild("base_diguang"):setVisible(false)
        end
    else
        node:findChild("superfree_diguang"):setVisible(false)
        node:findChild("free_diguang"):setVisible(false)
        node:findChild("base_diguang"):setVisible(true)
    end
end

--魔镜玩法结束
function CodeGameScreenMagikMirrorMachine:showRotateOver()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusList = bonusData.bonusList or {}
    local info = bonusList[table_length(bonusList)]

    self.curJackpotCoins = 0
    local num = #self.rotateMirrorList
    local waitTime = 0
    if num > 1 then
        waitTime = 0.5
    end
    if num > 1 then
        --移动聚集后删除
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_mirror_over)
        for i=1,num do
            local node = self.rotateMirrorList[1]
            if not tolua.isnull(node) then
                table.remove(self.rotateMirrorList,1)
                --移动
                local endPos = util_convertToNodeSpace(self:findChild("Node_mo".. 1 .."_" ..1),self.m_effect1)
                local moveAct = cc.MoveTo:create(0.5, endPos)
                local scaleAct = cc.ScaleTo:create(0.5, 1)
                local hideAct = cc.CallFunc:create(function(  )
                    node:resetImageAndJackpot()
                end)
                local act_move = cc.Spawn:create(scaleAct,moveAct,hideAct)
                local removeAct = cc.CallFunc:create(function(  )
                    node:removeFromParent()
                end)
                
                node:runAction(cc.Sequence:create(act_move,removeAct))
            end
        end
        self.rotateMirrorList = {}
        self:delayCallBack(0.5,function ()
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self.mirror:resetFreeKuang()
            else
                if self.stagingNum > 0 then
                    self.mirror:resetCollectKuang(false)
                else
                    self.mirror:resetCollectKuang(true,nil,nil,self.curBonusNum)
                end
                
            end
            self.mirror:setVisible(true)
        end)
    else
        local isHaveJackpot = info[#info][2] or 0
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.mirror:resetFreeKuang(isHaveJackpot,info[1][1])
        else
            self.mirror:resetCollectKuang(false,isHaveJackpot,info[1][1],self.curBonusNum)
        end
        self.mirror:setVisible(true)
        for i=1,num do
            local node = self.rotateMirrorList[1]
            if not tolua.isnull(node) then
                table.remove(self.rotateMirrorList,1)
                node:removeFromParent()
            end
        end
        self.rotateMirrorList = {}
    end
    
end

function CodeGameScreenMagikMirrorMachine:checkIsGoldType(info,type)
    for i,v in ipairs(info) do
        local infoType = info[i][1]
        if infoType == type then
            return true
        end
    end
    return false
end

function CodeGameScreenMagikMirrorMachine:showGoldSymbolForQuick(info)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType then
                if node.p_symbolType and self:checkIsGoldType(info,node.p_symbolType) then
                    --将小块提层
                    self:changeSymbolToClipParent(node)
                    node:runAnim("idleframe")
                    --在小块上添加粒子和背光
                    self:showLiziAndLighting(node,true,true,false)
                    --变成金色
                    node:runAnim("actionframe2")
                else
                    --取消金色
                    node:runAnim("idleframe")
                    self:showLiziAndLighting(node,false,true,false)
                    self:putSymbolBackToPreParent(node)
                end
            end
        end
    end
end

function CodeGameScreenMagikMirrorMachine:isHaveMirrorSymbol(info)
    for i,v in ipairs(info) do
        if info[i][1] == 100 then
            return true
        end
    end
    return false
end

--点击某个区域
--将所有的魔镜都展示成最终显示
function CodeGameScreenMagikMirrorMachine:showMirrorForQuickStop()
    local index = self.rotateIndexForQuickStop
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusData = selfData.bonusData or {}
    local bonusList = bonusData.bonusList or {}
    local totalNum = table_length(bonusList)
    local info = bonusList[index] or {}
    if table_length(info) == 0 then
        return
    end
    self.m_effect1:stopAllActions()
    local isShowOverSound = true
    for i,v in ipairs(info) do
        --获取对应镜子
        local mirror = self.rotateMirrorList[i]
        if not tolua.isnull(mirror) then
            if mirror.isSoundOver then
                isShowOverSound = false
            end
        end
    end
    if isShowOverSound then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_mirror_overShow)
    end
    
    for i,v in ipairs(info) do
        --获取对应镜子
        local mirror = self.rotateMirrorList[i]
        if not tolua.isnull(mirror) then
            mirror:stopAllActions()
            mirror:runCsbAction("idle3",true)
            mirror:runCsbAction("actionframe6")
            mirror:showImageForQuickStop(info[i][1])
            --是否显示jackpot
            local isHaveJackpot = info[i][2] or 0
            mirror:showJackpotForIndex(isHaveJackpot,true)--魔镜上的字
            mirror:showJackpotLightForIndex(isHaveJackpot,true,false)--魔镜上的光效
            if not self.mirrorViewTb.isShow and info[i][1] == 100 then
                self:showMirrorTb(true) --棋盘上的魔镜
            end
            
        end
    end
    --若最终无需显示棋盘魔镜，则隐藏
    if not self:isHaveMirrorSymbol(info) and self.mirrorViewTb.isShow then
        self:showMirrorTb(false)  
    end
    --如果此时正在显示小弹板，则刷新
    local jackpotList = self:getJackpotList(index)
    
    if #jackpotList > 0 then
        local jackpotType = jackpotList[1][1]
        local jackpotCoins = jackpotList[1][2] or 0
        self:showSmallJackpotTb(jackpotType)
    else
        self.smallJackpotViewTb.isShow = false
        self.smallJackpotViewTb:setVisible(false)
    end
    

    self:showGoldSymbolForQuick(info)
    self:delayCallBack(40/60,function ()
        --是否有jackpot弹板
        -- local jackpotList = self:getJackpotList(index)
        if #jackpotList > 0 then
            local jackpotType = jackpotList[1][1]
            local jackpotCoins = jackpotList[1][2] or 0
            -- self:showSmallJackpotTb(jackpotType,jackpotCoins)
            self:delayCallBack(1,function ()
                self:showSmallJackpotTbAct(function ()
                    self:hideSmallJackpotTb(function ()
                        self.smallJackpotViewTb:setVisible(false)
                        self.smallJackpotViewTb.isShow = false
                    end)
                    self:showJackpotView(jackpotCoins,jackpotType,function ()
                        
                        local waitTime = 0.5
                        if index + 1 <= totalNum then
                            waitTime = 1.5
                            --缩放移动，新的魔镜生成、移动
                            self:divisionMirrorEffect(index + 1)
                        end
                        self:delayCallBack(waitTime,function ()
                            --继续下一轮
                            index = index + 1
                            local waitTime = 0
                            if index == totalNum then
                                waitTime = 3
                            end
                            self:showMirrorRotateEffect(index,function ()
                                -- self:delayCallBack(waitTime,function ()
                                    self.rotateEffect.p_isPlay = true
                                    self:playGameEffect()
                                    self.rotateEffect = nil
                                -- end)
                            end)
                        end)
                    end)
                    
                end)
            end)
            
        else
            -- self:hideSmallJackpotTb(function ()
                
            -- end)
            local waitTime = 0.5
            if index + 1 <= totalNum then
                waitTime = 1.5
                --缩放移动，新的魔镜生成、移动
                self:divisionMirrorEffect(index + 1)
            end
            self:delayCallBack(waitTime,function ()
                --继续下一轮
                index = index + 1
                local waitTime = 0
                if index == totalNum then
                    waitTime = 3
                end
                self:showMirrorRotateEffect(index,function ()
                    -- self:delayCallBack(waitTime,function ()
                        self.rotateEffect.p_isPlay = true
                        self:playGameEffect()
                        self.rotateEffect = nil
                    -- end)
                end)
            end)
        end
    end)
    
    
    
end

---------pick

function CodeGameScreenMagikMirrorMachine:setReelUiFadeIn(isShow)
    local reel_ui = {
        "Node_reel",
        "Node_freebar",
        "Node_superbar",
        "Node_jackpot",
        "Node_jackpot_TB",
        "Node_mojing_TB",
        "Node_yugao",
        "Node_lizi",
    }
    local fadeTime = 1/30
    local startTransparency = 255
    local overTransparency = 0
    if isShow then
        for i,nodeName in ipairs(reel_ui) do
            if self:findChild(nodeName) then
                self:findChild(nodeName):setVisible(true)
                util_nodeFadeIn(self:findChild(nodeName), 0.5, 0, 255, nil, function()
                end)
            end
        end
        --将苹果隐藏
        self.mirror:resetCollectKuang(true)
        self.mirror:runCsbAction("chuxian")
    else
        for i,nodeName in ipairs(reel_ui) do
            if self:findChild(nodeName) then
                util_nodeFadeIn(self:findChild(nodeName), 1/30, 255, 0, nil, function()
                    self:findChild(nodeName):setVisible(false)
                end)
            end
        end
        self.mirror:runCsbAction("over2")
    end

end

function CodeGameScreenMagikMirrorMachine:showPickEffectView(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pickData = selfData.pickData or {}
    if table_length(pickData) == 0 then
        if func then
            func()
        end
        return
    end
    
    self.mirror:runCsbAction("idle1",true)
    self:findChild("Panel_di"):setVisible(false)
    
    self:setReelUiFadeIn(false)

    self.m_pickGameView:setResultDataAry(pickData)
    self.m_pickGameView:beginBonusEffect(func,function ()
        self.m_pickGameView:setVisible(true)
        util_nodeFadeIn(self.m_pickGameView, 1/30, 0, 255, nil, function()
        end)
    end)
end

function CodeGameScreenMagikMirrorMachine:showFreePickSpinView(effectData)
    -- gLobalSoundManager:playSound("MagikMirrorSounds/music_MagikMirror_custom_enter_fs.mp3")

    local showFSView = function ( ... )

        local view = self:showFreePickSpinStart(self.m_iFreeSpinTimes,function()
            if self.isSuperFree then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_baseTosuper_guochang)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_baseToFree_guochang)
            end
            if self.isSuperFree then
                self:resetMusicBg(true,PublicConfig.SoundConfig.music_MagikMirror_superFreeBgm)
            else
                self:resetMusicBg(true,PublicConfig.SoundConfig.music_MagikMirror_freeBgm)
            end
            
            self:showGuochang(function ()
                self.mirror:findChild("m_lb_num"):setString("")
                if self.isSuperFree then
                    local avgBet = self.m_runSpinResultData.p_avgBet or nil
                    self.curFreeNum = 0
                    self.m_baseFreeNumBar:resetAllSprite()
                    self:setMirrorLighting(self.mirror,true)
                    self:showUiForIndex(COMMON_INDEX.THREE)
                    self.m_jackPotBarView:setAverageBet(avgBet)
                    --平均bet值 展示
                    self.m_bottomUI:showAverageBet()
                else
                    self:setMirrorLighting(self.mirror,true)
                    self:showUiForIndex(COMMON_INDEX.TWO)
                end
                self:showPickEffectView(function ()
                    self:findChild("Panel_di"):setVisible(true)
                    self:delayCallBack(0.5,function ()
                        self.mirror:resetFreeKuangForFreeOver()
                        self.mirror:showFreeMirror(function ()
                            self:triggerFreeSpinCallFun()
                    
                            effectData.p_isPlay = true
                            self:playGameEffect() 
                        end)
                    end)
                    
                    
                end)
                
            end,function ()

            end)  
        end)
    end

    showFSView()    
end

function CodeGameScreenMagikMirrorMachine:showFreePickSpinStart(num, func, isAuto)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pickData = selfData.pickData or {}
    local pickTimes = pickData.pickTimes
    local name = BaseDialog.DIALOG_TYPE_FREESPIN_START
    local ownerlist = {}
    ownerlist["m_lb_num"] = pickTimes
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_freeView_show)  
    local view = nil
    if isAuto then
        view = self:showDialog(name, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(name, ownerlist, func)
    end
    local fire = util_spineCreate("Socre_MagikMirror_Bonus1",true,true)
    util_spinePlay(fire,"idleframe3",true)
    view:findChild("Node_spine"):addChild(fire)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_click)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_MagikMirror_freeView_hide)
    end)
    return view

end


return CodeGameScreenMagikMirrorMachine