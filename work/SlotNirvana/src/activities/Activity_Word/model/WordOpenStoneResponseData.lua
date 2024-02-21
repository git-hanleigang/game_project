-- word 打开石头返回的数据
local ShopItem = util_require("data.baseDatas.ShopItem")
local WordOpenStoneResponseData = class("WordOpenStoneResponseData")

function WordOpenStoneResponseData:parseData(_responseData)
    self.p_icon = _responseData.icon
    self.p_coins = _responseData.coinsV2
    self.p_items = {}
    if _responseData.items and #_responseData.items > 0 then
        for i = 1, #_responseData.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(_responseData.items[i])
            table.insert(self.p_items, shopItem)
        end
    end
    self.p_repeated = _responseData.repeated
    self.p_completed = _responseData.completed
end

function WordOpenStoneResponseData:getIcon()
    return self.p_icon
end

function WordOpenStoneResponseData:getCoins()
    return self.p_coins
end

function WordOpenStoneResponseData:getItems()
    return self.p_items
end

function WordOpenStoneResponseData:getRepeated()
    return self.p_repeated
end

function WordOpenStoneResponseData:getCompleted()
    return self.p_completed
end

return WordOpenStoneResponseData
