--[[
]]
local LuckFishCentreBallData = class("LuckFishCentreBallData")

function LuckFishCentreBallData:ctor()
end

-- message LuckFishCentreBall {
--     optional int32 centreBallCount = 1; //中间气泡球的数量
--     optional int32 needCrashCount = 2; //需要碰撞的次数
--     optional int32 crashCount = 3; //已经碰撞的次数
--   }
function LuckFishCentreBallData:parseData(_netData)
    self.p_centreBallCount = _netData.centreBallCount
    self.p_needCrashCount = _netData.needCrashCount
    self.p_crashCount = _netData.crashCount
end

-- 数值逻辑：初始化时是7，每次进入游戏手动调接口激活，+1
function LuckFishCentreBallData:getBallCount()
    return self.p_centreBallCount
end

function LuckFishCentreBallData:getNeedCrashCount()
    return self.p_needCrashCount
end

function LuckFishCentreBallData:getCrashCount()
    return self.p_crashCount
end

function LuckFishCentreBallData:isCrashed()
    return self.p_crashCount >= self.p_needCrashCount
end

function LuckFishCentreBallData:setCrashCount(_count)
    self.p_crashCount = math.min(_count, self.p_needCrashCount)
end

function LuckFishCentreBallData:isFirstContact()
    return self.p_crashCount == 1
end

return LuckFishCentreBallData
