--[[
Author: cxc
Date: 2021-02-25 16:46:12
LastEditTime: 2021-03-17 10:33:10
LastEditors: Please set LastEditors
Description: 邀请玩家 tableView
FilePath: /SlotNirvana/src/views/clan/member/ClanInviteUserTableView.lua
--]]
local BaseTable = util_require("base.BaseTable")
local ClanInviteUserTableView = class("ClanInviteUserTableView", BaseTable)

function ClanInviteUserTableView:ctor(param)
    ClanInviteUserTableView.super.ctor(self, param)
    self.m_touchedNodeList = {}
end

function ClanInviteUserTableView:cellSizeForTable(table, idx)
    return 549, 110
end

function ClanInviteUserTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.clan.member.ClanInviteUserCell")
        cell:addChild(cell.view)
        cell.view:move(549*0.5, 110*0.5)
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    self._cellList[idx + 1] = cell.view

    return cell
end

-- 触摸的处理
function ClanInviteUserTableView:_onTouchBegan( event )
    local touchPoint = cc.p( event.x,event.y )
    self._pointTouchBegin = touchPoint

    for i,node in pairs( self._cellList ) do
        local btn = node:findChild("btn_invite")
        local isTouchPosPanel = self:onTouchCellChildNode( btn,touchPoint )
        if btn:isTouchEnabled() and isTouchPosPanel then
            node:setBtnTouchedState(2)
            table.insert(self.m_touchedNodeList, node)
            break 
        end
    end

    return ClanInviteUserTableView.super._onTouchBegan( self,event )
end
function ClanInviteUserTableView:_onTouchEnded( event )
    local touchPoint = cc.p( event.x,event.y )
    local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)

    self:cancelBtnTouchedState()

    if distance > 10 then
        return
    end
    
    for i,node in pairs( self._cellList ) do
        local btn = node:findChild("btn_invite")
        local isTouchPosPanel = self:onTouchCellChildNode( btn,touchPoint )
        if isTouchPosPanel then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            node:inviteCurUser()
            node:setButtonLabelDisEnabled("btn_invite", false) 
            return
        end
    end

end

-- 取消按钮按下状态
function ClanInviteUserTableView:cancelBtnTouchedState()
    if #self.m_touchedNodeList <= 0 then
        return
    end
    
    for i, node in ipairs(self.m_touchedNodeList) do
        if not tolua.isnull(node) then
            node:setBtnTouchedState(1)
        end
    end

    self.m_touchedNodeList = {}
end

return ClanInviteUserTableView 