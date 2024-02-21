--[[--
    宝箱奖励
]]
-- 宝箱奖励类型
local BOX_REWARD_TYPE = {
    NONE = "NONE",
    PACKAGE = "PACKAGE",
    COINS = "COINS",
    ITEMS = "ITEMS"
}

local BaseView = util_require("base.BaseView")
local PuzzleGameMainBoxContent = class("PuzzleGameMainBoxContent", BaseView)

function PuzzleGameMainBoxContent:initUI()
    self:createCsbNode(CardResConfig.PuzzleGameMainBoxAwardRes)
    self.m_rewardNode = self:findChild("Node_reward")
    self.m_spCoins = self:findChild("sp_coins")
    self.m_spPackage = self:findChild("sp_package")
    self.m_spItem = self:findChild("sp_item")
    self.m_spGem = self:findChild("sp_gem")
    self.lb_GemNum = self:findChild("lb_GemNum")
    self.lb_CoinNum = self:findChild("lb_CoinNum")

    self.m_rewardNode:setVisible(false)
end

function PuzzleGameMainBoxContent:updateUI(boxData, isForceNULL)
    if isForceNULL then
        self.m_rewardNode:setVisible(false)
        return 
    end
    if boxData.type == BOX_REWARD_TYPE.NONE then
        self.m_rewardNode:setVisible(false)
    else
        self.m_rewardNode:setVisible(true)

        self.m_spCoins:setVisible(false)
        self.m_spPackage:setVisible(false)
        self.m_spItem:setVisible(false)
        self.m_spGem:setVisible(false)

        if boxData.type == BOX_REWARD_TYPE.COINS then
            self.m_spCoins:setVisible(true)
            self.lb_CoinNum:setString(util_formatCoins(boxData.coins, 3))
        elseif boxData.type == BOX_REWARD_TYPE.PACKAGE then
            self.m_spPackage:setVisible(true)
        elseif boxData.type == BOX_REWARD_TYPE.ITEMS then
            if boxData.rewards[1].p_icon == "CardGem" then
                -- 宝石
                self.m_spGem:setVisible(true)
                self.lb_GemNum:setString(boxData.rewards[1].p_num)
            else
                -- 碎片
                self.m_spItem:setVisible(true)            
                local icon = boxData.rewards[1].p_icon
                util_changeTexture(self.m_spItem, "CardRes/season201904/CashPuzzle/img/Common/"..icon..".png")                
            end            
        end

    end
end


function PuzzleGameMainBoxContent:getFlyNode()
    return self.m_spItem
end

return PuzzleGameMainBoxContent