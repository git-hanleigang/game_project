---
-- island li
-- 2019年1月26日
-- CodeGameScreenHallowinMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenHallowinMachine = class("CodeGameScreenHallowinMachine", BaseNewReelMachine)

CodeGameScreenHallowinMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenHallowinMachine.BREAK_BUBBLE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3

CodeGameScreenHallowinMachine.SYMBOL_FIX_TYPE = 95
CodeGameScreenHallowinMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenHallowinMachine.m_chipList = nil
CodeGameScreenHallowinMachine.m_playAnimIndex = 0
CodeGameScreenHallowinMachine.m_lightScore = 0

local RESPIN_NODE_ANIM_NAME = {"Number_Node", "Move_UP_Node", "Prize_Boost_Node", "YouLing_Node", "Pick_Add_Node"}

-- 构造函数
function CodeGameScreenHallowinMachine:ctor()
    BaseNewReelMachine.ctor(self)


    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_vecRsBtns = {}
    self.m_vecClickNodes = {}
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenHallowinMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("HallowinConfig.csv", "LevelHallowinConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  



function CodeGameScreenHallowinMachine:initUI()

    self.m_freeSpinTimesBar = util_createView("CodeHallowinSrc.HallowinFreespinBarView")
    self:findChild("tishitiao"):addChild(self.m_freeSpinTimesBar)
    self.m_freeSpinTimesBar:setVisible(false)
   
    self.m_jackpotBar = util_createView("CodeHallowinSrc.HallowinJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)

    self.m_progress = util_createView("CodeHallowinSrc.HallowinCollectProgress")
    self:findChild("progress"):addChild(self.m_progress)
    
    self.m_spinTimesBar = util_createView("CodeHallowinSrc.HallowinRespinBar")
    self:findChild("tishitiao"):addChild(self.m_spinTimesBar)
    self.m_spinTimesBar:setVisible(false)

    self.m_graveStone = util_createAnimation("Hallowin_xiaoshibei.csb")
    self:findChild("xiaoshibei"):addChild(self.m_graveStone)
    self.m_graveStone:playAction("idle")
    self:addClick(self.m_graveStone:findChild("click"))

    self.m_tipNode = util_createView("CodeHallowinSrc.HallowinTip")
    self:addChild(self.m_tipNode, GAME_LAYER_ORDER.LAYER_ORDER_TOUCH_LAYER)
    local posNode = self.m_graveStone:findChild("Node_tip")
    local pos = posNode:getParent():convertToWorldSpace(cc.p(posNode:getPosition()))
    self.m_tipNode:setPosition(pos)

    self.m_BubbleMainNode = cc.Node:create()
    self:findChild("reel"):addChild(self.m_BubbleMainNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 100)
    self:initBubble()

    self.m_guochangAnim = util_createView("CodeHallowinSrc.HallowinBonusGuochang")
    self:addChild(self.m_guochangAnim, GAME_LAYER_ORDER.LAYER_ORDER_TOUCH_LAYER)
    self.m_guochangAnim:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guochangAnim:setVisible(false)

    self.m_gameNode = self:findChild("gameNode")

    self.m_logo = util_spineCreate("Socre_Hallowin_danangua", true, true)
    self:findChild("Node_1"):addChild(self.m_logo)
    util_spinePlay(self.m_logo, "idleframe", true)

    self.m_spineGuochang = util_spineCreate("Socre_Hallowin_GuoChang", true, true)
    self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_spineGuochang:setVisible(false)

    self.m_vecParticles = {}

    local index = 1
    while true do
        local particle = self:findChild("Particle_"..index)
        if particle ~= nil then
            particle:stopSystem()
            self.m_vecParticles[#self.m_vecParticles + 1] = particle
        else
            break
        end
        index = index + 1
    end

    if self.m_machineRootScale < 0.67 then
        self.m_machineRootScale = 0.67
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
    end

    util_csbScale(self.m_gameBg.m_csbNode, self.m_machineRootScale)
    self:setReelRunSound("HallowinSounds/sound_Hallowin_quick_run.mp3")

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
        local soundName = "HallowinSounds/sound_Hallowin_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    self:runCsbAction("idle")
end

--默认按钮监听回调
function CodeGameScreenHallowinMachine:clickFunc(sender)
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "click" then
        if self.m_tipNode:isVisible() then
            self.m_tipNode:hideTip()
        else
            self.m_tipNode:showTip()
        end
        
    end
end

function CodeGameScreenHallowinMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "HallowinSounds/sound_Hallowin_scatter_down_" .. i .. ".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenHallowinMachine:showGuoChang(func)
    self.m_guochangAnim:showAnim(func)
end

function CodeGameScreenHallowinMachine:showSpineGuochang(func)
    self.m_spineGuochang:setVisible(true)
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_ghost_guochang.mp3")
    util_spinePlay(self.m_spineGuochang, "actionframe")
    util_spineEndCallFunc(self.m_spineGuochang, "actionframe", function()
        if func ~= nil then
            func()
        end
        self.m_spineGuochang:setVisible(false)
    end)
end

-- 断线重连 
function CodeGameScreenHallowinMachine:MachineRule_initGame(  )

end

function CodeGameScreenHallowinMachine:initFeatureInfo(spinData, featureData)

    if featureData.p_status == "CLOSED" then
        self.m_progress:resetProgress()
        if self.m_bProduceSlots_InFreeSpin ~= true then
            self:restAllBubble( )
        end
    elseif featureData.p_status == "OPEN" then
        self.isInBonus = true
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenHallowinMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Hallowin"  
end


function CodeGameScreenHallowinMachine:getBottomUINode()
    return "CodeHallowinSrc.HallowinBottomNode"
end

-- 继承底层respinView
function CodeGameScreenHallowinMachine:getRespinView()
    return "CodeHallowinSrc.HallowinRespinView"
end
-- 继承底层respinNode
function CodeGameScreenHallowinMachine:getRespinNode()
    return "CodeHallowinSrc.HallowinRespinNode"
end

----
--- 处理spin 成功消息
--
function CodeGameScreenHallowinMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "FEATURE" and spinData.result.action == "BONUS" then
        local features = spinData.result.features
        if #features > 1 then
            if features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
                self.m_runSpinResultData.p_freeSpinsTotalCount = spinData.result.freespin.freeSpinsTotalCount
                self.m_runSpinResultData.p_freeSpinsLeftCount = spinData.result.freespin.freeSpinsLeftCount

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
                --发送测试特殊玩法
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
            elseif features[2] == SLOTO_FEATURE.FEATURE_RESPIN then  -- 触发respin 玩法
                self.m_runSpinResultData.p_reSpinsTotalCount = spinData.result.respin.reSpinsTotalCount
                self.m_runSpinResultData.p_reSpinCurCount = spinData.result.respin.reSpinCurCount
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
            end
            
        end
    else
        BaseNewReelMachine.checkOperaSpinSuccess(self, param)
    end
end

function CodeGameScreenHallowinMachine:updateNetWorkData()
    
    if self.m_showFeatureEffect ~= true and #self.m_runSpinResultData.p_features > 1 and self.m_runSpinResultData.p_features[2] ~= 5 then
        local feature = self.m_runSpinResultData.p_features[2]
        local random = math.random(1, 100)
        if (random <= 20 and feature == SLOTO_FEATURE.FEATURE_FREESPIN) or (random <= 30 and feature == SLOTO_FEATURE.FEATURE_RESPIN) then
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_special_anim.mp3")
            self:runCsbAction("actionframe1")
            for i = 1, #self.m_vecParticles, 1 do
                local particle = self.m_vecParticles[i]
                particle:resetSystem()
            end
            util_spinePlay(self.m_logo, "fanv", true)
            self.m_showFeatureEffect = true
            performWithDelay(self, function ()
                BaseNewReelMachine.updateNetWorkData(self)
            end, 1)
        else
            BaseNewReelMachine.updateNetWorkData(self)
        end
    else
        BaseNewReelMachine.updateNetWorkData(self)
    end
    
end

function CodeGameScreenHallowinMachine:setReelRunInfo()
    if self.m_showFeatureEffect ~= true then
        BaseNewReelMachine.setReelRunInfo(self)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenHallowinMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_FIX_TYPE then
        return "Socre_Hallowin_PickOne"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Hallowin_10"
    end

   

    return nil
end

-- 给respin小块进行赋值
function CodeGameScreenHallowinMachine:setSpecialNodeScore(symbolNode)

    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end
    symbolNode:runAnim("dark")
    -- add 🎃
    -- local parent = symbolNode:getCcbProperty("Bonus")
    -- local nangua = parent:getChildByName("nangua")
    -- if nangua == nil then
    --     local node = util_spineCreate("Socre_Hallowin_NanGua", true, true)
    --     parent:addChild(node)
    --     node:setName("nangua")
    -- else
    --     nangua:setVisible(true)
    --     util_spinePlay(nangua, "idleframe")
    -- end
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenHallowinMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_TYPE then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenHallowinMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 

    local isplay= true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        local soundType = nil 
        for k = self.m_iReelRowNum, 1, -1 do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                soundType = "HaveFixSymbol"
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                symbolNode:runAnim("idleframe")
                local parent = symbolNode:getCcbProperty("Bonus")
                local node = parent:getChildByName("nangua")
                if node == nil then
                    node = util_spineCreate("Socre_Hallowin_NanGua", true, true)
                    parent:addChild(node)
                    node:setName("nangua")
                end
                node:setVisible(true)
                util_spinePlay(node, "buling")

                local lab = symbolNode:getCcbProperty("m_lb_index")
                if lab then
                    self.m_bonusNum = self.m_bonusNum + 1
                    lab:setString(self.m_bonusNum)
                end
            end
            if self.m_showFeatureEffect == true and self.m_stcValidSymbolMatrix[k][reelCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local symbolNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)
                symbolNode:runAnim("buling")
            end
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false
            -- respinbonus落地音效
            local soundPath = "HallowinSounds/sound_Hallowin_fall_" .. reelCol ..".mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath,soundType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
        end
    end
   
end

function CodeGameScreenHallowinMachine:slotReelDown()
    if self.m_showFeatureEffect == true then
        for i = 1, #self.m_vecParticles, 1 do
            local particle = self.m_vecParticles[i]
            particle:stopSystem()
        end
        self:runCsbAction("idle")
        if self.m_bProduceSlots_InFreeSpin ~= true then
            util_spinePlay(self.m_logo, "idleframe", true)
        else
            util_spinePlay(self.m_logo, "actionframe", true)
        end
        
        self.m_showFeatureEffect = false
        for iCol = 1, self.m_iReelColumnNum, 1 do
            for iRow = 1, self.m_iReelRowNum, 1 do
                local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                symbolNode:runAnim("idleframe")
            end
        end
    end
    BaseNewReelMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenHallowinMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenHallowinMachine:levelFreeSpinEffectChange()

    self.m_graveStone:setVisible(false)
    self.m_progress:setVisible(false)
    self:hideAllBubble()
    self.m_freeSpinTimesBar:setVisible(true)
    self.m_freeSpinTimesBar:changeFreeSpinByCount()
    self.m_jackpotBar:setMultip(tonumber(self.m_runSpinResultData.p_selfMakeData.jackpot))

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"free")
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenHallowinMachine:levelFreeSpinOverChangeEffect()
    
end
---------------------------------------------------------------------------


-- 触发freespin时调用
function CodeGameScreenHallowinMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinNewCount == 0 or self.m_runSpinResultData.p_freeSpinNewCount == 0 then
                effectData.p_isPlay = true
                self:playGameEffect()
                return
            end
            local soundID = gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_over.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                if soundID ~= nil then
                    gLobalSoundManager:stopAudio(soundID)
                    soundID = nil
                end
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            if self.m_winBigWinFlag == true then
                self.m_winBigWinFlag = false
            end
            self:showSpineGuochang(function()
                local soundID = gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_over.mp3")
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    if soundID ~= nil then
                        gLobalSoundManager:stopAudio(soundID)
                        soundID = nil
                    end
                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                    self.m_jackpotBar:mutilpEffect(tonumber(self.m_runSpinResultData.p_selfMakeData.jackpot), true)
                    performWithDelay(self, function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()       
                    end, 2)

                end)
            end)
            
            performWithDelay(self,function(  )
                self.m_graveStone:setVisible(false)
                self.m_progress:setVisible(false)
                self:hideAllBubble()
                self.m_freeSpinTimesBar:setVisible(true)
                self.m_freeSpinTimesBar:changeFreeSpinByCount()
                util_spinePlay(self.m_logo, "actionframe", true)
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"free")
            end, 1)
        end
    end

    performWithDelay(self,function(  )
        showFSView() 
    end,0.5)
end


-- 触发freespin结束时调用
function CodeGameScreenHallowinMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_fs_over.mp3")
    performWithDelay(self, function()
        local soundID = gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_over.mp3")

        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            -- 调用此函数才是把当前游戏置为freespin结束状态
            if soundID ~= nil then
                gLobalSoundManager:stopAudio(soundID)
                soundID = nil
            end
            self:triggerFreeSpinOverCallFun()
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.15,sy=1.15},492)

        performWithDelay(self,function(  )
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
            self.m_graveStone:setVisible(true)
            self.m_progress:setVisible(true)
            self.m_jackpotBar:setMultip(1)
            self:restAllBubble()
            self:updateBubbleVisible()
            util_spinePlay(self.m_logo, "idleframe", true)
            
            self.m_freeSpinTimesBar:setVisible(false)
        end, 0.5)
    end, 3)
    
end

function CodeGameScreenHallowinMachine:showRespinJackpot(index,coins,func)
    
    local jackPotWinView = util_createView("CodeHallowinSrc.HallowinJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
end

function CodeGameScreenHallowinMachine:addWinCionEffect()
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local winCoinPos = coinLab:getParent():convertToWorldSpace(cc.p(coinLab:getPosition()))
    

    if self.m_winLabEffect ~= nil then
        self.m_winLabEffect:removeFromParent()
        self.m_winLabEffect = nil
    end
    self.m_winLabEffect = util_createAnimation("Hallowin_jiesuankuang.csb")
    self:addChild(self.m_winLabEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_winLabEffect:setPosition(cc.p(winCoinPos.x, winCoinPos.y - 8))
    local particle = self.m_winLabEffect:findChild("Particle_1")
    particle:resetSystem()
    self.m_winLabEffect:playAction("actionframe", false, function()
        self.m_winLabEffect:setVisible(false)
    end)
end

-- 结束respin收集
function CodeGameScreenHallowinMachine:playLightEffectEnd()
    local lefPickResult = self.m_runSpinResultData.p_rsExtraData.lefPickResult
    for i = 1, #self.m_chipList, 1 do
        local symbolNode = self.m_chipList[i]
        if symbolNode.p_selectedID == nil then
            local result = lefPickResult[1]
            self:initRsNodeUI(result, symbolNode)
            symbolNode:runAnim("dark")
            table.remove(lefPickResult, 1)
        end
    end

    self:clearCurMusicBg()
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_end.mp3")
    performWithDelay(self, function()
        self:respinAccountAnim(1)
    end, 2)
end

function CodeGameScreenHallowinMachine:respinAccountAnim(respinAccountID)
    
    if respinAccountID > #self.m_chipList then
        -- 通知respin结束
        
        performWithDelay(self, function()
            
            self:respinOver()
            for i = 1, #self.m_chipList, 1 do
                local symbolNode = self.m_chipList[i]
                -- if symbolNode.p_lost == true then
                    -- symbolNode.p_lost = nil
                symbolNode:runAnim("idleframe")
                local parent = symbolNode:getCcbProperty("Bonus")
                local nangua = parent:getChildByName("nangua")
                if nangua ~= nil then
                    nangua:setVisible(true)
                    util_spinePlay(nangua, "idleframe")
                end
                -- end
            end
        end, 1)
        
        return
    end
    local symbolNode = self.m_chipList[respinAccountID] 
    if symbolNode.p_selectedID ~= nil then
        local result = self.m_runSpinResultData.p_rsExtraData.pickResult[symbolNode.p_selectedID]
        symbolNode.p_selectedID = nil
        symbolNode:runAnim("animation1")
        performWithDelay(self, function()
            respinAccountID = respinAccountID + 1
            self:respinAccountAnim(respinAccountID)
        end, 0.4)
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        self.m_lightScore = self.m_lightScore + result.multiple * totalBet
        performWithDelay(self, function()
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_over.mp3")
            -- self:addWinCionEffect()
            self:playCoinWinEffectUI()
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
        end, 0.2)
        
    else
        -- symbolNode.p_lost = true
        respinAccountID = respinAccountID + 1
        self:respinAccountAnim(respinAccountID)
    end
end

function CodeGameScreenHallowinMachine:playChipCollectAnim()
    self.m_bRespinClick = true
    self.m_spinTimesBar:respinChangePick(3)
    self.m_jackptLevel = #self.m_chipList
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_nangua_open.mp3")
    for i = 1, #self.m_chipList, 1 do
        local symbolNode = self.m_chipList[i]
        for j = 1, #RESPIN_NODE_ANIM_NAME, 1 do
            local node = symbolNode:getCcbProperty(RESPIN_NODE_ANIM_NAME[j])
            node:setVisible(false)
        end
        local parent = symbolNode:getCcbProperty("Bonus")
        local nangua = parent:getChildByName("nangua")
        if nangua ~= nil then
            util_spinePlay(nangua, "open")
        end
        symbolNode:runAnim("open", false, function()
            symbolNode:runAnim("idle1", true)
            nangua:setVisible(false)
            local btn = util_createView("CodeHallowinSrc.HallowinRespinBtn")
            parent:addChild(btn)
            btn:setClickCallBack(function()
                if self.m_bRespinClick ~= true then
                    return true
                end
                self.m_bRespinClick = false
                self.m_spinTimesBar:subPickNum()
                self:rsNodeClickAnim(symbolNode)
                return false
            end)
            self.m_vecRsBtns[i] = btn
        end)
    end
end

function CodeGameScreenHallowinMachine:rsNodeClickAnim(symbolNode)
    self.m_vecClickNodes[#self.m_vecClickNodes + 1] = symbolNode
    symbolNode.p_selectedID = #self.m_vecClickNodes
    local pickResult = self.m_runSpinResultData.p_rsExtraData.pickResult
    self.m_rsNodeNum = (self.m_rsNodeNum or 0) + 1
    local result = pickResult[self.m_rsNodeNum]
    self:initRsNodeUI(result, symbolNode, true)
    symbolNode:runAnim("animation0", false, function()
        self:showAnimByResult(result, symbolNode)
    end)
end

function CodeGameScreenHallowinMachine:showAnimByResult(result, symbolNode)
    local animCallFunc = function (...)
        local pickResult = self.m_runSpinResultData.p_rsExtraData.pickResult
        if self.m_rsNodeNum < #pickResult then
            self.m_bRespinClick = true
        else
            self:playLightEffectEnd()
        end
    end

    local index = tonumber(result.extraType) + 1
    local rewardName = RESPIN_NODE_ANIM_NAME[index]
    
    if rewardName ~= "Number_Node" then
        if rewardName ~= "Prize_Boost_Node" then
            local node = symbolNode:getCcbProperty("Number_Node")
            node:setVisible(true)
            symbolNode:runAnim("actionframe3", false, function()
                if rewardName == "YouLing_Node" then
                    local delayTime = 1
                    if self.m_spinTimesBar:getPickNum() == 0 then
                        delayTime = 2.5
                    end
                    performWithDelay(self, function()
                        animCallFunc()
                    end, delayTime)
                else
                    animCallFunc()
                end
            end)
        end
    else
        animCallFunc()
    end
    
    local startPos = util_getConvertNodePos(symbolNode, self)
    if rewardName == "Pick_Add_Node" then
        local endNode = self.m_spinTimesBar:getEndNode()
        self:createFlyParticle(startPos, endNode, function()
            self.m_spinTimesBar:addPickNum(result.extraAward)
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_update_times.mp3")
        end)
    elseif rewardName == "Move_UP_Node" then
        local endNode = self.m_jackpotBar:getEndNode(self.m_jackptLevel)
        self.m_jackptLevel = self.m_jackptLevel + 1
        self:createFlyParticle(startPos, endNode, function()
            self.m_jackpotBar:showSelectedAnim(self.m_jackptLevel)
        end)
    elseif rewardName == "Prize_Boost_Node" then
        self:boostAnim(startPos, endNode, result)
        
        performWithDelay(self, function()
            local node = symbolNode:getCcbProperty("Number_Node")
            node:setVisible(true)
            symbolNode:runAnim("actionframe3", false, function()
                animCallFunc()
            end)
        end, 0.3 * (#self.m_vecClickNodes - 1) + 0.5)
        
    elseif rewardName == "YouLing_Node" then
        self:createGhostFly(startPos, result)
    end
    
end

function CodeGameScreenHallowinMachine:initRsNodeUI(result, symbolNode, playSound)
    local index = tonumber(result.extraType) + 1
    local rewardName = RESPIN_NODE_ANIM_NAME[index]
    local node = symbolNode:getCcbProperty(rewardName)
    node:setVisible(true)
    self:initRsNodeCoin(result, symbolNode)
    if rewardName == "Pick_Add_Node" then
        self:initRsNodePick(result, symbolNode, playSound)
    end
    if playSound == true then
        if rewardName == "Number_Node" then
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_click_normal.mp3")
        else
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_click_special.mp3")
        end
    end
end

function CodeGameScreenHallowinMachine:initRsNodeCoin(result, symbolNode)
    local labCoin = symbolNode:getCcbProperty("m_lb_coins_1")
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local strCoin = util_formatCoins(result.multiple * totalBet, 3, false ,false, true)
    labCoin:setString(strCoin)

    local labLeftCoin = symbolNode:getCcbProperty("m_lb_coins_2")
    labLeftCoin:setString(strCoin)
end

function CodeGameScreenHallowinMachine:initRsNodePick(result, symbolNode, playSound)
    for i = 1, 3, 1 do
        local pickNum = symbolNode:getCcbProperty("add_"..i)
        if playSound ~= true then
            pickNum = symbolNode:getCcbProperty("dark_add_"..i)
        end
        if i ~= result.extraAward then
            pickNum:setVisible(false)
        else
            pickNum:setVisible(true)
        end
    end
end

function CodeGameScreenHallowinMachine:createFlyParticle(startPos, endNode, func)
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_particle_fly.mp3")
    local particle = cc.ParticleSystemQuad:create("effect/respin_L2.plist")
    self:addChild(particle, GAME_LAYER_ORDER.LAYER_ORDER_TOUCH_LAYER)
    particle:setPosition(startPos)
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    endNode = self:convertToNodeSpace(endPos)
    particle:runAction(cc.Sequence:create(cc.MoveTo:create(0.5, endPos), cc.CallFunc:create(function()
        if func ~= nil then
            func()
        end
        performWithDelay(self, function()
            particle:removeFromParent()
        end, 0.2)
    end)))
end

function CodeGameScreenHallowinMachine:createGhostFly(startPos, result)
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_gloden_ghost.mp3")
    local flyAnim = util_createAnimation("Socre_Hallowin_YouLing.csb")
    self:addChild(flyAnim, GAME_LAYER_ORDER.LAYER_ORDER_TOUCH_LAYER)
    flyAnim:setPosition(startPos)
    flyAnim:setScale(self.m_machineRootScale)
    local endNode = self.m_jackpotBar:getMultipEffectNode()
    local endPos = util_getConvertNodePos(endNode, self)
    flyAnim:playAction("actionframe")
    performWithDelay(self, function()
        util_playMoveToAction(flyAnim, 0.5, endPos,function()
            self.m_jackpotBar:mutilpEffect(result.extraAward)
            -- performWithDelay(self, function()
            --     self.m_jackpotBar:setMultip(result.extraAward)
            -- end, 0.5)
            flyAnim:removeFromParent()
        end)
    end, 0.5)
    
end

function CodeGameScreenHallowinMachine:boostAnim(startPos, endNode, result)
    local vecTempNodes = {}
    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = self.m_iReelRowNum, 1, -1 do
            for i = 1, #self.m_vecClickNodes - 1, 1 do
                local node = self.m_vecClickNodes[i]
                if node.p_cloumnIndex == iCol and node.p_rowIndex == iRow then
                    vecTempNodes[#vecTempNodes + 1] = node
                end
            end
        end
    end

    for i = 1, #vecTempNodes, 1 do
        local endNode = vecTempNodes[i]
        performWithDelay(self, function()
            self:createFlyParticle(startPos, endNode, function()
                gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_double.mp3")
                endNode:runAnim("actionframe4")
                local result = self.m_runSpinResultData.p_rsExtraData.pickResult[endNode.p_selectedID]
                result.multiple = result.multiple * 2
                self:initRsNodeCoin(result, endNode)
            end)
        end, 0.3 * (i - 1))
    end
end

--结束移除小块调用结算特效
function CodeGameScreenHallowinMachine:reSpinEndAction()    
    local jackpotNum = self.m_jackpotBar:getJackpotNum()
    if jackpotNum ~= nil and jackpotNum < #self.m_runSpinResultData.p_storedIcons then
        self.m_jackpotBar:showSelectedAnim(#self.m_runSpinResultData.p_storedIcons)
    end

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    self:playChipCollectAnim()
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenHallowinMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_SCORE_10,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenHallowinMachine:getRespinLockTypes( )
    local symbolList = 
    {
        {type = self.SYMBOL_FIX_TYPE, runEndAnimaName = "buling", bRandom = true},
    }

    return symbolList
end

function CodeGameScreenHallowinMachine:showRespinView(effectData)

     --先播放动画 再进入respin
    self:clearCurMusicBg()

    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_freeSpinTimesBar:setVisible(false)
    end

    self.m_progress:setVisible(false)
    self.m_graveStone:setVisible(false)
    self.m_spinTimesBar:setVisible(true)
    self.m_spinTimesBar:changeCount(self.m_runSpinResultData.p_reSpinCurCount)

    local num = #self.m_runSpinResultData.p_storedIcons

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()
     
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)

    performWithDelay(self, function()
        self.m_jackpotBar:showTriggerAnim(num, function()
            -- gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_update_times.mp3")
            -- self:runCsbAction("actionframe2", false, function()
                self:runCsbAction("idle")
                util_spinePlay(self.m_logo, "actionframe", true)
            -- end)
        end)
    end, 2.7)

    util_spinePlay(self.m_logo, "idleframe", true)
    
    self:hideAllBubble()
    
    -- self:runCsbAction("actionframe2", false, function()
    --     self:runCsbAction("idle")
    -- end)
    -- util_spinePlay(self.m_logo, "idleframe", true)

    --     --可随机的普通信息
    --     local randomTypes = self:getRespinRandomTypes( )

    --     --可随机的特殊信号 
    --     local endTypes = self:getRespinLockTypes()
        
    --     --构造盘面数据
    --     self:triggerReSpinCallFun(endTypes, randomTypes)

    
end

--ReSpin开始改变UI状态
function CodeGameScreenHallowinMachine:changeReSpinStartUI(respinCount)
    self.m_spinTimesBar:changeCount(respinCount)
end

--ReSpin刷新数量
function CodeGameScreenHallowinMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_spinTimesBar:changeCount(curCount)
    if curCount == 3 then
        gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_rs_update_times.mp3")
        self.m_spinTimesBar:addRsTimes()
        self.m_jackpotBar:showSelectedAnim(#self.m_runSpinResultData.p_storedIcons)
        self:runCsbAction("actionframe2", false, function()
            self:runCsbAction("idle")
        end)
    end
end

--ReSpin结算改变UI状态
function CodeGameScreenHallowinMachine:changeReSpinOverUI()

end

function CodeGameScreenHallowinMachine:showReSpinStart(func)
    if func ~= nil then
        func()
        self:resetMusicBg(true)
    end
end

function CodeGameScreenHallowinMachine:showRespinOverView(effectData)

    local soundID = gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_over.mp3")
    -- 恢复界面 泡泡
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_freeSpinTimesBar:setVisible(true)
    else
        self.m_jackpotBar:setMultip(1)
        self:restAllBubble()
        self:updateBubbleVisible()
        self.m_progress:setVisible(true)
        self.m_graveStone:setVisible(true)

        performWithDelay(self, function()
            util_spinePlay(self.m_logo, "idleframe", true)
        end, 0.5)
    end
    
    self.m_spinTimesBar:setVisible(false)
    self.m_jackpotBar:showIdle()

    local jackpotWinCoin = self.m_runSpinResultData.p_selfMakeData.jackpotWin
    local strCoins = self.m_serverWinCoins - jackpotWinCoin

    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"] = self.m_jackptLevel
    ownerlist["m_lb_coins"] = util_formatCoins(jackpotWinCoin, 30)
    ownerlist["m_lb_coins_2"] = util_formatCoins(strCoins, 30)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER,ownerlist, function()
        if soundID ~= nil then
            gLobalSoundManager:stopAudio(soundID)
            soundID = nil
        end
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self:resetMusicBg() 
    end)


    -- gLobalSoundManager:playSound("HallowinSounds/music_Hallowin_linghtning_over_win.mp3")
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.15,sy=1.15}, 492)

    local node2 = view:findChild("m_lb_coins_2")
    view:updateLabelSize({label=node2,sx=1.15,sy=1.15}, 492)
end


-- --重写组织respinData信息
function CodeGameScreenHallowinMachine:getRespinSpinData()
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

function CodeGameScreenHallowinMachine:updateReelGridNode(node)
    if self.m_showFeatureEffect == true then
        if node.p_symbolType ~= self.SYMBOL_FIX_TYPE and node.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self:setSpecialNodeScore(node)
        end
    end
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenHallowinMachine:MachineRule_SpinBtnCall()
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_rsNodeNum = 0
    self.m_bonusNum = 0
    for i = #self.m_vecRsBtns, 1, -1 do
        local btn = self.m_vecRsBtns[i]
        btn:removeFromParent()
        table.remove(self.m_vecRsBtns, i)
    end
    for i = #self.m_vecClickNodes, 1, -1 do
        table.remove(self.m_vecClickNodes, i)
    end

    if self.m_winBigWinFlag == true then
        self.m_winBigWinFlag = false
        util_spinePlay(self.m_logo, "idleframe", true)
    end

    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    return false -- 用作延时点击spin调用
end




function CodeGameScreenHallowinMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            self:resetMusicBg()
            if not self.isInBonus then
                self:setMinMusicBGVolume( )
            end
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenHallowinMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:updateProgressVisible()
    self:updateBubbleVisible()
    BaseNewReelMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    self.m_slotEffectLayer:setOpacity(255)
    util_setCascadeOpacityEnabledRescursion(self, true)

    if self.m_bProduceSlots_InFreeSpin == true then
        util_spinePlay(self.m_logo, "actionframe", true)
    end

    self.m_tipNode:showTip()
end

function CodeGameScreenHallowinMachine:addObservers()
	BaseNewReelMachine.addObservers(self)

end

function CodeGameScreenHallowinMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)  	-- 必须调用不予许删除
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
function CodeGameScreenHallowinMachine:MachineRule_network_InterveneSymbolMap()

end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenHallowinMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据
    
end

function CodeGameScreenHallowinMachine:showEffect_NewWin(effectData,winType)
    BaseNewReelMachine.showEffect_NewWin(self, effectData, winType)
    if self.m_bProduceSlots_InFreeSpin ~= true then
        self.m_winBigWinFlag = true
        util_spinePlay(self.m_logo, "actionframe", true)
    end
    
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenHallowinMachine:addSelfEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local newCollect = selfdata.newCollect or {}
    
    if #newCollect > 0 then

        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BREAK_BUBBLE_EFFECT -- 动画类型
        
    end
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
function CodeGameScreenHallowinMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.BREAK_BUBBLE_EFFECT then

        -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_BubbleBreak.mp3")
        self:updateBubbleVisible( true )
        -- performWithDelay(self,function(  )
            self:createCollectBubbleAct( function(  )
                effectData.p_isPlay = true
                self:playGameEffect()
            end )
        -- end, 0.5)
    end

    
	return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenHallowinMachine:showBonusGameView(effectData)
   
    self:clearCurMusicBg()
    -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_TriggerBonus.mp3")
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    performWithDelay(self, function()
        self.m_progress:completedAnim()
        self.m_graveStone:playAction("actionframe", false, function()
            self:showGuoChang(function()
                local bonusView = util_createView("CodeHallowinSrc.HallowinBonusGameView")
                bonusView:setOverCallFunc(function(coins)
                    self:showBonusGameOverView(coins, function()
                        self:showGuoChang(function()
                            self:resetMusicBg()
                            effectData.p_isPlay = true
                            self:playGameEffect() -- 播放下一轮
                        end)
                        performWithDelay(self, function()
                            self:restAllBubble()
                            self.m_progress:resetProgress()
                            util_playFadeInAction(self.m_gameNode, 0.5)   
                            self.m_graveStone:findChild("Particle_1"):resetSystem()
                            self.m_bottomUI:hideAverageBet()
                            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
                        end, 1)
                    end)
                end)
                self:findChild("bonusNode"):addChild(bonusView)
                bonusView:setPosition(-display.width * 0.5, -display.height * 0.5)
                gLobalSoundManager:playBgMusic("HallowinSounds/music_Hallowin_rs_bgm.mp3")
            end)
            
            performWithDelay(self, function()
                util_playFadeOutAction(self.m_gameNode, 0.5)    
                self.m_graveStone:findChild("Particle_1"):stopSystem()
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"bonus")
                self.m_bottomUI:showAverageBet()
            end, 1)
        end)
    end, 0.5)
end

function CodeGameScreenHallowinMachine:showBonusGameOverView(totalWinCoins, func)
    local soundID = gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_bonus_over.mp3")
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(totalWinCoins, 30)
    local view = self:showDialog("BonusGameOver",ownerlist,function ()
        if soundID ~= nil then
            gLobalSoundManager:stopAudio(soundID)
            soundID = nil
        end
        local oldCoins = globalData.slotRunData.lastWinCoin 
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{totalWinCoins,true,true})
        globalData.slotRunData.lastWinCoin = oldCoins

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{totalWinCoins, GameEffect.EFFECT_BONUS})

        if func ~= nil then
           func() 
        end
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.317,sy=1.317}, 425)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenHallowinMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenHallowinMachine:checktriggerSpecialGame( )
    local istrigger = false

    local features =  self.m_runSpinResultData.p_features

    if features then
       if #features > 1 and features[2] ~= 5 then
            istrigger = true
       end
    end

    return istrigger
end

---
--连线收集玩法

function CodeGameScreenHallowinMachine:initBubble( )
    
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local bubble = util_createAnimation("Socre_Hallowin_ZhiZhuWang.csb")
            local index = self:getPosReelIdx(iRow ,iCol,NORMAL_ROW_COUNT)
            self.m_BubbleMainNode:addChild(bubble,index,index)    
            local pos = cc.p(util_getOneGameReelsTarSpPos(self,index ) )  
            bubble:setPosition(pos)
        end
    end

end

function CodeGameScreenHallowinMachine:updateProgressVisible()
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    self.m_progress:initProgress(#collectPosition)
end

function CodeGameScreenHallowinMachine:restAllBubble( )
    local childs = self.m_BubbleMainNode:getChildren()
    for i = 1,#childs do
        local bubble = childs[i]
        if bubble then
            bubble:setVisible(true)
            bubble:runCsbAction("idle")
            
        end
    end
end

function CodeGameScreenHallowinMachine:hideAllBubble()
    local childs = self.m_BubbleMainNode:getChildren()
    for i = 1,#childs do
        local bubble = childs[i]
        if bubble then
            bubble:setVisible(false)
        end
    end
end

function CodeGameScreenHallowinMachine:updateBubbleVisible( isAct )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}

    for i = 1,#collectPosition do
        local pos = collectPosition[i]
        local bubble = self.m_BubbleMainNode:getChildByTag(pos)
        if bubble then
            if isAct then
                bubble:runCsbAction("actionframe",false,function(  )
                    bubble:setVisible(false)
                end)
            else
                bubble:setVisible(false)
            end
        end
    end

    
end

function CodeGameScreenHallowinMachine:createCollectBubbleAct( func )
    

    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_collect_ghost.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}
    local waitTime = 0.5

    local currTable = {}
    
    for i=1,#newCollect do
        local index = newCollect[i]

        local fixPos = self:getRowAndColByPos(index)

        if currTable[fixPos.iY] == nil then
            currTable[fixPos.iY] = {}
        end
        table.insert(currTable[fixPos.iY],index)
    end

    local actTable = {}

    for iCol =1,self.m_iReelColumnNum do
        local data = currTable[iCol]
        if data  then
            for iRow = 1,#data do
                table.insert(actTable,data[iRow])
            end
            
        end
    end

    

    local actMainNode = cc.Node:create()
    self:findChild("reel"):addChild(actMainNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

    for i=1,#actTable do
        local startIndex = actTable[i]

        local actNdoe = util_createAnimation("Hallowin_gost_fly.csb")
        actNdoe:runCsbAction("shouji")
        local flyNode = cc.Node:create()
        flyNode:addChild(actNdoe)
        actMainNode:addChild(flyNode, 1)
        
        local particle1 = cc.ParticleSystemQuad:create("effect/zhizhuwang.plist")
        actMainNode:addChild(particle1)

        local particle2 = cc.ParticleSystemQuad:create("effect/zhizhuwang2.plist")
        actMainNode:addChild(particle2)
        
        
        local StartPos = cc.p(util_getOneGameReelsTarSpPos(self,startIndex)) 
        local endPos = cc.p(util_getConvertNodePos(self.m_progress:getEndNode(i),flyNode)) 

        flyNode:setPosition(StartPos)
        particle1:setPosition(StartPos)
        particle2:setPosition(StartPos)

        local distance = cc.pGetDistance(StartPos, endPos)
        local height = endPos.y - StartPos.y
        local angle = math.deg(math.asin(height / distance ))
        if endPos.x < StartPos.x then
            angle = 270 + angle
        else
            angle = 90 - angle
        end
        -- actNdoe:setRotation(angle)

        util_playMoveToAction(flyNode,waitTime,endPos,function(  )
            flyNode:setVisible(false)
        end)

        util_playMoveToAction(particle1,waitTime,endPos,function(  )
            -- particle1:setVisible(false)
        end)

        util_playMoveToAction(particle2,waitTime,endPos,function(  )
            -- particle2:setVisible(false)
        end)
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        scheduler.performWithDelayGlobal(function (  )
            actMainNode:removeFromParent()
    
            self.m_progress:updateProgress(#actTable)
            
            if func then
                if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
                    performWithDelay(self, function()
                        func()
                    end, 1)
                else
                    func()
                end
            end
        end,waitTime,self:getModuleName())
    else
        scheduler.performWithDelayGlobal(function ()
            actMainNode:removeFromParent()
            self.m_progress:updateProgress(#actTable)
            if func then
                if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
                    performWithDelay(self, function()
                        func()
                    end, 1)
                end
            end
        end,waitTime,self:getModuleName())
        if func then
            if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false then
                func()
            end
        end
    end
end

return CodeGameScreenHallowinMachine






