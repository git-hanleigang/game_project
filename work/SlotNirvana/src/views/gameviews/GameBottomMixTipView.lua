local GameBottomMixTipView = class("GameBottomMixTipView", util_require("base.BaseView"))

--toComplete
function GameBottomMixTipView:initUI()
    self:createCsbNode("GameNode/GameBottomTCNode.csb")

    self.m_redNode = self:findChild("redPoint")
    self.m_lbRedPoint = self:findChild("lbRedPoint")

    -- self.m_redNodeBattlePass = self:findChild("redPoint_BattlePass")
    -- self.m_lbRedPointBattlePass = self:findChild("lbRedPoint_BattlePass")

    self:updateRedPoint()

    self:addClick(self:findChild("btn_challenge"))
    self:addClick(self:findChild("btn_mission"))

    self:findChild("lb_missionUnlockLevel"):setString(globalData.constantData.OPENLEVEL_DAILYMISSION)
    self:findChild("lb_challengeUnlockLevel"):setString(globalData.constantData.CHALLENGE_OPEN_LEVEL)
    -- local openLevel = globalData.constantData.BATTLEPASS_OPEN_LEVEL or 25 --解锁等级
    -- self:findChild("lb_BattlePassUnlockLevel"):setString(openLevel)

    self.m_tip1 = self:findChild("tip1_challengeUnlockLevel")
    self.m_tip2 = self:findChild("tip2_challengeNewSeason")
    self.m_tip3 = self:findChild("tip3_missionUnlockLevel")
    self.m_tip4 = self:findChild("tip4_challengeDownloading")
    self.m_tip5 = self:findChild("tip5_missionDownloading") -- csc 2021-10-23 新增mission 下载状态锁住
    -- self.m_tip5 = self:findChild("tip5_BattlePassDownloading")
    -- self.m_tip6 = self:findChild("tip6_BattlePassUnlockLevel")
    -- self.m_tip7 = self:findChild("tip7_BattlePassNewSeason")

    self.m_sp_arrowLeft = self:findChild("sp_arrowLeft")
    self.m_sp_arrowRight = self:findChild("sp_arrowRight")
    self.m_sp_arrowBelow = self:findChild("sp_arrowBelow")

    self:initLock()
end

function GameBottomMixTipView:initLock()
    self:findChild("sp_missionRedPoint"):setVisible(false)
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION then
        self:findChild("sp_missionlock"):setVisible(true)
    elseif not gLobalDailyTaskManager:isCanShowLayer() then --csc 2021-10-23 检查每日任务界面是否可以展开
        self:findChild("sp_missionlock"):setVisible(true)
    else
        self:findChild("sp_missionlock"):setVisible(false)
        if globalData.missionRunData and globalData.missionRunData:checkRedPointNum() then
            self:findChild("sp_missionRedPoint"):setVisible(true)
        end
    end

    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData then
        self:findChild("sp_challengelock"):setVisible(false)
    else
        self:findChild("sp_challengelock"):setVisible(true)
    end

    -- if gLobalBattlePassManager:getIsOpen() then
    --     self:findChild("sp_BattlePassLock"):setVisible(false)
    -- else
    --     self:findChild("sp_BattlePassLock"):setVisible(true)
    -- end
end

function GameBottomMixTipView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRedPoint()
        end,
        ViewEventType.NOTIFY_GAMEEFFECT_OVER
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRedPoint()
        end,
        ViewEventType.NOTIFY_LC_UPDATE_VIEW
    )

    if not gLobalDailyTaskManager:isCanShowLayer() then
        gLobalNoticManager:addObserver(
            self,
            function(target, percent)
                self:initLock()
            end,
            "DL_Complete" .. ACTIVITY_REF.NewPass
        )
    end
end

-- function GameBottomMixTipView:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

function GameBottomMixTipView:clickFunc(sender)
    if self.m_popShow == nil or self.m_popShow == false then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local senderName = sender:getName()
    if "btn_mission" == senderName then
        if self.m_isPlayingMission ~= nil and self.m_isPlayingMission == true then
            return
        end
        self:clearView(false, false, true)
        if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION then
            self.m_tip3:setVisible(true)
            self.m_isPlayingMission = true
            self:playSmallTipAnima()
            return
        elseif not gLobalDailyTaskManager:isCanShowLayer() then
            self.m_tip5:setVisible(true)
            self.m_isPlayingMission = true
            self:playSmallTipAnima()
            return
        end
        self:hidePop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BOTTOM_TASKCLICK, 1)
    elseif "btn_challenge" == senderName then
        if self.m_isPlayingCL ~= nil and self.m_isPlayingCL == true then
            return
        end
        self:clearView(true, false, false)

        --等级不足
        if globalData.userRunData.levelNum < globalData.constantData.CHALLENGE_OPEN_LEVEL then
            self.m_tip1:setVisible(true)
            self.m_isPlayingCL = true
            self:playSmallTipAnima()
            return
        end
        local _lcMgr = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge)
        if not _lcMgr then
            return
        end
        --coomingsoon
        local luckyChallengeData = _lcMgr:getRunningData()
        if luckyChallengeData == nil then
            self.m_tip2:setVisible(true)
            self.m_isPlayingCL = true
            self:playSmallTipAnima()
            return
        end
        --未下载
        if not _lcMgr:isDownloadRes() then
            self.m_tip4:setVisible(true)
            self.m_isPlayingCL = true
            self:playSmallTipAnima()
            return
        end
        self:hidePop()

        _lcMgr:showMainLayer(nil, sender:getTouchEndPosition())
    -- elseif senderName == "btn_BattlePass" then
    --     if self.m_isPlayingBattlePass ~= nil and self.m_isPlayingBattlePass == true then
    --         return
    --     end
    --     self:clearView(false,false,true)
    --     local openLevel = globalData.constantData.BATTLEPASS_OPEN_LEVEL or 25 --解锁等级
    --     if globalData.userRunData.levelNum < openLevel then
    --         self.m_tip6:setVisible(true)
    --         self.m_isPlayingBattlePass = true
    --         self:playSmallTipAnima()
    --         return
    --     end
    --     --coomingsoon
    --     local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    --     if not bpData or  not bpData:isRunning() then
    --         self.m_tip7:setVisible(true)
    --         self.m_isPlayingBattlePass = true
    --         self:playSmallTipAnima()
    --         return
    --     end
    --     --未下载
    --     if globalDynamicDLControl:checkDownloading(ACTIVITY_REF.BattlePass) then
    --         self.m_tip5:setVisible(true)
    --         self.m_isPlayingBattlePass = true
    --         self:playSmallTipAnima()
    --         return
    --     end
    --     self:hidePop()

    --     local battlePassMainUi = util_createView("Activity.BattlePassCode.BattlePassMainLayer")
    --     gLobalViewManager:showUI(battlePassMainUi)
    end
end

function GameBottomMixTipView:clearView(isLeft, isBelow, isRight)
    self.m_sp_arrowRight:setVisible(isRight)
    self.m_sp_arrowLeft:setVisible(isLeft)
    self.m_sp_arrowBelow:setVisible(isBelow)
    self:hideTip()
    self:removeAllSch()
    self:addDelayTimer()
end

function GameBottomMixTipView:playSmallTipAnima()
    local animName = "tipShow_heng"
    local idleName = "tipIdle_heng"
    local colseName = "tipClose_heng"
    -- if globalData.slotRunData.isPortrait == true then
    --     animName = "tipShow_shu"
    --     idleName = "tipIdle_shu"
    --     colseName = "tipClose_shu"
    -- end

    self.m_showAct =
        self:runCsbAction(
        animName,
        false,
        function()
            self:runCsbAction(idleName, true)
        end
    )
    self.m_closeAct =
        performWithDelay(
        self,
        function()
            self:runCsbAction(
                colseName,
                nil,
                function()
                    self:removeAllSch()
                end
            )
        end,
        3
    )
end

--未开启提示语隐藏
function GameBottomMixTipView:hideTip()
    self.m_tip1:setVisible(false)
    self.m_tip2:setVisible(false)
    self.m_tip3:setVisible(false)
    self.m_tip4:setVisible(false)
    self.m_tip5:setVisible(false)
    -- self.m_tip6:setVisible(false)
    -- self.m_tip7:setVisible(false)
end

function GameBottomMixTipView:updateRedPoint()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and luckyChallengeData:isOpen() then
        local redNum = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getAllRed()
        if redNum > 0 then
            self.m_redNode:setVisible(true)
            self.m_lbRedPoint:setString(redNum)
        else
            self.m_redNode:setVisible(false)
        end
    else
        self.m_redNode:setVisible(false)
    end

    -- battlepass
    -- if gLobalBattlePassManager:getIsOpen() then
    --     local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    --     local canClaimNum = bpData:getCanClaimNum()
    --     if  canClaimNum > 0  then
    --         self.m_redNodeBattlePass:setVisible(true)
    --         self.m_lbRedPointBattlePass:setString(canClaimNum)
    --     else
    --         self.m_redNodeBattlePass:setVisible(false)
    --     end
    -- else
    --     self.m_redNodeBattlePass:setVisible(false)
    -- end
end

--外部调用打开接口
function GameBottomMixTipView:showPop()
    if self.m_isPlayingAnima == true then
        return
    end
    self.m_popShow = true
    self.m_tip1:setVisible(false)
    self.m_tip2:setVisible(false)
    self.m_tip3:setVisible(false)
    self.m_tip5:setVisible(false)
    -- self.m_tip6:setVisible(false)
    -- self.m_tip7:setVisible(false)

    self:initLock()
    self:setVisible(true)

    self:addMask()
    self:updateRedPoint()
    self:addDelayTimer()
    local animName = "show_heng"
    -- if globalData.slotRunData.isPortrait == true then
    --     animName = "show_shu"
    -- end
    self.m_isPlayingAnima = true
    self:runCsbAction(
        animName,
        false,
        function()
            self.m_isPlayingAnima = false
        end
    )

    self:setXpos(true)
end

--隐藏气泡
function GameBottomMixTipView:hidePop()
    if self.m_isPlayingAnima == true then
        return
    end
    self.m_popShow = false
    if self.m_schAct then
        self:stopAction(self.m_schAct)
    end
    self.m_schAct = nil

    self:removeAllSch()
    self:removeMask()

    local animName = "close_heng"
    -- if globalData.slotRunData.isPortrait == true then
    --     animName = "close_shu"
    -- end
    self.m_isPlayingAnima = true
    self:runCsbAction(
        animName,
        false,
        function()
            self:setVisible(false)
            self:setXpos(false)
            self.m_isPlayingAnima = false
        end
    )
end

function GameBottomMixTipView:addDelayTimer()
    if self.m_schAct then
        self:stopAction(self.m_schAct)
    end
    self.m_schAct = nil
    self.m_schAct =
        performWithDelay(
        self,
        function()
            if self.m_popShow ~= nil and self.m_popShow == true then
                self:hidePop()
            end
        end,
        5
    )
end

function GameBottomMixTipView:setXpos(isShow)
    local xDis = 0
    if globalData.slotRunData.isPortrait == true then
        xDis = 0
    end
    if isShow == true then
        self:setPositionX(self:getPositionX() + xDis)
    else
        self:setPositionX(self:getPositionX() - xDis)
    end
end
--移除动画
function GameBottomMixTipView:removeAllSch()
    if self.m_showAct then
        self:stopAction(self.m_showAct)
    end
    self.m_showAct = nil

    if self.m_closeAct then
        self:stopAction(self.m_closeAct)
    end
    self.m_closeAct = nil

    self.m_isPlayingCL = false
    self.m_isPlayingMission = false
    -- self.m_isPlayingBattlePass = false
end

--添加透明遮罩
function GameBottomMixTipView:addMask()
    self:removeMask()
    self.m_mask = util_newMaskLayer()
    self:addChild(self.m_mask, -1)
    self.m_mask:setOpacity(0)
    self.m_mask:setScale(10)
    self.m_mask:onTouch(
        function(event)
            if event.name ~= "ended" then
                return true
            end
            self:hidePop()
        end,
        false,
        true
    )
end
function GameBottomMixTipView:removeMask()
    if self.m_mask then
        self.m_mask:removeFromParent()
        self.m_mask = nil
    end
end
function GameBottomMixTipView:onExit()
    if self.m_schAct then
        self:stopAction(self.m_schAct)
    end
    self:removeMask()
    self:removeAllSch()
    gLobalNoticManager:removeAllObservers(self)
end

return GameBottomMixTipView
