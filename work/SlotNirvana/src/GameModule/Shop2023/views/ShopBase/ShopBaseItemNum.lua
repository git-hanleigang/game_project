local ShopBaseItemNum = class("ShopBaseItemNum", util_require("base.BaseView"))

ShopBaseItemNum.m_baseNumberLabel = nil
ShopBaseItemNum.m_itemData = nil
ShopBaseItemNum.m_currNumberLabel = nil
ShopBaseItemNum.m_linesp = nil

local COINS_SCALE_NUM = 310

function ShopBaseItemNum:initUI(_itemData, _type, _index)
    
    self.m_itemData = _itemData
    self.m_type = _type
    self.m_index = _index or 0
    -- self:updateItemData(_itemData)
    self:createCsbNode(self:getCsbName())
    self:initView(_itemData)
end

function ShopBaseItemNum:initView(_itemData)
    self:updateItemData(_itemData)
end

-- 子类重写
function ShopBaseItemNum:getCsbName()
    return SHOP_RES_PATH.ItemNumber
end

function ShopBaseItemNum:initCsbNodes()
    self.m_baseNumberLabel = self:findChild("lb_coin_cut")
    self.m_currNumberLabel = self:findChild("shuzi")
    self.m_linesp = self:findChild("sp_line")
    self.m_nodeBase = self:findChild("node_base")
    self.m_nodeCur = self:findChild("node_curr")
    self.m_sprCoin = self:findChild("sp_coin")
    self.m_nodeBase:setVisible(false)
end

-- 子类可重写
function ShopBaseItemNum:initDescNode()
end

-- 子类可重写
function ShopBaseItemNum:isDisCount()
    if self:getHasDiscount() then
        return true
    end
    if self:getPlayerDiscount() > 0 then
        return true
    end
    return false
end

-- 子类重写
function ShopBaseItemNum:getHasDiscount()
    return false
end

-- 子类重写
-- 玩家自身属性（不同玩家可能不同）对商城的加成：比如buff
function ShopBaseItemNum:getPlayerDiscount()
    return 0
end

-- 子类重写
-- 界面展示具体的金币数值
function ShopBaseItemNum:getShowNumbers()
    local orginCoin, curCoin = self:getItemNumbers()

    -- 特殊逻辑：
    local extraMul = self:getExtraMulti()
    if extraMul > 0 then
        curCoin = curCoin * (1 + extraMul)
    end

    return orginCoin, curCoin
end

-- 子类重写 应该返回的值
function ShopBaseItemNum:getItemNumbers()
    return 0, 0
end

function ShopBaseItemNum:getExtraMulti()
    local extraMul = 0

    -- 玩家自身属性对商城数值的影响
    local playerDis = self:getPlayerDiscount()
    if playerDis and playerDis > 0 then
        extraMul = extraMul + playerDis
    end

    return extraMul
end

function ShopBaseItemNum:updateItemData(itemData)
    self.m_itemData = itemData

    self:initNumbersLb()
end

function ShopBaseItemNum:runShowActions()
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle")
            self:updateLabelSize({label = self.m_currNumberLabel}, COINS_SCALE_NUM)
        end
    )
end

function ShopBaseItemNum:initCoinsUI()
    self:initNumbersLb()

    -- if self:isDisCount() then
    --     self:runShowActions()
    -- else
    --     self:runCsbAction("idle")
    -- end
end

-- 购买之后更新数据 可能涉及到动画展示 另起一个接口
function ShopBaseItemNum:updateItemDataUI(_itemData)
    -- 动画.... 暂时没有

    self:updateItemData(_itemData)
end
-- 刷新金币跳动的效果
-- function ShopBaseItemNum:updataCoinsLb()
--     local baseCoins, coins = self:getShowNumbers()
--     local addValue = (coins - baseCoins) * 0.07 + math.random(1, 9) + math.random(1, 9) * 10 + math.random(1, 9) * 100

--     util_jumpNum(self.m_currNumberLabel, baseCoins, coins, addValue, 0.02, {30})

--     self:setDisCountNodePos()
-- end

-- function ShopBaseItemNum:setDisCountNodePos()
--     if self:isDisCount() then
--         local length = 170
--         local baseCoins, coins = self:getShowNumbers()
--         self.m_baseNumberLabel:setVisible(true)
--         self.m_baseNumberLabel:setString(util_formatMoneyStr(tostring(baseCoins)))
--         self:updateLabelSize({label = self.m_baseNumberLabel}, length)

--         local size = self.m_baseNumberLabel:getContentSize()
--         local scaleX = self.m_baseNumberLabel:getScaleX()
--         local sizeWidth = size.width * scaleX + 5
        
--         self.m_nodeBase:setVisible(true)
--         self.m_linesp:setContentSize(sizeWidth, 3)

--         -- if globalData.slotRunData.isPortrait == true then
--         --     self.m_currNumberLabel:setPositionY(-10)
--         -- else
--         --     self.m_currNumberLabel:setPositionY(0)
--         -- end
--     else
--         self.m_nodeBase:setVisible(false)
--         self.m_baseNumberLabel:setVisible(false)
--         -- self.m_currNumberLabel:setPositionY(-20)
--     end
-- end

function ShopBaseItemNum:setCurNum(coins)
    self.m_lastShowCoins = self.m_coins or 0
    self.m_coins = coins
    self.m_currNumberLabel:setString(util_getFromatMoneyStr(coins))
    self:updateLabelSize({label = self.m_currNumberLabel}, COINS_SCALE_NUM)
end

function ShopBaseItemNum:setBaseNum(coins)
    self.m_nodeBase:setVisible(false)
    self.m_baseNumberLabel:setVisible(false)

    -- if not self:isDisCount() then
    --     self.m_baseNumberLabel:setVisible(false)
    --     self.m_nodeBase:setVisible(false)
    -- else
    --     self.m_baseNumberLabel:setVisible(true)
    --     self.m_nodeBase:setVisible(true)

    --     local length = 170

    --     self.m_baseNumberLabel:setString(util_formatMoneyStr(tostring(coins)))
    --     self:updateLabelSize({label = self.m_baseNumberLabel}, length)

    --     local size = self.m_baseNumberLabel:getContentSize()
    --     local scaleX = self.m_baseNumberLabel:getScaleX()
    --     local sizeWidth = size.width * scaleX + 5

    --     self.m_linesp:setContentSize(sizeWidth, 3)
    -- end
end

function ShopBaseItemNum:initNumbersLb()
    local baseCoins, coins = self:getShowNumbers()
    if not G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        coins = baseCoins
    end

    -- if globalData.slotRunData.isPortrait == true then
    --     self.m_currNumberLabel:setPositionY(-10)
    -- end
    -- self.m_currNumberLabel:setString(util_getFromatMoneyStr(coins))
    -- self:updateLabelSize({label = self.m_currNumberLabel}, COINS_SCALE_NUM)
    self:setCurNum(coins)
    -- self:setDisCountNodePos()
    self:setBaseNum(baseCoins)
end

------------------------------------       折扣开关     ---------------------

function ShopBaseItemNum:promoCoinAction(_type)
    if _type == "on" then
        self:addCoinAction()
    elseif _type == "off" then
        self:subtractCoinAction()
    end
end

function ShopBaseItemNum:addCoinAction()
    if self.m_promoId then
        self:stopAction(self.m_promoId)
        self.m_promoId = nil
    end

    local baseCoins, coins = self:getShowNumbers()
    local interval = 1 / 30
    local rolls = 33
    local coinStep = 0
    if self.m_coins ~= coins then
        coinStep = math.floor((coins - baseCoins) / rolls)
    end

    if coinStep ~= 0 then
        self.m_promoId =
            schedule(
            self,
            function()
                self.m_coins = math.min(self.m_coins + coinStep, coins)
                self:setCurNum(self.m_coins)

                if self.m_coins >= coins then
                    if self.m_promoId then
                        self:stopAction(self.m_promoId)
                        self.m_promoId = nil
                    end
                end
            end,
            interval
        )
        local _ts = (rolls + 2) * interval
        local _action = {}
        _action[1] = cc.EaseBackInOut:create(cc.ScaleTo:create(_ts, 1.2))
        _action[2] = cc.ScaleTo:create(0.1, 1)
        _action[3] =
            cc.CallFunc:create(
            function()
                self:playPromoLizi()
            end
        )
        self.m_nodeCur:runAction(cc.Sequence:create(_action))
    end
end

function ShopBaseItemNum:subtractCoinAction()
    if self.m_promoId then
        self:stopAction(self.m_promoId)
        self.m_promoId = nil
    end

    local baseCoins, coins = self:getShowNumbers()
    local interval = 1 / 30
    local rolls = 33
    local coinStep = 0
    if self.m_coins ~= baseCoins then
        coinStep = math.floor((baseCoins - coins) / rolls)
    end

    if coinStep ~= 0 then
        self.m_promoId =
            schedule(
            self,
            function()
                self.m_coins = math.max(self.m_coins + coinStep, baseCoins)
                self:setCurNum(self.m_coins)
                if self.m_coins <= baseCoins then
                    if self.m_promoId then
                        self:stopAction(self.m_promoId)
                        self.m_promoId = nil
                    end
                    G_GetMgr(G_REF.Shop):setPromomodeSound(false)
                end
            end,
            interval
        )
    end
end

function ShopBaseItemNum:playPromoLizi()
    if not G_GetMgr(G_REF.Shop):getPromomodeSound() then
        gLobalSoundManager:playSound(SHOP_RES_PATH.Sound_promomode)
        G_GetMgr(G_REF.Shop):setPromomodeSound(true)
    end

    local sp = util_createAnimation(SHOP_RES_PATH.CoinLizi)
    if sp then
        self:addChild(sp, 10)
        sp:playAction(
            "start",
            false,
            function()
                sp:removeFromParent()
            end,
            60
        )
    end
end

function ShopBaseItemNum:coinAction()
    if not self.m_coins or not self.m_lastShowCoins then
        return
    end

    if self.m_coins > self.m_lastShowCoins then
        self.m_coins = self.m_lastShowCoins
        self:addCoinAction()
    end
end

function ShopBaseItemNum:onEnter()
    ShopBaseItemNum.super.onEnter(self)

    gLobalNoticManager:addObserver(self, self.promoCoinAction, ViewEventType.NOTIFY_SHOP_PROMO_SWITCH)
    gLobalNoticManager:addObserver(self, self.coinAction, ViewEventType.NOTIFY_STAY_COUPON_SHOP_COIN_ACTION)
end

return ShopBaseItemNum
