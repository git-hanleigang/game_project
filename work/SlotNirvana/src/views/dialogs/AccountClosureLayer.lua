--[[
    账号封停弹框
    登陆时弹出
]]
local AccountClosureLayer = class("AccountClosureLayer", BaseLayer)

function AccountClosureLayer:initDatas()
    AccountClosureLayer.super.initDatas(self)
    self:setLandscapeCsbName("Dialog/BlockPopup.csb")
end

function AccountClosureLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_quit" then
        if device.platform == "ios" then
            globalLocalPushManager:commonBackGround()
            G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            os.exit()
        else
            globalLocalPushManager:commonBackGround()
            G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            local director = cc.Director:getInstance()
            director:endToLua()
        end
    elseif name == "btn_contactus" then
        self:contactUS()
    end
end

function AccountClosureLayer:contactUS()
    globalData.newMessageNums = nil
    globalData.skipForeGround = true
    globalPlatformManager:openAIHelpRobot("AccountClosure")
end

return AccountClosureLayer
