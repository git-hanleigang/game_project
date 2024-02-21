---
-- island li
-- 2019年1月26日
-- CodeGameScreenRoaringKingMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenRoaringKingMachine = class("CodeGameScreenRoaringKingMachine", BaseSlotoManiaMachine)

CodeGameScreenRoaringKingMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenRoaringKingMachine.SYMBOL_JACKPOT = 100 
CodeGameScreenRoaringKingMachine.SYMBOL_JACKPOT_1 = 103 -- grand
CodeGameScreenRoaringKingMachine.SYMBOL_JACKPOT_2 = 102 -- major
CodeGameScreenRoaringKingMachine.SYMBOL_JACKPOT_3 = 101 -- minor

CodeGameScreenRoaringKingMachine.SYMBOL_JACKPOT_BG = 200 
CodeGameScreenRoaringKingMachine.FREESPIN_SCATTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenRoaringKingMachine.FREESPIN_JACKPOT_EFFECT = GameEffect.EFFECT_LINE_FRAME + 2 -- 自定义动画的标识
CodeGameScreenRoaringKingMachine.m_netStcValidSymbolMatrix = {}  -- 存储一份网络数据轮盘，本地需要修改
CodeGameScreenRoaringKingMachine.m_repeatWinCoins = 0

CodeGameScreenRoaringKingMachine.LINES_VOICE = {
    [1] = "music_RoaringKing_amazing",
    [2] = "music_RoaringKing_bigwin",
    [3] = "music_RoaringKing_electrifying",
    [4] = "music_RoaringKing_extremewin",
    [5] = "music_RoaringKing_goldenlion",
    [6] = "music_RoaringKing_hugefortune",
    [7] = "music_RoaringKing_inconceivable",
    [8] = "music_RoaringKing_Luckyyou",
    [9] = "music_RoaringKing_mightylion",
    [10] = "music_RoaringKing_thepowerofthewild",
    [11] = "music_RoaringKing_wildlion",
    [12] = "music_RoaringKing_exciting"
}

CodeGameScreenRoaringKingMachine.m_voiceId = 1

-- 构造函数
function CodeGameScreenRoaringKingMachine:ctor()
    CodeGameScreenRoaringKingMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_netStcValidSymbolMatrix = {} 
    self.m_spinRestMusicBG = true
    self.m_bCreateResNode  = false
    self.m_repeatWinCoins = 0
    self.m_voiceId = 1
    self.m_isCollectSCStop = false
    self.m_isCollectJpStop = false
    --init
    self:initGame()
end

function CodeGameScreenRoaringKingMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenRoaringKingMachine:scaleMainLayer()
    CodeGameScreenRoaringKingMachine.super.scaleMainLayer(self)

    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 3)

    if display.width/display.height <= 920/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.95)
        self.m_machineRootScale = self.m_machineRootScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width/display.height <= 1152/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.95)
        self.m_machineRootScale = self.m_machineRootScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width/display.height <= 1228/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.95)
        self.m_machineRootScale = self.m_machineRootScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRoaringKingMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RoaringKing"  
end

function CodeGameScreenRoaringKingMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self.m_gameBg:runCsbAction("base",true)
   
    self.m_baseBgSpine = util_spineCreate("GameScreenRoaringKingBg",true,true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_baseBgSpine)
    self.m_fsBgSpine = util_spineCreate("GameScreenRoaringKingBg",true,true)
    self.m_gameBg:findChild("free_bg"):addChild(self.m_fsBgSpine)
    util_spinePlay(self.m_fsBgSpine,"free_idle",true)
    util_spinePlay(self.m_baseBgSpine,"base_idle",true)

   
    -- self:initFreeSpinBar() -- FreeSpinbar

    self.m_lionHead = util_createView("CodeRoaringKingSrc.RoaringKingLionHead",self) 
    self:findChild("Node_shizitou"):addChild(self.m_lionHead)

    self.m_jpBar = util_createView("CodeRoaringKingSrc.RoaringKingJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jpBar)
    self.m_jpBar:initMachine(self)
    
    -- 显示的连线动画
    self.p_lines = {}
    for i=1,5 do -- 5条线
        local line = util_createAnimation("Socre_RoaringKing_lianxian_"..i..".csb")
        self:findChild("Node_lianxian"):addChild(line,2)
        self.p_lines[#self.p_lines+1] = line
    end
    self:hideAllLines( )

    self.m_lineMask = util_createAnimation("RoaringKing_mask.csb")
    self:findChild("Node_mask"):addChild(self.m_lineMask)

    self.m_jpView = util_createView("CodeRoaringKingSrc.RoaringKingJackPotWinView")
    self:addChild(self.m_jpView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    self.m_jpView:setVisible(false)
    self.m_jpView:setScale(self.m_machineRootScale)
    self.m_jpView:setPosition(util_convertToNodeSpace(self:findChild("Node_JpView"), self))

    local endNode = self.m_bottomUI.coinWinNode
    self.m_totalWin = util_createAnimation("RoaringKing_totalwin.csb")
    endNode:addChild(self.m_totalWin)
    self.m_totalWin:setPositionY(-10)
    self.m_totalWin:setVisible(false)
    
    self.m_totalWinBd = util_createAnimation("RoaringKing_totalwin_bd.csb")
    endNode:addChild(self.m_totalWinBd)
    self.m_totalWinBd:setVisible(false)
    self.m_totalWinBd:setPositionY(-10)

                    
    self:findChild("Node_shizitou"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 2)
    self:findChild("Node_lianxian"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 3)
    self:findChild("Node_mask"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    self:findChild("Node_yugao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 5)

    self:changeMainUI( )

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scCoinsLab = cc.Node:create()
    self:addChild(self.m_scCoinsLab,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    self.m_scNode = cc.Node:create()
    self:addChild(self.m_scNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

    self.m_yuGaoCsb = util_createAnimation("RoaringKing_free_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yuGaoCsb)
    self.m_yuGaoCsb:setVisible(false)
    self.m_yuGaoSpine = util_spineCreate("RoaringKing_yugao",true,true) 
    self.m_yuGaoCsb:findChild("Node_1"):addChild(self.m_yuGaoSpine)

    

end

function CodeGameScreenRoaringKingMachine:enterGamePlayMusic(  )
  
      self:playEnterGameSound( "RoaringKingSounds/music_RoaringKing_enter.mp3" )

end

function CodeGameScreenRoaringKingMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRoaringKingMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local fsExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local repeatWinList = fsExtra.repeatWinList or {}

    if self:getCurrSpinMode() == FREE_SPIN_MODE or #repeatWinList > 1 then
        self:setCurrSpinMode(FREE_SPIN_MODE)
        self:setFsCount( )
        self:changeMainUI(true )
        self.m_lionHead:updateNodeShowIdle( repeatWinList )
        self.m_gameBg:runCsbAction("free",true)
        self:showFreeSpinBar()
    end
end


function CodeGameScreenRoaringKingMachine:addObservers()

    CodeGameScreenRoaringKingMachine.super.addObservers(self)

        -- 大赢结束事件
    gLobalNoticManager:addObserver(self,function(target, param)
        if self.m_JpColletOver then
            self.m_JpColletOver = false
            self:resetMusicBg()
        end
    end,ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT)

    -- --点击了特殊spin按钮 监听
    gLobalNoticManager:addObserver(self,function(Target,params)

        

        if self.m_isCollectSCStop then
            self.m_isCollectSCStop = false
            self:quickStopScatterCollect()
        end
        
        if self.m_isCollectJpStop then
            self.m_isCollectJpStop = false
            gLobalNoticManager:postNotification("ROARINKING_NOTIFY_CLOSE_JP_VIEW") 
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN) -- 隐藏特殊spin按钮

    end,ViewEventType.NOTIFY_LEVEL_CLICKED_SPECIAL_SPIN)
    
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        local fsExtra = self.m_runSpinResultData.p_fsExtraData or {}
        local repeatWinList = fsExtra.repeatWinList or {}
        self.m_lionHead:updateLab(repeatWinList )

        local features = self.m_runSpinResultData.p_features or {}
        if #features > 1 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
            print("正常游戏单轮最后一次free不变化狮子头")
        else
            self.m_lionHead:updateNodeShow( repeatWinList )
        end
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

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
        elseif winRate > 3 then
            soundIndex = 3
            self:playVoice( )
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "RoaringKingSounds/music_RoaringKing_last_win_".. soundIndex .. ".mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "RoaringKingSounds/music_RoaringKing_FS_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end



function CodeGameScreenRoaringKingMachine:playVoice( )
    
    local soundId = math.random(1,#self.LINES_VOICE) 

    while soundId == self.m_voiceId  do
        soundId = math.random(1,#self.LINES_VOICE) 
    end

    self.m_voiceId = soundId
    gLobalSoundManager:playSound("RoaringKingSounds/"  .. self.LINES_VOICE[self.m_voiceId] ..   ".mp3")

end

function CodeGameScreenRoaringKingMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRoaringKingMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenRoaringKingMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_JACKPOT then
        return "Socre_RoaringKing_jackpot_Jackpot"
    elseif symbolType == self.SYMBOL_JACKPOT_1 then
        return "Socre_RoaringKing_jackpot_Grand"
    elseif symbolType == self.SYMBOL_JACKPOT_2 then
        return "Socre_RoaringKing_jackpot_Major"
    elseif symbolType == self.SYMBOL_JACKPOT_3 then
        return "Socre_RoaringKing_jackpot_Minor"
    elseif symbolType == self.SYMBOL_JACKPOT_BG then
        return "Socre_RoaringKing_jackpotBg"
    end

    return nil
end

function CodeGameScreenRoaringKingMachine:isSpecailSymbol( _symbolType )
    if _symbolType == self.SYMBOL_JACKPOT then
        return true
    elseif _symbolType == self.SYMBOL_JACKPOT_1 then
        return true
    elseif _symbolType == self.SYMBOL_JACKPOT_2 then
        return true
    elseif _symbolType == self.SYMBOL_JACKPOT_3 then
        return true
    end
    return false
end
---
--设置bonus scatter 层级
function CodeGameScreenRoaringKingMachine:getBounsScatterDataZorder(symbolType )

    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    if self:isSpecailSymbol(symbolType) then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 2
    elseif  TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
    end

    local order = CodeGameScreenRoaringKingMachine.super.getBounsScatterDataZorder(self,symbolType )

    

    return order

end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到SYMBOL_JACKPOT_的创建，如果有特殊信号则自己添加
--
function CodeGameScreenRoaringKingMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenRoaringKingMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenRoaringKingMachine:MachineRule_initGame(  )

    local fsExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local repeatWinList = fsExtra.repeatWinList or {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE or #repeatWinList > 1 then
        self.m_repeatWinCoins = repeatWinList[1] or 0
    end
    
end

--
--单列滚动停止回调
--
function CodeGameScreenRoaringKingMachine:slotOneReelDown(reelCol)    
    CodeGameScreenRoaringKingMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenRoaringKingMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenRoaringKingMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenRoaringKingMachine:checkHaveBigWinEffect( )
    if  self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
            self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
                self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        return true
    end
end

----------- FreeSpin相关
---
-- 显示free spin
function CodeGameScreenRoaringKingMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    local time = 0
    local winLines = self.m_reelResultLines or 0
    if #winLines > 0 and not self:checkHaveBigWinEffect() then
        time = self.m_changeLineFrameTime or 0
    end

    local lineLen = #self.m_reelResultLines
    local wildLineValue = {}
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        local vecValidMatrixSymPos = lineValue.vecValidMatrixSymPos or {}
        local isCopy = false
        local linInfo = clone(lineValue)
        linInfo.vecValidMatrixSymPos = {}
        for pos=1,#vecValidMatrixSymPos do
            local fixPos = vecValidMatrixSymPos[pos]
            local iRow = fixPos.iX
            local iCol = fixPos.iY
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if  symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                table.insert( linInfo.vecValidMatrixSymPos, fixPos )
                linInfo.iLineSymbolNum = #linInfo.vecValidMatrixSymPos
                isCopy = true
            end
        end
        if isCopy then
            table.insert( wildLineValue,linInfo )
        end
        
    end
    
    performWithDelay(self,function(  )
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        self:clearCurMusicBg()

        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE  then

            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
            
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
            if #wildLineValue > 0 then
                
                gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_Wild_Lion_Trigger.mp3")
                self:shakeRoot(  )

                self.m_lineMask:setVisible(false)
                self.m_lineMask:runCsbAction("idleframe")

                for i=1,#wildLineValue do
                    local info = wildLineValue[i]
                    local iLineIdx = info.iLineIdx
                    if iLineIdx then
                        local node = self.p_lines[iLineIdx + 1]
                        if node then
                            node:setVisible(true)
                            node:runCsbAction("actionframe",true)
                        end
                    end
                    if i == #wildLineValue then
                        self:showBonusAndScatterLineTip(info, function(  )
                            self.m_lineMask:setVisible(false)
                            self:hideAllLines( )
                            self:showFreeSpinView(effectData)
                        end)
                    else
                        self:showBonusAndScatterLineTip(info,function(  )
                            print("-- 不处理")
                        end)
                    end
                   
                end
                
            else
                self:showFreeSpinView(effectData)
            end
        else
            self:showFreeSpinView(effectData)
        end
        
        
    end,time)
    
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenRoaringKingMachine:setSlotNodeEffectParent(slotNode)
    local slotNode = CodeGameScreenRoaringKingMachine.super.setSlotNodeEffectParent(self,slotNode)
    slotNode:runAnim("actionframe")
    return slotNode
end

function CodeGameScreenRoaringKingMachine:addFsViewLight(_view )
    
    local light = util_createAnimation("RoaringKing/FreeSpinStart_shine.csb")
    _view:findChild("Node_shine"):addChild(light)
    light:runCsbAction("idleframe",true)

    util_setCascadeOpacityEnabledRescursion(_view,true)
end

-- FreeSpinstart
function CodeGameScreenRoaringKingMachine:showFreeSpinView(effectData)

    

    local showFSView = function ( ... )
        local fsExtra = self.m_runSpinResultData.p_fsExtraData or {}
        local repeatWinList = fsExtra.repeatWinList or {}
        
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE  then

            gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_Fs_More.mp3")


            local view = self:showFreeSpinStart( self.m_runSpinResultData.p_freeSpinNewCount,function()
                local fsExtra = self.m_runSpinResultData.p_fsExtraData or {}
                local repeatWinList = fsExtra.repeatWinList or {}
                self.m_lionHead:updateLab(repeatWinList )
                self.m_lionHead:updateNodeShow( repeatWinList )

                self.m_lionHead:resetLabNum( )
                self:resetMusicBg()

                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            self:addFsViewLight( view )
            view.m_btnTouchSound = "RoaringKingSounds/music_RoaringKin_Click.mp3"
            view:setBtnClickFunc(function(  )
                gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_fs_start_Hide.mp3")
            end)
            local coins = repeatWinList[1] or 0
            local coinsLab = view:findChild("BitmapFontLabel_5")
            coinsLab:setString(util_formatCoins(coins * globalData.slotRunData:getCurTotalBet(),3))

            local imgStart = view:findChild("RoaringKing_zi07_7")
            local imgMore = view:findChild("RoaringKing_zi05_15")
            imgStart:setVisible(false)
            imgMore:setVisible(true)

            self.m_repeatWinCoins = coins or 0

        else
            gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_fs_start_show.mp3")
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                
                self:changeMainUI( true )

                local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                local LeftCount = fsExtraData.freeSpinsLeftTimes or -1
                local TotalCount = fsExtraData.freeSpinsTotalTimes or -2

                if  TotalCount == LeftCount  then
                    self.m_lionHead:playFsTriggerAnim()
                    self.m_lionHead:updateNodeShow( repeatWinList )
                    self.m_gameBg:runCsbAction("base_free",false,function(  )
                        self.m_gameBg:runCsbAction("free",true)
                    end)
                end
                
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()  
            end)
            self:addFsViewLight( view )
            view.m_btnTouchSound = "RoaringKingSounds/music_RoaringKin_Click.mp3"
            view:setBtnClickFunc(function(  )
                gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_fs_start_Hide.mp3")
            end)
            local coins = repeatWinList[1] or 0
            local coinsLab = view:findChild("BitmapFontLabel_5")
            coinsLab:setString(util_formatCoins(coins * globalData.slotRunData:getCurTotalBet(),3))

            local imgStart = view:findChild("RoaringKing_zi07_7")
            local imgMore = view:findChild("RoaringKing_zi05_15")
            imgStart:setVisible(true)
            imgMore:setVisible(false)
            
            self.m_repeatWinCoins = coins or 0

        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenRoaringKingMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_Fs_over.mp3")
    local coins = self.m_runSpinResultData.p_fsWinCoins or 0
    local strCoins = util_formatCoins(coins,50)
    local freeSpinsTotalCount = globalData.slotRunData.totalFreeSpinCount
    local view = self:showFreeSpinOver( strCoins,freeSpinsTotalCount,function()
        self:changeMainUI( )
        self.m_gameBg:runCsbAction("free_base",false,function(  )
            self.m_gameBg:runCsbAction("base",true)
        end)
        self:triggerFreeSpinOverCallFun()
    end)
    view.m_btnTouchSound = "RoaringKingSounds/music_RoaringKin_Click.mp3"
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},818)
    local node_1 = view:findChild("m_lb_num")
    view:updateLabelSize({label=node_1,sx=1,sy=1},68)

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRoaringKingMachine:MachineRule_SpinBtnCall()
    self.m_JpColletOver = false 
    self:setMaxMusicBGVolume( )
    self.m_isCollectSCStop = false
    self.m_isCollectJpStop = false
    self.m_scNode:removeAllChildren()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenRoaringKingMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        notAdd = false
    end
    return notAdd
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRoaringKingMachine:addSelfEffect()
        
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local scatterNum = self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        if scatterNum > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREESPIN_SCATTER_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREESPIN_SCATTER_EFFECT -- 动画类型
        end

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpotWin = selfdata.jackpotWin
        if jackpotWin then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREESPIN_JACKPOT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREESPIN_JACKPOT_EFFECT -- 动画类型
        end
        

    end
        

end

function CodeGameScreenRoaringKingMachine:fsUpdateBottomCoinsLab(winCoin,beiginCoins,notPlaySound,isplay )

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    local params = {winCoin, false,isplay,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = notPlaySound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    globalData.slotRunData.lastWinCoin = lastWinCoin

end

function CodeGameScreenRoaringKingMachine:quickStopScatterCollect( )

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN) -- 隐藏特殊spin按钮
    self.m_scCoinsLab:stopAllActions()

    local isQuickStop = false
    for i=1,#self.m_scatterList do
        local node = self.m_scatterList[i].node
        local isPlay = self.m_scatterList[i].isplay
        if node and not isPlay then
            local SoundPlay = false
            if i == #self.m_scatterList then
                SoundPlay = true
            end
            self.m_scatterList[i].isplay = true
            self:playCollectAnim( node,0,self.m_scbeiginCoins,self.m_scAddCoins,i,SoundPlay,true)
            self.m_scCount = self.m_scCount + 1
            isQuickStop = true
        end
    end

    if isQuickStop then
        local waitTime = 0
        local oldCoins,linesCoins,scatterCoins,jackPotCoins = self:getAllWinCoins( )
        if linesCoins > 0 or self:checkHaveBigWinEffect() then
            waitTime = 21/30
        end

        self.m_scWaitNode:stopAllActions()
        performWithDelay(self.m_scWaitNode,function(  )
            local coins = self.m_runSpinResultData.p_fsWinCoins or 0
            self:fsUpdateBottomCoinsLab(coins,nil,true,false )

            self.m_totalWinBd:setVisible(false)
            self.m_totalWin:setVisible(false)
            if self.m_scEffectData then
                self.m_scEffectData.p_isPlay = true
                self:playGameEffect()
            end
        end,waitTime)
    end
end

function CodeGameScreenRoaringKingMachine:playCollectAnim( node,delayTime,beiginCoins,addCoins,index,isPlaySound,isQuickStop)
    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local id = index
        local startCoins = beiginCoins +  self.m_scCount  * addCoins
        local endCoins = beiginCoins +  (self.m_scCount + 1) * addCoins
        local SoundPlay = isPlaySound
        local quickStop = isQuickStop
        performWithDelay(self.m_scCoinsLab,function(  )

            local SoundPlay_1 = SoundPlay

            if SoundPlay_1 then
                gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_scatterCollect_Fly.mp3")
            end

            self.m_scatterList[id].isplay = true

            local coinsLab = util_createAnimation("Socre_RoaringKing_Scatter_Lab.csb")
            self.m_scCoinsLab:addChild(coinsLab)
            coinsLab:setScale(self.m_machineRootScale)
            coinsLab:setPosition(util_convertToNodeSpace(node, self))
    
            local iCol = node.p_cloumnIndex
            local iRow = node.p_rowIndex
            local coins = self:getScatterWinCoins( self:getPosReelIdx(iRow, iCol)) or 0
            local Lab = coinsLab:findChild("m_lb_coins")
            Lab:setString(util_formatCoins(coins ,3))
    
            local coinstw = util_createAnimation("RoaringKing_Scatter_tw.csb")
            coinsLab:findChild("Node_1"):addChild(coinstw)
            coinstw:findChild("Particle_1"):setDuration(-1)    
            coinstw:findChild("Particle_1"):setPositionType(0)
            coinstw:findChild("Particle_2"):setDuration(-1)    
            coinstw:findChild("Particle_2"):setPositionType(0)
            local endNode = self.m_bottomUI.coinWinNode
            coinsLab:setVisible(false)

            self:addScatterLab( node,"")
            node:runAnim("actionframe2")
            local scatterNode = util_spineCreate(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_SCATTER),true,true)
            self.m_scNode:addChild(scatterNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
            scatterNode:setScale(self.m_machineRootScale)
            scatterNode:setPosition(cc.p(util_convertToNodeSpace(node, self)))
            util_spinePlay(scatterNode,"actionframe2",false)
            performWithDelay(scatterNode,function(  )
                scatterNode:removeFromParent()
            end,2)
        
            local endCoins_1,startCoins_1  = endCoins,startCoins 
            coinsLab:setVisible(true)

            local coinsLab_1 = coinsLab
            local coinstw_1 = coinstw
            coinsLab:runCsbAction("actionframe2",false,function(  )
                coinsLab_1:removeFromParent()
            end)
            
            util_playMoveToAction(coinsLab, 18/60,cc.p(util_convertToNodeSpace(endNode, self)),function(  )
                
                if SoundPlay_1 then
                    gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_scatterCollect_FanKui.mp3")
                end
                
                self:fsUpdateBottomCoinsLab(endCoins_1,startCoins_1,true )

                self.m_totalWinBd:setVisible(true)
                self.m_totalWin:setVisible(true)

                self.m_totalWinBd:runCsbAction("actionframe")
                self.m_totalWin:runCsbAction("actionframe")
                self.m_totalWin:findChild("Particle_1"):resetSystem()
                
                coinstw_1:findChild("Particle_1"):stopSystem()
                coinstw_1:findChild("Particle_2"):stopSystem()
            end) 

            if id == #self.m_scatterList then
                if self.m_isCollectSCStop then
                    self.m_isCollectSCStop = false
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN) -- 隐藏特殊spin按钮
            end

        end,self.m_scCount * delayTime)
    

    end
end

function CodeGameScreenRoaringKingMachine:playScatterCollectEffect(effectData)

    

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:setAllJpShowNodeVisible(true )
    self.m_scEffectData = effectData
    self.m_scatterList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local info = {}
                info.node = node
                info.isplay = false
                table.insert( self.m_scatterList, info )
            end 
        end
    end

    local oldCoins,linesCoins,scatterCoins,jackPotCoins = self:getAllWinCoins( )
    local winCoin = oldCoins + scatterCoins
    self.m_scbeiginCoins = oldCoins 
    self.m_scAddCoins = (winCoin - self.m_scbeiginCoins) / #self.m_scatterList
    
    self.m_scCount = 0
    local delayTime =  0.6
    self.m_isCollectSCStop = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_SHOW_SPECIAL_SPIN) -- 显示特殊spin按钮

    for i=1,#self.m_scatterList do
        local node = self.m_scatterList[i].node
        local isPlay = self.m_scatterList[i].isplay
        if node and not isPlay then
            self:playCollectAnim( node,delayTime,self.m_scbeiginCoins,self.m_scAddCoins,i,true)
            self.m_scCount = self.m_scCount + 1
        end
    end
    
    local waitTime =  0
    local oldCoins,linesCoins,scatterCoins,jackPotCoins = self:getAllWinCoins( )
    if linesCoins > 0 or self:checkHaveBigWinEffect() then
        waitTime = 21/30
    end
    
    performWithDelay(self.m_scWaitNode,function(  )
    
        self.m_totalWinBd:setVisible(false)
        self.m_totalWin:setVisible(false)

        if self.m_scEffectData then
            self.m_scEffectData.p_isPlay = true
            self:playGameEffect()
        end
    end,(self.m_scCount-1) * delayTime + waitTime)

    
end

function CodeGameScreenRoaringKingMachine:playJpShowViewTriggerAnim(_func )

    gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_jpCollect_Trigger.mp3")

    for colIndex = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[colIndex]
        local slotParent = parentData.slotParent
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                if childNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
                    self:createJpShowNode(childNode,true,true )
                end
                self:runAllJpBgShowNodesAnim( childNode,"idleframe" )
                local symbol_node = childNode:getCCBNode()
                local Node_symbol = symbol_node.m_csbNode:getChildByName("Node_symbol")
                local jpShowNode = Node_symbol:getChildByName("jpShowNode")
                if jpShowNode then
                    local showNodes = jpShowNode:getChildren() or {}
                    for i=1,#showNodes do
                        local showNode = showNodes[i]
                        if self:isSpecailSymbol(showNode.m_symbolType)  then
                            showNode:runAnim("actionframe2")
                        end
                    end
                end

                local jpShowNodeLab = Node_symbol:getChildByName("jpShowNodeLab")
                if jpShowNodeLab then
                    local showNodes = jpShowNodeLab:getChildren() or {}
                    for i=1,#showNodes do
                        local showNode = showNodes[i]
                        if self:isSpecailSymbol(showNode.m_symbolType)  then
                            showNode:runAnim("actionframe2")
                        end
                    end
                end


                
            end
        end
    end

    performWithDelay(self,function(  )
        if _func then
            _func()
        end
    end,120/60)
end

function CodeGameScreenRoaringKingMachine:playJpShowViewEffect(effectData )

    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 播放触发动画
    self:playJpShowViewTriggerAnim(function(  )

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local jackpotWin = selfdata.jackpotWin
        local index = 1
        for iRow=1,self.m_iReelRowNum do
            local symbolType = self.m_netStcValidSymbolMatrix[iRow][self.m_iReelColumnNum]
            if symbolType == self.SYMBOL_JACKPOT_1 then
                index = 1
            elseif symbolType == self.SYMBOL_JACKPOT_2 then  
                index = 2
            elseif symbolType == self.SYMBOL_JACKPOT_3 then  
                index = 3
                break
            end
        end
        self:showJpView(index,jackpotWin,function(  )

            if self.m_isCollectJpStop then
                self.m_isCollectJpStop = false
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN) -- 隐藏特殊spin按钮

            local oldCoins,linesCoins,scatterCoins,jackPotCoins = self:getAllWinCoins( )
            local winCoin = oldCoins + linesCoins + scatterCoins + jackPotCoins
            local beiginCoins = oldCoins + linesCoins + scatterCoins
            self:fsUpdateBottomCoinsLab(winCoin,beiginCoins )

            if self:checkHaveBigWinEffect() then
                self.m_JpColletOver = true 
            else
                self:resetMusicBg()
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end,function(  )
            self.m_isCollectJpStop = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_SHOW_SPECIAL_SPIN) -- 显示特殊spin按钮
        end )

        
    end )

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenRoaringKingMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FREESPIN_SCATTER_EFFECT then

        self:playScatterCollectEffect(effectData)

    elseif effectData.p_selfEffectType == self.FREESPIN_JACKPOT_EFFECT then

        local time = 0
        local winLines = self.m_reelResultLines or 0
        if #winLines > 0 then
            time = self.m_changeLineFrameTime or 0
        end

        performWithDelay(self,function(  )
            self:playJpShowViewEffect(effectData )
        end,time)
    end

    
    return true
end

function CodeGameScreenRoaringKingMachine:setFsCount( )
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local LeftCount = fsExtraData.freeSpinsLeftTimes
    local TotalCount = fsExtraData.freeSpinsTotalTimes
    if LeftCount and TotalCount  then
        freeSpinsLeftCount = LeftCount
        freeSpinsTotalCount = TotalCount
    end
    
    globalData.slotRunData.freeSpinCount = freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount =  freeSpinsTotalCount 
end



--服务端网络数据返回成功后处理
function CodeGameScreenRoaringKingMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setFsCount( )
    end
    
end

---

function CodeGameScreenRoaringKingMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenRoaringKingMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenRoaringKingMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenRoaringKingMachine.super.slotReelDown(self)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenRoaringKingMachine:operaEffectOver()
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

function CodeGameScreenRoaringKingMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    ************ 连线动画相关    
--]]
function CodeGameScreenRoaringKingMachine:hideAllLines( )
    for i=1,#self.p_lines do
        local node = self.p_lines[i]
        node:setVisible(false)
    end
end
function CodeGameScreenRoaringKingMachine:showAllLines( )
    for i=1,#self.p_lines do
        local node = self.p_lines[i]
        node:setVisible(true)
    end
end

function CodeGameScreenRoaringKingMachine:clearWinLineEffect( )
    CodeGameScreenRoaringKingMachine.super.clearWinLineEffect( self )
    self:hideAllLines( )
    self.m_lineMask:setVisible(false)
end

function CodeGameScreenRoaringKingMachine:showEffect_LineFrame(effectData)
    self.m_lineMask:setVisible(false)
    self.m_lineMask:runCsbAction("actionframe")
    return CodeGameScreenRoaringKingMachine.super.showEffect_LineFrame( self ,effectData)
end

---
-- 显示所有的连线框
--
function CodeGameScreenRoaringKingMachine:showAllFrame(winLines)

    CodeGameScreenRoaringKingMachine.super.showAllFrame( self,winLines )

    self:hideAllLines( )
    for index=1,#winLines do
        local lineValue = winLines[index]
        local iLineIdx = lineValue.iLineIdx
        if iLineIdx then
            local node = self.p_lines[iLineIdx + 1]
            if node then
                node:setVisible(true)
                node:runCsbAction("actionframe",true)
            end
        end
    end
end

function CodeGameScreenRoaringKingMachine:showLineFrame( )

    local winLines = self.m_reelResultLines
    local lines = {}
    for index=1,#winLines do
        local line = winLines[index]
        local lineType = line.enumSymbolType 
        if lineType and lineType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.m_reelResultLines[index].iLineIdx = -1
        end 

        local enumSymbolEffectType = line.enumSymbolEffectType
        if enumSymbolEffectType  then
            self.m_reelResultLines[index].enumSymbolEffectType = 0
        end 
    end

    CodeGameScreenRoaringKingMachine.super.showLineFrame(self)
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenRoaringKingMachine:showLineFrameByIndex(winLines, frameIndex)
    CodeGameScreenRoaringKingMachine.super.showLineFrameByIndex( self,winLines, frameIndex )

    
    local lineValue = winLines[frameIndex]
    local iLineIdx = lineValue.iLineIdx
    if iLineIdx then
        local node = self.p_lines[iLineIdx + 1]
        if node then
            node:setVisible(true)
            node:runCsbAction("actionframe",true)
        end
    end
   
end


function CodeGameScreenRoaringKingMachine:getScatterWinCoins( _pos )
    local totalCoins = ""
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local coins = selfData.storedIcons or {} -- 每个触发bonus给的可以推的个数
    for i=1,#coins do
        local index = coins[i][1]
        if _pos == index then
            local bet = coins[i][2]
            totalCoins = bet * globalData.slotRunData:getCurTotalBet()
            break
        end
    end
    return totalCoins
end

function CodeGameScreenRoaringKingMachine:setScatterScore(_nodelist )

    local symbolNode = _nodelist[1]

    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    local posIndex = self:getPosReelIdx(iRow, iCol)
    local coins = ""
    
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
                coins = util_formatCoins(self:getScatterWinCoins( posIndex ),3) 
            else 
                coins = util_formatCoins(self.m_repeatWinCoins * globalData.slotRunData:getCurTotalBet(),3) 
                if coins == 0 then
                    coins = ""
                end
            end
        end
        self:addScatterLab( symbolNode,coins)
    end

    
end



function CodeGameScreenRoaringKingMachine:addScatterLab( _symbol,_str)
    local symbol_node = _symbol:getCCBNode()
    if symbol_node then
        local spineNode = symbol_node:getCsbAct()
        if tolua.isnull(spineNode.lab)  and _str ~= "" then
            spineNode.lab = util_createAnimation("Socre_RoaringKing_Scatter_Lab.csb")
            util_spinePushBindNode(spineNode,"shuzi",spineNode.lab)   
        end 
        if not tolua.isnull(spineNode.lab)  then
            spineNode.lab:findChild("m_lb_coins"):setString(_str)
        end
        
    end
end


function CodeGameScreenRoaringKingMachine:createJpShowNode(_symbolNode ,_isLast,_isHide )
    local symbolNode = _symbolNode
    local symbol_node = symbolNode:getCCBNode()
    if symbol_node and symbol_node.m_csbNode then
        local Node_symbol = symbol_node.m_csbNode:getChildByName("Node_symbol")
        if Node_symbol then
            if Node_symbol:getChildByName("jpShowNode") then
                Node_symbol:getChildByName("jpShowNode"):removeFromParent()
            end
            
            if Node_symbol:getChildByName("jpShowNodeLab") then
                Node_symbol:getChildByName("jpShowNodeLab"):removeFromParent()
            end
        end 
    end
    
    if symbolNode.p_symbolType == self.SYMBOL_JACKPOT_BG then

        local jpShowNode = cc.Node:create()
        jpShowNode:setName("jpShowNode")
        symbol_node.m_csbNode:getChildByName("Node_symbol"):addChild(jpShowNode,-1) 

        local jpShowNodeLab = cc.Node:create()
        jpShowNodeLab:setName("jpShowNodeLab")
        symbol_node.m_csbNode:getChildByName("Node_symbol"):addChild(jpShowNodeLab,1) 

        
        local columnData = self.m_reelColDatas[symbolNode.p_cloumnIndex]
        local slotNodeH = columnData.p_showGridH

        local jpList = {} -- 只会出现在第一列或第五列
        jpList[1] = self.SYMBOL_JACKPOT
        jpList[5] = self:getRadomJpBgType( ) 
        local symbolTypeList = {math.random(0,2),jpList,math.random(0,2)}
        local rod = math.random(1,8)
        if rod > 3 then
            symbolTypeList = {math.random(4,8),jpList,math.random(4,8)}
        end
        local hideList = {0,0,0}
        --[[
            对应长条bg位置 由下向上 1 2 3
            长条row1: 1;100;1 - 》1，2，3
            长条row2: 100;1 -》 1，2
            长条row0: 1;100 -》2，3
        --]] 
        local rowList = {1,2,3}
        if _isLast then 
            if symbolNode.p_rowIndex == 1 then

                symbolTypeList[1] = self.m_netStcValidSymbolMatrix[1][symbolNode.p_cloumnIndex]
                symbolTypeList[2] = self.m_netStcValidSymbolMatrix[2][symbolNode.p_cloumnIndex]
                symbolTypeList[3] = self.m_netStcValidSymbolMatrix[3][symbolNode.p_cloumnIndex]
            elseif symbolNode.p_rowIndex == 2 then

                symbolTypeList[1] = self.m_netStcValidSymbolMatrix[2][symbolNode.p_cloumnIndex]
                symbolTypeList[2] = self.m_netStcValidSymbolMatrix[3][symbolNode.p_cloumnIndex]
                hideList[3] = 1
                rowList = {2,3,4}
            elseif symbolNode.p_rowIndex == 0 then
                symbolTypeList[2] = self.m_netStcValidSymbolMatrix[1][symbolNode.p_cloumnIndex]
                symbolTypeList[3] = self.m_netStcValidSymbolMatrix[2][symbolNode.p_cloumnIndex]
                rowList = {-1,1,2}
            end
        end

        if not _isHide then
            hideList = {0,0,0}
        end
        for index=1,3 do
            local symbolType = symbolTypeList[index]
            if index == 2 and type(symbolType) == "table" then
                symbolType = symbolType[symbolNode.p_cloumnIndex]
            end
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            local showNode = util_createView("CodeRoaringKingSrc.RoaringKingJpShowSymbol",ccbName,symbolNode.p_cloumnIndex,rowList[index] ,symbolType,index,self) 
            showNode:createOtherSpine( )
            jpShowNode:addChild(showNode) 
            showNode:setTag(index)
            showNode:setPositionY(slotNodeH * (index - 1))
            if hideList[index] == 1 then
                showNode:setVisible(false)
            end
            
            if self:isSpecailSymbol(symbolType) then
                local showNodeLab = util_createView("CodeRoaringKingSrc.RoaringKingJpShowSymbol",ccbName,symbolNode.p_cloumnIndex,rowList[index] ,symbolType,index,self) 
                jpShowNodeLab:addChild(showNodeLab) 
                showNodeLab:setTag(index)
                showNodeLab:setPositionY(slotNodeH * (index - 1))
                if hideList[index] == 1 then
                    showNodeLab:setVisible(false)
                end
            end
            

        end

        
    end

end
-- 假滚时出现长条中间的jackpot信号的假滚概率
function CodeGameScreenRoaringKingMachine:getRadomJpBgType( )
    local symbolType = self.SYMBOL_JACKPOT_1
    local data = {}
    data[self.SYMBOL_JACKPOT_1] = 900
    data[self.SYMBOL_JACKPOT_2] = 100
    data[self.SYMBOL_JACKPOT_3] = 10
    local rad = math.random(1,1010)
    if rad <= data[self.SYMBOL_JACKPOT_3] then
        symbolType = self.SYMBOL_JACKPOT_1
    elseif rad <= data[self.SYMBOL_JACKPOT_2] then 
        symbolType = self.SYMBOL_JACKPOT_2
    -- elseif rad <= data[self.SYMBOL_JACKPOT_3] then
    --     symbolType = self.SYMBOL_JACKPOT_3
    end
    return symbolType
end


function CodeGameScreenRoaringKingMachine:changeNodeUI(_sender,_nodelist )
    self:setScatterScore(_nodelist)
    self:createJpShowNode(_nodelist[1],_nodelist[1].m_isLastSymbol )
end

function CodeGameScreenRoaringKingMachine:updateReelGridNode(node)


    local callFun = cc.CallFunc:create(handler(self,self.changeNodeUI),{node})
    self:runAction(callFun)
end

function CodeGameScreenRoaringKingMachine:changeMainUI(isFree )
    local basedi = self:findChild("Node_basedi")
    basedi:setVisible(false)
    local freedi = self:findChild("Node_freedi")
    freedi:setVisible(false)

    local reel_base = self:findChild("reel_base")
    reel_base:setVisible(false)
    local reel_free = self:findChild("reel_free")
    reel_free:setVisible(false)
    
    if isFree then
        local fsExtra = self.m_runSpinResultData.p_fsExtraData or {}
        local repeatWinList = fsExtra.repeatWinList or {}
        self.m_lionHead:updateLab(repeatWinList )
        freedi:setVisible(true)
        reel_free:setVisible(true)
    else
        basedi:setVisible(true)
        reel_base:setVisible(true)
    end

    self.m_lionHead:changeUI( isFree )
end

-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function CodeGameScreenRoaringKingMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)

    if self:isSpecailSymbol( symbolType ) then
        symbolType = math.random(0,8)
    end
    return symbolType
end

function CodeGameScreenRoaringKingMachine:setNetReelSymbolMatrix(_reel )

    self.m_netStcValidSymbolMatrix = self:getValidSymbolMatrixArray()
    local rowCount = #_reel
    for rowIndex = 1, rowCount do
        local rowDatas = _reel[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            local symbolType = rowDatas[colIndex]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_NIL_TYPE then
                symbolType = nil
            end
            self.m_netStcValidSymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
    end
end
-- 主动修改网络数据,让jackpot连接的地方变成长条
function CodeGameScreenRoaringKingMachine:changeNetReel( _param )
    local reels = clone(_param[2].result.reels)
    local netReels = _param[2].result.reels
    for iRow=1,#netReels do
        for iCol=1,#netReels[iRow] do
            local symbolType = netReels[iRow][iCol]
            if self:isSpecailSymbol(symbolType)  then
                if iRow == 1 then
                    reels[iRow][iCol] = self.SYMBOL_JACKPOT_BG
                    reels[iRow + 1][iCol] = self.SYMBOL_JACKPOT_BG
                elseif iRow == 2 then
                    reels[iRow - 1][iCol] = self.SYMBOL_JACKPOT_BG
                    reels[iRow][iCol] = self.SYMBOL_JACKPOT_BG
                    reels[iRow + 1][iCol] = self.SYMBOL_JACKPOT_BG
                elseif iRow == 3 then
                    reels[iRow - 1][iCol] = self.SYMBOL_JACKPOT_BG
                    reels[iRow][iCol] = self.SYMBOL_JACKPOT_BG
                end
            end
        end
    end

    _param[2].result.reels = reels

    return _param
end

---
-- 处理spin 返回消息的数据结构
--
function CodeGameScreenRoaringKingMachine:operaSpinResultData(param)

    self:setNetReelSymbolMatrix( param[2].result.reels )
    param = self:changeNetReel(param )
    CodeGameScreenRoaringKingMachine.super.operaSpinResultData(self,param)
    
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenRoaringKingMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
                local jpBg = self:getJpBgNode(slotsNode.p_cloumnIndex,slotsNode.p_rowIndex )
                for _frameIndex=1,#self.m_reelResultLines do
                    local lineValue = self.m_reelResultLines[_frameIndex]
                    local vecValidMatrixSymPos = lineValue.vecValidMatrixSymPos or {}
                    for i=1,#vecValidMatrixSymPos do
                        local SymPos = vecValidMatrixSymPos[i]
                        self:runLineAnimJpBgShowNode(jpBg,SymPos.iY,SymPos.iX )
                    end
                end
            else
                slotsNode:runLineAnim()
            end
            
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end


---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenRoaringKingMachine:playInLineNodesIdle()

    self:hideAllLines( )

    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
                self:runAllJpBgShowNodesAnim( slotsNode,"idleframe" )
            else
                slotsNode:runIdleAnim()
            end 
        end
    end
end

function CodeGameScreenRoaringKingMachine:runAllJpBgShowNodesAnim(_slotsNode,_animName,_loop )
    local symbol_node = _slotsNode:getCCBNode()
    local Node_symbol = symbol_node.m_csbNode:getChildByName("Node_symbol")
    local jpShowNode = Node_symbol:getChildByName("jpShowNode")
    if jpShowNode then
        local showNodes = jpShowNode:getChildren() or {}
        for i=1,#showNodes do
            local showNode = showNodes[i]
            if showNode.runAnim then
                showNode:runAnim(_animName,_loop)
            end
        end
    end

    local jpShowNodeLab = Node_symbol:getChildByName("jpShowNodeLab")
    if jpShowNodeLab then
        local showNodes = jpShowNodeLab:getChildren() or {}
        for i=1,#showNodes do
            local showNode = showNodes[i]
            if showNode.runAnim then
                showNode:runAnim(_animName,_loop)
            end
        end
    end

    
end

function CodeGameScreenRoaringKingMachine:runLineAnimJpBgShowNode(_slotsNode,_iCol,_iRow )
    local symbol_node = _slotsNode:getCCBNode()
    local Node_symbol = symbol_node.m_csbNode:getChildByName("Node_symbol")
    local jpShowNode = Node_symbol:getChildByName("jpShowNode")
    if jpShowNode then
        local showNodes = jpShowNode:getChildren() or {}
        for i=1,#showNodes do
            local showNode = showNodes[i]
            if showNode.m_iCol == _iCol and showNode.m_iRow == _iRow then
                if showNode.runAnim then
                    showNode:runAnim("actionframe",true)
                end
            end
        end
    end


    local jpShowNodeLab = Node_symbol:getChildByName("jpShowNodeLab")
    if jpShowNodeLab then
        local showNodes = jpShowNodeLab:getChildren() or {}
        for i=1,#showNodes do
            local showNode = showNodes[i]
            if showNode.m_iCol == _iCol and showNode.m_iRow == _iRow then
                if showNode.runAnim then
                    showNode:runAnim("actionframe",true)
                end
            end
        end
    end
    
end

function CodeGameScreenRoaringKingMachine:getJpBgNode(_iY,_iX )
    local array = self.m_lineSlotNodes or {}
    for index = 1,#array do
        local node = array[index]
        if node.p_symbolType == self.SYMBOL_JACKPOT_BG then
            local iCol = node.p_cloumnIndex
            local iRow = node.p_rowIndex
            local _iCol,_iRow = self:getJpNodeColRow(_iX, _iY)
            if iCol == _iCol and iRow == _iRow then
                return node
            end
        end
    end

end

function CodeGameScreenRoaringKingMachine:getJpNodeColRow(iX, iY)
    local slotNode = nil
    if self.m_bigSymbolColumnInfo ~= nil and
        self.m_bigSymbolColumnInfo[iY] ~= nil then
        local parentData = self.m_slotParents[iY]
        local slotParent = parentData.slotParent

        local bigSymbolInfos = self.m_bigSymbolColumnInfo[iY]
        for k = 1, #bigSymbolInfos do

            local bigSymbolInfo = bigSymbolInfos[k]

            for changeIndex=1,#bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == iX then
                    return iY, bigSymbolInfo.startRowIndex
                end
            end

        end
    end

    return iY,iX
end

function CodeGameScreenRoaringKingMachine:showEachLineSlotNodeLineAnim(_frameIndex )
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if slotsNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
                        local jpBg = self:getJpBgNode(slotsNode.p_cloumnIndex,slotsNode.p_rowIndex )
                        local lineValue = self.m_reelResultLines[_frameIndex]
                        local vecValidMatrixSymPos = lineValue.vecValidMatrixSymPos or {}
                        for i=1,#vecValidMatrixSymPos do
                            local SymPos = vecValidMatrixSymPos[i]
                            self:runLineAnimJpBgShowNode(jpBg,SymPos.iY,SymPos.iX )
                        end
                        
                    else
                        slotsNode:runLineAnim()
                    end 
                end
            end
        end
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenRoaringKingMachine:changeToMaskLayerSlotNode(slotNode)

    CodeGameScreenRoaringKingMachine.super.changeToMaskLayerSlotNode(self,slotNode)

    if slotNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
        self:createJpShowNode(slotNode,true,true )
    end
end

function CodeGameScreenRoaringKingMachine:setAllJpShowNodeVisible(_states )
    for colIndex = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[colIndex]
        local slotParent = parentData.slotParent
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                if childNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
                    self:createJpShowNode(childNode,true,true )
                end
                self:runAllJpBgShowNodesAnim( childNode,"idleframe" )
                local symbol_node = childNode:getCCBNode()
                local Node_symbol = symbol_node.m_csbNode:getChildByName("Node_symbol")
                local jpShowNode = Node_symbol:getChildByName("jpShowNode")
                if jpShowNode then
                    local showNodes = jpShowNode:getChildren() or {}
                    for i=1,#showNodes do
                        local showNode = showNodes[i]
                        showNode:setVisible(_states)
                    end
                end

                local jpShowNodeLab = Node_symbol:getChildByName("jpShowNodeLab")
                if jpShowNodeLab then
                    local showNodes = jpShowNodeLab:getChildren() or {}
                    for i=1,#showNodes do
                        local showNode = showNodes[i]
                        showNode:setVisible(_states)
                    end
                end

                
            end
        end
    end
end

function CodeGameScreenRoaringKingMachine:resetReelDataAfterReel( )
    CodeGameScreenRoaringKingMachine.super.resetReelDataAfterReel(self )
    self:setAllJpShowNodeVisible(true )
end

function CodeGameScreenRoaringKingMachine:showJpView(_index,_coins,_func,_startFunc )
    self.m_jpView:setVisible(true)
    self.m_jpView:initViewData(self,_index,_coins,_func,_startFunc)
end

function CodeGameScreenRoaringKingMachine:checkNotifyUpdateWinCoin()

    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        local winLines = self.m_reelResultLines

        if #winLines <= 0 then
            return
        end

        local oldCoins,linesCoins,scatterCoins,jackPotCoins = self:getAllWinCoins( )
        local winCoin = oldCoins + linesCoins + scatterCoins
        local beiginCoins = oldCoins + scatterCoins
        self:fsUpdateBottomCoinsLab(winCoin,beiginCoins )
        
    else
        CodeGameScreenRoaringKingMachine.super.checkNotifyUpdateWinCoin(self)
    end

end

function CodeGameScreenRoaringKingMachine:getAllWinCoins( )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins
    local oldCoins =  self.m_runSpinResultData.p_fsWinCoins - self.m_iOnceSpinLastWin
    local jackPotCoins = selfdata.jackpotWin or 0
    local scatterCoins = 0
    local totalIndex = self.m_iReelColumnNum * self.m_iReelRowNum
    for index = 1 , totalIndex do
        local scCoins = self:getScatterWinCoins( index - 1 )
        if scCoins ~= "" then
            scatterCoins = scatterCoins + scCoins
        end
    end
    local linesCoins = self.m_iOnceSpinLastWin - scatterCoins - jackPotCoins

    return oldCoins,linesCoins,scatterCoins,jackPotCoins
    
end

---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenRoaringKingMachine:MachineRule_ResetReelRunData()

    local showLongRun = false

    for iRow=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][1]
        if symbolType == self.SYMBOL_JACKPOT_BG then
            showLongRun = true
            break
        end
    end

    if showLongRun then
        local iCol = 5
        local reelRunInfo = self.m_reelRunInfo
        local reelRunData = self.m_reelRunInfo[iCol]
        local columnData = self.m_reelColDatas[iCol]
        if self:getCurrSpinMode() == FREE_SPIN_MODE then 
            -- free game中jackpot，第5列播放快滚5列
            local iRow = columnData.p_showGridCount
            local reelLongRunTime = 2
            local lastColLens = reelRunInfo[iCol- 1]:getReelRunLen()
            local colHeight = columnData.p_slotColumnHeight
            local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
            local preRunLen = reelRunData:getReelRunLen()
            reelRunData:setReelRunLen(runLen)
            self.m_reelRunInfo[iCol-1]:setNextReelLongRun(true)
            self.m_reelRunInfo[iCol-1]:setNextReelLongRun(true)
            self.m_reelRunInfo[iCol-1]:setReelLongRun(true)
        end

        self:setLastReelSymbolList()    
    end

end

function CodeGameScreenRoaringKingMachine:playCustomSpecialSymbolDownAct( slotNode )
    
    local soundPath = nil
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
            slotNode:runAnim("buling")
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex, "RoaringKingSounds/music_RoaringKing_Scatter_Dwon.mp3" )
        end
    end
        
        
    if slotNode.p_symbolType == self.SYMBOL_JACKPOT_BG then
        self:playBulingSymbolSounds( slotNode.p_cloumnIndex, "RoaringKingSounds/music_RoaringKing_Jp_Dwon.mp3" )
    end
    
end

function CodeGameScreenRoaringKingMachine:shakeRoot( func )

    local rootNode = self:findChild("root")
    if not rootNode then
        return
    end

    local changePosY = 5
    local changePosX = 2
    local actionList2={}
    local oldPos = cc.p(rootNode:getPosition())

    for i=1,15 do
        actionList2[#actionList2+1]=cc.MoveTo:create(2/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(2/30,cc.p(oldPos.x,oldPos.y))
    end

    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)


    local seq2=cc.Sequence:create(actionList2)
    rootNode:runAction(seq2)
end

function CodeGameScreenRoaringKingMachine:isAnimalSymbol( type )
    if  type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or
            type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or
                type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 or
                    type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then

        return true
    end

end

-- 连线带wild且带动物图标
function CodeGameScreenRoaringKingMachine:checkLineType(type)

   
    local isPlay = false

    for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
        local checkEndWild = false
        local checkEndAnimal = false
        local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
        if lineData.p_iconPos ~= nil then
            for posIndex = 1, #lineData.p_iconPos do
                local pos = lineData.p_iconPos[posIndex]

                local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                local colIndex = pos % self.m_iReelColumnNum + 1

                local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
               
                if  self:isAnimalSymbol( symbolType ) then
                    checkEndAnimal = true
                end

                if symbolType == type  then
                    checkEndWild = true
                end

                if  checkEndAnimal and checkEndWild then
                    isPlay = true
                    break
                end

            end
        end
        
    end

    return isPlay
end

function CodeGameScreenRoaringKingMachine:showYuGao(_func )

    gLobalSoundManager:playSound("RoaringKingSounds/music_RoaringKing_Yugao.mp3")

    self.m_yuGaoCsb:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine,"actionframe")
    self.m_yuGaoCsb:runCsbAction("actionframe",false,function(  )
        if _func then
            _func()
        end
        self.m_yuGaoCsb:setVisible(false)
    end)
end

function CodeGameScreenRoaringKingMachine:updateNetWorkData()

    local callFunc = function(  )
        CodeGameScreenRoaringKingMachine.super.updateNetWorkData(self)
    end

    local isSmashAni = self:checkLineType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    if isSmashAni then
        local rod =  math.random(1,10)
        if rod <= 2 then
            isSmashAni = false
        end
    end

    if isSmashAni then
        self:showYuGao(callFunc)
    else
        callFunc()
    end
    
end

function CodeGameScreenRoaringKingMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    local oldCoins,linesCoins,scatterCoins,jackPotCoins = self:getAllWinCoins( )
    if linesCoins > 0 then
        showTime = self.m_changeLineFrameTime - 0.5
    end

    return showTime
end


return CodeGameScreenRoaringKingMachine






