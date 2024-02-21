--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{dhs}
    time:2021-11-17 16:24:29
]]

local LotteryFAQPanel = class("LotteryFAQPanel",BaseLayer)
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")

local faqItemList = {
    {
		title = "1. When and how does the Lottery draw take place?",
		desc = "The Lottery draw takes place every Wednesday and Saturday at approximately 00:00 PST. You may log in anytime after that to watch the drawing.",
	},
	{
		title = "2. How do I get the Lottery tickets?",
		desc = "One Lottery ticket in the Daily Bonus;\nOne Lottery ticket in the first Season Mission every day;\nStay tuned for more...",
	},
	{
		title = "3. When and how do I select my Lottery numbers?",
		desc = "The access will shut down about 30 mins before the draw takes place.You must select 5 numbers between 1 and 30 plus an additional Bonus Number from a choice of 9 to play the Lottery.",
	},
	{
		title = "4. If I win, how do I claim a prize?",
		desc = "You can redeem a winning ticket and claim the prize after watching the drawing.",
	},
	{
		title = "5. What if I forgot to select numbers?",
		desc = "The access will shut down about 30 mins before the draw takes place. All the blank tickets will be issued to your Inbox and kept for the next Lottery drawing.",
	},
	{
		title = "6. What’s the expected value of the Grand Prize?",
		desc = "Coin values of all prizes are converted at the exchange rate against US dollars in the Coin Store. There will be a base amount in the Jackpot Pool for each draw, and it grows with more players involved. The Grand Prize will be partly saved to the pool of the next draw if there are no winners of it.",
	}
}

function LotteryFAQPanel:ctor()
    LotteryFAQPanel.super.ctor(self)

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Lottery/csd/Lottery_FAQ_layer.csb")
    --定义变量
    self.m_nodeList = {}
end

function LotteryFAQPanel:initCsbNodes()
    --self.m_btnClose = self:findChild("btn_close")
    self.m_listView = self:findChild("ListView_FAQ")
end

function LotteryFAQPanel:initView()
    --处理listView(初始化刷新)
    self.m_listView:setScrollBarEnabled(false)

    for i = 1, #faqItemList do

        local itemInfo = faqItemList[i]

        local view = util_createView("views.lottery.other.LotteryFAQCell", i, itemInfo)
        view:setName("FAQInfoCell")
        
        local layout = ccui.Layout:create()
        layout:setTouchEnabled(false)
        local cellSize = view:getCurCellSize()
        view:setPositionY(cellSize.height)
        layout:setContentSize(cellSize)
        layout:addChild(view)
        
        self.m_nodeList[i] = {}
        self.m_nodeList[i].layout = layout
        self.m_nodeList[i].state = false

        --将layout添加到listview
        self.m_listView:pushBackCustomItem(layout)
    end

end

function LotteryFAQPanel:registerListener()
    LotteryFAQPanel.super.registerListener(self)

    --注册事件监听
    gLobalNoticManager:addObserver(self, "updateListView", LotteryConfig.EVENT_NAME.UPDATE_FAQ_LISTVIEW)
end

--刷新当前listview中cell信息
function LotteryFAQPanel:updateListView(_index)

    for i = 1, #self.m_nodeList do
        local state = self.m_nodeList[i].state
        local layout = self.m_nodeList[i].layout
        if state and i ~= _index then
           local view = layout:getChildByName("FAQInfoCell")
           view:hideCell()

           local cellSize = view:getCurCellSize()
           view:setPositionY(cellSize.height)
           layout:setContentSize(cellSize)

           self.m_nodeList[i].state = false

        end
    end

    --刷新当前cell
    local layout = self.m_nodeList[_index].layout
    local view = layout:getChildByName("FAQInfoCell")
    local cellSize = view:getCurCellSize()
    view:setPositionY(cellSize.height)
    layout:setContentSize(cellSize)
    self.m_nodeList[_index].state = true

    --重新刷新listview布局
    self.m_listView:requestDoLayout()
end

function LotteryFAQPanel:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function LotteryFAQPanel:closeUI()
    LotteryFAQPanel.super.closeUI(
    self,
    function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end
)

end

return LotteryFAQPanel
