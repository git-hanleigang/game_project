--[[
    vip重置功能
]]
local VipResetData = class("VipResetData")

function VipResetData:ctor()
end

-- message VipResetConfig {
--     optional string year = 1;
--     optional string month = 2;
--     optional int32 lastYearVipPoints = 3; //去年总vip点数
--     optional string scale = 4; //比例
--     optional int32 lastYearDecVipPoints = 5; //去年12月总vip点数
--     optional int32 thisYearRewardVipPoints = 6; //本年获得的vip点数奖励
--     optional int32 thisYearVipPoints = 7; //本年总vip点数
--     optional int32 thisYearDecVipPoints = 8; //本年12月总vip点数
--     optional int32 registerTotalVipPoints = 9; //注册以来总积分
--   }
function VipResetData:parseData(_netData)
    self.p_year = tonumber(_netData.year)
    self.p_month = tonumber(_netData.month)
    self.p_lastYearVipPoints = _netData.lastYearVipPoints
    self.p_scale = tonumber(_netData.scale)
    self.p_lastYearDecVipPoints = _netData.lastYearDecVipPoints
    self.p_thisYearRewardVipPoints = _netData.thisYearRewardVipPoints
    self.p_thisYearVipPoints = _netData.thisYearVipPoints
    self.p_thisYearDecVipPoints = _netData.thisYearDecVipPoints
    self.p_registerTotalVipPoints = _netData.registerTotalVipPoints
end

function VipResetData:getYear()
    return self.p_year or 0
end

function VipResetData:getMonth()
    return self.p_month or 0
end

function VipResetData:getLastYearVipPoints()
    return self.p_lastYearVipPoints or 0
end

function VipResetData:getScale()
    return self.p_scale or 0
end

function VipResetData:getLastYearDecVipPoints()
    return self.p_lastYearDecVipPoints or 0
end

function VipResetData:getThisYearRewardVipPoints()
    return self.p_thisYearRewardVipPoints or 0
end

function VipResetData:getThisYearVipPoints()
    return self.p_thisYearVipPoints or 0
end

function VipResetData:getThisYearDecVipPoints()
    return self.p_thisYearDecVipPoints or 0
end

function VipResetData:getRegisterTotalVipPoints()
    return self.p_registerTotalVipPoints or 0
end

function VipResetData:getOnlineYear()
    return 2022
end

return VipResetData
