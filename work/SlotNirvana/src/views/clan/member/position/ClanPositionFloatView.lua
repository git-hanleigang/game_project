--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-21 15:13:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-21 15:13:49
FilePath: /SlotNirvana/src/views/clan/member/position/ClanPositionFloatView.lua
Description: 会长 任命成员职位 UI
--]]
local ClanPositionFloatView = class("ClanPositionFloatView", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanPositionFloatView:getCsbName()
    return "Club/csd/ClubEstablish/Club_InformationModification.csb"
end

function ClanPositionFloatView:initDatas(_memberData)
    ClanPositionFloatView.super.initDatas(self)

    self.m_memberData = _memberData
    self:setExtendData("ClanPositionFloatView")
end

function ClanPositionFloatView:initCsbNodes()
    ClanPositionFloatView.super.initCsbNodes(self)

    self.m_btnLeader    = self:findChild("btn_leader")
    self.m_btnElite     = self:findChild("btn_elite") -- (普通成员 and 精英 or 普通)
    self.m_btnKickoff   = self:findChild("btn_kickoff")
end

function ClanPositionFloatView:initUI()
    ClanPositionFloatView.super.initUI(self)

    -- 触摸
    self:initTouchView()

    -- 初始化按钮UI状态
    self:initBtnUI()

    self:runCsbAction("show", false)
    performWithDelay(self, util_node_handler(self, self.closeUI), 3)
    self:registerListener()
end

-- 触摸
function ClanPositionFloatView:initTouchView()
    -- 触摸
	local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
    self:addChild(touch, -1)
	performWithDelay(self, function()
		if tolua.isnull(touch) then
			return
		end
		touch:move(self:convertToNodeSpaceAR(display.center))
	end, 0)
    touch:setSwallowTouches(true)
    self:addClick(touch)
	-- touch:setBackGroundColorOpacity(120)
	-- touch:setBackGroundColorType(2)
	-- touch:setBackGroundColor(cc.c3b(255,0,0))
end

-- 初始化按钮UI状态
function ClanPositionFloatView:initBtnUI()
    -- 精英按钮
    local positionMember = self.m_memberData:getIdentity()
    local muiKey = "ClanPositionFloatView:elite"
    if positionMember == ClanConfig.userIdentity.ELITE then
        muiKey = "ClanPositionFloatView:member"
    end
    local str = gLobalLanguageChangeManager:getStringByKey(muiKey)
    self:setButtonLabelContent("btn_elite", str)
end

function ClanPositionFloatView:clickFunc(sender)
    local name = sender:getName()
    if name == "touch_mask" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK) 
        self:closeUI()
    elseif name == "btn_leader" then
        ClanManager:popChangePositionConfirmLayer(self.m_memberData, ClanConfig.userIdentity.LEADER)
    elseif name == "btn_elite" then
        self:popChenagePositionConfirmLayer()
    elseif name == "btn_kickoff" then
        -- 踢出公会
        local tipInfo = ProtoConfig.ErrorTipEnum.KICK_OFF_USER
        tipInfo.content =  self.m_memberData:getName()
        ClanManager:popCommonTipPanel(tipInfo, util_node_handler(self, self.confirmKickOffUser))
    end
end

-- 改变成员职位  确认弹板
function ClanPositionFloatView:popChenagePositionConfirmLayer()
    local positionMember = self.m_memberData:getIdentity()
    local changePositionType = ClanConfig.userIdentity.MEMBER
    local bError = false
    if positionMember == ClanConfig.userIdentity.MEMBER then
        changePositionType = ClanConfig.userIdentity.ELITE
        bError = ClanManager:checkElitieMemberFull() --精英满员了吗
    end

    if bError then
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.ELITE_MEMBER_FULL) --精英满员了
        return
    end
    ClanManager:popChangePositionConfirmLayer(self.m_memberData, changePositionType)
end

-- 确定踢出玩家
function ClanPositionFloatView:confirmKickOffUser()
    local udid = self.m_memberData:getUdid()
    ClanManager:requestKickMember(udid)
    self:closeUI()
end

function ClanPositionFloatView:closeUI()
    if self.m_bClose then
        return
    end

    self.m_bClose = true
    self:runCsbAction("over", false, function()
        self:removeSelf()
    end, 60)
end

-- 注册事件
function ClanPositionFloatView:registerListener()
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_CHANGE_MEMBER_POSITION) -- 接收到修改成员职位成功
end

return ClanPositionFloatView