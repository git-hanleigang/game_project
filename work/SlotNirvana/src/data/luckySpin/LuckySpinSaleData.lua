--[[
    author:{author}
    time:2019-04-18 21:53:40
]]

local LuckySpinSaleData = class("LuckySpinSaleData")

LuckySpinSaleData.p_score = nil         -- pay table
LuckySpinSaleData.p_expireAt = nil
LuckySpinSaleData.p_expire = nil        
LuckySpinSaleData.p_isExist = nil

function LuckySpinSaleData:ctor()
    self.p_isExist = false
end

function LuckySpinSaleData:parseData( data )          
    self.p_score = cjson.decode(data.score)
    self.p_expireAt = data.expireAt  
    self.p_expire = tonumber(data.expire)
    self.p_isExist = true
end

function LuckySpinSaleData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function LuckySpinSaleData:isExist()
    if self.p_expire and self.p_expire > 0 then
        return true
    end
    return false
end

-- cxc 2021年04月01日12:16:18 将 信号3个一样的时候 倍数显示 用 服务器发的值
-- "1":"5"  信号1 double时 倍数
-- "2":"6"
-- "3":"8"
-- "4":"9"
-- "5":"10"
-- other:"4" 信号 single时 倍数
-- same:"25" 信号 3个一样是 倍数
function LuckySpinSaleData:getThreeSameMulValue()
    local serverCF = self.p_score or {}
    local same = tonumber(serverCF["same"]) or 0

    return same
end

return LuckySpinSaleData