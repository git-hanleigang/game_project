---
-- island li
-- 2019年1月26日
-- CodeGameScreenChilliFiestaMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local BaseDialog = util_require("Levels.BaseDialog")
local ChilliFiestaSlotNode = require "CodeChilliFiestaSrc.ChilliFiestaSlotNode"

local CodeGameScreenChilliFiestaMachine = class("CodeGameScreenChilliFiestaMachine", BaseSlotoManiaMachine)

CodeGameScreenChilliFiestaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_ALL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14--107

CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13--106
CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 -- 105
CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 --104
CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 --103
CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --94

CodeGameScreenChilliFiestaMachine.SYMBOL_FIX_SCORE10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 +1


CodeGameScreenChilliFiestaMachine.m_chipList = nil
CodeGameScreenChilliFiestaMachine.m_playAnimIndex = 0
CodeGameScreenChilliFiestaMachine.m_lightScore = 0
CodeGameScreenChilliFiestaMachine.m_betLevel = 0

CodeGameScreenChilliFiestaMachine.m_triggerRespinRevive = nil --触发额外增加次数
CodeGameScreenChilliFiestaMachine.m_isShowRespinChoice = nil--是否显示额外弹窗
CodeGameScreenChilliFiestaMachine.m_isPlayCollect = nil  --是否正在播放收集动画
CodeGameScreenChilliFiestaMachine.m_triggerAllSymbol = nil  --是否触发 金辣椒
CodeGameScreenChilliFiestaMachine.m_aimAllSymbolNodeList = {} --金辣椒列表
CodeGameScreenChilliFiestaMachine.m_flyCoinsTime = 0.3
CodeGameScreenChilliFiestaMachine.m_reconnect = nil
CodeGameScreenChilliFiestaMachine.m_isRespinReelDown = false

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenChilliFiestaMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_betLevel = nil
    self.m_aimAllSymbolNodeList = {}
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_bJackpotHeight = false
    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false

	--init
	self:initGame()
end

function CodeGameScreenChilliFiestaMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("Node_bg"):setLocalZOrder(-100)
    self:findChild("Node_bg"):addChild(gameBg)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

function CodeGameScreenChilliFiestaMachine:scaleMainLayer()

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
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
    if  display.height == 1024 and display.width == 768 then
        local mainScale = 0.71
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end

end
function CodeGameScreenChilliFiestaMachine:changeViewNodePos( )
    self.m_bJackpotHeight = false
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height/display.width
        if pro > 1.867 and  pro < 2 then
            -- self:findChild("player_node"):setPositionY(self:findChild("player_node"):getPositionY() - 78)
        elseif pro > 2 and  pro < 2.2 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 100)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 180)
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 120)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 240)
            self.m_bJackpotHeight = true
        elseif pro == 2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 55)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 140)
        elseif pro <= 1.867 and pro > 1.6 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY()-10)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY()+10)
            -- self:findChild("player_node"):setPositionY(self:findChild("player_node"):getPositionY() - 78)
        else
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY()-20)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY()+30)
        end
    elseif display.height >= FIT_HEIGHT_MIN and  display.height < FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height/display.width
        if pro > 1.867 and  pro < 2 then
            self:findChild("player_node"):setPositionY(self:findChild("player_node"):getPositionY() - 78)
        elseif pro > 2 and  pro < 2.2 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 100)
            -- self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 160)
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 120)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 200)
            self.m_bJackpotHeight = true
        elseif pro == 2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 55)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 140)
        elseif pro <= 1.867 and pro > 1.6 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() -10 )
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 10)
            -- self:findChild("player_node"):setPositionY(self:findChild("player_node"):getPositionY() - 78)
        else
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() -10 )
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 10)
        end

    elseif display.height < FIT_HEIGHT_MIN then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height/display.width
        if pro < 1.5  then
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY()+10)
        end
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 8)
        -- self:findChild("player_node"):setPositionY(self:findChild("player_node"):getPositionY() - 78)
    end
    self:findChild("player_node"):setPositionY(self:findChild("player_node"):getPositionY() - 78)
end


function CodeGameScreenChilliFiestaMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("ChilliFiestaConfig.csv", "LevelChilliFiestaConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

-- function CodeGameScreenChilliFiestaMachine:enterGamePlayMusic(  )
-- --self.m_currentMusicBgName
--     scheduler.performWithDelayGlobal(function()
--         self:resetMusicBg()
--     end, 0.4,self.m_moduleName)

-- end


function CodeGameScreenChilliFiestaMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar
    self.m_respinNode = self:findChild("node_respin")
    self.m_respinNode:setVisible(false)
    -- jackpot
    self.m_jackpotView = util_createView("CodeChilliFiestaSrc.ChilliFiestaJackpotView",self)
    self:findChild("jackpot"):addChild(self.m_jackpotView)

    self.m_RsjackpotView = util_createView("CodeChilliFiestaSrc.ChilliFiestaRsJackpotView",self)
    self:findChild("jackpot"):addChild(self.m_RsjackpotView)
    self.m_RsjackpotView:setVisible(false)

    self.m_betChoiceIcon = util_createView("CodeChilliFiestaSrc.ChilliFiestaHighLowBetIcon",self)
    self:findChild("betIconNode"):addChild(self.m_betChoiceIcon)
    -- self.m_betChoiceIcon:setScale(0.6)
    -- logo
    -- self.m_logo = util_createView("CodeChilliFiestaSrc.ChilliFiestaLogoView",false)
    -- self:findChild("logo"):addChild(self.m_logo)
    self:findChild("logo"):setVisible(false)

    self.m_chilliPlayer = util_spineCreate("ChilliFiesta_logo", true, true)
    self:findChild("player_node"):addChild(self.m_chilliPlayer)
    self.m_chilliPlayer:setPosition(0,0)
    util_spinePlay(self.m_chilliPlayer,"idleframe",true)
    -- util_spineEndCallFunc(Boom, "buling", function()
    --       Boom:setVisible(false)
    -- end)


    self.m_reSpinPrize = util_createView("CodeChilliFiestaSrc.ChilliFiestaRespinPrize",self)
    self:findChild("freespinbar"):addChild(self.m_reSpinPrize)
    self.m_reSpinPrize:setVisible(false)

    self.m_freeSpinbar = util_createView("CodeChilliFiestaSrc.ChilliFiestaFreeSpinBar",self)
    self:findChild("freespinbar"):addChild(self.m_freeSpinbar)
    self.m_freeSpinbar:setVisible(false)

    self.m_double = util_createAnimation("ChilliFiesta_double.csb")
    self:findChild("freespinbar"):addChild(self.m_double)
    self.m_double:setPosition(0,-40)
    self.m_double:setVisible(false)


    -- m_reSpinbar
    self.m_reSpinbar = util_createView("CodeChilliFiestaSrc.ChilliFiestaReSpinBar",self)
    self:findChild("respinBar"):addChild(self.m_reSpinbar)
    self.m_reSpinbar:setVisible(false)

    -- m_wildBar
    self.m_wildBar = util_createView("CodeChilliFiestaSrc.ChilliFiestaWildBar",self)
    self:findChild("wildbar"):addChild(self.m_wildBar)
    self.m_wildBar:setVisible(false)

    self.m_changeScene = util_spineCreate("ChilliFiesta_guochang", true, true)
    self:addChild(self.m_changeScene,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    -- self.m_changeScene:setPosition(cc.p(0,0))
    self.m_changeScene:setPosition(cc.p(display.width/2,display.height/2))

    self.m_changeScene:setVisible(false)
    self.m_changeScene:setScale(0.5)
    local pro = display.height/display.width
    if pro > 2 then
        self.m_changeScene:setScale(0.7)
    end
    -- util_spinePlay(Boom,"buling",false)
    -- util_spineEndCallFunc(Boom, "buling", function()
    --       Boom:setVisible(false)
    -- end)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        if  self.m_reconnect then
            return
        end
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
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
            soundTime = 3
        end
        local soundName = "ChilliFiestaSounds/music_ChilliFiesta_last_win_".. soundIndex .. ".mp3"
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end
---
-- 进入关卡
--
function CodeGameScreenChilliFiestaMachine:enterLevel()
    
    self.m_reconnect = true
    
    BaseSlotoManiaMachine.enterLevel(self)

end

function CodeGameScreenChilliFiestaMachine:initGameStatusData(gameData)
    if gameData.feature and  gameData.feature.action == "BONUS" then
        gameData.spin.action = gameData.feature.action
        gameData.spin.features = gameData.feature.features
        gameData.spin.freespin = gameData.feature.freespin
    end
    if gameData.spin and gameData.spin.freespin and gameData.spin.freespin.extra then
        self.m_betChoiceIcon:setVisible(false)
        local freespin = gameData.spin.freespin
        self.m_fsReelDataIndex = freespin.extra.select
    end
    if gameData.spin and gameData.spin.respin and gameData.spin.respin.reSpinCurCount > 0 then
        self.m_betChoiceIcon:setVisible(false)
    end

    BaseSlotoManiaMachine.initGameStatusData(self,gameData)

end

function CodeGameScreenChilliFiestaMachine:drawReelArea()
    BaseSlotoManiaMachine.drawReelArea(self)

    self.m_clipUpParent = self.m_csbOwner["sp_reel_respin_0"]:getParent()

end
-- 断线重连
function CodeGameScreenChilliFiestaMachine:MachineRule_initGame(  )
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgScene(0)
        -- self.m_logo:setVisible(false)
        self.m_wildBar:setVisible(true)
        self.m_freeSpinbar:updateView(self.m_runSpinResultData.p_freeSpinsLeftCount,self.m_runSpinResultData.p_freeSpinsTotalCount)
    end

end



function CodeGameScreenChilliFiestaMachine:spinResultCallFun(param)
    local isSucc = param[1]
    local spinData = param[2]

    BaseSlotoManiaMachine.spinResultCallFun(self,param)
    if isSucc then

        local freespin = spinData.result.freespin
        if freespin and freespin.extra then
            self.m_fsReelDataIndex = freespin.extra.select
            self.m_fsmultiple = freespin.extra.multiple
        end

         --respin中触发了 额外奖励次数
        if spinData.result.respin.extra and spinData.result.respin.extra.options then
            self.m_triggerRespinRevive = true
        end

        if self.m_bIsSelectCall then
            self.m_bIsSelectCall = false
            globalData.slotRunData.freeSpinCount = spinData.result.freespin.freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = spinData.result.freespin.freeSpinsTotalCount
            -- freeSpinNewCount
            performWithDelay(self,function()
                self:triggerFreeSpinCallFun()
                self.m_effectData.p_isPlay = true
                self:playGameEffect()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Stop, false})
            end,0.1)

        end

    end

    
end

function CodeGameScreenChilliFiestaMachine:triggerFreeSpinCallFun()
    BaseSlotoManiaMachine.triggerFreeSpinCallFun(self)
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenChilliFiestaMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "ChilliFiesta"
end

-- 继承底层respinView
function CodeGameScreenChilliFiestaMachine:getRespinView()
    return "CodeChilliFiestaSrc.ChilliFiestaRespinView"
end
-- 继承底层respinNode
function CodeGameScreenChilliFiestaMachine:getRespinNode()
    return "CodeChilliFiestaSrc.ChilliFiestaRespinNode"
end

--触发respin
function CodeGameScreenChilliFiestaMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize(true)
    end

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    -- self.m_logo:setVisible(false)

    self.m_reSpinbar:setVisible(true)
    self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)

    self.m_reSpinPrize:setVisible(true)
    self.m_reSpinPrize:updateView(0)
    self.m_reSpinPrize:changeTitle(0)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    if self:isRespinInit() then
        self.m_respinView:setAnimaState(0)
    end
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --转换storeicons
    local storeIcons = {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    for i=1,#storedIcons do
        local pos = self:getRowAndColByPos(storedIcons[i][1])
        storeIcons[#storeIcons + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons[i][2]}
    end
    self.m_respinView:setStoreIcons(storeIcons)
    self:runCsbAction("idle2")
    self.m_respinNode:setVisible(true)
    -- if self.m_bJackpotHeight == false then
        self.m_jackpotView:changeCsbAni("idle2")

        self.m_RsjackpotView:setVisible(true)
        self.m_RsjackpotView:runCsbAction("idleframe",true)

        self.m_jackpotView:setVisible(false)
    -- end

     -- 创建炸弹respin层
     self.m_respinViewUp = util_createView(self:getRespinView(), self:getRespinNode())
     if self:isRespinInit() then
        self.m_respinViewUp:setAnimaState(0)
    else
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        self.m_reSpinPrize:updateView(score)
        self.m_reSpinPrize:changeTitle(0)
     end
     self.m_respinViewUp:setCreateAndPushSymbolFun(
         function(symbolType,iRow,iCol,isLastSymbol)
             return self:getSlotNodeWithPosAndTypeUp(symbolType,iRow,iCol,isLastSymbol)
         end,
         function(targSp)
             self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
         end
     )
     self.m_clipUpParent:addChild(self.m_respinViewUp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)

     

      --转换storeicons
    local storeIcons2 = {}
    local storedIcons2 = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    for i=1,#storedIcons2 do
        local pos = self:getRowAndColByPos(storedIcons2[i][1])
        storeIcons2[#storeIcons2 + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons2[i][2]}
    end
    self.m_respinViewUp:setStoreIcons(storeIcons2)


    self:initRespinView(endTypes, randomTypes)----1

    if self.m_reconnect then
        local list = self.m_respinViewUp:getAllCleaningNode()
        for i=1,#list do
            list[i]:runAnim("idleframe",true)
        end
    end
end
function CodeGameScreenChilliFiestaMachine:isRespinInit()
    -- return true
    return self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount
end
--强制 执行变黑
function CodeGameScreenChilliFiestaMachine:respinInitDark()
    if self:isRespinInit() then
        local respinList = self.m_respinViewUp:getAllCleaningNode()
        for i=1,#respinList do
            respinList[i]:setVisible(false)--runAnim("Dack",true)
        end
    end
end



function CodeGameScreenChilliFiestaMachine:initRespinView(endTypes, randomTypes)

    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            performWithDelay(self,function()
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                -- 更改respin 状态下的背景音乐
                self:changeReSpinBgMusic()
                if self:isRespinInit() then
                    self.m_flyIndex = 1
                    self.m_chipList = {}
                    self.m_chipListUp = {}
                    self.m_chipList = self.m_respinView:getAllCleaningNode()

                    self.m_chipListUp = self.m_respinViewUp:getAllCleaningNode()

                    --fly 动画
                    self.m_collScore = 0
                    self:flyCoins(function()
                        self.m_flyIndex = 1
                        self:flyDarkIcon(function()
                            self.m_respinViewUp:setAnimaState(1)
                            self.m_respinView:setAnimaState(1)
                            self:runNextReSpinReel()--开始滚动
                        end)
                    end)

                else
                    self:runNextReSpinReel()--开始滚动
                end
            end,3)
        end
    )

    self.m_respinView:changeClipRowNode(3,cc.p(0,1))

    self.m_respinViewUp:setEndSymbolType(endTypes, randomTypes)
    self.m_respinViewUp:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    local respinNodeInfoUp = self:reateRespinNodeInfoUp()

    self.m_respinViewUp:initRespinElement(
        respinNodeInfoUp,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:respinInitDark()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--开始下次ReSpin
function CodeGameScreenChilliFiestaMachine:runNextReSpinReel(_isDownStates)

    if self.m_triggerRespinRevive then --触发respin奖励次数
        if  self.m_isShowRespinChoice then
            return
        end
        self.m_isShowRespinChoice = true
        performWithDelay(self,function()
            local view=util_createView("CodeChilliFiestaSrc.ChilliFiestaRespinChose",self.m_runSpinResultData.p_rsExtraData,function()
                self.m_triggerRespinRevive = false
                self.m_isShowRespinChoice = false
                self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
                BaseSlotoManiaMachine.runNextReSpinReel(self)
                if _isDownStates then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end
            end,self)
            if globalData.slotRunData.machineData.p_portraitFlag then
                view.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalViewManager:showUI(view)
        end,0.5)
    else
        BaseSlotoManiaMachine.runNextReSpinReel(self)
        if _isDownStates then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

--下面辣椒往上飞
function CodeGameScreenChilliFiestaMachine:flyDarkIcon(func)
    if self.m_flyIndex > #self.m_chipList or self.m_flyIndex > #self.m_chipListUp then
        return
    end
    -- fly
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

    local nodeEndSymbol =  self.m_chipListUp[self.m_flyIndex]
    local endPos = nodeEndSymbol:getParent():convertToWorldSpace(cc.p(nodeEndSymbol:getPosition()))

    self:runFlySymbolAction(nodeEndSymbol,0.01,0.3,startPos,endPos,function()
        self.m_flyIndex = self.m_flyIndex + 1
        if  self.m_flyIndex == #self.m_chipList + 1 then
            if func then
                func()
            end
        else
            self:flyDarkIcon(func)
        end
    end)

end

function CodeGameScreenChilliFiestaMachine:runFlySymbolAction(endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpFly.mp3")

    local node = util_createAnimation("Socre_ChilliFiesta_Bonus_fly.csb")
    node:setVisible(false)

    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        node:playAction("buling1")
    end)
    local bez=cc.BezierTo:create(flyTime,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    actionList[#actionList + 1] = bez
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        endNode:setVisible(true)

        gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpBuling.mp3")

        endNode:runAnim("fuzhi",false,function()
            endNode:runAnim("idleframe",true)
        end)
        performWithDelay(self,function()
            if callback then
                callback()
            end
        end,0.5)
    end)
    node:runAction(cc.Sequence:create(actionList))
end

--金色的辣椒
function CodeGameScreenChilliFiestaMachine:flyCenterToSymbol(func)
    if self.m_flyIndex > #self.m_aimAllSymbolNodeList then
        return
    end
    local startPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))
    -- fl
    local symbolNode =  self.m_aimAllSymbolNodeList[self.m_flyIndex]
    if symbolNode:getParent() == nil or  symbolNode:getPosition() == nil  then
        self.m_flyIndex = self.m_flyIndex + 1
        self:flyCenterToSymbol(func)
        return
    end
    local endPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinBonusCollect.mp3",false)
    self.m_reSpinPrize.m_Particle_1:setVisible(true)

    self.m_reSpinPrize:runCsbAction("shouji")

    self:runFlyCoinsAction(0.01,self.m_flyCoinsTime,startPos,endPos,function()
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple

        -- symbolNode
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 3)
        local lbs = symbolNode:getCcbProperty("m_lb_score")
        if lbs and lbs.setString then
            lbs:setString(score)
        end
        self.m_flyIndex = self.m_flyIndex + 1
        gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpBuling.mp3")

        symbolNode:runAnim("fuzhi",false,function()
            symbolNode:runAnim("idleframe",true)
        end)
        performWithDelay(self,function()
            if  self.m_flyIndex == #self.m_aimAllSymbolNodeList + 1 then
                self.m_aimAllSymbolNodeList = {}
                if func then
                    func()
                end
            else
                self:flyCenterToSymbol(func)
            end
        end,0.3)
    end)

end


function CodeGameScreenChilliFiestaMachine:showRespinPrize(iRow, iCol)
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),true) --获取分数（网络数据）
    local lineBet = globalData.slotRunData:getCurTotalBet()
    self.m_collScore = self.m_collScore + score * lineBet
    self.m_reSpinPrize:updateView(self.m_collScore)
    self.m_reSpinPrize:changeTitle(0)
end
--[[
    @desc: 初始阶段飞金币
    author:{author}
    time:2019-08-20 14:10:50
    --@func:
    @return:
]]
function CodeGameScreenChilliFiestaMachine:flyCoins(func)
    if self.m_flyIndex > #self.m_chipList then
        return
    end

    -- fly
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

    local endPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinBonusCollect.mp3",false)
    symbolStartNode:runAnim("shouji",false,function()
        symbolStartNode:runAnim("idleframe",true)
    end)
    self:runFlyCoinsAction(0.01,self.m_flyCoinsTime,startPos,endPos,function()
        self:showRespinPrize(symbolStartNode.p_rowIndex,symbolStartNode.p_cloumnIndex)
        performWithDelay(self,function()
            self.m_flyIndex = self.m_flyIndex + 1
            if  self.m_flyIndex >= #self.m_chipList + 1 then
                if func then
                    func()
                end
            else
                self:flyCoins(func)
            end
        end,0.3)
    end)

end
function CodeGameScreenChilliFiestaMachine:runFlyCoinsAction(time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = cc.ParticleSystemQuad:create("ChilliFiesta/ui/Effect_lajiaolaoren_lizi_1.plist")
    node:setPositionType(0)
    node:setDuration(flyTime)
    node:setVisible(false)
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    local moveto=cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(flyTime)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))


end
----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenChilliFiestaMachine:reateRespinNodeInfoUp()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolTypeUp(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPosUp(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

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
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
-- GD.REEL_SYMBOL_ORDER = {  -- 基本来说这四个层级就够用了
--     REEL_ORDER_1 = 1000,  -- 默认都是此层级 ， 例如1~9信号
--     REEL_ORDER_2 = 2000,  -- 特殊层级，wild
--     REEL_ORDER_2_1 = 2200, -- 例如特殊或者比较大的 bonus 特殊关卡自行处理  等
--     REEL_ORDER_2_2 = 2300, -- 例如特殊或者比较大的 scatter 特殊关卡自行处理  等
--     REEL_ORDER_MASK = 2500, -- 滚动时遮罩
--     REEL_ORDER_3 = 3000,  -- 尤其突出显示效果
--     REEL_ORDER_4 = 4000   -- 备用
-- }
---
--设置bonus scatter 层级
function CodeGameScreenChilliFiestaMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
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

function CodeGameScreenChilliFiestaMachine:getReelPosUp(col)

    local reelNode = self:findChild("sp_reel_respin_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--- respin 快停
function CodeGameScreenChilliFiestaMachine:quicklyStop()
    BaseSlotoManiaMachine.quicklyStop(self)
    self.m_respinViewUp:quicklyStop()
end

--开始滚动
function CodeGameScreenChilliFiestaMachine:startReSpinRun()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
    else
        self.m_respinViewUp:startMove()
    end
    
    BaseSlotoManiaMachine.startReSpinRun(self)

    
    
end
function CodeGameScreenChilliFiestaMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.select then
        isNotifyUpdateTop = false
    end
    -- if gameData.feature and  gameData.feature.action == "BONUS" then
    --     gameData.spin.action = gameData.feature.action
    --     gameData.spin.features = gameData.feature.features
    --     gameData.spin.freespin = gameData.feature.freespin
    -- end
    -- if gameData.spin and gameData.spin.freespin and gameData.spin.freespin.extra then
    --     self.m_betChoiceIcon:setVisible(false)
    --     local freespin = gameData.spin.freespin
    --     self.m_fsReelDataIndex = freespin.extra.select
    -- end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

---判断结算
function CodeGameScreenChilliFiestaMachine:reSpinReelDown(addNode)
    if self.m_isRespinReelDown then
        return
    end
    self.m_isRespinReelDown = true
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin

    local inner = function()

        self:setGameSpinStage(STOP_RUN)

        self:updateQuestUI()
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
            self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()
            performWithDelay(self,function()
                --结束
                self:reSpinEndAction()
            end,1)


            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false

            return
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)

        if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        end

        --继续
        self:runNextReSpinReel(true)


    end
    -- if self.m_runSpinResultData.
    if self.m_triggerAllSymbol then
        performWithDelay(self,function()
            self.m_flyIndex = 1
            self:flyCenterToSymbol(function()
                self.m_triggerAllSymbol = false
                self.m_aimAllSymbolNodeList = {}
                performWithDelay(self,function()
                    inner()
                end,1)
            end)
        end,1)
    else
        inner()
    end
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenChilliFiestaMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
    if winAmonut == nil then
        return
    end

    --插入规避逻辑
    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i=1,#self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert( self.m_gameEffects, i + 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, i + 2, effectData )
                break
            end
        end
        if isAddEffect == false then
            self.m_llBigOrMegaNum = winAmonut


            local delayEffect = GameEffectData.new()
            delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
            delayEffect.p_effectOrder = feature + 1
            table.insert( self.m_gameEffects, #self.m_gameEffects + 1, delayEffect )

            local effectData = GameEffectData.new()
            effectData.p_effectType = winEffect
            table.insert( self.m_gameEffects, #self.m_gameEffects + 1, effectData )

        end

    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenChilliFiestaMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    else
        node:runAnim("idleframe", true)
    end
end
--结束移除小块调用结算特效
function CodeGameScreenChilliFiestaMachine:removeRespinNode()
    BaseSlotoManiaMachine.removeRespinNode(self)
    if self.m_respinViewUp == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNodeUp = self.m_respinViewUp:getAllEndSlotsNode()
    for i = 1, #allEndNodeUp do
        local node = allEndNodeUp[i]
        node:removeFromParent()
    end
    self.m_respinViewUp:removeFromParent()
    self.m_respinViewUp = nil
end



---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenChilliFiestaMachine:showLineFrameByIndex(winLines,frameIndex)
    if winLines == nil or #winLines == 0 then
        return
    end
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end

        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
               self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end
            node:runAnim("actionframe",true)
        else
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end

    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end

end
function CodeGameScreenChilliFiestaMachine:MachineRule_respinTouchSpinBntCallBack()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)

        self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)

        self:startReSpinRun()
    elseif self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        --快停
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end


end


--接收到数据开始停止滚动
function CodeGameScreenChilliFiestaMachine:stopRespinRun()

    BaseSlotoManiaMachine.stopRespinRun(self)

    local storedNodeInfoUp = self:getRespinSpinDataUp()
    local unStoredReelsUp = self:getRespinReelsButStoredUp(storedNodeInfoUp)
    self.m_respinViewUp:setRunEndInfo(storedNodeInfoUp, unStoredReelsUp)
end
function CodeGameScreenChilliFiestaMachine:getMatrixPosSymbolTypeUp(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_rsExtraData.upLastReels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_rsExtraData.upLastReels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end
function CodeGameScreenChilliFiestaMachine:getRespinSpinDataUp()
    if not self.m_runSpinResultData.p_rsExtraData then
        return {}
    end
    local storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons--p_storedIcons
    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for i = 1, #storedIcons do
                if storedIcons[i] == index then
                    local type = self:getMatrixPosSymbolTypeUp(iRow, iCol)

                    local pos = {iX = iRow, iY = iCol, type = type}
                    storedInfo[#storedInfo + 1] = pos
                end
            end
            index = index + 1
        end
    end
    return storedInfo
end
function CodeGameScreenChilliFiestaMachine:getRespinReelsButStoredUp(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and  storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
           local type = self:getMatrixPosSymbolTypeUp(iRow, iCol)
           if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
           end
        end
    end
    return reelData
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenChilliFiestaMachine:MachineRule_GetSelfCCBName(symbolType)

    -- getSymbolCCBNameByType
    -- 自行配置jackPot信号 csb文件名，不带后缀

    if symbolType == self.SYMBOL_FIX_SCORE10 then
        return "Socre_ChilliFiesta_10"
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Socre_ChilliFiesta_Bonus"
    end


    if symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_ChilliFiesta_bonus2"
    end

    if symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_ChilliFiesta_bonus3"
    end

    if symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_ChilliFiesta_bonus5"
    end

    if symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_ChilliFiesta_bonus4"
    end

    if symbolType == self.SYMBOL_FIX_ALL then
        return "Socre_ChilliFiesta_bonus6"
    end


    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenChilliFiestaMachine:getReSpinSymbolScore(id,onlyGetScore)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons == nil then
        storedIcons = {}
    end
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end
    if onlyGetScore then
        return score
    end
    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR  then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND  then
        score = "GRAND"
    end

    return score
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenChilliFiestaMachine:getReSpinSymbolScoreUp(id,onlyGetScore)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    if storedIcons == nil then
        storedIcons = {}
    end
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end
    if onlyGetScore then
        return score
    end
    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolTypeUp(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR  then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_FIX_GRAND  then
        score = "GRAND"
    end

    return score
end


function CodeGameScreenChilliFiestaMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()  
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenChilliFiestaMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex



    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_FIX_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            print("m_aimAllSymbolNodeList-----------")
            if self.m_aimAllSymbolNodeList == nil then
                self.m_aimAllSymbolNodeList = {}
            end
            local has = false
            for i=1,#self.m_aimAllSymbolNodeList do
                if self.m_aimAllSymbolNodeList[i] == symbolNode then
                    has = true
                    break
                end
            end
            if has == false then
                self.m_aimAllSymbolNodeList[#self.m_aimAllSymbolNodeList+1] = symbolNode

                local lbs = symbolNode:getCcbProperty("m_lb_score")
                if lbs and lbs.setString  then
                    lbs:setString("")
                end

            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then

                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab and lab.setString then
                    lab:setString(score)
                end
            end
        end

        if symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("idleframe",true)
        end


    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then

                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab and lab.setString then
                    lab:setString(score)
                end
                symbolNode:runAnim("idleframe",true)
            end
        end

    end

end
function CodeGameScreenChilliFiestaMachine:updateReelGridNode(node)
    if node.p_symbolType == self.SYMBOL_FIX_GRAND then
        node:getCcbProperty("m_lb_score_grand"):setVisible(self.m_jackpot_status == "Normal")
        node:getCcbProperty("m_lb_score_mega"):setVisible(self.m_jackpot_status == "Mega")
        node:getCcbProperty("m_lb_score_super"):setVisible(self.m_jackpot_status == "Super")
    end

    if node.p_symbolType == self.SYMBOL_FIX_SYMBOL
        -- or symbolType == self.SYMBOL_FIX_MINI
        -- or symbolType == self.SYMBOL_FIX_MINOR
        -- or symbolType == self.SYMBOL_FIX_MAJOR
        -- or symbolType == self.SYMBOL_FIX_GRAND
        or node.p_symbolType == self.SYMBOL_FIX_ALL
    then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        --快停有问题不下一帧执行
        self:setSpecialNodeScore(self,{node})
    end
end
-- 给respin小块进行赋值
function CodeGameScreenChilliFiestaMachine:setSpecialNodeScoreUp(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_FIX_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            -- print("m_aimAllSymbolNodeList-----------")
            if self.m_aimAllSymbolNodeList == nil then
                self.m_aimAllSymbolNodeList = {}
            end
            local has = false
            for i=1,#self.m_aimAllSymbolNodeList do
                if self.m_aimAllSymbolNodeList[i] == symbolNode then
                    has = true
                    break
                end
            end
            if has == false then
                self.m_aimAllSymbolNodeList[#self.m_aimAllSymbolNodeList+1] = symbolNode

                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab and lab.setString  then
                    lab:setString("")
                end

            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)

            if symbolNode then

                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab and lab.setString then
                    lab:setString(score)
                end
            end
        end

        -- symbolNode:runAnim("idleframe",true)

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)

            if symbolNode then

                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab and lab.setString then
                    lab:setString(score)
                end
            end

            -- symbolNode:runAnim("idleframe",true)
        end

    end

end

function CodeGameScreenChilliFiestaMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        -- or symbolType == self.SYMBOL_FIX_MINI
        -- or symbolType == self.SYMBOL_FIX_MINOR
        -- or symbolType == self.SYMBOL_FIX_MAJOR
        -- or symbolType == self.SYMBOL_FIX_GRAND
        or symbolType == self.SYMBOL_FIX_ALL
    then

        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end
    return reelNode
end

function CodeGameScreenChilliFiestaMachine:getSlotNodeWithPosAndTypeUp(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        -- or symbolType == self.SYMBOL_FIX_MINI
        -- or symbolType == self.SYMBOL_FIX_MINOR
        -- or symbolType == self.SYMBOL_FIX_MAJOR
        -- or symbolType == self.SYMBOL_FIX_GRAND
        or symbolType == self.SYMBOL_FIX_ALL
    then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScoreUp),{reelNode})
        self:runAction(callFun)
    end
    return reelNode
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenChilliFiestaMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_GRAND,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_ALL,count =  2}
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenChilliFiestaMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_ALL or
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end
-- 是不是 respinBonus小块
function CodeGameScreenChilliFiestaMachine:isBulingSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_ALL or
        symbolType == self.SYMBOL_FIX_GRAND then

            -- symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  or
            -- symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or
        return true
    end
    return false
end

function CodeGameScreenChilliFiestaMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i <= 2 then
            soundPath = "ChilliFiestaSounds/music_ChilliFiesta_scatterBuling.mp3"
        elseif i > 2 and i < 5 then
            soundPath = "ChilliFiestaSounds/music_ChilliFiesta_scatterBuling.mp3"
        else
            soundPath = "ChilliFiestaSounds/music_ChilliFiesta_scatterBuling.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

-- SYMBOL_SCATTER = 90,
-- SYMBOL_BONUS = 91,
-- SYMBOL_WILD = 92,
--
--单列滚动停止回调
--
function CodeGameScreenChilliFiestaMachine:slotOneReelDown(reelCol)
    if self.m_reelDownSound == nil then
        self.m_reelDownSound = "ChilliFiestaSounds/music_ChilliFiesta_reelStop.mp3"
    end
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        for i = 1, self.m_iReelRowNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[i][reelCol]
            if self:isBulingSymbol(symbolType) then
                local symbolNode = self:getFixSymbol(reelCol, i, SYMBOL_NODE_TAG) --self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,i,SYMBOL_NODE_TAG))
                symbolNode:runAnim("buling",false,function()
                    symbolNode:runAnim("idleframe",true)
                end)
                if self:isFixSymbol(symbolType) then

                    local soundPath =  "ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpBuling.mp3"

                    if self.playBulingSymbolSounds then
                        self:playBulingSymbolSounds( reelCol,soundPath )
                    else
                        -- respinbonus落地音效
                        gLobalSoundManager:playSound(soundPath)
                    end

                end
                -- if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                --     symbolNode:setLocalZOrder(-1)
                -- end
                -- if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                --     symbolNode:setLocalZOrder(1)
                -- end
            end
        end

    else


    end
end
function CodeGameScreenChilliFiestaMachine:playEffectNotifyNextSpinCall( )
    if  self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_freeSpinbar:setVisible(true)
    end
    BaseSlotoManiaMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)

end
function CodeGameScreenChilliFiestaMachine:requestSpinReusltData()
    self.m_wildBar:updateView(0)
    BaseSlotoManiaMachine.requestSpinReusltData(self)


end
function CodeGameScreenChilliFiestaMachine:requestSpinResult(spinType,selectIndex)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
    end
    self.m_curRequest = true
    self.m_reconnect = false
    self.m_isRespinReelDown = false

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

    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount-1,self.m_runSpinResultData.p_reSpinsTotalCount)
    end

    self:updateJackpotList()
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( )}
    if spinType then
        messageData={msg=spinType,data=selectIndex,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( )}
    end
   -- 拼接 collect 数据， jackpot 数据

    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenChilliFiestaMachine:showEffect_Bonus(effectData)
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
        util_spinePlay(self.m_chilliPlayer,"actionframe",false)
        performWithDelay(self,function()
            util_spinePlay(self.m_chilliPlayer,"idleframe",true)
            self:showFreeSpinView(effectData)
        end,143/30)

        util_nextFrameFunc(function()
            gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_scatterTrigger.mp3")
        end)
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move

        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenChilliFiestaMachine:showFreeSpinView(effectData)

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:changeBgScene(0)

        self.m_freeSpinChose=util_createView("CodeChilliFiestaSrc.ChilliFiestaFreeSpinChose",self.m_runSpinResultData.p_selfMakeData,function(spinType)
            self.m_bIsSelectCall = true
            self.m_effectData = effectData
            local sumNum = self.m_runSpinResultData.p_selfMakeData[spinType..""].times
            self:playChangeScene(function()
                self:updateBetIcon(false)
                self.m_wildBar:setVisible(true)
                self.m_wildBar:updateView(0)--freespin.extra.multiple)
                -- self.m_logo:setVisible(false)
                if self.m_freeSpinChose then
                    self.m_freeSpinChose:removeFromParent()
                end
                self.m_freeSpinbar:setVisible(true)
                self.m_freeSpinbar:updateView(sumNum,sumNum)

            end,0.5)
            self:runCsbAction("idle2")
            performWithDelay(self,function()
                self:requestSpinResult(MessageDataType.MSG_BONUS_SELECT,spinType)
            end,2)
        end,self)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_freeSpinChose.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalViewManager:showUI(self.m_freeSpinChose)
        local pro = display.height/display.width
        if pro < 1.4  then
            self.m_freeSpinChose:findChild("root"):setScale(0.90)
        end
    else
        globalMachineController:playBgmAndResume("ChilliFiestaSounds/music_ChilliFiesta_freespinmore.mp3",4,0.4,1)

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            true
        )
    end
end


function CodeGameScreenChilliFiestaMachine:getBetLevel( )
    return self.m_betLevel
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenChilliFiestaMachine:upateBetLevel()

    local minBet = self:getMinBet( )

    self:updateHighLowBetLock( minBet )
end

function CodeGameScreenChilliFiestaMachine:getMinBet( )
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

function CodeGameScreenChilliFiestaMachine:updateHighLowBetLock( minBet )
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
            self.m_betChoiceIcon:findChild("Particle_2"):stopSystem()
            self.m_betChoiceIcon:findChild("Particle_2"):resetSystem()
        end
    end
end

function CodeGameScreenChilliFiestaMachine:showChoiceBetView( )
    self.highLowBetView = util_createView("CodeChilliFiestaSrc.ChilliFiestaHighLowBetView",self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.highLowBetView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(self.highLowBetView)
end

function CodeGameScreenChilliFiestaMachine:unlockHigherBet()
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
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenChilliFiestaMachine:initJackpotInfo(jackpotPool,lastBetId)
    self:updateJackpot()
end

function CodeGameScreenChilliFiestaMachine:updateJackpot()
    self.m_jackpotView:updateJackpotInfo()
    self.m_RsjackpotView:updateJackpotInfo()
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenChilliFiestaMachine:levelFreeSpinEffectChange()


end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenChilliFiestaMachine:levelFreeSpinOverChangeEffect()

end
---------------------------------------------------------------------------

-- 触发freespin结束时调用
function CodeGameScreenChilliFiestaMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_freespinOver.mp3")


   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,15)
    local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:playChangeScene(function()
            self:updateBetIcon(true)
            self.m_wildBar:setVisible(false)
            self.m_freeSpinbar:setVisible(false)
            -- self.m_logo:setVisible(true)
            self:changeBgScene(1)
            self:runCsbAction("idle1")
              -- 调用此函数才是把当前游戏置为freespin结束状态
            performWithDelay(self,function()
                self:triggerFreeSpinOverCallFun()
            end,1)
        end,0.5)

    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.65,sy=0.65},571)
    -- local freespinNum =view:findChild("m_lb_num")
    -- freespinNum:setString(self.m_runSpinResultData.p_freeSpinsTotalCount)
end

function CodeGameScreenChilliFiestaMachine:showRespinJackpot(index,coins,func)

    local jackPotWinView = util_createView("CodeChilliFiestaSrc.ChilliFiestaJackPotWinView",{coins = coins,index = index,machine = self,callback = func})
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    -- jackPotWinView:initViewData(index,coins,func)
end

-- 结束respin收集
function CodeGameScreenChilliFiestaMachine:playLightEffectEnd()

    -- 通知respin结束
    self:respinOver()

end
--
function CodeGameScreenChilliFiestaMachine:respinOver()

    self:showRespinOverView()
end

function CodeGameScreenChilliFiestaMachine:playChipCollectAnim(isDouble)

    if self.m_playAnimIndex > #self.m_chipList then
        self.m_isPlayCollect = nil
        performWithDelay(self,function()
            self:playLightEffectEnd()
        end,2)
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))

    local addScore =  self.m_runSpinResultData.p_winLines[self.m_playAnimIndex].p_amount
    local nJackpotType = 0
   if chipNode.p_symbolType == self.SYMBOL_FIX_GRAND then
        nJackpotType = 1
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_MAJOR then
        nJackpotType = 2
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINOR then
        nJackpotType = 3
    elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINI then
        nJackpotType = 4
    end
    self.m_lightScore = self.m_lightScore + addScore
    local function runCollect()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim(isDouble)
        else
            self:showRespinJackpot(nJackpotType, util_formatCoins(addScore,15), function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim(isDouble)
            end)
        end
    end

    local worldPos = cc.p(self.m_RsjackpotView:findChild("Node_winner"):getParent():convertToWorldSpace(cc.p(self.m_RsjackpotView:findChild("Node_winner"):getPosition())))
    local endPos = cc.p(self:convertToNodeSpace(worldPos))

--   gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinBonusCollect.mp3",false)

    chipNode:runAnim("shouji",false,function()
        chipNode:runAnim("idleframe",true)
    end)

    local waitTime = 0.4
    if self:checkIsTopRsNode( chipNode ) then
        waitTime = 0.4
    end
    

   --最终收集阶段
   self:runFlyCoinsAction(0,waitTime,nodePos,endPos,function()
    
        runCollect()
       
        gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_bonusCollectBuling.mp3")


        self.m_RsjackpotView:runCsbAction("idleframe2")
        self.m_RsjackpotView:findChild("Particle_1"):resetSystem()
        self.m_RsjackpotView:updateLabCoins( util_formatCoins(self.m_lightScore,50)  )
        -- self.m_reSpinPrize:updateView(self.m_lightScore)
        -- self.m_reSpinPrize:changeTitle(1)
    end)
end

function CodeGameScreenChilliFiestaMachine:checkIsTopRsNode( _rsnode )
    local topChipList = self.m_respinViewUp:getAllCleaningNode()

    for k,v in pairs(topChipList) do
        local node = v
        if node == _rsnode then
            return true
        end
    end
end

--结束移除小块调用结算特效
function CodeGameScreenChilliFiestaMachine:reSpinEndAction()

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinViewUp:getAllCleaningNode()


    local upList = self.m_respinView:getAllCleaningNode()

    self.upSymbolNum = #self.m_respinViewUp:getAllCleaningNode()

    for i=1,#upList do
        self.m_chipList[#self.m_chipList + 1] = upList[i]
    end

    local innerCollect = function(isDouble)
        if self.m_isPlayCollect == nil then
            self.m_isPlayCollect = true

            globalMachineController:playBgmAndResume("ChilliFiestaSounds/music_ChilliFiesta_respinOver.mp3",3,0.4,1)

            self.m_reSpinbar:setVisible(false)
            self.m_RsjackpotView:runCsbAction("show")
            self.m_RsjackpotView:updateLabCoins( 0 )
            performWithDelay(self,function()
                -- self.m_reSpinPrize:updateView(0)
                -- self.m_reSpinPrize:changeTitle(1)


                self:playChipCollectAnim(isDouble)
            end,3)
        end
    end

    if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)*2  then
        self:respinToDouble(function()
            innerCollect(true)
        end)
    else
        innerCollect(false)
    end



end
function CodeGameScreenChilliFiestaMachine:respinToDouble(callback)
    self.m_double:setVisible(true)
    self.m_double:playAction("auto",false,function()
        self.m_double:setVisible(false)
        local lineBet = globalData.slotRunData:getCurTotalBet()

        for i=1,#self.m_chipList do
            local score = 0
            local iCol = self.m_chipList[i].p_cloumnIndex
            local iRow = self.m_chipList[i].p_rowIndex

            if i <= self.upSymbolNum then
                score = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow ,iCol))
            else
                score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
            end
            if type(score) == "number" then
                local showScore = util_formatCoins(score*2*lineBet, 3)
                
                local lab = self.m_chipList[i]:getCcbProperty("m_lb_score")
                if lab and lab.setString then
                    lab:setString(showScore)
                end
                
                
            end
        end
        performWithDelay(self,function()
            if callback then
                callback()
            end
        end,0.1)
    end)
end
-- 根据本关卡实际小块数量填写
function CodeGameScreenChilliFiestaMachine:getRespinRandomTypes( )
    local symbolList = { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        self.SYMBOL_FIX_SCORE10,
        self.SYMBOL_FIX_SYMBOL,
        self.SYMBOL_FIX_GRAND,
        self.SYMBOL_FIX_MAJOR,
        self.SYMBOL_FIX_MINOR,
        self.SYMBOL_FIX_MINI

    }


    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenChilliFiestaMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_ALL, runEndAnimaName = "buling", bRandom = true}
    }


    return symbolList
end

function CodeGameScreenChilliFiestaMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
    performWithDelay(self,function()

        self:playChangeScene(function()
            self:updateBetIcon(false)
            self.m_chilliPlayer:setVisible(false)

            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end,0.5)

    end,1.5)

end

function CodeGameScreenChilliFiestaMachine:changeBgScene(type)
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

function CodeGameScreenChilliFiestaMachine:playChangeScene(callBack,time)
    gLobalSoundManager:setBackgroundMusicVolume(0)

    self.m_changeScene:setVisible(true)
    -- 过场动画
    util_spinePlay(self.m_changeScene,"actionframe")
    performWithDelay(self,function()
        --构造盘面数据
        self.m_changeScene:setVisible(false)
    end,1.3)
        gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinChangeScene.mp3",false)
    performWithDelay(self,function()
        --构造盘面数据
        if callBack then
            callBack()
        end

    end,time)
    performWithDelay(self,function()
        self:resetMusicBg(true)
        gLobalSoundManager:setBackgroundMusicVolume(1)
    end,3)
end

--ReSpin开始改变UI状态
function CodeGameScreenChilliFiestaMachine:changeReSpinStartUI(respinCount)

end

--ReSpin刷新数量
function CodeGameScreenChilliFiestaMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)

end

function CodeGameScreenChilliFiestaMachine:triggerReSpinOverCallFun(score)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print(
            "================== respin  server=" ..
                self.m_serverWinCoins .. "    client=" .. score .. " ===================="
        )
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    performWithDelay(self,function()
        if self.m_bProduceSlots_InFreeSpin then
            local addCoin = self.m_serverWinCoins
            -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self:getLastWinCoin(),false,false})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end

    end,2)

    self:changeReSpinOverUI(function()


        local coins = nil
        if self.m_bProduceSlots_InFreeSpin then
            coins = self:getLastWinCoin() or 0
        else
            coins = self.m_serverWinCoins or 0
        end
        if self.postReSpinOverTriggerBigWIn then
            self:postReSpinOverTriggerBigWIn( coins)
        end

        -- self:resetMusicBg(true)
        self:playGameEffect()
        self.m_iReSpinScore = 0

        if
            self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or
                self.m_bProduceSlots_InFreeSpin
         then
            --不做处理
        else
            --停掉屏幕长亮
            globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
        end
    end)

end

--ReSpin结算改变UI状态
function CodeGameScreenChilliFiestaMachine:changeReSpinOverUI(callback)

    self:playChangeScene(function()
        self:updateBetIcon(true)
        self:setReelSlotsNodeVisible(true)

        -- 更新游戏内每日任务进度条 -- r
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:removeRespinNode()

            --播放下轮动画
        self:triggerRespinComplete()
        self:resetReSpinMode()
        self.m_reSpinPrize:setVisible(false)
        self.m_reSpinbar:setVisible(false)
        self.m_respinNode:setVisible(false)
        self:runCsbAction("idle1")
        self.m_jackpotView:changeCsbAni("idle")
        self.m_RsjackpotView:setVisible(false)
        self.m_jackpotView:setVisible(true)

        -- self.m_logo:setVisible(true)
        self.m_chilliPlayer:setVisible(true)
        util_spinePlay(self.m_chilliPlayer,"idleframe",true)

        performWithDelay(self,function()
            if callback then
                callback()
            end
        end,1)
    end,0.5)
end

function CodeGameScreenChilliFiestaMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    -- self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenChilliFiestaMachine:showRespinOverView(effectData)

    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_freespinOver.mp3")

    local strCoins=util_formatCoins(self.m_serverWinCoins,15)
    local view=self:showReSpinOver(strCoins,function()

        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self.m_isRespinOver = true
        -- self:resetMusicBg()
    end)
    -- gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.65,sy=0.65},511)
end


----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenChilliFiestaMachine:operaEffectOver()
    CodeGameScreenChilliFiestaMachine.super.operaEffectOver(self)

    if self.m_isRespinOver then
        self.m_isRespinOver = false
        --公共jackpot
        local midReel = self:findChild("sp_reel_2")
        local size = midReel:getContentSize()
        local worldPos = util_convertToNodeSpace(midReel,self)
        worldPos.x = worldPos.x + size.width / 2
        worldPos.y = worldPos.y + size.height / 2
        if G_GetMgr(ACTIVITY_REF.CommonJackpot) then
            G_GetMgr(ACTIVITY_REF.CommonJackpot):playEntryFlyAction(worldPos,function()

            end)
        end
    end
end

-- --重写组织respinData信息
function CodeGameScreenChilliFiestaMachine:getRespinSpinData()
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


---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenChilliFiestaMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)


    return false -- 用作延时点击spin调用
end

function CodeGameScreenChilliFiestaMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end

        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenChilliFiestaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()
    
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    self:upateBetLevel()
    
    local hasFeature = self:checkHasFeature()
    if not hasFeature then
        performWithDelay(self, function()
            if self.m_betLevel == 0 then
                self:showChoiceBetView()
            end
        end, 0.2)
    else
        -- self.m_logo:setVisible(false)
    end

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature and self.m_betLevel ~= 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end

    
end

function CodeGameScreenChilliFiestaMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
        self:updataJackpotStatus(params)
    end,ViewEventType.NOTIFY_BET_CHANGE)

    -- gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
    --     self:updateBetIcon(params)
    -- end,"BET_ENABLE")

    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)

    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CodeGameScreenChilliFiestaMachine:updateBetIcon(params)
    if params then
        if self.m_betLevel == 0 then
            self.m_betChoiceIcon:setVisible(params)
            -- self.m_betChoiceIcon:findChild("Particle_2"):stopSystem()
            -- self.m_betChoiceIcon:findChild("Particle_2"):resetSystem()
        end
    else
        self.m_betChoiceIcon:setVisible(params)
    end

end


---
-- 重连更新freespin 剩余次数
--
function CodeGameScreenChilliFiestaMachine:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self.m_freeSpinbar:updateView(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function CodeGameScreenChilliFiestaMachine:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freeSpinbar:updateView(leftFsCount,totalFsCount)
end
function CodeGameScreenChilliFiestaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end


function CodeGameScreenChilliFiestaMachine:slotReelDown()
    if self.m_fsmultiple ~= nil then
        self.m_wildBar:setVisible(true)
        self.m_wildBar:updateView(self.m_fsmultiple,function()
            BaseSlotoManiaMachine.slotReelDown(self)
        end)
    else
        BaseSlotoManiaMachine.slotReelDown(self)
    end
    self.m_fsmultiple = nil


    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)

end

function CodeGameScreenChilliFiestaMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    animTime = animTime + 2
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()
        self:resetMaskLayerNodes()
        callFun()
    end,util_max(2,animTime),self:getModuleName())
end

function CodeGameScreenChilliFiestaMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag


    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        local animName = slotNode:getLineAnimName()
        slotNode:runAnim(animName,false)
    end

    return slotNode
end


function CodeGameScreenChilliFiestaMachine:showEffect_Respin(effectData)
    if not self.m_reconnect and self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount  then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_WIN_RESPIN)
    end
    -- effectData.p_isPlay = true
    if self.m_reconnect then
        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )
        --可随机的特殊信号
        local endTypes = self:getRespinLockTypes()

        self.m_chilliPlayer:setVisible(false)
        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
    else
        performWithDelay(self,function()
            if self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount then
                
                util_spinePlay(self.m_chilliPlayer,"actionframe",false)
                performWithDelay(self,function()
                    util_spinePlay(self.m_chilliPlayer,"idleframe",true)
                    BaseSlotoManiaMachine.showEffect_Respin(self,effectData)
                end,143/30)

                for i=1,#self.m_slotParents do
                    local parentNode = self.m_slotParents[i].slotParent
                    local childs = parentNode:getChildren()
                    for index=1, #childs do
                        local slotNode = childs[index]
                        if slotNode.p_rowIndex <= 3 and self:isFixSymbol(slotNode.p_symbolType) then
                                -- p_rowIndex
                            slotNode:runAnim("actionframe")
                        end
                    end
                end
                globalMachineController:playBgmAndResume("ChilliFiestaSounds/music_ChilliFiesta_respinTrigger.mp3",4.5,0.4,1)
            end
        end,1)
    end
    return true

end
---
-- 显示free spin
function CodeGameScreenChilliFiestaMachine:showEffect_FreeSpin(effectData)

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

        util_spinePlay(self.m_chilliPlayer,"actionframe",false)
        performWithDelay(self,function()
            util_spinePlay(self.m_chilliPlayer,"idleframe",true)
            self:showFreeSpinView(effectData)
        end,143/30)
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
        end)
        util_nextFrameFunc(function()
            gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_scatterTrigger.mp3")
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


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenChilliFiestaMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

-- 处理特殊关卡 遮罩层级
function CodeGameScreenChilliFiestaMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function CodeGameScreenChilliFiestaMachine:isShowChooseBetOnEnter( )
    return not self:checkHasFeature() and self.m_betLevel == 0
end

function CodeGameScreenChilliFiestaMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        if _trigger then
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * (self.m_iReelRowNum * 2 + 0.5 )))
        else
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
        end
       
    end
end



-------------------------------------------------公共jackpot-----------------------------------------------------------------------

function CodeGameScreenChilliFiestaMachine:updateNetWorkData()
    CodeGameScreenChilliFiestaMachine.super.updateNetWorkData(self)
    self.m_jackpotView:resetCurRefreshTime()
    self.m_RsjackpotView:resetCurRefreshTime()
end

--[[
    更新公共jackpot状态
]]
function CodeGameScreenChilliFiestaMachine:updataJackpotStatus(params)
    
    local totalBetID = globalData.slotRunData:getCurTotalBet()
    self.m_jackpot_status = "Normal" -- "Mega" "Super"

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    if self.m_isJackpotEnd then
        self:updateJackpotBarMegaShow()
        return
    end

    

    if not mgr:isDownloadRes() then
        self:updateJackpotBarMegaShow()
        return
    end
    
    local data = mgr:getRunningData()
    if not data or not next(data) then
        self:updateJackpotBarMegaShow()
        return
    end

    local levelData = data:getLevelDataByBet(totalBetID)
    local levelName = levelData.p_name
    self.m_jackpot_status = levelName
    self:updateJackpotBarMegaShow()
end

function CodeGameScreenChilliFiestaMachine:updateJackpotBarMegaShow()
    self.m_jackpotView:updateMegaShow()
    self.m_RsjackpotView:updateMegaShow()
end

function CodeGameScreenChilliFiestaMachine:getCommonJackpotValue(_status, _addTimes)
    _addTimes = math.floor(_addTimes)
    local value     = 0

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if _status == "Mega" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Mega)
        end
    elseif _status == "Super" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Super)
        end
    end


    return value
end


--[[
    新增顶栏和按钮
]]
function CodeGameScreenChilliFiestaMachine:initTopCommonJackpotBar()
    if not ACTIVITY_REF.CommonJackpot then
        return 
    end

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        return
    end

    local commonJackpotTitle = mgr:createTitleNode()

    if not commonJackpotTitle then
        return
    end
    self.m_commonJackpotTitle = commonJackpotTitle
    self:addChild(self.m_commonJackpotTitle, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local titlePos = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"), self)
    local topSpSize = self.m_commonJackpotTitle:findChild("sp_Jackpot1"):getContentSize()
    titlePos.y = titlePos.y - topSpSize.height*0.25
    self.m_commonJackpotTitle:setPosition(titlePos)
    self.m_commonJackpotTitle:setScale(globalData.topUIScale)
    
end

return CodeGameScreenChilliFiestaMachine