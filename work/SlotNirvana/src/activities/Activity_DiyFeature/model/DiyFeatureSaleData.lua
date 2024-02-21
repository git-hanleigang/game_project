local DiyFeatureSaleData = class("DiyFeatureSaleData")

-- message DiyFeatureBuffSale {
--   optional int64 expireAt = 1; // 倒计时
--   repeated DiyFeatureBuffSaleBuy buffSaleBuyDataList = 2; // 每个buff的奖励
-- }
-- message DiyFeatureBuffSaleBuy {
--   optional int32 seq = 1; //  序号
--   optional string type = 2; // 类型
--   optional string key = 3; // 价格的档位
--   optional string price = 4; // 价钱
--   optional string value = 5; // 价钱的链接
--   optional int64 coins = 6; // 金钱
--   optional DiyFeatureBuff buffData = 7; // buff
--   optional double discount = 8; //  折扣
--   optional bool finishPayed = 9; // 是否完成购买
-- }
function DiyFeatureSaleData:ctor() 
end

function DiyFeatureSaleData:parseData(data)
    self.p_expireAt = tonumber(data.expireAt or 0)
    if data.buffSaleBuyDataList and #data.buffSaleBuyDataList > 0 then
        self:parseSale(data.buffSaleBuyDataList)
    end
end

function DiyFeatureSaleData:parseSale(_data)
    local itemList = {}
    for i,v in ipairs(_data) do
        local item = {}
        item.p_seq = v.seq
        item.p_type = v.type
        item.p_key = v.key
        item.p_price = v.price
        item.p_keyId = v.keyId
        item.p_coins = v.coins
        item.p_discount = v.discount
        item.p_finishPayed = v.finishPayed
        local buff = {}
        if v.buffData and v.buffData.buffType then
            buff.p_buffType = v.buffData.buffType
            buff.p_desc = v.buffData.desc
            buff.p_value = v.buffData.value
            buff.p_level = v.buffData.level
            item.buff = buff
        end
        table.insert(itemList,item)
    end
    self:setSort(itemList)
    dump(self.m_items)
end

function DiyFeatureSaleData:setSort(_data)
    if _data and #_data > 0 then
        self.m_items = {}
        local list1 = {}
        local list2 = {}
        for i,v in ipairs(_data) do
            if v.p_finishPayed then
                table.insert(list2,v)
            else
                table.insert(list1,v)
            end
        end
        if #list1 > 0 then
            for i,v in ipairs(list1) do
                table.insert(self.m_items,v)
            end
        end
        if #list2 > 0 then
            for i,v in ipairs(list2) do
                table.insert(self.m_items,v)
            end
        end
    end
end

function DiyFeatureSaleData:getBuff()
    return self.m_items
end

function DiyFeatureSaleData:getExpire()
    return self.p_expireAt or 0
end

function DiyFeatureSaleData:isAllP()
    local a = 1
    for i,v in ipairs(self.m_items) do
        if v.p_finishPayed == false then
            a = 0
        end
    end
    return a
end

return DiyFeatureSaleData