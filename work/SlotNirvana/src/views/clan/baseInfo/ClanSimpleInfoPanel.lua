--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-27 16:34:35
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-27 16:36:00
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanSimpleInfoPanel.lua
Description: 公会 基本信息面板
--]]
local ClanSimpleInfoPanel = class("ClanSimpleInfoPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanSimpleInfoPanel:ctor()
    ClanSimpleInfoPanel.super.ctor(self)

    self:setExtendData("ClanSimpleInfoPanel")
    self:setLandscapeCsbName("Club/csd/ClubEstablish/Club_Create_Info.csb")
    self:setKeyBackEnabled(true)
end

function ClanSimpleInfoPanel:initDatas(_simpleInfo)
    ClanSimpleInfoPanel.super.initDatas(self)

    -- 公会基础信息
    self.m_clanData = ClanManager:getClanData()
    self.m_bSearchEnter = _simpleInfo ~= nil
    self.m_simpleInfo = _simpleInfo or self.m_clanData:getClanSimpleInfo()
    self.m_nodeTagBubbleList = {}
end

function ClanSimpleInfoPanel:initView()
    ClanSimpleInfoPanel.super.initView(self)

    -- 按钮排列
    self.m_btnPosList = {}
    for i = 1, 3 do
        local nodeRefPos = self:findChild("node_refPos_" .. i)
        local pos = cc.p(nodeRefPos:getPosition())
        self.m_btnPosList[i] = pos
    end
    -- 按钮显隐
    self:initBtnVisible()

    self:updateUI()
end

function ClanSimpleInfoPanel:updateUI()
    -- 公会 logo
    self:updateTeamLogoUI()
    -- 公会名字
    self:updateTeamName()
    -- 公会id
    self:updateTeamId()
    -- 公会宣言
    self:updateClanDesc()
    -- 公会所属国家地区
    self:updateRegionUI()
    -- 公会 标签
    self:updateTeamTag()
    -- 公会 加入 类型(1,自由出入 2,需要申请)
    self:updateJoinTypeUI()
    -- 加入公会 vip限制
    self:updateJoinLimitVipLV()
    -- 公会 排行段位
    self:updateTeamRankDvision()
end

-- 按钮显隐
function ClanSimpleInfoPanel:initBtnVisible()
    local btnTouch = self:findChild("btn_touch")
    btnTouch:setSwallowTouches(false) 

    local selfPosition = self.m_clanData:getUserIdentity()
    local alignBtnList = {}

    -- 有公会了还搜索公会 只显示公会信息不显示个功能按钮
    local bHideBtn = selfPosition ~= ClanConfig.userIdentity.NON and self.m_bSearchEnter

    -- 离开公会按钮
    local btnLeave = self:findChild("Node_leave")
    local leaveVisible = selfPosition ~= ClanConfig.userIdentity.NON and not bHideBtn
    btnLeave:setVisible(leaveVisible)
    if leaveVisible then
        table.insert(alignBtnList, btnLeave)
    end

    -- 编辑按钮 会长才会显示
    local btnEdit = self:findChild("Node_edit")
    local editVisble = selfPosition == ClanConfig.userIdentity.LEADER and not bHideBtn
    btnEdit:setVisible(editVisble)
    if editVisble then
        table.insert(alignBtnList, btnEdit)
    end

    -- 加入公会
    local btnJoin = self:findChild("Node_join")
    local joinVisible = selfPosition == ClanConfig.userIdentity.NON and not bHideBtn
    btnJoin:setVisible(joinVisible)
    if joinVisible then
        table.insert(alignBtnList, btnJoin)
    end

    -- 按钮位置
    self:initBtnPos(alignBtnList)
end
-- 按钮位置
function ClanSimpleInfoPanel:initBtnPos(_alignBtnList)
    if not _alignBtnList or #_alignBtnList == 0 then
        return
    end

    local bMore = #_alignBtnList > 1
    if bMore then
        for idx, btn in pairs(_alignBtnList) do
            local pos = self.m_btnPosList[idx]
            if pos then
                btn:move(pos)
            end
        end
        return
    end

    local btn = _alignBtnList[1]
    local pos = self.m_btnPosList[3] or cc.p(0, -296)
    btn:move(pos)
end

-- 公会 logo
function ClanSimpleInfoPanel:updateTeamLogoUI()
    local spClanIconBg = self:findChild("sp_clubIconBg")
    local spLogo = self:findChild("sp_clubIcon")
    local iconName = self.m_simpleInfo:getTeamLogo()
    local imgBgPath = ClanManager:getClanLogoBgImgPath(iconName)
    local imgPath = ClanManager:getClanLogoImgPath(iconName)
    util_changeTexture(spClanIconBg, imgBgPath)
    util_changeTexture(spLogo, imgPath)
end

-- 公会名字
function ClanSimpleInfoPanel:updateTeamName()
    local lbName = self:findChild("font_name")
    local name = self.m_simpleInfo:getTeamName()
    lbName:setString(name)
end

-- 公会id
function ClanSimpleInfoPanel:updateTeamId()
    local lbClanId = self:findChild("font_teamid")
    local clanId = self.m_simpleInfo:getTeamCid()
    lbClanId:setString("ID: " .. clanId)
end

-- 公会宣言
function ClanSimpleInfoPanel:updateClanDesc()
    local listView = self:findChild("ListView_desc")
    listView:setScrollBarEnabled(false)
    local lbDesc = self:findChild("font_xuanyan")
    local desc = self.m_simpleInfo:getTeamDesc()
    local limitW = listView:getContentSize().width
    util_AutoLine(lbDesc, desc, limitW, true)
    listView:requestDoLayout()
end

-- 公会所属国家地区
function ClanSimpleInfoPanel:updateRegionUI()
    local lbCountry = self:findChild("lb_country")
    local region = self.m_simpleInfo:getTeamCountryArea()
    local country = string.split(region, "|")[1] or ""
    local state = string.split(region, "|")[2] or ""
    if country == "" then
        country = "USA"
    end
    if state == "" then
        lbCountry:setString(country)
    else
        lbCountry:setString(state .. ". " .. country)
    end
    util_scaleCoinLabGameLayerFromBgWidth(lbCountry, 210, 1)
end

-- 公会 标签
function ClanSimpleInfoPanel:updateTeamTag()
    local tag = self.m_simpleInfo:getTeamTag()
    local tagList = string.split(tag, "|")
    self.m_nodeTagBubbleList = {}
    for i = 1, 3 do
        local node = self:findChild("node_tag" .. i)
        node:removeChildByName("node_teamTag")
        local tag = tagList[i]
        if tonumber(tag) then
            local spTag = ClanManager:createTagSprite(tagList[i])
            spTag:setName("node_teamTag")
            node:addChild(spTag)
            local bubbleView = util_createView("views.clan.baseInfo.tag.ClanTagBubbleView", tag)
            bubbleView:setScale(1.5)
            node:addChild(bubbleView)
            self.m_nodeTagBubbleList[i] = bubbleView
        end
    end

end

-- 公会 加入 类型(1,自由出入 2,需要申请)
function ClanSimpleInfoPanel:updateJoinTypeUI()
    local joinType = self.m_simpleInfo:getTeamJoinType()

    local spPublic = self:findChild("lb_public") -- 自由出入
    local spPrivate = self:findChild("lb_private") -- 需要申请
    spPublic:setVisible(joinType == ClanConfig.joinLimitType.PUBLIC)
    spPrivate:setVisible(joinType == ClanConfig.joinLimitType.REQUEST)
end

-- 加入公会 vip限制
function ClanSimpleInfoPanel:updateJoinLimitVipLV()
    local vipLv = self.m_simpleInfo:getTeamMinVipLevel()

    local spVip = self:findChild("sp_vip")
    local vipImgPath = VipConfig.logo_shop .. vipLv .. ".png"
    util_changeTexture(spVip, vipImgPath)
    local spVipDesc = self:findChild("sp_vip_desc")
    local vipDescImgPath = VipConfig.name_big .. vipLv .. ".png"
    util_changeTexture(spVipDesc, vipDescImgPath)
    local scale = util_scaleCoinLabGameLayerFromBgWidth(spVipDesc, 200, 1)
    if scale > 0.6 then
        scale = 0.6
    end
    util_alignCenter(
        {
            {node = spVip},
            {node = spVipDesc, scale = scale, alignX = 5}
        }
    )
end

-- 公会 排行段位
function ClanSimpleInfoPanel:updateTeamRankDvision()
    local division = self.m_simpleInfo:getTeamDivision()

    local spRankIcon = self:findChild("sp_rank1")
    local iconPath = ClanManager:getRankDivisionIconPath(division)
    util_changeTexture(spRankIcon, iconPath)
    local lbRankId = self:findChild("font_rankid")
    local divisionDesc = ClanManager:getRankDivisionDesc(division)
    lbRankId:setString(divisionDesc)

    util_alignCenter(
        {
            {node = spRankIcon, scale = 0.18},
            {node = lbRankId, alignX = 5, alignY = 1}
        }
    )
end

function ClanSimpleInfoPanel:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_leaveteam" then
        -- 离开公会
        ClanManager:popCommonTipPanel(
            ProtoConfig.ErrorTipEnum.LEAVE_CUR_CLAN,
            function()
                ClanManager:requestLeaveClan()
            end
        )
    elseif name == "btn_edit" then
        -- 编辑公会基本信息
        local clanData = ClanManager:getClanData()
        local simpleInfo = clanData:getClanSimpleInfo()
        ClanManager:popEditClanInfoPanel(simpleInfo)
    elseif name == "btn_join" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 加入公会
        local clanId = self.m_simpleInfo:getTeamCid()
        ClanManager:requestClanJoin(clanId)
    elseif name == "btn_tag1" and self.m_nodeTagBubbleList[1] then
        self:clickTagByIdx(1)
    elseif name == "btn_tag2" and self.m_nodeTagBubbleList[2] then
        self:clickTagByIdx(2)
    elseif name == "btn_tag3" and self.m_nodeTagBubbleList[3] then
        self:clickTagByIdx(3)
    elseif name == "btn_touch" then
        -- 隐藏气泡
        self:hideTagBubble()
    end
end

function ClanSimpleInfoPanel:clickTagByIdx(_idx)
    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.CLICK_INFO_TAG)

    local bShow = self.m_nodeTagBubbleList[_idx]:isVisible()
    self:hideTagBubble()
    if not bShow then
        self.m_nodeTagBubbleList[_idx]:showTip()
        self:runCsbAction("start".._idx)
    end
end
function ClanSimpleInfoPanel:hideTagBubble()
    for _,node in ipairs(self.m_nodeTagBubbleList) do
        node:hideTip()
    end
end

-- 离开公会成功
function ClanSimpleInfoPanel:onLeaveClanSuccessEvt()
    self:closeUI()
end

-- 编辑公会成功
function ClanSimpleInfoPanel:onEditClanInfoSuccessEvt()
    self.m_clanData = ClanManager:getClanData()
    self.m_simpleInfo = self.m_clanData:getClanSimpleInfo()

    self:updateUI()
end

-- 注册弹板事件
function ClanSimpleInfoPanel:registerListener()
    ClanSimpleInfoPanel.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onEditClanInfoSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_NEW_CLAN_INFO_SUCCESS)
    gLobalNoticManager:addObserver(self, "onEditClanInfoSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_CHAGE_CLAN_NAME)
    gLobalNoticManager:addObserver(self, "onLeaveClanSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_USER_LEAVE_CLAN)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_JOIN_CLAN_SUCCESS)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
end
return ClanSimpleInfoPanel