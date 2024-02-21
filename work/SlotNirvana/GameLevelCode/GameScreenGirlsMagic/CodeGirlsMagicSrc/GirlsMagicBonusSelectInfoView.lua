---
--smy
--2018年4月26日
--GirlsMagicBonusSelectInfoView.lua

local BaseView = util_require("base.BaseView")
local GirlsMagicBonusSelectInfoView = class("GirlsMagicBonusSelectInfoView",BaseView)

--当前匹配提示文字
local TIP_CUR_MATCH = {
    {node = "color",sound = "GirlsMagicSounds/sound_GirlsMagic_match_color.mp3"},
    {node = "accessory",sound = "GirlsMagicSounds/sound_GirlsMagic_match_accessory.mp3"},
    {node = "pattern",sound = "GirlsMagicSounds/sound_GirlsMagic_match_pattern.mp3"},
}

function GirlsMagicBonusSelectInfoView:initUI(params)
    self:createCsbNode("GirlsMagic_PlayerDress.csb")
    --主类对象
    self.m_machine = params.machine
    util_setCascadeOpacityEnabledRescursion(self,true)

    self.m_node_heads = {}
    self.m_node_suits = {}
    self.m_playerItems = {}
    self.m_suitItems = {}   --衣服动画
    for index = 1,8 do
        local node_head = self:findChild("Node_Player_"..index)
        node_head:removeAllChildren(true)
        self.m_node_heads[index] = node_head

        local item = util_createView("CodeGirlsMagicSrc.GirlsMagicPlayerItem")
        node_head:addChild(item)
        self.m_playerItems[index] = item
        item:resetStatus()

        local node_suit = self:findChild("Node_dress_"..index)
        node_suit:removeAllChildren(true)
        self.m_node_suits[index] = node_suit

        local suitItem = util_createView("CodeGirlsMagicSrc.GirlsMagicDressItem",{spineManager = self.m_machine.m_spineManager,parentNode = node_suit})
        node_suit:addChild(suitItem)
        self.m_suitItems[index] = suitItem
    end
    
    self.m_lb_num = self:findChild("m_lb_times")
    self:showTip(-1)
end

function GirlsMagicBonusSelectInfoView:onEnter()
    BaseView.onEnter(self)
end
function GirlsMagicBonusSelectInfoView:onExit()
    BaseView.onExit(self)
end

--[[
    刷新当前次数
]]
function GirlsMagicBonusSelectInfoView:changeLeftTimes(curTime,totalTimes)
    local str = curTime.."/"..totalTimes
    self.m_lb_num:setString(str)
end

function GirlsMagicBonusSelectInfoView:showTip(matchIndex)
    for index = 1,3 do
        self:findChild(TIP_CUR_MATCH[index].node):setVisible(matchIndex == index)
        if matchIndex == index then
            gLobalSoundManager:playSound(TIP_CUR_MATCH[index].sound)
        end
    end
    self.m_lb_num:setVisible(matchIndex == -1)
    self:findChild("GirlsMagic_spin_5"):setVisible(matchIndex == -1)
end

--[[
    开启定时刷新函数
]]
function GirlsMagicBonusSelectInfoView:startSchdule()
    self.m_refreshTime = 0
    --清空之前的房间数据
    self:setRoomData(nil)
    self:clearHead()
    local roomData = self.m_machine:getRoomData()

    if roomData.result then
        --深拷贝房间数据,防止刷新数据时结果发生变化
        local roomData = clone(self.m_machine.m_roomData:getRoomData())
        local players = clone(self.m_machine.m_roomData:getRoomPlayersInfo())
        

        self:setRoomData(roomData)

        --接收到result消息后,roomData的selects字段可能因为超时被后端清空,所以要用result里的selects字段刷新一次头像信息
        self:refreshPlayerhead(roomData.result.data.selects)

        self:showClothAni(roomData.result.data.selects,function(  )
            if type(self.m_callBack) == "function" then
                self.m_callBack(roomData)
            end
        end)
    end
end

--[[
    设置回调函数
]]
function GirlsMagicBonusSelectInfoView:setCallBack(func)
    self.m_callBack = func
end

--[[
    显示界面
]]
function GirlsMagicBonusSelectInfoView:showView()
    self:setVisible(true)
    self:clearCloth()
    self:setPositionY(display.height / 2)
    self:showTip(-1)
    self:runCsbAction("start",false,function(  )
        if not self.m_roomData then
            self:runCsbAction("idle1",true)
        end
    end)
end

--[[
    开始动画
]]
function GirlsMagicBonusSelectInfoView:startAni(func)
    self.m_machine:delayCallBack((325 - 245) / 60,function(  )
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_bonus_go.mp3")
    end)
    self:setPositionY(display.height / 2)
    self:showTip(-1)
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idle2")
        self.m_machine:delayCallBack(1,function(  )
            if type(func) == "function" then
                func()
            end
        end)
    end)
end

--[[
    界面向下动作
]]
function GirlsMagicBonusSelectInfoView:downAni(func)
    -- self:runCsbAction("over3",false,function(  )
    --     self:runCsbAction("idle4")
    --     if type(func) == "function" then
    --         func()
    --     end
    -- end)
    self:showTip(-1)
    self:runCsbAction("idle4")
    self:setPositionY(display.height / 2 * self.m_machine.m_machineRootScale)
    if type(func) == "function" then
        func()
    end
end

--[[
    显示阴影
]]
function GirlsMagicBonusSelectInfoView:showShadow()
    for k,suitItem in pairs(self.m_suitItems) do
        suitItem:showShadow()
    end
end

--[[
    界面向上动作
]]
function GirlsMagicBonusSelectInfoView:upAni(func)
    -- self:runCsbAction("start3",false,function(  )
    --     self:runCsbAction("idle3")
    --     if type(func) == "function" then
    --         func()
    --     end
    -- end)
    self:showTip(-1)
    self:runCsbAction("idle3")
    self:setPositionY(display.height / 2 * self.m_machine.m_machineRootScale)
    if type(func) == "function" then
        func()
    end
end

--[[
    完全匹配动画
]]
function GirlsMagicBonusSelectInfoView:fullMatchAni(matchUdids,curSpinIndex,func)
    local fullSuits = {}
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_mutiples_x3.mp3")
    for k,udid in pairs(matchUdids) do
        for k,item in pairs(self.m_playerItems) do
            if udid == item:getPlayerID() then
                item:fullMatchAni(self.m_roomData.result.data.userExtraMultiples[curSpinIndex][udid])
            end
        end

        --衣服要亮起
        for index,suitItem in pairs(self.m_suitItems) do
            if suitItem.m_udid == udid then
                --颜色匹配动画
                suitItem:hideShadow()
                fullSuits[#fullSuits + 1] = suitItem
                break
            end
        end
    end

    self.m_machine:delayCallBack(2,function(  )
        for k,suitItem in pairs(fullSuits) do
            suitItem:showShadow()
        end
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    获取自己的头像节点
]]
function GirlsMagicBonusSelectInfoView:getSelfHeadNode()
    for k,item in pairs(self.m_playerItems) do
        if globalData.userRunData.userUdid == item:getPlayerID() then
            return item
        end
    end
end

--[[
    配饰匹配动画
]]
function GirlsMagicBonusSelectInfoView:matchAni(matchType,matchUdids,curSpinIndex,func)
    local result = self.m_roomData.result.data

    local temp1,temp2 = {},{}
    for index,suitItem in pairs(self.m_suitItems) do
        temp1[index] = suitItem.m_udid
    end

    local matchIndex = 1
    if matchType == "bag" then
        matchIndex = 2
    elseif matchType == "pattern" then
        matchIndex =3
    end

    self:showTip(matchIndex)
    
    --头像缩放动画
    for k,item in pairs(self.m_playerItems) do
        temp2[k] = item:getPlayerID()
    end
    self.m_machine:delayCallBack(1.33,function(  )
        gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_mutiples_show.mp3")
    end)
    
    for k,udid in pairs(matchUdids) do
        for index,suitItem in pairs(self.m_suitItems) do
            if suitItem.m_udid == udid then
                --匹配动画
                suitItem:matchAni(matchType)
                break
            end
        end
        
        --头像缩放动画
        for k,item in pairs(self.m_playerItems) do
            if udid == item:getPlayerID() then
                performWithDelay(item,function(  )
                    local multipes_ex = 0
                    if result.userExtraMultiples[curSpinIndex] and result.userExtraMultiples[curSpinIndex][udid] then
                        multipes_ex = result.userExtraMultiples[curSpinIndex][udid]
                    end
                    local multipes_suit = result.suitMultiple[matchIndex] or 0

                    item:showMultipleAni(multipes_ex * multipes_suit)
                end,1.33)
                
            end
        end
    end
    
    self.m_machine:delayCallBack(3.5,function(  )
        for k,udid in pairs(matchUdids) do
            for k,item in pairs(self.m_playerItems) do
                if udid == item:getPlayerID() then
                    --等待进度条涨完再隐藏乘倍标签
                    self.m_machine:delayCallBack(0.3,function(  )
                        item:hideMutilpleAni()
                    end)
                end
            end
        end

        if type(func) == "function" then
            func()
        end
    end)
end


--[[
    设置房间数据
]]
function GirlsMagicBonusSelectInfoView:setRoomData(roomData)
    self.m_roomData = roomData
end

--[[
    隐藏界面
]]
function GirlsMagicBonusSelectInfoView:hideView( )
    self:setVisible(false)
end

--[[
    刷新玩家头像
]]
function GirlsMagicBonusSelectInfoView:refreshPlayerhead(selects,players)
    for index = 1, 8 do
        local node_head = self.m_node_heads[index]
        
        self.m_playerItems[index]:resetStatus()
        if selects[index] then
            if (not selects[index].head or selects[index].head == "") and players then
                for k,playerInfo in pairs(players) do
                    if selects[index].udid == playerInfo.udid then
                        selects[index].head = playerInfo.head
                        selects[index].facebookId = playerInfo.facebookId
                        break
                    end
                end
            end
            
            local item = self.m_playerItems[index]
            item:setVisible(true)
            item:runCsbAction("idle")
            
            --刷新头像
            item:refreshData(selects[index])
            item:refreshHead()
        else
            --创建头像
            local item = self.m_playerItems[index]
            item:setVisible(true)
            item:refreshData(nil)
            item:runCsbAction("idle3",true)
        end
    end
end

--[[
    清除玩家头像
]]
function GirlsMagicBonusSelectInfoView:clearHead( )
    for index = 1, 8 do
        self.m_playerItems[index]:setVisible(false)
    end
end

--[[
    显示玩家衣服
]]
function GirlsMagicBonusSelectInfoView:showClothAni(selects,func)
    if self.m_machine.m_bonusView.m_isEnd then
        return
    end
    for index = 1,8 do
        if selects[index] then
            local choose = selects[index].chooses
            local udid = selects[index].udid
            self.m_suitItems[index]:setDressInfo(choose,udid)
        end
    end
    
    self:runCsbAction("idle")
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_all_clothes.mp3")
    self:showNextClothAni(1,func)
end

--[[
    清空衣服
]]
function GirlsMagicBonusSelectInfoView:clearCloth( )
    for index = 1,8 do
        self.m_suitItems[index]:clearCloth()
    end
end

--[[
    显示下一个衣服动画
]]
function GirlsMagicBonusSelectInfoView:showNextClothAni(index,func)
    if self.m_machine.m_bonusView.m_isEnd then
        return
    end
    --从中间开始显示
    local suitItem1,suitItem2
    if index == 1 then
        suitItem1,suitItem2 = self.m_suitItems[4],self.m_suitItems[5]
    elseif index == 2 then
        suitItem1,suitItem2 = self.m_suitItems[3],self.m_suitItems[6]
    elseif index == 3 then
        suitItem1,suitItem2 = self.m_suitItems[2],self.m_suitItems[7]
    else
        suitItem1,suitItem2 = self.m_suitItems[1],self.m_suitItems[8]
    end

    suitItem1:showAni()
    suitItem2:showAni()

    if index >= 4 then
        if type(func) == "function" then
            func()
        end
        return
    end
    self.m_machine:delayCallBack(0.17,function(  )
        self:showNextClothAni(index + 1,func)
    end)
    
end

return GirlsMagicBonusSelectInfoView