---
--xcyy
--2018年5月23日
--TripletroveRedFreeStartView.lua

local TripletroveRedFreeStartView = class("TripletroveRedFreeStartView",util_require("Levels.BaseLevelDialog"))


function TripletroveRedFreeStartView:initUI()

    self:createCsbNode("Tripletrove_hongstart.csb")
    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle",true)
    end)

    self.forkIndex = 0

end

function TripletroveRedFreeStartView:updateSymbolShow(index)
    if self.forkIndex > index then
        --展示
        self:delayCallBack(2,function (  )
            self:runCsbAction("over",false,function (  )
                self.forkIndex = 0
                if self.endFunc then
                    self.endFunc()
                end
                self:removeFromParent()
            end)
        end)
        
    else
        local fork = util_createAnimation("Tripletrove_cha.csb")
        local pos = util_convertToNodeSpace(self:getEndPosNode(self.forkIndex),self:findChild("Node_1"))
        self:findChild("Node_1"):addChild(fork)
        fork:setPosition(pos)
        gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_redFree_cha.mp3")
        fork:runCsbAction("start",false,function (  )
            fork:runCsbAction("idle")
        end)
        self:delayCallBack(0.5,function (  )
            self.forkIndex = self.forkIndex + 1
            self:updateSymbolShow(index)
        end)
    end
    
end

function TripletroveRedFreeStartView:getEndPosNode(index)

    return self:findChild("Socre_tripletrove_" .. index)
end

function TripletroveRedFreeStartView:setEndCall(func)
    self.endFunc = func
end

--延迟回调
function TripletroveRedFreeStartView:delayCallBack(time, func)
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

return TripletroveRedFreeStartView