-- CARDYEARINFO
local ParseCardAlbumSimpleData = require("GameModule.Card.data.ParseCardAlbumSimpleData")
local ParseCardWildData = require("GameModule.Card.data.ParseCardWildData")
local ParseRecoverData = require("GameModule.Card.data.ParseRecoverData")

local ParseYearData = class("ParseYearData")

function ParseYearData:parseData(_yearData)
    -- 年度
    self.p_year = _yearData.year
    -- wild卡总数量
    self.p_wildCards = _yearData.wildCards

    -- 章节简要信息数据
    if _yearData.cardAlums and next(_yearData.cardAlums) then
        self.p_cardAlums = {}
        local count = 1
        while _yearData.cardAlums[count] do
            local cardAlums = ParseCardAlbumSimpleData:create()
            cardAlums:parseData(_yearData.cardAlums[count])
            table.insert(self.p_cardAlums, cardAlums)
            count = count + 1
        end
    end

    -- 回收机数据
    if _yearData.wheelConfig and _yearData.wheelConfig.coolDown ~= nil then
        self.p_wheelConfig = ParseRecoverData:create()
        self.p_wheelConfig:parseData(_yearData.wheelConfig)
    end

    -- wild卡数据
    -- wildCardExpireAt：已弃用
    -- cardWilds：第二赛季新加的字段代替wildCardExpireAt
    if _yearData.cardWilds and next(_yearData.cardWilds) then
        self.p_cardWilds = {}
        local count = 1
        while _yearData.cardWilds[count] do
            local cardWild = ParseCardWildData:create()
            cardWild:parseData(_yearData.cardWilds[count])
            table.insert(self.p_cardWilds, cardWild)
            count = count + 1
        end
    end
end

function ParseYearData:getYear()
    return self.p_year
end

function ParseYearData:getWildCardNum()
    return self.p_wildCards
end

function ParseYearData:getAlbumDatas()
    return self.p_cardAlums
end

function ParseYearData:getWheelConfig()
    return self.p_wheelConfig
end

function ParseYearData:getWildCardDatas()
    return self.p_cardWilds
end

--[[--
    扩展函数
]]
function ParseYearData:getAlbumDataById(_albumId)
    if self.p_cardAlums and #self.p_cardAlums > 0 then
        for i = 1, #self.p_cardAlums do
            local cardAlum = self.p_cardAlums[i]
            if cardAlum:getAlbumId() == _albumId then
                return cardAlum
            end
        end
    end
    return nil
end

function ParseYearData:getClanDataByClanId(_clanId)
    if self.p_cardAlums and #self.p_cardAlums > 0 then
        for i = 1, #self.p_cardAlums do
            local cardAlum = self.p_cardAlums[i]
            local clanData = cardAlum:getClanDataById(_clanId)
            if clanData ~= nil then
                return clanData
            end
        end
    end
    return nil
end

-- 是否有开启的赛季
function ParseYearData:hasSeasonOpening()
    for i = 1, #self.p_cardAlums do
        local cardAlum = self.p_cardAlums[i]
        if cardAlum:isAlbumOpening() then
            return true
        end
    end
    return false
end

-- 检查是否有可兑换的wild卡
function ParseYearData:checkHadCanUseWildCardData()
    local wildCardCount = self:getWildCardNum()
    if wildCardCount and wildCardCount <= 0 then
        return false
    end

    local wildCardDataList = self:getWildCardDatas() or {}
    local curTime = util_getCurrnetTime()
    for idx, cardData in ipairs(wildCardDataList) do
        local expAtList = cardData:getExpireAts()
        if expAtList and #expAtList > 0 then
            if curTime < math.floor(tonumber(expAtList[1]) * 0.001) then
                return true, cardData:getType()
            end
        end
    end

    return false
end

function ParseYearData:setClanCurrent(_clanId, _current)
    if self.p_cardAlums and #self.p_cardAlums > 0 then
        for i = 1, #self.p_cardAlums do
            local cardAlum = self.p_cardAlums[i]
            cardAlum:setClanCurrent(_clanId, _current)
        end
    end
end

return ParseYearData
