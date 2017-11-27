local _M = {
    _VERSION = '0.0.1'
}

function _M.get_data()
   local sock, err = ngx.req.socket()
   if sock then
      ngx.say("got the request socket")
   else
      ngx.say("failed to get the request socket: ", err)
      return
   end

   local data, err, part = sock:receive(17)
   if data then
      ngx.say("received: ", data)
   else
      ngx.say("failed to receive: ", err, " [", part, "]")
   end
   return data
end
return _M
