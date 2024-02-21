--大地图上的排行榜节点
local QuestLobbyRank = class("QuestLobbyRank", util_require("base.BaseView"))

QuestLobbyRank.NoneRank = 360

-- function QuestLobbyRank:ctor()
--     QuestLobbyRank.super.ctor(self)

--     self:mergePlistInfos(QUEST_PLIST_PATH.QuestLobbyRank)
-- end

function QuestLobbyRank:getCsbNodePath()
    return QUEST_RES_PATH.QuestLobbyRank
end

function QuestLobbyRank:initUI(data)
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self.m_lastMyRank = self:getLastMyRank()
    self:createCsbNode(self:getCsbNodePath())
    self:initView()
    self:runCsbAction("idle", true)
    self:updateRankNum()
    local touch = G_GetMgr(ACTIVITY_REF.Quest):makeTouch(cc.size(140, 140), "touch")
    self:addChild(touch, 1)
    self:addClick(touch)
end

function QuestLobbyRank:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Rank"
end

function QuestLobbyRank:getLastMyRank()
    local lastMyRank = self.NoneRank
    if self.m_config and self.m_config.p_expireAt then
        lastMyRank = gLobalDataManager:getNumberByField("quest_lastRank" .. self.m_config.p_expireAt, lastMyRank)
    end
    return lastMyRank
end

function QuestLobbyRank:saveLastMyRank(rankNum)
    if self.m_config and self.m_config.p_expireAt then
        gLobalDataManager:setNumberByField("quest_lastRank" .. self.m_config.p_expireAt, rankNum)
    end
end

function QuestLobbyRank:initView()
end

function QuestLobbyRank:onEnter()
    --获取排行信息
    gLobalNoticManager:addObserver(
        self,
        function(self, rankData)
            self:updateRankNum()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_RANK
    )
end

--刷新排行按钮上的排名和状态
function QuestLobbyRank:updateRankNum()
    local BitmapFontLabel_1 = self:findChild("BitmapFontLabel_1")
    local jiantou_down = self:findChild("jiantou_down")
    local jiantou_up = self:findChild("jiantou_up")
    jiantou_down:setVisible(false)
    jiantou_up:setVisible(false)
    BitmapFontLabel_1:setVisible(false)
    local rankNum = nil
    local questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questData then
        return
    end
    local questRankConfig = questData:getRankCfg()
    if not questRankConfig then
        return
    end
    if not questRankConfig.p_myRank then
        return
    end
    local rankNum = questRankConfig.p_myRank.p_rank
    if not rankNum or rankNum == 0 then
        self.m_lastMyRank = self.NoneRank
        self:saveLastMyRank(self.m_lastMyRank)
        return
    end
    if not questRankConfig.p_myRank.p_points or questRankConfig.p_myRank.p_points == 0 then
        return
    end
    BitmapFontLabel_1:setVisible(true)
    BitmapFontLabel_1:setString(rankNum)
    if rankNum > self.m_lastMyRank then
        jiantou_down:setVisible(true)
        jiantou_up:setVisible(false)
    else
        jiantou_down:setVisible(false)
        jiantou_up:setVisible(true)
    end
    if rankNum ~= self.m_lastMyRank then
        self:saveLastMyRank(rankNum)
    else
        jiantou_down:setVisible(false)
        jiantou_up:setVisible(false)
    end
end

function QuestLobbyRank:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(ACTIVITY_REF.Quest):showRankView("QuestLobbyRank")
    end
end
return QuestLobbyRank
