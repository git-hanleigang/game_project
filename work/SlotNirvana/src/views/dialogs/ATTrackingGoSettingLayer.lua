--[[
    @desc: ATT tan一级弹板
    time:2021-03-16 17:38:42
    陈思超
]]
local ATTrackingGoSettingLayer = class("ATTrackingGoSettingLayer", BaseLayer)

function ATTrackingGoSettingLayer:ctor()
    ATTrackingGoSettingLayer.super.ctor(self)

    self:setLandscapeCsbName("Dialog/ATTrackingGoSettingLayer.csb")
    self:setPortraitCsbName("Dialog/ATTrackingGoSettingLayer_Portral.csb")

    self:setPauseSlotsEnabled(true)
end

function ATTrackingGoSettingLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local senderName = sender:getName()
    if senderName == "btn_next" then
        local callback = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            -- 记录当前ATT 弹板已经不用再弹出了
            gLobalDataManager:setBoolByField("checkATTrackingOver", true)
        end
        -- 关闭弹板,同时调用底层跳转到设置界面
        self:closeUI(callback)
    elseif senderName == "btn_later" then
        self:closeUI(
            function()
                -- 回调machineControl
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                -- 记录当前ATT 弹板已经不用再弹出了
                gLobalDataManager:setBoolByField("checkATTrackingOver", true)
            end
        )
    end
end

return ATTrackingGoSettingLayer
