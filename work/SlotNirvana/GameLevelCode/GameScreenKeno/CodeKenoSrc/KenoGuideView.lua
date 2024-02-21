---
--smy
--2018年5月24日
--KenoGuideView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local KenoGuideView = class("KenoGuideView",util_require("base.BaseView"))

function KenoGuideView:initUI()
    self.m_guideId = 1--当前引导到第几步
    self.m_skip = false -- 是否跳过引导
    self.m_TraiNodeList = {} -- 保存已经提层的节点

    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self:createCsbNode("Keno_yindao.csb", isAutoScale)

    --添加点击
    local Panel = self:findChild("Panel_6")
    self:addClick(Panel)
    
    local Panel1 = self:findChild("Panel_1")
    self:addClick(Panel1)
    self:runCsbAction("idle",true)
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function KenoGuideView:initViewData(machine)
    self.machine = machine
    self.machine:runCsbAction("idle1",true)

    self:setScale(self.machine.m_machine.m_machineRootScale)

    self:setShowGuide()
    local nodeParent = self:findChild("Panel_1"):getParent()
    local pos = self:findChild("Panel_1"):getParent():convertToWorldSpace(cc.p(self:findChild("Panel_1"):getPosition()))
    pos = self:convertToNodeSpace(pos)

    util_changeNodeParent(self, self:findChild("Panel_1"),1000)
    self:findChild("Panel_1"):setPosition(pos.x, pos.y)
end

function KenoGuideView:onEnter()
    
end

function KenoGuideView:onExit(  )

end

-- 点击函数
function KenoGuideView:clickFunc(sender)
    
    local name = sender:getName()
    local tag = sender:getTag()   
    -- super keno 不能点击 
    if self.m_isSuperKeno then
        return
    end

    gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_click.mp3")

    if name == "Panel_6" or name == "Panel_1" then
        self.m_guideId = self.m_guideId + 1
        if self.m_guideId > 6 then
            self.machine:findChild("Button_quick"):setBright(true)
            self.machine:findChild("Button_quick"):setTouchEnabled(true)
            self.machine:findChild("Button_erase"):setBright(false)
            self.machine:findChild("Button_erase"):setTouchEnabled(false)

            self:resetKenoNode()
            self.machine:runCsbAction("idle",true)
            self.machine.m_isSetGuide = false
            self:sendData()
            self:removeFromParent()
            return
        end
        if self.m_skip then
            return
        end
        self:setShowGuide()
    elseif name == "Button_skip" then
        self:resetKenoNode()
        self.m_skip = true
        self:setShowGuide()
    elseif name == "Button_yes" then
        for i=1,10 do
            self.machine:setShowNumNode(i, 1)
        end

        self.machine:findChild("Button_quick"):setBright(true)
        self.machine:findChild("Button_quick"):setTouchEnabled(true)
        self.machine:findChild("Button_erase"):setBright(false)
        self.machine:findChild("Button_erase"):setTouchEnabled(false)

        self.machine.m_paytable_tx[5]:setVisible(false)
        -- self.machine:setShowPayTable(5,1)
        self.machine.m_paytable[5]:runCsbAction("idleframe",false)
        self:resetKenoNode()
        self.machine:runCsbAction("idle",true)
        self.machine.m_isSetGuide = false
        self:sendData()
        self:removeFromParent()
    elseif name == "Button_no" then
        self.m_skip = false
        self:setShowGuide()
    end
end

-- 根据引导步骤显示界面1
function KenoGuideView:setShowGuide( )
    for i=1,7 do
        self:findChild("Node_"..i):setVisible(false)
    end
    self:findChild("confirm"):setVisible(false)

    -- m_skip表示点击跳过
    if self.m_skip then
        self:findChild("Button_skip"):setVisible(false)
        self:findChild("confirm"):setVisible(true)
        self:findChild("Panel_1"):setVisible(false)
    else
        self:findChild("Node_"..self.m_guideId):setVisible(true)
        self:findChild("Button_skip"):setVisible(true)
        if self.m_guideId == 6 then
            self:findChild("Button_skip"):setVisible(false)
        end
        self:findChild("Panel_1"):setVisible(true)
        self:setKenoNode(self.m_guideId)
    end
end

-- keno界面上某些节点 引导的时候 提层
-- index 表示第几个引导界面
function KenoGuideView:setKenoNode(index)
    self:resetKenoNode(index)
    local node
    local setNewParentFun = function(node)
        local nodeParent = node:getParent()
        node.m_oldPreX = node:getPositionX()
        node.m_oldPreY = node:getPositionY()
        node.m_oldParent = nodeParent
        node.m_oldZOrder = node:getZOrder()
        local pos = nodeParent:convertToWorldSpace(cc.p(node.m_oldPreX, node.m_oldPreY))
        pos = self:convertToNodeSpace(pos)

        util_changeNodeParent(self, node)
        node:setPosition(pos.x, pos.y)
        table.insert( self.m_TraiNodeList, node)
    end

    if index == 1 then
        local kenoNodeName = {"Keno_Num", "Node_mid","caiqie","mujiFlyEgg", "muji_caiqie","Node_AllHit"}
        for i,vNodeName in ipairs(kenoNodeName) do
            local node = self.machine:findChild(vNodeName)
            setNewParentFun(node)
        end
        self.machine:findChild("Button_quick"):setBright(false)
        self.machine:findChild("Button_quick"):setTouchEnabled(false)

    elseif index == 2 then
        local kenoNodeName = {"Keno_Num","Node_mid","caiqie","mujiFlyEgg","muji_caiqie","Node_AllHit"}
        for i=1,10 do
            self.machine:setShowNumNode(i, 3)
        end
        
        for i,vNodeName in ipairs(kenoNodeName) do
            local node = self.machine:findChild(vNodeName)
            setNewParentFun(node)
        end
    elseif index == 3 then
        local kenoNodeName = {"Node_pay","caiqie","mujiFlyEgg","muji_caiqie","Node_AllHit"}
        for i=1,10 do
            if i > 5 then
                self.machine:setShowNumNode(i, 3)
            else
                self.machine:setShowNumNode(i, 4)
            end
        end
        
        for i,vNodeName in ipairs(kenoNodeName) do
            local node = self.machine:findChild(vNodeName)
            setNewParentFun(node)
        end
        self.machine.m_paytable_tx[5]:setVisible(true)
        -- self.machine:setShowPayTable(5,2)
        self.machine.m_paytable[5]:runCsbAction("idleframe1",false)
        for i=1,10 do
            local node = self.machine:findChild("Node_"..i)
            setNewParentFun(node)
        end
    elseif index == 4 then
        self.machine.m_paytable_tx[5]:setVisible(false)
        -- self.machine:setShowPayTable(5,1)
        self.machine:findChild("Button_erase"):setBright(true)
        self.machine:findChild("Button_erase"):setTouchEnabled(true)

        self.machine.m_paytable[5]:runCsbAction("idleframe",false)
        local kenoNodeName = {"Button_erase","caiqie","mujiFlyEgg","muji_caiqie","Node_AllHit"}
        
        for i,vNodeName in ipairs(kenoNodeName) do
            local node = self.machine:findChild(vNodeName)
            setNewParentFun(node)
        end
        
        -- 还原第三步小块的颜色改变
        for i=1,10 do
            self.machine:setShowNumNode(i, 1)
        end
    elseif index == 5 then
        self.machine:findChild("Button_erase"):setBright(false)
        self.machine:findChild("Button_erase"):setTouchEnabled(false)

        self.machine:findChild("Button_quick"):setBright(true)
        self.machine:findChild("Button_quick"):setTouchEnabled(true)

        local kenoNodeName = {"Button_quick","caiqie","mujiFlyEgg","muji_caiqie","Node_AllHit"}
        
        for i,vNodeName in ipairs(kenoNodeName) do
            local node = self.machine:findChild(vNodeName)
            setNewParentFun(node)
        end
    elseif index == 6 then
        self.machine:findChild("Button_erase"):setBright(false)
        self.machine:findChild("Button_erase"):setTouchEnabled(false)

        self.machine:findChild("Button_quick"):setBright(false)
        self.machine:findChild("Button_quick"):setTouchEnabled(false)

        local kenoNodeName = {"Keno_Num","Node_mid","caiqie","mujiFlyEgg","muji_caiqie","Node_AllHit"}
        
        for i,vNodeName in ipairs(kenoNodeName) do
            local node = self.machine:findChild(vNodeName)
            setNewParentFun(node)
        end
    end
    
    if self.m_skip then
        self:findChild("Panel_1"):setVisible(false)
    else
        self:findChild("Panel_1"):setZOrder(2000)
    end
end

-- 还原已经提层的节点
function KenoGuideView:resetKenoNode(index)
    for i,node in ipairs(self.m_TraiNodeList) do
        util_changeNodeParent(node.m_oldParent, node, node.m_oldZOrder)
        node:setPosition(node.m_oldPreX, node.m_oldPreY)
        node.m_oldPreX = nil
        node.m_oldPreY = nil
        node.m_oldParent = nil
        node.m_oldZOrder = nil
    end
    self.m_TraiNodeList = {}
end

--数据发送
function KenoGuideView:sendData()
    self.machine:setDataByKey("introFinished", true)
end

-- super keno 第一次要显示的界面
function KenoGuideView:setSuperKenoView(machine, protectLoc)
    self.machine = machine
    self.machine:runCsbAction("idle1",true)

    self:setScale(self.machine.m_machine.m_machineRootScale)

    self.m_isSuperKeno = true
    for i=1,7 do
        if i ~= 7 then
            self:findChild("Node_"..i):setVisible(false)
        end
    end
    self:findChild("confirm"):setVisible(false)
    self:findChild("Button_skip"):setVisible(false)

    local node
    local setNewParentFun = function(node)
        local nodeParent = node:getParent()
        node.m_oldPreX = node:getPositionX()
        node.m_oldPreY = node:getPositionY()
        node.m_oldParent = nodeParent
        node.m_oldZOrder = node:getZOrder()
        local pos = nodeParent:convertToWorldSpace(cc.p(node.m_oldPreX, node.m_oldPreY))
        pos = self:convertToNodeSpace(pos)

        util_changeNodeParent(self, node)
        node:setPosition(pos.x, pos.y)
        table.insert( self.m_TraiNodeList, node)
    end

    local kenoNodeName = {"Node_mid", "Keno_Num", "caiqie", "mujiFlyEgg", "muji_caiqie", "Node_AllHit"}
    for i,vNodeName in ipairs(kenoNodeName) do
        local node = self.machine:findChild(vNodeName)
        setNewParentFun(node)
    end

    self.machine:waitWithDelay(2,function()
        table.sort(protectLoc, function(a, b)
            return a < b
        end)

        for i,vSuperId in ipairs(protectLoc) do
            self.machine:waitWithDelay(0.2*(i-1),function()
                gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_egg_zhongjiang.mp3")
                self.machine:setShowNumNode(vSuperId, 4)
                table.insert(self.machine.m_zhongJiangSpin, vSuperId)
                self.machine:findChild("m_lb_hits"):setString(#self.machine.m_zhongJiangSpin)

                self.machine.m_numNode[vSuperId]:runCsbAction("start",false)
                if i == #protectLoc then
                    self.machine:waitWithDelay(0.5,function()
                        self:resetKenoNode()
                        self.machine:runCsbAction("idle",true)
                        self:removeFromParent()
                    end)
                end
            end)
        end
        
    end)
end

return KenoGuideView