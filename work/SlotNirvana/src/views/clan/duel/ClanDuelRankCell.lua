--[[
    公会对决 -- 排行榜cell
--]]
local ClanDuelRankCell = class("ClanDuelRankCell", BaseView)

function ClanDuelRankCell:initDatas()
    ClanDuelRankCell.super.initDatas(self)
end

-- 初始化节点
function ClanDuelRankCell:initCsbNodes()
    self.m_imgBgMe = self:findChild("img_bg_me")
    self.m_imgBgOther = self:findChild("img_bg_other")
    -- rank
    self.m_spRank_1 = self:findChild("sp_1st")
    self.m_spRank_2 = self:findChild("sp_2nd")
    self.m_spRank_3 = self:findChild("sp_3rd")
    self.m_lbRank = self:findChild("lb_rank")
    self.m_spNoRank = self:findChild("sp_norank")
    -- name
    self.m_layoutName = self:findChild("layout_name")
    self.m_lbNameMe = self:findChild("lb_myName")
    self.m_lbNameOther = self:findChild("lb_otherName")
    -- points
    self.m_lbPoints = self:findChild("txt_reward")
    -- head
    self.m_node_head = self:findChild("node_head")
    self.m_sp_head = self:findChild("sp_head")
    self.m_sp_head:setVisible(false)
    -- reward
    self.m_sp_coins = self:findChild("sp_coins")
    self.m_node_item = self:findChild("node_item")
    self.m_lb_coins = self:findChild("lb_coins")
end

function ClanDuelRankCell:updateUI(_rankCellData)
    if not _rankCellData then
        return
    end
    self.m_rankCellData = _rankCellData
    self.m_bMe = _rankCellData:checkIsBMe()
    self.m_lbName = self.m_bMe and self.m_lbNameMe or self.m_lbNameOther
    self.m_lbNameMe:setVisible(self.m_bMe)
    self.m_lbNameOther:setVisible(not self.m_bMe)
    self.m_imgBgMe:setVisible(self.m_bMe)
    self.m_lbNameOther:setVisible(not self.m_bMe)

    -- 排名
    self:updateRankTxtUI()
    -- 公会 总点数
    self:updateTeamPointsUI()
    -- 公会 玩家头像、名字
    self:updateTeamHeadUI()
    -- 公会 奖励
    self:updateTeamRewardUI()
end

-- 排名
function ClanDuelRankCell:updateRankTxtUI()
    local rank = self.m_rankCellData:getRank()
    if rank <= 0 then
        self.m_spNoRank:setVisible(true)
        self.m_lbRank:setVisible(false)
        self:updateTopThreeUIVisible(false)
    elseif rank > 3 then
        self.m_spNoRank:setVisible(false)
        self.m_lbRank:setVisible(true)
        self:updateTopThreeUIVisible(false)
        self.m_lbRank:setString(rank)
    else
        self.m_spNoRank:setVisible(false)
        self.m_lbRank:setVisible(false)
        self:updateTopThreeUIVisible(true, rank)
    end
end

-- 排名显隐
function ClanDuelRankCell:updateTopThreeUIVisible(_isVisible, _rank)
    for i = 1, 3 do
        local rankIcon = self["m_spRank_" .. i]
        if rankIcon then
            if _rank then
                rankIcon:setVisible(_rank == i)
            else
                rankIcon:setVisible(_isVisible)
            end
        end
    end
end

-- 公会 总点数
function ClanDuelRankCell:updateTeamPointsUI()
    local points = self.m_rankCellData:getPoints()
    local limitNum = globalData.slotRunData.isPortrait and 3 or 6
    self.m_lbPoints:setString(util_formatCoins(points, limitNum))
end

-- 公会 玩家头像、名字
function ClanDuelRankCell:updateTeamHeadUI()
    if self.m_node_head then
        --设置头像
        local data = {
            p_fbid = self.m_rankCellData:getFacebookId(),
            p_head = self.m_rankCellData:getUserHead(),
            p_frameId = self.m_rankCellData:getUserFrame()
        }
        local limitSize = cc.size(56, 56)
        local nodeAvatar = self.m_node_head:getChildByName("CommonAvatarNode")
        if nodeAvatar then
            nodeAvatar:updateUI(data.p_fbid, data.p_head, data.p_frameId, nil, limitSize)
        else
            nodeAvatar =
                G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
                data.p_fbid,
                data.p_head,
                data.p_frameId,
                nil,
                limitSize
            )
            self.m_node_head:addChild(nodeAvatar)
            nodeAvatar:setName("CommonAvatarNode")

            local layout = ccui.Layout:create()
            layout:setName("layout_touch")
            layout:setTouchEnabled(true)
            layout:setContentSize(limitSize)
            layout:setPosition(-limitSize.width / 2, -limitSize.height / 2)
            layout:addTo(self.m_node_head)
            self:addClick(layout)
        end
    end

    if self.m_layoutName and self.m_lbName then
        local name = self.m_rankCellData:getUserName()
        self.m_lbName:setString(name)
        util_wordSwing(self.m_lbName, 1, self.m_layoutName, 3, 30, 3)
    end
end

function ClanDuelRankCell:updateTeamRewardUI()
    if not self.m_node_item or not self.m_rankCellData then
        return
    end
    local coins = self.m_rankCellData:getCoins()
    local items = self.m_rankCellData:getItems()
    local coinsStr = "0"
    local nodeItemSize = cc.size(0, 0)
    local rewardScale = self:getRewardScale()
    local isAlign = false
    if coins and coins > 0 then
        isAlign = true
        local limitNum = globalData.slotRunData.isPortrait and 3 or 6
        coinsStr = util_formatCoins(coins, limitNum)
    end
    if items and table.nums(items) > 0 then
        isAlign = true
        self.m_node_item:removeAllChildren()
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
                nodeItemSize.width =  nodeItemSize.width + item_width
            end
        end
        util_alignLeft(itemUiList)
    end

    self.m_lb_coins:setString(coinsStr)
    
    if isAlign then
        local uiList = {}
        nodeItemSize = cc.size(nodeItemSize.width * rewardScale, nodeItemSize.height * rewardScale)
        uiList[#uiList + 1] = {node = self.m_sp_coins, alignX = 2}
        uiList[#uiList + 1] = {node = self.m_lb_coins, alignX = 2}
        uiList[#uiList + 1] = {node = self.m_node_item, size = nodeItemSize}
        util_alignLeft(uiList)
    end
end

function ClanDuelRankCell:getRewardScale()
    return globalData.slotRunData.isPortrait and 0.35 or 0.45
end

function ClanDuelRankCell:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        if not self.m_rankCellData then
            return
        end
        if not self.m_rankCellData:getUdid() then
            return
        end
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(
            self.m_rankCellData:getUdid(),
            "",
            "",
            self.m_rankCellData:getUserFrame()
        )
    end
end

function ClanDuelRankCell:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "Club/csd/Duel/node_duel_ranking_Vertical.csb"
    end
    return "Club/csd/Duel/node_duel_ranking.csb"
end

function ClanDuelRankCell:getRank()
    local rank = 0
    if self.m_rankCellData then
        rank = self.m_rankCellData:getRank()
    end
    return rank
end

return ClanDuelRankCell
