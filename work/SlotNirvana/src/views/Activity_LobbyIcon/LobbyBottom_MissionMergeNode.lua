local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_MissionMergeNode = class("LobbyBottom_MissionMergeNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_MissionMergeNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomMissionMergeNode.csb")

    self:initView()

    self.m_sprRed = self:findChild("sprite_red")
    self.m_labelRedNum = self:findChild("label_total_num")

    self:refresRedTips()

    self.m_bCreate = true
end

-- function LobbyBottom_MissionMergeNode:initView( )

-- end

function LobbyBottom_MissionMergeNode:setMergeNodeInfo(data)
    self.m_mergeLobbyNodoInfo = data
end

function LobbyBottom_MissionMergeNode:updateView()
    -- 单纯重写 防止父类调用
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_timeBg:setVisible(false)
end

function LobbyBottom_MissionMergeNode:refresRedTips()
    if not self.m_sprRed or not self.m_labelRedNum then
        return
    end
    -- 每日任务
    local count = 0
    if globalData.userRunData.levelNum >= globalData.constantData.OPENLEVEL_DAILYMISSION then
        local totalNum = globalData.missionRunData.p_totalMissionNum or 0
        local curNum = globalData.missionRunData.p_currMissionID or 0
        count = totalNum - curNum + 1
        local taskInfo = globalData.missionRunData.p_taskInfo
        if totalNum == curNum and taskInfo and taskInfo.p_taskCompleted and taskInfo.p_taskCollected then
            count = 0
        end
    end

    -- 钻石挑战
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.LuckyChallenge):getRunningData()
    if luckyChallengeData then
        local redNum = luckyChallengeData:getRedPoint(0)
        count = count + redNum
    end

    if count > 0 then
        self.m_sprRed:setVisible(true)
        self.m_labelRedNum:setString(tostring(count))
    else
        self.m_sprRed:setVisible(false)
    end
end

function LobbyBottom_MissionMergeNode:createMergeNode()
    -- 创建活动合并节点
    if self.mergeNode == nil then
        self.mergeNode = util_createView("Activity_LobbyIconRes/MissionMergeNode", self.m_mergeLobbyNodoInfo)
        -- self:addChild(self.mergeNode)
        gLobalViewManager:getViewLayer():addChild(self.mergeNode, ViewZorder.ZORDER_GUIDE + 2)
        local wordPos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
        self.mergeNode:setPosition(wordPos)
        self.mergeNode:setScaleForResolution(true)
        self.m_bCreate = false

        self:openLayerSuccess()
    else
        self.mergeNode:removeFromParent()
        self.mergeNode = nil
        performWithDelay(
            self,
            function()
                self.m_bCreate = true
            end,
            0.1
        )
    end
end

function LobbyBottom_MissionMergeNode:getBottomName()
    return "MISSION"
end

-- 节点特殊处理逻辑 --
function LobbyBottom_MissionMergeNode:clickLobbyNode()
    --
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if self.m_bCreate then
        self:createMergeNode()
    end
end

function LobbyBottom_MissionMergeNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

-- onEnter
function LobbyBottom_MissionMergeNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target)
            self:createMergeNode()
        end,
        ViewEventType.NOTIFY_MISSION_MERGE_NODE_CLICK
    )

    -- 需要监听两个活动的刷新点数消息
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:refresRedTips()
        end,
        ViewEventType.NOTIFY_LC_UPDATE_VIEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:refresRedTips()
        end,
        ViewEventType.NOTIFY_MISSION_REFRESH
    )
end

function LobbyBottom_MissionMergeNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

return LobbyBottom_MissionMergeNode
