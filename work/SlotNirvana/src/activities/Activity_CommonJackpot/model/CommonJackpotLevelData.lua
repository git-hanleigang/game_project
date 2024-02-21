--[[
    档位数据
]]
local CommonJackpotLevelData = class("CommonJackpotLevelData")

function CommonJackpotLevelData:ctor()
end

function CommonJackpotLevelData:parseData(_lvData)
    self.p_key = _lvData.key
    self.p_name = _lvData.name -- 档位名字
    self.p_unlockLv = tonumber(_lvData.unlockLevel) -- 档位解锁等级
    self.p_minBet = tonumber(_lvData.minBet)
    self.p_maxBet = tonumber(_lvData.maxBet)
    self.p_bets = {} -- 档位中包含的bet金币
    if _lvData.bets and #_lvData.bets > 0 then
        for i = 1, #_lvData.bets do
            local _bet = tonumber(_lvData.bets[i])
            table.insert(self.p_bets, _bet)
        end
    end
    self.p_rsWinAmount = {} -- 档位中玩家累计的奖励金币列表
    if _lvData.rsWinAmount and #_lvData.rsWinAmount > 0 then
        for i = 1, #_lvData.rsWinAmount do
            local _rs = tonumber(_lvData.rsWinAmount[i])
            table.insert(self.p_rsWinAmount, _rs)
        end
    end
end

function CommonJackpotLevelData:getKey()
    return self.p_key
end

function CommonJackpotLevelData:getName()
    return self.p_name
end

function CommonJackpotLevelData:getMinBet()
    return self.p_minBet
end

function CommonJackpotLevelData:getMaxBet()
    return self.p_maxBet
end

function CommonJackpotLevelData:getBets()
    return self.p_bets
end

function CommonJackpotLevelData:getWinAmounts()
    return self.p_rsWinAmount
end

-- 档位是否解锁
function CommonJackpotLevelData:isUnlock()
    if globalData.userRunData.levelNum >= self.p_unlockLv then
        return true
    end
    return false
end

function CommonJackpotLevelData:isWinAmoutFull()
    if self.p_rsWinAmount and #self.p_rsWinAmount > 0 then
        local count = 0
        for i = 1, #self.p_rsWinAmount do
            if self.p_rsWinAmount[i] > 0 then
                count = count + 1
            end
        end
        if count >= CommonJackpotCfg.RESPIN_SHOW_MAX then
            return true
        end
    end
    return false
end

-- -- 是否被别人赢走了
-- function CommonJackpotLevelData:isWon()
--     return false
-- end

function CommonJackpotLevelData:getWinAmountIndexByCoin(_coins)
    if not (_coins and _coins > 0) then
        return nil
    end
    if self.p_rsWinAmount and #self.p_rsWinAmount > 0 then
        for i = 1, #self.p_rsWinAmount do
            if self.p_rsWinAmount[i] == _coins then
                return i
            end
        end
    end
    return nil
end

function CommonJackpotLevelData:clearWinAmount()
    self.p_rsWinAmount = {}
end

return CommonJackpotLevelData
