-- word 进度条
local WordProgressRewardData = util_require("activities.Activity_Word.model.WordProgressRewardData")
local WordProgressData = class("WordProgressData")

-- message WordProgress {
--     optional int32 pick = 1;//当前收集个数
--     optional int32 total = 2; // 总进度
--     optional int32 finishTimes = 3;// 本轮集满次数
--     repeated WordProgressRewards rewardList = 4;
--   }
function WordProgressData:parseData(_netData)
    self.p_pick = _netData.pick
    self.p_total = _netData.total
    self.p_finishTimes = _netData.finishTimes

    self.p_rewardList = {}
    if _netData.rewardList and #_netData.rewardList > 0 then
        for i = 1, #_netData.rewardList do
            local wprData = WordProgressRewardData:create()
            wprData:parseData(_netData.rewardList[i])
            wprData:setCompletePercent(i)
            table.insert(self.p_rewardList, wprData)
        end
    end
end

function WordProgressData:getPick()
    return self.p_pick
end

function WordProgressData:getTotal()
    return self.p_total
end

function WordProgressData:getFinishTimes()
    return self.p_finishTimes
end

function WordProgressData:getRewardList()
    return self.p_rewardList
end

return WordProgressData