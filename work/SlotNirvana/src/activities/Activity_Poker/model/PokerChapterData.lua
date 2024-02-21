--[[
    扑克 章节数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local PokerChapterData = class("PokerChapterData")

function PokerChapterData:ctor()
end

function PokerChapterData:parseData(_netData)
    self.p_coins = tonumber(_netData.coins)
    self.p_baseCoins = tonumber(_netData.rewardBaseCoins)

    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local sItem = ShopItem:create()
            sItem:parseData(_netData.items[i])
            table.insert(self.p_items, sItem)
        end
    end

    self.p_status = _netData.status -- LOCK PLAY FNISH
end

function PokerChapterData:getBaseCoins()
    return self.p_baseCoins
end

function PokerChapterData:getCoins()
    return self.p_coins
end

function PokerChapterData:getItems()
    return self.p_items
end

function PokerChapterData:getStatus()
    return self.p_status
end

return PokerChapterData
