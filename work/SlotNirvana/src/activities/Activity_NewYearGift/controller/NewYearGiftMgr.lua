--[[
]]
util_require("activities.Activity_NewYearGift.config.NewYearGiftCfg")
local NewYearGiftMgr = class("NewYearGiftMgr", BaseActivityControl)

function NewYearGiftMgr:ctor()
    NewYearGiftMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewYearGift)
    self.m_thisYear = 2022
    self.m_submitYear = nil
end

function NewYearGiftMgr:getThisYear()
    return self.m_thisYear
end

function NewYearGiftMgr:isCanShowPop()
    local data = G_GetMgr(ACTIVITY_REF.NewYearGift):getData()
    if not data then
        return false
    end
    if data:isCollected() then
        return false
    end
    return NewYearGiftMgr.super.isCanShowPop(self)
end

function NewYearGiftMgr:showMainLayer(_over)
    if not self:isCanShowLayer() then
        if _over then
            _over()
        end
        return
    end
    local themeName = self:getThemeName()
    if gLobalViewManager:getViewByName(themeName .. "MainLayer") ~= nil then
        if _over then
            _over()
        end
        return
    end
    local view = util_createView("Activity." .. themeName .. "MainLayer", _over)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NewYearGiftMgr:showFillLayer(_address, _over)
    if not self:isCanShowLayer() then
        return
    end
    local themeName = self:getThemeName()
    local str1 = themeName .. "FillLayer"
    local str2 = "Activity." .. themeName .. "FillLayer"
    if themeName == "Activity_NewYearGift_2023" and self:getRunningData():getYears() == "2022" then
        str1 = "Activity_NewYearGift_2022FillLayer"
        str2 = "Activity.Activity_NewYearGift_2022FillLayer"
    end
    if gLobalViewManager:getViewByName(str1) ~= nil then
        return
    end
    local view = util_createView(str2, _address, _over)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NewYearGiftMgr:setNewYearGiftSubmit(_year)
    self.m_submitYear = _year
end

function NewYearGiftMgr:getNewYearGiftSubmit()
    return self.m_submitYear
end

function NewYearGiftMgr:isSubmited()
    if self.m_submitYear == self.m_thisYear then
        return true
    end
    return false
end

function NewYearGiftMgr:sendExtraRequest()
    -- 更改缓存
    self:setNewYearGiftSubmit(self.m_thisYear)
    -- 发送请求
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.NewYearGiftSubmit] = self.m_thisYear
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

return NewYearGiftMgr
