---
--xcyy
--2018年5月23日
--OrcaCaptainProgressView.lua
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainProgressView = class("OrcaCaptainProgressView",util_require("Levels.BaseLevelDialog"))

local ITEM_NUM1 = 15
local ITEM_NUM2 = 10
local ITEM_NUM3 = 7
local ITEM_NUM4 = 20

function OrcaCaptainProgressView:initUI()

    self:createCsbNode("OrcaCaptain_jindutiao.csb")

    self.itemList20 = {}
    self.itemList15 = {}
    self.itemList10 = {}
    self.itemList7  = {}
    self.progressNum = 15

    self:createAllItem()
end

--创建所有item
function OrcaCaptainProgressView:createAllItem()
    --15个
    for i=1,ITEM_NUM1 do
        if i < ITEM_NUM1 then
            local item = util_createAnimation("OrcaCaptain_jindu_0.csb")
            local num1,num2 = self:getItemChildNumName(false)
            item:findChild(num1):setString(i)
            item:findChild(num2):setString(i)
            self:findChild("Node_jindu_15_"..i):addChild(item)
            item.isWild = false
            self:changeItemShow(item,false,false)
            self.itemList15[#self.itemList15 + 1] = item
        else
            local item = util_createAnimation("OrcaCaptain_jindu_wild.csb")
            self:findChild("Node_wild_15"):addChild(item)
            item.isWild = true
            self:changeItemShow(item,false,false)
            self.itemList15[#self.itemList15 + 1] = item
        end
    end
    --10个
    for i=1,ITEM_NUM2 do
        if i < ITEM_NUM2 then
            local item = util_createAnimation("OrcaCaptain_jindu_0.csb")
            local num1,num2 = self:getItemChildNumName(false)
            item:findChild(num1):setString(i)
            item:findChild(num2):setString(i)
            self:findChild("Node_jindu_10_"..i):addChild(item)
            item.isWild = false
            self:changeItemShow(item,false,false)
            self.itemList10[#self.itemList10 + 1] = item
        else
            local item = util_createAnimation("OrcaCaptain_jindu_wild.csb")
            self:findChild("Node_wild_10"):addChild(item)
            item.isWild = true
            self:changeItemShow(item,false,false)
            self.itemList10[#self.itemList10 + 1] = item
        end
    end
    --七个
    for i=1,ITEM_NUM3 do
        if i < ITEM_NUM3 then
            local item = util_createAnimation("OrcaCaptain_jindu_0.csb")
            local num1,num2 = self:getItemChildNumName(false)
            item:findChild(num1):setString(i)
            item:findChild(num2):setString(i)
            self:findChild("Node_jindu_7_"..i):addChild(item)
            item.isWild = false
            self:changeItemShow(item,false,false)
            self.itemList7[#self.itemList7 + 1] = item
        else
            local item = util_createAnimation("OrcaCaptain_jindu_wild.csb")
            self:findChild("Node_wild_7"):addChild(item)
            item.isWild = true
            self:changeItemShow(item,false,false)
            self.itemList7[#self.itemList7 + 1] = item
        end
    end
    --20个
    for i=1,ITEM_NUM4 do
        if i < ITEM_NUM4 then
            local item = util_createAnimation("OrcaCaptain_jindu_0.csb")
            local num1,num2 = self:getItemChildNumName(true)
            item:findChild(num1):setString(i)
            item:findChild(num2):setString(i)
            self:findChild("Node_jindu_20_"..i):addChild(item)
            item.isWild = false
            self:changeItemShow(item,false,true)
            self.itemList20[#self.itemList20 + 1] = item
        else
            local item = util_createAnimation("OrcaCaptain_jindu_wild.csb")
            self:findChild("Node_wild_20"):addChild(item)
            item.isWild = true
            self:changeItemShow(item,false,true)
            self.itemList20[#self.itemList20 + 1] = item
        end
    end
end

function OrcaCaptainProgressView:showItemChild(item,index,isMax)
    if not tolua.isnull(item) then
        if isMax then
            item:findChild("Node_daishouji"):setVisible(false)
            item:findChild("Node_shouji"):setVisible(false)
            item:findChild("Node_daishouji_20"):setVisible(true)
            item:findChild("Node_shouji_20"):setVisible(true)
        else
            item:findChild("Node_daishouji"):setVisible(false)
            item:findChild("Node_shouji"):setVisible(false)
            item:findChild("Node_daishouji_20"):setVisible(true)
            item:findChild("Node_shouji_20"):setVisible(true)
        end
    end
end

function OrcaCaptainProgressView:getItemChildNumName(isMax)
    if isMax then
        return "m_lb_num_3","m_lb_num_4"
    else
        return "m_lb_num_1","m_lb_num_2"
    end
end
function OrcaCaptainProgressView:getItemChildName(isMax)
    if isMax then
        return "Node_daishouji","Node_shouji"
    else
        return "Node_daishouji_20","Node_shouji_20"
    end
end

--刷新进度条显示
function OrcaCaptainProgressView:updateProgressNum(num)
    if num then
        self.progressNum = num
    end
    
    if num == 7 then
        self:findChild("Node_jindu_7"):setVisible(true)
        self:findChild("Node_jindu_10"):setVisible(false)
        self:findChild("Node_jindu_15"):setVisible(false)
        self:findChild("Node_jindu_20"):setVisible(false)
    elseif num == 10 then
        self:findChild("Node_jindu_7"):setVisible(false)
        self:findChild("Node_jindu_10"):setVisible(true)
        self:findChild("Node_jindu_15"):setVisible(false)
        self:findChild("Node_jindu_20"):setVisible(false)
    elseif num == 20 then
        self:findChild("Node_jindu_7"):setVisible(false)
        self:findChild("Node_jindu_10"):setVisible(false)
        self:findChild("Node_jindu_15"):setVisible(false)
        self:findChild("Node_jindu_20"):setVisible(true)
    else
        self:findChild("Node_jindu_7"):setVisible(false)
        self:findChild("Node_jindu_10"):setVisible(false)
        self:findChild("Node_jindu_15"):setVisible(true)
        self:findChild("Node_jindu_20"):setVisible(false)
    end
end

--触发
function OrcaCaptainProgressView:conglomerationAct()
    local time = 0
    local time2 = 0
    if self.progressNum == 7 then
        self:runCsbAction("jiman1")
        time = 25/60
        time2 = 25/60
    elseif self.progressNum == 10 then
        self:runCsbAction("jiman2")
        time = 41/60
        time2 = 45/60
    elseif self.progressNum == 20 then
        self:runCsbAction("jiman3")
        time = 41/60
        time2 = 45/60
    else
        self:runCsbAction("jiman3")
        time = 37/60
        time2 = 40/60
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_progress_wild_light)
    self:delayCallBack(time2,function ()
        self:triggerChangeBigWild()
    end)
    return time
end

--刷新item显示
function OrcaCaptainProgressView:updateItemForNum(num,isChangeBet)
    local list = {}
    local time = 0
    if self.progressNum == 7 then
        list = self.itemList7
    elseif self.progressNum == 10 then
        list = self.itemList10
    elseif self.progressNum == 20 then
        list = self.itemList20
    else
        list = self.itemList15
    end
    
    -- self:nextTriggerChangeBigWild(false)

    if num == 0 then
        if isChangeBet then
            time = self:conglomerationAct()
        end
    end
    local newNum = self.progressNum - num
    if newNum == 1 then     --重置后第一次
        self:showProgressIdle()
        local wildItem = self:getLastWildItem()
        if not tolua.isnull(wildItem) then
            wildItem:stopAllActions()
        end
        -- self:resetItemForProgressNum()
    end
    for i=1,self.progressNum do
        local item = list[i]
        local isShowSound = true
        if i <= newNum then
            
            if not tolua.isnull(item) and not item.isShow then
                self:delayCallBack(time,function ()
                    if isShowSound and isChangeBet then
                        isShowSound = false
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_progress_light)
                    end
                    local isMax = false
                    if self.progressNum == 20 then
                        isMax = true
                    end
                    self:changeItemShow(item,true,isMax)
                end)
            end
        else
            if not tolua.isnull(item) and not item.isShow then
                self:delayCallBack(time,function ()
                    local isMax = false
                    if self.progressNum == 20 then
                        isMax = true
                    end
                    self:changeItemShow(item,false,isMax)
                end)
            end
        end
    end
    
    if num == 1 and not isChangeBet then
        self:nextTriggerChangeBigWild(true)
    else
        if time == 0 then
            self:nextTriggerChangeBigWild(false)
        end
    end
end

--重置item显示
function OrcaCaptainProgressView:resetItemForProgressNum()
    local list = {}
    if self.progressNum == 7 then
        list = self.itemList7
    elseif self.progressNum == 10 then
        list = self.itemList10
    elseif self.progressNum == 20 then
        list = self.itemList20
    else
        list = self.itemList15
    end
    self:showProgressIdle()
    for i,v in ipairs(list) do
        local isMax = false
        if self.progressNum == 20 then
            isMax = true
        end
        self:changeItemShow(v,false,isMax)
    end
end

--初始化item显示
function OrcaCaptainProgressView:initItemForNum(num)
    local list = {}
    if self.progressNum == 7 then
        list = self.itemList7
    elseif self.progressNum == 10 then
        list = self.itemList10
    elseif self.progressNum == 20 then
        list = self.itemList20
    else
        list = self.itemList15
    end
    for i=1,num do
        local item = list[i]
        if not tolua.isnull(item) then
            local isMax = false
            if self.progressNum == 20 then
                isMax = true
            end
            self:changeItemShow(item,false,isMax)
        end
        
    end
end

--改变item的显示
function OrcaCaptainProgressView:changeItemShow(item,isShow,isMax)
    local shouji = item:findChild("Node_shouji")
    local daiShouji = item:findChild("Node_daishouji")
    --and not item.isWild
    if isMax then
        shouji = item:findChild("Node_shouji_20")
        daiShouji = item:findChild("Node_daishouji_20")
        item:findChild("Node_shouji"):setVisible(false)
        item:findChild("Node_daishouji"):setVisible(false)
        if item:findChild("Node_tx1") then
            item:findChild("Node_tx1"):setVisible(false)
            item:findChild("Node_tx2"):setVisible(true)
        end
        
    else
        if item:findChild("Node_tx1") then
            item:findChild("Node_tx1"):setVisible(true)
            item:findChild("Node_tx2"):setVisible(false)
        end
        
        item:findChild("Node_shouji_20"):setVisible(false)
        item:findChild("Node_daishouji_20"):setVisible(false)
    end
    
    
    if shouji and daiShouji then
        if isShow then
            item.isShow = true
            shouji:setVisible(true)
            daiShouji:setVisible(false)
        else
            item.isShow = false
            shouji:setVisible(false)
            daiShouji:setVisible(true)
        end
    end
end

function OrcaCaptainProgressView:getLastWildItem()
    local list = {}
    if self.progressNum == 7 then
        list = self.itemList7
    elseif self.progressNum == 10 then
        list = self.itemList10
    elseif self.progressNum == 20 then
        list = self.itemList20
    else
        list = self.itemList15
    end
    for i,v in ipairs(list) do
        if v.isWild then
            return v
        end
    end
    return nil
end

function OrcaCaptainProgressView:triggerChangeBigWild()
    local item = self:getLastWildItem()
    if not tolua.isnull(item) then
        item:stopAllActions()
        item:runCsbAction("idle")
        item:runCsbAction("start2")
        performWithDelay(item,function ()
            item:runCsbAction("idle2",true)
        end,28/60)
    end
end

function OrcaCaptainProgressView:triggerChangeBigWildOver()
    local item = self:getLastWildItem()
    if not tolua.isnull(item) then
        item:stopAllActions()
        item:runCsbAction("over2")
    end
end

function OrcaCaptainProgressView:nextTriggerChangeBigWild(isShow)
    local item = self:getLastWildItem()
    if not tolua.isnull(item) then
        item:stopAllActions()
        if isShow then
            item:runCsbAction("idle3",true)
        else
            item:runCsbAction("idle",true)
        end
        
    end
end

function OrcaCaptainProgressView:showProgressIdle()
    if self.progressNum == 7 then
        self:runCsbAction("idle1",true)
    elseif self.progressNum == 10 then
        self:runCsbAction("idle2",true)
    elseif self.progressNum == 20 then
        self:runCsbAction("idle3",true)
    else
        self:runCsbAction("idle3",true)
    end
end

--[[
    延迟回调
]]
function OrcaCaptainProgressView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return OrcaCaptainProgressView