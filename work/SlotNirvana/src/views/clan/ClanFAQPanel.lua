--[[
Author: cxc
Date: 2021-03-04 17:57:15
LastEditTime: 2021-03-08 18:08:05
LastEditors: Please set LastEditors
Description: FAQ 面板
FilePath: /SlotNirvana/src/views/clan/ClanFAQPanel.lua
--]]
local ClanFAQPanel = class("ClanFAQPanel", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")

local faqItemList = {
	{
		title = "1. What are Team Points?",
		desc = "Team points are points that each member can get through spins in any slot or daily tasks. The Team Points earned by members will be added together.",
	},
	{
		title = "2. What can Team Points do?",
		desc = "Before the weekly settlement, a key can be obtained if the Team earn enough points, and the key can be used to open the Treasure Chests for members.",
	},
	{
		title = "3. How to get the Treasure Chest?",
		desc = "A Member's contribution to Team Points decides the level of the Treasure Chest rewarded, according to the diferrent range of points. At the weekly settlement, the key will open the Treasure Chest for rewards.",
	},
	{
		title = "4. When will members get the Treasure Chests?",
		desc = "On Thursdays member will get the Treasure Chest. Members have to fight for your union to get the key before that, then it will be auto opened when you log in.",
	},
	{
		title = "5. How many Treasure Chests can a member get?",
		desc = "Only one every week, the one of the highest level according to your contribution.",
	},
	{
		title = "6. How do I collect the Chips from other members?",
		desc = "The Chips sent from other members will be in the FRIEND of INBOX to collect. A member can ask for Chips once a day, Green Chips only.",
	},
	{
		title = "7. How do I invite my friends to join a Team?",
		desc = "You can click the INVITE at the bottom of the MEMBER to invite your friends. You may choose one of the 2 ways. Post the link on Facebook, your Facebook friends can click the link to view your Team; Search for your friend's Name or UID in the game to invite.",
	},
	{
		title = "8. How can I modify the information of the Team?",
		desc = "On the Team homepage, tap the expand button at the bottom right of the Team's Avatar and Name, then tap Edit to modify the information. Only the Leader is authorized.",
	},
	{
		title = "9. How do I leave the Team?",
		desc = "On the Team homepage, click the expand button at the bottom right of the Team's Avatar and Name, then tap the Leave Team.",
	},
	{
		title = "10. How do I kick off other members?",
		desc = "In the member List, tap the member you want to kick off, then tap the Kick off. Only the Leader is authorized.",
	},
	{
		title = "11. What should I do if I have other questions?",
		desc = "You can resort to our customer services in Contact us.",
	}
}
function ClanFAQPanel:ctor()
    ClanFAQPanel.super.ctor(self)
    
    self.m_nodeList = {}
    self:setLandscapeCsbName("Club/csd/Faq/ClubFAQLayer.csb")
    self:setKeyBackEnabled(true) 
end

function ClanFAQPanel:initUI(_params)
    ClanFAQPanel.super.initUI(self)
    
    local listView = self:findChild("ListView_list")
    listView:setScrollBarEnabled(false)
    for i = 1, #faqItemList do
        local itemInfo = faqItemList[i]
        local view = util_createView("views.clan.ClanFAQInfoCell", i, itemInfo)
        view:setName("FAQInfoCell")
        local layout = ccui.Layout:create()
        layout:setTouchEnabled(false)
        local cellSize = view:getCurCellSize()
        view:setPositionY(cellSize.height)
        layout:setContentSize(cellSize)
        layout:addChild(view)

        self.m_nodeList[i] = layout
        listView:pushBackCustomItem(layout)
    end
    listView:onScroll(function(data)
            -- if data.name == "SCROLLING" then
            if data.name == "CONTAINER_MOVED" then
                self.m_moveSlider = false
                if self.m_moveTable == true then
                    local percent = self.m_listView:getScrolledPercentVertical() / 100
                    if percent == percent and self.m_slider ~= nil then
                        self.m_slider:setValue(percent)
                    end
                end
                self.m_moveSlider = true
            end
        end
    )
    -- 创建 slider滑动条 --
    local thumbFile = display.newSprite("#Club/ui_new/Tanban/FAQ/huakuai2.png")
    local bgFile = display.newSprite("#Club/ui_new/Tanban/FAQ/huakuai1.png")
    local progressFile = display.newSprite("#Club/ui_new/Tanban/FAQ/huakuai1.png")
    local markSize = thumbFile:getContentSize()
    local bgSize = bgFile:getContentSize()
    bgFile:setOpacity(0)
    progressFile:setOpacity(0)
    bgFile:setContentSize(cc.size(bgSize.width-markSize.width, bgSize.height))
    local percent = thumbFile:getContentSize().width / progressFile:getContentSize().width
    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:registerControlEventHandler(function()
        self.m_moveTable = false
        if self.m_moveSlider == true then
            local sliderOff = self.m_slider:getValue()
            self.m_listView:scrollToPercentVertical(sliderOff * 100, 1/60, false)
        end
        self.m_moveTable = true
    end, cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
    self.m_slider:setMinimumValue(0)
    self.m_slider:setMaximumValue(1)
    self.m_slider:setValue(percent)
    self:findChild("node_bar"):addChild(self.m_slider)

    -- -- 创建一个长背景条 保证滑块上下齐边 --
    local addBgNode = display.newSprite("#Club/ui_new/Tanban/FAQ/huakuai1.png")
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true

    self.m_listView = listView

    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
end

function ClanFAQPanel:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_close" then
        self:closeUI()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLNA_PANEL_UI, "ClanFAQPanel")
    end
end

function ClanFAQPanel:updateListViewEvt(_idx)
    local totalheight = self.m_listView:getInnerContainerSize().height - self.m_listView:getContentSize().height
    local oldPer = self.m_listView:getScrolledPercentVertical()
    local moveHeigth = totalheight * oldPer / 100

    local layout = self.m_nodeList[_idx]
    local view = layout:getChildByName("FAQInfoCell")
    local cellSize = view:getCurCellSize()
    view:setPositionY(cellSize.height)
    layout:setContentSize(cellSize)

    self.m_listView:requestDoLayout()
    local newHeight = self.m_listView:getInnerContainerSize().height - self.m_listView:getContentSize().height
    local newPer = moveHeigth * 100 / newHeight
    self.m_listView:jumpToPercentVertical(math.max(math.min(newPer, 100), 0))
end

-- 注册消息事件
function ClanFAQPanel:registerListener()
    ClanFAQPanel.super.registerListener(self)
    gLobalNoticManager:addObserver(self, "updateListViewEvt", ClanConfig.EVENT_NAME.UPDATE_FAQ_LISTVIEW)
end


return ClanFAQPanel