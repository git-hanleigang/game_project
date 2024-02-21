--邀请者
local Activity_Inviter = class("Activity_Inviter",BaseLayer)

function Activity_Inviter:ctor()
    Activity_Inviter.super.ctor(self)
    self:setLandscapeCsbName("Activity/Invitermain_MainLayer.csb")
    self:setExtendData("Activity_Inviter")
    self.m_data = G_GetMgr(G_REF.Invite):getData()
    self.MangeMr = G_GetMgr(G_REF.Invite)
    self.config = G_GetMgr(G_REF.Invite):getConfig()
end

function Activity_Inviter:initCsbNodes()
    self.node_qipao = self:findChild("Node_leftqi")
    self.node_qipao_r = self:findChild("Node_rightqi")
    self.person_bar = self:findChild("LoadingBar_g")
    self.pay_bar = self:findChild("LoadingBar_y")
    self.left_text = self:findChild("Text_lp")
    self.right_text = self:findChild("Text_level")
    self.left_item1 = self:findChild("Node_rewards1")
    self.left_item2 = self:findChild("Node_rewards2")
    self.right_item1 = self:findChild("Node_rewards3")
    self.right_item2 = self:findChild("Node_rewards4")
    self.btn_left = self:findChild("btn_left")
    self.btn_right = self:findChild("btn_right")
    self.left_gift = self:findChild("ef_lihe")
    self.right_gift = self:findChild("ef_lihe_0")
    self.btn_close = self:findChild("btn_close")
end

function Activity_Inviter:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    
    self:updataPerson()
    self:updataPay()
end

function Activity_Inviter:registerListener()

    gLobalNoticManager:addObserver(
        self,
        function()
            self.MangeMr:showUrgeLayer()
        end,
        self.config.EVENT_NAME.INVITER_GUIDE
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            self:checkRewards()
        end,
        self.config.EVENT_NAME.INVITEE_GUIDER_FINSH
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, _params)
            self:playBox(_params)
        end,
        self.config.EVENT_NAME.INVITER_REWARD_COLLECT
    )
end

function Activity_Inviter:resfhUI()
    local item_data = self.MangeMr:getData():getPayReceive()
    if item_data and #item_data > 0 then
        local shop_item = {}
        for i,v in ipairs(item_data) do
            table.insert(shop_item,v.shop[1])
        end
        self.MangeMr:sendInviterRew("3",nil,shop_item,item_data.zCoins)
    else
        self:updataPerson()
        self:updataPay()
    end
end
function Activity_Inviter:playBox(_params)
    self.btn_left:setVisible(false)
    self.btn_right:setVisible(false)
    local ani_name = "Lstart"
    local anima = "Lbudong"
    if _params.type == "3" then
        ani_name = "Rblank"
        anima = "Rbudong"
    end
    self:runCsbAction(ani_name,false,function()
        self:runCsbAction(anima,false)
        self.btn_left:setVisible(true)
        self.btn_right:setVisible(true)
        self.btn_close:setTouchEnabled(true)
        self:createReward(_params)
    end)
end
function Activity_Inviter:createReward(params)
    self.m_catFoodList = {}
    self.m_propsBagist = {}
    local call = function()
        if CardSysManager:needDropCards("Invite") == true then
            CardSysManager:doDropCards(
                "Invite",
                function()
                    self:triggerPropsBagView()
                    if params.type == "2" then
                        self:resfhUI()
                    elseif params.type == "3" then
                        self:updataPerson()
                        self:updataPay()
                    end
                    
                end
            )
        else
            self:triggerPropsBagView()
            if params.type == "2" then
                self:resfhUI()
            elseif params.type == "3" then
                self:updataPerson()
                self:updataPay()
            end
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
    end
    for i,v in ipairs(params.item) do
        if v.p_icon then
            if string.find(v.p_icon, "CatFood") then
                table.insert(self.m_catFoodList, v)
            end
            if string.find(v.p_icon, "Pouch") then
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                mergeManager:refreshBagsNum(v.p_icon, v.p_num)
                table.insert(self.m_propsBagist, v)
            end
        end
    end
    local rewardLayer = gLobalItemManager:createRewardLayer(params.item, call, params.coins, true)
    gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
end

function Activity_Inviter:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self.m_propsBagist, function()
    end)
end

function Activity_Inviter:updataPerson()
    local item_data = self.MangeMr:getData():getPersonReceive()
    local person_data = self.m_data:getInviterPerson()
    if item_data and #item_data > 0 then
        person_data = self.m_data:getLastCollect(self.m_data:getInviterReward().rewards)
    end
    local u_data = self.m_data:getInviterReward()
    
   
    self.left_text:setString(u_data.inviteNum.."/"..person_data.value)
    local error_text = self:findChild("Textl_error")
    if person_data.big then
        self.left_gift:setVisible(false)
        self.btn_left:setVisible(false)
        error_text:setVisible(true)
        --self.left_text:setString(u_data.inviteNum)
    else
        error_text:setVisible(false)
        self.left_gift:setVisible(true)
        self.btn_left:setVisible(true)
    end

    if item_data and #item_data > 0 then
        self.left_gift:setVisible(true)
        error_text:setVisible(false)
    end

    local percent = u_data.inviteNum*100/person_data.value
    self.person_bar:setPercent(percent)

    self.node_qipao:setVisible(false)
end

function Activity_Inviter:setQiPaoSize(bg,node_left,node_right,num)
    if num == 1 then
        bg:setContentSize(140,134)
    elseif num == 2 then
        bg:setContentSize(260,134)
    end
end

function Activity_Inviter:updataPay()
    local u_data = self.m_data:getInviterReward()
    local recharg_data = self.m_data:getInviterRecharg()
    local item_data1 = self.MangeMr:getData():getPayReceive()
    if item_data1 and #item_data1 > 0 then
        recharg_data = self.m_data:getLastCollect(self.m_data:getInviterReward().rechargerRewards)
    end
    self.right_text:setString(u_data.rechargeAmount.."/"..recharg_data.value)
    local error_text = self:findChild("Textr_error")
    if recharg_data.big then
        self.right_gift:setVisible(false)
        self.btn_right:setVisible(false)
        error_text:setVisible(true)
        --self.right_text:setString(u_data.rechargeAmount)
    else
        self.right_gift:setVisible(true)
        self.btn_right:setVisible(true)
        error_text:setVisible(false)
    end
    if item_data1 and #item_data1 > 0 then
        self.right_gift:setVisible(true)
        error_text:setVisible(false)
    end
    local percent = u_data.rechargeAmount*100/recharg_data.value
    self.pay_bar:setPercent(percent)
end

function Activity_Inviter:checkRewards()
    self.btn_close:setTouchEnabled(true)
    local item_data = self.MangeMr:getData():getPersonReceive()
    if #item_data > 0 then
        self.btn_close:setTouchEnabled(false)
        local shop_item = {}
        for i,v in ipairs(item_data) do
            table.insert(shop_item,v.shop[1])
        end
        self.MangeMr:sendInviterRew("2",nil,shop_item,item_data.zCoins)
    else
        local item_data1 = self.MangeMr:getData():getPayReceive()
        if item_data1 and #item_data1 > 0 then
            self.btn_close:setTouchEnabled(false)
            local shop_item = {}
            for i,v in ipairs(item_data1) do
                table.insert(shop_item,v.shop[1])
            end
            self.MangeMr:sendInviterRew("3",nil,shop_item,item_data1.zCoins)
        end
    end
end

function Activity_Inviter:addLeftQiPao()
    self.node_qipao:removeAllChildren()
    local item_data = self.m_data:getFreeItems()
    self.left_qipao = util_createView("views.Invite.Activity.InvitaQiPao")
    self.left_qipao:setPosition(0,0)    
    self.node_qipao:addChild(self.left_qipao)
    self.left_qipao:updataView(item_data,1)
end

function Activity_Inviter:addRightQiPao()
    self.node_qipao_r:removeAllChildren()
    local item_data = self.m_data:getPayItems()
    self.right_qipao = util_createView("views.Invite.Activity.InvitaQiPao")
    self.right_qipao:setPosition(0,0)    
    self.node_qipao_r:addChild(self.right_qipao)
    self.right_qipao:updataView(item_data,1)
end

function Activity_Inviter:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
    )
end

-- function Activity_Inviter:triggerDropMerge()
--     local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
--     mergeManager:popMergePropsBagRewardPanel(self.m_mergePropsBagList, handler(self, self.triggerDropFuncNext))
-- end

function Activity_Inviter:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_INVITEE_CLOSE)
        self:closeUI()
    elseif name == "btn_i" then
        local view = util_createView("views.Invite.Activity.InviterRules")
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    elseif name == "Btn_t" then
        --分享sm
        local btn_t = self:findChild("Btn_t")
        local size = btn_t:getContentSize()
        local pos = btn_t:convertToWorldSpace(cc.p(size.width/2,size.height/2))
        self.MangeMr:shareInvite(self.config.SHARE.SMS,pos)
    elseif name == "btn_left" then
        --左边气泡
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:addLeftQiPao()
        self.node_qipao:setVisible(true)
        self.left_qipao:playAnima()
    elseif name == "btn_right" then
        --右边气泡
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:addRightQiPao()
        self.node_qipao_r:setVisible(true)
        self.right_qipao:playAnima()
    end
end

function Activity_Inviter:onEnterFinish()
    Activity_Inviter.super.onEnterFinish(self)
    local guideStep = gLobalDataManager:getNumberByField(self.config.EVENT_NAME.INVITER_GUIDER, 1)
    if guideStep ~= 2 then
        local node1 = self:findChild("node_step1")
        local node2 = self:findChild("node_step2")
        local node3 = self:findChild("node_step3")
        local sm = display.width/CC_DESIGN_RESOLUTION.width
        local px = 0
        local py = 1
        if display.width > CC_DESIGN_RESOLUTION.width then
            px = 50
        elseif display.width < CC_DESIGN_RESOLUTION.width then
            py = display.width/CC_DESIGN_RESOLUTION.width
        end
        local node_list = {cc.p(node1:getPositionX()*py+px,node1:getPositionY()*py),cc.p(node2:getPositionX()*py-px,node2:getPositionY()*py),cc.p(node3:getPositionX()*py-px,node3:getPositionY()*(1/py))}
        self.MangeMr:showGuideLayer(1,node_list)
    else
        self:checkRewards()
    end
end

return Activity_Inviter