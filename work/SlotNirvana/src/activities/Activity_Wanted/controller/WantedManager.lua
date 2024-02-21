-- Want 控制类
require("activities.Activity_Wanted.config.WantedCfg")
local WantedNet = require("activities.Activity_Wanted.net.WantedNet")
local WantedManager = class("WantedManager", BaseActivityControl)

function WantedManager:ctor()
    WantedManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Wanted)

    self.m_wantedNet = WantedNet:getInstance()
    --self:registEvents()

    self.m_useNewPath = {
        ["Activity_Wanted_Pet"] = true,
    }
end

function WantedManager:getPopPath(popName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return popName .. "/" .. themeName
    else
        return WantedManager.super.getPopPath(self, popName)
    end
end

function WantedManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/" .. hallName .. "HallNode"
    else
        return WantedManager.super.getHallPath(self, hallName)
    end
end

function WantedManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/" .. slideName .. "SlideNode"
    else
        return WantedManager.super.getSlidePath(self, slideName)
    end    
end

-- 获取最新数据
function WantedManager:requestData()
    local success_call_fun = function(resData)
        local wantedData = self:getRunningData()
        if wantedData then
            if resData ~= nil then
                wantedData:parseData(resData)
            else
                local errorMsg = "parse wanted data error"
                printInfo(errorMsg)
                release_print(errorMsg)
            end
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Wanted})
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end

    self.m_wantedNet:requestData(success_call_fun, faild_call_fun)
end

function WantedManager:registEvents()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end

    if self.bl_registed then
        return
    end
    self.bl_registed = true
    local saved_key = self:getSavedKey()
    local bl_poped = gLobalDataManager:getBoolByField(saved_key, false)
    if not bl_poped then
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if params[1] == true then
                    local spin_data = params[2]
                    if spin_data.action == "SPIN" then
                        self:onSpinResult(spin_data)
                    end
                end
            end,
            ViewEventType.NOTIFY_GET_SPINRESULT
        )
    end
end

function WantedManager:onSpinResult(spin_data)
    local act_data = self:getRunningData()
    if not act_data then
        return
    end

    local play_data = spin_data.extend.oneDaySpecialMission
    if play_data then
        -- 更新数据
        play_data.cur_point = tonumber(play_data.process) -- 当前阶段任务进度
        play_data.max_point = tonumber(play_data.param) -- 目标任务进度
        play_data.bl_complete = play_data.complete -- 是否完成
        if play_data.complete == true then
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_GET_SPINRESULT)
        end
        -- 更新data类
        act_data:setComplete(play_data.bl_complete)
        act_data:setCurProcess(play_data.cur_point)
        act_data:setParam(play_data.max_point)
    end
end

function WantedManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local layerName = "Activity_Wanted"
    local themeName = self:getThemeName()
    if themeName and themeName ~= "" then
        layerName = themeName
    end
    local wantedUI
    if gLobalViewManager:getViewByExtendData(layerName) == nil then
        if self.m_useNewPath[themeName] then
            wantedUI = util_createFindView(themeName .. "/" .. themeName)
        else
            wantedUI = util_createFindView("Activity/" .. layerName)
        end
        if wantedUI ~= nil then
            gLobalViewManager:showUI(wantedUI, ViewZorder.ZORDER_UI)
        end
    end
    return wantedUI
end

-- function WantedManager:showCompleteLayer()
--     if not self:isCanShowLayer() then
--         return
--     end

--     local layerName = "Activity_WantedCompleteLayer"
--     local themeName = self:getThemeName()
--     if themeName == "Activity_Wanted_Bomb" then
--         return false
--     end
--     if themeName and themeName ~= "" then
--         layerName = themeName .. "CompleteLayer"
--     end

--     if gLobalViewManager:getViewByExtendData(layerName) == nil then
--         local wantedUI = util_createView("Activity." .. layerName)
--         if wantedUI ~= nil then
--             gLobalViewManager:showUI(wantedUI, ViewZorder.ZORDER_UI)
--             return true
--         end
--     end
-- end

function WantedManager:isTaskComplete()
    local act_data = self:getRunningData()
    if not act_data then
        return false
    end
    return act_data:isTaskComplete()
end

function WantedManager:getSavedKey()
    local act_data = self:getRunningData()
    if not act_data then
        return "Activity_WantedPoped"
    end

    local themeName = act_data:getThemeName()
    return "Activity_WantedPoped" .. themeName
end

-- function WantedManager:getHallPath(hallName)
--     return "Icons/" .. hallName .. "HallNode"
-- end

-- function WantedManager:getSlidePath(slideName)
--     return "Icons/" .. slideName .. "SlideNode"
-- end

-- function WantedManager:getPopPath(popName)
--     return "Activity/" .. popName
-- end

-- 自动弹出 主弹板去领奖
function WantedManager:checkCanAutoPopMaiLayer()
    if not self:isCanShowLayer() then
        return false
    end
    self:registEvents()
    local isTaskComplete = self:isTaskComplete()
    -- if isTaskComplete then
    --     local data = self:getRunningData()
    --     local isReceive = data:isReceive()
    --     if isReceive then --领完了
    --         return false
    --     end
    -- end
    return isTaskComplete
end

function WantedManager:sendReward(_data)
    local data = _data
    local successFun = function(res)
        gLobalViewManager:removeLoadingAnima()
        self:showRewardLayer(data.theme,data.isPro)
    end

    local faildFun = function(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end

    self.m_wantedNet:sendReward(data,successFun, faildFun)
end

-- _theme 主题, _isPro 是否检测掉卡
function WantedManager:showRewardLayer(_theme, _isPro)
    if not self:isCanShowLayer() then
        return
    end
    local data = self:getRunningData()
    local itemDataList = {}
    local coins = data:getCoinsV2()
    local items = data:getItems()

    -- local shopItem = items[#items]
    -- local itemData = gLobalItemManager:createLocalItemData(shopItem.p_icon, shopItem.p_num, shopItem)
    if coins and toLongNumber(coins) > toLongNumber(0) then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        itemData:setTempData({p_limit = 3})
        itemDataList[#itemDataList + 1] = itemData
    end

    if items and #items > 0 then
        local shopItem = items[#items]
        local itemData = gLobalItemManager:createLocalItemData(shopItem.p_icon, shopItem.p_num, shopItem)
        itemDataList[#itemDataList + 1] = itemData
    end

    if #itemDataList <= 0 then
        return
    end

    local clickFunc = function()
        if _isPro then
            if CardSysManager:needDropCards("Wanted") == true then
                CardSysManager:doDropCards(
                    "Wanted",
                    function()
                        local data = self:getData()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = data:getID(), name = data:getRefName()})
                        -- data:setCompleted(true)
                    end
                )
            else
                -- 没掉卡
                local data = self:getData()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = data:getID(), name = data:getRefName()})
                -- data:setCompleted(true)
            end
        else
            local data = self:getData()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = data:getID(), name = data:getRefName()})
            -- data:setCompleted(true)
        end
    end

    local view = gLobalItemManager:createRewardLayer(itemDataList, clickFunc, toLongNumber(coins), true, _theme)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

-- function WantedManager:isCanShowHall()
--     local isCan = WantedManager.super.isCanShowHall(self)
--     if isCan then
--         local data = self:getRunningData()
--         if data then
--             local isReceive = data:isReceive()
--             return (not isReceive)
--         end
--     end
--     return isCan
-- end

-- function WantedManager:isCanShowSlide()
--     local isCan = WantedManager.super.isCanShowSlide(self)
--     if isCan then
--         local data = self:getRunningData()
--         if data then
--             local isReceive = data:isReceive()
--             return (not isReceive)
--         end
--     end
--     return isCan
-- end

function WantedManager:isCanShowPop(...)
    local isCan = WantedManager.super.isCanShowPop(self,...)
    if not isCan then
        return false
    end

    if not self:isRunning() then
        return false
    end

    return true
    -- if isCan then
    --     local data = self:getRunningData()
    --     if data then
    --         local isReceive = data:isReceive()
    --         return (not isReceive)
    --     end
    -- end
    -- return isCan
end

return WantedManager
