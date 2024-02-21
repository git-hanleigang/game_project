local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenZeusVsHadesMachine = class("CodeGameScreenZeusVsHadesMachine", BaseNewReelMachine)

CodeGameScreenZeusVsHadesMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenZeusVsHadesMachine.m_norCSStatesTimes = 0 -- spin按钮可显示计数
CodeGameScreenZeusVsHadesMachine.m_norDownTimes = 0 -- 滚轮停止计数
CodeGameScreenZeusVsHadesMachine.m_maxReelNum = 2 -- 滚轮总数

CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_9_2 = 10
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_8_2 = 11
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_7_2 = 12
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_6_2 = 13
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_5_2 = 14
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_4_2 = 15
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_3_2 = 16
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_2_2 = 17
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_1_2 = 18
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_10_2 = 19
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_BONUS = 94

CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_RESPINNORMAL = 100
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_MULTIPLE = 101
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_COLLECT = 102
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_PLUNDER = 103

CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_RESPINNORMAL_2 = 200
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_MULTIPLE_2 = 201
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_COLLECT_2 = 202
CodeGameScreenZeusVsHadesMachine.SYMBOL_SCORE_PLUNDER_2 = 203

CodeGameScreenZeusVsHadesMachine.SYMBOL_INVALID = 96
CodeGameScreenZeusVsHadesMachine.BONUSCOLLECT_CHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
 --左右互相变wild--bonus收集
-- CodeGameScreenZeusVsHadesMachine.BONUSCOLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2--bonus收集
-- CodeGameScreenZeusVsHadesMachine.CHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1--左右互相变wild

CodeGameScreenZeusVsHadesMachine.RECONNECTION_BONUSOVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
 --重连领取bonus玩法赢钱
CodeGameScreenZeusVsHadesMachine.BONUSOVER_SHOWCHOOSEVIEW_EFFECT = GameEffect.EFFECT_EPICWIN + 1
 --bonus玩法结束弹出选择阵营弹框

CodeGameScreenZeusVsHadesMachine.YEAH_MULTIPLE = 50

-- 构造函数
function CodeGameScreenZeusVsHadesMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
    self.m_isReconnection = false
     --是否重连
    self.m_spinRestMusicBG = true

    self.m_respinReelRowNum = 4
     --respin轮盘行数
    self.m_respinReelColumnNum = 10
     --respin轮盘列数
    self.m_respinIndex = 0
     --当前respin进行到的次数
    self.m_zeusSpinIndex = nil
     --当前宙斯触发的respin进行到的次数

    self.m_clipNode = {}
     --存储提高层级的图标

    self.m_tipIsClosing = false
     --tip弹框是不是正在关闭
    self.m_isShowOutGame = false
     --是否弹出超时退出框

    self.m_replaceSignal = nil
     --假滚96号替换成的id
    self.m_thisRoundIsCanPlayWinSound = true
     --本轮是否还能播赢钱音效
    --init
    self:initGame()
end

function CodeGameScreenZeusVsHadesMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ZeusVsHadesConfig.csv", "LevelZeusVsHadesConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenZeusVsHadesMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ZeusVsHades"
end
--小块
function CodeGameScreenZeusVsHadesMachine:getBaseReelGridNode()
    return "CodeZeusVsHadesSrc.ZeusVsHadesSlotNode"
end
--适配
function CodeGameScreenZeusVsHadesMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1
    local disignWidth = 1170
     --设计轮盘有效宽度
    local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
    local wScale = winSize.width / disignWidth
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale


    local mainScale = self.m_machineRootScale
    if display.width / display.height <= 920/768 then
        mainScale = mainScale * 0.90
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width / display.height <= 1152/768 then
        mainScale = mainScale * 0.90
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 5)
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )
    elseif display.width / display.height <= 1228/768 then
        mainScale = mainScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() )   
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale

end
function CodeGameScreenZeusVsHadesMachine:initUI()
    self.m_reelRunSound = "ZeusVsHadesSounds/music_ZeusVsHades_quick_run.mp3"
     --快滚音效
    --添加副轮盘
    self:initMiniReel()
    --bonus计次条
    self.m_bonusNumBar = util_createAnimation("ZeusVsHades_bonusNumbar.csb")
    self:findChild("Node_bonusNumBar"):addChild(self.m_bonusNumBar)
    self.m_bonusNumBar:setVisible(false)
    --添加tip框
    self.m_tip = util_createAnimation("ZeusVsHades_bonusshuoming.csb")
    self:findChild("Node_bonusshuoming"):addChild(self.m_tip)
    self.m_tip:setVisible(false)
    self:addClick(self:findChild("touchPanel"))
    --添加respin触发过场
    self.m_respinGuochang = util_createAnimation("ZeusVsHAdes_zi_kaichang1.csb")
    self:findChild("Node_zi_kaichang1"):addChild(self.m_respinGuochang)
    self.m_respinGuochang.m_zeusAni = util_spineCreate("ZeusVsHades_Zeusidle", true, true)
    self.m_respinGuochang:findChild("Node_Zeus"):addChild(self.m_respinGuochang.m_zeusAni)
    self.m_respinGuochang.m_hadesAni = util_spineCreate("ZeusVsHAdes_HADES_shengli", true, true)
    self.m_respinGuochang:findChild("Node_Hades"):addChild(self.m_respinGuochang.m_hadesAni)
    --添加人物
    self.m_zeus = util_spineCreate("ZeusVsHades_Zeusidle", true, true)
    self:findChild("Node_Zeus"):addChild(self.m_zeus)
    self.m_hades = util_spineCreate("ZeusVsHAdes_duijue_HADES", true, true)
    self:findChild("Node_Hades"):addChild(self.m_hades)
    self.m_hadesWin = util_spineCreate("ZeusVsHAdes_HADES_shengli", true, true)
    self:findChild("Node_Hades"):addChild(self.m_hadesWin)
    self.m_zeus:setVisible(false)
    self.m_hades:setVisible(false)
    self.m_hadesWin:setVisible(false)
    --添加过场上边的对话框
    self.m_respinGuochang.m_dialog = util_createAnimation("ZeusVsHAdes_zi_kaichang2.csb")
    self.m_respinGuochang:findChild("Node_kaichang2"):addChild(self.m_respinGuochang.m_dialog)
    self.m_respinGuochang:setVisible(false)
    --添加respin下雷火特效框
    self.m_respinLeiKuang = util_createAnimation("ZeusVsHAdes_SDkuang.csb")
    self:findChild("Node_kuang"):addChild(self.m_respinLeiKuang)
    self.m_respinLeiKuang:setVisible(false)
    self.m_respinHuoKuang = util_createAnimation("ZeusVsHAdes_HuoKuang.csb")
    self:findChild("Node_kuang"):addChild(self.m_respinHuoKuang)
    self.m_respinHuoKuang:setVisible(false)

    --添加respin下收集的箭头
    self.m_collectLeftJiantouTab = {}
    for i = 1, 7 do
        local jiantou = util_createAnimation("ZeusVsHAdes_shoujijiantoulan.csb")
        self:findChild("Node_zuotiao_" .. i):addChild(jiantou)
        table.insert(self.m_collectLeftJiantouTab, jiantou)
        jiantou:setVisible(false)
        jiantou:playAction("idleframe")
    end
    self.m_collectRightJiantouTab = {}
    for i = 1, 5 do
        local jiantou = util_createAnimation("ZeusVsHAdes_shoujijiantouhong.csb")
        self:findChild("Node_youtiao_" .. i):addChild(jiantou)
        table.insert(self.m_collectRightJiantouTab, jiantou)
        jiantou:setVisible(false)
        jiantou:playAction("idleframe")
    end
    --添加收集箭头处特效
    self.m_leftJiantouEff = util_createAnimation("ZeusVsHades_NLSDKuang.csb")
    self:findChild("Node_jiantouzuo"):addChild(self.m_leftJiantouEff)
    self.m_leftJiantouEff:setVisible(false)
    self.m_rightJiantouEff = util_createAnimation("ZeusVsHades_NLHuokuang.csb")
    self:findChild("Node_jiantouyou"):addChild(self.m_rightJiantouEff)
    self.m_rightJiantouEff:setVisible(false)
    --添加respin 增加次数 最后一次 结束动画
    self.m_respinNumTriger = util_createAnimation("ZeusVsHAdes_zi_zhong.csb")
    self:findChild("Node_zi_zhong"):addChild(self.m_respinNumTriger)
    self.m_respinNumTriger:setVisible(false)
    self.m_respinNumTriger:findChild("addNum"):setVisible(false)
    self.m_respinNumTriger:findChild("finalRound"):setVisible(false)
    self.m_respinNumTriger:findChild("bonusCompleted"):setVisible(false)
    --添加respin收集框出的收集动效
    self.m_zeusCollectEff = util_createAnimation("ZeusVsHades_Bonus_jiesuan2.csb")
    self:findChild("Node_jiesuanbd2"):addChild(self.m_zeusCollectEff)
    self.m_zeusCollectEff:setVisible(false)
    self.m_hadesCollectEff = util_createAnimation("ZeusVsHades_Bonus_jiesuan1.csb")
    self:findChild("Node_jiesuanbd1"):addChild(self.m_hadesCollectEff)
    self.m_hadesCollectEff:setVisible(false)

    --宙斯方获胜 结算动画背景
    self.m_zeusWinBg = util_createAnimation("ZeusVsHAdes_zi_ZEUS_1.csb")
    self:findChild("Node_zi_ZEUS_1"):addChild(self.m_zeusWinBg)
    self.m_zeusWinBg:setVisible(false)
    --宙斯方获胜 人物列表
    self.m_zeusWinPlayerList = util_createAnimation("ZeusVsHades_kuanglan2.csb")
    self:findChild("Node_zi_ZEUS_1"):addChild(self.m_zeusWinPlayerList)
    self.m_zeusWinPlayerList:setVisible(false)
    self:addClick(self.m_zeusWinPlayerList:findChild("zeus_collectButton"))
    self.m_zeusWinPlayerList:findChild("zeus_collectButton"):setTouchEnabled(false)
    --哈迪斯方获胜 结算动画背景
    self.m_hadesWinBg = util_createAnimation("ZeusVsHAdes_zi_HADES_1.csb")
    self:findChild("Node_zi_HADES_1"):addChild(self.m_hadesWinBg)
    self.m_hadesWinBg:setVisible(false)
    --哈迪斯方获胜 人物列表
    self.m_hadesWinPlayerList = util_createAnimation("ZeusVsHades_kuanghong2.csb")
    self:findChild("Node_zi_HADES_1"):addChild(self.m_hadesWinPlayerList)
    self.m_hadesWinPlayerList:setVisible(false)
    self:addClick(self.m_hadesWinPlayerList:findChild("hades_collectButton"))
    self.m_hadesWinPlayerList:findChild("hades_collectButton"):setTouchEnabled(false)

    --添加房间玩家列表
    self.m_roomPlayerList = util_createView("CodeZeusVsHadesSrc.ZeusVsHadesPlayerLisitView", {machine = self})
    self:findChild("Node_playerList"):addChild(self.m_roomPlayerList)

    self:runCsbAction("idleframe")
    self.m_gameBg:runCsbAction("idleframe", true)
end

--[[
    暂停轮盘
]]
function CodeGameScreenZeusVsHadesMachine:pauseMachine()
    CodeGameScreenZeusVsHadesMachine.super.pauseMachine(self)
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end
--[[
    退出到大厅
]]
function CodeGameScreenZeusVsHadesMachine:showOutGame()
    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeZeusVsHadesSrc.ZeusVsHadesGameOut")
    -- if globalData.slotRunData.machineData.p_portraitFlag then
    --     view.getRotateBackScaleFlag = function()
    --         return false
    --     end
    -- end
    gLobalViewManager:showUI(view)
    self.m_roomPlayerList:changeStatus(false)
    self.m_roomPlayerList:sendLogOutRoom()
end
--[[
    恢复轮盘
]]
function CodeGameScreenZeusVsHadesMachine:resumeMachine()
    CodeGameScreenZeusVsHadesMachine.super.resumeMachine(self)
    --重新刷新房间消息
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_resumeUpdate")
end
--创建副轮盘
function CodeGameScreenZeusVsHadesMachine:initMiniReel()
    local className = "CodeZeusVsHadesSrc.ZeusVsHadesMiniMachine"
    local reelData = {}
    reelData.index = 1
    reelData.parent = self
    reelData.maxReelIndex = 1
    self.m_miniReel = util_createView(className, reelData)
    self:findChild("Node_baseyou_sp_reel"):addChild(self.m_miniReel)

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniReel.m_touchSpinLayer)
    end
end

function CodeGameScreenZeusVsHadesMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("ZeusVsHadesSounds/music_ZeusVsHades_enter.mp3")
            -- scheduler.performWithDelayGlobal(function ()
            --     self.m_enterGameMusicIsComplete = true
            --     self:resetMusicBg()
            --     if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            --         self:setMinMusicBGVolume()
            --     end
            -- end,2.5,self:getModuleName())
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenZeusVsHadesMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)
    self:addObservers()

    self:setCollectCoinNum(false)
    if self.m_isReconnection == false then
        self:showChooseTeamView()
    end
    self.m_roomPlayerList:hideAllNoPlayerSpr()
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_startLogOutTime")
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeUpdateState", {1})
end

function CodeGameScreenZeusVsHadesMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_thisRoundIsCanPlayWinSound == false then
                return
            end
            self.m_thisRoundIsCanPlayWinSound = false

            if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
                self.m_roomPlayerList:showSelfBigWinAni("EPIC_WIN")
            elseif self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) then
                self.m_roomPlayerList:showSelfBigWinAni("MAGE_WIN")
            elseif self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
                self.m_roomPlayerList:showSelfBigWinAni("BIG_WIN")
            end

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
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = "ZeusVsHadesSounds/music_ZeusVsHades_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
            -- self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setCollectCoinNum(false)
        end,
        "CodeGameScreenZeusVsHadesMachine_setCollectCoinNum"
    )
end

function CodeGameScreenZeusVsHadesMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)
    self:removeObservers()
    self:removeChangeReelDataHandler()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

--显示tips
function CodeGameScreenZeusVsHadesMachine:showTip()
    if self.m_tip:isVisible() == false then
        self.m_tip:setVisible(true)
        self.m_tip:playAction("show")
        if self.m_tip.m_delayNode == nil then
            local delayNode = cc.Node:create()
            self.m_tip:addChild(delayNode)
            self.m_tip.m_delayNode = delayNode
        end
        performWithDelay(
            self.m_tip.m_delayNode,
            function()
                self:hideTip()
            end,
            5
        )
    end
end
--隐藏tips
function CodeGameScreenZeusVsHadesMachine:hideTip()
    if self.m_tip:isVisible() == true and self.m_tipIsClosing == false then
        self.m_tipIsClosing = true
        if self.m_tip.m_delayNode ~= nil then
            self.m_tip.m_delayNode:removeFromParent()
            self.m_tip.m_delayNode = nil
        end
        self.m_tip:playAction(
            "over",
            false,
            function()
                self.m_tipIsClosing = false
                self.m_tip:setVisible(false)
            end
        )
    end
end
function CodeGameScreenZeusVsHadesMachine:clickFunc(sender)
    local name = sender:getName()
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_resetLogoutTime")
    if self.m_bottomUI.m_btn_add:isTouchEnabled() == true then
        if name == "touchPanel" then
            self:hideTip()
        elseif name == "tip_button" then
            --弹出说明框
            self:showTip()
        elseif name == "changeRoom_button" then
            self:showChooseTeamView()
        end
    end
    if name == "zeus_collectButton" then
        sender:setTouchEnabled(false)
        self:removeRespinView()
        self:runCsbAction(
            "over2",
            false,
            function()
                self:runCsbAction("over", false)
            end
        )
        self.m_zeusWinBg:playAction(
            "over",
            false,
            function()
                self.m_zeusWinBg:setVisible(false)
            end
        )
        self.m_zeus:setAnimation(0, "over", false)
        util_spineEndCallFunc(
            self.m_zeus,
            "over",
            function()
                self.m_zeus:setVisible(false)
            end
        )
        self.m_zeusWinPlayerList:playAction(
            "over",
            false,
            function()
                self.m_zeusWinPlayerList:setVisible(false)
                self:reSpinOverchangeUI()
            end
        )
    elseif name == "hades_collectButton" then
        sender:setTouchEnabled(false)
        self:removeRespinView()
        self:runCsbAction(
            "over2",
            false,
            function()
                self:runCsbAction("over", false)
            end
        )
        self.m_hadesWinBg:playAction(
            "over",
            false,
            function()
                self.m_hadesWinBg:setVisible(false)
            end
        )
        self.m_hadesWin:setAnimation(0, "over", false)
        util_spineEndCallFunc(
            self.m_hadesWin,
            "over",
            function()
                self.m_hadesWin:setVisible(false)
            end
        )
        self.m_hadesWinPlayerList:playAction(
            "over",
            false,
            function()
                self.m_hadesWinPlayerList:setVisible(false)
                self:reSpinOverchangeUI()
            end
        )
    end
end

-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenZeusVsHadesMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_ZeusVsHades_10"
    elseif symbolType == self.SYMBOL_SCORE_9_2 then
        return "Socre_ZeusVsHAdes_9_2"
    elseif symbolType == self.SYMBOL_SCORE_8_2 then
        return "Socre_ZeusVsHades_8_2"
    elseif symbolType == self.SYMBOL_SCORE_7_2 then
        return "Socre_ZeusVsHades_7_2"
    elseif symbolType == self.SYMBOL_SCORE_6_2 then
        return "Socre_ZeusVsHades_6_2"
    elseif symbolType == self.SYMBOL_SCORE_5_2 then
        return "Socre_ZeusVsHades_5_2"
    elseif symbolType == self.SYMBOL_SCORE_4_2 then
        return "Socre_ZeusVsHades_4_2"
    elseif symbolType == self.SYMBOL_SCORE_3_2 then
        return "Socre_ZeusVsHades_3_2"
    elseif symbolType == self.SYMBOL_SCORE_2_2 then
        return "Socre_ZeusVsHades_2_2"
    elseif symbolType == self.SYMBOL_SCORE_1_2 then
        return "Socre_ZeusVsHades_1_2"
    elseif symbolType == self.SYMBOL_SCORE_10_2 then
        return "Socre_ZeusVsHades_10_2"
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_ZeusVsHAdes_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_RESPINNORMAL then
        return "Socre_ZeusVsHades_respinnormal"
    elseif symbolType == self.SYMBOL_SCORE_MULTIPLE then
        return "Socre_ZeusVsHAdes_zuanlan"
    elseif symbolType == self.SYMBOL_SCORE_COLLECT then
        return "Socre_ZeusVsHAdes_jiantoulan"
    elseif symbolType == self.SYMBOL_SCORE_PLUNDER then
        return "Socre_ZeusVsHAdes_plunder"
    elseif symbolType == self.SYMBOL_SCORE_RESPINNORMAL_2 then
        return "Socre_ZeusVsHades_respinnormal2"
    elseif symbolType == self.SYMBOL_SCORE_MULTIPLE_2 then
        return "Socre_ZeusVsHAdes_zuanhong"
    elseif symbolType == self.SYMBOL_SCORE_COLLECT_2 then
        return "Socre_ZeusVsHAdes_jiantouhong"
    elseif symbolType == self.SYMBOL_SCORE_PLUNDER_2 then
        return "Socre_ZeusVsHAdes_plunder2"
    end
    return nil
end
--判断是否是抢地盘图标
function CodeGameScreenZeusVsHadesMachine:isPlunderSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_PLUNDER or symbolType == self.SYMBOL_SCORE_PLUNDER_2 then
        return true
    end
    return false
end
--判断是否是收集图标
function CodeGameScreenZeusVsHadesMachine:isCollectSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_COLLECT or symbolType == self.SYMBOL_SCORE_COLLECT_2 then
        return true
    end
    return false
end
-- 断线重连
function CodeGameScreenZeusVsHadesMachine:MachineRule_initGame()
    self.m_isReconnection = true
    --是否需要领取bonus奖励
    local winSpots = self.m_roomPlayerList.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local coins = 0
        for key, winInfo in pairs(winSpots) do
            if winInfo.udid == globalData.userRunData.userUdid then
                coins = coins + winInfo.coins
            end
        end

        if coins > 0 then
            -- local view = self:showReSpinOver(coins,function()
            --     local gameName = self:getNetWorkModuleName()
            --     local index = -1
            --     gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
            --         function()
            --             globalData.slotRunData.lastWinCoin = 0
            --             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, true, true})
            --             self:showChooseTeamView()
            --         end,
            --         function(errorCode, errorData)
            --         end)
            -- end)
            -- local node = view:findChild("m_lb_coins")
            -- view:updateLabelSize({label = node,sx = 1,sy = 1},688)
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.RECONNECTION_BONUSOVER_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.RECONNECTION_BONUSOVER_EFFECT
            self.m_miniReel:MainReel_addSelfEffect(selfEffect)
            self.m_reconnectionBonusWinCoin = coins

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.BONUSOVER_SHOWCHOOSEVIEW_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUSOVER_SHOWCHOOSEVIEW_EFFECT
            self.m_miniReel:MainReel_addSelfEffect(selfEffect)
        else
            self:showChooseTeamView()
        end
    else
        self:showChooseTeamView()
    end
end

function CodeGameScreenZeusVsHadesMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if
        symbolType == self.SYMBOL_SCORE_BONUS or symbolType == self.SYMBOL_SCORE_MULTIPLE or symbolType == self.SYMBOL_SCORE_MULTIPLE_2 or symbolType == self.SYMBOL_SCORE_PLUNDER or
            symbolType == self.SYMBOL_SCORE_PLUNDER_2
     then
        self:setSpecialNodeScore(node)
    end
end
-- 根据行 列转化为位置(行数为从下往上数，位置是从左上开始数)
function CodeGameScreenZeusVsHadesMachine:getPosByRowAndCol(row, col, iReelRowNum, iReelColNum)
    assert(row, " !! row is nil !! ")
    assert(col, " !! col is nil !! ")
    local cols_nums = iReelColNum -- 滚轴的数量(列数)
    local rows_nums = iReelRowNum -- 行的数量
    local pos
    pos = (col - 1) + (rows_nums - row) * cols_nums
    return pos
end
function CodeGameScreenZeusVsHadesMachine:getRowAndColByPos(posData, iReelRowNum, iReelColNum)
    local cols_nums = iReelColNum -- 滚轴的数量(列数)
    local rows_nums = iReelRowNum -- 行的数量
    if cols_nums == nil then
        cols_nums = self.m_iReelColumnNum
    end
    if rows_nums == nil then
        rows_nums = self.m_iReelRowNum
    end

    local rowIndex = rows_nums - math.floor(posData / cols_nums)
    local colIndex = posData % cols_nums + 1

    return {iX = rowIndex, iY = colIndex}
end
-- 给一些信号块上的数字进行赋值
function CodeGameScreenZeusVsHadesMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        if symbolNode.m_numLabel == nil then
            symbolNode.m_numLabel = util_createAnimation("Socre_ZeusVsHades_Bonusshuzi.csb")
            symbolNode:addChild(symbolNode.m_numLabel, 2)
        end
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.positionScores[1] then
                local pos = self:getPosByRowAndCol(iRow, iCol, self.m_iReelRowNum, self.m_iReelColumnNum)
                local coinNum = self.m_runSpinResultData.p_selfMakeData.positionScores[1]["" .. pos]
                if coinNum then
                    symbolNode.m_numLabel:findChild("m_lb_coins"):setString(util_formatCoins(coinNum, 3))
                    self:updateLabelSize({label = symbolNode.m_numLabel:findChild("m_lb_coins"), sx = 0.6, sy = 0.6}, 132)
                end
            end
        else
            local multiple = self.m_configData:getFixSymbolPro()
            local lineBet = globalData.slotRunData:getCurTotalBet()
            symbolNode.m_numLabel:findChild("m_lb_coins"):setString(util_formatCoins(multiple * lineBet, 3))
            self:updateLabelSize({label = symbolNode.m_numLabel:findChild("m_lb_coins"), sx = 0.6, sy = 0.6}, 132)
        end
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_MULTIPLE or symbolNode.p_symbolType == self.SYMBOL_SCORE_MULTIPLE_2 then
        if iRow ~= nil and iRow <= self.m_respinReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local pos = self:getPosByRowAndCol(iRow, iCol, self.m_respinReelRowNum, self.m_respinReelColumnNum)
            local multiple = 1
            if self.m_zeusSpinIndex ~= nil then
                multiple = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex].store[pos + 1]
            else
                multiple = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].store[pos + 1]
            end
            if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redMultiplePositions then
                local multipePosTab = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redMultiplePositions
                for i, multipePos in ipairs(multipePosTab) do
                    if multipePos == pos then
                        multiple = multiple / 2
                        break
                    end
                end
            end
            symbolNode:getCcbProperty("m_lb_beishu"):setString("X" .. multiple)
        else
            local multiple = self.m_configData:getRespinMultiple()
            symbolNode:getCcbProperty("m_lb_beishu"):setString("X" .. multiple)
        end
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_PLUNDER or symbolNode.p_symbolType == self.SYMBOL_SCORE_PLUNDER_2 then
        if iRow ~= nil and iRow <= self.m_respinReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local pos = self:getPosByRowAndCol(iRow, iCol, self.m_respinReelRowNum, self.m_respinReelColumnNum)
            local resultsData = nil
            if self.m_zeusSpinIndex ~= nil then
                resultsData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex]
            else
                resultsData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex]
            end

            if resultsData.blueReplace["" .. pos] ~= nil then
                symbolNode:getCcbProperty("m_lb_num"):setString(#resultsData.blueReplace["" .. pos])
            elseif resultsData.redReplace["" .. pos] ~= nil then
                symbolNode:getCcbProperty("m_lb_num"):setString(#resultsData.redReplace["" .. pos])
            end
        else
            local num = self.m_configData:getRespinPlunder()
            symbolNode:getCcbProperty("m_lb_num"):setString(num)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenZeusVsHadesMachine:slotOneReelDown(reelCol)
    CodeGameScreenZeusVsHadesMachine.super.slotOneReelDown(self, reelCol)
    local sound = {scatter = 0, bonus = 0}
    for row = 1, self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
        if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
            self:setSymbolToClip(symbolNode)
            if symbolNode.m_numLabel ~= nil then
                symbolNode.m_numLabel:playAction("buling")
            end
            symbolNode:runAnim(
                "buling",
                false,
                function()
                    if symbolNode.p_symbolType ~= nil then
                        symbolNode:runAnim("idleframe", true)
                    end
                end
            )
            sound.bonus = 1
        end
        local symbolType = self.m_miniReel.m_stcValidSymbolMatrix[row][reelCol]
        -- local symbolNode1 = self.m_miniReel:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)--快停时还没停拿的图标不对
        if symbolType == self.SYMBOL_SCORE_BONUS then
            sound.bonus = 1
        end
    end

    local soundPath = nil

    if sound.bonus == 1 then
        soundPath = "ZeusVsHadesSounds/music_ZeusVsHades_bonusBuling.mp3"
    end

    if soundPath then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds(reelCol, soundPath)
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end

--将图标提到clipParent层
function CodeGameScreenZeusVsHadesMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)

    if slotNode.m_numLabel ~= nil then
        slotNode.m_numLabel.m_csbAct:retain()
    end

    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)
    self.m_clipNode[#self.m_clipNode + 1] = slotNode

    if slotNode.m_numLabel ~= nil then
        slotNode.m_numLabel.m_csbNode:runAction(slotNode.m_numLabel.m_csbAct)
        slotNode.m_numLabel.m_csbAct:release()
    end

    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end
--获取信号块层级
function CodeGameScreenZeusVsHadesMachine:getBounsScatterDataZorder(symbolType)
    local order = self.super.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    return order
end
--将某一个图标恢复到轮盘层
function CodeGameScreenZeusVsHadesMachine:setOneSymbolToReel(symbolNode)
    for i, slotNode in ipairs(self.m_clipNode) do
        if slotNode == symbolNode then
            local preParent = slotNode.m_preParent
            if preParent ~= nil then
                slotNode.p_layerTag = slotNode.m_preLayerTag

                local nZOrder = slotNode.m_showOrder
                nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder
                util_changeNodeParent(preParent, slotNode, nZOrder)
                slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
                slotNode:runIdleAnim()
            end
            table.remove(self.m_clipNode, i)
            break
        end
    end
end
--将图标恢复到轮盘层
function CodeGameScreenZeusVsHadesMachine:setSymbolToReel()
    for i, slotNode in ipairs(self.m_clipNode) do
        local preParent = slotNode.m_preParent
        if preParent ~= nil then
            slotNode.p_layerTag = slotNode.m_preLayerTag

            local nZOrder = slotNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder
            util_changeNodeParent(preParent, slotNode, nZOrder)
            slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
            slotNode:runIdleAnim()
        end
    end
    self.m_clipNode = {}
end
--判断是不是自己触发的bonus玩法
function CodeGameScreenZeusVsHadesMachine:isMeTriggerBonus()
    local roomData = self.m_roomPlayerList:getRoomData()
    local triggerPlayer = roomData.result.data.triggerPlayer
    local isMe = triggerPlayer.udid == globalData.userRunData.userUdid
    if triggerPlayer.nickName == "SYSTEM" then
        return false
     --系统触发的，不是自己
    end
    return isMe
end
--[[
    显示bonus开始弹版
]]
function CodeGameScreenZeusVsHadesMachine:showRespinStartView(func)
    local roomData = self.m_roomPlayerList:getRoomData()
    local triggerPlayer = roomData.result.data.triggerPlayer
    local isMe = triggerPlayer.udid == globalData.userRunData.userUdid
    local isSystem = triggerPlayer.nickName == "SYSTEM"

    local view = util_createAnimation("ZeusVsHades/BonusStart.csb")

    local aniName = isMe and "auto" or "actionframe"

    view:playAction(
        aniName,
        false,
        function()
            view:removeFromParent(true)
            if func then
                func()
            end
        end
    )

    local lbl_name = view:findChild("lb_playerName")
    if isSystem then
        lbl_name:setString("Mr. Cash")
    else
        if isMe then
            lbl_name:setString("YOU")
        else
            lbl_name:setString(triggerPlayer.nickName)
        end
    end

    --刷新头像
    local head = view:findChild("touxiang")
    local frameId = isMe and globalData.userRunData.avatarFrameId or triggerPlayer.frame
    local headSize = head:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(triggerPlayer.facebookId, triggerPlayer.head, frameId, nil, headSize)
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    view:findChild("ZeusVsHades_kuanglan_4"):setVisible(false)
    view:findChild("ZeusVsHades_kuanghong_3"):setVisible(false)
    view:findChild("ZeusVsHades_kuanglv_1"):setVisible(frameId == nil or frameId == "")
    
    local headRoot = head:getParent()
    local headFrameNode = headRoot:getChildByName("headFrameNode")
    if not headFrameNode then
        headFrameNode = cc.Node:create()
        headRoot:addChild(headFrameNode, 10)
        headFrameNode:setName("headFrameNode")
        headFrameNode:setPosition(head:getPosition())
        headFrameNode:setLocalZOrder(10)
        headFrameNode:setScale(head:getScale())
    else
        headFrameNode:removeAllChildren(true)
    end
    util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)

    --添加图标
    local tubiao = util_createAnimation("ZeusVsHades/BonusStart1.csb")
    view:findChild("Node_tubiao"):addChild(tubiao)
    if isMe then
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinSelfTriggerShowStartView.mp3")
        tubiao:playAction("actionframe2", false)
    else
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinNoSelfTriggerShowStartView.mp3")
        local chairId = nil
        for i, setsInfo in ipairs(roomData.result.data.sets) do
            if setsInfo.udid == triggerPlayer.udid then
                chairId = setsInfo.chairId
                break
            end
        end
        local worldPos = self.m_roomPlayerList.m_playerItems[chairId + 1]:getParent():convertToWorldSpace(cc.p(self.m_roomPlayerList.m_playerItems[chairId + 1]:getPosition()))
        local pos = tubiao:getParent():convertToNodeSpace(worldPos)
        tubiao:setPosition(pos)
        if chairId < 4 then
            tubiao:findChild("1"):setVisible(false)
        else
            tubiao:findChild("2"):setVisible(false)
        end
        tubiao:playAction(
            "actionframe1",
            false,
            function()
                tubiao:playAction("actionframe2", false)
                local moveto = cc.MoveTo:create(30 / 60, cc.p(0, 0))
                tubiao:runAction(moveto)
            end
        )
    end

    gLobalViewManager:showUI(view)
end

function CodeGameScreenZeusVsHadesMachine:getRespinView()
    return "CodeZeusVsHadesSrc.ZeusVsHadesRespinView"
end

function CodeGameScreenZeusVsHadesMachine:getRespinNode()
    return "CodeZeusVsHadesSrc.ZeusVsHadesRespinNode"
end

function CodeGameScreenZeusVsHadesMachine:getRespinRandomTypes()
    local symbolList = {
        self.SYMBOL_SCORE_RESPINNORMAL,
        self.SYMBOL_SCORE_COLLECT,
        self.SYMBOL_SCORE_PLUNDER,
        self.SYMBOL_SCORE_RESPINNORMAL_2,
        self.SYMBOL_SCORE_COLLECT_2,
        self.SYMBOL_SCORE_PLUNDER_2
    }
    return symbolList
end

function CodeGameScreenZeusVsHadesMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_SCORE_MULTIPLE, runEndAnimaName = "buling", bRandom = true, weight = 1},
        {type = self.SYMBOL_SCORE_MULTIPLE_2, runEndAnimaName = "buling", bRandom = true, weight = 1}
    }
    return symbolList
end
--[[
    检测是否触发bonus
]]
function CodeGameScreenZeusVsHadesMachine:checkTriggerBonus()
    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k, gameEffect in pairs(self.m_gameEffects) do
        if gameEffect.p_effectType == GameEffect.EFFECT_RESPIN then
            return true
        end
    end

    --有玩家触发Bonus
    local roomData = self.m_roomPlayerList:getRoomData()
    if roomData.result then
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeUpdateState", {0})
        self:addBonusEffect()
        return true
    end

    return false
end
--[[
    添加Bonus玩法  把bonus当respin做了
]]
function CodeGameScreenZeusVsHadesMachine:addBonusEffect()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_RESPIN
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    self.m_miniReel:MainReel_addSelfEffect(bonusGameEffect)

    gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self.m_roomPlayerList:changeStatus(false)
    self.m_roomPlayerList:sendLogOutRoom()
    self.m_roomPlayerList:showBonusStartEff()
end
---
-- 触发respin 玩法
--
function CodeGameScreenZeusVsHadesMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self.m_miniReel:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self.m_miniReel:clearWinLineEffect()

        self:resetMaskLayerNodes()
        self.m_miniReel:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end

        local children = self.m_miniReel.m_lineSlotNodes
        for i = 1, #children do
            local cloumnIndex = children[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_miniReel.m_clipParent:convertToWorldSpace(cc.p(children[i]:getPosition()))
                local pos = self.m_miniReel.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self.m_miniReel:changeBaseParent(children[i])
                children[i]:setPosition(pos)
                self.m_miniReel.m_slotParents[cloumnIndex].slotParent:addChild(children[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end
--开始respin玩法
function CodeGameScreenZeusVsHadesMachine:showRespinView()
    --播放图标触发动画
    local delayTime = 0
    if self:isMeTriggerBonus() then
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinTrigger.mp3")
        for col = 1, self.m_iReelColumnNum do
            for row = 1, self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(col, row)
                if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    symbolNode:runAnim("actionframe", false)
                    if symbolNode.m_numLabel then
                        symbolNode.m_numLabel:playAction("actionframe")
                    end
                end
                if symbolNode.m_bonusNode ~= nil then
                    self:setSymbolToClip(symbolNode)
                    symbolNode.m_bonusNode:setLocalZOrder(1)
                    symbolNode.m_bonusNode:setVisible(true)
                    if symbolNode.m_numLabel then
                        symbolNode.m_numLabel:setLocalZOrder(2)
                        symbolNode.m_numLabel:setVisible(true)
                        symbolNode.m_numLabel:playAction("actionframe")
                    end
                    util_spinePlay(symbolNode.m_bonusNode, "actionframe", false)
                end
            end
        end
        for col = 1, self.m_miniReel.m_iReelColumnNum do
            for row = 1, self.m_miniReel.m_iReelRowNum do
                local symbolNode = self.m_miniReel:getFixSymbol(col, row)
                if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    symbolNode:runAnim("actionframe", false)
                    if symbolNode.m_numLabel then
                        symbolNode.m_numLabel:playAction("actionframe")
                    end
                end
                if symbolNode.m_bonusNode ~= nil then
                    self.m_miniReel:setSymbolToClip(symbolNode)
                    symbolNode.m_bonusNode:setLocalZOrder(1)
                    symbolNode.m_bonusNode:setVisible(true)
                    if symbolNode.m_numLabel then
                        symbolNode.m_numLabel:setLocalZOrder(2)
                        symbolNode.m_numLabel:setVisible(true)
                        symbolNode.m_numLabel:playAction("actionframe")
                    end
                    util_spinePlay(symbolNode.m_bonusNode, "actionframe", false)
                end
            end
        end
        delayTime = 2.5
    end

    performWithDelay(
        self,
        function()
            self:setSymbolToReel()
            self.m_miniReel:setSymbolToReel()
            self:findChild("tip_button"):setEnabled(false)
            self.m_roomPlayerList:hideAllNoPlayerSpr()
            self:showRespinStartView(
                function()
                    self:clearWinLineEffect()
                    self.m_miniReel:clearWinLineEffect()
                    self.m_bottomUI:checkClearWinLabel()
                    self:removeSoundHandler()

                    --可随机的普通信息
                    local randomTypes = self:getRespinRandomTypes()
                    --可随机的特殊信号
                    local endTypes = self:getRespinLockTypes()
                    --构造盘面数据
                    self:triggerReSpinCallFun(endTypes, randomTypes)

                    self:showEnterRespinGuochang(
                        function()
                            self:changeReSpinBgMusic()
                            self:runNextReSpinReel()
                        end
                    )
                end
            )
        end,
        delayTime
    )
end

--显示进入bonus过场动画
function CodeGameScreenZeusVsHadesMachine:showEnterRespinGuochang(func)
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showRespinStartGuochang.mp3")
    self.m_respinGuochang:setVisible(true)
    self.m_respinGuochang:playAction(
        "auto",
        false,
        function()
            self.m_respinGuochang:setVisible(false)
            if func then
                func()
            end
        end
    )
    self.m_respinGuochang.m_dialog:playAction("auto", false)
    util_spinePlay(self.m_respinGuochang.m_zeusAni, "actionframe1", false)
    util_spinePlay(self.m_respinGuochang.m_hadesAni, "actionframe1", false)
end
--触发respin
function CodeGameScreenZeusVsHadesMachine:triggerReSpinCallFun(endTypes, randomTypes)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self:initRespinView(endTypes, randomTypes)
end
function CodeGameScreenZeusVsHadesMachine:initRespinView(endTypes, randomType)
    --构造盘面数据
    self.m_respinIndex = 0
    self.m_respinTotalNum = self.m_roomPlayerList:getRoomData().result.data.bonusResults[1].totalTimes - self.m_roomPlayerList:getRoomData().result.data.bonusResults[1].newTimes

    local respinNodeInfo = self:reateRespinNodeInfo()
    self.m_respinView:setEndSymbolType(endTypes, randomType)

    local reelWidth = self:findChild("sp_bonus_reel_0"):getContentSize().width
    local reelHeight = self:findChild("sp_bonus_reel_0"):getContentSize().height
    local slotWidth = reelWidth
    local slotHeight = reelHeight / self.m_respinReelRowNum
    self.m_respinView:initRespinSize(slotWidth, slotHeight, reelWidth, reelHeight)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_respinReelRowNum,
        self.m_respinReelColumnNum,
        function()
            self:initLeftJiantou()
            self:initRightJiantou()
            self:runCsbAction(
                "actionframe1",
                false,
                function()
                    -- self:runNextReSpinReel()
                end
            )
            self.m_bonusNumBar:setVisible(true)
            self.m_bonusNumBar:playAction("idleframe")
            self:findChild("changeRoom_button"):setVisible(false)
            self:updateBonusNumBar()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
    self.m_miniReel:setReelSlotsNodeVisible(false)
end
function CodeGameScreenZeusVsHadesMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}
    for iCol = 1, self.m_respinReelColumnNum do
        for iRow = self.m_respinReelRowNum, 1, -1 do
            --信号类型
            local symbolType = nil
            local respinNodeType = 0
             --图标红蓝类型，0为宙斯蓝，1为哈迪斯红
            if iCol <= self.m_respinReelColumnNum / 2 then
                symbolType = self.SYMBOL_SCORE_RESPINNORMAL
                respinNodeType = 0
            else
                symbolType = self.SYMBOL_SCORE_RESPINNORMAL_2
                respinNodeType = 1
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local reelNode = self:findChild("sp_bonus_reel_" .. (iCol - 1))
            local posX = reelNode:getPositionX()
            local posY = reelNode:getPositionY()
            local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
            local reelHeight = reelNode:getContentSize().height
            local reelWidth = reelNode:getContentSize().width
            local pos = worldPos
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local slotNodeH = reelHeight / self.m_respinReelRowNum
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                teamType = respinNodeType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
--初始化左箭头数量显示
function CodeGameScreenZeusVsHadesMachine:initLeftJiantou()
    local showNum = 0
    for i, jiantou in ipairs(self.m_collectLeftJiantouTab) do
        if i < showNum then
            jiantou:setVisible(true)
        elseif i == showNum then
            jiantou:setVisible(true)
        else
            jiantou:setVisible(false)
        end
    end
end
--初始化右箭头数量显示
function CodeGameScreenZeusVsHadesMachine:initRightJiantou()
    local showNum = 0
    for i, jiantou in ipairs(self.m_collectRightJiantouTab) do
        if i < showNum then
            jiantou:setVisible(true)
        elseif i == showNum then
            jiantou:setVisible(true)
        else
            jiantou:setVisible(false)
        end
    end
end
--更新bonus几次条显示次数
function CodeGameScreenZeusVsHadesMachine:updateBonusNumBar()
    if self.m_zeusSpinIndex ~= nil then
        self.m_bonusNumBar:findChild("m_lb_num_1"):setString("" .. self.m_zeusSpinIndex)
        self.m_bonusNumBar:findChild("m_lb_num_2"):setString("" .. self.m_zeusRespinTotalNum)
    else
        self.m_bonusNumBar:findChild("m_lb_num_1"):setString("" .. self.m_respinIndex)
        self.m_bonusNumBar:findChild("m_lb_num_2"):setString("" .. self.m_respinTotalNum)
    end
end
--respin接收到数据开始停止滚动
function CodeGameScreenZeusVsHadesMachine:stopRespinRun()
    local storedNodeInfo, unStoredReels = self:getRespinSpinData()
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
end
--获取respin图标数据(锁定的图标)
function CodeGameScreenZeusVsHadesMachine:getRespinSpinData()
    local respinData = nil
    local replacePoints = nil
    self.m_playerReplacePointsDataIdx = nil
    if self.m_zeusSpinIndex ~= nil then
        respinData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex]
    else
        respinData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex]
        if self.m_roomPlayerList:getRoomData().result.data.replacePoints then
            for i, data in ipairs(self.m_roomPlayerList:getRoomData().result.data.replacePoints) do
                if data.atTimes == self.m_respinIndex then
                    self.m_playerReplacePointsDataIdx = i
                    break
                end
            end
        end
    end

    local storedInfo = {}
    local unStoredReels = {}
    for row = 1, self.m_respinReelRowNum do
        for col = 1, self.m_respinReelColumnNum do
            local symbolType = respinData.reels[self.m_respinReelRowNum - row + 1][col]
            if self.m_playerReplacePointsDataIdx ~= nil then
                local data = self.m_roomPlayerList:getRoomData().result.data.replacePoints[self.m_playerReplacePointsDataIdx]
                local rowColData = self:getRowAndColByPos(data.position, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                if rowColData.iX == row and rowColData.iY == col then
                    if data.chairId < 4 then
                        symbolType = self.SYMBOL_SCORE_RESPINNORMAL
                    else
                        symbolType = self.SYMBOL_SCORE_RESPINNORMAL_2
                    end
                end
            end
            local pos = {iX = row, iY = col, type = symbolType}
            if symbolType == self.SYMBOL_SCORE_MULTIPLE or symbolType == self.SYMBOL_SCORE_MULTIPLE_2 then
                table.insert(storedInfo, pos)
            else
                table.insert(unStoredReels, pos)
            end
        end
    end
    return storedInfo, unStoredReels
end

--respin轮盘停止
function CodeGameScreenZeusVsHadesMachine:reSpinReelDown(addNode)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    self:updateQuestUI()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local delayNode = cc.Node:create()
    self:addChild(delayNode)
    performWithDelay(
        delayNode,
        function()
            self:playerReplaceSymbol()
            delayNode:removeFromParent()
        end,
        1.0
    )
end
--玩家变图标
function CodeGameScreenZeusVsHadesMachine:playerReplaceSymbol()
    if self.m_playerReplacePointsDataIdx == nil then
        --玩家没变
        self:zeusGrabTerritory()
    else
        local data = self.m_roomPlayerList:getRoomData().result.data.replacePoints[self.m_playerReplacePointsDataIdx]
        if data.chairId < 4 then
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_zeusTeamPlayerReplaceSymbol.mp3")
        else
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_hadesTeamPlayerReplaceSymbol.mp3")
        end
        self.m_roomPlayerList:allPlayerItemJump(
            function()
                self.m_roomPlayerList.m_playerItems[data.chairId + 1]:runCsbAction(
                    "idleframe1",
                    false,
                    function()
                        local rowColData = self:getRowAndColByPos(data.position, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                        local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)

                        local startWorldPos =
                            self.m_roomPlayerList.m_playerItems[data.chairId + 1]:findChild("touxiang"):getParent():convertToWorldSpace(
                            cc.p(self.m_roomPlayerList.m_playerItems[data.chairId + 1]:findChild("touxiang"):getPosition())
                        )
                        local startPos = self:convertToNodeSpace(startWorldPos)

                        local endWorldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
                        local endPos = self:convertToNodeSpace(endWorldPos)

                        self.m_roomPlayerList.m_maskLayer:playAction(
                            "over",
                            false,
                            function()
                                self.m_roomPlayerList.m_maskLayer:setVisible(false)
                            end
                        )
                        self.m_roomPlayerList.m_playerItems[data.chairId + 1]:runCsbAction("actionframe1")
                        performWithDelay(
                            self,
                            function()
                                for i, v in ipairs(self.m_roomPlayerList.m_playerItems) do
                                    if i ~= data.chairId + 1 then
                                        if self.m_roomPlayerList.m_playerItems[i]:isVisible() == true then
                                            self.m_roomPlayerList.m_playerItems[i]:runCsbAction("actionframe2")
                                        end
                                    end
                                end
                            end,
                            30 / 60
                        )
                        performWithDelay(
                            self,
                            function()
                                local flyEff = nil
                                if data.chairId < 4 then
                                    flyEff = util_createAnimation("ZeusVsHades_TouxiangZ_trail.csb")
                                else
                                    flyEff = util_createAnimation("ZeusVsHades_TouxiangH_trail.csb")
                                end
                                self:addChild(flyEff, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

                                local angle = util_getAngleByPos(startPos, endPos)
                                flyEff:setRotation(-angle)
                                local scaleSize = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
                                flyEff:setScaleX(scaleSize / 325)
                                flyEff:setPosition(startPos)
                                flyEff:runCsbAction(
                                    "actionframe",
                                    false,
                                    function()
                                        flyEff:stopAllActions()
                                        flyEff:removeFromParent()
                                    end
                                )
                                performWithDelay(
                                    self,
                                    function()
                                        local baozhaEff = nil
                                        if data.chairId < 4 then
                                            baozhaEff = util_createAnimation("ZeusVsHades_TouxiangZ_bd.csb")
                                        else
                                            baozhaEff = util_createAnimation("ZeusVsHades_TouxiangH_bd.csb")
                                        end
                                        self:addChild(baozhaEff, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                                        baozhaEff:setPosition(endPos)
                                        baozhaEff:playAction(
                                            "actionframe",
                                            false,
                                            function()
                                                baozhaEff:removeFromParent()
                                                self:zeusGrabTerritory()
                                            end
                                        )
                                        performWithDelay(
                                            self,
                                            function()
                                                if data.chairId < 4 then
                                                    symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_PLUNDER), self.SYMBOL_SCORE_PLUNDER)
                                                else
                                                    symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_PLUNDER_2), self.SYMBOL_SCORE_PLUNDER_2)
                                                end
                                                self:updateReelGridNode(symbolNode)
                                            end,
                                            10 / 60
                                        )
                                    end,
                                    15 / 60
                                )
                            end,
                            30 / 60
                        )
                    end
                )
            end
        )
    end
end
--宙斯抢地盘
function CodeGameScreenZeusVsHadesMachine:zeusGrabTerritory()
    if self.m_zeusSpinIndex ~= nil then
        local resultsData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex]
        if table.nums(resultsData.blueReplace) > 0 then
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showNum.mp3")
            for triggerPosStr, targetPosTab in pairs(resultsData.blueReplace) do
                local rowColData = self:getRowAndColByPos(tonumber(triggerPosStr), self.m_respinReelRowNum, self.m_respinReelColumnNum)
                local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
                symbolNode:runAnim("actionframe1")
            end
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_zeusShowQiangdipan.mp3")
                    self.m_zeus:setVisible(true)
                    util_spinePlay(self.m_zeus, "actionframe3", false)
                    util_spineEndCallFunc(
                        self.m_zeus,
                        "actionframe3",
                        function()
                            self.m_zeus:setVisible(false)
                            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showLeikuang.mp3")
                            -- self.m_respinLeiKuang:setVisible(true)
                            -- self.m_respinLeiKuang:playAction("actionframe1",false,function ()
                            --     self.m_respinLeiKuang:playAction("idleframe",true)
                            -- end)

                            self.m_replaceData = clone(resultsData.blueReplace)
                            self:playZeusGrabTerritorySymbol()
                        end
                    )
                end,
                60 / 60
            )
        else
            self:zeusCollectJiantou()
        end
    else
        local resultsData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex]
        if table.nums(resultsData.blueReplace) > 0 then
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showNum.mp3")
            for triggerPosStr, targetPosTab in pairs(resultsData.blueReplace) do
                local rowColData = self:getRowAndColByPos(tonumber(triggerPosStr), self.m_respinReelRowNum, self.m_respinReelColumnNum)
                local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
                symbolNode:runAnim("actionframe1")
            end

            performWithDelay(
                self,
                function()
                    self.m_zeus:setVisible(true)
                    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_zeusShowQiangdipan.mp3")
                    util_spinePlay(self.m_zeus, "actionframe3", false)
                    util_spineEndCallFunc(
                        self.m_zeus,
                        "actionframe3",
                        function()
                            self.m_zeus:setVisible(false)
                            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showLeikuang.mp3")
                            self.m_respinLeiKuang:setVisible(true)
                            self.m_respinLeiKuang:playAction(
                                "actionframe1",
                                false,
                                function()
                                    self.m_respinLeiKuang:playAction("idleframe", true)
                                end
                            )
                            self.m_replaceData = clone(resultsData.blueReplace)
                            self:playZeusGrabTerritorySymbol()
                        end
                    )
                end,
                60 / 60
            )
        else
            self:hadesGrabTerritory()
        end
    end
end
--播宙斯抢地盘的图标动画
function CodeGameScreenZeusVsHadesMachine:playZeusGrabTerritorySymbol()
    if table.nums(self.m_replaceData) > 0 then
        local triggerPosTab = {}
        for triggerPosStr, targetPosTab in pairs(self.m_replaceData) do
            table.insert(triggerPosTab, tonumber(triggerPosStr))
        end
        table.sort(
            triggerPosTab,
            function(pos1, pos2)
                local rowColData1 = self:getRowAndColByPos(pos1, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                local rowColData2 = self:getRowAndColByPos(pos2, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                if rowColData1.iX > rowColData2.iX then
                    return true
                end
                if rowColData1.iX == rowColData2.iX then
                    return rowColData1.iY > rowColData2.iY
                end
                return false
            end
        )
        for i, triggerPos in ipairs(triggerPosTab) do
            -- for triggerPosStr,targetPosTab in pairs(self.m_replaceData) do
            local targetPosTab = self.m_replaceData["" .. triggerPos]
            self.m_replaceTargetData = targetPosTab
            local rowColData = self:getRowAndColByPos(triggerPos, self.m_respinReelRowNum, self.m_respinReelColumnNum)
            local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
            local numString = symbolNode:getCcbProperty("m_lb_num"):getString()
            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_RESPINNORMAL), self.SYMBOL_SCORE_RESPINNORMAL)
            local newSymbolNode = util_createAnimation("Socre_ZeusVsHAdes_plunder.csb")
            self.m_clipParent:addChild(newSymbolNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
            newSymbolNode:findChild("m_lb_num"):setString(numString)
            local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
            local position = self.m_clipParent:convertToNodeSpace(worldPos)
            newSymbolNode:setPosition(position)
            newSymbolNode:playAction(
                "actionframe",
                false,
                function()
                    newSymbolNode:removeFromParent()
                    self:playZeusGrabTerritorySymbolEd()
                end
            )
            self.m_replaceData["" .. triggerPos] = nil
            break
        end
    else
        --抢完了
        self.m_replaceData = nil
        self.m_replaceTargetData = nil
        if self.m_zeusSpinIndex == nil then
            self.m_respinLeiKuang:playAction(
                "over",
                false,
                function()
                    self.m_respinLeiKuang:setVisible(false)
                end
            )
        end

        if self.m_zeusSpinIndex ~= nil then
            self:zeusCollectJiantou()
        else
            self:hadesGrabTerritory()
        end
    end
end
--播被宙斯抢的图标动画
function CodeGameScreenZeusVsHadesMachine:playZeusGrabTerritorySymbolEd()
    if table.nums(self.m_replaceTargetData) > 0 then
        local replaceTargetData = self.m_replaceTargetData[1]
        table.remove(self.m_replaceTargetData, 1)
        --添加特效
        local leiEff = util_createAnimation("ZeusVsHades_SDChuFakuang.csb")
        self.m_clipParent:addChild(leiEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

        local rowColData = self:getRowAndColByPos(replaceTargetData, self.m_respinReelRowNum, self.m_respinReelColumnNum)
        local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
        local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local position = self.m_clipParent:convertToNodeSpace(worldPos)
        leiEff:setPosition(position)
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_HadesSymbolToZeus.mp3")
        leiEff:playAction(
            "actionframe",
            false,
            function()
                leiEff:removeFromParent()
                self:playZeusGrabTerritorySymbolEd()
            end
        )

        local changeSymbolNode = self.m_respinView:changeTeamType(self, 0, rowColData.iY, rowColData.iX)
        if changeSymbolNode.p_symbolType == self.SYMBOL_SCORE_MULTIPLE then
            -- 抢到大倍数图标，庆祝一下
            local numStr = changeSymbolNode:getCcbProperty("m_lb_beishu"):getString()
            local num = tonumber(string.match(numStr, "%d+"))
            if num >= self.YEAH_MULTIPLE then
                local yeaEff = util_createAnimation("ZeusVsHades_yeah.csb")
                self.m_clipParent:addChild(yeaEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                yeaEff:setPosition(position)
                yeaEff:findChild("ZeusVsHades_yeah1"):setVisible(false)
                yeaEff:playAction(
                    "auto",
                    false,
                    function()
                        yeaEff:removeFromParent()
                    end
                )
                gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_HadesSymbolToZeusYeah.mp3")
            else
            end
        end
    else
        --一个抢地盘图标抢的地盘动画完了，走下一个图标
        self:playZeusGrabTerritorySymbol()
    end
end
--哈迪斯抢地盘
function CodeGameScreenZeusVsHadesMachine:hadesGrabTerritory()
    local resultsData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex]
    if table.nums(resultsData.redReplace) > 0 then
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_hadesGrabTerritory.mp3")
        for triggerPosStr, targetPosTab in pairs(resultsData.redReplace) do
            local rowColData = self:getRowAndColByPos(tonumber(triggerPosStr), self.m_respinReelRowNum, self.m_respinReelColumnNum)
            local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
            symbolNode:runAnim("actionframe1")
        end

        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_hadesGrabTerritoryShow.mp3")
                self.m_hades:setVisible(true)
                util_spinePlay(self.m_hades, "actionframe3", false)
                util_spineEndCallFunc(
                    self.m_hades,
                    "actionframe3",
                    function()
                        self.m_hades:setVisible(false)
                        self.m_respinHuoKuang:setVisible(true)
                        self.m_respinHuoKuang:playAction(
                            "actionframe1",
                            false,
                            function()
                                self.m_respinHuoKuang:playAction("idleframe", true)
                            end
                        )
                        self.m_replaceData = clone(resultsData.redReplace)
                        self:playHadesGrabTerritorySymbol()
                    end
                )
            end,
            60 / 60
        )
    else
        self:hadesCollectJiantou()
    end
end
--播哈迪斯抢地盘的图标动画
function CodeGameScreenZeusVsHadesMachine:playHadesGrabTerritorySymbol()
    if table.nums(self.m_replaceData) > 0 then
        local triggerPosTab = {}
        for triggerPosStr, targetPosTab in pairs(self.m_replaceData) do
            table.insert(triggerPosTab, tonumber(triggerPosStr))
        end
        table.sort(
            triggerPosTab,
            function(pos1, pos2)
                local rowColData1 = self:getRowAndColByPos(pos1, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                local rowColData2 = self:getRowAndColByPos(pos2, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                if rowColData1.iX > rowColData2.iX then
                    return true
                end
                if rowColData1.iX == rowColData2.iX then
                    return rowColData1.iY < rowColData2.iY
                end
                return false
            end
        )
        for i, triggerPos in ipairs(triggerPosTab) do
            -- for triggerPosStr,targetPosTab in pairs(self.m_replaceData) do
            local targetPosTab = self.m_replaceData["" .. triggerPos]
            self.m_replaceTargetData = targetPosTab
            local rowColData = self:getRowAndColByPos(triggerPos, self.m_respinReelRowNum, self.m_respinReelColumnNum)
            local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
            -- local numString = symbolNode:getCcbProperty("m_lb_num"):getString()
            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_RESPINNORMAL_2), self.SYMBOL_SCORE_RESPINNORMAL_2)

            local newSymbolNode = util_createAnimation("Socre_ZeusVsHAdes_plunder2.csb")
            self.m_clipParent:addChild(newSymbolNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
            local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
            local position = self.m_clipParent:convertToNodeSpace(worldPos)
            newSymbolNode:setPosition(position)
            -- newSymbolNode:findChild("m_lb_num"):setString(numString)
            newSymbolNode:playAction(
                "actionframe",
                false,
                function()
                    newSymbolNode:removeFromParent()
                    self:playFireAni()

                    -- --添加飞火球特效
                    -- local flyEff = util_createAnimation("Socre_ZeusVsHAdes_plunder3.csb")
                    -- self.m_clipParent:addChild(flyEff,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                    -- flyEff:setPosition(position)
                    -- flyEff:playAction("actionframe",false,function ()
                    --     flyEff:removeFromParent()
                    -- end)

                    -- local replaceTargetData = self.m_replaceTargetData[1]
                    -- local targetrowColData = self:getRowAndColByPos(replaceTargetData,self.m_respinReelRowNum,self.m_respinReelColumnNum)
                    -- local targetsymbolNode = self.m_respinView:getEndSlotsNode(targetrowColData.iY,targetrowColData.iX)
                    -- local targetworldPos = targetsymbolNode:getParent():convertToWorldSpace(cc.p(targetsymbolNode:getPosition()))
                    -- local targetposition = self.m_clipParent:convertToNodeSpace(targetworldPos)

                    -- local moveto = cc.MoveTo:create(18/60,targetposition)
                    -- local callFunc = cc.CallFunc:create(function ()
                    --     self:playHadesGrabTerritorySymbolEd()
                    -- end)
                    -- local seq = cc.Sequence:create({moveto,callFunc})
                    -- flyEff:runAction(seq)

                    -- local angle = util_getAngleByPos(position,targetposition)
                    -- flyEff:setRotation( - angle - 180)
                end
            )
            self.m_replaceData["" .. triggerPos] = nil
            break
        end
    else
        --抢完了
        self.m_replaceData = nil
        self.m_replaceTargetData = nil
        self.m_respinHuoKuang:playAction(
            "over",
            false,
            function()
                self.m_respinHuoKuang:setVisible(false)
            end
        )
        self:hadesCollectJiantou()
    end
end
--播火球动画
function CodeGameScreenZeusVsHadesMachine:playFireAni()
    if table.nums(self.m_replaceTargetData) > 0 then
        local replaceTargetData = self.m_replaceTargetData[1]
        table.remove(self.m_replaceTargetData, 1)
        local rowColData = self:getRowAndColByPos(replaceTargetData, self.m_respinReelRowNum, self.m_respinReelColumnNum)
        local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
        local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local position = self.m_clipParent:convertToNodeSpace(worldPos)

        --添加飞火球特效
        local flyEff = util_createAnimation("Socre_ZeusVsHAdes_plunder3.csb")
        self.m_clipParent:addChild(flyEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        flyEff:setPosition(position)
        flyEff:playAction(
            "actionframe",
            false,
            function()
                flyEff:removeFromParent()

                -- local huoEff = util_createAnimation("ZeusVsHades_HYbaodian.csb")
                -- self.m_clipParent:addChild(huoEff,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                -- huoEff:setPosition(position)
                -- gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_ZeusSymbolToHades.mp3")
                -- huoEff:playAction("actionframe",false,function ()
                --     huoEff:removeFromParent()
                -- end)
                -- performWithDelay(huoEff,function ()
                --     local changeSymbolNode = self.m_respinView:changeTeamType(self,1,rowColData.iY,rowColData.iX)
                --     if changeSymbolNode.p_symbolType == self.SYMBOL_SCORE_MULTIPLE_2 then
                --         -- 抢到大倍数图标，庆祝一下
                --         local numStr = changeSymbolNode:getCcbProperty("m_lb_beishu"):getString()
                --         local num = tonumber(string.match(numStr,"%d+"))
                --         if num >= self.YEAH_MULTIPLE then
                --             local yeaEff = util_createAnimation("ZeusVsHades_yeah.csb")
                --             self.m_clipParent:addChild(yeaEff,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                --             yeaEff:setPosition(position)
                --             yeaEff:findChild("ZeusVsHades_yeah2"):setVisible(false)
                --             yeaEff:playAction("auto",false,function ()
                --                 yeaEff:removeFromParent()
                --             end)
                --             gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_ZeusSymbolToHadesYeah.mp3")
                --         end
                --     end
                -- end,45/60)

                performWithDelay(
                    self,
                    function()
                        self:playFireAni()
                    end,
                    0.1
                )
            end
        )
        --第30帧接爆点
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                waitNode:removeFromParent()

                local huoEff = util_createAnimation("ZeusVsHades_HYbaodian.csb")
                self.m_clipParent:addChild(huoEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                huoEff:setPosition(position)
                gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_ZeusSymbolToHades.mp3")
                huoEff:playAction(
                    "actionframe",
                    false,
                    function()
                        huoEff:removeFromParent()
                    end
                )

                performWithDelay(
                    huoEff,
                    function()
                        local changeSymbolNode = self.m_respinView:changeTeamType(self, 1, rowColData.iY, rowColData.iX)
                        if changeSymbolNode.p_symbolType == self.SYMBOL_SCORE_MULTIPLE_2 then
                            -- 抢到大倍数图标，庆祝一下
                            local numStr = changeSymbolNode:getCcbProperty("m_lb_beishu"):getString()
                            local num = tonumber(string.match(numStr, "%d+"))
                            if num >= self.YEAH_MULTIPLE then
                                local yeaEff = util_createAnimation("ZeusVsHades_yeah.csb")
                                self.m_clipParent:addChild(yeaEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                                yeaEff:setPosition(position)
                                yeaEff:findChild("ZeusVsHades_yeah2"):setVisible(false)
                                yeaEff:playAction(
                                    "auto",
                                    false,
                                    function()
                                        yeaEff:removeFromParent()
                                    end
                                )
                                gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_ZeusSymbolToHadesYeah.mp3")
                            end
                        end
                    end,
                    30 / 60
                )
            end,
            30 / 60
        )
    else
        --一个抢地盘图标抢的地盘动画完了，走下一个图标
        performWithDelay(
            self,
            function()
                self:playHadesGrabTerritorySymbol()
            end,
            45 / 60
        )
    end
end
--播被哈迪斯抢的图标动画
function CodeGameScreenZeusVsHadesMachine:playHadesGrabTerritorySymbolEd()
    if table.nums(self.m_replaceTargetData) > 0 then
        local replaceTargetData = self.m_replaceTargetData[1]
        table.remove(self.m_replaceTargetData, 1)

        local rowColData = self:getRowAndColByPos(replaceTargetData, self.m_respinReelRowNum, self.m_respinReelColumnNum)
        local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
        local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local position = self.m_clipParent:convertToNodeSpace(worldPos)

        local huoEff = util_createAnimation("ZeusVsHades_HYbaodian.csb")
        self.m_clipParent:addChild(huoEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        huoEff:setPosition(position)
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_ZeusSymbolToHades.mp3")
        huoEff:playAction(
            "actionframe",
            false,
            function()
                huoEff:removeFromParent()
                self:playHadesGrabTerritorySymbolEd()
            end
        )
        performWithDelay(
            huoEff,
            function()
                local changeSymbolNode = self.m_respinView:changeTeamType(self, 1, rowColData.iY, rowColData.iX)
                if changeSymbolNode.p_symbolType == self.SYMBOL_SCORE_MULTIPLE_2 then
                    -- 抢到大倍数图标，庆祝一下
                    local numStr = changeSymbolNode:getCcbProperty("m_lb_beishu"):getString()
                    local num = tonumber(string.match(numStr, "%d+"))
                    if num >= self.YEAH_MULTIPLE then
                        local yeaEff = util_createAnimation("ZeusVsHades_yeah.csb")
                        self.m_clipParent:addChild(yeaEff, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
                        yeaEff:setPosition(position)
                        yeaEff:findChild("ZeusVsHades_yeah2"):setVisible(false)
                        yeaEff:playAction(
                            "auto",
                            false,
                            function()
                                yeaEff:removeFromParent()
                            end
                        )
                        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_ZeusSymbolToHadesYeah.mp3")
                    end
                end
            end,
            45 / 60
        )
    else
        --一个抢地盘图标抢的地盘动画完了，走下一个图标
        self:playHadesGrabTerritorySymbol()
    end
end
--哈迪斯收集箭头
function CodeGameScreenZeusVsHadesMachine:hadesCollectJiantou()
    local respinData = self.m_roomPlayerList:getRoomData().result.data.bonusResults
    self.m_jiantouCollectPosTab = {}
    for row = self.m_respinReelRowNum, 1, -1 do
        for col = 1, self.m_respinReelColumnNum do
            local symbolType = respinData[self.m_respinIndex].finalReels[self.m_respinReelRowNum - row + 1][col]
            if symbolType == self.SYMBOL_SCORE_COLLECT_2 then
                local pos = {iX = row, iY = col}
                table.insert(self.m_jiantouCollectPosTab, pos)
            end
        end
    end

    if #self.m_jiantouCollectPosTab > 0 then
        self.m_rightJiantouEff:setVisible(true)
        self.m_rightJiantouEff:playAction("actionframe", true)
        self:playHadesCollectJiantouAni()
    else
        self:zeusCollectJiantou()
    end
end
--开始播哈迪斯收集箭头动画
function CodeGameScreenZeusVsHadesMachine:playHadesCollectJiantouAni()
    if #self.m_jiantouCollectPosTab == 0 then
        --等箭头动画播完
        performWithDelay(
            self,
            function()
                if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redMultiplePositions then
                    --收集满触发翻倍
                    self:hadesCollectJiantouFull()
                else
                    --没收集满
                    self.m_rightJiantouEff:setVisible(false)
                    self:zeusCollectJiantou()
                end
            end,
            30 / 60
        )
        return
    end

    --一个一个收集
    -- local rowColData = self.m_jiantouCollectPosTab[1]
    -- table.remove(self.m_jiantouCollectPosTab,1)
    -- local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY,rowColData.iX)
    -- symbolNode:runAnim("actionframe",false,function ()
    --     self:addOneRightJiantou()
    --     self:playHadesCollectJiantouAni()
    -- end)

    --一起收集
    -- gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinHadesCollectSymbolAni.mp3")
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinHadesCollectjiantou.mp3")
    for i, rowColData in ipairs(self.m_jiantouCollectPosTab) do
        local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
        if i == #self.m_jiantouCollectPosTab then
            symbolNode:runAnim(
                "actionframe",
                false,
                function()
                    -- gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinHadesCollectjiantou.mp3")
                    self:showRightJiantou()
                    self.m_jiantouCollectPosTab = {}
                    self:playHadesCollectJiantouAni()
                end
            )
        else
            symbolNode:runAnim("actionframe", false)
        end
    end
end
--右侧显示的箭头加一
function CodeGameScreenZeusVsHadesMachine:addOneRightJiantou()
    for i, jiantou in ipairs(self.m_collectRightJiantouTab) do
        if jiantou:isVisible() == false then
            jiantou:setVisible(true)
            jiantou:playAction("actionframe")
            break
        end
    end
end
--全部显示哈迪斯边的箭头
function CodeGameScreenZeusVsHadesMachine:showRightJiantou()
    local leftCount = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redCollect.collectLeftCount
    local totalCount = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redCollect.collectTotalCount
    if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redMultiplePositions then
        --这里触发了翻倍，显示满箭头
        leftCount = 0
    end

    local showNum = totalCount - leftCount
    for i, jiantou in ipairs(self.m_collectRightJiantouTab) do
        if i <= showNum then
            if jiantou:isVisible() == false then
                jiantou:setVisible(true)
                jiantou:playAction("actionframe")
            end
        else
            jiantou:setVisible(false)
        end
    end
end

--哈迪斯箭头收集满
function CodeGameScreenZeusVsHadesMachine:hadesCollectJiantouFull()
    -- self.m_rightJiantouEff:setVisible(true)
    -- self.m_rightJiantouEff:playAction("actionframe",true)

    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_hadesCollectFullShow.mp3")
    self.m_hades:setVisible(true)
    util_spinePlay(self.m_hades, "actionframe4", false)
    util_spineEndCallFunc(
        self.m_hades,
        "actionframe4",
        function()
            self.m_hades:setVisible(false)
            self.m_respinHuoKuang:setVisible(true)
            self.m_respinHuoKuang:playAction("actionframe", true)

            --翻倍图标处显示火焰特效框
            self.m_multiplePosData = clone(self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].redMultiplePositions)
            --排序  从右到左,从上到下
            table.sort(
                self.m_multiplePosData,
                function(pos1, pos2)
                    local rowColData1 = self:getRowAndColByPos(pos1, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                    local rowColData2 = self:getRowAndColByPos(pos2, self.m_respinReelRowNum, self.m_respinReelColumnNum)
                    if rowColData1.iY > rowColData2.iY then
                        return true
                    end
                    if rowColData1.iY == rowColData2.iY then
                        if rowColData1.iX > rowColData2.iX then
                            return true
                        end
                    end
                    return false
                end
            )
            self.m_respinView:allTeamChangeDark(0)
            self:respinHadesSymbolMultiple()
        end
    )
end
--哈迪斯阵营图标翻倍
function CodeGameScreenZeusVsHadesMachine:respinHadesSymbolMultiple()
    if #self.m_multiplePosData == 0 then
        self.m_respinHuoKuang:setVisible(false)
        self.m_rightJiantouEff:setVisible(false)
        self:initRightJiantou()
        self:zeusCollectJiantou()
        self.m_respinView:allTeamChangeLight(0)
        return
    end
    local pos = self.m_multiplePosData[1]
    table.remove(self.m_multiplePosData, 1)
    local rowColData = self:getRowAndColByPos(pos, self.m_respinReelRowNum, self.m_respinReelColumnNum)
    local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
    local multiple = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].store[pos + 1]
    symbolNode:runAnim(
        "chengbei",
        false,
        function()
            self:respinHadesSymbolMultiple()
        end
    )

    local temSymbol = util_createAnimation("Socre_ZeusVsHAdes_zuanhong.csb")
    self:findChild("Node_kuang"):addChild(temSymbol)
    temSymbol:findChild("m_lb_beishu"):setString(symbolNode:getCcbProperty("m_lb_beishu"):getString())

    local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
    local localPos = self:findChild("Node_kuang"):convertToNodeSpace(worldPos)
    temSymbol:setPosition(localPos)

    temSymbol:playAction(
        "chengbei",
        false,
        function()
            -- temSymbol:removeFromParent()
        end
    )

    performWithDelay(
        temSymbol,
        function()
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_Double.mp3")
            symbolNode:getCcbProperty("m_lb_beishu"):setString("X" .. multiple)
            temSymbol:findChild("m_lb_beishu"):setString("X" .. multiple)

            performWithDelay(
                temSymbol,
                function()
                    temSymbol:removeFromParent()
                end,
                20 / 60
            )
        end,
        15 / 60
    )
end
--宙斯收集箭头
function CodeGameScreenZeusVsHadesMachine:zeusCollectJiantou()
    local respinData = nil
    if self.m_zeusSpinIndex ~= nil then
        respinData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex]
    else
        respinData = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex]
    end

    self.m_jiantouCollectPosTab = {}
    for row = self.m_respinReelRowNum, 1, -1 do
        for col = 1, self.m_respinReelColumnNum do
            local symbolType = respinData.finalReels[self.m_respinReelRowNum - row + 1][col]
            if symbolType == self.SYMBOL_SCORE_COLLECT then
                local pos = {iX = row, iY = col}
                table.insert(self.m_jiantouCollectPosTab, pos)
            end
        end
    end

    if #self.m_jiantouCollectPosTab > 0 then
        self.m_leftJiantouEff:setVisible(true)
        self.m_leftJiantouEff:playAction("actionframe", true)
        self:playZeusCollectJiantouAni()
    else
        self:respinEffectEnd()
    end
end
--开始播宙斯收集箭头动画
function CodeGameScreenZeusVsHadesMachine:playZeusCollectJiantouAni()
    if #self.m_jiantouCollectPosTab == 0 then
        --等箭头动画播完
        performWithDelay(
            self,
            function()
                if self.m_zeusSpinIndex ~= nil then
                    if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex].blueNewTimes > 0 then
                        --收集满触发宙斯respin
                        self:zeusCollectJiantouFull()
                    else
                        --没收集满
                        self.m_leftJiantouEff:setVisible(false)
                        self:respinEffectEnd()
                    end
                else
                    if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueNewTimes > 0 then
                        --收集满触发宙斯respin
                        self:zeusCollectJiantouFull()
                    else
                        --没收集满
                        self.m_leftJiantouEff:setVisible(false)
                        self:respinEffectEnd()
                    end
                end
            end,
            30 / 60
        )
        return
    end
    --一个一个收集
    -- local rowColData = self.m_jiantouCollectPosTab[1]
    -- table.remove(self.m_jiantouCollectPosTab,1)
    -- local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY,rowColData.iX)
    -- symbolNode:runAnim("actionframe",false,function ()
    --     self:addOneLeftJiantou()
    --     self:playZeusCollectJiantouAni()
    -- end)

    --一起收集
    -- gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinZeusCollectSymbolAni.mp3")
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinZeusCollectjiantou.mp3")
    for i, rowColData in ipairs(self.m_jiantouCollectPosTab) do
        local symbolNode = self.m_respinView:getEndSlotsNode(rowColData.iY, rowColData.iX)
        if i == #self.m_jiantouCollectPosTab then
            symbolNode:runAnim(
                "actionframe",
                false,
                function()
                    -- gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinZeusCollectjiantou.mp3")
                    self:showLeftJiantou()
                    self.m_jiantouCollectPosTab = {}
                    self:playZeusCollectJiantouAni()
                end
            )
        else
            symbolNode:runAnim("actionframe", false)
        end
    end
end
--左侧显示的箭头加一
function CodeGameScreenZeusVsHadesMachine:addOneLeftJiantou()
    for i, jiantou in ipairs(self.m_collectLeftJiantouTab) do
        if jiantou:isVisible() == false then
            jiantou:setVisible(true)
            jiantou:playAction("actionframe")
            break
        end
    end
end
--全部显示宙斯边的箭头
function CodeGameScreenZeusVsHadesMachine:showLeftJiantou()
    local leftCount = 0
    local totalCount = 0
    if self.m_zeusSpinIndex ~= nil then
        leftCount = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex].blueCollect.collectLeftCount
        totalCount = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex].blueCollect.collectTotalCount
        --这里收集满，显示满箭头
        if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex].blueNewTimes > 0 then
            leftCount = 0
        end
    else
        leftCount = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollect.collectLeftCount
        totalCount = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollect.collectTotalCount
        --这里收集满，显示满箭头
        if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueNewTimes > 0 then
            leftCount = 0
        end
    end

    local showNum = totalCount - leftCount
    for i, jiantou in ipairs(self.m_collectLeftJiantouTab) do
        if i <= showNum then
            if jiantou:isVisible() == false then
                jiantou:setVisible(true)
                jiantou:playAction("actionframe")
            end
        else
            jiantou:setVisible(false)
        end
    end
end
--宙斯箭头收集满
function CodeGameScreenZeusVsHadesMachine:zeusCollectJiantouFull()
    if self.m_zeusSpinIndex == nil then
        self.m_zeusSpinIndex = 0
        self.m_zeusRespinTotalNum = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueTotalTimes
    else
        self.m_zeusRespinTotalNum = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature[self.m_zeusSpinIndex].blueTotalTimes
    end
    -- self.m_leftJiantouEff:setVisible(true)
    -- self.m_leftJiantouEff:playAction("actionframe",true)
    self.m_respinLeiKuang:setVisible(true)
    self.m_respinLeiKuang:playAction("actionframe", true)
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_zeusShow.mp3")
    self.m_zeus:setVisible(true)
    util_spinePlay(self.m_zeus, "actionframe4", false)
    util_spineEndCallFunc(
        self.m_zeus,
        "actionframe4",
        function()
            self.m_zeus:setVisible(false)
            self.m_leftJiantouEff:setVisible(false)
            self:initLeftJiantou()
            if self.m_zeusSpinIndex == 0 then
                self.m_respinView:allTeamChangeDark(1)
            end
            self:respinEffectEnd()
        end
    )
    self.m_bonusNumBar:setVisible(true)
    if self.m_zeusSpinIndex == 0 then
        self.m_bonusNumBar:playAction(
            "actionframe",
            false,
            function()
                self.m_bonusNumBar:playAction("idleframe1")
            end
        )
    end
    self:updateBonusNumBar()
end

--respin效果结束，走下一步
function CodeGameScreenZeusVsHadesMachine:respinEffectEnd()
    function normalRespin()
        -- 正常respin
        if self.m_respinIndex >= #self.m_roomPlayerList:getRoomData().result.data.bonusResults then
            self:updateBonusNumBar()
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
            --quest
            self:updateQuestBonusRespinEffectData()

            --结束
            if self.m_respinFinalEffect ~= nil then
                self.m_respinFinalEffect:removeFromParent()
                self.m_respinFinalEffect = nil
            end
            self:clearCurMusicBg()
            self:reSpinEndAction()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            local winCoins = self.m_roomPlayerList:getRoomData().result.data.userWinAmount[globalData.userRunData.userUdid]
            -- self:checkFeatureOverTriggerBigWin(winCoins , GameEffect.EFFECT_RESPIN_OVER)

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.BONUSOVER_SHOWCHOOSEVIEW_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUSOVER_SHOWCHOOSEVIEW_EFFECT
            self.m_miniReel:MainReel_addSelfEffect(selfEffect)

            self.m_isWaitingNetworkData = false
            return
        end
        --下一轮是最后一轮了，加点动画再转
        if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex + 1].leftTimes == 0 then
            self.m_respinNumTriger:setVisible(true)
            self.m_respinNumTriger:findChild("finalRound"):setVisible(true)
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_finalRound.mp3")
            self.m_respinNumTriger:playAction(
                "actionframe",
                false,
                function()
                    self.m_respinNumTriger:setVisible(false)
                    self.m_respinNumTriger:findChild("finalRound"):setVisible(false)

                    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                    self:runNextReSpinReel()
                end
            )
        else
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            self:runNextReSpinReel()
        end
    end

    if self.m_zeusSpinIndex ~= nil then
        --在宙斯收集满的玩法下
        if self.m_zeusSpinIndex >= #self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex].blueCollectFeature then
            self.m_zeusSpinIndex = nil
            self.m_bonusNumBar:playAction("idleframe", false)
            self.m_respinView:allTeamChangeLight(1)
            self.m_respinLeiKuang:setVisible(false)
            normalRespin()
            return
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        self:runNextReSpinReel()
    else
        normalRespin()
    end
end
--开始下次ReSpin
function CodeGameScreenZeusVsHadesMachine:runNextReSpinReel()
    if self.m_zeusSpinIndex == nil then
        if self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex + 1].newTimes > 0 then
            --增加次数
            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_addRespinNum.mp3")
            self.m_respinTotalNum = self.m_roomPlayerList:getRoomData().result.data.bonusResults[self.m_respinIndex + 1].totalTimes
            self.m_respinNumTriger:setVisible(true)
            self.m_respinNumTriger:findChild("addNum"):setVisible(true)
            self.m_respinNumTriger:playAction(
                "actionframe",
                false,
                function()
                    self.m_respinNumTriger:setVisible(false)
                    self.m_respinNumTriger:findChild("addNum"):setVisible(false)

                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                    CodeGameScreenZeusVsHadesMachine.super.runNextReSpinReel(self)
                end
            )
            performWithDelay(
                self,
                function()
                    self:updateBonusNumBar()
                end,
                125 / 60
            )
            return
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    CodeGameScreenZeusVsHadesMachine.super.runNextReSpinReel(self)
end

--respin开始滚动
function CodeGameScreenZeusVsHadesMachine:startReSpinRun()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end

    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    -- self:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})

    if self.m_zeusSpinIndex ~= nil then
        self.m_zeusSpinIndex = self.m_zeusSpinIndex + 1
        self:updateBonusNumBar()
        self.m_respinView:startMove(true)
    else
        self.m_respinIndex = self.m_respinIndex + 1
        self:updateBonusNumBar()
        self.m_respinView:startMove()
    end
    self.m_thisRoundIsCanPlayWinSound = true
    local delayNode = cc.Node:create()
    self:addChild(delayNode)
    performWithDelay(
        delayNode,
        function()
            self:stopRespinRun()
            self:setGameSpinStage(GAME_MODE_ONE_RUN)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
        end,
        0.1
    )
end
--respin结束开始结算
function CodeGameScreenZeusVsHadesMachine:reSpinEndAction()
    self.m_respinNumTriger:setVisible(true)
    self.m_respinNumTriger:findChild("bonusCompleted"):setVisible(true)
    self.m_zeusCollectMultiple = 0
     --当下宙斯收集的倍数
    self.m_hadesCollectMultiple = 0
     --当下哈迪斯收集的倍数
    self:updateRespinEndCollectMultipleNum()
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_bonusCompleted.mp3")
    self.m_respinNumTriger:playAction(
        "actionframe",
        false,
        function()
            self.m_respinNumTriger:setVisible(false)
            self.m_respinNumTriger:findChild("bonusCompleted"):setVisible(false)
            self:runCsbAction(
                "actionframe2",
                false,
                function()
                    --开始收集
                    self:respinEndCollectMultiple()
                end
            )
        end
    )
end
function CodeGameScreenZeusVsHadesMachine:updateRespinEndCollectMultipleNum()
    if self.m_zeusCollectMultiple == nil or self.m_zeusCollectMultiple == 0 then
        self:findChild("m_lb_coins_2"):setVisible(false)
    else
        self:findChild("m_lb_coins_2"):setVisible(true)
        self:findChild("m_lb_coins_2"):setString("X" .. self.m_zeusCollectMultiple)
    end
    if self.m_hadesCollectMultiple == nil or self.m_hadesCollectMultiple == 0 then
        self:findChild("m_lb_coins_3"):setVisible(false)
    else
        self:findChild("m_lb_coins_3"):setVisible(true)
        self:findChild("m_lb_coins_3"):setString("X" .. self.m_hadesCollectMultiple)
    end
end
--respin结束收集倍数
function CodeGameScreenZeusVsHadesMachine:respinEndCollectMultiple()
    self.m_zeusMultipleNodes, self.m_hadesMultipleNodes = self.m_respinView:getAllCleaningNode()
    self:playMultipleCollectAnim()
end
--播放收集动画
function CodeGameScreenZeusVsHadesMachine:playMultipleCollectAnim()
    if #self.m_zeusMultipleNodes == 0 and #self.m_hadesMultipleNodes == 0 then
        --等待收集动画播完
        performWithDelay(
            self,
            function()
                --收集结束
                self.m_zeusCollectEff:setVisible(false)
                self.m_hadesCollectEff:setVisible(false)
                gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_MultipleCollectAnim.mp3")
                self:runCsbAction(
                    "jiesuan",
                    false,
                    function()
                        if self.m_zeusCollectMultiple > self.m_hadesCollectMultiple then
                            self:runCsbAction(
                                "zeuswin",
                                false,
                                function()
                                    self:showRespinOverView()
                                end
                            )
                        else
                            self:runCsbAction(
                                "hadeswin",
                                false,
                                function()
                                    self:showRespinOverView()
                                end
                            )
                        end
                    end
                )
            end,
            1
        )
        return
    end
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_MultipleCollect.mp3")
    if #self.m_zeusMultipleNodes > 0 then
        local zeusMultipleNode = self.m_zeusMultipleNodes[1]
        table.remove(self.m_zeusMultipleNodes, 1)
        local beishu = tonumber(string.match(zeusMultipleNode:getCcbProperty("m_lb_beishu"):getString(), "%d+"))
        self.m_zeusCollectMultiple = self.m_zeusCollectMultiple + beishu
        zeusMultipleNode:runAnim("jiesuan", false)
        self.m_zeusCollectEff:setVisible(true)
        self.m_zeusCollectEff:playAction("actionframe", false)
    end
    if #self.m_hadesMultipleNodes > 0 then
        local hadesMultipleNode = self.m_hadesMultipleNodes[1]
        table.remove(self.m_hadesMultipleNodes, 1)
        local beishu = tonumber(string.match(hadesMultipleNode:getCcbProperty("m_lb_beishu"):getString(), "%d+"))
        self.m_hadesCollectMultiple = self.m_hadesCollectMultiple + beishu
        hadesMultipleNode:runAnim("jiesuan", false)
        self.m_hadesCollectEff:setVisible(true)
        self.m_hadesCollectEff:playAction("actionframe", false)
    end
    self:updateRespinEndCollectMultipleNum()
    local delayNode = cc.Node:create()
    self:addChild(delayNode)
    performWithDelay(
        delayNode,
        function()
            delayNode:removeFromParent()
            self:playMultipleCollectAnim()
        end,
        0.4
    )
 --60/60)
end
--显示respin结束结算界面
function CodeGameScreenZeusVsHadesMachine:showRespinOverView()
    performWithDelay(
        self,
        function()
            self:runCsbAction("over1", false)
            local selfChoose = 0
             --自己所在阵营
            for i, playSetInfo in ipairs(self.m_roomPlayerList:getRoomData().result.data.sets) do
                if playSetInfo.udid == globalData.userRunData.userUdid then
                    if playSetInfo.chairId < 4 then
                        selfChoose = 0
                    else
                        selfChoose = 1
                    end
                    break
                end
            end

            --宙斯方赢
            if self.m_zeusCollectMultiple > self.m_hadesCollectMultiple then
                if selfChoose ~= 0 then
                    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinOverSettlement1.mp3")
                else
                    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinOverSettlement2.mp3")
                end
                self.m_zeusWinBg:setVisible(true)
                self.m_zeusWinBg:playAction(
                    "start",
                    false,
                    function()
                        self.m_zeusWinBg:playAction("idle", true)
                    end
                )
                self.m_zeus:setVisible(true)
                self.m_zeus:setAnimation(0, "actionframe2", false)
                util_spineEndCallFunc(
                    self.m_zeus,
                    "actionframe2",
                    function()
                        gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_startLogOutTime")
                        gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeUpdateState", {1})

                        --如果自己是败方
                        if selfChoose ~= 0 then
                            self.m_zeusWinBg:setVisible(false)
                            self.m_zeus:setVisible(false)
                            self:removeRespinView()
                            self:runCsbAction(
                                "over2",
                                false,
                                function()
                                    self:runCsbAction("over", false)
                                end
                            )
                            local winCoins = self.m_roomPlayerList:getRoomData().result.data.userWinAmount[globalData.userRunData.userUdid]
                            local view =
                                self:showReSpinOver(
                                winCoins,
                                function()
                                    self:reSpinOverchangeUI()
                                end
                            )
                            local node = view:findChild("m_lb_coins")
                            view:updateLabelSize({label = node, sx = 1, sy = 1}, 688)
                        else
                            --如果自己是胜方
                            self.m_zeus:setAnimation(0, "start", false)
                            self.m_zeus:addAnimation(0, "idleframe2", true)

                            local zeusTeamData = {}
                             --宙斯阵营玩家数据
                            for i, playSetInfo in ipairs(self.m_roomPlayerList:getRoomData().result.data.sets) do
                                local data = clone(playSetInfo)
                                if playSetInfo.chairId < 4 then
                                    table.insert(zeusTeamData, data)
                                end
                            end
                            --按赢钱多少排序
                            table.sort(
                                zeusTeamData,
                                function(data1, data2)
                                    return self.m_roomPlayerList:getRoomData().result.data.userWinAmount[data1.udid] > self.m_roomPlayerList:getRoomData().result.data.userWinAmount[data2.udid]
                                end
                            )

                            for i = 1, 4 do
                                if zeusTeamData[i] ~= nil then
                                    self.m_zeusWinPlayerList:findChild("player_" .. i):setVisible(true)
                                    local head = self.m_zeusWinPlayerList:findChild("player_touxiang_" .. i)
                                    local winCoin = self.m_roomPlayerList:getRoomData().result.data.userWinAmount[zeusTeamData[i].udid]
                                    self.m_zeusWinPlayerList:findChild("player_wincoin_" .. i):setString(util_formatCoins(winCoin, 3))
                                    if zeusTeamData[i].udid == globalData.userRunData.userUdid then
                                        self.m_zeusWinPlayerList:findChild("qizi_" .. i .. "_me"):setVisible(true)
                                        self.m_zeusWinPlayerList:findChild("qizi_" .. i):setVisible(false)
                                        self.m_zeusWinPlayerList:findChild("head_kuanglv" .. i):setVisible(true)
                                        self.m_zeusWinPlayerList:findChild("head_kuanglan" .. i):setVisible(false)
                                        if i == 1 then
                                            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinwinNo1.mp3")
                                        else
                                            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinwin.mp3")
                                        end
                                    else
                                        self.m_zeusWinPlayerList:findChild("qizi_" .. i .. "_me"):setVisible(false)
                                        self.m_zeusWinPlayerList:findChild("qizi_" .. i):setVisible(true)
                                        self.m_zeusWinPlayerList:findChild("head_kuanglv" .. i):setVisible(false)
                                        self.m_zeusWinPlayerList:findChild("head_kuanglan" .. i):setVisible(true)
                                    end


                                    head:removeAllChildren(true)
                                    -- local frameId = zeusTeamData[i].udid == globalData.userRunData.userUdid and globalData.userRunData.avatarFrameId or zeusTeamData[i].frame
                                    -- local headSize = head:getContentSize()
                                    -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(zeusTeamData[i].facebookId, zeusTeamData[i].head, frameId, nil, headSize)
                                    -- head:addChild(nodeAvatar)
                                    -- nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

                                    -- local headRoot = head:getParent()
                                    -- local headFrameNode = headRoot:getChildByName("headFrameNode")
                                    -- if not headFrameNode then
                                    --     headFrameNode = cc.Node:create()
                                    --     headRoot:addChild(headFrameNode, 10)
                                    --     headFrameNode:setName("headFrameNode")
                                    --     headFrameNode:setPosition(head:getPosition())
                                    --     headFrameNode:setLocalZOrder(10)
                                    --     headFrameNode:setScale(head:getScale())
                                    -- else
                                    --     headFrameNode:removeAllChildren(true)
                                    -- end
                                    -- util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)
                                    util_setHead(head, zeusTeamData[i].facebookId, zeusTeamData[i].head, nil, false)
                                else
                                    self.m_zeusWinPlayerList:findChild("player_" .. i):setVisible(false)
                                end
                            end

                            self.m_zeusWinPlayerList:findChild("zeus_collectButton"):setTouchEnabled(true)
                            self.m_zeusWinPlayerList:setVisible(true)
                            self.m_zeusWinPlayerList:playAction(
                                "start" .. #zeusTeamData,
                                false,
                                function()
                                    self.m_zeusWinPlayerList:playAction("idle", true)
                                end
                            )
                        end
                    end
                )
            else
                --哈迪斯方赢
                if selfChoose ~= 1 then
                    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinOverSettlement3.mp3")
                else
                    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinOverSettlement4.mp3")
                end
                self.m_hadesWinBg:setVisible(true)
                self.m_hadesWinBg:playAction(
                    "start",
                    false,
                    function()
                        self.m_hadesWinBg:playAction("idle", true)
                    end
                )
                self.m_hadesWin:setVisible(true)
                self.m_hadesWin:setAnimation(0, "actionframe2", false)
                util_spineEndCallFunc(
                    self.m_hadesWin,
                    "actionframe2",
                    function()
                        gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_startLogOutTime")
                        gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeUpdateState", {1})

                        --如果自己是败方
                        if selfChoose ~= 1 then
                            self.m_hadesWinBg:setVisible(false)
                            self.m_hadesWin:setVisible(false)
                            self:removeRespinView()
                            self:runCsbAction(
                                "over2",
                                false,
                                function()
                                    self:runCsbAction("over", false)
                                end
                            )
                            local winCoins = self.m_roomPlayerList:getRoomData().result.data.userWinAmount[globalData.userRunData.userUdid]
                            local view =
                                self:showReSpinOver(
                                winCoins,
                                function()
                                    self:reSpinOverchangeUI()
                                end
                            )
                            local node = view:findChild("m_lb_coins")
                            view:updateLabelSize({label = node, sx = 1, sy = 1}, 688)
                        else
                            --如果自己是胜方
                            self.m_hadesWin:setAnimation(0, "start", false)
                            self.m_hadesWin:addAnimation(0, "idleframe2", true)

                            local hadesTeamData = {}
                             --哈迪斯阵营玩家数据
                            for i, playSetInfo in ipairs(self.m_roomPlayerList:getRoomData().result.data.sets) do
                                local data = clone(playSetInfo)
                                if playSetInfo.chairId >= 4 then
                                    table.insert(hadesTeamData, data)
                                end
                            end
                            --按赢钱多少排序
                            table.sort(
                                hadesTeamData,
                                function(data1, data2)
                                    return self.m_roomPlayerList:getRoomData().result.data.userWinAmount[data1.udid] > self.m_roomPlayerList:getRoomData().result.data.userWinAmount[data2.udid]
                                end
                            )

                            for i = 1, 4 do
                                if hadesTeamData[i] ~= nil then
                                    self.m_hadesWinPlayerList:findChild("player_" .. i):setVisible(true)
                                    local head = self.m_hadesWinPlayerList:findChild("player_touxiang_" .. i)
                                    local winCoin = self.m_roomPlayerList:getRoomData().result.data.userWinAmount[hadesTeamData[i].udid]
                                    self.m_hadesWinPlayerList:findChild("player_wincoin_" .. i):setString(util_formatCoins(winCoin, 3))
                                    if hadesTeamData[i].udid == globalData.userRunData.userUdid then
                                        self.m_hadesWinPlayerList:findChild("qizi_" .. i .. "_me"):setVisible(true)
                                        self.m_hadesWinPlayerList:findChild("qizi_" .. i):setVisible(false)
                                        self.m_hadesWinPlayerList:findChild("head_kuanglv" .. i):setVisible(true)
                                        self.m_hadesWinPlayerList:findChild("head_kuanglan" .. i):setVisible(false)
                                        if i == 1 then
                                            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinwinNo1.mp3")
                                        else
                                            gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_respinwin.mp3")
                                        end
                                    else
                                        self.m_hadesWinPlayerList:findChild("qizi_" .. i .. "_me"):setVisible(false)
                                        self.m_hadesWinPlayerList:findChild("qizi_" .. i):setVisible(true)
                                        self.m_hadesWinPlayerList:findChild("head_kuanglv" .. i):setVisible(false)
                                        self.m_hadesWinPlayerList:findChild("head_kuanglan" .. i):setVisible(true)
                                    end


                                    head:removeAllChildren(true)
                                    -- local frameId = hadesTeamData[i].udid == globalData.userRunData.userUdid and globalData.userRunData.avatarFrameId or hadesTeamData[i].frame
                                    -- local headSize = head:getContentSize()
                                    -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(hadesTeamData[i].facebookId, hadesTeamData[i].head, frameId, nil, headSize)
                                    -- head:addChild(nodeAvatar)
                                    -- nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

                                    -- local headRoot = head:getParent()
                                    -- local headFrameNode = headRoot:getChildByName("headFrameNode")
                                    -- if not headFrameNode then
                                    --     headFrameNode = cc.Node:create()
                                    --     headRoot:addChild(headFrameNode, 10)
                                    --     headFrameNode:setName("headFrameNode")
                                    --     headFrameNode:setPosition(head:getPosition())
                                    --     headFrameNode:setLocalZOrder(10)
                                    --     headFrameNode:setScale(head:getScale())
                                    -- else
                                    --     headFrameNode:removeAllChildren(true)
                                    -- end
                                    -- util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)
                                    util_setHead(head, hadesTeamData[i].facebookId, hadesTeamData[i].head, nil, false)
                                else
                                    self.m_hadesWinPlayerList:findChild("player_" .. i):setVisible(false)
                                end
                            end
                            self.m_hadesWinPlayerList:findChild("hades_collectButton"):setTouchEnabled(true)
                            self.m_hadesWinPlayerList:setVisible(true)
                            self.m_hadesWinPlayerList:playAction(
                                "start" .. #hadesTeamData,
                                false,
                                function()
                                    self.m_hadesWinPlayerList:playAction("idle", true)
                                end
                            )
                        end
                    end
                )
            end
        end,
        0.5
    )
end
function CodeGameScreenZeusVsHadesMachine:showReSpinOver(coins, func)
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showRespinOver.mp3")
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog("BonusOver", ownerlist, func)
end
--删除respin轮盘界面
function CodeGameScreenZeusVsHadesMachine:removeRespinView()
    self:setReelSlotsNodeVisible(true)
    self.m_miniReel:setReelSlotsNodeVisible(true)
    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end
function CodeGameScreenZeusVsHadesMachine:reSpinOverchangeUI()
    local gameName = self:getNetWorkModuleName()
    local index = -1
    local winCoins = self.m_roomPlayerList:getRoomData().result.data.userWinAmount[globalData.userRunData.userUdid]
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(
        gameName,
        index,
        function()
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(
                ViewEventType.NOTIFY_UPDATE_WINCOIN,
                {
                    winCoins,
                    true,
                    true
                }
            )
            self:triggerReSpinOverCallFun(winCoins)
            self:findChild("tip_button"):setEnabled(true)
            self:playGameEffect()
            self.m_miniReel:playGameEffect()
            self.m_roomPlayerList:getRoomData().result = nil
            self.m_bonusNumBar:setVisible(false)
            self:findChild("changeRoom_button"):setVisible(true)
            self.m_roomPlayerList:hideAllNoPlayerSpr()
        end,
        function(errorCode, errorData)
        end
    )
end
function CodeGameScreenZeusVsHadesMachine:triggerReSpinOverCallFun(score)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = score or 0
    if self.m_bProduceSlots_InFreeSpin then
        local addCoin = self.m_serverWinCoins
        coins = self:getLastWinCoin() or 0
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    if self.postReSpinOverTriggerBigWIn then
        self:postReSpinOverTriggerBigWIn(coins)
    end

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
     --不删除玩法结束若玩家没有spin的话触发不了玩法
    self.m_miniReel:removeGameEffectType(GameEffect.EFFECT_RESPIN)
    -- self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenZeusVsHadesMachine:MachineRule_SpinBtnCall()
    self.m_norDownTimes = 0
    self.m_norCSStatesTimes = 0

    self:setMaxMusicBGVolume()
    return false -- 用作延时点击spin调用
end
function CodeGameScreenZeusVsHadesMachine:beginReel()
    self:resetMusicBg()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_thisRoundIsCanPlayWinSound = true
    self.m_isReconnection = false
    self:hideTip()
    self:setSymbolToReel()
    self:removeChangeReelDataHandler()
    self.super.beginReel(self)
    self.m_miniReel:beginMiniReel()
    --重置自动退出时间间隔
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_resetLogoutTime")
end

function CodeGameScreenZeusVsHadesMachine:playEffectNotifyChangeSpinStatus()
    self:reelShowSpinNotify()
end

function CodeGameScreenZeusVsHadesMachine:reelShowSpinNotify()
    self.m_norCSStatesTimes = self.m_norCSStatesTimes + 1
    if self.m_norCSStatesTimes == self.m_maxReelNum then
        CodeGameScreenZeusVsHadesMachine.super.playEffectNotifyChangeSpinStatus(self)
        self.m_norCSStatesTimes = 0
    end
end

function CodeGameScreenZeusVsHadesMachine:reelDownNotifyPlayGameEffect()
    self:setReelRunDownNotify()
end

function CodeGameScreenZeusVsHadesMachine:setReelRunDownNotify()
    self.m_norDownTimes = self.m_norDownTimes + 1
    if self.m_norDownTimes == self.m_maxReelNum then
        CodeGameScreenZeusVsHadesMachine.super.reelDownNotifyPlayGameEffect(self)
        self.m_norDownTimes = 0
    end
end
-- 是否有bonus收集或者变wild玩法
function CodeGameScreenZeusVsHadesMachine:isHaveBonusCollectChangeWildEffect()
    self.m_isHaveBonusCollect = false
    self.m_isBonusCollectEnd = true
    self.m_isHaveChangeWild = false
    self.m_isChangeWildEnd = true
    if self.m_runSpinResultData.p_selfMakeData.positionScores then
        if table.nums(self.m_runSpinResultData.p_selfMakeData.positionScores[1]) > 0 or table.nums(self.m_runSpinResultData.p_selfMakeData.positionScores[2]) > 0 then
            self.m_isHaveBonusCollect = true
            self.m_isBonusCollectEnd = false
        end
    end
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.wildPositions and #self.m_runSpinResultData.p_selfMakeData.wildPositions > 0 then
        if #self.m_runSpinResultData.p_selfMakeData.wildPositions[1] > 0 or #self.m_runSpinResultData.p_selfMakeData.wildPositions[2] > 0 then
            self.m_isHaveChangeWild = true
            self.m_isChangeWildEnd = false
        end
    end
end
-- 添加关卡中触发的玩法
function CodeGameScreenZeusVsHadesMachine:addSelfEffect()
    -- -- bonus收集
    -- if self.m_runSpinResultData.p_selfMakeData.positionScores then
    --     if table.nums(self.m_runSpinResultData.p_selfMakeData.positionScores[1]) > 0 or table.nums(self.m_runSpinResultData.p_selfMakeData.positionScores[2]) > 0 then
    --         local selfEffect = GameEffectData.new()
    --         selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --         selfEffect.p_effectOrder = self.BONUSCOLLECT_EFFECT
    --         self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --         selfEffect.p_selfEffectType = self.BONUSCOLLECT_EFFECT
    --         self.m_miniReel:MainReel_addSelfEffect(selfEffect)
    --     end
    -- end
    -- -- 变wild
    -- if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.wildPositions and #self.m_runSpinResultData.p_selfMakeData.wildPositions > 0 then
    --     if #self.m_runSpinResultData.p_selfMakeData.wildPositions[1] > 0 or #self.m_runSpinResultData.p_selfMakeData.wildPositions[2] > 0 then
    --         local selfEffect = GameEffectData.new()
    --         selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --         selfEffect.p_effectOrder = self.CHANGEWILD_EFFECT
    --         self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --         selfEffect.p_selfEffectType = self.CHANGEWILD_EFFECT
    --         self.m_miniReel:MainReel_addSelfEffect(selfEffect)
    --     end
    -- end
    self:isHaveBonusCollectChangeWildEffect()
    if self.m_isHaveBonusCollect == true or self.m_isHaveChangeWild == true then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BONUSCOLLECT_CHANGEWILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUSCOLLECT_CHANGEWILD_EFFECT
        self.m_miniReel:MainReel_addSelfEffect(selfEffect)
    end

    self:checkTriggerBonus()
end
-- 通知某种类型动画播放完毕
function CodeGameScreenZeusVsHadesMachine:notifyGameEffectPlayComplete(param)
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

    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    self.m_miniReel:MainReel_removeSelfEffect(effectData)
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
function CodeGameScreenZeusVsHadesMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenZeusVsHadesMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BONUSCOLLECT_CHANGEWILD_EFFECT then
        self:collectBonus()
        self:changeWild()
    end
    -- if effectData.p_selfEffectType == self.BONUSCOLLECT_EFFECT then
    --     self:collectBonus()
    -- elseif effectData.p_selfEffectType == self.CHANGEWILD_EFFECT then
    --     self:changeWild()
    -- end
    if effectData.p_selfEffectType == self.RECONNECTION_BONUSOVER_EFFECT then
        -- self:checkFeatureOverTriggerBigWin(self.m_reconnectionBonusWinCoin,GameEffect.EFFECT_RESPIN_OVER)
        local view =
            self:showReSpinOver(
            self.m_reconnectionBonusWinCoin,
            function()
                local gameName = self:getNetWorkModuleName()
                local index = -1
                gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(
                    gameName,
                    index,
                    function()
                        globalData.slotRunData.lastWinCoin = 0
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_reconnectionBonusWinCoin, true, true})
                        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.RECONNECTION_BONUSOVER_EFFECT})
                        self.m_roomPlayerList:hideAllNoPlayerSpr()
                    end,
                    function(errorCode, errorData)
                    end
                )
            end
        )
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 688)
    end

    if effectData.p_selfEffectType == self.BONUSOVER_SHOWCHOOSEVIEW_EFFECT then
        self:showChooseTeamView(
            function()
                self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.BONUSOVER_SHOWCHOOSEVIEW_EFFECT})
            end
        )
    end
    return true
end
--bonus收集
function CodeGameScreenZeusVsHadesMachine:collectBonus()
    if self.m_isHaveBonusCollect then
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_collectBonus.mp3")
        if table.nums(self.m_runSpinResultData.p_selfMakeData.positionScores[1]) > 0 then
            for pos, coinNum in pairs(self.m_runSpinResultData.p_selfMakeData.positionScores[1]) do
                local fixPos = self:getRowAndColByPos(pos)
                local startClipPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local startWorldPos = self.m_clipParent:convertToWorldSpace(startClipPos)
                self:collectCoinFly(startWorldPos)
            end
        end

        if table.nums(self.m_runSpinResultData.p_selfMakeData.positionScores[2]) > 0 then
            for pos, coinNum in pairs(self.m_runSpinResultData.p_selfMakeData.positionScores[2]) do
                local fixPos = self:getRowAndColByPos(pos)
                local startClipPos = self.m_miniReel:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local startWorldPos = self.m_miniReel.m_clipParent:convertToWorldSpace(startClipPos)
                self:collectCoinFly(startWorldPos)
            end
        end
        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(
            delayNode,
            function()
                self:setCollectCoinNum(true)
            end,
            20 / 60
        )
        performWithDelay(
            delayNode,
            function()
                delayNode:removeFromParent()
                self.m_isBonusCollectEnd = true
                self:bonusCollectChangeWildEnd()
                -- self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.BONUSCOLLECT_EFFECT})
            end,
            60 / 60
        )
    end
end
function CodeGameScreenZeusVsHadesMachine:collectCoinFly(startWorldPos)
    local fly = util_createAnimation("ZeusVsHades_Bonus_trail.csb")
    self:addChild(fly, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = self:convertToNodeSpace(startWorldPos)
    local endWorldPos = self:findChild("m_lb_coins_1"):getParent():convertToWorldSpace(cc.p(self:findChild("m_lb_coins_1"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local angle = util_getAngleByPos(startPos, endPos)
    fly:setRotation(-angle)

    local scaleSize = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    fly:setScaleX(scaleSize / 570)

    fly:setPosition(startPos)

    fly:runCsbAction(
        "actionframe",
        false,
        function()
            fly:stopAllActions()
            fly:removeFromParent()
        end
    )
end
--设置收集的钱数
function CodeGameScreenZeusVsHadesMachine:setCollectCoinNum(isPlayAni)
    if isPlayAni == true then
        self:runCsbAction("collectAni")
    end
    local collectCoinNum = 0
    if self.m_roomPlayerList:getRoomData().result then
        collectCoinNum = self.m_roomPlayerList:getRoomData().result.data.userScore[globalData.userRunData.userUdid]
    else
        collectCoinNum = self.m_roomPlayerList:getRoomData().extra.score
    end
    if collectCoinNum == 0 then
        collectCoinNum = 1
    end
    local coinStr = util_formatCoins(collectCoinNum, 300)
    self:findChild("m_lb_coins_1"):setString(coinStr)
    self:updateLabelSize({label = self:findChild("m_lb_coins_1"), sx = 0.6, sy = 0.6}, 380)
end
--变wild
function CodeGameScreenZeusVsHadesMachine:changeWild()
    if self.m_isHaveChangeWild then
        local flyTime = 10 / 30
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_changeWild.mp3")
        if #self.m_runSpinResultData.p_selfMakeData.wildPositions[1] > 0 then
            for i, pos in ipairs(self.m_runSpinResultData.p_selfMakeData.wildPositions[1]) do
                local fixPos = self:getRowAndColByPos(pos)
                local startPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local flyWild = util_spineCreate("Socre_ZeusVsHades_Wild", true, true)
                self.m_clipParent:addChild(flyWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                flyWild:setPosition(startPos)

                local miniPos = self.m_miniReel:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local endWorldPos = self.m_miniReel.m_clipParent:convertToWorldSpace(miniPos)
                local endPos = self.m_clipParent:convertToNodeSpace(endWorldPos)

                local moveTo = cc.MoveTo:create(flyTime, endPos)
                flyWild:runAction(moveTo)
                util_spinePlay(flyWild, "actionframe2", false)
                util_spineFrameEvent(
                    flyWild,
                    "actionframe2",
                    "baodian",
                    function()
                        local baozha = util_createAnimation("Socre_ZeusVsHAdes_Wild_Hades.csb")
                        self.m_clipParent:addChild(baozha, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
                        baozha:setPosition(endPos)
                        performWithDelay(
                            baozha,
                            function()
                                local slotNode = self.m_miniReel:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                                if slotNode then
                                    if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                                        self.m_miniReel:setOneSymbolToReel(slotNode)
                                        if slotNode.m_bonusNode == nil then
                                            slotNode.m_bonusNode = util_spineCreate("Socre_ZeusVsHAdes_Bonus", true, true)
                                            slotNode:addChild(slotNode.m_bonusNode, -2)
                                            slotNode.m_bonusNode:setVisible(false)
                                        end
                                        if slotNode.m_numLabel then
                                            slotNode.m_numLabel:setLocalZOrder(-1)
                                            slotNode.m_numLabel:setVisible(false)
                                        end
                                    end

                                    slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                    slotNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD))
                                    slotNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - slotNode.p_rowIndex - 1)
                                end
                            end,
                            15 / 60
                        )
                        baozha:playAction(
                            "actionframe",
                            false,
                            function()
                                baozha:removeFromParent()
                                flyWild:removeFromParent()
                            end
                        )
                    end
                )
            end
        end
        if #self.m_runSpinResultData.p_selfMakeData.wildPositions[2] > 0 then
            for i, pos in ipairs(self.m_runSpinResultData.p_selfMakeData.wildPositions[2]) do
                local fixPos = self:getRowAndColByPos(pos)

                local miniPos = self.m_miniReel:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local startWorldPos = self.m_miniReel.m_clipParent:convertToWorldSpace(miniPos)
                local startPos = self.m_clipParent:convertToNodeSpace(startWorldPos)

                local endPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local flyWild = util_spineCreate("Socre_ZeusVsHades_Wild", true, true)
                self.m_clipParent:addChild(flyWild, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                flyWild:setPosition(startPos)

                local moveTo = cc.MoveTo:create(flyTime, endPos)
                flyWild:runAction(moveTo)
                util_spinePlay(flyWild, "actionframe1", false)
                util_spineFrameEvent(
                    flyWild,
                    "actionframe1",
                    "baodian",
                    function()
                        local baozha = util_createAnimation("Socre_ZeusVsHAdes_Wild_Zeus.csb")
                        self.m_clipParent:addChild(baozha, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
                        baozha:setPosition(endPos)
                        performWithDelay(
                            baozha,
                            function()
                                local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                                if slotNode then
                                    if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                                        self:setOneSymbolToReel(slotNode)
                                        if slotNode.m_bonusNode == nil then
                                            slotNode.m_bonusNode = util_spineCreate("Socre_ZeusVsHAdes_Bonus", true, true)
                                            slotNode:addChild(slotNode.m_bonusNode, -2)
                                            slotNode.m_bonusNode:setVisible(false)
                                        end
                                        if slotNode.m_numLabel then
                                            slotNode.m_numLabel:setLocalZOrder(-1)
                                            slotNode.m_numLabel:setVisible(false)
                                        end
                                    end

                                    slotNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                    slotNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD))
                                    slotNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - slotNode.p_rowIndex - 1)
                                end
                            end,
                            15 / 60
                        )
                        baozha:playAction(
                            "actionframe",
                            false,
                            function()
                                baozha:removeFromParent()
                                flyWild:removeFromParent()
                            end
                        )
                    end
                )
            end
        end

        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(
            delayNode,
            function()
                self.m_isChangeWildEnd = true
                self:bonusCollectChangeWildEnd()
                -- self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.CHANGEWILD_EFFECT})
            end,
            flyTime + 45 / 60
        )
    end
end
--收集bonus变wild结束
function CodeGameScreenZeusVsHadesMachine:bonusCollectChangeWildEnd()
    if self.m_isBonusCollectEnd == true and self.m_isChangeWildEnd == true then
        self.m_isHaveBonusCollect = false
        self.m_isHaveChangeWild = false
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT, self.BONUSCOLLECT_CHANGEWILD_EFFECT})
    end
end

function CodeGameScreenZeusVsHadesMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenZeusVsHadesMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    BaseNewReelMachine.slotReelDown(self)
end

--弹出选择阵营界面
function CodeGameScreenZeusVsHadesMachine:showChooseTeamView(func)
    self.m_roomPlayerList:sendLogOutRoom()
    self.m_chooseTeamView = util_createView("CodeZeusVsHadesSrc.ZeusVsHadesChooseTeamView", self, func)
    self:addChild(self.m_chooseTeamView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseTeamView:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenZeusVsHadesMachine:checkOperaSpinSuccess(param)
    if param == nil then
    end
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:operaSpinResultData(param)
        self:operaUserInfoWithSpinResult(param)
        --写入副轮盘的数据
        if spinData.result.selfData ~= nil and spinData.result.selfData.rightSpinResult ~= nil then
            local resultDatas = spinData.result.selfData.rightSpinResult
            resultDatas.bet = spinData.result.bet
            resultDatas.payLineCount = spinData.result.payLineCount
            resultDatas.action = spinData.result.action -- "NORMAL"
            self.m_miniReel:netWorkCallFun(resultDatas)
            self.m_miniReel.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        end
        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
        self:delayChangeReelData()
    end
end
--延迟改变假滚
function CodeGameScreenZeusVsHadesMachine:delayChangeReelData()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_configData:setReplaceSignal(self.m_runSpinResultData.p_selfMakeData.replaceSignal)
            self.m_miniReel.m_configData:setReplaceSignal(self.m_miniReel.m_runSpinResultData.p_selfMakeData.replaceSignal)
            for col = 1, self.m_iReelColumnNum do
                self:changeSlotReelDatas(col)
                self.m_miniReel:changeSlotReelDatas(col)
            end
        end,
        0.5,
        "changeReelData"
    )
end
function CodeGameScreenZeusVsHadesMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end
--重新设置假滚数据
function CodeGameScreenZeusVsHadesMachine:changeSlotReelDatas(_col)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end
-- 设置假滚
function CodeGameScreenZeusVsHadesMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil or parentData.beginReelIndex > #reelDatas then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end
--获取在哪一列出第二个图标
function CodeGameScreenZeusVsHadesMachine:getSymbolEndCol(findSymbolType)
    local endCol = 0
    local symbolNum = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[self.m_iReelRowNum - iRow + 1][iCol]
            if symbolType == findSymbolType then
                symbolNum = symbolNum + 1
            end
            local symbolType1 = self.m_miniReel.m_runSpinResultData.p_reels[self.m_iReelRowNum - iRow + 1][iCol]
            if symbolType1 == findSymbolType then
                symbolNum = symbolNum + 1
            end
            if symbolNum >= 2 then
                endCol = iCol
                break
            end
        end
        if endCol > 0 then
            break
        end
    end
    return endCol
end
--根据关卡玩法重新设置滚动信息
function CodeGameScreenZeusVsHadesMachine:MachineRule_ResetReelRunData()
    local endCol = self:getSymbolEndCol(self.SYMBOL_SCORE_BONUS)
    if endCol > 0 then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]
            local reelLongRunTime = 1

            if iCol > endCol then
                local iRow = columnData.p_showGridCount
                local lastColLens = reelRunInfo[1]:getReelRunLen()
                if iCol ~= 1 then
                    lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                    reelRunInfo[iCol - 1]:setNextReelLongRun(true)
                    reelLongRunTime = 1
                end

                local colHeight = columnData.p_slotColumnHeight
                local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                local runLen = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高

                local preRunLen = reelRunData:getReelRunLen()
                reelRunData:setReelRunLen(runLen)

                if endCol ~= iCol then
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
                end
            else
                local lastColLens = reelRunInfo[endCol]:getReelRunLen()
                local preRunLen = reelRunInfo[iCol].initInfo.reelRunLen
                local preEndColRunLen = reelRunInfo[endCol].initInfo.reelRunLen
                local addRunLen = preRunLen - preEndColRunLen

                reelRunData:setReelRunLen(lastColLens + addRunLen)
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end
        end
    end
end

-- -- 显示大赢动画
-- function CodeGameScreenZeusVsHadesMachine:showEffect_BigWin(effectData)
--     self.m_roomPlayerList:showSelfBigWinAni("BIG_WIN")
--     return CodeGameScreenZeusVsHadesMachine.super.showEffect_BigWin(self,effectData)
-- end
-- function CodeGameScreenZeusVsHadesMachine:showEffect_MegaWin(effectData)
--     self.m_roomPlayerList:showSelfBigWinAni("MAGE_WIN")
--     return CodeGameScreenZeusVsHadesMachine.super.showEffect_MegaWin(self,effectData)
-- end

-- function CodeGameScreenZeusVsHadesMachine:showEffect_EpicWin(effectData)
--     self.m_roomPlayerList:showSelfBigWinAni("EPIC_WIN")
--     return CodeGameScreenZeusVsHadesMachine.super.showEffect_EpicWin(self,effectData)
-- end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenZeusVsHadesMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end
    if self.m_runSpinResultData and self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
        if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end
return CodeGameScreenZeusVsHadesMachine
