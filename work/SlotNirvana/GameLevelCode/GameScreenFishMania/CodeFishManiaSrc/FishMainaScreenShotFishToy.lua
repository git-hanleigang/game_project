---
--smy
--2018年5月24日
--FishMainaScreenShotFishToy.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local FishMainaScreenShotFishToy = class("FishMainaScreenShotFishToy",util_require("base.BaseView"))

function FishMainaScreenShotFishToy:initUI()

    self:createCsbNode("FishMania/ShareScreen.csb")
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_share_tanban.mp3")
    -- 暂时屏蔽保存本地按钮
    -- self:findChild("Button_Save"):setTouchEnabled(false)
    -- self:findChild("Button_Save"):setBright(false)
end

function FishMainaScreenShotFishToy:onEnter()
    
end

function FishMainaScreenShotFishToy:onExit(  )

end

-- 点击函数
function FishMainaScreenShotFishToy:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()    
    
    if name == "Button_Save" then
        if self.m_saveFunc then
            self.m_saveFunc()
        end
    elseif name == "Button_Share" then
        if self.m_shareFunc then
            self.m_shareFunc()
        end
    elseif name == "Button_Close" then

    end

    self:runCsbAction("over",false,function()
        self.m_callBack()
        self:removeFromParent()
    end)
    
end

--进入游戏初始化游戏数据 
function FishMainaScreenShotFishToy:initViewData(_sp, _func1, _func2, _func3)

    self.m_saveFunc = _func1
    self.m_shareFunc = _func2
    self.m_callBack = _func3

    local size = self:findChild("Panel_Photo"):getSize()
    local scale = size.width / display.width

    _sp:setScale(scale)

    self:findChild("Node_1"):addChild(_sp)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",false)
    end)
end

return FishMainaScreenShotFishToy