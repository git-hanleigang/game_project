--[[
    装修促销
    author: 徐袁
    time: 2021-09-09 14:57:13
]]
local THEME_LOGIC = {
    ["Activity_Redecor"] = "activities.Activity_Redecor.config.RedecorThemeLogic"
}
local RedecorNet = require("activities.Activity_Redecor.net.RedecorNet")
local RedecorSaleManager = class("RedecorSaleManager", BaseActivityControl)

function RedecorSaleManager:ctor()
    RedecorSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RedecorSale)
    self:addPreRef(ACTIVITY_REF.Redecor)
    self.m_redecorNet = RedecorNet:getInstance()
end

function RedecorSaleManager:getThemeLogic()
    -- local themeName = self:getThemeName()
    -- local themeLogic = util_require(THEME_LOGIC[themeName])
    -- assert(themeLogic ~= nil, "!!! ERROR CONFIG, THEME_LOGIC not find themeName " .. themeName)
    -- return themeLogic:getInstance()
    local themeLogic = G_GetMgr(ACTIVITY_REF.Redecor):getThemeLogic()
    return themeLogic
end

function RedecorSaleManager:showMainLayer(entry_name)
    if not self:isCanShowLayer() then
        return
    end
    local extra_data = nil
    if entry_name == "ConfirmNode" or entry_name == "RedecorItemNode" or entry_name == "RedecorWheelSpinNode" then
        extra_data = {isShowSpinNode = true}
    end

    local themeLogic = self:getThemeLogic()
    local themeLuaCfg = themeLogic:getLuaCfg()
    local uiView = util_createFindView(themeLuaCfg.promotionLayer, extra_data)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)

    return uiView
end

return RedecorSaleManager
