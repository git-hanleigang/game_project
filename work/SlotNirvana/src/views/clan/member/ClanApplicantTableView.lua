--[[
Author: cxc
Date: 2021-02-25 17:27:26
LastEditTime: 2021-03-17 10:33:24
LastEditors: Please set LastEditors
Description: 申请列表 tableView
FilePath: /SlotNirvana/src/views/clan/member/ClanApplicantTableView.lua
--]]
local BaseTable = util_require("base.BaseTable")
local ClanApplicantTableView = class("ClanApplicantTableView", BaseTable)

function ClanApplicantTableView:ctor(param)
    ClanApplicantTableView.super.ctor(self, param)
    self.m_touchedNodeList = {}
end

function ClanApplicantTableView:cellSizeForTable(table, idx)
    return 1070, 110
end

function ClanApplicantTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.clan.member.ClanApplicantUserCell")
        cell:addChild(cell.view)
        cell.view:move(1070*0.5, 110*0.5)
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    self._cellList[idx + 1] = cell.view

    return cell
end

-- 触摸的处理
function ClanApplicantTableView:_onTouchBegan( event )
    local touchPoint = cc.p( event.x,event.y )
    self._pointTouchBegin = touchPoint

    for i,node in pairs( self._cellList ) do
        -- 同意
        local btnAgree = node:findChild("btn_agree")
        local isTouchPosPanel = self:onTouchCellChildNode( btnAgree,touchPoint )
        if isTouchPosPanel then
            node:setBtnTouchedState("btn_agree", 2)
            table.insert(self.m_touchedNodeList, {node, "btn_agree"})
            break 
        end
        -- 拒绝
        local btnAgree = node:findChild("btn_refuse")
        local isTouchPosPanel = self:onTouchCellChildNode( btnAgree,touchPoint )
        if isTouchPosPanel then
            node:setBtnTouchedState("btn_refuse", 2)
            table.insert(self.m_touchedNodeList, {node, "btn_refuse"})
            break 
        end
    end

    return ClanApplicantTableView.super._onTouchBegan( self,event )
end
function ClanApplicantTableView:_onTouchEnded( event )
    local touchPoint = cc.p( event.x,event.y )
    local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)

    self:cancelBtnTouchedState()

    if distance > 10 then
        return
    end
    
    for i,node in pairs( self._cellList ) do
        -- 同意
        local btnAgree = node:findChild("btn_agree")
        local isTouchPosPanel = self:onTouchCellChildNode( btnAgree,touchPoint )
        if isTouchPosPanel then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            node:agreeCurUserJoinClan()
            break 
        end
        -- 拒绝
        local btnAgree = node:findChild("btn_refuse")
        local isTouchPosPanel = self:onTouchCellChildNode( btnAgree,touchPoint )
        if isTouchPosPanel then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            node:rejectCurUserJoinClan()
            break 
        end
    end

end

-- 取消按钮按下状态
function ClanApplicantTableView:cancelBtnTouchedState()
    if #self.m_touchedNodeList <= 0 then
        return
    end
    
    for i, info in ipairs(self.m_touchedNodeList) do
        local node = info[1]
        local btnName = info[2]
        if not tolua.isnull(node) and not btnName then
            node:setBtnTouchedState(btnName, 1)
        end
    end

    self.m_touchedNodeList = {}
end

return ClanApplicantTableView 

