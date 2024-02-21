---
-- xcyy
-- 2018年5月28日
-- CodeGameScreenLightCherryMachine.lua
--
-- 玩法：
--
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local PublicConfig = require "LightCherryPublicConfig"
local BaseSlots = require "Levels.BaseSlots"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = require "Levels.BaseDialog"
local SendDataManager = require "network.SendDataManager"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenLightCherryMachine = class("CodeGameScreenLightCherryMachine", BaseSlotoManiaMachine)
--定义成员变量

--定义关卡特有的信号类型 以下为参考， 从TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1开始

CodeGameScreenLightCherryMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenLightCherryMachine.SYMBOL_MINI_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenLightCherryMachine.SYMBOL_MINOR_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenLightCherryMachine.SYMBOL_MAJOR_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenLightCherryMachine.SYMBOL_GRAND_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11

CodeGameScreenLightCherryMachine.SYMBOL_NOT_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenLightCherryMachine.SYMBOL_NOT_MINI_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
CodeGameScreenLightCherryMachine.SYMBOL_NOT_MINOR_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14
CodeGameScreenLightCherryMachine.SYMBOL_NOT_MAJOR_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15
CodeGameScreenLightCherryMachine.SYMBOL_NOT_GRAND_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 16


CodeGameScreenLightCherryMachine.m_freeSpinWildChange = GameEffect.EFFECT_SELF_EFFECT - 1 -- FreeSpin  过程中 wild 列变化
CodeGameScreenLightCherryMachine.m_respinOverAnimation = GameEffect.EFFECT_MEGAWIN + 1
CodeGameScreenLightCherryMachine.m_freeSpinOverAnimation = GameEffect.EFFECT_MEGAWIN + 2


CodeGameScreenLightCherryMachine.m_aFreeSpinWildArry = {} -- FreeSpin 过程中wild 个数
CodeGameScreenLightCherryMachine.m_aOffsetArry = {1, -1, 5, -5} -- 偏移量
CodeGameScreenLightCherryMachine.m_aNodeNameList = {"img_right", "img_left", "img_bottom", "img_top"}

CodeGameScreenLightCherryMachine.m_reSpinBar = nil --

CodeGameScreenLightCherryMachine.m_nMaxFreeSpinNum = 5

CodeGameScreenLightCherryMachine.m_choiceTriggerRespin = nil
CodeGameScreenLightCherryMachine.m_chooseRepin = nil

CodeGameScreenLightCherryMachine.m_bIsSelectCall = nil
CodeGameScreenLightCherryMachine.m_iSelectID = nil
CodeGameScreenLightCherryMachine.m_effectData = nil
CodeGameScreenLightCherryMachine.m_iLinkCherryNum = nil
CodeGameScreenLightCherryMachine.m_bIsTriggerRespin = nil
CodeGameScreenLightCherryMachine.m_vecCherryScore = nil
CodeGameScreenLightCherryMachine.m_bIsReconnect = nil
CodeGameScreenLightCherryMachine.m_vecUnlockCherry = nil
CodeGameScreenLightCherryMachine.m_vecCherryBars = nil
CodeGameScreenLightCherryMachine.m_vecJackPot = nil
CodeGameScreenLightCherryMachine.m_freeSpinStartEffect = nil
CodeGameScreenLightCherryMachine.m_freeSpinDelayTime = nil
CodeGameScreenLightCherryMachine.m_frameIndexNode = nil

CodeGameScreenLightCherryMachine.m_isChooseRespinFeature = nil -- 是否选择了respin玩法 , 这个是停留在界面层面的
CodeGameScreenLightCherryMachine.m_isChangeToFreespinBG = nil

local JACKPOT_TYPE = {
    "mini",
    "minor",
    "major",
    "grand"
}

local BONUS_SPINE_TAG       =       1001        --bonus小块上的spine

-- 构造函数
function CodeGameScreenLightCherryMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_aFreeSpinWildArry = {}
    self.m_adjacentCherryArry = {}
    self.m_schduleID = {}
    self.m_choiceTriggerRespin = false
    self.m_isChooseRespinFeature = false
    self.m_chooseRepin = false
    self.m_chooseFree = false
    self.m_bIsReconnect = false
    self.m_isChangeToFreespinBG = false
    self.m_isNoticeAni = false
    self.m_isScatterLongRun = false
    self.m_isLongRun = false
    self.m_inLineBonus = {}     --respin中在区域内的bonus小块
    self.m_playBigWinSayIndex = 1 --大赢预告播放音效的索引
    self.m_playFreeBigWinSayIndex = 1
    self.m_spinRestMusicBG = true
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
    self.m_publicConfig = PublicConfig
    self:initGame()
end

function CodeGameScreenLightCherryMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LightCherryConfig.csv", "LevelLightCherryConfig.lua")
    --启用jackpot
    self:BaseMania_jackpotEnable()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenLightCherryMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    self.m_isScatterLongRun = false
    self.m_isLongRun = false

    self.m_isNoticeAni = false

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName == "idleframe3" then
                local aniNode = symbolNode:checkLoadCCbNode()     
                local spine = aniNode.m_spineNode
                
                if spine then
                    util_spineMix(spine,symbolNode.m_currAnimName,"idleframe",0.1)
                    symbolNode:runAnim("idleframe")
                end
            end
        end
    end

    BaseSlotoManiaMachine.slotReelDown(self)
end

function CodeGameScreenLightCherryMachine:getBounsScatterDataZorder(symbolType)
    local symbolOrder = BaseSlots.getBounsScatterDataZorder(self, symbolType)

    if self:isFixSymbol(symbolType) == true then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
    end

    return symbolOrder
end

function CodeGameScreenLightCherryMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 5

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
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
    self:findChild("root"):setPosition(display.center)
end

function CodeGameScreenLightCherryMachine:initUI(data)
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode2:setScale(self.m_machineRootScale)

    self.m_schduleNode = cc.Node:create()
    self:addChild(self.m_schduleNode)

    self.m_jackPotBar = util_createView("CodeLightCherrySrc.LightCherryJackPotBar")
    self.m_csbOwner["jockpotNode"]:addChild(self.m_jackPotBar)
    self.m_jackPotBar:setScale(0.94)

    self.m_jackPotBar:setPositionY(234)
    self.m_jackPotBar:initMachine(self)

    self.m_reSpinBar = util_createView("CodeLightCherrySrc.LightCherryRespinBar")
    self:findChild("Respinbar"):addChild(self.m_reSpinBar)
    self.m_reSpinBar:setVisible(false)


    self.m_freeSpinStartEffect = util_createView("CodeLightCherrySrc.FreeSpinStartEffect")
    self:findChild("ef_za"):addChild(self.m_freeSpinStartEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_freeSpinStartEffect:setVisible(false)

    self.m_jackpotBG = util_createView("CodeLightCherrySrc.JackpotCherryBG")
    self.m_csbOwner["showJackpot"]:addChild(self.m_jackpotBG)
    self.m_jackpotBG:setVisible(false)

    self.m_jackpotBGEffect = util_createAnimation("LightCherry_fk.csb")
    self.m_csbOwner["showJackpot"]:addChild(self.m_jackpotBGEffect)
    self.m_jackpotBGEffect:setVisible(false)

    --隐藏粒子动效
    self:hideParticleOnReel()
end

--[[
    隐藏轮盘上的粒子
]]
function CodeGameScreenLightCherryMachine:hideParticleOnReel()
    for index = 1,5 do
        local parcitle = self:findChild("particle_"..index)
        if parcitle then
            parcitle:setVisible(false)
        end
    end
end

--[[
    播放轮盘上的粒子动效
]]
function CodeGameScreenLightCherryMachine:playParticleOnReel()
    for index = 1,5 do
        local parcitle = self:findChild("particle_"..index)
        if parcitle then
            parcitle:setVisible(true)
            parcitle:resetSystem()
        end
    end
end

function CodeGameScreenLightCherryMachine:initJackpotInfo(jackpotPool, lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLightCherryMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LightCherry"
end

function CodeGameScreenLightCherryMachine:getRespinView()
    return "CodeLightCherrySrc.LightCherryRespinView"
end

function CodeGameScreenLightCherryMachine:getRespinNode()
    return "CodeLightCherrySrc.LightCherryRespinNode"
end

---------- choseView
function CodeGameScreenLightCherryMachine:showFreatureChooseView(num, func)
    local view = util_createView("CodeLightCherrySrc.LightCherryFeatureChooseView",{
        machine = self,
        freeCount = num,
        func = function(chooseIndex)
            if type(func) == "function" then
                func(chooseIndex)
            end
        end
    })

    self:findChild("root"):addChild(view)
end

function CodeGameScreenLightCherryMachine:showJackpotWinView(jackpotType, coins, func)
    local view = util_createView("CodeLightCherrySrc.LightCherryJackpotWinView",{
        machine = self,
        winCoin = coins,
        jackpotType = jackpotType,
        func = function()
            if type(func) == "function" then
                func()
            end
        end
    })
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:findChild("root"):setPosition(display.center)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLightCherryMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if self:isFixSymbol(symbolType) then
        return "Socre_LightCherry_Bonus"
    end

    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenLightCherryMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MINI_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MINOR_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MAJOR_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_GRAND_SYMBOL, count = 2}

    return loadNode
end

function CodeGameScreenLightCherryMachine:getFormatCoins(scoreNum)
    if scoreNum == 0 then
        return ""
    end

    return util_formatCoins(scoreNum,3)

end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenLightCherryMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_NOT_FIX_SYMBOL or 
    symbolType == self.SYMBOL_MINI_SYMBOL or symbolType == self.SYMBOL_NOT_MINI_SYMBOL or 
    symbolType == self.SYMBOL_MINOR_SYMBOL or symbolType == self.SYMBOL_NOT_MINOR_SYMBOL or 
    symbolType == self.SYMBOL_MAJOR_SYMBOL or symbolType == self.SYMBOL_NOT_MAJOR_SYMBOL or 
    symbolType == self.SYMBOL_GRAND_SYMBOL or symbolType == self.SYMBOL_NOT_GRAND_SYMBOL then
        return true
    end
    
    return false
end

--新滚动使用
function CodeGameScreenLightCherryMachine:updateReelGridNode(symbolNode)
    if not tolua.isnull(symbolNode) and symbolNode.p_symbolType then
        local symbolType = symbolNode.p_symbolType
        if self:isFixSymbol(symbolType) then
            self:setSpecialNodeScore(symbolNode)
        end

    end
end

-- 给respin小块进行赋值
function CodeGameScreenLightCherryMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score,jackpotType = 0,""
    if symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score,jackpotType = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),symbolNode.p_symbolType) --获取分数（网络数据）
    else
        score,jackpotType =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    self:setSpineOnBonusSymbol(symbolNode,jackpotType)

    if not tolua.isnull(symbolNode) and symbolNode.p_symbolType then
        local storedIcons = self.m_runSpinResultData.p_storedIcons

        --respin里落地的bonus上没有钱
        if self:getCurrSpinMode() == RESPIN_MODE and not self.m_bIsTriggerRespin then
            score,jackpotType = 0,""
        end

        local symbolType = symbolNode.p_symbolType
        local m_lb_num = symbolNode:getCcbProperty("m_lb_num")
        if m_lb_num then
            m_lb_num:setVisible(jackpotType == "")
            local score = self:getFormatCoins(score)
            m_lb_num:setString(score)
        end

        symbolNode:getCcbProperty("jackpot_words"):setVisible(true)
        --设置jackpot显示
        for index = 1,#JACKPOT_TYPE do
            local sp_jackpot = symbolNode:getCcbProperty("jackpot_"..JACKPOT_TYPE[index])
            if sp_jackpot then
                sp_jackpot:setVisible(jackpotType == JACKPOT_TYPE[index])
            end
        end
    end
end

--[[
    设置bonus小块上的spine动画
]]
function CodeGameScreenLightCherryMachine:setSpineOnBonusSymbol(symbolNode,jackpotType)
    local Node_spine = symbolNode:getCcbProperty("Node_spine")
    if not Node_spine then
        return
    end
    Node_spine:removeAllChildren()
    if symbolNode.m_isLastSymbol == true then 
        if jackpotType == "" then
            local spine = util_spineCreate("Socre_LightCherry_Cherry",true,true)
            Node_spine:addChild(spine)
            spine:setTag(BONUS_SPINE_TAG)
        else --jackpot类型用金色的樱桃
            local spine = util_spineCreate("Socre_LightCherry_Cherry2",true,true)
            Node_spine:addChild(spine)
            spine:setTag(BONUS_SPINE_TAG)
        end
    else
        if jackpotType == "" then
            local sp = display.newSprite("#Symbol/Socre_LightCherry_Cherry.png")
            if sp then
                sp:setScale(0.5)
                Node_spine:addChild(sp)
            end
        else
            local sp = display.newSprite("#Symbol/Socre_LightCherry_Cherry2.png")
            if sp then
                sp:setScale(0.5)
                Node_spine:addChild(sp)
            end
        end
    end
end

--[[
    获取bonus上的spine
]]
function CodeGameScreenLightCherryMachine:getSpineOnBonus(symbolNode)
    local Node_spine = symbolNode:getCcbProperty("Node_spine")
    if not Node_spine then
        return
    end

    local spine = Node_spine:getChildByTag(BONUS_SPINE_TAG)
    return spine
end

function CodeGameScreenLightCherryMachine:getJackpotTypeBySymbolType(symbolType)
    local jackpotType = ""
    if symbolType == self.SYMBOL_MINI_SYMBOL or symbolType == self.SYMBOL_NOT_MINI_SYMBOL then
        jackpotType = "mini"
    end
    if symbolType == self.SYMBOL_MINOR_SYMBOL or symbolType == self.SYMBOL_NOT_MINOR_SYMBOL then
        jackpotType = "minor"
    end
    if symbolType == self.SYMBOL_MAJOR_SYMBOL or symbolType == self.SYMBOL_NOT_MAJOR_SYMBOL then
        jackpotType = "major"
    end
    if symbolType == self.SYMBOL_GRAND_SYMBOL or symbolType == self.SYMBOL_NOT_GRAND_SYMBOL then
        jackpotType = "grand"
    end

    return jackpotType
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenLightCherryMachine:getReSpinSymbolScore(id,symbolType)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if not storedIcons then
        return self:randomDownRespinSymbolScore(symbolType)
    end
    local jackpotType = self:getJackpotTypeBySymbolType(symbolType)
    
    
    local multi = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            multi = values[2]
        end
    end

    if multi == nil then
       return 0,jackpotType
    end

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score,jackpotType
end

--[[
    随机bonus分数
]]
function CodeGameScreenLightCherryMachine:randomDownRespinSymbolScore(symbolType)
    if self:getCurrSpinMode() == RESPIN_MODE then
       return 0,"" 
    end
    local score = 0
    local jackpotType = self:getJackpotTypeBySymbolType(symbolType)

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local multi = self.m_configData:getFixSymbolPro()
    score = multi * lineBet


    return score,jackpotType
end

--[[
    回弹动作
]]
function CodeGameScreenLightCherryMachine:getDownBackAction(symbolNode, parentData)
    local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, index)

    local moveTime = self.m_configData.p_reelResTime
    if self:getGameSpinStage() == QUICK_RUN then
        moveTime = 0.3
    end

    local back = cc.MoveTo:create(moveTime, tarSpPos)


    local speedActionTable = {}
    local dis = self.m_configData.p_reelResDis
    local speedStart = parentData.moveSpeed
    local preSpeed = speedStart / 118
    local timeDown = moveTime
    if self:getGameSpinStage() ~= QUICK_RUN then
        for i = 1, 10 do
            speedStart = speedStart - preSpeed * (11 - i) * 2
            local moveDis = dis / 10
            local time = moveDis / speedStart
            timeDown = timeDown + time
            local moveBy = cc.MoveBy:create(time, cc.p(0, -moveDis))
            speedActionTable[#speedActionTable + 1] = moveBy
        end
    end

    speedActionTable[#speedActionTable + 1] = back
    return speedActionTable, timeDown
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenLightCherryMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
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
                    local newSpeedActionTable, addTime = self:getDownBackAction(_slotNode, self.m_slotParents[_slotNode.p_cloumnIndex])

                    local seq = cc.Sequence:create(newSpeedActionTable)
                    _slotNode:runAction(seq)

                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                if self:isFixSymbol(_slotNode.p_symbolType) then
                    self:playBonusBulingAni(_slotNode,function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end)
                else
                    --2.播落地动画
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
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenLightCherryMachine:symbolBulingEndCallBack(symbolNode)
    if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self.m_isLongRun and self.m_isScatterLongRun then
            local aniNode = symbolNode:checkLoadCCbNode()     
            local spine = aniNode.m_spineNode
            
            if symbolNode.m_currAnimName ~= "idleframe3" then
                if spine then
                    util_spineMix(spine,symbolNode.m_currAnimName,"idleframe3",0.1)
                    symbolNode:runAnim("idleframe3",true)
                end
            end
        end
    end
end

--[[
    bonus落地动画
]]
function CodeGameScreenLightCherryMachine:playBonusBulingAni(symbolNode,func)
    self:playBonusAni(symbolNode,"buling",false,func)
end

--[[
    bonus图标播放动画
]]
function CodeGameScreenLightCherryMachine:playBonusAni(symbolNode,aniName,isLoop,func)
    if tolua.isnull(symbolNode) then
        if type(func) == "function" then
            func()
        end
        return
    end
    symbolNode:runAnim(aniName,isLoop,func)

    local spine = self:getSpineOnBonus(symbolNode)
    if spine then
        --动作混合
        if spine.m_curAnimName and spine.m_curAnimName == aniName and aniName == "idleframe2" then
            return
        end
        util_spinePlay(spine,aniName,isLoop)
        spine.m_curAnimName = aniName
    end
end

--[[
    播放idle动画
]]
function CodeGameScreenLightCherryMachine:playBonusIdleAniInRespin()
    local delayTime = 0
    for k,data in pairs(self.m_inLineBonus) do
        local spine = self:getSpineOnBonus(data.node)
        if spine then
            util_spinePlay(spine,"idleframe2")
            spine.m_curAnimName = "idleframe2"
            local aniTime = spine:getAnimationDurationTime("idleframe2")
            if aniTime > delayTime then
                delayTime = aniTime
            end
        end
    end

    performWithDelay(self.m_schduleNode,function()
        self:playBonusIdleAniInRespin()
    end,delayTime)
end

--[[
    停止idle定时器
]]
function CodeGameScreenLightCherryMachine:stopBonusIdleSchdule()
    self.m_schduleNode:stopAllActions()
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenLightCherryMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if self:checkPlayScatterBuling(_slotNode.p_cloumnIndex) then
                    return true
                end
            elseif self:isFixSymbol(_slotNode.p_symbolType) then
                return self:checkPlayBonusBuling(_slotNode.p_cloumnIndex)
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return false
            end
        end
    end

    return false
end

--[[
    检测scatter是否需要播落地
]]
function CodeGameScreenLightCherryMachine:checkPlayScatterBuling(colIndex)
    if colIndex <= 2 then
        return true
    end

    local reels = self.m_runSpinResultData.p_reels

    local count = 0
    for iCol = 1,colIndex do
        for iRow = 1,#reels do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                count = count + 1
                break
            end
        end
    end
    

    if count == 2 and colIndex == 3 then
        return true
    elseif count >= 3 then
        return true
    end

    return false
end

--[[
    检测bonus是否需要播落地(在同一行上有3个以上bonus才触发玩法)
]]
function CodeGameScreenLightCherryMachine:checkPlayBonusBuling(colIndex)
    
    if colIndex <= 3 then
        return true
    end
    local reels = self.m_runSpinResultData.p_reels

    local maxCount = 0
    for iRow = 1,#reels do
        local count = 0
        for iCol = 1,colIndex do
            if self:isFixSymbol(reels[iRow][iCol]) then
                count = count + 1
            end
        end

        if maxCount < count then
            maxCount = count
        end
    end

    if maxCount == 1 and colIndex == 4 then
        return false
    elseif maxCount <= 2 and colIndex == 5 then
        return false
    end

    return true
end

-- symbolType
function CodeGameScreenLightCherryMachine:isCherrySymbolType(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_MINI_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_MINOR_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_MAJOR_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_GRAND_SYMBOL then
        return true
    end

    return false
end

function CodeGameScreenLightCherryMachine:isJackpotCherrySymbolType(symbolType)
    if symbolType == self.SYMBOL_MINI_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_MINOR_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_MAJOR_SYMBOL then
        return true
    end

    if symbolType == self.SYMBOL_GRAND_SYMBOL then
        return true
    end

    return false
end

function CodeGameScreenLightCherryMachine:getSpinAction()
    --选择玩法时 置为repsin action  服务器不扣除bet
    if self.m_choiceTriggerRespin == true then
        self.m_choiceTriggerRespin = false
        return RESPIN
    else
        return BaseMachine.getSpinAction(self)
    end
end

function CodeGameScreenLightCherryMachine:checkCherryInLinks(index)
    if index < 0 or index > 14 then
        return false
    end
    for i = 1, #self.m_runSpinResultData.p_rsExtraData.links, 1 do
        local link = self.m_runSpinResultData.p_rsExtraData.links[i]
        if #link >= 3 then
            for j = 1, #link, 1 do
                if link[j] == index then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenLightCherryMachine:animationBar(symbolNode, index, prevDirection, vecAnimationBar)
    if prevDirection == 0 or prevDirection == -1 then
        local topBar = symbolNode:getCcbProperty("img_top")
        vecAnimationBar[#vecAnimationBar + 1] = topBar
        if symbolNode.p_cloumnIndex == 5 or (symbolNode.p_cloumnIndex < 5 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)) == false) then
            local rightBar = symbolNode:getCcbProperty("img_right")
            vecAnimationBar[#vecAnimationBar + 1] = rightBar
            if symbolNode.p_rowIndex == 0 or (symbolNode.p_rowIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)) == false) then
                local bottomBar = symbolNode:getCcbProperty("img_bottom")
                vecAnimationBar[#vecAnimationBar + 1] = bottomBar
                if symbolNode.p_rowIndex > 0 and symbolNode.p_cloumnIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)
                    self:animationBar(nextNode, index, -5, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)
                    self:animationBar(nextNode, index, 1, vecAnimationBar)
                end
            else
                if symbolNode.p_rowIndex > 0 and symbolNode.p_cloumnIndex < 5 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)
                    self:animationBar(nextNode, index, -1, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)
                    self:animationBar(nextNode, index, -5, vecAnimationBar)
                end
            end
        else
            if symbolNode.p_rowIndex < 3 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)
                self:animationBar(nextNode, index, 5, vecAnimationBar)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)
                self:animationBar(nextNode, index, -1, vecAnimationBar)
            end
        end
    elseif prevDirection == -5 then
        local rightBar = symbolNode:getCcbProperty("img_right")
        vecAnimationBar[#vecAnimationBar + 1] = rightBar
        if symbolNode.p_rowIndex == 0 or (symbolNode.p_rowIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)) == false) then
            local bottomBar = symbolNode:getCcbProperty("img_bottom")
            vecAnimationBar[#vecAnimationBar + 1] = bottomBar

            if symbolNode.p_cloumnIndex == 0 or (symbolNode.p_cloumnIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)) == false) then
                local leftBar = symbolNode:getCcbProperty("img_left")
                vecAnimationBar[#vecAnimationBar + 1] = leftBar
                if symbolNode.p_rowIndex < 3 and symbolNode.p_cloumnIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)
                    self:animationBar(nextNode, index, 1, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)
                    self:animationBar(nextNode, index, 5, vecAnimationBar)
                end
            else
                if symbolNode.p_rowIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)
                    self:animationBar(nextNode, index, -5, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)
                    self:animationBar(nextNode, index, 1, vecAnimationBar)
                end
            end
        else
            if symbolNode.p_cloumnIndex < 5 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)
                self:animationBar(nextNode, index, -1, vecAnimationBar)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)
                self:animationBar(nextNode, index, -5, vecAnimationBar)
            end
        end
    elseif prevDirection == 1 then
        local bottomBar = symbolNode:getCcbProperty("img_bottom")
        vecAnimationBar[#vecAnimationBar + 1] = bottomBar

        if symbolNode.p_cloumnIndex == 0 or (symbolNode.p_cloumnIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)) == false) then
            local leftBar = symbolNode:getCcbProperty("img_left")
            vecAnimationBar[#vecAnimationBar + 1] = leftBar
            local nodeID = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            if nodeID == index then
                return
            end
            if symbolNode.p_rowIndex == 3 or (symbolNode.p_rowIndex < 3 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)) == false) then
                local topBar = symbolNode:getCcbProperty("img_top")
                vecAnimationBar[#vecAnimationBar + 1] = topBar
                if symbolNode.p_rowIndex < 3 and symbolNode.p_cloumnIndex < 5 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)
                    self:animationBar(nextNode, index, 5, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)
                    self:animationBar(nextNode, index, -1, vecAnimationBar)
                end
            else
                if symbolNode.p_cloumnIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)
                    self:animationBar(nextNode, index, 1, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)
                    self:animationBar(nextNode, index, 5, vecAnimationBar)
                end
            end
        else
            if symbolNode.p_rowIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex - 1)
                self:animationBar(nextNode, index, -5, vecAnimationBar)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex - 1)
                self:animationBar(nextNode, index, 1, vecAnimationBar)
            end
        end
    elseif prevDirection == 5 then
        local leftBar = symbolNode:getCcbProperty("img_left")
        vecAnimationBar[#vecAnimationBar + 1] = leftBar

        local nodeID = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        if nodeID == index then
            return
        end

        if symbolNode.p_rowIndex == 3 or (symbolNode.p_rowIndex < 3 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)) == false) then
            local topBar = symbolNode:getCcbProperty("img_top")
            vecAnimationBar[#vecAnimationBar + 1] = topBar
            if symbolNode.p_cloumnIndex == 5 or (symbolNode.p_cloumnIndex < 5 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)) == false) then
                local rightBar = symbolNode:getCcbProperty("img_right")
                vecAnimationBar[#vecAnimationBar + 1] = rightBar
                if symbolNode.p_cloumnIndex < 5 and symbolNode.p_rowIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex + 1)
                    self:animationBar(nextNode, index, -1, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex - 1, symbolNode.p_cloumnIndex)
                    self:animationBar(nextNode, index, -5, vecAnimationBar)
                end
            else
                if symbolNode.p_rowIndex < 3 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)) then
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex + 1)
                    self:animationBar(nextNode, index, 5, vecAnimationBar)
                else
                    local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex + 1)
                    self:animationBar(nextNode, index, -1, vecAnimationBar)
                end
            end
        else
            if symbolNode.p_cloumnIndex > 0 and self:isCherrySymbolType(self:getMatrixPosSymbolType(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)) then
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex - 1)
                self:animationBar(nextNode, index, 1, vecAnimationBar)
            else
                local nextNode = self.m_respinView:getRespinEndNode(symbolNode.p_rowIndex + 1, symbolNode.p_cloumnIndex)
                self:animationBar(nextNode, index, 5, vecAnimationBar)
            end
        end
    end
end

function CodeGameScreenLightCherryMachine:addCherryBG(vecSymbolNodes)
    for i = 1, #vecSymbolNodes, 1 do
        local symbolNode = vecSymbolNodes[i]
        local oldBG = symbolNode.node:getCcbProperty("node_bg")
        local newBG = display.newSprite("#ui2019/2019cherry_reel_cherry_1.png")
        self.m_respinView:addChild(newBG, 1000)
        newBG:setPosition(symbolNode.node:getPosition())
        newBG:setScaleX(oldBG:getScaleX())
        newBG:setScaleY(oldBG:getScaleY())
    end
    self:hideCherryBar(vecSymbolNodes)
end

function CodeGameScreenLightCherryMachine:hideCherryBar(vecSymbolNodes)
    for i = 1, #vecSymbolNodes, 1 do
        local symbolNode = vecSymbolNodes[i]
        for j = 1, #self.m_aNodeNameList, 1 do
            local bar = symbolNode.node:getCcbProperty(self.m_aNodeNameList[j])
            bar:setVisible(false)
            if bar:getChildByName("lock") then
                bar:getChildByName("lock"):removeFromParent(true)
            end
        end
    end
end

function CodeGameScreenLightCherryMachine:showCherryBar(vecSymbolNodes)
    for i = 1, #vecSymbolNodes, 1 do
        local symbolNode = vecSymbolNodes[i]
        for j = 1, #self.m_aOffsetArry, 1 do
            if self:checkCherryInLinks(symbolNode.index + self.m_aOffsetArry[j]) then
                symbolNode.node:getCcbProperty(self.m_aNodeNameList[j]):setVisible(false)
            else
                symbolNode.node:getCcbProperty(self.m_aNodeNameList[j]):setVisible(true)
            end
        end
        if symbolNode.index % 5 == 0 then
            symbolNode.node:getCcbProperty("img_left"):setVisible(true)
        end
        if symbolNode.index % 5 == 4 then
            symbolNode.node:getCcbProperty("img_right"):setVisible(true)
        end
    end
end

function CodeGameScreenLightCherryMachine:getLinkCherryData()
    local vecSymbolNodes = {}
    local vecLinkCherry = {}
    local iLineCherry = 0
    for i = 1, #self.m_runSpinResultData.p_rsExtraData.links, 1 do
        local link = self.m_runSpinResultData.p_rsExtraData.links[i]
        local linkCherry = {}
        if #link >= 3 then
            iLineCherry = iLineCherry + #link
            for j = 1, #link, 1 do
                local pos = self:getRowAndColByPos(link[j])
                local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                if not tolua.isnull(symbolNode)  then
                    local stcSymbol = {}
                    stcSymbol.index = link[j]
                    stcSymbol.node = symbolNode
                    stcSymbol.score = self:getReSpinSymbolScore(link[j],symbolNode.p_symbolType)
                    vecSymbolNodes[#vecSymbolNodes + 1] = stcSymbol
                    linkCherry[#linkCherry + 1] = stcSymbol
                end
                
            end
        end
        if #linkCherry > 0 then
            table.sort(
                linkCherry,
                function(a, b)
                    return a.index < b.index
                end
            )
            vecLinkCherry[#vecLinkCherry + 1] = linkCherry
        end
    end
    table.sort(
        vecSymbolNodes,
        function(a, b)
            return a.index < b.index
        end
    )
    return vecSymbolNodes, vecLinkCherry, iLineCherry
end

function CodeGameScreenLightCherryMachine:getAnimationBars(vecLinkCherry)
    local vecBars = {}
    local iMaxLinkNum = 0
    for i = 1, #vecLinkCherry, 1 do
        local vecAnimationBar = {}
        self:animationBar(vecLinkCherry[i][1].node, vecLinkCherry[i][1].index, 0, vecAnimationBar)
        vecBars[#vecBars + 1] = vecAnimationBar
        iMaxLinkNum = math.max(iMaxLinkNum, #vecAnimationBar)
    end
    return vecBars, iMaxLinkNum
end

function CodeGameScreenLightCherryMachine:playCherryAnimation(func)
    if self.m_bIsTriggerRespin then
        self:getLinkCherryNum()
        self.m_bIsTriggerRespin = false
        if type(func) == "function" then
            func()
        end
    else
        local vecSymbolNodes, vecLinkCherry, iLineCherry = self:getLinkCherryData()
        --轮盘是否集满
        local isFull = #vecSymbolNodes == 15
        if iLineCherry > self.m_iLinkCherryNum then
            local betValue = globalData.slotRunData:getCurTotalBet()
            local vecBars, iMaxLinkNum = self:getAnimationBars(vecLinkCherry)
            self:addCherryBG(vecSymbolNodes)

            self:showNextLockArea(vecBars,1,function()
                self.m_inLineBonus = vecSymbolNodes
                self:showCherryBar(vecSymbolNodes)
                --轮盘集满
                if isFull then

                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_jiman)
                    --轮盘震动
                    self:playParticleOnReel()
                    self:runCsbAction("actionframe",false,function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_jiman_buling)
                        self:addNextTimeCoins(vecSymbolNodes,1,3,function()
                            self:delayCallBack(0.5,func)
                        end)
                    end)

                else
                    self:addNextTimeCoins(vecSymbolNodes,1,1,function()
                        self:delayCallBack(0.5,func)
                    end)
                end

                self.m_iLinkCherryNum = iLineCherry
            end)

        else
            if type(func) == "function" then
                func()
            end
        end
    end
end


--[[
    加钱动画
]]
function CodeGameScreenLightCherryMachine:addNextTimeCoins(vecSymbolNodes,curIndex,maxIndex,func)
    if curIndex > maxIndex then
        if type(func) == "function" then
            func()
        end
        return
    end
    for index = 1, #vecSymbolNodes, 1 do
        local symbolNode = vecSymbolNodes[index].node
        local labCoin = symbolNode:getCcbProperty("m_lb_num")
        local score = vecSymbolNodes[index].score or 0
        score = score / maxIndex * curIndex
        if labCoin ~= nil and not tolua.isnull(symbolNode) then
            symbolNode:runAnim("bianzi",false,function()
                
            end)

            self:delayCallBack(15 / 60,function()
                labCoin:setString(self:getFormatCoins(score))
            end)
        end
    end

    self:delayCallBack(35 / 60,function()
        self:addNextTimeCoins(vecSymbolNodes,curIndex + 1,maxIndex,func)
    end)
end

--[[
    显示锁定区域动画
]]
function CodeGameScreenLightCherryMachine:showNextLockArea(vecBars,index,func)
    if index > #vecBars then
        if type(func) == "function" then
            func()
        end
        return
    end

    local bars = vecBars[index]
    if bars then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_lock)
        self:showNextLockLine(bars,1,function()
            local lock = util_createAnimation("Socre_LightCherry_lock.csb")
            bars[#bars]:addChild(lock)
            lock:runCsbAction("show")
            lock:setName("lock")
            lock:setPosition(8, bars[#bars]:getContentSize().height - 8)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_lock_in)

            self:showNextLockArea(vecBars,index + 1,func)
        end)
    else
        self:showNextLockArea(vecBars,index + 1,func)
    end

    
end

--[[
    显示下条锁定线
]]
function CodeGameScreenLightCherryMachine:showNextLockLine(bars,index,func)
    if index > #bars then
        if type(func) == "function" then
            func()
        end
        return
    end
    if bars[index] then
        bars[index]:setVisible(true)
    end
    self:delayCallBack(0.05,function()
        self:showNextLockLine(bars,index + 1,func)
    end)
end

function CodeGameScreenLightCherryMachine:reSpinReelDown(addNode)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self.m_reSpinBar:showCompleteNode(true)
        self:playCherryAnimation(function()

            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

            --quest
            self:updateQuestBonusRespinEffectData()

            --结束
            self:reSpinEndAction()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
            self.m_isWaitingNetworkData = false
        end)
    else
        
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self:runNextReSpinReel(true)
    end
end

--[[
    获取连在一起的樱桃数量
]]
function CodeGameScreenLightCherryMachine:getLinkCherryNum()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if not rsExtraData or not rsExtraData.links then
        return
    end
    local iLineCherry = 0
    for index = 1, #rsExtraData.links do
        local link = rsExtraData.links[index]
        if #link >= 3 then
            iLineCherry = iLineCherry + #link
        end
    end
    self.m_iLinkCherryNum = iLineCherry
end

function CodeGameScreenLightCherryMachine:runNextReSpinReel(_isLightCherryStates)
    
    self:playCherryAnimation(
        function()
            
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            CodeGameScreenLightCherryMachine.super.runNextReSpinReel(self)

            if _isLightCherryStates then
                self:setGameSpinStage(STOP_RUN)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    )
end

---respinFeature
function CodeGameScreenLightCherryMachine:getRespinFeature(...)
    if self.m_reSpinCurCount == 3 then
        return {0, 3}
    end
    return {0}
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLightCherryMachine:MachineRule_SpinBtnCall()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:setMaxMusicBGVolume()

    return false
end

function CodeGameScreenLightCherryMachine:beginReel()
    if self.m_chooseFree then
        self.m_chooseFree = false
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_cai_down)
        self.m_freeSpinStartEffect:setVisible(true)
        self.m_freeSpinStartEffect:runAction()
        self:runCsbAction("actionframe1",true)
    end
    CodeGameScreenLightCherryMachine.super.beginReel(self)
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLightCherryMachine:addSelfEffect()
    for i = #self.m_aFreeSpinWildArry, 1, -1 do
        table.remove(self.m_aFreeSpinWildArry, i)
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then --and #self.m_allLockNodeReelPos < 6
        for iCol = 1, self.m_iReelColumnNum do --列
            local tempRow = nil
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    tempRow = iRow
                else
                    break
                end
            end
            if tempRow ~= nil and tempRow ~= 1 then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            end

            tempRow = nil
            for iRow = 1, self.m_iReelRowNum, 1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    tempRow = iRow
                else
                    break
                end
            end

            if tempRow ~= nil and tempRow ~= self.m_iReelRowNum then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "up"}
            end
        end
    end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and #self.m_aFreeSpinWildArry > 0 then
        local wildChangeEffect = GameEffectData.new()
        wildChangeEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_selfEffectType = self.m_freeSpinWildChange
        self.m_gameEffects[#self.m_gameEffects + 1] = wildChangeEffect
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLightCherryMachine:MachineRule_playSelfEffect(effectData)
    -- freeSpin wild 列 变化
    if effectData.p_selfEffectType == self.m_freeSpinWildChange then
        self:freeSpinWildChange(effectData)
    end
    return true
end

-- freeSpin wild change
function CodeGameScreenLightCherryMachine:freeSpinWildChange(effectData)
    local delayTime = 0
    for i = 1, #self.m_aFreeSpinWildArry, 1 do
        local temp = self.m_aFreeSpinWildArry[i]
        local iRow = temp.row
        local effectAnimation = "xia200"
        if temp.direction == "up" then
            iRow = temp.row + 1 - 3
            effectAnimation = "shang"
        end
        local iTempRow = {} --隐藏小块避免穿帮
        if iRow == -1 then
            iTempRow[1] = 2
            iTempRow[2] = 3
        elseif iRow == 0 then
            iTempRow[1] = 3
        elseif iRow == 2 then
            iTempRow[1] = 1
        elseif iRow == 3 then
            iTempRow[1] = 1
            iTempRow[2] = 2
        end
        local children = self:getReelParent(temp.col):getChildren()
        local node = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iRow, SYMBOL_NODE_TAG))
        --为什么屏幕外的小块还能移动
        if node then
            node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100)
            node:hideBigSymbolClip()
            node.p_rowIndex = 1
            local distance = (1 - iRow) * self.m_SlotNodeH
            local runTime = self.m_SlotNodeH / 300
             --math.abs( distance ) / 500
            delayTime = math.max(delayTime, runTime)

            local seq =cc.Sequence:create(cc.MoveBy:create(runTime, cc.p(0, distance)))

            local effect = util_createAnimation("Socre_LightCherry_Wild2_Eff.csb")
            effect.p_IsMask = true
            effect:runCsbAction(effectAnimation,false,function(  )
                effect:removeFromParent(true)
            end)
            self:getReelParent(temp.col):addChild(effect, 10000)
            effect:setPosition(self.m_SlotNodeW, self.m_SlotNodeH * 0.5)
          
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
            node:runAction(seq)
            node.m_bInLine = true
            local linePos = {}
            for i = 1, 3 do
                linePos[#linePos + 1] = {
                    iX = i,
                    iY = temp.col
                }
            end

            node:setLinePos(linePos)
        end
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_big_symbol_move)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        effectData.p_isPlay = true
        self:playGameEffect()

        waitNode:removeFromParent()
    end,delayTime + 0.1)
    
   
end

---
-- 播放freespin动画触发
-- 改变背景动画等

function CodeGameScreenLightCherryMachine:levelFreeSpinEffectChange()
    if self.m_isChangeToFreespinBG == false then
        self:runCsbAction("changefreespin")
        gLobalNoticManager:postNotification(
            ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,
            {
                "changeFreespin",
                false,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"freespin", true})
                end
            }
        )
        self.m_isChangeToFreespinBG = true
        
    end
end

function CodeGameScreenLightCherryMachine:levelFreeSpinOverChangeBG()
    self:runCsbAction("changeNomal")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "changeNomal")
    self.m_isChangeToFreespinBG = false
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenLightCherryMachine:levelFreeSpinOverChangeEffect(content)
    self.m_jackPotBar:toAction("freespin_hide")
end

function CodeGameScreenLightCherryMachine:showEffect_Bonus(effectData)
    if self.m_runSpinResultData.p_selfMakeData then
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_FREESPIN.times
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_iRespinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_RESPIN.times
        end
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            break
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_scatter_trigger_free)
    end

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    self:showBonusAndScatterLineTip(TAG_SYMBOL_TYPE.SYMBOL_SCATTER,function()
        -- gLobalSoundManager:stopAllAuido() -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
        self:showFreeSpinView(effectData)
    end)
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    return true
end

---
-- 显示free spin
function CodeGameScreenLightCherryMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:stopLinesWinSound()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            break
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_scatter_trigger_free)
    end

    self:showBonusAndScatterLineTip(TAG_SYMBOL_TYPE.SYMBOL_SCATTER,function()
        self:showFreeSpinView(effectData)
    end)
        
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenLightCherryMachine:showBonusAndScatterLineTip(symbolType, func)
    local animTime = 0
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == symbolType then
                --将图标提层到clipparent上
                self:changeSymbolToClipParent(symbolNode)
                symbolNode:runAnim("actionframe")
                animTime = util_max(animTime, symbolNode:getAniamDurationByName("actionframe"))
            end
        end
    end

    self:delayCallBack(animTime,func)
end

function CodeGameScreenLightCherryMachine:sendData(index)
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end
--[[
    @desc: 继承重写点击spin后扣钱的逻辑，
    time:2019-04-28 14:56:09
    --@betCoin: 
    @return:
]]
function CodeGameScreenLightCherryMachine:callSpinTakeOffBetCoin(betCoin)
    if self.m_isChooseRespinFeature == false then
        BaseMachine.callSpinTakeOffBetCoin(self, betCoin)
    else
        -- 如果本次界面选择了 respin的玩法则不做扣钱处理
    end
    self.m_isChooseRespinFeature = false
end

function CodeGameScreenLightCherryMachine:showFreeSpinView(effectData)
    -- 界面选择回调
    local function chooseCallBack(index)

        self.m_iSelectID = index
        if self.m_iSelectID == 1 then --触发了repin玩法， 则本次在进行滚动时并不扣钱
            self.m_isChooseRespinFeature = true
        end

        if self.m_iSelectID == 1 then --  clock feature
            -- self:normalSpinBtnCall()
            self.m_iFreeSpinTimes = 0
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0
            self.m_bProduceSlots_InFreeSpin = false
            self.m_choiceTriggerRespin = true
            self.m_chooseRepin = true
            self.m_chooseRepinGame = true --选择respin
            self.m_bIsSelectCall = false

            effectData.p_isPlay = true
            self:playGameEffect()
        else
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            self:changeSceneToFree(function()
                self.m_jackPotBar:toAction("freespin_show")
                self:levelFreeSpinEffectChange()
            end,function()
                
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
                self.m_chooseFree = true
                
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            end, true)
        end
    end

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        self:showFreatureChooseView(self.m_iFreeSpinTimes, chooseCallBack)
    else
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        local view = self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            true
        )
        view:findChild("root"):setPosition(display.center)
        view:findChild("root"):setScale(self.m_machineRootScale)

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_free_more)
    end
end

function CodeGameScreenLightCherryMachine:updateNetWorkData()
    CodeGameScreenLightCherryMachine.super.updateNetWorkData(self)
end

----------------------------预告中奖----------------------------------------

function CodeGameScreenLightCherryMachine:getFeatureGameTipChance()
    local isNotice = math.random(1,100) <= 70
    return isNotice
end

function CodeGameScreenLightCherryMachine:dealSmallReelsSpinStates()
    if not self.m_isNoticeAni then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
    
end

-- 播放预告中奖统一接口
function CodeGameScreenLightCherryMachine:showFeatureGameTip(_func)
    if self.m_freeSpinStartEffect:isVisible() then
        self:delayCallBack(1,function()
            self.m_freeSpinStartEffect:setVisible(false)
            self:runCsbAction("freespin")
            if type(_func) == "function" then
                _func()
            end
        end)
        return
    end

    local features = self.m_runSpinResultData.p_features or {}
    local isTriggerFs = false
    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            isTriggerFs = true
            break
        end
    end
    if isTriggerFs then

        -- 出现预告动画概率70%
        local isNotice = self:getFeatureGameTipChance()
       
        if isNotice then
            --播放预告中奖动画
            self:playFeatureNoticeAni(function()
                if type(_func) == "function" then
                    _func()
                end
            end)
        else
            if type(_func) == "function" then
                _func()
            end
        end
        
    else
        if type(_func) == "function" then
            _func()
        end
    end
end

--[[
    播放预告中奖动画
]]
function CodeGameScreenLightCherryMachine:playFeatureNoticeAni(func)
    --获取父节点
    local midReel = self:findChild("sp_reel_2")
    local size = midReel:getContentSize()
    local reelPos = cc.p(midReel:getPosition())
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(reelPos.x + size.width / 2,reelPos.y + size.height / 2))
    local pos = self.m_effectNode:convertToNodeSpace(worldPos)


    --检测是否存在预告中奖资源
    local aniName = "LightCherry_yugao.csb"

    self.m_isNoticeAni = true
    local csbAni = util_createAnimation(aniName)
    
    self.m_effectNode:addChild(csbAni)
    csbAni:setPosition(pos)
    csbAni:runCsbAction("actionframe",false,function()
        csbAni:removeFromParent()
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_notice)

    --动效执行时间
    local aniTime = util_csbGetAnimTimes(csbAni.m_csbAct,"actionframe")

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end
---------------------------------------预告中奖  end--------------------------------------------------

function CodeGameScreenLightCherryMachine:spinResultCallFun(param)
    CodeGameScreenLightCherryMachine.super.spinResultCallFun(self, param)
end

--[[
    过场动画(free)
]]
function CodeGameScreenLightCherryMachine:changeSceneToFree(keyFunc,endFunc,isBaseToFree)
    if isBaseToFree then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_base_to_free_guochang)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_free_to_base_guochang)
    end

    local spine = util_spineCreate("LightCherry_GC1",true,true)
    self.m_effectNode:addChild(spine)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
            if type(endFunc) == "function" then
                endFunc()
            end
        end)
    end)

    self:delayCallBack(1,keyFunc)
end

--[[
    过场动画(free到base)
]]
function CodeGameScreenLightCherryMachine:changeSceneFromFreeToBase(keyFunc,endFunc)
    self:changeSceneToFree(keyFunc,endFunc,false)
end

function CodeGameScreenLightCherryMachine:playEffectNotifyNextSpinCall()
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
        if self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0 and self.m_bIsSelectCall ~= true then
            delayTime = delayTime + self:getWinCoinTime()
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
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end
    self.m_bIsSelectCall = false
end

--[[
    过场动画(respin)
]]
function CodeGameScreenLightCherryMachine:changeSceneToRespin(keyFunc,endFunc,isBaseToRespin)
    if isBaseToRespin then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_base_to_respin_guochang)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_to_base_guochang)
    end

    local spine = util_spineCreate("LightCherry_GC2",true,true)
    self.m_effectNode:addChild(spine)
    util_spinePlay(spine,"actionframe")
    util_spineEndCallFunc(spine,"actionframe",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
            if type(endFunc) == "function" then
                endFunc()
            end
        end)
    end)

    self:delayCallBack(1.2,keyFunc)
end

--[[
    过场动画(respin返回base)
]]
function CodeGameScreenLightCherryMachine:changeSceneFromRespinToBase(keyFunc,endFunc)
    self:changeSceneToRespin(keyFunc,endFunc,false)
end

function CodeGameScreenLightCherryMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_show_free_over)

    local view =self:showFreeSpinOver(globalData.slotRunData.lastWinCoin,globalData.slotRunData.totalFreeSpinCount,function()
        self:changeSceneFromFreeToBase(function()
            self:runCsbAction("nomal")
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"changeNomal",false})
            self:triggerFreeSpinOverCallFun()
        end,function()
            
        end)
    end)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_LightCherry_btn_click
    view:setBtnClickFunc(function(  )
        
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_hide_free_over)
    end)

    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label = node, sx = 1,sy = 1}, 800)
    view:findChild("root"):setPosition(display.center)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

--[[
    bonus触发动画
]]
function CodeGameScreenLightCherryMachine:runBonusTriggerAni(func)
    local aniTime = 0

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_bonus_trriger)

    local extraData = self.m_runSpinResultData.p_rsExtraData
    if extraData and extraData.links then
        
        local links = extraData.links or {}
        local moves = extraData.moves or {}
        local temp = clone(links)
        for i,list in ipairs(moves) do
            temp[#temp + 1] = clone(list)
        end

        for k,list in pairs(temp) do
            for index,posIndex in pairs(list) do
                local symbolNode = self:getSymbolByPosIndex(posIndex)
                if not tolua.isnull(symbolNode) and self:isFixSymbol(symbolNode.p_symbolType) then
                    self:playBonusAni(symbolNode,"actionframe",false,function()
                        
                    end)
                    aniTime = symbolNode:getAniamDurationByName("actionframe")
                end
            end
        end
    end

    self:delayCallBack(aniTime,func)
end

--[[
    创建一个临时的bonus信号
]]
function CodeGameScreenLightCherryMachine:createTempBonus(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end
    local tempSymbolAni = util_createAnimation("Socre_LightCherry_Bonus.csb")

    local symbolType = symbolNode.p_symbolType

    local score,jackpotType = self:getReSpinSymbolScore(self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex),symbolNode.p_symbolType) --获取分数（网络数据）

    local Node_spine = tempSymbolAni:findChild("Node_spine")
    Node_spine:removeAllChildren()
    if jackpotType == "" then
        local spine = util_spineCreate("Socre_LightCherry_Cherry",true,true)
        Node_spine:addChild(spine)
        spine:setTag(BONUS_SPINE_TAG)
    else --jackpot类型用金色的樱桃
        local spine = util_spineCreate("Socre_LightCherry_Cherry2",true,true)
        Node_spine:addChild(spine)
        spine:setTag(BONUS_SPINE_TAG)
    end
        
    local m_lb_num = tempSymbolAni:findChild("m_lb_num")
    if m_lb_num then
        m_lb_num:setVisible(jackpotType == "")
        local score = self:getFormatCoins(score)
        m_lb_num:setString(score)
    end

    --设置jackpot显示
    for index = 1,#JACKPOT_TYPE do
        local sp_jackpot = tempSymbolAni:findChild("jackpot_"..JACKPOT_TYPE[index])
        if sp_jackpot then
            sp_jackpot:setVisible(jackpotType == JACKPOT_TYPE[index])
        end
    end
    return tempSymbolAni
end

--[[
    移动bonus图标
]]
function CodeGameScreenLightCherryMachine:moveBonusAni(moveData,func)
    local tempSymbols = {}
    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.links then
        local links = self.m_runSpinResultData.p_rsExtraData.links[1]
        for index = 1,#links do
            local posIndex = links[index]
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            if symbolNode and self:isFixSymbol(symbolNode.p_symbolType) then
                local tempNode = self:createTempBonus(symbolNode)
                tempSymbols[#tempSymbols + 1] = tempNode
                self.m_effectNode:addChild(tempNode)
                local pos = util_convertToNodeSpace(symbolNode,self.m_effectNode)
                tempNode:setPosition(pos)
            end
        end
    end
    

    for i = 1, #moveData, 1 do
        local posIndexA = moveData[i][1]
        local posIndexB = moveData[i][2]
        local posA = self:getRowAndColByPos(posIndexA)
        local posB = self:getRowAndColByPos(posIndexB)

        local symbolA = self:getSymbolByPosIndex(posIndexA)
        local symbolB = self:getSymbolByPosIndex(posIndexB)

        --创建一个临时的A信号
        local tempSymbol = self:createTempBonus(symbolA)

        for j = 1, #self.m_runSpinResultData.p_storedIcons, 1 do
            if self.m_runSpinResultData.p_storedIcons[j][1] == moveData[i][1] then
                self.m_runSpinResultData.p_storedIcons[j][1] = moveData[i][2]
            end
        end
        

        if symbolA and symbolB then
            --把终点信号变为symbolA信号
            self:changeSymbolType(symbolB,symbolA.p_symbolType)  
            symbolB.m_isLastSymbol = true 
            self:setSpecialNodeScore(symbolB) 
            
            
            local startPos = util_convertToNodeSpace(symbolA,self.m_effectNode)
            tempSymbol:setPosition(startPos)
            self.m_effectNode:addChild(tempSymbol)

            local randType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
            self:changeSymbolType(symbolA,randType)  

            local pos = util_convertToNodeSpace(symbolB,self.m_effectNode)
            local actionList = {
                cc.MoveTo:create(0.5, pos),
                cc.RemoveSelf:create()
            }
            local seq = cc.Sequence:create(actionList)
            tempSymbol:runAction(seq)
        end
    end
    self:delayCallBack(0.5,function()
        for index = 1,#tempSymbols do
            local tempNode = tempSymbols[index]
            tempNode:removeFromParent()
        end
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenLightCherryMachine:showRespinView(effectData)
    self:clearCurMusicBg()

    self.m_inLineBonus = {}

    --可随机的普通信息
    local randomTypes = {
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

    --可随机的特殊信号
    local endTypes = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_MINI_SYMBOL, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_MINOR_SYMBOL, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_MAJOR_SYMBOL, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_GRAND_SYMBOL, runEndAnimaName = "", bRandom = true}
    }
    self.m_bIsTriggerRespin = true

    if (self.m_runSpinResultData.p_rsExtraData.moves and #self.m_runSpinResultData.p_rsExtraData.moves > 0) or self.m_bIsReconnect == false then

        local parent = self.m_machineNode:getParent()
        local moves = self.m_runSpinResultData.p_rsExtraData.moves
        local reelIndex = math.modf(self.m_runSpinResultData.p_rsExtraData.links[1][1] / self.m_iReelColumnNum) + 1
        local vecNewSymbol = {}

        self:runBonusTriggerAni(function()
            
            local function removeCherry()
                local link = self.m_runSpinResultData.p_rsExtraData.links[1]
                for n = #self.m_runSpinResultData.p_storedIcons, 1, -1 do
                    local isContain = false
                    for m = 1, #link, 1 do
                        if self.m_runSpinResultData.p_storedIcons[n][1] == link[m] then
                            isContain = true
                            break
                        end
                    end
                    if isContain == false then
                        if self.m_vecUnlockCherry == nil then
                            self.m_vecUnlockCherry = {}
                        end
                        self.m_vecUnlockCherry[#self.m_vecUnlockCherry + 1] = self.m_runSpinResultData.p_storedIcons[n]
                        table.remove(self.m_runSpinResultData.p_storedIcons, n)
                    end
                end
            end

            self:reSpinChangeReelData()

            if moves == nil or #moves == 0 then
                
                self:changeSceneToRespin(function()
                    self:runCsbAction("freespin")
                    removeCherry()
                    for j = 1, #vecNewSymbol, 1 do
                        vecNewSymbol[j]:removeFromParent(true)
                    end
                    self:findChild("rootNode"):setVisible(true)
                    self:triggerReSpinCallFun(endTypes, randomTypes)
                end, nil, true)
                return
            end
            self:findChild("rootNode"):setVisible(false)
            --将同一行上没在一起的bonus图标移动到一块
            self:moveBonusAni(moves,function()
                self:findChild("rootNode"):setVisible(true)
                self:changeSceneToRespin(function()
                    self:runCsbAction("freespin")
                    removeCherry()
                    for j = 1, #vecNewSymbol, 1 do
                        vecNewSymbol[j]:removeFromParent(true)
                    end
                    self:triggerReSpinCallFun(endTypes, randomTypes)
                end, nil, true)
            end)
            
            self.m_runSpinResultData.p_reels[reelIndex] = self.m_runSpinResultData.p_rsExtraData.finalReel
        end)
    else
        self.m_bIsReconnect = false
        self:runCsbAction("freespin")
        self:delayCallBack(0.5,function()
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end)
    end
end

--触发/断线重连 reSpin时修改轮盘数据，修改不参与links的樱桃小块
function CodeGameScreenLightCherryMachine:reSpinChangeReelData()
    local p_rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if not p_rsExtraData or not p_rsExtraData.finalReel or not p_rsExtraData.links  then
        return
    end

    local reelIndex = math.modf(self.m_runSpinResultData.p_rsExtraData.links[1][1] / self.m_iReelColumnNum) + 1
    
    for j = 1, #self.m_runSpinResultData.p_reels, 1 do
        if j == reelIndex then
            if self.m_runSpinResultData.p_rsExtraData.finalReel and #self.m_runSpinResultData.p_rsExtraData.finalReel == 3 then
                self.m_runSpinResultData.p_reels[reelIndex] = self.m_runSpinResultData.p_rsExtraData.finalReel
            end
        else
            for i = 1, #self.m_runSpinResultData.p_reels[j], 1 do
                if self.m_runSpinResultData.p_reels[j][i] == self.SYMBOL_FIX_SYMBOL then
                    self.m_runSpinResultData.p_reels[j][i] = self.SYMBOL_NOT_FIX_SYMBOL
                end
                if self.m_runSpinResultData.p_reels[j][i] == self.SYMBOL_MINI_SYMBOL then
                    self.m_runSpinResultData.p_reels[j][i] = self.SYMBOL_NOT_MINI_SYMBOL
                end
                if self.m_runSpinResultData.p_reels[j][i] == self.SYMBOL_MINOR_SYMBOL then
                    self.m_runSpinResultData.p_reels[j][i] = self.SYMBOL_NOT_MINOR_SYMBOL
                end
                if self.m_runSpinResultData.p_reels[j][i] == self.SYMBOL_MAJOR_SYMBOL then
                    self.m_runSpinResultData.p_reels[j][i] = self.SYMBOL_NOT_MAJOR_SYMBOL
                end
                if self.m_runSpinResultData.p_reels[j][i] == self.SYMBOL_GRAND_SYMBOL then
                    self.m_runSpinResultData.p_reels[j][i] = self.SYMBOL_NOT_GRAND_SYMBOL
                end
            end
        end
    end
end

function CodeGameScreenLightCherryMachine:showReSpinStart(func)
    local vecSymbolNodes, vecLinkCherry = self:getLinkCherryData()
    self.m_inLineBonus = vecSymbolNodes
    local vecBars, iMaxLinkNum = self:getAnimationBars(vecLinkCherry)
    self:addCherryBG(vecSymbolNodes)
    local tempTime = 0.06
    for i = 1, #vecBars, 1 do
        local bars = vecBars[i]
        tempTime = 0.6 / #bars
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_lock)

        for j = 1, #bars, 1 do
            self:delayCallBack((j - 1) * tempTime,function()
                bars[j]:setVisible(true)
                if j == #bars then
                    local lock = util_createAnimation("Socre_LightCherry_lock.csb")
                    bars[j]:addChild(lock)
                    lock:runCsbAction("show")
                    lock:setName("lock")
                    lock:setPosition(8, bars[j]:getContentSize().height - 8)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_lock_in)

                    for n = 1, #vecSymbolNodes, 1 do
                        local symbolNode = vecSymbolNodes[n].node
                    end
                end
            end)
        end
    end

    local fDelayTime = tempTime * iMaxLinkNum
    local vecJackpot = {}
    for i = 1, #vecSymbolNodes, 1 do
        local symbolNode = vecSymbolNodes[i]
        if self:isJackpotCherrySymbolType(symbolNode.node.p_symbolType) then
            vecJackpot[#vecJackpot + 1] = symbolNode.node
            if self.m_vecJackPot == nil then
                self.m_vecJackPot = {}
            end
            self.m_vecJackPot[#self.m_vecJackPot + 1] = clone(symbolNode.node.p_symbolType)
        end
    end

    function respinStart()
        self:playBonusIdleAniInRespin()
        func()
        
        self.m_reSpinBar:setVisible(true)
        self.m_reSpinBar:showRespinBar(self.m_runSpinResultData.p_reSpinsTotalCount)
    end

    self:delayCallBack(fDelayTime,function()
        self:showCherryBar(vecSymbolNodes)

        --收集jackpot图标到右侧jackpot奖励
        self:delayCallBack(0.5,function()
            self:flyNextJackpotSymbol(vecJackpot,1,function()
                respinStart()
            end)
        end)
    end)
end

--[[
    收集jackpot图标到右侧奖励区
]]
function CodeGameScreenLightCherryMachine:flyNextJackpotSymbol(jackpots,index,func)
    if index > #jackpots then
        if type(func) == "function" then
            func()
        end
        return
    end

    local symbolNode = jackpots[index]

    --创建一个临时jackpot图标
    local newJackpot = self:createTempBonus(symbolNode)
    local jackpot = symbolNode:getCcbProperty("jackpot_words")
    local parentNode = self:findChild("showJackpot")
    parentNode:addChild(newJackpot)

    local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
    local tempPos = parentNode:convertToNodeSpace(worldPos)
    newJackpot:setPosition(tempPos)
    newJackpot:setName("jackpot" .. index)

    newJackpot:setVisible(false)
    local labCion = symbolNode:getCcbProperty("m_lb_num")
    labCion:setVisible(false)
    
    if self.m_jackpotBG:isVisible() == false then
        self.m_jackpotBG:setVisible(true)
    end
    self.m_jackpotBG:toAction("" .. (index - 1)..index)
    symbolNode:runAnim("bianzi",false,function()
        
    end)
    jackpot:setVisible(false)
    labCion:setVisible(true)
    newJackpot:setVisible(true)
    newJackpot:runCsbAction("shouji")

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_jackpot_bonus_fly)

    local actionList = {
        cc.DelayTime:create(10 / 60),
        cc.MoveTo:create(20 / 60, cc.p(0, (1 - index) * 70 - 10)),
        cc.CallFunc:create(function()
            self.m_jackpotBGEffect:setVisible(true)
            self.m_jackpotBGEffect:runCsbAction("idleframe", false, function()
                self.m_jackpotBGEffect:setVisible(false)
            end)
        end),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_jackpot_bonus_fly_end)

            self:flyNextJackpotSymbol(jackpots,index + 1,func)
        end)
    }

    local seq = cc.Sequence:create(actionList)
    newJackpot:runAction(seq)
end

function CodeGameScreenLightCherryMachine:changeReSpinStartUI(respinCount)
    self.m_reSpinBar:setVisible(true)
    self.m_reSpinBar:showRespinBar(self.m_runSpinResultData.p_reSpinsTotalCount)
    self.m_reSpinBar:updateLeftCount(respinCount,true)
end

--ReSpin刷新数量
function CodeGameScreenLightCherryMachine:changeReSpinUpdateUI(curCount)
    self.m_reSpinBar:updateLeftCount(curCount)
end

function CodeGameScreenLightCherryMachine:slotOneReelDown(reelCol)
    local isLongRun = CodeGameScreenLightCherryMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isLongRun then
        self.m_isLongRun = isLongRun
    end

    if self.m_isLongRun and self.m_isScatterLongRun then
        for iCol = 1,reelCol do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and symbolNode.m_currAnimName ~= "idleframe3" then
                    local aniNode = symbolNode:checkLoadCCbNode()     
                    local spine = aniNode.m_spineNode
                    
                    if spine then
                        util_spineMix(spine,symbolNode.m_currAnimName,"idleframe3",0.1)
                        symbolNode:runAnim("idleframe3",true)
                    end
                end
            end
        end
        
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        if self:getGameSpinStage() == QUICK_RUN then
            for k, v in pairs(self.m_reelRunAnima) do
                local runEffectBg = v
                if runEffectBg ~= nil and runEffectBg[1]:isVisible() then
                    runEffectBg[1]:setVisible(false)
                end
            end
        end
    end

    return isLongRun
end

function CodeGameScreenLightCherryMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    self:showRespinOverView()
end

function CodeGameScreenLightCherryMachine:showRespinOverView(effectData)
    local strCoins = util_formatCoins(self.m_serverWinCoins, 20)

    self:clearCurMusicBg()
    self.m_vecJackPot = nil
    local view =self:showReSpinOver(strCoins,
        function()
            -- util_setCsbVisible(self.m_fireworks,true)
            -- self.m_fireworks:showFireEffect()

            self:changeSceneFromRespinToBase(function()
                self:setReelSlotsNodeVisible(true)
                self:removeRespinNode()
                
            end,function()
                self:triggerReSpinOverCallFun(strCoins)
            end)
            
        end
    )
    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label = node, sx = 1,sy = 1}, 890)
end

--隐藏盘面信息
function CodeGameScreenLightCherryMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local childs = self:getReelParent(iCol):getChildren()
        for j = 1, #childs do
            local node = childs[j]
            node:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            local childs = slotParentBig:getChildren()
            for j = 1, #childs do
                local node = childs[j]
                node:setVisible(status)
            end
        end
    end

    --如果为空则从 clipnode获取
    local childs = self.m_clipParent:getChildren()
    local childCount = #childs

    for i = 1, childCount, 1 do
        local slotsNode = childs[i]
        if type(slotsNode.isSlotsNode) == "function" and slotsNode:isSlotsNode() then
            slotsNode:setVisible(status)
        end
    end
end

--respin结束 移除respin小块对应位置滚轴中的小块
function CodeGameScreenLightCherryMachine:checkRemoveReelNode(node)
    local targSp = self:getFixSymbol(node.p_cloumnIndex, node.p_rowIndex)
    if targSp then
        targSp:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenLightCherryMachine:checkChangeRespinFixNode(node)
    if tolua.isnull(node) then
        return
    end
    
    self:putSymbolBackToPreParent(node)
    
    if self:isFixSymbol(node.p_symbolType) then
        node:getCcbProperty("jackpot_words"):setVisible(true)
        self:playBonusAni(node,"idleframe")
        if node.p_symbolType ~= self.SYMBOL_FIX_SYMBOL then
            local m_lb_num = node:getCcbProperty("m_lb_num")
            m_lb_num:setVisible(false)
        end
    end
end

--[[
    将小块放回原父节点
]]
function CodeGameScreenLightCherryMachine:putSymbolBackToPreParent(symbolNode)
    if not tolua.isnull(symbolNode) and type(symbolNode.isSlotsNode) == "function" and symbolNode:isSlotsNode() then
        local parentData = self.m_slotParents[symbolNode.p_cloumnIndex]
        symbolNode.m_baseNode = parentData.slotParent
        symbolNode.m_topNode = parentData.slotParentBig

        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

        local zOrder = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
        symbolNode.p_showOrder = zOrder - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex * 10
        util_printLog("putSymbolBackToPreParent symbolType = "..symbolNode.p_symbolType.." p_cloumnIndex = ".. symbolNode.p_cloumnIndex.." p_rowIndex = "..symbolNode.p_rowIndex.." p_showOrder = "..symbolNode.p_showOrder)
        local isInTop = self:isSpecialSymbol(symbolNode.p_symbolType)
        symbolNode.m_isInTop = isInTop
        symbolNode:putBackToPreParent()

        symbolNode:setTag(self:getNodeTag(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex,SYMBOL_NODE_TAG))
    end
end

function CodeGameScreenLightCherryMachine:reSpinEndAction()
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_all_bonus_jiesuan)
    --停止idle定时器
    self:stopBonusIdleSchdule()
    local aniTime = 1
    local vecCherrys = self:getLinkCherryData()
    for index = 1,#vecCherrys do
        local data = vecCherrys[index]

        local symbolNode = data.node
        if not tolua.isnull(symbolNode) then
            self:playBonusAni(symbolNode,"actionframe",false,function()
                self:playBonusAni(symbolNode,"idleframe2",true)
            end)
            aniTime = util_max(aniTime, symbolNode:getAniamDurationByName("actionframe"))
        end
    end

    self:delayCallBack(aniTime,function()
        self.m_reSpinBar:setVisible(false)
        self:addCherryCoin(vecCherrys)
    end)
end

function CodeGameScreenLightCherryMachine:addCherryCoin(vecCherrys)
    local totalCherry = #vecCherrys
    local betValue = globalData.slotRunData:getCurTotalBet()
    self.m_lightScore = 0

    self:collectNextBonusCoins(vecCherrys,1,function()
        self:addCherryCoinOver(self.m_lightScore)
    end)
end

--[[
    收集下一个bonus赢钱
]]
function CodeGameScreenLightCherryMachine:collectNextBonusCoins(list,index,func)
    if index > #list then
        if type(func) == "function" then
            func()
        end
        return
    end
    local data = list[index]

    local symbolNode = data.node
    local labCoin = symbolNode:getCcbProperty("m_lb_num")

    self.m_lightScore = self.m_lightScore + data.score

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_bonus_jiesuan_win_fankui)

    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
    self:playCoinWinEffectUI()

    self:playBonusAni(symbolNode,"jiesuan",false,function()
        self:collectNextBonusCoins(list,index + 1,func)
    end)
end

function CodeGameScreenLightCherryMachine:addCherryCoinOver(winCoin)
    local fDelayTime = 0
    if not self.m_vecJackPot then
        self.m_vecJackPot = {}
    end
    self:addNextJackpotCoins(self.m_vecJackPot,1,function()
        local vecCherrys = self:getLinkCherryData()
        self:hideCherryBar(vecCherrys)
        self:respinOver()
    end)
end

function CodeGameScreenLightCherryMachine:addNextJackpotCoins(list,index,func)
    if index > #list then
        self.m_jackpotBG:setVisible(false)
        if type(func) == "function" then
            func()
        end
        return
    end

    local symbolType = list[index]
    if symbolType then
        local jackpotType = self:getJackpotTypeBySymbolType(symbolType)
        local jackpotNode = self.m_csbOwner["showJackpot"]:getChildByName("jackpot" .. index)
        if jackpotNode ~= nil then
            local jackpotCoin = 0
            jackpotCoin = self:getJackpotCoinsForIndex(symbolType,jackpotType)
            if jackpotCoin == 0 then
                for j = 1, #self.m_runSpinResultData.p_winLines, 1 do
                    if self.m_runSpinResultData.p_winLines[j].p_type == symbolType then
                        jackpotCoin = self.m_runSpinResultData.p_winLines[j].p_amount
                        break
                    end
                end
            end
            self.m_lightScore = self.m_lightScore + jackpotCoin

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_jackpot_bonus_fly_bottom)

            self:flyJackpotToWinCoins(jackpotNode,self.m_bottomUI.m_normalWinLabel,function()
                
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
                
                self:playCoinWinEffectUI()
                self:showJackpotWinView(jackpotType,jackpotCoin,function()
                    self:addNextJackpotCoins(list,index + 1,func)
                end)

            end)
        else
            self:addNextJackpotCoins(list,index + 1,func)
        end
    else
        self:addNextJackpotCoins(list,index + 1,func)
    end

end

function CodeGameScreenLightCherryMachine:getJackpotNumForType(symbolType)
    local num = 0
    for i,v in ipairs(self.m_vecJackPot) do
        if v == symbolType then
            num = num + 1
        end
    end
    if num == 0 then
        return 1
    else
        return num
    end
end

function CodeGameScreenLightCherryMachine:changeJackpotType(jackpotType)
    if jackpotType == "grand" then
        return "Grand"
    elseif jackpotType == "major" then
        return "Major"
    elseif jackpotType == "minor" then
        return "Minor"
        
    elseif jackpotType == "mini" then
        return "Mini"
    else
        return "Mini"
    end
end

function CodeGameScreenLightCherryMachine:getJackpotCoinsForIndex(symbolType,jackpotType)
    local p_jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    -- local jackpotTypeNum = self:getJackpotNumForType(symbolType)
    local totalCoins = 0
    for k,v in pairs(p_jackpotCoins) do
        if k == self:changeJackpotType(jackpotType) then
            totalCoins = v
        end
    end
    -- local coins = totalCoins / jackpotTypeNum or 0
    return totalCoins
end

function CodeGameScreenLightCherryMachine:flyJackpotToWinCoins(flyNode,endNode,func)
    local startPos = util_convertToNodeSpace(flyNode,self.m_effectNode2)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode2)

    util_changeNodeParent(self.m_effectNode2,flyNode)
    flyNode:setPosition(startPos)
    local actionList = {
        cc.DelayTime:create(10 / 60),
        cc.EaseIn:create(cc.MoveTo:create(20/60, endPos), 2),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create()
    }
    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("shouji")
end

-- 断线重连
function CodeGameScreenLightCherryMachine:MachineRule_initGame(initSpinData)
    if initSpinData.p_reSpinCurCount > 0 then
        self.m_bIsReconnect = true
        self:reSpinChangeReelData()
    end
    if initSpinData.p_freeSpinsLeftCount > 0 then
        self.m_jackPotBar:setFreeSpinCount(globalData.slotRunData.freeSpinCount)
        self.m_jackPotBar:toAction("freespin_show")
    end
end

function CodeGameScreenLightCherryMachine:enterGamePlayMusic()
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_LightCherry_enter_game)
    end)
end

function CodeGameScreenLightCherryMachine:onEnter()
    CodeGameScreenLightCherryMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_jackPotBar:updateJackpotInfo()

end

function CodeGameScreenLightCherryMachine:addObservers()
    CodeGameScreenLightCherryMachine.super.addObservers(self)
    -- 如果需要改变父类事件监听函数，则在此处修改(具体哪些监听看父类的addObservers)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            -- if self.m_bIsBigWin then
            --     return
            -- end
            if self.m_runSpinResultData and self.m_runSpinResultData.p_reSpinCurCount == 0 and 
                self.m_runSpinResultData.p_reSpinsTotalCount ~= 0 then
                return
            end
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet

            local soundIndex = 1
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
                soundTime = 2
            end
            local soundName = ""
            if self.m_bProduceSlots_InFreeSpin then
                soundName = self.m_publicConfig.SoundConfig["sound_LightCherry_winline_free_" .. soundIndex]
            else
                soundName = self.m_publicConfig.SoundConfig["sound_LightCherry_winline_" .. soundIndex]
            end
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            -- 播放音效freespin
            
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function CodeGameScreenLightCherryMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenLightCherryMachine:removeObservers()
    BaseSlotoManiaMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function CodeGameScreenLightCherryMachine:showReSpinOver(coins, func)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_view_show_over)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_LightCherry_btn_click
    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_respin_view_hide_over)
    end)

    view:findChild("root"):setPosition(display.center)
    view:findChild("root"):setScale(self.m_machineRootScale)

    return view
end

function CodeGameScreenLightCherryMachine:showFreeSpinStart(num, func)
    if func then
        self.m_bottomUI:checkClearWinLabel()
        func()
    end
end

function CodeGameScreenLightCherryMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenLightCherryMachine.super.dealSmallReelsSpinStates(self )
end

function CodeGameScreenLightCherryMachine:requestSpinReusltData()
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

function CodeGameScreenLightCherryMachine:playEffectNotifyChangeSpinStatus( )
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

--设置长滚信息
function CodeGameScreenLightCherryMachine:setReelRunInfo()
    
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local isScRunLong,isBnRunLong = false,false
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, isScRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, isScRunLong)
        bonusNum, isBnRunLong = self:setBonusScatterInfo(self.SYMBOL_FIX_SYMBOL, col , bonusNum, isBnRunLong)
        bRunLong = self.m_isScatterLongRun or isScRunLong or isBnRunLong
        if isScRunLong then
            self.m_isScatterLongRun = true
        end
        if isBnRunLong then
            self.m_ScatterShowCol = {1,2,3,4,5}
        else
            self.m_ScatterShowCol = {2,3,4}
        end

    end --end  for col=1,iColumn do

end



--设置bonus scatter 信息
function CodeGameScreenLightCherryMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]

    if self.m_isNoticeAni or self.m_chooseRepinGame then
        return 0,false
    end

    --下列长滚
    -- reelRunData:setNextReelLongRun(true)
    local reels = self.m_runSpinResultData.p_reels
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if column > 2 and column < 5 and self:checkPlayScatterBuling(column) then
            reelRunData:setNextReelLongRun(true)
            return specialSymbolNum,true
        else
            return specialSymbolNum,false
        end
    else
        -- local maxCount = 0
        -- for iRow = 1,#reels do
        --     local count = 0
        --     for iCol = 1,column do
        --         if self:isFixSymbol(reels[iRow][iCol]) then
        --             count = count + 1
        --         end
        --     end

        --     if maxCount < count then
        --         maxCount = count
        --     end
        -- end
        -- --同一行出现两个以上bonus时快滚
        -- if maxCount >= 2 then
        --     reelRunData:setNextReelLongRun(true)
        --     return maxCount,true
        -- end

        return 0,false
    end


end

-- 显示paytableview 界面
function CodeGameScreenLightCherryMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    view:findChild("root"):setScale(self.m_machineRootScale)
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

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenLightCherryMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_LightCherry_bigWin_notice)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local random = math.random(1,10)
        if random <= 3 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_LightCherry_bigWin_notice_say"..self.m_playFreeBigWinSayIndex])
            self.m_playFreeBigWinSayIndex = self.m_playFreeBigWinSayIndex + 1
            if self.m_playFreeBigWinSayIndex > 4 then
                self.m_playFreeBigWinSayIndex = 1
            end
        end
    else
        local random = math.random(1,10)
        if random <= 5 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_LightCherry_bigWin_notice_say"..self.m_playBigWinSayIndex])
            self.m_playBigWinSayIndex = self.m_playBigWinSayIndex + 1
            if self.m_playBigWinSayIndex > 4 then
                self.m_playBigWinSayIndex = 1
            end
        end
    end
    
    local coinWinNode = self.m_bottomUI.coinWinNode
    local spine_light = util_spineCreate("LightCherry_DY",true,true)
    self.m_effectNode:addChild(spine_light)
    local pos = util_convertToNodeSpace(coinWinNode,self.m_effectNode)
    spine_light:setPosition(pos)

    util_spinePlay(spine_light,"actionframe")
    util_spineEndCallFunc(spine_light,"actionframe",function(  )
        spine_light:setVisible(false)
        self:delayCallBack(0.1,function(  )
            spine_light:removeFromParent()
        end)

        if type(_func) == "function" then
            self:stopLinesWinSound()
            _func()
        end
    end)
end

return CodeGameScreenLightCherryMachine
