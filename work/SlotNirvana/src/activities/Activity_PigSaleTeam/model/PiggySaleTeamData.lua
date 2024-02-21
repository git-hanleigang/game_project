--[[
Author: cxc
Date: 2021-07-14 15:54:35
LastEditTime: 2021-07-15 18:18:26
LastEditors: Please set LastEditors
Description: 公会小猪折扣
FilePath: /SlotNirvana/src/activities/Activity_PigSaleTeam/model/PiggySaleTeamData.lua
--]]
-- message ClanPigBankDiscountConfig {
-- 	optional int32 expire = 1;
-- 	optional int64 expireAt = 2;
-- 	optional string activityId = 3;
-- 	optional int32 nonClanDisCount = 4;//非公会折扣
-- 	optional int32 clanDiscount = 5;//工会折扣
--  optional int32 discount = 6;//当前折扣
--   }
local BaseActivityData = require "baseActivity.BaseActivityData"
local PiggySaleTeamData = class("PiggySaleTeamData", BaseActivityData)

function PiggySaleTeamData:parseData(data)
    PiggySaleTeamData.super.parseData(self, data)
    if data.discount then
        self.p_discount = data.discount or 0
    end
    if data.nonClanDisCount then
        self.p_nonClanDiscount = data.nonClanDisCount or 0
    end
    if data.clanDiscount then
        self.p_clanDiscount = data.clanDiscount or 0
    end
end

function PiggySaleTeamData:getDiscount(isIgnoreNovice)
    local upperRate = 0
    if not isIgnoreNovice then
        local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
        local isInNoviceDiscount = piggyBankData and piggyBankData:checkInNoviceDiscount()
        if isInNoviceDiscount then
            upperRate = piggyBankData:getNoviceFirstDiscount() or 0
        end
    end

    if self:isRunning() and self.p_discount then
        return self.p_discount + upperRate
    end

    return upperRate
end

function PiggySaleTeamData:getClanDiscount()
    if self:isRunning() and self.p_clanDiscount then
        return self.p_clanDiscount
    end
    return 0
end

function PiggySaleTeamData:getNonClanDiscount()
    if self:isRunning() and self.p_nonClanDiscount then
        return self.p_nonClanDiscount
    end
    return 0
end

return PiggySaleTeamData
