--[[
    翻牌对象

    工程节点结构:
        Node_spine    如果效果是spine时加个挂点放在点击层下面
        Panel_click   点击图层
]]
local TripleBingoPickItem = class("TripleBingoPickItem", util_require("base.BaseView"))

function TripleBingoPickItem:initUI(_initData)
    --[[
        _initData = {
            itemIndex = 1,        --道具索引
            fnClick   = function, --点击回调
        }
    ]]
    self.m_initData = _initData

    self:createCsbNode("TripleBingo_PickEm_Items.csb")
    --[[
        添加spine效果
        self.m_spine = util_spineCreate("TripleBingoPickItem", true, false)
        self:findChild("Node_spine"):addChild(self.m_spine)
    ]]

    --添加点击
    self:addClick(self:findChild("Panel_click"))
end

--点击事件
function TripleBingoPickItem:clickFunc(sender)
    self.m_initData.fnClick(self.m_initData.itemIndex)
end

--重置为未翻开的默认静帧状态
function TripleBingoPickItem:resetPickItem()
    self:findChild("Node_result"):setVisible(false)
    self:playNormalAnim()
end
--设置奖励类型
function TripleBingoPickItem:setRewardType(_rewardData)
    local bEnd = _rewardData.value == 0
    local labSelect =  self:findChild("m_lb_coins0")
    local labNormal =  self:findChild("m_lb_coins1")
    if not bEnd then
        local sCoins = util_formatCoins(_rewardData.value, 3)
        labSelect:setString(sCoins)
        labNormal:setString(sCoins)
        self:updateLabelSize({label = labSelect, sx = 0.4, sy = 0.4}, 274)
        self:updateLabelSize({label = labNormal, sx = 0.4, sy = 0.4}, 274)
    end
    self:findChild("Node_result"):setVisible(true)
end
function TripleBingoPickItem:upDateRewardVisible(_bSelect, _coins)
    local bEnd =_coins == 0
    self:findChild("End"):setVisible(bEnd)
    self:findChild("m_lb_coins0"):setVisible(not bEnd and _bSelect)
    self:findChild("m_lb_coins1"):setVisible(not bEnd and not _bSelect)
end

--[[
    时间线表现
]]
--不能翻开的静帧
function TripleBingoPickItem:playNormalAnim()
    self:runCsbAction("idle3", false)
end
--普通idle
function TripleBingoPickItem:playIdleAnim()
    self:runCsbAction("idle", false)
end
--抖动idle
function TripleBingoPickItem:playShakeIdleAnim()
    self:runCsbAction("idle2", false)
end
--翻开
function TripleBingoPickItem:playOpenAnim(_coins, _fun)
    self:upDateRewardVisible(true, _coins)
    local animName =  _coins > 0 and "switch1" or "switch3"
    self:runCsbAction(animName, false, _fun)
end
--压暗
function TripleBingoPickItem:playDarkAnim(_coins)
    self:upDateRewardVisible(false, _coins)
    self:runCsbAction("switch2", false)
end
--未点击行的压暗
function TripleBingoPickItem:playLineDarkAnim(_coins)
    self:upDateRewardVisible(false, _coins)
    self:runCsbAction("switch4", false)
end
--中奖
function TripleBingoPickItem:playTriggerAnim()
    self:runCsbAction("actionframe", false)
end


return TripleBingoPickItem