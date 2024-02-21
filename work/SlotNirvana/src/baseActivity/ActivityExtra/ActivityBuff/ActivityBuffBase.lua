-- 活动主界面 buff基类

local ActivityBuffController = util_require("baseActivity.ActivityExtra.ActivityBuff.ActivityBuffController")
local ActivityBuffBase = class("ActivityBuffBase", util_require("base.BaseView"))

-- buff刷新类型
ActivityBuffBase.REFRESH_TYPE = {
    NUMBER = "number",
    TIMER = "timer"
}

function ActivityBuffBase:initUI(activity_type, res, data)
    assert(activity_type, "ActivityBuffBase 活动类型不能为空")
    self.activity_type = activity_type
    self.data = data
    assert(res, "ActivityBuffBase 没有buffUI资源")
    self:createCsbNode(res)
    -- 读取节点
    self:readNodes()

    -- 初始化buff
    self.buff_list = self:getBuffList() -- buff列表
    assert(self.buff_list and next(self.buff_list), "ActivityBuffBase buff列表不能为空 " .. self.activity_type)

    local buff_common = self:getBuffCommon()
    if buff_common then
        self.buff_common_index = 0
        self.buff_list[self.buff_common_index] = buff_common
        self.has_state_common = true
    else
        self.has_state_common = false
    end

    -- 创建
    self.controller = ActivityBuffController:create(self)
    assert(self.controller, "控制器创建失败")
    self:addChild(self.controller)

    self:touchForbid(true)
end

function ActivityBuffBase:readNodes()
    self.sp_timeBg = self:findChild("sp_timeBg")
    -- assert(self.sp_timeBg, "ActivityBuffBase 倒计时背景板缺失 检查资源对应名称")

    self.btn_buff = self:findChild("btn_buff")
end

-- buff按钮
function ActivityBuffBase:getBtnBuff()
    return self.btn_buff
end

-- 时间背景
function ActivityBuffBase:getTimeBG()
    return self.sp_timeBg
end

-- 获取buff列表
function ActivityBuffBase:getBuffList()
    assert(false, "子类需要重写这个方法 获取buff列表")
end

-- TODO 子类重载这个方法 返回没buff状态事的UI表现
function ActivityBuffBase:getBuffCommon()
    -- 没buff状态
end

function ActivityBuffBase:getBuffEffect()
    -- 有buff时的特效
end

-- 获取buff数据
function ActivityBuffBase:getBuffData(id)
    local buff = self.buff_list[id]
    assert(buff, "不存在的buffid " .. id)
    if buff.type then
        if buff.type == self.REFRESH_TYPE.TIMER then
            local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(buff.get_data)
            local buffData = globalData.buffConfigData:getBuffDataByType(buff.get_data)
            if buffData and buffData.buffDuration then
                return leftTimes, buffData.buffDuration * 60
            end
        elseif buff.type == self.REFRESH_TYPE.NUMBER then
            local gameData = G_GetActivityDataByRef(self.activity_type)
            if not gameData or not gameData:isRunning() then
                print("ActivityBuffBase:getBuffData 活动结束了 " .. self.activity_type)
                return
            end

            local current = buff.get_data.current
            assert(gameData[current], "数据类必须实现 " .. current .. " 方法以获取当前buff显示数值")
            local max = buff.get_data.max
            assert(gameData[max], "数据类必须实现 " .. max .. " 方法以获取当前buff最大数值")

            return gameData[current](gameData), gameData[max](gameData)
        end
    end

    return nil
end

function ActivityBuffBase:runBuffAction(ani_name, call_func)
    assert(ani_name, "动画名称不存在")
    if ani_name then
        self:runCsbAction(
            ani_name,
            false,
            function()
                if call_func then
                    call_func()
                end
            end,
            30
        )
    else
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(2),
                cc.CallFunc:create(
                    function()
                        if call_func then
                            call_func()
                        end
                    end
                )
            )
        )
    end
end

function ActivityBuffBase:touchForbid(bl_forbid)
    self.btn_buff:setVisible(not bl_forbid)
    self.btn_buff:setTouchEnabled(not bl_forbid)
end

function ActivityBuffBase:isInActivity()
    return self.data.path == "in_activity"
end

function ActivityBuffBase:isInLevel()
    return self.data.path == "in_stage"
end

function ActivityBuffBase:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_buff" then
        if self:isInActivity() then
            gLobalNoticManager:postNotification(ViewEventType.BUFF_BTN_CLICKED)
        elseif self:isInLevel() then
            gLobalNoticManager:postNotification(ViewEventType.BUFF_BTN_CLICKED_IN_STAGE)
        end
        return
    end
end

function ActivityBuffBase:onEnter()
    -- 刷新时间buff
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not params or params.name ~= self.activity_type then
                return
            end
            for id, buff in ipairs(self.buff_list) do
                if buff and buff.type == self.REFRESH_TYPE.TIMER then
                    if self.controller then
                        self.controller:resetBuffState()
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_BUFF_REFRESH
    )

    -- 刷新必中buff
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not params or params.name ~= self.activity_type then
                return
            end
            for id, buff in ipairs(self.buff_list) do
                if buff and buff.type == self.REFRESH_TYPE.NUMBER then
                    if self.controller then
                        self.controller:resetBuffState()
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            for id, buff in ipairs(self.buff_list) do
                if buff and self.controller then
                    self.controller:resetBuffState()
                end
            end
        end,
        ViewEventType.NOTIFY_INFINITE_SALE_COLLECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            for id, buff in ipairs(self.buff_list) do
                if buff and self.controller then
                    self.controller:resetBuffState()
                end
            end
        end,
        ViewEventType.NOTIFY_INFINITE_SALE_BUY
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            for id, buff in ipairs(self.buff_list) do
                if buff and self.controller then
                    self.controller:resetBuffState()
                end
            end
        end,
        ViewEventType.NOTIFY_FUNCTION_SALE_PASS_COLLECT
    )

    -- 启动控制器
    self.controller:start()
    self:touchForbid(false)
end

function ActivityBuffBase:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return ActivityBuffBase
