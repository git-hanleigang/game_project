--[[
    author:JohnnyFred
    time:2020-10-19 16:52:57
]]
local RepartBaseData = require "data.baseDatas.RepartBaseData"
local RepeatFreeSpinData = class("RepeatFreeSpinData", RepartBaseData)
--获取描述信息
function RepeatFreeSpinData:getStrPrize()
    local strPrize =self:getStrEndTime() .. " PST time."
    return strPrize
end
return RepeatFreeSpinData
