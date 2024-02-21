local StatueCardEffectNode = class("StatueCardEffectNode", BaseView)
function StatueCardEffectNode:initUI()
    StatueCardEffectNode.super.initUI(self)
end
function StatueCardEffectNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_effect_HuizhangSg.csb"
end

function StatueCardEffectNode:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function StatueCardEffectNode:playLevelUpOver(_levelUpOverCall, _number, _maxNum)
    self:runCsbAction("over", false, function()
        if _number == _maxNum then
            if _levelUpOverCall then
                _levelUpOverCall()
            end
        end
    end, 60)
end

function StatueCardEffectNode:playLevelUp(_levelUpOverCall, _number, _maxNum)
    self:runCsbAction("shengji", false, function()
        self:runCsbAction("idle2", true, nil, 60)
        if _number == _maxNum then
            if _levelUpOverCall then
                _levelUpOverCall()
            end
        end
    end, 60)
end

-- 单个卡牌点亮动画
function StatueCardEffectNode:playLight(_lightOverCall, _number, _maxNum)
    self:runCsbAction("dianliang", false, function()
        if _number == _maxNum then
            if _lightOverCall then
                _lightOverCall()
            end
        end
    end, 60)
end

return StatueCardEffectNode