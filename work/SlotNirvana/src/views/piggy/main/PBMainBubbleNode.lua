--[[--
    小猪后背气泡上显示的相关运营活动奖励展示
]]
local PBMainBubbleControl = util_require("views.piggy.main.PBMainBubbleControl")
local PBMainBubbleNode = class("PBMainBubbleNode", BaseView)

function PBMainBubbleNode:getCsbName()
    return "PigBank2022/csb/main/PBBubble.csb"
end

function PBMainBubbleNode:initDatas()
    self.m_bubbleCtr = PBMainBubbleControl:getInstance()
end

function PBMainBubbleNode:initCsbNodes()
    self.m_bubbleNode = self:findChild("node_rewards")
end

function PBMainBubbleNode:initUI()
    PBMainBubbleNode.super.initUI(self)
    self:initBubble()
end

function PBMainBubbleNode:initBubble()
    self:updateBubbles(true)
end

function PBMainBubbleNode:updateBubbles(_isInit)
    local luaPaths = self.m_bubbleCtr:getBubbleLuaPaths()
    if luaPaths and #luaPaths > 0 then
        self:showBubble(true)
        -- 移除旧的气泡
        if _isInit then
            local childs = self.m_bubbleNode:getChildren()
            if childs and #childs > 0 then
                self.m_bubbleNode:removeAllChildren()
            end
        end
        -- 创建新气泡
        local luaPath = luaPaths[1]
        local bubble = util_createView(luaPath)
        if bubble then
            self.m_bubbleNode:addChild(bubble)
        end
    else
        self:showBubble(false)
    end
end

function PBMainBubbleNode:showBubble(_isShow)
    self.m_csbNode:setVisible(_isShow)
end

function PBMainBubbleNode:onEnter()
    PBMainBubbleNode.super.onEnter(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local cfg = self.m_bubbleCtr:getCfgs()
            for i = 1, #cfg do
                local refName = cfg[i][1]
                if params.name and params.name == refName then
                    self:updateBubbles()
                    break
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return PBMainBubbleNode
