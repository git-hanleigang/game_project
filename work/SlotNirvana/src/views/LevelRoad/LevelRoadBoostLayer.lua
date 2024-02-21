-- 等级里程碑 主界面
local LevelRoadBoostLayer = class("LevelRoadBoostLayer", BaseLayer)

function LevelRoadBoostLayer:ctor()
    LevelRoadBoostLayer.super.ctor(self)

    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_StoreBooster.csb")
    self:setPortraitCsbName("LevelRoad/csd/Main_Portrait/LevelRoad_StoreBooster_Portrait.csb")
    self:setExtendData("LevelRoadBoostLayer")
end

function LevelRoadBoostLayer:initDatas(_params)
    self.m_params = _params or {}
    self.m_expansion = self.m_params.swell or 1
end

function LevelRoadBoostLayer:initCsbNodes()
    self.m_node_spine = self:findChild("spine")
    self.m_sp_boost_X_old = self:findChild("sp_boost_X_old")
    self.m_sp_boost_X_new = self:findChild("sp_boost_X_new")
    self.m_lb_boost_num_old = self:findChild("lb_boost_num_old")
    self.m_lb_boost_num_new = self:findChild("lb_boost_num_new")
end

function LevelRoadBoostLayer:initSpineUI()
    LevelRoadBoostLayer.super.initSpineUI(self)
    local spineNode = util_spineCreate("LevelRoad/spine/LevelRoad_StoreBooster_xct", true, true, 1)
    spineNode:addTo(self.m_node_spine)
    self.m_spine = spineNode
    self.m_spine:setVisible(false)
end

function LevelRoadBoostLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound("LevelRoad/sound/LevelRoad_boost.mp3")
            end,
            0.75
        )
        performWithDelay(
            self,
            function()
                if self.m_spine then
                    self.m_spine:setVisible(true)
                    util_spinePlay(self.m_spine, "start", false)
                    util_spineEndCallFunc(
                        self.m_spine,
                        "start",
                        function()
                            util_spinePlay(self.m_spine, "idle", true)
                        end
                    )
                end
            end,
            0.25
        )
    end
    LevelRoadBoostLayer.super.playShowAction(self, userDefAction)
end

function LevelRoadBoostLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function LevelRoadBoostLayer:initView()
    self:initBtnLabel()
    self:initBoost()
end

function LevelRoadBoostLayer:initBtnLabel()
    self:setButtonLabelContent("btn_gostore", "GO TO STORE")
end

function LevelRoadBoostLayer:initBoost()
    local preExpansion = G_GetMgr(G_REF.LevelRoad):getLocalPreviousExpansion() or 1
    self.m_lb_boost_num_old:setString("" .. preExpansion)
    self.m_lb_boost_num_new:setString("" .. self.m_expansion)
    local limitWid1 = globalData.slotRunData.isPortrait and 500 or 700
    local limitWid2 = globalData.slotRunData.isPortrait and 620 or 820
    local uiList1 = {
        {node = self.m_sp_boost_X_old},
        {node = self.m_lb_boost_num_old}
    }
    util_alignCenter(uiList1, nil, limitWid1)
    local uiList2 = {
        {node = self.m_sp_boost_X_new},
        {node = self.m_lb_boost_num_new}
    }
    util_alignCenter(uiList2, nil, limitWid2)
end

function LevelRoadBoostLayer:onEnter()
    LevelRoadBoostLayer.super.onEnter(self)
end

function LevelRoadBoostLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_BOOSTLAYER)
            end
        )
    elseif name == "btn_gostore" then
        G_GetMgr(G_REF.LevelRoad):setIsCanShowLogoLayer(true)

        self:closeUI(
            function()
                -- 跳转商城
                local params = {activityName = "LevelRoadBoostLayer", log = true, shopPageIndex = 1, notPushView = true}
                local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
                if not tolua.isnull(view) then
                    view:setOverFunc(
                        function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVELROAD_CLOSE_BOOSTLAYER)
                        end
                    )
                end
            end
        )
    end
end

return LevelRoadBoostLayer
