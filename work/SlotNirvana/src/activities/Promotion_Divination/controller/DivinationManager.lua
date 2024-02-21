--[[
Author: dhs
Date: 2022-02-14 14:59:30
LastEditTime: 2022-05-25 17:57:11
LastEditors: bogon
Description: 占卜促销 控制类
FilePath: /SlotNirvana/src/activities/DivinationManager/controller/DivinationManager.lua
--]]
local DivinationManager = class("DivinationManager", BaseActivityControl)
local DivinationConfig = util_require("activities.Promotion_Divination.config.DivinationConfig")
local NetWorkBase = util_require("network.NetWorkBase")

local ShopItem = require "data.baseDatas.ShopItem"

function DivinationManager:ctor()
    DivinationManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DivinationSale)
    self.m_payStatusList = {"FirstPay", "MoreFirst", "MoreSecond", "MoreThird"}
    self.m_timeOver = false
end

-- 设置当前为第几轮付费
function DivinationManager:setPayStatus(_index)
    self.m_payStatus = self.m_payStatusList[_index]
end
-- 获取当前第几轮付费
function DivinationManager:getPayStatus()
    return self.m_payStatus
end

function DivinationManager:setTimeStatus()
    self.m_timeOver = true
end

-- 获取倒计时是否结束（方便活动关闭）
function DivinationManager:getTimeStatus()
    return self.m_timeOver
end

function DivinationManager:getDivinationData()
    local divinationData = G_GetMgr(ACTIVITY_REF.DivinationSale):getRunningData()
    if divinationData then
        return divinationData
    end
    return nil
end

-- 获取玩家促销数据
function DivinationManager:getSaleDataByIndex(_index)
    local divinationData = G_GetMgr(ACTIVITY_REF.DivinationSale):getRunningData()
    if divinationData then
        local saleItems = divinationData:getSaleDataByIndex(_index)
        local cardItems = divinationData:getCardDataByIndex(_index)

        local itemList = {}
        local price = saleItems.p_price
        local coins = saleItems.p_coins
        local gem = saleItems.p_gemPrice
        local items = saleItems.p_items
        local itemNode = nil
        if cardItems then
            local chipUnit = util_createView("GameModule.Card.season201903.MiniChipUnit")
            chipUnit:playIdle()
            chipUnit:reloadUI(cardItems, true, true)
            chipUnit:updateTagNew(cardItems.newCard == true) -- 特殊显示逻辑，当玩家没有这张卡的时候显示new，告诉玩家送给玩家的是新卡
            chipUnit:setScale(0.5)
            itemNode = chipUnit
        else
            --金币道具
            if coins and coins > 0 then
                local tempData = gLobalItemManager:createLocalItemData("Coins", coins)
                tempData:setTempData({p_limit = 3})
                itemList[#itemList + 1] = tempData
            elseif gem and gem > 0 then
                local tempData = gLobalItemManager:createLocalItemData("Gem", gem, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
                itemList[#itemList + 1] = tempData
            elseif items ~= nil and #items > 0 then
                -- 通用道具

                for i = 1, #items do
                    local itemData = items[i]
                    itemList[#itemList + 1] = itemData
                end
            end
            itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.REWARD_BIG)
        end
        return itemNode
    end
end
-- ******************************************* 弹出界面 **************************************** --
-- 弹出领奖界面
function DivinationManager:showRewardLayer(_cb,_index)
    _cb = _cb or function() end

    -- if not self:isCanShowLayer() then
    --     if _cb then
    --         _cb()
    --     end
    --     return false
    -- end

    if gLobalViewManager:getViewByExtendData("Promotion_DivinationRewardLayer") then
        return false
    end

    local view = util_createView("Activity.Promotion_DivinationRewardLayer",_cb,_index)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return true
end

function DivinationManager:showBuyTipsLayer()
    if not self:isCanShowLayer() then
        return false
    end

    if gLobalViewManager:getViewByExtendData("Promotion_DivinationTipsLayer") then
        return false
    end

    local view = util_createView("Activity.Promotion_DivinationTipsLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return true
end

-- ******************************************* 弹出界面 **************************************** --

-- *************************************************** Net ********************************************--
-- 购买
function DivinationManager:collectDivinationReward(_index)
    local divinationData = G_GetMgr(ACTIVITY_REF.DivinationSale):getRunningData()
    if divinationData then
        local saleData = divinationData:getSaleDataByIndex(_index)
        self:setPayStatus(_index)
        self.m_payIndex = _index
        self:sendIapLog(saleData)
        local payStatus = self:getPayStatus()
        gLobalSaleManager:purchaseActivityGoods(
            saleData.p_activityId,
            payStatus,
            BUY_TYPE.DIVINATION,
            saleData.p_key,
            saleData.p_price,
            saleData.p_coins,
            saleData.p_discounts, -- p_discounts 折扣
            function(target,resultData)
                self:buySuccess(_index,resultData)             
            end,
            function(_errorInfo)
                self:buyFailed(_errorInfo)
            end
        )
    end
end
-- 购买成功
function DivinationManager:buySuccess(_index,resultData)
    gLobalNoticManager:postNotification(DivinationConfig.EVENT_NAME.DIVINATION_SALE_BUY_SUCCESS, _index)
end
-- 购买失败

function DivinationManager:buyFailed(_errorInfo)
    local view = self:checkPopPayConfirmLayer(_errorInfo)
    if not view then
        gLobalNoticManager:postNotification(DivinationConfig.EVENT_NAME.DIVINATION_SALE_BUY_FAILED,self.m_payIndex)
    end
end

-- 检查是否弹出 二次确认弹板
function DivinationManager:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end

    local data = G_GetMgr(ACTIVITY_REF.DivinationSale):getRunningData()
    if not data then
        return
    end
    local saleData = data:getSaleDataByIndex(self.m_payIndex)
    if not saleData or not saleData.p_coins or saleData.p_coins <= 0 then
        return
    end

    local payCoins = saleData.p_coins
    local priceV = saleData.p_price
    local params = {
        coins = payCoins,
        price = priceV,
        actRefName = ACTIVITY_REF.DivinationSale,
        confirmCB = function()
            self:collectDivinationReward(self.m_payIndex)
        end,
        cancelCB = function()
            gLobalNoticManager:postNotification(DivinationConfig.EVENT_NAME.DIVINATION_SALE_BUY_FAILED,self.m_payIndex)
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function DivinationManager:dropStamp()
    local closeFunc = function()
    end
    -- 正式服需要打开这个
    gLobalViewManager:checkBuyTipList(closeFunc)
end

-- 客户端打点
function DivinationManager:sendIapLog(_goodsInfo)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "PromotionDiviantion"
        goodsInfo.goodsId = _goodsInfo.p_key
        goodsInfo.goodsPrice = _goodsInfo.p_price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = "DivinationSale"
        local actData = G_GetMgr(ACTIVITY_REF.DivinationSale):getRunningData()
        if not actData then
            return
        end
        local payStatus = actData:getGamePayStatus()
        local status = 0
        if payStatus == "GemPay" then
            status = 1
        end
        purchaseInfo.purchaseStatus = status
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end


-- 第二货币
function DivinationManager:sendBuyGemAction()

    local successFunc = function (target, resData)
        -- 抛消息
        gLobalNoticManager:postNotification(DivinationConfig.EVENT_NAME.DIVINATION_SALE_BUY_GEM_SUCCESS)
    end

    local failedCallFun = function (target, resData)
        gLobalNoticManager:postNotification(DivinationConfig.EVENT_NAME.DIVINATION_SALE_BUY_GEM_FAILED)
    end

    local actionData = NetWorkBase:getSendActionData(ActionType.DivineGem)
    actionData.data.extra = cjson.encode({})
    NetWorkBase:sendMessageData(actionData, successFunc, failedCallFun)
end

-- *************************************************** Net ********************************************--

return DivinationManager
