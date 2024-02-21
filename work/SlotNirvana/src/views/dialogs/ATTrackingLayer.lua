--[[
    @desc: ATT tan一级弹板
    time:2021-03-16 17:38:42
    陈思超
]]
local ATTrackingLayer = class("ATTrackingLayer", BaseLayer)

function ATTrackingLayer:ctor()
    ATTrackingLayer.super.ctor(self)
end

function ATTrackingLayer:initUI(_pos)
    if _pos == "loading" then
        self:setLandscapeCsbName("Dialog/ATTrackingLoadingLayer.csb")
    elseif _pos == "bigwin" then
        self:setLandscapeCsbName("Dialog/ATTrackingBigWinLayer.csb")
    end
    ATTrackingLayer.super.initUI(self)
end

function ATTrackingLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local senderName = sender:getName()
    if senderName == "btn_ok" then
        local callback = function()
            -- 触发二级弹板 请求att弹窗
            -- 无论Att 玩家选择了什么 都进大厅
            globalPlatformManager:checkATTrackingStatus(
                function()
                    -- 回调loading界面进入大厅
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ATTRACKING_CALLBACK)
                end
            )
            -- 记录当前ATT 弹板已经不用再弹出了
            gLobalDataManager:setBoolByField("checkATTrackingOver", true)
        end
        -- 关闭一级弹板,需要去请求二级弹板
        self:closeUI(callback)
    elseif senderName == "btn_cancel" then
        local callback = function()
            -- 回调loading界面进入大厅
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ATTRACKING_CALLBACK)
        end
        -- 单纯的关闭一级弹板
        self:closeUI(callback)
    end
end

-- function ATTrackingLayer:onEnter( )
--     ATTrackingLayer.super.onEnter(self)
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
-- end

-- function ATTrackingLayer:onExit( )
--     ATTrackingLayer.super.onExit(self)
--     if gLobalViewManager:isPauseAndResumeMachine(self) then
--         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
--     end
-- end
return ATTrackingLayer
