--[[
    
]]
local QuestPassRewardNode = class("QuestPassRewardNode", BaseView)

function QuestPassRewardNode:initDatas(_data, _type, _passLayer,lock)
    self.m_data = _type == "free" and _data.free or _data.pay
    self.m_type = _type
    self.m_curExp = _data.curExp
    self.m_passLayer = _passLayer
    self.m_payUnlocked = _data.payUnlocked
    self.m_lock = lock
end

function QuestPassRewardNode:getCsbName()
    if self.m_type == "free" then
        return QUEST_RES_PATH.QuestPassTableFreeCell
    else
        return QUEST_RES_PATH.QuestPassTableTicketCell
    end
end

function QuestPassRewardNode:initCsbNodes()
    self.m_node_reward = self:findChild("node_reward")
    self.m_lb_num = self:findChild("lb_num")
    self.m_node_qipao = self:findChild("node_qipao")
    self.m_node_dex = self:findChild("Node_dex")
    self.m_btn_touch = self:findChild("btn_touch")
    self.m_sp_lock = self:findChild("sp_lock")
    self.m_sp_normal = self:findChild("sp_normal")
    self.m_btn_touch:setSwallowTouches(false)
end

function QuestPassRewardNode:initUI()
    QuestPassRewardNode.super.initUI(self)

    self:initItem()
    if self.m_node_dex then
        self.m_node_dex:setVisible(self.m_data.p_labelColor and self.m_data.p_labelColor  == "1")
    end
    self:setStatus()
end

function QuestPassRewardNode:initItem()
    local type = 0
    local value = ""
    if self.m_data.p_items and #self.m_data.p_items > 0 then
        local shopItem = self.m_data.p_items[#self.m_data.p_items]
        if shopItem.p_icon  == "QuestMul" then
            type = 2
            value = "" .. (tonumber(shopItem.p_buffInfo.buffMultiple) * 100 - 100)  .."%"
        end
        self.m_itemData = gLobalItemManager:createLocalItemData(shopItem.p_icon, shopItem.p_num, shopItem)
        self.m_itemData:setTempData({p_mark = {0}})
        self.m_itemNode = gLobalItemManager:createRewardNode(self.m_itemData, ITEM_SIZE_TYPE.REWARD)
        self.m_node_reward:addChild(self.m_itemNode)
        self.m_lb_num:setString(shopItem.p_num)
        self.m_itemNode:setIconTouchEnabled(false)
        self.m_itemNode:setIconTouchSwallowed(false)
    elseif self.m_data.p_coins and self.m_data.p_coins > 0 then 
        self.m_itemData = gLobalItemManager:createLocalItemData("Coins", self.m_data.p_coins)
        self.m_itemData:setTempData({p_mark = {0}})
        self.m_itemNode = gLobalItemManager:createRewardNode(self.m_itemData, ITEM_SIZE_TYPE.REWARD)
        self.m_node_reward:addChild(self.m_itemNode)
        self.m_lb_num:setString(util_formatCoins(self.m_data.p_coins, 3))
        self.m_itemNode:setIconTouchEnabled(false)
        self.m_itemNode:setIconTouchSwallowed(false)
    else
        self.m_lb_num:setVisible(false)
    end

    if self.m_data.p_labelColor and (self.m_data.p_labelColor  ~= "0" and self.m_data.p_labelColor ~= "1") then
        type = 1
        value = "" .. (tonumber(self.m_data.p_labelColor) - 1)* 100  .."%"
    end
    if type > 0 then
        self.m_lb_num:setVisible(false)
        self.m_node_reward:removeAllChildren()
        local itemSpecialNode = util_createView(QUEST_CODE_PATH.QuestPassRewardSpecialItemNode, type,value)
        self.m_node_reward:addChild(itemSpecialNode)
    end
end

function QuestPassRewardNode:initBubble()
    self.m_bubble = util_createView(QUEST_CODE_PATH.QuestPassCellBubble, self.m_data)
    self.m_node_qipao:addChild(self.m_bubble)
end

function QuestPassRewardNode:setStatus()
    if self.m_lock then
        self:runCsbAction("idle", true)
        self.m_sp_normal:setVisible(false)
        self.m_sp_lock:setVisible(false)
        self.m_node_dex:setVisible(false)
        return
    end
    self.m_status = "uncompleted"
    if self.m_type == "free" then
        if self.m_data.p_collected then
            self:runCsbAction("idle_gou", true)
            self.m_status = "collected"
        elseif self.m_curExp >= self.m_data.p_exp then
            self:runCsbAction("idle_claim", true)
            self.m_status = "completed"
        else
            self:runCsbAction("idle", true)
            self.m_status = "uncompleted"
        end
    else
        if not self.m_payUnlocked then
            self:runCsbAction("idle_lock", true)
            self.m_status = "unlocked"
        elseif self.m_data.p_collected then
            self:runCsbAction("idle_gou", true)
            self.m_status = "collected"
        elseif self.m_curExp >= self.m_data.p_exp then
            self:runCsbAction("idle_claim", true)
            self.m_status = "completed"
        else
            self:runCsbAction("idle", true)
            self.m_status = "uncompleted"
        end
    end
end

function QuestPassRewardNode:clickFunc(_sender)
    if self.m_passLayer and self.m_passLayer:getTouch() then
        return 
    end
    
    local name = _sender:getName()
    if name == "btn_touch" then
        local name = _sender:getName()
        if self.m_lock then
            if name == "btn_touch" then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                -- 如果是锁定块 点击要跳转到 pass 页
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUESTPASS_SCROLLTOCURRENT_POS)
            end
        else
            if self.m_status == "uncompleted" or self.m_status == "unlocked" then
                gLobalNoticManager:postNotification(
                    ViewEventType.NOTIFY_QUESTPASS_SHOW_REWARD_INFO,
                    {
                        level = self.m_data.p_level,
                        boxType = self.m_type,
                        isPreview = self.m_isPreview
                    }
                )
            elseif self.m_status == "completed" then
                self.m_passLayer:setTouch(true)
                G_GetMgr(ACTIVITY_REF.Quest):sendPassCollect(self.m_data, self.m_type)
            end
        end
    end
end

function QuestPassRewardNode:updateView(_params)
    if _params and _params.success then
        local data = _params.data
        local type = _params.type
        if data.p_level == self.m_data.p_level and type == self.m_type then 
            self.m_status = "collected"
            self:runCsbAction("dagou", false, function ()
                self:runCsbAction("idle_gou", false)
            end, 60)
        elseif type == "all" and self.m_status == "completed" then
            self.m_status = "collected"
            self:runCsbAction("dagou", false, function ()
                self:runCsbAction("idle_gou", false)
            end, 60)
        end
    end
end

function QuestPassRewardNode:unlock(_params)
    if _params and _params.success then
        if self.m_type == "pay" and self.m_status == "unlocked" then
            self:runCsbAction("open", false, function ()
                self.m_payUnlocked = true
                if self.m_data.p_labelColor  ~= "0" and self.m_data.p_labelColor  ~= "1" then

                    local QuestData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
                    if QuestData then
                        local passData = QuestData:getPassData()
                        if passData then
                            local passInfo = passData:getPassInfoByIndex(self.m_data.p_level)
                            self.m_data = passInfo.pay
                        end
                    end
                    
                end
                self:setStatus()
            end, 60)
        end
    end
end

function QuestPassRewardNode:onEnter()
    QuestPassRewardNode.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self, self.updateView, ViewEventType.NOTIFY_QUEST_PASS_COLLECT)
    gLobalNoticManager:addObserver(self, self.unlock, ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK)
end

function QuestPassRewardNode:isCellByLevel(_level)
    if _level == self.m_data.p_level then 
        return true
    end
    return false
end

return QuestPassRewardNode