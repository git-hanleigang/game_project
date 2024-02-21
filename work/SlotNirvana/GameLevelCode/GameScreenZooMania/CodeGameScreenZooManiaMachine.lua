---
-- island li
-- 2019年1月26日
-- CodeGameScreenZooManiaMachine.lua
-- 
-- 玩法：
-- 

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenZooManiaMachine = class("CodeGameScreenZooManiaMachine", BaseNewReelMachine)

CodeGameScreenZooManiaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenZooManiaMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 自定义的小块类型
CodeGameScreenZooManiaMachine.EFFECT_COLLOCTION  =   GameEffect.EFFECT_BONUS - 1     --收集

-- 构造函数
function CodeGameScreenZooManiaMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_BonusNum = 0
    self.m_reelRunAnimaBonus = {}
    self.m_reelRunAnimaBGBonus = {}
    self.m_clipBonus = {}--存储提高层级的bonus图标
    self.m_isAddFreeOver = false -- 是否需要自己手动添加freeover弹板
    self.m_serverWinCoins = 0

    --init
    self:initGame()
end

function CodeGameScreenZooManiaMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ZooManiaConfig.csv", "LevelZooManiaConfig.lua")
end  
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenZooManiaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ZooMania"  
end

function CodeGameScreenZooManiaMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self.m_gameBg:runCsbAction("normal",true)
    
    self.m_gameBgBaseCao = util_spineCreate("ZooMania_CaoCong1", true, true) 
    self.m_gameBg:findChild("caocong1"):addChild(self.m_gameBgBaseCao)
    util_spinePlay(self.m_gameBgBaseCao,"actionframe",true)
    self.m_gameBgBaseCao:setVisible(true)

    self.m_gameBgFreeCao = util_spineCreate("ZooMania_caocong2", true, true) 
    self.m_gameBg:findChild("caocong2"):addChild(self.m_gameBgFreeCao)
    self.m_gameBgFreeCao:setVisible(false)

    self:initFreeSpinBar() -- FreeSpinbar
    
    self.m_BonusGameChoose = util_createView("CodeZooManiaSrc.ZooManiaBonusGameChooseView",self)
    self:findChild("GameView"):addChild(self.m_BonusGameChoose)
    self.m_BonusGameChoose:setVisible(false)
    self.m_BonusGameChoose:setScale(0.83)

    self.m_RunDi = {}
    for i = 1, 5 do
        self:createReelEffectBonus(i)
        self:createReelEffectBGBonus(i)
    end

    self.m_BonusGuoChang = util_spineCreate("ZooMania_Bonus_guochang", true, true) 
    self:findChild("guochang"):addChild(self.m_BonusGuoChang,99999)
    self.m_BonusGuoChang:setVisible(false)

    self.m_BonusGuoChangMask = util_createAnimation("ZooMania/BonusStart_mask.csb")
    self:findChild("guochang"):addChild(self.m_BonusGuoChangMask,99997)
    self.m_BonusGuoChangMask:setVisible(false)

    self.m_BonusGuoChangBaoZha = util_createAnimation("ZooMania_guochang.csb")
    self:findChild("guochang"):addChild(self.m_BonusGuoChangBaoZha,99998)
    self.m_BonusGuoChangBaoZha:setVisible(false)

    self:findChild("reel_base"):setVisible(true)
    self:findChild("reel_free"):setVisible(false)
    self:findChild("Zoo_reekuang_guang_1"):setVisible(false)

    self:findChild("Zoo_reekuang_guang_1"):setPositionY(self:findChild("Zoo_reekuang_guang_1"):getPositionY()+45)
    self:findChild("ZooMania_reekuang_7"):setPositionY(self:findChild("ZooMania_reekuang_7"):getPositionY()+45)
    self:findChild("reelNode"):setPositionY(self:findChild("reelNode"):getPositionY()+48)

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
        local soundIndex = 1
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE  then
            if winRate <= 1 then
                soundIndex = 11
                soundTime = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 22
            elseif winRate > 3 then
                soundIndex = 33
            end
        end

        local soundName = "ZooManiaSounds/music_ZooMania_last_win_".. soundIndex .. ".mp3"
        -- self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenZooManiaMachine:setScatterDownScound( )

    local soundPath = "ZooManiaSounds/ZooMania_Scatter_down.mp3"
   
    self.m_scatterBulingSoundArry["auto"] = soundPath
end

function CodeGameScreenZooManiaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        -- self.m_initFeatureData
        if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            if self.m_initFeatureData == nil then
                self:playEnterGameSound( "ZooManiaSounds/music_ZooMania_enter.mp3" )
            elseif self.m_initFeatureData and self.m_initFeatureData.p_status == "CLOSED" then
                self:playEnterGameSound( "ZooManiaSounds/music_ZooMania_enter.mp3" )
            end
        end

    end,0.4,self:getModuleName())
end

function CodeGameScreenZooManiaMachine:getReelWidth( )
    if display.width < 1370 then
        return 1150
    else
        return 1000
    end
end

function CodeGameScreenZooManiaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:checkRemoveEffect()
    self:addObservers()
end

function CodeGameScreenZooManiaMachine:scaleMainLayer()
    CodeGameScreenZooManiaMachine.super.scaleMainLayer(self)

    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 3)
end

function CodeGameScreenZooManiaMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

end

function CodeGameScreenZooManiaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenZooManiaMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_ZooMania_bonus"
    end

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_ZooMania_wild"
    end

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_ZooMania_scatter"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenZooManiaMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenZooManiaMachine:MachineRule_initGame(  )

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        self.m_gameBg:runCsbAction("normal_free",false,function()
            self.m_gameBg:runCsbAction("FreeSpin",true)
            self:findChild("Zoo_reekuang_guang_1"):setVisible(true)
        end)
        self.m_gameBgFreeCao:setVisible(true)
        util_spinePlay(self.m_gameBgFreeCao,"actionframe",true)
    end
end

function CodeGameScreenZooManiaMachine:checkSymbolTypePlayTipAnima( symbolType )

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then
        return true
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS  then
        return true
    elseif symbolType == self.SYMBOL_BONUS  then
        return true
    end

end

function CodeGameScreenZooManiaMachine:hasBonusInFirstCol(iReelColumnNum)
    local reelData = self.m_runSpinResultData.p_reels
    local BonusNums = 0

    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            if reelData[iRow][iCol] == self.SYMBOL_BONUS then
                BonusNums = BonusNums + 1
                if iReelColumnNum <= 3 then
                    return true
                elseif iReelColumnNum == 4 then
                    if BonusNums > 1 then
                        return true
                    end
                elseif iReelColumnNum == 5 then
                    if BonusNums > 2 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function CodeGameScreenZooManiaMachine:hasScatterInFirstCol(iReelColumnNum)
    local reelData = self.m_runSpinResultData.p_reels
    local ScatterNums = 0
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            if reelData[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                ScatterNums = ScatterNums + 1
                if iReelColumnNum <= 3 then
                    return true
                elseif iReelColumnNum == 4 then
                    if ScatterNums > 1 then
                        return true
                    end
                elseif iReelColumnNum == 5 then
                    if ScatterNums > 2 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function CodeGameScreenZooManiaMachine:hasScatterInFirstColFreeSpin(iReelColumnNum)
    local reelData = self.m_runSpinResultData.p_reels
    local ScatterNums = 0
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            if reelData[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                ScatterNums = ScatterNums + 1
                if iReelColumnNum <= 4 then
                    return true
                elseif iReelColumnNum == 5 then
                    if ScatterNums > 1 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function CodeGameScreenZooManiaMachine:playCustomSpecialSymbolDownAct( slotNode )
    
    CodeGameScreenZooManiaMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    local soundPath = nil
    if self:hasBonusInFirstCol(slotNode.p_cloumnIndex) and slotNode.p_symbolType == self.SYMBOL_BONUS   then

        local slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)

        slotNode:runAnim("buling",false,function(  )
            slotNode:runAnim("idleframe",true)
        end)


        soundPath = "ZooManiaSounds/ZooMania_Bonus_down.mp3"
        
        self.m_reelDownAddTime = 21/30

    elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
            if self:hasScatterInFirstColFreeSpin(slotNode.p_cloumnIndex) then
                local slotNode =  util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)

                slotNode:runAnim("buling",false,function(  )
                    slotNode:runAnim("idleframe",true)
                end)

                self:playScatterBonusSound(slotNode)
                
                self.m_reelDownAddTime = 21/30
            else
                slotNode:runAnim("idleframe")
            end
        else
            if self:hasScatterInFirstCol(slotNode.p_cloumnIndex) then
                local slotNode =  util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)

                slotNode:runAnim("buling",false,function(  )
                    slotNode:runAnim("idleframe",true)
                end)

                self:playScatterBonusSound(slotNode)
                
                self.m_reelDownAddTime = 21/30
            else
                slotNode:runAnim("idleframe")
            end
        end
    else
        slotNode:runAnim("idleframe")
    end
        
    if soundPath then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end

--播放提示动画
function CodeGameScreenZooManiaMachine:playReelDownTipNode(slotNode)

    -- self:playScatterBonusSound(slotNode)
    -- slotNode:runAnim("idleframe")
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment( slotNode)
end


function CodeGameScreenZooManiaMachine:getScatterNum()
    local reelData = self.m_runSpinResultData.p_reels
    local ScatterNums = 0
    for iRow = 1,self.m_iReelRowNum do
        for iCol = 1, self.m_iReelColumnNum do
            if reelData[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                ScatterNums = ScatterNums + 1
            end
        end
    end
    return ScatterNums
end
--
--单列滚动停止回调
--
function CodeGameScreenZooManiaMachine:slotOneReelDown(reelCol)    
    
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local symbolType = targSp.p_symbolType
            if symbolType == self.SYMBOL_BONUS then
                self.m_BonusNum = self.m_BonusNum + 1
            end
        end
    end

    for row = 1,self.m_iReelRowNum do
        if self.m_stcValidSymbolMatrix[row][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local symbolNode = self:getFixSymbol(reelCol, row)
            if symbolNode then
                if symbolNode.p_symbolImage ~= nil and symbolNode.p_symbolImage:getParent() ~= nil then
                    symbolNode.p_symbolImage:removeFromParent()
                end
                symbolNode.p_symbolImage = nil
                if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                    if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
                        symbolNode:setIdleAnimName("idleframe1")
                    else
                        if self:getScatterNum() >= 2 then
                            symbolNode:setIdleAnimName("idleframe1")
                        else
                            symbolNode:setIdleAnimName("idleframe")
                        end
                    end
                else
                    symbolNode:setIdleAnimName("idleframe")
                end

            end
        end
    end


    if self.m_reelRunAnimaBonus[reelCol][1]:isVisible() then
        self.m_reelRunAnimaBonus[reelCol][1]:setVisible(false)
    end
    if self.m_reelRunAnimaBGBonus[reelCol][1]:isVisible() then
        self.m_reelRunAnimaBGBonus[reelCol][1]:setVisible(false)
    end

    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage( ) ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_BonusNum >= 2 then
            self:showBonusLongRunEffect(reelCol + 1)
        else
            self:creatReelRunAnimation(reelCol + 1)
        end
    end

     ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)


    if self.m_reelDownSoundPlayed then
        self:playReelDownSound(reelCol,self.m_reelDownSound )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end

    

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates( ) 
    end

    return isTriggerLongRun
end


--包含buling动画图标
function CodeGameScreenZooManiaMachine:isSymbolBuling( symbolType )
    local result = false

    if self.SYMBOL_BONUS == symbolType then
        result = true
    elseif TAG_SYMBOL_TYPE.SYMBOL_SCATTER == symbolType then
        result = true
    end

   return result
end

-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenZooManiaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self:findChild("reel_base"):setVisible(false)
    self:findChild("reel_free"):setVisible(true)  
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenZooManiaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------


-- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenZooManiaMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_fs_MoreView.mp3")

            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                -- self.m_freeSpinbar:setVisible(true)
                self.m_baseFreeSpinBar:setVisible(true)
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            performWithDelay(self,function(  )
                self:findChild("reel_base"):setVisible(false)
                self:findChild("reel_free"):setVisible(true)  
            end,0.1)
            gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_fs_StartView.mp3")

            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self.m_gameBg:runCsbAction("normal_free",false,function()
                    self.m_gameBg:runCsbAction("FreeSpin",true)
                    self:findChild("Zoo_reekuang_guang_1"):setVisible(true)
                end)
                self.m_gameBgFreeCao:setVisible(true)
                util_spinePlay(self.m_gameBgFreeCao,"actionframe",true)
                
                -- self.m_freeSpinbar:setVisible(true)
                self.m_baseFreeSpinBar:setVisible(true)
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end,false)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenZooManiaMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_fs_OverView.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            -- self.m_freeSpinbar:setVisible(false)
            self.m_baseFreeSpinBar:setVisible(false)
            self.m_gameBg:runCsbAction("free_normal",false,function()
                self.m_gameBg:runCsbAction("normal",true)
                self:findChild("Zoo_reekuang_guang_1"):setVisible(false)
            end)
            self.m_gameBgBaseCao:setVisible(true)
            util_spinePlay(self.m_gameBgBaseCao,"actionframe",true)
            self:findChild("reel_base"):setVisible(true)
            self:findChild("reel_free"):setVisible(false)

            self:triggerFreeSpinOverCallFun()
        end)
    local node=view:findChild("m_lb_coins")
    if node then
        view:updateLabelSize({label=node,sx=1,sy=1},650)
    end

end

function CodeGameScreenZooManiaMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    if coins == "0" then
        return self:showDialog("FreeSpinOver_0",ownerlist,func)
    else
        --
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    end
end

-- 显示bonus 触发的小游戏
function CodeGameScreenZooManiaMachine:showEffect_Bonus(effectData)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self.isInBonus = true
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    self:showBonusGameView(effectData)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
end

-- 根据Bonus Game 每关做的处理
function CodeGameScreenZooManiaMachine:showBonusGameView(effectData)
    
    self:showBonusGuoChang( function(  )

        self:showDialog("BonusStart_1",nil,function()

            self:createBonusGameChooseView( function(  )

                self:restSelfGameEffects( GameEffect.EFFECT_BONUS  )
            end )

        end,BaseDialog.AUTO_TYPE_ONLY)
    end)
    

end

-- 开始bonus游戏
function CodeGameScreenZooManiaMachine:createBonusGameChooseView( func , isduanxian)
    
    self.m_BonusGuoChangMask:runCsbAction("over",false,function()
        self.m_BonusGuoChangMask:setVisible(false)
    end)
    self:clearCurMusicBg()
    self:resetMusicBg(nil,"ZooManiaSounds/music_ZooMaina_bonus_bg.mp3")

    if isduanxian then
        self.m_BonusGameChoose:setVisible(true)
        self.m_BonusGameChoose:updateUIDate(self)
    end
    
    self.m_BonusGameChoose:updateUI( )
    self.m_BonusGameChoose:startGameCallFunc()
    self.m_BonusGameChoose:setEndCall( function()
        self.m_BonusGuoChang:setVisible(true)
        util_spinePlay(self.m_BonusGuoChang,"actionframe1",false)
        util_spineEndCallFunc(self.m_BonusGuoChang,"actionframe1",function ()
            self.m_BonusGuoChang:setVisible(false)
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                self.m_baseFreeSpinBar:setVisible(true)
            end
            if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then 
                self:checkFeatureOverTriggerBigWin( self.m_serverWinCoins ,GameEffect.EFFECT_BONUS)
                self:playGameEffect()
            end
        end)
        util_spineFrameEvent(self.m_BonusGuoChang,"actionframe1","Show1",function ()
            
            performWithDelay(self,function(  )
                if func then
                    func()
                end
                if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
                    self:playGameEffect()
                end
            end,0.5)
            local waitTime = 2
            if self:checkIsTriggerBigWin(self.m_serverWinCoins) then
                waitTime = 2.5
            end
            performWithDelay(self,function(  )
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end,waitTime)
            
            self.m_BonusGameChoose:setVisible(false)
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
                self.m_gameBg:runCsbAction("FreeSpin",true)
                self:findChild("Zoo_reekuang_guang_1"):setVisible(true)
                self.m_gameBgFreeCao:setVisible(true)
                util_spinePlay(self.m_gameBgFreeCao,"actionframe",true)
            else
                self.m_gameBg:runCsbAction("bonus_normal",false,function()
                    self.m_gameBg:runCsbAction("normal",true)
                    self:findChild("Zoo_reekuang_guang_1"):setVisible(false)
                end)
                self.m_gameBgBaseCao:setVisible(true)
                util_spinePlay(self.m_gameBgBaseCao,"actionframe",true)
            end
        end)
    end)
end

function CodeGameScreenZooManiaMachine:getBonusOverCoin( coin)
    self.m_serverWinCoins = coin
end
-- bonus游戏过场动画
function CodeGameScreenZooManiaMachine:showBonusGuoChang( func )
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_baseFreeSpinBar:setVisible(false)
    end
    self:notifyClearBottomWinCoin()
    self.m_BonusGuoChang:setVisible(true)
    self.m_BonusGuoChangMask:setVisible(true)
    self.m_BonusGuoChangMask:runCsbAction("auto",false,function()

    end)
    self.m_gameBg:runCsbAction("normal_bonus",false,function()
        self.m_gameBg:runCsbAction("Bonus",true)
    end)

    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_Bonus_GuoChang.mp3")
    util_spinePlay(self.m_BonusGuoChang,"actionframe",false)
    util_spineEndCallFunc(self.m_BonusGuoChang,"actionframe",function ()
        self.m_BonusGuoChang:setVisible(false)
    end)
    
    performWithDelay(self,function ()
        local lizi1 =  self.m_BonusGuoChangBaoZha:findChild("Particle_1")
        local lizi2 =  self.m_BonusGuoChangBaoZha:findChild("Particle_2")
        lizi1:stopSystem()
        lizi2:stopSystem()
        lizi1:resetSystem()
        lizi2:resetSystem()
        self.m_BonusGuoChangBaoZha:setVisible(true)
        self.m_BonusGuoChangBaoZha:runCsbAction("actionframe",false,function()
            self.m_BonusGuoChangBaoZha:setVisible(false)
        end)
    end,40/60)

    performWithDelay(self,function ()
        
        self.m_BonusGameChoose:setVisible(true)
        self.m_BonusGameChoose:updateUIDate(self)
    end,80/60)

    performWithDelay(self,function ()
        if func then
            func()
        end
    end,1.5)
end

-- 收集小游戏 断线处理
function CodeGameScreenZooManiaMachine:initFeatureInfo(spinData,featureData)
    if featureData.p_status and featureData.p_status ~= "CLOSED"  then
        self.m_runSpinResultData.p_selfMakeData = featureData
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            
            performWithDelay(self,function(  )
                self.m_baseFreeSpinBar:setVisible(false)
            end,0.1)
        end
        self:createBonusGameChooseView(function(  )
            self:restSelfGameEffects( GameEffect.EFFECT_BONUS  )
        end, true)
        scheduler.performWithDelayGlobal(function (  )
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        end,0.1,self:getModuleName())
    end
    
end

-- bonus游戏结束之后 播放动画
function CodeGameScreenZooManiaMachine:restSelfGameEffects( restType ,isSelfType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_effectType
                if isSelfType then
                    effectType = effectData.p_selfEffectType
                end

                if effectType == restType then

                    effectData.p_isPlay = true
                end
                
            end

        end
        -- self:playGameEffect()
    end
    
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenZooManiaMachine:MachineRule_SpinBtnCall()
    -- self:removeSoundHandler() -- 移除监听
    self:setMaxMusicBGVolume()
    self.isInBonus = false
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    if self.m_BonusGameChoose:isVisible() then
        return true
    else
        self.m_BonusNum = 0
        -- self:setMaxMusicBGVolume( )
       
        return false -- 用作延时点击spin调用
    end
   
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenZooManiaMachine:addSelfEffect()
    --收集玩法特效
    local features = self.m_runSpinResultData.p_features
    for i=1,#features do
        if features[i] == SPECIAL_SPIN_MODE then
            local selfGameEffect = GameEffectData.new()
            selfGameEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfGameEffect.p_effectOrder = self.EFFECT_COLLOCTION
            self.m_gameEffects[#self.m_gameEffects + 1] = selfGameEffect
            selfGameEffect.p_selfEffectType = self.EFFECT_COLLOCTION -- 动画类型
        end
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenZooManiaMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_COLLOCTION then
        -- gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbolTrigger.mp3")
        self:bonusGameEffect(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    end
    return true
end

function CodeGameScreenZooManiaMachine:bonusGameEffect(func)
    globalMachineController:playBgmAndResume("ZooManiaSounds/music_ZooMaina_TriggerBonus.mp3",3,0.1,1)
    --bonus图标播放动作
    for iRow =1,self.m_iReelRowNum do
        for iCol=1,self.m_iReelColumnNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol.p_symbolType ~= nil and symbol.p_symbolType == self.SYMBOL_BONUS  then

                symbol:runAnim("actionframe",false,function(  )
                    symbol:runAnim("idleframe",true)
                end)
            end
        end
    end
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,2)

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
end

function CodeGameScreenZooManiaMachine:getBonusIndex( )
    
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do

            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            
            if symbolType ==  self.SYMBOL_BONUS then
                
                return self:getPosReelIdx(iRow, iCol)
            end
        end

    end
end


--设置bonus scatter 层级
function CodeGameScreenZooManiaMachine:getBounsScatterDataZorder(symbolType)
    local order = 0
    order = BaseNewReelMachine.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    return order
end

-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenZooManiaMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenZooManiaMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenZooManiaMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseNewReelMachine.slotReelDown(self)
    self:checkRemoveEffect()
end

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

-- --设置bonus scatter 信息
function CodeGameScreenZooManiaMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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
    end
    
    -- soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount
    local bAdd = false

    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        local isTrue = false
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if targetSymbolType == self.SYMBOL_BONUS or targetSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                isTrue = true
            end 
        else
            if targetSymbolType == symbolType then
                isTrue = true
            end
        end
        if isTrue then
            local bPlaySymbolAnima = bPlayAni
                if bAdd == false then
                    allSpecicalSymbolNum = allSpecicalSymbolNum + 1
                    bAdd = true
                end
                
                if bRun == true then
                    -- if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
                    --     if targetSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    --         soundType, nextReelLong = self:getRunFreeSpinStatus(column, allSpecicalSymbolNum, showCol)
                    --     elseif targetSymbolType == self.SYMBOL_BONUS then 
                    --         soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                    --     end
                    -- else
                    --     soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)
                    -- end
    
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

function CodeGameScreenZooManiaMachine:createReelEffectBonus(col)
    local reelEffectNode, effectAct = util_csbCreate("LongRunFrameZooMania.csb")
    self.m_clipParent:addChild(reelEffectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    local reel = self:findChild("sp_reel_" .. (col - 1))
    reelEffectNode:setPosition(cc.p(reel:getPosition()))
    reelEffectNode:setVisible(false)
    self.m_reelRunAnimaBonus[col] = {reelEffectNode, effectAct}
end

function CodeGameScreenZooManiaMachine:createReelEffectBGBonus(col)
    
    local csbName = "LongRunFrameZooMania_bg.csb"
    local reelEffectNode, effectAct = util_csbCreate(csbName)

    self.m_clipParent:addChild(reelEffectNode, -1)
    local reel = self:findChild("sp_reel_" .. (col - 1))
    local reelType = tolua.type(reel)
    if reelType == "ccui.Layout" then
        reelEffectNode:setLocalZOrder(0)
    end
    reelEffectNode:setPosition(cc.p(reel:getPosition()))
    reelEffectNode:setVisible(false)
    self.m_reelRunAnimaBGBonus[col] = {reelEffectNode, effectAct}
end

function CodeGameScreenZooManiaMachine:showBonusLongRunEffect(col)
    self.m_reelRunAnimaBonus[col][1]:setVisible(true)
    util_csbPlayForKey(self.m_reelRunAnimaBonus[col][2], "run", true)

    self.m_reelRunAnimaBGBonus[col][1]:setVisible(true)
    util_csbPlayForKey(self.m_reelRunAnimaBGBonus[col][2], "run", true)

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenZooManiaMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false
    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()
    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
     or self.m_hasBigSymbol == true
    )
    then
        isTriggerLongRun = true -- 触发了长滚动
        for i = reelCol + 1, self.m_iReelColumnNum do
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent
            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenZooManiaMachine:getRunFreeSpinStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum < 1 then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, true
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 1  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum == 1 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

function CodeGameScreenZooManiaMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

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

            slotNode = self:setSlotNodeEffectParentFree(slotNode)
            
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
            
        end
    end

    animTime = animTime + 0.1
    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenZooManiaMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = 1, nodeLen do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent,lineNode,nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            end
        end
    end

    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_BONUS then
                    targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
 
                end
            end

        end

    end

    
end

function CodeGameScreenZooManiaMachine:checkIsTriggerBigWin( winAmonut)
    if winAmonut == nil then
        return false
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = winAmonut / lTatolBetNum
    if winRatio >= self.m_HugeWinLimitRate then
        return true
    elseif winRatio >= self.m_MegaWinLimitRate then
        return true
    elseif winRatio >= self.m_BigWinLimitRate then
        return true
    end
    return false
end

function CodeGameScreenZooManiaMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
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
    
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i=1,#self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert( self.m_gameEffects, i + 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, i + 2, effectData )
                break
            end
        end
        if isAddEffect == false then
            for i=1,#self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut


                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert( self.m_gameEffects, i + 1, delayEffect )

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert( self.m_gameEffects, i + 2, effectData )
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert( self.m_gameEffects, 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, 2, effectData )
            end
        end

    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

--beginReel时尝试修改层级
function CodeGameScreenZooManiaMachine:checkChangeBaseParent()

   CodeGameScreenZooManiaMachine.super.checkChangeBaseParent(self)

    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_BONUS then
                    targSp:runIdleAnim()
                    targSp:setIdleAnimName("idleframe")
                end
            end

        end

    end

end

function CodeGameScreenZooManiaMachine:setSlotNodeEffectParentFree(slotNode)
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

    self.m_clipParent:addChild(slotNode,self:getSlotNodeEffectZOrder(slotNode))
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runAnim(slotNode:getLineAnimName())
    end
    return slotNode
end

function CodeGameScreenZooManiaMachine:checkRemoveEffect()
    -- 如果处于 bonus 中 那么free收集不触发
    local hasBonusEffect = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    if hasBonusEffect == true  then
        local hasFreeOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
        if hasFreeOverEffect then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            self.m_isAddFreeOver = true
        end
    end

end

function CodeGameScreenZooManiaMachine:checkAddEffect()
    if self.m_isAddFreeOver then
        self.m_isAddFreeOver = false
        local fsOverEffect = GameEffectData.new()
        fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
        fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
        self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
    end

end
function CodeGameScreenZooManiaMachine:checkTriggerINFreeSpin( )
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
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self:checkTriggerFsOver( ) then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end
        -- self.m_initFeatureData.p_bonusWinAmount
        local params = {self.m_runSpinResultData.p_fsWinCoins,false,false}
        if self.m_initFeatureData then
            params = {self.m_runSpinResultData.p_fsWinCoins+self.m_initFeatureData.p_bonusWinAmount,false,false}
            globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_fsWinCoins+self.m_initFeatureData.p_bonusWinAmount
        end
        -- 发送事件显示赢钱总数量
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end

function CodeGameScreenZooManiaMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
    
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then  
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if iconsPos ~= nil and #iconsPos >= 2 then
                lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
            end
            
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
                lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
            end
        end

    else
        if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
            if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
                
            elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
            end
        end
    end

    return enumSymbolType
end

return CodeGameScreenZooManiaMachine