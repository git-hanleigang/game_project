---
--xcyy
--2018年5月23日
--AtlantisRespinBar.lua

local AtlantisRespinBar = class("AtlantisRespinBar",util_require("base.BaseView"))

local TARGET_JACKPOT = {
    {count = 12,reward = "Atlantis_mini_zi_22"},
    {count = 13,reward = "Atlantis_minor_zi_23"},
    {count = 14,reward = "Atlantis_major_zi_21"},
    {count = 15,reward = "Atlantis_grand_zi_20"},
}

local MAX_TIMES = 3     --最大次数

AtlantisRespinBar.m_bonusCount = 0

function AtlantisRespinBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("Respin_Atlantis.csb")
    self:findChild("Particle_2"):setVisible(false)
    --当前收集到的bonus数量
    local csb_bg = util_createAnimation("Qiu_Atlantis.csb")
    csb_bg:runCsbAction("idle",true)
    self:findChild("node_qiu"):addChild(csb_bg)

    --剩余次数
    self.m_times_left_bar = util_createAnimation("Respin_Atlantis_1.csb")
    self.m_machine:findChild("tanban"):addChild(self.m_times_left_bar)
    self.m_times_left_bar:runCsbAction("idle")
    
    
    --已收集bonus数量标签
    self.m_lbl_count = self:findChild("m_lb_num")
    --剩余次数
    self.m_lbl_times = self.m_times_left_bar:findChild("m_lb_num")

end


function AtlantisRespinBar:onEnter()
 

end


function AtlantisRespinBar:onExit()
 
end

--[[
    刷新界面
]]
function AtlantisRespinBar:refreshUI(data,isInit)
    --bonus数量
    local bonus_count = 0
    if data.p_storedIcons then
        bonus_count = #data.p_storedIcons
    end
    
    --判断是否增加了bonus数量
    if bonus_count > self.m_bonusCount then
        --增加数量动画
        self:bonusCountChangeAni(bonus_count,isInit)
    end

    --剩余次数
    local left_times = data.p_reSpinCurCount
    self:refreshTimes(left_times,isInit)
end

--[[
    bonus数量改变动画
]]
function AtlantisRespinBar:bonusCountChangeAni(count,isInit)
    --判断是否增加了bonus数量
    if count <= self.m_bonusCount then
        return
    end
    --记录当前bonus数量
    self.m_bonusCount = count
    local lbl_more_reward_count = self:findChild("m_lb_num_0")

    for k,v in pairs(TARGET_JACKPOT) do
        self:findChild(v.reward):setVisible(false)
    end

    if count <= 11 then
        lbl_more_reward_count:setString(12 - count)
        self:findChild(TARGET_JACKPOT[1].reward):setVisible(true)
    elseif count > 11 and count < 15 then
        lbl_more_reward_count:setString(1)
        for key,value in pairs(TARGET_JACKPOT) do
            if count + 1 ==  value.count then
                self:findChild(value.reward):setVisible(true)
            end
        end
    else
        lbl_more_reward_count:setString(0)
    end

    if isInit then
        self.m_lbl_count:setString(count)
        return
    end
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
            soundFile = "AtlantisSounds/sound_Atlantis_bonus_add.mp3",
            fps = 60,    --帧率  可选参数
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 13,    --关键帧数  帧动画用
                    callBack = function(  )
                        self.m_lbl_count:setString(count)
                    end,
                }       --关键帧回调
            },   
            callBack = function(  )
                self:runCsbAction("idle")
            end
        }
    })

    local particle = self:findChild("Particle_2")
    particle:setVisible(true)
    particle:resetSystem()
    
end

--[[
    刷新次数
]]
function AtlantisRespinBar:refreshTimes(times,isInit)
    self.m_lbl_times:setString(times)

    --次数刷新到最大 初始化次数不播放刷新特效
    if not isInit and times == MAX_TIMES then
        util_runAnimations({
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.m_times_left_bar,   --执行动画节点  必传参数
                actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数
            },
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.m_times_left_bar,   --执行动画节点  必传参数
                actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数
            },
        })
    end
end

--[[
    出现动画
]]
function AtlantisRespinBar:showAni(func)
    self.m_times_left_bar:setVisible(true)
    self:runCsbAction("idle")
    if type(func) == "function" then
        func()
    end
end

--[[
    结束动画 次数条消失动画
]]
function AtlantisRespinBar:OverAni1(func)
    self.m_times_left_bar:setVisible(false)
    if type(func) == "function" then
        func()
    end
end

--[[
    结束动画 bonus数量球下沉动画
]]
function AtlantisRespinBar:OverAni2(func)
    
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self,   --执行动画节点  必传参数
        actionName = "down", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        delayTime = 1.8,
        callBack = function(  )
            self:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
    self.m_bonusCount = 0
end

--默认按钮监听回调
function AtlantisRespinBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

--设置界面是否显示
function AtlantisRespinBar:setShow(isShow)
    self:setVisible(isShow)
    self.m_times_left_bar:setVisible(isShow)
end


return AtlantisRespinBar