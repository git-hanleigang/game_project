--[[
Author: cxc
Date: 2021-10-20 16:02:53
LastEditTime: 2021-10-20 16:19:42
LastEditors: your name
Description: lucky chips draw
FilePath: /SlotNirvana/src/activities/Activity_LuckyChipsDraw/controller/LuckyChipsDrawManager.lua
--]]
local LuckyChipsDrawManager = class("LuckyChipsDrawManager", BaseActivityControl)

function LuckyChipsDrawManager:ctor()
    LuckyChipsDrawManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckyChipsDraw)
end

-- 关卡内入口名
function LuckyChipsDrawManager:getEntryName()
    return self:getThemeName()
end

function LuckyChipsDrawManager:getConfig()
    if not self.m_config then
        local themeName = self:getThemeName()
        local cofigFileName = "activities/Activity_LuckyChipsDraw/config/" .. themeName .. "Config"
        if util_IsFileExist(cofigFileName..".lua") or util_IsFileExist(cofigFileName..".luac") then
            local tempFileName = string.gsub(cofigFileName, "/", ".")
            self.m_config = require(tempFileName)
        end
    end
    return self.m_config
end

-- 游戏主界面打开
function LuckyChipsDrawManager:showMainLayer(param)
    if not self:isCanShowLayer() then
        return
    end
    local ui = nil
    if gLobalViewManager:getViewByExtendData("LuckyChipsDrawMainUI") == nil then
        local cfg = self:getConfig()
        if cfg and cfg.luaPath then
            ui = util_createFindView(cfg.luaPath .. "LuckyChipsDrawMainUI", param)
            if ui ~= nil then
                gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
            end
        end
    end
    return ui
end

-- 剩余时间弹框
function LuckyChipsDrawManager:showTimeLeftLayer(param)
    local view = nil
    if gLobalViewManager:getViewByExtendData("LuckyChipsDrawMainUI") == nil then
        local cfg = self:getConfig()
        if cfg and cfg.luaPath then
            view = util_createFindView(cfg.luaPath .. "LuckyChipsDrawTimeLeft", param)
            if view then
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
        end
    end
    return view
end

--显示弹窗
function LuckyChipsDrawManager:showLuckyChipsDrawDialog(name, path, skipRotate, func, params, flyCoins)
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByExtendData(name) ~= nil then
        return false
    end
    if path and not util_IsFileExist(path) then
        return false
    end
    local config = {name = name, path = path, skipRotate = skipRotate, func = func, params = params, flyCoins = flyCoins}
    local cfg = self:getConfig()
    if cfg then
        local view = util_createFindView(cfg.luaPath .. "LuckyChipsDrawDialog", config)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return true
end

return LuckyChipsDrawManager
