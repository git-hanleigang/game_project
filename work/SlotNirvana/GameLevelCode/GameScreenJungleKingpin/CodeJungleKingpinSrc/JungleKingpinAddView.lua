---
--xcyy
--2018年5月23日
--JungleKingpinAddView.lua

local JungleKingpinAddView = class("JungleKingpinAddView", util_require("base.BaseView"))

JungleKingpinAddView.m_FeatureReel = nil
JungleKingpinAddView.m_featureOverCallBack = nil
JungleKingpinAddView.m_featureAddBonusFlyEffectCallBack = nil
JungleKingpinAddView.m_getNodeByTypeFromPool = nil
JungleKingpinAddView.m_pushNodeToPool = nil
JungleKingpinAddView.m_bigPoseidon = nil
JungleKingpinAddView.m_endValueIndex = nil
JungleKingpinAddView.m_endValue = nil
JungleKingpinAddView.m_winSound = nil
JungleKingpinAddView.m_wheelsData = nil
JungleKingpinAddView.m_bTouchEnable = nil
JungleKingpinAddView.m_bRunEnd = nil
local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 200, height = 300}
local SYMBOL_HEIGHT = 100
local REEL_SYMBOL_COUNT = 3

local ALL_RUN_SYMBOL_NUM = 50

JungleKingpinAddView.m_runDataPoint = nil
JungleKingpinAddView.m_allSymbols = nil

local BONUS_SYMBOL = 93

function JungleKingpinAddView:initUI(machine)
    self.m_machine = machine
    local resourceFilename = "JungleKingpin_AddReel.csb"
    self:createCsbNode(resourceFilename)
    self.effect = self:findChild("effectFile")
    self.m_effectAct = cc.CSLoader:createTimeline("WinFrameJungleKingpin_superfreespin_run.csb")
    self.effect:runAction(self.m_effectAct)
    util_csbPlayForKey(self.m_effectAct, "run", true)
end

function JungleKingpinAddView:initFirstSymbol(_Symbol)
    if self.m_wheelsData == nil then
        self.m_wheelsData = {}
    end
    for k, value in pairs(_Symbol) do
        local _tpye = value
        local wheel = {}
        wheel.type = _tpye
        self.m_wheelsData[#self.m_wheelsData + 1] = wheel
    end
    self:initWheelsData()
    self:initRuningPoint()
end

function JungleKingpinAddView:initWheelsData()
    local symbolList = {0, 1, 2, 3, 4, 5, 93}
    local RandomNum = 1
    for i = 1, ALL_RUN_SYMBOL_NUM, 1 do
        local data = xcyy.SlotsUtil:getArc4Random() % (#symbolList - 1) + 1
        if RandomNum >= 8 then
            local change = xcyy.SlotsUtil:getArc4Random() % 2
            if change == 0 then
                RandomNum = 1
                data = #symbolList
            end
        end
        local wheel = {}
        wheel.type = symbolList[data]
        if self.m_wheelsData == nil then
            self.m_wheelsData = {}
        end
        self.m_wheelsData[#self.m_wheelsData + 1] = wheel
        RandomNum = RandomNum + 1
    end
    self.m_runDataPoint = 1
end

function JungleKingpinAddView:initAllSymbol()
    self.m_allSymbols = {}
    local iSymbolsNum = ALL_RUN_SYMBOL_NUM
    for i = 1, iSymbolsNum, 1 do
        local type = self:getNextType()
        local data = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false)
        self.m_allSymbols[#self.m_allSymbols + 1] = data
        if i >= 50 then
            data.Last = true
            break
        end
    end
    local more = math.floor(REEL_SYMBOL_COUNT * 0.5)
    for i = 1, more, 1 do
        local type = self:getNextType()
        local data = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false)
        self.m_allSymbols[#self.m_allSymbols + 1] = data
    end

    self.m_FeatureReel:setAllRunSymbols(self.m_allSymbols)
end

function JungleKingpinAddView:initRuningPoint()
    self.m_runDataPoint = 1
end

function JungleKingpinAddView:getNextType()
    if self.m_runDataPoint > #self.m_wheelsData then
        self.m_runDataPoint = 1
    end

    local _type = self.m_wheelsData[self.m_runDataPoint].type
    self.m_runDataPoint = self.m_runDataPoint + 1

    return _type
end

function JungleKingpinAddView:setNodePoolFunc(getNodeFunc, pushNodeFunc)
    self.m_getNodeByTypeFromPool = getNodeFunc
    self.m_pushNodeToPool = pushNodeFunc
end

function JungleKingpinAddView:setOverCallBackFun(callFunc)
    self.m_featureOverCallBack = callFunc
end

function JungleKingpinAddView:setAddBonusFlyEffectCallBackFun(callFunc)
    self.m_featureAddBonusFlyEffectCallBack = callFunc
end

function JungleKingpinAddView:initFeatureUI()
    local reelNode = self:findChild("reelNode")
    local initReelData = self:getInitSequence()
    local featureReel = util_createView("CodeJungleKingpinSrc.JungleKingpinAddReel")
    reelNode:addChild(featureReel)
    self.m_FeatureReel = featureReel
    featureReel:init(TIME_IAMGE_SIZE.width, TIME_IAMGE_SIZE.height, self.m_getNodeByTypeFromPool, self.m_pushNodeToPool)

    local reelHeight = TIME_IAMGE_SIZE.height
    featureReel:initFirstSymbolBySymbols(initReelData, reelHeight)

    featureReel:initRunDate(
        nil,
        function()
            return self:getRunReelData()
        end
    )
    featureReel:setEndCallBackFun(
        function()
            self:runEndCallBack()
        end
    )

    featureReel:setPlayAddBonusFlyEffectCallBackFun(
        function()
            self:playAddBonusFlyEffectCallBack()
        end
    )

    local childs = self.m_FeatureReel.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        node:runAnim("idleframe", false, nil, 20)
    end
    self:initAllSymbol()
end

function JungleKingpinAddView:runEndCallBack()
    self.m_FeatureReel:playRunEndAnima()

    -- performWithDelay(self, function(  )
    if self.m_featureOverCallBack ~= nil then
        self.m_featureOverCallBack()
    end
    -- end,2.7)
end

function JungleKingpinAddView:playAddBonusFlyEffectCallBack()
    if self.m_featureAddBonusFlyEffectCallBack ~= nil then
        self.m_featureAddBonusFlyEffectCallBack()
    end
end
function JungleKingpinAddView:getRunReelData()
    local type = self:getNextType()
    local reelData = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false)
    return reelData
end

function JungleKingpinAddView:getReelData(zorder, width, height, symbolType, bLast)
    local reelData = util_require("data.slotsdata.SpecialReelData"):create()
    if symbolType == BONUS_SYMBOL then
        zorder = 100
    end
    reelData.Zorder = zorder
    reelData.Width = width
    reelData.Height = height
    reelData.SymbolType = symbolType
    reelData.Last = bLast
    return reelData
end

function JungleKingpinAddView:getInitSequence()
    local reelDatas = {}

    for i = 1, REEL_SYMBOL_COUNT, 1 do
        local type = self:getNextType()
        local data = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, type, false)
        reelDatas[#reelDatas + 1] = data
    end

    return reelDatas
end

function JungleKingpinAddView:transSymbolData(endValue)
    local jpType = nil
    if self.m_runDataPoint > #self.m_wheelsData then
        self.m_runDataPoint = 1
    end

    local type = endValue.type

    return type
end

function JungleKingpinAddView:getRunSequence(endValue)
    if self.m_bRunEnd == true then
        return nil
    end
    self.m_bRunEnd = true
    local reelDatas = {}
    local totleCount = 1
    local tempIndex = nil
    if self.m_runDataPoint > #self.m_wheelsData then
        tempIndex = 1
    else
        tempIndex = self.m_runDataPoint
    end
    if self.m_endValueIndex > tempIndex then
        totleCount = totleCount + self.m_endValueIndex - tempIndex
    elseif self.m_endValueIndex < tempIndex then
        totleCount = totleCount + #self.m_wheelsData + self.m_endValueIndex - tempIndex
    end

    local type = self:transSymbolData(endValue)
    for i = 1, totleCount do
        local symbolType = nil
        local bLast = nil

        if i == totleCount then
            symbolType = type
            bLast = true
            if self.m_runDataPoint > #self.m_wheelsData then
                self.m_runDataPoint = 1
            end
            self.m_runDataPoint = self.m_runDataPoint + 1
        else
            symbolType = self:getNextType()
            bLast = false
        end

        local reelData = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_HEIGHT, symbolType, bLast)

        reelDatas[#reelDatas + 1] = reelData
    end
    return reelDatas
end

function JungleKingpinAddView:beginMove()
    self.m_FeatureReel:beginMove()
end

function JungleKingpinAddView:onEnter()

end

function JungleKingpinAddView:onExit()
    local featureNode = self.m_FeatureReel
    featureNode:stopAllActions()
    featureNode:removeFromParent()
end

return JungleKingpinAddView
