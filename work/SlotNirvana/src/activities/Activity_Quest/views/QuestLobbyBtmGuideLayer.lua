--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-15 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-15 12:21:23
FilePath: /SlotNirvana/src/activities/Activity_Quest/views/QuestLobbyBtmGuideLayer.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local QuestLobbyBtmGuideLayer = class("QuestLobbyBtmGuideLayer", BaseLayer)

function QuestLobbyBtmGuideLayer:initDatas()
    QuestLobbyBtmGuideLayer.super.initDatas(self)

    self:setLandscapeCsbName("Dialog/guide_layer_l.csb")

    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setName("QuestLobbyBtmGuideLayer")
end

function QuestLobbyBtmGuideLayer:initView()
    QuestLobbyBtmGuideLayer.super.initView(self)

    -- 添加 解锁新功能动效  quest
    self:initQuestEfUI()
    -- 添加 解锁新功能动效  大活动
    self:initBigActEfUI()

    -- 添加触摸层
    self:addTouchLayer()

    schedule(self, util_node_handler(self, self.updateGuideNodePos), 1/60)
end

-- 添加 解锁新功能动效  quest
function QuestLobbyBtmGuideLayer:initQuestEfUI()
    local view = util_createView("activities/Activity_Quest/views/QuestLobbyBtmQuestEfUI")
    self:addChild(view)
    view:setScale(globalData.lobbyScale)
    self.m_questEfUI = view
end
-- 添加 解锁新功能动效  大活动
function QuestLobbyBtmGuideLayer:initBigActEfUI()
    local refNode = G_GetMgr(ACTIVITY_REF.Quest):getLobbyBtmBigActUI()
    if not refNode then
        return
    end

    local view = util_createView("activities/Activity_Quest/views/QuestLobbyBtmBigActEfUI")
    view:setScale(globalData.lobbyScale)
    self:addChild(view)
    self.m_bigActEfUI = view
    self.m_bigActEfUI:setVisible(false)
end

function QuestLobbyBtmGuideLayer:updateGuideNodePos()
    --quest
    if self.m_questEfUI:isVisible() then
        local refNodeQuest = G_GetMgr(ACTIVITY_REF.Quest):getLobbyBtmQuestUI()
        local posW = refNodeQuest:convertToWorldSpace(cc.p(0,0))
        self.m_questEfUI:move(self:convertToNodeSpace(posW))
    end
    
    --大活动
    if self.m_bigActEfUI and self.m_bigActEfUI:isVisible() then
        local refNodeBigAct = G_GetMgr(ACTIVITY_REF.Quest):getLobbyBtmBigActUI()
        posW = refNodeBigAct:convertToWorldSpace(cc.p(0,0))
        self.m_bigActEfUI:move(self:convertToNodeSpace(posW))
    end
end

-- 添加触摸层
function QuestLobbyBtmGuideLayer:addTouchLayer()
    local btnTouch = util_makeTouch(display:getRunningScene(), "btn_touch")
    btnTouch:setSwallowTouches(true)
    btnTouch:setAnchorPoint(0, 0)
    self:addChild(btnTouch)
    self:addClick(btnTouch)
end

function QuestLobbyBtmGuideLayer:startGuide()

    self.m_bCanTouch = false
    self.m_curStep = 1
    self.m_questEfUI:playUnlock(util_node_handler(self, self.resetTouchEnabled))
end

function QuestLobbyBtmGuideLayer:resetTouchEnabled()
    self.m_curStep = self.m_curStep + 1
    self.m_bCanTouch = true
end

function QuestLobbyBtmGuideLayer:clickFunc(_sender)
    if not self.m_bCanTouch then
        return
    end

    local name = _sender:getName()
    if name == "btn_touch" then
        if self.m_curStep == 2 and self.m_bigActEfUI and self.m_bigActEfUI:checkCanGuide() then
            self.m_questEfUI:setVisible(false)
            self.m_bigActEfUI:setVisible(true)
            self.m_bigActEfUI:playUnlock(util_node_handler(self, self.resetTouchEnabled))
        else
            self:closeUI()
        end
    end
end

function QuestLobbyBtmGuideLayer:closeUI()
    local cb = function()
        gLobalDataManager:setBoolByField("QuestUlkLobbyBtmGuide", false)
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
    QuestLobbyBtmGuideLayer.super.closeUI(self, cb)
end

return QuestLobbyBtmGuideLayer