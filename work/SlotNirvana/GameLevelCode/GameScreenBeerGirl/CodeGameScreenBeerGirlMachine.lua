---
-- island li
-- 2019年1月26日
-- CodeGameScreenBeerGirlMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CodeGameScreenBeerGirlMachine = class("CodeGameScreenBeerGirlMachine", BaseFastMachine)

CodeGameScreenBeerGirlMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBeerGirlMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 
CodeGameScreenBeerGirlMachine.EFFECT_TYPE_TEN_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 2 
CodeGameScreenBeerGirlMachine.EFFECT_TYPE_FAST_WIN = GameEffect.EFFECT_SELF_EFFECT - 3 


CodeGameScreenBeerGirlMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 
CodeGameScreenBeerGirlMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenBeerGirlMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3   
CodeGameScreenBeerGirlMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 

CodeGameScreenBeerGirlMachine.SYMBOL_FLY_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 100

CodeGameScreenBeerGirlMachine.m_collectList = nil
CodeGameScreenBeerGirlMachine.m_collectData = {}

CodeGameScreenBeerGirlMachine.m_FixBonusLayer  = nil
CodeGameScreenBeerGirlMachine.m_FixBonusKuang  = nil
CodeGameScreenBeerGirlMachine.m_FreeSpinFixBonusKuang  = nil

CodeGameScreenBeerGirlMachine.m_norDownTimes = 0
CodeGameScreenBeerGirlMachine.m_norSlotsDownTimes = 0

CodeGameScreenBeerGirlMachine.m_betLevel = nil -- betlevel 0 1 

CodeGameScreenBeerGirlMachine.m_betNetKuangData = nil -- 不同bet对应的框数据

CodeGameScreenBeerGirlMachine.m_betTotalCoins = 0 --本地存储一份betid

CodeGameScreenBeerGirlMachine.m_isOutLines = nil --是否是断线

-- 构造函数
function CodeGameScreenBeerGirlMachine:ctor()
    BaseFastMachine.ctor(self)

    self.m_collectList = nil
    self.m_FixBonusLayer  = nil
    self.m_FixBonusKuang  = {}
    self.m_betLevel = nil
    self.m_FreeSpinFixBonusKuang  = {}
    self.m_norDownTimes = 0
    self.m_norSlotsDownTimes = 0
    self.m_betNetKuangData = {}
    self.m_isOutLines = false
    self.m_betTotalCoins = 0
    self.m_chooseSoundIndex = 1
    self.m_tenSpinSoundIndex = 1
    self.m_longSlotSoundIndex = 1
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenBeerGirlMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "BeerGirlSounds/BeerGirl_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "BeerGirlSounds/BeerGirl_scatter_down2.mp3"
        else
            soundPath = "BeerGirlSounds/BeerGirl_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenBeerGirlMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBeerGirlMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BeerGirl"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenBeerGirlMachine:getNetWorkModuleName()
    return "BeerGirlV2"
end

function CodeGameScreenBeerGirlMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    self:findChild("viewNode_jackpot"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 2)
    self:findChild("viewNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    
    -- 创建view节点方式
    -- self.m_BeerGirlView = util_createView("CodeBeerGirlSrc.BeerGirlView")
    -- self:findChild("xxxx"):addChild(self.m_BeerGirlView)
            --.m_bottomUI
    local node_bar = self:findChild("node_bar")
    self.m_baseCollectBar = util_createView("CodeBeerGirlSrc.collect.BeerGirlCollectTimesBarView")
    node_bar:addChild(self.m_baseCollectBar)
    self.m_baseCollectBar:setPosition(0,0)

    

    self.m_BeerHauseGuoChangView = util_createView("CodeBeerGirlSrc.BeerGirlGuoChangView")
    self:addChild(self.m_BeerHauseGuoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_BeerHauseGuoChangView:setPosition(display.width/2,display.height/2)
    self.m_BeerHauseGuoChangView:setVisible(false)
   
    self.m_jackPotBar = util_createView("CodeBeerGirlSrc.BeerGirlJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    local data = {}
    data.index = 1
    data.parent = self
    self.m_FastReels = util_createView("CodeBeerGirlSrc.BeerGirlMiniMachine",data)
    self:findChild("right"):addChild(self.m_FastReels)

    self.m_FixBonusLayer = cc.Node:create()
    self:findChild("root"):addChild(self.m_FixBonusLayer,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    

    self.m_gameTip = util_createAnimation("BeerGirl_wanfashuoming.csb")
    self:findChild("wanfashuoming"):addChild(self.m_gameTip)
    self.m_gameTip:runCsbAction("animation0",true,nil,30)

    self:findChild("BeerGirl_bgshine_1"):setVisible(false)
    self:findChild("reel_free"):setVisible(false)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        local changeFreespinOver = false
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local isFreeSpinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)

            if isFreeSpinOver then
    
            else
                if self.m_bIsBigWin then
                    return
                end
            end
        else
            if self.m_bIsBigWin then
                return
            end
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
            soundIndex = 3
        end

        -- gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = nil
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "BeerGirlSounds/music_BeerGirl_free_win_".. soundIndex .. ".mp3"
        else
            soundName = "BeerGirlSounds/music_BeerGirl_last_win_".. soundIndex .. ".mp3"
        end
        
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            -- gLobalSoundManager:setBackgroundMusicVolume(1)
            self.m_winSoundsId = nil
        end)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBeerGirlMachine:FadeInNode( node,time)

    util_setCascadeOpacityEnabledRescursion(node,true)

    local actLict = {}
    actLict[#actLict + 1] = cc.FadeIn:create(time)
    local sq = cc.Sequence:create(actLict)
    node:runAction(sq)
end

function CodeGameScreenBeerGirlMachine:FadeOutNode( node,time)

    util_setCascadeOpacityEnabledRescursion(node,true)

    local actLict = {}
    actLict[#actLict + 1] = cc.FadeOut:create(time)
    local sq = cc.Sequence:create(actLict)
    node:runAction(sq)
end

function CodeGameScreenBeerGirlMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_enter.mp3")
        
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                gLobalSoundManager:setBackgroundMusicVolume(0)
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenBeerGirlMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self.m_jackPotBar:updateJackpotInfo()

    local totalBet = globalData.slotRunData:getCurTotalBet( )
    self.m_betTotalCoins =  totalBet

    self:upateBetLevel()
end

function CodeGameScreenBeerGirlMachine:scaleMainLayer()
    BaseFastMachine.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if  display.height/display.width <= 768/1370 and display.height/display.width > 768/1530 then
        mainScale = 0.97
    end
    self.m_machineRootScale = mainScale
    util_csbScale(self.m_machineNode, mainScale)
end

function CodeGameScreenBeerGirlMachine:changeLockFixNodeNode( isFreeStart)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0
    
    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    if spintimes == 10  then
        return
    end

    for colIndex = 1, self.m_iReelColumnNum do
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        for rowIndex = 1, self.m_iReelRowNum do
            
            local netSymbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            if netSymbolType == self.SYMBOL_FIX_BONUS then
                local symbolNode =  self:getReelParent(colIndex):getChildByTag(self:getNodeTag(colIndex,rowIndex,SYMBOL_NODE_TAG))
                local symbolType = self:getRandomReelType(colIndex, reelDatas)
                while true do
                    if self.m_bigSymbolInfos[symbolType] == nil then
                        break
                    end

                    symbolType = self:getRandomReelType(colIndex, reelDatas)
                end

                while true do
                    if symbolType ~= self.SYMBOL_FIX_BONUS then
                    
                        break
                    end

                    symbolType = self:getRandomReelType(colIndex, reelDatas)
                end

                
                if symbolNode   then
                    if not symbolNode:isVisible() then
                        symbolNode:setVisible(true)
                        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType),symbolType)
                        symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType))
                        symbolNode:runIdleAnim()
                    end

                else
                    local targSp = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)   

                    if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
            
                        targSp.m_baseBoolFlag = true

                        targSp.m_symbolTag = SYMBOL_NODE_TAG
                        targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                        
                        local zorder = self:getBounsScatterDataZorder(symbolType)
                        self:getReelParent(colIndex):addChild(targSp, zorder , self:getNodeTag(colIndex,rowIndex,SYMBOL_NODE_TAG))
            
                        local position =  self:getNodePosByColAndRow(rowIndex, colIndex) 

                        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(position))
                        local pos = self:getReelParent(colIndex):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))


                        targSp:setPosition(cc.p(pos))

                    end
                
                end
            end
            
            

 
        end
    end
end

function CodeGameScreenBeerGirlMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()

        local totalBet = globalData.slotRunData:getCurTotalBet( )

        -- 不同的bet切换才刷新框
        if self.m_betTotalCoins ~=  totalBet  then

            self.m_betTotalCoins = totalBet
            -- 根据bet刷新框显示
            self:removeAllBaseKuang()
            self:initCollectKuang(true )
            self:updateCollectTimes( )
            self:changeLockFixNodeNode( )
        end
        


   end,ViewEventType.NOTIFY_BET_CHANGE)

end


function CodeGameScreenBeerGirlMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBeerGirlMachine:MachineRule_GetSelfCCBName(symbolType)

    
    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_BeerGirl_10"
    elseif symbolType == self.SYMBOL_SCORE_11  then
        return "Socre_BeerGirl_11"
    elseif symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_BeerGirl_12"
    elseif symbolType == self.SYMBOL_FIX_BONUS then  
        return "Socre_BeerGirl_FIx_Bonus"
    elseif symbolType == self.SYMBOL_FLY_FIX_BONUS then
        return "Socre_BeerGirl_Bonus_shouji_tuowei"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBeerGirlMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_12,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FLY_FIX_BONUS,count =  2}
    
    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenBeerGirlMachine:checkTriggerINFreeSpin( )
    local isPlayGameEff = false

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
        hasBonusFeature = false  -- 特殊处理

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
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end

function CodeGameScreenBeerGirlMachine:updateCollectTimes( )

    local totalBet = globalData.slotRunData:getCurTotalBet( ) 
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 

    local selfdata =  wilddata or {}
    local spinTimes = selfdata.spinTimes or 0
    local oldSpinTimes = selfdata.spinTimes or 0
    if spinTimes then
        if spinTimes == 10 then
            spinTimes = 0
        end
        self.m_baseCollectBar:updateTimes(spinTimes ,10)
    end
end

-- 断线重连 
function CodeGameScreenBeerGirlMachine:MachineRule_initGame(  )



    self.m_isOutLines = true
   
    if self.m_bProduceSlots_InFreeSpin then
        --不是进入fs时 切背景
        if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:findChild("reel_free"):setVisible(true)
        end
    end
end

---
-- 老虎机滚动结束调用
function CodeGameScreenBeerGirlMachine:fastReelsWinslotReelDown()

    if self:getBetLevel() == 0 then
        return
    end

    local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
    local cash = selfdata.cash or {}
    local lines = cash.lines
    local isWin = false
    if lines and #lines > 0 then
        isWin = true
    end

    if isWin then
        self:setDownTimes( 1 )

        if self.m_jackPotRunSoundsId then
            gLobalSoundManager:stopAudio(self.m_jackPotRunSoundsId)
            self.m_jackPotRunSoundsId = nil
        end
        
        -- fast轮盘没有中奖停止播放
        self.m_FastReels:runCsbAction("idleframe")
        self.m_FastReels.m_fastLucyLogo:runCsbAction("idle1",true)

    end

    

end

function CodeGameScreenBeerGirlMachine:playEffectNotifyNextSpinCall( )

    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

  
    
end

function CodeGameScreenBeerGirlMachine:setDownTimes( time )

    self.m_norSlotsDownTimes = self.m_norSlotsDownTimes + time
    if self.m_norSlotsDownTimes == 2 then

        local node = cc.Node:create()
        self:addChild(node)
        performWithDelay(node,function(  )
            BaseFastMachine.slotReelDown(self)  
            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)
            node:removeFromParent()
        end,self.m_configData.p_reelResTime or 0)


        self.m_norSlotsDownTimes = 0
    end
    
end

---
-- 老虎机滚动结束调用
function CodeGameScreenBeerGirlMachine:slotReelDown()

    local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
    local cash = selfdata.cash or {}
    local lines = cash.lines
    local isWin = false
    if lines and #lines > 0 then
        isWin = true
    end
    if not isWin  then

        
        local node = cc.Node:create()
        self:addChild(node)
        performWithDelay(node,function(  )      --增加一个小延迟，在所有列滚动结束播连线等（解决偶现第六轮回弹卡顿的问题）
            BaseFastMachine.slotReelDown(self)  
            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)
            node:removeFromParent()
        end,self.m_configData.p_reelResTime or 0)
        

        

    else
        self:setDownTimes( 1 )
    end
  
end

--
--单列滚动停止回调
--
function CodeGameScreenBeerGirlMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) 
    and 
    (self:getGameSpinStage( ) ~= QUICK_RUN 
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
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
            reelEffectNode[1]:setVisible(false)
        end

        local reelEffectOneNode =  self.m_slotEffectLayer:getChildByName("reelEffectNode"..reelCol)
        if reelEffectOneNode and reelEffectOneNode:isVisible() then
            reelEffectOneNode:setVisible(false)
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end


    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        local isHaveFixSymbol = false
        local symbolType = nil
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,iRow,SYMBOL_NODE_TAG))
            if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_BONUS then
                isHaveFixSymbol = true
                symbolType = self.SYMBOL_FIX_BONUS
                targSp:runAnim("buling")

            end
        end

        if isHaveFixSymbol == true  then
            local soundPath = "BeerGirlSounds/music_BeerGirl_Bonus_Down_" .. reelCol .. ".mp3"

            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath,symbolType )
            else
                -- respinbonus落地音效
                gLobalSoundManager:playSound(soundPath)
            end
            
        end

    end

    if reelCol == 5 and self:getGameSpinStage( ) ~= QUICK_RUN  then
        local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
        local cash = selfdata.cash or {}
        local lines = cash.lines
        local isWin = false
        if lines and #lines > 0 then
            isWin = true
        end
        -- fast轮盘中奖随机
        self:checkIsRunFastWinAct(isWin )
    end

   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBeerGirlMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal_freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBeerGirlMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin_normal")
    
end
---------------------------------------------------------------------------



function CodeGameScreenBeerGirlMachine:removeAllFsKuang( )
    for i=1,#self.m_FreeSpinFixBonusKuang do
        local node = self.m_FreeSpinFixBonusKuang[i]
        node:setVisible(true)
        node:removeFromParent()
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        node.m_baseBoolFlag = true
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end

    self.m_FreeSpinFixBonusKuang = {}

   
end

function CodeGameScreenBeerGirlMachine:changeFixBonusKuang( )
    
    for k,node in pairs(self.m_FixBonusKuang) do
        local name = node:getName()
        local oldNode = self.m_clipParent:getChildByName(name)
        if oldNode then
            if oldNode.m_baseBoolFlag == nil then
                oldNode.m_baseBoolFlag = true
            end

            self.m_FixBonusKuang[k] = oldNode
        end
    end

    

end

function CodeGameScreenBeerGirlMachine:restAllBaseKuang( )

    for k,node in pairs(self.m_FixBonusKuang) do
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    end
    self.m_FixBonusKuang = {}

end

function CodeGameScreenBeerGirlMachine:removeAllBaseKuang( )
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        node:setVisible(true)
        node:removeFromParent()
        local linePos = {}
        node.m_bInLine = false
        node:setLinePos(linePos)
        node:setName("")
        node.m_baseBoolFlag = nil
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end

    self.m_FixBonusKuang = {}

end

---
-- 显示free spin
function CodeGameScreenBeerGirlMachine:showEffect_FreeSpin(effectData)

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

function CodeGameScreenBeerGirlMachine:showFreeSpinStart(num,func)
    -- local ownerlist={}
    -- ownerlist["m_lb_num"]=num
    -- return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)

    self.m_baseCollectBar:setVisible(false)
    self:findChild("BeerGirl_bgshine_1"):setVisible(true)
    -- self.m_topCollectBar:setVisible(false)

    -- 避免freespin开始时有空的格子，显得像有BUg一样
    self:changeLockFixNodeNode()


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spintimes = selfdata.spinTimes or 0

    -- 如果这一轮的次数为第十次那么就不变了
    -- 因为fix symbol 已经变成wild了
    if spintimes ~= 10  then
        self:removeAllBaseKuang( )
    end

    
    if func then
        func()
    end
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenBeerGirlMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_custom_enter_fs.mp3")


    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()

                    self:createFsMoveKuang( function(  )
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end )

                         
            end)
        end
    end

    
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenBeerGirlMachine:showGuoChang(index, func,funcEnd)

    -- gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_GuoChang.mp3")
    local soundName = "BeerGirlSounds/BeerGirl_GuoChang_" .. index .. ".mp3"
    gLobalSoundManager:playSound(soundName)

    self.m_BeerHauseGuoChangView:setVisible(true)
    self.m_BeerHauseGuoChangView:runCsbAction("actionframe",false,function(  )
        self.m_BeerHauseGuoChangView:setVisible(false)
        if funcEnd then
            funcEnd()
        end
    end)

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,1.5)
end

function CodeGameScreenBeerGirlMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_Freespin_end.mp3")

    performWithDelay(self,function(  )
        self:showFreeSpinOverView()
    end,2.5)
    
end

function CodeGameScreenBeerGirlMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_over_fs.mp3")
   gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_over_Congratulations.mp3")
   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

            performWithDelay(self,function(  )
                self:showGuoChang(2, function(  )
                    --修改底板
                    self:findChild("reel_free"):setVisible(false)

                    local needCount = self.m_collectData.collectNeedCount 
                    local collectCount =  self.m_collectData.collectCount 
                    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                    
                    if collectCount == needCount then
                        if fsExtraData.collect then
                            collectCount = 0
                        end
                    end

                    -- self:updateCollectLoading(collectCount ,needCount,true)

                    self.m_bottomUI:hideAverageBet()
   
               
                   local totalBet = globalData.slotRunData:getCurTotalBet( ) 
                   local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
                   local selfdata =  wilddata or {}
                   local oldSpinTimes = selfdata.spinTimes or 0
   
                   if oldSpinTimes and oldSpinTimes == 10  then
                       -- 第10次就不还原固定框了
                   else
                       self:initCollectKuang( )
                   end
   
                   -- 收集bonus 和 freespin同时触发时 
                   self:AddBonusEffect()
   
                  
                   self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
                   self:clearFrames_Fun()
                   -- 取消掉赢钱线的显示
                   self:clearWinLineEffect()
   
                   self:removeAllFsKuang()
                   self:findChild("BeerGirl_bgshine_1"):setVisible(false)
                   self.m_baseCollectBar:setVisible(true)
                --    self.m_topCollectBar:setVisible(true)
   
               end,function(  )

                    self:triggerFreeSpinOverCallFun()
                    
               end)
            end,0.5)
            

        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},571)

end



---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBeerGirlMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)


    self.isInBonus = false

    self:removeSoundHandler( )
    
    if self.m_winSoundsId then
        
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil

    end
   
    -- local needCount = self.m_collectData.collectNeedCount 
    -- local collectCount =  self.m_collectData.collectCount 
    -- self:updateCollectLoading(collectCount ,needCount)
    self.m_isOutLines = false
    self.m_norDownTimes = 0
    self.m_norSlotsDownTimes = 0
    local totalBet = globalData.slotRunData:getCurTotalBet( )
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
    local selfdata = wilddata or {}
    local spintimes = selfdata.spinTimes or 0
    if spintimes and spintimes == 9 then
        local soundName = "BeerGirlSounds/music_BeerGirl_TenSpin_" .. self.m_tenSpinSoundIndex .. ".mp3"
        gLobalSoundManager:playSound(soundName)
        if self.m_tenSpinSoundIndex == 1 then
            self.m_tenSpinSoundIndex = 2
        elseif self.m_tenSpinSoundIndex == 2 then
            self.m_tenSpinSoundIndex = 3
        elseif self.m_tenSpinSoundIndex == 3 then
            self.m_tenSpinSoundIndex = 1
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
function CodeGameScreenBeerGirlMachine:MachineRule_network_InterveneSymbolMap()
    if self:getBetLevel() ~= 0 then
        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.cash ~= nil then
            local resultDatas = self.m_runSpinResultData.p_selfMakeData.cash
            self:insetMiniReelsLines(resultDatas)
        end
    end
    
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenBeerGirlMachine:MachineRule_afterNetWorkLineLogicCalculate()

    self:updateCollectData()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

    self:updateBetNetKuangData()

    
end



function CodeGameScreenBeerGirlMachine:initBetNetKuangData(bets )
    
    if bets then
        self.m_betNetKuangData = bets
    end

end


function CodeGameScreenBeerGirlMachine:updateBetNetKuangData( )
    

    

    local selfdata =  self.m_runSpinResultData.p_selfMakeData
    if selfdata then

        
        local totalBet = globalData.slotRunData:getCurTotalBet( ) 
        local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
        if wilddata == nil then
            self.m_betNetKuangData[tostring(totalBet)] = {}
            wilddata =  self.m_betNetKuangData[tostring(totalBet)]
        end
        if selfdata.wildPositions then
            wilddata.wildPositions = selfdata.wildPositions
        end
        
        if selfdata.spinTimes then
            wilddata.spinTimes = selfdata.spinTimes
        end

    end

end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBeerGirlMachine:addSelfEffect()

    self.m_collectList = nil
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_FIX_BONUS then
                    if not self.m_collectList then
                        self.m_collectList = {}
                    end
                    self.m_collectList[#self.m_collectList + 1] = node
                end
            end
        end
    end
    if self.m_collectList and #self.m_collectList > 0 then

        --收集金币
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT

    end


    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spinTimes = selfdata.spinTimes
    local kaungList = selfdata.wildPositions or {}

    if spinTimes then
        if spinTimes == 10 and kaungList and #kaungList > 0 then
            --第十次所有框都变成wild
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_TEN_COLLECT
        end
    end
    

    local cash = selfdata.cash or {}
    local lines = cash.lines
    if lines and #lines > 0 then
        -- 添加 fast赢钱弹板
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_FAST_WIN
    end
       

  

end

function CodeGameScreenBeerGirlMachine:collectFixBonus(effectData )
    if self.m_collectList and #self.m_collectList > 0 then

        local needCount = self.m_collectData.collectNeedCount 
        local collectCount =  self.m_collectData.collectCount 
        
        gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_CollectBeizi.mp3")

        self:lockWild(self.m_collectList)

        self.m_collectList = nil
    end

    local cash = self.m_runSpinResultData.p_selfMakeData.cash or {}
    local lines = cash.lines

    local spinTimes = self.m_runSpinResultData.p_selfMakeData.spinTimes
    local features = self.m_runSpinResultData.p_features

    if lines and #lines > 0 then
        
        --第十次所有框都变成wild
        performWithDelay(self,function()

            if  self:getBetLevel() == 0 then

            else
                self.m_FastReels:restSelfEffect( effectData.p_selfEffectType )
            end 


            effectData.p_isPlay = true
            self:playGameEffect()
        end,1.7)

    elseif spinTimes == 10 and self.m_FixBonusKuang and #self.m_FixBonusKuang > 0 then

        --第十次所有框都变成wild
        performWithDelay(self,function(  )
            if  self:getBetLevel() == 0 then

            else

                self.m_FastReels:restSelfEffect( effectData.p_selfEffectType )
            end 

            effectData.p_isPlay = true
            self:playGameEffect()
        end,1)
    elseif features and #features == 2 and features[2] == 5 then

        --中了bonus
        performWithDelay(self,function(  )
            if  self:getBetLevel() == 0 then

            else

                self.m_FastReels:restSelfEffect( effectData.p_selfEffectType )
            end 

            effectData.p_isPlay = true
            self:playGameEffect()
        end,2.7)
    else

        -- performWithDelay(self,function(  )

            if  self:getBetLevel() == 0 then
                
            else
                self.m_FastReels:restSelfEffect( effectData.p_selfEffectType )
            end 
    
            effectData.p_isPlay = true
            self:playGameEffect()
            
        -- end,0.8)

        
    end
end

function CodeGameScreenBeerGirlMachine:fixBonusTurnWild( effectData )

    local time = 0.2

    local actList = {}
    for i=1,#self.m_FixBonusKuang do
        local node = self.m_FixBonusKuang[i]
        table.insert( actList, node)
    end

    table.sort( actList, function( a,b )

        local icolA = a.p_cloumnIndex
        local icolB = b.p_cloumnIndex

        return icolA < icolB
    end )

    local sortList = {}
    for i=1,#actList do
        local node = actList[i]
        local index = node.p_cloumnIndex
        local list = sortList[index]
        if list == nil then
            sortList[index] = {}
        end
        table.insert( sortList[index], actList[i] )
    end

    for k,v in pairs(sortList) do
        local list = v
        if list then
            table.sort( list, function( a,b )
                local irowA = a.p_rowIndex 
                local irowB = b.p_rowIndex 
        
                return irowA > irowB
            end )
        end
    end

    
    local sortNodeList = {}
    for i=1,5 do
        local list = sortList[i]
        if list then
            for k = 1,#list do

                table.insert( sortNodeList, list[ k ] )
            end
        end
    end
  
    

    for i=1,#sortNodeList do
        local node = sortNodeList[i]
        node:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
        node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        node:setTag(SYMBOL_FIX_NODE_TAG + 1)
        node:setName("")
        node.m_baseBoolFlag = true
        local linePos = {}
        linePos[#linePos + 1] = {iX = node.p_rowIndex, iY = node.p_cloumnIndex}
        node.m_bInLine = false
        node:setLinePos(linePos)

        performWithDelay(self,function(  )
            gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_BonusTurnWild.mp3")
            node:runAnim("bonus_wild")
        end,(i-1) * time )
    end


    self.m_FixBonusKuang = {}

    local waitTime = ( #actList * time) + 1 
    
    performWithDelay(self,function( )

        if  self:getBetLevel() == 0 then
                
        else
            self.m_FastReels:restSelfEffect( effectData.p_selfEffectType )
        end 
        

        effectData.p_isPlay = true
        self:playGameEffect() 
    end,waitTime)
    
end

function CodeGameScreenBeerGirlMachine:checkIsTright(rodTime ,courTime )
    
    if rodTime <= courTime then
        return true
    end

    return false
end

function CodeGameScreenBeerGirlMachine:changeFastReelsRunData( )
    if self:getBetLevel() == 0 then
        return
    end

    local selfdata =  self.m_runSpinResultData.p_selfMakeData or {}
    local cash = selfdata.cash or {}
    local lines = cash.lines
    local isWin = false
    if lines and #lines > 0 then
        isWin = true
    end

    if isWin then
        local rundata = {self.m_reelRunInfo[#self.m_reelRunInfo]:getReelRunLen()+ 80}
        self.m_FastReels:slotsReelRunData(rundata,self.m_FastReels.m_configData.p_bInclScatter
            ,self.m_FastReels.m_configData.p_bInclBonus,self.m_FastReels.m_configData.p_bPlayScatterAction
            ,self.m_FastReels.m_configData.p_bPlayBonusAction)
    else
        self.m_FastReels:slotsReelRunData(self.m_FastReels.m_configData.p_reelRunDatas,self.m_FastReels.m_configData.p_bInclScatter
            ,self.m_FastReels.m_configData.p_bInclBonus,self.m_FastReels.m_configData.p_bPlayScatterAction
            ,self.m_FastReels.m_configData.p_bPlayBonusAction)
    end
    


end

function CodeGameScreenBeerGirlMachine:checkIsRunFastWinAct(isWin )

    if self:getBetLevel() == 0 then
        return
    end

    if isWin then
        local rodTime = math.random( 1, 100)
        if self:checkIsTright(rodTime ,100 ) then

            self.m_jackPotRunSoundsId =  gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_JackPotLongRun.mp3",false,function(  )
                self.m_jackPotRunSoundsId = nil
            end)


            gLobalSoundManager:setBackgroundMusicVolume(0)
            self.m_FastReels:runCsbAction("actionframe",true)
            self.m_FastReels.m_fastLucyLogo:runCsbAction("actionframe",true)
        end
    end
    
    
end

function CodeGameScreenBeerGirlMachine:showFastWinView(effectData )

    local cash = self.m_runSpinResultData.p_selfMakeData.cash or {}

    local lines = cash.lines
    
    local fixPos = self.m_FastReels:getRowAndColByPos(lines[1].icons[1])

    performWithDelay(self,function(  )

        gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_JackPot_Symbol_win.mp3")
        
        self:removeSoundHandler()

        performWithDelay(self,function(  )
            local jpNode = self.m_FastReels:getReelParent(fixPos.iY):getChildByTag(self:getNodeTag(fixPos.iY,fixPos.iX,SYMBOL_NODE_TAG))
            jpNode:runAnim("actionframe",true)
    
            performWithDelay(self,function(  )
                self.m_FastReels:runCsbAction("idleframe")
                self.m_FastReels.m_fastLucyLogo:runCsbAction("idle1",true)

                local endfunc = function(  )

                    self.m_FastReels:restSelfEffect( effectData.p_selfEffectType )

                    effectData.p_isPlay = true
                    self:playGameEffect()
                end

                self:showJackPotWinView(lines[1].amount ,lines[1].type ,endfunc)
            end,4)
            
        end,3)

    end,0.5)

    
        


    
end

function CodeGameScreenBeerGirlMachine:showJackPotWinView(coins ,symbolType ,func)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "jackpot")
    end

    local data = {}
    data.coins = coins
    data.symbolType = symbolType
    data.func = function(  )

        gLobalSoundManager:setBackgroundMusicVolume(1)

        if func then
            func()
        end
    end
    local fastWinView = util_createView("CodeBeerGirlSrc.BeerGirlFastWinView",data)

    self:addChild(fastWinView,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)

    -- util_getConvertNodePos(self:findChild("viewNode"),fastWinView)
    
    -- fastWinView:setPosition(cc.p(-display.width/2,-display.height/2))
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBeerGirlMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        

        -- 这里加延时是为了等bonus播完落地
        self:collectFixBonus(effectData )

        

    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_TEN_COLLECT then  
        
        self:fixBonusTurnWild( effectData )
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_FAST_WIN then
        
        self:showFastWinView( effectData )
        
       
    end

    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBeerGirlMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenBeerGirlMachine:beginReel()
    
    BaseFastMachine.beginReel(self)

    self:changeFixBonusKuang( )

    if  self:getBetLevel() == 0 then
        self.m_FastReels:stopAllActions()
        self.m_FastReels:clearWinLineEffect()
    else
        self.m_FastReels:beginMiniReel()
    end


end

function CodeGameScreenBeerGirlMachine:insetMiniReelsLines(data )
    if data  and type(data.lines) == "table" then

        if #data.lines > 0 then
           if type(self.m_runSpinResultData.p_winLines) ~=  "table" then
                self.m_runSpinResultData.p_winLines= {}
           end     
        end

        if type(self.m_runSpinResultData.p_winLines) ==  "table" and #self.m_runSpinResultData.p_winLines > 0 then
            
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

function CodeGameScreenBeerGirlMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self,param)

    if param[1] == true then
        local spinData = param[2]
        print(cjson.encode(param[2])) 
        print("消息返回") 
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.cash then
                    if self.m_FastReels then
                        spinData.result.selfData.cash.bet = 0
                        spinData.result.selfData.cash.payLineCount = 0

                        self:changeFastReelsRunData( )

                        self.m_FastReels:netWorkCallFun(spinData.result.selfData.cash)
                    end
                end
            end
            
        end
    end

    
end


-- -----collect 相关
function CodeGameScreenBeerGirlMachine:updateCollectData( )
    
    local selfdata =  self.m_runSpinResultData.p_selfMakeData 

    if selfdata then
        
        self.m_collectData.collectNeedCount = selfdata.collectNeedCount
        self.m_collectData.collectCount = selfdata.collectCount

    end
end


function CodeGameScreenBeerGirlMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.SYMBOL_FIX_BONUS then
                
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end


            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end

function CodeGameScreenBeerGirlMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.SYMBOL_FIX_BONUS then
                
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenBeerGirlMachine:initCloumnSlotNodesByNetData()
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            while true do
                if symbolType ~= self.SYMBOL_FIX_BONUS then
                
                    break
                end

                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + showOrder)
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, changeRowIndex, colIndex, true)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = showOrder

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end

--小块
function CodeGameScreenBeerGirlMachine:getBaseReelGridNode()
    return "CodeBeerGirlSrc.BeerGirlSlotsNode"
end


-- 处理特殊关卡 遮罩层级
function CodeGameScreenBeerGirlMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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
function CodeGameScreenBeerGirlMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_BONUS then
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

function CodeGameScreenBeerGirlMachine:bonusOverAddFreespinEffect( )
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

function CodeGameScreenBeerGirlMachine:AddBonusEffect( isWheelOver)
    local featureDatas = self.m_runSpinResultData.p_features
    local isAddFs = false
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        
            isAddFs = true

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            if isWheelOver then
                bonusGameEffect.p_isWheelOver = isWheelOver
            end
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

        end
    end

    return isAddFs
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenBeerGirlMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusTypes

    if bonusTypes and bonusTypes[1] == "free" then
        
    end
    

    if self:getBetLevel() == 0 then
                
    else
        self.m_FastReels:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self.m_FastReels:clearFrames_Fun()
        -- 取消掉赢钱线的显示
        self.m_FastReels:clearWinLineEffect()
    end 

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    if bonusTypes and bonusTypes[1] == "free" then
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                bonusLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    
    

        local time = 1
        local changeNum = 1/(time * 60) 
        local curvolume = 1
        self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
            curvolume = curvolume - changeNum
            if curvolume <= 0 then

                curvolume = 0

                if self.m_updateBgMusicHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
                    self.m_updateBgMusicHandlerID = nil
                end
            end

            gLobalSoundManager:setBackgroundMusicVolume(curvolume)
        end)

        

        -- performWithDelay(self,function(  )

            -- 停止播放背景音乐
            self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
            -- 播放bonus 元素不显示连线
            if bonusLineValue ~= nil then
                
                self:showBonusAndScatterLineTip(bonusLineValue,function()
                    performWithDelay(self,function(  )
                        self:showBonusGameView(effectData)
                    end,0.5)
                    
                end)
                bonusLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
        
                -- 播放提示时播放音效        
                self:playBonusTipMusicEffect()
                local soundName = "BeerGirlSounds/BeerGirl_Choose_" .. self.m_chooseSoundIndex .. ".mp3"
                gLobalSoundManager:playSound(soundName)
                if self.m_chooseSoundIndex == 1 then
                    self.m_chooseSoundIndex = 2
                elseif self.m_chooseSoundIndex == 2 then
                    self.m_chooseSoundIndex = 1
                end
            else
                self:showBonusGameView(effectData)
            end

            
           
        -- end,0.5)
        
        
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end
---
-- 根据Bonus Game 每关做的处理
--

function CodeGameScreenBeerGirlMachine:showBonusGameView( effectData )
   
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusTypes
    -- self:findChild("BeerGirl_bgshine_1"):setVisible(true)
    self.m_baseCollectBar:setVisible(false)

    if bonusTypes and bonusTypes[1] == "free" then


        if effectData.p_isWheelOver then
            self.m_bottomUI:checkClearWinLabel()
            self:show_Choose_BonusGameView(effectData)
        else
            local time = 1
            self:FadeOutNode( self:findChild("root1"),time)
            self:FadeOutNode( self:findChild("right"),time)
            performWithDelay(self,function( )
                self.m_bottomUI:checkClearWinLabel()
                self:show_Choose_BonusGameView(effectData)
            end,time)
        end
        
 
    else

        effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮
        
    end
    
    
end


function CodeGameScreenBeerGirlMachine:show_Choose_BonusGameView(effectData)
    
    self:findChild("root1"):setVisible(false)
    self:findChild("right"):setVisible(false)
    local chooseView = util_createView("CodeBeerGirlSrc.BeerGirlChooseView",self)
    
    self:findChild("viewNode"):addChild(chooseView)
    chooseView:setPosition(cc.p(-display.width/2,-display.height/2))

    chooseView:setEndCall( function(  )

        self:showGuoChang(1, function(  )
            --修改底板
            self:findChild("reel_free"):setVisible(true)
            self:FadeInNode( self:findChild("root1"),0)
            self:FadeInNode( self:findChild("right"),0)
            self:findChild("root1"):setVisible(true)
            self:findChild("right"):setVisible(true)
            self:bonusOverAddFreespinEffect( )

            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮

            if chooseView then
                chooseView:removeFromParent()
            end
        end)

        
    end)

    
    
end


-- 收集玩法

function CodeGameScreenBeerGirlMachine:removeFlynode(node)
    node:setVisible(true)
    node:removeFromParent()
    node.m_baseBoolFlag = nil
    local symbolType = node.p_symbolType
    self:pushSlotNodeToPoolBySymobolType(symbolType, node)

end



function CodeGameScreenBeerGirlMachine:initCollectKuang(isBetChange )

    
    local totalBet = globalData.slotRunData:getCurTotalBet( ) 
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 

    local selfdata = wilddata or {}  --self.m_runSpinResultData.p_selfMakeData or {}
    local kaungList = selfdata.wildPositions or {}
    local spintimes = selfdata.spinTimes or 0


    if isBetChange and  (spintimes == 10) then
        return
    end

    for i=1,#kaungList do
        local v = kaungList[i]
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_FIX_BONUS, fixPos.iX, fixPos.iY, false)   

        self:checkRemoveOneCacheNode( targSp )

        if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
            targSp.m_baseBoolFlag = true
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            targSp.m_bInLine = false
            targSp:setLinePos(linePos)
            targSp:runAnim("kuang",true)
            targSp:setName(tostring(pos))
            self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_FIX_NODE_TAG - 1) -- 这里的tag值是为了不参与轮盘小块逻辑

            local position =  self:getBaseReelsTarSpPos(pos )
            targSp:setPosition(cc.p(position))
            table.insert( self.m_FixBonusKuang,targSp)
        end

               

    end
        
        


end

--收集玩法
function CodeGameScreenBeerGirlMachine:lockWild(list, func)

    -- gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_bonus.mp3")
    local isShowCollect = false
    for _, node in pairs(list) do
        -- node:runAnim("idleframe")
        
        local reelIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex )
        local oldNode = self.m_clipParent:getChildByName(tostring(reelIndex))
        if oldNode then
            node:stopAllActions()
            node:runAnim("idle3")
            oldNode:stopAllActions()
            oldNode:runAnim("shouji2",false,function (  )
                
                if oldNode.p_symbolType then
                    oldNode:runAnim("kuang",true)
                end
            end)
        else
            node:stopAllActions()
            node:runAnim("idle3")
            local posWorld = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
            local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            --创建一个固定框，保留在self.m_clipParent
            local lockKuang = self:getSlotNodeWithPosAndType(self.SYMBOL_FIX_BONUS, node.p_rowIndex, node.p_cloumnIndex, false)
            lockKuang:runAnim("kuang",true)
            self:checkRemoveOneCacheNode( lockKuang )

            lockKuang.m_baseBoolFlag = true
            local linePos = {}
            lockKuang.m_bInLine = false
            lockKuang:setLinePos(linePos)
            lockKuang:setName(tostring(reelIndex))
            lockKuang.m_symbolTag = SYMBOL_FIX_NODE_TAG
            lockKuang.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            lockKuang.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            
            
            lockKuang:setPosition(cc.p(pos.x, pos.y))
            lockKuang:removeFromParent()
            self.m_clipParent:addChild(lockKuang, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1, SYMBOL_FIX_NODE_TAG - 1) -- 这里的tag值是为了不参与轮盘小块逻辑
            lockKuang:stopAllActions()
            lockKuang:runAnim("shouji2",false,function (  )
                if lockKuang.p_symbolType then
                    lockKuang:runAnim("kuang",true)
                end
                
            end)
            

            table.insert( self.m_FixBonusKuang,lockKuang)

        end



        
    end


        if func ~= nil then
            func()
        end


end


--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenBeerGirlMachine:getBaseReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenBeerGirlMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end


-- 高低bet

function CodeGameScreenBeerGirlMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenBeerGirlMachine:updatJackPotLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            
            
            gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_jackpot_Reels_unlock.mp3")
            self.m_FastReels:runCsbAction("shangsheng")
            
            self.m_betLevel = 1  
        end
    else

        if self.m_betLevel == nil or self.m_betLevel == 1 then

            gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_jackpot_Reels_lock.mp3")
            self.m_FastReels:stopAllActions()
            self.m_FastReels:clearWinLineEffect()
            
            self.m_FastReels:runCsbAction("xialuo",false,function(  )
            end)

            self.m_betLevel = 0  
        end
        
    end 
end

function CodeGameScreenBeerGirlMachine:getMinBet( )
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
function CodeGameScreenBeerGirlMachine:upateBetLevel()

    

    local minBet = self:getMinBet( )
    self:updatJackPotLock( minBet ) 
    
end

function CodeGameScreenBeerGirlMachine:localRequestSpinResult( )
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

function CodeGameScreenBeerGirlMachine:requestSpinResult()


    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        if self.m_FreeSpinFixBonusKuang and #self.m_FreeSpinFixBonusKuang then

            local freeSpinLeftTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
            local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            --框开始移动
            self:MoveFsKuang( function(  )
                self:localRequestSpinResult( )
            end )

        else
            self:localRequestSpinResult( )
        end
    else

        
        local totalBet = globalData.slotRunData:getCurTotalBet( ) 
        local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 

        local selfdata =  wilddata or {}
        local spinTimes = selfdata.spinTimes or 0
        if spinTimes then

            if spinTimes == 10 then
                spinTimes = 0
            end
            
            self.m_baseCollectBar:updateTimes(spinTimes + 1,10)
        end

        self:localRequestSpinResult( )
    end

    
        

end

function CodeGameScreenBeerGirlMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    -- self.m_gameTip:setVisible(false)
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:runCsbAction("idle0",true) 
end

function CodeGameScreenBeerGirlMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    -- self.m_gameTip:setVisible(true)
    -- self.m_gameTip:runCsbAction("animation0",true,nil,30)
    self.m_baseFreeSpinBar:runCsbAction("idle1") 
end

function CodeGameScreenBeerGirlMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("fs_tishi")
        self.m_baseFreeSpinBar = util_createView("CodeBeerGirlSrc.BeerGirlFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
        self.m_baseFreeSpinBar:setPosition(0, 0)
    end
end


function CodeGameScreenBeerGirlMachine:createFsMoveKuang( func,isinit)
    self.m_FreeSpinFixBonusKuang = {}

    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local startWildPositions =  selfData.startWildPositions 


    local kaungStarActName = {"up","under","left","right","up_left","up_right","under_right","under_left"}

    if startWildPositions then
        for i=1,#startWildPositions do
            local v = startWildPositions[i]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_FIX_BONUS, fixPos.iX, fixPos.iY, false)   
            
            self:checkRemoveOneCacheNode( targSp )

            if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
                targSp.m_baseBoolFlag = true
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                local linePos = {}
                linePos[#linePos + 1] = {}
                targSp.m_bInLine = false
                targSp:setLinePos(linePos)
                targSp:runAnim("kuang",true)
                targSp:setName("fsKuang_" .. tostring(i))
                self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_FIX_NODE_TAG + 1) -- 为了参与连线
                
                if not isinit then
                    if pos > 10 then
                        pos = pos + 21
                    else
                        pos =  pos -21
                    end
                    targSp:setVisible(false)
                end
                

                local position =  self:getBaseReelsTarSpPos(pos )
                targSp:setPosition(cc.p(position))
                table.insert( self.m_FreeSpinFixBonusKuang,targSp)

                local actName = kaungStarActName[math.random( 1, #kaungStarActName)]
                --if isinit then
                    actName = "kuang"
                --end
                
                if i == 1 then
                    targSp:runAnim(actName,false,function(  )
                        targSp:runAnim("kuang",true)
                        if func then
                            func()
                        end
                    end)
                else

                    targSp:runAnim(actName,false,function(  )
                        targSp:runAnim("kuang",true)
                    end)
                    
                end
            end
        end
    end


end



function CodeGameScreenBeerGirlMachine:MoveFsKuang( fun )

    local fsKuangNum = #self.m_FreeSpinFixBonusKuang
    self.m_FreeSpinFixBonusKuang = {}

    local moveList= {}


    local selfData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildPositions =  selfData.wildPositions 
    if wildPositions then
        for i=1,fsKuangNum do

            local targSp = self.m_clipParent:getChildByName("fsKuang_" .. tostring(i)) 

            targSp:setVisible(true)
            targSp:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_FIX_BONUS ),self.SYMBOL_FIX_BONUS)

            table.insert( self.m_FreeSpinFixBonusKuang, targSp )

            local v = wildPositions[i]
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)

            local node = targSp --self.m_FreeSpinFixBonusKuang[i]
            node.p_cloumnIndex = fixPos.iY
            node.p_rowIndex = fixPos.iX
            local linePos = {}
            linePos[#linePos + 1] = {iX = node.p_rowIndex, iY = node.p_cloumnIndex}
            node.m_bInLine = true
            node:setLinePos(linePos)

            local oldPos = cc.p(node:getPosition())
            local position =  self:getBaseReelsTarSpPos(pos )

            local turnOldX = 1
            if (oldPos.x - position.x) < 0 then
                turnOldX = -1
            elseif (oldPos.x - position.x) == 0 then
                turnOldX = 0
            end 
            local turnOldY = 1
            if (oldPos.y - position.y) < 0 then
                turnOldY = -1
            elseif (oldPos.y - position.y) == 0 then
                turnOldY = 0
            end

            local turnNewX =  1
            if (position.x - oldPos.x ) < 0 then
                turnNewX =  -1
            elseif (position.x - oldPos.x ) == 0 then
                turnNewX =  0

            end
            local turnNewY =  1
            if (position.y - oldPos.y ) < 0 then
                turnNewY =  -1
            elseif (position.y - oldPos.y ) == 0 then
                turnNewY =  0
            end

            local actList = {}
            actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                targSp:runAnim("kuang",true)
            end)
            actList[#actList + 1 ] = cc.DelayTime:create(0.1)
            actList[#actList + 1 ] = cc.CallFunc:create(function(  )
                local actList_1 = {}
                actList_1[#actList_1 + 1 ] = cc.ScaleTo:create(1.2,1.35)
                local sq_1 = cc.Sequence:create(actList_1)
                node:runAction(sq_1)

            end)
            -- actList[#actList + 1 ] = cc.MoveTo:create(0.5,cc.p(oldPos.x + ( 20 * turnOldX ),oldPos.y + ( 20 * turnOldY )))
            -- actList[#actList + 1 ] = cc.MoveTo:create(2,cc.p(position.x + ( 20 * turnNewX ),position.y + ( 20 * turnNewY)))
            actList[#actList + 1 ] = cc.MoveTo:create(1.2,cc.p(position))
            actList[#actList + 1 ] = cc.DelayTime:create(0.1)
            if i == 1 then
                actList[#actList + 1] = cc.CallFunc:create(function(  )
                    gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_Bonus_za.mp3")
                end)
            end
            
            actList[#actList + 1 ] = cc.ScaleTo:create(0.1,1)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                targSp:runAnim("bonus_wild",false)
            end)
            if i == 1 then
                actList[#actList + 1 ] = cc.CallFunc:create(function(  )


                    for k=1,#self.m_FreeSpinFixBonusKuang do
                        local node = self.m_FreeSpinFixBonusKuang[k]
                        node.m_baseBoolFlag = true
                        node:setName("fsKuang_" .. tostring(k))
                    end
                    
                    
                    if fun then
                        fun()
                    end

                    

                    
                    
                end)
            end

            
            local sq = cc.Sequence:create(actList)
            -- node:runAction(cc.RepeatForever:create(sq))
            node:runAction(sq)
        end
    end
end


local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenBeerGirlMachine:addLastWinSomeEffect() -- add big win or mega win

    if #self.m_vecGetLineInfo == 0  then
        return
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
                self:checkHasEffectType(GameEffect.EFFECT_EPICWIN) == true or
                    self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenBeerGirlMachine:initGameStatusData(gameData)
    
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

    if gameData.gameConfig ~= nil and  gameData.gameConfig.bets ~= nil then
        self:initBetNetKuangData(gameData.gameConfig.bets)
    end

    self:initMachineGame()
end


function CodeGameScreenBeerGirlMachine:checkInitSpinWithEnterLevel( )
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
       
       
        if self.m_initFeatureData == nil then
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

---
-- 进入关卡
--
function CodeGameScreenBeerGirlMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:initKuangUI( )
    
    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects( )
        self:playGameEffect()
    end
end

function CodeGameScreenBeerGirlMachine:initKuangUI( )
    self:updateCollectData( )
    local needCount = self.m_collectData.collectNeedCount 
    local collectCount =  self.m_collectData.collectCount 
    -- self:updateCollectLoading(collectCount ,needCount,true)

    self:updateCollectTimes( )

    
    local totalBet = globalData.slotRunData:getCurTotalBet( ) 
    local wilddata =  self.m_betNetKuangData[tostring(toLongNumber(totalBet))] 
    local selfdata =  wilddata or {}
    local oldSpinTimes = selfdata.spinTimes or 0
  
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if oldSpinTimes and oldSpinTimes == 10  then
            -- 第10次就不还原固定框了
        else
            self:initCollectKuang( )
        end
        
    else    

        local selfdata = self.m_runSpinResultData.p_fsExtraData or {}
        if selfdata.collect then
            self.m_bottomUI:showAverageBet()
        end
        
        self:createFsMoveKuang( nil, true )
        self.m_baseCollectBar:setVisible(false)
        self:findChild("BeerGirl_bgshine_1"):setVisible(true)
        -- self.m_topCollectBar:setVisible(false)
    end

end

function CodeGameScreenBeerGirlMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and 
        #self.m_runSpinResultData.p_features > 0 then
        
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i=1,featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的， 
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes

                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then  -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 and 
                        #self.m_runSpinResultData.p_storedIcons == 15 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then  -- 其他小游戏

                    local isFreeSpinOver = false
                    if self:getCurrSpinMode() == FREE_SPIN_MODE then

                        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
                            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                                isFreeSpinOver = true
                            end
                        end
                
                    end

                    -- freespin over那次的bonus不走底层添加
                    if not isFreeSpinOver then
                       -- 添加 BonusEffect 
                        self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL) 
                    end
                    
                    
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end

            end
            
        end

    end
end


function CodeGameScreenBeerGirlMachine:setSlotNodeEffectParent(slotNode)
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

    

    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end

function CodeGameScreenBeerGirlMachine:playEffectNotifyChangeSpinStatus( )

    if self:getBetLevel() == 1  then
        if self.m_isOutLines then
            BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
        else
            self:setNormalAllRunDown(1 )
        end
        
    else
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
    end

     
    

end

function CodeGameScreenBeerGirlMachine:setNormalAllRunDown( times)

    self.m_norDownTimes = self.m_norDownTimes + times

    print("setNormalAllRunDown   "..self.m_norDownTimes)
    if self.m_norDownTimes == 2 then
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
        self.m_norDownTimes = 0
    end

    
end

function CodeGameScreenBeerGirlMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function CodeGameScreenBeerGirlMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()
    reelEffectNode:setName("reelEffectNode"..col)
    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

---
--添加金边
function CodeGameScreenBeerGirlMachine:creatReelRunAnimation(col)
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

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")
    reelEffectNode:getParent():setOpacity(255)
    reelEffectNode:setOpacity(255)
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenBeerGirlMachine:setBetId( )

    local minBet = self:getMinBet()

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
            -- 大于等于
        if bets.p_totalBetValue >= minBet then

            globalData.slotRunData.iLastBetIdx =   bets.p_betId

            break
        end
    end

    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

end

function CodeGameScreenBeerGirlMachine:changeBetToUnlock( )

   if self:getBetLevel() then
       

        if self:getBetLevel() == 0 then
            self:setBetId( )
        end

   end 
    
end

--设置长滚信息
function CodeGameScreenBeerGirlMachine:setReelRunInfo()
    
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
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 9) 
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

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenBeerGirlMachine:specialSymbolActionTreatment( node)
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) then
        node:runAnim("buling",false,function(  )
            node:runAnim("idleframe",true)
        end)
    end
end

function CodeGameScreenBeerGirlMachine:getBottomUINode( )
    return "CodeBeerGirlSrc.BeerGirlGameBottomNode"
end


function CodeGameScreenBeerGirlMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)

    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i=1,#newChilds do
            childs[#childs+1]=newChilds[i]
        end
    end

    for childIndex = 1, #childs do

        local child = childs[childIndex]
        self:moveDownCallFun(child, parentData.cloumnIndex)
    end

    local index = 1

    while index <= columnData.p_showGridCount do -- 只改了这 为了适应freespin
        self:createSlotNextNode(parentData)
        local symbolType = parentData.symbolType
        local node = self:getCacheNode(parentData.cloumnIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
            local slotParentBig = parentData.slotParentBig
            -- 添加到显示列表
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, parentData.order, parentData.tag)
            else
                slotParent:addChild(node, parentData.order, parentData.tag)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(parentData.order)
            node:setTag(parentData.tag)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        end
        
        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol

        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        node:runIdleAnim()
        -- node:setVisible(false)
        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
            -- 创建一个假的小块 在回滚停止后移除

            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end


end

function CodeGameScreenBeerGirlMachine:moveDownCallFun(node, colIndex)
    -- 回收对象
    if node and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
        node:setVisible(true)
        node:removeFromParent()
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
        print("回收对象".. node.p_symbolType)
        return
    end

    if node and node.m_baseBoolFlag then -- 使用底层池子的不能用basefast的缓存池机制得自己维护
        node.m_baseBoolFlag = nil
        print("回收对象  m_baseBoolFlag ".. node.p_symbolType)
        node:setVisible(true)
        node:removeFromParent()
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
        return
    end

    local symbolNodeList = self.cacheNodeMap[colIndex]
    if symbolNodeList == nil then
        symbolNodeList = {}
        self.cacheNodeMap[colIndex] = symbolNodeList
    end
    node:reset()
    node:setVisible(false)
    node:setTag(-1)
    node.cacheFlag = true
    table.insert(symbolNodeList, node)
end


---
-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
--
function CodeGameScreenBeerGirlMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    
    if node and node.m_baseBoolFlag then -- 使用底层池子的不能用basefast的缓存池机制得自己维护
        node.m_baseBoolFlag = nil
    end
    node:setVisible(true)
    BaseFastMachine.pushSlotNodeToPoolBySymobolType(self,symbolType, node)
end

function CodeGameScreenBeerGirlMachine:waitCallFunc( _time,_func)
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        if _func then
            _func()
        end
        node:removeFromParent()
    end,_time)
end

function CodeGameScreenBeerGirlMachine:checkRemoveOneCacheNode(_node )
   
    for kk,value in pairs(self.cacheNodeMap) do
        local symbolNodeList = value
        if symbolNodeList ~= nil then
            for i=#symbolNodeList,1,-1 do
                if _node == symbolNodeList[i] then
                   table.remove(symbolNodeList, i)
                end
            end
        end

    end

end

function CodeGameScreenBeerGirlMachine:showInLineSlotNodeByWinLines(winLines,startIndex,endIndex,bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
    	bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex=1,#self.m_lineSlotNodes do

                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end

            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end

            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex=startIndex,endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and
            lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then

            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i=1,frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and
                    self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then

                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do

                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex=1,#bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode==nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end

                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode==nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil  then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and
                    self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then

                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do

                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex=1,#bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                if slotNode then
                                    if slotNode.p_symbolType then
            
                                    else
                                        print("__________ 错")
                                    end
                                      
                                end
                                isBigSymbol = true
                                break
                            end
                        end

                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                        if slotNode then
                            if slotNode.p_symbolType then
    
                            else
                                print("__________ 错")
                            end
                              
                        end
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    if slotNode then
                        if slotNode.p_symbolType then

                        else
                            print("__________ 错")
                        end
                          
                    end
                end

                if slotNode then
                    if slotNode.p_symbolType then

                    else
                        print("__________ 错")
                    end
                      
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    if sepcicalNode.p_symbolType then
                   
                    else
                        print("__________ 错")
                    end
                end
                
                  
                if sepcicalNode ~= nil  then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    if slotNode then
                        if slotNode.p_symbolType then
                            self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                        else
                            print("__________ 错")
                        end
                          
                    end
                    
                end

                ---
            end  -- end for i = 1 frameNum

        end -- end if freespin bonus


    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    -- local specialChilds = self:getAllSpecialNode()
    -- for specialIndex =1,#specialChilds do
    --     local specialNode = specialChilds[specialIndex]
    --     checkAddLineSlotNode(specialNode)
    -- end

end

function CodeGameScreenBeerGirlMachine:showLineFrame()
    local winLines = self.m_reelResultLines
    
    
    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)
    local isHaveLongSlot = self:isHaveLongSlots(winLines)
    if isHaveLongSlot then
        local soundName = "BeerGirlSounds/music_BeerGirl_LongSlots_" .. self.m_longSlotSoundIndex .. ".mp3"
        self:changeSoundIndex(self.m_longSlotSoundIndex)
        gLobalSoundManager:playSound(soundName)
    end

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            if frameIndex > #winLines  then
                frameIndex = 1
                if self.m_showLineHandlerID ~= nil then

                    scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                    self.m_showLineHandlerID = nil
                    self:showAllFrame(winLines)
                    self:playInLineNodes()
                    showLienFrameByIndex()
                end
                return
            end
            self:playInLineNodesIdle()
            -- 跳过scatter bonus 触发的连线
            while true do
                if frameIndex > #winLines then
                    break
                end
                -- print("showLine ... ")
                local lineData = winLines[frameIndex]

                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self:getCurrSpinMode() == FREE_SPIN_MODE then


        self:showAllFrame(winLines)  -- 播放全部线框

        -- if #winLines > 1 then
            showLienFrameByIndex()
        -- end

    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end


        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines,1)
        end

    end
end

function CodeGameScreenBeerGirlMachine:isHaveLongSlots()
    for i,v in ipairs(self.m_lineSlotNodes) do
        if v.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            return true
        end
    end
    return false
end

function CodeGameScreenBeerGirlMachine:changeSoundIndex(soundIndex)
    if soundIndex == 1 then
        self.m_longSlotSoundIndex = 2
    elseif soundIndex == 2 then
        self.m_longSlotSoundIndex = 1
    end
end

function CodeGameScreenBeerGirlMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "free" == _sFeature then
        return
    end
    
    if CodeGameScreenBeerGirlMachine.super.levelDeviceVibrate then
        CodeGameScreenBeerGirlMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenBeerGirlMachine






