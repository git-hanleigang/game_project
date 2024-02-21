--
-- Author: 刘阳
-- Date: 2020-07-13
-- Desc:厨房活动的大厅节点Node
--

local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_DinnerLandLobbyNode = class("Activity_DinnerLandLobbyNode", BaseActLobbyNodeUI)

function Activity_DinnerLandLobbyNode:initUI(data)
    Activity_DinnerLandLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

-- 入口
function Activity_DinnerLandLobbyNode:clickLobbyNode(sender)
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local dinnerLandData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
    local unLockLevel = self:getSysOpenLv()
    local curLevel = globalData.userRunData.levelNum
    if dinnerLandData == nil or dinnerLandData:isRunning() == false then
        if curLevel < unLockLevel then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tips_msg)
            return
        end
    else
        if curLevel < unLockLevel then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tips_msg)
            return
        end
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if globalDynamicDLControl:checkDownloading("Activity_DinnerLand") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    -- 大厅 餐厅活动入口打点
    self:registDinnerLandPopupLog()

    self:openDinnerLandView()
end

-- 记录打点信息
function Activity_DinnerLandLobbyNode:registDinnerLandPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "DinnerLandLobbyIcon")
    -- gLobalSendDataManager:getDinnerLandActivity():sendPageLog( "RoundPage","Open", "lobby" )
end

function Activity_DinnerLandLobbyNode:openDinnerLandView()
    -- TODO 这里应该是统计
    -- gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen","lobbyBingoIcon")

    -- 打开餐厅主界面

    gLobalActivityManager:showActivityMainView("Activity_DinnerLand", "DinnerLandGameUI", nil, nil)
    self:openLayerSuccess()
end

--下载结束回调
function Activity_DinnerLandLobbyNode:endProcessFunc()
end

function Activity_DinnerLandLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_DinnerLandLobbyNode.csb"
end

function Activity_DinnerLandLobbyNode:getDownLoadKey()
    return "Activity_DinnerLand"
end

function Activity_DinnerLandLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/DinnerLandLogo.png"
end

function Activity_DinnerLandLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_DinnerLandLobbyNode:getBottomName()
    return "DINNERLAND"
end

function Activity_DinnerLandLobbyNode:updateLeftTime()
    Activity_DinnerLandLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local coin = gameData:getDinnerCoin()
            if coin > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(coin)
                local rp_size = self.m_spRedPoint:getContentSize()
                -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
                -- self:updateLabelSize({label = self.m_labelActivityNums}, rp_size.width-15)
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

function Activity_DinnerLandLobbyNode:getGameData()
    return G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
end

-- 获取活动引用名
function Activity_DinnerLandLobbyNode:getActRefName()
    return ACTIVITY_REF.DinnerLand
end

-- 获取默认的解锁文本
function Activity_DinnerLandLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK DINNER LAND AT LEVEL " .. self:getSysOpenLv()
end

return Activity_DinnerLandLobbyNode
