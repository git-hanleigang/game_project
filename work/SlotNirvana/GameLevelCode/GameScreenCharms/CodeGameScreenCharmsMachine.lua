---
-- island li
-- 2019年1月26日
-- CodeGameScreenCharmsMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
-- local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlots = require "Levels.BaseSlots"
local CollectData = require "data.slotsdata.CollectData"
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenCharmsMachine = class("CodeGameScreenCharmsMachine", BaseSlotoManiaMachine)

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 新添respinNode状态
CodeGameScreenCharmsMachine.CHARMS_RESPIN_NODE_STATUS = {
    UnLOCK = 104, --未解锁 bunus锁定状态
    NUllLOCK = 105, --空信号 状态
    UPLOCK = 106 --解锁 状态
}

--lockView状态
CodeGameScreenCharmsMachine.CHARMS_LOCKVIEW_NODE_STATUS = {
    LOCKDNODE = -1, --已经解锁了
    LOCKNULL = 0 --空信号 状态

}

--respin中连续Jackpot后显示背景
-- UI位置由左到右
CodeGameScreenCharmsMachine.m_respinJackpotBgName = {"Node_Grand","Node_Major_1","Node_Major_2","Node_Minor_1","Node_Minor_2","Node_Minor_3"}
CodeGameScreenCharmsMachine.m_respinJackpotBgViewName = {"Grand","Major","Major","Minor","Minor","Minor"}
CodeGameScreenCharmsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCharmsMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenCharmsMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenCharmsMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenCharmsMachine.SYMBOL_FIX_SYMBOL_DOUBLE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenCharmsMachine.SYMBOL_FIX_SYMBOL_BOOM = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenCharmsMachine.SYMBOL_FIX_MINOR_DOUBLE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
CodeGameScreenCharmsMachine.SYMBOL_FIX_SYMBOL_NULL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
CodeGameScreenCharmsMachine.SYMBOL_FIX_SYMBOL_BOOM_RUN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6

CodeGameScreenCharmsMachine.SYMBOL_WILD_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20
CodeGameScreenCharmsMachine.SYMBOL_WILD_3X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21
CodeGameScreenCharmsMachine.SYMBOL_WILD_5X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22
CodeGameScreenCharmsMachine.SYMBOL_WILD_8X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23
CodeGameScreenCharmsMachine.SYMBOL_WILD_10X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24
CodeGameScreenCharmsMachine.SYMBOL_WILD_25X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 25
CodeGameScreenCharmsMachine.SYMBOL_WILD_100X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 26

CodeGameScreenCharmsMachine.FLY_COIN_TYPE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 40


CodeGameScreenCharmsMachine.SYMBOL_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
CodeGameScreenCharmsMachine.SYMBOL_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号

CodeGameScreenCharmsMachine.m_respinLittleNodeSize = 2
CodeGameScreenCharmsMachine.m_chipList = nil
CodeGameScreenCharmsMachine.m_playAnimIndex = 0
CodeGameScreenCharmsMachine.m_lightScore = 0
CodeGameScreenCharmsMachine.m_lockList = {}

CodeGameScreenCharmsMachine.m_respinJackPotTipNodeList = {}

CodeGameScreenCharmsMachine.m_BoomList = {}
CodeGameScreenCharmsMachine.m_FirList = {}
CodeGameScreenCharmsMachine.m_isPlayRespinEnd = false

CodeGameScreenCharmsMachine.m_BoomReelsView = nil

CodeGameScreenCharmsMachine.m_isFreespinStart = false

CodeGameScreenCharmsMachine.m_isInFreeGames = false

CodeGameScreenCharmsMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenCharmsMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1

CodeGameScreenCharmsMachine.m_bIsInClassicGame = nil
CodeGameScreenCharmsMachine.m_bIsInBonusFreeGame = nil

local FIT_HEIGHT_MAX = 1363
local FIT_HEIGHT_MIN = 1136

local RESPIN_ROW_COUNT = 6
local NORMAL_ROW_COUNT = 3
-- 构造函数
function CodeGameScreenCharmsMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_respinStopCount = 0

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self:initLockList()
    self.m_BoomList = {}
    self.m_FirList = {}
    self.respinJackPotTipNodeList = {}
    self:initRespinJackPotTipNodeList()

    self.m_isPlayWinningNotice = false
    self.m_isPlayRespinEnd = false
    self.m_isFreespinStart = false
    self.m_isInFreeGames = false

    self.m_actRsNode = {}
    self.m_currFeature = {}
    self.m_iBetLevel = 0

	--init
	self:initGame()
end

function CodeGameScreenCharmsMachine:initGame()


    self.m_configData = gLobalResManager:getCSVLevelConfigData("CharmsConfig.csv", "LevelCharmsConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenCharmsMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        if i <= 2 then
            soundPath = "CharmsSounds/Charms_scatter_down.mp3"
        elseif i > 2 and i < 5 then
            soundPath = "CharmsSounds/Charms_scatter_down2.mp3"
        else
            soundPath = "CharmsSounds/Charms_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenCharmsMachine:scaleMainLayer()
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

            mainScale = (FIT_HEIGHT_MAX + 9 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            
            
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 13)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 13)   
            end
            
        elseif display.height < 1363 and display.height >= 1332 then
            mainScale = (display.height + 15 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 11)


        elseif display.height < 1332 and display.height >= 1301 then
            mainScale = (display.height + 21 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 9)

        elseif display.height < 1301 and display.height >= 1270 then
            mainScale = (display.height + 27 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 7)

            
        elseif display.height < 1270 and display.height >= 1239 then
            mainScale = (display.height + 31 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 5)


        elseif display.height < 1239 and display.height >= 1198 then
            mainScale = (display.height + 37 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 4)



        elseif display.height < 1198 and display.height >= 1167 then
            mainScale = (display.height + 40 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 1)


        elseif display.height < 1167 and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 44 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 1)



        elseif display.height < FIT_HEIGHT_MIN and display.height >= 1081 then
            mainScale = (display.height + 50 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5 )



        else
            mainScale = (display.height + 60 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5 )


        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
    
end

function CodeGameScreenCharmsMachine:changeViewNodePos()
   
    if display.height > FIT_HEIGHT_MAX then

        if display.height > 1536 then

            self:findChild("jackpotbar_1"):setPositionY(self:findChild("jackpotbar_1"):getPositionY() + 37)
            self:findChild("jackpotbar_0"):setPositionY(self:findChild("jackpotbar_0"):getPositionY() + 37)
            self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() + 27)
        else
            
            if display.height > 1370 then

                self:findChild("jackpotbar_1"):setScale(0.9)
                self:findChild("jackpotbar_0"):setScale(0.9)
                self:findChild("jackpotbar_1"):setPositionX(self:findChild("jackpotbar_1"):getPositionX() + 10)
                self:findChild("jackpotbar_0"):setPositionX(self:findChild("jackpotbar_0"):getPositionX() + 10)

                self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() + 27)

            else

                self:findChild("jackpotbar_1"):setScale(0.9)
                self:findChild("jackpotbar_0"):setScale(0.9)
                self:findChild("jackpotbar_1"):setPositionX(self:findChild("jackpotbar_1"):getPositionX() + 10)
                self:findChild("jackpotbar_0"):setPositionX(self:findChild("jackpotbar_0"):getPositionX() + 10)
                self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() + 27)

                local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
                local nodeLunpan = self:findChild("base_reels")
                nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY)
                local nodeCollect = self:findChild("respin_reels")
                nodeCollect:setPositionY(nodeCollect:getPositionY() - posY)
                local nodeoldman = self:findChild("oldman")
                nodeoldman:setPositionY(nodeoldman:getPositionY() - posY)
                self:findChild("freespinbar"):setPositionY(self:findChild("freespinbar"):getPositionY() - posY)
                self:findChild("respinbar"):setPositionY(self:findChild("respinbar"):getPositionY() - posY)
                local progress = self:findChild("progress")
                progress:setPositionY(progress:getPositionY() - posY)
                for i=1,self.m_iReelColumnNum do
                    local pos = i -1
                    self:findChild("sp_reel_"..pos):setPositionY(self:findChild("sp_reel_"..pos):getPositionY() - posY)

                end

                self:findChild("root_respin_jackPotBg"):setPositionY(self:findChild("root_respin_jackPotBg"):getPositionY() - posY)

                self:findChild("Node_respin_Lines"):setPositionY(self:findChild("Node_respin_Lines"):getPositionY() - posY)

                self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() - posY)
                self:findChild("effect_node"):setPositionY(self:findChild("effect_node"):getPositionY() - posY)
                self:findChild("Node_yelloLines"):setPositionY(self:findChild("Node_yelloLines"):getPositionY() - posY)
                

                local nodeJackpot_0 = self:findChild("Node_1_0")
                local nodeJackpot_1 = self:findChild("Node_1_1")
                

                if (display.height / display.width) >= 2 then
                    nodeJackpot_0:setPositionY(nodeJackpot_0:getPositionY() + posY - 30)
                    nodeJackpot_1:setPositionY(nodeJackpot_1:getPositionY() + posY - 30  )
                    self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() + posY - 30 )
                else
                    nodeJackpot_0:setPositionY(nodeJackpot_0:getPositionY() + posY )
                    nodeJackpot_1:setPositionY(nodeJackpot_1:getPositionY() + posY  )
                    self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() + posY  )
                end
            end
            
        end
        

    else


        self:findChild("jackpotbar_1"):setScale(0.9)
        self:findChild("jackpotbar_0"):setScale(0.9)
        self:findChild("jackpotbar_1"):setPositionX(self:findChild("jackpotbar_1"):getPositionX() + 10)
        self:findChild("jackpotbar_0"):setPositionX(self:findChild("jackpotbar_0"):getPositionX() + 10)
        self:findChild("Node_TipView"):setPositionY(self:findChild("Node_TipView"):getPositionY() + 27)

    end

    if globalData.slotRunData.isPortrait then
   
        -- local bangHeight =  util_getBangScreenHeight()

        -- local nodeJackpot_0 = self:findChild("Node_1_0")
        -- local nodeJackpot_1 = self:findChild("Node_1_1")
        -- nodeJackpot_0:setPositionY(nodeJackpot_0:getPositionY()  -bangHeight)
        -- nodeJackpot_1:setPositionY(nodeJackpot_1:getPositionY()  -bangHeight )
        local bottomHeight = util_getSaveAreaBottomHeight()
        local bangHeight = util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bottomHeight - bangHeight )
    end

    
    
end

function CodeGameScreenCharmsMachine:initUI()


    -- self.m_reelRunSound = "CharmsSounds/music_Charms_LongRun.mp3"


    self:runCsbAction("idle")

    self:findChild("Node_respin_Lines"):setVisible(false)  



    for k,v in pairs(self.m_respinJackpotBgName) do
        self:findChild(v):setVisible(false) 
        local name = "CodeCharmsSrc.CharmsView"..self.m_respinJackpotBgViewName[k].."Bg" 
        local view = util_createView(name)
        view:setName("JackPotBg")
        self:findChild(v):addChild(view)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"link")

    self.m_jackPotBar = util_createView("CodeCharmsSrc.CharmsJackPotBar")
    self:findChild("jackpotbar_1"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:setVisible(true)

    self.m_RSjackPotBar = util_createView("CodeCharmsSrc.CharmsFSJackPotBar")
    self:findChild("jackpotbar_0"):addChild(self.m_RSjackPotBar)
    self.m_RSjackPotBar:initMachine(self)
    self.m_RSjackPotBar:setVisible(false)

    self.m_oldMan = util_spineCreate("Charms_Oldgold", true, true)
    self.m_csbOwner["oldman"]:addChild(self.m_oldMan)
    local pos = cc.p(self.m_csbOwner["oldman"]:getPosition()) 
    self.m_csbOwner["oldman"]:setPositionY(pos.y + 145 )
    self.m_csbOwner["oldman"]:setPositionX(pos.x - 80 )
    util_spinePlay(self.m_oldMan,"idleframe",true)

    
    self.m_freeSpinbar = util_createView("CodeCharmsSrc.CharmsViewFreespinBar")
    self:findChild("freespinbar"):addChild(self.m_freeSpinbar,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN+10)
    self:initFreeSpinBar() -- FreeSpinbar
    self.m_baseFreeSpinBar = self.m_freeSpinbar
    self.m_baseFreeSpinBar:setVisible(false)

    self.m_respinSpinbar = util_createView("CodeCharmsSrc.CharmsViewRespinBar")
    self:findChild("respinbar"):addChild(self.m_respinSpinbar,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN+10)
    self.m_respinSpinbar:setVisible(false)

    self.m_progress = util_createView("CodeCharmsSrc.CharmsProgress")
    self:findChild("progress"):addChild(self.m_progress)
     
    self.m_guochang = util_spineCreate("Charms_Oldgold_guochang", true, true) 
    self.m_root:addChild(self.m_guochang,99999)
    self.m_guochang:setPosition(cc.p(display.width/2,0))
    self.m_guochang:setVisible(false)
    -- util_spinePlay(self.m_guochang,"actionframe",false)

    self.m_map = util_createView("CodeCharmsSrc.CharmsBonusMap")
    self:addChild(self.m_map, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)


    self.m_soundNode = cc.Node:create()
    self:addChild(self.m_soundNode)


    self.m_TipView = util_createAnimation("Charms_shuoming.csb")
    self:findChild("Node_TipView"):addChild(self.m_TipView)
    self.m_TipView:runCsbAction("animation0",true)

    self:findChild("effect_node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 12 )
    self.m_effectView = util_createAnimation("Charms_lunpanglow.csb")
    self:findChild("effect_node"):addChild(self.m_effectView)
    self.m_effectView:runCsbAction("actionframe",true)
    self.m_effectView:setVisible(false)

    -- self:findChild("Node_yelloLines"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1 )
   
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_isPlayRespinEnd then
            return
        end

        if self.m_classicMachine then
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


        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE  then
            print("freespin最后一次 无论是否大赢都播放赢钱音效")
        else
            if winRate >= self.m_HugeWinLimitRate then
                return
            elseif winRate >= self.m_MegaWinLimitRate then
                return
            elseif winRate >= self.m_BigWinLimitRate then
                return
            end
        end

        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName =  "CharmsSounds/Charms_winCoins_".. soundIndex .. ".mp3" -- "CharmsSounds/music_Charms_last_win_idle.mp3" --
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function()
            gLobalSoundManager:setBackgroundMusicVolume(1)
            self.m_winSoundsId = nil
        end)

        -- performWithDelay(self.m_soundNode,function()
        --     if self.m_winSoundsId then
        --         gLobalSoundManager:stopAudio(self.m_winSoundsId)
        --         self.m_winSoundsId = nil
        --         -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_last_win_over.mp3",false)
        --     end
            
            
        --     gLobalSoundManager:setBackgroundMusicVolume(1)

        -- end,soundIndex)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenCharmsMachine:getBottomUINode( )
    return "CodeCharmsSrc.CharmsGameBottomNode"
end

function CodeGameScreenCharmsMachine:initBottomUI()
    
    CodeGameScreenCharmsMachine.super.initBottomUI(self)
    self.m_bottomUI:createLocalAnimation()
    
end

function CodeGameScreenCharmsMachine:getBounsScatterDataZorder(symbolType)
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS 
        or math.abs(symbolType) == self.SYMBOL_FIX_MINI  
            or math.abs(symbolType) == self.SYMBOL_FIX_SYMBOL then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif  symbolType == self.FEATURE_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100
    else
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1
    end
    return order
end

function CodeGameScreenCharmsMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(6,5,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end


function CodeGameScreenCharmsMachine:getPosReelIdx(iRow, iCol)
    local iReelRow = #self.m_runSpinResultData.p_reels 
    local index = (iReelRow- iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

function CodeGameScreenCharmsMachine:respinChangeReelGridCount(count)
    for i=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end


function CodeGameScreenCharmsMachine:showEffect_Bonus(effectData)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.node
    local bonusGame = function()
        local gameType = self.m_bonusPath[self.m_nodePos]
        if gameType == 0 then
            performWithDelay(self, function()
                gLobalSoundManager:playSound("CharmsSounds/music_Charms_Open_View.mp3")
                self:showLocalDialog("ClassicStart", nil,function()
                    local data = {}
                    data.parent = self
                    data.paytable = self.m_runSpinResultData.p_selfMakeData.classicWinCoins
                    data.effectData = effectData
                    local uiW, uiH = self.m_topUI:getUISize()
                    local uiBW, uiBH = self.m_bottomUI:getUISize()
                    data.height = uiH + uiBH
                    -- data.func = function()
                        
                    --     self:updateBaseConfig()
                    --     self:initSymbolCCbNames()
                    --     self:initMachineData()
                    --     globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
                    --     globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    --     effectData.p_isPlay = true
                    --     self:playGameEffect()
                    --     self:resetMusicBg()
                    -- end
                    self.m_classicMachine = util_createView("GameScreenClassicSlots" , data)
                    self:addChild(self.m_classicMachine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
                    if globalData.slotRunData.machineData.p_portraitFlag then
                        self.m_classicMachine.getRotateBackScaleFlag = function() return false end
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_classicMachine})
                    self.m_bottomUI:showAverageBet()
                    self:clearWinLineEffect()
                    self:resetMaskLayerNodes()
                end)
            end, 0)
            
            
        else
            self.m_fsReelDataIndex = gameType
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            gLobalSoundManager:playSound("CharmsSounds/music_Charms_Open_View.mp3")
            local view = self:showLocalDialog("FreeSpinStart_1", nil,function()

                self:startGameGuoChangView( function()

                    util_spinePlay(self.m_oldMan,"idleframe",true)

                    globalData.slotRunData.lastWinCoin = 0
                    self.m_bottomUI:checkClearWinLabel()
                    self.m_bottomUI:showAverageBet()
                    self.m_progress:setVisible(false)
                    self.m_progress:setPercent(0)
                    
                    -- 调用此函数才是把当前游戏置为freespin状态
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()

                    if self.m_nodePos == #self.m_bonusPath then
                        self.m_map:resetMapUI()
                    end
                end)

            end)
            view:findChild("Charms_bonus_1"):setVisible(false)
            view:findChild("Charms_bonus_2"):setVisible(false)
            view:findChild("Charms_bonus_3"):setVisible(false)
            view:findChild("Charms_bonus_4"):setVisible(false)
            view:findChild("Charms_bonus_"..self.m_fsReelDataIndex):setVisible(true)
        end
        
    end
    performWithDelay(self, function()
        self:showBonusMap(bonusGame, self.m_nodePos)
    end, 2)
    return true
end

function CodeGameScreenCharmsMachine:addNewGameEffect()
    globalData.slotRunData.totalFreeSpinCount = (globalData.slotRunData.totalFreeSpinCount or 0) + self.m_iFreeSpinTimes
    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function CodeGameScreenCharmsMachine:classicSlotOverView(winCoin, effectData)
    gLobalSoundManager:playSound("CharmsSounds/music_Charms_open_over_View.mp3")
    local view = self:showLocalDialog("ClassicOver", nil,function()
        performWithDelay(self, function()

            self.m_classicMachine:removeFromParent()
            self.m_classicMachine = nil
            self.m_bottomUI:hideAverageBet()
            self:updateBaseConfig()
            self:initSymbolCCbNames()
            self:initMachineData()
            -- globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            -- globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
            self.m_bIsInClassicGame = false
            self:MachineRule_checkTriggerFeatures()
            self:addNewGameEffect()
            if effectData ~= nil then
                effectData.p_isPlay = true
            end
            
            self:playGameEffect()
            self:resetMusicBg()
        end, 0.02)
    end)
    local node=view:findChild("m_lb_coins")
    node:setString(util_formatCoins(winCoin, 50))
    view:updateLabelSize({label=node,sx=1,sy=1},332)
end

-- 断线重连 
function CodeGameScreenCharmsMachine:MachineRule_initGame( spinData )

    if self.m_initSpinData.p_reSpinCurCount and self.m_initSpinData.p_reSpinCurCount > 0 then
        self.m_isInFreeGames = true
    end

    if spinData.p_bonusStatus == "OPEN" and self.m_bonusPath[self.m_nodePos] ~= 0 then
        self.m_fsReelDataIndex = self.m_bonusPath[self.m_nodePos]
        self.m_progress:setVisible(false)
    end
    
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_progress:setVisible(false)
    end
    
    if self:BaseMania_isTriggerCollectBonus() then
        
        self.m_fsReelDataIndex = self.m_bonusPath[self.m_nodePos]
        if self.m_fsReelDataIndex ~= 0 then
            self.m_progress:setVisible(false)
            self.m_bIsInBonusFreeGame = true
        else
            self.m_bIsInClassicGame = true
        end
        
        self.m_bClassicReconnect = true
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

function CodeGameScreenCharmsMachine:initFeatureInfo(spinData,featureData)
    if featureData.p_status == "OPEN" then
        
        self.m_fsReelDataIndex = self.m_bonusPath[self.m_nodePos]
        if self.m_fsReelDataIndex ~= 0 then
            self.m_progress:setVisible(false)
            self.m_bIsInBonusFreeGame = true
        else
            self.m_bIsInClassicGame = true
        end
        
        self.m_bClassicReconnect = true
        local featureID = spinData.p_features[#spinData.p_features]
        
        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
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

function CodeGameScreenCharmsMachine:checkHasFeature()
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then

        for i=1,#self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN or 
            featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or  self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    hasFeature = hasFeature or  self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    hasFeature = hasFeature or  self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or 
    self:getCurrSpinMode() == RESPIN_MODE  then
        hasFeature = true
    end

    if (self.m_initFeatureData ~= nil and self.m_initFeatureData.p_status == "OPEN") or self:BaseMania_isTriggerCollectBonus() then
        hasFeature = true
    end

    return hasFeature
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenCharmsMachine:respinModeChangeSymbolType()
    if self.m_bIsInBonusFreeGame == true then
        return
    end
    if self.m_initSpinData ~= nil and self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then

        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            self.m_iReelRowNum = RESPIN_ROW_COUNT
            self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

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

function CodeGameScreenCharmsMachine:getRespinAddNum()
    local num = 0
    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        num = 3
        return num
    end
    return num
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node 
-- 
function CodeGameScreenCharmsMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    -- self.m_initGridNode = true

    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount  --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount 
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false 
        local beginIndex = 1
        if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
            if self.m_runSpinResultData.p_reSpinCurCount > 0 then
                beginIndex = 4 --  断线的时候respin  只从 后三行数据读取，初始化轮盘
            end
        end
        if self.m_initSpinData.p_selfMakeData ~= nil and self.m_initSpinData.p_selfMakeData.baseReels ~= nil then
            self.m_initSpinData.p_reels = self.m_initSpinData.p_selfMakeData.baseReels
        end
        while rowIndex >= beginIndex do 

            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式 
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1;
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP  = true
                end
                for checkRowIndex = changeRowIndex + 1,rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if  checkIndex == rowNum then
                                -- body
                                isUP  = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break;
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom
            
            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)
            
            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            local slotParentBig = parentData.slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node,
                    REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            else
                parentData.slotParent:addChild(node,
                    REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            end

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )
            node:runIdleAnim()      
            rowIndex = rowIndex - stepCount
        end  -- end while

    end
    
    -- self:initGridList()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCharmsMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "Charms"  
end

function CodeGameScreenCharmsMachine:getNetWorkModuleName()
    return "CharmsV2"
end

-- 继承底层respinView
function CodeGameScreenCharmsMachine:getRespinView()
    return "CodeCharmsSrc.CharmsRespinView"
end
-- 继承底层respinNode
function CodeGameScreenCharmsMachine:getRespinNode()
    return "CodeCharmsSrc.CharmsRespinNode"
end

-- 炸弹respin层
-- 继承底层respinView
function CodeGameScreenCharmsMachine:getBoomRespinView()
    return "CodeCharmsSrc.CharmsBoomRespinView"
end
-- 继承底层respinNode
function CodeGameScreenCharmsMachine:getBoomRespinNode()
    return "CodeCharmsSrc.CharmsBoomRespinNode"
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCharmsMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_UNLOCK_SYMBOL then
        return "Socre_Charms_".. math.random( 1, 4 ) 
    elseif symbolType == self.SYMBOL_NULL_LOCK_SYMBOL then
        return "Socre_Charms_".. math.random( 1, 4 )
    elseif symbolType == self.FLY_COIN_TYPE then
        return "Charms_shouji"
    end

    -- 自行配置jackPot信号 csb文件名，不带后缀
    if math.abs( symbolType )  == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_Charms_Bonus_2"
    end

    if math.abs( symbolType ) == self.SYMBOL_FIX_SYMBOL_DOUBLE then
        return "Socre_Charms_Bonus_3"
    end

    if math.abs( symbolType ) == self.SYMBOL_FIX_MINOR then
        return "Socre_Charms_Bonus_minor"
    end

    if math.abs( symbolType ) == self.SYMBOL_FIX_MINOR_DOUBLE then
        return "Socre_Charms_Bonus_minor"
    end

    

    if math.abs( symbolType ) == self.SYMBOL_FIX_MINI then
        return "Socre_Charms_Bonus_mini"
    end

    if math.abs( symbolType ) == self.SYMBOL_FIX_SYMBOL_BOOM  then
        return "Socre_Charms_Boom1"
    end

    if math.abs( symbolType ) == self.SYMBOL_FIX_SYMBOL_NULL  then
        return "Socre_Charms_Bonus_NULL"
    end

    if math.abs( symbolType ) == self.SYMBOL_FIX_SYMBOL_BOOM_RUN  then
        return "Socre_Charms_Boom1"
    end

    
    if symbolType == self.SYMBOL_WILD_2X then
        return "Socre_Charms_wildx2"
    end
    if symbolType == self.SYMBOL_WILD_3X then
        return "Socre_Charms_wildx3"
    end
    if symbolType == self.SYMBOL_WILD_5X then
        return "Socre_Charms_wildx5"
    end
    if symbolType == self.SYMBOL_WILD_8X then
        return "Socre_Charms_wildx8"
    end
    if symbolType == self.SYMBOL_WILD_10X then
        return "Socre_Charms_wildx10"
    end
    if symbolType == self.SYMBOL_WILD_25X then
        return "Socre_Charms_wildx25"
    end
    if symbolType == self.SYMBOL_WILD_100X then
        return "Socre_Charms_wildx100"
    end
   

    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenCharmsMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
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

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType then
        if math.abs( symbolType )  == self.SYMBOL_FIX_MINI then
            score = "MINI"
        elseif math.abs( symbolType ) == self.SYMBOL_FIX_MINOR  then
            score = "MINOR"
        end
    end
    

    return score
end

function CodeGameScreenCharmsMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType then
        if math.abs(symbolType) == self.SYMBOL_FIX_SYMBOL 
        or math.abs(symbolType) == self.SYMBOL_FIX_SYMBOL_DOUBLE  then
            -- 根据配置表来获取滚动时 respinBonus小块的分数
            -- 配置在 Cvs_cofing 里面
            score = self.m_configData:getFixSymbolPro()
        end
    end

    

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenCharmsMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local symbolIndex = self:getPosReelIdx(iRow, iCol)
        local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            local scoreNode = symbolNode:getCcbProperty("m_lb_score")
            if scoreNode then
                scoreNode:setString(score)
            end
            -- if symbolNode then
            --     symbolNode:runAnim("idleframe")
            -- end
        end        
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            local scoreNode = symbolNode:getCcbProperty("m_lb_score")
            if scoreNode then
                scoreNode:setString(score)
            end
            -- if symbolNode then
            --     symbolNode:runAnim("idleframe")
            -- end
        end
    end
end


function CodeGameScreenCharmsMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if math.abs( symbolType )  == self.SYMBOL_FIX_SYMBOL
        or math.abs( symbolType ) == self.SYMBOL_FIX_MINI       
        or math.abs( symbolType ) == self.SYMBOL_FIX_MINOR 
        or math.abs( symbolType ) == self.SYMBOL_FIX_SYMBOL_DOUBLE 
        or math.abs( symbolType ) == self.SYMBOL_FIX_MINOR_DOUBLE 
    then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end



    return reelNode
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCharmsMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINI,count =  2}

    -- 因为respin中会出现- 的信号
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_FIX_SYMBOL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_FIX_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_FIX_MINI,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_MINOR_DOUBLE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL_DOUBLE,count =  2}
    
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_FIX_MINOR_DOUBLE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_FIX_SYMBOL_DOUBLE,count =  2}


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL_BOOM,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL_NULL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL_BOOM_RUN,count =  2}

    loadNode[#loadNode + 1] = {symbolType = self.FLY_COIN_TYPE, count = 2}

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
function CodeGameScreenCharmsMachine:isFixSymbol(symbolType)
    symbolType = symbolType or 1
    if math.abs(symbolType) == self.SYMBOL_FIX_SYMBOL  or 
        math.abs(symbolType) == self.SYMBOL_FIX_SYMBOL_DOUBLE  or
        math.abs(symbolType) == self.SYMBOL_FIX_MINI or 
        math.abs(symbolType) == self.SYMBOL_FIX_MINOR or
        math.abs(symbolType) == self.SYMBOL_FIX_MINOR_DOUBLE then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenCharmsMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol) 
    performWithDelay(self,function()
        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
            local isHaveFixSymbol = false
            for k = 1, 3 do
                local symbolNode =  self:getFixSymbol(reelCol, k , SYMBOL_NODE_TAG)  -- self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,k,SYMBOL_NODE_TAG))
    
                if symbolNode then
                    print(symbolNode.p_symbolType .. " ---- "..reelCol) 
                    if self.m_stcValidSymbolMatrix[k][reelCol] ~= symbolNode.p_symbolType  then
                        print("chucuole")
                    end
                    print(" ++++ ".. self.m_stcValidSymbolMatrix[k][reelCol])
                end
                
                if symbolNode and symbolNode.p_symbolType and self:isFixSymbol(symbolNode.p_symbolType) then
                    isHaveFixSymbol = true
    
                    
                    symbolNode:runAnim("buling",false,function()
                        symbolNode:runAnim("idleframe2",true)
                    end)
                end
            end
            if isHaveFixSymbol == true  then

                local soundPath =  "CharmsSounds/music_Charms_Bonus_Down.mp3"

                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    -- respinbonus落地音效
                    gLobalSoundManager:playSound(soundPath)
                end

                
            end
        end 
    end,0)
    
   
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenCharmsMachine:levelFreeSpinEffectChange()

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")

end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenCharmsMachine:levelFreeSpinOverChangeEffect()

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")

    
    
end
---------------------------------------------------------------------------

function CodeGameScreenCharmsMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenCharmsMachine:showFreeSpinMore(num,func,isAuto)

    local function newFunc()
        self:resetMusicBg(true)  
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist={}
    ownerlist["m_lb_num"]=num
    if isAuto then
        return self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE,ownerlist,newFunc,BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE,ownerlist,newFunc)
    end
end

-- 触发freespin时调用
function CodeGameScreenCharmsMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_custom_enter_fs.mp3")
    
    

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("CharmsSounds/music_Charms_Open_View.mp3")
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,false)
    else
            performWithDelay(self,function()
                gLobalSoundManager:playSound("CharmsSounds/music_Charms_Open_View.mp3")


                self.m_isFreespinStart = true

                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    
                    self:startGameGuoChangView( function()

                        self:levelFreeSpinEffectChange()

                        util_spinePlay(self.m_oldMan,"idleframe",true)

                        self.m_progress:setVisible(false)
                        -- 调用此函数才是把当前游戏置为freespin状态
                        performWithDelay(self,function()
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end,0)
                    end,function()
                        gLobalSoundManager:playSound("CharmsSounds/music_Charms_fs_enter.mp3")
                    end)

          
                end)
            end,0)
            
    end

end

function CodeGameScreenCharmsMachine:removeAllReelsNode()
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

function CodeGameScreenCharmsMachine:createRandomReelsNode()
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()
    self:removeAllReelsNode()
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
                 
                local targSpPos =  cc.p(self:getThreeReelsTarSpPos(4 ))


                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(newNode.p_symbolType) then
                    slotParentBig:addChild(newNode,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 - iRow , iCol * SYMBOL_NODE_TAG + iRow)
                else
                    parentData.slotParent:addChild(newNode,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 - iRow , iCol * SYMBOL_NODE_TAG + iRow)
                end

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
                  
                -- if newNode.p_symbolType and newNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                --     local score = math.random( 1, 4 )
                --     local lineBet = globalData.slotRunData:getCurTotalBet()
                --     score = score * lineBet
                --     score = util_formatCoins(score, 3)
                --     local lab = newNode:getCcbProperty("m_lb_score")
                --     if lab then
                --         lab:setString(score)
                --     end
                -- end 

            end

        end
    end
end

function CodeGameScreenCharmsMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

-- 触发freespin结束时调用
function CodeGameScreenCharmsMachine:showFreeSpinOverView()

    -- local iFreeSpinTime = self.m_runSpinResultData.p_freeSpinsTotalCount
    -- if self.m_fsReelDataIndex ~= 0 then
    --     iFreeSpinTime = 10
    -- end
    
    gLobalSoundManager:playSound("CharmsSounds/free_spin_music_freespin_end.mp3")

    self.m_bIsInBonusFreeGame = false
    performWithDelay(self,function()

        gLobalSoundManager:playSound("CharmsSounds/music_Charms_open_over_View.mp3")

        local strCoins=util_formatCoins(self.m_runSpinResultData.p_fsWinCoins,50)
        local view = self:showFreeSpinOver( strCoins,globalData.slotRunData.totalFreeSpinCount,function()

                -- self:overGameGuoChangView(function()
                
                    -- util_spinePlay(self.m_oldMan,"idleframe",true)

                    if self.m_fsReelDataIndex ~= 0 then
                        self.m_progress:setPercent(0)
                        self.m_fsReelDataIndex = 0 
                        self.m_bottomUI:hideAverageBet()
                    end
                    
                    -- 调用此函数才是把当前游戏置为freespin结束状态
                    
                    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                        
                        self:createRandomReelsNode()
                        self:MachineRule_checkTriggerFeatures() 
                        self:addNewGameEffect()
                    end
                    
                    self.m_baseFreeSpinBar:setVisible(false)
                    -- util_playFadeOutAction(self.m_baseFreeSpinBar,0.19,function()
                        
                    --     util_playFadeInAction(self.m_baseFreeSpinBar,0.1,function()
                    --     end)
                    -- end)

                    util_playFadeOutAction(self.m_gameBg,0.1,function()

                        self:levelFreeSpinOverChangeEffect()

                        util_playFadeInAction(self.m_gameBg,0.1,function()
                        
                        end)
                    end)

                    util_playFadeOutAction(self.m_progress,0.01,function()
                        self.m_progress:setVisible(true)
                        util_playFadeInAction(self.m_progress,0.19,function()
                        
                            self:triggerFreeSpinOverCallFun()   
                            
                        end)
                    end)

                -- end )

         
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},298)
   end,2)
   

end

function CodeGameScreenCharmsMachine:showRespinJackpot(index,coins,func)
    
    -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_jackPotWinView.mp3")

    gLobalSoundManager:playSound("CharmsSounds/music_Charms_open_over_View.mp3")

    local jackPotWinView = util_createView("CodeCharmsSrc.CharmsJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
end

-- 结束respin收集
function CodeGameScreenCharmsMachine:playLightEffectEnd()

    self:sendSpinLog()
    self.m_bottomUI.m_respinEndActiom:setVisible(false)
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    performWithDelay(self,function()
        self:showRespinOverView()
    end,1)
    

end

function CodeGameScreenCharmsMachine:isInsetDoubleSymbolInEndChip()
    local isInster = true

    local lockBonusIndex = self.m_runSpinResultData.p_selfMakeData.lockBonus or {}
    local doubleSymbol = self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    for k,v in pairs(doubleSymbol) do
        for kk,vv in pairs(lockBonusIndex) do
            if vv == v then -- 如果双个信号有一个被锁住就不参与结算
                isInster = false
                return isInster
            end
        end
    end

    return isInster 
end

function CodeGameScreenCharmsMachine:getEndChip()
    local chipList ={}

    local lockBonusIndex = self.m_runSpinResultData.p_selfMakeData.lockBonus  or {}
    local doubleSymbol = self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    for k,v in pairs(self.m_chipList) do
        local isIn = false
        local index = self:getPosReelIdx(v.p_rowIndex, v.p_cloumnIndex)
        for kk,vv in pairs(lockBonusIndex) do
            if vv == index then
                isIn = true
            end
        end
        if not isIn then
            table.insert( chipList,  v )
        end
    end

    local insterIndex = nil
    local insterNode = nil
    for i = #chipList,1,-1 do
        local chipNode = chipList[i]
        local isIn = false
        local index = self:getPosReelIdx(chipNode.p_rowIndex, chipNode.p_cloumnIndex)
        for kk,vv in pairs(doubleSymbol) do
            if vv == index then
                insterIndex = i
                if math.abs( chipNode.p_symbolType )  == self.SYMBOL_FIX_SYMBOL_DOUBLE 
                    or math.abs( chipNode.p_symbolType )  == self.SYMBOL_FIX_MINOR_DOUBLE  then
                        insterNode = chipNode
                end
                table.remove( chipList, i )
            end
        end
    end

    -- 把大块填进去
    if insterIndex and insterNode and self:isInsetDoubleSymbolInEndChip() then
        table.insert( chipList, insterIndex, insterNode )
    end
    

    return chipList
end

function CodeGameScreenCharmsMachine:getShowMinorIndx()
    local index = nil
    local winRow = self.m_runSpinResultData.p_selfMakeData.series

    if #winRow == 3 then
        if winRow[2] == 2 then
            index = 4 -- 对应 m_respinJackpotBgName 中的位置 
        elseif winRow[2] == 3 then
            index = 5
        else
            index = 6
        end
    end

    return index
end

function CodeGameScreenCharmsMachine:getShowMajorIndx()
    
    local index = nil
    local winRow = self.m_runSpinResultData.p_selfMakeData.series

    if #winRow == 4 then

        if winRow[2] == 2 then
            index = 2 -- 对应 m_respinJackpotBgName 中的位置
        else
            index = 3
        end
        
    end

    return index

end

function CodeGameScreenCharmsMachine:jackPotEndWin( func)
    
    local addScore = 0
    local score = self.m_runSpinResultData.p_selfMakeData.jackpot
    local winRow = self.m_runSpinResultData.p_selfMakeData.series
    local jackpotScore = 0
    local nJackpotType = 1
    local waitTimes = 0
    if score ~= nil then
        if score == "Grand" then
            jackpotScore = self:BaseMania_getJackpotScore(1) 
            addScore = jackpotScore + addScore
            nJackpotType = 4
            self:findChild(self.m_respinJackpotBgName[1]):setVisible(true) 
            
            self.m_RSjackPotBar:runCsbAction("run1",true)

            waitTimes = 2
            gLobalSoundManager:playSound("CharmsSounds/Charms_WinJackPot3.mp3")

            local jpBg =  self:findChild(self.m_respinJackpotBgName[1]):getChildByName("JackPotBg")
            if jpBg then
                jpBg:runCsbAction("animation0",true)
            end
        elseif score == "Major" then

            self.m_RSjackPotBar:runCsbAction("run2",true)

            waitTimes = 2
            gLobalSoundManager:playSound("CharmsSounds/Charms_WinJackPot2.mp3")

            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 3
            local index = self:getShowMajorIndx()
            self:findChild(self.m_respinJackpotBgName[index]):setVisible(true)
            local jpBg =  self:findChild(self.m_respinJackpotBgName[index]):getChildByName("JackPotBg")
            if jpBg then
                jpBg:runCsbAction("animation0",true)
            end
        
        elseif score == "Minor" then
            waitTimes = 1
            gLobalSoundManager:playSound("CharmsSounds/Charms_WinJackPot1.mp3")

            jackpotScore =  self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                 
            nJackpotType = 2
            local index = self:getShowMinorIndx()
            self:findChild(self.m_respinJackpotBgName[index]):setVisible(true)
            local jpBg =  self:findChild(self.m_respinJackpotBgName[index]):getChildByName("JackPotBg")
            if jpBg then
                jpBg:runCsbAction("animation0",true)
            end
            
        elseif score == "Mini" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                     
            nJackpotType = 1
        end

        self.m_lightScore = self.m_serverWinCoins

        performWithDelay(self,function()
            if self.m_bProduceSlots_InFreeSpin then
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin 
    
            else
                
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin  
            end
    
    
            -- 显示提示背景
    
            self:showRespinJackpot(nJackpotType, util_formatCoins(jackpotScore,50), function()

                self.m_RSjackPotBar:runCsbAction("hide")

               if func then
                    func()
               end 

                for k,v in pairs(self.m_respinJackpotBgName) do
                    self:findChild(v):setVisible(false) 
                    local jpBg =  self:findChild(v):getChildByName("JackPotBg")
                    if jpBg then
                        jpBg:runCsbAction("animation0",true)
                    end
                    
                end
            end)
        end,3 + waitTimes)


    else
        if func then
            func()
       end 
    end

    
    
           

end

function CodeGameScreenCharmsMachine:playChipCollectAnim()

    self.m_isPlayRespinEnd = true

    local m_chipList = self:getEndChip()
    
    if self.m_playAnimIndex > #m_chipList then --- 这里待确认  是否中了grand 其他小块就不赢钱
        
        -- 最后检查一下有没连续的列来触发jackpot
        self:jackPotEndWin( function()
            -- 此处跳出迭代
            self:playLightEffectEnd()
        end)

        return 
    end

    local chipNode = m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    -- 根据网络数据获得当前固定小块的分数
    local scoreIndx = self:getPosReelIdx(iRow ,iCol)
    local score = self:getReSpinSymbolScore(scoreIndx) 
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 4
        elseif score == "MAJOR" then
            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINOR" then
            jackpotScore =  self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                 
            nJackpotType = 2
        elseif score == "MINI" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                     
            nJackpotType = 1
        end
    end

    local fullJackpot = self.m_runSpinResultData.p_selfMakeData.jackpot
    --bugly:最后一次收集保证和服务器赢钱一致
    if self.m_playAnimIndex == #m_chipList and fullJackpot == nil then
        self.m_lightScore = self.m_serverWinCoins
    else
        self.m_lightScore = self.m_lightScore + addScore
    end
    

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self. m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            self:showRespinJackpot(nJackpotType, util_formatCoins(jackpotScore,50), function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
           
        end
    end

    -- 添加鱼飞行轨迹
    local function fishFly()

        -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_respinEnd_win_jinguang.mp3")
            
            self:playCoinWinEffectUI()
            gLobalSoundManager:playSound("CharmsSounds/music_Charms_respinEnd_win.mp3")
            chipNode:runAnim("over")
            local noverAnimTime = 0

            if self.m_bProduceSlots_InFreeSpin then
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin 
        
            else
                
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin  
            end

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(self,function()
                fishFlyEndJiesuan()  
                waitNode:removeFromParent()
            end,noverAnimTime)

        
    end

    
    
    -- chipNode:runAnim("over")
    -- local nBeginAnimTime = chipNode:getAniamDurationByName("over")
    -- self:createParticleFly(0.4,chipNode)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(self,function()
        fishFly()  
    end,0.4)

    -- scheduler.performWithDelayGlobal(function()

    --     chipNode:runIdleAnim()

    -- end,nBeginAnimTime,self:getModuleName())

    
end



--结束移除小块调用结算特效
function CodeGameScreenCharmsMachine:reSpinEndAction()    
    
    self.m_respinSpinbar:changeRespinTimes(0)

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    self:removeAllRespinJackPotTipNode()

    self.m_respinSpinbar:setVisible(false)

    gLobalSoundManager:playSound("CharmsSounds/music_Charms_respinEndTip.mp3")
    performWithDelay(self, function()
        self:playChipCollectAnim()
    end,2)
    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenCharmsMachine:getRespinRandomTypes()
    local symbolList = { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenCharmsMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling2", bRandom = true},
        {type = -self.SYMBOL_FIX_SYMBOL_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_MINOR_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling2", bRandom = true}


    }

    return symbolList
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenCharmsMachine:getBoomRespinRandomTypes()
    local symbolList = { self.SYMBOL_FIX_SYMBOL_NULL,
self.SYMBOL_FIX_SYMBOL_BOOM_RUN}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenCharmsMachine:getBoomRespinLockTypes()
    local symbolList = { 
    }

    return symbolList
end

function CodeGameScreenCharmsMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()
    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()

    -- 炸弹轮盘
    local boomEndTypes = self:getBoomRespinLockTypes()
    local boomRandomTypes =  self:getBoomRespinRandomTypes()

    self.m_iReelRowNum = RESPIN_ROW_COUNT
    self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

    -- 播放 respinbonus buling 动画
    local ActionTime = 4.7
    for icol = 1,self.m_iReelColumnNum do
        for irow = 1, NORMAL_ROW_COUNT do

            local node = self:getFixSymbol(icol, irow , SYMBOL_NODE_TAG) 
            if node and  node.p_symbolType then
                if self:isFixSymbol(node.p_symbolType) then

                    self:createOneActionSymbol(node,"actionframe")
                    ActionTime = node:getAniamDurationByName("actionframe")
                end
            end
            
        end
    end
    
    gLobalSoundManager:playSound("CharmsSounds/music_Charms_trigger_respin.mp3")

    -- performWithDelay(self,function()
        -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_trigger_respin.mp3")
    -- end,2.3)
    
    performWithDelay(self,function()
        self:triggerReSpinCallFun(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
    end,ActionTime )
end

function CodeGameScreenCharmsMachine:getRespinNodeStates( symboltype )

    local states = nil

    states = RESPIN_NODE_STATUS.IDLE

    return states
end


----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenCharmsMachine:reateBoomRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self.SYMBOL_FIX_SYMBOL_NULL

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


            local symbolstatus = RESPIN_NODE_STATUS.IDLE
             if iRow > 3 then
                symbolstatus = RESPIN_NODE_STATUS.LOCK
            end
            local symbolNodeInfo = {
                status = symbolstatus ,
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

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenCharmsMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

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
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH   
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = self:getRespinNodeStates( symbolType ) ,
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

-- 添加上大信号的信息
function CodeGameScreenCharmsMachine:triggerChangeRespinNodeInfo(respinNodeInfo )

    local bigBonusPositions =  self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    
    for k,v in pairs(bigBonusPositions) do
        local fixpos = self:getRowAndColByPosForSixRow(v)
        local iRow = fixpos.iX
        local iCol = fixpos.iY

        --信号类型
        local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

        if math.abs( symbolType ) ==  self.SYMBOL_FIX_SYMBOL  then
            symbolType = self.SYMBOL_FIX_SYMBOL_DOUBLE 
        elseif math.abs( symbolType ) == self.SYMBOL_FIX_MINOR then 
            symbolType = self.SYMBOL_FIX_MINOR_DOUBLE 
        end

        --层级
        local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
        --tag值
        local tag = self:getNodeTag(iRow + 100, iCol + 100, SYMBOL_NODE_TAG)
        --二维坐标
        local arrayPos = {iX = iRow, iY = iCol}

        --世界坐标
        local pos, reelHeight, reelWidth = self:getReelPos(iCol)
        pos.x = (pos.x + reelWidth / 2 * self.m_machineRootScale) + self.m_SlotNodeW/2 * self.m_machineRootScale
        local columnData = self.m_reelColDatas[iCol]
        local slotNodeH = columnData.p_showGridH   
        pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

        local symbolNodeInfo = {
            status = self:getRespinNodeStates( symbolType ) ,
            bCleaning = true,
            isVisible = true,
            Type = symbolType,
            Zorder = zorder,
            Tag = tag,
            Pos = pos,
            ArrayPos = arrayPos
        }
        respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo

        break
    end

            

end



function CodeGameScreenCharmsMachine:initRespinView(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
    
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:initMachine(self)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH  , self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()

                    self.m_bottomUI:updateWinCount("")

                    self:startGameGuoChangView( function()

                        

                        for i=1,#self.m_actRsNode do
                            local node = self.m_actRsNode[i]
                            node:removeFromParent()
                        end
                        self.m_actRsNode = {}
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"link")

                        self.m_progress:setVisible(false)
                        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                        self.m_respinView:setVisible(true)
                        self.m_BoomReelsView:setVisible(true)

                        self:findChild("Node_respin_Lines"):setVisible(true) 
                        -- self:findChild("Node_respin_Lines"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 11)

                        gLobalSoundManager:playSound("CharmsSounds/music_Charms_rs_enter.mp3")
                        performWithDelay(self,function()
                            -- 播放对应的添加上边轮盘的动画
                            self:createRunningSymbolAnimation( function()

                                performWithDelay(self,function()
                                    if self.m_DouDongid then
                                        gLobalSoundManager:stopAudio(self.m_DouDongid)
                                        self.m_DouDongid = nil
                                    end 
                                    -- 过场动画播完了 
                                    -- 给未解锁的加锁
                                    local LockSymbolTime = self:createLockSymbol()

                                    performWithDelay(self,function()
            
                                    -- 是否播放炸开轮盘的动画
                                        local waitTime = self:checkBoomReels()

                                        performWithDelay(self,function()
                                            self:checkRemoveNotNeedTipNode()

                                            self:createRespinJackPotTipNode()

                                            -- 移除火焰特效 
                                            self:removeAllFir()
                                            -- 移除炸弹
                                            self:removeAllBoom()

                                            -- 更改respin 状态下的背景音乐
                                            self:changeReSpinBgMusic()

                                            self:runNextReSpinReel()
                                        end,waitTime)
                                    end,LockSymbolTime)
                                end,0)
                            end )
                        end,0.3)
                    end,function()
                        self.m_guochang:setVisible(false)

                        
                    end)

                end
            )
        end
    )
    

    --炸弹轮盘
    --构造盘面数据
    local respinBoomNodeInfo = self:reateBoomRespinNodeInfo()
    self.m_BoomReelsView:initMachine(self)
    self.m_BoomReelsView:setEndSymbolType(boomEndTypes, boomRandomTypes)
    self.m_BoomReelsView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH  , self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_BoomReelsView:initRespinElement(
        respinBoomNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
           
        end
    )


    self.m_baseFreeSpinBar:setVisible(false)
    self:hidAllUnLockUpSymbol()
    self.m_respinView:setVisible(false)
    self.m_BoomReelsView:setVisible(false)
    
    
end

---判断结算
function CodeGameScreenCharmsMachine:reSpinReelDown(addNode)

    self.m_respinStopCount = self.m_respinStopCount + 1
    --等2个respinView都停下来
    if self.m_respinStopCount < 2 then
        return
    end
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin

    -- 轮盘全部停止时处理炸弹炸轮盘的
    local waitBulingTime = 0
    if self.m_boomNodeBulingList and #self.m_boomNodeBulingList > 0 then
        waitBulingTime = 0.7
    end

    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function()

        self.m_BoomReelsView:hideAllCurrNode()

        -- 是否播放炸开轮盘的动画
        local waitTime = self:checkBoomReels()
        local waitTime_1 = 0
        if waitTime > 0 then
            waitTime_1 = 2
        end
        performWithDelay(node,function (  )
            if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end
        end,waitTime_1)
        

        performWithDelay(node,function()

            self:setGameSpinStage(STOP_RUN)

            self:updateQuestUI()
            
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

                --quest
                self:updateQuestBonusRespinEffectData()

                --结束
                self:reSpinEndAction()
                
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
                self.m_isWaitingNetworkData = false

                return
            end

           
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            --    dump(self.m_runSpinResultData,"m_runSpinResultData")
            

            self:checkRemoveNotNeedTipNode()
            self:createRespinJackPotTipNode()

            -- 移除火焰特效 
            self:removeAllFir()
            -- 移除炸弹
            self:removeAllBoom()
            --继续
            self:runNextReSpinReel()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            
            node:removeFromParent()

        end,waitTime)
    end,waitBulingTime)

end

function CodeGameScreenCharmsMachine:createFireNode(indexNum )
    local fixPos = self:getRowAndColByPosForSixRow(indexNum)
    local name = self.m_runSpinResultData.p_selfMakeData.unlock[tostring(fixPos.iY)] - fixPos.iX + 1
    
    if name < 0 and name > 6 then
        print("buduilelelele")
    end

    local pos = cc.p(self:getTarSpPos(indexNum))
    local fixY = fixPos.iX

    for i=2,name do
        local fir = util_createAnimation("Charms_baozha_zhayao.csb")  
        self:findChild("Node_2"):addChild(fir,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
        table.insert( self.m_FirList, fir )
        fir:setPosition(pos.x,pos.y + (self.m_SlotNodeH * (i - 1)))
        fir:setVisible(false)
        local posFireBoom = cc.p(pos.x,pos.y + (self.m_SlotNodeH * (i - 1)))
        performWithDelay(self,function()
            fir:setVisible(true)
            gLobalSoundManager:playSound("CharmsSounds/music_Charms_Respin_Muzhang_Baozha.mp3")
            fir:playAction("actionframe",false,function()
                fir:setVisible(false)
            end)

            local m_SymbolMatrix = self:getSymbolMatrixList()

            for iRow = 1, self.m_iReelRowNum do
                if iRow == (fixY + (i - 1)) then
                    local symbolType = m_SymbolMatrix[iRow][fixPos.iY]
    
                    if symbolType == self.SYMBOL_UNLOCK_SYMBOL or self:getUpReelsMaxRow(fixPos.iY ,iRow) then


                        local index = self:getPosReelIdx(iRow ,fixPos.iY)
                        
                        self:removeOneRespinJackPotTipNode(index )
                        local isHide_1 = false
                        local isHide_2 = false
                        if type(self.m_lockList[index + 1]) ~= "number" then
                            isHide_1 = true
                        end
                        -- 解锁轮盘
                        self:removeLoclNodeForIndex(index)

                        if type(self.m_lockList[index + 1]) == "number" then
                            isHide_2 = true
                        end 

                        if isHide_1 and isHide_2 then
                            fir:setVisible(false)

                            local firBoom = util_createAnimation("Charms_dangban.csb")  
                            self:findChild("Node_2"):addChild(firBoom,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
                            
                            firBoom:setPosition(posFireBoom)
                            firBoom:playAction("actionframe",false,function()
                                firBoom:removeFromParent()
                            end) 
                        end 
                        -- 显示新轮盘  -2的
                        self:showOneUnLockUpSymbolFromColAndRow(fixPos.iY,iRow,symbolType )
        
                    end
                end
                
            end 

        end,0.16 * i )
    end
end

function CodeGameScreenCharmsMachine:checkBoomReels()
    -- 是否播放炸开轮盘的动画

    local time = 0
    local fishNum = 0
    local dealyTime = 3
    local BoomCreateTime = 0
    local BoomShowtime = 1
    local BoomFireShowtime = 0
        
    local fish = self.m_runSpinResultData.p_selfMakeData.fish

    if fish and #fish > 0 then
        fishNum = #fish

        for i,v in ipairs(fish) do
            local pos =  self:getTarSpPos(v )
            local Boom =  util_spineCreate("Socre_Charms_Boom1", true, true) -- util_createAnimation("Socre_Charms_Boom1.csb")  --
            util_spinePlay(Boom,"idleframe",true)
            -- Boom:playAction("idleframe",true)

            self:findChild("Node_2"):addChild(Boom,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
            Boom.index = v
            Boom:setPosition(cc.p(pos))
            

            table.insert( self.m_BoomList, Boom )

            if i == fishNum then
                local fireReelsPos = self:getRowAndColByPosForSixRow(v)
                local fireNum = self.m_runSpinResultData.p_selfMakeData.unlock[tostring(fireReelsPos.iY)] - fireReelsPos.iX + 1
                BoomFireShowtime = BoomFireShowtime  + (0.16 * fireNum) 
            end
            
        end 

        performWithDelay(self,function()

            for i,v in ipairs(fish) do
                local indexNum = v
                local indexid = i
                

                    -- 炸弹炸开
                    
                    gLobalSoundManager:playSound("CharmsSounds/music_Charms_Respin_Boom_Baozha_yinxian.mp3")
                    
                    util_spinePlay(self.m_BoomList[indexid],"actionframe",false)
                    util_spineFrameCallFunc(self.m_BoomList[indexid],"actionframe","BoomEnd",function()
                        gLobalSoundManager:playSound("CharmsSounds/music_Charms_Respin_Boom_Baozha.mp3")
                        -- 显示烟火
                        self:createFireNode(indexNum )
                    end)


                
            end
        end,BoomCreateTime)

        time = dealyTime + BoomCreateTime + BoomShowtime
    end

    return time
end

function CodeGameScreenCharmsMachine:hidAllUnLockUpSymbol()
    local nodeList = self.m_respinView.m_respinNodes

    -- 双格特殊处理
    local bigBonusPositions =  self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}


    local m_SymbolMatrix = self:getSymbolMatrixList()
    for k,v in pairs(nodeList) do
        local symbolType =  m_SymbolMatrix[v.p_rowIndex][v.p_colIndex]
        if symbolType <= self.SYMBOL_NULL_LOCK_SYMBOL 
            or self:getUpReelsMaxRow(v.p_colIndex ,v.p_rowIndex) then -- 双格特殊处理

                    v.m_clipNode:setVisible(false)
        end

        -- 如果有双格信号特殊处理
        local index = self:getPosReelIdx(v.p_rowIndex,v.p_colIndex)
        for kv,vv in pairs(bigBonusPositions) do
            if vv == index then
                v.m_clipNode:setVisible(false)
            end 
        end

        if math.abs( v.p_symbolType ) == self.SYMBOL_FIX_SYMBOL_DOUBLE 
            or math.abs( v.p_symbolType ) == self.SYMBOL_FIX_MINOR_DOUBLE  then
            if self:isInsetDoubleSymbolInEndChip()  then
                v.m_clipNode:setVisible(true)
            else
                v.m_clipNode:setVisible(false)
            end
        end
    end


    local cleanNodelist =   self.m_respinView:getAllCleaningNode()
    for k,v in pairs(cleanNodelist) do
        if v.p_symbolType <= self.SYMBOL_NULL_LOCK_SYMBOL 
            or self:getUpReelsMaxRow(v.p_cloumnIndex ,v.p_rowIndex) then     
                    
                    v:setVisible(false)
        end

        -- 如果有双格信号特殊处理
        local index = self:getPosReelIdx(v.p_rowIndex,v.p_cloumnIndex)
        for kv,vv in pairs(bigBonusPositions) do
            if vv == index then
                v:setVisible(false)
            end 
        end

        if math.abs( v.p_symbolType ) == self.SYMBOL_FIX_SYMBOL_DOUBLE
            or math.abs( v.p_symbolType ) == self.SYMBOL_FIX_MINOR_DOUBLE  then
            if self:isInsetDoubleSymbolInEndChip()  then
                v:setVisible(true)
            else
                v:setVisible(false)
            end
        end
        

    end

 
end

function CodeGameScreenCharmsMachine:showOneUnLockUpSymbolFromColAndRow(icol,irow,symboltype,syindex )
    local m_SymbolMatrix = self:getSymbolMatrixList()
    local bigBonusPositions =  self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    local nodeList = self.m_respinView.m_respinNodes
    for k,v in pairs(nodeList) do
        
        --  symboltype 是 self.SYMBOL_FIX_SYMBOL_DOUBLE 的情况只有在respin开始时的动画结束时才会出现
        --  self.SYMBOL_FIX_SYMBOL_DOUBLE 目前只有一个所以可以真么
        if math.abs( symboltype ) == self.SYMBOL_FIX_SYMBOL_DOUBLE 
            or math.abs( symboltype ) == self.SYMBOL_FIX_MINOR_DOUBLE  then
        
                if (v.p_symbolType == self.SYMBOL_FIX_SYMBOL_DOUBLE or v.p_symbolType == self.SYMBOL_FIX_MINOR_DOUBLE )  and  v.p_colIndex == icol and v.p_rowIndex == irow   then
                    v.m_clipNode:setVisible(true)
                    --利用两个小块的背景来显示双格块的背景
                    for kk,vk in pairs(nodeList) do
                        -- 如果有双格信号特殊处理
                        local index = self:getPosReelIdx(vk.p_rowIndex,vk.p_colIndex)
                        for kv,vv in pairs(bigBonusPositions) do
                            if vv == index then
                                vk.m_clipNode:setVisible(true)
                            end 
                        end
                    end

                    break
                end

        else
            local symbolType =  m_SymbolMatrix[v.p_rowIndex][v.p_colIndex]
            if symbolType == symboltype and v.p_colIndex == icol and v.p_rowIndex == irow   then
                v.m_clipNode:setVisible(true)
                break
            end
        end  
                    
            
        
    end

    local cleanNodelist = self.m_respinView:getAllCleaningNode()

    for k,v in pairs(cleanNodelist) do

        if math.abs( symboltype ) == self.SYMBOL_FIX_SYMBOL_DOUBLE 
            or math.abs( symboltype ) == self.SYMBOL_FIX_MINOR_DOUBLE  then
               

        else
            if v.p_symbolType == symboltype and v.p_cloumnIndex == icol and v.p_rowIndex == irow   then
                v:setVisible(true)
                break
            end

        end
       
    end


    for k,v in pairs(cleanNodelist) do

        local index = self:getPosReelIdx(v.p_rowIndex,v.p_cloumnIndex)
        for kv,vv in pairs(bigBonusPositions) do

            if syindex then
                if syindex == vv then
                    if math.abs( v.p_symbolType ) == self.SYMBOL_FIX_SYMBOL_DOUBLE 
                        or math.abs( v.p_symbolType ) == self.SYMBOL_FIX_MINOR_DOUBLE  then
                            v:setVisible(true)
                            break
                    end
                end
            else
                if vv == index then 
                    if math.abs( v.p_symbolType ) == self.SYMBOL_FIX_SYMBOL_DOUBLE 
                        or math.abs( v.p_symbolType ) == self.SYMBOL_FIX_MINOR_DOUBLE  then
                            v:setVisible(true)
    
                    else
                        v:setVisible(false)
                    end
    
                end 

            end
           
            
        end
    end


    
end

function CodeGameScreenCharmsMachine:showReSpinStart(func)
    
    gLobalSoundManager:stopAllAuido() 

    performWithDelay(self,function()
        
         

        gLobalSoundManager:playSound("CharmsSounds/music_Charms_Open_View.mp3")
        
        self:clearCurMusicBg()
        self:showLocalDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func)
        --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
    end,0)
    
end


--ReSpin开始改变UI状态
function CodeGameScreenCharmsMachine:changeReSpinStartUI(respinCount)
   
    
    self.m_jackPotBar:setVisible(false)
    self.m_RSjackPotBar:setVisible(true)
    -- 隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)

    self.m_oldMan:setVisible(false)
    self:runCsbAction("actionframe1")
    self.m_respinSpinbar:setVisible(true)
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
    
end

--ReSpin刷新数量
function CodeGameScreenCharmsMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinSpinbar:changeRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenCharmsMachine:changeReSpinOverUI()

    
end

function CodeGameScreenCharmsMachine:showReSpinOver(coins,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showLocalDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER,ownerlist,func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end


function CodeGameScreenCharmsMachine:showRespinOverView(effectData)


    gLobalSoundManager:playSound("CharmsSounds/music_Charms_open_over_View.mp3")

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()

        self:overGameGuoChangView(function()
            self.m_jackPotBar:setVisible(true)
            self.m_RSjackPotBar:setVisible(false)
            self.m_oldMan:setVisible(true)

            self:respinChangeReelGridCount(NORMAL_ROW_COUNT)
            self.m_iReelRowNum = NORMAL_ROW_COUNT

            self.m_lightScore = 0
            self:resetMusicBg() 
            self:runCsbAction("idle")
            self:findChild("Node_respin_Lines"):setVisible(false)
            -- 去除锁定块
            self:removeAllLockNode()
            self.m_respinSpinbar:setVisible(false)

            self:removeAllRespinJackPotTipNode()

            self:setReelSlotsNodeVisible(true)
            self:removeRespinNode()
        end,function()
            for k,v in pairs(self.m_respinJackpotBgName) do
                self:findChild(v):setVisible(false) 
                local jpBg =  self:findChild(v):getChildByName("JackPotBg")
                if jpBg then
                    jpBg:runCsbAction("animation0",true)
                end
                
            end
            
            self.m_isPlayRespinEnd = false
            self:triggerReSpinOverCallFun(self.m_lightScore)

            if self.m_bProduceSlots_InFreeSpin then
                self.m_baseFreeSpinBar:setVisible(true)
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin") 
            else
                self.m_progress:setVisible(true)
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
            end
            
            if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                self:createRandomReelsNode()
                self:MachineRule_checkTriggerFeatures() 
                self:addNewGameEffect()
            end
        end)
 
    end)

    
    -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},332)
end


-- --重写组织respinData信息
function CodeGameScreenCharmsMachine:getRespinSpinData()
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

-- 获取到炸弹的轮盘位置
function CodeGameScreenCharmsMachine:getBoomRespinReelsButStored()
    local BoomList = {}
    if self.m_runSpinResultData.p_selfMakeData then
        local storedIcons = self.m_runSpinResultData.p_selfMakeData.fish or {}
        for k,v in pairs(storedIcons) do
            local fixPos = self:getRowAndColByPosForSixRow(v)
            table.insert( BoomList,  fixPos )
        end
    end
    return BoomList
end


---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCharmsMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_soundNode then
        self.m_soundNode:stopAllActions()
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
        -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_last_win_over.mp3",false)
    end

    self.m_isInFreeGames = false
    local iswait = false

    return iswait -- 用作延时点击spin调用
end

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function CodeGameScreenCharmsMachine:BaseMania_updateCollect(addCount,index,totalCount)
    if not index then
        index=1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index])=="table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

function CodeGameScreenCharmsMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount 
        self:BaseMania_updateCollect(addCount,1,totalCount)
    end

end

function CodeGameScreenCharmsMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList={}
    --默认总数
    
    self.m_collectDataList[1] = CollectData.new()
    self.m_collectDataList[1].p_collectTotalCount = 150
    self.m_collectDataList[1].p_collectLeftCount = 150
    self.m_collectDataList[1].p_collectCoinsPool = 0
    self.m_collectDataList[1].p_collectChangeCount = 0
    
end

----
--- 处理spin 成功消息
--
function CodeGameScreenCharmsMachine:checkOperaSpinSuccess( param )

    
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or (self.m_fsReelDataIndex > 0 and spinData.action == "FEATURE")  then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self.m_currFeature = {}
        if self.m_runSpinResultData.p_features then
            for i=1,#self.m_runSpinResultData.p_features do
                table.insert(self.m_currFeature,self.m_runSpinResultData.p_features[i]) 
            end
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenCharmsMachine:playEffectNotifyNextSpinCall()

    -- self:setMaxMusicBGVolume()


    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
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
        delayTime = delayTime + self:getWinCoinTime()
        -- FreeSpin玩法 第一次多滚
        if self.m_isFreespinStart then
            delayTime = 0.5
        end

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end
    
end

function CodeGameScreenCharmsMachine:requestSpinResult()

    self:clearSpinLog()

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
    self:getCurrSpinMode() ~= RESPIN_MODE
    then
       
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId = 
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenCharmsMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet() 
    if  betCoin == nil or betCoin >= self.m_BetChooseGear then
        --self.m_iBetLevel = 1
        return 1
    else
        return 0        
        --self.m_iBetLevel = 0
    end
end

function CodeGameScreenCharmsMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or 
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and 
    self:getGameSpinStage() ~= IDLE ) or 
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or 
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenCharmsMachine:showBonusMap(callback, nodePos)
    self.m_map:appear(callback, nodePos)
end

function CodeGameScreenCharmsMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
        
        gLobalSoundManager:playSound("CharmsSounds/music_Charms_enter.mp3")
        scheduler.performWithDelayGlobal(function ()
            if not self.m_isInFreeGames then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenCharmsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    self.m_iBetLevel = self:updateBetLevel()
    self.m_jackPotBar:updateJackpotInfo()
    self.m_RSjackPotBar:updateJackpotInfo()
    self.m_progress:setPercent(self.m_collectProgress)
    if self.m_iBetLevel == 1 then
        self.m_progress:idle()
    else
        self.m_progress:lock(self.m_iBetLevel)
    end
    local data = {}
    data.bonusPath = self.m_bonusPath
    data.nodePos = self.m_nodePos
    self.m_map:initMapUI(data)

    if self.m_bClassicReconnect == true  then
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
            self.m_classicMachine = util_createView("GameScreenClassicSlots" , data)
            self:addChild(self.m_classicMachine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
            if globalData.slotRunData.machineData.p_portraitFlag then
                self.m_classicMachine.getRotateBackScaleFlag = function() return false end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_classicMachine})
        end
    end
end

function CodeGameScreenCharmsMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self:updateBetLevel()
        if self.m_iBetLevel ~= perBetLevel then
            self.m_iBetLevel = perBetLevel
            if perBetLevel == 0 then
                self.m_progress:lock(self.m_iBetLevel)
            else
                self.m_progress:unlock(self.m_iBetLevel)
                gLobalSoundManager:playSound("CharmsSounds/Charms_unlock_hightLow_bet.mp3")
            end
        end
        

    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

    gLobalNoticManager:addObserver(self,function(self,params)
        if self.m_bHaveBonusGame or self.m_isRunningEffect or self:getGameSpinStage() > IDLE then
            return
        end
        self:showBonusMap()
    end,"SHOW_BONUS_MAP")
    
end

function CodeGameScreenCharmsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenCharmsMachine:resetProgress()
    self.m_progress:setPercent(0)
end

function CodeGameScreenCharmsMachine:initGameStatusData(gameData)

    if gameData.collect ~= nil then
        self.m_collectProgress = self:getProgress(gameData.collect[1])
    else
        self.m_collectProgress = 0
    end
    
    self.m_nodePos = gameData.gameConfig.extra.node
    if self.m_nodePos == nil then
        self.m_nodePos = 0
    end
    self.m_bonusPath = gameData.gameConfig.init.bonusPath
    
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenCharmsMachine:getProgress(collect)
    local collectTotalCount = collect.collectTotalCount
    local collectCount = nil

    if collectTotalCount ~= nil then
        collectCount = collect.collectTotalCount - collect.collectLeftCount
    else
        collectTotalCount = collect.p_collectTotalCount
        collectCount = collect.p_collectTotalCount - collect.p_collectLeftCount
    end

    local percent = collectCount / collectTotalCount * 100
    return percent
end
-- ------------玩法处理 -- 

---
-- 处理spin 结果轮盘数据
--
function CodeGameScreenCharmsMachine:MachineRule_network_ProbabilityCtrl()
    
    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex=1,rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex=1,colCount do
            local symbolType = rowDatas[colIndex]
            self.m_stcValidSymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
        
    end

    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    local iColumn = self.m_iReelColumnNum
    local iRow = #self.m_runSpinResultData.p_reels -- self.m_iReelRowNum

    for colIndex=1,iColumn do
        
        local rowIndex= 1 + self:getRespinAddNum()


        while true do
            if rowIndex > iRow then
                break
            end
            local symbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            -- 判断是否有大信号内容
            if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then

                local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
                
                
                local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                if colDatas == nil then
                    colDatas = {}
                    self.m_bigSymbolColumnInfo[colIndex] = colDatas
                end           

                colDatas[#colDatas + 1] = bigInfo     

                local symbolCount = self.m_bigSymbolInfos[symbolType]

                local hasCount = 1

                bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex

                for checkIndex = rowIndex + 1,iRow do
                    local checkType = self.m_stcValidSymbolMatrix[checkIndex][colIndex]
                    if checkType == symbolType then
                        hasCount = hasCount + 1

                        bigInfo.changeRows[#bigInfo.changeRows + 1] = checkIndex
                    end
                end

                if symbolCount == hasCount or rowIndex > 1 then  -- 表明从对应索引开始的
                    bigInfo.startRowIndex = rowIndex
                else

                    bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                end

                rowIndex = rowIndex + hasCount - 1  -- 跳过上面有的

            end -- end if ~= nil 

            rowIndex = rowIndex + 1
        end

    end

end

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenCharmsMachine:MachineRule_network_InterveneSymbolMap()

end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCharmsMachine:addSelfEffect()

    if self.m_iBetLevel == 1 and globalData.slotRunData.currSpinMode ~= RESPIN_MODE and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if self:isFixSymbol(node.p_symbolType) then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end
    end    

    if self.m_collectList and #self.m_collectList > 0 then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT

        --是否触发收集小游戏
        if self:BaseMania_isTriggerCollectBonus() then -- true or
            -- local selfEffect = GameEffectData.new()
            -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            -- selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
            self.m_bHaveBonusGame = true
        end
    end
end

function CodeGameScreenCharmsMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index=1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCharmsMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:collectCoin(effectData)
    -- elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
    --     self:showEffect_Bonus(effectData)
    end
    
	return true
end

function CodeGameScreenCharmsMachine:collectCoin(effectData)

    local endPos = self.m_progress:getCollectPos()
    gLobalSoundManager:playSound("CharmsSounds/sound_Charms_collect_coin.mp3")
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local coins = self:getSlotNodeBySymbolType(self.FLY_COIN_TYPE)
        if i == 1 then
            coins.m_isLastSymbol = true
        end
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        -- coins:setScale(self.m_machineRootScale)
        coins:setPosition(newStartPos)
        
        local delayTime = 0
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true or 
            self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            delayTime = 0.5
        end
        
        coins:runAnim("shouji")
        performWithDelay(self, function()
            local CoinsNdoe = coins
            if self.m_bHaveBonusGame ~= true and CoinsNdoe.m_isLastSymbol == true then
                performWithDelay(self, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, delayTime)
            end
            local flyParticleNode = cc.Node:create()
            local particle = cc.ParticleSystemQuad:create("partcial/Charms_Bonus_shouji_1.plist")
            flyParticleNode:addChild(particle)
            self:addChild(flyParticleNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
            particle:setPositionType(0)
            particle:setDuration(0.6)
            particle:setPosition(0,0)
            flyParticleNode:setPosition(newStartPos)
            local pecent = self:getProgress(self:BaseMania_getCollectData())

            local actLsit = {}
            actLsit[#actLsit + 1] = cc.CallFunc:create( function()

                local CoinsNdoe_1 = CoinsNdoe
                local actList_3 = {}
                actList_3[#actList_3 + 1] = cc.CallFunc:create(function()
                    util_playFadeInAction(CoinsNdoe_1,0.2)
                end)
                actList_3[#actList_3 + 1] = cc.DelayTime:create(0.2)
                actList_3[#actList_3 + 1] = cc.ScaleTo:create(0.3,0.6)
                CoinsNdoe:runAction(cc.Sequence:create(actList_3))            
            end)
            actLsit[#actLsit + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
            actLsit[#actLsit + 1] = cc.CallFunc:create( function()
                    if CoinsNdoe.m_isLastSymbol == true then
                        self.m_progress:updatePercent(pecent)
                        gLobalSoundManager:playSound("CharmsSounds/sound_Charms_fanhui.mp3")
                        if self.m_bHaveBonusGame == true and CoinsNdoe.m_isLastSymbol == true then
                            self:clearCurMusicBg()
                            performWithDelay(self, function()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                                self.m_bHaveBonusGame = false
                            end, 4.1)
                        end
                    end
                
            end)
            actLsit[#actLsit + 1] = cc.CallFunc:create(function()
                
                    CoinsNdoe:removeFromParent()
                    local symbolType = CoinsNdoe.p_symbolType
                    self:pushSlotNodeToPoolBySymobolType(symbolType, CoinsNdoe)
            end)
            CoinsNdoe:runAction(cc.Sequence:create(actLsit ))



            local actList_2 = {}
            actList_2[#actList_2 + 1] = cc.BezierTo:create(0.5,{cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
            actList_2[#actList_2 + 1] = cc.CallFunc:create(function()
                particle:stopSystem()
                performWithDelay(particle,function()
                    flyParticleNode:removeFromParent()
                end,1)
            end)
            flyParticleNode:runAction(cc.Sequence:create(actList_2))

        end, delayTime)
        table.remove(self.m_collectList, i)
    end
end

function CodeGameScreenCharmsMachine:checkCharmsYuGaoAnim()
    local feature =  self.m_currFeature 
    local bFree   = feature and #feature > 1 and feature[2] == 1
    local bRespin = feature and #feature > 1 and feature[2] == 3
    local bFeature     = bFree or bRespin
    local randomNum    = math.random(1,10)
    local bProbability = 3 >= randomNum
    self.m_isPlayWinningNotice = bFeature and bProbability
end
--设置bonus scatter 信息
function CodeGameScreenCharmsMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if not self.m_isPlayWinningNotice and bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenCharmsMachine:MachineRule_checkTriggerFeatures()
    if self.m_fsReelDataIndex ~= 0 or self:getCurrSpinMode() == RESPIN_MODE then
        return
    end
    
    if self.m_runSpinResultData.p_features ~= nil and 
        #self.m_runSpinResultData.p_features > 0 then
        
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        
        local featureID = self.m_runSpinResultData.p_features[featureLen]
        table.remove(self.m_runSpinResultData.p_features, featureLen)
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

                if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_newTrigger ~= true then
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

function CodeGameScreenCharmsMachine:checkNetDataFeatures()

    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    
    local featureId = featureDatas[#featureDatas]
    table.remove(featureDatas, #featureDatas)
    if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

        -- 添加freespin effect
        local freeSpinEffect = GameEffectData.new()
        freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
        freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

        if self.checkControlerReelType and self:checkControlerReelType( ) then
            globalMachineController.m_isEffectPlaying = true
        end
        self.m_isRunningEffect = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false})

        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

        for lineIndex = 1, #self.m_initSpinData.p_winLines do
            local lineData = self.m_initSpinData.p_winLines[lineIndex]
            local checkEnd = false
            local iconPos = lineData.p_iconPos -- 添加判空处理
            if iconPos == nil then
                self.m_initSpinData.p_winLines[lineIndex].p_iconPos = {}
            end
            for posIndex = 1 , #lineData.p_iconPos do
                local pos = lineData.p_iconPos[posIndex] 

                local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                local colIndex = pos % self.m_iReelColumnNum + 1

                local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    checkEnd = true
                    local lineInfo = self:getReelLineInfo()
                    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                    for addPosIndex = 1 , #lineData.p_iconPos do

                        local posData = lineData.p_iconPos[addPosIndex]
                        local rowColData = self:getRowAndColByPos(posData)
                        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                    end

                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                    self.m_reelResultLines = {}
                    self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                    break
                end
            end
            if checkEnd == true then
                break
            end

        end
        --更新fs次数ui 显示
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})

        -- self:sortGameEffects()
        -- self:playGameEffect()

    elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
    elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
    elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        
        -- if self.m_initFeatureData.p_status=="CLOSED" then
        --     return
        -- end

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

        -- 添加bonus effect
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

        self.m_isRunningEffect = true

        if self.checkControlerReelType and self:checkControlerReelType( ) then
            globalMachineController.m_isEffectPlaying = true
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false})


        for lineIndex = 1, #self.m_initSpinData.p_winLines do
            local lineData = self.m_initSpinData.p_winLines[lineIndex]
            local checkEnd = false
            for posIndex = 1 , #lineData.p_iconPos do
                local pos = lineData.p_iconPos[posIndex] 

                local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                local colIndex = pos % self.m_iReelColumnNum + 1

                local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    checkEnd = true
                    local lineInfo = self:getReelLineInfo()
                    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                    for addPosIndex = 1 , #lineData.p_iconPos do

                        local posData = lineData.p_iconPos[addPosIndex]
                        local rowColData = self:getRowAndColByPos(posData)
                        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                    end

                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                    self.m_reelResultLines = {}
                    self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                    break
                end
            end
            if checkEnd == true then
                break
            end

        end

        -- self:sortGameEffects()
        -- self:playGameEffect()


    end
    

end

--调整label大小 info={label=cc.label,sx=1,sy=1} length=宽度限制 otherInfo={info1,info2,info3,...}
function CodeGameScreenCharmsMachine:updateLabelSize(info,length,otherInfo)
    local width=info.label:getContentSize().width
    local scale=length/width
    if width<=length then
        scale=1
    end
    info.label:setScaleX(scale*(info.sx or 1))
    info.label:setScaleY(scale*(info.sy or 1))
    if otherInfo and #otherInfo>0 then
        for k,orInfo in ipairs(otherInfo) do
            orInfo.label:setScaleX(scale*(orInfo.sx or 1))
            orInfo.label:setScaleY(scale*(orInfo.sy or 1))
        end
    end
end

-- 在触发repsin时改变轮盘最终数据
---
-- 将最终轮盘放入m_reelSlotsList
--
function CodeGameScreenCharmsMachine:setLastReelSymbolList()
    self:checkCharmsYuGaoAnim()
    --- 将最终生成的盘面加入进去


    local iColumn = self.m_iReelColumnNum
    -- local iRow = self.m_iReelRowNum


    for cloumIndex=1,iColumn do
        local nodeCount = self.m_reelRunInfo[cloumIndex]:getReelRunLen()
        local columnData = self.m_reelColDatas[cloumIndex]
        local iRow = columnData.p_showGridCount
        
        if iRow == nil then  -- fix bug 可能是因为轮盘丢块导致的 2018-12-20 11:10:27
            iRow = self.m_iReelRowNum
        end

        local cloumnDatas = {}
        self.m_reelSlotsList[cloumIndex] = cloumnDatas

        local startIndex = nodeCount  -- 从假数据后面开始赋值
        
        for i=1,iRow  do
            local symbolValue = self.m_stcValidSymbolMatrix[i][cloumIndex] -- 循环提取每行中的某列¸
            local slotData = self:getSlotsReelData()

            slotData.m_isLastSymbol = true
            slotData.m_rowIndex = i
            slotData.m_columnIndex = cloumIndex
            slotData.p_symbolType = symbolValue--symbolValue.enumSymbolType
            
            if self.m_bigSymbolInfos[slotData.p_symbolType] ~= nil then
                slotData.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2
                
                local symbolCount = self.m_bigSymbolInfos[slotData.p_symbolType]

                symbolCount = symbolCount - 1
                -- 将前面的也进行赋值
                if i == 1 then  -- 检测后面是否足够数量展示 symbol count
                    for checkIndex=2,iRow do
                        local checkType = self.m_stcValidSymbolMatrix[checkIndex][cloumIndex]
                        if symbolValue == checkType then
                            symbolCount = symbolCount - 1
                        else
                            break
                        end
                    end
                    -- 将前面需要变为大信号的地方全部设置为大信号，这样滚动时如果最终信号组跨列 那么现实也是正常的
                    if symbolCount > 0 then
                        for addIndex=1,symbolCount do
                            local addSlotData = self:getSlotsReelData()
                            addSlotData.m_isLastSymbol = true
                            addSlotData.m_rowIndex = 1 - addIndex  -- 这里会是负数，因为创建长条的起始位置是从这里开始的， 所以针对于第一行是负数
                            addSlotData.m_columnIndex = cloumIndex
                            addSlotData.p_symbolType = symbolValue

                            slotData.m_showOrder = self:getBounsScatterDataZorder(slotData.p_symbolType )

                            cloumnDatas[startIndex + i - addIndex] = addSlotData
                        end
                    end
                end


            else
                slotData.m_showOrder = self:getBounsScatterDataZorder(slotData.p_symbolType )
            end

            cloumnDatas[startIndex + i] = slotData
        end

    end

end



function CodeGameScreenCharmsMachine:getSymbolMatrixList()
    
    local m_SymbolMatrix = {}

    for row=1,6 do
        m_SymbolMatrix[row] = {}
       for col=1,5 do
            m_SymbolMatrix[row][col] = "null"
       end
    end

    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex=1,rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex=1,colCount do
            local symbolType = rowDatas[colIndex]
            m_SymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
        
    end

    return  m_SymbolMatrix
end

function CodeGameScreenCharmsMachine:getRunningInfo()

    

    local m_SymbolMatrix = self:getSymbolMatrixList()

    local doubleSymbol = self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}
    

    local removeList = nil
    local removeIndex = nil

    local upLockInfoList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = m_SymbolMatrix[iRow][iCol]
            if symbolType < self.SYMBOL_UNLOCK_SYMBOL then

                local value = {}
                value.icol = iCol
                value.irow = iRow
                value.index = self:getPosReelIdx(iRow ,iCol)
                value.symboltype = symbolType
                if math.abs(value.symboltype) == self.SYMBOL_FIX_SYMBOL  then
                    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) --获取分数（网络数
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    score = score * lineBet
                    score = util_formatCoins(score, 3)

                    value.coins = score or 000000
                end
                table.insert( upLockInfoList,value )
            end

            -- 大块未解锁状态 给大块赋值为 bigBonusPositions 数组1 位置的信息
            if not self:isInsetDoubleSymbolInEndChip() then
                local index = self:getPosReelIdx(iRow, iCol)
                local vv = doubleSymbol[1]
                if vv == index  then
                    removeIndex = #upLockInfoList
                    if removeIndex == 0 then
                        removeIndex = 1
                    end

                    removeList = {}
                    removeList.icol = iCol
                    removeList.irow = iRow
                    removeList.index = self:getPosReelIdx(iRow ,iCol)
                    removeList.symboltype = symbolType
                    if math.abs(symbolType) == self.SYMBOL_FIX_SYMBOL then
                        removeList.symboltype = self.SYMBOL_FIX_SYMBOL_DOUBLE
                        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) --获取分数（网络数
                        local lineBet = globalData.slotRunData:getCurTotalBet()
                        score = score * lineBet
                        score = util_formatCoins(score, 3)
                        removeList.coins = score or 000000
                    elseif math.abs(symbolType) == self.SYMBOL_FIX_MINOR then 
                        removeList.symboltype = self.SYMBOL_FIX_MINOR_DOUBLE

                    end
                end

            end

        end
    end

    
    for i = #upLockInfoList,1,-1 do
        local chipNode = upLockInfoList[i]
        local isIn = false
        local index = self:getPosReelIdx(chipNode.irow, chipNode.icol)
        for kk,vv in pairs(doubleSymbol) do
            if vv == index  then
                table.remove( upLockInfoList, i )
            end
        end
    end

    -- 把双格块塞进去
    if removeIndex and removeList then
        table.insert( upLockInfoList,removeIndex,removeList ) 
    end



    return upLockInfoList
end

function CodeGameScreenCharmsMachine:isInArray( array,value)
   local isIn = false
   for k,v in pairs(array) do
       if v == value then
            isIn = true
            break
       end

   end

   return isIn
end

function CodeGameScreenCharmsMachine:getFSRunningInfo()

    local m_SymbolMatrix = self:getSymbolMatrixList()
    local indexList = {} -- {5,6,7,8,9} -- 只在中间位置显示
    local isRespinData = false
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, #m_SymbolMatrix do
           if m_SymbolMatrix[iRow][iCol] == "null" then
                isRespinData = true
                break
           end
           
        end
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
           local posindex = self:getPosReelIdx(iRow ,iCol)
           if not isRespinData then
                posindex = posindex - 15
           end
           table.insert( indexList, posindex )
        end
    end

    local chooseSum = math.random( 3, 7 )

    for i=1,chooseSum do
        local removeIndex = math.random( 1, #indexList )
        table.remove( indexList, removeIndex )
    end

    local upLockInfoList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = m_SymbolMatrix[iRow][iCol]
            local posINdex =  self:getPosReelIdx(iRow ,iCol)
            if not isRespinData then
                posINdex = posINdex - 15
           end
            if self:isInArray( indexList,posINdex) then

                local value = {}
                value.icol = iCol
                value.irow = iRow
                value.index = posINdex
                value.symboltype = symbolType
                if math.abs(value.symboltype) == self.SYMBOL_FIX_SYMBOL  then
                    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) --获取分数（网络数
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    score = score * lineBet
                    score = util_formatCoins(score, 3)

                    value.coins = score or 000000
                end
                table.insert( upLockInfoList,value )
            end
        end
    end

    return upLockInfoList
end


--[[
    @desc: respin触发，飞行小块特效
    --@triggerFunc: 最后一个小块落地调用
]]
function CodeGameScreenCharmsMachine:createRunningSymbolAnimation( triggerFunc )
    
    local netData = self:getRunningInfo()
    if #netData <= 0 then
        if triggerFunc then
            triggerFunc()
        end
        return
    end

    local createdNetIndex = 1
    local createdNetMaxIndex = #netData
    local createdrandomIndex = 1
    
    local flayNode = cc.Node:create()
    flayNode:setName("flayNode")
    flayNode:setPosition(0,0)
    self:findChild("Node_2"):addChild(flayNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 13) 

    self.m_DouDongid =  gLobalSoundManager:playSound("CharmsSounds/music_Charms_DouDong.mp3")

    self:runCsbAction("dou_chuxian",false,function()
        self:runCsbAction("dou_idle",true)
    end)

    schedule(flayNode,function ()
        local iscreate = math.random( 1,2 )
        if iscreate == 1 then
            local  Createnum = math.random( 3,4 )
            for i=1,Createnum do
                local num = math.random( 1,6 )

                if createdNetIndex >  createdNetMaxIndex then
                    print("真的该结束了 不应该创建了 ") 
                    return 
                end

                createdrandomIndex = createdrandomIndex + 1
                local show = false

                local begin =  (createdrandomIndex % 10)
                if begin == 0 and createdrandomIndex > 5 and createdNetIndex <=  createdNetMaxIndex  then
                    show = true
                end

                local data = {}
                if show then -- 根据网络数据创建
                    
                    print("createdrandomIndex ======= "..createdrandomIndex)

                    data.symboltype = netData[createdNetIndex].symboltype  
                    data.machine = self
                    if math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL or math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL_DOUBLE  then
                        data.coins = netData[createdNetIndex].coins 
                    end

                else -- 随机数据
                    data.symboltype = self:getRodomSymbolType()
                    data.machine = self
                    if math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL or math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL_DOUBLE  then
                        data.coins = self:getFlyNodeRandomCoins()
                    end
                end
                
                local moveSymbol = util_createView("CodeCharmsSrc.CharmsViewFlyNode",data)
                local xPos = display.width * 0.2 * (num - 1)
                local yPos = display.height
                moveSymbol:setPositionX(xPos)
                moveSymbol:setPositionY(yPos)
                flayNode:addChild(moveSymbol)
                local endPos = cc.p(xPos,0)
                local rand1 = math.random( 1,3 )
                local speed = 30 + rand1 * 0.5 * 30
                local func = nil

                if show then

                    -- 创建落地烟雾
                    local Smoke = util_createView("CodeCharmsSrc.CharmsViewSmoke") 
                    flayNode:addChild(Smoke)
                    if Smoke then
                        Smoke:setVisible(false)
                    end

                    
                    
                    local moveXDis = 0
                    if math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL_DOUBLE or math.abs(data.symboltype) == self.SYMBOL_FIX_MINOR_DOUBLE  then
                        moveXDis = self.m_SlotNodeW/2
                    end
                    local roandomSymbolIndex =  netData[createdNetIndex].index  -- math.random( 1, 30) - 1
                    local nodePos = cc.p(self:getTarSpPos(roandomSymbolIndex ))
                    local targSpPos = cc.p(nodePos.x + moveXDis,nodePos.y) 
                    
                    endPos =  cc.p(targSpPos.x ,targSpPos.y ) 
                    moveSymbol:setPositionX(targSpPos.x)
                    Smoke:setPosition(endPos)

                    local netDataInfo = netData[createdNetIndex]
                    local endNetIndex = createdNetIndex
                    func = function()
                                print("dadadada========= "..endNetIndex)
                                gLobalSoundManager:playSound("CharmsSounds/music_Charms_Respin_Boom_Down.mp3")

                                release_print("  3944 begin ") 
                                Smoke:setVisible(true)
                                release_print("  3946 end ") 

                                Smoke:showAnimation(1,function()
                                    release_print("  3949 begin ") 
                                    if Smoke then
                                        Smoke:setVisible(false)
                                    end
                                    release_print("  3949 end ") 
                                end)
                                -- if netDataInfo.icol == 3 and netDataInfo.irow == 5 then 
                                --     print("dadadada")
                                -- end
                                dump(netDataInfo)

                                self:showOneUnLockUpSymbolFromColAndRow(netDataInfo.icol,netDataInfo.irow,netDataInfo.symboltype,netDataInfo.index )

                                if endNetIndex >= createdNetMaxIndex then
                                    print("真的该结束了 " ..roandomSymbolIndex..targSpPos.y ) 

                                    flayNode:stopAllActions()
                                    

                                    performWithDelay(self,function()
                                        self:runCsbAction("dou_xiaoshi")
  
                                        if triggerFunc then
                                            triggerFunc()
                                        end

                                        -- local actionList={}
                                        -- actionList[#actionList+1]=cc.FadeOut:create(1)
                                        -- actionList[#actionList+1]=cc.CallFunc:create(function()
                                        
                                        -- end)
                                        -- local seq=cc.Sequence:create(actionList)  
                                        -- flayNode:runAction(cc.RepeatForever:create(seq))  --???  3 好像是设置动画 但是设置了怎样的动画不太理解

                                        flayNode:removeFromParent()
                                    end,1)
                                    
                                end
                                print("真实数据移动到结束" ..roandomSymbolIndex..targSpPos.y ) 
                            end


                    createdNetIndex = createdNetIndex + 1
                end
                
                --print("endPos ----"..endPos.x)
                self:moveAction(moveSymbol,endPos,func,speed)

                
            end
        end
    end,0.1)



end

function CodeGameScreenCharmsMachine:moveFsAction( node,endPos,func,speed)
    local finalPos = cc.p(endPos.x,endPos.y) 
    local finalSpeed = speed
    local symbolNode = node
    local callFunc = func

    schedule(symbolNode,function ()
        local PosY = cc.p(symbolNode:getPosition()).y
        --print("-----endpos"..PosY)
        local needHeight = PosY - endPos.y
        if PosY <= finalPos.y or needHeight <= finalSpeed then
            if callFunc then
                symbolNode:setPosition(finalPos)
                symbolNode:stopAllActions()

                gLobalSoundManager:playSound("CharmsSounds/music_Charms_Fs_add_Bonus.mp3")
                
                symbolNode:runCsbAction("buling",false,function()
                    
                end)
                callFunc()
                
                return 
            end

            if symbolNode then
                symbolNode:setVisible(false)
            end

        end

        symbolNode:setPositionY(PosY - finalSpeed)
    end,0.01)
end

function CodeGameScreenCharmsMachine:moveAction( node,endPos,func,speed)


    local finalPos = cc.p(endPos.x,endPos.y) 
    local finalSpeed = speed
    local symbolNode = node

    schedule(symbolNode,function ()
        
        local PosY = cc.p(symbolNode:getPosition()).y 

        --print("-----endpos"..PosY)
        local needHeight = PosY - endPos.y
        if PosY <= finalPos.y or  needHeight <= finalSpeed   then

            symbolNode:setPosition(finalPos)

            if func then
                func()
                
                func = nil     
            end

            if symbolNode then
                symbolNode:stopAllActions()  
                symbolNode:removeFromParent()
            end

        end

        symbolNode:setPositionY(PosY - finalSpeed)

        
    end,0.01)


end

--[[
    @desc: freespin触发，飞行小块特效
    --@triggerFunc: 最后一个小块落地调用
]]
function CodeGameScreenCharmsMachine:createFSRunningSymbolAnimation( triggerFunc )
    
    local netData = self:getFSRunningInfo()
    if #netData <= 0 then
        if triggerFunc then
            triggerFunc()
        end
        return
    end

    local createdNetIndex = 1
    local createdNetMaxIndex = #netData
    local createdrandomIndex = 1
    
    local flayNode = cc.Node:create()
    flayNode:setName("flayNode")
    flayNode:setPosition(0,0)
    self:findChild("Node_2"):addChild(flayNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 13) 

    if self.DouDongSound then
        gLobalSoundManager:stopAudio(self.DouDongSound)
        self.DouDongSound = nil
    end

    
    if self.DouDongSound == nil then
        self.DouDongSound =  gLobalSoundManager:playSound("CharmsSounds/music_Charms_DouDong.mp3")
    end

    

    self:runCsbAction("chuxian_fs",false,function()
        self:runCsbAction("idle_fs",true)
    end)

    schedule(flayNode,function ()

        local iscreate = math.random( 1,7 )
        if iscreate <= 4 then
            local Createnum = math.random( 4,5 )
            for i = 1,Createnum do
                local num = math.random( 1,6 )

                if createdNetIndex >  createdNetMaxIndex then
                    -- release_print("真的该结束了 不应该创建了 ") 
                    return 
                end

                createdrandomIndex = createdrandomIndex + 1
                local show = false

                local begin =  (createdrandomIndex % 6)
                if begin == 0 and createdrandomIndex > 5 and createdNetIndex <=  createdNetMaxIndex  then
                    show = true
                end

                local data = {}
                if show then -- 根据网络数据创建
                    data.symboltype = netData[createdNetIndex].symboltype -- 
                    data.machine = self
                    if math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL or math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL_DOUBLE  then
                        data.coins = netData[createdNetIndex].coins 
                    end

                else -- 随机数据
                    data.symboltype = self:getFsRodomSymbolType()
                    data.machine = self
                    if math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL or math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL_DOUBLE  then
                        data.coins = self:getFlyNodeRandomCoins()
                    end
                end
                data.freespin  = true
                local moveSymbol = util_createView("CodeCharmsSrc.CharmsViewFlyNode",data)
                local xPos = display.width * 0.2 * (num - 1)
                local yPos = display.height 
                moveSymbol:setPositionX(xPos)
                moveSymbol:setPositionY(yPos)
                flayNode:addChild(moveSymbol)
                local endPos = cc.p(xPos,0)
                local rand1 = math.random( 1,3 )
                local speed = 30 + rand1 * 0.5 * 30
                local func = nil

                if show then
                    -- 创建落地烟雾
                    local Smoke = util_createView("CodeCharmsSrc.CharmsViewSmoke") 
                    flayNode:addChild(Smoke)
                    if Smoke then
                        Smoke:setVisible(false)
                    end
                    
                    local moveXDis = 0
                    if math.abs(data.symboltype) == self.SYMBOL_FIX_SYMBOL_DOUBLE or math.abs(data.symboltype) == self.SYMBOL_FIX_MINOR_DOUBLE  then
                        moveXDis = self.m_SlotNodeW/2 
                    end
                    local roandomSymbolIndex =  netData[createdNetIndex].index  -- math.random( 1, 30) - 1
                    local nodePos = cc.p(self:getThreeReelsTarSpPos(roandomSymbolIndex ))
                    local targSpPos = cc.p(nodePos.x + moveXDis,nodePos.y) 

                    endPos = cc.p(targSpPos.x,targSpPos.y)
                    moveSymbol:setPositionX(targSpPos.x)
                    Smoke:setPosition(endPos)

                    local netDataInfo = netData[createdNetIndex]
                    local endNetIndex = createdNetIndex
                    func = function()
                                -- gLobalSoundManager:playSound("CharmsSounds/music_Charms_Respin_Boom_Down.mp3")
                                if endNetIndex >= createdNetMaxIndex then
                                    self:runCsbAction("over_fs",false,function()
                                        flayNode:stopAllActions()
                                        flayNode:removeFromParent()

                                        if self.DouDongSound then
                                            gLobalSoundManager:stopAudio(self.DouDongSound)
                                            self.DouDongSound = nil
                                        end
                                    end)

                                    util_playFadeOutAction(self.m_effectView,0.2,function()
                                        self.m_effectView:setVisible(false)
                                        util_playFadeInAction(self.m_effectView,0.1)
                                    end)
                                    
                                    if triggerFunc then
                                        performWithDelay(self,function ()
                                            triggerFunc()
                                        end,0.5)
                                    end
                                end
                                print("真实数据移动到结束" ..roandomSymbolIndex..targSpPos.y ) 
                            end

                    createdNetIndex = createdNetIndex + 1
                end
                --print("endPos ----"..endPos.x)
                self:moveFsAction(moveSymbol,endPos,func,speed)
            end
        end
    end,0.1)
end

function CodeGameScreenCharmsMachine:getFsRodomSymbolType()
    local symbolTypeList = {self.SYMBOL_FIX_MINI,
                            self.SYMBOL_FIX_SYMBOL}

    local rodomIndex = math.random( 1, #symbolTypeList )

    return symbolTypeList[rodomIndex]
end

function CodeGameScreenCharmsMachine:getRodomSymbolType()
    local symbolTypeList = {self.SYMBOL_FIX_MINOR,
                            self.SYMBOL_FIX_MINI,
                            self.SYMBOL_FIX_SYMBOL,
                            self.SYMBOL_FIX_SYMBOL_DOUBLE}

    local rodomIndex = math.random( 1, #symbolTypeList )

    return symbolTypeList[rodomIndex]
end

function CodeGameScreenCharmsMachine:getFlyNodeRandomCoins()

    
    local score =  self:randomDownRespinSymbolScore(self.SYMBOL_FIX_SYMBOL) -- 获取随机分数（本地配置）
    if score ~= nil  then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 3)
    else
        score = 000
    end

    return score
end

-- 只处理炸弹炸金块时 信号类型提前变为正数
function CodeGameScreenCharmsMachine:getUpReelsMaxRow(icol ,irow)
    local isBoom = false
    
    local netMaxNet =  self.m_runSpinResultData.p_selfMakeData.unlock
    local netFish = self.m_runSpinResultData.p_selfMakeData.fish
    if netFish and #netFish > 0 then

        for k,v in pairs(netFish) do
            local fixPos = self:getRowAndColByPosForSixRow(v)
            if fixPos.iY == icol then
               local maxRow =  netMaxNet[tostring(fixPos.iY)]

               if maxRow >= irow and irow > NORMAL_ROW_COUNT then
                    isBoom = true

                    break
               end
               
            end
        end
    end

    return isBoom
end

---------------- 创建锁定小块
function CodeGameScreenCharmsMachine:createLockSymbol()

    local time = 0
    local delayTime = 0.3
    local isWite = false

    local m_SymbolMatrix = self:getSymbolMatrixList()


    

    gLobalSoundManager:playSound("CharmsSounds/Charms_Lock.mp3")
    for iRow = 1, self.m_iReelRowNum do

        local isPlay = true

        local rowWaitTime = 0
        if iRow > 3 then
            rowWaitTime = (iRow -3) * delayTime
        end

        for iCol = 1, self.m_iReelColumnNum do

            local symbolType = m_SymbolMatrix[iRow][iCol]

            if symbolType < 0 or self:getUpReelsMaxRow(iCol, iRow) then

                isWite = true

                -- performWithDelay(self,function()

                    -- if isPlay == true then
                    --     gLobalSoundManager:playSound("CharmsSounds/Charms_Lock.mp3")
                    --     isPlay = false
                    -- end

                    local index = self:getPosReelIdx(iRow ,iCol) 
                    local lockView = util_createView("CodeCharmsSrc.CharmsLockView")
                    local viewPos = self:getTarSpPos(index )
                    lockView.m_lock:runCsbAction("buling")
                    lockView:setPosition(viewPos)  
                    self:findChild("Node_2"):addChild(lockView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)

                    
                    local topAct = util_createAnimation("Charms_dangban_top.csb")
                    topAct:setPosition(viewPos)
                    self:findChild("Node_2"):addChild(topAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 101)
                    topAct:playAction("buling",false,function()
                        topAct:removeFromParent()
                    end)
                    local downAct = util_createAnimation("Charms_dangban_down.csb")
                    downAct:setPosition(viewPos) 
                    self:findChild("Node_2"):addChild(downAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 99)
                    downAct:playAction("buling",false,function()
                        downAct:removeFromParent()
                    end)
                    if self.m_lockList[index + 1] == self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKNULL then
                        self.m_lockList[index + 1] = lockView
                    end
                -- end,rowWaitTime)

            end

        end
        
    end

    if isWite == true then
        time = 1 --delayTime * 3 + 1.5
    end
    
    return time
end
--[[
    @desc: 根据信号id进行小块移除
    -- index ：从一开始
]]
function CodeGameScreenCharmsMachine:removeLoclNodeForIndex(index,func )

    local posindex = index

    if type(self.m_lockList[posindex + 1]) == "number" then
        return
    end
    
    local node = self.m_lockList[posindex + 1].m_lock
    node:runCsbAction("actionframe")
    self.m_lockList[posindex + 1] = self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKDNODE
    
    performWithDelay(self,function()
        if func then
            func()
        end

        if node then
            node:setVisible(false)
        end
        
        

        -- self.m_lockList[posindex + 1] = self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKDNODE
       
    end,1.5)


   
    
    

end

function CodeGameScreenCharmsMachine:removeAllFir()
   for k,v in pairs(self.m_FirList) do
        v:removeFromParent()
   end

   self.m_FirList = {}
end

function CodeGameScreenCharmsMachine:removeAllBoom()
    
    for k,v in pairs(self.m_BoomList) do
        v:removeFromParent()
        
    end
    self.m_BoomList = {}
end

function CodeGameScreenCharmsMachine:removeAllLockNode()

    for k,v in pairs(self.m_lockList) do
        if v and type(v) ~= "number" then
            v:removeFromParent() 
        end

        v = nil
    end
   
    self:initLockList()
end
--[[
    @desc: 初始化lockViewList 默认开辟了30个地址
    author:{author}
    time:2019-05-20 18:21:13
    @return:
]]
function CodeGameScreenCharmsMachine:initLockList()
    self.m_lockList = {}

    for i=1,5 do
        for i=1,6 do
            table.insert( self.m_lockList, self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKNULL )
        end
    end

end

----------------- 工具

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenCharmsMachine:getThreeReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenCharmsMachine:getTarSpPos(index )
    local fixPos = self:getRowAndColByPosForSixRow(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenCharmsMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

--- respin下 6行的情况
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function CodeGameScreenCharmsMachine:getRowAndColByPosForSixRow(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = RESPIN_ROW_COUNT - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

--  --- 新添一个respin轮盘专门滚炸弹

--- respin 快停
function CodeGameScreenCharmsMachine:quicklyStop()
    BaseSlotoManiaMachine.quicklyStop(self)
    self.m_BoomReelsView:quicklyStop()
end

--开始滚动
function CodeGameScreenCharmsMachine:startReSpinRun()
    self.m_respinStopCount = 0
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
    else
        self.m_BoomReelsView.m_boomNodeEndList = {} -- 每次开始滚动重置一下数组
        self.m_BoomReelsView.m_boomNodeBulingList = {}
        self.m_BoomReelsView:startMove()
    end

    BaseSlotoManiaMachine.startReSpinRun(self)


    
end

--触发respin
function CodeGameScreenCharmsMachine:triggerReSpinCallFun(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
    
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    

    -- 创建炸弹respin层
    self.m_BoomReelsView = util_createView(self:getBoomRespinView(), self:getBoomRespinNode())
    self.m_BoomReelsView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_BoomReelsView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)

    

    self:initRespinView(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
end

--接收到数据开始停止滚动
function CodeGameScreenCharmsMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)

    local BoomStoredReels = self:getBoomRespinReelsButStored()
    self.m_BoomReelsView:setRunEndInfo(storedNodeInfo, unStoredReels,BoomStoredReels)

end

--开始下次ReSpin
function CodeGameScreenCharmsMachine:runNextReSpinReel()
    if self.m_runSpinResultData.p_selfMakeData.fish and #self.m_runSpinResultData.p_selfMakeData.fish > 0 then
        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
            local node = cc.Node:create()
            self:addChild(node)
            performWithDelay(node,function(  )
                self:startReSpinRun()
                node:removeFromParent()
            end,0)
            
        end
    else
        self.m_beginStartRunHandlerID =
            scheduler.performWithDelayGlobal(
            function()
                if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                    self:startReSpinRun()
                end

                self.m_beginStartRunHandlerID = nil
            end,
            self.m_RESPIN_RUN_TIME,
            self:getModuleName()
        )
    end
end


--播放respin放回滚轴后播放的提示动画
function CodeGameScreenCharmsMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    node:runAnim("idleframe")
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
    if node.p_symbolType and node.p_rowIndex <= 3 then
        if self:isFixSymbol(node.p_symbolType) then
            node = self:setSymbolToClipReel(node.p_cloumnIndex, node.p_rowIndex,node.p_symbolType)
            node:runAnim("actionframe",true)
        end
    end
end
--结束移除小块调用结算特效
function CodeGameScreenCharmsMachine:removeRespinNode()
    BaseSlotoManiaMachine.removeRespinNode(self)
    if self.m_BoomReelsView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNodeUp = self.m_BoomReelsView:getAllEndSlotsNode()
    for i = 1, #allEndNodeUp do
        local targSp = allEndNodeUp[i]
        if targSp then
            targSp:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    end
    if self.m_BoomReelsView then
        self.m_BoomReelsView:removeFromParent()
        self.m_BoomReelsView = nil
    end
end


-- ----创建respin下连续触发jackpot提示

function CodeGameScreenCharmsMachine:checkRemoveNotNeedTipNode()
    local nextJackpo = self.m_runSpinResultData.p_selfMakeData.nextJackpot
    if nextJackpo  then
        local IndexList = {}
        local removeIndex = nil
        for kk,vk in pairs(self.respinJackPotTipNodeList) do
            local isremove = false
            for k,v in pairs(nextJackpo) do
                local index = tonumber(k)  
                if type(vk) ~= "number"  then
                    if index == vk.index then
                        isremove = false
                    else
                        isremove = true
                        removeIndex = vk.index 
                    end
                end
                
            end

            if isremove and removeIndex then
                self:removeOneRespinJackPotTipNode(removeIndex )
            end
        end
        
    end
end

function CodeGameScreenCharmsMachine:checkIsInTipNodeList( index )
    local isin = false
    for k,v in pairs(self.respinJackPotTipNodeList) do
        if type(v) ~= "number" and index == v.index then
           if v and  type(v) ~= "number" then
                isin = true
                break
           end
        end
    end
    return isin
end

function CodeGameScreenCharmsMachine:createRespinJackPotTipNode()

    local nextJackpo = self.m_runSpinResultData.p_selfMakeData.nextJackpot
    if nextJackpo  then
        for k,v in pairs(nextJackpo) do
            local index = tonumber(k)
            if self:checkIsInTipNodeList( index ) then
                print("已经有相同位置的就不创建了,就检测是否应该变化状态就可以了")
                for kv,vv in pairs(self.respinJackPotTipNodeList) do
                    if vv and type(vv) ~= "number" and index == vv.index then

                        if vv.type ~= v then
                            self.respinJackPotTipNodeList[kv].type = v
                            local name = nil
                            if v == "Grand" then
                                name = "animation1"
                            elseif v == "Major" then
                                name = "animation2"
                            elseif v == "Minor" then
                                name = "animation3"
                            end

                            self.respinJackPotTipNodeList[kv]:runCsbAction(name,true)
                        end

                    end
                end
            else

                local pos =  self:getTarSpPos(index )
                local tipNode = util_createView("CodeCharmsSrc.CharmsHuXiActionView")

                local name = nil
                if v == "Grand" then
                    name = "animation1"
                elseif v == "Major" then
                    name = "animation2"
                elseif v == "Minor" then
                    name = "animation3"
                end

                tipNode:runCsbAction(name,true)

                self:findChild("Node_2"):addChild(tipNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)
                tipNode.index = index
                tipNode.jackPotType = v
                tipNode:setPosition(cc.p(pos))

                local listId = index + 1
                self.respinJackPotTipNodeList[listId] = tipNode
            end
        end
    end
end

function CodeGameScreenCharmsMachine:removeOneRespinJackPotTipNode(index )
    for k,v in pairs(self.respinJackPotTipNodeList) do
        local indexId = index + 1
        if k == indexId  and type(v) ~= "number" then
            v:removeFromParent()
            self.respinJackPotTipNodeList[k] = 0
            break
        end
    end
end

function CodeGameScreenCharmsMachine:removeAllRespinJackPotTipNode()
    for k,v in pairs(self.respinJackPotTipNodeList) do
        if v and type(v) ~= "number" then
            v:removeFromParent()
            v = nil
        end
    end

    self.respinJackPotTipNodeList = {}

    self:initRespinJackPotTipNodeList()
end

function CodeGameScreenCharmsMachine:initRespinJackPotTipNodeList()
    for icol=1,5 do
        for irow=1,6 do
            table.insert( self.respinJackPotTipNodeList, 0)
        end
    end
end

function CodeGameScreenCharmsMachine:createOneActionSymbol(endNode,actionName)
    if not endNode or not endNode.m_ccbName  then
        return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node = util_createAnimation(endNode.m_ccbName..".csb")
    local func = function()
            if fatherNode then
                fatherNode:setVisible(true)
            end

            if node then
                -- node:removeFromParent()
                node:runCsbAction("idleframe2",true)
            end
        end
    node:playAction(actionName,false,func)

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Node_2"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("Node_2"):addChild(node , 100000 - endNode.p_rowIndex + endNode.p_cloumnIndex * 10)
    node:setPosition(pos)

    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local symbolIndex = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    local index = 0
    if score ~= nil and type(score) ~= "string" then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
        score = util_formatCoins(score, 3)
        local scoreNode = node:findChild("m_lb_score")
        if scoreNode then
            scoreNode:setString(score)
        end
    end
       
    table.insert(self.m_actRsNode,node)

    return node
end

function CodeGameScreenCharmsMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
 
    self:produceSlots()
    --存在等待时间延后调用下面代码
    if self.m_waitChangeReelTime and self.m_waitChangeReelTime>0 then
        -- FreeSpin玩法 第一次多滚
        if self.m_isFreespinStart then
            local func = function()
                release_print("第二次freespin action ") 
                self:createFSRunningSymbolAnimation( function()
                    self.m_isFreespinStart = false
                    release_print("所有freespin action 结束 开始继续轮盘滚动停止逻辑 ") 
                    -- 开始继续轮盘滚动停止逻辑
                    self.m_waitChangeReelTime=nil
                    self:updateNetWorkData()
                end )
            end
            self.m_effectView:setVisible(true)
            self.m_effectView:runCsbAction("actionframe",true)
            release_print("第一次freespin action ") 
            if func then
                func()
            end
            return
        end

        scheduler.performWithDelayGlobal(function()
            self.m_waitChangeReelTime=nil
            self:updateNetWorkData()
        end, self.m_waitChangeReelTime,self:getModuleName())
        return
    end

    self:checkHaveFeature( function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()        
    end )

end

function CodeGameScreenCharmsMachine:checkHaveFeature( func )
    if self.m_isPlayWinningNotice then
        self:runCsbAction("idle_fs",false,function()
            self:runCsbAction("idle_fs",false,function()
                self:runCsbAction("over_fs")
            end)
        end)
        self.m_effectView:setVisible(true)
        self.m_effectView:runCsbAction("actionframe2",false,function()
            self.m_effectView:setVisible(false)
            
        end)

        gLobalSoundManager:playSound("CharmsSounds/Charms_YuGao.mp3")

        util_spinePlay(self.m_oldMan,"actionframe")
        util_spineEndCallFunc(self.m_oldMan, "actionframe", function()
            util_spinePlay(self.m_oldMan,"idleframe",true)
            
        end)

        scheduler.performWithDelayGlobal(function ()
            if func then
                func()
            end
        end,2,self:getModuleName())
    else
        if func then
            func()
        end
    end
end


-- 转轮开始滚动函数
function CodeGameScreenCharmsMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)


    -- FreeSpin玩法 第一次多滚
    if self.m_isFreespinStart then
          
        --添加滚轴停止等待时间,此处的时间只是为了，确定延时逻辑，并不是就停1秒
        self:setWaitChangeReelTime(0.1)
            
    end

end

---
-- 获取每列滚动信号中的 symboltype
--
function CodeGameScreenCharmsMachine:getReelSymbolType(parentData)
    local symbolType = nil
    if self.m_fsReelDataIndex ~= 0 and parentData.cloumnIndex == 3 then
        local resultType = self.m_runSpinResultData.p_reels[1][3]
       
        local leftCount = self.m_reelRunInfo[parentData.cloumnIndex]:getReelRunLen() - 3
        local beforeEnd = parentData.beginReelIndex + leftCount - 3
        if beforeEnd > #parentData.reelDatas then
            beforeEnd = beforeEnd - #parentData.reelDatas
        end
        if parentData.reelDatas[beforeEnd] ~= resultType then
            local index = nil
            for i = 1, #parentData.reelDatas, 1 do
                if parentData.reelDatas[i] == resultType then
                    index = i
                    break
                end
            end
            local nodeCount = math.floor((leftCount) * 0.5)
            if index == nil then
                return BaseSlots.getReelSymbolType(self, parentData)
            end
            index = index - nodeCount
            if index <= 0 then
                index = #parentData.reelDatas + index
            end
            parentData.beginReelIndex = index
        end
        
        symbolType = parentData.reelDatas[parentData.beginReelIndex]

        local addCount = 1
        parentData.beginReelIndex = parentData.beginReelIndex + addCount
        if parentData.beginReelIndex > #parentData.reelDatas then
            parentData.beginReelIndex = 1
            symbolType = parentData.reelDatas[parentData.beginReelIndex]
        end
        
    else
        symbolType = BaseSlots.getReelSymbolType(self, parentData)
    end

    return symbolType
end

function CodeGameScreenCharmsMachine:onKeyBack()
    
    BaseSlotoManiaMachine.onKeyBack(self)
end


function CodeGameScreenCharmsMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self.m_classicMachine ~= nil then
        return
    end
    BaseSlotoManiaMachine.quicklyStopReel(self, colIndex) 
end

-- 创建飞行粒子
function CodeGameScreenCharmsMachine:createParticleFly(time,oldNode)

    local fly =  util_createView("CodeCharmsSrc.CharmsBonusCollectView")
    
    -- fly:setScale(1.5)
    self:addChild(fly,GD.GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    fly:findChild("Particle_1"):setDuration(time)
    fly:findChild("Particle_xiao"):setDuration(time)
    fly:findChild("Particle_jinkuai"):setDuration(time)
    
    
    fly:setPosition(cc.p(util_getConvertNodePos(oldNode,fly)))
    fly:setVisible(false)


    local changex  = 0
    -- gLobalSoundManager:playSound("FortuneBrickSounds/music_FortuneBrick_bonus_reel_fly".mp3")
    fly:setVisible(true)

    
    local endPos = util_getConvertNodePos(self.m_bottomUI:getWinFlyNode() ,fly)

    local animation = {}
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function()

        fly:findChild("Particle_1"):stopSystem()
        fly:findChild("Particle_xiao"):stopSystem()
        fly:findChild("Particle_jinkuai"):stopSystem()

        performWithDelay(fly,function()
            fly:removeFromParent()
        end,1)
        

    end)

    fly:runAction(cc.Sequence:create(animation))

    
    
end

-- 背景音乐点击spin后播放
function CodeGameScreenCharmsMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    BaseMachine.normalSpinBtnCall(self)

end

function CodeGameScreenCharmsMachine:slotReelDown()
    BaseMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
      
end

---
-- 显示free spin
function CodeGameScreenCharmsMachine:showEffect_FreeSpin(effectData)

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
        
        if self.m_soundNode then
            self.m_soundNode:stopAllActions()
        end
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        -- 
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)            
            gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
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

function CodeGameScreenCharmsMachine:overGameGuoChangView(func,func2 )
    gLobalSoundManager:playSound("CharmsSounds/Charms_GuoChang.mp3")
    self.m_guochang:setVisible(true)
    util_spinePlay(self.m_guochang,"actionframe2",false)
    util_spineEndCallFunc(self.m_guochang,"actionframe2",function()
        self.m_guochang:setVisible(false)
        

        if func2 then
            func2()
        end
    end)
    util_spineFrameEvent(self.m_guochang, "actionframe2","show2",function()

        util_spinePlay(self.m_oldMan,"idleframe",true)
        
        if func then
            func()
        end
    end)
end

function CodeGameScreenCharmsMachine:startGameGuoChangView( func,func2)
    
    
    gLobalSoundManager:playSound("CharmsSounds/Charms_Man_GuoChang.mp3")
    util_spinePlay(self.m_oldMan,"actionframe2")
    util_spineEndCallFunc(self.m_oldMan, "actionframe2", function()

        gLobalSoundManager:playSound("CharmsSounds/Charms_GuoChang.mp3")

        self.m_guochang:setVisible(true)
        util_spinePlay(self.m_guochang,"actionframe",false)
        util_spineEndCallFunc(self.m_guochang,"actionframe",function()
            self.m_guochang:setVisible(false)
            if func2 then
                func2()
            end
        end)
        util_spineFrameEvent(self.m_guochang, "actionframe","show",function()
            if func then
                func()
            end
        end)
    end)

end

function CodeGameScreenCharmsMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenCharmsMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end
    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
        gLobalViewManager:showUI(view)
    -- end
    local root = view:findChild("root")
    if root then
        root:setScale(self.m_machineRootScale)
    end
    
    

    return view
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenCharmsMachine:showLocalDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeCharmsSrc.CharmsBaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
        gLobalViewManager:showUI(view)
    -- end

    local root = view:findChild("root")
    if root then
        root:setScale(self.m_machineRootScale)
    end

    return view
end

function CodeGameScreenCharmsMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow + _iCol * 10
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
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

-------------------------------------------日志发送 START
--缓存日志
function CodeGameScreenCharmsMachine:pushSpinLog(strLog)
    if not self.m_spinLog then
        local fieldValue = util_getUpdateVersionCode(false) or "Vnil"
        self.m_spinLog = "START "..fieldValue.." | \n"
    end
    strLog = tostring(strLog)
    self.m_spinLog = self.m_spinLog..strLog.. " | \n"
end
--清空日志
function CodeGameScreenCharmsMachine:clearSpinLog()
    self.m_spinLog = nil
end
--检测是否存在问题
function CodeGameScreenCharmsMachine:checkSpinError()
    local isSpinErrorFlag = nil
    local logStr = " \n"
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local allEndNode = self.m_respinView:getFixSlotsNode()
    for i = 1, #allEndNode do
        local chipNode = allEndNode[i]
        local iCol = chipNode.p_cloumnIndex
        local iRow = chipNode.p_rowIndex 
        local scoreIndx = self:getPosReelIdx(iRow ,iCol)
        local score = self:getReSpinSymbolScore(scoreIndx) 
        local curSymbolType = chipNode.p_symbolType or -1
        logStr = logStr.. " oriSymbolType = "..tostring(curSymbolType).." iCol = "..tostring(iCol).." iRow = "..tostring(iRow).." scoreIndx = "..tostring(scoreIndx).." score = "..tostring(score).." \n"
        curSymbolType = math.abs(curSymbolType)
        if score ~= nil and type(score) ~= "string" then
            local newScore = score * lineBet
            newScore = util_formatCoins(newScore, 3)
            if curSymbolType == self.SYMBOL_FIX_MINI or curSymbolType == self.SYMBOL_FIX_MINOR or curSymbolType == self.SYMBOL_FIX_MINOR_DOUBLE then
                isSpinErrorFlag = true
                logStr = logStr.." jackpot error 1"
                logStr = logStr.." strScore = "..newScore
            else
                local scoreNode = nil
                if chipNode.findChild then
                    logStr = logStr.." chipNode:findChild m_lb_score \n"
                    scoreNode = chipNode:findChild("m_lb_score")
                end
                if not scoreNode and chipNode.getCcbProperty then
                    logStr = logStr.." chipNode:getCcbProperty m_lb_score \n"
                    scoreNode = chipNode:getCcbProperty("m_lb_score")
                end
                if scoreNode then
                    local symbolScore = scoreNode:getString()
                    if newScore~=symbolScore then
                        isSpinErrorFlag = true
                        logStr = logStr.." \n SPINERROR: different symbolScore"
                        logStr = logStr.." symbolScore = "..symbolScore
                        logStr = logStr.." strScore = "..newScore
                    end
                else
                    isSpinErrorFlag = true
                    logStr = logStr.." \n SPINERROR: not labCoin"
                    logStr = logStr.." strScore = "..newScore
                end
            end
        else
            if curSymbolType == self.SYMBOL_FIX_MINI and score == "MINI" then
            elseif curSymbolType == self.SYMBOL_FIX_MINOR and score == "MINOR" then
            elseif curSymbolType == self.SYMBOL_FIX_MINOR_DOUBLE and score == "MINOR" then
            else
                isSpinErrorFlag = true
                logStr = logStr.." \n SPINERROR: jackpot error 2"
                logStr = logStr.." strScore = "..tostring(score)
            end
        end
    end
    self:pushSpinLog(logStr)
    return isSpinErrorFlag
end
--发送日志
function CodeGameScreenCharmsMachine:sendSpinLog()
    local isError = self:checkSpinError()
    if not isError then
        return
    end
    if self.m_spinLog and gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendSpinErrorLog then
        gLobalSendDataManager:getLogGameLoad():sendSpinErrorLog(self.m_spinLog)
    end
end
-------------------------------------------日志发送 END
return CodeGameScreenCharmsMachine






