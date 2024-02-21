

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenWheelOfRhinoMachine = class("CodeGameScreenWheelOfRhinoMachine", BaseNewReelMachine)

CodeGameScreenWheelOfRhinoMachine.SYMBOL_SCORE_10 = 9  -- 自定义的小块类型
CodeGameScreenWheelOfRhinoMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenWheelOfRhinoMachine.SYMBOL_SCORE_SCATTERMORE = 91
CodeGameScreenWheelOfRhinoMachine.SYMBOL_SCORE_SCATTERMOHU = 95
CodeGameScreenWheelOfRhinoMachine.SYMBOL_SCORE_WILD2 = 102
CodeGameScreenWheelOfRhinoMachine.SYMBOL_SCORE_WILD3 = 103

-- 构造函数
function CodeGameScreenWheelOfRhinoMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_enterGameMusicIsComplete = false--进关音乐是否播完
    self.m_isFeatureOverBigWinInFree = true

	self:initGame()
end

function CodeGameScreenWheelOfRhinoMachine:initGame()
	--初始化基本数据
	self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
function CodeGameScreenWheelOfRhinoMachine:getModuleName()
    return "WheelOfRhino"
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenWheelOfRhinoMachine:getRunStatus(col, nodeNum, showCol)
    --设置滚动状态
    local runStatus = 
    {
        DUANG = 1,
        NORUN = 2,
    }
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp] then
        if nodeNum >= 4 then
            return runStatus.DUANG, true
        else
            return runStatus.NORUN, false
        end
    else
        if nodeNum >= 4 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end
--创建快滚特效背景
function CodeGameScreenWheelOfRhinoMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode)
        reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end

end
function CodeGameScreenWheelOfRhinoMachine:initUI()
    self.m_gameBg:setPosition(cc.p(display.width/2,display.height/2 + self.m_machineNode:getPositionY()))
    self.m_gameBg:setScale(self.m_machineRootScale)
    self:initFreeSpinBar()
    --添加背景牛
    self.m_beijingNiu = util_spineCreate("Socre_RagingRhino_guochang",true,true)
    self.m_gameBg:findChild("niuNode"):addChild(self.m_beijingNiu)
    --添加背景草
    self.m_beijingCao = util_spineCreate("Socre_RagingRhino_cao",true,true)
    self.m_gameBg:findChild("niuNode"):addChild(self.m_beijingCao)
    self:playBgXiniuAni()

    --添加logo
    local logoNode = util_createAnimation("WheelOfRhino_logo.csb")
    self:findChild("logo"):addChild(logoNode)
    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeWheelOfRhinoSrc.WheelOfRhinoJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)
    --添加freespin计数条
    self.m_freespinBar = util_createView("CodeWheelOfRhinoSrc.WheelOfRhinoFreespinBarView")
    self:findChild("freespinNode"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)
    --添加过场犀牛
    self.m_guochang = util_spineCreate("Socre_RagingRhino_guochang",true,true)
    self.m_guochang:setPosition(display.center)
    self:addChild(self.m_guochang,GAME_LAYER_ORDER.LAYER_ORDER_EFFECT)
    self.m_guochang:setVisible(false)
    --添加白光过场
    self.m_baiguangGuochang = util_createAnimation("WheelOfRhino_wheel_guochang.csb")
    self.m_baiguangGuochang:setPosition(display.center)
    self:addChild(self.m_baiguangGuochang,GAME_LAYER_ORDER.LAYER_ORDER_EFFECT + 1)
    self.m_baiguangGuochang:setVisible(false)
end
--适配
function CodeGameScreenWheelOfRhinoMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize() --h 120
    local uiBW, uiBH = self.m_bottomUI:getUISize()  --h 180
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height/display.width == DESIGN_SIZE.height/DESIGN_SIZE.width then
        --设计尺寸屏

    elseif display.height/display.width > DESIGN_SIZE.height/DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 40--顶部条凹下去距离 在宽屏中会被用的尺寸
        local bottomMoveH = 30--底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH )/(mainHeight + topAoH - bottomMoveH)--有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH ) / (DESIGN_SIZE.height - uiH - uiBH + topAoH )--有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height/2 - uiBH) * mainScale--设计离下条距离
        local dis = (display.height/2 - uiBH)--实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end
--播放背景犀牛动画
function CodeGameScreenWheelOfRhinoMachine:playBgXiniuAni()
    self.m_beijingNiu:setAnimation(0, "idleframe", false)
    self.m_beijingCao:setAnimation(0, "idleframe", false)
    util_spineEndCallFunc(self.m_beijingNiu,"idleframe",function ()
        local rand = math.random(0,10)
        if rand < 3 then
            self.m_beijingNiu:setAnimation(0, "idlefreme2", false)
            self.m_beijingCao:setAnimation(0, "idleframe2", false)
            util_spineEndCallFunc(self.m_beijingNiu,"idlefreme2",function ()
                self:playBgXiniuAni()
            end)
        else
            self:playBgXiniuAni()
        end
    end)
end

function CodeGameScreenWheelOfRhinoMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            self.m_enterGameMusicIsComplete = true
            self:resetMusicBg()
            if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
                self:setMinMusicBGVolume()
            end
        end,2.5,self:getModuleName())
    end,0.4,self:getModuleName())
end
-- 重置当前背景音乐名称
function CodeGameScreenWheelOfRhinoMachine:resetCurBgMusicName()
    if self.m_enterGameMusicIsComplete == false then
        return nil
    end
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
    elseif self:getCurrSpinMode() == REWAED_SPIN_MODE then
        self.m_currentMusicBgName = "WheelOfRhinoSounds/music_WheelOfRhino_WheelBG.mp3"
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
--进关数据初始化
function CodeGameScreenWheelOfRhinoMachine:initGameStatusData(gameData)
    --大于一倍的wild变成对应的信号块
    if gameData.spin then
        if gameData.spin.action == "FREESPIN" then
            local reelsData = gameData.spin.reels
            if gameData.spin.selfData and gameData.spin.selfData.wildMul then
                local wildMulTab = gameData.spin.selfData.wildMul
                for i,v in ipairs(wildMulTab) do
                    local pos = v[1]
                    local mul = v[2]
                    if mul > 1 then
                        local rowNum = #reelsData
                        local colNum = #reelsData[1]
                        reelsData[math.floor(pos/colNum) + 1][math.floor(pos%colNum) + 1] = 100 + mul
                    end
                end
            end
        end
    end

    --将feature 跟spin合并 并删除feature
    if gameData.feature then
        table_merge(gameData.spin,gameData.feature)
        self.m_feature = gameData.feature
        gameData.feature = nil
    end

    CodeGameScreenWheelOfRhinoMachine.super.initGameStatusData(self,gameData)
end
----
--- 处理spin 成功消息
--
function CodeGameScreenWheelOfRhinoMachine:checkOperaSpinSuccess( param )
    --大于一倍的wild变成对应的信号块
    if param[2].result then
        if param[2].result.action == "FREESPIN" then
            local reelsData = param[2].result.reels
            if param[2].result.selfData and param[2].result.selfData.wildMul then
                local wildMulTab = param[2].result.selfData.wildMul
                for i,v in ipairs(wildMulTab) do
                    local pos = v[1]
                    local mul = v[2]
                    if mul > 1 then
                        local rowNum = #reelsData
                        local colNum = #reelsData[1]
                        reelsData[math.floor(pos/colNum) + 1][math.floor(pos%colNum) + 1] = 100 + mul
                    end
                end
            end
        end
    end

    CodeGameScreenWheelOfRhinoMachine.super.checkOperaSpinSuccess(self,param)
end
function CodeGameScreenWheelOfRhinoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)
    self:addObservers()
end

function CodeGameScreenWheelOfRhinoMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_bIsBigWin then
            return
        end

        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 3
        else
            soundIndex = 3
            soundTime = 3
        end

        local soundName = "WheelOfRhinoSounds/music_WheelOfRhino_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:bonusOver()
    end,"CodeGameScreenWheelOfRhinoMachine_bonusOver")
end

function CodeGameScreenWheelOfRhinoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWheelOfRhinoMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WheelOfRhino_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_WheelOfRhino_11"
    elseif symbolType == self.SYMBOL_SCORE_SCATTERMORE then
        return "Socre_WheelOfRhino_Scatter1"
    elseif symbolType == self.SYMBOL_SCORE_SCATTERMOHU then
        return "Socre_WheelOfRhino_ScatterMohu"
    elseif symbolType == self.SYMBOL_SCORE_WILD2 then
        return "Socre_WheelOfRhino_Wild2"
    elseif symbolType == self.SYMBOL_SCORE_WILD3 then
        return "Socre_WheelOfRhino_Wild3"
    end
    return nil
end

----------------------------- 玩法处理 -----------------------------------
-- 断线重连 
function CodeGameScreenWheelOfRhinoMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        --轮盘动画
        self:runCsbAction("freespin")
        --背景动画
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
        self.m_freespinBar:setVisible(true)
        self.m_freespinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount - self.m_runSpinResultData.p_freeSpinNewCount,self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinNewCount )
        self.m_fsLastWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    end
    if self.m_runSpinResultData.p_bonusStatus == "OPEN" then
        -- 添加bonus effect
        local bonusEffect = GameEffectData.new()
        bonusEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusEffect
        bonusEffect.isReconnection = true
    end
end

--所有滚轴停止调用
function CodeGameScreenWheelOfRhinoMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    CodeGameScreenWheelOfRhinoMachine.super.slotReelDown(self)
end
--
--单列滚动停止回调
--
function CodeGameScreenWheelOfRhinoMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol)
    for row = 1,self.m_iReelRowNum do
        local slotNode = self:getFixSymbol(reelCol,row,SYMBOL_NODE_TAG)
        if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if slotNode.isBuling ~= true then
                slotNode:runAnim("idleframe1",true)
            end
            slotNode.isBuling = nil
        end
        if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_SCATTERMORE then
            slotNode:runAnim("buling",false)

            local soundPath = "WheelOfRhinoSounds/music_WheelOfRhino_Scatter.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

        end
    end
end
--播放提示动画
function CodeGameScreenWheelOfRhinoMachine:specialSymbolActionTreatment(slotNode)
    slotNode.isBuling = true
    slotNode:runAnim("buling",false,function ()
        slotNode:runAnim("idleframe1",true)
    end)
end
function CodeGameScreenWheelOfRhinoMachine:setScatterDownScound()
    --底层播音效是数图标数量的，不是按列来的(⊙_⊙)?
    for i = 1, 20 do
        local soundPath = nil
        soundPath = "WheelOfRhinoSounds/music_WheelOfRhino_Scatter.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWheelOfRhinoMachine:addSelfEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local featureDatas = self.m_runSpinResultData.p_features
        if not featureDatas then
            return
        end
        for i=1,#featureDatas do
            local featureId = featureDatas[i]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.COLLECT_FREESPIN_EFFECT
            end
        end
    end
 end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWheelOfRhinoMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_FREESPIN_EFFECT then
        performWithDelay(self,function ()
            for row = 1,self.m_iReelRowNum do
                for col = 1,self.m_iReelColumnNum do
                    local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                    if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_SCATTERMORE then
                        slotNode:runAnim("actionframe",false)
                    end
                end
            end
            self:collectFreespinNum()
        end,0.5)
    end
	return true
end
--收集freespin次数
function CodeGameScreenWheelOfRhinoMachine:collectFreespinNum()
    local flyTime = 0
    for row = 1,self.m_iReelRowNum do
        for col = 1,self.m_iReelColumnNum do
            local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_SCATTERMORE then
                local flyNode = util_createAnimation("Socre_WheelOfRhino_Scatter1_jia1.csb")
                flyNode:playAction("actionframe",false)
                self.m_freespinBar:addChild(flyNode)
                local startWorldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(row,col))
                local startPos = self.m_freespinBar:convertToNodeSpace(startWorldPos)
                flyNode:setPosition(startPos)
                local endWorldPos = self.m_freespinBar:findChild("BitmapFontLabel_1_0"):getParent():convertToWorldSpace(cc.p(self.m_freespinBar:findChild("BitmapFontLabel_1_0"):getPosition()))
                local endPos = self.m_freespinBar:convertToNodeSpace(endWorldPos)
                flyTime = util_csbGetAnimTimes(flyNode.m_csbAct,"actionframe")
                local delay = cc.DelayTime:create(7/30)
                local moveTo = cc.MoveTo:create(flyTime - 7/30,endPos)
                local func = cc.CallFunc:create(function ()
                    flyNode:removeFromParent()
                end)
                local seq = cc.Sequence:create(delay,moveTo,func)
                flyNode:runAction(seq)
                -- flyNode:findChild("Particle_1"):setPositionType(0)
                -- flyNode:findChild("Particle_1"):resetSystem()
            end
        end
    end
    if flyTime > 0 then
        gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_collectfreefly.mp3")
    end
    performWithDelay(self,function ()
        gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_collectfreeflyover.mp3")
        self.m_freespinBar:runCsbAction("actionframe_zengzhang",false)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT ,self.COLLECT_FREESPIN_EFFECT})
    end,flyTime)
end
-- 通知某种类型动画播放完毕
function CodeGameScreenWheelOfRhinoMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i=1,effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end

end
--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenWheelOfRhinoMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
--连线效果动画
function CodeGameScreenWheelOfRhinoMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    local delayTime = self:showLineFrame()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5 + delayTime)
    else
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, delayTime)
    end
    return true
end
--显示连线
function CodeGameScreenWheelOfRhinoMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime()

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()

    local function showLine()
        self:checkNotifyUpdateWinCoin()
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
            if #winLines > 1 then
                self:showAllFrame(winLines)
                showLienFrameByIndex()
            else
                self:showLineFrameByIndex(winLines,1)
            end
        end
    end

    local delayTime = 0
    -- for i=1,#self.m_lineSlotNodes do
    --     local slotsNode = self.m_lineSlotNodes[i]
    --     if slotsNode ~= nil and 
    --         (slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD
    --             or slotsNode.p_symbolType == self.SYMBOL_SCORE_WILD2
    --             or slotsNode.p_symbolType == self.SYMBOL_SCORE_WILD3) then
    --         slotsNode:runAnim("actionframe1",false)
    --         delayTime = 60/30
    --     end
    -- end
    if delayTime > 0 then
        performWithDelay(self,function ()
            showLine()
        end,delayTime)
    else
        showLine()
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        delayTime = delayTime + 1
    end
    return delayTime
end
--信号块刷新时调用
function CodeGameScreenWheelOfRhinoMachine:updateReelGridNode(node)
    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD 
        or node.p_symbolType == self.SYMBOL_SCORE_WILD2 
        or node.p_symbolType == self.SYMBOL_SCORE_WILD3 then
        node:runIdleAnim()
    end
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWheelOfRhinoMachine:levelFreeSpinEffectChange()

end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWheelOfRhinoMachine:levelFreeSpinOverChangeEffect()
    --轮盘动画
    self:runCsbAction("normal")
    --背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"changetonormal")
    
    self.m_freespinBar:setVisible(false)
end
-- 显示free spin
function CodeGameScreenWheelOfRhinoMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
    end

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
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:clearCurMusicBg()
    end
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
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenWheelOfRhinoMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showFreeSpinView.mp3")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
                self:notifyClearBottomWinCoin()
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    -- performWithDelay(self,function()
        showFSView()
    -- end,0.5)
end

function CodeGameScreenWheelOfRhinoMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showFreeSpinOverView.mp3")
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label = node,sx = 1,sy = 1},607)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWheelOfRhinoMachine:MachineRule_SpinBtnCall()
    self.m_feature = nil
    gLobalSoundManager:setBackgroundMusicVolume(1)
    return false
end
--轮盘开始滚动
function CodeGameScreenWheelOfRhinoMachine:beginReel()
    -- if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end
    CodeGameScreenWheelOfRhinoMachine.super.beginReel(self)
end
--所有effect播放完之后调用
function CodeGameScreenWheelOfRhinoMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenWheelOfRhinoMachine.super.playEffectNotifyNextSpinCall(self)
end

function CodeGameScreenWheelOfRhinoMachine:showBonusGameView(effectData)
    if effectData.isReconnection == true then
        self:addWheelNode(false)
        --如果转盘中还没有获得钱，则加一下触发金币
        globalData.slotRunData.lastWinCoin = tonumber(self.m_runSpinResultData.p_bonusExtra.triggerWin) + tonumber(self.m_runSpinResultData.p_bonusWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{0,false,false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    
        self:setCurrSpinMode(REWAED_SPIN_MODE)
    else
        self:clearWinLineEffect()
        self:clearCurMusicBg()
        self:playScatterTipMusicEffect()
        
        local scatterNum = 0
        for row = 1,self.m_iReelRowNum do
            for col = 1,self.m_iReelColumnNum do
                local slotNode = self:getFixSymbol(col,row,SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    scatterNum = scatterNum + 1
                    self:setSlotNodeEffectParent(slotNode)
                    slotNode:runAnim("actionframe",false,function ()
                        slotNode:runAnim("idleframe1")
                    end)
                end
            end
        end
        if self.m_runSpinResultData and self.m_runSpinResultData.p_bonusExtra and self.m_runSpinResultData.p_bonusExtra.triggerSignalCount == nil then
            self.m_runSpinResultData.p_bonusExtra.triggerSignalCount = scatterNum
        end
        self:setCurrSpinMode(REWAED_SPIN_MODE)
        performWithDelay(self,function ()
            -- gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_JackpotReward.mp3")
            local num = scatterNum
            if num > 9 then
                num = 9
            end
            self.m_jackpotBar:runCsbAction("actionframe"..num,true)
            performWithDelay(self,function ()
                self:showJackpotLayer()
            end,2.0)
        end,2.5)
    end
end
--显示jackpot弹框
function CodeGameScreenWheelOfRhinoMachine:showJackpotLayer()
    local jackPotWinView = util_createView("CodeWheelOfRhinoSrc.WheelOfRhinoJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    local winCoin = self.m_runSpinResultData.p_selfMakeData.bonusTriggerWin
    local index = self.m_runSpinResultData.p_bonusExtra.triggerSignalCount
    jackPotWinView:initViewData(index,winCoin,self,function ()
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_winAmount + winCoin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{0,false,true})
        self:playGuochangAni(function ()
            self:addWheelNode(true)
            self.m_jackpotBar:runCsbAction("actionframe",true)
            self:resetMusicBg()
        end)
    end)
end
--添加过场
function CodeGameScreenWheelOfRhinoMachine:playGuochangAni(func)
    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_guochang.mp3")
    self.m_guochang:setVisible(true)
    util_spinePlay(self.m_guochang,"actionframe",false)
    util_spineEndCallFunc(self.m_guochang,"actionframe",function ()
        self.m_guochang:setVisible(false)
    end)
    performWithDelay(self,function ()
        if func then
            func()
        end
    end,34/30)
end
--添加过场
function CodeGameScreenWheelOfRhinoMachine:playBaiguangGuochangAni(func)
    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_baiguangguochang.mp3")
    self.m_baiguangGuochang:setVisible(true)
    self.m_baiguangGuochang:playAction("actionframe",false,function ()
        self.m_baiguangGuochang:setVisible(false)
        if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            self:resetMusicBg()
        end
    end)
    performWithDelay(self,function ()
        if func then
            func()
        end
    end,20/30)
end
--添加转盘
function CodeGameScreenWheelOfRhinoMachine:addWheelNode(isInit)
    local wheelNode = util_createView("CodeWheelOfRhinoSrc.WheelOfRhinoWheelView",self)
    self:findChild("wheelNode"):addChild(wheelNode)
    if isInit == true then
        wheelNode:showBonusStartView()
    else
        wheelNode:reconnection()
    end
    self:resetMusicBg()
end

--bonus玩法结束后添加freespin动画效果
function CodeGameScreenWheelOfRhinoMachine:featuresOverAddFreespinEffect()
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    local isFree = false
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
            isFree = true
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

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

            ---轮盘动画
            self:runCsbAction("freespin")
            --背景动画
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"changetofreespin")

            self.m_freespinBar:setVisible(true)
        end
    end
    --如果没有触发freespin，添加bigwin
    if isFree == false then
        local winAmonut = self.m_runSpinResultData.p_bonusWinCoins
        self:checkFeatureOverTriggerBigWin(winAmonut,GameEffect.EFFECT_BONUS)
    end
end
--bonus轮盘结束
function CodeGameScreenWheelOfRhinoMachine:bonusOver()
    self:playBaiguangGuochangAni(function ()
        self.m_bottomUI:notifyTopWinCoin()
        gLobalNoticManager:postNotification("WheelOfRhinoWheelView_closeView")
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        self:featuresOverAddFreespinEffect()
        self:notifyGameEffectPlayComplete(GameEffect.EFFECT_BONUS)
    end)
end

--点击轮盘后获得数据解析
function CodeGameScreenWheelOfRhinoMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
end

--获得信号块层级
function CodeGameScreenWheelOfRhinoMachine:getBounsScatterDataZorder(symbolType)
    local order = CodeGameScreenWheelOfRhinoMachine.super.getBounsScatterDataZorder(self,symbolType)
    if symbolType == self.SYMBOL_SCORE_WILD2
        or symbolType == self.SYMBOL_SCORE_WILD3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_SCORE_SCATTERMOHU then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    return order
end
function CodeGameScreenWheelOfRhinoMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


--初始化的 模糊图标修改为scatter 并多初始化一行
function CodeGameScreenWheelOfRhinoMachine:randomSlotNodesByReel()
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen + 1
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex=1,resultLen do
            
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            if symbolType == self.SYMBOL_SCORE_SCATTERMOHU then
                symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            end
            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = reelColData.p_showGridH      
            
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) -rowIndex
           
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )

        end
    end
    self:initGridList()
end

--初始化的 模糊图标修改为scatter 并多初始化一行
function CodeGameScreenWheelOfRhinoMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount + 1
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            local symbolType = self:getRandomReelType(colIndex,reelDatas)
            if symbolType == self.SYMBOL_SCORE_SCATTERMOHU then
                symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            end
            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex , reelDatas   )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end
            
--            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )

           
        end
    end
    self:initGridList()
end
--初始化的 模糊图标修改为scatter 并多初始化一行
--初始化格子列表（放在关卡初始化轮盘之后）
function CodeGameScreenWheelOfRhinoMachine:initGridList(isFirstNoramlReel)
    self.m_initGridNode = nil
    for i=1,#self.m_reels do
        local gridList = {}
        for j=1,self.m_reels[i].m_iRowNum + 1 do
            if isFirstNoramlReel then
                local symbolNode = self:getReelParentChildNode(i,j)
                if not symbolNode then
                    symbolNode = self:getFixSymbol(i,j)
                end
                gridList[j]= symbolNode
            else
                gridList[j]= self:getFixSymbol(i,j)
            end
        end
        self.m_reels[i]:initGridList(gridList)
    end
    self:initCacheGrids()
end
return CodeGameScreenWheelOfRhinoMachine