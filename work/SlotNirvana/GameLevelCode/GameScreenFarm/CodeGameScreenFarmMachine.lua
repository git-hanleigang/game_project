---
-- island li
-- 2019年1月26日
-- CodeGameScreenFarmMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseDialog = util_require("Levels.BaseDialog")
local FarmSlotsNode = require "CodeFarmSrc.FarmSlotsNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"

local CodeGameScreenFarmMachine = class("CodeGameScreenFarmMachine", BaseFastMachine)

CodeGameScreenFarmMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFarmMachine.COLLECT_CORN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenFarmMachine.SUPER_FREESPIN_OVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2

CodeGameScreenFarmMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  


CodeGameScreenFarmMachine.SYMBOL_FIX_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE   
CodeGameScreenFarmMachine.SYMBOL_FIX_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 
CodeGameScreenFarmMachine.SYMBOL_FIX_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 金色瓜 

CodeGameScreenFarmMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5 
CodeGameScreenFarmMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4 
CodeGameScreenFarmMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3 


CodeGameScreenFarmMachine.m_localCornNum = 0

CodeGameScreenFarmMachine.m_chipList = nil
CodeGameScreenFarmMachine.m_playAnimIndex = 0
CodeGameScreenFarmMachine.m_lightScore = 0
CodeGameScreenFarmMachine.m_vecMiniWheel = {}
CodeGameScreenFarmMachine.m_FsDownTimes = 0
CodeGameScreenFarmMachine.m_newCornList = {}

CodeGameScreenFarmMachine.gameEffectRunPause = nil
CodeGameScreenFarmMachine.m_SupperGameOver = false
--小块
function CodeGameScreenFarmMachine:getBaseReelGridNode()
    return "CodeFarmSrc.FarmSlotsNode"
end

-- 构造函数
function CodeGameScreenFarmMachine:ctor()
    BaseFastMachine.ctor(self)

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_vecMiniWheel = {}
    self.m_FsDownTimes = 0
    self.m_newCornList = {}
    self.gameEffectRunPause = nil
    self.isInBonus = false
    self.m_SupperGameOver = false
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenFarmMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FarmConfig.csv", "LevelFarmConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFarmMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Farm"  
end

-- 继承底层respinView
function CodeGameScreenFarmMachine:getRespinView()
    return "CodeFarmSrc.FarmRespinView"
end
-- 继承底层respinNode
function CodeGameScreenFarmMachine:getRespinNode()
    return "CodeFarmSrc.FarmRespinNode"
end


function CodeGameScreenFarmMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_FarmView = util_createView("CodeFarmSrc.FarmView")
    -- self:findChild("xxxx"):addChild(self.m_FarmView)

    self:createLocalAnimation()

    self.m_jackPotBar = util_createView("CodeFarmSrc.FarmJackPotBarView")
    self:findChild("JackPot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)


    self.m_MainReels_Barn = util_createView("CodeFarmSrc.FarmMainReels_BarnView")
    self:findChild("collect_gucang"):addChild(self.m_MainReels_Barn)
    self.m_MainReels_Barn:initMachine(self)
    

    self.m_MainReels_Corn = util_createView("CodeFarmSrc.FarmMainReels_CornView")
    self:findChild("collect_yumi"):addChild(self.m_MainReels_Corn)
    self.m_MainReels_Corn:findChild("m_lb_coins"):setString(util_formatCoins(0,6,nil,nil, true))
    
    
    
    self.m_respinSpinbar = util_createView("CodeFarmSrc.FarmRespinBarView")
    self:findChild("RespinsRemaning"):addChild(self.m_respinSpinbar)
    self.m_respinSpinbar:setVisible(false)

    self.m_GuoChang = util_createView("CodeFarmSrc.FarmGuoChangView")
    self:addChild(self.m_GuoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_GuoChang:setPosition(display.width/2,display.height/2)
    self.m_GuoChang:setVisible(false)

    self.m_CornNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_CornNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_soundNode = cc.Node:create()
    self:addChild(self.m_soundNode)


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "FarmSounds/music_Farm_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            self.m_winSoundsId = nil
        end)

        performWithDelay(self.m_soundNode,function(  )
            if self.m_winSoundsId then
                gLobalSoundManager:stopAudio(self.m_winSoundsId)
                self.m_winSoundsId = nil
            end  
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end,soundIndex)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenFarmMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "FarmSounds/Farm_scatter_down.mp3"
        elseif i == 2 then
            soundPath = "FarmSounds/Farm_scatter_down.mp3"
        else
            soundPath = "FarmSounds/Farm_scatter_down.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenFarmMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        if not self.isInBonus then
            gLobalSoundManager:playSound("FarmSounds/music_Farm_enter.mp3")
            scheduler.performWithDelayGlobal(function (  )
                
                    self:resetMusicBg()
                    self:setMinMusicBGVolume( )

            end,2.5,self:getModuleName())

        end

    end,0.4,self:getModuleName())
end

--[[
    @desc: 检测是否处于fs 状态
    @return: 是否触发
]]
function CodeGameScreenFarmMachine:checkTriggerOnEnterINFreeSpin( )
    local isPlayGameEff = false

    if self.m_initSpinData  then
        -- 检测是否处于
        local hasFreepinFeature = false
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            hasFreepinFeature = true
        end

        local hasReSpinFeature = false
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            hasReSpinFeature = true
        end

        local hasBonusFeature = false
        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
            hasBonusFeature = true
        end

        local isInFs = false
        if hasFreepinFeature == false and 
                self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
                self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
                (self.m_initSpinData.p_freeSpinsLeftCount > 0 or 
                    (hasReSpinFeature == true  or hasBonusFeature == true)) then
            -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
            isInFs = true
        end

        if isInFs == true then
            if self.m_initSpinData.p_freeSpinsTotalCount ~= self.m_initSpinData.p_freeSpinsLeftCount then
                isPlayGameEff=true
            end
            
        end
    end
    

    return isPlayGameEff
end

function CodeGameScreenFarmMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    -- 初始化小轮盘
    if self:checkTriggerOnEnterINFreeSpin() then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

        local reels = selfdata.reel or 1
        local row = selfdata.row or 3
        self:initFsMiniReels(reels,row)
        self:findChild("wheel_0"):setVisible(false)
    end

    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除

    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

    self:addObservers()

    self.m_jackPotBar:updateJackpotInfo()

    --小轮盘赋值
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        for i=1,#self.m_vecMiniWheel do
            local miniMachine = self.m_vecMiniWheel[i]
            miniMachine:enterLevelMiniSelf()
        end
    end

    
    
end



function CodeGameScreenFarmMachine:addObservers()
    BaseFastMachine.addObservers(self)


    gLobalNoticManager:addObserver(self, self.slotReelDownInFS,"FarmReelDownInFS")

end

function CodeGameScreenFarmMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName("farmCornFly")




    

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenFarmMachine:scaleMainLayer()
    
    BaseFastMachine.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.80
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.85 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end

end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFarmMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_FIX_BONUS_1  then
        return "Socre_Farm_Bouns"
    elseif symbolType == self.SYMBOL_FIX_BONUS_3  then
        return "Socre_Farm_Bouns"
        
    elseif symbolType == self.SYMBOL_FIX_BONUS_2  then
        return "Socre_Farm_Bouns2"
    elseif symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_Farm_10"

    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_Farm_Bouns_Major"


    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_Farm_Bouns_Minor"

    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_Farm_Bouns_Mini"
    end
    
    return nil
end

---
--设置bonus scatter 层级
function CodeGameScreenFarmMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1
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
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFarmMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS_3,count =  2}
    

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenFarmMachine:initGameStatusData(gameData)
    
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and  gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin  
    -- feature  
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end
 
    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0--gameData.totalWinCoins
    self:setLastWinCoin( totalWinCoins )

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                -- if feature.bonus.status == "CLOSED" and feature.bonus.content ~= nil then
                --     local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                --     feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = - bet
                -- end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
    
            end
        end 
        self.m_initFeatureData:parseFeatureData(feature)
        -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost 
    end
    
    if collect and type(collect)=="table" and #collect>0 then
        for i=1,#collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot)=="table" and #jackpot>0 then
        self.m_jackpotList=jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and  gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    if gameData.gameConfig ~= nil and  gameData.gameConfig.extra ~= nil then
        self.m_runSpinResultData["p_shopExtra"] = gameData.gameConfig.extra
    end

    self:initMachineGame()
end


function CodeGameScreenFarmMachine:initHasFeature( )
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:initRandomSlotNodes()
    else 
        self:initCloumnSlotNodesByNetData()
    end
end


function CodeGameScreenFarmMachine:checkInitSpinWithEnterLevel( )
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
       
        local isBonusOverData = false
        if self.m_initFeatureData then
            local bonusData = self.m_initFeatureData.p_bonus
            if bonusData  then
               if bonusData.status == "CLOSED" then
                    isBonusOverData = true
               end
            end
        end

        if self.m_initFeatureData == nil  or  isBonusOverData  then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end
        
        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin =  self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin --self:checkTriggerINFreeSpin()
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ---- 
        self:checkInitSlotsWithEnterLevel()
        
    end

    return isTriggerEffect,isPlayGameEffect
end

function CodeGameScreenFarmMachine:getFreeSpinType( )
    local fsType = 0
    -- 0  三个scatter触发
    -- 1 商城 触发bonus
    -- 2 商城触发freespin
   
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local machineFsType = selfdata.freespinTriggerType -- 商城触发

    if machineFsType then
        fsType = machineFsType  
    end


    return fsType

end

-- 断线重连 
function CodeGameScreenFarmMachine:MachineRule_initGame(  )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    -- 本地玉米数赋值
    self.m_localCornNum = selfdata.collectScore or 0
    self.m_MainReels_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_localCornNum,6,nil,nil, true))
    self.m_MainReels_Corn:updateLabelSize({label=self.m_MainReels_Corn:findChild("m_lb_coins"),sx=0.5,sy=0.5},297)
    
    if selfdata.collectScore  then
        self.m_runSpinResultData.p_selfMakeData.collect = nil
    end
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_jackPotBar:setVisible(false)
        self.m_MainReels_Barn:setVisible(false)
        self.m_MainReels_Corn:setVisible(false)

        local freespinType = self:getFreeSpinType( )
        if freespinType ~= 0 then
            self.m_bottomUI:showAverageBet()
        end
        

    end

end



--
--单列滚动停止回调
--
function CodeGameScreenFarmMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 


    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        local isHaveGoldFixSymbol = false
        for iRow = 1, self.m_iReelRowNum do

            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG) 
            if targSp and targSp.p_symbolType and self:isFixSymbol(targSp.p_symbolType) then
                isHaveFixSymbol = true
                targSp:runAnim("buling",false,function(  )
                    targSp:runAnim("idleframe",true)
                end)

                if targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_BONUS_2 then
                    isHaveGoldFixSymbol = true
                end

            end
        end

        if isHaveGoldFixSymbol then
            -- 金色南瓜落地
            local soundPath =  "FarmSounds/music_Farm_GoldfixBonusDown.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end
        elseif isHaveFixSymbol == true  then
            -- respinbonus落地音效

            local soundPath =  "FarmSounds/music_Farm_fixBonusDown.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

        end

    end

end

---
-- 老虎机滚动结束调用
function CodeGameScreenFarmMachine:slotReelDown()

    BaseFastMachine.slotReelDown(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

--freespin下主轮调用父类停止函数
function CodeGameScreenFarmMachine:slotReelDownInFS( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    self:setGameSpinStage( STOP_RUN )
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]
            
            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end



    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()

    

    self:reelDownNotifyPlayGameEffect( )
end

function CodeGameScreenFarmMachine:reelDownNotifyPlayGameEffect( )
    self.gameEffectRunIngPause = false

    BaseFastMachine.reelDownNotifyPlayGameEffect(self)
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFarmMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFarmMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    
end
---------------------------------------------------------------------------

---
-- 显示free spin
function CodeGameScreenFarmMachine:showEffect_FreeSpin(effectData)

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
    if scatterLineValue ~= nil then        
        -- 

        -- self:visibleMaskLayer(true,true)            
        gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
        self:showFreeSpinView(effectData)

        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue        
    else
        -- 
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFarmMachine:showFreeSpinView(effectData)

    self.isInBonus = true

    gLobalSoundManager:playSound("FarmSounds/music_Farm_freespinStart.mp3")

    self.m_bottomUI:checkClearWinLabel()

    
    if effectData.p_BonusTrigger then

    else

        self:createLittleReels( )
        self:findChild("wheel_0"):setVisible(true)
        self.m_jackPotBar:setVisible(true)
        self.m_MainReels_Barn:setVisible(true)
        self.m_MainReels_Corn:setVisible(true)

        for i=1,#self.m_vecMiniWheel do
            local miniMachine = self.m_vecMiniWheel[i]
            miniMachine:getParent():setVisible(false)
        end

    end

    

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
    else
        self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

            local freespinType = self:getFreeSpinType( )
            if freespinType ~= 0 then
                self.m_bottomUI:showAverageBet()
            end

            if effectData.p_BonusTrigger then
                self:triggerFreeSpinCallFun()
                
                effectData.p_isPlay = true
                self:playGameEffect()  
            else


                    
                    gLobalSoundManager:setBackgroundMusicVolume(0)
                    gLobalSoundManager:playSound("FarmSounds/Farm_GuoChang.mp3")
                    self.m_GuoChang:setVisible(true)
                    self.m_GuoChang:runCsbAction("actionframe",false,function(  )
                        self.m_GuoChang:setVisible(false)
                        gLobalSoundManager:setBackgroundMusicVolume(1)
                    end)
    
                    performWithDelay(self,function(  )
                        self:findChild("wheel_0"):setVisible(false)
                        self.m_jackPotBar:setVisible(false)
                        self.m_MainReels_Barn:setVisible(false)
                        self.m_MainReels_Corn:setVisible(false)

                        for i=1,#self.m_vecMiniWheel do
                            local miniMachine = self.m_vecMiniWheel[i]
                            miniMachine:getParent():setVisible(true)
                        end
                        
                        self:triggerFreeSpinCallFun()
                        gLobalSoundManager:setBackgroundMusicVolume(0)
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                        
                    end,1) 
                

                

                
            end

            

                 
        end)
    end



end

function CodeGameScreenFarmMachine:createLittleReels( func )

    self:findChild("wheel_0"):setVisible(false)
    self.m_jackPotBar:setVisible(false)
    self.m_MainReels_Barn:setVisible(false)
    self.m_MainReels_Corn:setVisible(false)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local reels = selfdata.reel or 1
    local row = selfdata.row or 3
    self:initFsMiniReels(reels,row)
   

    -- 重新赋值一下
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    --小轮盘赋值
    for i=1,#self.m_vecMiniWheel do
        local miniMachine = self.m_vecMiniWheel[i]
            miniMachine:enterLevelMiniSelf()
    end 

    if func then
        func()
    end

    


end

function CodeGameScreenFarmMachine:showShopUnLockView(func)
    local ownerlist={}
    local view  = self:showDialog("BonusgameFieldUnlock",ownerlist,func,BaseDialog.AUTO_TYPE_NOMAL)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local page = selfdata.page
    view:findChild("img_ji"):setVisible(false)
    view:findChild("iimg_niu"):setVisible(false)
    view:findChild("img_zhu"):setVisible(false)
    view:findChild("img_yang"):setVisible(false)
    
    if page then
        if page == 1 then
            view:findChild("img_ji"):setVisible(true)

        elseif page == 2 then

            view:findChild("img_yang"):setVisible(true)
        elseif page == 3 then

            view:findChild("img_zhu"):setVisible(true)

        elseif page == 4 then
            
            view:findChild("iimg_niu"):setVisible(true)

        end
        
    end

end

function CodeGameScreenFarmMachine:showNormalFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num

    local view  = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)

    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    -- 更新列数
    local rowNumNode = view:findChild("reelsNum")
    if rowNumNode then
        local reelNum = selfdata.reel or 1
        rowNumNode:setString(reelNum)
    end

    -- 创建tipreels
    local lunpanNode = view:findChild("lunpan")
    if lunpanNode then
        lunpanNode:setScale(0.5)

        local data = {}
        data.m_reelNum = 1
        data.m_reelRow = selfdata.row or 3
        data.m_wildCols = selfdata.wildReels or {}

        local m_ReelsTip = util_createView("CodeFarmSrc.FarmBonus_ReelsTipView",data)
        lunpanNode:addChild(m_ReelsTip)
        
    end

    return view
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenFarmMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view = util_createView("CodeFarmSrc.FarmNormalBaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
        gLobalViewManager:showUI(view)
    -- end

    return view
end

function CodeGameScreenFarmMachine:showShopFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num

    local view  = self:showDialog("SuperFreeGameStart",ownerlist,func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    -- 更新列数
    local rowNumNode = view:findChild("reelsNum")
    if rowNumNode then
        local reelNum = selfdata.reel or 1
        rowNumNode:setString(reelNum)
    end

    local page = selfdata.page
    view:findChild("img_ji"):setVisible(false)
    view:findChild("iimg_niu"):setVisible(false)
    view:findChild("img_zhu"):setVisible(false)
    view:findChild("img_yang"):setVisible(false)
    
    if page then
        if page == 1 then
            view:findChild("img_ji"):setVisible(true)

        elseif page == 2 then

            view:findChild("img_yang"):setVisible(true)
        elseif page == 3 then

            view:findChild("img_zhu"):setVisible(true)

        elseif page == 4 then
            
            view:findChild("iimg_niu"):setVisible(true)

        end
        
    end

    -- 创建tipreels
    local lunpanNode = view:findChild("lunpan")
    if lunpanNode then
        lunpanNode:setScale(0.5)

        local data = {}
        data.m_reelNum = 1
        data.m_reelRow = selfdata.row or 3
        data.m_wildCols = selfdata.wildReels or {}

        local m_ReelsTip = util_createView("CodeFarmSrc.FarmBonus_ReelsTipView",data)
        lunpanNode:addChild(m_ReelsTip)
        
    end


    return view

end



function CodeGameScreenFarmMachine:showFreeSpinStart(num,func)
    
    local view = nil
    if self:getFreeSpinType() == 2 then

        view = self:showShopFreeSpinStart(num,func)
        view:setClickSound( "FarmSounds/music_Farm_start.mp3" )
    else

        view = self:showNormalFreeSpinStart(num,func)
        view:setClickSound( "FarmSounds/music_Farm_start.mp3" )
    end
     

    return view

end

function CodeGameScreenFarmMachine:showFreeSpinOver(freecoins,bonuscoins,totalcoins,func)
    self:clearCurMusicBg()

    local ownerlist={}
    
    ownerlist["m_lb_coins_free"]=util_formatCoins(freecoins, 30)
    ownerlist["m_lb_coins_bonus"]=util_formatCoins(bonuscoins, 30)
    ownerlist["m_lb_coins_total"]=util_formatCoins(totalcoins, 30)

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    view:setClickSound( "FarmSounds/music_Farm_Collect_1.mp3" )


    return view

end



function CodeGameScreenFarmMachine:showFreeSpinOverView()

    
   gLobalSoundManager:playSound("FarmSounds/music_Farm_freespinOver.mp3")
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freecoins = self.m_runSpinResultData.p_fsWinCoins
    local bonuscoins = selfdata.mapWin or 0
    local totalcoins = freecoins + bonuscoins

    -- 线上反馈问题-弹板结算赢钱时赢钱金额为0，但是freeSpin底栏的金额展示是没有问题的。
    if 0 == totalcoins then
        if 2 ~= DEBUG then
            local sTitel = "[CodeGameScreenFarmMachine:showFreeSpinOverView] "
            local sUser = " error_userInfo_ udid=" .. (globalData.userRunData.userUdid or "isnil") .. " machineName="..(globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. " gameSeqID = " .. (globalData.seqId or "")
            local sServer = " sever传回的数据：  "..(globalData.slotRunData.severGameJsonData or "isnil")
            local sSelfData = " 当前selfData 数据 = " .. cjson.encode(selfdata) .. " 当前fsWinCoins = " .. self.m_runSpinResultData.p_fsWinCoins

            local msg = sTitel .. sUser .. sServer .. sSelfData
            if util_sendToSplunkMsg then
                util_sendToSplunkMsg("Farm_1132_luaError",msg)
            end
        end
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) == true or self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) == true then --如果赢取倍数小于等于total bet 的1倍
        self.m_llBigOrMegaNum = totalcoins
    end
    

    local view = self:showFreeSpinOver( freecoins,bonuscoins,totalcoins,

        function()


                self.m_FreespinGameOver = true 

                gLobalSoundManager:setBackgroundMusicVolume(0)

                gLobalSoundManager:playSound("FarmSounds/Farm_GuoChang.mp3")
                self.m_GuoChang:setVisible(true)
                self.m_GuoChang:runCsbAction("actionframe",false,function(  )
                    self.m_GuoChang:setVisible(false)
                end)

                performWithDelay(self,function(  )

                    self.m_bottomUI:hideAverageBet()

                    self:triggerFreeSpinOverCallFun()

                    self.m_jackPotBar:setVisible(true)
                    self.m_MainReels_Barn:setVisible(true)
                    self.m_MainReels_Corn:setVisible(true)

                    

                    self:findChild("wheel_0"):setVisible(true)
                    self:removeAllMiniReels( )
                    self:updateBaseConfig()
                    
                    self:updateMachineData()
                    self:initFarmMachineData()

                    self:resetMusicBg(true)
                    gLobalSoundManager:setBackgroundMusicVolume(0)

                    performWithDelay(self,function(  )
                        gLobalSoundManager:setBackgroundMusicVolume(1)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
                        globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
                        
                    end,0.5)
                    
                end,1)

                


        end)
    local node_1 = view:findChild("m_lb_coins_free")
    view:updateLabelSize({label=node_1,sx=1,sy=1},724)

    local node_2 = view:findChild("m_lb_coins_bonus")
    view:updateLabelSize({label=node_2,sx=1,sy=1},724)

    local node_3 = view:findChild("m_lb_coins_total")
    view:updateLabelSize({label=node_3,sx=1,sy=1},724)

    


end

function CodeGameScreenFarmMachine:initFarmMachineData( )

    self.m_spinResultName = self.m_moduleName.."_Datas"
    
    


    globalData.slotRunData.gameModuleName = self.m_moduleName
    
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

function CodeGameScreenFarmMachine:triggerFreeSpinOverCallFun()

    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    if self.postFreeSpinOverTriggerBigWIn then
        self:postFreeSpinOverTriggerBigWIn( _coins) 
    end
    
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

    -- self:resetMusicBg(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)

    -- 添加 超级freespinOver 之后打开商城逻辑
    --自定义动画创建方式
    self:addSuperFreeSpinOverEffect( )

    
end

function CodeGameScreenFarmMachine:addSuperFreeSpinOverEffect( )
    
    if self:getFreeSpinType() == 2 then
        
        self.m_SupperGameOver = true

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SUPER_FREESPIN_OVER_EFFECT -- 动画类型
    end

    
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFarmMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.isInBonus = false

    if self.m_soundNode then
        self.m_soundNode:stopAllActions()
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
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
function CodeGameScreenFarmMachine:MachineRule_network_InterveneSymbolMap()
    
end

function CodeGameScreenFarmMachine:insetMiniReelsLines(data )
    if data  and type(data.lines) == "table" then

        if #data.lines > 0 then
           if type(self.m_runSpinResultData.p_winLines) ~=  "table" then
                self.m_runSpinResultData.p_winLines= {}
           end     
        end


        for i = 1, #data.lines do
            local lineData = data.lines[i]
            local winLineData = SpinWinLineData.new()
            winLineData.p_id = lineData.id
            winLineData.p_amount = 0
            winLineData.p_iconPos = {}
            winLineData.p_iconPosNew = lineData.icons
            winLineData.p_type = lineData.type
            winLineData.p_multiple = 1
            
            self.m_runSpinResultData.p_winLines[#self.m_runSpinResultData.p_winLines + 1] = winLineData
        end
    end
    
end

function CodeGameScreenFarmMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        
        self:compareScatterWinLines(winLines)

        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
            
            if lineInfo.iLineSymbolNum >=5 then
                isFiveOfKind=true
            end

            local iconsPosNew = winLineData.p_iconPosNew -- 其他副轮盘
            if iconsPosNew and #iconsPosNew >= 5 then
                isFiveOfKind=true
            end
            
            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function CodeGameScreenFarmMachine:netWorklineLogicCalculate()

    if #self.m_vecMiniWheel > 0 then
        if self.m_runSpinResultData.p_fsExtraData ~= nil  then
            local resultDatas = self.m_runSpinResultData.p_fsExtraData
            
            for i=1,#self.m_vecMiniWheel do
                if i == 1 then
                  

                else
                    local dataName = "reel-".. (i -1)

                    local miniReelsResultDatas = resultDatas[dataName]
                    self:insetMiniReelsLines(miniReelsResultDatas)
                end
            end          
        end
    end

    BaseFastMachine.netWorklineLogicCalculate(self)
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFarmMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end


function CodeGameScreenFarmMachine:getTableNum( array)
    local num = 0
    for k,v in pairs(array) do
        num = num + 1
    end

    return num
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFarmMachine:addSelfEffect()



        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local collect = selfdata.collect

        if collect and type(collect) == "table"   then
            if self:getTableNum( collect) ~= 0 then
                --自定义动画创建方式
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.COLLECT_CORN_EFFECT -- 动画类型
            end
        end
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFarmMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_CORN_EFFECT then

        self:collectCornFly( )
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.SUPER_FREESPIN_OVER_EFFECT  then
        
        
        performWithDelay(self,function(  )
            

            effectData.p_isPlay = true
            self:playGameEffect()
            
            self:showSupperCollectView(  )
            self:showShopUnLockView( )

            self.m_SupperGameOver = false

            
            
        end,1)
        
    end

    
	return true
end

function CodeGameScreenFarmMachine:getCollectData(reelsIndex)

    local isCollect = false
    local collectNum = nil

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    local collect = selfdata.collect

    if collect and type(collect) == "table"   then
        if self:getTableNum( collect) ~= 0 then
            for k,v in pairs(collect) do
                local index = tonumber(k)
                if reelsIndex == index then
                    isCollect = true
                    collectNum = v
                end
            end
        end
    end

    return isCollect,collectNum
end


-- 强制刷新玉米
function CodeGameScreenFarmMachine:forceRefreshCorn( )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

    self.m_localCornNum = selfdata.collectScore or 0
    self.m_MainReels_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_localCornNum,6,nil,nil, true))
    self.m_MainReels_Corn:updateLabelSize({label=self.m_MainReels_Corn:findChild("m_lb_coins"),sx=0.5,sy=0.5},297)

    if selfdata.collectScore then
        self.m_runSpinResultData.p_selfMakeData.collect = nil
    end
    

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do

                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node  then
                    --移除小块内的玉米
                    if node.m_Corn then
                        node.m_Corn:stopAllActions()
                        node.m_Corn:removeFromParent()
                        node.m_Corn = nil
                    end 

                end 
        end

    end


    local child = self.m_CornNode:getChildren()
    for i=1,#child do
        local corn = child[i]
        if corn then
            corn:stopAllActions()
            corn:removeFromParent() 
        end
        
    end 

    if self.m_FlayCorn then
        gLobalSoundManager:stopAudio(self.m_FlayCorn)
        self.m_FlayCorn = nil
    end

    scheduler.unschedulesByTargetName("farmCornFly")



    

    


end

-- 收集飞玉米动画
function CodeGameScreenFarmMachine:collectCornFly( )

    

    local flyTime = 0.5
    local actionframeTimes = 0.5
    local ParticleTimes = 0.5
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isCollect,collectNum = self:getCollectData(reelsIndex)

            if isCollect then
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node  then
                    
                     -- 对应位置创建好玉米
                    local newCorn =   util_createView("CodeFarmSrc.FarmCollect_ReelsCorn")
                    newCorn:starFly(actionframeTimes + flyTime )
                    
                    self.m_CornNode:addChild(newCorn)
                    newCorn:runCsbAction("actionframe") -- 播放创建好的玉米动画
                    local numStr = "x" .. collectNum
                    newCorn:findChild("m_lb_num"):setString(collectNum)

                    local pos = cc.p(util_getConvertNodePos(node.m_Corn,newCorn)) 
                    newCorn:setPosition(pos)
                    --移除小块内的玉米
                    if node.m_Corn then
                        node.m_Corn:stopAllActions()
                        node.m_Corn:removeFromParent()
                        node.m_Corn = nil
                    end 

                    
                    local endPos = cc.p(self:findChild("collect_gucang"):getPosition())
                    local actionList = {}
                    actionList[#actionList + 1] = cc.DelayTime:create(actionframeTimes)
                    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                        newCorn:runCsbAction("actionframe1") 
                    end)
                    -- actionList[#actionList + 1] = cc.MoveTo:create(flyTime,cc.p(endPos.x ,endPos.y ))
                    local startPos = cc.p(util_getConvertNodePos(newCorn,self:findChild("collect_gucang")))
                    local angle = 85
                    local height = 10
                    local radian = angle*math.pi/180
                    local q1x = startPos.x+(endPos.x - startPos.x)/4
                    local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
                    local q2x = startPos.x + (endPos.x - startPos.x)/2.0
                    local q2 = cc.p(q2x*1.2, height + startPos.y+math.cos(radian)*q2x)
                    actionList[#actionList + 1] = cc.EaseInOut:create(cc.BezierTo:create(actionframeTimes,{q1,q2,cc.p(endPos.x - 60 ,endPos.y - 30 )}),1)

                    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                        newCorn:findChild("imgNode"):setVisible(false)
                    end)
                    actionList[#actionList + 1] = cc.DelayTime:create(ParticleTimes)
                    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
                        newCorn:setVisible(false)
                        newCorn:removeFromParent()
                    end)
                    local sq = cc.Sequence:create(actionList)
                    newCorn:runAction(sq)
                        

    
                end 
            end

            

        end

    end

    self.m_FlayCorn = gLobalSoundManager:playSound("FarmSounds/music_Farm_corn_flying.mp3",false,function(  )
        self.m_FlayCorn = nil
    end)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local netCornNum = selfdata.collectScore or 0
    

    local waitTimes = flyTime + actionframeTimes + ParticleTimes

    
    scheduler.performWithDelayGlobal(function (  )
        -- 飞行完毕刷新等其他操作
        self.m_localCornNum = netCornNum
        -- 刷新玉米个数
        self.m_MainReels_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_localCornNum,6,nil,nil, true))
        self.m_MainReels_Corn:updateLabelSize({label=self.m_MainReels_Corn:findChild("m_lb_coins"),sx=0.5,sy=0.5},297)

        gLobalSoundManager:playSound("FarmSounds/music_Farm_corn_fly_end.mp3")
        -- 谷仓蹦
        util_spinePlay(self.m_MainReels_Barn.m_BarnSpineNode,"actionframe",false)
        self.m_MainReels_Corn:runCsbAction("actionframe")
        
        
    end,(waitTimes- ParticleTimes),"farmCornFly")



end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFarmMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


-- --------respin 相关

-- 是不是 respinBonus小块
function CodeGameScreenFarmMachine:isFixSymbol(symbolType)


    if symbolType == self.SYMBOL_FIX_BONUS_1 or 
        symbolType == self.SYMBOL_FIX_BONUS_2 or 
        symbolType == self.SYMBOL_FIX_BONUS_3 or 
        
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR  then
            return true
    end
    return false
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenFarmMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
        -- assert(score, "根据网络数据获得respinBonus小块的分数 是空的")
        -- 如果是空 那就用 self.SYMBOL_FIX_BONUS_1 随机的
        return self:randomDownRespinSymbolScore(self.SYMBOL_FIX_BONUS_1)
    end


    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR  then
        score = "MAJOR"
    end

    return score
end

function CodeGameScreenFarmMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_BONUS_1 or 
        symbolType == self.SYMBOL_FIX_BONUS_2 or 
        symbolType == self.SYMBOL_FIX_BONUS_3 then

            
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenFarmMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        -- print(score .. "信号 "..symbolNode)
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3,nil,nil, true)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score")then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
            
        end

        if symbolNode then
            symbolNode:runAnim("idleframe",true)
        end
        

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3,nil,nil, true)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score")then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
                symbolNode:runAnim("idleframe",true)
            end
        end
        
    end

end

function CodeGameScreenFarmMachine:updateReelGridNode(node)
    if self:isFixSymbol(node.p_symbolType) then
        self:setSpecialNodeScore(self,{node})
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
    end
    -- 收集玉米相关
    if node:isLastSymbol() then
        local reelsIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)
        local isCollect,collectNum = self:getCollectData(reelsIndex)
        if isCollect  then -- 收集玉米的网络 绝对位置
            if node.m_Corn == nil then
                -- 填加收集玉米
                node.m_Corn =  util_createView("CodeFarmSrc.FarmCollect_ReelsCorn")
                node:addChild(node.m_Corn,2)
                local numStr = "x" .. collectNum
                node.m_Corn:findChild("m_lb_num"):setString(collectNum)
                node.m_Corn:runCsbAction("idle")
            end
            
        end
        
    end
end


function CodeGameScreenFarmMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  self:isFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

    -- 收集玉米相关
    if node:isLastSymbol() then
        local reelsIndex = self:getPosReelIdx(row, col)
        local isCollect,collectNum = self:getCollectData(reelsIndex)
        if isCollect  then -- 收集玉米的网络 绝对位置
            if node.m_Corn == nil then
                -- 填加收集玉米
                node.m_Corn =  util_createView("CodeFarmSrc.FarmCollect_ReelsCorn")
                node:addChild(node.m_Corn,2)
                local numStr = "x" .. collectNum
                node.m_Corn:findChild("m_lb_num"):setString(collectNum)
                node.m_Corn:runCsbAction("idle")
            end
            
        end
        
    end
end


function CodeGameScreenFarmMachine:showRespinJackpot(index,coins,func)
    if index == 1 or index == 2 then
        gLobalSoundManager:playSound("FarmSounds/music_Farm_freespinOver.mp3")
        -- 只有grand 和 major 弹板
        local jackPotWinView = util_createView("CodeFarmSrc.FarmJackPotWinView")
        gLobalViewManager:showUI(jackPotWinView)
        jackPotWinView:initViewData(self,index,coins,func)
    else
        --通知jackpot
        globalData.jackpotRunData:notifySelfJackpot(coins,index)
        if func then
            func()
        end 

    end
    


end

-- 结束respin收集
function CodeGameScreenFarmMachine:playLightEffectEnd()
    
    -- 通知respin结束
    self:respinOver()
 
end

function CodeGameScreenFarmMachine:getNetJackpotScore(index)
    
    local winlines = self.m_runSpinResultData.p_winLines or {}
    local score = 0

    for i=1, #winlines do
        local values = winlines[i]
        if #values.p_iconPos == 1 and values.p_iconPos[1] == index then
            score = values.p_amount
        end
    end
    

    return score 
 
end


function CodeGameScreenFarmMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= 20 then
            local jackpotScore = self:getNetJackpotScore(-1)
            self.m_lightScore = self.m_lightScore + jackpotScore

            self:playCoinWinEffectUI()
            
            local coins = self.m_lightScore  
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
            globalData.slotRunData.lastWinCoin = lastWinCoin  

            self:showRespinJackpot(
                1,
                util_formatCoins(jackpotScore, 12,nil,nil, true),
                function()
                    self:playLightEffectEnd()        
                end
            )
        else

            scheduler.performWithDelayGlobal(function()
                self:playLightEffectEnd() 
            end, 17/30 , self:getModuleName())
            
            
        
        end
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            

    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self:getNetJackpotScore(self:getPosReelIdx(iRow ,iCol))
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif score == "MAJOR" then
            jackpotScore = self:getNetJackpotScore(self:getPosReelIdx(iRow ,iCol))
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "MINOR" then
            jackpotScore =  self:getNetJackpotScore(self:getPosReelIdx(iRow ,iCol))
            addScore =jackpotScore + addScore                  
            nJackpotType = 3
        elseif score == "MINI" then
            jackpotScore = self:getNetJackpotScore(self:getPosReelIdx(iRow ,iCol))  
            addScore =  jackpotScore + addScore                      
            nJackpotType = 4
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            

            self:playChipCollectAnim()    
            
        else
            self:showRespinJackpot(nJackpotType, util_formatCoins(jackpotScore,12,nil,nil, true), function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
            -- gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_jackpotwinframe.mp3")
        end
    end
    -- 添加鱼飞行轨迹
    local function fishFly()
            
            self:playCoinWinEffectUI()
          
            local coins = self.m_lightScore  
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
            globalData.slotRunData.lastWinCoin = lastWinCoin  

            fishFlyEndJiesuan()    

    end

    gLobalSoundManager:playSound("FarmSounds/Farm_FixBonus_WinCoins.mp3") 
    
    chipNode:runAnim("shouji")
    local nBeginAnimTime = chipNode:getAniamDurationByName("shouji")

    scheduler.performWithDelayGlobal(function()
        fishFly()      
    end, 0.4 , self:getModuleName())

    

    scheduler.performWithDelayGlobal(function()
        chipNode:runAnim("idleframe2")       
    end, nBeginAnimTime , self:getModuleName())

 
end



--结束移除小块调用结算特效
function CodeGameScreenFarmMachine:reSpinEndAction()    
    self.m_respinSpinbar:changeRespinTimes(0)

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    performWithDelay(self,function(  )
        self:playChipCollectAnim()
    end,1)
    

    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenFarmMachine:getRespinRandomTypes( )
    local symbolList = { self.SYMBOL_SCORE_10,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenFarmMachine:getRespinLockTypes( )
    local symbolList = {

        {type = self.SYMBOL_FIX_BONUS_1, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_BONUS_2, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_BONUS_3, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true}
    }



    return symbolList
end

function CodeGameScreenFarmMachine:showRespinView()

        self.isInBonus = true
        
        --先播放动画 再进入respin
        self:clearCurMusicBg()
      

        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )

        --可随机的特殊信号 
        local endTypes = self:getRespinLockTypes()




        local features =  self.m_runSpinResultData.p_features
        if features and #features == 2 and features[2] == RESPIN_MODE then
           -- 触发的那一次

                   -- 播放 respinbonus buling 动画
                    local ActionTime = 0
                    for icol = 1,self.m_iReelColumnNum do
                        for irow = 1, self.m_iReelRowNum do
                            local node = self:getFixSymbol(icol, irow, SYMBOL_NODE_TAG)
                            if node and node.p_symbolType and  self:isFixSymbol(node.p_symbolType) then
                               
                                self:createOneActionSymbol(node,"actionframe")
                                ActionTime = node:getAniamDurationByName("actionframe")
                            end
                        end
                    end
                    
                    gLobalSoundManager:playSound("FarmSounds/Farm_triggerRespin.mp3")

                    performWithDelay(self,function(  )
                        --构造盘面数据
                        self:triggerReSpinCallFun(endTypes, randomTypes) 
                    end,ActionTime + 1)

                    

        else


            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end
        


end


function CodeGameScreenFarmMachine:initRespinView(endTypes, randomTypes)
    
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
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                   self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)

end

function CodeGameScreenFarmMachine:respinStartFlyParticle( func )
        local hideTime = 0.4
        local flytime = 0.7
        local flyRespinParticle = hideTime + flytime

        gLobalSoundManager:playSound("FarmSounds/music_Farm_respinbar_show.mp3")

        self.m_respinSpinbar:changeRespinTimes(3,true)
        self.m_respinSpinbar:setVisible(true)
        self.m_respinSpinbar:runCsbAction("start")
        
        util_spinePlay(self.m_MainReels_Barn.m_BarnSpineNode,"fadeout",false)
        util_spineEndCallFunc(self.m_MainReels_Barn.m_BarnSpineNode, "fadeout", function(  )
            self.m_MainReels_Barn:setVisible(false)
        end)
            
        self.m_MainReels_Corn:runCsbAction("over",false,function(  )
            self.m_MainReels_Corn:setVisible(false)
        end)

        self.m_respinSpinbar:findChild("Node_respinTimes"):setVisible(false)
        self.m_respinSpinbar:changeGoldBonusCoins(0)

        performWithDelay(self,function(  )
            
            
            gLobalSoundManager:playSound("FarmSounds/music_Farm_fixBonus_flying.mp3")
            for icol = 1,self.m_iReelColumnNum do
                for irow = 1, self.m_iReelRowNum do
                    local node = self:getFixSymbol(icol, irow, SYMBOL_NODE_TAG)
                    if node and node.p_symbolType and  self:isFixSymbol(node.p_symbolType) then
                
                        self:AddGoldBonusCoinsParticle( flytime, node,self:findChild("RespinsRemaning") )
                    end
                end
            end
        end,hideTime)
            
        local waitTime =  flyRespinParticle
        performWithDelay(self,function(  )
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local bet = selfdata.amountMultiple or 0

            local lineBet = globalData.slotRunData:getCurTotalBet()
            local coins =  bet * lineBet
            self.m_respinSpinbar:changeGoldBonusCoins(coins)
            self.m_respinSpinbar:runCsbAction("jiesuan")

            
            gLobalSoundManager:playSound("FarmSounds/music_Farm_fixBonus_fly_end.mp3")

            performWithDelay(self,function(  )
                if func then
                    func()
                end 
            end,1.5)
            
        end,waitTime )
end

function CodeGameScreenFarmMachine:showReSpinStart(func)
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("FarmSounds/music_Farm_repsinstart.mp3")

    local features =  self.m_runSpinResultData.p_features
    if features and #features == 2 and features[2] == RESPIN_MODE then
        local courFunc = function(  )

            self:respinStartFlyParticle( func )

        end
        self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,courFunc,BaseDialog.AUTO_TYPE_NOMAL)
    else
        if func then
            func()
        end 
    end

    
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--ReSpin开始改变UI状态
function CodeGameScreenFarmMachine:changeReSpinStartUI(respinCount)

    self.m_bottomUI:checkClearWinLabel()
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bet = selfdata.amountMultiple or 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local coins =  bet * lineBet
    self.m_respinSpinbar:changeGoldBonusCoins(coins)

    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
    if not self.m_respinSpinbar:isVisible() then
        self.m_respinSpinbar:runCsbAction("start")
        self.m_respinSpinbar:setVisible(true)
    end

    if self.m_MainReels_Barn:isVisible() then

        gLobalSoundManager:playSound("FarmSounds/music_Farm_respinbar_show.mp3")

        util_spinePlay(self.m_MainReels_Barn.m_BarnSpineNode,"fadeout",false)
        util_spineEndCallFunc(self.m_MainReels_Barn.m_BarnSpineNode, "fadeout", function(  )
            self.m_MainReels_Barn:setVisible(false)
        end)
    end

    if self.m_MainReels_Corn:isVisible() then
        self.m_MainReels_Corn:runCsbAction("over",false,function(  )
            self.m_MainReels_Corn:setVisible(false)
        end)
    end
    
    
    gLobalSoundManager:playSound("FarmSounds/music_Farm_showRespinbar_littlebar.mp3")
    self.m_respinSpinbar:findChild("Node_respinTimes"):setVisible(true)
    self.m_respinSpinbar:runCsbAction("fadein")
    

end

--ReSpin刷新数量
function CodeGameScreenFarmMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)

    self.m_respinSpinbar:changeRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenFarmMachine:changeReSpinOverUI()
    
end

--结束移除小块调用结算特效
function CodeGameScreenFarmMachine:removeRespinNode()
    BaseFastMachine.removeRespinNode(self)
    for i=1,#self.m_slotParents do
        local slotParentData = self.m_slotParents[i]
        local slotParent = slotParentData.slotParent
        slotParent:setLocalZOrder(i)
    end
end


function CodeGameScreenFarmMachine:showRespinOverView(effectData)

    gLobalSoundManager:playSound("FarmSounds/music_Farm_linghtning_over_win.mp3")

    local strCoins=util_formatCoins(self.m_serverWinCoins,11,nil,nil, true)
    local view=self:showReSpinOver(strCoins,function()
        
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self:resetMusicBg() 

        self.m_respinSpinbar:runCsbAction("over",false,function(  )
            self.m_respinSpinbar:setVisible(false)
        end)
                        
        self.m_MainReels_Barn:setVisible(true)
        util_spinePlay(self.m_MainReels_Barn.m_BarnSpineNode,"fadein",false)

            
        self.m_MainReels_Corn:setVisible(true)
        self.m_MainReels_Corn:runCsbAction("start",false,function(  )
        end)



        
    end)
    view:setClickSound( "FarmSounds/music_Farm_Collect_2.mp3" )
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.5,sy=1.5},827)
end


-- --重写组织respinData信息
function CodeGameScreenFarmMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

function CodeGameScreenFarmMachine:checkShopShouldClick( )

    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount

    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true

    local isRunningEffect = self.m_isRunningEffect == true

    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRespin = self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true

    -- 返回true 不允许点击

    if self.m_isWaitingNetworkData  then
        return true

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return true

    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return true

    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then

        return true

    elseif self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        return true
    elseif self.m_BonusView then
        return true
    elseif self.m_SupperGameOver then
        return true
    elseif #featureDatas > 1 then
        return true

    elseif isAutoSpin then
        return true

    elseif isFreespin then
        return true

    elseif isRunningEffect then

        return true

    elseif isNormalNoIdle then

        return true

    elseif isFreespinOver then

        return true

    elseif isRespin then

        return true
    end

    return false
end



---
-- 检测上次feature 数据
--
function CodeGameScreenFarmMachine:checkCollectViewTriggerFeatures()

    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})

        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS

            local effect = self.m_gameEffects[#self.m_gameEffects]
            if not effect or (effect.p_effectType ~= GameEffect.EFFECT_BONUS and effect.p_effectType ~= false)  then
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

                self.m_isRunningEffect = true
                
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                    {SpinBtn_Type.BtnType_Spin,false})
            end

            

        end
    end

end

-- ---- 收集商城部分
function CodeGameScreenFarmMachine:showCollectView( func )


    if self.m_CollectShopView  then
        return 
    end

   
    --  如果是freespin结束 而且还有动画没有播完 就不让点
    if type(self.m_gameEffects) == "table"  then
        for i=1,#self.m_gameEffects do
            local effect = self.m_gameEffects[i]
            if effect then

                if effect.p_effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
                
                    if self.m_isRunningEffect then
                        return
                    end
                end
                
            end
        end
    end

    
    
    

    self:forceRefreshCorn( ) -- 强制刷新本地玉米

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end

    self.m_CollectShopView = util_createView("CodeFarmSrc.FarmCollect_View",self)
    self:addChild(self.m_CollectShopView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_CollectShopView:setEndCall( function(  )
        self.m_CollectShopView:removeFromParent()
        self.m_CollectShopView = nil
    end)

    self.m_CollectShopView:findChild("root"):setScale(self.m_machineRootScale * 0.95)


end

-- ---- 收集商城部分
function CodeGameScreenFarmMachine:showSupperCollectView( func )


    self:forceRefreshCorn( ) -- 强制刷新本地玉米

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end

    self.m_CollectShopView = util_createView("CodeFarmSrc.FarmCollect_View",self)
    self:addChild(self.m_CollectShopView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_CollectShopView:setEndCall( function(  )
        self.m_CollectShopView:removeFromParent()
        self.m_CollectShopView = nil
    end)

    self.m_CollectShopView:findChild("root"):setScale(self.m_machineRootScale * 0.95)


end

function CodeGameScreenFarmMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

-- ---- bonus路部分
function CodeGameScreenFarmMachine:showBonusView( func )

   

    performWithDelay(self,function(  )
        self:resetMusicBg(nil,"FarmSounds/Farm_bonusBg.mp3") 
        self.m_BonusView = util_createView("CodeFarmSrc.FarmBonus_View",self)
        self.m_BonusView:setName("m_BonusView")
        self:addChild(self.m_BonusView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
        self.m_BonusView:setVisible(false)
        self.m_BonusView:setEndCall( function(  )
            
            self.m_MainReels_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_localCornNum,6,nil,nil, true))
            self.m_MainReels_Corn:updateLabelSize({label=self.m_MainReels_Corn:findChild("m_lb_coins"),sx=0.5,sy=0.5},297)

            self:bonusOverAddFreespinEffect( )

            

            self:createLittleReels( ) 

            for i=1,#self.m_vecMiniWheel do
                local miniMachine = self.m_vecMiniWheel[i]
                miniMachine:getParent():setVisible(false)
            end

            gLobalSoundManager:setBackgroundMusicVolume(0)

            gLobalSoundManager:playSound("FarmSounds/Farm_GuoChang.mp3")
            self.m_GuoChang:setVisible(true)
            self.m_GuoChang:runCsbAction("actionframe",false,function(  )
                self.m_GuoChang:setVisible(false)
                gLobalSoundManager:setBackgroundMusicVolume(1)
                
            end)

            performWithDelay(self,function(  )
                self.m_bottomUI:setVisible(true)

                self:levelFreeSpinEffectChange()
                
                for i=1,#self.m_vecMiniWheel do
                    local miniMachine = self.m_vecMiniWheel[i]
                    miniMachine:getParent():setVisible(true)
                end

                if self.m_BonusView then
                    self.m_BonusView:removeFromParent()
                    self.m_BonusView = nil
                else
                    local BonusView = self:getChildByName("m_BonusView")
                    if BonusView  then
                        BonusView:removeFromParent()
                        BonusView = nil
                    end
                end
                
                performWithDelay(self,function(  )
                    if func then
                        func()
                    end
                end,0.1)
                
            end,1)

        end)

        gLobalSoundManager:setBackgroundMusicVolume(0)
        
        gLobalSoundManager:playSound("FarmSounds/Farm_GuoChang.mp3")
        self.m_GuoChang:setVisible(true)
        self.m_GuoChang:runCsbAction("actionframe",false,function(  )
            self.m_GuoChang:setVisible(false)
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)

        performWithDelay(self,function(  )
            self.m_bottomUI:setVisible(false)
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            self.m_jackPotBar:setVisible(false)
            self.m_MainReels_Barn:setVisible(false)
            self.m_MainReels_Corn:setVisible(false)

            self:findChild("wheel_0"):setVisible(false)
            self.m_BonusView:setVisible(true)
        end,1)

    end,0.1)
    
    

end
-- bonus start

---
-- 显示bonus 触发的小游戏
function CodeGameScreenFarmMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    self.isInBonus = true
    
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then

        if self.m_soundNode then
            self.m_soundNode:stopAllActions()
        end
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        
        self:showBonusAndScatterLineTip(bonusLineValue,function()
            self:showBonusGameView(effectData)
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效        
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenFarmMachine:showBonusGameView(effectData)


    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        self:showBonusStartView(function(  )

            self:showBonusView(function(  )
                effectData.p_isPlay = true
                self:playGameEffect()  
            end)
            
        end)    
    end,0.5)

    
end

function CodeGameScreenFarmMachine:showBonusStartView( func)

    

    gLobalSoundManager:playSound("FarmSounds/music_Farm_bonusStart.mp3")

    local function newFunc()
        if func then
            func()
        end
    end

    local ownerlist={}

    self:showDialog("BonusgameStart",ownerlist,newFunc,BaseDialog.AUTO_TYPE_NOMAL)


end


function CodeGameScreenFarmMachine:initFeatureInfo(spinData,featureData)

    if featureData.p_status == "OPEN" then
        -- 容错处理 不走bonusEffect
        self:removeEffectByType(GameEffect.EFFECT_BONUS )
        self.isInBonus = true
        self:showBonusView(function(  )
            self:playGameEffect()  
        end)
    end

   

end

function CodeGameScreenFarmMachine:removeAllMiniReels( )
    for i=1,#self.m_vecMiniWheel do
        local miniReel = self.m_vecMiniWheel[i]
        if miniReel then
            miniReel:removeFromParent()
        end
    end

    self.m_vecMiniWheel = {}
end

function CodeGameScreenFarmMachine:initFsMiniReels(reels,row)
    
    for i=1,reels do
         -- 创建轮子
         local name =  "wheel_".. row .. "x5_".. reels .. "_" .. i 
         local addNode =  self.m_csbOwner[name]

            if addNode then
                local data = {}
                data.index = row
                data.parent = self
                data.reelId = i
                data.csbPath =  "GameScreenFarm_".. row .. "x5"
                local miniMachine = util_createView("CodeFarmSrc.FarmMiniMachine" , data)
                addNode:addChild(miniMachine)
                table.insert( self.m_vecMiniWheel, miniMachine)
                if self.m_bottomUI.m_spinBtn.addTouchLayerClick  then
                    self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
                end
            end 

         
    end
end



function CodeGameScreenFarmMachine:beginReel()

    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_waitChangeReelTime = 0
        release_print("beginReel ... ")
    
        self:stopAllActions()
        self:requestSpinReusltData()   -- 临时注释掉
    
        -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
        self.m_nScatterNumInOneSpin = 0
        self.m_nBonusNumInOneSpin = 0
    
        --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
        local effectLen = #self.m_gameEffects
        for i = 1, effectLen, 1 do
            self.m_gameEffects[i] = nil
        end
    
        self:clearWinLineEffect()
        for i=1,#self.m_vecMiniWheel do
            local mninReel = self.m_vecMiniWheel[i]
            if mninReel then
                mninReel:beginMiniReel()
            end
        end
    else


        BaseFastMachine.beginReel(self)

    end
end


function CodeGameScreenFarmMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self,param)

    if param[1] == true then
        local spinData = param[2]
        print(cjson.encode(param[2])) 
        print("消息返回") 
        if spinData.action == "SPIN" then

            if self:getCurrSpinMode() == FREE_SPIN_MODE then

                self.m_FsDownTimes = 0

                if spinData.result.freespin and spinData.result.freespin.extra  then
                    local resultDatas = spinData.result.freespin.extra
                    

                    for i=1,#self.m_vecMiniWheel do

                        local mninReel = self.m_vecMiniWheel[i]
                        if i == 1 then
                            mninReel:netWorkCallFun(spinData.result)
                            mninReel.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果

                        else
                            local dataName = "reel-".. (i -1)

                            local miniReelsResultDatas = resultDatas[dataName]
                            miniReelsResultDatas.bet = spinData.result.bet
                            -- resultDatas.payLineCount = 80 -- 暂时写死，正常应该是服务器传这个值
                            miniReelsResultDatas.action = spinData.result.action 

                            mninReel:netWorkCallFun(miniReelsResultDatas)
                        end
                    end
                 
                end
            end

        end
    end

    
end

function CodeGameScreenFarmMachine:updateResultData(spinData )
    
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end


function CodeGameScreenFarmMachine:playEffectNotifyChangeSpinStatus( )

    BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
end

function CodeGameScreenFarmMachine:setFsAllRunDown(times )
    self.m_FsDownTimes = self.m_FsDownTimes + times

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local reels = selfdata.reel or 1

    if self.m_FsDownTimes >= reels then

        -- if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) and self:getCurrSpinMode() == FREE_SPIN_MODE then
        --     print("啥也不做")
        -- else
        --     BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
        -- end

        
        self.m_FsDownTimes = 0
    end
end


function CodeGameScreenFarmMachine:createOneActionSymbol(endNode,actionName)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node= util_createAnimation(endNode.m_ccbName..".csb")
    local func = function(  )
          if fatherNode then
                fatherNode:setVisible(true)
          end
          if node then
                node:removeFromParent()
          end
          
    end
    node:playAction(actionName,true,func)  
    local zorder = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("wheel_0"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("wheel_0"):addChild(node , 100000 + zorder)
    node:setPosition(pos)

    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local symbolIndex = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    local index = 0
    if score ~= nil and type(score) ~= "string" then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 3,nil,nil, true)
        local scoreNode = node:findChild("m_lb_score")
        if scoreNode then
            scoreNode:setString(score)
        end
    end
            

    return node
end


-- 处理特殊关卡 遮罩层级
function CodeGameScreenFarmMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder  + parentData.cloumnIndex)
end


function CodeGameScreenFarmMachine:createLocalAnimation( )
    local pos = cc.p(self.m_bottomUI.m_normalWinLabel:getPosition()) 
    
    self.m_respinEndActiom =  util_createView("CodeFarmSrc.FarmViewWinCoinsAction")
    self.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom,9999999)
    self.m_respinEndActiom:setPosition(cc.p(pos.x - 8,pos.y))

    self.m_respinEndActiom:setVisible(false)
end


--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function CodeGameScreenFarmMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end



function CodeGameScreenFarmMachine:resumeMachine()
    globalData.slotRunData.gameRunPause = nil
    if globalData.slotRunData.gameResumeFunc then
        globalData.slotRunData.gameResumeFunc()
    end
    globalData.slotRunData.gameResumeFunc = nil
    self.gameEffectRunPause = nil
end

function CodeGameScreenFarmMachine:checkGameResumeCallFun( )
    if self:checkGameRunPause() then
        self.gameEffectRunPause = true -- 播放动画暂停
        globalData.slotRunData.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end


function CodeGameScreenFarmMachine:playEffectNotifyNextSpinCall( )

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

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or 
    self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local delayTime = 0.5
       
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            
            local lines =nil 
            if self.m_vecMiniWheel and #self.m_vecMiniWheel > 0 then
                lines = self.m_vecMiniWheel[1]:getResultLines()
            end
             

            if lines ~= nil and #lines > 0 then
                
                delayTime = delayTime + self:getWinCoinTime()
                if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
                    if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                        delayTime = 0.5
                    end
                end
            end

        else
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

function CodeGameScreenFarmMachine:reelSchedulerHanlder(delayTime)
    if self:checkGameRunPause()  then
        self.gameEffectRunIngPause = true -- 没有滚动结束那就意味着还没开始播放完动画，那么如果商城中了 freespin就不用 调用 playeffect
        self.gameEffectRunPause = true
    end
    BaseFastMachine.reelSchedulerHanlder(self,delayTime)
end

function CodeGameScreenFarmMachine:AddGoldBonusCoinsParticle( times, startNode,endNode,func )

    local flyParticle = util_createView("CodeFarmSrc.FarmBonus_AddFsPartacleView")   
    flyParticle:starFly(times)
    self.m_root:addChild(flyParticle,1000)
    local startPos = cc.p(util_getConvertNodePos(startNode,flyParticle))
    flyParticle:setPosition(startPos)

    local endPos = cc.p(util_getConvertNodePos(endNode,flyParticle))

    local animation = {}
    -- animation[#animation + 1] = cc.MoveTo:create(times, cc.p(endPos))
    local angle = 85
    local height = 10
    local radian = angle*math.pi/180
    local q1x = startPos.x+(endPos.x - startPos.x)/4
    local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
    local q2x = startPos.x + (endPos.x - startPos.x)/2.0
    local q2 = cc.p(q2x*1.2, height + startPos.y+math.cos(radian)*q2x)
    animation[#animation + 1] = cc.EaseInOut:create(cc.BezierTo:create(times,{q1,q2,cc.p(endPos.x,endPos.y - 30 )}),1)

    animation[#animation + 1] = cc.CallFunc:create(function(  )
        

            if func then
                func()
            end
            
    end)
    animation[#animation + 1] = cc.DelayTime:create(times)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        flyParticle:removeFromParent()
        flyParticle = nil
    end)

    flyParticle:runAction(cc.Sequence:create(animation))

end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenFarmMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()

    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end


function CodeGameScreenFarmMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel  then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE  then
        self:showLineFrame()
    else 
        self:checkNotifyUpdateWinCoin( )
    end
    

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true

end

---
-- 点击快速停止reel
--
function CodeGameScreenFarmMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self:getCurrSpinMode() == FREE_SPIN_MODE then

    else
        BaseFastMachine.quicklyStopReel(self,colIndex)
    end
    


end


return CodeGameScreenFarmMachine






