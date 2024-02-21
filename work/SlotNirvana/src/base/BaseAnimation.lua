local BaseView = util_require("base.BaseView")
local BaseAnimation = class("BaseAnimation", BaseView)

BaseAnimation.m_isAlive = nil
function BaseAnimation:initUI(csb_path, isAutoScale)
    self.m_isAlive = nil
    if cc.FileUtils:getInstance():isFileExist(csb_path) == true then
        self.m_path = csb_path
        --动画文件不打印log
        self.m_isCsbPathLog = false
        self:createCsbNode(csb_path, isAutoScale)
        self.m_isAlive = true
        release_print("BaseAnimation--csb_path =" .. csb_path)
    else
        release_print("BaseAnimation----------error not csb_path =" .. csb_path)
    end
end

function BaseAnimation:getCsbName()
    return self.m_path
end

--不重写父类
function BaseAnimation:playAction(key, loop, func, fps)
    if not self.m_isAlive then
        return
    end
    BaseAnimation.super.runCsbAction(self, key, loop, func, fps)
end

return BaseAnimation
