--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-24 14:57:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-24 14:57:19
FilePath: /SlotNirvana/src/views/clan/member/ClanMembeCell.lua
Description: 公会成员 cell
--]]
local ClanMemberCell = class("ClanMemberCell", util_require("base.BaseView"))
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanMemberCell:getCsbName()
    return "Club/csd/Main/ClubMemberCell.csb"
end

function ClanMemberCell:updateUI(_memberData)
    self.m_memberData = _memberData
    self.m_bMe = self.m_memberData:checkIsBMe()
    self.m_fontColor = self.m_bMe and cc.c3b(249, 195, 255) or cc.c3b(118, 52, 216)
    
    self:updateBgVisible()
    self:updateCountingVisible()
    self:updateUserLevel()
    self:updateUserPosition()
    self:updateUserName()
    self:updateUserHead()
    self:updateUserPoints()
    self:updateLastLogonTime()

    self:updateBtnState()
end

-- 底板
function ClanMemberCell:updateBgVisible()
    local spBgMe = self:findChild("sp_diban2")
    local spBgOther = self:findChild("sp_diban1")
    spBgMe:setVisible(self.m_bMe)
    spBgOther:setVisible(not self.m_bMe)

    local spPointBgMe = self:findChild("sp_di_zi")
    local spPointBgOther = self:findChild("sp_di_lan")
    spPointBgMe:setVisible(self.m_bMe)
    spPointBgOther:setVisible(not self.m_bMe)
end

-- 结算中 文本
function ClanMemberCell:updateCountingVisible()
    local lbPoint = self:findChild("lb_points")
    local lbCounting = self:findChild("lb_counting")
    local bCounting = ClanManager:checkShowTaskReward()
    lbCounting:setVisible(bCounting)
    lbPoint:setVisible(not bCounting)
end

-- 等级
function ClanMemberCell:updateUserLevel()
    local lbLevel = self:findChild("lb_level")
    local level = self.m_memberData:getLevel()
    lbLevel:setString("LV: " .. level)
    lbLevel:setTextColor(self.m_fontColor)
end

-- 职位
function ClanMemberCell:updateUserPosition()
    local nodeLeader = self:findChild("node_leader")
    local nodeElite = self:findChild("node_elite")
    local position = self.m_memberData:getIdentity()
    nodeLeader:setVisible(position == ClanConfig.userIdentity.LEADER)
    nodeElite:setVisible(position == ClanConfig.userIdentity.ELITE)
end

-- 姓名
function ClanMemberCell:updateUserName()
    local layoutName = self:findChild("layout_name")
    local lbName = self:findChild("lb_name")
    local name = self.m_memberData:getName()
    lbName:setString(name)
    lbName:setTextColor(self.m_fontColor)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end

-- 头像
function ClanMemberCell:updateUserHead()
    local _headParent = self:findChild("sp_head")
    local fbId = self.m_memberData:getFacebookId()
    local head = self.m_memberData:getHead() 
    local frameId = self.m_memberData:getFrameId()
    local headSize = _headParent:getContentSize()

    if self.m_bLoadHead and fbId == self.m_preFbId and head == self.m_preHead and frameId == self.m_preFrameId then
        return
    end
    self.m_preFbId = fbId
    self.m_preHead = head
    self.m_preFrameId = frameId
    _headParent:removeAllChildren()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    nodeAvatar:addTo(_headParent)
    nodeAvatar:setName("sp_head")
    self.m_bLoadHead = true
end

-- 公会点数
function ClanMemberCell:updateUserPoints()
    local lbPoint = self:findChild("lb_points")
    local points = self.m_memberData:getPoints()
    lbPoint:setString(util_getFromatMoneyStr(points))
end

-- 登录时间
function ClanMemberCell:updateLastLogonTime()
    local lbLastLogonTime = self:findChild("lb_lastLoginTime")
    local timeStr = ""
    if self.m_memberData:checkIsOnline() then
        timeStr = "ONLINE"
    else
        local lastTime = self.m_memberData:getLastLoginTime()
        timeStr = self:getLastLogonTimeStr()
    end
    lbLastLogonTime:setString(timeStr)
    lbLastLogonTime:setVisible(false) -- 此功能先不开未来优化
end

-- 按钮状态
function ClanMemberCell:updateBtnState()
    local btnChangePosition = self:findChild("btn_changePosition")
    local bVisible = ClanManager:checkCanPopPositionFloatView(self.m_memberData)
    btnChangePosition:setVisible(bVisible)
    btnChangePosition:setSwallowTouches(false)
end

--按钮监听回调
function ClanMemberCell:clickFunc(sender)
    local name = sender:getName()
    if self.m_bMe and name == "btn_userInfo" then
        G_GetMgr(G_REF.UserInfo):showMainLayer()
    elseif name == "btn_userInfo" then
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_memberData:getUdid(), "", "", self.m_memberData:getFrameId())
    elseif name == "btn_changePosition" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK) 
        if tolua.isnull(self.m_floatView) then
            self:showFloatView()
        else
            self.m_floatView:closeUI()
        end
    end
end

-- 显示 改变职位float界面
function ClanMemberCell:showFloatView()
    local parent = gLobalViewManager:getViewByExtendData("ClanHomeView")
    local refNode = self:findChild("node_floatView")
    local posW = refNode:convertToWorldSpace(cc.p(0, 0))
    self.m_floatView = ClanManager:showChangePositionFloatView(self.m_memberData)
    if self.m_floatView then
        parent:addChild(self.m_floatView)
        local posL = parent:convertToNodeSpace(posW)
        self.m_floatView:move(posL)
    end
end

-- 个人信息页 修改玩家信息 evt
function ClanMemberCell:onRefreshSelfUserInfoEvt()
    self:updateUserName()
    self:updateUserHead()
end

function ClanMemberCell:registerListener()
    if self.m_bMe then
        gLobalNoticManager:addObserver(self, "onRefreshSelfUserInfoEvt", ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
    end
end

-- 获取上次登录的时间
function ClanMemberCell:getLastLogonTimeStr(_time)
    local preStr = ""
    if not _time or _time <= 0 then
        return  "1 HOUR AGO"
    end

    local curTime = util_getCurrnetTime()
    local subTime = math.floor((curTime - (_time * 0.001))) 
    local days = math.floor(subTime / 86400)
    local str = "TODAY"
    if days < 1 then
        local hour = math.floor(subTime / 3600)
        if hour <= 1 then
            return "1 HOUR AGO" 
        end
        return hour .. " HOURS AGO"
    elseif days == 1 then
        return "1 DAY AGO"
    elseif days > 1 then
        return days .. " DAYS AGO"
    end
    
    return preStr .. str
end

function ClanMemberCell:getData()
    return self.m_memberData
end

return ClanMemberCell