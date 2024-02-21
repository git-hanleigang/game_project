--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardClanData = require("GameModule.Card.data.ParseCardClanData")
-- local ParseYearData = require("GameModule.Card.data.ParseYearData")

local BaseGameModel = require("GameBase.BaseGameModel")
local ObsidianCardData = class("ObsidianCardData", BaseGameModel)

function ObsidianCardData:ctor()
    self:setRefName(G_REF.ObsidianCard)
    -- self.m_CardCollectionSeasonIDs = {}
end

function ObsidianCardData:parseData(_netData, _isHistory)
    self.albumId = _netData.albumId --卡册id
    self.status = _netData.status --ON、OFF、ARCHIVE'
    self.current = _netData.current --当前获得卡数
    self.total = _netData.total --总卡数
    self.year = _netData.year --年份9001(由于没有年的概念，数值取了一个值)
    self.season = _netData.season --赛季05
    self.linkCards = _netData.linkCards --link卡数量
    self.getReward = _netData.getReward --是否获得卡册奖励
    self.coins = _netData.coins --卡册奖励金币数量
    self.linkWheels = _netData.linkWheels --link游戏轮盘icon数据
    self.askChipCD = _netData.askChipCD --索要卡片CD
    self.round = _netData.round --当前赛季轮次
    self.roundCoins = _netData.roundCoins --多轮金币
    self.isHistory = _isHistory

    self.cardClans = nil
    if _netData.cardClans and #_netData.cardClans > 0 then --所有卡组数据
        for i = 1, #_netData.cardClans do --因为黑曜卡册没有年的概念，其实这个数组就一个
            local clanData = ParseCardClanData:create()
            clanData:parseData(_netData.cardClans[i])
            self.cardClans = clanData
        end
    end

    self.rewards = {}
    if _netData.rewards and #_netData.rewards > 0 then --集齐卡册的其他物品奖励
        for i = 1, #_netData.rewards do
            local data = ShopItem:create()
            data:parseData(_netData.rewards[i])
            table.insert(self.rewards, data)
        end
    end

    -- if not self.m_CardAlbumInfo then
    --     self.m_CardAlbumInfo = {}
    -- end
    -- self.m_CardAlbumInfo[tostring(_netData.season)] = self
end

-- function ObsidianCardData:parseHistroyData(_netData)
--     self:parseData(_netData)
--     self.isHistory = true
-- end

-- function ObsidianCardData:parseCurrentAlbumId(_netData)
--     self.currentAlbumId = _netData -- 限时赛季 卡册Id
-- end

-- function ObsidianCardData:parseShortCardYears(_netData)
--     self.yearData = {}
--     for i = 1, #_netData do
--         local yeardata = ParseYearData:create()
--         yeardata:parseData(_netData[i])
--         table.insert(self.yearData, yeardata)
--     end
--     self:parseCollectionSeasonIDs()
-- end

function ObsidianCardData:getClanId()
    return self.cardClans.clanId
end

function ObsidianCardData:getAlbumId()
    return self.albumId
end

function ObsidianCardData:getCards()
    return self.cardClans.cards
end

-- function ObsidianCardData:getYearsData()
--     return self.yearData
-- end

function ObsidianCardData:isGetAllCards()
    return self.cardClans:isGetAllCards()
end

function ObsidianCardData:getCurrent()
    return self.current
end

function ObsidianCardData:getTotal()
    return self.total
end

-- function ObsidianCardData:getExpireAt()
--     local _cardYears = self:getYearsData()
--     for i = #_cardYears, 1, -1 do
--         local _cardAlums = _cardYears[i]:getAlbumDataById(self:getAlbumId())
--         if _cardAlums then
--             return _cardAlums:getExpireAt() / 1000
--         end
--     end
--     return 0
-- end

-- function ObsidianCardData:getCurAlbumID()
--     return self.currentAlbumId or self:getAlbumId()
-- end

function ObsidianCardData:getSeasonID()
    return self.season or nil
end

function ObsidianCardData:getHaveCardNum()
    local count = 0
    local cards = self:getCards()
    if cards and #cards > 0 then
        for i = 1, #cards do
            if cards[i]:getCount() > 0 then
                count = count + 1
            end
        end
    end
    return count
end

-- 阶段奖励
function ObsidianCardData:getPhaseRewards()
    return self.cardClans.quantityRewards
end

-- 获取对应的阶段奖励
function ObsidianCardData:getPhaseRewardByIndex(_index)
    return self.cardClans.quantityRewards[_index]
end

-- 阶段奖励是否完成
function ObsidianCardData:isPhaseRewardCompleted(_index)
    local haveCardNum = self:getHaveCardNum()
    local reward = self:getPhaseRewardByIndex(_index)
    if haveCardNum >= reward:getNum() then
        return true
    end
    return false
end

-- 一页上的卡
function ObsidianCardData:getPageCards(_pageIndex)
    assert(_pageIndex <= ObsidianCardCfg.pageNum, "[CARD][DATA ERROR]:Special clan _pageIndex is out of range. pageIndex = " .. _pageIndex)
    local tb = {}
    local startIndex = 1 + (_pageIndex - 1) * ObsidianCardCfg.pageCardNum
    local endIndex = _pageIndex * ObsidianCardCfg.pageCardNum
    local crads = self:getCards()
    if crads and #crads > 0 then
        for i = 1, #crads do
            if i >= startIndex and i <= endIndex then
                table.insert(tb, crads[i])
            end
        end
    end
    return tb
end

-- 一页上的带new标签的卡
function ObsidianCardData:getPageNewCards(_pageIndex)
    -- 一页10卡，一共3页
    local pageCards = self:getPageCards(_pageIndex)
    local newCards = {}
    if pageCards and pageCards and #pageCards >= 0 then
        for i = 1, #pageCards do
            if pageCards[i]:getNewCard() then
                table.insert(newCards, pageCards[i])
            end
        end
    end
    return newCards
end

-- -- 历史赛季collection黑曜卡册赛季解析
-- function ObsidianCardData:parseCollectionSeasonIDs()
--     self.m_CardCollectionSeasonIDs = {}
--     local _cardYears = self:getYearsData()
--     if _cardYears then
--         for i = #_cardYears, 1, -1 do
--             local _cardAlums = _cardYears[i]:getAlbumDatas()
--             if _cardAlums then
--                 for j = #_cardAlums, 1, -1 do
--                     local _info = _cardAlums[j]
--                     if _info then
--                         local _status = _info:getStatus()
--                         if _status == status.offline then
--                             table.insert(self.m_CardCollectionSeasonIDs, _info)
--                         end
--                     end
--                 end
--             end
--         end
--     end
-- end

-- -- 历史赛季collection是否显示黑曜卡册入口
-- function ObsidianCardData:isCollectionShowObsitionCard()
--     return #self.m_CardCollectionSeasonIDs > 0
-- end

-- function ObsidianCardData:getCollectionShowObsitionCard()
--     return self.m_CardCollectionSeasonIDs
-- end

-- 是否是历史赛季
function ObsidianCardData:isHistorySeason(_seasonId)
    return self.isHistory or false
end

-- -- 设置卡册基本信息 --
-- function ObsidianCardData:setCardAlbumInfo(tInfo)
--     if not self.m_CardAlbumInfo then
--         self.m_CardAlbumInfo = {}
--     end

--     -- local paData = ObsidianCardData:create()
--     self:parseHistroyData(tInfo)
--     if self.season then
--         self.m_CardAlbumInfo[tostring(self.season)] = self
--     end
-- end

-- -- 获得对应卡册基本信息 --
-- function ObsidianCardData:getCardAlbumInfo(seasonId)
--     return self.m_CardAlbumInfo[tostring(seasonId)]
-- end

return ObsidianCardData
