-- 解析赛季数据
-- 数据结构 CardLinkGame

local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardDropData = require("GameModule.Card.data.ParseCardDropData")
local ParseLinkGameData = class("ParseLinkGameData")

function ParseLinkGameData:ctor()
    self.nadoGames = nil
    self.cells = {}
    self.reward = nil
    self.index = nil
end

function ParseLinkGameData:parseData(data)
    self.nadoGames = data.nadoGames
    if data.cells then
        self.cells = {}
        for i = 1, #data.cells do
            self.cells[i] = {}
            self.cells[i] = self:parseCell(data.cells[i])
        end
    end
    if data.reward then
        self.reward = self:parseReward(data.reward)
    end
    self.index = data.index
end

function ParseLinkGameData:parseCell(cell)
    local temp = {}
    temp.value = tonumber(cell.value)
    temp.type = cell.type
    temp.icon = cell.icon

    if cell.reward then
        temp.reward = ShopItem:create()
        temp.reward:parseData(cell.reward, true)
    end
    return temp
end

function ParseLinkGameData:parseReward(rewardData)
    local temp = {}
    if rewardData.coins and tonumber(rewardData.coins) > 0 then
        temp.coins = tonumber(rewardData.coins)
    end
    if rewardData.club and tonumber(rewardData.club) > 0 then
        temp.club = tonumber(rewardData.club)
    end
    if rewardData.bigCoins and tonumber(rewardData.bigCoins) > 0 then -- 大奖金币数
        temp.bigCoins = tonumber(rewardData.bigCoins)
    end
    if rewardData.bigCoinsCount and tonumber(rewardData.bigCoinsCount) > 0 then -- 大奖个数
        temp.bigCoinsCount = rewardData.bigCoinsCount
    end
    if rewardData.goldPackages and tonumber(rewardData.goldPackages) > 0 then
        temp.goldPackages = tonumber(rewardData.goldPackages)
    end
    if rewardData.packages and tonumber(rewardData.packages) > 0 then
        temp.packages = tonumber(rewardData.packages)
    end
    if rewardData.highLimitPoints and tonumber(rewardData.highLimitPoints) > 0 then
        temp.highLimitPoints = tonumber(rewardData.highLimitPoints)
    end

    if rewardData.rewards and #rewardData.rewards > 0 then
        if not temp.rewards then
            temp.rewards = {}
        end
        for i = 1, #rewardData.rewards do
            local cell = ShopItem:create()
            cell:parseData(rewardData.rewards[i], true)
            temp.rewards[i] = cell
        end
    end
    if rewardData.cardDrops and #rewardData.cardDrops > 0 then
        if not temp.cardDrops then
            temp.cardDrops = {}
        end
        for i = 1, #rewardData.cardDrops do
            local pcData = ParseCardDropData:create()
            pcData:parseData(rewardData.cardDrops[i])
            temp.cardDrops[i] = pcData
        end
    end
    if next(temp) ~= nil then
        return temp
    end
    return nil
end

return ParseLinkGameData
