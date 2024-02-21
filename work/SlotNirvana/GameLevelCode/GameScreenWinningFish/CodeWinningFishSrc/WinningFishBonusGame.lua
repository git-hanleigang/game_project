---
--smy
--2018年4月26日
--WinningFishBonusGame.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local WinningFishBonusGame = class("WinningFishBonusGame",BaseGame )

local BONUS_COUNT   =   25      --鱼食数量
local MAX_COUNT     =   20      --最大抽奖数量
local BOX_ID    =    9          --宝箱ID

WinningFishBonusGame.m_isOver = false

function WinningFishBonusGame:initUI()
    self:createCsbNode("WinningFish/GameScreenWinningFish_shouji.csb")

    self.m_callBack = nil
    self.m_isWaiting = false

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    --选择界面
    self.m_select_view = util_createView("CodeWinningFishSrc.WinningFishBonusSelectView",self)
    self:findChild("BONUS"):addChild(self.m_select_view)
    self.m_select_view:setVisible(false)

    --抽奖次数
    local node_pick_time = self:findChild("goldenfish_shouji_pickleft_1")
    node_pick_time:removeAllChildren(true)
    self.m_pick_times = util_createAnimation("Socre_WinningFish_Bonus_pick.csb")
    self.m_pick_times:runCsbAction("actionframe")
    node_pick_time:addChild(self.m_pick_times)
    self.m_lb_num = self.m_pick_times:findChild("m_lb_num")

    --bouns图标位置节点
    self.node_bonus = {}
    self.bonus_items = {}
    for index=1,BONUS_COUNT do
        self.node_bonus[index] = self:findChild("bonus_"..(index - 1))

        local params = {
            callBack = function(node,sender,pos)
                self:clickFunc(sender,pos)
            end,   --按钮回调
            index = index - 1           --按钮索引   
        }

        --创建bonus图标
        local bouns_item = util_createView("CodeWinningFishSrc.WinningFishBonusItem",params)
        self.node_bonus[index]:removeAllChildren(true)
        self.node_bonus[index]:addChild(bouns_item)
        self.bonus_items[index] = bouns_item
    end
    --菜单
    self.m_menus = {}
    for index=1,9 do
        local node_menu = self:findChild("menu_"..(index - 1))
        local menu_item = util_createView("CodeWinningFishSrc.WinningFishBonusMenuItem",{menuIndex = index,baseGame = self})
        node_menu:removeAllChildren(true)
        node_menu:addChild(menu_item)
        if index < 9 then
            table.insert(self.m_menus,1,menu_item)
        else
            table.insert(self.m_menus,#self.m_menus + 1,menu_item)
        end
        
    end
end

function WinningFishBonusGame:onEnter()
    BaseGame.onEnter(self)
    --是否已触发选择玩法
    self.m_isSelected = false

    schedule(self,function()
        if self.m_isOver then
            return
        end
        self:swingFishFood()
    end,2)
end
function WinningFishBonusGame:onExit()
    BaseGame.onExit(self)
end

--[[
    摇摆鱼食动作
]]
function WinningFishBonusGame:swingFishFood()
    local choose = {}
    if self.m_machine.m_runSpinResultData.p_bonus then
        choose = self.m_machine.m_runSpinResultData.p_bonus.choose or {}
    end

    local fish_food = {}
    for index=1,BONUS_COUNT do
        local isPicked = false
        for k,value in pairs(choose) do
            if index == value + 1 then
                isPicked = true
                break;
            end
        end
        if not isPicked then
            fish_food[#fish_food + 1] = index
        end
    end

    local rand_index = math.random(1,#fish_food)
    local rand_pos = fish_food[rand_index]
    if self.bonus_items[rand_pos] then
        self.bonus_items[rand_pos]:runSwingAni()
    end
end

--[[
    显示界面
]]
function WinningFishBonusGame:showView(isShow,callBack)
    self.m_isWaiting = false

    local bonus = self.m_machine.m_runSpinResultData.p_bonus
    if bonus and bonus.extra.pickData[BOX_ID][2] >= 3 then
        self.m_isSelected = true
    else
        self.m_isSelected = false
    end
    
    if type(callBack) == "function" then
        self.m_callBack = callBack
    end
    
    if isShow then
        if self:isVisible() then
            return
        end
        self.m_isOver = false
        for index,menuItem in pairs(self.m_menus) do
            menuItem:updateInfo(self.m_machine.m_runSpinResultData)
        end
        --刷新剩余次数
        self.m_lb_num:setString(self.m_machine.m_runSpinResultData.p_selfMakeData.pickTimes or 0)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        self:refreshView(true)
        local params = {
            {
                type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                delayTime = 0.5,
                callBack = function(  )
                    self:setVisible(true)
                end
            },
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "start", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数 
                callBack = function(  )
                    self.m_machine:setBaseReelShow(false)
                end
            }
        }
        util_runAnimations(params)
    else
        local ownerlist = {}
        ownerlist["m_lb_coins"] = util_formatCoins(self.m_machine.m_runSpinResultData.p_bonus.bsWinCoins, 30)
        --清理背景音乐
        self.m_machine:clearCurMusicBg()
        --结束短乐 等待特效结束
        performWithDelay(self,function()
            gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_bonus_over_1.mp3")
        end,1.2)
        --结束弹版
        performWithDelay(self,function()
            gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_bonus_over.mp3")
            local view = self.m_machine:showDialog("BonusOver", ownerlist, function(  )
                performWithDelay(self,function()
                    self.m_machine:setBaseReelShow(true)
                    self:runCsbAction("over",false,function()
                        self:setVisible(false)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
                        if type(self.m_callBack) == "function" then
                            self.m_callBack()
                        end
                    end,60) 
                end,0.3)
            end)
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node,sx = 1.15,sy = 1.15}, 654)
        end,4.5)
    end
end

--[[
    刷新界面
]]
function WinningFishBonusGame:refreshView(isInit)
    local result = self.m_machine.m_runSpinResultData

    if isInit then
        for index=1,BONUS_COUNT do
            local item_bonus =  self.bonus_items[index]
            item_bonus:refreshUI(result)
        end
    end

    --重置等待状态
    self.m_isWaiting = false
    if result.p_bonus and result.p_bonus.status == "CLOSED" and not self.m_isSelecting  then
        self.m_isOver = true
        --检测是否获得大奖
        self.m_machine:checkFeatureOverTriggerBigWin(result.p_bonus.bsWinCoins, GameEffect.EFFECT_BONUS)
        self.m_machine.m_bottomUI:notifyTopWinCoin()
        self:showView(false)
    end
end

--[[
    刷新bonus显示
]]
function WinningFishBonusGame:refreshBonus()
    for index,bonus_item in pairs(self.bonus_items) do
        
    end
end

--[[
    按钮回调
]]
function WinningFishBonusGame:clickFunc(sender,pos)
    self:sendData(pos)
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function WinningFishBonusGame:initViewData(callBackFun, gameSecen)
    self:initData()
    
end


function WinningFishBonusGame:resetView(featureData, callBackFun, gameSecen)
    self:initData()
end

function WinningFishBonusGame:initData()
    self:initItem()
end

function WinningFishBonusGame:initItem()
    
end

--数据发送
function WinningFishBonusGame:sendData(pos)
    --获取当前剩余点击次数
    local pickTimes = self.m_machine.m_runSpinResultData.p_selfMakeData.pickTimes or 0
    local isPicked = false
    if self.m_machine.m_runSpinResultData.p_bonus and table.indexof(self.m_machine.m_runSpinResultData.p_bonus.choose,pos) then
        isPicked = true
    end
    if self.m_isWaiting or pickTimes <= 0 or isPicked then
        return
    end

    --刷新剩余次数
    self.m_lb_num:setString(self.m_machine.m_runSpinResultData.p_selfMakeData.pickTimes - 1)

    self.m_action=self.ACTION_SEND
    --防止连续点击
    self.m_isWaiting = true
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT , clickPos = pos}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


function WinningFishBonusGame:uploadCoins(featureData)
    
end

--数据接收
function WinningFishBonusGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end

    self.m_machine.m_runSpinResultData.p_features = featureData.p_data.features
    --更新bonus相关数据
    self.m_machine.m_runSpinResultData.p_bonus = featureData.p_bonus
    self.m_machine.m_runSpinResultData.p_selfMakeData.pickTimes = featureData.p_bonus.extra.pickTimes
    self.m_machine.m_runSpinResultData.p_selfMakeData.boxData = featureData.p_data.selfData.boxData
    local pickData = featureData.p_bonus.extra.pickData
    self.m_machine.m_runSpinResultData.addPicks = featureData.p_data.selfData.addPicks
    self.m_machine.m_runSpinResultData.p_selfMakeData.pickScore = featureData.p_data.selfData.pickScore
    self.pickIndex = 1
    --依次执行pick动作
    self:doNextAni(function ()
        --刷新分数用
        self:refreshView()

    end)

    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{featureData.p_bonusWinAmount, GameEffect.EFFECT_BONUS})
    else
        
    end
end

--[[
    下个收集动作
]]
function WinningFishBonusGame:doNextAni(callBack)
    local addPicks = self.m_machine.m_runSpinResultData.addPicks
    if addPicks and self.pickIndex <= #addPicks then
        self:colloctionAni(function()
            self.pickIndex = self.pickIndex + 1
            self:doNextAni(callBack)
        end)
    elseif not addPicks then
        self:colloctionAni(function()
            if type(callBack) == "function" then
                callBack()
            end
        end)
    else
        if type(callBack) == "function" then
            callBack()
        end
    end
end

--[[
    收集动画
]]
function WinningFishBonusGame:colloctionAni(callBack)
    local bonus = self.m_machine.m_runSpinResultData.p_bonus
    local addPicks = self.m_machine.m_runSpinResultData.addPicks
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local boxData = selfData.boxData
    local pos,fish_type
    if addPicks then
        pos = addPicks[self.pickIndex][1]
        fish_type = tonumber(addPicks[self.pickIndex][2])
    else
        pos = bonus.choose[#bonus.choose]
        fish_type = tonumber(bonus.content[#bonus.content])
    end
    local icon_bonus = self.bonus_items[pos + 1]

    --获取终点节点
    local menuItem = self.m_menus[fish_type]

    function refreshTimes(  )
        --播放剩余次数粒子特效
        self.m_pick_times:findChild("Particle_1"):resetSystem()
        self.m_pick_times:findChild("Particle_1_0"):resetSystem()
        --刷新剩余次数
        self.m_lb_num:setString(self.m_machine.m_runSpinResultData.p_selfMakeData.pickTimes or 0)

        util_runAnimations({
            [1] = {   --光效特效
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.m_pick_times,   --执行动画节点  必传参数
                actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
                soundFile = "WinningFishSounds/sound_winningFish_bonus_addPicks.mp3",
                fps = 60,    --帧率  可选参数 
                callBack = function (  )
                    
                end
            },
            [2] = {   --回复普通状态
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.m_pick_times,   --执行动画节点  必传参数
                actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数 
                callBack = function(  )
                    
                end
            }
        })
    end

    --鱼食开启动画
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_fish_food_click.mp3")
    icon_bonus:runOpenAni(fish_type,function(  )
        gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_fish_food_colloct.mp3")
        if fish_type ~= BOX_ID then
            --刷新金币
            self:refreshCoin(fish_type,false)
            menuItem:updateInfo(self.m_machine.m_runSpinResultData,fish_type)
            if type(callBack) == "function" then
                callBack()
            end
        else
            menuItem:updateInfo(self.m_machine.m_runSpinResultData,fish_type)
        end
    end,
    function()
        if fish_type == BOX_ID then  --抽到宝箱
            local showPick = false
            --是否显示选择界面
            if addPicks and self.pickIndex == #addPicks - 1 and bonus.extra.pickData[BOX_ID][2] >= 3 then
                showPick = true
            end
            self.m_select_view:showView(boxData,showPick,function (  )
                --粒子特效
                --判断是否游戏结束
                if addPicks and addPicks[self.pickIndex + 1] then
                    local particle = util_createAnimation("Socre_WinningFish_Bonus_TWlizi_0.csb")
                    particle:findChild("Particle_1"):setPositionType(0)
                    self.m_effectNode:addChild(particle)
                    particle:setPosition(util_convertToNodeSpace(self.node_bonus[pos + 1],self.m_effectNode))
                    local endPos = addPicks[self.pickIndex + 1][1]

                    local seq = cc.Sequence:create({
                        cc.MoveTo:create(0.4,util_convertToNodeSpace(self.node_bonus[endPos + 1],self.m_effectNode)),
                        cc.DelayTime:create(0.2),
                        cc.CallFunc:create(function(  )
                            particle:removeFromParent(true)
                            if type(callBack) == "function" then
                                callBack()
                            end
                        end)
                    })
                    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_bonus_fly.mp3")
                    particle:runAction(seq)
                else
                    if type(callBack) == "function" then
                        callBack()
                    end
                end
                

                
            end)
        else    --刷新剩余次数
            if bonus.extra.pickData[fish_type][2] >= selfData.picks[fish_type] then
                local node_pick,count = menuItem:findChild("pick"),selfData.picks[fish_type]
                menuItem:hidePickTimes()
                --创建临时图标用于执行动作
                local sp_temp = util_createAnimation("Socre_WinningFish_Bonus_jiaPick.csb")
                for index=1,2 do
                    sp_temp:findChild("picks2_"..index):setVisible(count == 2)
                    sp_temp:findChild("picks3_"..index):setVisible(count == 3)
                end
                sp_temp:findChild("Particle_1"):setPositionType(0)
                sp_temp:setPosition(util_convertToNodeSpace(node_pick,self.m_effectNode))
                self.m_effectNode:addChild(sp_temp)

                --添加次数执行动画
                util_runAnimations({
                    {
                        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                        node = sp_temp,   --执行动画节点  必传参数
                        actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
                        fps = 60,    --帧率  可选参数 
                    }
                })
                --终点坐标
                local node_pick_left = self:findChild("goldenfish_shouji_pickleft_1")
                local seq = {
                    cc.MoveTo:create(0.7, util_convertToNodeSpace(node_pick_left,self.m_effectNode)), 
                    cc.RemoveSelf:create(true),
                    cc.CallFunc:create(function()
                        refreshTimes()
                    end)
                }
                gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_bonus_pick_fly.mp3")
                sp_temp:runAction(cc.Sequence:create(seq))
            end
        end
    end)
end


--[[
    刷新金币
]]
function WinningFishBonusGame:refreshCoin(fish_type,isBox,boxNode)
    local menuItem = self.m_menus[fish_type]
    local addPicks = self.m_machine.m_runSpinResultData.addPicks
    local bonus = self.m_machine.m_runSpinResultData.p_bonus
    local winCount = 0

    local maxCount = 8
    if isBox or bonus.extra.pickData[BOX_ID][2] >= 3 then
        maxCount = BOX_ID
    end

    --刷新宝箱金币时要先剔除本次鱼的金币
    local curFishScore = 0
    if isBox then
        local fish_type = addPicks[#addPicks][2]
        local data = bonus.extra.pickData[fish_type]
        if data[2] > 0 then
            curFishScore = data[3] / data[2]
        end
    end

    --计算赢得钱
    for index=1,maxCount do
        local pickData = bonus.extra.pickData[index]
        winCount = winCount + pickData[3]
    end
    winCount = winCount - curFishScore
    local curWinCount = bonus.extra.pickData[fish_type][3]

    local playBottomEffect = function(  )
        --刷新赢钱
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
            winCount, true, true,winCount - curWinCount
        })

        --底部ui光效
        --创建临时光效用于执行动作
        -- local light_temp = util_createAnimation("Socre_WinningFish_jiesuan.csb")
        -- self.m_machine.m_bottomUI.coinWinNode:addChild(light_temp)
        -- --播放粒子特效
        -- light_temp:findChild("Particle_1"):resetSystem()
        -- util_runAnimations({
        --     {   --底部ui光效
        --         type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        --         node = light_temp,   --执行动画节点  必传参数
        --         actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        --         fps = 60,    --帧率  可选参数 
        --         callBack = function()
        --             light_temp:removeFromParent(true)
        --         end
        --     }
        -- })
        -- 这个地方还干掉了粒子效果
        self.m_machine:playCoinWinEffectUI()
    end

    local particle = util_createAnimation("Socre_WinningFish_Bonus_TWlizi.csb")
    
    if isBox then --点击宝箱获得金币粒子起始位置
        particle:setPosition(util_convertToNodeSpace(boxNode,self.m_machine.m_effectNode_top))
    else
        particle:setPosition(util_convertToNodeSpace(menuItem.m_lb_coins,self.m_machine.m_effectNode_top))
    end
    particle:findChild("Particle_1"):setPositionType(0)
    self.m_machine.m_effectNode_top:addChild(particle)
    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.4,util_convertToNodeSpace(self.m_machine.m_bottomUI.coinWinNode,self.m_machine.m_effectNode_top)),
        cc.DelayTime:create(0.2),
        cc.CallFunc:create(function(  )
            particle:removeFromParent(true)
            playBottomEffect()
        end)
    })
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_bonus_fly.mp3")
    particle:runAction(seq)
    
end

function WinningFishBonusGame:sortNetData(data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status

        end
    end 


    localdata = data

    return localdata
end

--[[
    接受网络回调
]]
function WinningFishBonusGame:featureResultCallFun(param)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bonusType and selfData.bonusType == "pick" then
        BaseGame.featureResultCallFun(self,param)
    end
    
end
return WinningFishBonusGame