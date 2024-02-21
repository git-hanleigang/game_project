--[[
    --新版每日任务主界面  左侧节点界面
]]
local DailyMissionMainTopNodeView = class("DailyMissionMainTopNodeView", BaseView)

local PAGE_TYPE = {
    MISSION_PAGE = 1,
    REWARD_PAGE = 2,
    FLOWER_PAGE = 3
}

function DailyMissionMainTopNodeView:initDatas(data)
    self.m_isPortrait = data.isPortrait
    self.m_currPageType = data.currPageTy
end

function DailyMissionMainTopNodeView:initUI()
    self:createCsbNode(self:getCsbName())
    self:initCsbNodes()
    self:initView()
    self:changePage(self.m_currPageType)
end

function DailyMissionMainTopNodeView:getCsbName()
    if self.m_isPortrait then
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_TopUi_Vertical.csb"
    else
        return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_TopUi.csb"
    end
end

function DailyMissionMainTopNodeView:initCsbNodes()
    self.m_node_DailyMission = self:findChild("node_DailyMission")
    self.m_node_pass = self:findChild("node_Pass")
    
    self.m_nodePromotion = self:findChild("node_Promotion") -- 促销节点
    self.m_nodeSeasonProgress = self:findChild("node_progress") -- season 进度节点
end

function DailyMissionMainTopNodeView:initView()
    self:runCsbAction("idle", true, nil, 60)
    self:initGemsSaleNode()
    self:initSeasonProgressNode()
    self:initPassNode()
end

function DailyMissionMainTopNodeView:changePage(PageType)
    self.m_node_DailyMission:setVisible(PageType ==PAGE_TYPE.MISSION_PAGE or PageType ==PAGE_TYPE.FLOWER_PAGE)
    self.m_node_pass:setVisible( PageType ==PAGE_TYPE.REWARD_PAGE)
end

function DailyMissionMainTopNodeView:refreshView()
    if not self.m_nodePromotion then
        self:initGemsSaleNode()
    end
    if not self.m_seasonProgressNode then
        self:initSeasonProgressNode()
    end

    if not self.m_passTitleNode then
        self:initPassNode()
    end

    if self.m_passTitleNode then
        self.m_passTitleNode:refreshView()
    end
end

function DailyMissionMainTopNodeView:initGemsSaleNode()
    -- 添加促销
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        local goodInfo = actData:getPayGemsSaleInfo()
        if goodInfo:isInitData() then
            local saleIcon = util_createView("views.baseDailyMissionCode.pass_Promotion.DailyMissionPassPromotionNode")
            self.m_nodePromotion:addChild(saleIcon)
            self.m_gemSaleIcon = saleIcon
        end
    end
end

function DailyMissionMainTopNodeView:initSeasonProgressNode()
    -- 添加进度节点
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        local progressNode = util_createView("views.baseDailyMissionCode.DailyMissionPassSeasonProgressNode")
        self.m_nodeSeasonProgress:addChild(progressNode)
        self.m_seasonProgressNode = progressNode
    end
end

function DailyMissionMainTopNodeView:initPassNode()
    -- 添加顶部 pass Title
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        local passTitleNode = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_RewardTopUi_ThreeLine ,self.m_isPortrait)
        self.m_node_pass:addChild(passTitleNode)
        self.m_passTitleNode = passTitleNode
    end
end
function DailyMissionMainTopNodeView:updatePassTopView()
    if self.m_passTitleNode then
        self.m_passTitleNode:updateView()
    end
end

function DailyMissionMainTopNodeView:updateGemSaleNode()
    if self.m_gemSaleIcon then
        self.m_gemSaleIcon:updateView()
    end
end

function DailyMissionMainTopNodeView:updateProgressNode(_params)
    if not self.m_seasonProgressNode then
        return
    end
    -- 更新左上角进度条长度数值
    if _params and _params.addExp then
        local addExp = _params.addExp
        self.m_seasonProgressNode:updateExpPro(addExp)
    end

    if _params.nextSafeBox then
        self.m_seasonProgressNode:resetExpPro()
    end
end

function DailyMissionMainTopNodeView:getMedalEndPos()
    if not self.m_seasonProgressNode then
        return
    end

    local x,y= self.m_nodeSeasonProgress:getPosition()
    local worldPos = self:getParent():convertToWorldSpace(cc.p(x -100,y))
    return worldPos
end

function DailyMissionMainTopNodeView:afterPassOver()
    self.m_node_pass:removeAllChildren()
    self.m_passTitleNode = nil

    self.m_nodeSeasonProgress:removeAllChildren()
    self.m_seasonProgressNode = nil

    self.m_nodePromotion:removeAllChildren()
    self.m_gemSaleIcon = nil
end

function DailyMissionMainTopNodeView:getPassTopView()
   return self.m_passTitleNode
end

return DailyMissionMainTopNodeView
