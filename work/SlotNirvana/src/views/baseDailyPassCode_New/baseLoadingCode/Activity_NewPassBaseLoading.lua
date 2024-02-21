--[[
    newpass 
    author:csc
    @tips ：csc 优化结构 继承 BaseLayer 
]]
local Activity_NewPassBaseLoading = class("Activity_NewPassBaseLoading", BaseLayer)

function Activity_NewPassBaseLoading:ctor()
    Activity_NewPassBaseLoading.super.ctor(self)

    self:setLandscapeCsbName(self:getCsbName())
end

--子类必须重新此方法
function Activity_NewPassBaseLoading:getCsbName()
end

function Activity_NewPassBaseLoading:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    -- self.m_labDiscount = self:findChild("lb_number")
    self:startButtonAnimation("btn_start", "breathe")
end

function Activity_NewPassBaseLoading:onKeyBack()
    if DEBUG == 2 then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
    end
end

function Activity_NewPassBaseLoading:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_NewPassBaseLoading:onEnter()
    Activity_NewPassBaseLoading.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then
                local callback = function()
                    -- 下一个弹板
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
                self:closeUI(callback)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_NewPassBaseLoading:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        local callback = function()
            gLobalDailyTaskManager:createDailyMissionPassMainLayer()
            -- 结束弹板
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
        self:closeUI(callback)
    elseif senderName == "btn_close" then
        local callback = function()
            -- 下一个弹板
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        self:closeUI(callback)
    end
end

return Activity_NewPassBaseLoading
