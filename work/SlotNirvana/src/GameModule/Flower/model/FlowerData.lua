--浇花
local FlowerData = class("FlowerData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function FlowerData:ctor()
    self.sl_kem = 0
    self.gl_kem = 0
    self.sl_ckm = 0
    self.gl_ckm = 0
end
function FlowerData:parseData(data)
    if not data then
        return
    end
    if data:HasField("silverFlower") then
        self.silverResult = data.silverFlower --银花数据
        if self.silverResult.flowerRewardList and #self.silverResult.flowerRewardList > 0 then
            self.slitem_list = {}
            for i,v in ipairs(self.silverResult.flowerRewardList) do
                local item = self:setShopItem(v)
                table.insert(self.slitem_list,item)
            end
        end
        if self.silverResult.bigReward then
            self.slbig_list = self:setShopItem(self.silverResult.bigReward)
        end
        if self.sl_ckm == 0 then
            self.sl_ckm = self.silverResult.kettleNum - self.sl_kem
        end
        self.sl_kem = self.silverResult.kettleNum
    end
    if data:HasField("goldFlower") then
        self.goldResult = data.goldFlower --银花数据
        if self.goldResult.flowerRewardList and #self.goldResult.flowerRewardList > 0 then
            self.glitem_list = {}
            for i,v in ipairs(self.goldResult.flowerRewardList) do
                local item = self:setShopItem(v)
                table.insert(self.glitem_list,item)
            end
        end
        if self.goldResult.bigReward then
            self.glbig_list = self:setShopItem(self.goldResult.bigReward)
        end
        self.gl_ckm = self.goldResult.kettleNum - self.gl_kem
        self.gl_kem = self.goldResult.kettleNum
    end 
    self.is_open = data.open
    self.wateringDay = data.wateringDay
    self.showGuide = data.showGuide
    self.waterGuide = data.waterGuide
    self.isLevel = data.openLevel
    self.waterDayTime = data.waterDayTime
    if data:HasField("flowerCoins") then
        if not self.flowerCoins or self.flowerCoins == 0 then
            self.flowerCoins = data.flowerCoins
        end
    end
end
--开启等级
function FlowerData:getOpenLevel()
	return self.isLevel or 0
end
--活动是否开启
function FlowerData:getOpen()
    local st = self.is_open
    if self.silverResult == nil or self.goldResult == nil then
        st = false
    end
	return st or false
end
--是否是浇水日
function FlowerData:getIsWateringDay()
	return self.wateringDay
end

function FlowerData:setIsWateringDay()
    self.wateringDay = false
end
--是否新手引导
function FlowerData:getIsGuide()
	return self.showGuide
end
--是否显示浇花页引导
function FlowerData:getIsWaterGuide()
    return self.waterGuide
end

function FlowerData:getSilverReward()
	return self.slitem_list or {}
end

function FlowerData:getSilverBigReward()
	return self.slbig_list or {}
end

function FlowerData:getGoldReward()
	return self.glitem_list or {}
end

function FlowerData:getGoldBigReward()
	return self.glbig_list or {}
end

function FlowerData:getSilverComplete()
    return self.silverResult.complete
end

function FlowerData:getGoldComplete()
    return self.goldResult.complete
end

function FlowerData:getSilverPayInfo()
    return self.silverResult.payInfoList
end

function FlowerData:getGoldPayInfo()
    return self.goldResult.payInfoList
end

function FlowerData:getSilverIndexList()
    return self.silverResult.indexList
end

function FlowerData:getGoldIndexList()
    return self.goldResult.indexList
end

function FlowerData:getSilCkm()
    return self.sl_ckm
end

function FlowerData:setSilCkm()
    self.sl_ckm = 0
end

function FlowerData:setGoldCkm()
    self.gl_ckm = 0
end

function FlowerData:getGoldCkm()
    return self.gl_ckm
end

function FlowerData:getFlowerCoins()
    return self.flowerCoins or 0
end

function FlowerData:setFlowerCoins()
    self.flowerCoins = 0
end

function FlowerData:setItemReward(_data)
    local _item_list = {}
    _item_list.coins = _data.coins
    _item_list.itemList = _data.itemList
    self.rewardItem = self:setShopItem(_item_list)
    self.isbigReward = _data.bigReward
    self.end_coins = _data.coins
    self.remainingKettleCoins = _data.remainingKettleCoins
    local remitem = {}
    remitem.coins = _data.remainingKettleCoins
    self.remainItem = self:setShopItem(remitem)
    self.cardDropInfoResultList = _data.cardDropInfoResultList
end

function FlowerData:getRemainCoins()
    return self.remainingKettleCoins or 0
end

function FlowerData:getRemainItem()
    return self.remainItem
end

function FlowerData:getItemReward()
    return self.rewardItem
end

function FlowerData:getIsBig()
    return self.isbigReward or false
end

function FlowerData:getEndCoins()
    return self.end_coins or 0
end

function FlowerData:getCardInfo()
    return self.cardDropInfoResultList
end

function FlowerData:getWaterTime()
    return self.waterDayTime
end

function FlowerData:getSilverData()
    return self.silverResult
end

function FlowerData:getGoldData()
    return self.goldResult
end

function FlowerData:setShopItem(_data)
    local items = {}
    if _data.itemList and #_data.itemList > 0 then
    	for i,v in ipairs(_data.itemList) do
    		local item = ShopItem:create()
    		item:parseData(v)
            if string.find(item.p_icon, "DuckShot") then
                item:setTempData({p_num = 1}) -- 小游戏修改数量
            end
    		table.insert(items,item)
    	end
    end
    if _data.coins and _data.coins ~= 0 then
        local coin = util_formatCoins(tonumber(_data.coins),3)
        local item = gLobalItemManager:createLocalItemData("Coins", coin)
        item.con = _data.coins
        table.insert(items,item)
    end
    return items
end

return FlowerData
