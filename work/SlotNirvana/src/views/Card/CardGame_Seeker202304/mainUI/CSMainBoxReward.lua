local CSMainBoxReward = class("CSMainBoxReward", BaseView)

function CSMainBoxReward:initDatas(_boxData, _isGrey)
    self.m_boxData = _boxData
    self.m_isGrey = _isGrey
end

function CSMainBoxReward:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_Box_prize.csb"
end

function CSMainBoxReward:initCsbNodes()
    self.m_nodeReward = self:findChild("Node_prize")
end

function CSMainBoxReward:initUI()
    CSMainBoxReward.super.initUI(self)
    self:initReward()
    self:initRewardColor()
    -- self:playHideIdle()
end

-- function CSMainBoxReward:resetView()
--     self.m_nodeReward:removeAllChildren()
--     self:initRewardColor(false)
--     self:playHideIdle()
-- end

function CSMainBoxReward:playStart(_over)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("show_idle", true, nil, 60)
            if _over then
                _over()
            end
        end,
        60
    )
end

function CSMainBoxReward:playOtherStart(_over)
    self:runCsbAction("start_other", false, _over, 60)
end

function CSMainBoxReward:playHideIdle()
    self:runCsbAction("hide_idle", true, nil, 60)
end

function CSMainBoxReward:playDisappear(_over)
    self:runCsbAction("hide", false, _over, 60)
end

function CSMainBoxReward:playOtherDisappear(_index, _over)
    self:runCsbAction(
        "box_hide",     -- 202304 改
        false,
        function()
            if _over then
                _over(_index)
            end
        end,
        60
    )
end

function CSMainBoxReward:initReward()
    local rewardNode = nil
    local _type = self.m_boxData:getType()
    local value = self.m_boxData:getValue()
    local itemDatas = self.m_boxData:getItems()
    if _type == CardSeekerCfg.BoxType.coin then
        local tempData = gLobalItemManager:createLocalItemData("Coins", value, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        rewardNode = gLobalItemManager:createRewardNode(tempData, ITEM_SIZE_TYPE.REWARD_BIG)
    elseif _type == CardSeekerCfg.BoxType.gem then
        local tempData = gLobalItemManager:createLocalItemData("Gem", value, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        rewardNode = gLobalItemManager:createRewardNode(tempData, ITEM_SIZE_TYPE.REWARD_BIG)
    elseif _type == CardSeekerCfg.BoxType.item then
        for i = 1, #itemDatas do
            if itemDatas[i].p_type == "Package" then
                itemDatas[i]:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
            end
            rewardNode = gLobalItemManager:createRewardNode(itemDatas[i], ITEM_SIZE_TYPE.REWARD_BIG)
            break
        end
    end
    if rewardNode then
        self.m_nodeReward:addChild(rewardNode)
    end
end

function CSMainBoxReward:initRewardColor()
    local color = self.m_isGrey and cc.c3b(127, 115, 150) or cc.c3b(255, 255, 255)
    self.m_nodeReward:setColor(color)
end

return CSMainBoxReward
