local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_BingoLobbyNode = class("Activity_BingoLobbyNode", BaseActLobbyNodeUI)

function Activity_BingoLobbyNode:initUI(data)
    Activity_BingoLobbyNode.super.initUI(self, data)
    self:initBingoGuide()

    self:initUnlockUI()
end

-- 删除bingo在大厅中的引导 2019-09-10 需求策划：黄腾达
function Activity_BingoLobbyNode:initBingoGuide()
end

function Activity_BingoLobbyNode:registerListener()
    Activity_BingoLobbyNode.super.registerListener(self)
end

function Activity_BingoLobbyNode:openBingoSelectUI()
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyBingoIcon")

    G_GetMgr(ACTIVITY_REF.Bingo):showSelectLayer()
    self:openLayerSuccess()
end

--点击了活动node
function Activity_BingoLobbyNode:clickLobbyNode()
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

    if globalDynamicDLControl:checkDownloading("Activity_Bingo") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end
    self:openBingoSelectUI()
end

function Activity_BingoLobbyNode:onEnter()
    Activity_BingoLobbyNode.super.onEnter(self)
end

function Activity_BingoLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_BingoLobbyNode.csb"
end

function Activity_BingoLobbyNode:getDownLoadKey()
    return "Activity_Bingo"
end

function Activity_BingoLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/bingo_node.png"
end

function Activity_BingoLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_BingoLobbyNode:getBottomName()
    return "BINGO"
end

function Activity_BingoLobbyNode:updateLeftTime()
    Activity_BingoLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local LeftBalls = gameData:getLeftBalls()
            if LeftBalls > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(LeftBalls)
                -- self:updateLabelSize({label = self.m_labelActivityNums}, 35)
                util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
            else
                self.m_spRedPoint:setVisible(false)
            end
        else
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
        end
    end
end

function Activity_BingoLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
end

-- 获取活动引用名
function Activity_BingoLobbyNode:getActRefName()
    return ACTIVITY_REF.Bingo
end

-- 获取默认的解锁文本
function Activity_BingoLobbyNode:getDefaultUnlockDesc()
    local lv = self:getNewUserLv()
    if lv then
        return lv
    else
        return "UNLOCK BINGO LINK AT LEVEL " .. self:getSysOpenLv()
    end
end

function Activity_BingoLobbyNode:updateView()
    Activity_BingoLobbyNode.super.updateView(self)

    self.m_lockIocn:setVisible(false) -- 锁定icon
    self.btnFunc:setOpacity(255)
end

return Activity_BingoLobbyNode
