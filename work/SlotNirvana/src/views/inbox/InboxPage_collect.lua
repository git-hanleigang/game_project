---
--island
--2018年7月10日
--Inbox.lua

local InboxPage_collectBase = util_require("views.inbox.InboxPage_collectBase")
local InboxPage_collect = class("InboxPage_collect", InboxPage_collectBase)
function InboxPage_collect:ctor()
    InboxPage_collect.super.ctor(self)
    -- self.m_alreadyList = {}     -- 已有邮件列表
    -- self.m_newlyNet    = {}     -- 新增邮件网络列表
    -- self.m_newlyLocal  = {}     -- 新增邮件本地列表
    -- self.m_localIndex  = 0 -- 当前本地邮件下标

    -- self.m_special     = {} -- 特殊类
    -- self.m_notice      = {} -- 通知类
    -- self.m_promotion   = {} -- 促销类
    -- self.m_award       = {} -- 奖励类
    self.m_itemList = {}
end

function InboxPage_collect:initUI(mainClass)
    InboxPage_collectBase.initUI(self, mainClass)
    self.m_list:setScrollBarEnabled(false)
end

function InboxPage_collect:getList()
    return self:findChild("list")
    -- return self:findChild("ScrollView_1")
end

function InboxPage_collect:getCsbName()
    return "InBox/FBCard/InboxPage_Collect.csb"
end

function InboxPage_collect:getAllMailData()
    local cData = G_GetMgr(G_REF.Inbox):getSysRunData()
    if cData then
        return cData:getShowMailDatas()
    end
    return
end

-- 创建item
function InboxPage_collect:createItemCell()
    -- self:removeTable()
    self:createCell()
    -- self:sortItem()
    -- self:showInboxItem()
end

function InboxPage_collect:createCell()
    self.m_itemList = {}
    self.m_itemHeightList = {}
    local mailAllData = self:getAllMailData()
    if mailAllData and #mailAllData > 0 then
        for i,v in ipairs(mailAllData) do
            if v:isGroup() then
                self:initGroupCell(v)
            else
                local mType = v:getType()
                local mNet = v:isNetMail()
                local info = InboxConfig.getNameMapConfig(mType, mNet)
                if info then
                    self:initCellItem(info, v, not mNet)
                end
            end
        end
    end
end

function InboxPage_collect:initGroupCell(_groupData)
    -- if not globalDynamicDLControl:checkDownloaded("Inbox_Collect") then
    --     return
    -- end
    local groupName = _groupData:getGroupName()
    local groupCfg = InboxConfig.getGroupCfgByName(groupName)
    if not groupCfg then
        print("warning !!!!")
        return
    end
    local gMailDatas = _groupData:getMailDatas()
    if not (gMailDatas and #gMailDatas > 0) then
        print("warning !!!! 脏数据了，分组中没有邮件了")
        return
    end

    local function removeCell(_target)
        if not tolua.isnull(self) then
            self:removeCell(_target)
        end
    end
    local function moveUnderItem(_groupName, _isMoveUnder, _changeH)
        if not tolua.isnull(self) then
            self:moveUnderItem(_groupName, _isMoveUnder, _changeH)
        end
    end
    local cell = util_createView("views.inbox.group." .. groupCfg.titleLua, _groupData, removeCell, moveUnderItem, groupCfg.unfold)
    local layout=ccui.Layout:create()
    local cellWidth = InboxConfig.CELL_WIDTH
    local cellHeight = groupCfg.height or 115
    layout:setContentSize(cc.size(cellWidth, cellHeight))
    layout:addChild(cell)
    -- cell:setPosition(6, -3)
    cell:setHeight(cellHeight)

    self.m_list:pushBackCustomItem(layout)
    print("initGroupCell layoutY",layout:getPositionY())

    -- self.m_list:addChild(layout)
    -- table.insert(self.m_itemHeightList, cellHeight)

    table.insert(self.m_itemList, {layout = layout, cell = cell, data = _groupData})
end

-- 初始化邮件
function InboxPage_collect:initCellItem(_mailInfo,_mailData,_isLocal)
    -- if _mailInfo.isDownLoad and not globalDynamicDLControl:checkDownloaded("Inbox_Collect") then
    --     return
    -- end
    -- -- 关联资源检测
    -- if not self:checkRelRes(_mailInfo.relRes) then
    --     return
    -- end

    local callFun = function (_target)
        if not tolua.isnull(self) then
            self:removeCell(_target)
        end
    end
    local cell = util_createView("views.inbox.item." .. _mailInfo.name, _mailData, callFun)
    local layout=ccui.Layout:create()
    local cellWidth = InboxConfig.CELL_WIDTH
    local cellHeight = _mailInfo.zOrder == 1 and 150 or 115
    layout:setContentSize(cc.size(cellWidth, cellHeight))
    layout:addChild(cell)
    -- cell:setPosition(6, -3)
    cell:setHeight(cellHeight)

    self.m_list:pushBackCustomItem(layout)
    print("initCellItem layoutY",layout:getPositionY())
    
    -- self.m_list:addChild(layout)
    -- table.insert(self.m_itemHeightList, cellHeight)

    table.insert(self.m_itemList, {layout = layout, cell = cell, data = _mailData})
end

function InboxPage_collect:removeItem(_mailId)
    if self.m_itemList and #self.m_itemList > 0 then
        for i = #self.m_itemList, 1, -1 do
            local cfg = self.m_itemList[i]
            if cfg.data and cfg.data.getId then
                if tonumber(cfg.data:getId()) == tonumber(_mailId) then
                    table.remove(self.m_itemList, i)
                    break
                end
            end
        end
    end
end

-- 停止进行中的位移动画
function InboxPage_collect:stopItemsMoveActon()
    for i = #(self.m_itemList or {}), 1, -1 do
        local cfg = self.m_itemList[i]
        if not tolua.isnull(cfg.layout) then
            if cfg.layout.mvActionId then
                cfg.layout:stopAction(cfg.layout.mvActionId)
                cfg.layout.mvActionId = nil
            end
        end
    end
end

-- 删除邮件,刷新并跳转到原来的位置
function InboxPage_collect:removeCell(_target)
    local targetMailData = _target.m_mailData
    local cellHeight = _target:getHeight()
    local index = self.m_list:getIndex(_target:getParent())
    local inerPos = self.m_list:getInnerContainerPosition() 

    self:removeItem(targetMailData:getId())
    
    self.m_list:removeItem(index)
    self:stopItemsMoveActon()
    
    local viewSize = self.m_list:getContentSize()
    local inerSize = self.m_list:getInnerContainerSize() 
    local minY1 = viewSize.height - inerSize.height 
    local deltaH = -1
    --根据公式 percent = 100 * (1 - innerpos.y/miny) 可推算出高度变化后的百分比(当列表拉到最底端时 percen = 100)
    local percent = 100 * (1.0 - ( inerPos.y - ( cellHeight * deltaH)) / (minY1 - (cellHeight * deltaH)))
    self.m_list:jumpToPercentVertical(percent)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
end

function InboxPage_collect:getGroupItemInfo(_groupName)
    local itemList = self.m_itemList
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local item = itemList[i]
            local mailData = item.data
            if mailData:isGroup() then
                if mailData:getGroupName() == _groupName then
                    return item
                end
            end
        end
    end
    return nil
end

-- function InboxPage_collect:removeTable()
--     -- self.m_alreadyList = {}
--     -- self.m_newlyLocal  = {}
--     -- self.m_newlyNet    = {}
--     -- self.m_special     = {} -- 特殊类
--     -- self.m_notice      = {} -- 通知类
--     -- self.m_promotion   = {} -- 促销类
--     -- self.m_award       = {} -- 奖励类
-- end

-- function InboxPage_collect:removeLocalMail()
--     for i = 1, self.m_localIndex do
--         self.m_list:removeItem(0)
--     end
--     self.m_localIndex = 0
-- end

function InboxPage_collect:canCollectAll()
    local mailAllData = self:getAllMailData()
    if #mailAllData == 0 then
        return false
    end
    return true
end

-- 领取所有邮件
function InboxPage_collect:requestCollectAllMail(success, fail)
    local mailAllData = self:getAllMailData()
    local ids = {}
    for i = 1, #mailAllData do
        ids[#ids + 1] = mailAllData[i].id
    end
    G_GetMgr(G_REF.Inbox):getSysNetwork():collectMail(
        ids,
        function()
            if not tolua.isnull(self) then
                self.m_isTouchOneItem = false
                if success then
                    success()
                end
            end
        end,
        function()
            if not tolua.isnull(self) then
                self.m_isTouchOneItem = false
                if fail then
                    fail()
                end
            end
        end
    )
end

-- 移动listItem
function InboxPage_collect:moveItem(_moveNode, _targetPosY, _moveEnd)
    local _actionList = {}
    -- _actionList[1] = cc.EaseBackOut:create(cc.MoveTo:create(InboxConfig.GroupFoldActionTime, cc.p(0, _targetPosY)))
    _actionList[1] = cc.MoveTo:create(InboxConfig.GroupFoldActionTime, cc.p(0, _targetPosY))
    _actionList[2] =
        cc.CallFunc:create(
        function()
            if _moveEnd then
                _moveEnd()
            end
        end
    )
    return _moveNode:runAction(cc.Sequence:create(_actionList))
end

function InboxPage_collect:getUnderItemInfo(_layoutPosY)
    local underItemInfos = {}
    local itemList = self.m_itemList
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local itemInfo = itemList[i]
            local itemPosY = itemInfo.layout:getPositionY()
            if itemPosY < _layoutPosY then
                table.insert(underItemInfos, itemInfo)
            end
        end
    end
    return underItemInfos
end

function InboxPage_collect:moveUnderItem(_groupName, _isMoveUnder, _changeH, _moveEndCall)
    print("moveUnderItem _groupName, _isMoveUnder", _groupName, tostring(_isMoveUnder))
    local curGroupItemInfo = self:getGroupItemInfo(_groupName)
    -- 分组中item的总高度
    -- local groupItemTotalH = self:getGroupItemTotalH(_groupName)
    -- item移动
    local moveDelta = 1
    if _isMoveUnder then
        moveDelta = -1
    end
    local moveDistance = moveDelta * _changeH
    -- print("moveUnderItem moveDistance", moveDistance)
    local curItemPosY = curGroupItemInfo.layout:getPositionY()
    local underItemInfos = self:getUnderItemInfo(curItemPosY)
    for i=1,#underItemInfos do
        local itemInfo = underItemInfos[i]
        local layout = itemInfo.layout
        if not layout:isVisible() then
            layout:setVisible(true)
        end
        local _actCall = function()
            if tolua.isnull(layout) then
                return
            end
            -- 停止进行中的位移动画
            local _actionId = layout.mvActionId
            if _actionId then
                layout:stopAction(_actionId)
                layout.mvActionId = nil
            end
        end
        _actCall()
        _actionId = self:moveItem(layout, layout:getPositionY() + moveDistance, _actCall)
        layout.mvActionId = _actionId
    end
    
    -- item移动结束后调整画布
    local sizeDelta = -1
    if _isMoveUnder then
        sizeDelta = 1
    end
    local sizeChangeH = sizeDelta * _changeH
    -- print("moveUnderItem sizeChangeH", sizeChangeH)
    performWithDelay(curGroupItemInfo.layout, 
        function()
            if not tolua.isnull(self) then
                -- 更改innersize
                local innerSize = self.m_list:getInnerContainerSize()
                local oldInnerH = innerSize.height
                local newInnerH = innerSize.height + sizeChangeH
                local contentS = self.m_list:getContentSize()
                local curItemH = curGroupItemInfo.layout:getContentSize().height
                local newLayoutH = curItemH + sizeChangeH
                local innerPos = self.m_list:getInnerContainerPosition()
                -- print("moveUnderItem _moveEndCall1", oldInnerH, newInnerH, contentS.height, newLayoutH)
                -- 更改layout size
                curGroupItemInfo.layout:setContentSize(cc.size(InboxConfig.CELL_WIDTH, newLayoutH))
                -- 更改cell位置
                local cellOldY = curGroupItemInfo.cell:getPositionY()
                -- print("moveUnderItem _moveEndCall2", cellOldY)
                curGroupItemInfo.cell:setPositionY(cellOldY + sizeChangeH)
                curGroupItemInfo.cell:setHeight(curGroupItemInfo.cell:getHeight() + sizeChangeH)
                -- innersize改变后需要保持list不动，计算出当前的偏移量
                local oldPercent = self:getScrolledPercentVertical()
                local oldMinY = contentS.height - oldInnerH
                if oldMinY == 0 then
                    oldMinY = 0
                end
                local dis = oldPercent * oldMinY
                local newPercent = 0
                local newMinY = contentS.height - newInnerH
                if newMinY == 0 then
                    newMinY = 0
                else
                    newPercent = dis/newMinY
                end
                -- print("moveUnderItem _moveEndCall2", oldPercent, dis, newPercent)
                -- 调整画布
                self.m_list:requestDoLayout()
                self.m_list:doLayout()
                -- print("moveUnderItem doLayout", self.m_list:getInnerContainerSize().height)
                self.m_list:jumpToPercentVertical(newPercent)
                if _moveEndCall then
                    _moveEndCall()
                end
            end
        end,
        InboxConfig.GroupFoldActionTime
    )
    -- 490-1070 = -580
    -- (1 - -482/(-580))*100
end

-- float ScrollView::getScrolledPercentVertical() const {
--     const float minY = getContentSize().height - getInnerContainerSize().height;
--     return (1.f - getInnerContainerPosition().y / minY)*100.f;
-- }
function InboxPage_collect:getScrolledPercentVertical()
    local minY = self.m_list:getContentSize().height - self.m_list:getInnerContainerSize().height
    if minY == 0 then
        return 0
    end
    return (1 - self.m_list:getInnerContainerPosition().y / minY) * 100
end


function InboxPage_collect:onEnter()
    InboxPage_collect.super.onEnter(self)    
end

return InboxPage_collect
