---
-- island li
-- 2019年1月26日
-- CodeGameScreenEgyptMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenEgyptMachine = class("CodeGameScreenEgyptMachine", BaseFastMachine)

CodeGameScreenEgyptMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenEgyptMachine.SYMBOL_CLASSIC_BONUS1 = 110 -- 自定义的小块类型
CodeGameScreenEgyptMachine.SYMBOL_CLASSIC_BONUS2 = 111
CodeGameScreenEgyptMachine.SYMBOL_CLASSIC_BONUS3 = 112
CodeGameScreenEgyptMachine.SYMBOL_CLASSIC_BONUS4 = 113
CodeGameScreenEgyptMachine.SYMBOL_CLASSIC_BONUS5 = 114
CodeGameScreenEgyptMachine.SYMBOL_FIRE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4 -- 自定义的小块类型
CodeGameScreenEgyptMachine.SYMBOL_NINE = 9

CodeGameScreenEgyptMachine.SYMBOL_RANDOM = 96

-- CodeGameScreenEgyptMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenEgyptMachine.DOUBLE_WIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenEgyptMachine.RAPID_FLAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 
CodeGameScreenEgyptMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3

CodeGameScreenEgyptMachine.m_rapidFlameNum = nil
CodeGameScreenEgyptMachine.m_vecBonusInCol1 = nil
CodeGameScreenEgyptMachine.m_vecBonusInCol2 = nil
CodeGameScreenEgyptMachine.m_vecBonusInCol3 = nil
CodeGameScreenEgyptMachine.m_vecBonusInCol4 = nil
CodeGameScreenEgyptMachine.m_vecBonusInCol5 = nil

CodeGameScreenEgyptMachine.m_triggerRespin = nil
CodeGameScreenEgyptMachine.m_fastLongRun = nil

CodeGameScreenEgyptMachine.m_vecScatter = nil
CodeGameScreenEgyptMachine.m_reelRunAnimaBG = nil
CodeGameScreenEgyptMachine.m_vecQuickScatter = nil
CodeGameScreenEgyptMachine.m_vecMarkNode = nil
CodeGameScreenEgyptMachine.m_bHaveQuickRun = nil
CodeGameScreenEgyptMachine.m_vecRapidNum = {5, 6, 7, 8, 9}

CodeGameScreenEgyptMachine.m_totalRapidNum = nil

local FIT_HEIGHT_MAX = 1280
local FIT_HEIGHT_MIN = 1110
-- 构造函数
function CodeGameScreenEgyptMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_vecBonusInCol1 = {}
    self.m_vecBonusInCol2 = {}
    self.m_vecBonusInCol3 = {}
    self.m_vecBonusInCol4 = {}
    self.m_vecBonusInCol5 = {}
    self.m_vecScatter = {}
    self.m_vecQuickScatter = {}
    self.m_vecMarkNode = {}
    self.m_reelRunAnimaBG = {}
    self.m_norDownTimes = 0
    self.m_rapidFlameNum = 0
    self.m_totalRapidNum = 0
    self.m_isFeatureOverBigWinInFree = true
	--init
	self:initGame()
end

function CodeGameScreenEgyptMachine:initGame()

    --初始化基本数据
    self.m_isMachineBGPlayLoop = true
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenEgyptMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Egypt"  
end


function CodeGameScreenEgyptMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            if display.height < FIT_HEIGHT_MIN then
                mainScale = (FIT_HEIGHT_MIN - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight =  util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight )
    end

end

function CodeGameScreenEgyptMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_EgyptView = util_createView("CodeEgyptSrc.EgyptView")
    -- self:findChild("xxxx"):addChild(self.m_EgyptView)

    self.m_jackpotNode = util_createView("CodeEgyptSrc.EgyptJackPotBarView")
    self.m_jackpotNode:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_jackpotNode)
    -- self.m_jackpotNode:findChild("9"):setVisible(false)
    -- self.m_jackpotNode:findChild("8"):setVisible(false)
    -- self.m_jackpotNode:findChild("7"):setVisible(false)
    -- self.m_jackpotNode:findChild("6"):setVisible(false)
    -- self.m_jackpotNode:findChild("5"):setVisible(false)
    -- self.m_jackpotNode:setVisible(false)

    local rapidNode = self:findChild("rapid")
    local pos = rapidNode:getParent():convertToWorldSpace(cc.p(rapidNode:getPosition()))
    pos = self:convertToNodeSpace(pos)

    self.m_jackpotView = util_createView("CodeEgyptSrc.EgyptRapidFlameView")
    self:addChild(self.m_jackpotView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.m_jackpotView:setScale(self.m_machineRootScale)
    self.m_jackpotView:setPosition(pos)
    -- self:findChild("rapid"):addChild(self.m_jackpotView)

    self.m_multipView = util_createView("CodeEgyptSrc.EgyptMultiplyView")
    self:addChild(self.m_multipView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.m_multipView:setScale(self.m_machineRootScale)
    self.m_multipView:setPosition(pos)

    self.m_guochangNode = util_spineCreate("WinEgypt_guochang", true, true)
    self:addChild(self.m_guochangNode, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.m_guochangNode:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guochangNode:setScale(self.m_machineRootScale)
    self.m_guochangNode:setVisible(false)

    self.m_freespinBar = util_createView("CodeEgyptSrc.EgyptFreespinBar")
    self:findChild("freespin_bar"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)

    self.m_collectBar = util_createView("CodeEgyptSrc.EgyptCollectBar")
    self:findChild("freespinjishu"):addChild(self.m_collectBar)
    self.m_collectBar:setVisible(false)

    self.m_showTip = util_createView("CodeEgyptSrc.EgyptViewTip")
    self:findChild("freespinjishu"):addChild(self.m_showTip)
    self.m_showTip:setPositionY(-20)

    local data = {}
    data.index = 1
    data.parent = self
    data.vecCollect = self.m_collectBar:getLabArray()
    self.m_FastReels = util_createView("CodeEgyptSrc.EgyptMiniMachine", data)
    self:findChild("Node_Reel"):addChild(self.m_FastReels)

    -- self.m_Particle1 = self.m_gameBg:findChild("Particle_1")
    -- self.m_Particle2 = self.m_gameBg:findChild("Particle_1_0")
    -- self.m_Particle1:setVisible(false)
    -- self.m_Particle2:setVisible(false)
    
    self:findChild("freespin"):setVisible(false)
    self:findChild("normal"):setVisible(true)

    self.m_gameBg:findChild("root"):setScale(self.m_machineRootScale)

    -- for i = 1, self.m_iReelColumnNum, 1 do
    --     local mark = self:findChild("Egypt_reel_mark_"..i)
    --     mark:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
    --     mark:setVisible(false)
    --     -- self.m_vecMarkNode[#self.m_vecMarkNode + 1] = mark
    -- end

    -- self:findChild("Node_reel"):setVisible(false)
    -- self:findChild("reels"):setVisible(false)
    -- self:findChild("normal"):setVisible(false)
    -- self:findChild("freespin"):setVisible(false)
    -- self:findChild("Egypt_di"):setVisible(false)
    -- self:findChild("Egypt_di_0"):setVisible(false)
    -- self:findChild("shu_3"):setVisible(false)
    -- self:findChild("shu_2"):setVisible(false)
    -- self:findChild("shu_1"):setVisible(false)
    -- self:findChild("shu"):setVisible(false)
    -- self.m_gameBg:setVisible(false)
    -- -- 创建大转盘
    -- -- 轮盘网络数据
    -- local data = self.m_runSpinResultData.p_selfMakeData
    -- local bonusWheel = util_createView("DwarfFairySrc.DwarfFairyWheelView", data)
    -- local callback = function ()

    --         bonusWheel:removeFromParent(true)
    -- end
    -- bonusWheel:setPosition(display.width * 0.5, display.height * 0.5)
    -- bonusWheel:initCallBack(callback)
    -- self:addChild(bonusWheel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
   
    local jackpotNode = self:findChild("jackpot")
    local wheelNode = self:findChild("wheelNode")

    local distance = (display.height - DESIGN_SIZE.height * self.m_machineRootScale) * 0.5
    jackpotNode:setPositionY(jackpotNode:getPositionY() + distance)

    if display.height > DESIGN_SIZE.height then
        wheelNode:setPositionY(wheelNode:getPositionY() + distance + 20)
        wheelNode:setScale(0.83)
    elseif display.height > FIT_HEIGHT_MAX then
        wheelNode:setPositionY(wheelNode:getPositionY() + 10)
        wheelNode:setScale(0.83)
    elseif display.height <= FIT_HEIGHT_MAX then
        wheelNode:setPositionY(wheelNode:getPositionY() + 40)
        wheelNode:setScale(0.84)
    elseif display.height <= 1080 then
        wheelNode:setPositionY(wheelNode:getPositionY() + 40)
        wheelNode:setScale(0.82)
    end

    
 
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        if self.m_rapidFlameNum ~= nil and self.m_rapidFlameNum >= 5 then
            return
        end
        if self.m_classicMachine ~= nil then
            return
        end
        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
            soundTime = 2
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 3
        elseif winRate > 3  then
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "EgyptSounds/sound_Egypt_last_win_".. soundIndex .. ".mp3"
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenEgyptMachine:showAnimation(func, overCall)
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_guochang.mp3")
    self.m_guochangNode:setVisible(true)
    util_spinePlay(self.m_guochangNode, "actionframe")
    util_spineEndCallFunc(self.m_guochangNode, "actionframe", function()
        if overCall then
            overCall()
        end
        self.m_guochangNode:setVisible(false)
    end)
    performWithDelay(self, function ()
	    if func ~= nil then
            func()
        end
    end, 1)
end

function CodeGameScreenEgyptMachine:setScatterDownScound( )
    for i = 1, 3 do
        local soundPath = "EgyptSounds/sound_Egypt_scatter_down"..i..".mp3"
        self.m_scatterBulingSoundArry[i] = soundPath
    end
end

function CodeGameScreenEgyptMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    
    local betCoin = globalData.slotRunData:getCurTotalBet()
    
    if self.m_specialBets and #self.m_specialBets > 0 then
        self.m_iBetLevel = #self.m_specialBets + 1
        for i = 1, #self.m_specialBets do
            if betCoin < self.m_specialBets[i].p_totalBetValue then
                self.m_iBetLevel = i
                break
            end
        end
    else
        self.m_iBetLevel = 1
    end
    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 5
    end
end

function CodeGameScreenEgyptMachine:unlockHigherBet(level)
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
    if betCoin >= self.m_specialBets[level].p_totalBetValue then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_specialBets[level].p_totalBetValue then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenEgyptMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        
        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            if not self.isInBonus then
                self:resetMusicBg()
                gLobalSoundManager:setBackgroundMusicVolume(0)
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenEgyptMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:updateBetLevel()
    self.m_jackpotNode:updateUI(self.m_iBetLevel)
    self.m_jackpotNode:initUnlockCoin(self.m_specialBets)
    self:addObservers()
end

function CodeGameScreenEgyptMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel ~= self.m_iBetLevel then
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_unLockJackpot"..self.m_iBetLevel..".mp3")
            self.m_jackpotNode:updateUI(self.m_iBetLevel)
        end
        
        -- if perBetLevel > self.m_iBetLevel then
        --     self.m_collectIcon:lock(self.m_iBetLevel)
        -- elseif perBetLevel < self.m_iBetLevel then
        --     gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_unlock.mp3")
        --     self.m_collectIcon:unlock(self.m_iBetLevel)
        -- end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet(params)
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end

function CodeGameScreenEgyptMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除

    for i, v in pairs(self.m_reelRunAnimaBG) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnimaBG[i] = v
    end

    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenEgyptMachine:MachineRule_GetSelfCCBName(symbolType)

    local ccbName = nil
    if symbolType == self.SYMBOL_CLASSIC_BONUS1 then
        ccbName = "Socre_Egypt_bonus1"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS2 then
        ccbName = "Socre_Egypt_bonus2"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS3 then
        ccbName = "Socre_Egypt_bonus3"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS4 then
        ccbName = "Socre_Egypt_bonus4"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS5 then
        ccbName = "Socre_Egypt_bonus5"
    elseif symbolType == self.SYMBOL_FIRE then
        ccbName = "Socre_Egypt_rapid1"
    elseif symbolType == self.SYMBOL_NINE then
        ccbName = "Socre_Egypt_10"
    elseif symbolType == self.SYMBOL_RANDOM then
        ccbName = "Socre_Egypt_"..math.random(1, 10)
    end
    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenEgyptMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_BONUS4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_BONUS5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIRE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_NINE,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 

function CodeGameScreenEgyptMachine:MachineRule_initGame(spinData)
    
    self.m_isOutLines = true
    if self:getInFreespin() == true then
        self.m_collectBar:setVisible(true)
        self.m_showTip:setVisible(false)
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_collectBar:updateUI(self.m_runSpinResultData.p_selfMakeData.classCounts)
        elseif self.m_runSpinResultData.p_selfMakeData.classTotalCounts ~= nil then
            local rsLeftCount = 0
            for i = 1, self.m_iReelColumnNum, 1 do
                local total = self.m_runSpinResultData.p_selfMakeData.classTotalCounts[i]
                local count = self.m_runSpinResultData.p_selfMakeData.classCounts[i]
                rsLeftCount = rsLeftCount + count
                if total > 0 then
                    if count > 0 then
                        self.m_collectBar:updateUI(self.m_runSpinResultData.p_selfMakeData.classTotalCounts)
                        break
                    else
                        self.m_collectBar:initFsRespinUI(i, total, count)
                    end
                end
            end
            if rsLeftCount > 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                local reSpinEffect = GameEffectData.new()
                reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
                reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
                self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
                self.m_FastReels:initReelsNodesByNetData(self.m_runSpinResultData.p_selfMakeData.fast.reels)
            else
                self.m_collectBar:setVisible(false)
                self.m_showTip:setVisible(true)
                self.m_collectBar:resetLabNum()
            end
        else
            self.m_collectBar:setVisible(false)
            self.m_showTip:setVisible(true)
        end
    end
    if self.m_runSpinResultData.p_selfMakeData.classic ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then 
        local respinCount = 0
        local fastType = self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1]
        for i = 1, self.m_iReelColumnNum, 1 do
            respinCount = respinCount + self.m_runSpinResultData.p_selfMakeData.classCounts[i]
        end
        if respinCount > 0 or fastType == self.SYMBOL_CLASSIC_BONUS1 or fastType == self.SYMBOL_CLASSIC_BONUS2
        or fastType == self.SYMBOL_CLASSIC_BONUS3 or fastType == self.SYMBOL_CLASSIC_BONUS4
        or fastType == self.SYMBOL_CLASSIC_BONUS5  then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
            self.m_FastReels:initReelsNodesByNetData(self.m_runSpinResultData.p_selfMakeData.fast.reels)
        end
    end
end

function CodeGameScreenEgyptMachine:initFeatureInfo(spinData,featureData)
    
end

--
--单列滚动停止回调
--
function CodeGameScreenEgyptMachine:slotOneReelDown(reelCol)

    --快滚重写
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
        self:showMarkLayer(reelCol)
    end

    if self.m_reelDownSoundPlayed  then

        self:playReelDownSound(reelCol,self.m_reelDownSound )

    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end

    
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
    
    if self.m_runSpinResultData.p_features[2] ~= nil and self.m_runSpinResultData.p_features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
        self.m_triggerRespin = true
    end
    
    local vec5ReelFire = {}
    local vec5ReelBonus = {}
    local haveBonus = false
    local haveRapid = false
    for i = 1, self.m_iReelRowNum, 1 do
        local symbol = self:getFixSymbol(reelCol, i, SYMBOL_NODE_TAG)
        if symbol.p_symbolType == (self.SYMBOL_CLASSIC_BONUS1 + reelCol - 1) then
            if reelCol == 5 then 
                vec5ReelBonus[#vec5ReelBonus + 1] = symbol
            else
                haveBonus = true
                self.m_haveOneBonus = true
                symbol:runAnim("buling")
                self:updateBonusSymbol(symbol, reelCol)
                local spine = symbol:getCcbProperty("Classic")
                util_spinePlay(spine, "buling")
            end
        elseif symbol.p_symbolType == self.SYMBOL_FIRE then
            if reelCol == 5 then 
                vec5ReelFire[#vec5ReelFire + 1] = symbol
            else
                self.m_haveOneFire = true
                haveRapid = true
                symbol:runAnim("buling")
            end
        elseif symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.m_vecScatter[#self.m_vecScatter + 1] = symbol
        end
    end

    if reelCol == 5 and (#vec5ReelBonus >= 2 or (self.m_haveOneBonus == true and #vec5ReelBonus > 0)) then
        haveBonus = true
        self.m_haveOneBonus = false
        for i = 1, #vec5ReelBonus, 1 do
            vec5ReelBonus[i]:runAnim("buling")
            self:updateBonusSymbol(vec5ReelBonus[i], reelCol)
            local spine = vec5ReelBonus[i]:getCcbProperty("Classic")
            util_spinePlay(spine, "buling")
        end
    end

    if reelCol == 5 and (#vec5ReelFire >= 2 or (self.m_haveOneFire == true and #vec5ReelFire > 0)) then
        self.m_haveOneFire = false
        haveRapid = true
        for i = 1, #vec5ReelFire, 1 do
            vec5ReelFire[i]:runAnim("buling")
        end
    end

    if haveBonus == true then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,"EgyptSounds/sound_Egypt_bonus_down.mp3" )
        else
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_bonus_down.mp3")
        end
        
    end

    if haveRapid == true then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,"EgyptSounds/sound_Egypt_jackpot_down.mp3" )
        else
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_jackpot_down.mp3")
        end
    end

    --fast特效 第五列落地后播放
    if reelCol == 4 then
        -- if self.m_vecScatter ~= nil and #self.m_vecScatter == 1 then
        --     self.m_vecScatter[1]:runIdleAnim()
        --     self.m_vecScatter = {}
        -- end
    elseif reelCol == 5 then
        if self.m_bHaveQuickRun == true then
            self.m_FastReels:changeReelRunSpeed()
        end
        -- if self.m_vecScatter ~= nil and #self.m_vecScatter == 2 then
        --     self.m_vecScatter[1]:runIdleAnim()
        --     self.m_vecScatter[2]:runIdleAnim()
        -- end
        if #self.m_vecScatter >= 3 then
            self:showMarkLayer(5)
        else
            self:hideMarkLayer()
        end
        self.m_vecScatter = {}
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local fast = selfdata.fast or {}
        local lines = fast.lines
        local isWin = false
        if lines and #lines > 0 and self.m_runSpinResultData.p_selfMakeData.fastCashWinCoins == nil and self.m_totalRapidNum >= 5 then
            isWin = true
        end
        self:checkIsRunFastWinAct(isWin)
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self.m_bHaveQuickRun = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function CodeGameScreenEgyptMachine:showMarkLayer(col)
    -- for i = 1, col, 1 do
    --     -- self.m_vecMarkNode[i]:setVisible(true)
    -- end
end

function CodeGameScreenEgyptMachine:hideMarkLayer()
    -- for i = 1, #self.m_vecMarkNode, 1 do
    --     self.m_vecMarkNode[i]:setVisible(false)
    -- end
end

function CodeGameScreenEgyptMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)
    self.m_vecMoveFixWildList = {} --移动完成 和 重新掉落的wild 集合
    if self.m_FastReels:isVisible() then
        self.m_FastReels:beginMiniReel()
    end

    if self.m_bonusGameReel ~= nil then
        self.m_bonusGameReel:beginReel()
    end
end

function CodeGameScreenEgyptMachine:slotReelDown()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fast = selfdata.fast or {}
    local lines = fast.lines
    local isWin = false
    if lines and #lines > 0 and self.m_runSpinResultData.p_selfMakeData.fastCashWinCoins == nil and self.m_totalRapidNum >= 5 then
        isWin = true
    end
    -- if not isWin then
    --     BaseFastMachine.slotReelDown(self)
    --     -- self:checkTriggerOrInSpecialGame(
    --     --     function()
    --     --         self:reelsDownDelaySetMusicBGVolume()
    --     --     end
    --     -- )
    -- else
        self:setDownTimes(1)
    -- end
end

function CodeGameScreenEgyptMachine:checkIsRunFastWinAct(isWin)
    if isWin then --or self.m_fastLongRun == true then
        -- local rodTime = math.random(1, 100)
        -- if self:checkIsTright(rodTime, 100) then
            self.m_jackPotRunSoundsId =gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_6_reel_quick.mp3",false)
            performWithDelay(self,function()
                self.m_jackPotRunSoundsId = nil
            end,4.5)
        
            -- gLobalSoundManager:setBackgroundMusicVolume(0)
            self.m_FastReels:playWinEffect()
        -- end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenEgyptMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    self:findChild("freespin"):setVisible(true)
    self:findChild("reels"):setVisible(true)          
    self:findChild("normal"):setVisible(false)
    self.m_freespinBar:setVisible(true)
    self.m_freespinBar:changeFreeSpinByCount()
    self.m_collectBar:setVisible(true)
    self.m_showTip:setVisible(false)
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenEgyptMachine:levelFreeSpinOverChangeEffect()
    self:findChild("freespin"):setVisible(false)
    self:findChild("normal"):setVisible(true)
    self:findChild("reels"):setVisible(true)
    self.m_freespinBar:setVisible(false)
    self.m_collectBar:setVisible(false)
    self.m_showTip:setVisible(true)
    self.m_collectBar:resetLabNum()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenEgyptMachine:checkTriggerInReSpin()
    
end


function CodeGameScreenEgyptMachine:showJackpotView(index,coins,func)
    local jackPotWinView = util_createView("CodeEgyptSrc.EgyptJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,function()
        gLobalSoundManager:stopAudio(soundID)
        soundID = nil
        if func ~= nil then 
            func()
        end
    end)
end

---- 轮盘结果
function CodeGameScreenEgyptMachine:wheelRotateOver(wheelResult, wheel, effectData)
    local showFSView = function ( ... )
        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_fs_start.mp3")
        self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            performWithDelay(self, function()
                self:showAnimation(function()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"freespin", true})
                    self:findChild("freespin"):setVisible(true)
                    self:findChild("normal"):setVisible(false)
                    self:findChild("reels"):setVisible(true)
                    self.m_freespinBar:setVisible(true)
                    self.m_freespinBar:changeFreeSpinByCount()
                    self.m_collectBar:setVisible(true)
                    self.m_showTip:setVisible(false)
                    wheel:removeFromParent()
                    -- self.m_Particle1:setVisible(false)
                    -- self.m_Particle2:setVisible(false)
                end, function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()   
                end)
            end, 0.5)
        end)
        
    end
    
    if wheelResult < 100 then
        showFSView()
    else
        wheelResult = wheelResult / 100
        if wheelResult > self.m_vecRapidNum[self.m_iBetLevel] then
            wheelResult = self.m_vecRapidNum[self.m_iBetLevel]
        end
        local coins = self.m_runSpinResultData.p_selfMakeData.wheelWinCoins
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount--globalData.slotRunData.lastWinCoin + self.m_runSpinResultData.p_selfMakeData.wheelWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_selfMakeData.wheelWinCoins, true})
        self:showJackpotView(wheelResult, coins, function()
            performWithDelay(self, function()
                self:showAnimation(function()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"normal", true})
                    wheel:removeFromParent()
                    -- self.m_Particle1:setVisible(false)
                    -- self.m_Particle2:setVisible(false)
                    self:findChild("normal"):setVisible(true)
                    self:findChild("reels"):setVisible(true)
                    self.m_jackpotNode:showIdle()
                end, function()
                    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_RESPIN)
                    self:resetMusicBg()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end)
            end, 0.5)
        end)
    end
end

----------- FreeSpin相关

function CodeGameScreenEgyptMachine:showEffect_FreeSpin(effectData)
    self.m_FastReels:stopLineAction()
    self.m_jackpotNode:showIdle()
    self:resetScatterNodes()
    return BaseMachineGameEffect.showEffect_FreeSpin(self, effectData)
end

function CodeGameScreenEgyptMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        performWithDelay(self, function()
            self:hideMarkLayer()
            self:resetMaskLayerNodes()
        end, 2)
        callFun()
    end,util_max(2,animTime),self:getModuleName())
end

function CodeGameScreenEgyptMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runAnim("actionframe")
    end
    return slotNode
end

-- FreeSpinstart
function CodeGameScreenEgyptMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("EgyptSounds/music_Egypt_custom_enter_fs.mp3")
    local showFreeSpinView = function()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_fs_start.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local wheel = nil
            self:showAnimation(function()
                -- self.m_machineNode:setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"wheel")
                -- self.m_Particle1:setVisible(true)
                -- self.m_Particle2:setVisible(true)
                local data = {}
                data.wheel = self.m_runSpinResultData.p_selfMakeData.wheels
                data.select = self.m_runSpinResultData.p_selfMakeData.wheelIndex + 1
                wheel = util_createView("CodeEgyptSrc.EgyptWheelView", data)
                local wheelResult = self.m_runSpinResultData.p_selfMakeData.wheels[self.m_runSpinResultData.p_selfMakeData.wheelIndex + 1]
                if wheelResult > 100 then
                    wheel:initShowJackpot(function()
                        self.m_jackpotNode:showJackpot(wheelResult / 100)
                    end)
                end
                wheel:initCallBack(function()
                    self:wheelRotateOver(wheelResult, wheel, effectData)
                end)
                self:findChild("wheelNode"):addChild(wheel)

                if globalData.slotRunData.machineData.p_portraitFlag then
                    wheel.getRotateBackScaleFlag = function(  ) return false end
                end
 

                self:findChild("normal"):setVisible(false)
                self:findChild("freespin"):setVisible(false)
                self:findChild("reels"):setVisible(false)
                -- performWithDelay(self, function()
                --     wheel:showStart()
                -- end, 1)
                
            end, function()
                gLobalSoundManager:playBgMusic("EgyptSounds/music_Egypt_bgm_rs.mp3")
                if wheel ~= nil then
                    wheel:showStart()
                end
            end)
        end
    end


    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFreeSpinView()    
    end,0.5)

end

function CodeGameScreenEgyptMachine:showFreeSpinOverView()

    performWithDelay(self, function() 
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_fs_over.mp3")
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                performWithDelay(self, function()
                    self:showAnimation(function()
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"normal", true})
                        self:levelFreeSpinOverChangeEffect()
                    end, function()
                        self:triggerFreeSpinOverCallFun()
                    end)
                end, 0.5)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)
    end, 1)
end

function CodeGameScreenEgyptMachine:playEffectNotifyNextSpinCall( )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        if (self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0) or self.m_runSpinResultData.p_selfMakeData.fastCashWinCoins ~= nil
         or self.m_runSpinResultData.p_selfMakeData.fireWinCoins ~= nil then
            delayTime = delayTime + self:getWinCoinTime()
        end

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenEgyptMachine:MachineRule_SpinBtnCall()
    self:removeSoundHandler()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if self.m_soundMultipId ~= nil then
        gLobalSoundManager:stopAudio(self.m_soundMultipId)
        self.m_soundMultipId = nil
    end
    for iCol = 1, self.m_iReelColumnNum, 1 do
        self["m_vecBonusInCol"..iCol] = {}
    end
    -- self.m_fastLongRun = false
    self.m_triggerRespin = false
    self.m_isOutLines = false
    self.m_isQuickSpin = false
    self.m_bHaveQuickRun = false
    self.m_bIsBigWin = false
    self.m_norDownTimes = 0
    self.m_norSlotsDownTimes = 0
    self.m_vecQuickScatter = {}
    self.m_jackpotNode:showIdle()
    self.m_FastReels:stopLineAction()
    self.m_FastReels:showIdle()
    return false -- 用作延时点击spin调用
end


---
-- 处理spin 返回结果
function CodeGameScreenEgyptMachine:spinResultCallFun(param)
    if self.m_classicMachine ~= nil then
        return
    end
    self.m_iFixSymbolNum = 0
    self.m_bFlagRespinNumChange = false
    self.m_vecExpressSound = {false, false, false, false, false}
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = 2
    
    self:checkTestConfigType(param)
    
    local isOpera = self:checkOpearReSpinAndSpecialReels(param)  -- 处理respin逻辑
    if isOpera == true then
        return 
    end

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end
end

----
--- 处理spin 成功消息
--
function CodeGameScreenEgyptMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end


    if spinData.action == "SPIN"  or (self:getIsBigLevel() == true and spinData.action == "FEATURE")  then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")

        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.fast then
                    if self.m_FastReels then
                        spinData.result.selfData.fast.bet = 0
                        spinData.result.selfData.fast.payLineCount = 0
                        self:changeFastReelsRunData()
                        self.m_FastReels:netWorkCallFun(spinData.result.selfData.fast)
                    end
                end
            end
        end

    end

    self.m_totalRapidNum = 0
    for i = 1, self.m_iReelRowNum, 1 do
        local vecRow = self.m_stcValidSymbolMatrix[i]
        for j = 1, self.m_iReelColumnNum, 1 do
            if vecRow[j] == self.SYMBOL_FIRE then
                self.m_totalRapidNum = self.m_totalRapidNum + 1
            end
        end
    end

    if self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1] == self.SYMBOL_FIRE then
        self.m_totalRapidNum = self.m_totalRapidNum + 1
    end

end

function CodeGameScreenEgyptMachine:changeFastReelsRunData()
    -- if self:getBetLevel() == 0 then
    --     return
    -- end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fast = selfdata.fast or {}
    local lines = fast.lines
    local isWin = false
    if lines and #lines > 0 and self.m_runSpinResultData.p_selfMakeData.fastCashWinCoins == nil and self.m_totalRapidNum >= 5 then
        isWin = true
    end
    -- local rodTime = math.random(1, 100)
    -- if rodTime <= 5 then
    --     self.m_fastLongRun = true
    -- end
    if isWin then --or self.m_fastLongRun == true then
        self.m_FastReels:setLongRunFlag(true)
        local rundata = {self.m_reelRunInfo[#self.m_reelRunInfo]:getReelRunLen() + 30}
        self.m_FastReels:slotsReelRunData(
            rundata,
            self.m_FastReels.m_configData.p_bInclScatter,
            self.m_FastReels.m_configData.p_bInclBonus,
            self.m_FastReels.m_configData.p_bPlayScatterAction,
            self.m_FastReels.m_configData.p_bPlayBonusAction
        )
    else
        local rundata = {self.m_reelRunInfo[#self.m_reelRunInfo]:getReelRunLen()}
        self.m_FastReels:slotsReelRunData(
            rundata,
            self.m_FastReels.m_configData.p_bInclScatter,
            self.m_FastReels.m_configData.p_bInclBonus,
            self.m_FastReels.m_configData.p_bPlayScatterAction,
            self.m_FastReels.m_configData.p_bPlayBonusAction
        )
    end
end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenEgyptMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenEgyptMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenEgyptMachine:addSelfEffect()

    self.m_rapidFlameNum = 0
    self.m_vecRapidNode = {}
    for i = 1, self.m_iReelRowNum, 1 do
        local vecRow = self.m_stcValidSymbolMatrix[i]
        for j = 1, self.m_iReelColumnNum, 1 do
            if vecRow[j] == self.SYMBOL_FIRE then
                self.m_rapidFlameNum = self.m_rapidFlameNum + 1
                self.m_vecRapidNode[#self.m_vecRapidNode + 1] = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            end
        end
    end

    if self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1] == self.SYMBOL_FIRE then
        self.m_rapidFlameNum = self.m_rapidFlameNum + 1
    end
    if self.m_rapidFlameNum >= 3 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.RAPID_FLAME_EFFECT -- 动画类型
    end
    if self.m_rapidFlameNum > self.m_vecRapidNum[self.m_iBetLevel] then
        self.m_rapidFlameNum = self.m_vecRapidNum[self.m_iBetLevel]
    end
    
    -- if self.m_runSpinResultData.p_selfMakeData.multipleWin ~= nil and self.m_runSpinResultData.p_selfMakeData.totalBetMultiple ~= nil and self.m_runSpinResultData.p_winAmount > 0 
    -- and self.m_runSpinResultData.p_winAmount ~= self.m_runSpinResultData.p_selfMakeData.fireWinCoins then
    if self.m_runSpinResultData.p_selfMakeData.multipleWin ~= nil then
       local selfEffect = GameEffectData.new()
       selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
       selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
       self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
       selfEffect.p_selfEffectType = self.DOUBLE_WIN_EFFECT -- 动画类型
   end

    if self:getInFreespin() == true then
        local hasCollectBonus = false
        for iRow = 1, self.m_iReelRowNum, 1 do
            for iCol = 1, self.m_iReelColumnNum, 1 do
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_CLASSIC_BONUS1 + iCol - 1 then
                    self["m_vecBonusInCol"..iCol][#self["m_vecBonusInCol"..iCol] + 1] = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    hasCollectBonus = true
                end
            end
        end
        local fastType = self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1]
        if fastType == self.SYMBOL_CLASSIC_BONUS1 or fastType == self.SYMBOL_CLASSIC_BONUS2
         or fastType == self.SYMBOL_CLASSIC_BONUS3 or fastType == self.SYMBOL_CLASSIC_BONUS4 or fastType == self.SYMBOL_CLASSIC_BONUS5 then 
                hasCollectBonus = true
        end
        if hasCollectBonus then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
        end
    end
    
end

function CodeGameScreenEgyptMachine:checkSelfEffectType(type)
    for i = 1, #self.m_gameEffects, 1 do
        local effect = self.m_gameEffects[i]
        if effect.p_selfEffectType == type then
            return true
        end
    end
    return false
end

function CodeGameScreenEgyptMachine:runRapidFireAnimation()
    if self:checkSelfEffectType(self.RAPID_FLAME_EFFECT) == false then
        return false
    end
    for i = 1, #self.m_vecRapidNode, 1 do
        local repidFire = self.m_vecRapidNode[i]
        self:changeScatterNode(repidFire)
        repidFire:runAnim("actionframe", true)
    end
    self.m_FastReels:rapidAnimation()
    if (self.m_runSpinResultData.p_winAmount == self.m_runSpinResultData.p_selfMakeData.fireWinCoins)
     or (self.m_runSpinResultData.p_selfMakeData.fastCashWinCoins ~= nil and self.m_runSpinResultData.p_winAmount == self.m_runSpinResultData.p_selfMakeData.fireWinCoins + self.m_runSpinResultData.p_selfMakeData.fastCashWinCoins) then 
        local isNotifyUpdateTop = true
        local onceWinCoin = globalData.slotRunData.lastWinCoin
        if self:getInFreespin() == true then
            isNotifyUpdateTop = false
            onceWinCoin = self.m_runSpinResultData.p_winAmount
        end
        self:removeBigMegaBeforeAdd()
        self:checkFeatureOverTriggerBigWin(onceWinCoin, GameEffect.EFFECT_RESPIN)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount, isNotifyUpdateTop})
    end
    
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenEgyptMachine:MachineRule_playSelfEffect(effectData)
    
    -- if self.m_runSpinResultData.p_selfMakeData.wheelWinCoins ~= nil then
    --     self:removeBigMegaBeforeAdd()
    --     globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - self.m_runSpinResultData.p_selfMakeData.wheelWinCoins
    --     self.m_iOnceSpinLastWin = globalData.slotRunData.lastWinCoin
    -- end

    if effectData.p_selfEffectType == self.RAPID_FLAME_EFFECT then
        self:runRapidFireAnimation()
        
        if self.m_rapidFlameNum >= 5 then
            gLobalSoundManager:setBackgroundMusicVolume(0)
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_triger_jackpot.mp3")
            self.m_jackpotNode:showJackpot(self.m_rapidFlameNum, true)
            performWithDelay(self, function()
                globalData.jackpotRunData:notifySelfJackpot(self.m_runSpinResultData.p_selfMakeData.fireWinCoins, 10 - self.m_rapidFlameNum)
                gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_rapid_window.mp3")
                self.m_jackpotView:showStart(self.m_rapidFlameNum, self.m_runSpinResultData.p_selfMakeData.fireWinCoins, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end, 3)
        else
            local delayTime = 0 
            if self:checkSelfEffectType(self.DOUBLE_WIN_EFFECT) then
                delayTime = 3
            end
            performWithDelay(self, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, delayTime)
        end
    elseif effectData.p_selfEffectType == self.DOUBLE_WIN_EFFECT then
        self:resetScatterNodes()
        self:removeGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        self:showLineFrame()
        local winCoin = self.m_runSpinResultData.p_winAmount
        if self.m_runSpinResultData.p_selfMakeData.fireWinCoins ~= nil then
            winCoin = winCoin - self.m_runSpinResultData.p_selfMakeData.fireWinCoins
        end
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local winEffect = false
        if winRatio >= self.m_BigWinLimitRate then
            winEffect = true
        end
        
        self.m_FastReels:multipAnimation(function()
            if winEffect == true then
                gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_multip_window.mp3")
                self.m_multipView:showStart(self.m_runSpinResultData.p_selfMakeData.totalBetMultiple, winCoin, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    self:runRapidFireAnimation()
                end)
            end
        end)
        if winEffect == false then
            effectData.p_isPlay = true
            self:playGameEffect()
            self:runRapidFireAnimation()
        else
            self.m_soundMultipId = gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_multip_reward.mp3")
            gLobalSoundManager:setBackgroundMusicVolume(0)
        end
        
    elseif effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        self:collectBonus(effectData)
    end

    
	return true
end

function CodeGameScreenEgyptMachine:collectBonus(effectData)
    local vecCollect = self.m_collectBar:getLabArray()
    -- addEffect(col, num)
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_collect_bonus.mp3")
    
    for iCol = 1, self.m_iReelColumnNum, 1 do
        if #self["m_vecBonusInCol"..iCol] > 0 then
            local endPos = vecCollect[iCol]:getParent():convertToWorldSpace(cc.p(vecCollect[iCol]:getPosition()))
            local newEndPos = self.m_slotEffectLayer:convertToNodeSpace(endPos)
            for i = 1, #self["m_vecBonusInCol"..iCol], 1 do 
                local symbol = self["m_vecBonusInCol"..iCol][i]
                local startPos = symbol:getParent():convertToWorldSpace(cc.p(symbol:getPosition()))
                local newStartPos = self.m_slotEffectLayer:convertToNodeSpace(startPos)
                local particle = cc.ParticleSystemQuad:create("partical/bonus_tuowei.plist")
                particle:setAutoRemoveOnFinish(true)
                self.m_slotEffectLayer:addChild(particle,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                particle:setPosition(newStartPos)
                local moveTo = cc.MoveTo:create(0.4, newEndPos)
                local callback = cc.CallFunc:create(function()
                    particle:stopSystem()
                    if i == #self["m_vecBonusInCol"..iCol] then
                        self.m_collectBar:addEffect(iCol, self.m_runSpinResultData.p_selfMakeData.classCounts[iCol])
                    end
                end)
                particle:runAction(cc.Sequence:create(moveTo, callback))
            end
        end
    end
    local fastType = self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1]
    if fastType == self.SYMBOL_CLASSIC_BONUS1 or fastType == self.SYMBOL_CLASSIC_BONUS2
         or fastType == self.SYMBOL_CLASSIC_BONUS3 or fastType == self.SYMBOL_CLASSIC_BONUS4
         or fastType == self.SYMBOL_CLASSIC_BONUS5 then 
        local iCol = fastType - self.SYMBOL_CLASSIC_BONUS1 + 1
        self.m_FastReels:collectBonus(iCol, #self["m_vecBonusInCol"..iCol] <= 0)
    end
    
    performWithDelay(self, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end, 1.4)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenEgyptMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenEgyptMachine:requestSpinResult()

    if self.m_classicMachine ~= nil then
        return
    end
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenEgyptMachine:changeRespinNum(col)
    if self:getInFreespin() == true then
        self.m_collectBar:changeRespinNum(col)
    end
end

function CodeGameScreenEgyptMachine:showEffect_Respin(effectData)

    -- 停掉背景音乐
    self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:resetScatterNodes()
        self.m_FastReels:stopLineAction()
        self.m_jackpotNode:showIdle()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(),childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:removeFromParent()
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
            -- end
        end
    end
    
    if  self:getLastWinCoin() > 0 then  -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝

        scheduler.performWithDelayGlobal(function()
            removeMaskAndLine()
            self:showRespinView(effectData)
        end, 1.5, self:getModuleName())

    else
        performWithDelay(self, function() 
            
            self:showRespinView(effectData)
        end, 1)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin,self.m_iOnceSpinLastWin)
    return true

end

function CodeGameScreenEgyptMachine:showRespinView(effectData)
    if self.m_classicMachine ~= nil then
        self.m_classicMachine:removeFromParent()
        self.m_classicMachine = nil
    end
    if self:getInFreespin() == true then
        local isRespinOver = true
        for i = 1, #self.m_runSpinResultData.p_selfMakeData.classCounts, 1 do
            local count = self.m_runSpinResultData.p_selfMakeData.classCounts[i]
            if count > 0 then
                self.m_collectBar:changeRespinUI(i, self.m_runSpinResultData.p_selfMakeData.classTotalCounts[i], count, function()
                    self:showClassicSlot(i, effectData, count)
                    self.m_runSpinResultData.p_selfMakeData.classCounts[i] = 0
                end)
                isRespinOver = false
                break
            end
        end
        if isRespinOver == true then 
            -- self:resetMusicBg()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    else
        local col = nil
        local index = nil
        local fastType = self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1]
        for i = 1, #self.m_runSpinResultData.p_selfMakeData.classTotalCounts, 1 do
            local total = self.m_runSpinResultData.p_selfMakeData.classTotalCounts[i]
            local count = self.m_runSpinResultData.p_selfMakeData.classCounts[i]
            if count > 0 then
                col = i
                index = total - count
                self.m_runSpinResultData.p_selfMakeData.classCounts[i] = count - 1
                break
            end
        end
        if col ~= nil and index ~= nil then
            for i = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(col, i, SYMBOL_NODE_TAG)
                if node.p_symbolType == self.SYMBOL_CLASSIC_BONUS1 + col - 1 then
                    if index == 0 then
                        self.m_currBonusNode = node
                        self:changeBonusParent(node)
                        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_trigger_bonus.mp3")
                        node:runAnim("actionframe", false, function()
                            self:showClassicSlot(col, effectData, 1)
                            self:resetBonusParent(node)
                        end)
                        self:updateBonusSymbol(node, col)
                        local spine = node:getCcbProperty("Classic")
                        util_spinePlay(spine, "actionframe")
                        return
                    else
                        index = index - 1
                    end
                end
                
            end
        elseif fastType == self.SYMBOL_CLASSIC_BONUS1 or fastType == self.SYMBOL_CLASSIC_BONUS2
         or fastType == self.SYMBOL_CLASSIC_BONUS3 or fastType == self.SYMBOL_CLASSIC_BONUS4
         or fastType == self.SYMBOL_CLASSIC_BONUS5 then 
            self.m_currBonusNode = self.m_FastReels:getLineNode()
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_trigger_bonus.mp3")
            self.m_FastReels:classicBonusAnimation(function()
                self.m_runSpinResultData.p_selfMakeData.fast.reels[2][1] = nil
                self:showClassicSlot(fastType - self.SYMBOL_CLASSIC_BONUS1 + 1, effectData, 1)
            end)
        else
            self:removeBigMegaBeforeAdd()
            self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_RESPIN)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            self:resetMusicBg()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    
end

function CodeGameScreenEgyptMachine:getInFreespin()
    if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        return true
    end
    return false
end

function CodeGameScreenEgyptMachine:showBonusWinCoin(coin)
    if self:getInFreespin() == false then
        self.m_currBonusNode:getCcbProperty("node_win"):setVisible(true)
        local lab = self.m_currBonusNode:getCcbProperty("m_lb_coins")
        lab:setString(util_formatCoins(coin, 30))
        local info = {label = lab, sx = 1, sy = 1}
        self:updateLabelSize(info, 98)
    end
end

function CodeGameScreenEgyptMachine:showClassicSlot(col, effectData, spinTimes)
    local data = {}
    data.parent = self
    data.col = col
    data.spinTimes = spinTimes
    data.betlevel = self.m_iBetLevel
    data.paytable = self.m_runSpinResultData.p_selfMakeData.classicWinCoins
    data.func = function()
        self:showRespinView(effectData)
    end
    
    self.m_classicMachine = util_createView("GameScreenEgypt.GameScreenEgyptClassicSlots",data)
    self:findChild("classical"):addChild(self.m_classicMachine)
    self.m_classicMachine:gameStart()

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_classicMachine.getRotateBackScaleFlag = function(  ) return false end
    end

end

function CodeGameScreenEgyptMachine:changeBonusParent(slotNode)

    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    slotNode:setScale(self.m_machineRootScale)
    -- 切换图层

   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)

    self:addChild(slotNode,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
end

function CodeGameScreenEgyptMachine:resetBonusParent(slotNode)

    local preParent = slotNode.p_preParent
    if preParent ~= nil then
        slotNode:removeFromParent()
        slotNode.p_layerTag = slotNode.p_preLayerTag
        local nZOrder = slotNode.p_showOrder
        preParent:addChild(slotNode, nZOrder)
        slotNode:setPosition(slotNode.p_preX, slotNode.p_preY)
        slotNode:setScale(1)
        slotNode:runIdleAnim()
    end
end

function CodeGameScreenEgyptMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self.m_classicMachine ~= nil then
        return
    end
    BaseFastMachine.quicklyStopReel(self, colIndex) 

end

-- 老虎机滚动结束调用
function CodeGameScreenEgyptMachine:fastReelsWinslotReelDown()
    -- local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    -- local fast = selfdata.fast or {}
    -- local lines = fast.lines

    -- if lines and #lines > 0 then
        self:setDownTimes(1)
        if self.m_jackPotRunSoundsId then
            gLobalSoundManager:stopAudio(self.m_jackPotRunSoundsId)
            self.m_jackPotRunSoundsId = nil
        end
    -- end
end

function CodeGameScreenEgyptMachine:setDownTimes(time)
    self.m_norSlotsDownTimes = self.m_norSlotsDownTimes + time
    if self.m_norSlotsDownTimes == 2 then
        BaseFastMachine.slotReelDown(self)
        if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self:clearCurMusicBg()
            gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_fs_lastspin.mp3")   -- 结束音
        end
        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )

        self.m_norSlotsDownTimes = 0
    end
end

function CodeGameScreenEgyptMachine:playEffectNotifyChangeSpinStatus()

    if self.m_isOutLines then
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
    else
        self:setNormalAllRunDown(1)
    end
end

function CodeGameScreenEgyptMachine:setNormalAllRunDown(times)
    self.m_norDownTimes = self.m_norDownTimes + times
    print("setNormalAllRunDown   "..self.m_norDownTimes)
    if self.m_norDownTimes == 2 then
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
        self.m_norDownTimes = 0
    end 
end

local L_ABS = math.abs
function CodeGameScreenEgyptMachine:reelSchedulerCheckColumnReelDown(parentData, parentY, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        local colIndex = parentData.cloumnIndex
        local slotParentData = self.m_slotParents[colIndex]
        local slotParent = slotParentData.slotParent

        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end
            
            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            self:slotOneReelDown(colIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig 
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(colIndex, true, halfH)
            end

            if self:getGameSpinStage() == QUICK_RUN and self.m_hasBigSymbol == false then
            --播放滚动条落下的音效
            -- if parentData.cloumnIndex == self.m_iReelColumnNum then

            -- gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            end
            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(colIndex, true, halfH)

            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end
            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            local tipSlotNoes = {}
            self:foreachSlotParent(
                colIndex,
                function(index, realIndex, slotNode)
                    local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                    if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                        --播放关卡中设置的小块效果
                        self:playCustomSpecialSymbolDownAct(slotNode)

                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                                tipSlotNoes[#tipSlotNoes + 1] = slotNode
                            end
                        end
                    end
                end
            )


            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]

                    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPECIAL_BONUS)
                    self:playScatterBonusSound(slotNode)
                    
                    slotNode:runAnim("buling", false, function()
                        -- if self.m_isQuickSpin == false then
                        --     slotNode:runAnim("idle", true)
                        -- end
                        -- if self.m_isQuickSpin == true and #self.m_vecQuickScatter >= 3 then
                        --     for i = 1, #self.m_vecQuickScatter do
                        --         self.m_vecQuickScatter[i]:runAnim("idle", true)
                        --     end
                        -- end
                        self:changeScatterNode(slotNode)
                    end)
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end
            
            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)
            
            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )

            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

-- function CodeGameScreenEgyptMachine:scatterIdleAnimation(slotNode)
--     local reelCol = slotNode.p_cloumnIndex
--     if reelCol == 5 then
--         if self.m_vecScatter ~= nil and #self.m_vecScatter >= 3 then
--             for i = 1, #self.m_vecScatter, 1 do
--                 self.m_vecScatter[i]:runAnim("idle", true)
--             end
--         elseif self.m_vecScatter ~= nil and #self.m_vecScatter < 3 then
--             for i = 1, #self.m_vecScatter, 1 do
--                 self.m_vecScatter[i]:runIdleAnim()
--             end
--         end
--         self.m_vecScatter = {}
--     end
-- end

function CodeGameScreenEgyptMachine:updateBonusSymbol(node, index)
    node:getCcbProperty("node_win"):setVisible(false)
    local spineNode = node:getCcbProperty("Spine")
    if spineNode:getChildByName("Classic") == nil then
        local animationNode = util_spineCreate("Socre_Egypt_bonus"..index, true, true)--util_spineCreateDifferentPath("Socre_Egypt_bonus"..index, "Socre_Egypt_bonus", true, true)
        animationNode:setName("Classic")
        spineNode:addChild(animationNode)
    end
    local spine = node:getCcbProperty("Classic")
    spine:resetAnimation()
end

function CodeGameScreenEgyptMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)

    if symbolType == self.SYMBOL_CLASSIC_BONUS1
     or symbolType == self.SYMBOL_CLASSIC_BONUS2
     or symbolType == self.SYMBOL_CLASSIC_BONUS3
     or symbolType == self.SYMBOL_CLASSIC_BONUS4
     or symbolType == self.SYMBOL_CLASSIC_BONUS5 then
        
    end
end

function CodeGameScreenEgyptMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)


    local reelEffectNodeBG = nil
    local reelActBG = nil
    if self.m_reelRunAnimaBG[col] == nil then
        reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
    else
        local reelBGObj = self.m_reelRunAnimaBG[col]

        reelEffectNodeBG = reelBGObj[1]
        reelActBG = reelBGObj[2]
    end

    reelEffectNodeBG:setScaleX(1)
    reelEffectNodeBG:setScaleY(1)

    reelEffectNodeBG:setVisible(true)
    util_csbPlayForKey(reelActBG, "ationframe", true)

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end


function CodeGameScreenEgyptMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenEgyptMachine:createReelEffectBG(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. "_bg.csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self:findChild("reels"):addChild(reelEffectNode, 1)
    reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
    self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenEgyptMachine:resetScatterNodes()
    local nodeLen = #self.m_vecQuickScatter

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_vecQuickScatter[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                local pos = lineNode:getParent():convertToWorldSpace(cc.p(lineNode:getPosition()))
                pos = preParent:convertToNodeSpace(pos)
                lineNode:removeFromParent()
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                preParent:addChild(lineNode, nZOrder)
                lineNode:setPosition(pos)
                lineNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenEgyptMachine:changeScatterNode(slotNode)

    self.m_vecQuickScatter[#self.m_vecQuickScatter + 1] = slotNode
    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)

    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then

        printInfo("xcyy : %s","slotNode p_rowIndex  p_cloumnIndex isnil")

    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end


--    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenEgyptMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        if self.m_bProduceSlots_InFreeSpin == false then
            self:removeBigMegaBeforeAdd()
        end

    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true  then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeBigMegaBeforeAdd()
    end

    local hasRsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    if hasRsEffect == true then
        self:removeBigMegaBeforeAdd()
    end

    if self.m_runSpinResultData.p_selfMakeData.wheelWinCoins ~= nil then
        self:removeBigMegaBeforeAdd()
        globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - self.m_runSpinResultData.p_selfMakeData.wheelWinCoins
        self.m_iOnceSpinLastWin = globalData.slotRunData.lastWinCoin
    end
end

function CodeGameScreenEgyptMachine:removeBigMegaBeforeAdd()
    self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
    self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
    self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
    self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
end

return CodeGameScreenEgyptMachine






