--[[
    弹板点位信息
    author:{author}
    time:2020-08-18 20:36:17
]]
local PopPosInfo = class("PopPosInfo")

function PopPosInfo:ctor()
    -- 弹板点位
    self.p_posId = nil
    self.p_description = ""
    -- 最大弹出数量
    self.p_maxNum = -1
    -- 弹出等级范围
    self.p_levelMin = -1
    self.p_levelMax = -1
    -- 点位是否开启
    self.p_open = 0
    -- 规则表
    self.p_popLimits = {}
end

function PopPosInfo:parseData(data)
    self.p_posId = data.posId
    self.p_description = data.description
    self.p_maxNum = data.maxNum
    self.p_levelMin = data.levelMin
    self.p_levelMax = data.levelMax
    self.p_open = data.open
end

function PopPosInfo:getPosId()
    return self.p_posId
end

function PopPosInfo:getMaxCount()
    return self.p_maxNum
end

function PopPosInfo:getPopLimitList()
    return self.p_popLimits
end

function PopPosInfo:addPopLimit(info)
    table.insert(self.p_popLimits, info)
end

function PopPosInfo:checkLvRule(nLv)
    local _minLv = self.p_levelMin
    local _maxLv = self.p_levelMax
    if (_minLv and _minLv > 0 and nLv < _minLv) or (_maxLv and _maxLv > 0 and nLv > _maxLv) then
        return false
    end
    return true
end

-- 筛选优先级排序
function PopPosInfo:sortPopLimits()
    local limitList = self.p_popLimits
    -- 根据筛选权重排序
    table.sort(
        limitList,
        function(a, b)
            return tonumber(a:getFiltOrder()) > tonumber(b:getFiltOrder())
        end
    )

    self.p_popLimits = limitList
end

return PopPosInfo
