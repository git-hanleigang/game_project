
local ShopDailySaleManager = class("ShopDailySaleManager", BaseActivityControl)

function ShopDailySaleManager:ctor()
    ShopDailySaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ShopDailySale)
    self.m_lotteryTickets = 0
end

function ShopDailySaleManager:getStoreJumpToViewIndex()
    if self:getRunningData() == nil then
        return 1
    end
    local storePrice = self:getRunningData():getStorePrice()
    -- storePrice = "4.99" -- test
    local priceSringList = string.split(storePrice,".")
    local num10 = tonumber(priceSringList[1])
    local num1 = tonumber(priceSringList[2])
    if not num1 or not num10 then
        release_print("stroePrice=" .. storePrice .. "| num10:" .. tostring(num10) .. "| num1:" .. tostring(num1))
    end
    storePrice = num10 * 100 + num1
    -- 跟当前商城点位最接近的进行匹配
    local index = 1
    local priceList = {}
    local coinsData , gemsData = globalData.shopRunData:getShopItemDatas()
    for i = 1 ,#coinsData do
        -- 由于 tonumber 的c++转换 防止”19.99"之类的转换成了 19.98 精度的情况 采用字符串拆分来分开取整
        local priceSringList = string.split(coinsData[i].p_price,".")
        local price = tonumber(priceSringList[1])  * 100 + tonumber(priceSringList[2])
        table.insert(priceList,price)
    end
    -- 阈值处理
    -- 1.如果当前推荐档位大于或者等于了商城档位的头尾 直接返回
    -- 2.如果推荐档位与前后区间差值相同，向上返回
    -- 3.正常情况下区间向下返回
    if storePrice >= priceList[#priceList] then
        return #priceList
    end
    if storePrice <= priceList[1] then
        return 1
    end
    for i = 1,#priceList do
        if i == #priceList then
            break
        end
        local left = priceList[i]
        local right = priceList[i+1]
        if left <= storePrice and storePrice <= right then
            local subLeft = math.floor(math.abs(storePrice  - left )) 
            local subRight = math.floor(math.abs(right  - storePrice))
            if subLeft == subRight or subRight < subLeft then
                index = i + 1
            else
                index = i
            end
            break
        end
    end
    return index
end

function ShopDailySaleManager:getStorePetJumpToViewIndex()
    if self:getRunningData() == nil then
        return 1
    end
    local storePrice = self:getRunningData():getStorePrice()
    -- storePrice = "4.99" -- test
    local priceSringList = string.split(storePrice,".")
    local num10 = tonumber(priceSringList[1])
    local num1 = tonumber(priceSringList[2])
    if not num1 or not num10 then
        release_print("stroePrice=" .. storePrice .. "| num10:" .. tostring(num10) .. "| num1:" .. tostring(num1))
    end
    storePrice = num10 * 100 + num1
    -- 跟当前商城点位最接近的进行匹配
    local index = 1
    local priceList = {}
    local coinsData , gemsData, hotData, petData = globalData.shopRunData:getShopItemDatas()
    if not petData or #petData == 0 then
        return 1
    end
    for i = 1 ,#petData do
        -- 由于 tonumber 的c++转换 防止”19.99"之类的转换成了 19.98 精度的情况 采用字符串拆分来分开取整
        local priceSringList = string.split(petData[i].p_price,".")
        local price = tonumber(priceSringList[1])  * 100 + tonumber(priceSringList[2])
        table.insert(priceList,price)
    end
    -- 阈值处理
    -- 1.如果当前推荐档位大于或者等于了商城档位的头尾 直接返回
    -- 2.如果推荐档位与前后区间差值相同，向上返回
    -- 3.正常情况下区间向下返回
    if storePrice >= priceList[#priceList] then
        return #priceList
    end
    if storePrice <= priceList[1] then
        return 1
    end
    for i = 1,#priceList do
        if i == #priceList then
            break
        end
        local left = priceList[i]
        local right = priceList[i+1]
        if left <= storePrice and storePrice <= right then
            local subLeft = math.floor(math.abs(storePrice  - left )) 
            local subRight = math.floor(math.abs(right  - storePrice))
            if subLeft == subRight or subRight < subLeft then
                index = i + 1
            else
                index = i
            end
            break
        end
    end
    return index
end
function ShopDailySaleManager:setStorePrice(_price)
    if self:getRunningData() == nil then
        return
    end
    self:getRunningData():setStorePrice(_price)
end

function ShopDailySaleManager:setStorePrice(_price)
    if self:getRunningData() == nil then
        return
    end
    self:getRunningData():setStorePrice(_price)
end

return ShopDailySaleManager
