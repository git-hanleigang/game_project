--[[
]]
local LuckFishRewardData = util_require("GameModule.Plinko.model.LuckFishRewardData")
local LuckFishBubbleData = util_require("GameModule.Plinko.model.LuckFishBubbleData")
local LuckFishGameData = class("LuckFishGameData")
function LuckFishGameData:ctor()
end

-- message LuckFishGame {
--     optional int32 index = 1; //序号
--     optional string keyId = 2;
--     optional string key = 3;
--     optional string price = 4; //价格
--     optional int64 expireAt = 5; //过期时间
--     optional int64 expire = 6; //剩余时间
--     optional string status = 7; //游戏状态:INIT, PLAYING,FINISH
--     optional bool mark = 8;//是否带付费项
--     optional bool pay = 9;//是否付过费
--     optional bool collect = 10;//是否领过奖
--     optional int32 leftPlayTimes = 11;//剩余可玩次数
--     optional int64 winCoins = 12;//已经获得的金币数
--     optional string source = 13 ;//来源
--     repeated LuckFishReward reward = 14;//底部瓶子奖励
--     repeated LuckFishBubble bubble = 15;//左右气泡配置
--     optional int64 freeShowCoins = 16;//展示用免费金币
--     optional int64 payShowCoins = 17;//展示用付费金币
--     optional int32 centreNeedCrashCount = 18;//中间球需要碰撞的次数
--     optional int32 centreCrashCount = 19;//中间球已经碰撞的次数
--   }
function LuckFishGameData:parseData(_netData)
    self.p_index = _netData.index
    self.p_keyId = _netData.keyId
    self.p_key = _netData.key
    self.p_price = _netData.price
    self.p_expireAt = tonumber(_netData.expireAt)
    self.p_expire = tonumber(_netData.expire)
    self.p_status = _netData.status
    self.p_mark = _netData.mark
    self.p_pay = _netData.pay
    self.p_collect = _netData.collect
    self.p_leftPlayTimes = _netData.leftPlayTimes
    self.p_winCoins = tonumber(_netData.winCoins)
    self.p_source = _netData.source

    self.p_cups = {}
    if _netData.reward and #_netData.reward > 0 then
        for i = 1, #_netData.reward do
            local cupData = LuckFishRewardData:create()
            cupData:parseData(_netData.reward[i])
            table.insert(self.p_cups, cupData)
        end
    end

    self.p_speicalDings = {}
    if _netData.bubble and #_netData.bubble > 0 then
        for i = 1, #_netData.bubble do
            local specialDing = LuckFishBubbleData:create()
            specialDing:parseData(_netData.bubble[i])
            table.insert(self.p_speicalDings, specialDing)
        end
    end

    self.p_freeShowCoins = tonumber(_netData.freeShowCoins)
    self.p_payShowCoins = tonumber(_netData.payShowCoins)
    self.p_centreNeedCrashCount = _netData.centreNeedCrashCount
    self.p_centreCrashCount = _netData.centreCrashCount

    -- if self:getGameNewStatus() == nil then
    --     self:setGameNewStatus(self.p_status == PlinkoConfig.GameStatus.Init)
    -- end
end

-- function LuckFishGameData:setGameNewStatus(_isNewGame)
--     self.m_isNewGame = _isNewGame
-- end

-- function LuckFishGameData:getGameNewStatus()
--     return self.m_isNewGame
-- end

function LuckFishGameData:getIndex()
    return self.p_index
end

function LuckFishGameData:getKeyId()
    return self.p_keyId
end

function LuckFishGameData:getKey()
    return self.p_key
end

function LuckFishGameData:getPrice()
    return self.p_price or 0
end

function LuckFishGameData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function LuckFishGameData:getExpire()
    return self.p_expire or 0
end

function LuckFishGameData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function LuckFishGameData:getGameStatus()
    return self.p_status
end

function LuckFishGameData:isGameWithPay()
    return self.p_mark
end

function LuckFishGameData:isPay()
    return self.p_pay
end

function LuckFishGameData:isCollect()
    return self.p_collect
end

function LuckFishGameData:getLeftPlayTimes()
    return self.p_leftPlayTimes or 0
end

function LuckFishGameData:setLeftPlayTimes(_leftTimes)
    self.p_leftPlayTimes = math.max(0, _leftTimes)
end

function LuckFishGameData:getWinCoins()
    return self.p_winCoins or 0
end

function LuckFishGameData:getCups()
    return self.p_cups
end

function LuckFishGameData:getPurchaseSource()
    return self.p_source
end

function LuckFishGameData:getCupDataByIndex(_index)
    if self.p_cups and _index <= #self.p_cups then
        return self.p_cups[_index]
    end
    return nil
end

function LuckFishGameData:getSpecialDings()
    return self.p_speicalDings
end

function LuckFishGameData:getSpecialDingByIndex(_index)
    if self.p_speicalDings and _index <= #self.p_speicalDings then
        return self.p_speicalDings[_index]
    end
    return nil
end

function LuckFishGameData:getFreeMaxCoins()
    return self.p_freeShowCoins
end

function LuckFishGameData:getPayMaxCoins()
    return self.p_payShowCoins
end

--[[-- 以下5个方法，保持跟 LuckFishBubbleData 中的一致 ---------------------------------------]]
--
function LuckFishGameData:getNeedCrashCount()
    return self.p_centreNeedCrashCount
end

function LuckFishGameData:getCrashCount()
    return self.p_centreCrashCount
end

function LuckFishGameData:isCrashed()
    return self.p_centreCrashCount >= self.p_centreNeedCrashCount
end

-- 手动更改缓存
function LuckFishGameData:setCrashCount(_count)
    self.p_centreCrashCount = math.min(_count, self.p_centreNeedCrashCount)
end
--
--[[-- -------------------------------------------------------------------------------------]]
function LuckFishGameData:isFirstContact()
    return self.p_centreCrashCount == 1
end

return LuckFishGameData
