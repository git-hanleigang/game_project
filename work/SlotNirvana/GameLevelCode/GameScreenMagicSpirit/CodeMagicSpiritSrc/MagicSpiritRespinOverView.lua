---
--island
--2018年4月12日
--MagicSpiritRespinOverView.lua
--先播时间线1(层级:主棋盘后) 所有小轮盘飞往完毕后 再播时间线2(层级:主棋盘前) -> 结束
local MagicSpiritRespinOverView = class("MagicSpiritRespinOverView", util_require("base.BaseView"))


MagicSpiritRespinOverView.m_isJumpOver = false

--按钮名称
MagicSpiritRespinOverView.Btn_Close = "tb_btn"


function MagicSpiritRespinOverView:initUI(data)
    local resourceFilename = "MagicSpirit/RespinOver.csb"
    self:createCsbNode(resourceFilename)
    --
    self.m_click = true
    self.m_coins = 0
    self.m_flyOverAnim = {}    --节点缓存
    

    --一些常用节点
    self.m_lb_coins = self:findChild("m_lb_coins")

    self.m_spineJuese = util_spineCreate("MagicSpirit_juese",true,true)
    self:findChild("Node_logo"):addChild(self.m_spineJuese)
    self.m_spineJuese:setVisible(false)

end

function MagicSpiritRespinOverView:onEnter()
end

function MagicSpiritRespinOverView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
end

--[[
    _params = {
        machine           --主棋盘

        fun_start1        --start1 回调
        fun_idle1         --idle1 回调
        fun_close         --结束回调
    }
]]
function MagicSpiritRespinOverView:initViewData(_params)
    self.m_click = false
    --
    self.m_machine = _params.machine

    self.fun_start1 = _params.fun_start1
    self.fun_idle1 = _params.fun_idle1
    self.fun_start2 = _params.fun_start2
    self.fun_close = _params.fun_close

    self.m_lb_coins:setString("")
end

function MagicSpiritRespinOverView:playActionStart1()
    self:runCsbAction("start1", false, self.fun_start1)
    self.m_spineJuese:setVisible(true)
    util_spinePlay(self.m_spineJuese, "actionframe2")
end
function MagicSpiritRespinOverView:playActionIdle1()
    self:runCsbAction("idle1", false, self.fun_idle1)
    util_spinePlay(self.m_spineJuese, "actionframe3")
end
function MagicSpiritRespinOverView:playActionStart2()
    self:runCsbAction("start2", false, self.fun_start2)
    util_spinePlay(self.m_spineJuese, "actionframe4")
end
function MagicSpiritRespinOverView:playActionIdle2()
    self:runCsbAction("idle2", true)
    util_spinePlay(self.m_spineJuese, "actionframe5", true)
end

--点击回调
function MagicSpiritRespinOverView:clickFunc(sender)
    local name = sender:getName()
    if name == self.Btn_Close then
        --使用通用按钮点击音效
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        if self.m_click == true then
            if(self.m_updateCoinHandlerID)then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil

                self:updateLabelCoiss(self.m_coins)
            end

            return 
        end

        if self.m_updateCoinHandlerID == nil then
            self.m_click = true
            sender:setTouchEnabled(false)

            self:runCsbAction("over2", false, function(  )
                if self.m_callFun then
                    self.m_callFun()
                end

                self.fun_close()

                self:removeFromParent()
            end)

        else
            if(self.m_updateCoinHandlerID)then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil

                self:updateLabelCoiss(self.m_coins)
            end
        end 

        
    end
end

function MagicSpiritRespinOverView:jumpCoins( coins , time)
    self.m_coins = coins
    if(self.m_updateCoinHandlerID)then
        return
    end
    self.m_isJumpOver = false

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

            self.m_isJumpOver = true
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
        end
        
        self:updateLabelCoiss(curCoins)
    end)
end

function MagicSpiritRespinOverView:updateLabelCoiss(count)
    self.m_lb_coins:setString(util_formatCoins(count, 50))
    self:updateLabelSize({label=self.m_lb_coins,sx=0.67,sy=0.67},805)
end

function MagicSpiritRespinOverView:playFlyOverAnim()
    local flyAnim = self:getOneFlyOverAnim()

    flyAnim:setVisible(true)
    flyAnim:runCsbAction("actionframe", false, function()
        flyAnim:setVisible(false)
        table.insert(self.m_flyOverAnim, flyAnim)
    end)
end

function MagicSpiritRespinOverView:getOneFlyOverAnim()
    if(#self.m_flyOverAnim > 0)then
        return table.remove(self.m_flyOverAnim, 1)
    end

    local parent = self:findChild("Node__RespinOver_L")
    local flyAnim = util_createAnimation("MagicSpirit_RespinOver_L.csb")
    parent:addChild(flyAnim)
    
    return flyAnim
end

return MagicSpiritRespinOverView