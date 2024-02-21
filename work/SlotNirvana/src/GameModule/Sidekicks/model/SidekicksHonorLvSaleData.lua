--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-12 18:21:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-13 11:52:26
FilePath: /SlotNirvana/src/GameModule/Sidekicks/model/SidekicksHonorLvSaleData.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksHonorLvSaleData = class("SidekicksHonorLvSaleData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function SidekicksHonorLvSaleData:ctor(_data)
    self._level = _data.level or 0 -- 系统等级
    self._key = _data.key or "" -- 促销价格
    self._keyId = _data.keyId or "" -- 促销价格
    self._price = _data.price or "" -- 促销价格
    -- 促销奖励物品
    self:parseItemList(_data.items or {})
    self._coins = toLongNumber(_data.coins) -- 促销奖励金币
end

function SidekicksHonorLvSaleData:getLevel()
    return self._level or 0
end
function SidekicksHonorLvSaleData:getKeyId()
    return self._keyId or ""
end
function SidekicksHonorLvSaleData:getPrice()
    return self._price or 0
end
function SidekicksHonorLvSaleData:getCoins()
    return self._coins or 0
end

-- 促销奖励物品
function SidekicksHonorLvSaleData:parseItemList(_list)
    self._itemList = {}
    for i,v in ipairs(_list) do
        local data = ShopItem:create()
        data:parseData(v)
        table.insert(self._itemList, data)
    end
end
function SidekicksHonorLvSaleData:getItemList()
    return self._itemList
end

return SidekicksHonorLvSaleData