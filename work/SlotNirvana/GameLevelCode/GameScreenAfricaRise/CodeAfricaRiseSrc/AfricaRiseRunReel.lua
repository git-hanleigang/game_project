local AfricaRiseRunReel = class("AfricaRiseRunReel", util_require("base.BaseView"))

AfricaRiseRunReel.m_FeatureNode = nil
AfricaRiseRunReel.m_featureOverCallBack = nil
AfricaRiseRunReel.m_getNodeByTypeFromPool = nil
AfricaRiseRunReel.m_pushNodeToPool = nil
AfricaRiseRunReel.m_bigPoseidon = nil
AfricaRiseRunReel.m_endValueIndex = nil
AfricaRiseRunReel.m_endValue = nil
AfricaRiseRunReel.m_winSound = nil
AfricaRiseRunReel.m_sendDataFunc = nil
AfricaRiseRunReel.m_wheelsData = nil
AfricaRiseRunReel.m_bTouchEnable = nil
AfricaRiseRunReel.m_bRunEnd = nil

local FeatureNode_Count = 0

local TIME_IAMGE_SIZE = {width = 350, height = 620}
local SYMBOL_WIDTH = 260
local REEL_SYMBOL_COUNT = 12
--配置滚动信息
local BASE_RNN_COUNT = 3
local OFF_RUN_COUNT = 3
local JACKPOT_COUNT = 2

local ALL_RUN_SYMBOL_NUM = 100

AfricaRiseRunReel.m_runDataPoint = nil
AfricaRiseRunReel.m_allSymbols = nil


function AfricaRiseRunReel:initUI()
    if REEL_SYMBOL_COUNT % 2 == 0 then
        REEL_SYMBOL_COUNT = REEL_SYMBOL_COUNT + 1
    end
    self.m_bTouchEnable = false
    self.m_bRunEnd = false
    local resourceFilename = "AfricaRise_gundong_Reel.csb"
    self:createCsbNode(resourceFilename)
    self:initWheelsData()
    self.m_ReelBg = util_spineCreate("AfricaRise_gundong", true, true)
    self:findChild("Node"):addChild(self.m_ReelBg, 1)
    util_spinePlay(self.m_ReelBg, "idleframe1", true)

    self.m_ReelFrameBg = util_createView("CodeAfricaRiseSrc.AfricaRiseReelFrameBg")
    self:findChild("Node"):addChild(self.m_ReelFrameBg, 2)
    
    self.m_ReelFrameEff = util_createAnimation("AfricaRise_gundong_frame_bg_0.csb")
    self:findChild("Node"):addChild(self.m_ReelFrameEff, 4)

    self.m_ReelFrame = util_createAnimation("AfricaRise_gundong_frame.csb")
    self:findChild("Node"):addChild(self.m_ReelFrame, 5)
    self.m_ReelFrame:playAction("idleframe1", true)
    self:initRuningPoint()
end

function AfricaRiseRunReel:setMachine(machine)
    self.m_machine = machine
end

function AfricaRiseRunReel:initWheelsData()
    local hSymbolList = {3,0,1,2,4}
    local lSymbolList = {8,7,6,5}
    if self.m_wheelsData == nil then
        self.m_wheelsData = {}
    end
    local lNum = 1
    local hNum = 1
    for i = 1, ALL_RUN_SYMBOL_NUM, 1 do
        local _type = 0
        local wheel = {}
        if i%2 == 1 then
            if hNum > #hSymbolList then
                hNum = 1
            end
            wheel.type= hSymbolList[hNum]
            hNum = hNum + 1
        else
            if lNum > #lSymbolList then
                lNum = 1
            end
            wheel.type= lSymbolList[lNum]
            lNum = lNum + 1
        end
        self.m_wheelsData[#self.m_wheelsData + 1] = wheel
    end
    self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function AfricaRiseRunReel:initAllSymbol(endValue)
    self.m_runDataPoint = 1
    self.m_allSymbols = {}
    self.m_endValue = endValue
    local endType = self:getSymbolType(endValue)
    --插入临时片段防止两个一样的挨上
    local tempList =  self:getTempNodeList(endType)
    local tempNum = 1
    for i = 1, ALL_RUN_SYMBOL_NUM, 1 do
        local type = self:getNextType()
        local data = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_WIDTH, type, false)
        self.m_allSymbols[#self.m_allSymbols + 1] = data
        -- if  endType == data.SymbolType and i > 50 then
        if i >= 65 and i <= 71  then
            data.SymbolType = tempList[tempNum]
            tempNum = tempNum + 1
            if   i == 68 then --固定位置 才会有减速效果
                print("AfricaRiseRunReel ============ iii ====" .. i)
                data.SymbolType = endType 
                data.Last = true
            end
            if i == 71 then
                break
            end
        end

    end
    local more = math.floor(REEL_SYMBOL_COUNT * 0.5)
    for i = 1, more, 1 do
        local type = self:getNextType()
        local data = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_WIDTH, type, false)
        self.m_allSymbols[#self.m_allSymbols + 1] = data
    end
end
function AfricaRiseRunReel:getTempNodeList( endType )
    local hSymbolList = {3,0,1,2,4}
    local lSymbolList = {8,7,6,5}
    local lFirst = false --低级图标打头
    if endType < 5 then
        lFirst = true
    end
    local tempList ={}
    local lowType =  0
    local highType = 0 
    for i=1,7 do
        local _type = 0
        if lFirst then
            if i%2 == 1 then
                _type = self:getLowSymbol(lowType,endType)
                lowType = _type
            else
                _type = self:getHighSymbol(highType,endType)
                highType = _type
            end
        else
            if i%2 == 1 then
                _type = self:getHighSymbol(highType,endType)
                highType = _type
             else
                _type = self:getLowSymbol(lowType,endType)
                lowType = _type
             end
        end
        tempList[#tempList + 1] = _type
    end
    return tempList
end

function AfricaRiseRunReel:getHighSymbol(_type,_endType)
    local hSymbolList = {3,0,1,2,4}
    while true do
        local index =  xcyy.SlotsUtil:getArc4Random() % #hSymbolList + 1
        local _symbolType = hSymbolList[index]
        if _type ~= _symbolType and _symbolType ~= _endType then
            return _symbolType
        end
    end

end

function AfricaRiseRunReel:getLowSymbol(_type,_endType)
    local lSymbolList = {8,7,6,5}
    while true do
        local index =  xcyy.SlotsUtil:getArc4Random() % #lSymbolList + 1
        local _symbolType = lSymbolList[index]
        if _type ~= _symbolType and _symbolType ~= _endType then
            return _symbolType
        end
    end

end

function AfricaRiseRunReel:getSymbolType(endValue)
    local type = endValue.type
    return type
end

function AfricaRiseRunReel:initRuningPoint()
    self.m_runDataPoint = xcyy.SlotsUtil:getArc4Random() % #self.m_wheelsData + 1
end

function AfricaRiseRunReel:getNextType()
    if self.m_runDataPoint > #self.m_wheelsData then
        self.m_runDataPoint = 1
    end

    local _type = self.m_wheelsData[self.m_runDataPoint].type
    self.m_runDataPoint = self.m_runDataPoint + 1

    return _type
end

function AfricaRiseRunReel:setNodePoolFunc(getNodeFunc, pushNodeFunc)
    self.m_getNodeByTypeFromPool = getNodeFunc
    self.m_pushNodeToPool = pushNodeFunc
end

function AfricaRiseRunReel:setSendDataFunc(sendDataFunc)
    self.m_sendDataFunc = sendDataFunc
end

function AfricaRiseRunReel:setOverCallBackFun(callFunc)
    self.m_featureOverCallBack = callFunc
end

function AfricaRiseRunReel:initFeatureUI()
    local node = self:findChild("Node")
    local initReelData = self:getInitSequence()

    local featureNode = util_createView("CodeAfricaRiseSrc.AfricaRiseRunNode")
    node:addChild(featureNode,3)
    featureNode:setMachine(self.m_machine)
    featureNode:setParentMachine(self)
    featureNode:init(1400, TIME_IAMGE_SIZE.height, self.m_getNodeByTypeFromPool, self.m_pushNodeToPool)

    local reelHeight = TIME_IAMGE_SIZE.width
    featureNode:initFirstSymbolBySymbols(initReelData, reelHeight)

    featureNode:initRunDate(
        nil,
        function()
            return self:getRunReelData()
        end
    )
    featureNode:setEndCallBackFun(
        function()
            self:runEndCallBack()
        end
    )

    self.m_FeatureNode = featureNode

end

function AfricaRiseRunReel:setEndValue(endValue)
    self:initAllSymbol(endValue)
    self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
end

function AfricaRiseRunReel:runEndCallBack()
    local winCoins = 0
    self.m_FeatureNode:playRunEndAnima()
    if self.m_featureOverCallBack ~= nil then
        self.m_featureOverCallBack()
    end
end

function AfricaRiseRunReel:getRunReelData()
    local type = self:getNextType()
    local reelData = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_WIDTH, type, false)
    return reelData
end

function AfricaRiseRunReel:getReelData(zorder, width, height, symbolType, bLast)
    local reelData = util_require("data.slotsdata.SpecialReelData"):create()
    reelData.Zorder = zorder
    reelData.Width = width
    reelData.Height = height
    reelData.SymbolType = symbolType
    reelData.Last = bLast
    return reelData
end

function AfricaRiseRunReel:getInitSequence()
    local reelDatas = {}

    for i = 1, REEL_SYMBOL_COUNT, 1 do
        local type = self:getNextType()
        local data = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_WIDTH, type, false)
        reelDatas[#reelDatas + 1] = data
    end

    return reelDatas
end

function AfricaRiseRunReel:transSymbolData(endValue)
    local jpType = nil
    if self.m_runDataPoint > #self.m_wheelsData then
        self.m_runDataPoint = 1
    end

    local type = endValue.type

    return type
end

function AfricaRiseRunReel:getRunSequence(endValue)
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

        local reelData = self:getReelData(1, TIME_IAMGE_SIZE.width, SYMBOL_WIDTH, symbolType, bLast)

        reelDatas[#reelDatas + 1] = reelData
    end
    return reelDatas
end

function AfricaRiseRunReel:playWinEffect()
    util_spinePlay(self.m_ReelBg, "zhongjiang", false)
    self.m_ReelFrameBg:runCsbAction("zhongjiang")
   
end

function AfricaRiseRunReel:changeToWild()
    self.m_FeatureNode:changeToWild()
end


function AfricaRiseRunReel:InitBeginMove()
  
    self.m_FeatureNode:initBeginAction()
    self.m_FeatureNode:initAction()
end
function AfricaRiseRunReel:changeSymbolBg()
    self.m_FeatureNode:changeSymbolBg()
    self:changeFrameBg()
end

function AfricaRiseRunReel:beginMove()
   
    util_spinePlay(self.m_ReelBg, "actionframe", false)
    self.m_FeatureNode:playScaleToBig()

    self.m_ReelFrameBg:runCsbAction("actionframe", false)
    self.m_ReelFrame:playAction("actionframe", false,function(  )
        self.m_FeatureNode:beginMove()
        self.m_ReelFrame:playAction("idleframe2", true)
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:removeEventListenersForTarget(self, true)
        self.m_ReelFrameEff:playAction("idleframe2", true)
    end)

end

function AfricaRiseRunReel:playOver()
    util_spinePlay(self.m_ReelBg, "over", false)
    util_spineEndCallFunc(
        self.m_ReelBg,
        "over",
        function()
            util_spinePlay(self.m_ReelBg, "idleframe1", true)
        end
    )
    self.m_ReelFrameBg:runCsbAction("over", false)

    self.m_ReelFrame:playAction("over", false,function (  )
        self.m_ReelFrame:playAction("idleframe1", true)
    end)
    self.m_FeatureNode:playScaleToSmall()
    self.m_ReelFrameEff:playAction("over", true)
end


function AfricaRiseRunReel:playEffOver()
    self.m_ReelFrame:playAction("zhongjiang", false)
end

function AfricaRiseRunReel:playFlyWild()
    self.m_ReelFrameEff:playAction("fly", false)
end

function AfricaRiseRunReel:onEnter()
    local function onTouchBegan_callback(touch, event)
        if self.m_bTouchEnable == true then
            self.m_bTouchEnable = false
            return true
        end
        return false
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        if self.m_sendDataFunc ~= nil then
            self.m_sendDataFunc()
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function AfricaRiseRunReel:onExit()
    local featureNode = self.m_FeatureNode
    featureNode:stopAllActions()
    featureNode:removeFromParent()
end

function AfricaRiseRunReel:changeFrameBg()
    self.m_ReelFrameBg:changeFrameBg()
    self:changeReelBg()
end

function AfricaRiseRunReel:changeReelBg()
    self.m_ReelBg:removeFromParent()
    self.m_ReelBg = nil
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_ReelBg = util_spineCreate("AfricaRise_gundong_free", true, true)
        self:findChild("Node"):addChild(self.m_ReelBg, 1)
        util_spinePlay(self.m_ReelBg, "idleframe1", true)
    else
        self.m_ReelBg = util_spineCreate("AfricaRise_gundong", true, true)
        self:findChild("Node"):addChild(self.m_ReelBg, 1)
        util_spinePlay(self.m_ReelBg, "idleframe1", true)
    end
end

return AfricaRiseRunReel
