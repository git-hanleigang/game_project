--[[
    --新版每日任务pass主界面 任务领取界面
    csc 2021-06-21
]]
local BaseCollectLayer = require("base.BaseCollectLayer")
local QuestPassRewardLayer = class("QuestPassRewardLayer", BaseCollectLayer)

function QuestPassRewardLayer:ctor()
    QuestPassRewardLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestPassRewardLayer)
end

function QuestPassRewardLayer:initUI(_collectType)
    self.m_bCollectType = _collectType --  区分当前是哪种模式的收集状态 用来确定时间线

    QuestPassRewardLayer.super.initUI(self)
end

function QuestPassRewardLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_rewards")
    self.m_btnCollect = self:findChild("btn_buy")
    self.m_btnClose = self:findChild("btn_close")
end

function QuestPassRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- 重写父类方法
function QuestPassRewardLayer:playShowAction()
    QuestPassRewardLayer.super.playShowAction(self, "start")
end

function QuestPassRewardLayer:updateView(_params)
    self.m_flyCoins = tonumber(_params.p_coins)
    self.m_flyGems = tonumber(_params.gems)
    self.m_params = _params
    -- 创建奖励道具
    local propList = {}
    if _params.p_items then
        propList = clone(_params.p_items)
    end
    if _params.p_coins and _params.p_coins > 0 then
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(_params.p_coins), {p_limit = 3})
    end
    if #propList > 0 then
        local itemList = {}
        for i = 1, #propList do
            -- 处理一下角标显示
            local itemData = propList[i]
            local newItemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD_BIG)
            if newItemNode then -- csc 2021-11-28 18:00:06 修复如果邮件里包含的道具如果不存在报错的情况
                gLobalDailyTaskManager:setItemNodeByExtraData(itemData, newItemNode)
                itemList[#itemList + 1] = gLobalItemManager:createOtherItemData(newItemNode, 1)
            end
        end
        local size = cc.size(850, 350)
        local scale = self:getUIScalePro()
        if globalData.slotRunData.isPortrait then
            size = cc.size(850, 400)
            scale = 0.84
        end
        --默认大小
        local listView = gLobalItemManager:createRewardListView(itemList, size)
        -- local node = gLobalItemManager:addPropNodeList(propList, ITEM_SIZE_TYPE.REWARD, 1, 128, false)
        listView:setScale(scale)
        self.m_nodeReward:addChild(listView)
        self.m_coinsItem = listView:findCell("Coins")
    end
end

function QuestPassRewardLayer:onClickMask()
    self:onCollect()
end

function QuestPassRewardLayer:onCollect()
    local btnCollect = self:findChild("btn_buy")
    local addCoins = math.max((self.m_addCoins or 0), tonumber(self.m_flyCoins or 0))
    local addGems = tonumber(self.m_flyGems or 0)
    QuestPassRewardLayer.super.onCollect(self, addCoins, btnCollect,addGems)
end

function QuestPassRewardLayer:collectCallback()
    self:closeFunc()
end

function QuestPassRewardLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_buy" or name == "btn_close" then
        self:onCollect()
    end
end

function QuestPassRewardLayer:closeFunc()
    if CardSysManager:needDropCards("Quest Pass") == true then
        gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    self:closeUI()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
        CardSysManager:doDropCards("Quest Pass", nil)
    else
        self:closeUI()
    end
end

return QuestPassRewardLayer
