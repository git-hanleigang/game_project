
-- wildChallenge 关卡入口

local WildChallengeActLevelLogo = class("WildChallengeActLevelLogo", util_require("base.BaseView"))

function WildChallengeActLevelLogo:initUI()
    WildChallengeActLevelLogo.super.initUI(self)

    self:updateView()
    self:runCsbAction("idle", true)
end

function WildChallengeActLevelLogo:initCsbNodes()
    self.m_loadingBar = self:findChild("LoadingBar_1")
    self.m_lb_percent = self:findChild("lb_percent")
    self.m_sp_red = self:findChild("sp_red")
end

function WildChallengeActLevelLogo:updateView()
    local gameData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()
    if gameData then
        local phase = gameData:getPhaseListData()
        local hasReward = false
        local percent = 100
        for i,v in ipairs(phase) do
            local status = v:getStatus()
            if status == 2 then 
                hasReward = true
            elseif status == 1 then
                local progLimit = v:getProgressLimit()
                local progCur = v:getProgressCur()
                percent = math.floor(math.min(progCur, progLimit) / progLimit * 100)
                break
            end
        end
        self.m_loadingBar:setPercent(percent)
        self.m_lb_percent:setString(percent .. "%")
        self.m_sp_red:setVisible(hasReward)
    else
        self.m_loadingBar:setPercent(0)
        self.m_lb_percent:setString("0%")
        self.m_sp_red:setVisible(false)
    end
end

-- 返回entry 大小
function WildChallengeActLevelLogo:getPanelSize()
    -- 暂时这么写 后期修改成csb panel 直接读取
    local size = self:findChild("Node_PanelSize"):getContentSize()
    local size_launch = self:findChild("Node_PanelSize_launch"):getContentSize()
    return {widht = size.width, height = size.height, launchHeight = size_launch.height}
end


--点击回调
function WildChallengeActLevelLogo:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_go" then
        G_GetMgr(ACTIVITY_REF.WildChallenge):showMainLayer()
    end
end

function WildChallengeActLevelLogo:onEnter()
    WildChallengeActLevelLogo.super.onEnter(self)

    -- 数据刷新
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateView()
        end,
    ViewEventType.NOTIFY_WILD_CHALLENGE_DATA_UPDATE)


    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.name == ACTIVITY_REF.WildChallenge then
                gLobalActivityManager:removeActivityEntryNode(ACTIVITY_REF.WildChallenge)
            end
        end,
    ViewEventType.NOTIFY_ACTIVITY_COMPLETED)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.name == ACTIVITY_REF.WildChallenge then
                gLobalActivityManager:removeActivityEntryNode(ACTIVITY_REF.WildChallenge)
            end
        end,
    ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

-- 监测 有小红点或者活动进度满了
function WildChallengeActLevelLogo:checkHadRedOrProgMax()
    local bHadRed = false
    if self.m_sp_red then
        bHadRed = self.m_sp_red:isVisible() 
    end
    local bProgMax = false
    if self.m_loadingBar then
        bProgMax = self.m_loadingBar:getPercent() >= 100
    end
    return {bHadRed, bProgMax}
end

return WildChallengeActLevelLogo