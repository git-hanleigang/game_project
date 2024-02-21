--[[
Author: cxc
Date: 2021-10-22 14:56:01
LastEditTime: 2021-10-21 16:34:43
LastEditors: your name
Description: 双倍盖戳 活动
FilePath: /SlotNirvana/src/activities/LuckyStamp/controller/MulLuckyStampActMgr.lua
--]]
local MulLuckyStampActMgr = class("MulLuckyStampActMgr", BaseActivityControl)

function MulLuckyStampActMgr:ctor()
    MulLuckyStampActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MulLuckyStamp)
end

function MulLuckyStampActMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function MulLuckyStampActMgr:getHallPath(hallName)
    return hallName .. "Icons/" .. hallName .. "HallNode"
end

-- function MulLuckyStampActMgr:getSlidePath(slideName)
--     return "Icons/" .. slideName .. "SlideNode"
-- end

return MulLuckyStampActMgr
