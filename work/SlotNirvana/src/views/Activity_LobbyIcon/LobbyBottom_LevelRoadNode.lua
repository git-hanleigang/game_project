local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_LevelRoadNode = class("LobbyBottom_LevelRoadNode", BaseLobbyNodeUI)

function LobbyBottom_LevelRoadNode:initUI(data)
    LobbyBottom_LevelRoadNode.super.initUI(self, data)
end

function LobbyBottom_LevelRoadNode:getCsbName()
    return "Activity_LobbyIconRes/LobbyBottomLevelRoad.csb"
end

function LobbyBottom_LevelRoadNode:updateView()
    --解锁等级
    local unLockLevel = self:getSysOpenLv()
    if not tolua.isnull(self.m_unlockValue) then
        self.m_unlockValue:setString(unLockLevel)
    end

    local lobbyNodeNewIconKey = self:getLobbyNodeNewIconKey()
    local newCount = 0
    if lobbyNodeNewIconKey ~= nil and lobbyNodeNewIconKey ~= "" then
        newCount = gLobalDataManager:getNumberByField(lobbyNodeNewIconKey, 0)
        newCount = newCount + 1
        gLobalDataManager:setNumberByField(lobbyNodeNewIconKey, newCount)
    end
    local curLevel = globalData.userRunData.levelNum
    if curLevel < unLockLevel then
        self.m_lock:setVisible(true)
        self.m_LockState = true
        self.m_sp_new:setVisible(false)
        self:updateDownLoad(false)
    else
        self.m_lock:setVisible(false)
        self.m_LockState = false
        if lobbyNodeNewIconKey ~= nil and lobbyNodeNewIconKey ~= "" then
            self.m_sp_new:setVisible(newCount < 3)
        end
        self:updateDownLoad(true)
    end
    self:updateRedPointNum()
end

function LobbyBottom_LevelRoadNode:updateRedPointNum()
    local num = 0
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        num = data:getRedPointNum()
    end
    self.m_spRedPoint:setVisible(num > 0)
    self.m_labelActivityNums:setString(num)
end

-- 节点处理逻辑 --
function LobbyBottom_LevelRoadNode:clickFunc()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end
    if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end
    G_GetMgr(G_REF.LevelRoad):showMainLayer()
    self:openLayerSuccess()
end

function LobbyBottom_LevelRoadNode:onEnter()
    LobbyBottom_LevelRoadNode.super.onEnter(self)
    -- 请求领取奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.isSuc then
                self:updateRedPointNum()
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_REQUEST_REWARD
    )
end

function LobbyBottom_LevelRoadNode:getLobbyNodeNewIconKey()
    return "LobbyBottom_LevelRoadNode"
end

-- 获取 开启等级
function LobbyBottom_LevelRoadNode:getSysOpenLv()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        return data:getOpenLevel()
    end
    return LobbyBottom_LevelRoadNode.super.getSysOpenLv(self)
end

function LobbyBottom_LevelRoadNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_LevelRoadNode:getBottomName()
    return "LEVEL ROAD"
end

function LobbyBottom_LevelRoadNode:getDownLoadKey()
    return "LevelRoad"
end

function LobbyBottom_LevelRoadNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/LevelRoad_2.png"
end

function LobbyBottom_LevelRoadNode:getProcessBgOffset()
    return 0, 0
end


return LobbyBottom_LevelRoadNode
