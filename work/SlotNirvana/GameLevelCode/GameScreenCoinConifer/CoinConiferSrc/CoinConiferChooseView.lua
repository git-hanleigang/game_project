---
--xcyy
--2018年5月23日
--CoinConiferChooseView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConiferChooseView = class("CoinConiferChooseView",util_require("Levels.BaseLevelDialog"))

local SHOW_INDEX = {1,2,3}

function CoinConiferChooseView:initUI(params)

    self:createCsbNode("CoinConifer/PickFeature.csb")
    self.m_machine = params.machine

    self.douNode = cc.Node:create()
    self:addChild(self.douNode)

    self.m_allowClick = false
    self.bagsList = {}
    self.clickIndex = 1
    self.bagOpenState = {"bluelight","greenlight","pinklight"}

    --环
    self.timeHuan = util_createAnimation("CoinConifer_tanbanhuan.csb")
    self:findChild("tanbanhuan"):addChild(self.timeHuan)
    self.timeHuan:setVisible(false)

    self:addClick(self:findChild("click_1")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("click_2")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("click_3")) -- 非按钮节点得手动绑定监听
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CoinConiferChooseView:initSpineUI()
    --树
    -- self.tree = util_spineCreate("CoinConifer_jackpot", true, true)
    -- self:findChild("Node_spine"):addChild(self.tree)
    for i = 1, 3 do
        --创建三个福袋
        local fudai = util_spineCreate("CoinConifer_fudai", true, true)
        self:findChild("fudai_"..i):addChild(fudai)
        self.bagsList[#self.bagsList + 1] = fudai
    end
end

function CoinConiferChooseView:onExit()

    CoinConiferChooseView.super.onExit(self)
    self:stopUpdate()

end

function CoinConiferChooseView:resetViewInfo(params)
    self.m_index = params.index         --服务器传的选择显示
    self.m_endFunc = params.func
    self.clickIndex = 1
    self.m_isSuper = false
    if self.m_index == 4 then
        self.m_isSuper = true
    end

    for i = 1, 3 do
        local bag = self.bagsList[i]
        if not tolua.isnull(bag) then
            util_spinePlay(bag,"actionframe_start",false)
            util_spineEndCallFunc(bag,"actionframe_start",function()
                util_spinePlay(bag,"idleframe",true)
            end)
        end
        
    end

    if not self.m_isSuper then
        --显示环
        self.timeHuan:setVisible(true)
        self.timeHuan:runCsbAction("idleframe",true)
    else
        self.timeHuan:setVisible(false)
    end
    
    --袋子重置
    self.bagOpenState = {"bluelight","greenlight","pinklight"}
end

function CoinConiferChooseView:showBagDouDong()
    local random = math.random(1,3)
    local bag = self.bagsList[random]
    if not tolua.isnull(bag) then
        util_spinePlay(bag,"idleframe2",false)
        util_spineEndCallFunc(bag,"idleframe2",function()
            util_spinePlay(bag,"idleframe",true)
        end)
    end
    performWithDelay(self.douNode,function ()
        self:showBagDouDong()
    end,3)
end

function CoinConiferChooseView:showView()
    self:findChild("choose"):setVisible(not self.m_isSuper)
    self:findChild("super1"):setVisible(self.m_isSuper)
    if self.m_isSuper then
        self:findChild("m_lb_num"):setString("")
    end
    if self.m_machine.freeType == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_choose_super)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_choose_pickOne)
    end
    
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
        if self.m_isSuper then
            self.m_allowClick = false
            self.m_machine:delayCallBack(0.5,function ()
                self:showAllBags()
            end)
        else
            self:showBagDouDong()
            self.m_allowClick = true
            self:startUpdate()
        end
    end)
end

function CoinConiferChooseView:closeView()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_hide_choose)
    self:runCsbAction("over",false,function ()
        if self.m_endFunc then
            self.m_endFunc()
        end
        self:setVisible(false)
    end)
end

function CoinConiferChooseView:showAllBags()
    self.m_allowClick = false
    local indexList = {"bluelight","greenlight","pinklight"}
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_pick_all)
    --三个福袋均打开
    for i = 1, 3 do
        local bag = self.bagsList[i]
        if not tolua.isnull(bag) then
            local skinName = indexList[i]
            bag:setSkin(skinName)
            --刷新福袋显示
            util_spinePlay(bag,"actionframe",false)
            util_spineEndCallFunc(bag,"actionframe",function()
                util_spinePlay(bag,"idleframe_actionframe",true)
            end)
        end
        
    end
    self.m_machine:delayCallBack(2.5,function ()
        self:closeView()
    end)
end

function CoinConiferChooseView:showClickBags(index)
    local bag = self.bagsList[index]
    if not tolua.isnull(bag) then
        local skinName = self:getSkinName()
        bag:setSkin(skinName)
        self:removeStateForCilck(skinName)
        self:showActSoundForIndex()
        --刷新福袋显示
        util_spinePlay(bag,"actionframe",false)
        util_spineEndCallFunc(bag,"actionframe",function()
            util_spinePlay(bag,"idleframe_actionframe",true)
        end)
    end
    
end

function CoinConiferChooseView:showActSoundForIndex()
    if self.m_index == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_pick_renewal)
    elseif self.m_index == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_pick_jackpot)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_pick_multiply)
    end
end

function CoinConiferChooseView:getSkinName()
    if self.m_index == 3 then
        return "bluelight"
    elseif self.m_index == 1 then
        return "greenlight"
    elseif self.m_index == 2 then
        return "pinklight"
    end
    return "bluelight"
end

function CoinConiferChooseView:removeStateForCilck(skinName)
    local index = nil
    for i, v in ipairs(self.bagOpenState) do
        if v == skinName then
            index = i
        end
    end
    if index then
        table.remove( self.bagOpenState, index)
    end
    
end

function CoinConiferChooseView:otherBagShowForClick()
    for i = 1, 3 do
        if i ~= self.clickIndex then
            local bag = self.bagsList[i]
            if not tolua.isnull(bag) then
                local skinName = self.bagOpenState[1] or "bluelight"
                self:removeStateForCilck(skinName)
                bag:setSkin(skinName)
                --刷新福袋显示
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_notPick_open)
                util_spinePlay(bag,"dark",false)
                util_spineEndCallFunc(bag,"dark",function()
                    util_spinePlay(bag,"dark_idle",true)
                end)
            end
            
        end
    end
end


--[[
    点击
]]
function CoinConiferChooseView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    self.douNode:stopAllActions()
    self.m_allowClick = false
    self:stopUpdate()
    local name = sender:getName()
    if name == "click_1" then
        self.clickIndex = 1
        self:showClickBags(1)
    elseif name == "click_2" then
        self.clickIndex = 2
        self:showClickBags(2)
    elseif name == "click_3" then
        self.clickIndex = 3
        self:showClickBags(3)
    end

    self.m_machine:delayCallBack(1,function ()
        --其他袋子打开
        self:otherBagShowForClick()
        self.m_machine:delayCallBack(2,function ()
            self:closeView()
        end)
    end)
    
end

--停止刷帧
function CoinConiferChooseView:stopUpdate()
    if self.m_expireALLHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireALLHandlerId)
        self.m_expireALLHandlerId = nil
    end
end

--开启刷帧：倒计时10秒
function CoinConiferChooseView:startUpdate()
    self:stopUpdate()
    local time = 10
    self:findChild("m_lb_num"):setString(time)
    self.m_expireALLHandlerId =
        scheduler.scheduleGlobal(
        function()
            time = time - 1
            self:findChild("m_lb_num"):setString(time)
            if time <= 0 then
                self.m_allowClick = false
                self:stopUpdate()
                self.douNode:stopAllActions()
                --帮玩家选择
                local random = math.random(1,3)
                if random == 1 then
                    self.clickIndex = 1
                    self:showClickBags(1)
                elseif random == 2 then
                    self.clickIndex = 2
                    self:showClickBags(2)
                else
                    self.clickIndex = 3
                    self:showClickBags(3)
                end
                self.m_machine:delayCallBack(1,function ()
                    --其他袋子打开
                    self:otherBagShowForClick()
                    self.m_machine:delayCallBack(3,function ()
                        self:closeView()
                    end)
                end)
            end
            if self.isClick then--点击了
                self:stopUpdate()
            end
        end,
        1
    )
end

function CoinConiferChooseView:showBigTreeActForChoose()
    -- self:runCsbAction("idle2")
    -- util_spinePlay(self.tree,"start_tanban",false)
    -- util_spineEndCallFunc(self.tree,"start_tanban",function()
    --     util_spinePlay(self.tree,"idle_tanban",true)
    -- end)
end


return CoinConiferChooseView