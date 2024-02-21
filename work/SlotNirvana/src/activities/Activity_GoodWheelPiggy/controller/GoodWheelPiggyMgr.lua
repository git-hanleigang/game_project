--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:35:38
]]
local GoodWheelPiggyNet = require("activities.Activity_GoodWheelPiggy.net.GoodWheelPiggyNet")
local GoodWheelPiggyMgr = class("GoodWheelPiggyMgr", BaseActivityControl)

function GoodWheelPiggyMgr:ctor()
    GoodWheelPiggyMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GoodWheelPiggy)

    self.m_netModel = GoodWheelPiggyNet:getInstance() -- 网络模块
end

function GoodWheelPiggyMgr:getConfig()
    local themeName = self:getThemeName()
    if not themeName then
        printError("获取主题名失败")
        return
    end
    local config = util_require("activities.Activity_GoodWheelPiggy.config." .. themeName .. "Config")
    return config
end

function GoodWheelPiggyMgr:requestSpin(data)
    local successFunc = function(resultData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GOODWHEELPIGGY_REQUEST_SPIN_SUCESS)
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestSpin(data, successFunc, failedCallFun)
end

-- 是否可在活动总入口中显示
function GoodWheelPiggyMgr:isCanShowInEntrance()
    local data = self:getRunningData()
    if not data then
        return false
    end
    if data:isCompleted() then
        return false
    end
    return GoodWheelPiggyMgr.super.isCanShowInEntrance(self)
end

-- 是否可显示展示页
function GoodWheelPiggyMgr:isCanShowHall()
    local data = self:getRunningData()
    if not data then
        return false
    end
    if data:isCompleted() then
        return false
    end

    return GoodWheelPiggyMgr.super.isCanShowHall(self)
end

function GoodWheelPiggyMgr:isCanShowPop()
    local data = self:getRunningData()
    if not data then
        return false
    end

    if data:isCompleted() then
        return false
    end
    return true
end

function GoodWheelPiggyMgr:showMainLayer(param)
    local themeName = self:getThemeName()
    if not themeName then
        printError("获取主题名失败")
        return
    end
    local view = util_createFindView("Activity/" .. themeName .. "MainLayer", param)
    -- 检查资源完整性
    if view ~= nil and view.isCsbExist ~= nil and view:isCsbExist() then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 去小猪银行 panel
function GoodWheelPiggyMgr:showPiggyBank(param)
    G_GetMgr(G_REF.PiggyBank):showMainLayer()
end

return GoodWheelPiggyMgr
