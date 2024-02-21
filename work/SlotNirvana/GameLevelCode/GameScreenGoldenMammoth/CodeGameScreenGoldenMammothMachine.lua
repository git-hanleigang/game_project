---
-- island li
-- 2019年1月26日
-- CodeGameScreenGoldenMammothMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenGoldenMammothMachine = class("CodeGameScreenGoldenMammothMachine", BaseSlotoManiaMachine)

CodeGameScreenGoldenMammothMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenGoldenMammothMachine.SYMBOL_NORMAL_9 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1   -- 自定义的小块类型
CodeGameScreenGoldenMammothMachine.SYMBOL_NORMAL_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2 
CodeGameScreenGoldenMammothMachine.SYMBOL_SPECAIL_MAMMON = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 

CodeGameScreenGoldenMammothMachine.EFFECT_GOLDEN_MAMMOTH = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenGoldenMammothMachine.EFFECT_CHANGE_SCALE = GameEffect.EFFECT_SELF_EFFECT - 2

CodeGameScreenGoldenMammothMachine.m_vecMammoths = nil
CodeGameScreenGoldenMammothMachine.m_bIsReconnectDiamond = nil
CodeGameScreenGoldenMammothMachine.m_iChangeSymbolID = nil
CodeGameScreenGoldenMammothMachine.m_fMammothScale = nil
CodeGameScreenGoldenMammothMachine.m_bIsChangeScale = nil

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

local FREE_SPIN_LEVEL =
{
    NORMAL = 0,
    SUPER = 1
}

-- 构造函数
function CodeGameScreenGoldenMammothMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    --连线最大的列数
    self.m_maxLineColIndex = 0

    self.m_freeSpinOverDelayTime = 5
    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenGoldenMammothMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    self.m_scatterBulingSoundArry = {}
    for i = 1, self.m_iReelColumnNum do
        local soundPath = "GoldenMammothSounds/sound_goldenmammoth_scatter_"..i..".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end  

function CodeGameScreenGoldenMammothMachine:getReelHeight()
    return 593
end

function CodeGameScreenGoldenMammothMachine:getReelWidth()
    return 1148
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGoldenMammothMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GoldenMammoth"  
end

function CodeGameScreenGoldenMammothMachine:getNetWorkModuleName()
    return "GoldenMammothV2"
end


function CodeGameScreenGoldenMammothMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_GoldenMammothView = util_createView("CodeGoldenMammothSrc.GoldenMammothView")
    -- self:findChild("xxxx"):addChild(self.m_GoldenMammothView)
   self.m_topBar = util_createView("CodeGoldenMammothSrc.GoldenMammothTopBar")
   self:findChild("topbar"):addChild(self.m_topBar)
   self.m_topBar:setVisible(false)
 
   self.m_leftBar = util_createView("CodeGoldenMammothSrc.GoldenMammothLeftBar")
   self:findChild("leftbar"):addChild(self.m_leftBar)
   self:findChild("leftbar"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
   self.m_leftBar:setVisible(false)

   self.m_progress = util_createView("CodeGoldenMammothSrc.GoldenMammothProgress")
   self:findChild("progressbar"):addChild(self.m_progress)
   self:findChild("progressbar"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    if display.width < 1270 then
        -- self.m_bIsChangeScale = true
        self.m_fMammothScale = display.width / 1270
    else
        self.m_bIsChangeScale = false
        self.m_fMammothScale = self.m_machineRootScale
    end

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3  then
            soundIndex = 3
            soundTime = 3
        end
        local soundName = "GoldenMammothSounds/sound_goldenmammoth_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY())
end

function CodeGameScreenGoldenMammothMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_enter_game.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenGoldenMammothMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinTriggerCnt = selfdata.freeSpinTriggerCnt or self.m_currFsCount or 0

    if freeSpinTriggerCnt > 0 then
        self.m_progress:initFsIconStatus(freeSpinTriggerCnt)
    end
    if self.m_bProduceSlots_InFreeSpin ~= true then
        performWithDelay(self, function()
            self:showSuperTip()
        end, 0.3)
    end
end

function CodeGameScreenGoldenMammothMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
end

function CodeGameScreenGoldenMammothMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function CodeGameScreenGoldenMammothMachine:scaleMainLayer()
    BaseSlotoManiaMachine.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.85
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.95 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end

  
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGoldenMammothMachine:MachineRule_GetSelfCCBName(symbolType)

    if self.SYMBOL_NORMAL_9 ==  symbolType then
        return "Socre_GoldenMammoth_10"
    elseif self.SYMBOL_NORMAL_10 == symbolType then
        return "Socre_GoldenMammoth_11"
    elseif self.SYMBOL_SPECAIL_MAMMON == symbolType then
        return "Socre_GoldenMammoth_H"
    end
    
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGoldenMammothMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_NORMAL_9,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_NORMAL_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECAIL_MAMMON,count =  2}

    return loadNode
end

-- 重写 getSlotNodeWithPosAndType 方法
function CodeGameScreenGoldenMammothMachine:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)

    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType,iRow,iCol,isLastSymbol)
    if self.m_runSpinResultData.p_selfMakeData ~= nil and reelNode.m_isLastSymbol == true and self.m_bIsReconnectDiamond ~= true then
        local index = self:getPosReelIdx(reelNode.p_rowIndex, reelNode.p_cloumnIndex)
        if self.m_runSpinResultData.p_fsExtraData ~= nil and self.m_runSpinResultData.p_fsExtraData.gold ~= nil
         and self.m_runSpinResultData.p_fsExtraData.gold.goldSignalPosition ~= nil then
            local position = self.m_runSpinResultData.p_fsExtraData.gold.goldSignalPosition
            if position ~= nil then
                for i = 1, #position, 1 do
                    if index == position[i] then
                        local mammoth = self:getSlotNodeBySymbolType(self.SYMBOL_SPECAIL_MAMMON)
                        mammoth:runAnim("idleframe")
                        mammoth:setPosition(0,0)
                        mammoth:setName("mammoth"..index)
                        -- mammoth:setScale(self.m_machineRootScale) 
                        reelNode:addChild(mammoth, 1000000)
                        if self.m_vecMammoths == nil then
                            self.m_vecMammoths = {}
                        end
                        self.m_vecMammoths[#self.m_vecMammoths + 1] = mammoth
                        break
                    end
                end

            end
        end
    end

    return reelNode
end

function CodeGameScreenGoldenMammothMachine:setSpecialNodeScore(sender,parma)
    local symbolNode = parma[1]
    if parma[2] == nil then
        
    else
        symbolNode:setLineAnimName("actionframe"..parma[2])
    end
end
----------------------------- 玩法处理 -----------------------------------

--设置长滚信息
function CodeGameScreenGoldenMammothMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false
     
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 15) 
                self:setLastReelSymbolList()    
            end
        end

        local runLen = reelRunData:getReelRunLen()
  

        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

        if self.m_bProduceSlots_InFreeSpin == true then
            local index = self.m_iReelColumnNum - 1
            if col == index and bRunLong then
                self.m_reelRunInfo[col]:setNextReelLongRun(false)
                bRunLong = false
                addLens = true
            end
        end

    end --end  for col=1,iColumn do
end

function CodeGameScreenGoldenMammothMachine:requestSpinResult()
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
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = 1}
    -- local operaId = 
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

-- 断线重连 
function CodeGameScreenGoldenMammothMachine:MachineRule_initGame(  )

    self.m_bIsReconnectDiamond = true

    local selfdate = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdate.freeSpinType and selfdate.freeSpinType == 1 and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        self.m_bottomUI:showAverageBet()
    end

end


function CodeGameScreenGoldenMammothMachine:spinResultCallFun(param)
    if self.m_bIsReconnectDiamond == true then
        self.m_bIsReconnectDiamond = false
    end
    BaseSlotoManiaMachine.spinResultCallFun(self,param)
end


function CodeGameScreenGoldenMammothMachine:MachineRule_reelDown(slotParent, parentData)
    local speedActionTable, timeDown = BaseSlotoManiaMachine.MachineRule_reelDown(self, slotParent, parentData)
    return speedActionTable, timeDown
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenGoldenMammothMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"change_freespin",false , function(  )
        -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"freespin",true})
    end})
    self.m_progress:hideProgress()
    self.m_leftBar:setVisible(true)
    self.m_topBar:setVisible(true)
    local count = self.m_runSpinResultData.p_fsExtraData.gold.collectedCount
    local symbol = self.m_runSpinResultData.p_fsExtraData.gold.waitReplaceSignal
    self.m_topBar:initCountAndSymbol(count, symbol)
    self.m_topBar:normal2Freespin()
    
    self.m_leftBar:updateCountNum(count) 
    count = self.m_runSpinResultData.p_fsExtraData.gold.collectCount - self.m_runSpinResultData.p_fsExtraData.gold.collectedCount 
    self.m_topBar:updateCountAndSymbol(count, symbol)
    self.m_leftBar:showLeftBar()
    local index = symbol - 1
    if count <= 0 then
        index = symbol
    end
    self.m_fsReelDataIndex = index
    self.m_iChangeSymbolID = index
    self.m_ScatterShowCol = {2, 3, 4}
    -- util_csbScale(self.m_machineNode, self.m_fMammothScale)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenGoldenMammothMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_normal")
    self.m_topBar:freespin2Normal()
    self.m_leftBar:hideLeftBar()
    -- util_csbScale(self.m_machineNode, self.m_machineRootScale)
    self.m_ScatterShowCol = nil
    if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
        self.m_progress:resetFsIconStatus()
    end
    self.m_progress:showProgress()
end
---------------------------------------------------------------------------


--返回本组下落音效和是否触发长滚效果
function CodeGameScreenGoldenMammothMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    if self.m_bProduceSlots_InFreeSpin == true then
        
        if nodeNum >= 1 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
        
    else
        if col == showColTemp[#showColTemp - 1] then
            if nodeNum <= 1 then
                return runStatus.NORUN, false
            elseif nodeNum == 2 then
                return runStatus.DUANG, true
            else
                return runStatus.DUANG, false
            end
        elseif col == showColTemp[#showColTemp] then
            if nodeNum <= 2  then
                return runStatus.NORUN, false
            else
                return runStatus.DUANG, false
            end
        else
            if nodeNum == 2 then
                return runStatus.DUANG, true
            else
                return runStatus.DUANG, false
            end
        end
    end
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenGoldenMammothMachine:showFreeSpinStart(num,func)
    local index = self.m_runSpinResultData.p_selfMakeData.freeSpinTriggerCnt
    self.m_progress:triggerIconAnim(index, function()
        local ownerlist={}
        ownerlist["m_lb_num"]=num
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
        local normal = view:findChild("normal")
        local super = view:findChild("super")
        if self.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
            normal:setVisible(false)
            self.m_bottomUI:showAverageBet()
        else
            super:setVisible(false)
        end
    end)
end

function CodeGameScreenGoldenMammothMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_freespin_start.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinNewCount == 1 then
                self:showDialog("FreeSpinAdd", nil, function()

                    self.m_baseFreeSpinBar:changeFreeSpinByCount()

                    performWithDelay(self, function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end, 1)
                end,BaseDialog.AUTO_TYPE_ONLY)
            else
                self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                    -- gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_click_btn.mp3")
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,true)
            end
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_click_btn.mp3")
                local delayTime = 0
                if self.m_bIsChangeScale == true then
                    delayTime = 0.5
                    self.m_machineNode:getChildByName("root"):runAction(cc.ScaleTo:create(delayTime, self.m_fMammothScale))
                end
                performWithDelay(self, function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, delayTime)
                       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function()
        showFSView()    
    end,0.5)

    

end

-- function CodeGameScreenGoldenMammothMachine:showEffect_FreeSpinOver()
--     if #self.m_reelResultLines ~= 0 then
--        performWithDelay(self, function(  )
--             BaseMachineGameEffect.showEffect_FreeSpinOver(self)
--        end, 2)
--     else
--         performWithDelay(self, function(  )
--             BaseMachineGameEffect.showEffect_FreeSpinOver(self)
--        end, 1.5)
--     end

--     return true
-- end

function CodeGameScreenGoldenMammothMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_freespin_over.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,60)
    local num      = self.m_runSpinResultData.p_freeSpinsTotalCount
    local view = self:showFreeSpinOver(
        strCoins, 
        num,
        function()
            gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_click_btn.mp3")
            self.m_bottomUI:hideAverageBet()
            self:triggerFreeSpinOverCallFun()
        end
    )
    if self.m_bIsChangeScale == true then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        table.insert( self.m_gameEffects, 1, selfEffect )
        selfEffect.p_selfEffectType = self.EFFECT_CHANGE_SCALE
    end
    
    local bSuper = 1 == self.m_runSpinResultData.p_selfMakeData.freeSpinType
    local labNum   = bSuper and view:findChild("m_lb_num2") or view:findChild("m_lb_num1")
    local labCoins = view:findChild("m_lb_coins")
    local normal = view:findChild("Node_normal")
    local super  = view:findChild("Node_super")
    normal:setVisible(not bSuper)
    super:setVisible(bSuper)
    labNum:setString(tostring(num)) 
    view:updateLabelSize({label = labNum,  sx = 0.52 ,sy = 0.52}, 93)
    view:updateLabelSize({label = labCoins,sx = 0.72 ,sy = 0.72}, 862)
end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGoldenMammothMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    self.m_progress:hideTip()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenGoldenMammothMachine:removeOneMammoth( posIndex )
    
    
    if self.m_vecMammoths then
        
        for index = #self.m_vecMammoths , 1 , -1 do
            
            local childName = self.m_vecMammoths[index]:getName()
            local removeName = "mammoth" .. posIndex
            if childName == removeName  then
                table.remove(self.m_vecMammoths,index)
                break
            end
        end

    end
end

function CodeGameScreenGoldenMammothMachine:slotReelDown()
    
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        local children = slotParent:getChildren()
        for i = 1, #children, 1 do
            local child = children[i]
            if child.p_symbolType and (child.p_rowIndex <= self.m_iReelRowNum and child.p_rowIndex > 0) then

                local index = self:getPosReelIdx(child.p_rowIndex, child.p_cloumnIndex)
                local mammoth = child:getChildByName("mammoth"..index)
                if mammoth ~= nil and child.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then

                    self:removeOneMammoth( index )

                    mammoth:removeFromParent(true)
                    mammoth = nil
                end
                if mammoth ~= nil then
                    local pos = mammoth:getParent():convertToWorldSpace(cc.p(mammoth:getPositionX(), mammoth:getPositionY()))
                    pos = self.m_clipParent:convertToNodeSpace(pos)
                    mammoth:retain()
                    mammoth:removeFromParent(true)
                    self.m_clipParent:addChild(mammoth, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                    mammoth:setPosition(pos)
                    mammoth:release()
                end
            end
        end
    end

    --连线最大的列数
    self.m_maxLineColIndex = 0
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i,lineData in ipairs(winLines) do
            for index,posIndex in ipairs(lineData.p_iconPos) do
                local pos = self:getRowAndColByPos(posIndex)
                local iCol,iRow = pos.iY,pos.iX
                if iCol > self.m_maxLineColIndex then
                    self.m_maxLineColIndex = iCol
                end
            end
        end
    end
    
    BaseSlotoManiaMachine.slotReelDown(self)

   
end

function CodeGameScreenGoldenMammothMachine:playEffectNotifyNextSpinCall( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self) 

end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenGoldenMammothMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenGoldenMammothMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGoldenMammothMachine:addSelfEffect()

    if self.m_runSpinResultData.p_fsExtraData ~= nil and self.m_runSpinResultData.p_fsExtraData.gold ~= nil
    and self.m_runSpinResultData.p_fsExtraData.gold.goldSignalPosition ~= nil then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_GOLDEN_MAMMOTH -- 动画类型
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGoldenMammothMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_GOLDEN_MAMMOTH then

        
        -- effectData.p_isPlay = true
        -- self:playGameEffect()
        self:playGoldenMammothEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_CHANGE_SCALE then
        
        local seq = cc.Sequence:create(cc.DelayTime:create(0.67), cc.ScaleTo:create(0.5, self.m_machineRootScale), cc.CallFunc:create(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        ))
        self.m_machineNode:getChildByName("root"):runAction(seq)
    end

	return true
end

function CodeGameScreenGoldenMammothMachine:playGoldenMammothEffect(effectData)
    if self.m_vecMammoths == nil then
        return
    end
    gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_collect_mammoth.mp3")
    for i = #self.m_vecMammoths, 1, -1 do
        local mammoth = self.m_vecMammoths[i]
        local isLast = false
        if i == 1 then
            mammoth.m_isLastSymbol = true
            isLast = true
        end

        local worldPos = mammoth:getParent():convertToWorldSpace(cc.p(mammoth:getPositionX(), mammoth:getPositionY()))

        mammoth:runAnim("shouji", false, function()
            if mammoth.m_isLastSymbol == true then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            mammoth:removeFromParent(true)
            -- self:pushSlotNodeToPoolBySymobolType(mammoth.p_symbolType, mammoth)
        end)

        
        table.remove(self.m_vecMammoths, i)
        performWithDelay(self, function ()
            self:drawLine2Mammoth(worldPos, isLast)
        end, 1/3)
    end

    -- if effectData.p_isPlay == false then
    --     effectData.p_isPlay = true
    --     self:playGameEffect()
    -- end
end

function CodeGameScreenGoldenMammothMachine:drawLine2Mammoth(beginPos, isLast)
    local endPos = self.m_leftBar:getParent():convertToWorldSpace(cc.p(self.m_leftBar:getPositionX() + 40, self.m_leftBar:getPositionY()))
    local distance = cc.pGetDistance(beginPos, endPos)
    local scale = distance / 540
    local height = endPos.y - beginPos.y
    local angle = math.deg(math.asin(height / distance ))
    local line, act = util_csbCreate("GoldenMammoth_shouji.csb")
    self:addChild(line, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    line:setPosition(beginPos)
    line:setScaleX(scale)
    if endPos.x > beginPos.x then
        angle = 180 - angle
    end
    line:setRotation(angle)
    util_csbPlayForKey(act, "show", false, function ()
        line:removeFromParent(true)
        if isLast == true then
            local count = self.m_runSpinResultData.p_fsExtraData.gold.collectedCount
            self.m_leftBar:showCountChange(count)
            count = self.m_runSpinResultData.p_fsExtraData.gold.collectCount - self.m_runSpinResultData.p_fsExtraData.gold.collectedCount 
            local symbol = self.m_runSpinResultData.p_fsExtraData.gold.waitReplaceSignal
            performWithDelay(self, function ()
                self.m_topBar:updateCountAndSymbol(count, symbol, true)
            end, 0.5)
            local index = symbol - 1
            if count <= 0 then
                index = symbol
            end
            self.m_fsReelDataIndex = index
            if index ~= self.m_iChangeSymbolID then
                self.m_iChangeSymbolID = index
            end
        end
    end)
end

function CodeGameScreenGoldenMammothMachine:initGameStatusData(gameData)

    self.m_currFsCount = gameData.gameConfig.extra.freeSpinTriggerCnt
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenGoldenMammothMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenGoldenMammothMachine:showSuperTip()
    self.m_progress:showTip()
end

--[[
    显示连线
]]
function CodeGameScreenGoldenMammothMachine:showLineFrame()
    
    CodeGameScreenGoldenMammothMachine.super.showLineFrame(self)
end

--[[
    显示单条连线
]]
function CodeGameScreenGoldenMammothMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    CodeGameScreenGoldenMammothMachine.super.showEachLineSlotNodeLineAnim(self,_frameIndex)
    self:wildMultiAni()
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenGoldenMammothMachine:playInLineNodes()
    CodeGameScreenGoldenMammothMachine.super.playInLineNodes(self)
    self:wildMultiAni()
end

--[[
    wild倍数动画
]]
function CodeGameScreenGoldenMammothMachine:wildMultiAni()

    local function callFunc(multipList,aniName)
        for i,posIndex in ipairs(multipList) do
            local pos = self:getRowAndColByPos(posIndex)
            local iCol,iRow = pos.iY,pos.iX
            local symbol = self:getFixSymbol(iCol,iRow)
            --满线关卡最大参与连线列数+1出现wild时,则该wild必定参与连线
            if symbol and symbol.p_symbolType then
                symbol:runAnim(aniName,true)
            end
        end
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.wild then
        --2倍wild列表
        if selfData.wild["2"] then
            local multipList = selfData.wild["2"]
            callFunc(multipList,"actionframe1")
        end

        --3倍wild列表
        if selfData.wild["3"] then
            local multipList = selfData.wild["3"]
            callFunc(multipList,"actionframe2")
        end
    end
end

return CodeGameScreenGoldenMammothMachine






