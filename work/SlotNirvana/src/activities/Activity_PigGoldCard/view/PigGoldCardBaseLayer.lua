--[[
    Author: dhs
    Date: 2022-03-01 20:29:06
    LastEditTime: 2022-03-01 20:30:16
    LastEditors: your name
    Description: 小猪折扣送金卡 基类界面
    FilePath: /SlotNirvana/src/activities/Activity_PigGoldCard/view/PigGoldCardBaseLayer.lua
--]]

local PigGoldCardBaseLayer = class("PigGoldCardBaseLayer", BaseLayer)

function PigGoldCardBaseLayer:ctor()
    PigGoldCardBaseLayer.super.ctor(self)
end

function PigGoldCardBaseLayer:initDatas()
    PigGoldCardBaseLayer.super.initDatas(self)

    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)

    self.m_itemLuaPath = "activities.Activity_PigGoldCard.view.PigGoldCardBaseItem"
    self.m_itemCsbPath = "Activity/Activity_PigGoldCard_Patrick/csb/PigGoldCard_Check.csb"

    self.m_data = G_GetMgr(ACTIVITY_REF.PigGoldCard):getRunningData()
end

-- 活动关闭 界面将自动关闭
function PigGoldCardBaseLayer:checkIsRunning()
    local bl_isRunning = G_GetMgr(ACTIVITY_REF.PigGoldCard):isRunning()
    if not bl_isRunning then
        self:setVisible(false)
        self:setShowActionEnabled(false)
        self:setHideActionEnabled(false)
        util_afterDrawCallBack(
            function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
        )
    end
    return bl_isRunning
end

function PigGoldCardBaseLayer:initUI(data)
    if not self:checkIsRunning() then
        return
    end
    PigGoldCardBaseLayer.super.initUI(self, data)
    self:initView()
end

function PigGoldCardBaseLayer:initCsbNodes()
    self.m_nodeSpine = self:findChild("node_spine")
    self.m_lbDiscount = self:findChild("lb_number") --折扣数字
    assert(self.m_lbDiscount, "PigGoldCardBaseLayer 必要的节点2")
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeReward = self:findChild("node_reward")
    assert(self.m_nodeReward, "PigGoldCardBaseLayer 必要的节点3")
end

function PigGoldCardBaseLayer:initView()
    -- 加载卡片
    if self.initSpine then
        self:initSpine()
    end
    local gameData = G_GetMgr(ACTIVITY_REF.PigGoldCard):getRunningData()
    if gameData then
        -- 在这里加载道具
        local view = self:createItem()
        self.m_nodeReward:addChild(view)
        -- 显示折扣
        local discount = gameData:getDisCount()
        self.m_lbDiscount:setString("" .. discount .. "%")
        util_setCascadeOpacityEnabledRescursion(self, true)
    end
end

function PigGoldCardBaseLayer:createItem()
    local view = util_createView(self.m_itemLuaPath, self.m_itemCsbPath)
    return view
end

function PigGoldCardBaseLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_go" then
        -- 去小猪银行页面
        self:closeUI(
            function()
                G_GetMgr(G_REF.PiggyBank):showMainLayer()
            end
        )
    end
end

function PigGoldCardBaseLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    PigGoldCardBaseLayer.super.playShowAction(self, "start")
end

-- 显示动画回调
function PigGoldCardBaseLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function PigGoldCardBaseLayer:onEnter()
    PigGoldCardBaseLayer.super.onEnter(self)
end

-- 注册消息事件
function PigGoldCardBaseLayer:registerListener()
    PigGoldCardBaseLayer.super.registerListener(self)
    -- 活动结束事件
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.PigGoldCard then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function PigGoldCardBaseLayer:closeUI(end_call)
    PigGoldCardBaseLayer.super.closeUI(
        self,
        function()
            if end_call then
                end_call()
                return
            end

            local closeCallBack = self.m_data:getCloseCallBack()
            if closeCallBack then
                closeCallBack()
                self.m_data:setCloseCallBack(nil)
            else
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        end
    )
end

return PigGoldCardBaseLayer
