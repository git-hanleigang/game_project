--
--版权所有:{company}
-- Des:解析卡册数据
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardClanData = require("GameModule.Card.data.ParseCardClanData")
local ParseCardAlbumData = class("ParseCardAlbumData")
function ParseCardAlbumData:ctor()
end

function ParseCardAlbumData:parseData(data)
    self.albumId = data.albumId
    self.status = data.status
    self.current = data.current
    self.total = data.total
    self.year = data.year
    self.season = data.season
    self.linkCards = data.linkCards
    self.getReward = data.getReward
    self.coins = data.coins
    self.linkCards = data.linkCards

    self.cardClans = {}
    self.cardSpecialClans = {} -- 特殊卡册以type为key的map结构（方便之后拓展）
    if data.cardClans and #data.cardClans > 0 then
        -- 常规集卡章节
        for i = 1, #data.cardClans do
            if CardSysRuntimeMgr:isNormalClan(data.cardClans[i].type) then
                local clanData = ParseCardClanData:create()
                clanData:parseData(data.cardClans[i])
                table.insert(self.cardClans, clanData)
            elseif (data.albumId == CardSysRuntimeMgr:getCurAlbumID()) and CardSysRuntimeMgr:isQuestMagicClan(data.cardClans[i].type) then
                local list = self.cardSpecialClans[data.cardClans[i].type]
                if not list then
                    list = {}
                end
                local clanData = ParseCardClanData:create()
                clanData:parseData(data.cardClans[i])
                table.insert(list, clanData)
                self.cardSpecialClans[data.cardClans[i].type] = list
            end
        end

        -- 只处理当前赛季的特殊章节，以往赛季的特殊章节看不见不处理即可
        if data.albumId == CardSysRuntimeMgr:getCurAlbumID() then
            -- magic章节数据
            G_GetMgr(G_REF.CardSpecialClan):parseData(data.cardClans, data.magicCoins)
        end
    end

    self.rewards = {}
    if data.rewards and #data.rewards > 0 then
        for i = 1, #data.rewards do
            local sItem = ShopItem:create()
            sItem:parseData(data.rewards[i])
            table.insert(self.rewards, sItem)
        end
    end

    self.linkWheels = {}
    if data.linkWheels and #data.linkWheels > 0 then
        for i = 1, #data.linkWheels do
            self.linkWheels[i] = data.linkWheels[i]
        end
    end
    self.askChipCD = tonumber(data.askChipCD)
    self.round = data.round

    self.roundCoins = {}
    if data.roundCoins and #data.roundCoins > 0 then
        for i = 1, #data.roundCoins do
            table.insert(self.roundCoins, tonumber(data.roundCoins[i]))
        end
    end
end

function ParseCardAlbumData:getRound()
    return self.round
end

function ParseCardAlbumData:setRound(_round)
    self.round = _round
end

function ParseCardAlbumData:getRoundRewardCoins()
    return self.roundCoins
end

function ParseCardAlbumData:isGetAllCards()
    if self.cardClans and #self.cardClans > 0 then
        for i = 1, #self.cardClans do
            local clanData = self.cardClans[i]
            if not clanData:isGetAllCards() then
                return false
            end
        end
    end
    return true
end

return ParseCardAlbumData
