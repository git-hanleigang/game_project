---
--xcyy
--2018年5月23日
--ZooManiaBonusGameChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseGame = util_require("base.BaseGame")
local ZooManiaBonusGameChooseView = class("ZooManiaBonusGameChooseView",BaseGame )

ZooManiaBonusGameChooseView.m_machine = nil
ZooManiaBonusGameChooseView.m_bonusEndCall = nil
ZooManiaBonusGameChooseView.m_dongWu = nil
ZooManiaBonusGameChooseView.m_dongWuBaoDian = nil
ZooManiaBonusGameChooseView.m_dongwuGuanTou = nil
ZooManiaBonusGameChooseView.m_Multiply = 1
ZooManiaBonusGameChooseView.m_coinNum = 0
ZooManiaBonusGameChooseView.m_floor = 0
ZooManiaBonusGameChooseView.m_multiplerBaoDian = nil
ZooManiaBonusGameChooseView.m_dongWuSpine = nil
ZooManiaBonusGameChooseView.m_isfirstComeIn = nil -- 判断第一次进入
ZooManiaBonusGameChooseView.m_schedule = nil
ZooManiaBonusGameChooseView.m_clickPos = nil --点击位置

function ZooManiaBonusGameChooseView:initUI(machine)
    self.m_machine = machine
    self.m_dongWu = {}
    self.m_dongWuBaoDian = {}
    self.m_dongwuGuanTou = {}
    self.m_Multiply = 1
    self.m_coinNum = 0
    self.m_floor = 0
    self.m_dongWuSpine = {}

    self:createCsbNode("ZooMania/Bonus.csb")

    self.m_dongWuBg = util_createAnimation("ZooMania/Bonus_dongwu.csb")
    self:findChild("Node_dongwu"):addChild(self.m_dongWuBg)

    self.m_dongWuBg1 = util_createAnimation("ZooMania/Bonus_dongwu_1.csb")
    self:findChild("Node_dongwu"):addChild(self.m_dongWuBg1)

    --背景
    self.m_bonusGameBg = util_createAnimation("ZooMania/GameScreenZooManiaBg.csb")
    self:findChild("gamebg"):addChild(self.m_bonusGameBg)
    self.m_bonusGameBg:runCsbAction("Bonus",true)

    self.m_bonusGameBgGunDong = util_createAnimation("ZooMania/GameScreenZooManiaBg_0.csb")
    self.m_bonusGameBg:findChild("dimian"):addChild(self.m_bonusGameBgGunDong)
    self.m_bonusGameBgGunDong:runCsbAction("idleframe",true)

    --动物
    self:initChest()

    --动物管理员
    self.m_zooGuanLiYuan = util_spineCreate("ZooMania_guanliyuan", true, true) 
    self:findChild("Node_guanliyuan"):addChild(self.m_zooGuanLiYuan)
    self.m_zooGuanLiYuan:setPositionY(-270)

    -- 结算倍数
    self.m_multipler = util_createAnimation("ZooMania_MULTIPLIER_X.csb")
    self:findChild("Node_MULTIPLIER_X"):addChild(self.m_multipler)
    self.m_multipler:setPositionY(-20)
    if display.height / display.width == 768/1024 then
        self.m_multipler:setPositionY(60)
    end
    self.m_multipler:runCsbAction("idleframe",false)

    self.m_multiplerBaoDian = util_createAnimation("ZooMania_dongwu_baodian.csb")
    self.m_multipler:findChild("Node_1_0"):addChild(self.m_multiplerBaoDian)
    self.m_multiplerBaoDian:setVisible(false)
end

function ZooManiaBonusGameChooseView:initChest()
    
    for i=1, 5 do
        local data = {}
        data.machine = self
        data.index = i

        self.m_dongWu[i] = util_createView("CodeZooManiaSrc.ZooManiaAnimalView",data)
        self.m_dongWuBg:findChild("Node_dongwu_"..(i-1)):addChild(self.m_dongWu[i])
        self.m_dongWu[i]:runCsbAction("idleframe",false)

        self.m_dongWuBaoDian[i] = util_createAnimation("ZooMania_dongwu_baodian.csb")
        self.m_dongWu[i]:addChild(self.m_dongWuBaoDian[i])
        self.m_dongWuBaoDian[i]:setVisible(false)

        self.m_dongwuGuanTou[i] = util_createAnimation("ZooMania_dongwu_guantou.csb")
        self:findChild("Node_dongwu_guantou"..(i-1)):addChild(self.m_dongwuGuanTou[i])
        self:updateDongWu(self.m_dongWu[i], i)
    end
end

function ZooManiaBonusGameChooseView:updateUIDate(machine  )
    self.m_machine = machine
    self.m_isfirstComeIn = true

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or nil

    self.m_Multiply = selfdata and selfdata.p_bonus.extra.totalMultiple or 1
    self.m_coinNum = self.m_machine.m_runSpinResultData.p_bet 
    self.m_floor = selfdata and selfdata.p_bonus.extra.floor or 0

    self.m_multipler:runCsbAction("idleframe",false)
    self.m_multipler:findChild("m_lb_beishu"):setString(self.m_Multiply .. "X")
    self.m_multipler:findChild("m_lb_coins"):setString(util_formatCoins(self.m_coinNum, 30))
    self.m_multipler:setVisible(true)
    self:updateSize()
    self:updateSizeBeiShu()
    self.m_zooGuanLiYuan:setVisible(false)

    for i = 1, 5 do
        self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
        self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
        self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
        self.m_dongWu[i]:findChild("ZooMania_end_6"):setColor(cc.c3b(255,255,255))
        self.m_dongWu[i]:findChild("ZooMania_winall_7"):setColor(cc.c3b(255,255,255))
        self.m_dongWu[i]:findChild("m_lb_beishu"):setColor(cc.c3b(255,255,255))
        self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)

        self.m_dongWu[i]:findChild("dark_animal01"):setVisible(false)
        self.m_dongWu[i]:findChild("dark_animal02"):setVisible(false)
        self.m_dongWu[i]:findChild("dark_animal03"):setVisible(false)
        self.m_dongWu[i]:findChild("dark_animal04"):setVisible(false)
        self.m_dongWu[i]:findChild("dark_animal05"):setVisible(false)

        self.m_dongWu[i]:runCsbAction("idleframe",false)
        for m=1,5 do
            self.m_dongWuSpine[i][m]:setVisible(false)
        end
        self.m_dongWuSpine[i][self.m_floor+1]:setVisible(true)
        util_spinePlay(self.m_dongWuSpine[i][self.m_floor+1],"idleframe2",false)
    end

end
function ZooManiaBonusGameChooseView:updateUI()
    
    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_Welcame.mp3")
    self.m_zooGuanLiYuan:setVisible(true)
    util_spinePlay(self.m_zooGuanLiYuan,"actionframe_ruchang",false)
    util_spineEndCallFunc(self.m_zooGuanLiYuan,"actionframe_ruchang",function ()
        util_spinePlay(self.m_zooGuanLiYuan,"actionframe_ruchang_idle",true)
    end)

    performWithDelay(self,function()
        
        if self:isCanTouch( ) then
            self.m_dongWuBg:runCsbAction("actionframe2",false)
            gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_DongWuSuoFang.mp3")
            performWithDelay(self,function()
                self:clearScheduler()
                self:randomPlayAnimalSpineScheduler(self.m_floor+1)
            end,1)
        else
            self:clearScheduler()
            self:randomPlayAnimalSpineScheduler(self.m_floor+1)
        end
    end,2)
    
end

-- 更新动物
function ZooManiaBonusGameChooseView:updateDongWu(dongWu,position)
    self.m_dongWuSpine[position] = {}
    for i=1,5 do
        self.m_dongWuSpine[position][i] = util_spineCreate("Socre_ZooMania_" .. (4+i) .. "_pick", true, true) 
        dongWu:findChild("Node_dongwu"):addChild(self.m_dongWuSpine[position][i])
    end

end

function ZooManiaBonusGameChooseView:updateSizeBeiShu()

    local label1=self.m_multipler:findChild("m_lb_beishu")
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,150)
end

function ZooManiaBonusGameChooseView:updateSize()

    local label1=self.m_multipler:findChild("m_lb_coins")
    local info1={label=label1,sx=0.9,sy=0.9}
    self:updateLabelSize(info1,360)
end

function ZooManiaBonusGameChooseView:updateSizeJieSuan()

    local label1=self.m_multipler:findChild("m_lb_coins_jiesuan")
    local info1={label=label1,sx=0.7,sy=0.7}
    self:updateLabelSize(info1,575)
end

function ZooManiaBonusGameChooseView:onEnter()
    BaseGame.onEnter(self)
    
end
function ZooManiaBonusGameChooseView:onExit()
    scheduler.unschedulesByTargetName("ZooManiaBonusGameChooseView")
    BaseGame.onExit(self)
    self:clearScheduler()
end

-- 随机播放动画的 定时器
function ZooManiaBonusGameChooseView:randomPlayAnimalSpineScheduler(floor)
    self.m_schedule = schedule(self, function(  )
        local roadNum = math.random(1,1)
        for i=1,roadNum do
            local position = math.random(1,5)
            util_spinePlay(self.m_dongWuSpine[position][floor],"idleframe",false)
        end
    end, 2)
    
end

-- 清除定时器
function ZooManiaBonusGameChooseView:clearScheduler()
    if self.m_schedule then
        self:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
end

function ZooManiaBonusGameChooseView:setClickData( pos )
    
    self:sendData(pos)
end

--数据发送
function ZooManiaBonusGameChooseView:sendData(pos)
    self.m_action=self.ACTION_SEND
    self.m_clickPos = pos
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else

        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT}
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end

--数据接收
function ZooManiaBonusGameChooseView:recvBaseData(featureData)
    
    -- self.m_machine:reSetBonusBg()
    local selfdata = featureData.p_bonus or {}
    local newContent = {}
    newContent[self.m_clickPos] = selfdata.extra.hit
    if self.m_clickPos == 1 then
        for i=1,4 do
            newContent[i+1] = selfdata.content[i]
        end
    elseif self.m_clickPos == 2 then
        newContent[1] = selfdata.content[1]
        for i=1,3 do
            newContent[i+2] = selfdata.content[i+1]
        end
    elseif self.m_clickPos == 3 then
        newContent[1] = selfdata.content[1]
        newContent[2] = selfdata.content[2]
        for i=1,2 do
            newContent[i+3] = selfdata.content[i+2]
        end
    elseif self.m_clickPos == 4 then
        for i=1,3 do
            newContent[i] = selfdata.content[i]
        end
        newContent[5] = selfdata.content[4]
    elseif self.m_clickPos == 5 then
        for i=1,4 do
            newContent[i] = selfdata.content[i]
        end
    end
    selfdata.content = newContent

    if self.m_isfirstComeIn then
        util_spinePlay(self.m_zooGuanLiYuan,"actionframe_ruchang_jiesu",false)
        self.m_isfirstComeIn = false
    end
    self.m_dongWuBaoDian[self.m_clickPos]:setVisible(true)
    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_Click.mp3")
    self.m_dongWuBaoDian[self.m_clickPos]:runCsbAction("actionframe",false,function(  )
        gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_GuanTou.mp3")
        self.m_dongwuGuanTou[self.m_clickPos]:runCsbAction("actionframe",false,function() end) 

        self:clearScheduler()

        for i = 1, 5 do
            if i == self.m_clickPos then
                if selfdata.content[i] == "winAll" then -- winall
                    self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
                    self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(true)
                    self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
                    self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
                elseif selfdata.content[i] == "end" then
                    self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(true)
                    self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
                    self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
                    self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
                else
                    self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
                    self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
                    self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(true)
                    self.m_dongWu[i]:findChild("m_lb_beishu"):setString(selfdata.content[i] .. "X")
                    self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(true)
                end
            else
                util_spinePlay(self.m_dongWuSpine[i][selfdata.extra.floor],"idleframe2",false)
            end
        end

        self.m_dongWu[self.m_clickPos]:runCsbAction("actionframe",false)
        util_spinePlay(self.m_dongWuSpine[self.m_clickPos][selfdata.extra.floor],"actionframe",false)

        performWithDelay(self,function(  )
            for i = 1, 5 do
                if i ~= self.m_clickPos then
                    if selfdata.content[i] == "winAll" then -- winall
                        self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
                        self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(true)
                        self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
                        self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
                    elseif selfdata.content[i] == "end" then
                        self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(true)
                        self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
                        self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
                        self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
                    else
                        self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
                        self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
                        self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(true)
                        self.m_dongWu[i]:findChild("m_lb_beishu"):setString(selfdata.content[i] .. "X")
                        self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(true)
                    end
                end
            end

            if selfdata.content[self.m_clickPos] == "winAll" then
                for i=1,5 do
                    if i ~= self.m_clickPos then                    
                        for m=1,5 do
                            self.m_dongWuSpine[i][m]:setVisible(false)
                            self.m_dongWu[i]:findChild("dark_animal0"..i):setVisible(false)
                        end
                        self.m_dongWu[i]:runCsbAction("dark",false)
                        self.m_dongWuSpine[i][selfdata.extra.floor]:setVisible(true)
                        if selfdata.content[i] == "end" then
                            self.m_dongWu[i]:findChild("dark_animal0"..selfdata.extra.floor):setVisible(true)
                            self.m_dongWu[i]:findChild("ZooMania_end_6"):setColor(cc.c3b(77,77,77))
                            self.m_dongWu[i]:findChild("ZooMania_winall_7"):setColor(cc.c3b(77,77,77))
                            self.m_dongWu[i]:findChild("m_lb_beishu"):setColor(cc.c3b(77,77,77))
                        end
                    end
                end
                
            else
                for i=1,5 do
                    if i ~= self.m_clickPos then                    
                        for m=1,5 do
                            self.m_dongWuSpine[i][m]:setVisible(false)
                            self.m_dongWu[i]:findChild("dark_animal0"..i):setVisible(false)
                        end
                        self.m_dongWu[i]:runCsbAction("dark",false)
                        self.m_dongWu[i]:findChild("dark_animal0"..selfdata.extra.floor):setVisible(true)
    
                        self.m_dongWuSpine[i][selfdata.extra.floor]:setVisible(true)
                        self.m_dongWu[i]:findChild("ZooMania_end_6"):setColor(cc.c3b(77,77,77))
                        self.m_dongWu[i]:findChild("ZooMania_winall_7"):setColor(cc.c3b(77,77,77))
                        self.m_dongWu[i]:findChild("m_lb_beishu"):setColor(cc.c3b(77,77,77))
                    end
                end
            end

            -- 第五页的时候 倍数和winall 播放大奖动画
            if selfdata.extra.floor == 5 then
                if selfdata.content[self.m_clickPos] == "end" then
                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_It.mp3")
                    util_spinePlay(self.m_zooGuanLiYuan,"actionframe_zhongjiang_end",false)
                else
                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_Good.mp3")
                    util_spinePlay(self.m_zooGuanLiYuan,"actionframe_zhongjiang_dajiang",false)
                end
            else
                if selfdata.content[self.m_clickPos] == "winAll" then
                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_Good.mp3")
                    util_spinePlay(self.m_zooGuanLiYuan,"actionframe_zhongjiang_dajiang",false)
                elseif selfdata.content[self.m_clickPos] == "end" then
                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_It.mp3")
                    util_spinePlay(self.m_zooGuanLiYuan,"actionframe_zhongjiang_end",false)
                else
                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_Well.mp3")
                    util_spinePlay(self.m_zooGuanLiYuan,"actionframe_zhongjiang_putong",false)
                end
            end

            performWithDelay(self,function(  )
                if selfdata.content[self.m_clickPos] == "winAll" then
                    for i=1,5 do
                        if i ~= self.m_clickPos and selfdata.content[i] == "winAll" then
                            self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(true)
                        elseif i ~= self.m_clickPos and selfdata.content[i] == "end" then
                            self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(true)
                        elseif i ~= self.m_clickPos then
                            local startPosWord = self.m_dongWu[i]:getParent():convertToWorldSpace(cc.p(self.m_dongWu[i]:getPosition()))
                            local startPos = self:convertToNodeSpace(startPosWord)
                            
                            local endPosWord = self.m_multipler:getParent():convertToWorldSpace(cc.p(self.m_multipler:getPosition()))
                            local endPos = self:convertToNodeSpace(endPosWord)
        
                            self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)

                            self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)

                            self:runFlyLineAct(selfdata.content[i], startPos, endPos, function() 
                                self.m_multiplerBaoDian:setVisible(true)
                                self.m_multiplerBaoDian:runCsbAction("actionframe1",false)
                                self.m_multipler:findChild("m_lb_beishu"):setString(selfdata.extra.totalMultiple .. "X")
                                self:updateSizeBeiShu()
                                
                                if selfdata.extra.floor ~= 5 then
                                    for i=1,5 do
                                        self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_01"):setVisible(false)
                                        self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_02"):setVisible(false)
                                        self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_03"):setVisible(false)
                                        self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_04"):setVisible(false)
                                        self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_05"):setVisible(false)

                                        self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_0"..selfdata.extra.floor+1):setVisible(true)
                                    end

                                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_DiMianZhuan.mp3")
                                    self.m_bonusGameBgGunDong:runCsbAction("actionframe",false,function()
                                        self.m_bonusGameBgGunDong:runCsbAction("idleframe",false)
                                        self.m_dongWuBg:runCsbAction("idleframe",false)
                                    end)
                                    self.m_dongWuBg:runCsbAction("actionframe",false,function()
                                        
                                    end)
                                    self.m_dongWuBg1:runCsbAction("actionframe",false,function()
                                        self.m_dongWuBg1:runCsbAction("idleframe",false)
                                    end)
                                end

                                performWithDelay(self,function(  )
                                    if selfdata.status == "CLOSED" then
                                    else
                                        for i = 1, 5 do
                                            self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
                                            self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
                                            self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
                                            self.m_dongWu[i]:findChild("ZooMania_end_6"):setColor(cc.c3b(255,255,255))
                                            self.m_dongWu[i]:findChild("ZooMania_winall_7"):setColor(cc.c3b(255,255,255))
                                            self.m_dongWu[i]:findChild("m_lb_beishu"):setColor(cc.c3b(255,255,255))
                                            self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
                
                                            self.m_dongWu[i]:findChild("dark_animal01"):setVisible(false)
                                            self.m_dongWu[i]:findChild("dark_animal02"):setVisible(false)
                                            self.m_dongWu[i]:findChild("dark_animal03"):setVisible(false)
                                            self.m_dongWu[i]:findChild("dark_animal04"):setVisible(false)
                                            self.m_dongWu[i]:findChild("dark_animal05"):setVisible(false)
                                            
                                            self.m_dongWu[i]:runCsbAction("idleframe",false)
                                            for m=1,5 do
                                                self.m_dongWuSpine[i][m]:setVisible(false)
                                            end
                                            self.m_dongWuSpine[i][selfdata.extra.floor+1]:setVisible(true)
                                            util_spinePlay(self.m_dongWuSpine[i][selfdata.extra.floor+1],"idleframe2",false)
                                        end
                                        self:clearScheduler()
                                        self:randomPlayAnimalSpineScheduler(selfdata.extra.floor+1)
                                        self.m_action=self.ACTION_RECV
                                    end
                                end,60/60)
                            end)
                        end
                    end
                    if selfdata.status == "CLOSED" then
                        performWithDelay(self,function(  )
                            self.m_multipler:findChild("m_lb_coins_jiesuan"):setString(util_formatCoins(self.m_machine.m_runSpinResultData.p_bet
                                * selfdata.extra.totalMultiple, 30))
                            self:updateSizeJieSuan()

                            gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_KuangHe.mp3")
                            self.m_multipler:runCsbAction("actionframe",false,function()
                                
                                performWithDelay(self,function(  )
                                    self.m_multipler:setVisible(false)
                                    self.m_bonusGameBgGunDong:runCsbAction("actionframe1",true)
                                    self.m_dongWuBg:runCsbAction("actionframe1",false)
                                    performWithDelay(self,function(  )
                                        if self.m_bonusEndCall then
                                            self.m_bonusEndCall()
                                        end
                                    end,24/60)
                                    performWithDelay(self,function(  )
                                        self.m_bonusGameBgGunDong:runCsbAction("idleframe",true)
                                        self.m_dongWuBg:runCsbAction("idleframe",false)
                                    end,2)
                                    
                                end,1.5)
                            end)
                            performWithDelay(self,function(  )
                                self.m_machine:clearCurMusicBg()
                                gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMaina_bonus_over.mp3")
                            end,1)
                            
                        end,2.2)
                    end
                elseif selfdata.content[self.m_clickPos] == "end" then
                    
                    if selfdata.status == "CLOSED" then
                        
                        self.m_multipler:findChild("m_lb_coins_jiesuan"):setString(util_formatCoins(self.m_machine.m_runSpinResultData.p_bet
                            * selfdata.extra.totalMultiple, 30))
                        self:updateSizeJieSuan()

                        gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_KuangHe.mp3")
                        self.m_multipler:runCsbAction("actionframe",false,function()
                            
                            performWithDelay(self,function(  )
                                self.m_multipler:setVisible(false)
                                self.m_bonusGameBgGunDong:runCsbAction("actionframe1",true)
                                self.m_dongWuBg:runCsbAction("actionframe1",false)
                                performWithDelay(self,function(  )
                                    if self.m_bonusEndCall then
                                        self.m_bonusEndCall()
                                    end
                                end,24/60)
                                performWithDelay(self,function(  )
                                    self.m_bonusGameBgGunDong:runCsbAction("idleframe",true)
                                    self.m_dongWuBg:runCsbAction("idleframe",false)
                                end,2)
                            end,1.5)
                        end)
                        performWithDelay(self,function(  )
                            self.m_machine:clearCurMusicBg()
                            gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMaina_bonus_over.mp3")
                        end,1)
                    end
                else
                    local startPosWord = self.m_dongWu[self.m_clickPos]:getParent():convertToWorldSpace(cc.p(self.m_dongWu[self.m_clickPos]:getPosition()))
                    local startPos = self:convertToNodeSpace(startPosWord)
                    
                    local endPosWord = self.m_multipler:getParent():convertToWorldSpace(cc.p(self.m_multipler:getPosition()))
                    local endPos = self:convertToNodeSpace(endPosWord)
        
                    self.m_dongWu[self.m_clickPos]:findChild("m_lb_beishu"):setVisible(false)
                    self.m_dongWu[self.m_clickPos]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
                    self:runFlyLineAct(selfdata.content[self.m_clickPos], startPos, endPos, function() 
                        self.m_multiplerBaoDian:setVisible(true)
                        self.m_multiplerBaoDian:runCsbAction("actionframe1",false)
                        self.m_multipler:findChild("m_lb_beishu"):setString(selfdata.extra.totalMultiple .. "X")
                        self:updateSizeBeiShu()
                        
                        if selfdata.extra.floor ~= 5 then
                            for i=1,5 do
                                self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_01"):setVisible(false)
                                self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_02"):setVisible(false)
                                self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_03"):setVisible(false)
                                self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_04"):setVisible(false)
                                self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_05"):setVisible(false)

                                self.m_dongWuBg1:findChild("ZooMania_animal_"..i.."_0"..selfdata.extra.floor+1):setVisible(true)
                            end
                            
                            gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_DiMianZhuan.mp3")
                            self.m_bonusGameBgGunDong:runCsbAction("actionframe",false,function()
                                self.m_bonusGameBgGunDong:runCsbAction("idleframe",false)
                                self.m_dongWuBg:runCsbAction("idleframe",false)
                            end)
                            self.m_dongWuBg:runCsbAction("actionframe",false,function()
                                
                            end)
                            self.m_dongWuBg1:runCsbAction("actionframe",false,function()
                                self.m_dongWuBg1:runCsbAction("idleframe",false)
                            end)
                        end

                        performWithDelay(self,function(  )
                            if selfdata.status == "CLOSED" then
                                self.m_multipler:findChild("m_lb_coins_jiesuan"):setString(util_formatCoins(self.m_machine.m_runSpinResultData.p_bet
                                    * selfdata.extra.totalMultiple, 30))
                                self:updateSizeJieSuan()

                                gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_KuangHe.mp3")
                                self.m_multipler:runCsbAction("actionframe",false,function()
                                    
                                    performWithDelay(self,function(  )
                                        self.m_multipler:setVisible(false)
                                        self.m_bonusGameBgGunDong:runCsbAction("actionframe1",true)
                                        self.m_dongWuBg:runCsbAction("actionframe1",false)
                                        performWithDelay(self,function(  )
                                            if self.m_bonusEndCall then
                                                self.m_bonusEndCall()
                                            end
                                        end,24/60)
                                        performWithDelay(self,function(  )
                                            self.m_bonusGameBgGunDong:runCsbAction("idleframe",true)
                                            self.m_dongWuBg:runCsbAction("idleframe",false)
                                        end,2)
                                    end,1.5)
                                end)
                                performWithDelay(self,function(  )
                                    self.m_machine:clearCurMusicBg()
                                    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMaina_bonus_over.mp3")
                                end,1)
                            else
                                for i = 1, 5 do
                                    self.m_dongWu[i]:findChild("ZooMania_end_6"):setVisible(false)
                                    self.m_dongWu[i]:findChild("ZooMania_winall_7"):setVisible(false)
                                    self.m_dongWu[i]:findChild("m_lb_beishu"):setVisible(false)
                                    self.m_dongWu[i]:findChild("ZooMania_end_6"):setColor(cc.c3b(255,255,255))
                                    self.m_dongWu[i]:findChild("ZooMania_winall_7"):setColor(cc.c3b(255,255,255))
                                    self.m_dongWu[i]:findChild("m_lb_beishu"):setColor(cc.c3b(255,255,255))
                                    self.m_dongWu[i]:findChild("ZooMania_chengbeidi_8"):setVisible(false)
        
                                    self.m_dongWu[i]:findChild("dark_animal01"):setVisible(false)
                                    self.m_dongWu[i]:findChild("dark_animal02"):setVisible(false)
                                    self.m_dongWu[i]:findChild("dark_animal03"):setVisible(false)
                                    self.m_dongWu[i]:findChild("dark_animal04"):setVisible(false)
                                    self.m_dongWu[i]:findChild("dark_animal05"):setVisible(false)
    
                                    self.m_dongWu[i]:runCsbAction("idleframe",false)
                                    for m=1,5 do
                                        self.m_dongWuSpine[i][m]:setVisible(false)
                                    end
                                    self.m_dongWuSpine[i][selfdata.extra.floor+1]:setVisible(true)
                                    util_spinePlay(self.m_dongWuSpine[i][selfdata.extra.floor+1],"idleframe2",false)
                                end
                                self:clearScheduler()
                                self:randomPlayAnimalSpineScheduler(selfdata.extra.floor+1)
                                self.m_action=self.ACTION_RECV
                            end
                            
                        end,60/60)
                    end)
                end
            end,1.8)
        end,1)

    end)
    
end

--开始结束流程
function ZooManiaBonusGameChooseView:gameOver(isContinue)

end

--弹出结算奖励
function ZooManiaBonusGameChooseView:showReward()

end

function ZooManiaBonusGameChooseView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            -- dump(spinData.result, "featureResultCallFun data")
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
    
            if spinData.action == "FEATURE" then
                self.m_featureData:parseFeatureData(spinData.result)
                self.m_spinDataResult = spinData.result
    
                -- self.m_machine:SpinResultParseResultData( spinData)
                self:recvBaseData(self.m_featureData)
      
            elseif self.m_isBonusCollect then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            else
                dump(spinData.result, "featureResult action"..spinData.action, 3)
            end
        else
            -- 处理消息请求错误情况
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
    end 
end

function ZooManiaBonusGameChooseView:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
end

function ZooManiaBonusGameChooseView:setEndCall( func)
    self.m_bonusEndCall = function(  )
        local coins = self.m_serverWinCoins

        local lastWinCoin = globalData.slotRunData.lastWinCoin
        
        local isUpdateTopUI = true     
        
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
            self.m_machine:checkFeatureOverTriggerBigWin( self.m_serverWinCoins, GameEffect.EFFECT_BONUS)
            isUpdateTopUI = false    
            globalData.slotRunData.lastWinCoin = coins+lastWinCoin
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isUpdateTopUI,true})
        else
            self.m_machine.m_runSpinResultData.p_features = {0}
            self.m_machine:getBonusOverCoin(self.m_serverWinCoins)
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isUpdateTopUI,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end
        self.m_machine:checkAddEffect()
        

        -- globalData.slotRunData.lastWinCoin = lastWinCoin 
        
        self.m_machine:resetMusicBg()

        if func then
            func()
        end  
        
    end 
end

function ZooManiaBonusGameChooseView:runFlyLineAct(multiple,startPos,endPos,func)

    gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_CollectFly.mp3")
    -- 创建粒子
    local flyNode =  util_createAnimation("ZooMania_dongwu_tuowei.csb")
    self:addChild(flyNode,300000)

    flyNode:setPosition(cc.p(startPos))
    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 430 )

    --创建临时乘倍标签和粒子一起飞下去
    local lbl_fnt_temp = ccui.TextBMFont:create()
    lbl_fnt_temp:setFntFile("Font/font_02.fnt")
    lbl_fnt_temp:setString(multiple.."X")
    lbl_fnt_temp:setScale(0.95)
    lbl_fnt_temp:setAnchorPoint(0.5, 0.5)
    lbl_fnt_temp:setPosition(startPos)
    self:addChild(lbl_fnt_temp,300001)
    lbl_fnt_temp:setLocalZOrder(flyNode:getLocalZOrder() + 1)
    lbl_fnt_temp:runAction(cc.Sequence:create({
        cc.MoveTo:create(35/60,endPos),
        cc.RemoveSelf:create(true)
    }))

    flyNode:runCsbAction("actionframe",false,function(  )

            if func then
                func()
            end

            flyNode:stopAllActions()
            flyNode:removeFromParent()
    end)

    return flyNode

end
return ZooManiaBonusGameChooseView