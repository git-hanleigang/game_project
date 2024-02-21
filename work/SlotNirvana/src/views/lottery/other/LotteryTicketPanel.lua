--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-01 19:29:12
    path:src/views/lottery/other/LotteryTicketPanel.lua
]]
local LotteryTicketPanel = class("LotteryTicketPanel", BaseLayer)
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")

function LotteryTicketPanel:ctor(_data, _cb, _num)
    LotteryTicketPanel.super.ctor(self, _data, _cb, _num)
    self.m_signDay = _data
    self.m_callFunc = _cb
    self.m_num = _num
    self:setPauseSlotsEnabled(true)

    self:setLandscapeCsbName("Lottery/csd/Lottery_Ticket.csb")
    self:setShownAsPortrait(globalData.slotRunData:isFramePortrait())
end

function LotteryTicketPanel:initCsbNodes()
    self.m_lbNumber = self:findChild("lb_number")
    -- 新增一键选号 号码展示节点
    self.m_nodeTicket = self:findChild("node_ticket")
    self.m_nodeList = self:findChild("node_list")
    
    -- 按钮名称
    self.m_btnRandom = self:findChild("btn_random")
    self.m_btnChoose = self:findChild("btn_choose")
end

--重写BaseLayer里界面弹出动效，隐藏动效
function LotteryTicketPanel:playShowAction()
    local userAction = function(callFunc)
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
                self:runCsbAction("idle", true)
            end,
            60
        )
    end

    LotteryTicketPanel.super.playShowAction(self, userAction)
end

function LotteryTicketPanel:hideShowAction()
    local userDefAction = function()
        self:runCsbAction("over", false)
    end
    LotteryTicketPanel.super.hideShowAction(self, userDefAction)
end

-- function LotteryTicketPanel:onClickMask()
--     self:onClickCollect()
-- end

function LotteryTicketPanel:initView()
    local lotteryData = G_GetMgr(G_REF.Lottery):getData()

    if not lotteryData then
        self.m_lbNumber:setVisible(false)
        return
    end

    if self.m_num > 0 then
        self.m_lbNumber:setString("x" .. self.m_num)
    else
        self.m_lbNumber:setVisible(false)
    end

    self:initTicketListView()
end

function LotteryTicketPanel:onClickCollect()
    --弹出选号界面
    local callFun = function()
        if tolua.isnull(self) then
            return
        end

        self:closeUI()
    end

    G_GetMgr(G_REF.Lottery):onDropLotteryTickets(callFun)
end

function LotteryTicketPanel:clickFunc(_sender)
    local btnName = _sender:getName()
    if btnName == "btn_random" then
        if self.m_canClick then
            return
        end
        self.m_canClick = true
        self:autoChooseNum()
    elseif btnName == "btn_choose" then
        self:onClickCollect()
    end
end

function LotteryTicketPanel:autoChooseNum()
    -- 随机选号，结束流程
    local call = function()
        if not tolua.isnull(self) then
            self:closeUI()
        end
    end

    local bCanChoose = G_GetMgr(G_REF.Lottery):checkIsStopChoose()
    if not bCanChoose then
        local view = G_GetMgr(G_REF.Lottery):showTicketsToInboxLayer()
        if view then
            view:setOverFunc(call)
            return
        end

        call()
    else
        G_GetMgr(G_REF.Lottery):sendSyncChooseNumber(true, true)
    end
end

function LotteryTicketPanel:closeUI()
    LotteryTicketPanel.super.closeUI(self, self.m_callFunc)
end

-- 一键选号消息通知

function LotteryTicketPanel:registerListener()
    LotteryTicketPanel.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(_target, _params)
            if _params.isOneKey then
                -- 证明是一键选号此时需要隐藏当前掉落券界面元素显示随机选号号码
                self:hidePanelElement()
            else
                self.m_canClick = false
                self.m_btnRandom:setTouchEnabled(false)
                self.m_btnChoose:setTouchEnabled(false)
                self:dropEnd()
            end
        end,
        LotteryConfig.EVENT_NAME.CREATE_RANDOM_NUMBER_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(_target, _params)
            self:dropEnd()
        end,
        LotteryConfig.EVENT_NAME.CLOSE_LOTTERY_TICKET_PANEL
    )
end

------------------------------------------------ 一键选号号码展示 --------------------------------------------------------

-- 初始化list
function LotteryTicketPanel:initTicketListView()
    local view = util_createView("views.lottery.other.LotteryTicketRandomNumberListView")
    if view then
        self.m_nodeList:addChild(view)
        self.m_randomListView = view
    end
end

-- 一键选号时隐藏按钮，券
function LotteryTicketPanel:hidePanelElement()
    -- 先获取当前已经一键选号的数据，如果存在就隐藏当前界面元素，执行剩余逻辑，如果没有数据就正常结束当前流程
    local mgr = G_GetMgr(G_REF.Lottery)
    if mgr then
        -- 看当前是否有一键选号的数据
        local randomList = mgr:getRandomNumberList()
        if randomList and table.nums(randomList) > 0 then
            self.m_btnRandom:setTouchEnabled(false)
            self.m_btnChoose:setTouchEnabled(false)
            -- 渐隐效果
            util_fadeOutNode(
                self.m_nodeTicket,
                0.5,
                function()
                    if not tolua.isnull(self) then
                        local listLength = table.nums(randomList)
                        self.m_randomListView:updateListBg(listLength, randomList)
                    end
                end
            )
        else
            self:dropEnd()
        end
    else
        -- 没有当前这个manager直接关闭界面
        self:dropEnd()
    end
end

function LotteryTicketPanel:dropEnd()
    self:closeUI()
end

return LotteryTicketPanel
