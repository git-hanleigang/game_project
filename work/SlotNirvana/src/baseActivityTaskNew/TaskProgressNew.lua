--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-05 18:24:58
    describe:新版大活动任务进度条
]]
local TaskProgressNew = class("TaskProgressNew", util_require("base.BaseView"))
local ActivityTaskManager = util_require("manager.ActivityTaskNewManager"):getInstance()

local MaxWidth = 3000 -- 根据效果图决定的总长度

function TaskProgressNew:initUI(_params)
    self.m_rewardCsbName = _params.rewardCsbName
    self.m_activityName = _params.activityName
    self.m_rewardNodeSpineName = _params.rewardNodeSpineName
    self.m_flowerOpenSound = _params.flowerOpenSound
    self.m_rewardWidth = _params.rewardWidth
    self.m_rewardBubbleWidth = _params.rewardBubbleWidth
    self:createCsbNode(_params.proCsbName)
    self:initData()
    self:initNode()
    self:initView()
end

function TaskProgressNew:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local data = ActivityTaskManager:getTaskDataByActivityName(self.m_activityName)
            local list = data:getStageRewardList()
            for i = 1, #list do
                local info = list[i]
                local rewardNode = self.m_rewardNodeList[i].node
                if rewardNode then
                    rewardNode:refreshShow(info)
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS
    )
end

--初始化数据
function TaskProgressNew:initData()
    self.m_taskDataObj = ActivityTaskManager:getTaskDataByActivityName(self.m_activityName)
    -- self.m_ratio = self:GetPreciseDecimal(MaxWidth / self.m_taskDataObj:getTotalPoints(), 1) --进度条长度与总点数的比值
    self.m_ratio = MaxWidth / self.m_taskDataObj:getTotalPoints()
    local maxWidth = self:caculateProgressLen()
    local len = #self.m_taskDataObj:getStageRewardList() or 1
    self.m_singleWidth = maxWidth / len --单个进度条长度

    local point = math.max((self.m_taskDataObj:getCurrentPoints() - self:getRisePoint()), 0)
    local ratio = self.m_taskDataObj:getRatio(point)
    self.m_curProgressLen = self.m_singleWidth * ratio --当前进度条长度

    self.m_rewardNodeList = {}
    self.m_progressLabelList = {}
end

--初始化节点
function TaskProgressNew:initNode()
    self.m_scrollView = self:findChild("ScrollView")
    assert(self.m_scrollView, "滚动容器为空")
    self.m_progress_bg = self:findChild("img_progress_bg")
    assert(self.m_progress_bg, "进度条背景为空")
    self.m_progress = self:findChild("img_progress")
    assert(self.m_progress, "进度条为空")

    self.m_node_spine = self:findChild("node_spine")
    -- assert(self.m_node_spine, "spine节点为空")
    self.m_lb_number = self:findChild("lb_number")
    assert(self.m_lb_number, "文本节点为空")
end

--idle
function TaskProgressNew:runIdle()
    self:runCsbAction("idle", true, nil, 60)
end

--进度条满
function TaskProgressNew:runIdle2()
    self:runCsbAction("idle2", true, nil, 60)
end

function TaskProgressNew:initView()
    self:addItems()
    self:initProgress()
    self:initLabel()
end

function TaskProgressNew:initLabel()
    local spineName = self.m_rewardNodeSpineName
    if spineName and self.m_node_spine then
        self.m_spine = util_spineCreate(spineName, false, true, 1)
        self.m_node_spine:addChild(self.m_spine)
        util_spinePlay(self.m_spine, "idle1", true)
    end

    local curPoint = self.m_taskDataObj:getCurrentPoints()
    if self.m_taskDataObj:getCompleted() then
        curPoint = 0
    end
    self.m_lb_number:setString("" .. curPoint)
end

--初始化进度条
function TaskProgressNew:initProgress()
    local maxWidth = self:caculateProgressLen()
    local bgOriSize = self.m_progress_bg:getContentSize()
    self.m_progress_bg:setContentSize(maxWidth, bgOriSize.height)
    self.m_scrollView:setScrollBarEnabled(false)

    -- 优化：scrollview总长度 = 第一个奖励的圆圈长度的一半 + 进度条长度 + 最后一个奖励的气泡的长度的一半
    self.m_scrollView:setInnerContainerSize(cc.size(maxWidth + self.m_rewardWidth/2 + self.m_rewardBubbleWidth/2, 300))
    self.m_scrollView:setSwallowTouches(false)

    self.m_scrollViewSize = self.m_scrollView:getContentSize()
    self.m_innerNodeSize = self.m_scrollView:getInnerContainerSize()
    self.m_subWidth = self.m_innerNodeSize.width - self.m_scrollViewSize.width
    self:updateProgress()
end

-- 计算出progressBar总长度
function TaskProgressNew:caculateProgressLen()
    local progressLen = 0
    local totalScore = self.m_taskDataObj:getTotalPoints() * self.m_ratio
    if totalScore then
        progressLen = totalScore
    end
    return progressLen
end

-- 更新中间的进度条显示 --
function TaskProgressNew:updateProgress()
    local curWidth = self.m_curProgressLen or 0

    local _size = self.m_progress:getContentSize()
    local maxWidth = self:caculateProgressLen()

    -- 优化：scrollview总长度算对了，所以这里的20偏移量可以删除了
    _size.width = math.min(curWidth, maxWidth)
    self.m_progress:setContentSize(_size)

    local precent = (curWidth - self.m_scrollViewSize.width * 0.5) / self.m_subWidth * 100
    precent = math.min(math.max(0, precent), 100)
    self.m_scrollView:jumpToPercentHorizontal(precent)
end

--增加完成一轮初始化
function TaskProgressNew:updateUI()
    self.m_curProgressLen = 0
    self:updateProgress()
    for i = 1, #self.m_rewardNodeList do
        local rewardNode = self.m_rewardNodeList[i].node
        if rewardNode then
            rewardNode:updateUI()
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_UI)
end

--解锁动画
function TaskProgressNew:unLockAct(width)
    if not self.m_taskDataObj then
        return
    end
    local list = self.m_taskDataObj:getStageRewardList()
    local lastNeedPoint = 0
    for i = 1, #list do
        local info = list[i]
        if self.m_rewardNodeList[i].isCheck then
            -- local labNode = self.m_progressLabelList[i]
            local rewardNode = self.m_rewardNodeList[i].node
            if width >= self.m_singleWidth * i then
                self.m_rewardNodeList[i].isCheck = false
                rewardNode:playCheckAction()
            -- local point = info.needPoints - lastNeedPoint
            -- local str = point .. "/" .. point
            -- labNode:playUnlock(function()
            --     labNode:setLabelString(str)
            -- end)
            -- else
            --     if lastNeedPoint * self.m_ratio < width then
            --         local curPoint = math.floor(width / self.m_ratio)
            --         local proStr = (curPoint - lastNeedPoint) .. "/" .. (info.needPoints - lastNeedPoint)
            --         labNode:playUnlock()
            --         labNode:setLabelString(proStr)
            --     end
            end
        end
        -- lastNeedPoint = info.needPoints
    end
end

-- 进度增长动画
function TaskProgressNew:increaseProgressAction()
    local intervalTime = 1 / 60
    local ratio = self.m_taskDataObj:getRatio()
    print("ratio--------------",ratio)
    -- 最新的当前长度
    local curProgressLen = self.m_singleWidth * ratio
    curProgressLen = math.min(self:caculateProgressLen(), curProgressLen)
    -- 根据不同情况可以设置不同的速度
    local sppeedTiem = 1
    -- 增长速度
    local speedVal = curProgressLen - self.m_curProgressLen
    speedVal = speedVal * intervalTime / sppeedTiem

    if self.m_sheduleHandle then
        self:stopAction(self.m_sheduleHandle)
        self.m_sheduleHandle = nil
    end
    print("curProgressLen--------------",curProgressLen)
    print("self.m_curProgressLen--------------",self.m_curProgressLen)

    self.m_sheduleHandle =
        schedule(
        self,
        function()
            if self.m_curProgressLen < curProgressLen then
                local newProgressLen = math.min(self.m_curProgressLen + speedVal, curProgressLen)
                self.m_curProgressLen = newProgressLen
                self:updateProgress()
                self:unLockAct(newProgressLen)
            else
                if self.m_sheduleHandle then
                    self:stopAction(self.m_sheduleHandle)
                    self.m_sheduleHandle = nil
                end
                self:setScrollTouch(true)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASKNEW_ACTION_FINISH)
            end
        end,
        intervalTime
    )
end

-- 获得要增长的进度
function TaskProgressNew:getRisePoint()
    local completeTaskList = ActivityTaskManager:getInstance():getAniTaskList(self.m_activityName)
    local point = 0
    if #completeTaskList > 0 then
        for i = 1, #completeTaskList do
            point = point + completeTaskList[i].data.points
        end
    end
    return point
end

--添加道具
function TaskProgressNew:addItems()
    if self.m_taskDataObj then
        -- local totalWidth = self:caculateProgressLen()
        -- local totalScore = self.m_taskDataObj:getTotalPoints()
        local curPoint = math.max((self.m_taskDataObj:getCurrentPoints() - self:getRisePoint()), 0)
        local list = self.m_taskDataObj:getStageRewardList()
        -- local lastPos = 0
        -- local lastNeedPoint = 0
        -- local proStr = ""
        for i = 1, #list do
            local info = list[i]
            local params = {
                csbName = self.m_rewardCsbName,
                data = info,
                spineName = self.m_rewardNodeSpineName,
                flowerOpenSound = self.m_flowerOpenSound
            }
            local rewardNode = util_createView("baseActivityTaskNew.TaskRewardNodeNew", params)
            self.m_scrollView:addChild(rewardNode)
            local posX = self.m_rewardWidth/2 + self.m_singleWidth * i --info.needPoints / totalScore * totalWidth
            local posY = self.m_scrollView:getContentSize().height / 2
            rewardNode:setPosition(posX, posY)
            local isCheck = curPoint <= info.needPoints
            if info.collect then
                isCheck = false
            end
            table.insert(self.m_rewardNodeList, {node = rewardNode, isCheck = isCheck})
            -- if curPoint > info.needPoints then
            --     local point = info.needPoints - lastNeedPoint
            --     proStr = point .. "/" .. point
            -- else
            --     isCheck = true
            --     if lastNeedPoint <= curPoint then
            --         proStr = (curPoint - lastNeedPoint) .. "/" .. (info.needPoints - lastNeedPoint)
            --     else
            --         proStr = "LOCKED"
            --     end
            -- end
            -- table.insert(self.m_rewardNodeList, {node = rewardNode, isCheck = isCheck})

            -- local params = {csbName = self.m_lockCsbName, data = info, proStr = proStr}
            -- local lockNode = util_createView("baseActivityTaskNew.TaskProgressLockNew", params)
            -- lockNode:setPosition(lastPos + (posX - lastPos) / 2 - 10, posY)
            -- self.m_scrollView:addChild(lockNode)
            -- table.insert(self.m_progressLabelList, lockNode)

            -- lastPos = posX
            -- lastNeedPoint = info.needPoints
        end
    end
end

function TaskProgressNew:setScrollTouch(val)
    self.m_scrollView:setTouchEnabled(val)
end

--粒子飞到的位置
function TaskProgressNew:getTargetPos()
    if self.m_taskDataObj then
        local list = self.m_taskDataObj:getStageRewardList()
        local inx = 1
        for i = 1, #list do
            local info = list[i]
            if info.finish == true and info.collect == true then
            else
                inx = i
                break
            end
        end
        local pos =
            self.m_rewardNodeList[inx].node:getParent():convertToWorldSpace(
            cc.p(self.m_rewardNodeList[inx].node:getPosition())
        )
        return pos
    end
    return nil
end

--- nNum 源数字
--- n 小数位数
function TaskProgressNew:GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum
    end
    n = n or 0
    n = math.floor(n)
    if n < 0 then
        n = 0
    end
    local nDecimal = 10 ^ n
    local nTemp = math.floor(nNum * nDecimal)
    local nRet = nTemp / nDecimal
    return nRet
end

function TaskProgressNew:hideParticles()
    if self.m_rewardNodeList and #self.m_rewardNodeList > 0 then
        for i,v in ipairs(self.m_rewardNodeList) do
            if not tolua.isnull(v.node) then
                v.node:hidePartiicles()
            end
        end
    end
end

return TaskProgressNew
