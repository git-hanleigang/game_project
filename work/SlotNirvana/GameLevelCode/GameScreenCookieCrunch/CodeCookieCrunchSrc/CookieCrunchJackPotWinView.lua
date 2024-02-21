local CookieCrunchJackPotWinView = class("CookieCrunchJackPotWinView",util_require("Levels.BaseLevelDialog"))

local JackPotNodeName = {
    [1] = "grand",
    [2] = "major",
    [3] = "minor",
    [4] = "mini",
}

function CookieCrunchJackPotWinView:onExit()
    CookieCrunchJackPotWinView.super.onExit(self)
    self:stopUpDateCoins()

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _initData = {
        coins        = 0,
        jackpotIndex = 1,
    }
]]
function CookieCrunchJackPotWinView:initUI(_initData)
    self.m_initData = _initData
    self.m_allowClick = false
    self.m_jackpotIndex = self.m_initData.jackpotIndex

    self:createCsbNode("CookieCrunch/JackpotWinView.csb")
    -- self:findChild("Button_collect"):setEnabled(false)

    self:createGrandShare(self.m_initData.machine)

    self.m_lightAnim = util_createAnimation("CookieCrunch_tb_light.csb")
    self:findChild("Node_light"):addChild(self.m_lightAnim)
    self.m_lightAnim:runCsbAction("idleframe", true)
    
    local roleSpineRes = {
        "Socre_CookieCrunch_9",
        "Socre_CookieCrunch_8",
        "Socre_CookieCrunch_7",
        "Socre_CookieCrunch_6",
    }
    local spineRes = roleSpineRes[self.m_initData.jackpotIndex] or roleSpineRes[1]
    self.m_roleSpine = util_spineCreate(spineRes,true,true)
    self:findChild("ren"):addChild(self.m_roleSpine)
    util_spinePlay(self.m_roleSpine, "idle", true)
    util_setCascadeOpacityEnabledRescursion(self.m_roleSpine, true)

    self:upDateJackPotShow()
    self:findChild("m_lb_coins"):setString("0")
end
-- 根据jackpot类型刷新展示
function CookieCrunchJackPotWinView:upDateJackPotShow()
    for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
        local isVisible = _jpIndex == self.m_initData.jackpotIndex
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end
end
--点击回调
function CookieCrunchJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name = sender:getName()

    if name == "Button_collect" then
        self:clickCollectBtn(sender)
    end
end

function CookieCrunchJackPotWinView:clickCollectBtn(_sender)
    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_click.mp3")

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setFinalWinCoins()
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

-- 弹板入口
function CookieCrunchJackPotWinView:initViewData()
    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_start.mp3")

    local startName = "start"
    self:runCsbAction(startName, false, function()
        -- self:findChild("Button_collect"):setEnabled(true)
        self.m_allowClick = true
        self:runCsbAction("idle", true)

        if self.m_initData.isAuto then
            local animTime = 4
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


function CookieCrunchJackPotWinView:jumpCoins(coins, _curCoins)
    local coinRiseNum =  coins / (3 * 60)  -- 每秒60帧

    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = _curCoins or 0

    local node=self:findChild("m_lb_coins")
    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_jumpCoin.mp3",true)
    

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum

        curCoins = curCoins < coins and curCoins or coins
        node:setString(util_formatCoins(curCoins,50))
        self:updateLabelSize({label=node,sx=1,sy=1},742)

        if curCoins >= coins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
        end
    end,0.008)
end

function CookieCrunchJackPotWinView:stopUpDateCoins()
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil

        gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_jackpotView_jumpCoinStop.mp3")
    end
end

function CookieCrunchJackPotWinView:setFinalWinCoins()
    if not self.m_initData then
        return
    end
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(self.m_initData.coins,50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1},742)
end



function CookieCrunchJackPotWinView:playOverAnim()
    self:findChild("Button_collect"):setEnabled(false)
    self.m_allowClick = false
    self:stopAllActions()

    local bShare = self:checkShareState()
    if not bShare then
        self:jackpotViewOver(function()
            if self.m_btnClickFunc then
                self.m_btnClickFunc()
                self.m_btnClickFunc = nil
            end
        
            self:runCsbAction("over", false)
        
            performWithDelay(
                self,
                function()
                    if self.m_overRuncallfunc then
                        self.m_overRuncallfunc()
                        self.m_overRuncallfunc = nil
                    end
            
                    self:removeFromParent()
                end,
                32/60
            )
        end)
    end

end

--[[
    模仿一下 BaseDialog 的点击结束流程
]]
function CookieCrunchJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
function CookieCrunchJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function CookieCrunchJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function CookieCrunchJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function CookieCrunchJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function CookieCrunchJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CookieCrunchJackPotWinView