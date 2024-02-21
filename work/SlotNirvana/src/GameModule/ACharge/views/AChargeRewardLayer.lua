--[[
    AppCharge兑换奖励界面
    author:{author}
    time:2023-10-25 15:03:05
]]
local AChargeRewardLayer = class("AChargeRewardLayer", BaseLayer)
function AChargeRewardLayer:initDatas(_productInfo)
    self.m_productInfo = _productInfo
    self:setLandscapeCsbName("AppCharge/Exclusivestore_Layer.csb")
    -- self:setKeyBackEnabled(true)
end

function AChargeRewardLayer:initCsbNodes()
    self.m_scrollView = self:findChild("ScrollView_1")
    -- self.m_scrollView:setBounceEnabled(true)
    self.m_scrollView:setScrollBarEnabled(false)
    self.m_nodeRewards = self:findChild("node_rewards")
end

function AChargeRewardLayer:initView()
    self:initRewards()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function AChargeRewardLayer:initRewards()
    self.m_rewardCoins = tonumber(self.m_productInfo:getCoins() or 0)
    local buk = self.m_productInfo:getBuckNum()
    if buk and buk ~= "" and buk ~= "0" then
        self.m_rawardBuckNum = tonumber(buk)
    end 
    self.m_rewardGems = 0
    -- self.m_rewardItems = self.m_productInfo:getItems()
    local shopCoinsInfo = self.m_productInfo:getShopCoinsInfo()

    local itemDataList = {}
    if self.m_rewardCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_rewardCoins)
        table.insert(itemDataList, itemData)
    end
    if self.m_rewardGems > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Gem", self.m_rewardGems)
        table.insert(itemDataList, itemData)
    end
    if self.m_rawardBuckNum and self.m_rawardBuckNum > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Buck", self.m_rawardBuckNum)
        table.insert(itemDataList, itemData)
    else
        local itemList = gLobalItemManager:checkAddLocalItemList(shopCoinsInfo, shopCoinsInfo.p_displayList)
        table.insertto(itemDataList, itemList)
    end
    
    local propShowList = {}
    for i = 1, #itemDataList do
        if i > 6 then
            propShowList[2] = propShowList[2] or {}
            table.insert(propShowList[2], itemDataList[i])
        else
            propShowList[1] = propShowList[1] or {}
            table.insert(propShowList[1], itemDataList[i])
        end
    end

    local size = self.m_scrollView:getContentSize()
    -- 通用道具宽高一致
    local itemW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
    local lineCount = #propShowList
    for j = 1, lineCount do
        local propNode = nil
        if not self.m_rawardBuckNum then
            propNode = gLobalItemManager:addPropNodeList(propShowList[j], ITEM_SIZE_TYPE.REWARD, 0.75, 195, true)
        else
            propNode = gLobalItemManager:addPropNodeList(propShowList[j], ITEM_SIZE_TYPE.REWARD)
        end
        if propNode then
            self.m_scrollView:addChild(propNode)
            if self.m_rawardBuckNum then
                propNode:setPositionX(self.m_scrollView:getContentSize().width/2)
            end
            if lineCount > 1 then
                propNode:setPositionY(self.m_nodeRewards:getPositionY() * (lineCount - j) + size.height / 4)
            else
                propNode:setPositionY(self.m_nodeRewards:getPositionY())
            end
            for i, v in ipairs(propNode:getChildren()) do
                if v.setIconTouchSwallowed then
                    v:setIconTouchSwallowed(false)
                end
            end
        end
    end
end

function AChargeRewardLayer:collectReward()
    if self.m_productInfo then
        G_GetMgr(G_REF.AppCharge):onCollectAChargeReward(self.m_productInfo:getId(),self.m_rawardBuckNum,handler(self,self.flyBonusGameCoins))
    end
end

function AChargeRewardLayer:flyBonusGameCoins()
    local flyList = {}
    local btnCollect = self:findChild("Btn_Collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    if self.m_rawardBuckNum and self.m_rawardBuckNum > 0 then
        table.insert(flyList, { cuyType = FlyType.Buck, addValue = self.m_rawardBuckNum, startPos = startPos })
    end
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        mgr:playFlyCurrency(flyList, function()
            if not tolua.isnull(self) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
                self:closeUI()
            end
        end)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        self:closeUI()  
    end
end

function AChargeRewardLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "Btn_Collect" then
        self:collectReward()
    end
end

return AChargeRewardLayer
