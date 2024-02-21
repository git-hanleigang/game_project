--[[
    等级里程碑 左边条入口
]]
local LevelRoadEntryNode = class("LevelRoadEntryNode", BaseView)

local BUBBLE_TYPE = {
    SWELL = "Swell", -- 膨胀系数 + 小游戏
    FUNCTION = "Function", -- 解锁的功能
    ITEM = "Item", -- 道具
    ULOCK_GAME = "Game", -- 解锁关卡
}

function LevelRoadEntryNode:getCsbName()
    return "LevelRoad/csd/LevelRoad_entryNode.csb"
end

function LevelRoadEntryNode:initDatas()
    self.m_data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    self.m_scheduleTimer = 0
    self.m_rewardIconIndex = 1
    self.m_rewardInfoList = {}
end

function LevelRoadEntryNode:initCsbNodes()
    self.m_sp_icon = self:findChild("sp_icon")
    self.m_lb_level_num = self:findChild("lb_level_num")
    local touch = self:findChild("touch")
    self:addClick(touch)
end

function LevelRoadEntryNode:initUI()
    LevelRoadEntryNode.super.initUI(self)

    self:initProgress()
    self:initNextPhaseLevel()
    self:initRewardList()
    self:initPercentage(true)
    self:initScheduleTimer()
    self:runCsbAction("idle", true)
end

function LevelRoadEntryNode:initNextPhaseLevel()
    if self.m_data then
        local level = self.m_data:getNextPhaseLevel()
        self.m_lb_level_num:setString("" .. level)
        self:updateLabelSize({label = self.m_lb_level_num}, 32)
    end
end

function LevelRoadEntryNode:initProgress()
    -- 创建进度条
    local img = util_createSprite("LevelRoad/ui/entry/LevelRoad_entry_tiao.png")
    local sp_bar = self:findChild("sp_bar")
    self.m_bar_pool = cc.ProgressTimer:create(img)
    self.m_bar_pool:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_bar_pool:setPercentage(0)
    self.m_bar_pool:setPosition(sp_bar:getPosition())
    self.m_bar_pool:setRotation(180)
    sp_bar:getParent():addChild(self.m_bar_pool, 1)
    sp_bar:setVisible(false)
end

function LevelRoadEntryNode:initPercentage(_init)
    if self.m_data then
        local userLevel = globalData.userRunData.levelNum
        local preLevel = self.m_data:getPreviousPhaseLevel()
        local nextLevel = self.m_data:getNextPhaseLevel()
        local ratio = ((userLevel - preLevel) / (nextLevel - preLevel)) * 100
        if _init then
            self.m_bar_pool:setPercentage(ratio)
        else
            self:increaseProgressAction(ratio)
        end
    end
end

-- 进度增长动画
function LevelRoadEntryNode:increaseProgressAction(_ratio)
    local curRatio = self.m_bar_pool:getPercentage()
    local ratio = _ratio
    if curRatio >= ratio then
        ratio = 100
    end
    self.m_curRatio = curRatio
    local intervalTime = 1 / 30
    -- 根据不同情况可以设置不同的速度
    local sppeedTiem = 0.2
    -- 增长速度
    local speedVal = ratio - curRatio
    speedVal = speedVal * intervalTime / sppeedTiem
    if not self.m_sheduleHandle then
        self.m_sheduleHandle =
            schedule(
            self,
            function()
                if self.m_curRatio < ratio then
                    local newRatio = math.min(self.m_curRatio + speedVal, ratio)
                    self.m_curRatio = newRatio
                    self.m_bar_pool:setPercentage(newRatio)
                else
                    if self.m_sheduleHandle then
                        self:stopAction(self.m_sheduleHandle)
                        self.m_sheduleHandle = nil
                    end
                    self.m_bar_pool:setPercentage(_ratio)
                end
            end,
            intervalTime
        )
    end
end

function LevelRoadEntryNode:initRewardList()
    if self.m_data then
        self.m_rewardInfoList = {}
        local nextPhaseReward = self.m_data:getNextPhaseReward()
        local type = nextPhaseReward.type or ""
        if type == BUBBLE_TYPE.SWELL then
            local items = nextPhaseReward.items or {}
            if #items > 0 then
                for i, v in ipairs(items) do
                    if string.find(v.p_icon, "MiniGame") then
                        local iconPath = "PBRes/CommonItemRes/icon/" .. items[1].p_icon .. ".png"
                        table.insert(self.m_rewardInfoList, {iconPath = iconPath, scale = 0.6})
                    end
                end
            end
        elseif type == BUBBLE_TYPE.FUNCTION then
            local unLock = nextPhaseReward.unLock or {}
            local len = #unLock
            for i = 1, len do
                local iconName = unLock[i]
                local iconPath = "LevelRoad/icon/" .. iconName .. ".png"
                table.insert(self.m_rewardInfoList, {iconPath = iconPath, scale = 0.24})
            end
        elseif type == BUBBLE_TYPE.ITEM then
            local items = nextPhaseReward.items or {}
            if #items > 0 then
                for i, v in ipairs(items) do
                    local iconPath = "PBRes/CommonItemRes/icon/" .. v.p_icon .. ".png"
                    table.insert(self.m_rewardInfoList, {iconPath = iconPath, scale = 0.6})
                end
            end
        elseif type == BUBBLE_TYPE.ULOCK_GAME then
            local iconPath = "LevelRoad/icon/newGameUlock.png"
            table.insert(self.m_rewardInfoList, {iconPath = iconPath, scale = 0.6})
        end
        if #self.m_rewardInfoList > 0 then
            self.m_sp_icon:setScale(self.m_rewardInfoList[1].scale)
            util_changeTexture(self.m_sp_icon, self.m_rewardInfoList[1].iconPath)
        end
    end
end

function LevelRoadEntryNode:refreshUI()
    self.m_scheduleTimer = 0
    self.m_rewardIconIndex = 1
    self:initNextPhaseLevel()
    self:initPercentage()
    self:initRewardList()
end

function LevelRoadEntryNode:clickFunc(sender)
    G_GetMgr(G_REF.LevelRoad):showMainLayer()
end

function LevelRoadEntryNode:getPanelSize()
    return {widht = 100, height = 100}
end

function LevelRoadEntryNode:onEnter()
    LevelRoadEntryNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:refreshUI()
            if not G_GetMgr(G_REF.LevelRoad):isCanShowEntryNode() then
                gLobalActivityManager:removeActivityEntryNode(G_REF.LevelRoad)
            end
        end,
        ViewEventType.SHOW_LEVEL_UP
    )
end

--显示倒计时
function LevelRoadEntryNode:initScheduleTimer()
    self:stopScheduleTimer()
    self.timerAction = schedule(self, handler(self, self.onScheduleTimer), 1)
    self:onScheduleTimer()
end

function LevelRoadEntryNode:onScheduleTimer()
    if #self.m_rewardInfoList > 1 then
        self.m_scheduleTimer = self.m_scheduleTimer + 1
        if self.m_scheduleTimer > 5 then
            self.m_scheduleTimer = 0
            self.m_rewardIconIndex = self.m_rewardIconIndex + 1
            if self.m_rewardIconIndex > #self.m_rewardInfoList then
                self.m_rewardIconIndex = 1
            end
            self:playSwitchAnimation()
        end
    end
end

function LevelRoadEntryNode:stopScheduleTimer()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function LevelRoadEntryNode:playSwitchAnimation()
    self:runCsbAction(
        "switch1",
        false,
        function()
            local info = self.m_rewardInfoList[self.m_rewardIconIndex]
            if info then
                self.m_sp_icon:setScale(info.scale)
                util_changeTexture(self.m_sp_icon, info.iconPath)
            end
            self:runCsbAction(
                "switch2",
                false,
                function()
                    self:runCsbAction("idle", true)
                end,
                60
            )
        end,
        60
    )
end

-- 监测 有小红点或者活动进度满了
function LevelRoadEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    local bProgMax = false
    if self.m_bar_pool then
        bProgMax = self.m_bar_pool:getPercentage() >= 100
    end
    return {bHadRed, bProgMax}
end

return LevelRoadEntryNode
