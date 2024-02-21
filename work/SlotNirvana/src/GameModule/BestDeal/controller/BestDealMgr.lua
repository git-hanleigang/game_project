--[[
    关卡促销入口
]]

local BestDealMgr = class("BestDealMgr", BaseGameControl)

function BestDealMgr:ctor()
    BestDealMgr.super.ctor(self)
    
    self:setRefName(G_REF.BestDeal)
end

function BestDealMgr:createEntryNode()
    local flag = self:checkSaleActivityOpen()
    
    if flag then
        local node = util_createView("BestDeal.BestDealEntryNode")
        return node
    end
end

function BestDealMgr:checkSaleActivityOpen()
    if not self:isDownloadRes() then
        return false
    end

    local activitys = self:getActivitys()
    for i,v in ipairs(activitys) do
        local mgr = G_GetMgr(v)
        if mgr then
            local data = mgr:getRunningData()
            if data then
                return true
            end
        end
    end

    return false
end

function BestDealMgr:showSaleMainLayer()
    local activitys = self:getActivitys()
    for i,v in ipairs(activitys) do
        local mgr = G_GetMgr(v)
        if mgr then
            local view = mgr:showMainLayer()
            if view then
                return
            end
        end
    end
end

function BestDealMgr:getActivitys()
    local activitys = {}
    local data = globalData.constantData.BEST_DEAL
    if data ~= "" then
        activitys = string.split(data, ";")
    end
    return activitys
end

return BestDealMgr