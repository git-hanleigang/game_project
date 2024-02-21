---
--xcyy
--2018年5月23日
--ReelRocksCompetitionOverView.lua
--集满火车玩法结束
local ReelRocksCompetitionOverView = class("ReelRocksCompetitionOverView",util_require("base.BaseView"))

--data1为排名情况，data2为显示左上角collectAvgBet,index为玩家选择的车
function ReelRocksCompetitionOverView:initUI(data1,data2,index)

    self:createCsbNode("ReelRocks/ReelRocks_bisaiOver.csb")
    self.playerChoose = index

    self.collectWinCoins = data2.collectWinCoins or 0

    self.viewBg = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks/GameScreenReelRocksBg")      --背景
    self:findChild("Node_bg"):addChild(self.viewBg)
    self.viewBg:runCsbAction("idle3",false)

    self.priceKuang = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_bisai_pricekuang")     --左上角显示平均倍数
    self:findChild("bisai_pricekuang"):addChild(self.priceKuang)
    self.priceKuang:changeNum(util_formatCoins(data2.collectAvgBet,3))

    self.renQun = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_bisai_renqun")  --人群
    self:findChild("renqun"):addChild(self.renQun)
    self.renQun:runCsbAction("idle2",true)

    self:showRanking(data1,data2,index)
    performWithDelay(self,function (  )
        if self.m_bonusEndCall then
            self.m_bonusEndCall()
        end
    end,6)
end

--data1中v[1]为车的index，v[2]为名次
--展示排名和钱数
function ReelRocksCompetitionOverView:showRanking(data1,data2,index)
    local rankMultiplies = data2.rankMultiplies
    for i,v in ipairs(data1) do
        local carNode = self:getCarForTank(v[1])
        if index == v[1] then
            self.biaoJi = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRock_biaoji")
            carNode:addChild(self.biaoJi)

            self.playerCar = carNode

            self.biaoJi:setPosition(cc.p(0,400))
            self.biaoJi:runCsbAction("idle",true)
        end
        local act = self:getEndAct(v[2]) 
        self:findChild("Node_bisai_che_"..v[2]):addChild(carNode)
        local rankMultiplies = rankMultiplies[i]
        self:findChild("m_lb_num_"..i):setString(rankMultiplies.."X")
        util_spinePlay(carNode,act,true)
    end
    performWithDelay(self,function (  )
        local startPos = util_convertToNodeSpace(self.playerCar,self:findChild("Node_1"))
        local endPos = util_convertToNodeSpace(self.priceKuang,self:findChild("Node_1"))
        self:runFlyLineAct(startPos,endPos,function (  )
            self.priceKuang:runCsbAction("actionframe",false)
            performWithDelay(self,function (  )
                self.priceKuang:changeNum(util_formatCoins(self.collectWinCoins,3))
            end,0.05)
        end)
    end,3)
end


function ReelRocksCompetitionOverView:getEndAct(rank)
    if rank == 1 then
        return "idleframe8"
    elseif rank == 2 then
        return "idleframe9"
    elseif rank == 3 then
        return "idleframe10"
    end
end

function ReelRocksCompetitionOverView:getCarForTank(carIndex)
    if carIndex == 1 then
        return util_spineCreate("Socre_ReelRocks_5",true,true)
    elseif carIndex == 2 then
        return util_spineCreate("Socre_ReelRocks_8",true,true)
    elseif carIndex == 3 then
        return util_spineCreate("Socre_ReelRocks_6",true,true)
    end
end

function ReelRocksCompetitionOverView:runFlyLineAct(startPos,endPos,func)
    -- -- 创建粒子
    local flyNode =  util_createAnimation("ReelRocks_car_tuowei.csb")

    flyNode:findChild("4"):setVisible(true)
    flyNode:findChild("4"):resetSystem()
    flyNode:findChild("4"):setDuration(-1)     --设置拖尾时间(生命周期)
    flyNode:findChild("4"):setPositionType(0)   --设置可以拖尾

    self:findChild("Node_1"):addChild(flyNode)
    flyNode:setPosition(startPos)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:runCsbAction("actionframe",true)
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_bisai_fly.mp3")
    end)
    actList[#actList + 1] = cc.MoveTo:create(1,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        flyNode:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)
end

function ReelRocksCompetitionOverView:setEndCall(func)
    self.m_bonusEndCall = func
end

function ReelRocksCompetitionOverView:onEnter()
 

end


function ReelRocksCompetitionOverView:onExit()
 
end

--默认按钮监听回调
function ReelRocksCompetitionOverView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ReelRocksCompetitionOverView