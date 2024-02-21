local baseView = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_VIPNode = class("LobbyBottom_VIPNode", baseView)

function LobbyBottom_VIPNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomVipNode.csb")
    self:initView()
    self:updateView()
    self:initBoost()
    self:checkLeftTimer()
end

function LobbyBottom_VIPNode:initView()
    self.btnFunc = self:findChild("Button_1")
    self.m_sp_boost = self:findChild("sp_boosted")
    self.m_lockIocn = self:findChild("lockIcon")
    self.m_sp_experience = self:findChild("sp_experience")
    if self.btnFunc then
        self.btnFunc:setSwallowTouches(false)
    end
end

function LobbyBottom_VIPNode:updateView()
    self.m_lockIocn:setVisible(false)
    self.m_sp_boost:setVisible(false)
    self.m_sp_experience:setVisible(false)
end

function LobbyBottom_VIPNode:initBoost()
    local bpData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if bpData and bpData:isRunning() then
        self.m_sp_boost:setVisible(not bpData:isExperienceItemType())
        self.m_sp_experience:setVisible(bpData:isExperienceItemType())
    else
        self.m_lockIocn:setVisible(false)
        self.m_sp_boost:setVisible(false)
    end
end
--剩下时间
function LobbyBottom_VIPNode:checkLeftTimer()
    self:stopLeftTimerAction()
    local function updateTime()
        local bpData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if not bpData or not bpData:isRunning() then
            self.m_sp_boost:setVisible(false)
        end
    end
    updateTime()
    self.m_leftTimeAction = util_schedule(self, updateTime, 1)
end

function LobbyBottom_VIPNode:stopLeftTimerAction()
    if self.m_leftTimeAction ~= nil then
        self:stopAction(self.m_leftTimeAction)
        self.m_leftTimeAction = nil
    end
end
-- 节点处理逻辑 --
function LobbyBottom_VIPNode:clickFunc()
    G_GetMgr(G_REF.Vip):showMainLayer()
    self:openLayerSuccess()
end

function LobbyBottom_VIPNode:onEnter()
    LobbyBottom_VIPNode.super.onEnter(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.VipBoost then
                self:initBoost()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initBoost()
        end,
        ViewEventType.NOTIFY_VIP_BOOST_UPDATE_DATA
    )
end

return LobbyBottom_VIPNode
