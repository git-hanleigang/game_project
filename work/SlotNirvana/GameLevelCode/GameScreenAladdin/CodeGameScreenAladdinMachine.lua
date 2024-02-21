---
-- island li
-- 2019年1月26日
-- CodeGameScreenAladdinMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local CodeGameScreenAladdinMachine = class("CodeGameScreenAladdinMachine", BaseFastMachine)

CodeGameScreenAladdinMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAladdinMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenAladdinMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenAladdinMachine.SYMBOL_SCATTER_2 = 95  -- 自定义的小块类型
CodeGameScreenAladdinMachine.SYMBOL_SCATTER_3 = 110
CodeGameScreenAladdinMachine.SYMBOL_SCATTER_4 = 111
CodeGameScreenAladdinMachine.SYMBOL_SCATTER_5 = 112
CodeGameScreenAladdinMachine.SYMBOL_SCATTER_6 = 113
CodeGameScreenAladdinMachine.SYMBOL_WILD_2 = 115
CodeGameScreenAladdinMachine.SYMBOL_WILD_3 = 116
CodeGameScreenAladdinMachine.SYMBOL_WILD_X6 = 200
-- CodeGameScreenAladdinMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenAladdinMachine.CHANGE_COL_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenAladdinMachine.LOCK_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2

CodeGameScreenAladdinMachine.m_vecLockWild = nil
CodeGameScreenAladdinMachine.m_wheelResult = nil
CodeGameScreenAladdinMachine.m_reelRunAnimaBG = nil
CodeGameScreenAladdinMachine.m_vecScatterSound = nil
CodeGameScreenAladdinMachine.m_vecExtraWild = nil
CodeGameScreenAladdinMachine.m_vecFsMoreScatter = nil
CodeGameScreenAladdinMachine.m_vecFsMoreCol = nil
CodeGameScreenAladdinMachine.m_npcIdleCall = nil
-- 构造函数
function CodeGameScreenAladdinMachine:ctor()
    BaseFastMachine.ctor(self)

    self.m_reelRunAnimaBG = {}
    self.m_vecScatterSound = {}
    self.m_vecExtraWild = {}
    self.m_isFeatureOverBigWinInFree = true
	--init
	self:initGame()
end

function CodeGameScreenAladdinMachine:initGame()


    self.m_configData = gLobalResManager:getCSVLevelConfigData("AladdinConfig.csv", "LevelAladdinConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    self.m_scatterBulingSoundArry = {}
    self.m_scatterBulingSoundArry["auto"] = "AladdinSounds/sound_Aladdin_scatter_down.mp3"

end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAladdinMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Aladdin"  
end

function CodeGameScreenAladdinMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    self.m_jackPotNode = util_createView("CodeAladdinSrc.AladdinJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackPotNode)
    self.m_jackPotNode:initMachine(self)

    self.m_npcNode = util_spineCreate("Socre_Aladdin_juese", true, true)
    self:findChild("NPC"):addChild(self.m_npcNode)
    self.m_npcNode:setPosition(160, -60)
    self:showNpcAnmation()

    self.m_wheel2Fs = util_spineCreate("Socre_Aladdin_juese2", true, true)
    self:findChild("wheel2fs"):addChild(self.m_wheel2Fs)
    self.m_wheel2Fs:setPosition(160, -60)
    self.m_wheel2Fs:setVisible(false)

    self.m_lanternNode = util_spineCreate("Socre_Aladdin_shendeng", true, true)
    self:findChild("lantern"):addChild(self.m_lanternNode)
    self.m_lanternNode:setPosition(160, -60)
    self.m_lanternNode:setVisible(false)

    self.m_smokeNode = util_spineCreate("Socre_Aladdin_smoke", true, true)
    self:findChild("lantern"):addChild(self.m_smokeNode)
    self.m_smokeNode:setPosition(160, -60)
    self.m_smokeNode:setVisible(false)
    -- -- 创建大转盘
    -- -- 轮盘网络数据
    -- local data = self.m_runSpinResultData.p_selfMakeData
    
    -- local callback = function ()
    --         bonusWheel:removeFromParent(true)
    -- end
    -- bonusWheel:setPosition(display.width * 0.5, display.height * 0.5)
    -- bonusWheel:initCallBack(callback)
    -- self:addChild(bonusWheel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
   
    self.m_bonusWheel = util_createView("CodeAladdinSrc.AladdinWheelView")
    -- self:findChild("wheels"):addChild(self.m_bonusWheel)
    -- self.m_bonusWheel:setVisible(false)

    self.m_freespinBar = util_createView("CodeAladdinSrc.AladdinFreespinBarView")
    self:findChild("fs_cishu"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)

    self.m_ruleDisplay = util_createView("CodeAladdinSrc.AladdinRuleDisplay")
    self:findChild("wenzi"):addChild(self.m_ruleDisplay)
    self.m_ruleDisplay:setVisible(true)

    self:findChild("lan_rell"):setVisible(true)
    self:findChild("fs_rell"):setVisible(false)

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

        local soundName = "AladdinSounds/sound_Aladdin_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    local scale = util_getAdaptDesignScale()
    util_csbScale(self.m_gameBg.m_csbNode, scale)
    if display.height > CC_DESIGN_RESOLUTION.height then
        local distance = (display.height - CC_DESIGN_RESOLUTION.height) * 0.5
        local bgTop = self.m_gameBg:findChild("bg_chuanglian")
        bgTop:setPositionY(bgTop:getPositionY() + distance * 0.5)

        local fitNode = self:findChild("fit_node")
        fitNode:setPositionY(fitNode:getPositionY() + distance)
    else
        local distance = (CC_DESIGN_RESOLUTION.height - display.height) * (1 - self.m_machineRootScale)  * 0.6
        local fitNode = self:findChild("fit_node")
        fitNode:setPositionY(fitNode:getPositionY() + distance)
    end
end

function CodeGameScreenAladdinMachine:showNpcAnmation()
    util_spinePlay(self.m_npcNode, "idle", false)
    util_spineEndCallFunc(self.m_npcNode, "idle", function()
        if self.m_npcIdleCall ~= nil then
            self.m_npcIdleCall()
            self.m_npcIdleCall = nil
        else
            self:showNpcAnmation()
        end
    end)
end

function CodeGameScreenAladdinMachine:animationGuoChang(frameFunc, endFunc, isWheel)
    local animationName = "guochang"
    if isWheel == true then
        animationName = "guochang2"
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_guochang.mp3")
        self.m_wheel2Fs:setVisible(true)
        util_spinePlay(self.m_wheel2Fs, animationName)
        util_spineFrameCallFunc(self.m_wheel2Fs, animationName, "show", function() 
            if frameFunc ~= nil then
                frameFunc()
            end
        end, function() 
            if endFunc ~= nil then
                endFunc()
            end
            self.m_wheel2Fs:setVisible(false)
        end)
    else
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_guochang.mp3")
        self.m_lanternNode:setVisible(true)
        util_spinePlay(self.m_lanternNode, animationName)
        util_spineFrameCallFunc(self.m_lanternNode, animationName, "show", function() 
            if frameFunc ~= nil then
                frameFunc()
            end
        end, function() 
            if endFunc ~= nil then
                endFunc()
            end
            self.m_lanternNode:setVisible(false)
        end)
    end

    util_spinePlay(self.m_npcNode, animationName)
    
end

function CodeGameScreenAladdinMachine:animationShowWheel(func)
    self.m_npcNode:setVisible(true)
    self.m_npcNode:setPosition(160, -600)
    util_spinePlay(self.m_npcNode, "show")
    util_spineEndCallFunc(self.m_npcNode, "show", function()
        if func then
            func()
        end
    end)
end

function CodeGameScreenAladdinMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_enter_game.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
                    performWithDelay(self, function()
                        self:reelsDownDelaySetMusicBGVolume( ) 
                    end, 0.3)
                end
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenAladdinMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_selfMakeData.lockWilds ~= nil then
            self:lockWild(nil, true)
        end
    end
end

function CodeGameScreenAladdinMachine:addObservers()
    BaseFastMachine.addObservers(self)

end

function CodeGameScreenAladdinMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    for i, v in pairs(self.m_reelRunAnimaBG) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnimaBG[i] = v
    end

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenAladdinMachine:addBonusWheel()
    self.m_bonusWheel = util_createView("CodeAladdinSrc.AladdinWheelView")
    self:findChild("wheels"):addChild(self.m_bonusWheel)
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_bonusWheel.getRotateBackScaleFlag = function(  ) return false end
    end

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAladdinMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_2 then
        return "Socre_Aladdin_Scatter_2"
    elseif symbolType == self.SYMBOL_SCATTER_3 or symbolType == self.SYMBOL_SCATTER_4 then
        return "Socre_Aladdin_Scatter_3"
    elseif symbolType == self.SYMBOL_SCATTER_5 or symbolType == self.SYMBOL_SCATTER_6 then
        return "Socre_Aladdin_Scatter_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_Aladdin_WildX2"
    elseif symbolType == self.SYMBOL_WILD_2 then
        return "Socre_Aladdin_Wild"
    elseif symbolType == self.SYMBOL_WILD_3 then
        return "Socre_Aladdin_Wild_sd"
    elseif symbolType == self.SYMBOL_WILD_X6 then
        return "Socre_Aladdin_WildX6"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Aladdin_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_Aladdin_11"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAladdinMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_WILD_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenAladdinMachine:MachineRule_initGame(  )

end

--
--单列滚动停止回调
--
function CodeGameScreenAladdinMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
    
    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_vecFsMoreScatter == nil then
        self.m_vecFsMoreScatter = {}
    end
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_vecFsMoreCol[reelCol] ~= nil then
            local slotsParents = self.m_slotParents
            local parentData = slotsParents[reelCol]
            local slotParent = parentData.slotParent
            local slotParentBig = parentData.slotParentBig
            local children = slotParent:getChildren()
            if slotParentBig then
                local newChildren = slotParentBig:getChildren()
                for j=1,#newChildren do
                    children[#children+1]=newChildren[j]
                end
            end
            for i = 1, #children, 1 do
                local child = children[i]
                if self:isScatterSymbol(child.p_symbolType)  then
                    child:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3 + 20)
                    self.m_vecFsMoreScatter[#self.m_vecFsMoreScatter + 1] = child
                end
            end
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenAladdinMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
    self.m_freespinBar:setVisible(true)
    self.m_ruleDisplay:setVisible(false)
    self.m_freespinBar:changeFreeSpinByCount()
    self:findChild("lan_rell"):setVisible(false)
    self:findChild("fs_rell"):setVisible(true)
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenAladdinMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    self.m_freespinBar:setVisible(false)
    self.m_ruleDisplay:setVisible(true)
    self:findChild("lan_rell"):setVisible(true)
    self:findChild("fs_rell"):setVisible(false)
end
---------------------------------------------------------------------------

function CodeGameScreenAladdinMachine:showEffect_FiveOfKind(effectData)

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

---
-- 显示free spin
function CodeGameScreenAladdinMachine:showEffect_Bonus(effectData)

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
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    if scatterLineValue ~= nil then
        --
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_trigger_bonus.mp3")
        util_spinePlay(self.m_npcNode, "idle5")
        util_spineEndCallFunc(self.m_npcNode, "idle5", function()
            self:showNpcAnmation()
        end)
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showBonusGameView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_trigger_bonus.mp3")
        util_spinePlay(self.m_npcNode, "idle5")
        util_spineEndCallFunc(self.m_npcNode, "idle5", function()
            self:showNpcAnmation()
            self:showBonusGameView(effectData)
        end)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenAladdinMachine:showBonusGameView(effectData)
    -- self.m_runSpinResultData.
    self.m_bWheelCallback = true
    -- 不播 过场
    -- self.m_bonusWheel:setVisible(true)
    -- self.m_bonusWheel:showBtnAnimation()
    self:addBonusWheel()
    self:notifyClearBottomWinCoin()
    self:setLastWinCoin(0)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"switch")
    gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_appear.mp3")
    self:runCsbAction("over", false, function()
        local startFreeSpin = function ()
            gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_fs_start.mp3")
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
            if self.m_wheelResult ~= "wild" then
                view:findChild("extraWild"):setVisible(false)
            end
            if type(self.m_wheelResult) ~= "number" then
                view:findChild("extraTimes"):setVisible(false)
                view:findChild("m_lb_num2"):setVisible(false)
            else
                view:findChild("m_lb_num2"):setString(self.m_wheelResult)
            end
            performWithDelay(self, function()
                self.m_freespinBar:setVisible(true)
                self.m_ruleDisplay:setVisible(false)
                self.m_freespinBar:changeFreeSpinByCount()
                self.m_bonusWheel:removeFromParent()
                self.m_bonusWheel = nil
            end, 0.4)
        end
        self.m_bonusWheel:initCallBack(function()
            if type(self.m_wheelResult) == "string" and self.m_wheelResult ~= "wild" then

                self:showJackpotView(self.m_wheelResult, self.m_runSpinResultData.p_bonusWinCoins, function()
                    self:animationGuoChang(function()
                        
                        self:runCsbAction("idle1")
                        self:findChild("lan_rell"):setVisible(false)
                        self:findChild("fs_rell"):setVisible(true)
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
                        self:showNpcAnmation()
                    end, function()
                        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWilds ~= nil then
                            self:lockWild(function()
                                startFreeSpin()
                            end)
                        else
                            startFreeSpin()
                        end
                    end, true)
                end)
            else
                self:animationGuoChang(function()
                    self:clearCurMusicBg()
                    self:runCsbAction("idle1")
                    self:findChild("lan_rell"):setVisible(false)
                    self:findChild("fs_rell"):setVisible(true)
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
                    self:showNpcAnmation()
                end, function()
    
                    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWilds ~= nil then
                        self:lockWild(function()
                            startFreeSpin()
                        end)
                    else
                        startFreeSpin()
                    end
                end, true)
            end
        end)
        -- self.m_bonusWheel:addClickEvent()
        gLobalSoundManager:playBgMusic("AladdinSounds/music_Aladdin_wheel_bg.mp3")
    end)
end

----------- FreeSpin相关

---
-- 显示free spin
function CodeGameScreenAladdinMachine:showEffect_FreeSpin(effectData)

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
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
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

-- FreeSpinstart
function CodeGameScreenAladdinMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("AladdinSounds/music_Aladdin_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_fs_start.mp3")
        local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()       
        end)
        -- if self.m_wheelResult ~= "wild" then
            view:findChild("extraWild"):setVisible(false)
            view:findChild("extraTimes"):setVisible(false)
            view:findChild("m_lb_num2"):setVisible(false)
        -- end
        performWithDelay(self, function()
            self.m_freespinBar:setVisible(true)
            self.m_ruleDisplay:setVisible(false)
            self.m_freespinBar:changeFreeSpinByCount()
        end, 0.4)
    end

    local showFsMore = function()
        local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
        -- if self.m_wheelResult ~= "wild" then
        --     view:findChild("extraWild"):setVisible(false)
        -- end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWilds ~= nil then
                self:lockWild(function()
                    showFsMore()  
                end)
            else
                showFsMore()
            end
        else
            self:animationGuoChang(function()
                self:findChild("lan_rell"):setVisible(false)
                self:findChild("fs_rell"):setVisible(true)
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
                self:showNpcAnmation()
            end, function()
                if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWilds ~= nil then
                    self:lockWild(function()
                        showFSView()  
                    end)
                else
                    showFSView()
                end
            end)
        end
    end,0.5)

end

function CodeGameScreenAladdinMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_fs_over.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount, function()
        self:animationGuoChang(function()
            self:levelFreeSpinOverChangeEffect()
            self:showNpcAnmation()
        end, function()
            self:triggerFreeSpinOverCallFun()
        end)
        
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.78,sy=0.78}, 810)

end

function CodeGameScreenAladdinMachine:showJackpotView(index,coins,func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_jackpot_window.mp3")
    local jackPotWinView = util_createView("CodeAladdinSrc.AladdinJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins, true})
    jackPotWinView:initViewData(index,coins,function()
        -- gLobalSoundManager:stopAudio(soundID)
        -- soundID = nil
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
        if func ~= nil then 
            func()
        end
    end)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAladdinMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    gLobalSoundManager:setBackgroundMusicVolume(1)
   

    if self.m_vecFixWild ~= nil and #self.m_vecFixWild > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 then
        for i = #self.m_vecFixWild, 1, -1 do
            local symbol = self.m_vecFixWild[i]
            if not tolua.isnull(symbol) then
                symbol:hideBigSymbolClip()
                symbol:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType,symbol)
            end
        end
        self.m_vecFixWild = {}
    end

    if self.m_vecExtraWild ~= nil and #self.m_vecExtraWild > 0 then
        for i = #self.m_vecExtraWild, 1, -1 do
            local symbol = self.m_vecExtraWild[i]
            if not tolua.isnull(symbol) then
                symbol:hideBigSymbolClip()
                symbol:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType,symbol)
            end
        end
    end
    self.m_vecExtraWild = {}

    self.m_vecScatterSound = {}
    -- if self.m_vecFillColWild ~= nil and #self.m_vecFillColWild > 0 then
    --     for i = #self.m_vecFillColWild, 1, -1 do
    --         local symbol = self.m_vecFillColWild[i]
    --         if symbol then
    --             symbol:hideBigSymbolClip()
    --         end
    --         table.remove(self.m_vecFillColWild, i)
    --     end
    -- end
    -- self.m_vecFillColWild = {}

    return false -- 用作延时点击spin调用
end

function CodeGameScreenAladdinMachine:beginReel()
    self:resetReelDataAfterReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        
        local reelDatas = self:checkUpdateReelDatas(parentData)
        
        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)
        
        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent,slotParentBig)
        else
            self:registerReelSchedule()
        end
        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        self:foreachSlotParent(
            i,
            function(index, realIndex, child)
                if child.__cname ~= nil and child.__cname == "SlotsNode" then
                    child:resetReelStatus()
                end
                if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE then
                    --将该节点放在 .m_clipParent
                    child:removeFromParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    child:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(child, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + child.m_showOrder)
                end
            end
        )
    end
    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if child.__cname ~= nil and child.__cname == "SlotsNode" and child.m_symbolTag ~= SYMBOL_FIX_NODE_TAG  then
            child:resetReelStatus()
        end
        if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local colIndex = child.p_cloumnIndex
            local childSlotParent = slotsParents[colIndex].slotParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
            local pos = childSlotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            child:removeFromParent()
            child:resetReelStatus()
            child:setPosition(cc.p(pos.x, pos.y))
            local slotParentBig = slotsParents[colIndex].slotParentBig
            if slotParentBig and  self.m_configData:checkSpecialSymbol(child.p_symbolType) then
                slotParentBig:addChild(child)
            else
                childSlotParent:addChild(child)
            end
        end
    end
    self:setGameSpinStage(GAME_MODE_ONE_RUN)

    if self.m_vecFixWild ~= nil and #self.m_vecFixWild > 0 then
        for i = #self.m_vecFixWild, 1, -1 do
            local symbol = self.m_vecFixWild[i]
            if symbol  then
                symbol:runAnim("idleframe2", true)
            end
        end
    end
    
end



----
--- 处理spin 成功消息
--
function CodeGameScreenAladdinMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        

        self.m_ScatterShowCol = {}
        local vecCol = {}
        for i = 1, self.m_iReelRowNum, 1 do
            local vecRow = spinData.result.reels[i]
            for j = 1, self.m_iReelColumnNum, 1 do
                if self:isScatterSymbol(vecRow[j]) then
                    vecCol[j] = j
                end
            end
        end
        for col = 1, #vecCol, 1 do
            if col == vecCol[col] then
                self.m_ScatterShowCol[col] = col
            else
                break
            end
        end
        if #self.m_ScatterShowCol > 0 then
            self.m_ScatterShowCol[#self.m_ScatterShowCol + 1] = #self.m_ScatterShowCol + 1
        end
        
        if self:getCurrSpinMode() == FREE_SPIN_MODE or (self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildColumns ~= nil) then
            self.m_vecFsMoreCol = {}
            for i = 1, #self.m_ScatterShowCol, 1 do
                self.m_vecFsMoreCol[i] = i
            end
            self.m_ScatterShowCol = {}
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end

    if self.m_bWheelCallback == true then
        self.m_bWheelCallback = false
        local data = {}
        data.wheel = spinData.result.bonus.content
        data.select = spinData.result.bonus.choose[1] + 1
        self.m_wheelResult = data.wheel[data.select]
        self.m_bonusWheel:setWheelResult(data)
        self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:setLastWinCoin(spinData.result.winAmount)
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    end

end

function CodeGameScreenAladdinMachine:updateNetWorkData()
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildColumns ~= nil then
        
        -- self.m_lanternNode:setVisible(true)
        self.m_smokeNode:setVisible(true)
        -- util_spinePlay(self.m_lanternNode, "actionframe")
        
        self.m_npcIdleCall = function() 
            util_spinePlay(self.m_npcNode, "actionframe")
            util_spinePlay(self.m_smokeNode, "actionframe")
            util_spineFrameCallFunc(self.m_npcNode, "actionframe", "wild", function() 
                self:changeColWild()
            end, function() 
                self:showNpcAnmation()
            end)
    
            util_spineEndCallFunc(self.m_smokeNode, "actionframe", function()
                util_spinePlay(self.m_smokeNode, "actionframe2", true)
            end)
        end
        
        return
    end
    local delayTime = 0
    if self.m_runSpinResultData.p_selfMakeData.wheelWild ~= nil then
        local vecWild = self.m_runSpinResultData.p_selfMakeData.wheelWild
        for i = 1, #vecWild, 1 do
            performWithDelay(self, function()
                self:randomWild(vecWild[i])
            end, 0.5 * (i - 1))
        end
        
        local time = 0.55 + 0.5 * #vecWild
        delayTime = math.max(delayTime, time)
    end
    
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.animation ~= nil then
        local index = self.m_runSpinResultData.p_selfMakeData.animation
        self.m_npcIdleCall = function()
            util_spinePlay(self.m_npcNode, "idle"..index)
            util_spineEndCallFunc(self.m_npcNode, "idle"..index, function()
                self:showNpcAnmation()
                BaseSlotoManiaMachine.updateNetWorkData(self)
            end)
        end
        return
    end

    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildColumns ~= nil then
        return
    end

    scheduler.performWithDelayGlobal(function()
        BaseSlotoManiaMachine.updateNetWorkData(self)
    end, delayTime, self:getModuleName())

end

function CodeGameScreenAladdinMachine:randomWild(vecWild)
    if vecWild ~= nil and #vecWild > 0 then
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_trigger_random_wild.mp3")
    end
    for i = 1, #vecWild, 1 do
        local index = vecWild[i]
        local pos = self:getRowAndColByPos(index)
        local iX = 55
        local iY = self.m_SlotNodeH * (pos.iX - 0.5)
        local colNodeName = "sp_reel_" .. (pos.iY - 1)
        local reel = self:findChild(colNodeName)
        local reelPos = cc.p(iX, iY)
        local worldPos = reel:convertToWorldSpace(reelPos)
        local nodePos = self.m_clipParent:convertToNodeSpace(worldPos)
        local symbolType = self.SYMBOL_WILD_2
        local symbol = self:getSlotNodeBySymbolType(symbolType)
        self.m_clipParent:addChild(symbol,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 10)
        symbol:setPosition(nodePos)
        symbol.p_cloumnIndex = pos.iY
        symbol.p_rowIndex = pos.iX
        symbol.m_isLastSymbol = true
        local linePos = {}
        linePos[#linePos + 1] = {iX = symbol.p_rowIndex, iY = symbol.p_cloumnIndex}
        symbol:setTag(self:getNodeTag(symbol.p_cloumnIndex, symbol.p_rowIndex, SYMBOL_NODE_TAG))
        symbol.m_bInLine = true
        symbol:setLinePos(linePos)
        symbol:runAnim("actionframe2")
        -- self.m_vecExtraWild[#self.m_vecExtraWild + 1] = symbol
    end
end

function CodeGameScreenAladdinMachine:slotReelDown()
    
    BaseSlotoManiaMachine.slotReelDown(self)

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        if #self.m_vecFsMoreScatter > 0 then
            self.m_vecFsMoreScatter = {}
        end
    end
    
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenAladdinMachine:playEffectNotifyNextSpinCall( )

    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

  
    
end

-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenAladdinMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenAladdinMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAladdinMachine:addSelfEffect()

    -- if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildColumns ~= nil then
    --     local selfEffect = GameEffectData.new()
    --     selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --     selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --     selfEffect.p_selfEffectType = self.CHANGE_COL_WILD_EFFECT -- 动画类型
    -- end

        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAladdinMachine:MachineRule_playSelfEffect(effectData)

	return true
end

function CodeGameScreenAladdinMachine:changeColWild(colNum)

    gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_trigger_col_wild.mp3")

    local vecCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    local rowIndex = 1
    local randomID = math.random(#vecCol)
    
    local cloumnIndex = vecCol[randomID] + 1
    local iX = 55
    local iY = self.m_SlotNodeH * 0.5
    local colNodeName = "sp_reel_" .. vecCol[randomID]
    local columnData = self.m_reelColDatas[cloumnIndex]
    local parentData = self.m_slotParents[cloumnIndex]

    local reel = self:findChild(colNodeName)
    local reelPos = cc.p(iX, iY)
    local worldPos = reel:convertToWorldSpace(reelPos)
    local nodePos = self.m_clipParent:convertToNodeSpace(worldPos)
    local symbolType = self.SYMBOL_WILD_X6

    local symbol = self:getSlotNodeBySymbolType(symbolType)
    self.m_clipParent:addChild(symbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    symbol:setPosition(nodePos)

    symbol.p_slotNodeH = columnData.p_showGridH
    symbol.p_symbolType = self.SYMBOL_WILD_X6
    symbol.p_showOrder = parentData.order
    symbol.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    
    symbol.p_cloumnIndex = cloumnIndex
    symbol.p_rowIndex = 1
    symbol.m_isLastSymbol = true
    local linePos = {}
    for i = 1, self.m_iReelRowNum, 1 do
        linePos[#linePos + 1] = {iX = i, iY = symbol.p_cloumnIndex}
    end
    
    symbol.m_bInLine = true
    symbol:setLinePos(linePos)
    symbol:setTag(self:getNodeTag(symbol.p_cloumnIndex, 1, SYMBOL_NODE_TAG))
    self.m_vecExtraWild[#self.m_vecExtraWild + 1] = symbol
    if self.m_vecFillColWild == nil then
        self.m_vecFillColWild = {}
    end
    self.m_vecFillColWild[#self.m_vecFillColWild + 1] = symbol

    table.remove(vecCol, randomID)

    if #vecCol == 0 then
        util_spinePlay(self.m_smokeNode, "actionframe3")
        util_spineEndCallFunc(self.m_smokeNode, "actionframe3", function()
            self.m_smokeNode:setVisible(false)
        end)
        symbol:runAnim("actionframe2", false, function()
            performWithDelay(self, function()
                BaseSlotoManiaMachine.updateNetWorkData(self)
            end, 0.3)
        end)
    else
        symbol:runAnim("actionframe2", false, function()
            self:changeColWild()
        end)
    end
    
    -- if #vecCol == 0 then
    --     util_spinePlay(self.m_smokeNode, "actionframe3")
    --     util_spineEndCallFunc(self.m_smokeNode, "actionframe3", function()
    --         self.m_smokeNode:setVisible(false)
    --     end)
    --     symbol:runAnim("actionframe2", false, function()
    --         performWithDelay(self, function()
    --             BaseSlotoManiaMachine.updateNetWorkData(self)
    --         end, 0.3)
    --     end)
    -- else
    --     symbol:runAnim("actionframe2")
    -- end
    
    -- performWithDelay(self, function ()
    --     if #vecCol > 0 then
    --         self:changeColWild()
    --     end
    -- end, 0.5)
end

-- function CodeGameScreenAladdinMachine:changeColWild(effectData)
--     local vecCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
--     local rowIndex = 1

--     for i = 1, #vecCol, 1 do
--         local cloumnIndex = vecCol[i] + 1
--         local columnData = self.m_reelColDatas[cloumnIndex]
--         local parentData = self.m_slotParents[cloumnIndex]
--         local slotParent = parentData.slotParent
--         local slotParentBig = parentData.slotParentBig

--         local symbolType = self.SYMBOL_WILD_X6
--         local node = self:getCacheNode(cloumnIndex,symbolType)
--         if node == nil then
--             node = self:getSlotNodeWithPosAndType(symbolType, 1, cloumnIndex, true)
--             slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_3 + 20, cloumnIndex * SYMBOL_NODE_TAG + 1)
--         else
--             local tmpSymbolType = self:convertSymbolType(symbolType)
--             node:setVisible(true)
--             node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3 + 20)
--             node:setTag(parentData.tag)
--             local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
--             node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
--             self:setSlotCacheNodeWithPosAndType(node, symbolType, 1, cloumnIndex, true)
--         end

--         -- local node = self:getSlotNodeWithPosAndType(self.SYMBOL_WILD_X6, rowIndex, cloumnIndex, true)
--         local posY = columnData.p_showGridH * 0.5

--         node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

--         node.p_slotNodeH = columnData.p_showGridH
--         node.p_symbolType = self.SYMBOL_WILD_X6
--         node.p_showOrder = parentData.order
--         node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        

--         if self.m_vecFillColWild == nil then
--             self.m_vecFillColWild = {}
--         end
--         self.m_vecFillColWild[#self.m_vecFillColWild + 1] = node

--         self:changeToMaskLayerSlotNode(node)

--         if i == #vecCol then
--             node:runAnim("actionframe2", false, function()
--                 -- effectData.p_isPlay = true
--                 -- self:playGameEffect()
--             end)
--         else
--             node:runAnim("actionframe2")
--         end
--     end
    
-- end

function CodeGameScreenAladdinMachine:lockWild(func, isReconnect)

    local vecLock = self.m_runSpinResultData.p_selfMakeData.lockWilds
    if isReconnect ~= true then
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_scatter_change_wild.mp3")
        vecLock = self.m_runSpinResultData.p_selfMakeData.newLockWilds
    end
    if vecLock == nil then
        if func ~= nil then
            func()
        end
        return
    end
    for i = 1, #vecLock, 1 do
        local index = vecLock[i]
        local pos = self:getRowAndColByPos(index)
        local targSp = self:getFixSymbol(pos.iY, pos.iX, SYMBOL_NODE_TAG)
        if targSp == nil and pos.iX == 1 then
            targSp = self:getFixSymbol(pos.iY, 0, SYMBOL_NODE_TAG)
        end
        if targSp ~= nil then
            local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            local slotParent = targSp:getParent()
            local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
            local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            self.m_clipParent:addChild(wild, REEL_SYMBOL_ORDER.REEL_ORDER_3, targSp:getTag())
            wild:setPosition(pos.x, pos.y)
            wild.p_cloumnIndex = targSp.p_cloumnIndex
            wild.p_rowIndex = targSp.p_rowIndex
            wild.m_isLastSymbol = targSp.m_isLastSymbol
            -- wild:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3)
            -- wild:setTag(SYMBOL_FIX_NODE_TAG)
            wild.m_symbolTag = SYMBOL_FIX_NODE_TAG
            wild.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local columnData = self.m_reelColDatas[wild.p_cloumnIndex]
            wild.p_slotNodeH = columnData.p_showGridH
            local linePos = {}
            for i = 1, 2, 1 do
                local row = wild.p_rowIndex + i - 1
                if row > 0 and row <= self.m_iReelRowNum then
                    linePos[#linePos + 1] = {iX = row, iY = wild.p_cloumnIndex}
                end
            end
            wild:setTag(self:getNodeTag(wild.p_cloumnIndex, wild.p_rowIndex, SYMBOL_NODE_TAG))
            wild.m_bInLine = true
            wild:setLinePos(linePos)

            if self.m_vecFixWild == nil then
                self.m_vecFixWild = {}
            end
            self.m_vecFixWild[#self.m_vecFixWild + 1] = wild
            if isReconnect == true then
                wild:runAnim("idleframe2", true)
            end
            self:operaBigSymbolShowMask(wild)
            if isReconnect ~= true then
                wild:setVisible(false)
                targSp:runAnim("actionframe3", false, function()
                    wild:setVisible(true)
                    wild:runAnim("actionframe2", false, function ()
                        wild:runAnim("idleframe2", true)
                    end)
                end)
            end
        end
    end
    performWithDelay(self, function()
        if func ~= nil then
            func()
        end
    end, 4)
    
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAladdinMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

---
--设置bonus scatter 层级
function CodeGameScreenAladdinMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_WILD_X6 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + 2
    elseif symbolType == self.SYMBOL_WILD_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + 1
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

-- 特殊信号下落时播放的音效
function CodeGameScreenAladdinMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = nil
        if self:isScatterSymbol(slotNode.p_symbolType) then
            soundType = "isScatterSymbol"
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil  and self.m_vecScatterSound[slotNode.p_cloumnIndex] ~= true then
                soundPath = self.m_scatterBulingSoundArry["auto"]
                self.m_vecScatterSound[slotNode.p_cloumnIndex] = true
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            soundType = slotNode.p_symbolType
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            end
        end
        if soundPath then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( iCol,soundPath,soundType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
            
        end
    end
end

local L_ABS = math.abs

function CodeGameScreenAladdinMachine:reelSchedulerCheckColumnReelDown(parentData, parentY, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        local colIndex = parentData.cloumnIndex
        local slotParentData = self.m_slotParents[colIndex]
        local slotParent = slotParentData.slotParent
        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end
            
            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            
            self:slotOneReelDown(colIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig 
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(colIndex, true, halfH)
            end

            if self:getGameSpinStage() == QUICK_RUN and self.m_hasBigSymbol == false then
            --播放滚动条落下的音效
            -- if parentData.cloumnIndex == self.m_iReelColumnNum then

            -- gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            end
            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(colIndex, true, halfH)

            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end
            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            local tipSlotNoes = {}
            self:foreachSlotParent(
                colIndex,
                function(index, realIndex, slotNode)
                    local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                    if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                        --播放关卡中设置的小块效果
                        self:playCustomSpecialSymbolDownAct( slotNode )

                        if self:isScatterSymbol(slotNode.p_symbolType) then
                            if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                                tipSlotNoes[#tipSlotNoes + 1] = slotNode
                            end
                        end
                    end
                end
            )

            
            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]

                    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPECIAL_BONUS)
                    self:playScatterBonusSound(slotNode)
                    slotNode:runAnim("buling")
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end
     
            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)
            
            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )


            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}
--设置bonus scatter 信息
function CodeGameScreenAladdinMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local columnSlotsList = self.m_reelSlotsList[column]  -- 提取某一列所有内容
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
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        local data = columnSlotsList[runLen + row]
        if data == nil then
            -- print("...")
        end
        if self:isScatterSymbol(data.p_symbolType) then
        
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

function CodeGameScreenAladdinMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if #showColTemp > 0 and col <= showColTemp[#showColTemp] then
        if nodeNum <= 1 then
            return runStatus.DUANG, false
        elseif nodeNum >= 2 then
            return runStatus.DUANG, true
        end
    else
        return runStatus.NORUN, false
    end
end

function CodeGameScreenAladdinMachine:isScatterSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_2
     or symbolType == self.SYMBOL_SCATTER_3 or symbolType == self.SYMBOL_SCATTER_4
     or symbolType == self.SYMBOL_SCATTER_5 or symbolType == self.SYMBOL_SCATTER_6 then
        return true
    end
    return false
end

function CodeGameScreenAladdinMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
            
    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
        if self:isScatterSymbol(enumSymbolType) == true then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
            
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

function CodeGameScreenAladdinMachine:compareScatterWinLines(winLines)

    for i=1,#winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex=1,#iconsPos do
            local posData = iconsPos[posIndex]
            
            local rowColData = self:getRowAndColByPos(posData)
                
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break  -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end
    end
end

function CodeGameScreenAladdinMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    local vecSymbols = {}
    -- self:operaBigSymbolMask(true)

    -- print("test  = "..#self.m_vecFsMoreScatter)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if not self.m_vecFsMoreScatter then
            self.m_vecFsMoreScatter = {}
        end
        for i = #self.m_vecFsMoreScatter, 1, -1 do
            -- 播放slot node 的动画
            local slotNode = self.m_vecFsMoreScatter[i]
            -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
            if slotNode ~= nil then--这里有空的没有管
    
                slotNode:setLineAnimName("actionframe2")
                slotNode = self:setSlotNodeEffectParent(slotNode)
    
                animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
    
                vecSymbols[#vecSymbols + 1] = slotNode
            end
            table.remove(self.m_vecFsMoreScatter, i)
        end
        self.m_vecFsMoreScatter = {}
    else
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
    
                slotNode:setLineAnimName("actionframe2")
                slotNode = self:setSlotNodeEffectParent(slotNode)
    
                animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
    
                vecSymbols[#vecSymbols + 1] = slotNode
            end
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, function()
        for i = 1, #vecSymbols, 1 do
            local lineNode = vecSymbols[i]
            lineNode:setLineAnimName("actionframe")
            lineNode:hideBigSymbolClip()
        end
        if callFun ~= nil then
            callFun()
        end
    end)

end

function CodeGameScreenAladdinMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        self:resetMaskLayerNodes()
        callFun()
    end, animTime, self:getModuleName())
end

function CodeGameScreenAladdinMachine:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if self:getInScatterShowCol(col) then 
            local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

        elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = self.m_reelRunInfo[col - 1]
            local diffLen = 12
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    end
    return len
end

function CodeGameScreenAladdinMachine:creatReelRunAnimation(col)
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

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)


    local reelEffectNodeBG = nil
    local reelActBG = nil
    if self.m_reelRunAnimaBG[col] == nil then
        reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
    else
        local reelBGObj = self.m_reelRunAnimaBG[col]

        reelEffectNodeBG = reelBGObj[1]
        reelActBG = reelBGObj[2]
    end

    reelEffectNodeBG:setScaleX(1)
    reelEffectNodeBG:setScaleY(1)

    reelEffectNodeBG:setVisible(true)
    util_csbPlayForKey(reelActBG, "ationframe", true)

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    local soundName = self.m_reelRunSound
    if col == 4 then
        soundName = "AladdinSounds/sound_Aladdin_qucik_run_4.mp3"
    end
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(soundName)
end

function CodeGameScreenAladdinMachine:createReelEffect(col)
    local csbName = self.m_reelEffectName .. ".csb"
    if col == 4 then
        csbName = self.m_reelEffectName .. "_2.csb"
    end
    local reelEffectNode, effectAct = util_csbCreate(csbName)
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenAladdinMachine:createReelEffectBG(col)
    local csbName = self.m_reelEffectName .. "_bg.csb"
    if col == 4 then
        csbName = self.m_reelEffectName .. "_bg_2.csb"
    end
    local reelEffectNode, effectAct = util_csbCreate(csbName)

    reelEffectNode:retain()
    effectAct:retain()

    self:findChild("rell"):addChild(reelEffectNode, 1)
    reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
    self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenAladdinMachine:initCloumnSlotNodesByNetData()
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    isUP = true
                    -- 判断 连续的大块 占位 type 的 个数 是否大于大块的长度
                    local totalCount = 1
                    for checkRowIndex = changeRowIndex + 1, rowCount do
                        local checkIndex = rowCount - checkRowIndex + 1
                        local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                        local checkType = checkRowDatas[colIndex]
                        if checkType == symbolType then
                            totalCount = totalCount + 1
                        else
                            break
                        end
                    end
                    if totalCount > symbolCount and totalCount % symbolCount > 0 then
                        symbolCount = symbolCount - totalCount % symbolCount
                    end
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    if symbolCount == sameCount then
                        break
                    end
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
                symbolCount = self.m_bigSymbolInfos[symbolType]
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

function CodeGameScreenAladdinMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        local rowIndex = resultLen 
        local isHaveBigSymbolIndex = false
        while rowIndex >= 1 do
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = reelData.p_reelResultSymbols[rowIndex]
            local stepCount = 1
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowCount then
                    isUP = true
                    -- 判断 连续的大块 占位 type 的 个数 是否大于大块的长度
                    local totalCount = 1
                    for checkRowIndex = changeRowIndex + 1, rowCount do
                        local checkIndex = rowCount - checkRowIndex + 1
                        local checkType = reelData.p_reelResultSymbols[checkIndex]
                        if checkType == symbolType then
                            totalCount = totalCount + 1
                        else
                            break
                        end
                    end
                    if totalCount > symbolCount and totalCount % symbolCount > 0 then
                        symbolCount = symbolCount - totalCount % symbolCount
                    end
                end
                for checkRowIndex = changeRowIndex + 1, rowCount do
                    if symbolCount == sameCount then
                        break
                    end
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkType = reelData.p_reelResultSymbols[checkIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowCount then
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
                symbolCount = self.m_bigSymbolInfos[symbolType]
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

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

            node.p_slotNodeH = reelColData.p_showGridH

            node.p_showOrder = showOrder

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * reelColData.p_showGridH + halfNodeH)
            rowIndex = rowIndex - stepCount
        end
    end
end

--[[
    @desc: 最后一列全是大块，滚动特殊处理
    author:{author}
    time:2020-03-30 14:32:32
    以下方法重写
]]

function CodeGameScreenAladdinMachine:operaNetWorkData()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})



    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i = 1, #self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)
        local preY = 0
        local isLastBigSymbol = false

        local _, realChildCount =
            self:foreachSlotParent(
            i,
            function(index, realIndex, child)
                local childY = child:getPositionY()
                local topY = nil
                local nodeH = child.p_slotNodeH or self.m_SlotNodeH
                if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                    local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                    topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
                    isLastBigSymbol = true
                else
                    topY = childY + nodeH * 0.5
                    isLastBigSymbol = false
                end

                if topY < preY and isLastBigSymbol == true then
                    isLastBigSymbol = false
                end
                preY = util_max(preY, topY)
            end
        )
        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if realChildCount == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY - moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    -- 检测假数据滚动时最后一个格子是否为 bigSymbol，
    -- 如果是那么其他列补齐到与最大bigsymbol同样的高度
    if lastNodeIsBigSymbol == true then
        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            local columnData = self.m_reelColDatas[i]
            local halfH = columnData.p_showGridH * 0.5

            local _, realChildCount = self:foreachSlotParent(i, nil)
            if realChildCount == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
                parentData.moveDiff = maxDiff
            end

            local parentY = slotParent:getPositionY()
            local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH

            moveL = moveL + maxDiff

            -- 补齐到长条高度
            local diffDis = maxDiff - math.abs(parentData.moveDiff)
            if self.m_configData.p_allBigSymbolCol[i] ~= nil and diffDis ~= 0 then
                moveL = moveL - diffDis
                diffDis = 0
            end
            if diffDis > 0 then
                local nodeCount = math.floor(diffDis / columnData.p_showGridH)

                for addIndex = 1, nodeCount do
                    local colIndex = parentData.cloumnIndex
                    local symbolType = self:getNormalSymbol(colIndex)
                    local node = self:getCacheNode(colIndex,symbolType)
                    if node == nil then
                        node = self:getSlotNodeWithPosAndType(symbolType, 1, 1, false)
                        local slotParentBig = parentData.slotParentBig
                        if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                            slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                        else
                            slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                        end
                    else
                        node:setVisible(true)
                        node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1)
                        node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
                        node:initSlotNodeByCCBName(ccbName, symbolType)
                        self:setSlotCacheNodeWithPosAndType(node, symbolType, 1, 1, false)
                    end

                    node.p_slotNodeH = columnData.p_showGridH
                    local posY = parentData.preY + (addIndex - 1) * columnData.p_showGridH + columnData.p_showGridH * 0.5
                    node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                    node:setPositionY(posY)
                end
            end

            parentData.moveDistance = parentY - moveL

            parentData.moveL = moveL
            parentData.moveDiff = nil
            self:createSlotNextNode(parentData)
        end
    else
        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            self:createSlotNextNode(parentData)
        end
    end
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

--[[
    @desc: 处理轮盘滚动中的快停，
    在快停前先检测各列需要补偿的nodecount 数量，一次来补齐各个高度同时需要考虑向下补偿的数量，这种处理
    主要是为了兼容长条模式
    time:2019-03-14 14:54:47
    @return:
]]
-- function CodeGameScreenAladdinMachine:operaQuicklyStopReel()
--     self:checkStopDelayTime()
--     local columnFillCounts = self:getColumnFillCounts()
--     local slotParentDatas = self.m_slotParents
--     local quickStopCol_CallFun = function(iCol)
--         local index = iCol
--         local reelRunData = self.m_reelRunInfo[index]

--         local parentData = slotParentDatas[index]
--         local slotParent = parentData.slotParent
--         local col = parentData.cloumnIndex
--         local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()
--         -- - self.m_iReelRowNum
--         --如果下个小块信号在最后一组 则不快停
--         --不在最后一组则触发快停
--         if self:checkColEnterLastReel(col) == false then
--             --改变下个创建信号
--             local fillCount = columnFillCounts[col]
--             if self.m_configData.p_allBigSymbolCol[col] ~= nil and fillCount == 1 and lastIndex % 2 == 0 then
--                 fillCount = 2
--             end
--             if lastIndex - fillCount ~= parentData.lastReelIndex then
--                 -- print(iCol .."列 调整前的开始位置" .. parentData.lastReelIndex)
--                 parentData.lastReelIndex = lastIndex - fillCount

--                 self:checkFillCountType(parentData, iCol, fillCount)

--                 -- print(iCol .."列 调整后的开始位置" .. parentData.lastReelIndex .. " 调整了几个位置 " ..fillCount )

--                 self:createSlotNextNode(parentData) -- 创建好下次需要滚动出来的小块

--                 --改变移动到目的地距离
--                 local lastNodeTopY = self:getSlotNodeChildsTopY(col)

--                 -- 这里计算fill count都是按照普通小块来计算的
--                 local columnData = self.m_reelColDatas[col]
--                 -- print(iCol .."列 调整前的坐标距离" ..  parentData.moveDistance .. "  " .. lastNodeTopY)

--                 parentData.moveDistance = -lastNodeTopY - fillCount * columnData.p_showGridH
--             -- print(iCol .."列 调整后的坐标距离" ..  parentData.moveDistance )
--             end
--         end
--     end

--     for i = 1, #slotParentDatas do
--         quickStopCol_CallFun(i)
--     end -- end for i=1,#slotParentDatas do
-- end

--[[
    @desc: 检测接下来需要补充的假信号是否是争取的， 主要是为了有大信号(占多个格子) 创建时出现问题
    time:2019-03-28 16:43:33
    @param fillCount 需要补充的信号数量
    @param col 对应列号
    @return:
]]
function CodeGameScreenAladdinMachine:checkFillCountType(parentData,col,fillCount )
    local beginIndex = parentData.lastReelIndex + 1
    local columnDatas = self.m_reelSlotsList[col]
    local lastIndex = self.m_reelRunInfo[col]:getReelRunLen()

    for checkIndex = beginIndex , beginIndex + fillCount - 1 do
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
        while true do
            symbolType = self:getReelSymbolType(parentData)
            if self.m_bigSymbolInfos[symbolType] == nil or self.m_configData.p_allBigSymbolCol[col] ~= nil then
                break
            end
        end

        if checkIndex > lastIndex then -- 这里用来保证不会影响到最终轮盘的结果， lastIndex 表明的是最后的假滚数据
            -- 如果不够补偿了 那么在多滚动几个保持补偿后的数量一致可以一起滚动停止
            table.insert( columnDatas, checkIndex ,symbolType )
        else
            local data = columnDatas[checkIndex]
            if data then
                if tolua.type(data) == "number" or self.m_bigSymbolInfos[data.p_symbolType] == nil then
                    columnDatas[checkIndex] = symbolType
                end
            end

        end
    end

    -- release_print("checkFillCountType  ....." .. col)
    -- dump(columnDatas)
    -- release_print("checkFillCountType  ..... END" .. col)
end

---
-- 将最终轮盘放入m_reelSlotsList
--
function CodeGameScreenAladdinMachine:setLastReelSymbolList()

    --- 将最终生成的盘面加入进去


    local iColumn = self.m_iReelColumnNum
    -- local iRow = self.m_iReelRowNum


    for cloumIndex=1,iColumn do
        local nodeCount = self.m_reelRunInfo[cloumIndex]:getReelRunLen()
        local columnData = self.m_reelColDatas[cloumIndex]
        local iRow = columnData.p_showGridCount
        
        if iRow == nil then  -- fix bug 可能是因为轮盘丢块导致的 2018-12-20 11:10:27
            iRow = self.m_iReelRowNum
        end

        local cloumnDatas = {}
        self.m_reelSlotsList[cloumIndex] = cloumnDatas

        local startIndex = nodeCount  -- 从假数据后面开始赋值
        
        for i=1,iRow  do
            local symbolValue = self.m_stcValidSymbolMatrix[i][cloumIndex] -- 循环提取每行中的某列¸
            local slotData = self:getSlotsReelData()

            slotData.m_isLastSymbol = true
            slotData.m_rowIndex = i
            slotData.m_columnIndex = cloumIndex
            slotData.p_symbolType = symbolValue--symbolValue.enumSymbolType
            
            if self.m_bigSymbolInfos[slotData.p_symbolType] ~= nil then
                slotData.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
                
                local symbolCount = self.m_bigSymbolInfos[slotData.p_symbolType]

                local totalCount = 1
                -- 将前面的也进行赋值
                if i == 1 then  -- 检测后面是否足够数量展示 symbol count
                    for checkIndex=2,iRow do
                        local checkType = self.m_stcValidSymbolMatrix[checkIndex][cloumIndex]
                        if symbolValue == checkType then
                            totalCount = totalCount + 1
                        else
                            break
                        end
                    end
                    -- 将前面需要变为大信号的地方全部设置为大信号，这样滚动时如果最终信号组跨列 那么现实也是正常的
                    if totalCount % symbolCount > 0 then
                        symbolCount = symbolCount - totalCount % symbolCount
                    else
                        symbolCount = 0
                    end
                    if symbolCount > 0 then
                        for addIndex=1,symbolCount do
                            local addSlotData = self:getSlotsReelData()
                            addSlotData.m_isLastSymbol = true
                            addSlotData.m_rowIndex = 1 - addIndex  -- 这里会是负数，因为创建长条的起始位置是从这里开始的， 所以针对于第一行是负数
                            addSlotData.m_columnIndex = cloumIndex
                            addSlotData.p_symbolType = symbolValue

                            slotData.m_showOrder = self:getBounsScatterDataZorder(slotData.p_symbolType )

                            cloumnDatas[startIndex + i - addIndex] = addSlotData
                        end
                    end
                end


            else
                slotData.m_showOrder = self:getBounsScatterDataZorder(slotData.p_symbolType )
            end

            cloumnDatas[startIndex + i] = slotData
        end

    end
end

---
-- 生成滚动序列
-- @param cloumGroupNums array 生成列对应组的数量 , 这个数量必须对应列的数量否则不执行
--
function CodeGameScreenAladdinMachine:produceReelSymbolList()

    if self.m_reelRunInfo == nil then
        return
    end

    local reelCount = #self.m_reelRunInfo  -- 共有多少列信息

    if reelCount ~= self.m_iReelColumnNum then
        assert(false,"reelCount  ！= self.m_iReelColumnNum")
        return
    end
    local bottomResList = self.m_runSpinResultData.p_resBottomTypes

    for cloumIndex = 1 , reelCount ,1  do
        local columnDatas = self.m_reelSlotsList[cloumIndex]
        local parentData = self.m_slotParents[cloumIndex]
        local columnData = self.m_reelColDatas[cloumIndex]
        parentData.lastReelIndex = columnData.p_showGridCount -- 从最初起始开始滚动
        

        if self.m_configData.p_allBigSymbolCol[cloumIndex] ~= nil then
            local totalCount = 0
            local index = 0
            for key, value in pairs(columnDatas) do
                totalCount = totalCount + 1
                index = math.max(index, key)
            end
            if parentData.beginReelIndex % 2 == 0 then
                parentData.beginReelIndex = parentData.beginReelIndex + 1
            end
            if totalCount ~= parentData.lastReelIndex then
                self.m_reelRunInfo[cloumIndex]:setReelRunLen(self.m_reelRunInfo[cloumIndex]:getReelRunLen() + 1)
                for i = 1, totalCount + 1, 1 do
                    columnDatas[index + 1] = columnDatas[index]
                    index = index - 1
                end
            end
            if parentData.beginReelIndex > #parentData.reelDatas then
                parentData.beginReelIndex = 1
            end
        end

        local nodeCount = self.m_reelRunInfo[cloumIndex]:getReelRunLen()

        -- local nodeList = {}
        for nodeIndex=1,nodeCount do
            
            -- 由于初始创建了一组数据， 所以跨过第一组从后面开始
            if nodeIndex >= 1 and nodeIndex <= parentData.lastReelIndex then
                columnDatas[nodeIndex] = 0
            else
                local symbolType = self:getReelSymbolType(parentData)  -- 根据规则随机产生信号
                -- 根据服务器传回来的数据获取 type ，检测是否是长条如果是长条不做处理 太麻烦了
                local bottomResType = nil
                if nodeIndex == nodeCount and bottomResList ~= nil and bottomResList[cloumIndex] ~= nil then
                    bottomResType = bottomResList[cloumIndex]
                    if self.m_bigSymbolInfos[bottomResType] ~= nil then
                        bottomResType = nil
                    end
                end
                if bottomResType ~= nil then
                    symbolType = bottomResType
                end

                if self.m_bigSymbolInfos[symbolType] ~= nil then
                    -- 大信号后面几个全部赋值为 symbolType  ******

                    if columnDatas[nodeIndex] == nil then

                        local addCount = self.m_bigSymbolInfos[symbolType]
                        local hasBigSymbol = false
                        for checkIndex=1,addCount do  -- 主要是判断后面是否有元素，如果有元素并且长度不足以放下长条元素则不再放置长条元素类型
                            local addedType= columnDatas[nodeIndex + checkIndex - 1]
                            if addedType ~= nil then
                                hasBigSymbol = true
                            end
                        end

                        if hasBigSymbol == false then -- 可以放置下长条元素，则直接将symbolType 赋值
                            for i=1,addCount do
                                columnDatas[nodeIndex + i - 1] = symbolType
                            end
                        else
                            for i=1,addCount do  -- 这里是在补充非长条小块
                                local checkType = columnDatas[nodeIndex + i - 1]
                                if checkType == nil then

                                    local addType = self:getReelSymbolType(parentData)
                                    local index = 1
                                    if DEBUG == 2 then
                                        -- release_print("657 begin  %d" , addType)
                                    end
                                    while true do
                                        if self.m_bigSymbolInfos[addType]== nil or self.m_configData.p_allBigSymbolCol[cloumIndex] ~= nil then
                                            break
                                        end
                                        index = index + 1
                                        
                                        addType = self:getReelSymbolType(parentData)
                                    end
                                    if DEBUG == 2 then
                                        release_print("668 begin")
                                    end
                                    columnDatas[nodeIndex + i - 1] = addType
                                end
                            end -- end for i=1,addCount do
                        end


                    end  -- end if columnDatas[nodeIndex] == nil then

                else
                    if columnDatas[nodeIndex] == nil then
                        columnDatas[nodeIndex] = symbolType
                    end
                end
                
            end
            
        end
        
        -- columnDatas[#columnDatas + 1] = nodeList

    end

end

---
-- 随机获取普通信号
--
function CodeGameScreenAladdinMachine:getNormalSymbol(col)
    local symbolType = self:MachineRule_getRandomSymbol(col)
    local index = 1
    if DEBUG == 2 then
        release_print("getNormalSymbol  begin")
    end
    while true do
        if DEBUG == 2 then
            index = index + 1
            if index == 120 then
                release_print("估计卡主了， 一直在while 循环")
            end
        end
        
        if self.m_bigSymbolInfos[symbolType] ~= nil and self.m_configData.p_allBigSymbolCol[col] ~= nil then
            break
        end
        if self.m_bigSymbolInfos[symbolType] ~= nil or 
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or
            symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then

            symbolType = self:MachineRule_getRandomSymbol(col)
        else
            break
        end
    end
    if DEBUG == 2 then
        release_print("getNormalSymbol  end")
    end
    return symbolType

end

return CodeGameScreenAladdinMachine






