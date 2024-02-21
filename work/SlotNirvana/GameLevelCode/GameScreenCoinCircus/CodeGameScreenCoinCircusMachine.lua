---
-- island
-- 2018年6月4日
-- CodeGameScreenCoinCircusMachine.lua
-- 
-- 玩法：
-- 


local BaseNewReelMachine              = require "Levels.BaseNewReelMachine"
local GameEffectData                  = require "data.slotsdata.GameEffectData"
local BaseDialog                      = util_require("Levels.BaseDialog")
local GamePusherManager               = require "CoinCircusSrc.GamePusherManager"
local Config                          = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")
local CodeGameScreenCoinCircusMachine = class("CodeGameScreenCoinCircusMachine", BaseNewReelMachine)

CodeGameScreenCoinCircusMachine.SYMBOL_BONUS_1                  = 94
CodeGameScreenCoinCircusMachine.SYMBOL_BONUS_2                  = 97
CodeGameScreenCoinCircusMachine.SYMBOL_BONUS_3                  = 96
CodeGameScreenCoinCircusMachine.SYMBOL_BONUS_4                  = 95

CodeGameScreenCoinCircusMachine.MAIN_ADD_POSY                   = 25

CodeGameScreenCoinCircusMachine.m_pGamePusherMgr                = nil       -- game推币机管理类

CodeGameScreenCoinCircusMachine.m_diskEntityDataID              = nil       -- 服务器传回的初始化轮盘类型
CodeGameScreenCoinCircusMachine.m_diskEntityDataCoinOdd         = nil       -- 服务器传回初始化时普通金币变随机金币的概率 ：小数
CodeGameScreenCoinCircusMachine.m_diskEntityDataJackpotHave     = nil       -- 服务器传回初始化时本次是否有jackpot金币 ：-- 1：有 0：无


CodeGameScreenCoinCircusMachine.m_nBonusID                      = nil       -- 本地数据存储Key

CodeGameScreenCoinCircusMachine.m_bonusEffectData               = nil       -- 存储正常触发或断线重连的推币机bonus游戏事件数据

CodeGameScreenCoinCircusMachine.CHANGE_BIG_SYMBOL_EFFECT        = GameEffect.EFFECT_SELF_EFFECT - 89 
CodeGameScreenCoinCircusMachine.PUSHER_RECONNECTING_EFFECT      = GameEffect.EFFECT_SELF_EFFECT - 99 -- 推币机断线重连，最先触发

local VEC_PROP_KEYS = 
{
    "wallMaxUseNum",
    "shakeMaxUseNum",
    "bigCoinMaxUseNum"
}

local VEC_PROP_TYPES = 
{
    wallMaxUseNum = 95,
    shakeMaxUseNum = 96,
    bigCoinMaxUseNum = 97
}

local SYNC_DIRTY_DATA_TIME      =       2 --同步脏数据时间间隔

--[[
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
     !!!!!!!!!!!!  !!!!!!!!!!!!
     !!!!!!!!!        !!!!!!!!!
     !!!!!!!    注意     !!!!!!!

     修改此关一定要注意推币机数据存储问题
     1、此关的数据存储是存储在CCUserDefault，Key：关卡服务器名称 + 用户udid 拼接 ；self.m_nBonusID  
     2、当有推币机数据修改时，例如新加推币机里的小玩法等等：请评估线上老用户的问题，因为推币机所有数据都是存储在本地，一旦修改
        数据逻辑，必然会导致老数据与新代码不兼容的问题，建议做法：服务器与客户端改 NetWorkModuleName，把这个需求当成一个新关做

   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
]]

-- 构造函数
function CodeGameScreenCoinCircusMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isOpenRewaedFreeSpin = true

    self.m_isSyncDirty = false
    self.m_spinRestMusicBG = true

    self.m_longRunBonusColList = {}

    self.m_mysterList = {}
    for i = 1, 5 do
        self.m_mysterList[i] = -1
    end
    self.m_initNodeCol = 0
    self.m_initNodeSymbolType = 0

    self.m_BonusWinCoins = 0
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenCoinCircusMachine:initGame()
 

    self.m_configData = gLobalResManager:getCSVLevelConfigData("CoinCircusConfig.csv", "LevelCoinCircusConfig.lua")

	--初始化基本数据
    self:initMachine(self.m_moduleName)
    local DeluexeName = ""
    if globalData.slotRunData.isDeluexeClub == true then
        DeluexeName = "Deluexe"
    end
    self.m_nBonusID         = self:getNetWorkModuleName().. DeluexeName .. globalData.userRunData.userUdid
    self.m_pGamePusherMgr   = GamePusherManager:getInstance()
    self.m_pGamePusherMgr.m_machine = self
end  

function CodeGameScreenCoinCircusMachine:initUI()

    self:runCsbAction("idle",true)


    self.m_jpBar = util_createView("CoinCircusSrc.CoinCircusJackPotBarView")
    self:findChild("jakcpot_kuang"):addChild(self.m_jpBar)
    self.m_jpBar:initMachine(self)
    local buyTxNode = self.m_topUI:findChild("buy_tx")
    if buyTxNode then
        local pos = util_convertToNodeSpace(buyTxNode,self:findChild("jakcpot_kuang"))
        if display.height > 1580 then
            local posAdd = (display.height - 1520) * 0.2
            self.m_jpBar:setPosition(cc.p(pos.x,pos.y - 215 - posAdd )) 
        else
            self.m_jpBar:setPosition(cc.p(pos.x,pos.y - 215)) 
        end
        
    end

    self.m_syncDirtyNode = cc.Node:create()
    self:addChild(self.m_syncDirtyNode)
    
    self.m_guoChang = util_createAnimation("CoinCircus_guochang.csb") 
    self:addChild(self.m_guoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChang:setPosition(display.width/2,display.height/2)
    self.m_guoChang:setVisible(false)

    self.m_logo = util_createAnimation("CoinCircus_logo.csb") 
    self:findChild("logo"):addChild(self.m_logo)
    self.m_logo:runCsbAction("idle",true)
    
    self.m_playTip = util_createAnimation("CoinCircus_tishi.csb") 
    self:findChild("tishi"):addChild(self.m_playTip)
    self.m_playTip:runCsbAction("animation0",true)
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
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
            elseif winRate > 3 then
                soundIndex = 3
            end

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = "CoinCircusSounds/sound_CoinCircus_last_win" .. soundIndex .. ".mp3"
            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    
    
end

function CodeGameScreenCoinCircusMachine:scaleMainLayer()
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

        mainScale = display.height / (self:getReelHeight() + uiH + uiBH)
        if display.height > DESIGN_SIZE.height then
            mainScale = DESIGN_SIZE.height / (self:getReelHeight() + uiH + uiBH)
            if display.height >= 1520 then
                local pos = (display.height - 1520) * 0.3
                self.MAIN_ADD_POSY = self.MAIN_ADD_POSY + pos
                
            end
            
        else
            self.MAIN_ADD_POSY = 60
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + self.MAIN_ADD_POSY )

        
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCoinCircusMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "CoinCircus"  
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCoinCircusMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_CoinCircus_Bonus_1"
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_CoinCircus_Bonus_2"
    elseif symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_CoinCircus_Bonus_3"
    elseif symbolType == self.SYMBOL_BONUS_4 then
        return "Socre_CoinCircus_Bonus_4"
    end
    

    return nil
end

----------------------------- 玩法处理 -----------------------------------

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenCoinCircusMachine:MachineRule_afterNetWorkLineLogicCalculate()


end


function CodeGameScreenCoinCircusMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol)   

end

function CodeGameScreenCoinCircusMachine:getNetWorkModuleName()
    return "CoinCircus"
end

-- 断线重连 
function CodeGameScreenCoinCircusMachine:MachineRule_initGame()

end

---
-- 数据生成之后
-- 改变轮盘ui块生成列表 (可以作用于贴长条等 特殊显示逻辑中)
function CodeGameScreenCoinCircusMachine:MachineRule_InterveneReelList()

end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCoinCircusMachine:MachineRule_ResetReelRunData()


end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCoinCircusMachine:MachineRule_SpinBtnCall()

    
    self:setMaxMusicBGVolume()
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil 
    end
    self:removeChangeReelDataHandler()
    self:randomMystery()

    return false
end

function CodeGameScreenCoinCircusMachine:slotReelDown()

    BaseNewReelMachine.slotReelDown(self) 

end

function CodeGameScreenCoinCircusMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenCoinCircusMachine:MachineRule_stopReelChangeData()

end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCoinCircusMachine:addSelfEffect()



    self.m_changeBigData = self:isNeedChangeBigSymbol( )
    -- 自定义动画创建方式
    if self.m_changeBigData.isChange then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.CHANGE_BIG_SYMBOL_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGE_BIG_SYMBOL_EFFECT -- 动画类型
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCoinCircusMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.PUSHER_RECONNECTING_EFFECT then

        self.m_bonusEffectData = effectData
        self.m_bonusEffectData.m_outLine = true
        

    elseif effectData.p_selfEffectType == self.CHANGE_BIG_SYMBOL_EFFECT then
            self:changeBigSymbolEffect(effectData)
    end

    return true
end


function CodeGameScreenCoinCircusMachine:enterGamePlayMusic(  )
    if not self:checkHasGameEffectType(GameEffect.EFFECT_REWARD_FS_START) then
        self:playEnterGameSound("CoinCircusSounds/music_CoinCircus_enter.mp3")
    end
    
end



function CodeGameScreenCoinCircusMachine:onEnter()

    BaseNewReelMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()


    -- -- 嵌入推币机 
    self:createGamePusher()
    
    if self.m_bonusEffectData then
        if self.m_bonusEffectData.m_outLine then
            self.m_bonusEffectData.m_outLine = nil
            -- 真正开始推币机断线重连逻辑
            -- 这个接口作为断线重连触发时真正开始推币机玩法的入口
            self:pusherGamebegin(true )
        end
    end
    
end


---
-- 进入关卡
--
function CodeGameScreenCoinCircusMachine:enterLevel()

    BaseNewReelMachine.enterLevel(self)
end

function CodeGameScreenCoinCircusMachine:createGamePusher()



    -- 创建推币机时，如果当前的bonus状态不是 OPEN 就把推币机数据清掉
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""

    if bonusStatus ~= "OPEN" then
        self.m_pGamePusherMgr:clearRunningPusherData(  )
        self.m_pGamePusherMgr:clearSendOverStates( )
        self.m_pGamePusherMgr:clearPusherEntityData( )
        
    end
    
    --load游戏数据
    -- local runningData = self.m_pGamePusherMgr:loadRunningData(  )
    -- local PuserPropData = runningData.playingData or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    -- if PuserPropData and table_length(PuserPropData) ~= 0 then
    --     print("本地有数据")
    -- else
    --     self.m_pGamePusherMgr:clearRunningPusherData(  )
    -- end

    self.m_pGamePusherMgr:setSlotMainRootScale( self.m_machineRootScale)

    self.m_pGamePusherMain = self.m_pGamePusherMgr:pubCreatePusher()
    self:addChild(self.m_pGamePusherMain,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1) 



end

function CodeGameScreenCoinCircusMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- bonusover

            self:resetMusicBg(true)  
            
            if self.m_bonusEffectData then
                self.m_bonusEffectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
                self.m_bonusEffectData = nil
            end
            
        end,
        ViewEventType.COINCIRCUS_NOTIC_BONUS_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- bonusover

            self:clearCurMusicBg()
            
        end,
        ViewEventType.COINCIRCUS__NOTIC_CLEARMUSIC
    )

    gLobalNoticManager:addObserver(self,
        function(self, params)
            self:handleBuyPropResult(params)
        end,
    Config.Event.GamePusherUseProp)

    --切换到后台
    gLobalNoticManager:addObserver(self,function(self, params)
        self.m_pGamePusherMgr:saveRunningData()
        if self.m_pGamePusherMain then
            self.m_pGamePusherMain:saveEntityData(true)
        end
        self.m_syncDirtyNode:stopAllActions()
    end,ViewEventType.APP_ENTER_BACKGROUND_EVENT)

    --同步脏数据
    gLobalNoticManager:addObserver(self,function(self, params)
        
        self:startSyncDirtyData()
        
    end,Config.Event.GamePusher_Sync_Dirty_Data)

end

--[[
    开启同步脏数据定时
]]
function CodeGameScreenCoinCircusMachine:startSyncDirtyData()
    if self.m_isSyncDirty then
        return
    end
    self.m_isSyncDirty = true

    --开启同步后每2秒存一次数据
    performWithDelay(self.m_syncDirtyNode,function()
        self.m_isSyncDirty = false
        self.m_pGamePusherMgr:saveRunningData()
    end,SYNC_DIRTY_DATA_TIME)
end


function CodeGameScreenCoinCircusMachine:onExit()
    if self.m_pGamePusherMgr then
        self.m_pGamePusherMgr:saveRunningData()
    end

    if self.m_pGamePusherMain then
        self.m_pGamePusherMain:saveEntityData(true)
    end
    
    BaseNewReelMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()
    self:removeChangeReelDataHandler()
    scheduler.unschedulesByTargetName(self:getModuleName())
end


function CodeGameScreenCoinCircusMachine:removeObservers()
	BaseNewReelMachine.removeObservers(self)

	-- 自定义的事件监听，也在这里移除掉
end


--[[
   *****************
   bonus推币机玩法
]]

-- 初始化上次游戏状态数据
--
function CodeGameScreenCoinCircusMachine:initGameStatusData(gameData)
    BaseNewReelMachine.initGameStatusData(self, gameData)

    local sequenceId = 0
    if gameData then
        if gameData.sequenceId then
            sequenceId = gameData.sequenceId
        end
        if gameData.gameConfig then
            if gameData.gameConfig.init then
                if gameData.gameConfig.init.type then
                    self.m_diskEntityDataID = gameData.gameConfig.init.type
                end

                if gameData.gameConfig.init.coinOdd then
                    self.m_diskEntityDataCoinOdd = gameData.gameConfig.init.coinOdd
                end

                if gameData.gameConfig.init.jackpot then
                    self.m_diskEntityDataJackpotHave = gameData.gameConfig.init.jackpot
                end
            end
        end
    end

    self.m_pGamePusherMgr:setBonusID(self.m_nBonusID)
    self.m_pGamePusherMgr:setDiskEntityDataID(self.m_diskEntityDataID)
    self.m_pGamePusherMgr:setDiskEntityDataCoinOdd(self.m_diskEntityDataCoinOdd)
    self.m_pGamePusherMgr:setDiskEntityDataJackpotHave(self.m_diskEntityDataJackpotHave)

    self.m_pGamePusherMgr:initSaveKey()

    local clearOldData = gLobalDataManager:getBoolByField("clearOldData" .. self.m_nBonusID, false)

    if sequenceId == 0 then
        self:clearTriggerPusherTimes()
        -- 第一次进或者清除服务器数据时清除本地推币机金币数据
        self.m_pGamePusherMgr:clearPusherEntityData()
    end

    if clearOldData == false then
        self:clearTriggerPusherTimes()
        -- 第一次进或者清除服务器数据时清除本地推币机金币数据
        gLobalDataManager:setStringByField(self.m_pGamePusherMgr.m_sEntitySaveKey, "{}", true)
        gLobalDataManager:setStringByField(self.m_pGamePusherMgr.m_sDataSaveKey, "{}", true)
        gLobalDataManager:setBoolByField("clearOldData" .. self.m_nBonusID, true)
    end
end

function CodeGameScreenCoinCircusMachine:saveTriggerPusherTimes()
    local str = "Triggered"

    gLobalDataManager:setStringByField(self.m_nBonusID .. "pusherTriggered", str, true)
end

function CodeGameScreenCoinCircusMachine:clearTriggerPusherTimes()
    gLobalDataManager:delValueByField(self.m_nBonusID .. "pusherTriggered")
end

function CodeGameScreenCoinCircusMachine:loadTriggerPusherTimes()
    local str = gLobalDataManager:getStringByField(self.m_nBonusID .. "pusherTriggered", "")
    return str
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenCoinCircusMachine:showBonusGameView(effectData)


    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    performWithDelay(self,function(  )
        -- 触发时清理本地推币机数据
        self.m_pGamePusherMgr:clearRunningPusherData()  

        -- 触发时存储数据
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpotCoinOdd = selfData.jackpotCoinOdd -- 随机一个初始金币为jackpot金币
        local randomCoinOdd = selfData.randomCoinOdd -- 每个金币都有概率变为随机金币
        local coins = selfData.coins or {} -- 每个触发bonus给的可以推的个数
        local gems  = selfData.gems or {} -- 道具需要的钱数

        local pusherMaxUseNum = 0 -- 推币机最多可推的个数
        for pos,num in pairs(coins) do
            pusherMaxUseNum = pusherMaxUseNum + tonumber(num)
        end

        local wallMaxUseTimes = 0 -- 墙道具可使用的倒计时
        local bigCoinMaxUseNum = selfData.items.bigCoin or 0 --大金币掉落道具可使用的最大次数
        local shakeMaxUseNum = selfData.items.shake or 0 -- 震动道具可使用的最大次数
        local wallMaxUseNum = selfData.items.wall or 0 --大金币掉落道具可使用的最大次数

        local isTriggered = self:loadTriggerPusherTimes()
        if isTriggered and isTriggered == "Triggered" then
            Config.ShowTipTimes = Config.SecondShowTipTimes
            Config.OverTimes    = Config.SecondShowOverTimes
        else
            Config.ShowTipTimes = Config.FirstShowTipTimes --倒计时弹板时间
            Config.OverTimes    = Config.FirstShowOverTimes
        end
        self:saveTriggerPusherTimes( )

        -- 存储本地数据
        local pushersData = {}
        pushersData.netInitData = selfData -- 服务器发来的初始化数据
        pushersData.pusherMaxUseNum = pusherMaxUseNum -- 赠送的金币的可使用的最大次数
        pushersData.wallMaxUseTimes = wallMaxUseTimes -- 墙道具可使用的倒计时
        pushersData.bigCoinMaxUseNum = bigCoinMaxUseNum --大金币掉落道具可使用的最大次数
        pushersData.wallMaxUseNum = wallMaxUseNum   -- 倒计时道具次数
        pushersData.shakeMaxUseNum = shakeMaxUseNum -- 震动道具可使用的最大次数
        pushersData.collectCurrNum = 0 -- 当前收集的金币的个数
        pushersData.jpCollectCurrNum = 0 -- 当前收集的jackpot金币的个数
        self.m_pGamePusherMgr:setPusherUseData(pushersData)
        self.m_pGamePusherMgr:saveRunningData()
        self.m_pGamePusherMain:saveEntityData(true)

        print("-------------- Pusher 存储完数据了")

        -- 向服务器推送存储完数据消息
        self.m_bonusEffectData = effectData
        self.m_bonusEffectData.m_outLine = nil
        performWithDelay(self,function(  )
            print("-------------- 发送数据告知服务器 推币机玩法正式开始")
            self.m_pGamePusherMgr:requestBonusPusherNetData(  )
        end,0.1)
    end,0.1)
    



end

function CodeGameScreenCoinCircusMachine:initPropUI(outLine)
    local data = self.m_pGamePusherMgr:getPusherUseData()
    if self.m_vecProps == nil then
        self.m_vecProps = {}
    end
    for i = 1, #VEC_PROP_KEYS, 1 do
        local propName = VEC_PROP_KEYS[i]
        if data[propName] and data[propName] > 0 then
            local info = {}
            info.propName = propName
            info.num = data[propName]
            self.m_vecProps[#self.m_vecProps + 1] = info
        elseif propName == "wallMaxUseNum" and data.wallMaxUseTimes > 0 then
            local info = {}
            info.propName = propName
            info.num = data[propName]
            self.m_vecProps[#self.m_vecProps + 1] = info
        end
    end
    
    self.m_iTotalPropNum = #self.m_vecProps
    local propView = self.m_pGamePusherMgr:getMainUiNode().m_propView
    propView:updateUI(self.m_vecProps, outLine)
    if outLine then
        for i = #self.m_vecProps, 1, -1 do
            table.remove(self.m_vecProps, i)
        end
    end
    
end

-- 推币机游戏断线重连
function CodeGameScreenCoinCircusMachine:initFeatureInfo(spinData,featureData)
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "OPEN" then
        -- 添加推币机断线游戏事件

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

        self.m_isRunningEffect = true
            
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.PUSHER_RECONNECTING_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.PUSHER_RECONNECTING_EFFECT

    end
end


function CodeGameScreenCoinCircusMachine:checkAddRewaedStartFSEffect( )

    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "OPEN" then
        -- 添加推币机断线游戏事件
        return false
    end

    return CodeGameScreenCoinCircusMachine.super.checkAddRewaedStartFSEffect(self )
end

function CodeGameScreenCoinCircusMachine:pusherGamebegin(_outLine )
    

    local isTriggered = self:loadTriggerPusherTimes()
    if isTriggered and isTriggered == "Triggered" then
        Config.ShowTipTimes = Config.SecondShowTipTimes
        Config.OverTimes    = Config.SecondShowOverTimes
    else
        Config.ShowTipTimes = Config.FirstShowTipTimes --倒计时弹板时间
        Config.OverTimes    = Config.FirstShowOverTimes
    end
    self:saveTriggerPusherTimes( )

    self.m_beInSpecialGameTrigger = true

    -- 从这个接口开始一定能确认本地存储好了数据
    --load实体数据
    local entityData = self.m_pGamePusherMgr:loadEntityData()
    --load游戏数据
    local runningData = self.m_pGamePusherMgr:loadRunningData(  )

    local PuserPropData = runningData.playingData or {} --字段名称不要轻易修改会影响本地数据存储逻辑

    if PuserPropData and table_length(PuserPropData) ~= 0 and PuserPropData.netInitData then
        -- 能取到数据进行正常的推币机逻辑
        if _outLine then
            release_print("--断线进来的")

        else
            release_print("--正常进来的")
        end
        release_print("-------------PuserPropData 长度~= 0")
        print("---PuserPropData 数据 --"..json.encode(PuserPropData))
        release_print("---PuserPropData 数据 --"..json.encode(PuserPropData))

        local netInitData = PuserPropData.netInitData  -- 服务器发来的初始化数据

        -- 根据本地存储数据更新
        self.m_pGamePusherMgr:setPusherUseData(PuserPropData)

         -- ** 更新宝箱金币进度挡位信息以及ui显示
         local collectTab = {}
         local collectData = {}
         local coinsWinCoins  = netInitData.coinsWinCoins or {} -- 道具需要的钱数
         for k,v in pairs(coinsWinCoins) do
             local coinsWinCoinsTab = {}
             coinsWinCoinsTab.collectNum = tonumber(k)
             coinsWinCoinsTab.coins = tonumber(v)
 
             table.insert( collectData, coinsWinCoinsTab )
         end
         table.sort( collectData, function( a,b )
             return a.collectNum < b.collectNum
         end )
         for i=1,5 do -- 只有五个ui 由小到大只要前五个数据
             table.insert(collectTab,collectData[i])
         end
         gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_CollectData,{nCollectData = collectTab}) 

                  
        -- 根据道具信息更新ui

        -- ** 更新剩余可使用免费金币UI显示
        local pusherMaxUseNum = PuserPropData.pusherMaxUseNum  -- 赠送的金币的可使用的最大次数
        self.m_pGamePusherMgr:updataLeftCoinsTimes(pusherMaxUseNum )
        
        -- ** 更新墙道具ui显示 
        local wallMaxUseTimes = PuserPropData.wallMaxUseTimes or 0  -- 墙道具可使用的倒计时
        Config.PropWallMaxCount = wallMaxUseTimes
        self.m_pGamePusherMgr:setPusherUpWalls( wallMaxUseTimes )
        self.m_pGamePusherMgr:upDataPropWallTimes(wallMaxUseTimes)
        if wallMaxUseTimes> 0 then
            local playPropData = {}
            playPropData.nAnimName = "start"
            playPropData.nIsLoop = false
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayProp_WallLoadingAni,playPropData) 
        end

        
        -- ** 更新大金币道具ui显示 
        local bigCoinMaxUseNum = PuserPropData.bigCoinMaxUseNum  --大金币掉落道具可使用的最大次数
        self.m_pGamePusherMgr:upDataPropBigCoinsTimes(bigCoinMaxUseNum )


        -- ** 更新收集的金币进度ui显示 
        local collectCurrNum = PuserPropData.collectCurrNum  -- 当前收集的金币的个数
        self.m_pGamePusherMgr:upDataEnergyProgress(collectCurrNum,true)

        for i=1,5 do
            local animData = {}
            animData.nBoxIndex  = i
            animData.nIsLoop    = true
            animData.nAnimName   = "idle2"
            animData.nisRest    = true
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayBaoXiangAnim,animData) 
        end

        local currlevel =  self.m_pGamePusherMgr:getCurrEnergyProgressBoxLevel(collectCurrNum) 
        local pusherMainUi = self.m_pGamePusherMgr:getMainUiNode()
        pusherMainUi.m_currBoxLevel = currlevel
        for i=1,currlevel do
            local animData = {}
            animData.nBoxIndex  = i
            animData.nIsLoop    = true
            animData.nAnimName   = "idle"
            animData.isPlayIdle = true
            animData.nisRest    = true
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayBaoXiangAnim,animData) 
        end

        self:initPropUI(_outLine)

        -- ** 更新收集的jp金币进度ui显示 
        local jpCollectCurrNum = PuserPropData.jpCollectCurrNum  -- 当前收集的jackpot金币的个数
        self.m_pGamePusherMgr:upDataPropJPCollectTimes(jpCollectCurrNum,true )
        if jpCollectCurrNum > 0 then
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateJPCollectDarkImg,{nVisible = false})  
        else
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateJPCollectDarkImg,{nVisible = true}) 
        
        end
        
         -- 更新道具价钱
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_updatePropPrice) 
        
        if _outLine then

            release_print("-------------_outLine 进入")


            self:resetMusicBg(nil,"CoinCircusSounds/music_ClassicCash_Pusherbg.mp3")

            self:findChild("root_1"):setVisible(false)
            self.m_jpBar:setVisible(false)
            -- ** 显示道具栏及进度条 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetProgressViewVisible,{nVisible = true,nScale = 1}) 
            local propsNum = self.m_iTotalPropNum + jpCollectCurrNum
            if  propsNum > 0 then
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetPropViewVisible,{nVisible = true}) 
                local playPropData = {}
                playPropData.nAnimName = "idle"..propsNum
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropViewAnim,playPropData)
            end 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetLeftFreeCoinsViewVisible,{nVisible = true}) 

            -- self.m_pGamePusherMgr:getMainUiNode():playPropViewWeakIdle( ) 

            local playPropData = {}
            playPropData.nAnimName = "idle"
            playPropData.nIsLoop = false
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayProgressViewAnim,playPropData) 


            local playPropData = {}
            playPropData.nAnimName = "idle"
            playPropData.nIsLoop = false
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayLeftFreeCoinsViewAnim,playPropData) 


            local playPropData = {}
            playPropData.nAnimName = "idle"
            playPropData.nIsLoop = false
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayTopCoinsViewAnim,playPropData) 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_setTopCoinsViewVisible,{nVisible = true}) 
                
            self.m_pGamePusherMgr:setPusherSpeed(  )
            
            self.m_pGamePusherMain:setCameraPosData( true )

            self.m_bottomUI:setVisible(false)

            local front = self.m_pGamePusherMgr:getFrontEffectNode( )
            if front then
                front:setVisible(true)
            end

            performWithDelay(self,function()
                -- ** 更新好所有ui显示开始推币机 
                self.m_pGamePusherMgr:pubBeginPlayPuhsher()
                self.m_pGamePusherMgr:setAllEntityNodeKinematic( false,true) -- 设置所有金币开启碰撞检测
            end,0)
                
        else

    
            release_print("-------------_outLine 正常进入")

            local pusherMaxUseNum = PuserPropData.pusherMaxUseNum  -- 赠送的金币的可使用的最大次数
            self.m_pGamePusherMgr:updataLeftCoinsTimes( 0 )

            self:showTriggerBonus(function(  )

                gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_bonusColelct.mp3")

                -- 收集免费金币
                self.m_jpBar:setVisible(false)

                local playTimes = 0
                -- 免费金币栏
                local playPropData = {}
                playPropData.nAnimName = "actionframe"
                playPropData.nIsLoop = false
                playPropData.nCallFunc = function(  )
                    
                    if playTimes >= 1 then
                        return 
                    end

                    playTimes = playTimes + 1

                    local playPropData1 = {}
                    playPropData1.nAnimName = "auto"
                    playPropData1.nIsLoop = false
                    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayLeftFreeCoinsViewAnim,playPropData1) 
        

                    self:playColelctAni(function(  )

                        local waitNode = cc.Node:create()
                        self:addChild(waitNode)

                        performWithDelay(waitNode,function(  )

                            local playPropData = {}
                            playPropData.nAnimName = "actionframe"
                            playPropData.nIsLoop = false
                            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayTopCoinsViewAnim,playPropData) 
                            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_setTopCoinsViewVisible,{nVisible = true}) 
                            
                            self:showGuoChang( )  
                            
                            self.m_bottomUI:setVisible(false)

                            local front = self.m_pGamePusherMgr:getFrontEffectNode( )
                            if front then
                                front:setVisible(true)
                            end

                            self.m_pGamePusherMgr:setPusherSpeed(  )

                            self:runCsbAction("over",false,function(  )
                                self:findChild("root_1"):setVisible(false)
                            end)
                            
                            
                            performWithDelay(waitNode,function(  )

                                self.m_pGamePusherMain:MoveCamera( 3 , 0.5 )

                                 -- 收集进度条
                                local playPropData = {}
                                playPropData.nAnimName = "start"
                                playPropData.nIsLoop = false
                                playPropData.nCallFunc = function(  )

                                end
                                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayProgressViewAnim,playPropData) 
                                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetProgressViewVisible,{nVisible = true,nScale = 1}) 
                            
                            
                                -- 道具栏
                                -- local playPropData = {}
                                -- playPropData.nAnimName = "actionframe"
                                -- playPropData.nIsLoop = false
                                -- playPropData.nCallFunc = function(  )
                                --     self.m_pGamePusherMgr:getMainUiNode():playPropViewWeakIdle( ) 
                                -- end
                                -- gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropViewAnim,playPropData) 
                                -- gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetPropViewVisible,{nVisible = true}) 

                                -- 进度条
                                local playPropData = {}
                                playPropData.nAnimName = "idle2"
                                playPropData.nIsLoop = true
                                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayProgressViewAnim,playPropData) 

                                self:resetMusicBg(nil,"CoinCircusSounds/music_ClassicCash_Pusherbg.mp3")
                                -- ** 更新好所有ui显示开始推币机 
                                self.m_pGamePusherMgr:pubBeginPlayPuhsher()
                                self.m_pGamePusherMgr:setAllEntityNodeKinematic( false,true  ) -- 设置所有金币开启碰撞检测
                                
                                local propView = self.m_pGamePusherMgr:getMainUiNode().m_propView
                                propView:showTip()


                                waitNode:removeFromParent()
                            end,15/60)
                        end,1)
                            
                            

                    end,true )

                    

                end
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayLeftFreeCoinsViewAnim,playPropData) 
                gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetLeftFreeCoinsViewVisible,{nVisible = true}) 
                

            end )
            
                

            
            
        end

    else

        gLobalViewManager:addLoadingAnima()

        -- 不能取到数据并且能进入到这个函数一定是处于推币机游戏状态，那么直接结束
        -- _progress,_jpNum ： 0，0 表示需要直接结束的状态
        self.m_pGamePusherMgr:requestBonusPusherNetData( 0,0 )

    end

end

function CodeGameScreenCoinCircusMachine:pusherGameOver( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local type = selfData.type
    local coinOdd = selfData.coinOdd
    local jackpot = selfData.jackpot
    local jackpotIndexes = selfData.jackpotIndexes -- jackpot转盘停止的位置
    local jackpotWinCoins = selfData.jackpotWinCoins -- jackpot赢得的钱
    

    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "CLOSED" then
        
        
        self.m_pGamePusherMgr:clearSendOverStates( )

        gLobalViewManager:removeLoadingAnima()
        -- 道具栏停止idle动画
        self.m_pGamePusherMgr:getMainUiNode():playPropViewStopIdle( )

        self.m_bonusOverFunc = function(  )

            -- 清理本地推币机数据
            self.m_pGamePusherMgr:clearRunningPusherData() 
            self.m_pGamePusherMgr:clearPusherEntityData( )

            --更新服务器传回的处理推币机金币的数据
            self:updateDiskEntityData(type,coinOdd,jackpot )

            -- 清除推币机牌面金币
            self.m_pGamePusherMgr:clearAllEntityCoins( )
            -- 重新创建推币机上的金币
            self.m_pGamePusherMgr:createEntityFromDisk( )

            -- 重置道具UI
            self.m_pGamePusherMgr:upDataPropJPCollectTimes( 0 ,true)
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_UpdateJPCollectDarkImg,{nVisible = true}) 
            

            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetProgressViewVisible,{nVisible = false}) 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetPropViewVisible,{nVisible = false}) 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetLeftFreeCoinsViewVisible,{nVisible = false}) 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_setTopCoinsViewVisible,{nVisible = false}) 
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_Rest_WallPos) 
            

            if self.m_BonusWinCoins and self.m_BonusWinCoins > 0 then

                self:showCoinsPusherOver(self.m_BonusWinCoins,function(  )

                    self:findChild("root_1"):setVisible(true)
                    self:showGuoChang( )    
                    self.m_pGamePusherMain:MoveCamera( 2 , 0.5 )
                    self.m_bottomUI:setVisible(true)

                    local lastWinCoin = globalData.slotRunData.lastWinCoin
                    globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_BonusWinCoins,true,true})
                    globalData.slotRunData.lastWinCoin = lastWinCoin  
    
                    self.m_pGamePusherMgr:setPusherSpeed( true )

                    self:runCsbAction("start",false,function(  )

                        local front = self.m_pGamePusherMgr:getFrontEffectNode( )
                        if front then
                            front:setVisible(false)
                        end

                        self.m_jpBar:setVisible(true)
                        self:runCsbAction("idle",true)

                        performWithDelay(self,function(  )
                            
                            -- 通知bonus 结束， 以及赢钱多少
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_BonusWinCoins, GameEffect.EFFECT_BONUS})
                            -- 更新游戏内每日任务进度条
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                            gLobalNoticManager:postNotification(ViewEventType.COINCIRCUS_NOTIC_BONUS_OVER) -- 推送推币机bonus结束

                        end,0.5)
                        
                     
                    end)

                    
    
                end )

            else

                self:findChild("root_1"):setVisible(true)
                self:runCsbAction("idle",true)
                self.m_jpBar:setVisible(true)

                self.m_bottomUI:setVisible(true)

                self:showGuoChang( )    
                self.m_pGamePusherMain:MoveCamera( 2 , 0.5 )

                self.m_pGamePusherMgr:setPusherSpeed( true )

                self:runCsbAction("start",false,function(  )

                    local front = self.m_pGamePusherMgr:getFrontEffectNode( )
                    if front then
                        front:setVisible(false)
                    end

                    gLobalNoticManager:postNotification(ViewEventType.COINCIRCUS_NOTIC_BONUS_OVER) -- 推送推币机bonus结束
                    
                end)

               
            end
           

            self.m_bonusOverFunc = nil
        end

        if jackpotIndexes then

            self.m_maxTurn = #jackpotIndexes
            self.m_currTurn = 1
            self.m_cumulativeCoins = 0
            
            local evenData = {}
            evenData.nCallFunc = function(  )
                self:beginBonusOverWheelAni( )
            end
            gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_PlayPropCollectJpCoinsTriggerAnim,evenData) -- 推送触发jackpot圆盘玩法

        else
            if self.m_bonusOverFunc then
                self.m_bonusOverFunc()
                self.m_bonusOverFunc = nil
            end
        end    
    end

    
end

function CodeGameScreenCoinCircusMachine:beginBonusOverWheelAni( )
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotIndexes = selfData.jackpotIndexes -- jackpot转盘停止的位置
    local jackpotWinCoins = selfData.jackpotWinCoins -- jackpot赢得的钱

    if self.m_currTurn > self.m_maxTurn then
        
        if self.m_bonusOverFunc then
            self.m_bonusOverFunc()
        end

        return
    end

    local endindex = jackpotIndexes[self.m_currTurn] + 1 -- [0,1,2,3]:Grand Mini Major minor
    local winCoins = jackpotWinCoins[self.m_currTurn]
    local jpindex = endindex 

    local evenData = {}
    evenData.nEndIndex = endindex
    evenData.njpindex = jpindex
    evenData.nwinCoins = winCoins
    evenData.nCallBackFun = function(  )

        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_cumulativeCoins,false,false})
        globalData.slotRunData.lastWinCoin = lastWinCoin 
        
        self:beginBonusOverWheelAni( )

    end
    
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_ShowWheelView,evenData) -- 推送显示圆盘玩法

    self.m_cumulativeCoins = self.m_cumulativeCoins + winCoins
    self.m_currTurn = self.m_currTurn + 1

end


function CodeGameScreenCoinCircusMachine:updateDiskEntityData(_type,_coinOdd,_jackpot )

    if _type then
        self.m_diskEntityDataID  = _type
    end
    
    if _coinOdd then
        self.m_diskEntityDataCoinOdd  = _coinOdd
    end

    if _jackpot then
        self.m_diskEntityDataJackpotHave  = _jackpot
    end

    self.m_pGamePusherMgr:setDiskEntityDataID(self.m_diskEntityDataID)   
    self.m_pGamePusherMgr:setDiskEntityDataCoinOdd(self.m_diskEntityDataCoinOdd)     
    self.m_pGamePusherMgr:setDiskEntityDataJackpotHave(self.m_diskEntityDataJackpotHave)  
end

---
-- 处理spin 返回结果
function CodeGameScreenCoinCircusMachine:spinResultCallFun(param)

    BaseNewReelMachine.spinResultCallFun(self,param)

    -- 处理bonus消息返回
    self:featureResultCallFun(param)
end

function CodeGameScreenCoinCircusMachine:featureResultCallFun(param)

    
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]

        if spinData.action == "FEATURE" then

            gLobalViewManager:removeLoadingAnima()
            
            local serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_BonusWinCoins = serverWinCoins
            globalData.userRate:pushCoins(serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            
            -- 更新本地数据
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            
            self:handleBonusResult( )


        elseif spinData.action == "SPECIAL" then
            
            gLobalViewManager:removeLoadingAnima()
            
            local serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_BonusWinCoins = serverWinCoins
            globalData.userRate:pushCoins(serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            
            -- 更新本地数据
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            self:handleBuyPropResult( )

        end

       
    else
        -- 处理消息请求错误情况
        -- gLobalViewManager:showReConnect()
    end
end

-- 处理购买bonus推币机道具逻辑
function CodeGameScreenCoinCircusMachine:handleBuyPropResult(select)

    self.m_pGamePusherMgr:pubStartPusherAllAnim( )

    -- 刷新道具信息
    -- select ： 0：震动 ，1墙， 2大金币 
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local freeItems = selfData.freeItems or {} -- 道具免费信息
    self.m_pGamePusherMgr:updateNetInitData(selfData)


    local PuserPropData = self.m_pGamePusherMgr:getPusherUseData() --字段名称不要轻易修改会影响本地数据存储逻辑
    local wallAddTimes = selfData.wallDuration or 15
    
    local btnName = nil


    if select == Config.PropType.BIGCOINS  then

        print("-----------大金币道具播放")

        local data = {}
        -- data.bigCoinMaxUseNum = PuserPropData.bigCoinMaxUseNum  + 1
        self.m_pGamePusherMgr:updatePlayingData( data )

        -- 存储到本地
        -- self.m_pGamePusherMgr:saveRunningData()

        self.m_pGamePusherMgr:playBigCoinsProp( function(  )
            self.m_pGamePusherMgr:upDataPropTouchEnabled(true )
        end)

    elseif select ==  Config.PropType.WALL   then
        print("-----------墙道具")

        local data = {}
        data.wallMaxUseTimes = PuserPropData.wallMaxUseTimes  + wallAddTimes
        self.m_pGamePusherMgr:updatePlayingData( data )

        -- 存储到本地
        -- self.m_pGamePusherMgr:saveRunningData()

        self.m_pGamePusherMgr:updateWallUpTimes( function(  )
            self.m_pGamePusherMgr:upDataPropTouchEnabled(true )
        end,data.wallMaxUseTimes )

    elseif select == Config.PropType.SHAKE    then
        
        print("-----------震动道具")

        local data = {}
        -- data.shakeMaxUseNum = PuserPropData.shakeMaxUseNum  + 1
        self.m_pGamePusherMgr:updatePlayingData( data )

        -- 存储到本地
        -- self.m_pGamePusherMgr:saveRunningData()

        self.m_pGamePusherMgr:playShakeProp()
    end


    -- 第二币值刷新
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    
end

-- 处理bonus触发结束数据逻辑
function CodeGameScreenCoinCircusMachine:handleBonusResult( )

    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""

    if bonusStatus == "OPEN" then
        -- 这个接口作为正常触发服务器返回时真正开始推币机玩法的入口
        self:pusherGamebegin( )
    elseif bonusStatus == "CLOSED" then
        -- 这个接口作为真正结束推币机玩法的入口
        self:pusherGameOver( )
    end

end

--[[
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   base下玩法  合图
]]

function CodeGameScreenCoinCircusMachine:getChangeBigSymbolName(changeType)
    local bigName = ""
    if changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        bigName     = "Socre_CoinCircus_6"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        bigName     = "Socre_CoinCircus_7"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        bigName     = "Socre_CoinCircus_8"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        bigName     = "Socre_CoinCircus_9"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        bigName     = "Socre_CoinCircus_Wild"
    end
    return bigName
end


--获取播放大图的中心点 起始列
function CodeGameScreenCoinCircusMachine:getBigSymbolPos(_startCol, _endCol)
    if _endCol > 5 then
        _endCol = 5
    end

    local targSp1 = self:getFixSymbol(_startCol, 1, SYMBOL_NODE_TAG)
    local posWorld1 = targSp1:getParent():convertToWorldSpace(cc.p(targSp1:getPositionX(), targSp1:getPositionY()))
    local pos1 = self.m_clipParent:convertToNodeSpace(cc.p(posWorld1.x, posWorld1.y))

    local targSp2 = self:getFixSymbol(_endCol, 4, SYMBOL_NODE_TAG)
    local posWorld2 = targSp2:getParent():convertToWorldSpace(cc.p(targSp2:getPositionX(), targSp2:getPositionY()))
    local pos2 = self.m_clipParent:convertToNodeSpace(cc.p(posWorld2.x, posWorld2.y))
    return cc.pMidpoint(pos1, pos2)
end

--判断是否有3列以上相同的信号块相邻 不包含（bonus 低级信号块1,2,3,4,5）

function CodeGameScreenCoinCircusMachine:isNeedChangeBigSymbol( )

    local winLines = self.m_runSpinResultData.p_winLines

    if #winLines <= 0 then
        return {isChange = false}
    end

    local function isSameSymbol(_firstType, _tempType)
        --低分信号块 及bonus 直接退出
        if _firstType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 and _firstType < TAG_SYMBOL_TYPE.SYMBOL_WILD then
            return false
        end

        if _tempType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 and _tempType < TAG_SYMBOL_TYPE.SYMBOL_WILD then
            return false
        end
        --两个图标不一样 但是有wild
        if _firstType ~= _tempType and (_firstType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _tempType == TAG_SYMBOL_TYPE.SYMBOL_WILD) then
            return true
        end

        if _firstType == _tempType then
            return true
        end

        return false
    end
    --存储每一列是否时相同图标
    local symbolTypeData = {}
    for iCol = 1, self.m_iReelColumnNum do
        local symbolType = nil -- 合图类型
        local bSame = true
        for iRow = 1, self.m_iReelRowNum do
            local tempType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = tempType
            end
            if not isSameSymbol(symbolType, tempType) then
                bSame = false
                symbolType = -1
                break
            end
        end
        local symbolData = {}
        symbolData.symbolType = symbolType
        symbolData.bSame = bSame
        symbolTypeData[iCol] = symbolData
    end

    local sameColData = {}
    local maxWildNum = 0
    local wildSame = nil
    local wildSameLsit = {}

    for iCol=1,#symbolTypeData do
        local data = {}
        local startCol = 0
        local sameCol = 0
        local symbolType = nil
        
        
        for i = iCol, #symbolTypeData do
            local data = symbolTypeData[i]
            if data.bSame then
                local tempType = data.symbolType
                if symbolType == nil then
                    symbolType = tempType
                end
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    symbolType = tempType
                end

                if wildSame and symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD  then
                    break
                end

                if startCol == 0 then
                    startCol = i
                end
                if not isSameSymbol(symbolType, tempType) then
        
                    break

                end
                sameCol = sameCol + 1
            else
                if i > 3 then
                    break
                end
                symbolType = nil
                sameCol = 0
                startCol = 0
            end

            if startCol == 1 then
                --前三列都是wild 直接返回 不合图 单独处理
                if sameCol >= 3 and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then

                    wildSame = true
                    symbolType = nil
                    sameCol = 0
                    startCol = 0
                    break
                end
            end

        end

        data.startCol       =   startCol
        data.sameCol        =   sameCol
        data.symbolType     =   symbolType


        table.insert( sameColData, data)
    end


    if wildSame then
        sameColData = {}
        startCol = 1
        sameCol = 0
        symbolType = nil
        for i = 1, #symbolTypeData do
            local data = symbolTypeData[i]
            if data.bSame then
                local tempType = data.symbolType
                if symbolType == nil then
                    symbolType = tempType
                end

                if tempType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    sameCol = sameCol + 1
                else
                    break
                end
                
            else
                 break

            end
    
        end
    
        local data = {}
        data.startCol       =   startCol
        data.sameCol        =   sameCol
        data.symbolType     =   symbolType

        table.insert( sameColData, data)

    else

        if symbolTypeData[1].bSame ~= true then

                for i=1,#sameColData do
                    local data = sameColData[i]
                    if data.symbolType and data.symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if data.startCol and data.startCol == 2 then
                            
                            if data.sameCol then
                                if data.sameCol == 3  then
                                    table.insert(wildSameLsit,data)
                                elseif data.sameCol == 4  then
                                    table.insert(wildSameLsit,data)
                                end
                            end       
                        end
                    else
                        if symbolTypeData[5].bSame == true then
                            if data.startCol and data.startCol == 2 then
                                if symbolTypeData[2].symbolType and symbolTypeData[2].symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                                    if symbolTypeData[3].symbolType and symbolTypeData[3].symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                                    
                                        if symbolTypeData[4].symbolType and symbolTypeData[4].symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                                            if data.sameCol   then
                                                if data.sameCol == 4  then
                                                    data.sameCol = 3
                                                    data.symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
                                                    table.insert(wildSameLsit,data)
                                                end
                                            end   
                                        end
                                    end
    
                                end
                                    
                            end
                        end
                        
                    end
                end

           
        end
        
        if #wildSameLsit == 0 then
            if symbolTypeData[2].bSame ~= true then
                for i=1,#sameColData do
                    local data = sameColData[i]
                    if data.symbolType and data.symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if data.startCol and data.startCol == 3 then
                            if data.sameCol then
                                if data.sameCol == 3  then
                                    table.insert(wildSameLsit,data)
                                end
                            end       
                        end
                    end
                end
            end
        end
        
    end
     
   
    if  #wildSameLsit > 0 then
        sameColData = wildSameLsit
    end

    table.sort( sameColData, function(a,b  )
        return a.sameCol < b.sameCol
    end )


    if wildSame or #wildSameLsit > 0 then
        
    else
        for i=#sameColData,1,-1 do

            --判断是否在赢钱线上
            if not self:isHaveWinLineByType(sameColData[i].symbolType) then
                table.remove(sameColData,i)
            end

        end
        
        if #sameColData == 0 then
            return {isChange = false}
        end
        
    end
    
    local lastData = sameColData[#sameColData]
    symbolType = lastData.symbolType
    
    --有3列及以上相同的则可以合图
    if lastData.sameCol >= 3 then
        return {isChange = true, changeType = symbolType, startCol = lastData.startCol, changeCol = lastData.sameCol}
    end
    return {isChange = false}

end


--判断是否在赢钱线上
function CodeGameScreenCoinCircusMachine:isHaveWinLineByType(_symbolType)
    local winLines = self.m_runSpinResultData.p_winLines

    local isHave = false
    for i = 1, #self.m_runSpinResultData.p_winLines do
        local line = self.m_runSpinResultData.p_winLines[i]
        if line.p_type == _symbolType then
            isHave = true
            break
        end
    end

    return isHave
end

function CodeGameScreenCoinCircusMachine:changeBigSymbolEffect(effectData )


    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_HeTu.mp3")

    local symbolType = self.m_changeBigData.changeType
    local startCol = self.m_changeBigData.startCol
    local changeCol = self.m_changeBigData.changeCol
    local endCol = startCol + changeCol - 1
    local aniNameId = endCol - startCol + 1

    local bigName = self:getChangeBigSymbolName(symbolType)
    local pos = self:getBigSymbolPos(startCol, endCol)


    if self.m_bigSymbol then
        self.m_bigSymbol:removeFromParent()
        self.m_bigSymbol = nil
    end

    self.m_bigSymbol = util_spineCreate(bigName,true,true)
    self.m_bigSymbol:setPosition(pos)
    self.m_clipParent:addChild(self.m_bigSymbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 100)
    util_spinePlay(self.m_bigSymbol,"actionframe"..aniNameId)
    util_spineEndCallFunc(self.m_bigSymbol,"actionframe"..aniNameId,function(  )
        local waitNode_1 = cc.Node:create()
        self:addChild(waitNode_1)
        performWithDelay(waitNode_1,function(  )
            
            util_spinePlay(self.m_bigSymbol,"over"..aniNameId)
            util_spineEndCallFunc(self.m_bigSymbol,"over"..aniNameId,function(  )

                performWithDelay(waitNode_1,function(  )

                    self:runCsbAction("idle",true)

                    if self.m_bigSymbol then
                        self.m_bigSymbol:removeFromParent()
                        self.m_bigSymbol = nil
                    end

                    effectData.p_isPlay = true
                    self:playGameEffect()

                    waitNode_1:removeFromParent()
                end,0)

            end)

        end,0)
    end)


    if self.m_bigSymbolAni then
        self.m_bigSymbolAni:removeFromParent()
        self.m_bigSymbolAni = nil
    end
    self.m_bigSymbolAni = util_createAnimation("CoinCircus_Socre_effect.csb") 
    self.m_bigSymbolAni:setPosition(pos)
    self.m_clipParent:addChild(self.m_bigSymbolAni, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 101)
    self.m_bigSymbolAni:runCsbAction("actionframe4_"..aniNameId,false,function(  )

        if self.m_bigSymbolAni then
            self.m_bigSymbolAni:removeFromParent()
            self.m_bigSymbolAni = nil
        end

    end)

            

    

    

end



--[[
    假滚需求    
--]]

function CodeGameScreenCoinCircusMachine:updateNetWorkData( )
    BaseNewReelMachine.updateNetWorkData(self)
    self:setNetMysteryType()
end

function CodeGameScreenCoinCircusMachine:randomMystery()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i)
        self.m_mysterList[i] = symbolInfo.symbolType
    end

    self.m_configData:setMysterSymbol(self.m_mysterList)
end

function CodeGameScreenCoinCircusMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end

--使用现在获取的数据
function CodeGameScreenCoinCircusMachine:setNetMysteryType()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_bNetSymbolType = true
            local bRunLong = false
            for i = 1, #self.m_mysterList do
                local symbolInfo = self:getColIsSameSymbol(i)
                self.m_mysterList[i] = symbolInfo.symbolType
                local reelRunData = self.m_reelRunInfo[i]
                if bRunLong then
                    self.m_mysterList[i] = -1
                end
                if self.m_mysterList[i] == -1 then
                    self:changeSlotReelDatas(i, bRunLong)
                end
                if reelRunData:getNextReelLongRun() == true then
                    bRunLong = true
                end
            end
        end,
        0.5,
        "changeReelData"
    )
end

function CodeGameScreenCoinCircusMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenCoinCircusMachine:checkUpdateReelDatas(parentData, _bRunLong)
    local reelDatas = nil

    if _bRunLong == true then
        reelDatas = self.m_configData:getRunLongDatasByColumnIndex(parentData.cloumnIndex)
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

--随机信号
function CodeGameScreenCoinCircusMachine:getReelSymbolType(parentData)
    local cloumnIndex = parentData.cloumnIndex
    if self.m_bNetSymbolType == true then
        if self.m_mysterList[cloumnIndex] ~= -1 then
            return self.m_mysterList[cloumnIndex]
        end
    end
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

function CodeGameScreenCoinCircusMachine:getColIsSameSymbol(_iCol)
    local reelsData = self.m_runSpinResultData.p_reels
    if reelsData and next(reelsData) then
        local symbolInfo = {}
        local tempType
        local symbolType = nil
        for iRow = 1, self.m_iReelRowNum do
            tempType = reelsData[iRow][_iCol]
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType ~= tempType then
                symbolInfo.symbolType = -1
                symbolInfo.bSame = false
                return symbolInfo
            end
        end
        symbolInfo.symbolType = tempType
        symbolInfo.bSame = true
        return symbolInfo
    else
        local symbolInfo = {}
        symbolInfo.symbolType = -1
        symbolInfo.bSame = false
        return symbolInfo
    end
end

function CodeGameScreenCoinCircusMachine:setNormalSymbolType()
    self.m_initNodeSymbolType = math.random(0, 8)
end

function CodeGameScreenCoinCircusMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
    local changedSymbolType = 0

    if colIndex and reelDatas then
        if self.m_initNodeCol ~= colIndex then
            self.m_initNodeCol = colIndex
            self:setNormalSymbolType()
            changedSymbolType = self.m_initNodeSymbolType
        else
            if self.m_initNodeSymbolType then
                changedSymbolType = self.m_initNodeSymbolType
            else
                changedSymbolType = symbolType
            end
        end
    else
        changedSymbolType = symbolType
    end

    return changedSymbolType
end

function CodeGameScreenCoinCircusMachine:getBonus1Num( _pos )
    local pusherNum = nil
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local coins = selfData.coins or {} -- 每个触发bonus给的可以推的个数
    for pos,num in pairs(coins) do
        if _pos == tonumber(pos) then
            pusherNum = tonumber(num) 
        end
    end
    
    if not pusherNum then
        pusherNum = math.random(4,10)
    end

    return pusherNum
end


function CodeGameScreenCoinCircusMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    local reelNode = node
    if symbolType == self.SYMBOL_BONUS_1 then
        
        local posIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)
        local lab = node:getCcbProperty("ml_coin")
        if lab then
            lab:setString(self:getBonus1Num( posIndex ))
        end

        local fsCoinsNode = node:getCcbProperty("CoinCircus_bonus_1")
        if fsCoinsNode then
            fsCoinsNode:setVisible(false)
        end

    end
end

function CodeGameScreenCoinCircusMachine:showCoinsPusherOver(coins,func,isAuto )

    self:clearCurMusicBg()

    local function newFunc()

        if func then
            func()
        end
    end

    
    local data = {}
    data.wallMaxUseNum = 0
    data.wallMaxUseTimes = 0
    self.m_pGamePusherMgr:updatePlayingData( data )
    self.m_pGamePusherMgr:saveRunningData()
    self.m_pGamePusherMgr:upDataPropWallTimes( data.wallMaxUseNum )
    self.m_syncDirtyNode:stopAllActions()

    local BonusOverView = util_createView("CoinCircusSrc.CoinCircusBonusOverView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        BonusOverView.getRotateBackScaleFlag = function(  ) return false end
    end
    BonusOverView:setPosition(display.width/2,display.height/2)
    gLobalViewManager:showUI(BonusOverView)

    BonusOverView:initViewData(coins,function()

        BonusOverView:runCsbAction("over",false,function(  )

            BonusOverView:removeFromParent()

            if newFunc ~= nil then 
                newFunc()
                newFunc = nil
            end 
        end)
        
          
    end)


end


function CodeGameScreenCoinCircusMachine:playCustomSpecialSymbolDownAct( slotNode )
    CodeGameScreenCoinCircusMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )
    if self:isSpecailSymbol(slotNode.p_symbolType) == true then

        local soundPath =  "CoinCircusSounds/CoinCircusSounds_BonusDown.mp3"
        local iCol = slotNode.p_cloumnIndex
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( iCol,soundPath )
        else
            -- respinbonus落地音效
            gLobalSoundManager:playSound(soundPath)
        end


        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_BONUS_1,0)

        slotNode:runAnim("buling")
    end

end

---
--设置bonus scatter 层级
function CodeGameScreenCoinCircusMachine:getBounsScatterDataZorder(symbolType )

    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    if self:isSpecailSymbol(symbolType) then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 2
    end

    local order = BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType )

    

    return order

end



function CodeGameScreenCoinCircusMachine:playColelctAni(_func )
    

    local maskBg = util_createAnimation("CoinCircus_Bonus_mask.csb")
    self:findChild("root_1"):addChild(maskBg, -1)
    -- maskBg:setName("maskBg")
    -- self.m_pGamePusherMgr:getMainUiNode( ):findChild("Node_mask"):addChild(maskBg)
    maskBg:runCsbAction("start")

    local waitTime = 0.5 
    local startNodeList = {}
    local endNode = self.m_pGamePusherMgr:getMainUiNode( ):findChild("pusherLevel_LeftNum")
    local endPos = util_convertToNodeSpace(endNode,self)
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == self.SYMBOL_BONUS_1 then
                    local startNode = util_createAnimation("Socre_CoinCircus_Bonus_1.csb")
                    self:addChild(startNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                    table.insert(startNodeList,startNode)
                    startNode:setPosition(util_convertToNodeSpace(slotNode,self))
                    startNode:findChild("ml_coin"):setString(slotNode:getCcbProperty("ml_coin"):getString())
                    
                    util_playMoveToAction(startNode,waitTime,endPos)
                end
                
            end
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode,function(  )
        self:jumpCollectCoins()
        if #self.m_vecProps > 0 then
            performWithDelay(waitNode,function(  )
                self:collectProps(function()
                    performWithDelay(waitNode,function(  )
                    
                        maskBg:runCsbAction("over",false,function(  )
                            maskBg:removeFromParent()
                        end)
            
                        waitNode:removeFromParent()
            
                    end,1)
                    
            
                    if _func then
                        _func()
                    end
                end)
            end,1)
        else
            performWithDelay(waitNode,function(  )
                
                maskBg:runCsbAction("over",false,function(  )
                    maskBg:removeFromParent()
                end)
    
                waitNode:removeFromParent()
    
            end,1)
            
            if _func then
                _func()
            end
        end
        

        for i=1,#startNodeList do
            local node = startNodeList[i]
            node:removeFromParent()
        end

       
    end,waitTime)

end

function CodeGameScreenCoinCircusMachine:jumpCollectCoins()
    local PuserPropData = self.m_pGamePusherMgr:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if PuserPropData and table_length(PuserPropData) ~= 0 then
        local pusherMaxUseNum = PuserPropData.pusherMaxUseNum  -- 赠送的金币的可使用的最大次数
        local playPropData = {}
        playPropData.ntimes = pusherMaxUseNum
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_JumpLeftFreeCoinsTimes,playPropData)
    end
end

function CodeGameScreenCoinCircusMachine:collectProps(_func)
    if #self.m_vecProps > 0 then
        
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_SetPropViewVisible,{nVisible = true}) 
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_collect_prop.mp3") 
        
        local propInfo = self.m_vecProps[1]
        local type = VEC_PROP_TYPES[propInfo.propName]
        local csbName = self:MachineRule_GetSelfCCBName(type)
        table.remove(self.m_vecProps, 1)
        
        local waitTime = 0.5 
        local startNodeList = {}
        local propView = self.m_pGamePusherMgr:getMainUiNode().m_propView
        local endNode = propView:getPropIconNode(propInfo.propName)
        local endPos = util_convertToNodeSpace(endNode,self)
        
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == type then
                        local startNode = util_createAnimation(csbName..".csb")
                        self:addChild(startNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                        table.insert(startNodeList,startNode)
                        startNode:setPosition(util_convertToNodeSpace(slotNode,self))
                        util_playMoveToAction(startNode,waitTime,endPos, function()
                            propView:showPropIcon(propInfo.propName)
                            startNode:removeFromParent()
                        end)
                    end
                end
            end
        end

        performWithDelay(self, function()
            self:collectProps(_func)
        end, waitTime)
    else
        _func()
    end
    
end

function CodeGameScreenCoinCircusMachine:showTriggerBonus(_func )

    gLobalSoundManager:playSound("CoinCircusSounds/CoinCircusSounds_BonusTrigger.mp3") 


    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if self:isSpecailSymbol(slotNode.p_symbolType) then
                    slotNode:runAnim("actionframe")
                end
                
            end
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode,function(  )
        if _func then
            _func()
        end
        self:runCsbAction("idle",true)
        waitNode:removeFromParent()
    end,80/60)
end



function CodeGameScreenCoinCircusMachine:showGuoChang( )

    gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_ShowGuoChang.mp3") 

    self.m_guoChang:setVisible(true)
    self.m_guoChang:runCsbAction("actionframe",false,function(  )
        self.m_guoChang:setVisible(false)
    end)
    
end

function CodeGameScreenCoinCircusMachine:isSpecailSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1
     or symbolType == self.SYMBOL_BONUS_2
     or symbolType == self.SYMBOL_BONUS_3
     or symbolType == self.SYMBOL_BONUS_4 then
        return true
    end
    return false
end

return CodeGameScreenCoinCircusMachine






