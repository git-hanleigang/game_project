---
--xcyy
--2018年5月23日
--RobinIsHoodShopItem.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodShopItem = class("RobinIsHoodShopItem",util_require("base.BaseView"))


function RobinIsHoodShopItem:initUI(params)
    self.m_pageView = params.pageView
    self.m_shopView = params.shopView
    self.m_machine = params.machine

    self.m_itemID = params.itemID     --索引ID
    self.m_isClicked = false    --是否已经点击
    self.m_isFree = false       --是否免费

    self:createCsbNode("RobinIsHood_shop_item.csb")

    --价格标签
    self.m_price_bar = util_createAnimation("RobinIsHood_shop_item_price.csb")
    self:findChild("node_price"):addChild(self.m_price_bar)

    --
    self.m_price_csb = util_createAnimation("RobinIsHood_shop_item_price_coins.csb")
    self.m_price_bar:findChild("Node_price"):addChild(self.m_price_csb)

    --原价标签
    self.m_prePrice_bar = util_createAnimation("RobinIsHood_shop_item_pre_price.csb")
    self.m_price_bar:findChild("Node_old_coins"):addChild(self.m_prePrice_bar)
    
    --压黑层
    self.m_blackNode = util_createAnimation("RobinIsHood_shop_main_state.csb")
    self:findChild("Node_black"):addChild(self.m_blackNode)

    --折扣标志
    self.m_discount_tip = util_createAnimation("RobinIsHood_shop_main_zhekouquan.csb")
    self:findChild("Node_coupon"):addChild(self.m_discount_tip)

    --金币数
    self.m_coins_csb = util_createAnimation("RobinIsHood_shop_item_coins.csb")
    self:findChild("node_reward"):addChild(self.m_coins_csb)

    --二次点击
    self.m_doublePick = util_createAnimation("RobinIsHood_shop_main_pick_double.csb")
    self:findChild("node_reward"):addChild(self.m_doublePick)
    self:doublePicRunIdleAni()

    --创建点击区域
    local layout = self:findChild("Panel_click")
    self:addClick(layout)
end

--[[
    double pick播静帧
]]
function RobinIsHoodShopItem:doublePicRunIdleAni()
    self.m_doublePick:runCsbAction("idle2",true)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function RobinIsHoodShopItem:initSpineUI()
    self.m_spine_lock = util_spineCreate("RobinIsHood_shop_main_lock",true,true)
    self.m_blackNode:findChild("Node_lock"):addChild(self.m_spine_lock)
    util_spinePlay(self.m_spine_lock,"idle",true)
end

--[[
    解锁动画
]]
function RobinIsHoodShopItem:runUnlockAni(func)
    self.m_isLock = false
    self.m_spine_lock:setVisible(true)
    util_spinePlay(self.m_spine_lock,"over")
    util_spineEndCallFunc(self.m_spine_lock,"over",function()
        self.m_spine_lock:setVisible(false)
        local coins = self.m_machine.m_shopData.coins
        local cost = self.m_cost
        if self.m_isDiscount then
            cost = cost * 0.7
        end
        if coins < cost then
            self.m_blackNode:setVisible(true)
            self.m_blackNode:runCsbAction("start",false,function()

            end)
        else
            self.m_blackNode:setVisible(false)
        end
        if type(func) == "function" then
            func()
        end
    end)

    self.m_blackNode:runCsbAction("over",false,function()
        
    end)

    
end

--[[
    显示压黑
]]
function RobinIsHoodShopItem:showDarkAni(func)
    if self.m_isLock or self.m_isClicked then
        return
    end
    self.m_blackNode:setVisible(true)
    self.m_spine_lock:setVisible(false)
    self.m_blackNode:runCsbAction("start",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    默认按钮监听回调
]]
function RobinIsHoodShopItem:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    self.m_shopView:clickItem(self)
end

--[[
    刷新显示
]]
function RobinIsHoodShopItem:updateUI(data)
    local pageIndex = data.pageIndex
    local reward = data.reward
    local cost = data.cost
    local isLock = data.isLock
    local isDiscount = data.isDiscount  --是否折扣
    local isFree = data.isFree  --是否免费
    local coins = self.m_machine.m_shopData.coins

    self.m_reward = reward
    self.m_cost = cost
    self.m_isLock = isLock
    self.m_isDiscount = isDiscount

    self.m_isFree = isFree

    if self.m_isFree then
        
        self.m_price_csb:runCsbAction("idle2")
    else
        self.m_price_csb:runCsbAction("idle1")
    end

    for index = 1,5 do
        self:findChild("sp_bg_"..index):setVisible(index == pageIndex)
    end

    

    self.m_prePrice_bar:setVisible(isDiscount and not isFree)
    self.m_price_bar:findChild("Node_discount"):setVisible(isDiscount)
    self.m_price_bar:findChild("Node_prePrice"):setVisible(not isDiscount)
    self.m_discount_tip:setVisible(isDiscount and not isFree)

    if isDiscount then
        self.m_price_csb:findChild("m_lb_coins"):setString(util_formatCoins(cost * 0.7,5) )
    else
        self.m_price_csb:findChild("m_lb_coins"):setString(util_formatCoins(cost,5) )
    end
    
    self.m_prePrice_bar:findChild("m_lb_coins"):setString(util_formatCoins(cost,5))

    self.m_coins_csb:setVisible(false)
    self.m_doublePick:setVisible(false)

    if type(reward) == "number" then
        if reward == 0 then --还没点击
            self.m_isClicked = false
            self.m_price_bar:setVisible(true)
            self:runCsbAction("idleframe1")
        else    --设置金币数
            self.m_isClicked = true
            self.m_price_bar:setVisible(false)
            self.m_discount_tip:setVisible(false)
            self:runCsbAction("idleframe2")
            self.m_coins_csb:setVisible(true)
            local str = util_formatCoins(reward,3)
            self.m_coins_csb:findChild("m_lb_coins"):setString(str)
        end
    else
        if self.m_isFree then
        
            self.m_doublePick:runCsbAction("idle",true)
        else
            self:doublePicRunIdleAni()
        end
        
        self.m_isClicked = true
        self.m_price_bar:setVisible(false)
        self.m_discount_tip:setVisible(false)
        self.m_doublePick:setVisible(true)
        self:runCsbAction("idleframe2")
    end

    self.m_blackNode:setVisible(isLock)

    if self.m_isDiscount then
        cost = cost * 0.7
    end
    if isLock then
        self.m_blackNode:runCsbAction("idle")
        self.m_spine_lock:setVisible(true)
        util_spinePlay(self.m_spine_lock,"idle",true)
    elseif coins < cost and not self.m_isClicked then
        self.m_blackNode:setVisible(true)
        self.m_spine_lock:setVisible(false)
        self.m_blackNode:runCsbAction("idle")
    end
end

--[[
    显示奖励
]]
function RobinIsHoodShopItem:showRewardAni(data,func)
    local reward = data.reward
    self.m_reward = reward
    self.m_blackNode:setVisible(false)
    self.m_price_bar:setVisible(false)
    self.m_discount_tip:setVisible(false)
    self.m_isClicked = true

    if type(reward) == "number" then
        self.m_doublePick:setVisible(false)
        self.m_coins_csb:setVisible(true)
        local coins = reward
        if self.m_isFree then
            coins = coins / 2
        end
        self.m_coins_csb:findChild("m_lb_coins"):setString(util_formatCoins(coins,3))

    else
        self.m_doublePick:setVisible(true)
        self.m_coins_csb:setVisible(false)
        
    end
    self:runCsbAction("actionframe",false,function()
        local flyCoins = function()
            -- local curMgr = G_GetMgr(G_REF.Currency)
            -- if curMgr then
            --     local startPos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
            --     local flyList = {}
            --     table.insert(flyList, {cuyType = FlyType.Coin, addValue = reward, startPos = startPos})
            --     curMgr:playFlyCurrency(flyList,function()
            --         if type(func) == "function" then
            --             func()
            --         end
            --     end)
            -- end
            local startPos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
            local baseCoins = globalData.topUICoinCount 
            local endPos = globalData.flyCoinsEndPos
            gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,reward,function ()
                -- if not tolua.isnull(self) and func then
                --     func()
                -- end
            end,nil,10,nil,nil,nil,true)
            if not tolua.isnull(self) and type(func) == "function" then
                func()
            end
        end

        if type(reward) == "number" then
            if self.m_isFree then
                --乘倍
                self.m_pageView:flyDoublePickAni(self,reward,function()
                    flyCoins()
                end)
            else
                flyCoins()
            end
        else
            self.m_doublePick:runCsbAction("idle",true)
            if type(func) == "function" then
                func()
            end
        end
        
    end)
end

--[[
    乘倍动画
]]
function RobinIsHoodShopItem:runMultiAni(coins,func)
    self.m_coins_csb:findChild("m_lb_coins"):setString(util_formatCoins(coins,3))
    self:runCsbAction("actionframe2",false,func)
end

--[[
    切换为免费
]]
function RobinIsHoodShopItem:switchFree()
    self.m_isFree = true
    self.m_prePrice_bar:setVisible(false)
    self.m_discount_tip:setVisible(false)
    self.m_price_csb:runCsbAction("switch")
end

--[[
    转换为普通价签
]]
function RobinIsHoodShopItem:switchNormal()
    self.m_isFree = false
    self.m_prePrice_bar:setVisible(self.m_isDiscount and not self.m_isClicked)
    self.m_discount_tip:setVisible(self.m_isDiscount and not self.m_isClicked)
    self.m_price_csb:runCsbAction("idle1")
end

--[[
    检测金币是否足够
]]
function RobinIsHoodShopItem:checkCoinsEnough()
    local shopCoins = self.m_machine.m_shopData.coins
    if shopCoins >= self.m_cost or self.m_isFree then
        return true
    elseif shopCoins >= self.m_cost * 0.7 and self.m_isDiscount then
        return true
    end
    return false
end

--[[
    获取花费
]]
function RobinIsHoodShopItem:getCost()
    if self.m_isFree then
        return 0
    end

    if self.m_isDiscount then
        return self.m_cost * 0.7
    end

    return self.m_cost
end


return RobinIsHoodShopItem