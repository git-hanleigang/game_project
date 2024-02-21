--[[
    特殊卡册标题-购物主题
]]
local UIStatus = {
    History = 1,
    Normal = 2,
    Jackopt = 3,
}

local ObsidianCardTitle = class("ObsidianCardTitle", BaseView)

function ObsidianCardTitle:initDatas(_pageIndex, _seasonId)
    self.m_data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(_seasonId)
    self.m_seasonId = _seasonId
    self.m_pageIndex = _pageIndex
    self.m_isHistory = self.m_data:isHistorySeason(_seasonId) or false
    self.m_rewardLuaPath = "views.Card.CardObsidian_7.mainUI.ObsidianCardTitleReward"

    if self.m_isHistory then
        self.m_UIStatus = UIStatus.History
    else
        self.m_UIStatus = UIStatus.Normal
    end
end

function ObsidianCardTitle:getCsbName()
    return "CardRes/CardObsidian_7/csb/main/ObsidianAlbum_title.csb"
end

function ObsidianCardTitle:initCsbNodes()
    self.m_nodeTitle = self:findChild("node_title")
    self.m_nodeTitleJackpot = self:findChild("node_title_JackPot")
    self.m_nodeTitleHistroy = self:findChild("node_title2")
    self.m_nodeShow1 = self:findChild("node_show1")
    self.m_nodeShow2 = self:findChild("node_show2")   --  2023 火鸡赛季 node_show2  大写变小写
    self.m_cardLogo = self:findChild("card_logo")
    self.m_lbProgress = self:findChild("lb_progress")
    self.m_lbJackpotPro = self:findChild("lb_jackpotPro")
    self.m_spJackpotCoin = self:findChild("sp_jackpotCoin")
    self.m_lbJackpotCoin = self:findChild("lb_jackpotCoin")
    self.m_nodeRewards = {}
    for i = 1, 3 do
        local nodePrize = self:findChild("node_prize_" .. i)
        table.insert(self.m_nodeRewards, nodePrize)
    end

    self.m_btnSwitchJackpot = self:findChild("btn_pageNormal")
end

function ObsidianCardTitle:initUI()
    ObsidianCardTitle.super.initUI(self)
    self:initTitle()
end

function ObsidianCardTitle:initTitle()
    if self.m_UIStatus == UIStatus.History then
        self.m_nodeTitle:setVisible(false)
        self.m_nodeTitleJackpot:setVisible(false)
        self.m_nodeTitleHistroy:setVisible(true)
        local isGetAllCards = self.m_data:isGetAllCards()
        self.m_nodeShow1:setVisible(isGetAllCards)
        self.m_nodeShow2:setVisible(not isGetAllCards)
    else
        self.m_nodeTitleHistroy:setVisible(false)

        if self.m_UIStatus == UIStatus.Normal then
            self.m_nodeTitle:setVisible(true)
            self.m_nodeTitleJackpot:setVisible(false)
        else
            self.m_nodeTitle:setVisible(false)
            self.m_nodeTitleJackpot:setVisible(true) 
        end

        self:initPro()
        self:initCoins()
        -- self:initJackpot() -- 2023火鸡节 不要jackpot了
    end
end

function ObsidianCardTitle:initPro()
    local current = self.m_data:getCurrent()
    local total = self.m_data:getTotal()
    self.m_lbProgress:setString(current .. "/" .. total)    
end

function ObsidianCardTitle:initCoins()
    for i = 1, #self.m_nodeRewards do
        local reward = util_createView(self.m_rewardLuaPath, i)
        self.m_nodeRewards[i]:addChild(reward)
    end
end

function ObsidianCardTitle:initJackpot()
    self.m_btnSwitchJackpot:setVisible(false)
    if self:getJackpotData() ~= nil then
        self.m_btnSwitchJackpot:setVisible(true)
        self:initJactpotPro()
        self:initJackpotSche()
    end    
end

function ObsidianCardTitle:initJactpotPro()
    local current = self.m_data:getCurrent()
    local total = self.m_data:getTotal()
    self.m_lbJackpotPro:setString(current .. "/" .. total)
end

function ObsidianCardTitle:stopJackpotSche()
    if self.m_jackpotSche then
        self:stopAction(self.m_jackpotSche)
        self.m_jackpotSche = nil
    end
end

function ObsidianCardTitle:initJackpotSche()
    local jackpotData = self:getJackpotData()
    if not jackpotData then
        return
    end
    self:stopJackpotSche()

    local function update()
        local jackpotValue = jackpotData:getJackpotValue()
        self:updateJackpotCoins(jackpotValue)
    end
    self.m_jackpotSche = util_schedule(self, update, 0.05)
end

function ObsidianCardTitle:updateJackpotCoins(_value)
    self.m_lbJackpotCoin:setString(util_formatCoins(_value, 28))
    util_alignCenter(
        {
            {node = self.m_spJackpotCoin, scale = 0.5},
            {node = self.m_lbJackpotCoin, scale = 0.4}
        },
        nil,
        560
    )
end

function ObsidianCardTitle:stopSwitchTimer()
    if self.m_switchTimer then
        self:stopAction(self.m_switchTimer)
        self.m_switchTimer = nil
    end
end

function ObsidianCardTitle:startSwitchTimer()
    self:stopSwitchTimer()
    self.m_switchTimer = util_performWithDelay(self, function()
        if not tolua.isnull(self) then
            self:startSwitch(UIStatus.Jackopt)
        end
    end, 6)
end

function ObsidianCardTitle:playStart(_over)
    self:runCsbAction("start", false, function()
        if not tolua.isnull(self) then
            self:playIdle()
        end
    end, 60)

    local jackpotData = self:getJackpotData()
    if jackpotData ~= nil and self.m_UIStatus ~= UIStatus.History and gLobalDataManager:getNumberByField("ObsidianTitleFirstJackpot", 0) == 0 then
        self:startSwitchTimer()
    end
end

function ObsidianCardTitle:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function ObsidianCardTitle:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

function ObsidianCardTitle:startSwitch(_targetStatus)
    if self.m_isSwitching then
        return
    end
    self.m_isSwitching = true
    if _targetStatus == self.m_UIStatus then
        return
    end
    self.m_UIStatus = _targetStatus
    if gLobalDataManager:getNumberByField("ObsidianTitleFirstJackpot", 0) == 0 then
        gLobalDataManager:getNumberByField("ObsidianTitleFirstJackpot", 1)
    end
    self:playSwitch1(function()
        if _targetStatus == UIStatus.Normal then
            self.m_nodeTitle:setVisible(true)
            self.m_nodeTitleJackpot:setVisible(false)
        elseif _targetStatus == UIStatus.Jackopt then
            self.m_nodeTitle:setVisible(false)
            self.m_nodeTitleJackpot:setVisible(true)
        end
        self:playSwitch2(function()
            if not tolua.isnull(self) then
                self.m_isSwitching = false
            end
        end)
    end)
end

function ObsidianCardTitle:playSwitch1(_over)
    self:runCsbAction("qiehuan1", false, _over, 60)
end

function ObsidianCardTitle:playSwitch2(_over)
    self:runCsbAction("qiehuan2", false, _over, 60) 
end

function ObsidianCardTitle:clickFunc(sender)
    if self.m_isSwitching then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local name = sender:getName()
    if name == "btn_pageNormal" then
        self:stopSwitchTimer()
        self:startSwitch(UIStatus.Jackopt)
    elseif name == "btn_pageJackpot" then
        self:stopSwitchTimer()
        self:startSwitch(UIStatus.Normal)
    end
end

function ObsidianCardTitle:onExit()
    ObsidianCardTitle.super.onExit(self)
    self:stopSwitchTimer()
    self:stopJackpotSche()
end

function ObsidianCardTitle:getJackpotData()
    local mgr = G_GetMgr(ACTIVITY_REF.CardObsidianJackpot)
    if mgr then
        return mgr:getRunningData()
    end
    return nil
end

return ObsidianCardTitle
