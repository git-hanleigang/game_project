---
-- island li
-- 2019年1月26日
-- CodeGameScreenWickedWinsMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local WickedWinsMusicConfig = require "WickedWinsPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenWickedWinsMachine = class("CodeGameScreenWickedWinsMachine", BaseSlotoManiaMachine)

CodeGameScreenWickedWinsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenWickedWinsMachine.m_videoPokerScale = 0.8
CodeGameScreenWickedWinsMachine.m_videoPokerPosX = 18
CodeGameScreenWickedWinsMachine.m_videoPokerPosY = 12
CodeGameScreenWickedWinsMachine.m_videoPokerMainScaleMul = 1

CodeGameScreenWickedWinsMachine.m_tblNodeNameList = {"Node_top", "Node_left", "Node_bottom", "Node_right"}
CodeGameScreenWickedWinsMachine.m_directionArry = {-5, 1, 5, -1} -- 偏移量,上、右、下、左
CodeGameScreenWickedWinsMachine.m_iLinkBonusNum = 0
CodeGameScreenWickedWinsMachine.m_iLinkLastBonusNum = 0

CodeGameScreenWickedWinsMachine.SYMBOL_SCORE_BONUS = 94
CodeGameScreenWickedWinsMachine.SYMBOL_SCORE_NULL = 100
CodeGameScreenWickedWinsMachine.SYMBOL_SCORE_JACKPOT_MINI = 101
CodeGameScreenWickedWinsMachine.SYMBOL_SCORE_JACKPOT_MINOR = 102
CodeGameScreenWickedWinsMachine.SYMBOL_SCORE_JACKPOT_MAJOR = 103
CodeGameScreenWickedWinsMachine.SYMBOL_SCORE_BG = 200

CodeGameScreenWickedWinsMachine.EFFECT_BIGWILD_PLAY = GameEffect.EFFECT_SELF_EFFECT - 3

-- CodeGameScreenWickedWinsMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
-- CodeGameScreenWickedWinsMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识



-- 构造函数
function CodeGameScreenWickedWinsMachine:ctor()
    CodeGameScreenWickedWinsMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WickedWinsConfig.csv", "LevelWickedWinsPublicConfig.lua")

    self.m_videoPokeMgr = util_require("LevelVideoPokerCode.VideoPokeManager"):getInstance()
    if self:checkControlerReelType() then
        self.m_videoPokeMgr:initData( self )
    end

    self.ENUM_DIRECTION = {
        ["top"] = -5,
        ["right"] = 1,
        ["bottom"] = 5,
        ["left"] = -1,
    }
    self.ENUM_LINE_DIRECTION = {
        ["right"] = 1,
        ["down"] = 2,
        ["left"] = 3,
        ["up"] = 4,
    }
    self.m_lightScore = 0
    self.m_spinRestMusicBG = true
    self.m_aFreeSpinWildArry = {}
    self.tblRespinBgNode = {}
    self.tblClipNode = {}
    self.tblClipSize = {179, 235, 179, 235}
    self.ABTEST = false
    self.playSymbolNode = nil
    self.tblBigWildSpine = {}
    self.tblRightJackpot = {}
    self.tblRightJackpotNode = {}
    self.tblRightJackpotData = {}

    self.tblLastTimeLineInfo = {}
    self.tblStartLineInfo = {}
    self.tblOverLineInfo = {}
    self.m_isShowBonusText = true
    self.m_panelOpacity = 102
    self.triggerRespinDelayTime = 0
    self.isPlayLineSound = true
    
    self.m_symbolNodeRandom = {
        1, 6, 11, 16, 2,
        7, 12, 17, 3, 8,
        13, 18, 4, 9, 14,
        19, 5, 10, 15, 20
    }
 
    self.m_isBonusTrigger = false
    --init
    self:initGame()
end

function CodeGameScreenWickedWinsMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWickedWinsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WickedWins"  
end

-- 继承底层respinNode
function CodeGameScreenWickedWinsMachine:getRespinNode()
    return "CodeWickedWinsSrc.WickedWinsRespinNode"
end

-- 继承底层respinNode
function CodeGameScreenWickedWinsMachine:getRespinView()
    return "CodeWickedWinsSrc.WickedWinsRespinView"
end

function CodeGameScreenWickedWinsMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --遮罩
    self.m_panelUpList = self:createRoyaleBattleMask(self)

    self.m_jackpotWinView = util_createView("CodeWickedWinsSrc.WickedWinsJackpotWinView", self)
    self:addChild(self.m_jackpotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_jackpotWinView:setVisible(false)

    self.m_jackPotBar = util_createView("CodeWickedWinsSrc.WickedWinsJackPotBarView")
    self:findChild("Jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_chooseView = util_createView("CodeWickedWinsSrc.WickedWinschoosePlayView")
    self:addChild(self.m_chooseView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_chooseView:initMachine(self)
    self.m_chooseView:setVisible(false)

    self.m_baseReSpinBar = util_createView("CodeWickedWinsSrc.WickedWinsRespinBarView")
    self:findChild("RespinLeft"):addChild(self.m_baseReSpinBar)
    self.m_baseReSpinBar:setVisible(false)
   
    self.m_baseFreeSpinBar = util_createView("CodeWickedWinsSrc.WickedWinsFreespinBarView")
    self:findChild("FGspins"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)

    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Node_reel_base")
    self.m_reelBg[2] = self:findChild("Node_reel_FG")
    self.m_reelBg[3] = self:findChild("Node_reel_respin")

    self.m_cutSceneSpine = util_spineCreate("WickedWins_guochang",true,true)
    self:findChild("Node_cut_scene"):addChild(self.m_cutSceneSpine)
    self.m_cutSceneSpine:setVisible(false)

    self.m_cutSceneAni = util_createAnimation("WickedWins_guochang.csb")
    self:findChild("Node_cut_scene"):addChild(self.m_cutSceneAni)
    self.m_cutSceneAni:setVisible(false)

    self.m_grandAni = util_createAnimation("WickedWins_grandL.csb")
    self:findChild("Node_cut_scene"):addChild(self.m_grandAni)
    self.m_grandAni:setVisible(false)

    self.m_grandSpine = util_spineCreate("Socre_WickedWins_Bonus",true,true)
    self:findChild("Node_cut_scene"):addChild(self.m_grandSpine)
    self.m_grandSpine:setVisible(false)

    self.m_showJackpotNode = self:findChild("ShowJackpot")
    self.m_rightJackpot = util_createAnimation("WickedWins_ShowJackpotBG.csb")
    self.m_showJackpotNode:addChild(self.m_rightJackpot)
    self.m_rightJackpot:setVisible(false)

    for i=1, 4 do
        self.tblRightJackpotNode[i] = self.m_rightJackpot:findChild("bonus_"..i)
        self.tblRightJackpot[i] = util_createAnimation("WickedWins_ShowJackpot.csb")
        self.tblRightJackpotNode[i]:addChild(self.tblRightJackpot[i])
        self.tblRightJackpot[i]:setVisible(false)
    end

    self.m_casinoEntrance = self:findChild("Node_CasinoEntrance")
    local posX, posY = self.m_casinoEntrance:getPosition()

    self.m_casinoEntrance:setScale(self.m_videoPokerScale)
    self.m_casinoEntrance:setPosition(cc.p(posX-self.m_videoPokerPosX, posY-self.m_videoPokerPosY))

    self.m_topSymbolNode = self:findChild("Node_topSymbol")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:runCsbAction("idle", true)
    self:changeBgSpine(1)
end


function CodeGameScreenWickedWinsMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(WickedWinsMusicConfig.Music_Enter_Game, 4, 0, 1)

    end,0.2,self:getModuleName())
end

function CodeGameScreenWickedWinsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWickedWinsMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self:isAbTest() then
        -- videoPoker添加ui
        self:addVideoPokerUI( )

        self:videoPoker_initGame()
    end
end

function CodeGameScreenWickedWinsMachine:addObservers()
    CodeGameScreenWickedWinsMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        if not self.isPlayLineSound then
            self.isPlayLineSound = true
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

        local soundName = "WickedWinsSounds/music_WickedWins_last_win_"..bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenWickedWinsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWickedWinsMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenWickedWinsMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0 - mainPosY

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
        if display.width / display.height >= 1660/768 then
            mainScale = mainScale * 1.08
            self.m_videoPokerMainScaleMul = 0.98
        elseif display.width / display.height >= 1530/768 then
            mainScale = mainScale * 1.08
            self.m_videoPokerMainScaleMul = 0.98
        elseif display.width / display.height >= 1370/768 then
            mainScale = mainScale * 1.08
            self.m_videoPokerMainScaleMul = 0.98
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 1.05
            self.m_videoPokerMainScaleMul = 0.89
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.96
            self.m_videoPokerMainScaleMul = 0.9
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.85
            self.m_videoPokerMainScaleMul = 0.88
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY+tempPosY)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWickedWinsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BG then
        return "Socre_WickedWins_Wild2"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MINI
    or symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR
    or symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR
    or symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_WickedWins_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_NULL then
        return "Socre_WickedWins_NULL"
    end
    
    return nil
end

--设置bonus scatter 层级
function CodeGameScreenWickedWinsMachine:getBounsScatterDataZorder(symbolType, iCol, iRow)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:getCurSymbolIsBonus(symbolType) then
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

    --右压左、下压上
    if (iCol and iRow) then
        order = order + iCol * 100 - iRow
    end
    return order

end

function CodeGameScreenWickedWinsMachine:getCurSymbolIsJackpot(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_JACKPOT_MINI or
       symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR or
       symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
        return true
    end
    return false
end

function CodeGameScreenWickedWinsMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_JACKPOT_MINI or
       symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR or
       symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR or
       symbolType == self.SYMBOL_SCORE_BONUS then
        return true
    end
    return false
end

function CodeGameScreenWickedWinsMachine:getMatrixPosSymbolType(iRow, iCol, isRemove)
    local rowCount = #self.m_runSpinResultData.p_reels
    local nodePos = self:getPosReelIdx(iRow, iCol)
    if isRemove and self.tblMidSymbol then
        for i=#self.tblMidSymbol, 1, -1 do
            if nodePos == self.tblMidSymbol[i] then
                if self:getCurMidSymbolIsRemove(nodePos, iRow, iCol) then
                    table.remove(self.tblMidSymbol, i)
                end
                break
            end
        end
    end

    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:getCurMidSymbolIsRemove(curNodePos, iRow, iCol)
    local isRemove = true
    if self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(iRow, iCol)) == false and self:getCurMidSymbolSideIsNull(curNodePos) then
        isRemove = false
    end
    return isRemove
end

function CodeGameScreenWickedWinsMachine:getCurMidSymbolSideIsNull(curNodePos)
    local isSideNull = true
    for j=1, #self.m_directionArry do
        if not self:checkBonusInLinks(curNodePos + self.m_directionArry[j]) then
            isSideNull = false
            break
        end
    end
    return isSideNull
end

-----
---创建一行小块 用于一列落下时 上边条漏出空隙过大
function CodeGameScreenWickedWinsMachine:createResNode(parentData, lastNode)
    if self.m_bCreateResNode == false then
        return
    end

    local rowIndex = parentData.rowIndex
    local addRandomNode = function()
        local symbolType = self:getResNodeSymbolType(parentData)
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:getCurSymbolIsBonus(symbolType) then
            symbolType = math.random(1, 5)
        end

        local slotParent = parentData.slotParent
        local columnData = self.m_reelColDatas[parentData.cloumnIndex]

        local node = self:getSlotNodeWithPosAndType(symbolType, columnData.p_showGridCount + 1, parentData.cloumnIndex, true)
        node.p_slotNodeH = columnData.p_showGridH
        node:setTag(-1)
        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local targetPosY = lastNode:getPositionY()

        local slotNodeH = columnData.p_showGridH

        if self.m_bigSymbolInfos[lastNode.p_symbolType] ~= nil then
            targetPosY = targetPosY + (self.m_bigSymbolInfos[lastNode.p_symbolType]) * slotNodeH
        else
            targetPosY = targetPosY + slotNodeH
        end
        -- node.

        node:setPosition(lastNode:getPositionX(), targetPosY)
        local order = 0

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            order = self:getBounsScatterDataZorder(symbolType) - node.p_rowIndex
        else
            order =  REEL_SYMBOL_ORDER.REEL_ORDER_1 - 1--self:getBounsScatterDataZorder(symbolType) - node.p_rowIndex
        end

        slotParent:addChild(node, order)

        node:runIdleAnim()
    end
    if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
        local bigSymbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if rowIndex > 1 and (rowIndex - 1) + bigSymbolCount > self.m_iReelRowNum then -- 表明跨过了 当前一组
            --表明跨组了 不创建小块
        else
            --创建一个小块
            addRandomNode()
        end
    else
        --创建一个小块
        addRandomNode()
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWickedWinsMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWickedWinsMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWickedWinsMachine:MachineRule_initGame(  )

    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
    end
    if self.m_runSpinResultData.p_reSpinCurCount > 0 and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:reSpinChangeReelData()
        self:changeBgSpine(3)
        self:initJackpotData()
    end
end

function CodeGameScreenWickedWinsMachine:initJackpotData()
    local jackpotSignal = self.m_runSpinResultData.p_selfMakeData.jackpotSignal
    if jackpotSignal then
        local sortVec = jackpotSignal.sort
        local miniNum = jackpotSignal.mini
        local minorNum = jackpotSignal.minor
        local majorNum = jackpotSignal.major
        if sortVec then
            for i=1, #sortVec do
                local tempTbl = {}
                if sortVec[i] == "mini" then
                    tempTbl.jackpotType = 2
                    tempTbl.jackpotNum = miniNum
                elseif sortVec[i] == "minor" then
                    tempTbl.jackpotType = 3
                    tempTbl.jackpotNum = minorNum
                elseif sortVec[i] == "major" then
                    tempTbl.jackpotType = 4
                    tempTbl.jackpotNum = majorNum
                end
                self.tblRightJackpotData[i] = tempTbl
            end
        end
    end

    self:initJackpotView()
end

function CodeGameScreenWickedWinsMachine:initJackpotView()
    if #self.tblRightJackpotData > 0 then
        local totalNum = #self.tblRightJackpotData
        local bgIdleName = "gezi"..totalNum.."_idle"
        self.m_rightJackpot:runCsbAction(bgIdleName, true)
        self.m_rightJackpot:setVisible(true)
        for i=1, #self.tblRightJackpotData do
            self.tblRightJackpot[i]:setVisible(true)
            local jackpotType = self.tblRightJackpotData[i].jackpotType
            local jackpotNum = self.tblRightJackpotData[i].jackpotNum
            for j=1, 4 do
                if j == jackpotType-1 then
                    self.tblRightJackpot[i]:findChild("jackpot_type_"..j):setVisible(true)
                else
                    self.tblRightJackpot[i]:findChild("jackpot_type_"..j):setVisible(false)
                end
            end
        
            --判断是否第一个
            local actionName = "actionframe"
            local idleframe = "idleframe"
            if jackpotNum > 1 then
                self.tblRightJackpot[i]:findChild("m_lb_num"):setString(jackpotNum)
                self.tblRightJackpot[i]:runCsbAction("jiaobiao_idle", true)
            else
                self.tblRightJackpot[i]:runCsbAction(idleframe, true)
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.respin
    local actionName = {"base", "free", "respin"}
    self.m_gameBg:runCsbAction(actionName[_bgType], true)
    self:setReelBgState(_bgType)
    if _bgType == 1 then
        self.m_casinoEntrance:setVisible(true)
    else
        self.m_casinoEntrance:setVisible(false)
    end
    if _bgType == 3 then
        self.m_showJackpotNode:setVisible(true)
    else
        self.m_showJackpotNode:setVisible(false)
    end
end

function CodeGameScreenWickedWinsMachine:setReelBgState(_bgType)
    for i=1, 3 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenWickedWinsMachine:initGameStatusData(gameData)
    --ABTest
    local gameConfig = gameData.gameConfig
    if gameConfig then
        local extra = gameConfig.extra
        if extra and extra.testType and extra.testType == "A" then
            self.ABTEST = true
        end
    end
    
    -- 数据合并
    local spin = gameData.spin
    local special = gameData.special
    if self:isAbTest() then
        if spin ~= nil then
            if special ~= nil then
                local bonus = special.bonus
                if bonus then
                    if bonus.status then
                        gameData.spin.selfData = clone(gameData.special.selfData)
                        gameData.spin.bonus    = clone(gameData.special.bonus)
                    end
                    self.m_videoPokeMgr.m_runData:parseData( bonus )
                    local extra = bonus.extra or {}
                    self.m_videoPokeMgr.m_runData:parseData( extra )
                end
                
            end
        else
            gameData.spin = clone(special)
            spin = gameData.spin
        end
    end

    CodeGameScreenWickedWinsMachine.super.initGameStatusData(self,gameData)

    local featureData = gameData.feature
    if featureData then
        local freespinData = featureData.freespin
        local respinData = featureData.respin
        local feature = featureData.features
        if feature then
            self.m_runSpinResultData.p_features = feature
            if freespinData then
                self.m_runSpinResultData.p_freeSpinsLeftCount = freespinData.freeSpinsLeftCount
                self.m_runSpinResultData.p_freeSpinsTotalCount = freespinData.freeSpinsTotalCount
            end
            if respinData then
                self.m_runSpinResultData.p_reSpinCurCount = respinData.reSpinCurCount
                self.m_runSpinResultData.p_reSpinTotalCount = respinData.reSpinsTotalCount
                globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
            end
        end
    end

    if spin ~= nil and self:isAbTest() then
        local bonus = spin.bonus or {}
        self.m_videoPokeMgr.m_runData:parseData( bonus )
        local extra = bonus.extra or {}
        self.m_videoPokeMgr.m_runData:parseData( extra )
    end
end

function CodeGameScreenWickedWinsMachine:isAbTest()
    return self.ABTEST
end

--
--单列滚动停止回调
--
function CodeGameScreenWickedWinsMachine:slotOneReelDown(reelCol)    
    CodeGameScreenWickedWinsMachine.super.slotOneReelDown(self,reelCol) 
    ---本列是否开始长滚
    local isTriggerLongRun = false
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end
    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe2
        self:playScatterSpine("idleframe2", reelCol)
    else
        if reelCol == self.m_iReelColumnNum then
            self:playScatterSpine("idleframe3", reelCol)
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:playMaskFadeAction(false, 0.2, reelCol, function()
            self:changeMaskVisible(false, reelCol)
        end)
    end
end

function CodeGameScreenWickedWinsMachine:playScatterSpine(_spineName, _reelCol)
    performWithDelay(self.m_scWaitNode,function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe3" and targSp.m_currAnimName ~= "idleframe3" and targSp.m_currAnimName ~= "buling" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe2" then
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWickedWinsMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWickedWinsMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 显示free spin
function CodeGameScreenWickedWinsMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- -- 取消掉赢钱线的显示
    -- self:clearWinLineEffect()
    -- -- 停掉背景音乐
    -- self:clearCurMusicBg()

    local waitTime = 0
    if not self.m_bInSuperFreeSpin and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        -- self:playScatterTipMusicEffect()
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_fG_More)
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        end
                        slotNode:runAnim("actionframe")
                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)
                    end
                end
            end
        end
    end
    -- self:playScatterTipMusicEffect()
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenWickedWinsMachine:showCutSceneAni(_callFunc)
    local callFunc = _callFunc
    self.m_cutSceneSpine:setVisible(true)
    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_FG_Cut_Scene)
    util_spinePlay(self.m_cutSceneSpine,"guochang",false)
    performWithDelay(self.m_scWaitNode, function()
        self.m_baseFreeSpinBar:setVisible(true)
        self:changeBgSpine(2)
        self.m_cutSceneAni:setVisible(true)
        self.m_cutSceneAni:runCsbAction("guochang", false, function()
            self.m_cutSceneAni:setVisible(false)
        end)
        performWithDelay(self.m_scWaitNode, function()
            self.m_cutSceneSpine:setVisible(false)
            if callFunc then
                callFunc()
                callFunc = nil
            end
        end, 20/30)
    end, 43/30)
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenWickedWinsMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("WickedWinsSounds/music_WickedWins_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local lightAni = util_createAnimation("WickedWins_tanban_guang.csb")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_fG_More_startOver)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            view:findChild("Node_guang"):addChild(lightAni)
            lightAni:runCsbAction("idle2", true)
            util_setCascadeOpacityEnabledRescursion(view, true)
        else
            local playClickFunc = function()
                gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_fG_Click)
            end
            -- self.m_baseFreeSpinBar:setVisible(true)
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_fG_bgStart)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_fG_bgStart_over)
                self:showCutSceneAni(function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)    
            end)
            view:setBtnClickFunc(playClickFunc)
            view:findChild("Node_guang"):addChild(lightAni)
            lightAni:runCsbAction("idle2", true)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenWickedWinsMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

function CodeGameScreenWickedWinsMachine:showFreeSpinOverView()

    -- gLobalSoundManager:playSound("WickedWinsSounds/music_WickedWins_over_fs.mp3")
    local roleSpine = util_spineCreate("WickedWins_tanban",true,true)
    local lightAni = util_createAnimation("WickedWins_tanban_guang.csb")
    local isShow = false
    local cutSceneFunc = function()
        self.m_baseFreeSpinBar:setVisible(false)
        if isShow then
            util_spinePlay(roleSpine,"over",false)
        end
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_FG_cutScene_Over)
            self:changeBgSpine(1)
        end, 35/60)
    end
    globalMachineController:playBgmAndResume(WickedWinsMusicConfig.Music_fG_bgOver, 4, 0, 1)
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:triggerFreeSpinOverCallFun()
        end)
        isShow = true
        view:setBtnClickFunc(cutSceneFunc)
        view:findChild("juese1"):addChild(roleSpine)
        view:findChild("Node_guang"):addChild(lightAni)
        lightAni:runCsbAction("idle", true)
        util_spinePlay(roleSpine,"start",false)
        util_setCascadeOpacityEnabledRescursion(view, true)
        performWithDelay(self.m_scWaitNode, function()
            if not tolua.isnull(roleSpine) then
                util_spinePlay(roleSpine,"idle",true)
            end
        end, 50/60)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.01,sy=1.0},653)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:triggerFreeSpinOverCallFun()
        end)
        view:setBtnClickFunc(cutSceneFunc)
    end
end

function CodeGameScreenWickedWinsMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("OOPS",nil,_func)
    return view
end

---
-- 触发respin 玩法
--
function CodeGameScreenWickedWinsMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    -- 播放震动
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
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
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
    return true
end

---
-- 触发respin 玩法
--
function CodeGameScreenWickedWinsMachine:showRespinView(_effectData)

    local respinFunc = function()
        --先播放动画 再进入respin
        self:clearCurMusicBg()

        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )

        --可随机的特殊信号 
        local endTypes = self:getRespinLockTypes()
        
        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
        -- self:reSpinStartChangeReel()
        self:hideRespinOtherSymbol()
        -- self:hideBaseReelSymbol()

        self.m_isShowBonusText = false
    end

    local showMaskFunc = function()
        self.m_grandAni:setVisible(true)
        self.m_topSymbolNode:setVisible(true)
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Cut_Scene)
        self.m_grandAni:runCsbAction("guochang1", false, function()
            self.m_grandAni:setVisible(false)
            self.m_topSymbolNode:removeAllChildren()
            self.m_topSymbolNode:setVisible(false)
            respinFunc()
        end)

        performWithDelay(self.m_scWaitNode, function()
            self:hideBaseReelSymbol()
            -- self:hideRespinOtherSymbol()
            self:setReelBgState(3)
        end, 80/60)
        
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local iconReplace = selfData.storedIconsReplace
        local moveBonus = {}
        
        self:respinChangeReplaceData()
        if iconReplace and #iconReplace > 0 then
            local delayTime = 50/60
            local totalChange = 0
            for i = 1, #iconReplace do
                totalChange = totalChange + 1
                moveBonus[#moveBonus + 1] = iconReplace[i][2]
                local posA = self:getRowAndColByPos(iconReplace[i][1])
                local posB = self:getRowAndColByPos(iconReplace[i][2])
                local symbolA = self:getFixSymbol(posA.iY, posA.iX, SYMBOL_NODE_TAG)
                local symbolB = self:getFixSymbol(posB.iY, posB.iX, SYMBOL_NODE_TAG)

                local tempSymbolA = self:createWickedSymbol(symbolA.p_symbolType)

                local nodePosA = self:getTopSymbolPos(iconReplace[i][1])
                local nodePosB = self:getTopSymbolPos(iconReplace[i][2])

                tempSymbolA:setPosition(nodePosA)
                self.m_topSymbolNode:addChild(tempSymbolA)
                symbolA:setVisible(false)
                symbolB:setVisible(false)
                
                local nodeScoreA = symbolA:getChildByName("bonus_tag")
                local nodeScoreB = symbolB:getChildByName("bonus_tag")
                if nodeScoreA then
                    nodeScoreA:removeFromParent()
                end

                if self:getCurSymbolIsBonus(symbolA.p_symbolType) then
                    tempSymbolA.p_symbolType = symbolA.p_symbolType
                    tempSymbolA.p_cloumnIndex = symbolA.p_cloumnIndex
                    tempSymbolA.p_rowIndex = symbolA.p_rowIndex
                    self:setSpecialNodeScoreBonus(tempSymbolA, true)
                end

                local symbolTypeA = symbolA.p_symbolType
                local symbolTypeB = symbolB.p_symbolType
                if symbolA.p_symbolImage then
                    symbolA.p_symbolImage:removeFromParent()
                    symbolA.p_symbolImage = nil
                end
                if symbolB.p_symbolImage then
                    symbolB.p_symbolImage:removeFromParent()
                    symbolB.p_symbolImage = nil
                end
                
                symbolA:changeCCBByName(self:getSymbolCCBNameByType(self, symbolTypeB), symbolTypeB)
                symbolB:changeCCBByName(self:getSymbolCCBNameByType(self, symbolTypeA), symbolTypeA)

                util_playMoveToAction(tempSymbolA, delayTime, nodePosB, function()
                    symbolA:setVisible(true)
                    symbolB:setVisible(true)
                end)
            end
        end

        local bnQuYu = self.m_runSpinResultData.p_rsExtraData.bnQuYu
        for i=1, #bnQuYu do
            local link = bnQuYu[i]
            if #link >= 3 then
                for j=1, #link do
                    local isCreate = true
                    for k=1, #moveBonus do
                        if link[j] == moveBonus[k] then
                            isCreate = false
                            break
                        end
                    end
                    if isCreate then
                        local pos = self:getRowAndColByPos(link[j])
                        local symbolNode = self:getFixSymbol(pos.iY, pos.iX, SYMBOL_NODE_TAG)
                        local tempSymbol = self:createWickedSymbol(symbolNode.p_symbolType)
                        local nodePos = self:getTopSymbolPos(link[j])
                        tempSymbol:setPosition(nodePos)
                        self.m_topSymbolNode:addChild(tempSymbol)
                        tempSymbol.p_symbolType = symbolNode.p_symbolType
                        tempSymbol.p_cloumnIndex = symbolNode.p_cloumnIndex
                        tempSymbol.p_rowIndex = symbolNode.p_rowIndex
                        self:setSpecialNodeScoreBonus(tempSymbol, true)
                    end
                end
            end
        end
    end

    --触发respin时，如果第五列有bonus，在bonus落地动画播完再播触发
    performWithDelay(self.m_scWaitNode, function()
        self:setRespinStartBonusRun(showMaskFunc)
    end, self.triggerRespinDelayTime)
end

function CodeGameScreenWickedWinsMachine:setRespinStartBonusRun(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local iconReplace = selfData.storedIconsReplace
    local bnQuYu = clone(self.m_runSpinResultData.p_rsExtraData.bnQuYu)
    if iconReplace and #iconReplace > 0 then
        for i=1, #bnQuYu do
            local link = bnQuYu[i]
            local linkBonus= {}
            if #link >= 3 then
                for j = 1, #link do
                    local pos = link[j]
                    for k=1, #iconReplace do
                        if pos == iconReplace[k][2] then
                            bnQuYu[i][j] = iconReplace[k][1]
                        end
                    end
                end
            end
        end
    end

    globalMachineController:playBgmAndResume(WickedWinsMusicConfig.Music_RG_Bonus_actionframe, 4, 0, 1)
    if bnQuYu then
        for i = 1, #bnQuYu do
            local link = bnQuYu[i]
            if #link >= 3 then
                for i=1, #link do
                    local fix = self:getRowAndColByPos(link[i])
                    local symbolNode = self:getFixSymbol(fix.iY, fix.iX, SYMBOL_NODE_TAG)
                    if symbolNode then
                        local nodeScore = symbolNode:getChildByName("bonus_tag")
                        if nodeScore then
                            nodeScore:runCsbAction("idle", true)
                        end
                        symbolNode:runAnim("actionframe", false, function()
                            symbolNode:runAnim("idleframe2", true)
                            if callFunc then
                                callFunc()
                                callFunc = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:getTopSymbolPos(_pos)
    local clipTarPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local nodePos = self.m_topSymbolNode:convertToNodeSpace(worldPos)
    return nodePos
end

function CodeGameScreenWickedWinsMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
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
                    -- rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % util_min(8, self.m_iRandomSmallSymbolTypeNum)
                end
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:respinChangeReplaceData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local iconReplace = selfData.storedIconsReplace
    self.cur_storedIcons = {}
    if iconReplace then
        for i=1, #iconReplace do
            for j=1, #self.m_runSpinResultData.p_storedIcons do
                if not self.cur_storedIcons[j] then
                    self.cur_storedIcons[j] = clone(self.m_runSpinResultData.p_storedIcons[j])
                end
                if iconReplace[i][1] == self.m_runSpinResultData.p_storedIcons[j][1] then
                    self.m_runSpinResultData.p_storedIcons[j][1] = iconReplace[i][2]
                end
            end
        end
    end
    self:reSpinChangeReelData(true)
end

function CodeGameScreenWickedWinsMachine:reSpinChangeReelData(isRun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local iconReplace = selfData.storedIconsReplace
    if isRun or not iconReplace then
        --改变轮盘数据
        local newReels = self.m_runSpinResultData.p_rsExtraData.lastReels
        if newReels then
            for i=1, #newReels do
                local rowReels = newReels[i]
                for j=1, #rowReels do
                    self.m_runSpinResultData.p_reels[i][j] = newReels[i][j]
                end
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:hideBaseReelSymbol()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(false)
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:createWickedSymbol(_symbolType)
    local symbol = util_createView("CodeWickedWinsSrc.WickedWinsSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenWickedWinsMachine:reSpinStartChangeReel()
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            _node:removeAndPushCcbToPool()
        end
    end)
end

function CodeGameScreenWickedWinsMachine:baseReelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            fun(node, iCol, iRow)
        end
    end
end

function CodeGameScreenWickedWinsMachine:initRespinView(endTypes, randomTypes)
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
            self:showReSpinStart(
                function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    -- self:changeReSpinBgMusic()
                    self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function CodeGameScreenWickedWinsMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_baseReSpinBar, true)
    self.m_baseReSpinBar:showRespinBar(respinCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end

--ReSpin刷新数量
function CodeGameScreenWickedWinsMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_baseReSpinBar:updateLeftCount(curCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenWickedWinsMachine:changeReSpinOverUI()
    util_setCsbVisible(self.m_baseReSpinBar, false)
end

function CodeGameScreenWickedWinsMachine:showRespinOverView()
    self.isPlayLineSound = false
    self.tblRightJackpotData = {}
    local roleSpine = util_spineCreate("WickedWins_tanban",true,true)
    local lightAni = util_createAnimation("WickedWins_tanban_guang.csb")
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Bg_Over_Fire)
        util_spinePlay(roleSpine,"over",false)
        performWithDelay(self.m_scWaitNode, function()
            self:changeBgSpine(1)
        end, 35/60)
    end
    self.m_iLinkBonusNum = 0
    self.m_iLinkLastBonusNum = 0
    self.m_isShowBonusText = true
    self.cur_storedIcons = {}
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    globalMachineController:playBgmAndResume(WickedWinsMusicConfig.Music_RG_Bg_Over, 3, 0, 1)
    local view=self:showReSpinOver(strCoins,function()
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.tblRespinBgNode = {}
        self.m_lightScore = 0
        self:resetMusicBg()
    end)
    view:findChild("juese1"):addChild(roleSpine)
    view:findChild("Node_guang"):addChild(lightAni)
    util_setCascadeOpacityEnabledRescursion(view, true)
    lightAni:runCsbAction("idle", true)
    util_spinePlay(roleSpine,"start",false)
    performWithDelay(self.m_scWaitNode, function()
        self:setReelSlotsNodeVisible(true)
        self:removeRespinNode()
        if not tolua.isnull(roleSpine) then
            util_spinePlay(roleSpine,"idle",true)
        end
        for i = 3, self.m_iReelColumnNum do
            local reelEffectNode = self.m_reelRunAnimaBG[i]
    
            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                reelEffectNode[1]:setVisible(false)
            end
        end
    end, 50/60)
    view:setBtnClickFunc(cutSceneFunc)
    -- gLobalSoundManager:playSound("levelsTempleSounds/music_levelsTemple_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.01,sy=1.0},653)
end

function CodeGameScreenWickedWinsMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:showRespinOverView()
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenWickedWinsMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getBounsScatterDataZorder(node.p_symbolType, node.p_cloumnIndex, node.p_rowIndex)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = showOrder
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)

    if self:getCurSymbolIsBonus(node.p_symbolType) then
        if node ~= nil then
            local index = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)
            local pos = util_getOneGameReelsTarSpPos(self, index)
            local showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
            node.m_showOrder = showOrder
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:removeFromParent(false)
            self.m_clipParent:addChild(node, 0 + showOrder, node:getTag())
            node:setPosition(cc.p(pos.x, pos.y))
            node:runAnim("idleframe")
            local nodeScore = node:getChildByName("bonus_tag")
            if nodeScore then
                nodeScore:removeFromParent()
                -- nodeScore:runCsbAction("idle", false)
            end
        end
    elseif node.p_symbolType == self.SYMBOL_SCORE_NULL then
        local tblRandomCcbName = {"Socre_WickedWins_1", "Socre_WickedWins_2", "Socre_WickedWins_3", "Socre_WickedWins_4", "Socre_WickedWins_5"}
        local tblRandomSymbolType = {8, 7, 6, 5, 4}
        local bRandom = math.random(1, 5)
        node:changeCCBByName(tblRandomCcbName[bRandom], tblRandomSymbolType[bRandom])
        node:runAnim("idleframe")
    end
end

function CodeGameScreenWickedWinsMachine:curSymbolIsLock(_row, _col)
    local index = self:getPosReelIdx(_row, _col)
    for i=1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        for j=1, #link do
            local pos = link[j]
            if index == pos then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenWickedWinsMachine:getRespinRandomTypes()
    local symbolList = { 
        self.SYMBOL_SCORE_NULL,
        self.SYMBOL_SCORE_BONUS,
        self.SYMBOL_SCORE_JACKPOT_MINI,
        self.SYMBOL_SCORE_JACKPOT_MINOR,
        self.SYMBOL_SCORE_JACKPOT_MAJOR,
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenWickedWinsMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_SCORE_BONUS, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_JACKPOT_MINI, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_JACKPOT_MINOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_JACKPOT_MAJOR, runEndAnimaName = "", bRandom = true},
    }

    return symbolList
end

function CodeGameScreenWickedWinsMachine:reSpinReelDown(addNode)
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        local overCallFunc = function()
            --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            CodeGameScreenWickedWinsMachine.super.reSpinReelDown(self)
        end
        local finalCallFunc = function()
            self:addFinalRewardAni(overCallFunc, 0)
        end
        local jackpotFunc = function()
            self:addFlyJackpot(finalCallFunc)
        end
        self:addRespinSymbolLine(jackpotFunc)
    else
        local nextCallFunc = function()
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            self:runNextReSpinReel()
        end

        local jackpotFunc = function()
            self:addFlyJackpot(nextCallFunc)
        end
        
        -- self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self:addRespinSymbolLine(jackpotFunc)
    end
end

function CodeGameScreenWickedWinsMachine:runNextReSpinReel()
    CodeGameScreenWickedWinsMachine.super.runNextReSpinReel(self)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenWickedWinsMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    return CodeGameScreenWickedWinsMachine.super.showEffect_Bonus(self, effectData)
end

function CodeGameScreenWickedWinsMachine:showBonusGameView(_effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()

    local waitTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                    end
                    slotNode:runAnim("actionframe")
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end
    self:playScatterTipMusicEffect()
    performWithDelay(self,function(  )
        self:showChooseView(_effectData)
    end,waitTime)
end

function CodeGameScreenWickedWinsMachine:showChooseView(_effectData)
    local effectData = _effectData
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        -- globalData.slotRunData.m_isAutoSpinAction = false
    end

    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Choose_Bg)
    self.m_chooseView:refreshAni()
    self.m_chooseView:setVisible(true)
    self.m_chooseView:runCsbAction("start",false, function()
        self.m_chooseView:refreshData(endCallFunc)
        self.m_chooseView:runCsbAction("idle", true)
    end)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWickedWinsMachine:MachineRule_SpinBtnCall()
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWickedWinsMachine:addSelfEffect()
    self.m_aFreeSpinWildArry = {}
    self:addCurIsBigWildPlay()
    local isChoseFeature = false
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and featureDatas[2] and featureDatas[2] == 5 then
        isChoseFeature = true
        self.isPlayLineSound = false
    end
    if featureDatas and featureDatas[2] and featureDatas[2] == 3 then
        self.isPlayLineSound = false
    end
    if #self.m_aFreeSpinWildArry > 0 and not isChoseFeature then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_BIGWILD_PLAY
        effectData.p_selfEffectType = self.EFFECT_BIGWILD_PLAY
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWickedWinsMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BIGWILD_PLAY then
        self:showBigWildPlay(effectData)
    end

    return true
end

function CodeGameScreenWickedWinsMachine:showBigWildPlay(effectData)
    self.tblBigWildSpine = {}
    local delayTime = 0
    local isMiddle = false
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Free_BigWild)
        for i = 1, #self.m_aFreeSpinWildArry, 1 do
            local temp = self.m_aFreeSpinWildArry[i]
            local iRow = temp.row
            local effectAnimation = "actionframe"
            if temp.direction == "up" then
                iRow = temp.row + 1 - 4
                effectAnimation = "actionframe1"
            elseif temp.direction == "down" then
                effectAnimation = "actionframe2"
            elseif temp.direction == "middle" then
                isMiddle = true
                effectAnimation = "actionframe"
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
            local children = self:getReelParent(temp.col):getChildren()
            local node = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iRow, SYMBOL_NODE_TAG))
            --为什么屏幕外的小块还能移动
            if node then
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100)
                node:hideBigSymbolClip()
                node.p_rowIndex = 1
                local distance = (1 - iRow) * self.m_SlotNodeH
                local runTime = 15/30
                delayTime = math.max(delayTime, runTime)

                local seq =cc.Sequence:create(cc.MoveBy:create(runTime, cc.p(0, distance)))
                for j = 1, #iTempRow, 1 do
                    self.m_runSpinResultData.p_reels[self.m_iReelRowNum - iTempRow[j] + 1][temp.col] = TAG_SYMBOL_TYPE.SYMBOL_WILD
                    local symbolNode = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iTempRow[j], SYMBOL_NODE_TAG))
                    if symbolNode ~= nil then
                        local seq =
                            cc.Sequence:create(
                            cc.MoveBy:create(runTime, cc.p(0, distance)),
                            cc.CallFunc:create(
                                function()
                                    symbolNode:removeFromParent(true)
                                end
                            )
                        )
                        symbolNode:runAction(seq)
                    end
                end
                node:runAnim(effectAnimation, false, function()
                    node:runAnim("idleframe", true)
                end)
                node:runAction(seq)
                node.m_bInLine = true
                local linePos = {}
                for i = 1, 4 do
                    linePos[#linePos + 1] = {
                        iX = i,
                        iY = temp.col
                    }
                end
                node:setLinePos(linePos)
            end
        end
    else
        local isPlay = true
        for i = 1, #self.m_aFreeSpinWildArry, 1 do
            delayTime = 30/60
            local temp = self.m_aFreeSpinWildArry[i]
            local iCol = temp.col

            local symbolNode = self:getFixSymbol(iCol, self.m_iReelRowNum, SYMBOL_NODE_TAG)
            local zorder = self:getCurWildZorder(iCol) + 10
            symbolNode:setLocalZOrder(zorder)

            if isPlay then
                gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Base_Wild_All)
                isPlay = false
            end
            local effectAni = util_createAnimation("Socre_WickedWins_bigWild_bg.csb")

            effectAni.p_IsMask = true
            effectAni:runCsbAction("actionframe",false,function(  )
                effectAni:removeFromParent(true)
            end)
            symbolNode:addChild(effectAni, 10000)
            effectAni:setPosition(0, -3*self.m_SlotNodeH)

            performWithDelay(self.m_scWaitNode, function()
                local bigWidSpine = util_spineCreate("Socre_WickedWins_Wild2",true,true)
                self.tblBigWildSpine[i] = bigWidSpine
                bigWidSpine:setName("bigWildSpine")
                local posY = -3*self.m_SlotNodeH
                bigWidSpine:setPosition(cc.p(0, posY))
                symbolNode:addChild(bigWidSpine, 100)
                util_spinePlay(bigWidSpine, "idleframe", true)
                --下边的wild不播actionFrame
                for j=1, self.m_iReelRowNum do
                    local node = self:getFixSymbol(iCol , j, SYMBOL_NODE_TAG)
                    if node then
                        node:putBackToPreParent()
                        node:setLineAnimName("idleframe")
                    end
                end
            end, 25/60)
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        effectData.p_isPlay = true
        self:playGameEffect()

        waitNode:removeFromParent()
    end,delayTime + 0.5)
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenWickedWinsMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if #self.tblBigWildSpine > 0 then
                for i=1, #self.tblBigWildSpine do
                    if not tolua.isnull(self.tblBigWildSpine[i]) then
                        util_spinePlay(self.tblBigWildSpine[i],"actionframe",true)
                    end
                end
            end
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

--base下，大wild加在了最上边小wild上，下边小wild不提层
function CodeGameScreenWickedWinsMachine:checkWildIsOrder(_slotNode)
    local slotNode = _slotNode
    local isOrder = false
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and #self.m_aFreeSpinWildArry > 0 then
        for i=1, #self.m_aFreeSpinWildArry do
            if self.m_aFreeSpinWildArry[i].direction == "middle" and self.m_aFreeSpinWildArry[i].col == slotNode.p_cloumnIndex then
                isOrder = true
                break
            end
        end
    end
    return isOrder
end

function CodeGameScreenWickedWinsMachine:getClipParentChildShowOrder(slotNode, iCol, iRow)
    --右压左、下压上
    local order = REEL_SYMBOL_ORDER.REEL_ORDER_3
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = slotNode:getLocalZOrder()
    end
    return order
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenWickedWinsMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode, slotNode.p_cloumnIndex, slotNode.p_rowIndex)
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    if (slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD and not self:checkWildIsOrder(slotNode)) or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
        pos = self.m_clipParent:convertToNodeSpace(pos)
        slotNode:setPosition(pos.x, pos.y)
        util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    end
    
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenWickedWinsMachine:getCurWildZorder(_col)
    local curCol = _col
    local tblZorderList = {}
    for i=1, 4 do
        local symbolNode = self:getFixSymbol(curCol ,i, SYMBOL_NODE_TAG)
        local zorder = symbolNode:getLocalZOrder()
        table.insert(tblZorderList, zorder)
    end
    table.sort(tblZorderList, function(a, b)
        return a > b
    end)
    return tblZorderList[1]
end

function CodeGameScreenWickedWinsMachine:addCurIsBigWildPlay()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do --列
            local tempRow = nil
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_SCORE_BG then
                    tempRow = iRow
                else
                    break
                end
            end
            if tempRow ~= nil and tempRow ~= 1 and self:curSymbolIsLine(nil, iCol) then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            end

            tempRow = nil
            for iRow = 1, self.m_iReelRowNum, 1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_SCORE_BG then
                    tempRow = iRow
                else
                    break
                end
            end

            if tempRow ~= nil and tempRow ~= self.m_iReelRowNum and self:curSymbolIsLine(nil, iCol) then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "up"}
            end
        end
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local wildIcons = selfData.wildIcons
        if wildIcons then
            for k, colData in pairs(wildIcons) do
                if #colData > 0 and self:curSymbolIsLine(colData) then
                    self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = k, row = 1, direction = "middle"}
                end
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:curSymbolIsLine(_colData, _col)
    local tblColData = {{0,5,10,15}, {1,6,11,16}, {2,7,12,17}, {3,8,13,18}, {4,9,14,19}}
    local colData = _colData
    local col = _col
    local isLine = false
    if not colData then
        colData = tblColData[col]
    end
    for i=1, #colData do
        local nodePos = colData[i]
        local linePos = self.m_runSpinResultData.p_winLines
        for k, v in pairs(linePos) do
            local iconPos = v.p_iconPos
            if iconPos then
                for i=1, #iconPos do
                    if nodePos == iconPos[i] then
                        isLine = true
                        break
                    end
                end
            end
        end
        if isLine then
            break
        end
    end

    return isLine
end

function CodeGameScreenWickedWinsMachine:addFinalRewardAni(_overCallFunc, _curIndex)
    local overCallFunc = _overCallFunc
    local curIndex = _curIndex
    if self:checkIsHaveGrand() then
        local callFunc = function()
            self:playFinalRewardAni(overCallFunc, curIndex)
        end

        self:showGrandAni(callFunc, curIndex)
    else
        self:playFinalRewardAni(overCallFunc, curIndex)
    end
end

function CodeGameScreenWickedWinsMachine:checkIsHaveGrand()
    local curIndex = 0
    local isHave = false
    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    for i=1, symbolTotalNum do
        local fixPos = self:getRowAndColByPos(i-1)
        local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
        if symbolNode then
            curIndex = curIndex + 1
        end
    end
    if curIndex == symbolTotalNum then
        isHave = true
    end
    return isHave
end

--显示grand动画
function CodeGameScreenWickedWinsMachine:showGrandAni(_callFunc, _curIndex)
    local callFunc = _callFunc
    local curIndex = _curIndex
    curIndex = curIndex + 1
    local delayTime = 18/30
    local jackpotType = 5
    
    local startPos = util_convertToNodeSpace(self:findChild("Node_cut_scene"), self)
    self:setCurRightJackpotData(jackpotType)
    local curJackpotNodePos = self:getCurRightJackpotNodePos(jackpotType)
    local endPos = util_convertToNodeSpace(self.tblRightJackpotNode[curJackpotNodePos], self:findChild("Node_cut_scene"))

    self.m_grandSpine:setPosition(cc.p(0, 0))
    self.m_grandSpine:setVisible(true)
    self.m_grandAni:setVisible(true)

    util_spinePlay(self.m_grandSpine, "jiesuan2", false)
    self.m_grandAni:runCsbAction("guochang", false, function()
        self.m_grandAni:setVisible(false)
    end)
    performWithDelay(self.m_scWaitNode, function()
        self:refreshRightJackpotBg(jackpotType)
    end, 10/60)
    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Jackpot_Grand)
    util_spineFrameEventAndRemove(self.m_grandSpine , "jiesuan2","luoxia",function ()
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Fly_Jackpot)
        util_playMoveToAction(self.m_grandSpine, delayTime, endPos, function()
            self:refreshRightJackpot(jackpotType)
            self.m_grandSpine:setVisible(false)
            self.m_grandAni:setVisible(false)
            if callFunc then
                callFunc()
                callFunc = nil
            end
        end)
    end)
end

--最后bonus结算前需要全部播放动画，连线的和不连线的不同
function CodeGameScreenWickedWinsMachine:playFinalRewardAni(_overCallFunc, _curIndex)
    local overCallFunc = _overCallFunc
    local curIndex = _curIndex
    local isPlay = true
    for i=1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        if #link >= 3 then
            for j = 1, #link do
                local pos = self:getRowAndColByPos(link[j])
                local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                if symbolNode then
                    if isPlay then
                        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_AllBonus_PlayEffect)
                        isPlay = false
                    end
                    symbolNode:runAnim("actionframe", false, function()
                        symbolNode:runAnim("idleframe2", true)
                    end)
                    if self:isFixSymbol(symbolNode.p_symbolType) then
                        local nodeScore = symbolNode:getChildByName("bonus_tag")
                        if nodeScore then
                            nodeScore:runCsbAction("idle", true)
                        end
                    end
                end
            end
        else
            for j = 1, #link do
                local pos = self:getRowAndColByPos(link[j])
                local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                if symbolNode then
                    symbolNode:runAnim("jiesuan3", false, function()
                        symbolNode:runAnim("jiesuan_idle", true)
                    end)
                end
            end
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self:addFinalOtherRewardAni(overCallFunc, curIndex)
    end, 125/60)
end

--单个结算bonus，递归
function CodeGameScreenWickedWinsMachine:addFinalOtherRewardAni(_overCallFunc, _curIndex)
    local overCallFunc = _overCallFunc
    local curIndex = _curIndex
    curIndex = curIndex + 1
    local delayTime = 0--10/60
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local curBet = globalData.slotRunData:getCurTotalBet()
    local fixPos = self:getRowAndColByPos(symbolNodePos-1)
    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    local isReward = self:checkCurRespinSymbolIsReward(symbolNodePos)
    if isReward and symbolNode then
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Bonus_Collect)
        symbolNode:runAnim("jiesuan", false, function()
            symbolNode:runAnim("jiesuan_idle", true)
        end)  
        if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
            local nodeScore = symbolNode:getChildByName("bonus_tag")
            if nodeScore then 
                nodeScore:runCsbAction("jiesuan", false)
            end
        end
        if not tolua.isnull(self.tblRespinBgNode[symbolNodePos]) then
            self.tblRespinBgNode[symbolNodePos]:runCsbAction("dark", false)
        end

        performWithDelay(self.m_scWaitNode, function()
            local curReward = 0
            local curRewardType = nil
            local jackpotReward = self.m_runSpinResultData.p_jackpotCoins
            if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                local mul = self:getReSpinBonusScore(self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex))
                if mul ~= nil then
                    local coins = mul * curBet
                    curReward = coins
                end
            elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MINI then
                curReward = jackpotReward["Mini"]
                curRewardType = 1
            elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR then
                curReward = jackpotReward["Minor"]
                curRewardType = 2
            elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
                curReward = jackpotReward["Major"]
                curRewardType = 3
            end

            local callFunc = function()
                local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
                if curIndex >= symbolTotalNum then
                    self:collectRightJackpot(overCallFunc, 1)
                else
                    self:addFinalOtherRewardAni(overCallFunc, curIndex)
                end
            end
            if curRewardType then
                self:showJackpotWinView(curRewardType, curReward, callFunc)
            end
            self:playhBottomLight(curReward, callFunc)
        end, delayTime)
    else
        local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
        if curIndex >= symbolTotalNum then
            self:collectRightJackpot(overCallFunc, 1)
        else
            self:addFinalOtherRewardAni(overCallFunc, curIndex)
        end
    end
end

function CodeGameScreenWickedWinsMachine:collectRightJackpot(_overCallFunc, _jackpotIndex)
    local overCallFunc = _overCallFunc
    local jackpotIndex = _jackpotIndex
    local totalNum = #self.tblRightJackpotData
    local delayTime = 15/30

    local endCallFunc = function()
        if overCallFunc then
            overCallFunc()
            overCallFunc = nil
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        if #self.tblRightJackpotData > 0 then
            if self.tblRightJackpotData[jackpotIndex] then
                local jackpotNum = self.tblRightJackpotData[jackpotIndex].jackpotNum
                local jackpotType = self.tblRightJackpotData[jackpotIndex].jackpotType
                if jackpotNum > 0 then
                    local delayTime = 25/60
                    local flyNode = util_createAnimation("WickedWins_ShowJackpot_danzhen.csb")
                    for i=1, 4 do
                        if i == jackpotType-1 then
                            flyNode:findChild("jackpot_type_"..i):setVisible(true)
                        else
                            flyNode:findChild("jackpot_type_"..i):setVisible(false)
                        end
                    end
                    local startPos = util_convertToNodeSpace(self.tblRightJackpotNode[jackpotIndex], self)
                    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self)
                    flyNode:setPosition(startPos.x, startPos.y)
                    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
                    flyNode:runCsbAction("fei_down")
                    
                    self.tblRightJackpotData[jackpotIndex].jackpotNum = self.tblRightJackpotData[jackpotIndex].jackpotNum - 1
                    self:collectRightEndState(jackpotIndex)
                    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Jackpot_Collect)
                    util_playMoveToAction(flyNode, delayTime, endPos, function()
                        flyNode:removeFromParent()
    
                        local callFunc = function()
                            self:collectRightJackpot(overCallFunc, jackpotIndex)
                        end
    
                        local curReward = 0
                        local curRewardType = 1
                        local jackpotReward = self.m_runSpinResultData.p_jackpotCoins
                        if jackpotType == 2 then
                            curReward = jackpotReward["Mini"]
                            curRewardType = 1
                        elseif jackpotType == 3 then
                            curReward = jackpotReward["Minor"]
                            curRewardType = 2
                        elseif jackpotType == 4 then
                            curReward = jackpotReward["Major"]
                            curRewardType = 3
                        elseif jackpotType == 5 then
                            curReward = jackpotReward["Grand"]
                            curRewardType = 4
                        end

                        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Jackpot_Collect_FeedBack)
                        self:playhBottomLight(curReward, function()
                            self:showJackpotWinView(curRewardType, curReward, callFunc)
                        end)
                    end)
                else
                    jackpotIndex = jackpotIndex + 1
                    self:collectRightJackpot(overCallFunc, jackpotIndex)
                end
            else
                endCallFunc()
            end
        else
            endCallFunc()
        end
    end, delayTime)
end

function CodeGameScreenWickedWinsMachine:collectRightEndState(jackpotIndex)
    local jackpotNum = self.tblRightJackpotData[jackpotIndex].jackpotNum
    if jackpotNum > 0 then
        if jackpotNum == 1 then
            self.tblRightJackpot[jackpotIndex]:runCsbAction("jiaobiao_over", false)
        else
            self.tblRightJackpot[jackpotIndex]:findChild("m_lb_num"):setString(jackpotNum)
        end
    else
        self.tblRightJackpot[jackpotIndex]:setVisible(false)
        local totalNum = #self.tblRightJackpotData
        if jackpotIndex == totalNum then
            local bgOverName = "gezi"..totalNum.."_over"
            self.m_rightJackpot:runCsbAction(bgOverName, false)
        end
    end
end

function CodeGameScreenWickedWinsMachine:checkCurRespinSymbolIsReward(_pos)
    local pos = _pos - 1
    local isReward = false
    for i=1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        if #link >= 3 then
            for j=1, #link do
                if link[j] == pos then
                    isReward = true
                    break
                end
            end
        end
        if isReward then
            break
        end
    end
    return isReward
end

function CodeGameScreenWickedWinsMachine:playhBottomLight(_endCoins, _endCallFunc)
    
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenWickedWinsMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenWickedWinsMachine:getCurBottomWinCoins()
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

function CodeGameScreenWickedWinsMachine:showReSpinStart(_callFunc)
    self.tblLastTimeLineInfo = {}
    self.tblStartLineInfo = {}
    self.tblOverLineInfo = {}
    local callFunc = _callFunc
    local jackpotFunc = function()
        self:addFlyJackpot(callFunc)
    end
    local addLineFunc = function()
        self:changeReSpinBgMusic()
        self:addRespinSymbolLine(jackpotFunc, true)
    end
    local showDialogFunc = function()
        gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_bg_startOver)
        performWithDelay(self.m_scWaitNode, function()
            self.m_gameBg:runCsbAction("switch", false, function()
                self:changeBgSpine(3)
            end)
        end, 150/60)
        self:clearCurMusicBg()
        self.m_casinoEntrance:setVisible(false)
        self.m_bottomUI:updateWinCount("")
        self:setLastWinCoin(0)
        self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, addLineFunc, BaseDialog.AUTO_TYPE_ONLY)
    end

    self:addStartPlayBonusAni(showDialogFunc)
end

--统一改变bonus上的钱数
function CodeGameScreenWickedWinsMachine:changeBonusCoins(_callFunc, isFly, curIndex)
    local delayTime = 0
    local callFunc = _callFunc
    local isPlay = true
    curIndex = curIndex + 1
    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local nodeScore, sScore, isPlayAni

    local endBonusCoinsFunc = function()
        self.m_iLinkLastBonusNum = self.m_iLinkBonusNum
        self:reSpinChangeReelData()
        if callFunc then
            callFunc()
            callFunc = nil
        end
    end

    if isFly or (self.m_iLinkLastBonusNum > 0 and self.m_iLinkBonusNum > self.m_iLinkLastBonusNum) then
        for i = 1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
            local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
            local linkBonus= {}
            if #link >= 3 then
                for j = 1, #link do
                    if symbolNodePos-1 == link[j] then
                        local pos = self:getRowAndColByPos(link[j])
                        local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                        if symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
                            sScore = self:getJackpotCoins(symbolNode)
                            nodeScore = symbolNode:getChildByName("bonus_tag")
                            if nodeScore then
                                local bonusText = nodeScore:findChild("m_jackpot_1"):getString()
                                if bonusText ~= sScore then
                                    isPlayAni = true
                                    delayTime = 15/60
                                end
                            end
                        end
                        break
                    end
                end
            end
        end

        if isPlayAni then
            gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_NewBonus_RefreshCoins)
            self:setBonusShowState(nodeScore, 1)
            nodeScore:runCsbAction("switch", false, function()
                nodeScore:runCsbAction("idle", true)
            end)
            performWithDelay(self.m_scWaitNode, function()
                nodeScore:findChild("m_jackpot_1"):setString(sScore)
            end, 10/60)
        end

        performWithDelay(self.m_scWaitNode, function()
            if curIndex >= symbolTotalNum then
                endBonusCoinsFunc()
            else
                self:changeBonusCoins(callFunc, isFly, curIndex)
            end
        end, delayTime)
    else
        endBonusCoinsFunc()
    end
end

function CodeGameScreenWickedWinsMachine:checkCurIsPlayFlyJackpot()
    --改变轮盘数据
    local isPlay = false
    local reels = self.m_runSpinResultData.p_reels
    if reels then
        for i=1, #reels do
            local rowReels = reels[i]
            for j=1, #rowReels do
                if self:getCurSymbolIsJackpot(reels[i][j]) then
                    isPlay = true
                    break
                end
            end
        end
    end
    return isPlay
end

function CodeGameScreenWickedWinsMachine:addFlyJackpot(_callFunc)
    local callFunc = _callFunc
    local curIndex = 0
    if self:checkCurIsPlayFlyJackpot() then
        self:playFlyJackpot(callFunc, curIndex, true)
    else
        self:changeBonusCoins(callFunc, nil, curIndex)
    end
end

--添加飞到右侧的jackpot
function CodeGameScreenWickedWinsMachine:playFlyJackpot(_callFunc, _curIndex, _isFly)
    local callFunc = _callFunc
    local curIndex = _curIndex
    local isFly = _isFly
    curIndex = curIndex + 1
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    local isPlay = true

    local fixPos = self:getRowAndColByPos(symbolNodePos-1)
    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    if symbolNode and self:getCurSymbolIsJackpot(symbolNode.p_symbolType) and self:curBonusIsLine(symbolNode) then
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_BONUS), self.SYMBOL_SCORE_BONUS)
        
        local flyNode = util_createAnimation("WickedWins_ShowJackpot_danzhen.csb")
        local delayTime = 25/60
        local jackpotType = nil
        if symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MINI then
            jackpotType = 2
        elseif symbolNode.p_symbolType  == self.SYMBOL_SCORE_JACKPOT_MINOR then
            jackpotType = 3
        elseif symbolNode.p_symbolType  == self.SYMBOL_SCORE_JACKPOT_MAJOR then
            jackpotType = 4
        end

        for i=1, 4 do
            if i == jackpotType-1 then
                flyNode:findChild("jackpot_type_"..i):setVisible(true)
            else
                flyNode:findChild("jackpot_type_"..i):setVisible(false)
            end
        end
        
        self:setCurRightJackpotData(jackpotType)
        local curJackpotNodePos = self:getCurRightJackpotNodePos(jackpotType)
        local clipTarPos = util_getOneGameReelsTarSpPos(self, symbolNodePos-1)
        local startPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
        local endPos = util_convertToNodeSpace(self.tblRightJackpotNode[curJackpotNodePos], self)
        flyNode:setPosition(startPos.x, startPos.y)
        self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER+1)
        flyNode:runCsbAction("fei_up")
        local nodeScore = symbolNode:getChildByName("bonus_tag")
        self:setBonusShowState(nodeScore, 1)
        nodeScore:findChild("m_jackpot_1"):setString("")
        symbolNode.p_symbolType = self.SYMBOL_SCORE_BONUS

        if isPlay then
            gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Fly_Jackpot)
            isPlay = false
        end
        performWithDelay(self.m_scWaitNode, function()
            self:refreshRightJackpotBg(jackpotType)
        end, 10/60)

        util_playMoveToAction(flyNode, delayTime, endPos, function()
            self:refreshRightJackpot(jackpotType)
            flyNode:removeFromParent()
            if curIndex >= symbolTotalNum then
                self:changeBonusCoins(callFunc, isFly, 0)
            else
                self:playFlyJackpot(callFunc, curIndex, isFly)
            end
        end)
    else
        if curIndex >= symbolTotalNum then
            self:changeBonusCoins(callFunc, isFly, 0)
        else
            self:playFlyJackpot(callFunc, curIndex, isFly)
        end
    end
end

function CodeGameScreenWickedWinsMachine:refreshRightJackpot(jackpotType)
    local curIndex, jackpotNum
    for i=1, #self.tblRightJackpotData do
        self.tblRightJackpot[i]:setVisible(true)
        if jackpotType == self.tblRightJackpotData[i].jackpotType then
            curIndex = i
            jackpotNum = self.tblRightJackpotData[i].jackpotNum
            break
        end
    end

    for i=1, 4 do
        if i == jackpotType-1 then
            self.tblRightJackpot[curIndex]:findChild("jackpot_type_"..i):setVisible(true)
        else
            self.tblRightJackpot[curIndex]:findChild("jackpot_type_"..i):setVisible(false)
        end
    end

    --判断是否第一个
    local actionName = "actionframe"
    local idleframe = "idleframe"
    if jackpotNum > 1 then
        if jackpotNum == 2 then
            self.tblRightJackpot[curIndex]:findChild("m_lb_num"):setString(jackpotNum)
            self.tblRightJackpot[curIndex]:runCsbAction("jiaobiao_start", false, function()
                self.tblRightJackpot[curIndex]:runCsbAction("jiaobiao_idle", true)
            end)
        else
            performWithDelay(self.m_scWaitNode, function()
                self.tblRightJackpot[curIndex]:findChild("m_lb_num"):setString(jackpotNum)
            end, 5/60)
            self.tblRightJackpot[curIndex]:runCsbAction("jiaobiao_actionframe", false, function()
                self.tblRightJackpot[curIndex]:runCsbAction("jiaobiao_idle", true)
            end)
        end
    else
        self.tblRightJackpot[curIndex]:runCsbAction(actionName, false, function()
            self.tblRightJackpot[curIndex]:runCsbAction(idleframe, true)
        end)
    end
end

function CodeGameScreenWickedWinsMachine:refreshRightJackpotBg(jackpotType)
    local jackpotNum
    local totalNum = #self.tblRightJackpotData
    for i=1, #self.tblRightJackpotData do
        if jackpotType == self.tblRightJackpotData[i].jackpotType then
            jackpotNum = self.tblRightJackpotData[i].jackpotNum
            break
        end
    end

    --判断是否新增
    self.m_rightJackpot:setVisible(true)
    local bgStartName = "gezi"..totalNum.."_idle"
    local bgIdleName = "gezi"..totalNum.."_idle"
    if jackpotNum > 1 then
        self.m_rightJackpot:runCsbAction(bgIdleName, true)
    else
        self.m_rightJackpot:runCsbAction(bgStartName, false, function()
            self.m_rightJackpot:runCsbAction(bgIdleName, true)
        end)
    end
end

function CodeGameScreenWickedWinsMachine:setCurRightJackpotData(jackpotType)
    --类型：mini,minor,major,grand
    local index = 0
    local jackpotNum = 0
    for i=1, #self.tblRightJackpotData do
        if jackpotType == self.tblRightJackpotData[i].jackpotType then
            index = i
            jackpotNum = self.tblRightJackpotData[i].jackpotNum
            break
        end
    end
    if index == 0 then
        index = #self.tblRightJackpotData + 1
    end
    local tempTbl = {}
    tempTbl.jackpotType = jackpotType
    tempTbl.jackpotNum = jackpotNum + 1
    self.tblRightJackpotData[index] = tempTbl
end

function CodeGameScreenWickedWinsMachine:getCurRightJackpotData()
    return self.tblRightJackpotData
end

function CodeGameScreenWickedWinsMachine:getCurRightJackpotNodePos(jackpotType)
    local pos
    for i=1, #self.tblRightJackpotData do
        if jackpotType == self.tblRightJackpotData[i].jackpotType then
            pos = i
            break
        end
    end
    if not pos then
        pos = 1
    end
    return pos
end

function CodeGameScreenWickedWinsMachine:getJackpotCoins(symbolNode)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local mul = self:getReSpinBonusScore(self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex))
    local sScore = ""
    if mul ~= nil then
        local coins = mul * curBet
        sScore = util_formatCoins(coins, 3)
    end
    return sScore
end

function CodeGameScreenWickedWinsMachine:addStartPlayBonusAni(_callFunc)
    local callFunc = _callFunc
    local allSymbolNodes, allLinkBonus, allLine = self:getLinkSymbolData()
   
    for i = 1, #allSymbolNodes do
        local symbolNode = allSymbolNodes[i]
        if self:isFixSymbol(symbolNode.node.p_symbolType) then
            local nodeScore = symbolNode.node:getChildByName("bonus_tag")
            if nodeScore then
                -- nodeScore:runCsbAction("actionframe", false, function()
                    nodeScore:runCsbAction("idle", true)
                -- end)
            end
        end
        -- symbolNode.node:runAnim("actionframe", false, function()
            self.playSymbolNode = symbolNode.node
            symbolNode.node:runAnim("idleframe2", true)
            if i == #allSymbolNodes and callFunc then
                callFunc()
                callFunc = nil
            end
        -- end)
    end
end

-- 增加新的连线
function CodeGameScreenWickedWinsMachine:getStartFireLine()
    local tempClipNode = {}
    if #self.tblStartLineInfo > 0 then
        for i=1, #self.tblStartLineInfo do
            local lines = self.tblStartLineInfo[i]
            local nodeLine = lines.nodeLine
            local curCol = lines.p_cloumnIndex
            local effectFire, sideIndex
            local tempTbl = {}
            if lines.direction == self.ENUM_LINE_DIRECTION["right"] then
                effectFire = util_createAnimation("WickedWins_RespinLine_right.csb")
                sideIndex = 1
            elseif lines.direction == self.ENUM_LINE_DIRECTION["down"] then
                effectFire = util_createAnimation("WickedWins_RespinLine_down.csb")
                sideIndex = 2
            elseif lines.direction == self.ENUM_LINE_DIRECTION["left"] then
                effectFire = util_createAnimation("WickedWins_RespinLine_left.csb")
                sideIndex = 3
            elseif lines.direction == self.ENUM_LINE_DIRECTION["up"] then
                effectFire = util_createAnimation("WickedWins_RespinLine_up.csb")
                sideIndex = 4
            end
            nodeLine:addChild(effectFire)
            effectFire:setName("line_effect")
            tempTbl.curCol = curCol
            tempTbl.effectFire = effectFire
            tempTbl.sideIndex = sideIndex
            tempClipNode[#tempClipNode + 1] = tempTbl
        end
    end
    return tempClipNode
end

-- 增加消失连线
function CodeGameScreenWickedWinsMachine:getOverFireLine()
    local tempClipNode = {}
    if #self.tblOverLineInfo > 0 then
        for i=1, #self.tblOverLineInfo do
            local lines = self.tblOverLineInfo[i]
            local nodeLine = lines.nodeLine
            local curCol = lines.p_cloumnIndex
            local sideIndex
            local tempTbl = {}
            local effectFire = nodeLine:getChildByName("line_effect")
            if not tolua.isnull(effectFire) then
                if lines.direction == self.ENUM_LINE_DIRECTION["right"] then
                    sideIndex = 1
                elseif lines.direction == self.ENUM_LINE_DIRECTION["down"] then
                    sideIndex = 2
                elseif lines.direction == self.ENUM_LINE_DIRECTION["left"] then
                    sideIndex = 3
                elseif lines.direction == self.ENUM_LINE_DIRECTION["up"] then
                    sideIndex = 4
                end
                tempTbl.curCol = curCol
                tempTbl.effectFire = effectFire
                tempTbl.sideIndex = sideIndex
                tempClipNode[#tempClipNode + 1] = tempTbl
            end
        end
    end
    return tempClipNode
end

function CodeGameScreenWickedWinsMachine:addRespinSymbolLine(_nextCallFunc, _isRespinStart)
    self.tblClipNode = {}
    local nextCallFunc = _nextCallFunc
    local isRespinStart = _isRespinStart
    local allSymbolNodes, allLinkBonus, allLine = self:getLinkSymbolData()
    local isPlay = true

    if allLine > self.m_iLinkBonusNum or isRespinStart then
        self.m_iLinkBonusNum = allLine
        self:setBonusBG(allSymbolNodes)
        local vecLines, iMaxLinkNum = self:getSideLines(allLinkBonus)
        self:selectStartAndOverLineNode(vecLines)

        local runCallFunc = function()
            local startFireLine = self:getStartFireLine()
            local overFireLine = self:getOverFireLine()
            self.tblLastTimeLineInfo = clone(vecLines)

            for i=1, #startFireLine do
                local effectFire = startFireLine[i].effectFire
                local curCol = startFireLine[i].curCol
                local sideIndex = startFireLine[i].sideIndex
                if isPlay then
                    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_RG_Link_Start_Fire)
                    isPlay = false
                end
                if sideIndex == 1 or sideIndex == 3 then
                    local startName = "start"..curCol
                    local idleName = "idle"..curCol
                    effectFire:runCsbAction(startName, false, function()
                        effectFire:runCsbAction(idleName, true)
                    end)
                else
                    local startName = "start6"
                    local idleName = "idle6"
                    effectFire:runCsbAction(startName, false, function()
                        effectFire:runCsbAction(idleName, true)
                    end)
                end
            end

            for i=1, #overFireLine do
                local effectFire = overFireLine[i].effectFire
                local curCol = overFireLine[i].curCol
                local sideIndex = overFireLine[i].sideIndex
                if sideIndex == 1 or sideIndex == 3 then
                    local overName = "over"..curCol
                    effectFire:runCsbAction(overName, false, function()
                        effectFire:removeFromParent()
                    end)
                else
                    local overName = "over6"
                    effectFire:runCsbAction(overName, false, function()
                        effectFire:removeFromParent()
                    end)
                end
            end

            --要求在此刷新respin次数
            performWithDelay(self.m_scWaitNode, function()
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end, 60/60)

            performWithDelay(self.m_scWaitNode, function()
                if nextCallFunc then
                    nextCallFunc()
                    nextCallFunc = nil
                end
            end, 70/60)
        end

        local waitFunc = function()
            if #self.tblLastTimeLineInfo > 0 then
                local lines = self.tblLastTimeLineInfo[1]
                local nodeLine = lines.nodeLine
                local effectFire = nodeLine:getChildByName("line_effect")
                local delayTime = 0
                if not tolua.isnull(effectFire) then
                    local curPlayTime= util_csbGetDuration(effectFire.m_csbAct)--effectFire:getCurrentFrame()         --获取固定小块的当前帧数
                    delayTime = 60/60 - curPlayTime
                end
                performWithDelay(self.m_scWaitNode, function()
                    runCallFunc()
                end, delayTime)
            else
                runCallFunc()
            end
        end
        
        self:setRespinBonusAni(allSymbolNodes, waitFunc)
    else
        if nextCallFunc then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            nextCallFunc()
            nextCallFunc = nil
        end
    end
    
end

function CodeGameScreenWickedWinsMachine:selectStartAndOverLineNode(vecLines)
    self.tblStartLineInfo = {}
    self.tblOverLineInfo = {}
    if #self.tblLastTimeLineInfo > 0 then
        -- 增加新的连线
        for i = 1, #vecLines do
            local lines = vecLines[i]
            local isHave = false
            local curIndex = lines.p_curIndex
            local direction = lines.direction

            for k, v in pairs(self.tblLastTimeLineInfo) do
                if curIndex == v.p_curIndex and direction == v.direction then
                    isHave = true
                    break
                end
            end
            if not isHave then
                self.tblStartLineInfo[#self.tblStartLineInfo + 1] = lines
            end
        end

        -- 增加消失连线
        for i=1, #self.tblLastTimeLineInfo do
            local lines = self.tblLastTimeLineInfo[i]
            local isHave = false
            local curIndex = lines.p_curIndex
            local direction = lines.direction

            for k, v in pairs(vecLines) do
                if curIndex == v.p_curIndex and direction == v.direction then
                    isHave = true
                    break
                end
            end
            if not isHave then
                self.tblOverLineInfo[#self.tblOverLineInfo + 1] = lines
            end
        end
    else
        self.tblStartLineInfo = clone(vecLines)
    end
end

function CodeGameScreenWickedWinsMachine:setBonusBG(allSymbolNodes)
    for i = 1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        if #link >= 0 then
            for j = 1, #link do
                local pos = link[j] + 1
                if not self.tblRespinBgNode[pos] then
                    self:addRespinBgNode(pos)
                end
                if self.tblRespinBgNode[pos] then
                    self.tblRespinBgNode[pos]:findChild("img_bg"):setVisible(false)
                end
            end
        end
    end

    -- for i = 1, #allSymbolNodes, 1 do
    --     local symbolNode = allSymbolNodes[i]
    --     local pos = symbolNode.index + 1
    --     if not self.tblRespinBgNode[pos] then
    --         self:addRespinBgNode(pos)
    --     end
    --     if self.tblRespinBgNode[pos] then
    --         self.tblRespinBgNode[pos]:findChild("img_bg"):setVisible(false)
    --     end

    --     local showOrder = self:getBounsScatterDataZorder(symbolNode.node.p_symbolType, symbolNode.node.p_cloumnIndex, symbolNode.node.p_rowIndex)
    --     symbolNode.node:setLocalZOrder(showOrder)
    -- end
    -- -- self:hideBonusLine(allSymbolNodes)
end

function CodeGameScreenWickedWinsMachine:setRespinBonusAni(allSymbolNodes, _callFunc)
    local callFunc = _callFunc
    local ccbNode = self.playSymbolNode:getCCBNode()
    local tempSpineNode = ccbNode.m_spineNode
    util_spineFrameEventAndRemove(tempSpineNode , "idleframe2","shijian",function ()
        for i = 1, #allSymbolNodes do
            local symbolNode = allSymbolNodes[i]
            symbolNode.node:runAnim("idleframe2", true)
            if i == #allSymbolNodes and callFunc then
                callFunc()
                callFunc = nil
            end
            if self:isFixSymbol(symbolNode.node.p_symbolType) then
                local nodeScore = symbolNode.node:getChildByName("bonus_tag")
                if nodeScore then
                    nodeScore:runCsbAction("idle", true)
                end
            end
        end
    end)
end

function CodeGameScreenWickedWinsMachine:addRespinBgNode(_pos)
    local pos = _pos - 1
    local fixPos = self:getRowAndColByPos(pos)
    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    if symbolNode then
        local nodeBg = util_createAnimation("WickedWins_RespinBG.csb")
        nodeBg:runCsbAction("idle", true)
        self.m_respinView:addChild(nodeBg, 1000)
        nodeBg:setPosition(symbolNode:getPosition())
        self.tblRespinBgNode[_pos] = nodeBg
    end
end

function CodeGameScreenWickedWinsMachine:hideBonusLine(allSymbolNodes)
    for i = 1, #allSymbolNodes, 1 do
        local symbolNode = allSymbolNodes[i]
        local pos = symbolNode.index + 1
        if self.tblRespinBgNode[pos] then
            for i=1, 4 do
                local sideNode = self.tblRespinBgNode[pos]:findChild(self.m_tblNodeNameList[i])
                sideNode:removeAllChildren()
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:getLinkSymbolData()
    local allSymbolNodes = {}
    local allLinkBonus = {}
    local allLine = 0
    for i = 1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        local linkBonus= {}
        if #link >= 3 then
            allLine = allLine + #link
            for j = 1, #link do
                local pos = self:getRowAndColByPos(link[j])
                local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                local stcSymbol = {}
                stcSymbol.index = link[j]
                stcSymbol.node = symbolNode
                allSymbolNodes[#allSymbolNodes + 1] = stcSymbol
                linkBonus[#linkBonus + 1] = stcSymbol
            end
        end
        if #linkBonus > 0 then
            table.sort(
                linkBonus,
                function(a, b)
                    return a.index < b.index
                end
            )
            allLinkBonus[#allLinkBonus + 1] = linkBonus
        end
    end
    table.sort(
        allSymbolNodes,
        function(a, b)
            return a.index < b.index
        end
    )
    return allSymbolNodes, allLinkBonus, allLine
end

function CodeGameScreenWickedWinsMachine:getSideLines(allLinkBonus)
    local vecLine = {}
    local iMaxLinkNum = 0
    self.tblMidSymbol = {6, 7, 8, 11, 12, 13}
    for i = 1, #allLinkBonus do
        local vecAnimationLine = {}
        self:addSideLine(allLinkBonus[i][1].node, allLinkBonus[i][1].index, 0, vecLine)
        iMaxLinkNum = math.max(iMaxLinkNum, #vecLine)
    end
  
    self:addAroundNoHaveLine(vecLine)

    return vecLine, iMaxLinkNum
end

--添加单个区域
function CodeGameScreenWickedWinsMachine:addAroundNoHaveLine(vecLine)
    if #self.tblMidSymbol == 0 then
        return
    end
    for i = 1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        for j = 1, #link, 1 do
            local pos = link[j]
            for k=#self.tblMidSymbol, 1, -1 do
                if pos == self.tblMidSymbol[k] then
                    table.remove(self.tblMidSymbol, k)
                end
            end
        end
    end
    
    --单个小块四边是空的
    if #self.tblMidSymbol > 0 then
        for i=#self.tblMidSymbol, 1, -1 do
            local curNodePos = self.tblMidSymbol[i]
            local isSideNull = true
            for j=1, #self.m_directionArry do
                if not self:checkBonusInLinks(curNodePos + self.m_directionArry[j]) then
                    isSideNull = false
                    break
                end
            end
            if isSideNull then
                --上、右、下、左
                local tblNodeBgName = {self.ENUM_DIRECTION["top"], self.ENUM_DIRECTION["right"], self.ENUM_DIRECTION["bottom"], self.ENUM_DIRECTION["left"]}
                for k, v in pairs(self.m_directionArry) do
                    local fixPos = self:getRowAndColByPos(curNodePos + v)
                    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
                    local line = self:getTblLineNode(symbolNode, tblNodeBgName[k], true)
                    if line then
                        vecLine[#vecLine + 1] = line
                    end
                end
                table.remove(self.tblMidSymbol, i)
            end
        end
    end

    self:selectMidSymbol()
    --多个小块连接区域
    if #self.tblMidSymbol > 0 then
        local twoMidVec = {}
        if #self.tblMidSymbol == 4 then
            self:addTwoMidVec(twoMidVec)
        end
        if #twoMidVec > 0 then
            for i=1, #twoMidVec do
                self:addLastMiddleLine(twoMidVec[i][1], twoMidVec[i][1], vecLine, 0)
            end
        else
            self:addLastMiddleLine(self.tblMidSymbol[1], self.tblMidSymbol[1], vecLine, 0)
        end
    end
    
    return false
end

function CodeGameScreenWickedWinsMachine:addTwoMidVec(twoMidVec)
    local twoMidData = {6, 8, 11, 13}
    local lastIndex = 0
    for i=1, #self.tblMidSymbol do
        if self.tblMidSymbol[i] == twoMidData[i] then
            lastIndex = lastIndex + 1
        end
    end
    if lastIndex == 4 then
        local firstMidData = {6, 11}
        local secondMidData = {8, 13}
        table.insert(twoMidVec, firstMidData)
        table.insert(twoMidVec, secondMidData)
    end
end

function CodeGameScreenWickedWinsMachine:selectMidSymbol()
    local midData = {6, 7, 8, 11, 12, 13}
    -- local connectedData = {{1, 5}, {2}, {3, 9}, {10, 16}, {17}, {14, 18}}
    local connectedData = {{1, 5, 16}, {2, 17}, {3, 9, 18}, {10, 16, 1}, {17, 2}, {14, 18, 3}}
    
    if #self.tblMidSymbol > 0 then
        for i=#self.tblMidSymbol, 1, -1 do
            local index = nil
            for j=1, #midData do
                if self.tblMidSymbol[i] == midData[j] then
                    index = j
                    break
                end
            end

            if index then
                local isHave = false
                for k, v in pairs(connectedData[index]) do
                    local pos = v
                    local fixPos = self:getRowAndColByPos(pos)
                    if self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(fixPos.iX, fixPos.iY)) == false then
                        isHave = true
                        break
                    else
                        for i=1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
                            local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
                            if #link >= 3 then
                                for j = 1, #link do
                                    isHave = true
                                    if link[j] == midData[index] then
                                        isHave = nil
                                        break
                                    end
                                end
                                if isHave == nil then
                                    break
                                end
                            end
                        end
                        if isHave == nil then
                            break
                        end
                    end
                end
                if isHave then
                    table.remove(self.tblMidSymbol, i)
                end
            end
        end
    end
end

--添加中间成块区域
function CodeGameScreenWickedWinsMachine:addLastMiddleLine(curNodePos, startPos, vecAnimationLine, prevDirection)
    local tempTblLine = {}
    local curPos = self:getRowAndColByPos(curNodePos)
    if prevDirection == 0 or prevDirection == self.ENUM_DIRECTION["top"] then
        local topPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[1])
        local symbolNode = self.m_respinView:getRespinEndNode(topPos.iX, topPos.iY)
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["top"], true)
        if curPos.iY == 4 or (curPos.iY < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX, curPos.iY + 1))) then
            local rightPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[2])
            local symbolNode = self.m_respinView:getRespinEndNode(rightPos.iX, rightPos.iY)
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["right"], true)
            if curPos.iX == 1 or (curPos.iX > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY))) then
                local bottomPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[3])
                local symbolNode = self.m_respinView:getRespinEndNode(bottomPos.iX, bottomPos.iY)
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["bottom"], true)
                if curPos.iX > 1 and curPos.iY > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY - 1)) == false then
                        local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY - 1)
                        self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["right"])
                    else
                        local nextNodePos = self:getPosReelIdx(curPos.iX, curPos.iY - 1)
                        self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["bottom"])
                    end
                else
                    if curPos.iX > 1 and curPos.iY < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY + 1)) == false then
                        local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY + 1)
                        self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["top"])
                    else
                        local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY)
                        self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["right"])
                    end
                end
            else
                if curPos.iX < 3 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY + 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["left"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["top"])
                end
            end
    elseif prevDirection == self.ENUM_DIRECTION["right"] then
        local rightPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[2])
        local symbolNode = self.m_respinView:getRespinEndNode(rightPos.iX, rightPos.iY)
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["right"], true)
        if curPos.iX == 1 or (curPos.iX > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY))) then
            local bottomPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[3])
            local symbolNode = self.m_respinView:getRespinEndNode(bottomPos.iX, bottomPos.iY)
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["bottom"], true)
            if curPos.iY == 1 or (curPos.iY > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX, curPos.iY - 1))) then
                local leftPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[4])
                local symbolNode = self.m_respinView:getRespinEndNode(leftPos.iX, leftPos.iY)
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["left"], true)
                if curPos.iX < 3 and curPos.iY > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY - 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY - 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["bottom"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["left"])
                end
            else
                if curPos.iX > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY - 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY - 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["right"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX, curPos.iY - 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["bottom"])
                end
            end
        else
            if curPos.iY < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY + 1)) == false then
                local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY + 1)
                self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["top"])
            else
                local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY)
                self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["right"])
            end
        end
    elseif prevDirection == self.ENUM_DIRECTION["bottom"] then
        local bottomPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[3])
        local symbolNode = self.m_respinView:getRespinEndNode(bottomPos.iX, bottomPos.iY)
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["bottom"], true)
        if curPos.iY == 1 or (curPos.iY > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX, curPos.iY - 1))) then
            local leftPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[4])
            local symbolNode = self.m_respinView:getRespinEndNode(leftPos.iX, leftPos.iY)
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["left"], true)
            if curNodePos == startPos then
                return
            end
            if curPos.iX == 3 or (curPos.iX < 3 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY))) then
                local topPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[1])
                local symbolNode = self.m_respinView:getRespinEndNode(topPos.iX, topPos.iY)
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["top"], true)
                if curPos.iX < 3 and curPos.iY < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY + 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["left"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["top"])
                end
            else
                if curPos.iY > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY - 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY - 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["bottom"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["left"])
                end
            end
        else
            if curPos.iX > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY - 1)) == false then
                local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY - 1)
                self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["right"])
            else
                local nextNodePos = self:getPosReelIdx(curPos.iX, curPos.iY - 1)
                self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["bottom"])
            end
        end
    elseif prevDirection == self.ENUM_DIRECTION["left"] then
        local leftPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[4])
        local symbolNode = self.m_respinView:getRespinEndNode(leftPos.iX, leftPos.iY)
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["left"], true)
        if curNodePos == startPos then
            return
        end
        if curPos.iX == 3 or (curPos.iX < 3 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY))) then
            local topPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[1])
            local symbolNode = self.m_respinView:getRespinEndNode(topPos.iX, topPos.iY)
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["top"], true)
            if curPos.iY == 4 or (curPos.iY < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX, curPos.iY + 1))) then
                local rightPos = self:getRowAndColByPos(curNodePos+self.m_directionArry[2])
                local symbolNode = self.m_respinView:getRespinEndNode(rightPos.iX, rightPos.iY)
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["right"], true)
                if curPos.iY < 4 and curPos.iX > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX - 1, curPos.iY + 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["top"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX - 1, curPos.iY)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["right"])
                end
            else
                if curPos.iX < 3 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY + 1)) == false then
                    local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["left"])
                else
                    local nextNodePos = self:getPosReelIdx(curPos.iX, curPos.iY + 1)
                    self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["top"])
                end
            end
        else
            if curPos.iY > 1 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(curPos.iX + 1, curPos.iY - 1)) == false then
                local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY - 1)
                self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["bottom"])
            else
                local nextNodePos = self:getPosReelIdx(curPos.iX + 1, curPos.iY)
                self:addLastMiddleLine(nextNodePos, startPos, vecAnimationLine, self.ENUM_DIRECTION["left"])
            end
        end  
    end
end

function CodeGameScreenWickedWinsMachine:getTblLineNode(_symbolNode, _prevDirection, _different)
    local symbolNode = _symbolNode
    local prevDirection = _prevDirection
    -- 1:从左到右；2：从右到左
    local different = _different
    local tempTbl = {}
    local nodePos = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local nodeBg = self.tblRespinBgNode[nodePos+1]
    if not nodeBg then
        return nil
    end
    tempTbl.p_curIndex = nodePos+1
    tempTbl.p_cloumnIndex = symbolNode.p_cloumnIndex
    if prevDirection == self.ENUM_DIRECTION["top"] then
        local topLineNode
        if different then
            topLineNode = nodeBg:findChild("Node_bottom")
        else
            topLineNode = nodeBg:findChild("Node_top")
        end
        tempTbl.direction = self.ENUM_LINE_DIRECTION["right"]
        tempTbl.nodeLine = topLineNode
    elseif prevDirection == self.ENUM_DIRECTION["right"] then
        local rightLineNode
        if different then
            rightLineNode = nodeBg:findChild("Node_left")
        else
            rightLineNode = nodeBg:findChild("Node_right")
        end
        tempTbl.direction = self.ENUM_LINE_DIRECTION["down"]
        tempTbl.nodeLine = rightLineNode
    elseif prevDirection == self.ENUM_DIRECTION["bottom"] then
        local downLineNode
        if different then
            downLineNode = nodeBg:findChild("Node_top")
        else
            downLineNode = nodeBg:findChild("Node_bottom")
        end
        tempTbl.direction = self.ENUM_LINE_DIRECTION["left"]
        tempTbl.nodeLine = downLineNode
    elseif prevDirection == self.ENUM_DIRECTION["left"] then
        local leftLineNode
        if different then
            leftLineNode = nodeBg:findChild("Node_right")
        else
            leftLineNode = nodeBg:findChild("Node_left")
        end
        tempTbl.direction = self.ENUM_LINE_DIRECTION["up"]
        tempTbl.nodeLine = leftLineNode
    end
    return tempTbl
end

--添加外侧区域
function CodeGameScreenWickedWinsMachine:addSideLine(symbolNode, index, prevDirection, vecAnimationLine)
    if prevDirection == 0 or prevDirection == self.ENUM_DIRECTION["top"] then
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["top"])
        if symbolNode.p_cloumnIndex == 5 or (symbolNode.p_cloumnIndex < 5 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1, true)) == false) then
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["right"])

            if symbolNode.p_rowIndex == 0 or (symbolNode.p_rowIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex, true)) == false) then
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["bottom"])
                if symbolNode.p_rowIndex > 0 and symbolNode.p_cloumnIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["right"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["bottom"], vecAnimationLine)
                end
            else
                if symbolNode.p_rowIndex > 0 and symbolNode.p_cloumnIndex < 5 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["top"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["right"], vecAnimationLine)
                end
            end
        else
            if symbolNode.p_rowIndex < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1, true)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["left"], vecAnimationLine)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["top"], vecAnimationLine)
            end
        end
    elseif prevDirection == self.ENUM_DIRECTION["right"] then
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["right"])
        if symbolNode.p_rowIndex == 0 or (symbolNode.p_rowIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex, true)) == false) then
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["bottom"])
            if symbolNode.p_cloumnIndex == 0 or (symbolNode.p_cloumnIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1, true)) == false) then
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["left"])
                if symbolNode.p_rowIndex < 4 and symbolNode.p_cloumnIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["bottom"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["left"], vecAnimationLine)
                end
            else
                if symbolNode.p_rowIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["right"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["bottom"], vecAnimationLine)
                end
            end
        else
            if symbolNode.p_cloumnIndex < 5 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1, true)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["top"], vecAnimationLine)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["right"], vecAnimationLine)
            end
        end
    elseif prevDirection == self.ENUM_DIRECTION["bottom"] then
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["bottom"])
        if symbolNode.p_cloumnIndex == 0 or (symbolNode.p_cloumnIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1, true)) == false) then
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["left"])
            local nodeID = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            if nodeID == index then
                return
            end
            if symbolNode.p_rowIndex == 4 or (symbolNode.p_rowIndex < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex, true)) == false) then
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["top"])
                if symbolNode.p_rowIndex < 4 and symbolNode.p_cloumnIndex < 5 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["left"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["top"], vecAnimationLine)
                end
            else
                if symbolNode.p_cloumnIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["bottom"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["left"], vecAnimationLine)
                end
            end
        else
            if symbolNode.p_rowIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1, true)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["right"], vecAnimationLine)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["bottom"], vecAnimationLine)
            end
        end
    elseif prevDirection == self.ENUM_DIRECTION["left"] then
        vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["left"])
        local nodeID = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        if nodeID == index then
            return
        end

        if symbolNode.p_rowIndex == 4 or (symbolNode.p_rowIndex < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex, true)) == false) then
            vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["top"])
            if symbolNode.p_cloumnIndex == 5 or (symbolNode.p_cloumnIndex < 5 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1, true)) == false) then
                vecAnimationLine[#vecAnimationLine + 1] = self:getTblLineNode(symbolNode, self.ENUM_DIRECTION["right"])
                if symbolNode.p_cloumnIndex < 5 and symbolNode.p_rowIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["top"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["right"], vecAnimationLine)
                end
            else
                if symbolNode.p_rowIndex < 4 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1, true)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["left"], vecAnimationLine)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)
                    self:addSideLine(nextNode, index, self.ENUM_DIRECTION["top"], vecAnimationLine)
                end
            end
        else
            if symbolNode.p_cloumnIndex > 0 and self:getCurSymbolIsBonus(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1, true)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["bottom"], vecAnimationLine)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)
                self:addSideLine(nextNode, index, self.ENUM_DIRECTION["left"], vecAnimationLine)
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:checkBonusInLinks(index)
    if index < 0 or index > 19 then
        return false
    end
    for i = 1, #self.m_runSpinResultData.p_rsExtraData.bnQuYu do
        local link = self.m_runSpinResultData.p_rsExtraData.bnQuYu[i]
        for j = 1, #link do
            if link[j] == index then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenWickedWinsMachine:addPlayEffect()
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
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
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then
            -- globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount

            -- local respinEffect = GameEffectData.new()
            -- respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            -- respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN

            -- self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

            -- --发送测试特殊玩法
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:setSpecialSpinStates(true)
            if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                self:normalSpinBtnCall()
            end
        end
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWickedWinsMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenWickedWinsMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenWickedWinsMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWickedWinsMachine:startReSpinRun()
    CodeGameScreenWickedWinsMachine.super.startReSpinRun(self)
end

function CodeGameScreenWickedWinsMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenWickedWinsMachine.super.slotReelDown(self)
end

function CodeGameScreenWickedWinsMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    @desc: 遮罩相关
]]
function CodeGameScreenWickedWinsMachine:createRoyaleBattleMask(_mainClass)
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
        local offsetSize = cc.size(5, 5)
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

function CodeGameScreenWickedWinsMachine:changeMaskVisible(_isVis, _reelCol, _isOpacity)
    if _isOpacity then
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(0)
    else
        self.m_panelUpList[_reelCol]:setVisible(_isVis)
        self.m_panelUpList[_reelCol]:setOpacity(self.m_panelOpacity)
    end
end

function CodeGameScreenWickedWinsMachine:playMaskFadeAction(_isFadeTo, _fadeTime, _reelCol, _fun)
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
    performWithDelay(
        waitNode,
        function()
            if _fun then
                _fun()
            end

            waitNode:removeFromParent()
        end,
        fadeTime
    )
end

function CodeGameScreenWickedWinsMachine:beginReel()

    self.isPlayLineSound = true
    if self:isAbTest() then
        if self.m_videoPokerBetChoose:isVisible() then
            self.m_videoPokeMgr:hideVideoPokeChooseBetViewView()
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        for i = 1, self.m_iReelColumnNum do
            self:changeMaskVisible(true, i, true)
            self.m_panelUpList[i]:setVisible(true)
            self:playMaskFadeAction(true, 0.2, i, function()
                self:changeMaskVisible(true, i)
            end)
        end
    end
    CodeGameScreenWickedWinsMachine.super.beginReel(self)
    if #self.tblBigWildSpine > 0 then
        for i=1, #self.tblBigWildSpine do
            if not tolua.isnull(self.tblBigWildSpine[i]) then
                util_spinePlay(self.tblBigWildSpine[i],"idleframe",true)
            end
        end
    end
end

function CodeGameScreenWickedWinsMachine:updateReelGridNode(_symbolNode)

    local nodeScore = _symbolNode:getChildByName("bonus_tag")
    local allWildSpine = _symbolNode:getChildByName("bigWildSpine")
    if nodeScore then
        nodeScore:removeFromParent()
    end
    if allWildSpine then
        allWildSpine:removeFromParent()
    end
    if self:getCurSymbolIsBonus(_symbolNode.p_symbolType) and (_symbolNode.m_isLastSymbol or self:getCurrSpinMode() ~= RESPIN_MODE) then
        self:setSpecialNodeScoreBonus(_symbolNode)
    end

    if self:isAbTest() then
        -- videoPoker收集添加角标
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local iconLocs = selfdata.iconLocs or {}
        self.m_videoPokeMgr:createVideoPokerIcon(_symbolNode,self,iconLocs )
    end

    if self:getCurrSpinMode() ~= RESPIN_MODE then
        if _symbolNode.p_rowIndex <= self.m_iReelRowNum then
            local showOrder = self:getBounsScatterDataZorder(_symbolNode.p_symbolType)
            _symbolNode.m_showOrder = showOrder
            _symbolNode:setLocalZOrder(showOrder)
        end
    end
end

function CodeGameScreenWickedWinsMachine:setSpecialNodeScoreBonus(_symbolNode, _isChange)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()

    local nodeScore = util_createAnimation("Socre_WickedWins_Coins.csb")
    symbolNode:addChild(nodeScore, 100)
    nodeScore:setPosition(cc.p(0, 0))
    nodeScore:setName("bonus_tag")
    nodeScore:runCsbAction("idle")

    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
        self:setBonusShowState(nodeScore, 1)
        local sScore = ""
        if symbolNode.m_isLastSymbol == true or _isChange then
            if self.m_isShowBonusText then
                local mul = self:getReSpinBonusScore(self:getPosReelIdx(iRow, iCol), _isChange)
                if mul ~= nil and mul ~= 0 then
                    local coins = mul * curBet
                    sScore = util_formatCoins(coins, 3)
                end
            end
        else
            -- 获取随机分数（本地配置）
            local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
            score = score * curBet
            sScore = util_formatCoins(score, 3)
        end
        nodeScore:findChild("m_jackpot_1"):setString(sScore)
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MINI then
        self:setBonusShowState(nodeScore, 2)
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR then
        self:setBonusShowState(nodeScore, 3)
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
        self:setBonusShowState(nodeScore, 4)
    end
end

function CodeGameScreenWickedWinsMachine:setBonusShowState(_targetNode, _jackpotType)
    for i=1, 4 do
        if i == _jackpotType then
            _targetNode:findChild("m_jackpot_"..i):setVisible(true)
        else
            _targetNode:findChild("m_jackpot_"..i):setVisible(false)
        end
    end
end

function CodeGameScreenWickedWinsMachine:getReSpinBonusScore(_iPos, _isChange)
    local storedIcons
    local pos = _iPos
    if _isChange and self.cur_storedIcons and #self.cur_storedIcons > 0 then
        storedIcons = self.cur_storedIcons
    else
        storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    end
    
    for k, v in ipairs(storedIcons) do
        if v[1] == pos then
            return v[3]
        end
    end
    return nil
end

-- 从配置中获取一个随机倍数
function CodeGameScreenWickedWinsMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if self:isFixSymbol(symbolType) then
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 是不是 respinBonus小块
function CodeGameScreenWickedWinsMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return true
    end
    return false
end

--当前列是否全部wild
function CodeGameScreenWickedWinsMachine:checkCurColAllWild(_col, _symbolType)
    local curCol = _col
    local symbolType = _symbolType
    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return true
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildIcons = selfData.wildIcons
    if wildIcons and #wildIcons[curCol] > 0 then
        return false
    end
    return true
end

function CodeGameScreenWickedWinsMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg and self:checkCurColAllWild(_slotNode.p_cloumnIndex, _slotNode.p_symbolType) then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
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

            if self:checkSymbolBulingAnimPlay(_slotNode) and _slotNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                --2.播落地动画
                if self:isFixSymbol(_slotNode.p_symbolType) then
                    local nodeScore = _slotNode:getChildByName("bonus_tag")
                    if nodeScore then
                        nodeScore:runCsbAction("buling", false)
                    end
                end
                self.triggerRespinDelayTime = 0
                if self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                    if _slotNode.p_cloumnIndex == self.m_iReelColumnNum then
                        self.triggerRespinDelayTime = 15/30
                    end
                end
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
end

--快停优先播放scatter
function CodeGameScreenWickedWinsMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        if _iCol == self.m_iReelColumnNum then
            local soundIds = {}
            local bulingDatas = self.m_symbolQsBulingSoundArray
            local isPlayOther = true
            for type, path in pairs(bulingDatas) do
                if type == "90" then
                    isPlayOther = false
                    break
                end
            end

            for soundType, soundPaths in pairs(bulingDatas) do
                local soundPath = soundPaths[#soundPaths]
                if soundType == "90" or isPlayOther then
                    local soundId = gLobalSoundManager:playSound(soundPath)
                    table.insert(soundIds, soundId)
                end
            end

            return soundIds
        end
    end
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenWickedWinsMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) and self:getCurSymbolIsPlaySound(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                end
            end
        end
    end
end

--所有玩法里，当有多个图标同时落地时，只播一个音效，且优先播放scatter落地
function CodeGameScreenWickedWinsMachine:getCurSymbolIsPlaySound(_slotNode)
    local curCol = _slotNode.p_cloumnIndex
    if _slotNode then
        if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            return true
        elseif self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
            local bounsList = {}
            for row=1, self.m_iReelRowNum do
                local node = self:getFixSymbol(curCol , row, SYMBOL_NODE_TAG)
                if node then 
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        return false
                    elseif self:getCurSymbolIsBonus(node.p_symbolType) then
                        bounsList[#bounsList + 1] = node
                    end
                end
            end
            if #bounsList > 0 then
                if _slotNode.p_rowIndex == bounsList[1].p_rowIndex then
                    return true
                end
            end
        end
    end
    return false
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenWickedWinsMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                return self:getCurSymbolIsPlayBuLing(_slotNode)
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenWickedWinsMachine:getCurSymbolIsPlayBuLing(_slotNode)
    if _slotNode.p_cloumnIndex < 4 then
        return true
    else
        local curRow = _slotNode.p_rowIndex
        local lastCol = _slotNode.p_cloumnIndex - 1
        local bonusCount = 0
        local isPlay = false
        for i=1, lastCol do
            local targSp = self:getFixSymbol(i, curRow, SYMBOL_NODE_TAG)
            if targSp and self:getCurSymbolIsBonus(targSp.p_symbolType)  then
                bonusCount = bonusCount + 1
            end
        end
        if _slotNode.p_cloumnIndex == 4 and bonusCount > 0 then
            isPlay = true
        elseif _slotNode.p_cloumnIndex == 5 and bonusCount > 1 then
            isPlay = true
        end
        return isPlay
    end
end

function CodeGameScreenWickedWinsMachine:curBonusIsLine(_symbolNode)
    local symbolNode = _symbolNode
    local bnQuYu = self.m_runSpinResultData.p_rsExtraData.bnQuYu
    if bnQuYu then
        for i = 1, #bnQuYu do
            local nodePos = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            local link = bnQuYu[i]
            if #link >= 3 then
                for i=1, #link do
                    if link[i] == nodePos then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenWickedWinsMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        node:runAnim("idleframe3", true)
    elseif self:getCurSymbolIsBonus(node.p_symbolType) then
        node:runAnim("idleframe", true)
    end
end

function CodeGameScreenWickedWinsMachine:showJackpotWinView(_rewardType, _rewardCoins, _callFunc)
    local rewardType = _rewardType
    local rewardCoins = _rewardCoins
    local callFunc = _callFunc
    
    self.m_jackpotWinView:setVisible(true)
    self.m_jackpotWinView:refreshRewardType(rewardType, rewardCoins, self, callFunc)
    self.m_jackpotWinView:runCsbAction("start", false, function()
        -- self.m_jackpotWinView:setClickState(true)
        self.m_jackpotWinView:setSpineIdle()
        self.m_jackpotWinView:runCsbAction("idle", true)
    end)
    local curJackpotSound = nil
    if rewardType == 1 then
        curJackpotSound = WickedWinsMusicConfig.Music_RG_Jackpot_Collect_Mini
    elseif rewardType == 2 then
        curJackpotSound = WickedWinsMusicConfig.Music_RG_Jackpot_Collect_Minor
    elseif rewardType == 3 then
        curJackpotSound = WickedWinsMusicConfig.Music_RG_Jackpot_Collect_Major
    elseif rewardType == 4 then
        curJackpotSound = WickedWinsMusicConfig.Music_RG_Jackpot_Collect_Grand
    end
    gLobalSoundManager:playSound(curJackpotSound)
end

--继承重写 改变盘面数据
function CodeGameScreenWickedWinsMachine:triggerChangeRespinNodeInfo(respinNodeInfo)

end

function CodeGameScreenWickedWinsMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 5, 0, 0)
    end
end

function CodeGameScreenWickedWinsMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenWickedWinsMachine:hideRespinOtherSymbol()
    local respinMachine = self.m_respinView.m_respinMachine
    local respinColorNode = self.m_respinView.m_respinColorNode
    for i=1, #respinMachine do
        local symbolNode = respinMachine[i]
        if not self:getCurSymbolIsBonus(symbolNode.p_symbolType) or not self:curSymbolIsLock(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex) then
            symbolNode:setVisible(false)
        else
            self.m_videoPokeMgr:removeVideoPokerIcon(symbolNode)
        end
    end

    for i=1, #respinColorNode do
        local colorNode = respinColorNode[i]
        if colorNode then
            colorNode:setVisible(false)
        end
    end
end

-- videoPoker 相关
-- 处理spin 返回结果
function CodeGameScreenWickedWinsMachine:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]

        if spinData.action == "SPECIAL" and self:isAbTest() then
             -- 处理bonus消息返回
            self:videoPokerResultCallFun(param)
        else
            CodeGameScreenWickedWinsMachine.super.spinResultCallFun(self,param)
        end
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

function CodeGameScreenWickedWinsMachine:videoPokerResultCallFun(param)

    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]

        if spinData.action == "SPECIAL" then
            gLobalViewManager:removeLoadingAnima()
            local serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_BonusWinCoins = serverWinCoins
            globalData.userRate:pushCoins(serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            -- 更新本地数据
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            -- 更新VideoPoker数据
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            self.m_videoPokeMgr.m_runData:parseData( selfdata )
            local bonus = spinData.result.bonus or {}
            self.m_videoPokeMgr.m_runData:parseData( bonus )
            local extra = bonus.extra or {}
            self.m_videoPokeMgr.m_runData:parseData( extra )

            self.m_videoPokeMgr:handleVideoPokerResult( )
        end

       
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

function CodeGameScreenWickedWinsMachine:addVideoPokerUI( )

    self.m_videoPokerGuoChang =  self.m_videoPokeMgr:createVideoPokerGuoChang()
    self:addChild(self.m_videoPokerGuoChang ,self.m_videoPokeMgr.p_Config.UIZORDER.GUOCAHNG)
    self.m_videoPokerGuoChang:setVisible(false)
    self.m_videoPokerGuoChang:setPosition(display.center)
    
    self.m_videoPokerMain =  self.m_videoPokeMgr:createVideoPokerBaseMain()
    self:addChild(self.m_videoPokerMain ,self.m_videoPokeMgr.p_Config.UIZORDER.MAINUI)
    self.m_videoPokerMain:setVisible(false)

    self.m_videoPokerBetChoose =  self.m_videoPokeMgr:createVideoPokerBetChooseView()
    self:addChild(self.m_videoPokerBetChoose ,self.m_videoPokeMgr.p_Config.UIZORDER.BETCHOSEUI)
    self.m_videoPokerBetChoose:setVisible(false)
    if not self.m_videoPokeMgr:checkEntranceCanClick( ) then
        self.m_videoPokeMgr:showVideoPokeChooseBetViewView()
    end

    self.m_entrance = self.m_videoPokeMgr:ceateVideoPokerEntrance( )
    self.m_casinoEntrance:addChild(self.m_entrance)
end


--[[
   videoPoke断线重连
]]
function CodeGameScreenWickedWinsMachine:videoPoker_initGame()
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "OPEN" then
        local requestType = self.m_videoPokeMgr.m_runData:getRequestType( )
        if requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP then
            -- 消耗筹码开始
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP ) 
            self.m_videoPokerMain:postChipRequestCallFun()
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.HOLDPOKER then
            -- 选择牌型
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP ) 
            self.m_videoPokerMain:holdPokeRequestCallFun( )
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.COLLECTDOUBLE_START then
            -- double直接结束选择赢钱
            print("直接结束不处理任何逻辑,实际上这块逻辑就不会走进来")
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.COLLECTDOUBLE_MAIN then
            -- double直接结束选择赢钱
            print("直接结束不处理任何逻辑,实际上这块逻辑就不会走进来")
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_MAIN then
            -- doubleMain选择继续翻倍
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_MAIN ) 
            gLobalNoticManager:postNotification(self.m_videoPokeMgr.p_Config.EventType.NOTIFY_REC_SHOW_DOUBLEGAME_MAINVIEW)
            self.m_videoPokerMain:doubleUpMainRequestCallFun( )
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_START then
            -- doubeStart选择继续翻倍
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_START ) 
            gLobalNoticManager:postNotification(self.m_videoPokeMgr.p_Config.EventType.NOTIFY_SHOW_DOUBLEGAME_MAINVIEW)
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLECLICKPOS then
            -- 发送在double里选择选择牌的位置
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLECLICKPOS )
            self.m_videoPokerMain:recDoubleClickPosRequestCallFun( )
        end
        
    end
end

-- 显示paytableview 界面
function CodeGameScreenWickedWinsMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"
     --!!! ABTest
     if self:isAbTest() then
        csbFileName = "PayTableLayer" .. self.m_moduleName .. "_abtest.csb"
    end

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    if view then
        view:setOverFunc(
            function()
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

function CodeGameScreenWickedWinsMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenWickedWinsMachine.super.levelDeviceVibrate then
        CodeGameScreenWickedWinsMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenWickedWinsMachine






