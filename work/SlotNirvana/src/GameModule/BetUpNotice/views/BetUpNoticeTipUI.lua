--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-02 17:39:05
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-02 18:08:55
FilePath: /SlotNirvana/src/GameModule/BetUpNotice/views/BetUpNoticeTipUI.lua
Description: spin 升级后 bet值小于指定bet 弹出气泡
--]]
local BetUpNoticeTipUI = class("BetUpNoticeTipUI", BaseView)

function BetUpNoticeTipUI:getCsbName()
    return "GameNode/GameBottomBetUpQipao.csb"
end

function BetUpNoticeTipUI:initUI(_posW)
    BetUpNoticeTipUI.super.initUI(self)

    self.m_posW = _posW
    -- self:addTouchLayer()
    self:setName("BetUpNoticeTipUI")
end
function BetUpNoticeTipUI:onEnter()
    BetUpNoticeTipUI.super.onEnter(self)

    self:move(self.m_posW.x, self.m_posW.y)
    self:playShowAct()
end

function BetUpNoticeTipUI:addTouchLayer()
    -- 触摸
	local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
    touch:setScale(10)
	self:addChild(touch, -1)
	touch:setSwallowTouches(false)
	self:addClick(touch)
	-- touch:setBackGroundColorOpacity(120)
	-- touch:setBackGroundColorType(2)
	-- touch:setBackGroundColor(cc.c3b(255,0,0))
end

function BetUpNoticeTipUI:playShowAct()
    self.m_bCanClick = false
    self:runCsbAction("show", false, function()
        performWithDelay(self, util_node_handler(self, self.playHideAct), 2)
        self:runCsbAction("idle")
        self.m_bCanClick = true
    end, 60)
end

function BetUpNoticeTipUI:playHideAct()
	self:stopAllActions()
    self:runCsbAction("hide", false, function()
        if tolua.isnull(self) then
            return
        end
        self:removeSelf()
    end, 60)
end

function BetUpNoticeTipUI:clickFunc(sender)
	local name = sender:getName()

	if self.m_bCanClick and name == "touch_mask" then
		self:playHideAct()
	end
end

return BetUpNoticeTipUI