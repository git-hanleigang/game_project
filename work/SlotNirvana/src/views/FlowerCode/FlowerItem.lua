local FlowerItem = class("FlowerItem", BaseView)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}

function FlowerItem:initUI(_type)
    local path = "Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/MainUI_vertical_flower.csb"
    if _type == ITEM_TYPE.SLVER_ITEM then
        path = "Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/MainUI_vertical_flower_2.csb"
    end
    self._type = _type
    self:createCsbNode(path)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    if not globalData.slotRunData.isPortrait then
        self:setScale(1.2)
    end
    self:initView()
end

function FlowerItem:initCsbNodes()
    self.btn_now = self:findChild("btn_now")
    self.sp_true = self:findChild("sp_duihao")
    self.btn_flow = self:findChild("btn_flow")
    self.node_hua = self:findChild("node_hua")
end

function FlowerItem:initView()
    --self:runCsbAction("idle",true)
    self:startButtonAnimation("btn_now", "sweep")
    self:startButtonAnimation("btn_now", "breathe")
    if self._type == 1 then
        self:updataItem(self.m_data:getSilverComplete())
    else
        self:updataItem(self.m_data:getGoldComplete())
    end
    self:initSpine()
    self:registerListener()
end

function FlowerItem:setBtnTouch(_enble)
    self.btn_flow:setTouchEnabled(_enble)
    self.btn_now:setTouchEnabled(_enble)
end

function FlowerItem:initSpine()
    local path = self.config.SPINE_PATH.SILVER
    if self._type == 2 then
        path = self.config.SPINE_PATH.GOLD
    end
    self.m_spine = util_spineCreate(path, true, true, 1)
    self.node_hua:addChild(self.m_spine)
    util_spinePlay(self.m_spine, "idle", true)
end

function FlowerItem:updataItem(complete)
    if complete then
        self.sp_true:setVisible(true)
        self.btn_now:setVisible(false)
    else
        self.sp_true:setVisible(false)
        if self.m_data:getIsWateringDay() then
            self.btn_now:setVisible(true)
        else
            self.btn_now:setVisible(false)
        end
    end
end

function FlowerItem:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            if _index > 2 then
                self:resetGuideNode()
                local node_di = self:findChild("node_di")
                node_di:setScale(1)
            else
                self:setOpenGuide(_index)
            end
        end,
        self.config.EVENT_NAME.NOTIFY_UNWATER_GUIDE
    )
end
function FlowerItem:setOpenGuide(_index)
    local node_hua = self:findChild("node_hua")
    local node_btn = self:findChild("node_btn")
    local node_di = self:findChild("node_di")
    if _index == 1 then
       self.guide_data = {}
       self:setGuideDate(node_hua)
       self:setGuideDate(node_btn)
       local wordPos = node_hua:getParent():convertToWorldSpace(cc.p(node_hua:getPosition()))
       node_hua:setPosition(wordPos)
       local wordPos1 = node_btn:getParent():convertToWorldSpace(cc.p(node_btn:getPosition()))
       node_btn:setPosition(wordPos1)
       self:changeGuideNodeZorder(node_hua,ViewZorder.ZORDER_GUIDE + 3)
       self:changeGuideNodeZorder(node_btn,ViewZorder.ZORDER_GUIDE + 3)
    elseif _index == 2 then
        self:resetGuideNode()
        self.guide_data = {}
        node_hua:setScale(0.8)
        node_btn:setScale(0.65)
        self:setGuideDate(node_di)
        local wordPos = node_di:getParent():convertToWorldSpace(cc.p(node_di:getPosition()))
        node_di:setPosition(wordPos)
        self:changeGuideNodeZorder(node_di,ViewZorder.ZORDER_GUIDE + 3)
        node_di:setScale(1.2)
    end
end

function FlowerItem:setGuideDate(node)
     local item = {}
     item.node = node
     item.zorder = node:getZOrder()
     item.parent = node:getParent()
     item.pos = cc.p(node:getPosition())
     table.insert(self.guide_data, item)
end

function FlowerItem:changeGuideNodeZorder(node, zorder)
    local newZorder = zorder and zorder or ViewZorder.ZORDER_GUIDE + 1
    util_changeNodeParent(gLobalViewManager:getViewLayer(), node, newZorder)
    local currLayerScale = self:findChild("root"):getScale()
    node:setScale(currLayerScale)
end

function FlowerItem:resetGuideNode()
    if #self.guide_data > 0 then
        for i,v in ipairs(self.guide_data) do
            util_changeNodeParent(v.parent, v.node, v.zorder)
            v.node:setPosition(v.pos)
        end
    end
end

function FlowerItem:clickStartFunc(sender)
end

function FlowerItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_flow" then
        gLobalSoundManager:playSound(self.config.SOUND.CLICK)
        util_spinePlay(self.m_spine, "click", false)
        util_spineEndCallFunc(
            self.m_spine,
            "click",
            function()
                util_spinePlay(self.m_spine, "idle", true)
            end
        )
        gLobalNoticManager:postNotification(self.config.EVENT_NAME.ITEM_CLICK_GIFT,self._type)
    elseif name == "btn_now" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:postNotification(self.config.EVENT_NAME.ITEM_CLICK_WATER,self._type)
    end
end

return FlowerItem