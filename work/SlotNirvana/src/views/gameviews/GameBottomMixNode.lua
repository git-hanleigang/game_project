local GameBottomMixNode = class("GameBottomMixNode", util_require("base.BaseView"))

local popType = {
    First = 1, --第一次进入关卡
    Two = 2, --如果有完成的任务
    Three = 3 --限时活动开启
}
--toComplete
function GameBottomMixNode:initUI(machine)
    self:createCsbNode("GameNode/GameBottomSwitchNode.csb")

    self.m_machine = machine

    local taskNode = self:findChild("taskNode")
    self.m_taskNode = util_createView("views.dailytasks.DailyTaskLevelEnter")
    taskNode:addChild(self.m_taskNode)

    local challengeNode = self:findChild("challengeNode")
    self.m_challengeNode = util_createView("views.gameviews.LuckyChallengeLevelEnter")
    challengeNode:addChild(self.m_challengeNode)

    self:addClick(self:findChild("clickBtn"))

    self.m_leftPopNode = self:findChild("challengePopLeftNode") -- 竖版使用此节点
    self.m_rightPopNode = self:findChild("challengePopRightNode") -- 横版使用此节点

    self:initBubble()
    -- self:playAnim("taskIdle")

    if self:checkInChallenge() then
        self:playAnim("challengeIdle")
    else
        self:playAnim("taskIdle")
    end
    self:resetChange()
end

function GameBottomMixNode:initBubble()
    self.m_bubbleList = {}

    self.m_qiPao = util_createView("views.gameviews.GameBottomChallengePop")
    -- if globalData.slotRunData.isPortrait == true then
    --     self:findChild("challengePopRightNode"):addChild(self.m_qiPao)
    -- else
    self:findChild("challengePopLeftNode"):addChild(self.m_qiPao)
    self.m_qiPao:setPositionX(45)
    if not globalData.slotRunData:isFramePortrait() then
        self.m_qiPao:setPositionY(-10)
    end
    -- end
    self.m_qiPao:setVisible(false)
end

--如果是在luckychallenge关卡的话 优先显示luckychallenge
function GameBottomMixNode:checkInChallenge()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and globalData.slotRunData.gameNetWorkModuleName then
        local task = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self:getLevID())
        if task and #task > 0 then
            return task
        end
    end
    return false
end

function GameBottomMixNode:playAnim(name, isLoop, callFun)
    self.m_aniName = name
    self:runCsbAction(
        name,
        isLoop,
        function()
            if callFun then
                callFun()
            end
        end
    )
end

function GameBottomMixNode:resetChange()
    self:removeAction()
    self.m_changeAction =
        schedule(
        self,
        function()
            if self.m_aniName == "challengeIdle" then
                self:playAnim(
                    "change2Task",
                    false,
                    function()
                        self:playAnim("taskIdle")
                    end
                )
            elseif self.m_aniName == "taskIdle" then
                self:playAnim(
                    "change2Challenge",
                    false,
                    function()
                        self:playAnim("challengeIdle")
                    end
                )
            end
            self:resetChange()
        end,
        8
    )
end

function GameBottomMixNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params) --强制切换任务显示
            self:switchState(params)
        end,
        ViewEventType.NOTIFY_GAME_BOTTOM_FORCE_SWITCH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) --强制切换任务显示
            local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
            if luckyChallengeData then
                local task = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self:getLevID())
                if task then
                    self:showStartAnim(popType.Two)
                end
            end
        end,
        ViewEventType.NOTIFY_GAME_BOTTOM_LC_COMPLETE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            --每个关卡仅第一次进入时弹出
            if not self.m_isFirstEnter then
                self.m_isFirstEnter = true
                self:showStartAnim(popType.First)
            end
        end,
        ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showStartAnim()
        end,
        ViewEventType.NOTIFY_LC_LEVELUP_OPEN
    )

    local machine = self.m_machine
    performWithDelay(
        self,
        function()
            if machine ~= nil and machine.isShowChooseBetOnEnter ~= nil and not machine:isShowChooseBetOnEnter() then
                self.m_isFirstEnter = true
                self:showStartAnim(popType.First)
            end
        end,
        0.5
    )

    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and luckyChallengeData:isOpen() then --已经完成
        self:switchState(1)
    end
end

function GameBottomMixNode:showStartAnim(_flag)
    if not self:checkInChallenge() then
        return
    end
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and luckyChallengeData:isOpen() then
        self:switchState(2)
        if self.m_qiPao then
            self.m_qiPao:showPop(_flag)
            performWithDelay(
                self,
                function()
                    if self.m_qiPao.m_popShow ~= nil and self.m_qiPao.m_popShow == true then
                        self.m_qiPao:hidePop()
                    end
                end,
                5
            )
        -- gLobalViewManager:addAutoCloseTips(self.m_qiPao,function()
        --     self.m_qiPao:hidePop()
        -- end)
        end
    end
end

function GameBottomMixNode:switchState(params)
    if params == 1 then --task
        -- self.m_taskNode:setVisible(true)
        -- self.m_challengeNode:setVisible(false)
        self:playAnim(
            "change2Task",
            false,
            function()
                self:playAnim("taskIdle")
            end
        )
    else --challenge
        -- self.m_taskNode:setVisible(false)
        -- self.m_challengeNode:setVisible(true)
        self:playAnim(
            "change2Challenge",
            false,
            function()
                self:playAnim("challengeIdle")
            end
        )
    end
    self:resetChange()
end

function GameBottomMixNode:getLevID()
    local p_id = globalData.slotRunData.machineData.p_id
    local levedata = globalData.slotRunData:getLevelInfoByName(globalData.slotRunData.machineData.p_levelName)
    if levedata then
        p_id = levedata.p_id
    end
    return p_id
end

function GameBottomMixNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function GameBottomMixNode:clickFunc(sender)
    local senderName = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_qiPao and self.m_qiPao.m_popShow ~= nil and self.m_qiPao.m_popShow == true then
        self.m_qiPao:setVisible(false)
        self.m_qiPao:hidePop()
    end

    -- if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION then
    --     -- 等级未解锁
    --     return
    -- elseif not gLobalDailyTaskManager:isCanShowLayer() then
    --     return
    -- end
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BOTTOM_TASKCLICK, 1)

    if not self.m_tipView or tolua.isnull(self.m_tipView) then
        self.m_tipView = util_createView("views.gameviews.GameBottomMixTipView")
        -- if globalData.slotRunData.isPortrait == true then
        --     self:findChild("tipRighttNode"):addChild(self.m_tipView)
        -- else
        self:findChild("tipLeftNode"):addChild(self.m_tipView)
    -- end
    end
    if self.m_tipView.m_popShow ~= nil and self.m_tipView.m_popShow == true then
        self.m_tipView:hidePop()
    else
        self.m_tipView:showPop()
    end
end

function GameBottomMixNode:removeAction()
    if self.m_changeAction then
        self:stopAction(self.m_changeAction)
        self.m_changeAction = nil
    end
end

return GameBottomMixNode
