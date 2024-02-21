local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_FriendsNode = class("LobbyBottom_FriendsNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_FriendsNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/Activity_FriendsLobbyNode.csb")

    self:initView()

    self.m_sprRed = self:findChild("spRedPoint")
    self.m_labelRedNum = self:findChild("labelActivityNums")
    if G_GetMgr(G_REF.Friend) and G_GetMgr(G_REF.Friend).getLobbyBottomNum then
        self:refresRedTips(G_GetMgr(G_REF.Friend):getLobbyBottomNum())
    else
        self:refresRedTips(0)
    end
end

function LobbyBottom_FriendsNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
end

function LobbyBottom_FriendsNode:refresRedTips(Count)
    if not self.m_sprRed or not self.m_labelRedNum then
        return
    end
    --根据好友消息刷新红点
    if Count > 0 then
        self.m_sprRed:setVisible(true)
        self.m_labelRedNum:setString(Count)
    else
        self.m_sprRed:setVisible(false)
    end
end

function LobbyBottom_FriendsNode:getBottomName()
    return "FRIEND"
end

-- 节点特殊处理逻辑 --
function LobbyBottom_FriendsNode:clickLobbyNode()
    --进入好友系统
    -- if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
    --     gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    --     self:showTips(self.m_tipsNode_downloading)
    --     return
    -- end
    G_GetMgr(G_REF.Friend):showMainLayer()
    self:openLayerSuccess()
end

-- function LobbyBottom_FriendsNode:getDownLoadKey()
--     return "Activity_Friends"
-- end

function LobbyBottom_FriendsNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

-- onEnter
function LobbyBottom_FriendsNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(Target, Count)
            self:refresRedTips(Count)
        end,
        ViewEventType.NOTIFY_FRIEND_TIP
    )
end

function LobbyBottom_FriendsNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

return LobbyBottom_FriendsNode
