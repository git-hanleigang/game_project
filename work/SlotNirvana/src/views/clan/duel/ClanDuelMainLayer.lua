--[[
    公会对决 - 主界面
--]]
local ClanDuelMainLayer = class("ClanDuelMainLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanDuelRankTableView = util_require("views.clan.duel.ClanDuelRankTableView")
local TYPE_ENUM = {
    DuelInfo = 1,
    TeamRank = 2
}

function ClanDuelMainLayer:ctor()
    ClanDuelMainLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true)
    self:setExtendData("ClanDuelMainLayer")
    self:setLandscapeCsbName("Club/csd/Duel/Duel_ranking.csb")
    self:setPortraitCsbName("Club/csd/Duel/Duel_ranking_Vertical.csb")
end

function ClanDuelMainLayer:initDatas()
    self:initBaseDatas()
    self.m_type = TYPE_ENUM.DuelInfo
    self.m_isRequestRankInfo = false
end

function ClanDuelMainLayer:initBaseDatas()
    local clanData = ClanManager:getClanData()
    self.m_duelData = clanData:getClanDuelData()
    self.m_selfRankInfo = self.m_duelData:getSelfRankInfo()
    self.m_selfRank = self.m_selfRankInfo:getRank()
end

function ClanDuelMainLayer:registerListener()
    ClanDuelMainLayer.super.registerListener(self)

    -- 排行榜请求
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            self:initBaseDatas()
            self:initSelfTeamInfoUI()
            self:updateRankListUI()
            self:refreshView(TYPE_ENUM.TeamRank)
        end,
        ClanConfig.EVENT_NAME.CLAN_DUEL_REQUEST_RANK
    )

    -- 公会对决自己的信息显隐
    gLobalNoticManager:addObserver(
        self,
        "updateFlotSelfRankInfoVisibleEvt",
        ClanConfig.EVENT_NAME.UPDATE_DUEL_RANK_SELF_VIEW_VISIBLE
    )
end

function ClanDuelMainLayer:initCsbNodes()
    self.m_node_duel_info = self:findChild("node_duel_info")
    self.m_node_team_rank = self:findChild("node_team_rank")
    self.m_btn_duel = self:findChild("btn_rush1")
    self.m_btn_rank = self:findChild("btn_rush2")
    self.m_node_time = self:findChild("node_time")
    self.m_txt_time = self:findChild("txt_time")
    self.m_sp_even = self:findChild("sp_even")

    self.m_btn_start = self:findChild("btn_start")
    -- reward
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_node_item = self:findChild("node_item")

    -- my clan
    self.m_sp_clubIconBg = self:findChild("sp_clubIconBg")
    self.m_sp_clubIcon = self:findChild("sp_clubIcon")
    self.m_lb_team = self:findChild("lb_team")
    self.m_lb_point = self:findChild("lb_point")
    self.m_sp_flag1 = self:findChild("sp_flag1")

    -- other clan
    self.m_sp_clubIconBg_other = self:findChild("sp_clubIconBg_other")
    self.m_sp_clubIcon_other = self:findChild("sp_clubIcon_other")
    self.m_lb_team_other = self:findChild("lb_team_other")
    self.m_lb_point_other = self:findChild("lb_point_other")
    self.m_sp_flag2 = self:findChild("sp_flag2")

    -- duel status
    self.m_vs_up = self:findChild("vs_lan") -- 领先
    self.m_vs_down = self:findChild("vs_hong") -- 落后
    self.m_vs_same = self:findChild("vs_zhong") -- 均势
end

function ClanDuelMainLayer:initView()
    -- 时间
    self:initTimeUI()
    -- 更新对决状态
    self:updateLeadUI()

    --[[ DuelInfo ]]
    -- 公会 徽章logo
    self:initClanLogoUI()
    -- 公会 名字
    self:initClanNameUI()
    -- 公会 总点数
    self:initClanPointsUI()
    --奖励
    self:initReward()

    --[[ TeamRank ]]
    -- 个人榜单信息
    self:initSelfTeamInfoUI()
    -- 更新排行列表
    self:updateRankListUI()

    -- 刷新界面
    self:refreshView(self.m_type)
end

function ClanDuelMainLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

-- 公会 徽章logo
function ClanDuelMainLayer:initClanLogoUI()
    local myClanInfo = self.m_duelData:getMyClanInfo()
    if myClanInfo then
        local clanLogo = myClanInfo:getTeamLogo()
        local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
        local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
        util_changeTexture(self.m_sp_clubIconBg, imgBgPath)
        util_changeTexture(self.m_sp_clubIcon, imgPath)
    end

    local duelClanHead = self.m_duelData:getDuelClanHead()
    if duelClanHead and duelClanHead ~= "" then
        local clanLogo = duelClanHead
        local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
        local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
        util_changeTexture(self.m_sp_clubIconBg_other, imgBgPath)
        util_changeTexture(self.m_sp_clubIcon_other, imgPath)
    end
end

-- 公会 名字
function ClanDuelMainLayer:initClanNameUI()
    local myClanInfo = self.m_duelData:getMyClanInfo()
    if myClanInfo then
        local name = myClanInfo:getTeamName()
        self.m_lb_team:setString(name)
    end

    local otherClanName = self.m_duelData:getDuelClanName()
    if otherClanName then
        local name = otherClanName
        self.m_lb_team_other:setString(name)
    end
end

-- 公会 总点数
function ClanDuelMainLayer:initClanPointsUI()
    local myClanPoints = self.m_duelData:getMyPoints()
    if myClanPoints then
        local points = myClanPoints
        self.m_lb_point:setString(util_formatCoins(points, 6))
    end

    local otherClanPoints = self.m_duelData:getDuelClanPoints()
    if otherClanPoints then
        local points = otherClanPoints
        self.m_lb_point_other:setString(util_formatCoins(points, 6))
    end
end

function ClanDuelMainLayer:initReward()
    if not self.m_duelData then
        return
    end
    local coins = self.m_duelData:getCoins()
    local items = self.m_duelData:getItems()
    local coinsStr = ""
    local rewardScale = 0.7
    local nodeItemSize = cc.size(0, 0)

    if coins and coins > 0 then
        coinsStr = coinsStr .. util_formatCoins(coins, 6)
    end

    if items and table.nums(items) > 0 then
        coinsStr = coinsStr .. "+"
        local itemUiList = {}
        local item_width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
        nodeItemSize.height = item_width
        for i, shopItemData in ipairs(items) do
            local shopItemUI = gLobalItemManager:createRewardNode(shopItemData, ITEM_SIZE_TYPE.TOP)
            if shopItemUI ~= nil then
                self.m_node_item:addChild(shopItemUI)
                shopItemUI:setScale(rewardScale)
                table.insert(
                    itemUiList,
                    {node = shopItemUI, alignX = 0, size = cc.size(item_width, item_width), anchor = cc.p(0.5, 0.5)}
                )
                nodeItemSize.width = nodeItemSize.width + item_width
            end
        end
        util_alignLeft(itemUiList)
    end

    nodeItemSize = cc.size(nodeItemSize.width * rewardScale, nodeItemSize.height * rewardScale)

    self.m_lb_coin:setString(coinsStr)

    local uiList = {}
    uiList[#uiList + 1] = {node = self.m_sp_coin, alignX = 2}
    uiList[#uiList + 1] = {node = self.m_lb_coin, alignX = 2}
    uiList[#uiList + 1] = {node = self.m_node_item, size = nodeItemSize}
    util_alignCenter(uiList)
end

-- 时间
function ClanDuelMainLayer:initTimeUI()
    self:clearScheduler()
    self:updateLeftTime()
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTime), 1)
end

function ClanDuelMainLayer:updateLeftTime()
    if self.m_duelData then
        local expireAt = self.m_duelData:getExpireAt()
        local str, isOver = util_daysdemaining(expireAt)
        if isOver then
            self:clearScheduler()
            self:closeUI(
                function()
                    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLAN_DUEL_TIME_OUT)
                end
            )
            return
        end
        self.m_txt_time:setString(str)
    else
        self:clearScheduler()
    end
end

--停掉定时器
function ClanDuelMainLayer:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

-- 个人榜单信息
function ClanDuelMainLayer:initSelfTeamInfoUI()
    local count = self.m_selfRank > 0 and 2 or 1
    for i = 1, count do
        local parent = self:findChild(i == 1 and "node_self_bottom" or "node_self_top")
        parent:removeAllChildren()
        local view = util_createView("views.clan.duel.ClanDuelRankCell")
        parent:addChild(view)
        view:updateUI(self.m_selfRankInfo)
        parent:setVisible(false)
    end

    if count == 1 then
        local nodeBottom = self:findChild("node_self_bottom")
        nodeBottom:setVisible(true)
    end
end

-- 更新排行列表
function ClanDuelMainLayer:updateRankListUI()
    local listData = self.m_duelData:getRankList()
    if self.m_tableView then
        self.m_tableView:reload(listData)
        if self.m_selfRank > 0 then
            self.m_tableView:setNeedUpdateSelfUI(true)
            self.m_tableView:updateFlotSelfRankInfoVisible()
        end
    else
        local listView = self:findChild("Panel_TableView")
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        local tableView = ClanDuelRankTableView.new(param)
        listView:addChild(tableView)
        tableView:reload(listData)
        if self.m_selfRank > 0 then
            tableView:setNeedUpdateSelfUI(true)
            tableView:updateFlotSelfRankInfoVisible()
        end
        self.m_tableView = tableView
    end
end

-- 更新对决状态
function ClanDuelMainLayer:updateLeadUI()
    local data = self.m_duelData
    if data then
        local status = data:getDuelStatus() -- UP DOWN SAME
        local isSame = status == "SAME"
        local isLead = status == "UP"
        self.m_sp_even:setVisible(isSame)
        self.m_vs_same:setVisible(isSame)
        if isSame then
            self.m_sp_flag1:setVisible(false)
            self.m_sp_flag2:setVisible(false)
            self.m_vs_up:setVisible(false)
            self.m_vs_down:setVisible(false)
        else
            self.m_sp_flag1:setVisible(isLead)
            self.m_sp_flag2:setVisible(not isLead)
            self.m_vs_up:setVisible(isLead)
            self.m_vs_down:setVisible(not isLead)
        end
    end
end

function ClanDuelMainLayer:clickFunc(sender)
    if self.m_isAnimationing then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_start" then
        self:closeUI()
    elseif name == "btn_info" then
        ClanManager:popClanDuelRuleLayer()
    elseif name == "btn_rush1" then
        self:refreshView(TYPE_ENUM.DuelInfo)
    elseif name == "btn_rush2" then
        if self.m_isRequestRankInfo then
            self:refreshView(TYPE_ENUM.TeamRank)
        else
            self.m_isRequestRankInfo = true
            ClanManager:sendClanDuelRank()
        end
    end
end

-- 自己的信息显隐
function ClanDuelMainLayer:updateFlotSelfRankInfoVisibleEvt(_params)
    if self.m_selfRank <= 0 then
        return
    end

    local rankMin = _params[1] or 0
    local rankMax = _params[2] or 9999

    local nodeTop = self:findChild("node_self_top")
    local nodeBottom = self:findChild("node_self_bottom")
    if self.m_selfRank < rankMin then
        nodeTop:setVisible(true)
        nodeBottom:setVisible(false)
    elseif self.m_selfRank > rankMax then
        nodeTop:setVisible(false)
        nodeBottom:setVisible(true)
    else
        nodeTop:setVisible(false)
        nodeBottom:setVisible(false)
    end
end

function ClanDuelMainLayer:refreshView(_type)
    self.m_type = _type
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.m_node_duel_info:setVisible(_type == TYPE_ENUM.DuelInfo)
    self.m_node_team_rank:setVisible(_type == TYPE_ENUM.TeamRank)
    self.m_btn_duel:setEnabled(_type == TYPE_ENUM.TeamRank)
    self.m_btn_rank:setEnabled(_type == TYPE_ENUM.DuelInfo)
end

return ClanDuelMainLayer
