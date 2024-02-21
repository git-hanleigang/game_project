--[[
Author: cxc
Date: 2021-02-23 14:29:18
LastEditTime: 2021-07-26 11:46:22
LastEditors: Please set LastEditors
Description: 编辑公会名字 面板
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanEditClanNamePanel.lua
--]]
local ClanEditClanNamePanel = class("ClanEditClanNamePanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

function ClanEditClanNamePanel:ctor()
    ClanEditClanNamePanel.super.ctor(self)
    self:setLandscapeCsbName("Club/csd/Tanban/ClubNameChangeLayer.csb")
    self:setKeyBackEnabled(true)
    
    gLobalNoticManager:addObserver(self, "editClanNameSuccess", ClanConfig.EVENT_NAME.RECIEVE_CHAGE_CLAN_NAME)
    gLobalNoticManager:addObserver(self, "editClanNameFail", ClanConfig.EVENT_NAME.ERROR_CLAN_NAME_ERROR)
end

function ClanEditClanNamePanel:initUI()
    ClanEditClanNamePanel.super.initUI(self)
    
    local clanData = ClanManager:getClanData() 
    local simpleInfo = clanData:getClanSimpleInfo()

    -- 获取改名字消耗消耗第二货币数量
    self.m_updateNameGems = clanData:getUpdateNameGems() or 0

    -- local lbGems = self:findChild("font_gemnum")
    -- lbGems:setString(self.m_updateNameGems)
    local gems = tonumber(self.m_updateNameGems) or 0
    local str = "FREE"
    if gems > 0 then
        local LanguageKey = "ClanEditClanNamePanel:btn_gem"
        local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "%d"
        str = string.format(refStr, gems)
    end
    self:setButtonLabelContent("btn_gem", str)

    -- 提示 公会名字已存在
    local spTip = self:findChild("sp_redword")
    spTip:setVisible(false)

    -- 公会名字
    local textFieldName = self:findChild("TextField_1")
    local lbNamePlaceHolder = self:findChild("font_word1")
    self.m_eboxName = util_convertTextFiledToEditBox(textFieldName, nil, function(strEventName,pSender)
        if strEventName == "began" then
            lbNamePlaceHolder:setVisible(false)
            spTip:setVisible(false) 
        elseif strEventName == "changed" then
            self:refreshClanName() 
        elseif strEventName == "return" then
            self:refreshClanName()
        end
    end)
    local name = simpleInfo:getTeamName()
    self.m_sourceName = name
    self:refreshClanName(name)
end

-- 公会名字
function ClanEditClanNamePanel:refreshClanName(_name)
    _name = _name or self.m_eboxName:getText()
    local _name = SensitiveWordParser:getString(_name, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
    _name = string.gsub(_name, "[^%w]", "")

    local lbNamePlaceHolder = self:findChild("font_word1")
    self.m_eboxName:setText(_name)
    lbNamePlaceHolder:setVisible(#_name <= 0)

    -- local btnGem = self:findChild("btn_gem")
    -- btnGem:setEnabled(#_name > 0 and _name ~= self.m_sourceName)
    self:setButtonLabelDisEnabled("btn_gem", #_name > 0 and _name ~= self.m_sourceName)
    
    self:refreshLeftWordCountUI()
end

-- 刷新 剩余 文字提示ui
function ClanEditClanNamePanel:refreshLeftWordCountUI()
    local  lbLeftWord = self:findChild("font_word2")
    local name = self.m_eboxName:getText()
    local count = #name
    
    local leftCount  = ClanConfig.CLAN_NAME_LIMIT_SIZE - count
    lbLeftWord:setString(leftCount)
    self.m_eboxName:setText(name)
end

function ClanEditClanNamePanel:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_gem" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if not self:checkNameAndGemOk() then
            return
        end

        -- 更改 名字按钮
        ClanManager:clearEditCache()
        local name = self.m_eboxName:getText()
        ClanManager:editClanName(name)
        ClanManager:sendClanNameEdit()
    end
end

-- 编辑公会成功
function ClanEditClanNamePanel:editClanNameSuccess()
    self:closeUI()

    -- 同步宝石
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
end

-- 编辑公会失败
function ClanEditClanNamePanel:editClanNameFail()
    local spTip = self:findChild("sp_redword")
    spTip:setVisible(true) 
end

-- 检查输入的名字和宝石是否 ok
function ClanEditClanNamePanel:checkNameAndGemOk()
    -- name 
    local name = self.m_eboxName:getText()
    if #name <= 0 then
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.USER_NAME_EMPTY)
        return false
    end

    if name == self.m_sourceName then
        ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CLAN_NAME_EXIT)
        return false
    end

    -- 宝石
    local curGem = globalData.userRunData.gemNum or 0
    if curGem < self.m_updateNameGems then
        -- 去商城
        local params = {shopPageIndex = 2 , dotKeyType = "btn_buy", dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
        local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
        view.buyShop = true
        return false
    end

    return true
end

return ClanEditClanNamePanel