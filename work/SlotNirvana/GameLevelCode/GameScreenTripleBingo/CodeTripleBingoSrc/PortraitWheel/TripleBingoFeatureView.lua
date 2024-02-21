local TripleBingoFeatureView = class("TripleBingoFeatureView", util_require("base.BaseView"))
local PublicConfig = require "TripleBingoPublicConfig"
TripleBingoFeatureView.m_FeatureNode = nil
TripleBingoFeatureView.m_featureOverCallBack = nil
TripleBingoFeatureView.m_getNodeByTypeFromPool = nil
TripleBingoFeatureView.m_pushNodeToPool = nil
TripleBingoFeatureView.m_wheelsData = {"Coins", "Coins", "Mini", "Coins", "Coins", "Coins", "Minor", "Coins", "Coins", "Major", "Coins", "Coins", "Coins", "Mini", "Coins", "Coins", "Grand"}
TripleBingoFeatureView.m_wheelsTypeInfo = {
    ["Coins"] = {["showNode"] = {"m_lb_coins"}, ["specShow"] = {"coins0", "coins1"}},
    ["Mini"] = {["showNode"] = {"mini", "mini0"}},
    ["Minor"] = {["showNode"] = {"minor", "minor0"}},
    ["Major"] = {["showNode"] = {"major", "major0"}},
    ["Grand"] = {["showNode"] = {"grand", "grand0"}}
}
TripleBingoFeatureView.m_coinsMul = {3, 4, 5, 4, 2, 8, 15, 6, 9, 4, 3, 2}
TripleBingoFeatureView.m_runDataPoint = nil
TripleBingoFeatureView.m_allSymbols = nil

--配置滚动信息
TripleBingoFeatureView.TIME_IAMGE_SIZE = {width = 425, height = 720}
TripleBingoFeatureView.SYMBOL_HEIGHT = 240
TripleBingoFeatureView.REEL_SYMBOL_COUNT = 3
function TripleBingoFeatureView:initUI(_machine)
    self:createCsbNode("TripleBingo/GameScreenWheel.csb")
    self.m_coinsShowType = true
    self.m_machine = _machine

    self.m_jackPotBarView = util_createView("CodeTripleBingoSrc.TripleBingoJackPotBarView")
    self.m_jackPotBarView:initMachine(self.m_machine)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView)

    self.m_tapTip = util_createAnimation("TripleBingo_Wheel_title.csb")
    self:findChild("Node_title"):addChild(self.m_tapTip)
    self.m_tapTip:runCsbAction("idle",true)

    self.m_glow = util_spineCreate("GameScreenWheel_glow",true,true)
    self:findChild("Node_glow"):addChild(self.m_glow)
    self.m_glow:setVisible(false)

    self.m_bigWinView = util_spineCreate("TripleBingo_bigwin_tb", true, true)
    self:findChild("Node_glow2"):addChild(self.m_bigWinView)
    self.m_bigWinView:setVisible(false)

    self.m_light = util_createAnimation("TripleBingo/GameScreenWheel_0.csb")
    self:findChild("Node_tx"):addChild(self.m_light)
    self.m_light:setVisible(false)

    self.m_hand = util_spineCreate("TripleBingo_xinshou",true,true)
    self:findChild("xinshou"):addChild(self.m_hand)
    util_spinePlay(self.m_hand,"idleframe",true)

    self.m_runDataPoint = 16 -- 因为初始就必须是grand在中间
    self:setNodePoolFunc()
    self:initFeatureUI()

end

function TripleBingoFeatureView:getReelEndType(_data)
    if type(_data) == "number" then
        return "Coins"
    else
        return _data
    end
end

function TripleBingoFeatureView:initAllSymbol()
    local wheelData = self.m_machine:getWheelGameData()
    local endData   = wheelData.endData
    self.m_allSymbols = {}
    self.endData    = endData or {"Major", 36000, 54000}
    local endType   = self:getReelEndType(self.endData[2])
    self.m_runDataPoint = math.random(1,#self.m_wheelsData) -- 组织最终数据时，重新随机一下，保证体验真实感
    -- 先把真实数据塞上去 不用服务器发的了，自己写一样的效果,保证最终值正确且符合数值给的假滚即可
    while true do
        local symType = self.m_wheelsData[self.m_runDataPoint]
        if symType == endType then
            self.m_allSymbols[#self.m_allSymbols + 1] = self:getRunReelData(true)
            self.m_allSymbols[#self.m_allSymbols + 1] = self:getRunReelData(false)
            break
        else
            self.m_allSymbols[#self.m_allSymbols + 1] = self:getRunReelData(false)
        end
    end

    local allNum = 31 -- 滚动的真实长度
    -- 在根据数据塞假的
    if #self.m_allSymbols < allNum then
        self.m_runDataPoint = self.m_runDataPoint - 1 -- 因为自动累加了所以指针应该先减一才是当前的位置
        local addNum = allNum - #self.m_allSymbols
        local index = 1
        while true do
            if index > #self.m_allSymbols  then
                table.insert(self.m_allSymbols, 1, self:getRunReelData(false))
                if self.m_runDataPoint == 1 then
                    self.m_runDataPoint = #self.m_wheelsData - 1 
                elseif self.m_runDataPoint == 2 then
                    self.m_runDataPoint = #self.m_wheelsData 
                else
                    self.m_runDataPoint = self.m_runDataPoint - 2
                end
            else
                if self.m_runDataPoint <= 1 then
                    self.m_runDataPoint = #self.m_wheelsData + 1
                end
                self.m_runDataPoint = self.m_runDataPoint - 1
            end
            
            index = index + 1
            if index > allNum then
                break
            end
        end

    elseif #self.m_allSymbols > allNum then
        local cutNum = allNum - #self.m_allSymbols
        for i = #self.m_allSymbols, 1, -1 do
            if i < cutNum then
                table.remove(self.m_allSymbols, i)
            end
        end
    end

    -- 最后在塞一个补位的，以免回弹显着空
    self.m_allSymbols[#self.m_allSymbols + 1] = self:getRunReelData(false)
end

function TripleBingoFeatureView:getNextType()
    if self.m_runDataPoint > #self.m_wheelsData then
        self.m_runDataPoint = 1
    end
    local jpType = self.m_wheelsData[self.m_runDataPoint]
    self.m_runDataPoint = self.m_runDataPoint + 1
    if self.m_runDataPoint > #self.m_wheelsData then
        self.m_runDataPoint = 1
    end
    return jpType
end

function TripleBingoFeatureView:setNodePoolFunc()
    self.m_getNodeByTypeFromPool = function(symbolType, nextNodeData)
        local node = util_createAnimation("TripleBingo_Wheel_wins.csb")
        local showInfo = self.m_wheelsTypeInfo[symbolType]
        local childs = node:findChild("Node_bg"):getChildren()
        local showNode = showInfo.showNode
        local specShow = showInfo.specShow
        for i = 1, #childs do
            local tarNode = childs[i]
            local tarNodeName = tarNode:getName()
            tarNode:setVisible(table_vIn(showNode, tarNodeName))
        end
        if specShow then
            node:findChild(specShow[1]):setVisible(not self.m_coinsShowType)
            node:findChild(specShow[2]):setVisible(self.m_coinsShowType)
            self.m_coinsShowType = not self.m_coinsShowType
        end

        if nextNodeData.JpScore then
            local lab = util_getChildByName(node, "m_lb_coins")
            if lab ~= nil then
                lab:setString(util_coinsLimitLen(nextNodeData.JpScore, 3))
            end
        end

        return node
    end

    self.m_pushNodeToPool = function(targSp)
    end
end

function TripleBingoFeatureView:setOverCallBackFun(callFunc)
    self.m_featureOverCallBack = callFunc
end

function TripleBingoFeatureView:initFeatureUI()
    local jpNode = self:findChild("Node_Reel")

    local initReelData = self:getInitSequence()

    local featureNode = util_createView("CodeTripleBingoSrc.PortraitWheel.TripleBingoFeatureNode")
    jpNode:addChild(featureNode)
    featureNode:init(self.TIME_IAMGE_SIZE.width, self.TIME_IAMGE_SIZE.height, self.m_getNodeByTypeFromPool, self.m_pushNodeToPool, self.TIME_IAMGE_SIZE.uiheight, self.TIME_IAMGE_SIZE.decelerNum)
    featureNode:initFirstSymbolBySymbols(initReelData)
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

function TripleBingoFeatureView:setEndValue()
    self:initAllSymbol()

    self.m_FeatureNode:setresDis(120)
    self.m_FeatureNode:setAllRunSymbols(self.m_allSymbols)
end

function TripleBingoFeatureView:runEndCallBack()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_21)

    self.m_light:runCsbAction("over",false,function()
        self.m_light:setVisible(false)
    end)

    -- 播放中奖动画
    util_spinePlay(self.m_glow,"idle3",true)

    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idle3",true)
    end)

    self.m_bigWinView:setVisible(true)
    util_spinePlay(self.m_bigWinView,"actionframe2")
    util_spineEndCallFunc(self.m_bigWinView,"actionframe2",function()
        performWithDelay(self,function()
            if self.m_featureOverCallBack then
                self.m_featureOverCallBack()
            end 
        end,0)
    end)
end

function TripleBingoFeatureView:getRunReelData(_isLast)
    local reelData = {}
    reelData.index = self.m_runDataPoint
    reelData.SymbolType = self:getNextType()
    if reelData.SymbolType == "Coins" then
        if _isLast then
            reelData.JpScore = self.endData[2] 
        else
            reelData.JpScore = self.m_coinsMul[math.random(1, #self.m_coinsMul)] * globalData.slotRunData:getCurTotalBet()
        end
    end
    reelData.Zorder = 1
    reelData.Width = self.TIME_IAMGE_SIZE.width
    reelData.Height = self.SYMBOL_HEIGHT
    reelData.Last = _isLast
    return reelData
end

function TripleBingoFeatureView:getInitSequence()
    local reelDatas = {}

    for i = 1, self.REEL_SYMBOL_COUNT, 1 do
        reelDatas[#reelDatas + 1] = self:getRunReelData(false)
    end

    return reelDatas
end

function TripleBingoFeatureView:removeFeatureNode()
    local featureNode = self.m_FeatureNode
    featureNode:stopAllActions()
    featureNode:removeFromParent()
end

function TripleBingoFeatureView:beginMove()
    self.m_FeatureNode:initAction()
    self.m_FeatureNode:beginMove()

    self.m_light:setVisible(true)
    self.m_light:runCsbAction("start",false,function()
        self.m_light:runCsbAction("idle",true)
    end)
end

function TripleBingoFeatureView:showWheelView()
    -- self:runCsbAction("start",false,function()
        self:addClick(self:findChild("Panel_1"))
    -- end)  
end

--默认按钮监听回调
function TripleBingoFeatureView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_1" then

        self.m_hand:setVisible(false)
        self.m_tapTip:runCsbAction("switch",false,function()
            self.m_tapTip:runCsbAction("idle2",true)
        end)
        self:runCsbAction("idle2",true)
        sender:setTouchEnabled(false)
        self.m_glow:setVisible(true)
        util_spinePlay(self.m_glow,"idle2",true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_6"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_20)
        self:beginMove()
        performWithDelay(self:findChild("root"),function()
            self:setEndValue()
        end,2)
    end
end
return TripleBingoFeatureView
