---
--xcyy
--2018年5月23日
--WinningFishJackPot.lua

local WinningFishJackPot = class("WinningFishJackPot",util_require("base.BaseView"))

local lbl_count = " m_lb_grand" 
local POT_INDEX = {5,4,3,2,1}

local SIGN_TIMES = {
    "WinningFish_caijindot_1_1",
    "WinningFish_caijindot_02_1",
    'WinningFish_caijindot_3_1'
}

function WinningFishJackPot:initUI(params)
    self.m_index = POT_INDEX[params.pot_index]
    self:createCsbNode(params.csbName)

    self.m_isActiveInRespin = false         --respin状态下是否激活
    self.isUnLockReward = false             --是否解锁解锁奖励
    self.m_winner = self:findChild("winner")    --获奖动画节点
    -- self:runCsbAction("idleframe",true)

    self:findChild("Particle_3"):setVisible(false)
    self:findChild("Particle_3_0"):setVisible(false)
end

function WinningFishJackPot:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    
    if self.m_index <= 2 then
        schedule(self,function()
            self:updateJackpotInfo()
        end,0.08)
    else
        performWithDelay(self,function()
            self:updateJackpotInfo()
        end,0.08)
    end
    
end

function WinningFishJackPot:onExit()
 
end

function WinningFishJackPot:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function WinningFishJackPot:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(lbl_count))

    self:updateSize()
end

function WinningFishJackPot:updateSize()

    local label=self.m_csbOwner[lbl_count]
    local info={label=label,sx=1,sy=1}
    self:updateLabelSize(info,170)
end

--[[
    修改奖池数字
]]
function WinningFishJackPot:changeNode(label)
    local value=self.m_machine:BaseMania_updateJackpotScore(self.m_index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    变暗动画
    ani_type:1 普通模式下变暗 2 respin玩法下变暗
]]
function WinningFishJackPot:turnToBlack(ani_type)
    local params = {}
    if ani_type == 1 then   --普通模式
        params[1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "change_dark", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
        }
        params[2] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "dark1", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
        }
    else    --respin模式
        if not self.m_isActiveInRespin then
            return
        end
        params[1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "change_dark2", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
        }
        params[2] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "dark2", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = function(  )
                self.m_isActiveInRespin = false
            end
        }
    end
    util_runAnimations(params)
end

--[[
    开始动画
]]
function WinningFishJackPot:startAni(func)
    self.m_isActiveInRespin = true
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_jackpot_up.mp3")
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "idle2", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = func
        }
    })
end

--[[
    结束动画
]]
function WinningFishJackPot:overAni(func)
    self.isUnLockReward = false
    local waitingNode = cc.Node:create()
    self:addChild(waitingNode)

    performWithDelay(waitingNode,function()
        waitingNode:removeFromParent(true)
        self:runCsbAction("idle1",false,nil,60) 
    end,1.1)
    self.m_winner:removeAllChildren(true)
end

--[[
    中奖动画
]]
function WinningFishJackPot:winAni()
    self:findChild("Particle_3"):setVisible(true)
    self:findChild("Particle_3_0"):setVisible(true)
    self:findChild("Particle_3"):resetSystem()
    self:findChild("Particle_3_0"):resetSystem()

    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "zhongjiang", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = function(  )
            end
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "zhongjiang_idle", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = function(  )
                
            end
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "zhongjiang_idle", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = function(  )
                
            end
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "idle2", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = function(  )
                
            end
        }
    })
end

--[[
    刷新剩余次数
]]
function WinningFishJackPot:refreshTimes(count,isInit)
    for index=1,3 do
        self:findChild(SIGN_TIMES[index]):setVisible(index <= count)
    end
    if count == 3 and not isInit then
        gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_respin_reset_times.mp3")
        local effect = util_createAnimation("Socre_WinningFish_jackpot_cishuCZ.csb")
        local icon = self:findChild(SIGN_TIMES[3])
        icon:addChild(effect)
        local size = icon:getContentSize()
        effect:setPosition(cc.p(size.width / 2,size.height / 2))
        effect:findChild("Particle_1"):resetSystem()
        performWithDelay(effect,function()
            effect:removeFromParent(true)
        end,1)
    end
end

--[[
    解锁jackpot奖励动画
]]
function WinningFishJackPot:unlockReward()
    if self.isUnLockReward then
        return
    end
    self.isUnLockReward  = true

    local winner_ani = util_createAnimation("Socre_WinningFish_jackpot_winner.csb")
    self.m_winner:removeAllChildren(true)
    self.m_winner:addChild(winner_ani)
     --播放粒子特效
    --  light_temp:findChild("Particle_1"):resetSystem()
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_respin_winner.mp3")
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = winner_ani,   --执行动画节点  必传参数
            actionName = "winner", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = winner_ani,   --执行动画节点  必传参数
            actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
        },
    })
end


return WinningFishJackPot