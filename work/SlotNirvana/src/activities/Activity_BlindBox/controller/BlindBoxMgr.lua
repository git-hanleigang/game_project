--[[
    集装箱大亨
]]

local BlindBoxConfig = require("activities.Activity_BlindBox.config.BlindBoxConfig")
local BlindBoxGuideMgr = require("activities.Activity_BlindBox.controller.BlindBoxGuideMgr")
local BlindBoxNet = require("activities.Activity_BlindBox.net.BlindBoxNet")
local BlindBoxMgr = class("BlindBoxMgr", BaseActivityControl)

function BlindBoxMgr:ctor()
    BlindBoxMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.BlindBox)
    self.m_net = BlindBoxNet:getInstance()
    self.m_guide = BlindBoxGuideMgr:getInstance()
end

function BlindBoxMgr:sendActionRank(_flag)
    self.m_net:sendActionRank(_flag)
end

function BlindBoxMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxMainLayer") == nil then
        view = util_createView("Activity_BlindBox.Activity.BlindBoxMainLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

function BlindBoxMgr:showTipLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxTipLayer") == nil then
        view = util_createView("Activity_BlindBox.Activity.BlindBoxTipLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

function BlindBoxMgr:showSaleLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxSaleLayer") == nil then
        view = util_createView("Activity_BlindBox.Activity.BlindBoxSaleLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

function BlindBoxMgr:showCollectLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxCollectLayer") == nil then
        view = util_createView("Activity_BlindBox.Activity.BlindBoxCollectLayer", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

function BlindBoxMgr:showPassLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxPassLayer") == nil then
        view = util_createView("Activity_BlindBox_Pass.BlindBoxPassLayer", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

-- 显示任务主界面
function BlindBoxMgr:showMissionMainLayer(_over)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("BlindBoxMissionMainLayer") ~= nil then
        return nil
    end
    local function openMission()
        local view = util_createView("Activity_BlindBox.Activity.Mission.BlindBoxMissionMainLayer", _over)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    -- 打开界面时主动拉取活动数据，刷新任务实时数据
    if self.m_isReqMission then
        return nil
    end
    self.m_isReqMission = true
    self:sendBlindBoxGetData(
        function()
            self.m_isReqMission = false
            openMission()
        end,
        function()
            self.m_isReqMission = false
        end
    )
    return true 
end

function BlindBoxMgr:showRankLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxRankLayer") == nil then
        view = util_createView("Activity_BlindBox_Rank.BlindBoxRank.BlindBoxRankUI", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

function BlindBoxMgr:showNoRankLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("BlindBoxNoRankLayer") == nil then
        view = util_createView("Activity_BlindBox_Rank.BlindBoxRank.BlindBoxNoRankLayer", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view 
end

function BlindBoxMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function BlindBoxMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function BlindBoxMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function BlindBoxMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
   return themeName .. "/Activity/" .. entryName .. "EntryNode" 
end

function BlindBoxMgr:sendBlindBoxNext()
    self.m_net:sendBlindBoxNext()
end

function BlindBoxMgr:sendBlindBoxOpen()
    self.m_net:sendBlindBoxOpen()
end

function BlindBoxMgr:buySale(_data, _index)
    self.m_net:buySale(_data, _index)
end

function BlindBoxMgr:sendBlindBoxMissionCollect(_missionId, _success)
    self.m_net:sendBlindBoxMissionCollect(_missionId, _success)
end

function BlindBoxMgr:sendBlindBoxGetData(_succ, _fail)
    self.m_net:sendBlindBoxGetData(_succ, _fail)
end

function BlindBoxMgr:sendCollect(_point, _type, _index)
    self.m_net:sendCollect(_point, _type, _index)
end

function BlindBoxMgr:buyUnlock(_data)
    self.m_net:buyUnlock(_data)
end

function BlindBoxMgr:getGuide()
    return self.m_guide
end

function BlindBoxMgr:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    return self.m_guide:triggerGuide(view, name, ACTIVITY_REF.BlindBox)
end

return BlindBoxMgr
