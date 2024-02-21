local ScratchWinnerCardViewBingo = class("ScratchWinnerCardViewBingo", util_require("CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewBase"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"
--[[
    上方bingo区域图标
]]
function ScratchWinnerCardViewBingo:upDateBingoLinesList()
    local parent = self:findChild("lines")

    for _bingoIndex,_symbolType in ipairs(self.m_cardData.bingoReels) do
        local lineSymbol = self.m_linesSymbolList[_bingoIndex]
        if not lineSymbol then
            local posNode = self:findChild(string.format("line_%d", _bingoIndex))
            if posNode then
                lineSymbol = self.m_machine:createnScratchWinnerTempSymbol(_symbolType)
                parent:addChild(lineSymbol)
                lineSymbol:setPosition(cc.p(posNode:getPosition()))
                self.m_linesSymbolList[_bingoIndex] = lineSymbol
            end
        else
            lineSymbol:changeSymbolCcb(_symbolType)
        end

        self.m_machine:upDateLineSymbol_card3(lineSymbol, _bingoIndex, self.m_cardData)
    end
end
function ScratchWinnerCardViewBingo:playBingoLineSymbolStart()
    --[[
        梯度出现(梯度值) 
        0 1 2 3 4
        1 2 3 4 5
        2 3 4 5 6
        3 4 5 6 7
        4 5 6 7 8
    ]]
    local level    = 0
    local interval = 0.05
    local colLen = 5
    local col = 1
    local row = 1

    for _lineIndex,_lineSymbol in ipairs(self.m_linesSymbolList) do
        col = math.mod(_lineIndex, colLen) 
        col = (0~=col) and col or colLen
        row = math.ceil(_lineIndex/colLen)
        level = math.ceil( math.sqrt( math.pow(col - 1 ,2) + math.pow(row - 1,2 )) ) 
        
        local delayTime = interval * level
        performWithDelay(_lineSymbol,function()
            _lineSymbol:runAnim("start", false)
        end, delayTime)
    end
end
function ScratchWinnerCardViewBingo:touchBingoReelSymbol(_reelIndex ,_bSound)
    local bingoIndexList = {}
    local symbolType = self.m_cardData.reels[_reelIndex]
    for _bingoIndex,_symbolType in ipairs(self.m_cardData.bingoReels) do
        if symbolType == _symbolType then
            table.insert(bingoIndexList, _bingoIndex)

            local lineSymbol = self.m_linesSymbolList[_bingoIndex]
            lineSymbol:stopAllActions()
            --上方图标变红
            lineSymbol:runAnim("switch", false)
        end
    end

    local bSwitch = #bingoIndexList > 0
    if bSwitch then
        if _bSound then
            gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_BingoSwitch)
        end
        
        --底部图标变红
        local reelSymbol = self.m_reelsSymbolList[_reelIndex]
        reelSymbol:runAnim("switch_down", false)
        --检测是否成线
        self:playBingoLineAnim(bingoIndexList)
    end

    return bSwitch
end
function ScratchWinnerCardViewBingo:playBingoLineAnim(_bingoIndexList)
    local lineSymbolList = {}
    local cardShopData = ScratchWinnerShopManager:getInstance():getCardShopData(self.m_cardData.name)
    local lines = cardShopData.lineInfo

    for i,_bingoIndex in ipairs(_bingoIndexList) do
        for _lineListIndex,_lineData in ipairs(lines) do
            -- 是否在这个连线上
            local bLine = false
            for iii,_bingoPos in ipairs(_lineData[1]) do
                local bingoPos = _bingoPos+1
                if _bingoIndex == bingoPos then
                    bLine = true
                    if not self.m_bingoLineData[bingoPos] then
                        self.m_bingoLineData[bingoPos] = {}
                    end
                    break
                end
            end

            if bLine then
                --播放列表不存在
                local bPlay = true
                for iii,_bingoPos in ipairs(_lineData[1]) do
                    local bingoPos = _bingoPos+1
                    if nil == self.m_bingoLineData[bingoPos] or nil ~= self.m_bingoLineData[bingoPos][_lineListIndex] then
                        bPlay = false
                        break
                    end
                end
                --已刮出该条线的所有图标
                if bPlay then
                    for iii,_bingoPos in ipairs(_lineData[1]) do
                        local bingoPos = _bingoPos+1
                        self.m_bingoLineData[bingoPos][_lineListIndex] = true

                        table.insert(lineSymbolList, self.m_linesSymbolList[bingoPos])
                    end
                end
            end

        end
    end
    

    if #lineSymbolList < 1 then
        return
    end

    for i,_symbol in ipairs(lineSymbolList) do
        _symbol.m_diCsb:runCsbAction("start", false)
    end
end
--[[
    上方区域的jackpot数值
]]
function ScratchWinnerCardViewBingo:upDateBingoLineLabel()
    local cardShopData = ScratchWinnerShopManager:getInstance():getCardShopData(self.m_cardData.name)
    local multi = cardShopData.lineInfo[1][2]
    local curBet = globalData.slotRunData:getCurTotalBet()
    local sCoins = string.format("$%s", util_formatCoins(curBet*multi, 3))
    local lab = self:findChild("m_lb_line")
    lab:setString(sCoins)
    self:updateLabelSize({label=lab,sx=1,sy=1}, 150)
end
function ScratchWinnerCardViewBingo:resetBingoLineLabel()
    self:findChild("m_lb_line"):setString("")
end
--[[
    重写接口
]]
function ScratchWinnerCardViewBingo:initUI(_cardConfig)
    ScratchWinnerCardViewBingo.super.initUI(self, _cardConfig)

    self.m_linesSymbolList = {}
end

function ScratchWinnerCardViewBingo:initCardViewSpine()
    ScratchWinnerCardViewBingo.super.initCardViewSpine(self)

    util_spinePlay(self.m_cardSpine, "idle", true)
end

function ScratchWinnerCardViewBingo:initCardViewSymbol()
    ScratchWinnerCardViewBingo.super.initCardViewSymbol(self)

    self.m_bingoData = {}
    --[[
        m_bingoData = {
            {
                reelIndex = 1,           --图标位置索引
                
            }
        }
    ]]
    self.m_bingoLineData = {
        [13] = {}
    }
    --[[
        m_bingoLineData = {
            lineIndex = {          --上方图标的索引
                lineListIndex = true,     --已经参与的连线列表索引
            }
        }
    ]]

    self:upDateBingoLinesList()
    self:upDateBingoLineLabel()
end

function ScratchWinnerCardViewBingo:getDelayAutoScrapeTime()
    -- 需要等待一下梯度出现
    local jackpotEnterTime = 8 * 0.05 + 0.34
    return jackpotEnterTime
end

function ScratchWinnerCardViewBingo:playCardViewShow(_bDifferent, _bReconnect)
    ScratchWinnerCardViewBingo.super.playCardViewShow(self, _bDifferent, _bReconnect)

    self:playBingoLineSymbolStart()
end

function ScratchWinnerCardViewBingo:getAutoScrapePath()
    -- cc.size(615, 276) 
    -- cc.size(90, 70)
    local pathList = {
        {
            cc.p(0, 225),cc.p(90, 280),
            cc.p(180, 280),cc.p(0, 135),

            cc.p(0, 45),cc.p(270, 280),
            cc.p(360, 280),cc.p(45, 0),

            cc.p(135, 0),cc.p(450, 280),
            cc.p(540, 280),cc.p(225, 0),

            cc.p(315, 0),cc.p(615, 280),
            cc.p(615, 190),cc.p(405, 0),

            cc.p(495, 0),cc.p(615, 100),
            cc.p(540, 0),
        }
    }
    local finalPath = pathList[1]
    local newPath = {}
    local mainScale = self.m_machine.m_machineRootScale

    for i,_pos in ipairs(finalPath) do
        table.insert( newPath, cc.p(_pos.x*mainScale, _pos.y*mainScale))
    end

    return newPath
end

function ScratchWinnerCardViewBingo:coatingOverCallBack()
    local bSound = true
    --把所有图标都摸一遍
    for _reelIndex,_reelSymbol in ipairs(self.m_reelsSymbolList) do
        local bHave = false
        for ii,_bingoData in ipairs(self.m_bingoData) do
            if _reelIndex == _bingoData.reelIndex then
                bHave = true
                break
            end
        end
        if not bHave then
            table.insert(self.m_bingoData, {
                reelIndex = _reelIndex,
            })
            local bSwitch = self:touchBingoReelSymbol(_reelIndex, bSound)
            if bSwitch then
                bSound = false
            end
        end
    end

    ScratchWinnerCardViewBingo.super.coatingOverCallBack(self)
end


function ScratchWinnerCardViewBingo:onTouchCoatingLayer(_obj, _event, _bInArea)
    ScratchWinnerCardViewBingo.super.onTouchCoatingLayer(self, _obj, _event, _bInArea)
    if not _bInArea then
        return
    end

    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(self.m_cardData.name)
    local symbolParent = self:findChild("reel")
    local touchNodePos = symbolParent:convertToNodeSpace( cc.p(_event.x, _event.y) )
    local brushRadius = cardConfig.cardViewBrushRadius

    -- 循环下方的刮卡节点列表
    for _reelIndex,_reelSymbol in ipairs(self.m_reelsSymbolList) do
        local symbolPos = cc.p(_reelSymbol:getPosition())
        local distance  = math.sqrt(math.pow(symbolPos.x - touchNodePos.x, 2) + math.pow(symbolPos.y - touchNodePos.y, 2))
        local bTouchIn = distance <= brushRadius
        -- print("[ScratchWinnerCardViewBingo:onTouchCoatingLayer]", _reelIndex,distance,brushRadius,bTouchIn)
        -- 匹配在触摸范围的所有节点
        if bTouchIn then
            -- 之前摸过的不处理
            local bTouched = false
            for i,_bingoData in ipairs(self.m_bingoData) do
                if _reelIndex == _bingoData.reelIndex then
                    bTouched = true
                    break
                end
            end
            if not bTouched then
                --记录一下触摸过的节点
                table.insert(self.m_bingoData, {
                    reelIndex = _reelIndex,
                })
                self:touchBingoReelSymbol(_reelIndex, true)
            end
            
        end
    end
end

function ScratchWinnerCardViewBingo:playJackpotLineSound()
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_BingoJackpot)
end
function ScratchWinnerCardViewBingo:playInLineNodes()
    local commonLinePos  = {}
    local jackpotLinePos = {}
    for i,v in ipairs(self.m_cardData.lines) do
        local linePos = nil
        if "jackpot" == v.kind then
            linePos = jackpotLinePos
        else
            linePos = commonLinePos
        end
        for ii,_reelPos in ipairs(v.icons) do
            local reelPos = _reelPos+1
            linePos[reelPos] = true
        end
    end

    local lineMaxTime = 0
    local symbolList = self.m_linesSymbolList
    for _reelPos,v in pairs(commonLinePos) do
        local symbol = symbolList[_reelPos]
        lineMaxTime = util_max(lineMaxTime, symbol:getAniamDurationByName(symbol:getLineAnimName()))
    end
    for _reelPos,v in pairs(jackpotLinePos) do
        local symbol = symbolList[_reelPos]
        lineMaxTime = util_max(lineMaxTime, symbol:getAniamDurationByName(symbol:getLineAnimName()))
    end

    self.m_lineBgSoundsId = gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_BingoLine)

    local lineFrameIndex = 0
    --超过一条线开始执行循环播放
    if #self.m_cardData.lines > 1 then
        local lineFrameNode  = self:findChild("reelSpecial")
        self:stopLineFrameUpDate()
        self:playInLineNodesByIndex(lineFrameIndex)
        self.m_upDateLineFrame = schedule(lineFrameNode, function()
            lineFrameIndex = lineFrameIndex >= #self.m_cardData.lines and 0 or lineFrameIndex+1
            self:playInLineNodesIdle()
            self:playInLineNodesByIndex(lineFrameIndex)
        end, lineMaxTime)
    else
        self:playInLineNodesByIndex(lineFrameIndex)
    end
end
function ScratchWinnerCardViewBingo:playInLineNodesByIndex(_lineIndex)
    local commonLinePos  = {}
    local jackpotLinePos = {}
    local linePos = nil
    local lineData = self.m_cardData.lines[_lineIndex]
    -- 全体连线
    if not lineData then
        commonLinePos,jackpotLinePos = self:getFirstLinePosList()
    -- 单条连线
    else
        if "jackpot" == lineData.kind then
            linePos = jackpotLinePos
        else
            linePos = commonLinePos
        end
        for i,_reelPos in ipairs(lineData.icons) do
            local reelPos = _reelPos+1
            linePos[reelPos] = true
        end
    end

    

    local symbolList = self.m_linesSymbolList
    for _reelPos,v in pairs(jackpotLinePos) do
        commonLinePos[_reelPos] = nil
        
        local symbol = symbolList[_reelPos]
        symbol.m_diCsb:runCsbAction("start2", false)
        symbol:runLineAnim()
    end
    for _reelPos,v in pairs(commonLinePos) do
        local symbol = symbolList[_reelPos]
        symbol.m_diCsb:runCsbAction("start", false)
        symbol:runLineAnim()
    end
    
end
function ScratchWinnerCardViewBingo:playInLineNodesIdle()
    -- 播一下底板的idle
    local allLinePos     = {}
    for i,v in ipairs(self.m_cardData.lines) do
        for ii,_reelPos in ipairs(v.icons) do
            local reelPos = _reelPos+1
            allLinePos[reelPos] = true
        end
    end
    local symbolList = self.m_linesSymbolList
    for _reelPos,v in pairs(allLinePos) do
        local symbol = symbolList[_reelPos]
        symbol.m_diCsb:runCsbAction("idle", false)
        symbol:runIdleAnim()
    end
end

function ScratchWinnerCardViewBingo:getFirstLinePosList()
    local commonLinePos     = {}
    local jackpotLinePos    = {}
    local linePos           = nil
    local isJackpot = self:isTriggerJackpot()

    if isJackpot then
        for i,v in ipairs(self.m_cardData.lines) do
            if "jackpot" == v.kind then
                for ii,_reelPos in ipairs(v.icons) do
                    local reelPos = _reelPos+1
                    jackpotLinePos[reelPos] = true
                end
            end
        end
    else
        for i,v in ipairs(self.m_cardData.lines) do
            for ii,_reelPos in ipairs(v.icons) do
                local reelPos = _reelPos+1
                commonLinePos[reelPos] = true
            end
        end
    end

    return commonLinePos,jackpotLinePos
end

function ScratchWinnerCardViewBingo:endCardGame()
    self.m_bingoData = {}
    self.m_bingoLineData = {}

    ScratchWinnerCardViewBingo.super.endCardGame(self)
end

return ScratchWinnerCardViewBingo