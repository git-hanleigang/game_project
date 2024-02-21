local BaseStoreItemNum = class("BaseStoreItemNum", util_require("base.BaseView"))

BaseStoreItemNum.m_basecoinslab = nil
BaseStoreItemNum.m_itemData = nil
BaseStoreItemNum.m_currCoinsLb = nil
BaseStoreItemNum.m_linesp = nil

local COINS_SCALE_NUM = 215

-- 子类重写
function BaseStoreItemNum:getCsbName()
    return "Shop_Res/ZQCoinStoreLayer_number.csb"
end

-- 子类可重写
function BaseStoreItemNum:isDeleteLine()
    if self:getHasDiscount() then
        return true
    end
    if self:getPlayerDiscount() > 0 then
        return true
    end
    return false
end

-- 子类重写
function BaseStoreItemNum:getHasDiscount()
    return false
end

-- 子类重写
-- 玩家自身属性（不同玩家可能不同）对商城的加成：比如buff
function BaseStoreItemNum:getPlayerDiscount()
    return 0
end

-- 子类重写
-- 界面展示具体的金币数值
function BaseStoreItemNum:getShowCoins()
    local orginCoin, curCoin = self:getItemCoins()

    -- 特殊逻辑：
    local extraMul = self:getExtraMulti()
    if extraMul > 0 then
        curCoin = curCoin * (1 + extraMul)
    end

    return orginCoin, curCoin
end

function BaseStoreItemNum:getItemCoins()
    return 0, 0
end

function BaseStoreItemNum:getExtraMulti()
    local extraMul = 0

    -- 玩家自身属性对商城数值的影响
    local playerDis = self:getPlayerDiscount()
    if playerDis and playerDis > 0 then
        extraMul = extraMul + playerDis
    end

    return extraMul
end

function BaseStoreItemNum:initUI(itemData)
    self:updateItemData(itemData)
    self:createCsbNode(self:getCsbName())
    self:initCoinsUI()
end

function BaseStoreItemNum:updateItemData(itemData)
    self.m_itemData = itemData
end

function BaseStoreItemNum:runShowActions()
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle")
            self:updateLabelSize({label = self.m_currCoinsLb}, COINS_SCALE_NUM)
        end
    )
end

function BaseStoreItemNum:initCoinsUI()
    self.m_basecoinslab = self:findChild("m_coin_cut")
    self.m_currCoinsLb = self:findChild("shuzi")
    self.m_linesp = self:findChild("line")

    self:initCoinsLb()

    if self:isDeleteLine() then
        self:runShowActions()
    else
        self:runCsbAction("idle")
    end
end

function BaseStoreItemNum:updataCoinsLb()
    local baseCoins, coins = self:getShowCoins()
    local addValue = (coins - baseCoins) * 0.07 + math.random(1, 9) + math.random(1, 9) * 10 + math.random(1, 9) * 100

    util_jumpNum(self.m_currCoinsLb, baseCoins, coins, addValue, 0.02, {30})

    self:setDisCountNodePos()
end

function BaseStoreItemNum:setDisCountNodePos()
    if self:isDeleteLine() then
        local length = 130
        local baseCoins, coins = self:getShowCoins()

        self.m_basecoinslab:setVisible(true)
        self.m_basecoinslab:setString(util_formatMoneyStr(tostring(baseCoins)))
        self:updateLabelSize({label = self.m_basecoinslab, sx = 1.5, sy = 1.5}, length)

        local size = self.m_basecoinslab:getContentSize()
        local scaleX = self.m_basecoinslab:getScaleX()
        local sizeWidth = size.width * scaleX + 10

        self.m_linesp:setVisible(true)
        self.m_linesp:setContentSize(sizeWidth, 3)

        if globalData.slotRunData.isPortrait == true then
            self.m_currCoinsLb:setPositionY(-10)
        else
            self.m_currCoinsLb:setPositionY(0)
        end
    else
        self.m_linesp:setVisible(false)
        self.m_basecoinslab:setVisible(false)
        self.m_currCoinsLb:setPositionY(-20)
    end
end

function BaseStoreItemNum:initCoinsLb()
    local _, coins = self:getShowCoins()
    if globalData.slotRunData.isPortrait == true then
        self.m_currCoinsLb:setPositionY(-10)
    end
    self.m_currCoinsLb:setString(util_getFromatMoneyStr(coins))
    self:updateLabelSize({label = self.m_currCoinsLb}, COINS_SCALE_NUM)
    self:setDisCountNodePos()
end

return BaseStoreItemNum
