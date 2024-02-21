--[[--
    赛季的简要信息
]]
local ParseCardClanSimpleData = util_require("GameModule.Card.data.ParseCardClanSimpleData")
local ParseCardAlbumSimpleData = class("ParseCardAlbumSimpleData")

-- message CardAlbumSimpleInfo {
--     optional string albumId = 1; //卡册id
--     optional string status = 2; //ON、OFF、ARCHIVE
--     optional int32 current = 3; //当前获得卡数
--     optional int32 total = 4; //总卡数
--     optional int32 year = 5; //年份2019
--     optional int32 season = 6; //赛季05
--     optional int32 linkCards = 7; //link卡数量
--     optional int64 expireAt = 8; //赛季结束时间戳，毫秒
--     optional string backIcon = 9; //底图
--     optional CardSpecialGame specialGame = 10; //集卡第二赛季小游戏 废弃不用
--     optional int32 clans = 11; //章节数量
--     optional int64 startAt = 12; //赛季开启时间戳，毫秒
--     repeated CardClanSimpleInfo cardClans = 13; //卡组简单信息
--     optional int32 round = 14;//当前轮次
--   }

function ParseCardAlbumSimpleData:parseData(tInfo)
    self.albumId = tInfo.albumId
    self.status = tInfo.status
    self.current = tInfo.current
    self.total = tInfo.total
    self.clans = tInfo.clans
    self.year = tInfo.year
    self.season = tInfo.season
    self.linkCards = tInfo.linkCards
    self.expireAt = tInfo.expireAt
    self.backIcon = tInfo.backIcon
    self.startAt = tInfo.startAt -- 赛季开启时间戳
    
    self.round = tInfo.round

    self.cardClans = {}
    if tInfo.cardClans and #tInfo.cardClans > 0 then
        for i = 1, #tInfo.cardClans do
            local clanData = ParseCardClanSimpleData:create()
            clanData:parseData(tInfo.cardClans[i])
            
            -- 客户端缓存数据
            local clanCollectData = CardSysRuntimeMgr:getClanCollectByClanId(clanData:getClanId())
            local isNormalClan = CardSysRuntimeMgr:isNormalClan(clanData.type)
            if isNormalClan and (clanCollectData == nil)  then
                CardSysRuntimeMgr:setClanCollects(clanData:getClanId(), clanData:getCur(), clanData:getMax(), self.round)
            end

            table.insert(self.cardClans, clanData)
        end
    end

end

function ParseCardAlbumSimpleData:getAlbumId()
    return self.albumId
end

function ParseCardAlbumSimpleData:getStatus()
    return self.status
end

function ParseCardAlbumSimpleData:getSeason()
    return self.season
end

function ParseCardAlbumSimpleData:getStartAt()
    return self.startAt
end

function ParseCardAlbumSimpleData:getExpireAt()
    return self.expireAt
end

function ParseCardAlbumSimpleData:getCurrent()
    return self.current
end

function ParseCardAlbumSimpleData:getTotal()
    return self.total
end

function ParseCardAlbumSimpleData:getCardClans()
    return self.cardClans
end

function ParseCardAlbumSimpleData:getRound()
    return self.round
end

-- 赛季是否开启
function ParseCardAlbumSimpleData:isAlbumOpening()
    local nowTime = math.floor(globalData.userRunData.p_serverTime / 1000)
    if self:getStatus() == CardSysConfigs.CardSeasonStatus.online and nowTime < math.floor(tonumber(self:getExpireAt()) / 1000) then
        return true
    end
    return false
end

function ParseCardAlbumSimpleData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = math.floor(tonumber(self:getExpireAt()) / 1000) - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function ParseCardAlbumSimpleData:getClanDataById(_clanId)
    if self.cardClans and #self.cardClans > 0 then
        for i = 1, #self.cardClans do
            local clanData = self.cardClans[i]
            if clanData:getClanId() == _clanId then
                return clanData
            end
        end
    end
    return nil
end

function ParseCardAlbumSimpleData:setClanCurrent(_clanId, _current)
    local clanData = self:getClanDataById(_clanId)
    if clanData then
        clanData:setCur(_current)
    end
end

return ParseCardAlbumSimpleData
