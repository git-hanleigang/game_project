local UserInfoBagItemCell = class("UserInfoBagItemCell", BaseView)

function UserInfoBagItemCell:initDatas()
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
end

function UserInfoBagItemCell:getCsbName()
    return "Activity/csd/Information_BackBag/Information_reward.csb"
end

function UserInfoBagItemCell:initUI()
    UserInfoBagItemCell.super.initUI(self)
    self:initView()
end

function UserInfoBagItemCell:initView()
    local btn_cell = self:findChild("btn_choose")
    btn_cell:setSwallowTouches(false)
    self.sp_choose = self:findChild("sp_choicebox")
    self.sp_reddian = self:findChild("sp_reddian")
    self.txt_reward1 = self:findChild("txt_reward1")
    self.node_reward = self:findChild("node_reward")
    self.sp_num = self:findChild("txt_desc")
end

function UserInfoBagItemCell:updataCell(_data)
    self.item_data = _data
    self:updateName()
    self:updateRedPoint()
    self:updateIcon()
    self:updateChoose()
    self:updateMiddleNum()
    self:registerListener()
end

function UserInfoBagItemCell:updateName()
    self.txt_reward1:setString(self.item_data.name or "")
end

function UserInfoBagItemCell:updateRedPoint()
    local num = self.item_data.num
    if self.sp_reddian then
        self.sp_reddian:setVisible(num > 0)
    end
    if self.sp_num then
        self.sp_num:setString(num)
        util_scaleCoinLabGameLayerFromBgWidth(self.sp_num,30)
    end
end

function UserInfoBagItemCell:updateIcon()
    local shopdata = self.item_data.shop
    shopdata:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
    local shopItemUI = gLobalItemManager:createRewardNode(shopdata, ITEM_SIZE_TYPE.REWARD)
    if shopItemUI ~= nil then
        local shop1 = self.node_reward:getChildByName("Shop_Item")
        if shop1 ~= nil and not tolua.isnull(shop1) then
            self.node_reward:removeChildByName("Shop_Item")
        end 
        self.node_reward:addChild(shopItemUI)
        shopItemUI:setName("Shop_Item")
        shopItemUI:setIconTouchEnabled(false)
    end    
end

function UserInfoBagItemCell:updateChoose()
    local select_id = self.ManGer:getBagCheckItemId()
    self.sp_choose:setVisible(select_id == self.item_data.id)
end

function UserInfoBagItemCell:updateMiddleNum()
end

function UserInfoBagItemCell:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self.sp_choose:setVisible(self.item_data.id == self.ManGer:getBagCheckItemId())
    end,self.config.ViewEventType.BAG_ITEM_CLICKED)
end

function UserInfoBagItemCell:clickCell()
    if self.sp_choose:isVisible() then 
        return 
    end
    self.ManGer:setBagCheckItemId(self.item_data.id)
    self.sp_choose:setVisible(true)
    self.ManGer:getData():setChooseItem(self.item_data)
    gLobalNoticManager:postNotification(self.config.ViewEventType.BAG_ITEM_CLICKED)
end

function UserInfoBagItemCell:clickInfo()
end

function UserInfoBagItemCell:clickStartFunc(sender)

end

function UserInfoBagItemCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_choose" then
        self:clickCell()
    elseif name == "btn_info" then
        self:clickInfo()
    end
end

return UserInfoBagItemCell