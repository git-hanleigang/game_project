--[[--
    解析赛季数据
]]
local ParseYearData = require("GameModule.Card.data.ParseYearData")
local ParseCollectNado = require("GameModule.Card.data.ParseCollectNado")
local ParseLinkGameData = require("GameModule.Card.data.ParseLinkGameData")
-- local ParsePuzzleGameData = require("GameModule.Card.data.ParsePuzzleGameData")
local StatuePickGameData = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickGameData")

local ParseSeasonsData = class("ParseSeasonsData")

function ParseSeasonsData:parseData(data)
    self.p_currentAlbumId = data.currentAlbumId
    self.p_cardRecords = data.cardRecords
    self.p_totalLinkCard = data.totalLinkCard -- nado机小红点
    self.p_playLinks = tonumber(data.playLinks) -- nado机玩家玩过的次数

    if data.cardYears and next(data.cardYears) ~= nil then
        self.p_cardYears = {}
        for i = 1, #data.cardYears do
            local years = ParseYearData:create()
            years:parseData(data.cardYears[i])
            table.insert(self.p_cardYears, years)
        end
    end

    if data.nadoGame and data.nadoGame.nadoGames ~= nil then
        self.p_nadoGame = ParseLinkGameData:create()
        self.p_nadoGame:parseData(data.nadoGame)
    end

    if data.collectNado and data.collectNado.currentCards ~= nil then
        self.p_collectNado = ParseCollectNado:create()
        self.p_collectNado:parseData(data.collectNado)
    end

    -- 暂时不用解析，03赛季的拼图卡小游戏数据
    -- self.p_vegasTornado = ParsePuzzleGameData:parseData(data.vegasTornado)

    if StatuePickGameData then
        StatuePickGameData:getInstance():parseData(data.specialGame)
    end
end

-- 当前赛季的卡册Id
function ParseSeasonsData:getCurrentAlbumId()
    return self.p_currentAlbumId
end

-- 卡片历史掉落记录数量
function ParseSeasonsData:getHistoryNewNum()
    return self.p_cardRecords
end
-- 客户端将新的历史数据数量清空
function ParseSeasonsData:setHistoryNewNum(_newNum)
    self.p_cardRecords = _newNum or 0 -- 默认为0
end

-- 总的link收集进度
function ParseSeasonsData:getTotalLinkCard()
    return self.p_totalLinkCard
end

-- link游戏总次数（第二赛季新加）
function ParseSeasonsData:getPlayLinks()
    return self.p_playLinks
end

function ParseSeasonsData:getYearsData()
    return self.p_cardYears
end

function ParseSeasonsData:getNadoGameData()
    return self.p_nadoGame
end

function ParseSeasonsData:getCollectNado()
    return self.p_collectNado
end

function ParseSeasonsData:getVegasTornado()
    return self.p_vegasTornado
end

--[[--
    扩展函数
]]
-- _year: 2019
function ParseSeasonsData:getYearDataById(_year)
    local _cardYears = self.p_cardYears
    for i = 1, #_cardYears do
        local _cardYear = _cardYears[i]
        if _cardYear and _cardYear:getYear() == _year then
            return _cardYear
        end
    end
end

-- 获得赛季信息
function ParseSeasonsData:getAlbumDataById(_albumId)
    local _year = tonumber(string.sub(_albumId, 1, 4))
    local yearData = self:getYearDataById(_year)
    if yearData then
        return yearData:getAlbumDataById(_albumId)
    end
    return nil
end

function ParseSeasonsData:hasSeasonOpening()
    if self.p_cardYears and #self.p_cardYears > 0 then
        for i = 1, #self.p_cardYears do
            local yearData = self.p_cardYears[i]
            if yearData:hasSeasonOpening() then
                return true
            end
        end
    end
    return false
end

function ParseSeasonsData:hasWildCardData()
    if not self.p_cardYears then
        return false
    end
    if #self.p_cardYears == 0 then
        return false
    end
    -- 判断wild卡的数量
    local nWildNum = 0
    for i = 1, #self.p_cardYears do
        local yearData = self.p_cardYears[i]
        nWildNum = nWildNum + (yearData:getWildCardNum() or 0)
    end
    if nWildNum == 0 then
        return false
    end
    -- 判断wild卡的倒计时
    local allExpireAts = {}
    local count = 0
    for i = 1, #self.p_cardYears do
        local yearData = self.p_cardYears[i]
        local wildCards = yearData:getWildCardDatas()
        if wildCards and #wildCards > 0 then
            for j = 1, #wildCards do
                local wildCard = wildCards[j]
                local wildCardType = wildCard:getType()
                local wildExpAts = wildCard:getExpireAts()
                if wildExpAts and #wildExpAts > 0 then
                    for jj = 1, #wildExpAts do
                        count = count + 1
                        table.insert(allExpireAts, {id = count, wildType = wildCardType, expAt = wildExpAts[jj]})
                    end
                end
            end
        end
    end
    if #allExpireAts > 0 then
        local _nearestTime, wildCardType = self:getNearestTime(math.floor(globalData.userRunData.p_serverTime / 1000), allExpireAts)
        if _nearestTime > 0 then
            return true, wildCardType
        end
    end
    return false
end

function ParseSeasonsData:getNearestTime(_nowTime, _expireAts)
    if _expireAts then
        if #_expireAts > 1 then
            table.sort(
                _expireAts,
                function(a, b)
                    if a.expAt == b.expAt then
                        return a.id < b.id
                    else
                        return a.expAt < b.expAt
                    end
                end
            )
        end
        if #_expireAts > 0 then
            for i = 1, #_expireAts do
                local ext = math.floor(_expireAts[i].expAt / 1000)
                if _nowTime < ext then
                    return ext, _expireAts[i].wildType
                end
            end
        end
    end
    return 0
end

return ParseSeasonsData
