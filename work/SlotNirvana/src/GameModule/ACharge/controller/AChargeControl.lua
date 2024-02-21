--[[
    AppCharge 管理模块
    author:{author}
    time:2023-10-24 20:29:53
]]
require("GameModule.ACharge.config.AChargeConfig")

local AChargeNet = require("GameModule.ACharge.net.AChargeNet")
local AChargeControl = class("AChargeControl", BaseGameControl)

function AChargeControl:ctor()
    AChargeControl.super.ctor(self)

    self:setRefName(G_REF.AppCharge)
    self:setResInApp(true)
    self:setDataModule("GameModule.ACharge.model.AChargeData")

    self.m_net = AChargeNet:getInstance()
end

-- 获得兑换商品信息
function AChargeControl:getProductById(productId)
    if not productId then
        return
    end
    return self:getData():getProductById(productId)
end

-- 显示领取界面
function AChargeControl:showCollectLayer(productId)
    -- 查找商品信息
    local productInfo = self:getProductById(productId)
    if not productInfo then
        return nil
    end

    local _layer = gLobalViewManager:getViewByName("AChargeRewardLayer")
    if _layer ~= nil then
        return
    end
    _layer = util_createView("GameModule.ACharge.views.AChargeRewardLayer", productInfo)
    _layer:setName("AChargeRewardLayer")
    self:showLayer(_layer, ViewZorder.ZORDER_UI)
    return _layer
end

-- 领取奖励
function AChargeControl:onCollectAChargeReward(productId,_rawardBuckNum,_callback)
    -- 验证productId
    local productInfo = self:getProductById(productId)
    if not productInfo then
        return false
    end

    local succCallFunc = function(jsonResult)
        --刷新邮件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        if _rawardBuckNum then
            _callback()
            return
        end
        local _layer = gLobalViewManager:getViewByName("AChargeRewardLayer")
        if not tolua.isnull(_layer) then
            _layer:closeUI(
                function()
                    self:showBuyTip(productInfo)
                end
            )
        else
            self:showBuyTip(productInfo)
        end
    end

    local failedCallFunc = function(errorCode, errorData)
    end

    self.m_net:requestCollectAChargeReward(productId, succCallFunc, failedCallFunc)
end

function AChargeControl:showBuyTip(productInfo)
    if not productInfo then
        return
    end

    --购买成功提示界面
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local view = util_createView("GameModule.Shop.BuyTip")
    -- if gLobalSendDataManager.getLogPopub then
    --     gLobalSendDataManager:getLogPopub():addNodeDot(view, "btnBuy", DotUrlType.UrlName, false)
    -- end
    view:setSource("AppChargeCollect")

    local buyData = clone(productInfo:getShopCoinsInfo())

    view:initBuyTip(
        BUY_TYPE.APP_CHARGE,
        buyData,
        buyData.p_originalCoins,
        levelUpNum,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_APP_CHARGE_COLLECTED)
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
end

return AChargeControl
