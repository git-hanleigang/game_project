--[[
    GroupBg
]]
local BaseInboxGroupItems = class("BaseInboxGroupItems", BaseView)

function BaseInboxGroupItems:initDatas(_itemDatas, _itemCellH, _isOpenItems, _removeItemCall)
    self.m_itemDatas = _itemDatas
    self.m_itemCellH = _itemCellH
    self.m_isOpenItems = _isOpenItems
    self.m_removeItemCall = _removeItemCall

    self.m_imgFrontY = 33 -- 初始化的位置 这俩的高度必须保持一致

    self.m_itemIntervalH = InboxConfig.GroupItemIntervalH

    self.m_items = {}
end

function BaseInboxGroupItems:getCsbName()
    return "InBox/Group/GroupItems.csb"
end

function BaseInboxGroupItems:initCsbNodes()
    self.m_pClipBg = self:findChild("Panel_bg")
    self.m_ImgBack = self:findChild("img_back")
    self.m_pItemList = self:findChild("Panel_itemList")
    self.m_ImgFront = self:findChild("img_front")

    self.m_pClipMoveBgW = self.m_pClipBg:getContentSize().width
end

function BaseInboxGroupItems:initUI()
    BaseInboxGroupItems.super.initUI(self)
    self:initBg()
    self:initItems()    
end

function BaseInboxGroupItems:initBg()
    -- items的高度
    local itemTotalH = self:getItemListTotalH()
    -- 背景高度
    local bgH = self:getBgHeight()
    print("bgH =", bgH)

    self:updateClipBgHeight(self.m_isOpenItems == true and bgH or 0)

    self.m_ImgBack:setContentSize(cc.size(self.m_ImgBack:getContentSize().width, bgH))
    self.m_ImgFront:setContentSize(cc.size(self.m_ImgFront:getContentSize().width, bgH))
    self.m_pItemList:setContentSize(cc.size(self.m_pItemList:getContentSize().width, itemTotalH))
end

function BaseInboxGroupItems:updateClipBgHeight(_height)
    self.m_pClipBg:setContentSize(cc.size(self.m_pClipMoveBgW, _height))
end

-- 创建item
function BaseInboxGroupItems:initItems()
    local totalH = self:getItemListTotalH()
    local mDatas = self.m_itemDatas
    if mDatas and #mDatas > 0 then
        for i,v in ipairs(mDatas) do
            local info = InboxConfig.getNameMapConfig(v:getType(), v:isNetMail())
            if info then
                local y = totalH - (i-1)*(self.m_itemCellH + InboxConfig.GroupItemIntervalH)
                print("initItems y = ", y)
                self:initCellItem(i, info, v, y)
            end
        end
    end
end

-- 初始化邮件
function BaseInboxGroupItems:initCellItem(_index, _mailInfo, _mailData, _posY)
    local removeCell = function (_target)
        if not tolua.isnull(self) then
            self:removeCell(_target)
        end
    end
    local cell = util_createView("views.inbox.item.".._mailInfo.name, _mailData, removeCell)
    local cellWidth = InboxConfig.GROUP_CELL_WIDTH
    local cellHeight = self.m_itemCellH
    local layout=ccui.Layout:create()
    layout:setTouchEnabled(false)
    layout:setSwallowTouches(false)
    layout:setContentSize({width = cellWidth, height = cellHeight})
    layout:setAnchorPoint(cc.p(0.5, 1))
    layout:addChild(cell)
    -- cell:setPosition(6, -3)
    cell:setHeight(cellHeight)

    layout:setPosition(cc.p(cellWidth*0.5, _posY or 0))

    self.m_pItemList:addChild(layout)
    table.insert(self.m_items, {layout = layout, cell = cell, mailId = _mailData:getId()})
end

function BaseInboxGroupItems:removeCell(_target)
    local targetMailData = _target.m_mailData
    if not targetMailData then
        return
    end
    local targetMailId = targetMailData:getId()
    if not targetMailId then
        return
    end
    -- 删除对象
    local removePosY = nil
    local items = self.m_items
    if items and #items > 0 then
        for i = #items, 1, -1 do
            local mailId = items[i].mailId
            local layout = items[i].layout
            if tonumber(mailId) == tonumber(targetMailId) then
                removePosY = layout:getPositionY()
                table.remove(items, i)
                if tolua.isnull(layout) then
                    layout:removeFromParent()
                end
                break
            end
        end
    end
    -- 删除数据
    local itemDatas = self.m_itemDatas
    if itemDatas and #itemDatas > 0 then
        for i = #itemDatas, 1, -1 do
            if tonumber(itemDatas[i]:getId()) == tonumber(targetMailId) then
                table.remove(itemDatas, i)
                break
            end
        end
    end
    -- 下移位置高的cell的位置
    local h = self:getBgHeight()
    local finalH = 0
    local removeH = 0
    if #items == 0 then
        finalH = 0
        removeH = h
    else
        finalH = h
        removeH = self.m_itemCellH + InboxConfig.GroupItemIntervalH
        if removePosY ~= nil then
            for i=1,#items do
                local layout = items[i].layout
                local posY = layout:getPositionY()
                if posY > removePosY then
                    local oldY = layout:getPositionY()
                    layout:setPositionY(oldY - self.m_itemCellH)
                end
            end
        end
    end
    if self.m_isOpenItems == true then
        self:updateClipBgHeight(finalH)
    end
    if self.m_removeItemCall then
        self.m_removeItemCall(removeH, finalH == 0)
    end
end

function BaseInboxGroupItems:openItems(_isOpenItems, _openEndCall)
    if _isOpenItems == self.m_isOpenItems then
        return
    end
    local h = self:getBgHeight()
    local curH = self.m_isOpenItems == true and h or 0
    local tarH = self.m_isOpenItems == true and 0 or h
    self:changeHeight(curH, tarH, function()
        if not tolua.isnull(self) then
            self.m_isOpenItems = not self.m_isOpenItems
            if _openEndCall then
                _openEndCall()
            end
        end
    end)
end

function BaseInboxGroupItems:changeHeight(_curH, _tarH, _changeEndCall)
    local function changeOver()
        self:onUpdate(function() end)
        if _changeEndCall then
            _changeEndCall()
        end        
    end
    
    local curH = _curH
    local tarH = _tarH
    local secFrame = 60
    local totalSec = InboxConfig.GroupFoldActionTime
    local frameCount = totalSec*secFrame
    local frameH = (tarH - curH)/frameCount
    self:onUpdate(
        function()
            curH = curH + frameH
            if frameH > 0 then
                if curH >= tarH then
                    changeOver(tarH)
                    self:updateClipBgHeight(tarH)
                else
                    self:updateClipBgHeight(curH)
                end
            else
                if curH <= tarH then
                    self:updateClipBgHeight(tarH)
                    changeOver(tarH)
                else
                    self:updateClipBgHeight(curH)
                end
            end
        end
    )
end

function BaseInboxGroupItems:onEnter()
    BaseInboxGroupItems.super.onEnter(self)
end

function BaseInboxGroupItems:getItemCount()
    local items = self.m_itemDatas
    if items and #items > 0 then
        return #items
    end
    return 0
end

function BaseInboxGroupItems:getItemListTotalH()
    local count = self:getItemCount()
    if count > 0 then
        local totalH = count*self.m_itemCellH + (count-1)*InboxConfig.GroupItemIntervalH
        return totalH
    end
    return 0
end

-- 背景的总高度 = 高出的长度 + items的高度 + 底部的厚度
function BaseInboxGroupItems:getBgHeight()
    local totalH = self:getItemListTotalH()
    return self.m_imgFrontY + totalH + InboxConfig.GroupMaskEdageH
end


-- function BaseInboxGroupItems:getItemPosY(_index, _isUnfold)
--     local totalH = self:getItemListTotalH()
--     if not _isUnfold then
--         totalH = 3*totalH
--     end
--     local y = totalH - (_index-1)*(self.m_itemCellH + InboxConfig.GroupItemIntervalH)
--     return y
-- end


return BaseInboxGroupItems