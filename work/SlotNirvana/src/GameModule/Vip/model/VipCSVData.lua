--[[--
    存储的vip.csv数据 
    用作查找数据(经验 奖励百分比 等)
]]
local VipCSVData = class("VipCSVData")

function VipCSVData:parseData(_netData)
    self.levelIndex = math.min(_netData.level, VipConfig.MAX_LEVEL)
    self.levelPoints = _netData.points
    self.coinPackages = tonumber(_netData.coins)
    self.vipPoint = tonumber(_netData.vipPoint)
    self.storeGift = tonumber(_netData.freeCoins)
    self.luckyCharms = tonumber(_netData.luckyCharms)
    self.cashBonus = tonumber(_netData.cashBonus)
    self.vipName = _netData.description
    self.vipPointActivity = _netData.vipPointActivity
    self.vipGiftCoupon = _netData.vipGiftCoupon -- VipGift优惠券折扣
    self.vipGiftCoinsUsd = _netData.vipGiftCoinsUsd -- VipGift金币价值
end

function VipCSVData:getCenterNums()
    return {
        {
            self.coinPackages,
            self.vipPoint,
            self.storeGift,
            self.cashBonus * 100,
            self.cashBonus * 100
        },
        {
            self.cashBonus * 100,
            self.coinPackages,
            self.coinPackages,
            self.vipGiftCoupon,
            self.vipGiftCoinsUsd
        }
    }
end

function VipCSVData:getStoreGift()
    return self.storeGift
end

return VipCSVData
