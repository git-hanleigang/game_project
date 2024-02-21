--[[
]]
local CommonRewards = require "data.baseDatas.CommonRewards"
local ReturnPassPointData = class("ReturnPassPointData")

-- message PassPointData {
--     optional int32 level = 1;
--     optional int64 exp = 2;
--     optional bool collected = 3;
--     optional CommonRewards rewards = 4;
--     optional string description = 5;
--     optional string label = 6; // 底色
--   }
function ReturnPassPointData:parseData(_netData, _curPoint, _unlocked)
    self.p_level = _netData.level
    self.p_exp = tonumber(_netData.exp)
    self.p_collected = _netData.collected
    self.p_commonReward = nil
    if _netData.rewards then
        self.p_commonReward = CommonRewards:create()
        self.p_commonReward:parseData(_netData.rewards)
    end
    
    self.p_description = _netData.description
    self.p_label = _netData.label

    self.m_curPoint = _curPoint
    self.m_unlocked = _unlocked
end

function ReturnPassPointData:getLevel()
    return self.p_level
end

function ReturnPassPointData:getPoint()
    return self.p_exp
end

function ReturnPassPointData:isCollected()
    return self.p_collected
end

function ReturnPassPointData:getCommonReward()
    return self.p_commonReward
end

function ReturnPassPointData:getDesc()
    return self.p_description
end

function ReturnPassPointData:getLabel()
    return self.p_label
end

function ReturnPassPointData:getCurPoint()
    return self.m_curPoint
end

function ReturnPassPointData:isUnlocked()
    return self.m_unlocked
end

-- 解锁pass时要及时同步
function ReturnPassPointData:setUnlocked(_isUnlocked)
    self.m_unlocked = _isUnlocked
end

-- 状态
function ReturnPassPointData:getStatus()
    if self.m_unlocked == false then
        return  ReturnConfig.PassCellStatus.Locked
    elseif self.p_collected == true then
        return  ReturnConfig.PassCellStatus.Collected
    else
        if self.m_curPoint >= self.p_exp then
            return  ReturnConfig.PassCellStatus.Completed
        end
        return  ReturnConfig.PassCellStatus.Unlocked
    end
end

return ReturnPassPointData