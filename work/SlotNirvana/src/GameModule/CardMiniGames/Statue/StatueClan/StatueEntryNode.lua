--[[
    BattlePass奖励道具
    author:{author}
    time:2020-09-23 15:23:14
]]
local StatueEntryNode = class("StatueEntryNode", BaseView)

function StatueEntryNode:getCsbName()
    return "CardRes/season202102/Statue/StatueEntryNode.csb"
end

function StatueEntryNode:initCsbNodes()
    self.m_touch = self:findChild("dianji")
    self:addClick(self.m_touch)
end

function StatueEntryNode:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "dianji" then
        if self.m_click then
            return 
        end
        self.m_click = true
        performWithDelay(self, function()
            self.m_click = false
        end, 1)
        CardSysManager:getStatueMgr():pubShowStatueClanUI("StatueEntryNode")
    end
end

function StatueEntryNode:onEnter()
    gLobalNoticManager:addObserver(
        self, 
        function(target, params)
            if not CardSysManager:getStatueMgr():checkEntryNode() then
                gLobalActivityManager:removeActivityEntryNode("CardStatueGame")
            end
        end,
        ViewEventType.STATUS_PICK_COLLECT_REWARD_COMPLETED
    )
    
    self:runCsbAction("idle", true, nil, 60)
end

function StatueEntryNode:onExit()
    StatueEntryNode.super.onExit(self)
end

-- 返回entry 大小
function StatueEntryNode:getPanelSize( )
    -- 暂时这么写 后期修改成csb panel 直接读取
    local size = self:findChild("Node_PanelSize"):getContentSize()
    local size_launch = self:findChild("Node_PanelSize_launch"):getContentSize()
    return {widht = size.width,height = size.height,launchHeight = size_launch.height}
end

-- 监测 有小红点或者活动进度满了
function StatueEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    local bProgMax = false
    return {bHadRed, bProgMax}
end

return StatueEntryNode
