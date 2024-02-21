-- quest挑战活动主界面
-- FIX IOS 150 v465

local Activity_QuestNewRushLayerBase = class("Activity_QuestNewRushLayerBase", BaseLayer)

local PROG_SPEED = 100 -- 进度条速度
local INTERVEL = 0.02
local SCHEDULE_TIME_LIMIT_SEC = 24 * 60 * 60 * 1.5
local MAX_GEAR = 3 -- 3个档位
local MIN_PRG_WIDTH = 54 --进度条最小的大小

-- 任务类型
local QuestNewRush_RushType = {
    STAR = "1001", -- 累积星星完成任务
    STAGE = "1002", -- 累积过关完成任务
    CHAPTER = "1003" -- 累积章节完成任务
}

function Activity_QuestNewRushLayerBase:ctor()
    Activity_QuestNewRushLayerBase.super.ctor(self)

    self.m_data = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRunningData()

    self:setKeyBackEnabled(true)
    -- 设置横屏csb
    self:setLandscapeCsbName(self:getCsbPath())
    self:setExtendData("QuestRushMainlayer")
end

function Activity_QuestNewRushLayerBase:initDatas(_data)
    self.m_isEntrance = false
    if _data and _data.popupType == ACT_LAYER_POPUP_TYPE.ENTRANCE then
        self.m_isEntrance = true
    end
end

function Activity_QuestNewRushLayerBase:initUI()
    Activity_QuestNewRushLayerBase.super.initUI(self)

    self:initBgUI()
    self:initRewardsUI()
    self:initSpine()
    -- 刷新进度条
    self:updateProgress()
    -- 刷新时间
    self:updateTimer()

    local csbName = self:getCsbPath()
    local pathList = string.split(csbName, "/")
    if pathList and table.nums(pathList) > 0 then
        local name = pathList[table.nums(pathList)]
        local key = name .. ":" .. "btn_start"
        local labelString = gLobalLanguageChangeManager:getStringByKey(key)
        self:setButtonLabelContent("btn_start", labelString)
    end

    if self.m_isEntrance then
        self:hideEntranceNodes()
    end
end

function Activity_QuestNewRushLayerBase:initSpine()
    -- body
end

function Activity_QuestNewRushLayerBase:hideEntranceNodes()
    local leftTimeBg = self:findChild("sp_time_bg")
    if leftTimeBg then
        leftTimeBg:setVisible(false)
    end
    if self.m_lbLeftTime then
        self.m_lbLeftTime:setVisible(false)
    end
end

--子类必须重写
function Activity_QuestNewRushLayerBase:getCsbPath()
    
end

function Activity_QuestNewRushLayerBase:initCsbNodes()
    --self.root = self:findChild("root")
    -- 倒计时
    self.m_lbLeftTime = self:findChild("lb_timeleft")
    -- 关闭按钮 供活动主入口使用
    self.m_btnClose = self:findChild("btn_close")
    -- 进度条
    self.progress = self:findChild("progress")
    -- 进度条上的panel 裁切进度条上的特效用的
    self.progress_panel = self:findChild("Panel_1")

    self.particleFollow = self:findChild("Particle_follow")
    self.particleFollow:setVisible(false)

    self.particleFull = self:findChild("Particle_full")

    -- 累积星星任务 星星的数值文本
    self.lb_curNum = self:findChild("lb_star")
    self.lb_progress = self:findChild("lb_progress")
    self.sp_diban = self:findChild("sp_diban")
    -- 累积通关或累积通过章节任务 任务描述文本
    self.lb_task = self:findChild("lb_task")
    self.lb_difficulty = self:findChild("lb_difficulty")

    self:setButtonLabelContent("btn_get_stars", "GET STARS")
    self:setButtonLabelContent("bth_quest_on", "QUEST ON")
end

function Activity_QuestNewRushLayerBase:initBgUI()
    -- 任务描述
    local rushType = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRushType()
    if rushType == QuestNewRush_RushType.STAGE then
        self.lb_task:setString("PASS SLOT GAMES IN QUEST TO WIN PRIZES")
    elseif rushType == QuestNewRush_RushType.CHAPTER then
        self.lb_task:setString("PASS THE PHASE IN QUEST TO WIN PRIZES")
    end

    -- 难度描述
    if rushType == QuestNewRush_RushType.STAGE or rushType == QuestNewRush_RushType.CHAPTER then
        local diff = G_GetMgr(ACTIVITY_REF.QuestNewRush):getDifficulty()
        local diff_str = ""
        if diff <= 1 then
            local posy = self.lb_task:getPositionY()
            self.lb_task:setPositionY(posy - 22)
            diff_str = ""
        elseif diff == 2 then
            diff_str = "ON NORMAL OR HARD"
        elseif diff == 3 then
            diff_str = "ON HARD"
        end
        self.lb_difficulty:setString(diff_str)
    end
end

function Activity_QuestNewRushLayerBase:getItemPath()
    assert(false, "Activity_QuestNewRushLayerBase:getItemPath 需要子类指定文件路径")
end

-- init 奖励UI
function Activity_QuestNewRushLayerBase:initRewardsUI()
    self:resetRewardPosition()
    -- 奖励信息节点列表
    self.m_rewards = {}
    local pos_start = 0
    for idx = 1, MAX_GEAR do
        local _node = self:findChild("node_reward_" .. idx)
        local rewardItem, pos_end
        if _node then
            local file_path = self:getItemPath()
            rewardItem = util_createFindView(file_path, idx)
            if not tolua.isnull(rewardItem) then
                rewardItem:addTo(_node)
            end
            if idx == MAX_GEAR then
                local size = self.progress_panel:getContentSize()
                pos_end = size.width
            else
                local world_pos = _node:convertToWorldSpace(cc.p(0, 0))
                local node_pos = self.progress_panel:convertToNodeSpace(world_pos)
                pos_end = node_pos.x
            end
        end

        local _label = self:findChild("lb_step_" .. idx)
        if _label then
            local completeNum = self.m_data:getConditionByIdx(idx)
            _label:setString(completeNum)
            util_scaleCoinLabGameLayerFromBgWidth(_label, 48)
        end

        self.m_rewards[idx] = {
            pos_start = pos_start,
            pos_end = pos_end,
            lb_step = _label,
            reward = rewardItem
        }
        pos_start = pos_end
    end
end

function Activity_QuestNewRushLayerBase:resetRewardPosition()
    local sp_progress_bg = self:findChild("sp_progress_bg")
    if not sp_progress_bg then
        printError("quest挑战 进度条背景控件获取失败")
        return
    end

    local size = sp_progress_bg:getContentSize()
    local length = size.width
    local rewardsData = self.m_data:getRewardsInfoList()
    if not rewardsData or table.nums(rewardsData) ~= MAX_GEAR then
        printError("quest挑战 数据对不上")
        return
    end

    for idx = 1, MAX_GEAR do
        local _node = self:findChild("node_step" .. idx)
        if _node then
            local percent = idx / MAX_GEAR
            if percent > 0 and size.width > 0 then
                _node:setPositionX(size.width * percent)
            end
        end
    end
end

-- 刷新累积的进度数值
function Activity_QuestNewRushLayerBase:updateProcessNum(_bPre)
    local starNum = self.m_data:getCurProcess()
    if _bPre then
        starNum = self.m_data:getPreProcess()
    end
    local maxStarNum = self.m_data:getRushCompleteCondition()

    local width = 130
    if self.sp_diban then
        width = self.sp_diban:getContentSize().width - 15
    end
    local rushType = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRushType()
    if self.lb_curNum then
        self.lb_curNum:setString(starNum .. "/" .. maxStarNum)
        self:updateLabelSize({label = self.lb_curNum, sx = 0.62,sy = 0.62},160)
    end

    if self.lb_progress then
        self.lb_progress:setString(starNum .. "/" .. maxStarNum)
        util_scaleCoinLabGameLayerFromBgWidth(self.lb_progress, width)
    end
end

-- 更新进度条
function Activity_QuestNewRushLayerBase:updateProgressUI(_layoutW)
    local size = cc.size(_layoutW, self.progress_panel:getContentSize().height)
    self.progress_panel:setContentSize(size)
    if self.particleFollow then
        self.particleFollow:setPositionX(_layoutW)
    end
    local progress_width = self.progress:getContentSize().width
    self.progress:setPercent(_layoutW / progress_width * 100)
    self.m_layoutW = _layoutW
end

-- 更新进度
function Activity_QuestNewRushLayerBase:updateProgress()
    if not self.m_layoutW then
        self.m_layoutW = self:getLengthToComplete(true)
    end
    if not self.m_newLayoutW then
        self.m_newLayoutW = self:getLengthToComplete()
    end

    if math.abs(self.m_layoutW - self.m_newLayoutW) < 1 then
        self:updateProgressUI(self.m_layoutW)
        self:updateProcessNum(false)
        self:updateItemsState(true)

        for idx = 1, MAX_GEAR do
            local _label = self:findChild("lb_step_" .. idx)
            if _label then
                local starNum = self.m_data:getCurProcess()
                local completeNum = self.m_data:getConditionByIdx(idx)
                _label:setString(completeNum)
                util_scaleCoinLabGameLayerFromBgWidth(_label, 48)

                local bl_complete = (tonumber(starNum) >= tonumber(completeNum))
                local sp_star = self:findChild("sp_star" .. idx)
                if sp_star then
                    sp_star:setVisible(not bl_complete)
                end
                local sp_complete = self:findChild("sp_duihao" .. idx)
                if sp_complete then
                    sp_complete:setVisible(bl_complete)
                end
            end
        end

        if self.m_scheduleProg then
            if self.particleFollow then
                self.particleFollow:setVisible(false)
            end
            self:stopAction(self.m_scheduleProg)
            self.m_scheduleProg = nil
        end
        G_GetMgr(ACTIVITY_REF.QuestNewRush):resetOldData()
    else
        local step = INTERVEL * PROG_SPEED
        if self.m_newLayoutW < self.m_layoutW then
            -- 5倍速度倒退回原点
            step = -1 * step * 5
        end

        local curLayoutW = self.m_layoutW + step
        if self.m_newLayoutW >= self.m_layoutW then
            curLayoutW = math.min(curLayoutW, self.m_newLayoutW)
        else
            curLayoutW = math.max(curLayoutW, self.m_newLayoutW)
        end
        self:updateProgressUI(curLayoutW)
        local bl_isNew = curLayoutW >= self.m_newLayoutW
        self:updateProcessNum(not bl_isNew)

        for idx = 1, MAX_GEAR do
            local starNum = self.m_data:getCurProcess()
            local completeNum = self.m_data:getConditionByIdx(idx)
            local bl_complete = (tonumber(starNum) >= tonumber(completeNum))
            local sp_star = self:findChild("sp_star" .. idx)
            if sp_star then
                sp_star:setVisible(not bl_complete)
            end
            local sp_complete = self:findChild("sp_duihao" .. idx)
            if sp_complete then
                sp_complete:setVisible(bl_complete)
            end
        end

        if not self.m_scheduleProg then
            if self.particleFollow then
                self.particleFollow:setVisible(true)
            end
            self.m_scheduleProg = util_schedule(self, handler(self, self.updateProgress), INTERVEL)
        end
    end
end

function Activity_QuestNewRushLayerBase:updateItemsState(bl_isNew)
    for idx, data in ipairs(self.m_rewards) do
        if data.reward then
            data.reward:updateItemState(bl_isNew)
        end
    end
end

-- 刷新活动倒计时
function Activity_QuestNewRushLayerBase:updateTimer()
    -- 刷新倒计时
    local leftTime = self.m_data:getLeftTime()
    local timeStr = util_daysdemaining1(leftTime)
    self.m_lbLeftTime:setString(timeStr)

    if leftTime <= SCHEDULE_TIME_LIMIT_SEC then
        self.schedule_timer =
            util_schedule(
            self.m_lbLeftTime,
            function()
                local leftTime = self.m_data:getLeftTime()
                if leftTime <= 0 then
                    self.m_lbLeftTime:stopAction(self.schedule_timer)
                    self.schedule_timer = nil
                    leftTime = 0
                end

                local timeStr = util_daysdemaining1(leftTime)
                self.m_lbLeftTime:setString(timeStr)
            end,
            1
        )
    end
end

function Activity_QuestNewRushLayerBase:onKeyBack()
    self:closeUI(true)
end

function Activity_QuestNewRushLayerBase:onEnter()
    Activity_QuestNewRushLayerBase.super.onEnter(self)

    -- 活动结束事件
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.QuestNewRush then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self)
            if G_GetMgr(ACTIVITY_REF.QuestNewRush):getNeedRefreshProcess() then
                G_GetMgr(ACTIVITY_REF.QuestNewRush):setNeedRefreshProcess(false)
                self.m_layoutW = nil
                self.m_newLayoutW = nil
                self:updateProgress()
            end
        end,
        ViewEventType.NOTIFY_NEWQUESTRUSH_UPDATE_REWARD_ITEM_STATE
    )
end

function Activity_QuestNewRushLayerBase:closeUI(isNotify)
    local callback = function()
        if isNotify then
            -- 没有逻辑回调弹窗 谈下一个队列里的
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end

        -- 未领取的奖励 领取
        for _, data in ipairs(self.m_rewards) do
            if data.reward then
                data.reward:checkReceiveReward()
            end
        end

        -- 更新 老数据
        G_GetMgr(ACTIVITY_REF.QuestNewRush):resetOldData()
        G_GetMgr(ACTIVITY_REF.QuestNewRush):setNeedRefreshProcess(false)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_RUSH_ENTERY_UPDATE)
    end

    -- hide 粒子
    if self.particleFollow then
        self.particleFollow:stopSystem()
        self.particleFollow:setVisible(false)
    end
    if self.particleFull then
        self.particleFull:stopSystem()
        self.particleFull:setVisible(false)
    end

    Activity_QuestNewRushLayerBase.super.closeUI(self, callback)
end

-- 统一点击回调
function Activity_QuestNewRushLayerBase:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        self:closeUI(true)
    elseif name == "btn_start" or name == "btn_get_stars" or name == "bth_quest_on" then
        -- 去quest主界面
        self:goToQuestMainView()
        self:closeUI()
    end
end

-- 去quest主界面
function Activity_QuestNewRushLayerBase:goToQuestMainView()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterQuestLayer() then
        return
    end

    gLobalSendDataManager:getLogQuestNewActivity():sendQuestEntrySite("questRushToQuestMain")
    G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
end

-- 获取进度条最大的进度
function Activity_QuestNewRushLayerBase:getLengthToComplete(_bPre)
    -- 当前进度
    local curNum = self.m_data:getCurProcess()
    if _bPre then
        curNum = self.m_data:getPreProcess()
    end
    curNum = tonumber(curNum)

    local cur_step = self.m_data:getCurrentStep()
    if _bPre then
        cur_step = self.m_data:getPreStep()
    end

    -- 当前阶段 起始条件
    local startNum = tonumber(self.m_data:getBaseByIdx(cur_step))
    -- 当前阶段 完成条件
    local conditionNum = tonumber(self.m_data:getConditionByIdx(cur_step))

    local reward_data = self.m_rewards[cur_step]
    local step_length = reward_data.pos_end - reward_data.pos_start
    local step_percent = (curNum - startNum) / (conditionNum - startNum)
    local percent_length = step_percent * step_length
    -- 初始的默认长度
    if cur_step == 1 and percent_length > 0 then
        percent_length = math.max(percent_length, self:getProgShowMinWidth())
    end
    return percent_length + reward_data.pos_start
end

-- 初始的最小进度
function Activity_QuestNewRushLayerBase:getProgShowMinWidth()
    return MIN_PRG_WIDTH
end

return Activity_QuestNewRushLayerBase
