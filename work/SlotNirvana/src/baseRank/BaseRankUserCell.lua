-- 排行榜通用控件 玩家排名控件
local NetSpriteLua = require("views.NetSprite")
local BaseRankUserCell = class("BaseRankUserCell", util_require("base.BaseView"))

function BaseRankUserCell:initDatas(csb_res, params)
    if csb_res then
        self:setCsbName(csb_res)
    end
    params = params or {}
    self.m_isHangCell = params.isHang or false
end

function BaseRankUserCell:initUI(csb_res)
    
    self:createCsbNode(self:getCsbName())
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BaseRankUserCell:initCsbNodes()
    self.sp_myRank = self:findChild("sp_myRank")
    self.sp_myRankBg = self:findChild("sp_myRankBg")
    self.sp_myIcon = self:findChild("sp_myIcon")
    self.layer_myId = self:findChild("layer_myId")
    self.lb_myId = self:findChild("lb_myId")

    self.sp_otherRank = self:findChild("sp_otherRank")
    self.sp_otherRankBg = self:findChild("sp_otherRankBg")
    self.sp_otherIcon = self:findChild("sp_otherIcon")
    self.layer_otherId = self:findChild("layer_otherId")
    self.lb_otherId = self:findChild("lb_otherId")

    self.sp_rankBg = self:findChild("sp_rankBg")
    self.sp_1st = self:findChild("sp_1st")
    self.sp_2nd = self:findChild("sp_2nd")
    self.sp_3rd = self:findChild("sp_3rd")
    self.lb_rank = self:findChild("lb_rank")
    self.sp_noRank = self:findChild("sp_noRank")
    self.lb_point = self:findChild("lb_point")
    self.lb_coin = self:findChild("lb_coin")

    self.node_reward = self:findChild("node_reward")
    --self.sp_my_pointBg = self:findChild("sp_my_pointBg")
    --self.sp_other_pointBg = self:findChild("sp_other_pointBg")

    --self.node_reward = self:findChild("node_reward")
    --self.node_rewards = self:findChild("node_rewards")

    -- 初始化显隐
    self.sp_noRank:setVisible(true)
    self.lb_rank:setVisible(false)
end

function BaseRankUserCell:isHangCell()
    return self.m_isHangCell
end

-- 是否是自己的排名cell
function BaseRankUserCell:isMyRank(rank_data)
    local bl_isMyRank = false
    if rank_data and rank_data.p_udid == globalData.userRunData.userUdid then
        bl_isMyRank = true
    end
    return bl_isMyRank or self:isHangCell()
end

function BaseRankUserCell:updateView(rank_data, idx, myIdx)
    if not rank_data or table.nums(rank_data) <= 0 then
        return
    end

    if not idx then
        return
    end

    self:setRankData(rank_data)
    if idx then
        self:setIndex(idx)
        if myIdx ~= nil and idx ~= myIdx then
            self:setCompareIdx(myIdx)
        end
    end

    local bl_isMyRank = self:isMyRank(rank_data)
    if self.sp_myRank then
        self.sp_myRank:setVisible(bl_isMyRank)
        self.sp_otherRank:setVisible(not bl_isMyRank)
    end
    
    self:reloaedIcon()
    self:setRankInfo(rank_data)
end

function BaseRankUserCell:reloaedIcon()
    local sp_icon
    local bl_isMyRank = self:isMyRank()

    if bl_isMyRank then
        sp_icon = self.sp_myIcon
    else
        sp_icon = self.sp_otherIcon
    end
    if not sp_icon then
        return
    end

    local rank_data = self:getRankData()
    self.rank_data = rank_data
    --设置头像
    local limitSize = cc.size(60, 60)
    local headSize = sp_icon:getContentSize()
    local nodeAvatar = sp_icon:getChildByName("CommonAvatarNode")
    if nodeAvatar then
        nodeAvatar:updateUI(rank_data.p_fbid, rank_data.p_head, rank_data.p_frameId, nil, headSize)
    else
        sp_icon:removeAllChildren()
        local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(rank_data.p_fbid, rank_data.p_head, rank_data.p_frameId, nil, headSize)
        sp_icon:addChild(nodeAvatar)
        nodeAvatar:setPosition(headSize.width * 0.5, headSize.height * 0.5)
        if limitSize.width < headSize.width then
            sp_icon:setScale(limitSize.width / headSize.width)
        end
        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(headSize)
        self:addClick(layout)
        layout:addTo(sp_icon)
    end
end

function BaseRankUserCell:setRankInfo(data)
    -- 设置排名
    local bl_ranked = (data.p_rank and data.p_rank > 0)
    self.sp_noRank:setVisible(not bl_ranked)

    if self.sp_myRankBg then
        self.sp_myRankBg:setVisible(bl_ranked and data.p_rank > 3)
    end
    if self.sp_otherRankBg then
        self.sp_otherRankBg:setVisible(bl_ranked and data.p_rank > 3)
    end
    if self.sp_rankBg then
        self.sp_rankBg:setVisible(bl_ranked and data.p_rank > 3)
    end
    self.lb_rank:setVisible(bl_ranked and data.p_rank > 3)
    self.lb_rank:setString(data.p_rank)
    -- 没有图标的 用数字显示
    if self.sp_1st then
        self.sp_1st:setVisible(data.p_rank == 1)
    else
        if self.sp_myRankBg then
            self.sp_myRankBg:setVisible(bl_ranked)
        end
        if self.sp_otherRankBg then
            self.sp_otherRankBg:setVisible(bl_ranked)
        end
        if self.sp_rankBg then
            self.sp_rankBg:setVisible(bl_ranked)
        end
        self.lb_rank:setVisible(bl_ranked)
    end

    if self.sp_2nd then
        self.sp_2nd:setVisible(data.p_rank == 2)
    else
        if self.sp_myRankBg then
            self.sp_myRankBg:setVisible(bl_ranked)
        end
        if self.sp_otherRankBg then
            self.sp_otherRankBg:setVisible(bl_ranked)
        end
        if self.sp_rankBg then
            self.sp_rankBg:setVisible(bl_ranked)
        end
        self.lb_rank:setVisible(bl_ranked)
    end

    if self.sp_3rd then
        self.sp_3rd:setVisible(data.p_rank == 3)
    else
        if self.sp_myRankBg then
            self.sp_myRankBg:setVisible(bl_ranked)
        end
        if self.sp_otherRankBg then
            self.sp_otherRankBg:setVisible(bl_ranked)
        end
        if self.sp_rankBg then
            self.sp_rankBg:setVisible(bl_ranked)
        end
        self.lb_rank:setVisible(bl_ranked)
    end
    --设置名称
    local name = ""
    if data and data.p_name then
        name = data.p_name
    end
    local lb_name, layer_name
    if self:isMyRank() then
        lb_name = self.lb_myId
        layer_name = self.layer_myId
    else
        lb_name = self.lb_otherId
        layer_name = self.layer_otherId
    end    
    if lb_name then
        lb_name:setString(name)
    end
    if lb_name and layer_name then
        lb_name:stopAllActions()
        local widthlb = lb_name:getContentSize().width
        local widthly = layer_name:getContentSize().width
        if widthlb > widthly then
            util_wordSwing(lb_name, 1, layer_name, 2, 30, 2)
        end
    end

    -- 设置点数
    if data and data.p_points then
        self.lb_point:setString(util_formatCoins(tonumber(data.p_points), 5))
    end
end

function BaseRankUserCell:showRewards(reward_data)
    if not self.reward_item then
        if not self.node_reward then
            printError("奖励挂点不存在")
            return
        end
        local item_path = self:getRewardItemPath()
        if not item_path then
            printError("BaseRankUserCell:showRewards 资源路径未指定")
            return
        end
        local reward_item = util_createView(item_path)
        if reward_item then
            reward_item:addTo(self.node_reward)
            self.reward_item = reward_item
        else
            printError("奖励控件创建失败")
            return
        end
    end

    self.reward_item:showRewards(reward_data)
end

-- function BaseRankUserCell:isMyRank()
--     if not self:getCompareIdx() then
--         return false
--     end
--     local rank_data = self:getRankData()
--     if not rank_data or table.nums(rank_data) <= 0 then
--         return false
--     end

--     if self:getIndex() == self:getCompareIdx() then
--         return true
--     end
--     return false
-- end

function BaseRankUserCell:setIndex(rankIdx)
    self.rankIdx = rankIdx
end

function BaseRankUserCell:getIndex()
    return self.rankIdx
end

function BaseRankUserCell:setCompareIdx(idx)
    self.compareIdx = idx
end

function BaseRankUserCell:getCompareIdx()
    return self.compareIdx
end

function BaseRankUserCell:setRankData(rank_data)
    self.rank_data = rank_data
end

function BaseRankUserCell:getRankData()
    return self.rank_data
end

function BaseRankUserCell:getContentSize()
    if self:isMyRank() then
        if self.sp_myRank then
            return self.sp_myRank:getContentSize()
        end
    else
        if self.sp_otherRank then
            return self.sp_otherRank:getContentSize()
        end
    end
    assert(false, "获取 BaseRankUserCell 控件大小失敗 默认背景图片命名不一致")
end

function BaseRankUserCell:setCsbName(csb_res)
    self.csb_res = csb_res
end

function BaseRankUserCell:getCsbName()
    return self.csb_res
end

function BaseRankUserCell:setRewardItemPath(item_path)
    self.rewardItem_path = item_path
end

function BaseRankUserCell:getRewardItemPath()
    return self.rewardItem_path
end

function BaseRankUserCell:clickFunc(_sender)
    local name = _sender:getName()
    if name == "layout_touch" then
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.rank_data.p_udid, "", "", self.rank_data.p_frameId)
    end
end

return BaseRankUserCell
