--[[
]]

--   message ChasePassPhaseData {
--     optional int32 points = 1; //一个阶段的目标值
--     optional ChasePassRewardData freeReward = 2;//免费的奖励
--     optional ChasePassRewardData payReward = 3;//付费的奖励
--   }
local ChasePassRewardData = import(".ChasePassRewardData")
local ChasePassPhaseData = class("ChasePassPhaseData")

function ChasePassPhaseData:parseData(_netData, _curPoint)
    self.p_targetPoints = _netData.points

    self.p_freeReward = nil
    if _netData:HasField("freeReward") then
        self.p_freeReward = ChasePassRewardData:create()
        self.p_freeReward:parseData(_netData.freeReward)
    end
    self.p_payReward = nil
    if _netData:HasField("payReward") then
        self.p_payReward = ChasePassRewardData:create()
        self.p_payReward:parseData(_netData.payReward)
    end

    self.p_curPoint = _curPoint -- 协议中没有的字段，为了方便后续处理数据，每次解析数据时，这里也保存一份
end

function ChasePassPhaseData:getTargetPoints()
    return self.p_targetPoints
end

function ChasePassPhaseData:getFreeReward()
    return self.p_freeReward
end

function ChasePassPhaseData:getPayReward()
    return self.p_payReward
end

function ChasePassPhaseData:getCurrentPoint()
    return self.p_curPoint    
end

-- function ChasePassPhaseData:insertLobbyShowChips(_tb)
--     _tb = _tb or {}
--     if self.p_freeReward and self.p_freeReward:getType() == "ITEM" then
--         local items = self.p_freeReward:getItems()
--         if items and #items > 0 then
--             for i=1,#items do
--                 if items[i]:getType() == "Package" then
--                     table.insert(_tb, items[i])
--                 end
--             end
--         end
--     end
--     return _tb
-- end

return ChasePassPhaseData