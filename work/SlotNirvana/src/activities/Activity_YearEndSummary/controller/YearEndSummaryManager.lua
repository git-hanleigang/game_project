local YearEndSummaryNet = require("activities.Activity_YearEndSummary.net.YearEndSummaryNet")
local YearEndSummaryManager = class(" YearEndSummaryManager", BaseActivityControl)

-- 构造函数
function YearEndSummaryManager:ctor()
    YearEndSummaryManager.super.ctor(self)

    self:setRefName(ACTIVITY_REF.YearEndSummary)
    self.m_YearEndSummaryNet = YearEndSummaryNet:getInstance()
end

function YearEndSummaryManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local refName = self:getRefName()
    local themeName = self:getThemeName(refName)
    local uiView = util_createView("Activity." .. themeName)
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

function YearEndSummaryManager:isCanShowPop()
    if not self:isHasShowedPop() then
        return YearEndSummaryManager.super.isCanShowPop(self)
    else
        return false
    end
end

function YearEndSummaryManager:createPopLayer(popInfo, ...)
    if not self:isCanShowLobbyLayer() then
        return nil
    end

    local luaFileName = self:getPopModule(true)
    if luaFileName == "" then
        return nil
    end

    return util_createView(luaFileName, popInfo, ...)
end

function YearEndSummaryManager:getPopModule(isFromPop)
    if not self:isDownloadLobbyRes() then
        return ""
    end

    local _popName = self:getPopName()
    if not isFromPop then
        _popName = "Activity_YearEndSummary2023Entrance"
    end
    if _popName ~= "" then
        local _filePath = self:getPopPath(_popName)
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        end
    end
    return ""
end

function YearEndSummaryManager:isHasShowedPop()
    local themeName = self:getThemeName(self:getRefName())
    return gLobalDataManager:getBoolByField("YearEndSummaryKey"..themeName, false)
end

function YearEndSummaryManager:setHasShowedPop()
    local themeName = self:getThemeName(self:getRefName())
    return gLobalDataManager:setBoolByField("YearEndSummaryKey"..themeName, true)
end

function YearEndSummaryManager:showPopByEmail()
    if not self:isCanShowLobbyLayer() then
        return 
    end
    local uiView = util_createView("Activity.Activity_YearEndSummary2023")
    if uiView ~= nil then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
end

function YearEndSummaryManager:showFBShareLayer()
    local uiView = util_createView("Activity.Activity_YearEndSummary2023FBShareLayer")
    if uiView ~= nil then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
end

-- 颜料选择
function YearEndSummaryManager:requestShare()
    self.m_YearEndSummaryNet:requestShare()
end

return YearEndSummaryManager