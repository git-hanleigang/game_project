--[[
]]
local CSEntryNode = class("CSEntryNode", BaseView)

function CSEntryNode:getCsbName()
    return CardSeekerCfg.csbPath .."SeekerEntryNode.csb"
end

function CSEntryNode:initCsbNodes()
    self.m_touch = self:findChild("dianji")
    self.m_sp_lock = self:findChild("sp_lock")
    self:addClick(self.m_touch)
end

function CSEntryNode:initUI()
    CSEntryNode.super.initUI(self)
    if self.m_sp_lock then
        self.m_sp_lock:setVisible(false)
        self:initCloseTimer()
    end
end

function CSEntryNode:initCloseTimer()

    local expireAt = CardSysManager:getSeasonExpireAt()

    if not expireAt then
        return
    end
    self:stopCloseTimer()

    self.m_closeTimer = util_schedule(self, function()

        if not tolua.isnull(self) then
            local leftTime = util_getLeftTime(expireAt * 1000)    
            if leftTime <= 0 then
                self.m_click = true
                self.m_sp_lock:setVisible(true)
                self:stopCloseTimer()
            end
        end

    end, 1)
end

function CSEntryNode:stopCloseTimer()
   if self.m_closeTimer ~= nil then
        self:stopAction(self.m_closeTimer)
        self.m_closeTimer = nil
    end
end

function CSEntryNode:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "dianji" then
        if self.m_click then
            return
        end
        self.m_click = true
        performWithDelay(
            self,
            function()
                self.m_click = false
            end,
            1
        )
        G_GetMgr(G_REF.CardSeeker):enterGame("CSEntryNode")
    end
end

function CSEntryNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.isSuc and not G_GetMgr(G_REF.CardSeeker):checkEntryNode() then
                gLobalActivityManager:removeActivityEntryNode("CardSeekerGame")
            end
        end,
        ViewEventType.CARD_SEEKER_REQUEST_COLLECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.isSuc and not G_GetMgr(G_REF.CardSeeker):checkEntryNode() then
                gLobalActivityManager:removeActivityEntryNode("CardSeekerGame")
            end
        end,
        ViewEventType.CARD_SEEKER_REQUEST_GIVEUP
    )

    self:runCsbAction("idle", true, nil, 60)
end

function CSEntryNode:onExit()
    self:stopCloseTimer()
    CSEntryNode.super.onExit(self)
end

-- 返回entry 大小
function CSEntryNode:getPanelSize()
    -- 暂时这么写 后期修改成csb panel 直接读取
    local size = self:findChild("Node_PanelSize"):getContentSize()
    local size_launch = self:findChild("Node_PanelSize_launch"):getContentSize()
    return {widht = size.width, height = size.height, launchHeight = size_launch.height}
end

-- 监测 有小红点或者活动进度满了
function CSEntryNode:checkHadRedOrProgMax()
    local bHadRed = true -- 入口显示就有 小红点1
    local bProgMax = false
    return {bHadRed, bProgMax}
end

return CSEntryNode
