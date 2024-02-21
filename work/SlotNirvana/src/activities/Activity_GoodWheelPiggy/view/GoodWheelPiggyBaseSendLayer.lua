--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:40:10
    describe:小猪转盘-弹板基类
]]
local GoodWheelPiggyBaseSendLayer = class("GoodWheelPiggyBaseSendLayer", BaseLayer)

function GoodWheelPiggyBaseSendLayer:ctor()
    GoodWheelPiggyBaseSendLayer.super.ctor(self)

    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)

    self.m_data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    self.m_config = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getConfig()

    self:setLandscapeCsbName(self.m_config.SendLayer)
end

function GoodWheelPiggyBaseSendLayer:initUI(data)
    self.m_param = data
    GoodWheelPiggyBaseSendLayer.super.initUI(self, data)
end

function GoodWheelPiggyBaseSendLayer:initCsbNodes()
    self.m_timeText = self:findChild("Text_1")
    self.m_lbNumber = self:findChild("lb_number")
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnStart = self:findChild("btn_start")
    self.m_nodePig = self:findChild("Node_pig")
    self.m_spTitle = self:findChild("sp_title2")
end

function GoodWheelPiggyBaseSendLayer:initView()
    local leftTimes = self.m_data:getLeftTimes()
    self.m_lbNumber:setString("" .. leftTimes)
    self:updateTime()
    self.m_touch = true
    self:initSpine()
end

function GoodWheelPiggyBaseSendLayer:initSpine()
    --spine
    if self.m_spTitle then
        self.m_spineTitle = util_spineCreate(self.m_config.SpineTitle, true, true, 1)
        self.m_spTitle:addChild(self.m_spineTitle)
        util_spinePlay(self.m_spineTitle, "animation", true)
    end
end

-- 倒计时
function GoodWheelPiggyBaseSendLayer:updateTime()
    local updateTimeLable = function()
        local gameData = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
        if gameData == nil or not gameData:isRunning() then
            self.m_timeText:stopAllActions()
        else
            local strLeftTime, isOver = util_daysdemaining(gameData:getExpireAt(), true)
            if isOver then
                self.m_timeText:stopAllActions()
            else
                self.m_timeText:setString(strLeftTime)
            end
        end
    end
    util_schedule(self.m_timeText, updateTimeLable, 1)
    updateTimeLable()
end

function GoodWheelPiggyBaseSendLayer:onKeyBack()
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT) -- 下一个弹板
    end
    self:closeUI(callback)
end

function GoodWheelPiggyBaseSendLayer:clickFunc(sender)
    if self.m_touch then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        local callback = function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT) -- 下一个弹板
        end
        self:closeUI(callback)
    elseif name == "btn_start" then
        local callback = function()
            G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):showMainLayer()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH) -- 弹板结束
        end
        self:closeUI(callback)
    end
end

function GoodWheelPiggyBaseSendLayer:onEnter()
    GoodWheelPiggyBaseSendLayer.super.onEnter(self)
    self:registerListener()
end

function GoodWheelPiggyBaseSendLayer:onShowedCallFunc()
    self:runCsbAction("start", true)
    --spine
    self.m_spinePig = util_spineCreate(self.m_config.SpinePig, true, true, 1)
    self.m_nodePig:addChild(self.m_spinePig)
    util_spinePlay(self.m_spinePig, "start", false)
    util_spineEndCallFunc(
        self.m_spinePig,
        "start",
        function()
            self.m_touch = false
            util_spinePlay(self.m_spinePig, "idle", true)
        end
    )
end

-- 注册消息事件
function GoodWheelPiggyBaseSendLayer:registerListener()
    GoodWheelPiggyBaseSendLayer.super.registerListener(self)

    -- 活动结束事件
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.GoodWheelPiggy then
                local callback = function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT) -- 下一个弹板
                end
                self:closeUI(callback)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return GoodWheelPiggyBaseSendLayer
