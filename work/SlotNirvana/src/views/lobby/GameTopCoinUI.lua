--[[
    author:JohnnyFred
    time:2019-11-27 16:05:54
]]
local GameTopCoinUI = class("GameTopCoinUI",util_require("base.BaseView"))
GameTopCoinUI.m_bRotation = nil
GameTopCoinUI.m_bHorizontalScreen = nil

function GameTopCoinUI:initUI(bHorizontalScreen, bRotation)
    local csbName = "GameNode/GameTopCoin1.csb"
    if not bHorizontalScreen then
        csbName = "GameNode/GameTopCoinPortrait.csb"
    end

    self:createCsbNode(csbName)

    self:setCsbNodeScale(globalData.topUIScale)
    self.m_bHorizontalScreen = bHorizontalScreen
    self.m_bRotation = bRotation
    if self.m_bRotation then
        self:findChild("mainNode"):setRotation(90)
    end
    self.coinIcon = self:findChild("coinIcon")
    self.lbCoins = self:findChild("lbCoin")
    -- self.lbAddCoin = self:findChild("lbAddCoin")
    -- self.lbAddCoinPosX,self.lbAddCoinPosY = self.lbAddCoin:getPosition()
    -- self.uiList = 
    -- {
    --     {node = self.coinIcon},
    --     {node = self.lbCoins,alignX = 10},
    -- }
    -- local effectNode = self:findChild("effectNode")
    -- local refreshEffect = cc.ParticleSystemQuad:create("Lobby/Other/Shuzi.plist")
    -- self.refreshEffect = refreshEffect
    -- effectNode:addChild(refreshEffect)
    -- refreshEffect:setVisible(false)
    self:updateUI(nil)
end

function GameTopCoinUI:updateUI(coinValue)
    coinValue = coinValue or globalData.userRunData.coinNum
    local lbCoins = self.lbCoins
    lbCoins.coinValue = coinValue
    lbCoins:setString(util_getFromatMoneyStr(lbCoins.coinValue))
    self:updateLable(lbCoins)
    -- util_alignCenter(self.uiList)
    self:setAddValueVisible(false,nil)
end

function GameTopCoinUI:getCoinIconPos()
    local pos = self.coinIcon:getParent():convertToWorldSpace(cc.p(self.coinIcon:getPosition()))
    return pos
end

function GameTopCoinUI:refreshCoin(addValue,addCoinTime,callBack)
    local lbCoins = self.lbCoins
    local preValue = lbCoins.coinValue
    local curValue = addValue ~= nil and (preValue + addValue) or globalData.userRunData.coinNum
    lbCoins.coinValue = curValue
    local perAddValue = (curValue - preValue) / (addCoinTime * 30)
    -- self.refreshEffect:setVisible(true)
    -- self.refreshEffect:resetSystem()
    local function animCallBack()
        self:updateUI(curValue)
        performWithDelay(self,function(  )
            if callBack then
                callBack()
            end
        end,0.5)
    end
    util_jumpNumExtra(lbCoins,preValue,curValue,perAddValue,1 / 30,util_getFromatMoneyStr,{16},nil,nil,animCallBack,
    function()
        self:updateLable(lbCoins)
        -- util_alignCenter(self.uiList)
    end)
end

function GameTopCoinUI:updateLable(lbCoins)
    if not self.m_bHorizontalScreen then
        self:updateLabelSize({label = lbCoins, sx = 0.44 , sy= 0.44},269)
    else
        self:updateLabelSize({label = lbCoins, sx = 0.58 , sy= 0.58},333)
    end
end

function GameTopCoinUI:setAddValueVisible(flag,addValue)
    -- local lbAddCoin = self.lbAddCoin
    -- if flag then
    --     lbAddCoin:setPositionY(self.lbAddCoinPosY - 100)
    --     lbAddCoin:runAction(cc.MoveTo:create(0.5,cc.p(self.lbAddCoinPosX,self.lbAddCoinPosY)))
    --     lbAddCoin:setString(string.format("+%s",util_getFromatMoneyStr(tonumber(addValue))))
    -- end
    -- lbAddCoin:setVisible(flag)
end

function GameTopCoinUI:showAction()
    self:runCsbAction("idle",false)
end

function GameTopCoinUI:onEnter()
    -- gLobalNoticManager:addObserver(self,
    -- function(self,params)
    --     self:refreshCoin(nil,nil)
    -- end,ViewEventType.NOTIFY_TOPCOIN_UPDATE_COIN)
end

function GameTopCoinUI:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end
return GameTopCoinUI