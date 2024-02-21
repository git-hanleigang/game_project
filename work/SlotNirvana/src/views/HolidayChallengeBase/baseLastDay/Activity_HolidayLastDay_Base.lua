--[[
    @desc: 独立日宣传弹板-额外奖励星星
    time:2021-06-04
]]
local Activity_HolidayLastDay_Base = class("Activity_HolidayLastDay_Base", BaseLayer)

function Activity_HolidayLastDay_Base:ctor()
    Activity_HolidayLastDay_Base.super.ctor(self)

    self:setLandscapeCsbName(self:getSelfCsbName())
end

function Activity_HolidayLastDay_Base:getSelfCsbName()
    local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return  config.RESPATH.HOLIDAY_LASTDAY_LAYER
end

function Activity_HolidayLastDay_Base:initUI(data)
    Activity_HolidayLastDay_Base.super.initUI(self)
end

function Activity_HolidayLastDay_Base:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeSpine = self:findChild("Node_spine")
    self.m_nodeEffec = self:findChild("sp_node_guang")
end
function Activity_HolidayLastDay_Base:initView()
    self:initSpineNode()
end
function Activity_HolidayLastDay_Base:initSpineNode()
    if self.m_nodeSpine then
        local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
        if config.RESPATH["SPINE_PATH_LASTDAY"] then
            self.m_SpineAct = util_spineCreate(config.RESPATH["SPINE_PATH_LASTDAY"], true, true, 1)
            self.m_SpineAct:setScale(1)
            self.m_nodeSpine:addChild(self.m_SpineAct)
            util_spinePlay(self.m_SpineAct, "idle", true)
        end
    end
end
function Activity_HolidayLastDay_Base:onKeyBack()
    -- 手机点击返回按钮也会调用这里
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end

-- 重写父类方法 
function Activity_HolidayLastDay_Base:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_HolidayLastDay_Base:onEnter()
    Activity_HolidayLastDay_Base.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.ChallengePassLastDay then
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_HolidayLastDay_Base:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        local callback = function()
            -- 打开购买界面
            if globalDynamicDLControl:checkDownloading("Activity_HolidayChallenge_Base") then
                print("--- click, Activity_HolidayChallenge_Base isDownloading ----")
            else
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):createPayLayer()
            end
            -- 结束弹板
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
        self:closeUI(callback)
    elseif senderName == "btn_close" then
        self:closeUI(function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end)
    end
end

return Activity_HolidayLastDay_Base
