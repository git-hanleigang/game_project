--[[
Author: cxc
Date: 2021-10-14 15:30:20
LastEditTime: 2021-10-14 15:41:16
LastEditors: your name
Description: 公会小猪折扣权益
FilePath: /SlotNirvana/src/activities/Activity_PigSaleTeam/controller/PigSaleTeamManager.lua
--]]
local PigSaleTeamManager = class("PigSaleTeamManager", BaseActivityControl)

function PigSaleTeamManager:ctor()
    PigSaleTeamManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PigClanSale)
end

return PigSaleTeamManager
