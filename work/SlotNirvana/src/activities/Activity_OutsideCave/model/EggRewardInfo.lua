--[[
    砸蛋奖励
    author:{author}
    time:2023-11-09 14:18:40
]]
local ShopItem = require "data.baseDatas.ShopItem"
local EggRewardInfo = class("EggRewardInfo")

function EggRewardInfo:ctor()
    self.m_coins = toLongNumber(0)
end

function EggRewardInfo:parseData(data)
    self.m_order = data.order
    self.m_type = data.type
    self.m_grand = data.grand
    self.m_fetch = data.fetch
    self.m_coins:setNum(data.reward.coins or 0)
    self.m_gems = data.reward.gems
    local re = data.reward.items
    local shopitem = {}
    if re and #re > 0 then
        for k = 1, #re do
            local tempData = ShopItem:create()
            tempData:parseData(re[k])
            table.insert(shopitem, tempData)
        end
    end
    self.m_shopItem = shopitem
end

return EggRewardInfo
