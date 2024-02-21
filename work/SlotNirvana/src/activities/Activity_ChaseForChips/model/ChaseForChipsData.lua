--[[
   集卡赛季末聚合
]]
local ChaseForChipsTaskData = import(".ChaseForChipsTaskData")
local ChasePassPhaseData = import(".ChasePassPhaseData")
local BaseActivityData = require "baseActivity.BaseActivityData"
local ChaseForChipsData = class("ChaseForChipsData", BaseActivityData)

-- message ChaseForChips {
--     optional string activityId = 1; // 活动ID
--     optional string activityName = 2; //活动名称
--     optional string begin = 3; //活动开启时间
--     optional string end = 4; //活动结束时间
--     optional int64 expireAt = 5; // 活动倒计时
--     optional int64 expire = 6; //活动倒计时秒数
--     optional int64 currentPoint = 7; //奖励的进度
--     repeated ChaseForChipsTaskData tasks = 8; //任务数据
--     repeated ChasePassPointData points = 9; //奖励数据
--     optional bool unlocked = 10; //是否付费解锁pass
--     optional string priceKey = 11;//pass标准档位
--     optional string price = 12;//pass标准价格
--     optional string value = 13;
--   }

function ChaseForChipsData:ctor()
    ChaseForChipsData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChaseForChips)
end

function ChaseForChipsData:parseData(_netData)
    ChaseForChipsData.super.parseData(self, _netData)

    self.p_currentPoint = tonumber(_netData.currentPoint)

    self.p_tasks = {}
    if _netData.tasks and #_netData.tasks > 0 then
        for i=1,#_netData.tasks do
            local passPoint = ChaseForChipsTaskData:create()
            passPoint:parseData(_netData.tasks[i])
            table.insert(self.p_tasks, passPoint)
        end
    end

    self.p_passPhases = {}
    -- self.m_lobbyShowItems = {}
    if _netData.points and #_netData.points > 0 then
        for i=1,#_netData.points do
            local passPoint = ChasePassPhaseData:create()
            passPoint:parseData(_netData.points[i], self.p_currentPoint)
            table.insert(self.p_passPhases, passPoint)
            -- passPoint:insertLobbyShowChips(self.m_lobbyShowItems)
        end
    end

    self.m_totalPoint = self.p_passPhases[#self.p_passPhases]:getTargetPoints()

    self.p_unlocked = _netData.unlocked

    self.p_price = _netData.price
    self.p_key = _netData.key
    self.p_value = _netData.value

    -- 缓存数据，当从关卡中触发
    self:initCacheData()
    ChaseForChipsCfg.setPath(self:getThemeName())
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.ChaseForChips})
end

function ChaseForChipsData:initCacheData()
    if not self.m_cacheData then
        self.m_cacheData = clone(self)
    end
end

function ChaseForChipsData:getCacheData()
    return self.m_cacheData
end

function ChaseForChipsData:syncCacheData()
    self.m_cacheData = clone(self)
end

function ChaseForChipsData:getPrice()
    return self.p_price
end

function ChaseForChipsData:getKey()
    return self.p_key
end

function ChaseForChipsData:getValue()
    return self.p_value
end

function ChaseForChipsData:getCurrentPoint( )
    return self.p_currentPoint or 0
end

function ChaseForChipsData:getTotalPoint( )
    return self.m_totalPoint or 0
end

function ChaseForChipsData:isMax( )
    return self.p_currentPoint >= self.m_totalPoint
end

function ChaseForChipsData:getTasks( )
    return self.p_tasks
end

function ChaseForChipsData:getPassPhasesData( )
    return self.p_passPhases
end

function ChaseForChipsData:getUnlocked( )
    return self.p_unlocked
end

function ChaseForChipsData:getPassPhaseDataByIndex(_index)
    if _index and self.p_passPhases and #self.p_passPhases >= _index then
        return self.p_passPhases[_index]
    end
end

function ChaseForChipsData:getTargetPointList()
    local targetPoints = {}
    if self.p_passPhases and #self.p_passPhases > 0 then
        for i=1,#self.p_passPhases do
            local pData = self.p_passPhases[i]
            table.insert(targetPoints, pData:getTargetPoints())
        end
    end
    return targetPoints
end

--获取入口位置 1：左边，0：右边
function ChaseForChipsData:getPositionBar( )
    return 1
end

return ChaseForChipsData
