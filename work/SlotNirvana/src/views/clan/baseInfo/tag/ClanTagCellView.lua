--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-26 14:51:00
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-26 14:51:34
FilePath: /SlotNirvana/src/views/clan/baseInfo/tag/ClanTagCellView.lua
Description: 公会 标签选择  单个tagView
--]]
local ClanTagCellView = class("ClanTagCellView", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanTagCellView:getCsbName()
    return "Club/csd/ClubEstablish/Club_ChoiceStyle.csb"
end

function ClanTagCellView:initDatas(_tagIdx, _mainLayer)
    ClanTagCellView.super.initDatas(self)

    self.m_tagIdx = _tagIdx
    self.m_mainLayer = _mainLayer
end

function ClanTagCellView:initUI()
    ClanTagCellView.super.initUI(self)

    -- icon
    self:initTagIconUI()
    -- tag name
    self:initTagNameUI()
    -- 是否勾选标签显隐
    self:updateSelVisible()
end

-- icon
function ClanTagCellView:initTagIconUI()
    local spIcon = self:findChild("sp_icon")
    local imgPath = ClanManager:getTagImgPath(self.m_tagIdx)
    util_changeTexture(spIcon, imgPath)
end
-- tag name
function ClanTagCellView:initTagNameUI()
    local layoutName = self:findChild("layout_style")
    local lbName = self:findChild("lb_style")
    local name = ClanManager:getStdTagName(self.m_tagIdx)
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end
-- 是否勾选标签显隐
function ClanTagCellView:updateSelVisible()
    local spSel = self:findChild("sp_duihao")
    local spSelBg = self:findChild("sp_bg_2")
    local bSel = self.m_mainLayer:checkHadSelect(self.m_tagIdx)
    spSel:setVisible(bSel)
    spSelBg:setVisible(bSel)
    self.m_bSelect = bSel
end

function ClanTagCellView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_choose" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updateChooseState()
    end
end

-- 更新 tag 选择状态
function ClanTagCellView:updateChooseState()
    if not self.m_bSelect then
        local bTagFull = self.m_mainLayer:checkTagListFull()
        if bTagFull then
            -- 满了删除第一个
            self.m_mainLayer:removeFirstTag()
            -- return
        end

        self.m_mainLayer:addNewTag(self.m_tagIdx)
    else
        self.m_mainLayer:removeTag(self.m_tagIdx)
    end
    
    self:updateSelVisible()
end

return ClanTagCellView