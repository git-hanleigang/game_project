--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-08 10:43:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-08 10:52:40
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftChooseMemberLayer.lua
Description: 公会红包  选择赠送成员 弹板
--]]
local ClanRedGiftChooseMemberLayer = class("ClanRedGiftChooseMemberLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRedGiftChooseMemberLayer:initDatas(_giftData)
    self.m_giftData = _giftData

    local clanData = ClanManager:getClanData() 
    local allMemberList = clanData:getClanMemberList()
    self.m_memberDataList = {}
    self.m_memberUIList = {}
    for _, memberData in pairs(allMemberList) do
        local bMe = memberData:checkIsBMe()
        if not bMe then
            table.insert(self.m_memberDataList, memberData)
        end
    end

    -- 重置 选择用户的列表
    ClanManager:resetGiftChooseUserList()

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Gift/Gift_choose_member_layer.csb")
    self:setExtendData("ClanRedGiftChooseMemberLayer")
end

function ClanRedGiftChooseMemberLayer:initView()
    -- listview 成员列表
    self:initMemberListView()
    -- 按钮 价格
    self:initBtnLb()
    -- 选择all 状态UI
    self:updateSelAllState()
    -- 支付按钮 触摸状态
    self:updateBuyBtnState()
end

-- listview 成员列表
function ClanRedGiftChooseMemberLayer:initMemberListView()
    local listView = self:findChild("ListView_member")
    listView:removeAllItems()
	listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    self.m_listViewSize = listView:getContentSize()

    local count = math.ceil(#self.m_memberDataList * 0.5)
    for i=1, count do
        local layout = self:createMemberLayout(i)
        listView:pushBackCustomItem(layout)
    end
end
function ClanRedGiftChooseMemberLayer:createMemberLayout(_idx)
    local layout = ccui.Layout:create()
    layout:setTouchEnabled(false)
    local cellSize = cc.size(426, 106)
    local spaceX = self.m_listViewSize.width - cellSize.width * 2
    for i=1,2 do
        local memberIdx = (_idx-1) * 2 + i
        local memberData = self.m_memberDataList[memberIdx]
        if memberData then
            local memberCell = util_createView("views.clan.redGift.ClanRedGiftChooseMemberCell", memberData)
            memberCell:move(cellSize.width*(i-0.5) + (i-1)*spaceX, cellSize.height*0.5)
            layout:addChild(memberCell)
            self.m_memberUIList[memberData:getUdid()] = memberCell
        end
    end

    layout:setContentSize(cc.size(self.m_listViewSize.width, cellSize.height))
    return layout
end

-- 按钮 价格
function ClanRedGiftChooseMemberLayer:initBtnLb()
    local LanguageKey = "ClanRedGiftChooseMemberLayer:btn_buy"
    local labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "$ "
    local price = self.m_giftData:getPrice()
    self:setButtonLabelContent("btn_buy", labelString .. price)
end

-- 选择all 状态UI
function ClanRedGiftChooseMemberLayer:updateSelAllState()
    local chooseList = ClanManager:getGiftChooseUserList()
    local spUnSel = self:findChild("sp_unSel")
    local spSel = self:findChild("sp_sel")

    spSel:setVisible(#chooseList == #self.m_memberDataList and #self.m_memberDataList ~= 0)
    spUnSel:setVisible(#chooseList ~= #self.m_memberDataList or #self.m_memberDataList == 0)
end

-- 支付按钮 触摸状态
function ClanRedGiftChooseMemberLayer:updateBuyBtnState()
    local btnBuy = self:findChild("btn_buy")
    local chooseList = ClanManager:getGiftChooseUserList()
    self:setButtonLabelDisEnabled("btn_buy", #chooseList > 0)
end

function ClanRedGiftChooseMemberLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_return" then
        self:closeUI(function()
            ClanManager:popSendGiftLayer()
        end)
    elseif name == "btn_buy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        ClanManager:goPurchase(self.m_giftData)
    elseif name == "btn_bp" then
        -- 显示付费权益界面
        ClanManager:showPayBenefitLayer(self.m_giftData)
    elseif name == "btn_selAll" and #self.m_memberDataList > 0 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:tapSelAllBtn()
    end
end

-- 点击 all 更新状态
function ClanRedGiftChooseMemberLayer:tapSelAllBtn()
    local chooseList = ClanManager:getGiftChooseUserList()
    ClanManager:resetGiftChooseUserList() 
    if #chooseList ~= #self.m_memberDataList then
        for _, memberData in pairs(self.m_memberDataList) do
            ClanManager:addGiftChooseUser(memberData:getUdid())
        end
    end
    self:updateMemberCellUISelState()
    self:updateSelAllState()
    self:updateBuyBtnState()
end
-- 更新成员选择状态
function ClanRedGiftChooseMemberLayer:updateMemberCellUISelState()
    for _,  memberCell in pairs(self.m_memberUIList) do
        memberCell:updateSelState()
    end
end

return ClanRedGiftChooseMemberLayer