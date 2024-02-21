--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-15 11:44:04
]]
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_FrameChallengeReward = class("InboxItem_FrameChallengeReward", InboxItem_baseReward)

function InboxItem_FrameChallengeReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_FrameChallengeReward:getCardSource()
    return {"Frame Challenge"}
end
-- 描述说明
function InboxItem_FrameChallengeReward:getDescStr()
    return "FRAME CHALLENGE REWARD"
end

function InboxItem_FrameChallengeReward:initData()
    InboxItem_FrameChallengeReward.super.initData(self)
    self.m_propsBagList = {}
end

-- 尝试 掉落合成福袋
function InboxItem_FrameChallengeReward:initDropPropsBagLayer()
    if #self.m_items > 0 then 
        local rewardItems = self:mergeItems(self.m_items)
        for i,v in ipairs(rewardItems) do
            if string.find(v.p_icon, "Pouch") then
                table.insert(self.m_propsBagList, v)
            end
        end
        -- 合成福包弹板
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        mergeManager:setPopPropsBagTempList(self.m_propsBagList)
    end
end


function InboxItem_FrameChallengeReward:collectMailSuccess()
    local sourceList = self:getCardSource()
    self:initDropPropsBagLayer()
    local startDropCards = function ()
        if sourceList and #sourceList > 0 then 
            local bool = true
            for i,v in ipairs(sourceList) do
                if CardSysManager:needDropCards(v) == true then 
                    bool = false
                    CardSysManager:doDropCards(v, function()
                        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                        local cb = function()
                            mergeManager:resetPropsBagTempList()
                            globalDeluxeManager:dropExperienceCardItemEvt()
                        end
                        mergeManager:autoPopPropsBagLayer(cb)
                    end)
                    break
                end    
            end
            if bool then
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                local cb = function()
                    mergeManager:resetPropsBagTempList()
                    globalDeluxeManager:dropExperienceCardItemEvt()
                end
                mergeManager:autoPopPropsBagLayer(cb)
            end
        else
            local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
            local cb = function()
                mergeManager:resetPropsBagTempList()
                globalDeluxeManager:dropExperienceCardItemEvt()
            end
            mergeManager:autoPopPropsBagLayer(cb)
        end
    end

    if toLongNumber(self.m_coins) > toLongNumber(0) or self.m_gems > 0 then 
        self:flyBonusGameCoins(startDropCards)
    else
        startDropCards()
        self:removeSelfItem()
    end
end

return InboxItem_FrameChallengeReward
