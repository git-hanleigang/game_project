--[[
]]
local PerlinkData = class("PerlinkData")
function PerlinkData:ctor()
end

-- +message PearlsLinkGame {
--   optional int32 index = 1;//小游戏序号
--   optional string keyId = 2; // S1
--   optional string price = 3; //价格
--   optional string key = 4;//付费点
--   optional string status = 5;//游戏状态
--   optional string source = 6;//来源
--   optional bool collect = 7;//是否领奖
--   optional bool isDown = 8; //是否降档
--   optional string downKeyId = 9;//降完档的S1
--   optional string downPrice = 10;//降完档价格
--   optional int32 v = 11;//玩家的v
--   optional int32 gameType = 12;//玩家是否付费
--   optional int64 expireAt = 13; //过期时间
--   optional int64 expire = 14; //剩余时间
--   optional int64 enterGameWinUpTo = 15; //进入页面的
--   optional int64 jackpotMultiple = 16; //客户端显示jackPot乘倍
--   repeated string range = 17;
--   optional string downKey = 18;//付费点
--   optional bool playFirstAndPayLater = 19;//否要弹先玩后付
--   optional PearlsLinkNewPrice pearlsLinkNewPrice = 20;//新增的价格
-- }
function PerlinkData:parseData(_netData)
    self.p_index = _netData.index
    self.p_keyId = _netData.keyId
    self.p_key = _netData.key
    self.p_price = _netData.price
    self.p_expireAt = tonumber(_netData.expireAt)
    self.p_expire = tonumber(_netData.expire)
    self.p_status = _netData.status
    self.p_collect = _netData.collect
    self.p_source = _netData.source
    self.p_gameType = _netData.gameType
    self.p_enterGameWinUpTo = _netData.enterGameWinUpTo
    self.p_jackpotMultiple = _netData.jackpotMultiple
    self.p_range = _netData.range
    self.p_isDown = _netData.down
    self.p_downKeyId = _netData.downKeyId
    self.p_downPrice = _netData.downPrice
    self.p_downKey = _netData.downKey
    self.p_playFirstAndPayLater = _netData.playFirstAndPayLater
    if _netData.pearlsLinkNewPrice then
        self:praseNewPrice(_netData.pearlsLinkNewPrice)
    end
end

function PerlinkData:praseNewPrice(_data)
    self.p_newKey = _data.key
    self.p_newKeyId = _data.keyId
    self.p_newPrice = _data.price
    self.p_newdownKey = _data.downKey
    self.p_newdownPrice = _data.downPrice
    self.p_newdownKeyId = _data.downKeyId
end

function PerlinkData:getPayLater()
    return self.p_playFirstAndPayLater or false
end

function PerlinkData:getNewPrice()
    self.newP = {}
    if self.p_isDown then
        self.newP.key = self.p_newdownKey
        self.newP.keyId = self.p_newdownKeyId
        self.newP.price = self.p_newdownPrice
    else
        self.newP.key = self.p_newKey
        self.newP.keyId = self.p_newKeyId
        self.newP.price = self.p_newPrice
    end
    return self.newP
end

function PerlinkData:getIndex()
    return self.p_index
end

function PerlinkData:getKeyId()
    if self.p_isDown then
        return self.p_downKeyId
    else
        return self.p_keyId
    end
end

function PerlinkData:getKey()
    if self.p_isDown then
        return self.p_downKey
    else
        return self.p_key
    end
end

function PerlinkData:getPrice()
    if self.p_isDown then
        return self.p_downPrice or 0
    else
        return self.p_price or 0
    end
end

function PerlinkData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function PerlinkData:getExpire()
    return self.p_expire or 0
end

function PerlinkData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function PerlinkData:getGameStatus()
    return self.p_status
end

function PerlinkData:isCollect()
    return self.p_collect
end

function PerlinkData:getPurchaseSource()
    return self.p_source
end

function PerlinkData:getGameType()
    return self.p_gameType
end

function PerlinkData:getGameWin()
    return self.p_enterGameWinUpTo
end

function PerlinkData:getJackMul()
    return self.p_jackpotMultiple
end

function PerlinkData:getRange()
    return self.p_range
end

return PerlinkData
