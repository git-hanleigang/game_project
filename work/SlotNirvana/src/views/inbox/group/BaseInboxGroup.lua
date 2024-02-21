--[[
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_base")
local BaseInboxGroup = class("BaseInboxGroup", InboxItem_base)

-- _isDefaultUnfoldItems -- 展开
function BaseInboxGroup:initDatas(_groupData, _removeMySelf, _changeMyHeightCall, _isDefaultUnfoldItems)
    BaseInboxGroup.super.initDatas(self, _groupData, _removeMySelf)

    self.m_changeMyHeightCall = _changeMyHeightCall
    self.m_isUnfold = _isDefaultUnfoldItems == true

    local groupName = self.m_mailData:getGroupName()
    self.m_groupCfg = InboxConfig.getGroupCfgByName(groupName)

    -- 如果有实现方式不同的，请重新命名此路径
    self.m_itemsLuaPath = "views.inbox.group.BaseInboxGroupItems"

    -- 正在做收放动作
    self.m_isFolding = false
end

function BaseInboxGroup:initCsbNodes()
    self.m_nodeGroupItems = self:findChild("node_groupItems")

    self.m_spBtnMore = self:findChild("sp_btn_more")
    self.m_spBtnLess = self:findChild("sp_btn_less")

    self.m_nodeRedPoint = self:findChild("node_redPoint")

    self.m_btnSelect = self:findChild("btn_select")
    if self.m_btnSelect then
        self.m_btnSelect:setSwallowTouches(false)
    end
end

function BaseInboxGroup:initView()
    -- 创建邮件
    self:initItems()
    self:initRedPoint()
    self:updateBtnTxt()
end

function BaseInboxGroup:initRedPoint()
    self.m_redPoint = util_createView("views.inbox.InboxPage_redPoint")
    self.m_nodeRedPoint:addChild(self.m_redPoint)
    self:updateRedPoint(self:getItemCount())
end

function BaseInboxGroup:updateRedPoint(_num)
    if _num and _num > 0 then
        self.m_redPoint:setVisible(true)
        self.m_redPoint:updateNum(_num)
    else
        self.m_redPoint:setVisible(false)
    end 
end

function BaseInboxGroup:updateBtnTxt()
    self.m_spBtnMore:setVisible(self.m_isUnfold == false)
    self.m_spBtnLess:setVisible(self.m_isUnfold == true)
end

function BaseInboxGroup:initItems()
    local function removeItem(_removeH, _isEmpty)
        if not tolua.isnull(self) then
            self:removeItem(_removeH, _isEmpty)
        end
    end
    self.m_item = util_createView(self.m_itemsLuaPath, self.m_mailData:getMailDatas(), self.m_groupCfg.height, self.m_isUnfold == true, removeItem)
    self.m_nodeGroupItems:addChild(self.m_item)
end


function BaseInboxGroup:removeItem(_removeH, _isEmpty)
    if _isEmpty then
        if self.m_removeMySelf then
            self.m_removeMySelf(self)
        end
    else
        if self.m_isUnfold == true then
            self:setHeight(self:getHeight() - _removeH)
            if self.m_changeMyHeightCall then
                self.m_changeMyHeightCall(self.m_mailData:getGroupName(), self.m_isUnfold == false, _removeH)
            end
        end
        self:updateRedPoint(self:getItemCount())
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())        
    end
end


function BaseInboxGroup:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_select" then
        if self.m_isFolding == true then
            return
        end
        self.m_isFolding = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 当前收起的，点击时要打开分组，下面的邮件需要下移分组的高度
        -- 当前打开的，点击时要收起分组，下面的邮件需要上移分组的高度
        local changeH = self:getChangeHeight()
        if self.m_changeMyHeightCall then
            self.m_changeMyHeightCall(self.m_mailData:getGroupName(), self.m_isUnfold == false, changeH)
        end
        self.m_item:openItems(not self.m_isUnfold, function()
            if not tolua.isnull(self) then
                self.m_isFolding = false
                self.m_isUnfold = not self.m_isUnfold
                self:updateBtnTxt()

                if self.m_isUnfold == true then
                    self:setHeight(self.m_groupCfg.height + changeH)
                else
                    self:setHeight(self.m_groupCfg.height)
                end
            end
        end)
    end
end

function BaseInboxGroup:getItemCount()
    local items = self.m_mailData:getMailDatas()
    if items and #items > 0 then
        return #items
    end
    return 0
end

function BaseInboxGroup:getItemListTotalH()
    local count = self:getItemCount()
    if count > 0 then
        local totalH = count*self.m_groupCfg.height + (count-1)*InboxConfig.GroupItemIntervalH
        return totalH
    end
    return 0
end

-- 变化总高度 = items的高度 + 底部的厚度
function BaseInboxGroup:getChangeHeight()
    local totalH = self:getItemListTotalH()
    return totalH + InboxConfig.GroupMaskEdageH + InboxConfig.GroupBottomEdageH
end

return BaseInboxGroup