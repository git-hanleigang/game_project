local ScratchWinnerCardViewTriple = class("ScratchWinnerCardViewTriple", util_require("CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewBase"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"

--[[
    触摸图标
]]
function ScratchWinnerCardViewTriple:touchAllTripleReelSymbol()
    for _reelIndex,_symbol in ipairs(self.m_reelsSymbolList) do
        self:touchTripleReelSymbol(_reelIndex)
    end
end
function ScratchWinnerCardViewTriple:touchTripleReelSymbol(_reelIndex)
    if self.m_tripleData[_reelIndex] then
        return 
    end
    self.m_tripleData[_reelIndex] = true

    local symbolType = self.m_cardData.reels[_reelIndex]
    if self.m_machine.SYMBOL_Card1_Jackpot == symbolType then
        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_CardView_TripleBuling)

        local symbol = self.m_reelsSymbolList[_reelIndex]
        symbol:runAnim("buling")
    end
end
--[[
    重写接口
]]
function ScratchWinnerCardViewTriple:initCardViewSymbol()
    ScratchWinnerCardViewTriple.super.initCardViewSymbol(self)

    self.m_tripleData = {}
    --[[
        m_tripleData = {
            reelIndex = true, --触摸过的图标索引
        }
    ]]
end

function ScratchWinnerCardViewTriple:getAutoScrapePath()
    -- cc.size(600, 450) 
    -- cc.size(200, 150)
    local pathList = {
        {
            cc.p(10, 380),cc.p(100, 440),
            cc.p(200, 440),cc.p(10, 300),

            cc.p(10, 225),cc.p(300, 440),
            cc.p(400, 440),cc.p(10, 150),

            cc.p(10, 75),cc.p(500, 440),
            cc.p(590, 440),cc.p(10, 0),

            cc.p(100, 0),cc.p(590, 380),
            cc.p(590, 300),cc.p(200, 0),

            cc.p(300, 0),cc.p(590, 225),
            cc.p(590, 150),cc.p(500, 0),
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

function ScratchWinnerCardViewTriple:onTouchCoatingLayer(_obj, _event, _bInArea)
    ScratchWinnerCardViewTriple.super.onTouchCoatingLayer(self, _obj, _event, _bInArea)
    if not _bInArea then
        return
    end

    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(self.m_cardData.name)
    local symbolParent = self:findChild("reel")
    local touchNodePos = symbolParent:convertToNodeSpace( cc.p(_event.x, _event.y) )
    local brushRadius  = cardConfig.cardViewBrushRadius
    for _reelIndex,_reelSymbol in ipairs(self.m_reelsSymbolList) do
        if not self.m_tripleData[_reelIndex] then
            local symbolPos = cc.p(_reelSymbol:getPosition())
            local distance  = math.sqrt(math.pow(symbolPos.x-touchNodePos.x, 2) + math.pow(symbolPos.y-touchNodePos.y, 2))
            if distance < brushRadius then
                self:touchTripleReelSymbol(_reelIndex)
            end 
        end
    end
end

function ScratchWinnerCardViewTriple:playInLineNodesByIndex(_lineIndex)
    ScratchWinnerCardViewTriple.super.playInLineNodesByIndex(self, _lineIndex)
    local allLinePos     = {}
    local lineData = self.m_cardData.lines[_lineIndex]
    -- 全体连线
    if not lineData then
        allLinePos = self:getFirstLinePosList()
    -- 单条连线
    else
        for i,_reelPos in ipairs(lineData.icons) do
            local reelPos = _reelPos+1
            allLinePos[reelPos] = true
        end
    end
    
    local symbolList = self.m_reelsSymbolList
    for _reelPos,v in pairs(allLinePos) do
        local symbol = symbolList[_reelPos]
        local lineFrameCsb = symbol.m_animNode.m_lineFrameCsb
        lineFrameCsb:setVisible(true)
        lineFrameCsb:runCsbAction("actionframe", true)
    end
end
function ScratchWinnerCardViewTriple:playInLineNodesIdle()
    ScratchWinnerCardViewTriple.super.playInLineNodesIdle(self)

    local allLinePos     = {}
    for i,v in ipairs(self.m_cardData.lines) do
        for ii,_reelPos in ipairs(v.icons) do
            local reelPos = _reelPos+1
            allLinePos[reelPos] = true
        end
    end

    local symbolList = self.m_reelsSymbolList
    for _reelPos,v in pairs(allLinePos) do
        local symbol = symbolList[_reelPos]
        local lineFrameCsb = symbol.m_animNode.m_lineFrameCsb
        util_setCsbVisible(lineFrameCsb, false)
    end
end
function ScratchWinnerCardViewTriple:coatingOverCallBack()
    --把所有图标都摸一遍
    self:touchAllTripleReelSymbol()

    ScratchWinnerCardViewTriple.super.coatingOverCallBack(self)
end
function ScratchWinnerCardViewTriple:endCardGame()
    self.m_tripleData = {}

    ScratchWinnerCardViewTriple.super.endCardGame(self)
end

return ScratchWinnerCardViewTriple