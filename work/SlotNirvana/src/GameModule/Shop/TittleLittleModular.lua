local TittleLittleModular=class("TittleLittleModular",util_require("base.BaseView"))

function TittleLittleModular:initUI(csbpath, index, showCall)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end

    self.callbackFunc = nil 
    self.viewIndex = index
    self.m_init = false
    if cc.FileUtils:getInstance():isFileExist(csbpath) == true then
        self.m_init = true
        self:createCsbNode(csbpath,isAutoScale)
        self:runCsbAction("idleframe",false)

        performWithDelay(self, function()
            self:runCsbAction("animation",false)
            if showCall then
                showCall()
            end
        end, 1)
    end
end

function TittleLittleModular:onEnter()
end

function TittleLittleModular:onExit()
end

return TittleLittleModular