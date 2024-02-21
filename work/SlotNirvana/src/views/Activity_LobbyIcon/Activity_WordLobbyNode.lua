--[[
    author:JohnnyFred
    time:2020-10-09 20:58:15
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_WordLobbyNode = class("Activity_WordLobbyNode", BaseActLobbyNodeUI)

function Activity_WordLobbyNode:initUI(data)
    Activity_WordLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

-- 点击响应逻辑 活动跳转和一些点击提示
function Activity_WordLobbyNode:clickLobbyNode()
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

    if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    gLobalActivityManager:showActivityMainView("Activity_Word", "WordLevel", nil, nil)
    self:openLayerSuccess()
end

function Activity_WordLobbyNode:onEnter()
    Activity_WordLobbyNode.super.onEnter(self)
end

-- 资源名称
function Activity_WordLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_WordLobbyNode.csb"
end

-- 关联下载资源的文件夹名称
-- 如果资源没下载 按钮上会显示这个文件夹的下载进度
function Activity_WordLobbyNode:getDownLoadKey()
    return "Activity_Word"
end

--获得下载进度图片路径
function Activity_WordLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/Word_LobbyIcon1.png"
end

-- 用于下载显示的节点 将在这个节点上创建一个扇形进度条来显示下载进度
-- 具体下载控制逻辑参考 BaseDownLoadNodeUI:registerListener()
-- 下载模块在下载过程中不断抛出消息告知某模块的下载进度 BaseDownLoadNodeUI 会检查下载模块跟自身downLoadKey一致就回刷新自己的进度条
function Activity_WordLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

-- 显示的活动名称
function Activity_WordLobbyNode:getBottomName()
    return "WORD"
end

-- 刷新活动倒计时
function Activity_WordLobbyNode:updateLeftTime()
    Activity_WordLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    self:showCounts()
end

-- 显示红点
function Activity_WordLobbyNode:showCounts()
    if not self.m_spRedPoint or not self.m_labelActivityNums then
        return
    end

    local gameData = self:getGameData()
    if not gameData then
        -- 隐藏
        self.m_spRedPoint:setVisible(false)
        return
    end

    local balls = gameData:getBalls()
    if not balls or balls <= 0 then
        self.m_spRedPoint:setVisible(false)
        return
    end

    self.m_spRedPoint:setVisible(true)
    self.m_labelActivityNums:setString(balls)

    local rp_size = self.m_spRedPoint:getContentSize()
    -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
    -- self:updateLabelSize({label = self.m_labelActivityNums}, rp_size.width-15)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
end

-- 关联的活动数据
function Activity_WordLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.Word):getRunningData()
end

-- 获取活动引用名
function Activity_WordLobbyNode:getActRefName()
    return ACTIVITY_REF.Word
end

-- 获取默认的解锁文本
function Activity_WordLobbyNode:getDefaultUnlockDesc()
    local lv = self:getNewUserLv()
    if lv then
        return lv
    else
        return "UNLOCK WORD TORNADO AT LEVEL " .. self:getSysOpenLv()
    end
end

return Activity_WordLobbyNode
