---
-- island li
-- 2019年1月26日
-- CodeGameScreenOZMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local OZSlotsNode = require "CodeOZSrc.OZSlotFastNode"

local CodeGameScreenOZMachine = class("CodeGameScreenOZMachine", BaseFastMachine)

CodeGameScreenOZMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenOZMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  
CodeGameScreenOZMachine.SYMBOL_FixBonus = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 
CodeGameScreenOZMachine.SYMBOL_Mini_Scatter = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2

CodeGameScreenOZMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1 
CodeGameScreenOZMachine.EFFECT_TYPE_BONUS = GameEffect.EFFECT_SELF_EFFECT - 2 


CodeGameScreenOZMachine.m_vecMiniWheel = {} -- mini轮盘列表

CodeGameScreenOZMachine.m_chooseIndex = nil
CodeGameScreenOZMachine.m_FsDownTimes = 0

CodeGameScreenOZMachine.m_addDiamondsEffectTimes = 0

CodeGameScreenOZMachine.m_FsAllWinStates = 0

CodeGameScreenOZMachine.m_reelDownSoundIdList = {}

--重写了小块
function CodeGameScreenOZMachine:getBaseReelGridNode()
    return "CodeOZSrc.OZSlotFastNode"
end
-- 构造函数
function CodeGameScreenOZMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_chooseIndex = nil -- freespin触发时选择的轮盘id
    self.m_FsDownTimes = 0
    self.m_addDiamondsEffectTimes = 0
    self.isInBonus = false
    self.m_FsAllWinStates = 0
    self.m_wheelOver = false
    self.m_BonusChestOver = false
    self.m_outLines = false
    self.m_reelDownSoundIdList = {}
    self.m_isFeatureOverBigWinInFree = true

    self.m_lastSetWinCoins = {0,0,0,0}

	--init
	self:initGame()
end

function CodeGameScreenOZMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


function CodeGameScreenOZMachine:initUI()

    self.m_reelRunSound = "OZSounds/music_OZ_LongRun.mp3"

    self.m_gameBg:findChild("bg_Baoxiang"):setVisible(false)

    
    self:createLocalAnimation( )

    self:initMiniMachine( )

    self.m_CollectMainView = util_createView("CodeOZSrc.CollectGame.OZCollectMainView")
    self:findChild("_jindutiao"):addChild(self.m_CollectMainView)

    self.m_JPtMainView = util_createView("CodeOZSrc.JackpotGame.OZJPtMainView")
    self:findChild("lvdiban"):addChild(self.m_JPtMainView)
    self.m_JPtMainView:runCsbAction("idle1",true)

    self.m_GuoChangView = util_createView("CodeOZSrc.OZGuoChangView")
    self:findChild("GuoChang"):addChild(self.m_GuoChangView)
    self.m_GuoChangView:setVisible(false)


    self.m_RunDi = {}
    for i=1,5 do

        local longRunDi =  util_createAnimation("WinFrameOZ_run_0.csb") 
        self:findChild("reel"):addChild(longRunDi,1) 
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunDi, longRunDi )
        longRunDi:setVisible(false)
    end

    self.m_RunTop = {}
    for i=1,5 do

        local longRunTop =  util_createAnimation("WinFrameOZ_run.csb") 
        self:findChild("reel"):addChild(longRunTop,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 500) 
        longRunTop:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunTop, longRunTop )
        longRunTop:setVisible(false)
    end

    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin  then
            return
        elseif self.m_wheelOver then
            self.m_wheelOver = false
            return
        elseif self.m_BonusChestOver then
            self.m_BonusChestOver = false
            return 
        elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
            return
        elseif self.m_outLines then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2

        local soundName = "OZSounds/music_OZ_last_win_low.mp3"

        if winRate >= 1.5 then

            local specialSoundId = self:getSpecialSoundId( ) 
            local ishaveH1Symol = self:checkhaveOneSymol( TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 )
            local ishaveWildSymol = self:checkhaveOneSymol( TAG_SYMBOL_TYPE.SYMBOL_WILD )
            local ishaveH2Symol = self:checkhaveOneSymol( TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 )
            local ishaveH3Symol = self:checkhaveOneSymol( TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 )
            local ishaveH4Symol = self:checkhaveOneSymol( TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 )

            local isAllWildSymol = nil
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                local winLines = self.m_runSpinResultData.p_winLines
                if winLines and #winLines > 0 then
                    isAllWildSymol =  self:checkIsAllOneType( winLines ,0)
                end
            end
             

            if ishaveH1Symol then
                -- 如果有h1 就播h1
                soundName = "OZSounds/music_OZ_last_win_special_".. 0 .. ".mp3"
            elseif isAllWildSymol then
                -- 如果全是wild播放wild
                soundName = "OZSounds/music_OZ_last_win_special_".. 92 .. ".mp3"
            elseif ishaveH2Symol and ishaveH3Symol and ishaveH4Symol then
                -- 如果 h2 h3 h4 都存在那么就随机播人声
                soundName = "OZSounds/music_OZ_last_win_special_".. math.random( 1 , 3 ) .. ".mp3"
            elseif ishaveH2Symol and ishaveH3Symol  then
                -- 如果 h2 h3  都存在那么就随机播人声
                local rodNum = math.random( 1,2)
                
                if rodNum == 1 then
                    soundName = "OZSounds/music_OZ_last_win_special_".. 1 .. ".mp3"
                else
                    soundName = "OZSounds/music_OZ_last_win_special_".. 2 .. ".mp3"
                end
                
            elseif ishaveH2Symol  and ishaveH4Symol then
                -- 如果 h2  h4 都存在那么就随机播人声
                local rodNum = math.random( 1,2)
                if rodNum == 1 then
                    soundName = "OZSounds/music_OZ_last_win_special_".. 1 .. ".mp3"
                else
                    soundName = "OZSounds/music_OZ_last_win_special_".. 3 .. ".mp3"
                end
            elseif  ishaveH3Symol and ishaveH4Symol then
                -- 如果  h3 h4 都存在那么就随机播人声
                local rodNum = math.random( 1,2)
                if rodNum == 1 then
                    soundName = "OZSounds/music_OZ_last_win_special_".. 2 .. ".mp3"
                else
                    soundName = "OZSounds/music_OZ_last_win_special_".. 3 .. ".mp3"
                end
            elseif specialSoundId then
                -- 只有单独的H级别图标
                soundName = "OZSounds/music_OZ_last_win_special_".. specialSoundId .. ".mp3"
            elseif ishaveH2Symol then
                soundName = "OZSounds/music_OZ_last_win_special_".. 1 .. ".mp3"
            elseif ishaveH3Symol then
                soundName = "OZSounds/music_OZ_last_win_special_".. 2 .. ".mp3"
            elseif ishaveH4Symol then
                soundName = "OZSounds/music_OZ_last_win_special_".. 3 .. ".mp3"
            elseif ishaveWildSymol and not ishaveH1Symol and not ishaveH2Symol and not ishaveH3Symol and not ishaveH4Symol then
                -- 如果 普通小块和wild连线有wild就播wild
                soundName = "OZSounds/music_OZ_last_win_special_".. 92 .. ".mp3"
            else

                if winRate >= 2 then
                    -- 以上情况都不满足播放普通 2- 8倍赢钱
                    soundName = "OZSounds/music_OZ_last_win_hight.mp3"
                else
                    soundName = "OZSounds/music_OZ_last_win_low.mp3"
                end
                
            end 

        end
    
        if self.m_winSoundsId == nil then
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,3,0.4,1)
            performWithDelay(self,function()
                self.m_winSoundsId = nil
            end,3)
        end
        
        
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenOZMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "OZSounds/OZ_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "OZSounds/OZ_scatter_down2.mp3"
        elseif i == 3 then
            soundPath = "OZSounds/OZ_scatter_down3.mp3"
        else
            soundPath = "OZSounds/OZ_scatter_down1.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end


function CodeGameScreenOZMachine:initMiniMachine( )
    self.m_vecMiniWheel = {} -- mini轮盘列表

    self.m_vecMiniWheelBg = util_createView("CodeOZSrc.MiniReel.OZMiniReelsBg")
    self:findChild("miniReels"):addChild(self.m_vecMiniWheelBg)

    self.m_vecMiniWheelBg:setVisible(false)

    for i=1,4 do
         local name = "Node_".. i 
         local addNode =  self.m_vecMiniWheelBg:findChild(name)
         if addNode then
             local data = {}
             data.index = i
             data.parent = self
             local miniMachine = util_createView("CodeOZSrc.MiniReel.OZMiniMachine" , data)
             addNode:addChild(miniMachine)
             table.insert( self.m_vecMiniWheel, miniMachine)
             
             if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
             end

         end 

    end

    self.m_baseFreeSpinBar = util_createView("CodeOZSrc.OZFreespinBar")
    self.m_vecMiniWheelBg:findChild("FreeSpinBar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenOZMachine:updateGirlPos( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCount = selfdata.bonusCount
    if bonusCount then

        self.m_CollectMainView:initGirlPos(bonusCount )

    end
end

-- 断线重连 
function CodeGameScreenOZMachine:MachineRule_initGame(  )

    self:initJackpotData( )

    self:updateGirlPos( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        local fsTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
        if fsTimes then
            self.m_baseFreeSpinBar:updateTimes(fsTimes)
        end
        
        
        self.m_gameBg:findChild("bg"):setVisible(false)

        self:ShowMiniReels( )

        self:updateLittleReelsCoinsAndDiamonds()

        local actStates =  self:getFsAddActStates( )
        if self.m_FsAllWinStates ~= actStates then
            self.m_FsAllWinStates = actStates
            self:initMiniReelAct( actStates )
        end
        
    end
    
    
    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenOZMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "OZ"  
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenOZMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_OZ_10"

    elseif symbolType == self.SYMBOL_FixBonus then
        return "Socre_OZ_Bonus"
    elseif symbolType == self.SYMBOL_Mini_Scatter then
        return "Socre_OZ_Scatter_Mini"
    end


    return nil
end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenOZMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FixBonus,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Mini_Scatter,count =  2}
    


    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

--
--单列滚动停止回调
--
function CodeGameScreenOZMachine:slotOneReelDown(reelCol)  
      
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


    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if  self:getGameSpinStage() ~= QUICK_RUN  then
                local reelDownSoundId =  gLobalSoundManager:playSound(self.m_reelDownSound)
                table.insert(self.m_reelDownSoundIdList,reelDownSoundId)
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if  self:getGameSpinStage() ~= QUICK_RUN  then
            local reelDownSoundId =  gLobalSoundManager:playSound(self.m_reelDownSound)
            table.insert(self.m_reelDownSoundIdList,reelDownSoundId)
        end
    end



    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    

    local dealFunc = function(  )

        if self.m_reelRunSoundTag ~= -1 then
            --停止长滚音效
            gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
            self.m_reelRunSoundTag = -1
        end

        local rundi = self.m_RunDi[5]
        if rundi:isVisible() then
            rundi:runCsbAction("stop",false,function(  )
                rundi:setVisible(false)
            end)
            
        end

        local rundi_col1 = self.m_RunDi[1]
        if rundi_col1:isVisible() then
            rundi_col1:runCsbAction("stop",false,function(  )
                rundi_col1:setVisible(false)
            end)
            
        end

        local rundi_col3 = self.m_RunDi[3]
        if rundi_col3:isVisible() then
            rundi_col3:runCsbAction("stop",false,function(  )
                rundi_col3:setVisible(false)
            end)
            
        end

        local runTop_col1 = self.m_RunTop[1]
        if runTop_col1:isVisible() then
            runTop_col1:runCsbAction("stop",false,function(  )
                runTop_col1:setVisible(false)
            end)
            
        end

        local runTop_col3 = self.m_RunTop[3]
        if runTop_col3:isVisible() then
            runTop_col3:runCsbAction("stop",false,function(  )
                runTop_col3:setVisible(false)
            end)
            
        end

        local runTop_col5 = self.m_RunTop[5]
        if runTop_col5 then
            runTop_col5:runCsbAction("stop",false,function(  )
                runTop_col5:setVisible(false)
            end)
            
        end
    end

       
    if reelCol == 5 then
        dealFunc()
    elseif reelCol == 3 then
        local isLongRun = self.m_reelRunInfo[4].m_bReelLongRun
        if not isLongRun then
            dealFunc()
        end
       
    end
    

end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenOZMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenOZMachine:levelFreeSpinOverChangeEffect()

    
    
end
---------------------------------------------------------------------------

function CodeGameScreenOZMachine:showChooseView( fsTimes,func )

    self:showGuoChang( function(  )
        self.m_baseFreeSpinBar:setVisible(true)
        self.m_baseFreeSpinBar:updateTimes(fsTimes)
        self:ShowMiniReels( )

        self.m_gameBg:findChild("bg"):setVisible(false)

    end,function(  )

        
        local chooseView = util_createView("CodeOZSrc.OZChooseView",self)
        chooseView:setEndCall(function(  )

                if func then
                    func()
                end

                chooseView:removeFromParent()
                chooseView = nil

        end)
        chooseView:findChild("BitmapFontLabel_1"):setString(fsTimes)
        gLobalViewManager:showUI(chooseView)
    end )

    
    
   
end

---
-- 显示free spin
function CodeGameScreenOZMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.isInBonus = true

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

-- 触发freespin时调用
function CodeGameScreenOZMachine:showFreeSpinView(effectData)

    
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            self:showChooseView(self.m_iFreeSpinTimes ,function()

                    local miniReelsId =  self.m_chooseIndex + 1
                    local miniReels = self.m_vecMiniWheel[miniReelsId]
                    miniReels:runCsbAction("actionframe")
                    miniReels.m_ReelsWinBar:runCsbAction("actionframe")

                    performWithDelay(self,function(  )
                        self.m_FsAllWinStates = 0
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()    
                    end,1)
                       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

function CodeGameScreenOZMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 50)
    local viewCsbName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local winAll = selfdata.winAll
    if winAll and winAll == 1 then
        viewCsbName = "FreeSpinOver_1"
        gLobalSoundManager:playSound("OZSounds/music_OZ_Normal_Open_view_sound.mp3")
    else
        gLobalSoundManager:playSound("OZSounds/music_OZ_Open_view_sound.mp3")
    end
    
    return self:showDialog(viewCsbName,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

-- 触发freespin结束时调用
function CodeGameScreenOZMachine:showFreeSpinOverView()
    
    
    gLobalSoundManager:playSound("OZSounds/music_OZ_FS_End.mp3")

    performWithDelay(self,function(  )
        local waitTime = 0

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local winAll = selfdata.winAll

        local freeData = self.m_runSpinResultData.p_fsExtraData or {}
        local setWinCoins = freeData.setWinCoins
        local select = freeData.select -- 0开始
        local bonusCounts = freeData.bonusCounts

        
        if winAll and winAll == 1 then
                
            if setWinCoins then

                local showWinCoins = globalData.slotRunData.lastWinCoin 
                
                for k=1,#setWinCoins do
                    local miniReelsCoins = tonumber(setWinCoins[k])
                    showWinCoins = showWinCoins - miniReelsCoins
                end

                for i=1,#setWinCoins do

                    waitTime = 1 * ( i - 1)

                    local miniReelsCoins = tonumber(setWinCoins[i])
                

                    performWithDelay(self,function(  )

                        gLobalSoundManager:playSound("OZSounds/music_OZ_FS_Over_win_light.mp3")

                        local littleReel =  self.m_vecMiniWheel[i]
                        littleReel:runCsbAction("actionframe2")

                        self:playCoinWinEffectUI()


                        showWinCoins = showWinCoins + miniReelsCoins

                        self.m_bottomUI:updateWinCount(util_formatCoins(showWinCoins,50))
                    end,1 * ( i - 1))
                end
        
                
            end
            
        else
            gLobalSoundManager:playSound("OZSounds/music_OZ_FS_Over_win_light.mp3")
            waitTime = 1

            if select then
                local littleReel =  self.m_vecMiniWheel[select + 1]
                littleReel:runCsbAction("actionframe2")
            end
            
            self:playCoinWinEffectUI()
            
            self.m_bottomUI:updateWinCount(util_formatCoins(globalData.slotRunData.lastWinCoin,50)) 
        end

        performWithDelay(self,function(  )


            local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
                local view = self:showFreeSpinOver( strCoins, 
                    self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{globalData.slotRunData.lastWinCoin,false,false})
        
                        self:showOverGuoChang( function(  )
                            
                            self.m_gameBg:findChild("bg"):setVisible(true)
        
                            self:HideMiniReels( )      
        
                            for i=1,#self.m_vecMiniWheel do
                                local minireel = self.m_vecMiniWheel[i]
        
                                minireel:runCsbAction("green")
                                minireel.m_ReelsWinBar:runCsbAction("green")
        
                                minireel:updateWinBarScore( 0 )
                                minireel:updateWinBarDiamondsNum( 0)
        
                                minireel:stopMiniScatterAct( )
                            
                            end
        
                        end,function(  )
        
                            self.m_FsAllWinStates = 0
                            -- 调用此函数才是把当前游戏置为freespin结束状态
                            self:triggerFreeSpinOverCallFun()
                        end )
        
                end)
                local node=view:findChild("m_lb_coins")
                view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

            

            
        end,waitTime + 1.5)
    end,1.5)

   

end


---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenOZMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )

    self.m_reelDownSoundIdList = {}

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        -- 处理快速点spin的情况 直接刷新
        local freeData = self.m_runSpinResultData.p_fsExtraData or {}
        local setWinCoins = freeData.setWinCoins

        if setWinCoins then
            self.m_lastSetWinCoins = setWinCoins 

            for i=1,#self.m_vecMiniWheel do
                local minireel = self.m_vecMiniWheel[i]
    
                minireel:stopWinBarScoreAct( tonumber(setWinCoins[i]) )
            end
        end
        
    else
        self.m_lastSetWinCoins = {0,0,0,0}
    end

    if self.m_winFSSoundsId then
        gLobalSoundManager:stopAudio(self.m_winFSSoundsId)
        self.m_winFSSoundsId = nil
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_outLines = false

    self.isInBonus = false
    self.m_wheelOver = false
    self.m_BonusChestOver = false

    self.m_FsDownTimes = 0
    self.m_addDiamondsEffectTimes = 0

    self:setMaxMusicBGVolume( )
    self:removeSoundHandler( )


    return false -- 用作延时点击spin调用
end




function CodeGameScreenOZMachine:enterGamePlayMusic(  )

    
    if not self.isInBonus then

        gLobalSoundManager:playSound("OZSounds/music_OZ_enter.mp3")

        scheduler.performWithDelayGlobal(function (  )
            
                self:resetMusicBg()
                self:setMinMusicBGVolume( )

            
        end,3.5,self:getModuleName())
    end
        

end

function CodeGameScreenOZMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenOZMachine:addObservers()
	BaseFastMachine.addObservers(self)

end

function CodeGameScreenOZMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 -- 

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenOZMachine:MachineRule_network_InterveneSymbolMap()

end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenOZMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据
    
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenOZMachine:addSelfEffect()

       
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:checkAllMiniReelsIsAddDiamonds( ) then
            --收集钻石
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
        end
    else

        if self:getBonusNodeList( ) then
            --收集Bonus
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_BONUS
        end

    end
    

    
 

end
-- 设置自定义游戏事件
function CodeGameScreenOZMachine:restSelfEffect( selfEffect )
    for i = 1, #self.m_gameEffects , 1 do

        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and effectData.p_selfEffectType == selfEffect then
            
            effectData.p_isPlay = true
            self:playGameEffect()

            break
        end
        
    end
    
end

function CodeGameScreenOZMachine:playEndAddDiamondsEffect(index )
    self.m_addDiamondsEffectTimes = self.m_addDiamondsEffectTimes + 1

    if index then
        
        self:updateOneLittleReelsDiamonds( index )
    end
    

    if self.m_addDiamondsEffectTimes == 4 then

        
        self:updateLittleReelsDiamonds( )


        local actStates =  self:getFsAddActStates( )

        if self.m_FsAllWinStates ~= actStates then
            self.m_FsAllWinStates = actStates
            self:updateMiniReelAct( actStates )
        end

        self:restSelfEffect( self.EFFECT_TYPE_COLLECT )

        -- 恢复各个轮盘的等待状态
        for i=1,#self.m_vecMiniWheel do
            local minireel = self.m_vecMiniWheel[i]
            minireel:restSelfEffect( self.EFFECT_TYPE_COLLECT )
        end

        self.m_addDiamondsEffectTimes = 0
    end
end

function CodeGameScreenOZMachine:isInArray( array , value)
    
    for k,v in pairs(array) do
        if value == v then
            return true
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenOZMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then

        local isAddDiamonds,addReelsId = self:checkAllMiniReelsIsAddDiamonds()
        if isAddDiamonds then

            for i=1,#addReelsId do
                local reelsIndex = addReelsId[i]
                local miniReel = self.m_vecMiniWheel[reelsIndex]

                performWithDelay(self,function(  )
                    miniReel:runAddDiamondsEffect(  )

                end,1*(i -1))
            end

            performWithDelay(self,function(  )
                for i=1,#self.m_vecMiniWheel do

                    if not self:isInArray( addReelsId , i) then

                        local miniReel = self.m_vecMiniWheel[i]
                        miniReel:runAddDiamondsEffect(  )

                    end
                
                end
            end,1 * #addReelsId )
            

        end

    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_BONUS then 


        local bonusList =  self:getBonusNodeList( )
        local node = bonusList[#bonusList]
        node:runAnim("actionframe")

        

        performWithDelay(self,function(  )

            gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_symbol_collect.mp3")
            
            local time = 0.5 
            local startNode = node
            local endNode = self.m_CollectMainView.m_OZCollectGirl
            local csbName = "Socre_OZ_shouji_tuowei"
            local flyNode = self:runFlyWildAct(startNode,endNode,csbName,time,function(  )
                
        
                    gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_symbol_Down.mp3")

                    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                    local bonusCount = selfdata.bonusCount
                    
                    performWithDelay(self,function(  )
                        if bonusCount > 0 and bonusCount < 6 then
                            gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_Collect_" .. bonusCount .. ".mp3")
                        end
                    end,0.5)

                    if bonusCount then
                        self.m_CollectMainView:RunGirlAct(bonusCount,function(  )

                            if bonusCount == 5 then
                                gLobalSoundManager:playSound("OZSounds/music_OZ_Girl_down_bonus_trigger.mp3")
                            end
                            

                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end )
                    end
                
                
            end)
        end,0.66)

        

        

        


            
    end

    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenOZMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenOZMachine:ShowMiniReels( )

    for i=1,#self.m_vecMiniWheel do
        local reels = self.m_vecMiniWheel[i]
        reels:clearFrames_Fun()
        reels:clearWinLineEffect()
    end

    self.m_vecMiniWheelBg:setVisible(true)

    self:clearFrames_Fun()
    self:clearWinLineEffect()
    self:findChild("reel"):setVisible(false)
end

function CodeGameScreenOZMachine:HideMiniReels( )

    for i=1,#self.m_vecMiniWheel do
        local reels = self.m_vecMiniWheel[i]
        reels:clearFrames_Fun()
        reels:clearWinLineEffect()
    end
    self.m_vecMiniWheelBg:setVisible(false)
    
    
    self:clearFrames_Fun()
    self:clearWinLineEffect()
    self:findChild("reel"):setVisible(true)

end


function CodeGameScreenOZMachine:beginReel()
    

    if  self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:resetReelDataAfterReel()
        
        for i=1,#self.m_vecMiniWheel do
            local reels = self.m_vecMiniWheel[i]
            reels:beginMiniReel()
        end
    else

        BaseFastMachine.beginReel(self)
        
    end

end

function CodeGameScreenOZMachine:playEffectNotifyNextSpinCall( )

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
    self:getCurrSpinMode() == FREE_SPIN_MODE) then
        
        local delayTime = 1.5
       
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            
            local lines = {} 

            for i=1,#self.m_vecMiniWheel do
                local reels = self.m_vecMiniWheel[i]
                local miniReelslines = reels:getResultLines()

                if miniReelslines then
                    for i=1,#miniReelslines do
                        table.insert( lines,miniReelslines[i] )
                    end
                end
                
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
    
end

---
-- 处理spin 返回结果
function CodeGameScreenOZMachine:spinResultCallFun(param)

    self.m_chooseIndex = nil
    
    BaseFastMachine.spinResultCallFun(self,param)

    self:updateJackpotCoins( )
    
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if param[1] == true then
            local spinData = param[2]
            if spinData.result then
                if spinData.result.selfData then
                    if spinData.result.selfData.sets then
                        local datas = spinData.result.selfData.sets
                    
                        for i=1,#self.m_vecMiniWheel do
                            local miniReelsData = datas[i]
                            miniReelsData.bet = 0
                            miniReelsData.payLineCount = 0
                            local reels = self.m_vecMiniWheel[i]
                            reels:netWorkCallFun(miniReelsData)
                        end
    
                    end
                end
            end
        end
    end
end

function CodeGameScreenOZMachine:requestSpinResult()
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
                        data=self.m_collectDataList,jackpot = self.m_jackpotList,clickPos = self:getChooseIndex( )}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenOZMachine:getChooseIndex( )

    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and  freeSpinsLeftCount > 0 then
            if freeSpinsTotalCount == freeSpinsLeftCount then
                return self.m_chooseIndex
            end
        end
    end
   
end

function CodeGameScreenOZMachine:updateJackpotCoins( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectBetCoins = selfdata.collectBetCoins or {Mini = 0,Major = 0,Minor = 0}

    for k,v in pairs(collectBetCoins) do
        local coins = v
        local labname = k .. "_coins" 
        local lab =  self.m_JPtMainView:findChild(labname)
        if lab then

            local startValue = self.m_JPtMainView.m_coinsList[k]
            local addValue = (coins - startValue) /15
            util_jumpNum(lab,startValue,coins,addValue,0.02,{50},nil,nil,function(  )

                self.m_JPtMainView:updateLabelSize({label=lab,sx=1,sy=1},208)

            end)

            self.m_JPtMainView.m_coinsList[k] = coins

            -- lab:setString(util_formatCoins(coins,50) )
            -- self.m_JPtMainView:updateLabelSize({label=lab,sx=1,sy=1},208)
        end
    end
end

function CodeGameScreenOZMachine:initJackpotData( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectBetCoins = selfdata.collectBetCoins or {Mini = 0,Major = 0,Minor = 0}
    local jackpotCounts = selfdata.jackpotCounts or { Mini = 0,Major = 0,Minor = 0}

    

    for k,v in pairs(collectBetCoins) do
        local coins = v
        local labname = k .. "_coins" 
        local lab =  self.m_JPtMainView:findChild(labname)
        if lab then
            
            self.m_JPtMainView.m_coinsList[k] = coins
            lab:setString(util_formatCoins(coins,50) )
            self.m_JPtMainView:updateLabelSize({label=lab,sx=1,sy=1},208)

        end
    end

    for k,v in pairs(jackpotCounts) do
        local num = v
        for i=1,3 do

            local nodename = k .. "_node_" .. i .. "_Diamond" 
            local diamond =  self.m_JPtMainView[nodename]
            if diamond then
                diamond:setVisible(false)
                if num ~= 3 then
                    if num >= i then
                        diamond:setVisible(true)             
                    end 
                end
            end
        end
    end

end


function CodeGameScreenOZMachine:slotReelDown( )
    BaseFastMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
      
end

--freespin下主轮调用父类停止函数
function CodeGameScreenOZMachine:slotReelDownInFS( )
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

function CodeGameScreenOZMachine:playEffectNotifyChangeSpinStatus( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then



    else
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
    end
end

function CodeGameScreenOZMachine:setFsAllRunDown(times )
    self.m_FsDownTimes = self.m_FsDownTimes + times

    if self.m_FsDownTimes == 4 then

        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) and self:getCurrSpinMode() == FREE_SPIN_MODE then
            print("啥也不做")
        else
            BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
        end

        
        self.m_FsDownTimes = 0
    end
end

function CodeGameScreenOZMachine:quicklyStopReel(colIndex)

    
    for i=1,#self.m_reelDownSoundIdList do
        local soundId = self.m_reelDownSoundIdList[i]
        gLobalSoundManager:stopAudio(soundId)
    end

    self.m_reelDownSoundIdList = {}

    gLobalSoundManager:playSound(self.m_reelDownSound)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

    else
        BaseFastMachine.quicklyStopReel(self, colIndex)
    end
    
end

function CodeGameScreenOZMachine:checkAllMiniReelsIsAddDiamonds( )

    local actMiniReelsId = {}
    local isAdd = false
    -- 有一个轮子 需要收集钻石那么四个小轮子一起等
    for i=1,#self.m_vecMiniWheel do
        local minireel = self.m_vecMiniWheel[i]
        if minireel:checkIsAddDiamonds( ) then
            
            table.insert( actMiniReelsId, i )

            isAdd = true
        end
    end

    if isAdd then
        return isAdd,actMiniReelsId
    end

end

function CodeGameScreenOZMachine:updateLittleReelsCoinsAndDiamonds( )
    local freeData = self.m_runSpinResultData.p_fsExtraData or {}
    local select = freeData.select -- 0开始
    local bonusCounts = freeData.bonusCounts
    local setWinCoins = freeData.setWinCoins

    for i=1,#self.m_vecMiniWheel do
        local minireel = self.m_vecMiniWheel[i]
        if setWinCoins then
            minireel:updateWinBarScore( tonumber(setWinCoins[i]) )
        end

        if bonusCounts then
            minireel:updateWinBarDiamondsNum( bonusCounts[i])
        end

        if select then
            if i == (select + 1) then
                minireel:runCsbAction("golden")
                minireel.m_ReelsWinBar:runCsbAction("golden")
            end
        end
        
        
    end
end

function CodeGameScreenOZMachine:updateOneLittleReelsDiamonds( index )
    local freeData = self.m_runSpinResultData.p_fsExtraData or {}
    local select = freeData.select -- 0开始
    local bonusCounts = freeData.bonusCounts
    local setWinCoins = freeData.setWinCoins

    for i=1,#self.m_vecMiniWheel do
        local minireel = self.m_vecMiniWheel[i]

        if i == index then
            if bonusCounts then
                minireel:updateWinBarDiamondsNum( bonusCounts[i])
            end
        end
        
        
    end
end

function CodeGameScreenOZMachine:updateLittleReelsDiamonds( )
    local freeData = self.m_runSpinResultData.p_fsExtraData or {}
    local select = freeData.select -- 0开始
    local bonusCounts = freeData.bonusCounts
    local setWinCoins = freeData.setWinCoins

    for i=1,#self.m_vecMiniWheel do
        local minireel = self.m_vecMiniWheel[i]


        if bonusCounts then
            minireel:updateWinBarDiamondsNum( bonusCounts[i])
        end
        
    end
end

function CodeGameScreenOZMachine:updateLittleReelsCoins( miniReelId )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeData = self.m_runSpinResultData.p_fsExtraData or {}
        local select = freeData.select -- 0开始
        local bonusCounts = freeData.bonusCounts
        local setWinCoins = freeData.setWinCoins

        local isUpdateCoins = false

        for i=1,#self.m_vecMiniWheel do
            if i == miniReelId then
                local minireel = self.m_vecMiniWheel[i]
            
                local newCoins = setWinCoins[i]
                local oldCoins = self.m_lastSetWinCoins[i]
    
                if newCoins ~= oldCoins then
                    isUpdateCoins = true
                    minireel:updateWinBarScore( tonumber(newCoins),tonumber(oldCoins) )
                end
            end
        end

        
        if isUpdateCoins  then

            if not self.m_winFSSoundsId then
                self.m_winFSSoundsId = globalMachineController:playBgmAndResume("OZSounds/music_OZ_last_win_low.mp3",3,0.4,1)
                performWithDelay(self,function()
                    self.m_winFSSoundsId = nil
                end,3)
            end
           

        end



    end

    
end

function CodeGameScreenOZMachine:getBonusNodeList( )
    local collectList = nil

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_FixBonus then
                    if not collectList then
                        collectList = {}
                    end
                    collectList[#collectList + 1] = node
                end
            end
        end
    end
    if collectList and #collectList > 0 then

        return collectList

    end
end


---
-- 显示bonus 触发的小游戏
function CodeGameScreenOZMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

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

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then

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
function CodeGameScreenOZMachine:showBonusGameView(effectData)

    local showBonusCallFunc = function(  )
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local icons = selfdata.icons

        if icons then
            

            self:showChestBonusView( function(  )
                self.m_CollectMainView.m_OZCollectDoor:runCsbAction("close")
                self.m_CollectMainView.m_OZCollectDoorLight:runCsbAction("close")
                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
            end )
        else
            self:showWheelView( function(  )
                self.m_CollectMainView.m_OZCollectDoor:runCsbAction("close")
                self.m_CollectMainView.m_OZCollectDoorLight:runCsbAction("close")
                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
            end)
        end
    end


    
    if not effectData.p_isOutLine then

        local bonusCoins = self.m_runSpinResultData.p_bonusWinCoins
        if bonusCoins > 0 then
            self.m_bottomUI:updateWinCount(util_formatCoins(bonusCoins,50))
        end

        gLobalSoundManager:playSound("OZSounds/music_OZ_Open_Door.mp3")


        local waitTimes  = 2
        self.m_CollectMainView.m_OZCollectDoor:runCsbAction("open")
        self.m_CollectMainView.m_OZCollectDoorLight:runCsbAction("open")

        performWithDelay(self,function(  )
            showBonusCallFunc()
            if self.m_WheelBgView then
                self.m_WheelBgView:setVisible(false)
            end
            
            performWithDelay(self,function(  )
                self:showGuoChang( function(  )
                    self.m_bottomUI:updateWinCount("")
                    if self.m_WheelBgView then
                        
                        self.m_WheelBgView:setVisible(true)
                        self.m_WheelBgView:bgWheelAct( )
                    end
                    
                    
                end )
            end,0)
            
        end,waitTimes)
        
    else
        
        self:findChild("reel"):setVisible(false)
        showBonusCallFunc()
        if self.m_WheelBgView then
            self.m_WheelBgView:bgWheelAct( )
        end
        
        
    end

    
end


function CodeGameScreenOZMachine:showWheelView( func )
    
    self:resetMusicBg(nil,"OZSounds/music_OZ_Wheel_bgm.mp3")
    
    self.m_WheelBgView = util_createView("CodeOZSrc.Wheel.OZWheelBgView",self)
    self:findChild("Wheel"):addChild(self.m_WheelBgView)
    self.m_WheelBgView:setPosition(-display.width/2,-display.height/2)
    self.m_WheelBgView:setOverCall(function(  )
        if func then
            func()
        end
    end)
end

function CodeGameScreenOZMachine:showChestBonusView( func ,isAct,isWait)


    self:resetMusicBg(nil,"OZSounds/music_OZ_Bonus_bgm.mp3")

    self.m_gameBg:findChild("bg_Baoxiang"):setVisible(true)

    self.m_ChestBonusView = util_createView("CodeOZSrc.BonusGame.OZBonusMainView",self,isAct,isWait)
    self:findChild("Chest"):addChild(self.m_ChestBonusView)
    self.m_ChestBonusView:setPosition(-display.width/2,-display.height/2)
    self.m_ChestBonusView:setEndCall(function(  )

        self.m_gameBg:findChild("bg_Baoxiang"):setVisible(false)

        

        if func then
            func()
        end
    end)

    
end

-- bonus游戏断线
function CodeGameScreenOZMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "OPEN" then
        local bsWinCoins = featureData.p_bonus.bsWinCoins
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(bsWinCoins))

        local featureDatas = spinData.p_features
        if not featureDatas then
            return
        end
        for i=1,#featureDatas do
            local featureId = featureDatas[i]

            if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                
                gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

                -- 添加bonus effect
                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_isOutLine = true
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

end

function CodeGameScreenOZMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end

---
--设置bonus scatter 层级
function CodeGameScreenOZMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_Mini_Scatter then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 1
    elseif symbolType == self.SYMBOL_FixBonus then
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

function CodeGameScreenOZMachine:getAngleByPos(p1,p2)  

    local p = {}  
    p.x = p2.x - p1.x  
    p.y = p2.y - p1.y  

    local r = math.atan2(p.y,p.x)*180/math.pi  
    print("夹角[-180 - 180]:",r)  
    return r  
end

function CodeGameScreenOZMachine:runFlyWildAct(startNode,endNode,csbName,flytime,func)

        -- 创建粒子
        local flyNode =  util_createAnimation( csbName ..".csb")
        self:findChild("root"):addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)

        local startPos = util_getConvertNodePos(startNode,flyNode)

        flyNode:setPosition(cc.p(startPos))

        local endPos = cc.p(util_getConvertNodePos(endNode,flyNode))

        local angle = self:getAngleByPos(startPos,endPos)
        flyNode:findChild("Node_1"):setRotation( - angle)

        local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
        flyNode:findChild("Node_1"):setScale(scaleSize / 581)

        flyNode:runCsbAction("animation0",false,function(  )

                if func then
                    func()
                end

                flyNode:stopAllActions()
                flyNode:removeFromParent()
        end)

        return flyNode

end

function CodeGameScreenOZMachine:showGuoChang( func1,func2 )

    gLobalSoundManager:playSound("OZSounds/music_OZ_LongJuanFeng.mp3")

    self.m_GuoChangView:findChild("Node_12"):setVisible(false)
    self.m_GuoChangView:findChild("Node_12_0"):setVisible(true)

    self.m_GuoChangView:setVisible(true)
    self.m_GuoChangView:runCsbAction("animation0",false,function(  )
        self.m_GuoChangView:setVisible(false)
        if func2 then
            func2()
        end
    end)
    performWithDelay(self,function(  )

        self:findChild("reel"):setVisible(false)

        if func1 then
            func1()
        end
    end,1.5)
end

function CodeGameScreenOZMachine:showOverGuoChang( func1,func2 )

    gLobalSoundManager:playSound("OZSounds/music_OZ_LongJuanFeng.mp3")

    self.m_GuoChangView:findChild("Node_12"):setVisible(true)
    self.m_GuoChangView:findChild("Node_12_0"):setVisible(false)
    

    self.m_GuoChangView:setVisible(true)
    self.m_GuoChangView:runCsbAction("animation0",false,function(  )
        self.m_GuoChangView:setVisible(false)
        if func2 then
            func2()
        end
    end)
    performWithDelay(self,function(  )

        self:findChild("reel"):setVisible(true)
        if func1 then
            func1()
        end
    end,1.5)
end


---
--添加金边
function CodeGameScreenOZMachine:creatReelRunAnimation(col)
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

    
    

    
    local rundi_col1 = self.m_RunDi[1]
    if rundi_col1 then
        if not rundi_col1:isVisible() then
            rundi_col1:runCsbAction("run")
            rundi_col1:setVisible(true)
        end
        
    end

    local runTop_col1 = self.m_RunTop[1]
    if runTop_col1 then
        if not runTop_col1:isVisible() then
            runTop_col1:runCsbAction("run",true)
            runTop_col1:setVisible(true)
        end
    end




    if col == 5 then
        local rundi = self.m_RunDi[5]
        if rundi then
            rundi:runCsbAction("run")
            rundi:setVisible(true)
        end  

        local runTop_col5 = self.m_RunTop[5]
        if runTop_col5 then
            runTop_col5:runCsbAction("run",true)
            runTop_col5:setVisible(true)
        end
    end
    

    if col == 3 then
        local rundi_col3 = self.m_RunDi[3]
        if rundi_col3 then
            rundi_col3:runCsbAction("run")
            rundi_col3:setVisible(true)
        end
        
        local runTop_col3 = self.m_RunTop[3]
        if runTop_col3 then
            runTop_col3:runCsbAction("run",true)
            runTop_col3:setVisible(true)
        end
    end

    
    
    
    -- reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenOZMachine:getReelHeight()
    return 578
end

function CodeGameScreenOZMachine:getReelWidth()
    return 1070
end

function CodeGameScreenOZMachine:scaleMainLayer()
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

        -- local ratio = display.height/display.width
        -- if  ratio >= 768/1024 then
        --     mainScale = 0.95
        -- elseif ratio < 768/1024 and ratio >= 640/960 then
        --    mainScale = 0.95 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        -- end
        if display.width < 1370 then
            mainScale = mainScale * 0.9
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 8)
    end

end


---
-- 显示free spin over 动画
function CodeGameScreenOZMachine:showEffect_FreeSpinOver()

    local waitTimes = 1

    local lines = {} 
    for i=1,#self.m_vecMiniWheel do
        local reels = self.m_vecMiniWheel[i]
        local miniReelslines = reels:getResultLines()

        if miniReelslines then
            for i=1,#miniReelslines do
                table.insert( lines,miniReelslines[i] )
            end
        end
        
    end

    if lines ~= nil and #lines > 0 then
        waitTimes =  1.5
    end

    performWithDelay(self,function(  )
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
    end,waitTimes)

    
    return true
end

---
-- 进入关卡
--
function CodeGameScreenOZMachine:enterLevel()
    
    self.m_outLines = true

    BaseFastMachine.enterLevel(self)
    
    self:createGameTip( )
end

function CodeGameScreenOZMachine:checkShouldCreateTip( )

    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
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

    elseif #featureDatas > 1 then

        if featureDatas[2] == 5 then
            if self.m_initFeatureData then

                if self.m_initFeatureData.p_bonus and
                     self.m_initFeatureData.p_bonus.status and 
                        self.m_initFeatureData.p_bonus.status == "CLOSED" then
                    
                            return false
                else
                    return true 
                end

            else
                return true 
            end

        else
            return true 
        end
        
    end

    return false
end



function CodeGameScreenOZMachine:createGameTip( )

    if self:checkShouldCreateTip() then
        return
    end


    self:findChild("OZ_jackPoTip_2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 500)
    self:findChild("OZ_jackPoTip_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 500)

    local OZ_jackPoTip_1 =  util_createAnimation("OZ_jackPoTip_1.csb") 
    self:findChild("OZ_jackPoTip_1"):addChild(OZ_jackPoTip_1) 
    OZ_jackPoTip_1:runCsbAction("open")

    local OZ_jackPoTip_2 =  util_createAnimation("OZ_jackPoTip_2.csb") 
    self:findChild("OZ_jackPoTip_2"):addChild(OZ_jackPoTip_2) 
    OZ_jackPoTip_2:runCsbAction("open")


    local OZGameTipClickView =  util_createView("CodeOZSrc.OZGameTipClickView")
    self:addChild(OZGameTipClickView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    performWithDelay(self,function(  )

        OZGameTipClickView:setOverCallFunc( function(  )
     
            OZ_jackPoTip_1:runCsbAction("over",false,function(  )
                OZ_jackPoTip_1:removeFromParent()
            end)
            OZ_jackPoTip_2:runCsbAction("over",false,function(  )
                OZ_jackPoTip_2:removeFromParent()
            end)
    
        end)

        OZGameTipClickView:addClick(OZGameTipClickView:findChild("Panel_1"))
       
    end,0.5)
 
end

function CodeGameScreenOZMachine:initMiniReelAct( states )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeData = self.m_runSpinResultData.p_fsExtraData or {}
        local select = freeData.select -- 0开始
        local bonusCounts = freeData.bonusCounts
        local setWinCoins = freeData.setWinCoins
    
        local miniReelId = select + 1

        for i=1,#self.m_vecMiniWheel do
            if i ~= miniReelId then
                local minireel = self.m_vecMiniWheel[i]
            
                if states == 1 then
                    minireel:runCsbAction("golden")
                else
                    minireel:runCsbAction("green")
                end
                
            end
        end
    end
end

function CodeGameScreenOZMachine:updateMiniReelAct( states )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeData = self.m_runSpinResultData.p_fsExtraData or {}
        local select = freeData.select -- 0开始
        local bonusCounts = freeData.bonusCounts
        local setWinCoins = freeData.setWinCoins
    
        local miniReelId = select + 1

        for i=1,#self.m_vecMiniWheel do
            if i ~= miniReelId then
                local minireel = self.m_vecMiniWheel[i]
            
                if states == 1 then
                    minireel:runCsbAction("actionframe")
                else
                    minireel:runCsbAction("actionframe1")
                end
                
            end
        end
    end
end

function CodeGameScreenOZMachine:getFsAddActStates( )

    local states = 1

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeData = self.m_runSpinResultData.p_fsExtraData or {}
        local select = freeData.select -- 0开始
        local bonusCounts = freeData.bonusCounts

        local bonusSelectCount = bonusCounts[select + 1]

        for i=1,#bonusCounts do
            if i  ~= (select + 1) then
                local bonusCount = bonusCounts[i]
                if bonusCount > bonusSelectCount then
                    states = 0
                end
            end
        end
    end
    
    return states
    
end


---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenOZMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
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

function CodeGameScreenOZMachine:checkIsAllOneType( winLines ,symbolType)

    for i=1,#winLines do
        local lineData = winLines[i]
        
        if lineData.p_iconPos and #lineData.p_iconPos > 0 then

            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolTypeNum = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                    if symbolTypeNum ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if symbolTypeNum ~= symbolType then
                        
                            return false
                        end
                    end
                    
                end

            end
           
        end 

    end

    return true
end

function CodeGameScreenOZMachine:checkhaveOneSymol( symbolType )


    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local winLines = self.m_runSpinResultData.p_winLines
        if winLines and #winLines > 0 then

            for i=1,#winLines do
                local lineData = winLines[i]
                
                if lineData.p_iconPos and #lineData.p_iconPos > 0 then
        
                    for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                        local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                        local checkEnd = false
                        for posIndex = 1 , #lineData.p_iconPos do
                            local pos = lineData.p_iconPos[posIndex] 
        
                            local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                            local colIndex = pos % self.m_iReelColumnNum + 1
        
                            local symbolTypeNum = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
        
                            if symbolTypeNum == symbolType then
                            
                                return true
                            end
        
                            
                        end
        
                    end
                   
                end 
        
            end

        end
    end

    

    return false
end


function CodeGameScreenOZMachine:getSpecialSoundId( )

    local soundId = nil

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local winLines = self.m_runSpinResultData.p_winLines
        if winLines and #winLines > 0 then

            if self:checkIsAllOneType( winLines ,0) then
                soundId = 0
            elseif self:checkIsAllOneType( winLines ,1) then
                soundId = 1
            elseif self:checkIsAllOneType( winLines ,2) then
                soundId = 2
            elseif self:checkIsAllOneType( winLines ,3) then
                soundId = 3
            end

        end
    end
    
    return soundId

end

function CodeGameScreenOZMachine:getBottomUINode( )
    return "CodeOZSrc.OZGameBottomNode"
end

--设置长滚信息
function CodeGameScreenOZMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false
    local firstColHaoScatter = false
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)
        else
            if addLens == true then
                if col == 4 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 12 ) 
                    self:setLastReelSymbolList() 
                elseif col == 5 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 10) 
                    self:setLastReelSymbolList() 
                end
                   
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

        if col == 1 then
            if scatterNum > 0 then
                firstColHaoScatter = true
            end
            
        end
        if firstColHaoScatter  then
            if col == 1 and not bRunLong then
                self.m_reelRunInfo[col]:setNextReelLongRun(true)
                bRunLong = true
                addLens = false
            
            elseif col == 3 and scatterNum < 2 then
                self.m_reelRunInfo[col]:setNextReelLongRun(false)
                bRunLong = false
                addLens = true
            end
        end
        

    end --end  for col=1,iColumn do

end


function CodeGameScreenOZMachine:createLocalAnimation( )
    local pos = cc.p(self.m_bottomUI.m_normalWinLabel:getPosition()) 
    
    self.m_EndActiom =  util_createAnimation("OZ_4rl_jiesuan.csb")
    self.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_EndActiom,9999999)
    self.m_EndActiom:setPosition(cc.p(pos.x - 8,pos.y))

    self.m_EndActiom:setVisible(false)
end

function CodeGameScreenOZMachine:getLongRunLen(col, index)

    local longRunTimes = {1.5,0.7,1.5,0.7,1.5,0.7}

    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if self:getInScatterShowCol(col) then 
            local reelCount = (longRunTimes[col] * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = self.m_reelRunInfo[col - 1]
            local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (longRunTimes[col] * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    end
    return len
end

function CodeGameScreenOZMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        self:resetMaskLayerNodes()
        callFun()
    end,40/30,self:getModuleName())
end

return CodeGameScreenOZMachine






