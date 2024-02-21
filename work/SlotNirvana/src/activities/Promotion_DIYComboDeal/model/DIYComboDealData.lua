--[[--
    FB加好友活动 数据
]]
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require("baseActivity.BaseActivityData")
local DIYComboDealData = class("DIYComboDealData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

-- optional SaleItemConfig price = 4; //促销列表
-- repeated DiyComboDealBoxs boxs = 5; //礼盒列表


function DIYComboDealData:ctor()
    DIYComboDealData.super.ctor(self)
    self.p_leftBuyCount = 0
    self.m_boxData = {}
    self.p_saleItem = nil
end

function DIYComboDealData:parseData( data )
    DIYComboDealData.super.parseData(self, data)

    if data.price then
        local saleItemCfg = SaleItemConfig:create()
        saleItemCfg:parseData(data.price)
        self.p_saleItem = saleItemCfg
    end

    if data.boxs and #data.boxs > 0 then
        self.m_boxData = {}
        for i,boxData in ipairs(data.boxs) do
            local oneBoxData = {}
            oneBoxData.boxId = boxData.id --礼盒编号 1-3
            oneBoxData.itemData = {}
            if boxData.items and #boxData.items >0 then
                for i,item in ipairs(boxData.items) do
                    local oneItem = {} 
                    oneItem.boxId = boxData.id --
                    oneItem.rewardId = item.id --物品盒编号 1-4
                    if item.coins and tonumber(item.coins) > 0 then
                        local itemData = gLobalItemManager:createLocalItemData("Coins", tonumber(item.coins),{p_limit = 6})
                        oneItem.item = itemData
                        oneItem.coins = tonumber(item.coins)
                    elseif item.gems and tonumber(item.gems) > 0 then
                        local itemData = gLobalItemManager:createLocalItemData("Gem", tonumber(item.gems),{p_limit = 6})
                        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}
                        oneItem.item = itemData
                        oneItem.gems = tonumber(item.gems)
                    elseif item.items then
                        local itemData = ShopItem:create()
                        itemData:parseData(item.items)
                        oneItem.item = itemData
                    end
                    table.insert(oneBoxData.itemData,oneItem)
                end
            end
            table.insert(self.m_boxData,oneBoxData)
        end
    end

    self.p_leftBuyCount = data.leftTimes or 0
end

function DIYComboDealData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function DIYComboDealData:setExpire(t)
    self.p_expire = t
end
function DIYComboDealData:getExpire()
    return self.p_expire
end

function DIYComboDealData:isRunning()
    if not self:checkOpenLevel() then
        return false
    end

    if self.p_leftBuyCount <= 0 then
        return false
    end

    if self:getOpenFlag() or self:getBuffFlag() then
        if self:isIgnoreExpire() then
            return true
        end

        if self:getExpireAt() > 0 then
            return self:getLeftTime() > 0
        else
            return false
        end
    else
        return false
    end
end

return DIYComboDealData 