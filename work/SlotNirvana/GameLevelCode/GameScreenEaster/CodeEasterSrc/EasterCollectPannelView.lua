local EasterCollectPannelView = class("EasterCollectPannelView",util_require("base.BaseView"))

function EasterCollectPannelView:initUI(data)
	self.m_machine = data.machine
	self.m_gameMachine = data.gameMachine

	--todo
    -- self:createCsbNode("FreeGameTip.csb")

    -- self:runCsbAction("idleframe",true)
    self:addClick(self:findChild("Button_1")) -- 非按钮节点得手动绑定监听

    --todo
    self.m_curIndex = 1
end

function EasterCollectPannelView:onEnter()

end

function EasterCollectPannelView:onExit()
 
end

function EasterCollectPannelView:updateUIByData(data)
	-- body
end

function EasterCollectPannelView:resetUI()
	-- body
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取
--默认按钮监听回调
function EasterCollectPannelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
    	print("=================== " .. name)
    	self.m_gameMachine:sendCollectData(self.m_curIndex - 1)
    	self.m_curIndex = self.m_curIndex + 1
    end
end

return EasterCollectPannelView