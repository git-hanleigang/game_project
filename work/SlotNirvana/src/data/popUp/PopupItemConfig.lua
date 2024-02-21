--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
--
local PopupItemConfig = class("PopupItemConfig")

function PopupItemConfig:ctor()
    self.id = nil --弹窗id
    self.type = nil --弹窗类型
    self.desc = nil --描述
    self.leftLevel = nil --最小等级
    self.rightLevel = nil --最大等级
    self.time = nil --间隔时间
    self.fb = nil --是否为fb用户  0:非  1:是  -1:都可以
    self.vType = nil --弹出位置
    self.zOrder = nil --优先级
    self.zOrder1 = nil --优先级,同一优先级只显示一个
    self.luaName = nil --程序引用名
    self.pathCsbName = nil --资源路径
    self.hotPriority = nil --资源路径
    self.open = 1
    self.m_isNovice = false
    -- self.hallPriority = nil --展示图优先级
    -- self.hallShow = nil --是否显示展示图 如果为0不显示
    -- self.slidShow = nil --是否显示轮播图 如果为0不显示
    -- self.loginShow = nil --登录是否显示 如果为0不显示
    --开启状态  （发过来的数据，都是开启的）
end

function PopupItemConfig:parseData(data)
    self.id = data.popupId
    self.type = data.type
    self.desc = data.description
    self.leftLevel = data.levelMin or 1
    self.rightLevel = data.levelMax or -1
    self.time = data.duration
    self.fb = data.facebook
    self.pos = data.pos
    self.zOrder = data.priority
    self.zOrder1 = data.secondPriority or 0
    self.luaName = data.activityName
    self.pathCsbName = data.resourcePath
    if data.hotPriority then
        self.hotPriority = data.hotPriority
    end
    self.cd = data.cd or 0
    -- self.hallPriority = data.hallPriority --展示图优先级
    -- self.hallShow = data.hallShow --是否显示展示图 如果为0不显示
    -- self.slidShow = data.slidShow --是否显示轮播图 如果为0不显示
    -- self.loginShow = data.loginShow --登录是否显示 如果为0不显示
end

function PopupItemConfig:isOpen()
    return self.open
end

-- 弹板活动名
function PopupItemConfig:getRefName()
    return self.luaName
end

-- 首要优先
function PopupItemConfig:getPriority()
    return self.zOrder
end

function PopupItemConfig:setPriority(order)
    self.zOrder = order
end

-- 次级优先
function PopupItemConfig:getSecondPriority()
    return self.zOrder1
end

-- 点位类型
function PopupItemConfig:getPosType()
    return self.pos
end

-- 获得弹板类型
function PopupItemConfig:getPopType()
    return self.type
end

-- 获得弹板ID
function PopupItemConfig:getPopUpId()
    return self.id
end

function PopupItemConfig:getCdSecs()
    return self.cd
end

-- 获得资源路径
function PopupItemConfig:getCsbPath()
    return self.pathCsbName
end

function PopupItemConfig:isNovice()
    return self.m_isNovice
end

function PopupItemConfig:setNovice(isNovice)
    self.m_isNovice = (isNovice or false)
end

return PopupItemConfig
