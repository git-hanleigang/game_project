--[[
    多福多彩中的翻牌对象
]]
local CherryBountyPickItem = class("CherryBountyPickItem", util_require("base.BaseView"))

function CherryBountyPickItem:initUI(_initData)
    --[[
        _initData = {
            itemIndex = 1,        --道具索引
            fnClick   = function, --点击回调
        }
    ]]
    self.m_machine  = _initData.machine
    self.m_initData = _initData

    self:createCsbNode("CherryBounty_pick_xuanxiang.csb")
    self.m_spine = util_spineCreate("CherryBounty_pick_xuanxiang2", true, true)
    self:findChild("Node_spine"):addChild(self.m_spine)

    --添加点击
    self:addClick(self:findChild("Panel_click"))
end

--点击事件
function CherryBountyPickItem:clickFunc(sender)
    self.m_initData.fnClick(self.m_initData.itemIndex)
end

--重置为未翻开的默认静帧状态
function CherryBountyPickItem:resetPickItem()
    self:playNormalAnim()
end
--设置奖励类型
function CherryBountyPickItem:setRewardType(_rewardData)
    local jpIndex = self.m_machine.JackpotTypeToIndex[_rewardData.name]
    if jpIndex then
        local jpCount = #self.m_machine.JackpotIndexToType
        local animIndex = jpCount + 1 - jpIndex
        self.m_openAnimName = string.format("pick%d", animIndex)
        self.m_idleAnimName = string.format("idle%d", animIndex)
    else
        self.m_openAnimName = "pick5"
        self.m_idleAnimName = "idle5"
    end
end


--[[
    时间线表现
]]
--未翻开静帧
function CherryBountyPickItem:playNormalAnim()
    self:playIdleAnim()
end
--普通idle
function CherryBountyPickItem:playIdleAnim()
    util_spinePlay(self.m_spine, "idleframe1", false)
end
--抖动idle
function CherryBountyPickItem:playShakeIdleAnim()
    util_spinePlay(self.m_spine, "idleframe2", false)
end
--翻开
function CherryBountyPickItem:playOpenAnim(_fun)
    util_spinePlay(self.m_spine, self.m_openAnimName, false)
    util_spineEndCallFunc(self.m_spine,  self.m_openAnimName, _fun)
end
--中奖
function CherryBountyPickItem:playTriggerAnim()
end
--压暗
function CherryBountyPickItem:playDarkAnim()
    util_spinePlay(self.m_spine, self.m_idleAnimName, false)
    self:runCsbAction("darkstart", false)
end

return CherryBountyPickItem