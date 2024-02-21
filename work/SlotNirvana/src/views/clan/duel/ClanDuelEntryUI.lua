--[[
    公会对决 -- 公会内入口
--]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanDuelEntryUI = class("ClanDuelEntryUI", BaseView)

function ClanDuelEntryUI:initDatas()
    ClanDuelEntryUI.super.initDatas(self)
    local clanData = ClanManager:getClanData()
    self.m_duelData = clanData:getClanDuelData()
    self.m_isRuning = self.m_duelData:isRunning()
    self.m_isMatchRival = self.m_duelData:isMatchRival()
end

function ClanDuelEntryUI:getCsbName()
    return "Club/csd/Duel/node_duel_entry.csb"
end

function ClanDuelEntryUI:onEnter()
    ClanDuelEntryUI.super.onEnter(self)
    gLobalNoticManager:addObserver(self, "editClanInfoSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_NEW_CLAN_INFO_SUCCESS)
end

-- 初始化节点
function ClanDuelEntryUI:initCsbNodes()
    self.m_node_comesoon = self:findChild("node_comesoon")
    self.m_node_matching = self:findChild("node_matching")
    self.m_node_loading = self:findChild("node_loading")
    self.m_lb_day = self:findChild("lb_day") -- commonSoon日期
    self.m_node_duel = self:findChild("node_duel")
    -- duel icon
    self.m_node_lead = self:findChild("node_lead") -- 超过图标节点
    self.m_sp_even = self:findChild("sp_even") -- 平手图标
    self.m_sp_mylead = self:findChild("sp_mylead")
    self.m_sp_otherlead = self:findChild("sp_otherlead")
    -- logo
    self.m_sp_clubIconBg = self:findChild("sp_clubIconBg")
    self.m_sp_clubIcon = self:findChild("sp_clubIcon")
    self.m_sp_clubIconBg_duel = self:findChild("sp_clubIconBg_duel")
    self.m_sp_clubIcon_duel = self:findChild("sp_clubIcon_duel")
    -- time
    self.m_lb_time = self:findChild("txt_time_1")
    -- btn
    self.m_btn_duelEntry = self:findChild("btn_duelEntry")
    -- duel status
    self.m_vs_up = self:findChild("vs_lan") -- 领先
    self.m_vs_down = self:findChild("vs_hong") -- 落后
    self.m_vs_same = self:findChild("vs_zhong") -- 均势
end

function ClanDuelEntryUI:initUI()
    ClanDuelEntryUI.super.initUI(self)
    self:updateCommonSoonVisible()
    self:updateRushInfoUI()
end

-- 更新活动commonsoon显隐
function ClanDuelEntryUI:updateCommonSoonVisible()
    local isDuel = self.m_isRuning and self.m_isMatchRival
    self.m_node_loading:setVisible(not isDuel)
    self.m_node_duel:setVisible(isDuel)
    if not isDuel then
        self.m_node_loading:setVisible(not self.m_isRuning)
        self.m_node_matching:setVisible(self.m_isRuning)
        local aniName = self.m_isRuning and "3" or "2"
        self:runCsbAction("idle" .. aniName, true)
    else
        self:runCsbAction("idle", true)
    end
end

-- 活动基本信息UI
function ClanDuelEntryUI:updateRushInfoUI()
    local isRunning = self.m_isRuning
    if not isRunning then
        return
    end

    self:updateLeadUI()
    self:initClanLogoUI()
    self:showDownTimer()
end

-- 更新对决状态
function ClanDuelEntryUI:updateLeadUI()
    local data = self.m_duelData
    if data then
        local status = data:getDuelStatus() -- UP DOWN SAME
        local isSame = status == "SAME"
        local isLead = status == "UP"
        self.m_node_lead:setVisible(not isSame)
        self.m_sp_even:setVisible(isSame)
        self.m_sp_mylead:setVisible(isLead)
        self.m_sp_otherlead:setVisible(not isLead)
        self.m_vs_same:setVisible(isSame)
        if isSame then
            self.m_vs_up:setVisible(false)
            self.m_vs_down:setVisible(false)
        else
            self.m_vs_up:setVisible(isLead)
            self.m_vs_down:setVisible(not isLead)
        end
    end
end

-- 公会 徽章logo
function ClanDuelEntryUI:initClanLogoUI()
    local clanData = ClanManager:getClanData()
    local data = clanData:getClanDuelData()
    if data then
        local myClanInfo = data:getMyClanInfo()
        if myClanInfo then
            local clanLogo = myClanInfo:getTeamLogo()
            local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
            local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
            util_changeTexture(self.m_sp_clubIconBg, imgBgPath)
            util_changeTexture(self.m_sp_clubIcon, imgPath)
        end
    
        local duelClanHead = data:getDuelClanHead()
        if duelClanHead and duelClanHead ~= "" then
            local clanLogo = duelClanHead
            local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
            local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
            util_changeTexture(self.m_sp_clubIconBg_duel, imgBgPath)
            util_changeTexture(self.m_sp_clubIcon_duel, imgPath)
        end
    end
end

--显示倒计时
function ClanDuelEntryUI:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function ClanDuelEntryUI:updateLeftTime()
    if self.m_duelData then
        local strLeftTime, isOver, isFullDay = util_daysdemaining(self.m_duelData:getExpireAt())
        if isOver then
            self:stopTimerAction()
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLAN_ENTRY_REFRESH)
            return
        end
        if isFullDay then
            strLeftTime = strLeftTime .. " LEFT"
        end
        self.m_lb_time:setString(strLeftTime)
    else
        self:stopTimerAction()
    end
end

function ClanDuelEntryUI:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function ClanDuelEntryUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_duelEntry" then
        ClanManager:popClanDuelMainLayer()
    end
end

function ClanDuelEntryUI:editClanInfoSuccessEvt()
    self:initClanLogoUI()
end

return ClanDuelEntryUI
