local BaseTable = util_require("base.BaseTable")
local FrameTableView = class("FrameTableView", BaseTable)

function FrameTableView:ctor(param)
    FrameTableView.super.ctor(self, param)
end

function FrameTableView:reload( _items,_type )
    _items = _items or {}
    self.cul_num = 5
    self.curr_index = 0
    self.item_height = 145
    self.curr_index = G_GetMgr(G_REF.UserInfo):getGameHoldFrameItem()
    local splitItemsList = self:getItemList(_items,_type)
    self.item_list = splitItemsList
    FrameTableView.super.reload( self, splitItemsList )
end

function FrameTableView:getItemList(_items)
    local splitItemsList = {}
    local x = 1
    if self.curr_index ~= 0 then
        local item_list = G_GetMgr(G_REF.UserInfo):getCfHoldList()
        for idx, itemInfo in ipairs(item_list) do
            local newIdx = math.floor((idx-1) / self.cul_num) + 1
            if not splitItemsList[newIdx] then
                splitItemsList[newIdx] = {}
            end
            table.insert(splitItemsList[newIdx], itemInfo)
        end
        local slot_list = G_GetMgr(G_REF.UserInfo):getCfHoldSoltList()
        for idx, itemInfo in ipairs(slot_list) do
            local newIdx = math.floor((idx-1) / self.cul_num) + 1 + self.curr_index
            if not splitItemsList[newIdx] then
                splitItemsList[newIdx] = {}
            end
            table.insert(splitItemsList[newIdx], itemInfo)
        end
    else
        local slot_list = G_GetMgr(G_REF.UserInfo):getCfHoldSoltList()
        for idx, itemInfo in ipairs(slot_list) do
            local newIdx = math.floor((idx-1) / self.cul_num) + 1
            if not splitItemsList[newIdx] then
                splitItemsList[newIdx] = {}
            end
            table.insert(splitItemsList[newIdx], itemInfo)
        end
    end
    return splitItemsList
end

function FrameTableView:cellSizeForTable(table, idx)
    if idx == 0 then
        return 570, 200
    elseif idx == self.curr_index then
        return 570, 200
    end
    return 570, 135
end

function FrameTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
        cell.view = nil
    end

    if cell.view == nil then
        cell.view = cc.Layer:create()
        cell.view:setContentSize(570,150)
        if self.item_list[idx+1] ~= nil then
            for i,v in ipairs(self.item_list[idx+1]) do
                local node = self:createNode(i)
                node:setTag(i)
                node:updataCell(v,idx,i)
                cell.view:addChild(node)
            end
        end
        cell:addChild(cell.view)
        cell.view:setName("avtCell")
        self._cellList[idx + 1] = cell.view
    else
        -- local view = cell:getChildByName("avtCell")
        -- local shuju = self.item_list[idx+1]
        -- for i=1,4 do
        --     local node = view:getChildByTag(i)
        --     local sj = shuju[i]
        --     if node then
        --         if sj then
        --             node:updataCell(sj,idx,i)
        --             node:setVisible(true)
        --         else
        --             node:setVisible(false)
        --         end
        --     end
        --     if sj and not node then
        --         local node1 = self:createNode(i)
        --         node1:setTag(i)
        --         node1:updataCell(sj,idx,i)
        --         view:addChild(node1)
        --     end
        -- end
    end
    return cell
end

function FrameTableView:tableCellTouched(table, cell)
     print("点击了cell：" .. cell:getIdx())
end


-- function UserInfoHeadTableView:_onTouchBegan( event )
--     local touchPoint = cc.p( event.x,event.y )
--     self._pointTouchBegin = touchPoint

--     return UserInfoHeadTableView.super._onTouchBegan( self,event )
-- end

-- function UserInfoHeadTableView:_onTouchEnded( event )
--     local touchPoint = cc.p( event.x,event.y )
--     local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)

--     if distance > 20 then
--         return
--     end
--     for i,node in pairs( self._cellList ) do
--         if tolua.isnull(node) then
--             return
--         end
--         local isTouchPosPanel = self:onTouchCellChildNode( node, touchPoint )
--         if isTouchPosPanel then
--             for i,v in ipairs(node:getChildren()) do
--                 if not v.findChild then
--                     return
--                 end
--                 local sp_bg = v:findChild("sp_bg")
--                 local isTouch = self:onTouchCellChildNode( sp_bg, touchPoint )
--                 if isTouch then
--                     gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
--                     v:clickCell()
--                 end
--             end
--             return
--         end
--     end

-- end

function FrameTableView:createNode(index)
    local node = util_createView("views.UserInfo.view.UserPerson.FrameDisyCell")
    node:setContentSize(145,145)
    local pos_x = 60+135*(index-1)
    node:setPosition(pos_x,75)
    return node
end

function FrameTableView:_addScrollNoticeNode()
    if not self._showScroll then
        return
    end
    -- 创建背景 进度条
    self:createScrollBgAndIcon()
    self:addTouchForScrollIcon()
    -- 滚动条初始位置距离tableview的距离 ( 对于竖直位置来说 距离tableview的右上点差10px 对于水平来说 距离左下点差10px)
    local padding = 10
    if self._paddingScroll then
        padding = self._paddingScroll
    end

    if self._tableDirection == 2 then

        -- 对于竖直位置的初始化
        self._scrollIcon:setAnchorPoint(cc.p(1, 1))
        self._maxHeight = self._tableSize.height -- 滚动的背景底(或者区域)的高度
        self._topPoint = cc.p(self._tableSize.width + padding-7, self._tableSize.height-15) -- 滚动条能到的最高点
        self._scrollIcon:setPosition(self._topPoint)
        self._bottomPoint = cc.p(self._tableSize.width + padding, 0) -- 滚动条的右下点
        self._scrollIconOrgSize = self._scrollIcon:getContentSize()
        -- 设置scroll背景底部条
        self._scrollBg:setAnchorPoint(cc.p(1, 1))
        self._scrollBg:setPosition(cc.p(self._tableSize.width + padding, self._tableSize.height))
        self._scrollBg:setContentSize(cc.size(self._scrollBgSize.width, self._maxHeight))
        self._scrollBg:setScaleY(0.9)
    else
        -- 对于水平位置的初始化
        self._scrollIcon:setAnchorPoint(cc.p(0, 0))
        self._maxWidth = self._tableSize.width - padding * 2 -- 滚动条能设置的最大宽度
        self._leftPoint = cc.p(0 + padding, 0 - padding) -- 滚动条左边的位置
        self._scrollIcon:setPosition(self._leftPoint)
        -- self._scrollIcon:setScaleY( 0.25 )  -- 针对这个图片需要设置一下 后面换图片了 需要改
        self._rightPoint = cc.p(self._tableSize.width - padding, 0 - padding)
    end
    self._scrollIcon:setVisible(false)
end

function FrameTableView:createScrollBgAndIcon()
    if self._scrollIcon == nil then
        self._scrollIcon = ccui.ImageView:create("Activity/img/Information_FramePartII/FramePartII_progress_bg.png")
        --self._scrollIcon:setScale9Enabled(true)
        --self._scrollIcon:setCapInsets(cc.rect(7, 7, 30, 30))
        --self._scrollIcon:ignoreContentAdaptWithSize(true)
        self:addChild(self._scrollIcon, 1999)
        self._scrollIconSize = self._scrollIcon:getContentSize()
    end
    if self._scrollBg == nil then
        self._scrollBg = ccui.ImageView:create("Activity/img/Information_FramePartII/FramePartII_progress.png")
        --self._scrollBg:setScale9Enabled(true)
        --self._scrollBg:setCapInsets(cc.rect(8, 8, 153, 153))
        --self._scrollBg:ignoreContentAdaptWithSize(true)
        self:addChild(self._scrollBg, 1998)
        self._scrollBgSize = self._scrollIcon:getContentSize()
    end
end

return FrameTableView 