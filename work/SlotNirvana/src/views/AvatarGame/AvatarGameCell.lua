--[[
    
]]

local AvatarGameCell = class("AvatarGameCell", BaseView)

function AvatarGameCell:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_cell.csb"
end

function AvatarGameCell:initCsbNodes()
    self.m_sp_scene1 = self:findChild("sp_scene1")
    self.m_sp_scene2 = self:findChild("sp_scene2")
    self.m_node_reward1 = self:findChild("node_reward1")
    self.m_node_reward2 = self:findChild("node_reward2")
    self.m_big_reward1 = self:findChild("big_reward1")
    self.m_big_reward2 = self:findChild("big_reward2")

    if self.m_index % 2 == 1 then 
        self.m_sp_scene2:setVisible(false)
        self.m_node_reward = self.m_node_reward1
        self.m_big_reward = self.m_big_reward1
    else
        self.m_sp_scene1:setVisible(false)
        self.m_node_reward = self.m_node_reward2
        self.m_big_reward = self.m_big_reward2
    end
end

function AvatarGameCell:initDatas(_index, _isUpdateReward)
    self.m_index = _index
    self.m_hasUpdateReward = _isUpdateReward
end

function AvatarGameCell:initUI()
    AvatarGameCell.super.initUI(self)

    self:rewardUpdate()
end

function AvatarGameCell:updateReward()
    self.m_node_reward:removeAllChildren()

    local gameData = globalData.avatarFrameData:getMiniGameData()
    local cellList = gameData:getCellList()
    if cellList and cellList[self.m_index] then 
        local cellData = cellList[self.m_index]
        if not cellData:isBigReward() then 
            self.m_big_reward:setVisible(false)
            local type = cellData:getRewardType()
            local rewardInfo = nil
            if type == "Coins" then 
                rewardInfo = gLobalItemManager:createLocalItemData("Coins", cellData:getCoins())
                rewardInfo:setTempData({p_limit = 3})
            elseif type == "Item" then
                local items = cellData:getRewardList()
                local item = items[1]
                if item then 
                    rewardInfo = gLobalItemManager:createLocalItemData(item.p_icon, item.p_num, item)
                end
            end
    
            if rewardInfo then 
                local itemNode = gLobalItemManager:createRewardNode(rewardInfo, ITEM_SIZE_TYPE.REWARD)
                self.m_node_reward:addChild(itemNode)
            end
        else
            self.m_big_reward:setVisible(true)
        end
    end
end

function AvatarGameCell:rewardUpdate()
    self:updateScene()
    self:updateReward()
end

function AvatarGameCell:updateScene()
    if self.m_hasUpdateReward then 
        self.m_hasUpdateReward = false
        util_changeTexture(self.m_sp_scene1, "Activity/img/frame_cashDice/frame_scene1_jin.png")
        util_changeTexture(self.m_sp_scene2, "Activity/img/frame_cashDice/frame_scene2_jin.png")
        util_changeTexture(self.m_big_reward, "Activity/img/frame_cashDice/frame_jackpot_jin.png")
    else
        self.m_hasUpdateReward = true
        util_changeTexture(self.m_sp_scene1, "Activity/img/frame_cashDice/frame_scene1.png")
        util_changeTexture(self.m_sp_scene2, "Activity/img/frame_cashDice/frame_scene2.png")
        util_changeTexture(self.m_big_reward, "Activity/img/frame_cashDice/frame_jackpot.png")
    end
end

return AvatarGameCell