--[[
    砸蛋奖励
    author:{author}
    time:2023-11-09 14:18:40
]]
local ShopItem = require "data.baseDatas.ShopItem"
local EggPackageInfo = class("EggPackageInfo")

function EggPackageInfo:ctor()
    self.p_coins = toLongNumber(0)
end

function EggPackageInfo:parseData(data)
    self.p_type = data.type
    local re = data.reward
    if re.coins then
        self.p_coins:setNum(re.coins)
    end
    if re.gems then
        self.p_gems = re.gems
    end
    if re.items and #re.items > 0 then
        local shopitem = {}
        for k = 1, #re.items do
            local tempData = ShopItem:create()
            tempData:parseData(re.items[k])
            table.insert(shopitem, tempData)
        end
        self.p_items = shopitem
    end
end

return EggPackageInfo
