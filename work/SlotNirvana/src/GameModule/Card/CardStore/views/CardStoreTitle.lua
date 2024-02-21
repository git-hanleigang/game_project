-- 卡牌商城 商品道具

local CardStoreTitle = class("CardStoreTitle", BaseView)

function CardStoreTitle:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if p_config and p_config.ChipTitle then
        return p_config.ChipTitle
    end
end

function CardStoreTitle:initDatas(title_type)
    self.title_type = title_type
    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
end

function CardStoreTitle:initUI()
    CardStoreTitle.super.initUI(self)
    self:onRefresh()

    if self.title_type == 3 then
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if not tolua.isnull(self) then
                    self:showGem()
                end
            end,
            ViewEventType.FRESH_GEM_LABEL
        )

        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if not tolua.isnull(self) then
                    self:showGem()
                end
            end,
            ViewEventType.NOTIFY_TOP_UPDATE_GEM
        )
    end
end

function CardStoreTitle:initCsbNodes()
    self.lb_chips = self:findChild("lb_chips")
    self.sp_icon1 = self:findChild("sp_icon1")
    self.sp_icon2 = self:findChild("sp_icon2")
    self.sp_icon3 = self:findChild("sp_icon3")
end

function CardStoreTitle:showNormal()
    self.sp_icon1:setVisible(true)
    self.sp_icon2:setVisible(false)
    self.sp_icon3:setVisible(false)

    if not self.store_data then
        return
    end
    local chips = self.store_data:getNormalChipPoints() or 0
    self.lb_chips:setString(chips)
end

function CardStoreTitle:showGolden()
    self.sp_icon1:setVisible(false)
    self.sp_icon2:setVisible(true)
    self.sp_icon3:setVisible(false)

    if not self.store_data then
        return
    end
    local chips = self.store_data:getGoldenChipPoints() or 0
    self.lb_chips:setString(chips)
end

function CardStoreTitle:showGem()
    self.sp_icon1:setVisible(false)
    self.sp_icon2:setVisible(false)
    self.sp_icon3:setVisible(true)
    local gemNum = globalData.userRunData.gemNum
    self.lb_chips:setString(util_getFromatMoneyStr(gemNum))
    -- local GEMS_LABEL_WIDTH = 149 -- 钻石控件的长度
    -- local GEMS_DEFAULT_SCALE = 0.60 -- 钻石控件的缩放
    -- util_scaleCoinLabGameLayerFromBgWidth(self.lb_chips, GEMS_LABEL_WIDTH, GEMS_DEFAULT_SCALE)
end

function CardStoreTitle:onRefresh()
    if self.title_type == 1 then
        self:showNormal()
    elseif self.title_type == 2 then
        self:showGolden()
    elseif self.title_type == 3 then
        self:showGem()
    end
end

return CardStoreTitle
