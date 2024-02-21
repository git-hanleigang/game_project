local UserInfoBag = class("UserInfoBag", BaseLayer)

function UserInfoBag:ctor()
    UserInfoBag.super.ctor(self)
    self:setExtendData("UserInfoBag")
    self:setLandscapeCsbName("Activity/csd/Information_BackBag/Iformation_zong/Information_zong.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self:setMaskEnabled(false)
end

function UserInfoBag:initView()
	self:updataTabview()
    self:updataItem()
end

function UserInfoBag:updataTabview()
    local size = cc.size(615,520)
    local param = {
        tableSize = size,
        parentPanel = self:findChild("root"),
        directionType = 2
    }
    self.m_tableView = util_require("views.UserInfo.view.UserInfoHeadTableView").new(param)
    self:findChild("root"):addChild(self.m_tableView)
    self.m_tableView:setPosition(375,10)
    if self.ManGer:getData():getBagItem() and #self.ManGer:getData():getBagItem() > 0 then
        self.empty_text:setVisible(false)
        self.node_bg:setVisible(true)
    else
        self.empty_text:setVisible(true)
        self.node_bg:setVisible(false)
    end
    self.m_tableView:reload(self.ManGer:getData():getBagItem(),3)
end

function UserInfoBag:initCsbNodes()
    self.amount = self:findChild("txt_desc_0")
    self.desc = self:findChild("txt_desc")
    self.reward_name = self:findChild("txt_reward_desc")
    self.node_reward = self:findChild("node_reward")
    self.btn_use = self:findChild("btn_use")
    self.empty_text = self:findChild("Text_empty")
    self.node_bg = self:findChild("Node_bg")
    self:findChild("txt_desc2"):setVisible(false)
end

function UserInfoBag:updataItem()
    local _data = self.ManGer:getData():getChooseItem()
    if _data == nil or _data.name == nil then
        return
    end
    -- 物品名字
    self.reward_name:setString(_data.name or "")

    -- 物品数量
    -- 如果显示的是代币，这里特殊处理一下数量
    local isBuck = _data.shop and _data.shop.p_icon == ShopBuckConfig.ItemIcon
    if isBuck then
        local buckNum = G_GetMgr(G_REF.ShopBuck):getBuckNum()
        self.amount:setString(util_cutCoins(buckNum, true, 2))
    else
        local num = _data.num
        if num <= 0 then
            num = 1
        end
        self.amount:setString("Amount: "..num)
    end
    -- 物品描述
    local desc = _data.description or ""
    util_AutoLine(self.desc, desc, 270, true)
    -- 物品icon
    local shopdata = _data.shop
    shopdata.p_mark = nil
    local shopItemUI = gLobalItemManager:createRewardNode(shopdata, ITEM_SIZE_TYPE.REWARD)
    if shopItemUI ~= nil then
        local shop1 = self.node_reward:getChildByName("Shop_Item1")
        if shop1 ~= nil and not tolua.isnull(shop1) then
            self.node_reward:removeChildByName("Shop_Item1")
        end 
        self.node_reward:addChild(shopItemUI)
        shopItemUI:setName("Shop_Item1")
        shopItemUI:setIconTouchEnabled(false)
    end

    local activityId = _data.activityId or "-1"
    local isShowBtn = activityId ~= "-1"
    if isBuck then
        isShowBtn = true
    end
    local actData = G_GetActivityDataById(activityId, true)
    self.btn_use:setVisible(isShowBtn)
    if _data.open then
        if actData or isBuck then
            self.btn_use:setTouchEnabled(true)
            self:setButtonLabelAction(self.btn_use, false)
        else
            self.btn_use:setTouchEnabled(false)
            self:setButtonLabelAction(self.btn_use, true)    
        end
    else
        self.btn_use:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_use, true)
    end
    if actData then
        local downloadName = actData:getThemeName()
        local isDl = globalDynamicDLControl:checkDownloaded(downloadName)
        if not isDl then
            self.btn_use:setTouchEnabled(false)
            self:setButtonLabelAction(self.btn_use, true)
        end
    end
end


function UserInfoBag:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self:updataItem()
    end,self.config.ViewEventType.BAG_ITEM_CLICKED)

    -- 购买代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updataItem()
        end,
        ViewEventType.NOTIFY_PURCHASE_BUCK_SUCCESS
    )    
    -- 花费代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.isConsumeBuck then
                self:updataItem()
            end
        end,
        ViewEventType.NOTIFY_PURCHASE_SUCCESS
    )    
end

function UserInfoBag:onEnter()
    self:registerListener()
end



function UserInfoBag:clickStartFunc(sender)
end

function UserInfoBag:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_use" then
        --去用
        local _data = self.ManGer:getData():getChooseItem()
        
        -- 如果显示的是代币，这里特殊处理一下
        local isBuck = _data.shop and _data.shop.p_icon == ShopBuckConfig.ItemIcon
        if isBuck then
            G_GetMgr(G_REF.Shop):showMainLayer()
            -- 商城不切换横竖版，这里不要打开下面这一行，否则在竖版关卡打开横版公会再打开个人信息在进入商城后，横竖版显示出错
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_OPEN_USER_INFO_LAYER_SYSTEM)
            -- G_GetMgr(G_REF.UserInfo):exitGame()
            return
        end  
        
        local activityId = _data.activityId
        local actData = G_GetActivityDataById(activityId, true)
        if actData then
            -- 主活动
            local downloadName = actData:getRefName()
            local _mgr = G_GetMgr(downloadName)
            if _mgr then
                _mgr:showMainLayer()
            else
                local activityName = self.UserInfoConfig.ActivityMainViewMap[downloadName]
                gLobalActivityManager:showActivityMainView(downloadName, activityName)
            end
            -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_OPEN_USER_INFO_LAYER_SYSTEM)
            G_GetMgr(G_REF.UserInfo):exitGame()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
    end
end

return UserInfoBag