--[[
    装修排行榜
    author: 徐袁
    time: 2021-09-09 14:57:13
]]
local RedecorNet = require("activities.Activity_Redecor.net.RedecorNet")
local RedecorShowTopManager = class("RedecorShowTopManager", BaseActivityControl)

function RedecorShowTopManager:ctor()
    RedecorShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RedecorShowTop)
    self:addPreRef(ACTIVITY_REF.Redecor)
    self.m_redecorNet = RedecorNet:getInstance()
end

function RedecorShowTopManager:showMainLayer(entry_name)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("RedecorRankUI") == nil then
        local themeLogic = G_GetMgr(ACTIVITY_REF.Redecor):getThemeLogic()
        local _themeLuaCfg = themeLogic:getLuaCfg()

        local rankUI = util_createView(_themeLuaCfg.rankLayer)
        if rankUI then
            gLobalViewManager:showUI(rankUI, ViewZorder.ZORDER_POPUI)
        end
    end
end

-- 发送获取排行榜消息
function RedecorShowTopManager:getRank(loadingLayerFlag, _callback)
    -- 数据不全 不执行请求
    if not self:getRunningData() then
        return
    end

    local function successCallFunc(resultData)
        local rankData = resultData
        if rankData ~= nil then
            local data = self:getRunningData(ACTIVITY_REF.Redecor)
            if data then
                data:parseRankConfig(rankData)
            end
            if _callback then
                _callback()
            end
        end
    end

    local function failedCallFun(target, code, errorMsg)
        gLobalViewManager:showReConnect()
    end

    self.m_redecorNet:requestGetRank(loadingLayerFlag, successCallFunc, failedCallFun)
end

return RedecorShowTopManager
