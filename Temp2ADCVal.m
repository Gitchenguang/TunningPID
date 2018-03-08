function ADCVal = Temp2ADCVal( Temp )
% ADCVal = Temp2ADCVal( Temp )
% 常数定义
B = 3435;
K = 273.15; % 绝对零度
Rs = 10000; % 与热敏电阻串联的电阻阻值 
Vcc = 3.31; % 热敏电阻一头接Vcc=3.3V，一头接Rs电阻，并且与其并联一个10uF电容，以滤除高频噪声
Vref = 4.096;
T0 = 25 + K; % 参考温度25℃对应的绝对温度
R0 = 10000;  % 25℃ 电阻10K

Rset = R0*exp(B*(1/(Temp+273.15)-1/T0));
Voltset = Vcc*(Rset/(R0+Rset));
ADCVal = Voltset*32768/Vref;
