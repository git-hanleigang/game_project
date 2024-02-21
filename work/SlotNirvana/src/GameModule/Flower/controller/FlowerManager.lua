--浇花
local FlowerNet = require("GameModule.Flower.net.FlowerNet")
local FlowerManager = class("FlowerManager", BaseGameControl)

function FlowerManager:ctor()
    FlowerManager.super.ctor(self)
    self:setRefName(G_REF.Flower)

    self.m_netModel = FlowerNet:getInstance() -- 网络模块
end

function FlowerManager:getConfig()
    if not self.FlowerConfig then
        self.FlowerConfig = util_require("GameModule.Flower.config.FlowerConfig")
    end
    return self.FlowerConfig
end

function FlowerManager:getData()
    return globalData.flowerData
end

function FlowerManager:isDownloadRes(_name)
    if not self:checkRes(_name) then
        return false
    end

    local isDownloaded = self:checkDownloaded(_name)
    if not isDownloaded then
        return false
    end

    return true
end

function FlowerManager:sendReward(_type)
	local successFunc = function(_data)
		gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.INIT_REWARD_INFO)
    end
    local fileFunc = function()
    end
    self.m_netModel:sendInitRewardReq(successFunc,fileFunc,_type)
end

function FlowerManager:sendPayInfo(_type)
	local successFunc = function(_data)
		gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.INIT_PAY_INFO)		
    end
    local fileFunc = function()
        self:setWaterHide(true)
    end
    self.m_netModel:sendInitPayReq(successFunc,fileFunc,_type)
end

function FlowerManager:sendWater(_type,_index)
	local successFunc = function(_data)
		self:getData():setItemReward(_data)
		gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.NOTIFY_FLOWER_WATER,_index)		
    end
    local fileFunc = function()
    end
    self.m_netModel:sendWaterReq(successFunc,fileFunc,_type,_index)
end

function FlowerManager:sendWaterGuide(_type)
    local successFunc = function(_data)  
    end
    local fileFunc = function()
    end
    self.m_netModel:sendFlowerGuideReq(successFunc,fileFunc,_type)
end

function FlowerManager:sendWaterTime()
    local successFunc = function(_data)
        gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.NOTIFY_REWARD_BIG) 
    end
    local fileFunc = function()
    end
    self.m_netModel:sendWaterTimeReq(successFunc,fileFunc)
end

function FlowerManager:showRewardLayer(param)
    if not self:isDownloadRes(G_REF.Flower) then 
        return
    end
    local view = util_createView("views.FlowerCode.FlowerRewardSpot",param)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function FlowerManager:showResultLayer(call_back,coins)
     if not self:isDownloadRes(G_REF.Flower) then 
        return
     end
     if self:getData():getFlowerCoins() ~= 0 then
        coins = tonumber(self:getData():getFlowerCoins()) + coins
     end
     local item = {}
     local coin_item = gLobalItemManager:createLocalItemData("Coins", tonumber(coins), {p_limit = 3})
     table.insert(item,coin_item)
     local cb = function()
        if self:getData():getFlowerCoins() ~= 0 then
            self:getData():setFlowerCoins()
            self.m_netModel:sendFlowerCoinsReq()
        end
        if call_back then
            call_back()
        end
     end
     local view = util_createView("views.FlowerCode.FlowerRewardLayer",item,cb,tonumber(coins),true,3)
     gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function FlowerManager:setWaterHide(_hide)
    self.waterHide = _hide
end

function FlowerManager:getWaterHide()
    return self.waterHide
end

function FlowerManager:setGoodHide(_hide)
    self.goodHide = _hide
end

function FlowerManager:getGoodHide()
    return self.goodHide
end

function FlowerManager:setFlowerCoins(_flowerCoins)
    self.flowerCoins = _flowerCoins
end

function FlowerManager:getFlowerCoins()
    return self.flowerCoins or 0
end

--购买
function FlowerManager:buyGoods(data,_typestr,purchase_name,purchase_status)
    local saleData = {key = data.key,keyId = data.keyId, price = data.price}
    self:sendIapLog(saleData,purchase_name,purchase_status)
    gLobalSaleManager:purchaseActivityGoods(
        "Flower",
        _typestr,
        BUY_TYPE.FLOWER,
        data.keyId,
        data.price,
        0,
        0,
        function()
            self:buySuccess(data.num)
        end,
        function()
            self:setGoodHide(true)
            self:setWaterHide(true)
        end,
        _typestr
    )
end
function FlowerManager:buySuccess(_num)
    self:setWaterHide(true)
    self:setGoodHide(true)
    gLobalViewManager:checkBuyTipList(function()
        gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.NOTIFY_FLOWER_BUY_SUCCESS,_num)
    end)
end
-- 客户端打点
function FlowerManager:sendIapLog(_goodsInfo,name,status)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "Flower"
        goodsInfo.goodsId = _goodsInfo.key
        goodsInfo.goodsPrice = _goodsInfo.price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = name
        purchaseInfo.purchaseStatus = status
        gLobalSendDataManager:getLogIap():setEntryType("GloryPass")
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
        gLobalSendDataManager:getLogIap():setLastEntryType()
    end
end

--红点处理
function FlowerManager:setFlowerData()
    local data = self:getData()
    local water = data:getIsWateringDay()
    if data and water then
        local flower_red = gLobalDataManager:getNumberByField("flower_red1", 1)
        local flower_time = gLobalDataManager:getStringByField("flower_time", "")
        if water and flower_red == 2 and flower_time ~= "" then
            local cha_time = (tonumber(globalData.userRunData.p_serverTime) - tonumber(flower_time))/1000
            if cha_time > 86400 then
                gLobalDataManager:setNumberByField("flower_red1", 1)
            end
        end
    end
end

--红点处理
function FlowerManager:getFlowerData()
    local data = self:getData()
    if not data:getOpen() then
        return 0
    end
    local water = data:getIsWateringDay()
    local ct = 0
    local flower_red = gLobalDataManager:getNumberByField("flower_red", 1)
    if tonumber(flower_red) == 1 then
        ct = 1
    end
    local flower_red1 = gLobalDataManager:getNumberByField("flower_red1", 1)
    if water and tonumber(flower_red1) == 1 then
        ct = 1
    end
    if water and self:getFlowerSpot() > 0 then
        ct = 1
    end
    return ct
end

--总水壶数量
function FlowerManager:getFlowerSpot()
    local sl_data = self:getData():getSilverData()
    local gl_data = self:getData():getGoldData()
    local sl_complete = self:getData():getSilverComplete()
    local gl_complete = self:getData():getGoldComplete()
    local num = 0
    if sl_data and sl_data.kettleNum and not sl_complete then
        num = num + sl_data.kettleNum
    end
    if gl_data and gl_data.kettleNum and not gl_complete then
        num = num + gl_data.kettleNum
    end
    return num
end

function FlowerManager:createFlayerLayer()
    if not self:isDownloadRes(G_REF.Flower) then 
        return nil
    end
    local view = util_createView("views.FlowerCode.FlowerFlayLayer")
    return view
end

function FlowerManager:createFlayerLayer_New()
    if not self:isDownloadRes("Flower_2023") then 
        return nil
    end
    local view = util_createView("views.FlowerCode_New.FlowerFlayLayer")
    return view
end


return FlowerManager
