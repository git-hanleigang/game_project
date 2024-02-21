--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:39:50
    describe:小猪转盘-主界面基类
]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local GoodWheelPiggyBaseMainLayer = class("GoodWheelPiggyBaseMainLayer", BaseLayer)

function GoodWheelPiggyBaseMainLayer:ctor()
    GoodWheelPiggyBaseMainLayer.super.ctor(self)

    self.m_data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    self.m_config = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getConfig()

    self:setLandscapeCsbName(self.m_config.MainLayer)
end

function GoodWheelPiggyBaseMainLayer:initUI(callback)
    self.m_callback = callback
    GoodWheelPiggyBaseMainLayer.super.initUI(self, callback)
end

function GoodWheelPiggyBaseMainLayer:initCsbNodes()
    self.m_nodeMid = self:findChild("Node_mid")
    self.m_nodeWheel = self:findChild("Node_Wheel")
    self.m_spTitle = self:findChild("sp_title2")
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnGo = self:findChild("btn_go")
end

function GoodWheelPiggyBaseMainLayer:initView()
    if self.m_data then
        -- 在这里加载道具
        local view = self:createWheel()
        self.m_nodeWheel:addChild(view)
        self.m_nodeWheel:setVisible(true)

        local isVis = self.m_data:checkIsReconnectPop()
        self.m_btnGo:setVisible((not isVis))
    end

    self:initSpine()
end

function GoodWheelPiggyBaseMainLayer:initSpine()
    --spine
    if self.m_spTitle then
        self.m_spineTitle = util_spineCreate(self.m_config.SpineTitle, true, true, 1)
        self.m_spTitle:addChild(self.m_spineTitle)
        util_spinePlay(self.m_spineTitle, "animation", true)
    end
end

function GoodWheelPiggyBaseMainLayer:createWheel()
    local view = util_createView("activities.Activity_GoodWheelPiggy.view.GoodWheelPiggyWheel")
    return view
end

function GoodWheelPiggyBaseMainLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        if self.m_btnGo:isVisible() then
            self:closeUI()
        end
    end
    if name == "btn_go" then
        local callback = function()
            G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):showPiggyBank()
        end
        self:closeUI(callback)
    end
end

-- 显示动画回调
function GoodWheelPiggyBaseMainLayer:onShowedCallFunc()
    self:runCsbAction("start", true)
end

function GoodWheelPiggyBaseMainLayer:onEnter()
    GoodWheelPiggyBaseMainLayer.super.onEnter(self)
end

-- 注册消息事件
function GoodWheelPiggyBaseMainLayer:registerListener()
    GoodWheelPiggyBaseMainLayer.super.registerListener(self)

    -- 活动结束事件
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.GoodWheelPiggy then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self and not tolua.isnull(self) then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_GOODWHEELPIGGY_SPIN_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self and not tolua.isnull(self) then
                self.m_btnClose:setVisible(false)
            end
        end,
        ViewEventType.NOTIFY_GOODWHEELPIGGY_REQUEST_SPIN_SUCESS
    )
end

function GoodWheelPiggyBaseMainLayer:closeUI(callback)
    if self.m_callback then
        GoodWheelPiggyBaseMainLayer.super.closeUI(self, self.m_callback)
    else
        GoodWheelPiggyBaseMainLayer.super.closeUI(self, callback)
    end
end

function GoodWheelPiggyBaseMainLayer:getLanguageTableKeyPrefix()
    return "GoodWheelPiggyBaseMainLayer"
end

return GoodWheelPiggyBaseMainLayer
