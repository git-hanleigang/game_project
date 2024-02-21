--[[
Author: cxc
Date: 2022-02-24 14:11:51
LastEditTime: 2022-02-24 14:12:55
LastEditors: cxc
Description: 公会排行榜权益
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankBenefitLayer.lua
--]]
local ClanRankBenefitLayer = class("ClanRankBenefitLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRankBenefitLayer:ctor()
    ClanRankBenefitLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true) 

    self.m_bubbleObjList = {}
    self:setKeyBackEnabled(true)
    self:setExtendData("ClanRankBenefitLayer")
    self:setLandscapeCsbName("Club/csd/RANK/Rank_benefit.csb")
end

function ClanRankBenefitLayer:initDatas(_benifitList)
    self.m_benifitList = _benifitList
end

function ClanRankBenefitLayer:initCsbNodes()
    self.m_layoutTouch = self:findChild("layout_touch")
    self.m_layoutTouch:setSwallowTouches(true)
    self:addClick(self.m_layoutTouch)
    self.m_layoutTouch:setVisible(false)
end

function ClanRankBenefitLayer:initView()
    -- 气泡
    self:initBubbleUI()
    
    -- 权益
    self:updateRewardListUI()
end

-- 气泡
function ClanRankBenefitLayer:initBubbleUI()
    self.m_bubbleObjList = {}
    for idx=1, 4 do
        local parent = self:findChild("Node_lb" .. idx)
        local view = util_createView("views.clan.rank.ClanRankBenefitBubble", idx)
        parent:addChild(view)
        view:setVisible(false)
        table.insert(self.m_bubbleObjList, view)
    end
end

-- 权益
function ClanRankBenefitLayer:updateRewardListUI()
    local listView = self:findChild("ListView")
    listView:removeAllItems()
	listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)

    local clanData = ClanManager:getClanData()
    local selfDivision = clanData:getSelfClanRankInfo().division
    for i=1, #self.m_benifitList do
        local benifitData = self.m_benifitList[i]
        local division = benifitData:getDivision()
        local layout = self:createCellUI(benifitData, selfDivision == division)
        listView:pushBackCustomItem(layout)
    end 
    listView:jumpToBottom() 
end

-- 权益cell
function ClanRankBenefitLayer:createCellUI(_benifitData, _bMe)
    local layout = ccui.Layout:create()
    layout:setTouchEnabled(false)
    local view = util_createView("views.clan.rank.ClanRankBenefitCellUI", _benifitData, _bMe)
    local cellSize = view:getContentSize()
    layout:addChild(view)
    layout:setContentSize(cellSize)
    view:move(cellSize.width * 0.5, cellSize.height * 0.5)
    -- layout:setBackGroundColorOpacity(200)
	-- layout:setBackGroundColorType(2)
	-- layout:setBackGroundColor(cc.c3b(0,255,0))

    return layout
end

-- 切换气泡显隐
function ClanRankBenefitLayer:switchBubbleVisible(_idx)
    if not _idx then
        return
    end

    local nodeBubble = self.m_bubbleObjList[_idx]
    if not nodeBubble then
        return
    end

    nodeBubble:stopAllActions()
    local bVisible = nodeBubble:isVisible()
    nodeBubble:switchBubbleVisible()
    self.m_layoutTouch:setVisible(not bVisible)
    if not bVisible then
        self.m_showIdx = _idx
        performWithDelay(nodeBubble, function()
            self:switchBubbleVisible(self.m_showIdx)
            self.m_showIdx = nil
        end, 4)
    else
        self.m_showIdx = nil
    end
end

function ClanRankBenefitLayer:hideBubble()
    if not self.m_showIdx then
        return
    end

    self:switchBubbleVisible(self.m_showIdx)
end

function ClanRankBenefitLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_baox" then
        self:switchBubbleVisible(1)
    elseif name == "btn_coins" then
        self:switchBubbleVisible(2)
    elseif name == "btn_chips" then
        self:switchBubbleVisible(3)
    elseif name == "btn_gems" then
        self:switchBubbleVisible(4)
    elseif name == "layout_touch" then
        self:hideBubble()
    end
end

function ClanRankBenefitLayer:onRecieveBeniftEvt()
    local benifitList = ClanManager:getClanBenifitList() 
    if not benifitList or #benifitList <= 0 then
        return
    end
    self.m_benifitList = benifitList
    self:updateRewardListUI()
end

function ClanRankBenefitLayer:registerListener()
    ClanRankBenefitLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onRecieveBeniftEvt", ClanConfig.EVENT_NAME.RECIEVE_TEAM_BENIFIT_SUCCESS) -- 接收到公会权益信息
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM) -- 玩家被踢了
end

function ClanRankBenefitLayer:onShowedCallFunc()
    self:dealGuideLogic()
end

-- 处理 引导逻辑
function ClanRankBenefitLayer:dealGuideLogic()
    if tolua.isnull(self) then
        return
    end
    
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterRankBenifit.id) -- 第一次进入公会主页
    if bFinish then
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterRankBenifit)

    local node = self:findChild("Node_middle") -- 权益
    local guideNodeList = {node}
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstEnterRankBenifit.id, guideNodeList)
end

function ClanRankBenefitLayer:closeUI(_cb)
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLAN_GUIDE_LAYER) -- 关闭引导界面事件 
    ClanRankBenefitLayer.super.closeUI(self, _cb)
end

return ClanRankBenefitLayer