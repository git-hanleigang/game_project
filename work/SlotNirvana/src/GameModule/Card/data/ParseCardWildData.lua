--[[
    author:{author}
    time:2019-12-18 21:44:44
]]
local ParseCardWildData = class("ParseCardWildData")
function ParseCardWildData:ctor()
end

function ParseCardWildData:parseData(_netData)
    self.p_cardId = _netData.cardId
    self.p_year = _netData.year
    self.p_type = _netData.type

    if _netData.expireAts and next(_netData.expireAts) and #_netData.expireAts > 0 then
        self.p_expireAts = {}
        for i = 1, #_netData.expireAts do
            self.p_expireAts[i] = tonumber(_netData.expireAts[i])
        end
    end
end

function ParseCardWildData:getCardId()
    return self.p_cardId
end

function ParseCardWildData:getYear()
    return self.p_year
end

function ParseCardWildData:getType()
    return self.p_type
end

function ParseCardWildData:getExpireAts()
    return self.p_expireAts
end

return ParseCardWildData
