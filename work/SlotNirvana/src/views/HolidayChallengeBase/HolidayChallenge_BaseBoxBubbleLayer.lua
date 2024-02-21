--[[
    感恩节聚合挑战 登录弹板
    author:csc
    time:2021-11-10 17:52:06
]]
local HolidayChallenge_BaseBoxBubbleLayer = class("HolidayChallenge_BaseBoxBubbleLayer", BaseLayer)

function HolidayChallenge_BaseBoxBubbleLayer:ctor()
    HolidayChallenge_BaseBoxBubbleLayer.super.ctor(self)
end

function HolidayChallenge_BaseBoxBubbleLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.BOX_BUBBLE_NODELAYER)
end

function HolidayChallenge_BaseBoxBubbleLayer:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self:startButtonAnimation("btn_go", "sweep", true) 

    self.m_node_unlock = self:findChild("node_unlock")
    self.m_node_lock = self:findChild("node_lock")

    self.ef_beihou = self:findChild("ef_beihou")

    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coins = self:findChild("lb_coin")
    self.m_lb_extraPoint = self:findChild("lb_text_point")
    self.m_sp_beer_unlock = self:findChild("sp_dou_unlock")

    self.m_lizi = self:findChild("lizi")
    self.m_lizi_1 = self:findChild("lizi_0")
end

function HolidayChallenge_BaseBoxBubbleLayer:initUI()
    HolidayChallenge_BaseBoxBubbleLayer.super.initUI(self)
end

function HolidayChallenge_BaseBoxBubbleLayer:initView()
    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getCurrThemeName() .."BoxBubbleLayer:btn_go"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) ~= "" and gLobalLanguageChangeManager:getStringByKey(key) or "GOLDEN HUNT"
    self:setButtonLabelContent("btn_go", lbString)

    local activityRunData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    local coinsNum = activityRunData:getExtraPointCoins()
    local extraPoint = activityRunData:getExtraPoint()
    if coinsNum > 0 then
        self.m_node_unlock:setVisible(true)
        self.m_node_lock:setVisible(false)
        self.m_lb_coins:setString(util_formatCoins(coinsNum,9,nil,nil,true))
        self.m_lb_extraPoint:setString("AN EXTRA "..extraPoint)
        self.m_sp_coin:setPositionX(self.m_lb_coins:getPositionX() - self.m_lb_coins:getContentSize().width/2*0.55 - 44)
        self.m_sp_beer_unlock:setPositionX(self.m_lb_extraPoint:getPositionX() + self.m_lb_extraPoint:getContentSize().width + 43)
    else
        self.m_node_unlock:setVisible(false)
        self.m_node_lock:setVisible(true)
    end
end 

-- 重写父类方法 
function HolidayChallenge_BaseBoxBubbleLayer:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end


function HolidayChallenge_BaseBoxBubbleLayer:onEnter()
    HolidayChallenge_BaseBoxBubbleLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HolidayChallenge_BaseBoxBubbleLayer:onExit()
    HolidayChallenge_BaseBoxBubbleLayer.super.onExit(self)
end

function HolidayChallenge_BaseBoxBubbleLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()

    if name == "btn_go" or name == "btn_close" then
        if name == "btn_go" then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)  
        end
        self:closeUI()
    end
end

function HolidayChallenge_BaseBoxBubbleLayer:closeUI(callbackFunc)
    if self.ef_beihou then
        self.ef_beihou:setVisible(false)
    end

    if self.m_lizi then
        self.m_lizi:setVisible(false)
    end
    if self.m_lizi_1 then
        self.m_lizi_1:setVisible(false)
    end
    HolidayChallenge_BaseBoxBubbleLayer.super.closeUI(self, callbackFunc)
end

return HolidayChallenge_BaseBoxBubbleLayer
