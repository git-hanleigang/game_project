local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")

local CashOrConkDFSureView = class("CashOrConkDFSureView", CashOrConkDFBase)

function CashOrConkDFSureView:initUI(data)
    self._data = data
    self._machine = data.machine
    self.m_overRuncallfunc = data.callback
    self.m_click = false
    local resourceFilename = "CashOrConk/CashOrConk_DF_jieduan.csb"
    self:createCsbNode(resourceFilename)

    self:setWinCoinsLab(self._data.data.coins)

    local spine = util_spineCreate("CashOrConk_tb_sg",true,true)
    util_spinePlayAction(spine, "sg_zi_idle2",true)
    self:findChild("Node_zi_sg"):addChild(spine)

    if data and data.data and data.data.is3in1 then
        self:findChild("anniu_xiayiju"):hide()
        self:findChild("anniu_jin3in1"):show()
        self:findChild("xiayiju"):hide()
        self:findChild("xiayiju1"):hide()
        self:findChild("jin3in1"):show()
    elseif data and data.data and data.data.is2_3 then
        self:findChild("anniu_xiayiju"):hide()
        self:findChild("anniu_jin3in1"):show()
        self:findChild("xiayiju"):hide()
        self:findChild("xiayiju1"):show()
        self:findChild("jin3in1"):hide()
    else
        self:findChild("anniu_xiayiju"):show()
        self:findChild("anniu_jin3in1"):hide()
        self:findChild("xiayiju"):show()
        self:findChild("xiayiju1"):hide()
        self:findChild("jin3in1"):hide()
    end
end

function CashOrConkDFSureView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.85,sy=0.85}, 804)
end

function CashOrConkDFSureView:popView()
    self:levelPerformWithDelay(self,0.1,function()
        gLobalSoundManager:playSound(self._config_music.sound_CashOrConk_38)
    end)
    self:runCsbAction("start",false,function(  )
        self.m_click = true
        self:runCsbAction("idle",true)
        if self._idleAniRunFunc then
            self._idleAniRunFunc(self._lastSendData == 1)
        end
    end)
end

function CashOrConkDFSureView:onEnter()
    CashOrConkDFSureView.super.onEnter(self)
    --解决进入横版活动时再切换回关卡 弹板位置不对问题
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

function CashOrConkDFSureView:onExit()
    CashOrConkDFSureView.super.onExit(self)
end

function CashOrConkDFSureView:clickFunc(sender)
    if not self.m_click then
        return 
    end
    self.m_click = false
    gLobalSoundManager:playSound(self._config_music.sound_COC_baseLineFrame_click)
    local name = sender:getName()
    if name == "n" then
        self:sendData(0)
    else
        self:sendData(1)
    end
end

function CashOrConkDFSureView:playOverAnim()
    self.m_click = false

    self:stopAllActions()
    gLobalNoticManager:postNotification("HIDEEFFECT_SUPERHERO")
    -- gLobalSoundManager:playSound(LeoWealthPublicConfig.sound_LeoWealth_40) --界面关闭音效
    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
    performWithDelay(self,function()
        if self.m_overRuncallfunc then
            self.m_overRuncallfunc(self._lastSendData == 1)
            self.m_overRuncallfunc = nil
        end

        self:removeFromParent()
    end,overTime)
end

function CashOrConkDFSureView:featureResultCallFun(param)
    CashOrConkDFSureView.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        self:playOverAnim()
    else
        self.m_click = true
    end
end

return CashOrConkDFSureView