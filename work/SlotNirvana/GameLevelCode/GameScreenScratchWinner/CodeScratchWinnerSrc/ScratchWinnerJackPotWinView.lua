local ScratchWinnerJackPotWinView = class("ScratchWinnerJackPotWinView",util_require("Levels.BaseLevelDialog"))
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"

function ScratchWinnerJackPotWinView:onExit()
    ScratchWinnerJackPotWinView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        name         = "lotto",
        coins        = 0,
        jackpotIndex = 1,
        isAuto       = true,
    }
]]
function ScratchWinnerJackPotWinView:initUI(_initData)
    self.m_initData = _initData
    self.m_allowClick = false

    self:createCsbNode("ScratchWinner/JackpotWinView.csb")

    self:upDateJackPotShow()
    self:findChild("m_lb_coins"):setString("0")
end
-- 根据类型刷新
function ScratchWinnerJackPotWinView:upDateJackPotShow()
    local children = self:findChild("cardIcon"):getChildren()
    for i,v in ipairs(children) do
        v:setVisible(false)
    end
    local icon = self:findChild(self.m_initData.name)
    icon:setVisible(true)
end

--点击回调
function ScratchWinnerJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
    local name = sender:getName()

    if name == "Button_collect" then
        self:clickCollectBtn(sender)
    end
end

function ScratchWinnerJackPotWinView:clickCollectBtn(_sender)
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setFinalWinCoins()
    else
        self:playOverAnim()
    end

end

-- 弹板入口
function ScratchWinnerJackPotWinView:initViewData()
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_JackpotView)

    local startName = "start"
    self:runCsbAction(startName, false, function()
        -- self:findChild("Button_collect"):setEnabled(true)
        self.m_allowClick = true
        self:runCsbAction("idle", true)

        if self.m_initData.isAuto then
            local animTime = util_csbGetAnimTimes(self.m_csbAct, "idle")
            performWithDelay(
                self,
                function()
                    self:playOverAnim()
                end,
                animTime
            )
        end
   end)

    self:jumpCoins(self.m_initData.coins, 0)
end


function ScratchWinnerJackPotWinView:jumpCoins(coins, _curCoins)
    local coinRiseNum =  coins / (3 * 60)  -- 每秒60帧

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = _curCoins or 0

    local node = self:findChild("m_lb_coins")
    --  数字上涨音效 
    self.m_soundId = gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_JackpotView_JumpCoin)
    

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum

        curCoins = curCoins < coins and curCoins or coins
        node:setString(util_formatCoins(curCoins,50))
        self:updateLabelSize({label=node,sx=1,sy=1},643)

        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
        end
    end,0.008)
end

function ScratchWinnerJackPotWinView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_JackpotView_JumpCoinStop)
    end
end

function ScratchWinnerJackPotWinView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(self.m_initData.coins,50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1},742)
end



function ScratchWinnerJackPotWinView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    local animTime = util_csbGetAnimTimes(self.m_csbAct, "over")
    performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
    
            self:removeFromParent()
        end,
        animTime
    )

end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function ScratchWinnerJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function ScratchWinnerJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

return ScratchWinnerJackPotWinView