--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local SevenDaySignDayData = class("SevenDaySignDayData")

SevenDaySignDayData.p_day = nil
SevenDaySignDayData.p_collected = nil
SevenDaySignDayData.p_coins = nil
SevenDaySignDayData.p_multiple = nil
SevenDaySignDayData.p_items = nil

function SevenDaySignDayData:ctor()
end

function SevenDaySignDayData:parseData( data )
    self.p_day = data.day
    self.p_collected = data.collected
    self.p_coins = tonumber(data.coins)
    self.p_multiple = data.multiple
    self.p_items = {}
    for i=1,#data.items do
        local shopItem = ShopItem:create()
        shopItem:parseData(data.items[i],true)
        self.p_items[i] = shopItem
    end
end

return SevenDaySignDayData