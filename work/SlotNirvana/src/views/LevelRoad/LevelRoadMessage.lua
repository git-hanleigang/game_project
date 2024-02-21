-- 等级里程碑 信息界面
local LevelRoadMessage = class("LevelRoadMessage", util_require("base.BaseView"))

function LevelRoadMessage:initDatas()
    self.m_expansion = 0
end

function LevelRoadMessage:initUI()
    LevelRoadMessage.super.initUI(self)
    self:initView()
end

function LevelRoadMessage:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "LevelRoad/csd/Main_Portrait/LevelRoad_main_message_Portrait.csb"
    end
    return "LevelRoad/csd/LevelRoad_main_message.csb"
end

function LevelRoadMessage:initCsbNodes()
    self.m_sp_num_x_old = self:findChild("sp_num_x_old")
    self.m_lb_buff_num_old = self:findChild("lb_buff_num_old")
    self.m_sp_num_x_new = self:findChild("sp_num_x_new")
    self.m_lb_buff_num_new = self:findChild("lb_buff_num_new")
    self.m_lb_exp = self:findChild("lb_title_num_1")
    self.m_lb_level_coin = self:findChild("lb_title_num_2")
end

function LevelRoadMessage:initView()
    self:initStroeBoost()
    -- self:initExp()
    self:initBuff()
    self:runCsbAction("idle", true)
end

function LevelRoadMessage:initStroeBoost()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local expansion = data:getCurrentExpansion() or 1
        if self.m_expansion == 0 then
            self.m_expansion = expansion
        end
        self.m_lb_buff_num_old:setString("" .. self.m_expansion)
        self.m_expansion = expansion
        local uiList1 = {
            {node = self.m_sp_num_x_old},
            {node = self.m_lb_buff_num_old}
        }
        util_alignCenter(uiList1, nil, 150)

        self.m_lb_buff_num_new:setString("" .. expansion)
        local uiList2 = {
            {node = self.m_sp_num_x_new},
            {node = self.m_lb_buff_num_new}
        }
        util_alignCenter(uiList2, nil, 150)
    end
end

function LevelRoadMessage:initExp()
    local curLevel = globalData.userRunData.levelNum
    local multipleCoin = globalData.buffConfigData:getAllCoinBuffMultiple(curLevel, curLevel + 1)
    local curData = globalData.userRunData:getLevelUpRewardInfo(curLevel)
    local maxExp = globalData.userRunData:getPassLevelNeedExperienceVal()
    local upgradeNeedExp = maxExp - globalData.userRunData.currLevelExper
    upgradeNeedExp = upgradeNeedExp > 0 and upgradeNeedExp or 0
    self.m_lb_exp:setString(util_formatCoins(upgradeNeedExp, 30))
    self:updateLabelSize({label = self.m_lb_exp}, 241)
    self.m_lb_level_coin:setString(util_formatCoins(curData.p_coins * multipleCoin, 30))
    self:updateLabelSize({label = self.m_lb_level_coin}, 245)
end

function LevelRoadMessage:initBuff()
    for i = 1, 2 do
        local node_nuff = self:findChild("node_buff_" .. i)
        local buffNode = util_createView("views.LevelRoad.LevelRoadBuffNode", i)
        if node_nuff and buffNode then
            node_nuff:addChild(buffNode)
        end
    end
end

function LevelRoadMessage:refreshBuff(_cb)
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local expansion = data:getCurrentExpansion() or 1
        if self.m_expansion >= expansion then
            return
        end
        self:initStroeBoost()
        self:runCsbAction(
            "start",
            false,
            function()
                self:initStroeBoost()
                self:runCsbAction("idle", true)
                if _cb then
                    _cb()
                end
            end,
            60
        )
    end
end

function LevelRoadMessage:onEnter()
    LevelRoadMessage.super.onEnter(self)
end

function LevelRoadMessage:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        self:showNextBoostTipLayer()
    end
end

function LevelRoadMessage:showNextBoostTipLayer()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local reward = data:getNextPhaseSwellReward()
        if reward then
            G_GetMgr(G_REF.LevelRoad):showBoostTipLayer(reward)
        end
    end
end

return LevelRoadMessage
