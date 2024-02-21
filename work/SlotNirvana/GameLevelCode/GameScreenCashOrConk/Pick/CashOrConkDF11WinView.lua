local CashOrConkDF11WinView = class("CashOrConkDF11WinView", util_require("base.BaseView"))

CashOrConkDF11WinView.m_isJumpOver = false
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

local jackpot2index = {
    ["grand"] = 1,["mega"] = 2,["major"] = 3,["minor"] = 4,["mini"] = 5,
}

local index2jackpot = {
    "grand","mega","major","minor","mini"
}

local hash_jackpot2music = {
    [1] = CashOrConkPublicConfig.sound_CashOrConk_60,
    [2] = CashOrConkPublicConfig.sound_CashOrConk_23,
    [3] = CashOrConkPublicConfig.sound_CashOrConk_61,
    [4] = CashOrConkPublicConfig.sound_CashOrConk_32,
    [5] = CashOrConkPublicConfig.sound_CashOrConk_59,
}

function CashOrConkDF11WinView:initUI(data)
    self.m_index = data.index
    self.m_coins = data.coins
    self.m_click = false
    local resourceFilename = "CashOrConk/CashOrConk_JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    local spine = util_spineCreate("Socre_CashOrConk_juese",true,true)
    util_spinePlayAction(spine, "tb_idle1",true)
    self:findChild("juese_tb"):addChild(spine)

    local spine = util_spineCreate("CashOrConk_tb_sg",true,true)
    util_spinePlayAction(spine, "sg_idle",true)
    self:findChild("Node_sg"):addChild(spine)
    
    for jackpot,i in pairs(jackpot2index) do
        self:findChild(jackpot):setVisible(i == self.m_index)
    end

    self:findChild("grand_guang"):setVisible(self.m_index == 1)

    local anim = util_createAnimation("Socre_CashOrConk_tb_guang.csb")
    anim:playAction("idleframe",true)
    self:findChild("Node_guang"):addChild(anim)

    self._lb_coin = self:findChild("m_lb_coins_"..index2jackpot[self.m_index])


    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            if not self.m_isJumpOver then
                self:stopUpDateCoins()
                self:setWinCoinsLab(self.m_coins)
            end
            self:clickFunc(self:findChild("Button_1"))
        end,10)
    end
end

function CashOrConkDF11WinView:popView()
    gLobalSoundManager:playSound(hash_jackpot2music[self.m_index])
    --数字上涨音效
    -- local key = string.format("sound_jackpotWinView_%d", index)
    -- self.m_bgSoundId =  gLobalSoundManager:playSound(SoundConfig[key])
    self:setWinCoinsLab(0)
    self:jumpCoins(nil, 0)
    self:runCsbAction("start",false,function(  )
        self.m_click = true
        self:runCsbAction("idle",true)
        if self._idleAniRunFunc then
            self._idleAniRunFunc()
        end
    end)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_coins,self.m_index)
end


function CashOrConkDF11WinView:setWinCoinsLab(_coins)
    local labCoins = self._lb_coin
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.93,sy=0.93}, 790)
end

function CashOrConkDF11WinView:onEnter()
    CashOrConkDF11WinView.super.onEnter(self)
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

function CashOrConkDF11WinView:onExit()
    CashOrConkDF11WinView.super.onExit(self)
    if not self.m_isJumpOver then
        self:stopUpDateCoins()
    end

    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
end

function CashOrConkDF11WinView:clickFunc(sender)
    if not self.m_click then
        return 
    end
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_COC_baseLineFrame_click)
    local name = sender:getName()
    if name == "Button_1" then
        -- gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_LeoWealth_49)
        if not self.m_isJumpOver then
            self:stopUpDateCoins()
            self:setWinCoinsLab(self.m_coins)
        else
            self:playOverAnim()
        end
    end
end

function CashOrConkDF11WinView:jumpCoins(coins, startCoins)
    --数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_1)
    if not startCoins then
        startCoins = 0
    end
    local node = self._lb_coin
    node:setString(startCoins)
    local addValue = (self.m_coins - startCoins) / (60 * 5)
    util_jumpNum(node,startCoins,self.m_coins,addValue,1/60,{30}, nil, nil,function(  )
        self:stopUpDateCoins()
    end,function()
        self:updateLabelSize({label=node,sx=0.93,sy=0.93}, 790)
    end)
end

function CashOrConkDF11WinView:stopUpDateCoins()
    self.m_isJumpOver = true
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    local node = self._lb_coin
    node:unscheduleUpdate()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_33)  --结束音效
end

function CashOrConkDF11WinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function CashOrConkDF11WinView:setIdleAniRunFunc(func)
    self._idleAniRunFunc = func
end

function CashOrConkDF11WinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

function CashOrConkDF11WinView:playOverAnim()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_53)
    self:findChild("Button_1"):setTouchEnabled(false)
    self.m_click = false

    self:stopAllActions()
    gLobalNoticManager:postNotification("HIDEEFFECT_SUPERHERO")
    -- gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_LeoWealth_40) --界面关闭音效
    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
    performWithDelay(self,function()
        if self.m_overRuncallfunc then
            self.m_overRuncallfunc()
            self.m_overRuncallfunc = nil
        end

        self:removeFromParent()
    end,overTime)
end

return CashOrConkDF11WinView