--[[--
    钞票小游戏数据结构解析
]]
local CashBonusVaultData = class("CashBonusVaultData")

function CashBonusVaultData:parseData(data)
    self.type = data.type
    self.expireAt = tonumber(data.expireAt) or 0
    self.maxCoins = tonumber(data.maxCoins) or 0
    self.coinsShowMax = tonumber(data.coinsShowMax) or 0
    self.coinsShowPerSecond = data.coinsShowPerSecond
end

function CashBonusVaultData:getLeftTime()
    if self.expireAt and self.expireAt > 0 then
        return self.expireAt / 1000 - util_getCurrnetTime()
    end
    return 0
end

return CashBonusVaultData
