--浇水界面
local FlowerWaterLayer = class("FlowerWaterLayer", BaseView)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}
function FlowerWaterLayer:initUI(_type)
    local path = "Activity/csd/EasterSeason_Operation/EasterSeason_Operation.csb"
    if globalData.slotRunData.isPortrait then
        path = "Activity/csd/EasterSeason_Operation/EasterSeason_Operation_veratical.csb"
    end
    self:createCsbNode(path)
    self._type = _type
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:initView()
end

function FlowerWaterLayer:initCsbNodes()
    self.progress = self:findChild("txt_desc")
    self.sp_silver = self:findChild("sp_silver")
    self.sp_gold = self:findChild("sp_gold")
    self.coin_label = self:findChild("txt_coin")
    self.node_reward1 = self:findChild("node_sprew1")
    self.node_reward2 = self:findChild("node_sprew2")
    self.reward_layer = self:findChild("reward_layer")
end

function FlowerWaterLayer:initView()
    self:registerListener()
    self.m_Hiding = true
    self:updataCoins()
    self:updataFlowers()
    --self:openGuide()
    self.ManGer:setWaterHide(true)
    if self.item_data.kettleNum == 0 then
        self.ManGer:sendPayInfo(self.type_str)
    else
        self.ManGer:sendReward(self.type_str)
    end
end

function FlowerWaterLayer:updataCoins()
    local big_list = {}
    self.type_str = "silver"
    if self._type == ITEM_TYPE.SLVER_ITEM then
        self.item_data = self.m_data.silverResult
        big_list = self.m_data:getSilverBigReward()
    else
        self.type_str = "gold"
        self.item_data = self.m_data.goldResult
        big_list = self.m_data:getGoldBigReward()
    end
    self.sp_silver:setVisible(self._type == ITEM_TYPE.SLVER_ITEM)
    self.sp_gold:setVisible(self._type == ITEM_TYPE.GOLD_ITEM)
    local str = self.item_data.kettleNum.."/7"
    self.progress:setString(str)
    local nums = big_list[#big_list].con
    local text_coin = util_formatCoins(tonumber(nums),9).."+"
    self.coin_label:setString(text_coin)
    local scale = 0.31
    local wt = 0.4
    if globalData.slotRunData.isPortrait then
        scale = 0.24
        wt = 0.3
    end
    local pos_X = self.coin_label:getPositionX() + self.coin_label:getContentSize().width*scale + 30
    local width = 30 + self.coin_label:getContentSize().width*scale + 70
    --改成自适配奖励
    for i=1,3 do
        local node = self:findChild("node_sprew"..i)
        local str = "shopItemUI_rew"..i
        if node:getChildByName(str) ~= nil and not tolua.isnull(node:getChildByName(str)) then
            node:removeChildByName(str)
        end
        if big_list[i] then
            local shopItemUI = gLobalItemManager:createRewardNode(big_list[i], ITEM_SIZE_TYPE.REWARD)
            node:addChild(shopItemUI)
            shopItemUI:setName(str)
            local pos = pos_X + (128+5)*(i-1)*wt
            node:setPositionX(pos)
            if i > 1 then
                width = width + (128+5)*wt
            end
        end
        node:setScale(wt)
    end
    
    local size = cc.size(width,self.reward_layer:getContentSize().height)
    self.reward_layer:setContentSize(size)
end

function FlowerWaterLayer:updataFlowers()
    local index_list = {}
    self.item_list = {}
    if self._type == ITEM_TYPE.SLVER_ITEM then
        index_list = self.m_data:getSilverIndexList()
    else
        index_list = self.m_data:getGoldIndexList()
    end
    for i=1,7 do
        local node = self:findChild("node_flower"..i)
        node:removeAllChildren()
    end
    for i=1,#index_list do
        local inde = index_list[i] + 1
        local node = self:findChild("node_flower"..inde)
        local param = {}
        param.type = self._type
        param.index = index_list[i]
        local view = util_createView("views.FlowerCode.FlowerWaterItem",param)
        view:setName("WaterItem")
        node:addChild(view)
        table.insert(self.item_list,view)
    end
end

function FlowerWaterLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _type)
            local data = {}
            if self._type == ITEM_TYPE.SLVER_ITEM then
                data = self.m_data:getSilverPayInfo()
            else
                data = self.m_data:getGoldPayInfo()
            end
            if #data > 0 then
                local view = util_createView("views.FlowerCode.FlowerBuyLayer",self._type)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
        end,
        self.config.EVENT_NAME.INIT_PAY_INFO
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _num)
            local param = {}
            param.type = self._type
            param.num = _num
            gLobalSoundManager:playSound(self.config.SOUND.PAY)
            self.ManGer:showRewardLayer(param)
            if self._type == ITEM_TYPE.SLVER_ITEM then
                self.item_data = self.m_data.silverResult
            else
                self.item_data = self.m_data.goldResult
            end
            local str = self.item_data.kettleNum.."/7"
            self.progress:setString(str)
            self.ManGer:sendReward(self.type_str)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FLOWER)
        end,
        self.config.EVENT_NAME.NOTIFY_FLOWER_BUY_SUCCESS
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            local isBig = self.m_data:getIsBig()
            local inde = _index + 1
            local node = self:findChild("node_flower"..inde)
            local view = node:getChildByName("WaterItem")
            if view and not tolua.isnull(view) then
                view:playEndAnima(isBig)
            end

            if self._type == ITEM_TYPE.SLVER_ITEM then
                self.item_data = self.m_data.silverResult
            else
                self.item_data = self.m_data.goldResult
            end
        end,
        self.config.EVENT_NAME.NOTIFY_FLOWER_WATER
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _data)
            if self._type == ITEM_TYPE.SLVER_ITEM then
                self.item_data = self.m_data.silverResult
            else
                self.item_data = self.m_data.goldResult
            end
        end,
        self.config.EVENT_NAME.INIT_REWARD_INFO
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
           local str = self.item_data.kettleNum.."/7"
           self.progress:setString(str)
           gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FLOWER)
           self:createRewardLayer()
        end,
        self.config.EVENT_NAME.ITEM_END
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            if _index < 3 then
                self:setOpenGuide(_index)
            else
                self:resetGuideNode()
                if self.item_data.kettleNum == 0 then
                    self.ManGer:sendPayInfo(self.type_str)
                else
                    self.ManGer:sendReward(self.type_str)
                end
                self.ManGer:setWaterHide(true)
                for i,v in ipairs(self.item_list) do
                    v:setBtnTouch(true)
                end
            end
        end,
        self.config.EVENT_NAME.NOTIFY_WATER_GUIDE
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            self:updataCoins()
        end,
        self.config.EVENT_NAME.NOTIFY_FLOWER_GUIDE
    )

end

function FlowerWaterLayer:createRewardLayer()
    self.m_catFoodList = {}
    self.m_propsBagist = {}
    local itemList = self.m_data:getItemReward()
    local isBig = self.m_data:getIsBig()
    local clickFunc = function()
        if tolua.isnull(self) then
            G_GetMgr(G_REF.Flower):setWaterHide(true)
            return
        end
        --检查掉卡
        if CardSysManager:needDropCards("Flower") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                   --掉卡完成
                   if #self.m_propsBagist > 0 then
                       self:triggerPropsBagView(isBig)
                   else
                       self:resfuh(isBig)
                   end
                   
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Flower")
        else
            if #self.m_propsBagist > 0 then
                self:triggerPropsBagView(isBig)
            else
                self:resfuh(isBig)
            end
        end
        G_GetMgr(G_REF.Flower):setWaterHide(true)
    end
    for i,v in ipairs(itemList) do
        if v.p_icon then
            if string.find(v.p_icon, "CatFood") then
                table.insert(self.m_catFoodList, v)
            end
            if string.find(v.p_icon, "Pouch") then
                -- local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                -- mergeManager:refreshBagsNum(v.p_icon, v.p_num)
                table.insert(self.m_propsBagist, v)
            end
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
    local coins = self.m_data:getEndCoins()
    local view = util_createView("views.FlowerCode.FlowerRewardLayer",itemList,clickFunc,coins,true,isBig)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    performWithDelay(self, function()
        self:updataFlowers()
    end, 0.1)
    if isBig then
        gLobalSoundManager:playSound(self.config.SOUND.REWARD)
    else
        gLobalSoundManager:playSound(self.config.SOUND.REWARD1)
    end
end

function FlowerWaterLayer:triggerPropsBagView(isBig)
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self.m_propsBagist, function()
        if not tolua.isnull(self) then
            self:resfuh(isBig)
        end
    end)
end

function FlowerWaterLayer:resfuh(isBig)
    if isBig then
        if self.m_data:getRemainCoins() ~= 0 then
            local item = self.m_data:getRemainItem()
            local cb = function()
                if not tolua.isnull(self) then
                    gLobalNoticManager:postNotification(self.config.EVENT_NAME.NOTIFY_REWARD_BIG)
                    self:removeFromParent()
                end
            end
            local view = util_createView("views.FlowerCode.FlowerRewardLayer",item,cb,self.m_data:getRemainCoins(),true,3)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        else
            gLobalNoticManager:postNotification(self.config.EVENT_NAME.NOTIFY_REWARD_BIG)
            self:removeFromParent()
        end
        
    else
        if self.item_data.kettleNum == 0 then
            self.ManGer:sendPayInfo(self.type_str)
        end
    end
end


function FlowerWaterLayer:clickStartFunc(sender)
end

function FlowerWaterLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_return" then
        if self.m_Hiding and self.ManGer:getWaterHide() then --防止连续点击
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            gLobalNoticManager:postNotification(self.config.EVENT_NAME.NOTIFY_REWARD_BIG)
            self:removeFromParent()
        end
    end
end

function FlowerWaterLayer:openGuide()
    if not self.m_data:getIsWaterGuide() then
        if self.item_data.kettleNum == 0 then
            self.ManGer:sendPayInfo(self.type_str)
        else
            self.ManGer:sendReward(self.type_str)
        end
        return
    end
    for i,v in ipairs(self.item_list) do
        v:setBtnTouch(false)
    end
    local guideLayer = util_createView("views.FlowerCode.FlowerGuideLayer",2)
    guideLayer:setPosData(2)
    local guide1 = self:findChild("node_guide1")
    local guide2 = self:findChild("node_guide2")
    local stepRefNodes = {guide1,guide2}
    guideLayer:setGuideRefNodes(stepRefNodes)
    self.ManGer:sendWaterGuide("waterFlower")
end


function FlowerWaterLayer:setOpenGuide(_index)
    local sp_prl = self:findChild("sp_reward")
    if _index == 1 then
       self.guide_data = {}
       self:setGuideDate(sp_prl)
    elseif _index == 2 then
        self:resetGuideNode()
        self.guide_data = {}
        for i=1,7 do
            local node = self:findChild("node_flower"..i)
            self:setGuideDate(node)
        end
    end
end

function FlowerWaterLayer:setGuideDate(node)
     local item = {}
     item.node = node
     item.zorder = node:getZOrder()
     item.parent = node:getParent()
     item.pos = cc.p(node:getPosition())
     table.insert(self.guide_data, item)
     local wordPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
     node:setPosition(wordPos)
     self:changeGuideNodeZorder(node,ViewZorder.ZORDER_GUIDE + 3)
end

function FlowerWaterLayer:changeGuideNodeZorder(node, zorder)
    local newZorder = zorder and zorder or ViewZorder.ZORDER_GUIDE + 1
    util_changeNodeParent(gLobalViewManager:getViewLayer(), node, newZorder)
end

function FlowerWaterLayer:resetGuideNode()
    if #self.guide_data > 0 then
        for i,v in ipairs(self.guide_data) do
            util_changeNodeParent(v.parent, v.node, v.zorder)
            v.node:setPosition(v.pos)
        end
    end
end

return FlowerWaterLayer