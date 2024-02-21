---
--xcyy
--2018年5月23日
--JollyFactoryAddCoinsView.lua
local PublicConfig = require "JollyFactoryPublicConfig"
local JollyFactoryAddCoinsView = class("JollyFactoryAddCoinsView",util_require("base.BaseView"))


function JollyFactoryAddCoinsView:initUI(params)
    self.m_machine = params.machine
    self.m_curIndex = 1
    
end

function JollyFactoryAddCoinsView:resetCoins()
    self.m_addCoins = toLongNumber(0)
    self:setLabelVisible(true)
end

function JollyFactoryAddCoinsView:setCoins(coins)
    self.m_addCoins = toLongNumber(coins)
end

function JollyFactoryAddCoinsView:runAddCoinsAni(index,addCoins,func)
    if index > 5 then
        index = 5
    end
    self.m_curIndex = index
    local duration = 0.2
    if index > 2 then
        duration = 0.4
    end
    local params = {
        startCoins = self.m_addCoins,
        endCoins = self.m_addCoins + toLongNumber(addCoins),
        duration = duration
    }
    
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe"..index,false,function()
        self:runSpineAni("actionframe"..index.."_idle",true)
        if type(func) == "function" then
            func()
        end
    end)
    performWithDelay(self,function()
        self:jumpCoins(params)
    end,1)

    self.m_addCoins  = self.m_addCoins + toLongNumber(addCoins)

    return aniTime
end

function JollyFactoryAddCoinsView:runEndIdle(endIndex)
    self:runSpineAni("actionframe"..endIndex.."_idle",true)
end

--[[
    结束动画
]]
function JollyFactoryAddCoinsView:runOverAni(func)
    self:stopAllActions()
    self:runSpineAni("actionframe"..self.m_curIndex.."_over",false,function()
        if type(func) == "function" then
            func()
        end
        self:setVisible(false)
    end)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JollyFactoryAddCoinsView:initSpineUI()
    self.m_spine = util_spineCreate("JollyFactory_xxd",true,true)
    self:addChild(self.m_spine)

    self.m_lblCsb = util_createAnimation("JollyFactory_Money_Star.csb")
    util_spinePushBindNode(self.m_spine, "kb", self.m_lblCsb)

    self:resetCoins()
end

--[[
    金币跳动
]]
function JollyFactoryAddCoinsView:jumpCoins(params)
    local label = self.m_lblCsb:findChild("m_lb_coins")
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or toLongNumber(0)  -- 起始金币
    local endCoins = params.endCoins or  toLongNumber(0)   --结束金币数
    local duration = params.duration or 0.5   --持续时间
    local maxWidth = params.maxWidth or 540 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound --= PublicConfig.SoundConfig.sound_JollyFactory_jump_coins --跳动音效
    local jumpSoundEnd --= PublicConfig.SoundConfig.sound_JollyFactory_jump_coins_end --跳动结束音效

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_rise_coins"])
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / toLongNumber(120  * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))

    local curCoins = startCoins
    label:stopAllActions()

    if jumpSound then
        self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            label:stopAllActions()
            label:setString(util_formatCoinsLN(endCoins,12))
            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoinsLN(curCoins,12))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

function JollyFactoryAddCoinsView:runSpineAni(aniName,isLoop,func)
    if not isLoop then
        isLoop = false
    end

    --动作已经执行完不需要融合
    if not self.m_runAniEnd then
        -- util_spineMix(self.m_spine,self.m_curAniName,aniName,0.2)
    end

    self.m_runAniEnd = false
    self.m_curAniName = aniName
    util_spinePlay(self.m_spine,aniName,isLoop)
    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    performWithDelay(self,function()
        if not isLoop then
            self.m_runAniEnd = true
        end
        
        if type(func) == "function" then
            func()
        end
    end,aniTime)

    return aniTime
end

--[[
    设置金币标签可见性
]]
function JollyFactoryAddCoinsView:setLabelVisible(isShow)
    self.m_lblCsb:setVisible(isShow)
end



return JollyFactoryAddCoinsView