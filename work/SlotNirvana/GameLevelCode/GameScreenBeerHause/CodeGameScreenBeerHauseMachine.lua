---
-- island li
-- 2019年1月26日
-- CodeGameScreenBeerHauseMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotsBeerHauseNode = require "CodeBeerHauseSrc.BeerHauseSlotsNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"


local CodeGameScreenBeerHauseMachine = class("CodeGameScreenBeerHauseMachine", BaseFastMachine)

CodeGameScreenBeerHauseMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenBeerHauseMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenBeerHauseMachine.WILD_COL_CHANGE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 整列变wild
CodeGameScreenBeerHauseMachine.ADD_FS_MORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- Add FS MORE times


CodeGameScreenBeerHauseMachine.SYMBOL_FSMORE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 -- 101 freespin + 1  暂时加的容错处理，按理说不应该出现这个信号
CodeGameScreenBeerHauseMachine.SYMBOL_FSMORE_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- 102 freespin + 1
CodeGameScreenBeerHauseMachine.SYMBOL_FSMORE_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 -- 103 freespin + 2
CodeGameScreenBeerHauseMachine.SYMBOL_FSMORE_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 -- 104 freespin + 3
CodeGameScreenBeerHauseMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94 bonus

CodeGameScreenBeerHauseMachine.SYMBOL_WILD_GOLD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20 


CodeGameScreenBeerHauseMachine.m_vecMiniWheel = {} -- mini轮盘列表
CodeGameScreenBeerHauseMachine.m_BarrelNodeList = {} -- 酒桶列表
CodeGameScreenBeerHauseMachine.m_TapNodeList = {} -- 水龙头列表

CodeGameScreenBeerHauseMachine.m_redBonusTipPos = {6,8} -- 红色提示位置
CodeGameScreenBeerHauseMachine.m_blueBonusTipPos = {1,3,11,13} -- 蓝色提示位置
CodeGameScreenBeerHauseMachine.m_redBonusTipNodeList = {} -- 红色
CodeGameScreenBeerHauseMachine.m_blueBonusTipNodeList = {} -- 蓝色

CodeGameScreenBeerHauseMachine.m_WildKuangViewList = {} -- Wild变化时亮的框

CodeGameScreenBeerHauseMachine.m_longWildViewList = {} -- longWild


CodeGameScreenBeerHauseMachine.m_bonusView = nil -- bonus页面

CodeGameScreenBeerHauseMachine.m_triggerBonusActionTimes = 6.1 
CodeGameScreenBeerHauseMachine.m_addFsTimesActionTimes = 3

CodeGameScreenBeerHauseMachine.m_norDownTimes = 0
CodeGameScreenBeerHauseMachine.m_FsDownTimes = 0
CodeGameScreenBeerHauseMachine.m_soundList = {}


local hightLowBet = true
CodeGameScreenBeerHauseMachine.m_betLevel = nil -- betlevel 0 1 

local normalAuxiliaryReelid = 2
local freespinMainReelid = 3
local freespinAuxiliaryReelid = 4

-- 构造函数
function CodeGameScreenBeerHauseMachine:ctor()
    BaseFastMachine.ctor(self)
    

	--init
	self:initGame()
end


--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenBeerHauseMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i >= 3 then
            soundPath = "BeerHauseSounds/BeerHause_scatter_down.mp3"
        else
            soundPath = "BeerHauseSounds/BeerHause_scatter_down.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
        self.m_bonusBulingSoundArry[#self.m_bonusBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenBeerHauseMachine:initGame()

	--初始化基本数据
    self:initMachine(self.m_moduleName)
    
    self.m_vecMiniWheel = {}
    self.m_bonusView = nil

    self.m_BarrelNodeList = {} -- 酒桶列表
    self.m_TapNodeList = {} -- 水龙头列表
    self.m_redBonusTipNodeList = {} -- 红色
    self.m_blueBonusTipNodeList = {} -- 蓝色
    self.m_WildKuangViewList = {}
    self.m_norDownTimes = 0
    self.m_FsDownTimes = 0

    self.m_longWildViewList = {} -- longWild

    --限定 bonus 出现的列(只适用于这一关，做了特殊处理)
    self.m_ScatterShowCol = {2,3,4}

    self.m_soundList = {}


    self.m_betLevel = nil

    self.isInBonus = false
    self.m_isFeatureOverBigWinInFree = true

end  

---
-- 获取游戏区域reel height 这些都是在ccb中配置的 custom properties 属性， 但是目前无法从ccb读取，
-- cocos2dx 未开放接口
--
function CodeGameScreenBeerHauseMachine:getReelHeight()
    return 600
end

function CodeGameScreenBeerHauseMachine:getReelWidth()
    return 1150
end

function CodeGameScreenBeerHauseMachine:scaleMainLayer()
    
    BaseFastMachine.scaleMainLayer(self)

    local mainScale = self.m_machineRootScale
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        mainScale = 0.85
    elseif ratio < 768/1024 and ratio >= 640/960 then
         mainScale = 0.90 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
    end
    if display.width < 1370 then
        mainScale = mainScale * 0.9
    end
    self.m_machineRootScale = mainScale
    util_csbScale(self.m_machineNode, mainScale)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBeerHauseMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BeerHause"  
end

function CodeGameScreenBeerHauseMachine:updateReels( )
    
    for i=1,4 do
        -- 创建3个轮子
        local name = "wheel_".. i  
        local addNode =  self.m_csbOwner[name]
        addNode:setVisible(false)
        local miniReels = self.m_vecMiniWheel[i]

        if miniReels then
            miniReels:clearWinLineEffect()
        end
       
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if i >2 then
                addNode:setVisible(true)
            end
        else
            if i <3 then
                addNode:setVisible(true)
            end
        end
        
    end

    

end

function CodeGameScreenBeerHauseMachine:initMiniMachine( )
    for i=1,4 do
        if i == 1 then
            table.insert( self.m_vecMiniWheel, self)
        else
            -- 创建3个轮子
            local name = "wheel_".. i 
            local addNode =  self.m_csbOwner[name]
            if addNode then
                local data = {}
                data.index = i
                data.parent = self
                local miniMachine = util_createView("CodeBeerHauseSrc.BeerHauseMiniMachine" , data)
                addNode:addChild(miniMachine)
                table.insert( self.m_vecMiniWheel, miniMachine)
                
                if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
                    self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
                end
                
            end 
            
        end
        
    end

    self:updateReels( )
end

function CodeGameScreenBeerHauseMachine:showHightLowBetView( )

    self.m_hightLowbetView:setVisible(true)
    self.m_hightLowbetView:stopAllActions()

    self.m_hightLowbetView:runCsbAction("show",false,function(  )
        performWithDelay(self.m_hightLowbetView,function(  )
            self.m_hightLowbetView:runCsbAction("over",false,function(  )
                self.m_hightLowbetView:setVisible(false)
            end)
        end,3)
    end)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_hightLowbetView:setVisible(false)
    end

    if self.isInBonus then
        self.m_hightLowbetView:setVisible(false)
    end
    
    
end

function CodeGameScreenBeerHauseMachine:initUI()


    -- 创建view节点方式
    -- self.m_BeerHauseView = util_createView("CodeBeerHauseSrc.BeerHauseView")
    -- self:findChild("xxxx"):addChild(self.m_BeerHauseView)
    
    -- 初始化小轮子
    self:initMiniMachine()

    self:initWineBarrel( )

    self:createBonusTipNode( )
    
    self:initFreeSpinBar() -- FreeSpinbar
    if self.m_baseFreeSpinBar then
        self.m_baseFreeSpinBar:findChild("m_lb_num"):setString("")
    end
    


    self.m_BeerHauseGuoChangView = util_createView("CodeBeerHauseSrc.BeerHauseGuoChangView")
    self:addChild(self.m_BeerHauseGuoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_BeerHauseGuoChangView:setPosition(display.width/2,display.height/2)
    self.m_BeerHauseGuoChangView:setVisible(false)
    -- self.m_BeerHauseGuoChangView:runCsbAction("actionframe",true) 
    

    self.m_LogoView = util_createView("CodeBeerHauseSrc.BeerHauseLogoView")
    self:findChild("logo"):addChild(self.m_LogoView)
    

    
    self:findChild("Node_tittle"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 2)


    --高低bet选择
    self.m_hightLowbetView = util_createView("CodeBeerHauseSrc.BeerHauseHightLowbetView")
    self:addChild(self.m_hightLowbetView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    local pos = self:getThreeReelsTarSpPos(8)
    local worldPos = self:findChild("wheel_1"):convertToWorldSpace(cc.p(pos))
    local newpos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self.m_hightLowbetView:setPosition(cc.p(newpos))
    self.m_hightLowbetView:setVisible(false)
    -- self.m_hightLowbetView:initMachine(self)

    
 
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
        elseif winRate > 3 then
            soundIndex = 3
        end
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "BeerHauseSounds/BeerHause_wincoins_".. soundIndex .. ".mp3"
        local winSoundsId = gLobalSoundManager:playSound(soundName)

        performWithDelay(self,function(  )

            gLobalSoundManager:setBackgroundMusicVolume(1)
            self:removeWinSound( winSoundsId)

        end,soundIndex)

        table.insert( self.m_soundList, winSoundsId )
        
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBeerHauseMachine:stopAllWinSound( )
    for i=#self.m_soundList,1,-1 do
        local sound = self.m_soundList[i]
        if sound then
            gLobalSoundManager:stopAudio(sound)
        end
    end
    self.m_soundList = {}
end

function CodeGameScreenBeerHauseMachine:removeWinSound( id)

    for i=#self.m_soundList,1,-1 do
        local sound = self.m_soundList[i]
        if sound then
            if sound == id then
                table.remove( self.m_soundList, i)
            end
        end
    end

end


function CodeGameScreenBeerHauseMachine:enterGamePlayMusic(  )
  
    if not self.isInBonus then
        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_enterLevel.mp3")
    end
    
    scheduler.performWithDelayGlobal(function (  )
        if not self.isInBonus then
            self:resetMusicBg()
            self:setMinMusicBGVolume()
        end
        
    end,3.5,self:getModuleName())

end

function CodeGameScreenBeerHauseMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:upateBetLevel()

    for i=2,4 do
        local miniMachine = self.m_vecMiniWheel[i]
        miniMachine:enterLevelMiniSelf()
    end
end

function CodeGameScreenBeerHauseMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self, self.slotReelDownInFS,"ReelDownInFS")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
   end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenBeerHauseMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBeerHauseMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_FSMORE_1 then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_FSMORE_2 then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_FSMORE_3 then
        return "Socre_BeerHause_Bonus"
    elseif symbolType == self.SYMBOL_FIX_BONUS then
        return "Socre_BeerHause_FixBonus"
    elseif symbolType == self.SYMBOL_FSMORE then
        return "Socre_BeerHause_Bonus"   

    elseif symbolType == self.SYMBOL_WILD_GOLD then
        return "Socre_BeerHause_Wild_Gold"   
    end  

    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBeerHauseMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_GOLD,count =  2}

    
    

    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenBeerHauseMachine:addBonusEffectOutLines( )
    -- 断线重连添加bonus游戏事件
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    -- 如果已经添加过bonus游戏事件那就不添加了
    -- 这种状态说明是刚触发的状态
    for i=1,#self.m_gameEffects do
        local effect = self.m_gameEffects[i]
        if effect.p_effectType == GameEffect.EFFECT_BONUS then
            return
        end
    end

    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加自定义 bonus effect 
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_isOutLInes = true 
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})


            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end
        end
    end
end

-- 断线重连 
function CodeGameScreenBeerHauseMachine:MachineRule_initGame(  )

    self:updateReels( )

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        
        self:addBonusEffectOutLines( )

    else
        self.m_hightLowbetView:setVisible(false)
    end
    


end

--
--单列滚动停止回调
--
function CodeGameScreenBeerHauseMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 

    for iCol = 1, self.m_iReelColumnNum  do
        if iCol == reelCol then
            for iRow = self.m_iReelRowNum , 1, -1 do
                local targSp = self:getReelParentChildNode(iCol,iRow) 
                if targSp then
                    if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        targSp:runIdleAnim() 
                    end
                end
                
            end
        end
        
    end
   
end

---
-- 老虎机滚动结束调用
function CodeGameScreenBeerHauseMachine:slotReelDown()
    BaseFastMachine.slotReelDown(self) 
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

--freespin下主轮调用父类停止函数
function CodeGameScreenBeerHauseMachine:slotReelDownInFS( )
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


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBeerHauseMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBeerHauseMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关

---
-- 显示free spin
function CodeGameScreenBeerHauseMachine:showEffect_FreeSpin(effectData)

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
        --self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)            
            gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        --end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue        
        -- 播放提示时播放音效        
        self:playScatterTipMusicEffect()
    else
        -- 
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
-- FreeSpinstart
function CodeGameScreenBeerHauseMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BeerHauseSounds/music_BeerHause_custom_enter_fs.mp3")

    local showFreeSpinView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                    self.isInBonus = true

                    self:triggerFreeSpinCallFun()
                    self:updateReels( )
                    effectData.p_isPlay = true
                    self:playGameEffect()       
            end)
        end
    end
    showFreeSpinView()    
end

function CodeGameScreenBeerHauseMachine:showFreeSpinStart(num,func)
    -- local ownerlist={}
    -- ownerlist["m_lb_num"]=num
    -- return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)

    if func then
        func()
    end
end

---
-- 显示free spin over 动画
function CodeGameScreenBeerHauseMachine:showEffect_FreeSpinOver()


    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    
    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")
    if #self.m_reelResultLines == 0 then
        self.m_freeSpinOverCurrentTime = 1
    end
    
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
        self.m_fsOverHandlerID =scheduler.scheduleGlobal(function()
            if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
                self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
            else
                self:showEffect_newFreeSpinOver()
            end
        end,0.1)
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenBeerHauseMachine:triggerFreeSpinOverCallFun()

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

    -- self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenBeerHauseMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fsOver_show.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_guochang.mp3")
            self.m_BeerHauseGuoChangView:setVisible(true)
            self.m_BeerHauseGuoChangView:runCsbAction("actionframe",false,function(  )
                self.m_BeerHauseGuoChangView:setVisible(false)
                self:resetMusicBg()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
                
                performWithDelay(self,function(  )
                    -- 改变成auto状态
                    if globalData.slotRunData.m_isAutoSpinAction and globalData.slotRunData.m_autoNum >0 then
                        globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end,1)
                
            end) 

            performWithDelay(self,function(  )
                self:triggerFreeSpinOverCallFun()
                self:updateReels( )
            end,1.5)
        
        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},584)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBeerHauseMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.isInBonus = false
    self.m_norDownTimes = 0
    self.m_FsDownTimes = 0


    self.m_hightLowbetView:stopAllActions()
    self.m_hightLowbetView:setVisible(false)

    self:stopAllWinSound( )

    


    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenBeerHauseMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 刷新freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
      
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBeerHauseMachine:addSelfEffect()

     
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local triggerFSMore = false
        for iCol = 1, self.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelColumnNum  do
            for iRow = self.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelRowNum , 1, -1 do
                local targSp = self.m_vecMiniWheel[freespinAuxiliaryReelid]:getReelParentChildNode(iCol,iRow)--:getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
               if targSp then
                    if  targSp.p_symbolType == self.SYMBOL_FSMORE
                        or targSp.p_symbolType == self.SYMBOL_FSMORE_1 
                            or targSp.p_symbolType == self.SYMBOL_FSMORE_2 
                                or targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                            
                                    triggerFSMore = true

                                    break
                    end 
               end
                
            end
        end

        for iCol = 1, self.m_vecMiniWheel[freespinMainReelid].m_iReelColumnNum  do
            for iRow = self.m_vecMiniWheel[freespinMainReelid].m_iReelRowNum , 1, -1 do
                local targSp = self.m_vecMiniWheel[freespinMainReelid]:getReelParentChildNode(iCol,iRow) --:getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                if targSp then
                    if targSp.p_symbolType == self.SYMBOL_FSMORE
                        or targSp.p_symbolType == self.SYMBOL_FSMORE_1 
                            or targSp.p_symbolType == self.SYMBOL_FSMORE_2 
                                or targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                            
                                    triggerFSMore = true

                                    break
                    end
                end
                
            end
        end

        if triggerFSMore then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_FS_MORE_EFFECT -- 动画类型
        end



        if self.m_runSpinResultData.p_fsExtraData then
            local wildCol = self.m_runSpinResultData.p_fsExtraData.wildColumns
            if wildCol and #wildCol > 0 then
                -- 整列变wild
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.WILD_COL_CHANGE_EFFECT -- 动画类型
            end
    
        end

    else

        if self.m_runSpinResultData.p_selfMakeData then
            local wildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
            if wildCol and #wildCol > 0 then
                -- 整列变wild
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.WILD_COL_CHANGE_EFFECT -- 动画类型
            end
    
        end
    end
        

end

function CodeGameScreenBeerHauseMachine:freespinMainReelTrigger(trigger_reels_1,trigger_reels_1_node,wildCols ,func)
    for i=1,#trigger_reels_1_node do
        local sp = trigger_reels_1_node[i]
        if sp then
            sp:runAnim("actionframe")
            self.m_vecMiniWheel[freespinMainReelid]:createOneCSbActionSymbol(sp,"actionframe",true)
        end
    end

    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fixBonus_zhongjiang.mp3")

    local fixTriggerTimes = 2.9
    local longWildAct = 4.17
    local waitTimes = 0.5
    local tongJumpTimes = 1

    performWithDelay(self,function(  )
        
        local reelsA = function(  )
            for i=1,#wildCols do
                local col = wildCols[i] + 1 
                
                self.m_vecMiniWheel[freespinMainReelid]:showOneLongWild(col )
                self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
            end
    
            performWithDelay(self,function(  )
                for i=1,#wildCols do
                    local col = wildCols[i] + 1 
                    self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe3")   
                end
    
            end,2.56)
            
            performWithDelay(self,function(  )
    
    
                self.m_vecMiniWheel[freespinMainReelid]:hideAllLongWild()
                self.m_vecMiniWheel[freespinMainReelid]:hideAllKuang( )
                self.m_vecMiniWheel[freespinMainReelid]:playWildColumnAct(wildCols)
                
            end,longWildAct)
        end
        
        local reelsB = function(  )
             -- 复制轮盘变化
            for i=1,#wildCols do
                local col = wildCols[i] + 1
                self.m_vecMiniWheel[freespinMainReelid]:showOneKuang(col )
                self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneKuang(col )
                self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
            end

            gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_barrel_jump.mp3")

            performWithDelay(self,function(  )
                -- 复制轮盘变化
                for i=1,#wildCols do
                    local col = wildCols[i] + 1 
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneLongWild(col )
                end

                gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_changeCol_6.mp3")

                performWithDelay(self,function(  )
                    for i=1,#wildCols do
                        local col = wildCols[i] + 1 
                        self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe3")

                    end
                end,2.56)
                
                performWithDelay(self,function(  )

                    for i=1,#wildCols do
                        local col = wildCols[i] + 1 
                        self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                        self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                    end

                    
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllKuang( )
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllLongWild()


                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:playWildColumnAct(wildCols)

                    performWithDelay(self,function(  )
                        if func then
                            func()
                        end
                    end,waitTimes)
                    
                end,longWildAct)


                reelsA()

            end,tongJumpTimes)
        end
       

        -- 动画开始
        reelsB()
        

    end,fixTriggerTimes)
end

function CodeGameScreenBeerHauseMachine:freespinAuxiliaryReelTrigger(trigger_reels_2,trigger_reels_2_node,wildCols ,func)
    for i=1,#trigger_reels_2_node do
        local sp = trigger_reels_2_node[i]
        if sp then
            sp:runAnim("actionframe")
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:createOneCSbActionSymbol(sp,"actionframe",true)
        end
    end

    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fixBonus_zhongjiang.mp3")
    

    local fixTriggerTimes = 2.9
    local longWildAct = 4.17
    local waitTimes = 0.5
    local tongJumpTimes = 1

    local reelsA = function(  )
        
        for i=1,#wildCols do
            local col = wildCols[i] +1
            
            self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneLongWild(col )
        end

        performWithDelay(self,function(  )
            for i=1,#wildCols do
                local col = wildCols[i] + 1 
                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe3")   
            end
        end,2.56)

        performWithDelay(self,function(  )

            self.m_vecMiniWheel[freespinAuxiliaryReelid]:playWildColumnAct(wildCols)
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllKuang( )
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllLongWild()
            
        end,longWildAct)
    end

    local reelsB = function(  )
        
        -- 复制轮盘动画
        for i=1,#wildCols do
            local col = wildCols[i] + 1
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneKuang(col )
            self.m_vecMiniWheel[freespinMainReelid]:showOneKuang(col )
            self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
            self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
            self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
            self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
        end
        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_barrel_jump.mp3")

        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_changeCol_6.mp3")

            for i=1,#wildCols do
                local col = wildCols[i] +1
                self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
                self.m_vecMiniWheel[freespinMainReelid]:showOneLongWild(col )
            end

            performWithDelay(self,function(  )

                for i=1,#wildCols do
                    local col = wildCols[i] + 1 
                    self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe3")
                end
    
            end,2.56)
    
            performWithDelay(self,function(  )
    
                for i=1,#wildCols do
                    local col = wildCols[i] + 1 
                    self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("idle")
                    
                end
    
                -- self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllKuang( )
                self.m_vecMiniWheel[freespinMainReelid]:hideAllKuang( )
                self.m_vecMiniWheel[freespinMainReelid]:hideAllLongWild()
    
    
                self.m_vecMiniWheel[freespinMainReelid]:playWildColumnAct(wildCols)
    
                performWithDelay(self,function(  )
                    if func then
                        func()
                    end
                end,waitTimes)
                
            end,longWildAct)


            reelsA()
    
        end,tongJumpTimes)
    end

    performWithDelay(self,function(  )
        
        -- 动画开始
        reelsB()

    end,fixTriggerTimes)

end

function CodeGameScreenBeerHauseMachine:freespinMainReel_BothTrigger(trigger_reels_1,trigger_reels_1_node,wildCols ,func,sameWildsCol)
    for i=1,#trigger_reels_1_node do
        local sp = trigger_reels_1_node[i]
        if sp then
            sp:runAnim("actionframe")

            if sp.id == freespinMainReelid then
                self.m_vecMiniWheel[freespinMainReelid]:createOneCSbActionSymbol(sp,"actionframe",true)
            else
                self.m_vecMiniWheel[freespinAuxiliaryReelid]:createOneCSbActionSymbol(sp,"actionframe",true)
            end
            
            
        end
    end
    if func then
        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fixBonus_zhongjiang.mp3")
    end
    

    local isSameCol = function( col )
        for i=1,#sameWildsCol do
            local sameIcol = sameWildsCol[i] + 1
            if col == sameIcol then
                return true
            end

        end

        return false
    end

    local fixTriggerTimes = 2.9
    local longWildAct = 4.17
    local waitTimes = 0.5
    local tongJumpTimes = 1

    local reelsA = function(  )
        for i=1,#wildCols do
            local col = wildCols[i] + 1 
            
            self.m_vecMiniWheel[freespinMainReelid]:showOneLongWild(col )
            self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
        end

        performWithDelay(self,function(  )
            for i=1,#wildCols do
                local col = wildCols[i] + 1 
                self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe3")   
            end
        end,2.56)
        
        performWithDelay(self,function(  )


            self.m_vecMiniWheel[freespinMainReelid]:hideAllLongWild()
            self.m_vecMiniWheel[freespinMainReelid]:hideAllKuang( )
            self.m_vecMiniWheel[freespinMainReelid]:playWildColumnAct(wildCols)
           
        end,longWildAct)
    end

    local reelsB = function(  )

            -- 复制轮盘变化
            tongJumpTimes = 0

            for i=1,#wildCols do
                local col = wildCols[i] + 1

                if not isSameCol(col) then
                    tongJumpTimes = 1
                    self.m_vecMiniWheel[freespinMainReelid]:showOneKuang(col )
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneKuang(col )
                    self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                    self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
                end 
                
            end

            if tongJumpTimes > 0 then
                if func then
                    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_barrel_jump.mp3")
                end
                
            end


            performWithDelay(self,function(  )
                -- 复制轮盘变化
                longWildAct = 0

                for i=1,#wildCols do
                    local col = wildCols[i] + 1 
                    if not isSameCol(col) then

                        longWildAct = 4.17

                        self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
                        self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneLongWild(col )
                    end
                    
                end

                if longWildAct > 0 then
                    if func then
                        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_changeCol_6.mp3")
                    end
                    
                end

                performWithDelay(self,function(  )
        
                    if longWildAct > 0 then
                        for i=1,#wildCols do
                            local col = wildCols[i] + 1 

                            if not isSameCol(col) then
                                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe3")
                            end
                            
                            
                        end
                    end
                end,2.56)
                
                performWithDelay(self,function(  )

                    if longWildAct > 0 then
                        for i=1,#wildCols do
                            local col = wildCols[i] + 1 

                            if not isSameCol(col) then
                                self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                                self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("idle")
                               
                            end
                            
                            
                        end
                    end
                    

                   
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllKuang( )
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllLongWild()


                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:playWildColumnAct(wildCols)

                    performWithDelay(self,function(  )
                        if func then
                            func()
                        end
                    end,waitTimes)
                    
                end,longWildAct)


                reelsA()

            end,tongJumpTimes)
            

    end

    performWithDelay(self,function(  )


        reelsB()
    
    end,fixTriggerTimes)

end

function CodeGameScreenBeerHauseMachine:freespinAuxiliaryReel_BothTrigger(trigger_reels_2,trigger_reels_2_node,wildCols ,func,sameWildsCol)
    for i=1,#trigger_reels_2_node do
        local sp = trigger_reels_2_node[i]
        if sp then
            sp:runAnim("actionframe")

            if sp.id == freespinMainReelid then
                self.m_vecMiniWheel[freespinMainReelid]:createOneCSbActionSymbol(sp,"actionframe",true)
            else
                self.m_vecMiniWheel[freespinAuxiliaryReelid]:createOneCSbActionSymbol(sp,"actionframe",true)
            end
        end
    end

    if func then
        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fixBonus_zhongjiang.mp3")
    end

    

    local isSameCol = function( col )
        for i=1,#sameWildsCol do
            local sameIcol = sameWildsCol[i] + 1
            if col == sameIcol then
                return true
            end

        end

        return false
    end
    

    local fixTriggerTimes = 2.9
    local longWildAct = 4.17
    local waitTimes = 0.5
    local tongJumpTimes = 1

    local reelsA = function(  )
        for i=1,#wildCols do
            local col = wildCols[i] +1
            
            self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneLongWild(col )
        end

        performWithDelay(self,function(  )
            for i=1,#wildCols do
                local col = wildCols[i] + 1 
                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe3")   
            end
        end,2.56)

        performWithDelay(self,function(  )

            self.m_vecMiniWheel[freespinAuxiliaryReelid]:playWildColumnAct(wildCols)
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllKuang( )
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllLongWild()

        end,longWildAct)
    end

    local reelsB = function(  )
            -- 复制轮盘动画
            tongJumpTimes = 0
            for i=1,#wildCols do
                local col = wildCols[i] + 1
                if not isSameCol(col) then
                    tongJumpTimes = 1
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:showOneKuang(col )
                    self.m_vecMiniWheel[freespinMainReelid]:showOneKuang(col )
                    self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                    self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
                    self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
                end 
            end

            if tongJumpTimes > 0 then
                if func then
                    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_barrel_jump.mp3")
                end
                
            end
            performWithDelay(self,function(  )
                 longWildAct = 0

                for i=1,#wildCols do
                    local col = wildCols[i] +1
                    if not isSameCol(col) then
                        longWildAct = 4.17
                        self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
                        self.m_vecMiniWheel[freespinMainReelid]:showOneLongWild(col ) 
                    end
                   
                end

                if longWildAct > 0 then
                    if func then
                        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_changeCol_6.mp3")
                    end
                    
                end

                performWithDelay(self,function(  )
                    if longWildAct > 0 then
                        for i=1,#wildCols do
                            local col = wildCols[i] + 1 

                            if not isSameCol(col) then
                                self.m_vecMiniWheel[freespinMainReelid].m_TapNodeList[col]:runCsbAction("actionframe3")
                            end
                            
                            
                        end
                    end
                end,2.56)
        
                performWithDelay(self,function(  )

                    if longWildAct > 0 then
                        for i=1,#wildCols do
                            local col = wildCols[i] + 1 

                            if not isSameCol(col) then
                                self.m_vecMiniWheel[freespinMainReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                                self.m_vecMiniWheel[freespinAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("idle")
                            end
                            
                            
                        end
                    end
        
                    
        
                    -- self.m_vecMiniWheel[freespinAuxiliaryReelid]:hideAllKuang( )
                    self.m_vecMiniWheel[freespinMainReelid]:hideAllKuang( )
                    self.m_vecMiniWheel[freespinMainReelid]:hideAllLongWild()
        
        
                    self.m_vecMiniWheel[freespinMainReelid]:playWildColumnAct(wildCols)
        
                    performWithDelay(self,function(  )
                        if func then
                            func()
                        end
                    end,waitTimes)
                    
                end,longWildAct)

                reelsA()
        
            end,tongJumpTimes)

    end

    performWithDelay(self,function(  )
 
        reelsB()
    end,fixTriggerTimes)
end

function CodeGameScreenBeerHauseMachine:istriggerBonus( col ,row)

    local istrigger = true

    if row > 3 then
        istrigger = false
    end

    if col == 1 or col == 3 or col == 5 then
        istrigger = false
    end

    return istrigger

end

function CodeGameScreenBeerHauseMachine:playSelfEffectInFreespin(func )
    local wildCols = self.m_runSpinResultData.p_fsExtraData.wildColumns
    local trigger_reels_1 = nil
    local trigger_reels_2 = nil

    local trigger_reels_1_node = {}
    local trigger_reels_2_node = {}

    local MainReelCols = {}
    local AuxiliaryCols = {}

    -- 去重
    local isSameCol = function( col,array )
        for i=1,#array do
            local sameIcol = array[i]
            if col == sameIcol then
                return true
            end

        end

        return false
    end

    
    for iCol = 1, self.m_vecMiniWheel[freespinMainReelid].m_iReelColumnNum  do
        for iRow = self.m_vecMiniWheel[freespinMainReelid].m_iReelRowNum , 1, -1 do

            if self:istriggerBonus(iCol,iRow) then
                local targSp = self.m_vecMiniWheel[freespinMainReelid]:getReelParentChildNode(iCol,iRow)
                if targSp and targSp.p_symbolType then
                    if targSp.p_symbolType == self.SYMBOL_FIX_BONUS  then
                        trigger_reels_1 = freespinMainReelid
                        table.insert( trigger_reels_1_node, targSp)

                        local index = self.m_vecMiniWheel[freespinMainReelid]:getPosReelIdx(iRow, iCol)

                        for i=1,#self.m_vecMiniWheel[freespinMainReelid].m_redBonusTipPos  do
                            local pos = self.m_vecMiniWheel[freespinMainReelid].m_redBonusTipPos[i]
                            if index == pos then
                                if iCol == 2 then
                                   local belevel =  self:getBetLevel( )
                                   if belevel and belevel == 0  then
                                        local col = 2
                                        if not isSameCol(col,MainReelCols) then
                                            table.insert( MainReelCols,col-1  )
                                        end
                                   else
                                        for i=1,3 do
                                            local col = i
                                            if not isSameCol(col,MainReelCols) then
                                                table.insert( MainReelCols,col-1  )
                                            end
                                        end

                                   end

                                    
                                else
                                    local belevel =  self:getBetLevel( )
                                    if belevel and belevel == 0  then
           
                                        local col = 4
                                        if not isSameCol(col,MainReelCols) then
                                            table.insert( MainReelCols,col-1  )
                                        end
                                    else
                                        for i=1,3 do
                                            local col = i + 2
                                            if not isSameCol(col,MainReelCols) then
                                                table.insert( MainReelCols,col-1  )
                                            end
                                        end
 
                                    end

                                    
                                end
                                
                                
                            end
                        end

                        for i=1,#self.m_vecMiniWheel[freespinMainReelid].m_blueBonusTipPos do
                            local pos = self.m_vecMiniWheel[freespinMainReelid].m_blueBonusTipPos[i]

                            if index == pos then
                                if iCol == 2 then
                                    local col =  2
                                    if not isSameCol(col,MainReelCols) then
                                        table.insert( MainReelCols, col-1)
                                    end
                                else
                                    local col = 4
                                    if not isSameCol(col,MainReelCols) then
                                        table.insert( MainReelCols, col-1)
                                    end
                                    
                                end
                                
                            end
                        end
                    end
                end
            end
            
             
        end
    end

    for iCol = 1, self.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelColumnNum  do
        for iRow = self.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelRowNum , 1, -1 do
            if self:istriggerBonus(iCol,iRow) then
                local targSp = self.m_vecMiniWheel[freespinAuxiliaryReelid]:getReelParentChildNode(iCol,iRow)

                if targSp and targSp.p_symbolType then
                    if targSp.p_symbolType == self.SYMBOL_FIX_BONUS then
                        trigger_reels_2 = freespinAuxiliaryReelid
                        table.insert( trigger_reels_2_node, targSp)

                        local index = self.m_vecMiniWheel[freespinAuxiliaryReelid]:getPosReelIdx(iRow, iCol)
                        for i=1,#self.m_vecMiniWheel[freespinAuxiliaryReelid].m_redBonusTipPos  do
                            local pos = self.m_vecMiniWheel[freespinAuxiliaryReelid].m_redBonusTipPos[i]
                            if index == pos then
                                if iCol == 2 then

                                    local belevel =  self:getBetLevel( )
                                    if belevel and belevel == 0  then
                                            local col = 2
                                            if not isSameCol(col,AuxiliaryCols) then
                                                table.insert( AuxiliaryCols, col-1)
                                            end
                                    else
                                            for i=1,3 do
                                                local col = i
                                                if not isSameCol(col,AuxiliaryCols) then
                                                    table.insert( AuxiliaryCols, col-1)
                                                end
                                            end

                                    end

                                    
                                else
                                    local belevel =  self:getBetLevel( )
                                    if belevel and belevel == 0  then
                                            local col = 4
                                            if not isSameCol(col,AuxiliaryCols) then
                                                table.insert( AuxiliaryCols,col-1  )
                                            end
                                    else
                                        for i=1,3 do
                                            local col = i + 2
                                            if not isSameCol(col,AuxiliaryCols) then
                                                table.insert( AuxiliaryCols,col-1  )
                                            end
                                            
                                        end

                                    end

                                    
                                end
                                
                            end
                        end
        
                        for i=1,#self.m_vecMiniWheel[freespinAuxiliaryReelid].m_blueBonusTipPos do
                            local pos = self.m_vecMiniWheel[freespinAuxiliaryReelid].m_blueBonusTipPos[i]
        
                            if index == pos then
                                if iCol == 2 then
                                    local col =  2
                                    if not isSameCol(col,AuxiliaryCols) then
                                        table.insert( AuxiliaryCols, col-1 )
                                    end
                                    
                                else
                                    local col = 4
                                    if not isSameCol(col,AuxiliaryCols) then
                                        table.insert( AuxiliaryCols, col-1)
                                    end
                                    
                                end
                                
                            end
                        end
                    end
                end
            end

            
        end
    end

    

    if trigger_reels_1 and trigger_reels_2 then
        local samecol = {}
        for i=1,#MainReelCols do
            local MainCol = MainReelCols[i]
            for k=1,#AuxiliaryCols do
                local AuxiliaryCol = AuxiliaryCols[k]
                if MainCol == AuxiliaryCol then
                    if not isSameCol(col,samecol) then
                        table.insert( samecol, MainCol )
                    end
                    
                end
            end
        end

        local func1= nil
        local func2= nil

        local MainNotAllInSame = false
        
        for i=1,#MainReelCols do
            local MainCol = MainReelCols[i]

            for k =1,#samecol do
                local sameIcol = samecol[i]
                if MainCol ~= sameIcol then
                    MainNotAllInSame = true
                    break 
                end
            end
            
        end
        
        local nodelist = {}

        for i=1,#trigger_reels_1_node do
            trigger_reels_1_node[i].id = freespinMainReelid
            table.insert( nodelist, trigger_reels_1_node[i] )
        end
        for i=1,#trigger_reels_2_node do
            trigger_reels_2_node[i].id = freespinAuxiliaryReelid
            table.insert( nodelist, trigger_reels_2_node[i] )
        end

        if MainNotAllInSame then
            func1 = func
            if trigger_reels_1 then
                self:freespinMainReel_BothTrigger(trigger_reels_1,nodelist,wildCols ,func1,{})
                
            end
        else
            func2 = func
            if trigger_reels_2 then
                self:freespinAuxiliaryReel_BothTrigger(trigger_reels_2,nodelist,wildCols ,func2,{})
            end
        end

       
       

        


    else

        if trigger_reels_1 then

            self:freespinMainReelTrigger(trigger_reels_1,trigger_reels_1_node,wildCols ,func)
            
        end

        if trigger_reels_2 then
            self:freespinAuxiliaryReelTrigger(trigger_reels_2,trigger_reels_2_node,wildCols ,func)
        end
    end
    
end

function CodeGameScreenBeerHauseMachine:playWildColumnAct(wildCols )
    for i=1,#wildCols do
        local iCol = wildCols[i] + 1
        for iRow = 1, self.m_iReelRowNum do

            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
        
            if targSp.p_symbolType then
                    targSp:changeCCBByName(
                            self:getSymbolCCBNameByType(self, self.SYMBOL_WILD_GOLD),
                            self.SYMBOL_WILD_GOLD
                        )
            end

        end

    end
end

function CodeGameScreenBeerHauseMachine:playSelfEffectInNormal(func )
    local wildCols = self.m_runSpinResultData.p_selfMakeData.wildColumns

    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fixBonus_zhongjiang.mp3")

    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum , 1, -1 do
           if self:istriggerBonus(iCol,iRow) then
                local targSp = self:getReelParentChildNode(iCol,iRow)
                if targSp and targSp.p_symbolType then
                    if targSp.p_symbolType == self.SYMBOL_FIX_BONUS then
                        targSp:runAnim("actionframe")

                        self:createOneCSbActionSymbol(targSp,"actionframe",true)
                    end
                end
           end 
            
             
        end
    end

    local fixTriggerTimes = 2.9
    local longWildAct = 4.17
    local waitTimes = 0.5
    local tongJumpTimes = 1
    local longWildAct_1 = 4.17


    local reelsA = function(  )
        for i=1,#wildCols do
            local col = wildCols[i] + 1
            
            self:showOneLongWild(col )
            self.m_TapNodeList[col]:runCsbAction("actionframe2")
        end

        performWithDelay(self,function(  )
            for i=1,#wildCols do
                local col = wildCols[i] + 1 
                self.m_TapNodeList[col]:runCsbAction("actionframe3")
            end
        end,2.56)

        performWithDelay(self,function(  )

            for i=1,#wildCols do
                local col = wildCols[i] + 1 
                self.m_BarrelNodeList[col]:runCsbAction("idle")
            end

            self:hideAllKuang( )
            self:hideAllLongWild()
            self:playWildColumnAct(wildCols)

        end,longWildAct_1)
    end

    local reelsB = function(  )
            performWithDelay(self,function(  )

            
                gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_barrel_jump.mp3")

                for i=1,#wildCols do
                    local col = wildCols[i] + 1
                    self.m_vecMiniWheel[normalAuxiliaryReelid]:showOneKuang(col )
                    self:showOneKuang(col )
                    self.m_BarrelNodeList[col]:runCsbAction("actionframe")
                    self.m_vecMiniWheel[normalAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("actionframe")
                    self.m_TapNodeList[col]:runCsbAction("actionframe1")
                    self.m_vecMiniWheel[normalAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe1")
                end
                
                performWithDelay(self,function(  ) 

                    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_changeCol_6.mp3")
                    -- 复制轮盘
                    for i=1,#wildCols do
                        local col = wildCols[i] + 1
                        self.m_vecMiniWheel[normalAuxiliaryReelid]:showOneLongWild(col )
                        self.m_vecMiniWheel[normalAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe2")
                    end

                    performWithDelay(self,function(  )
                        for i=1,#wildCols do
                            local col = wildCols[i] + 1 
                            self.m_vecMiniWheel[normalAuxiliaryReelid].m_TapNodeList[col]:runCsbAction("actionframe3")
                            
                        end
                    end,2.56)

                    performWithDelay(self,function(  )

                        for i=1,#wildCols do
                            local col = wildCols[i] + 1 
                            self.m_BarrelNodeList[i]:runCsbAction("idle")
                            self.m_vecMiniWheel[normalAuxiliaryReelid].m_BarrelNodeList[col]:runCsbAction("idle")
                            self.m_TapNodeList[col]:runCsbAction("idle")      
                        end

                        self.m_vecMiniWheel[normalAuxiliaryReelid]:hideAllKuang( )
                        self.m_vecMiniWheel[normalAuxiliaryReelid]:hideAllLongWild()


                        self.m_vecMiniWheel[normalAuxiliaryReelid]:playWildColumnAct(wildCols)

                        performWithDelay(self,function(  )
                            if func then
                                func()
                            end
                        end,waitTimes)
                            
                    end,longWildAct)


                    reelsA()

                end,tongJumpTimes)

                
            end,fixTriggerTimes)
    end

    -- 动画开始
    reelsB()

    
end

function CodeGameScreenBeerHauseMachine:addFreespinTimes(effectData )
    for iCol = 1, self.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelColumnNum  do
        for iRow = self.m_vecMiniWheel[freespinAuxiliaryReelid].m_iReelRowNum , 1, -1 do
            local targSp = self.m_vecMiniWheel[freespinAuxiliaryReelid]:getReelParentChildNode(iCol,iRow)

            if targSp and targSp.p_symbolType then
                if targSp.p_symbolType == self.SYMBOL_FSMORE_1 then
                    targSp:runAnim("actionframe",false,function(  )
                        targSp:runAnim("idleframe",true)
                    end)

                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:createOneActionSymbol(targSp,"actionframe2")
                elseif targSp.p_symbolType == self.SYMBOL_FSMORE_2 then
                    targSp:runAnim("actionframe",false,function(  )
                        targSp:runAnim("idleframe",true)
                    end)

                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:createOneActionSymbol(targSp,"actionframe3")
                elseif targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                    targSp:runAnim("actionframe",false,function(  )
                        targSp:runAnim("idleframe",true)
                    end)

                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:createOneActionSymbol(targSp,"actionframe4")
                end 
            end
        end
    end

    for iCol = 1, self.m_vecMiniWheel[freespinMainReelid].m_iReelColumnNum  do
        for iRow = self.m_vecMiniWheel[freespinMainReelid].m_iReelRowNum , 1, -1 do
            local targSp = self.m_vecMiniWheel[freespinMainReelid]:getReelParentChildNode(iCol,iRow)
            if targSp and targSp.p_symbolType then
                if targSp.p_symbolType == self.SYMBOL_FSMORE_1 then
                    targSp:runAnim("actionframe",false,function(  )
                        targSp:runAnim("idleframe",true)
                    end)

                    self.m_vecMiniWheel[freespinMainReelid]:createOneActionSymbol(targSp,"actionframe2")
                elseif targSp.p_symbolType == self.SYMBOL_FSMORE_2 then
                    targSp:runAnim("actionframe",false,function(  )
                        targSp:runAnim("idleframe",true)
                    end)

                    self.m_vecMiniWheel[freespinMainReelid]:createOneActionSymbol(targSp,"actionframe3")
                elseif targSp.p_symbolType == self.SYMBOL_FSMORE_3 then
                    targSp:runAnim("actionframe",false,function(  )
                        targSp:runAnim("idleframe",true)
                    end)

                    self.m_vecMiniWheel[freespinMainReelid]:createOneActionSymbol(targSp,"actionframe4")
                end 
            end
             
        end
    end

    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_fsMore_zhongjiang.mp3")

    performWithDelay(self,function(  )
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

    end,2)

    performWithDelay(self,function(  )

        self.m_vecMiniWheel[freespinMainReelid]:changeEffectToPlayed(self.ADD_FS_MORE_EFFECT )
        self.m_vecMiniWheel[freespinAuxiliaryReelid]:changeEffectToPlayed(self.ADD_FS_MORE_EFFECT )

        effectData.p_isPlay = true
        self:playGameEffect()
    end,self.m_addFsTimesActionTimes)
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBeerHauseMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.WILD_COL_CHANGE_EFFECT then

      if self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:playSelfEffectInFreespin(function(  )

            self.m_vecMiniWheel[freespinMainReelid]:changeEffectToPlayed(self.WILD_COL_CHANGE_EFFECT )
            self.m_vecMiniWheel[freespinAuxiliaryReelid]:changeEffectToPlayed(self.WILD_COL_CHANGE_EFFECT )

            effectData.p_isPlay = true
            self:playGameEffect()
        end )
      else
        self:playSelfEffectInNormal( function(  )
            self.m_vecMiniWheel[normalAuxiliaryReelid]:changeEffectToPlayed(self.WILD_COL_CHANGE_EFFECT )

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
      end 

        

    elseif effectData.p_selfEffectType ==  self.ADD_FS_MORE_EFFECT then
        -- 只出现在freespin中
        

        self:addFreespinTimes(effectData)
        
    end

    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBeerHauseMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenBeerHauseMachine:changeAddLines( )
    local isAdd = false
    local ishaveBonus = false

    for i=1,#self.m_runSpinResultData.p_winLines do
        local line = self.m_runSpinResultData.p_winLines[i]

       if line.p_type == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            ishaveBonus = true

            break
       end  
    end

    if ishaveBonus and (#self.m_runSpinResultData.p_winLines == 1 ) then
        isAdd = true
    end

    return isAdd
end

function CodeGameScreenBeerHauseMachine:insetMiniReelsLines(data )
    if data  and type(data.lines) == "table" then

        if #data.lines > 0 then
           if type(self.m_runSpinResultData.p_winLines) ~=  "table" then
                self.m_runSpinResultData.p_winLines= {}
           end     
        end

        -- 里面有线就不用塞了
        if #self.m_runSpinResultData.p_winLines > 0 and (not self:changeAddLines( )) then
            return
        end


        for i = 1, #data.lines do
            local lineData = data.lines[i]
            local winLineData = SpinWinLineData.new()
            winLineData.p_id = lineData.id
            winLineData.p_amount = lineData.amount
            winLineData.p_iconPos = {}
            winLineData.p_type = lineData.type
            winLineData.p_multiple = lineData.multiple
            
            self.m_runSpinResultData.p_winLines[#self.m_runSpinResultData.p_winLines + 1] = winLineData
        end
    end
    
end


function CodeGameScreenBeerHauseMachine:MachineRule_network_InterveneSymbolMap( )
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.extraReelsResult ~= nil then
            local resultDatas = self.m_runSpinResultData.p_selfMakeData.extraReelsResult
            self:insetMiniReelsLines(resultDatas)
        end
    end
    
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function CodeGameScreenBeerHauseMachine:netWorklineLogicCalculate()

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.netWorklineLogicCalculate(self)
    else

        self:checkAndClearVecLines()
        self.m_iFreeSpinTimes = 0
    
        --计算连线之前将 计算连线中添加的动画效果移除 (防止重新计算连线后效果播放错误)
        self:removeEffectByType(GameEffect.EFFECT_FREE_SPIN)
        self:removeEffectByType(GameEffect.EFFECT_BONUS )
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
        -- 根据features 添加具体玩法 
        self:MachineRule_checkTriggerFeatures()
        self:staticsQuestEffect()
    end

    
end


--[[
    @desc: 网络消息返回后， 做的处理
    time:2018-11-29 17:24:15
    @return:
]]
function CodeGameScreenBeerHauseMachine:produceSlots()

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.produceSlots(self)
    else
        -- 计算连线数据
        self:netWorklineLogicCalculate()
        self:MachineRule_afterNetWorkLineLogicCalculate()
    end
   

end

function CodeGameScreenBeerHauseMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self,param)

    if param[1] == true then
        local spinData = param[2]
        print(cjson.encode(param[2])) 
        print("消息返回") 
        if spinData.action == "SPIN" then

            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                if spinData.result.selfData ~= nil and spinData.result.selfData.extraReelsResult ~= nil then
                    local resultDatas = spinData.result.selfData.extraReelsResult
                    resultDatas.bet = spinData.result.bet
                    resultDatas.payLineCount = 80 -- 暂时写死，正常应该是服务器传这个值
                    resultDatas.action = spinData.result.action --"NORMAL"
                    self.m_vecMiniWheel[normalAuxiliaryReelid]:netWorkCallFun(resultDatas)
                end
            else
                if spinData.result.freespin ~= nil and spinData.result.freespin.extra and spinData.result.freespin.extra.extraReelsResult ~= nil then
                    local resultDatas = spinData.result.freespin.extra.extraReelsResult
                    resultDatas.bet = spinData.result.bet
                    resultDatas.payLineCount = 80 -- 暂时写死，正常应该是服务器传这个值
                    resultDatas.action = spinData.result.action -- "NORMAL"
                    self.m_vecMiniWheel[freespinAuxiliaryReelid]:netWorkCallFun(resultDatas)
                    self.m_vecMiniWheel[freespinMainReelid]:netWorkCallFun(spinData.result)
                    self.m_vecMiniWheel[freespinMainReelid].m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果

                    
                end
            end

        end
    end

    
end

function CodeGameScreenBeerHauseMachine:operaNetWorkData( )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Stop,true})

        self:setGameSpinStage( GAME_MODE_ONE_RUN )
    else
        BaseFastMachine.operaNetWorkData(self)
    end
   
end

function CodeGameScreenBeerHauseMachine:beginReel()

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
        
        self.m_vecMiniWheel[freespinMainReelid]:beginMiniReel()
        self.m_vecMiniWheel[freespinAuxiliaryReelid]:beginMiniReel()
        self.m_vecMiniWheel[freespinMainReelid]:setWheelStates(true)
        self.m_vecMiniWheel[freespinAuxiliaryReelid]:setWheelStates(true)
        self.m_vecMiniWheel[normalAuxiliaryReelid]:setWheelStates(false)
    else

        -- self.m_vecMiniWheel[freespinMainReelid]:setWheelStates(false)
        -- self.m_vecMiniWheel[freespinAuxiliaryReelid]:setWheelStates(false)
        self.m_vecMiniWheel[normalAuxiliaryReelid]:setWheelStates(true)
        self.m_vecMiniWheel[normalAuxiliaryReelid]:beginMiniReel()

        BaseFastMachine.beginReel(self)

    end
end

-- 初始化上次游戏状态数据
--
function CodeGameScreenBeerHauseMachine:initGameStatusData(gameData)
    
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

    local freeGameCost = gameData.freeGameCost

    local spin = gameData.spin
    -- spin = nil
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

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        -- if gameData.spin then
        --     if gameData.spin.selfData then
        --         if gameData.spin.selfData.extraReelsResult then
        --             local data = {}
        --             data.spin = gameData.spin.selfData.extraReelsResult
        --             self.m_vecMiniWheel[freespinAuxiliaryReelid]:initMiniGameStatusData(data)
        --         end
        --     end  
        --   end
        
    else
        if gameData.spin then
          if gameData.spin.selfData then
              if gameData.spin.selfData.extraReelsResult then
                local data = {}
                data.spin = gameData.spin.selfData.extraReelsResult
                self.m_vecMiniWheel[normalAuxiliaryReelid]:initMiniGameStatusData(data)
              end
          end  
        end
        
    end
    
    
    self:initMachineGame()
end

-- 初始化酒桶UI
function CodeGameScreenBeerHauseMachine:initWineBarrel( )

    self.m_BarrelNodeList = {}
    self.m_TapNodeList = {}
    for i=1,5 do
        local nodeBarrel = self:findChild("tong"..i)
        local barrelView = util_createView("CodeBeerHauseSrc.BeerHauseBarrelView")
        nodeBarrel:addChild(barrelView)
        table.insert( self.m_BarrelNodeList, barrelView )

        local nodetap =  self:findChild("longtou"..i) 
        nodetap:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 150 )
        local tapView = util_createView("CodeBeerHauseSrc.BeerHauseWaterTapView")
        nodetap:addChild(tapView)
        
        table.insert( self.m_TapNodeList, tapView )
    end

end

function CodeGameScreenBeerHauseMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        self:resetMaskLayerNodes()
        callFun()
    end,util_max(self.m_triggerBonusActionTimes,animTime),self:getModuleName())
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenBeerHauseMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = #lineValue.vecValidMatrixSymPos or lineValue.iLineSymbolNum

    local animTime = 0
    
    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent

        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
    
                        break
                    end
                end
                
            end
        end

        if slotNode ~= nil then--这里有空的没有管
           
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenBeerHauseMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.m_hightLowbetView:setVisible(false)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
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
    -- 停掉所有音效
    gLobalSoundManager:stopAllAuido()

    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil and not effectData.p_isOutLInes then
        
        self:showBonusAndScatterLineTip(bonusLineValue,function()
            self:showBonusGameView(effectData)
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        if effectData.p_isOutLInes then
            print("断线进来不播放音效")
        else
            -- 播放提示时播放音效        
            self:playBonusTipMusicEffect()
        end
        
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenBeerHauseMachine:showBonusGameView(effectData)

    

    gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_guochang.mp3")

    self.m_BeerHauseGuoChangView:setVisible(true)
    self.m_BeerHauseGuoChangView:runCsbAction("actionframe",false,function(  )
        self.m_BeerHauseGuoChangView:setVisible(false)
    end) 

    performWithDelay(self,function(  )
        self.m_bottomUI:checkClearWinLabel()
        self:createBonusView(effectData) 
    end,1.5)

 
end

function CodeGameScreenBeerHauseMachine:bonusTriggerFreespin( )

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

function CodeGameScreenBeerHauseMachine:createBonusView(effectData)
    self.m_bonusView = util_createView("CodeBeerHauseSrc.BeerHauseBonusView")
    self.m_root:addChild(self.m_bonusView,1)
    self.m_bonusView:setEndCall(function(  )
        self:clearCurMusicBg()

        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_guochang.mp3")
        self.m_BeerHauseGuoChangView:setVisible(true)
        self.m_BeerHauseGuoChangView:runCsbAction("actionframe",false,function(  )
            self.m_BeerHauseGuoChangView:setVisible(false)

        end) 

        performWithDelay(self,function(  )
            if self.m_bonusView then
                self.m_bonusView:removeFromParent()
            end 

            self:bonusTriggerFreespin( )
            
            effectData.p_isPlay = true
            self:playGameEffect()
             
            
        end,1.5)

       
       
    end)

    for i=1,4 do
        local node = self:findChild("wheel_"..i)
        if node then
            node:setVisible(false)
        end
    end
    

    self.m_bonusView:setRunResultDataCall(function( spinData )
        self:updateResultData(spinData )
     end)

     self:resetMusicBg(nil,"BeerHauseSounds/BeerHause_bonusGamebg.mp3") 

    if effectData.p_isOutLInes then
        -- 断线重连进入的bonus 
        -- 更新bonus显示
        local data = self.m_initFeatureData.p_bonus
        self.m_bonusView:initBonusUI(data )
        
    end
    

end


function CodeGameScreenBeerHauseMachine:createBonusTipNode( )


    for i=1,#self.m_redBonusTipPos do
        local tipView = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView","BeerHause_kuang_red" )
        self:findChild("wheel_1"):addChild(tipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1 )
        tipView.pos = self.m_redBonusTipPos[i]
        table.insert( self.m_redBonusTipNodeList, tipView )

        local pos = cc.p(self:getThreeReelsTarSpPos(tipView.pos  )) 
        tipView:setPosition(pos)

    end

    for i=1,#self.m_blueBonusTipPos do
        local tipView = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView","BeerHause_kuang_blue" )
        self:findChild("wheel_1"):addChild(tipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        tipView.pos = self.m_blueBonusTipPos[i]
        table.insert( self.m_blueBonusTipNodeList, tipView )

        local pos = cc.p(self:getThreeReelsTarSpPos(tipView.pos  )) 
        tipView:setPosition(pos)
    end

end



--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenBeerHauseMachine:getThreeReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenBeerHauseMachine:getSixReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPosForSixRow(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--- respin下 6行的情况
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function CodeGameScreenBeerHauseMachine:getRowAndColByPosForSixRow(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = 6 - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenBeerHauseMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function CodeGameScreenBeerHauseMachine:checkInitSpinWithEnterLevel( )
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
        local isBonusOverData = false
        if self.m_initFeatureData then
            local bonusData = self.m_initFeatureData.p_bonus
            if bonusData then
                if bonusData.choose and bonusData.extra then
                    if bonusData.extra.plusSpinTimes then
                            -- 99 说明是bonus结束状态
                            if bonusData.extra.plusSpinTimes[#bonusData.choose] == 99  then
                                isBonusOverData = true
                            end
                            
                    end
                end
            end
        end
        
        if self.m_initFeatureData == nil or  isBonusOverData then
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

function CodeGameScreenBeerHauseMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.quicklyStopReel(self, colIndex) 
    end
    
   
end

function CodeGameScreenBeerHauseMachine:updateResultData(spinData )
    
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end



--小块
function CodeGameScreenBeerHauseMachine:getBaseReelGridNode()
    return "CodeBeerHauseSrc.BeerHauseSlotsNode"
end



-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenBeerHauseMachine:specialSymbolActionTreatment( node)
    if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        node:runAnim("buling",false,function(  )
            node:runIdleAnim()
        end)
    end
end



-- 处理特殊关卡 遮罩层级
function CodeGameScreenBeerHauseMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end


---
--设置bonus scatter 层级
function CodeGameScreenBeerHauseMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE_1 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FSMORE_3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==   self.SYMBOL_FIX_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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


function CodeGameScreenBeerHauseMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else 
                return false
            end
        end
    end

    return true
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

--设置bonus scatter 信息
function CodeGameScreenBeerHauseMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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
        showCol = self.m_ScatterShowCol
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

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenBeerHauseMachine:randomSlotNodes( )
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            local symbolType = self:getRandomReelType(colIndex,reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
                -- 添加到显示列表
                parentData.slotParent:addChild(node,showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self,tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName,tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node,symbolType,rowIndex,colIndex,false)
            end

            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = showOrder
           
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node:runIdleAnim()
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )
        end
    end
end

function CodeGameScreenBeerHauseMachine:randomSlotNodesByReel()
    for colIndex = 1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1,resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
                parentData.slotParent:addChild(node,showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self,tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName,tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node,symbolType,rowIndex,colIndex,false)
            end
            node.p_slotNodeH = reelColData.p_showGridH      
            
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima
            node:runIdleAnim()
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )

        end
    end
end


function CodeGameScreenBeerHauseMachine:hideAllKuang( )
    for i=1,#self.m_WildKuangViewList do
        local kuang = self.m_WildKuangViewList[i]
        if kuang then
            kuang:setVisible(false) 
            kuang:runCsbAction("idle",false) 
            kuang:removeFromParent()
        end
    end

    self.m_WildKuangViewList = {}
    
end

function CodeGameScreenBeerHauseMachine:showOneKuang(col )

    local pos = col -1
    local name =  "Socre_BeerHause_kuang1"
    local WildKuangView =  util_createView("CodeBeerHauseSrc.BeerHauseWildKuangView" , name)
    self:findChild("wheel_1"):addChild(WildKuangView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 4)
    WildKuangView:setPosition(cc.p(self:findChild("sp_reel_"..pos):getPosition()))
    table.insert( self.m_WildKuangViewList, WildKuangView )

    WildKuangView:setVisible(true) 
    WildKuangView:runCsbAction("actionframe",true) 

end


function CodeGameScreenBeerHauseMachine:playEffectNotifyNextSpinCall( )


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
            
            local lines = self.m_vecMiniWheel[freespinMainReelid]:getResultLines()
            
             

            if lines ~= nil and #lines > 0 then
                
                delayTime = delayTime + self:getWinCoinTime()
                if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
                    if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                        delayTime = 0.5
                    end
                end
            end

        else
            if self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0 then
                delayTime = delayTime + self:getWinCoinTime()
            end
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
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end



function CodeGameScreenBeerHauseMachine:hideAllLongWild( )
    for i=1,#self.m_longWildViewList do
        local kuang = self.m_longWildViewList[i]
        if kuang then
            kuang:setVisible(false) 
            kuang:runCsbAction("idle1") 
            kuang:removeFromParent()
        end
    end

    self.m_longWildViewList = {}
    
end

function CodeGameScreenBeerHauseMachine:showOneLongWild(col )

    local pos = col -1
    local name =  "Socre_BeerHause_CopyWild"
    local longWildView =  util_createView("CodeBeerHauseSrc.BeerHauseLongWildView" , name)
    self:findChild("wheel_1"):addChild(longWildView,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 100)
    longWildView:setPosition(cc.p(self:findChild("sp_reel_"..pos):getPosition()))
    table.insert( self.m_longWildViewList, longWildView )
    longWildView:setVisible(true) 

    longWildView:playAddWild("actionframe2") 

end


function CodeGameScreenBeerHauseMachine:createOneCSbActionSymbol(endNode,actionName,isSpine)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    local node = self:getSlotNodeBySymbolType(endNode.p_symbolType)
    local func = function(  )
          if fatherNode then
                fatherNode:setVisible(true)
          end
          if node then
                node:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
          end
          
    end
    node:runAnim(actionName,false,func)
    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("wheel_1"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("wheel_1"):addChild(node , SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE  + endNode.p_rowIndex + 200)
    node:setPosition(pos)

    return node
end

function CodeGameScreenBeerHauseMachine:playEffectNotifyChangeSpinStatus( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        -- self:setFsAllRunDown(1 )

    else
        self:setNormalAllRunDown(1 )
    end
end

function CodeGameScreenBeerHauseMachine:setFsAllRunDown(times )
    self.m_FsDownTimes = self.m_FsDownTimes + times

    if self.m_FsDownTimes == 2 then

        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) and self:getCurrSpinMode() == FREE_SPIN_MODE then
            print("啥也不做")
        else
            BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
        end

        
        self.m_FsDownTimes = 0
    end
end

function CodeGameScreenBeerHauseMachine:setNormalAllRunDown( times)

    self.m_norDownTimes = self.m_norDownTimes + times

    if self.m_norDownTimes == 2 then
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
        self.m_norDownTimes = 0
    end

    
end


-- 高低bet相关

function CodeGameScreenBeerHauseMachine:getNetWorkModuleName()

    if hightLowBet then
        return "BeerHauseV2"
    else
        return "BeerHause"   
    end
    
end

function CodeGameScreenBeerHauseMachine:getBetLevel( )

    if hightLowBet then
        return self.m_betLevel 
    else
        return nil
    end
    
end


function CodeGameScreenBeerHauseMachine:requestSpinResult()
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


function CodeGameScreenBeerHauseMachine:updatJackPotLock( minBet )
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            
            self.m_betLevel = 1
            self:updateTipNode( self.m_betLevel)
            
        end
    else


        if self.m_betLevel == nil or self.m_betLevel == 1 then

            self:showHightLowBetView( )

            self.m_betLevel = 0
            self:updateTipNode( self.m_betLevel)
            
        end
        
    end

    

    

   
end

function CodeGameScreenBeerHauseMachine:getMinBet( )
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

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenBeerHauseMachine:upateBetLevel()

    if hightLowBet then

        local minBet = self:getMinBet( )
        self:updatJackPotLock( minBet ) 
        
    end
    
    
end

function CodeGameScreenBeerHauseMachine:updateTipNode( level)

    for i=1,#self.m_redBonusTipNodeList do
        self.m_redBonusTipNodeList[i]:removeFromParent()
    end

    self.m_redBonusTipNodeList = {}


    for i=1,#self.m_redBonusTipPos do

        local fileName = "BeerHause_kuang_red"

        if level == 0 then  
            fileName = "BeerHause_kuang_blue"
        end

        local tipView = util_createView("CodeBeerHauseSrc.BeerHauseBonusTittleView",fileName )
        self:findChild("wheel_1"):addChild(tipView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1 )
        tipView.pos = self.m_redBonusTipPos[i]
        table.insert( self.m_redBonusTipNodeList, tipView )
        local pos = cc.p(self:getThreeReelsTarSpPos(tipView.pos  )) 
        tipView:setPosition(pos)

    end

    self.m_vecMiniWheel[freespinMainReelid]:updateTipNode( level)
    self.m_vecMiniWheel[freespinAuxiliaryReelid]:updateTipNode( level)

    
 
end



local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenBeerHauseMachine:addLastWinSomeEffect() -- add big win or mega win

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local lines = self.m_vecMiniWheel[freespinMainReelid]:getVecGetLineInfo( )
        if #lines == 0 then
            return
        end
    else
        if #self.m_vecGetLineInfo == 0 then
            return
        end
    end
    

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin
        
        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN) 
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin
        
        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin
        
        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)

    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or
            self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or
            self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)

    end


end


---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenBeerHauseMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
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


   

--设置长滚信息
function CodeGameScreenBeerHauseMachine:setReelRunInfo()
    
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
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 11) 
                self:setLastReelSymbolList()    
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

        local index = self.m_iReelColumnNum - 1
        if col == index and bRunLong then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true

        end

    end --end  for col=1,iColumn do

end

-- 背景音乐点击spin后播放
function CodeGameScreenBeerHauseMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    BaseFastMachine.normalSpinBtnCall(self)
end

function CodeGameScreenBeerHauseMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "free" == _sFeature then
        return
    end
    if CodeGameScreenBeerHauseMachine.super.levelDeviceVibrate then
        CodeGameScreenBeerHauseMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenBeerHauseMachine






