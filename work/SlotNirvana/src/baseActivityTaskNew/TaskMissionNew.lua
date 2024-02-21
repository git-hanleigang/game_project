--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-06 10:53:26
    describe:新版大活动任务奖励节点
]]
local TaskMissionNew = class("TaskMissionNew", util_require("base.BaseView"))
local ActivityTaskManager = util_require("manager.ActivityTaskNewManager"):getInstance()

function TaskMissionNew:initUI(params)
    self.m_activityName = params.activityName
    self.m_data = params.data
    self.m_inx = params.inx
    self.m_missionRefreshSound = params.missionRefreshSound
    self:createCsbNode(params.missionCsb)
    self:initNode()
    self:initView()
end

--初始化节点
function TaskMissionNew:initNode()
    self.m_node_normal = self:findChild("node_normal")
    assert(self.m_node_normal, "普通任务节点为空")

    self.m_normal_number = self:findChild("lb_normal_number")
    assert(self.m_normal_number, "普通任务节点为空")
    self.m_normal_desc1 = self:findChild("lb_normal_desc1")
    assert(self.m_normal_desc1, "普通任务描述1节点为空")
    self.m_normal_desc2 = self:findChild("lb_normal_desc2")
    assert(self.m_normal_desc2, "普通任务描述2节点为空")
    self.m_normal_desc3 = self:findChild("lb_normal_desc3")
    assert(self.m_normal_desc3, "普通任务描述3节点为空")
    self.m_normal_progress = self:findChild("sp_normal_progress")
    assert(self.m_normal_progress, "普通任务进度条节点为空")
    self.m_lb_normal_progress = self:findChild("lb_normal_progress")
    assert(self.m_lb_normal_progress, "普通任务进度条文本节点为空")
end

function TaskMissionNew:initView(isAni)
    if self.m_data then
        if not isAni then
            self:runCsbAction("idle", true, nil, 60)
        end
        self:initTitle()
        self:initPoints()
        self:initProgress()
    end
end

-- 初始化描述
function TaskMissionNew:initTitle()
    local lineNum, lineStrVec = util_AutoLine(self.m_normal_desc1, self.m_data.description, 194, true)
    for i = 1, 3 do
        local label = self["m_normal_desc" .. i]
        if i <= lineNum then
            label:setString("" .. lineStrVec[i])
        else
            label:setString("")
        end
    end
    
    -- 根据行数调整位置
    if lineNum == 1 then
        local label = self.m_normal_desc1
        label:setPositionY(30)
    elseif lineNum <= 3 then
        for i = 1, lineNum do
            local label = self["m_normal_desc" .. i]
            if label then
                label:setPositionY((3 - lineNum) * 10 + 30 * (lineNum - i))
            end
        end
    end
end

-- 初始化完成该任务可获得的点数
function TaskMissionNew:initPoints()
    self.m_normal_number:setString("" .. self.m_data.points)
end

-- 初始化进度
function TaskMissionNew:initProgress()
    local process = self.m_data.process / self.m_data.param * 100
    local processStr = util_formatCoins(self.m_data.process, 3, true)
    local paramStr = util_formatCoins(self.m_data.param, 3, true)

    self.m_normal_progress:setPercent(process)
    self.m_lb_normal_progress:setString(processStr .. "/" .. paramStr)
end

-- 进度动画
function TaskMissionNew:playProgressAction(_cb)
    local completeTaskList = ActivityTaskManager:getInstance():getAniTaskList(self.m_activityName)
    if #completeTaskList > 0 then
        for i = 1, #completeTaskList do
            if self.m_inx == completeTaskList[i].index then
                self:increaseProgressAction(_cb)
            end
        end
    end
end

-- 进度增长动画
function TaskMissionNew:increaseProgressAction(_cb)
    local intervalTime = 1 / 60
    local curPercent = self.m_normal_progress:getPercent()
    local time = 0.5 * 60
    local speed = (100 - curPercent) / time
    if self.m_sheduleHandle then
        self:stopAction(self.m_sheduleHandle)
        self.m_sheduleHandle = nil
    end

    self.m_sheduleHandle =
        schedule(
        self,
        function()
            local curPercent = self.m_normal_progress:getPercent()
            if curPercent < 100 then
                curPercent = curPercent + speed
                self.m_normal_progress:setPercent(curPercent)
            else
                if self.m_sheduleHandle then
                    self:stopAction(self.m_sheduleHandle)
                    self.m_sheduleHandle = nil
                end
                local paramStr = util_formatCoins(self.m_data.param, 3, true)
                self.m_normal_progress:setPercent(100)
                self.m_lb_normal_progress:setString(paramStr .. "/" .. paramStr)

                self:runCsbAction(
                    "start",
                    false,
                    function()
                        self:runCsbAction("idle", true, nil, 60)
                    end,
                    60
                )

                performWithDelay(
                    self,
                    function()
                        if not tolua.isnull(self) then
                            self:playParticle()
                        end
                    end,
                    35 / 60
                )
                if _cb then
                    _cb()
                end
            end
        end,
        intervalTime
    )
end

function TaskMissionNew:updateView(_data)
    if _data then
        self.m_data = _data
        self.m_isUpdate = true
        if self.m_missionRefreshSound and type(self.m_missionRefreshSound) == "string" then
            gLobalSoundManager:playSound(self.m_missionRefreshSound)
        end
        self:runCsbAction(
            "start2",
            false,
            function()
                self:runCsbAction("idle", true, nil, 60)
            end,
            60
        )
        performWithDelay(
            self,
            function()
                self:initView(true)
            end,
            10 / 60
        )
    end
end

-- 播放粒子
function TaskMissionNew:playParticle()
    for i = 1, 3 do
        local lizi = self:findChild("ef_lizi" .. i)
        if lizi then
            lizi:resetSystem()
        end
    end
end

return TaskMissionNew
