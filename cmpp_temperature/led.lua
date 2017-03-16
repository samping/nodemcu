---LED MODULE
-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M

-- Timer module
local tmr = tmr
local gpio = gpio
local type = type

-- Limited to local environment
setfenv(1,M)
IO_BLINK = 4
TMR_BLINK = 5
gpio.mode(IO_BLINK, gpio.OUTPUT)

blink = nil
tmr.register(TMR_BLINK, 100, tmr.ALARM_AUTO, function()
    gpio.write(IO_BLINK, blink.i % 2)
    tmr.interval(TMR_BLINK, blink[blink.i + 1])
    blink.i = (blink.i + 1) % #blink
end)

function blinking(param)
    if type(param) == 'table' then
        blink = param
        blink.i = 0
        tmr.interval(TMR_BLINK, 1)
        running, _ = tmr.state(TMR_BLINK)
        if running ~= true then
            tmr.start(TMR_BLINK)
        end
    else
        tmr.stop(TMR_BLINK)
        gpio.write(IO_BLINK, param or gpio.LOW)
    end
end

-- blinking({300, 300}) -- 循环闪烁：亮300ms，灭300ms
-- blinking({100, 100 , 100, 500}) -- 循环闪烁：亮100ms，灭100ms，亮100ms，灭500ms

-- blinking() -- 常亮
-- blinking(gpio.LOW) -- 常亮
-- blinking(gpio.HIGH) -- 常灭

-- Return module table
return M
