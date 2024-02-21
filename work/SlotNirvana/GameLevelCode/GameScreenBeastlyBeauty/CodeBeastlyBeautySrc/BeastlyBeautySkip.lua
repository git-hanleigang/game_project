-- 翻开bonus图标流程，可以通过点击跳过
local BeastlyBeautySkip = class("BeastlyBeautySkip",util_require("Levels.BaseLevelDialog"))

function BeastlyBeautySkip:initUI(_data)
    self.m_machine = _data.machine
    -- 点击跳过时的回调
    self.m_skipCallBack = nil

    self:createCsbNode("BeastlyBeauty_skip.csb")

    self:addClick(self:findChild("Panel_skip"))
end

--[[
    点击事件
]]
function BeastlyBeautySkip:clickFunc(sender)
    self:skipPanelClickCallBack()
end

function BeastlyBeautySkip:skipPanelClickCallBack()
    if self.m_skipCallBack then
        self.m_skipCallBack()
    end
end

-- 设置跳过后的回调
function BeastlyBeautySkip:setSkipCallBack(_fun)
    self.m_skipCallBack = _fun
end
function BeastlyBeautySkip:clearSkipCallBack()
    self.m_skipCallBack = nil
end

return BeastlyBeautySkip