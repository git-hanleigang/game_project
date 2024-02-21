--[[
    小猪 三合一促销
]]

util_require("activities.Activity_TrioPiggy.config.TrioPiggyConfig")
local TrioPiggyMgr = class("TrioPiggyMgr", BaseActivityControl)
local TrioPiggyNet = require("activities.Activity_TrioPiggy.net.TrioPiggyNet")

function TrioPiggyMgr:ctor()
    TrioPiggyMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TrioPiggy)
    self.m_net = TrioPiggyNet:getInstance()
end

function TrioPiggyMgr:getTrioEffectivePiggyDatas()
    local effectiveDatas = {}
    local refs = TrioPiggyConfig.TrioPiggyEffectiveRefs
    if refs and #refs > 0 then
        for i = 1, #refs do
            local mgr = G_GetMgr(refs[i])
            if mgr then
                local rData = mgr:getRunningData()
                if rData then
                    table.insert(effectiveDatas, rData)
                end
            end
        end
    end
    return effectiveDatas
end

function TrioPiggyMgr:isTrioPiggyEffective()
    local effectiveDatas = self:getTrioEffectivePiggyDatas()
    if effectiveDatas and #effectiveDatas > 0 then
        return true
    end
    return false
end

-- 请求集卡小猪数据
function TrioPiggyMgr:requestTrioPigInfo(_succ, _fail)
    -- local successFunc = function()
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHIPPIGGY_REQUEST_DATA, true)
    -- end
    -- local failedCallFunc = function()
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHIPPIGGY_REQUEST_DATA, false)
    -- end
    self.m_net:requestTrioPigInfo(_succ, _fail)
end

-- 请求购买三合一小猪（金币小猪，集卡小猪，第二货币小猪打包购买）
function TrioPiggyMgr:requestBuyTrioPiggy()
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TRIOPIGGY_BUY, {isSuc = true})
    end

    local failedCallFunc = function(_errorInfo)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TRIOPIGGY_BUY, {errorInfo = _errorInfo})
    end
    self.m_net:requestBuyTrioPiggy(successFunc, failedCallFunc)
end

-- 主界面
function TrioPiggyMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    local view = util_createView("Activity_TrioPiggyCode.main.TrioPiggyMainLayer", _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 规则界面
function TrioPiggyMgr:showRuleLayer()
    if gLobalViewManager:getViewByExtendData("TrioPiggyRuleLayer") then
        return nil
    end
    local view = util_createView("Activity_TrioPiggyCode.rule.TrioPiggyRuleLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 结算界面
function TrioPiggyMgr:showRewardLayer(_params)
    if gLobalViewManager:getViewByExtendData("TrioPiggyRewardLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_TrioPiggyCode.reward.TrioPiggyRewardLayer", _params)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

return TrioPiggyMgr
