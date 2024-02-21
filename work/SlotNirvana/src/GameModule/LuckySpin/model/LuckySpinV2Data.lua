--[[
    author:{author}
    time:2019-04-18 21:53:40
]]

local LuckySpinV2Data = class("LuckySpinV2Data")

function LuckySpinV2Data:ctor( )
    self.p_isExist = false
end

function LuckySpinV2Data:parseData( data )
    self.p_price = data.price
    self.p_product = data.product                 
    self.p_coins = data.coins  
    self.p_score = cjson.decode(data.score)
    self.p_isExist = true         
    self.p_enjoyStatus = data.enjoyStatus
    self.p_remainingTimes = data.remainingTimes
    self.p_type = data.type
    if data.gearList and #data.gearList > 0 then
        self:parseGear(data.gearList)
    end
    if data.spinRecords and #data.spinRecords > 0 then
        self:parseRecord(data.spinRecords)
    end  
end

function LuckySpinV2Data:parseGear(_data)
    self.m_gear = {}
    local coinsData, gemsData,hotSale = globalData.shopRunData:getShopItemDatas()
    local figer = 0
    if coinsData and coinsData[1] then
        figer = tonumber(coinsData[1].p_id) - 1
    end
    for i,v in ipairs(_data) do
        local item = {}
        item.p_index = tonumber(v.gearIndex) + figer
        item.p_type = v.type
        item.p_gear = tonumber(v.gearIndex)
        item.p_remainingTimes = v.remainingTimes
        table.insert(self.m_gear,item)
    end
end

function LuckySpinV2Data:upDateGear()
    if self.m_gear and #self.m_gear > 0 then
         local coinsData, gemsData,hotSale = globalData.shopRunData:getShopItemDatas()
         local figer = 0
         if coinsData and coinsData[1] then
             figer = tonumber(coinsData[1].p_id) - 1
         end
        for i,v in ipairs(self.m_gear) do
            v.p_index = v.p_gear + figer
        end
    end
end

function LuckySpinV2Data:parseRecord(_data)
    self.m_record = {}
    for i,v in ipairs(_data) do
        local item = {}
        item.p_signal = v.signal
        item.p_count = v.count
        item.p_multiple = v.multiple
        item.p_coins = v.coins
        if v.reels then
            local rm = {}
            for k=1,#v.reels do
                local rel = v.reels[k].reels
                table.insert(rm,rel)
            end
            item.reels = rm
        end
        table.insert(self.m_record,item)
    end
end

function LuckySpinV2Data:resetData()
    self.p_price = nil
    self.p_product = nil      
    self.p_coins = nil
    self.p_score = nil
    self.p_isExist = false  
    self.p_enjoyStatus = false         
end

function LuckySpinV2Data:getGearList()
    return self.m_gear or {}
end

function LuckySpinV2Data:getScore()
    return self.p_score["HIGH"] or {}
end

function LuckySpinV2Data:getNormalScore()
    return self.p_score["NORMAL"] or {}
end

function LuckySpinV2Data:getPrice()
    return self.p_price or 0
end

function LuckySpinV2Data:getCoins()
    return self.p_coins or 0
end

function LuckySpinV2Data:getProut()
    return self.p_product or 0
end

function LuckySpinV2Data:getIsEnjoy()
    return self.p_enjoyStatus or false
end

function LuckySpinV2Data:getRemainTimes()
    return  self.p_remainingTimes or 0
end

function LuckySpinV2Data:getRecod()
    return self.m_record or {}
end

function LuckySpinV2Data:getCurrentRecod()
    return self.m_record[#self.m_record] 
end

function LuckySpinV2Data:getMaxMultipleRecodData()
    if self.m_record then
        if #self.m_record > 1 then
            local item = self.m_record[1]
            local item1 = self.m_record[2]
            if tonumber(item.p_multiple) <= tonumber(item1.p_multiple) then
                return item1
            else
                return item
            end
        else
            return self.m_record[1]
        end
    end
    return
end

function LuckySpinV2Data:getWinMultiple()
    local maxMultipleRecord = self:getMaxMultipleRecodData()
    if maxMultipleRecord then
        return maxMultipleRecord.p_multiple or 0
    end
    return 0
end

function LuckySpinV2Data:isExist()
    return self.p_isExist
end

function LuckySpinV2Data:getType()
    return self.p_type
end



return LuckySpinV2Data