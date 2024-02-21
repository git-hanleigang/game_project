---
-- island li
-- 2019年1月26日
-- CodeGameScreenLottoPartyMachine.lua
--
-- 玩法：
--

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SendDataManager = require "network.SendDataManager"
local CodeGameScreenLottoPartyMachine = class("CodeGameScreenLottoPartyMachine", BaseNewReelMachine)

require "CodeLottoPartySpotSrc.LottoPartyManager"
require "CodeLottoPartySpotSrc.LottoPartyHeadManager"

CodeGameScreenLottoPartyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenLottoPartyMachine.SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 自定义的小块类型
CodeGameScreenLottoPartyMachine.SYMBOL_JACKPOT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenLottoPartyMachine.CHANGE_BIG_SYMBOL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenLottoPartyMachine.WIN_SPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --中spot玩法
CodeGameScreenLottoPartyMachine.OPEN_BONUS_SPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 开奖

CodeGameScreenLottoPartyMachine.m_longRunBonusColList = {}

-- 构造函数
function CodeGameScreenLottoPartyMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_clickJackpot = false
    self.m_clickTag = -1

    self.m_slotsAnimNodeFps = 60
    self.m_lineFrameNodeFps = 60
    self.m_baseDialogViewFps = 60

    self.m_longRunBonusColList = {}
    --init
    self.m_mysterList = {}
    for i = 1, 5 do
        self.m_mysterList[i] = -1
    end

    self.m_initNodeCol = 0
    self.m_initNodeSymbolType = 0

    self.m_jackpotWinCoins = false
    self.m_bonusWinCoins = false
    self.m_bOutGame = false
    self.m_bEnterGame = true --首次进入关卡
    self:initGame()
    self.m_resultData = {}
end

function CodeGameScreenLottoPartyMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LottoPartyConfig.csv", "LevelLottoPartyConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenLottoPartyMachine:randomMystery()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i)
        self.m_mysterList[i] = symbolInfo.symbolType
    end

    self.m_configData:setMysterSymbol(self.m_mysterList)
end

function CodeGameScreenLottoPartyMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end

--使用现在获取的数据
function CodeGameScreenLottoPartyMachine:setNetMysteryType()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_bNetSymbolType = true
            local bRunLong = false
            for i = 1, #self.m_mysterList do
                local symbolInfo = self:getColIsSameSymbol(i)
                self.m_mysterList[i] = symbolInfo.symbolType
                local reelRunData = self.m_reelRunInfo[i]
                if bRunLong then
                    self.m_mysterList[i] = -1
                end
                if self.m_mysterList[i] == -1 then
                    self:changeSlotReelDatas(i, bRunLong)
                end
                if reelRunData:getNextReelLongRun() == true then
                    bRunLong = true
                end
            end
        end,
        0.5,
        "changeReelData"
    )
end

function CodeGameScreenLottoPartyMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenLottoPartyMachine:checkUpdateReelDatas(parentData, _bRunLong)
    local reelDatas = nil

    if _bRunLong == true then
        reelDatas = self.m_configData:getRunLongDatasByColumnIndex(parentData.cloumnIndex)
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

--随机信号
function CodeGameScreenLottoPartyMachine:getReelSymbolType(parentData)
    local cloumnIndex = parentData.cloumnIndex
    if self.m_bNetSymbolType == true then
        if self.m_mysterList[cloumnIndex] ~= -1 then
            return self.m_mysterList[cloumnIndex]
        end
    end
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

function CodeGameScreenLottoPartyMachine:getColIsSameSymbol(_iCol)
    local reelsData = self.m_runSpinResultData.p_reels
    if reelsData and next(reelsData) then
        local symbolInfo = {}
        local tempType
        local symbolType = nil
        for iRow = 1, self.m_iReelRowNum do
            tempType = reelsData[iRow][_iCol]
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType ~= tempType then
                symbolInfo.symbolType = -1
                symbolInfo.bSame = false
                return symbolInfo
            end
        end
        symbolInfo.symbolType = tempType
        symbolInfo.bSame = true
        return symbolInfo
    else
        local symbolInfo = {}
        symbolInfo.symbolType = -1
        symbolInfo.bSame = false
        return symbolInfo
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLottoPartyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LottoParty"
end

function CodeGameScreenLottoPartyMachine:initUI()
    self.m_reelRunSound = "LottoPartySounds/sound_LottoParty_fast_run.mp3"
    -- jackpot
    self.m_JackPotBar = util_createView("CodeLottoPartySrc.LottoPartyJackPotBarView")
    self.m_JackPotBar:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_JackPotBar)
    self.m_gameBg:runCsbAction("idle", true, nil, 60)

    self.m_reelPanel = self:findChild("reelNode")

    self:runCsbAction("idle1", true, nil, 60)
end

function CodeGameScreenLottoPartyMachine:enterGamePlayMusic()
    self:delayRefreshRoomData()
    self:delayOutGame()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("LottoPartySounds/sound_LottoParty_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.m_bBonusGame then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenLottoPartyMachine:initSpotBonusUI()
    --邮件按钮
    self.m_MailTip = util_createView("CodeLottoPartySpotSrc.LottoPartyMailTip")
    self:findChild("Node_Mail"):addChild(self.m_MailTip)
    self:showOrHideMailTip()
    --房间玩家列表
    self.m_RoomListView = util_createView("CodeLottoPartySpotSrc.LottoPartyRoomListView")
    self.m_RoomListView:initPlayerData()
    self:findChild("Node_Room"):addChild(self.m_RoomListView)

    self.m_SpotOpenView = util_createView("CodeLottoPartySpotSrc.LottoPartySpotOpenView")
    self:findChild("Node_SpotNum"):addChild(self.m_SpotOpenView)
end

function CodeGameScreenLottoPartyMachine:showOrHideMailTip()
    local wins = LottoPartyManager:getWinSpots()
    if wins and #wins > 0 then
        if self.m_bEnterGame == true then
            self.m_MailTip:setClickEnable(false)
            self:openMail()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        else
            self.m_MailTip:setVisible(true)
            self.m_MailTip:setClickEnable(true)
            self.m_MailTip:runCsbAction("idle", true, nil, 60)
        end
    else
        self.m_MailTip:setVisible(false)
        self.m_MailTip:setClickEnable(false)
    end
end

function CodeGameScreenLottoPartyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:initSpotBonusUI()
end

function CodeGameScreenLottoPartyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    self:removeRefreshHandler()
    self:removeOutGameHandler()
    self:removeChangeReelDataHandler()
    scheduler.unschedulesByTargetName(self:getModuleName())
    LottoPartyManager:release()
    LottoPartyHeadManager:release()
    display.removeSpriteFrames("userinfo/ui_head/UserHeadPlist.plist", "userinfo/ui_head/UserHeadPlist.png")
end

function CodeGameScreenLottoPartyMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            if self.m_bIsBigWin then
                return
            end

            if self:checktriggerSpecialGame() or self.m_jackpotWinCoins or self.m_bonusWinCoins then
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

            local soundName = "LottoPartySounds/sound_LottoParty_last_win" .. soundIndex .. ".mp3"
            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
    --刷新排行榜
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_RoomListView then
                if params ~= nil and params[1] == true then
                end
                self.m_RoomListView:updataRoomPlayers()
            end
        end,
        ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_RANK
    )
    --刷新中spot格子
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_SpotOpenView then
                local winSpotPos = -1
                if params ~= nil and params[1] == true then
                    if LottoPartyManager:getSpotResult() then
                        return
                    end
                    --触发玩法 不刷新此位置
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    if selfData and selfData.collectData then
                        winSpotPos = selfData.collectData.position + 1
                    end
                end

                self.m_SpotOpenView:updataBonusViewData(winSpotPos)
            end
        end,
        ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT
    )
    --重置开奖信息
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_SpotOpenView:resetBonusViewData()
            self.m_RoomListView:resetRoomPlayers()
        end,
        ViewEventType.NOTIFY_LOTTO_PARTY_RESET_BONUS_SPOT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})
            self:showSpotBonusWin()
        end,
        ViewEventType.NOTIFY_LOTTO_PARTY_SPOT_BONUS
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showOrHideMailTip()
        end,
        ViewEventType.NOTIFY_LOTTO_PARTY_SHOW_OR_HIDE_MAIL
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:openMail()
        end,
        ViewEventType.NOTIFY_LOTTO_PARTY_SHOW_MAIL_WIN
    )
end

function CodeGameScreenLottoPartyMachine:getBaseReelGridNode()
    return "CodeLottoPartySrc.LottoPartySlotsNode"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLottoPartyMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_LottoParty_Bonus"
    elseif symbolType == self.SYMBOL_JACKPOT then
        return "Socre_LottoParty_jackpot"
    end
    return nil
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenLottoPartyMachine:MachineRule_initGame()
end

function CodeGameScreenLottoPartyMachine:scaleMainLayer()
    BaseNewReelMachine.scaleMainLayer(self)
    local ratio = display.height / display.width
    if ratio >= 768 / 1024 then
        local mainScale = 0.85
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        local mainScale = 0.90 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenLottoPartyMachine:slotOneReelDown(reelCol)
    local bTriggerLongRun = BaseNewReelMachine.slotOneReelDown(self, reelCol)
    if bTriggerLongRun and self:getGameSpinStage() ~= QUICK_RUN then
        self.m_bonusRunIdle = true
        self:setLongRunBonusIdle(reelCol)
    end

    local playSound = {bonusSound = 0, jackpotSound = 0}
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local symbolType = targSp.p_symbolType
            if symbolType == self.SYMBOL_BONUS_1 then
                targSp:runAnim("buling", false)
                playSound.bonusSound = 1
            end
            if symbolType == self.SYMBOL_JACKPOT then
                targSp:runAnim("buling", false)
                playSound.jackpotSound = 1
            end
        end
    end

    if playSound.bonusSound == 1 then
        local soundPath = "LottoPartySounds/sound_LottoParty_bonus_ground.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    elseif playSound.jackpotSound == 1 then
        local soundPath = "LottoPartySounds/sound_LottoParty_jackpot_ground.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLottoPartyMachine:MachineRule_SpinBtnCall()
    self:stopBonusIdleSound()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self:removeRefreshHandler()
    self:removeOutGameHandler()
    self:removeChangeReelDataHandler()
    self:stopLinesWinSound()
    self:randomMystery()
    self.m_longRunBonusColList = {}
    self.m_jackpotWinCoins = false
    self.m_bonusWinCoins = false
    self.m_resultData = {}
    self.m_bEnterGame = false
    return false -- 用作延时点击spin调用
end

function CodeGameScreenLottoPartyMachine:operaUserOutCoins()
    --金币不足
    -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
    gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NoCoins)
    end

    gLobalPushViewControl:setEndCallBack(
        function()
            local betCoin = self:getSpinCostCoins() or toLongNumber(0)
            local totalCoin = globalData.userRunData.coinNum or 1
            if betCoin <= totalCoin then
                globalData.rateUsData:resetBankruptcyNoPayCount()
                self:showLuckyVedio()
                return
            end

            -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
            if view then
                view:setOverFunc(function()
                    self:showLuckyVedio()
                end)
            else
                self:showLuckyVedio()
            end
        end
    )

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        self.m_RoomListView:setBtnTouch(true)
        self.m_SpotOpenView:setClickTouch(true)
        self.m_MailTip:setClickEnable(true)
        self:delayRefreshRoomData()
        self:delayOutGame()
    end
end

function CodeGameScreenLottoPartyMachine:spinBtnEnProc()
    --TODO 处理repeat逻辑
    BaseNewReelMachine.spinBtnEnProc(self)
    self.m_RoomListView:setBtnTouch(false)
    self.m_SpotOpenView:setClickTouch(false)
    self.m_MailTip:setClickEnable(false)
end

function CodeGameScreenLottoPartyMachine:removeRefreshHandler()
    if self.m_refreshRoomId ~= nil then
        scheduler.unschedulesByTargetName("refreshRoom")
        self.m_refreshRoomId = nil
    end
end

--判断是否有3列以上相同的信号块相邻 不包含（bonus wild 低级信号块1,2,3,4,5）
function CodeGameScreenLottoPartyMachine:isNeedChangeBigSymbol()
    local winLines = self.m_runSpinResultData.p_winLines

    if #winLines <= 0 then
        return {isChange = false}
    end

    local function isSameSymbol(_firstType, _tempType)
        --低分信号块 及bonus 直接退出
        if _firstType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 and _firstType < TAG_SYMBOL_TYPE.SYMBOL_WILD then
            return false
        end

        if _tempType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 and _tempType < TAG_SYMBOL_TYPE.SYMBOL_WILD then
            return false
        end
        --两个图标不一样 但是有wild
        if _firstType ~= _tempType and (_firstType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _tempType == TAG_SYMBOL_TYPE.SYMBOL_WILD) then
            return true
        end

        if _firstType == _tempType then
            return true
        end

        return false
    end
    --存储每一列是否时相同图标
    local symbolTypeData = {}
    for iCol = 1, self.m_iReelColumnNum do
        local symbolType = nil -- 合图类型
        local bSame = true
        for iRow = 1, self.m_iReelRowNum do
            local tempType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = tempType
            end
            if not isSameSymbol(symbolType, tempType) then
                bSame = false
                symbolType = -1
                break
            end
        end
        local symbolData = {}
        symbolData.symbolType = symbolType
        symbolData.bSame = bSame
        symbolTypeData[iCol] = symbolData
    end

    local startCol = 0
    local sameCol = 0
    local symbolType = nil
    for i = 1, #symbolTypeData do
        local data = symbolTypeData[i]
        if data.bSame then
            local tempType = data.symbolType
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = tempType
            end
            if startCol == 0 then
                startCol = i
            end
            if not isSameSymbol(symbolType, tempType) then
                if sameCol >= 3 then
                    break
                end
                symbolType = nil
                sameCol = 0
                startCol = i--0
            end
            sameCol = sameCol + 1
        else
            if i > 3 then
                break
            end
            symbolType = nil
            sameCol = 0
            startCol = 0
        end
        --前三列都是wild 直接返回 不合图
        if sameCol >= 3 and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            symbolType = nil
            sameCol = 0
            startCol = 0
            break
        end
    end

    --判断是否在赢钱线上
    if not self:isHaveWinLineByType(symbolType) then
        return {isChange = false}
    end
    --有3列及以上相同的则可以合图
    if sameCol >= 3 then
        return {isChange = true, changeType = symbolType, startCol = startCol, changeCol = sameCol}
    end
    return {isChange = false}
end

--判断是否在赢钱线上
function CodeGameScreenLottoPartyMachine:isHaveWinLineByType(_symbolType)
    local winLines = self.m_runSpinResultData.p_winLines

    local isHave = false
    for i = 1, #self.m_runSpinResultData.p_winLines do
        local line = self.m_runSpinResultData.p_winLines[i]
        if line.p_type == _symbolType then
            isHave = true
            break
        end
    end

    return isHave
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLottoPartyMachine:addSelfEffect()
    local isTriggerEffect = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.collectData then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WIN_SPOT_EFFECT -- 动画类型
        isTriggerEffect = true
    end
    self.m_changeBigData = self:isNeedChangeBigSymbol()
    -- 自定义动画创建方式
    if self.m_changeBigData.isChange then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGE_BIG_SYMBOL_EFFECT -- 动画类型
        isTriggerEffect = true
    end

    if LottoPartyManager:getSpotResult() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.OPEN_BONUS_SPOT_EFFECT -- 动画类型
        isTriggerEffect = true
        self.m_resultData = LottoPartyManager:getSpotResult()
    end

    if not self:isTriggerSpecialEffect() and not isTriggerEffect then
        self.m_RoomListView:setBtnTouch(true)
        self.m_SpotOpenView:setClickTouch(true)
        self.m_MailTip:setClickEnable(true)
    end
end

function CodeGameScreenLottoPartyMachine:isTriggerSpecialEffect()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:checktriggerSpecialGame() then
        return true
    end
    return false
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLottoPartyMachine:MachineRule_playSelfEffect(effectData)
    -- 记得完成所有动画后调用这两行
    -- 作用：标识这个动画播放完结，继续播放下一个动画
    if effectData.p_selfEffectType == self.CHANGE_BIG_SYMBOL_EFFECT then
        self:changeBigSymbolEffect(effectData)
    elseif effectData.p_selfEffectType == self.WIN_SPOT_EFFECT then
        performWithDelay(
            self,
            function()
                self:playBonusMoveEffect(effectData)
            end,
            0.5
        )
    elseif effectData.p_selfEffectType == self.OPEN_BONUS_SPOT_EFFECT then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE, {isShow = false})
        performWithDelay(
            self,
            function()
                self:showSpotBonusWin(effectData)
            end,
            0.5
        )
    end

    return true
end
--获取播放大图的中心点 起始列
function CodeGameScreenLottoPartyMachine:getBigSymbolPos(_startCol, _endCol)
    if _endCol > 5 then
        _endCol = 5
    end

    local targSp1 = self:getFixSymbol(_startCol, 1, SYMBOL_NODE_TAG)
    local posWorld1 = targSp1:getParent():convertToWorldSpace(cc.p(targSp1:getPositionX(), targSp1:getPositionY()))
    local pos1 = self.m_clipParent:convertToNodeSpace(cc.p(posWorld1.x, posWorld1.y))

    local targSp2 = self:getFixSymbol(_endCol, 4, SYMBOL_NODE_TAG)
    local posWorld2 = targSp2:getParent():convertToWorldSpace(cc.p(targSp2:getPositionX(), targSp2:getPositionY()))
    local pos2 = self.m_clipParent:convertToNodeSpace(cc.p(posWorld2.x, posWorld2.y))
    return cc.pMidpoint(pos1, pos2)
end

function CodeGameScreenLottoPartyMachine:getChangeBigSymbolName(changeType)
    local bigName = ""
    if changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        bigName = "Socre_LottoParty_6"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        bigName = "Socre_LottoParty_7"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        bigName = "Socre_LottoParty_8"
    elseif changeType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        bigName = "Socre_LottoParty_9"
    end
    return bigName
end

function CodeGameScreenLottoPartyMachine:changeBigSymbolEffect(effectData)
    local changeType = self.m_changeBigData.changeType
    local startCol = self.m_changeBigData.startCol
    local changeCol = self.m_changeBigData.changeCol

    local bigName = self:getChangeBigSymbolName(changeType)
    local endCol = startCol + changeCol - 1
    local pos = self:getBigSymbolPos(startCol, endCol)
    self:setSymbolVisibleByCol(startCol, endCol, false)
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_change_bigSymbol.mp3")
    local bigSymbol = util_spineCreate(bigName, true, true)
    local actName = "actionframe" .. changeCol
    util_spinePlay(bigSymbol, actName, false)
    util_spineEndCallFunc(bigSymbol, actName)
    bigSymbol:setPosition(pos)
    self.m_clipParent:addChild(bigSymbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --黄色遮罩
    self:createChangeBigSymbolYellowEffect(changeCol, pos)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        self,
        function()
            self:setSymbolVisibleByCol(startCol, endCol, true)
        end,
        75 / 30
    )
    performWithDelay(
        waitNode,
        function()
            bigSymbol:removeFromParent()
            effectData.p_isPlay = true
            self:playGameEffect()
            waitNode:removeFromParent()
        end,
        85 / 30
    )
end

function CodeGameScreenLottoPartyMachine:setSymbolVisibleByCol(_startCol, _endCol, _bShow)
    for iCol = _startCol, _endCol do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                targSp:setVisible(_bShow)
            end
        end
    end
end

function CodeGameScreenLottoPartyMachine:playBonusMoveEffect(effectData)
    if not self:isNeedMoveBonus() then
        self:playMoveBonusReel(effectData)
    else
        self:playChangeBigBonusEffect(effectData)
    end
end

function CodeGameScreenLottoPartyMachine:isNeedMoveBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --scatter所在整列
    if selfData and selfData.bonusColumns then
        local startReel = 0
        for i, v in ipairs(selfData.bonusColumns) do
            if startReel ~= v then
                return false
            end
            startReel = startReel + 1
        end
    end
    return true
end

function CodeGameScreenLottoPartyMachine:createPenEffect(_col)
    local penEffect = util_createAnimation("LottoParty_Socrereel_effect.csb")

    self.m_clipParent:addChild(penEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    local index = self:getPosReelIdx(3, _col)
    local pos = util_getOneGameReelsTarSpPos(self, index)
    penEffect:setPosition(cc.p(pos.x - self.m_SlotNodeW / 2, pos.y - self.m_SlotNodeH / 2))
    penEffect:runCsbAction(
        "actionframe",
        false,
        function()
            penEffect:removeFromParent()
        end,
        60
    )
    return penEffect
end

function CodeGameScreenLottoPartyMachine:playMoveBonusReel(effectData)
    self.m_bonusReel = {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local moveLeftTime = 0.25
    local moveRightTime = 0.25
    local maxTime = moveLeftTime + moveRightTime + 0.1
    --Bonus所在整列
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_bonus_he.mp3")
    if selfData and selfData.bonusColumns then
        local startReel = 1
        for i, v in ipairs(selfData.bonusColumns) do
            local col = v + 1
            local bonusReel = self:createMoveBonusReel(col)
            if bonusReel then
                if startReel ~= col then
                    local penEffectCol = startReel
                    local movePos = self:getMoveToPos(startReel)
                    local actList = {}
                    local endPos = movePos.x
                    if penEffectCol ~= 1 then
                        endPos = movePos.x - 20
                    end
                    actList[#actList + 1] = cc.DelayTime:create(0.2 * (startReel - 1))
                    actList[#actList + 1] = cc.MoveTo:create(moveLeftTime, cc.p(endPos, movePos.y))
                    actList[#actList + 1] =
                        cc.CallFunc:create(
                        function()
                            if penEffectCol ~= 1 then
                                self:createPenEffect(penEffectCol)
                            end
                        end
                    )
                    actList[#actList + 1] = cc.MoveTo:create(moveRightTime, cc.p(movePos.x, movePos.y))

                    local sq = cc.Sequence:create(actList)
                    bonusReel:runAction(sq)
                    maxTime = maxTime + 0.2 * (startReel - 1)
                end
                table.insert(self.m_bonusReel, bonusReel)
            end
            startReel = startReel + 1
        end
    end

    self:setAllSymbolVisible(false)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self:playChangeBigBonusEffect(effectData)

            waitNode:removeFromParent()
        end,
        maxTime
    )
end

function CodeGameScreenLottoPartyMachine:getMoveToPos(_col)
    local targSp = self:getFixSymbol(_col, 1, SYMBOL_NODE_TAG)
    local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    return pos
end

function CodeGameScreenLottoPartyMachine:setAllSymbolVisible(_bShow)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local changeCol = 0
    if selfData and selfData.bonusColumns then
        changeCol = #selfData.bonusColumns
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType == self.SYMBOL_BONUS_1 then
                    targSp:runAnim("idleframe")
                end

                targSp:setVisible(_bShow)
            end
        end
    end
end

--创建移动的列
function CodeGameScreenLottoPartyMachine:createMoveBonusReel(_col)
    local targSp = self:getFixSymbol(_col, 1, SYMBOL_NODE_TAG)
    local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

    local bonusReel = cc.Node:create()
    bonusReel:setPosition(pos)
    self.m_clipParent:addChild(bonusReel, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 1)

    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local bonusSymbol = self:createMoveBonus()
            local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
            local pos = bonusReel:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            local zorder = targSp:getLocalZOrder()
            bonusSymbol:setPosition(pos)
            bonusReel:addChild(bonusSymbol, zorder)
        end
    end
    return bonusReel
end

function CodeGameScreenLottoPartyMachine:createMoveBonus()
    local bonusSymbol = util_spineCreate("Socre_LottoParty_Bonus", true, true)
    util_spinePlay(bonusSymbol, "idleframe", false)
    return bonusSymbol
end
--bigSpot 赢的位置信息
function CodeGameScreenLottoPartyMachine:createBigSpotWinNum(changeCol, winSpotNum, totalBetNum)
    local winCsb = util_createAnimation("LottoParty_SpotTrigger.csb")
    local spotNumLab = winCsb:findChild("m_lb_num")
    local totalBetLab = winCsb:findChild("m_lb_num_tb")
    spotNumLab:setString(tostring(winSpotNum))
    totalBetLab:setString(util_formatCoins(totalBetNum, 10))

    local Panel3 = winCsb:findChild("Panel_3")
    local Panel4 = winCsb:findChild("Panel_4")
    local Panel5 = winCsb:findChild("Panel_5")
    Panel3:setVisible(false)
    Panel4:setVisible(false)
    Panel5:setVisible(false)
    if changeCol == 3 then
        Panel3:setVisible(true)
    elseif changeCol == 4 then
        Panel4:setVisible(true)
    elseif changeCol == 5 then
        Panel5:setVisible(true)
    end
    return winCsb
end

--变成大信号块 表现时的黄色遮罩
function CodeGameScreenLottoPartyMachine:createChangeBigSymbolYellowEffect(changeCol, pos)
    if changeCol > 5 then
        changeCol = 5
    end

    local effCsb = util_createAnimation("LottoParty_Socre_effect.csb")
    local actName = "actionframe4_" .. changeCol
    effCsb:runCsbAction(
        actName,
        false,
        function()
            effCsb:removeFromParent()
        end,
        60
    )
    effCsb:setPosition(pos)
    for i = 1, changeCol do
        local par = effCsb:findChild("Particle_" .. i)
        par:resetSystem()
        par:setPositionType(0)
    end
    self.m_clipParent:addChild(effCsb, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)
end

function CodeGameScreenLottoPartyMachine:playChangeBigBonusEffect(effectData)
    self.m_SpotOpenView.m_bClick = true
    self.m_effectData = effectData
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_bonus_trigger.mp3")
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local changeCol = #selfData.bonusColumns
    local winSpotNum = 0
    local totalBetNum = 0
    local spotData = {}

    if selfData and selfData.collectData then
        totalBetNum = selfData.collectData.coins
        winSpotNum = selfData.collectData.position + 1
        spotData = selfData.collectData
    end

    local pos = self:getBigSymbolPos(1, changeCol)
    --黄色遮罩
    self:createChangeBigSymbolYellowEffect(changeCol, pos)

    self:setSymbolVisibleByCol(1, changeCol, false)
    if self.m_bonusReel then
        for i = 1, #self.m_bonusReel do
            local bonusReel = self.m_bonusReel[i]
            bonusReel:setVisible(false)
        end
    end

    self.m_spotBigSymbol = util_spineCreate("Socre_LottoParty_Bonus", true, true)
    self.m_spotWinCsb = self:createBigSpotWinNum(changeCol, winSpotNum, totalBetNum)

    self.m_clipParent:addChild(self.m_spotBigSymbol, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_clipParent:addChild(self.m_spotWinCsb, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

    self.m_spotBigSymbol:setPosition(pos)
    self.m_spotWinCsb:setPosition(pos)
    local idlefameName = "idleframe" .. changeCol
    util_spinePlay(self.m_spotBigSymbol, idlefameName, false)
    scheduler.performWithDelayGlobal(
        function()
            local actName = "actionframe" .. changeCol
            util_spinePlay(self.m_spotBigSymbol, actName, false)
            util_spineFrameEvent(
                self.m_spotBigSymbol,
                actName,
                "Show",
                function()
                    self.m_spotWinCsb:runCsbAction(
                        "actionframe",
                        false,
                        function()
                        end,
                        60
                    )
                end
            )
            util_spineEndCallFunc(
                self.m_spotBigSymbol,
                actName,
                function()
                    self:showBonusSpotWinView(winSpotNum, spotData, changeCol)
                end
            )
        end,
        30 / 60,
        self:getModuleName()
    )
end

function CodeGameScreenLottoPartyMachine:showBonusSpotWinView(_num, _spotData, _changeCol)
    if self.m_SpotOpenView then
        self.m_SpotOpenView:setWinNum(_num, _spotData)
        self.m_SpotOpenView:setFunc(
            function()
                self:setAllSymbolVisible(true)
                if self.m_bonusReel then
                    for i = 1, #self.m_bonusReel do
                        local bonusReel = self.m_bonusReel[i]
                        bonusReel:removeFromParent()
                    end
                    self.m_bonusReel = nil
                end
                if self.m_spotWinCsb then
                    local overName = "over" .. _changeCol
                    util_spinePlay(self.m_spotBigSymbol, overName)
                    self.m_spotWinCsb:runCsbAction(
                        "over",
                        false,
                        function()
                            self.m_spotWinCsb:removeFromParent()
                        end,
                        60
                    )
                end

                if self.m_effectData then
                    self.m_effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end
        )
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_RANK)
        self.m_SpotOpenView:showOpenSpotNum(true)
    end
end

-- 根据Bonus Game 每关做的处理
function CodeGameScreenLottoPartyMachine:showBonusGameView(effectData)
    self.m_clickJackpot = true
    self:clearWinLineEffect()
    self:stopLinesWinSound()
    self:showDarkLayer()
    self.m_jackpotSymbol = {}
    self.m_clickJackpotPanel = {}
    self:playBonusJackpotTrigger(effectData)
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(false) 
    end
    
end

function CodeGameScreenLottoPartyMachine:playBonusJackpotTrigger(effectData)
    
    self.m_effectData = effectData
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_trigger.mp3")
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == self.SYMBOL_JACKPOT then
                    targSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if not targSp then
                        targSp = self:setSymbolToClipReel(iCol, iRow, symbolType)
                    end
                    local effCsb = self:creatJackpotWinOpenEff("actionframe1")
                    targSp:addChild(effCsb, 3)
                    targSp:runAnim(
                        "actionframe",
                        false,
                        function()
                            targSp:runAnim("idleframe", true)
                        end
                    )
                    local tag = targSp:getTag()
                    local clickCsb = self:ceateJackpotTouchView(tag, iRow)
                    targSp:addChild(clickCsb, 2)
                    self.m_jackpotSymbol[#self.m_jackpotSymbol + 1] = targSp
                    local jackpotData = {}
                    jackpotData.row = iRow
                    jackpotData.clickCsb = clickCsb
                    self.m_clickJackpotPanel[#self.m_clickJackpotPanel + 1] = jackpotData
                end
            end
        end
    end
    -- self:delayRefreshRoomData()
    self:delayOutGame()
end

function CodeGameScreenLottoPartyMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder

        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        --bonus 特殊处理
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))

        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end

function CodeGameScreenLottoPartyMachine:showDarkLayer()
    local nowHeight = self.m_iReelRowNum * self.m_SlotNodeH + 2
    local nowWidth = 778
    if not self.m_DarkLayer then
        self.m_DarkLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 200))
        self.m_DarkLayer:setContentSize(nowWidth, nowHeight)
        local reel = self:findChild("sp_reel_0")
        local posWorld = reel:getParent():convertToWorldSpace(cc.p(reel:getPosition()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        pos.y = pos.y - 1
        self.m_DarkLayer:setPosition(pos)
        self.m_clipParent:addChild(self.m_DarkLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 5)
    end
    self.m_DarkLayer:setVisible(true)
end

function CodeGameScreenLottoPartyMachine:hideDarkLayer()
    if self.m_DarkLayer then
        self.m_DarkLayer:setVisible(false)
    end
end

function CodeGameScreenLottoPartyMachine:showJackpotSymbleWin()
    for i, v in ipairs(self.m_clickJackpotPanel) do
        local jackpotData = v
        local overName = "over1"
        if jackpotData.row > 2 then
            overName = "over2"
        end
        local clickCsb = jackpotData.clickCsb
        clickCsb:runCsbAction(
            overName,
            false,
            function()
                clickCsb:removeFromParent()
            end,
            60
        )
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.hitReward then
        local winType = selfData.hitReward.type

        local reward = selfData.rewards
        local num = 1
        for i, v in ipairs(self.m_jackpotSymbol) do
            local tag = v:getTag()
            if self.m_clickTag == tag then
                local effCsb = self:creatJackpotWinOpenEff("actionframe2")
                v:addChild(effCsb, 3)
                if winType == 2 then
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_open_jackpot.mp3")
                else
                    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_open_coins.mp3")
                end
                v:runAnim(
                    "actionframe2",
                    false,
                    function()
                        local winCsb = self:ceateJackpotWinCsb(selfData.hitReward, true)
                        winCsb:runCsbAction("idle", false, nil, 60)
                        v.m_jackpotTag = winCsb
                        v:addChild(winCsb, 2)
                    end
                )
            else
                v:runAnim("actionframe_dark")
                local winCsb = self:ceateJackpotWinCsb(reward[num], false)
                winCsb:runCsbAction("actionframe_dark", false, nil, 60)
                v.m_jackpotTag = winCsb
                v:addChild(winCsb, 2)
                num = num + 1
            end
        end

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                self.m_jackpotWinCoins = true
                local winCoins = selfData.hitReward.value
                if winType == 2 then
                    self:showJackpotWin(
                        selfData.hitReward.name,
                        winCoins,
                        function()
                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            globalData.slotRunData.lastWinCoin = 0
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCoins, false, false})
                            globalData.coinsSoundType = 1
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum) -- 立即更改金币数量
                            globalData.slotRunData.lastWinCoin = lastWinCoin
                            self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
                            self:playOpenBonusJackpotEffect()
                        end
                    )
                else
                    self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCoins, false, false})
                    globalData.coinsSoundType = 1
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum) -- 立即更改金币数量
                    self:playOpenBonusJackpotEffect()
                end

                waitNode:removeFromParent()
            end,
            2.2
        )
    end
end

function CodeGameScreenLottoPartyMachine:creatJackpotWinOpenEff(actName)
    local effCsb = util_createAnimation("Socre_LottoParty_jackpot_effect.csb")
    effCsb:runCsbAction(
        actName,
        false,
        function()
            effCsb:removeFromParent()
        end,
        60
    )
    return effCsb
end

--显示中奖类型
function CodeGameScreenLottoPartyMachine:ceateJackpotWinCsb(_winData, _dark)
    local winType = 0
    local name = ""
    local coins = 0
    if _winData and _winData.type then
        winType = _winData.type
        name = _winData.name
        coins = _winData.value
    end
    local csb = util_createAnimation("LottoParty_jackpot_win.csb")

    local minorNode = csb:findChild("Node_minor")
    local majorNode = csb:findChild("Node_major")
    local grandNode = csb:findChild("Node_grand")

    local winLab = csb:findChild("BitmapFontLabel_1")
    local winLabdark = csb:findChild("BitmapFontLabel_1_dark")

    if winType == 1 then
        minorNode:setVisible(false)
        majorNode:setVisible(false)
        grandNode:setVisible(false)
        local score = util_formatCoins(coins, 3)
        winLab:setString(score)
        winLabdark:setString(score)
        if _dark then
            winLabdark:setVisible(false)
        else
            winLab:setVisible(false)
        end
    else
        winLab:setVisible(false)
        winLabdark:setVisible(false)
        if name == "Minor" then
            local minor = csb:findChild("minor")
            local minordark = csb:findChild("minor_dark")
            majorNode:setVisible(false)
            grandNode:setVisible(false)
            if _dark then
                minordark:setVisible(false)
            else
                minor:setVisible(false)
            end
        elseif name == "Major" then
            local major = csb:findChild("major")
            local majordark = csb:findChild("major_dark")
            minorNode:setVisible(false)
            grandNode:setVisible(false)
            if _dark then
                majordark:setVisible(false)
            else
                major:setVisible(false)
            end
        else
            local grand = csb:findChild("grand")
            local granddark = csb:findChild("grand_dark")
            minorNode:setVisible(false)
            majorNode:setVisible(false)
            if _dark then
                granddark:setVisible(false)
            else
                grand:setVisible(false)
            end
        end
    end

    return csb
end

function CodeGameScreenLottoPartyMachine:ceateJackpotTouchView(_tag, _row)
    local clicKPanel = util_createView("CodeLottoPartySrc.LottoPartyJackPotSymbolTouchView")
    clicKPanel:setTag(_tag)
    local startName = "actionframe1"
    local idleName = "idle1"

    if _row > 2 then
        startName = "actionframe2"
        idleName = "idle2"
    end
    clicKPanel:runCsbAction(
        startName,
        false,
        function()
            clicKPanel:setPanelTouch(true)
            clicKPanel:runCsbAction(idleName, true, nil, 60)
        end,
        60
    )

    clicKPanel:setClickFunc(
        function(tag)
            -- self:removeRefreshHandler()
            self:removeOutGameHandler()
            self:sendBonusData(tag)
        end
    )
    return clicKPanel
end

function CodeGameScreenLottoPartyMachine:showJackpotWin(jackPot, coins, func)
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_jackpot_tip.mp3")
    local jackPotWinView = util_createView("CodeLottoPartySrc.LottoPartyJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self, jackPot, coins, func)
end

function CodeGameScreenLottoPartyMachine:playOpenBonusJackpotEffect()
    if self.m_effectData then
        self.m_effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮
    end
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(true) 
    end
    
    self:resetMusicBg()
    self:hideDarkLayer()
end

function CodeGameScreenLottoPartyMachine:setSpotBonusMusic()
    self.m_currentMusicBgName = "LottoPartySounds/music_LottoParty_bonus_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenLottoPartyMachine:showSpotBonusWin(effectData)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    -- gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_tips_show.mp3")
    self:removeRefreshHandler()
    self.m_effectData = effectData
    self.m_MailTip:setVisible(false)
    self.m_SpotOpenView:setVisible(false)
    self:clearCurMusicBg()

    performWithDelay(
        self,
        function()
            self.m_reelPanel:setVisible(false)
            self.m_RoomListView:setVisible(false)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_RESET_BONUS_SPOT)
        end,
        40 / 60
    )
    if not self.m_spotWinView then
        self.m_spotWinView = util_createView("CodeLottoPartySpotSrc.LottoPartySpotBonusView", self.m_resultData)
        self.m_spotWinView:setMachine(self)
        self.m_spotWinView:setFunc(
            function()
                self.m_reelPanel:setVisible(true)
                self.m_RoomListView:setVisible(true)
            end,
            function(_winCoins)
                self.m_SpotOpenView:setVisible(true)
                self.m_spotWinView = nil
                self.m_bonusWinCoins = true
                if _winCoins > 0 then
                    self:showSpotWinView(_winCoins)
                else
                    self:playBonusOverEffect()
                end
            end
        )
        local node = self:findChild("Node_SpotBonusView")
        node:addChild(self.m_spotWinView)
    end
end

--bonus结束后效果衔接
function CodeGameScreenLottoPartyMachine:playBonusOverEffect()
    self:showOrHideMailTip()
    self:resetMusicBg()
    self:setMinMusicBGVolume()
    if self.m_effectData then
        self.m_effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮
    else
        self:delayRefreshRoomData()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
end

--jackpot 开奖消息
function CodeGameScreenLottoPartyMachine:sendBonusData(_tag)
    if not self.m_clickJackpot then
        return
    end
    if self.m_clickJackpot then
        self.m_clickJackpot = false
    end
    self.m_clickTag = _tag
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = {}}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

--消息返回
function CodeGameScreenLottoPartyMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "FEATURE" then
        release_print("消息返回胡来了")
        print(cjson.encode(spinData))

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)
        if spinData.action == "FEATURE" then
            self:showJackpotSymbleWin()
        end

        if spinData.action == "SPIN" then
            self:updateNetWorkData()
            self:setNetMysteryType()
        end
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

--打开邮件
function CodeGameScreenLottoPartyMachine:openMail()
    if self.m_MailTip then
        self.m_MailTip:setVisible(false)
        local mailTip = util_createView("CodeLottoPartySpotSrc.LottoPartyMailTip")
        mailTip:setClickEnable(false)
        self:findChild("Node_Mail"):addChild(mailTip)
        local movePos = cc.p(self:findChild("MailFlyNode"):getPosition())
        local delay = cc.DelayTime:create(64 / 60)
        local moveTo = cc.MoveTo:create(22 / 60, movePos)
        gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_open_mail.mp3")
        mailTip:runAction(cc.Sequence:create(delay, moveTo))
        mailTip:runCsbAction(
            "actionframe",
            false,
            function()
                mailTip:removeFromParent()
            end,
            60
        )
        scheduler.performWithDelayGlobal(
            function()
                self:showSpotMailWinView()
            end,
            110 / 60,
            self:getModuleName()
        )
    end
end

--spot开奖获得奖励弹板
function CodeGameScreenLottoPartyMachine:showSpotWinView(_winCoins, _func)
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_bonus_over_tip.mp3")
    local winView = util_createView("CodeLottoPartySpotSrc.LottoPartySpotBonusOverView")
    winView:initViewData(_winCoins)
    winView:setFunc(
        function()
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {_winCoins, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin
            -- self:checkFeatureOverTriggerBigWin(_winCoins, GameEffect.EFFECT_BONUS)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            self:playBonusOverEffect()
        end
    )
    local node = self:findChild("Node_SpotBonusView")
    node:addChild(winView)
end

--邮箱获得奖励弹板
function CodeGameScreenLottoPartyMachine:showSpotMailWinView()
    gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_bonus_over_tip.mp3")
    local winView = util_createView("CodeLottoPartySpotSrc.LottoPartySpotMailWin")
    local _winCoins = LottoPartyManager:getMailWinCoins()
    winView:initViewData(_winCoins)
    winView:setPosition(display.width/2,display.height/2)
    winView:setFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    )
    gLobalViewManager:showUI(winView)
end

--设置bonus scatter 层级
function CodeGameScreenLottoPartyMachine:getBounsScatterDataZorder(symbolType)
    local order = 0
    order = BaseNewReelMachine.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_JACKPOT then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    return order
end

function CodeGameScreenLottoPartyMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
            self:delayRefreshRoomData()
            self:delayOutGame()
        end
    )
    if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
        if self.m_RoomListView then
            self.m_RoomListView:setBtnTouch(true)
        end
        if self.m_SpotOpenView then
            self.m_SpotOpenView:setClickTouch(true)
        end
        if self.m_MailTip then
            self.m_MailTip:setClickEnable(true)
        end
    end
end

function CodeGameScreenLottoPartyMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
            self:delayRefreshRoomData()
            self:delayOutGame()
        end
    )
    self:stopBonusIdleSound()
    self:setBonusSymbolPlayIdle()
    BaseNewReelMachine.slotReelDown(self)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_RANK, {true})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT, {true})
end

function CodeGameScreenLottoPartyMachine:delayRefreshRoomData()
    if not self.m_bOutGame then
        self:removeRefreshHandler()
        self.m_refreshRoomId =
            scheduler.performWithDelayGlobal(
            function()
                self:sendRefreshData()
            end,
            10,
            "refreshRoom"
        )
    end
end

--十分钟不spin弹出弹板 离开房间
function CodeGameScreenLottoPartyMachine:delayOutGame()
    self:removeOutGameHandler()
    self.m_OutGameId =
        scheduler.performWithDelayGlobal(
        function()
            self:showGameOutView()
        end,
        10 * 60,
        "OutGameHandler"
    )
end

function CodeGameScreenLottoPartyMachine:removeOutGameHandler()
    if self.m_OutGameId ~= nil then
        scheduler.unschedulesByTargetName("OutGameHandler")
        self.m_OutGameId = nil
    end
end

function CodeGameScreenLottoPartyMachine:sendRefreshData()
    local gameName = "LottoParty"
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionData(
        gameName,
        function()
            if not tolua.isnull(self) then
                self:changeSuccess()
            end
        end,
        function(errorCode, errorData)
            print("----- errorCode -----", errorCode)
            if not tolua.isnull(self) then
                self:changeFailed()
            end
        end
    )
end

function CodeGameScreenLottoPartyMachine:changeSuccess()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_RANK)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_UPDATE_OPEN_SPOT)
    if LottoPartyManager:getSpotResult() then
        self.m_resultData = LottoPartyManager:getSpotResult()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOTTO_PARTY_SPOT_BONUS)
        
    else
        self:delayRefreshRoomData()
    end
end

function CodeGameScreenLottoPartyMachine:changeFailed()
end
---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenLottoPartyMachine:MachineRule_ResetReelRunData()
    local triggerCol = self:getBonusTriggerCol()

    if triggerCol > 0 then
        for iCol = 1, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            local reelLongRunTime = 1.5

            if iCol > triggerCol then
                local iRow = columnData.p_showGridCount

                local lastColLens = reelRunInfo[1]:getReelRunLen()
                if iCol ~= 1 then
                    lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                    reelRunInfo[iCol - 1]:setNextReelLongRun(true)
                end

                local colHeight = columnData.p_slotColumnHeight
                local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                local runLen = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高

                local preRunLen = reelRunData:getReelRunLen()
                reelRunData:setReelRunLen(runLen)

                if triggerCol ~= iCol then
                    reelRunData:setReelLongRun(true)
                    reelRunData:setNextReelLongRun(true)
                end
            else
                local lastColLens = reelRunInfo[triggerCol]:getReelRunLen()
                local preRunLen = reelRunInfo[iCol].initInfo.reelRunLen
                local pretriggerColRunLen = reelRunInfo[triggerCol].initInfo.reelRunLen
                local addRunLen = preRunLen - pretriggerColRunLen

                reelRunData:setReelRunLen(lastColLens + addRunLen)
                reelRunData:setReelLongRun(false)
                reelRunData:setNextReelLongRun(false)
            end
        end
    end
end

function CodeGameScreenLottoPartyMachine:getBonusTriggerCol()
    local triggerColNum = 2
    local colNum = 0
    local triggerCol = 0

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == self.SYMBOL_BONUS_1 then
                bonusNum = bonusNum + 1
            end
        end

        if bonusNum >= self.m_iReelRowNum then
            colNum = colNum + 1
        end

        if colNum == triggerColNum then
            triggerCol = iCol

            return triggerCol
        end
    end

    return triggerCol
end

function CodeGameScreenLottoPartyMachine:playCustomSpecialSymbolDownAct(slotNode)

    CodeGameScreenLottoPartyMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

end

function CodeGameScreenLottoPartyMachine:checkFullRowBonus(_iCol)
    local bonusNum = 0
    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][_iCol]
        if symbolType == self.SYMBOL_BONUS_1 then
            bonusNum = bonusNum + 1
        end
    end

    if bonusNum >= self.m_iReelRowNum then
        return true
    end

    return false
end

function CodeGameScreenLottoPartyMachine:stopBonusIdleSound()
    if self.m_bonusIdleId then
        gLobalSoundManager:stopAudio(self.m_bonusIdleId)
        self.m_bonusIdleId = nil
    end
end

function CodeGameScreenLottoPartyMachine:setLongRunBonusIdle(_iCol)
    if _iCol == self.m_iReelColumnNum then
        return
    end
    if not self.m_bonusIdleId then
    -- self.m_bonusIdleId = gLobalSoundManager:playSound("LottoPartySounds/sound_LottoParty_bonus_idle.mp3", true)
    end

    local triggerCol = self:getBonusTriggerCol()

    if _iCol >= triggerCol then
        for iCol = 1, self.m_iReelColumnNum do
            if iCol <= _iCol then
                if self:checkFullRowBonus(iCol) then
                    if self.m_longRunBonusColList[iCol] == nil then
                        self.m_longRunBonusColList[iCol] = true
                        for iRow = 1, self.m_iReelRowNum do
                            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                            if targSp then
                                if targSp.p_symbolType == self.SYMBOL_BONUS_1 then
                                    local waitNode = cc.Node:create()
                                    self:addChild(waitNode)
                                    performWithDelay(
                                        waitNode,
                                        function()
                                            targSp:runAnim("idleframe2", true)
                                            waitNode:removeFromParent()
                                        end,
                                        0.5
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenLottoPartyMachine:setBonusSymbolPlayIdle()
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            for iCol = 1, self.m_iReelColumnNum do
                if self:checkFullRowBonus(iCol) then
                    for iRow = 1, self.m_iReelRowNum do
                        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                        if targSp then
                            if targSp.p_symbolType == self.SYMBOL_BONUS_1 then
                                targSp:runAnim("idleframe", false)
                            end
                        end
                    end
                end
            end
        end,
        0.5
    )
end

function CodeGameScreenLottoPartyMachine:setNormalSymbolType()
    self.m_initNodeSymbolType = math.random(0, 8)
end

function CodeGameScreenLottoPartyMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
    local changedSymbolType = 0

    if colIndex and reelDatas then
        if self.m_initNodeCol ~= colIndex then
            self.m_initNodeCol = colIndex
            self:setNormalSymbolType()
            changedSymbolType = self.m_initNodeSymbolType
        else
            if self.m_initNodeSymbolType then
                changedSymbolType = self.m_initNodeSymbolType
            else
                changedSymbolType = symbolType
            end
        end
    else
        changedSymbolType = symbolType
    end

    return changedSymbolType
end

function CodeGameScreenLottoPartyMachine:showGameOutView()
    self.m_bOutGame = true
    self:removeRefreshHandler()
    self:removeOutGameHandler()
    local view = util_createView("CodeLottoPartySpotSrc.LottoPartyGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

return CodeGameScreenLottoPartyMachine
