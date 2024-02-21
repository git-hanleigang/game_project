---
--xcyy
--2018年5月23日
--AliceMapChoose.lua

local AliceMapChoose = class("AliceMapChoose",util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
AliceMapChoose.m_chooseGame = nil

function AliceMapChoose:initUI(data)

    self:createCsbNode("Alice/BonusMapChoose.csb")

    self:runCsbAction("start") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:findChild("hat"):setVisible(false)
    self:findChild("card"):setVisible(false)
    self:findChild("tree"):setVisible(false)
    self:findChild("mushroom"):setVisible(false)
    self:findChild("rose"):setVisible(false)

    self.m_chooseGame = data.name
    self.m_closeCall = data.closeCall
    self.m_chooseCall = data.chooseCall
    self.m_clickOK = data.clickOK
    self:findChild(self.m_chooseGame):setVisible(true)

    gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_choose_layer.mp3")
end


function AliceMapChoose:onEnter()
 

end

function AliceMapChoose:showAdd()
    
end
function AliceMapChoose:onExit()
 
end

--默认按钮监听回调
function AliceMapChoose:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_choose_click.mp3")
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_choose_close.mp3")
    if name == "tb_btn_yes" and self.m_clickOK ~= nil then
        self.m_clickOK()
    end
    self:runCsbAction("over", false, function()
        if name == "tb_btn_yes" then
            local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = self.m_chooseGame}
            local httpSendMgr = SendDataManager:getInstance()
            httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, false)
            if self.m_chooseCall then
                self.m_chooseCall()
            end
        else
            if self.m_closeCall ~= nil then
                self.m_closeCall()
            end
        end
        self:removeFromParent()
    end)
    
end


return AliceMapChoose