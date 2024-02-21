--[[
]]
local VipCsvData = import(".VipCSVData")
local VipResetData = import(".VipResetData")
local BaseGameModel = require("GameBase.BaseGameModel")
local VipData = class("VipData", BaseGameModel)
function VipData:ctor()
    VipData.super.ctor(self)
    self:setRefName(G_REF.Vip)
end

function VipData:parseData(_netData)
    self.p_configs = {}
    if _netData.config and #_netData.config > 0 then
        for i = 1, #_netData.config do
            local csvData = VipCsvData:create()
            csvData:parseData(_netData.config[i])
            table.insert(self.p_configs, csvData)
        end
    end
    self:setMaxLevel(#self.p_configs)
end

function VipData:parseResetData(_netData)
    self.m_resetData = nil
    self.m_resetData = VipResetData:create()
    self.m_resetData:parseData(_netData)
end

function VipData:getResetData()
    return self.m_resetData
end

function VipData:getConfigs()
    return self.p_configs
end

function VipData:setMaxLevel(_max)
    self.m_maxLevel = _max
end

-- 最大级别
function VipData:getMaxLevel()
    return self.m_maxLevel
end

function VipData:getVipLevelInfo(_vipLevel)
    if _vipLevel and _vipLevel <= table.nums(self.p_configs) then
        local info = self.p_configs[_vipLevel]
        return info
    end
    return nil
    -- assert(info ~= nil, "vipData :等级 %d 数据错误, level = " .. _vipLevel)
end

--金币百分比
function VipData:getVipCoinBonusPer(_vipLevel)
    local info = self.p_configs[_vipLevel]
    -- assert(info ~= nil, "vipData :等级 %d 数据错误, level = " .. _vipLevel)
    return info.coinPackages
end

return VipData
