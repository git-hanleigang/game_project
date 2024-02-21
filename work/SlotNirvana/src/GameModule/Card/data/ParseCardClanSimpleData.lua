--[[
    卡册简要信息
]]
local ParseCardClanSimpleData = class("ParseCardClanSimpleData")

function ParseCardClanSimpleData:ctor()
end

-- message CardClanSimpleInfo {
--     optional string clanId = 1; //卡组id
--     optional string type = 2; //卡组类型
--     optional int32 cur = 3; //当前数
--     optional int32 max = 4; //总数
--    }
function ParseCardClanSimpleData:parseData(_netData)
    self.clanId = _netData.clanId
    self.type = _netData.type
    self.cur = _netData.cur
    self.max = _netData.max
end

function ParseCardClanSimpleData:getClanId()
    return self.clanId
end

function ParseCardClanSimpleData:getType()
    return self.type
end

function ParseCardClanSimpleData:getCur()
    return self.cur
end

function ParseCardClanSimpleData:setCur(_cur)
    self.cur = _cur
end

function ParseCardClanSimpleData:getMax()
    return self.max
end

return ParseCardClanSimpleData