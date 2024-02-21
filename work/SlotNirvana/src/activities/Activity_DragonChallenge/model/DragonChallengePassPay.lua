local DragonChallengePassPay = class("DragonChallengePassPay")

function DragonChallengePassPay:ctor()
    self.type = 0
end

function DragonChallengePassPay:parseData(_data)
    self.p_key = _data.key
    self.p_price = _data.price
    self.p_value = _data.value
end

function DragonChallengePassPay:getKeyId()
    return self.p_key
end

function DragonChallengePassPay:getPrice()
    return self.p_price
end

function DragonChallengePassPay:getValue()
    return self.p_value
end

function DragonChallengePassPay:setType(_type)
    self.type = _type
end

return DragonChallengePassPay