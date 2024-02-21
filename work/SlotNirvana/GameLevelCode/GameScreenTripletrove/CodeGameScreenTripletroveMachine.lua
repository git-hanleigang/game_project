---
-- island li
-- 2019年1月26日
-- CodeGameScreenTripletroveMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenTripletroveMachine = class("CodeGameScreenTripletroveMachine", BaseNewReelMachine)

CodeGameScreenTripletroveMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenTripletroveMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_DOOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7         --门
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_JACKPOT1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_JACKPOT2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_JACKPOT3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_JACKPOT4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_JACKPOT5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenTripletroveMachine.SYMBOL_SCORE_JACKPOT6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13

CodeGameScreenTripletroveMachine.OPEN_DOOR_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5        --开门
CodeGameScreenTripletroveMachine.BASE_GOLDCASE_CHANGE_JACKPOT = GameEffect.EFFECT_SELF_EFFECT - 3        --base下，加成
CodeGameScreenTripletroveMachine.GOLD_FREE_JACKPOT_WIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4        --金色free收集


--self.m_fsReelDataIndex    --更改假滚配置的字段
CodeGameScreenTripletroveMachine.FREEINDEX_NOMAL = 0
CodeGameScreenTripletroveMachine.FREEINDEX_ONE = 1
CodeGameScreenTripletroveMachine.FREEINDEX_TWO = 2
CodeGameScreenTripletroveMachine.FREEINDEX_THTRR = 3
CodeGameScreenTripletroveMachine.FREEINDEX_FOUR = 4
CodeGameScreenTripletroveMachine.FREEINDEX_FIVE = 5
CodeGameScreenTripletroveMachine.FREEINDEX_SIX = 6
CodeGameScreenTripletroveMachine.FREEINDEX_SEVEN = 7

local CURRENCY_NUM = {
    ONE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8,
    NINE = 9,
    TEN = 10,
    ZERO = 0
}

-- 构造函数
function CodeGameScreenTripletroveMachine:ctor()
    CodeGameScreenTripletroveMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.tempDoorList = {}
    self.bonusDoorList = {}
    self.m_betNetCollectData = {}         --储存初始化游戏数据时的gameConfig

    --更改freeGame假滚配置的字段
    self.FREEINDEX_BLUE = 0
    self.FREEINDEX_GOLD = 1
    self.FREEINDEX_RED = 2

    self.JackpotWinIndex = 1

    self.blueWordNum = 0
    self.redSpecialBonus = 0

    self.m_betTotalCoins = 0

    self.m_isShowOpenDoor = true

    self.m_baseBonusEffect = nil

    self.openDoorSound = nil
 
    --init
    self:initGame()
end

function CodeGameScreenTripletroveMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTripletroveMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Tripletrove"  
end


function CodeGameScreenTripletroveMachine:initUI()

    --三个颜色箱子
    self.blueCase = util_createView("CodeTripletroveSrc.TripletroveCaseView",1)
    self.goldCase = util_createView("CodeTripletroveSrc.TripletroveCaseView",2)
    self.redCase = util_createView("CodeTripletroveSrc.TripletroveCaseView",3)
    self:findChild("Node_lanxiang"):addChild(self.blueCase)
    self:findChild("Node_jinxiang"):addChild(self.goldCase)
    self:findChild("Node_hongxiang"):addChild(self.redCase)

    --三个颜色的字
    self.blueWord = util_createView("CodeTripletroveSrc.TripletroveFeatureWordView",1)
    self.goldWord = util_createView("CodeTripletroveSrc.TripletroveFeatureWordView",2)
    self.redWord = util_createView("CodeTripletroveSrc.TripletroveFeatureWordView",3)
    self:findChild("Node_lanzi"):addChild(self.blueWord)
    self:findChild("Node_jinzi"):addChild(self.goldWord)
    self:findChild("Node_hongzi"):addChild(self.redWord)

    --jackpotBar
    self.jackpotBar = util_createView("CodeTripletroveSrc.TripletroveJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.jackpotBar)
    self.jackpotBar:initMachine(self)
    self:setJackpotBarPosY()

    --freeSpinBar
    self.m_freeSpinBar = util_createView("CodeTripletroveSrc.TripletroveFreespinBarView")
    self:findChild("Node_freecishu"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(false)

    --spine背景
    local base_spine = self.m_gameBg:findChild("base_spine")
    local free_spine = self.m_gameBg:findChild("free_spine")
    self.baseBg = util_spineCreate("GameScreenTripletroveBg",true,true)
    self.freeBg = util_spineCreate("GameScreenTripletroveBg",true,true)
    base_spine:addChild(self.baseBg)
    free_spine:addChild(self.freeBg)
    
    util_spinePlay(self.baseBg,"base_idle",true)
    util_spinePlay(self.freeBg,"free_idle",true)
    self.m_gameBg:runCsbAction("base_idle")

    --特效层
    self.m_spineTanbanParent = cc.Node:create()
    self:addChild(self.m_spineTanbanParent, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_spineTanbanParent:setPosition(display.center)

    self.jackpotBar:isShowSpot(false)

    self.m_openDoorNode = cc.Node:create()
    self:addChild(self.m_openDoorNode)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
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
            soundIndex = 4
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "TripletroveSounds/music_Tripletrove_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "TripletroveSounds/music_Tripletrove_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName,false,function (  )
            self.m_winSoundsId = nil
        end)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenTripletroveMachine:setJackpotBarPosY( )
    
    local addPosY = 0
    if display.height >= DESIGN_SIZE.height then
        if display.height >= 1370 and display.height < 1530 then
            addPosY = 7 + (display.height - 1370) * 0.3125
        elseif display.height >= 1530 and display.height <= 1660 then
            addPosY = 57 + (display.height - 1530) * 0.4615
        end
    end
    self.jackpotBar:setPositionY(addPosY)
    
    local baoDianPosY = self:findChild("Node_baodian"):getPositionY() + addPosY
    local baoDianPosX = self:findChild("Node_baodian"):getPositionX()
    self:findChild("Node_baodian"):setPosition(cc.p(baoDianPosX,baoDianPosY))
end


function CodeGameScreenTripletroveMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound("TripletroveSounds/music_Tripletrove_enter.mp3")

    end,0.4,self:getModuleName())
end

function CodeGameScreenTripletroveMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    local features = self.m_runSpinResultData.p_features or {}
    if #features and features[2] == 1 then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local kind = fsExtraData.kind or {}
        self.m_freeSpinBar:changeLabForFeature(kind)
    end

    CodeGameScreenTripletroveMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins = totalBet  
    self:changebetUpDataCollect(totalBet)
end

function CodeGameScreenTripletroveMachine:addObservers()
    CodeGameScreenTripletroveMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)

        local totalBet = globalData.slotRunData:getCurTotalBet( )

        -- 不同的bet切换才刷新框
        if self.m_betTotalCoins ~=  totalBet  then
            self.m_betTotalCoins = totalBet
            self:changebetUpDataCollect(totalBet)
            
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenTripletroveMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTripletroveMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    self.m_openDoorNode:stopAllActions()
    self:clearDoorList()

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTripletroveMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Tripletrove_10"
    elseif symbolType == self.SYMBOL_SCORE_DOOR then
        return "Socre_Tripletrove_Door"
    elseif symbolType == self.SYMBOL_SCORE_BONUS1  then
        return "Socre_Tripletrove_bonus1"
    elseif symbolType == self.SYMBOL_SCORE_BONUS2 then
        return "Socre_Tripletrove_bonus2"
    elseif symbolType == self.SYMBOL_SCORE_BONUS3 then
        return "Socre_Tripletrove_bonus3"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT1 then
        return "Socre_Tripletrove_grand"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT2 then
        return "Socre_Tripletrove_super"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT3 then
        return "Socre_Tripletrove_mega"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT4 then
        return "Socre_Tripletrove_major"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT5 then
        return "Socre_Tripletrove_minor"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT6 then
        return "Socre_Tripletrove_mini"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTripletroveMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenTripletroveMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_DOOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_JACKPOT1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_JACKPOT2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_JACKPOT3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_JACKPOT4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_JACKPOT5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_JACKPOT6,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenTripletroveMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --根据触发的类型修改显示不同的freeSpinBar
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local kind = fsExtraData.kind or {}
        self.m_freeSpinBar:changeLabForFeature(kind)
        if kind[2] == CURRENCY_NUM.ONE then
            self.jackpotBar:isShowSpot(true)
            --刷新jackpot点的显示
            self:updateJackpotSpotForDisconnection()
        end
        if kind[3] == CURRENCY_NUM.ONE then
            self:changeFreeIndex(true)
        end
    end
    
end

--断线重连刷新jackpot点的显示
function CodeGameScreenTripletroveMachine:updateJackpotSpotForDisconnection( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local totaljackpot = fsExtraData.totaljackpot or {}
    for i,v in ipairs(totaljackpot) do
        self.jackpotBar:updateJackpotSpotShow(i,v,false)
    end
end

--initGame刷新宝箱和小板子
function CodeGameScreenTripletroveMachine:updateCaseForDisconnection( )
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        return
    end
    --根据触发的类型修改显示不同的freeSpinBar
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}

    for i=1,3 do
        if kind[i] == 1 then
            local case = self:getTriggerCase(i)
            local word = self:getTriggerWold(i)
            case:initTriggerShow()
        else
            local case = self:getTriggerCase(i)
            local word = self:getTriggerWold(i)
            case:showDarkEffect()
            word:triggerFreeWordShow()
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenTripletroveMachine:slotOneReelDown(reelCol)    
    CodeGameScreenTripletroveMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenTripletroveMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self:findChild("reel_fs"):setVisible(true)
    self:findChild("reel_base"):setVisible(false)
    self.m_freeSpinBar:setVisible(true)
    self.m_gameBg:runCsbAction("base_to_free",false,function (  )
        self.m_gameBg:runCsbAction("free_idle")
    end)
    
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenTripletroveMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self:findChild("reel_fs"):setVisible(false)
    self:findChild("reel_base"):setVisible(true)
    self.m_freeSpinBar:setVisible(false)
    self.m_gameBg:runCsbAction("free_to_base",false,function (  )
        self.m_gameBg:runCsbAction("base_idle")
    end)
end
---------------------------------------------------------------------------


--************************************************************玩法：FreeSpinstart
function CodeGameScreenTripletroveMachine:showFreeSpinView(effectData)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}     --表示触发了哪种free [0,0,0]这个结构，表示触发的是哪几个free，比如1，0， 0，表示的就是只触发了第一个free
    
    --根据触发的类型修改显示不同的freeSpinBar
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {} 
    self.m_freeSpinBar:changeLabForFeature(kind)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local num,tempList = self:getFreeKindNum()
            if num == 1 then
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_fsStartOne.mp3")
            elseif num == 2 then
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_fsStartTwo.mp3")
            elseif num == 3 then
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_fsStartThree.mp3")
            end
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:delayCallBack(0.5,function (  )
                    self:changeFreeSpinBarShow()
                    self:hideFeatureWord()
                end)
                
                self:showGuoChangView(function (  )
                    if kind[3] == 1 then
                        self:showResStartView(function (  )
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()  
                        end)
                    else
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end
                end)   
            end)
            --根据类型修改宝箱的显示
            self:changeFreeSpinStartShow(view)
            local lab = view:findChild("m_lb_num")
            view:updateLabelSize({label=lab,sx=0.45,sy=0.45},163)
            view:findChild("Node"):setScale(self.m_machineRootScale * 0.9)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    self:delayCallBack(1,function (  )
        self:triggerFreeForCase(function (  )
            showFSView()  
        end)
    end)

end

function CodeGameScreenTripletroveMachine:hideFeatureWord( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}
    for i,v in ipairs(kind) do
        if v == 0 then
            --小板子压黑
            local word = self:getTriggerWold(i)
            word:triggerFreeWordShow()
        end
    end
end


function CodeGameScreenTripletroveMachine:changeFreeSpinStartShow(view)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}     --表示触发了哪种free [0,0,0]这个结构，表示触发的是哪几个free，比如1，0， 0，表示的就是只触发了第一个free
    local num,tempList = self:getFreeKindNum()
    
    if num == 1 then
        local label = self:getFreeSpinBonus(tempList[1])
        view:findChild("Node_dan"):addChild(label)
    elseif num == 2 then
        local label1 = self:getFreeSpinBonus(tempList[1])
        local label2 = self:getFreeSpinBonus(tempList[2])
        view:findChild("Node_zuo"):addChild(label1)
        view:findChild("Node_you"):addChild(label2)
    elseif num == 3 then
        local label1 = self:getFreeSpinBonus(tempList[1])
        local label2 = self:getFreeSpinBonus(tempList[2])
        local label3 = self:getFreeSpinBonus(tempList[3])
        view:findChild("Node_zuo_0"):addChild(label1)
        view:findChild("Node_zhong_0"):addChild(label2)
        view:findChild("Node_you_0"):addChild(label3)
    end

    for i=1,3 do
        if i == num then
            view:findChild("Node_" .. i):setVisible(true)
        else
            view:findChild("Node_" .. i):setVisible(false)
        end
    end
end

function CodeGameScreenTripletroveMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )
    -- free下不需要考虑更新左上角赢钱
    globalData.slotRunData.lastWinCoin = currCoins
    local params = {currCoins,isNotifyUpdateTop,nil,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--有金色宝箱玩法修改freespinBar展示
function CodeGameScreenTripletroveMachine:changeFreeSpinBarShow( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}     --表示触发了哪种free [0,0,0]这个结构，表示触发的是哪几个free，比如1，0， 0，表示的就是只触发了第一个free
    if kind[2] == CURRENCY_NUM.ONE then
        self.jackpotBar:isShowSpot(true)
    end
end

function CodeGameScreenTripletroveMachine:changeFreeIndex(isDisconnection)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local specialbonus = selfData.special_bonus or 0
    if isDisconnection then
        specialbonus = fsExtraData.special_bonus or 0
        self.redWord:initRedWordShow(specialbonus)
    else
        specialbonus = selfData.special_bonus or 0
    end
    
    if specialbonus == 0 then
        self.m_fsReelDataIndex = self.FREEINDEX_ONE
    elseif specialbonus == 1 then
        self.m_fsReelDataIndex = self.FREEINDEX_TWO
    elseif specialbonus == 2 then
        self.m_fsReelDataIndex = self.FREEINDEX_THTRR
    elseif specialbonus == 3 then
        self.m_fsReelDataIndex = self.FREEINDEX_FOUR
    elseif specialbonus == 4 then
        self.m_fsReelDataIndex = self.FREEINDEX_FIVE
    elseif specialbonus == 5 then
        self.m_fsReelDataIndex = self.FREEINDEX_SIX
    elseif specialbonus == 6 then
        self.m_fsReelDataIndex = self.FREEINDEX_SEVEN
    end
end

--红色开始弹板
function CodeGameScreenTripletroveMachine:showResStartView(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local specialbonus = selfData.special_bonus or 0
    self:changeFreeIndex(false)
    local redStartView = util_createView("CodeTripletroveSrc.TripletroveRedFreeStartView")
    self:findChild("Node_hongstart"):addChild(redStartView)
    self:delayCallBack(1/3,function (  )
        redStartView:setEndCall(func)
        redStartView:updateSymbolShow(specialbonus)
        
    end)
end

function CodeGameScreenTripletroveMachine:getFreeSpinBonus(colorBonus)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local bonus_position = selfData.bonus_position or {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local winjackpot = fsExtraData.winjackpot or {}
    local jackpot_bonuschange = selfData.jackpot_bonuschange
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0
    local labelView = nil
    if colorBonus == CURRENCY_NUM.ONE then
        labelView = util_createAnimation("Tripletrove_biaoqian_lan.csb")
        local wordView = util_createView("CodeTripletroveSrc.TripletroveFreeSpinLabelView",1)
        wordView:initBuleWordShow(buleFreeNum)
        labelView:findChild("Node_lanzi"):addChild(wordView)
    elseif colorBonus == CURRENCY_NUM.TWO then
        labelView = util_createAnimation("Tripletrove_biaoqian_jin.csb")
        local wordView = util_createView("CodeTripletroveSrc.TripletroveFreeSpinLabelView",2)
        labelView:findChild("Node_jinzi"):addChild(wordView)
    elseif colorBonus == CURRENCY_NUM.THREE then
        labelView = util_createAnimation("Tripletrove_biaoqian_hong.csb")
        local wordView = util_createView("CodeTripletroveSrc.TripletroveFreeSpinLabelView",3)
        wordView:initRedWordShow(specialbonus)
        labelView:findChild("Node_hongzi"):addChild(wordView)
    else
        labelView = util_createAnimation("Tripletrove_biaoqian_jin.csb")
        local wordView = util_createView("CodeTripletroveSrc.TripletroveFreeSpinLabelView",2)
        labelView:findChild("Node_jinzi"):addChild(wordView)
    end
    return labelView
end

function CodeGameScreenTripletroveMachine:getFreeKindNum( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}     --表示触发了哪种free [0,0,0]这个结构，表示触发的是哪几个free，比如1，0， 0，表示的就是只触发了第一个free
    local kindNum = 0
    local tempList = {}
    for i,v in ipairs(kind) do
        if kind[i] == 1 then
            kindNum = kindNum + 1
            table.insert( tempList,i)
        end
    end
    return kindNum,tempList
end

--[[
    @desc: free结束后刷新jackpot数值、宝箱显示、文字框显示
    author:{author}
    time:2022-01-10 18:20:28
    @return:
]]

function CodeGameScreenTripletroveMachine:changejackpotCoins(isFreeOver)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0
    local collect = selfData.collect or {0,0,0}    --收集数量
    local collectlevel = selfData.collectlevel or {0,0,0}  --收集等级
    if isFreeOver then
        --刷新红色文字框显示
        self.redWord:initRedWordShow(specialbonus)
        --更改蓝色文字框显示free的字数
        local buleLab = self.blueWord:findChild("m_lb_num")
        buleLab:setString(buleFreeNum)
        self:updateLabelSize({label=buleLab,sx=0.35,sy=0.35},163)
        self.redSpecialBonus = specialbonus
        self.blueWordNum = buleFreeNum

        self.redWord:showLightEffect(true)
        self.blueWord:showLightEffect()
        self.goldWord:showLightEffect()
    end
    
end

--无赢钱
function CodeGameScreenTripletroveMachine:showNoWinView(func)
    local view = self:showDialog("NoWin", nil, func)
    view:findChild("Node_1"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenTripletroveMachine:showFreeSpinOverView()
    self:delayCallBack(0.5,function (  )
        gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_over_fs.mp3")
        local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
        local strCoins=util_formatCoins(freeSpinWinCoin,50)
        self:delayCallBack(35/60,function (  )
            self:refreshCaseEffect(true,nil)
            --刷新宝箱显示
            self:changejackpotCoins(true)
            self.jackpotBar:isShowSpot(false)
        end)
        if freeSpinWinCoin == 0 then
            local view = self:showNoWinView(function ()
                self:triggerFreeSpinOverCallFun()
                self.m_fsReelDataIndex = self.FREEINDEX_NOMAL
            end)
        else
            local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:triggerFreeSpinOverCallFun()
                self.m_fsReelDataIndex = self.FREEINDEX_NOMAL
            end)
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=0.93,sy=1},833)
            local lab = view:findChild("m_lb_num")
            view:updateLabelSize({label=lab,sx=0.51,sy=0.51},163)
            view:findChild("Node_1"):setScale(self.m_machineRootScale * 0.9)
        end
        
    end)
    
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTripletroveMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )

    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenTripletroveMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local bonus_position = selfData.bonus_position or {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local winjackpot = fsExtraData.winjackpot or {}
    local jackpot_bonuschange = selfData.jackpot_bonuschange
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0

    if #mystery_position > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.OPEN_DOOR_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.OPEN_DOOR_EFFECT -- 动画类型
    end

    if #winjackpot > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GOLD_FREE_JACKPOT_WIN_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GOLD_FREE_JACKPOT_WIN_EFFECT -- 动画类型
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:isTriggerAddition() then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.BASE_GOLDCASE_CHANGE_JACKPOT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BASE_GOLDCASE_CHANGE_JACKPOT -- 动画类型
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTripletroveMachine:MachineRule_playSelfEffect(effectData)

    --jackpotchange
    if effectData.p_selfEffectType == self.OPEN_DOOR_EFFECT then
        --base下开门有机会产生bonus图标，free下开门有机会产生jackpot图标
        self.m_baseBonusEffect = effectData
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:showOpenDoorForGoldCaseEffect()
        else
            self:showOpenDoorEffect()
        end
    elseif effectData.p_selfEffectType == self.GOLD_FREE_JACKPOT_WIN_EFFECT then
        self.JackpotWinIndex = 1
        --展示获得jackpot弹板
        self:delayCallBack(1,function (  )
            self:showFreeGameJackpotWin(effectData)
        end)
    elseif effectData.p_selfEffectType == self.BASE_GOLDCASE_CHANGE_JACKPOT then
        self:delayCallBack(1.7,function (  )
            self:changeJackpotFourCoinsEffect(effectData)
        end)
    end

    return true
end

--**********************************************玩法：每次spin都修改中间两档jackpot的值
--[[
    @desc: 每次spin都修改中间两档jackpot的值
    author:{author}
    time:2022-01-17 17:49:37
    --@effectData: 
    @return:
]]
function CodeGameScreenTripletroveMachine:changeJackpotEffect(isSpin,isFree)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotchange = selfData.jackpotchange or {0,0,0,0}
    local jackpot_bonuschange = selfData.jackpot_bonuschange
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    if isSpin then
        if jackpotchange then
            --每次spin改变中间两个jackpot的值（如果有加成，将倍数减掉，飞行之后再刷新总的倍数）
            local jackpotchange2 = self:getJackpotChangeForBonus()
            self.jackpotBar:changeNodeForSpin(jackpotchange2,totalBet,true,false)
        end
    else
        if jackpotchange then  
            --在free中了jackpot后会reset
            if isFree then
                --每次spin改变中间两个jackpot的值
                self.jackpotBar:changeNodeForSpin(jackpotchange,totalBet,false,false,nil) 
            else
                local additionIndex = self:getJackpotChangeForAddition()
                --每次spin改变中间两个jackpot的值
                self.jackpotBar:changeNodeForSpin(jackpotchange,totalBet,true,true,additionIndex) 
            end
              
        end
    end
end

--判断哪一种jackpot发生加成
function CodeGameScreenTripletroveMachine:getJackpotChangeForAddition( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotchange = selfData.jackpotchange or {0,0,0,0}
    local jackpot_bonuschange = selfData.jackpot_bonuschange        --飞金币用
    if jackpot_bonuschange then
        for i,v in ipairs(jackpot_bonuschange) do
            if jackpot_bonuschange[i] > 0 then
                return i
            end
        end
    else
        return nil
    end
end

function CodeGameScreenTripletroveMachine:getJackpotChangeForBonus( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotchange = selfData.jackpotchange or {0,0,0,0}
    local jackpot_bonuschange = selfData.jackpot_bonuschange        --飞金币用
    local tempList = {}
    if jackpot_bonuschange then
        for i=1,4 do
            local difference = jackpotchange[i] - jackpot_bonuschange[i]
            tempList[#tempList + 1] = difference
        end
        return tempList
    else
        return jackpotchange
    end
end

--**********************************************玩法：金色宝箱有几率触发飞一枚金币到jackpot上

function CodeGameScreenTripletroveMachine:getMultipleAdditionNum( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpot_bonuschange = selfData.jackpot_bonuschange
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0
    local additionNum = 0
    if jackpot_bonuschange then
        additionNum = additionNum + 1
    end
    if self.redSpecialBonus ~= specialbonus then
        additionNum = additionNum + 1
    end
    if self.blueWordNum ~= buleFreeNum then
        additionNum = additionNum + 1
    end
    return additionNum
end

function CodeGameScreenTripletroveMachine:changeJackpotFourCoinsEffect(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpot_bonuschange = selfData.jackpot_bonuschange
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0
    local collectlevel = self:changeCollectLevelForFree()

    local waitTime = 0.6

    --判断是否是两个及以上箱子加成
    local additionNum = self:getMultipleAdditionNum()
    if additionNum >= 2 then
        local num = math.random(1,3)
        if num == 1 then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_goldWord_fankui.mp3")
        elseif num == 2 then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_redWord_cha.mp3")
        else
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_blueWord_addNum.mp3")
        end
    end

    if jackpot_bonuschange then
        local function transformationIndex( index )
            if index == 1 then
                return CURRENCY_NUM.THREE
            elseif index == 2 then
                return CURRENCY_NUM.FOUR
            elseif index == 3 then
                return CURRENCY_NUM.FIVE
            elseif index == 4 then
                return CURRENCY_NUM.SIX
            end
        end
    
        local collectType = nil
        for i,v in ipairs(jackpot_bonuschange) do
            if v ~= 0 then
                collectType = i
            end
        end
    
        local startPos = cc.p(self:getEndPosForSymbolType(self.SYMBOL_SCORE_BONUS2))
        local endPos = self:getflyOneGoldEndPos(collectType)
        local flyGold = util_createAnimation("Tripletrove_jackpot_shouji_jinbi.csb")
        self:addChild(flyGold,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5)
        flyGold:setPosition(startPos)
        local actList = {}
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            if additionNum < 2 then
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_goldWord_fankui.mp3")
            end
            --宝箱抖一下
            self.goldCase:showCaseAdditionEffect()
        end)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyGold:runCsbAction("start")
        end)
        actList[#actList + 1] = cc.DelayTime:create(8/60)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyGold:runCsbAction("feixing")
        end)
        actList[#actList + 1]  = cc.MoveTo:create(5/6,endPos)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyGold:runCsbAction("over")
            
        end)
        
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            --反馈
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_flyFankui.mp3")
            self.jackpotBar:flyGoldFeedback(transformationIndex(collectType))
            self.jackpotBar:showJackpotBulingEffect(transformationIndex(collectType),false)
            self:changeJackpotEffect(false,false)
        end)
        actList[#actList + 1] = cc.DelayTime:create(1/3)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            
            flyGold:removeFromParent()
        end)
        local sq = cc.Sequence:create(actList)
        flyGold:runAction(sq)
        waitTime = 5/6 + 0.5
    end
    
    
    --刷新红色文字框显示
    if self.redSpecialBonus ~= specialbonus then
        --宝箱抖一下
        if additionNum < 2 then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_redWord_cha.mp3")
        end
        self.redCase:showCaseAdditionEffect()
        self.redWord:updateRedCaseShow(specialbonus)
        self.redSpecialBonus = specialbonus
    end

    --更改蓝色文字框显示free的字数
    if self.blueWordNum ~= buleFreeNum then
        --宝箱抖一下
        if additionNum < 2 then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_blueWord_addNum.mp3")
        end
        self.blueCase:showCaseAdditionEffect()
        self.blueWord:updateBlueShow(function (  )
            local buleLab = self.blueWord:findChild("m_lb_num")
            buleLab:setString(buleFreeNum)
            self:updateLabelSize({label=buleLab,sx=0.35,sy=0.35},163)
            self.blueWordNum = buleFreeNum
        end)
    end
    self:delayCallBack(waitTime,function (  )
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end)
end


function CodeGameScreenTripletroveMachine:getflyOneGoldEndPos(type)
    if type == CURRENCY_NUM.ONE then
        return util_convertToNodeSpace(self.jackpotBar:findChild("Tripletrove_bace_kuang9_8"),self)
    elseif type == CURRENCY_NUM.TWO then
        return util_convertToNodeSpace(self.jackpotBar:findChild("Tripletrove_bace_kuang10_3"),self)
    elseif type == CURRENCY_NUM.THREE then
        return util_convertToNodeSpace(self.jackpotBar:findChild("Tripletrove_bace_kuang11_4"),self)
    elseif type == CURRENCY_NUM.FOUR then
        return util_convertToNodeSpace(self.jackpotBar:findChild("Tripletrove_bace_kuang12_5"),self)
    end
end

function CodeGameScreenTripletroveMachine:changeCollectLevelForFree( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local features = self.m_runSpinResultData.p_features or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local kind = fsExtraData.kind or {}
    local collectlevel = selfData.collectlevel or {0,0,0}  --收集等级

    local newCollectLevel = clone(collectlevel)
    if #features >= 2 and features[2] == 1 then
        for i=1,3 do
            if kind[i] == 1 then
                newCollectLevel[i] = 3
            end
        end
    end
    
    return newCollectLevel
end


--********************************base开门玩法相关start

function CodeGameScreenTripletroveMachine:showOpenDoorEffect()
    
    --如果有开门玩法，则激活stop按钮
    -- 打开stop按钮的点击状态 
    -- 修改的状态取自 SpinBtn:btnStopTouchEnd() 内判断的状态数据
    self.m_bottomUI.m_spinBtn.m_btnStopTouch = false
    globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
    globalData.slotRunData.isClickQucikStop = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local mystery_change = selfData.mystery_change
    local bonus_position = selfData.bonus_position or {}
    local collectlevelchange = selfData.collectlevelchange or {0,0,0}
    local waitTime = 0

    for i,v in ipairs(mystery_position) do
        local info = mystery_position[i]
        local fixPos = self:getRowAndColByPos(info)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        --创建一个假的门图标，用来打开
        local pos = util_convertToNodeSpace(symbolNode,self.m_clipParent)
        local endPos = nil
        local tempBonus = nil
        --是否有收集bonus
        if self:isHaveCollect(info) then
            local symbolType = self:isHaveCollect(info)
            tempBonus = util_createAnimation(self:getTempBonusSymbol(symbolType))
            tempBonus:setPosition(pos)
            tempBonus.pos = info
            endPos = cc.p(self:getEndPosForSymbolType(self:isHaveCollect(info)))
            self.m_clipParent:addChild(tempBonus,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
            table.insert( self.bonusDoorList,tempBonus)
        end
        local tempDoor = util_spineCreate("Socre_Tripletrove_Door",true,true)
        tempDoor:setPosition(cc.p(pos))

        self.m_clipParent:addChild(tempDoor,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5)
        table.insert(self.tempDoorList,tempDoor)
        
        if symbolNode then
            --改变门下图标
            local ccbName = self:getSymbolCCBNameByType(self, mystery_change)
            symbolNode:changeCCBByName(ccbName, mystery_change)
            
            symbolNode:changeSymbolImageByName(ccbName)
        end
    end
    self:showOpenDoorAction(false)
end

function CodeGameScreenTripletroveMachine:showOpenDoorAction(isQuickStop)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local mystery_change = selfData.mystery_change
    local bonus_position = selfData.bonus_position or {}
    local collectlevelchange = selfData.collectlevelchange or {0,0,0}
    local features = self.m_runSpinResultData.p_features or {}
    

    local function flyBonus( flyNode,endPos)
        local particle1 = flyNode:findChild("Particle_1")
        local particle2 = flyNode:findChild("Particle_1_0")
        local newPos = util_convertToNodeSpace(flyNode,self)
        local actList = {}
        
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyNode:runCsbAction("actionframe")
        end)
        actList[#actList + 1] = cc.DelayTime:create(45/60)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            util_changeNodeParent(self,flyNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
            flyNode:setScale(self.m_machineRootScale)
            flyNode:setPosition(newPos)
        end)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyNode:runCsbAction("shouji")
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle2:setDuration(-1)
            particle1:setPositionType(0)   --设置可以拖尾
            particle2:setPositionType(0)
            particle1:resetSystem()
            particle2:resetSystem()
        end)
        actList[#actList + 1]  = cc.BezierTo:create(17/60,{cc.p(newPos.x , newPos.y), cc.p(endPos.x, newPos.y), endPos})
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            particle1:stopSystem()--移动结束后将拖尾停掉
            particle2:stopSystem()
            flyNode:removeFromParent()
        end)
        local sq = cc.Sequence:create(actList)
        flyNode:runAction(sq)
    end

    local actList = {}
    if not isQuickStop then
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self.m_isShowOpenDoor = false
            if #self.tempDoorList > 0 then
                self.openDoorSound = gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_openDoor.mp3")
            end
            for i,v in ipairs(self.tempDoorList) do
                util_spinePlay(v,"actionframe",false)
            end
        end)
        actList[#actList + 1] = cc.DelayTime:create(0.9)
    end
    
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        self.m_isShowOpenDoor = true
        if #self.bonusDoorList > 0 then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_rotate.mp3")
        end
        for i,v in ipairs(self.bonusDoorList) do
            local endPos = cc.p(self:getEndPosForSymbolType(self:isHaveCollect(v.pos)))
            flyBonus(v,endPos)
        end
        self.bonusDoorList = {}
    end)
    
    if #bonus_position > 0 then
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self:delayCallBack(62/60,function (  )
                self:refreshCaseEffect(false,selfData)
            end)
        end)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self:delayCallBack(45/60,function (  )
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_fly.mp3")
            end)
        end)
    end
    --判断是否触发大赢
    if #features >= 2 or self:checkIsBigWin(self.m_runSpinResultData.p_winAmount,false) then
        actList[#actList + 1] = cc.DelayTime:create(1)
    end
    
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        self.m_baseBonusEffect.p_isPlay = true
        self.m_baseBonusEffect = nil
        self:playGameEffect()
    end)
    self.m_openDoorNode:runAction(cc.Sequence:create( actList))
end

function CodeGameScreenTripletroveMachine:checkIsBigWin(winAmonut,isFree)
    local winEffect = false
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local mystery_position = selfData.mystery_positin or {}
    local mystery_change = selfData.mystery_change
    local bonus_position = selfData.bonus_position or {}
    local winjackpot = fsExtraData.winjackpot or {}
    if isFree then
        if winAmonut == 0 or #winjackpot ~= 0 then return winEffect end
    else
        if winAmonut == 0 or #bonus_position == 0 then return winEffect end
    end
    
    
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = winAmonut / lTatolBetNum

    if winRatio >= self.m_HugeWinLimitRate then
        winEffect = true
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = true
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = true
    end
    return winEffect
end

--是否触发了加成
function CodeGameScreenTripletroveMachine:isTriggerAddition( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local bonus_position = selfData.bonus_position or {}
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local winjackpot = fsExtraData.winjackpot or {}
    local jackpot_bonuschange = selfData.jackpot_bonuschange
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0

    if jackpot_bonuschange or self.redSpecialBonus ~= specialbonus or self.blueWordNum ~= buleFreeNum then
        return true
    end
    return false
end

function CodeGameScreenTripletroveMachine:clearDoorList( )
    for i,v in ipairs(self.tempDoorList) do
        v:removeFromParent()
    end
    self.tempDoorList = {}
end

function CodeGameScreenTripletroveMachine:checkCaseShowForSymbolType(symbolType,bonusPosition)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_position = selfData.bonus_position or {}
    if bonusPosition then
        bonus_position = bonusPosition
    end
    for k,v in pairs(bonus_position) do
        if v[1] == symbolType then
            return true
        end
    end
    return false
end

function CodeGameScreenTripletroveMachine:clearCollectLevel( )
    local fsExtra = self.m_runSpinResultData.p_fsExtraData
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectlevel = selfData.collectlevel or {0,0,0}  --收集等级
    local kind = fsExtra.kind or {0,0,0}
    local newCollectLevel = clone(collectlevel)
    for i=1,3 do
        if kind[i] == 1 then
            newCollectLevel[i] = 0
        end
    end
    return newCollectLevel
end

function CodeGameScreenTripletroveMachine:isFreeForFreeKind(caseIndex)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local features = self.m_runSpinResultData.p_features or {}
    local kind = fsExtraData.kind or {}
    if #features >= 2 and features[2] == 1 then
        for i,v in ipairs(kind) do
            if i == caseIndex and kind[caseIndex] == 1 then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenTripletroveMachine:refreshCaseEffect(isFreeOver,self_data)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    
    if self_data then
        selfData = self_data
    end
    local buleFreeNum = selfData.special_freetime or 9
    local specialbonus = selfData.special_bonus or 0
    local collect = selfData.collect or {0,0,0}    --收集数量
    local collectlevel = selfData.collectlevel or {0,0,0}  --收集等级
    local bonus_position = selfData.bonus_position or {}
    local jackpotchange = selfData.jackpotchange or {0,0,0,0}
    local totalBet = globalData.slotRunData:getCurTotalBet( )

    local features = self.m_runSpinResultData.p_features or {}
    --刷新宝箱显示
    if isFreeOver then
        --触发了哪个free，就清理哪一个free的collectLevel
        local newCollectLevel = self:clearCollectLevel()
        self.blueCase:updateCaseState(newCollectLevel[1],true,isFreeOver)
        self.goldCase:updateCaseState(newCollectLevel[2],true,isFreeOver)
        self.redCase:updateCaseState(newCollectLevel[3],true,isFreeOver)

        --恢复jackpot钱数
        self.jackpotBar:changeNodeForSpin(jackpotchange,totalBet,false,false,nil) 

    else
        gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_bonus_collectFanKui_1.mp3")
        if self:checkCaseShowForSymbolType(self.SYMBOL_SCORE_BONUS1,bonus_position) then
            self.blueCase:showBoomEffect()
            local isFree = self:isFreeForFreeKind(1)
            self.blueCase:updateCaseState(collectlevel[1],false,isFree)
        end
        if self:checkCaseShowForSymbolType(self.SYMBOL_SCORE_BONUS2,bonus_position) then
            self.goldCase:showBoomEffect()
            local isFree = self:isFreeForFreeKind(2)
            self.goldCase:updateCaseState(collectlevel[2],false,isFree)
        end
        if self:checkCaseShowForSymbolType(self.SYMBOL_SCORE_BONUS3,bonus_position) then
            self.redCase:showBoomEffect()
            local isFree = self:isFreeForFreeKind(3)
            self.redCase:updateCaseState(collectlevel[3],false,isFree)
        end
    end
    

end

function CodeGameScreenTripletroveMachine:triggerFreeForCase(func)
    gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_trigger_free.mp3")
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}
    if #kind > 0 then
        for i,v in ipairs(kind) do
            if v == 1 then
                local case = self:getTriggerCase(i)
                --触发时切换层级
                local newPos = util_convertToNodeSpace(self:getTriggerZorderForKindType(i),self:findChild("Node_jackpot"))
                if self:getTriggerZorderForKindType(i) then
                    util_changeNodeParent(self:findChild("Node_jackpot"),case,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
                    case:setPosition(newPos)
                    if i ~= 2 then
                        case:setScale(0.82)
                    end
                    
                end
                
                case:showFreeSpinForCase(function (  )
                    if self:getTriggerZorderForKindType(i) then
                        util_changeNodeParent(self:getTriggerZorderForKindType(i),case)
                        case:setPosition(cc.p(0,0))
                        if i ~= 2 then
                            case:setScale(1)
                        end
                    end
                    
                end)
            else
                local case = self:getTriggerCase(i)
                case:showDarkEffect()
                --小板子压黑
                local word = self:getTriggerWold(i)
                word:showDarkEffect()
            end
        end
    end
    self:delayCallBack(2,function (  )
        if func then
            func()
        end
    end)
end

function CodeGameScreenTripletroveMachine:getTriggerCase( index )
    if index == CURRENCY_NUM.ONE then
        return self.blueCase
    elseif index == CURRENCY_NUM.TWO then
        return self.goldCase
    elseif index == CURRENCY_NUM.THREE then
        return self.redCase
    end
end

function CodeGameScreenTripletroveMachine:getTriggerWold( index )
    if index == CURRENCY_NUM.ONE then
        return self.blueWord
    elseif index == CURRENCY_NUM.TWO then
        return self.goldWord
    elseif index == CURRENCY_NUM.THREE then
        return self.redWord
    end
end

function CodeGameScreenTripletroveMachine:getTriggerZorderForKindType(type)
    local endPos = nil
    if type == 1 then
        return self:findChild("Node_lanxiang")
    elseif type == 2 then
        return self:findChild("Node_jinxiang")
    elseif type == 3 then
        return self:findChild("Node_hongxiang")
    else
        return nil
    end
end

--开门是否有收集
function CodeGameScreenTripletroveMachine:isHaveCollect(pos)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_position = selfData.bonus_position or {}
    for k,v in pairs(bonus_position) do
        if v[2] == pos then
            return v[1]
        end
    end
    return nil
end

--返回不同信号值所对应的工程名
function CodeGameScreenTripletroveMachine:getTempBonusSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return "Socre_Tripletrove_bonus1.csb"
    elseif symbolType == self.SYMBOL_SCORE_BONUS2 then
        return "Socre_Tripletrove_bonus2.csb"
    elseif symbolType == self.SYMBOL_SCORE_BONUS3 then
        return "Socre_Tripletrove_bonus3.csb"
    else
        return "Socre_Tripletrove_bonus1.csb"
    end
end

--获取收集最终位置
function CodeGameScreenTripletroveMachine:getEndPosForSymbolType(symbolType)
    local endPos = nil
    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return util_convertToNodeSpace(self:findChild("Node_lanxiang"),self)
    elseif symbolType == self.SYMBOL_SCORE_BONUS2 then
        return util_convertToNodeSpace(self:findChild("Node_jinbi"),self)
    elseif symbolType == self.SYMBOL_SCORE_BONUS3 then
        return util_convertToNodeSpace(self:findChild("Node_hongxiang"),self)
    else
        return nil
    end
end

--********************************base开门玩法相关end

--***************************************************玩法：金色宝箱开门，获得jackpot图标
--[[
    @desc: 金色宝箱开门，获得jackpot图标
    author:{author}
    time:2022-01-17 18:25:50
    --@effectData: 
    @return:
]]
function CodeGameScreenTripletroveMachine:showOpenDoorForGoldCaseEffect()

    --如果有开门玩法，则激活stop按钮
    -- 打开stop按钮的点击状态 
    -- 修改的状态取自 SpinBtn:btnStopTouchEnd() 内判断的状态数据
    self.m_bottomUI.m_spinBtn.m_btnStopTouch = false
    globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
    globalData.slotRunData.isClickQucikStop = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local newjackpot = fsExtraData.newjackpot or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local mystery_change = selfData.mystery_change
    local waitTime = 0

    for i,v in ipairs(mystery_position) do
        local info = mystery_position[i]
        local fixPos = self:getRowAndColByPos(info)
        local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        --创建一个假的门图标，用来打开
        local pos = util_convertToNodeSpace(symbolNode,self.m_clipParent)
        local endPos = nil
        local tempBonus = nil
        --是否有收集bonus
        if self:isHaveJackpotCollect(info) then
            local jackpotInfo = self:isHaveJackpotCollect(info)
            tempBonus = util_createAnimation(self:getTempJackpotSymbol(jackpotInfo[1]))
            tempBonus:setPosition(pos)
            tempBonus.info = info
            endPos = self:getJackpotEndPosForSymbolType(jackpotInfo[1])
            self.m_clipParent:addChild(tempBonus,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
            table.insert( self.bonusDoorList,tempBonus)
        end
        local tempDoor = util_spineCreate("Socre_Tripletrove_Door",true,true)
        tempDoor:setPosition(cc.p(pos))

        self.m_clipParent:addChild(tempDoor,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 5)
        table.insert(self.tempDoorList,tempDoor)
        
        if symbolNode then
            --改变门下图标
            local ccbName = self:getSymbolCCBNameByType(self, mystery_change)
            symbolNode:changeCCBByName(ccbName, mystery_change)
            
            symbolNode:changeSymbolImageByName(ccbName)
        end
    end

    self:showFreeOpenDoorAction(false)
    
end

function CodeGameScreenTripletroveMachine:showFreeOpenDoorAction(isQuickStop)

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local newjackpot = fsExtraData.newjackpot or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local mystery_position = selfData.mystery_positin or {}
    local mystery_change = selfData.mystery_change
    local waitTime = 0

    local function flyBonus( flyNode,endPos,jackpotInfo )
        local particle1 = flyNode:findChild("Particle_1")
        local particle2 = flyNode:findChild("Particle_1_0")
        local newPos = util_convertToNodeSpace(flyNode,self)
        
        local actList = {}
        
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            util_changeNodeParent(self,flyNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
            flyNode:setScale(self.m_machineRootScale)
            flyNode:setPosition(newPos)
        end)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyNode:runCsbAction("actionframe")
        end)
        actList[#actList + 1] = cc.DelayTime:create(45/60)
        
        actList[#actList + 1] = cc.DelayTime:create(0.1)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            flyNode:runCsbAction("shouji")
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle2:setDuration(-1)
            particle1:setPositionType(0)   --设置可以拖尾
            particle2:setPositionType(0)
            particle1:resetSystem()
            particle2:resetSystem()
        end)
        actList[#actList + 1]  = cc.BezierTo:create(17/60,{cc.p(newPos.x , newPos.y), cc.p(endPos.x, newPos.y), cc.p(endPos.x , endPos.y)})
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            local jackpotSymbolType = jackpotInfo[1]
            local jackpotType = self:getJackpotType(jackpotSymbolType)
            self.jackpotBar:showBoomEffect(jackpotType)
            self.jackpotBar:flyGoldFeedback(jackpotType)
        end)
        actList[#actList + 1] = cc.DelayTime:create(0.05)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self:updateJackpotSpot(jackpotInfo)
            particle1:stopSystem()--移动结束后将拖尾停掉
            particle2:stopSystem()
            flyNode:removeFromParent()
        end)
        flyNode:runAction(cc.Sequence:create( actList))
    end

    local actList = {}
    if not isQuickStop then
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self.m_isShowOpenDoor = false
            if #self.tempDoorList > 0 then
                self.openDoorSound = gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_openDoor.mp3")
            end
            for i,v in ipairs(self.tempDoorList) do
                util_spinePlay(v,"actionframe",false)
            end
        end)
        actList[#actList + 1] = cc.DelayTime:create(0.9)
    end
    
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        self.m_isShowOpenDoor = true
        if #self.bonusDoorList > 0 then
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_rotate.mp3")
        end
        for i,v in ipairs(self.bonusDoorList) do
            local jackpotInfo = self:isHaveJackpotCollect(v.info)
            local endPos = self:getJackpotEndPosForSymbolType(jackpotInfo[1])
            flyBonus(v,endPos,self:isHaveJackpotCollect(v.info))
        end
        self.bonusDoorList = {}
    end)
    
    if #newjackpot > 0 then
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self:delayCallBack(62/60,function (  )
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_flyFankui.mp3")
            end)
        end)
        actList[#actList + 1]  = cc.CallFunc:create(function(  )
            self:delayCallBack(45/60,function (  )
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_fly.mp3")
            end)
            
        end)
    end

    if self:checkIsBigWin(self.m_runSpinResultData.p_winAmount,true) then
        actList[#actList + 1] = cc.DelayTime:create(62/60)
    end
    
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        self.m_baseBonusEffect.p_isPlay = true
        self.m_baseBonusEffect = nil
        self:playGameEffect()
    end)
    self.m_openDoorNode:runAction(cc.Sequence:create( actList))
end


function CodeGameScreenTripletroveMachine:getJackpotIndex(jackpotIndex)
    if tostring(jackpotIndex) == "grand" then
        return CURRENCY_NUM.ONE
    elseif tostring(jackpotIndex) == "super" then
        return CURRENCY_NUM.TWO
    elseif tostring(jackpotIndex) == "mega" then
        return CURRENCY_NUM.THREE
    elseif tostring(jackpotIndex) == "major" then
        return CURRENCY_NUM.FOUR
    elseif tostring(jackpotIndex) == "minor" then
        return CURRENCY_NUM.FIVE
    elseif tostring(jackpotIndex) == "mini" then
        return CURRENCY_NUM.SIX
    end
end

--**************************************在金色free中获取jackpot
function CodeGameScreenTripletroveMachine:getJackpotEndCoins( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local winjackpot = fsExtraData.winjackpot or {}
    local coins = 0
    for i,v in ipairs(winjackpot) do
        coins = coins + winjackpot[i][2]
    end
    return coins
end

function CodeGameScreenTripletroveMachine:showFreeGameJackpotWin(effectData)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local winjackpot = fsExtraData.winjackpot or {}
    if self.JackpotWinIndex > #winjackpot then
        --检测大赢
        if #self.m_runSpinResultData.p_winLines == 0 then
            local endCoins = self:getJackpotEndCoins()
            self:checkFeatureOverTriggerBigWin(endCoins,self.OPEN_DOOR_EFFECT)
        end
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        return
    end
    local index = self:getJackpotIndex(winjackpot[self.JackpotWinIndex][1])
    local coins = winjackpot[self.JackpotWinIndex][2]
    self.jackpotBar:showTriggerJackpotEffect(index)
    self:delayCallBack(2,function (  )
        self.jackpotBar:clearCollectFullEffect(index)
        self:showJackpotView(index,coins,function (  )
            self.JackpotWinIndex = self.JackpotWinIndex + 1
            self:showFreeGameJackpotWin(effectData)
        end)
    end)
end

function CodeGameScreenTripletroveMachine:showJackpotView(index,coins,func)
    -- self:delayCallBack(35/60,function (  )
    --     --刷新jackpot钱数显示
    --     self:changeJackpotEffect(false,true)
    -- end)
    local jackPotWinView = util_createView("CodeTripletroveSrc.TripletroveJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    jackPotWinView:findChild("Node_1"):setScale(self.m_machineRootScale * 0.9)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self,index,coins,func)
    local beginCoins = self.m_runSpinResultData.p_fsWinCoins - coins
    self:updateBottomUICoins(beginCoins,self.m_runSpinResultData.p_fsWinCoins,false)
end

function CodeGameScreenTripletroveMachine:updateJackpotSpot(jackpotInfo)
    local jackpotSymbolType = jackpotInfo[1]
    local jackpotType = self:getJackpotType(jackpotSymbolType)
    local spotNum = jackpotInfo[3]
    --刷新jackpot点的数量
    self.jackpotBar:updateJackpotSpotShow(jackpotType,spotNum,true)
end

function CodeGameScreenTripletroveMachine:getJackpotType(jackpotSymbolType)
    if jackpotSymbolType == self.SYMBOL_SCORE_JACKPOT1 then
        return CURRENCY_NUM.ONE
    elseif jackpotSymbolType == self.SYMBOL_SCORE_JACKPOT2 then
        return CURRENCY_NUM.TWO
    elseif jackpotSymbolType == self.SYMBOL_SCORE_JACKPOT3 then
        return CURRENCY_NUM.THREE
    elseif jackpotSymbolType == self.SYMBOL_SCORE_JACKPOT4 then
        return CURRENCY_NUM.FOUR
    elseif jackpotSymbolType == self.SYMBOL_SCORE_JACKPOT5 then
        return CURRENCY_NUM.FIVE
    elseif jackpotSymbolType == self.SYMBOL_SCORE_JACKPOT6 then
        return CURRENCY_NUM.SIX
    end
end

--开门是否有收集
function CodeGameScreenTripletroveMachine:isHaveJackpotCollect(pos)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local newjackpot = fsExtraData.newjackpot or {}
    for k,v in pairs(newjackpot) do
        if v[2] == pos then
            return v
        end
    end
    return nil
end

--返回不同信号值所对应的工程名(金色宝箱玩法）
function CodeGameScreenTripletroveMachine:getTempJackpotSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_JACKPOT1 then
        return "Socre_Tripletrove_grand.csb"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT2 then
        return "Socre_Tripletrove_super.csb"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT3 then
        return "Socre_Tripletrove_mega.csb"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT4 then
        return "Socre_Tripletrove_major.csb"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT5 then
        return "Socre_Tripletrove_minor.csb"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT6 then
        return "Socre_Tripletrove_mini.csb"
    else
        return "Socre_Tripletrove_mini.csb"
    end
end

--获取收集最终位置(金色宝箱玩法）
function CodeGameScreenTripletroveMachine:getJackpotEndPosForSymbolType(symbolType)
    if symbolType == self.SYMBOL_SCORE_JACKPOT1 then
        return util_convertToNodeSpace(self:findChild("Node_GRAND"),self)
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT2 then
        return util_convertToNodeSpace(self:findChild("Node_SUPER"),self)
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT3 then
        return util_convertToNodeSpace(self:findChild("Node_MEGA"),self)
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT4 then
        return util_convertToNodeSpace(self:findChild("Node_MAJOR"),self)
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT5 then
        return util_convertToNodeSpace(self:findChild("Node_MINOR"),self)
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT6 then
        return util_convertToNodeSpace(self:findChild("Node_MINI"),self)
    else
        return nil
    end
end
--********************************金色宝箱开门玩法相关end


--[[
    @desc: 过场
    author:{author}
    time:2022-01-13 10:33:21
    @return:
]]

function CodeGameScreenTripletroveMachine:chooseKindCombination( )
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local kind = fsExtraData.kind or {}
    if kind[1] == 1 and kind[2] == 1 and kind[3] == 0 then
        return CURRENCY_NUM.ONE
    elseif kind[1] == 1 and kind[2] == 0 and kind[3] == 1 then
        return CURRENCY_NUM.TWO
    elseif kind[1] == 0 and kind[2] == 1 and kind[3] == 1 then
        return CURRENCY_NUM.THREE
    else
        return CURRENCY_NUM.ONE
    end
end

function CodeGameScreenTripletroveMachine:getCaseForFreeKind(colorCase)
    if colorCase == CURRENCY_NUM.ONE then
        return "Tripletrove_Xiangzilan"
    elseif colorCase == CURRENCY_NUM.TWO then
        return "Tripletrove_Xiangzi"
    elseif colorCase == CURRENCY_NUM.THREE then
        return "Tripletrove_Xiangzihong"
    else
        return "Tripletrove_Xiangzi"
    end
end

function CodeGameScreenTripletroveMachine:changeCaseShowForKind( )
    local tempCases = {}
    local num,tempList = self:getFreeKindNum()
    for i=1,3 do
        if i == num then
            self.guochange:findChild("Node_" .. i):setVisible(true)
        else
            self.guochange:findChild("Node_" .. i):setVisible(false)
        end
    end

    if num == 1 then
        local case = util_spineCreate(self:getCaseForFreeKind(tempList[1]),true,true)
        util_spinePlay(case,"idleframegc1",false)
        self.guochange:findChild("Node_1_1"):addChild(case)
        table.insert( tempCases,case)
    elseif num == 2 then
        local case = util_spineCreate(self:getCaseForFreeKind(tempList[1]),true,true)
        local case2 = util_spineCreate(self:getCaseForFreeKind(tempList[2]),true,true)
        self.guochange:findChild("Node_2_1"):addChild(case)
        self.guochange:findChild("Node_2_2"):addChild(case2)
        util_spinePlay(case,"idleframegc1",false)
        util_spinePlay(case2,"idleframegc1",false)
        table.insert( tempCases,case)
        table.insert( tempCases,case2)
    elseif num == 3 then
        local case = util_spineCreate(self:getCaseForFreeKind(tempList[1]),true,true)
        local case2 = util_spineCreate(self:getCaseForFreeKind(tempList[2]),true,true)
        local case3 = util_spineCreate(self:getCaseForFreeKind(tempList[3]),true,true)
        self.guochange:findChild("Node_3_1"):addChild(case)
        self.guochange:findChild("Node_3_2"):addChild(case2)
        self.guochange:findChild("Node_3_3"):addChild(case3)
        util_spinePlay(case,"idleframegc1",false)
        util_spinePlay(case2,"idleframegc1",false)
        util_spinePlay(case3,"idleframegc1",false)
        table.insert( tempCases,case)
        table.insert( tempCases,case2)
        table.insert( tempCases,case3)
    end
    return tempCases
end

function CodeGameScreenTripletroveMachine:showGuoChangView(func)
    
    --根据不同的free种类  显示不同的动画
    self.guochange = util_createAnimation("Tripletrove_guochang.csb")
    local spine1 = util_spineCreate("Tripletrove_spine1",true,true)
    local spine2 = util_spineCreate("Tripletrove_spine2",true,true)
    local spine3 = util_spineCreate("Tripletrove_spine3",true,true)
    self.guochange:findChild("spine1"):addChild(spine1)
    self.guochange:findChild("spine2"):addChild(spine2)
    self.guochange:findChild("spine3"):addChild(spine3)
    self.m_spineTanbanParent:addChild(self.guochange,1000)
    self.guochange:setScale(self.m_machineRootScale)
    gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_guochang_light.mp3")
    self.guochange:runCsbAction("actionframe")
    util_spinePlay(spine2,"guochang",false)
    util_spinePlay(spine1,"guochang",false)
    util_spinePlay(spine3,"guochang",false)
    local tempCases = self:changeCaseShowForKind()
    self:delayCallBack(84/30,function (  )
        for i,v in ipairs(tempCases) do
            util_spinePlay(v,"actionframe",false)
        end
    end)
    self:delayCallBack(8,function (  )
        if func then
            func()
            self.guochange:removeFromParent()
        end
    end)
    
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenTripletroveMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenTripletroveMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenTripletroveMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenTripletroveMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenTripletroveMachine.super.slotReelDown(self)
end

function CodeGameScreenTripletroveMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


function CodeGameScreenTripletroveMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

    self:updateBetNetCollectData()

end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenTripletroveMachine:initGameStatusData(gameData)
    
    CodeGameScreenTripletroveMachine.super.initGameStatusData(self,gameData)
    local gameConfig = gameData.gameConfig
    if gameData.gameConfig ~= nil and  gameData.gameConfig.extra ~= nil then
        self:initBetNetCollectData(gameData.gameConfig.extra)
    else
        self.m_betNetCollectData = {}
        
    end
     
end

function CodeGameScreenTripletroveMachine:initBetNetCollectData(bets )
    if bets then
        self.m_betNetCollectData = bets
    end
end

function CodeGameScreenTripletroveMachine:updateBetNetCollectData( )
    local selfdata =  self.m_runSpinResultData.p_selfMakeData
    if selfdata then

        local totalBet = globalData.slotRunData:getCurTotalBet( )
        local data =  self.m_betNetCollectData[tostring(toLongNumber(totalBet) )] 
        if data == nil then
            self.m_betNetCollectData[tostring(toLongNumber(totalBet))] = {}
            data =  self.m_betNetCollectData[tostring(toLongNumber(totalBet))]
        end
        --客户端自己保存当前收集相关,在不断线的情况下，切换bet使用
        data.special_freetime = selfdata.special_freetime or 9
        data.special_bonus = selfdata.special_bonus or 0
        data.collect = selfdata.collect or {0,0,0}
        data.collectlevel = selfdata.collectlevel or {0,0,0}
        data.jackpotchange = selfdata.jackpotchange or {0,0,0,0}
    end
end

function CodeGameScreenTripletroveMachine:changebetUpDataCollect(totalBet)
    local data = self.m_betNetCollectData[tostring(toLongNumber(totalBet) )] 
    if data ~= nil then
        self:initCollectForGameConfig(data)
    else
        self:initCollectForGameConfig(self.m_betNetCollectData[tostring(0)] )
    end
end

function CodeGameScreenTripletroveMachine:initCollectForGameConfig(data)
    local buleFreeNum, specialbonus, collect, collectlevel, jackpotchange
    if data then
        buleFreeNum = data.special_freetime or 9
        specialbonus = data.special_bonus or 0
        collect = data.collect or {0,0,0}    --收集数量
        collectlevel = data.collectlevel or {0,0,0}  --收集等级
        jackpotchange = data.jackpotchange or {0,0,0,0}
    else
        buleFreeNum = 9
        specialbonus = 0
        collect = {0,0,0}    --收集数量
        collectlevel = {0,0,0}  --收集等级
        jackpotchange = {0,0,0,0}
    end
    

    self.blueWordNum = buleFreeNum
    self.redSpecialBonus = specialbonus

    --刷新宝箱显示
    self.blueCase:updateCaseState(collectlevel[1],true,false)
    self.goldCase:updateCaseState(collectlevel[2],true,false)
    self.redCase:updateCaseState(collectlevel[3],true,false)
    

    --刷新红色文字框显示
    self.redWord:initRedWordShow(specialbonus)
    --更改蓝色文字框显示free的字数
    local buleLab = self.blueWord:findChild("m_lb_num")
    buleLab:setString(buleFreeNum)
    self:updateLabelSize({label=buleLab,sx=0.35,sy=0.35},163)
    
    if jackpotchange then
        local totalBet = globalData.slotRunData:getCurTotalBet( )
        --每次spin改变中间两个jackpot的值
        self.jackpotBar:changeNodeForSpin(jackpotchange,totalBet,false,false)   
    end
    self:updateCaseForDisconnection()
end

function CodeGameScreenTripletroveMachine:quicklyStopReel(colIndex)
    --如果是开门玩法的stop，则跳过开门玩法
    if not self.m_isShowOpenDoor then
        if self.openDoorSound then
            gLobalSoundManager:stopAudio(self.openDoorSound)
            self.openDoorSound = nil
        end
        self.m_openDoorNode:stopAllActions()
        self:clearDoorList()
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:showFreeOpenDoorAction(true)
        else
            self:showOpenDoorAction(true)
        end
        
        self.m_isShowOpenDoor = true
    else
        CodeGameScreenTripletroveMachine.super.quicklyStopReel(self,colIndex)
    end
end

function CodeGameScreenTripletroveMachine:beginReel( )
    self:clearDoorList()
    CodeGameScreenTripletroveMachine.super.beginReel(self)
end

---
-- 处理spin 返回结果
function CodeGameScreenTripletroveMachine:spinResultCallFun(param)

    CodeGameScreenTripletroveMachine.super.spinResultCallFun(self,param)

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --每spin一次改变中间两档钱数
        self:changeJackpotEffect(true,false)
    end
    
end

function CodeGameScreenTripletroveMachine:scaleMainLayer()
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
            local cfgHeight = self:getReelHeight() + uiH + uiBH
            mainScale       = (cfgHeight / DESIGN_SIZE.height) * (display.height / DESIGN_SIZE.height)
            local offsetY = - mainPosY

            if display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.05
                offsetY = - mainPosY
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.05
                offsetY = (- mainPosY) + 10
            elseif display.height / display.width >= 1024/768 then
                offsetY = (- mainPosY + 10) * ((1228/768) / (display.height/display.width))
            end

            self.m_machineNode:setPositionY(mainPosY + offsetY)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

-- 显示paytableview 界面
function CodeGameScreenTripletroveMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    view:findChild("root"):setScale(self.m_machineRootScale)
    if view then
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
    end
end

--延迟回调
function CodeGameScreenTripletroveMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return CodeGameScreenTripletroveMachine