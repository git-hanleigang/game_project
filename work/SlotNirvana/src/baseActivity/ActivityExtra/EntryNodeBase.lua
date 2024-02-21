-- FIX IOS 139
-- 关卡能量收集条 基类
local EntryNodeConfig = util_require("baseActivity.ActivityExtra.EntryNodeConfig")
local BaseView = util_require("base.BaseView")
local EntryNodeBase = class("EntryNodeBase", BaseView)

function EntryNodeBase:ctor()
    BaseView.ctor(self)

    self.show_list = {}
    self.onCollecting = false
    self.processTable = {}
    -- self.state = EntryNodeConfig.NODE_STATE.NORMAL
end

function EntryNodeBase:initUI(activity_type, res_name)
    assert(activity_type, "EntryNodeBase 活动类型异常")
    assert(res_name, "EntryNodeBase 关卡能量收集条资源名称异常 " .. activity_type)

    self.activity_type = activity_type
    self:initDataConfig()

    self.m_bOpenProgress = false

    self:createCsbNode(res_name)
    -- 读取必要节点
    self:readCsbNodes()
end

function EntryNodeBase:initDataConfig()
    local activity_config = EntryNodeConfig.data_config[self.activity_type]
    assert(activity_config, "EntryNodeBase 活动配置不存在 " .. self.activity_type)

    -- 记录一些随活动类型配置的常量
    self.fly_effect_name = activity_config.fly_effect_name -- 收集特效
    self.effect_nums = activity_config.effect_nums -- 创建特效数量
    self.activity_file_name = activity_config.lua_file -- 活动主界面索引名称
    self.entry_type = activity_config.entry_type -- 打点 类型
    self.entry_node_name = activity_config.entry_node_name -- 打点 名称
    self.is_rotation = activity_config.is_rotation -- 是否旋转
end

function EntryNodeBase:getIsInQuest()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig:isRunning() then
        return questConfig.m_IsQuestLogin
    end

    return G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()
end

-- 初始化必要节点
function EntryNodeBase:readCsbNodes()
    self.root = self:findChild("root")
    assert(self.root, self.activity_type .. " EntryNodeBase 必须的节点 root")

    -- 缩小状态下 显示区域
    self.panel_small = self:findChild("Node_PanelSize")
    assert(self.panel_small, self.activity_type .. " EntryNodeBase 必须的节点1")

    -- 正常状态下 显示区域
    self.panel_normal = self:findChild("Node_PanelSize_launch")
    assert(self.panel_normal, self.activity_type .. " EntryNodeBase 必须的节点2")

    -- 进度条
    self.sp_process_open = self:findChild("progress_open")
    assert(self.sp_process_open, self.activity_type .. " EntryNodeBase 必须的节点3")

    -- 进度条百分比
    self.lb_process_open = self:findChild("lb_progress_open")
    assert(self.lb_process_open, self.activity_type .. " EntryNodeBase 必须的节点4")

    -- 骰子累积数量
    self.lb_num_open = self:findChild("lb_num_open")
    assert(self.lb_num_open, self.activity_type .. " EntryNodeBase 必须的节点5")

    -- 进度条
    self.sp_process_close = self:findChild("progress_close")
    assert(self.sp_process_close, self.activity_type .. " EntryNodeBase 必须的节点6")

    --关闭的时候进度条百分比
    self.lb_progress_close = self:findChild("lb_progress_close")
    assert(self.lb_progress_close, self.activity_type .. " EntryNodeBase 必须的节点7")

    -- 骰子累积数量
    self.lb_num_close = self:findChild("lb_num_close")
    assert(self.lb_num_close, self.activity_type .. " EntryNodeBase 必须的节点8")

    -- 红点 关闭状态下数字的背景图
    self.sp_num_close_bg = self:findChild("sp_num_close_bg")
    assert(self.sp_num_close_bg, self.activity_type .. " EntryNodeBase 必须的节点9")

    --正常状态下 飞行终止点
    self.open_flyNode = self:findChild("sp_item")
    assert(self.open_flyNode, self.activity_type .. " EntryNodeBase 必须的节点10")

    --缩小状态下 飞行终止点
    self.close_flyNode = self:findChild("sp_logo")
    assert(self.close_flyNode, self.activity_type .. " EntryNodeBase 必须的节点11")

    local btn_close = self:findChild("btn_close")
    assert(btn_close, self.activity_type .. " EntryNodeBase 必须的节点12")

    local btn_open = self:findChild("btn_open")
    assert(btn_open, self.activity_type .. " EntryNodeBase 必须的节点13")

    assert(util_csbActionExists(self.m_csbAct, "show", self.__cname), self.activity_type .. " show 动画不存在")
    assert(util_csbActionExists(self.m_csbAct, "hide", self.__cname), self.activity_type .. " over 动画不存在")

    self.processTable = {
        [EntryNodeConfig.NODE_STATE.NORMAL] = {
            process = self.sp_process_open,
            percent = self.lb_process_open,
            num = self.lb_num_open,
            flyNode = self.open_flyNode
        },
        [EntryNodeConfig.NODE_STATE.SMALL] = {
            process = self.sp_process_close,
            percent = self.lb_progress_close,
            num = self.lb_num_close,
            flyNode = self.close_flyNode
        }
    }
end

-- 点击事件 --
function EntryNodeBase:clickFunc(sender)
    local sName = sender:getName()
    local nTag = sender:getTag()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    if sName == "btn_close" then
        self:changeState(EntryNodeConfig.NODE_STATE.SMALL)
    elseif sName == "btn_open" then
        if self._bForbidUnflod then
            self:gotoPlay()
            return
        end
        self:changeState(EntryNodeConfig.NODE_STATE.NORMAL)
    elseif sName == "btn_play" then
        self:gotoPlay()
    end
end

function EntryNodeBase:onEnter()
    self:registerListener()

    -- 更新显示状态 -- (下面的代码是quest关卡里面的悬浮条指定位置显示 必须写在构造函数里 不能写到onEnter里面去)
    local state = EntryNodeConfig.NODE_STATE.SMALL -- 新版本修改为默认是small 入口
    -- 如果记录的展开入口为这个入口,那么设置成展开状态
    local bInitSmall = true -- 初始化是否为小信号,为小信号的情况下不需要调用左边条的缩回动画
    if gLobalActivityManager:getAutoChangeToProgress(self.activity_type) then
        state = EntryNodeConfig.NODE_STATE.NORMAL
        bInitSmall = false
    end

    local bl_inQuest = self:getIsInQuest()
    if bl_inQuest == true then
        state = EntryNodeConfig.NODE_STATE.SMALL
        bInitSmall = true
    end

    self:changeState(state, bInitSmall)

    -- 刷新数据
    self:onDataRefresh()
end

function EntryNodeBase:registerListener()
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.name == self.activity_type then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.name == self.activity_type then
                -- 这里不做直接刷新 放入缓存列表等待表现
                printInfo("数据刷新获得")
                self:onDataRefresh()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData.action == "SPIN" then
                    self:onSpinResult(spinData)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 监听强制收回展开状态的消息
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.name == self.activity_type then
                -- 如果当前是自己触发的强制收回的话
                self.m_bPauseFunc = true
            else
                if self.m_bOpenProgress then
                    -- 直接调用缩小动画
                    self:changeState(EntryNodeConfig.NODE_STATE.SMALL)
                end
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_FORCE_HIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            -- 监听悬浮条移动到左侧后应该做的动画
            if not self.m_bPauseFunc then
                if self.m_updateEntryNodeFunc then
                    self.m_updateEntryNodeFunc()
                    self.m_updateEntryNodeFunc = nil
                end
            else
                self.m_bPauseFunc = nil
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_MOVEIN
    )
end

function EntryNodeBase:onExit()
    gLobalNoticManager:removeAllObservers(self)

    -- 退出关卡 清除缓存数据
    local activity_data = G_GetActivityDataByRef(self.activity_type)
    if activity_data and activity_data:isRunning() then
        -- 清空
        -- activity_data.state_popupInStage_ShowCollect = nil -- cxc 2023-01-10 16:14:03 登录期间状态统一，退出关卡不清除标识
        activity_data.popupInStage_willShowCollect = nil
        activity_data.popupInStage_showCollectNum = nil

        activity_data.state_popupInStage_ShowMax = EntryNodeConfig.COLLECT_MAX_STATE.WILL_SHOW
        activity_data.popupInStage_willShowMax = nil
        activity_data.popupInStage_showMaxNum = nil
    end
end

-- 活动结束 去除图标 --
function EntryNodeBase:closeUI()
    gLobalActivityManager:removeActivityEntryNode(self.activity_type)
end

-----------------------------------------   UI伸缩变换相关  -----------------------------------------
-- 返回entry 大小
function EntryNodeBase:getPanelSize()
    local size_small = self.panel_small:getContentSize()
    local size_normal = self.panel_normal:getContentSize()
    return {widht = size_small.width, height = size_small.height, launchHeight = size_normal.height}
end

function EntryNodeBase:getState()
    return self.state
end

function EntryNodeBase:setState(state)
    if state and self.state ~= state then
        self.state = state
        return true
    end
    return false
end

-- _inQuest 只有在第一次加载节点的时候会传入
-- true 的情况下表示当前在quest关卡内,不允许调用展开动画
function EntryNodeBase:changeState(state, _bInitSmall)
    -- 无效的状态切换
    if not self:setState(state) then
        return
    end

    -- 刷新UI
    local cur_data = self:getControllData()
    if cur_data then
        self:updateProcess(cur_data)
    end

    if state == EntryNodeConfig.NODE_STATE.NORMAL then
        self:setStateNormal()
    elseif state == EntryNodeConfig.NODE_STATE.SMALL then
        self:setStateSmall(_bInitSmall)
    end
end

function EntryNodeBase:setStateSmall(_bInitSmall)
    self.m_bOpenProgress = false
    if _bInitSmall then
        self:onActionComplete()
    else
        self:runCsbAction("hide", false)
        gLobalActivityManager:resetEntryNodeInfo(
            self.activity_type,
            function()
                if not tolua.isnull(self) then
                    self:onActionComplete()
                end
            end
        )
    end
end

function EntryNodeBase:setStateNormal()
    if self._bForbidUnflod then
        return
    end
    self:runCsbAction("show", false)
    self.m_bOpenProgress = true
    gLobalActivityManager:showEntryNodeInfo(
        self.activity_type,
        function()
            if not tolua.isnull(self) then
                self:onActionComplete()
            end
        end
    )
end

-- 动画衔接
function EntryNodeBase:onActionComplete()
    if self.state == EntryNodeConfig.NODE_STATE.NORMAL then
        self:showComplete()
    elseif self.state == EntryNodeConfig.NODE_STATE.SMALL then
        self:hideComplete()
    end
end

function EntryNodeBase:getEntryNodeOpenState()
    -- 获取当前进度条是否展开
    return self.m_bOpenProgress
end

-- TODO normal动画播放完的动画衔接 具体逻辑子类实现
function EntryNodeBase:showComplete()
end

-- TODO small动画播放完的动画衔接 具体逻辑子类实现
function EntryNodeBase:hideComplete()
end

-- 如果要传参数 子类重写
function EntryNodeBase:gotoPlay()
    local param = nil
    local callback = nil
    self:openActivityMainView(param, callback)
end

-- 跳转到活动主界面
function EntryNodeBase:openActivityMainView(param, callBack)
    if not self:getActivityData() then
        return
    end

    if gLobalViewManager:getViewByExtendData(self.activity_file_name) then
        return
    end

    self:registPopupLog()
    -- self:logOnClick()
    -- 打开活动主界面
    gLobalActivityManager:showActivityMainView(self.activity_type, self.activity_file_name, param, callBack)
end

-- 打点
function EntryNodeBase:registPopupLog()
    local curMachineData = globalData.slotRunData.machineData or {}
    gLobalSendDataManager:getLogIap():setEntryGame(curMachineData.p_name)
    gLobalSendDataManager:getLogIap():setEnterOpen(self.entry_type, self.entry_node_name)
end

-- -- 打点
-- function EntryNodeBase:logOnClick()
--     local logManager = gLobalSendDataManager:getActivityLogManager()
--     if logManager then
--         logManager:onClick( self.activity_type, self.entry_node_name )
--     end
-- end
-----------------------------------------   UI伸缩变换相关  -----------------------------------------

-----------------------------------------   能量收集特效  -----------------------------------------

function EntryNodeBase:getActivityData()
    if self.activity_type then
        local gameData = G_GetActivityDataByRef(self.activity_type)
        if gameData and gameData:isRunning() then
            return gameData
        end
    end
end
-- 子类重写 数据赋值
function EntryNodeBase:getControllData()
    assert(false, "getControllData 需要重写")
end

-- 子类重写 数据赋值
function EntryNodeBase:setCollectData()
    assert(false, "setCollectData 需要重写")
end

function EntryNodeBase:onSpinResult(spinData, data_type)
    -- 数值常规判断
    if not spinData then
        return
    end
    local activityData = self:getActivityData()
    if not activityData then
        return
    end

    local result = self:getControllData()
    if not result then
        return
    end
    -- 刷新本地缓存
    if not self:setCollectData(spinData) then
        return
    end
    -- 刷新数据
    self:onDataRefresh(data_type)
end

-- 刷新数据
function EntryNodeBase:onDataRefresh(data_type)
    -- 检查弹框
    self:checkPopupView()
    -- 组装一个规范数据去刷新表现
    local result = self:getControllData()
    if result then
        -- 首次放入队列
        if not result.num or not result.num_max or not result.energy or not result.energy_max then
            printError(" num " .. tostring(result.num) .. ", num_max " .. tostring(result.num_max) .. ", energy " .. tostring(result.energy) .. ", energy_max " .. tostring(result.energy_max))
            return
        end

        result.data_type = data_type

        local lastest_data = nil
        if table.nums(self.show_list) > 0 then
            lastest_data = self.show_list[#self.show_list]
        else
            lastest_data = self.cur_data
        end
        -- 有新数据需要放入队列(数据发生变化)
        if not lastest_data or lastest_data.num ~= result.num or lastest_data.num_max ~= result.num_max or lastest_data.energy ~= result.energy or lastest_data.energy_max ~= result.energy_max then
            --result.energy = math.floor(result.energy / 100) * 100
            table.insert(self.show_list, result)
        end

        if table.nums(self.show_list) > 0 then
            -- 收集动画
            self:collect()
        end
    end
end

function EntryNodeBase:checkPopupView()
    local result = self:getControllData()
    if not result then
        return
    end

    local activity_data = G_GetActivityDataByRef(self.activity_type)
    if not activity_data or not activity_data:isRunning() then
        -- 清空
        activity_data.state_popupInStage_ShowCollect = nil
        activity_data.popupInStage_willShowCollect = nil
        activity_data.popupInStage_showCollectNum = nil

        activity_data.state_popupInStage_ShowMax = EntryNodeConfig.COLLECT_MAX_STATE.WILL_SHOW
        activity_data.popupInStage_willShowMax = nil
        activity_data.popupInStage_showMaxNum = nil
        return
    end

    -- 弹框判定 累积数量发生变化
    if self.cur_data and self.cur_data.num then
        if activity_data.state_popupInStage_ShowCollect == nil then
            activity_data.state_popupInStage_ShowCollect = true
        end
        -- 获得新的活动次数弹框
        if self.cur_data.num < result.num and result.num < result.num_max and self:checkPlayIsOn(result) then
            activity_data.popupInStage_willShowCollect = true
            activity_data.popupInStage_showCollectNum = result.num
        else
            activity_data.popupInStage_willShowCollect = false
            activity_data.popupInStage_showCollectNum = nil
        end
    end

    if not activity_data.state_popupInStage_ShowMax then
        activity_data.state_popupInStage_ShowMax = EntryNodeConfig.COLLECT_MAX_STATE.WILL_SHOW
    end
    -- 活动次数累积满弹框
    if result.num >= result.num_max then
        if activity_data.state_popupInStage_ShowMax ~= EntryNodeConfig.COLLECT_MAX_STATE.SHOW_OVER then
            activity_data.state_popupInStage_ShowMax = EntryNodeConfig.COLLECT_MAX_STATE.ON_SHOW
        end
        activity_data.popupInStage_willShowMax = true
        activity_data.popupInStage_showMaxNum = result.num
    else
        activity_data.state_popupInStage_ShowMax = EntryNodeConfig.COLLECT_MAX_STATE.WILL_SHOW
        activity_data.popupInStage_willShowMax = false
        activity_data.popupInStage_showMaxNum = nil
    end
end

-- 累积道具是否激活活动玩法(默认累积道具大于一个就能激活)
function EntryNodeBase:checkPlayIsOn(result)
    -- if result.num and result.num >= 1 then
    --     return true
    -- end
    -- return false
    return true
end

-- 收集动画表现 刷新进度条等
function EntryNodeBase:collect()
    printInfo("levelfly --- EntryNodeBase:collect --- 1")
    -- 活动数据异常或活动结束
    local activityData = self:getActivityData()
    if not activityData then
        return
    end
    printInfo("levelfly --- EntryNodeBase:collect --- 2")
    -- 正在刷新 不能抢占
    if self.onCollecting == true then
        return
    end
    printInfo("levelfly --- EntryNodeBase:collect --- 3")
    -- 数据列表为空 不需要刷新
    if table.nums(self.show_list) <= 0 then
        return
    end
    printInfo("levelfly --- EntryNodeBase:collect --- 4")
    self.onCollecting = true
    -- 飞行动画 这里需要判定 是否需要飞行动画
    local play_data = self.show_list[1]
    local m_isC = false
    if self.cur_data then
        local zz = play_data.energy - self.cur_data.energy
        if zz >= 0 then
            local baifen = zz/play_data.energy_max
            if baifen < 0.01 then
                m_isC = true
            end
        else
            if play_data.energy > 0 then
                m_isC = true
            end
        end
    end

    local bLimitRefresh = false
    local slotIsSmallEntry = gLobalActivityManager:getEntryNode(self.activity_type, true)
    if slotIsSmallEntry then
        -- 当前入口在展开滑动列表里， 同时当前入口没显示 直接刷新数据
        bLimitRefresh = slotIsSmallEntry ~= self 
    end
    if bLimitRefresh or not self.cur_data or not self.cur_data.energy or self.cur_data.energy == play_data.energy or m_isC then
        -- 这种状态下的数据直接刷新 不需要飞行动画
        table.remove(self.show_list, 1)
        -- 缓存一份数据
        self.cur_data = clone(play_data)

        -- 直接刷新就好了
        self:updateProcess(play_data)

        self.onCollecting = false
        printInfo("levelfly --- EntryNodeBase:collect --- 5")
        self:collect()
        return
    end
    printInfo("levelfly --- EntryNodeBase:collect --- 6")
    self:doCollectEffect()
end

function EntryNodeBase:getFlyActionParentNode()
    local getEntryRootNode = gLobalActivityManager:getEntryRootNode()
    if getEntryRootNode then
        return getEntryRootNode
    end
    return self:getParent():getParent()
end

function EntryNodeBase:getEffectStartPos()
    -- 这一段抄过来的 关系节点没变
    return self:getFlyActionParentNode():convertToNodeSpace(globalData.bingoCollectPos)
end

function EntryNodeBase:getEffectEndPos()
    local world_pos = cc.p(0, 0)
    local _isVisible = gLobalActivityManager:getEntryNodeVisible(self.activity_type)
    if not _isVisible then
        world_pos = gLobalActivityManager:getEntryArrowWorldPos()
    else
        local node_based = nil
        local state = self:getState()
        if state == EntryNodeConfig.NODE_STATE.NORMAL then
            node_based = self.open_flyNode
        elseif state == EntryNodeConfig.NODE_STATE.SMALL then
            node_based = self.close_flyNode
        else
            local errMsg = tostring(self.__cname) .. " getEffectEndPos 需要比配的新状态 " .. tostring(state)
            if isMac() then
                assert(nil, errMsg)
            else
                sendBuglyLuaException(errMsg)
            end
        end
        if not tolua.isnull(node_based) then
            local node_parent = node_based:getParent()
            local node_pos = {}
            node_pos.x, node_pos.y = node_based:getPosition()
            world_pos = node_parent:convertToWorldSpace(cc.p(node_pos.x, node_pos.y))
        else
            -- assert(nil, "getEffectEndPos 没有获取到正确结果")
            -- 没有获取到节点，则认为是隐藏了
            world_pos = gLobalActivityManager:getEntryArrowWorldPos()
        end
        
    end

    return self:getFlyActionParentNode():convertToNodeSpace(cc.p(world_pos.x, world_pos.y))
end

-- 展示收集特效
function EntryNodeBase:doCollectEffect()
    -- 获取目标点
    local startPos = self:getEffectStartPos()
    local endPos = self:getEffectEndPos()
    local effect_node_list = {}
    local do_collect = true
    for i = 1, self.effect_nums do
        local effect_node = cc.Sprite:create(self.fly_effect_name)
        if not tolua.isnull(effect_node) then
            effect_node:setVisible(false)
        end
        local addNode = self:getFlyActionParentNode()
        addNode:getParent():addChild(effect_node, 100000)
        effect_node:setPosition(startPos)

        table.insert(effect_node_list, effect_node)

        local time_per = math.random(1, 5) / 100
        local delay_time = (i - 1) * time_per
        local delay = cc.DelayTime:create(delay_time)
        local bezier = self:runEffectMoveAction(effect_node, startPos, endPos)
        effect_node:runAction(
            cc.Sequence:create(
                delay,
                bezier,
                cc.CallFunc:create(
                    function()
                        table.removebyvalue(effect_node_list, effect_node)
                        effect_node:removeSelf()

                        if not tolua.isnull(self) then
                            self:runItemPopAction()
                        end

                        if do_collect then
                            do_collect = false
                            -- 进度条涨
                            if not tolua.isnull(self) then
                                self:doProcessRiseUp()
                            end
                        end
                    end
                )
            )
        )
    end

    if self.is_rotation then
        self:updatePickRotation(effect_node_list)
    end
end

local moveTime = 1
local start_scale = 1.5
function EntryNodeBase:runEffectMoveAction(effect_node, startPos, endPos)
    -- 随机一个区域
    local off_1 = math.random(1, 200 * start_scale)
    local off_2 = math.random(1, 100 * start_scale)

    -- 这里给曲线匹配一个方向(相当于给原曲线做了一个轴对称的反转)
    local x_param = (endPos.x - startPos.x) / math.abs(endPos.x - startPos.x)
    local y_param = (endPos.y - startPos.y) / math.abs(endPos.y - startPos.y)
    -- 位移
    local control_1 = cc.p(startPos.x + 60 * x_param, startPos.y + (200 + off_1) * y_param)
    local control_2 = cc.p(endPos.x - 200 * x_param, endPos.y - (100 + off_2) * y_param)
    local bezierTo = cc.BezierTo:create(moveTime, {control_1, control_2, endPos})
    local ease = cc.EaseSineInOut:create(bezierTo)

    -- 缩放
    local scale_pre =
        cc.CallFunc:create(
        function()
            -- 节点的初始状态
            effect_node:setVisible(true)
            effect_node:setScale(start_scale)
        end
    )
    local scale1 = cc.ScaleTo:create(5 / 30, start_scale + 0.5)
    local scale2 = cc.ScaleTo:create(15 / 30, 1)
    local scale_delay = cc.DelayTime:create(10 / 30)
    local scale_seq = cc.Sequence:create(scale_pre, scale1, scale2, scale_delay)

    -- 透明度
    local opacity_pre =
        cc.CallFunc:create(
        function()
            effect_node:setOpacity(255)
        end
    )
    local opacity1 = cc.FadeTo:create(5 / 30, 255)
    local opacity_delay = cc.DelayTime:create(17 / 30)
    local opacity2 = cc.FadeTo:create(8 / 30, 0 * 255)
    local opacity_seq = cc.Sequence:create(opacity_pre, opacity1, opacity_delay, opacity2)

    local spawn = cc.Spawn:create(ease, scale_seq, opacity_seq)
    return spawn
end

function EntryNodeBase:updatePickRotation(effect_node_list)
    if not effect_node_list or table.nums(effect_node_list) <= 0 then
        return
    end
    if not self.effect_schedule then
        self.effect_schedule =
            util_schedule(
            self,
            function()
                if table.nums(effect_node_list) <= 0 then
                    self:stopAction(self.effect_schedule)
                    self.effect_schedule = nil
                    return
                end
                for k, effect_node in pairs(effect_node_list) do
                    if not effect_node.recordPos then
                        effect_node.recordPos = {}
                        effect_node.recordPos.x, effect_node.recordPos.y = effect_node:getPosition()
                    end
                    local pos = effect_node.recordPos

                    local pos_new = {}
                    pos_new.x, pos_new.y = effect_node:getPosition()
                    local distance = cc.pGetDistance(pos, pos_new)
                    if distance > 0 then
                        local angle = math.deg(math.asin((pos_new.y - pos.y) / distance))
                        if pos_new.x >= pos.x then
                            angle = (-angle)
                        end

                        effect_node:setRotation(angle)
                        effect_node.recordPos = pos_new
                    end
                end
            end,
            1 / 30
        )
    end
end

-- 收集特效飞行结束后 道具动一下
function EntryNodeBase:runItemPopAction()
    if self:getState() == EntryNodeConfig.NODE_STATE.SMALL then
        return
    end
    if not self.open_flyNode then
        return
    end
    self.open_flyNode:stopAllActions()
    self.open_flyNode:setScale(1)
    local scale1 = cc.ScaleTo:create(0.05, 1.2)
    local scale2 = cc.ScaleTo:create(0.05, 1)
    local seq = cc.Sequence:create({scale1, scale2})
    self.open_flyNode:runAction(seq)

    -- 坐标转换
    local node_pos = {}
    node_pos.x, node_pos.y = self.open_flyNode:getPosition()
    local world_pos = self.open_flyNode:getParent():convertToWorldSpace(cc.p(node_pos.x, node_pos.y))
    local endPos = self.root:convertToNodeSpace(cc.p(world_pos.x, world_pos.y))

    local effect_node = cc.Sprite:create(self.fly_effect_name)
    self.root:addChild(effect_node)
    effect_node:setPosition(endPos)
    local scale3 = cc.ScaleTo:create(0.1, 2)
    local fadeOut = cc.FadeOut:create(0.1)
    local spawn = cc.Spawn:create({scale3, fadeOut})
    local remove = cc.RemoveSelf:create()
    local seq1 = cc.Sequence:create({spawn, remove})
    effect_node:runAction(seq1)
end

local stepLength = 200 -- 刷新步长(上限10000 一步走200 相当于2%)
local stepTimer = 0.02 -- 刷新频率
-- 刷新结果
function EntryNodeBase:doProcessRiseUp()
    if table.nums(self.show_list) <= 0 then
        return
    end
    local cur_data = self.show_list[1]
    -- 缓存一份数据
    self.cur_data = clone(cur_data)
    table.remove(self.show_list, 1)

    local process_data = clone(cur_data)
    if not self.process_schedule then
        self.process_schedule =
            util_schedule(
            self,
            function()
                local cur_energy = math.floor(self.processTable[self.state].process:getPercent() / 100 * cur_data.energy_max)
                process_data.energy = cur_energy
                -- 只能进不能退 如果最大值小于当前值 则滚动到100
                if cur_data.energy < process_data.energy then
                    cur_data.record = cur_data.energy
                    cur_data.energy = cur_data.energy_max
                end

                local sub = cur_data.energy - process_data.energy
                local step = math.min(sub, stepLength)
                process_data.energy = process_data.energy + step
                self:updateProcess(process_data)

                -- -- 是否重新刷新进度条
                -- if process_data.energy == process_data.energy_max then
                --     if cur_data.record then
                --         cur_data.energy = cur_data.record
                --         process_data.energy = 0
                --         cur_data.record = nil
                --         -- 清空计时器
                --         self:stopAction(self.process_schedule)
                --         self.process_schedule = nil

                --         self:pauseAction(self.process_schedule)
                --         self:doProcessClear(function()
                --             self:resumeAction(self.process_schedule)
                --             if process_data.energy == cur_data.energy then
                --                 self:stopAction(self.process_schedule)
                --                 self.process_schedule = nil
                --                 -- 刷新下一组数据
                --                 self.onCollecting = false
                --                 self:collect()
                --             end
                --         end)
                --     end
                -- end

                -- 判断结束 长满或者涨到指定值
                printInfo("levelfly --- EntryNodeBase:doProcessRiseUp --- 1")
                if process_data.energy == cur_data.energy then
                    printInfo("levelfly --- EntryNodeBase:doProcessRiseUp --- 2")
                    self:stopAction(self.process_schedule)
                    self.process_schedule = nil
                    -- 刷新下一组数据
                    if process_data.energy == process_data.energy_max and process_data.num ~= process_data.num_max then
                        printInfo("levelfly --- EntryNodeBase:doProcessRiseUp --- 3")
                        self:doProcessClear(
                            function()
                                self.onCollecting = false
                                self:collect()
                            end
                        )
                    else
                        printInfo("levelfly --- EntryNodeBase:doProcessRiseUp --- 4")
                        self.onCollecting = false
                        self:collect()
                    end
                end
            end,
            stepTimer
        )
    end
end

function EntryNodeBase:updateProcess(cur_data)
    local process_tab = self.processTable[self.state]
    if not process_tab or not cur_data then
        return
    end
    local percent = math.floor(cur_data.energy / cur_data.energy_max * 100)

    -- 进度条
    local process_node = process_tab.process
    assert(process_node, "进度条节点丢失")
    if cur_data.num >= cur_data.num_max then
        process_node:setPercent(100)
    else
        process_node:setPercent(percent)
    end

    -- 进度条百分比
    local percent_node = process_tab.percent
    if percent_node then
        if cur_data.num >= cur_data.num_max then
            percent_node:setString("MAX")
        else
            percent_node:setString(percent .. "%")
        end
    end

    local num_node = process_tab.num
    if num_node then
        local visible = true
        if self:getState() == EntryNodeConfig.NODE_STATE.SMALL then
            visible = (cur_data.num > 0)
        end
        num_node:setVisible(visible)
        num_node:setString(cur_data.num)
    end

    if self.sp_num_close_bg then
        local visible = (cur_data.num > 0)
        self.sp_num_close_bg:setVisible(visible)
    end

    self:onProcessChanged()
end

-- TODO 进度条发生变化
function EntryNodeBase:onProcessChanged()
end

function EntryNodeBase:doProcessClear(end_call)
    local downNum = 10
    local curNum = 100
    local progressBar = self.processTable[self.state].process
    local percent = self.processTable[self.state].percent
    schedule(
        progressBar,
        function()
            curNum = curNum - downNum
            progressBar:setPercent(curNum)
            percent:setString(curNum .. "%")
            self:onProcessChanged()
            if curNum <= 0 then
                progressBar:stopAllActions()
                if end_call then
                    end_call()
                end
            end
        end,
        0.02
    )
end

-- 监测 有小红点或者活动进度满了
function EntryNodeBase:checkHadRedOrProgMax()
    local bHadRed = false
    if self.sp_num_close_bg then
        bHadRed = self.sp_num_close_bg:isVisible() 
    end
    local bProgMax = false
    if self.sp_process_close then
        bProgMax = self.sp_process_close:getPercent() >= 100
    end
    return {bHadRed, bProgMax}
end
-- 禁止 该入口 支持可展开状态
function EntryNodeBase:forbidEntryUnflodState(_bForbidUnflod)
    self._bForbidUnflod = _bForbidUnflod
end

return EntryNodeBase
