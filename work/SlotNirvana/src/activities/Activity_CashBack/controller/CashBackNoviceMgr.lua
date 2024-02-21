--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-02 20:05:04
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-02 20:28:32
FilePath: /SlotNirvana/src/activities/Activity_CashBack/controller/CashBackNoviceMgr.lua
Description: 新手期 cashback mgr
--]]
local CashBackNoviceMgr = class("CashBackNoviceMgr", BaseActivityControl)

function CashBackNoviceMgr:ctor()
    CashBackNoviceMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CashBackNovice)

    self:setDataModule("activities.Activity_CashBack.model.CashBackNoviceData")
end

-- 新手期数据
function CashBackNoviceMgr:parseNoviceData(_data)
    local data = self:getData()
    if data then
        data:parseNoviceData(_data)
    end
end

return CashBackNoviceMgr