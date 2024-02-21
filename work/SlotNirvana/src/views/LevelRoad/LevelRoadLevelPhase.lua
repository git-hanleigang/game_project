-- 等级里程碑 等级阶段节点
local LevelRoadLevelPhase = class("LevelRoadLevelPhase", util_require("base.BaseView"))

function LevelRoadLevelPhase:initUI()
    LevelRoadLevelPhase.super.initUI(self)
    self:initView()
end

-- type : Swell: 膨胀系数 + 小游戏 Function: 解锁的功能 Item: 道具
function LevelRoadLevelPhase:initDatas(_params)
    local params = _params or {}
    self.m_phaseData = params.phaseData
    self.m_type = self.m_phaseData.type
    local curLevel = globalData.userRunData.levelNum
    self.m_isCanCollect = curLevel >= self.m_phaseData.level
end

function LevelRoadLevelPhase:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "LevelRoad/csd/Main_Portrait/LevelRoad_levelbar_levelphase_Portrait.csb"
    end
    return "LevelRoad/csd/LevelRoad_levelbar_levelphase.csb"
end

function LevelRoadLevelPhase:initCsbNodes()
    self.m_lb_level_phase = self:findChild("lb_level_phase")
end

function LevelRoadLevelPhase:onEnter()
    LevelRoadLevelPhase.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.m_isCanCollect then
                self:runCsbAction("over", false, nil, 60)
            end
        end,
        ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER
    )
end

function LevelRoadLevelPhase:initView()
    self:initLevel()
end

function LevelRoadLevelPhase:initLevel()
    self.m_lb_level_phase:setString("" .. self.m_phaseData.level)
    if globalData.slotRunData.isPortrait then
        self:updateLabelSize({label = self.m_lb_level_phase}, 90)
    end
end

return LevelRoadLevelPhase
