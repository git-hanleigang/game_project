---
--xcyy
--2018年5月23日
--TripletroveCaseView.lua

local TripletroveCaseView = class("TripletroveCaseView",util_require("Levels.BaseLevelDialog"))

local CURRENCY_NUM = {
    ONE = 1,
    TWO = 2,
    THREE = 3,
    FOUR = 4,
    FIVE = 5,
    SIX = 6,
    SEVEN = 7,
    EIGHT = 8,
    NINE = 9,
    TEN = 10,
    ZERO = 0
}

function TripletroveCaseView:initUI(index)
    self:createCsbNode("Tripletrove_jinxiang.csb")
    self:changeCaseForIndex(index)
    self.boom = util_spineCreate("Tripletrove_Xiangzifankui",true,true)
    self:findChild("case_fankui"):addChild(self.boom)
    self.caseStateIndex = CURRENCY_NUM.ZERO

end

function TripletroveCaseView:changeCaseForIndex(index)
    local spineFile = nil
    if index == 1 then
        spineFile = "Tripletrove_Xiangzilan"
    elseif index == 2 then
        spineFile = "Tripletrove_Xiangzi"
    elseif index == 3 then
        spineFile = "Tripletrove_Xiangzihong"
    else
        spineFile = "Tripletrove_Xiangzi"
    end

    self.colorCase = util_spineCreate(spineFile,true,true)    
    self:findChild("case"):addChild(self.colorCase)
end

function TripletroveCaseView:updateCaseState(index,isInit,isFree)
    if isInit then      --进入关卡初始化和free结束用
        if isFree then
            if index == CURRENCY_NUM.ZERO then
                util_spinePlay(self.colorCase,"idleframecf2",false)
                self:delayCallBack(1/30,function (  )
                    util_spinePlay(self.colorCase,"idleframe",true)
                end)
            elseif index == CURRENCY_NUM.ONE then
                util_spinePlay(self.colorCase,"idleframe1",true)
            elseif index == CURRENCY_NUM.TWO then
                util_spinePlay(self.colorCase,"idleframe2",true)
            elseif index == CURRENCY_NUM.THREE then
                util_spinePlay(self.colorCase,"idleframe3",true)
            end
        else
            if index == CURRENCY_NUM.ZERO then
                if self.caseStateIndex == CURRENCY_NUM.ZERO then
                    util_spinePlay(self.colorCase,"idleframe",true)
                elseif self.caseStateIndex == CURRENCY_NUM.ONE then
                    util_spinePlay(self.colorCase,"idleframeliang1",false)
                    self:delayCallBack(1/30,function (  )
                        util_spinePlay(self.colorCase,"idleframe",true)
                    end)
                elseif self.caseStateIndex == CURRENCY_NUM.TWO then
                    util_spinePlay(self.colorCase,"idleframeliang2",false)
                    self:delayCallBack(1/30,function (  )
                        util_spinePlay(self.colorCase,"idleframe",true)
                    end)
                elseif self.caseStateIndex == CURRENCY_NUM.THREE then
                    util_spinePlay(self.colorCase,"idleframeliang3",false)
                    self:delayCallBack(1/30,function (  )
                        util_spinePlay(self.colorCase,"idleframe",true)
                    end)
                else
                    util_spinePlay(self.colorCase,"idleframe",true)
                end
                
            elseif index == CURRENCY_NUM.ONE then
                util_spinePlay(self.colorCase,"idleframe1",true)
            elseif index == CURRENCY_NUM.TWO then
                util_spinePlay(self.colorCase,"idleframe2",true)
            elseif index == CURRENCY_NUM.THREE then
                util_spinePlay(self.colorCase,"idleframe3",true)
            end
        end
        
        self.caseStateIndex = index
    else
        if isFree then      --是否触发free
            if self.caseStateIndex == CURRENCY_NUM.ZERO then
                util_spinePlay(self.colorCase,"switch3",false)
            elseif self.caseStateIndex == CURRENCY_NUM.ONE then
                util_spinePlay(self.colorCase,"switch4",false)
            elseif self.caseStateIndex == CURRENCY_NUM.TWO then
                util_spinePlay(self.colorCase,"switch2",false)
            elseif self.caseStateIndex == CURRENCY_NUM.THREE then
                util_spinePlay(self.colorCase,"shouji6",false)
            end
            self.caseStateIndex = 3
        else
            if self.caseStateIndex == index then        --收集但不升级
                if self.caseStateIndex == CURRENCY_NUM.ONE then
                    util_spinePlay(self.colorCase,"shouji4",false)
                    util_spineEndCallFunc(self.colorCase,"shouji4",function (  )
                        util_spinePlay(self.colorCase,"idleframe1",true)
                    end)
                elseif self.caseStateIndex == CURRENCY_NUM.TWO then
                    util_spinePlay(self.colorCase,"shouji5",false)
                    util_spineEndCallFunc(self.colorCase,"shouji5",function (  )
                        util_spinePlay(self.colorCase,"idleframe2",true)
                    end)
                elseif self.caseStateIndex == CURRENCY_NUM.THREE then
                    util_spinePlay(self.colorCase,"shouji6",false)
                    util_spineEndCallFunc(self.colorCase,"shouji6",function (  )
                        util_spinePlay(self.colorCase,"idleframe3",true)
                    end)
                end
            else        --收集并且升级
                if self.caseStateIndex == CURRENCY_NUM.ZERO then
                    util_spinePlay(self.colorCase,"switch",false)
                    util_spineEndCallFunc(self.colorCase,"switch",function (  )
                        util_spinePlay(self.colorCase,"idleframe1",true)
                    end)
                elseif self.caseStateIndex == CURRENCY_NUM.ONE then
                    util_spinePlay(self.colorCase,"switch1",false)
                    util_spineEndCallFunc(self.colorCase,"switch1",function (  )
                        util_spinePlay(self.colorCase,"idleframe2",true)
                    end)
                elseif self.caseStateIndex == CURRENCY_NUM.TWO then
                    util_spinePlay(self.colorCase,"switch2",false)
                    util_spineEndCallFunc(self.colorCase,"switch2",function (  )
                        util_spinePlay(self.colorCase,"idleframe3",true)
                    end)

                end
                
            end
            self.caseStateIndex = index
        end
        
    end
    
end

function TripletroveCaseView:showCaseAdditionEffect()
    if self.caseStateIndex == CURRENCY_NUM.ONE then
        util_spinePlay(self.colorCase,"shouji1",false)
        util_spineEndCallFunc(self.colorCase,"shouji1",function (  )
            util_spinePlay(self.colorCase,"idleframe1",true)
        end)
    elseif self.caseStateIndex == CURRENCY_NUM.TWO then
        util_spinePlay(self.colorCase,"shouji2",false)
        util_spineEndCallFunc(self.colorCase,"shouji2",function (  )
            util_spinePlay(self.colorCase,"idleframe2",true)
        end)
    elseif self.caseStateIndex == CURRENCY_NUM.THREE then
        util_spinePlay(self.colorCase,"shouji3",false)
        util_spineEndCallFunc(self.colorCase,"shouji3",function (  )
            util_spinePlay(self.colorCase,"idleframe3",true)
        end)
    end
end

--触发
function TripletroveCaseView:showFreeSpinForCase(func)
    util_spinePlay(self.colorCase,"actionframe",false)
    self:delayCallBack(5/3,function (  )
        util_spinePlay(self.colorCase,"idleframecf",true)
        if func then
            func()
        end
    end)
end

--展示爆点
function TripletroveCaseView:showBoomEffect( )
    util_spinePlay(self.boom,"shoujibaodian",false)
end

function TripletroveCaseView:initTriggerShow( )
    util_spinePlay(self.colorCase,"idleframecf",true)
end

--不触发free的宝箱压黑
function TripletroveCaseView:showDarkEffect( )
    if self.caseStateIndex == CURRENCY_NUM.ZERO then
        util_spinePlay(self.colorCase,"idleframean",false)
    elseif self.caseStateIndex == CURRENCY_NUM.ONE then
        util_spinePlay(self.colorCase,"idleframean1",false)
    elseif self.caseStateIndex == CURRENCY_NUM.TWO then
        util_spinePlay(self.colorCase,"idleframean2",false)
    elseif self.caseStateIndex == CURRENCY_NUM.THREE then
        util_spinePlay(self.colorCase,"idleframean3",false)
    else
        util_spinePlay(self.colorCase,"idleframean",false)
    end
    
end

--延迟回调
function TripletroveCaseView:delayCallBack(time, func)
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

return TripletroveCaseView