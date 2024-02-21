-- 排行榜金币滚动

local BaseCoinsRollingControll = require("baseRank.BaseCoinsRollingControll")
local BaseRankCoinsControll = class("BaseRankCoinsControll", BaseCoinsRollingControll)

function BaseRankCoinsControll:getInstance()
    -- p_instance 这里不要与父类同名 否则不会创建单例
    if self.p_instance == nil then
        self.p_instance = BaseRankCoinsControll.new()
    end
    return self.p_instance
end

-- 获取基底
function BaseRankCoinsControll:getBasal(act_ref, ex_key)
    local act_data = self:getActDataByRef(act_ref)
    if act_data then
        if not act_data.getRankCfg then
            printError("排行榜数据需要活动数据类实现方法 getRankCfg 来获取排行榜数据" .. act_ref .. " " .. ex_key)
            return
        end
        local rank_data = act_data:getRankCfg()
        return rank_data.p_prizePool
    end
    return nil
end

function BaseRankCoinsControll:isRunning(act_ref)
    local act_data = self:getActDataByRef(act_ref)
    if act_data and act_data:isRunning() then
        if not act_data.getRankCfg then
            printError("排行榜数据需要活动数据类实现方法 getRankCfg 来获取排行榜数据" .. act_ref)
            return false
        end
        local rank_data = act_data:getRankCfg()
        if rank_data then
            return true
        end
    end
end

return BaseRankCoinsControll
