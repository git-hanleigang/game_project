--[[
    调差问卷通用弹版
]]
local SurveyInGameMgr = class("SurveyInGameMgr", BaseGameControl)

function SurveyInGameMgr:ctor()
    SurveyInGameMgr.super.ctor(self)
    self:setRefName(G_REF.SurveyInGame)
end

-- 打开问卷界面
function SurveyInGameMgr:showMainLayer(_url)
    local bFlag = true
    if device.platform == "ios" and not util_isSupportVersion("1.7.4") then
        bFlag = false
    elseif device.platform == "android" and not util_isSupportVersion("1.6.6") then
        bFlag = false
    end
    if bFlag then
        self:openSurveyinLayer(_url)
    else
        self:updateVersionLayer()
    end
end

function SurveyInGameMgr:openSurveyinLayer(_url)
    if not self:isDownloadRes() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("SurveyMainLayer") == nil then
        view = util_createView("Activity.SurveyMainLayer", _url)
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

function SurveyInGameMgr:updateVersionLayer()
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

return SurveyInGameMgr
