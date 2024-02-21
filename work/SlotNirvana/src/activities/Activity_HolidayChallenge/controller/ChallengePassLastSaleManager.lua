--[[
    
    author: csc
    time: 2021-12-09 14:21:22
    聚合挑战最后一天促销 manager
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local ChallengePassLastSaleManager = class("ChallengePassLastSaleManager", BaseActivityControl)

function ChallengePassLastSaleManager:ctor()
    ChallengePassLastSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChallengePassLastSale)

    self.m_reward = nil
end

-- csc 2022-01-22 修改为这个活动只弹出购买
-- function ChallengePassLastSaleManager:getPopName()
--     local saleData = self:getRunningData()
--     if saleData:getPay() == nil then
--         -- 如果是奖励阶段,需要弹出另外的板子
--         -- if self:isCanShowRewardLayer() then
--         --     return self:getThemeName().."RewardLayer"
--         -- else
--             return ""
--         -- end
--     else
--         return self:getThemeName()
--     end
-- end

function ChallengePassLastSaleManager:createRewardLayer()
    local mainLayerPath = "Activity/HolidayLastSalePopupRewardLayer"
    local mainlayer = util_createFindView(mainLayerPath)
    if mainlayer then
        gLobalViewManager:showUI(mainlayer, ViewZorder.ZORDER_UI)
    end
    return mainlayer
end

function ChallengePassLastSaleManager:isCanShowRewardLayer()
    local bHasRewardMail = false
    if not self.m_reward then
        self.m_reward = self:getMailDataHasReward()
        if self.m_reward and table.nums(self.m_reward) > 0 then
            bHasRewardMail = true
        end
    end
    -- 如果当前没有邮件奖励,直接返回
    if not bHasRewardMail then
        return false
    end
    -- 需要判断当前资源是否下载完毕 固定的活动名 不走服务器配置
    if not globalDynamicDLControl:checkDownloaded("Activity_HolidayLastSalePopup") then
        return false
    end
    -- 获取当前邮件的主题 ,用作记录当前主题的促销是否弹出过
    local emailTheme = self.m_reward.theme or "Activity_HolidayChallenge_DefaultPop"
    local theme = string.split(emailTheme, "Activity_HolidayChallenge_")[2]
    local openFlagName = "HolidayChallenge_LastSalePopup_" .. theme
    if gLobalDataManager:getBoolByField(openFlagName, false) then
        return false
    end
    gLobalDataManager:setBoolByField(openFlagName, true)

    return true
end

-- 获得一下当前邮箱中是否有奖励
function ChallengePassLastSaleManager:getMailDataHasReward()
    local reward = nil
    local collectData = G_GetMgr(G_REF.Inbox):getSysRunData()
    if collectData then
        local mailData = collectData:getMailData()
        for i = 1, #mailData do
            if mailData[i].type == InboxConfig.TYPE_NET.HolidayChallengeSaleAward then
                local awards = mailData[i].awards
                reward = {}
                if awards ~= nil then
                    if awards.coins and tonumber(awards.coins) > 0 then
                        reward.coins = tonumber(awards.coins)
                    end
                    if awards.items ~= nil then
                        reward.items = {}
                        for i = 1, #awards.items do
                            local shopItem = ShopItem:create()
                            shopItem:parseData(awards.items[i], true)
                            -- 判断当前奖励中有 小游戏奖励的 话才进行解析
                            if string.find(shopItem.p_icon, "MiniGame_") then
                                shopItem:setTempData({p_num = 1}) -- 小游戏修改数量
                            end
                            reward.items[i] = shopItem
                        end
                    end
                end
                if mailData[i]:HasField("extra") then --mailData[i].extra
                    local extra = cjson.decode(mailData[i].extra)
                    local theme_str = extra.theme
                    reward.theme = theme_str
                end
                break
            end
        end
    end
    return reward
end

function ChallengePassLastSaleManager:getRewardsInfo()
    return self.m_reward
end

return ChallengePassLastSaleManager
