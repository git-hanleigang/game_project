
-- 大卡上的request按钮

local CardTagRequest_big = class("CardTagRequest_big", util_require("base.BaseView"))
function CardTagRequest_big:initUI()
    self:createCsbNode(self:getCsbName())
    self:initNode()
    self:updateCountdown()
end

function CardTagRequest_big:setCardData(_cardData)
    self.m_cardData = _cardData    
end

function CardTagRequest_big:getCsbName()
    return string.format(CardResConfig.seasonRes.CardMiniTagRequestRes_big, "season201903")
end

function CardTagRequest_big:initNode()
    self.btn_request        = self:findChild("btn_request")
    -- self.m_spRequestLabel   = self:findChild("sp_requestLabel")
    self.node_cd            = self:findChild("node_cd")
    self.m_lbTime           = self:findChild("lb_time")

    -- cd按钮
    self:setButtonLabelContent("btn_cd", "")
    self:setButtonLabelDisEnabled("btn_cd", false)
end

function CardTagRequest_big:updateCountdown()
    if not self.activityAction then
        self.activityAction = util_schedule(self,function()
            local leftTime = self:getLeftTime()
            self.btn_request:setBright( leftTime <= 0 )
            self.btn_request:setTouchEnabled( leftTime <= 0 )
            self.node_cd:setVisible( leftTime > 0 )

            if leftTime > 0 then 
                self.m_lbTime:setString(util_count_down_str(leftTime))
            else
                self:stopAction(self.activityAction)
                self.activityAction = nil
            end
        end,1)
    end

    local leftTime = self:getLeftTime()
    self.btn_request:setBright( leftTime <= 0 )
    self.btn_request:setTouchEnabled( leftTime <= 0 )
    self.node_cd:setVisible( leftTime > 0 )
    if leftTime > 0 then 
        self.m_lbTime:setString(util_count_down_str(leftTime))
    end
end

function CardTagRequest_big:getLeftTime()
    local leftTime = 0
    local expireAt = CardSysRuntimeMgr:getAskCD()
    if expireAt and expireAt > 0 then
        leftTime = math.max(0, (math.floor((expireAt - globalData.userRunData.p_serverTime)/1000)))
    end
    return leftTime
end

function CardTagRequest_big:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_request" then
        -- 发送请求，要卡
        if not self.m_cardData then
            assert(false, "self.m_cardData is not inited!!!")
            return 
        end

        -- -- 要卡弹板界面
        -- local ClanManager = util_require("manager.System.ClanManager"):getInstance()
        -- local bTeamMember = ClanManager:checkIsMember()
        -- --暂时新增好友要卡
        -- local friend_list = nil
        -- if G_GetMgr(G_REF.Friend) then
        --     friend_list = G_GetMgr(G_REF.Friend):getAllFriend()
        -- end
        -- if not bTeamMember and (not friend_list or #friend_list == 0) then
        --     ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CLAN_NO_JOIN_TEAM)
        --     return
        -- end
        -- if bTeamMember then
        --     CardSysManager:popRequestCardFormClanPanel(self.m_cardData)
        -- end
        -- if friend_list and #friend_list > 0 then
        --     G_GetMgr(G_REF.Friend):requestApplyFriendCard(self.m_cardData.cardId)
        -- end
        -- --CardSysManager:popRequestCardFormClanPanel(self.m_cardData)

        local ClanManager = util_require("manager.System.ClanManager"):getInstance()
        local bTeamMember = ClanManager:checkIsMember()
        local friend_list = G_GetMgr(G_REF.Friend):getAllFriend()

        local isSendTeam = false
        if bTeamMember then
            isSendTeam = true
        end
        local isSendFriend = false
        if friend_list and #friend_list > 0 then
            isSendFriend = true
        end
        if isSendTeam or isSendFriend then
            if isSendTeam and isSendFriend then
                gLobalViewManager:showDialog("Dialog/ClanAskChip.csb",
                    function()
                        CardSysManager:requestCardFromClan(self.m_cardData)
                        G_GetMgr(G_REF.Friend):requestApplyFriendCard(self.m_cardData.cardId)
                    end
                )
            elseif isSendTeam and not isSendFriend then
                gLobalViewManager:showDialog("Dialog/ClanAskChip.csb",
                    function()
                        CardSysManager:requestCardFromClan(self.m_cardData)
                    end
                )
            elseif not isSendTeam and isSendFriend then
                gLobalViewManager:showDialog("Dialog/ClanAskChip.csb",
                    function()
                        G_GetMgr(G_REF.Friend):requestApplyFriendCard(self.m_cardData.cardId)
                    end
                )
            end
        else
            ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CLAN_NO_TEAM_NO_FRIEND)
        end        
    end
end

function CardTagRequest_big:onEnter()
    gLobalNoticManager:addObserver(self, function(target, params)
        self:updateCountdown()
    end, CardSysConfigs.ViewEventType.CARD_COUNTDOWN_UPDATE)
end

function CardTagRequest_big:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return CardTagRequest_big
