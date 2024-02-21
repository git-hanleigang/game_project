---
-- island li
-- 2019年1月26日
-- GameScreenClassicRapid2ClassicSlots.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = util_require("Levels.BaseMachine")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local GameScreenClassicRapid2ClassicSlots = class("GameScreenClassicRapid2ClassicSlots", BaseSlotoManiaMachine)



GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_7 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_3 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3
GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_2 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 4
GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_1 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 5
GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_CHERRY = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 6
GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_WHEEL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

GameScreenClassicRapid2ClassicSlots.SYMBOL_CLASSIC_SCORE_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

-- 这个wild成倍信号数值是跟普通轮盘start信号是一样的
GameScreenClassicRapid2ClassicSlots.SYMBOL_WILD_x1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
GameScreenClassicRapid2ClassicSlots.SYMBOL_WILD_x2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
GameScreenClassicRapid2ClassicSlots.SYMBOL_WILD_x3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
GameScreenClassicRapid2ClassicSlots.SYMBOL_WILD_x5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12

GameScreenClassicRapid2ClassicSlots.Classic_GameStates_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 -- 自定义动画的标识

GameScreenClassicRapid2ClassicSlots.Classic_Wheel_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 11 -- 自定义动画的标识


GameScreenClassicRapid2ClassicSlots.m_gameTypeIndex = nil -- 当前进行到哪个游戏类型
GameScreenClassicRapid2ClassicSlots.m_gameTypeMaxIndex = nil -- 当前最多进行到哪个游戏类型

GameScreenClassicRapid2ClassicSlots.m_ITME_WIDTH = 980 -- 当前最多进行到哪个游戏类型
GameScreenClassicRapid2ClassicSlots.m_isPlayWinSound = nil
GameScreenClassicRapid2ClassicSlots.m_winSoundTime = 1.5
GameScreenClassicRapid2ClassicSlots.m_symbolIndex = nil
-- 构造函数
function GameScreenClassicRapid2ClassicSlots:ctor()
    self.reelAllList = {{self.SYMBOL_WILD_x1},{self.SYMBOL_WILD_x2},{self.SYMBOL_WILD_x3},{self.SYMBOL_WILD_x5},{self.SYMBOL_WILD_x2,self.SYMBOL_WILD_x3,self.SYMBOL_WILD_x5}}

    BaseSlotoManiaMachine.ctor(self)
end

function GameScreenClassicRapid2ClassicSlots:initData_( data )
    self.m_parent = data.parent
    self.m_callFunc = data.func
    self.m_effectData = data.effectData
    self.paytable = data.paytable
    self.wheels = data.wheels
    self.m_uiHeight = data.height
    self.m_iBetLevel = data.betlevel
    self.m_parentWinResult = data.parentResultData
    self:initGame()
end


function GameScreenClassicRapid2ClassicSlots:getBottomUINode( )
    return "CodeClassicRapid2Src.ClassicRapid2_GameBottomNode"
end


function GameScreenClassicRapid2ClassicSlots:enterGamePlayMusic(  )

end
function GameScreenClassicRapid2ClassicSlots:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("ClassicRapid2_ClassicConfig.csv", "LevelClassicRapid2ClassicConfig.lua")

	--初始化基本数据
	self:initMachine()
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

end
--默认按钮监听回调
function GameScreenClassicRapid2ClassicSlots:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- self.m_spinBtn:setVisible(false)
    -- self.m_bashou:playAction("idle2")

    -- self:normalSpinBtnCall()
    --respin

end


function GameScreenClassicRapid2ClassicSlots:initMachine( )

    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    -- globalData.slotRunData.gameModuleName = self.m_moduleName
    -- globalData.slotRunData.gameNetWorkModuleName = self:getNetWorkModuleName()
    -- globalData.slotRunData.lineCount = self.m_lineCount

    self:createCsbNode("ClassicRapid2/GameScreenClassicRapid_Classical.csb")


    self.m_topJackBg = {}
    for i=1,5 do
        self.m_topJackBg[i] = self:findChild("jackpotTop"..i)
    end

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()
    
    self:updateMachineData()
    self:initMachineData()
    self:initSymbolCCbNames()

    self:drawReelArea()

    self:updateReelInfoWithMaxColumn()
    self:initReelEffect()

    self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
    ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
    ,self.m_configData.p_bPlayBonusAction)

    if display.height < 1370 then
        -- self:findChild("root"):setScale((display.height - self.m_uiHeight) / (1370 - self.m_uiHeight))
    else
        local posY = (display.height - 1370) * 0.5
        -- self:findChild("reel"):setPositionY(self:findChild("reel"):getPositionY() - posY)
        -- self:findChild("title"):setPositionY(self:findChild("title"):getPositionY() - posY)
        -- self:findChild("paytable"):setPositionY(self:findChild("paytable"):getPositionY() + posY * 0.5)
    end
    -- self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 100)

    self.m_Classic_Wheel =  util_createView("CodeClassicRapid2Src.ClassicRapid2_Classic_WheelView")
    self:findChild("bigWheel"):addChild(self.m_Classic_Wheel)

    for i=1,5 do
        local name = "bar"..i
        local barname =  "TopBar"..i
        self[barname] =  util_createView("CodeClassicRapid2Src.ClassicRapid2ReelsTopBarView",i,self.m_parent)
        self:findChild(name):addChild(self[barname])
    end
    self:initWheelbar( )
    --背景可变的
    self.reelBgList = {}
    self.m_endIndex = self:getEndColIndex()
    for i=1,self.m_endIndex do
        self.reelBgList[i] = util_createView("CodeClassicRapid2Src.ClassicRapid2_ClassicReelView",i)
        self.reelBgList[i]:setPosition(cc.p(526.5+self.m_ITME_WIDTH*(i-1),212))
        self:findChild("wheel"):addChild(self.reelBgList[i])
        self.reelBgList[i]:hideWheel()
        if self.m_nowPlayCol == i then
            self.reelBgList[i]:setScale(1)

        else
            self.reelBgList[i]:setScale(0.9)
            self.reelBgList[i]:setVisible(false)
        end
    end
    self.m_showCol = self.m_nowPlayCol
    self:findChild("wheel"):setPositionX(-1*(self.m_nowPlayCol - 1)*self.m_ITME_WIDTH)

    self.m_bashou = util_createAnimation("ClassicRapid2_bashou.csb")
    self:findChild("bashou"):addChild(self.m_bashou)
    self.m_bashou:playAction("idle")


    local logo = util_createAnimation("ClassicRapid2_logo.csb")
    self:findChild("logo"):addChild(logo)

end


function GameScreenClassicRapid2ClassicSlots:initMachineData()


    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName.."_Datas"

    

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    -- 配置全局信息，供外部使用
    globalData.slotRunData.levelGetAnimNodeCallFun = function(symbolType,ccbName)
                                                      return self:getAnimNodeFromPool(symbolType,ccbName)
                                                   end
    globalData.slotRunData.levelPushAnimNodeCallFun = function(animNode,symbolType)
                                                        self:pushAnimNodeToPool(animNode,symbolType)
                                                    end

    self:checkHasBigSymbol()
end

function GameScreenClassicRapid2ClassicSlots:startPlay()

    self:runCsbAction("idle")
    self:setVisible(true)

    performWithDelay(self,function()
        self.m_wheelBgSoundId = gLobalSoundManager:playBgMusic("ClassicRapid2Sounds/classRapid_wheelBg.mp3")
        gLobalSoundManager:setBackgroundMusicVolume(0)

        performWithDelay(self,function()
            self:runCsbAction("actionframe2",false,function()
                gLobalSoundManager:stopBgMusic()
                self:normalSpinBtnCall(true)
            end,60)
        end,1)
    end,0.5)

   
end

function GameScreenClassicRapid2ClassicSlots:LittleByLittleChangeBgMusic(time,callback)
    local volume = 0
    gLobalSoundManager:setBackgroundMusicVolume(volume)

    self.m_selfSsoundGlobalId =  scheduler.scheduleGlobal( function()
        if volume >= 1 then
            volume = 1
        end
        volume = volume + 1/time
        print("curSOund"..volume)
        gLobalSoundManager:setBackgroundMusicVolume(volume)
        if volume >= 1 then
            if self.m_selfSsoundGlobalId ~= nil then
                scheduler.unscheduleGlobal(self.m_selfSsoundGlobalId)
                self.m_selfSsoundGlobalId = nil
            end
        end
    end, 1/30)
end
function GameScreenClassicRapid2ClassicSlots:LittleByLittleChangeBgMusic2(time,callback)
    local volume = 1
    gLobalSoundManager:setBackgroundMusicVolume(volume)

    self.m_selfSsoundGlobalId =  scheduler.scheduleGlobal( function()
        if volume <= 0 then
            volume = 0
        end
        volume = volume - 1/time

        gLobalSoundManager:setBackgroundMusicVolume(volume)
        if volume <= 0 then
            if self.m_selfSsoundGlobalId ~= nil then
                scheduler.unscheduleGlobal(self.m_selfSsoundGlobalId)
                self.m_selfSsoundGlobalId = nil
            end
        end
    end, 1/30)
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenClassicRapid2ClassicSlots:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "ClassicRapid2_Classic"
end

function GameScreenClassicRapid2ClassicSlots:getNetWorkModuleName()
    return self.m_parent:getNetWorkModuleName()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenClassicRapid2ClassicSlots:MachineRule_GetSelfCCBName(symbolType)

    if self.SYMBOL_CLASSIC_SCORE_WILD == symbolType then
        return "Socre_ClassicRapid2_Classical_Wild"
    elseif self.SYMBOL_CLASSIC_SCORE_7 == symbolType then
        return "Socre_ClassicRapid2_Classical_9"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_3 == symbolType then
        return "Socre_ClassicRapid2_Classical_8"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_2 == symbolType then
        return "Socre_ClassicRapid2_Classical_7"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_1 == symbolType then
        return "Socre_ClassicRapid2_Classical_6"
    elseif self.SYMBOL_CLASSIC_SCORE_CHERRY == symbolType then
        return "Socre_ClassicRapid2_Classical_5"
    elseif self.SYMBOL_CLASSIC_SCORE_WHEEL == symbolType then
        return "Socre_ClassicRapid2_Classical_Spin"
    elseif self.SYMBOL_CLASSIC_SCORE_EMPTY == symbolType then
        return "Socre_ClassicRapid2_Classical_Empty"

    elseif self.SYMBOL_WILD_x1 == symbolType then
        return "Socre_ClassicRapid2_Classical_Wild"
    elseif self.SYMBOL_WILD_x2 == symbolType then
        return "Socre_ClassicRapid2_Classical_2X"
    elseif self.SYMBOL_WILD_x3 == symbolType then
        return "Socre_ClassicRapid2_Classical_3X"
    elseif self.SYMBOL_WILD_x5 == symbolType then
        return "Socre_ClassicRapid2_Classical_5X"


    end



    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenClassicRapid2ClassicSlots:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_CHERRY,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_CLASSIC_SCORE_WHEEL,count =  2}

    return loadNode
end



function GameScreenClassicRapid2ClassicSlots:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)

    -- if self.m_nowPlayCol then
    --     local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
    --     if data[self.m_nowPlayCol] < 1 then

    --     end
    -- end

    if self.m_spinSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_spinSoundId)
        self.m_spinSoundId = nil
    end
end

function GameScreenClassicRapid2ClassicSlots:reelDownNotifyChangeSpinStatus( )
    -- 通知滚动结束
-- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
-- BtnType_Auto  BtnType_Stop  BtnType_Spin
-- if self:getCurrSpinMode() == AUTO_SPIN_MODE then
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, false})
-- else
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
-- end
end

function GameScreenClassicRapid2ClassicSlots:showLineFrame()
    local winLines = self.m_reelResultLines
    if not self:checkHasWheel() then

        self:checkNotifyUpdateWinCoin()
    end
    self.m_lineSlotNodes = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            -- self:clearFrames_Fun()

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
            if frameIndex > #winLines  then
                frameIndex = 1
            end
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self:getCurrSpinMode() == FREE_SPIN_MODE then


        self:showAllFrame(winLines)  -- 播放全部线框

        showLienFrameByIndex()

    else
        -- 播放一条线线框
        self:showLineFrameByIndex(winLines,1)
        frameIndex = 2
        if frameIndex > #winLines  then
            frameIndex = 1
        end

        showLienFrameByIndex()
    end
end

function GameScreenClassicRapid2ClassicSlots:checkHasWheel( )
    for i=1,#self.m_gameEffects do
        if self.m_gameEffects[i].p_selfEffectType == self.Classic_Wheel_EFFECT then
            return true
        end
    end
    return false

end
function GameScreenClassicRapid2ClassicSlots:checkTriggerWheel( )
    local wheelIndex  =  self.m_runSpinResultData.p_selfMakeData.wheelIndex
    if wheelIndex then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 11--GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.Classic_Wheel_EFFECT
    end
end


function GameScreenClassicRapid2ClassicSlots:checkChangeGameStates( )
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.Classic_GameStates_EFFECT
end

---
-- 添加关卡中触发的玩法
--
function GameScreenClassicRapid2ClassicSlots:addSelfEffect()

    self:checkTriggerWheel()

    -- self:checkChangeGameStates( )


    if not self:checkIsOver( ) then
        if self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE) == false then
            local questEffect = GameEffectData:create()
            questEffect.p_effectType =  GameEffect.EFFECT_QUEST_DONE  --创建属性
            questEffect.p_effectOrder = 999999  --动画播放层级 用于动画播放顺序排序
            self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
        end
    end

end


function GameScreenClassicRapid2ClassicSlots:callSpinBtn()


    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end


    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    self:spinBtnEnProc()

    self:setGameSpinStage( GAME_MODE_ONE_RUN )

    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function GameScreenClassicRapid2ClassicSlots:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.Classic_Wheel_EFFECT then

        gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_wheeltrigger.mp3")

        performWithDelay(self,function()
            self:ClassicWheelAct(effectData)
        end,3)
    elseif effectData.p_selfEffectType == self.Classic_GameStates_EFFECT then
        self:ClassicGameStatesAct(effectData)

    end





	return true
end

function GameScreenClassicRapid2ClassicSlots:ClassicWheelAct( effectData)
    
    self.m_wheelBgSoundId = gLobalSoundManager:playBgMusic("ClassicRapid2Sounds/classRapid_wheelBg.mp3")
    self:LittleByLittleChangeBgMusic(75)
    self:runCsbAction("actionframe",false,function()
        self.m_Classic_Wheel:showActionFrame(1,function(  )

        end)
        local wheelIndex = self.m_runSpinResultData.p_selfMakeData.wheelIndex + 1
        self.m_Classic_Wheel:setRunWheelData(wheelIndex)
        self.m_Classic_Wheel:initCallBack(function()

            

            if wheelIndex == 1 then--jackpot
                local score = self.m_parent:BaseMania_getJackpotScore(self.m_nowPlayCol)
                local jpScore = score
                if self.m_runSpinResultData.p_selfMakeData then
                   if self.m_runSpinResultData.p_selfMakeData.wheelCoins then
                        jpScore = self.m_runSpinResultData.p_selfMakeData.wheelCoins
                   end
                end
                self.m_parent:showWheelJackPot(jpScore,self.m_nowPlayCol,function()
                    performWithDelay(self,function()
                        self:LittleByLittleChangeBgMusic2(75)
                        self:runCsbAction("actionframe2",false,function()

                            self.m_Classic_Wheel:resetView()

                            self:checkNotifyUpdateWinCoin()
                            gLobalSoundManager:stopBgMusic()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end,60)
                    end,1.5)
                end)
            else
                performWithDelay(self,function()
                    self:LittleByLittleChangeBgMusic2(75)
                    self:runCsbAction("actionframe2",false,function()

                        self.m_Classic_Wheel:resetView()
                        
                        self:checkNotifyUpdateWinCoin()
                        gLobalSoundManager:stopBgMusic()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,60)
                end,1.5)
            end
        end)
        -- self.m_Classic_Wheel:beginWheelAction()
        performWithDelay(self,function()
            self.m_Classic_Wheel:beginWheelAction()
        end,1.5)
    end,60)
end
function GameScreenClassicRapid2ClassicSlots:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     local showWinCoins = 0
     if self.m_runSpinResultData then
        if self.m_runSpinResultData.p_resWinCoins then
            showWinCoins = self.m_runSpinResultData.p_resWinCoins
        end
     end
    self:setLastWinCoin(showWinCoins)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_winAmount,false,true,1})
end

function GameScreenClassicRapid2ClassicSlots:ClassicGameStatesAct( effectData)
    effectData.p_isPlay = true
    self:playGameEffect()
end
function GameScreenClassicRapid2ClassicSlots:playGameEffect()
    -- local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    -- if hasQuestEffect == true then
    --     self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    -- end
    BaseMachineGameEffect.playGameEffect(self)
end
--绘制多个裁切区域
function GameScreenClassicRapid2ClassicSlots:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self:findChild("sp_reel_0"):getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)
        local high = reelSize.height / 4
        reelSize.height = reelSize.height + high

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2


        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create()     -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --

        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - high * 0.5)
        clipNode:setTag(CLIP_NODE_TAG + i)

        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()

        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
    end
end




---
-- 获取最高的那一列
--
function GameScreenClassicRapid2ClassicSlots:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0

    local iColNum = self.m_iReelColumnNum
    --    local maxHeightColumnIndex = iColNum
    for iCol = 1, iColNum, 1 do
        -- local colNodeName = "reel_unit"..(iCol - 1)
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))


        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width

        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / 4

    for iCol = 1, iColNum, 1 do
        -- self.m_reelColDatas[iCol].p_slotColumnPosY = self.m_reelColDatas[iCol].p_slotColumnPosY - 0.5 * self.m_SlotNodeH
        self.m_reelColDatas[iCol].p_slotColumnHeight = self.m_reelColDatas[iCol].p_slotColumnHeight + self.m_SlotNodeH
    end

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = self.m_iReelRowNum -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

function GameScreenClassicRapid2ClassicSlots:checkRestSlotNodePos( )
    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        local moveDis = nil
        for nodeIndex = 1, #childs do
            local childNode = childs[nodeIndex]
            if childNode.m_isLastSymbol == true then
                local childPosY = childNode:getPositionY()
                if maxLastNodePosY == nil then
                    maxLastNodePosY = childPosY
                elseif maxLastNodePosY < childPosY then
                    maxLastNodePosY = childPosY
                end

                if minLastNodePosY == nil then
                    minLastNodePosY = childPosY
                elseif minLastNodePosY > childPosY then
                    minLastNodePosY = childPosY
                end
                local columnData = self.m_reelColDatas[childNode.p_cloumnIndex]
                local nodeH = columnData.p_showGridH

                childNode:setPositionY((nodeH * childNode.p_rowIndex - nodeH * 0.5))

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    childNode:removeFromParent()
                    local posWorld =
                        slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    childNode:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(childNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                end
            end
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end


---
-- 处理spin 返回结果
function GameScreenClassicRapid2ClassicSlots:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    
    self:checkTestConfigType(param)

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end
end


function GameScreenClassicRapid2ClassicSlots:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" then
        globalData.seqId = spinData.sequenceId
        release_print("消息返回胡来了")
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        --发送测试赢钱数
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN,self.m_serverWinCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)

        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

        local preLevel =  globalData.userRunData.levelNum
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if self.m_spinIsUpgrade == true then

            local sendData = {}

            local betCoin = globalData.slotRunData:getCurTotalBet()

            sendData.exp = betCoin  * self.m_expMultiNum

            -- 存储一下VIP的原始等级
            self.m_preVipLevel = globalData.userRunData.vipLevel
            self.m_preVipPoints = globalData.userRunData.vipPoints
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function GameScreenClassicRapid2ClassicSlots:requestSpinResult()

    local showWinCoins = self.m_parentWinResult.p_winAmount
    if self.m_runSpinResultData then
       if self.m_runSpinResultData.p_resWinCoins then
           showWinCoins = self.m_runSpinResultData.p_resWinCoins
       end
    end
    self:setLastWinCoin(showWinCoins)

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

    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, false, moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function GameScreenClassicRapid2ClassicSlots:normalSpinBtnCall(isFirst)
    -- self:ChangeWheelbar( )
    self.m_isPlayWinSound = false
    performWithDelay(self,function(  )

        gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_Pullrod.mp3")
        -- gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_classicReelSound.mp3")
        self.m_bashou:playAction("actionframe",false,function()
            BaseMachine.normalSpinBtnCall(self)
            self.m_spinSoundId = gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_classic_lastwin_4.mp3")
        end,20)
    end,0.5)
end


function GameScreenClassicRapid2ClassicSlots:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex,self.m_nowPlayCol)

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end

function GameScreenClassicRapid2ClassicSlots:beginReel()
    BaseSlotoManiaMachine.beginReel(self)
    if self.m_nowPlayCol then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        if data[self.m_nowPlayCol] > 0 then
            data[self.m_nowPlayCol] = data[self.m_nowPlayCol] - 1
            -- local oldCol = self.m_nowPlayCol
            -- self:checkChangeIndex()
            self:updateOldBar(false)
            -- self:spinChangeJackpotBarState(self.m_nowPlayCol)
        end
    end
end

function GameScreenClassicRapid2ClassicSlots:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or
    self:checkGameRunPause()
    then
        return
    end

    -- slotReelTime = slotReelTime  + delayTime
    -- if slotReelTime < reelDelayTime then
    --     return
    -- end
    -- reelDelayTime = util_random(8,30) / 100
    -- slotReelTime = 0

    if self.m_reelDownAddTime > 0 then
        self.m_reelDownAddTime = self.m_reelDownAddTime - delayTime
    else
        self.m_reelDownAddTime = 0
    end
    local timeDown = 0
    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        -- if parentData.cloumnIndex == 1 then
        -- 	printInfo(" %d ", parentData.tag)
        -- end
        local columnData = self.m_reelColDatas[index]
        local halfH = columnData.p_showGridH * 0.5

        local parentY = slotParent:getPositionY()
        if parentData.isDone == false then


            local cloumnMoveStep = self:getColumnMoveDis(parentData, delayTime)
            local newParentY = slotParent:getPositionY() - cloumnMoveStep
            if self.m_isWaitingNetworkData == false then
                if newParentY < parentData.moveDistance then
                    newParentY = parentData.moveDistance
                end
            end
            parentData.symbolType = self:filterSymbolType(parentData.symbolType)

            -- if index == 3 thenx
            --     print("")
            -- end
            slotParent:setPositionY(newParentY)
            parentY = newParentY
            local childs = slotParent:getChildren()
            local zOrder, preY = self:reelSchedulerCheckRemoveNodes(childs, halfH, parentY , index)
            self:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
        end

        if self.m_isWaitingNetworkData == false then
            timeDown = self:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
        end
    end -- end for

    local isAllReelDone = function()
        for index = 1, #slotParentDatas do
            if slotParentDatas[index].isResActionDone == false then
            -- if slotParentDatas[index].isDone == false then

                return false
            end
        end
        return true
    end

    if isAllReelDone() == true then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        self:slotReelDown()

        -- 先写在这里 之后写到 回弹结束里面去
        --加入回弹

        -- scheduler.performWithDelayGlobal(
        --     function()
        --         self:slotReelDown()
        --     end,
        --     timeDown,
        --     self:getModuleName()
        -- )

        --        end,timeDown)
        self.m_reelDownAddTime = 0
    end
end
function GameScreenClassicRapid2ClassicSlots:filterSymbolType(symbolType)
    if symbolType ==  self.SYMBOL_CLASSIC_SCORE_WILD or symbolType == self.SYMBOL_WILD_x1 or symbolType == self.SYMBOL_WILD_x2 or symbolType == self.SYMBOL_WILD_x3 or symbolType == self.SYMBOL_WILD_x5 then
        local temp = self.reelAllList[self.m_showCol]
        local has = false
        for i=1,#temp do
            if symbolType == temp[i] then
                has = true
                break
            end
        end
        if not has then
            symbolType = temp[1]
        end
    end
    return symbolType
end

function GameScreenClassicRapid2ClassicSlots:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        performWithDelay(self,function()
            self:requestSpinResult()
        end,0.5)
    else
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage( WAITING_DATA )
    -- 设置stop 按钮处于不可点击状态
    -- if self:getCurrSpinMode() == RESPIN_MODE then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --     {SpinBtn_Type.BtnType_Spin,false})
    -- else
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --     {SpinBtn_Type.BtnType_Stop,false})
    -- end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function GameScreenClassicRapid2ClassicSlots:dealSmallReelsSpinStates( )
    -- do nothing
end

function GameScreenClassicRapid2ClassicSlots:checkHasBigSymbolWithNetWork( )

    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i=1,#self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)
        
        local preY , isLastBigSymbol, realChildCount = self:checkLastSymbolInfo(slotParent,nil)
        
        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if realChildCount == 0 then  -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY -  moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        
        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    return lastNodeIsBigSymbol,maxDiff
end

function GameScreenClassicRapid2ClassicSlots:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
end

function GameScreenClassicRapid2ClassicSlots:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    if self.m_isPlayWinSound then
        return
    else
        self.m_isPlayWinSound = true
    end
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 6 then
            soundIndex = 1
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 1
        end

        local soundName = "ClassicRapid2Sounds/classicRapid_classic_lastwin_".. soundIndex .. ".mp3"
        local soundId = globalMachineController:playBgmAndResume(soundName,self.m_winSoundTime,0.4,1)

        performWithDelay(self,function()
            gLobalSoundManager:stopAudio(soundId)
            soundId = nil
        end,self.m_winSoundTime)
        self.m_winSoundsId = soundId

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function GameScreenClassicRapid2ClassicSlots:MachineRule_SpinBtnCall()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    return false
end

function GameScreenClassicRapid2ClassicSlots:symbolNodeAnimation(animation)
    for reelCol = 1, self.m_iReelColumnNum, 1 do
        local parent = self:getReelParent(reelCol)
        local children = parent:getChildren()
        for i = 1, #children, 1 do
            local child = children[i]
            child:runAnim(animation)
        end
        -- local symbolNode =  self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, 1, SYMBOL_NODE_TAG))

    end
end

function GameScreenClassicRapid2ClassicSlots:checkIsOver( )
    local  selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local classCounts =  selfdata.classCounts or {}
    local isover = true
    for k,v in pairs(classCounts) do
        if v ~= 0 then
            isover = false
        end
    end

    return isover

end

function GameScreenClassicRapid2ClassicSlots:playEffectNotifyNextSpinCall( )
    -- 0-max
    local oldCol = self.m_nowPlayCol
    self.m_showCol = oldCol
    self:checkChangeIndex()
    if oldCol ~= self.m_nowPlayCol then--移动
        self.m_moveIndex = oldCol
        performWithDelay(self,function(  )
            self:clearWinLineEffect()
            self:changeOldBarState(oldCol)
            self:startMove(function()
                if self:checkIsOver( ) then
                    self:leaveClassicGame( )
                else
                    performWithDelay(self, function()
                        local random = math.random(1, 3)
                        self:normalSpinBtnCall()
                    end, self.m_winSoundTime)--1
                end
            end)
        end,2)
    else
        self:updateOldBar(true)
        if self:checkIsOver( ) then
            self:leaveClassicGame( )
        else

            performWithDelay(self, function()
                local random = math.random(1, 3)
                self:normalSpinBtnCall()
            end, self.m_winSoundTime)--1
        end
    end
    -- self:spinChangeJackpotBarState(oldCol)
end
function GameScreenClassicRapid2ClassicSlots:startMove(callback)
    self:beforeMoveAction(function()
        local time = 0.75
        local endPos = cc.p(-1*self.m_moveIndex*self.m_ITME_WIDTH,0)--cc.p(-1*(self.m_nowPlayCol-1)*self.m_ITME_WIDTH,-32)--cur - 1

        self:runMoveAction(time,endPos,function()
            self.m_moveIndex = self.m_moveIndex + 1
            if self.m_moveIndex < self.m_nowPlayCol then
                self:startMove(callback)
            else
                self:dealReelData()
                self:changeNewBarState()
                self.m_showCol = self.m_nowPlayCol
                self.reelBgList[self.m_moveIndex]:hideWheel()
                self:findChild("reayWheel"):setVisible(true)
                self.m_moveIndex = 1
                if callback then
                    callback()
                end
            end
        end)
    end)
end
function GameScreenClassicRapid2ClassicSlots:dealReelData()
    -- local tempList = {self.SYMBOL_WILD_x1,self.SYMBOL_WILD_x2,self.SYMBOL_WILD_x3,self.SYMBOL_WILD_x5}
    -- self.m_bProduceSlots_RunSymbol =  self.SYMBOL_MYSTER_NAME[math.random( 1, #self.SYMBOL_MYSTER_NAME)]

    -- if globalData.slotRunData and globalData.slotRunData.levelConfigData then
    --     -- self.m_nowPlayCol
    --     local levelConfig = globalData.slotRunData.levelConfigData
    --     for i=1,#levelConfig.reel_cloumn1 do
    --         if levelConfig.reel_cloumn1[i] == self.SYMBOL_CLASSIC_SCORE_WILD then

    --         end
    --     end
    --     for i=1,#levelConfig.reel_cloumn2 do
    --         if levelConfig.reel_cloumn2[i] == self.SYMBOL_CLASSIC_SCORE_WILD then

    --         end
    --     end
    --     for i=1,#levelConfig.reel_cloumn3 do
    --         if levelConfig.reel_cloumn3[i] == self.SYMBOL_CLASSIC_SCORE_WILD then

    --         end
    --     end
    -- end

end



function GameScreenClassicRapid2ClassicSlots:runMoveAction(flyTime,endPos,runMoveCallback)
    local actionList = {}
    gLobalSoundManager:playSound("ClassicRapid2Sounds/classicRapid_classicMove.mp3")
    local node = self:findChild("wheel")
    local moveto=cc.MoveTo:create(flyTime+0.01,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        -- self.reelBgList[self.m_moveIndex+1]:hideWheel()
        -- self:afterBgMoveAction(function()
        performWithDelay(self,function()
            if runMoveCallback then
                runMoveCallback()
            end
        end,0.15)

        -- end)
    end)
    node:runAction(cc.Sequence:create(actionList))
    util_playScaleToAction(self.reelBgList[self.m_moveIndex],0.25,0.9,function()

    end)

    performWithDelay(self,function()
        if self.m_moveIndex + 1 <=  self.m_nowPlayCol then
            util_playScaleToAction(self.reelBgList[self.m_moveIndex+1],0.25,1,function()

            end)
        end
    end,0.5)

    -- self:playBgMoveAction(flyTime)
end

function GameScreenClassicRapid2ClassicSlots:beforeMoveAction(bcallback)
    local reelNodeInfo = self:reateReelNodeInfo()
    self.reelBgList[self.m_moveIndex]:initReelElement(reelNodeInfo,self)--假的轴赋值
    self.reelBgList[self.m_moveIndex]:showWheel()--假的轴显示出来
    self:findChild("reayWheel"):setVisible(false)

    util_nextFrameFunc(function()
        -- util_playScaleToAction(self.reelBgList[self.m_moveIndex],0.25,0.9,function()
            -- self.reelBgList[self.m_moveIndex]:setVisible(false)
            if  bcallback then
                bcallback()
            end
        -- end)
    end)
    -- for i=self.m_moveIndex + 1,self.m_nowPlayCol do
        if  self.m_moveIndex + 1 <= self.m_nowPlayCol then
            self.reelBgList[self.m_moveIndex + 1]:initReelElement(reelNodeInfo,self)--假的轴赋值
            self.reelBgList[self.m_moveIndex + 1]:showWheel()
            self.reelBgList[self.m_moveIndex + 1]:setVisible(true)
            self.reelBgList[self.m_moveIndex + 1]:setScale(0.9)
        end
    -- end
end

--移动格子
function GameScreenClassicRapid2ClassicSlots:afterBgMoveAction(aCallback)
    util_playScaleToAction(self.reelBgList[self.m_moveIndex],0.25,1,function()
        -- for i=1,self.m_nowPlayCol-1 do
        --     self.reelBgList[i]:setVisible(false)
        -- end
        if aCallback then
            aCallback()
        end
    end)
end

---
-- 根据类型获取对应节点
--
function GameScreenClassicRapid2ClassicSlots:getSlotNodeBySymbolType(symbolType)
    local reelNode =  SlotsNode:create()
    reelNode:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载

    symbolType = self:filterSymbolType(symbolType)


    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    -- print("hhhhh~ "..ccbName)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end


function GameScreenClassicRapid2ClassicSlots:playEffectNotifyChangeSpinStatus( )

end

----构造respin所需要的数据
function GameScreenClassicRapid2ClassicSlots:reateReelNodeInfo()
    local reelNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)

            local addScale = 0

            if display.height > 1500 then
                addScale = (display.height - 1500) * 0.001

            end

            pos.x = pos.x + reelWidth / 2 * (self.m_machineRootScale + addScale)

            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH

            pos.y = pos.y + (iRow - 0.5) * slotNodeH * (self.m_machineRootScale + addScale)

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            reelNodeInfo[#reelNodeInfo + 1] = symbolNodeInfo
        end
    end
    return reelNodeInfo
end

function GameScreenClassicRapid2ClassicSlots:leaveClassicGame( )

    performWithDelay(self,function()
       -- self.m_parent:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount , GameEffect.EFFECT_BONUS)
       local winCount = 0
       if self.m_runSpinResultData then
        if self.m_runSpinResultData.p_resWinCoins then
            winCount = self.m_runSpinResultData.p_resWinCoins
        end
     end
    --  self:setLastWinCoin( winCount )

       self.m_parent:classicSlotOverView(winCount)
       self:clearWinLineEffect()
       self:resetMaskLayerNodes()

    end,self.m_winSoundTime+1)

end


function GameScreenClassicRapid2ClassicSlots:showLineFrameByIndex(winLines,frameIndex)

end

function GameScreenClassicRapid2ClassicSlots:checkFeatureOverTriggerBigWin( winAmonut , feature)
    if winAmonut == nil then
        return
    end
end

function GameScreenClassicRapid2ClassicSlots:addLastWinSomeEffect() -- add big win or mega win
    if #self.m_vecGetLineInfo == 0 then
        return
    end
end


function GameScreenClassicRapid2ClassicSlots:getEndColIndex( )
    local index = 1
    if self.m_parent then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        if data then
            for i=1,#data do
                if data[i] > 0 then
                    index = i
                end
            end
        end
    end
    return index
end




function GameScreenClassicRapid2ClassicSlots:ChangeWheelbar( )
    if self.m_parent then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        local data1 = self.m_parent.m_runSpinResultData.p_selfMakeData.classTotalCounts or "ffff"
        for i=1,5 do
            local barname =  "TopBar"..self.m_parent.jackpotMappingList[i]
            if self[barname] and self[barname].m_curIndex > 0 and data1[i] > 0 then
                local leftCount = self[barname].m_curIndex - 1
                self[barname]:showSpinTime(leftCount,data1[i])
                break
            end
        end
    end
end


--初始化
function GameScreenClassicRapid2ClassicSlots:initWheelbar()
    local coins1 = self.m_parent.m_specialBets[#self.m_parent.m_specialBets].p_totalBetValue
    local coins2 = self.m_parent.m_specialBets[#self.m_parent.m_specialBets - 1].p_totalBetValue
    local coins3 = self.m_parent.m_specialBets[#self.m_parent.m_specialBets - 2].p_totalBetValue
    local coins4 = self.m_parent.m_specialBets[#self.m_parent.m_specialBets - 3].p_totalBetValue

    local list = {coins4,coins3,coins2,coins1}
    self:updateTopLittleBarLock(list)
    self:initJackpotBarState()
end

function GameScreenClassicRapid2ClassicSlots:checkChangeIndex()
    if self.m_parent then
        local selfData = self.m_parent.m_runSpinResultData.p_selfMakeData
        local data = selfData and selfData.classCounts
        local data1 = selfData and selfData.classTotalCounts or "ffff"
        if data then
            local isFirst = false
            for i=1,#data do
                if data1[i] > 0 then
                    local curCount = data[i]
                    if curCount > 0 and curCount <= data1[i] then
                        isFirst = true
                        self.m_nowPlayCol = i
                        local showCol = self.m_nowPlayCol
                        if not self.m_parent.m_IsBonusCollectFull then
                            local betLevel = self.m_parent:getBetLevel()
                            for i=self.m_nowPlayCol,-1 do
                                if i - 1 <= betLevel then
                                    showCol = i
                                    break
                                end
                            end
                        end

                        self.m_Classic_Wheel:initWheelLable(self.wheels[showCol])

                        -- self.m_Classic_Wheel:initWheelLable(self.wheels[self.m_nowPlayCol])

                        break
                    end
                end
            end
            if isFirst == false then
                for i=1,#data do
                    if data[i] > 0 and data1[i] > 0 then
                        isFirst = true
                        self.m_nowPlayCol = i
                        local showCol = self.m_nowPlayCol
                        if not self.m_parent.m_IsBonusCollectFull then
                            local betLevel = self.m_parent:getBetLevel()
                            for i=self.m_nowPlayCol,-1 do
                                if i - 1 <= betLevel then
                                    showCol = i
                                    break
                                end
                            end
                        end

                        self.m_Classic_Wheel:initWheelLable(self.wheels[showCol])

                        -- self.m_Classic_Wheel:initWheelLable(self.wheels[self.m_nowPlayCol])

                        break
                    end
                end
            end
        end
    end


end
function GameScreenClassicRapid2ClassicSlots:checkNeedOver(node)
    local needList = {1,4,7}
    local need = false
    for i=1,#needList do
        if needList[i] == node.m_state then
            need = true
            break
        end
    end
    return need
end

--更新状态
function GameScreenClassicRapid2ClassicSlots:initJackpotBarState()
    self.m_nowPlayCol = 0
    self:checkChangeIndex()
    if self.m_parent then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        local data1 = self.m_parent.m_runSpinResultData.p_selfMakeData.classTotalCounts or "ffff"
        if data then
            local isFirst = false
            for i=1,#data do
                local barname =  "TopBar"..self.m_parent.jackpotMappingList[i]
                if self[barname] then
                    if data1[i] > 0 then
                        if i < self.m_nowPlayCol then
                            self[barname]:changeState(6,function()
                                self[barname]:changeState(7)
                            end)
                        elseif i == self.m_nowPlayCol then
                            self[barname]:changeState(3,function()
                                self[barname]:changeState(4)
                            end)
                        else
                            self[barname]:changeState(0,function()
                                self[barname]:changeState(1)
                            end)
                        end
                        self[barname]:showSpinTime(data[i],data1[i])
                    else
                        self[barname]:changeState(-1,function()
                        end)
                    end
                end
            end
        end
    end
end

--更新状态
function GameScreenClassicRapid2ClassicSlots:updateOldBar(changeState)
    if self.m_parent then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        local data1 = self.m_parent.m_runSpinResultData.p_selfMakeData.classTotalCounts or "ffff"
        local barname =  "TopBar"..self.m_parent.jackpotMappingList[self.m_nowPlayCol]
        self[barname]:showSpinTime(data[self.m_nowPlayCol],data1[self.m_nowPlayCol])
        if self.m_nowPlayCol == self.m_endIndex and data[self.m_nowPlayCol] == 0 and changeState then
            if self:checkNeedOver(self[barname]) then
                self[barname]:changeState(self[barname].m_state + 1,function()
                    self[barname]:changeState(6,function()
                        self[barname]:changeState(7)
                    end)
                end)
            else
                self[barname]:changeState(6,function()
                    self[barname]:changeState(7)
                end)
            end


        end
    end
end

--更新状态
function GameScreenClassicRapid2ClassicSlots:changeOldBarState(oldCol)
    if self.m_parent then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        local data1 = self.m_parent.m_runSpinResultData.p_selfMakeData.classTotalCounts or "ffff"

        local barname =  "TopBar"..self.m_parent.jackpotMappingList[oldCol]

        if self:checkNeedOver(self[barname]) then
            self[barname]:changeState(self[barname].m_state + 1,function()
                self[barname]:changeState(6,function()
                    self[barname]:changeState(7)
                end)
            end)
        else
            self[barname]:changeState(6,function()
                self[barname]:changeState(7)
            end)
        end

        self[barname]:showSpinTime(data[oldCol],data1[oldCol])


    end
end

function GameScreenClassicRapid2ClassicSlots:changeNewBarState()
    if self.m_parent then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        local data1 = self.m_parent.m_runSpinResultData.p_selfMakeData.classTotalCounts or "ffff"

        local newBarname =  "TopBar"..self.m_parent.jackpotMappingList[self.m_nowPlayCol]


        if self:checkNeedOver(self[newBarname]) then
            self[newBarname]:changeState(self[newBarname].m_state + 1,function()
                self[newBarname]:changeState(3,function()
                    self[newBarname]:changeState(4)
                end)
            end)
        else
            self[newBarname]:changeState(3,function()
                self[newBarname]:changeState(4)
            end)
        end

        self[newBarname]:showSpinTime(data[self.m_nowPlayCol],data1[self.m_nowPlayCol])
    end
end


function GameScreenClassicRapid2ClassicSlots:updateTopLittleBarLock(list)
    local betLevel = self.m_parent:getBetLevel()

    if self.m_parent.m_IsBonusCollectFull then-- averagebet 强行解锁所有的jackpot
        betLevel = 4
    end
    if betLevel then
        local tempLv = 5 - betLevel
        for i=1,5 do
            local barname =  "TopBar"..i
            local littleBar =  self[barname]
            if littleBar then
                if i < 5  then
                   littleBar:showUnLockBet(list[5-i])
                   if i >= tempLv  then
                        littleBar:showUnLock()
                    else
                        littleBar:showLock()
                    end
                else
                    littleBar:showUnLock()
                end
            end
        end
    end
end


function GameScreenClassicRapid2ClassicSlots:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    -- BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除

    self:clearSlotoData()
    globalData.userRate:leaveLevel()
    scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")

    BaseMachineGameEffect.onExit(self) -- 必须调用不予许删除
    --停止背景音乐
    gLobalSoundManager:stopBgMusic()
    -- gLobalSoundManager:stopAllSounds()

    self:removeObservers()

    self:clearFrameNodes()
    self:clearSlotNodes()
    -- gLobalSoundManager:stopBackgroudMusic()
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnima[i] = v
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}
    -- clear view childs
    local viewLayer = gLobalViewManager.p_ViewLayer
    if not tolua.isnull(viewLayer) then
        viewLayer:removeAllChildren()
    end

    

    self:removeSoundHandler( )

    --离开，清空
    gLobalActivityManager:clear()

    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    self:clearSlotoData()
    globalData.userRate:leaveLevel()
    scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")

end

function GameScreenClassicRapid2ClassicSlots:checkAddQuestDoneEffectType( )
   
end

function GameScreenClassicRapid2ClassicSlots:checkControlerReelType( )
    return false
end

return GameScreenClassicRapid2ClassicSlots






