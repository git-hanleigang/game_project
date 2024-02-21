--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-31 14:44:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-31 14:45:48
FilePath: /SlotNirvana/src/activities/Activity_CashBack/model/CashBackNoviceData.lua
Description: 新手期 cashback 数据
--]]
local CashBackData = util_require("activities.Activity_CashBack.model.CashBackData")
local ShopItem = util_require("data.baseDatas.ShopItem")
local CashBackNoviceData = class("CashBackNoviceData", CashBackData)

function CashBackNoviceData:ctor()
    CashBackNoviceData.super.ctor(self)

    -- 新手cashback商城金币档位奖励数据
    self.m_shopCoinsItemList = {}
end

function CashBackNoviceData:parseNoviceData(_data)
    CashBackNoviceData.super.super.parseData(self, _data)

    self:parseShopItemList(_data.rewards or {})

    -- 更新商城显示道具数据
    self:updateShopCoinsConfigDisplayData()

    self.p_open = true
    self:setNovice(true)
    self.p_activityId = _data.activityId
end

function CashBackNoviceData:parseShopItemList(_list)
    self.m_shopCoinsItemList = {}
    for _, info in ipairs(_list) do
        if info.key and info.items and info.items[1] then
            local shopItem = ShopItem:create()
            shopItem:parseData(info.items[1])

            self.m_shopCoinsItemList[info.key] = shopItem
        end
    end
end

function CashBackNoviceData:getCashBackShopItemByKey(_key)
    return self.m_shopCoinsItemList[_key]
end

-- 更新商城显示道具数据
function CashBackNoviceData:updateShopCoinsConfigDisplayData()
    if globalData.shopRunData and globalData.shopRunData.updateNoviceCashBackItem then
        globalData.shopRunData:updateNoviceCashBackItem()
    end
end

function CashBackNoviceData:isRunning()
    local bRunning = table.nums(self.m_shopCoinsItemList) > 0
    if not bRunning then
        return false
    end

    return CashBackNoviceData.super.isRunning(self)
end

return CashBackNoviceData