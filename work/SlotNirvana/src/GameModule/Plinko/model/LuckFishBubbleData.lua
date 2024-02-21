--[[
]]
local LuckFishBubbleData = class("LuckFishBubbleData")

function LuckFishBubbleData:ctor()
end

-- message LuckFishBubble {
--     optional int32 pos = 1 ;//气泡位置
--     optional int32 multiple = 2;//奖励倍数
--     optional int32 needCrashCount = 3;//需要碰撞次数
--     optional int32 crashCount = 4;//已经碰撞次数
--     optional bool collect = 5;//是否已经获得
--   }
function LuckFishBubbleData:parseData(_netData)
    self.p_pos = _netData.pos
    self.p_multiple = _netData.multiple
    self.p_needCrashCount = _netData.needCrashCount
    self.p_crashCount = _netData.crashCount
    self.p_collect = _netData.collect
end

function LuckFishBubbleData:getPos()
    return self.p_pos
end

function LuckFishBubbleData:getMultiple()
    return self.p_multiple
end

function LuckFishBubbleData:getNeedCrashCount()
    return self.p_needCrashCount
end

function LuckFishBubbleData:getCrashCount()
    return self.p_crashCount
end

function LuckFishBubbleData:isCrashed()
    return self.p_crashCount >= self.p_needCrashCount
end

-- 手动更改缓存
function LuckFishBubbleData:setCrashCount(_count)
    -- if self.p_crashCount + 1 == self.p_needCrashCount then
    --     self.m_isNeedPlayCrash = true
    -- end
    self.p_crashCount = math.min(_count, self.p_needCrashCount)
end

function LuckFishBubbleData:getCollect()
    return self.p_collect
end

-- function LuckFishBubbleData:isNeedPlayCrash()
--     return self.m_isNeedPlayCrash == true
-- end

-- function LuckFishBubbleData:resetNeedPlayCrash()
--     self.m_isNeedPlayCrash = false
-- end

return LuckFishBubbleData
