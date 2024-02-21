--[[
    新版常规促销
--]]

local RoutineSaleRewardLayer = class("RoutineSaleRewardLayer", BaseLayer)

function RoutineSaleRewardLayer:initDatas(_reward, _baseCoins)
    self.m_reward = _reward
    self.m_baseCoins = toLongNumber(_baseCoins)
    self.m_isTouch = true

    self:setPortraitCsbName("Sale_New/csb/reward/SaleReward_shu.csb")
    self:setLandscapeCsbName("Sale_New/csb/reward/SaleReward.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("RoutineSaleRewardLayer")
end

function RoutineSaleRewardLayer:initCsbNodes()
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_node_fly = self:findChild("node_number_fly")
end

function RoutineSaleRewardLayer:initView()
    self:setCoins(self.m_baseCoins)
    self:addNumNode()
end

function RoutineSaleRewardLayer:addNumNode()
    self.m_numNode = util_createView("GameModule.RoutineSale.views.RoutineSaleFlyNode", self.m_reward.p_multiple, self.m_isShownAsPortrait)
    self.m_node_fly:addChild(self.m_numNode)
end

function RoutineSaleRewardLayer:coinRoll()
    local count = 1
    local coins = toLongNumber(self.m_reward.p_coins)
    local addCoins = (coins - self.m_baseCoins) * 0.02
    local updateCoins = function ()
        if count >= 50 then
            self.m_isTouch = false
            self.m_lb_coin:stopAllActions()
            self:setCoins(coins)
        else
            count = count + 1
            self.m_baseCoins = self.m_baseCoins + addCoins
            self:setCoins(self.m_baseCoins)
        end
    end

    updateCoins()
    util_schedule(self.m_lb_coin, updateCoins, 0.01)
end

function RoutineSaleRewardLayer:setCoins(_coins)
    self.m_lb_coin:setString(util_formatCoins(_coins, 12))
    
    local uiList = {
        {node = self.m_sp_coin},
        {node = self.m_lb_coin, alignX = 3}
    }
    util_alignCenter(uiList)
end

function RoutineSaleRewardLayer:clickFunc(_sender)
    if self.m_isTouch then
        return
    end

    local name = _sender:getName()
    if name == "btn_collect" then
        self.m_isTouch = true
        G_GetMgr(G_REF.RoutineSale):sendWheelReward()
    end
end

function RoutineSaleRewardLayer:flyCoins(_params)
    if _params and _params.result then
        local coins = tonumber(_params.result.coins) or 0
        local flyList = {}
        local btnCollect = self:findChild("btn_collect")
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        if coins > 0 then
            table.insert(flyList, { cuyType = FlyType.Coin, addValue = coins, startPos = startPos })
        end

        G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, function()
            if not tolua.isnull(self) then
                self:closeUI(function ()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_REWARD_CLOSE)
                end)
            end
        end)
    else
        self.m_isTouch = false
        gLobalViewManager:showReConnect()
    end
end

function RoutineSaleRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
    self.m_numNode:playStart(function ()
        self:coinRoll()
    end)
end

function RoutineSaleRewardLayer:registerListener()
    RoutineSaleRewardLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "flyCoins", ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_REWARD)
end

return RoutineSaleRewardLayer