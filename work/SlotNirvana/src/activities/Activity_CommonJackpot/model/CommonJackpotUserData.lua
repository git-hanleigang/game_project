--[[
    触发大奖的用户
]]
local CommonJackpotUserData = class("CommonJackpotUserData")

function CommonJackpotUserData:parseData(_netData)
    self.p_udid = _netData.udid
    self.p_head = _netData.head
    self.p_facebookId = _netData.facebookId
    self.p_nickName = _netData.nickName
    self.p_key = _netData.key -- 大奖key
    self.p_coins = tonumber(_netData.coins) -- 赢得的金币
    self.p_jillionId = _netData.jillionId -- 大奖编号
end

function CommonJackpotUserData:getUDID()
    return self.p_udid
end

function CommonJackpotUserData:getHead()
    return self.p_head or ""
end

function CommonJackpotUserData:getFacebookId()
    return self.p_facebookId or ""
end

function CommonJackpotUserData:getNickName()
    return self.p_nickName or ""
end

function CommonJackpotUserData:getKey()
    return self.p_key
end

function CommonJackpotUserData:getCoins()
    return self.p_coins
end

function CommonJackpotUserData:getJillionId()
    return self.p_jillionId
end

return CommonJackpotUserData
