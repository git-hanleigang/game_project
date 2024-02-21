local ScratchWinnerCardViewLotto = class("ScratchWinnerCardViewLotto", util_require("CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewBase"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"

--[[
    交替展示的tips
]]
function ScratchWinnerCardViewLotto:upDateTip()
    self:stopUpDateTip()

    local tip_1 = self:findChild("shuoming1")
    local tip_2 = self:findChild("shuoming2")
    --渐变时间
    local fadeTime   = 0.5
    --持续时间
    local delayTime  = 3
    
    local sequence_1 = cc.Sequence:create(
        cc.FadeIn:create(fadeTime), 
        cc.DelayTime:create(delayTime), 
        cc.FadeOut:create(fadeTime), 
        cc.DelayTime:create(delayTime)
    )
    local sequence_2 = cc.Sequence:create(
        cc.FadeOut:create(fadeTime), 
        cc.DelayTime:create(delayTime), 
        cc.FadeIn:create(fadeTime), 
        cc.DelayTime:create(delayTime)
    )
    
    tip_1:setOpacity(255)
    tip_2:setOpacity(0)
    tip_1:runAction( cc.RepeatForever:create(sequence_1) )
    tip_2:runAction( cc.RepeatForever:create(sequence_2) )
end
function ScratchWinnerCardViewLotto:stopUpDateTip()
    local tip_1 = self:findChild("shuoming1")
    local tip_2 = self:findChild("shuoming2")

    tip_1:stopAllActions()
    tip_2:stopAllActions()
end
--[[
    卡片的paytable
]]
function ScratchWinnerCardViewLotto:initLottoPaytable()
    self.m_lottoPaytable = util_createAnimation("ScratchWinner_lottoluck_paytable.csb") 
    self:findChild("Node_paytable"):addChild(self.m_lottoPaytable)
    self.m_lottoPaytable:runCsbAction("idle", false)
end

--[[
    灯光spine
]]
function ScratchWinnerCardViewLotto:initLightSpine()
    local spineParent = self:findChild("Node_cardSpine")
    self.m_lightSpine = util_spineCreate("ScratchWinner_lottoluck_deng",true,true)
    spineParent:addChild(self.m_lightSpine)

    util_spinePlay(self.m_lightSpine, "idle", false)
end
--[[
    侧边两个jackpot栏的效果
]]
function ScratchWinnerCardViewLotto:initJackpotLight()
    self.m_jackpotEffLeft = util_createAnimation("ScratchWinner_lottoluck_jackpotwin.csb") 
    self:findChild("jackpotwin1"):addChild(self.m_jackpotEffLeft)

    self.m_jackpotEffRight = util_createAnimation("ScratchWinner_lottoluck_jackpotwin.csb") 
    self:findChild("jackpotwin2"):addChild(self.m_jackpotEffRight)

    self:playLottoJackpotEff({})
end
function ScratchWinnerCardViewLotto:playLottoJackpotEff(_posList)
    local jackpot1 = self:findChild("jackpotwin1")
    local jackpot2 = self:findChild("jackpotwin2")
    jackpot1:setVisible(false)
    jackpot2:setVisible(false)
    for i,_reelPos in ipairs(_posList) do
        if 1 == _reelPos or 9 == _reelPos then
            jackpot1:setVisible(true)
        elseif 3 == _reelPos or 7 == _reelPos then
            jackpot2:setVisible(true)
        end
    end

    if jackpot1:isVisible() then
        self.m_jackpotEffLeft:runCsbAction("idleframe", true)
    end
    if jackpot2:isVisible() then
        self.m_jackpotEffRight:runCsbAction("idleframe", true)
    end
end

--[[
    重写接口
]]
function ScratchWinnerCardViewLotto:initUI(_cardConfig)
    ScratchWinnerCardViewLotto.super.initUI(self, _cardConfig)

    self:initLottoPaytable()
    self:initLightSpine()
    self:initJackpotLight()
end
function ScratchWinnerCardViewLotto:playCardViewShow(_bDifferent, _bReconnect)
    ScratchWinnerCardViewLotto.super.playCardViewShow(self, _bDifferent, _bReconnect)

    self:upDateTip()
    self:playLottoJackpotEff({})
    self.m_lottoPaytable:runCsbAction("idle", false)

    self.m_lightSpine:setVisible(true)
    util_spinePlay(self.m_lightSpine, "idle", false)
end

-- 返回一条路线 --子类自己重写
function ScratchWinnerCardViewLotto:getAutoScrapePath()
    -- cc.size(480, 420) 
    -- cc.size(160, 140)
    local pathList = {
        {
            cc.p(0, 350),cc.p(80, 420),
            cc.p(160, 420),cc.p(0, 280),

            cc.p(0, 210),cc.p(240, 420),
            cc.p(320, 420),cc.p(0, 140),

            cc.p(0, 70),cc.p(400, 420),
            cc.p(480, 420),cc.p(0, 0),
--
            cc.p(80, 0),cc.p(480, 350),
            cc.p(480, 280),cc.p(160, 0),

            cc.p(240, 0),cc.p(480, 210),
            cc.p(480, 140),cc.p(400, 0),
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

function ScratchWinnerCardViewLotto:showLineFrame(_winCoins)
    ScratchWinnerCardViewLotto.super.showLineFrame(self, _winCoins)

    if _winCoins <= 0 then
        self.m_lightSpine:setVisible(false)
    end
end
function ScratchWinnerCardViewLotto:playInLineNodes()
    ScratchWinnerCardViewLotto.super.playInLineNodes(self)
    -- 连线列表 找到paytable需要高亮的位置
    local paytableSymbolType = {}
    for i,v in ipairs(self.m_cardData.lines) do
        for ii,_reelPos in ipairs(v.icons) do
            local reelPos = _reelPos + 1
            local reelSymbolType = self.m_cardData.reels[reelPos]
            paytableSymbolType[reelSymbolType] = true
        end
    end

    local lineFrameParent = self.m_lottoPaytable:findChild("Node_lineFrame")
    local children = lineFrameParent:getChildren() 
    for i,v in ipairs(children) do
        v:setVisible(false)
    end
    for _symbolType,v in pairs(paytableSymbolType) do
        local nodeName = string.format("%d", _symbolType-200)
        local node = self.m_lottoPaytable:findChild(nodeName)
        node:setVisible(true)
    end

    if nil ~= next(paytableSymbolType) then
        self.m_lottoPaytable:runCsbAction("actionframe", false)
        self.m_lightSpine:setVisible(true)
        util_spinePlay(self.m_lightSpine, "actionframe", true)
    end
end
function ScratchWinnerCardViewLotto:playInLineNodesByIndex(_lineIndex)
    ScratchWinnerCardViewLotto.super.playInLineNodesByIndex(self, _lineIndex)
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
function ScratchWinnerCardViewLotto:playInLineNodesIdle()
    ScratchWinnerCardViewLotto.super.playInLineNodesIdle(self)

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

function ScratchWinnerCardViewLotto:showJackpotLineEffect(_winCoins)
    ScratchWinnerCardViewLotto.super.showJackpotLineEffect(self, _winCoins)
    --拿jackpot的位置
    local jackpotPos = {}

    for i,v in ipairs(self.m_cardData.lines) do
        if "jackpot" == v.kind then
            for ii,_reelPos in ipairs(v.icons) do
                table.insert(jackpotPos, _reelPos+1)
            end
        end
    end

    self:playLottoJackpotEff(jackpotPos)
end

function ScratchWinnerCardViewLotto:endCardGame()
    self:stopUpDateTip()
    ScratchWinnerCardViewLotto.super.endCardGame(self)
end

return ScratchWinnerCardViewLotto