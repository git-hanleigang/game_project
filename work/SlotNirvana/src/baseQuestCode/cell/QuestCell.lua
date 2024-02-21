-- Created by jfwang on 2019-05-21.
-- QuestCell
--
local QuestCell = class("QuestCell", BaseView)

local CELL_STATE = {
    LOCKED = "LOCKED", -- 锁定
    UNLOCK = "UNLOCK", -- 解锁
    PLAYING = "PLAYING", -- 开启中
    FINISHED = "FINISHED", -- 完结未结算
    REWARD = "REWARD", -- 奖励已领取
    COMPLETE = "COMPLETE" -- 关卡完成
}

function QuestCell:getCsbNodePath()
    return QUEST_RES_PATH.QuestCell
end

--奖励礼盒
function QuestCell:getGiftCsbNodePath()
    return QUEST_RES_PATH.QuestCellGift
end

function QuestCell:initDatas(data)
    --阶段序号
    self.m_curPhase = data.phase
    --关卡序号
    self.m_curStage = data.stage
    --唯一标示
    self.m_index = data.index

    --当前关卡数据
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return
    end
    self.m_data = act_data:getStageData(self.m_curPhase, self.m_curStage)
    self.m_info = globalData.slotRunData:getLevelInfoById(self.m_data.p_gameId)
end

function QuestCell:initCsbNodes()
    self.m_logoNode = self:findChild("logo")
    self.m_logoNode1 = self:findChild("logo1")

    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
        btn_click:setSwallowTouches(false)
    end

    self.btn_i = self:findChild("btn_i")
    if self.btn_i then
        self:addClick(self.btn_i)
        self.btn_i:setVisible(false)
        self.btn_i:setSwallowTouches(false)
    end
    self.m_btnAct_i = self:findChild("FileNode_1")

    self.m_sp_Minz = self:findChild("sp_Minz")
end

function QuestCell:initUI()
    self:createCsbNode(self:getCsbNodePath())

    self:initView()
    self:initInfo()
    self:initState()
end

function QuestCell:initState()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return
    end
    self.m_data = act_data:getStageData(self.m_curPhase, self.m_curStage)
    local stage_state = self.m_data:getState()
    local cell_state = nil
    if stage_state == "INIT" then
        if not self:isUnLock() then
            cell_state = CELL_STATE.LOCKED
        elseif self:isComplete() then
            cell_state = CELL_STATE.COMPLETE
        else
            --维护关卡直接改为完成状态
            if self.m_info and self.m_info.p_maintain then
                self.m_data.p_status = "FINISHED"
                cell_state = CELL_STATE.FINISHED
            elseif self:getCellState() == CELL_STATE.LOCKED then
                cell_state = CELL_STATE.UNLOCK
            elseif self:getCellState() == CELL_STATE.COMPLETE then
                cell_state = CELL_STATE.UNLOCK
            else
                cell_state = CELL_STATE.PLAYING
            end
        end
    elseif stage_state == "FINISHED" then
        cell_state = CELL_STATE.FINISHED
    elseif stage_state == "REWARD" then
        cell_state = CELL_STATE.REWARD
    elseif stage_state == "COMPLETE" then
        cell_state = CELL_STATE.COMPLETE
    end
    if cell_state then
        self:changeState(cell_state)
    end
end

function QuestCell:getIndex()
    return self.m_index
end

--初始化关卡配置信息并检测下载状态
function QuestCell:initInfo()
    if self.m_info and not self.m_info.p_fastLevel then
        local percent = gLobaLevelDLControl:getLevelPercent(self.m_info.p_levelName)
        if percent then
            self:createDownLoadNode(percent)
        end
    end
end

function QuestCell:isUnLock()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return false
    end
    local phase_idx = act_data:getPhaseIdx()
    if not phase_idx or self.m_curPhase > phase_idx then
        return false
    end

    local stage_idx = act_data:getStageIdx()
    if not stage_idx or self.m_curStage > stage_idx then
        return false
    end

    return true
end

function QuestCell:isComplete()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return false
    end
    local phase_idx = act_data:getPhaseIdx()
    if not phase_idx or self.m_curPhase > phase_idx then
        return false
    end

    local stage_idx = act_data:getStageIdx()
    if not stage_idx or self.m_curStage >= stage_idx then
        return false
    end

    return true
end

function QuestCell:updateQuestIcon()
    --关卡头像
    local levelName = globalData.slotRunData:getLevelName(self.m_data.p_gameId)
    if levelName then
        local level_icon = self:showSprite(levelName)
        if level_icon then
            if self.m_sp_cell then
                level_icon:setColor(self.m_sp_cell:getColor())
            end
            level_icon:setName("level_icon")
            self.m_logoNode:removeChildByName("level_icon")
            self.m_logoNode:addChild(level_icon)
            self.m_sp_cell = level_icon
            self.m_sp_cell:setScale(0.75) -- 设置的固定值 之前是66% 正常的关卡图标放在这里会偏大
        end
    end
end

function QuestCell:showSprite(levelName)
    local p_sprite = nil
    local path = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.UNLOCK)
    if util_IsFileExist(path) then
        p_sprite = util_createSprite(path)
    else
        local loading_path = "QuestOther/quest_loading_icon.png"
        p_sprite = util_createSprite(loading_path)
        if self.m_info and self.m_info.p_csbName then
            local notifyName = util_getFileName(self.m_info.p_csbName)
            if globalDynamicDLControl:checkDownloading(notifyName) then
                --注册下载通知
                gLobalNoticManager:addObserver(
                    self,
                    function(self, params)
                        if not tolua.isnull(self) then
                            self:updateQuestIcon()
                        end
                    end,
                    notifyName
                )
            end
        end
    end
    return p_sprite
end

function QuestCell:initView()
    if self.m_data == nil then
        return
    end
    if self.m_sp_Minz then
        local data = G_GetMgr(ACTIVITY_REF.Minz):getRunningData()
        local machineData = globalData.slotRunData:getLevelInfoById(self.m_data.p_gameId)
        if data and machineData and machineData.getMinzGame and machineData:getMinzGame() then
            self.m_sp_Minz:setVisible(true)
        else
            self.m_sp_Minz:setVisible(false)
        end
    end

    self:updateQuestIcon()

    local csbAct = util_actCreate(self:getGiftCsbNodePath())
    self.m_btnAct_i:runAction(csbAct)
    local btn_i =  self.m_btnAct_i:getChildByName("btn_i")
    local sp_cell =  btn_i:getChildByName("sp_cell")
    if sp_cell then
        self.m_lb_time = sp_cell:getChildByName("lb_time")
        self.m_time_cell = sp_cell
        self:updataTime()
    end

    util_csbPlayForKey(csbAct, "idle", true)
    self.m_btnAct_i:setVisible(false)

    self:updateNado()
end

function QuestCell:updataTime()
    self:updateLeftTime()
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTime), 1)
end

function QuestCell:updateLeftTime()
    local buffInfo_1 = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
    if buffInfo_1 then
        self.m_time_cell:setVisible(true)
        local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
        self.m_lb_time:setString(util_switchSecondsToHSM(leftTimes))
    else
        self.m_time_cell:setVisible(false)
    end
end

function QuestCell:updateNado()
    local act_nado = G_GetActivityDataByRef(ACTIVITY_REF.QuestNado)
    if act_nado and act_nado:isRunning() then
        if not self.m_logoNode:getChildByName("sp_nado") then
            local sp_nado = cc.Sprite:create("QuestOther/questNado.png")
            sp_nado:setName("sp_nado")
            sp_nado:setPosition(cc.p(70, 50))
            sp_nado:addTo(self.m_logoNode)
        end
    else
        if self.m_logoNode:getChildByName("sp_nado") then
            self.m_logoNode:removeChildByName("sp_nado")
        end
    end
end

function QuestCell:onEnter()
    self:registerHandler()
end

--完成quest关卡后弹窗
function QuestCell:checkShowFinishView(func)
    if self.m_isFinishShow then
        if func then
            func()
        end
        return false
    end
    self.m_isFinishShow = true
    if func then
        return G_GetMgr(ACTIVITY_REF.Quest):checkShowFinishView(func)
    else
        return G_GetMgr(ACTIVITY_REF.Quest):checkShowFinishView()
    end
    return false
end

--进入quest弹窗
function QuestCell:checkShowEnterView()
    if self.m_isFirstShow then
        return false
    end
    self.m_isFirstShow = true
    return G_GetMgr(ACTIVITY_REF.Quest):checkShowEnterView()
end

function QuestCell:changeState(new_state)
    if self.cell_state == new_state then
        if new_state == CELL_STATE.LOCKED then
            self:showBtnTip()
        else
            local stage_state = self.m_data:getState()
            if stage_state == "INIT" then
                self:showBtnTip()
            end
        end
        return
    end

    self:setCellState(new_state)
    if new_state == CELL_STATE.LOCKED then
        self:showLocked()
    elseif new_state == CELL_STATE.UNLOCK then
        self:showUnlock()
    elseif new_state == CELL_STATE.PLAYING then
        self:showPlaying()
    elseif new_state == CELL_STATE.FINISHED then
        self:showPlaying()
        self:showFinished()
    elseif new_state == CELL_STATE.REWARD then
        self:showPlaying()
        self:showOnRewarded()
    elseif new_state == CELL_STATE.COMPLETE then
        self:showComplete()
    end
end

function QuestCell:setCellState(new_state)
    self.cell_state = new_state
end

function QuestCell:getCellState()
    return self.cell_state
end

function QuestCell:showLocked()
    if self.m_sp_cell then
        self.m_sp_cell:setColor(cc.c3b(180, 180, 180))
    end
    self:runCsbAction("unlock")

    self:showBtnTip()
end

function QuestCell:showUnlock()
    self:runCsbAction(
        "unlock_act",
        false,
        function()
            self:changeState(CELL_STATE.PLAYING)
            local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if not act_data then
                return
            end
            if not act_data.m_lastPhase or act_data.m_lastPhase <= act_data.p_phase then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_NEWSTAGE_UNLOCK)
            end
        end,
        60
    )
    self:showBtnTip()
end

function QuestCell:showPlaying()
    if self.m_sp_cell then
        self.m_sp_cell:setColor(cc.c3b(255, 255, 255))
    end
    self:runCsbAction("spin", true)
    self:showBtnTip()
end

function QuestCell:showFinished()
    --发送切换下一关消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE)
                self:onMsgFinished(params)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE
    )

    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNextStage("Reward")
end

function QuestCell:onMsgFinished(bl_success)
    if not bl_success then
        util_restartGame()
        return
    end
    gLobalNoticManager:addObserver(
        self,
        function()
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE)
            self:changeState(CELL_STATE.REWARD)
        end,
        ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE
    )
    -- 请求奖励
    local _index = self.m_index
    if self.checkShowFinishView then
        self:checkShowFinishView(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK, {index = _index})
            end
        )
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK, {index = _index})
    end
end

function QuestCell:showOnRewarded()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return
    end
    local phase_idx = act_data:getPhaseIdx()
    local stage_idx = act_data:getStageIdx()
    if self:getIndex() ~= (phase_idx - 1) * 6 + stage_idx then
        self:changeState(CELL_STATE.COMPLETE)
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE)
                self:onMsgRewarded(params)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE
    )

    --发送切换下一关消息
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNextStage("NextStage")
end

function QuestCell:onMsgRewarded(bl_success)
    if not bl_success then
        util_restartGame()
        return
    end
    if self.checkShowFinishView then
        self:checkShowFinishView(
            function()
                if tolua.isnull(self) then
                    return
                end
                if self:getCellState() == CELL_STATE.REWARD then
                    self:onComplete()
                else
                    self:changeState(CELL_STATE.COMPLETE)
                end
            end
        )
    else
        if tolua.isnull(self) then
            return
        end
        if self:getCellState() == CELL_STATE.REWARD then
            self:onComplete()
        else
            self:changeState(CELL_STATE.COMPLETE)
        end
    end
end

function QuestCell:onComplete()
    --完成调转下一关
    self:runCsbAction(
        "done_act",
        false,
        function()
            self:changeState(CELL_STATE.COMPLETE)

            -- 消息发送，执行轮盘和关卡的解锁逻辑
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_OPEN, {index = self.m_index + 1})
        end,
        60
    )
end

function QuestCell:showComplete()
    self:runCsbAction("done", true, nil, 60)
    self:hideBtnTip()
end

function QuestCell:registerHandler()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                if params.index == self:getIndex() then
                    self:initState()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_OPEN
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.QuestNado then
                if not tolua.isnull(self) then
                    self:updateNado()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

--显示礼物按钮
function QuestCell:showBtnTip()
    if self.btn_i and not G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView(self.m_curPhase) then
        self.btn_i:setVisible(true)
        if self.m_btnAct_i then
            self.m_btnAct_i:setVisible(true)
        end
    end
end

function QuestCell:hideBtnTip()
    if self.btn_i then
        self.btn_i:setVisible(false)
        if self.m_btnAct_i then
            self.m_btnAct_i:setVisible(false)
        end
    end
end

--打开betTips
function QuestCell:showTipsView(btnWDPos, btnSize)
    --当前关卡数据
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return
    end

    if act_data:getPhaseIdx() ~= self.m_curPhase then
        return
    end

    self:initTipView()
    if self.m_bet_tipNode == nil then
        return
    end
    if btnWDPos and btnSize then
        local nodePos = self.m_bet_tipNode:getParent():convertToNodeSpace(btnWDPos)
        self.m_bet_tipNode:setPosition(nodePos.x + btnSize.width / 2 + 20, nodePos.y + btnSize.height / 2)
    end

    --难度还未选择，就不弹提示框
    if G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
        return
    end

    if not self.m_showBetTips then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.btn_i then
            self.btn_i:setTouchEnabled(false)
        end
        self.m_showBetTips = true
        self.m_bet_tipNode:showTipView(
            function()
                --3s自动消失
                performWithDelay(
                    self,
                    function()
                        self:hideTipsView()
                    end,
                    3
                )
            end
        )
    end
end

function QuestCell:hideTipsView()
    if self.btn_i then
        self.btn_i:setTouchEnabled(true)
    end

    if self.m_showBetTips and self.m_bet_tipNode then
        self.m_bet_tipNode:hideTipView(
            function()
                self.m_showBetTips = false
            end
        )
    end
end

--创建tips
function QuestCell:initTipView()
    if not self.btn_i then
        return
    end
    if not self.m_bet_tipNode then
        self.m_bet_tipNode = util_createFindView(QUEST_CODE_PATH.QuestCellTips, self.m_curPhase, self.m_curStage)
        self.m_bet_tipNode:setLocalZOrder(1000)

        local nodePos = cc.p(self.btn_i:getPosition())
        local worldPos = self.btn_i:getParent():convertToWorldSpace(nodePos)
        local pos = self:getParent():convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        local gift_size = self.btn_i:getContentSize()
        self.m_bet_tipNode:setPosition(pos.x + gift_size.width / 2 + 10, pos.y + 20)
        self:getParent():addChild(self.m_bet_tipNode)
    end
end

--检测下载状态并进入游戏
function QuestCell:checkDownLoadGotoLevel(isClickMusic)
    local info = self.m_info
    if not info then
        return
    end
    local percent = gLobaLevelDLControl:getLevelPercent(info.p_levelName)
    if info.p_fastLevel then
        self:checkGotoLevel()
    elseif percent then
        self:createDownLoadNode(percent)
    elseif gLobaLevelDLControl:isDownLoadLevel(info) == 2 then
        self:checkGotoLevel()
    elseif info.p_freeOpen and gLobaLevelDLControl:isUpdateFreeOpenLevel(info.p_levelName, info.p_levelName.p_md5) == false then
        self:checkGotoLevel()
    else
        self:createDownLoadNode(nil, isClickMusic)
    end
end

--创建下载节点
function QuestCell:createDownLoadNode(percent, isClickMusic)
    local info = self.m_info
    if not info then
        return
    end

    if self.m_dlView then
        return
    end

    self.m_dlView =
        util_createFindView(
        QUEST_CODE_PATH.QuestCellDL,
        info,
        function()
            self.m_dlView:removeFromParent()
            self.m_dlView = nil
            self:checkGotoLevel()
        end,
        function()
            self.m_dlView:removeFromParent()
            self.m_dlView = nil
        end
    )

    self.m_logoNode1:addChild(self.m_dlView, 1)
    self.m_dlView:updateStartDl(percent)
    if not percent then
        if isClickMusic then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
        --下载入口记录
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
            gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(info.p_levelName, {type = "Quest", siteType = "RegularArea"})
        end
        gLobaLevelDLControl:checkDownLoadLevel(info)
    end
end

--进入关卡
function QuestCell:checkGotoLevel()
    local info = self.m_info
    if not info then
        return
    end

    --根据app版本检测关卡是否可以进入
    -- if not gLobalViewManager:checkEnterLevelForApp(info.p_id) then
    --     gLobalViewManager:showUpgradeAppView()
    --     return
    -- end

    local notifyName = util_getFileName(info.p_csbName)
    if globalDynamicDLControl:checkDownloading(notifyName) then
        --入口未下载
        return
    end

    --难度还未选择，就不进入关卡了
    if G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
        return
    end

    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not act_data then
        return
    end

    --已完成关卡不能进入
    if not self.m_data or not self.m_data.p_status or self.m_data.p_status == "FINISHED" or self.m_data.p_status == "COMPLETE" then
        return
    end

    --不是当前关卡
    local phase_idx = act_data:getPhaseIdx()
    local stage_idx = act_data:getStageIdx()
    if self.m_curPhase ~= phase_idx or self.m_curStage ~= stage_idx then
        return
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
    gLobalSendDataManager:getLogSlots():resetEnterLevel()
    local isSucc = gLobalViewManager:gotoSlotsScene(info, "QuestLobby")
    if isSucc then
        --确定从quest活动，进入关卡
        act_data.class.m_IsQuestLogin = true
        act_data:recordLastBoxData()
    end
end

function QuestCell:onTouchClick(isClick)
    --进入难度选择
    if self:getCellState() == CELL_STATE.PLAYING then
        ----只有手动点击才会进入这里
        if isClick and not G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
            self:checkDownLoadGotoLevel(true)
        end
    end
end

function QuestCell:clicked()
    return self.m_clicked
end

function QuestCell:setClicked(bl_clicked)
    if self.m_clicked == bl_clicked then
        return
    end
    if bl_clicked then
        if self.click_delay then
            self:stopAction(self.click_delay)
            self.click_delay = nil
        end
        self.click_delay =
            util_performWithDelay(
            self,
            function()
                if not tolua.isnull(self) then
                    self.click_delay = nil
                    self.m_clicked = false
                end
            end,
            0.5
        )
    end
    self.m_clicked = bl_clicked
end

function QuestCell:clickFunc(sender)
    if self:clicked() then
        return
    end

    local name = sender:getName()
    if name == "btn_click" then
        self:setClicked(true)
        self:onTouchClick(true)
    elseif name == "btn_i" then
        self:setClicked(true)
        self:showTipsView()
    end
end

return QuestCell
