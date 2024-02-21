-- 活动buff控制器 buff切换显示

-- 活动状态
local BUFF_STATE = {
    INACTIVE = "inactive", -- 未激活
    ACTIVE = "active" -- 激活
}

-- 动作类型
local ACTION_TYPE = {
    HIDE = "hide",
    SHOW = "show"
}

local ActivityBuffController = class("ActivityBuffController", cc.Node)

function ActivityBuffController:ctor(buff_node)
    assert(buff_node, "ActivityBuffController buffUI节点不存在")
    self.buff_node = buff_node

    self.buff_min_id = 999 -- buff初始数组下标
    self.buff_count = 0 -- 当前buff数组下标
    self.ani_count = 0 -- 动画循环次数 循环3次以后 切换下一个buff
    -- 组装buff列表
    self:initBuffList()
end

function ActivityBuffController:initBuffList()
    assert(self.buff_node.buff_list, "buff列表不存在")
    -- 组装buff列表
    for id, buff in pairs(self.buff_node.buff_list) do
        if self.buff_min_id > id then
            self.buff_min_id = id
        end
        -- 设置buff初始状态
        self.buff_node.buff_list[id].state = BUFF_STATE.INACTIVE
        -- 检查数据源
        if self.buff_node.buff_list[id].type then
            assert(self.buff_node.buff_list[id].get_data, "ActivityBuffController buff数据源缺失 " .. id)
        end
        self:buffHide(id, true)
    end
end

function ActivityBuffController:start()
    -- 初始id
    self.buff_count = self.buff_min_id
    -- 显示buff
    self:resetBuffState()
    self:showNext()
end

-- 刷新buff
function ActivityBuffController:resetBuff(id)
    local buff = self.buff_node.buff_list[id]
    if not buff then
        return
    end

    -- 更新buff
    buff.state = BUFF_STATE.INACTIVE
    local left, max = self.buff_node:getBuffData(id)

    if left and max and left > 0 and max > 0 then
        if left > 0 then
            -- 刷新buff状态
            buff.state = BUFF_STATE.ACTIVE
        end

        -- 刷新倒计时
        if buff.timer then
            if buff.type and buff.type == self.buff_node.REFRESH_TYPE.TIMER then
                buff.timer:setString(util_count_down_str(left))
            else
                buff.timer:setString(left)
            end
        end
        -- 刷新进度条
        if buff.process then
            buff.process:setPercent(left / max * 100)
        end
    else
        -- 刷新倒计时
        if buff.timer then
            buff.timer:setString("")
        end
        -- 刷新进度条
        if buff.process then
            buff.process:setPercent(0)
        end
    end
    return buff.state
end

-- 刷新没有buff的UI表现
function ActivityBuffController:resetBuffStateForNormal()
    if self.buff_node.has_state_common == true then
        -- 默认buff显示激活
        self.buff_node.buff_list[self.buff_node.buff_common_index].state = BUFF_STATE.ACTIVE
    else
        for id, buff in pairs(self.buff_node.buff_list) do
            buff.state = BUFF_STATE.ACTIVE
        end
    end
    return not self.buff_node.has_state_common
end

-- 刷新buff列表
function ActivityBuffController:resetBuffState()
    local has_buff = false
    for id, buff in pairs(self.buff_node.buff_list) do
        local bl_state = self:resetBuff(id)
        if bl_state and bl_state == BUFF_STATE.ACTIVE then
            has_buff = true
        end
    end

    -- 根据buff 显示计时器背景
    local timerBg = self.buff_node:getTimeBG()
    if timerBg then
        timerBg:setVisible(has_buff)
    end

    if has_buff == false then
        has_buff = self:resetBuffStateForNormal()
    end

    -- 刷新计时器
    if has_buff then
        -- 启动计时器
        if not self.buff_schedule then
            self.buff_schedule = util_schedule(self, self.resetBuffState, 1)
        end
        -- 有buff激活 显示buff
        if (self.buff_node.has_state_common == true and self.buff_count == self.buff_node.buff_common_index) or self.buff_node.buff_list[self.buff_count].state == BUFF_STATE.INACTIVE then
            self:showNext()
        end
    else
        if self.buff_schedule then
            self:stopAction(self.buff_schedule)
            self.buff_schedule = nil
        end
        -- 所有buff都失效了 显示默认
        if self.buff_node.has_state_common == true and self.buff_count ~= self.buff_node.buff_common_index then
            self:showNext()
        end
    end
end

-- 显示下一个buff
function ActivityBuffController:showNext()
    assert(self.buff_node.buff_list, "ActivityBuffController:showNext buff列表为空")
    local max = table.nums(self.buff_node.buff_list)
    local cur_count = self.buff_count
    local new_count = self.buff_count
    while true do
        new_count = new_count + 1
        if new_count > max then
            new_count = self.buff_min_id
        end

        if self.buff_node.buff_list[new_count] and self.buff_node.buff_list[new_count].state == BUFF_STATE.ACTIVE or new_count == cur_count then
            self.buff_count = new_count
            self:runBuffChangeAction(cur_count, new_count)
            break
        end
    end
end

function ActivityBuffController:runBuffChangeAction(pre_buffIdx, next_buffIdx)
    if pre_buffIdx == next_buffIdx or (pre_buffIdx == self.buff_common_index and self.buff_count.has_state_common == true) then
        for i, buff in pairs(self.buff_node.buff_list) do
            assert(buff and buff.node, "这是一个无效的点 " .. i)
            if next_buffIdx == i then
                self:buffShow(i, true)
            else
                self:buffHide(i, true)
            end
        end
        self:runBuffAction()
    else
        self:buffHide(pre_buffIdx)
        self:buffShow(
            next_buffIdx,
            false,
            function()
                self:runBuffAction()
                self:onBuffShow()
            end
        )
    end
end

function ActivityBuffController:buffHide(id, bl_force, end_call)
    self:buffChangeAction(id, ACTION_TYPE.HIDE, bl_force, end_call)
end

function ActivityBuffController:buffShow(id, bl_force, end_call)
    self:buffChangeAction(id, ACTION_TYPE.SHOW, bl_force, end_call)
end

function ActivityBuffController:buffChangeAction(id, act_type, bl_force, end_call)
    if not id then
        return
    end

    if bl_force == nil then
        bl_force = false
    end

    assert(self.buff_node.buff_list and self.buff_node.buff_list[id] and self.buff_node.buff_list[id].node, "执行动作的节点不存在 " .. id)

    -- 记录当前buff序列号
    self:setBuffIdx(id)

    local node_buff = self.buff_node.buff_list[id].node
    node_buff:setVisible(true)
    node_buff:stopAllActions()
    if bl_force == true then
        if act_type == ACTION_TYPE.HIDE then
            node_buff:setOpacity(0)
            node_buff:setVisible(false)
        elseif act_type == ACTION_TYPE.SHOW then
            node_buff:setOpacity(255)
        end
    else
        local act = nil
        if act_type == ACTION_TYPE.HIDE then
            act = cc.FadeOut:create(0.8)
        elseif act_type == ACTION_TYPE.SHOW then
            act = cc.FadeIn:create(0.8)
        end
        local visible =
            cc.CallFunc:create(
            function()
                if act_type == ACTION_TYPE.HIDE then
                    node_buff:setVisible(false)
                end
            end
        )
        node_buff:runAction(
            cc.Sequence:create(
                cc.EaseSineIn:create(act),
                visible,
                cc.CallFunc:create(
                    function()
                        if end_call and type(end_call) == "function" then
                            end_call()
                        end
                    end
                )
            )
        )
    end
end

-- buff动画
function ActivityBuffController:runBuffAction()
    if self.bl_running then
        return
    end
    self.bl_running = true
    local ani_name = self.buff_node.buff_list[self.buff_count].ani
    local strs = string.split(ani_name, "|")
    local ani_name_use = strs[1]
    if self.m_useSpecial and strs[2] then
        ani_name_use = strs[2]
    end
    if ani_name_use ~= "idle" then
        local a =1
    end
    self.buff_node:runBuffAction(
        ani_name_use,
        function()
            self.bl_running = false
            self:onBuffActionOver()
        end
    )
end

function ActivityBuffController:onBuffActionOver()
    if self.ani_count == 2 then
        self.ani_count = 0
        self.m_useSpecial = false
        self:showNext()
    else
        self.ani_count = self.ani_count + 1
        self:runBuffAction()
    end
end

function ActivityBuffController:setBuffIdx(id)
    self.cur_buffId = id
end

function ActivityBuffController:getBuffIdx()
    return self.cur_buffId or 0
end

function ActivityBuffController:onBuffShow()
    local effectNode, effectAct = self.buff_node:getBuffEffect()
    if not effectNode or not effectAct then
        return
    end

    if self:getBuffIdx() == self.buff_common_index then
        effectNode:setVisible(false)
        if effectAct:isPlaying() then
            effectAct:pause()
        end
    else
        effectNode:setVisible(true)
        if not effectAct:isPlaying() then
            util_csbPlayForKey(effectAct, "idle", true, nil, 60)
        end
    end
end

return ActivityBuffController
