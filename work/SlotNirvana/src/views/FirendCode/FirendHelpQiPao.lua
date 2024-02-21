--弹出气泡
local FirendHelpQiPao = class("FirendHelpQiPao", BaseView)
function FirendHelpQiPao:initUI()
    local path = "Friends/csd/Activity_FriendsHelp_qipao.csb"
    self:createCsbNode(path)
    self:initView()
end

function FirendHelpQiPao:initCsbNodes()
end

function FirendHelpQiPao:initView()
    self.status = true
    self:runCsbAction("idle",true)
end

function FirendHelpQiPao:updataUI(_data,_index,_callback)
    self.data = _data
    self.m_callback = _callback
end

function FirendHelpQiPao:showAction()
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
                            if self.m_callback then
                                self.m_callback()
                            end
                            self.m_mask:removeFromParent()
                            self:removeFromParent()
                        end)
                    end,
                    3
                )
            end
        )
    end 
    self:addMask()
end

function FirendHelpQiPao:addMask()
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch(
        function(event)
            if not isTouch then
                return true
            end
            if event.name == "ended" then
                if not tolua.isnull(self) then
                    self.m_mask:removeFromParent()
                    if self.m_callback then
                        self.m_callback()
                    end
                    self:removeFromParent()
                end
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
    self.m_mask = mask
    gLobalViewManager:showUI(self.m_mask, ViewZorder.ZORDER_UI)
end

function FirendHelpQiPao:showEnd()
    self:runCsbAction("over",false,function()
        if self.m_callback then
            self.m_callback()
        end
        self:removeFromParent()
    end)
end

function FirendHelpQiPao:getStatus()
    return self.status
end

return FirendHelpQiPao