-- 解析卡牌掉落历史数据
-- 数据结构
--[[--
      records{}
            card{}
            dropName
            dropTime            
]]
local ParseCardDropRecord = require("GameModule.Card.data.ParseCardDropRecord")
local ParseCardDropHistoryData = class("ParseCardDropHistoryData")

function ParseCardDropHistoryData:ctor()
end

function ParseCardDropHistoryData:parseData(data)
    self.records = {}
    if data.records and #data.records > 0 then
        for i = 1, #data.records do
            local rData = ParseCardDropRecord:create()
            rData:parseData(data.records[i])
            table.insert(self.records, rData)
        end
    end
end

return ParseCardDropHistoryData
