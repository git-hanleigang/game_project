--[[
Author: cxc
Date: 2021-12-14 10:22:48
LastEditTime: 2021-12-14 10:22:49
LastEditors: your name
Description: 乐透新手引导
FilePath: /SlotNirvana/src/views/lottery/other/LotteryGuideLayer.lua
--]]

local LotteryGuideLayer = class("LotteryGuideLayer", BaseView)
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")

function LotteryGuideLayer:ctor(_highlightNodeList, _npcGuideNodeList, _scale)
    LotteryGuideLayer.super.ctor(self)

    self.m_curGuideInfo = {}
    self.m_highlightNodeList = _highlightNodeList or {} --高亮节点的list
    self.m_npcGuideNodeList = _npcGuideNodeList or {} -- npc提示的节点list
    self.m_scale = _scale or 1
    self.m_curStep = 1
end

function LotteryGuideLayer:getCsbName()
    return "Lottery/csd/Guide/Lottery_Guide_NpcTip.csb"
end

function LotteryGuideLayer:initUI()
    LotteryGuideLayer.super.initUI(self)
    
    -- util_csbScale(self.m_csbNode, self.m_scale)
    self:setScale(self.m_scale)
    self.m_csbNode:setLocalZOrder(2)
    
    -- 设置遮罩层
    local maskLayer = util_newMaskLayer(true)
    maskLayer:setLocalZOrder(-1)
   

    self:addChild(maskLayer)
    self:move(display.center)

    self.m_maskLayer = maskLayer 
    self:registerTouchEvent()
    -- self:setMaskTouchEnabled()

    --设置第一步引导遮罩层
    -- 设置遮罩层
    local firstMaskLayer = util_newMaskLayer(true)
    firstMaskLayer:setOpacity(0)
    self:addChild(firstMaskLayer,99)
    self:move(display.center)

    self.m_firstMaskLayer = firstMaskLayer
    self:setFirstStepMask()

    self:resetGuideNodeList()

    self:showStep()

    self:registerEvent()
end
-- 引导第一步不让他点击
function LotteryGuideLayer:setFirstStepMask()
    local function onTouchBegan(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:dealNextStep()
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.m_firstMaskLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.m_firstMaskLayer)

end
-- 设置当前引导 参考的 refNode 
function LotteryGuideLayer:resetGuideNodeList()
    self.m_curGuideInfo = {}
    for i, node in ipairs(self.m_highlightNodeList) do

        self.m_curGuideInfo[i] = {}
        self.m_curGuideInfo[i].refNode = node
        self.m_curGuideInfo[i].refNodeParent = node:getParent()
        self.m_curGuideInfo[i].refPosL = cc.p(node:getPosition())
        local npcRefNode = self.m_npcGuideNodeList[i] 
        self.m_curGuideInfo[i].npcRefNode = npcRefNode

        local spTip = self:findChild("node_guide_" .. i)
        if spTip and not tolua.isnull(npcRefNode) then
            local posW = npcRefNode:convertToWorldSpaceAR(cc.p(0,0))
            local posL = spTip:getParent():convertToNodeSpaceAR(posW)
            spTip:move(posL)
            spTip:setVisible(false)
        end
        
    end
   
end

-- 显示引导 UI
function LotteryGuideLayer:showStep(_step)
    self.m_curStep = _step or 1
    
    local stepInfo = self.m_curGuideInfo[self.m_curStep]
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

        local spTip = self:findChild("node_guide_" .. i)
        if spTip then
            spTip:setVisible(i == self.m_curStep)
        end

    end

end

function LotteryGuideLayer:resetStepNode(_step)
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
end

function LotteryGuideLayer:registerTouchEvent( )
    local function onTouchBegan(touch, event)
        return true
    end
    local function onTouchEnded(touch, event)
        -- self:setMaskTouchEnabled()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_curStep >= 3 then
            return
        end 
        self:dealNextStep()
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.m_maskLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.m_maskLayer)
end

function LotteryGuideLayer:closeUI()
    self:resetStepNode(self.m_curStep)

    if not tolua.isnull(self) then
        self:removeSelf()
    end
end

function LotteryGuideLayer:dealNextStep()
    self:resetStepNode(self.m_curStep)

    local nextStep = self.m_curStep + 1
    
    if nextStep == 2 then
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.GUIDE_EFFECT, true)
        self.m_firstMaskLayer:removeFromParent()
    end

    if nextStep == 3 then
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.GUIDE_EFFECT_STOP)
    end


    if nextStep > #self.m_curGuideInfo then
        -- 引导完成
        self:closeUI()
    else
        self:showStep(nextStep)
    
    end
end

function LotteryGuideLayer:registerEvent()
    gLobalNoticManager:addObserver(self, "dealNextStep", LotteryConfig.EVENT_NAME.GUIDE_FINAL_STEP) --跟服务器同步号码成功
end

return LotteryGuideLayer