--[[
Author: cxc
Date: 2021-02-03 14:22:28
LastEditTime: 2021-07-22 11:19:15
LastEditors: Please set LastEditors
Description: 公会成员 
FilePath: /SlotNirvana/src/views/clan/member/ClanSysViewMember.lua
--]]
local ClanSysViewMember = class("ClanSysViewMember", util_require("base.BaseView"))
local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = require("data.clanData.ChatConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanSysViewMember:initUI()
    local csbName = "Club/csd/Main/ClubSysMember.csb"
    self:createCsbNode(csbName)
    
    -- listview
    local listView = self:findChild("listView_member")
    listView:removeAllItems()
	listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    self.m_listView = listView

    self:updateUI()
    self:registerListener()
end 

function ClanSysViewMember:onEnter()
    -- 引导逻辑
    performWithDelay(self, util_node_handler(self, self.dealGuideLogic), 0)
end

function ClanSysViewMember:updateUI()
    local clanData = ClanManager:getClanData()

    -- 列表
    local memberList = clanData:getClanMemberList()
    local itemViewList = self.m_listView:getItems()
    self.m_memberCell_pointMax = nil
    for i=1, #memberList do
        local memberData = memberList[i]
        self:refreshListViewItem(i-1, memberData)
    end
    if #itemViewList > #memberList then
        self:delOverListViewItem(#memberList+1, #itemViewList)
    end

    -- 列表基本信息
    local curCount =  #memberList
    local limitCount = clanData:getMemberMax() 
    local bFull = curCount >= limitCount
    local lbMemberCount = self:findChild("font_renshu")
    lbMemberCount:setString(curCount .. "/" .. limitCount)

    -- 邀请按钮(公会人满了不显示)
    local btnInvite = self:findChild("btn_invite")
    btnInvite:setVisible(not bFull)
    if curCount == 0 then
        btnInvite:setVisible(false)
    end

    -- 申请按钮
    -- 申请列表按钮(只有会长可以看到)
    local userIdentity = clanData:getUserIdentity()
    local bLeader = userIdentity == ClanConfig.userIdentity.LEADER
    local btnApplicant = self:findChild("node_btn_1")
    btnApplicant:setVisible(bLeader)
    -- 申请列表 小红点
    local nodeRed = self:findChild("spApplicatRed")
    if bLeader and nodeRed then
        self.m_nodeRed = nodeRed
        self:updateRedPoints()
        self:clearScheduler()
        self.m_scheduler = schedule(self, handler(self, self.updateRedPoints), 1)
    end
end

-- 刷新成员信息
function ClanSysViewMember:refreshListViewItem(_idx, _memberData)
    local layout = self.m_listView:getItem(_idx)
    local cellView
    if layout then
        cellView = layout:getChildByName("ClanMemberCell")
        if cellView then
            cellView:updateUI(_memberData)
        end
    else
        layout = self:createMemberCell(_memberData)
        cellView = layout:getChildByName("ClanMemberCell")
        self.m_listView:pushBackCustomItem(layout)
    end

    if cellView and _memberData:getIdentity() ~= ClanConfig.userIdentity.LEADER and not self.m_memberCell_pointMax then
        self.m_memberCell_pointMax = cellView
    end
end
-- 删除listView溢出的 节点
function ClanSysViewMember:delOverListViewItem(_startIdx, _endIdx)
    for i=_startIdx, _endIdx do
        self.m_listView:removeItem(i-1) 
    end
end

-- 显示红点
function ClanSysViewMember:updateRedPoints()
    local clanData = ClanManager:getClanData()
    local num = clanData:getApplyCounts()

    local bShow = num > 0
    self.m_nodeRed:setVisible( bShow )
    
    if not bShow then
        return
    end

    local lbRedNum = self:findChild("lb_num")
    lbRedNum:setString( num )
end

-- 创建 成员cell
-- _memberData type == ClanUser
function ClanSysViewMember:createMemberCell(_memberData)
    if not _memberData then
        return
    end

    local layout = ccui.Layout:create()
    local itemUI = util_createView("views/clan/member/ClanMemberCell")
    itemUI:updateUI(_memberData)
    itemUI:setName("ClanMemberCell")
    layout:addChild(itemUI)
    layout:setContentSize(cc.size(858,112))
    itemUI:move(858*0.5, 112*0.5)

    return layout
end

function ClanSysViewMember:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_invite" then
        -- 邀请 玩家
        self:popInvitePanel()
    elseif name == "btn_applicant" then
        -- 申请列表按钮
        self:popApplicantListPanel()
    end
end

-- 邀请人面板
function ClanSysViewMember:popInvitePanel()
    local view = util_createView("views.clan.member.ClanInvitePanel")
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_UI)
end

-- 申请人面板
function ClanSysViewMember:popApplicantListPanel()
    local view = util_createView("views.clan.member.ClanApplicantListPanel")
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_UI)
end

function ClanSysViewMember:agreeUserJoinEvt()
    ClanManager:sendClanMemberList()
end

-- 处理 引导逻辑
function ClanSysViewMember:dealGuideLogic()
    if tolua.isnull(self) then
        return
    end
    
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterMember.id) -- 第一次进入公会主页
    if bFinish then
        self:checkGuideChangePositionView()
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterMember)
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewPositionView)
    -- globalData.NoviceGuideFinishList[#globalData.NoviceGuideFinishList + 1] = NOVICEGUIDE_ORDER.clanFirstEnterMember.id 

    local nodeAll = self:findChild("node_members") -- 公会基本信息按钮
    local guideNodeList = {nodeAll}
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstEnterMember.id, guideNodeList)
end
function ClanSysViewMember:checkGuideChangePositionView()
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstCheckNewPositionView.id) -- 第一次进入公会主页
    if bFinish then
        return
    end
    
    local clanData = ClanManager:getClanData()
    local userIdentity = clanData:getUserIdentity()
    local bLeader = userIdentity == ClanConfig.userIdentity.LEADER
    if not bLeader then
        return
    end
    
    if not self.m_memberCell_pointMax then
        return
    end
    
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewPositionView)
    performWithDelay(self, function()
        local curShowType = ClanManager:getCurSystemShowType() 
        if curShowType ~= ClanConfig.systemEnum.MEMEBER then
            return
        end
        if not self.m_memberCell_pointMax then
            return
        end
        ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstCheckNewPositionView.id, {self.m_memberCell_pointMax})
    end, 0.5)
end

-- 引导显示职位变化floatView
function ClanSysViewMember:onShowGuideFloatViewEvt()
    if tolua.isnull(self.m_memberCell_pointMax) then
        return
    end

    self.m_memberCell_pointMax:showFloatView()
end

function ClanSysViewMember:onRecieveMemberListEvt()
    self:updateUI()
    self:checkGuideChangePositionView()
end

--玩家退出或被踢更新 成员数据
function ClanSysViewMember:deleteMemberByUdidEvt(_udid)
    local itemViewList = self.m_listView:getItems()
    for i=1, #itemViewList do
        local layout = itemViewList[i]
        local cellView = layout:getChildByName("ClanMemberCell")
        local memberData = cellView:getData()
        if cellView and memberData:getUdid() == _udid then
            self.m_listView:removeItem(i-1)
            break
        end
    end
end

-- 注册事件
function ClanSysViewMember:registerListener(  )
    gLobalNoticManager:addObserver(self, "onRecieveMemberListEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_MEMBER_LIST) -- 请求接收到公会成员列表
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.RECIEVE_CHANGE_MEMBER_POSITION) -- 接收到修改成员职位成功
    gLobalNoticManager:addObserver(self, "agreeUserJoinEvt", ClanConfig.EVENT_NAME.RECIEVE_CLAN_AGREE_USER_JOIN)
    gLobalNoticManager:addObserver(self, "clearScheduler", ClanConfig.EVENT_NAME.CLOSE_CLAN_HOME_VIEW)  -- 关闭公会
    gLobalNoticManager:addObserver(self, "onShowGuideFloatViewEvt", ClanConfig.EVENT_NAME.NOTIFY_SHOW_POSITION_FLOAT_VIEW)  -- 引导显示职位变化floatView
    gLobalNoticManager:addObserver(self, "deleteMemberByUdidEvt", ChatConfig.EVENT_NAME.DELETE_DATABASE_MEMBER) --玩家退出或被踢更新 成员数据
end

-- 清楚定时器
function ClanSysViewMember:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return ClanSysViewMember