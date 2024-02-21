--[[
    特殊卡册标题奖励-购物主题
]]
local ObsidianCardTitleReward = class("ObsidianCardTitleReward", BaseView)

function ObsidianCardTitleReward:initDatas(_index)
    self.m_index = _index
end

function ObsidianCardTitleReward:getCsbName()
    return "CardRes/CardObsidian_5/csb/main/ObsidianAlbum_title_reward.csb"
end

function ObsidianCardTitleReward:initCsbNodes()
    self.m_lbChips = self:findChild("lb_chips")
    self.m_lbCompleted = self:findChild("lb_completed")

    self.m_nodeCoin = self:findChild("node_coin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_nodeReward = self:findChild("node_card")
end

function ObsidianCardTitleReward:initUI()
    ObsidianCardTitleReward.super.initUI(self)
    self:initCoins()
    self:initChips()
end

function ObsidianCardTitleReward:initCoins()
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData()
    if not data then
        return
    end
    local rewardData = self:getPhaseReward()
    if not rewardData then
        return
    end
    if data:isPhaseRewardCompleted(self.m_index) then
        self.m_nodeCoin:setVisible(false)
        self.m_lbCompleted:setVisible(true)
    else
        self.m_nodeCoin:setVisible(true)
        self.m_lbCompleted:setVisible(false)
        -- 金币
        local coinNum = rewardData:getCoins()
        self.m_lbCoin:setString(util_formatCoins(coinNum, 3))
        local items = rewardData:getItems()
        if items and #items > 0 then
            self.m_lbCoin:setString(util_formatCoins(coinNum, 3) .. " +")
        end
        local uiList = {
            {node = self.m_spCoin, scale = 0.43, alignX = -15},
            {node = self.m_lbCoin, scale = 0.3, alignX = 17}
        }
        --道具
        local itemDataList = {}
        if items and #items > 0 then
            for i, v in ipairs(items) do
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
        if #itemDataList > 0 then
            local len = #itemDataList
            local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
            local height = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
            local width = height * #itemDataList
            self.m_nodeReward:addChild(itemNode)
            table.insert(uiList, {node = self.m_nodeReward, scale = 0.3, alignX = 8 + 14 * (len - 1), size = cc.size(width * 0.3, height * 0.3)})
        end

        util_alignCenter(uiList)
    end
end

function ObsidianCardTitleReward:initChips()
    local rewardData = self:getPhaseReward()
    if not rewardData then
        return
    end
    local chipNum = rewardData:getNum()
    self.m_lbChips:setString(chipNum .. " CHIPS")
end

function ObsidianCardTitleReward:getPhaseReward()
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData()
    if not data then
        return
    end
    return data:getPhaseRewardByIndex(self.m_index)
end

return ObsidianCardTitleReward
