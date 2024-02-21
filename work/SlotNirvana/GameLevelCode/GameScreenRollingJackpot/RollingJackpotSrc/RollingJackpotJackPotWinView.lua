---
--island
--2018年4月12日
--RollingJackpotJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local RollingJackpotJackPotWinView = class("RollingJackpotJackPotWinView", util_require("Levels.BaseLevelDialog"))

local ConfigInstance  = require("RollingJackpotPublicConfig"):getInstance()
local SoundConfig = ConfigInstance.SoundConfig

RollingJackpotJackPotWinView.m_isJumpOver = false

function RollingJackpotJackPotWinView:initUI(data)
    self.m_click = false
    local resourceFilename = "RollingJackpot/RollingJackpot_JackpotWinView.csb"
    self:createCsbNode(resourceFilename)
end

function RollingJackpotJackPotWinView:initViewData(index,rapidNums,coins)
    self.m_index = index
    self.m_coins = coins
    self.rapidNums = rapidNums
    self.m_click = false
    self.m_bgSoundId = gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_19)
    self:findChild("m_lb_num"):setString(self.rapidNums)
    self:upDateJackPotShow()
    self:setWinCoinsLab(0)
    self:runCsbAction("start",false,function(  )
        self.m_click = true
        self:runCsbAction("idle",true)
    end)
    util_performWithDelay(self, function()
        self:jumpCoins(coins, 0)
    end, 55/60)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

-- 根据jackpot类型刷新展示
function RollingJackpotJackPotWinView:upDateJackPotShow()
    self.m_guang = util_createAnimation("RollingJackpot_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(self.m_guang)
    self.m_guang:playAction("idle",true)
end


function RollingJackpotJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    labCoins:setVisible(_coins ~= 0)
    self:updateLabelSize({label = labCoins, sx = 0.96, sy = 0.96}, 693)
end

function RollingJackpotJackPotWinView:onEnter()
    RollingJackpotJackPotWinView.super.onEnter(self)
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

function RollingJackpotJackPotWinView:onExit()
    RollingJackpotJackPotWinView.super.onExit(self)
    if not self.m_isJumpOver then
        self:stopUpDateCoins()
    end

    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
    
end

function RollingJackpotJackPotWinView:clickFunc(sender)
    if not self.m_click then
        return 
    end
    local name = sender:getName()
    if name == "Button_collect" then
        gLobalSoundManager:playSound(SoundConfig.sound_base_dialog) --按钮点击音效
        if not self.m_isJumpOver then
            self:stopUpDateCoins()
            self:setWinCoinsLab(self.m_coins)
        else
            self:playOverAnim()
        end
    end
end

function RollingJackpotJackPotWinView:jumpCoins(coins, startCoins)
    --数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(SoundConfig.sound_jackpotView_num_jump,true)
    if not startCoins then
        startCoins = 0
    end
    local node=self:findChild("m_lb_coins")
    node:setVisible(true)
    node:setString(startCoins)
    local addValue = (self.m_coins - startCoins) / (60 * 5)
    util_jumpNum(node,startCoins,self.m_coins,addValue,1/60,{30}, nil, nil,function(  )
        self:stopUpDateCoins()
    end,function()
        self:updateLabelSize({label = node, sx = 0.96, sy = 0.96}, 693)
    end)
end

--
function RollingJackpotJackPotWinView:stopUpDateCoins()
    self.m_isJumpOver = true
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    local node=self:findChild("m_lb_coins")
    node:unscheduleUpdate()
    gLobalSoundManager:playSound(SoundConfig.sound_jackpotView_num_end)  --结束音效
end

--[[
    点击回调 和 结束回调
]]
function RollingJackpotJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function RollingJackpotJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

function RollingJackpotJackPotWinView:playOverAnim()
    self:findChild("Button_collect"):setTouchEnabled(false)
    self.m_click = false

    self:stopAllActions()
    gLobalNoticManager:postNotification("HIDEEFFECT_SUPERHERO")
    gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_32) --界面关闭音效
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

return RollingJackpotJackPotWinView