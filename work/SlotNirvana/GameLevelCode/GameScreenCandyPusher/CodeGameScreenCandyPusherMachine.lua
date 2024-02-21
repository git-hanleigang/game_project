---
-- island
-- 2018年6月4日
-- CodeGameScreenCandyPusherMachine.lua
-- 
-- 玩法：
-- 


local BaseNewReelMachine               = require "Levels.BaseNewReelMachine"
local GameEffectData                   = require "data.slotsdata.GameEffectData"
local BaseDialog                       = util_require("Levels.BaseDialog")
local GamePusherManager                = require "CandyPusherSrc.GamePusherManager"
local Config                           = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")
local CodeGameScreenCandyPusherMachine = class("CodeGameScreenCandyPusherMachine", BaseNewReelMachine)

CodeGameScreenCandyPusherMachine.SYMBOL_BONUS_1                  = 94
CodeGameScreenCandyPusherMachine.MAIN_ADD_POSY                   = 25
CodeGameScreenCandyPusherMachine.m_pGamePusherMgr                = nil       -- game推币机管理类
CodeGameScreenCandyPusherMachine.m_diskEntityDataID              = 1         -- 服务器传回的初始化轮盘类型
CodeGameScreenCandyPusherMachine.m_nBonusID                      = nil       -- 本地数据存储Key
CodeGameScreenCandyPusherMachine.m_bonusEffectData               = nil       -- 存储正常触发或断线重连的推币机bonus游戏事件数据
CodeGameScreenCandyPusherMachine.PUSHER_RECONNECTING_EFFECT      = GameEffect.EFFECT_SELF_EFFECT - 99 -- 推币机断线重连，最先触发

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
function CodeGameScreenCandyPusherMachine:ctor()
    CodeGameScreenCandyPusherMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_isOpenRewaedFreeSpin = true
    self.m_spinRestMusicBG = true
    self.m_longRunBonusColList = {}

    self.m_mysterList = {}
    for i = 1, 5 do
        self.m_mysterList[i] = -1
    end
    
    self.m_initNodeCol = 0
    self.m_initNodeSymbolType = 0
    self.m_BonusWinCoins = 0

    --是否同步脏数据
    self.m_isSyncDirty = false

	--init
	self:initGame()
end

function CodeGameScreenCandyPusherMachine:initGame()
 
    self.m_reelRunSound = "CandyPusherSounds/music_CandyPusher_quick_run.mp3"--快滚音效

    self.m_configData = gLobalResManager:getCSVLevelConfigData("CandyPusherConfig.csv", "LevelCandyPusherConfig.lua")

	--初始化基本数据
    self:initMachine(self.m_moduleName)
    local DeluexeName = ""
    if globalData.slotRunData.isDeluexeClub == true then
        DeluexeName = "Deluexe"
    end
    self.m_nBonusID         = self:getNetWorkModuleName().. DeluexeName .. globalData.userRunData.userUdid
    self.m_pGamePusherMgr   = GamePusherManager:getInstance()

end  

function CodeGameScreenCandyPusherMachine:initUI()

    self.m_baseFreeSpinBar = util_createView("CandyPusherSrc.CandyPusherFreespinBar")
    self:findChild("Node_FreeSpinBar"):addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    self:runCsbAction("idle",true)

    self.m_syncDirtyNode = cc.Node:create()
    self:addChild(self.m_syncDirtyNode)

    self.m_jpBar = util_createView("CandyPusherSrc.CandyPusherJackPotBarView")
    self:findChild("jakcpot_kuang"):addChild(self.m_jpBar)
    self.m_jpBar:initMachine(self)
    self.m_jpBar:runCsbAction("idle1",true)
    local buyTxNode = self.m_topUI:findChild("buy_tx")
    if buyTxNode then
        local pos = util_convertToNodeSpace(buyTxNode,self:findChild("jakcpot_kuang"))
        self.m_jpBar:setPosition(cc.p(pos.x,pos.y - 52 - 119 * (2- self.m_machineRootScale))) 
    end
    
    self.m_guoChang = util_createAnimation("CandyPusher_guochang.csb") 
    self:addChild(self.m_guoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChang:setPosition(display.width/2,display.height/2)
    self.m_guoChang:setVisible(false)

    self.m_logo = util_createAnimation("CandyPusher_logo.csb") 
    self:findChild("logo"):addChild(self.m_logo)
    self.m_logo:runCsbAction("idle",true)
    
    self.m_collectBar = util_createView("CandyPusherSrc.CandyPusherCollectBar",self)
    self:findChild("Node_shouji"):addChild(self.m_collectBar)
    self.m_collectBar:runCsbAction("idle",true)
    self.m_collectBar.m_super:runCsbAction("idle",true)
    
    --预告中奖光效
    self.m_noticeWin = util_createAnimation("CandyPusher_yugao.csb")
    self:findChild("yugao"):addChild(self.m_noticeWin)
    self.m_noticeWin:setVisible(false)
    self.m_noticeWin.m_spine = util_spineCreateDifferentPath("CandyPusher_jackpot_yugao","CandyPusher_jackpot_tanban",true,true)
    self.m_noticeWin:findChild("Node_Beer"):addChild(self.m_noticeWin.m_spine)


    self.m_wildAdd = util_createAnimation("CandyPusher_wildadd.csb")
    self:findChild("yugao"):addChild(self.m_wildAdd)
    self.m_wildAdd:setVisible(false)

    self.m_maskBg = util_createAnimation("CandyPusher_Bonus_mask.csb")
    self:findChild("root_1"):addChild(self.m_maskBg, -1)
    self.m_maskBg:setVisible(false)


    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_2 ,cc.c3b(0, 0, 0),130)
    self.m_layer_colors = colorLayers
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(false)
    end

    self.m_enterTip = util_createAnimation("CandyPusher/EnterLeveTips.csb")
    self:addChild(self.m_enterTip,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_enterTip:setPosition(display.center)
    self.m_enterTip:setVisible(false)


    self.m_reelMask = util_createSprite("CandyPusher_C3b/MachineJackpot_dipian.png")
    self:findChild("root_1"):addChild(self.m_reelMask,-10)
    self.m_reelMask:setScaleX(300)
    self.m_reelMask:setScaleY(200)
    self.m_reelMask:setPosition(0,-635)
    
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenCandyPusherMachine:showLayerBlack(isShow)
    
    for key,layer in pairs(self.m_layer_colors) do
        if isShow then
            layer:setVisible(isShow)
            util_playFadeInAction(layer,0.5)
        else
            util_playFadeOutAction(layer,0.5,function()
                layer:setVisible(isShow)
            end)
        end
    end
end

function CodeGameScreenCandyPusherMachine:updateNetWorkData()

    local callFunc = function(  )
        CodeGameScreenCandyPusherMachine.super.updateNetWorkData(self)
        self:setNetMysteryType()
    end

    local isSmashAni = false
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
    if freeSpinsTotalCount > 0 and freeSpinsLeftCount > 0 then
        if (freeSpinsTotalCount - 1) == freeSpinsLeftCount then
            isSmashAni = true
        end
    end


    if isSmashAni then
        callFunc()
    else
        self:showYuGao(callFunc)
    end
    

end

function CodeGameScreenCandyPusherMachine:requestSpinResult()

    local isSmashAni = false
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
    if freeSpinsTotalCount > 0 and freeSpinsLeftCount > 0 then
        if freeSpinsTotalCount == freeSpinsLeftCount then
            isSmashAni = true
        end
    end
    if isSmashAni then
        self:showWildAdd(function(  )
            CodeGameScreenCandyPusherMachine.super.requestSpinResult(self)
        end)
    else
        CodeGameScreenCandyPusherMachine.super.requestSpinResult(self)
    end
    

end



function CodeGameScreenCandyPusherMachine:showYuGao( _func )
    local isShow = false
    local features = self.m_runSpinResultData.p_features
    local rodIndex = math.random(1,100)
    if features and #features > 1 and rodIndex <= 30 then
        isShow = true
    end
    if isShow then
        
        
        gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_yuGao.mp3")

        self.m_logo:findChild("Particle_1"):resetSystem()
        self.m_logo:findChild("Particle_2"):resetSystem()
        self.m_logo:runCsbAction("actionframe",false,function(  )
            self.m_logo:runCsbAction("idle",true)
        end)

        -- 不计算快滚开关
        for col = 1, #self.m_reelRunInfo do
            self.m_reelRunInfo[col].m_bInclScatter = false
        end

        
        util_spinePlay(self.m_noticeWin.m_spine,"yugao")
        self.m_noticeWin:setVisible(true)
        self.m_noticeWin:runCsbAction("actionframe",false,function(  )
            if _func then
                _func()
            end
            self.m_noticeWin:setVisible(false)
        end)
    else
        if _func then
            _func()
        end
    end
    
end

function CodeGameScreenCandyPusherMachine:showWildAdd(_func )
    
    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_wildAdd.mp3")

    self.m_configData:changeSpecialSymbolList(1)
    self:showLayerBlack(true)
    self.m_wildAdd:setVisible(true)
    self.m_wildAdd:runCsbAction("actionframe",false,function(  )
        self.m_wildAdd:setVisible(false)
    end)
    performWithDelay(self,function(  )
        self:showLayerBlack(false)
        performWithDelay(self,function(  )
            self.m_configData:changeSpecialSymbolList(0)
            if _func then
                _func()
            end
        end,0.5)
    end,120/60)

    
end

function CodeGameScreenCandyPusherMachine:getReelHeight()
    if display.height >= DESIGN_SIZE.height then
        return self.m_reelHeight
    else
        return 970
    end
end

function CodeGameScreenCandyPusherMachine:getReelWidth()
    return self.m_reelWidth
end

function CodeGameScreenCandyPusherMachine:scaleMainLayer()
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
        if display.height >= DESIGN_SIZE.height then
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

    end

    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCandyPusherMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "CandyPusher"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenCandyPusherMachine:getNetWorkModuleName()
    return "CandyPusher"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCandyPusherMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_CandyPusher_Bonus_1"
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
function CodeGameScreenCandyPusherMachine:MachineRule_afterNetWorkLineLogicCalculate()


end


function CodeGameScreenCandyPusherMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCandyPusherMachine.super.slotOneReelDown(self,reelCol)   

end



-- 断线重连 
function CodeGameScreenCandyPusherMachine:MachineRule_initGame()

   
end

---
-- 数据生成之后
-- 改变轮盘ui块生成列表 (可以作用于贴长条等 特殊显示逻辑中)
function CodeGameScreenCandyPusherMachine:MachineRule_InterveneReelList()

end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCandyPusherMachine:MachineRule_ResetReelRunData()
  
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCandyPusherMachine:MachineRule_SpinBtnCall()

    self:removeSoundHandler() -- 移除监听

    self.m_collectBar:quickTip( )
    
    self:setMaxMusicBGVolume()
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil 
    end
    self:removeChangeReelDataHandler()
    self:randomMystery()

    return false
end

function CodeGameScreenCandyPusherMachine:slotReelDown()

    -- 计算快滚开关
    for col = 1, #self.m_reelRunInfo do
        self.m_reelRunInfo[col].m_bInclScatter = true
    end
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    
    CodeGameScreenCandyPusherMachine.super.slotReelDown(self) 

end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenCandyPusherMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

function CodeGameScreenCandyPusherMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenCandyPusherMachine.super.playEffectNotifyNextSpinCall(self)
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenCandyPusherMachine:MachineRule_stopReelChangeData()

end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCandyPusherMachine:addSelfEffect()
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCandyPusherMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.PUSHER_RECONNECTING_EFFECT then
        self.m_bonusEffectData = effectData
        self.m_bonusEffectData.m_outLine = true
    end

    return true
end


function CodeGameScreenCandyPusherMachine:enterGamePlayMusic(  )
    if not self:checkHasGameEffectType(GameEffect.EFFECT_REWARD_FS_START) then
        self:playEnterGameSound("CandyPusherSounds/music_CandyPusher_enter.mp3")
    end
end



function CodeGameScreenCandyPusherMachine:onEnter()

    CodeGameScreenCandyPusherMachine.super.onEnter(self) 	-- 必须调用不予许删除
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

    self:changeReelImg(self:getCurrSpinMode() == FREE_SPIN_MODE )
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusProgress = selfData.bonusProgress or 0
    local features = self.m_runSpinResultData.p_features
    if features and #features > 1  then
        if features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            bonusProgress = bonusProgress - 1
        end
    end
    self.m_collectBar:updatePoints(bonusProgress )


    if not features or  #features < 2 then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            if not self.m_bonusEffectData then
                self.m_enterTip:setVisible(true)
                self.m_enterTip:runCsbAction("auto",false,function(  )
                    self.m_enterTip:setVisible(false)
                end)
            end
        end
    end
    

end


---
-- 进入关卡
--
function CodeGameScreenCandyPusherMachine:enterLevel()

    CodeGameScreenCandyPusherMachine.super.enterLevel(self)
end

function CodeGameScreenCandyPusherMachine:createGamePusher()

    -- 创建推币机时，如果当前的bonus状态不是 OPEN 就把推币机数据清掉
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""

    if bonusStatus ~= "OPEN" then
        self.m_pGamePusherMgr:clearRunningPusherData(  )
        self.m_pGamePusherMgr:clearSendOverStates( )
        self.m_pGamePusherMgr:clearPusherEntityData( )
    end
    
    --load游戏数据
    -- local runningData = self.m_pGamePusherMgr:loadRunningData(  )
    -- local pushersData = runningData.playingData or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    -- if pushersData and table_length(pushersData) ~= 0 then
    --     print("本地有数据")
    -- else
    --     self.m_pGamePusherMgr:clearRunningPusherData(  )
    -- end

    self.m_pGamePusherMgr:setSlotMainRootScale( self.m_machineRootScale)

    self.m_pGamePusherMain = self.m_pGamePusherMgr:pubCreatePusher()
    self:addChild(self.m_pGamePusherMain,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1) 



end

function CodeGameScreenCandyPusherMachine:addObservers()
    CodeGameScreenCandyPusherMachine.super.addObservers(self)
    
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

            local soundName = "CandyPusherSounds/sound_CandyPusher_last_win" .. soundIndex .. ".mp3"
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                soundName = "CandyPusherSounds/sound_CandyPusher_Fs_last_win" .. soundIndex .. ".mp3"
            end
            
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName, false)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

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
function CodeGameScreenCandyPusherMachine:startSyncDirtyData()
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


function CodeGameScreenCandyPusherMachine:onExit()
    if self.m_pGamePusherMgr then
        self.m_pGamePusherMgr:saveRunningData()
    end

    if self.m_pGamePusherMain then
        self.m_pGamePusherMain:saveEntityData(true)
    end
    CodeGameScreenCandyPusherMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()
    self:removeChangeReelDataHandler()
    scheduler.unschedulesByTargetName(self:getModuleName())
end


function CodeGameScreenCandyPusherMachine:removeObservers()
	CodeGameScreenCandyPusherMachine.super.removeObservers(self)

	-- 自定义的事件监听，也在这里移除掉
end


--[[
   *****************
   bonus推币机玩法
]]

-- 初始化上次游戏状态数据
--
function CodeGameScreenCandyPusherMachine:initGameStatusData(gameData)

    -- 触发推币机断线spin数据处理
    local spin = gameData.spin
    local feature = gameData.feature
    if spin ~= nil then
        if feature ~= nil then
            local bonus = feature.bonus
            if bonus then
                if bonus.status then
                    gameData.spin.features = clone(gameData.feature.features)
                    gameData.spin.selfData = clone(gameData.feature.selfData)
                    gameData.spin.bonus    = clone(gameData.feature.bonus)
                end
            end
        end
    end

    CodeGameScreenCandyPusherMachine.super.initGameStatusData(self,gameData)

     -- 推币机数据更新
     self:initPusherSaveData(gameData )

end

function CodeGameScreenCandyPusherMachine:initPusherSaveData(gameData )
    local sequenceId = 0
    if gameData then
        if gameData.sequenceId then
            sequenceId = gameData.sequenceId
        end
        if gameData.gameConfig  then
            if gameData.gameConfig.init then
                if gameData.gameConfig.init.type then
                    self.m_diskEntityDataID  = gameData.gameConfig.init.type
                end
            end
        end 
    end
   
    self.m_pGamePusherMgr:setBonusID(self.m_nBonusID)     
    self.m_pGamePusherMgr:setDiskEntityDataID(self.m_diskEntityDataID)    
    self.m_pGamePusherMgr:initSaveKey( )

    if sequenceId == 0 then
        self:clearTriggerPusherTimes( )
        -- 第一次进或者清除服务器数据时清除本地推币机金币数据
        self.m_pGamePusherMgr:clearPusherEntityData( ) 
        self.m_pGamePusherMgr:clearRunningPusherData()
    end

end


function CodeGameScreenCandyPusherMachine:saveTriggerPusherTimes()
    local str = "Triggered"

    gLobalDataManager:setStringByField(self.m_nBonusID .. "pusherTriggered", str, true)
end

function CodeGameScreenCandyPusherMachine:clearTriggerPusherTimes()
    gLobalDataManager:delValueByField(self.m_nBonusID .. "pusherTriggered")
end

function CodeGameScreenCandyPusherMachine:getTriggerPusherTimes()
    local str = gLobalDataManager:getStringByField(self.m_nBonusID .. "pusherTriggered", "")
    return str
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenCandyPusherMachine:showBonusGameView(effectData)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    performWithDelay(self,function(  )
        -- 触发时清理本地推币机数据
        self.m_pGamePusherMgr:clearRunningPusherData()  
        -- 触发时存储数据
        local isTriggered = self:getTriggerPusherTimes()
        if isTriggered and isTriggered == "Triggered" then
            Config.ShowTipTimes = Config.SecondShowTipTimes
            Config.OverTimes    = Config.SecondShowOverTimes
        else
            Config.ShowTipTimes = Config.FirstShowTipTimes --倒计时弹板时间
            Config.OverTimes    = Config.FirstShowOverTimes
        end
        self:saveTriggerPusherTimes( )

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local coins = selfData.coins or {} -- 每个触发bonus给的可以推的个数
        local superBonusOccur = selfData.superBonusOccur 
        local pusherMaxUseNum = 0 -- 推币机最多可推的个数
        for pos,num in pairs(coins) do
            pusherMaxUseNum = pusherMaxUseNum + tonumber(num)
        end

        -- 存储本地数据
        local pushersData = {}
        pushersData.netInitData         = selfData -- 服务器发来的初始化数据
        pushersData.netInitData.bet     = 1
        pushersData.netInitData.coinCoe = 1
        pushersData.netInitData.coinPileMaxUseNum   = 0  -- 小金币堆赠送的最大使用个数
        pushersData.pusherMaxUseNum     = pusherMaxUseNum -- 赠送的金币的可使用的最大次数
        if superBonusOccur then
            pushersData.pusherMaxUseNum = pusherMaxUseNum * 2
        end
        pushersData.wallMaxUseNum       = 0   -- 倒计时道具次数
        pushersData.wallMaxUseTimes     = 0 -- 墙道具可使用的倒计时
        pushersData.collectCurrNum      = 0 -- 当前收集的金币的个数
        pushersData.dropCoinNum         = 0 -- 掉落无效区域金币总数 
        pushersData.isShoInitSlotReel   = 0 -- 是否显示初始3个grand的老虎机棋盘 0 显示 1 不显示
        
        self.m_pGamePusherMgr:setPusherUseData(pushersData)
        self.m_pGamePusherMgr:saveRunningData()
        self.m_pGamePusherMain:saveEntityData()

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



-- 推币机游戏断线重连
function CodeGameScreenCandyPusherMachine:initFeatureInfo(spinData,featureData)
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or "OPEN"
    if bonusStatus == "OPEN" then
        -- 添加推币机断线游戏事件
        self.m_isRunningEffect = true
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.PUSHER_RECONNECTING_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.PUSHER_RECONNECTING_EFFECT
    end
end


function CodeGameScreenCandyPusherMachine:checkAddRewaedStartFSEffect( )

    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "OPEN" then
        -- 添加推币机断线游戏事件
        return false
    end

    return CodeGameScreenCandyPusherMachine.super.checkAddRewaedStartFSEffect(self )
end

-- 推币机运行数据更新
function CodeGameScreenCandyPusherMachine:updatePusherData(_pushersData )
    -- 根据本地存储数据更新
    self.m_pGamePusherMgr:setPusherUseData(_pushersData)    
    -- 更新netInitData
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_pGamePusherMgr:updateNetInitData(selfData )

end

 -- 根据道具信息更新ui
function CodeGameScreenCandyPusherMachine:updatePusherUI(_pushersData )
    
    

    -- ** 更新剩余可使用免费金币UI显示
    local pusherMaxUseNum = _pushersData.pusherMaxUseNum  -- 赠送的金币的可使用的最大次数
    self.m_pGamePusherMgr:updataLeftCoinsTimes(pusherMaxUseNum )
    
    -- ** 更新墙道具ui显示 
    local wallMaxUseTimes = _pushersData.wallMaxUseTimes or 0  -- 墙道具可使用的倒计时
    self.m_pGamePusherMgr:setPusherUpWalls( wallMaxUseTimes )
    self.m_pGamePusherMgr:setMaxWallTime(wallMaxUseTimes )

    local params = {}
    params.coinNum = _pushersData.collectCurrNum
    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_updateTotaleCoins,params) 


    local netInitData = _pushersData.netInitData or {}
    local jpTriggerd = netInitData.jpTriggerd  
    local jpPlayed = netInitData.jpPlayed  
    if jpTriggerd and  jpPlayed and jpTriggerd == 1  and jpPlayed == 1 then 
        -- 如果本轮中了jackpot并且播放完jackpot流程，更新jackpot_logo
        local jackpotSignal = tonumber(netInitData.jackpotSignal)  
        self.m_pGamePusherMgr:getMainUiNode().m_jpLogoCsb:setVisible(true)
        self.m_pGamePusherMgr:getMainUiNode().m_jpLogoCsb:runCsbAction("idleframe",true)
        self.m_pGamePusherMgr:getMainUiNode():initJpLogoImg(self.m_pGamePusherMgr:getJpTypeIndex( jackpotSignal ) )
    end

end

function CodeGameScreenCandyPusherMachine:showPusherOutLineAnim( )

    

    local isShoInitSlotReel = 1 
    local pushersData = self.m_pGamePusherMgr:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if pushersData and table_length(pushersData) ~= 0 and pushersData.netInitData then
        isShoInitSlotReel = pushersData.isShoInitSlotReel  -- 是否显示初始3个grand的老虎机棋盘 0 显示 1 不显示
    end

    if isShoInitSlotReel == 0 then
        local reel = {}
        reel[#reel + 1] = Config.slotsSymbolType.Grand
        reel[#reel + 1] = Config.slotsSymbolType.Grand
        reel[#reel + 1] = Config.slotsSymbolType.Grand
        self.m_pGamePusherMgr.m_pusherMain:resetUnitTexture(reel)
    end
    

    release_print("-------------  outLine 进入")
    self:resetMusicBg(nil,"CandyPusherSounds/music_ClassicCash_Pusherbg.mp3")
    
    self.m_jpBar:runCsbAction("idle2",true)
    self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "idle")

    self.m_pGamePusherMgr:setPusherSpeed( Config.PusherSpeed )
    self.m_pGamePusherMain:setCameraPosData( true )

    self:findChild("root_1"):setVisible(false)
    self.m_bottomUI:setVisible(false)

    local front = self.m_pGamePusherMgr:getFrontEffectNode( )
    if front then
        front:setVisible(true)
    end

    performWithDelay(self,function()
        -- ** 更新好所有ui显示开始推币机 
        self.m_pGamePusherMgr:pubBeginPlayPuhsher()
        self.m_pGamePusherMgr:setAllEntityNodeKinematic( false,true ) -- 设置所有金币开启碰撞检测

        -- 断线重连--
        self.m_pGamePusherMgr:initPlayListData() 
        self.m_pGamePusherMgr:reconnectionPlay() 
    end,0)
end

function CodeGameScreenCandyPusherMachine:showPusherNoramlTrigger( )

    local pusherMaxUseNum = 0 
    local superBonusOccur = false
    local pushersData = self.m_pGamePusherMgr:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if pushersData and table_length(pushersData) ~= 0 and pushersData.netInitData then
        superBonusOccur = pushersData.netInitData.superBonusOccur 
        pusherMaxUseNum = pushersData.pusherMaxUseNum  -- 赠送的金币的可使用的最大次数
    end

    self.m_pGamePusherMgr:updataLeftCoinsTimes( 0 )

    local reel = {}
    reel[#reel + 1] = Config.slotsSymbolType.Grand
    reel[#reel + 1] = Config.slotsSymbolType.Grand
    reel[#reel + 1] = Config.slotsSymbolType.Grand
    self.m_pGamePusherMgr.m_pusherMain:resetUnitTexture(reel)

    self:showTriggerBonus(function(  )

        gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_addBarCoins.mp3") 

        self.m_collectBar:showTriggerAnimation( function(  )
            if not superBonusOccur then
                self.m_maskBg:setVisible(true)
                self.m_maskBg:runCsbAction("start")
            end
            
            self.m_jpBar.m_AverageBet = self.m_pGamePusherMgr:getPusherAvergeBet( )

            self.m_jpBar:runCsbAction("switch1",false,function(  )
                self.m_jpBar:runCsbAction("idle2",true) 
            end)
            
            
            gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_showLeftCoinsView.mp3")
            self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "actionframe",false,function(  )
                

                local time = 0
                if superBonusOccur then
                    self.m_collectBar:showFullAnimation(  )
                    time = 100/60
                end

                performWithDelay(self,function(  )
                    
                    if superBonusOccur then
                        self.m_maskBg:setVisible(true)
                        self.m_maskBg:runCsbAction("start")
                        self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoStart")
                    else
                        self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoStart")
                    end

                    self:playColelctAni(function(  )
    
                        local pusherCoomfunc = function(  )

                            self.m_maskBg:runCsbAction("over",false,function(  )
                                self.m_maskBg:setVisible(false)

                                self.m_pGamePusherMgr.m_pusherMain._freeSpinText:setVisible(true)
                                
                                self:showGuoChang( )  
                                self.m_bottomUI:setVisible(false)
            
                                local front = self.m_pGamePusherMgr:getFrontEffectNode( )
                                if front then
                                    front:setVisible(true)
                                end
            
                                self.m_pGamePusherMgr:setPusherSpeed( Config.PusherSpeed  )
            
                                self:runCsbAction("over",false,function(  )
                                    self:findChild("root_1"):setVisible(false)
                                end)
                                
                                performWithDelay(self,function(  )
            
                                    self.m_pGamePusherMain:MoveCamera( 3 , 0.5 )
                                    self:resetMusicBg(nil,"CandyPusherSounds/music_ClassicCash_Pusherbg.mp3")
                                    -- ** 更新好所有ui显示开始推币机 
                                    self.m_pGamePusherMgr:pubBeginPlayPuhsher()
                                    self.m_pGamePusherMgr:setAllEntityNodeKinematic( false,true  ) -- 设置所有金币开启碰撞检测
            
                                end,15/60)

                            end)

                        end

                        if superBonusOccur then
                            self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "jumpOver")
                            self:playSuperBonusRadialAni(function(  )
                                
                                self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "actionframe2",false,function(  )
                                    self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoOver")
                                    pusherCoomfunc()
                                end)
                                self.m_pGamePusherMgr:getMainUiNode():upDataTimesLb(pusherMaxUseNum)

                            end )
                        else
                            self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoOver")
                            pusherCoomfunc() 
                        end
    
                    end,true )

                end, time)

            end)

        end)  
    end )
end

function CodeGameScreenCandyPusherMachine:pusherGamebegin(_outLine )
    

    local isTriggered = self:getTriggerPusherTimes()
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
    local pushersData = runningData.playingData or {} --字段名称不要轻易修改会影响本地数据存储逻辑

    if pushersData and table_length(pushersData) ~= 0 and pushersData.netInitData then

        

        self:updatePusherData( pushersData )
        self:updatePusherUI( pushersData )

        
        if _outLine then
            self.m_jpBar.m_AverageBet = self.m_pGamePusherMgr:getPusherAvergeBet( )
            self.m_pGamePusherMgr.m_pusherMain._freeSpinText:setVisible(true)
            self:showPusherOutLineAnim()
        else
            release_print("------------- 正常进入")
            self:showPusherNoramlTrigger()
        end

    else

        gLobalViewManager:addLoadingAnima()
        -- 不能取到数据并且能进入到这个函数一定是处于推币机游戏状态，那么直接结束
        -- _progress,_jpNum ： 0，0 表示需要直接结束的状态
        self.m_pGamePusherMgr:requestBonusPusherNetData( 0,0,true )

    end

end

function CodeGameScreenCandyPusherMachine:pusherGameOver( )

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pusherType = selfData.type
    local jackpotType = selfData.jackpotType -- jackpottype
    local jackpotWinCoins = selfData.jackpotWinCoins -- jackpot赢得的钱
    
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "CLOSED" then
        
        self.m_pGamePusherMgr:clearSendOverStates( )
        gLobalViewManager:removeLoadingAnima()

        --更新服务器传回的处理推币机金币的数据
        self:updateDiskEntityData( pusherType )

        if self.m_BonusWinCoins and self.m_BonusWinCoins > 0 then

            local bonusOverFunc = function(  )

                local bonusTotalProgress = selfData.bonusTotalProgress or 0
                local bonusProgress = selfData.bonusProgress or 0

                self:showCoinsPusherOver(self.m_BonusWinCoins,function(  )
                    -- 清理本地推币机数据
                    self.m_pGamePusherMgr:clearRunningPusherData() 
                    self.m_pGamePusherMgr:clearPusherEntityData( )

                    -- 清除推币机牌面金币
                    self.m_pGamePusherMgr:clearAllEntityCoins( )
                    self.m_pGamePusherMgr:getMainUiNode().m_leftCoinsCsb:setVisible(false)
                    gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_Rest_WallPos) 

                    -- 下一帧再创建，防止一瞬间运算量过大
                    performWithDelay(self,function(  )
                        -- 重新创建推币机上的金币
                        self.m_pGamePusherMgr:createEntityFromDisk( )

                        local params = {}
                        params.coinNum =  0
                        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_updateTotaleCoins,params) 
                        
                        self.m_collectBar:updatePoints(bonusProgress )
                        
                        if bonusProgress == (bonusTotalProgress - 1) then 
                            -- 倒数第二次金币需要有下落流程
                            self.m_pGamePusherMgr.m_pusherMain:playSuperBonusCoinsDown(function(  )
                                self:pusherToSlotsAnimate( )
                            end)
                        else
                            self:pusherToSlotsAnimate( )
                        end
                    end,0)
                    
    
                end )

            end
            
            local jackpotType = selfData.jackpotType -- jackpottype
            local jackpotWinCoins = selfData.jackpotWinCoins -- jackpot赢得的钱

            if jackpotType then
                self.m_pGamePusherMgr:getMainUiNode( ):showJackpotView(tonumber(jackpotType),jackpotWinCoins,function(  )
                    bonusOverFunc()
                end,self)
            else
                bonusOverFunc()
            end 
            

        else

            self:findChild("root_1"):setVisible(true)
            self:runCsbAction("idle",true)

            self.m_bottomUI:setVisible(true) 

            self.m_pGamePusherMain:setCameraPosData( false )
            self.m_pGamePusherMgr:setPusherSpeed( Config.BaseReelSpeed  )
            
            local front = self.m_pGamePusherMgr:getFrontEffectNode( )
            if front then
                front:setVisible(false)
            end
            gLobalNoticManager:postNotification(ViewEventType.COINCIRCUS_NOTIC_BONUS_OVER) -- 推送推币机bonus结束

        end
           
    end

end

function CodeGameScreenCandyPusherMachine:updateDiskEntityData(_type )

    if _type then
        self.m_diskEntityDataID  = _type
    end
    

    self.m_pGamePusherMgr:setDiskEntityDataID(self.m_diskEntityDataID)   

end

---
-- 处理spin 返回结果
function CodeGameScreenCandyPusherMachine:spinResultCallFun(param)

    CodeGameScreenCandyPusherMachine.super.spinResultCallFun(self,param)

    -- 处理bonus消息返回
    self:featureResultCallFun(param)
end

function CodeGameScreenCandyPusherMachine:featureResultCallFun(param)

    
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

        end

       
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end



-- 处理bonus触发结束数据逻辑
function CodeGameScreenCandyPusherMachine:handleBonusResult( )

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
    --假滚需求    
--]]

function CodeGameScreenCandyPusherMachine:randomMystery()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i)
        self.m_mysterList[i] = symbolInfo.symbolType
    end

    self.m_configData:setMysterSymbol(self.m_mysterList)
end

function CodeGameScreenCandyPusherMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end

--使用现在获取的数据
function CodeGameScreenCandyPusherMachine:setNetMysteryType()
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

function CodeGameScreenCandyPusherMachine:changeSlotReelDatas(_col, _bRunLong)
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
function CodeGameScreenCandyPusherMachine:checkUpdateReelDatas(parentData, _bRunLong)
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
function CodeGameScreenCandyPusherMachine:getReelSymbolType(parentData)
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

function CodeGameScreenCandyPusherMachine:getColIsSameSymbol(_iCol)
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

function CodeGameScreenCandyPusherMachine:setNormalSymbolType()
    self.m_initNodeSymbolType = math.random(0, 8)
end

function CodeGameScreenCandyPusherMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
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

function CodeGameScreenCandyPusherMachine:getBonus1Num( _pos )
    local pusherNum = nil
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local coins = selfData.coins or {} -- 每个触发bonus给的可以推的个数
    for pos,num in pairs(coins) do
        if _pos == tonumber(pos) then
            pusherNum = tonumber(num) 
        end
    end
    
    if not pusherNum then
        pusherNum = math.random(4,9) * 2
    end

    return pusherNum
end


function CodeGameScreenCandyPusherMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    local reelNode = node
    if symbolType == self.SYMBOL_BONUS_1 then
        
        local posIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)
        local lab = node:getCcbProperty("ml_coin")
        if lab then
            lab:setString(self:getBonus1Num( posIndex ))
        end

        local fsCoinsNode = node:getCcbProperty("CandyPusher_bonus_1")
        if fsCoinsNode then
            fsCoinsNode:setVisible(false)
        end

    end
end

function CodeGameScreenCandyPusherMachine:showCoinsPusherOver(coins,func,isAuto )

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
    self.m_syncDirtyNode:stopAllActions()


    local BonusOverView = util_createView("CandyPusherSrc.CandyPusherBonusOverView")
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

function CodeGameScreenCandyPusherMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "CandyPusherSounds/CandyPusherSounds_ScatterDown.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end


-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenCandyPusherMachine:specialSymbolActionTreatment(_slotNode)
    CodeGameScreenCandyPusherMachine.super.specialSymbolActionTreatment(self, _slotNode )
    local slotNode = _slotNode
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
        slotNode:runAnim("buling")
    end

end

function CodeGameScreenCandyPusherMachine:playCustomSpecialSymbolDownAct( slotNode )
    CodeGameScreenCandyPusherMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )
    if self:isSpecailSymbol(slotNode.p_symbolType) == true then

        local soundPath =  "CandyPusherSounds/CandyPusherSounds_BonusDown.mp3"
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
function CodeGameScreenCandyPusherMachine:getBounsScatterDataZorder(symbolType )

    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    if self:isSpecailSymbol(symbolType) then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_1 
    end

    local order = CodeGameScreenCandyPusherMachine.super.getBounsScatterDataZorder(self,symbolType )

    
    return order

end



function CodeGameScreenCandyPusherMachine:playColelctAni(_func )
    

    local waitTime = 0.1 
    local moveTime = 0.3
    local startNodeList = {}
    local endNode = self.m_pGamePusherMgr:getMainUiNode( ):findChild("pusherLevel_LeftNum")
    local endPos = util_convertToNodeSpace(endNode,self)
    
    local index = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == self.SYMBOL_BONUS_1 then
                    index = index + 1
                    local startNode = util_createAnimation("Socre_CandyPusher_Bonus_1.csb")
                    self:addChild(startNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                    table.insert(startNodeList,startNode)
                    startNode:setPosition(util_convertToNodeSpace(slotNode,self))
                    startNode:findChild("ml_coin"):setString(slotNode:getCcbProperty("ml_coin"):getString())
                    startNode:setVisible(false)
                    performWithDelay(startNode,function(  )
                        slotNode:runAnim("actionframe2")
                        startNode:setVisible(true)
                        local startNode_1 = startNode
                        self:playBonusMove(startNode_1,moveTime,endPos,function(  )
                            startNode_1:setVisible(false)
                        end )
                    end,(index - 1 )*0.2)
                end
            end
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode,function(  )

        self.m_pGamePusherMgr:getMainUiNode():playLeftCoinsAnim( "autoJump",true)
        self:jumpCollectCoins(function(  )

            if _func then
                _func()
            end

            performWithDelay(waitNode,function(  )
                for i=1,#startNodeList do
                    local node = startNodeList[i]
                    node:removeFromParent()
                end
                waitNode:removeFromParent()
            end,1)
            
        end,(index - 1 )*0.2)

    end, moveTime)

end

function CodeGameScreenCandyPusherMachine:playBonusMove(_node,_time,_pos,_func )

    gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_CollectFly.mp3") 
    local actionList = {}
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            util_playScaleToAction(_node,_time,1)
        end
    )
    actionList[#actionList + 1] = cc.MoveTo:create(_time, _pos)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_CollectFanKui.mp3") 
            if _func then
                _func()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    _node:runAction(seq)
end

function CodeGameScreenCandyPusherMachine:jumpCollectCoins(_func,time)
    local pushersData = self.m_pGamePusherMgr:getPusherUseData() or {} --字段名称不要轻易修改会影响本地数据存储逻辑
    if pushersData and table_length(pushersData) ~= 0 then
        local pusherMaxUseNum = pushersData.pusherMaxUseNum  -- 赠送的金币的可使用的最大次数
        local superBonusOccur = pushersData.netInitData.superBonusOccur -- super Bonus
        local playPropData = {}
        playPropData.ntimes = pusherMaxUseNum
        playPropData.jumpTime = time
        if superBonusOccur then
            playPropData.ntimes = pusherMaxUseNum / 2 -- superBonus 需要有一个成倍的过程，先减后加
        end
        playPropData.callfunc = function(  )
            if _func then
                _func()
            end
        end
        gLobalNoticManager:postNotification(Config.Event.GamePusherMainUI_JumpLeftFreeCoinsTimes,playPropData)
    end
end


function CodeGameScreenCandyPusherMachine:showTriggerBonus(_func )

    gLobalSoundManager:playSound("CandyPusherSounds/CandyPusherSounds_BonusTrigger.mp3") 


    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if self:isSpecailSymbol(slotNode.p_symbolType) then
                    slotNode:runAnim("actionframe",false,function(  )
                        slotNode:runAnim("idleframe",true)
                    end)
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



function CodeGameScreenCandyPusherMachine:showGuoChang( )

    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_ShowGuoChang.mp3") 
    self.m_guoChang:setVisible(true)

    performWithDelay(self,function(  )
        self.m_guoChang:findChild("Particle_1_0"):resetSystem()
        self.m_guoChang:findChild("Particle_1_0_0"):resetSystem()
        self.m_guoChang:findChild("Particle_1"):resetSystem()
        self.m_guoChang:findChild("Particle_1_1"):resetSystem()
        self.m_guoChang:findChild("Particle_1_1_0"):resetSystem()
    end,30/60)
    

    self.m_guoChang:runCsbAction("actionframe",false,function(  )
        self.m_guoChang:setVisible(false)
    end)
    
end

function CodeGameScreenCandyPusherMachine:isSpecailSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 then
        return true
    end
    return false
end



-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCandyPusherMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCandyPusherMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

---
-- 显示free spin
function CodeGameScreenCandyPusherMachine:showEffect_FreeSpin(effectData)

    self:removeSoundHandler() -- 移除监听

    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
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
                    end
                    slotNode:runAnim("actionframe")
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                    
                end
                
            end
        end
    end

    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)

    return true
end

-- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenCandyPusherMachine:showFreeSpinView(effectData)

    

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("CandyPusherSounds/music_CandyPusher_Fs_MoreView.mp3")
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            if display.height >= display.width then
                if display.height <= 1228 then
                    view:findChild("root"):setScale(view:getUIScalePro())
                end
            else
                if display.width <= 1228 then
                    view:findChild("root"):setScale(view:getUIScalePro())
                end
            end
            
        else
            gLobalSoundManager:playSound("CandyPusherSounds/music_CandyPusher_Fs_StartView.mp3")
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:changeReelImg(true )
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end,false)
            if display.height >= display.width then
                if display.height <= 1228 then
                    view:findChild("root"):setScale(view:getUIScalePro())
                end
            else
                if display.width <= 1228 then
                    view:findChild("root"):setScale(view:getUIScalePro())
                end
            end
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenCandyPusherMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("CandyPusherSounds/music_CandyPusher_fs_OverView.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:changeReelImg(false )
            self:triggerFreeSpinOverCallFun()
        end)
    local node=view:findChild("m_lb_coins")
    if node then
        view:updateLabelSize({label=node,sx=1,sy=1},650)
    end
    if display.height >= display.width then
        if display.height <= 1228 then
            view:findChild("root"):setScale(view:getUIScalePro())
        end
    else
        if display.width <= 1228 then
            view:findChild("root"):setScale(view:getUIScalePro())
        end
    end




end

function CodeGameScreenCandyPusherMachine:changeReelImg(_isFree )
    if _isFree then
        self.m_logo:setVisible(false)
        self:findChild("Node_reelBG_free"):setVisible(true)
        self:findChild("Node_reelBG"):setVisible(false)
    else
        self.m_logo:setVisible(true)
        self:findChild("Node_reelBG_free"):setVisible(false)
        self:findChild("Node_reelBG"):setVisible(true)
    end
end



function CodeGameScreenCandyPusherMachine:playSuperBonusRadialAni(_func )
    gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_SuperToX2.mp3")
    local startPos = util_convertToNodeSpace(self.m_collectBar:findChild("Node_Zi"), self)  
    local endPos = util_convertToNodeSpace(self.m_pGamePusherMgr:getMainUiNode().m_leftCoinsCsb, self)  
    
    local flylab = util_createAnimation("CandyPusher_shouji_zi.csb")
    self:addChild(flylab, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2) 
    flylab:setPosition(cc.p(startPos))
    flylab:setVisible(false)
    flylab:runCsbAction("actionframe3")
 
    self.m_collectBar:runCsbAction("actionframe2")
    self.m_collectBar.m_super:runCsbAction("actionframe2",false,function(  )

        flylab:setVisible(true)
        flylab:findChild("Particle_1"):resetSystem()
        flylab:findChild("Particle_1"):setPositionType(0)
        flylab:findChild("Particle_1"):setDuration(-1)

        gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_SuperFly.mp3")

        local time = 0.5
        util_playMoveToAction(flylab,time,endPos,function(  )
            
            gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_SuperFlyFanKui.mp3")

            if _func then
                _func()
            end

            flylab:removeFromParent()

        end)
    end)
    

end

function CodeGameScreenCandyPusherMachine:pusherToSlotsAnimate( )
    
    self.m_pGamePusherMgr.m_pusherMain._freeSpinText:setVisible(false)
    self.m_collectBar:runCsbAction("idle",true)
    self.m_collectBar.m_super:runCsbAction("idle",true)
    self.m_jpBar.m_AverageBet = nil
    self.m_jpBar:runCsbAction("idle1",true) 
    self:findChild("root_1"):setVisible(true)
    self:showGuoChang( )    
    self.m_pGamePusherMain:MoveCamera( 2 , 0.5 )
    self.m_bottomUI:setVisible(true)

    if self.m_bProduceSlots_InFreeSpin then
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalData.slotRunData.lastWinCoin = lastWinCoin  
    else
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_BonusWinCoins,true,true})
        globalData.slotRunData.lastWinCoin = lastWinCoin  
    end
    
    self.m_pGamePusherMgr:setPusherSpeed( Config.BaseReelSpeed  )

    
    self:runCsbAction("start",false,function(  )

        local front = self.m_pGamePusherMgr:getFrontEffectNode( )
        if front then
            front:setVisible(false)
        end

        self:runCsbAction("idle",true)
        

        performWithDelay(self,function(  )
            -- 通知bonus 结束， 以及赢钱多少
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_BonusWinCoins, GameEffect.EFFECT_BONUS})
            -- 更新游戏内每日任务进度条
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
            gLobalNoticManager:postNotification(ViewEventType.COINCIRCUS_NOTIC_BONUS_OVER) -- 推送推币机bonus结束
        end,0.5)
            
    end)
end

return CodeGameScreenCandyPusherMachine






