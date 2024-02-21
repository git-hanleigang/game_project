--[[
Author: cxc
Date: 2021-02-20 18:02:40
LastEditTime: 2021-03-19 15:10:55
LastEditors: Please set LastEditors
Description: 搜索到的 公会列表
FilePath: /SlotNirvana/src/views/clan/recurit/ClanSearchClanCell.lua
--]]
local ClanSearchClanCell = class("ClanSearchClanCell", util_require("base.BaseView"))
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanSearchClanCell:initUI()
    local csbName = "Club/csd/Browse/ClubBrowseTeamList.csb"
    self:createCsbNode(csbName)

    local btnClick = self:findChild("btn_click")
    btnClick:setSwallowTouches(false)
end

function ClanSearchClanCell:updateUI(_searchClanInfo)
    self.m_searchClanInfo = _searchClanInfo

    -- 公会logo
    local spClanIconBg = self:findChild("sp_clanBg")
    local spClanLogo = self:findChild("sp_clanLogo")
    local teamLogo = _searchClanInfo:getTeamLogo()
    local imgBgPath = ClanManager:getClanLogoBgImgPath(teamLogo)
    local imgPath = ClanManager:getClanLogoImgPath(teamLogo)
    util_changeTexture(spClanIconBg, imgBgPath)
    util_changeTexture(spClanLogo, imgPath)

    -- 公会 name
    local layoutName = self:findChild("layout_name")
    local lbClanName = self:findChild("font_name")
    local teamName = _searchClanInfo:getTeamName()
    lbClanName:setString(teamName)
    -- util_scaleCoinLabGameLayerFromBgWidth(lbClanName, 220, 0.8)
    local ricTextName = self:createRichText(teamName, lbClanName)
    local layoutNameSize = layoutName:getContentSize()
    local lbClanNameSize = lbClanName:getContentSize()
    local swingLb = lbClanName
    if ricTextName then
        swingLb = ricTextName
        ricTextName:stopAllActions()
        ricTextName:setPositionX(0)
    end
    if layoutNameSize.width < (lbClanNameSize.width * lbClanName:getScale()) then
        util_wordSwing(swingLb, 1, layoutName, 3, 30, 3, lbClanNameSize)
    else
        lbClanName:stopAllActions()
        lbClanName:setPositionX(0)
    end

    -- 国家地区
    local lbCountry = self:findChild("lb_country")
    local region = _searchClanInfo:getTeamCountryArea()
    local country = string.split(region, "|")[1] or "USA"
    local state = string.split(region, "|")[2] or ""
    if country == "" then
        country = "USA"
    end
    if state == "" then
        lbCountry:setString(country)
    else
        lbCountry:setString(state .. " " .. country)
    end
    util_scaleCoinLabGameLayerFromBgWidth(lbCountry, 140, 1)

    -- 公会type
    local tag = _searchClanInfo:getTeamTag()
    local tagList = string.split(tag, "|")
    local nodeTag = self:findChild("node_type")
    nodeTag:removeAllChildren()
    local alignUIList = {}
    local tagStr = ""
    for i=1, #tagList do
        local spTag = ClanManager:createTagSprite(tagList[i])
        nodeTag:addChild(spTag)
        table.insert(alignUIList, {node = spTag, alignX = 5})
    end
    util_alignCenter(alignUIList)


    -- 公会人数
    local cur = _searchClanInfo:getCurMemberCount()
    local max = _searchClanInfo:getLimitMemberCount()
    local lbMember = self:findChild("font_renshu")
    lbMember:setString(cur .. "/" .. max)

    -- 公会加入限制vip
    local spVipLimit = self:findChild("sp_viplogo")
    local vipLevel = _searchClanInfo:getTeamMinVipLevel()
    local vipImgPath = VipConfig.logo_shop .. vipLevel .. ".png"
    util_changeTexture(spVipLimit, vipImgPath)
end

-- 排行段位
function ClanSearchClanCell:initRankUI(_division)
    local spRankIcon = self:findChild("sp_rank")
    local path = ClanManager:getRankDivisionIconPath(_division)
    util_changeTexture(spRankIcon, path)
end

function ClanSearchClanCell:popBaseInfoPanel()
    ClanManager:popClanBaseInfoPanel(self.m_searchClanInfo)
end

-- 创建富文本
function ClanSearchClanCell:createRichText(_handleStr, _refNode)
    local filterStr = ClanManager:getCurClanSearchStr()

    return ClanManager:createSearchRichText(_handleStr, _refNode, filterStr)
end

return ClanSearchClanCell
