--[[
    推荐关卡
    author: 徐袁
    time: 2021-07-21 10:50:15
]]
local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
local LevelRecmdNode = class("LevelRecmdNode", util_require("base.BaseView"))
-- LevelRecmdNode.m_touch = nil
-- LevelRecmdNode.m_index = nil

function LevelRecmdNode:initDatas()
    LevelRecmdNode.super.initDatas(self)
    self.m_contentLen = 0
    self.m_info = nil

    -- 是否显示关卡
    self.m_isShowLevels = false

    self.m_group = ""

    self.m_isFlod = true -- 是否折叠
end

function LevelRecmdNode:initUI(info)
    self.m_info = info

    LevelRecmdNode.super.initUI(self)

    self:initView()
end

function LevelRecmdNode:getCsbName()
    -- self.m_nodeType = self.NODE_TYPE_BIG
    return "newIcons/LevelRecmd2023/LevelRecmdNode.csb"
end

function LevelRecmdNode:initCsbNodes()
    self.m_content = self:findChild("Panel_content")
    self:addClick(self.m_content)
    self.m_content:setSwallowTouches(false)
    self.m_nodeBG = self:findChild("Node_bg")
    self.m_nodeShow = self:findChild("Node_jiantou")
    self.m_showInitPosX = self.m_nodeShow:getPositionX()
    self.m_showInitPosY = self.m_nodeShow:getPositionY()
    -- self.m_nodeHide = self:findChild("Node_jiantou_zhedie")
    -- self.m_jtInitPosX = self.m_nodeHide:getPositionX()
    -- self.m_jtInitPosY = self.m_nodeHide:getPositionY()
end

function LevelRecmdNode:initView()
    self.m_group = self.m_info:getRecmdName()
    local _csb = self.m_info:getCsb()
    self.m_titleNode, self.m_titleAct = util_csbCreate(_csb)
    
    self.m_nodeBG:addChild(self.m_titleNode)
    self.m_nodeLevels = util_createView("views.lobby.LevelRecmdShowNode", self.m_info)
    self.m_nodeShow:addChild(self.m_nodeLevels)
    -- -- 折叠起来的箭头
    -- self.m_nodeZDJT = util_createView("views.lobby.LevelRecmdBtnNode")
    -- self.m_nodeHide:addChild(self.m_nodeZDJT)
    -- self.m_nodeZDJT:setParentNode(self)

    -- 初始化节点位置
    local isShow = self.m_info:isShowed()
    if isShow then
        self:showLevels()
        local _len = self.m_nodeLevels:getContentLen()
        local _showPosX = self.m_nodeShow:getPositionX() + _len
        self.m_nodeShow:setPositionX(_showPosX)
        -- local _hidePosX = self.m_nodeHide:getPositionX() + _len
        -- self.m_nodeHide:setPositionX(_hidePosX)
        -- self.m_nodeZDJT:idleOpened()
    else
        self:playIdle()
    end
end

function LevelRecmdNode:getContentLen()
    local contentSize = self.m_content:getContentSize()
    self.m_contentLenX = contentSize.width / 2
    if self:isShowLevels() then
        self.m_contentLenX = self.m_contentLenX + self.m_nodeLevels:getContentLen() / 2
    end
    self.m_contentLenY = contentSize.height / 2
    return self.m_contentLenX, self.m_contentLenY
end

function LevelRecmdNode:getOffsetPosX()
    local contentSize = self.m_content:getContentSize()
    return contentSize.width / 2
end

function LevelRecmdNode:updateUI()
end

function LevelRecmdNode:onEnter()
    LevelRecmdNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.bDealTouch == false then
                return
            end

            local isPlaying = params.isPlaying or false
            self.m_content:setTouchEnabled(not isPlaying)
            self.m_content:setSwallowTouches(false)
        end,
        ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.recmdName == self.m_group then
                self:changeLevelsVisible(true)
            end
        end,
        ViewEventType.NOTIFY_LOBBY_RECMD_AUTOMOVE
    )

    -- 显示关卡分类详情
    gLobalNoticManager:addObserver(
        self,
        function(self, groupName)
            if  self.m_group ~= groupName then
                return
            end
            if not self:isShowLevels() then
                self:changeLevelsVisible()
            elseif self:isCanShowLevels() then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION, {isPlaying = true, secs = 0.1, group = self.m_group, bDealTouch = false})
            end
        end,
        ViewEventType.NOTIFY_LOBBY_SHOW_RECMD_LEVEL
    )

    self:updateUI()
end

--点击回调
function LevelRecmdNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_content" then
        -- 展示关卡
        self:changeLevelsVisible()
    end
end

-- 是否能显示关卡
function LevelRecmdNode:isCanShowLevels()
    local levelInfos = self.m_info.levelInfos
    if #levelInfos > 0 then
        return true
    else
        return false
    end
end

function LevelRecmdNode:isShowLevels()
    return self.m_isShowLevels
end

function LevelRecmdNode:setLevelsVisible(isVisible)
    self.m_isShowLevels = isVisible
    LevelRecmdData:getInstance():setRecmdShowState(self.m_group, isVisible)
    if isVisible then
        self:playOpen()
    else
        self:playClose()
    end
end

-- 显示关卡
function LevelRecmdNode:showLevels(secs)
    secs = secs or 0
    self:setLevelsVisible(true)
    self.m_nodeLevels:showLevels()
end

-- 显示关卡动画
function LevelRecmdNode:showLevelsAction(secs, callback)
    -- local levelInfos = self.m_info.levelInfos or {}
    -- local secs = 12 / 60 + math.max(#levelInfos - 1, 0) * 12 / 60
    secs = secs or 0
    local _len = self.m_nodeLevels:getContentLen()
    local _desPosX = self.m_showInitPosX + _len
    local _desPosY = self.m_showInitPosY
    local actList1 = {}
    -- actList1[#actList1 + 1] = cc.EaseElasticOut:create(cc.MoveBy:create(secs, cc.p(_len, 0)), 1)
    actList1[#actList1 + 1] =
        cc.CallFunc:create(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_VISIBLE, {isShow = true, secs = secs})
        end
    )
    -- actList1[#actList1 + 1] = cc.MoveBy:create(secs, cc.p(_len, 0))
    actList1[#actList1 + 1] = cc.EaseSineOut:create(cc.MoveTo:create(secs, cc.p(_desPosX + 6, _desPosY)))
    actList1[#actList1 + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    actList1[#actList1 + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(20 / 60, cc.p(_desPosX - 4, _desPosY)))
    actList1[#actList1 + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(20 / 60, cc.p(_desPosX, _desPosY)))
    self.m_nodeShow:runAction(cc.Sequence:create(actList1))

    -- local _desJtPosX = self.m_jtInitPosX + _len
    -- local _desJtPosY = self.m_jtInitPosY
    -- local actList2 = {}
    -- -- actList2[#actList2 + 1] = cc.MoveBy:create(secs, cc.p(_len, 0))
    -- actList2[#actList2 + 1] = cc.EaseSineOut:create(cc.MoveTo:create(secs, cc.p(_desJtPosX + 6, _desJtPosY)))
    -- actList2[#actList2 + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(20 / 60, cc.p(_desJtPosX - 4, _desJtPosY)))
    -- actList2[#actList2 + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(20 / 60, cc.p(_desJtPosX, _desJtPosY)))
    -- self.m_nodeHide:runAction(cc.Sequence:create(actList2))
end

-- 隐藏关卡
function LevelRecmdNode:hideLevels(secs)
    secs = secs or 0

    self:setLevelsVisible(false)
end

-- 隐藏动画
function LevelRecmdNode:hideLevelsAction(secs, callback)
    -- local levelInfos = self.m_info.levelInfos or {}
    -- local secs = 12 / 60 + math.max(#levelInfos - 1, 0) * 12 / 60
    secs = secs or 0
    local _len = self.m_nodeLevels:getContentLen()
    local _desPosX = self.m_showInitPosX
    local _desPosY = self.m_showInitPosY
    local actList1 = {}
    -- actList1[#actList1 + 1] = cc.EaseSineInOut:create(cc.MoveBy:create(10 / 60, cc.p(5, 0)))
    -- actList1[#actList1 + 1] = cc.EaseSineIn:create(cc.MoveBy:create(0.1, cc.p(-5, 0)))
    actList1[#actList1 + 1] =
        cc.CallFunc:create(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_VISIBLE, {isShow = false, secs = secs})
        end
    )
    -- actList1[#actList1 + 1] = cc.EaseSineIn:create(cc.MoveBy:create(secs, cc.p(-(_len + 5), 0)))
    actList1[#actList1 + 1] = cc.EaseSineIn:create(cc.MoveTo:create(secs, cc.p(_desPosX, _desPosY)))
    actList1[#actList1 + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    self.m_nodeShow:stopAllActions()
    self.m_nodeShow:runAction(cc.Sequence:create(actList1))

    -- local _desJtPosX = self.m_jtInitPosX
    -- local _desJtPosY = self.m_jtInitPosY
    -- local actList2 = {}
    -- -- actList2[#actList2 + 1] = cc.EaseSineOut:create(cc.MoveBy:create(10 / 60, cc.p(5, 0)))
    -- -- actList2[#actList2 + 1] = cc.EaseSineIn:create(cc.MoveBy:create(0.1, cc.p(-5, 0)))
    -- -- actList2[#actList2 + 1] = cc.EaseSineIn:create(cc.MoveBy:create(secs, cc.p(-(_len + 5), 0)))
    -- actList2[#actList2 + 1] = cc.EaseSineIn:create(cc.MoveTo:create(secs, cc.p(_desJtPosX, _desJtPosY)))
    -- self.m_nodeHide:stopAllActions()
    -- self.m_nodeHide:runAction(cc.Sequence:create(actList2))
end

-- 动画持续时间
function LevelRecmdNode:getActionSecs()
    local levelInfos = self.m_info.levelInfos or {}
    local secs = 24 / 60 + math.max(#levelInfos - 1, 0) * 6 / 60
    return secs
end

-- 改变关卡表显隐状态
function LevelRecmdNode:changeLevelsVisible(_forceShow)
    if self.m_group == RecmdGroup.NewGame then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_NEWLEVEL)
        return
    end
    if not self:isCanShowLevels() then
        return
    end

    local secs = self:getActionSecs()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION, {isPlaying = true, secs = secs, group = self.m_group})

    if self:isShowLevels() then
        if _forceShow then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION, {isPlaying = false})
            return
        end
        local callback = function()
            self.m_nodeLevels:hideLevels()
            -- self.m_nodeZDJT:playCloseAction()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION, {isPlaying = false})
        end
        self:hideLevels()
        self:hideLevelsAction(secs, callback)
    else
        local callback = function()
            self:showLevels()
            local callback2 = function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CHANGE_RECMD_LEVEL_ACTION, {isPlaying = false})
            end
            self:showLevelsAction(secs, callback2)
        end
        callback()
        -- self.m_nodeZDJT:playOpenAction()
    end
end

-- 更新高倍场状态
function LevelRecmdNode:updateDeluxeLevels(_bOpenDeluxe)
    if self.m_nodeLevels then
        self.m_nodeLevels:updateDeluxeLevels(_bOpenDeluxe)
    end
end

-- 更新关卡logo显示
function LevelRecmdNode:updateLevelLogo()
    if self.m_nodeLevels then
        self.m_nodeLevels:updateLevelLogo()
    end
end

function LevelRecmdNode:isNeedUpdateLogo()
    return true
end

function LevelRecmdNode:playIdle()
    local isShow = self:isShowLevels()
    if isShow then
        util_csbPlayForKey(self.m_titleAct, "openidle", true)
    else
        util_csbPlayForKey(self.m_titleAct, "closeidle", true)
    end
end

function LevelRecmdNode:playOpen()
    self.m_isFlod = false
    util_csbPlayForKey(self.m_titleAct, "open", false, function()
        if not self.m_isFlod then
            self:playIdle()
        end
    end, 60)
end

function LevelRecmdNode:playClose()
    self.m_isFlod = true
    util_csbPlayForKey(self.m_titleAct, "close", false, function()
        if self.m_isFlod then
            self:playIdle()
        end
    end, 60)
end

return LevelRecmdNode
