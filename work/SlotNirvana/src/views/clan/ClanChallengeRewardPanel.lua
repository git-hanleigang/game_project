--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-05-17 10:07:27
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-01 16:16:04
FilePath: /SlotNirvana/src/views/clan/ClanChallengeRewardPanel.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
--[[
Author: cxc
Date: 2021-02-24 10:48:00
LastEditTime: 2021-07-27 11:06:15
LastEditors: Please set LastEditors
Description: 公会宝箱 领取奖励 面板
FilePath: /SlotNirvana/src/views/clan/ClanChallengeRewardPanel.lua
--]]
local ClanChallengeRewardPanel = class("ClanChallengeRewardPanel", BaseLayer)
local ShopItem = util_require("data.baseDatas.ShopItem")

local PAGE_COUNT = 4

function ClanChallengeRewardPanel:ctor()
    ClanChallengeRewardPanel.super.ctor(self)

    self.m_rewardCoinNum = 0 -- 奖励的金币数

    self:setLandscapeCsbName("Club/csd/Rewards/ClubReward.csb")
end

function ClanChallengeRewardPanel:initUI(_rewards)
    ClanChallengeRewardPanel.super.initUI(self)
    _rewards = _rewards or {}

    -- 奖励
    local itemList = _rewards.items or {}
    local shopItemList = {}
    for _, data in pairs(itemList) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        table.insert(shopItemList, shopItem)
    end

    -- 金币
    self.m_rewardCoinNum = tonumber(_rewards.coins) or 0
    if self.m_rewardCoinNum > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_rewardCoinNum, 3))
        table.insert(shopItemList, 1, itemData)
    end

    local nodeItems = self:findChild("node_reward")
    local shopItemsUI = gLobalItemManager:addPropNodeList(table_values(shopItemList), ITEM_SIZE_TYPE.REWARD, nil, nil, false)
    shopItemsUI:addTo(nodeItems)

    -- btn
    self.m_btnCollect = self:findChild("btn_collect")
end

function ClanChallengeRewardPanel:onClickMask()
    self:onClickCollect()
end

function ClanChallengeRewardPanel:onClickCollect()
    -- 领取 奖励
    if self.m_rewardCoinNum > 0 then
        self:collectRewards()
    else
        self:closeUI(
            function()
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
    end
end

function ClanChallengeRewardPanel:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_collect" then
        self:onClickCollect()
    end
end

-- 领取奖励
function ClanChallengeRewardPanel:collectRewards()
    if self.m_bCollected then
        return
    end
    self.m_bCollected = true

    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        --弹窗逻辑执行下一个事件
        self:closeUI()
    end

    local senderSize = self.m_btnCollect:getContentSize()
    local startPos = self.m_btnCollect:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
    gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_rewardCoinNum, callback)
end

return ClanChallengeRewardPanel
