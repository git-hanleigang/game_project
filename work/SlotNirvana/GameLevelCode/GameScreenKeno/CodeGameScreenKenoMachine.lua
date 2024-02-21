---
-- island li
-- 2019年1月26日
-- CodeGameScreenKenoMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"
local CodeGameScreenKenoMachine = class("CodeGameScreenKenoMachine", BaseNewReelMachine)

CodeGameScreenKenoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenKenoMachine.SYMBOL_WILD2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE -- 自定义的小块类型
CodeGameScreenKenoMachine.EFFECT_SEND = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenKenoMachine.EFFECT_NEXT_SEND = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识


-- 构造函数
function CodeGameScreenKenoMachine:ctor()
    CodeGameScreenKenoMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_muji = {}
    self.m_bIsSelectCall = nil
    self.m_playedYuGao = false -- 是否播放预告
    self.m_collectNum = 0 --收集进度
    self.m_isDuanXian = false -- 是否是断线进来的
    self.m_newWild = {} --上次spin得到的wild
    self.m_newWildXiaoJi = {} --base下小鸡节点
    self.superFreeMoveWild = {}--保存superfree 第一次spin前小鸡位置
    self.superTrigger = false -- 触发super
    self.m_kenoIsPlayBigWin = false -- keno玩法是否播放大赢
    self.m_reelRunSound = "KenoSounds/sound_Keno_QuickHit_reel.mp3"--快滚音效
    self.m_isKeno = false -- 是否在keno玩法里
    --init
    self:initGame()
end

function CodeGameScreenKenoMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("KenoConfig.csv", "LevelKenoConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenKenoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Keno"  
end

function CodeGameScreenKenoMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 收集进度
    self.m_shouji = util_createAnimation("Keno_shouji.csb")
    self:findChild("Node_shouji"):addChild(self.m_shouji)

    self.m_shoujiZi = util_createAnimation("Keno_shouji_zi.csb")
    self.m_shouji:findChild("Node_Zi"):addChild(self.m_shoujiZi)
    self.m_shoujiZi:runCsbAction("idleframe",true)

    -- 说明tips
    self.m_shoujiTips = util_createAnimation("Keno_Tips.csb")
    self:findChild("Node_tips"):addChild(self.m_shoujiTips)
    self.m_shoujiTips:setVisible(false)
    self:addClick(self.m_shouji:findChild("Btn_tips"))

    -- 母鸡
    for i=1,10 do
        self.m_muji[i] = util_createAnimation("Keno_shouji_muji.csb")
        self.m_shouji:findChild("Node_"..i):addChild(self.m_muji[i])
        self.m_muji[i]:runCsbAction("idleframe",true)
    end

    --keno界面
    self.m_kenoGameView = util_createView("CodeKenoSrc.KenoBonusGameView",self)
    self:findChild("GameView"):addChild(self.m_kenoGameView)
    self.m_kenoGameView:setPosition(-display.width * 0.5, -display.height * 0.5)
    self.m_kenoGameView:setVisible(false)

    --棋盘压黑
    self.m_qipanMask = util_createAnimation("Keno_mask.csb")
    self:findChild("Node_mask"):addChild(self.m_qipanMask)
    self.m_qipanMask:setVisible(false)

    -- 过场
    self.m_GuoChang = util_spineCreate("Keno_guochang",true,true)            --过场
    self:addChild(self.m_GuoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 11)
    self.m_GuoChang:setPosition(display.width/2,display.height/2)
    self.m_GuoChang:setVisible(false)  

    -- 过场遮罩
    self.m_GuoChangDark = util_createAnimation("Keno_dark.csb")
    self:addChild(self.m_GuoChangDark,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
    self.m_GuoChangDark:setPosition(display.width/2,display.height/2)
    self.m_GuoChangDark:setVisible(false)  

    self:setKenoGameBg(1)

    -- 收集玩法的动画
    self.m_collect_action = cc.Node:create()
    self.m_collect_action:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("Node_1"):addChild(self.m_collect_action)

    --base下老母鸡
    self.m_baseLaoMuJi = util_spineCreate("Keno_Laobmuji",true,true)            
    self:findChild("Node_1"):addChild(self.m_baseLaoMuJi)
    -- self.m_baseLaoMuJi:setPosition(display.width/2,display.height/2)
    self.m_baseLaoMuJi:setVisible(false)  

    --麦子
    self.m_maizi = util_createAnimation("Keno_Wheat.csb")         
    self:findChild("Node_wheat"):addChild(self.m_maizi)

    -- 棋盘遮罩
    self.m_maskNodeTab = {}

    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local mask = self:findChild("sp_reel_" .. col .. "_dark")
        table.insert(self.m_maskNodeTab,mask)
        mask:setVisible(false)
    end
   
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
            if self.m_bIsBigWin then
                return 
            end
        end 

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 1
        local soundTime = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 2
        elseif winRate > 6 then
            soundIndex = 3
            soundTime = 2
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if winRate <= 1 then
                soundIndex = 11
                soundTime = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 22
                soundTime = 2
            elseif winRate > 3 then
                soundIndex = 33
                soundTime = 2
            end
        end

        local soundTime = soundTime
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "KenoSounds/sound_Keno_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenKenoMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self:findChild("Node_Freebar")
        self.m_baseFreeSpinBar =util_createView("CodeKenoSrc.KenoFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end
end

function CodeGameScreenKenoMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local kenoBgName = {"base", "free", "super"}
    local spineActionName = {"base_bg_idle", "free_bg_idle", "super_bg_idle"}

    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    for i=1,3 do
        local kenoBgSpine = util_spineCreate("GameScreenKenoBg", true, true)
        gameBg:findChild(kenoBgName[i]):addChild(kenoBgSpine)
        util_spinePlay(kenoBgSpine, spineActionName[i], true)
    end

    self.m_gameBg = gameBg
end

-- 滚动背景可见性
-- index当前背景 lastIndex 切换之后的背景 isSwitch 是否切换
function CodeGameScreenKenoMachine:setKenoGameBg(index, isSwitch, lastIndex)
    local kenoBgName = {"base", "free", "super"}
    for i=1,3 do
        self.m_gameBg:findChild(kenoBgName[i]):setVisible(false)
    end
    if isSwitch then
        self.m_gameBg:findChild(kenoBgName[index]):setVisible(true)
        self.m_gameBg:findChild(kenoBgName[index]):setZOrder(2)
        self.m_gameBg:findChild(kenoBgName[lastIndex]):setVisible(true)
        self.m_gameBg:findChild(kenoBgName[index]):setZOrder(1)
        self.m_gameBg:runCsbAction("switch"..index,false)
    else
        self.m_gameBg:findChild(kenoBgName[index]):setVisible(true)
        self.m_gameBg:runCsbAction("idleframe",false)
    end
end

-- 滚动背景可见性
function CodeGameScreenKenoMachine:setReelBg(index)
    self:findChild("reel_bg_base"):setVisible(false)
    self:findChild("reel_bg_free"):setVisible(false)
    self:findChild("reel_bg_super"):setVisible(false)
    if index == 1 then
        self:findChild("reel_bg_base"):setVisible(true)
    elseif index == 2 then
        self:findChild("reel_bg_free"):setVisible(true)
    elseif index == 3 then
        self:findChild("reel_bg_super"):setVisible(true)
    end
end

-- 设置收集进度
function CodeGameScreenKenoMachine:setCollectPregress( func)
    self.superTrigger = false
    if func == nil then
        for i=1,self.m_collectNum do
            self.m_muji[i]:runCsbAction("idleframe1",true)
        end
    else
        if self.m_isDuanXian then
            if func then
                func()
            end
        else
            self.m_collect_action:setVisible(true)
            -- 播放一次收集音效
            local isPlaySound = true
            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if isPlaySound then
                            gLobalSoundManager:playSound("KenoSounds/sound_Keno_shouji_fly.mp3")
                            isPlaySound = false
                        end
                        local startPos = util_convertToNodeSpace(symbolNode, self.m_collect_action)
                        local endPos = util_convertToNodeSpace(self.m_muji[self.m_collectNum], self.m_collect_action)
                        symbolNode:setLocalZOrder(symbolNode:getLocalZOrder()+iCol)
                        local egg = util_createAnimation("Keno_jindu_dan_fly.csb")
                        egg:setPosition(startPos)
                        self.m_collect_action:addChild(egg)
                        egg:runCsbAction("actionframe", false)

                        for index = 1, 2 do
                            if egg:findChild("Particle_"..index) then
                                egg:findChild("Particle_"..index):setDuration(700)
                                egg:findChild("Particle_"..index):setPositionType(0)
                                egg:findChild("Particle_"..index):resetSystem()
                            end
                        end

                        local seq = cc.Sequence:create({
                            cc.BezierTo:create(30/60,{cc.p(startPos.x-30, startPos.y), cc.p(startPos.x-30, endPos.y), endPos}),
                            cc.DelayTime:create(0.2),
                            cc.RemoveSelf:create(true)
                        })
                        egg:runAction(seq)
                    end
                end
            end

            self:waitWithDelay(0.5,function()
                if self.m_collectNum == 10 then
                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_shouji_baozha_man.mp3")
                else
                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_shouji_baozha.mp3")
                end
                self.m_muji[self.m_collectNum]:runCsbAction("actionframe",false,function(  )
                    self.m_muji[self.m_collectNum]:runCsbAction("idleframe1",true)
                    -- 触发super收集
                    if self.m_collectNum == 10 then
                        self.superTrigger = true
                        self.m_shouji:runCsbAction("actionframe",false)
                        self.m_shoujiZi:runCsbAction("actionframe",false,function()
                            self.m_shoujiZi:runCsbAction("idleframe1",false)
                            if func then
                                func()
                            end
                        end)
                    else
                        if func then
                            func()
                        end
                    end
                end)
            end)
        end
    end
end

-- 设置收集的母鸡idle动画一致
function CodeGameScreenKenoMachine:setShouJiMujiPlayIdle( )
    for i=1,self.m_collectNum do
        self.m_muji[i]:runCsbAction("idleframe1",true)
    end
end

function CodeGameScreenKenoMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound("KenoSounds/music_Keno_enter.mp3")

    end,0.4,self:getModuleName())
end

function CodeGameScreenKenoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenKenoMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenKenoMachine:addObservers()
    CodeGameScreenKenoMachine.super.addObservers(self)

end

function CodeGameScreenKenoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenKenoMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenKenoMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_WILD2  then 
        return "Socre_Keno_Wild2"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenKenoMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenKenoMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD2,count =  2}
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------
-- 断线重连 
function CodeGameScreenKenoMachine:MachineRule_initGame(  )
    self.m_isDuanXian = true

    local kenoData_introFinished = globalData.slotRunData.kenoData_introFinished
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    if selfMakeData.bonus and selfMakeData.bonus.status and selfMakeData.bonus.status == "OPEN" and not selfMakeData.bonus.extra.isSelect then
        if kenoData_introFinished then
            selfMakeData.bonus.extra.introFinished = kenoData_introFinished
        end
        self:showBeginKenoView()
        self.m_isKeno = true
    end

    -- free玩法断线 创建wild
    if self.m_bProduceSlots_InFreeSpin then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        self.m_newWild = fsExtraData.newWild or {}
        if fsExtraData and fsExtraData.moveWild and #fsExtraData.moveWild > 0 then
            for i,vPosNew in ipairs(fsExtraData.moveWild ) do
                local fixPos1 = self:getRowAndColByPos(vPosNew[2])
                local startWorldPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
                local startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)

                local newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
                newWild:setPosition(startPos)
                self.m_collect_action:addChild(newWild)
                newWild:setZOrder(vPosNew[2])
                newWild:setTag(vPosNew[2])
                newWild:runAnim("idleframe", true)
            end
            self.m_collect_action:setVisible(false)
        end
        if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount and 
            self.m_runSpinResultData.p_freeSpinsTotalCount > 0 then
                globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
                globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
                self.m_iOnceSpinLastWin = 0
                self:triggerFreeSpinCallFun()
                self:playGameEffect()
    
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Stop,false})
        end
    end
end

-- 开始keno玩法
function CodeGameScreenKenoMachine:showBeginKenoView( )
    -- 是否有引导
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    if selfMakeData.bonus and selfMakeData.bonus.extra and not selfMakeData.bonus.extra.introFinished then
        self:waitWithDelay(15/60,function()
            self.m_kenoGameView:beginShowGuide()
        end)
    end
    self:resetMusicBg(nil,"KenoSounds/Music_Keno_Keno_Bg.mp3")

    self.m_kenoGameView:setVisible(true)
    self.m_kenoGameView:updataKenoView(self)
    self.m_kenoGameView:runCsbAction("start",false,function(  )
        self.m_kenoGameView:runCsbAction("idle",true)
        -- 隐藏棋盘
        self:findChild("reel"):setVisible(false)
        self:findChild("Node_shouji"):setVisible(false)
        self:findChild("Node_Freebar"):setVisible(false)
        -- 隐藏下条目
        self.m_bottomUI:setVisible(false)
    end)
end
--
--单列滚动停止回调
--
function CodeGameScreenKenoMachine:slotOneReelDown(reelCol)    
    CodeGameScreenKenoMachine.super.slotOneReelDown(self,reelCol) 

    -- 棋盘滚动出来的wild要提层 播放idle
    for iRow = 1, self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self:isPlayTipAnima(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex,symbolNode) == true then
                symbolNode:runAnim("buling",false)
                local symbolNode = util_setSymbolToClipReel(self,symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                self:playScatterBonusSound(symbolNode)
            end
        end
    end
end

-- 过场
function CodeGameScreenKenoMachine:playChangeGuoChang(_func1, _func2)
    self.m_GuoChang:setVisible(true)  
    self.m_GuoChangDark:setVisible(true) 

    self:waitWithDelay(40/30,function(  )
        self.m_GuoChangDark:runCsbAction("over",false)
    end)

    self.m_GuoChangDark:runCsbAction("start",false,function(  )
        self.m_GuoChangDark:runCsbAction("idle",true)
    end)

    gLobalSoundManager:playSound("KenoSounds/sound_Keno_guochang.mp3")
    util_spinePlay(self.m_GuoChang, "guochang", false)
    util_spineEndCallFunc(self.m_GuoChang, "guochang", function()
    
        self.m_GuoChang:setVisible(false)  
        self.m_GuoChangDark:setVisible(false) 
        if _func2 then
            _func2()
        end
    end)
    self:waitWithDelay(25/30,function(  )
        if _func1 then
            _func1()
        end
    end)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenKenoMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    if self.m_runSpinResultData.p_selfMakeData.collectData.point < 10 then
        self:setKenoGameBg(1,true,2)
        self:setReelBg(2)
        self.m_baseFreeSpinBar:runCsbAction("free", false)
    else
        self:setKenoGameBg(1,true,3)
        self:setReelBg(3)
        self.m_baseFreeSpinBar:runCsbAction("super", false)
        self.m_bottomUI:showAverageBet()
    end
    -- 隐藏收集
    self.m_shouji:setVisible(false)
    -- 显示free条
    self:showFreeSpinBar()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenKenoMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    if self.m_runSpinResultData.p_selfMakeData.collectData.point ~= 0 then
        self:setKenoGameBg(2,true,1)
        self:setReelBg(1)
    else
        -- super返回
        self:setKenoGameBg(3,true,1)
        self:setReelBg(1)
        self.m_bottomUI:hideAverageBet()
        -- 重置进度
        self:resetShouJiMuJi()
    end
    
    self:setShouJiMujiPlayIdle()
    -- 显示收集
    self.m_shouji:setVisible(true)
    -- 隐藏free条
    self:hideFreeSpinBar()
end
---------------------------------------------------------------------------

-- 重置进度条
function CodeGameScreenKenoMachine:resetShouJiMuJi( )
    self.m_shouji:runCsbAction("idleframe",false)
    self.m_shoujiZi:runCsbAction("idleframe",true)
    self.m_collectNum = 0
    for i=1,10 do
        self.m_muji[i]:runCsbAction("idleframe",true)
    end
end
----------- FreeSpin相关

function CodeGameScreenKenoMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("KenoSounds/sound_Keno_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playChangeGuoChang(function(  )
                self.m_newWild = {}
                self.m_collect_action:removeAllChildren()
                self:levelFreeSpinOverChangeEffect()
            end,function()
                self:triggerFreeSpinOverCallFun()
            end)
    end)
    view:findChild("root"):setScale(self.m_machineRootScale)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},780)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenKenoMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )
    if self.m_kenoGameView:isVisible() then
        return true
    else 
        if self.m_scheduleId then
            self:showTipsOverView()
        end

        self.m_isDuanXian = false
        return false -- 用作延时点击spin调用
    end
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenKenoMachine:addSelfEffect()

end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenKenoMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_SEND then
        self:waitWithDelay(1,function()
            self.m_kenoIsPlayBigWin = false
            self.m_kenoGameView:checkBigWinEffect()
            -- 按钮不可点击
            self.m_kenoGameView:setBtnStatus(false)
            self.m_kenoGameView:sendData()

            effectData.p_isPlay = true
            self.m_gameEffects = {}
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_NEXT_SEND then
        -- 按钮不可点击
        self.m_kenoGameView:setBtnStatus(false)
        self.m_kenoGameView:sendData()

        effectData.p_isPlay = true
        self.m_gameEffects = {}
    end
    return true
end

--下一次send的自定义事件
function CodeGameScreenKenoMachine:nextKenoSendEffect( )
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_NEXT_SEND

    self:playGameEffect()
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenKenoMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    if self.m_playedYuGao then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            -- 这个关卡 scatter只会出现在2 3 4 列，所以第二个scatter图标是在第三列
            -- 从第四列开始恢复
            if iCol > 3 then
                local preRunLen = reelRunData.initInfo.reelRunLen
                reelRunData:setReelRunLen(preRunLen)
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end
        end
    end
end

function CodeGameScreenKenoMachine:playEffectNotifyNextSpinCall( )
    if self.m_kenoGameView:isVisible() then
        return
    end 
    CodeGameScreenKenoMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

--保存时间
function CodeGameScreenKenoMachine:saveTime()
    self.m_curTime = socket.gettime()
end

--读取时间间隔
function CodeGameScreenKenoMachine:getSpanTime()
    local spanTime = (socket.gettime() - self.m_curTime)
    self.m_curTime = nil
    return spanTime
end

function CodeGameScreenKenoMachine:beginReel( )
    self.m_playedYuGao = false

    CodeGameScreenKenoMachine.super.beginReel(self)

    if self.m_bProduceSlots_InFreeSpin then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if #self.m_newWild > 0 or (fsExtraData.moveWild and #fsExtraData.moveWild > 0) then
            -- 棋盘遮罩
            self:beginReelShowMask()
            self.m_collect_action:setVisible(true)
            self:saveTime()

            -- FG里 《Wild蛋裂开冒出小鸡动画》和《Wild小鸡站起来》同时出现时，
            -- 只播《Wild小鸡站起来》
            if #self.m_newWild > 0 and #fsExtraData.moveWild > 0 then
                gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_free_old.mp3")
            else
                if #self.m_newWild > 0 then
                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_free_new.mp3")
                elseif #fsExtraData.moveWild > 0 then
                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_free_old.mp3")
                end
            end

            for i,vPosNew in ipairs(self.m_newWild ) do
                local fixPos1 = self:getRowAndColByPos(vPosNew)
                local startWorldPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
                local startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)

                local newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
                newWild:setPosition(startPos)
                self.m_collect_action:addChild(newWild)
                newWild:setZOrder(vPosNew)
                newWild:setTag(vPosNew)

                newWild:runAnim("switch4", false, function()
                    newWild:runAnim("idleframe3", true)
                end)
            end

            for i,vPosOld in ipairs(fsExtraData.moveWild ) do
                local newWild = self.m_collect_action:getChildByTag(vPosOld[2])
                local fixPos1 = self:getRowAndColByPos(vPosOld[2])
                local startWorldPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
                local startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)
    
                if newWild == nil then
                    newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
                    newWild:setPosition(startPos)
                    self.m_collect_action:addChild(newWild)
                    newWild:setZOrder(vPosOld[2])
                    newWild:setTag(vPosOld[2])
                end

                newWild:runAnim("switch2", false, function()
                    newWild:runAnim("idleframe3", true)
                end)
            end
            self:waitWithDelay(21/30,function()
                gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_free_jiaobu.mp3")
            end)
        end
        -- super free
        if self.superFreeMoveWild and #self.superFreeMoveWild > 0 then
            self:beginReelShowMask()
            self.m_collect_action:setVisible(true)
            self:saveTime()
            self:superFreeWildAct(self.superFreeMoveWild)
        end
    end
end

function CodeGameScreenKenoMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self.m_bProduceSlots_InFreeSpin then
        -- free 随机  wild 在棋盘上创建新的 wild
        local selfMakeData = self.m_runSpinResultData.p_fsExtraData
        if selfMakeData.moveWild and #selfMakeData.moveWild > 0 then
            for i,vPos in ipairs(selfMakeData.moveWild) do
                local fixPos = self:getRowAndColByPos(vPos[2])
                local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                self:changeOneSymbol(symbolNode)
            end
        end
        self.m_collect_action:setVisible(false)
    else
        -- base下随机wild
        local selfMakeData = self.m_runSpinResultData.p_selfMakeData
        if selfMakeData.addWild and #selfMakeData.addWild > 0 then
            for i,vPos in ipairs(selfMakeData.addWild) do
                local fixPos = self:getRowAndColByPos(vPos)
                local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                self:changeOneSymbol(symbolNode)
            end
            for i,vNode in ipairs(self.m_newWildXiaoJi) do
                if not tolua.isnull(vNode) then
                    vNode:removeFromParent()
                end
            end
            self.m_newWildXiaoJi = {}
        end
    end
    CodeGameScreenKenoMachine.super.slotReelDown(self)
end

--换一个小块
function CodeGameScreenKenoMachine:changeOneSymbol(symbolNode)
    local ccbName = self:getSymbolCCBNameByType(self, self.SYMBOL_WILD2)
    symbolNode:changeCCBByName(ccbName, self.SYMBOL_WILD2)
    symbolNode:changeSymbolImageByName(ccbName)
    symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - symbolNode.p_rowIndex)
    symbolNode:runAnim("idleframe",true)

    local symbolNode = util_setSymbolToClipReel(self,symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_WILD,symbolNode.p_cloumnIndex)
end

function CodeGameScreenKenoMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

function CodeGameScreenKenoMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- 延时函数
function CodeGameScreenKenoMachine:waitWithDelay(time, endFunc)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenKenoMachine:showBonusGameView(effectData)
     -- 界面选择回调
     local function chooseCallBack(index)
        self:sendData(index)
        self.m_bIsSelectCall = true
        self.m_iSelectID = index
        self.m_gameEffect = effectData
    end

    if self.m_runSpinResultData.p_selfMakeData then
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.bonus.extra.freeTimes
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_iKenoTimes = self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonusTimes
        end
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.collectData then
            self.m_collectNum = self.m_runSpinResultData.p_selfMakeData.collectData.point
        end

        self:setCollectPregress(function()
            self:showFreatureChooseView(chooseCallBack)
        end)
    end
    effectData.p_isPlay = true
end

-- 二选一界面
function CodeGameScreenKenoMachine:showFreatureChooseView(func)
	local view = util_createView("CodeKenoSrc.KenoFeatureChooseView")
   
    self:waitWithDelay(0.8,function()
        self.m_bottomUI:checkClearWinLabel()
    end)
    view:initViewData(self, func, function()
        self:levelFreeSpinEffectChange()
    end)
    gLobalViewManager:showUI(view)
end

-- 点击二选一界面 发送消息
function CodeGameScreenKenoMachine:sendData(index)
    local newData = {}
    newData.select = index
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = newData}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--spin结果
function CodeGameScreenKenoMachine:spinResultCallFun(param)
    CodeGameScreenKenoMachine.super.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        if self.m_iSelectID == 0 then   --  keno feature
            if param[1] == true then
                if param[2] then
                    self:operaSpinResultData(param)
                    self:showBeginKenoView()
                    self.m_isKeno = true
                end
            end
        else
            if param[1] == true then
                if param[2] and param[2].result then
                    local result = param[2].result
                    if result.freespin.extra and result.freespin.extra.moveWild and #result.freespin.extra.moveWild > 0 then
                        self.superFreeMoveWild = result.freespin.extra.moveWild
                    end
                    globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
                    globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
                    self.m_iOnceSpinLastWin = 0
                    self:triggerFreeSpinCallFun()

                    self.m_gameEffect.p_isPlay = true
                    self:playGameEffect()

                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                    {SpinBtn_Type.BtnType_Stop,false})
                end
            end
        end
    end
    self.m_bIsSelectCall = false
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenKenoMachine:initGameStatusData(gameData)
    CodeGameScreenKenoMachine.super.initGameStatusData(self,gameData)
    -- 收集进度
    self.m_collectNum = 0

    if gameData.feature then --2选1断线重连之后的数据
        self.m_runSpinResultData.p_features = gameData.feature.features
        self.m_runSpinResultData.p_selfMakeData = gameData.feature.selfData
        self.m_runSpinResultData.p_freeSpinsLeftCount = gameData.feature.freespin.freeSpinsLeftCount
        self.m_runSpinResultData.p_freeSpinsTotalCount = gameData.feature.freespin.freeSpinsTotalCount
        if gameData.feature.freespin.extra and gameData.feature.freespin.extra.moveWild and #gameData.feature.freespin.extra.moveWild > 0 then
            self.superFreeMoveWild = gameData.feature.freespin.extra.moveWild
        end

        self.m_initSpinData = self.m_runSpinResultData
        if gameData.feature and gameData.feature.selfData and gameData.feature.selfData.collectData then
            if gameData.feature.selfData.collectData.point < 10 then
                self.m_collectNum = gameData.feature.selfData.collectData.point
            end
        end
    else
        if gameData.spin and gameData.spin.selfData and gameData.spin.selfData.collectData then
            if gameData.spin.selfData.collectData.point < 10 then
                self.m_collectNum = gameData.spin.selfData.collectData.point
            end
        end
    end
    
    self:setCollectPregress()
end

function CodeGameScreenKenoMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    if self.m_bProduceSlots_InFreeSpin then
        self:freeSpinWildChange(function(  )
            self:produceSlots()

            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end)
        
    else
        local features = self.m_runSpinResultData.p_features or {}
        if #features >= 2 and features[2] > 0 then
            -- c出现预告动画概率30%
            local yuGaoId = math.random(1, 100)
            if yuGaoId <= 30  then
                self.m_playedYuGao = true
                self:playYuGaoAct(function()
                    self:produceSlots()
        
                    local isWaitOpera = self:checkWaitOperaNetWorkData()
                    if isWaitOpera == true then
                        return
                    end
                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData() -- end
                end)
            else
                self:produceSlots()
    
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
            
        else
            self:baseSpinWildChange(function(  )
                self:produceSlots()
    
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
    
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end)
        end

    end
end

-- 从小鸡队伍里随机几个跳
function CodeGameScreenKenoMachine:xiaojiRandom(totalNum, needNum)
    local selectNumId = {}
    local cheakRandomFun = function()
        while #selectNumId < needNum do 
            local istrue = false
            local num = math.random( 1,totalNum )
            if #selectNumId ~= nil then
                for i = 1 ,#selectNumId do
                    if selectNumId[i] == num then
                        istrue = true
                    end
                end
            end
            if istrue == false then
                table.insert( selectNumId, num )
            end
        end
    end

    cheakRandomFun()
    return selectNumId
end

--superfree 第一次spin小鸡动画
function CodeGameScreenKenoMachine:superFreeWildAct(addWild, _func)
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local startPos1 = cc.p(-display.width/2-100, -display.height/2 + uiBH + 50)
    local startPos2 = cc.p(display.width/2+100, -display.height/2 + uiBH + 50)

    -- 跳的小鸡
    local newWildNum = #addWild
    --创建小鸡跟着跑
    for eggIndex = 1, newWildNum do
        local newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
        local startWorldPos = self:findChild("Node_1"):convertToWorldSpace(startPos1)
        local startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)
        if eggIndex > 2 then
            startWorldPos = self:findChild("Node_1"):convertToWorldSpace(startPos2)
            startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)
        end
        
        newWild:setPosition(startPos)
        self.m_collect_action:addChild(newWild)
        
        table.insert(self.m_newWildXiaoJi, newWild)
        newWild:setVisible(false)

        -- 每只小鸡的时间间隔
        self:waitWithDelay(0.2*(eggIndex-1), function()
            newWild:setVisible(true)
            local fixPos = self:getRowAndColByPos(addWild[eggIndex][1])
            local startPosBegin = cc.p(self.m_newWildXiaoJi[eggIndex]:getPosition())
            local endWorldPos = self:getNodePosByColAndRow( fixPos.iX, fixPos.iY)
            local endPosTiao = self.m_collect_action:convertToNodeSpace(endWorldPos)

            local move = cc.BezierTo:create(17/30,{cc.p(startPosBegin.x, endPosTiao.y+200), cc.p(endPosTiao.x, endPosTiao.y+200), endPosTiao})
            local call = cc.CallFunc:create(function ()
                if endPosTiao.x < startPosBegin.x then
                    self.m_newWildXiaoJi[eggIndex]:setScaleX(1)
                end
                self.m_newWildXiaoJi[eggIndex]:runAnim("switch3", false, function()
                    self.m_newWildXiaoJi[eggIndex]:runAnim("idleframe", true)
                end)

                self.m_newWildXiaoJi[eggIndex]:setTag(addWild[eggIndex][1])
                self.m_newWildXiaoJi[eggIndex]:setZOrder(addWild[eggIndex][1])

                if eggIndex == #addWild then
                    if _func then
                        _func()
                    end
                end
            end)
            local seq = cc.Sequence:create(move,call)
            if endPosTiao.x < startPosBegin.x then
                self.m_newWildXiaoJi[eggIndex]:setScaleX(-1)
            end
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_base_ji_fly.mp3")
            self.m_newWildXiaoJi[eggIndex]:runAnim("actionframe5", false)
            self.m_newWildXiaoJi[eggIndex]:runAction(seq)
        end)
    end
end

-- base
function CodeGameScreenKenoMachine:baseWildLaoMuJi(addWild)
    local distanceTotal = display.width + 200
    local speed = 392 -- (display.width + 200)/4 -- 392.5
    local timeTotal = distanceTotal/speed
    
    -- 每只小鸡的距离间隔
    local xiaojiDistance = 118 

    -- 小鸡加速时间
    local speedUpTime = xiaojiDistance/speed*1.5

    self.m_baseLaoMuJi:setVisible(true)
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local pos = cc.p(self.m_bottomUI:findChild("node_bar"):getPosition())
    local startPosworld = self.m_bottomUI:findChild("node_bar"):getParent():convertToWorldSpace(cc.p(-display.width/2-100,pos.y + uiBH/2 + 20))
    local endworldPos = self.m_bottomUI:findChild("node_bar"):getParent():convertToWorldSpace(cc.p(display.width/2+100,pos.y + uiBH/2 + 20))

    local startPos = self:findChild("Node_1"):convertToNodeSpace(cc.p(startPosworld))
    local endPos = self:findChild("Node_1"):convertToNodeSpace(cc.p(endworldPos))
    self.m_baseLaoMuJi:setPosition(cc.p(startPos.x, startPos.y+60))
    util_spinePlay(self.m_baseLaoMuJi, "actionframe", true)

    gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_base.mp3")

    --老母鸡跑
    local move = cc.MoveTo:create(timeTotal, endPos)
    local call = cc.CallFunc:create(function ()
        self.m_baseLaoMuJi:setVisible(false)
    end)
    local seq = cc.Sequence:create(move,call)
    self.m_baseLaoMuJi:runAction(seq)

    -- 创建的小鸡要比 跳的小鸡多
    -- 3, +2
    -- 4+2
    -- 5+1
    -- 6+1
    -- 7+0
    local newWildNum = 5
    if #addWild >= 4 then
        newWildNum = 6
    end
    if #addWild >= 6 then
        newWildNum = 7
    end
    local randomId = self:xiaojiRandom(newWildNum, #addWild)
    table.sort(randomId,function(a,b)
        return a < b
    end)

    -- 需要加速的小鸡ID
    local speedUpNode = {}
    for i=1,newWildNum do
        local isHave = false
        for j,v in ipairs(randomId) do
            if i == v then
                isHave = true
            end
        end
        if not isHave then
            table.insert(speedUpNode, i)
        end
    end

    --创建小鸡跟着老母鸡跑
    for i=1,newWildNum do
        local newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
        newWild:setPosition(startPos)
        self:findChild("Node_1"):addChild(newWild)
        
        table.insert(self.m_newWildXiaoJi, newWild)
        newWild:setVisible(false)

        -- xiaojiDistance/speed 每只小鸡的时间间隔
        self:waitWithDelay(xiaojiDistance/speed*(2/3)+xiaojiDistance/speed*i, function()
            newWild:setVisible(true)
            newWild:runAnim("idleframe4", true)
            local move = cc.MoveTo:create(timeTotal,endPos)
            local call = cc.CallFunc:create(function ()
                newWild:removeFromParent()
            end)
            local seq = cc.Sequence:create(move,call)
            newWild:runAction(seq)
        end)
    end

    -- 小鸡加速函数
    local xiaojiSpeedUpFunc = function (_node, _endPos)
        local move = cc.MoveTo:create(speedUpTime, _endPos)
        local call = cc.CallFunc:create(function ()
            -- 加速结束之后 恢复原来速度
            local startPosNew = cc.p(_node:getPosition())
            _node:stopAllActions()
            local move1 = cc.MoveTo:create((endPos.x-startPosNew.x)/speed, endPos)
            local call1 = cc.CallFunc:create(function ()
                _node:removeFromParent()
            end)
            local seq1 = cc.Sequence:create(move1,call1)
            _node:runAction(seq1)
        end)
        local seq = cc.Sequence:create(move,call)
        _node:runAction(seq)
    end

    -- 小鸡跳
    local waitTime = xiaojiDistance/speed + xiaojiDistance/speed*(2/3) + timeTotal/2
    self:waitWithDelay(waitTime, function()
        for i,vPos in ipairs(addWild) do
            self:waitWithDelay(xiaojiDistance/speed/2*(randomId[i]-1)+0.01, function()
                local fixPos = self:getRowAndColByPos(vPos)
                local startPos = cc.p(self.m_newWildXiaoJi[randomId[i]]:getPosition())
                local endWorldPos = self:getNodePosByColAndRow( fixPos.iX, fixPos.iY)
                local endPosTiao = self:findChild("Node_1"):convertToNodeSpace(endWorldPos)
                self.m_newWildXiaoJi[randomId[i]]:stopAllActions()
                
                local move = cc.BezierTo:create(16/30,{cc.p(startPos.x, endPosTiao.y+150), cc.p(endPosTiao.x, endPosTiao.y+150), endPosTiao})
                local call = cc.CallFunc:create(function ()
                    if endPosTiao.x < startPos.x then
                        self.m_newWildXiaoJi[randomId[i]]:setScaleX(1)
                    end
                    self.m_newWildXiaoJi[randomId[i]]:runAnim("switch3", false, function()
                        self.m_newWildXiaoJi[randomId[i]]:runAnim("idleframe", true)
                    end)
                end)
                local seq = cc.Sequence:create(move,call)
                if endPosTiao.x < startPos.x then
                    self.m_newWildXiaoJi[randomId[i]]:setScaleX(-1)
                end
                gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_base_ji_fly.mp3")
                self.m_newWildXiaoJi[randomId[i]]:runAnim("actionframe3", false)
                self.m_newWildXiaoJi[randomId[i]]:runAction(seq)

                if i == #addWild then
                    -- 小鸡加速
                    for i,vId in ipairs(speedUpNode) do
                        -- 只有第1 ， 2只小鸡 不需要加速
                        if #speedUpNode == 2 and speedUpNode[1] == 1 and speedUpNode[2] == 2 then
                            break
                        end
                        -- 小鸡ID不为1才需要加速
                        if vId ~= 1 then
                            -- 加速的小鸡 只有两中情况 1只加速 和 2只加速
                            local _startPos = cc.p(self.m_newWildXiaoJi[vId]:getPosition())
                            self.m_newWildXiaoJi[vId]:stopAllActions()

                            -- 小鸡需要加速的距离
                            local distanceX = (speedUpTime+xiaojiDistance/speed*(vId-i)) * speed
                            local _endPos = cc.p(_startPos.x + distanceX, _startPos.y)
                            xiaojiSpeedUpFunc(self.m_newWildXiaoJi[vId], _endPos)
                        end
                    end
                end
            end)
        end
    end)
end

-- base下 随机wild
function CodeGameScreenKenoMachine:baseSpinWildChange(_func)
    
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    if selfMakeData.addWild and #selfMakeData.addWild > 0 then

        self:beginReelShowMask()

        local waitTime = 0.6 * 1 + 0.2 + 4
        if #selfMakeData.addWild == 3 then
            waitTime = 0.6 * 2 + 0.2 + 4
        elseif #selfMakeData.addWild == 6 then
            waitTime = 0.2 + 4
        end
        self:baseWildLaoMuJi(selfMakeData.addWild)
        self:waitWithDelay(waitTime, function()
            if _func then
                _func()
            end
        end)
    else
        if _func then
            _func()
        end
    end
end

-- free下 随机wild
function CodeGameScreenKenoMachine:freeSpinWildChange(_func)
    local selfMakeData = self.m_runSpinResultData.p_fsExtraData
    -- super free 第一次不在此处播放动画
    if self.superFreeMoveWild and #self.superFreeMoveWild > 0 then
        self.superFreeMoveWild = {}
        self.m_newWild = selfMakeData.newWild or {}

        if _func then
            _func()
        end
        
        return
    end
    -- 判断跑的小鸡里面的 上次spin得到的蛋
    local isNewWild = function(pos)
        for i,vPos in ipairs(self.m_newWild) do
            if pos == vPos then
                return true
            end
        end
        return false
    end

    -- 小鸡移动]
    local moveWildFunc = function(chicken, startPos, endPos, tag)
        local move = cc.MoveTo:create(60/60,endPos)
        local call = cc.CallFunc:create(function ()
            if endPos.x < startPos.x then
                chicken:setScaleX(1)
            end
            chicken:setZOrder(tag)
            chicken:runAnim("switch3", false, function()
                chicken:runAnim("idleframe", true)
            end)
            chicken:setTag(tag)
        end)
        local seq = cc.Sequence:create(move,call)
        if endPos.x < startPos.x then
            chicken:setScaleX(-1)
        end
        chicken:runAction(seq)

    end

    local waitTimeSuper = 0
    if self.superTrigger and (self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount - 1) then
        local timeTotal = 1.6
        if not self.m_curTime then 
            waitTimeSuper = timeTotal
        else
            waitTimeSuper = (timeTotal*1000 - self:getSpanTime())/1000
        end
    end

    self:waitWithDelay(waitTimeSuper,function()
        if selfMakeData.moveWild and #selfMakeData.moveWild > 0 then
            local moveWildNew = {}
            local moveWildOld = {}
            -- 跑的鸡分为两部分 一部分是上次spin得到的蛋 另一部分是之前得到的半破壳的鸡
            for i,vPos in ipairs(selfMakeData.moveWild) do
                if isNewWild(vPos[1]) then
                    table.insert(moveWildNew, vPos)
                else
                    table.insert(moveWildOld, vPos)
                end
            end
            -- 计算时间差
            local waitTime = 0
            if not self.m_curTime then
                waitTime = 41/30
            else
                waitTime = (41/30*1000 - self:getSpanTime())/1000
            end
            if self.superTrigger and (self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount - 1) then
                waitTime = 0
            end
    
            if waitTime < 0 then
                waitTime = 0
            end
            -- 蛋跑起来的
            for i,vPosNew in ipairs(moveWildNew) do
                local newWild = self.m_collect_action:getChildByTag(vPosNew[1])
                local fixPos1 = self:getRowAndColByPos(vPosNew[1])
                local fixPos2 = self:getRowAndColByPos(vPosNew[2])
    
                local startWorldPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
                local startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)
                local endWorldPos = self:getNodePosByColAndRow( fixPos2.iX, fixPos2.iY)
                local endPos = self.m_collect_action:convertToNodeSpace(endWorldPos)
    
                if newWild == nil then
                    newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
                    newWild:setPosition(startPos)
                    self.m_collect_action:addChild(newWild)
                    newWild:setZOrder(vPosNew[1])
                    newWild:setTag(vPosNew[1])
                end
    
                self:waitWithDelay(waitTime,function()
                    moveWildFunc(newWild, startPos, endPos, vPosNew[2])
                end)
            end
    
            -- 不是蛋跑起来的
            for i,vPosOld in ipairs(moveWildOld) do
                local newWild = self.m_collect_action:getChildByTag(vPosOld[1])
                local fixPos1 = self:getRowAndColByPos(vPosOld[1])
                local fixPos2 = self:getRowAndColByPos(vPosOld[2])
    
                local startWorldPos =  self:getNodePosByColAndRow( fixPos1.iX, fixPos1.iY)
                local startPos = self.m_collect_action:convertToNodeSpace(startWorldPos)
                local endWorldPos = self:getNodePosByColAndRow( fixPos2.iX, fixPos2.iY)
                local endPos = self.m_collect_action:convertToNodeSpace(endWorldPos)
    
                if newWild == nil then
                    newWild = self:getSlotNodeBySymbolType(self.SYMBOL_WILD2)
                    newWild:setPosition(startPos)
                    self.m_collect_action:addChild(newWild)
                    newWild:setZOrder(vPosOld[1])
                    newWild:setTag(vPosOld[1])
                end
    
                self:waitWithDelay(waitTime,function()
                    moveWildFunc(newWild, startPos, endPos, vPosOld[2])
                end)
            end
            self:waitWithDelay(waitTime + 1,function()
                if _func then
                    _func()
                end
            end)

            -- 小鸡跳到最高点开始往下坐的时候 是12帧，这个时候播放音效
            self:waitWithDelay(waitTime + 1 + 12/30,function()
                if #moveWildNew > 0 or #moveWildOld > 0 then
                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_wild_free_move.mp3")
                end
            end)
        else
            if _func then
                _func()
            end
        end
        self.m_newWild = selfMakeData.newWild or {}
    end)
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
-- isKeno表示是否是玩法过程中的大赢
function CodeGameScreenKenoMachine:checkFeatureOverTriggerBigWin(winAmonut, feature, isKeno)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end
    for i = 1, #self.m_gameEffects do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == feature and feature == GameEffect.EFFECT_BONUS then
            effectData.p_isPlay = true
        end
    end

    if winEffect ~= nil then
        if isKeno then
            self.m_kenoIsPlayBigWin = true
        end

        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
        
        -- 大赢之后添加自定义事件
        if isKeno then 
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_SEND
        end
    end
    if feature == GameEffect.EFFECT_BONUS then
        self:playGameEffect()
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenKenoMachine:specialSymbolActionTreatment( node)
    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --修改小块层级
        local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
        local linePos = {}
        linePos[#linePos + 1] = {iX = symbolNode.p_rowIndex, iY = symbolNode.p_cloumnIndex}
        symbolNode:setLinePos(linePos)
        symbolNode:runAnim("buling",false)
    end
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenKenoMachine:showBonusAndScatterLineTip(lineValue,callFun)

    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode==nil then
            slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]
                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then--这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            slotNode:runAnim("actionframe")
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenKenoMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

--播放中奖预告
function CodeGameScreenKenoMachine:playYuGaoAct(func)

    gLobalSoundManager:playSound("KenoSounds/sound_Keno_playYuGaoAct.mp3") 
    self.m_GuoChang:setVisible(true)
    self.m_qipanMask:setVisible(true)

    self.m_qipanMask:runCsbAction("start",false,function()
        self.m_qipanMask:runCsbAction("idle",false)
    end) 
    util_spinePlay(self.m_GuoChang,"actionframe")

    util_spineEndCallFunc(self.m_GuoChang,"actionframe",function ()
        self.m_GuoChang:setVisible(false)
        if func then
            func()
        end
    end)
    -- 43帧之后 棋盘遮罩开始消失
    self:waitWithDelay(43/30,function()
        self.m_qipanMask:runCsbAction("over",false,function()
            self.m_qipanMask:setVisible(false)
        end)
    end)
end

function CodeGameScreenKenoMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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
            for checkIndex = 1, #self.m_lineSlotNodes do
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
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode == nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode == nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end
                if slotNode==nil then
                    slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex = 1, #specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end
end

--轮盘滚动显示遮罩
function CodeGameScreenKenoMachine:beginReelShowMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            maskNode:setOpacity(0)
            maskNode:runAction(cc.FadeTo:create(0.5,150))
        end
    end
end
--轮盘停止隐藏遮罩
function CodeGameScreenKenoMachine:reelStopHideMask(actionTime, col)
    local maskNode = self.m_maskNodeTab[col]
    local fadeAct = cc.FadeTo:create(actionTime,0)
    local func = cc.CallFunc:create(function ()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct,func))
end

--滚轴停止回弹
function CodeGameScreenKenoMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()
        local slotParentBig = parentData.slotParentBig 
        if slotParentBig then
            slotParentBig:stopAllActions()
        end
        self:slotOneReelDown(parentData.cloumnIndex)
        local speedActionTable = nil
        local addTime = nil
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        if self.m_isNewReelQuickStop then
            slotParent:setPositionY(quickStopY)
            if slotParentBig then
                slotParentBig:setPositionY(quickStopY)
            end
            speedActionTable = {}
            speedActionTable[1], addTime = self:MachineRule_BackAction(slotParent, parentData)
        else
            speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
        end
        if slotParentBig then
            local seq = cc.Sequence:create(speedActionTable)
            slotParentBig:runAction(seq:clone())
        end
        local tipSlotNoes = nil
        local nodeParent = parentData.slotParent
        local nodes = nodeParent:getChildren()
        if slotParentBig then
            local nodesBig = slotParentBig:getChildren()
            for i=1,#nodesBig do
                nodes[#nodes+1]=nodesBig[i]
            end
        end

        -- 播放配置信号的落地音效
        self:playSymbolBulingSound(nodes)
        -- 播放配置信号的落地动效
        self:playSymbolBulingAnim(nodes, speedActionTable)

        --添加提示节点
        tipSlotNoes = self:addReelDownTipNode(nodes)
 
        if tipSlotNoes ~= nil then
            local nodeParent = parentData.slotParent
            for i = 1, #tipSlotNoes do
                --播放提示动画
                self:playReelDownTipNode(tipSlotNoes[i])
            end -- end for
        end

        self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

        local actionFinishCallFunc = cc.CallFunc:create(
        function()
            parentData.isResActionDone = true
            if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                self:newQuickStopReel(self.m_quickStopReelIndex)
            end
            self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
        end)

        
        speedActionTable[#speedActionTable + 1] = actionFinishCallFunc
        slotParent:runAction(cc.Sequence:create(speedActionTable))

        if self.m_maskNodeTab[parentData.cloumnIndex]:isVisible() then
            self:reelStopHideMask(0.1, parentData.cloumnIndex)
        end
    end
    return 0.1
end

function CodeGameScreenKenoMachine:getClipParentChildShowOrder(slotNode)
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or slotNode.p_symbolType == self.SYMBOL_WILD2 then
        return REEL_SYMBOL_ORDER.REEL_ORDER_3 - slotNode.p_rowIndex
    end
    return REEL_SYMBOL_ORDER.REEL_ORDER_3
end

function CodeGameScreenKenoMachine:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    self:postFreeSpinOverTriggerBigWIn(_coins)
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    -- self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenKenoMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    if self.superTrigger then
        return self:showDialog("SuperFreeSpinOver", ownerlist, func)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

-- 适配
function CodeGameScreenKenoMachine:scaleMainLayer()
    CodeGameScreenKenoMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.75
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        -- 
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.87 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.90 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

-- 点击函数
function CodeGameScreenKenoMachine:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Btn_tips" then
        if self.m_shoujiTips:isVisible() then
            self:showTipsOverView()
        else
            if self.getGameSpinStage() == IDLE then
                self:showTipsOpenView()
            end
        end
    end
end

--打开tips
function CodeGameScreenKenoMachine:showTipsOpenView( )
    self.m_shoujiTips:setVisible(true)
    self.m_shoujiTips:runCsbAction("show",false,function()
        self.m_shoujiTips:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:showTipsOverView()
        end, 4)
    end)
end

--关闭tips
function CodeGameScreenKenoMachine:showTipsOverView( )
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    self.m_shoujiTips:runCsbAction("over",false,function()
        self.m_shoujiTips:setVisible(false)
    end)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenKenoMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "KenoSounds/sound_Keno_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenKenoMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k,_slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)
    
                    --回弹
                    local newSpeedActionTable = {}
                    for i=1,#speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end
    
                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end
            
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                _slotNode:runAnim(symbolCfg[2], true, function()
                    self:symbolBulingEndCallBack(_slotNode)
                end)
            end
        end
    end
end

-- 重置当前背景音乐名称
function CodeGameScreenKenoMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        if self.m_isKeno then
        else
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    end
end

return CodeGameScreenKenoMachine






