--[[
]]
require("GameModule.Vip.config.VipConfig")
local VipManager = class("VipManager", BaseGameControl)
function VipManager:ctor()
    VipManager.super.ctor(self)
    self:setRefName(G_REF.Vip)
end

function VipManager:parseData(_netData)
    local data = self:getData()
    if not data then
        data = require("GameModule.Vip.model.VipData"):create()
        self:registerData(data)
    end
    data:parseData(_netData)
end

function VipManager:setExitVipCallFunc(_callFunc)
    self.m_callFunc = _callFunc
end

function VipManager:exitVipSys()
    if self.m_callFunc then
        self.m_callFunc()
        self.m_callFunc = nil
    end
end

-- 进入vip系统的入口
-- vipboost弹板 - viprewardui - vipmainui
-- viplevelup弹板 - viprewardui - vipmainui
-- vipmainui - viprewardui
-- viprewardui - vipmainui

function VipManager:showMainLayer(_callFunc)
    if gLobalViewManager:getViewByName("VipMainUI") ~= nil then
        return nil
    end
    if _callFunc then
        self:setExitVipCallFunc(_callFunc)
    end
    local view = util_createView("views.vipNew.mainUI.VipMainUI")
    view:setName("VipMainUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function VipManager:showRewardLayer(_defaultPageIndex, _callFunc, _flag)
    if gLobalViewManager:getViewByName("VipRewardUI") ~= nil then
        return nil
    end
    if _callFunc then
        self:setExitVipCallFunc(_callFunc)
    end
    local view = util_createView("views.vipNew.rewardUI.VipRewardUI", _defaultPageIndex,_flag)
    view:setName("VipRewardUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- function VipManager:showBlackPlusInfoLayer()
--     if gLobalViewManager:getViewByName("VipBlackPlusInfoUI") ~= nil then
--         return nil
--     end
--     local view = util_createView("views.vipNew.rewardUI.VipBlackPlusInfoUI")
--     view:setName("VipBlackPlusInfoUI")
--     gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
--     return view
-- end

function VipManager:showInfoLayer()
    if gLobalViewManager:getViewByName("VipInfoUI") ~= nil then
        return nil
    end
    local view = util_createView("views.vipNew.mainUI.VipInfoUI")
    view:setName("VipInfoUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function VipManager:showBoostLayer(_vipLevel, _callFunc)
    if gLobalViewManager:getViewByName("VipBoostUI") ~= nil then
        return nil
    end
    if _callFunc then
        self:setExitVipCallFunc(_callFunc)
    end
    local view = util_createView("views.vipNew.boostUI.VipBoostUI", _vipLevel)
    view:setName("VipBoostUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function VipManager:showLevelUpLayer(_callFunc)
    if gLobalViewManager:getViewByName("VipLevelUpUI") ~= nil then
        return nil
    end
    if _callFunc then
        self:setExitVipCallFunc(_callFunc)
    end
    local view = util_createView("views.vipNew.levelUpUI.VipLevelUpUI")
    view:setName("VipLevelUpUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function VipManager:showResetLayer(_over)
    if gLobalViewManager:getViewByName("VipResetUI") ~= nil then
        if _over then
            _over()
        end
        return nil
    end
    local view = util_createView("views.vipNew.mainUI.VipResetUI", _over)
    if view then
        view:setName("VipResetUI")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function VipManager:setShowVipResetYear(_year)
    self.m_showVipResetYear = _year
end

function VipManager:getShowVipResetYear()
    return self.m_showVipResetYear or 0
end

function VipManager:sendExtraRequest(_thisYear)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.showVipResetYear] = _thisYear
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

return VipManager
