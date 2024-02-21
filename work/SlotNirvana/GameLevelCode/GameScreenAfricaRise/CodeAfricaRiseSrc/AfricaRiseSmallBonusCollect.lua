---
--xcyy
--2018年5月23日
--AfricaRiseSmallBonusCollect.lua

local AfricaRiseSmallBonusCollect = class("AfricaRiseSmallBonusCollect", util_require("base.BaseView"))

function AfricaRiseSmallBonusCollect:initUI()
    self:createCsbNode("AfricaRise/SmallBonusCollect.csb")
    self:runCsbAction("start")
    if  display.height/display.width == 1024/768 then
        local node = self:findChild("root")
        node:setScale(0.8)
    end
    self.m_touchFlag = true
    self.m_parent = nil
end

function AfricaRiseSmallBonusCollect:setMachine(machine)
    self.m_machine = machine
end

function AfricaRiseSmallBonusCollect:onEnter()
end


function AfricaRiseSmallBonusCollect:onExit()
end

--默认按钮监听回调
function AfricaRiseSmallBonusCollect:clickFunc(sender)
    if self.m_touchFlag == false then
        return
    end
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_click.mp3")
    self.m_touchFlag = false
    self:runCsbAction("over",false,function ()
        if self.m_parent then
            self.m_parent:closeMapView()
        end
        self.m_func()
        self:removeFromParent()
    end)
end

function AfricaRiseSmallBonusCollect:setFunCall(_func)
    self.m_func = function()
        if _func then
            _func()
        end
    end
end

function AfricaRiseSmallBonusCollect:setWinCoins(_winCoins)
    local node=self:findChild("m_lb_coins")
    node:setString(util_formatCoins(_winCoins,50))
    self:updateLabelSize({label=node,sx=1,sy=1},600)
end

function AfricaRiseSmallBonusCollect:jumpCoins(coins)

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum),"0", math.random(1,5) )
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()


        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},600)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            -- if self.m_JumpSound then
            --     gLobalSoundManager:stopAudio(self.m_JumpSound)
            --     self.m_JumpSound = nil
            --     gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
            -- end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},600)
        end
    end)
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                -- if self.m_JumpSound then
                --     gLobalSoundManager:stopAudio(self.m_JumpSound)
                --     self.m_JumpSound = nil
                --     gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
                -- end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},600)
            end
        end,
        5
    )
end

function AfricaRiseSmallBonusCollect:setViewParent(_parent)
    self.m_parent = _parent
end
return AfricaRiseSmallBonusCollect
