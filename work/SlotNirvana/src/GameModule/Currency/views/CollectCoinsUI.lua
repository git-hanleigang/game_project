--[[
    author:JohnnyFred
    time:2019-11-27 16:05:54
]]
local CollectCoinsUI = class("CollectCoinsUI", util_require("base.BaseView"))

function CollectCoinsUI:initUI(bRotation)
    local isPortrait = globalData.slotRunData.isPortrait
    local csbName = "GameNode/GameTopCoin1.csb"
    if isPortrait then
        csbName = "GameNode/GameTopCoinPortrait.csb"
    end

    self:createCsbNode(csbName)

    self:setCsbNodeScale(globalData.topUIScale)
    self.m_isPortrait = isPortrait
    self.m_bRotation = bRotation
    if self.m_bRotation then
        self:findChild("mainNode"):setRotation(90)
    end
    self.coinIcon = self:findChild("coinIcon")
    self.lbCoins = self:findChild("lbCoin")


end

function CollectCoinsUI:updateUI(coinValue)
    assert(coinValue, "coin value is nil!!!")

    local lbCoins = self.lbCoins
    lbCoins.coinValue = coinValue
    self.m_curValue = coinValue
    lbCoins:setString(util_formatBigNumCoins(lbCoins.coinValue))
    self:updateLable(lbCoins)

    self:setAddValueVisible(false, nil)
end

function CollectCoinsUI:refreshValue(addValue, addCoinTime, callBack)
    local lbCoins = self.lbCoins
    local preValue = toLongNumber(lbCoins.coinValue)
    local curValue = addValue ~= nil and (preValue + addValue) or globalData.userRunData.coinNum
    lbCoins.coinValue = curValue
    self.m_curValue = curValue
    local perAddValue = toLongNumber(curValue - preValue) / (addCoinTime * 30)

    local function animCallBack()
        self:updateUI(curValue)
        performWithDelay(
            self,
            function()
                if callBack then
                    callBack()
                end
            end,
            0.5
        )
    end
    util_jumpNumExtra(
        lbCoins,
        preValue,
        curValue,
        perAddValue,
        1 / 30,
        util_getFromatMoneyStr,
        {16},
        nil,
        nil,
        animCallBack,
        function()
            self:updateLable(lbCoins)
            self:setFinalValue()
        end
    )
end

function CollectCoinsUI:updateLable(lbCoins)
    if self.m_isPortrait then
        self:updateLabelSize({label = lbCoins, sx = 0.44, sy = 0.44}, 269)
    else
        self:updateLabelSize({label = lbCoins, sx = 0.58, sy = 0.58}, 333)
    end
end

function CollectCoinsUI:setAddValueVisible(flag, addValue)
end

function CollectCoinsUI:showAction()
    self:runCsbAction("idle", false)
end

function CollectCoinsUI:setFinalValue()
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        mgr:setCoins(self.m_curValue, true)
    end
end

return CollectCoinsUI
