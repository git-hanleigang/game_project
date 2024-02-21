-- 气球挑战管理器

local AllpayNet = require("activities.Activity_Allpay.net.AllpayNet")
local AllpayManager = class("AllpayManager", BaseActivityControl)

-- 存一些本地数据
function AllpayManager:ctor()
    AllpayManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Allpay)
    self.m_allpayNet = AllpayNet:getInstance()
end

------------------------------ 活动中用到的一些标记位 ------------------------------
function AllpayManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_Allpay") == nil then
        local mainUI = util_createView("Activity.Activity_Allpay")
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function AllpayManager:requestUpdate()
    self.m_allpayNet:requestUpdate()
end

return AllpayManager
