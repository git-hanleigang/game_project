--[[
    Quest Pass
]]

local QuestPassBuyTicket = class("QuestPassBuyTicket", BaseLayer)

function QuestPassBuyTicket:ctor()
    QuestPassBuyTicket.super.ctor(self)

    self:setLandscapeCsbName(QUEST_RES_PATH.QuestPassBuyTicketLayer)
    self:setExtendData("QuestPassBuyTicket")
end

function QuestPassBuyTicket:initDatas()
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

function QuestPassBuyTicket:initCsbNodes()
    self.m_lb_num = self:findChild("lb_num")
end

function QuestPassBuyTicket:initView()
    if self.m_gameData and self.m_gameData:getPassData() then
        local passData = self.m_gameData:getPassData()
        local price = passData:getPrice()
        local totalUsd = passData:getTotalUsd()
        self.m_lb_num:setString("$" .. totalUsd)
        self:setButtonLabelContent("btn_buy", "          $" .. price, nil, true)
    end

    self:updateBtnBuck()
end

function QuestPassBuyTicket:updateBtnBuck()
    local buyType = BUY_TYPE.QUEST_PASS
    self:setBtnBuckVisible(self:findChild("btn_buy"), buyType, nil,
        {
            {node = self:findChild("btn_buy"):getChildByName("ef_zi"):getChildByName("label_1"), addX = 20},
            {node = self:findChild("sp_ticket"), addX = 20},
        }
    )
end

function QuestPassBuyTicket:clickFunc(_sender)
    if self.m_isTouch then
        return
    end

    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_benefit" then
        if self.m_gameData and self.m_gameData:getPassData() then
            local passData = self.m_gameData:getPassData()
            local price = passData:getPrice()
            G_GetMgr(G_REF.PBInfo):showPBInfoLayer({p_price = price}, nil, nil, true)
        end
    elseif name == "btn_buy" then
        if self.m_gameData and self.m_gameData:getPassData() then
            local passData = self.m_gameData:getPassData()
            _sender:setTouchEnabled(false)
            gLobalSendDataManager:getLogIap():setEntryType("questLobby")
            G_GetMgr(ACTIVITY_REF.Quest):buyPassUnlock(passData)
        end
    end
end

function QuestPassBuyTicket:registerListener()
    QuestPassBuyTicket.super.registerListener(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            gLobalSendDataManager:getLogIap():setLastEntryType()
            if params and params.success then
                self:closeUI()
            else
                self:findChild("btn_buy"):setTouchEnabled(true)
            end            
        end,
        ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK
    )
end

return QuestPassBuyTicket