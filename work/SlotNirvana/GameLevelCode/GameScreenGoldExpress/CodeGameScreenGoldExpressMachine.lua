---
-- island li
-- 2019年1月26日
-- CodeGameScreenGoldExpressMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local CollectData = require "data.slotsdata.CollectData"
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenGoldExpressMachine = class("CodeGameScreenGoldExpressMachine", BaseSlotoManiaMachine)

CodeGameScreenGoldExpressMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画


CodeGameScreenGoldExpressMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

CodeGameScreenGoldExpressMachine.m_chipList = nil
CodeGameScreenGoldExpressMachine.m_playAnimIndex = 0
CodeGameScreenGoldExpressMachine.m_lightScore = 0
CodeGameScreenGoldExpressMachine.m_vecReelPos = {0, 132, 263, 394, 525}
CodeGameScreenGoldExpressMachine.m_iGoldExpressNum = nil
CodeGameScreenGoldExpressMachine.m_iCurrSelectedID = nil
CodeGameScreenGoldExpressMachine.m_iSelectedTimes = nil
CodeGameScreenGoldExpressMachine.m_iFixSymbolNum = nil
CodeGameScreenGoldExpressMachine.m_bFlagRespinNumChange = nil
CodeGameScreenGoldExpressMachine.m_vecExpressSound = {false, false, false, false, false}
CodeGameScreenGoldExpressMachine.m_vecJackpotNum = {15, 14, 13, 12}
---------------------------------------新增变量--------------------------------------------
CodeGameScreenGoldExpressMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT
CodeGameScreenGoldExpressMachine.FLY_COIN_TYPE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 40

CodeGameScreenGoldExpressMachine.m_bCanClickMap = nil
CodeGameScreenGoldExpressMachine.m_bSlotRunning = nil
CodeGameScreenGoldExpressMachine.m_vecFixWild = nil
CodeGameScreenGoldExpressMachine.m_bIsBonusFreeGame = nil
CodeGameScreenGoldExpressMachine.m_iBonusFreeTimes = nil

CodeGameScreenGoldExpressMachine.m_vecBigLevel = {4, 8, 13, 19}
CodeGameScreenGoldExpressMachine.m_iReelMinRow = 3

local RESPIN_BIG_REWARD_MULTIP = 5000
local RESPIN_BIG_REWARD_SYMBOL_NUM = 15
CodeGameScreenGoldExpressMachine.m_winSoundsId = nil
CodeGameScreenGoldExpressMachine.m_mapNodePos = nil
CodeGameScreenGoldExpressMachine.m_normalFreeSpinTimes = nil
-----------------------------------------------------------------------------------
local FIT_HEIGHT_MAX = 1300
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenGoldExpressMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)


    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenGoldExpressMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("GoldExpressConfig.csv", "LevelGoldlExpressConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
    self.m_scatterBulingSoundArry = {}
    self.m_scatterBulingSoundArry["auto"] = "GoldExpressSounds/sound_glod_express_scatter_down.mp3"
end

function CodeGameScreenGoldExpressMachine:scaleMainLayer()
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

        if display.height == 1370 then

            mainScale = (FIT_HEIGHT_MAX - uiH - uiBH + 90 )/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale

            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 50)

        elseif display.height == 1660 then

            mainScale = (FIT_HEIGHT_MAX - uiH - uiBH + 90 )/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale

            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 90)

        elseif display.height >= FIT_HEIGHT_MAX  then

            mainScale = (FIT_HEIGHT_MAX - uiH - uiBH + 90 )/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if display.height / display.width >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 75)
            else

                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 55)
            end
            

        elseif display.height < FIT_HEIGHT_MAX and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height - uiH - uiBH )/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 5)
        else
            mainScale = (display.height + 50 - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 25)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)

end

function CodeGameScreenGoldExpressMachine:initUI()

    self:changeReelsBg( false )

    self:findChild("Lun_pan4x5"):setVisible(false)
    self:findChild("Lun_pan3x5"):setVisible(true)


    self.m_jackPotNode = util_createView("CodeGoldExpressSrc.GoldExpressJackPotNode")
    self:findChild("Jackpot"):addChild(self.m_jackPotNode)
    self.m_jackPotNode:initMachine(self)

    self.m_spinTimesBar = util_createView("CodeGoldExpressSrc.GoldExpressSpinTimes")
    self:findChild("spins"):addChild(self.m_spinTimesBar)
    self.m_spinTimesBar:findChild("GoldExpress_di"):setVisible(false)

    local logo, act = util_csbCreate("GoldExpress_logo.csb")
    self:findChild("logo"):addChild(logo)
    util_csbPlayForKey(act, "actionframe", true)
    self.m_logo = logo

    self.m_expressRun = util_spineCreate("Socre_GoldExpress_Guochang", false, true)
    self:addChild(self.m_expressRun, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_expressRun:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_expressRun:setVisible(false)

    self:findChild("effect"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_changeScoreEffect = util_createView("CodeGoldExpressSrc.GoldExpressChangeScoreEffect")
    self.m_changeScoreEffect:runAnimation("actionframe", true)
    self:findChild("effect"):addChild(self.m_changeScoreEffect)
    self.m_changeScoreEffect:setVisible(false)


    self.m_bonusFreeGameBar = util_createView("CodeGoldExpressSrc.GoldExpressBnousFreeGameBar")
    self:findChild("Node_iswild"):addChild(self.m_bonusFreeGameBar)
    self.m_bonusFreeGameBar:setPositionX(self.m_bonusFreeGameBar:getPositionX() + 70)
    self.m_bonusFreeGameBar:setVisible(false)

    -- self.m_selectedColEffect = util_createView("CodeGoldExpressSrc.GoldExpressSelectedColEffect")
    -- self.m_selectedColEffect:runAnimation("actionframe", true)
    -- self:findChild("effect"):addChild(self.m_selectedColEffect)
    -- self.m_selectedColEffect:setVisible(false)

    self:findChild("freespin"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_freeSpinStartEffect = util_createView("CodeGoldExpressSrc.FreeSpinStartEffect")
    self:findChild("freespin"):addChild(self.m_freeSpinStartEffect)
    self.m_freeSpinStartEffect:setVisible(false)


    self.m_progress = util_createView("CodeGoldExpressSrc.GoldExpressBonusProgress")
    self:findChild("progress"):addChild(self.m_progress)

    self.m_huocheBg = self:findChild("huocheBg")
    self.m_huocheBg:setVisible(false)


    self.m_tipView = util_createAnimation("GoldExpress_jackPoTip.csb")
    self:findChild("jackPoTip"):addChild(self.m_tipView)
    self:findChild("jackPoTip"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    self.m_tipView:setVisible(false)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    performWithDelay(self.m_actNode,function(  )
        
        if self:isNormalStates( ) then
            self.m_tipView:setVisible(true)
            self.m_tipView:runCsbAction("open",false,function(  )

                if not  self.m_tipView.isSpin then
                    self.m_tipView:runCsbAction("idle",true)

                    performWithDelay(self.m_actNode,function(  )
                        if not  self.m_tipView.isSpin then
                            self.m_tipView.isOverAct = true
                            self.m_tipView:runCsbAction("over",false)
                        end
                        
                    end,4)
                end
                

            end)
        end
    end,0.1)

    self.m_tipView_1 = util_createAnimation("GoldExpress_jushu.csb")
    self:findChild("jushu"):addChild(self.m_tipView_1)
    
    


    if display.height >= FIT_HEIGHT_MAX then--Lun_pan4x5

        local nodeJackpot = self:findChild("Jackpot")
        
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        if display.height > 1550 then
            posY = (display.height - 1250) * 0.5
        elseif display.height > 1450 then
            posY = (display.height - 1260) * 0.5
        elseif display.height > 1370 then
            posY = (display.height - 1270) * 0.5
        else
            posY = (display.height - 1270) * 0.5
        end

        local Node_Bonus_Game = self:findChild("Node_Bonus_Game")
        Node_Bonus_Game:setPositionY(Node_Bonus_Game:getPositionY() - posY)

        -- local panel = self:findChild("Panel_1")
        -- panel:setPositionY(panel:getPositionY() - posY)
        local nodeLunpan = self:findChild("Node_lunpan")
        nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY )
        local nodeSpin = self:findChild("spins")
        nodeSpin:setPositionY(nodeSpin:getPositionY() - posY )
        local nodeEffect = self:findChild("effect")
        nodeEffect:setPositionY(nodeEffect:getPositionY() - posY )
        local nodeFreespin = self:findChild("freespin")
        nodeFreespin:setPositionY(nodeFreespin:getPositionY() - posY )
        logo:setPositionY(logo:getPositionY() - posY)

        local nodeprogress = self:findChild("progress")
        nodeprogress:setPositionY(nodeprogress:getPositionY() - posY )

        local jackPoTip = self:findChild("jackPoTip")
        jackPoTip:setPositionY(jackPoTip:getPositionY() - posY )

        local nodemap = self:findChild("map")
        nodemap:setPositionY(nodemap:getPositionY() - posY )

        local node_3x5 = self:findChild("Node_3x5")
        node_3x5:setPositionY(node_3x5:getPositionY() - posY )

        local Node_iswild = self:findChild("Node_iswild")
        Node_iswild:setPositionY(Node_iswild:getPositionY() - posY )
        

        local Node_bg = self:findChild("Node_bg")
        Node_bg:setPositionY(Node_bg:getPositionY() - posY )
        

        local nodeJackpotBet = nodeJackpot:getPositionY() / DESIGN_SIZE.height 
        local nodeJackpotWorldPos =  nodeJackpotBet * display.height

        local addLength = 0
        if display.height >= FIT_HEIGHT_MAX then
            local fitScale = display.height / 1000 - 1.3

            if display.height == 1370 then
                fitScale = 1 + fitScale

                nodeJackpot:setScale(0.87)
                addLength = 0
            elseif display.height == 1660 then
                fitScale = 1 + fitScale

                nodeJackpot:setScale(1.15)
                addLength = 50
            elseif display.height >= 1536 then

                addLength = (350 * fitScale) * self.m_machineRootScale
                fitScale = 0.77 + fitScale
                nodeJackpot:setScale(fitScale) 

            else
                addLength = (100 * fitScale) * self.m_machineRootScale

                fitScale = 0.77 + fitScale
                nodeJackpot:setScale(fitScale) 
            end
            
        end

        -- local bgImg = self.m_gameBg:findChild("root")
        -- if bgImg then
        --     bgImg:setPositionY(-100)
        -- end

        if display.height / display.width >= 2 then
            
            if display.height == 1660 then
                local Node_Center =  self.m_jackPotNode:findChild("Node_16")
                local scalenum = Node_Center:getScale()
                Node_Center:setScaleY( scalenum + 0.1)
                Node_Center:setScaleX(scalenum + 0.05)
    
                local worldPos = cc.p(0,nodeJackpotWorldPos)
                local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                nodeJackpot:setPositionY( pos.y - addLength )

            else
                local Node_Center =  self.m_jackPotNode:findChild("Node_16")
                local scalenum = Node_Center:getScale()
                Node_Center:setScaleY( scalenum + 0.1)
                Node_Center:setScaleX(scalenum + 0.05)
    
                local worldPos = cc.p(0,nodeJackpotWorldPos)
                local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                nodeJackpot:setPositionY( pos.y - addLength + 60 )
            end

        else

            

            if display.height == 1370 then
                local jackpot_big =  self.m_jackPotNode:findChild("jackpot_big")
                local scaleNum = jackpot_big:getScale()
                jackpot_big:setScale(scaleNum + 0.25 )

                local worldPos = cc.p(0,nodeJackpotWorldPos)
                local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                nodeJackpot:setPositionY( pos.y - addLength )

            else

                local jackpot_big =  self.m_jackPotNode:findChild("jackpot_big")
                jackpot_big:setScale(jackpot_big:getScale() + 0.15)

                local worldPos = cc.p(0,nodeJackpotWorldPos)
                local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                nodeJackpot:setPositionY( pos.y - addLength + 40 )
            end

        end
        

    elseif display.height < FIT_HEIGHT_MIN then
        local nodeJackpot = self:findChild("Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - 5 )
        nodeJackpot:setScale(0.9)

        local jackpot_big =  self.m_jackPotNode:findChild("jackpot_big")
        jackpot_big:setScale(jackpot_big:getScale() + 0.3)
    else

        -- local bgImg = self.m_gameBg:findChild("root")
        -- if bgImg then
        --     bgImg:setPositionY(-100)
        -- end

        local nodeJackpot = self:findChild("Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - 5 )
        nodeJackpot:setScale(0.97)

        local jackpot_big =  self.m_jackPotNode:findChild("jackpot_big")
        jackpot_big:setScale(jackpot_big:getScale() + 0.2)

        nodeJackpot:setPositionY( nodeJackpot:getPositionY() +  35 )
    end


    local nodeJackpot = self:findChild("Jackpot")
    -- local jackpot_big =  self.m_jackPotNode:findChild("jackpot_big")
    local bangDownHeight = util_getSaveAreaBottomHeight()
    nodeJackpot:setPositionY(nodeJackpot:getPositionY() - bangDownHeight)
    -- jackpot_big:setPositionY(jackpot_big:getPositionY() - bangDownHeight)

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
        end
        local soundName = "GoldExpressSounds/sound_glod_express_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenGoldExpressMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    if self.m_bonusReconnect and self.m_bonusReconnect == true then
        return false
    end

    return true
end

function CodeGameScreenGoldExpressMachine:beginReel()

    BaseSlotoManiaMachine.beginReel(self)

    if self.m_bonusGameReel ~= nil then
        self.m_bonusGameReel:beginReel()
    end
end


function CodeGameScreenGoldExpressMachine:chooseAddScoreCol(func)
    self.m_changeScoreEffect:setVisible(true)
    self.m_changeScoreEffect:runAnimation("actionframe", true)
    self.m_changeScoreEffect:setPosition(0,0)
    self.m_iSelectedTimes = 0
    local vecActions = {}
    local vecReverse = {}
    local delayTime = 0.2
    for i = 2, 5, 1 do
        local moveBy = cc.MoveBy:create(0.3, cc.p(132, 0))
        vecActions[#vecActions + 1] = moveBy
        local delay = cc.DelayTime:create(delayTime)
        local callback = cc.CallFunc:create(function()
            gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_rs_move.mp3")
            self:chooseColDown(i, func)
        end)
        vecActions[#vecActions + 1] = callback
        -- vecActions[#vecActions + 1] = delay

        local reverseDelay = cc.DelayTime:create(delayTime)
        -- vecReverse[#vecReverse + 1] = reverseDelay
        local reverseCall = cc.CallFunc:create(function()
            gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_rs_move.mp3")
            self:chooseColDown(i - 1, func)
        end)
        vecReverse[#vecReverse + 1] = reverseCall
        vecReverse[#vecReverse + 1] = moveBy:reverse()
    end
    for i = #vecReverse, 1, -1 do
        vecActions[#vecActions + 1] = vecReverse[i]
    end

    vecActions[#vecActions + 1] = callback
    self.m_changeScoreEffect:runAction(cc.RepeatForever:create(cc.Sequence:create(vecActions)))

end

function CodeGameScreenGoldExpressMachine:chooseColDown(index, func)
    self.m_iCurrSelectedID = index
    self.m_iSelectedTimes = self.m_iSelectedTimes + 1

    local bIsOverRun = false
    if self.m_iSelectedTimes >= 4 and self.m_iCurrSelectedID == self.m_runSpinResultData.p_selfMakeData.column then
        bIsOverRun = true
    elseif self.m_iSelectedTimes >= 3 and self.m_iCurrSelectedID == self.m_runSpinResultData.p_selfMakeData.column then
        local random = math.random(10)
        if random >= 7 then
            bIsOverRun = true
        end
    elseif self.m_iSelectedTimes >= 2 and self.m_iCurrSelectedID == self.m_runSpinResultData.p_selfMakeData.column then
        local random = math.random(10)
        if random >= 9 then
            bIsOverRun = true
        end
    end
    
    if bIsOverRun == true then
        local reelID = self.m_runSpinResultData.p_selfMakeData.column
        gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_rs_select.mp3")
        self.m_changeScoreEffect:stopAllActions()
        self.m_changeScoreEffect:setPositionX(self.m_vecReelPos[reelID])
        self.m_changeScoreEffect:runAnimation("actionframe1", true)
        -- self.m_selectedColEffect:setPosition(self.m_changeScoreEffect:getPosition())
        -- self.m_selectedColEffect:setVisible(true)
        if func ~= nil then
            performWithDelay(self, function()
                -- self.m_selectedColEffect:setVisible(false)
                self.m_changeScoreEffect:setVisible(false)
                func()
            end, 1)
        end
    end
end

function CodeGameScreenGoldExpressMachine:updateNetWorkData()
    if self.m_freeSpinStartEffect:isVisible() == true then
        scheduler.performWithDelayGlobal(function()
            self.m_freeSpinStartEffect:setVisible(false)
            self:updateNetWorkData()
        end, 3.4, self:getModuleName())
    else
        BaseSlotoManiaMachine.updateNetWorkData(self)
    end

end
function CodeGameScreenGoldExpressMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index=1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

function CodeGameScreenGoldExpressMachine:initGameStatusData(gameData)

    if gameData.collect ~= nil then
        self.m_collectProgress = self:getProgress(gameData.collect[1])
    else
        self.m_collectProgress = 0
    end
    if gameData.gameConfig.extra then
        self.m_nodePos = gameData.gameConfig.extra.currPosition
        self:updateMapData(gameData.gameConfig.extra.map)

    end
    if self.m_nodePos == nil then
        self.m_nodePos = 0
    end
    self.m_mapNodePos = self.m_nodePos

    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end
function CodeGameScreenGoldExpressMachine:updateMapData(map)
    local vecSelectedID = {}
    local vecAllID = {}
    local bigLevelID = 1
    for i = 1, #map, 1 do
        local info = map[i]
        if info.type == "SMALL" then
            if info.selected == true then
                vecSelectedID[#vecSelectedID + 1] = info.position
            end
            vecAllID[#vecAllID + 1] = info.position
        elseif info.type == "BIG" then
            info.extraGames = {}
            info.allGames = {}
            info.levelID = bigLevelID
            bigLevelID = bigLevelID + 1
            for j = #vecSelectedID, 1, -1 do
                table.insert( info.extraGames, 1, vecSelectedID[j])
                table.remove( vecSelectedID, j)
            end
            for j = #vecAllID, 1, -1 do
                table.insert( info.allGames, 1, vecAllID[j])
                table.remove( vecAllID, j)
            end
        end
    end
    self.m_bonusData =  map
end

function CodeGameScreenGoldExpressMachine:getProgress(collect)
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

-- 断线重连
function CodeGameScreenGoldExpressMachine:MachineRule_initGame(  )
    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.m_bIsRespinReconnect = true
        -- if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        --     self.m_normalFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        -- end
        self.m_tipView_1:setVisible(false)
    end

    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_progress:setVisible(true)
        self:resetViewBeforeFreespin()
        if self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_tipView_1:setVisible(false)
            self:triggerFreeSpinCallFun()
        end
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    elseif self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self.m_tipView_1:setVisible(false)
        self:triggerFreeSpinCallFun()
    end
    -- if  self.m_runSpinResultData.p_reSpinCurCount > 0  then
        -- self.m_progress:setVisible(false)
    -- end
    if self:BaseMania_isTriggerCollectBonus() then
        self.m_tipView_1:setVisible(false)
        if self.m_bonusData[self.m_nodePos].type == "BIG" and self.m_initSpinData.p_freeSpinsLeftCount and self.m_initSpinData.p_freeSpinsLeftCount > 0 then
            self.m_spinTimesBar:resetUIBuyMode("freespin")
            self.m_spinTimesBar:showBar()
            self:bonusFreeGameInfo()
            performWithDelay(self,function()
                self:initFixWild()

            end,0.3)
            self.m_bIsBonusFreeGame = true
            self.m_progress:setVisible(false)
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iBonusFreeTimes = self.m_iFreeSpinTimes
            self.m_bIsBonusFreeGame = true
            -- util_setCsbVisible(self.m_baseFreeSpinBar, true)
            self.m_bottomUI:showAverageBet()
            self:setCurrSpinMode( FREE_SPIN_MODE)
        else
            self.m_progress:setVisible(true)
        end
        self.m_mapNodePos = self.m_nodePos - 1
        self.m_bonusReconnect = true
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end

    end


    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        self:changeReelsBg( true )
        self.m_tipView_1:setVisible(false)
    end
end

function CodeGameScreenGoldExpressMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false
     and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        -- self:BaseMania_completeCollectBonus()
        -- self:updateCollect()
        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then

        self.m_tipView_1:setVisible(false)

        local bonusView = util_createView("CodeGoldExpressSrc.GoldExpressBonusGameLayer", self.m_nodePos,featureData)
        -- performWithDelay(self, function()
        --     self:clearCurMusicBg()
        --     self.m_currentMusicBgName = "LinkFishSounds/music_LinkFish_bonusgame_bgm.mp3"
        --     self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        -- end, 3)

        bonusView:resetView((function(coins, extraGame)
            self:clearCurMusicBg()
            self:bonusGameOver(coins, extraGame, function()

                

                -- self:resetViewAfterBigLevel()
                self:showBonusMap(function()
                    self.m_bIsInBonusGame = false
                    self:MachineRule_checkTriggerFeatures()
                    self:addNewGameEffect()
                    self.m_progress:resetProgress(self.m_bonusData[self.m_nodePos + 1].levelID, function()
                        -- if self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                        --     self:triggerFreeSpinCallFun()
                        -- else
                            self:resetMusicBg()
                        -- end
                        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                            self:triggerFreeSpinCallFun()
                            self:changeReelsBg( true )
                            self.m_tipView_1:setVisible(false)
                        end
                        self:playGameEffect()
                    end)
                end, self.m_nodePos)
                if self.m_bProduceSlots_InFreeSpin == true or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                    self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins + coins)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                end
            end)
            bonusView:removeFromParent()

            self.m_progress:setVisible(true)
        end), self)
        if globalData.slotRunData.machineData.p_portraitFlag then
            bonusView.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalViewManager:showUI(bonusView)
        -- self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        if self.m_bProduceSlots_InFreeSpin ~= true then
            self.m_bottomUI:checkClearWinLabel()
        else
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        performWithDelay(self, function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end, 0.1)
        self.m_bIsInBonusGame = true
        self:setCurrSpinMode( NORMAL_SPIN_MODE)
        local featureID = spinData.p_features[#spinData.p_features]

        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            table.remove(self.m_runSpinResultData.p_features, #self.m_runSpinResultData.p_features)
        end

        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
        self.m_mapNodePos = self.m_nodePos - 1
    end

    if featureData.p_data ~= nil and featureData.p_data.freespin ~= nil then
        self.m_runSpinResultData.p_freeSpinsLeftCount = featureData.p_data.freespin.freeSpinsLeftCount
        self.m_runSpinResultData.p_freeSpinsTotalCount = featureData.p_data.freespin.freeSpinsTotalCount
    end
end

function CodeGameScreenGoldExpressMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
         isNotifyUpdateTop = false
     end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

function CodeGameScreenGoldExpressMachine:bonusFreeGameInfo()
    self.m_fsReelDataIndex = 1
    local info = self.m_bonusData[self.m_nodePos]
    local m4IsWild = false
    local isAddWild = false
    local isAddRow = false
    local isAddWheel = false
    local isDoubleWin = false
    for i = 1, #info.extraGames, 1 do
        local game = info.extraGames[i]
        if game == 2 or game == 12 or game == 17 then
            m4IsWild = true
        end
        if game == 6 then
            isDoubleWin = true
        end
        if game == 3 or game == 18 then
            isAddWild = true
        end
        if game == 11 then
            isAddRow = true
        end
        if game == 15 then
            isAddWheel = true
        end
    end
    if m4IsWild == true and isAddWild == true then
        self.m_fsReelDataIndex = 4
    elseif m4IsWild == true then
        self.m_fsReelDataIndex = 2
    elseif isAddWild == true then
        self.m_fsReelDataIndex = 3
    end

    if m4IsWild == true then
        -- if isAddRow == true then
        --     self.m_bonusFreeGameBar:removeFromParent()
        --     self:findChild("Node_4x5"):addChild(self.m_bonusFreeGameBar)
        -- else
        --     self.m_bonusFreeGameBar:removeFromParent()
        --     self:findChild("Node_3x5"):addChild(self.m_bonusFreeGameBar)
        -- end
        self.m_bonusFreeGameBar:setVisible(true)
        self.m_bonusFreeGameBar:m4IsWild()

        self.m_spinTimesBar:findChild("GoldExpress_di"):setVisible(true)

    end

    if isDoubleWin == true then
        -- if isAddRow == true then
        --     self.m_bonusFreeGameBar:removeFromParent()
        --     self:findChild("Node_4x5"):addChild(self.m_bonusFreeGameBar)
        -- else
        --     self.m_bonusFreeGameBar:removeFromParent()
        --     self:findChild("Node_3x5"):addChild(self.m_bonusFreeGameBar)
        -- end
        self.m_bonusFreeGameBar:setVisible(true)
        self.m_bonusFreeGameBar:doubleWins()

        self.m_spinTimesBar:findChild("GoldExpress_di"):setVisible(true)

    end
    if m4IsWild == false and isDoubleWin == false then
        self.m_spinTimesBar:setPositionY(-63)
    end
    self.m_huocheBg:setPositionY(112)

    if isAddRow == true then
        self.m_iReelRowNum = 4
        self:changeReelData()
        self.m_bonusFreeGameBar:setPositionY(119)
        self.m_spinTimesBar:setPositionY(54)
        self.m_huocheBg:setPositionY(228)
    end

    self.m_jackPotNode:setVisible(false)
    -- self.m_spinTimesBar:setPositionX(243)
    self.m_logo:setVisible(false)
    self.m_huocheBg:setVisible(true)

    if isAddWheel == true then

        self.m_huocheBg:setVisible(false)
        self.m_bonusFreeGameBar:setPositionY(-5)
        self.m_spinTimesBar:setPositionY(-65)
        -- self.m_spinTimesBar:setPositionX(self.m_spinTimesBar:getPositionX() - 150)

        self.m_bonusGameReel = util_createView("CodeGoldExpressSrc.GoldExpressBonusGameMachine")
        self:findChild("Node_Bonus_Game"):addChild(self.m_bonusGameReel)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_bonusGameReel.getRotateBackScaleFlag = function(  ) return false end
        end


        self.m_bonusGameReel:setPositionY(10)
        if self.m_runSpinResultData.p_storedIcons ~= nil then
            self.m_bonusGameReel:setStoredIcons(self.m_runSpinResultData.p_storedIcons)
        end
        if self.m_runSpinResultData.p_selfMakeData.otherReel == nil then
            self.m_bonusGameReel:initSlotNode(self.m_runSpinResultData.p_reels)
        else
            self.m_bonusGameReel:initSlotNode(self.m_runSpinResultData.p_selfMakeData.otherReel.reels)
        end

        self.m_bonusGameReel:initFixWild(self.m_runSpinResultData.p_selfMakeData.lockWild)
        self.m_bonusGameReel:setFSReelDataIndex(self.m_fsReelDataIndex)

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    else

        if self.m_iReelRowNum == 3 then
            self.m_spinTimesBar:setPositionY(-63)
        end

    end

end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGoldExpressMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "GoldExpress"
end

function CodeGameScreenGoldExpressMachine:getNetWorkModuleName()
    return "GoldExpressV2"
end
-- 继承底层respinView
function CodeGameScreenGoldExpressMachine:getRespinView()
    return "CodeGoldExpressSrc.GoldExpressRespinView"
end
-- 继承底层respinNode
function CodeGameScreenGoldExpressMachine:getRespinNode()
    return "CodeGoldExpressSrc.GoldExpressRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGoldExpressMachine:MachineRule_GetSelfCCBName(symbolType)

    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_GoldExpress_bonus"
    elseif symbolType == self.FLY_COIN_TYPE then
        return "Bonus_GoldExpress_Train_fly"
    end
    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenGoldExpressMachine:getReSpinSymbolScore(id)
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

    return score
end

function CodeGameScreenGoldExpressMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end


    return score
end

-- 给respin小块进行赋值
function CodeGameScreenGoldExpressMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if iCol ~= nil and symbolNode.m_isLastSymbol == true then
        symbolNode.p_reelDownRunAnima = "buling1"

        if self.m_runSpinResultData.p_reSpinsTotalCount ~= nil and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
            symbolNode.p_reelDownRunAnima = "buling2"
        end
        if self.m_vecExpressSound[iCol] == false  then
            symbolNode.p_reelDownRunAnimaSound = "GoldExpressSounds/sound_glod_express_bonus_down_"..symbolNode.p_cloumnIndex..".mp3"
            self.m_vecExpressSound[iCol] = true
        end

        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE and self.m_runSpinResultData.p_selfMakeData.bonusIndex ~= nil
         and symbolNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            if symbolNode:getChildByName("tips") ~= nil then
                symbolNode:getChildByName("tips"):removeFromParent()
            end
            local tips, act = util_csbCreate("GoldExpress_tips.csb")
            tips:setName("tips")
            symbolNode:addChild(tips, 2000)
            tips:setPosition(41, 39)
            local symbolIndex = self:getPosReelIdx(iRow, iCol)
            tips:getChildByName("lab_num"):setString(self.m_runSpinResultData.p_selfMakeData.bonusIndex[tostring(symbolIndex)])
            -- util_csbPlayForKey(act, "actionframe", true)
        end
    end
end


function CodeGameScreenGoldExpressMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)
    if reelNode:getChildByName("tips") ~= nil then
        reelNode:getChildByName("tips"):removeFromParent()
    end
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end



    return reelNode
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGoldExpressMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL, count =  2}
    loadNode[#loadNode + 1] = {symbolType = self.FLY_COIN_TYPE, count = 2}

    return loadNode
end

function CodeGameScreenGoldExpressMachine:getIsBigLevel()
    for i = 1, #self.m_vecBigLevel, 1 do
        if self.m_vecBigLevel[i] == self.m_nodePos then
            return true
        end
    end
    return false
end

function CodeGameScreenGoldExpressMachine:showEffect_Bonus(effectData)

    self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.currPosition
    if self.m_bonusReconnect ~= true then
        self.m_mapNodePos = self.m_nodePos
    else
        self.m_bonusReconnect = false
    end

    -- self:updateMapData(self.m_runSpinResultData.p_selfMakeData.map)

    local bonusGame = function()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        
        local gameType = self.m_bonusData[self.m_nodePos].type
        if gameType == "SMALL" then
            performWithDelay(self, function()
                self:clearCurMusicBg()
                gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_viewOpen.mp3", false)

                self:bonusGameStart(function()
                    self.m_tiggerBonus = false
                    -- self.m_currentMusicBgName = "GoldExpressSounds/music_GoldExpress_bonusgame_bgm.mp3"
                    -- self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                    local bonusView = util_createView("CodeGoldExpressSrc.GoldExpressBonusGameLayer", self.m_nodePos)
                    bonusView:initViewData(function(coins, extraGame)
                        self:clearCurMusicBg()
                        self:bonusGameOver(coins, extraGame, function()
                            gLobalSoundManager:setBackgroundMusicVolume(0)
                            self:showBonusMap(function()
                                gLobalSoundManager:setBackgroundMusicVolume(1)
                                self:resetMusicBg()

                                self:MachineRule_checkTriggerFeatures()
                                self:addNewGameEffect()
                                self.m_progress:resetProgress(self.m_bonusData[self.m_nodePos + 1].levelID, function()
                                    self.m_progress:runCsbAction("idleframe1",true)
                                   self.m_progress:findChild("huoche"):setVisible(true)
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                    -- self:resetMusicBg()
                                end)
                            end, self.m_nodePos)

                            if self.m_bProduceSlots_InFreeSpin == true or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins + coins)
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
                            else
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            end
                        end)
                        bonusView:removeFromParent()

                    end, self)
                    if globalData.slotRunData.machineData.p_portraitFlag then
                        bonusView.getRotateBackScaleFlag = function(  ) return false end
                    end
                    gLobalViewManager:showUI(bonusView)
                    -- self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
                    if self.m_bProduceSlots_InFreeSpin ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
                        self.m_bottomUI:checkClearWinLabel()
                    end

                end)
            end, 0)

        else
            if self.m_mapNodePos ~= self.m_nodePos then
                self.m_mapNodePos = self.m_nodePos
            end
            if self.m_normalFreeSpinTimes == 0 then
                globalData.slotRunData.lastWinCoin = 0
                self.m_bottomUI:checkClearWinLabel()
            end
            self:clearCurMusicBg()
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iBonusFreeTimes = self.m_iFreeSpinTimes
            self.m_bIsBonusFreeGame = true
            gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_viewOpen.mp3")
            local ownerlist={}
            ownerlist["more"] = self.m_iFreeSpinTimes
            local view = self:showDialog("BonusFreeGame", ownerlist, function()
                -- gLobalSoundManager:playSound("CharmsSounds/Charms_GuoChang.mp3")
                -- function( )


                    self.m_tipView_1:setVisible(false)
                    -- 调用此函数才是把当前游戏置为freespin状态
                    self:triggerFreeSpinCallFun()

                    self:changeReelsBg( true )

                    effectData.p_isPlay = true
                    self:playGameEffect()

                    -- if self.m_nodePos == #self.m_bonusPath then
                    --     self.m_map:resetMapUI()
                    -- end
                -- end
            end, BaseDialog.AUTO_TYPE_ONLY)

            performWithDelay(self, function()
                self:bonusFreeGameInfo()
                self:initFixWild()
                -- globalData.slotRunData.lastWinCoin = 0
                -- self.m_bottomUI:checkClearWinLabel()
                self.m_bottomUI:showAverageBet()
                self.m_progress:setVisible(false)

            end, 1)

            for i = 1, 5 do
                view:findChild("extra_id_"..i):setVisible(false)
                view:findChild("dui_"..i):setVisible(false)
                view:findChild("cha_"..i):setVisible(false)
                if i < 5 then
                    view:findChild("fix_wild_"..i):setVisible(false)
                end
            end

            local info = self.m_bonusData[self.m_nodePos]
            view:findChild("fix_wild_"..info.levelID):setVisible(true)
            for i = 1, #info.allGames, 1 do
                view:findChild("extra_id_"..i):setVisible(true)
                local tittle = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesTittle")
                view:findChild("extra_words_"..i):addChild(tittle)
                tittle:unselected(info.allGames[i])
                view:findChild("cha_"..i):setVisible(true)
                for j = 1, #info.extraGames, 1 do
                    if info.extraGames[j] == info.allGames[i] then
                        tittle:selected(info.allGames[i])
                        view:findChild("dui_"..i):setVisible(true)
                        view:findChild("cha_"..i):setVisible(false)
                        break
                    end
                end
            end
        end

    end

    performWithDelay(self, function()
        bonusGame()
    end, 1)

    -- performWithDelay(self, function()
    --     self:showBonusMap(bonusGame, self.m_nodePos)
    -- end, 2)


    return true
end

function CodeGameScreenGoldExpressMachine:MachineRule_checkTriggerFeatures()
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

function CodeGameScreenGoldExpressMachine:checkNetDataFeatures()

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

        -- self:sortGameEffects( )
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

        if self.checkControlerReelType and self:checkControlerReelType( ) then
            globalMachineController.m_isEffectPlaying = true
        end

        self.m_isRunningEffect = true

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

    end


end

function CodeGameScreenGoldExpressMachine:checkHasFeature( )
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

function CodeGameScreenGoldExpressMachine:addNewGameEffect()
    globalData.slotRunData.totalFreeSpinCount = (globalData.slotRunData.totalFreeSpinCount or 0) + self.m_iFreeSpinTimes
    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
    for i = effectLen, 1, -1 do
        table.remove( self.m_vecSymbolEffectType, i)
    end
end

function CodeGameScreenGoldExpressMachine:checkTriggerINFreeSpin()

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true or self.m_initSpinData.p_features[#self.m_initSpinData.p_features] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        return true
    end
    return BaseSlotoManiaMachine.checkTriggerINFreeSpin(self)
end

function CodeGameScreenGoldExpressMachine:resetViewAfterBigLevel()
    self.m_jackPotNode:setVisible(true)
    self.m_huocheBg:setVisible(false)
    self.m_logo:setVisible(true)
    self.m_bonusFreeGameBar:setPositionY(0)
    self.m_spinTimesBar:setPositionY(0)
    self.m_spinTimesBar:setPositionX(0)

end
function CodeGameScreenGoldExpressMachine:resetViewBeforeFreespin()
    -- self.m_logo:setPositionY(50)

end
function CodeGameScreenGoldExpressMachine:resetViewAfterFreespin()
    -- self.m_logo:setPositionY(0)
    self.m_bonusFreeGameBar:setVisible(false)
    self.m_spinTimesBar:findChild("GoldExpress_di"):setVisible(false)
    self.m_spinTimesBar:hideBar()
end
function CodeGameScreenGoldExpressMachine:bonusGameStart(func)
    self.m_tiggerBonus = true
    return self:showDialog(BaseDialog.DIALOG_TYPE_BONUS_START,nil,func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end


function CodeGameScreenGoldExpressMachine:initFixWild()
    local vecFixWild = nil
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWild ~= nil then
        vecFixWild = self.m_runSpinResultData.p_selfMakeData.lockWild
    end
    if vecFixWild == nil then
        return
    end
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()

    for i = 1, #vecFixWild, 1 do
        local fixPos = self:getRowAndColByPos(vecFixWild[i])
        local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX)
        if not targSp then
            local colParent = self:getReelParent(fixPos.iY)
            local children = colParent:getChildren()
            for i = 1, #children, 1 do
                local child = children[i]
                if child.p_cloumnIndex == fixPos.iY and child.p_rowIndex == fixPos.iX then
                    targSp = child
                    break
                end
            end
        end
        if targSp then
            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                targSp:getParent():addChild(wild)
                wild:setPosition(targSp:getPositionX(), targSp:getPositionY())
                wild.p_cloumnIndex = targSp.p_cloumnIndex
                wild.p_rowIndex = targSp.p_rowIndex
                wild.m_isLastSymbol = targSp.m_isLastSymbol
                wild:setTag(targSp:getTag())
                targSp:removeFromParent()
                local symbolType = targSp.p_symbolType
                self:pushSlotNodeToPoolBySymobolType(symbolType, targSp)
                targSp = nil
                targSp = wild
            end
            if targSp:getChildByName("tips") ~= nil then
                targSp:getChildByName("tips"):removeFromParent(true)
            end
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            if self.m_vecFixWild == nil then
                self.m_vecFixWild = {}
            end
            self.m_vecFixWild[#self.m_vecFixWild + 1] = targSp
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
        end
    end
end


function CodeGameScreenGoldExpressMachine:showBonusMap(callback, nodePos)

    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true) and callback == nil then
        return
    end
    self.m_bCanClickMap = false
    -- self.m_map:setMapCanTouch(false)
    if self.m_map:getMapIsShow() == true then
        self.m_map:mapDisappear(function()
            self.m_bCanClickMap = true
        end)
    else
        gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_openMap.mp3")

        self.m_map:mapAppear(function()
            self.m_bCanClickMap = true
            if callback ~= nil then
                self.m_map:pandaMove(callback, self.m_bonusData, nodePos)
                -- performWithDelay(self,function()
                --     self.m_map:setMapCanTouch(true)
                -- end,2)
            end
        end)
        if callback ~= nil then
            self.m_map:setMapCanTouch(true)
        end
    end

end

function CodeGameScreenGoldExpressMachine:BaseMania_updateCollect(addCount,index,totalCount)
    if not index then
        index=1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index])=="table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

function CodeGameScreenGoldExpressMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount,1,totalCount)
    end

end
function CodeGameScreenGoldExpressMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList={}
    --默认总数

    self.m_collectDataList[1] = CollectData.new()
    self.m_collectDataList[1].p_collectTotalCount = 150
    self.m_collectDataList[1].p_collectLeftCount = 150
    self.m_collectDataList[1].p_collectCoinsPool = 0
    self.m_collectDataList[1].p_collectChangeCount = 0

end
----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenGoldExpressMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return true
    end
    return false
end

---
-- 处理spin 返回结果
function CodeGameScreenGoldExpressMachine:spinResultCallFun(param)
    self.m_iFixSymbolNum = 0
    self.m_bFlagRespinNumChange = false
    self.m_vecExpressSound = {false, false, false, false, false}

    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime
    
    self:checkTestConfigType(param)
    
    local isOpera = self:checkOpearReSpinAndSpecialReels(param)  -- 处理respin逻辑
    if isOpera == true then
        return 
    end

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end
end

----
--- 处理spin 成功消息
--
function CodeGameScreenGoldExpressMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or (self:getIsBigLevel() == true and spinData.action == "FEATURE")  then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")

        if self.m_bonusGameReel ~= nil then
            local resultData = spinData.result.selfData.otherReel
            resultData.bet = 1
            self.m_bonusGameReel:netWorkCallFun(resultData)
        end
    end
end

function CodeGameScreenGoldExpressMachine:bonusGameOver(coins, extraGame, func)

    self.m_tipView_1:setVisible(true)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        self.m_tipView_1:setVisible(false)
    end

    local ownerlist={}
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    -- self:clearCurMusicBg()
    gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_viewClose.mp3", false)
    if extraGame == nil then
        local view =  self:showDialog(BaseDialog.DIALOG_TYPE_BONUS_OVER,ownerlist,func)
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.95,sy=0.95},601)
    else
        local view = self:showDialog("BonusOver2",ownerlist,func)
        local tittle = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesDialog", self.m_nodePos)
        view:findChild("Extra_Game"):addChild(tittle)
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.95,sy=0.95},554)
    end
    self.m_freeSpinOverCurrentTime = 2
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenGoldExpressMachine:playEffectNotifyNextSpinCall( )
    self.m_bSlotRunning = false

    BaseSlotoManiaMachine.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

--
--单列滚动停止回调
--
function CodeGameScreenGoldExpressMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local vecBonus = {}
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                self.m_iFixSymbolNum = self.m_iFixSymbolNum + 1
                local node =  self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,  k, SYMBOL_NODE_TAG))
                vecBonus[#vecBonus + 1] = node
            end
        end
        if (reelCol == 4 and self.m_iFixSymbolNum < 2) or (reelCol == 5 and self.m_iFixSymbolNum < 5) then
            for i = #vecBonus, 1, -1 do
                local symbolNode = vecBonus[i]
                symbolNode.p_reelDownRunAnima = nil
                symbolNode.p_reelDownRunAnimaSound = nil
            end
        end
    end

end

function CodeGameScreenGoldExpressMachine:reelDownNotifyPlayGameEffect( )
    if  self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true
    then
        local pos = self.m_runSpinResultData.p_selfMakeData.currPosition
        if pos ~= nil and pos > 0 and self.m_bonusData[pos].type == "BIG" then
            local effectLen = #self.m_gameEffects
            for i = 1, effectLen, 1 do
                local gameEffect = self.m_gameEffects[i]
                if gameEffect.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                    table.remove( self.m_gameEffects, i)
                    table.insert( self.m_gameEffects, gameEffect)
                    break
                end
            end
            for i = 1, effectLen, 1 do
                local gameEffect = self.m_gameEffects[i]
                if gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
                    table.remove( self.m_gameEffects, i)
                    table.insert( self.m_gameEffects, gameEffect)
                    break
                end
            end
        end
    end
    BaseMachine.reelDownNotifyPlayGameEffect(self)
end

function CodeGameScreenGoldExpressMachine:changeExpressScore(func)
    local changeCol = self.m_runSpinResultData.p_selfMakeData.column
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local score = storedIcons[i][2]

        if id % self.m_iReelColumnNum == changeCol - 1 then
            local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
            if score < 1 and score > 0 then
                score = score * globalData.slotRunData:getCurTotalBet()
                score = util_formatCoins(score, 4)
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
                symbolNode:runAnim("change", false, function()
                    symbolNode:runAnim("idle2", true)
                end)
            else
                score = score * globalData.slotRunData:getCurTotalBet()
                score = util_formatCoins(score, 4)
                symbolNode:runAnim("Add", false, function()
                    symbolNode:runAnim("idle2", true)
                end)
                performWithDelay(self,function()
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end, 1 / 3)
            end
        end
    end
    performWithDelay(self,function()
        if func ~= nil then
            -- self.m_selectedColEffect:setVisible(false)
            self.m_changeScoreEffect:setVisible(false)
            func()
        end
    end, 0.8)
end

---判断结算
function CodeGameScreenGoldExpressMachine:reSpinReelDown()

    self:updateQuestUI()
    self.m_iGoldExpressNum = #self.m_runSpinResultData.p_storedIcons
    self.m_jackPotNode:showJackptSelected(self.m_iGoldExpressNum)

    local callBack = nil
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        callBack = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()

            --结束
            self:reSpinEndAction()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false
        end

    else
        callBack = function()
            
            self:setGameSpinStage(STOP_RUN)
            
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end

            self:runNextReSpinReel()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
    self:chooseAddScoreCol(function()
        gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_change_2_coin.mp3")
        self:changeExpressScore(callBack)
    end)

end


---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenGoldExpressMachine:levelFreeSpinEffectChange()

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal_freespin")
    self.m_spinTimesBar:changeFreeSpinByCount()
    self.m_spinTimesBar:showBar()
    self.m_spinTimesBar:resetUIBuyMode("freespin")
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenGoldExpressMachine:levelFreeSpinOverChangeEffect()

    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin_normal")
    self.m_spinTimesBar:hideBar()
    self.m_tipView_1:setVisible(true)

end
---------------------------------------------------------------------------


-- 触发freespin时调用
function CodeGameScreenGoldExpressMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_fs_start.mp3")
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            self.m_normalFreeSpinTimes = self.m_normalFreeSpinTimes + self.m_runSpinResultData.p_freeSpinNewCount
        else
            self.m_normalFreeSpinTimes = self.m_iFreeSpinTimes
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                    

                -- performWithDelay(self, function()
                    self:resetViewBeforeFreespin()
                    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_click.mp3")

                    self:changeReelsBg( true )
                    self.m_tipView_1:setVisible(false)
                    self:triggerFreeSpinCallFun()

                    self:changeReelsBg( true )

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    gLobalNoticManager:postNotification(
                                ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                {SpinBtn_Type.BtnType_Stop, false}
                            )

                            scheduler.performWithDelayGlobal(
                                function()
                                    self.m_freeSpinStartEffect:setVisible(true)
                                    self.m_freeSpinStartEffect:toAction("actionframe")
                                    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_add_wild.mp3")
                                end,
                                0.5,
                                self:getModuleName()
                            )
                -- end, 0.5)

            end)
        end
    end
    -- self.m_jackPotNode:setVisible(false)

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()
    end,0.5)

end



function CodeGameScreenGoldExpressMachine:showFreeSpinOverView()

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
    if self.m_fsReelDataIndex ~= 0 then
        self.m_fsReelDataIndex = 0
    end
    if self.m_bIsBonusFreeGame == true then
        -- gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_bonusgame_over.mp3")
        self.m_bIsBonusFreeGame = false
        local ownerlist={}
        ownerlist["m_lb_num"] = self.m_iBonusFreeTimes
        ownerlist["m_lb_coins"] = util_formatCoins(self.m_runSpinResultData.p_selfMakeData.countCoins, 30)
        gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_viewClose.mp3", false)
        local view = self:showDialog("BonusFreeGameOver", ownerlist, function()
        performWithDelay(self,function()
            -- self.m_PandaToFish:setVisible(true)
            -- self.m_PandaToFish:actionChange(false,function( )
            --     self.m_PandaToFish:setVisible(false)
                self:showBonusMap(function()
                    self:MachineRule_checkTriggerFeatures()
                    self:addNewGameEffect()

                    local index = nil
                    if self.m_nodePos < #self.m_bonusData then
                        index = self.m_bonusData[self.m_nodePos + 1].levelID
                    else
                        self.m_nodePos = 0
                        self.m_map:mapReset()
                    end
                    self.m_progress:resetProgress(index, function()


                        self:resetViewAfterBigLevel()
                        local haveNext = false
                        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                            haveNext = true
                        end
                        self:triggerFreeSpinOverCallFun(haveNext)
                        self:changeReelsBg( false )

                        self.m_progress.m_csbOwner["reel_s"]:setVisible(true)
                        self.m_progress.m_csbOwner["reel_1"]:setVisible(true)
                        

                        if haveNext == true then
                            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                            self:triggerFreeSpinCallFun()
                            self:changeReelsBg( true )
                            self.m_tipView_1:setVisible(false)

                        end

                    end)
                    -- self:resetMusicBg()
                end, self.m_nodePos)
            end,2)
            performWithDelay(self, function()
                self.m_bonusFreeGameBar:setVisible(false)
                self.m_spinTimesBar:findChild("GoldExpress_di"):setVisible(false)
                self.m_bottomUI:hideAverageBet()
                self.m_progress:setVisible(true)

                if self.m_vecFixWild ~= nil and #self.m_vecFixWild > 0 then
                    for i = #self.m_vecFixWild, 1, -1 do
                        local symbol = self.m_vecFixWild[i]
                        if symbol then
                            if symbol and symbol.updateLayerTag then
                                symbol:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                            end
                            symbol:setVisible(false)
                            symbol:removeFromParent()
                            self:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType, symbol)
                            
                            -- symbol:removeFromParent()

                        end
                        table.remove(self.m_vecFixWild, i)
                    end
                end

                self:clearWinLineEffect()
                self:resetMaskLayerNodes()

                if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                    self:removeAllReelsNode()
                end
                -- util_setCsbVisible(self.m_baseFreeSpinBar, false)
                if self.m_iReelRowNum > self.m_iReelMinRow then
                    self.m_iReelRowNum = self.m_iReelMinRow
                    self:changeReelData()
                end
                if self.m_bonusGameReel ~= nil then
                    self.m_jackPotNode:setVisible(true)
                    self.m_bonusGameReel:removeFromParent()
                    self.m_bonusGameReel = nil
                end

                if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                    self:createRandomReelsNode()
                end

            end, 1)

        end)
        local node=view:findChild("m_lb_coins")

        view:updateLabelSize({label=node,sx=0.8,sy=0.8},632)
        for i = 1, 5 do
            view:findChild("extra_id_"..i):setVisible(false)
            view:findChild("dui_"..i):setVisible(false)
            view:findChild("cha_"..i):setVisible(false)
        end

        local info = self.m_bonusData[self.m_nodePos]
        for i = 1, #info.allGames, 1 do
            view:findChild("extra_id_"..i):setVisible(true)
            local tittle = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesTittle")
            view:findChild("extra_words_"..i):addChild(tittle)
            tittle:unselected(info.allGames[i])
            view:findChild("cha_"..i):setVisible(true)
            for j = 1, #info.extraGames, 1 do
                if info.extraGames[j] == info.allGames[i] then
                    tittle:selected(info.allGames[i])
                    view:findChild("dui_"..i):setVisible(true)
                    view:findChild("cha_"..i):setVisible(false)
                    break
                end
            end
        end
    else
        gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_pop_fs_over.mp3")

        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
        local view = self:showFreeSpinOver( strCoins,
            self.m_normalFreeSpinTimes,function()
                gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_click.mp3")
            -- 调用此函数才是把当前游戏置为freespin结束状态
                self:triggerFreeSpinOverCallFun()
                self:changeReelsBg( false )
                self.m_normalFreeSpinTimes = 0
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label = node,sx = 1, sy = 1}, 590)
        self.m_jackPotNode:setVisible(true)
    end
    self:resetViewAfterFreespin()
    -- self:changeReelData()

end

function CodeGameScreenGoldExpressMachine:triggerFreeSpinOverCallFun(notAddCoin2Top)

    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    if self.postFreeSpinOverTriggerBigWIn then
        self:postFreeSpinOverTriggerBigWIn( _coins) 
    end
    
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode( NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")

    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    self:resetMusicBg()
    if notAddCoin2Top ~= true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenGoldExpressMachine:createRandomReelsNode(  )

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
                if newNode:getParent() then
                    print("qaq")
                end
                newNode:removeFromParent()  -- 暂时补丁
                parentData.slotParent:addChild(
                    newNode,
                    REEL_SYMBOL_ORDER.REEL_ORDER_2,
                    iCol * SYMBOL_NODE_TAG + iRow
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
end
function CodeGameScreenGoldExpressMachine:removeAllReelsNode( )


    for iCol = 1, self.m_iReelColumnNum do

        for iRow = 1, self.m_iReelRowNum do

            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)

            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end

        end
    end
    --bugly-21.12.01-这个地方需要清空一下 连线信号列表 不然操作已经被放入池子的信号会有问题
    self.m_lineSlotNodes = {}
end

function CodeGameScreenGoldExpressMachine:changeReelData()
    self:findChild("Lun_pan4x5"):setVisible(false)
    self:findChild("Lun_pan3x5"):setVisible(false)

    

    self:findChild("Lun_pan"..self.m_iReelRowNum.."x5"):setVisible(true)
    if self.m_iReelRowNum == self.m_iReelMinRow then

        -- self.m_bonusFreeGameBar:removeFromParent()
        -- self:findChild("Node_3x5"):addChild(self.m_bonusFreeGameBar)
        self.m_bonusFreeGameBar:setPositionY(0)

        -- self.m_baseFreeSpinBar:setPositionY(0)
        -- self.m_bonusFreeGameBar:setPositionY(self.m_baseFreeSpinBar:getPositionY() + 90)
        self.m_stcValidSymbolMatrix[4] = nil
    else
        -- self.m_bonusFreeGameBar:removeFromParent()
        -- local  node45 =  self:findChild("Node_4x5")
        -- node45:addChild(self.m_bonusFreeGameBar)
        -- self.m_baseFreeSpinBar:setPositionY(self.m_SlotNodeH)
        self.m_bonusFreeGameBar:setPositionY(self.m_bonusFreeGameBar:getPositionY() + 90)
        if self.m_stcValidSymbolMatrix[4] == nil then
            self.m_stcValidSymbolMatrix[4] = {92, 92, 92, 92, 92}
        end
    end
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = columnData.p_slotColumnHeight
            }
        )
    end
end

function CodeGameScreenGoldExpressMachine:showRespinJackpot(index,coins,func)

    local jackPotWinView = util_createView("CodeGoldExpressSrc.GoldExpressJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
end

-- 结束respin收集
function CodeGameScreenGoldExpressMachine:playLightEffectEnd()

    local startPos = self.m_jackPotNode:showJackpotAnimation()
    local node = self.m_bottomUI.m_normalWinLabel
    local endPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local particle = cc.ParticleSystemQuad:create("GoldExpress_JackPot_jiesuan_17.plist")
    self:addChild(particle, 1000000)
    particle:setPosition(startPos)
    particle:setVisible(true)
    
    -- self:playCoinWinEffectUI()

    local moveTo = cc.MoveTo:create(0.4, endPos)
    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(function()

        

        performWithDelay(self, function()
            local effect, act = util_csbCreate("GoldExpress_jiesuan.csb")
            self.m_bottomUI.m_normalWinLabel:getParent():addChild(effect)
            effect:setPosition(self.m_bottomUI.m_normalWinLabel:getPositionX(), self.m_bottomUI.m_normalWinLabel:getPositionY())
            util_csbPlayForKey(act, "animation0", false, function()
                effect:removeFromParent(true)
            end)

            self:playCoinWinEffectUI()
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_serverWinCoins))
        end, 0.3)

        particle:stopSystem()
        performWithDelay(self, function()
            particle:removeFromParent(true)
        end, 1.5)
        performWithDelay(self, function ()
            self:respinOver()
        end, 1.7)
    end)))

end

function CodeGameScreenGoldExpressMachine:cleanRespinGray()
    for iCol = 1, self.m_iReelColumnNum  do         --列
        for iRow = self.m_iReelRowNum , 1, -1 do     --行
            if self.m_stcValidSymbolMatrix[iRow][iCol] ~= self.SYMBOL_FIX_SYMBOL then
                local node =  self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol,  iRow, SYMBOL_NODE_TAG))
                local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
                if imageName ~= nil then
                    node:spriteChangeImage(node.p_symbolImage,imageName)
                end
            end
        end
    end
end

function CodeGameScreenGoldExpressMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        -- 此处跳出迭代
        performWithDelay(self, function ()
            if #self.m_chipList < 7 then
                self:respinOver()
            else
                self:playLightEffectEnd()
            end

        end, 0.5)

        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_bottomUI:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    -- 根据网络数据获得当前固定小块的分数
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    if score == 0 then
        self.m_playAnimIndex = self. m_playAnimIndex + 1
        chipNode:runAnim("idle", false)

        self:playChipCollectAnim()
        return
    end
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local addScore = score * lineBet

    self.m_lightScore = self.m_lightScore + addScore

    local collectEnd = function ()
        self.m_playAnimIndex = self. m_playAnimIndex + 1
        self:playChipCollectAnim()
    end

    local collectEffect = function()
      
        chipNode:runAnim("jiesuan2", false, function()

        end)
        gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_rs_jiesuan.mp3")
        local effect, act = util_csbCreate("GoldExpress_jiesuan.csb")
        self.m_bottomUI.m_normalWinLabel:getParent():addChild(effect)

        self:playCoinWinEffectUI()
        effect:setVisible(false)
        
        effect:setPosition(self.m_bottomUI.m_normalWinLabel:getPositionX(), self.m_bottomUI.m_normalWinLabel:getPositionY())
        util_csbPlayForKey(act, "animation0", false, function()
            
            effect:removeFromParent(true)
        end)
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode, function()
            
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))

            collectEnd()
            
            waitNode:removeFromParent()

        end, 0.4)
    end


    collectEffect()

end

function CodeGameScreenGoldExpressMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    else
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1
    end
    return order

end

--结束移除小块调用结算特效
function CodeGameScreenGoldExpressMachine:reSpinEndAction()

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()


    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_respin_over.mp3")
    performWithDelay(self, function ()
        self:playChipCollectAnim()
    end, 3.5)

end

-- 根据本关卡实际小块数量填写
function CodeGameScreenGoldExpressMachine:getRespinRandomTypes( )
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenGoldExpressMachine:getRespinLockTypes( )
    local symbolList =
    {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenGoldExpressMachine:showRespinView()

    self.m_bottomUI:updateWinCount("")
          --先播放动画 再进入respin
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_rs_start.mp3")
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)

    if self.m_bIsRespinReconnect == true then
        self.m_bIsRespinReconnect = false
        self.m_respinView:setReconnect(true)

        local express = self.m_respinView:getAllCleaningNode()
        for i = 1, #express, 1 do
            local chipNode = express[i]
            local iCol = chipNode.p_cloumnIndex
            local iRow = chipNode.p_rowIndex
            -- 根据网络数据获得当前固定小块的分数
            local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
            if score == 0 then
                chipNode:runAnim("idle", true)
            else
                score = score * globalData.slotRunData:getCurTotalBet()
                score = util_formatCoins(score, 4)
                chipNode:runAnim("idle2", true)
                chipNode:getCcbProperty("m_lb_score"):setString(score)
            end
        end
    end
    self.m_respinView:setOneReelDownCallback(function()
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        if self.m_runSpinResultData.p_reSpinCurCount == 3 and self.m_bFlagRespinNumChange ~= true then
            self.m_bFlagRespinNumChange = true
            self.m_spinTimesBar:addRespinEffect()
            gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_rs_num_reset.mp3")
        end
    end)
end

function CodeGameScreenGoldExpressMachine:showReSpinStart(func)

    self.m_tipView_1:setVisible(false)

    self:clearCurMusicBg()
    self.m_expressRun:setVisible(true)
    util_spinePlay(self.m_expressRun, "actionframe", false)
    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_guochang.mp3")

    util_spineEndCallFunc(self.m_expressRun, "actionframe", function()
        self.m_expressRun:setVisible(false)
        if func ~= nil then
            func()
        end
    end)

    performWithDelay(self, function()
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"freespin_respin",false , function(  )
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"freespin",true})
            -- end})
        else
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"normal_freespin",false , function(  )
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"freespin",true})
            end})
            self.m_spinTimesBar:showBar()
        end
        self.m_spinTimesBar:resetUIBuyMode("respin")
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self:changeReSpinStartUI()
    end, 0.8)
end

--ReSpin开始改变UI状态
function CodeGameScreenGoldExpressMachine:changeReSpinStartUI(respinCount)
    self.m_iGoldExpressNum = #self.m_runSpinResultData.p_storedIcons
    self.m_jackPotNode:showJackptSelected(self.m_iGoldExpressNum)
    -- self.m_spinTimesBar:setPositionY(-63)
    self:changeReelsBg( true )
end

--ReSpin刷新数量
function CodeGameScreenGoldExpressMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_spinTimesBar:updateSpinNum(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenGoldExpressMachine:changeReSpinOverUI()
    -- self.m_spinTimesBar:setPositionY(0)
    -- self.m_progress:setVisible(true)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        --gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"respin_freespin")
        self.m_spinTimesBar:resetUIBuyMode("freespin")
        self.m_spinTimesBar:updateSpinNum(self.m_runSpinResultData.p_freeSpinsLeftCount)
    else
        self.m_tipView_1:setVisible(true)
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin_normal")
        self.m_spinTimesBar:hideBar()
    end

    self.m_jackPotNode:resetDataAndAnimation()
end

function CodeGameScreenGoldExpressMachine:showRespinOverView(effectData)

    local coins = self.m_serverWinCoins - self.m_lightScore

    local clickCallback = function()
        gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_click.mp3")
        self:MachineRule_afterNetWorkLineLogicCalculate()
        self:addSelfEffect()
        self:triggerReSpinOverCallFun(self.m_serverWinCoins)
        self:MachineRule_checkTriggerFeatures()
        self:addNewGameEffect()
        self.m_lightScore = 0
        self:resetMusicBg()

        self:changeReelsBg( false )

    end
    local jackPotNum = #self.m_runSpinResultData.p_storedIcons
    -- if jackPotNum > self.m_vecJackpotNum[self.m_iBetLevel] then
    --     jackPotNum = self.m_vecJackpotNum[self.m_iBetLevel]
    -- end
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, "ReSpinOver", clickCallback)
    local ownerlist={}
    ownerlist["m_lb_coins"] = util_formatCoins(self.m_lightScore, 30)
    ownerlist["m_lb_jackPot"] = util_formatCoins(coins, 30)
    ownerlist["m_lb_jackPot_num"] = jackPotNum
    view:updateOwnerVar(ownerlist)

    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_pop_rs_over.mp3")
    local labCoin = view:findChild("m_lb_coins")
    view:updateLabelSize({label = labCoin,sx = 1, sy = 1}, 590)
    local labJackpot = view:findChild("m_lb_jackPot")
    view:updateLabelSize({label = labJackpot,sx = 1, sy = 1}, 590)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)

    self:changeReelData()
    performWithDelay(self, function()
        self:cleanRespinGray()
    end, 0.5)

end


-- --重写组织respinData信息
function CodeGameScreenGoldExpressMachine:getRespinSpinData()
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
function CodeGameScreenGoldExpressMachine:MachineRule_SpinBtnCall()


    if not self.m_tipView.isOverAct then
        
        if not self.m_tipView.isSpin then
            self.m_tipView:runCsbAction("over",false,function(  )
                self.m_tipView:setVisible(false)
            end) 
        end
        
    end
    
    self.m_tipView.isSpin = true


    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil
    gLobalSoundManager:setBackgroundMusicVolume(1)
    if self.m_map:getMapIsShow() == true then
        self:showBonusMap()
    end
    self.m_bSlotRunning = true
    return false -- 用作延时点击spin调用
end




function CodeGameScreenGoldExpressMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_enter_game.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus and not self.m_tiggerBonus then
                self:resetMusicBg()
                gLobalSoundManager:setBackgroundMusicVolume(0)
            end

        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenGoldExpressMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    self:updateBetLevel()
    self.m_jackPotNode:initLockUI(self.m_specialBets, self.m_iBetLevel)

    if self.m_bIsRespinReconnect == true then
        self.m_spinTimesBar:resetUIBuyMode("respin")
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end
    if self.m_bonusData then
        local levelId = nil
        if self.m_bonusData[self.m_mapNodePos + 1] and self.m_bonusData[self.m_mapNodePos + 1].levelID then
            levelId = self.m_bonusData[self.m_mapNodePos + 1].levelID
            self.m_progress:setPercent(self.m_collectProgress, levelId)
        else
            self.m_progress:setPercent(self.m_collectProgress)
        end
    end

    if self.m_iBetLevel == 1 then
        self.m_progress:idle()
    else
        self.m_progress:lock(self.m_iBetLevel)
    end

    if self.m_map == nil then
        self.m_map = util_createView("CodeGoldExpressSrc.GoldExpressBonusMapScrollView", self.m_bonusData, self.m_mapNodePos)
        self:findChild("map"):addChild(self.m_map)
        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_map.getRotateBackScaleFlag = function(  ) return false end
        end

    end
end

function CodeGameScreenGoldExpressMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel > self.m_iBetLevel then
            self.m_progress:lock(self.m_iBetLevel)
            self.m_jackPotNode:unlockJackptByBetLevel(self.m_iBetLevel)
            gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_change_normal.mp3")
        elseif perBetLevel < self.m_iBetLevel then
            self.m_progress:unlock(self.m_iBetLevel)
            self.m_jackPotNode:lockJackptByBetLevel(self.m_iBetLevel)
        end
   end,ViewEventType.NOTIFY_BET_CHANGE)

   gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

    gLobalNoticManager:addObserver(self,function(self,params)
        if self.getCurrSpinMode() ~= RESPIN_MODE and self.getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:showBonusMap()
        end
    end,"SHOW_BONUS_MAP")

end

function CodeGameScreenGoldExpressMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end



-- ------------玩法处理 --

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenGoldExpressMachine:MachineRule_network_InterveneSymbolMap()

end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGoldExpressMachine:addSelfEffect()

    if self.m_iBetLevel == 1 and self.m_runSpinResultData.p_reSpinCurCount == 0 then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node then
                    if node.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end


                        self.m_collectList[#self.m_collectList + 1] = node--:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    end
                end
            end
        end
    end
        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
    if self.m_collectList and #self.m_collectList > 0 then

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT

        --是否触发收集小游戏
        if self:BaseMania_isTriggerCollectBonus() then -- true or
            self.m_bHaveBonusGame = true
        end
    end
end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGoldExpressMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:collectPanda(effectData)
    end

	return true

end

function CodeGameScreenGoldExpressMachine:collectPanda(effectData)

    local endPos = self.m_progress:getCollectPos()

    -- coins:runAnim("shouji")
    local isTrigger = self:BaseMania_isTriggerCollectBonus()

    gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_collect_item.mp3")
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

        -- local startPos = node:getParent():convertToWorldSpace(node:getPosition())
        local newStartPos = self:convertToNodeSpace(startPos)
        -- local coins = cc.ParticleSystemQuad:create("Effect/GoldExpress_Bonus_Trail.plist")
        -- node:runAnim("shouji",false,function()
        -- end)
        local coins, act = util_csbCreate("GoldExpress_shouji.csb")
        local isLastSymbol = coins.m_isLastSymbol
        if i == 1 then
            isLastSymbol = true
        end
        coins.m_isLastSymbol = isLastSymbol
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        -- coins:setScale(self.m_machineRootScale)
        coins:setPosition(newStartPos)

        local delayTime = 0
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true or
            self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            delayTime = 0.5
        end

        util_csbPlayForKey(act, "animation0", false)
        local pecent = self:getProgress(self:BaseMania_getCollectData())
        -- performWithDelay(self, function()
            if self.m_bHaveBonusGame ~= true and isLastSymbol == true then
                performWithDelay(self, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, delayTime)
            end
        -- end, 0.2)
        
        scheduler.performWithDelayGlobal(function()
            -- if self.m_bHaveBonusGame ~= true and isLastSymbol == true then
            --     performWithDelay(self, function()
            --         effectData.p_isPlay = true
            --         self:playGameEffect()
            --     end, delayTime)
            -- end
            -- local particle = cc.ParticleSystemQuad:create("effect/Golden_Charms_Fly_gold.plist")
            -- coins:addChild(particle,10)
            -- particle:setPosition(0, 0)

            local isTrigger_1 = isTrigger

            local bez =
            cc.BezierTo:create(
            0.5,
            {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
            local callback = function()
                coins:removeFromParent()
                if isLastSymbol == true then
                    self.m_progress:updatePercent(pecent,function()
                        if self.m_bHaveBonusGame == true and isLastSymbol == true and isTrigger_1 then
                            gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_collectfull.mp3")

                            self.m_progress:runCsbAction("actionframe3",false,function()
                                self.m_progress:runCsbAction("idle2",true)
                                performWithDelay(self,function()
                                    self.m_progress:findChild("huoche"):setVisible(false)
                                end,1)
                                effectData.p_isPlay = true
                                self:playGameEffect()
                                self.m_bHaveBonusGame = false
                            end)
                        end
                    end)
                    -- gLobalSoundManager:playSound("CharmsSounds/sound_Charms_tramcar_move.mp3")

                end
            end
            coins:runAction(cc.Sequence:create(bez, cc.CallFunc:create(callback)))
        end, 0.5, self:getModuleName())
        table.remove(self.m_collectList, i)
    end
end


function CodeGameScreenGoldExpressMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if  betCoin == nil or betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end


function CodeGameScreenGoldExpressMachine:unlockHigherBet()
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
    gLobalSoundManager:playSound("GoldExpressSounds/sound_bonus_unlock.mp3")

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenGoldExpressMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

function CodeGameScreenGoldExpressMachine:requestSpinResult()

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

function CodeGameScreenGoldExpressMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("Node_bg"):addChild(gameBg,-1)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg

end

function CodeGameScreenGoldExpressMachine:changeReelsBg( isFur )

    for i=1,5 do
        local bg =  self:findChild("sp_reel_" .. (i -1) .. "_1")
        if bg then
            if isFur then
                bg:setVisible(true)
            else
                bg:setVisible(false)
            end
        end
    end
    
end

return CodeGameScreenGoldExpressMachine






