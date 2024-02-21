--[[
    章节奖励
]]
local JewelManiaRewardData = require("activities.Activity_JewelMania.model.JewelManiaRewardData")
local JewelManiaChapterData = class("JewelManiaChapterData")

function JewelManiaChapterData:ctor()
end

-- message JewelManiaChapter {
--     optional int32 chapter = 1;//章节
--     optional JewelManiaReward freeReward = 2;//免费奖励
--     optional JewelManiaReward payReward = 3;//付费奖励
--     optional string slateSize = 4;//石盘大小 3x3
--   }
function JewelManiaChapterData:parseData(_netData)
    self.p_chapter = _netData.chapter
    self.p_freeReward = nil
    if _netData:HasField("freeReward") then
        local freeData = JewelManiaRewardData:create()
        freeData:parseData(_netData.freeReward)
        self.p_freeReward = freeData
    end
    self.p_payReward = nil
    if _netData:HasField("payReward") then
        local payData = JewelManiaRewardData:create()
        payData:parseData(_netData.payReward)
        self.p_payReward = payData
    end
    self.p_slateSize = _netData.slateSize
end

function JewelManiaChapterData:getChapter()
    return self.p_chapter
end

function JewelManiaChapterData:getFreeReward()
    return self.p_freeReward
end

function JewelManiaChapterData:getPayReward()
    return self.p_payReward
end

function JewelManiaChapterData:getSlateSize()
    local size = util_split(self.p_slateSize, "*")
    return tonumber(size[1]), tonumber(size[2])
end



return JewelManiaChapterData