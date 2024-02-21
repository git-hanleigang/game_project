--[[
    @desc: ATT tan一级弹板
    time:2021-03-16 17:38:42
    陈思超
]]
local ATTrackingLevelUpLayer = class("ATTrackingLevelUpLayer", BaseLayer)

function ATTrackingLevelUpLayer:ctor()
    ATTrackingLevelUpLayer.super.ctor(self)

    self:setLandscapeCsbName("Dialog/ATTrackingLevelUpLayer.csb")
    self:setPortraitCsbName("Dialog/ATTrackingLevelUpLayer_Portral.csb")

    self:setPauseSlotsEnabled(true)
end

function ATTrackingLevelUpLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local senderName = sender:getName()
    if senderName == "btn_ok" then
        -- 触发二级弹板 请求att弹窗
        globalPlatformManager:checkATTrackingStatus(
            function(status)
                -- status 玩家att 状态
                -- 发送firebase打点
                if status == "true" then
                    globalFireBaseManager:sendFireBaseLogDirect("AttrackingAllow", false)
                    -- 记录当前ATT 弹板已经不用再弹出了
                    gLobalDataManager:setBoolByField("checkATTrackingOver", true)

                    release_print("----csc checkATTrackingStatus true")
                else
                    globalFireBaseManager:sendFireBaseLogDirect("AttrackingReject", false)
                    if not gLobalAdsControl:isAgainRequestATTracking() then
                        -- 需要记录一下当前玩家需要 弹出setting 弹板
                        gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", true)
                    end
                    release_print("----csc checkATTrackingStatus false")
                end
                local callback = function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end
                -- 关闭一级弹板,需要去请求二级弹板
                self:closeUI(callback)
            end
        )
    end
end

return ATTrackingLevelUpLayer
