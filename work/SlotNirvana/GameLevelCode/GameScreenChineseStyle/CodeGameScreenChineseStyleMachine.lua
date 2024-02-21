---
-- island
-- 2018年6月4日
-- CodeGameScreenChineseStyleMachine.lua
-- 
-- 玩法：
-- 


local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseDialog = util_require("Levels.BaseDialog")



local CodeGameScreenChineseStyleMachine = class("CodeGameScreenChineseStyleMachine", BaseSlotoManiaMachine)


CodeGameScreenChineseStyleMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
CodeGameScreenChineseStyleMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenChineseStyleMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenChineseStyleMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10

CodeGameScreenChineseStyleMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

--- wild 在freespin 时显示的倍数， 1到8倍
-- CodeGameScreenChineseStyleMachine.m_mutilWild1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 201
CodeGameScreenChineseStyleMachine.m_mutilWild2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 202
CodeGameScreenChineseStyleMachine.m_mutilWild3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 203
CodeGameScreenChineseStyleMachine.m_mutilWild4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 204
CodeGameScreenChineseStyleMachine.m_mutilWild5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 205
CodeGameScreenChineseStyleMachine.m_mutilWild6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 206
CodeGameScreenChineseStyleMachine.m_mutilWild7 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 207
CodeGameScreenChineseStyleMachine.m_mutilWild8 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 208

CodeGameScreenChineseStyleMachine.m_chipFly1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19
CodeGameScreenChineseStyleMachine.m_chipFly2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20
CodeGameScreenChineseStyleMachine.m_chipFly3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21
CodeGameScreenChineseStyleMachine.m_chipFly4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22
CodeGameScreenChineseStyleMachine.m_chipFly5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23
CodeGameScreenChineseStyleMachine.m_chipFly6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24
CodeGameScreenChineseStyleMachine.m_chipFly7 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 25
CodeGameScreenChineseStyleMachine.m_chipFly8 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 26
CodeGameScreenChineseStyleMachine.m_chipFly9 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 27

CodeGameScreenChineseStyleMachine.nMiniScore = 0
CodeGameScreenChineseStyleMachine.nMinorScore = 0
CodeGameScreenChineseStyleMachine.nMajorScore = 0
CodeGameScreenChineseStyleMachine.nGrandScore = 0

CodeGameScreenChineseStyleMachine.m_winFrame = nil
CodeGameScreenChineseStyleMachine.m_fishFlyHandlerID = nil
CodeGameScreenChineseStyleMachine.m_jackPotBar = nil

CodeGameScreenChineseStyleMachine.m_chipList = nil
CodeGameScreenChineseStyleMachine.m_playAnimIndex = 0
CodeGameScreenChineseStyleMachine.m_lightScore = 0

CodeGameScreenChineseStyleMachine.m_reelEffectName = "WinFrameChineseStyle_Big"


-- respin
CodeGameScreenChineseStyleMachine.m_allLockNodeReelPos = nil
CodeGameScreenChineseStyleMachine.m_addLockNodeReelPos = nil

CodeGameScreenChineseStyleMachine.m_totleBombNumCount = nil

local BIG_WIN_COIN_RATIO_ONE = 1;
local BIG_WIN_COIN_RATIO_TWO = 2;
local BIG_WIN_COIN_RATIO_THR = 3;
local BIG_WIN_COIN_RATIO_FOU = 4;
local BIG_WIN_COIN_RATIO_FIV = 5;
local BIG_WIN_COIN_RATIO_SIX = 6;
local BIG_WIN_COIN_RATIO_SEV = 7;

--定义成员
local ID_COMPARE_INFO = nil
local JACKPOTNAME = {"mini", "minor", "major", "grand"}

-- 构造函数
function CodeGameScreenChineseStyleMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)


    self.m_endType =  self.SYMBOL_FIX_SYMBOL
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_wildContinusPos = {}
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenChineseStyleMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ChineseStyleConfig.csv", "LevelChineseStyleConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    -- respin 音效
    self.m_respinEndSound = {}
    for i=1,self.m_iReelColumnNum  do
        self.m_respinEndSound[#self.m_respinEndSound  + 1] = "ChineseStyleSounds/music_ChineseStyle_reward_fall_" .. i .. ".mp3"
    end
end  

function CodeGameScreenChineseStyleMachine:initUI()

    self.m_winFrame = util_createView("CodeChineseStyleSrc.ChineseStyleWinFrame")
    local targetNode = self:findChild("m_targetPos")
    targetNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    targetNode:addChild(self.m_winFrame)

    util_setCsbVisible(self.m_winFrame,false)

    self.m_jackPotBar = util_createView("CodeChineseStyleSrc.ChineseStyleTopBar")
    self:findChild("m_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    
    -- self:findChild("m_jackpot"):setVisible(false)

    self:initFreeSpinBar()
    util_setPositionPercent(self.m_csbNode,0.44)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        -- local index = util_random(1,3)
        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local index = 1
        if winRate <= 1 then
            index = 1
        elseif winRate > 1 and winRate <= 3 then
            index = 2
        elseif winRate > 3 then
            index = 3
        end
        gLobalSoundManager:playSound("ChineseStyleSounds/music_Chinese_last_win_" .. index .. ".mp3")

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        -- 播放音效freespin
        gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_lightning_count_3.mp3")
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


end

function CodeGameScreenChineseStyleMachine:initJackpotInfo(jackpotPool,lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenChineseStyleMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "ChineseStyle"  
end


function CodeGameScreenChineseStyleMachine:getRespinView()
    return "CodeChineseStyleSrc.ChineseStyleRespinView"
end

function CodeGameScreenChineseStyleMachine:getRespinNode()
    return "CodeChineseStyleSrc.ChineseStyleRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenChineseStyleMachine:MachineRule_GetSelfCCBName(symbolType)
    
    if symbolType == self.SYMBOL_FIX_SYMBOL  then
        return "Socre_ChineseStyle_Chip"
    end


    if symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_ChineseStyle_Grand"
    end

    if symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_ChineseStyle_Major"
    end

    if symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_ChineseStyle_Minor"
    end

    if symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_ChineseStyle_Mini"
    end

    if symbolType == self.m_mutilWild2 or 
    symbolType == self.m_mutilWild3 or
    symbolType == self.m_mutilWild4 or
    symbolType == self.m_mutilWild5 or
    symbolType == self.m_mutilWild6 or
    symbolType == self.m_mutilWild7 or
    symbolType == self.m_mutilWild8 then

        return "Socre_ChineseStyle_SuperWild"
    end

    if symbolType == self.m_chipFly1 then
        return "Socre_ChineseStyle_Chip_Fly1"
    end
    if symbolType == self.m_chipFly2 then
        return "Socre_ChineseStyle_Chip_Fly2"
    end
    if symbolType == self.m_chipFly3 then
        return "Socre_ChineseStyle_Chip_Fly3"
    end
    if symbolType == self.m_chipFly4 then
        return "Socre_ChineseStyle_Chip_Fly4"
    end
    if symbolType == self.m_chipFly5 then
        return "Socre_ChineseStyle_Chip_Fly5"
    end
    if symbolType == self.m_chipFly6 then
        return "Socre_ChineseStyle_Chip_Fly6"
    end
    if symbolType == self.m_chipFly7 then
        return "Socre_ChineseStyle_Chip_Fly7"
    end
    if symbolType == self.m_chipFly8 then
        return "Socre_ChineseStyle_Chip_Fly8"
    end
    if symbolType == self.m_chipFly9 then
        return "Socre_ChineseStyle_Chip_Fly9"
    end

    return nil
end

function CodeGameScreenChineseStyleMachine:getReelHeight()
    return 633-60
end

function CodeGameScreenChineseStyleMachine:getReelWidth()
    return 1070
end

function CodeGameScreenChineseStyleMachine:scaleMainLayer()
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
        local posChange = 0
        if self.m_isPadScale then
            posChange = 22
            mainScale = mainScale - 0.04
        else
            posChange = 22
        end
       
        if  display.height/display.width >= 768/1024 then
            mainScale = 0.80
        elseif display.height/display.width < 768/1024 and display.height/display.width >= 640/960 then
            mainScale = 0.90
        end
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(mainPosY + posChange)
    end

end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenChineseStyleMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_SYMBOL,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_mutilWild8,count =  2}


    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly7,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly8,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.m_chipFly9,count =  2}
    return loadNode
end

-- 是不是 fixSymbol
function CodeGameScreenChineseStyleMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND then
        return true
    end
    return false
end

function CodeGameScreenChineseStyleMachine:getIDCompares(idNum)
    return ID_COMPARE_INFO[idNum]
end

function CodeGameScreenChineseStyleMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    local reelNode = node
    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_MINI       
        or symbolType == self.SYMBOL_FIX_MINOR 
        or symbolType == self.SYMBOL_FIX_MAJOR
        or symbolType == self.SYMBOL_FIX_GRAND 
    then
        reelNode.p_idleIsLoop = true

        if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            reelNode.p_reelDownRunAnima = "lighting"
        end

        for k = 1, 3 do
            if reelNode:getCcbProperty("imgbg_" .. k) ~= nil then

                util_setCsbVisible(reelNode:getCcbProperty("imgbg_" .. k),false)
            end
        end

        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then

            util_setCsbVisible(reelNode:getCcbProperty("imgbg_" .. 1),true)
        end
        
        --下帧调用 才可能取到 x y值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end


    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        for k = 2, 8 do
            if self["m_mutilWild" .. k] == symbolType then
                local sprite = reelNode:getCcbProperty("m_wild_num")
                local lblNum = sprite:setSpriteFrame("ui/ChineseStyle_wild_x" .. k .. ".png")
                break
            end
        end
    end
end

function CodeGameScreenChineseStyleMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL
        or symbolType == self.SYMBOL_FIX_MINI       
        or symbolType == self.SYMBOL_FIX_MINOR 
        or symbolType == self.SYMBOL_FIX_MAJOR
        or symbolType == self.SYMBOL_FIX_GRAND 
    then
        reelNode.p_idleIsLoop = true

        if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            reelNode.p_reelDownRunAnima = "lighting"
        end

        for k = 1, 3 do
            if reelNode:getCcbProperty("imgbg_" .. k) ~= nil then

                util_setCsbVisible(reelNode:getCcbProperty("imgbg_" .. k),false)
            end
        end

        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then

            util_setCsbVisible(reelNode:getCcbProperty("imgbg_" .. 1),true)
        end
        
        --下帧调用 才可能取到 x y值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end


    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        for k = 2, 8 do
            if self["m_mutilWild" .. k] == symbolType then
                local sprite = reelNode:getCcbProperty("m_wild_num")
                local lblNum = sprite:setSpriteFrame("Symbol/ChineseStyle_wild_x" .. k .. ".png")
                break
            end
        end
    end
    

   
    return reelNode
end


function CodeGameScreenChineseStyleMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --获取分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
            
        end
        if symbolNode then
            symbolNode:runAnim("idleframe",true)
        end
        

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
                
                symbolNode:runAnim("idleframe",true)
            end
            
        end
        
    end

    
end

function CodeGameScreenChineseStyleMachine:getReSpinSymbolScore(id)
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
       return nil
    end

    local pos = self:getRowAndColByPos(idNode)
    local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if type < 1000 then
        if score == 10 then
            score = "MINI"
        elseif score == 20 then
            score = "MINOR"
        elseif score == 100 then
            score = "MAJOR"
        elseif score == 1000 then
            score = "GRAND"
        end
    end
    return score
end



----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenChineseStyleMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        score = self.m_configData:getBnBasePro1()
    end


    return score
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenChineseStyleMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self.m_runSpinResultData.p_fsExtraData then
        
        self:reels_ChangeTypeForSuperWild(self.m_runSpinResultData.p_fsExtraData)
    end
end


function CodeGameScreenChineseStyleMachine:reels_ChangeTypeForSuperWild( data )

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            
            local iconpos = self:getPosReelIdx(iRow, iCol)
            for k,v in pairs(data) do
                local pos = tonumber(k)
                if iconpos == pos then
                    self.m_stcValidSymbolMatrix[iRow][iCol] = self["m_mutilWild" .. v] or TAG_SYMBOL_TYPE.SYMBOL_WILD
                    print("----------------- 超级wild位置 ".. iconpos .." 倍数 ".. v)
                    break
                end
            end

           
        end
    end

end
function CodeGameScreenChineseStyleMachine:slotOneReelDown(reelCol)    
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)   

    local isplay= true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false
            gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_fall_" .. reelCol ..".mp3") 
        end
    end
end

function CodeGameScreenChineseStyleMachine:getNetWorkModuleName()
    return "DoubleFish"
end

--结束移除小块调用结算特效
function CodeGameScreenChineseStyleMachine:reSpinEndAction()    
    self.m_winFrame:updateLeftCount(0)
    --播放闪电效果
    self:playTriggerLight()
end

function CodeGameScreenChineseStyleMachine:showRespinOverView(effectData)
    local seq = cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function ()

        util_setCsbVisible(self.m_winFrame,false)
        self.m_jackPotBar:setVisible(true)
    end))

    self:runAction(seq)

    local strCoins=util_formatCoins(self.m_serverWinCoins,11)
    local view=self:showReSpinOver(strCoins,function()
        self:triggerReSpinOverCallFun(self.m_lightScore)
        self.m_lightScore = 0
        self:resetMusicBg() 
        self:setMinMusicBGVolume()
        
    end)
    gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)
end


-- lighting 完毕之后 播放动画
function CodeGameScreenChineseStyleMachine:playLightEffectEnd()
    local cleaningNode = self.m_respinView:getFixSlotsNode()
    for i = 1, #cleaningNode do
        local lastNode = cleaningNode[i]
        lastNode:getCcbProperty("imgbg_1"):setVisible(false) 
    end

    performWithDelay(self, function ()
        self:respinOver()
    end, 1.5)
    
end

function CodeGameScreenChineseStyleMachine:playTriggerLight(reSpinOverFunc)

-- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- gLobalSoundManager:stopBackgroudMusic()
    self:clearCurMusicBg()
    
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    local nDelayTime = #self.m_chipList * (0.1 + 0.85)
    self:playChipCollectAnim()
    
end


function CodeGameScreenChineseStyleMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= 15 then
            local jackpotScore = self:BaseMania_getJackpotScore(1)
            self.m_lightScore = self.m_lightScore + jackpotScore
            self:showRespinJackpot(
                4,
                util_formatCoins(jackpotScore, 12),
                function()
                    self:playLightEffectEnd()        
                end
            )
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
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 2
        elseif score == "MINI" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 1
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local fishFlyEndJiesuan = function()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self. m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            self:showRespinJackpot(nJackpotType, util_formatCoins(jackpotScore,12), function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
            gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_jackpotwinframe.mp3")
        end
    end

    


    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        chipNode:runAnim("lighting")

        gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_linghtning_1.mp3") 

        self.m_winFrame:showCollectCoin(util_formatCoins(self.m_lightScore,17))

        fishFlyEndJiesuan()   

        waitNode:removeFromParent()
    end,0.4)

        

  
end



function CodeGameScreenChineseStyleMachine:showRespinJackpot(index,coins,func)
    gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_jackpotwinframe.mp3")
    local jackPotWinView = util_createView("CodeChineseStyleSrc.ChineseStyleJackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,func)
end



-- 断线重连 
function CodeGameScreenChineseStyleMachine:MachineRule_initGame()
    local storedCherryArry = self.m_runSpinResultData.p_storedIcons
    if self.m_respinNodeInfo == nil then
        print("  ")
    end
end

---
-- 数据生成之后
-- 改变轮盘ui块生成列表 (可以作用于贴长条等 特殊显示逻辑中)
function CodeGameScreenChineseStyleMachine:MachineRule_InterveneReelList()

end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenChineseStyleMachine:MachineRule_ResetReelRunData()
--self.m_reelRunInfo 中存放轮盘滚动信息

end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenChineseStyleMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    return false
end
function CodeGameScreenChineseStyleMachine:slotReelDown()
    CodeGameScreenChineseStyleMachine.super.slotReelDown(self) 
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end
function CodeGameScreenChineseStyleMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenChineseStyleMachine.super.playEffectNotifyNextSpinCall(self)
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenChineseStyleMachine:MachineRule_stopReelChangeData()

end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenChineseStyleMachine:addSelfEffect()

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenChineseStyleMachine:MachineRule_playSelfEffect(effectData)

end

function CodeGameScreenChineseStyleMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_custom_enter_fs.mp3")
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

function CodeGameScreenChineseStyleMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_linghtning_over_win.mp3")
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS,false)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)
end


function CodeGameScreenChineseStyleMachine:showRespinView()

          --先播放动画 再进入respin
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_goin_lightning.mp3")

        --可随机的普通信息
        local randomTypes = 
        { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1}

        --可随机的特殊信号 
        local endTypes = 
        {
            {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "", bRandom = true},
            {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "", bRandom = false},
            {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "", bRandom = true},
            {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "", bRandom = true}
        }

        --构造盘面数据
        performWithDelay(self,function()

            if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
                self:triggerReSpinCallFun(endTypes, randomTypes)
            else
            -- 由玩法触发出来， 而不是多个元素触发
                if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                    self.m_runSpinResultData.p_reSpinCurCount = 3
                end
                self:triggerReSpinCallFun(endTypes, randomTypes)
            end   
        
        end,1)


  
 
end

function CodeGameScreenChineseStyleMachine:playRespinViewShowSound()
    gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_linghtning_frame.mp3")
end

--ReSpin开始改变UI状态
function CodeGameScreenChineseStyleMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_winFrame,true)
    self.m_jackPotBar:setVisible(false)
    self.m_winFrame:updateLeftCount(respinCount)

   

end

--ReSpin刷新数量
function CodeGameScreenChineseStyleMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_winFrame:updateLeftCount(curCount)   
end

--ReSpin结算改变UI状态
function CodeGameScreenChineseStyleMachine:changeReSpinOverUI()

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end




---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenChineseStyleMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_freespin")
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenChineseStyleMachine:levelFreeSpinOverChangeEffect()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"change_normal")
end
---------------------------------------------------------------------------



function CodeGameScreenChineseStyleMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_goin.mp3") 
        scheduler.performWithDelayGlobal(function (  )
            self:resetMusicBg()
            self:setMinMusicBGVolume()
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end



function CodeGameScreenChineseStyleMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()
    
    self.m_jackPotBar:updateJackpotInfo()   
end

function CodeGameScreenChineseStyleMachine:addObservers()
	BaseSlotoManiaMachine.addObservers(self)

-- 如果需要改变父类事件监听函数，则在此处修改(具体哪些监听看父类的addObservers)
end


function CodeGameScreenChineseStyleMachine:onExit()
    BaseSlotoManiaMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    if self.m_fishFlyHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fishFlyHandlerID)
        self.m_fishFlyHandlerID = nil
    end

    if self.m_reSpinHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_reSpinHandlerId)
        self.m_reSpinHandlerId = nil
    end
    scheduler.unschedulesByTargetName(self:getModuleName())
end


function CodeGameScreenChineseStyleMachine:removeObservers()
	BaseSlotoManiaMachine.removeObservers(self)

	-- 自定义的事件监听，也在这里移除掉
end

-- --重写组织respinData信息
function CodeGameScreenChineseStyleMachine:getRespinSpinData()
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

function CodeGameScreenChineseStyleMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end


---
--设置bonus scatter 层级
function CodeGameScreenChineseStyleMachine:getBounsScatterDataZorder(symbolType )
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
            -- 这样调整后 分值越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

return CodeGameScreenChineseStyleMachine






