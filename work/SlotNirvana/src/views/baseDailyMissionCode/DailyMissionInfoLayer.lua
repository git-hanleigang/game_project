--[[
    --新版每日任务pass主界面 info界面
    csc 2021-06-21
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionInfoLayer = class("DailyMissionInfoLayer", BaseLayer)

function DailyMissionInfoLayer:ctor()
    DailyMissionInfoLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Info/Pass_InfoLayer.csb")
    self:setPortraitCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Info/Pass_InfoLayer_Vertical.csb")
end

function DailyMissionInfoLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end
return DailyMissionInfoLayer
