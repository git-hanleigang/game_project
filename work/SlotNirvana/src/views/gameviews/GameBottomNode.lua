--
--
-- 游戏中底部UI
local GameBetBarControl = util_require("views.gameviews.GameBetBarControl"):getInstance()
local GameBottomNode = class("GameBottomNode", util_require("base.BaseView"))

GameBottomNode.m_spinBtn = nil
GameBottomNode.m_normalWinLabel = nil -- 小赢label
GameBottomNode.m_winFlyNode = nil
GameBottomNode.m_betValueLabel = nil

-- GameBottomNode.p_tasksImgCollect = nil
GameBottomNode.m_showTipAction = nil
GameBottomNode.m_changeLabJumpTime = nil -- 特殊玩法需要改变数字滚动时间的
GameBottomNode.m_showPopUpUIStates = true

function GameBottomNode:initUI(machine)
    self.m_machine = machine
    self.m_showPopUpUIStates = true
    self.m_spinWinCount = 0
    self.m_addWinCount = 0
    self.m_checkPopUICount = 0
    -- setDefaultTextureType("RGBA8888", nil)

    local deluxeName = ""
    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    if bOpenDeluxe then
        deluxeName = "_1"
    end
    local csbName = "GameNode/GameBottomNode" .. deluxeName .. ".csb"
    if globalData.slotRunData.isPortrait == true then
        csbName = "GameNode/GameBottomNodePortrait" .. deluxeName .. ".csb"
    end
    self:createCsbNode(csbName)

    self.m_changeLabJumpTime = nil

    self.coinWinNode = self:findChild("WinNode_fly")
    self:createCoinWinEffectUI()
    self:createBigWinLabUi()
    self:initMegaWinIcon()

    if globalData.slotRunData.isPortrait then
        local offheight = util_getSaveAreaBottomHeight()
        local mainNode = self:findChild("mainNode")
        mainNode:setPositionY(mainNode:getPositionY() + offheight)
    end

    -- if globalData.slotRunData.isPortrait == true then
    --     self:findChild("Sprite_25"):setVisible(false)
    -- else
    --     self:findChild("Sprite_2"):setVisible(false)
    --     self:findChild("Sprite_2_0"):setVisible(false)
    -- end

    self:runAnim("idle", true)

    self.m_sp_average = self:findChild("m_sp_average")

    self.m_btn_add = self:findChild("btn_add")
    self.m_btn_sub = self:findChild("btn_sub")
    self.m_btn_MaxBet = self:findChild("btn_MaxBet")
    -- globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.newBetAva,self.m_btn_add)
    -- globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.addBet,self.m_btn_add)
    self.m_btn_MaxBet1 = self:findChild("btn_MaxBet_1")

    local spinParent = self:findChild("free_spin_new")
    if spinParent then
        local touchSpinLayer = nil
        if machine then
            touchSpinLayer = machine.m_touchSpinLayer
        end
        self.m_spinBtn = util_createView(self:getSpinUINode(), touchSpinLayer)
        spinParent:addChild(self.m_spinBtn)
        self.m_spinBtn:setGuideScale(self.m_csbNode:getScale())
    end

    globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.noobTaskStart1, spinParent)

    self.m_normalWinLabel = self:findChild("font_last_win_value")
    self.m_winFlyNode = self:findChild("WinNode_fly")
    self.m_betValueLabel = self:findChild("font_total_bet_value")
    self:updateBetEnable(true)
    self:hideAverageBet()

    self.m_betTipsNode = self:findChild("node_bet_tips")
    GameBetBarControl:init(self.m_betTipsNode)

    -- self:addTaskNode()
    self:initWinLizi()

    performWithDelay(
        self,
        function()
            self:updateRightBar()
        end,
        0.1
    )

    self:addFlashEff()
    -- self:updateTopUIBg()

    -- setDefaultTextureType("RGBA4444",nil)

    performWithDelay(
        self,
        function()
            if gLobalAdChallengeManager:isShowMainLayer() then
                gLobalAdChallengeManager:showMainLayer()
            end
        end,
        0.3
    )

end

-- 刷新背景
-- function GameBottomNode:updateTopUIBg()
--     local spNormalBgL = self:findChild("sp_bg")

--     local spDeluxeBgL = self:findChild("sp_dcbg")

--     local bOpenDeluxe = globalData.slotRunData.isDeluexeClub

--     spNormalBgL:setVisible(not bOpenDeluxe)
--     spDeluxeBgL:setVisible(bOpenDeluxe)
-- end

function GameBottomNode:initWinLizi()
    local normalLizi = self:findChild("win_lizi01")
    local deluxeLizi = self:findChild("win_lizi02")
    if not normalLizi or not deluxeLizi then
        return
    end
    if globalData.slotRunData.isDeluexeClub then
        normalLizi:setVisible(false)
        deluxeLizi:setVisible(true)
    else
        normalLizi:setVisible(true)
        deluxeLizi:setVisible(false)
    end
end

--任务相关的添加
function GameBottomNode:addTaskNode(machine)
    self.m_machine = machine

    local missionNode = self:findChild("Node_mission")
    globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.dallyMissionReward, missionNode)

    self.m_taskMix = util_createView("views.gameviews.GameBottomMixNode", self.m_machine)
    missionNode:addChild(self.m_taskMix)

    --事件单独添加
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- params
            if not tolua.isnull(self) and self.taskClickAgent then
                self:taskClickAgent(params)
            end
        end,
        ViewEventType.NOTIFY_BOTTOM_TASKCLICK
    )
    self:initTishi()

    -- setDefaultTextureType("RGBA4444",nil)
end

function GameBottomNode:getWinFlyNode()
    return self:findChild("WinNode_fly")
end

function GameBottomNode:getSpinUINode()
    return "views.gameviews.SpinBtn"
end

function GameBottomNode:initWinFlyNodePos()
    local winFlyNode = self:getWinFlyNode()
    if not winFlyNode then
        return
    end
    local pos = winFlyNode:getParent():convertToWorldSpace(cc.p(winFlyNode:getPosition()))
    globalData.winFlyNodePos = pos
end


function GameBottomNode:showAverageBet()
    self.m_sp_average:setVisible(true)
    self.m_betValueLabel:setVisible(false)
    globalData.slotRunData.m_averageStates = true
end

function GameBottomNode:hideAverageBet()
    self.m_sp_average:setVisible(false)
    self.m_betValueLabel:setVisible(true)
    globalData.slotRunData.m_averageStates = false
end

function GameBottomNode:addFlashEff()
    local flashNode = self:findChild("node_flash")

    if flashNode then
        local csbName = "GameNode/GameBottomFlash.csb"
        if globalData.slotRunData.isPortrait == true then
            csbName = "GameNode/GameBottomPortraitFlash.csb"
        end
        local flash = util_createAnimation(csbName)
        flashNode:addChild(flash)
        flash:playAction("idle", true)
    end
end

function GameBottomNode:firstEnter()
    local curDayTime = util_getymd_format()
    if globalData.custTime == "" or globalData.custTime ~= curDayTime then --当天首次进入关卡
        globalData.custTime = curDayTime
        gLobalSendDataManager:getNetWorkFeature():sendCustTimeUpdate(globalData.custTime)
        return true
    end
    return false
end
function GameBottomNode:initTishi()
    --首次进入先判断要不要弹每日引导
    --如果不用弹 再判读要不要弹小猪银行
    --如果需要弹 在关闭后判断 要不要弹小猪提示
    -- if globalData.userRunData.levelNum >= 10 or globalData.userRunData.levelNum < 80 then  --判断是否弹出每日引导
    --     if self:firstEnter() then
    --         self:openMissionLead()
    --     end
    -- else
    --     if globalData.userRunData.levelNum >= 11 or globalData.userRunData.levelNum < 80 then  --判断是否要弹出小猪提示
    --         if self:firstEnter() then
    --             performWithDelay(self, function()
    --                 gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIGBANK_TISHI)
    --             end, 0.2)
    --         end

    --     end
    -- end
    -- self.m_mission_msg =  self:findChild("mission_msg")
    -- self.m_mission_msg:setVisible(false)

    self:readTipsData()
    self.m_lastTipBetValue = 0
end

function GameBottomNode:updateTasksBar()
    self:setTasksBarPercent(true)
end

function GameBottomNode:setTasksBarPercent(init)
    -- if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION then
    --     return
    -- end
    -- -- 每天的第一次完成任务
    -- local missionData = globalData.missionRunData
    -- if missionData.p_currMissionID == 1 and missionData.p_taskInfo:checkCanCollect() then
    --     local isShowTip  = globalData.missionRunData:checkIsFirstTip()
    --     if isShowTip then
    --         self:missionCompleted(missionData.p_taskInfo)
    --     end
    -- end
end

function GameBottomNode:updateTotalBet(betValue)
    -- 额外消耗bet
    betValue = globalMachineController:calculateBetExtraCost(betValue)
    -- 显示
    self.m_betValueLabel:setString(util_getFromatMoneyStr(betValue))
    if globalData.slotRunData:isMachinePortrait() then -- 用关卡的属性去判断，因为有可能在横版关卡调起竖版的levelrush小游戏
        self:updateLabelSize({label = self.m_betValueLabel, sx = 0.7, sy = 0.7}, 260)
    else
        self:updateLabelSize({label = self.m_betValueLabel, sx = 0.6, sy = 0.6}, 248)
    end
end
function GameBottomNode:updateWinCount(goldCountStr)
    self.m_normalWinLabel:setString(goldCountStr)
    if globalData.slotRunData:isMachinePortrait() then
        self:updateLabelSize({label = self.m_normalWinLabel}, 383)
    else
        self:updateLabelSize({label = self.m_normalWinLabel}, 428)
    end
end

function GameBottomNode:getUISize()
    local spBg = self:findChild("size_for_level")
    local size = spBg:getContentSize()

    local csbScale = self.m_csbNode:getScale()

    return size.width * csbScale, size.height * csbScale
end

function GameBottomNode:getFreeSpinPos()
    local freeNode = self:findChild("free_spin_new")
    local freePos = cc.p(freeNode:getPositionX(), freeNode:getPositionY())
    return freeNode:getParent():convertToWorldSpace(freePos)
end

function GameBottomNode:getSpinBtn()
    return self.m_spinBtn
end

function GameBottomNode:onEnter()
    -- 增加观察者
    self:updateWinCount("")

    self:initMegaWinUI()

    G_GetMgr(G_REF.BetBubbles):onRefreshBubbleDatas()

    if self.m_bCheckShowPopUpUI then
        -- 判断 显示 弹板 (0.5秒后 关卡onEnter后可能还在处理UI, 直接写下一帧执行也可能有问题)
        performWithDelay(
            self,
            function()
                -- 关卡里 特殊逻辑已经调用过 updateBetEnable 监测过弹板了，不要重复检测
                if self.m_checkPopUICount > 0 then
                    return
                end
                globalMachineController:checkShowPopUpUI(self.m_machine)
            end,
            0.5
        )
    end

    -- 更新赢钱动画
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            print("同步消息 " .. params[1])
            self:notifyUpdateWinLabel(params[1], params[2], params[3], params[4])
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    --显示特殊玩法赢钱动画eg. 樱桃 respin

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            local effect, act = util_csbCreate("ui_dikuang_zhongjiang.csb")
            util_csbPlayForKey(
                act,
                "actionframe",
                false,
                function()
                    effect:removeFromParent(true)
                end
            )
            effect:setPosition(self.m_normalWinLabel:getPositionX(), self.m_normalWinLabel:getPositionY())
            self.m_normalWinLabel:getParent():addChild(effect)
            self:updateWinCount(util_getFromatMoneyStr(params))
        end,
        ViewEventType.NOTIFY_UPDATE_SPECIAL_WINCOIN
    )

    -- 通知停止赢钱变化 , 一般用于win coin 变化时 点击了spin按钮
    gLobalNoticManager:addObserver(
        self,
        function(self, isClearWinArea)
            if self.m_isUpdateTopUI == true then
                -- 表明有钱的变化，
                self:notifyTopWinCoin()
                self:resetWinLabel()
                self.m_spinWinCount = 0
            else
                self:resetWinLabel()
            end

            if isClearWinArea == nil or isClearWinArea == true then
                -- 赢钱区域钱数清空， 一般用于有钱变化时 或者 freespin 结束时
                self.m_addWinCount = 0
                scheduler.performWithDelayGlobal(
                    function()
                        self:checkClearWinLabel()
                    end,
                    0.5,
                    "GameBottomNode"
                )
            end
        end,
        ViewEventType.NOTIFY_STOP_WINCOIN
    )

    -- 更新bet 值
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新bet 值
            self:updateBetCoin()
            self:playBetMaxEffect()
            if self.m_lastTipBetValue == 0 then
                self.m_lastTipBetValue = globalData.slotRunData:getCurTotalBet()
            end
        end,
        ViewEventType.NOTIFY_UPDATE_BETIDX
    )

    -- 只更新bet值
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local betValue = globalData.slotRunData:getCurTotalBet()
            self:updateTotalBet(betValue)
        end,
        ViewEventType.NOTIFY_UPDATE_BETCOIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            self:updateBetEnable(params)
        end,
        "BET_ENABLE"
    )

    -- 更新进度条
    -- gLobalNoticManager:addObserver(self,function(self,params)   -- 更新每日任务进度条
    --     self:setTasksBarPercent(params)
    -- end,ViewEventType.NOTIFY_UPDATE_BAR)

    -- 有新的任务提示
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新每日任务进度条
            self:addNewMissionTips(params)
        end,
        ViewEventType.NOTIFY_DAILYPASS_REFRESH_TIPS
    )

    -- 更新进度条
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 可以弹出每日任务引导
            self.closeMissionLeadFunc = params
            self:openMissionLead()
        end,
        ViewEventType.NOTIFY_MISSION_LEAD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            if globalData.slotRunData.iLastBetIdx then
                if globalData.slotRunData:checkCurBetIsMaxbet() then --最大BET
                    if self.m_btn_MaxBet then
                        -- self.m_btn_MaxBet:setBright(false)
                        -- self.m_btn_MaxBet:setTouchEnabled(false)
                        self.m_btn_MaxBet:setVisible(false)
                    end
                    if self.m_btn_MaxBet1 then
                        self.m_btn_MaxBet1:setVisible(true)
                    end
                else
                    if self.m_btn_MaxBet then
                        -- self.m_btn_MaxBet:setBright(true)
                        -- self.m_btn_MaxBet:setTouchEnabled(true)
                        self.m_btn_MaxBet:setVisible(true)
                    end
                    if self.m_btn_MaxBet1 then
                        self.m_btn_MaxBet1:setVisible(false)
                    end
                end
            end
            self:updateBetCoin(true)
            self:playBetMaxEffect()
        end,
        ViewEventType.NOTIFY_GAME_SPIN_MAX_BET
    )

    -- gLobalNoticManager:addObserver(self,function(Target, params)
    --     Target:initSaleNode()
    -- end,ViewEventType.NOTIFY_UPDATE_SALE_GAMENODE)

    --升级消息
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateRightBar()
            self:checkClearAllTipsData()
        end,
        ViewEventType.SHOW_LEVEL_UP
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            performWithDelay(
                self,
                function()
                    self:updateRightBar()
                end,
                0.1
            )
        end,
        ViewEventType.NOTIFY_ACTIVITY_FIND_GOSPIN
    )

    --加buff刷新
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateRightBar()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateRightBar()
        end,
        ViewEventType.NOTIFY_REFRESH_GAMEBOTTOM_BUFF
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRightBar()
        end,
        "ads_vedio"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRightBar()
        end,
        "hide_vedio_icon"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRightBar()
        end,
        ViewEventType.NOTIFY_LEVELROAD_SALE_END
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateRightBar()
        end,
        ViewEventType.NOTIFY_REFRESH_BROKENSALE_BUFF
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            --记录spin次数
            if params and params[1] == true then
                local spinData = params[2]
                if spinData ~= nil then
                    self:checkShowSpinBaseTips()
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
    --引导提示
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 可以弹出每日任务引导
            if params == GUIDE_LEVEL_POP.AddBet then --- max bet
                local path = "AddBetPortrait.csb"
                if globalData.slotRunData.isPortrait == true then
                    path = "AddBet.csb"
                end

                local size = self.m_btn_MaxBet:getContentSize()
                local pos = self.m_btn_MaxBet:getParent():convertToWorldSpace(cc.p(self.m_btn_MaxBet:getPositionX(), self.m_btn_MaxBet:getPositionY() + size.height / 2))
                globalNoviceGuideManager:addNewPop(GUIDE_LEVEL_POP.AddBet, pos, path)
                if globalFireBaseManager.sendFireBaseLogDirect then
                    globalFireBaseManager:sendFireBaseLogDirect("guideBubbleMaxBetPopup", false)
                end
                globalNoviceGuideManager.guideBubbleMaxBetPopup = true
            elseif params == GUIDE_LEVEL_POP.MaxBet then -- addbet
                local path = "NewBets.csb"
                if globalData.slotRunData.isPortrait == true then
                    path = "NewBetsPortrait.csb"
                end
                local size = self.m_btn_add:getContentSize()
                local pos = self.m_btn_add:getParent():convertToWorldSpace(cc.p(self.m_btn_add:getPositionX(), self.m_btn_add:getPositionY() + size.height / 2))
                globalNoviceGuideManager:addNewPop(GUIDE_LEVEL_POP.MaxBet, pos, path)

                if globalFireBaseManager.sendFireBaseLogDirect then
                    globalFireBaseManager:sendFireBaseLogDirect("guideBubbleAddBetPopup", false)
                end

                -- 引导打点：bet提醒-1.bet提升显示
                gLobalSendDataManager:getLogGuide():setGuideParams(4, {isForce = false, isRepeat = false, guideId = nil})
                gLobalSendDataManager:getLogGuide():sendGuideLog(4, 1)

                globalNoviceGuideManager.guideBubbleAddBetPopup = true
            elseif params == GUIDE_LEVEL_POP.BetUpNotice then
                -- spin 升级后 bet值小于指定bet 弹出气泡
                local size = self.m_btn_add:getContentSize()
                local pos = self.m_btn_add:getParent():convertToWorldSpace(cc.p(self.m_btn_add:getPositionX(), self.m_btn_add:getPositionY() + size.height / 2))
                G_GetMgr(G_REF.BetUpNotice):showBetUpNoticeBubbleUI(pos)
            end
        end,
        ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE
    )

    -- 清除LOG_GUIDE中非强制性引导的后续打点
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.guideIndex == 4 then
                -- 非强制性引导【bet提升】，玩家如果拒绝了后续不打点
                if gLobalSendDataManager:getLogGuide():isGuideBegan(4) then
                    gLobalSendDataManager:getLogGuide():cleanParams(4)
                end
            end
            if params and params.guideIndex == 7 then
                -- 非强制性引导【每日任务完成提示】，玩家如果拒绝了后续不打点
                if gLobalSendDataManager:getLogGuide():isGuideBegan(7) then
                    gLobalSendDataManager:getLogGuide():cleanParams(7)
                end
            end
        end,
        ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE
    )

    --maxbet引导
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.checkPlayMaxBetEff then
                self:checkPlayMaxBetEff()
            end
        end,
        ViewEventType.NOTIFY_GUIDE_MAXBET_EFF
    )
    -- free spin 大赢
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
            if FBSignRewardManager then
                FBSignRewardManager:getInstance():setOpenGroupState()
            end
        end,
        ViewEventType.NOTIFY_FREESPIN_OVER_BIGWIN
    )
    -- respin 大赢
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
            if FBSignRewardManager then
                FBSignRewardManager:getInstance():setOpenGroupState()
            end
        end,
        ViewEventType.NOTIFY_RESPIN_OVER_BIGWIN
    )
    -- freespin结束
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if gLobalAdChallengeManager:isAdsFreeSpin() then
                gLobalAdChallengeManager:setAdsFreeSpin(false)
                if gLobalAdChallengeManager:isShowMainLayer() then
                    gLobalAdChallengeManager:showMainLayer()
                end
            end
        end,
        ViewEventType.REWARD_FREE_SPIN_OVER
    )

    -- minz 开关切换
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新bet 值
            if params and params == "off" then
                self:playMinzBetEffectNode()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_MINZ_SWITCH_ONOFF
    )

    -- DiyFeature 开关切换
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新bet 值
            if params and params == "off" then
                self:playDiyFeatureBetEffectNode()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DIYFEATURE_SWITCH_ONOFF
    )

    -- 玩家手动操作开关
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if G_GetMgr(G_REF.BetExtraCosts):isExtraRef(params.name) then
                -- 刷新bet
                local betValue = globalData.slotRunData:getCurTotalBet()
                self:updateTotalBet(betValue)
                -- 刷新betTips
                GameBetBarControl:updateShowBetTips()
            end
        end,
        ViewEventType.NOTIFI_BET_EXTRA_COST_SWITCH
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if G_GetMgr(G_REF.BetExtraCosts):isExtraRef(params.name) then
                -- 刷新bet
                local betValue = globalData.slotRunData:getCurTotalBet()
                self:updateTotalBet(betValue)
                -- -- 刷新betTips
                -- GameBetBarControl:updateShowBetTips()
            end
            if params.name == ACTIVITY_REF.MegaWinParty then
                self:afterMegaWinOver()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 触发宠物bet加成
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:checkSidekicksBet()
        end,
        ViewEventType.NOTIFY_SIDEKICKS_EXTRA_BET
    )
end

function GameBottomNode:onEnterFinish()
    self:initWinFlyNodePos()
end

function GameBottomNode:openMissionLead()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_DailyQuest)
    end

    local Node_mission = self:findChild("Node_mission")
    if Node_mission then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_BOTTOM_FORCE_SWITCH, 1)
        self.m_guideMissionNode = util_createView("views.newbieTask.GuideNewDailyMission")
        Node_mission:addChild(self.m_guideMissionNode)
        self.m_guideMissionNode:setPosition(0, 50)
        gLobalViewManager:addAutoCloseTips(
            self.m_guideMissionNode,
            function()
                if self.m_guideMissionNode then
                    self.m_guideMissionNode:hide(
                        function()
                            self.m_guideMissionNode = nil
                        end
                    )
                end
            end
        )
    end
    if self.closeMissionLeadFunc then
        self.closeMissionLeadFunc()
        self.closeMissionLeadFunc = nil
    end
end

function GameBottomNode:onExit()
    GameBottomNode.super.onExit(self)

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    self:stopUpDateBigWinLab()

    if self.m_normalWinCoinSoundTag ~= nil then
        gLobalSoundManager:stopEffectMusic(self.m_normalWinCoinSoundTag)
        self.m_normalWinCoinSoundTag = nil
    end

    -- if self.m_clearHandlerID ~= nil  then
    --     scheduler.unscheduleGlobal(self.m_clearHandlerID)
    --     self.m_clearHandlerID = nil
    -- end

    scheduler.unschedulesByTargetName("GameBottomNode")
    self:saveTipsData()

    GameBetBarControl:clearBets()
end

-- 打开FindbetTips
function GameBottomNode:showBetTipsView()
end

function GameBottomNode:saveTipsData()
    local toDayTime = util_getymd_format()
    gLobalDataManager:setNumberByField(toDayTime .. "bet_tipsBetCount", self.m_tipsBetCount)
    gLobalDataManager:setNumberByField(toDayTime .. "bet_tipsSpinCount", self.m_tipsSpinCount)
    gLobalDataManager:setNumberByField(toDayTime .. "bet_spinCount", self.m_spinCount)
end

function GameBottomNode:readTipsData()
    local toDayTime = util_getymd_format()
    self.m_tipsBetCount = gLobalDataManager:getNumberByField(toDayTime .. "bet_tipsBetCount", 0)
    self.m_tipsSpinCount = gLobalDataManager:getNumberByField(toDayTime .. "bet_tipsSpinCount", 0)
    self.m_spinCount = gLobalDataManager:getNumberByField(toDayTime .. "bet_spinCount", 0)
end

function GameBottomNode:checkClearAllTipsData()
    if not globalData.slotRunData.machineData then
        return
    end
    local machineData = globalData.slotRunData.machineData
    local machineCurBetList = machineData:getMachineCurBetList()
    local betData = machineCurBetList[#machineCurBetList]
    if betData.p_unlockAt == globalData.userRunData.levelNum then
        self:clearAllTipsData()
    end
end
function GameBottomNode:clearAllTipsData()
    self.m_tipsBetCount = 0
    self.m_tipsSpinCount = 0
    self.m_spinCount = 0
    self:saveTipsData()
end
function GameBottomNode:clearSpinTipsData()
    self.m_spinCount = 0
    self:saveTipsData()
end
function GameBottomNode:clearCountData()
    self.m_tipsBetCount = 0
    self.m_tipsSpinCount = 0
    self:saveTipsData()
end
--调整bet时是否显示
function GameBottomNode:checkShowBaseTips()
    self.m_spinCount = 0
    local curBetValue = globalData.slotRunData:getCurTotalBet()
    if not self.m_showBaseBetTips then
        if self.m_selectBetValue and self.m_selectBetValue >= curBetValue then
            return
        end
        self.m_selectBetValue = nil
        -- if curBetValue < globalData.userRunData.coinNum * 0.002 then
        if toLongNumber(curBetValue * 500) < globalData.userRunData.coinNum then
            if self.m_lastTipBetValue and self.m_lastTipBetValue > curBetValue and (self.m_tipsBetCount or 0) < 2 then
                self.m_tipsBetCount = (self.m_tipsBetCount or 0) + 1
                self.m_lastTipBetValue = curBetValue
                self.m_selectBetValue = curBetValue
                self:saveTipsData()
                -- self:showBaseBetTipsView()
            end
        end
    end
    self.m_lastTipBetValue = curBetValue
end

--spin
function GameBottomNode:checkShowSpinBaseTips()
    local curBetValue = globalData.slotRunData:getCurTotalBet()
    -- if curBetValue < globalData.userRunData.coinNum * 0.002 then
    if globalData.userRunData.coinNum > toLongNumber(curBetValue * 500) then
        self.m_spinCount = self.m_spinCount + 1
        if self.m_spinCount >= 50 and self.m_tipsSpinCount < 2 then
            self.m_tipsSpinCount = self.m_tipsSpinCount + 1
            self.m_spinCount = 0
            self:saveTipsData()
            -- self:showBaseBetTipsView()
        end
    end
end

-- --打开系统betTips
-- function GameBottomNode:showBaseBetTipsView()
--     if self.m_baseBetTipNode == nil then
--         return
--     end
--     if not self.m_showBaseBetTips then
--         self.m_showBaseBetTips = true
--         self.m_baseBetTipNode:showBetTips(
--             function()
--                 --3s自动消失
--                 performWithDelay(
--                     self,
--                     function()
--                         self.m_baseBetTipNode:hideBetTips(
--                             function()
--                                 self.m_showBaseBetTips = false
--                             end
--                         )
--                     end,
--                     3
--                 )
--             end
--         )
--     end
-- end

function GameBottomNode:clickFunc(sender)
    local senderName = sender:getName()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_PIG_TIPS)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 5})
    if "btn_add" ~= senderName then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 4})
    end

    if "btn_add" == senderName then
        globalData.slotRunData.machineData:updateSpecNewBetsData() -- 当有特殊bet需要刷新时，在玩家切换bet前刷新
        self:addBetCoinNum()
        self:checkShowBaseTips()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE)
        gLobalSendDataManager:getLogSlots():setGameBet()
        --【如何保证此消息的唯一性】
        -- 引导打点：bet提升-2.bet点击
        if gLobalSendDataManager:getLogGuide():isGuideBegan(4) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(4, 2)
        end
        G_GetMgr(G_REF.BetUpNotice):removeBetUpNoticeBubbleUI()
    elseif "btn_sub" == senderName then
        globalData.slotRunData.machineData:updateSpecNewBetsData() -- 当有特殊bet需要刷新时，在玩家切换bet前刷新
        self:subBetCoinNum()
        self:checkShowBaseTips()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE) 
        gLobalSendDataManager:getLogSlots():setGameBet()
        G_GetMgr(G_REF.BetUpNotice):removeBetUpNoticeBubbleUI()
    elseif "btn_MaxBet" == senderName or "btn_MaxBet1" == senderName then
        if globalData.slotRunData:checkCurBetIsMaxbet() then --最大BET
            return
        end
        globalData.slotRunData.machineData:updateSpecNewBetsData() -- 当有特殊bet需要刷新时，在玩家切换bet前刷新
        self:maxBetCoinNum()
        self:checkShowBaseTips()

        self:playBetAddEffect("add")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BET_CHANGE) 
        gLobalSendDataManager:getLogSlots():setMaxBet()
        G_GetMgr(G_REF.BetUpNotice):removeBetUpNoticeBubbleUI()
    elseif "btn_help" == senderName then
        -- 打开游戏界面
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        self:showPayTableView()
    elseif "btn_Minz" == senderName then
        if GameBetBarControl and GameBetBarControl.clickBtnBetBarFunc then
            GameBetBarControl:clickBtnBetBarFunc()
        end
    elseif "panel_chestList" == senderName then
        local bOpen = G_GetMgr(ACTIVITY_REF.MegaWinParty):isCanShowLayer()
        if bOpen then
            if self.m_MegaWinPartyNode then
                self.m_MegaWinPartyNode:doShowOrHide()
            end
        end 
    end
end
function GameBottomNode:updateBetEnable(flag)
    local showPopUpUIFlag = nil
    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE and flag == true then
        showPopUpUIFlag = true
    end
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag = false
    end
    if showPopUpUIFlag == nil then
        showPopUpUIFlag = flag
    end

    if not self.m_showPopUpUIStates then
        showPopUpUIFlag = false
    end
    --test 特殊需求可以调整bet
    -- if DEBUG == 2 then
    --     flag = true
    -- end
    globalData.betFlag = flag
    self.m_btn_add:setBright(flag)
    self.m_btn_add:setTouchEnabled(flag)
    self.m_btn_sub:setBright(flag)
    self.m_btn_sub:setTouchEnabled(flag)

    self.m_btn_MaxBet:setBright(flag)
    self.m_btn_MaxBet:setTouchEnabled(flag)
    self.m_btn_MaxBet1:setBright(flag)
    self.m_btn_MaxBet1:setTouchEnabled(flag)

    if showPopUpUIFlag and self.m_bCheckShowPopUpUI then
        self.m_checkPopUICount = self.m_checkPopUICount + 1
        globalMachineController:checkShowPopUpUI(self.m_machine)
    end
    -- cxc 第一次 放到onEnter中执行
    self.m_bCheckShowPopUpUI = true

    return flag
end
--------------------  更新bet 信息   -------------------------
function GameBottomNode:updateBetCoin(isLevelUp, isSkipSound)
    -- local betIdex =  globalTestDataManager:getBetIndex()

    -- if betIdex then
    --     globalData.slotRunData.iLastBetIdx = betIdex
    -- end

    if globalData.slotRunData.iLastBetIdx ~= nil then
        if isLevelUp then
        else
            if globalData.slotRunData:checkCurBetIsMaxbet() then --最大BET
                if self.m_btn_MaxBet then
                    -- self.m_btn_MaxBet:setBright(false)
                    -- self.m_btn_MaxBet:setTouchEnabled(false)
                    self.m_btn_MaxBet:setVisible(false)
                end
                if self.m_btn_MaxBet1 then
                    self.m_btn_MaxBet1:setVisible(true)
                end
                self:runAnim(
                    "bet_guang",
                    false,
                    function()
                        self:runAnim("idle", true)
                        self:updateTasksBar()
                    end
                )

                --特效
                if self.m_maxBetEff then
                    self.m_maxBetEff:removeFromParent()
                    self.m_maxBetEff = nil
                end
            else
                if self.m_btn_MaxBet then
                    -- self.m_btn_MaxBet:setBright(true)
                    -- self.m_btn_MaxBet:setTouchEnabled(true)
                    self.m_btn_MaxBet:setVisible(true)
                end
                if self.m_btn_MaxBet1 then
                    self.m_btn_MaxBet1:setVisible(false)
                end
            end
        end
        local betValue = globalData.slotRunData:getCurTotalBet()
        globalData.nowBetValue = betValue
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BET_CHANGE, {p_isLevelUp = isLevelUp})
        GameBetBarControl:changeBet(betValue)
        self:updateTotalBet(betValue)
        
    end
    if DEBUG == 2 then
        local function creatBmt(name)
            local bmtLabel = ccui.TextBMFont:create()
            bmtLabel:setFntFile("Common/font_white.fnt")
            bmtLabel:setString("")
            bmtLabel:setName(name)
            bmtLabel:setScale(0.5)
            bmtLabel:setAnchorPoint(1, 0.5)
            return bmtLabel
        end
        if not self.m_betIndexLabel then
            self.m_betIndexLabel = creatBmt("betIndexLabel")
            self.m_betIndexLabel:setPosition(-250, 100)
            self:addChild(self.m_betIndexLabel, 1)
        end
        self.m_betIndexLabel:setString("betIndex=" .. globalData.slotRunData:getCurBetIndex())
    end
end

---
-- 增加堵住筹码
function GameBottomNode:addBetCoinNum()
    local lastBetIdx = globalData.slotRunData.iLastBetIdx
    local betData = globalData.slotRunData:getBetDataByIdx(globalData.slotRunData.iLastBetIdx, 1)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("add", lastBetIdx)
    self:updateBetCoin()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AdjustBetBig)
    end
    globalNoviceGuideManager:removeNewPop(GUIDE_LEVEL_POP.MaxBet)
    if globalNoviceGuideManager.guideBubbleAddBetPopup then
        globalNoviceGuideManager.guideBubbleAddBetPopup = nil
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("guideBubbleAddBetClick", false)
        end
    end

    self:playBetAddEffect("add")
end

function GameBottomNode:getEffectNode()
    if not tolua.isnull(self.add_effect) then
        return self.add_effect
    end
    local ef_node = self:findChild("ef_sao")
    if tolua.isnull(ef_node) then
        return
    end
    local add_effect
    if globalData.slotRunData.isPortrait == true then
        add_effect = util_createAnimation("GameNode/GameBottomNodePortrai_saosu.csb")
    else
        add_effect = util_createAnimation("GameNode/GameBottomNode_saohen.csb")
    end
    if not tolua.isnull(add_effect) then
        add_effect:addTo(ef_node)
        local node_jin = add_effect:findChild("jin")
        if not tolua.isnull(node_jin) then
            node_jin:setVisible(globalData.slotRunData.isDeluexeClub)
        end
        local node_lan = add_effect:findChild("lan")
        if not tolua.isnull(node_lan) then
            node_lan:setVisible(not globalData.slotRunData.isDeluexeClub)
        end
        self.add_effect = add_effect
    end
    return add_effect
end

function GameBottomNode:playBetAddEffect(_type)
    self:playBetChangeSound()
    if _type == "sub" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            self:showMax()
        else
            local add_effect = self:getEffectNode()
            if not tolua.isnull(add_effect) then
                add_effect:setVisible(false)
            end
        end
    elseif _type == "add" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            self:showMax()
        else
            local cur_idx = globalData.slotRunData:getCurBetIndex()
            if cur_idx and cur_idx > 1 then
                self:showAdd()
            else
                local add_effect = self:getEffectNode()
                if not tolua.isnull(add_effect) then
                    add_effect:setVisible(false)
                end
            end
        end
    end
end

function GameBottomNode:showMax()
    local max_effect = self:getMaxEffectNode()
    if not tolua.isnull(max_effect) then
        max_effect:setVisible(true)
        max_effect:runCsbAction(
            "bet_guang2",
            false,
            function()
                max_effect:setVisible(false)
            end,
            60
        )
    end
    local add_effect = self:getEffectNode()
    if not tolua.isnull(add_effect) then
        add_effect:setVisible(true)
        add_effect:runCsbAction(
            "bet_guang2",
            false,
            function()
                self:playBetMaxEffect()
            end,
            60
        )
    end
end

function GameBottomNode:showAdd()
    local add_effect = self:getEffectNode()
    if not tolua.isnull(add_effect) then
        add_effect:setVisible(true)
        add_effect:runCsbAction(
            "gift_full",
            false,
            function()
                add_effect:setVisible(false)
            end,
            60
        )
    end
end

function GameBottomNode:getMaxEffectNode()
    if not tolua.isnull(self.max_effect) then
        return self.max_effect
    end
    local ef_node = self:findChild("ef_baoguan")
    if tolua.isnull(ef_node) then
        return
    end

    local max_effect = util_createAnimation("GameNode/GameBottomNode_bao.csb")
    if not tolua.isnull(max_effect) then
        max_effect:addTo(ef_node)
        self.max_effect = max_effect
    end
    return max_effect
end

function GameBottomNode:playBetMaxEffect()
    if globalData.slotRunData:checkCurBetIsMaxbet() then
        local add_effect = self:getEffectNode()
        if not tolua.isnull(add_effect) then
            add_effect:setVisible(true)
            add_effect:runCsbAction("max_idle", true, nil, 60)
        end
    else
        local add_effect = self:getEffectNode()
        if not tolua.isnull(add_effect) then
            add_effect:setVisible(false)
        end
    end
end

-- 切换minz开关 播放的特效
function GameBottomNode:getMinzBetEffectNode()
    if not tolua.isnull(self.minz_bet_effect) then
        return self.minz_bet_effect
    end
    local ef_node = self:findChild("ef_baoguan")
    if tolua.isnull(ef_node) then
        return
    end

    local csbName = "GameNode/GameBottomNode_bet_down.csb"
    if globalData.slotRunData.isPortrait == true then
        csbName = "GameNode/GameBottomNode_bet_down_shu.csb"
    end
    local minz_bet_effect = util_createAnimation(csbName)
    if not tolua.isnull(minz_bet_effect) then
        minz_bet_effect:addTo(ef_node)
        self.minz_bet_effect = minz_bet_effect
    end
    return minz_bet_effect
end

function GameBottomNode:playMinzBetEffectNode()
    local minz_bet_effect = self:getMinzBetEffectNode()
    if not tolua.isnull(minz_bet_effect) then
        minz_bet_effect:setVisible(true)
        minz_bet_effect:runCsbAction("start", false, function()
            minz_bet_effect:setVisible(false)
        end, 60)
    end
end

function GameBottomNode:playDiyFeatureBetEffectNode()
    
end

function GameBottomNode:playBetChangeSound()
    if globalData.slotRunData:checkCurBetIsMaxbet() then
        gLobalSoundManager:playSound("GameNode/sound/BetChangeMax.mp3")
    else
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        if not betList then
            return
        end
        local counts = table.nums(betList)
        if counts <= 0 then
            return
        end

        -- 总共11个音效 bet列表超过音效数量以后 前面n个音效1 之后顺序排
        local cur_idx = globalData.slotRunData:getCurBetIndex()
        if counts <= 11 then
            gLobalSoundManager:playSound("GameNode/sound/BetChange" .. cur_idx .. ".mp3")
        else
            local change_betIdx = counts - 11
            if cur_idx <= change_betIdx + 1 then
                gLobalSoundManager:playSound("GameNode/sound/BetChange1.mp3")
            else
                local idx = cur_idx - change_betIdx
                gLobalSoundManager:playSound("GameNode/sound/BetChange" .. idx .. ".mp3")
            end
        end
    end
end

---
-- 减少赌注筹码
function GameBottomNode:subBetCoinNum()
    local betData = globalData.slotRunData:getBetDataByIdx(globalData.slotRunData.iLastBetIdx, -1)
    globalData.slotRunData.iLastBetIdx = betData.p_betId
    self:postPiggy("sub")
    self:updateBetCoin()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AdjustBetSmall)
    end
    self:playBetAddEffect("sub")
end
function GameBottomNode:maxBetCoinNum()
    if globalData.slotRunData.iLastBetIdx == nil then
        globalData.slotRunData.iLastBetIdx = 1
    end
    local maxBetData = globalData.slotRunData:getMaxBetData()
    globalData.slotRunData.iLastBetIdx = maxBetData.p_betId
    self:postPiggy("max")
    self:updateBetCoin()
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AdjustBetBig)
    end
    globalNoviceGuideManager:removeNewPop(GUIDE_LEVEL_POP.MaxBet)

    if globalNoviceGuideManager.guideBubbleMaxBetPopup then
        globalNoviceGuideManager.guideBubbleMaxBetPopup = nil
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("guideBubbleMaxBetClick", false)
        end
    end
    -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_MaxBet})
end

----------------  处理赢钱动画变化  ------------------
function GameBottomNode:resetWinLabel()
    if self.m_updateCoinHandlerID ~= nil then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    self.m_isUpdateTopUI = false
end

---
-- 通知top ui 赢钱区域的显示
--
function GameBottomNode:notifyTopWinCoin()
    local curTotalCoin = globalData.userRunData.coinNum
    globalData.coinsSoundType = 1
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, curTotalCoin)
    -- local addWinCoins = self.m_spinWinCount - self.m_addWinCount
    -- if addWinCoins > 0 then
    --     self.m_addWinCount = self.m_addWinCount + addWinCoins
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {varCoins = addWinCoins, isPlayEffect = true})
    -- end
end

function GameBottomNode:checkClearWinLabel()
    self:updateWinCount("")

    -- self.m_clearHandlerID = scheduler.performWithDelayGlobal(function()
    --     self.m_clearHandlerID = nil
    --     self:updateWinCount("")
    -- end, 1 , "GameBottomNode")
end

function GameBottomNode:getCoinsShowTimes(winCoin)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    -- 大数除法没有浮点数，所以除之前要 * 100
    local _rate = (toLongNumber(winCoin) * 100) / totalBet
    -- LongNumber转number，必须保证不越界
    local winRate = tonumber("" .. _rate) / 100
    local showTime = 2
    if winRate <= 1 then
        showTime = 1
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 3
    end

    return showTime
end

---
-- wincoin 是本次赢取了多少钱
-- @param 第三个参数，用来处理显示赢钱时 不需要播放数字变化动画
--
function GameBottomNode:notifyUpdateWinLabel(winCoin, isUpdateTopUI, isPlayAnim, beiginCoins)
    local updateComplete = function()
        if self.m_isUpdateTopUI == true then
            -- self.m_addWinCount = 0
            self:notifyTopWinCoin()
            self:resetWinLabel()
            self:checkClearWinLabel()
            self.m_spinWinCount = 0
        else
            self:resetWinLabel()
        end
    end
    updateComplete()
    -- self:resetWinLabel()
    self.m_isUpdateTopUI = isUpdateTopUI

    if globalData.slotRunData.lastWinCoin ~= 0 then
        self.m_spinWinCount = globalData.slotRunData.lastWinCoin
    else
        self.m_spinWinCount = winCoin
    end

    if self.m_spinWinCount == 0 then
        return
    end
    -- if self.m_clearHandlerID ~= nil  then
    --     scheduler.unscheduleGlobal(self.m_clearHandlerID)
    --     self.m_clearHandlerID = nil
    -- end

    -- local function updateComplete()
    --     if self.m_isUpdateTopUI == true then
    --         self:notifyTopWinCoin()
    --         self:resetWinLabel()
    --         self:checkClearWinLabel()
    --     else
    --         self:resetWinLabel()
    --     end
    -- end

    if isPlayAnim == false then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))

        updateComplete()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE, 1)
        return
    end

    local showTime = self:getCoinsShowTimes(winCoin)

    local changeTims = self:getChangeJumpTime() -- 特殊逻辑
    showTime = changeTims or showTime

    local coinRiseNum = toLongNumber(winCoin * (1 / (showTime * 60))) -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum:setNum(str)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AUTO_SPIN_DELAY_TIME, showTime)

    -- coinRiseNum = math.floor(coinRiseNum)

    local curSpinCount = toLongNumber(0)

    if globalData.slotRunData.lastWinCoin ~= 0 then
        curSpinCount:setNum(globalData.slotRunData.lastWinCoin - winCoin)
    -- else
    --     curSpinCount = 0
    end

    if curSpinCount == toLongNumber(0) then
        if beiginCoins then
            curSpinCount:setNum(beiginCoins)
        end
    end

    local spinWinCount = self.m_spinWinCount
    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curSpinCount = curSpinCount + coinRiseNum

            if toLongNumber(curSpinCount) >= toLongNumber(spinWinCount) then
                curSpinCount:setNum(spinWinCount)
                updateComplete()
                self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE, 0.5)
            else
                self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
            end
        end
    )
end

function GameBottomNode:getChangeJumpTime()
    return self.m_changeLabJumpTime
end

function GameBottomNode:showPayTableView()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAYTABLEVIEW_OPEN)
end

-- 是否是minz关卡
function GameBottomNode:isMinzLevel()
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr then
        return minzMgr:isMinzLevel()
    end
    return false
end

-- 是否是DiyFeature 触发关卡
function GameBottomNode:isDiyFeatureLevel()
    local diyFeatureMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    if diyFeatureMgr then
        return diyFeatureMgr:isDiyFeatureLevel()
    end
    return false
end

--活动节点
function GameBottomNode:updateRightBar()
    if self:isMinzLevel() then
        return
    end
    if self:isDiyFeatureLevel() then
        return
    end

    local missNode = self:findChild("Node_activity")
    local machineNode = gLobalViewManager:getViewLayer():getParent()
    local worldPos = missNode:getParent():convertToWorldSpace(cc.p(missNode:getPosition()))
    if machineNode then
        self.m_rightFrame = machineNode:getChildByName("GameRightFrame")
        if self.m_rightFrame == nil then
            local luaPath = "views.leftFrame.RightFrameLayer_h"
            local zOrder = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM
            if globalData.slotRunData.isPortrait == true then
                luaPath = "views.leftFrame.RightFrameLayer_p"
                zOrder = GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
            end
            self.m_rightFrame = util_createView(luaPath, worldPos)
            self.m_rightFrame:setName("GameRightFrame")
            machineNode:addChild(self.m_rightFrame, zOrder)
        else
            self.m_rightFrame:updateNode()
        end
    end
end

function GameBottomNode:postPiggy(type, lastBetIdx)
    if type == "add" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        elseif self:checkBetIsMaxbet(lastBetIdx) then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "add"})
        end
    elseif type == "max" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
    elseif type == "sub" then
        if globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "max"})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE, {type = "sub"})
        end
    end
end

--[[
    @desc: 检测bet是否是最大bet
    author:{author}
    time:2019-09-27 22:59:03
    @return:
]]
function GameBottomNode:checkBetIsMaxbet(betIdx)
    local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()

    if machineCurBetList == nil or #machineCurBetList == 0 then
        return true
    end

    local betData = machineCurBetList[#machineCurBetList]
    if betData.p_betId == betIdx then
        return true
    end
    return false
end

function GameBottomNode:runAnim(animation, isLoop, func)
    self:runCsbAction(animation, isLoop, func, 60)
end

function GameBottomNode:missionCompleted(taskInfo)
    -- 引导打点：每日任务完成提示-1.每日任务完成提示显示
    local info = NOVICEGUIDE_ORDER.dallyMissionReward
    local taskData = globalData.missionRunData.p_taskInfo
    if taskData then
        gLobalSendDataManager:getLogGuide():setGuideParams(
            7,
            {
                guideId = info.id,
                isForce = info.force,
                isRepeat = info.repetition,
                taskId = taskData and taskData.p_taskId
            }
        )
        gLobalSendDataManager:getLogGuide():sendGuideLog(7, 1)
    end
    self:runAnim(
        "tishi_show",
        false,
        function()
        end
    )

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_BOTTOM_FORCE_SWITCH, 1)

    if self.m_showTipAction ~= nil then
        self:stopAction(self.m_showTipAction)
        self.m_showTipAction = nil
    end
    self.m_showTipAction =
        performWithDelay(
        self,
        function()
            self:runAnim("idle", true)
            -- self:runAnim("tishi_over", false, function()
            --     if self.m_bIsClickMission == true then
            --         return
            --     end
            --     self:runAnim("gift_full", true)
            -- end)
        end,
        4
    )
end

function GameBottomNode:getCoinWinNode()
    return self.coinWinNode
end

function GameBottomNode:createCoinWinEffectUI()
    if self.coinBottomEffectNode ~= nil then
        self.coinBottomEffectNode:removeFromParent()
        self.coinBottomEffectNode = nil
    end
    if self.coinWinNode ~= nil then
        local effectCsbName = nil
        if globalData.slotRunData.isPortrait == true then
            effectCsbName = "GameNode/GameBottomNodePortrait_jiesuan.csb"
        else
            effectCsbName = "GameNode/GameBottomNode_jiesuan.csb"
        end
        if effectCsbName ~= nil then
            local coinBottomEffectNode = util_createAnimation(effectCsbName)
            self.coinBottomEffectNode = coinBottomEffectNode
            self.coinWinNode:addChild(coinBottomEffectNode)
            coinBottomEffectNode:setVisible(false)
        end
    end
end
-- 修改已创建的收集反馈效果
function GameBottomNode:changeCoinWinEffectUI(_levelName, _csbName)
    if nil ~= self.coinBottomEffectNode and nil ~= _csbName then
        local csbPath = ""
        --找关卡资源
        csbPath = string.format("GameScreen%s/%s", _levelName, _csbName)
        if CCFileUtils:sharedFileUtils():isFileExist(csbPath) then
            self.coinBottomEffectNode:removeFromParent()
            self.coinBottomEffectNode = nil
            self.coinBottomEffectNode = util_createAnimation(csbPath)
            self.coinWinNode:addChild(self.coinBottomEffectNode)
            self.coinBottomEffectNode:setVisible(false)
            return
        end
        --找系统资源
        csbPath = string.format("GameNode/%s", _csbName)
        if CCFileUtils:sharedFileUtils():isFileExist(csbPath) then
            self.coinBottomEffectNode:removeFromParent()
            self.coinBottomEffectNode = nil
            self.coinBottomEffectNode = util_createAnimation(csbPath)
            self.coinWinNode:addChild(self.coinBottomEffectNode)
            self.coinBottomEffectNode:setVisible(false)
            return
        end
    --不修改,使用默认创建好的资源工程
    end
end

function GameBottomNode:playCoinWinEffectUI(callBack)
    local coinBottomEffectNode = self.coinBottomEffectNode
    if coinBottomEffectNode ~= nil then
        coinBottomEffectNode:setVisible(true)
        coinBottomEffectNode:runCsbAction("actionframe",false,function()
            coinBottomEffectNode:setVisible(false)
            if callBack ~= nil then
                callBack()
            end
        end)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

--[[
    大赢文本效果
        简介:
            用于展示关卡触发大赢时在底栏文本上再展示一个大赢文本,跳动数值为本次触发大赢的赢钱数值
]]
function GameBottomNode:createBigWinLabUi()
    --[[
        actionframe  0~30   横屏
        actionframe2 0~20   竖屏(主要用于respin结算)
        actionframe3 0~150  正常连线(主要用于大赢)
    ]]
    local csbPath = "CommonButton/csb_slot/totalwin_shuzi.csb"
    self:changeBigWinLabUi(csbPath)
end
function GameBottomNode:changeBigWinLabUi(_csbPath)
    if not self.coinWinNode then
        return
    end
    if not CCFileUtils:sharedFileUtils():isFileExist(_csbPath) then
        return
    end
    --资源创建
    if self.m_bigWinLabCsb ~= nil then
        self.m_bigWinLabCsb:removeFromParent()
        self.m_bigWinLabCsb = nil
    end
    self.m_bigWinLabCsb = util_createAnimation(_csbPath)
    self.coinWinNode:addChild(self.m_bigWinLabCsb)
    self.m_bigWinLabCsb:setVisible(false)
    --初始化适配参数
    local labCoins = self.m_bigWinLabCsb:findChild("m_lb_coins")
    local labInfo = {}
    labInfo.label = labCoins
    local labSize = labCoins:getContentSize()
    labInfo.width = labSize.width
    labInfo.sx = labCoins:getScaleX()
    labInfo.sy = labCoins:getScaleY()
    self:setBigWinLabInfo(labInfo)
end
function GameBottomNode:setBigWinLabInfo(_labInfo)
    self.m_bigWinLabInfo = _labInfo
end
function GameBottomNode:playBigWinLabAnim(_params)
    if not self.m_bigWinLabCsb then
        return 
    end
    --[[
        _params = {
            beginCoins = 0,
            overCoins  = 100,
            jumpTime   = 3,
            actType    = 1,             --(二选一)通用的几种放大缩小表现
            animName   = "actionframe", --(二选一)工程内的时间线

            fnActOver  = function,
            fnJumpOver = function,
        }
    ]]
    self:stopUpDateBigWinLab()
    local beginCoins  = _params.beginCoins or 0
    local overCoins   = _params.overCoins  or 100
    local winCoins    = overCoins - beginCoins
    _params.jumpTime  = _params.jumpTime or self:getCoinsShowTimes(winCoins)
    local jumpTime    = _params.jumpTime
    _params.fnActOver = _params.fnActOver or function() end
    local fnJumpOver  = _params.fnJumpOver or function() end

    --跳钱
    local coinRiseNum = winCoins / (jumpTime * 60)
    local str   = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.floor(coinRiseNum)
    local curCoins = beginCoins
    self.m_updateBigWinLabHandler = util_schedule(self.m_bigWinLabCsb, function()
        curCoins =  math.min(overCoins, curCoins + coinRiseNum)
        self:setBigWinLabCoins(curCoins)
        if curCoins >= overCoins then
            self:stopUpDateBigWinLab()
            fnJumpOver()
        end
    end, 1/60)
    --文本放大缩小 分为通用动作或时间线
    self:playBigWinLabActionByType(_params)
    self:playBigWinLabTimeLineByName(_params)
end
--通用动作
function GameBottomNode:playBigWinLabActionByType(_params)
    local actType = _params.actType
    if not actType then
        return
    end
    if actType == 1 then
        self:playBigWinLabAction_1(_params)
    elseif actType == 2 then
    end
end
function GameBottomNode:playBigWinLabAction_1(_params)
    local jumpTime   = _params.jumpTime
    local minScale   = 0.01
    local labParent  = self.m_bigWinLabCsb:findChild("m_lb_coins"):getParent()
    -- 放大1->放大2->放大3->缩小消失  
    labParent:stopAllActions()
    labParent:setScale(minScale)
    self.m_bigWinLabCsb:setVisible(true)
    labParent:runActionEx(cc.Sequence:create(
        cc.ScaleTo:create(24/60, 1),
        cc.ScaleTo:create(jumpTime-24/60+0.1, 1.15),
        cc.ScaleTo:create(15/60, 1.25),
        cc.ScaleTo:create(15/60, minScale),
        cc.CallFunc:create(function()
            self.m_bigWinLabCsb:setVisible(false)
            _params.fnActOver()
        end)
    ))
end
--时间线
function GameBottomNode:playBigWinLabTimeLineByName(_params)
    local animName = _params.animName
    if not animName then
        return
    end
    util_resetCsbAction(self.m_bigWinLabCsb.m_csbAct)
    self.m_bigWinLabCsb:setVisible(true)
    self.m_bigWinLabCsb:runCsbAction(animName, false, function()
        self.m_bigWinLabCsb:setVisible(false)
        _params.fnActOver()
    end)
end
function GameBottomNode:setBigWinLabCoins(_coins)
    local sCoins   = string.format("+%s", util_getFromatMoneyStr(_coins)) 
    local labCoins = self.m_bigWinLabCsb:findChild("m_lb_coins")
    labCoins:setString(sCoins)
    self:updateLabelSize(self.m_bigWinLabInfo, self.m_bigWinLabInfo.width)
end
function GameBottomNode:stopUpDateBigWinLab()
    if nil ~= self.m_updateBigWinLabHandler then
        self.m_bigWinLabCsb:stopAction(self.m_updateBigWinLabHandler)
        self.m_updateBigWinLabHandler = nil
    end
end


function GameBottomNode:checkPlayMaxBetEff()
    if not globalNoviceGuideManager:isNoobUsera() then
        return
    end
    if not self.m_maxBetEffCount then
        self.m_maxBetEffCount = gLobalDataManager:getNumberByField("guide_maxBetEffCount", 0)
    end
    if self.m_maxBetEffCount < 2 then
        self.m_maxBetEffCount = self.m_maxBetEffCount + 1
        gLobalDataManager:setNumberByField("guide_maxBetEffCount", self.m_maxBetEffCount)
        local maxBet = nil
        if self.m_btn_MaxBet then
            maxBet = self.m_btn_MaxBet
        elseif self.m_btn_MaxBet1 then
            maxBet = self.m_btn_MaxBet1
        end
        if not maxBet then
            return
        end
        self.m_maxBetEff = util_createView("views.newbieTask.GuideMaxBetNode")
        maxBet:addChild(self.m_maxBetEff)
        local size = maxBet:getContentSize()
        self.m_maxBetEff:setPosition(size.width * 0.5, size.height * 0.5)
        performWithDelay(
            self,
            function()
                if self.m_maxBetEff then
                    self.m_maxBetEff:removeFromParent()
                    self.m_maxBetEff = nil
                end
            end,
            6
        )
    end
end

function GameBottomNode:addCardBetChip()
end

function GameBottomNode:delCardBetChip()
end

-- 任务按钮迁移出去 点击事件操作还放在这里代理执行
function GameBottomNode:taskClickAgent(clickType)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 5})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_PIG_TIPS)

    if clickType and clickType == 0 then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_LOG_GUIDE_NOFORCE, {guideIndex = 7})
        -- self.m_mission_msg:setVisible(true)
        -- gLobalViewManager:addAutoCloseTips(self.m_mission_msg,function()
        --     self.m_mission_msg:setVisible(false)
        -- end)
    else
        -- 打开每日任务界面
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "gameDailyMissionIcon")

        -- 引导打点：每日任务完成提示-2.点击每日任务按钮
        if gLobalSendDataManager:getLogGuide():isGuideBegan(7) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(7, 2)
        end

        -- GameBottomMixTipView:clickFunc已经播了
        --gLobalSoundManager:playSound("Sounds/btn_click.mp3")

        -- csc 2021-07-06 修改创建 tasklayer 的点位
        gLobalDailyTaskManager:updateConfig()
        gLobalDailyTaskManager:createDailyMissionPassMainLayer()

        self.closeMissionLeadFunc = nil
        if self.m_showTipAction ~= nil then
            self:stopAction(self.m_showTipAction)
            self.m_showTipAction = nil
        end
        self:runAnim("idle", true)

        if self.m_guideMissionNode then
            self.m_guideMissionNode:hide(
                function()
                    self.m_guideMissionNode = nil
                end
            )
        end
    end
end

function GameBottomNode:clickTips(node)
    if not node then
        return
    end
    if node:isVisible() then
        node:setVisible(false)
        return
    end
    node:setVisible(true)
    gLobalViewManager:addAutoCloseTips(
        node,
        function()
            performWithDelay(
                self,
                function()
                    if not tolua.isnull(node) then
                        node:setVisible(false)
                    end
                end,
                0.1
            )
        end
    )
end

function GameBottomNode:getNormalWinLabel()
    return self.m_normalWinLabel
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

function GameBottomNode:addNewMissionTips(_params)
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_DAILYMISSION then
        return
    end

    if _params ~= nil and _params.task ~= nil then
        local missionNode = self:findChild("Node_mission")
        local qipao = util_createView("views.gameviews.GameBottomNextTaskQiapo", _params)
        missionNode:addChild(qipao)
    end
end


-- 大赢宝箱tip
function GameBottomNode:initMegaWinIcon()
    local bOpen = G_GetMgr(ACTIVITY_REF.MegaWinParty):isCanShowLayer()
    if not bOpen then
        return
    end 
    
    local parent = self:findChild("node_MegaWin")
    if parent then
        local view = util_createView("Activity.MegaWinPartyGameIconNode")
        view:addTo(parent)
    end
end

function GameBottomNode:initMegaWinUI()
    local panel_chestList = self:findChild("panel_chestList")
    local bOpen = G_GetMgr(ACTIVITY_REF.MegaWinParty):isCanShowLayer()
    if not bOpen then
        if panel_chestList then
            panel_chestList:setVisible(false)
        end
        return
    end 
    if panel_chestList then
        self:addClick(panel_chestList)
        panel_chestList:setSwallowTouches(true)
    end
    local parent = self:findChild("node_chestList")
    local view = G_GetMgr(ACTIVITY_REF.MegaWinParty):createGameBottomNode() 
    self.m_MegaWinPartyNode = view
    view:addTo(parent)
end

function GameBottomNode:afterMegaWinOver()
    local node_MegaWin = self:findChild("node_MegaWin")
    if node_MegaWin then
        node_MegaWin:removeAllChildren()
    end
    local node_chestList = self:findChild("node_chestList")
    if node_chestList then
        node_chestList:removeAllChildren()
    end
    
    G_GetMgr(ACTIVITY_REF.MegaWinParty):showOverView()
end

function GameBottomNode:checkSidekicksBet()
    local node = self:findChild("node_sidekicksBet")
    if not node then
        return
    end

    if gLobalActivityManager:isMinzLevel() or gLobalActivityManager:isDiyFeatureLevel() then
        -- minz diy 不显示 宠物
        return
    end
    
    local sidekicksWinCoin = G_GetMgr(G_REF.Sidekicks):getBetWinCoins()
    if sidekicksWinCoin then
        local machineNode = gLobalViewManager:getViewLayer():getParent()
        if not self.m_sidekicksBetNode and machineNode then
            local seasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
            self.m_sidekicksBetNode = G_GetMgr(G_REF.Sidekicks):getSidekicksBetNode(seasonIdx)
            if not self.m_sidekicksBetNode then
                return
            end
            local posW = node:convertToWorldSpace(cc.p(0, 0))
            machineNode:addChild(self.m_sidekicksBetNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
            self.m_sidekicksBetNode:move(posW)
            local scale = self.m_csbNode:getScale()
            self.m_sidekicksBetNode:setScale(scale)
        end
    
        if self.m_sidekicksBetNode then
            self.m_sidekicksBetNode:playStart(sidekicksWinCoin)
        end 
    end
end

function GameBottomNode:setVisible(_bVisible)
    _bVisible = _bVisible and true or false
    
    if self.m_sidekicksBetNode then
        self.m_sidekicksBetNode:setVisible(_bVisible)
    end
    GameBottomNode.super.setVisible(self, _bVisible)
end

-- 设置活动等额外节点显示状态
function GameBottomNode:setExtraNodeVisible(isVisible)
    -- 宠物大赢宝箱UI
    local node_chest = self:findChild("node_chestList")
    if node_chest then
        node_chest:setVisible(isVisible or false)
    end
end

return GameBottomNode
