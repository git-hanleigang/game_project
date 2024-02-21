local BaseTable = util_require("base.BaseTable")
local UserInfoHeadTableView = class("UserInfoTableView", BaseTable)

function UserInfoHeadTableView:ctor(param)
    UserInfoHeadTableView.super.ctor(self, param)
end

function UserInfoHeadTableView:reload( _items,_type )
    _items = _items or {}
    self.cul_num = 4
    if _type == 4 then
        self.cul_num = 3
    end
    self.type = _type
    self.curr_index = 0
    self.item_height = 145
    if _type == 3 then
        self.item_height = 175
    elseif _type == 4 then
        self.item_height = 240
    elseif _type == 2 then
        self.curr_index = G_GetMgr(G_REF.UserInfo):getGameFrameItem()
    end
    local splitItemsList = self:getItemList(_items,_type)
    self.item_list = splitItemsList
    
    UserInfoHeadTableView.super.reload( self, splitItemsList )
end

function UserInfoHeadTableView:getItemList(_items,_type)
    local splitItemsList = {}
    local x = 1
    if _type == 2 and self.curr_index ~= 0 then
        local item_list = G_GetMgr(G_REF.UserInfo):getCfItemList()
        for idx, itemInfo in ipairs(item_list) do
            local newIdx = math.floor((idx-1) / self.cul_num) + 1
            if not splitItemsList[newIdx] then
                splitItemsList[newIdx] = {}
            end
            table.insert(splitItemsList[newIdx], itemInfo)
        end
        local slot_list = G_GetMgr(G_REF.UserInfo):getCfSoltList()
        for idx, itemInfo in ipairs(slot_list) do
            local newIdx = math.floor((idx-1) / self.cul_num) + 1 + self.curr_index
            if not splitItemsList[newIdx] then
                splitItemsList[newIdx] = {}
            end
            table.insert(splitItemsList[newIdx], itemInfo)
        end
    else
        for idx, itemInfo in ipairs(_items) do
            local newIdx = math.floor((idx-1) / self.cul_num) + 1
            if not splitItemsList[newIdx] then
                splitItemsList[newIdx] = {}
            end
            table.insert(splitItemsList[newIdx], itemInfo)
        end
    end
    return splitItemsList
end

function UserInfoHeadTableView:cellSizeForTable(table, idx)
    if self.curr_index ~= 0 then
        if idx == 0 then
            return 570, 200
        elseif idx == self.curr_index then
            return 570, 200
        end
    end
    return 570, self.item_height
end

function UserInfoHeadTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
        cell.view = nil
    end

    if cell.view == nil then
        cell.view = cc.Layer:create()
        cell.view:setContentSize(570,self.item_height)
        for i,v in ipairs(self.item_list[idx+1]) do
            local node = self:createNode(i, v)
            node:setTag(i)
            node:updataCell(v,idx,i)
            cell.view:addChild(node)
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

function UserInfoHeadTableView:tableCellTouched(table, cell)
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

function UserInfoHeadTableView:createNode(index, cellData)
    local node = nil
    if self.type == 1 then
        node = util_createView("views.UserInfo.view.UserInfoFramCell")
        node:setContentSize(145,145)
        local pos_x = 80+145*(index-1)
        node:setPosition(pos_x,72)
    elseif self.type == 2 then
        node = util_createView("views.UserInfo.view.UserInfoAvterCell")
        node:setContentSize(145,145)
        local pos_x = 80+145*(index-1)
        node:setPosition(pos_x,72)
    elseif self.type == 3 then
        local shopData = cellData.shop
        if shopData and shopData.p_icon == ShopBuckConfig.ItemIcon then
            node = util_createView("views.UserInfo.view.UserInfoBagItemCell_Buck")
        else
            node = util_createView("views.UserInfo.view.UserInfoBagItemCell")
        end
        node:setContentSize(152,175)
        local pos_x = 74+152*(index-1)
        node:setPosition(pos_x,83)
    elseif self.type == 4 then
        node = util_createView("views.UserInfo.view.UserInfoCashItemCell")
        node:setContentSize(204,240)
        local pos_x = 104+206*(index-1)
        node:setPosition(pos_x,120)
    end
    return node
end

return UserInfoHeadTableView 