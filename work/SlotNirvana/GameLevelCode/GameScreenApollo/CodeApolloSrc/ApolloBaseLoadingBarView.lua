local ApolloBaseLoadingBarView = class("ApolloBaseLoadingBarView", util_require("base.BaseView"))

local PROGRESS_WIDTH = 445

function ApolloBaseLoadingBarView:initUI()
    local resourceFilename = "Apollo_jindutiao.csb"
    self:createCsbNode(resourceFilename)
    --添加宫殿
    self.m_gongDian = util_createAnimation("Apollo_jindutiao_gongdian.csb")
    self:findChild("gongdian"):addChild(self.m_gongDian)
    self.m_gongDian:playAction("idle",true)
    --添加金币
    self.m_jinbi = util_createAnimation("Apollo_jindutiao_jinbi.csb")
    self:findChild("jinbi"):addChild(self.m_jinbi)
    self.m_jinbi:playAction("idle",true)
    --添加锁定条
    self.m_unLock = util_createAnimation("Apollo_jindutiao_unlock.csb")
    self:findChild("unlock"):addChild(self.m_unLock)
    self.m_unLock:playAction("idle")
    self.m_unLock.m_isJiesuoIng = false--是否正在播解锁动画
    --添加火焰特效
    self.m_huo = util_createAnimation("Apollo_jindutiao_huo.csb")
    self:findChild("huo"):addChild(self.m_huo)
    self.m_huo:playAction("idle",true)

    self.m_progress = self:findChild("Node_jindu")

    self:addClick(self:findChild("Button_i"))
    self:addClick(self:findChild("btn_Map"))
    self:addClick(self.m_unLock:findChild("click"))

    self:idle()
    self:resetProgress()
end

function ApolloBaseLoadingBarView:idle()
    self:runCsbAction("idleframe", true)
end

function ApolloBaseLoadingBarView:setMachine( _machine )
    self.m_machine = _machine
end

--默认按钮监听回调
function ApolloBaseLoadingBarView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()
    if name == "btn_Map" then
        if self:findChild("unlock"):isVisible() == true then
            if self.m_unLock.m_isJiesuoIng == false then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
            end
            return
        end
        if self.m_machine then
            if self.m_machine:checkShopShouldClick() then
                return
            end
            self.m_machine:showMapFromBarClick()
        end
    elseif name == "Button_i" then
        if self.m_machine then
            self.m_machine:showTip(true)
        end
    elseif name == "click" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
    end
end

function ApolloBaseLoadingBarView:resetProgress(_func)
    self:setBarPercent(0)
    if _func then
        _func()
    end
end

function ApolloBaseLoadingBarView:setBarPercent(_percent)
    self.m_progress:setPositionX(_percent * 0.01 * PROGRESS_WIDTH)
end

function ApolloBaseLoadingBarView:updatePercent(_percent,_callback)
    local percent = _percent
    local callback = _callback

    if self.m_percentAction then
        self:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end

    local oldPercent = self.m_progress:getPositionX() / ( 0.01 * PROGRESS_WIDTH)

    local addPercent = (percent - oldPercent) / 4
    if addPercent < 0 then
        addPercent = 1
    end

    self.m_percentAction = schedule(self, function()
        oldPercent = oldPercent + addPercent
        if oldPercent >= percent then
            if self.m_percentAction then
                self:stopAction(self.m_percentAction)
                self.m_percentAction = nil
            end

            if callback then
                callback()
            end
            oldPercent = percent
        end

        self:setBarPercent(oldPercent)
    end, 0.05)

    self.m_jinbi:playAction("actionframe",false,function ()
        self.m_jinbi:playAction("idle",true)
    end)
    self.m_huo:playAction("actionframe",false,function ()
        self.m_huo:playAction("idle",true)
    end)
    self:runCsbAction("collect", false, function()
        if percent >= 100 then

        else
            self:idle()
        end
    end,60)
end

function ApolloBaseLoadingBarView:playGongdianAni(func)
    self.m_gongDian:playAction("actionframe",false,function ()
        self.m_gongDian:playAction("idle",true)
        if func then
            func()
        end
    end)
end

function ApolloBaseLoadingBarView:onEnter()

end

function ApolloBaseLoadingBarView:onExit()
    if self.m_percentAction then
        self:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end

end

return ApolloBaseLoadingBarView