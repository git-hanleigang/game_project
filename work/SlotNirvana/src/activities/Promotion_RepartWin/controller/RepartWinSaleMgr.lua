--[[
Author: cxc
Date: 2021-10-20 12:28:18
LastEditTime: 2021-10-20 12:28:24
LastEditors: zzy
Description: LuckyWinnner
FilePath: /SlotNirvana/src/activities/Promotion_RepartWin/controller/RepartWinSaleMgr.lua
--]]
local RepartWinSaleMgr = class("RepartWinSaleMgr", BaseActivityControl)

function RepartWinSaleMgr:ctor()
    RepartWinSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RepartWin)
end

function RepartWinSaleMgr:getEntryPath(_entryName)
    return "" .. _entryName .. "/RepartWinNode"
end

function RepartWinSaleMgr:getHallPath(hallName)
    return hallName  .. "/" .. hallName .."HallNode"
end

function RepartWinSaleMgr:getPopPath(popName)
    return popName  .. "/" .. popName
end


return RepartWinSaleMgr
