--[[
    author:{author}
    time:2022-05-16 08:11:35
]]
-- 默认飞行数量
local DEFAULT_FLY_COUNT = 30

local FlyCurrencyInfo = class("FlyCurrencyInfo")

function FlyCurrencyInfo:ctor()
    self:clearData()
end

function FlyCurrencyInfo:clearData()
    -- 货币类型
    self.m_currencyType = ""
    -- 增加数量
    self.m_addValue = 0
    -- 初始数量
    -- self.m_origValue = 0
    -- 起点
    self.m_startPos = nil
    -- 终点
    self.m_endPos = nil
    -- 飞行个数
    self.m_flyCount = nil
end

function FlyCurrencyInfo:setFlyCurrencyInfo(info)
    -- 货币类型
    self.m_currencyType = info.cuyType
    -- 增加数量
    self.m_addValue = info.addValue
    -- 初始数量
    self.m_origValue = info.origValue
    -- 起始位置
    self.m_startPos = info.startPos
    -- 目标位置
    self.m_endPos = info.endPos
end

function FlyCurrencyInfo:getType()
    return self.m_currencyType
end

function FlyCurrencyInfo:getAddValue()
    return self.m_addValue
end

-- function FlyCurrencyInfo:getOrgiValue()
--     return self.m_origValue
-- end

function FlyCurrencyInfo:getStartPos()
    return self.m_startPos
end

function FlyCurrencyInfo:getEndPos()
    return self.m_endPos
end

function FlyCurrencyInfo:flyCount()
    return self.m_flyCount or DEFAULT_FLY_COUNT
end

return FlyCurrencyInfo
