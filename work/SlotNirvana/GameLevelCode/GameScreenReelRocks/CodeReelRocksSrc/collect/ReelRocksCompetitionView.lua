---
--xcyy
--2018年5月23日
--ReelRocksCompetitionView.lua
--集满火车玩法  将车进行编号：绿色：1   红色：2   蓝色：3
local ReelRocksCompetitionView = class("ReelRocksCompetitionView",util_require("base.BaseView"))
local SWITCHNUM = 3

--比赛中，小车移动六段
local startPos = 70
local midPos1 = 286
local midPos2 = 502
local midPos3 = 718
local endPos = 1000


function ReelRocksCompetitionView:initUI(data)

    self:createCsbNode("ReelRocks/ReelRocks_bisai.csb")

    self.viewBg = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks/GameScreenReelRocksBg")      --背景
    self:findChild("Node_Bg"):addChild(self.viewBg)
    self.viewBg:setPosition(cc.p(0,0))
    self.viewBg:runCsbAction("idle4",true)

    --根据不同颜色创建车，并加到对应位置
    self.car1 = self:findChild("Node_bisai_che_lv")
    self.car2 = self:findChild("Node_bisai_che_hong")
    self.car3 = self:findChild("Node_bisai_che_lan")

    --旗子
    self.bao1 = self:findChild("bao1")
    self.bao2 = self:findChild("bao2")
    self.bao3 = self:findChild("bao3")
    self.switchList = {}
    self.date = data
    self.playerChoose = 0
    self:initSwitch()
    self:initCar()
    self:initFlags()
    self.endList = {}
    self:showSwitchAct()        --开关打开，小车开始移动
end

--比赛背景
function ReelRocksCompetitionView:levelBiSaiChangeEffect()
    self.viewBg:runCsbAction("actionframe")
    self:runCsbAction("actionframe",false)
end

function ReelRocksCompetitionView:levelBiSaiOverChangeEffect( )
    self:runCsbAction("idle2",false)
end

function ReelRocksCompetitionView:initSwitch()
    for i=1,SWITCHNUM do
        local switch = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_kaiguan")
        self:findChild("ReelRocks_kaiguan_"..i):addChild(switch)
        table.insert(self.switchList,switch)
    end
end

--初始化车和标记
function ReelRocksCompetitionView:initCar( )
    self.kuangGong_1 = util_spineCreate("Socre_ReelRocks_5",true,true)
    self.car1:addChild(self.kuangGong_1)
    self.biaoJi_1 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRock_biaoji")
    self.kuangGong_1:addChild(self.biaoJi_1)
    self.biaoJi_1:setPosition(cc.p(0,200))
    self.biaoJi_1:setVisible(false)
    util_spinePlay(self.kuangGong_1,"idleframe2",true)
    self.kuangGong_2 = util_spineCreate("Socre_ReelRocks_8",true,true)
    self.car2:addChild(self.kuangGong_2)
    self.biaoJi_2 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRock_biaoji")
    self.kuangGong_2:addChild(self.biaoJi_2)
    self.biaoJi_2:setPosition(cc.p(0,200))
    self.biaoJi_2:setVisible(false)
    util_spinePlay(self.kuangGong_2,"idleframe2",true)
    self.kuangGong_3 = util_spineCreate("Socre_ReelRocks_6",true,true)
    self.car3:addChild(self.kuangGong_3)
    self.biaoJi_3 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRock_biaoji")
    self.kuangGong_3:addChild(self.biaoJi_3)
    self.biaoJi_3:setPosition(cc.p(0,200))
    self.biaoJi_3:setVisible(false)
    util_spinePlay(self.kuangGong_3,"idleframe2",true)
end

function ReelRocksCompetitionView:initFlags()
    self.baoNode1 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_bisai_bao")      --旗子爆炸
    self.bao1:addChild(self.baoNode1)
    self.baoNode2 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_bisai_bao")      --旗子爆炸
    self.bao2:addChild(self.baoNode2)
    self.baoNode3 = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_bisai_bao")      --旗子爆炸
    self.bao3:addChild(self.baoNode3)
end

function ReelRocksCompetitionView:showSwitchAct(func )
    
    performWithDelay(self,function (  )
        self:levelBiSaiChangeEffect()
        self:updateCarPos()
    end,3)
    performWithDelay(self,function (  )
        self:closeUi()
    end,10)
end

--分别为三个车播放时间线动画（同时进行车的移动）
function ReelRocksCompetitionView:updateCarPos( )
    local tempList = {1,2,3}    --车
    local list = {}
    local rank = self.date.rank + 1 or 1      --服务器给到的名次   0-1
    --玩家选择的车
    local playerChooseCar,playBao,playBiaoJi = self:getCarForIndex(self.playerChoose)
    playBiaoJi:setVisible(true)
    playBiaoJi:runCsbAction("idle",true)
    local chooseTime1,chooseTime2,chooseTime3,chooseTime4 = self:getCarTime(rank)
    table.insert(self.endList,{self.playerChoose,rank})
    self:changeCarMovePos(playerChooseCar,playBao,rank,chooseTime1,chooseTime2,chooseTime3,chooseTime4)
    table.remove( tempList,self.playerChoose)
    local listOther = self:randomOtherank(rank)

    --其他车
    for i,v in ipairs(tempList) do
        local carNode,bao,biaoJi = self:getCarForIndex(v)
        biaoJi:setVisible(false)
        local time1,time2,time3,time4 = self:getCarTime(listOther[i])
        --保存车的排名
        table.insert(self.endList,{v,listOther[i]})
        self:changeCarMovePos(carNode,bao,listOther[i],time1,time2,time3,time4)
    end
end

function ReelRocksCompetitionView:getCarTime(rank)
    if rank == 1 then
        return 1.5,2,1.5,1
    elseif rank == 2 then
        return 2,1,2,1.5
    elseif rank == 3 then
        return 2,1.2,1.5,2
    end
end

function ReelRocksCompetitionView:randomOtherank(index)
    local list = {1,2,3}
    table.remove(list,index)
    local isSwith = (1 == math.random(1,2))
    if isSwith then
        list[2],list[1] = list[1],list[2]
    end
    return list
end

function ReelRocksCompetitionView:changeCarMovePos(node,bao,rank,time1,time2,time3,time4)
    local soundID = nil
    local actForRank = self:getActForRank(rank)
    self:showNumber(bao,rank)
    local actList = {}

    --小车移动，分为六段
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        util_spinePlay(node,"idleframe7",true)
    end)
    actList[#actList + 1]  = cc.MoveTo:create(time1,cc.p(midPos1,0))
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        soundID = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_car_fast.mp3")
        util_spinePlay(node,actForRank[1],true)
    end)
    actList[#actList + 1]  = cc.MoveTo:create(time2,cc.p(midPos2,0))
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        if soundID then
            gLobalSoundManager:stopAudio(soundID)
        end
        util_spinePlay(node,"idleframe7",true)
    end)
    actList[#actList + 1]  = cc.MoveTo:create(time3,cc.p(midPos3,0))
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        soundID = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_car_fast.mp3")
        util_spinePlay(node,actForRank[2],true)
     end)
    actList[#actList + 1]  = cc.MoveTo:create(time4,cc.p(endPos,0))
    actList[#actList + 1]  = cc.CallFunc:create(function (  )
        if soundID then
            gLobalSoundManager:stopAudio(soundID)
        end
        util_spinePlay(node,"idleframe2",true)
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function (  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_biSai_carEnd.mp3")
        bao:runCsbAction("actionframe",false,function (  )
            bao:runCsbAction("idle",true)
        end)
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

function ReelRocksCompetitionView:showNumber(node,rank)
    for i=1,3 do
        node:findChild("num"..i):setVisible(false)
    end
    
    if rank == 1 then
        node:findChild("num1"):setVisible(true)
    elseif rank == 2 then
        node:findChild("num2"):setVisible(true)
    elseif rank == 3 then
        node:findChild("num3"):setVisible(true)
    end
end

function ReelRocksCompetitionView:getCarForIndex(index)
    if index == 1 then
        return self.kuangGong_1,self.baoNode2,self.biaoJi_1   
    elseif index == 2 then
        return self.kuangGong_2,self.baoNode3,self.biaoJi_2
    elseif index == 3 then
        return self.kuangGong_3,self.baoNode1,self.biaoJi_3
    end
    return nil,nil
end

function ReelRocksCompetitionView:getEndList( )
    return self.endList
end

function ReelRocksCompetitionView:getActForIndex(index)
    if index == 1 then
        return "idleframe6"
    elseif index == 2 then
        return "idleframe7"
    elseif index == 3 then
        return "idleframe7"
    end
    return nil
end

function ReelRocksCompetitionView:getActForRank(rank)
    if rank == 1 then
        return {"idleframe7","idleframe6"}
    elseif rank == 2 then
        return {"idleframe6","idleframe7"}
    elseif rank == 3 then
        return {"idleframe6","idleframe7"}
    end
end


--玩家选择的车
function ReelRocksCompetitionView:setPlayerChoose(index)
    self.playerChoose = index
end

function ReelRocksCompetitionView:setViewDate(date)
    self.date = date
end

function ReelRocksCompetitionView:setEndCall( func)
    self.m_bonusEndCall = func
end

function ReelRocksCompetitionView:closeUi( func )
    -- performWithDelay(self,function (  )
        if self.m_bonusEndCall then
            self.m_bonusEndCall()
        end 
    -- end,0.5)
    
end

function ReelRocksCompetitionView:onEnter()
 
end


function ReelRocksCompetitionView:onExit()
    
end

--默认按钮监听回调
function ReelRocksCompetitionView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ReelRocksCompetitionView