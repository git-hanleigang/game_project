---
-- island li
-- 2019年1月26日
-- CodeGameScreenMrCashGoMachine.lua
-- 
--[[
    玩法：

    base:
        
    free:
        滚出scatter时，升级一次出现位置的图标框(最大三级)，
        如果出现的位置图标框已经是满级，则弹射到另外一个除了满级图标框之外最高等级的图标框位置，并提升一级。    
    bonsu:
        滚出超过3个及以上的bonus图标时触发玩法。
        玩法开始时玩家先点击按钮投掷一次骰子，根据骰子的结果移动到对应小格子触发相应的小玩法。
        jackpot：
            直接弹板领奖励
        大图标:
            miin轮盘滚动一次，大scatter的所有覆盖范围出现等级框，然后进入free。
        满级房子:
            触发bonus的图标直接升级为最高级的框，然后进入free，frre中出现的所有scatter升级边框时直接升到满级
        bonus移动:
            触发bonus的图标依次从当前位置向右移动，对路径上所有格子的框升1级。
]]
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenMrCashGoMachine = class("CodeGameScreenMrCashGoMachine", BaseNewReelMachine)

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}
CodeGameScreenMrCashGoMachine.MAIN_ADD_POSY = 30

CodeGameScreenMrCashGoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
-- 一些轮盘滚动信号
CodeGameScreenMrCashGoMachine.SYMBOL_L5 = 9
CodeGameScreenMrCashGoMachine.SYMBOL_L6 = 10
CodeGameScreenMrCashGoMachine.SYMBOL_Bonus = 91
    -- 玩法升级出来的外套等级框 和 玩法结束后 等级框转换的 bonus图标 
CodeGameScreenMrCashGoMachine.SYMBOL_LevelBox_1 = 101
CodeGameScreenMrCashGoMachine.SYMBOL_LevelBox_2 = 102
CodeGameScreenMrCashGoMachine.SYMBOL_LevelBox_3 = 103
    -- scatter大信号、空信号
CodeGameScreenMrCashGoMachine.SYMBOL_Scatter_2x2 = 200
CodeGameScreenMrCashGoMachine.SYMBOL_Scatter_3x3 = 300
CodeGameScreenMrCashGoMachine.SYMBOL_Blank = 999

-- 一些玩法事件
    -- 升级等级框-滚动
CodeGameScreenMrCashGoMachine.EFFECT_UpGradeLevelBox_Run = GameEffect.EFFECT_SELF_EFFECT - 100
    -- 升级等级框-弹射转移
CodeGameScreenMrCashGoMachine.EFFECT_UpGradeLevelBox_Transfer = GameEffect.EFFECT_SELF_EFFECT - 90
    -- Bonus2 超大图标滚动
CodeGameScreenMrCashGoMachine.EFFECT_BONUS_MoneyBag = GameEffect.EFFECT_SELF_EFFECT - 80
    -- Bonus3 满级房子
CodeGameScreenMrCashGoMachine.EFFECT_BONUS_BigVilla = GameEffect.EFFECT_SELF_EFFECT - 70
    -- Bonus4  bonus移动
CodeGameScreenMrCashGoMachine.EFFECT_BONUS_CashRain = GameEffect.EFFECT_SELF_EFFECT - 60
    

-- bonus的四种奖励类型 (1:jackpot类型奖励 2:大图标滚动玩法 3:bonus移动玩法 4:满级房子玩法)
CodeGameScreenMrCashGoMachine.BONUSTYPE_1 = 1
CodeGameScreenMrCashGoMachine.BONUSTYPE_2 = 2
CodeGameScreenMrCashGoMachine.BONUSTYPE_3 = 3
CodeGameScreenMrCashGoMachine.BONUSTYPE_4 = 4

CodeGameScreenMrCashGoMachine.m_panelOpacity = 160

-- 构造函数
function CodeGameScreenMrCashGoMachine:ctor()
    CodeGameScreenMrCashGoMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

 
    --init
    self:initGame()
end

function CodeGameScreenMrCashGoMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    
    -- free结束时的一轮jackpot列表
    self.m_freeOverJackpotList = {}
    -- bonus触发free时奖励的free次数
    self.m_freeSpinCount = 6
    -- 预告中奖标记
    self.m_isPlayWinningNotice = false
    -- 本次触发bonus是否为重连触发(上一次已经请求过数据了，本次需要跳过发送请求的接口)
    self.m_bIsBonusReconnect = false
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMrCashGoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MrCashGo"  
end




function CodeGameScreenMrCashGoMachine:initUI()

    -- freespinBar
    self.m_freeSpinBar = util_createView("CodeMrCashGoSrc.MrCashGoFreespinBarView")
    self:findChild("FreeSpinBar"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(false)

    --freeMore界面
    self.m_freeMoreView = util_createView("CodeMrCashGoSrc.MrCashGoFreespinMoreView")
    self:findChild("FreeSpinMore"):addChild(self.m_freeMoreView)
    self.m_freeMoreView:setVisible(false)
    
    --freeStart界面
    self.m_freeStartView = util_createView("CodeMrCashGoSrc.MrCashGoFreespinStartView")
    self:findChild("FreeSpinMore"):addChild(self.m_freeStartView)
    self.m_freeStartView:setVisible(false)

    -- free过场 1,2
    self.m_freeGuoChang_1 = util_spineCreate("MrCashGo_GC",true,true)
    self:findChild("FreeGuoChang"):addChild(self.m_freeGuoChang_1)
    self.m_freeGuoChang_1:setVisible(false)
    self.m_freeGuoChang_2 = util_spineCreate("MrCashGo_GC2",true,true)
    self:findChild("FreeGuoChang"):addChild(self.m_freeGuoChang_2)
    self.m_freeGuoChang_2:setVisible(false)

    -- 奖池
    self.m_jackpotBar = util_createView("CodeMrCashGoSrc.MrCashGoJackPotBarView", self)
    self:findChild("JackpotBar"):addChild(self.m_jackpotBar)

    -- 等级框
    self.m_levelBoxManager = util_createView("CodeMrCashGoSrc.MrCashGoLevelBoxManager", self)
    self:findChild("LevelBox"):addChild(self.m_levelBoxManager)

    --lookUp
    self.m_lookUpView = util_createAnimation("MrCashGo/LookUp.csb")
    self:findChild("Node_lookUp"):addChild(self.m_lookUpView)
    self.m_lookUpView:setVisible(false)

    -- bonus
    self.m_bonusGame = util_createView("CodeMrCashGoSrc.MrCashGoBonusGame", self)
    self:findChild("Map"):addChild(self.m_bonusGame)
    self.m_bonusGameData = {}

    -- mini轮盘 处理大图标假滚
    self.m_bonusMiniMachine = util_createView("CodeMrCashGoSrc.MrCashGoBonusReel", self)
    self:findChild("LevelBox"):addChild(self.m_bonusMiniMachine)
    self.m_bonusMiniMachine:setVisible(false)

    -- 大角色
    self.m_roleSpine = util_spineCreateDifferentPath("Socre_MrCashGo_jiaose", "Socre_MrCashGo_Bonus", true, true)
    self:findChild("Node_Role_Down"):addChild(self.m_roleSpine)
    self:playRoleIdleframe()
    -- 大角色( 在棋盘上层 )
    self.m_roleSpine_Up = util_spineCreateDifferentPath("Socre_MrCashGo_jiaose", "Socre_MrCashGo_Bonus", true, true)
    self:findChild("Node_Role_Up"):addChild(self.m_roleSpine_Up)
    self.m_roleSpine_Up:setVisible(false)

    -- 背景spine 动效没办法在spine内做表现比较好的透明度渐变，创建两个吧 程序淡出
    local bgParent = self:findChild("bg")
    self.m_gameBgSpine_base = util_spineCreate("GameScreenMrCashGoBg",true,true)
    bgParent:addChild(self.m_gameBgSpine_base)
    self.m_gameBgSpine_free = util_spineCreate("GameScreenMrCashGoBg",true,true)
    bgParent:addChild(self.m_gameBgSpine_free)
    util_setCascadeOpacityEnabledRescursion(self.m_gameBgSpine_base, true)
    util_setCascadeOpacityEnabledRescursion(self.m_gameBgSpine_free, true)

    --bottom底栏反馈
    self.m_bottomUiEffect = util_createAnimation("MrCashGo_Fankui.csb")
    self:addChild(self.m_bottomUiEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    self.m_bottomUiEffect:setVisible(false)
   
    --中奖预告 绿、金
    self.m_yugaoSpine = util_spineCreate("MrCashGo_YGq",true,true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpine)
    self.m_yugaoSpine:setVisible(false)

    self.m_yugaoSpineGold = util_spineCreate("MrCashGo_YGqj",true,true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineGold)
    self.m_yugaoSpineGold:setVisible(false)

    --图标连线遮罩
    self.m_lineMask = self:createMrCashGoMask()
    --棋盘遮罩
    self:findChild("Panel_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

    -- 初始化时设置为base展示
    self:findChild("BaseReel"):setVisible(true)
    self:findChild("FreeReel"):setVisible(false)
    self.m_gameBgSpine_base:setVisible(true)
    self.m_gameBgSpine_free:setVisible(false)
    util_spinePlay(self.m_gameBgSpine_base, "idleframe", true)

    self:runCsbAction("idle", true)
end

function CodeGameScreenMrCashGoMachine:enterGamePlayMusic(  )
    self:playEnterGameSound("MrCashGoSounds/music_MrCashGo_enter.mp3")
end

function CodeGameScreenMrCashGoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_levelBoxManager:upDatelevelBoxPos()
    local bottomEffectPos = util_convertToNodeSpace(self.m_bottomUI:findChild("WinNode_fly"), self)
    self.m_bottomUiEffect:setPosition(bottomEffectPos)

    CodeGameScreenMrCashGoMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        -- bonus重连屏蔽spinBtn
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    end
end


function CodeGameScreenMrCashGoMachine:addObservers()
    CodeGameScreenMrCashGoMachine.super.addObservers(self)

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

        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local collectLeftCount = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        local isFree = collectTotalCount > 0 and collectLeftCount > 0

        local soundName = string.format("MrCashGoSounds/music_MrCashGo_last_win_base_%d.mp3", soundIndex)
        if isFree then
            soundName = string.format("MrCashGoSounds/music_MrCashGo_last_win_free_%d.mp3", soundIndex)
        end

        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- 升级边框音效播放
    self.m_upGradeNode =  cc.Node:create()
    self:addChild(self.m_upGradeNode)
    self.m_upGradeSoundList = {}
    gLobalNoticManager:addObserver(self,function(self,params)
        self:noticCallBack_playUpGradeLevelBoxSound(params)
    end,"MrCashGoMachine_playUpGradeLevelBoxSound")
end

function CodeGameScreenMrCashGoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMrCashGoMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMrCashGoMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_L5 then
        return "Socre_MrCashGo_10"
    elseif symbolType == self.SYMBOL_L6 then
        return "Socre_MrCashGo_11"
    elseif symbolType == self.SYMBOL_Bonus then
        return "Socre_MrCashGo_Bonus"
    elseif symbolType == self.SYMBOL_LevelBox_1 then
        return "Socre_MrCashGo_Scatter_0"
    elseif symbolType == self.SYMBOL_LevelBox_2 then
        return "Socre_MrCashGo_Scatter_1"
    elseif symbolType == self.SYMBOL_LevelBox_3 then
        return "Socre_MrCashGo_Scatter_2"
    elseif symbolType == self.SYMBOL_Scatter_2x2 then
        return "Socre_MrCashGo_Scatter_2x2"
    elseif symbolType == self.SYMBOL_Scatter_3x3 then
        return "Socre_MrCashGo_Scatter_3x3"
    elseif symbolType == self.SYMBOL_Blank then
        return "Socre_MrCashGo_Blank"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMrCashGoMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMrCashGoMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end



-----------------------------主界面上挂载的控件-----------------------------------
--[[
    bg
]]
function CodeGameScreenMrCashGoMachine:changeLevelBgAndReel(_model)
    -- base | free
    local isBase = _model == "base"
    local isFree = _model == "free"
    --背景
    self:findChild("FreeEffect"):setVisible(isFree)
    --卷轴
    self:findChild("BaseReel"):setVisible(isBase)
    self:findChild("FreeReel"):setVisible(isFree)


    --背景 层级高的做淡出
    local baseBgOrder = isBase and 10 or 50
    local freeBgOrder = isFree and 10 or 50
    self.m_gameBgSpine_base:setLocalZOrder(baseBgOrder)
    self.m_gameBgSpine_free:setLocalZOrder(freeBgOrder)
    self.m_gameBgSpine_base:setVisible(true)
    self.m_gameBgSpine_free:setVisible(true)

    local actNode = self.m_gameBgSpine_free
    local actList = {}
    
    if isBase then
        util_spinePlay(self.m_gameBgSpine_base, "idleframe", true)
    else
        actNode = self.m_gameBgSpine_base
        util_spinePlay(self.m_gameBgSpine_free, "idleframe2", true)
    end

    table.insert(actList, cc.FadeOut:create(0.5))
    table.insert(actList, cc.CallFunc:create(function()
        actNode:setVisible(false)
        actNode:setOpacity(255)
    end))
    actNode:runAction(cc.Sequence:create(actList))
end

--[[
    人物spine
]]
function CodeGameScreenMrCashGoMachine:playRoleAnim(_animName,_loop,_fun)
    util_spinePlay(self.m_roleSpine, _animName, _loop)
    if _fun then
        util_spineEndCallFunc(self.m_roleSpine, _animName, _fun)
    end
end
function CodeGameScreenMrCashGoMachine:playRoleAnim_Up(_animName,_loop,_fun)
    self.m_roleSpine_Up:setVisible(true)
    util_spinePlay(self.m_roleSpine_Up, _animName, _loop)
    util_spineEndCallFunc(self.m_roleSpine_Up, _animName, function()
        self.m_roleSpine_Up:setVisible(false)

        if _fun then
            _fun()
        end
    end)

end

function CodeGameScreenMrCashGoMachine:playRoleIdleframe()
    --区分free和base的idle动画
    local collectLeftCount = globalData.slotRunData.freeSpinCount
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount

    local idleName = "idle1_bace_idle"
    if collectTotalCount > 0 and collectLeftCount > 0 then
        idleName = "idle1_free_idle"
    end
    util_spinePlay(self.m_roleSpine, idleName, true)
end
--[[
    遮罩相关
]]
function CodeGameScreenMrCashGoMachine:createMrCashGoMask()
    --棋盘主类
    local mainClass = self
    --单列卷轴尺寸
    local reel = mainClass:findChild("sp_reel_0")
    local reelSize = reel:getContentSize() 
    local posX = reel:getPositionX()
    local posY = reel:getPositionY()
    local scaleX = reel:getScaleX()
    local scaleY = reel:getScaleY()
    --棋盘尺寸
    local offsetSize = cc.size(10, 5)
    reelSize.width = reelSize.width * scaleX * mainClass.m_iReelColumnNum + offsetSize.width
    reelSize.height = reelSize.height * scaleY + offsetSize.height
    --遮罩尺寸和坐标
    local clipParent = mainClass.m_onceClipNode or mainClass.m_clipParent
    local panelOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1
    local panel = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
    panel:setOpacity(self.m_panelOpacity)
    panel:setContentSize(reelSize.width, reelSize.height)
    panel:setPosition(cc.p(posX, posY - offsetSize.height/2))
    clipParent:addChild(panel, panelOrder)
    panel:setVisible(false)

    return panel
end
function CodeGameScreenMrCashGoMachine:playMaskFadeAction(_isFadeIn, _fun)
    local fadeTime      = 0.5
    local opacity       = _isFadeIn and 0 or self.m_lineMask:getOpacity()
    local targetOpacity = _isFadeIn and self.m_panelOpacity or 0

    local actList = {}
    local act_fade = cc.FadeTo:create(fadeTime, targetOpacity)
    local act_fun  = cc.CallFunc:create(function()
        if not _isFadeIn then
            self.m_lineMask:setVisible(false)
        end
    end)

    table.insert(actList, act_fade)
    table.insert(actList, act_fun)

    self.m_lineMask:stopAllActions()
    self.m_lineMask:setOpacity(opacity)
    self.m_lineMask:setVisible(true)
    self.m_lineMask:runAction(cc.Sequence:create(actList))

    if _fun then
        self:levelPerformWithDelay(fadeTime, function()
            _fun() 
        end)
    end
end

--[[
    事件通知
    _params = {
        信号
        是否必须播放音效
    }
]]
function CodeGameScreenMrCashGoMachine:noticCallBack_playUpGradeLevelBoxSound(_params)
    local symbolType = _params[1]
    local playSound  = _params[2]
    -- 同一时间多次触发播一遍
    if not playSound and nil ~= self.m_upGradeSoundList[symbolType] then
        return
    end
    

    local soundName = ""

    local bonusType = self.m_bonusGame:getCurBonusType()

    --大房子玩法升级格子时增加语音播放 不能是弹射出来的
    if 3 == bonusType and not _params[3] then
        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_levelBox_upGrade_bigVilla.mp3") 
    end
    
    if symbolType == self.SYMBOL_LevelBox_1 then
        soundName = "MrCashGoSounds/sound_MrCashGo_levelBox_upGrade_1.mp3"
    elseif symbolType == self.SYMBOL_LevelBox_2 then
        soundName = "MrCashGoSounds/sound_MrCashGo_levelBox_upGrade_2.mp3"
    elseif   symbolType == self.SYMBOL_LevelBox_3 then
        soundName = "MrCashGoSounds/sound_MrCashGo_levelBox_upGrade_3.mp3"
    end

    self.m_upGradeSoundList[symbolType] = gLobalSoundManager:playSound(soundName)
    self:levelPerformWithDelay(1, function()
        self.m_upGradeSoundList[symbolType] = nil
    end)
end
----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenMrCashGoMachine:isTriggerUpGradeLevelBoxRun()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local leftFsCount  = self.m_runSpinResultData.p_freeSpinsLeftCount
    local totalFsCount = self.m_runSpinResultData.p_freeSpinsTotalCount

    -- 字段存在 且 不在free触发时那一次spin
    -- 触发时freeStart会执行一下 playEffect_UpGradeLevelBoxRun
    if selfData.run_level and (leftFsCount<=0 or leftFsCount ~= totalFsCount) then
        return true
    end
    
    return false
end
function CodeGameScreenMrCashGoMachine:playEffect_UpGradeLevelBoxRun(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local runLevel = selfData.run_level or {}

    local time = self:upDataLevelBoxByLevelData(runLevel)

    self:levelPerformWithDelay(time, function()
        if _fun then
            _fun()
        end
    end)
end

function CodeGameScreenMrCashGoMachine:upDataLevelBoxByLevelData(_levelData)
    local time = 0
    for _boxLevel,_boxPosList in ipairs(_levelData) do
        for i,_pos in ipairs(_boxPosList) do
            
            local iPos = tonumber(_pos)
            local fixPos = self:getRowAndColByPos(iPos)
            local iconData = {
                symbolType = self:getLevelBoxSymbolType(_boxLevel),             
            }
            time = self.m_levelBoxManager:upDateLevelBoxIcon(fixPos.iY , fixPos.iX, iconData)

        end
    end

    return time
end

function CodeGameScreenMrCashGoMachine:isTriggerUpGradeLevelBoxTransfer()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if selfData.change_level then
        return true
    end

    return false
end
function CodeGameScreenMrCashGoMachine:playEffect_UpGradeLevelBoxTransfer(_fun)
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local changeLevel = selfData.change_level

    local ccbName = self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)

    local soundList = {
        "MrCashGoSounds/sound_MrCashGo_bonusGame_jackpot.mp3",
        "MrCashGoSounds/sound_MrCashGo_bonusGame_bigVilla.mp3",
        "MrCashGoSounds/sound_MrCashGo_bonusGame_cashRain.mp3",
        "MrCashGoSounds/sound_MrCashGo_bonusGame_moneyBag.mp3",
    }
    local soundName = soundList[math.random(1, #soundList)]
    gLobalSoundManager:playSound(soundName)

    -- 人物勾起来scatter丢到一个地方
    self:playRoleAnim("qiandaiweiyi_huigun", false, function()
        self:playRoleIdleframe()
    end)
    -- weiyi
    
    -- 16帧开始移动
    self:levelPerformWithDelay(16/30, function()
        local flyTime = 12/30 

        for _boxLevel,_posData in ipairs(changeLevel) do
            for i,_data in ipairs(_posData) do
                local iconData = {
                    symbolType = self:getLevelBoxSymbolType(_boxLevel),             
                }
                
                local sourcePos  = tonumber(_data[2])
                local upGradePos = tonumber(_data[1])
                local fixPos1 = self:getRowAndColByPos(sourcePos) 
                local fixPos2 = self:getRowAndColByPos(upGradePos)
                local slotsNode_1 = self:getFixSymbol(fixPos1.iY, fixPos1.iX)
                local slotsNode_2 = self:getFixSymbol(fixPos2.iY, fixPos2.iX)
            
                local startPosition = util_convertToNodeSpace(slotsNode_1, self)
                local endPosition   = util_convertToNodeSpace(slotsNode_2, self)
                -- 临时的飞行小块
                local flySlotsNode = self:createMrCashGoTempSymbol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                self:addChild(flySlotsNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+2)
                flySlotsNode:setScale(self.m_machineRootScale)
                flySlotsNode:setPosition(startPosition)
                
                -- bonus从框内出来
                flySlotsNode:runAnim("weiyi", false)
                -- 跳到升级的地方
                local actList = {}
                
                table.insert(actList, cc.DelayTime:create(5/30))
                if fixPos1.iY ~= fixPos2.iY then
                    local distance = math.sqrt((endPosition.x - startPosition.x) * (endPosition.x - startPosition.x) + (endPosition.y - startPosition.y) * (endPosition.y - startPosition.y))
                    local radius = distance/2
                    local flyAngle = util_getAngleByPos(startPosition, endPosition)
                    local offsetAngle = endPosition.x > startPosition.x and -90 or 90
                    local pos1 = cc.p( util_getCirclePointPos(startPosition.x, startPosition.y, radius, flyAngle + offsetAngle) )
                    local pos2 = cc.p( util_getCirclePointPos(endPosition.x, endPosition.y, radius/2, flyAngle + offsetAngle) )
                
                    table.insert(actList, cc.BezierTo:create(flyTime, {pos1, pos2, endPosition}))
                -- 直线移动
                else
                    table.insert(actList, cc.MoveTo:create(flyTime, endPosition))
                end
                table.insert(actList, cc.CallFunc:create(function()
                    -- 升级
                    self.m_levelBoxManager:upDateLevelBoxIcon(fixPos2.iY , fixPos2.iX, iconData, nil, true)
                end))
                table.insert(actList, cc.DelayTime:create(25/30))
                table.insert(actList, cc.RemoveSelf:create())

                flySlotsNode:runAction(cc.Sequence:create(actList))
            end
        end
    end)

    
    -- qiandaiweiyi_huigun(0~40) + weiyi(0~37)
    local time = 16/30 + 37/30
    self:levelPerformWithDelay(time, function()
        if _fun then
            _fun()
        end
    end)
    
end

function CodeGameScreenMrCashGoMachine:isTriggerOpenLevelBox()
    local storesIcons = self.m_runSpinResultData.p_storedIcons or {}

    if #storesIcons > 0 then
        return true
    end

    return false
end
--[[
    开箱流程:
        全部边框变为对应宝箱
        从低到高按等级开箱
            从左到右按魔杖挥舞的位置开箱

]]
function CodeGameScreenMrCashGoMachine:playEffect_OpenLevelBox(_fun)
    self:clearWinLineEffect()
    local storesIcons = self.m_runSpinResultData.p_storedIcons or {}
    local levelBoxList = {
        {},
        {},
        {}
    }

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_levelBox_actionframe.mp3")

    -- 刷新一下数据 and 更改等级框背景
    local animTime = 0
    for i,_data in ipairs(storesIcons) do
        local iPos = tonumber(_data[1])
        local fixPos = self:getRowAndColByPos(iPos)
        local iconData = {
            coins = _data[2],
            coinsType =  _data[3],
        }
        self.m_levelBoxManager:upDateLevelBoxData(fixPos.iY , fixPos.iX, iconData)
        animTime = self.m_levelBoxManager:upDateCoinsBgShow(fixPos.iY , fixPos.iX)
        
        local levelBox = self.m_levelBoxManager:getLevelBox(fixPos.iY, fixPos.iX)
        local iconData = levelBox.m_data
        table.insert(levelBoxList[iconData.level], iPos)
    end

    self:levelPerformWithDelay(animTime, function()
        self:freeOverChangeReel()
        -- 从低到高展示赢钱结果
        self:playLevelBoxOpen_level(1, levelBoxList, function()
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_freeOver_juese_huanhu.mp3")
            -- 所有房子收集完毕 角色欢呼
            self:playRoleAnim("huanhu", false, function()
                self:playRoleIdleframe()

                self:levelPerformWithDelay(0.5, function()
                    if _fun then
                        _fun()
                    end
                end)                
            end)
        end)
    end)
end

-- 递归展示等级框打开 - 等级
function CodeGameScreenMrCashGoMachine:playLevelBoxOpen_level(_level, _dataList, _fun)
    local data = _dataList[_level]
    if not data then
        -- --开始收集流程
        -- self:playFreeOverFlyWinCoins(self.m_freeOverCollectList,function()
        --     if _fun then
        --         _fun()
        --     end
        -- end)
        if _fun then
            _fun()
        end
        return
    end
    -- 首次进入递归时初始化一些数据
    if 1 == _level then
        self.m_freeOverCollectList = {}
    end
    


    local nextLevel = _level + 1   
    
    if #data < 1 then
        -- 下一轮
        self:playLevelBoxOpen_level(nextLevel, _dataList, _fun)
    else
        local soundName = string.format("MrCashGoSounds/sound_MrCashGo_freeOver_roleSell_%d.mp3", _level)
        gLobalSoundManager:playSound(soundName)
        

        --人物挥手打开一个等级的所有宝箱 
        self:playRoleAnim("chushou_huigun", false, function()
            self:playRoleIdleframe()
        end)
        self:playRoleAnim_Up("chushou_huigun2", false)
        --房子延时按列依次出现
        self:playLevelBoxOpen_index(1, data, function()
            -- 组织一下本轮所有 普通奖励 和 jackpot奖励
            self:saveFreeOverBoxAwardData(data, _level)
            self:playFreeOverFlyWinCoins(self.m_freeOverCollectList,function()
                 -- 下一轮
                self:playLevelBoxOpen_level(nextLevel, _dataList, _fun)
            end)
        end, 0)
    end
end
-- 递归展示等级框打开 - 等级框内index
function CodeGameScreenMrCashGoMachine:playLevelBoxOpen_index(_index, _dataList, _fun, _delayTime)
    local iPos = _dataList[_index]
    if not iPos then
        --跳出
        self:levelPerformWithDelay(_delayTime, _fun)
        return
    end

    local fixPos = self:getRowAndColByPos(iPos)
    local animTime = 33/30
    -- 按照列数配合人物挥手依次出现
    local delayTime = 17/30 + (fixPos.iY-1) * 1/30
    self:levelPerformWithDelay(delayTime, function()
        self.m_levelBoxManager:upDateCoinsShow(fixPos.iY, fixPos.iX)
    end)

    if 1 == _index then
        self:levelPerformWithDelay(17/30, function()
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_levelBox_showCoins.mp3")
        end)
    end
    
    

    self:playLevelBoxOpen_index(_index+1, _dataList, _fun, math.max(_delayTime, delayTime+animTime))
end
-- 存一下本轮所有的奖励
function CodeGameScreenMrCashGoMachine:saveFreeOverBoxAwardData(_posData, _level)
    for i,_iPos in ipairs(_posData) do
        local fixPos   = self:getRowAndColByPos(_iPos)
        local levelBox = self.m_levelBoxManager:getLevelBox(fixPos.iY, fixPos.iX)
        local iconData = levelBox.m_data

        local coinsData = {
            level   = _level,
            iPos    = _iPos,
            coins   = iconData.coins,
        }
        if iconData.jpIndex > 0 then
            coinsData.jpIndex = iconData.jpIndex
        end
        table.insert(self.m_freeOverCollectList, coinsData)
    end

    local sortFunc = function(a, b)
        if a and b then
            -- 等级
            if a.level ~= b.level then
                return a.level < b.level
            end
            -- 位置
            if a.iPos ~= b.iPos then
                local aFixPos = self:getRowAndColByPos(a.iPos)
                local bFixPos = self:getRowAndColByPos(b.iPos)
                -- 列
                if aFixPos.iY ~= bFixPos.iY then
                    return aFixPos.iY < bFixPos.iY
                end
                -- 行
                if aFixPos.iX ~= bFixPos.iX then
                    return aFixPos.iX > bFixPos.iX
                end
            end
        end

        return false
    end
    table.sort(self.m_freeOverCollectList, sortFunc)
end
--free结束时将房子下面的图标修改为最终的赢钱结果加入滚动带走
function CodeGameScreenMrCashGoMachine:freeOverChangeReel()
    local storesIcons = self.m_runSpinResultData.p_storedIcons or {}
    local levelBox    = self.m_runSpinResultData.p_selfMakeData.level

    for _index,_data in ipairs(storesIcons) do
        local iPos = tonumber(_data[1])
        local fixPos = self:getRowAndColByPos(iPos)
        local slotsNode   = self:getFixSymbol(fixPos.iY, fixPos.iX)
        local symbolType  = self.SYMBOL_LevelBox_1
        local bShowLv3Lab = false
        for _level,_levelPosData in ipairs(levelBox) do
            local bool = false
            for i,_iPos in ipairs(_levelPosData) do
                if iPos == _iPos then
                    bool = true
                    symbolType = self.SYMBOL_LevelBox_1 + (_level-1)

                    local levelBox = self.m_levelBoxManager:getLevelBox(fixPos.iY, fixPos.iX) 
                    bShowLv3Lab = levelBox:isShowLv3Lab(levelBox.m_data.symbolType, levelBox.m_data.coins)
                    break
                end
            end
            if bool then
                break
            end
        end
        --修改信号
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        slotsNode:changeCCBByName(ccbName, symbolType)
        slotsNode:runAnim("idleframe", false)
        --刷新赢钱展示
        slotsNode:getCcbProperty("mini"):setVisible("mini"   == _data[3])
        slotsNode:getCcbProperty("minor"):setVisible("minor"  == _data[3])
        local labCoins = slotsNode:getCcbProperty("m_lb_coins")
        local labCoins_0 = slotsNode:getCcbProperty("m_lb_coins_0")

        local coinsVisible = ""   == _data[3]
        labCoins:setVisible(coinsVisible and not bShowLv3Lab)
        labCoins_0:setVisible(coinsVisible and bShowLv3Lab)
        if coinsVisible then
            local sCoins = util_formatCoins(_data[2], 3)
            labCoins:setString(sCoins)
            labCoins_0:setString(sCoins)
            self:updateLabelSize({label=labCoins,sx=1,sy=1}, 239)
            self:updateLabelSize({label=labCoins_0,sx=1,sy=1}, 239)
        end
    end
end

-- 宝箱的金币和jackpot飞向底栏
function CodeGameScreenMrCashGoMachine:playFreeOverFlyWinCoins(_coinsList, _fun)
    if #_coinsList <= 0 then
        _fun()
        return
    end
    --[[
        coinsData = {
            iPos    = 0,
            coins   = 0,
            -- 可选参数 存在的话必为 jackpot
            jpIndex = 1,
        }
    ]]
    local coinsData = table.remove(_coinsList, 1)

    local fixPos   = self:getRowAndColByPos(coinsData.iPos)
    local levelBox = self.m_levelBoxManager:getLevelBox(fixPos.iY, fixPos.iX) 
    local labCoins = levelBox:getFlyEffectCoinsLab()
    local bShowLv3Lab = levelBox:isShowLv3Lab(levelBox.m_data.symbolType, levelBox.m_data.coins)

    local startPos = util_convertToNodeSpace(labCoins, self)
    local endPos   = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self)

    local flyLab = util_createAnimation("MrCashGo_ScatterLab.csb") 
    self:addChild(flyLab, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    
    local iCoins = coinsData.coins
    local sCoins = util_formatCoins(iCoins, 3)
    local coinsLab   = flyLab:findChild("m_lb_coins")
    local coinsLab_0 = flyLab:findChild("m_lb_coins_0")
    coinsLab:setVisible(nil == coinsData.jpIndex and not bShowLv3Lab)
    coinsLab_0:setVisible(nil == coinsData.jpIndex and bShowLv3Lab)
    coinsLab:setString(sCoins)   
    coinsLab_0:setString(sCoins)    
    flyLab:findChild("mini"):setVisible(4 == coinsData.jpIndex)
    flyLab:findChild("minor"):setVisible(3 == coinsData.jpIndex)

    -- labCoins:setVisible(false)
    flyLab:setScale(self.m_machineRootScale)
    flyLab:setPosition(startPos)
    local info={label = flyLab,sx = 1,sy = 1}
    self:updateLabelSize(info, 239)

    local particle = flyLab:findChild("Particle_1")
    particle:setPositionType(0) 
    particle:setDuration(-1)

    levelBox:playFlyEffectAnim()
    local flyTime = 18/60
    flyLab:runCsbAction("fangda", false, function()
        local actList = {}
        table.insert(actList, cc.MoveTo:create(flyTime, endPos))
        table.insert(actList, cc.CallFunc:create(function()
            -- 底栏当前展示的赢钱数值
            local bottomWinCoin = self:getMrCashGoCurBottomWinCoins()
            self:setLastWinCoin(bottomWinCoin + iCoins)
            self:updateBottomUICoins(0, iCoins)
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_collectEnd.mp3")
            self.m_bottomUiEffect:setVisible(true)
            self.m_bottomUiEffect:runCsbAction("fankui", false)
            -- 飞行到底部后 看下要不要弹jackpot弹板
            if nil ~= coinsData.jpIndex then
                self:showJackpotView(coinsData.coins, coinsData.jpIndex, false, function()
                    self:playFreeOverFlyWinCoins(_coinsList, _fun)
                end)
            else
                self:playFreeOverFlyWinCoins(_coinsList, _fun)
            end
        end))
        -- 粒子延迟消失
        table.insert(actList, cc.CallFunc:create(function()
            flyLab:findChild("m_lb_coins"):setVisible(false)
            flyLab:findChild("m_lb_coins_0"):setVisible(false)
            flyLab:findChild("mini"):setVisible(false)
            flyLab:findChild("minor"):setVisible(false)

            flyLab:findChild("Particle_1"):stopSystem()
            flyLab:findChild("Particle_1"):runAction(cc.FadeOut:create(0.5))
        end))
        table.insert(actList,cc.DelayTime:create(0.5))
        table.insert(actList, cc.RemoveSelf:create())

        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_collectStart.mp3")
        flyLab:runCsbAction("weiyi", false)
        flyLab:runAction(cc.Sequence:create(actList))
    end)

    
end
-- 展示jackpot弹板
function CodeGameScreenMrCashGoMachine:showJackpotView(_coins, _jackpotIndex, isMulti, _fun)
    self.m_jackpotBar:playJackpotWinAnim(_jackpotIndex, function()
        --通知jackpot
        globalData.jackpotRunData:notifySelfJackpot(_coins, _jackpotIndex)

        local curMode = self:getCurrSpinMode()
        local isAuto = curMode == AUTO_SPIN_MODE or curMode == FREE_SPIN_MODE
        local data = {
            coins = _coins,
            jackpotIndex = _jackpotIndex,
            isMulti = isMulti,
            isAuto  = isAuto,
        }
        local newFun = function()
            _fun()

            self.m_jackpotBar:hideJackpotWinAnim(_jackpotIndex)
        end

        self.m_bonusGame:hideJackpotLightAnim()
        local jackPotWinView = util_createView("CodeMrCashGoSrc.MrCashGoJackPotWinView", data)
        jackPotWinView:setOverAniRunFunc(newFun)
        gLobalViewManager:showUI(jackPotWinView)
        jackPotWinView:initViewData()
    end)
end


function CodeGameScreenMrCashGoMachine:isTriggerBonusGame()
    local selfData  = self.m_runSpinResultData.p_selfMakeData or {}
    
    if selfData.bonus then
        return true
    end

    return false
end
function CodeGameScreenMrCashGoMachine:saveBonusGameData()
    self:clearBonusGameData()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local bonus    = selfData.bonus

    
    self.m_bonusGameData.mapPos = tonumber(selfData.mappos) 
    local oneMaxNumber = 6 -- 单个最大点数
    local minNumber = 1
    local maxNumber = 6
    if self.m_bonusGameData.mapPos <= oneMaxNumber then
        maxNumber = self.m_bonusGameData.mapPos - 1
    else
        minNumber = self.m_bonusGameData.mapPos - oneMaxNumber
    end
    local dice1 = math.random(minNumber, maxNumber)
    local dice2 = self.m_bonusGameData.mapPos - dice1
    -- 两个骰子的点数
    self.m_bonusGameData.dice     = {dice1, dice2}
    -- 触发玩法的bonus图标位置
    self.m_bonusGameData.bonusPos = clone(bonus.bonuspos)
    -- type == 2,3,4 时  生成的等级框
    self.m_bonusGameData.level    = clone(bonus.level)
    -- 本次移动触发的bonus玩法类型 (1:jackpot类型奖励 2:大图标滚动玩法 3:bonus移动玩法 4:满级房子玩法)
    self.m_bonusGameData.bonusType = tonumber(bonus.type) 
    -- 本次触发是否为重连触发(上一次已经请求过数据了，本次需要跳过发送请求的接口)
    self.m_bonusGameData.isReconnect = self.m_bIsBonusReconnect

    -- 根据不同奖励类型回传的可选字段
    if self.m_bonusGameData.bonusType == self.BONUSTYPE_1 then
        self.m_bonusGameData.coinsType  = bonus.coinstype
        self.m_bonusGameData.coinsValue = tonumber(bonus.coins) 
    elseif self.m_bonusGameData.bonusType == self.BONUSTYPE_2 then
        self.m_bonusGameData.reels     = clone(bonus.reels) 
        self.m_bonusGameData.miniReels = clone(bonus.reels) 
        -- 另一份大图标停轮数据，将大scatter覆盖的区域改为90
        for _level,_posList in ipairs(self.m_bonusGameData.level) do
            for _index,_iPos in ipairs(_posList) do
                local fixPos = self:getRowAndColByPos(_iPos)
                local line   = self.m_iReelRowNum - fixPos.iX + 1
                local iCol   = fixPos.iY
                self.m_bonusGameData.miniReels[line][iCol] = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            end
        end
    end

    self.m_bonusGameData.bonusOverFun = function()
        -- self:resetMusicBg()
        -- self:setMaxMusicBGVolume( )
        
        if self.m_bonusGameData.bonusType == self.BONUSTYPE_1 then
            self.m_bIsBonusReconnect = false
            self:clearBonusGameData()
            self.m_bonusGame:clearBonusData()
        elseif  self.m_bonusGameData.bonusType == self.BONUSTYPE_2 then
            self:triggerBonusAwardFree()
        elseif  self.m_bonusGameData.bonusType == self.BONUSTYPE_3 then
            self:triggerBonusAwardFree()
        elseif  self.m_bonusGameData.bonusType == self.BONUSTYPE_4 then
            self:triggerBonusAwardFree()
        end

        if nil ~= self.m_bonusEffect then
            self.m_bonusEffect.p_isPlay= true
            self.m_bonusEffect = nil
        end
        

        self:playBonusGameOver(function()
            --压暗消失
            self:playMaskFadeAction(false)
            -- 下一步流程
            self:levelPerformWithDelay(25/60,function()
                self:playGameEffect()
            end)
        end)
    end
    
end
function CodeGameScreenMrCashGoMachine:getBonusGameData()
    return self.m_bonusGameData
end
function CodeGameScreenMrCashGoMachine:clearBonusGameData()
    self.m_bonusGameData = {}
end

-- bonus2 超大图标移动
function CodeGameScreenMrCashGoMachine:playEffect_bonusMoneyBag(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusGameData = self:getBonusGameData()

    -- 切换到mini轮盘
    local curReels  = self.m_runSpinResultData.p_reels
    self.m_bonusMiniMachine:resetBonusReelShow(curReels, bonusGameData.reels, bonusGameData.level)
    self.m_bonusMiniMachine:setVisible(true)
    self:findChild("Reel"):setVisible(false)

    local reelDownFun = function()
        -- 切换回主轮盘
        self:resetMrCashGoReelShow(bonusGameData.miniReels)
        self.m_bonusMiniMachine:setVisible(false)
        self:findChild("Reel"):setVisible(true)
        -- 存储等级框数据
        self.m_runSpinResultData.p_selfMakeData.run_level = bonusGameData.level

         -- self:triggerBonusAwardFree()
        if _fun then
            _fun()
        end
    end
    

    self.m_bonusMiniMachine:startSlideMove(reelDownFun)
end
-- bonus3 满级房子
function CodeGameScreenMrCashGoMachine:playEffect_bonusBigVilla(_fun)
    -- 存储等级框数据
    local bonusGameData = self:getBonusGameData()
    self.m_runSpinResultData.p_selfMakeData.run_level = bonusGameData.level
    if _fun then
        _fun()
    end
end

-- bonus4 bonus移动
function CodeGameScreenMrCashGoMachine:playEffect_bonusCashRain(_fun)
    local bonusGameData = self:getBonusGameData()
    local bonusList = bonusGameData.bonusPos
    -- 播放循环idle
    self:playCashRainBonusIdle(bonusList)

    --棋盘压暗
    self:playMaskFadeAction(true, function()
        -- bonus开始跑路 
        self:playBonusSymbolMoveAnim(1,bonusList, function()
            --压暗消失
            self:playMaskFadeAction(false)
            if _fun then
                _fun()
            end
        end)
    end)
end
function CodeGameScreenMrCashGoMachine:playBonusSymbolMoveAnim(_index, _bonusList, _fun, _lastSoundId)
    local pos = _bonusList[_index]
    if not pos then
        -- 保证最后一次的音效播放完毕
        if _fun then
            _fun()
        end
        
        return 
    end

    local iPos = tonumber(pos)
    local fixPos = self:getRowAndColByPos(iPos)
    local bonusNode = self:getFixSymbol(fixPos.iY, fixPos.iX)
    local tempBonus = self:createMrCashGoTempSymbol(self.SYMBOL_Bonus)
    self:addChild(tempBonus, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
    util_setCascadeOpacityEnabledRescursion(tempBonus, true)
    tempBonus:setScale(self.m_machineRootScale)
    local bonusPos = util_convertToNodeSpace(bonusNode, self)
    -- bonusPos.y = bonusPos.y + self.m_SlotNodeH/2
    tempBonus:setPosition(bonusPos)

    local soundId = gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_CashRain.mp3")
    local soundTime = 3
    if 1 == _index then
        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_CashRain_first.mp3")
    end
    
    -- bonus跳出来
    tempBonus:runAnim("bian", false, function()
        if nil ~= _lastSoundId then
            gLobalSoundManager:stopAudio(_lastSoundId)
        end

        local levelBox = self.m_levelBoxManager:getLevelBox(fixPos.iY, fixPos.iX)
        local fadeTime = levelBox:playCellMaskFadeIn()
        self:levelPerformWithDelay(fadeTime, function()
            -- 放回原层级 参考这个 BaseMachine:checkChangeBaseParent()
            local pos = util_convertToNodeSpace(bonusNode, self.m_slotParents[bonusNode.p_cloumnIndex].slotParent)
            bonusNode.p_showOrder = self:getBounsScatterDataZorder(bonusNode.p_symbolType)
            self:changeBaseParent(bonusNode)
            bonusNode:resetReelStatus()
            bonusNode:setPosition(pos)
        end)
        
        
        
        -- 移动到 self.m_iReelColumnNum + 2 的 x坐标
        local oneStepTime = 20/30
        local stepCount   = self.m_iReelColumnNum + 2 - fixPos.iY
        local moveTime    = stepCount * oneStepTime
        local movePosx    = stepCount * self.m_SlotNodeW

        local actList  = {}
        local act_move   = cc.MoveBy:create(moveTime, cc.p(movePosx, 0))
        local act_fade   = cc.FadeOut:create(0.5)
        local act_remove = cc.RemoveSelf:create()
        local act_fun    = cc.CallFunc:create(function()
            local nextIndex = _index+1
            self:playBonusSymbolMoveAnim(nextIndex, _bonusList, _fun, soundId)
        end) 

        table.insert(actList, act_move)
        table.insert(actList, act_fade)
        table.insert(actList, act_remove)
        table.insert(actList, act_fun)

        
        tempBonus:runAnim("switch", true)
        tempBonus:runAction(cc.Sequence:create(actList))

        for iCol=fixPos.iY,self.m_iReelColumnNum do
            local levelBox = self.m_levelBoxManager:getLevelBox(iCol, fixPos.iX)
            local level = levelBox.m_data.level or 0

            if level < 3 then
                local nextLevel  = level + 1
                local curCol = iCol
                local iconData = {
                    symbolType = self:getLevelBoxSymbolType(nextLevel),             
                }

                self:levelPerformWithDelay(oneStepTime * (1 + curCol-fixPos.iY), function()
                    -- self:playCellMaskFadeOut(curCol, fixPos.iX)
                    self.m_levelBoxManager:upDateLevelBoxIcon(curCol, fixPos.iX, iconData, true)
                end)            
            end
        end
    end)
end
-- 给bonus提层到mask上面并，做一个遮罩淡出
function CodeGameScreenMrCashGoMachine:playCellMaskFadeOut(_iCol, _iRow)
    local slotsNode = self:getFixSymbol(_iCol, _iRow)
    local curParent = slotsNode:getParent()
    if curParent == self.m_clipParent then
        return
    end
    local slotsOrder      = self.m_lineMask:getLocalZOrder() + 1
    -- 提层
    slotsNode = util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, slotsNode.p_sumbolType, slotsOrder)
    
    local levelBox = self.m_levelBoxManager:getLevelBox(_iCol, _iRow)
    levelBox:playCellMaskFadeOut()
end
-- bonus 循环idle
function CodeGameScreenMrCashGoMachine:playCashRainBonusIdle(_bonusList)
    for _index,_pos in ipairs(_bonusList) do
        local iPos = tonumber(_pos)
        local fixPos = self:getRowAndColByPos(iPos)
        local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX)

        local slotsOrder      = self.m_lineMask:getLocalZOrder() + 1
        -- 提层
        slotsNode = util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, slotsNode.p_sumbolType, slotsOrder)
        -- 循环idle
        slotsNode:runAnim("idle", true)
    end
end

-- 添加bonus奖励的free事件 bonus和普通free不可能同时触发
function CodeGameScreenMrCashGoMachine:triggerBonusAwardFree()
    -- fs 总数量 | 剩余次数
    self.m_runSpinResultData.p_freeSpinsTotalCount = self.m_freeSpinCount
    self.m_runSpinResultData.p_freeSpinsLeftCount  = self.m_freeSpinCount
    self.m_iFreeSpinTimes                          = self.m_runSpinResultData.p_freeSpinsTotalCount
    globalData.slotRunData.freeSpinCount           = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount      = self.m_runSpinResultData.p_freeSpinsTotalCount


    --插入freeSpin 事件
    local effectData = GameEffectData.new()
    effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = effectData
end



-- 断线重连 
function CodeGameScreenMrCashGoMachine:MachineRule_initGame(  )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if self.m_bProduceSlots_InFreeSpin then
        local collectLeftCount = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if collectLeftCount ~= collectTotalCount then
            local levelBoxData = selfData.level
            self.m_levelBoxManager:upDateLevelBoxIconReconnect(levelBoxData)

            self.m_freeSpinBar:changeFreeSpinByCount()
            self.m_freeSpinBar:setVisible(true)

            self:changeLevelBgAndReel("free")
        end
    end
    
    if self:isTriggerBonusGame() then
        -- bonus获得jackpot奖励时 如果上次断线前已经点击了关闭弹板领取过奖励时，下次重连不触发bonus
        if 1 ~= selfData.bonus.type or not self.m_isBonusFeature then
            self.m_bIsBonusReconnect = self.m_isBonusFeature
            self.m_isBonusFeature    = nil
            self:saveBonusGameData()
            --不在free时自己把底栏赢钱带一下进入bonus
            if not self.m_bProduceSlots_InFreeSpin then
                local lineWinCoins = self.m_runSpinResultData.p_winAmount
                local params = {lineWinCoins, false, false}
                params[self.m_stopUpdateCoinsSoundIndex] = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
            end
        

            if not self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
            end
        else
            -- 移除底层添加的bonus事件
            if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                self:removeGameEffectType(GameEffect.EFFECT_BONUS)
            end
        end
        
        
    end
    

end

function CodeGameScreenMrCashGoMachine:initGameStatusData(gameData)
    CodeGameScreenMrCashGoMachine.super.initGameStatusData(self,gameData)

    local feature = gameData.feature
    if feature then
        if feature.action == "BONUS" then
            self.m_isBonusFeature = true
        end
    end

    if gameData.gameConfig.extra ~= nil then
        self.m_freeSpinCount = gameData.gameConfig.extra.freeSpinCount
    end
end
--
--单列滚动停止回调
--
function CodeGameScreenMrCashGoMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMrCashGoMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMrCashGoMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMrCashGoMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
---
-- 显示free spin
function CodeGameScreenMrCashGoMachine:showEffect_FreeSpin(effectData)
    --!!! 处于free模式时 freeMore在断线重连时不在展示弹板
    local curTotalTimes = self.m_freeSpinBar.m_freespinTotalTimes
    local newTotalTimes = globalData.slotRunData.totalFreeSpinCount
    if curTotalTimes == newTotalTimes and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        effectData.p_isPlay = true
        self:playGameEffect() 
        return  true
    end
    
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    self.m_beInSpecialGameTrigger = true
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- !!! 停掉背景音乐 freeMore不停止
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:clearCurMusicBg()
    end
    

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            --!!!插入修改
            scatterLineValue.iLineSymbolNum = #scatterLineValue.vecValidMatrixSymPos
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    if scatterLineValue ~= nil then
        --!!! 播放人物配合时间线
        self:playRoleAnim("naqiandai", false, function()
            self:playRoleIdleframe()
        end)
        --!!!压暗
        self:playMaskFadeAction(true)
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            --!!!压暗消失
            self:playMaskFadeAction(false)
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)

    return true
end
-- FreeSpinstart
function CodeGameScreenMrCashGoMachine:showFreeSpinView(effectData)
    -- 

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            --棋盘压暗
            self:playMaskFadeAction(true)
            --弹板
            local startPos = self:findChild("FreeSpinMore"):getParent():convertToWorldSpace(cc.p(self:findChild("FreeSpinMore"):getPosition()))
            local endPos   = self:findChild("FreeSpinBar"):getParent():convertToWorldSpace(cc.p(self:findChild("FreeSpinBar"):getPosition()))
            self.m_freeMoreView:playFlyAnim(startPos, endPos, function()
                --消失压暗
                self:playMaskFadeAction(false)
                self.m_freeSpinBar:changeFreeSpinByCount()
                -- 加次数动效
                self.m_freeSpinBar:playFreeMoreAnim(function()
                    effectData.p_isPlay = true
                    self:playGameEffect()   
                end)
            end)                    
        else
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_roleSapai.mp3")
            -- 人物丢一张卡牌
            self:playRoleAnim_Up("sapai2", false)
            self:playRoleAnim("sapai", false, function()
                self:playRoleIdleframe()
            end)
            -- 第50帧出弹板
            self:levelPerformWithDelay(50/30, function()
                local bonusType = self.m_bonusGame:getCurBonusType()
                -- free弹板出现
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_free_guochang.mp3")
                    -- 弹板关闭 -> free过场
                    self:playFreeGuoChang(
                        -- 过场中间切换展示
                        function()
                            self.m_freeSpinBar:changeFreeSpinByCount()
                            self.m_freeSpinBar:setVisible(true)
                            self:changeLevelBgAndReel("free")
                        end,
                        -- 结束过场
                        function()
                            self:resetMusicBg(nil, "MrCashGoSounds/music_MrCashGo_free.mp3")
                            -- 过场结束 -> 出现等级框
                            self:playFreeStartUpGardLevelBox(function()
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()    
                            end)
                        end
                    )
                end)
                --粒子
                local particle = view:findChild("Particle_1")
                particle:setVisible(true)
                particle:stopSystem()
                particle:resetSystem()

                -- 根据触发free的条件不同区分展示
                view:findChild("WenZi_0"):setVisible(0 == bonusType)
                view:findChild("WenZi_2"):setVisible(2 == bonusType)
                view:findChild("WenZi_3"):setVisible(3 == bonusType)
                view:findChild("WenZi_4"):setVisible(4 == bonusType)
                local soundName = string.format("MrCashGoSounds/sound_MrCashGo_freeStart_%d.mp3", bonusType)
                gLobalSoundManager:playSound(soundName)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenMrCashGoMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_freeOver_roleHuigunzi.mp3")
    -- 人物挥动拐杖
    self:playRoleAnim("huigunzi1", false, function()
        self:playRoleIdleframe()

        -- 按等级依次开箱
        self:playEffect_OpenLevelBox(function()
            gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_freeOver_view.mp3")
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            local lastWinCoin = self:getLastWinCoin()
            self:clearCurMusicBg()

            local view = self:showFreeSpinOver( 
                lastWinCoin, 
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    self.m_bottomUiEffect:setVisible(false)
                    self.m_freeSpinBar:setVisible(false)
                    self.m_freeSpinBar:freeOverResetShow()
                    self:changeLevelBgAndReel("base")
                    self.m_levelBoxManager:clearLevelBoxList()
                    self.m_bIsBonusReconnect = false
                    self:clearBonusGameData()
                    self.m_bonusGame:clearBonusData()
                    self.m_bonusGame:hideFeatureLightAnim()
                    
                    self:triggerFreeSpinOverCallFun()
                end
            )

            local bonusType = self.m_bonusGame:getCurBonusType()
            view:findChild("WenZi_0"):setVisible(0 == bonusType)
            view:findChild("WenZi_2"):setVisible(2 == bonusType)
            view:findChild("WenZi_3"):setVisible(3 == bonusType)
            view:findChild("WenZi_4"):setVisible(4 == bonusType)

            local lb_coins = view:findChild("m_lb_coins")
            view:updateLabelSize({label=lb_coins,sx=1,sy=1}, 670)
        end)
    end)
    -- 角色棍子 上层
    self:playRoleAnim_Up("huigunzi1b", false)
    -- 第20帧播放棋盘效果
    self:levelPerformWithDelay(21/30, function()
        -- 棋盘震动
        self:findChild("yugao_gold"):setVisible(false)
        self:findChild("yugao_green"):setVisible(false)
        self:runCsbAction("zhen",false, function()
            self:runCsbAction("idle", true)
        end)
    end)
end
-- 重写一下freeStart界面
function CodeGameScreenMrCashGoMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local isAuto = isAuto
    if nil == isAuto then
        local curMode = self:getCurrSpinMode()
        isAuto = curMode == AUTO_SPIN_MODE or curMode == FREE_SPIN_MODE
    end
    if self.m_bottomUI.setExtraNodeVisible then
        self.m_bottomUI:setExtraNodeVisible(false)
    end
    local callback = function()
        if func then
            if self.m_bottomUI.setExtraNodeVisible then
                self.m_bottomUI:setExtraNodeVisible(true)
            end
            func()
        end
    end
    self.m_freeStartView:initViewData(ownerlist, callback, isAuto)

    return self.m_freeStartView
end

-- free触发时 升级宝箱
function CodeGameScreenMrCashGoMachine:playFreeStartUpGardLevelBox(_fun)
    -- base       -> free
    local bonusGameData = self:getBonusGameData()
    if nil == next(bonusGameData) then
        self:playEffect_UpGradeLevelBoxRun(function()
            _fun()             
        end)
    -- bonus大图标   -> free
    elseif  bonusGameData.bonusType == self.BONUSTYPE_2 then
        -- 大图标先滚
        self:playEffect_bonusMoneyBag(function()
            -- 升级主轮盘 
            self:playEffect_UpGradeLevelBoxRun(function()
                _fun()
            end)
           
        end)
    -- bonus满级房子 -> free
    elseif  bonusGameData.bonusType == self.BONUSTYPE_3 then
        self:playEffect_bonusBigVilla(function()
            -- 升级主轮盘 
            self:playEffect_UpGradeLevelBoxRun(function()
                _fun()
            end)
        end)
    -- bonus移动    -> free
    elseif  bonusGameData.bonusType == self.BONUSTYPE_4 then
        self:playEffect_bonusCashRain(function()
            _fun()
        end)
    else
        local sMsg = "[CodeGameScreenMrCashGoMachine:playFreeStartUpGardLevelBox] error"
        print(sMsg)
        release_print(sMsg)
        _fun()
    end
end
function CodeGameScreenMrCashGoMachine:playFreeGuoChang(_switchFun,_overFun)
    self.m_freeGuoChang_1:setVisible(true)
    self.m_freeGuoChang_2:setVisible(true)

    --人物挥手
    -- self:playRoleAnim("saqian", false, function()
    --     self:playRoleIdleframe()
    -- end)

    -- 第56帧播放钞票雨
    -- self:levelPerformWithDelay(57/30, function()
        -- 过场金色钞票雨
        util_spinePlay(self.m_freeGuoChang_1, "actionframe", false)
        util_spinePlay(self.m_freeGuoChang_2, "actionframe", false)
        util_spineEndCallFunc(self.m_freeGuoChang_1, "actionframe", function()
            self.m_freeGuoChang_1:setVisible(false)
            self.m_freeGuoChang_2:setVisible(false)

            if _overFun then
                _overFun()
            end

        end)
        -- 第30帧切换展示
        if _switchFun then
            self:levelPerformWithDelay(30/30,function()
                _switchFun()
            end)
        end
    -- end)
end
----------- Bonus相关
function CodeGameScreenMrCashGoMachine:playBonusGameActionAnim(_fun)
    local bonusGameData = self:getBonusGameData()
    
    --压暗
    self:playMaskFadeAction(true)
    --触发动画
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonus_actionframe.mp3")
    for _index,_iPos in ipairs(bonusGameData.bonusPos) do
        local fixPos = self:getRowAndColByPos(_iPos)
        local bonusNode = self:getFixSymbol(fixPos.iY, fixPos.iX) 
        -- 提层
        if bonusNode:getParent() ~= self.m_clipParent then
            bonusNode = util_setSymbolToClipReel(
                self,bonusNode.p_cloumnIndex, 
                bonusNode.p_rowIndex, 
                bonusNode.p_sumbolType,
                0
            )
        end
        bonusNode:runAnim("actionframe", false, function()
            -- 放回原层级 参考这个 BaseMachine:checkChangeBaseParent()
            local pos = util_convertToNodeSpace(bonusNode, self.m_slotParents[bonusNode.p_cloumnIndex].slotParent)
            bonusNode.p_showOrder = self:getBounsScatterDataZorder(bonusNode.p_symbolType)
            self:changeBaseParent(bonusNode)
            bonusNode:resetReelStatus()
            bonusNode:setPosition(pos)
        end)
    end
    
    self:levelPerformWithDelay(60/30, function()
        --压暗消失
        self:playMaskFadeAction(false)
        _fun()
    end)
end
function CodeGameScreenMrCashGoMachine:showBonusGameView(effectData)
    self.m_bonusEffect = effectData

    self:clearWinLineEffect()
    -- 清理底栏
    -- if not self.m_bProduceSlots_InFreeSpin then
    --     self:setLastWinCoin(0)
    --     self.m_bottomUI:resetWinLabel()
    --     self.m_bottomUI:checkClearWinLabel()
    -- end

    local bonusGameData = self:getBonusGameData()
    self.m_bonusGame:setBonusData(bonusGameData)

    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    -- 播放触发动画
    self:playBonusGameActionAnim(function()
        -- 开始bonus游戏
        self:plauBonusGameGuoChang(function()
            self.m_bonusGame:startBonusGame()
        end)
    end)
    
   
end
-- 打电话 -> 飞走 -> 投骰子 -> 降落
function CodeGameScreenMrCashGoMachine:plauBonusGameGuoChang(_fun)
    --棋盘压暗
    self:playMaskFadeAction(true)
    --lookUp弹板
    self:showLookUpView()

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_bonusGame_guochang.mp3")
    -- 打电话
    self:playRoleAnim("idle2", false, function()
        -- 飞走 1
        self:playRoleAnim("idle3", false, function()
            self.m_roleSpine:setVisible(false)
            if _fun then
                _fun()
            end
        end)
    end)
end
-- 返回起点 -> 上飞机 -> 回到主界面 ->
function CodeGameScreenMrCashGoMachine:playBonusGameOver(_fun)
    self.m_roleSpine:setVisible(true)
    --关闭lookUp界面
    self:hideLookUpView()

    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_roleBackReel.mp3")
    self:playRoleAnim("idle6", false, function()
        self:playRoleIdleframe()

        if _fun then
            _fun()
        end
    end)
end

function CodeGameScreenMrCashGoMachine:showLookUpView()
    if self.m_lookUpView:isVisible() then
        return
    end
    self.m_lookUpView:setVisible(true)
    self.m_lookUpView:runCsbAction("start", false, function()
        self.m_lookUpView:runCsbAction("idle", false)
    end)
end
function CodeGameScreenMrCashGoMachine:hideLookUpView()
    self.m_lookUpView:runCsbAction("over", false, function()
        self.m_lookUpView:setVisible(false)
    end)
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMrCashGoMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMrCashGoMachine:addSelfEffect()
    -- 字段存在 且 不在free触发时那一次spin
    if self:isTriggerUpGradeLevelBoxRun() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_UpGradeLevelBox_Run
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_UpGradeLevelBox_Run 
    end
    -- 弹射和连线同时触发时 改到连线后面
    if self:isTriggerUpGradeLevelBoxTransfer() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_UpGradeLevelBox_Transfer
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_UpGradeLevelBox_Transfer 
    end

    if self:isTriggerOpenLevelBox() then
        -- free结束开盒子时 将连线赢钱 和 开盒子赢钱分开上涨
        local winLines  = self.m_runSpinResultData.p_winLines or {}
        -- 本次连线赢钱
        local lineCoins = 0
        for i,v in ipairs(winLines)do
            lineCoins = lineCoins + v.p_amount
        end
        -- 底栏当前展示的赢钱
        local bottomWinCoin = self:getMrCashGoCurBottomWinCoins()
        self:setLastWinCoin(bottomWinCoin + lineCoins)
    end
    
    -- bonus
    if self:isTriggerBonusGame() then
        self:saveBonusGameData()
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMrCashGoMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_UpGradeLevelBox_Run then
        self:playEffect_UpGradeLevelBoxRun(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_UpGradeLevelBox_Transfer then
        self:playEffect_UpGradeLevelBoxTransfer(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    -- Bonus的三个事件 修改流程后不需要 addSelfEffect了，但是先留一下代码
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_MoneyBag then
        self:playEffect_bonusMoneyBag(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_BigVilla then
        self:playEffect_bonusBigVilla(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_CashRain then
        self:playEffect_bonusCashRain(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

---


function CodeGameScreenMrCashGoMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenMrCashGoMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenMrCashGoMachine:slotReelDown( )
    CodeGameScreenMrCashGoMachine.super.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenMrCashGoMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


----------------------------- 一些工具 -----------------------------------
-- 获取信号数量
function CodeGameScreenMrCashGoMachine:getSymbolCountByType(symbolType, limitCol)
    local count = 0
    if (not self.m_runSpinResultData or not self.m_runSpinResultData.p_reels) then
        return count
    end
    for _iRow, _row_data in ipairs(self.m_runSpinResultData.p_reels) do
        for _iCol, _symbolType in ipairs(_row_data) do
            if ((not limitCol or _iCol<=limitCol) and symbolType == _symbolType) then
                count = count + 1
            end
        end
    end

    return count
end

--[[
    临时信号小块，不使用 池子的那一套，有可能泄漏
    create
    change
    runAnim
]]
function CodeGameScreenMrCashGoMachine:createMrCashGoTempSymbol(_symbolType)
    local symbol = util_createView("CodeMrCashGoSrc.MrCashGoTempSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenMrCashGoMachine:resetMrCashGoReelShow(_reels)
    for _line,_lineData in ipairs(_reels) do
        local iRow = self.m_iReelRowNum - _line + 1
        for iCol,_symbolType in ipairs(_lineData) do
            local slotsNode = self:getFixSymbol(iCol, iRow)
            local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
            slotsNode:changeCCBByName(ccbName, _symbolType)
            slotsNode:runAnim("idleframe", false)
        end
    end
end
--BottomUI接口
function CodeGameScreenMrCashGoMachine:updateBottomUICoins( _beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound )
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end
function CodeGameScreenMrCashGoMachine:getMrCashGoCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

function CodeGameScreenMrCashGoMachine:getLevelBoxSymbolType(_level)
    local symbolType = self.SYMBOL_LevelBox_1 + (_level - 1)
    return symbolType
end
function CodeGameScreenMrCashGoMachine:getLevelBoxLevel(_symbolType)
    local level = _symbolType - self.SYMBOL_LevelBox_1 + 1
    return level
end

function CodeGameScreenMrCashGoMachine:levelPerformWithDelay(_time, _fun)
    if _time <= 0 then
        _fun()
        return
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        _fun()

        waitNode:removeFromParent()
    end, _time)

    return waitNode
end

function CodeGameScreenMrCashGoMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num_0"] = num
    ownerlist["m_lb_num_2"] = num
    ownerlist["m_lb_num_3"] = num
    ownerlist["m_lb_num_4"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
end
function CodeGameScreenMrCashGoMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

---
--设置bonus scatter 层级
function CodeGameScreenMrCashGoMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_Scatter_2x2 or symbolType == self.SYMBOL_Scatter_3x3 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
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

--[[
    预告中奖
]]
function CodeGameScreenMrCashGoMachine:operaSpinResultData(param)
    CodeGameScreenMrCashGoMachine.super.operaSpinResultData(self,param)

    -- 预告中奖标记
	self.m_isPlayWinningNotice = self:playYugaoAnim()
end


function CodeGameScreenMrCashGoMachine:playYugaoAnim()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        return false
    end

    local features      = self.m_runSpinResultData.p_features or {}
    local probability   = (math.random(1,3) <= 1)

    if #features > 1 and probability then
        local isBonus = false
        for i,v in ipairs(features) do
            if v == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                isBonus = true
                break
            end
        end

        gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_yugao.mp3")
        -- 角色挥手
        self:playRoleAnim("huigunzi1", false, function()
            self:playRoleIdleframe()
        end)
        -- 角色棍子 上层
        self:playRoleAnim_Up("huigunzi1b", false)
        -- 第20帧播放棋盘效果
        self:levelPerformWithDelay(21/30, function()
            -- 棋盘震动
            self:findChild("yugao_gold"):setVisible(not isBonus)
            self:findChild("yugao_green"):setVisible(isBonus)
            self:runCsbAction("yugao",false, function()
                self:runCsbAction("idle", true)
            end)
            -- bonus钞票雨
            
            local yugaoSpine = isBonus and self.m_yugaoSpineGold or self.m_yugaoSpine
            yugaoSpine:setVisible(true)
            util_spinePlay(yugaoSpine, "actionframe", false)
            util_spineEndCallFunc(yugaoSpine, "actionframe", function()
                yugaoSpine:setVisible(false)
            end)
            
        end)

        return true
    end

    return false
end

-- 关卡重写方法
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMrCashGoMachine:MachineRule_ResetReelRunData()
    if self.m_isPlayWinningNotice then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local preRunLen = reelRunData.initInfo.reelRunLen
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            
            reelRunData:setReelRunLen(preRunLen)
            reelRunData:setReelLongRun(false)
            reelRunData:setNextReelLongRun(false)

            -- 提取某一列所有内容， 一些老关在创建最终信号小块时会以此列表作为最终信号的判断条件
            local columnSlotsList = self.m_reelSlotsList[iCol]  
            -- 新的关卡父类可能没有这个变量
            if columnSlotsList then

                local curRunLen = reelRunData:getReelRunLen()
                local iRow = columnData.p_showGridCount
                -- 将 老的最终列表 依次放入 新的最终列表 对应索引处
                local maxIndex = runLen + iRow
                for checkRunIndex = maxIndex,1,-1 do
                    local checkData = columnSlotsList[checkRunIndex]
                    if checkData == nil then
                        break
                    end
                    columnSlotsList[checkRunIndex] = nil
                    columnSlotsList[curRunLen + iRow - (maxIndex - checkRunIndex)] = checkData
                end

            end
            
        end
    end
end

function CodeGameScreenMrCashGoMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    -- 将下一步的逻辑包裹一下
    local nextFun = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    -- 判断本次spin的预告中奖标记
    if self.m_isPlayWinningNotice then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 时间线长度
        end, (20 + 115)/30)
    else
        nextFun()
    end
end
-- 连线时没有参与连线的图标被压暗
function CodeGameScreenMrCashGoMachine:showEffect_LineFrame(effectData)
    --!!! 压暗
    self:playMaskFadeAction(true)

    return CodeGameScreenMrCashGoMachine.super.showEffect_LineFrame(self, effectData)
end
function CodeGameScreenMrCashGoMachine:clearWinLineEffect()
    if self.m_lineMask:isVisible() then
        --!!! 压暗消失
        self:playMaskFadeAction(false)
    end
    

    CodeGameScreenMrCashGoMachine.super.clearWinLineEffect(self)
end

function CodeGameScreenMrCashGoMachine:checkNotifyUpdateWinCoin()
    --!!!
    if self:isTriggerOpenLevelBox() then
        -- free结束开盒子时 将连线赢钱 和 开盒子赢钱分开上涨
        local winLines  = self.m_runSpinResultData.p_winLines or {}
        -- 本次连线赢钱
        local lineCoins = 0
        for i,v in ipairs(winLines)do
            lineCoins = lineCoins + v.p_amount
        end
        -- 底栏当前展示的赢钱
        self.m_iOnceSpinLastWin = lineCoins
    end

    CodeGameScreenMrCashGoMachine.super.checkNotifyUpdateWinCoin(self)
end

function CodeGameScreenMrCashGoMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    --!!! 这里要用 fsWinCoins 计算大赢
    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_fsWinCoins, GameEffect.EFFECT_FREE_SPIN_OVER)
    -- self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
     --!!! 不要关闭free音效
    -- self:clearCurMusicBg()
    self:showFreeSpinOverView()
end

function CodeGameScreenMrCashGoMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            if  _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    --前四列Scatter总数小于3个, 第四列Scatter不播落地动画
                    if _slotNode.p_cloumnIndex == self.m_iReelColumnNum-1 then
                        local scatterCount = self:getSymbolCountByType(_slotNode.p_symbolType, self.m_iReelColumnNum-1)
                        if scatterCount < self.m_iReelRowNum then
                            return false
                        end
                    --前四列Scatter总数小于等于3个, 第五列Scatter不播落地动画
                    elseif _slotNode.p_cloumnIndex == self.m_iReelColumnNum then   
                        local scatterCount = self:getSymbolCountByType(_slotNode.p_symbolType, self.m_iReelColumnNum-1)                 
                        if scatterCount <= self.m_iReelRowNum then
                            return false
                        end
                    end
                    return true
                end
            else
                return true
            end

        end
    end

    return false
end

-- 满线关卡不播五连
-- 显示五个元素在同一条线效果
function CodeGameScreenMrCashGoMachine:showEffect_FiveOfKind(effectData)
    -- local fiveAnim = FiveOfKindAnima:create()  -- 不在播放five of kind 动画 2017-12-08 11:54:46
    -- local fiveAnim =
    --     util_createView(
    --     "views.fiveofkind.FiveOfKindLayer",
    --     function()
    --     end
    -- )
    -- if gLobalSendDataManager.getLogPopub then
    --     gLobalSendDataManager:getLogPopub():addNodeDot(fiveAnim, "Push", DotUrlType.UrlName, true, DotEntrySite.SpinPush, DotEntryType.Game)
    -- end
    -- gLobalViewManager:showUI(fiveAnim, nil, false)
    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

function CodeGameScreenMrCashGoMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    --!!! 注释掉
    -- self:resetMusicBg()
end

function CodeGameScreenMrCashGoMachine:scaleMainLayer()
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
            local cfgHeight = self:getReelHeight() + uiH + uiBH
            mainScale       = (cfgHeight / DESIGN_SIZE.height) * (display.height / DESIGN_SIZE.height)
            
            if display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.05
                self.MAIN_ADD_POSY = - mainPosY
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.05
                self.MAIN_ADD_POSY = (- mainPosY) + 10
            elseif display.height / display.width >= 1024/768 then
                self.MAIN_ADD_POSY = (- mainPosY + 10) * ((1228/768) / (display.height/display.width))
            end

            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(mainPosY + self.MAIN_ADD_POSY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

-- 触发bonus时 底栏带入玩法时不计算大赢
function CodeGameScreenMrCashGoMachine:checkIsAddLastWinSomeEffect()
    local notAdd = CodeGameScreenMrCashGoMachine.super.checkIsAddLastWinSomeEffect(self)

    if not notAdd then
        local isTriggerBonus = self:isTriggerBonusGame()
        if isTriggerBonus then
            notAdd = true
        end
    end

    return notAdd
end

return CodeGameScreenMrCashGoMachine