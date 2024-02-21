local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopItem = util_require("data.baseDatas.ShopItem")

local DartsGameReward = class("DartsGameReward")

--[[
    message DartsGameReward {
  optional int32 index = 1; //气球位置
  optional string rewardType = 2; //奖励类型
  repeated ShopItem items = 3;//物品奖励
  optional int64 coins = 4;//金币奖励
}
]]
DartsGameReward.protoKey2Key = {
    ["index"] = "index",
    ["rewardType"] = "rewardType",
    ["items"] = "items",
    ["coins"] = "coins"
}

function DartsGameReward:ctor()
    for _, key in pairs(self.protoKey2Key) do
        self:set(key):get(key)
    end
end

function DartsGameReward:parseData(data)
    for pKey, key in pairs(self.protoKey2Key) do
        if key == "items" then
            local shopItemList = {}
            for _, data in ipairs(data[key]) do
                local shopItem = ShopItem:create()
                shopItem:parseData(data)
                table.insert(shopItemList, shopItem)
            end
            self["set" .. self:getUperKey(key)](self, shopItemList)
        elseif data:HasField(key) then
            local value = data[key]
            self["set" .. self:getUperKey(key)](self, value)
        end
    end
end

function DartsGameReward:set(key)
    if key then
        local firstUperKey = string.gsub(key, "^.", string.upper(string.sub(key, 1, 1)))
        self["set" .. firstUperKey] = function(self, v)
            self["_" .. key] = v
        end
    end
    return self
end

function DartsGameReward:get(key)
    if key then
        local firstUperKey = string.gsub(key, "^.", string.upper(string.sub(key, 1, 1)))
        self["get" .. firstUperKey] = function(self)
            return self["_" .. key]
        end
    end
    return self
end

function DartsGameReward:getUperKey(key)
    return string.gsub(key, "^.", string.upper(string.sub(key, 1, 1)))
end

local DartsGameSingleData = class("DartsGameSingleData", BaseActivityData)

--[[
    message DartsGameV2 {
        optional int32 index = 1; //小游戏序号
        optional string keyId = 2;
        optional string key = 3;
        optional string price = 4; //价格
        optional int64 expireAt = 5; //过期时间
        optional int32 expire = 6; //剩余时间
        optional int32 status = 7; //游戏状态 0未开始 1进行中
        optional bool pay = 8;//是否付过费
        optional int32 totalItems = 9; //道具总数
        optional int32 leftItems = 10; //剩余道具
        repeated int32 jackpots = 11; //Jackpot星星数
        repeated int32 jackpotMax = 12; //最大Jackpot星星数
        repeated int64 jackpotCoins = 13; //jackpot奖金
        optional int64 coins = 14; //奖励金币
        repeated ShopItem items = 15;//物品奖励
        optional bool collect = 16;//是否领取奖励
        repeated DartsGameReward rewards = 17;//每个位置的奖励信息
        repeated int64 payJackpotCoins = 18; //付费后jackpot奖金
    }
]]
DartsGameSingleData.protoKey2Key = {
    ["index"] = "index",
    ["keyId"] = "keyId",
    ["key"] = "key",
    ["price"] = "price",
    ["expireAt"] = "expireAt",
    ["expire"] = "expire",
    ["status"] = "status",
    ["pay"] = "pay",
    ["totalItems"] = "totalItems",
    ["leftItems"] = "leftItems",
    ["jackpots"] = "jackpots",
    ["jackpotMax"] = "jackpotMax",
    ["jackpotCoins"] = "jackpotCoins",
    ["collect"] = "collect",
    ["coins"] = "coins",
    ["items"] = "items",
    ["rewards"] = "rewards",
    ["payJackpotCoins"] = "payJackpotCoins"
}

function DartsGameSingleData:ctor()
    for _, key in pairs(self.protoKey2Key) do
        self:set(key):get(key)
    end
end

function DartsGameSingleData:parseData(data)
    -- local starCount = self:getJackpots()
    for pKey, key in pairs(self.protoKey2Key) do
        if key == "items" then
            local shopItemList = {}
            for _, data in ipairs(data[key]) do
                local shopItem = ShopItem:create()
                shopItem:parseData(data)
                table.insert(shopItemList, shopItem)
            end
            self["set" .. self:getUperKey(key)](self, shopItemList)
        elseif key == "rewards" then
            local rewards = {}
            for _, data in ipairs(data[key]) do
                local dartsGameReward = DartsGameReward:create()
                dartsGameReward:parseData(data)
                table.insert(rewards, dartsGameReward)
            end
            self["set" .. self:getUperKey(key)](self, rewards)
        else
            local value = data[key]
            self["set" .. self:getUperKey(key)](self, value)
        end
    end
    --同步之前3星,同步之后不少于3星(付费情况)
    -- if starCount and starCount >= 3 and self:getJackpots() >= 3 then
    --     self._syncBeforeMaxStar = true
    -- else
    --     self._syncBeforeMaxStar = false
    -- end
end

function DartsGameSingleData:setGameStartData(data)
    if data.item then
        self._bulletIndex = tonumber(data.item)
    end
    if data.wheelRewards then
        self._wheelRewards = data.wheelRewards
    -- if self._syncBeforeMaxStar then
    --     for k, v in pairs(self._wheelRewards) do
    --         v.jackpot = false
    --     end
    -- end
    end
    if data.jackpotCoins then
        self._jackpotCoins = data.jackpotCoins
    end
    if data.itemResults then
        self._itemResults = data.itemResults
    end
end

function DartsGameSingleData:getGameStartData()
    return {
        item = self._bulletIndex,
        wheelRewards = self._wheelRewards,
        jackpotCoins = self._jackpotCoins,
        itemResults = self._itemResults
    }
end

--spin后给的数据
function DartsGameSingleData:setResponData(data)
end

--子弹index
function DartsGameSingleData:getBulletIndex()
    return self._bulletIndex or assert(false, "Error Bullet Index!")
end

--获取气球显示的奖励
function DartsGameSingleData:getBubbleRewards(index)
    local rewards = self:getRewards()
    if rewards and rewards[index] then
        local coins = tonumber(rewards[index]:getCoins())
        local info = gLobalItemManager:createLocalItemData("Coins", coins)
        local res = {}
        if coins > 0 then
            res[#res + 1] = info
        end
        if rewards[index]:getItems() then
            for i, v in ipairs(rewards[index]:getItems()) do
                res[#res + 1] = v
            end
        end
        return res
    else
        return {}
    end
end

function DartsGameSingleData:clearLocalData()
    self._wheelRewards = {}
end

--球球是否可产出对应jackpot星星 type = {1 = minor, 2 = major, 3 = grand}
function DartsGameSingleData:isBubbleHaveStar(index, type)
    local isHaveStar = false
    if self._wheelRewards and self._wheelRewards[index] then
        local jackpot = self._wheelRewards[index]['jackpot']
        if jackpot and jackpot[type] then
            local num = tonumber(jackpot[type])
            if num > 0 then
                isHaveStar = true
            end
        end
    end
    return isHaveStar
end

--[[
    jackpotInxList = {} 球球产出minor， major, grand哪个位置的星星数
    starNum = number 星星个数
]]
function DartsGameSingleData:getJackpotInxListAndStarNum(index)
    local jackpotInxList = {}
    local starNum = 0
    if self._wheelRewards and self._wheelRewards[index] then
        local jackpot = self._wheelRewards[index]['jackpot']
        if jackpot then
            for i = 1, #jackpot do
                local num = tonumber(jackpot[i])
                starNum = starNum + num
                for j = 1, num do
                    table.insert(jackpotInxList, i)
                end
            end
        end
    end
    return jackpotInxList, starNum
end

--根据jackpots类型得到本轮游戏对应jackpots的星星数
function DartsGameSingleData:getStarCountByType(_type)
    local starNum = 0
    if self._wheelRewards and #self._wheelRewards > 0 then
        for k, v in pairs(self._wheelRewards) do
            if v.jackpot and v.jackpot[_type] and v.jackpot[_type] > 0 then
                local num = tonumber(v.jackpot[_type])
                starNum = starNum + num
            end
        end
    end
    return starNum
end

--获取jackpot点数通过种类（type: 1-minor, 2-major, 3-grand）
function DartsGameSingleData:getJackpotsByType(type)
    local jackpots = self:getJackpots()
    if jackpots and jackpots[type] then
        return tonumber(jackpots[type])
    end
    return 0
end

--获取jackpot金额通过种类（type: 1-minor, 2-major, 3-grand）
function DartsGameSingleData:getJackpotCoinsByType(type)
    local jackpotCoins = self:getJackpotCoins()
    if jackpotCoins and jackpotCoins[type] then
        return tonumber(jackpotCoins[type])
    end
    return 0
end

--获取付费jackpot金额通过种类（type: 1-minor, 2-major, 3-grand）
function DartsGameSingleData:getPayJackpotCoinsByType(type)
    local payJackpotCoins = self:getPayJackpotCoins()
    if payJackpotCoins and payJackpotCoins[type] then
        return tonumber(payJackpotCoins[type])
    end
    return 0
end

--获取付费确认的金币
function DartsGameSingleData:getPayCoins()
    local payJackpotCoins = self:getPayJackpotCoins()
    local maxCoins = 0
    if payJackpotCoins and #payJackpotCoins > 0 then
        for i = 1, #payJackpotCoins do
            maxCoins = maxCoins + tonumber(payJackpotCoins[i])
        end
    end
    return maxCoins
end

--获取付费弹板上显示的彩金栏
function DartsGameSingleData:getPayLayerJackpot()
    local jackpotType = 3
    local jackpotCoins = 0
    local maxStarNum = 0
    local payJackpotCoins = self:getPayJackpotCoins()
    local jackpots = self:getJackpots()
    if jackpots and payJackpotCoins then
        for i = 1, #jackpots do
            if maxStarNum <= jackpots[i] and jackpots[i] < 3 then
                jackpotType = i
                maxStarNum = jackpots[i]
            end
        end
        if payJackpotCoins[jackpotType] then
            jackpotCoins = payJackpotCoins[jackpotType]
        end
    end
    return jackpotType, jackpotCoins, maxStarNum
end

--（type: 1-minor, 2-major, 3-grand）
function DartsGameSingleData:getPayCoinItem(type)
    local payCoins = self:getPayJackpotCoinsByType(type)
    local info = gLobalItemManager:createLocalItemData("Coins", payCoins)
    return info
end

-- (type: 1-minor, 2-major, 3-grand）
function DartsGameSingleData:getCoinItem(type)
    local coins = self:getJackpotCoinsByType(type)
    local info = gLobalItemManager:createLocalItemData("Coins", coins)
    return info
end

--本局的所有奖励新,返回shopitem
function DartsGameSingleData:getGotRewardList(withOutCoin)
    local items = clone(self:getItems())
    if not withOutCoin and tonumber(self:getCoins()) ~= 0 then
        items[#items + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(self:getCoins()))
    end
    return items
end

--本次击碎气球count
function DartsGameSingleData:getShutBubbleCount()
    if self._wheelRewards then
        return #self._wheelRewards
    else
        return 9
    end
end

--是否可玩
function DartsGameSingleData:canPlay()
    --计算过期
    if globalData.userRunData.p_serverTime * 0.001 - self:getExpirationTime() >= 0 then
        return false
    end
    --判断是否结束(付费了，次数也没了)
    if self:getPay() and self:getLeftItems() <= 0 and self:getCollect() then
        return false
    end
    return true
end

function DartsGameSingleData:getExpirationTime()
    local t = tonumber(self:getExpireAt())
    return t * 0.001
end

function DartsGameSingleData:getAddItemList()
    local itemList = gLobalItemManager:checkAddLocalItemList({p_keyId = self._keyId})
    return itemList
end

function DartsGameSingleData:getVipPoint()
    local list = self:getAddItemList()
    for i = 1, #list do
        local data = list[i]
        if data.p_icon == "Vip" then
            return data.p_num or 0
        end
    end
end

--制作BuyTip数据
function DartsGameSingleData:makeDataForBuyTip()
    local saleData = SaleItemConfig:create()
    saleData.p_keyId = self._keyId
    saleData.p_discounts = self._discount
    saleData.p_originalCoins = self.m_originalCoins
    saleData.p_coins = 0
    saleData.p_price = self._price
    saleData.m_buyPosition = BUY_TYPE.BROKENSALE2
    saleData.p_vipPoint = self:getVipPoint()
    local purchaseData = gLobalItemManager:getCardPurchase(nil, self._price)
    if purchaseData then
        saleData:setClubPoints(tonumber(purchaseData.p_clubPoints) or 0)
    end
    return saleData
end

function DartsGameSingleData:set(key)
    if key then
        local firstUperKey = string.gsub(key, "^.", string.upper(string.sub(key, 1, 1)))
        self["set" .. firstUperKey] = function(self, v)
            self["_" .. key] = v
        end
    end
    return self
end

function DartsGameSingleData:get(key)
    if key then
        local firstUperKey = string.gsub(key, "^.", string.upper(string.sub(key, 1, 1)))
        self["get" .. firstUperKey] = function(self)
            return self["_" .. key]
        end
    end
    return self
end

function DartsGameSingleData:getUperKey(key)
    return string.gsub(key, "^.", string.upper(string.sub(key, 1, 1)))
end

return DartsGameSingleData
