--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-05-12 10:24:48
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_ScratchCardsLobbyNode = class("Activity_ScratchCardsLobbyNode", BaseActLobbyNodeUI)

function Activity_ScratchCardsLobbyNode:initUI(data)
    Activity_ScratchCardsLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

-- 点击响应逻辑 活动跳转和一些点击提示
function Activity_ScratchCardsLobbyNode:clickLobbyNode()
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

    if not G_GetMgr(ACTIVITY_REF.ScratchCards):isCanShowLayer() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_UI_OPEN_VIEW)
    G_GetMgr(ACTIVITY_REF.ScratchCards):showMainLayer()
end

function Activity_ScratchCardsLobbyNode:onEnter()
    Activity_ScratchCardsLobbyNode.super.onEnter(self)
end

-- 资源名称
function Activity_ScratchCardsLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_ScratchNode.csb"
end

-- 关联下载资源的文件夹名称
-- 如果资源没下载 按钮上会显示这个文件夹的下载进度
function Activity_ScratchCardsLobbyNode:getDownLoadKey()
    return "Activity_ScratchCards"
end

--获得下载进度图片路径
function Activity_ScratchCardsLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/Scratch_card.png"
end

-- 用于下载显示的节点 将在这个节点上创建一个扇形进度条来显示下载进度
-- 具体下载控制逻辑参考 BaseDownLoadNodeUI:registerListener()
-- 下载模块在下载过程中不断抛出消息告知某模块的下载进度 BaseDownLoadNodeUI 会检查下载模块跟自身downLoadKey一致就回刷新自己的进度条
function Activity_ScratchCardsLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

-- 显示的活动名称
function Activity_ScratchCardsLobbyNode:getBottomName()
    return "SCRATCH"
end

-- 刷新活动倒计时
function Activity_ScratchCardsLobbyNode:updateLeftTime()
    Activity_ScratchCardsLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    self:showCounts()
end

-- 显示红点
function Activity_ScratchCardsLobbyNode:showCounts()
    if not self.m_spRedPoint or not self.m_labelActivityNums then
        return
    end
    local gameData = self:getGameData()
    if not gameData then
        -- 隐藏
        self.m_spRedPoint:setVisible(false)
        return
    end

    local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
    if not data then
        self.m_spRedPoint:setVisible(false)
        return
    end
    local counts = data:isFree() and 1 or 0
    local lastCard = data:getUserLastCards()
    counts = counts + lastCard
    if counts <= 0 then
        self.m_spRedPoint:setVisible(false)
        return
    end
    self.m_spRedPoint:setVisible(true)
    self.m_labelActivityNums:setString("" .. counts)
    local rp_size = self.m_spRedPoint:getContentSize()
    util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
end

-- 关联的活动数据
function Activity_ScratchCardsLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.ScratchCards):getRunningData()
end

-- 获取活动引用名
function Activity_ScratchCardsLobbyNode:getActRefName()
    return ACTIVITY_REF.ScratchCards
end

-- 获取默认的解锁文本
function Activity_ScratchCardsLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK SCRATCH AT LEVEL " .. self:getSysOpenLv()
end

return Activity_ScratchCardsLobbyNode
