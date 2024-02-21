---
-- island li
-- 2019年1月26日
-- CodeGameScreenPowerUpMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"

local PowerUpSlotsNode = require "CodePowerUpSrc.PowerUpSlotsNode"

local CodeGameScreenPowerUpMachine = class("CodeGameScreenPowerUpMachine", BaseSlotoManiaMachine)

CodeGameScreenPowerUpMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenPowerUpMachine.m_betLevel = 0

CodeGameScreenPowerUpMachine.SYMBOL_SPECIAL_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 -- 自定义的小块类型

CodeGameScreenPowerUpMachine.SYMBOL_BONUS_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_SCATTER + 1 -- 自定义的小块类型

CodeGameScreenPowerUpMachine.m_BonusTipMusicPath = "PowerUpSounds/music_PowerUp_triggerBonus.mp3"

CodeGameScreenPowerUpMachine.bgMusicList  = {"PowerUpSounds/music_PowerUp_BgSound.mp3","PowerUpSounds/powerup_wheelBgSound2.mp3","PowerUpSounds/powerup_towerBgSound.mp3"}

--状态类型
CodeGameScreenPowerUpMachine.STATE_BASE_GAME = 1
CodeGameScreenPowerUpMachine.STATE_WHEEL_GAME = 2
CodeGameScreenPowerUpMachine.STATE_TOWER_GAME = 3
--结果类型
CodeGameScreenPowerUpMachine.RESULT_WHEEL = 1
CodeGameScreenPowerUpMachine.RESULT_TOWER = 2
CodeGameScreenPowerUpMachine.m_curRequest = nil

CodeGameScreenPowerUpMachine.m_viewState = nil

CodeGameScreenPowerUpMachine.m_clickBet = nil

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

function CodeGameScreenPowerUpMachine:changeViewNodePos( )

    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5

        local Node_changeScene = self:findChild("Node_changeScene")
        Node_changeScene:setPositionY(Node_changeScene:getPositionY() - posY)

        local Node_win = self:findChild("Node_win")
        Node_win:setPositionY(Node_win:getPositionY() - posY * 0.8)
        local Node_tower = self:findChild("Node_tower")
        Node_tower:setPositionY(Node_tower:getPositionY() - posY  + 25)
        Node_tower:setScale(0.9)
        local baseWheel = self:findChild("baseWheel")
        baseWheel:setPositionY(baseWheel:getPositionY() - posY)
        local Node_wheel1 = self:findChild("Node_wheel1")

        local Node_winCoins = self:findChild("Node_winCoins")


        local pro = display.height/display.width
        if pro > 1.867 and  pro < 2 then
            Node_win:setPositionY(Node_win:getPositionY() + 30)
            Node_wheel1:setPositionY(Node_wheel1:getPositionY() - posY * 0.7)
            Node_wheel1:setScale(1.3)
            Node_tower:setPositionY(Node_tower:getPositionY() + 15)
        elseif pro > 2 then
            Node_win:setPositionY(Node_win:getPositionY() + 10)
            Node_wheel1:setPositionY(Node_wheel1:getPositionY() - posY * 0.3)
            Node_wheel1:setScale(1.5)
            Node_tower:setPositionY(Node_tower:getPositionY() + 15)
            Node_winCoins:setPositionY(Node_winCoins:getPositionY() + 100)
        elseif pro == 2 then

            Node_win:setPositionY(Node_win:getPositionY() + 10)
            Node_wheel1:setPositionY(Node_wheel1:getPositionY() - posY * 0.3-10)
            Node_wheel1:setScale(1.32)
            Node_tower:setPositionY(Node_tower:getPositionY() + 15)
        else

            Node_win:setPositionY(Node_win:getPositionY() + 25)

            if pro < 1.67 then
                Node_wheel1:setScale(1)
                Node_wheel1:setPositionY(Node_wheel1:getPositionY() - posY - 80)
            else
                Node_wheel1:setScale(1.2)
                Node_wheel1:setPositionY(Node_wheel1:getPositionY() - posY - 50)
            end


        end




        local Node_jackpot = self:findChild("Node_jackpot")
        Node_jackpot:setPositionY(Node_jackpot:getPositionY() + posY - 120)


    elseif display.height >= FIT_HEIGHT_MIN and  display.height < FIT_HEIGHT_MAX then
        local Node_jackpot = self:findChild("Node_jackpot")
        Node_jackpot:setPositionY(Node_jackpot:getPositionY() - 10)

        local Node_wheel1 = self:findChild("Node_wheel1")
        Node_wheel1:setScale(1.2)
        Node_wheel1:setPositionY(Node_wheel1:getPositionY()  - 50)

        local Node_win = self:findChild("Node_win")
        Node_win:setPositionY(Node_win:getPositionY()  - 10)

        local Node_tower = self:findChild("Node_tower")
        Node_tower:setPositionY(Node_tower:getPositionY() - 10 )

    elseif display.height < FIT_HEIGHT_MIN then

        local Node_jackpot = self:findChild("Node_jackpot")
        Node_jackpot:setPositionY(Node_jackpot:getPositionY() - 10)

        local Node_wheel1 = self:findChild("Node_wheel1")
        Node_wheel1:setScale(1.2)
        Node_wheel1:setPositionY(Node_wheel1:getPositionY()  - 70)

        local Node_win = self:findChild("Node_win")
        Node_win:setPositionY(Node_win:getPositionY()  - 50)

        local Node_tower = self:findChild("Node_tower")
        Node_tower:setPositionY(Node_tower:getPositionY() - 50 )
    end


    if globalData.slotRunData.isPortrait then
        local bangHeight =  util_getBangScreenHeight()
        local nodeJackpot = self:findChild("Node_jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY()  - bangHeight )

        local bangDownHeight = util_getSaveAreaBottomHeight()
        nodeJackpot:setPositionY(nodeJackpot:getPositionY()  - bangDownHeight )
    end

end

function CodeGameScreenPowerUpMachine:scaleMainLayer()
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
        if display.height >= FIT_HEIGHT_MAX then
            mainScale = (FIT_HEIGHT_MAX + 110 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 37)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 45 )
            end

        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 10 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 3)
        else
            mainScale = (display.height + 25 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 15)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)

end

-- 构造函数
function CodeGameScreenPowerUpMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_betLevel = nil
    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenPowerUpMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("PowerUpConfig.csv", "PowerUpConfig2.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {1,3,5}
    self:runCsbAction("idle",true)
end

function CodeGameScreenPowerUpMachine:enterLevel()
    BaseSlotoManiaMachine.enterLevel(self)
    if self.m_initSpinData == nil then
        self.m_currentMusicBgName = self.bgMusicList[1]
    end
end

function CodeGameScreenPowerUpMachine:initGameStatusData(gameData)

    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and  gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin
    -- feature
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0--gameData.totalWinCoins
    self:setLastWinCoin( totalWinCoins )

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin,self.m_lineDataPool,self.m_symbolCompares,feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                if feature.bonus.status == "CLOSED" and feature.bonus.choose then
                    local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                    feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = - bet
                end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status

            end
        end
        self.m_initFeatureData:parseFeatureData(feature)
        -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost 
    end
    
    if collect and type(collect)=="table" and #collect>0 then
        for i=1,#collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot)=="table" and #jackpot>0 then
        self.m_jackpotList=jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and  gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    self:initMachineGame()
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPowerUpMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PowerUp"
end

function CodeGameScreenPowerUpMachine:getNetWorkModuleName()
    return "PowerUpV2"
end

function CodeGameScreenPowerUpMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 轮盘
    self.m_wheelView = util_createView("CodePowerUpSrc.PowerUpWheelView",self)
    self:findChild("Node_wheel1"):addChild(self.m_wheelView)

    self.m_betChoiceIcon = util_createView("CodePowerUpSrc.PowerUpHighLowBetIcon",self)
    self:findChild("betChoiceNode"):addChild(self.m_betChoiceIcon)

    --切换动画
    self.m_changeSceneAni = util_createAnimation("PowerUp_changeScene.csb")
    self.m_changeSceneAni:setPosition(0,-294)
    self.m_changeSceneAni:setVisible(false)
    self:findChild("Node_changeScene"):addChild(self.m_changeSceneAni)

    --jacpot界面
    self.m_jackpotView = util_createView("CodePowerUpSrc.PowerUpJackpotView",self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotView)

    --塔轮
    self.m_towerWheel = util_createView("CodePowerUpSrc.PowerUpTowerWheel",self)
    self:findChild("Node_tower"):addChild(self.m_towerWheel)
    self.m_towerWheel:setVisible(false)

    --
    self.m_towerNextView = util_createView("CodePowerUpSrc.PowerUpTowerNextView",self)
    self:findChild("Node_win"):addChild(self.m_towerNextView)
    self.m_towerNextView:setVisible(false)

    self.m_topWinCoinsView = util_createView("CodePowerUpSrc.PowerUpGoodLuckyView",self)
    self:findChild("Node_winCoins"):addChild(self.m_topWinCoinsView)
    self.m_topWinCoinsView:setVisible(false)



    self.m_Particle_1 = self:findChild("Particle_1")
    self.m_Particle_2 = self:findChild("Particle_2")
    self.m_Particle_3 = self:findChild("Particle_3")

    self.m_Particle_1:setVisible(false)
    self.m_Particle_2:setVisible(false)
    self.m_Particle_3:setVisible(false)
    self.m_Particle_1:stopSystem()
    self.m_Particle_2:stopSystem()
    self.m_Particle_3:stopSystem()

    self.m_baseWheel1 = self:findChild("baseWheel1")



    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
            soundTime = 3
        elseif winRate > 6 then
            soundIndex = 4
            soundTime = 4
        end
        local soundName = "PowerUpSounds/music_PowerUp_last_win_".. soundIndex .. ".mp3"
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end



function CodeGameScreenPowerUpMachine:changeBgScene(type)
    if type == 1 then
        self.m_gameBg:runCsbAction("freespin_normal",false,function()
            self.m_gameBg:runCsbAction("normal",true)
        end)
    else
        self.m_gameBg:runCsbAction("normal_freespin",false,function()
            self.m_gameBg:runCsbAction("freespin",true)
        end)
    end
end

function CodeGameScreenPowerUpMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:requestSpinResult()
    end,ViewEventType.NOTIFY_POWERUP_SPECIAL_SPIN)

    gLobalNoticManager:addObserver(self,function(self,params)

    end,ViewEventType.NOTIFY_POWERUP_TOWER_OVER)

    gLobalNoticManager:addObserver(self,function(self,params)
        local time = 2
        if self.m_runSpinResultData.p_selfMakeData.select  ==  "BONUS"  then--PowerUp_Wheel_xiaoyuan01_1
            if self.m_towerWheel.m_curPlayLevel then
                if self.m_towerWheel.m_curPlayLevel >= 5 then
                    time = 3
                elseif self.m_towerWheel.m_curPlayLevel >= 3 then
                    time = 2
                else
                    time = 1
                end
            end
        elseif self.m_runSpinResultData.p_selfMakeData.select  ==  "MINI"  then
            time = 1
        elseif self.m_runSpinResultData.p_selfMakeData.select  ==  "MINOR"  then
            time = 2
        elseif self.m_runSpinResultData.p_selfMakeData.select  ==  "MAJOR"  then
            time = 2
        elseif self.m_runSpinResultData.p_selfMakeData.select  ==  "GRAND"  then
            time = 3
        else
            time = 2
        end
        -- self.m_towerNextView:showWinCount(self.m_runSpinResultData.p_bonusExtra.bWinCoins,time)
        self.m_topWinCoinsView:setVisible(true)
        self.m_topWinCoinsView:updateWin(self.m_runSpinResultData.p_bonusExtra.bWinCoins,time)
    end,ViewEventType.NOTIFY_POWERUP_ROLL_OVER)

end



function CodeGameScreenPowerUpMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()
    if self.m_initSpinData and self.m_initSpinData.p_bonusStatus ~= "OPEN" then
        performWithDelay(self, function()
            if self.m_betLevel == 0 then
                self:showChoiceBetView()
            end
        end, 0.2)
    end
end

function CodeGameScreenPowerUpMachine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self,param)
    local isSucc = param[1]
    local spinData = param[2]
    self.m_spineNodeList = {}

    if isSucc then
        self.m_resultCoins = param[3].resultCoins
        if spinData.action ~= "SPIN" then
            self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.type == "3" then
                self.m_towerWheel:updateViewData(self.m_runSpinResultData)
            else
                self.m_wheelView:updateViewData(self.m_runSpinResultData)
            end
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN)
    end

    -- self.p_bonusExtra.bWinCoins = data.bonus.bsWinCoins
    -- self.p_bonusStatus = data.bonus.status
    -- self.p_bonusExtra = data.bonus.extra
    -- if self.m_runSpinResultData.p_bonusStatus == "OPEN" then
        --p_selfMakeData
end

function CodeGameScreenPowerUpMachine:getWinLineSymboltType(winLineData,lineInfo )
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        if winLineData.p_id == -1 then
            local poList = self:getAllRowAndColByPos(posData)
            for i=1,#poList do
                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = poList[i]  -- 连线元素的 pos信息
            end
            local symbolType = self.m_stcValidSymbolMatrix[poList[1].iX][poList[1].iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
            end
        else
            local rowColData = self:getRowAndColByPos(posData)
            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
            end
        end
    end
    return enumSymbolType
end

function CodeGameScreenPowerUpMachine:lineLogicWinLines( )
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        
        self:compareScatterWinLines(winLines)

        for i=1,#winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo,iconsPos)
            
            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            if winLineData.p_id ~= -1 then
                lineInfo.iLineSymbolNum = #iconsPos
            else
                lineInfo.iLineSymbolNum = #lineInfo.vecValidMatrixSymPos
            end
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
            
            if lineInfo.iLineSymbolNum >=5 then
                isFiveOfKind=true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end

    end

    return isFiveOfKind
end

---
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function CodeGameScreenPowerUpMachine:getAllRowAndColByPos(posData)
    local posList = {}
    for i=1,self.m_iReelRowNum do
        posList[#posList + 1] = self:getRowAndColByPos(posData + self.m_iReelColumnNum*(i-1))
    end
    return posList
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPowerUpMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SPECIAL_SYMBOL then
        return "Socre_PowerUp_Scatter"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPowerUpMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--播放bonus tip music
function CodeGameScreenPowerUpMachine:playBonusTipMusicEffect()
    if self.m_curRequest then
        if self.m_BonusTipMusicPath ~= nil then
            gLobalSoundManager:playSound(self.m_BonusTipMusicPath)
        end
    end

end

----------------------------- 玩法处理 -----------------------------------
-- 断线重连
function CodeGameScreenPowerUpMachine:MachineRule_initGame(  )

    if self.m_runSpinResultData.p_bonusStatus == "OPEN" then

        if self.m_runSpinResultData.p_selfMakeData and self:checkInTower() then
            if self.m_runSpinResultData.p_bonusExtra.bWinCoins > 0 then
                self.m_topWinCoinsView:setVisible(true)
                self.m_topWinCoinsView:initView(self.m_runSpinResultData.p_bonusExtra.bWinCoins)
            end
            self:changeGameState(self.STATE_TOWER_GAME,{isReConnect = true})
        else
            if  self.m_runSpinResultData.p_selfMakeData.type == nil or self.m_runSpinResultData.p_selfMakeData.type == "3" or self.m_runSpinResultData.p_selfMakeData.type == "2" then--tower -> respin 之后断线重连
                self:changeGameState(self.STATE_WHEEL_GAME,{nextViewState = 1,isReConnect = true})
            else          -- wheel 界面断线重连
                self:changeGameState(self.STATE_WHEEL_GAME,{nextViewState = 2,isReConnect = true})
            end
            performWithDelay(self,function()
                self.m_wheelView:updateViewData(self.m_runSpinResultData,true)
            end,0.5)
        end
    else
        self:changeGameState(self.STATE_BASE_GAME,{isReConnect = true})
    end

end
function CodeGameScreenPowerUpMachine:checkInTower()
    if self.m_runSpinResultData.p_selfMakeData then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData.level and selfData.level > 0 and selfData.level < #selfData.bonusWheel then
            return true
        end
    end
    return false
end

--
--单列滚动停止回调
--
function CodeGameScreenPowerUpMachine:slotOneReelDown(reelCol)
    if globalData.slotRunData.gameSpinStage == QUICK_RUN then
        if reelCol == 1 then
            local soundIndex = math.random(1,5)
            gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_reelDownSound"..soundIndex..".mp3")
        end
    else
        local soundIndex = math.random(1,5)
        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_reelDownSound"..soundIndex..".mp3")
    end

    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)
    local isPlayScatter = true
    local isPlayBonus = true
    -- 播放动画
      for i = 1, self.m_iReelRowNum, 1 do

          local symbolType = self.m_stcValidSymbolMatrix[i][reelCol]

          if symbolType == self.SYMBOL_BONUS_SYMBOL then
            -- local symbolNode = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,i,SYMBOL_NODE_TAG))
            local symbolNode = self:getReelParentChildNode(reelCol,i)

            local soundPath = "PowerUpSounds/music_PowerUp_bonusBuling.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

            symbolNode:runAnim("buling",false)
            self.m_spineNodeList[#self.m_spineNodeList + 1] = symbolNode

            self:playSpineAnim(#self.m_spineNodeList,"idleframe")
            symbolNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)

            if isPlayScatter then
                isPlayScatter = false
            end
          end
      end
end
function CodeGameScreenPowerUpMachine:playSpineAnim(index,aniName)
    performWithDelay(self.m_spineNodeList[index],function()
        if self.m_spineNodeList and self.m_spineNodeList[index] then
            self.m_spineNodeList[index]:runAnim(aniName,true)
        end
    end,0.7)
end

--[[
    @desc:  重写解决 bonus默认动画循环播放问题
    author:{author}
    time:2019-07-25 17:34:52
    --@symbolType:
	--@ccbName:
    @return:
]]
function CodeGameScreenPowerUpMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:"..ccbName)
        return nil
    end
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:initSpineInfo(spineSymbolData[1],spineSymbolData[2])
            node.m_defaultAnimLoop = true --bonus默认动画循环播放问题
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        return node
    end
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenPowerUpMachine:showBonusGameView(effectData)

   self:changeGameState(self.STATE_WHEEL_GAME,{nextViewState = 1})
   effectData.p_isPlay = true
   return true
end

--小块
function CodeGameScreenPowerUpMachine:getBaseReelGridNode()
    return "CodePowerUpSrc.PowerUpSlotsNode"
end


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenPowerUpMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            -- showFreeSpinView()
    end,0.5)



end

function CodeGameScreenPowerUpMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPowerUpMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)


    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenPowerUpMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenPowerUpMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end
function CodeGameScreenPowerUpMachine:requestSpinResult()
    self.m_curRequest = true
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

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
    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
        self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
        self:getCurrSpinMode() ~= RESPIN_MODE
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
   -- 拼接 collect 数据， jackpot 数据
   local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
        data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( )}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPowerUpMachine:addSelfEffect()

end
function CodeGameScreenPowerUpMachine:resetMusicBg(isMustPlayMusic)
    if self.m_currentMusicId then
        gLobalSoundManager:stopBgMusic(self.m_currentMusicId)
    end
    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        self.m_currentMusicId =gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end
function CodeGameScreenPowerUpMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            self:resetMusicBg()
            self:setMinMusicBGVolume()
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end
function CodeGameScreenPowerUpMachine:changeBgMusic(stateData)
    self.m_currentMusicBgName = self.bgMusicList[self.m_viewState]
    if stateData and stateData.isReConnect  then

    else
        self:resetMusicBg()
    end
end
--切换场景
--[[
    @desc:
    author:{author}
    time:2019-07-26 13:56:01
    --@state:
	--@stateData: isReConnect 是否是重连进来  callback 回调  nextViewState
    @return:
]]
function CodeGameScreenPowerUpMachine:changeGameState(state,stateData)
    if self.m_viewState == state then
        if stateData and stateData.isRespin then
        else
            return
        end
    end
    self.m_viewState = state
    if state == self.STATE_BASE_GAME then
        self:changeBgMusic(stateData)
        self.m_baseWheel1:setPosition(cc.p(0,0))
        self.m_wheelView:resetView()
        self.m_wheelView:setVisible(true)

        util_playMoveToAction(self.m_wheelView,0.5,cc.p(0,0),function()
            if stateData and stateData.callback then
                stateData.callback()
            end
        end)

        util_playScaleToAction(self.m_wheelView,0.5,1)

        self.m_bottomUI:setVisible(true)
        self.m_towerWheel:setVisible(false)
        self.m_jackpotView:setVisible(true)
        self.m_jackpotView:playAnimation(false)
        self.m_towerNextView:setVisible(false)
        self.m_topWinCoinsView:setVisible(false)

    elseif state == self.STATE_WHEEL_GAME then
        self.m_wheelView:resetView()
        self.m_wheelView:setVisible(true)
        self.m_towerNextView:resetView()

        local inner = function()
            self.m_jackpotView:setVisible(true)
            self.m_jackpotView:playAnimation(true)
            local AddbigWheelMovetoY = 0
            local AddbigWheelScale = 0
            if display.height > FIT_HEIGHT_MAX then
                local pro = display.height/display.width
                if pro > 1.867 and  pro < 2 then
                    AddbigWheelScale = - 0.15
                elseif pro == 2 then
                    AddbigWheelMovetoY = 50
                    AddbigWheelScale = - 0.1
                elseif pro > 2 then
                    AddbigWheelMovetoY = 70
                    AddbigWheelScale = - 0.1
                else
                    AddbigWheelMovetoY = 40
                    AddbigWheelScale = - 0.15
                end
            elseif display.height >= FIT_HEIGHT_MIN and  display.height < 1153 then

            elseif display.height < FIT_HEIGHT_MIN then
                AddbigWheelMovetoY = 13
                AddbigWheelScale = 0
            end
            util_playMoveToAction(self.m_wheelView,0.5,cc.p(0,-294 + AddbigWheelMovetoY))
            util_playScaleToAction(self.m_wheelView,0.5,1.45 + AddbigWheelScale,function()
                if stateData then
                    self.m_wheelView:showAnchor(1)
                    if stateData.nextViewState == 1 then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN)
                    elseif stateData.nextViewState == 2 then
                        self.m_towerNextView:showGoodLuck()
                    else

                    end
                    self.m_towerNextView:setVisible(true)
                end
            end)
        end
        if stateData and (stateData.isReConnect or stateData.isDirect) then
            self:changeBgMusic(stateData)
            inner()
            self.m_baseWheel1:setPosition(0,-800)
            self.m_bottomUI:setVisible(false)
        else
            globalMachineController:playBgmAndResume("PowerUpSounds/music_PowerUp_startWheel.mp3",3,0,1)

            self:changeBgMusic(stateData)
            performWithDelay(self,function()
                self.m_Particle_2:setVisible(true)
                self.m_Particle_2:resetSystem()
            end,0.15)
            self.m_Particle_1:setVisible(true)
            self.m_Particle_1:resetSystem()
            self.m_Particle_3:setVisible(true)
            self.m_Particle_3:resetSystem()
            util_playMoveToAction(self.m_baseWheel1,1,cc.p(0,-800))

            util_playFadeOutAction(self.m_bottomUI,0.5,function()
                inner()
                self.m_bottomUI:setVisible(false)
                self.m_bottomUI:setOpacity(255)
            end)
        end
        self.m_towerWheel:setVisible(false)

    elseif state == self.STATE_TOWER_GAME then
        self:changeBgMusic(stateData)
        self.m_wheelView:setVisible(false)
        local inner = function()
            self.m_towerWheel:setVisible(true)
            self.m_towerWheel:resetView()

            if stateData then
                self.m_towerNextView:showGoodLuck()
                self.m_towerWheel:updateViewData(self.m_runSpinResultData,stateData.isReConnect)
            else
                self.m_towerWheel:updateViewData(self.m_runSpinResultData)
            end
            self.m_towerNextView:setVisible(true)
        end
        if stateData and stateData.isReConnect then
            self:changeBgScene(2)
            self.m_baseWheel1:setPosition(0,-800)
            inner()
        else
            util_playMoveToAction(self.m_baseWheel1,1,cc.p(0,-2000))
            inner()
        end
        self.m_bottomUI:setVisible(false)
        self.m_jackpotView:setVisible(false)
    end
end

--配合切换场景
function CodeGameScreenPowerUpMachine:hideJackpotAndNextView(callback,bgType)
    self.m_changeSceneAni:setVisible(true)
    self.m_changeSceneAni:playAction("show",false)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_changeScene.mp3")
    self:changeBgScene(bgType)
    self.m_jackpotView:setVisible(false)
    self.m_towerNextView:setVisible(false)
    performWithDelay(self,function()
        if callback then
            callback()
        end
    end,0.7)
end
--jackpot弹窗
function CodeGameScreenPowerUpMachine:showBonusJackpot(type)
    self:clearCurMusicBg()
    self:changeGameState(self.STATE_BASE_GAME)
    if type  ==  "MINI"  then
        self:showSelfJackPot(4)
    elseif type  ==  "MINOR"  then
        self:showSelfJackPot(3)
    elseif type  ==  "MAJOR"  then
        self:showSelfJackPot(2)
    elseif type  ==  "GRAND"  then
        self:showSelfJackPot(1)
    end
end

function CodeGameScreenPowerUpMachine:showSelfJackPot(index)

    globalData.jackpotRunData:notifySelfJackpot(self.m_runSpinResultData.p_winAmount,index)
    local view=util_createView("CodePowerUpSrc.PowerUpJackpoWinView",{coins = self.m_runSpinResultData.p_winAmount,type = index,callback=function()
        self:checkSelfWinType(self.m_runSpinResultData.p_bonusExtra.bWinCoins,function()
            self:setLastWinCoin(self.m_runSpinResultData.p_bonusWinCoins)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,self.m_resultCoins)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_bonusWinCoins,false,false})
            self:playGameEffect()
        end)
    end}, self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
end

function CodeGameScreenPowerUpMachine:showFeatureResult(type,isAllOver,_callback)
    self:clearCurMusicBg()
    local view=util_createView("CodePowerUpSrc.PowerUpFeatureResultView",{coins = self.m_runSpinResultData.p_bonusExtra.bWinCoins,type = type,callback = function()
        if isAllOver then--p_bonusWinCoins
            self:setLastWinCoin(self.m_runSpinResultData.p_bonusWinCoins)--总的赢钱数
            --bWinCoins 本次赢钱数
            if type == self.RESULT_TOWER then
                self:hideJackpotAndNextView(function()
                    self:changeGameState(self.STATE_BASE_GAME,{callback=function()

                        self:checkSelfWinType(self.m_runSpinResultData.p_bonusExtra.bWinCoins,function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,self.m_resultCoins)
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_bonusWinCoins,false,false})
                            self:playGameEffect()
                        end)
                    end})
                end,1)
            else--p_winAmount
                self:changeGameState(self.STATE_BASE_GAME,{callback=function()

                    self:checkSelfWinType(self.m_runSpinResultData.p_bonusExtra.bWinCoins,function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,self.m_resultCoins)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_bonusWinCoins,false,false})
                        self:playGameEffect()
                    end)
                end})
            end
        else

            self:checkSelfWinType(self.m_runSpinResultData.p_bonusExtra.bWinCoins,function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,self.m_resultCoins)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_bonusExtra.bWinCoins,false,false})
                if _callback then
                    _callback()
                end
            end)
        end
    end})
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)

end
function CodeGameScreenPowerUpMachine:checkSelfWinType(coinsNum,callBack)
    if coinsNum == nil then
        coinsNum = 0
    end
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = coinsNum / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_HugeWinLimitRate then
        self:showSelf_EpicWin(coinsNum,callBack)
    elseif winRatio >= self.m_MegaWinLimitRate then
        self:showSelf_MegaWin(coinsNum,callBack)
    elseif winRatio >= self.m_BigWinLimitRate then
        self:showSelf_BigWin(coinsNum,callBack)
    else
        if callBack then
            callBack()
        end
    end

end

---
-- 显示大赢动画
function CodeGameScreenPowerUpMachine:showSelf_BigWin(coinsNum,callBack)
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg",SpineWinType.SpineWinType_BigWin)
    bigMegaWin:initViewData(coinsNum,SpineWinType.SpineWinType_BigWin,
        function()
            if callBack then
                callBack()
            end
        end)
    if globalData.slotRunData.machineData.p_portraitFlag then
        bigMegaWin.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(bigMegaWin)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_BigWin,coinsNum)
    return true
end

---
-- 显示一半赢钱动画  ,, megawin 暂时不适用了
function CodeGameScreenPowerUpMachine:showSelf_MegaWin(coinsNum,callBack)
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg",SpineWinType.SpineWinType_MegaWin)
    bigMegaWin:initViewData(coinsNum,SpineWinType.SpineWinType_MegaWin,
        function()
            if callBack then
                callBack()
            end
        end)
    if globalData.slotRunData.machineData.p_portraitFlag then
        bigMegaWin.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(bigMegaWin)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_MegaWin,coinsNum)
    return true
end

function CodeGameScreenPowerUpMachine:showSelf_EpicWin(coinsNum,callBack)
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg",SpineWinType.SpineWinType_EpicWin)
    bigMegaWin:initViewData(coinsNum,SpineWinType.SpineWinType_EpicWin,
        function()
            if callBack then
                callBack()
            end
        end)
    if globalData.slotRunData.machineData.p_portraitFlag then
        bigMegaWin.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(bigMegaWin)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_EpicWin,coinsNum)
    return true
end

function CodeGameScreenPowerUpMachine:showChoiceBetView( )
    self.highLowBetView = util_createView("CodePowerUpSrc.PowerUpHighLowBetView",self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.highLowBetView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(self.highLowBetView)
end

function CodeGameScreenPowerUpMachine:unlockHigherBet()

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end


function CodeGameScreenPowerUpMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local num,isLongRun = BaseSlotoManiaMachine.setBonusScatterInfo(self,symbolType, column , specialSymbolNum, bRunLong)
    if column <= 3 then--检查第四行  不允许出现快滚
        local reelRunData = self.m_reelRunInfo[column]
        reelRunData:setNextReelLongRun(false)

        isLongRun = false
    end
    return num,isLongRun
end

--[[
    @desc: 断线重连时处理 是否有feature
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenPowerUpMachine:checkHasFeature( )
    local hasFeature = false
    if self.m_initSpinData ~= nil and self.m_initSpinData.p_bonusStatus ~= nil and self.m_initSpinData.p_bonusStatus == "OPEN" then
        hasFeature = true
    end
    return hasFeature
end

function CodeGameScreenPowerUpMachine:getBetLevel( )
    return self.m_betLevel
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenPowerUpMachine:upateBetLevel()

    local minBet = self:getMinBet( )

    self:updateHighLowBetLock( minBet )
end

function CodeGameScreenPowerUpMachine:getMinBet( )
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenPowerUpMachine:updateHighLowBetLock( minBet )
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_clickBet = true

            self.m_betLevel = 1
            self.m_betChoiceIcon:setVisible(false)
        else

        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_clickBet = false

            self.m_betLevel = 0
            self.m_betChoiceIcon:setVisible(true)
        end
    end
end

function CodeGameScreenPowerUpMachine:initJackpotInfo(jackpotPool,lastBetId)
    self:updateJackpot()
end

function CodeGameScreenPowerUpMachine:updateJackpot()
    self.m_jackpotView:updateJackpotInfo()
end


function CodeGameScreenPowerUpMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        if self.m_betLevel == 1 then
            reelDatas = self.m_configData:getHighCloumnByColumnIndex(parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        end
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas

end



function CodeGameScreenPowerUpMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function CodeGameScreenPowerUpMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    if self:checkTriggerBonus() then
        return
    end

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            -- self:clearFrames_Fun()
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


            self:showAllFrame(winLines)
            if #winLines > 1 then
                showLienFrameByIndex()
            end
    else
        self:showAllFrame(winLines)
        if #winLines > 1 then
            showLienFrameByIndex()
        end
    end
end

function CodeGameScreenPowerUpMachine:isShowChooseBetOnEnter()
    return self.m_initSpinData and self.m_initSpinData.p_bonusStatus ~= "OPEN" and self.m_betLevel == 0
end

function CodeGameScreenPowerUpMachine:checkTriggerBonus()

    for k,v in pairs(self.m_runSpinResultData.p_features) do
        if v == 5 then
            return true
        end

    end

    return false
end
function CodeGameScreenPowerUpMachine:slotReelDown()
    CodeGameScreenPowerUpMachine.super.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
 end
function CodeGameScreenPowerUpMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenPowerUpMachine.super.playEffectNotifyNextSpinCall(self)
end
return CodeGameScreenPowerUpMachine






