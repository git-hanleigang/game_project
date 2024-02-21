--[[
    新关挑战
]]

local SurveyinGameeNet = require("activities.Activity_SurveyinGame.net.SurveyinGameNet")
local SurveyinGameControl = class("SurveyinGameControl", BaseActivityControl)

function SurveyinGameControl:ctor()
    SurveyinGameControl.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.SurveyinGame)

    self.m_netModel = SurveyinGameeNet:getInstance()   -- 网络模块
end

--发送领取奖励信息
function SurveyinGameControl:sendCollectMessage()
    self.m_netModel:sendCollectMessage()
end

-- 打开问卷界面
function SurveyinGameControl:showSurveyinLayer(_params)
    local bFlag = false
    if device.platform == "ios" then
        bFlag = util_isSupportVersion("1.7.4")
    elseif device.platform == "android" then
        bFlag = util_isSupportVersion("1.6.6")
    end

    if bFlag then 
        self:openSurveyinLayer(_params)
    else
        self:updateVersionLayer()
    end
end

function SurveyinGameControl:openSurveyinLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    
    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_SurveyinLayer") == nil then
        view = util_createView("Activity/Activity_SurveyinLayer", _params)
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

function SurveyinGameControl:updateVersionLayer()
    gLobalViewManager:showDialog(
        "Dialog/NewVersionLayerClan.csb",
        function()
            xcyy.GameBridgeLua:rateUsForSetting()
        end,
        nil,
        nil,
        nil
    )
end

function SurveyinGameControl:showCollectLayer(_isSendMessage)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_SurveyinCollectLayer") == nil then
        view = util_createView("Activity/Activity_SurveyinCollectLayer", _isSendMessage)
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

return SurveyinGameControl
