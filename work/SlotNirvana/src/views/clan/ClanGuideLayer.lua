--[[
Author: cxc
Date: 2021-03-01 10:55:47
LastEditTime: 2021-03-18 18:29:28
LastEditors: Please set LastEditors
Description: 公会的引导
FilePath: /SlotNirvana/src/views/clan/ClanGuideLayer.lua
--]]

local ClanGuideLayer = class("ClanGuideLayer", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

-- clanFirstEnterMain = {id = 400 preId=999}, -- 第一次进入公会主页
-- clanFirstEnterChat = {id = 401, preId=999}, -- 第一次看见公会聊天
-- clanFirstEnterMember = {id = 402, preId=999}, -- 第一次进入公会成员列表
-- clanFirstEnterRank = {id = 403, preId=999}, -- 第一次进入公会成员列表
-- clanFirstEnterRankBenifit = {id = 404, preId=999}, -- 第一次进入公会排行界权益界面
function ClanGuideLayer:ctor()
    ClanGuideLayer.super.ctor(self)

    local guideStepList = {}
    guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterMain.id] = {
        {tipPos = cc.p(-110, -40), npcPos = cc.p(90,-270), npcScaleX = -1},
        {tipPos = cc.p(110, 0), npcPos = cc.p(290,-220), npcScaleX = -1},
        {tipPos = cc.p(220, -40), npcPos = cc.p(410,-280), npcScaleX = -1},
        {tipPos = cc.p(-210, 100), npcPos = cc.p(-470,-150), npcScaleX = 1, callFunc = function()
            -- -- 弹出 开启宝箱时间变化提示弹板
            -- ClanManager:popOpenTimeChangeLayer()
            -- 检查 公会rush 新手引导
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.NOTIFY_RUSH_DEAL_GUIDE)
        end}
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterChat.id] = {
        {tipPos = cc.p(-450, 90), npcPos = cc.p(-440,-300), npcScaleX = 1},
        {tipPos = cc.p(-50, -220), npcPos = cc.p(-460,-340), npcScaleX = 1},
    }
    if ClanManager:checkRedGiftOpen() then
        guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterChat.id] = {
            {tipPos = cc.p(-450, 90), npcPos = cc.p(-440,-300), npcScaleX = 1},
            {tipPos = cc.p(60, -220), npcPos = cc.p(-350,-340), npcScaleX = 1},
        }
    end
    guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterMember.id] = {
        {tipPos = cc.p(-450, 90), npcPos = cc.p(-480,-300), npcScaleX = 1},
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterRank.id] = {
        {tipPos = cc.p(90, -85), npcPos = cc.p(500,-140), npcScaleX = -1},
        {tipPos = cc.p(10, -10), npcPos = cc.p(-400,-70), npcScaleX = 1},
        {tipPos = cc.p(0, 20), npcPos = cc.p(390,-25), npcScaleX = -1},
        {tipPos = cc.p(80, 90), npcPos = cc.p(450,35), npcScaleX = -1, callFunc = function()
            -- 强制打开权益界面
            ClanManager:showRankBenifitLayer() 
        end},
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterRankBenifit.id] = {
        {tipPos = cc.p(40, 70), npcPos = cc.p(450,15), npcScaleX = -1},
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstEnterRush.id] = {
        {tipPos = cc.p(100, -10), npcPos = cc.p(-80,-280), npcScaleX = 1, callFunc = function()
            -- 弹出 公会Rush挑战任务弹板
            ClanManager:popTeamRushMainLayer()
        end}
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstCheckNewEditMain.id] = {
        {tipPos = cc.p(-130, 60), npcPos = cc.p(-110,-340), npcScaleX = -1, callFunc = function()
            -- 弹出 公会新版信息界面
            local clanData = ClanManager:getClanData()
            local simpleInfo = clanData:getClanSimpleInfo()
            ClanManager:popEditClanInfoPanel(simpleInfo)
        end}
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel.id] = {
        {tipPos = cc.p(30, 30), npcPos = cc.p(30, -360), npcScaleX = -1},
        {tipPos = cc.p(20, -180), npcPos = cc.p(-400,-370), npcScaleX = 1, callFunc = function()
            -- 弹出 公会新版信息界面
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.NOTIFY_TEAM_EDIT_SHOW_NEXT_PAGE)
        end},
        {tipPos = cc.p(40, -100), npcPos = cc.p(-360,-260), npcScaleX = 1},
    }
    guideStepList[NOVICEGUIDE_ORDER.clanFirstCheckNewPositionView.id] = {
        {tipPos = cc.p(-460, 100), npcPos = cc.p(-460,-300), callFunc = function()
            -- 显示 改变公会成员职位floatView
            gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.NOTIFY_SHOW_POSITION_FLOAT_VIEW)
        end}
    }
    self.m_guideStepList = guideStepList
    self.m_curGuideInfo = {}
    self.m_curChildStep = 0
    self.m_bCanTouch = false

    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.CLOSE_CLAN_GUIDE_LAYER) -- 关闭引导界面事件
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
end

function ClanGuideLayer:initUI(_guideId)
    local csbName = "Club/csd/Guide/Club_guideMain.csb"
    if _guideId == NOVICEGUIDE_ORDER.clanFirstEnterMain.id then 
        csbName = "Club/csd/Guide/Club_guideMain.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstEnterChat.id then 
        csbName = "Club/csd/Guide/Club_guideChat.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstEnterMember.id then 
        csbName = "Club/csd/Guide/Club_guideMember.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstEnterRank.id then
        csbName = "Club/csd/RANK/Club_guideRank.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstEnterRankBenifit.id then
        csbName = "Club/csd/RANK/Club_guideRankBenifit.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstEnterRush.id then 
        csbName = "Club/csd/Guide/Club_guideTeamRush.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstCheckNewEditMain.id then
        csbName = "Club/csd/Guide/Club_guideLeader.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel.id then
        csbName = "Club/csd/Guide/Club_guideOldCheckEditPanel.csb"
    elseif _guideId == NOVICEGUIDE_ORDER.clanFirstCheckNewPositionView.id then
        csbName = "Club/csd/Guide/Club_guideMember_changePosition.csb"
    end
    self:createCsbNode(csbName)
    self.m_scale = math.min(self:getUIScalePro(), 1)
    self:setScale(self.m_scale)
    self:maskShow(255)
    self.m_csbNode:setLocalZOrder(2)
    
    -- 设置遮罩层
    local maskLayer = util_newMaskLayer(true)
    maskLayer:setLocalZOrder(-1)
    self:addChild(maskLayer)
    self:move(display.center)

    self.m_maskLayer = maskLayer 
    self:registerTouchEvent()
    self:setMaskTouchEnabled()

    -- 上层添加一个触摸层 点击就下一步
	local touch = util_makeTouch(gLobalViewManager:getViewLayer(), "touch_mask")
    self:addChild(touch, 99)
    touch:setSwallowTouches(true)
    self:addClick(touch)
    self.m_touch = touch
	-- touch:setBackGroundColorOpacity(120)
	-- touch:setBackGroundColorType(2)
	-- touch:setBackGroundColor(cc.c3b(255,0,0))
end

-- 设置当前引导 参考的 refNode 
function ClanGuideLayer:setCurGuideIdNodeList(_guideId, _guideNodeList)
    self.m_curGuideInfo = self.m_guideStepList[_guideId] or {}
    for i, node in ipairs(_guideNodeList) do
        self.m_curGuideInfo[i] = self.m_curGuideInfo[i] or {}
        self.m_curGuideInfo[i].refNode = node
        self.m_curGuideInfo[i].refNodeParent = node:getParent()
        self.m_curGuideInfo[i].refPosL = cc.p(node:getPosition())
    end
    for i = 1, #self.m_curGuideInfo do
        local spTip = self:findChild("yindao_" .. i)
        spTip:setVisible(false)
    end
end

-- 显示引导 UI
function ClanGuideLayer:showStep(_step)
    self.m_curChildStep = _step or 1
    
    local stepInfo = self.m_curGuideInfo[self.m_curChildStep]
    if not next(stepInfo) then
        self:closeUI()
        return
    end

    -- 节点
    local refNode = stepInfo.refNode
    if refNode then
        local posW = refNode:convertToWorldSpaceAR(cc.p(0,0))
        local posL = self:convertToNodeSpaceAR(posW)
        refNode:setPosition(posL)
        util_changeNodeParent(self, refNode)
    end
    
    -- 提示
    for i = 1, #self.m_curGuideInfo do
        local spTip = self:findChild("yindao_" .. i)
        spTip:setVisible(i == self.m_curChildStep)
    end
    self:runCsbAction("start")

    if stepInfo.tipPos then
        local spTip = self:findChild("yindao_"..self.m_curChildStep)
        spTip:move(stepInfo.tipPos)
    end
    
    -- npc
    local spNpc = self:findChild("sp_npc")
    spNpc:setScaleX(1)
    if stepInfo.npcPos then
        spNpc:move(stepInfo.npcPos)
    end
    if stepInfo.npcScaleX then
        spNpc:setScaleX(stepInfo.npcScaleX)
    end

    -- 触摸是否穿透
    if self.m_touch and stepInfo.bPenetrate then
        self.m_touch:setSwallowTouches(false) 
    end
end

function ClanGuideLayer:resetStepNode(_step)
    _step = _step or 0

    local stepInfo = self.m_curGuideInfo[_step]
    if not next(stepInfo) then
        return
    end

    -- 节点
    local refNode = stepInfo.refNode
    local refNodeParent = stepInfo.refNodeParent
    if not tolua.isnull(refNode) and not tolua.isnull(refNodeParent) then
        refNode:setPosition(stepInfo.refPosL or cc.p(0, 0))
        util_changeNodeParent(refNodeParent, refNode)
    end

    if stepInfo.callFunc then
        stepInfo.callFunc()
        stepInfo.callFunc = nil
    end
end

function ClanGuideLayer:registerTouchEvent( )
    local function onTouchBegan(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        if not self.m_bCanTouch then
            return
        end
        self:setMaskTouchEnabled()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over", false, function()
            self:dealNextStep()
        end, 60)
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.m_maskLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.m_maskLayer)
end

function ClanGuideLayer:closeUI()
    self:resetStepNode(self.m_curChildStep)

    if not tolua.isnull(self) then
        self:removeSelf()
    end
end

-- 设置蒙版可以点击
function ClanGuideLayer:setMaskTouchEnabled()
    self.m_bCanTouch = false
    performWithDelay(self, function( )
        self.m_bCanTouch = true
    end, 1)
end

function ClanGuideLayer:dealNextStep()
    self:resetStepNode(self.m_curChildStep)

    if tolua.isnull(self) then
        return
    end

    local nextStep = self.m_curChildStep + 1
    if nextStep > #self.m_curGuideInfo then
        -- 引导完成
        self:closeUI()
    else
        self:showStep(nextStep)
    end
end

function ClanGuideLayer:clickFunc(sender)
    if not self.m_bCanTouch then
        return
    end

    self:setMaskTouchEnabled()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:runCsbAction("over", false, function()
        self:dealNextStep()
    end, 60)
end

return ClanGuideLayer