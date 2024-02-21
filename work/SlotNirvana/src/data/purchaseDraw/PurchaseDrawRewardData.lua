--[[
Author: cxc
Date: 2021-05-08 17:05:32
LastEditTime: 2021-05-17 19:49:08
LastEditors: Please set LastEditors
Description: HAT TRICK DELUXE 活动 购买充值触发的活动 数据
FilePath: /SlotNirvana/src/data/purchaseDraw/PurchaseDrawRewardData.lua
 --   message HatTrickAwards {
    --     optional int32 pos = 1;
    --     optional string type = 2;// WinAll/Single
    --     repeated ShopItem items = 3;
    --   }
    
--]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local PurchaseDrawRewardData = class("PurchaseDrawRewardData")

function PurchaseDrawRewardData:ctor()
    self.m_idx = 1
    self.m_type = ""
    self.m_rewardList = {}
    self.m_rewardListNoMark = {}
end

function PurchaseDrawRewardData:parseData(data)
    if not data then
        return
    end

    self.m_idx  = data.pos
    self.m_type = data.type

    for i = 1, #(data.items or {}) do
        local itemData = data.items[i]
        local rewardItem = ShopItem:create()
        rewardItem:parseData(itemData)
        table.insert(self.m_rewardList, rewardItem)
    end

    for i = 1, #(data.items or {}) do
        local itemData = data.items[i]
        local rewardItem = ShopItem:create()
        rewardItem:parseData(itemData)
        rewardItem.p_mark = nil
        table.insert(self.m_rewardListNoMark, rewardItem)
    end 
end

function PurchaseDrawRewardData:getIdx()
    if self.m_idx <= 0 then
        return 10
    end
    return self.m_idx
end

function PurchaseDrawRewardData:getRewardType()
    return self.m_type
end

function PurchaseDrawRewardData:checkIsWinAllType()
    return self.m_type == "WinAll"
end

function PurchaseDrawRewardData:getItemList(_bNoMark)
    if _bNoMark then
        return self.m_rewardListNoMark
    end
    return self.m_rewardList
end

return PurchaseDrawRewardData
