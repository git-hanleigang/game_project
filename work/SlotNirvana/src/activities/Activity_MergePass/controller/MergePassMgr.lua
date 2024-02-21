--[[
    合成pass
]]

local MergePassNet = require("activities.Activity_MergePass.net.MergePassNet")
local MergePassMgr = class("MergePassMgr", BaseGameControl)

function MergePassMgr:ctor()
    MergePassMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MergePass)
    self.m_net = MergePassNet:getInstance()
end

function MergePassMgr:parseData(_data)
    if not _data then
        return
    end

    local gameData = self:getData()
    if not gameData then
        gameData = require("activities.Activity_MergePass.model.MergePassData"):create()
        gameData:parseData(_data)
        gameData:setRefName(ACTIVITY_REF.MergePass)
        self:registerData(gameData)
    else
        gameData:parseData(_data)
    end
end

function MergePassMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("MergePassMainLayer") == nil then
        local view = util_createView("Activity_MergePass.Activity.MergePassMainLayer", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function MergePassMgr:shwoInfoLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("MergePassInfo") == nil then
        local view = util_createView("Activity_MergePass.Activity.MergePassInfo", _data)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function MergePassMgr:showPassBuyTicketLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("MergePassBuyTicketLayer") == nil then
        local view = util_createView("Activity_MergePass.Activity.MergePassBuyTicketLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function MergePassMgr:createEntryNode()
    if not self:isCanShowLayer() then
        return nil
    end

    local entry = util_createView("Activity_MergePass.Activity.MergePassLogo")
    return entry
end

function MergePassMgr:sendPassCollect(_data, _type)
    self.m_net:sendPassCollect(_data, _type)
end

function MergePassMgr:sendPassBoxCollect(_data, _type)
    self.m_net:sendPassBoxCollect(_data, _type)
end

function MergePassMgr:buyPassUnlock(_data)
    self.m_net:buyPassUnlock(_data)
end

return MergePassMgr
