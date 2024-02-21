local BaseMachine = require "Levels.BaseMachine"
local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local BaseSlots = require "Levels.BaseSlots"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = require "Levels.BaseDialog"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenDwarfFairyMachine = class("CodeGameScreenDwarfFairyMachine", BaseSlotoManiaMachine)

CodeGameScreenDwarfFairyMachine.SYMBOL_BONUS_NORMAL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7
CodeGameScreenDwarfFairyMachine.SYMBOL_BONUS_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenDwarfFairyMachine.SYMBOL_BONUS_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenDwarfFairyMachine.SYMBOL_BONUS_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10

CodeGameScreenDwarfFairyMachine.FLY_COIN_TYPE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20

CodeGameScreenDwarfFairyMachine.m_reelBar = nil
CodeGameScreenDwarfFairyMachine.m_reelLine = nil
CodeGameScreenDwarfFairyMachine.m_reelTop = nil

CodeGameScreenDwarfFairyMachine.m_iReelMinRow = nil
CodeGameScreenDwarfFairyMachine.m_iReelMaxRow = nil
CodeGameScreenDwarfFairyMachine.m_updateReelHeightID = nil
CodeGameScreenDwarfFairyMachine.m_bonusSelect = nil
CodeGameScreenDwarfFairyMachine.m_reelMoveTime = nil
CodeGameScreenDwarfFairyMachine.m_reelMoveUpSpeed = {1, 1, 2, 2, 2}
CodeGameScreenDwarfFairyMachine.m_reelMoveDownSpeed = {1, 2, 3, 3, 3}
CodeGameScreenDwarfFairyMachine.m_vecGoldOffset = {2.5, 1.5, 1, 0.8, 0.5}    --向上移动时金罐 移动偏移量
CodeGameScreenDwarfFairyMachine.m_goldOffset = nil
CodeGameScreenDwarfFairyMachine.m_reelAddLenNum = {60, 60, 60, 60, 60}
CodeGameScreenDwarfFairyMachine.m_reelAddFallLenNum = {18, 20, 22, 24, 26}
CodeGameScreenDwarfFairyMachine.m_fitDistance = nil
CodeGameScreenDwarfFairyMachine.m_bIsHideLittlePerson = nil
CodeGameScreenDwarfFairyMachine.m_bIsReelStartMove = nil
CodeGameScreenDwarfFairyMachine.m_vecJackPotNodePos = nil
CodeGameScreenDwarfFairyMachine.m_jackPotEffect = nil
CodeGameScreenDwarfFairyMachine.m_winBonusColFlag = {false, false, false, false, false}
CodeGameScreenDwarfFairyMachine.m_bonusBreak = nil
CodeGameScreenDwarfFairyMachine.m_scatterColFlag = {false, false, false, false, false}
CodeGameScreenDwarfFairyMachine.m_scatterBreak = nil
CodeGameScreenDwarfFairyMachine.m_vecScatter = {}
CodeGameScreenDwarfFairyMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenDwarfFairyMachine.BONUS_GAME_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenDwarfFairyMachine.m_bHaveBonusGame = nil

CodeGameScreenDwarfFairyMachine.m_jackpotIndex =
{
    Grand = 1,
    Major = 2,
    Minor = 3,
    Mini = 4
}

CodeGameScreenDwarfFairyMachine.m_arrNormalSymbol =
{
    "Socre_DwarfFairy_2",
    "Socre_DwarfFairy_3",
    "Socre_DwarfFairy_4",
    "Socre_DwarfFairy_5",
    "Socre_DwarfFairy_6",
    "Socre_DwarfFairy_7",
    "Socre_DwarfFairy_8",
    "Socre_DwarfFairy_9",
}

local FIT_HEIGHT_MAX = 1370
local FIT_HEIGHT_MIN = 1136

function CodeGameScreenDwarfFairyMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isOnceClipNode = false --是否只绘制一个矩形裁切 --小矮仙 袋鼠等不规则或者可变高度设置成false
    self:initGame()
end

function CodeGameScreenDwarfFairyMachine:initGame()
    self.m_iReelMinRow = 3
    self.m_iReelMaxRow = 8

    --启用jackpot
    self:BaseMania_jackpotEnable()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("DwarfFairyConfig.csv", "LevelDwarfFairyConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_ScatterShowCol = {3,4,5}

    self.m_scatterBulingSoundArry = {}
    self.m_scatterBulingSoundArry["auto"] = "DwarfFairySounds/sound_DwarfFairy_scatter.mp3"

    self.m_jackPotEffect = GameEffect.EFFECT_SELF_EFFECT - 3

    self.m_vecStoredCol = {1, 1, 1, 1, 1}
    self.m_isFeatureOverBigWinInFree = true
end

function CodeGameScreenDwarfFairyMachine:getReelHeight()
    return 579
end
function CodeGameScreenDwarfFairyMachine:getReelWidth()
    return 1120
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenDwarfFairyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "DwarfFairy"
end

function CodeGameScreenDwarfFairyMachine:getNetWorkModuleName()
    return "DwarfFairyV2"
end


function CodeGameScreenDwarfFairyMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(self.m_iReelMaxRow,self.m_iReelColumnNum,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenDwarfFairyMachine:scaleMainLayer()
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
            mainScale = (FIT_HEIGHT_MAX - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale

        elseif display.height <= FIT_HEIGHT_MIN then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            mainScale = mainScale + 0.03
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        elseif display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            -- mainScale = mainScale
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

function CodeGameScreenDwarfFairyMachine:initUI(data)
    if display.height/display.width > 1530 / 768 then
        self.m_gameBg:setScale(1.1)
    end
    
    self.m_jackpotBar = util_createView("CodeDwarfFairySrc.DwarfFairyJackpotBar")
    self.m_csbOwner["jackpot"]:addChild(self.m_jackpotBar)
    self.m_jackpotBar:updateJackpotInfo()
    self.m_jackpotBar:initMachine(self)

    self.m_fresSpinBar = util_createView("CodeDwarfFairySrc.DwarfFairyFreeSpinBar")
    self.m_csbOwner["freespin"]:addChild(self.m_fresSpinBar)
    self.m_fresSpinBar:setVisible(false)
    -- self.m_fresSpinBar:setPosition(0, 70)

    self.m_collectIcon = util_createView("CodeDwarfFairySrc.DwarfFairyCollectCoin",self)
    self.m_csbOwner["lock"]:addChild(self.m_collectIcon)

    self.m_gold = util_spineCreate("DwarfFairy_Standing", false, true)
    self.m_csbOwner["m_xiaoaixian"]:addChild(self.m_gold)
    util_spinePlay(self.m_gold, "ildeframe", true)
    self.m_gold:setPosition(140, -170)

    self.m_person = util_spineCreate("DwarfFairy_Xiaoaixian", false, true)
    self.m_csbOwner["m_xiaoaixian"]:addChild(self.m_person)
    util_spinePlay(self.m_person, "idle", true)
    self.m_person:setPosition(10, 80)

    self.m_firstReel = self.m_csbOwner["first_reel"]
    local reelEffect, reelAct = util_csbCreate("DwarfFairy_first_idle.csb")
    util_csbPlayForKey(reelAct, "actionframe", true)
    self.m_firstReel:addChild(reelEffect)
    self.m_firstReel:setVisible(false)

    self.m_littlePerson = util_spineCreate("DwarfFairy_Above", false, true)
    self.m_firstReel:addChild(self.m_littlePerson)
    util_spinePlay(self.m_littlePerson, "idleB", true)
    self.m_littlePerson:setPositionY(-148)

    local logo, act = util_csbCreate("logoSG.csb")
    self.m_csbOwner["logo"]:addChild(logo)
    util_csbPlayForKey(act, "idle", true)
    self.m_logo = logo

    self.m_respinReel, self.m_respinReelAct = util_csbCreate("DwarfFairy_RespinLight.csb")
    self.m_clipParent:addChild(self.m_respinReel, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_respinReel:setVisible(false)

    self.m_guochang, self.m_guochangAct = util_csbCreate("guochang.csb")
    self:addChild(self.m_guochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_guochang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guochang:setVisible(false)
    if display.height > FIT_HEIGHT_MAX then
        util_getChildByName(self.m_guochang, "heise"):setScaleY((display.height / FIT_HEIGHT_MAX) + 4 )
        util_getChildByName(self.m_guochang,"xingkong_00000_1_0"):setScaleY((display.height / FIT_HEIGHT_MAX) + 4)
    end

    self.m_csbOwner["DwarfFairy_reel_kuang_1"]:setZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 2)
    self.m_csbOwner["reel_top_1"]:setZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 1)


    local nodeLunpan = self:findChild("DwarfFairy_reel")
    if display.height < FIT_HEIGHT_MAX then
        local posY = (FIT_HEIGHT_MAX - display.height) * self.m_machineRootScale * 0.5 + 10
        if display.height <= FIT_HEIGHT_MIN then
            posY = posY + 30
        end
        nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY)
        local nodeXiaoaixian = self:findChild("m_xiaoaixian")
        nodeXiaoaixian:setPositionY(nodeXiaoaixian:getPositionY() - posY)
        self.m_firstReel:setPositionY(self.m_firstReel:getPositionY() - posY)
        local freespin = self.m_csbOwner["freespin"]
        freespin:setPositionY(freespin:getPositionY() - posY)
        local lock = self.m_csbOwner["lock"]
        lock:setPositionY(lock:getPositionY() - posY)

        local jackpot = self.m_csbOwner["jackpot"]

        jackpot:setPositionY(jackpot:getPositionY() + (FIT_HEIGHT_MAX - display.height) * self.m_machineRootScale * 0.5)
        if display.height < FIT_HEIGHT_MIN then
            jackpot:setPositionY(jackpot:getPositionY() + (1 - self.m_machineRootScale) * 100)
        end
    end

    if globalData.slotRunData.isPortrait then

        local bangHeight =  util_getBangScreenHeight()
        local nodeJackpot = self:findChild("jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY()  -bangHeight )
    
    end

    
    self.m_reelBar = {}
    self.m_reelLine = {}
    self.m_reelTop = {}
    for i = 1, self.m_iReelColumnNum, 1 do
        self.m_reelBar[i] = self.m_csbOwner["reel_bar_"..i]
        self.m_reelLine[i] = self.m_csbOwner["reel_line_"..i]
        self.m_reelTop[i] = self.m_csbOwner["reel_top_"..i]
    end

    self.m_reelMoveTime = 0
end

function CodeGameScreenDwarfFairyMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    if symbolType == self.SYMBOL_BONUS_NORMAL then
        ccbName = "Socre_DwarfFairy_Bonus"
    elseif symbolType == self.SYMBOL_BONUS_MINI then
        ccbName = "Socre_DwarfFairy_Bonus_mini"
    elseif symbolType == self.SYMBOL_BONUS_MINOR then
        ccbName = "Socre_DwarfFairy_Bonus_minor"
    elseif symbolType == self.SYMBOL_BONUS_MAJOR then
        ccbName = "Socre_DwarfFairy_Bonus_major"
    elseif symbolType == self.FLY_COIN_TYPE then
        ccbName = "DwarfFairy_Fly_Coin"
    elseif symbolType == -1 then
        ccbName = self.m_arrNormalSymbol[util_random(1, self.m_iRandomSmallSymbolTypeNum)]
    end

    return ccbName
end

function CodeGameScreenDwarfFairyMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS_NORMAL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.FLY_COIN_TYPE, count = 2}

    return loadNode
end
function CodeGameScreenDwarfFairyMachine:updateReelGridNode(node)
    local reelNode = node
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS_NORMAL 
        or  symbolType == self.SYMBOL_BONUS_MINI
        or symbolType == self.SYMBOL_BONUS_MINOR
        or symbolType == self.SYMBOL_BONUS_MAJOR then

          --下帧调用 才可能取到 x y值
        -- local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        -- reelNode:runAction(callFun)
        if symbolType == self.SYMBOL_BONUS_NORMAL then
            self:setSpecialNodeScore(self,{reelNode})
        end
        
        local labCoin = reelNode:getCcbProperty("m_lb_score")
        if labCoin then
            labCoin:setVisible(true)
        end
        
        if self.m_bonusBreak == true then
            reelNode.p_reelDownRunAnima = "respin"
        end

    elseif self.m_bIsReelStartMove == true then
        -- reelNode:setIdleAnimName("respin")
        util_setCascadeOpacityEnabledRescursion(reelNode, true)
        reelNode:setOpacity(102)
        if self.m_runSpinResultData.p_selfMakeData.select ~= nil and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            reelNode:setIdleAnimName(nil)
        end
    end
end


-- 设置respin分数
function CodeGameScreenDwarfFairyMachine:setSpecialNodeScore(sender, parma)
    local logStr = ""
    local symbolNode = parma[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    logStr = logStr .." iCol = "..tostring(iCol)
    logStr = logStr .. " iRow".. tostring(iRow)
    if iCol ~= nil and iCol == 1 then
        local labCoin = symbolNode:getCcbProperty("m_lb_score")
        if labCoin then
            -- labCoin:setVisible(false)
            labCoin:setString("")
        end
        symbolNode.p_reelDownRunAnima = "buling"
        symbolNode.p_reelDownRunAnimaSound = "DwarfFairySounds/sound_DwarfFairy_bonus.mp3"
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end
    logStr = logStr .." rowCount = "..tostring(rowCount)

    if symbolNode.m_isLastSymbol == true then
        logStr = logStr .." isLastSymbol = true"
    end
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        logStr = logStr .." LastSymbol 1"
        --获取分数
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
        if score then
            logStr = logStr .." LastSymbol 2"
            local lineBet = self:BaseMania_getLineBet() * self.m_lineCount
            score = score * lineBet
            score = util_formatCoins(score, 3)
            local labCoin = symbolNode:getCcbProperty("m_lb_score")
            if labCoin then
                labCoin:setString(score)
                logStr = logStr .." score = "..tostring(score)
            else
                logStr = logStr .." score = not labCoin"
            end
        end
        --   symbolNode:runAnim("buling")
    else
        logStr = logStr .." randomSymbol 1"
        local score = util_random(1, 10)

        local lineBet = self:BaseMania_getLineBet() * self.m_lineCount
        if score == nil then
            score = 1
        end
        score = score * lineBet
        score = util_formatCoins(score, 3)
        local labCoin = symbolNode:getCcbProperty("m_lb_score")
        if labCoin then
            labCoin:setString(score)
            logStr = logStr .." random score = "..tostring(score)
        else
            logStr = logStr .." random score = not labCoin"
        end

        --   symbolNode:runAnim("buling")
    end
    if self.m_iReelRowNum > self.m_iReelMinRow then
        if self:isBonusInLine(iRow, iCol) == true then
            symbolNode.p_reelDownRunAnima = "buling"
            symbolNode.p_reelDownRunAnimaSound = "DwarfFairySounds/sound_DwarfFairy_bonus.mp3"
        else
            symbolNode.p_reelDownRunAnima = "respin"
        end
    end
    self:pushSpinLog(logStr)
end

function CodeGameScreenDwarfFairyMachine:isBonusInLine(iRow, iCol)
    local index = self:getPosReelIdx(iRow, iCol)
    local arrBonus = self.m_runSpinResultData.p_selfMakeData.bonusIcons
    for i = 1, #arrBonus, 1 do
        if arrBonus[i][1] == index then
            return true
        end
    end
    return false
end

function CodeGameScreenDwarfFairyMachine:addAllReelsEffect()
    self.m_respinReel:setVisible(true)
    util_csbPlayForKey(self.m_respinReelAct, "chuxian", false, function()
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_reel_effect_idle.mp3")
        util_csbPlayForKey(self.m_respinReelAct, "idleframe", false, function()
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_reel_effect_disappear.mp3")
            util_csbPlayForKey(self.m_respinReelAct, "over", false, function()
                self.m_respinReel:setVisible(false)
            end, 20)
        end, 20)
    end, 20)
end

function CodeGameScreenDwarfFairyMachine:showFirstReelEffect()
    self.m_bIsReelStartMove = true
    self.m_firstReel:setVisible(true)
    self.m_firstReel:setOpacity(255)
    util_spinePlay(self.m_littlePerson, "kaishiC", false)
    util_spineEndCallFunc(self.m_littlePerson, "kaishiC", function()
        if self.m_bProduceSlots_InFreeSpin then
            self.m_fresSpinBar:hide()
        end
        self:pushSpinLog("showFirstReelEffect-changeReelLength")
        self:changeReelLength(self.m_iReelRowNum - self.m_iReelMinRow,false)
        self:showLittlePersonAnimation()
    end)
end

function CodeGameScreenDwarfFairyMachine:showLittlePersonAnimation()
    util_spinePlay(self.m_littlePerson, "idleB", false)
    util_spineEndCallFunc(self.m_littlePerson, "idleB", function()
        local random = util_random(1, 10)
        if random % 3 == 0 then
            util_spinePlay(self.m_littlePerson, "idleA", false)
            util_spineEndCallFunc(self.m_littlePerson, "idleA", function()
                self:showLittlePersonAnimation()
            end)
        else
            self:showLittlePersonAnimation()
        end
    end)
end

function CodeGameScreenDwarfFairyMachine:flyCoin()
    local parent = self.m_csbOwner["m_xiaoaixian"]:getParent()
    local coin, coinAct = util_csbCreate("jinbi.csb")
    local actTime = 0.5
    local upTime = 0.15
    util_csbPlayForKey(coinAct, "actionframe", false, function()
        self:addAllReelsEffect()
        coin:removeFromParent(true)
    end)
    local posX = self.m_csbOwner["m_xiaoaixian"]:getPositionX()
    local posY = self.m_csbOwner["m_xiaoaixian"]:getPositionY()
    self.m_csbOwner["root"]:addChild(coin,10000)
    coin:setPosition(posX - 57, posY + 130)
    local moveUp = cc.EaseSineInOut:create(cc.MoveTo:create(upTime, cc.p(coin:getPositionX(), coin:getPositionY() + 120)))
    local move = cc.EaseSineIn:create(cc.MoveTo:create(actTime - upTime, cc.p(self.m_csbOwner["DwarfFairy_reel"]:getPositionX(), self.m_csbOwner["DwarfFairy_reel"]:getPositionY() - 122)))
    coin:runAction(cc.Sequence:create(moveUp, move))
end

function CodeGameScreenDwarfFairyMachine:getIsShowReelEffect(reelCurrRow)
    local iRandomShow = util_random(1,100)
    local effectWeight = 20
    if reelCurrRow >= 5 then
        effectWeight = 60
    end
    if iRandomShow > effectWeight then
        return false
    else
        return true
    end
end

function CodeGameScreenDwarfFairyMachine:getWinBonusCol()
    self.m_winBonusColFlag = {false, false, false, false, false}
    local reels = self.m_runSpinResultData.p_reels
    for i = 2, self.m_iReelColumnNum, 1 do
        for j = 1, #reels, 1 do
            if self:isBonusSymbal(reels[j][i]) then
                self.m_winBonusColFlag[i] = true
                break
            end
        end
        if self.m_winBonusColFlag[i] == false then
            return
        end
    end
end

function CodeGameScreenDwarfFairyMachine:getScatterCol()
    self.m_scatterColFlag = {false, false, false, false, false}
    local reels = self.m_runSpinResultData.p_reels
    for i = 3, self.m_iReelColumnNum, 1 do
        for j = 1, #reels, 1 do
            if reels[j][i] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.m_scatterColFlag[i] = true
                break
            end
        end
        if self.m_scatterColFlag[i] == false then
            return
        end
    end
end

function CodeGameScreenDwarfFairyMachine:isBonusSymbal(symbolType)
    if symbolType == self.SYMBOL_BONUS_NORMAL
      or  symbolType == self.SYMBOL_BONUS_MINI
      or symbolType == self.SYMBOL_BONUS_MINOR
      or symbolType == self.SYMBOL_BONUS_MAJOR then
        return true
    end
    return false
end

function CodeGameScreenDwarfFairyMachine:produceSlots()
    --延长滚动长度
    local reelCurrRow = self.m_runSpinResultData.p_selfMakeData.unlockedReels
    self:getScatterCol()
    if reelCurrRow > self.m_iReelRowNum then
        local addition = 0
        for i=2,#self.m_reelRunInfo, 1 do
            local runInfo = self.m_reelRunInfo[i]
            self:getWinBonusCol()
            --得到初始长度
            local len = runInfo:getInitReelRunLen()
            if self.m_winBonusColFlag[i] == true then
                addition = self.m_reelAddFallLenNum[reelCurrRow - self.m_iReelRowNum] * i
            else
                addition = addition + 6
            end
            runInfo:setReelRunLen(len + self.m_reelAddLenNum[reelCurrRow - self.m_iReelRowNum] + addition)
        end
        local isShowReelEffect = self:getIsShowReelEffect(reelCurrRow)
        if self.m_bProduceSlots_InFreeSpin then
            isShowReelEffect = false
        end
        if isShowReelEffect then
            for i=1,#self.m_reelRunInfo do
                local runInfo = self.m_reelRunInfo[i]
                --得到初始长度
                local len = runInfo:getReelRunLen()
                runInfo:setReelRunLen(len + 120)
            end
        end
        if isShowReelEffect then
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_reel_effect_appear.mp3")
            util_spinePlay(self.m_person, "tanjinbi", false)
            util_spineFrameCallFunc(self.m_person, "tanjinbi", "show", function()
                self:flyCoin()
            end, function()
                util_spinePlay(self.m_person, "idle", true)
            end)
        end

    end
    if reelCurrRow ~= self.m_iReelRowNum then
        local direction = reelCurrRow - self.m_iReelRowNum
        self.m_iReelRowNum = reelCurrRow
        self:changeReelData()
        self:changeNewReelNode()
    end

    BaseSlots.produceSlots(self)
end

function CodeGameScreenDwarfFairyMachine:updateNetWorkData()
    if self.m_reelMoveTime > 0 and self.m_runSpinResultData.p_selfMakeData.unlockedReels > self.m_iReelMinRow then
        self.m_reelMoveTime = self.m_reelMoveTime + 1.6
    end

    scheduler.performWithDelayGlobal(function()
        if  self.m_reelMoveTime > 0 then
            self:changeReelData()
        end
        self.m_isWaitChangeReel=true
        self:produceSlots()
        --存在等待时间延后调用下面代码
        if self.m_waitChangeReelTime and self.m_waitChangeReelTime>0 then
            scheduler.performWithDelayGlobal(function()
                self.m_waitChangeReelTime=nil
                self:updateNetWorkData()
            end, self.m_waitChangeReelTime, self:getModuleName())
            return
        end
        self.m_isWaitingNetworkData = false

        self:operaNetWorkData()
        self.m_reelMoveTime = 0
    end, self.m_reelMoveTime, self:getModuleName())

end

function CodeGameScreenDwarfFairyMachine:operaNetWorkData()
    BaseSlotoManiaMachine.operaNetWorkData(self)
    if self.m_iReelRowNum > self.m_iReelMinRow then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

-- 每个reel条滚动到底
function CodeGameScreenDwarfFairyMachine:slotOneReelDown(reelCol)
    BaseMachine.slotOneReelDown(self, reelCol)
    if self.m_iReelRowNum > self.m_iReelMinRow then
        if reelCol == 1 then
            scheduler.performWithDelayGlobal(function()
                self:firstReelAnimation()
            end, 0.5, self:getModuleName())
        elseif reelCol == 5 then
            self.m_bonusBreak = false
        elseif self.m_winBonusColFlag[reelCol] == false then
            self.m_bonusBreak = true
        end
        if reelCol >= 3 then
            if self.m_scatterColFlag[reelCol] == false then
                self.m_scatterBreak = true
            end
        end

    end
end

function CodeGameScreenDwarfFairyMachine:reelDownNotifyPlayGameEffect( )
    if self.m_scatterBreak == true then
        self.m_scatterBreak = false
        for i = 1, #self.m_vecScatter, 1 do
            self.m_vecScatter[i]:runAnim("respin")
        end
    end
    for i = #self.m_vecScatter, 1, -1 do
        table.remove( self.m_vecScatter, i)
    end

    BaseMachine.reelDownNotifyPlayGameEffect(self)

end

function CodeGameScreenDwarfFairyMachine:slotReelDown()
    if self.m_runSpinResultData.p_selfMakeData.jackpotCoins ~= nil and self.m_runSpinResultData.p_selfMakeData.jackpotCoins > 0 then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
    BaseMachine.slotReelDown(self)
    
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenDwarfFairyMachine:specialSymbolActionTreatment( node)
    if not node then
        return
    end


    -- node:runAnim("buling",true)
    if self.m_scatterBreak == true then
        if self.m_iReelRowNum > self.m_iReelMinRow then
            node:runAnim("respin")
        else
            node:runAnim("idleframe")
        end
    else
        self.m_vecScatter[#self.m_vecScatter + 1] = node
    end


end

function CodeGameScreenDwarfFairyMachine:getJackPotNodePos()
    if self.m_vecJackPotNodePos == nil then
        self.m_vecJackPotNodePos = {}
    end
    for iCol = 2, self.m_iReelColumnNum, 1 do
        local totalRow = #self.m_runSpinResultData.p_reels
        for iRow = 1, totalRow, 1 do
            if self.m_runSpinResultData.p_reels[iRow][iCol] > self.SYMBOL_BONUS_NORMAL then
                if self:isBonusInLine(totalRow - iRow + 1, iCol) then
                    local id = self:getPosReelIdx(totalRow - iRow + 1, iCol)
                    self.m_vecJackPotNodePos[#self.m_vecJackPotNodePos + 1] = {index = id, type = self.m_runSpinResultData.p_reels[iRow][iCol]}
                end
            end
        end
    end
    if #self.m_vecJackPotNodePos > 0 then
        return true
    end
    return false
end

function CodeGameScreenDwarfFairyMachine:addSelfEffect()
    if self.m_runSpinResultData.p_selfMakeData.unlockedReels > self.m_iReelMinRow then
        if self:getJackPotNodePos() == true then
            local jackPotEffect = GameEffectData.new()
            jackPotEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            jackPotEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            jackPotEffect.p_selfEffectType = self.m_jackPotEffect
            self.m_gameEffects[#self.m_gameEffects + 1] = jackPotEffect
        end
    end

    if self.m_iBetLevel == 1 then
        for iCol = 2, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node then
                    if self:isBonusSymbal(node.p_symbolType) then
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
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
            self.m_bHaveBonusGame = true
        end
    end
end

function CodeGameScreenDwarfFairyMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index=1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

function CodeGameScreenDwarfFairyMachine:showEffect_Bonus(effectData)
    --  local data = self:BaseMania_getCollectData()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
        -- 停掉背景音乐
        self.m_collectIcon:collectOver(function()
            self:showBonusGame(
            function()
                self.m_collectIcon:collect(0)
                self.m_guochang:setVisible(true)
                gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_guochang.mp3")
                self.m_bottomUI:hideAverageBet()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                util_csbPlayForKey(self.m_guochangAct, "guochang", false, function()
                    self.m_guochang:setVisible(false)
                    gLobalSoundManager:stopBgMusic()
                    self:resetMusicBg(true)
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_freeSpinOverCurrentTime = 1
                end)

                performWithDelay(self, function()
                    if self.m_bonusWin ~= nil then
                        self.m_bonusWin = self.m_bonusWin + self.m_serverWinCoins
                        self.m_bottomUI.m_normalWinLabel:setString(util_getFromatMoneyStr(self.m_bonusWin))
                    end
                end, 0.6)
            end
        )
        end)
        self:clearCurMusicBg()

        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
        return true
end

function CodeGameScreenDwarfFairyMachine:showBonusGame(func)
    self.m_guochang:setVisible(true)
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_guochang.mp3")
    util_csbPlayForKey(self.m_guochangAct, "guochang", false, function()
        self.m_guochang:setVisible(false)
    end)
    self.m_bottomUI:showAverageBet()
    performWithDelay(self, function()
        local view = util_createView("CodeDwarfFairySrc.DwarfFairyBonusGame")
        view:initViewData(func, self)
        self:addChild(view, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = view})
    end, 0.6)
end

function CodeGameScreenDwarfFairyMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" then
        -- self:BaseMania_completeCollectBonus()
        -- self:updateCollect()
        self:playGameEffect()
        return
    end

    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    self.m_isRunningEffect = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
end

function CodeGameScreenDwarfFairyMachine:creatReelRunAnimation(col)
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
    if self.m_iReelRowNum == self.m_iReelMinRow then
        reelEffectNode:setVisible(true)
        util_csbPlayForKey(reelAct, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenDwarfFairyMachine:createNewBonus(symbolType, rowIndex, cloumnIndex, slotParent)
    local columnData = self.m_reelColDatas[1]
    local parentData = self.m_slotParents[1]
    local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, cloumnIndex, false)

    node.p_slotNodeH = columnData.p_showGridH
    node.p_symbolType = symbolType
    node.p_preSymbolType = parentData.preSymbolType
    node.p_showOrder = parentData.order

    node.p_reelDownRunAnima = parentData.reelDownAnima

    node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
    node.p_layerTag = parentData.layerTag

    slotParent:addChild(node, parentData.order, parentData.tag)
    node:runIdleAnim()

    return node
end

function CodeGameScreenDwarfFairyMachine:firstReelAnimation()

    local reelParent = self:getReelParent(1)
    local direction = nil
    local lastIndex = nil
    local bonusNum = 0
    for i = 1, self.m_iReelMinRow, 1 do
        if self:getMatrixPosSymbolType(i, 1) ~= self.SYMBOL_BONUS_NORMAL then
            lastIndex = i
            if i == 1 then
                direction = -1
            end
        else
            if i == 1 then
                direction = 1
            end
            bonusNum = bonusNum + 1
        end
    end
    local addBonusNum = self.m_iReelMinRow - bonusNum
    local arrAddBonus = {}
    local distance = addBonusNum * direction

    local children = reelParent:getChildren()
    table.sort( children, function(a, b)
        return a.p_rowIndex < b.p_rowIndex
    end )
    if direction == -1 then
        for i = 1, #children, 1 do
            local child = children[i]
            if child.p_rowIndex > self.m_iReelMinRow  then
                if addBonusNum > 0 then
                    addBonusNum = addBonusNum - 1
                    local bonus = self:createNewBonus(self.SYMBOL_BONUS_NORMAL, i + distance, 1, reelParent)
                    arrAddBonus[#arrAddBonus + 1] = bonus
                    bonus:setPosition(cc.p(child:getPosition()))
                end
                child.p_rowIndex = child.p_rowIndex - distance
                child:setPositionY(child:getPositionY() - distance * self.m_SlotNodeH)
            else
                child.p_rowIndex = child.p_rowIndex + distance
            end
        end
        local rowIndex = 4
        local tempNode = self:getReelParent(1):getChildByTag(self:getNodeTag(1,  1, SYMBOL_NODE_TAG))
        if  addBonusNum > 0 then
            for i = 1, addBonusNum, 1 do
                rowIndex = 4 - i
                local bonus = self:createNewBonus(self.SYMBOL_BONUS_NORMAL, rowIndex , 1, reelParent)
                bonus.p_rowIndex = rowIndex
                arrAddBonus[#arrAddBonus + 1] = bonus
                bonus:setPosition(tempNode:getPositionX(), tempNode:getPositionY() + (rowIndex +1)* self.m_SlotNodeH)
            end
        end
    else
        local tempNode = self:getReelParent(1):getChildByTag(self:getNodeTag(1,  1, SYMBOL_NODE_TAG))
        local rowIndex = self.m_iReelRowNum
        for i = 1, #children, 1 do
            local child = children[i]
            child.p_rowIndex = child.p_rowIndex + distance
            rowIndex = math.min(rowIndex, child.p_rowIndex)
        end
        for i = 1, addBonusNum, 1 do
            rowIndex = rowIndex - 1
            local bonus = self:createNewBonus(self.SYMBOL_BONUS_NORMAL, rowIndex , 1, reelParent)
            arrAddBonus[#arrAddBonus + 1] = bonus
            bonus:setPosition(tempNode:getPositionX(), tempNode:getPositionY() - i * self.m_SlotNodeH)
        end
    end

    local moveDistance = distance * self.m_SlotNodeH
    local children = reelParent:getChildren()
    local moveTime = 0.25 * math.abs( distance )
    for i = 1, #children, 1 do
        local child = children[i]
        child:setTag(self:getNodeTag(1, child.p_rowIndex, SYMBOL_NODE_TAG))
        local seq = cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
            if i == #children then
                gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_bonus_move.mp3")
            end
        end), cc.MoveBy:create(moveTime, cc.p(0,moveDistance)))
        child:runAction(seq)
    end

    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_trigger_respin.mp3")
            util_spinePlay(self.m_person, "disappear", false)
            util_spineFrameCallFunc(self.m_person, "disappear", "show", function()
                gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_respin2.mp3")
                local node1 =  self:getFixSymbol(1,  1, SYMBOL_NODE_TAG)
                local node2 =  self:getFixSymbol(1,  2, SYMBOL_NODE_TAG)
                local node3 =  self:getFixSymbol(1,  3, SYMBOL_NODE_TAG)
                local seq = cc.Sequence:create(cc.MoveTo:create(0.3, cc.p(node2:getPosition())), cc.CallFunc:create(function ()
                    if not tolua.isnull(node1) then
                        node1:setVisible(false)
                    end
                    if not tolua.isnull(node2) then
                        node2:setVisible(false)
                    end
                    if not tolua.isnull(node3) then
                        node3:setVisible(false)
                    end
                    self:showFirstReelEffect()
                    for i = 1, #arrAddBonus, 1 do
                        arrAddBonus[i]:removeFromParent(true)
                        self:pushSlotNodeToPoolBySymobolType(arrAddBonus[i].p_symbolType,arrAddBonus[i])
                    end

                end))
                if node1 then
                    node1:runAction(seq)
                end
                if node3 then
                    node3:runAction(cc.MoveTo:create(0.3, cc.p(node2:getPosition())))
                end
            end)
        end,  0.5 + moveTime, self:getModuleName())
end

function CodeGameScreenDwarfFairyMachine:changeReelData()
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end
end

function CodeGameScreenDwarfFairyMachine:changeNewReelNode()
    for i = 2, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
    end
end
function CodeGameScreenDwarfFairyMachine:changeReelLength(direction,isChangeReel)
    if isChangeReel then
        self:changeNewReelNode()
    end
    --第一列不用动
    if direction <= self.m_iReelMinRow - self.m_iReelMaxRow + 1 then
        self.m_jackpotBar:runAction(cc.FadeIn:create(0.5))
    end
    local minPercent = math.ceil(self.m_iReelMinRow * 100 / self.m_iReelMaxRow)
    local endPercent = math.ceil((self.m_iReelMinRow + direction) * 100 / self.m_iReelMaxRow )
    local movePercent = 0
    local maxHeight = self.m_SlotNodeH * self.m_iReelMaxRow

    local scheduleDelayTime = 0.016
    local percent = 0
    if direction > 0 then
        -- self.m_bIsReelStartMove = true
        self.m_goldOffset = self.m_vecGoldOffset[direction]
        movePercent = self.m_reelMoveUpSpeed[direction]
        percent = minPercent
        direction = 1
        self.m_logo:runAction(cc.FadeOut:create(0.3))
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_reel_up.mp3")
    else
        self.m_bIsReelStartMove = false
        percent = math.ceil((self.m_iReelMinRow - direction) * 100 / self.m_iReelMaxRow )
        endPercent = minPercent
        movePercent = self.m_reelMoveDownSpeed[-direction]
        direction = -1
        scheduleDelayTime = 0.5 * movePercent / (percent - endPercent)

        if self.m_bProduceSlots_InFreeSpin == false then
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_gold_pot.mp3")
        end
        util_spinePlay(self.m_gold, "actionframe2", false)
        util_spineEndCallFunc(self.m_gold, "actionframe2", function()
            util_spinePlay(self.m_gold, "ildeframe", true)
        end)
    end
    if self.m_iReelRowNum >= self.m_iReelMaxRow - 1 then
        self.m_jackpotBar:runAction(cc.FadeOut:create(0.5))
    end

    self.m_updateReelHeightID = scheduler.scheduleGlobal( function(delayTime)
        self.m_reelMoveTime = self.m_reelMoveTime + delayTime
        local distance = 0
        if direction > 0 then

            if percent + movePercent * direction > endPercent then
                distance = (endPercent - percent) * maxHeight / 100
                percent = endPercent
                scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                if self.m_bProduceSlots_InFreeSpin == false then
                    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_gold_pot.mp3")
                end
                util_spinePlay(self.m_gold, "actionframe", false)
                util_spineEndCallFunc(self.m_gold, "actionframe", function()
                    util_spinePlay(self.m_gold, "ildeframe", true)
                end)
            else
                percent = percent + movePercent * direction
                distance = movePercent * maxHeight * direction / 100
            end
        else
            if percent + movePercent * direction < minPercent then
                distance = (percent - endPercent) * maxHeight * direction / 100
                percent = minPercent
                scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                self.m_logo:runAction(cc.FadeIn:create(0.3))
                -- self.m_person:setVisible(true)

                if self.m_bProduceSlots_InFreeSpin == false then
                    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_back.mp3")
                end
                util_spinePlay(self.m_person, "chuxian", false)
                util_spineFrameCallFunc(self.m_person, "chuxian", "show", function()
                    util_spinePlay(self.m_gold, "actionframe3", false)
                    if self.m_bProduceSlots_InFreeSpin == false then
                        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_gold_pot.mp3")
                    end
                    util_spineEndCallFunc(self.m_gold, "actionframe3", function()
                        util_spinePlay(self.m_gold, "ildeframe", true)
                    end)
                end, function()
                    util_spinePlay(self.m_person, "idle", true)
                end)
                if self.m_bProduceSlots_InFreeSpin == true and self.m_bIsHideLittlePerson ~= true then
                    self.m_fresSpinBar:show()
                end
            else
                percent = percent + movePercent * direction
                distance = movePercent * maxHeight * direction / 100
            end
        end
        if not self.m_goldOffset then
            self.m_goldOffset = 0
        end
        self.m_gold:setPositionY(self.m_gold:getPositionY() + distance - (self.m_goldOffset * movePercent * direction))

        for i = 1, self.m_iReelColumnNum, 1 do
            if i ~= 1 then
                local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
                local rect = clipNode:getClippingRegion()
                clipNode:setClippingRegion(
                    {
                        x = rect.x,
                        y = rect.y,
                        width = rect.width,
                        height = rect.height + distance
                    }
                )
                self.m_reelBar[i]:setPercent(percent)
            end
            self.m_reelLine[i]:setPercent(percent)
            self.m_reelTop[i]:setPosition(self.m_reelTop[i]:getPositionX(), self.m_reelTop[i]:getPositionY() + distance)
        end
    end, scheduleDelayTime)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end

function CodeGameScreenDwarfFairyMachine:normalSpinBtnCall()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_iReelRowNum > self.m_iReelMinRow then
        self:bonusAnimation("idleframe", false)
        local direction = self.m_iReelMinRow - self.m_iReelRowNum
        self.m_iReelRowNum = self.m_iReelMinRow
        -- self:changeReelData()
        self:pushSpinLog("showFirstReelEffect-normalSpinBtnCall")
        self:changeReelLength(direction,true)
        self.m_firstReel:runAction(cc.FadeOut:create(1))
    end
    if self.m_bIsHideLittlePerson == true then
        self.m_bIsHideLittlePerson = false
        self.m_firstReel:runAction(cc.FadeOut:create(1))
    end
    BaseMachine.normalSpinBtnCall(self)
end

function CodeGameScreenDwarfFairyMachine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self, param)
    --断网数据错误判断
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    if self.m_runSpinResultData.p_selfMakeData.jackpotCoins ~= nil and self.m_runSpinResultData.p_selfMakeData.jackpotCoins > 0 then
        self.m_serverWinCoins = 0
        self:setLastWinCoin(0)
    end

end

function CodeGameScreenDwarfFairyMachine:playEffectNotifyNextSpinCall( )


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

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

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

function CodeGameScreenDwarfFairyMachine:MachineRule_playSelfEffect(effectData)

    -- freeSpin wild 列 变化
    if effectData.p_selfEffectType == self.m_jackPotEffect then
        self:showJackPotWindow(effectData)
    elseif effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:collectCoin(effectData)
        -- effectData.p_isPlay = true
        -- self:playGameEffect()
    elseif effectData.p_selfEffectType == self.BONUS_GAME_EFFECT then
        -- self:showEffect_Bonus(effectData)
        effectData.p_isPlay = true
        self:playGameEffect()
        self.m_bHaveBonusGame = false
    end

    return true
end

function CodeGameScreenDwarfFairyMachine:collectCoin(effectData)
    local endNode = self.m_csbOwner["lock"]
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_coin_fly.mp3")
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local coins, act = self:getSlotNodeBySymbolType(self.FLY_COIN_TYPE)
        if i == 1 then
            coins.m_isLastSymbol = true
        end
        self:addChild(coins, 99999)
        -- coins:setScale(self.m_machineRootScale)
        coins:setPosition(newStartPos)

        local pecent = self:getProgress(self:BaseMania_getCollectData())
        coins:runAnim("actionframe")
        
        if self.m_bHaveBonusGame ~= true and coins.m_isLastSymbol == true then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(delayNode, function()
            delayNode:removeFromParent()
            local bez =
            cc.BezierTo:create(
            0.5,
            {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
            coins:runAction(cc.Sequence:create(bez, cc.CallFunc:create(function()
                if coins.m_isLastSymbol == true then
                    self.m_collectIcon:collect(pecent)
                    if self.m_bHaveBonusGame == true and coins.m_isLastSymbol == true then
                        performWithDelay(self, function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end, 0.8)

                    end
                end
                coins:removeFromParent()
                local symbolType = coins.p_symbolType
                self:pushSlotNodeToPoolBySymobolType(symbolType, coins)
            end)))
        end, 0.5)
        table.remove(self.m_collectList, i)
    end
end

function CodeGameScreenDwarfFairyMachine:getJackpotScore(index)
    local arrBonus = self.m_runSpinResultData.p_winLines
    for i = 1, #arrBonus, 1 do
        local pos = arrBonus[i].p_iconPos[1]
        if pos == index then
            return arrBonus[i].p_amount
        end
    end
end

function CodeGameScreenDwarfFairyMachine:showJackPotWindow(effectData)
    if #self.m_vecJackPotNodePos > 0 then
        local index = self.m_vecJackPotNodePos[1].index
        local type = self.m_vecJackPotNodePos[1].type
        local score = self:getJackpotScore(index)
        local pos = self:getRowAndColByPos(index)
        local node = self:getReelParent(pos.iY):getChildByTag(self:getNodeTag(pos.iY,  pos.iX, SYMBOL_NODE_TAG))
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local id = self.SYMBOL_BONUS_NORMAL + 5 - type
        local coin = score
        node:runAnim("actionframe", false, function()
            node:runAnim("actionframe", false, function()
                node:runAnim("idleframe", false)
                self:showRespinJackpot(id, coin,
                    function ()
                        self:showJackPotWindow(effectData)
                    end)
            end)
        end)
        table.remove(self.m_vecJackPotNodePos, 1)
    else
        scheduler.performWithDelayGlobal(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.8, self:getModuleName())
    end

end

function CodeGameScreenDwarfFairyMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
    if winAmonut == nil then
        return
    end

    BaseMachine.checkFeatureOverTriggerBigWin(self, winAmonut , feature)
    self.m_bonusWin = winAmonut
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenDwarfFairyMachine:levelFreeSpinEffectChange()
    self:runCsbAction("changefreespin")

end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenDwarfFairyMachine:levelFreeSpinOverChangeEffect(content)
    self:runCsbAction("changeNomal")
end

function CodeGameScreenDwarfFairyMachine:showFreeSpinView(effectData)

    self:clearCurMusicBg()
    gLobalSoundManager:playSound("")

    local wheelBG, bgAct = util_csbCreate("DwarfFairy/GameScreenDwarfFairyBg_0.csb")
    self:addChild(wheelBG, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
    if display.height > FIT_HEIGHT_MAX then
        wheelBG:getChildByName("DwarfFairy_Bg_4"):setScaleY((display.height / FIT_HEIGHT_MAX) + 2.2)
    end
    util_csbPlayForKey(bgAct, "normal_lunpan", false, function()
        self.m_runSpinResultData.p_selfMakeData.select = self.m_runSpinResultData.p_selfMakeData.select + 1
        self.m_bottomUI:setVisible(false)
        self.m_topUI:setVisible(false)
        local bonusWheel = util_createView("CodeDwarfFairySrc.DwarfFairyWheelView", self.m_runSpinResultData.p_selfMakeData)
        local callback = function ()
            scheduler.performWithDelayGlobal(
                function()
                    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_wheel_disappear.mp3")
                    bonusWheel:runCsbAction("over", false, function ()
                        bonusWheel:removeFromParent(true)
                        self.m_bottomUI:setVisible(true)
                        self.m_topUI:setVisible(true)
                        util_csbPlayForKey(bgAct, "lunpan_freespin", false, function()
                            wheelBG:removeFromParent(true)
                            self:wheelRotateOver(effectData)
                        end)
                    end)
                end,  1.0, self:getModuleName())

        end
        bonusWheel:setPosition(display.width * 0.5, display.height * 0.5)
        bonusWheel:initCallBack(callback)
        self:addChild(bonusWheel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
        self.m_bonusSelect = self.m_runSpinResultData.p_selfMakeData.wheel[self.m_runSpinResultData.p_selfMakeData.select]
        self:hideReel()
        if globalData.slotRunData.machineData.p_portraitFlag then
            bonusWheel.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = bonusWheel})

    end)

end

function CodeGameScreenDwarfFairyMachine:hideReel() -- respin 同时触发 free spin
    if self.m_bonusSelect ~= nil and type(self.m_bonusSelect) ~= "string" then
        --触发free spin
        if self.m_iReelRowNum > self.m_iReelMinRow then
            local direction = self.m_iReelMinRow - self.m_iReelRowNum
            self.m_iReelRowNum = self.m_iReelMinRow
            self.m_bIsHideLittlePerson = true
            self:pushSpinLog("showFirstReelEffect-hideReel")
            self:changeReelLength(direction,true)
        end
    end
end

function CodeGameScreenDwarfFairyMachine:showOrHideFreespinBar(show, isRespin)
    if show == true then
        self.m_fresSpinBar:setVisible(true)
        self.m_fresSpinBar:show()
        self.m_gold:setVisible(false)
        self.m_person:setVisible(false)
        self.m_logo:setVisible(false)
    else
        self.m_fresSpinBar:hide()
        self.m_gold:setVisible(true)
        self.m_person:setVisible(true)
        self.m_logo:setVisible(true)
        self.m_gold:runAction(cc.FadeIn:create(0.5))
        self.m_person:runAction(cc.FadeIn:create(0.5))
        if isRespin ~= true then
            self.m_logo:runAction(cc.FadeIn:create(0.5))
        end

    end
end

function CodeGameScreenDwarfFairyMachine:wheelRotateOver(effectData)
    if self.m_bonusSelect ~= nil and type(self.m_bonusSelect) ~= "string" then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_freespin")
        self:showOrHideFreespinBar(true)
        self.m_guochang:setVisible(true)
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_guochang.mp3")
        util_csbPlayForKey(self.m_guochangAct, "guochang", false, function()
            self.m_guochang:setVisible(false)
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_pop_window.mp3")
            self:showFreeSpinStart(
            self.m_iFreeSpinTimes,
            function()

                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            )
        end)

    elseif self.m_bonusSelect ~=nil then
        --触发jackpot
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_wheel_disappear.mp3")
        self:showRespinJackpot(self.m_jackpotIndex[self.m_bonusSelect], self.m_runSpinResultData.p_selfMakeData.jackpotCoins,
        function ()
            local delayTime = 0--self:getShowCoinTime(self.m_serverWinCoins)
            scheduler.performWithDelayGlobal(
                function()
                    self.m_serverWinCoins = self.m_runSpinResultData.p_winAmount
                    self:setLastWinCoin(self.m_serverWinCoins)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins, true})
                    self:resetMusicBg()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_serverWinCoins, GameEffect.EFFECT_RESPIN})
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                delayTime,
                self:getModuleName()
            )
        end)
    end
end

function CodeGameScreenDwarfFairyMachine:getShowCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self:getLastWinCoin() / totalBet
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 4
    end
    return showTime
end

function CodeGameScreenDwarfFairyMachine:bonusAnimation(animation, isLoop)
    local arrBonus = self.m_runSpinResultData.p_selfMakeData.bonusIcons
    for i = 1, #arrBonus, 1 do
        local pos = self:getRowAndColByPos(arrBonus[i][1])
        local node = self:getReelParent(pos.iY):getChildByTag(self:getNodeTag(pos.iY,  pos.iX, SYMBOL_NODE_TAG))
        if node ~= nil then
            node:runAnim(animation, isLoop)
        end
    end
end

function CodeGameScreenDwarfFairyMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel  then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:sendSpinLog()
    self:showLineFrame()
    -- and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false
    if self.m_iReelRowNum > self.m_iReelMinRow  then
        if self.m_runSpinResultData.p_selfMakeData.select == nil then
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            self:clearWinLineEffect()
        end
        self:bonusAnimation("actionframe", true)
        performWithDelay(self, function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 2.3)

    else
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
         or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            performWithDelay(self, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, 0.5)
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end


    return true
end

-- function CodeGameScreenDwarfFairyMachine:showEffect_FreeSpinOver()

--     self.m_freeSpinOverCurrentTime = 1
--     BaseMachineGameEffect.showEffect_FreeSpinOver(self)
--     self.m_fresSpinBar:getShowCoinTime() + 1,
--     return true
-- end

function CodeGameScreenDwarfFairyMachine:showFreeSpinOverView()
    -- 由于 freespin时， 2，4列不参与滚动， 所以最后阶段需要补偿最后一个格子用于滚动处理
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_pop_window.mp3")

            local view=self:showFreeSpinOver(
                globalData.slotRunData.lastWinCoin,
                globalData.slotRunData.totalFreeSpinCount,
                function()
                    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_click.mp3")
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_normal")
                    self:showOrHideFreespinBar(false, true)
                    self.m_guochang:setVisible(true)
                    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_guochang.mp3")
                    util_csbPlayForKey(self.m_guochangAct, "guochang", false, function()
                        self.m_guochang:setVisible(false)
                        self:triggerFreeSpinOverCallFun()
                    end)
                end
            )
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=0.55,sy=0.55},1110)
        end,
        1,
        self:getModuleName()
    )

end

function CodeGameScreenDwarfFairyMachine:showRespinJackpot(index,coins,func)
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_pop_window.mp3")
    local jackPotWinView = util_createView("CodeDwarfFairySrc.DwarfFairyJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,util_formatCoins(coins,20),self,func)
end

function CodeGameScreenDwarfFairyMachine:MachineRule_initGame(  )
    -- 断线重连,重置轮盘
    -- local a = self.m_runSpinResultData.p_selfMakeData
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:showOrHideFreespinBar(true)
        end
    -- elseif self.m_runSpinResultData.p_selfMakeData.jackpotCoins ~= nil and self.m_runSpinResultData.p_selfMakeData.jackpotCoins > 0 then
    --     local effectData = GameEffectData.new()
    --     effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
    --     self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function CodeGameScreenDwarfFairyMachine:BaseMania_updateCollect(addCount,index,totalCount)
    if not index then
        index=1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index])=="table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

function CodeGameScreenDwarfFairyMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount,1,totalCount)
    end

end

function CodeGameScreenDwarfFairyMachine:requestSpinResult()

    self:clearSpinLog()

    self.m_collectIcon:hideTip()

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
---------------------------------------------------------------------------

function CodeGameScreenDwarfFairyMachine:unlockHigherBet()
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

function CodeGameScreenDwarfFairyMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end

function CodeGameScreenDwarfFairyMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:updateBetLevel()
    self.m_collectIcon:initByGameData({betLevel = self.m_iBetLevel, betNum = self.m_BetChooseGear, progress = self.m_collectProgress})
    self:addObservers()
    self:enterGamePlayMusic()
end

function CodeGameScreenDwarfFairyMachine:initGameStatusData(gameData)

    if gameData.collect ~= nil then
        self.m_collectProgress = self:getProgress(gameData.collect[1])
    else
        self.m_collectProgress = 0
    end

    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenDwarfFairyMachine:getProgress(collect)
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

function CodeGameScreenDwarfFairyMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_enter_game.mp3")

            scheduler.performWithDelayGlobal(
                function()
                    self:resetMusicBg()
                    self:setMinMusicBGVolume( )
                end,
                4,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end


function CodeGameScreenDwarfFairyMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_collectIcon.m_iBetLevel or self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel > self.m_iBetLevel then
            self.m_collectIcon:lock(self.m_iBetLevel)
        elseif perBetLevel < self.m_iBetLevel then
            gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_unlock.mp3")
            self.m_collectIcon:unlock(self.m_iBetLevel)
        else
            self.m_collectIcon.m_iBetLevel = self.m_iBetLevel
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        local winAmonut =  params[1]
        if type(winAmonut) == "number" then
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winRatio = winAmonut / lTatolBetNum
            local soundName = nil
            local soundTime = 2
            if winRatio > 0 then
                if winRatio <= 1 then
                    soundName = "DwarfFairySounds/sound_DwarfFairy_win_1.mp3"
                    soundTime = 2
                elseif winRatio > 1 and winRatio <= 3 then
                    soundName = "DwarfFairySounds/sound_DwarfFairy_win_2.mp3"
                    soundTime = 2
                elseif winRatio > 3 then
                    soundName = "DwarfFairySounds/sound_DwarfFairy_win_3.mp3"
                    soundTime = 4
                end
            end

            if soundName ~= nil then
                globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
            end

        end
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
    -- 如果需要改变父类事件监听函数，则在此处修改(具体哪些监听看父类的addObservers)
end

function CodeGameScreenDwarfFairyMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_updateReelHeightID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenDwarfFairyMachine:removeObservers()
    BaseSlotoManiaMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end
-------------------------------------------日志发送 START
function CodeGameScreenDwarfFairyMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil

    if storedIcons == nil then
        return
    end
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end
--缓存日志
function CodeGameScreenDwarfFairyMachine:pushSpinLog(strLog)
    if not self.m_spinLog then
        local fieldValue = util_getUpdateVersionCode(false) or "Vnil"
        self.m_spinLog = "START "..fieldValue.." | \n"
    end
    strLog = tostring(strLog)
    self.m_spinLog = self.m_spinLog..strLog.. " | \n"
end
--清空日志
function CodeGameScreenDwarfFairyMachine:clearSpinLog()
    self.m_spinLog = nil
end
--检测是否存在问题
function CodeGameScreenDwarfFairyMachine:checkSpinError()
    local logStr = " checkSpinError start | \n"
    local isError = false
    local lineBet = self:BaseMania_getLineBet() * self.m_lineCount
    local serverData = tostring(globalData.slotRunData.severGameJsonData)
    for iCol = 2, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolType then
                local curSymbolType = symbolNode.p_symbolType
                if curSymbolType and curSymbolType == symbolType then
                    if symbolType == self.SYMBOL_BONUS_NORMAL then
                        --获取分数
                        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
                        score = score * lineBet
                        local strScore = util_formatCoins(score, 3)
                        local labCoin = symbolNode:getCcbProperty("m_lb_score")
                        if labCoin then
                            local symbolScore = labCoin:getString()
                            if strScore~=symbolScore then
                                --临时修复强制替换为正确的
                                labCoin:setString(strScore)
                                isError = true
                                logStr = logStr.." different symbolScore"
                                logStr = logStr.." symbolScore = "..symbolScore
                                logStr = logStr.." strScore = "..strScore
                                logStr = logStr.. " symbolType = "..tostring(symbolType).. " iRow = "..tostring(iRow).. " iCol = "..tostring(iCol).." | \n"
                            end
                        else
                            isError = true
                            logStr = logStr.." not labCoin"
                            logStr = logStr.." strScore = "..strScore
                            logStr = logStr.. " symbolType = "..tostring(symbolType).. " iRow = "..tostring(iRow).. " iCol = "..tostring(iCol).." | \n"
                        end
                    end
                else
                    isError = true
                    logStr = logStr.." not curSymbolType or different symbolType"
                    logStr = logStr.. " curSymbolType = "..tostring(curSymbolType)
                    logStr = logStr.. " symbolType = "..tostring(symbolType).. " iRow = "..tostring(iRow).. " iCol = "..tostring(iCol).." | \n"
                end
            else
                isError = true
                logStr = logStr.." not symbolNode "
                logStr = logStr.. " symbolType = "..tostring(symbolType).. " iRow = "..tostring(iRow).. " iCol = "..tostring(iCol).." | \n"
            end
        end
    end
    logStr = logStr.." checkSpinError end"
    self:pushSpinLog(logStr)
    return isError
end
--发送日志
function CodeGameScreenDwarfFairyMachine:sendSpinLog()
    local isError = self:checkSpinError()
    if not isError then
        return
    end
    if self.m_spinLog and gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendSpinErrorLog then
        gLobalSendDataManager:getLogGameLoad():sendSpinErrorLog(self.m_spinLog)
    end
end
-------------------------------------------日志发送 END

function CodeGameScreenDwarfFairyMachine:getScatterBeginCol( )
    local scatterNum = 0
    local iColIndex = nil
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol] 
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if not iColIndex then
                    iColIndex = iCol
                end
                scatterNum = scatterNum + 1
            end
        end
        
    end

    if iColIndex then
        return iColIndex,scatterNum
    else
        return self.m_iReelColumnNum,scatterNum
    end
    
     
end

function CodeGameScreenDwarfFairyMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    local isplay =  CodeGameScreenDwarfFairyMachine.super.isPlayTipAnima(self,matrixPosY, matrixPosX, node)
    local iColIndex,scatterNum = self:getScatterBeginCol( )
    if iColIndex ~= 3 then
        isplay = false
    end
    if node.p_cloumnIndex and node.p_cloumnIndex == self.m_iReelColumnNum then
        if scatterNum <= 2 then
            isplay = false
        end
    end
   
    return isplay
end

return CodeGameScreenDwarfFairyMachine