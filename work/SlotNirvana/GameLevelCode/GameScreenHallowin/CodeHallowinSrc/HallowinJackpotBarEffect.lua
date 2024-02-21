---
--xcyy
--2018年5月23日
--HallowinJackpotBarEffect.lua

local HallowinJackpotBarEffect = class("HallowinJackpotBarEffect",util_require("base.BaseView"))


function HallowinJackpotBarEffect:initUI()

    self:createCsbNode("Hallowin_jackpot_0.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:setVisible(false)
end

function HallowinJackpotBarEffect:updateJackpotNum(isFreeSpin)
    self:setVisible(true)
    self:showEffectVisible(true)
    local animName = "fankui"
    if isFreeSpin == true then
        animName = "fankui1"
    end
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_jackpot_multip.mp3")
    self:runCsbAction(animName, false, function()
        self:setVisible(false)
    end)
end

function HallowinJackpotBarEffect:jackpotUpAnim(num, func)
    self:setVisible(true)
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_jackpot_up.mp3")
    self:showEffectVisible(false, num)
    self:runCsbAction("up", false, function()
        if func ~= nil then
            func()
        end
        self:setVisible(false)
    end)
end

function HallowinJackpotBarEffect:showEffectVisible(visible, num)
    local index = 7
    while true do
        local parent = self:findChild("kuang_"..index)
        if parent ~= nil then
            if num == index then
                parent:setVisible(not visible)
            else
                parent:setVisible(visible)
            end
        else
            break
        end
        index = index + 1
    end
end

function HallowinJackpotBarEffect:onEnter()

end

function HallowinJackpotBarEffect:onExit()
 
end

return HallowinJackpotBarEffect