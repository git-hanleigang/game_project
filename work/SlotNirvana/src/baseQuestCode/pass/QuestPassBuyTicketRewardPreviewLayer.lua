
local BaseLayer = util_require("base.BaseLayer")
local QuestPassBuyTicketRewardPreviewLayer = class("QuestPassBuyTicketRewardPreviewLayer", BaseLayer)

function QuestPassBuyTicketRewardPreviewLayer:initDatas()
    QuestPassBuyTicketRewardPreviewLayer.super.initDatas(self)
    self:setPauseSlotsEnabled(true)
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self:setExtendData("QuestPassRewardPreviewLayer")
end

function QuestPassBuyTicketRewardPreviewLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_rewards")
end

function QuestPassBuyTicketRewardPreviewLayer:getCsbName()
    return QUEST_RES_PATH.QuestPassBuyTicketRewardPreviewLayer
end

-- 重写父类方法
function QuestPassBuyTicketRewardPreviewLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestPassBuyTicketRewardPreviewLayer:initView()
    local passData = self.m_gameData:getPassData()
    local price = passData:getPrice()
    self:setButtonLabelContent("btn_buy", "          $" .. price, nil, true) 

    -- 初始化奖励列表
    self:initRewardList(passData)
    
    self:updateBtnBuck()
end

function QuestPassBuyTicketRewardPreviewLayer:updateBtnBuck()
    local buyType = BUY_TYPE.QUEST_PASS
    self:setBtnBuckVisible(self:findChild("btn_buy"), buyType, nil, {
        {node = self:findChild("btn_buy"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 20},
        {node = self:findChild("sp_ticket"), addX = 20}
    })
end

function QuestPassBuyTicketRewardPreviewLayer:initRewardList(passData)
    local popDisPlayList = passData:getDisplayRewardPoints()
    local itemList = {}
    for i = 1 ,#popDisPlayList do
        local payInfo = popDisPlayList[i]
        local payCell = util_createView(QUEST_CODE_PATH.QuestPassRewardNode,{pay = payInfo} , "pay",nil)
        itemList[#itemList+1] = gLobalItemManager:createOtherItemData(payCell,1)
    end
    -- --创建通用道具布局
    local size = cc.size(700,280)
    local maxConut = 5
    local scale = 1
    local listView = gLobalItemManager:createRewardListView(itemList,size,maxConut,{width = 150,height = 150},scale)
    self.m_nodeReward:addChild(listView)
end

function QuestPassBuyTicketRewardPreviewLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_benefit" then
        if self.m_gameData and self.m_gameData:getPassData() then
            local passData = self.m_gameData:getPassData()
            local price = passData:getPrice()
            G_GetMgr(G_REF.PBInfo):showPBInfoLayer({p_price = price}, nil, nil, true)
        end
    elseif name == "btn_buy" then
        if self.m_gameData and self.m_gameData:getPassData() then
            local passData = self.m_gameData:getPassData()
            _sender:setTouchEnabled(false)
            gLobalSendDataManager:getLogIap():setEntryType("questLobby")
            G_GetMgr(ACTIVITY_REF.Quest):buyPassUnlock(passData)
        end
    end
end

function QuestPassBuyTicketRewardPreviewLayer:registerListener()
    QuestPassBuyTicketRewardPreviewLayer.super.registerListener(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            gLobalSendDataManager:getLogIap():setLastEntryType()
            if params and params.success then
                self:closeUI()
            else
                self:findChild("btn_buy"):setTouchEnabled(true)                
            end
        end,
        ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK
    )
end

return QuestPassBuyTicketRewardPreviewLayer
