-- 个人累充管理器

local AddPayNet = require("activities.Activity_AddPay.net.AddPayNet")
local AddPayManager = class("AddPayManager", BaseActivityControl)

-- 存一些本地数据
function AddPayManager:ctor()
    AddPayManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AddPay)
    self.m_addPayNet = AddPayNet:getInstance()
    self.m_configInit = false
    self.AddPayConfig = util_require("activities.Activity_AddPay.config.AddPayConfig")

    self:addExtendResList("Activity_AddPayCode")
end

function AddPayManager:getConfig()
    local data = self:getRunningData()
    if not data then
        return
    end
    local cur_theme = data:getThemeName()
    local config_theme = self.AddPayConfig.getThemeName()
    if not cur_theme or cur_theme ~= config_theme or not self.m_configInit then
        self.m_configInit = true
        self.AddPayConfig.setThemeName(cur_theme)
    end
    return self.AddPayConfig
end

------------------------------ 活动中用到的一些标记位 ------------------------------
function AddPayManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_AddPay") == nil then
        local data = self:getRunningData()
        local themeName = data:getThemeName()
        local luaPath = self:getConfig().getThemeFile(themeName)
        local mainUI = util_createFindView(luaPath)
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function AddPayManager:hasRewards()
    local act_data = self:getRunningData()
    if not act_data then
        return false
    end
    return act_data:hasRewards()
end

function AddPayManager:requestCollect()
    self.m_addPayNet:requestCollect()
end

function AddPayManager:recordRewardsList(data)
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    act_data:recordRewardsList(data)
end

function AddPayManager:addRewardPops(pop_list)
    if not pop_list or table.nums(pop_list) <= 0 then
        return
    end

    if self.pop_list then
        printError("AddPayManager 存在掉落列表残留")
        self.pop_list = nil
    end
    self.pop_list = pop_list
end

function AddPayManager:popNext()
    if not self.pop_list then
        return
    end
    if table.nums(self.pop_list) <= 0 then
        self.pop_list = nil
        return
    end

    local popFunc = self.pop_list[1]
    table.remove(self.pop_list, 1)
    if popFunc and type(popFunc) == "function" then
        local bl_succ = popFunc()
        if not bl_succ then
            self:popNext()
        end
    end
end

return AddPayManager
