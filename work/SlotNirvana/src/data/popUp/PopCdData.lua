--[[
    弹板cd数据
    author:{author}
    time:2020-11-09 20:24:07
]]
local PopCdData = class("PopCdData")

function PopCdData:ctor()
    self:resetData()
end

-- 重置数据
function PopCdData:resetData()
    -- 弹框配置表
    self.m_tbPopCDs = {}

    -- 最后更新时间
    self.m_lastUpdateTime = 0
end

-- 解析数据
function PopCdData:parseData(data)
    self.m_lastUpdateTime = data.lastUpdateTime or 0

    self.m_tbPopCDs = data.popCDs or {}
end

-- 初始化数据
function PopCdData:initData()
    -- 是否跨天
    local oldSecs = self.m_lastUpdateTime or 0
    if oldSecs > 0 then
        local newSecs = util_getCurrnetTime()
        -- 服务器时间戳转本地时间
        local oldTM = util_UTC2TZ(oldSecs, -8)
        local newTM = util_UTC2TZ(newSecs, -8)

        if oldTM.day ~= newTM.day then
            self:clearLocalData()
        end
    end
end

-- 添加弹板CD
function PopCdData:addPopCd(popUpId, cdSecs)
    if not popUpId then
        return
    end

    cdSecs = cdSecs or 0
    -- 判断CD时间是否为0
    if cdSecs <= 0 then
        return
    end

    local curTime = util_getCurrnetTime()
    local cdTime = curTime + cdSecs

    self.m_lastUpdateTime = curTime
    self.m_tbPopCDs["" .. popUpId] = cdTime

    self:saveLocalData()
end

-- 是否已经冷却
function PopCdData:isCoolDown(popUpId)
    if device.platform == "mac" then
        -- mac开发环境下不判断弹板CD
        return true
    end

    local cdTime = self.m_tbPopCDs["" .. popUpId]
    if not cdTime then
        return true
    end

    local curTime = util_getCurrnetTime()
    if tonumber(curTime) >= tonumber(cdTime) then
        -- 已经CD好
        return true
    end

    return false
end

-- 存本地
function PopCdData:saveLocalData()
    local tbData = {
        lastUpdateTime = self.m_lastUpdateTime,
        popCDs = self.m_tbPopCDs
    }

    local strData = cjson.encode(tbData)
    gLobalDataManager:setStringByField("PopCdData", strData)
end

-- 读取本地
function PopCdData:loadLocalData()
    -- gLobalDataManager:setStringByField("PopCdData", cjson.encode({}))
    local strData = gLobalDataManager:getStringByField("PopCdData", "{}")
    local tbData = cjson.decode(strData)
    self:parseData(tbData)

    self:initData()
end

-- 清理本地数据
function PopCdData:clearLocalData()
    self:resetData()
    self:saveLocalData()
end

return PopCdData
