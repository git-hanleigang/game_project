--背景霓虹灯
local LevelRoadExpTip = class("LevelRoadExpTip", util_require("base.BaseView"))

function LevelRoadExpTip:initUI(isLobbyView)
    local csbName = "LevelRoad/csd/Level_Exp/LevelRoad_Exp_1.csb"

    if isLobbyView == true then
        csbName = "LevelRoad/csd/Level_Exp/LevelRoad_Exp_3.csb"
    elseif globalData.slotRunData:isFramePortrait() then
        csbName = "LevelRoad/csd/Level_Exp/LevelRoad_Exp_2.csb"
    end

    self:createCsbNode(csbName)
    self.lbs_leftLevel = self:findChild("lbs_leftLevel")
    self:runCsbAction("animation0", true)
    self:updateLevel()
end

function LevelRoadExpTip:updateLevel()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if not data then
        return
    end
    local nextPhaseLevel = data:getNextPhaseLevel()
    local curLevel = globalData.userRunData.levelNum
    local leftLv = nextPhaseLevel - curLevel
    self.lbs_leftLevel:setString("LEFT: LV " .. leftLv)
end

function LevelRoadExpTip:onEnter()
    LevelRoadExpTip.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:updateLevel()
        end,
        ViewEventType.SHOW_LEVEL_UP
    )
end

return LevelRoadExpTip
