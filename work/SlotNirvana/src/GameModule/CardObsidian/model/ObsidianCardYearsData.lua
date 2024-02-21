--[[
]]
local ParseYearData = require("GameModule.Card.data.ParseYearData")
local ObsidianCardYearsData = class("ObsidianCardYearsData")

local status = {
    offline = "OFF_LINE",
    online = "ON_LINE",
    coming = "COMING_SOON"
}

function ObsidianCardYearsData:parseData(_netData)
    self.yearsData = {}
    if _netData and #_netData > 0 then
        for i = 1, #_netData do
            local yearsdata = ParseYearData:create()
            yearsdata:parseData(_netData[i])
            table.insert(self.yearsData, yearsdata)
        end
    end
    self:parseCollectionSeasonIDs()
end

function ObsidianCardYearsData:getYearsData()
    return self.yearsData
end

function ObsidianCardYearsData:getExpireAt(_albumId)
    if self.yearsData and #self.yearsData > 0 then
        for i = #self.yearsData, 1, -1 do
            local _cardAlums = self.yearsData[i]:getAlbumDataById(_albumId)
            if _cardAlums then
                return _cardAlums:getExpireAt() / 1000
            end
        end
    end
    return 0
end

-- 历史赛季collection黑曜卡册赛季解析
function ObsidianCardYearsData:parseCollectionSeasonIDs()
    self.m_CardCollectionSeasonIDs = {}
    if self.yearsData and #self.yearsData > 0 then
        for i = #self.yearsData, 1, -1 do
            local _cardAlums = self.yearsData[i]:getAlbumDatas()
            if _cardAlums then
                for j = #_cardAlums, 1, -1 do
                    local _info = _cardAlums[j]
                    if _info then
                        local _status = _info:getStatus()
                        if _status == status.offline then
                            table.insert(self.m_CardCollectionSeasonIDs, _info)
                        end
                    end
                end
            end
        end
    end
end

-- 历史赛季collection是否显示黑曜卡册入口
function ObsidianCardYearsData:isCollectionShowObsitionCard()
    return #self.m_CardCollectionSeasonIDs > 0
end

function ObsidianCardYearsData:getCollectionShowObsitionCard()
    return self.m_CardCollectionSeasonIDs
end

return ObsidianCardYearsData
