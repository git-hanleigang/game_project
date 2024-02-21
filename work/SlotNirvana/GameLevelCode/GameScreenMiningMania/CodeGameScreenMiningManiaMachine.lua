---
-- island li
-- 2019年1月26日
-- CodeGameScreenMiningManiaMachine.lua
-- 
-- 玩法：
--[[
    收集玩法：
        1.出现scatter会收集；收集的钱作为社交玩法的基底
        2.bonus收集：见下
    base:
        1.Bonus1（大信号）图标仅出现在第5列；Bonus2（带钱）、Bonus3（带jackpot）、Bonus4（带free）仅出现在1、2、3、4列；wild仅出现在2.3.4.5列；
        2.前四列出现bonus2、bonus3或者bonus4，并且第五列出现bonus1（不用占满格，可以拖拽触发玩法）；触发玩法->收集钱；收集jackpot；触发free
    free：
        1.free模式下；bonus1（长条）会固定存在第五列；增加bonus玩法的概率（玩法特色之一）
        2.free下模式；社交触发方式必须是别人触发带进去；因为第五列固定bonus1
    社交：
        1.三个scatter触发社交玩法；社交玩法和收集能同时触发
        2.社交1：共六轮，每轮收集bonus图标，刷新倍数；最终根据倍数确定排名
        3.社交2：三条轨道；第一名占一条轨道；第2、3名和第4、5名各站一条轨道；根据社交1的排名获得小车收集的时间；社交2存在反超的情况（也是玩法特色之一）；最终钱数=基底*收集倍数
        4.社交不做断线重连
]]


-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local PublicConfig = require "MiningManiaPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenMiningManiaMachine = class("CodeGameScreenMiningManiaMachine", BaseSlotoManiaMachine)

CodeGameScreenMiningManiaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMiningManiaMachine.m_bonusRootSccale1 = 1.0
CodeGameScreenMiningManiaMachine.m_bonusRootSccale2 = 1.0
CodeGameScreenMiningManiaMachine.m_baseRootPosY = 0

CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_1 = 94  --长条
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_2 = 95
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_3 = 96
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_4 = 97
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_FREE_NULL = 100
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_NULL = 110
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_5 = 111
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_6 = 112
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_7 = 113
CodeGameScreenMiningManiaMachine.SYMBOL_SCORE_BONUS_8 = 114

CodeGameScreenMiningManiaMachine.EFFECT_BONUS_MAIL_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1  --社交触发；断线回来领取奖励
CodeGameScreenMiningManiaMachine.EFFECT_BONUS_OVER_ADD_COINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2  --bonus玩法结束后加钱
CodeGameScreenMiningManiaMachine.EFFECT_BONUS_FREE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3  --bonus4玩法；触发free；加free次数
CodeGameScreenMiningManiaMachine.EFFECT_BONUS_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4  --bonus3玩法；触发jackpot
CodeGameScreenMiningManiaMachine.EFFECT_BONUS_COINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5  --bonus2玩法；加钱
CodeGameScreenMiningManiaMachine.EFFECT_BONUS_TRIGGER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6  --bonus触发
CodeGameScreenMiningManiaMachine.EFFECT_BIG_BONUS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 7  --大信号上下拖拽
CodeGameScreenMiningManiaMachine.EFFECT_SCATTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 8  --scatter玩法；收集



-- 构造函数
function CodeGameScreenMiningManiaMachine:ctor()
    CodeGameScreenMiningManiaMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isShowOutGame = false
    self.m_isShowSystemView = false

    self.m_publicConfig = PublicConfig

    self.m_triggerBigWinEffect = false

    -- 大信号信息
    self.m_bigBonusArry = {}
    -- 大信号状态
    self.ENUM_BIG_SYMBOL_STATE = 
    {
        BONUS_1 = 1,
        BONUS_2 = 2,
        BONUS_3 = 3,
        BONUS_4 = 4,
    }
    self.m_bigSymbolState = self.ENUM_BIG_SYMBOL_STATE.BONUS_1

    self.m_isBonusPlaying = false

    -- 保存当前触发了几个玩法
    self.m_curTriggerPlayTbl = {}

    self.m_panelOpacity = 153

    --大赢光效
    self.m_isAddBigWinLightEffect = true

    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
 
    --init
    self:initGame()
end

function CodeGameScreenMiningManiaMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MiningManiaConfig.csv", "LevelMiningManiaConfig.lua")
    self.m_configData.m_machine = self
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMiningManiaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MiningMania"  
end

function CodeGameScreenMiningManiaMachine:getBottomUINode()
    return "CodeMiningManiaSrc.MiningManiaBottomNode"
end

---
-- 等待滚动全部结束后 执行reel down 的具体后续逻辑
local curWinType = 0

--[[
    初始化房间列表
]]
function CodeGameScreenMiningManiaMachine:initRoomList()
    --房间列表
    self.m_roomList = util_createView("CodeMiningManiaSrc.MiningManiaRoomListView", {machine = self})
    self:findChild("Node_Seat"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData
end


function CodeGameScreenMiningManiaMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- reel条
    self.m_tblReelBg = {}
    self.m_tblReelBg[1] = self:findChild("base")
    self.m_tblReelBg[2] = self:findChild("free")
    
    --初始化房间列表
    self:initRoomList()
    
    self:initFreeSpinBar() -- FreeSpinbar
    
    self.m_baseFreeSpinBar = util_createView("CodeMiningManiaSrc.MiningManiaFreespinBarView", self)
    self:findChild("FreeSpinBar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)

    --jackpot栏
    self.m_jackPotBar = util_createView("CodeMiningManiaSrc.MiningManiaJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    --收集区域
    self.m_baseCollectBar = util_createView("CodeMiningManiaSrc.MiningManiaBaseCollectView", self, true)
    self:findChild("Shoujiqu"):addChild(self.m_baseCollectBar)

    --特效层
    self.m_effectNode = self:findChild("Node_topEffect")

    --free特效层
    self.m_effectFixdNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectFixdNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)

    -- 收集底栏上字体
    self.textWorldPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self)
    self.textWorldPos.y = self.textWorldPos.y+60
    self.m_collectEffectNum = util_createAnimation("MiningMania_Totalwin.csb")
    self.m_collectEffectNum:setPosition(self.textWorldPos)
    self:addChild(self.m_collectEffectNum, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_collectEffectNum:setVisible(false)
    self.m_coinsText = self.m_collectEffectNum:findChild("m_lb_coins")
    self.m_coinsText:setString(0)

    -- 第五列的箭头
    local arrowPos = self:getWorldToNodePos(self:findChild("Node_yugao"), 14)
    local columnData = self.m_reelColDatas[5]
    local halfH = columnData.p_showGridH * 0.5
    self.m_arrowAni = util_createAnimation("MiningManiaBonus_jiantou.csb")
    self.m_arrowAni:setPosition(cc.p(arrowPos.x, arrowPos.y + halfH))
    self:findChild("Node_yugao"):addChild(self.m_arrowAni)
    self.m_arrowAni:setVisible(false)

    -- 过场动画
    self.m_cutSceneAni = util_createAnimation("MiningMania_guochang.csb")
    self:findChild("Node_yugao"):addChild(self.m_cutSceneAni)
    self.m_cutSceneAni:setVisible(false)

    self.m_cutSceneSpine = util_spineCreate("MiningMania_guochang",true,true)
    self:findChild("Node_yugao"):addChild(self.m_cutSceneSpine)
    self.m_cutSceneSpine:setVisible(false)

    -- 预告中奖
    self.m_yuGaoAni = util_createAnimation("MiningMania_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yuGaoAni)
    self.m_yuGaoAni:setVisible(false)

    self.m_yuGaoSpine = util_spineCreate("MiningMania_yugao",true,true)
    self:findChild("Node_yugao"):addChild(self.m_yuGaoSpine)
    self.m_yuGaoSpine:setVisible(false)

    --触发bonus玩法遮罩
    self.m_maskAni = util_createAnimation("MiningMania_dark.csb")
    self.m_onceClipNode:addChild(self.m_maskAni, 10000)
    self.m_maskAni:setVisible(false)

    --遮罩
    self.m_panelUpList = self:createSpinMask(self)

    --大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("MiningMania_Totalwin",true,true)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    --社交1
    self.m_machine_bonus = self:createrBonusReel()
    self:findChild("Node_shejiao1"):addChild(self.m_machine_bonus)
    self.m_machine_bonus:scaleMainLayer(self.m_bonusRootSccale1)
    self.m_machine_bonus:setPosition(cc.p(-display.width / 2, -display.height / 2))
    -- self:addChild(self.m_machine_bonus, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

    --社交2
    self.m_machine_carView = self:createrBonusCar()
    self.m_machine_carView:scaleMainLayer(self.m_bonusRootSccale2)
    self:addChild(self.m_machine_carView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)

    --显示基础轮盘
    self:setBaseReelShow(true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:runCsbAction("idle", true)
    self:changeBgAndReelBg(1)
end


function CodeGameScreenMiningManiaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 3, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenMiningManiaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMiningManiaMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

--初始化界面数据
function CodeGameScreenMiningManiaMachine:initGameUI()
    -- 初始化收集分数
    self:refreshBaseCollectScore(true)

    -- 收集提示
    self.m_baseCollectBar:showTips()
end

function CodeGameScreenMiningManiaMachine:addObservers()
    CodeGameScreenMiningManiaMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
            self.m_roomList:showSelfBigWinAni("EPIC_WIN")
        elseif self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) then
            self.m_roomList:showSelfBigWinAni("MAGE_WIN")
        elseif self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            self.m_roomList:showSelfBigWinAni("BIG_WIN")
        end

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin and not self.m_triggerBigWinEffect then
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
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
        else
            bgmType = "base"
        end

        local soundName = "MiningManiaSounds/music_MiningMania_last_win_".. bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenMiningManiaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMiningManiaMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    --需手动调用房间列表的退出方法,否则未加载完成退出游戏不会主动调用
    self.m_roomList:onExit()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenMiningManiaMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1370/768 then
            mainScale = mainScale * 1.03
            self.m_bonusRootSccale1 = mainScale
            self.m_bonusRootSccale2 = mainScale
            mainPosY = mainPosY + 7
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 0.98
            self.m_bonusRootSccale1 = mainScale*0.99
            self.m_bonusRootSccale2 = mainScale*0.96
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.98
            self.m_bonusRootSccale1 = mainScale * 0.99
            self.m_bonusRootSccale2 = mainScale * 0.96
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.98
            mainPosY = mainPosY + 10
            self.m_bonusRootSccale1 = mainScale * 0.99
            self.m_bonusRootSccale2 = mainScale * 0.96
        elseif display.width / display.height >= 1.2 then--1812x2176
            mainScale = mainScale * 0.94
            self.m_bonusRootSccale1 = mainScale
            self.m_bonusRootSccale2 = mainScale
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

-- 创建社交轮盘
function CodeGameScreenMiningManiaMachine:createrBonusReel()
    local className = "CodeMiningManiaBonusReel.MiningManiaBonusReelMachine"

    local params = {
        parent = self,
    }
    local bonusReel = util_createView(className,params)

    return bonusReel
end

-- 创建社交2玩法
function CodeGameScreenMiningManiaMachine:createrBonusCar()
    local className = "CodeMiningManiaBonusCar.MiningManiaBonusCarView"

    local params = {
        parent = self,
    }
    local bonusCarView = util_createView(className,params)

    return bonusCarView
end

--[[
    退出到大厅
]]
function CodeGameScreenMiningManiaMachine:showOutGame( )

    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeMiningManiaSrc.MiningManiaGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

--[[
    暂停轮盘
]]
function CodeGameScreenMiningManiaMachine:pauseMachine()
    BaseMachine.pauseMachine(self)
    self.m_isShowSystemView = true
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    恢复轮盘
]]
function CodeGameScreenMiningManiaMachine:resumeMachine()
    BaseMachine.resumeMachine(self)
    self.m_isShowSystemView = false
    if self.m_isTriggerBonus then
        return
    end
    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

function CodeGameScreenMiningManiaMachine:addMailCollectReward()
    if self.m_isTriggerBonus then
        return
    end
    
    local wins = self.m_roomData:getWinSpots()
    if wins and #wins > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_MAIL_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_MAIL_COLLECT -- 动画类型

        self.m_isShowMail = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end

--[[
    获取邮件奖励
]]
function CodeGameScreenMiningManiaMachine:showMailWinView(_callFunc)
    local callFunc = _callFunc
    local winView = util_createView("CodeMiningManiaSrc.MiningManiaMailWin",{machine = self, index = -1})
    local _winCoins = self.m_roomData:getMailWinCoins()
    winView:initViewData(_winCoins)
    -- winView:setPosition(display.width / 2,display.height / 2)
    --检测大赢
    self:checkFeatureOverTriggerBigWin(_winCoins, GameEffect.EFFECT_BONUS)

    winView:setFunc(
        function()
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                    _winCoins, true, true
                })
            end
            
            --为了播放大赢动画
            -- self:playGameEffect()
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            --重新刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
            self.m_isShowMail = false

            if type(callFunc) == "function" then
                callFunc()
            end
        end
    )
    gLobalViewManager:showUI(winView)

    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMiningManiaMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MiningMania_10"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_1 then
        return "Socre_MiningMania_Bonus1"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return "Socre_MiningMania_Bonus2"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_3 then
        return "Socre_MiningMania_Bonus3"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_4 then
        return "Socre_MiningMania_Bonus4"
    elseif symbolType == self.SYMBOL_SCORE_FREE_NULL then
        return "Socre_MiningMania_Free_Null"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_NULL then
        return "Socre_MiningMania_Free_Null"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_5 then
        return "Socre_MiningMania_Bonus5"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_6 then
        return "Socre_MiningMania_Bonus6"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_7 then
        return "Socre_MiningMania_Bonus7"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_8 then
        return "Socre_MiningMania_Bonus8"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMiningManiaMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMiningManiaMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMiningManiaMachine:MachineRule_initGame(  )
    self:addMailCollectReward()
    --Free模式
    -- if self.m_bProduceSlots_InFreeSpin then
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgAndReelBg(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        self:addFreeFixBigNode()
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenMiningManiaMachine:initGameStatusData(gameData)
    CodeGameScreenMiningManiaMachine.super.initGameStatusData(self,gameData)
end
--
--单列滚动停止回调
--
function CodeGameScreenMiningManiaMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMiningManiaMachine.super.slotOneReelDown(self,reelCol) 
    ---本列是否开始长滚
    local isTriggerLongRun = false
    if reelCol == 1 then
        self.isHaveLongRun = false
    end
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) and self:frontColIsHaveScatter() then
        isTriggerLongRun = true
    end
    local delayTime = 15/30
    if isTriggerLongRun then
        self.isHaveLongRun = true
        self:playScatterSpine("idleframe2", reelCol)
    else
        if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
            --落地
            self:playScatterSpine("idleframe1", reelCol, true)
        end
    end

    self:playMaskFadeAction(false, 0.2, reelCol, function()
        self:changeMaskVisible(false, reelCol)
    end)
end

-- 判断前面列是否有两个scatter
function CodeGameScreenMiningManiaMachine:frontColIsHaveScatter()
    local positionScore = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
    local scatterCount = 0
    if next(positionScore) then
        for k, v in pairs(positionScore) do
            local pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if fixPos.iY == 1 then
                    scatterCount = scatterCount + 1
                elseif fixPos.iY == 3 then
                    scatterCount = scatterCount + 1
                end
            end
        end
        if scatterCount == 2 then
            return true
        end
    end
    return false
end

function CodeGameScreenMiningManiaMachine:playScatterSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe2" and targSp.m_currAnimName ~= "idleframe2" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe1" then
                            -- local symbol_node = targSp:checkLoadCCbNode()
                            -- local curSpine = symbol_node:getCsbAct()
                            -- if curSpine then
                            --     util_spineMix(curSpine, "idleframe2", "idleframe1", 0.1)
                            -- end
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

---
-- --根据关卡玩法重新设置滚动信息
-- function CodeGameScreenMiningManiaMachine:MachineRule_ResetReelRunData()
--     if self.b_gameTipFlag and #self.m_reelSlotsList > 0 then
--         for i = 1, #self.m_reelRunInfo do
--             local runInfo = self.m_reelRunInfo[i]
--             local bRunLong = runInfo:getReelLongRun()
--             local columnSlotsList = self.m_reelSlotsList[i]  -- 提取某一列所有内容
--             local columnData = self.m_reelColDatas[i]
--             local iRow = columnData.p_showGridCount
--             local curRunLen = runInfo:getReelRunLen()
--             local preRunLen = runInfo.initInfo.reelRunLen
--             if curRunLen > preRunLen then
--                 local addRun = curRunLen - preRunLen
--                 for checkRunIndex = curRunLen + iRow,1,-1 do
--                     local checkData = columnSlotsList[checkRunIndex]
--                     if checkData == nil then
--                         break
--                     end
--                     columnSlotsList[checkRunIndex] = nil
--                     columnSlotsList[checkRunIndex - addRun] = checkData
--                 end
--             end
--         end
--     end
--     CodeGameScreenMiningManiaMachine.super.MachineRule_ResetReelRunData(self)
-- end

-- free下没有快滚
function CodeGameScreenMiningManiaMachine:checkIsInLongRun(col, symbolType)
    local longRun = CodeGameScreenMiningManiaMachine.super.checkIsInLongRun(self, col, symbolType)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self.b_gameTipFlag then
        longRun = false
    end
    return longRun
end

--设置长滚信息
function CodeGameScreenMiningManiaMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

        if self.m_isHaveSpecialBonus and col == self.m_iReelColumnNum-1 and not self.b_gameTipFlag and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --下列长滚
            reelRunData:setNextReelLongRun(true)
            bRunLong = true
        end

    end --end  for col=1,iColumn do

end

-- 播放预告中奖统一接口
-- 子类重写接口
function CodeGameScreenMiningManiaMachine:showFeatureGameTip(_func)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        _func() 
    else
        --有玩家触发Bonus
        local result = self.m_roomData:getSpotResult()
        if result then
            local randomNum = math.random(1, 10)
            if randomNum <= 4 then
                self.b_gameTipFlag = true
            end
            -- self.b_gameTipFlag = true
        end
        self.m_isHaveSpecialBonus = self:getCurIsHaveSpecialBonus()
        self.m_isTriggerBonus = self:getCurIsHaveBonus()
        if self.b_gameTipFlag then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
            self.m_yuGaoAni:setVisible(true)
            self.m_yuGaoSpine:setVisible(true)
            self.m_baseCollectBar:setCollectTipState(false)
            util_spinePlay(self.m_yuGaoSpine,"actionframe_yugao",false)
            self.m_yuGaoAni:runCsbAction("actionframe_yugao", false)
            util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe_yugao", function()
                self.m_baseCollectBar:setCollectTipState(true)
                self.m_yuGaoAni:setVisible(false)
                self.m_yuGaoSpine:setVisible(false)
                _func()
            end)
        else
            _func() 
        end
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMiningManiaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMiningManiaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 显示free spin
function CodeGameScreenMiningManiaMachine:showEffect_FreeSpin(effectData)
    local waitTime = 0
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local curBigSymbolNode = self.m_bigBonusNode
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        curBigSymbolNode = self.m_freeBigSymbolNode
    else
        -- 播放震动
        self:levelDeviceVibrate(6, "free")
    end
    
    gLobalSoundManager:playSound(PublicConfig.Music_Trigger_Free)
    if not tolua.isnull(curBigSymbolNode) then
        waitTime = 35/30
        curBigSymbolNode:runAnim("actionframe2", false, function()
            curBigSymbolNode:runAnim("idleframe1", true)
        end)
    else
        local curBigSymbolNode = self:getFixSymbol(self.m_iReelColumnNum , 1 , SYMBOL_NODE_TAG)
        if not tolua.isnull(curBigSymbolNode) and curBigSymbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
            waitTime = 35/30
            curBigSymbolNode:runAnim("actionframe2", false, function()
                curBigSymbolNode:runAnim("idleframe1", true)
            end)
        end
    end
    -- self:playScatterTipMusicEffect()
    
    performWithDelay(self,function(  )
        self:showMask(false, 3)
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMiningManiaMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("MiningManiaSounds/music_MiningMania_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local cutSceneFunc = function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
            end, 5/60)
        end
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_More)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, true)
            local m_carSpine = util_spineCreate("Socre_MiningMania_Scatter",true,true)
            util_spinePlay(m_carSpine,"tanban_idle",true)
            view:findChild("che"):addChild(m_carSpine)
            util_setCascadeOpacityEnabledRescursion(view, true)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_StartStart)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:addFreeFixBigNode()
                self:showCutPlaySceneAni(function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, "freeStart")     
            end)
            local m_carSpine = util_spineCreate("Socre_MiningMania_Scatter",true,true)
            util_spinePlay(m_carSpine,"actionframe_tanban",false)
            util_spineEndCallFunc(m_carSpine, "actionframe_tanban", function()
                util_spinePlay(m_carSpine,"tanban_idle",true)
            end)
            view:findChild("che"):addChild(m_carSpine)
            view:setBtnClickFunc(cutSceneFunc)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

--free过场
function CodeGameScreenMiningManiaMachine:showCutPlaySceneAni(_callFunc, _playType)
    local callFunc = _callFunc
    local playType = _playType
    self.m_cutSceneAni:setVisible(true)
    self.m_cutSceneSpine:setVisible(true)
    self.m_cutSceneAni:runCsbAction("actionframe_guochang", false, function()
        self.m_cutSceneAni:setVisible(false)
    end)
    self.m_baseCollectBar:setCollectTipState(false)
    util_spinePlay(self.m_cutSceneSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_cutSceneSpine, "actionframe_guochang", function()
        self.m_baseCollectBar:setCollectTipState(true)
        self.m_cutSceneSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    if playType == "freeStart" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_ToFree)
    elseif playType == "freeOver" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_ToBase)
    elseif playType == "bonus1" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_BonusReel_CutScene)
    end
    -- 75帧切过场(总共96帧)
    performWithDelay(self.m_scWaitNode, function()
        if playType == "freeStart" then
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            self.m_baseFreeSpinBar:setVisible(true)
            self:changeBgAndReelBg(2, true, "idle2")
        elseif playType == "freeOver" then
            self.m_baseFreeSpinBar:setVisible(false)
            self:changeBgAndReelBg(1, true, "idle1")
        elseif playType == "bonus1" then
            self:setBaseReelShow(false, 1)
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:changeBgAndReelBg(4, true, "idle3")
            else
                self:changeBgAndReelBg(3, true, "idle3")
            end
        end
    end, 75/30)
end

function CodeGameScreenMiningManiaMachine:showFreeSpinOverView()

    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 5, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_overOver)
        end, 5/60)
    end

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:showCutPlaySceneAni(function()
                self:triggerFreeSpinOverCallFun()
            end, "freeOver")
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},591)
        view:setBtnClickFunc(cutSceneFunc)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:showCutPlaySceneAni(function()
                self:triggerFreeSpinOverCallFun()
            end, "freeOver")
        end)
        view:setBtnClickFunc(cutSceneFunc)
    end
end

function CodeGameScreenMiningManiaMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWin",nil,_func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMiningManiaMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    self.m_isTriggerBonus = false

    self:stopLinesWinSound()

    return false -- 用作延时点击spin调用
end

function CodeGameScreenMiningManiaMachine:beginReel()
    self.collectBonus = false
    self.m_triggerBigWinEffect = false
    self.m_baseCollectBar:spinCloseTips()
    --前四列是否有bonus
    self.m_isHaveSpecialBonus = false
    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_effectFixdNode:setVisible(false)
    else
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        self.m_effectFixdNode:setVisible(true)
        local curBigSymbolNode = self.m_bigBonusNode
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            curBigSymbolNode = self.m_freeBigSymbolNode
        end
        if self.m_bigSymbolState ~= self.ENUM_BIG_SYMBOL_STATE.BONUS_1 and not tolua.isnull(curBigSymbolNode) then
            curBigSymbolNode:runAnim("idleframe3", false, function()
                curBigSymbolNode:runAnim("idleframe1", true)
            end)
        end
    end
        
    for i = 1, self.m_iReelColumnNum do
        self:changeMaskVisible(true, i, true)
        self.m_panelUpList[i]:setVisible(true)
        self:playMaskFadeAction(true, 0.2, i, function()
            self:changeMaskVisible(true, i)
        end)
    end
    CodeGameScreenMiningManiaMachine.super.beginReel(self)
end

-- free下固定第五列大信号
function CodeGameScreenMiningManiaMachine:addFreeFixBigNode()
    self.m_effectFixdNode:removeAllChildren()
    local targetPos = self:getWorldToNodePos(self.m_effectFixdNode, 19)
    --free底
    self.m_freeBigSymbolNodeBg = util_createAnimation("MiningMania_Free_ColBg.csb")
    self.m_effectFixdNode:addChild(self.m_freeBigSymbolNodeBg, 1)
    self.m_freeBigSymbolNodeBg:setPosition(targetPos)

    self.m_freeBigSymbolNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_1)
    self.m_effectFixdNode:addChild(self.m_freeBigSymbolNode, 10)
    self.m_freeBigSymbolNode:setPosition(targetPos)
    self.m_freeBigSymbolNode:runAnim("idleframe1", true)
end

-- 根据index转换需要节点坐标系
function CodeGameScreenMiningManiaMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenMiningManiaMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
        self.m_triggerBigWinEffect = true
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMiningManiaMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    --检测是否触发社交玩法
    self:checkTriggerBonus()

    -- 重置大信号动画状态
    self.m_bigSymbolState = self.ENUM_BIG_SYMBOL_STATE.BONUS_1
    -- 保存当前触发了几个玩法
    self.m_curTriggerPlayTbl = {}

    local hasBonus = self.m_runSpinResultData.p_selfMakeData.hasBonus
    -- 触发动画
    local isTrigger = false
    --判断当钱是否有玩法
    --Mul：bonus2钱数倍数；FsTimes：bonus4-free次数；Jp：jackpot类型
    local bonusPlayCoins, bonusPlayJp, bonusPlayFree = self:getCurBonusPlay()

    -- 添加大信号数据
    self.m_bigBonusArry = {}
    self.m_bigBonusNode = nil
    if hasBonus and (bonusPlayCoins or bonusPlayJp or bonusPlayFree) then
        self.m_curTriggerPlayTbl = {bonusPlayCoins, bonusPlayJp, bonusPlayFree}
        self:addCurIsBigBonusPlay()
    end

    -- 大信号玩法（上下拖拽）
    if #self.m_bigBonusArry > 0 then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_BIG_BONUS_PLAY
        effectData.p_selfEffectType = self.EFFECT_BIG_BONUS_PLAY
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    local positionScore = self.m_runSpinResultData.p_selfMakeData.positionScore or {}

    -- 房间里scatter基底收集
    if next(positionScore) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_SCATTER_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SCATTER_EFFECT -- 动画类型
    end
    
    local isHaveBonus = false
    -- bonus钱数收集
    if bonusPlayCoins then
        isHaveBonus = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_COINS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_COINS_EFFECT -- 动画类型
        isTrigger = true
    end

    -- jackpot收集
    if bonusPlayJp then
        isHaveBonus = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_JACKPOT_EFFECT -- 动画类型
        isTrigger = true
    end

    -- free次数收集
    if bonusPlayFree then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_FREE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_FREE_EFFECT -- 动画类型
        isTrigger = true
    end

    -- bonus结束后加钱
    if isHaveBonus then
        isHaveBonus = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_OVER_ADD_COINS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_OVER_ADD_COINS_EFFECT -- 动画类型
    end

    -- 触发动画
    if isTrigger then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_TRIGGER_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_TRIGGER_EFFECT -- 动画类型
    end
end

-- 获取当前bonus玩法
function CodeGameScreenMiningManiaMachine:getCurBonusPlay()
    --判断当钱是否有玩法
    --Mul：bonus2钱数倍数；FsTimes：bonus4-free次数；Jp：jackpot类型
    local positionData = self.m_runSpinResultData.p_selfMakeData.positionData or {}
    local hasBonus = self.m_runSpinResultData.p_selfMakeData.hasBonus
    local bonusPlayCoins, bonusPlayJp, bonusPlayFree
    if hasBonus and next(positionData) then
        for k, v in pairs(positionData) do
            local playType = v[1]
            if playType == "Mul" then
                bonusPlayCoins = true
            elseif playType == "Jp" then
                bonusPlayJp = true
            elseif playType == "FsTimes" then
                bonusPlayFree = true
            else
                print("error-type", playType)
            end
        end
    end
    return bonusPlayCoins, bonusPlayJp, bonusPlayFree
end

-- 获取是否有bonus
function CodeGameScreenMiningManiaMachine:getCurIsHaveBonus()
    local positionData = self.m_runSpinResultData.p_selfMakeData.positionData or {}
    local hasBonus = self.m_runSpinResultData.p_selfMakeData.hasBonus
    if hasBonus and next(positionData) then
        for k, v in pairs(positionData) do
            local playType = v[1]
            if playType == "Mul" or playType == "Jp" or playType == "FsTimes" then
                return true
            end
        end
    end
    return false
end

-- 是否有bonus3和bonus4
function CodeGameScreenMiningManiaMachine:getCurIsHaveSpecialBonus()
    local positionData = self.m_runSpinResultData.p_selfMakeData.positionData or {}
    if next(positionData) then
        for k, v in pairs(positionData) do
            local playType = v[1]
            if playType == "Jp" or playType == "FsTimes" then
                return true
            end
        end
    end
    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMiningManiaMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_SCATTER_EFFECT then
        self:showScatterCollectCoins(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BIG_BONUS_PLAY then
        self:showBigBonusPlay(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TRIGGER_EFFECT then
        self:showBonusTrigger(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_COINS_EFFECT then
        local bonusDataTbl = self:getSortCollectPlayData("Mul")
        self:showBonusCoins(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, bonusDataTbl, 1)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_JACKPOT_EFFECT then
        local jackpotDataTbl = self:getSortCollectPlayData("Jp")
        self:showBonusJackpot(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, jackpotDataTbl, 1)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_FREE_EFFECT then
        local freeDataTbl = self:getSortCollectPlayData("FsTimes")
        self:showBonusFreeTimes(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, freeDataTbl, 1, 0)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_OVER_ADD_COINS_EFFECT then
        self:addBonusCoins(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_MAIL_COLLECT then
        self:showMailWinView(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    return true
end

-- 排序玩法信息
function CodeGameScreenMiningManiaMachine:getSortCollectPlayData(_curType)
    local curType = _curType
    local tempDataTbl = {}
    local positionData = self.m_runSpinResultData.p_selfMakeData.positionData or {}
    if curType == "Mul" then
        for k, v in pairs(positionData) do
            local playType = v[1]
            if playType == "Mul" then
                local tempTbl = {}
                tempTbl.p_pos = tonumber(k)
                local fixPos = self:getRowAndColByPos(tonumber(k))
                tempTbl.m_mul = tonumber(v[2])
                tempTbl.p_rowIndex = fixPos.iX
                tempTbl.p_cloumnIndex = fixPos.iY
                table.insert(tempDataTbl, tempTbl)
            end
        end
    elseif curType == "Jp" then
        for k, v in pairs(positionData) do
            local playType = v[1]
            if playType == "Jp" then
                local tempTbl = {}
                tempTbl.p_pos = tonumber(k)
                local fixPos = self:getRowAndColByPos(tonumber(k))
                tempTbl.p_jpType = v[2]
                tempTbl.p_rowIndex = fixPos.iX
                tempTbl.p_cloumnIndex = fixPos.iY
                table.insert(tempDataTbl, tempTbl)
            end
        end
    elseif curType == "FsTimes" then
        for k, v in pairs(positionData) do
            local playType = v[1]
            if playType == "FsTimes" then
                local tempTbl = {}
                tempTbl.p_pos = tonumber(k)
                local fixPos = self:getRowAndColByPos(tonumber(k))
                tempTbl.p_freeTimes = tonumber(v[2])
                tempTbl.p_rowIndex = fixPos.iX
                tempTbl.p_cloumnIndex = fixPos.iY
                table.insert(tempDataTbl, tempTbl)
            end
        end
    end
    
    table.sort(tempDataTbl, function(a, b)
        if a.p_cloumnIndex ~= b.p_cloumnIndex then
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
        if a.p_rowIndex ~= b.p_rowIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return false
    end)
    return tempDataTbl
end

-- 添加bonus大信号信息
function CodeGameScreenMiningManiaMachine:addCurIsBigBonusPlay()
    for iCol = 1, self.m_iReelColumnNum do --列
        local tempRow = nil
        for iRow = self.m_iReelRowNum, 1, -1 do --行
            if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_SCORE_BONUS_1 then
                tempRow = iRow
            else
                break
            end
        end
        -- 向下
        if tempRow ~= nil and tempRow ~= 1 then
            self.m_bigBonusArry[#self.m_bigBonusArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            self.m_bigBonusNode = self:getFixSymbol(iCol , tempRow , SYMBOL_NODE_TAG)
        end

        tempRow = nil
        for iRow = 1, self.m_iReelRowNum, 1 do --行
            if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_SCORE_BONUS_1 then
                tempRow = iRow
            else
                break
            end
        end
        -- 向上
        if tempRow ~= nil and tempRow ~= self.m_iReelRowNum then
            self.m_bigBonusArry[#self.m_bigBonusArry + 1] = {col = iCol, row = tempRow, direction = "up"}
            self.m_bigBonusNode = self:getFixSymbol(iCol , tempRow , SYMBOL_NODE_TAG)
        end

        --中间
        local bonusCount = 0
        for iRow = 1, self.m_iReelRowNum, 1 do --行
            if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_SCORE_BONUS_1 then
                bonusCount = bonusCount + 1
            else
                break
            end
        end
        if bonusCount == 4 then
            self.m_bigBonusNode = self:getFixSymbol(self.m_iReelColumnNum, 1 , SYMBOL_NODE_TAG)
        end
    end
end

function CodeGameScreenMiningManiaMachine:showBigBonusPlay(_callFunc)
    local callFunc = _callFunc
    local delayTime = 0
    for i = 1, #self.m_bigBonusArry, 1 do
        local temp = self.m_bigBonusArry[i]
        local iRow = temp.row
        local effectAnimation = "actionframe1_up"
        local arrowAnimation = "actionframe_up"
        if temp.direction == "up" then
            iRow = temp.row + 1 - 4
            effectAnimation = "actionframe1_up"
            arrowAnimation = "actionframe_up"
        elseif temp.direction == "down" then
            effectAnimation = "actionframe1_down"
            arrowAnimation = "actionframe_down"
        end
        local iTempRow = {} --隐藏小块避免穿帮
        if iRow == -2 then
            iTempRow[1] = 2
            iTempRow[2] = 3
            iTempRow[3] = 4
        elseif iRow == -1 then
            iTempRow[1] = 3
            iTempRow[2] = 4
        elseif iRow == 0 then
            iTempRow[1] = 4
        elseif iRow == 2 then
            iTempRow[1] = 1
        elseif iRow == 3 then
            iTempRow[1] = 1
            iTempRow[2] = 2
        elseif iRow == 4 then
            iTempRow[1] = 1
            iTempRow[2] = 2
            iTempRow[3] = 3
        end

        delayTime = delayTime + 60/60
        self.m_arrowAni:setVisible(true)
        self.m_arrowAni:runCsbAction(arrowAnimation, false, function()
            self.m_arrowAni:setVisible(false)
            local bigSymbolNode = self:getFixSymbol(temp.col, iRow, SYMBOL_NODE_TAG)
            -- local bigSymbolNode = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iRow, SYMBOL_NODE_TAG))
            --卷轴滚动
            if bigSymbolNode then
                if tolua.isnull(self.m_bigBonusNode) then
                    self.m_bigBonusNode = bigSymbolNode
                end
                -- bigSymbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100)
                bigSymbolNode:hideBigSymbolClip()
                bigSymbolNode.p_rowIndex = 1
                local distance = (1 - iRow) * self.m_SlotNodeH
                local runTime = 15/30
                delayTime = delayTime + runTime

                local seq =cc.Sequence:create(cc.MoveBy:create(runTime, cc.p(0, distance)))
                for j = 1, #iTempRow, 1 do
                    local symbolNode = self:getFixSymbol(temp.col, iTempRow[j], SYMBOL_NODE_TAG)
                    -- local symbolNode = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iTempRow[j], SYMBOL_NODE_TAG))
                    if symbolNode ~= nil then
                        local seq = cc.Sequence:create(cc.MoveBy:create(runTime, cc.p(0, distance)),cc.CallFunc:create(function()
                            symbolNode:removeFromParent(true)
                        end))
                        symbolNode:runAction(seq)
                    end
                end
                bigSymbolNode:runAnim(effectAnimation, false, function()
                    bigSymbolNode:runAnim("idleframe1", true)
                end)
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Special_Bonus_Move)
                bigSymbolNode:runAction(seq)
                bigSymbolNode.m_bInLine = true
                local linePos = {}
                for i = 1, 4 do
                    linePos[#linePos + 1] = {iX = i, iY = temp.col}
                end
                bigSymbolNode:setLinePos(linePos)
            end
        end)
    end

    performWithDelay(self.m_scWaitNode,function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end,delayTime + 0.5)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenMiningManiaMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe")
    util_shakeNode(rootNode,5,10,aniTime)
end

--statter收集
function CodeGameScreenMiningManiaMachine:showScatterCollectCoins(_callFunc)
    local callFunc = _callFunc
    self.m_effectNode:removeAllChildren()
    local positionScore = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
    local scatterPos = {}
    if next(positionScore) then
        for k, v in pairs(positionScore) do
            local pos = tonumber(k)
            scatterPos[#scatterPos+1] = pos
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:runAnim("shouji", false, function()
                    symbolNode:runAnim("idleframe1", true)
                end)
            end
        end
    end

    -- scatter收集动画19帧
    -- 收集（粒子飞行）
    for index=1, #scatterPos do
        local isEnd = index == #scatterPos and true or false
        local symbolNodePos = scatterPos[index]
        local particleNode = util_createAnimation("MiningMania_scatter_shouji.csb")
        local m_particleTbl = {}
        for i=1, 2 do
            m_particleTbl[i] = particleNode:findChild("Particle_"..i)
            m_particleTbl[i]:setPositionType(0)
            m_particleTbl[i]:setDuration(-1)
            m_particleTbl[i]:resetSystem()
        end

        local startPos = self:getWorldToNodePos(self.m_effectNode, symbolNodePos)
        local endPos = util_convertToNodeSpace(self:findChild("Shoujiqu"), self.m_effectNode)
        particleNode:setPosition(startPos)
        self.m_effectNode:addChild(particleNode)

        local tblActionList = {}
        local delayTime = 0.4
        local delayTime1 = 19/30-delayTime
        tblActionList[#tblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            for i=1, 2 do
                m_particleTbl[i]:stopSystem()
            end
            if isEnd then
                self:refreshBaseCollectScore()
            end
        end)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            if isEnd then
                if type(callFunc) == "function" then
                    callFunc()
                end
            end
        end)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            particleNode:setVisible(false)
        end)

        particleNode:runAction(cc.Sequence:create(tblActionList))
    end
end

-- 触发bonus玩法时；把scatter层级放在slotParent上；spin时再放回去
function CodeGameScreenMiningManiaMachine:changeSymbolParentNode(_onTop)
    local onTop = _onTop
    local positionScore = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
    if next(positionScore) then
        for k, v in pairs(positionScore) do
            local pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if onTop then
                    self:putSymbolBackToPreParent(symbolNode, true)
                else
                    self:putSymbolBackToPreParent(symbolNode, false)
                end
            end
        end
    end
end

--[[
    将小块放回原父节点
]]
function CodeGameScreenMiningManiaMachine:putSymbolBackToPreParent(symbolNode, isInTop)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
        local parentData = self.m_slotParents[symbolNode.p_cloumnIndex]
        if not symbolNode.m_baseNode then
            symbolNode.m_baseNode = parentData.slotParent
        end

        if not symbolNode.m_topNode then
            symbolNode.m_topNode = parentData.slotParentBig
        end

        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        local zOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
        -- local isInTop = self:isSpecialSymbol(symbolNode.p_symbolType)
        symbolNode.m_isInTop = isInTop
        symbolNode:putBackToPreParent()

        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))
    end
end

-- bonus触发
function CodeGameScreenMiningManiaMachine:showBonusTrigger(_callFunc)
    self:changeSymbolParentNode(false)
    self:showMask(true)
    local callFunc = _callFunc
    local positionData = self.m_runSpinResultData.p_selfMakeData.positionData or {}
    local randomNum = math.random(1, 10)
    if randomNum <= 3 then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Weight_Play)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Trigger_Play)
    for k, v in pairs(positionData) do
        local pos = tonumber(k)
        local fixPos = self:getRowAndColByPos(pos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
            symbolNode:runAnim("actionframe", false, function()
                symbolNode:runAnim("idleframe1", true)
            end)
        end
    end

    -- free的话，取上边的大信号
    local curBigSymbolNode = self.m_bigBonusNode
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        curBigSymbolNode = self.m_freeBigSymbolNode
    end
    if not tolua.isnull(curBigSymbolNode) then
        curBigSymbolNode:runAnim("actionframe", false, function()
            curBigSymbolNode:runAnim("idleframe1", true)
        end)
    end

    performWithDelay(self.m_scWaitNode, function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, 60/30)
end

-- 30%播放
function CodeGameScreenMiningManiaMachine:playBonusSoundToWeight(_playType)
    local num = math.random(1, 10)
    if num <= 3 then
        local soundRandom = math.random(1, 2)
        if _playType == "green" then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Bonus_Green[soundRandom])
        elseif _playType == "red" then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Bonus_Green[soundRandom])
        elseif _playType == "gold" then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Collect_Bonus_Green[soundRandom])
        end
    end
end

--bonus2收集钱
function CodeGameScreenMiningManiaMachine:showBonusCoins(_callFunc, _bonusDataTbl, _curIndex)
    self.collectBonus = true
    self:showMask(true)
    local callFunc = _callFunc
    local bonusDataTbl = _bonusDataTbl
    local curIndex = _curIndex

    if curIndex > #bonusDataTbl then
        self.collectBonus = false
        self:showMask(false, 1)
        performWithDelay(self.m_scWaitNode, function()
            self.m_effectNode:removeAllChildren()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 0.5)
        return
    end

    local bonusData = bonusDataTbl[curIndex]
    local curBet = globalData.slotRunData:getCurTotalBet()
    local curMul = bonusData.m_mul
    local symbolNodePos = bonusData.p_pos
    local winCoins = curMul * curBet
    local sScore = util_formatCoins(winCoins, 3)

    -- 最终位置为第五列中间靠下（直接算出来）
    local endNodePos = self:getWorldToNodePos(self.m_effectNode, 14)
    local delayTime = 0.3

    local bonusNodeScore = util_createAnimation("Socre_MiningMania_BonusScore.csb")
    bonusNodeScore:runCsbAction("idle1", true)
    bonusNodeScore:findChild("m_lb_num"):setString(sScore)

    local particleNode = util_createAnimation("MiningMania_bonus2_shouji.csb")
    local m_particleTbl = {}
    for i=1, 2 do
        m_particleTbl[i] = particleNode:findChild("Particle_"..i)
        m_particleTbl[i]:setPositionType(0)
        m_particleTbl[i]:setDuration(-1)
        m_particleTbl[i]:resetSystem()
    end

    local fixPos = self:getRowAndColByPos(symbolNodePos)
    local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
        symbolNode:runAnim("idleframe", true)
    end

    -- 假的信号飞行
    local flyNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_NULL)
    local bonusNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_2)
    local startPos = self:getWorldToNodePos(self.m_effectNode, symbolNodePos)
    bonusNode:runAnim("shouji", false)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode)
    flyNode:addChild(particleNode, 1)
    flyNode:addChild(bonusNode, 10)
    local m_spine = bonusNode:getNodeSpine()
    util_spinePushBindNode(m_spine,"zi",bonusNodeScore)
    
    performWithDelay(self.m_scWaitNode, function()
        -- free的话，取上边的大信号
        local curBigSymbolNode = self.m_bigBonusNode
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            curBigSymbolNode = self.m_freeBigSymbolNode
        end
        if not tolua.isnull(curBigSymbolNode) then
            if self.m_bigSymbolState == self.ENUM_BIG_SYMBOL_STATE.BONUS_1 then
                self.m_bigSymbolState = self.ENUM_BIG_SYMBOL_STATE.BONUS_2
                curBigSymbolNode:runAnim("fankui1_1", false, function()
                    curBigSymbolNode:runAnim("idleframe2", true)
                end)
            else
                curBigSymbolNode:runAnim("fankui1_2", false, function()
                    curBigSymbolNode:runAnim("idleframe2", true)
                end)
            end
        end
    end, 15/30)

    local midPos = cc.p((startPos.x + endNodePos.x)/2, startPos.y+200)
    local actionList = {}
    actionList[#actionList + 1] = cc.EaseSineOut:create(cc.BezierTo:create(20/30, {startPos, midPos, endNodePos}))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        for i=1, 2 do
            m_particleTbl[i]:stopSystem()
        end
        performWithDelay(self.m_scWaitNode, function()
            if not tolua.isnull(particleNode) then
                particleNode:setVisible(false)
            end
        end, 0.5)
        bonusNode:removeFromParent()
        -- self.m_coinsText:setString("+"..winCoins)
        -- self.m_collectEffectNum:setVisible(true)
        -- self.m_collectEffectNum:runCsbAction("actionframe")
        local params = {
            overCoins  = winCoins,
            jumpTime   = 0.1,
            animName   = "actionframe2",
        }
        self:playBottomBigWinLabAnim(params)

        gLobalSoundManager:playSound(self.m_publicConfig.Music_Bottom_Coins_Refresh)
        self:playhBottomLight(winCoins, true)
        self:showBonusCoins(callFunc, bonusDataTbl, curIndex+1)
    end)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:playBonusSoundToWeight("green")
    end
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_CollectFeedBack)
    flyNode:runAction(cc.Sequence:create(actionList))
end

--bonus4收集free次数
function CodeGameScreenMiningManiaMachine:showBonusFreeTimes(_callFunc, _freeDataTbl, _curIndex, _curTotalTimes)
    self:showMask(true)
    local callFunc = _callFunc
    local freeDataTbl = _freeDataTbl
    local curIndex = _curIndex
    local curTotalTimes = _curTotalTimes

    if curIndex > #freeDataTbl then
        performWithDelay(self.m_scWaitNode, function()
            self.m_effectNode:removeAllChildren()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 0.5)
        return
    end

    local freeData = freeDataTbl[curIndex]
    local curFreeTimes = freeData.p_freeTimes
    local symbolNodePos = freeData.p_pos
    curTotalTimes = curTotalTimes + curFreeTimes

    -- 最终位置为第五列中间靠下（直接算出来）
    local endNodePos = self:getWorldToNodePos(self.m_effectNode, 14)
    local delayTime = 0.3

    local bonusNodeScore = util_createAnimation("Socre_MiningMania_BonusScore.csb")
    bonusNodeScore:runCsbAction("idle3", true)
    bonusNodeScore:findChild("m_lb_num1"):setString(curFreeTimes)

    local particleNode = util_createAnimation("MiningMania_bonus4_shouji.csb")
    local m_particleTbl = {}
    for i=1, 2 do
        m_particleTbl[i] = particleNode:findChild("Particle_"..i)
        m_particleTbl[i]:setPositionType(0)
        m_particleTbl[i]:setDuration(-1)
        m_particleTbl[i]:resetSystem()
    end

    local fixPos = self:getRowAndColByPos(symbolNodePos)
    local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
        symbolNode:runAnim("idleframe", true)
    end

    -- 假的信号飞行
    local flyNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_NULL)
    local bonusNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_4)
    local startPos = self:getWorldToNodePos(self.m_effectNode, symbolNodePos)
    bonusNode:runAnim("shouji", false)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode)
    flyNode:addChild(particleNode, 1)
    flyNode:addChild(bonusNode, 10)
    local m_spine = bonusNode:getNodeSpine()
    util_spinePushBindNode(m_spine,"zi",bonusNodeScore)
    
    performWithDelay(self.m_scWaitNode, function()
        -- free的话，取上边的大信号
        local curBigSymbolNode = self.m_bigBonusNode
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            curBigSymbolNode = self.m_freeBigSymbolNode
        end
        if not tolua.isnull(curBigSymbolNode) then
            if self.m_bigSymbolState == self.ENUM_BIG_SYMBOL_STATE.BONUS_1 then
                self.m_bigSymbolState = self.ENUM_BIG_SYMBOL_STATE.BONUS_4
                curBigSymbolNode:runAnim("fankui2_1", false, function()
                    curBigSymbolNode:runAnim("idleframe2", true)
                end)
            else
                curBigSymbolNode:runAnim("fankui2_2", false, function()
                    curBigSymbolNode:runAnim("idleframe2", true)
                end)
            end   
        end
    end, 15/30)

    local midPos = cc.p((startPos.x + endNodePos.x)/2, startPos.y+200)
    local actionList = {}
    actionList[#actionList + 1] = cc.EaseSineOut:create(cc.BezierTo:create(20/30, {startPos, midPos, endNodePos}))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if not tolua.isnull(self.m_bigBonusNode) then
            local symbol_node = self.m_bigBonusNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            local bigNodeScore
            if not tolua.isnull(spineNode.m_bigNodeScore) then
                bigNodeScore = spineNode.m_bigNodeScore
            else
                bigNodeScore = util_createAnimation("Socre_MiningMania_BonusScore.csb")
                util_spinePushBindNode(spineNode,"node_2",bigNodeScore)
                spineNode.m_bigNodeScore = bigNodeScore
            end
            if bigNodeScore then
                bigNodeScore:setVisible(true)
                bigNodeScore:runCsbAction("idle3", true)
                local textNode = bigNodeScore:findChild("m_lb_num1")
                local testSpin = bigNodeScore:findChild("MiningMania_wenzi")
                local fgNode = bigNodeScore:findChild("Node_fg")
                textNode:setString(curTotalTimes)
                self:setSpinNodeScale(fgNode, {testSpin, textNode}, true, 160)
            end
        end
        for i=1, 2 do
            m_particleTbl[i]:stopSystem()
        end
        performWithDelay(self.m_scWaitNode, function()
            if not tolua.isnull(particleNode) then
                particleNode:setVisible(false)
            end
        end, 0.5)
        bonusNode:removeFromParent()
        self:showBonusFreeTimes(callFunc, freeDataTbl, curIndex+1, curTotalTimes)
    end)
    self:playBonusSoundToWeight("gold")
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_CollectFeedBack)
    flyNode:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenMiningManiaMachine:setSpinNodeScale(parentNode, nodes, useScale, totalWidth)
    local tblWidth = {}
    local totalNodeWidth = 0
    for i, node in ipairs(nodes) do
        tblWidth[i] = node:getContentSize().width
        if useScale then
            tblWidth[i] = tblWidth[i] * node:getScale()
        end
        totalNodeWidth = totalNodeWidth + tblWidth[i]
    end
    local targetScale = totalWidth/totalNodeWidth
    local diffX = (tblWidth[2] - 40)*targetScale/2
    parentNode:setScale(targetScale)
    parentNode:setPositionX(-diffX)
end

--bonus3收集jackpot
function CodeGameScreenMiningManiaMachine:showBonusJackpot(_callFunc, _jackpotDataTbl, _curIndex)
    self:setMaxMusicBGVolume()
    self:showMask(true)
    local callFunc = _callFunc
    local jackpotDataTbl = _jackpotDataTbl
    local curIndex = _curIndex
    if curIndex > #jackpotDataTbl then
        self:reelsDownDelaySetMusicBGVolume()
        self.m_jackPotBar:setJpIdle()
        if not self:checkHasBigWin() then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end
        self:showMask(false, 2)
        performWithDelay(self.m_scWaitNode, function()
            self.m_effectNode:removeAllChildren()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, 0.5)
        return
    end

    local jackpotData = jackpotDataTbl[curIndex]
    local symbolNodePos = jackpotData.p_pos
    local jackpotType = jackpotData.p_jpType
    local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    local jackpotCoins = allJackpotCoins[jackpotType] or 0

    local bonusNodeScore = util_createAnimation("Socre_MiningMania_BonusScore.csb")
    bonusNodeScore:runCsbAction("idle2", true)
    bonusNodeScore:findChild("grand"):setVisible(jackpotType == "Grand")
    bonusNodeScore:findChild("major"):setVisible(jackpotType == "Major")
    bonusNodeScore:findChild("minor"):setVisible(jackpotType == "Minor")
    bonusNodeScore:findChild("mini"):setVisible(jackpotType == "Mini")
    
    local jackpotIndex = 4
    if jackpotType == "Mini" then
        jackpotIndex = 4
    elseif jackpotType == "Minor" then
        jackpotIndex = 3
    elseif jackpotType == "Major" then
        jackpotIndex = 2
    elseif jackpotType == "Grand" then
        jackpotIndex = 1
    end
    local startPos = self:getWorldToNodePos(self.m_effectNode, symbolNodePos)

    -- jackpot触发
    self.m_jackPotBar:triggerJackpot(jackpotIndex)

    local particleNode = util_createAnimation("MiningMania_bonus3_shouji.csb")
    local m_particleTbl = {}
    for i=1, 2 do
        m_particleTbl[i] = particleNode:findChild("Particle_"..i)
        m_particleTbl[i]:setPositionType(0)
        m_particleTbl[i]:setDuration(-1)
        m_particleTbl[i]:resetSystem()
    end

    local fixPos = self:getRowAndColByPos(symbolNodePos)
    local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
        symbolNode:runAnim("idleframe", true)
    end

    -- 假的信号飞行
    local flyNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_NULL)
    local bonusNode = self:createMiningManiaSymbol(self.SYMBOL_SCORE_BONUS_3)
    bonusNode:runAnim("shouji", false)
    flyNode:setPosition(startPos)
    self.m_effectNode:addChild(flyNode)
    flyNode:addChild(particleNode, 1)
    flyNode:addChild(bonusNode, 10)
    bonusNode:addChild(bonusNodeScore)

    performWithDelay(self.m_scWaitNode, function()
        -- free的话，取上边的大信号
        local curBigSymbolNode = self.m_bigBonusNode
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            curBigSymbolNode = self.m_freeBigSymbolNode
        end
        if not tolua.isnull(curBigSymbolNode) then
            if self.m_bigSymbolState == self.ENUM_BIG_SYMBOL_STATE.BONUS_1 then
                self.m_bigSymbolState = self.ENUM_BIG_SYMBOL_STATE.BONUS_3
                curBigSymbolNode:runAnim("fankui3_1", false, function()
                    curBigSymbolNode:runAnim("idleframe2", true)
                end)
            else
                curBigSymbolNode:runAnim("fankui3_2", false, function()
                    curBigSymbolNode:runAnim("idleframe2", true)
                end)
            end   
        end
    end, 15/30)

    -- 最终位置为第五列中间靠下（直接算出来）
    local endNodePos = self:getWorldToNodePos(self.m_effectNode, 14)
    local midPos = cc.p((startPos.x + endNodePos.x)/2, startPos.y+200)
    local actionList = {}
    actionList[#actionList + 1] = cc.EaseSineOut:create(cc.BezierTo:create(20/30, {startPos, midPos, endNodePos}))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        bonusNode:removeFromParent()
        for i=1, 2 do
            m_particleTbl[i]:stopSystem()
        end
        performWithDelay(self.m_scWaitNode, function()
            if not tolua.isnull(particleNode) then
                particleNode:setVisible(false)
            end
        end, 0.5)
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(15/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        local jackPotWinView = util_createView("CodeMiningManiaSrc.MiningManiaJackpotWinView")
        self:addChild(jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        local jpData = {}
        jpData.coins = jackpotCoins
        jpData.index = jackpotIndex
        jpData.machine = self
        if jackpotIndex <= 2 then
            self:levelDeviceVibrate(6, "jackpot")
        end
        jackPotWinView:initViewData(jpData)
        jackPotWinView:setOverAniRunFunc(function()
            self:showBonusJackpot(callFunc, jackpotDataTbl, curIndex+1)
        end)
        self:playhBottomLight(jackpotCoins)
    end)
    self:playBonusSoundToWeight("red")
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_CollectFeedBack)
    flyNode:runAction(cc.Sequence:create(actionList))
end

-- bonus收集完通知上边加钱
function CodeGameScreenMiningManiaMachine:addBonusCoins(_callFunc)
    local callFunc = _callFunc
    local winLines = self.m_reelResultLines
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and #winLines <= 0 then
        self:checkNotifyUpdateWinCoin(true)
    end

    if type(callFunc) == "function" then
        callFunc()
    end
end

function CodeGameScreenMiningManiaMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    CodeGameScreenMiningManiaMachine.super.showEffect_runBigWinLightAni(self, effectData)
    return true
end

-- 显示遮罩
function CodeGameScreenMiningManiaMachine:showMask(_showState, _index)
    local showState = _showState
    local index = _index
    
    if _showState then
        if not self.m_maskAni:isVisible() then
            self.m_maskAni:setVisible(true)
            self.m_maskAni:runCsbAction("start", false, function()
                self.m_maskAni:runCsbAction("idle", true)
            end)
        end
    else
        self.m_curTriggerPlayTbl[index] = false
        local isOver = true
        for k, v in pairs(self.m_curTriggerPlayTbl) do
            if v then
                isOver = false
                break
            end
        end
        if isOver and self.m_maskAni:isVisible() then
            self:changeSymbolParentNode(true)
            self.m_maskAni:runCsbAction("over", false, function()
                self.m_maskAni:setVisible(false)
            end)
        end
    end
end

function CodeGameScreenMiningManiaMachine:createMiningManiaSymbol(_symbolType)
    local symbol = util_createView("CodeMiningManiaSrc.MiningManiaSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

--[[
    检测是否触发bonus
]]
function CodeGameScreenMiningManiaMachine:checkTriggerBonus()

    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect and gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
            return true
        end
    end
    
    --有玩家触发Bonus
    local result = self.m_roomData:getSpotResult()

    if result then
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        self:addBonusEffect(result)
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenMiningManiaMachine:addBonusEffect(result)
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
    --进入玩法后需要使用拷贝出来的result结果,本地roomData中的result需要清空,防止重复触发玩法
    effect.resultData = clone(result) 

    self.m_isTriggerBonus = true
end

--[[
    社交1玩法
]]
function CodeGameScreenMiningManiaMachine:showEffect_Bonus(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    if self.m_bottomUI.m_spinBtn.m_autoSpinChooseNode and self.m_bottomUI.m_spinBtn.m_autoSpinChooseNode.hide then
        self.m_bottomUI.m_spinBtn.m_autoSpinChooseNode:hide()
    end
    local delayTime = 0
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        local positionScore = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
        if next(positionScore) then
            self:playScatterTipMusicEffect()
            delayTime = 60/30+0.5
            for k, v in pairs(positionScore) do
                local pos = tonumber(k)
                local fixPos = self:getRowAndColByPos(pos)
                local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    symbolNode:runAnim("actionframe", false, function()
                        symbolNode:runAnim("idleframe1", true)
                    end)
                end
            end
        end
    end

    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")
    -- 临时修改层级
    -- self.m_bottomUI:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP-2)
    
    local result = effectData.resultData
    -- self:showBonusCarPlayView(result, effectData)
    
    if self.m_isBonusPlaying then
        return
    end
    self.m_isBonusPlaying = true

    self:clearCurMusicBg()
    self:setMaxMusicBGVolume()

    self:removeSoundHandler()
    --bonus结束回调
    local function bonusEnd()
        self:showBonusCarPlayView(result, effectData)
    end

    -- bonusEnd()

    --清理连线
    self:clearWinLineEffect()
    --清空赢钱
    -- self.m_bottomUI:updateWinCount("")

    performWithDelay(self.m_scWaitNode, function()
        self:showSheJiaoStart(result, function()
            self:resetMusicBg(nil, self.m_publicConfig.Music_Bonus_Bg_1)
            self.m_machine_bonus:resetUI(result,bonusEnd)
            self:showCutPlaySceneAni(function()
                --隐藏基础轮盘
                -- self:setBaseReelShow(false, 1)
                -- self.m_machine_bonus:resetUI(result,bonusEnd)
        
                self.m_machine_bonus:showStartBonusView()
                
                self.m_roomData.m_teamData.room.result = nil
                self.m_roomList:refreshPlayInfo()
            end, "bonus1")
        end)
    end, delayTime)
    return true
end

-- 社交2玩法
function CodeGameScreenMiningManiaMachine:showBonusCarPlayView(_resultData, _effectData)
    local resultData = _resultData
    local effectData = _effectData

    self.m_bottomUI:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP-2)
    --bonus结束回调
    local function bonusEnd()
        if self:judgeIsFree() then
            self:setCurrSpinMode(FREE_SPIN_MODE)
        else
            --变更轮盘状态
            if globalData.slotRunData.m_isAutoSpinAction then
                self:setCurrSpinMode(AUTO_SPIN_MODE)
            else
                self:setCurrSpinMode(NORMAL_SPIN_MODE)
            end
        end

        performWithDelay(self.m_scWaitNode, function()
            self.m_machine_carView:showNodeBg(false)
        end, 45/60)
        
        --重置bonus触发状态
        self.m_isBonusPlaying = false
        self.m_isTriggerBonus = false

        self.m_bottomUI:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
        
        -- 刷新房间收集分数
        self:refreshBaseCollectScore(true)
        self:findChild("Node_base"):setVisible(true)
        self.m_bottomUI:setVisible(true)
        self:changeBgAndReelBg(1)

        local particle = self:findChild("Particle_1")
        --50帧后播粒子
        performWithDelay(self.m_scWaitNode, function()
            particle:resetSystem()
        end, 70/60)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_BonusCar_ToBase)
        self:runCsbAction("actionframe", false, function()
            particle:stopSystem()
            effectData.p_isPlay = true
            self:playGameEffect()
            --显示基础轮盘
            self:setBaseReelShow(true)
            self:resetMusicBg()
        end)
        self.m_machine_carView:runCsbAction("actionframe", false)

        --重新刷新房间数据
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
    end

    self:resetMusicBg(nil, self.m_publicConfig.Music_Bonus_Bg_2)
    self.m_machine_carView:setVisible(true)
    self:runCsbAction("actionframe_guochang", false, function()
        self:runCsbAction("idle", true)
    end)
    self.m_machine_carView:resetData(resultData, bonusEnd)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Reel_Enter_Car)
    self.m_machine_carView:runCsbAction("actionframe_guochang", false, function()
        self:setBaseReelShow(false, 2)
        self.m_machine_carView:showBonusView()
    end)
    self.m_roomData.m_teamData.room.result = nil
end

-- 判断社交结束后是否是free
function CodeGameScreenMiningManiaMachine:judgeIsFree()
    if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0
    and self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinNewCount
    and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinNewCount then
        return true
    end
    return false
end

-- 触发社交弹板
function CodeGameScreenMiningManiaMachine:showSheJiaoStart(_result, _callfunc)
    local result = _result
    gLobalSoundManager:playSound(self.m_publicConfig.Music_BonusReel_Start_Dialog)
    local view = self:showDialog("MinecartRushStart", nil, _callfunc, BaseDialog.AUTO_TYPE_ONLY)
    view:findChild("root"):setScale(self.m_machineRootScale)
    local item = util_createView("CodeMiningManiaSrc.MiningManiaPlayerItem")
    view:findChild("Node_role"):addChild(item)

    -- 触发的玩家
    local triggerPlayer = result.data.triggerPlayer
    local playersInfo = self.m_roomData:getRoomPlayersInfo()
    for index = 1, 5 do
        local info = playersInfo[index]
        if info then
            local udid = item:getPlayerID()
            item:refreshData(info)
            --刷新头像
            if triggerPlayer and triggerPlayer.chairId == info.chairId then
                item:refreshHead()
                break
            end
        end
    end
    util_setCascadeOpacityEnabledRescursion(view, true)
    return view
end

--[[
    社交结束
]]
function CodeGameScreenMiningManiaMachine:showBonusOverView(_userScore, _userMul, func)
    self:clearCurMusicBg()
    local winSpots = self.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local winCoins = winSpots[#winSpots].coins
        --检测是否获得大奖
        self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
        local curIndex = #winSpots - 1
        local view = util_createView("CodeMiningManiaSrc.MiningManiaMailWin",{machine = self, index = curIndex})
        view:initViewData(winCoins, _userMul, _userScore)
        view:setFunc(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            if type(func) == "function" then
                func()
            end
        end)

        gLobalViewManager:showUI(view)
    else
        if type(func) == "function" then
            func()
        end
    end
end

function CodeGameScreenMiningManiaMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMiningManiaMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenMiningManiaMachine:slotReelDown()
    --其他玩家大赢事件
    local eventData = self.m_roomData:getRoomEvent()
    self.m_roomList:showBigWinAni(eventData)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenMiningManiaMachine.super.slotReelDown(self)
end

function CodeGameScreenMiningManiaMachine:updateReelGridNode(_symbolNode)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if _symbolNode and _symbolNode.p_symbolType ~= self.SYMBOL_SCORE_FREE_NULL and _symbolNode.p_cloumnIndex == self.m_iReelColumnNum then
            -- _symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_FREE_NULL), self.SYMBOL_SCORE_FREE_NULL)
        end
    end
    if _symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        self:setSpecialNodeFreeCoins(_symbolNode)
    elseif self:getCurSymbolIsBonus(_symbolNode.p_symbolType) then
        self:setSpecialNodeScoreBonus(_symbolNode)
    elseif _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
       self:setBigSymbolNodeState(_symbolNode)
    end
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenMiningManiaMachine:checkHasGameEffect(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

-- 设置大信号上的free次数不显示
function CodeGameScreenMiningManiaMachine:setBigSymbolNodeState(_symbolNode)
    local symbolNode = _symbolNode
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if not tolua.isnull(spineNode.m_bigNodeScore) then
        util_spineRemoveBindNode(spineNode, spineNode.m_bigNodeScore)
        spineNode.m_bigNodeScore = nil
    end
end

--设置bonus上的钱数；jackpot；free次数
function CodeGameScreenMiningManiaMachine:setSpecialNodeScoreBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()
    local sScore = ""
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore, mul
    if not tolua.isnull(spineNode.m_nodeScore) then
        nodeScore = spineNode.m_nodeScore
    else
        nodeScore = util_createAnimation("Socre_MiningMania_BonusScore.csb")
        util_spinePushBindNode(spineNode,"zi",nodeScore)
        spineNode.m_nodeScore = nodeScore
    end

    if symbolNode.m_isLastSymbol == true then
        sScore = self:getBonusCoins(self:getPosReelIdx(iRow, iCol), symbolNode.p_symbolType)
    else
        -- 获取随机分数（本地配置）
        sScore = self:randomDownSymbolScore(symbolNode.p_symbolType)
    end
    if nodeScore then
        if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
            nodeScore:runCsbAction("idle1", true)
            nodeScore:findChild("m_lb_num"):setString(sScore)
        elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_3 then
            nodeScore:runCsbAction("idle2", true)
            nodeScore:findChild("grand"):setVisible(sScore == "Grand")
            nodeScore:findChild("major"):setVisible(sScore == "Major")
            nodeScore:findChild("minor"):setVisible(sScore == "Minor")
            nodeScore:findChild("mini"):setVisible(sScore == "Mini")
        elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_4 then
            nodeScore:runCsbAction("idle3", true)
            nodeScore:findChild("m_lb_num1"):setString(sScore)
        end
    end
end

function CodeGameScreenMiningManiaMachine:getBonusCoins(id, _symbolType)
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local positionData = self.m_runSpinResultData.p_selfMakeData.positionData or {}
    if next(positionData) then
        for k, v in pairs(positionData) do
            local curPos = tonumber(k)
            if curPos == id then
                if _symbolType == self.SYMBOL_SCORE_BONUS_2 then
                    local curBet = globalData.slotRunData:getCurTotalBet()
                    local mul = tonumber(v[2])
                    local coins = mul * curBet
                    local sScore = util_formatCoins(coins, 3)
                    return sScore
                elseif _symbolType == self.SYMBOL_SCORE_BONUS_3 then
                    local jackpotType = v[2]
                    return jackpotType
                elseif _symbolType == self.SYMBOL_SCORE_BONUS_4 then
                    local freeTimes = tonumber(v[2])
                    return freeTimes
                else
                    print("error-_symbolType", _symbolType)
                end
            end
        end
    end
end

--设置scatter上的钱数
function CodeGameScreenMiningManiaMachine:setSpecialNodeFreeCoins(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()
    local sScore = ""
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local scNodeCoins, scatterCoins
    if not tolua.isnull(spineNode.m_scatterCoins) then
        scNodeCoins = spineNode.m_scatterCoins
    else
        scNodeCoins = util_createAnimation("Socre_MiningMania_Scatter_zi.csb")
        util_spinePushBindNode(spineNode,"zi",scNodeCoins)
        spineNode.m_scatterCoins = scNodeCoins
    end

    if symbolNode.m_isLastSymbol == true then
        scatterCoins = self:getScatterCoins(self:getPosReelIdx(iRow, iCol))
        sScore = util_formatCoins(scatterCoins, 3)
    else
        -- 获取随机分数（本地配置）
        sScore = self:randomDownSymbolScore(symbolNode.p_symbolType)
    end
    if scNodeCoins then
        local textNode = scNodeCoins:findChild("m_lb_coins")
        textNode:setString(sScore)
    end
end

--[[
    获取scatter真实分数
]]
function CodeGameScreenMiningManiaMachine:getScatterCoins(id)
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local positionScore = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
    if next(positionScore) then
        for k, v in pairs(positionScore) do
            local curPos = tonumber(k)
            if curPos == id then
                return v
            end
        end
    end
    return 0
end

--[[
    随机bonus分数
]]
function CodeGameScreenMiningManiaMachine:randomDownSymbolScore(symbolType)
    local score = nil

    local curBet = globalData.slotRunData:getCurTotalBet()
    if symbolType == self.SYMBOL_SCORE_BONUS_2 then
        local mul = self.m_configData:getBnBonusPro2()
        local coins = mul * curBet
        score = util_formatCoins(coins, 3)
    elseif symbolType == self.SYMBOL_SCORE_BONUS_3 then
        score = self.m_configData:getBnBonusPro3()
    elseif symbolType == self.SYMBOL_SCORE_BONUS_4 then
        score = self.m_configData:getBnBonusPro4()
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local mul = 0.01 --固定的
        local coins = 0.01 * curBet
        score = util_formatCoins(coins, 3)
    else
        print("error-_symbolType", symbolType)
    end

    return score
end

function CodeGameScreenMiningManiaMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_BONUS_2 or
       symbolType == self.SYMBOL_SCORE_BONUS_3 or
       symbolType == self.SYMBOL_SCORE_BONUS_4 then
        return true
    end
    return false
end


--[[
    @desc: 遮罩相关
]]
function CodeGameScreenMiningManiaMachine:createSpinMask(_mainClass)
    --棋盘主类
    local tblMaskList = {}
    local mainClass = _mainClass or self
    
    for i=1, 5 do
        --单列卷轴尺寸
        local reel = mainClass:findChild("sp_reel_"..i-1)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()
        --棋盘尺寸
        local offsetSize = cc.size(4.5, 4.5)
        reelSize.width = reelSize.width * scaleX + offsetSize.width
        reelSize.height = reelSize.height * scaleY + offsetSize.height
        --遮罩尺寸和坐标
        local clipParent = mainClass.m_onceClipNode or mainClass.m_clipParent
        local panelOrder = 10000--REEL_SYMBOL_ORDER.REEL_ORDER_4--SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1

        local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
        panel:setOpacity(self.m_panelOpacity)
        panel:setContentSize(reelSize.width, reelSize.height)
        panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
        clipParent:addChild(panel, panelOrder)
        panel:setVisible(false)
        tblMaskList[i] = panel
    end

    return tblMaskList
end

function CodeGameScreenMiningManiaMachine:changeMaskVisible(_isVis, _reelCol, _isOpacity)
    if _isOpacity then
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(0)
    else
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(self.m_panelOpacity)
    end
end

function CodeGameScreenMiningManiaMachine:playMaskFadeAction(_isFadeTo, _fadeTime, _reelCol, _fun)
    local fadeTime = _fadeTime or 0.1
    local opacity = self.m_panelOpacity

    local act_fade = _isFadeTo and cc.FadeTo:create(fadeTime, opacity) or cc.FadeOut:create(fadeTime)
    if not _isFadeTo then
        self.m_panelUpList[_reelCol]:setOpacity(opacity)
    end
    self.m_panelUpList[_reelCol]:setVisible(true)
    self.m_panelUpList[_reelCol]:runAction(act_fade)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function()
        if _fun then
            _fun()
        end
        waitNode:removeFromParent()
    end, fadeTime)
end

-- 更新base收集分数
function CodeGameScreenMiningManiaMachine:refreshBaseCollectScore(_onEnter)
    local onEnter = _onEnter
    local curScore = 0
    -- 刷新房间收集分数
    if self.m_roomData and self.m_roomData.m_teamData and self.m_roomData.m_teamData.room then
        local extraData = self.m_roomData.m_teamData.room.extra
        if extraData and extraData.score then
            curScore = extraData.score
        end
    end

    local result = self.m_roomData:getSpotResult()
    -- 触发社交时用selfdata下分数
    if result and self.m_runSpinResultData.p_selfMakeData then
        local allScore = self.m_runSpinResultData.p_selfMakeData.allScore
        if allScore then
            curScore = allScore
        end
    end
    
    if not onEnter then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Collect)
    end

    -- 不存在0的情况；客户端写死，因为触发玩法必然不是0
    if curScore and curScore == 0 then
        curScore = 1
    end
    
    self.m_baseCollectBar:setCollectCoins(curScore, onEnter)
end

--[[
    显示基础轮盘
]]
function CodeGameScreenMiningManiaMachine:setBaseReelShow(_isShow, _playType)
    self.m_machine_bonus:setVisible(false)
    self.m_machine_carView:setVisible(false)
    
    if _isShow then
        self.m_bottomUI:setVisible(true)
        self:findChild("Node_base"):setVisible(true)
    else
        self:findChild("Node_base"):setVisible(false)
        self.m_bottomUI:setVisible(false)
        if _playType == 1 then
            self.m_machine_bonus:setVisible(true)
        elseif _playType == 2 then
            self.m_machine_carView:setVisible(true)
        end
    end
end

-- 改变背景和底条
function CodeGameScreenMiningManiaMachine:changeBgAndReelBg(_bgType, _isSwitch, _idleName)
    -- 1.base；2.freespin；3.社交1；4.社交2
    local bgType = _bgType
    local isSwitch = _isSwitch
    local idleName = _idleName
    if isSwitch then
        local switchName = "switch" .. bgType
        if bgType == 4 then
            bgType = 3
        end
        self.m_gameBg:runCsbAction(switchName, false, function()
            self.m_gameBg:runCsbAction(idleName, true)
        end)
    else
        for i=1, 3 do
            if i == bgType then
                self.m_gameBg:runCsbAction("idle"..i, true)
            end
        end
    end

    if bgType <= 2 then
        for i=1, 2 do
            if i == bgType then
                self.m_tblReelBg[i]:setVisible(true)
            else
                self.m_tblReelBg[i]:setVisible(false)
            end
        end
    end
end

function CodeGameScreenMiningManiaMachine:playhBottomLight(_endCoins, _playEffect)
    if _playEffect then
        self.m_bottomUI:playCoinWinEffectUI()
    end

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenMiningManiaMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenMiningManiaMachine:getCurBottomWinCoins()
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

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenMiningManiaMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount and _slotNode.p_symbolType ~= self.SYMBOL_SCORE_BONUS_1 then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] and self:getCurSymbolIsBuling(_slotNode) then
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
                    for i = 1, #speedActionTable do
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
                _slotNode:runAnim(symbolCfg[2], false, function()
                    self:symbolBulingEndCallBack(_slotNode)
                end)
            end
        end
    end
end

-- 落地提层特殊；重写条件
function CodeGameScreenMiningManiaMachine:getCurSymbolIsBuling(_slotNode)
    if _slotNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return true
    elseif _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and not self.m_isTriggerBonus then
        return true
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenMiningManiaMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    return false
                else
                    if self.m_isHaveSpecialBonus then
                        return true
                    else
                        return false
                    end
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenMiningManiaMachine:symbolBulingEndCallBack(_slotNode)
    if self:getCurSymbolIsBonus(_slotNode.p_symbolType) or _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
        _slotNode:runAnim("idleframe1", true)
    end
end

-- bonus的赢钱不计算总赢钱等待时间，只计算连线赢钱的等待
function CodeGameScreenMiningManiaMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local lastLineWinCoins = self:getClientWinCoins()
    local winRate = lastLineWinCoins / totalBet
    -- local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if lastLineWinCoins > 0 then
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 1.5
        elseif winRate > 3 and winRate <= 6 then
            showTime = 2.5
        elseif winRate > 6 then
            showTime = 3
        end
        if self:checkHasBigWin() then
            showTime = 1
        end
    end

    return showTime
end

function CodeGameScreenMiningManiaMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

function CodeGameScreenMiningManiaMachine:checkNotifyUpdateWinCoin(_isBonus)
    local winLines = self.m_reelResultLines

    if #winLines <= 0 and not _isBonus then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local lineWinCoins  = self:getClientWinCoins()
    -- self.m_iOnceSpinLastWin = lineWinCoins

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

function CodeGameScreenMiningManiaMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    local isHaveBonus = self:getCurIsHaveBonus()
    if #self.m_vecGetLineInfo == 0 and not isHaveBonus then
        notAdd = true
    end

    return notAdd
end

function CodeGameScreenMiningManiaMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        -- self.m_clipParent:addChild(reelEffectNode, -1,SYMBOL_NODE_TAG * 100)
        self.m_onceClipNode:addChild(reelEffectNode, 20010)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        -- if reelType == "ccui.Layout" then
        --     reelEffectNode:setLocalZOrder(0)
        -- end
        reelEffectNode:setPosition(cc.p(reel:getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenMiningManiaMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
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

    if winEffect ~= nil then
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
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end


function CodeGameScreenMiningManiaMachine:playScatterTipMusicEffect(_isFreeMore)
    if self.m_ScatterTipMusicPath ~= nil then
        globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        -- gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
    end
end

function CodeGameScreenMiningManiaMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenMiningManiaMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

return CodeGameScreenMiningManiaMachine






