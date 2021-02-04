#!/usr/bin/env python3

#cmd('*IDN?')
#cmd('INST CH1')
#cmd('INST?')
#cmd('MEASURE:CURRENT? CH1')
#cmd('MEASURE:VOLTAGE? CH1')
#cmd('MEASURE:POWER? CH1')
#cmd('CH1:CURR 0.5')
#cmd('CH1:VOLT 4.2')
#cmd('OUTPUT CH1,ON')
#cmd('OUTPUT:WAVE CH1,OFF')

import sys, time

f = open('/dev/spd3000', 'wb+', buffering=0)

def cmd(cmd):
    f.write(cmd.encode('utf-8') + b'\n')
    time.sleep(0.05)
    return f.read(1024).strip().decode('utf-8')

def status(ch, sts=None):
    sts = int(cmd('SYSTEM:STATUS?'), base=16) if sts is None else sts
    if ch == 2: sts >>= 1
    s = 'CH%d' % ch
    print(s+': %s %s' % ('CC' if sts&0x01 else 'CV',
                         'ON' if sts&0x10 else 'OFF'))
    print('  Set: %sV  %sA' % (cmd(s+':VOLT?'), cmd(s+':CURR?')))
    print('  Act: %sV  %sA  %sW' %
          (cmd('MEAS:VOLT? '+s), cmd('MEAS:CURR? '+s),
           cmd('MEAS:POWER? '+s)))


if len(sys.argv) == 1:

    print(cmd('*IDN?'))
    sts = int(cmd('SYSTEM:STATUS?'), base=16)
    print('Mode: ' + ('???', 'Independent', 'Parallel', 'Series')[(sts>>2)&3])
    status(1, sts)
    status(2, sts)

else:

    ch = int(sys.argv[1])
    assert 1 <= ch <= 2

    quiet = False

    for x in sys.argv[2:]:
        if x.endswith('v'):
            cmd('CH%d:VOLT %s' % (ch, x[:-1]))
        elif x.endswith('a'):
            cmd('CH%d:CURR %s' % (ch, x[:-1]))
        elif x == 'on':
            cmd('OUTPUT CH%d,ON' % ch)
        elif x == 'off':
            cmd('OUTPUT CH%d,OFF' % ch)
        elif x == 'quiet':
            quiet = True
        elif x == 'beep':
            cmd('FOO')

    if not quiet:
        status(ch)
