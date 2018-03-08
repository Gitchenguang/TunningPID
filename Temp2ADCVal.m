function ADCVal = Temp2ADCVal( Temp )
% ADCVal = Temp2ADCVal( Temp )
% ��������
B = 3435;
K = 273.15; % �������
Rs = 10000; % ���������贮���ĵ�����ֵ 
Vcc = 3.31; % ��������һͷ��Vcc=3.3V��һͷ��Rs���裬�������䲢��һ��10uF���ݣ����˳���Ƶ����
Vref = 4.096;
T0 = 25 + K; % �ο��¶�25���Ӧ�ľ����¶�
R0 = 10000;  % 25�� ����10K

Rset = R0*exp(B*(1/(Temp+273.15)-1/T0));
Voltset = Vcc*(Rset/(R0+Rset));
ADCVal = Voltset*32768/Vref;
