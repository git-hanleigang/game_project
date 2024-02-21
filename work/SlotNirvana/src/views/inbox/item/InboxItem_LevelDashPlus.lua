local InboxItem_LevelDashPlus = class("InboxItem_LevelDashPlus", util_require("views.inbox.item.InboxItem_baseReward"))
local ShopItem = require "data.baseDatas.ShopItem"

function InboxItem_LevelDashPlus:getCardSource()
    return {"Level Dash Plus"}
end

function InboxItem_LevelDashPlus:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

function InboxItem_LevelDashPlus:getDescStr()
    self.m_content = self.m_mailData.content
    if self.m_content and self.m_content ~= "" then
        self:setButtonLabelContent("btn_inbox", "SEE MORE")
    end
    return self.m_mailData.title or ""
end

function InboxItem_LevelDashPlus:getMergeBagList()
    local list = {}
    if self.m_mailData.awards and self.m_mailData.awards.items and #self.m_mailData.awards.items > 0 then
        for i = 1, #self.m_mailData.awards.items do
            local tempData = ShopItem:create()
            tempData:parseData(self.m_mailData.awards.items[i])
            if string.find(tempData.p_icon, "Pouch") then
                table.insert(list, tempData)
            end
        end
    end
    return list
end

function InboxItem_LevelDashPlus:collectMailSuccess()
    local sourceList = self:getCardSource()
    local startDropCards = function ()
        if tolua.isnull(self) then
            return
        end
        
        if sourceList and #sourceList > 0 then 
            if CardSysManager:needDropCards(sourceList[1]) == true then 
                CardSysManager:doDropCards(sourceList[1], function()
                    globalDeluxeManager:dropExperienceCardItemEvt()
                end)
            else
                local mergeBagList = self:getMergeBagList()
                G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):popMergePropsBagRewardPanel(
                    mergeBagList,
                    function()
                        
                    end
                )
            end
        else
            globalDeluxeManager:dropExperienceCardItemEvt()
        end
    end

    if toLongNumber(self.m_coins) > toLongNumber(0) or self.m_gems > 0 then 
        self:flyBonusGameCoins(startDropCards)
    else
        startDropCards()
        self:removeSelfItem()
    end
end


return InboxItem_LevelDashPlus