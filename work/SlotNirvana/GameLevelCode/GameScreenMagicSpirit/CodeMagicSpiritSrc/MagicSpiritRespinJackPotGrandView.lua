---
--island
--2018年4月12日
--MagicSpiritRespinJackPotGrandView.lua
-- reSpin下收集精灵头像全满的弹板
local MagicSpiritRespinJackPotGrandView = class("MagicSpiritRespinJackPotGrandView", util_require("base.BaseView"))

MagicSpiritRespinJackPotGrandView.Btn_Close = "Panel_1"

function MagicSpiritRespinJackPotGrandView:initUI(data)
    local resourceFilename = "MagicSpirit/JackpotOver_Grand.csb"
    self:createCsbNode(resourceFilename)




    self.m_coins = 0
    --node
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_spineJuese = util_spineCreate("MagicSpirit_juese",true,true)
    self:findChild("Node_logo"):addChild(self.m_spineJuese)
    --event
    local clickNode = self:findChild(self.Btn_Close)
    self:addClick(clickNode)
end

function MagicSpiritRespinJackPotGrandView:onEnter()
end

function MagicSpiritRespinJackPotGrandView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
end

--[[
    _params = {
        machine          --主棋盘

        winCoins         --赢钱
        fun_close        --界面关闭
    }
]]
function MagicSpiritRespinJackPotGrandView:initViewData(_params)
    self.m_click = false
    
    self.m_coins = _params.winCoins
    self.fun_close = _params.fun_close
end

function MagicSpiritRespinJackPotGrandView:playStartAnim()
    util_spinePlay(self.m_spineJuese, "actionframe10")
    --提前一秒
    self:jumpCoins(self.m_coins, 88/30)
    --当第20帧时，播放grand弹板的start时间线 
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        self:runCsbAction("start")

        --第108帧播放grand弹板的over时间线
        performWithDelay(waitNode,function()
            self:playOverAnim()
        end, 90/30)
        
    end, 20/30)
end

function MagicSpiritRespinJackPotGrandView:playOverAnim()
    self:runCsbAction("over", false, function(  )
        self.fun_close()

        self:removeFromParent()
    end)
end

--点击回调
function MagicSpiritRespinJackPotGrandView:clickFunc(sender)
    local name = sender:getName()
    if name == self.Btn_Close then
        --使用通用按钮点击音效
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:OnCloseBtnClick(sender)
    end
end

function MagicSpiritRespinJackPotGrandView:OnCloseBtnClick(sender)
    if self.m_updateCoinHandlerID == nil then
        sender:setTouchEnabled(false)

        self:playOverAnim()
    else
        self:jumpCoinsEnd()
    end 
end

--结束跳动
function MagicSpiritRespinJackPotGrandView:jumpCoinsEnd()
    if(self.m_updateCoinHandlerID)then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil

        self:updateLabelCoiss(self.m_coins)
    end
end
--开始跳动
function MagicSpiritRespinJackPotGrandView:jumpCoins( coins , time)
    self.m_coins = coins
    if(self.m_updateCoinHandlerID)then
        return
    end

    self.m_lb_coins:setString("")
    local coinRiseNum =  coins / (time * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum) 

    local curCoins = 0

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= self.m_coins then
            curCoins = self.m_coins

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
        end
        
        self:updateLabelCoiss(curCoins)
    end)
end

function MagicSpiritRespinJackPotGrandView:updateLabelCoiss(count)
    self.m_lb_coins:setString(util_formatCoins(count, 50))
    self:updateLabelSize({label=self.m_lb_coins,sx=0.67,sy=0.67},805)
end

return MagicSpiritRespinJackPotGrandView