--[[
    author:JohnnyFred
    time:2020-10-09 20:58:15
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_BingoRushLobbyNode = class("Activity_BingoRushLobbyNode", BaseActLobbyNodeUI)

function Activity_BingoRushLobbyNode:initUI(data)
    Activity_BingoRushLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

-- 点击响应逻辑 活动跳转和一些点击提示
function Activity_BingoRushLobbyNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if not G_GetMgr(ACTIVITY_REF.BingoRush):isCanShowLayer() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_OPEN_VIEW)
    -- 断线重连
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    G_GetMgr(ACTIVITY_REF.BingoRush):checkReconnect()
end

function Activity_BingoRushLobbyNode:onEnter()
    Activity_BingoRushLobbyNode.super.onEnter(self)
end

-- 资源名称
function Activity_BingoRushLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_BingoRushLobbyNode.csb"
end

-- 关联下载资源的文件夹名称
-- 如果资源没下载 按钮上会显示这个文件夹的下载进度
function Activity_BingoRushLobbyNode:getDownLoadKey()
    return "Activity_BingoRush"
end

--获得下载进度图片路径
function Activity_BingoRushLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/bingRush_lobbyBtn1.png"
end

-- 用于下载显示的节点 将在这个节点上创建一个扇形进度条来显示下载进度
-- 具体下载控制逻辑参考 BaseDownLoadNodeUI:registerListener()
-- 下载模块在下载过程中不断抛出消息告知某模块的下载进度 BaseDownLoadNodeUI 会检查下载模块跟自身downLoadKey一致就回刷新自己的进度条
function Activity_BingoRushLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

-- 显示的活动名称
function Activity_BingoRushLobbyNode:getBottomName()
    return "BINGO RUSH"
end

-- 刷新活动倒计时
function Activity_BingoRushLobbyNode:updateLeftTime()
    Activity_BingoRushLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    self:showCounts()
end

-- 显示红点
function Activity_BingoRushLobbyNode:showCounts()
    if not self.m_spRedPoint or not self.m_labelActivityNums then
        return
    end
    local gameData = self:getGameData()
    if not gameData then
        -- 隐藏
        self.m_spRedPoint:setVisible(false)
        return
    end

    local passData = G_GetMgr(ACTIVITY_REF.BingoRush):getPassData()
    if not passData then
        self.m_spRedPoint:setVisible(false)
        return
    end
    local counts = passData:getCollectCounts()
    if counts <= 0 then
        self.m_spRedPoint:setVisible(false)
        return
    end
    self.m_spRedPoint:setVisible(true)
    self.m_labelActivityNums:setString(counts)
    local rp_size = self.m_spRedPoint:getContentSize()
    util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
end

-- 关联的活动数据
function Activity_BingoRushLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
end

-- 获取活动引用名
function Activity_BingoRushLobbyNode:getActRefName()
    return ACTIVITY_REF.BingoRush
end

-- 获取默认的解锁文本
function Activity_BingoRushLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK BINGO RUSH AT LEVEL " .. self:getSysOpenLv()
end

return Activity_BingoRushLobbyNode
