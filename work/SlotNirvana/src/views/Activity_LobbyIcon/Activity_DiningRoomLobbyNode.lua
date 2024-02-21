-- 新版餐厅 大厅入口控件
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_DiningRoomLobbyNode = class("Activity_DiningRoomLobbyNode", BaseActLobbyNodeUI)

function Activity_DiningRoomLobbyNode:initUI(data)
    Activity_DiningRoomLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

-- 入口
function Activity_DiningRoomLobbyNode:clickLobbyNode(sender)
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

    self:openDiningRoomView()
end

function Activity_DiningRoomLobbyNode:openDiningRoomView()
    -- 大厅 餐厅活动入口打点
    self:registDiningRoomPopupLog()
    -- 打开餐厅选关主界面

    gLobalActivityManager:showActivityMainView("Activity_DiningRoom", "DiningRoomGameUI", nil, nil)
    self:openLayerSuccess()

    local guideView = gLobalViewManager:getViewByExtendData("Activity_DiningRoomGudieLayer")
    if guideView then
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        guideView:closeSelf()
    end
end

-- 记录打点信息
function Activity_DiningRoomLobbyNode:registDiningRoomPopupLog()
    gLobalSendDataManager:getLogIap():setEntryType("lobby")
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "DiningRoomLobbyIcon")
end

-- 资源名
function Activity_DiningRoomLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_DiningRoomLobbyNode.csb"
end

-- 下载key
function Activity_DiningRoomLobbyNode:getDownLoadKey()
    return "Activity_DiningRoom"
end

-- 下载进度条图片
function Activity_DiningRoomLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/DinnerLandLogo.png"
end

-- 下载节点
function Activity_DiningRoomLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_DiningRoomLobbyNode:getBottomName()
    return "DINNER LAND"
end

-- 活动倒计时刷新
function Activity_DiningRoomLobbyNode:updateLeftTime()
    Activity_DiningRoomLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local num = gameData:getPigNum() + gameData:getWildBags()
            if num > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(num)
                -- self:updateLabelSize({label = self.m_labelActivityNums},35)
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

function Activity_DiningRoomLobbyNode:getGameData()
    return G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
end

--下载结束回调
function Activity_DiningRoomLobbyNode:endProcessFunc()
    -- self:checkGuide()
end

function Activity_DiningRoomLobbyNode:onEnter()
    Activity_DiningRoomLobbyNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.stage == 1 then
                self:checkGuide()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_GUIDE
    )
end

function Activity_DiningRoomLobbyNode:checkGuide()
    if not globalDynamicDLControl:checkDownloading(ACTIVITY_REF.DiningRoom) then
        local guideView = util_createView("Activity.GameUI.Activity_DiningRoomGudieLayer", 1)
        if guideView then
            local lobbyNode = util_createView("views.Activity_LobbyIcon.Activity_DiningRoomLobbyNode")
            if lobbyNode then
                local worldPos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
                local localPos = guideView:getRootNode():convertToNodeSpace(worldPos)
                lobbyNode:addTo(guideView:getRootNode())
                lobbyNode:setPosition(cc.p(localPos))
                lobbyNode:setZOrder(100)
                guideView:addFinger(lobbyNode)
                gLobalViewManager:showUI(guideView, ViewZorder.ZORDER_UI)
            end
        end
    end
end

-- 获取活动引用名
function Activity_DiningRoomLobbyNode:getActRefName()
    return ACTIVITY_REF.DiningRoom
end

-- 获取默认的解锁文本
function Activity_DiningRoomLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK DINNER LAND AT LEVEL " .. self:getSysOpenLv()
end

return Activity_DiningRoomLobbyNode
