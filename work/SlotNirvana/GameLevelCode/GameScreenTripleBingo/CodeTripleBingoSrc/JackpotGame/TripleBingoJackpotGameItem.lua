--[[
    多福多彩中的翻牌对象

    工程节点结构:
        Node_spine    如果效果是spine时加个挂点放在点击层下面
        Panel_click   点击图层
]]
local TripleBingoJackpotGameItem = class("TripleBingoJackpotGameItem", util_require("base.BaseView"))

function TripleBingoJackpotGameItem:initUI(_initData)
    --[[
        _initData = {
            itemIndex = 1,        --道具索引
            fnClick   = function, --点击回调
        }
    ]]
    self.m_initData = _initData

    self:createCsbNode("TripleBingo_dfdc_0.csb")
    self.m_spine = util_spineCreate("Socre_TripleBingo_Bonus", true, true)
    self:findChild("Node_tx"):addChild(self.m_spine)
    self.m_spine:setVisible(false)

    --添加点击
    self:addClick(self:findChild("Panel_click"))
end

--点击事件
function TripleBingoJackpotGameItem:clickFunc(sender)
    self.m_initData.fnClick(self.m_initData.itemIndex)
end

--重置为未翻开的默认静帧状态
function TripleBingoJackpotGameItem:resetPickItem()
    self:playNormalAnim()
end
--设置奖励类型
function TripleBingoJackpotGameItem:setRewardType(_rewardData)
    for i,_node in ipairs(self:findChild("Node_item"):getChildren()) do
        _node:setVisible(false)
    end
    local itemNode = self:findChild(string.format("item_%s", _rewardData.name))
    itemNode:setVisible(true)
end


--[[
    时间线表现
]]
--未翻开静帧
function TripleBingoJackpotGameItem:playNormalAnim()
    self:playIdleAnim()
end
--普通idle
function TripleBingoJackpotGameItem:playIdleAnim()
    self:runCsbAction("idle", false)
end
--抖动idle
function TripleBingoJackpotGameItem:playShakeIdleAnim()
    self:runCsbAction("idle2", false)
end
--翻开
function TripleBingoJackpotGameItem:playOpenAnim(_fun)
    local animName = "pick"
    self:runCsbAction(animName, false)

    self.m_spine:setVisible(true)
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self.m_spine:setVisible(false)
    end)

    performWithDelay(self, _fun, 15/30)
end
--中奖
function TripleBingoJackpotGameItem:playTriggerAnim()
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle4", true)
    end)
end
--压暗
function TripleBingoJackpotGameItem:playDarkAnim()
    self:runCsbAction("darkstart", false)
end

return TripleBingoJackpotGameItem