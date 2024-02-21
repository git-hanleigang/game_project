---
-- island li
-- 2019年1月26日
-- CodeGameScreenPussMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"


local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local CollectData = require "data.slotsdata.CollectData"
local PussSlotsNode = require "CodePussSrc.PussSlotsNode"
local BaseSlots = require "Levels.BaseSlots"

local CodeGameScreenPussMachine = class("CodeGameScreenPussMachine", BaseFastMachine)

CodeGameScreenPussMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenPussMachine.SYMBOL_SCORE_WILD_CAT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 
CodeGameScreenPussMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenPussMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

CodeGameScreenPussMachine.SYMBOL_WILD_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20 -- 113
CodeGameScreenPussMachine.SYMBOL_WILD_3X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21 -- 114
CodeGameScreenPussMachine.SYMBOL_WILD_5X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22 -- 115
CodeGameScreenPussMachine.SYMBOL_WILD_8X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23 -- 116
CodeGameScreenPussMachine.SYMBOL_WILD_10X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24 -- 117
CodeGameScreenPussMachine.SYMBOL_WILD_25X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 25 -- 118
CodeGameScreenPussMachine.SYMBOL_WILD_100X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 26 -- 119


CodeGameScreenPussMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2

CodeGameScreenPussMachine.m_chipList = nil
CodeGameScreenPussMachine.m_playAnimIndex = 0
CodeGameScreenPussMachine.m_lightScore = 0
CodeGameScreenPussMachine.m_SpecialReels = {3,4,5,6,7}

CodeGameScreenPussMachine.m_respinLittleNodeSize = 7/3

CodeGameScreenPussMachine.m_normalReelPercent = {100,75,60,50,43}

CodeGameScreenPussMachine.m_respinReelCut = {583,695,807,919,1031}

CodeGameScreenPussMachine.m_roofBeginPos = {595,600,604,608,614}
CodeGameScreenPussMachine.m_roofMaxPos = {595,709,824,940,1060}

CodeGameScreenPussMachine.m_topTiaoMaxPos = {1031,920,808,696,584}
CodeGameScreenPussMachine.m_topTiaoBeginPos = 584
CodeGameScreenPussMachine.m_topTiaoAddPos = 2

CodeGameScreenPussMachine.m_respinLayerMaxSize = {594,706,818,930,1041}
CodeGameScreenPussMachine.m_respinLayerBeginPos = 582

CodeGameScreenPussMachine.m_SevenRowsLayerMaxSize = {336,448,560,672,784}
CodeGameScreenPussMachine.m_m_SevenRowsLayerBegimSize = 336

CodeGameScreenPussMachine.m_flyWildList = {}
CodeGameScreenPussMachine.m_allJackpotWin = {}

CodeGameScreenPussMachine.m_nodePos = nil -- 地图当前进度
CodeGameScreenPussMachine.m_bonusPath = nil -- 地图id

local FIT_HEIGHT_MAX = 1281
local FIT_HEIGHT_MIN = 1136

local RESPIN_ROW_COUNT = 7
local NORMAL_ROW_COUNT = 3

local selectRespinId = 1
local selectFreeSpinId = 2


-- 构造函数
function CodeGameScreenPussMachine:ctor()
    BaseFastMachine.ctor(self)

    self.m_choiceTriggerRespin = false
    self.m_chooseRepin = false
    self.m_chooseRepinNotCollect = false

    self.m_isOnceClipNode = false

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_flyWildList = {}
    self.m_triggerShowMap = false

    self.m_SpecialReels = {3,4,5,6,7}

    self.m_respinLittleNodeSize = 7/3

    self.m_normalReelPercent = {100,75,60,50,43}

    self.m_respinReelCut = {583,695,807,919,1031}

    self.m_roofBeginPos = {595,600,604,608,614}
    self.m_roofMaxPos = {595,709,824,940,1060}

    self.m_topTiaoMaxPos = {1031,920,808,696,584}
    self.m_topTiaoBeginPos = 584
    self.m_topTiaoAddPos = 2

    self.m_respinLayerMaxSize = {594,706,818,930,1041}
    self.m_respinLayerBeginPos = 582

    self.m_SevenRowsLayerMaxSize = {336,448,560,672,784}
    self.m_m_SevenRowsLayerBegimSize = 336

    self.m_flyWildList = {}
    self.m_allJackpotWin = {}

    self.m_nodePos = nil -- 地图当前进度
    self.m_bonusPath = nil -- 地图id

    self.m_midCatJumpPos = cc.p(386,704)
    self.m_downCatJumpPos = cc.p(326,248)

    self.m_isPlayRespinEnd = false

    self.m_isBonusTrigger = false

    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenPussMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("PussConfig.csv", "LevelPussConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  



function CodeGameScreenPussMachine:initUI()


    self:findChild("Puss_Fs_ear"):setVisible(false)
    self:findChild("Puss_Fs_ear_1"):setVisible(false)

    self:initReelsBG( )
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:isNormalBgShow(true)
   
    self.m_LogoView = util_createView("CodePussSrc.PussLogoView")
    self:findChild("logo"):addChild(self.m_LogoView)
    self:findChild("logo"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)

    self.m_JackPotView = util_createView("CodePussSrc.PussJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotView)
    self.m_JackPotView:initMachine(self)
    self.m_JackPotView:runCsbAction("idle")
    
    self.m_BigRoofView = util_createView("CodePussSrc.PussBigRoofView")
    self:findChild("roof"):addChild(self.m_BigRoofView)


    self.m_CollectBar = util_createView("CodePussSrc.Collect.PussCollectBarView")
    self:findChild("jindutiao"):addChild(self.m_CollectBar)
    self.m_CollectBar:setMachine(self)


    self.m_respinSpinbar = util_createView("CodePussSrc.PussRespinBarView")
    self:findChild("respinBar"):addChild(self.m_respinSpinbar)
    self.m_respinSpinbar:setVisible(false)

    self.m_freespinSpinbar = util_createView("CodePussSrc.PussFreespinBarView")
    self:findChild("freespinBar"):addChild(self.m_freespinSpinbar)
    self.m_freespinSpinbar:setVisible(false)
    self.m_baseFreeSpinBar = self.m_freespinSpinbar

    

    self.m_MapView = util_createView("CodePussSrc.Map.PussMapMainView")
    self:addChild(self.m_MapView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_MapView:setVisible(false)
    util_csbScale(self.m_MapView.m_csbNode, self.m_machineRootScale)
    

    self:initLittleRoof( )

    local data = {}
    data.parent = self
    self.m_SevenRowReels = util_createView("CodePussSrc.SevenRow.PussMiniMachine",data)
    self:findChild("sevenReels"):addChild(self.m_SevenRowReels)
    self.m_SevenRowReels:setVisible(false)
    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setVisible(true)
    end
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick  then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_SevenRowReels.m_touchSpinLayer)
    end

    self:findChild("cat"):setLocalZOrder(-1)
    self.m_cat = util_spineCreate("Puss_GameScreen_Tostar",true,true)
    self:findChild("cat"):addChild(self.m_cat)
    util_spinePlay(self.m_cat,"idleframe",true)

    self:findChild("gameBg"):setLocalZOrder(-100)
    
    

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self.m_classicMachine then
            return
        end

        if self.m_isPlayRespinEnd then
            return
        end

        if self.m_bIsBigWin then

            local isFreespinOver = false
            if self:getCurrSpinMode() == FREE_SPIN_MODE then

                if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
                    if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                        isFreespinOver = true
                    end
                end
        
            end

            if not isFreespinOver then
                return
            end
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 1
        local soundTime = 3
        if winRate <= 2 then
            if winRate <= 1 then
                soundIndex = 4 
                soundTime = 4
            else

                if self:checkIsLinesHaveWild() then
                    soundIndex = 1
                    soundTime = 3
                else
    
                    soundIndex = 2
                    soundTime = 3
                end
            end
        else
            soundIndex = 3
            soundTime = 4
        end
        local soundName = "PussSounds/music_Puss_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        performWithDelay(self,function() 
            self.m_winSoundsId = nil
        end,soundTime)
    
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenPussMachine:checkIsLinesHaveWild( )

    
    local winLines = self.m_runSpinResultData.p_winLines

    if winLines and #winLines > 0 then

        for i=1,#winLines do
            local lineData = winLines[i]
            
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then

                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                            
                            return true
                        end
                    end

                end
               
            end 

        end

    end

    if self:isSevenRowsFreespin(  )then
        local winSevenLines = self.m_SevenRowReels.m_runSpinResultData.p_winLines

        if winSevenLines and #winSevenLines > 0 then

            for i=1,#winSevenLines do
                local lineData = winSevenLines[i]
                
                if lineData.p_iconPos and #lineData.p_iconPos > 0 then

                    for lineIndex = 1, #self.m_SevenRowReels.m_runSpinResultData.p_winLines do
                        local lineData = self.m_SevenRowReels.m_runSpinResultData.p_winLines[lineIndex]
                        local checkEnd = false
                        for posIndex = 1 , #lineData.p_iconPos do
                            local pos = lineData.p_iconPos[posIndex] 
        

                            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
                            local catWildPositions =  selfData.catWildPositions or {}
                            if catWildPositions and #catWildPositions > 0  then

                                for j =1,#catWildPositions do
                                    local changeWildPos = catWildPositions[i]

                                    if changeWildPos == pos then
                                        return true
                                    end
                                end
                            end

                        end

                    end
                
                end 

            end

        end
    end


    return false

end

function CodeGameScreenPussMachine:getBottomUINode( )
    return "CodePussSrc.PussGameBottomNode"
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenPussMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "PussSounds/Puss_scatter_down.mp3"
        elseif i == 2 then
            soundPath = "PussSounds/Puss_scatter_down.mp3"
        else
            soundPath = "PussSounds/Puss_scatter_down.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenPussMachine:changeViewNodePos( )
   
    local downNodeName = {"Puss_rl_botom_6","Node_litleRoof",
    "Puss_rl_top","reel_right","reel_left","Image_1","reel_in4","reel_in3",
    "reel_in2","reel_in1","reel_4","reel_3","reel_2","reel_1","reel_0",
    "Puss_rl_top2","sp_reel_4","sp_reel_3","sp_reel_2","sp_reel_1",
    "sp_reel_0","sevenReels","Puss_rl_botom2_7","jindutiao","respinBar","roof",
    "logo","cat","Puss_rl_ear_1","Puss_rl_ear_1_0","reel_reel_0","reel_reel_1",
    "reel_reel_2","reel_reel_3","reel_reel_4","freespinBar","Puss_rl_side_6","Puss_rl_side_6_0",
    "Puss_rl_shadow_1","Puss_Fs_ear","Puss_Fs_ear_1"}

    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5

        for i=1,#downNodeName do
            local name = downNodeName[i]
            local ui =  self:findChild(name)
            if ui then
                ui:setPositionY(ui:getPositionY() - posY)
            end

        end

        

         self.m_respinLayerBeginPos = math.ceil( self.m_respinLayerBeginPos - posY ) 

        for i=1,#self.m_respinLayerMaxSize do
            self.m_respinLayerMaxSize[i] =  math.ceil( self.m_respinLayerMaxSize[i] - posY ) 
        end
        
        local sizeBet = display.height / display.width

        if sizeBet >= 2 then
            self.m_midCatJumpPos.y = self.m_midCatJumpPos.y - posY + 5
            self.m_downCatJumpPos.y = self.m_downCatJumpPos.y - posY - 95

            self:findChild("cat"):setPositionY(self.m_midCatJumpPos.y)

            self:findChild("cat"):setScale(1.45)

            local jackpot =  self:findChild("jackpot")
            if jackpot then
                jackpot:setPositionY(jackpot:getPositionY() + 30)
            end
            
        else


            self.m_midCatJumpPos.y = self.m_midCatJumpPos.y - posY - 5
            self.m_downCatJumpPos.y = self.m_downCatJumpPos.y - posY - 33

            self:findChild("cat"):setPositionY(self.m_midCatJumpPos.y)

            if sizeBet > 1.667 and sizeBet < 1.777  then
                self:findChild("cat"):setScale(0.95)
            else
                self:findChild("cat"):setScale(1.05)
            end
            

            local jackpot =  self:findChild("jackpot")
            if jackpot then
                jackpot:setPositionY(jackpot:getPositionY() - 25)
            end

        end
    
    elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
        self.m_midCatJumpPos.y = self.m_midCatJumpPos.y  - 25
        self:findChild("cat"):setPositionY(self.m_midCatJumpPos.y)
        self:findChild("cat"):setScale(1.05)

    elseif display.height < FIT_HEIGHT_MIN then

        self.m_midCatJumpPos.y = self.m_midCatJumpPos.y - 30
        self.m_midCatJumpPos.x = self.m_midCatJumpPos.x - 15

        self:findChild("cat"):setPosition(self.m_midCatJumpPos)
        self:findChild("cat"):setScale(0.9)
       


        local freespinBar =  self:findChild("freespinBar")
        
        if freespinBar then
            freespinBar:setPositionY(freespinBar:getPositionY() - 80)
        end

        local respinBar =  self:findChild("respinBar")
        if respinBar then
            respinBar:setPositionY(respinBar:getPositionY() - 80)
        end

        local jackpot =  self:findChild("jackpot")
        jackpot:setScale(1.2)
        if jackpot then
            jackpot:setPositionY(jackpot:getPositionY() - 100)
        end
        
        

        

    end


    self.m_RunDi = {}
    for i=1,5 do

        local longRunDi =  util_createAnimation("WinFramePuss_run_di.csb") 
        self:findChild("root"):addChild(longRunDi,1) 
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunDi, longRunDi )
        longRunDi:setVisible(false)
    end
 
end

function CodeGameScreenPussMachine:scaleMainLayer()
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
            mainScale = (FIT_HEIGHT_MAX + 80 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 65)
            else
                local sizeBet = display.height / display.width
                local addY = 0
                if sizeBet > 1.670 and sizeBet < 1.698  then
                    addY = - 10
                end

                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 33 + addY )
            end
            
        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 50 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
        else
            mainScale = (display.height + 120 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 43)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    if globalData.slotRunData.isPortrait then
        local bottomHeight = util_getSaveAreaBottomHeight()
        local bangHeight = util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bottomHeight - bangHeight )
    end
    
end


function CodeGameScreenPussMachine:initLittleRoof( )
    
    local FatherNodeName = {"roof1","roof12","roof13","roof14","roof15"}
    for i=1,5 do
        local name = "m_LittleRoof_"..i 
        self[name] = util_createView("CodePussSrc.PussLittleRoofView",i)
        self:findChild(FatherNodeName[i]):addChild(self[name])
        self[name]:setVisible(false)
    end

end

function CodeGameScreenPussMachine:initGameStatusData(gameData)

    self.m_nodePos = gameData.gameConfig.extra.node
    if self.m_nodePos == nil then
        self.m_nodePos = 0
    end
    self.m_bonusPath = gameData.gameConfig.init.bonusPath
    
    BaseFastMachine.initGameStatusData(self, gameData)
end


-- 断线重连 
function CodeGameScreenPussMachine:MachineRule_initGame(  )

  
    local collectData =  self:getBonusCollectData( )

    if collectData and type(collectData) == "table" then
        local progress = self:getProgress(collectData)
        if progress then
            self.m_CollectBar.m_Progress:setPercent(progress)
        end
    end

    if self:isSevenRowsFreespin(  ) then

        self.m_JackPotView:runCsbAction("idle1")

        self:changePosLittleUIX( false )

        self:findChild("Puss_rl_ear_1"):setVisible(false)
        self:findChild("Puss_rl_ear_1_0"):setVisible(false)

        self:findChild("Puss_Fs_ear"):setVisible(true)
        self:findChild("Puss_Fs_ear_1"):setVisible(true)

        self.m_SevenRowReels:setVisible(true)

        if self.m_touchSpinLayer then
            self.m_touchSpinLayer:setVisible(false)
        end

        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)
        self:setTopUiVisible( false)
        self:findChild("cat"):setLocalZOrder(-1)
        util_spinePlay(self.m_cat,"idleframe2")
        self:findChild("cat"):setPosition(self.m_downCatJumpPos)
        self:reelsBgActionToSeven(0)
        self:isNormalBgShow(false)
        for i=1,5 do
            local name = "m_LittleRoof_"..i 
            self[name]:setVisible(true)
            local img = self[name]:findChild("Puss_jackpot_img") 
            if img then
                img:setVisible(false)
            end
        end

    end
    
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE  then
        local selfData =  self.m_runSpinResultData.p_selfMakeData or {}
        local freespinType = selfData.freespinType
        if freespinType == "collect" then
            self.m_bottomUI:showAverageBet()
        end
    end



end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPussMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Puss"  
end

-- 继承底层respinView
function CodeGameScreenPussMachine:getRespinView()
    return "CodePussSrc.PussRespinView"
end
-- 继承底层respinNode
function CodeGameScreenPussMachine:getRespinNode()
    return "CodePussSrc.PussRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPussMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_Puss_FixBonus"

    elseif symbolType == self.SYMBOL_SCORE_WILD_CAT then
        return "Socre_Puss_Wild_Cat"

    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Puss_10"

    elseif symbolType == self.SYMBOL_WILD_2X then
        return "Socre_Puss_Wild"

    elseif symbolType == self.SYMBOL_WILD_3X then
        return "Socre_Puss_Wild"

    elseif symbolType == self.SYMBOL_WILD_5X then
        return "Socre_Puss_Wild"

    elseif symbolType == self.SYMBOL_WILD_8X then
        return "Socre_Puss_Wild"

    elseif symbolType == self.SYMBOL_WILD_10X then
        return "Socre_Puss_Wild"

    elseif symbolType == self.SYMBOL_WILD_25X then
        return "Socre_Puss_Wild"

    elseif symbolType == self.SYMBOL_WILD_100X then
        return "Socre_Puss_Wild"
    end


    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenPussMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
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
       return self:randomDownRespinSymbolScore(self.SYMBOL_FIX_SYMBOL)
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)



    return score
end

function CodeGameScreenPussMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenPussMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        local addPos = 0

        local features = self.m_runSpinResultData.p_features
        -- 触发respin那一次的 storedIcons 是按照 7x5算的
        if features and features[2] and features[2] == RESPIN_MODE then
            if rowCount == NORMAL_ROW_COUNT then
                addPos = 20
            end
        end

        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol) + addPos) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet

            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local Ratio = score / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

            local lab = symbolNode:getCcbProperty("m_lb_score")
            if lab then
                if Ratio >= 8 then
                    lab:setColor(cc.c3b(255,255,255))
                else
                    lab:setColor(cc.c3b(255,255,255))
                end
    
                score = util_formatCoins(score, 3)
                lab:setString(score)
            end
        end

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local Ratio = score / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

            local lab = symbolNode:getCcbProperty("m_lb_score")
            if lab then
                if Ratio >= 8 then
                    lab:setColor(cc.c3b(255,255,255))
                else
                    lab:setColor(cc.c3b(255,255,255))
                end
    
                score = util_formatCoins(score, 3)
                lab:setString(score)
            end
            
        end
        
    end

end

function CodeGameScreenPussMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        self:setSpecialNodeScore(self,{node})
    end
end

function CodeGameScreenPussMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end
    return node
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPussMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_WILD_CAT,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_2X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_3X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_5X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_8X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_10X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_25X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_100X, count = 2}
    

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenPussMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return true
    end
    return false
end

---
--添加金边
function CodeGameScreenPussMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    local rundi = self.m_RunDi[col]

    if rundi then
        rundi:setVisible(true)
        rundi:playAction("open")
    end
    


    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--
--单列滚动停止回调
--
function CodeGameScreenPussMachine:slotOneReelDown(reelCol)    

    

    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end


    if self.m_reelDownSoundPlayed then

        self:playReelDownSound(reelCol,self.m_reelDownSound )

    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end





    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    

    local rundi = self.m_RunDi[reelCol]
    if rundi:isVisible() then
        rundi:playAction("end",false,function(  )
            rundi:setVisible(false)
        end)
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,iRow,SYMBOL_NODE_TAG))
            if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                isHaveFixSymbol = true
                targSp:runAnim("buling",false,function(  )
                    targSp:runAnim("idleframe")
                end)

            end
        end

        if isHaveFixSymbol == true  then
            -- respinbonus落地音效

            local soundPath = "PussSounds/music_Puss_Bonus_Down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

        end

    end

    
   
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPussMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPussMachine:levelFreeSpinOverChangeEffect()

    
    
end
---------------------------------------------------------------------------

---
-- 显示free spin
function CodeGameScreenPussMachine:showEffect_FreeSpin(effectData)

    self.isInBonus = true

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
        --
        --self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
            self:showFreeSpinView(effectData)
        --end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        -- self:playScatterTipMusicEffect()
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenPussMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

-- 触发freespin时调用
function CodeGameScreenPussMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            -- gLobalSoundManager:playSound("PussSounds/music_Puss_fsView.mp3")
            -- self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self:findChild("cat"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
                gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Down_And_HuiJina.mp3")
                util_spinePlay(self.m_cat,"actionframe")
                util_spineFrameCallFunc(self.m_cat, "actionframe", "jump1", function(  )
                    self:catJumpDown( )

                    util_spineFrameCallFunc(self.m_cat, "actionframe", "Show1", function(  )

                        self.m_JackPotView:runCsbAction("toseven")

                        self:findChild("Puss_rl_ear_1"):setVisible(false)
                        self:findChild("Puss_rl_ear_1_0"):setVisible(false)

                        self:findChild("Puss_Fs_ear"):setVisible(true)
                        self:findChild("Puss_Fs_ear_1"):setVisible(true)
    
                        self.m_SevenRowReels:setVisible(true)

                        if self.m_touchSpinLayer then
                            self.m_touchSpinLayer:setVisible(false)
                        end

                        --隐藏 盘面信息
                        self:setReelSlotsNodeVisible(false)
    
                        self:changePosLittleUIX( false )

                        self:setTopUiVisible( false)
    
                        for i=1,5 do
                            local name = "m_LittleRoof_"..i 
                            self[name]:setVisible(true)
                            local img = self[name]:findChild("Puss_jackpot_img") 
                            if img then
                                img:setVisible(false)
                            end
                        end
    
                        self.m_SevenRowReels:changeClippingRegionToFiveRows( )
    
                        local oldSizeY = {} 
                        for i=1,5 do
                            table.insert( oldSizeY, self.m_m_SevenRowsLayerBegimSize)
                        end
                        gLobalSoundManager:playSound("PussSounds/music_Puss_Reel_up.mp3")

                        local reelBgChangeTimes = 0.3
                        self:isNormalBgShow(false)
                        self:reelsBgActionToSeven(reelBgChangeTimes,function(  )
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()  
                        end,function(updatetimes )
    
                            local allOver = true
                            allOver =  self.m_SevenRowReels:updateSevenRowsSizeY( updatetimes , oldSizeY)
                            
                            return allOver 
    
                        end)
                        
                    end)
                end)

                

                
                     
            -- end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

end

---
-- 显示free spin over 动画
function CodeGameScreenPussMachine:showEffect_FreeSpinOver()

    performWithDelay(self,function(  )
        globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")
        if #self.m_reelResultLines == 0 then
            self.m_freeSpinOverCurrentTime = 1
        end

        if self.m_fsOverHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
            self.m_fsOverHandlerID = nil
        end
        if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
            self.m_fsOverHandlerID =scheduler.scheduleGlobal(function()
                if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
                    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
                else
                    self:showEffect_newFreeSpinOver()
                end
            end,0.1)
        else
            self:showEffect_newFreeSpinOver()
        end
    end,1.5)

    
    return true
end


function CodeGameScreenPussMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

-- 触发freespin结束时调用
function CodeGameScreenPussMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("PussSounds/music_Puss_Respin_OverView.mp3")
   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self.m_baseFreeSpinBar:setVisible(false)
       
            self:findChild("Puss_Fs_ear"):setVisible(false)
            self:findChild("Puss_Fs_ear_1"):setVisible(false)

            self:findChild("Puss_rl_ear_1"):setVisible(true)
            self:findChild("Puss_rl_ear_1_0"):setVisible(true)
            
    
            self:changePosLittleUIX( true )

            -- 调用此函数才是把当前游戏置为freespin结束状态
            self:triggerFreeSpinOverCallFun()    
            
            self:findChild("cat"):setLocalZOrder(-1)
            gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Back.mp3")
            
            -- 猫回去
            util_spinePlay(self.m_cat,"actionframe2")
            self:findChild("cat"):setPosition(self.m_midCatJumpPos)
            util_spineEndCallFunc(self.m_cat, "actionframe2", function(  )
                util_spinePlay(self.m_cat,"idleframe",true)
            end)     
    
    end)

    view:setOverActBeginCallFunc( function(  )

        self:changePosLittleUIX( true )

        self.m_baseFreeSpinBar:setVisible(false)
       
        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
            self:createRandomReelsNode()
        end

        
        if self.m_fsReelDataIndex == 0 then
            self:setCurrSpinMode( NORMAL_SPIN_MODE)
            self:AddBonusEffect( )
        end

        if self.m_fsReelDataIndex ~= 0 then
            self.m_fsReelDataIndex = 0 
            self.m_bottomUI:hideAverageBet()

            local progress = 0
            if progress then
                self.m_CollectBar.m_Progress:setPercent(progress)
            end

        else 

            self.m_SevenRowReels:clearFrames_Fun()
            self.m_SevenRowReels:clearWinLineEffect()
            self.m_SevenRowReels:changeFlyWildList()
            self.m_SevenRowReels:removeFlyWild( )

            local oldSizeY = {} 
            for i=1,5 do
                table.insert( oldSizeY, self.m_SevenRowsLayerMaxSize[i])
            end

            self.m_JackPotView:runCsbAction("idle")
            self:isNormalBgShow(true)
            local reelBgChangeTimes = 0
            self:reelsBgActionToFive(reelBgChangeTimes,function(  )

                for i=1,5 do
                    local name = "m_LittleRoof_"..i 
                    self[name]:setVisible(false)
                end
                self:setTopUiVisible( true)
                self.m_SevenRowReels:setVisible(false)
                if self.m_touchSpinLayer then
                    self.m_touchSpinLayer:setVisible(true)
                end
                --隐藏 盘面信息
                self:setReelSlotsNodeVisible(true)  

                

                
            end,function(updatetimes )

                local allOver = true
                allOver =  self.m_SevenRowReels:updateSevenRowsToFiveSizeY( updatetimes , oldSizeY)
                
                return allOver 

            end)

        end


    end )

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},592)

end

function CodeGameScreenPussMachine:AddBonusEffect( )
    
    --是否触发收集小游戏
    if self:BaseMania_isTriggerCollectBonus() then -- true or

        self.m_triggerShowMap = true
    end
    

    local featureDatas = self.m_runSpinResultData.p_features
    local isAddFs = false
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        
            isAddFs = true

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS

            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

        end
    end

    return isAddFs
end

function CodeGameScreenPussMachine:removeAllReelsNode( )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end
        end
    end

end

function CodeGameScreenPussMachine:createRandomReelsNode(  )
    
    self.m_initGridNode = true
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()
    self:removeAllReelsNode( )
    self.m_runSpinResultData.p_reels = self.m_runSpinResultData.p_selfMakeData.baseReels
    local reels = {}
    for iRow = 1, 3 do
        reels[iRow] = self.m_runSpinResultData.p_selfMakeData.baseReels[#self.m_runSpinResultData.p_selfMakeData.baseReels - iRow + 1]
    end

    for iCol = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[iCol]
        local slotParent = parentData.slotParent

        for iRow = 1, 3 do

            local symbolType = reels[iRow][iCol]
            
            if symbolType then

                local newNode =  self:getSlotNodeWithPosAndType( symbolType , iRow, iCol , false)
                local zorder = self:getBounsScatterDataZorder(symbolType)
                parentData.slotParent:addChild(
                    newNode,
                    REEL_SYMBOL_ORDER.REEL_ORDER_2,
                    self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG)
                )
                newNode.m_symbolTag = SYMBOL_NODE_TAG
                newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
                newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                newNode.m_isLastSymbol = true
                newNode.m_bRunEndTarge = false
                local columnData = self.m_reelColDatas[iCol]
                newNode.p_slotNodeH = columnData.p_showGridH         
                newNode:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                local halfNodeH = columnData.p_showGridH * 0.5
                newNode:setPositionY(  (iRow - 1) * columnData.p_showGridH + halfNodeH )


            end

        end
    end
    self:initGridList(true)
end

function CodeGameScreenPussMachine:MachineRule_checkTriggerFeatures()
    if self.m_fsReelDataIndex ~= 0  then
        return
    end
    
    if self.m_runSpinResultData.p_features ~= nil and 
        #self.m_runSpinResultData.p_features > 0 then
        
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i=1,featureLen do
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

                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then  -- 触发respin 玩法
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
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then  -- 其他小游戏

                    -- 添加 BonusEffect 
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end

            end
            
        end

    end
end


function CodeGameScreenPussMachine:showRespinJackpot(index,coins,func)

    local curFunc = function(  )

        if func then
            func()
        end
    end
    
    local jackPotWinView = util_createView("CodePussSrc.PussJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self,index,coins,curFunc)
end

-- 结束respin收集
function CodeGameScreenPussMachine:playLightEffectEnd()
    
    -- 通知respin结束
    
    
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    self:showRespinOverView()
 
end

function CodeGameScreenPussMachine:playJackpotCollectAnim(  )
    local isPlay = false
    for k,v in pairs(self.m_allJackpotWin) do
        local data = v

        if not data.isPlay then

            self.m_allJackpotWin[k].isPlay = true
            isPlay = true

            local nJackpotType = 0
            if data.type ==  "Grand" then
                nJackpotType = 1
            elseif data.type ==  "Major" then
                nJackpotType = 2
            elseif data.type ==  "Minor" then
                nJackpotType = 3

            end

            local jackpotScore = v.coins

            self.m_lightScore = self.m_lightScore + jackpotScore

            self:showRespinJackpot(nJackpotType, jackpotScore, function()

                self:hideOneJackPotTip( data.type)
                
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin 

                self:playJackpotCollectAnim(  ) 
            end)
            -- gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_jackpotwinframe.mp3")

            
            break
        end
    end

    if not isPlay then
        self:playLightEffectEnd()
    end
end


function CodeGameScreenPussMachine:runJackPotAct( )
    local allJackpotWinCoins = self.m_runSpinResultData.p_selfMakeData.allJackpotWinCoins

    self.m_allJackpotWin = {}

    for k,v in pairs(allJackpotWinCoins) do
        
        local jackPotData = {}
        jackPotData.type = tostring(k) 
        jackPotData.coins = v
        jackPotData.isPlay = false

        if jackPotData.type ==  "Grand" then
            jackPotData.index  = 1
        elseif jackPotData.type ==  "Major" then
            jackPotData.index = 2
        elseif jackPotData.type ==  "Minor" then
            jackPotData.index = 3
        
        end

        

        table.insert( self.m_allJackpotWin, jackPotData )

    end
    
    table.sort( self.m_allJackpotWin, function(a,b  )

        return a.index > b.index

    end )
    
    

end

function CodeGameScreenPussMachine:getTableNum( array)
    local num = 0

    for k,v in pairs(array) do
        num = num + 1
    end

    return num
    
end

function CodeGameScreenPussMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then

        -- 判断是否有Jackpot
        local allJackpotWinCoins = self.m_runSpinResultData.p_selfMakeData.allJackpotWinCoins

        if (type(allJackpotWinCoins) == "table") and self:getTableNum( allJackpotWinCoins) > 0 then
            self:runJackPotAct( )
            self:playJackpotCollectAnim(  ) 
            
        else
            self:playLightEffectEnd()
        end
   
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function fishFlyEndJiesuan()

            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim() 
      
    end
    -- 添加鱼飞行轨迹
    local function fishFly()
            
            local coins = self.m_lightScore  
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
            globalData.slotRunData.lastWinCoin = lastWinCoin  
 
            scheduler.performWithDelayGlobal(function()

                fishFlyEndJiesuan()    

            end,0.4,self:getModuleName())

    end

    self:playCoinWinEffectUI()


    gLobalSoundManager:playSound("PussSounds/music_Puss_Bonus_EndWin.mp3")

    self:createOneActionSymbol(chipNode,"jiesuan",chipNode:getCcbProperty("m_lb_score"):getString())
    chipNode:runAnim("jiesuan")
    local nBeginAnimTime = chipNode:getAniamDurationByName("jiesuan")

    fishFly()        


    
end



--结束移除小块调用结算特效
function CodeGameScreenPussMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    self.m_isPlayRespinEnd = true

    performWithDelay(self,function(  )
        self:playChipCollectAnim()
    end,1)

    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenPussMachine:getRespinRandomTypes( )
    local symbolList = { self.SYMBOL_SCORE_WILD_CAT}
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenPussMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "", bRandom = true},
        
    }

    return symbolList
end

---
-- 触发respin 玩法
--
function CodeGameScreenPussMachine:showEffect_Respin(effectData)

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
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(),childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:removeFromParent()
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
            -- end
        end
    end

    if  self:getLastWinCoin() > 0 then  -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝

        -- scheduler.performWithDelayGlobal(function()
            removeMaskAndLine()
            self:showRespinView(effectData)
        -- end,1,self:getModuleName())

    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin,self.m_iOnceSpinLastWin)
    return true

end

function CodeGameScreenPussMachine:showRespinView()

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        self.isInBonus = true

          --先播放动画 再进入respin
        self:clearCurMusicBg()
      

        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )
        --可随机的特殊信号 
        local endTypes = self:getRespinLockTypes()

        local reels = self.m_runSpinResultData.p_reels or {}
        local waittimes = 0.01
        local actTime = 0.01
        if #reels == NORMAL_ROW_COUNT then
            waittimes = 3
            actTime = 2.3 + 2
            performWithDelay(self,function(  ) -- 这个延迟是为了等bonus播完buling

                

                gLobalSoundManager:playSound("PussSounds/music_Puss_TriggerRespin.mp3")

                for iCol = 1, self.m_iReelColumnNum do
                    for iRow = 1, self.m_iReelRowNum do
                        local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG))
                        if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_SYMBOL then

                            self:createOneActionSymbol(targSp,"chufa",targSp:getCcbProperty("m_lb_score"):getString())

                            -- targSp:runAnim("chufa",false,function(  )
                            -- end)
            
                        end
                    end
                end
            end,2)
            

        end
        
         
        performWithDelay(self,function(  )

            
            local triggerRespinCallFunc = function(  )

                self:respinChangeReelGridCount(RESPIN_ROW_COUNT)
                self.m_iReelRowNum = RESPIN_ROW_COUNT
                --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)
            end

    
            if waittimes == 3 then

                triggerRespinCallFunc()

                
                for i=1,5 do
                    local name = "layerOut_"..i
                    self.m_respinView[name]:setContentSize(270,self.m_respinLayerBeginPos)
                end
                
                self:showReSpinStart(
                    function()

                        self:findChild("Puss_rl_ear_1_0"):setVisible(false)
                        self:findChild("Puss_rl_ear_1"):setVisible(false)

                        for i=1,5 do
                            local name = "layerOut_"..i
                            self.m_respinView[name]:setContentSize(270,self.m_respinLayerBeginPos)
                        end
                        self:findChild("cat"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
        
                        gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Down_And_HuiJina.mp3")
                        util_spinePlay(self.m_cat,"actionframe")
                        util_spineFrameCallFunc(self.m_cat, "actionframe", "jump1", function(  )
                            self:catJumpDown()
        
                            util_spineFrameCallFunc(self.m_cat, "actionframe", "Show1", function(  )
        
                                self:changePosLittleUIX( false )
        
                                self.m_JackPotView:runCsbAction("toseven")
            
                                self:setTopUiVisible( false)
            
                                for i=1,5 do
                                    local name = "m_LittleRoof_"..i 
                                    self[name]:setVisible(true)
                                    local img = self[name]:findChild("Puss_jackpot_img") 
                                    if img then
                                        img:setVisible(true)
                                    end
                                end
            
                                local oldSizeY = {} 
                                for i=1,5 do
                                    table.insert( oldSizeY, self.m_respinLayerBeginPos)
                                end
        
                                gLobalSoundManager:playSound("PussSounds/music_Puss_Reel_up.mp3")
        
                                local reelBgChangeTimes = 0.3
                                self:isNormalBgShow(false)
                                self:reelsBgActionToSeven(reelBgChangeTimes,function(  )
                                    performWithDelay(self,function(  )
                                        self:respinStartCall( )
                                    end,1)
                                    
                                end,function(updatetimes )
            
                                    local allOver = true
                                    
                                    for i=1,5 do
                                        local addSizeY = math.ceil( (self.m_respinLayerMaxSize[i] - self.m_respinLayerBeginPos) / (60*updatetimes) )  
                                        oldSizeY[i] = oldSizeY[i] + addSizeY
            
                                        local name = "layerOut_"..i
                                        local nowSizeY = self.m_respinView[name]:getContentSize().height
                                        if nowSizeY < self.m_respinLayerMaxSize[i] then
                                            self.m_respinView[name]:setContentSize(270,oldSizeY[i])
                                            allOver = false
                                        elseif nowSizeY > self.m_respinLayerMaxSize[i] then
                                            self.m_respinView[name]:setContentSize(270,self.m_respinLayerMaxSize[i])
                                            allOver = false
                                        end
                                    end
            
                                    return allOver 
            
                                end)
                                
                                
                            end)
                        end)
                        
                    end
                )

                
                

            else

                self:findChild("Puss_rl_ear_1_0"):setVisible(false)
                self:findChild("Puss_rl_ear_1"):setVisible(false)
                
                self.m_JackPotView:runCsbAction("idle1")
                self:setTopUiVisible( false)

                for i=1,5 do
                    local name = "m_LittleRoof_"..i 
                    self[name]:setVisible(true)
                    local img = self[name]:findChild("Puss_jackpot_img") 
                    if img then
                        img:setVisible(true)
                    end
                end
                self:findChild("cat"):setLocalZOrder(-1)
                util_spinePlay(self.m_cat,"idleframe2")
                self:findChild("cat"):setPosition(self.m_downCatJumpPos)
                self:isNormalBgShow(false)
                self:reelsBgActionToSeven(0)
                triggerRespinCallFunc()
            end

            

            
        end,actTime)
        


end

--ReSpin开始改变UI状态
function CodeGameScreenPussMachine:changeReSpinStartUI(respinCount)

    self.m_respinSpinbar:setVisible(true)
    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
   
end

--ReSpin刷新数量
function CodeGameScreenPussMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinSpinbar:changeRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenPussMachine:changeReSpinOverUI()
    self.m_respinSpinbar:setVisible(false)
end

function CodeGameScreenPussMachine:showRespinOverView(effectData)

    self.m_isPlayRespinEnd = false

    gLobalSoundManager:playSound("PussSounds/music_Puss_Respin_OverView.mp3")

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()

        self:findChild("Puss_rl_ear_1_0"):setVisible(true)
        self:findChild("Puss_rl_ear_1"):setVisible(true)

        self:setCurrSpinMode( NORMAL_SPIN_MODE)
        self:AddBonusEffect( )
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self:resetMusicBg() 

        self:findChild("cat"):setLocalZOrder(-1)
        gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Back.mp3")
        -- 猫回去
        util_spinePlay(self.m_cat,"actionframe2")
        self:findChild("cat"):setPosition(self.m_midCatJumpPos)
        util_spineEndCallFunc(self.m_cat, "actionframe2", function(  )
            util_spinePlay(self.m_cat,"idleframe",true)
        end)


    end)

    view:setOverActBeginCallFunc( function(  )

        self:changePosLittleUIX( true )

        self.m_choiceTriggerRespin = false
        self.m_chooseRepin = false

        local oldSizeY = {} 
        for i=1,5 do
            table.insert( oldSizeY, self.m_respinLayerMaxSize[i])
        end

        self.m_JackPotView:runCsbAction("idle")

        self.m_respinSpinbar:setVisible(false)

        self:isNormalBgShow(true)
        local reelBgChangeTimes = 0
        self:reelsBgActionToFive(reelBgChangeTimes,function(  )

            self:respinChangeReelGridCount(NORMAL_ROW_COUNT)
            self.m_iReelRowNum = NORMAL_ROW_COUNT

            self:setTopUiVisible( true)
            for i=1,5 do
                local name = "m_LittleRoof_"..i 
                self[name]:setVisible(false)
            end

            self:removeRespinNode()

            if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                self:createRandomReelsNode()
            end

            
            self:setReelSlotsNodeVisible(true)
            
            

        end,function(updatetimes )

            local allOver = true
                        
            for i=1,5 do
                local addSizeY = (self.m_respinLayerMaxSize[i] - self.m_respinLayerBeginPos) / (60*updatetimes)
                oldSizeY[i] = oldSizeY[i] - addSizeY

                local name = "layerOut_"..i
                local nowSizeY = self.m_respinView[name]:getContentSize().height
                if nowSizeY > self.m_respinLayerBeginPos then
                    self.m_respinView[name]:setContentSize(270,oldSizeY[i])
                    allOver = false
                elseif nowSizeY < self.m_respinLayerBeginPos then
                    self.m_respinView[name]:setContentSize(270,self.m_respinLayerBeginPos)
                    allOver = false
                end
            end
            
            return allOver 

        end)
    end )

    -- gLobalSoundManager:playSound("PussSounds/music_Puss_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},592)
end

function CodeGameScreenPussMachine:showReSpinOver(coins,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenPussMachine:showLocalDialog(ccbName,ownerlist,func,isAuto,index)
    local view = util_createView("CodePussSrc.PussBaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
        gLobalViewManager:showUI(view)
    -- end

    return view
end


-- --重写组织respinData信息
function CodeGameScreenPussMachine:getRespinSpinData()
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

--接收到数据开始停止滚动
function CodeGameScreenPussMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)

    for i=1,#unStoredReels do
        local data = unStoredReels[i]
        if data.type == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            unStoredReels[i].type =  self.SYMBOL_SCORE_WILD_CAT
        end
    end
    

    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
end
--播放respin放回滚轴后播放的提示动画
function CodeGameScreenPussMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    --这关没有屏蔽了这个后续如果有问题
    -- if targSp then
        --     targSp:removeFromParent()
        --     self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        -- end
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPussMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_isPlayRespinEnd = false
    self.isInBonus = false
    -- 重置飞wild 信息
    self:clearWinLineEffect()
    self:changeFlyWildList()
    self:restFlyWild( )
    self.m_SevenRowReels:clearWinLineEffect()
    self.m_SevenRowReels:changeFlyWildList( )
    self.m_SevenRowReels:restFlyWild( )


    self:setMaxMusicBGVolume( )
    self:removeSoundHandler( )

    return false -- 用作延时点击spin调用
end




function CodeGameScreenPussMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("PussSounds/music_Puss_enter.mp3")

        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenPussMachine:initFeatureInfo(spinData,featureData)
    if featureData and featureData.p_status == "OPEN" then
        
        self.m_fsReelDataIndex = self.m_bonusPath[self.m_nodePos]
        if self.m_fsReelDataIndex ~= 0 then
            
            self.m_bIsInBonusFreeGame = true
        else
            self.m_bIsInClassicGame = true
            self.m_bClassicReconnect = true
        end
        
        
        local featureID = featureData.p_data.features[#featureData.p_data.features]
        
        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            self.m_bClassicReconnect = false
            table.remove(self.m_runSpinResultData.p_features, #self.m_runSpinResultData.p_features)
        end

        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
            self:removeGameEffectType(GameEffect.EFFECT_BONUS)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
    end
end


function CodeGameScreenPussMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) 	-- 必须调用不予许删除

    self.m_JackPotView:updateJackpotInfo()

    self:addObservers()

    self:upateBetLevel()


    -- local data = {}
    -- data.bonusPath = self.m_bonusPath
    -- data.nodePos = self.m_nodePos
    -- self.m_MapView:updateLittleUINodeAct( self.m_nodePos,self.m_bonusPath )

    if self.m_bClassicReconnect == true  then

        self.isInBonus = true

        self.m_bottomUI:showAverageBet()
        if self.m_bonusPath[self.m_nodePos] == 0 then
            self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.node
            local data = {}
            data.parent = self
            data.paytable = self.m_runSpinResultData.p_selfMakeData.classicWinCoins
            local uiW, uiH = self.m_topUI:getUISize()
            local uiBW, uiBH = self.m_bottomUI:getUISize()
            data.height = uiH + uiBH
            data.func = function()
                performWithDelay(self, function()
                    self:updateBaseConfig()
                    self:initSymbolCCbNames()
                    self:initMachineData()
                    -- effectData.p_isPlay = true
                    self:playGameEffect()
                end, 0.02)
            end
            self.m_classicMachine = util_createView("CodePussSrc.Classic.GameScreenClassicSlots" , data)
            self:addChild(self.m_classicMachine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
            if globalData.slotRunData.machineData.p_portraitFlag then
                self.m_classicMachine.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_classicMachine})
            
        end
    end

end

function CodeGameScreenPussMachine:addObservers()
    BaseFastMachine.addObservers(self)
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()

   end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenPussMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    if self.m_reelsBgActionHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_reelsBgActionHandlerID)
        self.m_reelsBgActionHandlerID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 -- 

function CodeGameScreenPussMachine:changeAddLines( )
    local isAdd = false
    local ishaveBonus = false

    for i=1,#self.m_runSpinResultData.p_winLines do
        local line = self.m_runSpinResultData.p_winLines[i]

       if line.p_type == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            ishaveBonus = true

            break

       elseif line.p_type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            ishaveBonus = true

            break
       end  

    end

    if ishaveBonus and (#self.m_runSpinResultData.p_winLines == 1 ) then
        isAdd = true
    end

    return isAdd
end


function CodeGameScreenPussMachine:insetMiniReelsLines(data )
    if data  and type(data.lines) == "table" then

        if #data.lines > 0 then
           if type(self.m_runSpinResultData.p_winLines) ~=  "table" then
                self.m_runSpinResultData.p_winLines= {}
           end     
        end

        -- 里面有线就不用塞了
        if #self.m_runSpinResultData.p_winLines > 0 and (not self:changeAddLines( )) then
            return
        end


        for i = 1, #data.lines do
            local lineData = data.lines[i]
            local winLineData = SpinWinLineData.new()
            winLineData.p_id = lineData.id
            winLineData.p_amount = lineData.amount
            winLineData.p_iconPos = {}
            winLineData.p_type = lineData.type
            winLineData.p_multiple = lineData.multiple
            
            self.m_runSpinResultData.p_winLines[#self.m_runSpinResultData.p_winLines + 1] = winLineData
        end
    end
    
end

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenPussMachine:MachineRule_network_InterveneSymbolMap()
    if self:isSevenRowsFreespin(  ) then
        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.free ~= nil then
            local resultDatas = self.m_runSpinResultData.p_selfMakeData.free
            self:insetMiniReelsLines(resultDatas)
        end
    end
end


--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function CodeGameScreenPussMachine:netWorklineLogicCalculate()

    if not self:isSevenRowsFreespin(  ) then
        BaseFastMachine.netWorklineLogicCalculate(self)
    else

        self:checkAndClearVecLines()
        self.m_iFreeSpinTimes = 0
    
        --计算连线之前将 计算连线中添加的动画效果移除 (防止重新计算连线后效果播放错误)
        self:removeEffectByType(GameEffect.EFFECT_FREE_SPIN)
        self:removeEffectByType(GameEffect.EFFECT_BONUS )
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
        -- 根据features 添加具体玩法 
        self:MachineRule_checkTriggerFeatures()
        self:staticsQuestEffect()
    end

    
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenPussMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self.m_runSpinResultData.p_selfMakeData then
        if self.m_runSpinResultData.p_selfMakeData.node then
            self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.node
        end
        
    end
    
   
    -- self.m_runSpinResultData 可以从这个里边取网络数据
    
end

--[[
    @desc: 网络消息返回后， 做的处理
    time:2018-11-29 17:24:15
    @return:
]]
function CodeGameScreenPussMachine:produceSlots()

    if not self:isSevenRowsFreespin(  ) then
        BaseFastMachine.produceSlots(self)
    else
        -- 计算连线数据
        self:netWorklineLogicCalculate()
        self:MachineRule_afterNetWorkLineLogicCalculate()

    end
   

end



function CodeGameScreenPussMachine:operaNetWorkData( )
    if self:isSevenRowsFreespin(  ) then

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Stop,true})

        self:setGameSpinStage( GAME_MODE_ONE_RUN )
    else
        BaseFastMachine.operaNetWorkData(self)
    end
   
end

function CodeGameScreenPussMachine:beginReel()

    if self:isSevenRowsFreespin(  )then
        self:resetReelDataAfterReel()
        
        self.m_SevenRowReels:beginMiniReel()
    else

        BaseFastMachine.beginReel(self)

    end


end

function CodeGameScreenPussMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")

    if self.m_classicMachine ~= nil then
        return
    end


    if not self:isSevenRowsFreespin(  ) then
        BaseFastMachine.quicklyStopReel(self, colIndex) 
    end
    
   
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPussMachine:addSelfEffect()

    self.m_collectList = {}
    if self.m_betLevel == 1 and globalData.slotRunData.currSpinMode ~= RESPIN_MODE and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
       
        if not self.m_chooseRepinNotCollect then
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if node then
                        if self:isFixSymbol(node.p_symbolType) then
                            self.m_collectList[#self.m_collectList + 1] = node
                        end
                    end
                end
            end
        end

        if self.m_chooseRepinNotCollect then
            self.m_chooseRepinNotCollect = false
        end
        
    end    

    if self.m_collectList and #self.m_collectList > 0 then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT

    end

    self.m_triggerShowMap = false

     --是否触发收集小游戏
    if self:BaseMania_isTriggerCollectBonus() then -- true or

        self.m_triggerShowMap = true

    end
        


end

function CodeGameScreenPussMachine:BaseMania_isTriggerCollectBonus()
    

    local features = self.m_runSpinResultData.p_features
    if features and features[2] and features[2] == 5 then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusTypes =  selfdata.bonusMode

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            if self:getCurrSpinMode() ~= RESPIN_MODE then
                if bonusTypes and bonusTypes == "collect"  then
                    return true
                end
            end
            
        end
          
    end

end

function CodeGameScreenPussMachine:collectCoin(effectData)
    local time = 0.1
    local flyTimes = 0.5


    local pecent = 0
    local collectData =  self:getBonusCollectData( )
    if collectData and type(collectData) == "table" then
        pecent = self:getProgress(collectData)
    end

    gLobalSoundManager:playSound("PussSounds/music_Puss_Coins_fly.mp3")

    for i = 1 ,#self.m_collectList do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local CsbName = "Socre_Puss_FixBonus.csb"
        local coins =  util_createAnimation(CsbName) 
        coins:findChild("m_lb_score"):setString("")
        
        coins:setPosition(newStartPos)
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)

        local endPos = cc.p(util_getConvertNodePos(self.m_CollectBar:findChild("coins"),coins))    
        coins:playAction("actionframe",false)
        
        local actionList = {}
        actionList[#actionList + 1] =  cc.DelayTime:create(time)
        actionList[#actionList + 1] =  cc.CallFunc:create(function(  )
            local lizi =  util_createAnimation("Socre_Puss_FixBonus_tuowei.csb") 
            coins:addChild(lizi, -1)
            lizi:findChild("Particle_1"):setPositionType(0)
            lizi:findChild("Particle_1_0"):setPositionType(0)
            lizi:findChild("Particle_1"):setDuration(flyTimes)
            lizi:findChild("Particle_1_0"):setDuration(flyTimes)

            local actionList_1 = {}
            actionList_1[#actionList_1 + 1] =  cc.ScaleTo:create(flyTimes,0.75)
            local sq_1 = cc.Sequence:create(actionList_1)
            coins:runAction(sq_1)

        end)

        local BezierPos = {newStartPos, cc.p(endPos.x, newStartPos.y), endPos}
        actionList[#actionList + 1] =  cc.BezierTo:create(flyTimes, BezierPos)
        actionList[#actionList + 1] =  cc.CallFunc:create(function(  )
            coins:findChild("Node_1"):setVisible(false)
        end)

        if i == 1 then
            actionList[#actionList + 1] =  cc.CallFunc:create(function(  )

                gLobalSoundManager:playSound("PussSounds/music_Puss_Coins_Jump_FanKui.mp3")
                
                self.m_CollectBar.m_Coins:runCsbAction("run",false,function(  )
                    self.m_CollectBar.m_Coins:runCsbAction("idleframe")   
                end)
                self.m_CollectBar.m_Progress:updatePercent(pecent)
            end)
        end

        
       
        actionList[#actionList + 1] =  cc.DelayTime:create(time*2)
        actionList[#actionList + 1]  = cc.CallFunc:create(function()

            coins:stopAllActions()
            coins:removeFromParent()

        end)

        local sq = cc.Sequence:create(actionList)
        coins:runAction(sq)

        
    end

    if not self.m_triggerShowMap then

        effectData.p_isPlay = true
        self:playGameEffect()

    else

        performWithDelay(self,function(  )

            if self.m_triggerShowMap then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
    
        end,(time*3) + flyTimes + 0.63) -- 0.63 (self.m_CollectBar.m_Coins:run动画时间)
        
        

    end

   

end


function CodeGameScreenPussMachine:getBonusCollectData( )

    local data = nil
    local collectNetData = self.m_runSpinResultData.p_collectNetData
    if collectNetData then
        if collectNetData[1] then
            data = collectNetData[1]
        end
        
    end

    return data 

end

function CodeGameScreenPussMachine:getProgress(collect)

    local collectTotalCount = collect.collectTotalCount
    local collectCount = collect.collectLeftCount

    local percent = (collectTotalCount - collectCount) / collectTotalCount * 100

    return percent
end

function CodeGameScreenPussMachine:showMapView( func )

    gLobalSoundManager:playSound("PussSounds/music_Puss_Click_Show_Map.mp3")

    self.m_MapView:BonusTriggerShowMap( )

    self.m_MapView:updateRunLittleUINodeAct( self.m_nodePos,self.m_bonusPath )

    self.m_MapView:runCsbAction("start",false,function(  )
        self.m_MapView:runCsbAction("idle",true)
        local littleUiAct = function(  )
            self.m_MapView:runLittleUINodeAct(self.m_nodePos,self.m_bonusPath,function(  )
                
                performWithDelay(self,function(  )
                    local progress = 0
                    if progress then
                        self.m_CollectBar.m_Progress:setPercent(progress)
                    end
                    self.m_MapView:BonusTriggercloseUi(function(  )

                        if func then
                            func()
                        end
    
                    end)
                end,1.5)
                
            end )
        end

        if self.m_nodePos == 1 then

            


            self.m_MapView.m_tipaCat:setVisible(true)
            local pos = cc.p(self.m_MapView["m_point_"..(self.m_nodePos -1)]:getParent():getPosition())
            self.m_MapView.m_tipaCat:setPosition(pos)
            self.m_MapView.m_tipaCat:playAction("animation0")
            self.m_MapView:catJump( pos,function(  )
                littleUiAct()
            end)

        else

            if self.m_bonusPath[self.m_nodePos] == 0 then

                

                self.m_MapView:beginLittleUiCatAct(self.m_nodePos,function(  )
                    littleUiAct()
                end )

            else

                self.m_MapView:beginLittleUiCatAct(self.m_nodePos,function(  )
                    performWithDelay(self,function(  )
                        self.m_MapView.m_tipaCat:playAction("animation1",false,function(  )
                            self.m_MapView.m_tipaCat:playAction("idle")
                            self.m_MapView.m_tipaCat:setVisible(false)
                        end)
                        
                        performWithDelay(self,function(  )
                            littleUiAct()
                        end,0.5)
                    end,1)
                    
                    
                end )
                
            end
            
        end

    end)
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPussMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:collectCoin(effectData)      
    end

    
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPussMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

-- 高低bet

function CodeGameScreenPussMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenPussMachine:updatJackPotLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then

            gLobalSoundManager:playSound("PussSounds/music_Puss_unLock_Bet.mp3")

            self.m_CollectBar:runCsbAction("unlock")
            self.m_betLevel = 1  
        end
    else

        if self.m_betLevel == nil or self.m_betLevel == 1 then

           
            self.m_CollectBar:runCsbAction("lock")
            self.m_betLevel = 0  
        end
        
    end 
end

function CodeGameScreenPussMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenPussMachine:upateBetLevel()

    

    local minBet = self:getMinBet( )
    self:updatJackPotLock( minBet ) 
    
end

function CodeGameScreenPussMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE and
    not self.m_choiceTriggerRespin
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()

    self.m_choiceTriggerRespin = false

    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( )}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)


end


function CodeGameScreenPussMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(7,5,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenPussMachine:respinChangeReelGridCount(count)
    for i=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

function CodeGameScreenPussMachine:initRespinView(endTypes, randomTypes)

    self:initRespinViewJackpotTip( )
    
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initPanel( self )

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()

            local reels = self.m_runSpinResultData.p_reels or {}
            
            if #reels == NORMAL_ROW_COUNT then
                print("等动画播放完毕在开始滚动")
            else
                self:respinoutLinesCall( )
            end
            
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function CodeGameScreenPussMachine:showReSpinStart(func)

    gLobalSoundManager:playSound("PussSounds/music_Puss_fsView.mp3")

    self:clearCurMusicBg()
    self:showLocalDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function CodeGameScreenPussMachine:respinoutLinesCall( )
    self:reSpinEffectChange()
    self:playRespinViewShowSound()
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    -- 更改respin 状态下的背景音乐
    self:changeReSpinBgMusic()
    self:runNextReSpinReel()

end

function CodeGameScreenPussMachine:respinStartCall( )
    self:reSpinEffectChange()
    self:playRespinViewShowSound()
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    -- 更改respin 状态下的背景音乐
    self:changeReSpinBgMusic()
    self:runNextReSpinReel()
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenPussMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local maxCol = self.m_SpecialReels[iCol]
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            if symbolType == nil then
                local randomTypes = self:getRespinRandomTypes( )
                symbolType = randomTypes[math.random( 1, #randomTypes)]
            end

            local reels = self.m_runSpinResultData.p_reels or {}
            if #reels == NORMAL_ROW_COUNT then
                if iRow > NORMAL_ROW_COUNT  then
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        symbolType =  self.SYMBOL_SCORE_WILD_CAT
                    end
                end

            else
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    symbolType =  self.SYMBOL_SCORE_WILD_CAT
                end
            end
            

            if iRow > maxCol then
                symbolType = - 1 -- 超过最大行数就是-1 
            end
            
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
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


---- lighting 断线重连时，随机转盘数据
function CodeGameScreenPussMachine:respinModeChangeSymbolType( )
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then

        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            -- self.m_iReelRowNum = RESPIN_ROW_COUNT
            -- self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

        else
            local storedIcons = self.m_initSpinData.p_storedIcons
            if storedIcons == nil or #storedIcons <= 0 then
                return
            end
    
            local function isInArry(iRow, iCol)
                for k = 1, #storedIcons do
                    local fix = self:getRowAndColByPos(storedIcons[k][1])
                    if fix.iX == iRow and fix.iY == iCol then
                        return true
                    end
                end
                return false
            end 
    
            for iRow = 1, #self.m_initSpinData.p_reels do
                local rowInfo = self.m_initSpinData.p_reels[iRow]
                for iCol = 1, #rowInfo do
                    if isInArry(#self.m_initSpinData.p_reels - iRow + 1, iCol) == false then
                        rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % 8
                    end
                end            
            end

        end

        
    end
end

-- 还原轮盘元素 为默认状态
function CodeGameScreenPussMachine:initReelsBG( )

        -- 小屋檐
        local FatherNodeName = {"roof1","roof12","roof13","roof14","roof15",}
        for i=1,5 do
            local littlRoof = self:findChild(FatherNodeName[i])
            littlRoof:setPositionY(self.m_roofBeginPos[i])
        end


        -- 顶部条1
        for i=1,5 do
            local topTiaoImg = self:findChild("Puss_rl_top2_"..i)
            topTiaoImg:setPositionY(self.m_topTiaoBeginPos)
        end

        -- 顶部条2
        for i=1,5 do
            local topTiaoImg_1 = self:findChild("Puss_rl_top_"..i)
            topTiaoImg_1:setPositionY(self.m_topTiaoBeginPos + self.m_topTiaoAddPos)
        end

        -- 背景条
        for i=1,5 do
            local reelBG = self:findChild("reel_"..(i -1))
            reelBG:setPercent(self.m_normalReelPercent[i])
            
        end


        -- 背景线
        for i=1,4 do
            local reel_in_lines = self:findChild("reel_in"..i )
            reel_in_lines:setPercent(self.m_normalReelPercent[i + 1])
        end

        -- 最右侧背景线
        local reel_right_lines = self:findChild("reel_right")
        local newLinesPercent =  reel_right_lines:getPercent()
        reel_right_lines:setPercent(43)
  

end

-- 播放轮盘元素动画
function CodeGameScreenPussMachine:reelsBgActionToSeven(times,endfunc,updateFunc)
    
    local maxPercent = 100

    if times == 0 then
        times = 1/60
    end


    local littleRoof = {}
    littleRoof.littleRoof_add_1 = (self.m_roofMaxPos[1] - self.m_roofBeginPos[1])/ (60*times)
    littleRoof.littleRoof_add_2 = (self.m_roofMaxPos[2] - self.m_roofBeginPos[2])/ (60*times)
    littleRoof.littleRoof_add_3 = (self.m_roofMaxPos[3] - self.m_roofBeginPos[3])/ (60*times)
    littleRoof.littleRoof_add_4 = (self.m_roofMaxPos[4] - self.m_roofBeginPos[4])/ (60*times)
    littleRoof.littleRoof_add_5 = (self.m_roofMaxPos[5] - self.m_roofBeginPos[5])/ (60*times)

    littleRoof.littleRoof_Old_1 = self.m_roofBeginPos[1]
    littleRoof.littleRoof_Old_2 = self.m_roofBeginPos[2]
    littleRoof.littleRoof_Old_3 = self.m_roofBeginPos[3]
    littleRoof.littleRoof_Old_4 = self.m_roofBeginPos[4]
    littleRoof.littleRoof_Old_5 = self.m_roofBeginPos[5]


    local topTiao = {}
    topTiao.topTiao_add_1 = (self.m_topTiaoMaxPos[1] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_2 = (self.m_topTiaoMaxPos[2] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_3 = (self.m_topTiaoMaxPos[3] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_4 = (self.m_topTiaoMaxPos[4] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_5 = (self.m_topTiaoMaxPos[5] - self.m_topTiaoBeginPos)/ (60*times)

    topTiao.topTiao_Old_5 = self.m_topTiaoBeginPos
    topTiao.topTiao_Old_4 = self.m_topTiaoBeginPos
    topTiao.topTiao_Old_3 = self.m_topTiaoBeginPos
    topTiao.topTiao_Old_2 = self.m_topTiaoBeginPos
    topTiao.topTiao_Old_1 = self.m_topTiaoBeginPos

    local topTiao_1 = {}
    topTiao_1.topTiao_1_add_1 = (self.m_topTiaoMaxPos[1] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_2 = (self.m_topTiaoMaxPos[2] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_3 = (self.m_topTiaoMaxPos[3] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_4 = (self.m_topTiaoMaxPos[4] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_5 = (self.m_topTiaoMaxPos[5] - self.m_topTiaoBeginPos)/ (60*times)

    topTiao_1.topTiao_1_Old_5 = self.m_topTiaoBeginPos + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_4 = self.m_topTiaoBeginPos + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_3 = self.m_topTiaoBeginPos + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_2 = self.m_topTiaoBeginPos + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_1 = self.m_topTiaoBeginPos + self.m_topTiaoAddPos


    local reesAdd = {}
    reesAdd.reel_add_1 = (maxPercent - self.m_normalReelPercent[1])/ (60*times)
    reesAdd.reel_add_2 = (maxPercent - self.m_normalReelPercent[2])/ (60*times)
    reesAdd.reel_add_3 = (maxPercent - self.m_normalReelPercent[3])/ (60*times)
    reesAdd.reel_add_4 = (maxPercent - self.m_normalReelPercent[4])/ (60*times)
    reesAdd.reel_add_5 = (maxPercent - self.m_normalReelPercent[5])/ (60*times)
    
    reesAdd.reel_Old_1 = self.m_normalReelPercent[1]
    reesAdd.reel_Old_2 = self.m_normalReelPercent[2]
    reesAdd.reel_Old_3 = self.m_normalReelPercent[3]
    reesAdd.reel_Old_4 = self.m_normalReelPercent[4]
    reesAdd.reel_Old_5 = self.m_normalReelPercent[5]

    local reesInAdd = {}
    reesInAdd.reesIn_add_1 = (maxPercent - self.m_normalReelPercent[2])/ (60*times)
    reesInAdd.reesIn_add_2 = (maxPercent - self.m_normalReelPercent[3])/ (60*times)
    reesInAdd.reesIn_add_3 = (maxPercent - self.m_normalReelPercent[4])/ (60*times)
    reesInAdd.reesIn_add_4 = (maxPercent - self.m_normalReelPercent[5])/ (60*times)
    reesInAdd.reesIn_Old_1 = self.m_normalReelPercent[2]
    reesInAdd.reesIn_Old_2 = self.m_normalReelPercent[3]
    reesInAdd.reesIn_Old_3 = self.m_normalReelPercent[4]
    reesInAdd.reesIn_Old_4 = self.m_normalReelPercent[5]



    local reel_right = {}
    local reel_right_percent = 43
    reel_right.reel_right_add = (maxPercent - reel_right_percent)/ (60*times)
    reel_right.reel_right_Old =reel_right_percent

    


    self.m_reelsBgActionHandlerID = scheduler.scheduleUpdateGlobal(function()

        local isAllEnd = true


        if updateFunc then
            isAllEnd = updateFunc(times)
        end
        -- 小屋檐
        local FatherNodeName = {"roof1","roof12","roof13","roof14","roof15",}
        for i=1,5 do
            local littlRoof = self:findChild(FatherNodeName[i])
            local newPosY =  littlRoof:getPositionY()
            if newPosY < self.m_roofMaxPos[i] then
                littleRoof["littleRoof_Old_"..i] = littleRoof["littleRoof_Old_"..i] + littleRoof["littleRoof_add_"..i]
                littlRoof:setPositionY(littleRoof["littleRoof_Old_"..i])

                isAllEnd = false

            elseif newPosY > self.m_roofMaxPos[i] then

                littlRoof:setPositionY(self.m_roofMaxPos[i] )
                isAllEnd = false

            end
        end


        -- 顶部条1
        for i=1,5 do
            local topTiaoImg = self:findChild("Puss_rl_top2_"..i)
            local newPosY =  topTiaoImg:getPositionY()
            if newPosY < (self.m_topTiaoMaxPos[i]) then
                topTiao["topTiao_Old_"..i] = topTiao["topTiao_Old_"..i]  + topTiao["topTiao_add_"..i]
                topTiaoImg:setPositionY(topTiao["topTiao_Old_"..i])

                isAllEnd = false

            elseif newPosY > self.m_topTiaoMaxPos[i] then

                topTiaoImg:setPositionY(self.m_topTiaoMaxPos[i] )
                isAllEnd = false

            end
        end

        -- 顶部条2
        for i=1,5 do
            local topTiaoImg_1 = self:findChild("Puss_rl_top_"..i)
            local newPosY =  topTiaoImg_1:getPositionY()
            if newPosY < (self.m_topTiaoMaxPos[i]+ self.m_topTiaoAddPos) then
                topTiao_1["topTiao_1_Old_"..i] = topTiao_1["topTiao_1_Old_"..i]  + topTiao_1["topTiao_1_add_"..i]
                topTiaoImg_1:setPositionY(topTiao_1["topTiao_1_Old_"..i])

                isAllEnd = false

            elseif newPosY > (self.m_topTiaoMaxPos[i]+ self.m_topTiaoAddPos) then

                topTiaoImg_1:setPositionY(self.m_topTiaoMaxPos[i] + self.m_topTiaoAddPos )
                isAllEnd = false
            end
        end

        -- 背景条
        for i=1,5 do
            local reelBG = self:findChild("reel_"..(i -1))
            local newPercent =  reelBG:getPercent()
            if newPercent < maxPercent then
                reesAdd["reel_Old_"..i] = reesAdd["reel_Old_"..i] + reesAdd["reel_add_"..i]
                reelBG:setPercent(reesAdd["reel_Old_"..i])
                isAllEnd = false
            elseif newPercent > maxPercent then

                reelBG:setPositionY(maxPercent )
                isAllEnd = false
            end
        end


        -- 背景线
        for i=1,4 do
            local reel_in_lines = self:findChild("reel_in"..i )
            local newLinesPercent =  reel_in_lines:getPercent()
            if newLinesPercent < maxPercent then
                reesInAdd["reesIn_Old_"..i] = reesInAdd["reesIn_Old_"..i] + reesInAdd["reesIn_add_"..i]
                reel_in_lines:setPercent(reesInAdd["reesIn_Old_"..i])
                isAllEnd = false
            elseif newLinesPercent > maxPercent then

                reel_in_lines:setPositionY(maxPercent )
                isAllEnd = false
            end
        end

        -- 最右侧背景线
        local reel_right_lines = self:findChild("reel_right")
        local newLinesPercent =  reel_right_lines:getPercent()
        if newLinesPercent < maxPercent then
            reel_right.reel_right_Old = reel_right.reel_right_Old + reel_right.reel_right_add
            reel_right_lines:setPercent(reel_right.reel_right_Old)
            isAllEnd = false
        elseif newLinesPercent > maxPercent then

            reel_right_lines:setPositionY(maxPercent )
            isAllEnd = false
        end

        local reel_Dark_BG = self:findChild("Image_1")
        
        

        if isAllEnd then
            if self.m_reelsBgActionHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_reelsBgActionHandlerID)
                self.m_reelsBgActionHandlerID = nil
            end

            if endfunc then
                endfunc()
            end
        end
    
    end)


    


end

-- 播放轮盘元素动画
function CodeGameScreenPussMachine:reelsBgActionToFive(times,endfunc,updateFunc)
    
    local maxPercent = 100

    if times == 0 then
        times = 1/60
    end

    local littleRoof = {}
    littleRoof.littleRoof_add_1 = (self.m_roofMaxPos[1] - self.m_roofBeginPos[1])/ (60*times)
    littleRoof.littleRoof_add_2 = (self.m_roofMaxPos[2] - self.m_roofBeginPos[2])/ (60*times)
    littleRoof.littleRoof_add_3 = (self.m_roofMaxPos[3] - self.m_roofBeginPos[3])/ (60*times)
    littleRoof.littleRoof_add_4 = (self.m_roofMaxPos[4] - self.m_roofBeginPos[4])/ (60*times)
    littleRoof.littleRoof_add_5 = (self.m_roofMaxPos[5] - self.m_roofBeginPos[5])/ (60*times)

    littleRoof.littleRoof_Old_1 = self.m_roofMaxPos[1]
    littleRoof.littleRoof_Old_2 = self.m_roofMaxPos[2]
    littleRoof.littleRoof_Old_3 = self.m_roofMaxPos[3]
    littleRoof.littleRoof_Old_4 = self.m_roofMaxPos[4]
    littleRoof.littleRoof_Old_5 = self.m_roofMaxPos[5]


    local topTiao = {}
    topTiao.topTiao_add_1 = (self.m_topTiaoMaxPos[1] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_2 = (self.m_topTiaoMaxPos[2] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_3 = (self.m_topTiaoMaxPos[3] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_4 = (self.m_topTiaoMaxPos[4] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao.topTiao_add_5 = (self.m_topTiaoMaxPos[5] - self.m_topTiaoBeginPos)/ (60*times)

    topTiao.topTiao_Old_5 = self.m_topTiaoMaxPos[5]
    topTiao.topTiao_Old_4 = self.m_topTiaoMaxPos[4]
    topTiao.topTiao_Old_3 = self.m_topTiaoMaxPos[3]
    topTiao.topTiao_Old_2 = self.m_topTiaoMaxPos[2]
    topTiao.topTiao_Old_1 = self.m_topTiaoMaxPos[1]

    local topTiao_1 = {}
    topTiao_1.topTiao_1_add_1 = (self.m_topTiaoMaxPos[1] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_2 = (self.m_topTiaoMaxPos[2] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_3 = (self.m_topTiaoMaxPos[3] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_4 = (self.m_topTiaoMaxPos[4] - self.m_topTiaoBeginPos)/ (60*times)
    topTiao_1.topTiao_1_add_5 = (self.m_topTiaoMaxPos[5] - self.m_topTiaoBeginPos)/ (60*times)

    topTiao_1.topTiao_1_Old_5 = self.m_topTiaoMaxPos[5] + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_4 = self.m_topTiaoMaxPos[4] + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_3 = self.m_topTiaoMaxPos[3] + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_2 = self.m_topTiaoMaxPos[2] + self.m_topTiaoAddPos
    topTiao_1.topTiao_1_Old_1 = self.m_topTiaoMaxPos[1] + self.m_topTiaoAddPos




    local reesAdd = {}
    reesAdd.reel_add_1 = (maxPercent - self.m_normalReelPercent[1])/ (60*times)
    reesAdd.reel_add_2 = (maxPercent - self.m_normalReelPercent[2])/ (60*times)
    reesAdd.reel_add_3 = (maxPercent - self.m_normalReelPercent[3])/ (60*times)
    reesAdd.reel_add_4 = (maxPercent - self.m_normalReelPercent[4])/ (60*times)
    reesAdd.reel_add_5 = (maxPercent - self.m_normalReelPercent[5])/ (60*times)
    
    reesAdd.reel_Old_1 = maxPercent
    reesAdd.reel_Old_2 = maxPercent
    reesAdd.reel_Old_3 = maxPercent
    reesAdd.reel_Old_4 = maxPercent
    reesAdd.reel_Old_5 = maxPercent

    local reesInAdd = {}
    reesInAdd.reesIn_add_1 = (maxPercent - self.m_normalReelPercent[2])/ (60*times)
    reesInAdd.reesIn_add_2 = (maxPercent - self.m_normalReelPercent[3])/ (60*times)
    reesInAdd.reesIn_add_3 = (maxPercent - self.m_normalReelPercent[4])/ (60*times)
    reesInAdd.reesIn_add_4 = (maxPercent - self.m_normalReelPercent[5])/ (60*times)
    reesInAdd.reesIn_Old_1 = maxPercent
    reesInAdd.reesIn_Old_2 = maxPercent
    reesInAdd.reesIn_Old_3 = maxPercent
    reesInAdd.reesIn_Old_4 = maxPercent



    local reel_right = {}
    local reel_right_percent = 43
    reel_right.reel_right_add = (maxPercent - reel_right_percent)/ (60*times)
    reel_right.reel_right_Old = maxPercent

    


    self.m_reelsBgActionHandlerID = scheduler.scheduleUpdateGlobal(function()

        local isAllEnd = true


        if updateFunc then
            isAllEnd = updateFunc(times)
        end
        -- 小屋檐
        local FatherNodeName = {"roof1","roof12","roof13","roof14","roof15",}
        for i=1,5 do
            local littlRoof = self:findChild(FatherNodeName[i])
            local newPosY =  littlRoof:getPositionY()
            if newPosY > self.m_roofBeginPos[i] then
                littleRoof["littleRoof_Old_"..i] = littleRoof["littleRoof_Old_"..i] - littleRoof["littleRoof_add_"..i]
                littlRoof:setPositionY(littleRoof["littleRoof_Old_"..i])

                isAllEnd = false

            elseif newPosY < self.m_roofBeginPos[i] then

                littlRoof:setPositionY(self.m_roofBeginPos[i] )
                isAllEnd = false

            end
        end


        -- 顶部条1
        for i=1,5 do
            local topTiaoImg = self:findChild("Puss_rl_top2_"..i)
            local newPosY =  topTiaoImg:getPositionY()
            if newPosY > self.m_topTiaoBeginPos then
                topTiao["topTiao_Old_"..i] = topTiao["topTiao_Old_"..i]  - topTiao["topTiao_add_"..i]
                topTiaoImg:setPositionY(topTiao["topTiao_Old_"..i])

                isAllEnd = false

            elseif newPosY < self.m_topTiaoBeginPos then

                topTiaoImg:setPositionY(self.m_topTiaoBeginPos)
                isAllEnd = false

            end
        end

        -- 顶部条2
        for i=1,5 do
            local topTiaoImg_1 = self:findChild("Puss_rl_top_"..i)
            local newPosY =  topTiaoImg_1:getPositionY()
            if newPosY > (self.m_topTiaoBeginPos + self.m_topTiaoAddPos ) then
                topTiao_1["topTiao_1_Old_"..i] = topTiao_1["topTiao_1_Old_"..i]  - topTiao_1["topTiao_1_add_"..i]
                topTiaoImg_1:setPositionY(topTiao_1["topTiao_1_Old_"..i])

                isAllEnd = false

            elseif newPosY < (self.m_topTiaoBeginPos + self.m_topTiaoAddPos ) then

                topTiaoImg_1:setPositionY(self.m_topTiaoBeginPos+ self.m_topTiaoAddPos )
                isAllEnd = false
            end
        end

        -- 背景条
        for i=1,5 do
            local reelBG = self:findChild("reel_"..(i -1))
            local newPercent =  reelBG:getPercent()
            if newPercent > self.m_normalReelPercent[i] then
                reesAdd["reel_Old_"..i] = reesAdd["reel_Old_"..i] - reesAdd["reel_add_"..i]
                reelBG:setPercent(reesAdd["reel_Old_"..i])
                isAllEnd = false
            elseif newPercent < self.m_normalReelPercent[i] then

                reelBG:setPositionY(self.m_normalReelPercent[i] )
                isAllEnd = false
            end
        end


        -- 背景线
        for i=1,4 do
            local reel_in_lines = self:findChild("reel_in"..i )
            local newLinesPercent =  reel_in_lines:getPercent()
            if newLinesPercent > self.m_normalReelPercent[i+1] then
                reesInAdd["reesIn_Old_"..i] = reesInAdd["reesIn_Old_"..i] - reesInAdd["reesIn_add_"..i]
                reel_in_lines:setPercent(reesInAdd["reesIn_Old_"..i])
                isAllEnd = false
            elseif newLinesPercent < self.m_normalReelPercent[i+1] then

                reel_in_lines:setPositionY(self.m_normalReelPercent[i+1] )
                isAllEnd = false
            end
        end

        -- 最右侧背景线
        local reel_right_lines = self:findChild("reel_right")
        local newLinesPercent =  reel_right_lines:getPercent()
        if newLinesPercent > reel_right_percent then
            reel_right.reel_right_Old = reel_right.reel_right_Old - reel_right.reel_right_add
            reel_right_lines:setPercent(reel_right.reel_right_Old)
            isAllEnd = false
        elseif newLinesPercent < reel_right_percent then

            reel_right_lines:setPositionY(reel_right_percent )
            isAllEnd = false
        end

        local reel_Dark_BG = self:findChild("Image_1")
        
        

        if isAllEnd then
            if self.m_reelsBgActionHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_reelsBgActionHandlerID)
                self.m_reelsBgActionHandlerID = nil
            end

            if endfunc then
                endfunc()
            end
        end
    
    end)


    


end

---
--设置bonus scatter 层级
function CodeGameScreenPussMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1
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

-- 处理特殊关卡 遮罩层级
function CodeGameScreenPussMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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

function CodeGameScreenPussMachine:slotReelDown( )
    BaseFastMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
      
end

--freespin下主轮调用父类停止函数
function CodeGameScreenPussMachine:slotReelDownInFS( )
    self:setGameSpinStage( STOP_RUN )
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
    self:reelDownNotifyPlayGameEffect( )
end


function CodeGameScreenPussMachine:playEffectNotifyNextSpinCall( )


    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if (self:getCurrSpinMode() == AUTO_SPIN_MODE or 
    self:getCurrSpinMode() == FREE_SPIN_MODE) and self.m_bIsInClassicGame ~= true  then
        
        local delayTime = 0.5
       
        if self:isSevenRowsFreespin(  ) then
            
            local lines = self.m_SevenRowReels:getResultLines()
        
            if lines ~= nil and #lines > 0 then
                
                delayTime = delayTime + self:getWinCoinTime()
                if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
                    if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                        delayTime = 0.5
                    end
                end
            end

        else
            if self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0 then
                delayTime = delayTime + self:getWinCoinTime()
            end
        end

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end
    
end

function CodeGameScreenPussMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or (self.m_fsReelDataIndex > 0 and spinData.action == "FEATURE") then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        if self:isSevenRowsFreespin(  ) then
                
            if spinData.result.selfData ~= nil  and spinData.result.selfData.free ~= nil then
                local resultDatas = spinData.result.selfData.free
                resultDatas.bet = spinData.result.bet
                resultDatas.payLineCount = 100 -- 暂时写死，正常应该是服务器传这个值
                resultDatas.action = spinData.result.action -- "NORMAL"
                self.m_SevenRowReels:netWorkCallFun(resultDatas)
                self.m_SevenRowReels.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果

                
            end
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenPussMachine:updateNetWorkData()

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

    -- 网络消息已经赋值成功开始进行击剑飞wild的判断逻辑
    self:netBackCheckAddAction( )
    
end

function CodeGameScreenPussMachine:FencingFlyWildAction(catWildPositions )

    -- 猫击剑

    self:findChild("cat"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
    gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Down_And_HuiJina.mp3")
    util_spinePlay(self.m_cat,"actionframe")

    util_spineFrameCallFunc(self.m_cat, "actionframe", "jump1", function(  )
        
        self:catJumpDown()

        util_spineFrameCallFunc(self.m_cat, "actionframe", "Show1", function(  )
        
            gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Fly_to_WIld.mp3")
    
        
            -- 飞wild
            -- 初始化wild信号
            local flyWildList =  self:initFlyWild( catWildPositions)
            self:runFlyWildAct( flyWildList,function(  )
    
                self:netBackReelsStop( )
                
            end)
    
        end,function(  )
            if not self:isSevenRowsFreespin(  )  then
                self:findChild("cat"):setLocalZOrder(-1)
                gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Back.mp3")
                -- 猫回去
                util_spinePlay(self.m_cat,"actionframe2")
                self:findChild("cat"):setPosition(self.m_midCatJumpPos)
                util_spineEndCallFunc(self.m_cat, "actionframe2", function(  )
                    util_spinePlay(self.m_cat,"idleframe",true)
                end)
            end
            
        end)
       
    end)


    

    
    
    


end

function CodeGameScreenPussMachine:runFlyWildAct( flyWildList,func)

    for i=1,#flyWildList do
        local endNode = flyWildList[i]

        local flytime = 1
        -- 创建粒子
        local flyLizi =  util_createAnimation("Socre_Puss_fly_lizi.csb")
        self.m_root:addChild(flyLizi,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)
        flyLizi:findChild("Particle_1"):setDuration(flytime)
        flyLizi:findChild("Particle_1"):setPositionType(0)
        flyLizi:setPosition(cc.p(150,340))

        local liziWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(endNode:getPosition()))
        local liziPos = self:findChild("root"):convertToNodeSpace(cc.p(liziWorldPos))
        local endPos = cc.p(liziPos)

        self:flySpecialNode(flyLizi,cc.p(150,340),endPos,flytime,function(  )
            local flyLiziBaoZha =  util_createAnimation("Socre_Puss_Symbol_baozha.csb")
            self.m_root:addChild(flyLiziBaoZha,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
            local liziBaoZhaWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(endNode:getPosition()))
            local lizibaozhaPos = self:findChild("root"):convertToNodeSpace(cc.p(liziBaoZhaWorldPos))
            flyLiziBaoZha:setPosition(cc.p(lizibaozhaPos))
            flyLiziBaoZha:playAction("actionframe",false,function(  )
                if i == 1 then
                    if func then
                        func()
                    end
                end
    
                flyLiziBaoZha:removeFromParent()
                flyLizi:removeFromParent()
            end)

            local endWild = endNode
            performWithDelay(flyLiziBaoZha,function(  )
                endWild:setVisible(true)
            end,0.1)
        end)


    end
    
end

function CodeGameScreenPussMachine:changeFlyWildList( )
    
    for k,node in pairs(self.m_flyWildList) do
        local name = node:getName()
        local oldNode = self.m_clipParent:getChildByName(name)
        if oldNode then
            self.m_flyWildList[k] = oldNode
        end
    end
end

function CodeGameScreenPussMachine:removeFlyWild( )
    
    for i=1,#self.m_flyWildList do
        local wild = self.m_flyWildList[i]
        if wild then
            wild:removeFromParent()
            local linePos = {}
            wild.m_bInLine = false
            wild:setLinePos(linePos)
            wild:setName("")
            local symbolType = wild.p_symbolType
            self:pushSlotNodeToPoolBySymobolType(symbolType, wild)
        end
    end

    self.m_flyWildList = {}
end

function CodeGameScreenPussMachine:restFlyWild( )
    
    for i=1,#self.m_flyWildList do
        local wild = self.m_flyWildList[i]
        if wild then
            local linePos = {}
            wild.m_bInLine = false
            wild:setLinePos(linePos)
            wild:setName("")
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
    end

    self.m_flyWildList = {}
end

function CodeGameScreenPussMachine:initFlyWild( catWildPositions)

    
    self.m_flyWildList = {}

    for i=1,#catWildPositions do
        local endPos = catWildPositions[i]
        local v = endPos
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY, false)   

        if targSp  then -- and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD

            targSp:setName("baseFlyWild_"..i)
            targSp:setVisible(false)

            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
            self.m_clipParent:addChild(targSp,  SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1 , SYMBOL_NODE_TAG)
            local position =  self:getBaseReelsTarSpPos(pos )
            targSp:setPosition(cc.p(position))

            table.insert( self.m_flyWildList, targSp )
        end

    end


    return self.m_flyWildList
end

function CodeGameScreenPussMachine:freespinFencingFlyWildAction(catWildPositions )

    -- 猫击剑
    self:findChild("cat"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 502)
    util_spinePlay(self.m_cat,"actionframe3")
    
    gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Left_And_HuiJina.mp3")
    

    

    util_spineFrameCallFunc(self.m_cat, "actionframe3", "Show2", function(  )
        
        gLobalSoundManager:playSound("PussSounds/music_Puss_Cat_Fly_to_WIld.mp3")
        -- 飞wild
        -- 初始化wild信号
        local flyWildList =  self.m_SevenRowReels:initFlyWild( catWildPositions)
        self.m_SevenRowReels:runFlyWildAct( flyWildList,function(  )

            self.m_SevenRowReels:netBackReelsStop( )
            self:netBackReelsStop( )
            
        end)

    end)
    
    


end

function CodeGameScreenPussMachine:netBackCheckAddAction( )
    

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local catWildPositions =  selfData.catWildPositions or {}
    if catWildPositions and #catWildPositions > 0  then

        if self:isSevenRowsFreespin(  ) then
            -- 开始播放Freespin轮盘猫击剑⚔
            self:freespinFencingFlyWildAction(catWildPositions )
        else
            -- 开始播放普通轮盘猫击剑⚔
            self:FencingFlyWildAction(catWildPositions )
        end
        

    else

        if self:isSevenRowsFreespin(  ) then
            self.m_SevenRowReels:netBackReelsStop( )
        end
        self:netBackReelsStop( )

    end


    
end


function CodeGameScreenPussMachine:netBackReelsStop( )

    

    self.m_isWaitChangeReel=nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenPussMachine:getBaseReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenPussMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end


---
-- 显示bonus 触发的小游戏
function CodeGameScreenPussMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusMode
    if bonusTypes then

        if bonusTypes == "collect"  then
            
            if not self.m_triggerShowMap  then
                local progress = 0
                if progress then
                    self.m_CollectBar.m_Progress:setPercent(progress)
                end
                 
            end
        end
    end

    self.m_baseFreeSpinBar:setVisible(false)

    self.isInBonus = true

    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:changeFlyWildList()
    self:removeFlyWild()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTypes =  selfdata.bonusMode


    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    if bonusTypes and bonusTypes == "select" then
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                bonusLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end


        local time = 1
        local changeNum = 1/(time * 60) 
        local curvolume = 1
        self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
            curvolume = curvolume - changeNum
            if curvolume <= 0 then

                curvolume = 0

                if self.m_updateBgMusicHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
                    self.m_updateBgMusicHandlerID = nil
                end
            end

            gLobalSoundManager:setBackgroundMusicVolume(curvolume)
        end)

        

        performWithDelay(self,function(  )

            -- 停止播放背景音乐
            self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
            -- 播放bonus 元素不显示连线
            if bonusLineValue ~= nil then

                self:showBonusAndScatterLineTip(bonusLineValue,function()
                    performWithDelay(self,function(  )
                        self:showBonusGameView(effectData)
                    end,0.5)
                    
                end)
                bonusLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
        
                -- 播放提示时播放音效        
                self:playBonusTipMusicEffect()

            else
                self:showBonusGameView(effectData)
            end

            
           
        end,time)
        
        
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end
---
-- 根据Bonus Game 每关做的处理
--

function CodeGameScreenPussMachine:showBonusGameView( effectData )
   

        if self.m_updateBgMusicHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
            self.m_updateBgMusicHandlerID = nil
        end


        self.m_bottomUI:checkClearWinLabel()

    
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusTypes =  selfdata.bonusMode
        if bonusTypes then

            if bonusTypes == "select"  then
                self:show_Choose_BonusGameView(effectData)

            else

                if self.m_triggerShowMap  then

                    

                    self:showMapView(function(  )
                        self:show_Map_BonusGameView(effectData)
                    end)

                    self.m_triggerShowMap = false

                else
                    self:show_Map_BonusGameView(effectData)
                end  

                
            end
        end


end

function CodeGameScreenPussMachine:classicSlotOverView(winCoin, effectData)


    gLobalSoundManager:playSound("PussSounds/music_Puss_Respin_OverView.mp3")

    local view = self:showLocalDialog("ClassicOver", nil,function()

        local progress = 0

        if progress then
            self.m_CollectBar.m_Progress:setPercent(progress)
        end

        performWithDelay(self,function(  )
            self.m_classicMachine:removeFromParent()
            self.m_classicMachine = nil
            self.m_bottomUI:hideAverageBet()
            self:updateBaseConfig()
            self:initSymbolCCbNames()
            self:initMachineData()

            -- globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            -- globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
            self.m_bIsInClassicGame = false
            if effectData ~= nil then
                effectData.p_isPlay = true
            end
            self:playGameEffect()
            self:resetMusicBg()
        end,0)
            

    end)
    local node=view:findChild("m_lb_coins")
    node:setString(util_formatCoins(winCoin, 50))
    view:updateLabelSize({label=node,sx=1,sy=1},592)
end

function CodeGameScreenPussMachine:show_Map_BonusGameView(effectData )

    self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.node
    local gameType = self.m_bonusPath[self.m_nodePos]
    if gameType == 0 then
        
        performWithDelay(self, function()
            gLobalSoundManager:playSound("PussSounds/music_Puss_fsView.mp3")
            self:showLocalDialog("ClassicStart", nil,function()
                local data = {}
                data.parent = self
                data.paytable = self.m_runSpinResultData.p_selfMakeData.classicWinCoins
                data.effectData = effectData
                local uiW, uiH = self.m_topUI:getUISize()
                local uiBW, uiBH = self.m_bottomUI:getUISize()
                data.height = uiH + uiBH

                self.m_classicMachine = util_createView("CodePussSrc.Classic.GameScreenClassicSlots" , data)
                self:addChild(self.m_classicMachine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
                self.m_bottomUI:showAverageBet()
                self:clearWinLineEffect()
                self:resetMaskLayerNodes()
                if globalData.slotRunData.machineData.p_portraitFlag then
                    self.m_classicMachine.getRotateBackScaleFlag = function(  ) return false end
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_classicMachine})
            end)
        end, 1)
        
        
    else
        self.m_fsReelDataIndex = gameType
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalSoundManager:playSound("PussSounds/music_Puss_fsView.mp3")

        local view = self:showLocalDialog("SuperFreeSpinStart", nil,function()

            globalData.slotRunData.lastWinCoin = 0
            self.m_bottomUI:checkClearWinLabel()
            self.m_bottomUI:showAverageBet()

            
            -- 调用此函数才是把当前游戏置为freespin状态
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()

            if self.m_nodePos == #self.m_bonusPath then
                
            end

        end)

        view:findChild("m_lb_num"):setString(globalData.slotRunData.totalFreeSpinCount)
        view:findChild("Puss_MiniGame_1"):setVisible(false)
        view:findChild("Puss_MiniGame_2"):setVisible(false)
        view:findChild("Puss_MiniGame_3"):setVisible(false)
        view:findChild("Puss_MiniGame_4"):setVisible(false)
        view:findChild("Puss_MiniGame_"..self.m_fsReelDataIndex):setVisible(true)

        -- local csb_path = "Puss_MiniGame_tower" .. self.m_fsReelDataIndex ..".csb"
        -- local icon =  util_createAnimation(csb_path)
        -- icon:playAction("unlock")
        -- view:findChild("iconNode"):addChild(icon)
        

    end
        


end

function CodeGameScreenPussMachine:bonusOverAddFreespinEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

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

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end



function CodeGameScreenPussMachine:show_Choose_BonusGameView(effectData)
    

    gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView.mp3")

    local chooseView = util_createView("CodePussSrc.PussChooseView",self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        chooseView.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(chooseView)
    -- chooseView:setPosition(cc.p(-display.width/2,-display.height/2))

    chooseView:setEndCall( function( selectId ) 

        if selectId == selectRespinId then
            self.m_iFreeSpinTimes = 0 
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0      
            self.m_bProduceSlots_InFreeSpin = false

            self.m_choiceTriggerRespin  = true
            self.m_chooseRepin = true
            self.m_chooseRepinGame = true --选择respin
            self.m_chooseRepinNotCollect = true

            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        else
            self:bonusOverAddFreespinEffect( )
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
            
        end
        

        if chooseView then
            chooseView:removeFromParent()
        end


        
    end)

    
    
end



function CodeGameScreenPussMachine:setTopUiVisible( states)
    self.m_LogoView:setVisible(states)
    self.m_BigRoofView:setVisible(states)
    self.m_CollectBar:setVisible(states)
end

function CodeGameScreenPussMachine:isSevenRowsFreespin(  )
    local selfData =  self.m_runSpinResultData.p_selfMakeData or {}
    local freespinType = selfData.freespinType

    local isTrue = false
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE  then
        local features =  self.m_runSpinResultData.p_features
        local freeSpinsLeftCount =  self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount =  self.m_runSpinResultData.p_freeSpinsTotalCount
        -- 这种判断说明是同时触发的情况  选择的freespin结束并且收集的freespin触发
        if features and features[2] and features[2] == 5 then
            if freeSpinsLeftCount and freeSpinsTotalCount  then
                if freeSpinsLeftCount == freeSpinsTotalCount then

                    if globalData.slotRunData.freeSpinCount == 0 then
                        isTrue = true
                        return isTrue
                    end
                    
                end
            end
            
            
        end
        if freespinType == "select" then
            isTrue = true
        end
    end

    return isTrue
end

---
-- 根据类型获取对应节点
--
function CodeGameScreenPussMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeBySymbolType(self,symbolType)
    reelNode:initMachine(self )
    return reelNode
end

--小块
function CodeGameScreenPussMachine:getBaseReelGridNode()
    return "CodePussSrc.PussSlotsNode"
end


--node飞行的图片或者粒子,startPos开始坐标,endPos停止坐标,flyTime飞行时间,func结束回调
function CodeGameScreenPussMachine:flySpecialNode(node,startPos,endPos,flyTime,func)
    if not node then
        return
    end
    if not flyTime then
        flyTime = 1
    end
    local actionList = {}
    local tempPos = cc.p(startPos.x+100+endPos.x*0.1,startPos.y+400+endPos.y*0.1)
    local bez1=cc.BezierTo:create(flyTime*0.5,{cc.p(startPos.x+500,startPos.y),cc.p(startPos.x+300,tempPos.y),tempPos})
    actionList[#actionList + 1] = bez1
    local bez2=cc.BezierTo:create(flyTime*0.5,{cc.p(tempPos.x-300,(startPos.y+tempPos.y)*0.5),cc.p(tempPos.x-100,(startPos.y+tempPos.y)*0.5),endPos})
    actionList[#actionList + 1] = bez2
    if func then
        actionList[#actionList + 1] = cc.CallFunc:create(func)
    end
    node:runAction(cc.Sequence:create(actionList))
end


---
--判断改变freespin的状态
function CodeGameScreenPussMachine:changeFreeSpinModeStatus()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER

                for i=#self.m_vecSymbolEffectType,1,-1 do
                    local EffectType = self.m_vecSymbolEffectType[i]
                    if EffectType == GameEffect.EFFECT_BONUS then
                        table.remove( self.m_vecSymbolEffectType, i)
                    end
                end
            end
        end

    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
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
function CodeGameScreenPussMachine:checkTriggerINFreeSpin( )
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    if hasFreepinFeature == false and 
            self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
            self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or 
                (hasReSpinFeature == true  or hasBonusFeature == true)) then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs then
        if self.m_initSpinData.p_freeSpinsTotalCount > 0 and self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            if self.m_initSpinData.p_selfMakeData.bonusMode ~= "select" then
                isInFs = false
            end
        end

        if self.m_initSpinData.p_freeSpinsTotalCount == self.m_initSpinData.p_freeSpinsLeftCount then
            if self.m_initSpinData.p_features and #self.m_initSpinData.p_features == 2 then
                if self.m_initSpinData.p_features[2] == 5 then
                    isInFs = false
                end
            end
        end

    end
    
    

    if isInFs == true then
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end

function CodeGameScreenPussMachine:checkShopShouldClick( )

    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    -- 返回true 不允许点击

    if self.m_isWaitingNetworkData  then
        return true

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return true

    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return true

    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then

        return true

    elseif self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        return true
    elseif #featureDatas > 1 then
        return true
    elseif self:getGameSpinStage( ) > IDLE then
        return true
    elseif self.m_isRunningEffect then
        return true
    end

    return false
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenPussMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end


local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenPussMachine:addLastWinSomeEffect() -- add big win or mega win

    if self:isSevenRowsFreespin(  ) then
        local lines = self.m_SevenRowReels:getVecGetLineInfo( )
        if #lines == 0 then
            return
        end
    else
        if #self.m_vecGetLineInfo == 0 then
            return
        end
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
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or
            self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or
            self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        
        self.m_SevenRowReels:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)

    end


end

function CodeGameScreenPussMachine:callSpinBtn()

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end
    end

    
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToAutospinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
            end
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE  then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToFreespinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
            end
        end
    end


    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    self:notifyClearBottomWinCoin()
   
    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if not self.m_choiceTriggerRespin and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        --金币不足
        -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
        gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
        -- cxc 2023-12-05 15:57:06 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        local checkOperaGuidePop = function()
            if tolua.isnull(self) then
                return
            end
            
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
                view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
            else
                self:showLuckyVedio()
            end
        end
        gLobalPushViewControl:setEndCallBack(checkOperaGuidePop)
       
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        end

    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
            self:getCurrSpinMode() ~= RESPIN_MODE and not self.m_choiceTriggerRespin
         then
            self:callSpinTakeOffBetCoin(betCoin)
            
        else
            self.m_spinNextLevel = globalData.userRunData.levelNum
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
            self.m_spinIsUpgrade = false
        end


        --统计quest spin次数
        self:staticsQuestSpinData()

        self:spinBtnEnProc()

        self:setGameSpinStage( GAME_MODE_ONE_RUN )

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()

    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end


function CodeGameScreenPussMachine:changeBetToUnlock( )

    if self:getBetLevel() then
        
 
         if self:getBetLevel() == 0 then
             self:setBetId( )
         end
 
    end 
     
 end

function CodeGameScreenPussMachine:setBetId( )

    local minBet = self:getMinBet()

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
            -- 大于等于
        if betData.p_totalBetValue >= minBet then

            globalData.slotRunData.iLastBetIdx =   betData.p_betId

            break
        end
    end

    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

end

function CodeGameScreenPussMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end


function CodeGameScreenPussMachine:createOneActionSymbol(endNode,actionName,str)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node= util_createAnimation(endNode.m_ccbName..".csb")
    node:findChild("m_lb_score"):setString(str)
    local func = function(  )
          if fatherNode then
                fatherNode:setVisible(true)
          end
          if node then
                node:removeFromParent()
          end
          
    end
    node:playAction(actionName,false,func)  

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self.m_root:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self.m_root:addChild(node , SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100 - endNode.p_rowIndex)
    node:setPosition(pos)

    return node
end


function CodeGameScreenPussMachine:isNormalBgShow(states )
    for i=1,5 do
        self:findChild("reel_reel_" .. (i - 1)):setVisible(states)
    end

    -- self:findChild("Puss_rl_botom2_7"):setVisible(not states)
    -- self:findChild("Puss_rl_top2"):setVisible(not states)
    
end

function CodeGameScreenPussMachine:catJumpDown( func)
    

    local pos = cc.p(self.m_downCatJumpPos.x - 200 ,self.m_downCatJumpPos.y)

    local jumpTimes = 0.5
    local actionList = {}
    actionList[#actionList + 1] = cc.JumpTo:create(jumpTimes, pos ,350,1)
    actionList[#actionList + 1] = cc.DelayTime:create(jumpTimes)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        
        if func then
            func()
        end
    end)
    local sq = cc.Sequence:create(actionList)
    self:findChild("cat"):runAction(sq)
    
end


function CodeGameScreenPussMachine:changePosLittleUIX( isFive )
    if display.height < FIT_HEIGHT_MIN then

        local freespinBar =  self:findChild("freespinBar")
        if freespinBar then
            if isFive then
                freespinBar:setPositionX(151.92)
            else
                freespinBar:setPositionX(151.92 - 60)
            end
            
        end

        local respinBar =  self:findChild("respinBar")
        if respinBar then
            if isFive then
                respinBar:setPositionX(127.92)
            else
                respinBar:setPositionX(127.92 - 60)
            end

        end

        local jackpot =  self:findChild("jackpot")
        if jackpot then
            if isFive then
                jackpot:setPositionX(384)
            else
                jackpot:setPositionX(384 - 3)
            end
            
        end

    elseif display.height > FIT_HEIGHT_MAX then

        if (display.height / display.width) >= 2 then
            
        else

            local freespinBar =  self:findChild("freespinBar")
            if freespinBar then
                if isFive then
                    freespinBar:setPositionX(151.92)
                else
                    freespinBar:setPositionX(151.92 - 30)
                end
                
            end

            local respinBar =  self:findChild("respinBar")
            if respinBar then
                if isFive then
                    respinBar:setPositionX(127.92)
                else
                    respinBar:setPositionX(127.92 - 30)
                end

            end

            local jackpot =  self:findChild("jackpot")
            if jackpot then
                if isFive then
                    jackpot:setPositionX(384)
                else
                    jackpot:setPositionX(384 - 30)
                end
                
            end
            
        end
        
    end
end




function CodeGameScreenPussMachine:initBottomUI()
    
    CodeGameScreenPussMachine.super.initBottomUI(self)

    local pos = cc.p(self.m_bottomUI:getWinFlyNode():getPosition()) 
    self.m_respinEndActiom =  util_createView("CodePussSrc.PussRespinAction")
    self.m_bottomUI:getWinFlyNode():getParent():addChild(self.m_respinEndActiom,99999)
    self.m_respinEndActiom:setPosition(cc.p(pos.x,pos.y - 25))
    self.m_respinEndActiom:setVisible(false)
end

function CodeGameScreenPussMachine:initRespinViewJackpotTip( )
    if self.m_respinView then

        local nameList = {"minor","major","grand"}
        for i=1,3 do

            local csbName = "Puss_jackpotfull_" .. nameList[i] 
            local name = nameList[i]
            self.m_respinView[name] = util_createAnimation(csbName .. ".csb") 
            self.m_respinView:addChild(self.m_respinView[name])
            if globalData.slotRunData.machineData.p_portraitFlag then
                self.m_respinView[name].getRotateBackScaleFlag = function(  ) return false end
            end

            
            local pos = util_getConvertNodePos( self:findChild("sp_reel_" .. (i + 1)) , self.m_respinView[name])
            self.m_respinView[name]:setPosition(pos)

            self.m_respinView[name]:setVisible(false)


        end
        
    end
end

function CodeGameScreenPussMachine:showJackPotTip( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackPotTipData = selfdata.jackpots

    if jackPotTipData and #jackPotTipData > 0 then

        for i=1,#jackPotTipData do
            local jpId = jackPotTipData[i]
            if jpId == "Minor" then

                self["m_LittleRoof_".. 3 ]:runCsbAction("actionframe",true)
                self.m_respinView["minor"]:setVisible(true)
                self.m_respinView["minor"]:playAction("actionframe",true)

            elseif jpId == "Major" then   

                self["m_LittleRoof_".. 4 ]:runCsbAction("actionframe",true)
                self.m_respinView["major"]:setVisible(true)
                self.m_respinView["major"]:playAction("actionframe",true)

            elseif jpId == "Grand" then 

                self["m_LittleRoof_".. 5 ]:runCsbAction("actionframe",true)
                self.m_respinView["grand"]:setVisible(true)
                self.m_respinView["grand"]:playAction("actionframe",true)

            end
        end
        
    end
end

function CodeGameScreenPussMachine:hideOneJackPotTip( jpId)


        if jpId == "Minor" then

            self["m_LittleRoof_".. 3 ]:runCsbAction("idle")
            self.m_respinView["minor"]:setVisible(false)
            self.m_respinView["minor"]:playAction("idle")

        elseif jpId == "Major" then   

            self["m_LittleRoof_".. 4 ]:runCsbAction("idle")
            self.m_respinView["major"]:setVisible(false)
            self.m_respinView["minor"]:playAction("idle")

        elseif jpId == "Grand" then 

            self["m_LittleRoof_".. 5 ]:runCsbAction("idle")
            self.m_respinView["grand"]:setVisible(false)
            self.m_respinView["minor"]:playAction("idle")

        end

        

end


function CodeGameScreenPussMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    
end

function CodeGameScreenPussMachine:specialSymbolActionTreatment(slotNode )

    local currslotNode = slotNode
    slotNode:runAnim("buling",false,function(  )
        currslotNode:resetReelStatus()
    end)

end

function CodeGameScreenPussMachine:setSlotNodeEffectParent(slotNode)
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
        local currslotNode = slotNode
        slotNode:runAnim("actionframe",false,function(  )
            currslotNode:resetReelStatus()
        end)
        -- slotNode:runLineAnim()
    end
    return slotNode
end

--隐藏盘面信息
function CodeGameScreenPussMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local ReelParent = self:getReelParent(iCol)
        if ReelParent then
            ReelParent:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            slotParentBig:setVisible(status)
        end
    end

    -- --如果为空则从 clipnode获取
    -- local childs = self.m_clipParent:getChildren()
    -- local childCount = #childs
    -- self.m_clipParent:setVisible(status)


    
end

function CodeGameScreenPussMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenPussMachine.super.dealSmallReelsSpinStates(self )

end

function CodeGameScreenPussMachine:requestSpinReusltData()
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
    if not self.m_chooseRepinGame  then
        if self:getCurrSpinMode() == RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false,true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Stop,false,true})
        end
    end
    

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function CodeGameScreenPussMachine:playEffectNotifyChangeSpinStatus( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Auto,true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Auto,true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                    self:normalSpinBtnCall()
                end, 0.5,self:getModuleName())
            end
        else
            if not self.m_chooseRepinGame  then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,true})
            end
            
        end
    end

   
end

---
-- 获取随机信号，  
-- @param col 列索引
function CodeGameScreenPussMachine:MachineRule_getRandomSymbol(col)

    local reelDatas = nil
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex,col)
        if reelDatas == nil then
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
        end
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(col)
    end
    if reelDatas == nil then
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(1)
    end

    local totalCount = #reelDatas
    local randomType = reelDatas[xcyy.SlotsUtil:getArc4Random() % totalCount + 1]
    
    return randomType
end

function CodeGameScreenPussMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenPussMachine.super.levelDeviceVibrate then
        CodeGameScreenPussMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenPussMachine






