local ShopItem = require "data.baseDatas.ShopItem"
local FindProcessAward = class("FindProcessAward")
FindProcessAward.p_process = nil
FindProcessAward.p_coins = nil
FindProcessAward.p_shopItems = nil
FindProcessAward.p_collect = nil
function FindProcessAward:ctor()
    
end

function FindProcessAward:parseData(data)
    self.p_process = data.process
    self.p_coins = tonumber(data.coins)
    if data.shopItems ~= nil and data.shopItems ~= "" then
        local d = data.shopItems
        if d ~= nil and #d > 0 then
              self.p_shopItems = {}
              for i=1,#d do
                    local shopItem = ShopItem:create()
                    shopItem:parseData(d[i])
                    self.p_shopItems[#self.p_shopItems+1] = shopItem
              end
        end
    end
    self.p_collect = data.collect
end


return  FindProcessAward