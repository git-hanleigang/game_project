--[[
    4周年抽奖+分奖
]]

local dayDraw4BRewardData = require("activities.Activity_4BdayDraw.model.dayDraw4BRewardData")
local dayDraw4BNet = require("activities.Activity_4BdayDraw.net.dayDraw4BNet")
local dayDraw4BMgr = class("dayDraw4BMgr", BaseActivityControl)

function dayDraw4BMgr:ctor()
    dayDraw4BMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.dayDraw4B)

    self.m_netModel = dayDraw4BNet:getInstance()   -- 网络模块
    self.m_rewardData = dayDraw4BRewardData:create()
end

function dayDraw4BMgr:showMainLayer()
    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function dayDraw4BMgr:showWheelLayer(_params)
    if not self:isCanShowLayer() then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_4BdayDrawWheel") == nil then
        view = util_createView("Activity_4BdayDraw.Activity.Activity_4BdayDrawWheel", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function dayDraw4BMgr:shwoRewardLayer()
    if not self:isDownloadTheme("Activity_4BdayDrawCollect") then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_4BdayDrawCollect") == nil then
        view = util_createView("Activity_4BdayDrawCollect.Activity.Activity_4BdayDrawCollect")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function dayDraw4BMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function dayDraw4BMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function dayDraw4BMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function dayDraw4BMgr:saveCollect()
    self.m_netModel:saveCollect()
end

function dayDraw4BMgr:parseWheelData(_data)
    local gameData = self:getRunningData()
    if gameData then
        local drawIndex = _data.drawIndex
        local wheelList = _data.wheelList or {}
        if drawIndex and #wheelList > 0 then
            gameData:setWheelIndex(drawIndex)
            gameData:parseWheelData(wheelList)
        end
    end
end

function dayDraw4BMgr:checkWheelData()
    local flag = false
    local gameData = self:getRunningData()
    if gameData then
        local drawIndex = gameData:getWheelIndex()
        local wheelList = gameData:getWheelData()
        if drawIndex and #wheelList > 0 then
            flag = true
        end
    end
    return flag
end

function dayDraw4BMgr:parseRewardData(_data)
    self.m_rewardData:parseData(_data)
end

function dayDraw4BMgr:clearRewardData()
    self.m_rewardData:clearData()
end

function dayDraw4BMgr:getRewardData()
    return self.m_rewardData
end

return dayDraw4BMgr
