--[[
    特殊章节解锁奖励
]]
local JewelManiaRewardData = require("activities.Activity_JewelMania.model.JewelManiaRewardData")
local JewelManiaSpecialChapterData = class("JewelManiaSpecialChapterData")

function JewelManiaSpecialChapterData:ctor()
end

-- message JewelManiaSpecialChapter {
--     optional string jackpotCoins = 1;
--     optional bool payUnlock = 2;//是否付费解锁
--   }
function JewelManiaSpecialChapterData:parseData(_netData)
    self.p_jackpotCoins = _netData.jackpotCoins
    -- self.p_rewardList = {}
    -- if _netData.rewardList and #_netData.rewardList > 0 then
    --     for i=1,#_netData.rewardList do
    --         local data = JewelManiaRewardData:create()
    --         data:parseData(_netData.rewardList[i])
    --         table.insert(self.p_rewardList, data)
    --     end
    -- end
    -- if self.p_rewardList and #self.p_rewardList > 1 then
    --     table.sort(self.p_rewardList, function(a, b)
    --         return a:getIndex() < b:getIndex()
    --     end)    
    -- end
    self.p_payUnlock = _netData.payUnlock
end

function JewelManiaSpecialChapterData:getJackpotCoins()
    return self.p_jackpotCoins
end

function JewelManiaSpecialChapterData:getRewardList()
    return  self.p_rewardList 
end

function JewelManiaSpecialChapterData:isPayUnlock()
    return  self.p_payUnlock 
end

function JewelManiaSpecialChapterData:getRewardDataByIndex(_index)
    if _index and self.p_rewardList and #self.p_rewardList > 0 then
        for i=1,#self.p_rewardList do
            local rData = self.p_rewardList[i]
            if rData and rData:getIndex() == _index then
                return rData
            end
        end
    end
    return nil
end

return JewelManiaSpecialChapterData