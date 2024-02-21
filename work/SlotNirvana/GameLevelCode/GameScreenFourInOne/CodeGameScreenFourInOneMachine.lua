---
-- island li
-- 2019年1月26日
-- CodeGameScreenFourInOneMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
-- local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseDialog = util_require("Levels.BaseDialog")

local respinReel = 1
local BaseReel = 2
local FsLittle = 3
local FsBig = 4

local CodeGameScreenFourInOneMachine = class("CodeGameScreenFourInOneMachine", BaseFastMachine)

CodeGameScreenFourInOneMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_A1 = 100
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_A2 = 101
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_A3 = 102
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_A4 = 103
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_A5 = 104
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_B1 = 105
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_B2 = 106
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_B3 = 107
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_B4 = 108
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_B5 = 109
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_SC = 190
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_WILD = 192
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_BONUS = 194
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_ALL = 1105
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_GRAND = 1104
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_MINOR = 1102
CodeGameScreenFourInOneMachine.SYMBOL_ChilliFiesta_MINI = 1101

CodeGameScreenFourInOneMachine.SYMBOL_Charms_P1 = 200
CodeGameScreenFourInOneMachine.SYMBOL_Charms_P2 = 201
CodeGameScreenFourInOneMachine.SYMBOL_Charms_P3 = 202
CodeGameScreenFourInOneMachine.SYMBOL_Charms_P4 = 203
CodeGameScreenFourInOneMachine.SYMBOL_Charms_P5 = 204
CodeGameScreenFourInOneMachine.SYMBOL_Charms_Ace = 205
CodeGameScreenFourInOneMachine.SYMBOL_Charms_King = 206
CodeGameScreenFourInOneMachine.SYMBOL_Charms_Queen = 207
CodeGameScreenFourInOneMachine.SYMBOL_Charms_Jack = 208
CodeGameScreenFourInOneMachine.SYMBOL_Charms_Scatter = 290
CodeGameScreenFourInOneMachine.SYMBOL_Charms_Wild = 292
CodeGameScreenFourInOneMachine.SYMBOL_Charms_bonus = 294

CodeGameScreenFourInOneMachine.SYMBOL_Charms_MINOR = 2104
CodeGameScreenFourInOneMachine.SYMBOL_Charms_MINI = 2103
CodeGameScreenFourInOneMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
CodeGameScreenFourInOneMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
CodeGameScreenFourInOneMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
CodeGameScreenFourInOneMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
CodeGameScreenFourInOneMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
CodeGameScreenFourInOneMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
CodeGameScreenFourInOneMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号

CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_Wild = 392
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_H1 = 300
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_H2 = 301
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_H3 = 302
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_L1 = 303
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_L2 = 304
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_L3 = 305
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_L4 = 306
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_L5 = 307
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_L6 = 308
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_SC = 390
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_Bonus = 394
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_MINI = 3102
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_MINOR = 3103
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_MAJOR = 3104
CodeGameScreenFourInOneMachine.SYMBOL_HowlingMoon_GRAND = 3105

CodeGameScreenFourInOneMachine.SYMBOL_Pomi_Scatter = 490
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_H1 = 400
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_H2 = 401
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_H3 = 402
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_H4 = 403
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_L1 = 404
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_L2 = 405
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_L3 = 406
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_L4 = 407
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_L5 = 408
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_Wild = 492
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_Bonus = 494
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_GRAND = 4104
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_MAJOR = 4103
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_MINOR = 4102
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_MINI = 4101
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
CodeGameScreenFourInOneMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

CodeGameScreenFourInOneMachine.m_baseLittleReelsList = {}
CodeGameScreenFourInOneMachine.m_FSLittleReelsList = {}
CodeGameScreenFourInOneMachine.m_LinkBigReels = nil
CodeGameScreenFourInOneMachine.m_fsBigReel = nil

CodeGameScreenFourInOneMachine.m_reelsTypeList = {"HowlingMoon", "Pomi", "ChilliFiesta", "Charms"}

CodeGameScreenFourInOneMachine.m_baseLittleReelsDownIndex = 0 -- baseReels停止计数
CodeGameScreenFourInOneMachine.m_baseLittleReelsShowSpinIndex = 0 -- baseReels显示计数

CodeGameScreenFourInOneMachine.m_FSLittleReelsDownIndex = 0 -- FS停止计数
CodeGameScreenFourInOneMachine.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数

CodeGameScreenFourInOneMachine.FS_LockWild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"

--小块
function CodeGameScreenFourInOneMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end

-- 构造函数
function CodeGameScreenFourInOneMachine:ctor()
    BaseFastMachine.ctor(self)

    --init
    self:initGame()
end

function CodeGameScreenFourInOneMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOneConfig.csv", "LevelFourInOneConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_baseLittleReelsList = {}
    self.m_FSLittleReelsList = {}
    self.m_LinkBigReels = nil
    self.m_fsBigReel = nil

    self.m_reelsTypeList = {"HowlingMoon", "Pomi", "ChilliFiesta", "Charms"}
    self.m_baseLittleReelsDownIndex = 0
    self.m_baseLittleReelsShowSpinIndex = 0

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数
    self.m_respinOverRunning = false
    self.isInBonus = false
    self.m_isFeatureOverBigWinInFree = true
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFourInOneMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function CodeGameScreenFourInOneMachine:initBaseLittleReels()
    self:changeBaseReelsBg()

    for i = 1, #self.m_reelsTypeList do
        local className = "CodeFourInOneSrc.BaseReels.FourInOneBaseMiniMachine"
        local reelData = {}
        reelData.reelType = self.m_reelsTypeList[i]
        reelData.reelId = i
        reelData.parent = self
        local miniReel = util_createView(className, reelData)
        self:findChild("reel_" .. i):addChild(miniReel)

        if globalData.slotRunData.machineData.p_portraitFlag then
            miniReel.getRotateBackScaleFlag = function()
                return false
            end
        end

        table.insert(self.m_baseLittleReelsList, miniReel)

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local reelResult = selfdata.sets
        if reelResult then
            miniReel:SpinResultParseResultData(reelResult[i])
        end

        miniReel:enterSelfLevel()
        if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
            self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniReel.m_touchSpinLayer)
        end
        
    end
end

function CodeGameScreenFourInOneMachine:initFSBigReels()
    -- 初始化 fs 大轮子
    local className = "CodeFourInOneSrc.FsReels.FourInOneFSMiniMachine"
    local reelData = {}
    reelData.FSBig = true
    reelData.reelType = "_FS"
    reelData.reelId = 1
    reelData.parent = self
    local miniReel = util_createView(className, reelData)
    self:findChild("fs_Big_reel"):addChild(miniReel)

    if globalData.slotRunData.machineData.p_portraitFlag then
        miniReel.getRotateBackScaleFlag = function()
            return false
        end
    end

    self.m_fsBigReel = miniReel
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniReel.m_touchSpinLayer)
    end
    
end

function CodeGameScreenFourInOneMachine:initFSLittleReels()
    for i = 1, 4 do
        local className = "CodeFourInOneSrc.FsReels.FourInOneFSMiniMachine"
        local reelData = {}
        reelData.reelType = "_FS"
        reelData.reelId = i
        reelData.parent = self
        local miniReel = util_createView(className, reelData)
        self:findChild("fs_small_reel_" .. i):addChild(miniReel)

        if globalData.slotRunData.machineData.p_portraitFlag then
            miniReel.getRotateBackScaleFlag = function()
                return false
            end
        end


        table.insert( self.m_FSLittleReelsList, miniReel )

        if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
            self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniReel.m_touchSpinLayer) 
        end
        
    end
end

function CodeGameScreenFourInOneMachine:initFSReelsLockWildFromNetNetData()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wheelRewordType = fsExtraData.mode
    local wildPositions = fsExtraData.wildPositions

    if wheelRewordType then
        if wheelRewordType == "Free" then
            if self.m_fsBigReel and wildPositions and wildPositions[1] then
                self.m_fsBigReel:initFsLockWild(wildPositions[1])
            end
        elseif wheelRewordType == "SuperFree" then
            for i = 1, #self.m_FSLittleReelsList do
                local FsLittleReel = self.m_FSLittleReelsList[i]
                if FsLittleReel and wildPositions and wildPositions[i] then
                    FsLittleReel:initFsLockWild(wildPositions[i])
                end
            end
        end
    end
end

function CodeGameScreenFourInOneMachine:initFSReelsFromNetNetData()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wheelRewordType = fsExtraData.mode

    if wheelRewordType then
        if wheelRewordType == "Free" then
            self:findChild("fs_Big_reel_coins"):setVisible(true)

            self:changeBgToNormalFreespinStart()

            self:initFSBigReels()
            self:checkShowReels(FsBig)
        elseif wheelRewordType == "SuperFree" then
            self:changeBgToSuperFreespinStart()
            -- 初始化 fs 小轮子
            self:initFSLittleReels()
            self:checkShowReels(FsLittle)
        end
    end
end

function CodeGameScreenFourInOneMachine:initLinkBigReels(linkType)
    self.m_linkReelsList = {"HowlingMoon", "Pomi", "ChilliFiesta", "Charms"}

    self:checkShowReels(respinReel)

    for i = 1, 4 do
        local linkReelId = self.m_linkReelsList[i]

        if linkType == linkReelId then
            local className = "CodeFourInOneSrc.LinkReels.FourInOne" .. linkReelId .. "MiniMachine"
            local reelData = {}
            reelData.reelType = linkReelId
            reelData.reelId = i
            reelData.parent = self
            local miniReel = util_createView(className, reelData)
            self:findChild(linkReelId .. "_Link_Big_reel"):addChild(miniReel)

            if globalData.slotRunData.machineData.p_portraitFlag then
                miniReel.getRotateBackScaleFlag = function()
                    return false
                end
            end

            self.m_LinkBigReels = miniReel

            if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniReel.m_touchSpinLayer)
            end
            
        end
    end
end

function CodeGameScreenFourInOneMachine:initUI()
    self:findChild("fs_Big_reel_coins"):setVisible(false)
    self:addClick(self:findChild("Click_Choose"))

    self.m_chooseBntAct = util_createAnimation("FourInOne_Choose_btn.csb")

    self:findChild("chooseBntAct"):addChild(self.m_chooseBntAct)
    -- 把控制类的轮盘隐藏掉
    self:findChild("Node_base_noUseReels"):setVisible(false)

    -- jackpotbar
    self.m_jackPorBar = util_createView("CodeFourInOneSrc.FourInOneJPBarView")
    self:findChild("4in1_jackpot"):addChild(self.m_jackPorBar)
    self.m_jackPorBar:initMachine(self)
    self.m_jackPorBar:runCsbAction("animation0", true)

    if display.height >= 1536 and display.height < 1560 then
        self:findChild("4in1_jackpot"):setScale(0.95)
    end

    self:checkShowReels(BaseReel)

    self.m_GuoChangView = util_createView("CodeFourInOneSrc.FourInOneGuoChangView")
    self:findChild("GuoChang"):addChild(self.m_GuoChangView)
    self.m_GuoChangView:setVisible(false)

    self.m_Fsbar = util_createView("CodeFourInOneSrc.FsReels.FourInOne_FS_TimeisBarView")
    self:findChild("freespin_text"):addChild(self.m_Fsbar)
    self.m_Fsbar:setVisible(false)
    self:initFreeSpinBar() -- FreeSpinbar
    self.m_baseFreeSpinBar = self.m_Fsbar

    
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false)
    end
    -- 创建view节点方式
    -- self.m_FourInOneView = util_createView("CodeFourInOneSrc.FourInOneView")
    -- self:findChild("xxxx"):addChild(self.m_FourInOneView)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_respinOverRunning then
                return
            end
            if self:getCurrSpinMode() == RESPIN_MODE then
                return
            end

            if self.m_bIsBigWin then
                self.m_light_left:runCsbAction("bigwin", true)
                self.m_light_reight:runCsbAction("bigwin", true)

                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 2
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
                soundTime = 3
            elseif winRate > 6 then
                soundIndex = 3
                soundTime = 5
            end

            local soundName = "FourInOneSounds/music_FourInOne_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
            performWithDelay(
                self,
                function()
                    self.m_winSoundsId = nil
                end,
                soundTime
            )

            if winRate and winRate > 0 then
                self.m_light_left:runCsbAction("littlewin", true)
                self.m_light_reight:runCsbAction("littlewin", true)
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenFourInOneMachine:enterGamePlayMusic()
    if not self.isInBonus then
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_enter.mp3")
                scheduler.performWithDelayGlobal(
                    function()
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    end,
                    2.5,
                    self:getModuleName()
                )
            end,
            0.4,
            self:getModuleName()
        )
    end
end

function CodeGameScreenFourInOneMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenFourInOneMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            local flag = params
            if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
                flag = false
            end

            self.m_chooseBntAct:findChild("Sprite_2"):setVisible(flag)

            self:findChild("Click_Choose"):setTouchEnabled(flag)

            -- self:findChild("Click_Choose"):setVisible(flag)
        end,
        "BET_ENABLE"
    )
end

function CodeGameScreenFourInOneMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFourInOneMachine:MachineRule_GetSelfCCBName(symbolType)
    if self.SYMBOL_ChilliFiesta_A1 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_9"
    elseif self.SYMBOL_ChilliFiesta_A2 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_8"
    elseif self.SYMBOL_ChilliFiesta_A3 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_7"
    elseif self.SYMBOL_ChilliFiesta_A4 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_6"
    elseif self.SYMBOL_ChilliFiesta_A5 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_5"
    elseif self.SYMBOL_ChilliFiesta_B1 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_4"
    elseif self.SYMBOL_ChilliFiesta_B2 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_3"
    elseif self.SYMBOL_ChilliFiesta_B3 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_2"
    elseif self.SYMBOL_ChilliFiesta_B4 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_1"
    elseif self.SYMBOL_ChilliFiesta_B5 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_10"
    elseif self.SYMBOL_ChilliFiesta_SC == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Scatter"
    elseif self.SYMBOL_ChilliFiesta_WILD == symbolType then
        return "4in1_Socre_ChilliFiesta_Wild"
    elseif self.SYMBOL_ChilliFiesta_BONUS == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus"
    elseif symbolType == self.SYMBOL_ChilliFiesta_GRAND then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_2"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MAJOR then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_3"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MINOR then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_5"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MINI then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_4"
    elseif symbolType == self.SYMBOL_ChilliFiesta_ALL then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_6"
    elseif self.SYMBOL_Charms_P1 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_9"
    elseif self.SYMBOL_Charms_P2 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_8"
    elseif self.SYMBOL_Charms_P3 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_7"
    elseif self.SYMBOL_Charms_P4 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_6"
    elseif self.SYMBOL_Charms_P5 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_5"
    elseif self.SYMBOL_Charms_Ace == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_4"
    elseif self.SYMBOL_Charms_King == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_3"
    elseif self.SYMBOL_Charms_Queen == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_2"
    elseif self.SYMBOL_Charms_Jack == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_1"
    elseif self.SYMBOL_Charms_Scatter == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Scatter"
    elseif self.SYMBOL_Charms_Wild == symbolType then
        return "4in1_Socre_Charms_Wild"
    elseif self.SYMBOL_Charms_bonus == math.abs(symbolType) then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_2"
    elseif symbolType == self.SYMBOL_Charms_UNLOCK_SYMBOL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_" .. math.random(1, 4)
    elseif symbolType == self.SYMBOL_Charms_NULL_LOCK_SYMBOL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_" .. math.random(1, 4)
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_DOUBLE then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_3"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINOR then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_minor"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINOR_DOUBLE then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_minor"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINI then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_mini"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_BOOM then
        return "4in1_Socre_Charms_Boom1"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_NULL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_NULL"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_BOOM_RUN then
        return "4in1_Socre_Charms_Boom1"
    elseif self.SYMBOL_HowlingMoon_Wild == symbolType then
        return "4in1_Socre_HowlingMoon_Wild"
    elseif self.SYMBOL_HowlingMoon_H1 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_9"
    elseif self.SYMBOL_HowlingMoon_H2 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_8"
    elseif self.SYMBOL_HowlingMoon_H3 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_7"
    elseif self.SYMBOL_HowlingMoon_L1 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_6"
    elseif self.SYMBOL_HowlingMoon_L2 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_5"
    elseif self.SYMBOL_HowlingMoon_L3 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_4"
    elseif self.SYMBOL_HowlingMoon_L4 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_3"
    elseif self.SYMBOL_HowlingMoon_L5 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_2"
    elseif self.SYMBOL_HowlingMoon_L6 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_1"
    elseif self.SYMBOL_HowlingMoon_SC == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Scatter"
    elseif self.SYMBOL_HowlingMoon_Bonus == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_light"
    elseif symbolType == self.SYMBOL_HowlingMoon_MINI then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_mini"
    elseif symbolType == self.SYMBOL_HowlingMoon_MINOR then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_minor"
    elseif symbolType == self.SYMBOL_HowlingMoon_MAJOR then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_major"
    elseif symbolType == self.SYMBOL_HowlingMoon_GRAND then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_grand"
    elseif self.SYMBOL_Pomi_Scatter == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Scatter"
    elseif self.SYMBOL_Pomi_H1 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_9"
    elseif self.SYMBOL_Pomi_H2 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_8"
    elseif self.SYMBOL_Pomi_H3 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_7"
    elseif self.SYMBOL_Pomi_H4 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_6"
    elseif self.SYMBOL_Pomi_L1 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_5"
    elseif self.SYMBOL_Pomi_L2 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_4"
    elseif self.SYMBOL_Pomi_L3 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_3"
    elseif self.SYMBOL_Pomi_L4 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_2"
    elseif self.SYMBOL_Pomi_L5 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_1"
    elseif self.SYMBOL_Pomi_Wild == symbolType then
        return "4in1_Socre_Pomi_Wild"
    elseif self.SYMBOL_Pomi_Bonus == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Num"
    elseif symbolType == self.SYMBOL_Pomi_GRAND then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Grand"
    elseif symbolType == self.SYMBOL_Pomi_MAJOR then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Major"
    elseif symbolType == self.SYMBOL_Pomi_MINOR then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Minor"
    elseif symbolType == self.SYMBOL_Pomi_MINI then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Mini"
    elseif symbolType == self.SYMBOL_Pomi_Reel_Up then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_reel_up"
    elseif symbolType == self.SYMBOL_Pomi_Double_bet then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_DoubleBet"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFourInOneMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A4,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A5,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B4,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B5,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_SC,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_WILD,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_BONUS,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_ALL,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_GRAND,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_MAJOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_MINOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_MINI,count =  2}

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P4,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P5,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Ace,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_King,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Queen,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Jack,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Scatter,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Wild,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_bonus,count =  2}

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_MINOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_MINI,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_MINOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_MINI,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_MINOR_DOUBLE,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_DOUBLE,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_MINOR_DOUBLE,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_SYMBOL_DOUBLE,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_BOOM,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_NULL,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_BOOM_RUN,count =  2}

    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_UNLOCK_SYMBOL, count = 12}
    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_NULL_LOCK_SYMBOL, count = 12}

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_Wild,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_H1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_H2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_H3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L4,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L5,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L6,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_SC,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_Bonus,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_MINI,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_MINOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_MAJOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_GRAND,count =  2}

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Scatter,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H4,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L1,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L2,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L3,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L4,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L5,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Wild,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Bonus,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_GRAND,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_MAJOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_MINOR,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_MINI,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Reel_Up,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Double_bet,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenFourInOneMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:findChild("Click_Choose"):setVisible(false)

        self.m_gameLightBg:findChild("Base_Bg_Img"):setVisible(false)
        self.m_gameLightBg:findChild("Fs_Bg_Img"):setVisible(true)

        self.m_gameLightBg:findChild("Sprite_11"):setVisible(false)
        self.m_gameLightBg:findChild("Sprite_112121"):setVisible(false)

        self.m_jackPorBar:setVisible(false)

        self:updateFreeSpinBarPos()

        self:changeReelsQuickStopStates(false)

        self:initFSReelsFromNetNetData()

        self:initFSReelsLockWildFromNetNetData()

        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenFourInOneMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self, reelCol)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFourInOneMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFourInOneMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

function CodeGameScreenFourInOneMachine:updateFreeSpinBarPos()
    local pos = cc.p(self:findChild("freespin_text_Fs"):getPosition())
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wheelRewordType = fsExtraData.mode

    if wheelRewordType then
        if wheelRewordType == "SuperFree" then
            pos = cc.p(self:findChild("freespin_text_SupperFs"):getPosition())
        else
            pos = cc.p(self:findChild("freespin_text_Fs"):getPosition())
        end
    end

    self:findChild("freespin_text"):setPosition(pos)
end

function CodeGameScreenFourInOneMachine:showFreeSpinStart(num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local fsViewName = BaseDialog.DIALOG_TYPE_FREESPIN_START

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wheelRewordType = fsExtraData.mode

    if wheelRewordType then
        if wheelRewordType == "SuperFree" then
            fsViewName = "Super_FreeSpinStart"
        end
    end

    return self:showDialog(fsViewName, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

---
-- 显示free spin
function CodeGameScreenFourInOneMachine:showEffect_FreeSpin(effectData)
    self.isInBonus = true

    return BaseMachineGameEffect.showEffect_FreeSpin(self, effectData)
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFourInOneMachine:showFreeSpinView(effectData)
    self:findChild("Click_Choose"):setVisible(false)

    -- gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_custom_enter_fs.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self:updateFreeSpinBarPos()

            gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_OpenView.mp3")

            self:showFreeSpinStart(
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    self:showGuoChang(
                        function()
                            self.m_gameLightBg:findChild("Base_Bg_Img"):setVisible(false)
                            self.m_gameLightBg:findChild("Fs_Bg_Img"):setVisible(true)

                            self.m_gameLightBg:findChild("Sprite_11"):setVisible(false)
                            self.m_gameLightBg:findChild("Sprite_112121"):setVisible(false)

                            local betValue = globalData.slotRunData:getCurTotalBet()
                            self.m_bottomUI:updateTotalBet(betValue / 4)

                            self.m_jackPorBar:setVisible(false)

                            performWithDelay(
                                self,
                                function()
                                    if self.m_WheelBgView then
                                        self.m_WheelBgView:removeFromParent()
                                        self.m_WheelBgView = nil
                                    end
                                end,
                                0
                            )

                            self:initFSReelsFromNetNetData()

                            self:changeReelsQuickStopStates(false)

                            -- 保留freespin 数量信息
                            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

                            performWithDelay(
                                self,
                                function()
                                    self:triggerFreeSpinCallFun()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end,
                                0.5
                            )
                        end
                    )
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        0.5
    )
end

function CodeGameScreenFourInOneMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)

    local fsViewName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wheelRewordType = fsExtraData.mode

    if wheelRewordType then
        if wheelRewordType == "SuperFree" then
            fsViewName = "Super_FreeSpinOver"
        end
    end

    return self:showDialog(fsViewName, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

---
-- 显示free spin over 动画
function CodeGameScreenFourInOneMachine:showEffect_FreeSpinOver()
    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")

    local lines = {}
    if self.m_fsBigReel then
        local miniReelslines = self.m_fsBigReel:getResultLines()
        if miniReelslines then
            for i = 1, #miniReelslines do
                table.insert(lines, miniReelslines[i])
            end
        end
    else
        for i = 1, #self.m_FSLittleReelsList do
            local reels = self.m_FSLittleReelsList[i]
            local miniReelslines = reels:getResultLines()

            if miniReelslines then
                for i = 1, #miniReelslines do
                    table.insert(lines, miniReelslines[i])
                end
            end
        end
    end

    if #lines == 0 then
        self.m_freeSpinOverCurrentTime = 1
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
        self.m_fsOverHandlerID =
            scheduler.scheduleGlobal(
            function()
                if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
                    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
                else
                    self:showEffect_newFreeSpinOver()
                end
            end,
            0.1
        )
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenFourInOneMachine:showFreeSpinOverView()
    if self.m_gameEffects and #self.m_gameEffects > 0 then
        for i = #self.m_gameEffects, 1, -1 do
            local effect = self.m_gameEffects[i]
            if effect and effect.p_isPlay then
                table.remove(self.m_gameEffects, i)
            end
        end
    end

    gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_OpenView.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:showGuoChang(
                function()
                    self:findChild("fs_Big_reel_coins"):setVisible(false)

                    self.m_gameLightBg:findChild("Base_Bg_Img"):setVisible(true)
                    self.m_gameLightBg:findChild("Fs_Bg_Img"):setVisible(false)

                    self.m_gameLightBg:findChild("Sprite_11"):setVisible(true)
                    self.m_gameLightBg:findChild("Sprite_112121"):setVisible(true)

                    local betValue = globalData.slotRunData:getCurTotalBet()
                    self.m_bottomUI:updateTotalBet(betValue)

                    self:findChild("Click_Choose"):setVisible(true)

                    self.m_jackPorBar:setVisible(true)

                    for i = 1, #self.m_baseLittleReelsList do
                        local baseLittleReel = self.m_baseLittleReelsList[i]
                        baseLittleReel:clearLittleReelsLinesEffect()
                    end

                    -- 在完成freespinoverEffect之前 添加下一个effect(处理同时触发的情况)
                    self:featuresOverAddFreespinEffect()

                    self:removeAllFSReels()

                    self:checkShowReels(BaseReel)

                    self:triggerFreeSpinOverCallFun()

                    self:changeReelsQuickStopStates(true)

                    self:changeBgToFreespinOver()
                end
            )
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFourInOneMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.isInBonus = false
    self.m_respinOverRunning = false
    self.m_bIsBigWin = false

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_light_left:runCsbAction("idleframe", true)
    self.m_light_reight:runCsbAction("idleframe", true)

    self.m_baseLittleReelsDownIndex = 0
    self.m_baseLittleReelsShowSpinIndex = 0

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数

    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFourInOneMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFourInOneMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

function CodeGameScreenFourInOneMachine:checkIsAddFsWildLock()
    local isAddEffect = false

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local wheelRewordType = fsExtraData.mode

        if wheelRewordType then
            if wheelRewordType == "Free" then
                if self.m_fsBigReel then
                    self.m_fsBigReel:setWildList()
                    if self.m_fsBigReel.m_lockWildList and #self.m_fsBigReel.m_lockWildList > 0 then
                        isAddEffect = true
                    end
                end
            elseif wheelRewordType == "SuperFree" then
                if self.m_FSLittleReelsList and #self.m_FSLittleReelsList > 0 then
                    for i = 1, #self.m_FSLittleReelsList do
                        local FsLittleReel = self.m_FSLittleReelsList[i]
                        if FsLittleReel then
                            FsLittleReel:setWildList()

                            if FsLittleReel.m_lockWildList and #FsLittleReel.m_lockWildList > 0 then
                                isAddEffect = true
                            end
                        end
                    end
                end
            end
        end
    end

    return isAddEffect
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFourInOneMachine:addSelfEffect()
    if self:checkIsAddFsWildLock() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FS_LockWild_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFourInOneMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.FS_LockWild_EFFECT then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local wheelRewordType = fsExtraData.mode

        if wheelRewordType then
            if wheelRewordType == "Free" then
                if self.m_fsBigReel then
                    self.m_fsBigReel:updateFsLockWild(self.m_fsBigReel.m_lockWildList)
                end

                performWithDelay(
                    self,
                    function()
                        self.m_fsBigReel:restSelfGameEffects(self.FS_LockWild_EFFECT)

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    0.5
                )
            elseif wheelRewordType == "SuperFree" then
                if self.m_FSLittleReelsList and #self.m_FSLittleReelsList > 0 then
                    for i = 1, #self.m_FSLittleReelsList do
                        local FsLittleReel = self.m_FSLittleReelsList[i]
                        if FsLittleReel then
                            if FsLittleReel.m_lockWildList and #FsLittleReel.m_lockWildList > 0 then
                                FsLittleReel:updateFsLockWild(FsLittleReel.m_lockWildList)
                            end
                        end
                    end
                end

                performWithDelay(
                    self,
                    function()
                        for i = 1, #self.m_FSLittleReelsList do
                            local FsLittleReel = self.m_FSLittleReelsList[i]
                            if FsLittleReel then
                                FsLittleReel:restSelfGameEffects(self.FS_LockWild_EFFECT)
                            end
                        end

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    0.5
                )
            end
        end
    end

    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFourInOneMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenFourInOneMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(0, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--- 滚动处理
function CodeGameScreenFourInOneMachine:beginReel()
    self:resetReelDataAfterReel()

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)

        self:resetParentDataReel(parentData)
    end

    -- 处理轮子滚动

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
        local wheelRewordType = fsExtraData.mode

        if wheelRewordType then
            if wheelRewordType == "Free" then
                if self.m_fsBigReel then
                    self.m_fsBigReel:beginMiniReel()
                end
            elseif wheelRewordType == "SuperFree" then
                if self.m_FSLittleReelsList and #self.m_FSLittleReelsList > 0 then
                    for i = 1, #self.m_FSLittleReelsList do
                        local FsLittleReel = self.m_FSLittleReelsList[i]
                        FsLittleReel:beginMiniReel()
                    end
                end
            end
        end
    else
        for i = 1, #self.m_baseLittleReelsList do
            local baseLittleReel = self.m_baseLittleReelsList[i]
            baseLittleReel:beginMiniReel()
        end
    end
end

function CodeGameScreenFourInOneMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()

    for i = 1, #self.m_reelsTypeList do
        local reelsType = self.m_reelsTypeList[i]
        print("第几个 " .. i .. " 类型" .. reelsType)
        release_print("第几个 " .. i .. " 类型" .. reelsType)
    end

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        clickPos = self.m_reelsTypeList
    } -- clickPos:base小轮子类型列表
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenFourInOneMachine:updateBaseLittleSpinResult(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.sets then
                    local datas = spinData.result.selfData.sets

                    for i = 1, #self.m_baseLittleReelsList do
                        local miniReelsData = datas[i]
                        miniReelsData.bet = 0
                        miniReelsData.payLineCount = 0
                        local reels = self.m_baseLittleReelsList[i]
                        reels:netWorkCallFun(miniReelsData)
                    end
                end
            end
        end
    end
end

function CodeGameScreenFourInOneMachine:updateFSLittleSpinResult(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.freeSets then
                    local wheelRewordType = spinData.result.freespin.extra.mode
                    local datas = spinData.result.selfData.freeSets

                    if wheelRewordType then
                        if wheelRewordType == "SuperFree" then
                            if self.m_FSLittleReelsList and #self.m_FSLittleReelsList > 0 then
                                for i = 1, #self.m_FSLittleReelsList do
                                    local FsLittleReel = self.m_FSLittleReelsList[i]
                                    local miniReelsData = datas[i]
                                    miniReelsData.bet = 0
                                    miniReelsData.payLineCount = 0
                                    FsLittleReel:netWorkCallFun(miniReelsData)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenFourInOneMachine:updateFSBigSpinResult(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.freeSet then
                    local wheelRewordType = spinData.result.freespin.extra.mode
                    if wheelRewordType then
                        if wheelRewordType == "Free" then
                            if self.m_fsBigReel then
                                local miniReelsData = spinData.result.selfData.freeSet
                                miniReelsData.bet = 0
                                miniReelsData.payLineCount = 0
                                self.m_fsBigReel:netWorkCallFun(miniReelsData)
                            end
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenFourInOneMachine:updateLinkBigSpinResult(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.linkSets then
                    local features = spinData.result.features

                    local linkPosition = tostring(spinData.result.selfData.linkPosition)
                    local triggerPosition = tostring(spinData.result.selfData.triggerPosition)

                    if features and #features > 1 and features[2] == RESPIN_MODE then
                        self.m_respinTriggerData = spinData.result.selfData.linkSets[triggerPosition] -- 只在respin触发时作为赋值数据
                    end

                    if self.m_LinkBigReels then
                        local miniReelsData = spinData.result.selfData.linkSets[linkPosition]
                        miniReelsData.bet = 0
                        miniReelsData.payLineCount = 0
                        self.m_LinkBigReels:netWorkCallFun(miniReelsData)
                    end
                end
            end
        end
    end
end

--接收到数据开始停止滚动
function CodeGameScreenFourInOneMachine:stopRespinRun()
end

---
-- 处理spin 返回结果
function CodeGameScreenFourInOneMachine:spinResultCallFun(param)
    self:updateLinkBigSpinResult(param)

    BaseFastMachine.spinResultCallFun(self, param)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:updateFSLittleSpinResult(param)
        self:updateFSBigSpinResult(param)
    elseif self:getCurrSpinMode() == RESPIN_MODE then
    elseif self.m_WheelBgView then
    else
        self:updateBaseLittleSpinResult(param)
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenFourInOneMachine:initGameStatusData(gameData)
    BaseFastMachine.initGameStatusData(self, gameData)

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local reelTypeList = selfData.games

    -- self.m_reelsTypeList:整个游戏就维护这一个游戏列表
    if reelTypeList then
        self.m_reelsTypeList = reelTypeList
    else
        if gameData.gameConfig ~= nil and gameData.gameConfig.init ~= nil and gameData.gameConfig.init.defaultGames ~= nil then
            self.m_reelsTypeList = gameData.gameConfig.init.defaultGames
        end
    end

    if gameData then
        local spinData = gameData.spin
        if spinData then
            if spinData.selfData then
                if spinData.selfData.linkSets then
                    local features = spinData.features

                    local linkPosition = tostring(spinData.selfData.linkPosition)
                    local triggerPosition = tostring(spinData.selfData.triggerPosition)

                    if features and #features > 1 and features[2] == RESPIN_MODE then
                        self.m_respinTriggerData = spinData.selfData.linkSets[triggerPosition] -- respin触发时短线
                    else
                        self.m_respinTriggerData = spinData.selfData.linkSets[linkPosition] -- respin过程中短线
                    end
                end
            end
        end
    end

    -- 初始化小轮子
    self:initBaseLittleReels()

    self:changeReelsQuickStopStates(true)
end

-- 创建大圆盘界面
function CodeGameScreenFourInOneMachine:createWheelView(func, time)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local wheels = selfdata.wheels

    local WheelInfo = {}
    WheelInfo.wheelData = wheels or {"Grand", "Major", "Minor", "Mini", "Free", "SuperFree", "Grand", "Major", "Minor", "Mini", "Free", "SuperFree"} --
    WheelInfo.machine = self

    self.m_WheelBgView = util_createView("CodeFourInOneSrc.Wheel.FourInOneBonus_WheelView", WheelInfo)
    self:findChild("4in1_wheel"):addChild(self.m_WheelBgView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_WheelBgView.getRotateBackScaleFlag = function()
            return false
        end
    end

    self.m_WheelBgView:setOverCall(
        function(isJpOver)
            if func then
                func(isJpOver)
            end
        end
    )

    local pos = util_getConvertNodePos(self.m_gameLightBg:findChild("Node_1"), self.m_WheelBgView)
    self.m_WheelBgView:setPosition(pos)
    self.m_WheelBgView:findChild("click"):setVisible(false)

    self:findChild("4in1_jackpot"):setLocalZOrder(2)
    self:findChild("4in1_wheel"):setLocalZOrder(1)

    local moveSize = (DESIGN_SIZE.height - 900)
    local addPos = display.height - DESIGN_SIZE.height
    if addPos > 0 then
        moveSize = moveSize + addPos
    end
    local sq1 =
        cc.Sequence:create(
        cc.MoveTo:create(time, cc.p(0, moveSize)),
        cc.MoveTo:create(0.5, cc.p(0, -30)),
        cc.MoveTo:create(0.1, cc.p(0, 0)),
        cc.CallFunc:create(
            function()
                self.m_jackPorBar:setPosition(0, 0)
                self:findChild("4in1_jackpot"):setLocalZOrder(1)
                self:findChild("4in1_wheel"):setLocalZOrder(2)
            end
        )
    )
    self.m_jackPorBar:runAction(sq1)

    local sq =
        cc.Sequence:create(
        cc.DelayTime:create(time),
        cc.MoveTo:create(0.5, cc.p(0, -30)),
        cc.MoveTo:create(0.1, cc.p(0, 0)),
        cc.CallFunc:create(
            function()
                self.m_WheelBgView:findChild("click"):setVisible(true)
            end
        )
    )
    self.m_WheelBgView:runAction(sq)
end

--freespin下主轮调用父类停止函数
function CodeGameScreenFourInOneMachine:slotReelDownInLittleBaseReels()
    self:setGameSpinStage(STOP_RUN)
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
    self:reelDownNotifyPlayGameEffect()
end

function CodeGameScreenFourInOneMachine:baseReelDownNotify(maxCount)
    self.m_baseLittleReelsDownIndex = self.m_baseLittleReelsDownIndex + 1

    if self.m_baseLittleReelsDownIndex == maxCount then
        self.m_baseLittleReelsDownIndex = 0

        local isUpdateWinCoins = false
        for i = 1, #self.m_baseLittleReelsList do
            local reel = self.m_baseLittleReelsList[i]
            local lines = reel:getVecGetLineInfo()
            if lines and #lines > 0 then
                isUpdateWinCoins = true
            end

            reel:reelDownNotifyBaseReelsPlayGameEffect()
        end

        if isUpdateWinCoins then
            self:checkNotifyManagerUpdateWinCoin()
        end

        self:slotReelDownInLittleBaseReels()

        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )
    end
end

function CodeGameScreenFourInOneMachine:baseReelShowSpinNotify(maxCount)
    self.m_baseLittleReelsShowSpinIndex = self.m_baseLittleReelsShowSpinIndex + 1

    if self.m_baseLittleReelsShowSpinIndex == maxCount then
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)

        self.m_baseLittleReelsShowSpinIndex = 0
    end
end

function CodeGameScreenFourInOneMachine:FSReelDownNotify(maxCount)
    self.m_FSLittleReelsDownIndex = self.m_FSLittleReelsDownIndex + 1

    if self.m_FSLittleReelsDownIndex == maxCount then
        self.m_FSLittleReelsDownIndex = 0

        self:slotReelDownInLittleBaseReels()

        local isUpdateWinCoins = false
        if self.m_fsBigReel then
            local reel = self.m_fsBigReel
            local lines = reel:getVecGetLineInfo()
            if lines and #lines > 0 then
                isUpdateWinCoins = true
            end
        else
            for i = 1, #self.m_FSLittleReelsList do
                local reel = self.m_FSLittleReelsList[i]
                local lines = reel:getVecGetLineInfo()
                if lines and #lines > 0 then
                    isUpdateWinCoins = true
                    break
                end
            end
        end

        if self:checkIsAddFsWildLock() then
            if isUpdateWinCoins then
                performWithDelay(
                    self,
                    function()
                        self:checkNotifyManagerUpdateWinCoin()
                    end,
                    0.5
                )
            end
        else
            if isUpdateWinCoins then
                self:checkNotifyManagerUpdateWinCoin()
            end
        end
    end
end

function CodeGameScreenFourInOneMachine:FSReelShowSpinNotify(maxCount)
    self.m_FSLittleReelsShowSpinIndex = self.m_FSLittleReelsShowSpinIndex + 1

    if self.m_FSLittleReelsShowSpinIndex == maxCount then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
            end
        end

        self.m_FSLittleReelsShowSpinIndex = 0
    end
end

function CodeGameScreenFourInOneMachine:quicklyStopReel()
    -- 控制类不走快停

    self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。
end

-- ****************  bonus 处理
---
-- 显示bonus 触发的小游戏
function CodeGameScreenFourInOneMachine:showEffect_Bonus(effectData)
    local lines = {}
    local waitTimes = 0
    for i = 1, #self.m_baseLittleReelsList do
        local reels = self.m_baseLittleReelsList[i]
        local miniReelslines = reels:getResultLines()

        if miniReelslines then
            for i = 1, #miniReelslines do
                table.insert(lines, miniReelslines[i])
            end
        end
    end

    if lines ~= nil and #lines > 0 then
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = self.m_serverWinCoins / totalBet
        if winRate <= 0 then
            waitTimes = 0
        elseif winRate <= 1 then
            waitTimes = 1.7
        elseif winRate > 1 and winRate <= 3 then
            waitTimes = 1.7
        elseif winRate > 3 and winRate <= 6 then
            waitTimes = 3
        elseif winRate > 6 then
            waitTimes = 3
        end
    end

    performWithDelay(
        self,
        function()
            if globalData.slotRunData.currLevelEnter == FROM_QUEST then
                self.m_questView:hideQuestView()
            end

            self.isInBonus = true

            if self.m_winSoundsId then
                gLobalSoundManager:stopAudio(self.m_winSoundsId)
                self.m_winSoundsId = nil
            end

            self:findChild("Click_Choose"):setVisible(false)

            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local triggerPosition = selfdata.triggerPosition
            for i = 1, #self.m_baseLittleReelsList do
                local reelPos = triggerPosition + 1
                if i ~= reelPos then
                    local baseLittleReel = self.m_baseLittleReelsList[i]
                    baseLittleReel:clearLittleReelsLinesEffect()
                end
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
                if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                    bonusLineValue = lineValue
                    table.remove(self.m_reelResultLines, i)
                    break
                end
            end

            -- 停止播放背景音乐
            self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
            -- 播放bonus 元素不显示连线
            if bonusLineValue ~= nil then
                --self:showBonusAndScatterLineTip(bonusLineValue,function()
                self:showBonusGameView(effectData)
                --end)
                bonusLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
            else
                self:showBonusGameView(effectData)
            end

            gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
        end,
        waitTimes
    )

    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenFourInOneMachine:showBonusGameView(effectData)
    local showWheelView = function()
        -- self:showGuoChang(function(  )

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local triggerPosition = selfdata.triggerPosition

        if triggerPosition then
            local baseMiniReel = self.m_baseLittleReelsList[triggerPosition + 1]
            if baseMiniReel then
                baseMiniReel.m_triggerEffect:setVisible(false)
                baseMiniReel.m_triggerEffect:playAction("stop")
                baseMiniReel:hideRunDi()
            end
        end

        self.m_gameLightBg:findChild("Sprite_11"):setVisible(false)
        self.m_gameLightBg:findChild("Sprite_112121"):setVisible(false)

        performWithDelay(
            self,
            function()
                self.m_gameLightBg:findChild("Base_Bg_Img"):setLocalZOrder(-1)
                self.m_gameLightBg:findChild("Fs_Bg_Img"):setLocalZOrder(1)

                self.m_gameLightBg:findChild("Base_Bg_Img"):setVisible(true)
                self.m_gameLightBg:findChild("Fs_Bg_Img"):setVisible(true)
                self.m_gameLightBg:findChild("Fs_Bg_Img"):setOpacity(0)
                util_playFadeInAction(self.m_gameLightBg:findChild("Fs_Bg_Img"), 0.3)

                self:resetMusicBg(nil, "FourInOneSounds/music_FourInOne_Wheel_Bg.mp3")

                self.m_light_left:runCsbAction("lighting", true)
                self.m_light_reight:runCsbAction("lighting", true)

                for i = 1, 4 do
                    local reelNdoe = self:findChild("reel_" .. i)
                    if reelNdoe then
                        self:findChild("reel_" .. i):setVisible(false)
                    end
                end
                self:findChild("root_0_1"):setVisible(false)
            end,
            0.5
        )

        self:createWheelView(
            function(isJpOver)
                if self.m_WheelBgView and isJpOver then
                    self:showGuoChang(
                        function()
                            self.m_gameLightBg:findChild("Sprite_112121"):setVisible(true)
                            self.m_gameLightBg:findChild("Sprite_11"):setVisible(true)
                            self.m_light_left:runCsbAction("idleframe", true)
                            self.m_light_reight:runCsbAction("idleframe", true)

                            self.m_gameLightBg:findChild("Base_Bg_Img"):setVisible(true)
                            self.m_gameLightBg:findChild("Fs_Bg_Img"):setVisible(false)

                            effectData.p_isPlay = true
                            self:playGameEffect() -- 播放下一轮
                            self.m_WheelBgView:removeFromParent()
                            self.m_WheelBgView = nil
                            self:findChild("Click_Choose"):setVisible(true)

                            self:checkShowReels(BaseReel)

                            self:resetMusicBg()
                        end
                    )
                else
                    self.m_light_left:runCsbAction("idleframe", true)
                    self.m_light_reight:runCsbAction("idleframe", true)

                    effectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮
                end
            end,
            0.5
        )

        -- end)
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerPosition = selfdata.triggerPosition

    if triggerPosition then
        local baseMiniReel = self.m_baseLittleReelsList[triggerPosition + 1]
        if baseMiniReel then
            -- 播放提示时播放音效
            self:playBonusTipMusicEffect()

            baseMiniReel:showBaseMiniEffect_Bonus(showWheelView)
        end
    end
end

-- 更新控制类数据
function CodeGameScreenFourInOneMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function CodeGameScreenFourInOneMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    if
        self.m_respinTriggerData and self.m_respinTriggerData.respin and self.m_respinTriggerData.respin.reSpinsTotalCount ~= nil and self.m_respinTriggerData.respin.reSpinsTotalCount > 0 and
            self.m_respinTriggerData.respin.reSpinCurCount > 0
     then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenFourInOneMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    -- self:initCloumnSlotNodesByNetData()
end

function CodeGameScreenFourInOneMachine:initNoneFeature()
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end
    self:checkUpateDefaultBet()
    -- 直接使用 关卡bet 选择界面的bet 来使用
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    -- self:initRandomSlotNodes()
end

function CodeGameScreenFourInOneMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect = false
    local isPlayGameEffect = false

    if self.m_initSpinData ~= nil then
        -- 检测上次的feature 信息
        local isCheck = false

        if self.m_initFeatureData then
            if self.m_initFeatureData.p_data.selfData then
                if self.m_initFeatureData.p_data.selfData.wheelIndex then
                    -- 有轮盘位置说明刚触发完 收集轮盘
                    local wheelRewordType = self.m_initFeatureData.p_data.selfData.wheel
                    if wheelRewordType == "Free" or wheelRewordType == "SuperFree" then
                        -- 说明是 收集玩法触发的freespin 断线 添加bonus游戏事件
                        isCheck = true
                    else
                        if self.m_initFeatureData.p_data.features and #self.m_initFeatureData.p_data.features > 1 and self.m_initFeatureData.p_data.features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                            -- 说明是 圆盘玩法结束后 又触发的bonus 断线 添加bonus游戏事件
                            isCheck = true
                        end
                    end
                end
            end
        end

        if self.m_initFeatureData == nil or isCheck then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end

        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin = self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin --self:checkTriggerINFreeSpin()
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ----
        self:checkInitSlotsWithEnterLevel()
    end

    return isTriggerEffect, isPlayGameEffect
end

function CodeGameScreenFourInOneMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    for i = 1, #self.m_baseLittleReelsList do
        local baseLittleReel = self.m_baseLittleReelsList[i]
        baseLittleReel:updateAllScoreFixSymbol()
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local betValue = globalData.slotRunData:getCurTotalBet()
        self.m_bottomUI:updateTotalBet(betValue / 4)
    end

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function CodeGameScreenFourInOneMachine:checkShowReels(reelType)
    local linkReelsName = {"HowlingMoon", "Pomi", "ChilliFiesta", "Charms"}
    local fsBigReel = self:findChild("fs_Big_reel")
    fsBigReel:setVisible(false)
    for i = 1, 4 do
        local baseReelsNode = self:findChild("reel_" .. i)
        baseReelsNode:setVisible(false)
        local fsSmallReelsNode = self:findChild("fs_small_reel_" .. i)
        fsSmallReelsNode:setVisible(false)
        local linkReelsNode = self:findChild(linkReelsName[i] .. "_Link_Big_reel")
        linkReelsNode:setVisible(false)
    end

    self:findChild("root_0_1"):setVisible(false)

    if respinReel == reelType then
        for i = 1, 4 do
            local linkReelsNode = self:findChild(linkReelsName[i] .. "_Link_Big_reel")
            linkReelsNode:setVisible(true)
        end
    elseif BaseReel == reelType then
        for i = 1, 4 do
            local baseReelsNode = self:findChild("reel_" .. i)
            baseReelsNode:setVisible(true)
        end

        self:findChild("root_0_1"):setVisible(true)
    elseif FsLittle == reelType then
        for i = 1, 4 do
            local fsSmallReelsNode = self:findChild("fs_small_reel_" .. i)
            fsSmallReelsNode:setVisible(true)
        end
    elseif FsBig == reelType then
        local fsBigReel = self:findChild("fs_Big_reel")
        fsBigReel:setVisible(true)
    end
end

function CodeGameScreenFourInOneMachine:featuresOverAddFreespinEffect()
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
            globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount

            local respinEffect = GameEffectData.new()
            respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN

            self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

            --发送测试特殊玩法
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end
    end
end

function CodeGameScreenFourInOneMachine:showSelfUI(View, zorder)
    local centerYPos = display.height / 2

    local addZorder = -1
    if zorder then
        addZorder = zorder
    end

    self:findChild("root_0"):addChild(View, addZorder)

    if globalData.slotRunData.machineData.p_portraitFlag then
        View.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = View})

    local addPosY = 0
    if display.height > 1535 then
        addPosY = 17
    elseif display.height < 1121 then
        addPosY = 25
    else
        addPosY = 15
    end

    local wordPos = cc.p(0, centerYPos + addPosY)
    local curPos = cc.p(self:findChild("root_0"):convertToNodeSpace(wordPos))

    View:setPositionX(-16.51)
    View:setPositionY((curPos.y) - (DESIGN_SIZE.height / 2) - ((display.height - DESIGN_SIZE.height) / 2))
end

function CodeGameScreenFourInOneMachine:showJackpotView(index, coins, func)
    gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_OpenView.mp3")

    local jackPotWinView = util_createView("CodeFourInOneSrc.FourInOneJackPotWinView")

    self:showSelfUI(jackPotWinView)

    jackPotWinView:initViewData(index, coins, self, func)
end

function CodeGameScreenFourInOneMachine:changeReelsQuickStopStates(states)
    for i = 1, #self.m_baseLittleReelsList do
        local baseLittleReel = self.m_baseLittleReelsList[i]
        baseLittleReel.m_isRuning = states
    end
end

function CodeGameScreenFourInOneMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        local lines = {}
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_fsBigReel then
                local miniReelslines = self.m_fsBigReel:getResultLines()
                if miniReelslines then
                    for i = 1, #miniReelslines do
                        table.insert(lines, miniReelslines[i])
                    end
                end
            else
                for i = 1, #self.m_FSLittleReelsList do
                    local reels = self.m_FSLittleReelsList[i]
                    local miniReelslines = reels:getResultLines()

                    if miniReelslines then
                        for i = 1, #miniReelslines do
                            table.insert(lines, miniReelslines[i])
                        end
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
            for i = 1, #self.m_baseLittleReelsList do
                local reels = self.m_baseLittleReelsList[i]
                local miniReelslines = reels:getResultLines()

                if miniReelslines then
                    for i = 1, #miniReelslines do
                        table.insert(lines, miniReelslines[i])
                    end
                end
            end

            if lines ~= nil and #lines > 0 then
                delayTime = delayTime + self:getWinCoinTime()
            end
        end

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end

function CodeGameScreenFourInOneMachine:removeAllFSReels()
    if self.m_fsBigReel then
        self.m_fsBigReel:removeFromParent()
    end
    self.m_fsBigReel = nil

    for i = 1, #self.m_FSLittleReelsList do
        local reels = self.m_FSLittleReelsList[i]
        if reels then
            reels:removeFromParent()
        end
    end
    performWithDelay(
        self,
        function()
            self.m_FSLittleReelsList = {}
        end,
        0
    )
end

function CodeGameScreenFourInOneMachine:removeAllLinkReels()
    if self.m_LinkBigReels then
        self.m_LinkBigReels:removeFromParent()
    end
    self.m_LinkBigReels = nil
end

function CodeGameScreenFourInOneMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes
                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                    -- 四合一关卡特殊处理，freespin过程中不触发Respin,respin游戏事件在freespin结束手动添加
                    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                        globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                        if self:getCurrSpinMode() == RESPIN_MODE then
                        else
                            local respinEffect = GameEffectData.new()
                            respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                            if globalData.slotRunData.iReSpinCount == 0 and #self.m_runSpinResultData.p_storedIcons == 15 then
                                respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                                respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                            end
                            self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                            --发送测试特殊玩法
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                        end
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 四合一关卡特殊处理，freespin过程中不触发bonus,bonus游戏事件在freespin结束手动添加
                    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                        -- 添加 BonusEffect
                        self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenFourInOneMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
    -- hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
    -- hasBonusFeature = true
    end

    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (hasReSpinFeature == true or hasBonusFeature == true))
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

---
-- 触发respin 玩法
--
function CodeGameScreenFourInOneMachine:showEffect_Respin(effectData)
    self.isInBonus = true

    local lines = {}
    local waitTimes = 0
    for i = 1, #self.m_baseLittleReelsList do
        local reels = self.m_baseLittleReelsList[i]
        local miniReelslines = reels:getResultLines()

        if miniReelslines then
            for i = 1, #miniReelslines do
                table.insert(lines, miniReelslines[i])
            end
        end
    end

    if lines ~= nil and #lines > 0 then
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = self.m_serverWinCoins / totalBet
        if winRate <= 1 then
            waitTimes = 1
        elseif winRate > 1 and winRate <= 3 then
            waitTimes = 1.5
        elseif winRate > 3 and winRate <= 6 then
            waitTimes = 2.5
        elseif winRate > 6 then
            waitTimes = 4
        end
    end

    performWithDelay(
        self,
        function()
            -- 停掉背景音乐
            self:clearCurMusicBg()
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "respin")
            end
            local removeMaskAndLine = function()
                self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()

                self:resetMaskLayerNodes()

                -- 处理特殊信号
                local childs = self.m_lineSlotNodes
                for i = 1, #childs do
                    -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
                    --将该节点放在 .m_clipParent
                    local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
                    local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    childs[i]:removeFromParent()
                    childs[i]:setPosition(cc.p(pos.x, pos.y))
                    self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
                    -- end
                end
            end

            if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
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
        end,
        waitTimes
    )

    return true
end

-- respin控制
function CodeGameScreenFourInOneMachine:showRespinView()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true
    self.m_bottomUI.m_showPopUpUIStates = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_bottomUI.m_showPopUpUIStates = true

    self.m_runSpinResultData.p_reSpinsTotalCount = self.m_respinTriggerData.respin.reSpinsTotalCount
    self.m_runSpinResultData.p_reSpinCurCount = self.m_respinTriggerData.respin.reSpinCurCount

    self:clearWinLineEffect()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local triggerPosition = selfdata.triggerPosition

    for i = 1, #self.m_baseLittleReelsList do
        local reelPos = triggerPosition + 1
        if i ~= reelPos then
            local baseLittleReel = self.m_baseLittleReelsList[i]
            baseLittleReel:clearLittleReelsLinesEffect()
        end
    end

    if triggerPosition then
        local baseMiniReel = self.m_baseLittleReelsList[triggerPosition + 1]
        if baseMiniReel then
            local features = self.m_runSpinResultData.p_features
            if features and #features > 1 and features[2] == RESPIN_MODE then
                baseMiniReel:showBaseMiniEffect_Respin(
                    function()
                        self:enterRespinView(triggerPosition)
                    end
                )
            else
                -- 如果不是触发直接进入respin
                self:enterRespinView(triggerPosition)
            end
        end
    end
end

function CodeGameScreenFourInOneMachine:setRsBgMusicName(reelType)
    if reelType == HowlingMoon_Reels then
        self.m_rsBgMusicName = "FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_linghtning_frame.mp3"
    elseif reelType == Pomi_Reels then
        self.m_rsBgMusicName = "FourInOneSounds/PomiSounds/music_Pomi_Respin_Bg.mp3"
    elseif reelType == ChilliFiesta_Reels then
        self.m_rsBgMusicName = "FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBgSound.mp3"
    elseif reelType == Charms_Reels then
        self.m_rsBgMusicName = "FourInOneSounds/CharmsSounds/Charms_RespinBg.mp3"
    end
end

function CodeGameScreenFourInOneMachine:enterRespinView(triggerPosition)
    self:clearCurMusicBg()

    self:showGuoChang(
        function()
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local triggerPosition = selfdata.triggerPosition

            if triggerPosition then
                local baseMiniReel = self.m_baseLittleReelsList[triggerPosition + 1]
                if baseMiniReel then
                    baseMiniReel.m_triggerEffect:setVisible(false)
                    baseMiniReel.m_triggerEffect:playAction("stop")
                end
            end

            local betValue = globalData.slotRunData:getCurTotalBet()
            self.m_bottomUI:updateTotalBet(betValue / 4)

            self:findChild("Click_Choose"):setVisible(false)

            self.m_light_left:runCsbAction("lighting", true)
            self.m_light_reight:runCsbAction("lighting", true)

            self:initLinkBigReels(self.m_reelsTypeList[triggerPosition + 1])

            if self.m_LinkBigReels then
                if self.m_respinTriggerData then
                    self.m_LinkBigReels:SpinResultParseResultData(self.m_respinTriggerData)
                end
                self.m_LinkBigReels:enterSelfLevel()

                local reelType = self.m_LinkBigReels.m_reelType

                self:setRsBgMusicName(reelType)

                if reelType ~= HowlingMoon_Reels then
                    self.m_LinkBigReels:showRespinView(nil)
                else
                    self.m_LinkBigReels:runCsbAction("animation1")
                    self.m_LinkBigReels:setReelSlotsNodeVisible(false)
                end

                performWithDelay(
                    self,
                    function()
                        self:showReSpinStart(
                            function()
                                -- -- 更改respin 状态下的背景音乐
                                self:changeReSpinBgMusic()

                                if reelType == HowlingMoon_Reels then
                                    self.m_LinkBigReels:showRespinView(nil)
                                else
                                    self.m_LinkBigReels:showReSpinStart()
                                end
                            end
                        )
                    end,
                    0.5
                )
            end
        end
    )
end

function CodeGameScreenFourInOneMachine:showReSpinStart(func)
    if func then
        func()
    end

    -- local features = self.m_runSpinResultData.p_features
    -- if features and #features > 1 and features[2] == RESPIN_MODE then

    -- else
    --     -- 如果不是触发直接进入respin
    --     if func then
    --         func()
    --     end

    --     return

    -- end

    -- local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    -- local triggerPosition = selfdata.triggerPosition

    -- local respinStartName = BaseDialog.DIALOG_TYPE_RESPIN_START
    -- local isAuto = nil

    -- if self.m_reelsTypeList[triggerPosition + 1] == HowlingMoon_Reels then

    --     gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_show_view.mp3")

    --     respinStartName = "FourInOne_Moon_ReSpinStart"
    --     isAuto = BaseDialog.AUTO_TYPE_ONLY
    --     self:showDialog(respinStartName,nil,func,isAuto)
    -- elseif self.m_reelsTypeList[triggerPosition + 1] == Pomi_Reels then

    --     gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_common_viewOpen.mp3")

    --     respinStartName = "FourInOne_Pomi_ReSpinStart"
    --     self:showDialog(respinStartName,nil,func)
    -- elseif self.m_reelsTypeList[triggerPosition + 1] == ChilliFiesta_Reels then

    --     if func then
    --         func()
    --     end
    -- elseif self.m_reelsTypeList[triggerPosition + 1] == Charms_Reels then

    --     gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_Open_View.mp3")

    --     respinStartName = "FourInOne_Charms_ReSpinStart"
    --     self:showDialog(respinStartName,nil,func)
    -- end

    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenFourInOneMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeFourInOneSrc.FourInOneBaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    self:showSelfUI(view)

    return view
end

--ReSpin开始改变UI状态
function CodeGameScreenFourInOneMachine:changeReSpinStartUI(respinCount)
end

--ReSpin刷新数量
function CodeGameScreenFourInOneMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenFourInOneMachine:changeReSpinOverUI()
end

function CodeGameScreenFourInOneMachine:showReSpinOver(coins, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = coins

    local reelType = self.m_LinkBigReels.m_reelType
    local respinOverName = BaseDialog.DIALOG_TYPE_RESPIN_OVER

    if reelType == HowlingMoon_Reels then
        respinOverName = "ReSpinOver"
    elseif reelType == Pomi_Reels then
        respinOverName = "ReSpinOver"
    elseif reelType == ChilliFiesta_Reels then
        respinOverName = "ReSpinOver"
    elseif reelType == Charms_Reels then
        respinOverName = "ReSpinOver"
    end

    return self:showDialog(respinOverName, ownerlist, func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenFourInOneMachine:showRespinOverView(strCoins)
    if self.m_gameEffects and #self.m_gameEffects > 0 then
        for i = #self.m_gameEffects, 1, -1 do
            local effect = self.m_gameEffects[i]
            if effect and effect.p_isPlay then
                table.remove(self.m_gameEffects, i)
            end
        end
    end

    self.m_respinOverRunning = true

    local strCoins = util_formatCoins(strCoins, 50)
    local view =
        self:showReSpinOver(
        strCoins,
        function()
            self:showGuoChang(
                function()
                    local betValue = globalData.slotRunData:getCurTotalBet()
                    self.m_bottomUI:updateTotalBet(betValue)

                    self:findChild("4in1_jackpot"):setVisible(true)

                    self:findChild("Click_Choose"):setVisible(true)

                    self.m_light_left:runCsbAction("idleframe", true)
                    self.m_light_reight:runCsbAction("idleframe", true)

                    self.m_gameLightBg:setVisible(true)

                    for i = 1, #self.m_baseLittleReelsList do
                        local baseLittleReel = self.m_baseLittleReelsList[i]
                        baseLittleReel:clearLittleReelsLinesEffect()
                    end

                    -- 在完成freespinoverEffect之前 添加下一个effect(处理同时触发的情况)
                    self:featuresOverAddFreespinEffect()

                    self:removeAllLinkReels()

                    self:checkShowReels(BaseReel)

                    self:triggerReSpinOverCallFun(0)

                    self:changeReelsQuickStopStates(true)

                    self.m_CharmsGameBg:setVisible(false)
                    self.m_ChilliFiestaGameBg:setVisible(false)
                    self.m_HowlingMoonGameBg:setVisible(false)
                    self.m_PomiGameBg:setVisible(false)

                    self:resetMusicBg()
                end
            )
        end
    )

    local reelType = self.m_LinkBigReels.m_reelType

    if reelType == HowlingMoon_Reels then
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 461)
    elseif reelType == Pomi_Reels then
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 461)
    elseif reelType == ChilliFiesta_Reels then
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 461)
    elseif reelType == Charms_Reels then
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 461)
    end
end
---判断结算
function CodeGameScreenFourInOneMachine:reSpinReelDown(addNode)
    print("")
end

---判断结算
function CodeGameScreenFourInOneMachine:reSpinSelfReelDown(addNode, func, funcStop)
    self:setGameSpinStage(STOP_RUN)

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_LinkBigReels.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_LinkBigReels.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        if funcStop then
            funcStop()
        end
        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self.m_LinkBigReels:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_LinkBigReels.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_LinkBigReels.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self.m_LinkBigReels:changeReSpinUpdateUI(self.m_LinkBigReels.m_runSpinResultData.p_reSpinCurCount)
    end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    if func then
        func()
    end

    self.m_LinkBigReels:runNextReSpinReel(true)
end

function CodeGameScreenFourInOneMachine:showGuoChang(func, func2)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_GuoChang.mp3")

            self.m_GuoChangView:setVisible(true)
            self.m_GuoChangView:runCsbAction(
                "guochang",
                false,
                function()
                    self.m_GuoChangView:setVisible(false)
                    if func2 then
                        func2()
                    end
                end
            )

            performWithDelay(
                self,
                function()
                    self.m_GuoChangView:findChild("Particle_1"):resetSystem()
                    self.m_GuoChangView:findChild("Particle_1_0"):resetSystem()
                    performWithDelay(
                        self,
                        function()
                            if func then
                                func()
                            end
                        end,
                        15 / 30
                    )
                end,
                5 / 30
            )
        end,
        1
    )
end

function CodeGameScreenFourInOneMachine:checkNotifyManagerUpdateWinCoin()
    -- 这里作为连线时通知钱数更新的 唯一接口
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, isNotifyUpdateTop})
end

function CodeGameScreenFourInOneMachine:MachineRule_respinTouchSpinBntCallBack()
end

function CodeGameScreenFourInOneMachine:showChooseMainView()
    self:findChild("Click_Choose"):setVisible(false)

    -- self.m_gameLightBg:findChild("Sprite_11"):setVisible(false)

    self.m_bottomUI.m_showPopUpUIStates = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_bottomUI.m_showPopUpUIStates = true
    local jackpot = self:findChild("4in1_jackpot")
    if jackpot then
        jackpot:setVisible(false)
    end

    for i = 1, 4 do
        local reelNdoe = self:findChild("reel_" .. i)
        if reelNdoe then
            self:findChild("reel_" .. i):setVisible(false)
        end
    end

    -- self:findChild("root_0_1"):setVisible(false)

    self.m_gameLightBg:stopBgWheelImg()

    self.m_chooseMain = util_createView("CodeFourInOneSrc.ChooseView.FourInOneChooseMainView", self)
    self:findChild("CHooseView"):addChild(self.m_chooseMain)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_chooseMain.getRotateBackScaleFlag = function()
            return false
        end
    end
end

function CodeGameScreenFourInOneMachine:updateBaseReelsView(reelsTypeList)
    self.m_gameLightBg:runBgWheelImg()

    self.m_gameLightBg:findChild("Sprite_11"):setVisible(true)
    self.m_gameLightBg:findChild("Sprite_112121"):setVisible(true)
    self:findChild("Click_Choose"):setVisible(true)

    self.m_bottomUI.m_showPopUpUIStates = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    self.m_bottomUI.m_showPopUpUIStates = true
    for i = 1, 4 do
        local reelNdoe = self:findChild("reel_" .. i)
        if reelNdoe then
            self:findChild("reel_" .. i):setVisible(true)
        end
    end

    self:findChild("root_0_1"):setVisible(true)

    local jackpot = self:findChild("4in1_jackpot")
    if jackpot then
        jackpot:setVisible(true)
    end

    if self.m_chooseMain then
        self.m_chooseMain:removeFromParent()
        self.m_chooseMain = nil
    end

    self.m_reelsTypeList = reelsTypeList

    self:changeBaseReelsBg()

    for i = 1, #reelsTypeList do
        local choosedReelType = reelsTypeList[i]
        local miniReel = self.m_baseLittleReelsList[i]
        local miniReelType = miniReel.m_reelType

        if choosedReelType ~= miniReelType then
            miniReel:removeFromParent()

            local className = "CodeFourInOneSrc.BaseReels.FourInOneBaseMiniMachine"
            local reelData = {}
            reelData.reelType = reelsTypeList[i]
            reelData.reelId = i
            reelData.parent = self
            reelData.change = true -- 标识是选择创建的轮盘
            local miniReel = util_createView(className, reelData)
            self:findChild("reel_" .. i):addChild(miniReel)

            if globalData.slotRunData.machineData.p_portraitFlag then
                miniReel.getRotateBackScaleFlag = function()
                    return false
                end
            end

            self.m_baseLittleReelsList[i] = miniReel
            miniReel:enterSelfLevel()
            miniReel.m_isRuning = true

            if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniReel.m_touchSpinLayer)
            end
            
        end
    end
end

function CodeGameScreenFourInOneMachine:checkChooseBtnShouldClick()
    local featureDatas = self.m_runSpinResultData.p_features or {0}

    -- 返回true 不允许点击

    if self.m_isWaitingNetworkData then
        return true
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return true
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return true
    elseif self.m_LinkBigReels then
        return true
    elseif #featureDatas > 1 then
        return true
    end

    return false
end

--默认按钮监听回调
function CodeGameScreenFourInOneMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkChooseBtnShouldClick() then
        -- 不允许点击
        return
    end

    if self.m_chooseMain then
        return
    end

    if name == "Click_Choose" then
        gLobalSoundManager:playSound("FourInOneSounds/music_FourInOnes_Click_Collect.mp3")

        self:showChooseMainView()
    end
end

function CodeGameScreenFourInOneMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("Node_mainBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    self.m_gameLightBg = util_createView("CodeFourInOneSrc.FourInOneGameBg")
    self:findChild("Node_bg"):addChild(self.m_gameLightBg)
    self.m_gameLightBg:runCsbAction("animation0")

    -- local pos = cc.p(util_getConvertNodePos(self:findChild("BgBuildPos"),self.m_gameLightBg:findChild("Node_4")))
    -- self.m_gameLightBg:findChild("Node_4"):setPositionY(-500 )

    self.m_LogoView = util_createView("CodeFourInOneSrc.FsReels.FourInOne_FS_LogoView")
    self.m_gameLightBg:findChild("Node_Logo"):addChild(self.m_LogoView)
    self.m_LogoView:runCsbAction("idleframe")

    self.m_light_left = util_createAnimation("FourInOne_Bg_left_light.csb")
    self:findChild("light_left"):addChild(self.m_light_left)
    self.m_light_left:runCsbAction("idleframe", true)

    self.m_light_reight = util_createAnimation("FourInOne_Bg_right_light.csb")
    self:findChild("light_reight"):addChild(self.m_light_reight)
    self.m_light_reight:runCsbAction("idleframe", true)

    self.m_CharmsGameBg = util_createView("CodeFourInOneSrc.LittleReelsGameMachineBG", "Charms")
    self.m_gameLightBg:findChild("Node_LinkBG"):addChild(self.m_CharmsGameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG + 1)
    local csbPath = "LinkReels/CharmsLink/4in1_GameScreenCharmsBg.csb"
    self.m_CharmsGameBg:initBgByModuleName(csbPath, self.m_isMachineBGPlayLoop)
    self.m_CharmsGameBg:setVisible(false)

    self.m_ChilliFiestaGameBg = util_createView("CodeFourInOneSrc.LittleReelsGameMachineBG", "ChilliFiesta")
    self.m_gameLightBg:findChild("Node_LinkBG"):addChild(self.m_ChilliFiestaGameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG + 2)
    local csbPath = "LinkReels/ChilliFiestaLink/4in1_GameScreenChilliFiestaBg.csb"
    self.m_ChilliFiestaGameBg:initBgByModuleName(csbPath, self.m_isMachineBGPlayLoop)
    self.m_ChilliFiestaGameBg:setVisible(false)

    self.m_HowlingMoonGameBg = util_createView("CodeFourInOneSrc.LittleReelsGameMachineBG", "HowlingMoon")
    self.m_gameLightBg:findChild("Node_LinkBG"):addChild(self.m_HowlingMoonGameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG + 3)
    local csbPath = "LinkReels/HowlingMoonLink/4in1_GameScreenHowlingMoonBg.csb"
    self.m_HowlingMoonGameBg:initBgByModuleName(csbPath, self.m_isMachineBGPlayLoop)
    self.m_HowlingMoonGameBg:setVisible(false)

    self.m_PomiGameBg = util_createView("CodeFourInOneSrc.LittleReelsGameMachineBG", "Pomi")
    self.m_gameLightBg:findChild("Node_LinkBG"):addChild(self.m_PomiGameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG + 4)
    local csbPath = "LinkReels/PomiLink/4in1_GameScreenPomiBg.csb"
    self.m_PomiGameBg:initBgByModuleName(csbPath, self.m_isMachineBGPlayLoop)
    self.m_PomiGameBg:setVisible(false)
    --测试代码
    -- performWithDelay(self,function()
    --     self.m_chooseBntAct:setVisible(false)
    --     self.m_GuoChangView:setVisible(false)
    --     self.m_Fsbar:setVisible(false)
    --     self.m_gameBg:setVisible(false)
    --     self.m_gameLightBg:setVisible(false)
    --     self.m_LogoView:setVisible(false)
    --     self.m_light_left:setVisible(false)
    --     self.m_light_reight:setVisible(false)
    --     self.m_jackPorBar:setVisible(false)
    --     self.m_topUI:setVisible(false)
    --     self.m_bottomUI:setVisible(false)
    --     self.m_spinBtn = util_createView("views.gameviews.SpinBtn")
    --     self:addChild(self.m_spinBtn,1)
    --     self.m_spinBtn:setPosition(display.cx,80)
    -- end,0.2)
end

function CodeGameScreenFourInOneMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    local GameScreenCSbName = self.m_moduleName
    if display.height > 1535 then
        GameScreenCSbName = self.m_moduleName .. "_BigSize"
    end

    local resourceFilename = self.m_moduleName .. "/GameScreen" .. GameScreenCSbName .. ".csb"
    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode(resourceFilename)
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function CodeGameScreenFourInOneMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    globalData.slotRunData.gameModuleName = self.m_moduleName
    globalData.slotRunData.gameNetWorkModuleName = self:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        globalData.slotRunData.gameNetWorkModuleName = globalData.slotRunData.gameNetWorkModuleName .. "_H"
    end
    globalData.slotRunData.lineCount = self.m_lineCount

    BaseFastMachine.initMachine(self)
end

function CodeGameScreenFourInOneMachine:changeSelfViewNodePos()
    local posY = 0

    local rootNode = self:findChild("reelNode")
    if display.height > 1535 then
        posY = (display.height - 1536) * 0.5
        rootNode:setPositionY(rootNode:getPositionY() - posY)
    elseif display.height < 1121 then
    else
        if display.height >= 1121 and display.height < 1400 then
        else
            posY = (display.height - 1401) * 0.5
            rootNode:setPositionY(rootNode:getPositionY() - posY)
        end
    end
end

function CodeGameScreenFourInOneMachine:scaleMainLayer()
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
        if display.height >= 1121 and display.height < 1400 then
            mainScale = (display.height - 30 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        elseif display.height < 1121 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end

        local mainLayerPos = cc.p(self.m_machineNode:getPosition())
        if display.height > 1535 then
            self.m_machineNode:setPositionY(mainLayerPos.y + 17)
        elseif display.height < 1121 then
            self.m_machineNode:setPositionY(mainLayerPos.y + 25)
        else
            self.m_machineNode:setPositionY(mainLayerPos.y + 15)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    local m_light_Height = 1195
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local showHeight = (1660 / 2) + ((display.height / 2) - uiBH) / self.m_machineRootScale

    local lightScale = showHeight / m_light_Height
    self.m_light_left:setScaleY(lightScale)
    self.m_light_reight:setScaleY(lightScale)

    self:changeSelfViewNodePos()

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
end

function CodeGameScreenFourInOneMachine:changeBgToNormalFreespinStart()
    self.m_gameLightBg:runCsbAction("idleframe", true)
    self.m_LogoView:runCsbAction("animation0", true)
end

function CodeGameScreenFourInOneMachine:changeBgToSuperFreespinStart()
    self.m_gameLightBg:runCsbAction("animation0")
    self.m_LogoView:runCsbAction("idleframe")
end

function CodeGameScreenFourInOneMachine:changeBgToFreespinOver()
    self.m_gameLightBg:runCsbAction("animation0")
    self.m_LogoView:runCsbAction("idleframe")
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenFourInOneMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
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

function CodeGameScreenFourInOneMachine:changeBaseReelsBg()
    for i = 1, #self.m_reelsTypeList do
        local spr = self:findChild("baseReels_bg_" .. i)
        local reelType = self.m_reelsTypeList[i]
        if spr then
            util_changeTexture(spr, "ui/" .. reelType .. "_BG.png")
        end
    end
end

function CodeGameScreenFourInOneMachine:changeOneBaseReelsBg(reelType, index, time, callback)
    for i = 1, #self.m_reelsTypeList do
        local spr = self:findChild("baseReels_bg_" .. i)
        if spr and index == i then
            util_changeTexture(spr, "ui/" .. reelType .. "_BG.png")
            spr:setOpacity(0)
            util_playFadeInAction(spr, time, callback)
            break
        end
    end
end

-- 背景音乐点击spin后播放
function CodeGameScreenFourInOneMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    for i = 1, #self.m_baseLittleReelsList do
        local baseLittleReel = self.m_baseLittleReelsList[i]
        if baseLittleReel and baseLittleReel.m_showLineFrameTime then
            if self.m_showLineFrameTime then
                self.m_showLineFrameTime = util_max(self.m_showLineFrameTime, baseLittleReel.m_showLineFrameTime)
            else
                self.m_showLineFrameTime = baseLittleReel.m_showLineFrameTime
            end
        end
    end

    for i = 1, #self.m_FSLittleReelsList do
        local fsLittleReel = self.m_FSLittleReelsList[i]
        if fsLittleReel and fsLittleReel.m_showLineFrameTime then
            if self.m_showLineFrameTime then
                self.m_showLineFrameTime = util_max(self.m_showLineFrameTime, fsLittleReel.m_showLineFrameTime)
            else
                self.m_showLineFrameTime = fsLittleReel.m_showLineFrameTime
            end
        end
    end

    local linkBigReel = self.m_LinkBigReels
    if linkBigReel and linkBigReel.m_showLineFrameTime then
        if self.m_showLineFrameTime then
            self.m_showLineFrameTime = util_max(self.m_showLineFrameTime, linkBigReel.m_showLineFrameTime)
        else
            self.m_showLineFrameTime = linkBigReel.m_showLineFrameTime
        end
    end

    local fsBigReel = self.m_fsBigReel
    if fsBigReel and fsBigReel.m_showLineFrameTime then
        if self.m_showLineFrameTime then
            self.m_showLineFrameTime = util_max(self.m_showLineFrameTime, fsBigReel.m_showLineFrameTime)
        else
            self.m_showLineFrameTime = fsBigReel.m_showLineFrameTime
        end
    end

    BaseFastMachine.normalSpinBtnCall(self)
end

function CodeGameScreenFourInOneMachine:checkPaytableChangeSpinStates()
    if self:checkChooseBtnShouldClick() then
        -- 不允许点击
        return false
    end

    if self.m_chooseMain then
        return false
    end

    return true
end

-- 显示paytableview 界面
function CodeGameScreenFourInOneMachine:showPaytableView()
    self.m_topUI.m_isNotCanClick = true

    self.m_bottomUI.m_showPopUpUIStates = false
    --if self:checkPaytableChangeSpinStates( ) then
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    --end
    self.m_bottomUI.m_showPopUpUIStates = true

    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = util_createView("base/BasePayTableView", sCsbpath)
    self:showSelfUI(view, 100)
    if view then
        view:setOverFunc(
            function()
                self.m_topUI.m_isNotCanClick = false
                if self:checkPaytableChangeSpinStates() then
                    self.m_bottomUI.m_showPopUpUIStates = false
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                    self.m_bottomUI.m_showPopUpUIStates = true
                end

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
    end
end

function CodeGameScreenFourInOneMachine:operaNetWorkData()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
    self:perpareStopReel()
end

local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenFourInOneMachine:addLastWinSomeEffect() -- add big win or mega win
    --
    local lines = {}

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_fsBigReel then
            local miniReelslines = self.m_fsBigReel:getResultLines()
            if miniReelslines then
                for i = 1, #miniReelslines do
                    table.insert(lines, miniReelslines[i])
                end
            end
        else
            for i = 1, #self.m_FSLittleReelsList do
                local reels = self.m_FSLittleReelsList[i]
                local miniReelslines = reels:getResultLines()

                if miniReelslines then
                    for i = 1, #miniReelslines do
                        table.insert(lines, miniReelslines[i])
                    end
                end
            end
        end
    else
        for i = 1, #self.m_baseLittleReelsList do
            local baseLittleReel = self.m_baseLittleReelsList[i]
            local miniReelslines = baseLittleReel:getResultLines()

            if miniReelslines then
                for i = 1, #miniReelslines do
                    table.insert(lines, miniReelslines[i])
                end
            end
        end
    end

    if #lines == 0 then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
    end
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

---
-- 根据枚举的内容播放效果
--
function CodeGameScreenFourInOneMachine:playGameEffect()
    if gLobalViewManager.m_currentScene == SceneType.Scene_LAUNCH then
        return
    end

    local effectLen = #self.m_gameEffects

    local currEffect = nil
    local delayTime = 0
    for i = 1, effectLen, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_isPlay ~= true then
            currEffect = effectData.p_effectType
            break
        end
    end
    if currEffect == GameEffect.EFFECT_BIGWIN or currEffect == GameEffect.EFFECT_MEGAWIN or currEffect == GameEffect.EFFECT_EPICWIN then
        delayTime = 1
    end
    performWithDelay(
        self,
        function()
            BaseMachineGameEffect.playGameEffect(self)
        end,
        delayTime
    )
end

--不需要解析数据
-- function CodeGameScreenFourInOneMachine:produceSlots()
-- end

return CodeGameScreenFourInOneMachine
