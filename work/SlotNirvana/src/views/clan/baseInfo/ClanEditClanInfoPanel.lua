--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-25 15:08:55
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-25 15:09:18
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanEditClanInfoPanel.lua
Description: 公会信息编辑界面
--]]
local ClanEditClanInfoPanel = class("ClanEditClanInfoPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")
local ClanBaseInfoData = util_require("data.clanData.ClanBaseInfoData")

function ClanEditClanInfoPanel:ctor()
    ClanEditClanInfoPanel.super.ctor(self)

    self.m_ranName = ClanManager:generateClanRandomName() --创建公会默认名字
    self.m_defaultDescPlaceH = "HAVE A GOOD TIME" -- 创建公会默认简介描述

    self:setExtendData("ClanEditClanInfoPanel")
    self:setLandscapeCsbName("Club/csd/ClubEstablish/Club_Create_team.csb")
    self:setKeyBackEnabled(true)

    self:addClickSound("btn_save", SOUND_ENUM.SOUND_HIDE_VIEW)
end

function ClanEditClanInfoPanel:initDatas(_simpleInfo)
    self.m_simpleInfo = _simpleInfo or ClanBaseInfoData:create()
    self.m_editTeamInfo = clone(self.m_simpleInfo)
    self.m_bCreateClan = _simpleInfo == nil
    self.m_maxVipLevel = globalData.userRunData.vipLevel

    ClanEditClanInfoPanel.super.initDatas(self)
end

function ClanEditClanInfoPanel:initCsbNodes()
    ClanEditClanInfoPanel.super.initCsbNodes(self)

    -- 公会名字
    self.text_name = util_convertTextFiledToEditBox(self:findChild("TextField_name"))
    self.btn_editName = self:findChild("btn_editName")
    self.lb_namePlaceHolder = self:findChild("lb_namePlaceHolder")
    self.lb_nameWordsLeft = self:findChild("lb_nameWordLeft")

    -- 公会描述
    self.listView = self:findChild("ListView_desc")
    self.listView:setScrollBarEnabled(false)
    local textFieldDesc = self:findChild("TextField_desc")
    self.m_descUISize = textFieldDesc:getContentSize()
    self.m_descUIFondSize = textFieldDesc:getFontSize()
    self.text_desc = util_convertTextFiledToEditBox(textFieldDesc, nil, nil, cc.EDITBOX_INPUT_MODE_ANY)
    self.text_desc:onEditHandler(handler(self, self.onDescEdit))
    textFieldDesc:removeSelf()
    self.lb_descPlaceHolder = self:findChild("lb_descPlaceHolder")
    self.lb_descWordsLeft = self:findChild("font_word_desc")
end

function ClanEditClanInfoPanel:initView()
    ClanEditClanInfoPanel.super.initView(self)

    self:setPageVisible(1)

    -- 公会标题显隐
    self:initTitleVisible()
    -- 公会 logo
    self:updateTeamLogo()
    -- 公会名字
    self:initTeamName()
    -- 公会宣言
    self:initClanDesc()
    -- 公会所属国家地区
    self:initRegionUI()
    -- 公会 标签
    self:initTeamTag()
    -- 公会 加入 类型(1,自由出入 2,需要申请)
    self:initJoinTypeUI()
    -- 加入公会 vip限制
    self:initJoinLimitVipLV()
end

-- 公会标题显隐
function ClanEditClanInfoPanel:initTitleVisible()
    local spTitleCreate = self:findChild("sp_titleCreate")
    local spTitleEdit = self:findChild("sp_titleEdit")
    spTitleCreate:setVisible(self.m_bCreateClan)
    spTitleEdit:setVisible(not self.m_bCreateClan)
end

-- 公会 logo
function ClanEditClanInfoPanel:updateTeamLogo(_iconName)
    if not _iconName then
        _iconName = self.m_simpleInfo:getTeamLogo() or util_random(1, ClanConfig.MAX_LOGO_COUNT)
    end
    local spClanIconBg = self:findChild("sp_clubIconBg")
    local spLogo = self:findChild("sp_clubIcon")
    local imgBgPath = ClanManager:getClanLogoBgImgPath(_iconName)
    local imgPath = ClanManager:getClanLogoImgPath(_iconName)
    util_changeTexture(spClanIconBg, imgBgPath)
    util_changeTexture(spLogo, imgPath)
    self.m_editTeamInfo:setTeamLogo(_iconName)
end

-- 公会名字
function ClanEditClanInfoPanel:initTeamName()
    if self.m_bCreateClan then
        self.btn_editName:setVisible(false)
        self.text_name:setVisible(true)
        self.text_name:onEditHandler(handler(self, self.onNameEdit))
        self.lb_namePlaceHolder:setString(self.m_ranName) 
        self.text_name:setFontColor(self.lb_namePlaceHolder:getTextColor())
    else
        self.btn_editName:setVisible(true)
        self.text_name:setVisible(false)
    end

    local name = self.m_simpleInfo:getTeamName() or self.m_ranName
    self:updateTeamName(name)
end
-- 更新名字
function ClanEditClanInfoPanel:updateTeamName(_name)
    _name = _name or self.text_name:getText()

    local _name = SensitiveWordParser:getString(_name, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
    _name = string.gsub(_name, "[^%w]", "")
    self.lb_namePlaceHolder:setVisible(#_name == 0)
    self.text_name:setText(_name)
    if not self.m_bCreateClan then
        self.lb_namePlaceHolder:setString(_name)
        self.lb_namePlaceHolder:setVisible(true)
    end
    util_scaleCoinLabGameLayerFromBgWidth(self.lb_namePlaceHolder, 440, self.lb_namePlaceHolder:getScale())

    self:updateNameLeftCounts()
end
-- 刷新 剩余 文字提示ui
function ClanEditClanInfoPanel:updateNameLeftCounts()
    local name = self.text_name:getText()
    local count = #name

    local leftCount = ClanConfig.CLAN_NAME_LIMIT_SIZE - count
    self.lb_nameWordsLeft:setString(leftCount)
    self.lb_nameWordsLeft:setVisible(leftCount > 0)
end

-- 公会宣言
function ClanEditClanInfoPanel:initClanDesc()
    local desc = self.m_simpleInfo:getTeamDesc()
    self.lb_descPlaceHolder:setString(self.m_defaultDescPlaceH)
    self.text_desc:setFontColor(self.lb_descPlaceHolder:getTextColor())

    self:updateClanDesc(desc)
end
-- 公会描述
function ClanEditClanInfoPanel:updateClanDesc(_desc)
    _desc = _desc or ""
    self.lb_descPlaceHolder:setVisible(#_desc <= 0)
    _desc = string.gsub(_desc, "[^%w^%s^%p]", "")
    if string.find(_desc, "^%s+$") then
        _desc = "" -- 全是空格置空
    end
    self.text_desc:setText(_desc)
    self.listView:requestDoLayout()
    self.listView:jumpToBottom()
    self:updateDescCounts()
end
-- 刷新 剩余 文字提示ui
function ClanEditClanInfoPanel:updateDescCounts()
    local desc = self.text_desc:getText()
    local count = #desc

    local leftCount = ClanConfig.CLAN_DESC_LIMIT_SIZE - count
    self.lb_descWordsLeft:setString(leftCount)
end

-- 地区
function ClanEditClanInfoPanel:initRegionUI()
    local region = self.m_simpleInfo:getTeamCountryArea()
    local country = string.split(region, "|")[1]
    local state = string.split(region, "|")[2]
    self:updateRegionUI(country, state)

    local nodeRegionDetailView = self:findChild("node_country_show")
    local view = util_createView("views.clan.baseInfo.region.ClanRegionView")
    nodeRegionDetailView:addChild(view)
    self.m_teamRegionView = view
end
function ClanEditClanInfoPanel:updateRegionUI(_country, _state)
    _country = _country or ""
    _state = _state or ""
    local layoutCountry = self:findChild("layout_country")
    local layoutState = self:findChild("layout_state")
    local lbCountry = self:findChild("lb_country")
    local lbState = self:findChild("lb_state")

    if _country == "" then
        _country = "USA"
    else
    end
    lbCountry:setString(_country)
    util_wordSwing(lbCountry, 2, layoutCountry, 3, 30, 3)

    if _state == "" then
        lbState:setString("--")
    else
        lbState:setString(_state)
    end
    util_wordSwing(lbState, 2, layoutState, 3, 30, 3)

    self.m_editTeamInfo:setTeamCountryArea(_country .. "|" .. _state)
    self.m_editTeamInfo.country = _country 
    self.m_editTeamInfo.state = _state

    local btnState = self:findChild("btn_country2")
    local stateList = ClanManager:getStdCountryData(self.m_editTeamInfo.country)
    btnState:setEnabled(#stateList > 0)
end

-- 公会 标签
function ClanEditClanInfoPanel:initTeamTag()
    local tag = self.m_simpleInfo:getTeamTag()
    local tagList = string.split(tag, "|")
    if self.m_bCreateClan and #tagList == 1 and tagList[1] == "" then
        -- 创建公会 玩家未选择时，默认选择标签1
        tagList = {1}
    end
    self:updateTeamTag(tagList)
end
function ClanEditClanInfoPanel:updateTeamTag(_list)
    local nodeTag = self:findChild("node_style")
    nodeTag:removeAllChildren()
    local alignUIList = {}
    local tagStr = ""
    for i=1, #_list do
        local spTag = ClanManager:createTagSprite(_list[i])
        nodeTag:addChild(spTag)
        table.insert(alignUIList, {node = spTag, alignX = 5})
    end
    util_alignCenter(alignUIList)
    self.m_editTeamInfo:setTeamTag(table.concat(_list, "|"))
end

-- 公会 加入 类型(1,自由出入 2,需要申请)
function ClanEditClanInfoPanel:initJoinTypeUI(_joinType)
    local joinType = self.m_simpleInfo:getTeamJoinType() or ClanConfig.joinLimitType.PUBLIC
    self:updateJoinTypeUI(joinType)
end
function ClanEditClanInfoPanel:updateJoinTypeUI(_joinType)
    _joinType = _joinType or ClanConfig.joinLimitType.PUBLIC
    
    local spPublic = self:findChild("lb_public") -- 自由出入
    local spPrivate = self:findChild("lb_private") -- 需要申请
    spPublic:setVisible(_joinType == ClanConfig.joinLimitType.PUBLIC)
    spPrivate:setVisible(_joinType == ClanConfig.joinLimitType.REQUEST)

    self.m_editTeamInfo:setTeamJoinType(_joinType)
end

-- 加入公会 vip限制
function ClanEditClanInfoPanel:initJoinLimitVipLV()
    local vipLv = self.m_simpleInfo:getTeamMinVipLevel()
    if self.m_maxVipLevel == 1 then
        local btnPre = self:findChild("btn_vip1")
        local btnNext = self:findChild("btn_vip2")
        btnPre:setEnabled(false)
        btnNext:setEnabled(false)
    end
    self:updateJoinLimitVipLV(vipLv)
end
function ClanEditClanInfoPanel:updateJoinLimitVipLV(_vipLv)
    _vipLv = _vipLv or 1

    local spVip = self:findChild("sp_vip")
    local vipImgPath = VipConfig.logo_shop .. _vipLv .. ".png"
    util_changeTexture(spVip, vipImgPath)
    local spVipDesc = self:findChild("sp_vip_desc")
    local vipDescImgPath = VipConfig.name_big .. _vipLv .. ".png"
    util_changeTexture(spVipDesc, vipDescImgPath)

    util_alignCenter(
        {
            {node = spVip},
            {node = spVipDesc, scale = 0.6, alignX = 5}
        }
    )
    self.m_editTeamInfo:setTeamMinVipLevel(_vipLv)
end

-- 点击事件
function ClanEditClanInfoPanel:clickFunc(sender)
    local name = sender:getName()
    if name ~= "btn_close" and name ~= "btn_edit" and name ~= "btn_editName" and 
    name ~= "btn_save" and name ~= "btn_country1" and name ~= "btn_country2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_nextPage" then
        -- 显示第二页
        self:setPageVisible(2)
    elseif name == "btn_prePage" then
        -- 显示第一页
        self:setPageVisible(1)
    elseif name == "btn_save" then
        -- 保存公会信息
        self:saveClanInfo()
    elseif name == "btn_edit" then
        -- 显示 公会 logo 列表
        self:popChangeClanLogoPanel()
    elseif name == "btn_country1" and self.m_teamRegionView then
        self.m_teamRegionView:updateByType("country", self.m_editTeamInfo.country)
        -- 显示 国家 信息
    elseif name == "btn_country2" and self.m_teamRegionView then
        self.m_teamRegionView:updateByType(self.m_editTeamInfo.country, self.m_editTeamInfo.state)
        -- 显示 国家的地区 信息
    elseif name == "btn_tag" then
        -- 公会tag
        self:popChooseTagLayer()
    elseif name == "btn_type1" or name == "btn_type2" then
        -- 切换 加入公会类型
        local joinType = ClanConfig.joinLimitType.PUBLIC
        if self.m_editTeamInfo:getTeamJoinType() == joinType then
            joinType = ClanConfig.joinLimitType.REQUEST
        end
        self:updateJoinTypeUI(joinType)
    elseif name == "btn_vip1" then
        -- pre
        local vipLevel = self.m_editTeamInfo:getTeamMinVipLevel() - 1
        if vipLevel < 1 then
            vipLevel = self.m_maxVipLevel
        end
        self:updateJoinLimitVipLV(vipLevel)
    elseif name == "btn_vip2" then
        -- next
        local vipLevel = self.m_editTeamInfo:getTeamMinVipLevel() + 1
        if vipLevel > self.m_maxVipLevel then
            vipLevel = 1
        end
        self:updateJoinLimitVipLV(vipLevel)
    elseif name == "btn_editName" then
        -- 更改名字面板
        self:popChangeClanNamePanel()
    end
end

-- 更改公会名字成功 evt
function ClanEditClanInfoPanel:onEditClanNameSuccessEvt()
    local clanData = ClanManager:getClanData()
    local simpleInfo = clanData:getClanSimpleInfo()
    self:updateTeamName(simpleInfo:getTeamName())
end
-- 名字已存在 evt
function ClanEditClanInfoPanel:onEditClanNameExitEvt()
    if not self.m_bCreateClan then
        return
    end

    -- 这里应该有一个弹板
    ClanManager:popCommonTipPanel(
        ProtoConfig.ErrorTipEnum.CLAN_NAME_EXIT,
        function()
            if self.lb_namePlaceHolder:getString() == self.m_ranName then
                self.m_ranName = ClanManager:generateClanRandomName() --创建公会默认名字
                self.lb_namePlaceHolder:setString(self.m_ranName)
                util_scaleCoinLabGameLayerFromBgWidth(self.lb_namePlaceHolder, 440, self.lb_namePlaceHolder:getScale())
            end
        end
    )
end

-- 更新选择国家地区UIEvt
-- _params = {_type, _data}
function ClanEditClanInfoPanel:onChangeRegoinEvt(_params)
    local type = _params[1]
    local data = _params[2]
    local state = data
    if type == "country" then
        if self.m_editTeamInfo.country == data then
            return 
        else
            self.m_editTeamInfo.country = data
            state = ClanManager:getStdCountryData(data)[1] or ""
        end
    end

    self:updateRegionUI(self.m_editTeamInfo.country, state)
end

function ClanEditClanInfoPanel:onShowPage2Evt()
    self:setPageVisible(2)
end 

-- 注册弹板事件
function ClanEditClanInfoPanel:registerListener()
    ClanEditClanInfoPanel.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_NEW_CLAN_INFO_SUCCESS)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_CLAN_CREATE_SUCCESS)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_USER_LEAVE_CLAN)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)

    gLobalNoticManager:addObserver(self, "onEditClanNameSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_CHAGE_CLAN_NAME)
    gLobalNoticManager:addObserver(self, "onEditClanNameExitEvt", ClanConfig.EVENT_NAME.ERROR_CLAN_NAME_ERROR)
    gLobalNoticManager:addObserver(self, "updateTeamLogo", ClanConfig.EVENT_NAME.SAVE_SELECT_CLAN_LOGO)
    gLobalNoticManager:addObserver(self, "onChangeRegoinEvt", ClanConfig.EVENT_NAME.UPDATE_CHOOSE_REGION_UI)
    gLobalNoticManager:addObserver(self, "onShowPage2Evt", ClanConfig.EVENT_NAME.NOTIFY_TEAM_EDIT_SHOW_NEXT_PAGE) --引导显示第二页
end

-- 公会名字输入框事件
function ClanEditClanInfoPanel:onNameEdit(event)
    if event.name == "began" then
        self.lb_namePlaceHolder:setVisible(false)
    elseif event.name == "changed" then
        -- 改变字数
        self:updateTeamName()
    elseif event.name == "return" then
        self:updateTeamName()
    end
end

-- 公会描述输入框事件
function ClanEditClanInfoPanel:onDescEdit(event)
    local sender = event.target
    if event.name == "began" then
        self.lb_descPlaceHolder:setVisible(false)
    elseif event.name == "changed" then
        -- 改变字数
        local newDesc = sender:getText()
        self:updateClanDesc(newDesc)
    elseif event.name == "return" then
        local newDesc = sender:getText()
        newDesc = SensitiveWordParser:getString(newDesc)
        self:updateClanDesc(newDesc)
    end
end

-- 组织 公会数据
function ClanEditClanInfoPanel:dealClanEditData()
    ClanManager:clearEditCache()

    -- name
    local name = self.text_name:getText()
    if #name <= 0 then
        if self.m_bCreateClan then
            name = self.m_ranName -- 使用默认名字
        else
            ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.USER_NAME_EMPTY)
            return false
        end
    end
    ClanManager:editClanName(name)
    -- desc
    local desc = self.text_desc:getText()
    if #desc <= 0 then
        if self.m_bCreateClan then
            desc = self.m_defaultDescPlaceH
        else
            ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.USER_DESC_EMPTY)
            return false
        end
    end
    ClanManager:editClanDescription(desc)
    
    -- 公会logo
    ClanManager:editClanLogo(self.m_editTeamInfo:getTeamLogo())
    -- 加入 限制类型
    ClanManager:editClanJoinLimitType(self.m_editTeamInfo:getTeamJoinType())
    -- 加入 最低vip等级
    ClanManager:editClanMinVipLevel(self.m_editTeamInfo:getTeamMinVipLevel())
    -- 工会所属国家地区
    ClanManager:editClanRegionInfo(self.m_editTeamInfo:getTeamCountryArea())
    -- 工会标签
    ClanManager:editClanTagInfo(self.m_editTeamInfo:getTeamTag())

    return true
end

-- 保存公会信息
function ClanEditClanInfoPanel:saveClanInfo()
    local bContinue = self:dealClanEditData()
    if not bContinue then
        return
    end

    if self.m_bCreateClan then
        ClanManager:sendClanCreate()
    else
        ClanManager:sendClanInfoEdit()
    end
end

-- 界面page页面显隐
function ClanEditClanInfoPanel:setPageVisible(_curPage)
    local nodePage1 = self:findChild("node_page1")
    local nodePage2 = self:findChild("node_page2")

    nodePage1:setVisible(_curPage == 1)
    nodePage2:setVisible(_curPage == 2)
end

-- 公会tag
function ClanEditClanInfoPanel:popChooseTagLayer()
    local hadChooseTagStr = self.m_editTeamInfo:getTeamTag()
    local list = {}
    if #hadChooseTagStr > 0 then
        list = string.split(hadChooseTagStr, "|")
    end
    local view = ClanManager:popChooseTagLayer(list)
    if view then
        view:setUpdateTagListFunc(util_node_handler(self, self.updateTeamTag))
    end
end

-- 显示 改变公会logo 面板
function ClanEditClanInfoPanel:popChangeClanLogoPanel()
    local view = util_createView("views.clan.baseInfo.ClanChangeLogoPanel", self.m_editTeamInfo:getTeamLogo())
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_UI)
end
-- 显示 改变公会名字 面板
function ClanEditClanInfoPanel:popChangeClanNamePanel()
    local view = util_createView("views.clan.baseInfo.ClanEditClanNamePanel")
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_UI)
end

function ClanEditClanInfoPanel:closeUI()
    if self.m_teamRegionView then
        self.m_teamRegionView:hide()
    end
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLAN_GUIDE_LAYER) -- 关闭引导界面事件
    ClanEditClanInfoPanel.super.closeUI(self)
end

function ClanEditClanInfoPanel:onShowedCallFunc()
    ClanEditClanInfoPanel.super.onShowedCallFunc(self)

    if not self.m_bCreateClan then
        self:dealGuideLogic()
    else
        globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel) -- 老公会才需要看新版修改公会信息界面
    end
end

-- 处理 引导逻辑
function ClanEditClanInfoPanel:dealGuideLogic()
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel.id) -- 老公会才需要看新版修改公会信息界面
    if bFinish then
        return
    end
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel) -- 老公会才需要看新版修改公会信息界面
    local nodeRegion = self:findChild("node_region") -- 公会基本信息按钮
    local btnNextPage = self:findChild("btn_nextPage") -- 下一页按钮
    local nodeTagStyle = self:findChild("node_tagStyle") -- 公会tag按钮
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel.id, {nodeRegion, btnNextPage, nodeTagStyle})
end

return ClanEditClanInfoPanel