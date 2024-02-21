---------
local LuckyChallengeLevelEnter = class("LuckyChallengeLevelEnter", util_require("base.BaseView"))
local EnterState = {
    LOCK = 1,
    CHNAGEGAME = 2,
    BETENOUGH = 3,
    BETNOTENOUGH = 4,
    COMPLETE = 5
}
function LuckyChallengeLevelEnter:initUI()
    local csbName = "GameNode/GameBottomChallengeNode.csb"
    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    if bOpenDeluxe then
        csbName = "GameNode/GameBottomChallengeNode_1.csb"
    end
    self:createCsbNode(csbName)

    self.m_img_light = self:findChild("img_light")
    self.m_img_lock = self:findChild("img_lock")
    self.m_sp_dark = self:findChild("sp_dark")

    self.m_lb_Lock = self:findChild("lb_Lock")
    self.m_sp_changeGame = self:findChild("sp_changeGame")
    self.m_sp_addBet = self:findChild("sp_addBet")
    self.m_lb_spin = self:findChild("lb_spin")
    self.m_lb_Collect = self:findChild("lb_Collect")

    self:initState(true)
    self:initProgress()
    self.m_loadingProgress:setPercentage(self:getTaskProcess())
end
-------------------------------------new---------------------------------------
function LuckyChallengeLevelEnter:initProgress()
    -- 创建进度条
    local rateImg = self:findChild("jindu_tiao")
    rateImg:setVisible(false)
    local img = util_createSprite("GameNode/ui_challengeTask/2020_spin_jindu.png")
    self.m_loadingProgress = cc.ProgressTimer:create(img)
    self.m_loadingProgress:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_loadingProgress:setPercentage(0)
    -- self.m_loadingProgress:setAnchorPoint(0.5,0)
    self.m_loadingProgress:setPosition(cc.p(0, 0))
    self.m_loadingProgress:setScaleX(img:getScaleX())
    self.m_loadingProgress:setScaleY(img:getScaleY())
    self:findChild("clipping_node"):addChild(self.m_loadingProgress, 1)
end

function LuckyChallengeLevelEnter:setProgress(progress, endCall)
    local time = 0.5
    local actionList = {}
    actionList[#actionList + 1] = cc.ProgressTo:create(time, progress)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if endCall and not tolua.isnull(self) then
                endCall()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    self.m_loadingProgress:runAction(seq)
end

-------------------------------------newend---------------------------------------
function LuckyChallengeLevelEnter:initState(_init)
    self.m_img_light:setVisible(false)
    self.m_img_lock:setVisible(false)
    self.m_sp_dark:setVisible(false)

    self.m_lb_Lock:setVisible(false)
    self.m_sp_changeGame:setVisible(false)
    self.m_sp_addBet:setVisible(false)
    self.m_lb_spin:setVisible(false)
    self.m_lb_Collect:setVisible(false)

    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData then
        self:showDownTimer()
        self.m_task = nil
       
        local task = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self:getLevID())
        if task and #task > 0 then
            self.m_task = task[1]
        end
        
        if self.m_task then
            if self.m_task:getCompleted() then --任务完成
                if not _init then
                    if not self.m_First then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_BOTTOM_LC_COMPLETE)
                    end
                    self.m_First = true
                end
                
                self.m_state = EnterState.COMPLETE
                self.m_img_light:setVisible(true)
                self.m_lb_Collect:setVisible(true)
                if self.m_aniName ~= "complete" and self.m_aniName ~= "toComplete" then
                    self:runCsbAction("complete", true)
                end
                return
            else
                self.m_First = false
                --bet enough
                if self:checkBetEnough(self.m_task) then
                    self.m_state = EnterState.BETENOUGH
                    self.m_img_light:setVisible(true)
                    self.m_lb_spin:setVisible(true)
                else -- bet not enough
                    self.m_state = EnterState.BETNOTENOUGH
                    self.m_sp_dark:setVisible(true)
                    self.m_sp_addBet:setVisible(true)
                end
            end
        else --关卡不匹配
            self.m_state = EnterState.CHNAGEGAME
            self.m_sp_dark:setVisible(true)
            self.m_sp_changeGame:setVisible(true)
        end
    else --无活动数据
        self.m_state = EnterState.LOCK
        self.m_img_lock:setVisible(true)
        self.m_lb_Lock:setVisible(true)
    end
    self:runCsbAction("idle")
end

function LuckyChallengeLevelEnter:getLevID()
    local p_id = globalData.slotRunData.machineData.p_id
    local levedata = globalData.slotRunData:getLevelInfoByName(globalData.slotRunData.machineData.p_levelName)
    if levedata then
        p_id = levedata.p_id
    end
    return p_id
end

function LuckyChallengeLevelEnter:updateAfterSpin()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData then
        local tempData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getCurLevelTask(self:getLevID())
        if tempData and #tempData > 0 then
            local newtask = tempData[1]
            if self.m_task and self.m_task:getCompleted() and newtask:getCompleted() and self.m_task:getIndex() ~= newtask:getIndex() then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_BOTTOM_LC_COMPLETE)
                self:playAnim(
                    "toComplete",
                    false,
                    function()
                        if self.m_aniName ~= "complete" then
                            self:playAnim("complete", true)
                        end
                    end
                )
            end
            self.m_task = newtask
            self:setProgress(self:getTaskProcess())
        end
    end
end

function LuckyChallengeLevelEnter:playAnim(name, isLoop, callFun)
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

function LuckyChallengeLevelEnter:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateAfterSpin()
            self:initState()
        end,
        ViewEventType.NOTIFY_GAMEEFFECT_OVER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateAfterSpin()
            self:initState()
        end,
        ViewEventType.NOTIFY_LC_UPDATE_VIEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateAfterSpin()
            self:initState()
            self.m_loadingProgress:setPercentage(self:getTaskProcess())
        end,
        ViewEventType.NOTIFY_NDC_TASK_RED
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initState()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initState()
        end,
        ViewEventType.NOTIFY_LC_LEVELUP_OPEN
    )
end

function LuckyChallengeLevelEnter:getTaskProcess()
    local process = 0
    if self.m_task then
        process = self.m_task:getBaiFenBi()
        process = math.floor(process * 100)
        if process > 100 then
            process = 100
        end
        if self.m_task:getCompleted() then
            process = 100
        end
    end
    return process
end

function LuckyChallengeLevelEnter:checkBetEnough(task)
    local enough = true
    -- if task and #task:getParam() > 0 and globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_betsData then
    --     if task.jump == 1 and task.extra == 1 then
    --         local bet = task.params[#task.params]
    --         local curBet = globalData.slotRunData:getCurTotalBet()
    --         -- local t = string.lower(util_formatCoins(bet,3,nil,true))
    --         local t = util_formatCoins(tonumber(bet), 3, true, nil, true)
    --         if curBet < tonumber(bet) then
    --             enough = false
    --         end
    --     end
    -- end
    return enough
end

--显示倒计时
function LuckyChallengeLevelEnter:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateChallengeSeasonTime), 1)
    self:updateChallengeSeasonTime()
end

function LuckyChallengeLevelEnter:updateChallengeSeasonTime()
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if not luckyChallengeData then
        return
    end

    local leftTime = util_getLeftTime(tonumber(luckyChallengeData.p_expireAt))
    if leftTime <= 0 then
        self:stopTimerAction()
        self:initState()
        self.m_loadingProgress:setPercentage(0)
    end
end

function LuckyChallengeLevelEnter:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end
-- function LuckyChallengeLevelEnter:initSeasonTimer()
--     if globalData.luckyChallengeData and globalData.luckyChallengeData:isOpen() then
--         local leftTime = util_getLeftTime(globalData.luckyChallengeData.expireAt)
--         if leftTime > 0 then
--             performWithDelay(self,function()
--                 self:initState()
--             end,leftTime)
--         end
--     end
-- end

function LuckyChallengeLevelEnter:onExit()
    self:stopTimerAction()
    gLobalNoticManager:removeAllObservers(self)
end

return LuckyChallengeLevelEnter
