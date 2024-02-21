---
--xcyy
--2018年5月23日
--LuckyRacingRankListView.lua

local LuckyRacingRankListView = class("LuckyRacingRankListView",util_require("base.BaseView"))


function LuckyRacingRankListView:initUI(params)

    local playersInfo = clone(params.playersInfo) 
    local winnerChairID = params.winnerChairID
    local choose = params.choose
    local bonusCountInfo = params.bonusCountInfo
    local scoreItem = params.scoreItem
    local lbl_total = params.lbl_total
    local winScore = params.winScore
    local mineScore = params.mineScore
    self.m_userMultiple = params.userMultiple
    self.m_winnerMultiple = 0
    self.m_callBack = params.callBack

    self:createCsbNode("LuckyRacing/WinnerTakeAll_2.csb")

    local light = util_createAnimation("LuckyRacing/WinnerTakeAll_guang.csb")
    light:runCsbAction("idle")
    self:findChild("Node_guang"):addChild(light)

    --临时奖杯
    local tempMineScore = util_createAnimation("LuckyRacing_JiangBei.csb")
    tempMineScore:findChild("Particle_1"):setVisible(false)
    self:addChild(tempMineScore,1003)
    tempMineScore:setPosition(util_convertToNodeSpace(mineScore,self))
    local str = mineScore:findChild("BitmapFontLabel_1"):getString()
    tempMineScore:findChild("BitmapFontLabel_1"):setString(str)
    local info={label = tempMineScore:findChild("BitmapFontLabel_1"),sx = 0.32,sy = 0.32}
    self:updateLabelSize(info,302)

    local endNode = self:findChild("Node_touxiang")

    local sp_sign_1 = self:findChild("winnerTakeAll")
    local sp_sign_2 = self:findChild("winnerTakeAll_0")

    for index = 1,6 do
        local particle_1 = self:findChild("Particle_"..index)
        particle_1:setVisible(false)

        local particle_2 = self:findChild("Particle_"..index.."_0")
        particle_2:setVisible(false)
    end

    local selfRank = 1
    for index = 1,4 do
        local info = bonusCountInfo[index]
        if bonusCountInfo[index].index == choose + 1 then
            selfRank = index
        end
        self.m_winnerMultiple = self.m_winnerMultiple + self.m_userMultiple[index]
    end

    
    self:findChild("BitmapFontLabel_3"):setString(util_formatCoins(winScore,50))
    self:updateLabelSize({label=self:findChild("BitmapFontLabel_3"),sx=1,sy=1},665)
    if selfRank == 1 then
        self:findChild("font_0_0"):setString("X"..self.m_winnerMultiple)
    else
        self:findChild("font_0_0"):setString("X"..self.m_userMultiple[selfRank])
    end
    

    --将自己放在对应的座位上
    for index = 1,4 do
        local info = playersInfo[index]
        if info and info.udid == globalData.userRunData.userUdid and index ~= selfRank then
            local temp = playersInfo[index]
            playersInfo[index] = playersInfo[selfRank]
            playersInfo[selfRank] = temp
            break
        end
    end

    --创建默认头像
    self.m_lbl_scores = {}
    self.m_headItems = {}

    --创建第一名
    self.m_firstItem = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = scoreItem.m_curIndex})
    self:addChild(self.m_firstItem,1000)
    self.m_firstItem:setPosition(util_convertToNodeSpace(scoreItem,self))
    self.m_firstItem:refreshData(scoreItem.m_playerInfo)
    self.m_firstItem:refreshHead(true)
    self.m_firstItem:showRank(1)
    self.m_headItems[1] = self.m_firstItem

    --分数框背景
    local scoreBg = util_createAnimation("LuckyRacing_touxiang_1.csb")
    self.m_firstItem:findChild("Node_touxiang_1"):addChild(scoreBg)
    self.m_firstItem.m_scoreBg = scoreBg

    --创建分数标签
    local lbl_score = util_createAnimation("LuckyRacing_WinnerTakeAll_1shouji.csb")
    lbl_score:runCsbAction("idle")
    scoreBg:findChild("Node_Font"):addChild(lbl_score)
    lbl_score:findChild("Font"):setString("X"..self.m_winnerMultiple)
    self.m_lbl_scores[1] = lbl_score

    for index = 2,4 do
        local item = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = bonusCountInfo[index].index})
        self.m_headItems[index] = item
        self:findChild("touxiang_"..(index - 1)):addChild(item,10)

        item:showRank(index)

        --分数框背景
        local scoreBg = util_createAnimation("LuckyRacing_touxiang_1.csb")
        item:findChild("Node_touxiang_1"):addChild(scoreBg)
        item.m_scoreBg = scoreBg

        --创建分数标签
        local lbl_score = util_createAnimation("LuckyRacing_WinnerTakeAll_1shouji.csb")
        lbl_score:runCsbAction("idle")
        scoreBg:findChild("Node_Font"):addChild(lbl_score)
        local score = self.m_userMultiple[index]
        lbl_score:findChild("Font"):setString("X"..score)
        self.m_lbl_scores[#self.m_lbl_scores + 1] = lbl_score

        local userInfo = playersInfo[index]
        if userInfo then
            --设置头像
            item:refreshData(userInfo)
            item:refreshHead(true)
        else
            --设置默认头像
            item:refreshData(nil)
            item:refreshHead(true)
        end
    end


    --总倍数标签
    local txt = util_createAnimation("LuckyRacing_free_shizi.csb")
    txt:findChild("font"):setString(lbl_total:getString())
    self:addChild(txt,1001)
    txt:setPosition(util_convertToNodeSpace(lbl_total,self))

    --移动放大动作
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_fly_total_mutiple.mp3")
    self.m_firstItem:runCsbAction("tobig",false,function()
        self.m_firstItem.m_scoreBg:runCsbAction("change")
    end)
    self.m_firstItem:runAction(cc.Sequence:create({
        cc.EaseOut:create(cc.MoveTo:create(30 / 60,util_convertToNodeSpace(endNode,self)),6)
        
    }))

    local endPos = util_convertToNodeSpace(endNode,self)

    txt:runCsbAction("tobig",false,function()
        txt:removeFromParent()
    end)
    txt:runAction(cc.Sequence:create({
        cc.EaseOut:create(cc.MoveTo:create(30 / 60,cc.p(endPos.x,endPos.y - 100)),6)
    }))

    util_setCascadeOpacityEnabledRescursion(self,true)

    sp_sign_1:setVisible(true)
    sp_sign_2:setVisible(false)

    performWithDelay(self,function()
        for index = 1,6 do
            local particle_1 = self:findChild("Particle_"..index)
            particle_1:setVisible(true)
            particle_1:resetSystem()

            local particle_2 = self:findChild("Particle_"..index.."_0")
            particle_2:setVisible(true)
            particle_2:resetSystem()
        end

    end,30 / 60)


    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function()
        node:removeFromParent()
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_show_winner_view.mp3")
    end,25 / 60)

    local node_1 = cc.Node:create()
    self:addChild(node_1)
    performWithDelay(node_1,function()
        
        self:runCsbAction("start",false,function()
            util_changeNodeParent(self:findChild("Node_touxiang"),self.m_firstItem)
            self.m_firstItem:setPosition(cc.p(0,0))
            --停1秒再变化
            performWithDelay(node_1,function ()
                node_1:removeFromParent()
                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_show_winner_other.mp3")
                self:runCsbAction("change",false,function()
                    performWithDelay(self,function()
                        for index = 1,4 do
                            if index == selfRank then
                                --终点坐标
                                local endPos = util_convertToNodeSpace(self:findChild("Node_1"),self.m_headItems[index]:getParent())
                                --头像移动
                                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_show_self_wincoin.mp3")
                                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_show_self_wincoins_music.mp3")
                                self.m_headItems[index]:runAction(cc.Sequence:create({
                                    cc.MoveTo:create(35 / 60,endPos),
                                }))

                                

                                if selfRank == 1 then
                                    self.m_headItems[index]:runCsbAction("tosmall")
                                else
                                    sp_sign_1:setVisible(false)
                                    sp_sign_2:setVisible(true)
                                end
        
                                --分数框移动
                                local pos = util_convertToNodeSpace(self.m_headItems[index].m_scoreBg,self)
                                util_changeNodeParent(self,self.m_headItems[index].m_scoreBg)
                                self.m_headItems[index].m_scoreBg:setPosition(pos)
        
                                self.m_headItems[index].m_scoreBg:runCsbAction("tobig",false,function()
                                    self.m_headItems[index].m_scoreBg:setVisible(false)
                                    util_changeNodeParent(self.m_headItems[index]:findChild("Node_touxiang_1"),self.m_headItems[index].m_scoreBg)
                                end)
                                local endPos2 = util_convertToNodeSpace(self:findChild("kuang"),self)
                                self.m_headItems[index].m_scoreBg:runAction(cc.MoveTo:create(35 / 60,endPos2))
        
                                self:runCsbAction("actionframe",false,function()
                                    self:overAni()
                                end)
        
                                performWithDelay(self,function()
                                    --分数标签
                                    local tempTxt = ccui.TextBMFont:create()
                                    tempTxt:setFntFile("Font/font_03.fnt")
                                    tempTxt:setString(str)
                                    local info={label = tempTxt,sx = 0.32,sy = 0.32}
                                    self:updateLabelSize(info,302)
                                    
                                    local flyAni = self:flyParticleAni3(mineScore:findChild("BitmapFontLabel_1"),self:findChild("BitmapFontLabel_3"),function()
                                        tempTxt:removeFromParent()
                                        tempMineScore:removeFromParent()
                                    end)
                                    flyAni:addChild(tempTxt)
                                    
                                    
                                end,89 / 60)
                                
                            else
                                self.m_headItems[index]:runAction(cc.FadeOut:create(0.3))
                            end
                            
                        end
                        
                    end,1.5)
                end)
                for index = 2,4 do
                    self.m_headItems[index].m_scoreBg:runCsbAction("change")
                end
            end,1)

            
        end)
    end,5 / 60)
end

--[[
    结束动画
]]
function LuckyRacingRankListView:overAni()

    performWithDelay(self,function()
        self:runCsbAction("over",false,function()
            if type(self.m_callBack) == "function" then
                self.m_callBack()
            end
            self:removeFromParent()
        end)
    end,1)
end

--[[
    赢家通吃动画
]]
function LuckyRacingRankListView:collectAni(func)
    local endNode = self.m_lbl_scores[1]
    for index = 2,4 do
        local score = self.m_userMultiple[index]
        self:flyParticleAni(self.m_lbl_scores[index],endNode,score)
    end
    performWithDelay(self,function()
        local ani = util_createAnimation("LuckyRacing_guakashoujifankui.csb")
        endNode:addChild(ani)
        endNode:findChild("Font"):setString("X"..self.m_winnerMultiple)
        ani:runCsbAction("zhongjiang",false,function ()
            ani:removeFromParent()

            if type(func) == "function" then
                func()
            end
        end)

        
    end,35 / 60)
end

--[[
    飞粒子动画
]]
function LuckyRacingRankListView:flyParticleAni(startNode,endNode,score,func)
    local ani = util_createAnimation("LuckyRacing_WinnerTakeAll_1shouji.csb")
    ani:findChild("ef_lizi"):setPositionType(0)
    ani:findChild("Font"):setString("X"..score)
    self:addChild(ani,100)

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    ani:setPosition(startPos)

    ani:runCsbAction("shouji")

    local seq = cc.Sequence:create({
        cc.DelayTime:create(10 / 60),
        cc.MoveTo:create(25 / 60,endPos),
        cc.CallFunc:create(function(  )
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })
    ani:runAction(seq)
    
end

--[[
    飞粒子动画
]]
function LuckyRacingRankListView:flyParticleAni2(startNode,endNode,score,func)
    local ani = util_createAnimation("LuckyRacing_WinnerTakeAll_1shouji.csb")
    ani:findChild("ef_lizi"):setPositionType(0)
    ani:findChild("Font"):setString("X"..score)
    self:addChild(ani,100)

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    ani:setPosition(startPos)

    ani:runCsbAction("shouji")

    local seq = cc.Sequence:create({
        cc.MoveTo:create(29/60,endPos),
        cc.CallFunc:create(function(  )
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })
    ani:runAction(seq)
    
end

--[[
    飞粒子动画
]]
function LuckyRacingRankListView:flyParticleAni3(startNode,endNode,func)
    local ani = util_createAnimation("LuckyRacing_shouji_tuowei.csb")
    for index = 1,6 do
        ani:findChild("Particle_"..index):setPositionType(0)
        ani:findChild("Particle_"..index):setDuration(-1)
    end
    
    self:addChild(ani,1100)

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    ani:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(25 / 60,util_convertToNodeSpace(self:findChild("BitmapFontLabel_3"),self)),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_fly_base_coin_feed_back.mp3")
            for index = 1,6 do
                ani:findChild("Particle_"..index):stopSystem()
            end
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()
    })

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_fly_base_coin.mp3")
    ani:runAction(seq)

    return ani
    
end

function LuckyRacingRankListView:onEnter()
    LuckyRacingRankListView.super.onEnter(self)
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end


return LuckyRacingRankListView