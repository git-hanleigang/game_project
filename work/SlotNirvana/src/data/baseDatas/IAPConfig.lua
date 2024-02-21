--支付存储信息
local IAPExtraData = util_require("data.baseDatas.IAPExtraData")
local IAPConfig = class("IAPConfig")
IAPConfig.ID = nil                --唯一标识
IAPConfig.userid = nil            --用户信息
IAPConfig.productID = nil         --支付信息
IAPConfig.buyType = nil           --支付类型
IAPConfig.signature = nil         --交易信息
IAPConfig.platform = nil          --平台信息
IAPConfig.receipt = nil           --收据信息
IAPConfig.orderID = nil           --订单信息
IAPConfig.failCount = nil         --失败次数
IAPConfig.createTime = nil        --订单创建时间
IAPConfig.purchaseStatus = nil    --订单支付状态
IAPConfig.purchasingCount = nil   --订单支付中检测次数
IAPConfig.skipBuyGoodsCheck = nil --订单是否跳过购买检测
IAPConfig.extraData = nil         --附加信息

function IAPConfig:ctor()
    
end

--创建订单
function IAPConfig:createIapConfig(buyType,productID,extraData)
    self.ID = globalData.userRunData.uid .. "_" .. buyType .."_"..os.time()
    self.userid = globalData.userRunData.uid
    self.productID = productID
    self.buyType = buyType
    if MARKETSEL == AMAZON_MARKET then
        self.platform = AMAZON_MARKET
    else
        self.platform = device.platform
    end
    self.failCount = 0                  --失败次数
    self.signature = nil                --交易签名
    self.receipt = nil                  --收据信息
    self.orderID = nil                  --订单信息
    self.purchaseStatus = "PURCHASING"  --默认订单状态 
    self.purchasingCount = 0
    self.skipBuyGoodsCheck = false
    self.extraData = extraData          --附加信息
    self.createTime = globalData.userRunData.p_serverTime
end

--刷新收据
function IAPConfig:updateReceipt(orderID, signature, receipt)
    self.orderID = orderID
    self.signature = signature
    self.receipt = receipt
end

--刷新失败次数
function IAPConfig:updateFailedCount()
    self.failCount = self.failCount + 1
end

function IAPConfig:updatePurchaseStatus(status)
    self.purchaseStatus = status
end

--根据json结构解析数据
function IAPConfig:parseData(jsonData)
    self.ID = jsonData.ID                           --唯一标识
    self.userid = jsonData.userid                   --用户信息
    self.productID = jsonData.productID             --支付信息
    self.buyType = jsonData.buyType                 --支付类型
    self.signature = jsonData.signature             --交易签名
    self.platform = jsonData.platform               --平台信息
    self.receipt = jsonData.receipt                 --收据信息
    self.orderID = jsonData.orderID                 --订单信息
    self.failCount = jsonData.failCount             --失败次数
    self.createTime = jsonData.createTime
    self.purchaseStatus = jsonData.purchaseStatus
    self.purchasingCount = jsonData.purchasingCount
    self.skipBuyGoodsCheck = jsonData.skipBuyGoodsCheck
    self.extraData = nil
    self.extraData = IAPExtraData:create()
    self.extraData:parseData(jsonData.extraData)    --附加信息
end
--获取json结构数据
function IAPConfig:getJsonData()
    local jsonData = {
        ID = self.ID,
        userid = self.userid,
        productID = self.productID,
        buyType = self.buyType,
        signature = self.signature,
        platform = self.platform,
        receipt = self.receipt,
        orderID = self.orderID,
        failCount = self.failCount,
        createTime = self.createTime,
        purchaseStatus = self.purchaseStatus,
        purchasingCount = self.purchasingCount,
        skipBuyGoodsCheck = self.skipBuyGoodsCheck,
        extraData = self.extraData:getJsonData()
    }
    return jsonData
end

return  IAPConfig