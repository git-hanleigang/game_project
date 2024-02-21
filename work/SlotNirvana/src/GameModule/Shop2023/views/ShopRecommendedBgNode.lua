local ShopRecommendedBgNode=class("ShopRecommendedBgNode",util_require("base.BaseView"))

function ShopRecommendedBgNode:initUI(_isShowStorePrice,isFramePortrait)
    self.m_isShowStorePrice = _isShowStorePrice
    self.m_isFramePortrait = isFramePortrait

    self:createCsbNode(self:getCsbName(_isShowStorePrice))
    self:updateView()
end

function ShopRecommendedBgNode:getCsbName(_isShowStorePrice)
    local char = "heng"
    if self.m_isFramePortrait == true then
        char = "shu"
    end

    local shopDailySaleData = G_GetMgr(ACTIVITY_REF.ShopDailySale):getRunningData()
    local bgNodePath = SHOP_RES_PATH.RecommendBgDefaultNode
    if shopDailySaleData  then 
        self.m_rewardData = shopDailySaleData:getRewards()
        if not self.m_isShowStorePrice and table.nums(self.m_rewardData.items)  > 0 then
            bgNodePath = shopDailySaleData:getBgIcon()
        end
    end
    bgNodePath = string.split(bgNodePath,".csb")[1].."_"..char..".csb"
    return "Recommended/"..bgNodePath
end

function ShopRecommendedBgNode:updateView()
    local char = "heng"
    if self.m_isFramePortrait == true then
        char = "shu"
    end

    if self.m_isShowStorePrice then
        return 
    end
    
    if table.nums(self.m_rewardData.items) > 0 then
        for i = 1, #self.m_rewardData.items do
            local itemData = self.m_rewardData.items[i]
            if string.find(itemData.p_icon, "club_pass_") then
                local num = tonumber(string.split(itemData.p_icon,"club_pass_")[2]) 
                -- 如果是高倍场体验卡的话 额外做处理
                local sprDay = self:findChild("sp_day_"..char)
                local sprDays = self:findChild("sp_days_"..char)
                local labDay = self:findChild("lb_day_"..char)
                local dayStatus = num > 1 and true or false
                sprDay:setVisible(not dayStatus)
                sprDays:setVisible(dayStatus)
                labDay:setString(num)
                break
            end
        end 
    end
end

function ShopRecommendedBgNode:playRecommendAction(_callback)
    self:runCsbAction("idle", false, function ()
        if _callback then
            _callback()
        end
    end, 60)
end
return ShopRecommendedBgNode