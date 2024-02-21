--[[
    任务信息
    author:{author}
    time:2023-11-21 20:01:24
]]

-- message BlindBoxMissionInfo {
--     optional int32 total = 1; //总次数
--     optional int32 current = 2; // 当前进度
--     optional bool completed = 3; // 领取标识
--     optional int32 index = 4; // 任务id
--     optional string description = 5; //任务描述
--     optional string pluralDescription = 6; //任务描述复数
--     optional string param = 7; //参数
--     repeated ShopItem items = 8; //奖励
--     optional string missionType = 9; //任务类型
--     optional bool passTask = 10; //是否pass任务
-- }

local ShopItem = require("data.baseDatas.ShopItem")
local BlindBoxMissionInfo = class("BlindBoxMissionInfo")

function BlindBoxMissionInfo:parseData(data, _isUnlockPass, _expireAt)
    self.m_id = data.index
    self.m_total = data.total or 100
    self.m_cur = data.current or 0
    self.m_completed = data.completed or false
    self.m_param = data.param or ""
    self.m_description = data.description or ""
    self.m_pluralDescription = data.pluralDescription or ""
    self.m_type = data.missionType or "NORMALCARD"

    self.m_items = {}
    for i = 1, #data.items do
        local _info = data.items[i]
        local _item = ShopItem:create()
        _item:parseData(_info)
        table.insert(self.m_items, _item)
    end

    self.m_isPassTask = data.passTask

    self.m_isUnlockPass = _isUnlockPass
    self.m_expireAt = _expireAt
end

function BlindBoxMissionInfo:getId()
    return self.m_id    
end

function BlindBoxMissionInfo:getItems()
    return self.m_items
end

function BlindBoxMissionInfo:getCur()
    return self.m_cur
end

function BlindBoxMissionInfo:getTotal()
    return self.m_total
end

function BlindBoxMissionInfo:isCompleted()
    return self.m_completed
end

function BlindBoxMissionInfo:getType()
    return self.m_type
end

function BlindBoxMissionInfo:getExpireAt()
    return (self.m_expireAt or 0) / 1000
end

function BlindBoxMissionInfo:isUnlockPass()
    return self.m_isUnlockPass
end

function BlindBoxMissionInfo:isPassTask()
    return self.m_isPassTask
end

-- 进度文本
function BlindBoxMissionInfo:getTxtPer()
    return "" .. self.m_cur .. "/" .. self.m_total
end
-- 进度百分比
function BlindBoxMissionInfo:getLoadingPer()
    return math.floor(math.max(0.001, self.m_cur / self.m_total) * 100)
end
-- 说明文本
function BlindBoxMissionInfo:getDesText()
    local text = ""
    if tonumber(self.m_param) > 1 then
        text = string.format(self.m_pluralDescription, self.m_total, self.m_param)
    else
        text = string.format(self.m_description, self.m_total, self.m_param)
    end
    text = string.gsub(text, ";", "\r\n")
    return text
end

function BlindBoxMissionInfo:getRewardNum()
    if self.m_items and #self.m_items > 0 then
        local item = self.m_items[1]
        return item:getNum() or 0
    end
    return 0
end

function BlindBoxMissionInfo:isMax()
    if self.m_cur >= self.m_total then
        return true
    end
    return false
end

function BlindBoxMissionInfo:getStatus()
    if self.m_completed then
        return BlindBoxConfig.MissionStatus.Collect
    else
        -- if self.m_isPassTask then
        --     if self.m_isUnlockPass == true then
        --         if self:isMax() then
        --             return BlindBoxConfig.MissionStatus.Complete
        --         else
        --             return BlindBoxConfig.MissionStatus.UnComplete
        --         end
        --     else
        --         return BlindBoxConfig.MissionStatus.Lock
        --     end
        -- else
            if self:isMax() then
                return BlindBoxConfig.MissionStatus.Complete
            else
                return BlindBoxConfig.MissionStatus.UnComplete
            end
        -- end
    end
end

return BlindBoxMissionInfo
