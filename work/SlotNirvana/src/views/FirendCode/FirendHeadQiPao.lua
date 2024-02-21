--弹出气泡
local FirendHeadQiPao = class("FirendHeadQiPao", BaseView)
function FirendHeadQiPao:initUI()
    local path = "Friends/csd/Activity_FriendsMain_qipao.csb"
    self:createCsbNode(path)
    self:initView()
end

function FirendHeadQiPao:initCsbNodes()
    self.left_node = self:findChild("ef_maodian1")
    self.right_node = self:findChild("ef_maodian")
    self.node_mask = self:findChild("node_mask")
end

function FirendHeadQiPao:initView()
    self.status = true
    self:runCsbAction("idle",true)
end

function FirendHeadQiPao:updataUI(_data,_index,_callback)
    self.data = _data
    self.m_callback = _callback
    if _index == 5 then
        self.left_node:setVisible(true)
        self.right_node:setVisible(false)
    else
        self.left_node:setVisible(false)
        self.right_node:setVisible(true)
    end
end

function FirendHeadQiPao:showAction()
    self:stopAllActions()
    if self.status then
        self.status = false
        self:runCsbAction(
            "start",
            false,
            function()
                performWithDelay(
                    self,
                    function()
                        self:runCsbAction("over",false,function()
                            self.status = true
                            self:closeUI()
                        end)
                    end,
                    3
                )
            end
        )
    end 
    self:addMask()
end

function FirendHeadQiPao:addMask()
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                --self.m_mask:removeFromParent()
               self:closeUI()
                
                --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_REMOVE_REWARD_INFO,false)
            end

            return true
        end,
        false,
        true
    )

    performWithDelay(
        self,
        function()
            isTouch = true
        end,
        0.5
    )
    self.node_mask:addChild(mask)
    -- self.m_mask = mask
    -- gLobalViewManager:showUI(self.m_mask, ViewZorder.ZORDER_UI)
end

function FirendHeadQiPao:showEnd()
    self:runCsbAction("over",false,function()
        if self.m_callback then
            self.m_callback()
        end
        self:removeFromParent()
    end)
end

function FirendHeadQiPao:getStatus()
    return self.status
end

function FirendHeadQiPao:closeUI()
    if self.m_callback then
        self.m_callback()
    end
    self:removeFromParent()
end

function FirendHeadQiPao:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_profile" or name == "btn_profile1" then
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.p_udid, "","",self.data.p_facebookHead)
        self:closeUI()
    elseif name == "btn_unfriend" or name == "btn_unfriend1" then
        --删除好友
        G_GetMgr(G_REF.Friend):setDeleteuid(self.data.p_udid)
        local view = util_createView("views.FirendCode.FirendDialogLayer",function()
            local id = G_GetMgr(G_REF.Friend):getDeleteuid()
            if not id then
                return
            end
            G_GetMgr(G_REF.Friend):requestAddFriend(FriendConfig.QuestType.Delete,id)
            G_GetMgr(G_REF.Friend):setDeleteuid()
        end, nil, nil, {{buttomName = "btn_ok", labelString = "YES"}})
        view:updateContentTipUI("lb_name",self.data.p_name)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

return FirendHeadQiPao