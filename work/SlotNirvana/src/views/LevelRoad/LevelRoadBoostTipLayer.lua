-- 等级里程碑 主界面
local LevelRoadBoostTipLayer = class("LevelRoadBoostTipLayer", BaseLayer)

function LevelRoadBoostTipLayer:ctor()
    LevelRoadBoostTipLayer.super.ctor(self)

    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_Boost_tanban.csb")
    self:setPortraitCsbName("LevelRoad/csd/Main_Portrait/LevelRoad_Boost_tanban_Portrait.csb")
    self:setExtendData("LevelRoadBoostTipLayer")
end

function LevelRoadBoostTipLayer:initDatas(_params)
    self.m_params = _params or {}
    self.m_expansion = self.m_params.expansion or 1
    self.m_level = self.m_params.level or 1
end

function LevelRoadBoostTipLayer:initCsbNodes()
    self.m_sp_boost_x = self:findChild("sp_boost_x")
    self.m_lb_boost_num = self:findChild("lb_boost_num")
    self.m_lb_boost_num_old = self:findChild("lb_boost_num_old")
    self.m_lb_level = self:findChild("lb_desc2")
    self.m_lb_boost_num_new = self:findChild("lb_boost_num_new")
end

function LevelRoadBoostTipLayer:initView()
    self:initBoost()
end

function LevelRoadBoostTipLayer:initBoost()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local preExpansion = data:getCurrentExpansion() or 1
        self.m_lb_boost_num_old:setString("X" .. preExpansion)
        self.m_lb_level:setString("LV" .. self.m_level .. ":")
        self.m_lb_boost_num_new:setString("X" .. self.m_expansion)
        self.m_lb_boost_num:setString("" .. self.m_expansion)
        local uiList = {
            {node = self.m_sp_boost_x},
            {node = self.m_lb_boost_num}
        }
        util_alignCenter(uiList, nil, 200)
    end
end

function LevelRoadBoostTipLayer:onEnter()
    LevelRoadBoostTipLayer.super.onEnter(self)
end

function LevelRoadBoostTipLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    LevelRoadBoostTipLayer.super.playShowAction(self, "start")
end

function LevelRoadBoostTipLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function LevelRoadBoostTipLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return LevelRoadBoostTipLayer
