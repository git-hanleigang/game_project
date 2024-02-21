--[[--
    wild兑换数据
]]
local ParseCardAlbumData = require("GameModule.Card.data.ParseCardAlbumData")
local ParseCardExchangeData = require("GameModule.Card.data.ParseCardExchangeData")
local CardSysWildExchangeRunData = class("CardSysWildExchangeRunData")
local ObsidianCardData = require("GameModule.CardObsidian.model.ObsidianCardData")

function CardSysWildExchangeRunData:ctor()
end
--[[
    @desc: 设置wild卡可兑换的年度所有卡片数据
    author:{author}
    time:2021-01-26 17:02:56
    --@tInfo: 
    @return:
]]
function CardSysWildExchangeRunData:setCardExchangeYearCardsInfo(tInfo)
    -- 清理数据 --
    self.m_CardExchangeYearCardsInfo = {}
    -- 解析数据 --

    -- 返回所有赛季的所有卡片 以赛季为单位 --
    if tInfo.cardAlbums then
        self.m_CardExchangeYearCardsInfo.cardAlbums = {}
        for i = 1, #tInfo.cardAlbums do
            local pData = ParseCardAlbumData:create()
            pData:parseData(tInfo.cardAlbums[i])
            self.m_CardExchangeYearCardsInfo.cardAlbums[i] = pData
        end

        if self.m_CardExchangeYearCardsInfo.cardAlbums and #self.m_CardExchangeYearCardsInfo.cardAlbums > 0 then
            -- 按赛季排序
            table.sort(
                self.m_CardExchangeYearCardsInfo.cardAlbums,
                function(a, b)
                    return a.season < b.season
                end
            )
            -- 如果有拼图章节将拼图章节放在最前面
            for i = 1, #self.m_CardExchangeYearCardsInfo.cardAlbums do
                table.sort(
                    self.m_CardExchangeYearCardsInfo.cardAlbums[i].cardClans,
                    function(a, b)
                        local _clanTypeA = string.find(a.type, "PUZZLE") and 1 or 2
                        local _clanTypeB = string.find(b.type, "PUZZLE") and 1 or 2
                        if _clanTypeA == _clanTypeB then
                            return tonumber(a.clanId) < tonumber(b.clanId)
                        else
                            return _clanTypeA < _clanTypeB
                        end
                    end
                )
            end
        end
    end

    -- 限时赛季 黑耀卡
    self.m_shortCardAlbums = {}
    for i = 1, #tInfo.shortCardAlbums do
        local pData = ObsidianCardData:create()
        pData:parseData(tInfo.shortCardAlbums[i])
        self.m_shortCardAlbums[i] = pData
    end

    self.m_CardExchangeYearCardsInfo.expireAt = tInfo.expireAt
    self.m_CardExchangeYearCardsInfo.wildCards = tInfo.wildCards
end

-- 获取wild卡可兑换的年度所有卡片数据 --
function CardSysWildExchangeRunData:getCardExchangeYearCardsInfo()
    return self.m_CardExchangeYearCardsInfo
end

-- 获取限时赛季 黑耀卡
function CardSysWildExchangeRunData:getWildObsidianCardAlbums()
    return self.m_shortCardAlbums or {}
end

function CardSysWildExchangeRunData:getExpireAt()
    return self.m_CardExchangeYearCardsInfo.expireAt
end

--[[
    @desc: 设置wild卡请求兑换数据
    author:{author}
    time:2021-01-26 17:03:10
    --@tInfo: 
    @return:
]]
function CardSysWildExchangeRunData:setCardExchangeInfo(tInfo)
    self.m_CardExchangeInfo = ParseCardExchangeData:create()
    self.m_CardExchangeInfo:parseData(tInfo)
end

-- 获取wild卡请求兑换数据 --
function CardSysWildExchangeRunData:getCardExchangeInfo()
    return self.m_CardExchangeInfo and self.m_CardExchangeInfo.cardInfo
end

return CardSysWildExchangeRunData
