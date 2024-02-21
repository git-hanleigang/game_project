--[[
]]
local EntranceMgr = class("EntranceMgr", BaseActivityControl)

function EntranceMgr:ctor()
    EntranceMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Entrance)
end

-- 显示主界面
function EntranceMgr:showMainLayer(_selIdx)
    return self:showPopLayer(_selIdx)
end

function EntranceMgr:showPopLayer(...)
    local _layer = EntranceMgr.super.showPopLayer(self, ...)
    self:registerLayer(_layer)
    return _layer
end

function EntranceMgr:isCanShowPop()
    if not self:isCanShowLayer() then
        return false
    end

    if not EntranceMgr.super.isCanShowPop(self) then
        return false
    end

    local runningData = self:getRunningData()
    if not runningData or #runningData:getCellDatas() <= 0 then
        return false
    end

    return true
end

function EntranceMgr:getCellIdxByRefName(_refName)
    local idx = 1
    local data = self:getRunningData()
    if data then
        idx = data:getCellIdxByRefName(_refName)
    end
    return idx
end

return EntranceMgr
