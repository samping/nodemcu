-- init.lua
print('Setting up WIFI...')
wifi.setmode(wifi.STATION)
wifi.sta.config('CMPP_HUAWEI_4G', 'CMPP8888@')
wifi.sta.connect()

tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
    if wifi.sta.getip() == nil then
        print('Waiting for IP ...')
    else
        print('IP is ' .. wifi.sta.getip())
    tmr.stop(1)
    end
end)
print('OK!')