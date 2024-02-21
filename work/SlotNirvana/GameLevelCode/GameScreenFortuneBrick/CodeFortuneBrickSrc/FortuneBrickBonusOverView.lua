
local FortuneBrickBonusOverView = class("FortuneBrickBonusOverView", util_require("base.BaseView"))

function FortuneBrickBonusOverView:initUI(data)
    local resourceFilename="FortuneBrick/BonusOver.csb"
    self:createCsbNode(resourceFilename)
    
    --添加收集条收集钱时的爆炸特效
    self.m_collectBaozha = util_createAnimation("FortuneBrick_baozha.csb")
    self:findChild("root"):addChild(self.m_collectBaozha)
    local worldPos = self:findChild("biaotizi"):getParent():convertToWorldSpace(cc.p(self:findChild("biaotizi"):getPosition()))
    local pos = self:findChild("root"):convertToNodeSpace(worldPos)
    self.m_collectBaozha:setPosition(pos)

    self:runCsbAction("shuzi")
    self:findChild("biaotizi"):setString("")
    self:findChild("Panel_1"):setVisible(false)
    
    self.m_click = true
end

function FortuneBrickBonusOverView:onEnter()
    
end

function FortuneBrickBonusOverView:onExit()
    
end

---
-- 显示收集赢钱效果和数量
--
function FortuneBrickBonusOverView:showCollectCoin(winCoin)
    self.m_collectBaozha:playAction("start")
    local score = util_formatCoins(winCoin,20) 
    self:updateLabelSize({label=self:findChild("biaotizi"),sx=1,sy=1},666)
    self:findChild("biaotizi"):setString(score)

    self:updateLabelSize({label=self:findChild("biaotizi_0"),sx=1,sy=1},666)
    self:findChild("biaotizi_0"):setString(score)
end

function FortuneBrickBonusOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return
        end
        self.m_click = true
        self:runCsbAction("over",false,function ()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)
    end
end
--收集结束后 界面播开始动画
function FortuneBrickBonusOverView:playStartAni(func)
    self.m_callFun = func
    self:findChild("biaotizi"):setVisible(false)
    self:findChild("Panel_1"):setVisible(true)
    self:runCsbAction("start",false,function ()
        self.m_click = false 
        self:runCsbAction("idle",true)
    end)
end
return FortuneBrickBonusOverView