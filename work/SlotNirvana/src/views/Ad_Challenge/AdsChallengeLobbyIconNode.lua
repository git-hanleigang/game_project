


local BaseView = require("base.BaseView")
local AdsChallengeLobbyIconNode = class("AdsChallengeLobbyIconNode",BaseView)

function AdsChallengeLobbyIconNode:getCsbName()
    return "Ad_Challenge/csb/Ad_Challenge_lobbyIcon.csb"
end

function AdsChallengeLobbyIconNode:initCsbNodes()
    self.m_watchProgress = self:findChild("progress")
    self.m_txt_progress = self:findChild("txt_progress")
    self:addClick(self:findChild("btn_go"))
end

function AdsChallengeLobbyIconNode:initUI()
    AdsChallengeLobbyIconNode.super.initUI(self)
    self:RefreshNode()
    self:runCsbAction("idle", true, nil, 60)
end

function AdsChallengeLobbyIconNode:onEnter()
    AdsChallengeLobbyIconNode.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function()
            self:RefreshNode()
        end,
        ViewEventType.NOTIFY_ADS_REWARDS_END
    )
end

-- 刷新数据
function AdsChallengeLobbyIconNode:RefreshNode()
    local currentWatchCount =  globalData.AdChallengeData.m_currentWatchCount
    local maxWatchCount =  globalData.AdChallengeData.m_maxWatchCount
    if currentWatchCount > maxWatchCount then
        currentWatchCount = maxWatchCount
    end
    local rate = currentWatchCount / maxWatchCount * 100
    self.m_watchProgress:setPercent(rate)
    self.m_txt_progress:setString(currentWatchCount.."/"..maxWatchCount)
end

function AdsChallengeLobbyIconNode:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_go" then
        gLobalAdChallengeManager:showMainLayer()
    end
end

-- 返回右边栏 entry 大小
function AdsChallengeLobbyIconNode:getRightFrameSize()
    self.m_Node_PanelSize = self:findChild("Node_PanelSize")

    local size = {widht = 110, height = 90}

    if self.m_Node_PanelSize ~= nil then
        local contentSize = self.m_Node_PanelSize:getContentSize()
        size.height = contentSize.height
    end
    
    return size
end

return AdsChallengeLobbyIconNode
