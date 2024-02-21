local BuglyControl = class("BuglyControl")
function BuglyControl:ctor()

end
-- 设置用户id，您在页面的异常详情会显示具体用户的id
function BuglyControl:setId(id)
    --debug模式不上传日志
    if DEBUG == 2 then
        return
    end
    if not id then
        return
    end
    
    if device.platform == "android" then
        buglySetUserId(id)
    end

    if device.platform == "ios" then
        buglySetUserId(id)
    end

    if device.platform == "mac" then

    end
end
-- 设置当前场景的“TAG”，int类型（bugly页面可备注该值含义）
-- 一次运行过程中只有一个TAG，以上报异常时最后TAG为准。例如登录时设置tag=1，进入副本设置tag=2
function BuglyControl:setTag(tag)
    --debug模式不上传日志
    if DEBUG == 2 then
        return
    end
    if not tag then
        return
    end
    if device.platform == "android" then
        buglySetTag(tag)
    end

    if device.platform == "ios" then
        buglySetTag(tag)
    end

    if device.platform == "mac" then

    end
end
-- 上报一些自定义的Key-Value键值对：
-- 1）最多10对，超出的会被忽略
-- 2）每个key限长50字节，value限长200字节
-- 3）key限制为字母 + 数字
function BuglyControl:setInfo(key,value)
    --debug模式不上传日志
    if DEBUG == 2 then
        return
    end
    if not key or not value then
        return
    end
    if device.platform == "android" then
        buglyAddUserValue(key, value)
    end

    if device.platform == "ios" then
        buglyAddUserValue(key, value)
    end
    if device.platform == "mac" then

    end
end
-- 记录开发者自定义的关键信息日志。该日志会随异常信息一起上报。
-- 注：Log最大长度约10K，超长会保留最近内容。建议每条Log长度控制在200字节以内。
function BuglyControl:log(value)
    --debug模式不上传日志
    if DEBUG == 2 then
        return
    end
    if not value then
        return
    end

    if device.platform == "android" then
        buglyLog(1, "log", value)
    end

    if device.platform == "ios" then
        buglyLog(1, "log", value)
    end
    if device.platform == "mac" then

    end
end
function BuglyControl:luaException(mess,value)
    --debug模式不上传日志
    if DEBUG == 2 then
        return
    end
    if not value then
        return
    end

    if device.platform == "android" then
        buglyReportLuaException(mess,value)
    end

    if device.platform == "ios" then
        buglyReportLuaException(mess,value)
    end
    if device.platform == "mac" then

    end
end

return BuglyControl