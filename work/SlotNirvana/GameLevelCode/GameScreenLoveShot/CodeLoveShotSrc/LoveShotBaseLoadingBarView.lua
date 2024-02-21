local LoveShotBaseLoadingBarView = class("LoveShotBaseLoadingBarView", util_require("base.BaseView"))
-- 构造函数
--fixios0223
local PROGRESS_WIDTH = 515

function LoveShotBaseLoadingBarView:initUI()

    local resourceFilename = "LoveShot_jindutiao.csb"
    self:createCsbNode(resourceFilename)

    self.m_lockUI = util_createAnimation("LoveShot_Jindutiao_unLock.csb") 
    self:findChild("lock_node"):addChild(self.m_lockUI)

    self.m_progress = self:findChild("Node_jindu") 

    self.m_heart = util_createAnimation("LoveShot_heart.csb") 
    self:findChild("heart"):addChild(self.m_heart)
    self.m_heart:runCsbAction("idleframe",true)
    self.m_btn_i = util_createAnimation("LoveShot_i.csb")
    self:findChild("btn_node"):addChild(self.m_btn_i)

    self:addClick(self:findChild("btn_i"))
    self:addClick(self:findChild("LoveShot_suoding"))

    self:idle()
    self:resetProgress()

end


function LoveShotBaseLoadingBarView:idle()

    self:runCsbAction("idleframe", true)

end

function LoveShotBaseLoadingBarView:setMachine( _machine )
    self.m_machine = _machine
end

--默认按钮监听回调
function LoveShotBaseLoadingBarView:clickFunc(_sender)
    local name = _sender:getName()
    local tag = _sender:getTag()

    if name == "btn_i" then

        if self.m_machine then

            if self.m_machine:checkShopShouldClick( ) then
                return
            end
            
            self.m_machine:showMapFromBarClick( ) 
            


        end

    elseif name == "LoveShot_suoding" then 

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
        
        print("------------- LoveShot_suoding ")

    end
    
end



function LoveShotBaseLoadingBarView:resetProgress(_func)

    self:setBarPercent(0)

    if _func then
        _func()
    end
       
end

function LoveShotBaseLoadingBarView:setBarPercent(_percent)

    self.m_progress:setPositionX(_percent * 0.01 * PROGRESS_WIDTH) 

end


function LoveShotBaseLoadingBarView:updatePercent(_percent,_callback)

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


    self:runCsbAction("actionframe", false, function()
        if percent >= 100 then
            
        else
            self:idle()
        end
    end,60)
end

function LoveShotBaseLoadingBarView:onEnter()

end

function LoveShotBaseLoadingBarView:onExit()

    if self.m_percentAction then
        self:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
end

return LoveShotBaseLoadingBarView