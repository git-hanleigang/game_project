--[[
Author: cxc
Date: 2021-07-27 19:50:11
LastEditTime: 2021-07-27 19:50:12
LastEditors: your name
Description: 公会任务 已完成 奖励面板
FilePath: /SlotNirvana/src/views/clan/taskReward/ClanTaskRewardDoneInfoPanel.lua
--]]
local ClanTaskRewardDoneInfoPanel = class("ClanTaskRewardDoneInfoPanel", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ClanTaskRewardDoneInfoPanel:ctor()
    ClanTaskRewardDoneInfoPanel.super.ctor(self)

    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)

    self.m_rewardCoinNum = 0 -- 奖励的金币数
    self.m_rewardGemNum = 0 -- 奖励的钻石数

    self:setExtendData("ClanTaskRewardDoneInfoPanel")
    self:setShownAsPortrait(globalData.slotRunData:isMachinePortrait())
    self:setLandscapeCsbName("Club/csd/Rewards/ClubReward_success_Reward.csb")
end

function ClanTaskRewardDoneInfoPanel:initUI(_rewards)
    ClanTaskRewardDoneInfoPanel.super.initUI(self)
    _rewards = _rewards or {}

    local shopItemList = {}

    -- 金币
    self.m_rewardCoinNum = tonumber(_rewards.coins) or 0
    local lbCoins = self:findChild("lb_coin_number")
    lbCoins:setString(util_getFromatMoneyStr(self.m_rewardCoinNum))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 905, 0.7)
    util_alignCenter(
        {
            {node = self:findChild("sp_coin")},
            {node = lbCoins, alignX = 5}
        }
    )

    -- 奖励
    local itemList = _rewards.items or {}
    self.m_darts = {}
    for _, data in pairs(itemList) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        if shopItem.p_icon == "Gem" then
            self.m_rewardGemNum = self.m_rewardGemNum + shopItem:getNum()
        end
        if shopItem.p_icon == "DART_BALLON" then
            table.insert(self.m_darts,shopItem)
        end
        if CardSysManager:isNovice() and shopItem.p_type == "Package" then
            -- 新手集卡期不显示 集卡 道具
        else
            table.insert(shopItemList, shopItem)
        end
    end

    local nodeItems = self:findChild("Node_Rewards_other")
    local shopItemsUI = gLobalItemManager:addPropNodeList(table_values(shopItemList), ITEM_SIZE_TYPE.REWARD, nil, nil, false)
    shopItemsUI:addTo(nodeItems)
    self.m_shopItemList = shopItemList

    -- btn
    self.m_btnCollect = self:findChild("btn_collect")
end

function ClanTaskRewardDoneInfoPanel:onShowedCallFunc()
    ClanTaskRewardDoneInfoPanel.super.onShowedCallFunc(self)

    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle")
        end,
        60
    )

    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.TASK_DONE_REWARD_INFO)
end

function ClanTaskRewardDoneInfoPanel:onClickMask()
    self:onClickCollect()
end

function ClanTaskRewardDoneInfoPanel:onClickCollect()
    if self.m_bCollected then
        return
    end
    self.m_bCollected = true

    -- 领取 奖励
    if self.m_rewardCoinNum > 0 then
        self:collectRewards()
    else
        self:closeUI()
    end
end

function ClanTaskRewardDoneInfoPanel:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_collect" then
        self:onClickCollect()
    end
end

-- 领取奖励
function ClanTaskRewardDoneInfoPanel:collectRewards()
    local callback = function()
        self:closeUI()
    end

    local senderSize = self.m_btnCollect:getContentSize()
    local startPos = self.m_btnCollect:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))

    -- 飞货币
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local flyList = {}
        if self.m_rewardCoinNum > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_rewardCoinNum, startPos = startPos})
        end
        if self.m_rewardGemNum > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_rewardGemNum, startPos = startPos})
        end

        cuyMgr:playFlyCurrency(flyList, callback)
    else
        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_rewardCoinNum, callback)
    end
    
end

function ClanTaskRewardDoneInfoPanel:closeUI()
    local cb = function()
        -- 掉卡
        if CardSysManager:needDropCards("Clan Points") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    ClanTaskRewardDoneInfoPanel.super.closeUI(self, handler(self,self.triggerDropDartsGameItem))
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Clan Points")
        else
            ClanTaskRewardDoneInfoPanel.super.closeUI(self, handler(self,self.triggerDropDartsGameItem))
        end
    end

    self:runCsbAction("over", false, cb, 60)
end

function ClanTaskRewardDoneInfoPanel:triggerDropDartsGameItem()
    local dartsGameData = G_GetMgr(ACTIVITY_REF.DartsGame):getData()

    if not dartsGameData then
        -- self.m_closeUICb()
        self:triggerDropDartsGameItemNew()
        return
    end

    local bDropNew = dartsGameData:checkIsGainNewGame()
    local newGameData = dartsGameData:getNewGameData()
    if not bDropNew or not newGameData then
        -- self.m_closeUICb()
        self:triggerDropDartsGameItemNew()
        return
    end

    G_GetMgr(ACTIVITY_REF.DartsGame):showTriggerLayer(newGameData, self.m_closeUICb)
end

function ClanTaskRewardDoneInfoPanel:triggerDropDartsGameItemNew()
    local dartsGameData = G_GetMgr(ACTIVITY_REF.DartsGameNew):getData()

    if not dartsGameData then
        if self.m_closeUICb then
            self.m_closeUICb()
        end
        return
    end

    --local bDropNew = dartsGameData:checkIsGainNewGame()
    local newGameData = dartsGameData:getNewGameData()
    if not newGameData then
        if self.m_closeUICb then
            self.m_closeUICb()
        end
        return
    end
    if not self.m_darts or #self.m_darts <= 0 then
        if self.m_closeUICb then
            self.m_closeUICb()
        end
        return
    end

    G_GetMgr(ACTIVITY_REF.DartsGameNew):showTriggerLayer(newGameData, self.m_closeUICb)
end

function ClanTaskRewardDoneInfoPanel:setViewOverFunc(_cb)
    self.m_closeUICb = _cb
end

return ClanTaskRewardDoneInfoPanel
