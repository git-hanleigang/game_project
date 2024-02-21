---
-- island li
-- 2019年1月26日
-- CodeGameScreenVegasLifeMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenVegasLifeMachine = class("CodeGameScreenVegasLifeMachine", BaseNewReelMachine)

CodeGameScreenVegasLifeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenVegasLifeMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenVegasLifeMachine.SYMBOL_FIRE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE
CodeGameScreenVegasLifeMachine.SYMBOL_FIRE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
CodeGameScreenVegasLifeMachine.SYMBOL_MYSTER = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenVegasLifeMachine.SYMBOL_START_x1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenVegasLifeMachine.SYMBOL_START_x2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenVegasLifeMachine.SYMBOL_START_x3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenVegasLifeMachine.SYMBOL_START_x4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenVegasLifeMachine.SYMBOL_START_x5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13 --93 106

CodeGameScreenVegasLifeMachine.VegasLife_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenVegasLifeMachine.m_betLevel = nil -- betlevel 0 1 2
CodeGameScreenVegasLifeMachine.m_jackPotTipsList = {}

CodeGameScreenVegasLifeMachine.m_classicMachine = nil
CodeGameScreenVegasLifeMachine.m_avgBet = 0

CodeGameScreenVegasLifeMachine.m_outLines = nil
CodeGameScreenVegasLifeMachine.m_outLineInitLock = nil
CodeGameScreenVegasLifeMachine.jackpotMappingList = {5,4,3,2,1}
CodeGameScreenVegasLifeMachine.m_IsBonusCollectFull = false
CodeGameScreenVegasLifeMachine.m_IsInClassic = false
-- 构造函数
function CodeGameScreenVegasLifeMachine:ctor()
    CodeGameScreenVegasLifeMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_betLevel = nil
    self.m_jackPotTipsList = {}
    self.m_classicMachine = nil
    self.m_outLines = true
    self.m_avgBet = 0
    self.m_outLineInitLock = true
    self.m_bonusLeftPos = {} --触发classic的bonus
    self.m_winSoundsId = nil
    self.m_winSoundsId1 = nil
    self.m_bonusPlayNum = 0
    self.m_spinRestMusicBG = true
    self.m_showCol = 0 --播放classic到第几列
    self.m_isFirstFreeSpin = false --是否是第一次free 策划要求第一次free的滚动时间 加0.5s
    self.m_reelRunSound = "VegasLifeSounds/VegasLife_quick_run.mp3"--快滚音效
    self.m_shuomingTipStatus = 4 -- 1表示正在显示；2表示idle；3表示正在消失；4表示已经消失完
    self.m_bProduceSlots_InClassic = false --是否处在classic玩法
	--init
	self:initGame()
end

function CodeGameScreenVegasLifeMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("VegasLifeConfig.csv", "LevelVegasLifeConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
end


--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenVegasLifeMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "VegasLifeSounds/VegasLife_scatterBuling.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenVegasLifeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "VegasLife"
end

function CodeGameScreenVegasLifeMachine:scaleMainLayer()
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
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        local ratio = display.height / display.width
        if ratio < 768 / 1024  and ratio >= 640 / 960 then
            self.m_machineNode:setPositionY(mainPosY+15)
        else
            self.m_machineNode:setPositionY(mainPosY+10)
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end

end

function CodeGameScreenVegasLifeMachine:getReelWidth( )
    local ratio = display.height / display.width
    if ratio < 768 / 1024  and ratio >= 640 / 960 then
        return 1300
    else
        return 1270
    end
end

function CodeGameScreenVegasLifeMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:runCsbAction("idle",true)

    -- jackpotbar
    self.m_jackPorBar = util_createView("CodeVegasLifeSrc.VegasLifeJackPotBarView")
    self:findChild("jackpot1"):addChild(self.m_jackPorBar)
    self.m_jackPorBar:initMachine(self)

    self.m_jackpotLock = util_createView("CodeVegasLifeSrc.VegasLifeJackPotLockView",self)
    self:findChild("jackpot2"):addChild(self.m_jackpotLock)

    -- FreeSpinbar
    self.m_VegasLifeFreespinBarView = util_createView("CodeVegasLifeSrc.VegasLifeFreespinBarView")
    self:findChild("freespinbar"):addChild(self.m_VegasLifeFreespinBarView)
    self.m_VegasLifeFreespinBarView:setVisible(false)

    for i=1,5 do
        local name = "bar"..i
        local barname =  "TopBar"..i
        self[barname] =  util_createView("CodeVegasLifeSrc.VegasLifeReelsTopBarView",i,self)
        self:findChild(name):addChild(self[barname],-1)
        self:findChild(name):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE )
    end

    --收集进度条
    self.m_CollectFreeSpinView = util_spineCreate("VegasLife_Superfreegame_Logo", true, true) 
    self:findChild("jindutiao"):addChild(self.m_CollectFreeSpinView)

    self.m_CollectFreeSpinJinDu = util_spineCreate("VegasLife_Superfreegame_Logo2", true, true) 
    self:findChild("jindutiao"):addChild(self.m_CollectFreeSpinJinDu)
    self:updateBarVisible()

    self:addClick(self:findChild("click"))

    self.m_changeScene = util_spineCreate("VegasLife_guochang", false, true)
    self:findChild("guochang"):addChild(self.m_changeScene)
    self.m_changeScene:setPosition(cc.p(display.width/2,display.height/2))
    self.m_changeScene:setVisible(false)

    -- base下idle扫光
    self.m_baseIdleGuang1 = util_spineCreate("GameScreenVegasLifeBg_2", true, true) 
    self:findChild("saoguang_reelborder"):addChild(self.m_baseIdleGuang1,99999)

    -- base下idle扫光
    self.m_baseIdleGuang2 = util_spineCreate("GameScreenVegasLifeBg_3", true, true) 
    self:findChild("saoguang2"):addChild(self.m_baseIdleGuang2,99999)

    -- base下idle扫光
    self.m_baseIdleGuang3 = util_spineCreate("GameScreenVegasLifeBg_4", true, true) 
    self:findChild("saoguang"):addChild(self.m_baseIdleGuang3,99999)

    self.m_baseIdleGuang4 = util_spineCreate("GameScreenVegasLifeBg_5", true, true) 
    self:findChild("saoguang"):addChild(self.m_baseIdleGuang4,99999)

    -- 说明框
    self.m_shuomingTip = util_createAnimation("VegasLife_shouji_shuomingkuang.csb")
    self:findChild("Node_shuomingkuang"):addChild(self.m_shuomingTip)
    
    --classic paytable
    self.m_classicPayTable = util_createAnimation("VegasLife_Classic_Paytable.csb")
    self:findChild("Classic_paytable"):addChild(self.m_classicPayTable)
    self.m_classicPayTable:setVisible(false)
    for i=2,5 do
        self.m_classicPayTable:findChild("VegasLife_paytable0"..i):setVisible(false)
    end

    self:changeBgState(0)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        if self.m_classicMachine then
            return
        end
        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 1
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE  then
            if winRate <= 1 then
                soundIndex = 11
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 22
            elseif winRate > 3 then
                soundIndex = 33
            end
        end
        -- 和赢钱线一起播 ：base或free中赢钱大于3倍小于big win时；classic中赢钱大于10倍时
        if winRate >= 3 and winRate < self.m_BigWinLimitRate then
            self.m_winSoundsId1 = gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_winSound4.mp3")
        end

        local soundName = "VegasLifeSounds/VegasLife_winSound".. soundIndex .. ".mp3"
        -- self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

-- 进入关卡显示说明框
function CodeGameScreenVegasLifeMachine:showShuoMingTip( )
    if self.m_bProduceSlots_InFreeSpin or self.m_bProduceSlots_InClassic then 
        return
    end

    self.m_shuomingTipStatus = 1
    self.m_shuomingTip:runCsbAction("start",false,function()
        self.m_shuomingTipStatus = 2
        self.m_shuomingTip:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self.m_shuomingTipStatus = 3
            self.m_shuomingTip:runCsbAction("over",false,function()
                self.m_shuomingTipStatus = 4
                if self.m_scheduleId then
                    self:stopAction(self.m_scheduleId)
                    self.m_scheduleId = nil
                end
            end)
        end, 5)
    end)
end

--默认按钮监听回调
function CodeGameScreenVegasLifeMachine:clickFunc(sender)
    local name = sender:getName()
    if self.m_bProduceSlots_InFreeSpin or self.m_bProduceSlots_InClassic then 
        return
    end

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    if name == "click" then
        if self.m_shuomingTipStatus == 4 then
            self:showShuoMingTip()
        elseif self.m_shuomingTipStatus == 2 then
            self.m_shuomingTipStatus = 3
            self.m_shuomingTip:runCsbAction("over",false,function()
                self.m_shuomingTipStatus = 4
            end)
        end
    end
end

--更新superfree 进度条
function CodeGameScreenVegasLifeMachine:updateBarVisible(isAdd, fun)
    if not self.m_CollectFreeSpinView:isVisible() then
        return
    end

    local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
    if selfMakeData then

        local freeSpinCount = selfMakeData.freeSpinCount
        util_spinePlay(self.m_CollectFreeSpinView,"idleframe",true)

        if freeSpinCount and freeSpinCount > 0 then
            if isAdd then
                if not self.m_reconnect then
                    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_superFree_collect.mp3")
                    util_spinePlay(self.m_CollectFreeSpinJinDu,"start"..freeSpinCount,false)
                    util_spineEndCallFunc(self.m_CollectFreeSpinJinDu,"start"..freeSpinCount,function ()
                        util_spinePlay(self.m_CollectFreeSpinJinDu,"idleframe"..freeSpinCount,true)
                    end)
                else
                    util_spinePlay(self.m_CollectFreeSpinJinDu,"idleframe"..freeSpinCount,true)
                end
                if freeSpinCount < 10 and fun then
                    fun()
                end
            else
                util_spinePlay(self.m_CollectFreeSpinJinDu,"idleframe"..freeSpinCount,true)
            end
        else
            util_spinePlay(self.m_CollectFreeSpinView,"idleframe",true)
            util_spinePlay(self.m_CollectFreeSpinJinDu,"idleframe",true)
        end
        if freeSpinCount and freeSpinCount >= 10 and isAdd then
            performWithDelay(self,function(  )
                gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_superFree_collect_full.mp3")
                util_spinePlay(self.m_CollectFreeSpinView,"actionframe",false)
                util_spinePlay(self.m_CollectFreeSpinJinDu,"actionframe",false)
            end,0.5)
            if fun then
                util_spineEndCallFunc(self.m_CollectFreeSpinView,"actionframe",function ()
                    fun()
                end)
            end
        end 
    end
end

function CodeGameScreenVegasLifeMachine:initBottomUI()
    local bottomNode = util_createView("CodeVegasLifeSrc.VegasLife_GameBottomNode",self)
    self:addChild(bottomNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
    if globalData.slotRunData.isPortrait == false then
        bottomNode:setScaleForResolution(true)
    end
    bottomNode:setPositionX(display.cx)
    bottomNode:setPositionY(0)

    self.m_bottomUI = bottomNode
end

function CodeGameScreenVegasLifeMachine:enterGamePlayMusic(  )

    self:playEnterGameSound( "VegasLifeSounds/VegasLife_enterLevel.mp3" )
end

function CodeGameScreenVegasLifeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenVegasLifeMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

end


function CodeGameScreenVegasLifeMachine:normalSpinBtnCall( )
    if self.m_IsInClassic then
        return
    end

    CodeGameScreenVegasLifeMachine.super.normalSpinBtnCall(self)
    self:setMaxMusicBGVolume( )
    
end

function CodeGameScreenVegasLifeMachine:addObservers()
    CodeGameScreenVegasLifeMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
   end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenVegasLifeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenVegasLifeMachine.super.onExit(self)      -- 必须调用不予许删除

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenVegasLifeMachine:MachineRule_GetSelfCCBName(symbolType)


    if self.SYMBOL_SCORE_10 == symbolType then
        return "Socre_VegasLife_10"
    elseif self.SYMBOL_FIRE_WILD == symbolType then
        return "Socre_VegasLife_rapid2"
    elseif self.SYMBOL_MYSTER == symbolType then

        return "Socre_VegasLife_1"

    elseif self.SYMBOL_FIRE == symbolType then
        return "Socre_VegasLife_rapid1"
    elseif self.SYMBOL_START_x1 == symbolType then
        return "Socre_VegasLife_Bonus1"
    elseif self.SYMBOL_START_x2 == symbolType then
        return "Socre_VegasLife_Bonus2" 
    elseif self.SYMBOL_START_x3 == symbolType then
        return "Socre_VegasLife_Bonus3"
    elseif self.SYMBOL_START_x4 == symbolType then
        return "Socre_VegasLife_Bonus4"
    elseif self.SYMBOL_START_x5 == symbolType then
        return "Socre_VegasLife_Bonus5"

    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenVegasLifeMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenVegasLifeMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIRE_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MYSTER,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIRE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_START_x1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_START_x2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_START_x3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_START_x4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_START_x5,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenVegasLifeMachine:restLeveldData(  )

    if self.m_IsBonusCollectFull then
        self:upateBetLevel(self.m_avgBet, true)
    else
        self:upateBetLevel()
    end

    self:updateBarVisible( )


    -- self:randomMyster( )
    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.m_bProduceSlots_InClassic = true
        self.m_bonusPlayNum = self.m_runSpinResultData.p_reSpinsTotalCount - self.m_runSpinResultData.p_reSpinCurCount 
    end

    -- 显示tip
    self:showShuoMingTip()
end

-- 断线重连
function CodeGameScreenVegasLifeMachine:MachineRule_initGame(  )
    self.m_reconnect = true
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
        if selfMakeData and selfMakeData.freeSpinCount and selfMakeData.freeSpinCount == 10 then
            self.m_IsBonusCollectFull = true
            self.m_bottomUI:showAverageBet()
        end
        self.m_VegasLifeFreespinBarView:changeBgFreeSpin(self.m_IsBonusCollectFull)
        self:changeBgState(1)
        self.m_CollectFreeSpinView:setVisible(false)
        self.m_CollectFreeSpinJinDu:setVisible(false)
        self.m_VegasLifeFreespinBarView:setVisible(true)
    end
    self:setMysterTypeFromNet( )
end

function CodeGameScreenVegasLifeMachine:setMysterTypeFromNet( )
    local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
    if selfMakeData and selfMakeData.mystery then
        self.m_configData:setMysterSymbol(selfMakeData.mystery)
        self.m_configData:setMysterRandomRoolIndex()
    end
end
--
--单列滚动停止回调
--
function CodeGameScreenVegasLifeMachine:slotOneReelDown(reelCol)
    CodeGameScreenVegasLifeMachine.super.slotOneReelDown(self,reelCol)

    -- local isHaveFixSymbol = false
    local isPlayJackpotBuling = false
    for k = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[k][reelCol]
        if self:isSymbolBuling(symbolType) then
            -- isHaveFixSymbol = true
            local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
            if self:isSymbolStart(symbolType) then
                if symbolNode.runAnim then
                    symbolNode:runAnim("buling")
                end
                gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_bonusBuling.mp3")
            elseif symbolType == self.SYMBOL_FIRE_WILD or symbolType == self.SYMBOL_FIRE then
                if self:checkTriggerJackpot(reelCol) then
                    if symbolNode.runAnim then
                        symbolNode:runAnim("buling")
                    end
                    if not isPlayJackpotBuling then
                        isPlayJackpotBuling = true
                        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_jackpotBuling.mp3")
                    end

                end
            end
        end
    end
end

function CodeGameScreenVegasLifeMachine:checkTriggerJackpot(reelCol)
    if reelCol == 5 then
        local beforeNum = 0
        for i=1,reelCol - 1 do
            for k = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[k][i]
                if  symbolType == self.SYMBOL_FIRE_WILD or symbolType == self.SYMBOL_FIRE then
                    beforeNum = beforeNum + 1
                end
            end
        end
        if beforeNum > 2 then
            return true
        end
        return false
    else
        return true
    end
end
--增加提示节点
function CodeGameScreenVegasLifeMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            if slotNode.p_reelDownRunAnima ~= nil then
                slotNode:playReelDownAnima()

                if slotNode.p_reelDownRunAnimaSound ~= nil then
                    gLobalSoundManager:playSound(slotNode.p_reelDownRunAnimaSound)
                end
                if slotNode.p_reelDownRunAnimaTimes then
                    self.m_reelDownAddTime = slotNode.p_reelDownRunAnimaTimes
                end
            end

            if
                slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
                    slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS
             then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    slotNode:runAnim("idleframe",true)
                end
                
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex,slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end

            --                            break
            end
        --                        end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenVegasLifeMachine:specialSymbolActionTreatment( node)
    if not node then
        return
    end

    node:runAnim("buling",false,function(  )
        node:runAnim("idleframe",true)
    end)

end


-- function CodeGameScreenVegasLifeMachine:slotReelDown( )
--     CodeGameScreenVegasLifeMachine.super.slotReelDown(self)
-- end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenVegasLifeMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenVegasLifeMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
end
---------------------------------------------------------------------------

---
-- 显示free spin
function CodeGameScreenVegasLifeMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_scatter_trigger.mp3")

    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenVegasLifeMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_freespin_more.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:updateBarVisible(true, function() 
                performWithDelay(self,function(  )
                    local random = math.random(1,2)
                    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_freespin_start" .. random .. ".mp3")
                    
                    self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                        self:playChangeScene(function()
                            
                        end)
                        -- 过场50帧切换背景
                        performWithDelay(self,function(  )
                            self:changeBgState(1, true)
                            self.m_CollectFreeSpinView:setVisible(false)--
                            self.m_CollectFreeSpinJinDu:setVisible(false)
                            self.m_VegasLifeFreespinBarView:setVisible(true)

                            if  self.m_IsBonusCollectFull then
                                self.m_bottomUI:showAverageBet()
                                --显示avergaebet的时候 无视bet强行解锁 所以的jackpot
                                self:upateBetLevel(self.m_avgBet, true)
                            end
                            
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                            self.m_isFirstFreeSpin = true
                        end,40/30)

                    end)
                end,1)
                
            end)
            
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()
    end,0.5)
end

function CodeGameScreenVegasLifeMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    local selfMakeData =  self.m_runSpinResultData.p_selfMakeData

    if selfMakeData and selfMakeData.freeSpinCount and selfMakeData.freeSpinCount == 10 then
        self.m_IsBonusCollectFull = true
        self.m_VegasLifeFreespinBarView:changeBgFreeSpin(self.m_IsBonusCollectFull)
        return self:showDialog("FreeSpinStart2",ownerlist,func)
    else
        self.m_VegasLifeFreespinBarView:changeBgFreeSpin(self.m_IsBonusCollectFull)
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)

    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end


function CodeGameScreenVegasLifeMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    
    if self.m_IsBonusCollectFull then
        return self:showDialog("FreeSpinOver2",ownerlist,func)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    end

    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenVegasLifeMachine:changeClassOverFreeSpinOverBigWinEffect( )
    

    if self.m_gameEffects then
        local effectLen = #self.m_gameEffects
        local isStop = false
        local isFreespinOver = false
    
        for i = 1, effectLen , 1 do
    
            local effectData = self.m_gameEffects[i]
            local effectType = effectData.p_effectType

            if effectData.p_isPlay ~= true then
                
    
                if effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
                    isFreespinOver = true
                end
    
            end
    
            if isFreespinOver then
                local bigwinOver = false
                if effectType == GameEffect.EFFECT_EPICWIN then
                    bigwinOver = true
                elseif effectType == GameEffect.EFFECT_MEGAWIN then
                    bigwinOver = true
                elseif effectType == GameEffect.EFFECT_NORMAL_WIN then
                    bigwinOver = true
                elseif effectType == GameEffect.EFFECT_BIGWIN then
                    bigwinOver = true
                end
    
                if bigwinOver then
                    isFreespinOver = false
                    isStop = true
    
                    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                    local fLastWinBetNumRatio = self.m_llBigOrMegaNum / lTatolBetNum

                    local iBigWinLimit = self.m_BigWinLimitRate
                    local iMegaWinLimit = self.m_MegaWinLimitRate
                    local iEpicWinLimit = self.m_HugeWinLimitRate
                    if fLastWinBetNumRatio >= iEpicWinLimit then
    
                        self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_EPICWIN
                        
                    elseif fLastWinBetNumRatio >= iMegaWinLimit then
    
                        self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_MEGAWIN
    
                    elseif fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
    
                        self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_BIGWIN
    
                    end
                end
                
            end
    
            if isStop == true then
                break
            end
        end
    end
   

end

function CodeGameScreenVegasLifeMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_freespin_over.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local fsOverCoins = self.m_runSpinResultData.p_fsWinCoins
    self.m_llBigOrMegaNum = fsOverCoins
    self:changeClassOverFreeSpinOverBigWinEffect()
    
    local strCoins = util_formatCoins(fsOverCoins,30)

    local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:playChangeScene(function()
            self:triggerFreeSpinOverCallFun()
            self:resetMusicBg()
        end)
        -- 过场50帧切换背景
        performWithDelay(self,function(  )
            self:changeBgState(0, true)
            self.m_CollectFreeSpinView:setVisible(true)
            self.m_CollectFreeSpinJinDu:setVisible(true)
            self.m_VegasLifeFreespinBarView:setVisible(false)
            if not self.m_IsBonusCollectFull then
                self:updateBarVisible(false)
            end

            if  self.m_IsBonusCollectFull then
                self:updateBarVisible()
                self.m_IsBonusCollectFull = nil
                self.m_bottomUI:hideAverageBet()
                self:upateBetLevel(nil, true)
            end
        end,50/30)
    end)
    local node=view:findChild("m_lb_coins")
    if self.m_IsBonusCollectFull then
        view:updateLabelSize({label=node,sx=1.1,sy=1.1},585)
    else
        view:updateLabelSize({label=node,sx=1.1,sy=1.1},770)
    end
end

function CodeGameScreenVegasLifeMachine:triggerFreeSpinOverCallFun()
    self:checkQuestDoneGameEffect()
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode( NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")

    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())

end

--检测是否可以增加quest 完成事件
function CodeGameScreenVegasLifeMachine:checkQuestDoneGameEffect()
    local questConfig = G_GetActivityDataByRef(ACTIVITY_REF.Quest)
    if not questConfig then
        return
    end
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == false then
        local questEffect = GameEffectData:create()
        questEffect.p_effectType =  GameEffect.EFFECT_QUEST_DONE  --创建属性
        questEffect.p_effectOrder = 999999  --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenVegasLifeMachine:MachineRule_SpinBtnCall()
    -- self:setMaxMusicBGVolume()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if self.m_winSoundsId1 then
        gLobalSoundManager:stopAudio(self.m_winSoundsId1)
        self.m_winSoundsId1 = nil
    end
    self.m_outLines = false

    if self.m_scheduleId then
        self.m_shuomingTip:runCsbAction("over",false,function()
            self.m_shuomingTipStatus = 4
        end)
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    else
        if self.m_shuomingTipStatus == 2 then
            self.m_shuomingTipStatus = 3
            self.m_shuomingTip:runCsbAction("over",false,function()
                self.m_shuomingTipStatus = 4
            end)
        end
    end

    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenVegasLifeMachine:MachineRule_network_InterveneSymbolMap()
    self:setMysterTypeFromNet( )
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenVegasLifeMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end

--------------------添加动画

function CodeGameScreenVegasLifeMachine:checkAddJackPotEffect( )


    self.m_jackPotTipsList={}
    local jackpotNum = 0
    local maxRow=#self.m_runSpinResultData.p_reelsData
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType ==self.SYMBOL_FIRE_WILD
                    or targSp.p_symbolType ==self.SYMBOL_FIRE then
                        jackpotNum=jackpotNum+1
                        self.m_jackPotTipsList[jackpotNum]=targSp
                end
            end
        end
    end


    if jackpotNum<3   then
        self.m_jackPotTipsList=nil
    else

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.VegasLife_JACKPOT_EFFECT

    end
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenVegasLifeMachine:addSelfEffect()

        -- 检测是否添加jackPot动画
        self:checkAddJackPotEffect()
        local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
        if hasQuestEffect == true and self.m_bProduceSlots_InFreeSpin then
            self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
        end
end

-- ClassicRapidJackPot玩法
function CodeGameScreenVegasLifeMachine:ClassicVegasLifeJackPotAct(effectData)
    local function clearLine()
        self:clearWinLineEffect()

        if self.m_isShowMaskLayer == true then
            self:resetMaskLayerNodes()
            -- 隐藏所有的遮罩 layer

        end
    end

    -- 触发rapid的时候 可能会同时触发其他玩法 此时需要删除大赢
    local function cheackRemoveEffect()
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
            if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
                self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
                self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
                    
                    self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                    self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                    self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            end
        end
    end

    if self.m_jackPotTipsList and #self.m_jackPotTipsList>0 then
        local count=#self.m_jackPotTipsList
        if count>9 then
            count=9
        end

        --jackpot加钱逻辑
        local index=10-count
        local score = self:BaseMania_getJackpotScore(index)
        clearLine()

        if count >= 3 then
            for _,targSp in ipairs(self.m_jackPotTipsList) do
                targSp:runAnim("actionframe",true)
            end
        end

        self.m_jackPotTipsList=nil

        if count>=5 then
            -- 5个以上rapid 触发的时候 才会播放触发音效，3个4个 不播
            gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_jackPot_trigger.mp3")
            local jpScore = score
            if self.m_runSpinResultData.p_selfMakeData then
                if self.m_runSpinResultData.p_selfMakeData.jackpotWinCoins then
                    jpScore = self.m_runSpinResultData.p_selfMakeData.jackpotWinCoins
                end
            end

            local result
            if self.m_betLevel >= 4 then
                result = self.m_jackpotLock:showjackPotAction(count)
            else
                local myLevelBet = {5,6,7,8,9}
                if count > myLevelBet[self.m_betLevel+1] then
                    result = self.m_jackpotLock:showjackPotAction(myLevelBet[self.m_betLevel+1])
                    index=10-myLevelBet[self.m_betLevel+1]
                else
                    result = self.m_jackpotLock:showjackPotAction(count)
                end
            end
            self.m_jackPorBar:showjackPotAction(result)
            gLobalSoundManager:pauseBgMusic()

            -- 中5/6两档Jackpot时 播放1遍 时间3秒 ，其他档位2遍 时间6秒
            local delayTime = 6
            if count == 5 or count == 6 then
                delayTime = 3
            else
                -- 7/8/9三挡 播了两遍触发动画 所以三秒之后需要在播一遍音效
                performWithDelay(self,function()
                    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_jackPot_trigger.mp3")
                end,3)
            end
            performWithDelay(self,function(  )
                self.m_jackpotLock:clearAnim()
                self.m_jackPorBar:clearAnim()
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()

                self:showJackPot(jpScore,index,function()
                    -- self:resetMusicBg()
                    -- 通知UI钱更新
                    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                        -- freeSpin下特殊玩法的算钱逻辑
                        if #self.m_vecGetLineInfo == 0  then
                            print("没有赢钱线，得手动加钱")

                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
                        else
                            print("在算线钱的时候就已经把特殊玩法赢的钱加到总钱了，所以不用更新钱")

                        end

                    else
                        if #self.m_vecGetLineInfo == 0 then

                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})

                            if not self.m_bProduceSlots_InFreeSpin  then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                            end
                            
                        end

                    end
                    cheackRemoveEffect()
                    effectData.p_isPlay = true
                    self:playGameEffect()

                end)
            end,delayTime)
        else
            -- performWithDelay(self,function(  )
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()
                cheackRemoveEffect()
                effectData.p_isPlay = true
                self:playGameEffect()
            -- end,3)
        end
    end

end


function CodeGameScreenVegasLifeMachine:playChangeScene(overCallback)
    self:setMinMusicBGVolume( )
    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_changescene.mp3")

    self.m_changeScene:setVisible(true)
    -- 过场动画
    util_spinePlay(self.m_changeScene,"actionframe")

    util_spineEndCallFunc(self.m_changeScene,"actionframe",function ()
        --构造盘面数据0
        self.m_changeScene:setVisible(false)
        if overCallback then
            overCallback()
        end
    end)
end

-- 显示普通的jackpot
function CodeGameScreenVegasLifeMachine:showJackPot(coins,num,func)

    self:setMinMusicBGVolume( )

    local view=util_createView("CodeVegasLifeSrc.VegasLifeJackPotWinView",1,self)

    local courFunc = function(  )

        self:setMaxMusicBGVolume()

        if func then
            func()
        end
    end

    view:initViewData(coins,num,courFunc)
    gLobalViewManager:showUI(view)
    self:specialAdaptive(view)
end

-- 显示classic玩法 的 jackpot
function CodeGameScreenVegasLifeMachine:showClassicJackPot(coins,index,func)

    
    local view=util_createView("CodeVegasLifeSrc.VegasLifeJackPotWinView",2,self)

    self:setMinMusicBGVolume( )

    local courFunc = function(  )

        self:setMaxMusicBGVolume()

        if func then
            func()
        end

        -- 不是Jackpot 连线的时候 延时自动消失，jackpot连线的时候 弹板关闭的时候消失
        self.m_classicPayTable:runCsbAction("idle") 

        self:unShowClassicJackPotAction(index) 
    end

    view:initClassicViewData(coins,index,courFunc)
    gLobalViewManager:showUI(view)
    self:specialAdaptive(view)
end

-- 特殊适配
function CodeGameScreenVegasLifeMachine:specialAdaptive(view)
    -- 策划要求 这么写的，1024上下的范围（策划定的） 弹板适配,其他不处理
    local ratio = display.height / display.width
    if ratio >= (768/1024 - 0.02) and ratio <= (768/1024 + 0.02) then
        view:findChild("rootNode"):setScale(self.m_machineRootScale)
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenVegasLifeMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.VegasLife_JACKPOT_EFFECT then
        self:ClassicVegasLifeJackPotAct(effectData)
    end
	return true
end

-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenVegasLifeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

--小块
function CodeGameScreenVegasLifeMachine:getBaseReelGridNode()
    return "CodeVegasLifeSrc.VegasLifeSlotNode"
end


function CodeGameScreenVegasLifeMachine:getBetLevel( )
    return self.m_betLevel
end


function CodeGameScreenVegasLifeMachine:requestSpinResult()
    if self.m_classicMachine then
        return
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if self.m_winSoundsId1 then
        gLobalSoundManager:stopAudio(self.m_winSoundsId1)
        self.m_winSoundsId1 = nil
    end

    self.m_reconnect = false
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
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( ) }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)

end

--服务器没有基础值初始化一份
function CodeGameScreenVegasLifeMachine:updateJackpotList()
    self.m_jackpotList = {}
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index ,poolData in pairs(jackpotPools) do 
            local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData,false,globalData.slotRunData:getCurTotalBet())
            if self.m_IsBonusCollectFull and self.m_avgBet ~= 0 then
                totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData,false,self.m_avgBet)
            end
            self.m_jackpotList[index]=totalScore-baseScore
        end
    end
    
end

function CodeGameScreenVegasLifeMachine:updatJackPotLock( level )

    if self.m_betLevel == nil or  self.m_betLevel ~= level then
        self.m_betLevel = level

        self.m_jackPorBar:updateLock( self.m_betLevel,self.m_outLineInitLock )
        self.m_jackpotLock:updateLock( self.m_betLevel ,self.m_outLineInitLock)

    end
end


function CodeGameScreenVegasLifeMachine:unlockHigherBet(_level)

    local features = self.m_runSpinResultData.p_features or {}

    if self.m_bProduceSlots_InFreeSpin == true or 
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and 
    self:getGameSpinStage() ~= IDLE ) or 
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or 
    self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self.m_classicMachine or
    self:getCurrSpinMode() == FREE_SPIN_MODE or
    self:getCurrSpinMode() == RESPIN_MODE or
    #features >= 2
    then
        return
    end

    local level = _level - 1
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if self.m_betLevel and level <= self.m_betLevel then
        return
    end

    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    if self.m_specialBets == nil then
        return
    end


    local betGear = self.m_specialBets[level].p_totalBetValue

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= betGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end


--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenVegasLifeMachine:upateBetLevel(_curBetCoins, _isPlaySound)

    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    if self.m_specialBets == nil then
        return
    end

    local betCoin = _curBetCoins or globalData.slotRunData:getCurTotalBet()
    local level = 0
    
    for k,v in pairs(self.m_specialBets) do
        local betleveCoin = v.p_totalBetValue
        if betCoin >= betleveCoin then
            level = k
        else
            break
        end
    end

    if level == nil then
        level = 0
    end

    if self.m_betLevel and not _isPlaySound then
        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_unLockJackpot.mp3")
    end

    local coins1 = self.m_specialBets[#self.m_specialBets].p_totalBetValue
    local coins2 = self.m_specialBets[#self.m_specialBets - 1].p_totalBetValue
    local coins3 = self.m_specialBets[#self.m_specialBets - 2].p_totalBetValue
    local coins4 = self.m_specialBets[#self.m_specialBets - 3].p_totalBetValue
    local list = {coins4,coins3,coins2,coins1}
    self.m_jackpotLock:updateLocklab(list)
    self:updatJackPotLock( level )

    self:updateTopLittleBarLock(list)

    if self.m_outLineInitLock then
        self.m_outLineInitLock = false
    end
end

function CodeGameScreenVegasLifeMachine:updateTopLittleBarLock(list)
    local betLevel = self:getBetLevel()
    if betLevel then
        local tempLv = 5 - betLevel
        for i=1,5 do
            local barname =  "TopBar"..i
            local littleBar =  self[barname]
            if littleBar then
                if i < 5  then
                   littleBar:showUnLockBet(list[5-i])
                   if i >= tempLv  then
                        littleBar:showUnLock(betLevel,self.m_outLineInitLock)
                    else
                        littleBar:showLock(betLevel)
                    end
                else
                    littleBar:showUnLock(betLevel,self.m_outLineInitLock)
                end
            end
        end
    end
end

function CodeGameScreenVegasLifeMachine:getProMysterIndex( array )

    local index = 1
    local Gear = 0
    local tableGear = {}
    for k,v in pairs(array) do
        Gear = Gear + v
        table.insert( tableGear, Gear )
    end

    local randomNum = math.random( 1,Gear )

    for kk,vv in pairs(tableGear) do
        if randomNum <= vv then
            return kk
        end

    end

    return index

end

-- 更新背景 相关
-- isChange表示是否切换背景
function CodeGameScreenVegasLifeMachine:changeBgState( states, isChange)

    util_spinePlay(self.m_baseIdleGuang1,"idleframe",true)
    
    util_spinePlay(self.m_baseIdleGuang3,"idleframe",true)
    util_spinePlay(self.m_baseIdleGuang4,"idleframe",true)
    self:findChild("superfree_bg4_1"):setVisible(false)
    if states == 0 then
        self.m_baseIdleGuang2:setVisible(true)
        util_spinePlay(self.m_baseIdleGuang2,"idleframe",true)
        if isChange then
            if self.m_IsBonusCollectFull then
                self.m_gameBg:runCsbAction("superfree_normal",false,function()
                    self.m_gameBg:runCsbAction("idle1",true)
                end)
            else
                self.m_gameBg:runCsbAction("free_normal",false,function()
                    self.m_gameBg:runCsbAction("idle1",true)
                end)
            end
        else
            self.m_gameBg:runCsbAction("idle1",true)
        end
        
        self:findChild("base_reel"):setVisible(true)
        self:findChild("free_reel"):setVisible(false)
        self:findChild("Panel_base"):setVisible(true)
        self:findChild("Panel_free"):setVisible(false)
    elseif states == 1 then
        self.m_baseIdleGuang2:setVisible(false)
        
        self:findChild("base_reel"):setVisible(false)
        self:findChild("free_reel"):setVisible(true)
        self:findChild("Panel_base"):setVisible(false)
        self:findChild("Panel_free"):setVisible(true)
        if self.m_IsBonusCollectFull then
            if isChange then
                self.m_gameBg:runCsbAction("normal_superfree",false,function()
                    self.m_gameBg:runCsbAction("superfree",true)
                    self:findChild("superfree_bg4_1"):setVisible(true)
                end)
            else
                self.m_gameBg:runCsbAction("superfree",true)
                self:findChild("superfree_bg4_1"):setVisible(true)
            end
        else
            if isChange then
                self.m_gameBg:runCsbAction("normal_free",false,function()
                    self.m_gameBg:runCsbAction("idle2",true)
                    self:findChild("superfree_bg4_1"):setVisible(false)
                end)
            else
                self.m_gameBg:runCsbAction("idle2",true)
                self:findChild("superfree_bg4_1"):setVisible(false)
            end
        end
    end
end

function CodeGameScreenVegasLifeMachine:createClassicMachine(_isFirst)
    if self.classicSoundSpinIndex > 3 then
        self.classicSoundSpinIndex = 1
    end
    self.m_classicMachine:startPlay(self.classicSoundSpinIndex, _isFirst)
    self.classicSoundSpinIndex = self.classicSoundSpinIndex + 1
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()

end

function CodeGameScreenVegasLifeMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self.m_classicMachine then
        return
    end
    CodeGameScreenVegasLifeMachine.super.quicklyStopReel(self, colIndex) 

end

-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenVegasLifeMachine:checkOpearReSpinAndSpecialReels( param )
    -- self:closeCheckTimeOut()
    if self.m_classicMachine then
        if param[1] == true then
            local spinData = param[2]
            if spinData.action == "SPIN" then

                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
                -- self:getRandomList()
                -- self:stopRespinRun()
            end
        else

        end
        return true
    end
    return false
end

---
-- 处理spin 返回结果
function CodeGameScreenVegasLifeMachine:spinResultCallFun(param)

    CodeGameScreenVegasLifeMachine.super.spinResultCallFun(self,param)

    self.m_avgBet = 0
    if param and param[1] then
        local spinData = param[2]
        if spinData.result  then
            if  spinData.result.freespin then
                if spinData.result.freespin.extra then
                    if spinData.result.freespin.extra.avgBet then
                        self.m_avgBet = spinData.result.freespin.extra.avgBet
                    end
                end
                
            end
        end
    end

end


--属于顶部jackpot触发图标
function CodeGameScreenVegasLifeMachine:isSymbolStart( symbolType )
    local result = false

    if self.SYMBOL_START_x1 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x2 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x3 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x4 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x5 == symbolType  then
        result = true
    end

   return result
end
--包含buling动画图标
function CodeGameScreenVegasLifeMachine:isSymbolBuling( symbolType )
    local result = false

    if self.SYMBOL_START_x1 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x2 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x3 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x4 == symbolType then
        result = true
    elseif  self.SYMBOL_START_x5 == symbolType  then
        result = true
    elseif  self.SYMBOL_FIRE_WILD == symbolType  then
        result = true
    elseif  self.SYMBOL_FIRE == symbolType  then
        result = true
    end

   return result
end
function CodeGameScreenVegasLifeMachine:startFly(callback)
    if self.m_flyIndex == nil then
        self.m_flyIndex = 1
    end

    local temp = self.m_flyList[self.m_flyIndex]--参数 行 列
    local state = 9
    if self.m_ColList[temp[2]] == nil then
        self.m_ColList[temp[2]] = 1
        state = 0
    end
    local targSp = self:getFixSymbol(temp[2], temp[1], SYMBOL_NODE_TAG)

    local startPos = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
    local barname =  "TopBar"..self.jackpotMappingList[temp[2]]
    local endPos = self[barname]:getParent():convertToWorldSpace(cc.p(self[barname]:findChild("end"):getPosition()))
    if state == 0 then
        self[barname]:changeState(state,function()
            self[barname]:showSpinTime(0)
        end)
    end
    -- local tarSp = self:getFixSymbol(temp[2], temp[1], SYMBOL_NODE_TAG)

    targSp:runAnim("shouji")
    gLobalSoundManager:setBackgroundMusicVolume(0)

    self:runFlyAction(0.1,0.6,startPos,endPos,function()
        -- if state == 0 then
         local barname_1 = barname

        self[barname_1]:changeState(9,function()

            self.m_flyIndex = self.m_flyIndex + 1
            if self.m_flyIndex <= #self.m_flyList then
                self:startFly(callback)
            else
                performWithDelay(self,function()
                    self.m_flyIndex = 1
                    if callback then
                        callback()
                    end
                end,0.5)
            end
        end,function(  )

            local nextCount = self[barname_1].m_curIndex + 1
            self[barname_1]:showSpinTime(nextCount)

        end)
        -- end
    end)
end
function CodeGameScreenVegasLifeMachine:runFlyAction(time,flyTime,startPos,endPos,callback)


    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_jackpotcollect.mp3")

    local node2 = cc.ParticleSystemQuad:create("effect/shouji_lizi.plist")
    node2:setVisible(false)
    self:addChild(node2, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node2:setPosition(startPos)

    local actionList2 = {}
    actionList2[#actionList2 + 1] = cc.DelayTime:create(time)
    actionList2[#actionList2 + 1] = cc.CallFunc:create(function()
        node2:setVisible(true)
    end)
    actionList2[#actionList2 + 1] = cc.MoveTo:create(flyTime,endPos)
    actionList2[#actionList2 + 1] = cc.CallFunc:create(function()
        node2:setVisible(false)
        node2:removeFromParent()
    end)
    node2:runAction(cc.Sequence:create(actionList2))

    local node = util_createAnimation("VegasLife_wheel_shouji.csb")
    node:playAction("animation0",false,function()
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:setVisible(false)
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    node:setPosition(startPos)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()

       
    end)
    node:runAction(cc.Sequence:create(actionList))


    local node3 = cc.Node:create()
    
    self:addChild(node3, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node3:setPosition(startPos)

    local actionList3 = {}
    actionList3[#actionList3 + 1] = cc.DelayTime:create(flyTime + time )
    actionList3[#actionList3 + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
        node3:removeFromParent()
    end)
 
    node3:runAction(cc.Sequence:create(actionList3))

end
function CodeGameScreenVegasLifeMachine:classicOverResetView()

    if self.m_IsBonusCollectFull then
        self:upateBetLevel(self.m_avgBet, true)
    else
        self:upateBetLevel(nil, true)
    end

end

function CodeGameScreenVegasLifeMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true
    self.m_bProduceSlots_InClassic = true

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
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
        end,1,self:getModuleName())

    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin,self.m_iOnceSpinLastWin)
    return true

end

-- respin
function CodeGameScreenVegasLifeMachine:showRespinView()
    self.classicSoundSpinIndex = 1
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    
    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end
    self.m_flyList = {}
    if not self.m_reconnect then
        for icol = 1,self.m_iReelColumnNum do
            for irow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[irow][icol]--icol
                if self:isSymbolStart(symbolType) then
                    self.m_flyList[#self.m_flyList+1] = {irow,icol}
                end
            end
        end
    else
        local countsList = self.m_runSpinResultData.p_selfMakeData.classCounts
        local countsTotalList = self.m_runSpinResultData.p_selfMakeData.classTotalCounts
        for i=1,#countsList do
            if countsTotalList[i] > 0 then
                local barname =  "TopBar"..self.jackpotMappingList[i]
                self[barname]:showSpinTime(countsList[i],countsTotalList[i])
                if countsList[i] > 0 then
                    self[barname]:changeState(0,function()
                        self[barname]:changeState(1)
                    end)
                else
                    self[barname]:changeState(6,function()
                        self[barname]:changeState(7)
                    end)
                end
            end
        end
    end

    if #self.m_flyList > 0 then
        table.sort(self.m_flyList, function(a, b)
            if a[2] == b[2] then
                return a[1] > b[1]
            end
            return a[2] < b[2]
        end)
    end

    -- 整合触发classic的bonus集合 后面做动画用
    self:getAllBonusByClassic()

    local flyEndFun = function()
        -- 播放 respinbonus buling 动画

        local isCalled = false
        local random = math.random(1,2)
        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_bonusTrigger" .. random .. ".mp3")

        for icol = 1,self.m_iReelColumnNum do
            for irow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[irow][icol]
                if self:isSymbolStart(symbolType) then
                    local node = self:getFixSymbol(icol, irow, SYMBOL_NODE_TAG)
                    if isCalled  then
                        node:runAnim("actionframe",false,function(  )
                            node:runAnim("idleframe",true)
                        end)
                    else
                        isCalled = true
                        node:runAnim("actionframe",false,function(  )
                            node:runAnim("idleframe",true)
                            performWithDelay(self,function()
                                self:playClassicPayTableAniStart()
                            end,0.6)
                            self:playClassicAniStart(nil, true)
                        end)
                    end

                end
            end
        end

        if self.m_outLines then
        self.m_outLines = false
            
            performWithDelay(self,function()
                self:playClassicPayTableAniStart()
            end,0.6)
            self:playClassicAniStart(nil, true)

        end
    end
    if #self.m_flyList > 0 then
        self.m_ColList = {}

        --清空底部金币
        self.m_bottomUI:checkClearWinLabel()

        self:startFly(function()
            flyEndFun()
        end)
    else
        flyEndFun()
    end

end

-- 获得第一个classic的bonus 是第几列
function CodeGameScreenVegasLifeMachine:getClassicBonusCol( )
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    for i=1,#selfMakeData.classCounts do
        if selfMakeData.classCounts[i] > 0 then
            return i
        end
    end
end

-- 播放classic的出现paytable 动画
function CodeGameScreenVegasLifeMachine:playClassicPayTableAniStart( )
    self.m_jackPorBar:runCsbAction("over",false) 
    self.m_jackpotLock:runCsbAction("over",false)
    local bonusCol = self:getClassicBonusCol()
    for i=1,5 do
        self.m_classicPayTable:findChild("VegasLife_paytable0"..i):setVisible(false)
    end
    self.m_classicPayTable:findChild("VegasLife_paytable0"..bonusCol):setVisible(true)

    performWithDelay(self,function(  )
        self.m_classicPayTable:setVisible(true)
        self.m_classicPayTable:runCsbAction("start",false,function()
            self.m_classicPayTable:runCsbAction("idle",true)
            
        end) 
        self.m_baseIdleGuang3:setVisible(false)
    end,8/60)
    
end

-- 播放classic的消失paytable 动画
function CodeGameScreenVegasLifeMachine:playClassicPayTableAniOver( )
    self.m_classicPayTable:runCsbAction("over",false) 
     
    performWithDelay(self,function(  )
        self.m_jackPorBar:runCsbAction("start",false) 
        self.m_jackpotLock:runCsbAction("start",false)
        self.m_baseIdleGuang3:setVisible(true)
    end,8/60)
end

-- 播放classic的切换paytable 动画
function CodeGameScreenVegasLifeMachine:playClassicPayTableAniSwitch(_col)
    self.m_classicPayTable:runCsbAction("switch",false) 
    performWithDelay(self,function(  )
        for i=1,5 do
            self.m_classicPayTable:findChild("VegasLife_paytable0"..i):setVisible(false)
        end
        self.m_classicPayTable:findChild("VegasLife_paytable0".._col):setVisible(true)
    end,15/60)
end

--classic动画流程
function CodeGameScreenVegasLifeMachine:playClassicAniStart(winCount, isFirst)
    if self.m_bonusPlayNum >= #self.m_bonusLeftPos then
        performWithDelay(self,function()
            self:playClassicPayTableAniOver()
        end,1)
        self:classicSlotOverView(winCount)
        return
    end
    local data = {}
    data.parent = self
    data.betlevel = self:getBetLevel()
    data.parentResultData = self.m_runSpinResultData
    data.effectData = nil
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    data.height = uiH + uiBH
    data.func = function(_winCount, _showCol)
        self:playBaseClassicAniOver(function(  )
            self:initJackpotBarState(_showCol, true)
        end,function()
            self:playClassicAniStart(_winCount)
        end, _showCol)
    end

    self.m_IsInClassic = true
    local delayTime = 0.05
    if isFirst then
        delayTime = 0.3
    end
    performWithDelay(self,function()
        self.m_bonusPlayNum = self.m_bonusPlayNum + 1
        local bonusPos = self.m_bonusLeftPos[self.m_bonusPlayNum]
        data.col = bonusPos.p_cloumnIndex
        self.m_classicMachine = util_createView("GameScreenVegasLife.GameScreenVegasLifeClassicSlots",data)
        self:findChild("ClassicNode"):addChild(self.m_classicMachine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)--GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1  classicNode
        self.m_classicMachine:setVisible(false)

        performWithDelay(self,function()
            self:playBaseClassicStart(function()
                self:initJackpotBarState(bonusPos.p_cloumnIndex, false, isFirst)
                self:createClassicMachine(isFirst)
            end, bonusPos.p_cloumnIndex)
        end,delayTime)
    end,delayTime)
end

-- 检查bonus剩余数量 是否是最后一个
function CodeGameScreenVegasLifeMachine:cheakIsJackPotBonus( )
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    for i=1,#selfMakeData.classCounts do
        if selfMakeData.classCounts[i] > 0 then
            return false
        end
    end
    return true
end
--更新状态
function CodeGameScreenVegasLifeMachine:initJackpotBarState(_col, _isEnd, _isFirst)
    local newColNum = {5,4,3,2,1}--顶部的jackpot从大到小
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local barname =  "TopBar"..newColNum[_col]
    if self[barname] then
        if _isEnd then 
            if selfMakeData.classCounts[_col] <= 0 then
                self[barname]:changeState(6,function()
                    
                    if self:cheakIsJackPotBonus( ) then
                        for i=1,5 do
                            local barname1 =  "TopBar"..self.jackpotMappingList[i]
                            self[barname1]:showSpinTime(0,0)
                            self[barname1]:changeState(-1,function()
                                self:classicOverResetView()
                            end)
                        end
                    else
                        self[barname]:changeState(7)
                    end
                end)
                self[barname]:showSpinTime(selfMakeData.classCounts[_col], selfMakeData.classTotalCounts[_col])
            end
        else
            if selfMakeData.classCounts[_col] > 0 then
                if self.m_showCol ~= _col then
                    self[barname]:changeState(3,function()
                        self[barname]:changeState(4)
                        self.m_showCol = _col
                    end)
                    if not _isFirst then
                        performWithDelay(self,function()
                            self:playClassicPayTableAniSwitch(_col)
                        end,0.6)
                    end
                    
                end
                self[barname]:showSpinTime(selfMakeData.classCounts[_col], selfMakeData.classTotalCounts[_col])
            end
        end
    end
end

--bonus从小变大
function CodeGameScreenVegasLifeMachine:playBaseClassicStart( _func , _showPlayCol)
    local symbolType = self.SYMBOL_START_x1
    local iRow = 1
    local iCol = 1
    
    local data = self.m_bonusLeftPos[self.m_bonusPlayNum]
    if data then
        symbolType = data.symbolType
        iRow = data.p_rowIndex
        iCol = data.p_cloumnIndex
    end
    
    local tarSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    tarSp:setVisible(false)

    local startPos = util_convertToNodeSpace(tarSp,self.m_classicMachine:getParent())
    local endPos = cc.p(0,0)

    self.m_classicMachine:runCsbAction("idle2")
    self.m_classicMachine:setScale(0.2)

    self.m_classicMachine:setVisible(true)
    self.m_classicMachine:setPosition(startPos)

    local moveTime = 20/60
    
    gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_classic_open_start.mp3")
    self:playMoveToActionSineIn(self.m_classicMachine,moveTime,endPos,function()
        self.m_classicMachine:runCsbAction("idle1")
    end)

    if _func then
        _func()
    end
    performWithDelay(self,function()
        self:showOrHideReel(false)
    end,32/60)
    

end

--bonus从大变小
function CodeGameScreenVegasLifeMachine:playBaseClassicAniOver(_func1, _func2, _showPlayCol)

    local symbolType = self.SYMBOL_START_x1
    local iRow = 1
    local iCol = 1
    local data = self.m_bonusLeftPos[self.m_bonusPlayNum]
    if data then
        symbolType = data.symbolType
        iRow = data.p_rowIndex
        iCol = data.p_cloumnIndex
    end
    
    local tarSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    tarSp:setVisible(true)
    
    local winView = self:createClassicWinView(tarSp )

    local endPos = util_convertToNodeSpace(winView:findChild("Node_2"),self.m_classicMachine:getParent())
    
    performWithDelay(self,function()
        local moveTime = 20/60
        -- 最后一个classic时候 弹板提前
        if self.m_bonusPlayNum >= #self.m_bonusLeftPos then
            if _func2 then
                _func2()
            end
        end
        
        self.m_classicMachine:runCsbAction("idle2")

        gLobalSoundManager:playSound("VegasLifeSounds/VegasLife_classic_open_start.mp3")
        self:playMoveToActionSineOut(self.m_classicMachine, moveTime, endPos, function(  )
            if _func1 then
                _func1()
            end

            if self.m_bonusPlayNum < #self.m_bonusLeftPos then
                if _func2 then
                    _func2()
                end
            end

            -- 移动完成 删除
            if self.m_bonusPlayNum < #self.m_bonusLeftPos then
                self.m_classicMachine:removeFromParent()
                self.m_classicMachine = nil
            else
                self.m_classicMachine:setVisible(false)
            end
            
        end)

    end,20/60)

    performWithDelay(self,function(  )
        self:showOrHideReel(true)
        
        self.m_classicMachine:findChild("zhezhao_0"):setVisible(false)
    end,2/60)
    
end

function CodeGameScreenVegasLifeMachine:createClassicWinView(_tarSp )
    local winView = nil
    
    local Node_ClassicWin = _tarSp:getCcbProperty("Node_ClassicWin")
    if Node_ClassicWin then
        winView = util_getChildByName(Node_ClassicWin, "classicWinView")

        if not winView then
            winView = util_createView("CodeVegasLifeSrc.VegasLifeClassicWinView",self.m_classicMachine)
            winView:setName("classicWinView")
            Node_ClassicWin:addChild(winView)
        end
    end

    return winView 
end

function CodeGameScreenVegasLifeMachine:callSpinBtn( )

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1
    -- freespin时不做钱的计算
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        self:removeSoundHandler( )
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( )
        end)
    end

    BaseMachine.callSpinBtn(self)
end

function CodeGameScreenVegasLifeMachine:playEffectNotifyNextSpinCall( )
    self:removeSoundHandler( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if (self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE)  then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        if self.m_isFirstFreeSpin then
            delayTime = self:getWinCoinTime()
        end
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            -- self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end



function CodeGameScreenVegasLifeMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        -- 触发classic玩法 断线之后 初始化棋盘使用服务器数据p_reSpinCurCount
        if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
            self:initHasFeature()
        else
            self:initNoneFeature()
        end
    else
        self:initHasFeature()
    end

    self:restLeveldData()
    
    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects( )
        self:playGameEffect()
    end
end


--[[
    @desc: 断线重连时处理 是否有feature
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenVegasLifeMachine:checkHasRespinFeature( )
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then

        for i=1,#self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or  self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)

    if  self:getCurrSpinMode() == RESPIN_MODE  then
        hasFeature = true
    end

    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        hasFeature = true
    end

    return hasFeature
end

--classic结束弹板
function CodeGameScreenVegasLifeMachine:classicSlotOverView(coinsNum)
    local coins = coinsNum or 0
    self:checkFeatureOverTriggerBigWin(coinsNum , GameEffect.EFFECT_RESPIN)

    local view = util_createView("CodeVegasLifeSrc/VegasLifeClassicOverView")
    gLobalViewManager:showUI(view)
    self:specialAdaptive(view)

    view:initViewData(coins,function()
        if not self.m_bProduceSlots_InFreeSpin  then
            local curTotalCoin = globalData.userRunData.coinNum
            globalData.coinsSoundType = 1
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,curTotalCoin)
        end

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:triggerReSpinOverCallFun(0)

        if self.m_bonusPlayNum >= #self.m_bonusLeftPos then
            self.m_classicMachine:removeFromParent()
            self.m_classicMachine = nil
        end

        self.m_bonusLeftPos = {}
        self.m_bonusPlayNum = 0
        self.m_IsInClassic = 0
        self.m_showCol = 0
        self.m_bProduceSlots_InClassic = false

    end)
end

function CodeGameScreenVegasLifeMachine:triggerReSpinOverCallFun(score)
    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    performWithDelay(self,function()
        performWithDelay(self,function()
            self:removeSoundHandler( )
            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( )
            end)
            performWithDelay(self,function()
                self.m_IsInClassic = false
                
                if self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
                    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins
                    if fsWinCoins then
                        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoins))
                    end
                    
                    self:changeBgState(1)

                else
                    self:changeBgState(0)
                end

                self:updateBaseConfig()
                
                self:updateMachineData()
                self:initSymbolCCbNames()
                self:initMachineData()

                self:MachineRule_checkTriggerFeatures()

            end,0.05)
        end,0.05)

        performWithDelay(self,function()
            performWithDelay(self,function()
                self:playGameEffect()
            end,0.1)
            util_nextFrameFunc(function()
                self:resetMusicBg()
            end)
        end,0.1)
            
    end,0.1)

    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0
    if
        self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or
            self.m_bProduceSlots_InFreeSpin
     then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenVegasLifeMachine:playEffectNotifyChangeSpinStatus( )

    CodeGameScreenVegasLifeMachine.super.playEffectNotifyChangeSpinStatus(self)
    self:removeSoundHandler( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)
end

function CodeGameScreenVegasLifeMachine:initMachineData()

    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName.."_Datas"

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    -- 配置全局信息，供外部使用
    globalData.slotRunData.levelGetAnimNodeCallFun = function(symbolType,ccbName)
                                                      return self:getAnimNodeFromPool(symbolType,ccbName)
                                                   end
    globalData.slotRunData.levelPushAnimNodeCallFun = function(animNode,symbolType)
                                                        self:pushAnimNodeToPool(animNode,symbolType)
                                                    end

    self:checkHasBigSymbol()
end

function CodeGameScreenVegasLifeMachine:classicSlotStartView(func)
    local view = self:showDialog("Classical_Start", nil,function()
        if func then
            func()
        end
    end)
end

function CodeGameScreenVegasLifeMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
            
    local validLineSymNum = self.m_validLineSymNum

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        validLineSymNum = 2
    end

    if iconsPos ~= nil and #iconsPos >= validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果

        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

function CodeGameScreenVegasLifeMachine:initGameStatusData(gameData)
    CodeGameScreenVegasLifeMachine.super.initGameStatusData(self,gameData)
    self.m_avgBet = 0
    if gameData then
        if gameData.spin  then
            if  gameData.spin.freespin then
                if gameData.spin.freespin.extra then
                    if gameData.spin.freespin.extra.avgBet then
                        self.m_avgBet = gameData.spin.freespin.extra.avgBet
                    end
                end
                
            end
        end
    end
 
end

function CodeGameScreenVegasLifeMachine:BaseMania_updateJackpotScore(index,totalBet)
    if not totalBet then
        totalBet=globalData.slotRunData:getCurTotalBet()
    end

    if self.m_IsBonusCollectFull and self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end
    
    release_print("报错断点看看 p_id: " .. globalData.slotRunData.machineData.p_id)
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index],true,totalBet)

    return totalScore
    
end

-- 触发classic玩法之后 整合所有的bonus集合
function CodeGameScreenVegasLifeMachine:getAllBonusByClassic( )
    local selfdata = self.m_runSpinResultData.p_reels or {}

    for row, rowData in ipairs(selfdata) do
        for col, symbol in ipairs(rowData) do
            if self:isSymbolStart(symbol) then
                table.insert(self.m_bonusLeftPos, {
                    symbolType = tonumber(symbol),
                    p_cloumnIndex = col,
                    p_rowIndex = row ~= 2 and (row == 1 and 3 or 1) or row,
                })
            end
        end
    end
    table.sort(
        self.m_bonusLeftPos,
        function(a, b)
            --列
            if(a.p_cloumnIndex ~= b.p_cloumnIndex)then
                return a.p_cloumnIndex < b.p_cloumnIndex
            --行
            else
                return a.p_rowIndex > b.p_rowIndex
            end
        end
    )
end

--滚动之前删除小块上方的自定义图标
function CodeGameScreenVegasLifeMachine:removeClassicWinView(_parentNode )

    if _parentNode and _parentNode.p_symbolType then
        if self:isSymbolStart(_parentNode.p_symbolType) then
            local Node_ClassicWin = _parentNode:getCcbProperty("Node_ClassicWin")
            if Node_ClassicWin then
                Node_ClassicWin:removeAllChildren()
            end
        end
    end
    

end
function CodeGameScreenVegasLifeMachine:updateReelGridNode(_symbolNode)

    local symbolType = _symbolNode.p_symbolType
    if symbolType then

        self:removeClassicWinView(_symbolNode )
    
    end

end

function CodeGameScreenVegasLifeMachine:pushAnimNodeToPool(animNode, symbolType)
    self:removeClassicWinView(animNode )
    CodeGameScreenVegasLifeMachine.super.pushAnimNodeToPool(self,animNode, symbolType)
   
end
function CodeGameScreenVegasLifeMachine:getAnimNodeFromPool(symbolType, ccbName)

    local node = CodeGameScreenVegasLifeMachine.super.getAnimNodeFromPool(self,symbolType, ccbName)
   
    self:removeClassicWinView(node )

    return node
end

-- 正弦曲线移动
function CodeGameScreenVegasLifeMachine:playMoveToActionSineIn(node, time, pos, callback)
    local actionList = {}
    local spawn = cc.Spawn:create({
        cc.EaseSineIn:create(cc.MoveTo:create(time, pos)),
        cc.EaseSineIn:create(cc.ScaleTo:create(time, 1))
    })

    actionList[#actionList + 1] = spawn
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end

-- 余弦曲线移动
function CodeGameScreenVegasLifeMachine:playMoveToActionSineOut(node, time, pos, callback)
    local actionList = {}
    local spawn = cc.Spawn:create({
        cc.EaseSineOut:create(cc.MoveTo:create(time, pos)),
        cc.EaseSineOut:create(cc.ScaleTo:create(time, 0.2)),
    })

    actionList[#actionList + 1] = spawn
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    
    node:runAction(seq)

    performWithDelay(self,function()
        -- 做这个判断 是因为加速15倍的时候 可能node 不存在 ，报错
        if node and node.showViewFadeOut then
            assert(node.showViewFadeOut, "node.showViewFadeOut 存在")
            node:showViewFadeOut(5/60)
        end
    end,15/60)
    
end

-- 显示和隐藏棋盘
function CodeGameScreenVegasLifeMachine:showOrHideReel(isShow)
    self:findChild("root_0"):setVisible(isShow)
end

-- 播放classic的paytable 赢钱提示
function CodeGameScreenVegasLifeMachine:showClassicLineAction(id, isBigWin)
    --总共8个触发底板
    for i=1,8 do
        self.m_classicPayTable:findChild("Glow_"..i):setVisible(false)
    end
    self.m_classicPayTable:findChild("Glow_"..id):setVisible(true)
    if isBigWin then
        self.m_classicPayTable:runCsbAction("actionframe2", true) 
    else
        self.m_classicPayTable:runCsbAction("actionframe", true) 
    end

    -- 不是Jackpot 连线的时候 延时自动消失，jackpot连线的时候 弹板关闭的时候消失
    if id ~= 1 then
        local delayTime = 100/60
        if isBigWin then
            delayTime = 184/60
        end
        performWithDelay(self,function()
            self.m_classicPayTable:runCsbAction("idle") 
        end,delayTime)
    end
end

-- classic的触发ackpot 时候 显示
function CodeGameScreenVegasLifeMachine:showClassicJackPotAction(_col)
    local mapList = {5,4,3,2,1}
    local barname =  "TopBar"..mapList[_col]
    self[barname]:showJacpPotYuGao()
end

-- classic的触发ackpot 时候 隐藏
function CodeGameScreenVegasLifeMachine:unShowClassicJackPotAction(_col)
    local mapList = {5,4,3,2,1}
    local barname =  "TopBar"..mapList[_col]
    self[barname]:unShowJacpPotYuGao()
end

function CodeGameScreenVegasLifeMachine:setSlotNodeEffectParent(slotNode)
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

    self.m_clipParent:addChild(slotNode,self:getSlotNodeEffectZOrder(slotNode))
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runAnim(slotNode:getLineAnimName(),false)
    end
    return slotNode
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

--设置bonus scatter 信息
function CodeGameScreenVegasLifeMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        nextReelLong = false
    end
    
    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenVegasLifeMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
        if selfMakeData and selfMakeData.freeSpinCount and selfMakeData.freeSpinCount == 10 then
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(1, parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        end
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end

function CodeGameScreenVegasLifeMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        if self.m_isFirstFreeSpin then
            delayTime = delayTime + 0.5
        end
        performWithDelay(self,function()
            self:requestSpinResult()
            self.m_isFirstFreeSpin = false
        end,delayTime)
    else
        self:requestSpinResult() 
    end

    self.m_isWaitingNetworkData = true
    
    self:setGameSpinStage( WAITING_DATA )
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Spin,false,true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Stop,false,true})
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenVegasLifeMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeVegasLifeSrc.VegasLifeBaseDialog")
    
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(view)
    self:specialAdaptive(view)
    return view
end
return CodeGameScreenVegasLifeMachine