--[[
Author: cxc
Date: 2021-04-15 11:55:12
LastEditTime: 2021-04-15 14:11:09
LastEditors: Please set LastEditors
Description: 游客绑定token 进行账号数据转移
FilePath: /SlotNirvana/src/views/dialogs/TokenLoginFailLayer.lua
--]]
local TokenLoginFailLayer = class("TokenLoginFailLayer", BaseLayer)

function TokenLoginFailLayer:ctor()
    TokenLoginFailLayer.super.ctor(self) 

    -- 横屏资源
    self:setLandscapeCsbName("Dialog/TokenLoginFail.csb")
end

function TokenLoginFailLayer:initUI(_bFormatErr)
    TokenLoginFailLayer.super.initUI(self)

    local nodeUsed = self:findChild("node_used") -- 提示格式错误
    local nodeWrong = self:findChild("node_wrong") -- 提示被占用了token
    nodeUsed:setVisible(_bFormatErr)
    nodeWrong:setVisible(not _bFormatErr)
end

function TokenLoginFailLayer:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_ok" then
        self:closeUI()        
    end
    
end

return TokenLoginFailLayer