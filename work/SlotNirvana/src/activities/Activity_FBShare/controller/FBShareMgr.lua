--[[
    author:{author}
    time:2021-09-28 14:22:08
]]
util_require("activities.Activity_FBShare.config.FBShareCfg")
local FBShareMgr = class("FBShareMgr", BaseActivityControl)

function FBShareMgr:ctor()
    FBShareMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FBShare)
end

function FBShareMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("Activity_FBShare") ~= nil then
        return nil
    end
    local ui = util_createView("Activity/Activity_FBShare", data)
    ui:setName("Activity_FBShare")
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    return ui
end

function FBShareMgr:requestCollectCoins()
    local function success()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FBSHARE_COLLECT, {isSuc = true})
    end
    local function fail()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FBSHARE_COLLECT, {isSuc = false})
        gLobalViewManager:showReConnect()
    end
    G_GetNetModel(NetType.FBShare):requestCollectCoins(success, fail)
end

return FBShareMgr
