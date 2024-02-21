--[[
    促销券
    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local PiggyCommonSaleData = class("PiggyCommonSaleData", BaseActivityData)

function PiggyCommonSaleData:parseData(data)
    PiggyCommonSaleData.super.parseData(self, data)
    self.p_expire = data.expire
    self.p_expireAt = tonumber(data.expireAt)
    self.p_activityId = data.activityId
    if data.lastDiscount then
        self.p_lastDiscount = data.lastDiscount
    end

    self:setPiggyCommonSaleFlag(data.expire)
    self:setPiggyCommonSaleParam(data.discount)
end

function PiggyCommonSaleData:setPiggyCommonSaleFlag(nOpenFlag)
    self.nFlag = nOpenFlag
end

function PiggyCommonSaleData:getPiggyCommonSaleFlag()
    return self.nFlag
end

function PiggyCommonSaleData:setPiggyCommonSaleParam(nParam)
    self.nParam = nParam
end

function PiggyCommonSaleData:getPiggyCommonSaleParam(isIgnoreNovice)
    local upperRate = 0
    if not isIgnoreNovice then
        local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
        local isInNoviceDiscount = piggyBankData and piggyBankData:checkInNoviceDiscount()
        if isInNoviceDiscount then
            upperRate = piggyBankData:getNoviceFirstDiscount() or 0
        end
    end
    if self.nParam == nil then
        return upperRate
    else
        if globalData.userRunData and self.p_expireAt > globalData.userRunData.p_serverTime then --小猪未到期
            upperRate = upperRate + self.nParam
        end
    end
    return upperRate
end

function PiggyCommonSaleData:getPiggySaleLastDiscount()
    if self.p_lastDiscount then
        return self.p_lastDiscount
    end
    return nil
end

function PiggyCommonSaleData:beingOnPiggyCommonSale()
    if self.nFlag and self.nFlag > 0 then
        return true
    end
    return false
end

return PiggyCommonSaleData
