---
--xcyy
--2018年5月23日
--AtlantisFreespinColloction.lua

local AtlantisFreespinColloction = class("AtlantisFreespinColloction",util_require("base.BaseView"))

local TAG_LIGHT_EFFECT  =   1001    --item光圈

function AtlantisFreespinColloction:initUI()

    self:createCsbNode("FreeGames_Atlantis.csb")

    self.m_node_bonus = {}
    self.m_bonus_item = {}
    for index=1,15 do
        local node = self:findChild("Node_"..(index - 1))
        self.m_node_bonus[index] = node

        local bonus = util_createAnimation("Bonus_Atlantis.csb")
        node:addChild(bonus)
        self.m_bonus_item[index] = bonus
    end

    --两侧金色雕塑
    self.m_statue_1 = util_spineCreate("GoldMan_Atlantis", true, true)
    self:findChild("Atlantis_freeshixiang_left"):addChild(self.m_statue_1)
    self.m_statue_2 = util_spineCreate("GoldMan_Atlantis", true, true)
    self:findChild("Atlantis_freeshixiang_right"):addChild(self.m_statue_2)

    self.m_super_tip = util_createAnimation("SuperFreeGames_Atlantis_shuoming.csb")
    self:findChild("SuperFree_shuoming"):addChild(self.m_super_tip)
    self.m_super_tip:setVisible(false)
end


function AtlantisFreespinColloction:onEnter()
    
end

function AtlantisFreespinColloction:onExit()

end

--[[
    开始动画
]]
function AtlantisFreespinColloction:showAni(isSuperFs,func)
    self:setVisible(true)
    --重置界面
    self:resetUI()
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        soundFile = "AtlantisSounds/sound_Atlantis_chessboard_up.mp3",
        fps = 60,    --帧率  可选参数
        callBack = function(  )
            self:findChild("Atlantis_freedi"):removeAllChildren(true)
            self:idleAni()
            if isSuperFs then
                self.m_super_tip:setVisible(true)
                self.m_super_tip:runCsbAction("start",false,function(  )
                    self.m_super_tip:runCsbAction("idleframe",true)
                end)
            end
            if type(func) == "function" then
                func()
            end
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    --添加粒子
    local particle = util_createAnimation("UpReelPaoPao_Atlantis.csb")
    self:findChild("Node_1"):addChild(particle)
    particle:findChild("paopao_lizi"):resetSystem()

    --两侧雕像执行动作
    local params1 = {}
    params1[1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_statue_1,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            util_spinePlay(self.m_statue_1,"idle")
        end,   --回调函数 可选参数
    }
    util_runAnimations(params1)

    local params2 = {}
    params2[1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_statue_2,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            util_spinePlay(self.m_statue_2,"idle")
        end,   --回调函数 可选参数
    }
    util_runAnimations(params2)
end

--[[
    结束动画
]]
function AtlantisFreespinColloction:hideAni(func)
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self,   --执行动画节点  必传参数
        actionName = "over", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  )
            self.m_super_tip:setVisible(false)
            self:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
end

--[[
    隐藏superfree标签
]]
function AtlantisFreespinColloction:hideSuperTip( )
    self.m_super_tip:setVisible(false)
end

--[[
    idle静帧
]]
function AtlantisFreespinColloction:idleAni()
    self:runCsbAction("idle")
end

--[[
    重连显示superfs
]]
function AtlantisFreespinColloction:showSuperFsTipIdle( )
    self.m_super_tip:setVisible(true)
    self.m_super_tip:runCsbAction("idleframe",true)
end

--[[
    刷新界面
]]
function AtlantisFreespinColloction:refreshUI(data)
    local count = #data.multiplies

    --显示bonus
    for index=1,15 do
        local item = self:getNodeByIndex(index)
        item:findChild("xuanzhong"):removeAllChildren(true)
        item:findChild("di_1"):setVisible(false)
        
        if count >= index then
            item:runCsbAction("idleframe2")
            --金币标签
            local lbl_coin = item:findChild("m_lb_coins")
            --倍数标签
            local lbl_multiplied = item:findChild("chengbei")
            if data.freeWinCoins and data.freeWinCoins[index] ~= nil then
                local coinNum = util_formatCoins(tonumber(data.freeWinCoins[index]), 3)
                lbl_coin:setString(coinNum)

                if tonumber(data.freeWinCoins[index]) == 0 then --未中奖
                    self:unRewardAni(index)
                    lbl_coin:setVisible(false)
                    lbl_multiplied:setVisible(true)
                else
                    lbl_coin:setVisible(true)
                    item:findChild("di_1"):setVisible(true)
                    lbl_multiplied:setVisible(false)
                end
            else
                lbl_coin:setVisible(false)
                lbl_multiplied:setVisible(true)
            end
            
            lbl_multiplied:setString(data.multiplies[index].."X")

            self:updateLabelSize({label=lbl_multiplied,sx=0.3,sy=0.3},268)
            self:updateLabelSize({label=lbl_coin,sx=0.27,sy=0.27},315)
        else
            item:runCsbAction("idleframe1")
        end
    end
end

--[[
    重置界面
]]
function AtlantisFreespinColloction:resetUI()
    for index=1,15 do
        local item = self.m_bonus_item[index]
        item:runCsbAction("idleframe1")
        item:findChild("xuanzhong"):removeAllChildren(true)
    end
end

--[[
    获取节点 飞粒子动效用
]]
function AtlantisFreespinColloction:getNodeByIndex(index)
    if index > 15 then
        return self.m_bonus_item[1]
    end
    return self.m_bonus_item[index]
end

--[[
    播放激活动画
]]
function AtlantisFreespinColloction:activeAni(index,data)
    local item = self.m_bonus_item[index]
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = item,   --执行动画节点  必传参数
        actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  )
            item:runCsbAction("idleframe2")
            --金币标签
            local lbl_coin = self.m_bonus_item[index]:findChild("m_lb_coins")
            --倍数标签
            local lbl_multiplied = self.m_bonus_item[index]:findChild("chengbei")
            lbl_coin:setVisible(false)
            item:findChild("di_1"):setVisible(false)
            lbl_multiplied:setVisible(true)
            
            lbl_multiplied:setString(data.multiplies[index].."X")

            self:updateLabelSize({label=lbl_multiplied,sx=0.3,sy=0.3},268)
            self:updateLabelSize({label=lbl_coin,sx=0.27,sy=0.27},315)
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
end

--[[
    当前item动画
]]
function AtlantisFreespinColloction:runCurItemAni(curIndex)
    for index=1,15 do
        local item = self:getNodeByIndex(index)
        item:findChild("xuanzhong"):removeAllChildren(true)
        
        if curIndex == index then
            local light = util_createAnimation("Bonus_Atlantis_0.csb")
            item:findChild("xuanzhong"):addChild(light,1000)
            light:runCsbAction("actionframe",true)

            item:runCsbAction("xuanzhong1",false,function(  )
                item:runCsbAction("actionframe2",true)
            end)
        end
    end
end

--[[
    未中奖动画
]]
function AtlantisFreespinColloction:unRewardAni(curIndex)
    local item = self:getNodeByIndex(curIndex)
    item:runCsbAction("idleframe3")
end

--[[
    中奖动画
]]
function AtlantisFreespinColloction:rewardAni(curIndex,data)
    local item = self:getNodeByIndex(curIndex)
    item:runCsbAction("idleframe2")
    --金币标签
    local lbl_coin = item:findChild("m_lb_coins")
    --倍数标签
    local lbl_multiplied = item:findChild("chengbei")
    lbl_coin:setVisible(true)
    lbl_multiplied:setVisible(false)
    item:findChild("di_1"):setVisible(true)

    local coinNum = util_formatCoins(tonumber(data.freeWinCoins[curIndex]), 3)
    lbl_coin:setString(coinNum)

    self:updateLabelSize({label=lbl_multiplied,sx=0.3,sy=0.3},268)
    self:updateLabelSize({label=lbl_coin,sx=0.27,sy=0.27},315)

    local effect = util_createAnimation("Bonus_Atlantis_1.csb")
    item:addChild(effect)
    effect:runCsbAction("actionframe",false,function(  )
        effect:removeFromParent(true)
    end)
end

return AtlantisFreespinColloction