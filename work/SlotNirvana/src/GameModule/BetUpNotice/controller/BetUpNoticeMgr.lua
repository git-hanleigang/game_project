--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-02 12:06:27
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-02 12:06:55
FilePath: /SlotNirvana/src/GameModule/BetUpNotice/controller/BetUpNoticeMgr.lua
Description: spin 升级后 bet值小于指定bet 弹出气泡
--]]
local BetUpNoticeMgr = class("BetUpNoticeMgr", BaseGameControl)

function BetUpNoticeMgr:ctor()
    BetUpNoticeMgr.super.ctor(self)
    
    self:setRefName(G_REF.BetUpNotice)
    -- 本次spin是否提示 加bet
    self.m_curSpinBetUpShow = false
end

-- 本次spin是否提示 加bet
function BetUpNoticeMgr:setCurSpinBetUpShow(_bShow)
    self.m_curSpinBetUpShow = _bShow
end
function BetUpNoticeMgr:checkCurSpinBetUpShow()
    return self.m_curSpinBetUpShow
end

function BetUpNoticeMgr:showBetUpNoticeBubbleUI(_posW)
    if not _posW or gLobalViewManager:getViewByName("BetUpNoticeTipUI") then
        return
    end

    local view = util_createView("GameModule.BetUpNotice.views.BetUpNoticeTipUI", _posW)
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_GUIDE)
end

-- 点击 改变bet值 关闭气泡提示
function BetUpNoticeMgr:removeBetUpNoticeBubbleUI()
    local view = gLobalViewManager:getViewByName("BetUpNoticeTipUI")
    if tolua.isnull(view) then
        return
    end
    view:removeSelf()
end

return BetUpNoticeMgr