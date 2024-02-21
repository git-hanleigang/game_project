-- 等级里程碑 主界面
local LevelRoadMainLayer = class("LevelRoadMainLayer", BaseLayer)

function LevelRoadMainLayer:ctor()
    LevelRoadMainLayer.super.ctor(self)

    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_mainlayer.csb")
    self:setPortraitCsbName("LevelRoad/csd/Main_Portrait/LevelRoad_mainlayer_Portrait.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("LevelRoadMainLayer")
    self:setBgm("LevelRoad/sound/levelRoadBgm.mp3")
    self:setHideLobbyEnabled(true)
end

function LevelRoadMainLayer:initDatas(_params)
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    self.m_params = _params
    self.m_reconnectNum = 0 -- 重试次数，如果1次重试失败，则之间关闭界面，不卡主玩家
    self.m_resData = nil
    self.m_singleLen = globalData.slotRunData.isPortrait and 340 or 464 -- 俩个奖励节点之间的长度固定（根据这个值设置滚动区域的长度）
    self.m_offsetNum = 100 -- 偏移量
    self.m_isCanCollect = data and data:checkIsCanCollect() or false
    self.m_fingerGuideTime = 0
end

function LevelRoadMainLayer:initCsbNodes()
    self.m_node_main = self:findChild("node_main")
    self.m_node_title = self:findChild("node_title")
    self.m_node_levelbar = self:findChild("node_levelbar")
    self.m_scrollView = self:findChild("ScrollView_1")
    self.m_node_message = self:findChild("node_message")
end

-- 加个小手
function LevelRoadMainLayer:initSpineUI()
    LevelRoadMainLayer.super.initSpineUI(self)
    local spineNode = util_spineCreate("CommonSpine/DeluxeClub_Cat_GuideUI", true, true, 1)
    spineNode:setName("spine_finger")
    self:addChild(spineNode)
    self.m_spine_finger = spineNode
    self.m_spine_finger:setVisible(false)
end

function LevelRoadMainLayer:initView()
    self:initScrollView()
    self:initTitle()
    self:initLevelBar()
    self:initMessage()
    self:showDownTimer()
end

function LevelRoadMainLayer:initScrollView()
    self.m_scrollView:setScrollBarEnabled(false)
    self.m_scrollView:setTouchEnabled(not self.m_isCanCollect)
    self.m_scrollView:onScroll(
        function(data)
            local pos = cc.p(self.m_scrollView:getInnerContainerPosition())
            if globalData.slotRunData.isPortrait then
                if pos.y >= 0 then
                    self.m_scrollView:setInnerContainerPosition(cc.p(pos.x, 0))
                end
            else
                if pos.x >= 0 then
                    self.m_scrollView:setInnerContainerPosition(cc.p(0, pos.y))
                end
            end
        end
    )
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local phase = data:getPhaseData()
        if #phase > 0 then
            local maxNum = math.min(#phase, 5)
            local innerSize = self.m_scrollView:getInnerContainerSize()
            if globalData.slotRunData.isPortrait then
                local innerH = math.max(self.m_offsetNum + maxNum * self.m_singleLen, innerSize.height)
                self.m_scrollView:setInnerContainerSize(cc.size(innerSize.width, innerH))
                self.m_scrollView:jumpToBottom()
            else
                local innerW = math.max(self.m_offsetNum + maxNum * self.m_singleLen, innerSize.width)
                self.m_scrollView:setInnerContainerSize(cc.size(innerW, innerSize.height))
            end
        end
    end
end

function LevelRoadMainLayer:initTitle()
    local titleNode = util_createAnimation("LevelRoad/csd/LevelRoad_title.csb")
    self.m_node_title:addChild(titleNode)
    titleNode:playAction("idle", true, nil, 60)
end

function LevelRoadMainLayer:initLevelBar()
    local levelBar = util_createView("views.LevelRoad.LevelRoadProgress")
    self.m_node_levelbar:addChild(levelBar)
    self.m_levelBar = levelBar
end

function LevelRoadMainLayer:initMessage()
    local messageNode = util_createView("views.LevelRoad.LevelRoadMessage")
    self.m_node_message:addChild(messageNode)
    self.m_messageNode = messageNode
end

function LevelRoadMainLayer:playFingerAnimation()
    if self.m_fingerAnimationing then
        return
    end
    self.m_fingerAnimationing = true
    local pos = self.m_levelBar:getFirstRewardNodePos()
    local nodePos = self.m_spine_finger:getParent():convertToNodeSpace(pos)
    self.m_spine_finger:setPosition(nodePos)
    self.m_spine_finger:runAction(
        cc.RepeatForever:create(
            cc.Sequence:create(
                cc.DelayTime:create(0.2),
                cc.CallFunc:create(
                    function()
                        self.m_spine_finger:setVisible(true)
                        util_spinePlay(self.m_spine_finger, "idleframe", false)
                    end
                ),
                cc.DelayTime:create(1.5),
                cc.CallFunc:create(
                    function()
                        self.m_spine_finger:setVisible(false)
                    end
                ),
                cc.DelayTime:create(0.5)
            )
        )
    )
end

function LevelRoadMainLayer:removeSpineFinger()
    self.m_fingerAnimationing = false
    self.m_isCanCollect = false
    self:stopTimerAction()
    if self.m_spine_finger then
        self.m_spine_finger:setVisible(false)
        self.m_spine_finger:stopAllActions()
    end
end

function LevelRoadMainLayer:onEnter()
    LevelRoadMainLayer.super.onEnter(self)
    -- 请求领取奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.isSuc then
                self:removeSpineFinger()
                self.m_scrollView:setTouchEnabled(false)
                local resData = params.resData or {}
                self.m_resData = resData
                local callFunc = function()
                    if resData.swell then
                        G_GetMgr(G_REF.LevelRoad):showBoostLayer(resData)
                    elseif resData.items or resData.coins then
                        G_GetMgr(G_REF.LevelRoad):showRewardLayer(resData)
                    else
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER)
                    end
                end
                if resData.isFirst then
                    self.m_levelBar:hideFirstNode()
                    local startPos = self.m_levelBar:getFirstRewardNodePos()
                    local endPos = self.m_node_main:getParent():convertToWorldSpace(cc.p(self.m_node_main:getPosition()))
                    local boxAni = util_createView("views.LevelRoad.LevelRoadBoxAnimation", startPos, endPos, callFunc)
                    self.m_node_main:addChild(boxAni, 999)
                    boxAni:playStartAni()
                else
                    callFunc()
                end
            else
                self.m_isTouch = false
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_REQUEST_REWARD
    )
    -- 奖励界面关闭（需要等待动画时间）
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            util_performWithDelay(
                self,
                function()
                    self.m_scrollView:setTouchEnabled(true)
                    self.m_isTouch = false
                    if params then
                        G_GetMgr(ACTIVITY_REF.LevelRoadGame):onClickMail()
                    end
                end,
                90 / 60
            )
            self.m_messageNode:refreshBuff()
        end,
        ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER
    )
    -- boost界面关闭
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.m_resData then
                if self.m_resData.items or self.m_resData.coins then
                    G_GetMgr(G_REF.LevelRoad):showRewardLayer(self.m_resData)
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER)
                end
                self.m_resData = nil
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER)
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_CLOSE_BOOSTLAYER
    )
end

function LevelRoadMainLayer:clickFunc(sender)
    if self.m_isTouch then
        return
    end

    local name = sender:getName()
    if name == "btn_close" then
        self:closeView()
    end
end

function LevelRoadMainLayer:closeView()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local isCanCollect = data:checkIsCanCollect()
        if isCanCollect and self.m_reconnectNum < 1 then
            self.m_reconnectNum = self.m_reconnectNum + 1
            self.m_isTouch = true
            G_GetMgr(G_REF.LevelRoad):requestCollectReward()
        else
            self:closeUI()
        end
    else
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_REFRESH_LOBBY_BOTTOMNODE)
            end
        )
    end
end

--显示倒计时
function LevelRoadMainLayer:showDownTimer()
    if not self.m_isCanCollect then
        return
    end
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function LevelRoadMainLayer:updateLeftTime()
    if self.m_isCanCollect then
        self.m_fingerGuideTime = self.m_fingerGuideTime + 1
        if self.m_fingerGuideTime > 3 then
            self:playFingerAnimation()
            self:stopTimerAction()
        end
    else
        self:stopTimerAction()
    end
end

function LevelRoadMainLayer:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

return LevelRoadMainLayer
