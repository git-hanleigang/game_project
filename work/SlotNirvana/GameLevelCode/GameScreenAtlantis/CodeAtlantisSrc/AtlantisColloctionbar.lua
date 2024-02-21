---
--xcyy
--2018年5月23日
--AtlantisColloctionbar.lua

local AtlantisColloctionbar = class("AtlantisColloctionbar",util_require("base.BaseView"))

local TAG_EXPLAIN       =       1001    --收集条说明

AtlantisColloctionbar.m_collot_count = 0
function AtlantisColloctionbar:initUI(params)

    self:createCsbNode("SuperFreeCollect_Atlantis.csb")
    self:idleAni()

    self:initMachine(params.machine)

    --位置节点
    self.m_ary_node_pos = {}
    self.m_items = {}
    for index=1,10 do
        self.m_ary_node_pos[index] = self:findChild("Node_"..(index - 1))
        local item = util_createAnimation("CollectBonus_Atlantis.csb")
        self.m_ary_node_pos[index]:addChild(item)
        item:findChild("Atlantis_superfree01"):setVisible(false)
        self.m_items[index] = item
    end

    --添加点击回调
    self:addClick(self:findChild("Button_1"))
    --添加提示
    self:addTips()
    performWithDelay(self,function(  )
        self:removeTips()
    end,4)
end

function AtlantisColloctionbar:onEnter()
    
end

function AtlantisColloctionbar:onExit()
 
end

function AtlantisColloctionbar:initMachine(machine)
    self.m_machine = machine
end

function AtlantisColloctionbar:clickFunc(sender)
    --防止快速连续点击
    if self.m_isWaitting then
        return
    end
    --添加说明节点
    local node_tips = self.m_machine:findChild("tips")

    self.m_isWaitting = true
    local item_explain = node_tips:getChildByTag(TAG_EXPLAIN)

    --判断说明是否已经显示
    if item_explain then
        self:removeTips()
    else
        self:addTips()
        
    end
end

function AtlantisColloctionbar:removeTips(func)
    local node_tips = self.m_machine:findChild("tips")
    local item_explain = node_tips:getChildByTag(TAG_EXPLAIN)
    if self.m_isRemoving then
        return
    end

    self.m_isRemoving = true

    --判断说明是否已经显示
    if item_explain then
        item_explain:runCsbAction("over",false,function(  )
            node_tips:removeAllChildren(true)
            self.m_isWaitting = false
            self.m_isRemoving = false
            if type(func) == "function" then
                func()
            end
        end)
    else
        node_tips:removeAllChildren(true)
        self.m_isWaitting = false
        self.m_isRemoving = false
        if type(func) == "function" then
            func()
        end
    end
    
end

function AtlantisColloctionbar:addTips()
    if self.m_machine:getGameSpinStage( ) > IDLE then
        self.m_isWaitting = false
        return
    end
    --添加说明节点
    local node_tips = self.m_machine:findChild("tips")
    local item_explain = util_createAnimation("Tips_Atlantis.csb")
    node_tips:addChild(item_explain)
    item_explain:setTag(TAG_EXPLAIN)
    
    item_explain:runCsbAction("start",false,function(  )
        -- item_explain:runCsbAction("idleframe")
        self.m_isWaitting = false
    end)
end

--[[
    设置界面是否显示
]]
function AtlantisColloctionbar:setShow(isShow)
    local node_tips = self.m_machine:findChild("tips")
    node_tips:removeAllChildren(true)
    self.m_isWaitting = false
    self:setVisible(isShow)
    -- self:removeTips(function ( )
    --     self:setVisible(isShow)
    -- end)
end

--[[
    更新进度条
]]
function AtlantisColloctionbar:updateBar(count)
    for index=1,10 do
        local item = self.m_items[index]
        if count >= index then
            item:runCsbAction("idleframe1")
        else
            item:runCsbAction("idleframe")
        end
    end
    self.m_collot_count = count
end

--[[
    收集动画
]]
function AtlantisColloctionbar:colloctionAni(count,func)
    if count > self.m_collot_count then
        for index = self.m_collot_count + 1,count do
            local item_index = index
            --数据安全范围限定
            if item_index > 10 then
                item_index = 10
            end
            local item = self.m_items[item_index]
            local params = {}
            params[1] = {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = item,   --执行动画节点  必传参数
                actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    item:runCsbAction("idleframe1")
                    if type(func) == "function" then
                        func()
                    end
                end
            }
            --执行动画
            util_runAnimations(params)
        end
    end

    self.m_collot_count = count
end

--[[
    集满动画
]]
function AtlantisColloctionbar:colloctFullAni(func)
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self,   --执行动画节点  必传参数
        soundFile = "AtlantisSounds/sound_Atlantis_superFs_trigger.mp3",
        actionName = "jiman", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  )
            self:idleAni()
            if type(func) == "function" then
                func()
            end
        end
    }
    --执行动画
    util_runAnimations(params)
end

function AtlantisColloctionbar:idleAni( )
    self:runCsbAction("idle")
end


return AtlantisColloctionbar