-- 小猪挑战主界面的公共类

local PigChallengeBaseLayer = class("PigChallengeBaseLayer", BaseLayer)

function PigChallengeBaseLayer:ctor()
    PigChallengeBaseLayer.super.ctor(self)

    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)

    self.m_data = G_GetMgr(ACTIVITY_REF.PiggyChallenge):getRunningData()
    self.m_config = G_GetMgr(ACTIVITY_REF.PiggyChallenge):getConfig()
    -- 宝箱特效轮播记录值
    self.record_idx = 0

    self:setLandscapeCsbName(self.m_config.MainView)
    self:setPortraitCsbName(self.m_config.MainView_Portral)
end

-- 活动关闭 界面将自动关闭
function PigChallengeBaseLayer:checkIsRunning()
    local bl_isRunning = G_GetMgr(ACTIVITY_REF.PiggyChallenge):isRunning()
    if not bl_isRunning then
        self:setVisible(false)
        self:setShowActionEnabled(false)
        self:setHideActionEnabled(false)
        util_afterDrawCallBack(
            function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
        )
    end
    return bl_isRunning
end

function PigChallengeBaseLayer:initUI(data)
    if not self:checkIsRunning() then
        return
    end

    PigChallengeBaseLayer.super.initUI(self, data)

    -- 注册界面点击事件
    self:registBgClick()

    -- 创建宝箱
    self.reward_items = {}
    for boxId, node in pairs(self.box_nodes) do
        local reward_data = self.m_data:getRewardDataByBoxId(boxId)
        local rewardBox = util_createView("activities.Activity_PiggyChallenge.view.PigChallengeBox", boxId, reward_data, "pop_layer")
        node:addChild(rewardBox)
        self.reward_items[boxId] = rewardBox
    end

    -- 显示刻度尺
    local isSmallR = self.m_data:isSmallR()
    self.spDial_s:setVisible(isSmallR)
    self.spDial_b:setVisible(not isSmallR)

    local cur_process = self.m_data:getCurProcess()
    local cur_idx = self.m_data:getCurIdx()
    if not self.m_data:isRewardCollected(cur_idx) then
        cur_process = self.m_data:getPreProcess()
    end
    self.sp_process:setPercent(math.floor(cur_process * 100))

    -- 显示档位
    for idx, lb_gear in ipairs(self.lb_gears) do
        local gearIdx = isSmallR and idx or idx * 2
        lb_gear:setString(gearIdx)
    end

    -- 刷新倒计时
    self:tickTimer()
end

function PigChallengeBaseLayer:initCsbNodes()
    self.sp_bg = self:findChild("sp_bg")
    assert(self.sp_bg, "PigChallengeBaseLayer 必要的节点1")

    self.sp_process = self:findChild("progress")
    assert(self.sp_process, "PigChallengeBaseLayer 必要的节点2")

    self.panel_eff = self:findChild("panel_eff")

    self.spDial_b = self:findChild("sp_kedu") --大R的
    assert(self.spDial_b, "PigChallengeBaseLayer 必要的节点3")

    self.spDial_s = self:findChild("sp_kedu2") --小R的
    assert(self.spDial_s, "PigChallengeBaseLayer 必要的节点4")

    self.box_nodes = {}
    self.lb_gears = {}
    for idx = 1, 4 do
        local node_box = self:findChild("node_" .. idx)
        assert(node_box, "PigChallengeBaseLayer 必要的节点 宝箱位置 " .. idx)
        table.insert(self.box_nodes, idx, node_box)

        local lb_gear = self:findChild("lb_" .. idx)
        assert(lb_gear, "PigChallengeBaseLayer 必要的节点 档位文本 " .. idx)
        table.insert(self.lb_gears, idx, lb_gear)
    end

    self.m_btnClose = self:findChild("btn_close")
end

function PigChallengeBaseLayer:tickTimer()
    local left_time = self.m_data:getLeftTime()
    -- 低于1.5天再开始创建计时器
    if left_time <= 86400 * 1.5 then
        self.timer_schedule =
            schedule(
            self,
            function()
                local end_time = self.m_data:getExpireAt()
                -- 刷新倒计时
                if self.setTimer then
                    self:setTimer(end_time)
                else
                    if self.timer_schedule then
                        self:stopAction(self.timer_schedule)
                        self.timer_schedule = nil
                    end
                end
            end,
            1
        )
    end

    if self.setTimer then
        local end_time = self.m_data:getExpireAt()
        self:setTimer(end_time)
    end
end

function PigChallengeBaseLayer:registBgClick()
    local bg_size = self.sp_bg:getContentSize()

    local layout = ccui.Layout:create()
    layout:setName("layout_touch")
    layout:setTouchEnabled(true)
    layout:setContentSize(bg_size)
    self:addClick(layout)
    layout:addTo(self.sp_bg)
end

-- 请求领取奖励 自动领取未领取奖励
function PigChallengeBaseLayer:requestReward()
    local onSuccess = function(_, resDat)
        gLobalViewManager:removeLoadingAnima()
        if not tolua.isnull(self) then
            self:onPrecessMove()
        end
    end
    local onFailed = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end
    gLobalViewManager:addLoadingAnima(true)
    gLobalSendDataManager:getNetWorkFeature():sendPigChallengeCollectReq(onSuccess, onFailed)
end

function PigChallengeBaseLayer:onPrecessMove()
    local tick_delay = 0.02 -- 刷新间隔时间
    local step_length = 50 * tick_delay -- 步长 目标是1秒钟涨100%

    local tar_percent = self.m_data:getCurProcess()
    tar_percent = math.floor(tar_percent * 100)
    local cur_percent = self.sp_process:getPercent()

    if cur_percent >= tar_percent then
        -- 开箱子
        self:onProcessMoveEnd()
        return
    end

    local mask = util_newMaskLayer(false)
    mask:setOpacity(0)
    self:addChild(mask)

    self.process_schedule =
        util_schedule(
        self,
        function()
            local cur_percent = self.sp_process:getPercent()
            local new_percent = cur_percent + step_length

            if new_percent > tar_percent then
                new_percent = tar_percent
                self:stopAction(self.process_schedule)
                self.process_schedule = nil
                -- 开箱子
                mask:removeSelf()
                self:onProcessMoveEnd()
            end
            self.sp_process:setPercent(new_percent)

            --self.panel_eff:setContentSize()
        end,
        tick_delay
    )
end

-- 进度条上涨完毕 刷新宝箱状态
function PigChallengeBaseLayer:onProcessMoveEnd()
    local cur_idx = self.m_data:getCurIdx()
    for idx, reward_box in pairs(self.reward_items) do
        local box_data = reward_box:getData()
        if box_data and box_data.pos == cur_idx and self.m_data:hasRewards(cur_idx) then
            reward_box:onOpen()
            break
        end
    end

    -- 弹出奖励弹板
    self:showRewards()
end

-- 弹出通用奖励面板
function PigChallengeBaseLayer:showRewards()
    local idx = self.m_data:getCurIdx()
    if not self.m_data:hasRewards(idx) then
        return
    end
    local rewards = self.m_data:getRewardData(idx)
    if not rewards then
        return
    end

    local callbackfunc = function()
        if CardSysManager:needDropCards("Pig Challenge") == true then
            CardSysManager:doDropCards("Pig Challenge")
        end
    end
    local item_list = {}
    if rewards.items and table.nums(rewards.items) > 0 then
        for _, item_data in pairs(rewards.items) do
            table.insert(item_list, item_data)
        end
    end

    local rewardLayer = gLobalItemManager:createRewardLayer(item_list, callbackfunc, tonumber(rewards.coins), true)
    gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)

    if self.m_config.SOUNDS_ENUM and self.m_config.SOUNDS_ENUM.GAIN_REWARD then
        gLobalSoundManager:playSound(self.m_config.SOUNDS_ENUM.GAIN_REWARD)
    end
end

function PigChallengeBaseLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        self:hideTips()
    elseif name == "btn_close" then
        self:closeUI()
    elseif name == "btn_start" then
        -- 去小猪银行页面
        self:closeUI(
            function()
                G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
                    gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, "PigChallengeLayer")
                    if gLobalSendDataManager.getLogPopub then
                        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_start", DotUrlType.UrlName, false)
                    end
                end)                 
            end
        )
    end
end

-- 显示宝箱奖励tips
function PigChallengeBaseLayer:showTips(idx)
    if not idx then
        return
    end
    local reward_data = self.m_data:getRewardDataByBoxId(idx)
    if not reward_data then
        return
    end
    local node_box = self.box_nodes[idx]
    if not node_box then
        return
    end

    if not self.reward_tips then
        self.reward_tips = util_createView("activities.Activity_PiggyChallenge.view.PigChallengeTips")
        self:addChild(self.reward_tips)
    end

    local pos = {}
    pos.x, pos.y = node_box:getPosition()
    local world_pos = node_box:getParent():convertToWorldSpace(pos)
    local node_pos = self:convertToNodeSpace(world_pos)
    self.reward_tips:setPosition(cc.p(node_pos.x, node_pos.y + 50))
    self.reward_tips:updateUI(reward_data)
    self.reward_tips:showTips()
end

-- 隐藏宝箱奖励tips
function PigChallengeBaseLayer:hideTips()
    if self.reward_tips then
        self.reward_tips:hideTips()
    end
end

-- 显示动画回调
function PigChallengeBaseLayer:onShowedCallFunc()
    if util_csbActionExists(self.m_csbAct, "idle", self.__cname) then
        self:runCsbAction("idle", true)
    end
end

function PigChallengeBaseLayer:onEnter()
    PigChallengeBaseLayer.super.onEnter(self)

    local idx = self.m_data:getCurIdx()
    if not self.m_data:isRewardCollected(idx) and self.m_data:hasRewards(idx) then
        -- 发送请求领取奖励
        self:requestReward()
    end

    self:playBoxEffect()
end

-- 宝箱闪烁效果
function PigChallengeBaseLayer:playBoxEffect()
    local cur_idx = self.m_data:getCurIdx()
    -- 修正值
    if self.record_idx >= table.nums(self.reward_items) then
        self.record_idx = cur_idx
    end
    for idx, reward_item in ipairs(self.reward_items) do
        if idx > self.record_idx and not self.m_data:isRewardCollected(idx) then
            if reward_item then
                reward_item:runCsbAction(
                    "idle",
                    false,
                    function()
                        self:playBoxEffect()
                    end
                )
                self.record_idx = idx
                break
            end
        end
    end
end

-- 注册消息事件
function PigChallengeBaseLayer:registerListener()
    PigChallengeBaseLayer.super.registerListener(self)

    -- 活动结束事件
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.PiggyChallenge then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    -- 显示宝箱奖励tips
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                if params and params.init_type == "pop_layer" and params.idx then
                    self:showTips(params.idx)
                end
            end
        end,
        ViewEventType.NOTIFY_PIG_CHALLENGE_REWARD_CLICKED
    )
end

function PigChallengeBaseLayer:closeUI(end_call)
    if not tolua.isnull(self.panel_eff) then
        self.panel_eff:setVisible(false)
    end

    self:hideTips()

    PigChallengeBaseLayer.super.closeUI(
        self,
        function()
            if end_call then
                end_call()
                return
            end

            local closeCallBack = self.m_data:getCloseCallBack()
            if closeCallBack then
                closeCallBack()
                self.m_data:setCloseCallBack(nil)
            else
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        end
    )
end

return PigChallengeBaseLayer
