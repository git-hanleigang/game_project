---
--smy
--2018年4月18日
--CatchMonstersWheelView.lua
local PublicConfig = require "CatchMonstersPublicConfig"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local CatchMonstersWheelView = class("CatchMonstersWheelView", BaseGame)
CatchMonstersWheelView.m_curShowWheelType = 1 --当前显示转盘类型 1普通 2super

local MAX_WHEEL_COUNT   =   16  -- 转盘区域数
local ITEM_BG = {"Node_maxspin", "Node_free_10", "Node_free_12", "Node_free_15", "Node_free_20", "Node_grand", "Node_epic"}
local ALL_ITEM_BG = {"Node_maxspin", "Node_free_10_15", "Node_free_20", "Node_grand", "Node_epic", "Node_shuziCoins"}
local ALL_ITEM_BG_NODE = {"maxspin", "freegame", "free_20", "grand", "epic"}

--转盘转动方向
local DIRECTION = {
    CLOCK_WISE = 1,             --顺时针
    ANTI_CLOCK_WISH = -1,       --逆时针
}

function CatchMonstersWheelView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("CatchMonsters_WheelFeature.csb")

    self:createWheelView()
    self:createWheelSymbol()

    self.m_endIndex = 0
    self:createWheelNode()
end

--[[
    创建转盘
]]
function CatchMonstersWheelView:createWheelNode()
    local params = {
        doneFunc = handler(self,self.wheelDown),        --停止回调
        rotateNode = self.m_wheelNode:findChild("Node_wheel"),      --需要转动的节点
        sectorCount = MAX_WHEEL_COUNT,     --总的扇面数量
        direction = DIRECTION.CLOCK_WISE,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 10,      --最小速度(每秒转动的角度)
        maxSpeed = 600,     --最大速度(每秒转动的角度)
        accSpeed = 400,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 80,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 2,         --开始减速前转动的圈数
        minDistance = 36,   --以最小速度行进的距离
        backDistance = 2,    --回弹距离
        backTime = 1.5    --回弹时间
    }
    self.m_wheel_node = util_require("Levels.BaseReel.BaseWheelNew"):create(params)
    self:addChild(self.m_wheel_node)
end

--[[
    创建转盘界面
]]
function CatchMonstersWheelView:createWheelView( )
    -- wheel转盘
    self.m_wheelNode = util_createAnimation("CatchMonsters_Wheel.csb")
    self:findChild("Node_wheel"):addChild(self.m_wheelNode)
    self.m_wheelNode:runCsbAction("idle", true)

    -- 转盘上的点击区域
    self.m_wheelPanelSpin = util_createView("CatchMonstersSrc.CatchMonstersPanelSpin", self)
    self.m_wheelNode:findChild("Node_panel"):addChild(self.m_wheelPanelSpin)
    self.m_wheelPanelSpin:setVisible(false)

    -- 转盘中间的指针
    self.m_pointerNode = util_createAnimation("CatchMonsters_Wheel_pointer.csb")
    self:findChild("Node_wheel_pointer"):addChild(self.m_pointerNode)
    self.m_pointerNode:runCsbAction("idle", true)

    -- 中奖时候 指针上的动画
    self.m_pointerTXNode = util_createAnimation("CatchMonsters_Wheel_pointer_tx.csb")
    self.m_pointerNode:findChild("Node_tx"):addChild(self.m_pointerTXNode)
    self.m_pointerTXNode:setVisible(false)

    -- 按钮
    self.m_buttonNode = util_createAnimation("CatchMonsters_wheel_button.csb")
    self:findChild("Node_off"):addChild(self.m_buttonNode)

    -- 按钮 动画
    self.m_buttonEffectNode = util_createAnimation("CatchMonsters_wheel_button_0.csb")
    self:findChild("Node_wheel_pointer"):addChild(self.m_buttonEffectNode)
    self.m_buttonEffectNode:setPosition(util_convertToNodeSpace(self.m_buttonNode:findChild("Node_on"), self:findChild("Node_wheel_pointer")))
    self.m_buttonEffectNode:runCsbAction("idle", true)
    self.m_buttonEffectNode:setVisible(false)

    -- 履带
    self.m_lvDaiSpine = util_spineCreate("CatchMonsters_WheelFeature_lvdai", true, true)
    self:findChild("Node_lvdai"):addChild(self.m_lvDaiSpine)
    util_spinePlay(self.m_lvDaiSpine, "idle1")

    -- 履带上的人物
    self.m_roleSpine = util_spineCreate("Socre_CatchMonsters_WheelBonus", true, true)
    self:findChild("Node_juese"):addChild(self.m_roleSpine)
    self.m_roleSpine:setVisible(false)
end

function CatchMonstersWheelView:createWheelSymbol()
    self.m_bigWheelNode = {}

    for i = 1, MAX_WHEEL_COUNT, 1 do
        local symbolNode = util_createAnimation("CatchMonsters_Wheel_shanxing.csb")
        self.m_wheelNode:findChild("Node_"..i):addChild(symbolNode)
        self.m_bigWheelNode[#self.m_bigWheelNode+1] = symbolNode

        symbolNode.m_rewardNode = {}
        symbolNode.m_zhongjiangNode = {}
        for _index, _bgName in ipairs(ALL_ITEM_BG) do
            symbolNode.m_zhongjiangNode[_bgName] = util_createAnimation("CatchMonsters_Wheel_zhongjiang.csb")
            symbolNode:findChild(_bgName.."1"):addChild(symbolNode.m_zhongjiangNode[_bgName])
            symbolNode.m_zhongjiangNode[_bgName]:setVisible(false)

            if _bgName ~= "Node_shuziCoins" then
                symbolNode.m_rewardNode[_bgName] = util_createAnimation("CatchMonsters_Wheel_neirong.csb")
                symbolNode:findChild(ALL_ITEM_BG_NODE[_index]):addChild(symbolNode.m_rewardNode[_bgName])
            end

            if _bgName == "Node_grand" then
                symbolNode.m_rewardNode[_bgName].m_grandSpine = util_spineCreate("Socre_CatchMonsters_7", true, true)
                symbolNode.m_rewardNode[_bgName]:findChild("Node_spine1"):addChild(symbolNode.m_rewardNode[_bgName].m_grandSpine)
                util_spinePlay(symbolNode.m_rewardNode[_bgName].m_grandSpine, "idleframe2", true)
            elseif _bgName == "Node_epic" then
                symbolNode.m_rewardNode[_bgName].m_epicSpine = util_spineCreate("Socre_CatchMonsters_8", true, true)
                symbolNode.m_rewardNode[_bgName]:findChild("Node_spine2"):addChild(symbolNode.m_rewardNode[_bgName].m_epicSpine)
                util_spinePlay(symbolNode.m_rewardNode[_bgName].m_epicSpine, "idleframe2", true)
            elseif _bgName == "Node_shuziCoins" then
                symbolNode.m_coinsNode = {}
                for indexMax = 2, 12 do
                    for index = 1, indexMax do
                        symbolNode.m_coinsNode[index.."_"..indexMax] = util_createAnimation("CatchMonsters_zhuanpan_zi.csb")
                        symbolNode:findChild("Node_"..index.."_"..indexMax):addChild(symbolNode.m_coinsNode[index.."_"..indexMax])
                        util_setCascadeOpacityEnabledRescursion(symbolNode:findChild("Node_"..index.."_"..indexMax), true)
                        util_setCascadeColorEnabledRescursion(symbolNode:findChild("Node_"..index.."_"..indexMax), true)
                    end
                end
            end
        end
    end
end

--[[
    刷新钱数
]]
function CatchMonstersWheelView:updateSymbolCoins(_index, _mul)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local score = util_formatCoinsLN(_mul * curBet / self.m_machine.m_specialBetMulti[self.m_machine.m_iBetLevel + 1], 4, true)
    local coinsList = {}
    for _subNum = 1, string.len(score) do
       table.insert(coinsList, string.sub(score, _subNum, _subNum)) 
    end
    for _nodeIndex = 2, 12 do
        self.m_bigWheelNode[_index]:findChild("Node_shuzi_".._nodeIndex):setVisible(false)
    end
    local coinCur = #coinsList
    if #coinsList > 12 then
        coinCur = 12
        self.m_bigWheelNode[_index]:findChild("Node_shuzi_12"):setVisible(true)
    else
        if #coinsList == 0 then
            coinCur = 1
        end
        self.m_bigWheelNode[_index]:findChild("Node_shuzi_"..coinCur):setVisible(true)
    end

    for _nodeIndex, _str in ipairs(coinsList) do
        if _nodeIndex <= 12 then
            self.m_bigWheelNode[_index]:findChild("Node_".._nodeIndex.."_"..coinCur):setVisible(true)
            self.m_bigWheelNode[_index].m_coinsNode[_nodeIndex.."_"..coinCur]:findChild("m_lb_coins"):setString(_str)
        end
    end
end

--[[
    转盘开始 动画
]]
function CatchMonstersWheelView:wheelStart()
    local bonusDate = self.m_machine.m_runSpinResultData.p_rsExtraData
    performWithDelay(self, function()
        self.m_roleSpine:setVisible(true)
    end, 3/30)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_wheel_role_start)
    util_spinePlay(self.m_roleSpine, "wheel_start")
    util_spineEndCallFunc(self.m_roleSpine, "wheel_start", function()
        util_spinePlay(self.m_roleSpine, "wheel_idle", true)
    end)

    performWithDelay(self, function()
        self.m_machine.m_wheelGuochangSpine:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_wheel_startView)
        util_spinePlay(self.m_machine.m_wheelGuochangSpine, "auto_wheelbonus")
        util_spineEndCallFunc(self.m_machine.m_wheelGuochangSpine, "auto_wheelbonus", function()
            self.m_machine.m_wheelGuochangSpine:setVisible(false)

            self.m_wheelPanelSpin:setSkipCallBack(function()
                self:beginWheel()
            end)
            self.m_machine:setWheelBtnVisible(true)
        end)
    end, 40/30 + 0.5)
end

--[[
    刷新转盘
]]
function CatchMonstersWheelView:updateWheelSymbol()
    local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData
    self.m_roleSpine:setVisible(false)
    self.m_buttonNode:runCsbAction("idle", true)
    self.m_buttonEffectNode:setVisible(true)
    self:showWheelSymbol(rsExtraData)
    self.m_firstChange = true
    for i = 1, MAX_WHEEL_COUNT, 1 do
        if self.m_bigWheelNode[i].m_rewardNode["Node_grand"] and self.m_bigWheelNode[i].m_rewardNode["Node_grand"].m_grandSpine then
            util_spinePlay(self.m_bigWheelNode[i].m_rewardNode["Node_grand"].m_grandSpine, "idleframe2", true)
        end

        if self.m_bigWheelNode[i].m_rewardNode["Node_epic"] and self.m_bigWheelNode[i].m_rewardNode["Node_epic"].m_epicSpine then
            util_spinePlay(self.m_bigWheelNode[i].m_rewardNode["Node_epic"].m_epicSpine, "idleframe2", true)
        end
    end
end

--[[
    根据服务器给的数据  显示转盘
]]
function CatchMonstersWheelView:showWheelSymbol(_rsExtraData)
    local wheelData = _rsExtraData.wheelData or {}
    for _index, _type in ipairs(wheelData) do
        for _, _bgName in ipairs(ALL_ITEM_BG) do
            self.m_bigWheelNode[_index]:findChild(_bgName):setVisible(false)
            self.m_bigWheelNode[_index].m_zhongjiangNode[_bgName]:setVisible(false)
            if _bgName ~= "Node_shuziCoins" then
                for _, _bgNameNode in ipairs(ITEM_BG) do
                    self.m_bigWheelNode[_index].m_rewardNode[_bgName]:findChild(_bgNameNode):setVisible(false)
                end
                self.m_bigWheelNode[_index].m_rewardNode[_bgName]:runCsbAction("idle", false)

                if _bgName == "Node_epic" then
                    self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setVisible(false)
                    util_changeNodeParent(self.m_bigWheelNode[_index].m_rewardNode[_bgName]:findChild("Node_spine2"), self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine)
                    self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setPosition(cc.p(0, 0))
                    self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setRotation(0)
                end

                if _bgName == "Node_grand" then
                    self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setVisible(false)
                    util_changeNodeParent(self.m_bigWheelNode[_index].m_rewardNode[_bgName]:findChild("Node_spine1"), self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine)
                    self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setPosition(cc.p(0, 0))
                    self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setRotation(0)
                end
            end
        end

        self.m_bigWheelNode[_index]:runCsbAction("idle")
        if type(_type) == "string" then
            self.m_bigWheelNode[_index]:findChild("Node_shuziCoins"):setVisible(true)
            self:updateSymbolCoins(_index, tonumber(_type))
        else
            if _type == 1000 then -- epic 
                self.m_bigWheelNode[_index]:findChild("Node_epic"):setVisible(true)
                self.m_bigWheelNode[_index].m_rewardNode["Node_epic"]:findChild("Node_epic"):setVisible(true)
                self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setVisible(true)
                local pos = util_convertToNodeSpace(self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine, self.m_wheelNode:findChild("Node_new"))
                local rotationX = self.m_bigWheelNode[_index]:getParent():getRotationSkewX()
                local rotationY = self.m_bigWheelNode[_index]:getParent():getRotationSkewY()
                util_changeNodeParent(self.m_wheelNode:findChild("Node_new"), self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine)
                self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setPosition(pos)
                self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setRotationSkewX(rotationX)
                self.m_bigWheelNode[_index].m_rewardNode["Node_epic"].m_epicSpine:setRotationSkewY(rotationY)
            elseif _type == 500 then -- grand
                self.m_bigWheelNode[_index]:findChild("Node_grand"):setVisible(true)
                self.m_bigWheelNode[_index].m_rewardNode["Node_grand"]:findChild("Node_grand"):setVisible(true)
                self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setVisible(true)
                local pos = util_convertToNodeSpace(self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine, self.m_wheelNode:findChild("Node_new"))
                local rotationX = self.m_bigWheelNode[_index]:getParent():getRotationSkewX()
                local rotationY = self.m_bigWheelNode[_index]:getParent():getRotationSkewY()
                util_changeNodeParent(self.m_wheelNode:findChild("Node_new"), self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine)
                self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setPosition(pos)
                self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setRotationSkewX(rotationX)
                self.m_bigWheelNode[_index].m_rewardNode["Node_grand"].m_grandSpine:setRotationSkewY(rotationY)
            elseif _type == 200 then -- big spin
                self.m_bigWheelNode[_index]:findChild("Node_maxspin"):setVisible(true)
                self.m_bigWheelNode[_index].m_rewardNode["Node_maxspin"]:findChild("Node_maxspin"):setVisible(true)
            elseif _type == 20 then -- free 20次
                self.m_bigWheelNode[_index]:findChild("Node_free_20"):setVisible(true)
                self.m_bigWheelNode[_index].m_rewardNode["Node_free_20"]:findChild("Node_free_20"):setVisible(true)
            else -- free 其他次数
                self.m_bigWheelNode[_index]:findChild("Node_free_10_15"):setVisible(true)
                if _type == 15 then
                    self.m_bigWheelNode[_index].m_rewardNode["Node_free_10_15"]:findChild("Node_free_15"):setVisible(true)
                elseif _type == 12 then
                    self.m_bigWheelNode[_index].m_rewardNode["Node_free_10_15"]:findChild("Node_free_12"):setVisible(true)
                elseif _type == 10 then
                    self.m_bigWheelNode[_index].m_rewardNode["Node_free_10_15"]:findChild("Node_free_10"):setVisible(true)
                end
            end
        end
    end
end

-- 转盘转动结束调用
function CatchMonstersWheelView:initCallBack(callBackFun)
    self.m_callFunc = function(_func)
        callBackFun(_func)
    end
end

function CatchMonstersWheelView:onEnter()
    CatchMonstersWheelView.super.onEnter(self)
end

function CatchMonstersWheelView:onExit()
    CatchMonstersWheelView.super.onExit(self)
end

function CatchMonstersWheelView:beginWheel()
    self.m_machine:setWheelBtnVisible(false)
    self.m_buttonEffectNode:setVisible(false)
    self.m_buttonNode:runCsbAction("switch", false, function()
        self.m_buttonNode:runCsbAction("idle2", true)
        
        util_spinePlay(self.m_lvDaiSpine, "start", false)
        util_spineEndCallFunc(self.m_lvDaiSpine, "start", function ()
            util_spinePlay(self.m_lvDaiSpine, "idle2", true)
        end)
    end)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_wheel_click_end)

    util_spinePlay(self.m_roleSpine, "wheel_switch", true)
    performWithDelay(self, function()
        util_spinePlay(self.m_roleSpine, "wheel_idle2", true)
    end, 29/30)
    
    for _, _node in ipairs(self.m_bigWheelNode) do
        _node:runCsbAction("idle", true)
    end
    self.m_machine.m_isDuanxian = false

    self:sendData()
end

--[[
    开始转动
]]
function CatchMonstersWheelView:beginWheelAction()
    self.m_pointerNode:runCsbAction("actionframe", true)
    
    self.m_wheel_node:startMove()
    if self.m_firstChange then
        self.m_firstChange = false
        performWithDelay(self, function()
            for i = 1, MAX_WHEEL_COUNT, 1 do
                if self.m_bigWheelNode[i].m_rewardNode["Node_grand"] and self.m_bigWheelNode[i].m_rewardNode["Node_grand"].m_grandSpine then
                    util_spinePlay(self.m_bigWheelNode[i].m_rewardNode["Node_grand"].m_grandSpine, "idleframe3", true)
                end

                if self.m_bigWheelNode[i].m_rewardNode["Node_epic"] and self.m_bigWheelNode[i].m_rewardNode["Node_epic"].m_epicSpine then
                    util_spinePlay(self.m_bigWheelNode[i].m_rewardNode["Node_epic"].m_epicSpine, "idleframe3", true)
                end
            end
        end, 3)
    end
end

--[[
    转盘停止
]]
function CatchMonstersWheelView:wheelDown()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_wheel_win)

    local extra = self.m_bonusData.respin.extra.wheel[2] or {}
    self.m_pointerTXNode:setVisible(true)
    self.m_pointerTXNode:runCsbAction("actionframe", false, function()
        self.m_pointerTXNode:setVisible(false)
    end)
    self.m_pointerNode:runCsbAction("idle", true)
    util_spinePlay(self.m_roleSpine, "wheel_switch2", false)
    util_spineEndCallFunc(self.m_roleSpine, "wheel_switch2", function()
        self.m_roleSpine:setVisible(false)
    end)

    util_spinePlay(self.m_lvDaiSpine, "over", false)
    for index = 1, #self.m_bigWheelNode do
        if index == self.m_endIndex then
            self.m_bigWheelNode[self.m_endIndex].m_oldParent = self.m_bigWheelNode[self.m_endIndex]:getParent()
            local pos = util_convertToNodeSpace(self.m_bigWheelNode[self.m_endIndex], self.m_wheelNode:findChild("Node_new"))
            local rotationX = self.m_bigWheelNode[self.m_endIndex]:getParent():getRotationSkewX()
            local rotationY = self.m_bigWheelNode[self.m_endIndex]:getParent():getRotationSkewY()
            util_changeNodeParent(self.m_wheelNode:findChild("Node_new"), self.m_bigWheelNode[self.m_endIndex])
            self.m_bigWheelNode[self.m_endIndex]:setPosition(pos)
            self.m_bigWheelNode[self.m_endIndex]:setRotationSkewX(rotationX)
            self.m_bigWheelNode[self.m_endIndex]:setRotationSkewY(rotationY)

            if extra[1] == "jackpot" then
                local winJackpotCoins, jType = self:getJackpotWinCoins()
                if jType == "Epic" then
                    util_changeNodeParent(self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_epic"]:findChild("Node_spine2"), self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_epic"].m_epicSpine)
                    self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_epic"].m_epicSpine:setPosition(cc.p(0, 0))
                    self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_epic"].m_epicSpine:setRotation(0)
                end

                if jType == "Grand" then
                    util_changeNodeParent(self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_grand"]:findChild("Node_spine1"), self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_grand"].m_grandSpine)
                    self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_grand"].m_grandSpine:setPosition(cc.p(0, 0))
                    self.m_bigWheelNode[self.m_endIndex].m_rewardNode["Node_grand"].m_grandSpine:setRotation(0)
                end
            end

            self.m_bigWheelNode[index]:runCsbAction("actionframe2", true)
            
            for _index, _bgName in ipairs(ALL_ITEM_BG) do
                self.m_bigWheelNode[index].m_zhongjiangNode[_bgName]:setVisible(true)
                self.m_bigWheelNode[index].m_zhongjiangNode[_bgName]:runCsbAction("actionframe", true)
                if _bgName ~= "Node_shuziCoins" then
                    self.m_bigWheelNode[index].m_rewardNode[_bgName]:runCsbAction("actionframe2", true)
                end
            end
        else
            self.m_bigWheelNode[index]:runCsbAction("darkauto", false)
            for _index, _bgName in ipairs(ALL_ITEM_BG) do
                if _bgName ~= "Node_shuziCoins" then
                    self.m_bigWheelNode[index].m_rewardNode[_bgName]:runCsbAction("darkauto", false)
                end
            end
        end
    end

    performWithDelay(self, function()
        local callBack = function(_func)
            -- 转盘结束
            if self.m_bonusData.respin.reSpinCurCount == 0 and self.m_bonusData.respin.reSpinsTotalCount ~= 0 then
                performWithDelay(self, function()
                    self.m_callFunc(function()
                        if self.m_bigWheelNode[self.m_endIndex].m_oldParent then
                            local rotationX = self.m_bigWheelNode[self.m_endIndex]:getParent():getRotationSkewX()
                            local rotationY = self.m_bigWheelNode[self.m_endIndex]:getParent():getRotationSkewY()
                            util_changeNodeParent(self.m_bigWheelNode[self.m_endIndex].m_oldParent, self.m_bigWheelNode[self.m_endIndex])
                            self.m_bigWheelNode[self.m_endIndex]:setPosition(cc.p(0, 0))
                            self.m_bigWheelNode[self.m_endIndex]:setRotationSkewX(rotationX)
                            self.m_bigWheelNode[self.m_endIndex]:setRotationSkewY(rotationY)
                        end

                        if _func then
                            _func()
                        end
                    end)
                end, 1)
            else
                performWithDelay(self, function()
                    self.m_machine:setWheelBtnVisible(true)
                    if _func then
                        _func()
                    end
                end, 1)
            end
        end

        -- 中奖jackpot
        if extra[1] == "jackpot" then
            local winJackpotCoins, jType = self:getJackpotWinCoins()
            self.m_machine:showJackpotView(winJackpotCoins, jType, function()
                self:updateCoinsByEnd()
                callBack()
            end)
        -- 中奖free
        elseif extra[1] == "free" then
            callBack(function()
                performWithDelay(self, function()
                    self.m_machine:beginFreeOrBigSpin()
                end, 0.5)
            end)
        -- 中奖big spin
        elseif extra[1] == "bonus" then
            callBack(function()
                performWithDelay(self, function()
                    self.m_machine:beginFreeOrBigSpin()
                end, 0.5)
            end)
        -- 中奖钱
        else
            self.m_machine.m_iOnceSpinLastWin = self.m_bonusData.winAmount
            local delayTime = self.m_machine:getWinCoinTime()
            self:updateCoinsByEnd()
            performWithDelay(self, function()
                callBack()
            end, delayTime)
        end
    end, 2)
end

--[[
    获取jackpot的钱数
]]
function CatchMonstersWheelView:getJackpotWinCoins()
    if self.m_bonusData.jackpotCoins then
        for _jpType, _jackpotCoins in pairs(self.m_bonusData.jackpotCoins) do
            return _jackpotCoins, _jpType
        end
    end
    return 0, "Minor"
end

--[[
    设置停止索引
]]
function CatchMonstersWheelView:setWheelEndIndex()
    local extra = self.m_bonusData.respin.extra.wheel or {}
    if next(extra) then
        self.m_endIndex = extra[1] + 1
        self.m_wheel_node:setEndIndex(extra[1])
    end
end

--[[
    重置转盘角度
]]
function CatchMonstersWheelView:resetWheel()
    self.m_wheel_node:resetViewStatus()
end

function CatchMonstersWheelView:sendData()
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={ msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function CatchMonstersWheelView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            dump(spinData.result, "featureResultCallFun data", 3)
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            if spinData.action == "SPIN" and spinData.result.action == "RESPIN" then
                self.m_machine.m_runSpinResultData:parseResultData(spinData.result,self.m_machine.m_lineDataPool)
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(spinData.result)
            end
        else
            -- 处理消息请求错误情况
            gLobalViewManager:showReConnect()
        end
    end
end

function CatchMonstersWheelView:recvBaseData(_data)
    self.m_bonusData = _data
    if _data.respin.reSpinCurCount == 0 and _data.respin.reSpinsTotalCount ~= 0 then

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_bonusData.winAmount, GameEffect.EFFECT_BONUS})
    end

    -- 中奖了free玩法
    if #_data.features > 1 and _data.features[2] == 1 then
        self.m_machine:addFreeSpinEffect()
        globalData.slotRunData.totalFreeSpinCount = _data.freespin.freeSpinsTotalCount
        globalData.slotRunData.freeSpinCount = _data.freespin.freeSpinsLeftCount
        self.m_machine.m_iFreeSpinTimes = _data.freespin.freeSpinsTotalCount
        if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
            self.m_machine.m_runSpinResultData.p_freeSpinNewCount = _data.freespin.freeSpinsTotalCount
        end
        self.m_machine.m_wheelToFree = true
    end

    -- 中奖了big spin 玩法
    if #_data.features > 1 and _data.features[2] == 5 then
        self.m_machine:addBigSpinEffect()
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_wheel_run)
    self:beginWheelAction()
    self:setWheelEndIndex()
end

--[[
    转盘结束 刷新金币
]]
function CatchMonstersWheelView:updateCoinsByEnd( )
    local lastCoins = self.m_machine:getCurBottomWinCoins()
    self.m_machine:setLastWinCoin(self.m_bonusData.winAmount)
    if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_machine:updateBottomUICoins(0, self.m_bonusData.winAmount, false, true, false)
    else
        self.m_machine:updateBottomUICoins(0, self.m_bonusData.winAmount, true, true, false)
    end

    if not self.m_machine:checkHasSelfBigWin() then
        self.m_machine:checkFeatureOverTriggerBigWin(self.m_bonusData.winAmount, GameEffect.EFFECT_RESPIN_OVER, true)
    end
end

return CatchMonstersWheelView