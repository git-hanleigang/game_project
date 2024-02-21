---
--xcyy
--2018年5月23日
--GirlsCookJackPotBarView.lua

local GirlsCookJackPotBarView = class("GirlsCookJackPotBarView",util_require("base.BaseView"))

function GirlsCookJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("GirlsCook_jackpot.csb")

    self.m_lbl_coins = {}
    self.m_lights = {}
    for index = 1,3 do
        local node = self:findChild("Node_jackpot_"..index)
        local lbl_coin = node:getChildByName("m_lb_coin")
        self.m_lbl_coins[index] = lbl_coin

        local light = util_createAnimation("GirlsCook_jackpot_0.csb")
        self:findChild("Node_"..index):addChild(light)
        light:setVisible(false)
        self.m_lights[index] = light
    end

    self.m_rewards = nil

    
end

function GirlsCookJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function GirlsCookJackPotBarView:onExit()
 
end

function GirlsCookJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function GirlsCookJackPotBarView:refreshCoins(data,isInit,func)
    local isJumpCoin = false
    for index = 1,3 do
        local lbl_coin = self.m_lbl_coins[index]
        if data then
            local rewardData = data[index]
            if rewardData and rewardData.hit and not isInit then
                isJumpCoin = true
                -- local preCoins = 0
                -- if self.m_rewards then
                --     preCoins = self.m_rewards[index].amount
                -- end
                -- self:jumpCoins(lbl_coin,preCoins,rewardData.amount)
                gLobalSoundManager:playSound("GirlsCookSounds/music_GirlsCook_fs_hit_light.mp3")
                self:showLights(index,function()
                    lbl_coin:setString(util_formatCoins(rewardData.amount,50))
                    local info={label = lbl_coin,sx = 1,sy = 1}
                    self:updateLabelSize(info,206)

                    self:addCoinAni(index)
                end)
            elseif rewardData and (not rewardData.hit or isInit) then
                lbl_coin:setString(util_formatCoins(rewardData.amount,50))
                local info={label = lbl_coin,sx = 1,sy = 1}
                self:updateLabelSize(info,206)
            elseif not rewardData then
                lbl_coin:setString(0)
            end

            
        else
            lbl_coin:setString(0)
        end
    end

    self.m_rewards = data

    if isJumpCoin then
        performWithDelay(self,function()
            if type(func) == "function" then
                func()
            end
        end,2)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    显示光效
]]
function GirlsCookJackPotBarView:showLights(index,func)
    local light = self.m_lights[index]
    light:setVisible(true)
    light:runCsbAction("actionfrane",false,function()
        light:setVisible(false)
        self.m_machine:delayCallBack(1,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    end)
end

--[[
    加钱动作
]]
function GirlsCookJackPotBarView:addCoinAni(index,func)
    local light = self.m_lights[index]
    light:setVisible(true)
    light:runCsbAction("actionframe1",false,function()
        light:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    重置数据
]]
function GirlsCookJackPotBarView:resetData()
    self.m_rewards = nil
end

function GirlsCookJackPotBarView:jumpCoins(lbl_coin,startValue,endValue)

    local startCoins = startValue or 0
    local endCoins = endValue or 0

    local coinRiseNum = (endCoins - startCoins) / 100
    local curCoins = startCoins

    lbl_coin:setString(util_formatCoins(curCoins,50))
    local info={label = lbl_coin,sx = 1,sy = 1}
    self:updateLabelSize(info,206)

    util_schedule(lbl_coin,function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= endCoins then

            curCoins = endCoins

            lbl_coin:setString(util_formatCoins(curCoins,50))
            local info={label = lbl_coin,sx = 1,sy = 1}
            self:updateLabelSize(info,206)
            lbl_coin:stopAllActions()
        else
            lbl_coin:setString(util_formatCoins(curCoins,50))

            local info={label = lbl_coin,sx = 1,sy = 1}
            self:updateLabelSize(info,206)
        end
        

    end,2 / 100)
end

return GirlsCookJackPotBarView