--星星奖励界面奖励节点
local QuestNewChapterStarPrizesRewardNode = class("QuestNewChapterStarPrizesRewardNode", util_require("base.BaseView"))

QuestNewChapterStarPrizesRewardNode.NoneRank = 360

function QuestNewChapterStarPrizesRewardNode:initDatas(data)
    self.m_starData = data.starData 
    self.m_chapterId = data.chapterId
end

function QuestNewChapterStarPrizesRewardNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewChapterStarPrizesRewardNode 
end

function QuestNewChapterStarPrizesRewardNode:initCsbNodes()
    self.m_node_reward = self:findChild("node_jiangli") 
    self.m_node_Bubble = self:findChild("node_Bubble") 
    self:initView()
end

function QuestNewChapterStarPrizesRewardNode:initView()
    local touch = G_GetMgr(ACTIVITY_REF.QuestNew):makeTouch(cc.size(140, 140), "touch")
    self:addChild(touch, 1)
    self:addClick(touch)
    self:initReward()
    self:updateState()
end

function QuestNewChapterStarPrizesRewardNode:initReward()
    local propList = {}
    -- 通用道具
    if self.m_starData.p_items and #self.m_starData.p_items > 0 then
        for i, v in ipairs(self.m_starData.p_items) do
            propList[#propList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
        end
    end
    if self.m_starData.p_coins and self.m_starData.p_coins > 0 then
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(self.m_starData.p_coins), {p_limit = 3})
    end
    self.m_propList = propList
    if #propList > 0 then
        local itemData = propList[1]
        local newItemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD_BIG)
        if newItemNode then -- csc 2021-11-28 18:00:06 修复如果邮件里包含的道具如果不存在报错的情况
            gLobalDailyTaskManager:setItemNodeByExtraData(itemData, newItemNode)
        end
        newItemNode:setScale(0.5)
        self.m_node_reward:addChild(newItemNode)
    end
end

function QuestNewChapterStarPrizesRewardNode:updateState()
    self.m_isUnlock = false
    local currentChapterStarNum,currentChapterMaxStarNum = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterPickStars(self.m_chapterId)
    if self.m_starData.p_collected then
        self:runCsbAction("yaan", false)
    else
        if self.m_starData.p_stars > currentChapterStarNum then
            self.m_isUnlock = true
            self:runCsbAction("lock", false)
        else
            self:runCsbAction("idle", true)
        end
    end
end

function QuestNewChapterStarPrizesRewardNode:doUnlockAct(callBack)
    self.m_isUnlock = false
    self:runCsbAction("jiesuo", false,function ()
        if callBack then
            callBack()
        end
    end)
end
function QuestNewChapterStarPrizesRewardNode:changeToCompleted()
    self:runCsbAction("yaan", false)
end

function QuestNewChapterStarPrizesRewardNode:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        if self.m_isUnlock then
            self:runCsbAction("suo", false)
        end
    end
end

function QuestNewChapterStarPrizesRewardNode:doBubble()
    if not self.m_boxBubbleNode then
        self.m_boxBubbleNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapBoxBubbleNode)
        self.m_boxBubbleNode:setScale(0.8)
        self.m_node_Bubble:addChild(self.m_boxBubbleNode)
    end
    self.m_boxBubbleNode:doShowOrHide()
end

return QuestNewChapterStarPrizesRewardNode
