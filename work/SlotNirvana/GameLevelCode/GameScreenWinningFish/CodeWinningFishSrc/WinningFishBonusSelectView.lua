--[[
    选择奖励界面
]]

local WinningFishBonusSelectView = class("WinningFishBonusSelectView",util_require("base.BaseView"))

local BOX_NODE = {
    "Node_3",
    "Node_3_0",
    "Node_3_1"
}

function WinningFishBonusSelectView:initUI(base_game)
    self:createCsbNode("Socre_WinningFish_Bonus_tanban.csb")
    self.m_base_game = base_game
    --宝箱
    self.m_boxs = {}
    for index=1,3 do
        local box = util_createAnimation("Socre_WinningFish_Bonus_tanban_0.csb")
        self.m_boxs[index] = box
        self:findChild(BOX_NODE[index]):addChild(box)
        --创建点击区域
        local layout = ccui.Layout:create() 
        box:findChild("Node_1"):addChild(layout)    
        layout:setAnchorPoint(0.5,0.5)
        layout:setContentSize(box:findChild("WinningFish_zhe_37"):getContentSize())
        layout:setTouchEnabled(true)
        layout:setTag(index)
        self:addClick(layout)
    end

    self.m_node_pick = self:findChild("Node_1")
    self.m_node_select = self:findChild("Node_2")
end


function WinningFishBonusSelectView:onEnter()

end

function WinningFishBonusSelectView:onExit()

end

--[[
    显示奖励
]]
function WinningFishBonusSelectView:showReward(index)
    local reward = nil
    for key,value in pairs(self.m_rewardData) do
        if value[2] == "open" then
            reward = {
                key = key,
                value = value
            }
            break
        end
    end

    local box = self.m_boxs[index]
    local lbl_coin = box:findChild("m_lb_coins_2")
    lbl_coin:setString(reward.value[1])
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = box,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,
            callBack = function(  )
                self.m_base_game:refreshCoin(9,true,self.m_boxs[index])
                local count = 0
                while count < 3 do
                    local box_index = (index + count) % 3
                    if box_index == 0 then
                        box_index = 3
                    end
                    if box_index ~= index then
                        box = self.m_boxs[box_index]
                        local lbl_coin = box:findChild("m_lb_coins_2")
                        
                        local params = {}
                        
                        local close_index = (reward.key + count) % 3
                        if close_index == 0 then
                            close_index = 3
                        end
                        local reward_close = self.m_rewardData[close_index]
                        lbl_coin:setString(reward_close[1])
                    
                        params[1] = {
                            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                            node = box,   --执行动画节点  必传参数
                            actionName = "over", --动作名称  动画必传参数,单延时动作可不传
                        }
                        params[2] = {
                            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                            node = box,   --执行动画节点  必传参数
                            actionName = "over_idle", --动作名称  动画必传参数,单延时动作可不传
                        }
                        util_runAnimations(params)
                    end
                    count = count + 1
                end
            end
        }
    })

    util_runAnimations({
        {
            type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            delayTime = 2,
            callBack = function(  )
                self:hideView()
            end
        }
    })
end

--[[
    点击回调
]]
function WinningFishBonusSelectView:clickFunc(sender)
    if self.m_isWaitting then
       return 
    end
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_box_click.mp3")
    self.m_isWaitting = true
    self:showReward(sender:getTag())
end

--[[
    显示界面
]]
function WinningFishBonusSelectView:showView(rewardData,showPick,callFun)
    self.m_isWaitting = false
    self:setVisible(true)
    
    local delayTime = 0
    if showPick then
        self.m_node_pick:setVisible(false)
        self.m_node_select:setVisible(true)
        gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_box_show.mp3")
        delayTime = 2
    else
        
        self.m_node_pick:setVisible(true)
        self.m_node_select:setVisible(false)
    end
    self.m_callBack = callFun
    self.m_rewardData = rewardData

    --宝箱回复状态
    for key,box in pairs(self.m_boxs) do
        box:runCsbAction("idle") 
    end
    
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            soundFile = "WinningFishSounds/sound_winningFish_box_show2.mp3",
            delayTime = delayTime
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                if not showPick then
                    self:hideView()
                end
            end,
            fps = 60
        }
    })
end

--[[
    隐藏界面
]]
function WinningFishBonusSelectView:hideView( )
    
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            soundFile = "WinningFishSounds/sound_winningFish_box_close.mp3",  --播放音效 执行动作同时播放 可选参数
            actionName = "over", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                self:setVisible(false)
                if type(self.m_callBack) == "function" then
                    self:m_callBack()
                end
            end,
            fps = 60
        }
    })
    
end

return WinningFishBonusSelectView